import 'package:conecta_mais/auth/auth_provider.dart';
import 'package:conecta_mais/screens/models/evento.dart';
import 'package:conecta_mais/widgets/evento_card.dart';
import 'package:conecta_mais/providers/evento_provider.dart';
import 'package:conecta_mais/screens/auth/login_page.dart';
import 'package:conecta_mais/screens/pages/edit_event_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class DetailsEventPage extends StatelessWidget {
  const DetailsEventPage({super.key, required this.evento});

  final Evento evento;

  @override
  Widget build(BuildContext context) {
    final isLoggedIn = context.watch<AuthProvider>().isLoggedIn;
    final eventoAtual = context.select<EventoProvider, Evento>((provider) {
      for (final item in provider.eventos) {
        if (item.id == evento.id) return item;
      }
      return evento;
    });
    final isOwner =
        eventoAtual.ownerId != null &&
        eventoAtual.ownerId == FirebaseAuth.instance.currentUser?.uid;
    final valorIngressoFormatado = eventoAtual.valorIngresso == 0
        ? 'Gratuito'
        : 'R\$ ${eventoAtual.valorIngresso.toStringAsFixed(2).replaceAll('.', ',')}';
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalhes do evento'),
        actions: [
          IconButton(
            icon: const Icon(Icons.ios_share),
            tooltip: 'Enviar convite',
            onPressed: () => _enviarConvite(context, eventoAtual),
          ),
          if (isOwner) ...[
            IconButton(
              icon: const Icon(Icons.edit),
              tooltip: 'Editar evento',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => EditEventPage(evento: eventoAtual),
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Excluir evento',
              onPressed: () => _confirmarExclusao(context, eventoAtual),
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
              child: EventImage(url: eventoAtual.imagemEvento),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    eventoAtual.nomeEvento,
                    style: Theme.of(context).textTheme.headlineSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  if (eventoAtual.isPrivate) ...[
                    const SizedBox(height: 8),
                    const Chip(
                      avatar: Icon(Icons.lock_outline, size: 18),
                      label: Text('Evento privado'),
                    ),
                  ],
                  const SizedBox(height: 16),
                  _InfoLine(
                    icon: Icons.calendar_month,
                    text: eventoAtual.dataHoraFormatada,
                  ),
                  const SizedBox(height: 10),
                  _InfoLine(
                    icon: Icons.location_on_outlined,
                    text: eventoAtual.localEvento,
                  ),
                  if (eventoAtual.enderecoEvento.trim().isNotEmpty) ...[
                    const SizedBox(height: 10),
                    _InfoLine(
                      icon: Icons.pin_drop_outlined,
                      text: eventoAtual.enderecoEvento,
                    ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: () => _verNoMapa(context, eventoAtual),
                        icon: const Icon(Icons.map_outlined),
                        label: const Text('Ver no mapa'),
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),
                  _InfoLine(
                    icon: Icons.category_outlined,
                    text: eventoAtual.tipoEvento,
                  ),
                  const SizedBox(height: 10),
                  _InfoLine(
                    icon: Icons.confirmation_number_outlined,
                    text: valorIngressoFormatado,
                  ),
                  const SizedBox(height: 10),
                  _InfoLine(
                    icon: Icons.people_outline,
                    text: eventoAtual.vagasTotal == null
                        ? 'Vagas não informadas'
                        : '${eventoAtual.vagasRestantes} de ${eventoAtual.vagasTotal} vagas disponíveis',
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Descrição',
                    style: Theme.of(context).textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(eventoAtual.descricaoEvento),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: !isOwner && eventoAtual.temVagas
                          ? () async {
                              if (!isLoggedIn) {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const LoginPage(),
                                  ),
                                );
                                return;
                              }
                              final mensagem = await context
                                  .read<EventoProvider>()
                                  .participarDoEvento(eventoAtual);
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
                            : !isLoggedIn
                            ? 'Entrar para se inscrever'
                            : eventoAtual.temVagas
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

  Future<void> _verNoMapa(BuildContext context, Evento eventoAtual) async {
    final query = Uri.encodeComponent(eventoAtual.enderecoEvento);
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

  Future<void> _enviarConvite(BuildContext context, Evento eventoAtual) async {
    final ingresso = eventoAtual.valorIngresso == 0
        ? 'Gratuito'
        : 'R\$ ${eventoAtual.valorIngresso.toStringAsFixed(2).replaceAll('.', ',')}';
    final convite = [
      'Você está convidado para ${eventoAtual.nomeEvento}!',
      'Data: ${eventoAtual.dataHoraFormatada}',
      'Local: ${eventoAtual.localEvento}',
      if (eventoAtual.enderecoEvento.trim().isNotEmpty)
        'Endereço: ${eventoAtual.enderecoEvento}',
      'Ingresso: $ingresso',
      if (eventoAtual.isPrivate && eventoAtual.linkCompartilhamento != null)
        'Acesse e inscreva-se pelo link: ${eventoAtual.linkCompartilhamento}',
    ].join('\n');

    await SharePlus.instance.share(
      ShareParams(text: convite, subject: 'Convite: ${eventoAtual.nomeEvento}'),
    );
  }

  Future<void> _confirmarExclusao(
    BuildContext context,
    Evento eventoAtual,
  ) async {
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
    final erro = await context.read<EventoProvider>().excluirEvento(
      eventoAtual,
    );
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
