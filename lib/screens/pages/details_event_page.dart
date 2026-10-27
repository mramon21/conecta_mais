import 'package:conecta_mais/screens/models/evento.dart';
import 'package:conecta_mais/widgets/evento_card.dart';
import 'package:conecta_mais/providers/evento_provider.dart';
import 'package:conecta_mais/screens/pages/edit_event_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class DetailsEventPage extends StatelessWidget {
  const DetailsEventPage({super.key, required this.evento});

  final Evento evento;

  @override
  Widget build(BuildContext context) {
    final isOwner =
        evento.ownerId != null &&
        evento.ownerId == FirebaseAuth.instance.currentUser?.uid;
    final valorIngressoFormatado = evento.valorIngresso == 0
        ? 'Gratuito'
        : 'R\$ ${evento.valorIngresso.toStringAsFixed(2).replaceAll('.', ',')}';
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalhes do evento'),
        actions: [
          IconButton(
            icon: const Icon(Icons.ios_share),
            tooltip: 'Enviar convite',
            onPressed: () => _enviarConvite(context),
          ),
          if (isOwner) ...[
            IconButton(
              icon: const Icon(Icons.edit),
              tooltip: 'Editar evento',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => EditEventPage(evento: evento),
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Excluir evento',
              onPressed: () => _confirmarExclusao(context),
            ),
          ],
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: double.infinity,
              height: 260,
              child: EventImage(url: evento.imagemEvento),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    evento.nomeEvento,
                    style: Theme.of(context).textTheme.headlineSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _InfoLine(
                    icon: Icons.calendar_month,
                    text: evento.dataHoraFormatada,
                  ),
                  const SizedBox(height: 10),
                  _InfoLine(
                    icon: Icons.location_on_outlined,
                    text: evento.localEvento,
                  ),
                  if (evento.enderecoEvento.trim().isNotEmpty) ...[
                    const SizedBox(height: 10),
                    _InfoLine(
                      icon: Icons.pin_drop_outlined,
                      text: evento.enderecoEvento,
                    ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: () => _verNoMapa(context),
                        icon: const Icon(Icons.map_outlined),
                        label: const Text('Ver no mapa'),
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),
                  _InfoLine(
                    icon: Icons.category_outlined,
                    text: evento.tipoEvento,
                  ),
                  const SizedBox(height: 10),
                  _InfoLine(
                    icon: Icons.confirmation_number_outlined,
                    text: valorIngressoFormatado,
                  ),
                  const SizedBox(height: 10),
                  _InfoLine(
                    icon: Icons.people_outline,
                    text: evento.vagasTotal == null
                        ? 'Vagas não informadas'
                        : '${evento.vagasRestantes} de ${evento.vagasTotal} vagas disponíveis',
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Descrição',
                    style: Theme.of(context).textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(evento.descricaoEvento),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: !isOwner && evento.temVagas
                          ? () async {
                              final mensagem = await context
                                  .read<EventoProvider>()
                                  .participarDoEvento(evento);
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    mensagem ?? 'Participação confirmada!',
                                  ),
                                  backgroundColor: mensagem == null
                                      ? Colors.green
                                      : Colors.red,
                                ),
                              );
                            }
                          : null,
                      icon: const Icon(Icons.how_to_reg),
                      label: Text(
                        isOwner
                            ? 'Você criou este evento'
                            : evento.temVagas
                            ? 'Participar do evento'
                            : 'Vagas esgotadas',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _verNoMapa(BuildContext context) async {
    final query = Uri.encodeComponent(evento.enderecoEvento);
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$query',
    );
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível abrir o mapa.')),
      );
    }
  }

  Future<void> _enviarConvite(BuildContext context) async {
    final ingresso = evento.valorIngresso == 0
        ? 'Gratuito'
        : 'R\$ ${evento.valorIngresso.toStringAsFixed(2).replaceAll('.', ',')}';
    final convite = [
      'Você está convidado para ${evento.nomeEvento}!',
      'Data: ${evento.dataHoraFormatada}',
      'Local: ${evento.localEvento}',
      if (evento.enderecoEvento.trim().isNotEmpty)
        'Endereço: ${evento.enderecoEvento}',
      'Ingresso: $ingresso',
    ].join('\n');

    await SharePlus.instance.share(
      ShareParams(text: convite, subject: 'Convite: ${evento.nomeEvento}'),
    );
  }

  Future<void> _confirmarExclusao(BuildContext context) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Excluir evento?'),
        content: const Text('Essa ação não pode ser desfeita.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (confirmar != true || !context.mounted) return;
    final erro = await context.read<EventoProvider>().excluirEvento(evento);
    if (!context.mounted) return;
    if (erro != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(erro), backgroundColor: Colors.red),
      );
      return;
    }
    Navigator.pop(context);
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, color: Theme.of(context).colorScheme.primary),
      const SizedBox(width: 10),
      Expanded(child: Text(text)),
    ],
  );
}
