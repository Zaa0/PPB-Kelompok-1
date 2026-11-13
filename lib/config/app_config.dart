import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;

// URL dasar API. Bisa dioverride lewat --dart-define=API_URL=...,
// berguna saat demo pakai HP fisik (pakai IP LAN laptop).
const kApiUrlOverride = String.fromEnvironment('API_URL');

String apiBaseUrl() {
  if (kApiUrlOverride.isNotEmpty) return kApiUrlOverride;
  if (kIsWeb) return 'http://localhost:8000/api';
  // Emulator Android melihat localhost laptop lewat 10.0.2.2.
  if (defaultTargetPlatform == TargetPlatform.android) {
    return 'http://10.0.2.2:8000/api';
  }
  return 'http://localhost:8000/api';
}
