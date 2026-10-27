import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:conecta_mais/models/user_model.dart';

enum UserRole { explorer, manager }

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  UserModel? _user;
  bool _isLoggedIn = false;
  bool _isLoading = false;
  String? _error;
  late final StreamSubscription<User?> _authSubscription;

  UserModel? get user => _user;
  bool get isLoggedIn => _isLoggedIn;
  bool get isLoading => _isLoading;
  String? get error => _error;
  UserRole get role =>
      _user?.isOrganizer == true ? UserRole.manager : UserRole.explorer;

  AuthProvider() {
    _authSubscription = _auth.authStateChanges().listen((
      User? firebaseUser,
    ) async {
      if (firebaseUser == null) {
        _setLoggedOut();
      } else {
        await _fetchUserProfile(firebaseUser.uid);
      }
    });
  }

  void _setLoggedOut() {
    _isLoggedIn = false;
    _user = null;
    _error = null;
    notifyListeners();
  }

  Future<bool> _fetchUserProfile(String uid) async {
    _setLoading(true);
    try {
      DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(uid)
          .get();
      if (doc.exists) {
        final userData = Map<String, dynamic>.from(
          doc.data() as Map<String, dynamic>,
        );
        final authEmail = _auth.currentUser?.uid == uid
            ? _auth.currentUser?.email
            : null;
        if (authEmail != null && userData['email'] != authEmail) {
          await doc.reference.update({'email': authEmail});
          userData['email'] = authEmail;
        }
        _user = UserModel.fromMap(userData);
        _isLoggedIn = true;
        _error = null;
        return true;
      } else {
        _error = 'Perfil de usuário não encontrado no Firestore.';
        _isLoggedIn = false;
        _user = null;
        return false;
      }
    } catch (e) {
      _error = 'Erro ao buscar perfil: $e';
      _isLoggedIn = false;
      _user = null;
      return false;
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  Future<String?> signUp({
    required String email,
    required String password,
    required String name,
    required bool isOrganizer,
  }) async {
    _setLoading(true);
    _error = null;
    try {
      UserCredential credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      String uid = credential.user!.uid;
      UserModel newUser = UserModel(
        id: uid,
        nome: name,
        email: email,
        isOrganizer: false,
        solicitacaoOrganizador: isOrganizer,
        createdAt: DateTime.now(),
      );

      await _firestore.collection('users').doc(uid).set(newUser.toMap());
      if (!await _fetchUserProfile(uid)) {
        final error = _error ?? 'Não foi possível carregar o perfil criado.';
        await _auth.signOut();
        return error;
      }
      return null;
    } on FirebaseAuthException catch (e) {
      return _handleAuthError(e);
    } catch (e) {
      return 'Ocorreu um erro inesperado. Tente novamente.';
    } finally {
      _setLoading(false);
    }
  }

  Future<String?> signIn(String email, String password) async {
    _setLoading(true);
    _error = null;
    try {
      UserCredential credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final profileLoaded = await _fetchUserProfile(credential.user!.uid);
      if (profileLoaded) return null;
      final error = _error ?? 'Não foi possível carregar seu perfil.';
      await _auth.signOut();
      return error;
    } on FirebaseAuthException catch (e) {
      return _handleAuthError(e);
    } catch (e) {
      return 'Ocorreu um erro inesperado. Tente novamente.';
    } finally {
      _setLoading(false);
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
  }

  Future<String?> cadastrarComoOrganizador({
    required String documento,
    required String nomeInstituicao,
  }) async {
    if (_user == null) return 'Faça login para se tornar organizador.';
    _setLoading(true);
    try {
      await _firestore.collection('users').doc(_user!.id).update({
        'documento': documento,
        'nomeInstituicao': nomeInstituicao,
        'isOrganizer': true,
        'solicitacaoOrganizador': false,
      });
      final profileLoaded = await _fetchUserProfile(_user!.id);
      return profileLoaded ? null : _error;
    } catch (_) {
      return 'Não foi possível salvar os dados de organizador.';
    } finally {
      _setLoading(false);
    }
  }

  Future<String?> atualizarPerfil({
    required String nome,
    Uint8List? foto,
    String? contentType,
  }) async {
    final user = _user;
    if (user == null) return 'Faça login para editar seu perfil.';

    _setLoading(true);
    try {
      String? photoUrl = user.photoUrl;
      if (foto != null) {
        final referencia = _storage.ref().child(
          'usuarios/${user.id}/perfil/foto',
        );
        await referencia.putData(
          foto,
          SettableMetadata(contentType: contentType ?? 'image/jpeg'),
        );
        photoUrl = await referencia.getDownloadURL();
      }

      await _firestore.collection('users').doc(user.id).update({
        'nome': nome.trim(),
        'photoUrl': photoUrl,
      });
      final profileLoaded = await _fetchUserProfile(user.id);
      return profileLoaded ? null : _error;
    } on FirebaseException catch (error) {
      return 'Não foi possível atualizar o perfil '
          '(${error.code}): ${error.message}';
    } catch (_) {
      return 'Não foi possível atualizar o perfil.';
    } finally {
      _setLoading(false);
    }
  }

  Future<String?> solicitarAlteracaoEmail(String email) async {
    final novoEmail = email.trim();
    final usuarioFirebase = _auth.currentUser;
    if (_user == null || usuarioFirebase == null) {
      return 'Faça login para alterar seu e-mail.';
    }
    if (novoEmail.isEmpty ||
        !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(novoEmail)) {
      return 'Informe um e-mail válido.';
    }
    if (novoEmail.toLowerCase() == _user!.email.toLowerCase()) {
      return 'Informe um e-mail diferente do atual.';
    }

    try {
      await usuarioFirebase.verifyBeforeUpdateEmail(novoEmail);
      return null;
    } on FirebaseAuthException catch (error) {
      switch (error.code) {
        case 'email-already-in-use':
          return 'Este e-mail já está sendo usado por outra conta.';
        case 'invalid-email':
          return 'Formato de e-mail inválido.';
        case 'requires-recent-login':
          return 'Por segurança, saia e entre novamente antes de alterar o e-mail.';
        case 'operation-not-allowed':
          return 'A alteração de e-mail não está habilitada no Firebase.';
        default:
          return 'Não foi possível enviar a confirmação (${error.code}).';
      }
    }
  }

  @override
  void dispose() {
    _authSubscription.cancel();
    super.dispose();
  }

  String _handleAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'Este e-mail já está cadastrado.';
      case 'invalid-email':
        return 'Formato de e-mail inválido.';
      case 'user-not-found':
        return 'Usuário não encontrado.';
      case 'wrong-password':
        return 'Senha incorreta.';
      case 'weak-password':
        return 'A senha é muito fraca.';
      default:
        return 'Erro de autenticação: ${e.message}';
    }
  }
}
