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

// Warna identitas pengirim; nama yang tidak dikenal memakai warna utama.
Color colorForSender(String name) {
  switch (name) {
    case 'Budi':
      return const Color(0xFF3B82F6);
    case 'Sari':
      return const Color(0xFF10B981);
    case 'Rina':
      return const Color(0xFF8B5CF6);
    case 'Deni':
      return const Color(0xFFF59E0B);
    default:
      return AppColors.primary;
  }
}

// Icon & warna default berdasarkan kategori room. Dipakai saat buat room dan
// saat data dibaca dari JSON, karena icon/color memang tidak ikut disimpan.
IconData iconForCategory(String category) {
  switch (category) {
    case 'matkul':
      return Icons.book_outlined;
    case 'organisasi':
      return Icons.groups_outlined;
    default:
      return Icons.topic_outlined;
  }
}

Color colorForCategory(String category) => const Color(0xFF3B82F6);

// Model data chat room.
// Field tampilan (icon, color) tidak ikut diserialisasi; cukup diturunkan dari
// kategori supaya struktur model siap disambung ke backend nanti.
class ChatRoom {
  final String id;
  final String name;
  final String category; // 'matkul' | 'organisasi' | 'topik'
  final String lastMessage;
  final String lastTime;
  final int unreadCount;
  final List<String> memberIds; // id user anggota room
  final String createdById; // id pembuat room = admin
  final String inviteCode; // kode undangan unik per room
  final bool allowGuest; // true = guest boleh kirim pesan
  final IconData icon;
  final Color color;

  const ChatRoom({
    required this.id,
    required this.name,
    required this.category,
    required this.lastMessage,
    required this.lastTime,
    required this.unreadCount,
    this.memberIds = const [],
    this.createdById = '',
    this.icon = Icons.book_outlined,
    this.color = const Color(0xFF3B82F6),
    this.inviteCode = '',
    this.allowGuest = false,
  });

  int get memberCount => memberIds.length;

  ChatRoom copyWith({
    String? lastMessage,
    String? lastTime,
    int? unreadCount,
    List<String>? memberIds,
    String? createdById,
    String? inviteCode,
    bool? allowGuest,
  }) {
    return ChatRoom(
      id: id,
      name: name,
      category: category,
      lastMessage: lastMessage ?? this.lastMessage,
      lastTime: lastTime ?? this.lastTime,
      unreadCount: unreadCount ?? this.unreadCount,
      memberIds: memberIds ?? this.memberIds,
      createdById: createdById ?? this.createdById,
      icon: icon,
      color: color,
      inviteCode: inviteCode ?? this.inviteCode,
      allowGuest: allowGuest ?? this.allowGuest,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'category': category,
    'lastMessage': lastMessage,
    'lastTime': lastTime,
    'unreadCount': unreadCount,
    'memberIds': memberIds,
    'createdById': createdById,
    'inviteCode': inviteCode,
    'allowGuest': allowGuest,
  };

  factory ChatRoom.fromJson(Map<String, dynamic> json) {
    final category = (json['category'] ?? 'matkul') as String;
    return ChatRoom(
      id: (json['id'] ?? '') as String,
      name: (json['name'] ?? '') as String,
      category: category,
      lastMessage: (json['lastMessage'] ?? '') as String,
      lastTime: (json['lastTime'] ?? '') as String,
      unreadCount: (json['unreadCount'] ?? 0) as int,
      memberIds: (json['memberIds'] as List<dynamic>? ?? const [])
          .map((e) => e as String)
          .toList(),
      createdById: (json['createdById'] ?? '') as String,
      inviteCode: (json['inviteCode'] ?? '') as String,
      allowGuest: (json['allowGuest'] ?? false) as bool,
      icon: iconForCategory(category),
      color: colorForCategory(category),
    );
  }
}

// Model data pesan. Field tampilan (inisial, warna, isMe) diturunkan di UI
// dari senderId/senderName, jadi tidak ikut disimpan.
class ChatMessage {
  final String id;
  final String senderId;
  final String senderName;
  final String text;
  final DateTime createdAt;

  const ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.text,
    required this.createdAt,
  });

  String get senderInitial =>
      senderName.isNotEmpty ? senderName[0].toUpperCase() : '?';

  // Jam:menit untuk label di bawah bubble.
  String get timeLabel {
    final h = createdAt.hour.toString().padLeft(2, '0');
    final m = createdAt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  bool isSentBy(String userId) => senderId == userId;

  Map<String, dynamic> toJson() => {
    'id': id,
    'senderId': senderId,
    'senderName': senderName,
    'text': text,
    'createdAt': createdAt.toIso8601String(),
  };

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
    id: (json['id'] ?? '') as String,
    senderId: (json['senderId'] ?? '') as String,
    senderName: (json['senderName'] ?? '') as String,
    text: (json['text'] ?? '') as String,
    createdAt:
        DateTime.tryParse((json['createdAt'] ?? '') as String) ??
        DateTime.now(),
  );
}

