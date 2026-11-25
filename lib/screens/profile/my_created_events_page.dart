import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:conecta_mais/providers/evento_provider.dart';
import 'package:conecta_mais/screens/models/evento.dart';
import 'package:conecta_mais/widgets/evento_card.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class MyCreatedEventsPage extends StatefulWidget {
  const MyCreatedEventsPage({super.key});

  @override
  State<MyCreatedEventsPage> createState() => _MyCreatedEventsPageState();
}

class _MyCreatedEventsPageState extends State<MyCreatedEventsPage> {
  late Future<List<Evento>> _eventosFuture;

  @override
  void initState() {
    super.initState();
    _atualizar();
  }

  void _atualizar() {
    _eventosFuture = context.read<EventoProvider>().buscarEventosCriados();
  }

  @override
  Widget build(BuildContext context) => DefaultTabController(
    length: 2,
    child: Scaffold(
      appBar: AppBar(
        title: const Text('Eventos que criei'),
        actions: [
          IconButton(
            onPressed: () => setState(_atualizar),
            tooltip: 'Atualizar',
            icon: const Icon(Icons.refresh),
          ),
        ],
        bottom: const TabBar(
          tabs: [
            Tab(text: 'Públicos'),
            Tab(text: 'Privados'),
          ],
        ),
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
                        ? 'Erro ao carregar eventos (${error.code}): '
                              '${error.message}'
                        : 'Não foi possível carregar seus eventos: $error',
                    textAlign: TextAlign.center,
                  ),
                  TextButton(
                    onPressed: () => setState(_atualizar),
                    child: const Text('Tentar novamente'),
                  ),
                ],
              ),
            );
          }

          final eventos = snapshot.data ?? const [];
          return TabBarView(
            children: [
              _buildLista(
                eventos.where((evento) => !evento.isPrivate).toList(),
              ),
              _buildLista(eventos.where((evento) => evento.isPrivate).toList()),
            ],
          );
        },
      ),
    ),
  );

  Widget _buildLista(List<Evento> eventos) {
    if (eventos.isEmpty) {
      return const Center(child: Text('Nenhum evento nesta aba.'));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: eventos.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) => EventoCard(evento: eventos[index]),
    );
  }
}
