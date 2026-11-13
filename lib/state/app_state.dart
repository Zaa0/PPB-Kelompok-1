import 'dart:async';

import 'package:flutter/material.dart';

import '../data/api_client.dart';
import '../data/app_repository.dart';
import '../models/app_data.dart';

// State terpusat aplikasi: identitas user/guest, daftar room, membership,
// dan isi chat per room. Screens tinggal konsumsi lewat provider.
//
// Ada dua mode yang jalan otomatis:
//  - ONLINE (api disediakan): auth & data lewat REST API Laravel, hasil
//    tetap dicache lokal (offline-first), dan polling tiap 3 detik
//    mengambil pesan baru saat chat dibuka.
//  - OFFLINE (tanpa api, atau API tidak terjangkau): semua in-memory /
//    cache lokal dengan data dummy, persis perilaku versi mock.
class AppState extends ChangeNotifier {
  final AppRepository? _repo;
  final ApiClient? _api;

  // Nama parameter publik dipakai agar pemanggil mudah dibaca; field tetap privat.
  AppState({AppRepository? repository, ApiClient? api})
      : _repo = repository, // ignore: prefer_initializing_formals
        _api = api; // ignore: prefer_initializing_formals

  bool _hasSession = false;
  bool _isGuest = false;
  String _displayName = 'User';
  String _currentUserId = 'me';
  String? _token;

  bool get hasSession => _hasSession;
  bool get isGuest => _isGuest;
  bool get isOnline => _api != null;
  String get userId => _currentUserId;
  String get displayName => _displayName;

  // Loading/error state (syarat RPS).
  bool _loadingRooms = false;
  bool get loadingRooms => _loadingRooms;
  bool _offline = false;
  bool get offlineMode => _offline;

  List<ChatRoom> _rooms = List.from(DummyData.rooms);
  Set<String> _myRoomIds = {}; // admin = pembuat room
  Set<String> _joinedIds = {};
  final Map<String, List<ChatMessage>> _messagesByRoom = {};
  final Map<String, List<RoomMember>> _membersByRoom = {};
  final Map<String, int> _lastMessageId = {}; // polling ?after=

  int _seq = 0; // pengaman id biar tidak bentrok
  Timer? _pollTimer;

  List<ChatRoom> get rooms => List.unmodifiable(_rooms);

  List<ChatRoom> get myRooms =>
      _rooms.where((r) => _myRoomIds.contains(r.id)).toList();

  bool isJoined(String roomId) => _joinedIds.contains(roomId);

  // ── Pulihkan data tersimpan ──

  // Dipanggil sekali sebelum runApp; belum ada listener jadi tidak perlu
  // notifyListeners di sini.
  Future<void> restore() async {
    final repo = _repo;
    if (repo == null) return;

    final session = await repo.loadSession();
    if (session != null) {
      _hasSession = true;
      _isGuest = session.isGuest;
      _displayName = session.displayName;
      _token = session.token;
      if (session.userId != null) _currentUserId = session.userId!;
    }

    final rooms = await repo.loadRooms();
    if (rooms == null) {
      // Pertama kali: seed dummy langsung disimpan supaya konsisten.
      await repo.saveRooms(_rooms);
    } else {
      _rooms = List.from(rooms);
    }
    for (final room in _rooms) {
      final msgs = await repo.loadMessages(room.id);
      if (msgs != null) _messagesByRoom[room.id] = msgs;
    }

    // Sesi online divalidasi di background: kalau token masih valid,
    // data langsung di-refresh dari API.
    if (_api != null && _token != null) {
      unawaited(_validateAndRefresh());
    }
  }

  Future<void> _validateAndRefresh() async {
    try {
      final me = await _api!.me(_token!);
      _displayName = me.name;
      _isGuest = me.isGuest;
      _currentUserId = '${me.userId}';
      _offline = false;
      await refreshRooms(silent: true);
    } on ApiException {
      _offline = true;
      notifyListeners();
    }
  }

  // ── Auth via API (dipakai layar login saat online) ──

  Future<void> registerAndStart(String name, String email, String password) async {
    final res = await _api!.register(name: name, email: email, password: password);
    _applyAuth(res);
    await refreshRooms(silent: true);
  }

