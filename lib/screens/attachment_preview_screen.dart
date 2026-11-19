// Preview sebelum kirim seperti WhatsApp: gambar/video langsung tampil,
// dokumen tampil sebagai kartu file, user bisa menulis pesan (caption)
// lalu memilih Kirim atau Batal. Return caption (String) saat kirim,
// null saat batal.
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';

import '../utils/attachment_kind.dart';
import '../widgets/attachment_card.dart';

class AttachmentPreviewScreen extends StatefulWidget {
  final Uint8List bytes;
  final String fileName;

  const AttachmentPreviewScreen({
    super.key,
    required this.bytes,
    required this.fileName,
  });

  @override
  State<AttachmentPreviewScreen> createState() =>
      _AttachmentPreviewScreenState();
}

class _AttachmentPreviewScreenState extends State<AttachmentPreviewScreen> {
  final _captionCtrl = TextEditingController();
  late final AttachmentInfo _info;
  VideoPlayerController? _video;
  bool _videoFailed = false;

  int get _ukuran => widget.bytes.length;

  @override
  void initState() {
    super.initState();
    _info = AttachmentInfo.fromName(widget.fileName);
    if (_info.kind == AttachmentKind.video) _siapkanVideo();
  }

  Future<void> _siapkanVideo() async {
    try {
      // video_player butuh file fisik, tulis bytes ke cache dulu.
      final dir = await getTemporaryDirectory();
      final safe = widget.fileName.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
      final file = File('${dir.path}${Platform.pathSeparator}preview_$safe');
      await file.writeAsBytes(widget.bytes);
      final ctrl = VideoPlayerController.file(file);
      await ctrl.initialize();
      if (!mounted) return;
      setState(() => _video = ctrl);
      await ctrl.play();
    } catch (_) {
      if (mounted) setState(() => _videoFailed = true);
    }
  }

  @override
  void dispose() {
    _captionCtrl.dispose();
    _video?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(
          'Kirim ${_info.kind == AttachmentKind.image ? 'gambar' : 'lampiran'}',
          style: const TextStyle(fontSize: 15),
        ),
      ),
      body: Column(
        children: [
          Expanded(child: _preview()),
          Padding(
            padding: EdgeInsets.fromLTRB(
                16, 8, 16, MediaQuery.paddingOf(context).bottom + 12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _captionCtrl,
                    maxLines: 1,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Tulis pesan (opsional)...',
                      hintStyle: const TextStyle(color: Colors.white54),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.08),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(26),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                CircleAvatar(
                  radius: 24,
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white, size: 22),
                    onPressed: () =>
                        Navigator.of(context).pop(_captionCtrl.text),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _preview() {
    switch (_info.kind) {
      case AttachmentKind.image:
        return Center(
          child: InteractiveViewer(
            maxScale: 4,
            child: Image.memory(widget.bytes, fit: BoxFit.contain),
          ),
        );
      case AttachmentKind.video:
        final v = _video;
        if (v == null || !v.value.isInitialized) {
          return Center(
            child: _videoFailed
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(_info.icon, size: 64, color: _info.color),
                      const SizedBox(height: 12),
                      Text(
                        '${widget.fileName}\nVideo • ${AttachmentInfo.formatSize(_ukuran)}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ],
                  )
                : const CircularProgressIndicator(),
          );
        }
        return Center(
          child: AspectRatio(
            aspectRatio: v.value.aspectRatio,
            child: GestureDetector(
              onTap: () => setState(() {
                v.value.isPlaying ? v.pause() : v.play();
              }),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  VideoPlayer(v),
                  Icon(
                    v.value.isPlaying ? Icons.pause : Icons.play_arrow,
                    size: 56,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ],
              ),
            ),
          ),
        );
      case AttachmentKind.audio:
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(_info.icon, size: 64, color: _info.color),
              const SizedBox(height: 12),
              Text(
                widget.fileName,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 15),
              ),
              Text(
                '${_info.label} • ${AttachmentInfo.formatSize(_ukuran)}',
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ],
          ),
        );
      default:
        // Dokumen & file lain: kartu besar di tengah.
        return Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 32),
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFF16233B),
              borderRadius: BorderRadius.circular(14),
            ),
            child: AttachmentDocCard(
              name: widget.fileName,
              info: _info,
              sizeBytes: _ukuran,
              background: Colors.white.withValues(alpha: 0.06),
              textPrimary: Colors.white,
              textSecondary: Colors.white60,
            ),
          ),
        );
    }
  }
}
