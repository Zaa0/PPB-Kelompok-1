import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'data/api_client.dart';
import 'data/local_repository.dart';
import 'screens/welcome_screen.dart';
import 'state/app_state.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(UniTalkApp(state: await _loadAppState()));
}

Future<AppState> _loadAppState() async {
  try {
    // Muat data tersimpan (sesi, room, chat) sebelum aplikasi jalan.
    // ApiClient aktif = mode online; kalau server tidak bisa dihubungi,
    // aplikasi otomatis jalan offline dari cache.
    final repo = LocalRepository();
    await repo.init();
    final app = AppState(repository: repo, api: ApiClient());
    await app.restore();
    return app;
  } catch (_) {
    // Kalau penyimpanan lokal gagal (misal browser tanpa IndexedDB),
    // jalan tanpa persistensi supaya aplikasi tetap bisa dipakai.
    return AppState();
  }
}

class UniTalkApp extends StatelessWidget {
  // Kalau state belum disiapkan dari luar (misal main() yang restore data
  // tersimpan), state baru dibuat di memori. Ini juga yang dipakai test.
  final AppState? state;

  const UniTalkApp({super.key, this.state});

  @override
  Widget build(BuildContext context) {
    final app = state;
    if (app != null) {
      return ChangeNotifierProvider<AppState>.value(
        value: app,
        child: const _AppView(),
      );
    }
    return ChangeNotifierProvider<AppState>(
      create: (_) => AppState(),
      child: const _AppView(),
    );
  }
}

class _AppView extends StatelessWidget {
  const _AppView();

  @override
  Widget build(BuildContext context) {
    final scheme = ColorScheme.fromSeed(seedColor: const Color(0xFF2563EB));
    return MaterialApp(
      title: 'UniTalk',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: scheme,
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF6F8FC),
        appBarTheme: AppBarTheme(
          backgroundColor: scheme.surface,
          foregroundColor: scheme.onSurface,
          elevation: 0,
          centerTitle: false,
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.grey.shade200),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const WelcomeScreen(),
      },
    );
  }
}
