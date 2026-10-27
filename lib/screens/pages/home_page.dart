import 'package:conecta_mais/auth/auth_provider.dart';
import 'package:conecta_mais/screens/auth/login_page.dart';
import 'package:conecta_mais/screens/pages/all_events_page.dart';
import 'package:conecta_mais/screens/pages/create_event_page.dart';
import 'package:conecta_mais/screens/pages/details_event_page.dart';
import 'package:conecta_mais/screens/profile/profile_page.dart';
import 'package:conecta_mais/screens/profile/organizer_page.dart';
import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:conecta_mais/widgets/evento_card.dart';
import 'package:conecta_mais/screens/models/evento.dart';
import 'package:provider/provider.dart';
import 'package:conecta_mais/providers/evento_provider.dart';
import 'package:conecta_mais/models/event_category.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _searchController = TextEditingController();

  Map<String, bool> filtros = {
    for (var cat in EventCategory.values) cat.label: false,
  };

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _abrirCriarEvento() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CreateEventPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final eventoProvider = context.watch<EventoProvider>();
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFF060226),
      endDrawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Color(0xFF9E77ED)),
              child: Text(
                'Menu',
                style: TextStyle(color: Colors.white, fontSize: 24),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Perfil'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => authProvider.isLoggedIn
                        ? const ProfilePage()
                        : const LoginPage(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.event),
              title: Text(
                authProvider.role == UserRole.manager
                    ? 'Criar Evento'
                    : 'Seja Organizador',
              ),
              onTap: () {
                Navigator.pop(context);
                if (authProvider.role == UserRole.manager) {
                  _abrirCriarEvento();
                } else {
                  if (!authProvider.isLoggedIn) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LoginPage(),
                      ),
                    );
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const OrganizerPage()),
                    );
                  }
                }
              },
            ),
            const ListTile(
              leading: Icon(Icons.support),
              title: Text('Suporte'),
            ),
            ListTile(
              leading: authProvider.isLoggedIn
                  ? const Icon(Icons.logout)
                  : const Icon(Icons.login),
              title: authProvider.isLoggedIn
                  ? const Text('Sair')
                  : const Text('Entrar'),
              onTap: () {
                if (authProvider.isLoggedIn) {
                  authProvider.logout();
                } else {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginPage()),
                  );
                }
              },
            ),
          ],
        ),
      ),
      body: _buildBody(eventoProvider),
    );
  }

  Widget _buildBody(EventoProvider provider) {
    if (provider.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF9E77ED)),
      );
    }

    if (provider.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text(
              provider.error!,
              style: const TextStyle(color: Colors.white),
              textAlign: TextAlign.center,
            ),
            TextButton(
              onPressed: () {
                provider.retry();
              },
              child: const Text(
                'Tentar novamente',
                style: TextStyle(color: Colors.blue),
              ),
            ),
          ],
        ),
      );
    }

    String searchQuery = _searchController.text;
    List<String> activeCategories = filtros.entries
        .where((e) => e.value)
        .map((e) => e.key)
        .toList();

    final events = provider.getEventosFiltrados(activeCategories, searchQuery);

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          pinned: false,
          floating: false,
          title: const Text('Conecta +'),
          leading: const Icon(Icons.calendar_month),
          actions: [
            Builder(
              builder: (context) => IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () => Scaffold.of(context).openEndDrawer(),
              ),
            ),
          ],
        ),
        SliverToBoxAdapter(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8),
                child: TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    hintText: 'Pesquisar eventos...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    setState(() {});
                  },
                ),
              ),

              if (events.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Icon(Icons.event_busy, color: Colors.white30, size: 48),
                      SizedBox(height: 12),
                      Text(
                        'Nenhum evento encontrado para sua busca.',
                        style: TextStyle(color: Colors.white60, fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

              CarouselSlider(
                options: CarouselOptions(
                  height: 180,
                  autoPlay: true,
                  autoPlayInterval: const Duration(seconds: 7),
                  enlargeCenterPage: true,
                  viewportFraction: 0.9,
                ),
                items: provider.eventosAtivos.map((evento) {
                  return InkWell(
                    key: ValueKey(evento.id ?? evento.nomeEvento),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DetailsEventPage(evento: evento),
                      ),
                    ),
                    child: Container(
                      width: MediaQuery.of(context).size.width,
                      margin: const EdgeInsets.symmetric(horizontal: 5),
                      decoration: BoxDecoration(
                        color: Colors.amber,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            evento.imagemEvento != null
                                ? EventImage(url: evento.imagemEvento)
                                : _buildBannerFallback(evento),
                            if (!evento.temVagas)
                              Align(
                                alignment: Alignment.topRight,
                                child: Container(
                                  margin: const EdgeInsets.all(10),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade700,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text(
                                    'ESGOTADO',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),

              Wrap(
                children: filtros.keys.map((chave) {
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Checkbox(
                        value: filtros[chave],
                        onChanged: (newValue) {
                          setState(() {
                            filtros[chave] = newValue ?? false;
                          });
                        },
                      ),
                      Text(chave, style: const TextStyle(color: Colors.white)),
                    ],
                  );
                }).toList(),
              ),

              const Divider(color: Colors.grey),

              _buildSecaoHorizontal(
                titulo: 'Todos os eventos',
                listaEventos: events,
              ),

              const SizedBox(height: 16),

              _buildSecaoHorizontal(
                titulo: 'Encontre o que fazer no fim de semana',
                listaEventos: provider.eventosFimDeSemana,
              ),
              const SizedBox(height: 16),

              ...filtros.keys.map((categoria) {
                return Column(
                  children: [
                    _buildSecaoHorizontal(
                      titulo: 'Eventos de $categoria perto de você',
                      listaEventos: provider.eventosPorCategoria(categoria),
                    ),
                    const SizedBox(height: 16),
                  ],
                );
              }),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBannerFallback(Evento evento) {
    return Container(
      color: Colors.amber,
      child: Center(
        child: Text(
          evento.nomeEvento,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildSecaoHorizontal({
    required String titulo,
    required List<Evento> listaEventos,
  }) {
    if (listaEventos.isEmpty) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  titulo,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AllEvents(listaEventos: listaEventos),
                  ),
                ),
                child: const Text(
                  'Ver tudo',
                  style: TextStyle(color: Colors.blueAccent),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 250,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            itemCount: listaEventos.length,
            itemBuilder: (context, index) {
              return Container(
                width: 300,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                child: EventoCard(evento: listaEventos[index]),
              );
            },
          ),
        ),
      ],
    );
  }
}
