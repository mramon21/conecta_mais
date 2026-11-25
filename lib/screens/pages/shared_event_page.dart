import 'package:conecta_mais/providers/evento_provider.dart';
import 'package:conecta_mais/screens/models/evento.dart';
import 'package:conecta_mais/screens/pages/details_event_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SharedEventPage extends StatefulWidget {
  const SharedEventPage({super.key, required this.eventId});

  final String eventId;

  @override
  State<SharedEventPage> createState() => _SharedEventPageState();
}

class _SharedEventPageState extends State<SharedEventPage> {
  late Future<Evento?> _eventoFuture;

  @override
  void initState() {
    super.initState();
    _carregarEvento();
  }

  void _carregarEvento() {
    _eventoFuture = context.read<EventoProvider>().buscarEventoPorId(
      widget.eventId,
    );
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<Evento?>(
    future: _eventoFuture,
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }
      if (snapshot.hasError) {
        return _buildMensagem(
          'Não foi possível carregar o evento: ${snapshot.error}',
          podeTentarNovamente: true,
        );
      }
      final evento = snapshot.data;
      if (evento == null) {
        return _buildMensagem('Este evento não está mais disponível.');
      }
      return DetailsEventPage(evento: evento);
    },
  );

  Widget _buildMensagem(String mensagem, {bool podeTentarNovamente = false}) =>
      Scaffold(
        appBar: AppBar(title: const Text('Evento compartilhado')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(24),
                child: Text(mensagem, textAlign: TextAlign.center),
              ),
              if (podeTentarNovamente)
                TextButton(
                  onPressed: () => setState(_carregarEvento),
                  child: const Text('Tentar novamente'),
                ),
            ],
          ),
        ),
      );
}
