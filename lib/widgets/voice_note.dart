// Voice note seperti WhatsApp: tombol play/pause, gelombang sederhana,
// durasi dan posisi. File audio diputar langsung dari server.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

class VoiceNotePlayer extends StatefulWidget {
  final String url;
  final Color color; // warna ikon & slider (bubble saya vs orang lain)
  final Color waveformColor;

  const VoiceNotePlayer({
    super.key,
    required this.url,
    required this.color,
    required this.waveformColor,
  });

  @override
  State<VoiceNotePlayer> createState() => _VoiceNotePlayerState();
}

class _VoiceNotePlayerState extends State<VoiceNotePlayer> {
  AudioPlayer? _player;
  bool _loading = false;
  bool _error = false;

  StreamSubscription? _posSub;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  bool _playing = false;

  @override
  void dispose() {
    _posSub?.cancel();
    _player?.dispose();
    super.dispose();
  }

  Future<void> _toggle() async {
    if (_error) return;
    if (_player == null) {
      setState(() => _loading = true);
      try {
        final player = AudioPlayer();
        await player.setUrl(widget.url);
        _posSub = player.positionStream.listen((p) {
          if (mounted) setState(() => _position = p);
        });
        player.durationStream.listen((d) {
          if (mounted && d != null) setState(() => _duration = d);
        });
        player.playerStateStream.listen((s) {
          if (!mounted) return;
          setState(() => _playing = s.playing);
          if (s.processingState == ProcessingState.completed) {
            player.seek(Duration.zero);
            player.pause();
          }
        });
        _player = player;
        await player.play();
      } catch (_) {
        if (mounted) setState(() => _error = true);
      }
      if (mounted) setState(() => _loading = false);
      return;
    }
    if (_playing) {
      await _player!.pause();
    } else {
      await _player!.play();
    }
  }

  String _fmt(Duration d) {
    final s = d.inSeconds.clamp(0, 3599);
    return '${(s ~/ 60).toString().padLeft(1, '0')}:${(s % 60).toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final total = _duration > Duration.zero
        ? _duration
        : const Duration(seconds: 1);
    final progress =
        (_position.inMilliseconds / total.inMilliseconds).clamp(0.0, 1.0);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: _toggle,
          child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: widget.color.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            child: _loading
                ? const Padding(
                    padding: EdgeInsets.all(9),
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(
                    _error
                        ? Icons.error_outline
                        : (_playing ? Icons.pause : Icons.play_arrow),
                    size: 22,
                  ),
          ),
        ),
        const SizedBox(width: 8),
        // Gelombang sederhana: bar yang menyala sesuai posisi.
        SizedBox(
          width: 120,
          height: 24,
          child: CustomPaint(
            painter: _WavePainter(
              progress: progress,
              activeColor: widget.color,
              idleColor: widget.waveformColor,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          _fmt(_playing || _position > Duration.zero ? _position : _duration),
          style: const TextStyle(fontSize: 11.5),
        ),
      ],
    );
  }
}

class _WavePainter extends CustomPainter {
  final double progress;
  final Color activeColor;
  final Color idleColor;

  _WavePainter({
    required this.progress,
    required this.activeColor,
    required this.idleColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const bars = 24;
    final barWidth = size.width / bars / 2;
    final paintActive = Paint()..color = activeColor;
    final paintIdle = Paint()..color = idleColor;
    // Pola gelombang deterministik biar terlihat alami tapi konsisten.
    const heights = [6, 10, 14, 9, 18, 12, 8, 16, 20, 11, 7, 14, 19, 9, 13, 17, 8, 12, 16, 10, 6, 14, 18, 9];
    final activeUntil = progress * bars;
    for (var i = 0; i < bars; i++) {
      final h = heights[i].toDouble();
      final x = i * (size.width / bars);
      final rect = Rect.fromCenter(
        center: Offset(x + size.width / bars / 2, size.height / 2),
        width: barWidth,
        height: h,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(1.5)),
        i < activeUntil ? paintActive : paintIdle,
      );
    }
  }

  @override
  bool shouldRepaint(_WavePainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.activeColor != activeColor ||
      oldDelegate.idleColor != idleColor;
}
