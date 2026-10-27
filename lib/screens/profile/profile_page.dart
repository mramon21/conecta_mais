import 'package:cached_network_image/cached_network_image.dart';
import 'package:conecta_mais/auth/auth_provider.dart';
import 'package:conecta_mais/screens/pages/create_event_page.dart';
import 'package:conecta_mais/screens/profile/edit_profile_page.dart';
import 'package:conecta_mais/screens/profile/organizer_page.dart';
import 'package:conecta_mais/screens/profile/my_events_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    final isOrganizer = auth.role == UserRole.manager;
    return Scaffold(
      appBar: AppBar(title: const Text('Perfil')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 50,
              backgroundImage: user?.photoUrl?.isNotEmpty == true
                  ? CachedNetworkImageProvider(user!.photoUrl!)
                  : null,
              child: user?.photoUrl?.isNotEmpty == true
                  ? null
                  : const Icon(Icons.person, size: 50),
            ),
            const SizedBox(height: 16),
            Text(
              user?.nome ?? 'Usuário',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              user?.email ?? 'E-mail não disponível',
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const EditProfilePage()),
              ),
              icon: const Icon(Icons.edit),
              label: const Text('Editar perfil'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MyEventsPage()),
              ),
              icon: const Icon(Icons.event_available),
              label: const Text('Eventos que estou participando'),
            ),
            const SizedBox(height: 12),
            if (isOrganizer)
              ElevatedButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CreateEventPage()),
                ),
                child: const Text('Criar um novo evento'),
              )
            else if (user?.solicitacaoOrganizador == true)
              Column(
                children: [
                  const Text(
                    'Preencha o formulário para liberar a criação de eventos.',
                  ),
                  TextButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const OrganizerPage()),
                    ),
                    child: const Text('Preencher formulário'),
                  ),
                ],
              )
            else
              ElevatedButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const OrganizerPage()),
                ),
                child: const Text('Quero ser organizador'),
              ),
          ],
        ),
      ),
    );
  }
}