// Anggota room (dari API saat online, atau contoh saat offline).
class RoomMember {
  final String id;
  final String name;
  final bool isAdmin;
  final bool isGuest;

  const RoomMember({
    required this.id,
    required this.name,
    this.isAdmin = false,
    this.isGuest = false,
  });
}

// Data dummy chat rooms
class DummyData {
  static List<String> _members(int count) =>
      List.generate(count, (i) => 'member-$i');

  static final List<ChatRoom> rooms = [
    ChatRoom(
      id: '1',
      name: 'Pemrograman Mobile',
      category: 'matkul',
      lastMessage: 'Ada yang sudah ngerjain tugas Flutter?',
      lastTime: '10:30',
      unreadCount: 5,
      memberIds: _members(48),
      icon: Icons.phone_android,
      color: Color(0xFF3B82F6),
      inviteCode: 'UT-101',
    ),
    ChatRoom(
      id: '2',
      name: 'Basis Data',
      category: 'matkul',
      lastMessage: 'Tugas normalisasi dikumpul besok ya',
      lastTime: '09:15',
      unreadCount: 2,
      memberIds: _members(52),
      icon: Icons.storage,
      color: Color(0xFF8B5CF6),
      inviteCode: 'UT-102',
    ),
    ChatRoom(
      id: '3',
      name: 'Algoritma & Pemrograman',
      category: 'matkul',
      lastMessage: 'Soal nomor 3 gimana cara ngerjainnya?',
      lastTime: 'Kemarin',
      unreadCount: 0,
      memberIds: _members(45),
      icon: Icons.code,
      color: Color(0xFF10B981),
      inviteCode: 'UT-103',
    ),
    ChatRoom(
      id: '4',
      name: 'Kalkulus',
      category: 'matkul',
      lastMessage: 'Integral trigonometri yang susah banget',
      lastTime: 'Kemarin',
      unreadCount: 1,
      memberIds: _members(60),
      icon: Icons.calculate,
      color: Color(0xFFF59E0B),
      inviteCode: 'UT-104',
    ),
    ChatRoom(
      id: '5',
      name: 'BEM Fakultas',
      category: 'organisasi',
      lastMessage: 'Rapat besok jam 14.00 di aula ya',
      lastTime: '11:00',
      unreadCount: 8,
      memberIds: _members(30),
      icon: Icons.groups,
      color: Color(0xFFEF4444),
      inviteCode: 'UT-201',
    ),
    ChatRoom(
      id: '6',
      name: 'Himpunan Mahasiswa IF',
      category: 'organisasi',
      lastMessage: 'Pendaftaran anggota baru dibuka!',
      lastTime: '08:45',
      unreadCount: 3,
      memberIds: _members(120),
      icon: Icons.school,
      color: Color(0xFF06B6D4),
      inviteCode: 'UT-202',
    ),
    ChatRoom(
      id: '7',
      name: 'UKM Robotika',
      category: 'organisasi',
      lastMessage: 'Workshop Arduino minggu depan',
      lastTime: 'Kemarin',
      unreadCount: 0,
      memberIds: _members(25),
      icon: Icons.precision_manufacturing,
      color: Color(0xFFF59E0B),
      inviteCode: 'UT-203',
    ),
    ChatRoom(
      id: '8',
      name: 'Tips & Trik Kuliah',
      category: 'topik',
      lastMessage: 'Share cara belajar efektif dong!',
      lastTime: '10:00',
      unreadCount: 12,
      memberIds: _members(200),
      icon: Icons.lightbulb_outline,
      color: Color(0xFF8B5CF6),
      inviteCode: 'UT-301',
      allowGuest: true,
    ),
    ChatRoom(
      id: '9',
      name: 'Loker & Magang',
      category: 'topik',
      lastMessage: 'Ada lowongan magang di startup tech nih',
      lastTime: '09:30',
      unreadCount: 6,
      memberIds: _members(180),
      icon: Icons.work_outline,
      color: Color(0xFF10B981),
      inviteCode: 'UT-302',
      allowGuest: true,
    ),
    ChatRoom(
      id: '10',
      name: 'Sharing Tugas Akhir',
      category: 'topik',
      lastMessage: 'Judul TA yang bagus itu gimana?',
      lastTime: 'Kemarin',
      unreadCount: 0,
      memberIds: _members(95),
      icon: Icons.article_outlined,
      color: Color(0xFF3B82F6),
      inviteCode: 'UT-303',
    ),
  ];

