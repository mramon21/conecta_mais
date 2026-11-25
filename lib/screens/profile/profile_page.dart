import 'package:cached_network_image/cached_network_image.dart';
import 'package:conecta_mais/auth/auth_provider.dart';
import 'package:conecta_mais/screens/pages/create_event_page.dart';
import 'package:conecta_mais/screens/profile/edit_profile_page.dart';
import 'package:conecta_mais/screens/profile/organizer_page.dart';
import 'package:conecta_mais/screens/profile/my_events_page.dart';
import 'package:conecta_mais/screens/profile/my_created_events_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    final isOrganizer = auth.role == UserRole.manager;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Perfil')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 44,
                          backgroundImage: user?.photoUrl?.isNotEmpty == true
                              ? CachedNetworkImageProvider(user!.photoUrl!)
                              : null,
                          child: user?.photoUrl?.isNotEmpty == true
                              ? null
                              : const Icon(Icons.person, size: 44),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          user?.nome ?? 'Usuário',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user?.email ?? 'E-mail não disponível',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 8),
                  child: Text(
                    'Minha conta',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Card(
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.edit_outlined),
                        title: const Text('Editar perfil'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const EditProfilePage(),
                          ),
                        ),
                      ),
                      const Divider(height: 1, indent: 56),
                      ListTile(
                        leading: const Icon(Icons.event_available_outlined),
                        title: const Text('Eventos que estou participando'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const MyEventsPage(),
                          ),
                        ),
                      ),
                      if (isOrganizer) ...[
                        const Divider(height: 1, indent: 56),
                        ListTile(
                          leading: const Icon(Icons.event_note_outlined),
                          title: const Text('Eventos que criei'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const MyCreatedEventsPage(),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                if (!isOrganizer && user?.solicitacaoOrganizador == true)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      'Preencha o formulário para liberar a criação de eventos.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: colorScheme.onSurfaceVariant),
                    ),
                  ),
                SizedBox(
                  height: 52,
                  child: FilledButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => isOrganizer
                            ? const CreateEventPage()
                            : const OrganizerPage(),
                      ),
                    ),
                    icon: Icon(
                      isOrganizer ? Icons.add : Icons.star_outline,
                    ),
                    label: Text(
                      isOrganizer
                          ? 'Criar um novo evento'
                          : user?.solicitacaoOrganizador == true
                          ? 'Preencher formulário'
                          : 'Quero ser organizador',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
