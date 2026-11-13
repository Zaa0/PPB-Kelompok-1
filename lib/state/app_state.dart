import 'package:flutter/material.dart';

import '../models/app_data.dart';

// State terpusat aplikasi: identitas user/guest, daftar room, membership,
// dan isi chat per room. Screens tinggal konsumsi lewat provider.
//
// Semua logika aturan (guest hanya posting di room allowGuest, admin =
// pembuat room, kode undangan unik) kumpul di sini supaya screens polos.
// Data masih in-memory (dummy + buatan user); penyimpanan lokal menyusul.
class AppState extends ChangeNotifier {
  // Untuk mock lokal, user perangkat ini selalu punya id 'me'.
  static const String _localUserId = 'me';
  String get userId => _localUserId;

  bool _hasSession = false;
  bool _isGuest = false;
  String _displayName = 'User';

  bool get hasSession => _hasSession;
  bool get isGuest => _isGuest;
  String get displayName => _displayName;

  final List<ChatRoom> _rooms = List.from(DummyData.rooms);
  final Set<String> _myRoomIds = {}; // room buatan sendiri = admin
  final Set<String> _joinedIds = {}; // room yang pernah digabung via kode
  final Map<String, List<ChatMessage>> _messagesByRoom = {};
  final Map<String, List<String>> _memberNamesByRoom = {}; // mock daftar nama

  int _seq = 0; // pengaman id biar tidak bentrok

  List<ChatRoom> get rooms => List.unmodifiable(_rooms);

  List<ChatRoom> get myRooms =>
      _rooms.where((r) => _myRoomIds.contains(r.id)).toList();

  bool isJoined(String roomId) => _joinedIds.contains(roomId);

  // ── Sesi ──

  // Dipakai tombol login/guest: selalu set identitas baru.
  void startSession({required bool isGuest, String userName = 'User'}) {
    _hasSession = true;
    _isGuest = isGuest;
    _displayName = userName;
    notifyListeners();
  }

  // Versi senyap untuk HomeScreen yang dibangun langsung dengan parameter
  // (misal dari test). Sengaja tidak notifyListeners supaya aman dipanggil
  // dari initState.
  void ensureSession({required bool isGuest, required String userName}) {
    if (_hasSession) return;
    _hasSession = true;
    _isGuest = isGuest;
    _displayName = userName;
  }

  void logout() {
    _hasSession = false;
    _isGuest = false;
    _displayName = 'User';
    notifyListeners();
  }

  void rename(String name) {
    final n = name.trim();
    if (n.isEmpty) return;
    _displayName = n;
    notifyListeners();
  }

  // ── Aturan akses ──

  bool isAdmin(ChatRoom room) =>
      _myRoomIds.contains(room.id) ||
      (room.createdById.isNotEmpty && room.createdById == userId);

  bool canPostIn(ChatRoom room) => !_isGuest || room.allowGuest;

  // ── Room ──

  String _formatNow() {
    final dt = DateTime.now();
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String _generateInviteCode() {
    var n = 100 + _rooms.length + 1;
    while (_rooms.any((r) => r.inviteCode.toUpperCase() == 'UT-$n')) {
      n++;
    }
    return 'UT-$n';
  }

  ChatRoom createRoom({
    required String name,
    String description = '',
    String category = 'matkul',
  }) {
    final id = 'r${DateTime.now().millisecondsSinceEpoch}-${_seq++}';
    final room = ChatRoom(
      id: id,
      name: name.trim(),
      category: category,
      lastMessage: description.trim().isEmpty
          ? 'Room baru dibuat'
          : description.trim(),
      lastTime: 'Baru saja',
      unreadCount: 0,
      memberIds: [userId],
      createdById: userId,
      icon: iconForCategory(category),
      color: colorForCategory(category),
      inviteCode: _generateInviteCode(),
      allowGuest: category == 'topik',
    );
    _rooms.add(room);
    _myRoomIds.add(id);
    notifyListeners();
    return room;
  }

  ChatRoom? joinByCode(String code) {
    final k = code.trim().toUpperCase();
    final i = _rooms.indexWhere((r) => r.inviteCode.toUpperCase() == k);
    if (i == -1) return null;
    final room = _rooms[i];
    if (!room.memberIds.contains(userId)) {
      _rooms[i] = room.copyWith(memberIds: [...room.memberIds, userId]);
    }
    _joinedIds.add(room.id);
    notifyListeners();
    return _rooms[i];
  }

  void deleteRoom(ChatRoom room) {
    _rooms.removeWhere((r) => r.id == room.id);
    _myRoomIds.remove(room.id);
    _joinedIds.remove(room.id);
    _messagesByRoom.remove(room.id);
    _memberNamesByRoom.remove(room.id);
    notifyListeners();
  }

  // ── Chat ──

  // Pesan per room di-seed dari dummy saat pertama kali dibuka, lalu
  // tersimpan di state jadi tidak hilang lagi saat pindah room.
  List<ChatMessage> messagesFor(ChatRoom room) {
    return _messagesByRoom.putIfAbsent(
      room.id,
      () => List.from(DummyData.messagesFor(room)),
    );
  }

  void sendMessage(ChatRoom room, String text) {
    final t = text.trim();
    if (t.isEmpty) return;
    final msgs = messagesFor(room);
    msgs.add(
      ChatMessage(
        id: 'm${DateTime.now().millisecondsSinceEpoch}-${_seq++}',
        senderId: userId,
        senderName: _displayName,
        text: t,
        createdAt: DateTime.now(),
      ),
    );
    final i = _rooms.indexWhere((r) => r.id == room.id);
    if (i != -1) {
      _rooms[i] = _rooms[i].copyWith(lastMessage: t, lastTime: _formatNow());
    }
    notifyListeners();
  }

  void deleteMessage(ChatRoom room, ChatMessage message) {
    _messagesByRoom[room.id]?.removeWhere((m) => m.id == message.id);
    notifyListeners();
  }

  // ── Anggota (mock: nama tampilan contoh) ──

  List<String> memberNamesFor(ChatRoom room) {
    return _memberNamesByRoom.putIfAbsent(
      room.id,
      () => ['Budi', 'Sari', 'Rina', 'Deni'],
    );
  }

  void kickMember(ChatRoom room, String name) {
    _memberNamesByRoom[room.id]?.remove(name);
    notifyListeners();
  }
}
