import 'package:conecta_mais/auth/auth_provider.dart';
import 'package:conecta_mais/screens/auth/login_page.dart';
import 'package:conecta_mais/screens/pages/all_events_page.dart';
import 'package:conecta_mais/screens/pages/create_event_page.dart';
import 'package:conecta_mais/screens/pages/details_event_page.dart';
import 'package:conecta_mais/screens/pages/nearby_events_page.dart';
import 'package:conecta_mais/screens/profile/profile_page.dart';
import 'package:conecta_mais/screens/profile/organizer_page.dart';
import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:conecta_mais/widgets/evento_card.dart';
import 'package:conecta_mais/screens/models/evento.dart';
import 'package:provider/provider.dart';
import 'package:conecta_mais/providers/evento_provider.dart';
import 'package:conecta_mais/providers/theme_provider.dart';
import 'package:conecta_mais/models/event_category.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _searchController = TextEditingController();
  bool _mostrarTodasCategorias = false;

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
    final themeProvider = context.watch<AppThemeProvider>();
    final colorScheme = Theme.of(context).colorScheme;
    final scaledBodyTextSize = MediaQuery.textScalerOf(context).scale(16);

    return Scaffold(
      endDrawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            Container(
              alignment: Alignment.bottomLeft,
              constraints: BoxConstraints(
                minHeight: 100 + scaledBodyTextSize - 16,
              ),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colorScheme.primary),
              child: const Text('Menu', style: TextStyle(fontSize: 24)),
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
              leading: const Icon(Icons.map_outlined),
              title: const Text('Eventos na proximidade'),
              onTap: () {
                final navigator = Navigator.of(context);
                navigator.pop();
                navigator.push(
                  MaterialPageRoute(builder: (_) => const NearbyEventsPage()),
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
              leading: const Icon(Icons.brightness_6_outlined),
              title: const Text('Tema'),
              subtitle: Text(_themeModeLabel(themeProvider.themeMode)),
              onTap: () => _selecionarTema(context, themeProvider),
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
                  Navigator.pop(context);
                  _confirmLogout(authProvider);
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

  Future<void> _confirmLogout(AuthProvider authProvider) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Sair da conta?'),
        content: const Text(
          'Você precisará entrar novamente para acessar seu perfil.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Sair'),
          ),
        ],
      ),
    );
    if (shouldLogout != true || !mounted) return;

    try {
      await authProvider.logout();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Não foi possível sair da conta: $error'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  String _themeModeLabel(ThemeMode mode) => switch (mode) {
    ThemeMode.system => 'Seguir o sistema',
    ThemeMode.light => 'Claro',
    ThemeMode.dark => 'Escuro',
  };

  Future<void> _selecionarTema(
    BuildContext context,
    AppThemeProvider themeProvider,
  ) async {
    final mode = await showDialog<ThemeMode>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Escolher tema'),
        content: RadioGroup<ThemeMode>(
          groupValue: themeProvider.themeMode,
          onChanged: (mode) => Navigator.pop(dialogContext, mode),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<ThemeMode>(
                value: ThemeMode.system,
                title: Text('Seguir o sistema'),
              ),
              RadioListTile<ThemeMode>(
                value: ThemeMode.light,
                title: Text('Claro'),
              ),
              RadioListTile<ThemeMode>(
                value: ThemeMode.dark,
                title: Text('Escuro'),
              ),
            ],
          ),
        ),
      ),
    );
    if (mode == null || !context.mounted) return;
    try {
      await themeProvider.setThemeMode(mode);
    } on StateError catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.message.toString()),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  Widget _buildBody(EventoProvider provider) {
    final colorScheme = Theme.of(context).colorScheme;
    final scaledBodyTextSize = MediaQuery.textScalerOf(context).scale(16);

    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: colorScheme.error, size: 48),
            const SizedBox(height: 16),
            Text(
              provider.error!,
              style: TextStyle(color: colorScheme.onSurface),
              textAlign: TextAlign.center,
            ),
            TextButton(
              onPressed: () {
                provider.retry();
              },
              child: Text(
                'Tentar novamente',
                style: TextStyle(color: colorScheme.primary),
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
    final categoriasComEventos = EventCategory.values
        .where(
          (categoria) =>
              provider.eventosPorCategoria(categoria.label).isNotEmpty,
        )
        .toList();
    final categoriasVisiveis = _mostrarTodasCategorias
        ? categoriasComEventos
        : categoriasComEventos.take(3).toList();

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          pinned: false,
          floating: false,
          toolbarHeight: 56 + scaledBodyTextSize - 16,
          title: const Text(
            'Conecta +',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
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
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    hintText: 'Pesquisar eventos...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(20)),
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {});
                  },
                ),
              ),

              if (events.isEmpty)
                Padding(
                  padding: EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Icon(
                        Icons.event_busy,
                        color: colorScheme.onSurface.withValues(alpha: 0.3),
                        size: 48,
                      ),
                      SizedBox(height: 12),
                      Text(
                        'Nenhum evento encontrado para sua busca.',
                        style: TextStyle(
                          color: colorScheme.onSurface.withValues(alpha: 0.6),
                          fontSize: 16,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

              if (provider.eventosAtivos.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: CarouselSlider(
                    options: CarouselOptions(
                      height: 180,
                      autoPlay: true,
                      autoPlayInterval: const Duration(seconds: 5),
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
                            color: colorScheme.surfaceContainerHighest,
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
                ),

              SizedBox(
                height: 48 + (scaledBodyTextSize - 16),
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: filtros.keys.map((chave) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(chave),
                        selected: filtros[chave]!,
                        labelStyle: TextStyle(color: colorScheme.onSurface),
                        backgroundColor: colorScheme.surfaceContainerHighest,
                        selectedColor: colorScheme.primaryContainer,
                        checkmarkColor: colorScheme.onPrimaryContainer,
                        onSelected: (selected) {
                          setState(() => filtros[chave] = selected);
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),

              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Divider(height: 1),
              ),

              _buildSecaoHorizontal(
                titulo: 'Todos os eventos',
                listaEventos: events,
              ),

              if (provider.eventosFimDeSemana.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: _buildSecaoHorizontal(
                    titulo: 'Encontre o que fazer no fim de semana',
                    listaEventos: provider.eventosFimDeSemana,
                  ),
                ),

              ...categoriasVisiveis.map((categoria) {
                return Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: _buildSecaoHorizontal(
                    titulo: 'Eventos de ${categoria.label} perto de você',
                    listaEventos: provider.eventosPorCategoria(categoria.label),
                  ),
                );
              }),

              if (categoriasComEventos.length > 3)
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _mostrarTodasCategorias = !_mostrarTodasCategorias;
                    });
                  },
                  icon: Icon(
                    _mostrarTodasCategorias
                        ? Icons.expand_less
                        : Icons.expand_more,
                  ),
                  label: Text(
                    _mostrarTodasCategorias
                        ? 'Mostrar menos categorias'
                        : 'Ver mais categorias',
                  ),
                ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBannerFallback(Evento evento) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      color: colorScheme.surfaceContainerHighest,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Text(
            evento.nomeEvento,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 50, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  Widget _buildSecaoHorizontal({
    required String titulo,
    required List<Evento> listaEventos,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final scaledBodyTextSize = MediaQuery.textScalerOf(context).scale(16);

    if (listaEventos.isEmpty) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  titulo,
                  style: TextStyle(
                    color: colorScheme.onSurface,
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
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: const Size(0, 40),
                ),
                child: Text(
                  'Ver tudo',
                  style: TextStyle(color: colorScheme.primary),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 280 + (scaledBodyTextSize - 16) * 8,
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