  Future<void> loginAndStart(String email, String password) async {
    final res = await _api!.login(email: email, password: password);
    _applyAuth(res);
    await refreshRooms(silent: true);
  }

  Future<void> startGuestSession() async {
    if (_api != null && !_offline) {
      final res = await _api.guest();
      _applyAuth(res);
      await refreshRooms(silent: true);
    } else {
      startSession(isGuest: true, userName: 'Guest');
    }
  }

  void _applyAuth(AuthResult res) {
    _token = res.token;
    _currentUserId = '${res.userId}';
    _hasSession = true;
    _isGuest = res.isGuest;
    _displayName = res.name;
    _saveSession();
    notifyListeners();
  }

  // ── Sesi mock (offline) ──

  // Dipakai tombol login/guest saat offline: selalu set identitas baru.
  void startSession({required bool isGuest, String userName = 'User'}) {
    _hasSession = true;
    _isGuest = isGuest;
    _displayName = userName;
    _currentUserId = 'me';
    _token = null;
    _saveSession();
    notifyListeners();
  }

  // Versi senyap untuk HomeScreen yang dibangun langsung dengan parameter
  // (misal dari test). Sengaja tidak notifyListeners supaya aman dipanggil
  // dari initState. Saat online dengan sesi API, tidak menimpa apa pun.
  void ensureSession({required bool isGuest, required String userName}) {
    if (_hasSession) return;
    _hasSession = true;
    _isGuest = isGuest;
    _displayName = userName;
    _currentUserId = 'me';
    _saveSession();
  }

  Future<void> logout() async {
    if (_api != null && _token != null) {
      try {
        await _api.logout(_token!);
      } on ApiException {
        // Token sudah mati / server mati — tetap bersihkan lokal.
      }
    }
    _token = null;
    _hasSession = false;
    _isGuest = false;
    _displayName = 'User';
    _currentUserId = 'me';
    stopPolling();
    _saveSession(clear: true);
    notifyListeners();
  }

  void rename(String name) {
    final n = name.trim();
    if (n.isEmpty) return;
    _displayName = n;
    _saveSession();
    notifyListeners();
    if (_api != null && _token != null) {
      unawaited(_updateNameOnServer(n));
    }
  }

  Future<void> _updateNameOnServer(String name) async {
    try {
      await _api!.updateName(_token!, name);
    } on ApiException {
      _offline = true;
      notifyListeners();
    }
  }

  // ── Aturan akses ──

  bool isAdmin(ChatRoom room) =>
      _myRoomIds.contains(room.id) ||
      (room.createdById.isNotEmpty && room.createdById == userId);

  bool canPostIn(ChatRoom room) => !_isGuest || room.allowGuest;

  // ── Room ──

  // Ambil ulang daftar room dari API (dipakai juga setelah kick/ubah data).
  Future<void> refreshRooms({bool silent = false}) async {
    if (_api == null || _token == null) return;
    if (!silent) {
      _loadingRooms = true;
      notifyListeners();
    }
    try {
      final list = await _api.fetchRooms(_token!);
      _rooms = list.map((r) => r.room).toList();
      _myRoomIds = {for (final r in list) if (r.isAdmin) r.room.id};
      _joinedIds = {for (final r in list) if (r.isMember) r.room.id};
      _offline = false;
      _saveRooms();
    } on ApiException {
      _offline = true;
    } finally {
      _loadingRooms = false;
      notifyListeners();
    }
  }

  bool get _useApi => _api != null && _token != null && !_offline;

  Future<ChatRoom> createRoom({
    required String name,
    String description = '',
    String category = 'matkul',
  }) async {
    if (_useApi) {
      final r = await _api!.createRoom(
        _token!,
        name: name,
        description: description,
        category: category,
      );
      _rooms.add(r.room);
      _myRoomIds.add(r.room.id);
      _saveRooms();
      notifyListeners();
      return r.room;
    }

    // Mock offline (perilaku versi lama).
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
    _saveRooms();
    notifyListeners();
    return room;
  }

