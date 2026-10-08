// Model pesan chat - dummy dulu, nanti dari GET /api/rooms/{id}/messages
class ChatMessage {
  final String pengirim;
  final String isi;
  final String jam;
  final bool isMe;

  const ChatMessage({
    required this.pengirim,
    required this.isi,
    required this.jam,
    required this.isMe,
  });
}

const dummyMessages = [
  ChatMessage(
    pengirim: 'Anon_21',
    isi: 'Halo, ada yang sudah install Flutter?',
    jam: '09:10',
    isMe: false,
  ),
  ChatMessage(
    pengirim: 'Saya',
    isi: 'Sudah, pakai flutter doctor aman.',
    jam: '09:12',
    isMe: true,
  ),
  ChatMessage(
    pengirim: 'Anon_07',
    isi: 'Room PPB ini untuk bahas widget ya?',
    jam: '09:15',
    isMe: false,
  ),
];
