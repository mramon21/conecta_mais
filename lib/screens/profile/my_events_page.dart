import 'package:conecta_mais/providers/evento_provider.dart';
import 'package:conecta_mais/screens/models/evento.dart';
import 'package:conecta_mais/widgets/evento_card.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class MyEventsPage extends StatefulWidget {
  const MyEventsPage({super.key});

  @override
  State<MyEventsPage> createState() => _MyEventsPageState();
}

class _MyEventsPageState extends State<MyEventsPage> {
  late Future<List<Evento>> _eventosFuture;

  @override
  void initState() {
    super.initState();
    _eventosFuture = context.read<EventoProvider>().buscarEventosDoUsuario();
  }

  void _atualizar() {
    setState(() {
      _eventosFuture = context.read<EventoProvider>().buscarEventosDoUsuario();
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Eventos que estou participando'),
      actions: [
        IconButton(
          onPressed: _atualizar,
          tooltip: 'Atualizar',
          icon: const Icon(Icons.refresh),
        ),
      ],
    ),
    body: FutureBuilder<List<Evento>>(
      future: _eventosFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          final error = snapshot.error;
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  error is FirebaseException
                      ? 'Erro ao carregar eventos (${error.code}): ${error.message}'
                      : 'Não foi possível carregar seus eventos: $error',
                  textAlign: TextAlign.center,
                ),
                TextButton(
                  onPressed: _atualizar,
                  child: const Text('Tentar novamente'),
                ),
              ],
            ),
          );
        }

        final eventos = snapshot.data ?? const [];
        if (eventos.isEmpty) {
          return const Center(
            child: Text('Você ainda não está participando de nenhum evento.'),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: eventos.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (context, index) => EventoCard(evento: eventos[index]),
        );
      },
    ),
  );
}
