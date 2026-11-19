// Jenis lampiran dideteksi dari ekstensi nama file, lalu dipakai untuk
// memilih ikon, warna, dan label seperti WhatsApp (PDF merah, APK hijau,
// video, audio, arsip, dokumen Office, dll).
import 'package:flutter/material.dart';

enum AttachmentKind { image, video, audio, pdf, doc, sheet, slide, archive, apk, other }

class AttachmentInfo {
  final AttachmentKind kind;
  final IconData icon;
  final Color color; // warna ikon kartu dokumen
  final String label; // tulisan jenis: PDF / APK / Video, dll

  const AttachmentInfo({
    required this.kind,
    required this.icon,
    required this.color,
    required this.label,
  });

  static const _pdf = AttachmentInfo(
    kind: AttachmentKind.pdf,
    icon: Icons.picture_as_pdf,
    color: Color(0xFFE53935),
    label: 'PDF',
  );
  static const _doc = AttachmentInfo(
    kind: AttachmentKind.doc,
    icon: Icons.description,
    color: Color(0xFF1E88E5),
    label: 'DOC',
  );
  static const _sheet = AttachmentInfo(
    kind: AttachmentKind.sheet,
    icon: Icons.table_chart,
    color: Color(0xFF43A047),
    label: 'SHEET',
  );
  static const _slide = AttachmentInfo(
    kind: AttachmentKind.slide,
    icon: Icons.slideshow,
    color: Color(0xFFFB8C00),
    label: 'SLIDE',
  );
  static const _archive = AttachmentInfo(
    kind: AttachmentKind.archive,
    icon: Icons.folder_zip_outlined,
    color: Color(0xFFF6BF26),
    label: 'ZIP',
  );
  static const _apk = AttachmentInfo(
    kind: AttachmentKind.apk,
    icon: Icons.android,
    color: Color(0xFF3DDC84),
    label: 'APK',
  );
  static const _video = AttachmentInfo(
    kind: AttachmentKind.video,
    icon: Icons.play_circle_fill,
    color: Color(0xFF7E57C2),
    label: 'Video',
  );
  static const _audio = AttachmentInfo(
    kind: AttachmentKind.audio,
    icon: Icons.graphic_eq,
    color: Color(0xFFEC407A),
    label: 'Audio',
  );
  static const _image = AttachmentInfo(
    kind: AttachmentKind.image,
    icon: Icons.image_outlined,
    color: Color(0xFF26A69A),
    label: 'Gambar',
  );
  static const _other = AttachmentInfo(
    kind: AttachmentKind.other,
    icon: Icons.insert_drive_file,
    color: Color(0xFF78909C),
    label: 'File',
  );

  /// Deteksi jenis dari nama file; kalau nama tidak punya ekstensi
  /// (misal pesan lama bernama "lampiran"), coba dari URL lampiran yang
  /// selalu berakhiran ekstensi asli (.m4a, .pdf, .mp4, dst).
  static AttachmentInfo detect({String? name, String? url}) {
    final dariNama = fromName(name);
    if (dariNama.kind != AttachmentKind.other || name == null) return dariNama;
    // Nama tanpa ekstensi: pakai URL sebagai sumber jenis file.
    if (url == null || url.isEmpty) return dariNama;
    return fromName(url.split('?').first.split('/').last);
  }

  /// Deteksi dari nama file (ekstensi). Aman dipanggil dengan nama apa pun.
  static AttachmentInfo fromName(String? name) {
    final ext =
        (name ?? '').split('.').last.toLowerCase().trim();
    switch (ext) {
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
      case 'webp':
      case 'bmp':
      case 'heic':
        return _image;
      case 'mp4':
      case 'mov':
      case 'avi':
      case 'mkv':
      case '3gp':
      case 'webm':
        return _video;
      case 'mp3':
      case 'm4a':
      case 'aac':
      case 'wav':
      case 'ogg':
      case 'amr':
        return _audio;
      case 'pdf':
        return _pdf;
      case 'doc':
      case 'docx':
      case 'txt':
      case 'rtf':
      case 'odt':
        return _doc;
      case 'xls':
      case 'xlsx':
      case 'csv':
      case 'ods':
        return _sheet;
      case 'ppt':
      case 'pptx':
      case 'odp':
        return _slide;
      case 'zip':
      case 'rar':
      case '7z':
      case 'tar':
      case 'gz':
        return _archive;
      case 'apk':
        return _apk;
      default:
        return _other;
    }
  }

  /// Ukuran file dalam format pendek: 10 kB, 2.4 MB, dst.
  static String formatSize(num bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(bytes < 10240 ? 1 : 0)} kB';
    }
    return '${(bytes / 1024 / 1024).toStringAsFixed(1)} MB';
  }
}