  // null berarti kode tidak ditemukan (statusCode 404).
  Future<ChatRoom?> joinByCode(String code) async {
    if (_useApi) {
      try {
        final r = await _api!.joinByCode(_token!, code);
        final i = _rooms.indexWhere((x) => x.id == r.room.id);
        if (i != -1) {
          _rooms[i] = r.room;
        } else {
          _rooms.add(r.room);
        }
        _joinedIds.add(r.room.id);
        if (r.isAdmin) _myRoomIds.add(r.room.id);
        _saveRooms();
        notifyListeners();
        return r.room;
      } on ApiException catch (e) {
        if (e.statusCode == 404) return null;
        rethrow; // error lain ditampilkan di layar
      }
    }

    // Mock offline.
    final k = code.trim().toUpperCase();
    final i = _rooms.indexWhere((r) => r.inviteCode.toUpperCase() == k);
    if (i == -1) return null;
    final room = _rooms[i];
    if (!room.memberIds.contains(userId)) {
      _rooms[i] = room.copyWith(memberIds: [...room.memberIds, userId]);
    }
    _joinedIds.add(room.id);
    _saveRooms();
    notifyListeners();
    return _rooms[i];
  }

  Future<void> deleteRoom(ChatRoom room) async {
    if (_useApi) {
      await _api!.deleteRoom(_token!, room.id);
    }
    _rooms.removeWhere((r) => r.id == room.id);
    _myRoomIds.remove(room.id);
    _joinedIds.remove(room.id);
    _messagesByRoom.remove(room.id);
    _membersByRoom.remove(room.id);
    _saveRooms();
    notifyListeners();
  }

  String _generateInviteCode() {
    var n = 100 + _rooms.length + 1;
    while (_rooms.any((r) => r.inviteCode.toUpperCase() == 'UT-$n')) {
      n++;
    }
    return 'UT-$n';
  }

  // ── Chat ──

  // Pesan per room: diambil dari cache/dummy saat pertama dibuka, lalu
  // ditimpa hasil API kalau online.
  List<ChatMessage> messagesFor(ChatRoom room) {
    return _messagesByRoom.putIfAbsent(
      room.id,
      () => List.from(DummyData.messagesFor(room)),
    );
  }

  Future<void> loadMessages(ChatRoom room) async {
    if (!_useApi) return;
    try {
      final msgs = await _api!.fetchMessages(_token!, room.id);
      _messagesByRoom[room.id] = msgs;
      _trackLastMessageId(room.id, msgs);
      _saveMessages(room.id);
      _offline = false;
      notifyListeners();
    } on ApiException {
      _offline = true;
      notifyListeners();
    }
  }

  Future<void> sendMessage(ChatRoom room, String text) async {
    final t = text.trim();
    if (t.isEmpty) return;
    final msgs = messagesFor(room);

    if (_useApi) {
      try {
        final m = await _api!.sendMessage(_token!, room.id, t);
        msgs.add(m);
        _trackLastMessageId(room.id, [m]);
        _bumpRoomLastMessage(room.id, t);
        _saveMessages(room.id);
        _offline = false;
        notifyListeners();
        return;
      } on ApiException {
        // Kirim gagal (server mati) → simpan lokal saja + tandai offline.
        _offline = true;
        notifyListeners();
      }
    }

    // Mock / fallback offline.
    msgs.add(
      ChatMessage(
        id: 'm${DateTime.now().millisecondsSinceEpoch}-${_seq++}',
        senderId: userId,
        senderName: _displayName,
        text: t,
        createdAt: DateTime.now(),
      ),
    );
    _bumpRoomLastMessage(room.id, t);
    _saveMessages(room.id);
    _saveRooms();
    notifyListeners();
  }

  Future<void> deleteMessage(ChatRoom room, ChatMessage message) async {
    if (_useApi) {
      try {
        await _api!.deleteMessage(_token!, message.id);
      } on ApiException {
        _offline = true;
      }
    }
    _messagesByRoom[room.id]?.removeWhere((m) => m.id == message.id);
    _saveMessages(room.id);
    notifyListeners();
  }

