import 'dart:async';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:conecta_mais/screens/models/evento.dart';

class EventoProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final List<Evento> _eventos = [];
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _subscription;
  bool _isLoading = true;
  String? _error;

  List<Evento> get eventos => List.unmodifiable(_eventos);
  bool get isLoading => _isLoading;
  String? get error => _error;

  EventoProvider() {
    _startListening();
  }

  void _startListening() {
    _subscription?.cancel();
    _isLoading = true;
    _error = null;
    notifyListeners();
    _subscription = _firestore
        .collection('eventos')
        .snapshots()
        .listen(
          (snapshot) {
            _eventos
              ..clear()
              ..addAll(
                snapshot.docs.map(
                  (doc) => Evento.fromJson(doc.data(), id: doc.id),
                ),
              );
            _isLoading = false;
            _error = null;
            notifyListeners();
          },
          onError: (Object _) {
            _isLoading = false;
            _error = 'Não foi possível carregar os eventos.';
            notifyListeners();
          },
        );
  }

  void retry() => _startListening();

  List<Evento> get eventosAtivos => _eventos
      .where((evento) => evento.dataHoraEvento.isAfter(DateTime.now()))
      .toList();

  List<Evento> get eventosFimDeSemana {
    final agora = DateTime.now();
    return eventosAtivos.where((evento) {
      final diasAteEvento = evento.dataHoraEvento.difference(agora).inDays;
      return diasAteEvento <= 7 &&
          (evento.dataHoraEvento.weekday == DateTime.saturday ||
              evento.dataHoraEvento.weekday == DateTime.sunday);
    }).toList();
  }

  List<Evento> eventosPorCategoria(String categoria) =>
      eventosAtivos.where((evento) => evento.tipoEvento == categoria).toList();

  List<Evento> getEventosFiltrados(List<String> categorias, String query) {
    final normalizedQuery = query.trim().toLowerCase();
    return eventosAtivos.where((evento) {
      final matchesQuery =
          normalizedQuery.isEmpty ||
          evento.nomeEvento.toLowerCase().contains(normalizedQuery) ||
          evento.descricaoEvento.toLowerCase().contains(normalizedQuery) ||
          evento.localEvento.toLowerCase().contains(normalizedQuery);
      final matchesCategory =
          categorias.isEmpty || categorias.contains(evento.tipoEvento);
      return matchesQuery && matchesCategory;
    }).toList();
  }

  Future<List<Evento>> buscarEventosDoUsuario() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const [];

    final documentos = await _firestore.collection('eventos').get();
    final participacoes = await Future.wait(
      documentos.docs.map((documento) async {
        final idsLegados = List<String>.from(
          documento.data()['participantesIds'] as List? ?? const [],
        );
        if (idsLegados.contains(uid)) return documento;

        final participacao = await documento.reference
            .collection('participantes')
            .doc(uid)
            .get();
        return participacao.exists ? documento : null;
      }),
    );

    return participacoes
        .whereType<QueryDocumentSnapshot<Map<String, dynamic>>>()
        .map((documento) => Evento.fromJson(documento.data(), id: documento.id))
        .toList()
      ..sort((a, b) => a.dataHoraEvento.compareTo(b.dataHoraEvento));
  }

  Future<String> uploadImagem(
    Uint8List imageBytes, {
    String? contentType,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw StateError('Faça login para enviar uma imagem.');
    final ref = _storage.ref().child(
      'eventos/$uid/${DateTime.now().microsecondsSinceEpoch}',
    );
    await ref.putData(
      imageBytes,
      SettableMetadata(contentType: contentType ?? 'image/jpeg'),
    );
    return ref.getDownloadURL();
  }

  Future<void> adicionarEvento(Evento evento) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw StateError('Faça login para criar um evento.');
    await _firestore.collection('eventos').add({
      ...evento.toJson(),
      'ownerId': uid,
    });
  }

  Future<String?> atualizarEvento(Evento evento) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || evento.id == null || evento.ownerId != uid) {
      return 'Você não tem permissão para editar este evento.';
    }
    try {
      await _firestore
          .collection('eventos')
          .doc(evento.id)
          .update(evento.toJson());
      return null;
    } catch (_) {
      return 'Não foi possível atualizar o evento.';
    }
  }

  Future<String?> excluirEvento(Evento evento) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || evento.id == null || evento.ownerId != uid) {
      return 'Você não tem permissão para excluir este evento.';
    }
    try {
      final reference = _firestore.collection('eventos').doc(evento.id);
      final participantes = await reference.collection('participantes').get();
      for (var start = 0; start < participantes.docs.length; start += 400) {
        final batch = _firestore.batch();
        final end = start + 400 < participantes.docs.length
            ? start + 400
            : participantes.docs.length;
        for (final participante in participantes.docs.sublist(start, end)) {
          batch.delete(participante.reference);
        }
        await batch.commit();
      }
      await reference.delete();
      return null;
    } catch (_) {
      return 'Não foi possível excluir o evento.';
    }
  }

  Future<String?> participarDoEvento(Evento evento) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return 'Faça login para participar do evento.';
    if (evento.id == null) return 'Evento indisponível.';

    try {
      await _firestore.runTransaction((transaction) async {
        final reference = _firestore.collection('eventos').doc(evento.id);
        final snapshot = await transaction.get(reference);
        if (!snapshot.exists) throw StateError('Evento não encontrado.');
        final dados = snapshot.data()!;
        final participantRef = reference.collection('participantes').doc(uid);
        final participantSnapshot = await transaction.get(participantRef);
        final vagas = (dados['vagasTotal'] as num?)?.toInt();
        if (participantSnapshot.exists) {
          throw StateError('Você já participa deste evento.');
        }
        final rawDate = dados['dataHoraEvento'];
        final dataHora = rawDate is Timestamp
            ? rawDate.toDate()
            : rawDate is String
            ? DateTime.tryParse(rawDate)
            : null;
        if (dataHora == null || !dataHora.isAfter(DateTime.now())) {
          throw StateError(
            'Este evento já ocorreu ou possui uma data inválida.',
          );
        }
        final inscritos =
            (dados['vagasOcupadas'] as num?)?.toInt() ??
            (dados['participantesIds'] as List? ?? const []).length;
        if (vagas != null && inscritos >= vagas) {
          throw StateError('Todas as vagas foram preenchidas.');
        }
        transaction.update(reference, {'vagasOcupadas': inscritos + 1});
        transaction.set(participantRef, {'uid': uid});
      });
      return null;
    } on StateError catch (error) {
      return error.message.toString();
    } on FirebaseException catch (error) {
      if (error.code == 'permission-denied') {
        return 'O Firestore recusou a inscrição. Publique as regras atualizadas '
            'em firebase/firestore.rules e tente novamente.';
      }
      return 'Erro do Firebase (${error.code}): ${error.message}';
    } catch (_) {
      return 'Não foi possível registrar sua participação.';
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
