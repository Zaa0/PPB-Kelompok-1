import 'package:flutter/material.dart';
import '../models/room.dart';
import '../models/chat_message.dart';
import '../widgets/chat_bubble.dart';

// Layout: Scaffold + ListView + bottom Row (TextField + Button)
class ChatScreen extends StatefulWidget {
  final Room room;

  const ChatScreen({super.key, required this.room});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final List<ChatMessage> _pesan = List.from(dummyMessages);
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _kirim() {
    if (_controller.text.isEmpty) return;
    setState(() {
      _pesan.add(ChatMessage(
        pengirim: 'Saya',
        isi: _controller.text,
        jam: 'now',
        isMe: true,
      ));
      _controller.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.room.nama),
            Text(
              widget.room.kode,
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            color: Colors.amber.shade50,
            child: const Text(
              'Mode anonim aktif. Jaga etika diskusi.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12),
            ),
          ),
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _pesan.length,
                  itemBuilder: (context, i) =>
                      ChatBubble(message: _pesan[i]),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: const InputDecoration(
                        hintText: 'Tulis pesan anonim...',
                        prefixIcon: Icon(Icons.tag_faces),
                      ),
                      onSubmitted: (_) => _kirim(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _kirim,
                    style: FilledButton.styleFrom(
                      shape: const CircleBorder(),
                      padding: const EdgeInsets.all(12),
                    ),
                    child: const Icon(Icons.send, size: 20),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
