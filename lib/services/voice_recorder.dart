// Rekam voice note seperti WhatsApp: minta izin mikrofon ke sistem
// (Android/iOS), rekam audio AAC, kembalikan bytes-nya untuk dikirim.
import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

class VoiceRecorder {
  final AudioRecorder _rec = AudioRecorder();
  DateTime? _mulai;

  /// Cek + minta izin mikrofon. Return true kalau diizinkan.
  Future<bool> cekIzin() async {
    try {
      return await _rec.hasPermission();
    } catch (_) {
      return false;
    }
  }

  Future<bool> mulai() async {
    if (!await cekIzin()) return false;
    final dir = await getTemporaryDirectory();
    final path =
        '${dir.path}${Platform.pathSeparator}vn-${DateTime.now().millisecondsSinceEpoch}.m4a';
    await _rec.start(
      const RecordConfig(encoder: AudioEncoder.aacLc, bitRate: 64000),
      path: path,
    );
    _mulai = DateTime.now();
    return true;
  }

  /// Selesai rekam; kembalikan (bytes, durasi detik) atau null bila gagal.
  Future<(Uint8List, int)?> selesai() async {
    final path = await _rec.stop();
    final durasi =
        _mulai == null ? 0 : DateTime.now().difference(_mulai!).inSeconds;
    _mulai = null;
    if (path == null) return null;
    final file = File(path);
    if (!await file.exists()) return null;
    final bytes = await file.readAsBytes();
    await file.delete();
    if (bytes.isEmpty) return null;
    return (bytes, durasi < 1 ? 1 : durasi);
  }

  /// Batal rekam; buang hasilnya.
  Future<void> batal() async {
    final path = await _rec.stop();
    _mulai = null;
    if (path != null) {
      final file = File(path);
      if (await file.exists()) await file.delete();
    }
  }

  Future<void> buang() async {
    try {
      if (await _rec.isRecording()) await batal();
    } catch (_) {}
  }
}
