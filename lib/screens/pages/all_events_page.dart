import 'package:conecta_mais/widgets/evento_card.dart';
import 'package:flutter/material.dart';
import 'package:conecta_mais/screens/models/evento.dart';

class AllEvents extends StatelessWidget {
  final List<Evento> listaEventos;

  const AllEvents({super.key, required this.listaEventos});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Todos os eventos')),
      body: ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: listaEventos.length,
        itemBuilder: (context, index) {
          return EventoCard(evento: listaEventos[index]);
        },
      ),
    );
  }
}
