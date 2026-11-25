import 'package:conecta_mais/widgets/evento_card.dart';
import 'package:flutter/material.dart';
import 'package:conecta_mais/screens/models/evento.dart';
import 'package:conecta_mais/providers/evento_provider.dart';
import 'package:provider/provider.dart';

class AllEvents extends StatelessWidget {
  final List<Evento> listaEventos;

  const AllEvents({super.key, required this.listaEventos});

  @override
  Widget build(BuildContext context) {
    final eventosAtualizados = context.select<EventoProvider, List<Evento>>(
      (provider) => listaEventos.map((evento) {
        for (final eventoAtual in provider.eventos) {
          if (eventoAtual.id == evento.id) return eventoAtual;
        }
        return evento;
      }).toList(),
    );
    return Scaffold(
      appBar: AppBar(title: const Text('Todos os eventos')),
      body: ListView.separated(
        padding: const EdgeInsets.all(8),
        itemCount: eventosAtualizados.length,
        itemBuilder: (context, index) {
          return EventoCard(evento: eventosAtualizados[index]);
        },
        separatorBuilder: (context, index) => const SizedBox(height: 12),
      ),
    );
  }
}