  static List<ChatRoom> getByCategory(String category) =>
      rooms.where((r) => r.category == category).toList();

  // Waktu dummy "hari ini jam HH:mm" supaya pesan punya createdAt beneran.
  static DateTime _at(String hhmm) {
    final p = hhmm.split(':');
    final now = DateTime.now();
    return DateTime(
      now.year,
      now.month,
      now.day,
      int.parse(p[0]),
      int.parse(p[1]),
    );
  }

  static ChatMessage _msg(
    String id,
    String name,
    String text,
    String time, {
    bool isMe = false,
  }) {
    return ChatMessage(
      id: id,
      senderId: isMe ? 'me' : 'u-${name.toLowerCase()}',
      senderName: name,
      text: text,
      createdAt: _at(time),
    );
  }

  static final List<ChatMessage> dummyMessages = [
    _msg('1', 'Budi', 'Halo semua! Ada yang sudah mulai ngerjain tugas Flutter?', '09:00'),
    _msg('2', 'Sari', 'Aku baru mulai install Flutter SDK kemarin', '09:05'),
    _msg('3', 'Me', 'Sudah! Bagian widget yang sedikit membingungkan', '09:10', isMe: true),
    _msg('4', 'Budi', 'Iya betul, widget tree-nya lumayan dalam kalau sudah complex', '09:12'),
    _msg('5', 'Rina', 'Ada tutorial yang recommended nggak? Aku masih bingung StatefulWidget vs StatelessWidget', '09:15'),
    _msg('6', 'Me', 'Coba cek flutter.dev, dokumentasinya lengkap banget!', '09:18', isMe: true),
    _msg('7', 'Sari', 'Oh iya, ada juga YouTube channel Rivaan Ranawat yang bagus untuk Flutter', '09:20'),
    _msg('8', 'Deni', 'Deadline tugasnya kapan ya? Masih ingat tidak?', '09:45'),
    _msg('9', 'Me', 'Kalau tidak salah minggu depan Jumat', '09:46', isMe: true),
    _msg('10', 'Budi', 'Ada yang sudah ngerjain tugas Flutter?', '10:30'),
  ];

  // Percakapan contoh per room supaya isi tiap room tidak sama semua.
  static List<ChatMessage> messagesFor(ChatRoom room) {
    if (room.id == '1') return List<ChatMessage>.from(dummyMessages);

    final id = room.id;
    ChatMessage m(
      int n,
      String name,
      String text,
      String time, {
      bool isMe = false,
    }) {
      return ChatMessage(
        id: '$id-$n',
        senderId: isMe ? 'me' : 'u-${name.toLowerCase()}',
        senderName: name,
        text: text,
        createdAt: _at(time),
      );
    }

    switch (room.category) {
      case 'matkul':
        return [
          m(1, 'Sari', 'Selamat datang di ${room.name} 👋', '08:40'),
          m(2, 'Budi', 'Ada yang sudah baca materi minggu ini?', '08:45'),
          m(3, 'Me', 'Sudah, tapi bagian akhir masih belum paham', '08:50', isMe: true),
          m(4, 'Rina', 'Nanti aku share catatannya ya', '08:52'),
          m(5, 'Deni', 'Tugas kelompok dikumpul kapan?', '09:10'),
          m(6, 'Sari', 'Minggu depan Jumat, jangan lupa ya', '09:12'),
        ];
      case 'organisasi':
        return [
          m(1, 'Rina', 'Halo semua, ini room ${room.name}', '08:30'),
          m(2, 'Budi', 'Rapat rutin besok jam 14.00 di aula ya', '08:35'),
          m(3, 'Me', 'Siap, aku hadir', '08:37', isMe: true),
          m(4, 'Deni', 'Yang belum bisa hadir tolong kabari', '08:40'),
          m(5, 'Sari', 'Nanti aku catat hasil rapatnya', '08:44'),
        ];
      default:
        return [
          m(1, 'Deni', 'Halo! Ini room ${room.name}', '09:00'),
          m(2, 'Sari', 'Boleh share pengalaman kalian di sini?', '09:05'),
          m(3, 'Me', 'Boleh banget, nanti aku tulis juga', '09:08', isMe: true),
          m(4, 'Budi', 'Terima kasih infonya, sangat membantu', '09:15'),
          m(5, 'Rina', 'Kalau ada yang mau ditanyakan, langsung tulis aja', '09:20'),
        ];
    }
  }
}
