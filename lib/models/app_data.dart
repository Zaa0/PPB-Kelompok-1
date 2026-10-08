import 'package:flutter/material.dart';

// UniTalk - Chatroom Mahasiswa
// Data model dan konstanta

const String kAppName = 'UniTalk';
const String kAppTagline = 'Ruang Diskusi Mahasiswa';

// Warna utama UniTalk

class AppColors {
  static const primary = Color(0xFF1E3A8A);
  static const primaryLight = Color(0xFF3B82F6);
  static const accent = Color(0xFF06B6D4);
  static const surface = Color(0xFFF0F6FF);
  static const cardBg = Colors.white;
  static const textDark = Color(0xFF0F172A);
  static const textMuted = Color(0xFF64748B);
  static const online = Color(0xFF22C55E);
  static const unread = Color(0xFFEF4444);
}

// Model data chat room
class ChatRoom {
  final String id;
  final String name;
  final String category; // 'matkul' | 'organisasi' | 'topik'
  final String lastMessage;
  final String lastTime;
  final int unreadCount;
  final int memberCount;
  final IconData icon;
  final Color color;

  const ChatRoom({
    required this.id,
    required this.name,
    required this.category,
    required this.lastMessage,
    required this.lastTime,
    required this.unreadCount,
    required this.memberCount,
    required this.icon,
    required this.color,
  });
}

// Model data pesan
class ChatMessage {
  final String id;
  final String senderName;
  final String senderInitial;
  final Color senderColor;
  final String text;
  final String time;
  final bool isMe;

  const ChatMessage({
    required this.id,
    required this.senderName,
    required this.senderInitial,
    required this.senderColor,
    required this.text,
    required this.time,
    required this.isMe,
  });
}

// Data dummy chat rooms
class DummyData {
  static const List<ChatRoom> rooms = [
    ChatRoom(
      id: '1', name: 'Pemrograman Mobile', category: 'matkul',
      lastMessage: 'Ada yang sudah ngerjain tugas Flutter?',
      lastTime: '10:30', unreadCount: 5, memberCount: 48,
      icon: Icons.phone_android, color: Color(0xFF3B82F6),
    ),
    ChatRoom(
      id: '2', name: 'Basis Data', category: 'matkul',
      lastMessage: 'Tugas normalisasi dikumpul besok ya',
      lastTime: '09:15', unreadCount: 2, memberCount: 52,
      icon: Icons.storage, color: Color(0xFF8B5CF6),
    ),
    ChatRoom(
      id: '3', name: 'Algoritma & Pemrograman', category: 'matkul',
      lastMessage: 'Soal nomor 3 gimana cara ngerjainnya?',
      lastTime: 'Kemarin', unreadCount: 0, memberCount: 45,
      icon: Icons.code, color: Color(0xFF10B981),
    ),
    ChatRoom(
      id: '4', name: 'Kalkulus', category: 'matkul',
      lastMessage: 'Integral trigonometri yang susah banget',
      lastTime: 'Kemarin', unreadCount: 1, memberCount: 60,
      icon: Icons.calculate, color: Color(0xFFF59E0B),
    ),
    ChatRoom(
      id: '5', name: 'BEM Fakultas', category: 'organisasi',
      lastMessage: 'Rapat besok jam 14.00 di aula ya',
      lastTime: '11:00', unreadCount: 8, memberCount: 30,
      icon: Icons.groups, color: Color(0xFFEF4444),
    ),
    ChatRoom(
      id: '6', name: 'Himpunan Mahasiswa IF', category: 'organisasi',
      lastMessage: 'Pendaftaran anggota baru dibuka!',
      lastTime: '08:45', unreadCount: 3, memberCount: 120,
      icon: Icons.school, color: Color(0xFF06B6D4),
    ),
    ChatRoom(
      id: '7', name: 'UKM Robotika', category: 'organisasi',
      lastMessage: 'Workshop Arduino minggu depan',
      lastTime: 'Kemarin', unreadCount: 0, memberCount: 25,
      icon: Icons.precision_manufacturing, color: Color(0xFFF59E0B),
    ),
    ChatRoom(
      id: '8', name: 'Tips & Trik Kuliah', category: 'topik',
      lastMessage: 'Share cara belajar efektif dong!',
      lastTime: '10:00', unreadCount: 12, memberCount: 200,
      icon: Icons.lightbulb_outline, color: Color(0xFF8B5CF6),
    ),
    ChatRoom(
      id: '9', name: 'Loker & Magang', category: 'topik',
      lastMessage: 'Ada lowongan magang di startup tech nih',
      lastTime: '09:30', unreadCount: 6, memberCount: 180,
      icon: Icons.work_outline, color: Color(0xFF10B981),
    ),
    ChatRoom(
      id: '10', name: 'Sharing Tugas Akhir', category: 'topik',
      lastMessage: 'Judul TA yang bagus itu gimana?',
      lastTime: 'Kemarin', unreadCount: 0, memberCount: 95,
      icon: Icons.article_outlined, color: Color(0xFF3B82F6),
    ),
  ];

  static List<ChatRoom> getByCategory(String category) =>
      rooms.where((r) => r.category == category).toList();

  static const List<ChatMessage> dummyMessages = [
    ChatMessage(id: '1', senderName: 'Budi', senderInitial: 'B', senderColor: Color(0xFF3B82F6), text: 'Halo semua! Ada yang sudah mulai ngerjain tugas Flutter?', time: '09:00', isMe: false),
    ChatMessage(id: '2', senderName: 'Sari', senderInitial: 'S', senderColor: Color(0xFF10B981), text: 'Aku baru mulai install Flutter SDK kemarin', time: '09:05', isMe: false),
    ChatMessage(id: '3', senderName: 'Me', senderInitial: 'M', senderColor: Color(0xFF1E3A8A), text: 'Sudah! Bagian widget yang sedikit membingungkan', time: '09:10', isMe: true),
    ChatMessage(id: '4', senderName: 'Budi', senderInitial: 'B', senderColor: Color(0xFF3B82F6), text: 'Iya betul, widget tree-nya lumayan dalam kalau sudah complex', time: '09:12', isMe: false),
    ChatMessage(id: '5', senderName: 'Rina', senderInitial: 'R', senderColor: Color(0xFF8B5CF6), text: 'Ada tutorial yang recommended nggak? Aku masih bingung StatefulWidget vs StatelessWidget', time: '09:15', isMe: false),
    ChatMessage(id: '6', senderName: 'Me', senderInitial: 'M', senderColor: Color(0xFF1E3A8A), text: 'Coba cek flutter.dev, dokumentasinya lengkap banget!', time: '09:18', isMe: true),
    ChatMessage(id: '7', senderName: 'Sari', senderInitial: 'S', senderColor: Color(0xFF10B981), text: 'Oh iya, ada juga YouTube channel Rivaan Ranawat yang bagus untuk Flutter', time: '09:20', isMe: false),
    ChatMessage(id: '8', senderName: 'Deni', senderInitial: 'D', senderColor: Color(0xFFF59E0B), text: 'Deadline tugasnya kapan ya? Masih ingat tidak?', time: '09:45', isMe: false),
    ChatMessage(id: '9', senderName: 'Me', senderInitial: 'M', senderColor: Color(0xFF1E3A8A), text: 'Kalau tidak salah minggu depan Jumat', time: '09:46', isMe: true),
    ChatMessage(id: '10', senderName: 'Budi', senderInitial: 'B', senderColor: Color(0xFF3B82F6), text: 'Ada yang sudah ngerjain tugas Flutter?', time: '10:30', isMe: false),
  ];
}
