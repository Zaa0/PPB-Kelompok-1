import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;

// URL dasar API. Bisa dioverride lewat --dart-define=API_URL=...
// kalau IP laptop berubah.
// IP laptop di WiFi (cek: ipconfig) - HP fisik menghubungi alamat ini.
const String kLaptopIp = '192.168.101.59';

const kApiUrlOverride = String.fromEnvironment('API_URL');

String apiBaseUrl() {
  if (kApiUrlOverride.isNotEmpty) return kApiUrlOverride;
  if (kIsWeb) return 'http://localhost:8000/api';
  // HP fisik & emulator Android: server di laptop lewat IP WiFi.
  // (10.0.2.2 hanya berlaku di emulator, tidak di HP beneran.)
  if (defaultTargetPlatform == TargetPlatform.android) {
    return 'http://$kLaptopIp:8000/api';
  }
  return 'http://localhost:8000/api';
}
