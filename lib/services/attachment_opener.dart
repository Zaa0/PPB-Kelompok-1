// Membuka lampiran seperti WhatsApp: file diunduh ke perangkat lalu
// dibuka dengan aplikasi bawaan (viewer galeri untuk gambar, pembaca
// PDF untuk dokumen). Di web cukup dibuka di tab baru.
import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

class AttachmentOpener {
  /// Unduh lampiran dari server lalu buka. Return pesan error, atau
  /// null kalau sukses.
  static Future<String?> downloadAndOpen(String url, String fileName) async {
    if (kIsWeb) {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return null;
      }
      return 'Tidak bisa membuka lampiran di browser.';
    }

    try {
      final res = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 30));
      if (res.statusCode >= 400) {
        return 'Gagal mengunduh lampiran (kode ${res.statusCode}).';
      }

      // Simpan dengan nama asli ke folder sementara perangkat.
      final dir = await getTemporaryDirectory();
      final safeName = fileName.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
      final file = File('${dir.path}${Platform.pathSeparator}$safeName');
      await file.writeAsBytes(res.bodyBytes);

      final result = await OpenFilex.open(file.path);
      if (result.type != ResultType.done) {
        // Di Android gambar/pdf kadang tidak ada aplikasi pembaca.
        return result.message;
      }
      return null;
    } catch (_) {
      return 'Tidak bisa terhubung ke server untuk mengunduh lampiran.';
    }
  }
}