  // ── Polling: ambil pesan baru tiap 3 detik selama chat dibuka ──

  void startPolling(ChatRoom room) {
    _pollTimer?.cancel();
    if (_api == null || _token == null) return;
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) => _poll(room.id));
  }

  void stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  Future<void> _poll(String roomId) async {
    if (_api == null || _token == null || _messagesByRoom[roomId] == null) return;
    try {
      final after = _lastMessageId[roomId];
      final fresh = await _api.fetchMessages(_token!, roomId, after: after);
      if (fresh.isEmpty) return;
      final list = _messagesByRoom[roomId]!;
      final ada = list.map((m) => m.id).toSet();
      var ditambah = false;
      for (final m in fresh) {
        if (!ada.contains(m.id)) {
          list.add(m);
          ditambah = true;
        }
      }
      if (!ditambah) return;
      _trackLastMessageId(roomId, fresh);
      _saveMessages(roomId);
      notifyListeners();
    } on ApiException {
      _offline = true;
      notifyListeners();
    }
  }

  void _trackLastMessageId(String roomId, List<ChatMessage> msgs) {
    for (final m in msgs) {
      final v = int.tryParse(m.id);
      if (v != null) {
        final cur = _lastMessageId[roomId];
        if (cur == null || v > cur) _lastMessageId[roomId] = v;
      }
    }
  }

  void _bumpRoomLastMessage(String roomId, String text) {
    final i = _rooms.indexWhere((r) => r.id == roomId);
    if (i != -1) {
      _rooms[i] = _rooms[i].copyWith(lastMessage: text, lastTime: _formatNow());
    }
  }

  String _formatNow() {
    final dt = DateTime.now();
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  // ── Anggota ──

  // Versi offline memakai nama contoh; versi online diambil dari API.
  List<RoomMember> membersFor(ChatRoom room) {
    return _membersByRoom.putIfAbsent(
      room.id,
      () => const [
        RoomMember(id: 'mock-budi', name: 'Budi'),
        RoomMember(id: 'mock-sari', name: 'Sari'),
        RoomMember(id: 'mock-rina', name: 'Rina'),
        RoomMember(id: 'mock-deni', name: 'Deni'),
      ],
    );
  }

  Future<void> loadMembers(ChatRoom room) async {
    if (!_useApi) return;
    try {
      _membersByRoom[room.id] = await _api!.fetchMembers(_token!, room.id);
      _offline = false;
      notifyListeners();
    } on ApiException {
      _offline = true;
      notifyListeners();
    }
  }

  Future<void> kickMember(ChatRoom room, RoomMember member) async {
    if (_useApi) {
      try {
        await _api!.kick(_token!, room.id, member.id);
      } on ApiException {
        _offline = true;
      }
    }
    _membersByRoom[room.id]?.removeWhere((m) => m.id == member.id);
    notifyListeners();
    // jumlah anggota di daftar room ikut berubah
    if (_useApi) unawaited(refreshRooms(silent: true));
  }

  // ── Akun mock (dipakai layar login saat offline) ──

  Future<String?> lookupAccountName(String email) async {
    return _repo?.findAccountNameByEmail(email);
  }

  Future<void> saveAccount({
    required String name,
    required String email,
  }) async {
    await _repo?.saveAccount(name: name, email: email);
  }

  // ── Penyimpanan (fire-and-forget; kegagalan tidak boleh mengganggu UI) ──

  void _saveSession({bool clear = false}) {
    final repo = _repo;
    if (repo == null) return;
    if (clear) {
      unawaited(repo.clearSession());
      return;
    }
    unawaited(
      repo.saveSession(
        SessionData(
          isGuest: _isGuest,
          displayName: _displayName,
          token: _token,
          userId: _currentUserId,
        ),
      ),
    );
  }

  void _saveRooms() {
    final repo = _repo;
    if (repo == null) return;
    unawaited(repo.saveRooms(_rooms));
  }

  void _saveMessages(String roomId) {
    final repo = _repo;
    if (repo == null) return;
    final msgs = _messagesByRoom[roomId];
    if (msgs == null) return;
    unawaited(repo.saveMessages(roomId, msgs));
  }
}
