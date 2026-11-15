import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'data/api_client.dart';
import 'data/local_repository.dart';
import 'screens/welcome_screen.dart';
import 'services/notifications.dart';
import 'state/app_state.dart';
import 'theme/chat_theme.dart';

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
    // Layanan notifikasi lokal (Android/Windows) + jalur balas cepat.
    onQuickReply = (roomId, pesan) {
      unawaited(app.replyFromNotification(roomId, pesan));
    };
    unawaited(initNotifications());
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
    final app = context.watch<AppState>();
    return AnimatedTheme(
      duration: const Duration(milliseconds: 250),
      data: Theme.of(context),
      child: MaterialApp(
        title: 'UniTalk',
        debugShowCheckedModeBanner: false,
        theme: UniTalkChatTheme.lightTheme,
        darkTheme: UniTalkChatTheme.darkTheme,
        themeMode: app.themeMode,
        initialRoute: '/',
        routes: {
          '/': (context) => const WelcomeScreen(),
        },
        builder: (context, child) {
          // Transisi pergantian tema berlangsung halus (tanpa kedipan).
          return AnimatedTheme(
            data: Theme.of(context),
            duration: const Duration(milliseconds: 250),
            child: child ?? const SizedBox.shrink(),
          );
        },
      ),
    );

  }
}
