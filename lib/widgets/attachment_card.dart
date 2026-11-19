// Kartu lampiran seperti WhatsApp: ikon berwarna sesuai jenis file
// (PDF merah, APK hijau, dst), nama file asli, dan info ukuran.
// Dipakai di bubble chat maupun layar preview sebelum kirim.
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:get_video_thumbnail/get_video_thumbnail.dart';
import 'package:get_video_thumbnail/index.dart' show ImageFormat;

import '../utils/attachment_kind.dart';

/// Kartu dokumen: PDF, Word, APK, ZIP, atau file lain.
class AttachmentDocCard extends StatelessWidget {
  final String name;
  final AttachmentInfo info;
  final int? sizeBytes;
  final Color background;
  final Color textPrimary;
  final Color textSecondary;

  const AttachmentDocCard({
    super.key,
    required this.name,
    required this.info,
    this.sizeBytes,
    required this.background,
    required this.textPrimary,
    required this.textSecondary,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: info.color.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(info.icon, color: info.color, size: 26),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  sizeBytes == null
                      ? info.label
                      : '${info.label} • ${AttachmentInfo.formatSize(sizeBytes!)}',
                  style: TextStyle(fontSize: 11.5, color: textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Kartu video: thumbnail frame pertama + tombol play di tengah.
/// Thumbnail diambil dari server (Android); di web pakai ikon saja.
class AttachmentVideoCard extends StatefulWidget {
  final String? url;
  final Uint8List? localBytes;
  final String name;
  final int? sizeBytes;
  final Color background;
  final Color textPrimary;
  final Color textSecondary;

  const AttachmentVideoCard({
    super.key,
    this.url,
    this.localBytes,
    required this.name,
    this.sizeBytes,
    required this.background,
    required this.textPrimary,
    required this.textSecondary,
  });

  @override
  State<AttachmentVideoCard> createState() => _AttachmentVideoCardState();
}

class _AttachmentVideoCardState extends State<AttachmentVideoCard> {
  Uint8List? _thumb;

  @override
  void initState() {
    super.initState();
    _ambilThumbnail();
  }

  Future<void> _ambilThumbnail() async {
    if (kIsWeb || widget.url == null) return;
    try {
      final thumb = await VideoThumbnail.thumbnailData(
        video: widget.url!,
        imageFormat: ImageFormat.JPEG,
        quality: 60,
      );
      if (mounted && thumb.isNotEmpty) setState(() => _thumb = thumb);
    } catch (_) {
      // Thumbnail gagal - kartu tetap tampil dengan ikon play.
    }
  }

  @override
  Widget build(BuildContext context) {
    final meta = widget.sizeBytes == null
        ? 'Video'
        : 'Video • ${AttachmentInfo.formatSize(widget.sizeBytes!)}';
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Container(
        color: widget.background,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                if (_thumb != null)
                  Image.memory(_thumb!,
                      width: 250, height: 180, fit: BoxFit.cover)
                else
                  Container(
                    width: 250,
                    height: 150,
                    color: Colors.black.withValues(alpha: 0.25),
                    child: const Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.45),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.play_arrow_rounded,
                      color: Colors.white, size: 40),
                ),
              ],
            ),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: widget.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(meta,
                      style: TextStyle(
                          fontSize: 11.5, color: widget.textSecondary)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
