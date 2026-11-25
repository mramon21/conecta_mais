import 'package:conecta_mais/providers/evento_provider.dart';
import 'package:conecta_mais/widgets/nearby_events_map.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class NearbyEventsPage extends StatelessWidget {
  const NearbyEventsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EventoProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Eventos na proximidade')),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : provider.error != null
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(provider.error!, textAlign: TextAlign.center),
                  TextButton(
                    onPressed: provider.retry,
                    child: const Text('Tentar novamente'),
                  ),
                ],
              ),
            )
          : NearbyEventsMap(events: provider.eventosAtivos),
    );
  }
}
