// Penampil lampiran layar penuh seperti WhatsApp: gambar bisa di-zoom,
// ada tombol unduh. Untuk dokumen, unduh + buka lewat AttachmentOpener.
import 'package:flutter/material.dart';

import '../services/attachment_opener.dart';
import '../utils/attachment_kind.dart';

class AttachmentViewerScreen extends StatelessWidget {
  final String url;
  final String fileName;
  final bool isImage;

  const AttachmentViewerScreen({
    super.key,
    required this.url,
    required this.fileName,
    required this.isImage,
  });

  Future<void> _unduh(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final nav = Navigator.of(context);
    messenger.showSnackBar(
      const SnackBar(content: Text('Mengunduh lampiran...'), duration: Duration(seconds: 2)),
    );
    final error = await AttachmentOpener.downloadAndOpen(url, fileName);
    messenger.hideCurrentSnackBar();
    if (error != null) {
      messenger.showSnackBar(SnackBar(content: Text(error)));
    } else if (!isImage) {
      // Untuk gambar viewer galeri sudah terbuka otomatis; dokumen juga.
      nav.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(
          fileName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 15),
        ),
        actions: [
          IconButton(
            tooltip: 'Unduh',
            icon: const Icon(Icons.download_outlined),
            onPressed: () => _unduh(context),
          ),
        ],
      ),
      body: Center(
        child: isImage
            ? InteractiveViewer(
                maxScale: 4,
                child: Image.network(
                  url,
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, progress) =>
                      progress == null
                          ? child
                          : const Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                  errorBuilder: (_, _, _) => const Text(
                    'Lampiran gagal dimuat',
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Builder(builder: (context) {
                    final info = AttachmentInfo.fromName(fileName);
                    return Icon(info.icon, size: 72, color: info.color);
                  }),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      fileName,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: () => _unduh(context),
                    icon: const Icon(Icons.download_outlined),
                    label: const Text('Unduh & Buka'),
                  ),
                ],
              ),
      ),
    );
  }
}
