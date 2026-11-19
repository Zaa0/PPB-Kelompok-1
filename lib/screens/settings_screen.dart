import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';

// Halaman Pengaturan: tema, notifikasi, bersihkan data, tentang.
// Dipakai sebagai tab kedua (narrow) atau panel (layout lebar).
class SettingsBody extends StatelessWidget {
  const SettingsBody({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              'Pengaturan',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            _judul(context, 'Tampilan'),
            Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Tema aplikasi'),
                    const SizedBox(height: 10),
                    SegmentedButton<ThemeMode>(
                      segments: const [
                        ButtonSegment(
                          value: ThemeMode.system,
                          icon: Icon(Icons.settings_suggest_outlined, size: 18),
                          label: Text('Sistem'),
                        ),
                        ButtonSegment(
                          value: ThemeMode.light,
                          icon: Icon(Icons.light_mode_outlined, size: 18),
                          label: Text('Terang'),
                        ),
                        ButtonSegment(
                          value: ThemeMode.dark,
                          icon: Icon(Icons.dark_mode_outlined, size: 18),
                          label: Text('Gelap'),
                        ),
                      ],
                      style: ButtonStyle(
                        padding: const WidgetStatePropertyAll(
                          EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                        ),
                        visualDensity: VisualDensity.compact,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        textStyle: const WidgetStatePropertyAll(
                          TextStyle(fontSize: 12),
                        ),
                      ),
                      selected: {app.themeMode},
                      onSelectionChanged: (pilihan) =>
                          app.setThemeMode(pilihan.first),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            _judul(context, 'Notifikasi'),
            Card(
              margin: EdgeInsets.zero,
              child: SwitchListTile(
                value: app.notifEnabled,
                onChanged: (v) => app.setNotifEnabled(v),
                title: const Text('Notifikasi pesan baru'),
                subtitle: const Text(
                  'Muncul saat ada pesan di room lain. '
                  'Bunyi mengikuti pengaturan perangkat.',
                ),
              ),
            ),
            const SizedBox(height: 16),
            _judul(context, 'Privasi & Keamanan'),
            Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.lock_outline,
                          color: Color(0xFF38BDF8),
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Identitas dilindungi',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Yang tampil di chat hanya alias kamu, bukan nomor '
                      'pribadi. Akun asli tetap tercatat di server demi '
                      'ketertiban. Login dilindungi token dan password '
                      'tersimpan terenkripsi.',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            _judul(context, 'Tentang'),
            Card(
              margin: EdgeInsets.zero,
              child: ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('Tentang UniTalk'),
                subtitle: const Text('Versi 1.0.0 - Kelompok 1 UMRAH'),
                onTap: () => showAboutDialog(
                  context: context,
                  applicationIcon: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.asset(
                      'assets/icon/icon.png',
                      width: 48,
                      height: 48,
                      fit: BoxFit.cover,
                    ),
                  ),
                  applicationName: 'UniTalk',
                  applicationVersion: '1.0.0',
                  applicationLegalese:
                      'Kelompok 1 - Pemrograman Perangkat Bergerak, '
                      'Teknik Informatika UMRAH',
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _judul(BuildContext context, String teks) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6, left: 4),
      child: Text(
        teks.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          letterSpacing: 1,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

}
