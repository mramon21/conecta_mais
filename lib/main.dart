import 'package:conecta_mais/providers/evento_provider.dart';
import 'package:conecta_mais/providers/theme_provider.dart';
import 'package:conecta_mais/auth/auth_provider.dart';
import 'package:conecta_mais/auth/auth_gate.dart';
import 'package:conecta_mais/screens/pages/shared_event_page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initializeDateFormatting('pt_BR', null);

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  final themeProvider = await AppThemeProvider.load();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => EventoProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider.value(value: themeProvider),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeMode = context.watch<AppThemeProvider>().themeMode;
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      theme: _buildTheme(Brightness.light),
      darkTheme: _buildTheme(Brightness.dark),
      home: const AuthGate(),
      onGenerateRoute: (settings) {
        final eventId = _eventIdFromRoute(settings.name);
        if (eventId == null) return null;
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => SharedEventPage(eventId: eventId),
        );
      },
    );
  }

  String? _eventIdFromRoute(String? routeName) {
    if (routeName == null) return null;
    final uri = Uri.tryParse(routeName);
    if (uri == null) return null;
    final segments = uri.pathSegments;
    if (segments.length != 2 || segments.first != 'eventos') return null;
    return segments[1].isEmpty ? null : segments[1];
  }

  ThemeData _buildTheme(Brightness brightness) {
    const primaryColor = Color(0xFF7652BD);
    final isDark = brightness == Brightness.dark;
    final colorScheme = ColorScheme.fromSeed(
      seedColor: primaryColor,
      brightness: brightness,
      surface: isDark ? const Color(0xFF130B24) : const Color(0xFFFFFFFF),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: isDark
          ? const Color(0xFF060226)
          : const Color(0xFFF7F5FC),
      appBarTheme: AppBarTheme(
        backgroundColor: isDark
            ? const Color(0xFF060226)
            : const Color(0xFFF7F5FC),
        foregroundColor: colorScheme.onSurface,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        color: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
      drawerTheme: DrawerThemeData(
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
      ),
    );
  }
}
