import 'package:flutter/material.dart';
import '../models/chat_message.dart';

// Layout: Align + Container (chat kiri/kanan)
class ChatBubble extends StatelessWidget {
  final ChatMessage message;

  const ChatBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Align(
      alignment:
          message.isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        constraints: const BoxConstraints(maxWidth: 280),
        decoration: BoxDecoration(
          color: message.isMe ? scheme.primary : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(message.isMe ? 16 : 4),
            bottomRight: Radius.circular(message.isMe ? 4 : 16),
          ),
          border: message.isMe
              ? null
              : Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.pengirim,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: message.isMe ? Colors.white70 : Colors.grey,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              message.isi,
              style: TextStyle(
                color: message.isMe ? Colors.white : Colors.black87,
                height: 1.35,
              ),
            ),
            Text(
              message.jam,
              style: TextStyle(
                fontSize: 10,
                color: message.isMe ? Colors.white70 : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
