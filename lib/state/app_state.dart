import 'dart:async';

import 'dart:typed_data';
import 'package:flutter/material.dart';

import '../data/api_client.dart';
import '../data/app_repository.dart';
import '../data/local_repository.dart';
import '../models/app_data.dart';
import '../services/notifications.dart';

// State terpusat aplikasi: identitas user/guest, daftar room, membership,
// dan isi chat per room. Screens tinggal konsumsi lewat provider.
//
// Ada dua mode yang jalan otomatis:
//  - ONLINE (api disediakan): auth & data lewat REST API Laravel, hasil
//    tetap dicache lokal (offline-first), dan polling tiap 1 detik
//    mengambil pesan baru saat chat dibuka.
//  - OFFLINE (tanpa api, atau API tidak terjangkau): semua in-memory /
//    cache lokal dengan data dummy, persis perilaku versi mock.
class AppState extends ChangeNotifier {
  final AppRepository? _repo;
  // Bukan final: bisa dibuat ulang saat user mengganti alamat server
  // di Pengaturan (misal IP laptop berubah di WiFi kampus).
  ApiClient? _api;

  // Nama parameter publik dipakai agar pemanggil mudah dibaca; field tetap privat.
  AppState({AppRepository? repository, ApiClient? api})
      : _repo = repository, // ignore: prefer_initializing_formals
        _api = api; // ignore: prefer_initializing_formals

  bool _hasSession = false;
  bool _isGuest = false;
  String _displayName = 'User'; // nama tampil (alias)
  String _realName = 'User'; // nama panjang asli (tidak bisa diubah)
  String _nim = ''; // NIM (fix, tidak bisa diubah)
  String _currentUserId = 'me';
  String? _token;

  bool get hasSession => _hasSession;
  bool get isGuest => _isGuest;
  bool get isOnline => _api != null;
  // Alamat server yang sedang dipakai (untuk tampil di Pengaturan).
  String get serverUrl => _api?.baseUrl ?? '-';
  String get userId => _currentUserId;
  String get displayName => _displayName;
  String get realName => _realName;
  String get nim => _nim;

  // Loading/error state (syarat RPS).
  bool _loadingRooms = false;
  bool get loadingRooms => _loadingRooms;
  bool _offline = false;
  bool get offlineMode => _offline;

  List<ChatRoom> _rooms = List.from(DummyData.rooms);
  Set<String> _myRoomIds = {}; // admin = pembuat room
  Set<String> _joinedIds = {};
  final Map<String, List<ChatMessage>> _messagesByRoom = {};
  final Map<String, List<RoomMember>> _membersByRoom = {}; // mock daftar nama
  final Map<String, int> _lastMessageId = {}; // polling ?after=
  final Map<String, int> _unreadByRoom = {}; // pesan belum dibaca per room
  final Map<String, DateTime> _lastSeen = {}; // terakhir dilihat per room
  Map<String, String>? _banner; // popup pesan baru di atas layar
  String? _openRoomId; // room yang sedang dibuka (polling aktif di sini)

  int _seq = 0; // pengaman id biar tidak bentrok
  Timer? _pollTimer;
  Timer? _roomsTimer;
  Timer? _bannerTimer;
  String? _lastRoomsSig; // penanda perubahan daftar room (perf)

  List<ChatRoom> get rooms => List.unmodifiable(_rooms);
  Map<String, String>? get banner => _banner;
  int unreadFor(String roomId) => _unreadByRoom[roomId] ?? 0;

  // Pengaturan tampilan & notifikasi (disimpan lokal).
  ThemeMode _themeMode = ThemeMode.system;
  ThemeMode get themeMode => _themeMode;
  bool _notifEnabled = true;
  bool get notifEnabled => _notifEnabled;

  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    unawaited(_repo?.saveSetting(LocalRepository.themeKey, mode.name));
    notifyListeners();
  }

  void setNotifEnabled(bool aktif) {
    _notifEnabled = aktif;
    unawaited(_repo?.saveSetting(LocalRepository.notifKey, aktif ? '1' : '0'));
    notifyListeners();
  }

  // Ganti alamat server (misal IP laptop berubah di WiFi kampus).
  // Return false bila alamat tidak valid. Sesi lama diakhiri supaya
  // user login ulang ke server baru.
  Future<bool> setServerUrl(String url) async {
    var u = url.trim();
    if (u.isEmpty) return false;
    if (!u.startsWith('http://') && !u.startsWith('https://')) {
      u = 'http://$u';
    }
    while (u.endsWith('/')) {
      u = u.substring(0, u.length - 1);
    }
    if (!u.endsWith('/api')) u = '$u/api';
    if (Uri.tryParse(u) == null) return false;

    _api = ApiClient(baseUrl: u);
    unawaited(_repo?.saveSetting(LocalRepository.serverKey, u));
    _hasSession = false;
    _isGuest = false;
    _token = null;
    stopPolling();
    _offline = false;
    unawaited(_repo?.clearSession());
    notifyListeners();
    return true;
  }

  void clearUnread(String roomId) {
    if (_unreadByRoom.remove(roomId) != null) notifyListeners();
  }

  void clearBanner() {
    if (_banner != null) {
      _bannerTimer?.cancel();
      _banner = null;
      notifyListeners();
    }
  }

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
      if (session.realName != null) _realName = session.realName!;
      if (session.nim != null) _nim = session.nim!;
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
    // Muat pengaturan tema & notifikasi.
    final theme = await repo.loadSetting(LocalRepository.themeKey);
    if (theme != null) {
      _themeMode = ThemeMode.values.firstWhere(
        (m) => m.name == theme,
        orElse: () => ThemeMode.system,
      );
    }
    final notif = await repo.loadSetting(LocalRepository.notifKey);
    if (notif != null) _notifEnabled = notif == '1';

    // Alamat server tersimpan (dipakai saat IP laptop berubah, misal
    // pindah WiFi di kampus) - buat ulang ApiClient dengan alamat itu.
    final server = await repo.loadSetting(LocalRepository.serverKey);
    if (server != null && server.isNotEmpty && _api != null) {
      _api = ApiClient(baseUrl: server);
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
      _realName = me.realName;
      _nim = me.nim ?? '';
      _isGuest = me.isGuest;
      _currentUserId = '${me.userId}';
      _offline = false;
      await refreshRooms(silent: true);
      _startRoomRefresh();
    } on ApiException catch (e) {
      _handleApiError(e);
    }
  }

  // Refresh daftar room tiap 5 detik saat online: room card selalu segar
  // (pesan terakhir, jumlah anggota) dan badge/banner belum dibaca jalan.
  void _startRoomRefresh() {
    _roomsTimer?.cancel();
    if (_api == null || _token == null) return;
    _roomsTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      // Tetap coba walau sempat offline: begitu server hidup lagi,
      // daftar room dan status koneksi pulih otomatis (BUG-01).
      if (_token != null && hasSession) {
        unawaited(refreshRooms(silent: true));
      }
    });
  }

  // Token mati (401) = paksa keluar dari sesi; selain itu tandai offline.
  void _handleApiError(ApiException e) {
    if (e.statusCode == 401) {
      _token = null;
      _hasSession = false;
      _isGuest = false;
      _displayName = 'User';
      _currentUserId = 'me';
      _saveSession(clear: true);
    } else {
      _offline = true;
    }
    notifyListeners();
  }

  // ── Auth via API (dipakai layar login saat online) ──

  Future<void> registerAndStart(
    String name,
    String email,
    String password, {
    required String nim,
  }) async {
    final res = await _api!.register(
      name: name,
      nim: nim,
      email: email,
      password: password,
    );
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
      final res = await _api!.guest();
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
    _realName = res.realName;
    _nim = res.nim ?? '';
    _saveSession();
    _startRoomRefresh();
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
        await _api!.logout(_token!);
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
    _roomsTimer?.cancel();
    _bannerTimer?.cancel();
    _banner = null;
    _unreadByRoom.clear();
    _lastSeen.clear();
    _lastRoomsSig = null;
    _saveSession(clear: true);
    notifyListeners();
  }

  void rename(String alias) {
    final n = alias.trim();
    if (n.isEmpty) return;
    _displayName = n;
    _saveSession();
    notifyListeners();
    if (_api != null && _token != null) {
      unawaited(_updateAliasOnServer(n));
    }
  }

  Future<void> _updateAliasOnServer(String alias) async {
    try {
      await _api!.updateAlias(_token!, alias);
    } on ApiException catch (e) {
      _handleApiError(e);
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
    var berubah = false;
    try {
      final list = await _api!.fetchRooms(_token!);
      // Perf: silent refresh tidak memancing rebuild kalau tidak ada yang
      // berubah (sig = gabungan identitas tiap room dari server).
      final sig = list
          .map(
            (r) =>
                '${r.room.id}:${r.room.lastMessage}:${r.room.memberCount}:'
                '${r.lastSenderId}',
          )
          .join('|');
      berubah = sig != _lastRoomsSig;
      _rooms = list.map((r) => r.room).toList();
      _myRoomIds = {for (final r in list) if (r.isAdmin) r.room.id};
      _joinedIds = {for (final r in list) if (r.isMember) r.room.id};
      _lastRoomsSig = sig;
      _offline = false;
      _detectUnread(list);
      if (berubah) _saveRooms();
    } on ApiException catch (e) {
      _handleApiError(e);
    } finally {
      _loadingRooms = false;
      // Rebuild hanya kalau ada perubahan data, bukan tiap siklus refresh.
      if (berubah || !silent || _banner != null) notifyListeners();
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
      _lastSeen[room.id] = DateTime.now();
      _unreadByRoom.remove(room.id);
      _saveMessages(room.id);
      _offline = false;
      notifyListeners();
    } on ApiException catch (e) {
      _handleApiError(e);
    }
  }

  Future<bool> sendMessage(
    ChatRoom room,
    String text, {
    Uint8List? attachmentBytes,
    String? attachmentName,
  }) async {
    final t = text.trim();
    if (t.isEmpty && attachmentBytes == null) return true;
    final msgs = messagesFor(room);
    final teksPesan = t.isNotEmpty ? t : 'Mengirim lampiran';

    if (_useApi) {
      try {
        final m = await _api!.sendMessage(
          _token!,
          room.id,
          t,
          fileBytes: attachmentBytes,
          fileName: attachmentName,
        );
        msgs.add(m);
        _trackLastMessageId(room.id, [m]);
        _lastSeen[room.id] = m.createdAt;
        _bumpRoomLastMessage(room.id, teksPesan);
        _saveMessages(room.id);
        _offline = false;
        notifyListeners();
        return true;
      } on ApiException catch (e) {
        // Kirim gagal → kalau token mati, sesi diakhiri;
        // kalau server mati dan ada lampiran, tidak bisa disimpan lokal.
        _handleApiError(e);
        if (e.statusCode == 401 || attachmentBytes != null) return false;
      }
    }

    // Mock / fallback offline (hanya teks; lampiran tidak didukung offline).
    msgs.add(
      ChatMessage(
        id: 'm${DateTime.now().millisecondsSinceEpoch}-${_seq++}',
        senderId: userId,
        senderName: _displayName,
        // Isi teks cadangan supaya bubble lampiran offline tidak kosong.
        text: t.isEmpty ? teksPesan : t,
        createdAt: DateTime.now(),
        pending: true,
      ),
    );
    _bumpRoomLastMessage(room.id, teksPesan);
    _saveMessages(room.id);
    _saveRooms();
    notifyListeners();
    return true;
  }

  // Balasan yang masuk lewat tombol "Balas" di notifikasi (Android/Windows).
  Future<void> replyFromNotification(String roomId, String pesan) async {
    final match = _rooms.where((r) => r.id == roomId).toList();
    if (match.isEmpty) return;
    await sendMessage(match.first, pesan);
  }

  Future<void> deleteMessage(ChatRoom room, ChatMessage message) async {
    if (_useApi) {
      try {
        await _api!.deleteMessage(_token!, message.id);
      } on ApiException catch (e) {
        _handleApiError(e);
      }
    }
    _messagesByRoom[room.id]?.removeWhere((m) => m.id == message.id);
    _saveMessages(room.id);
    notifyListeners();
  }

  // ── Polling: ambil pesan baru tiap 1 detik selama chat dibuka ──

  void startPolling(ChatRoom room) {
    _pollTimer?.cancel();
    _openRoomId = room.id;
    if (_api == null || _token == null) return;
    _pollTimer = Timer.periodic(const Duration(seconds: 1), (_) => _poll(room.id));
  }

  void stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
    _openRoomId = null;
  }

  Future<void> _poll(String roomId) async {
    if (_api == null || _token == null || _messagesByRoom[roomId] == null) return;
    try {
      final after = _lastMessageId[roomId];
      final fresh = await _api!.fetchMessages(_token!, roomId, after: after);
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
    } on ApiException catch (e) {
      _handleApiError(e);
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
    } on ApiException catch (e) {
      _handleApiError(e);
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

  // Deteksi pesan baru di room yang tidak sedang dibuka: naikkan badge
  // belum dibaca dan tampilkan banner di atas layar.
  void _detectUnread(List<ApiRoom> list) {
    final nol = DateTime.fromMillisecondsSinceEpoch(0);
    for (final r in list) {
      final at = r.lastAt;
      if (at == null || r.lastSenderId == null) continue;

      final dariSaya = '${r.lastSenderId}' == userId;
      final sudahDilihat =
          !at.isAfter(_lastSeen[r.room.id] ?? nol) ||
              r.room.id == _openRoomId;
      if (dariSaya || sudahDilihat) {
        _lastSeen[r.room.id] = at;
        continue;
      }

      _unreadByRoom[r.room.id] = (_unreadByRoom[r.room.id] ?? 0) + 1;
      _lastSeen[r.room.id] = at;
      _bannerTimer?.cancel();
      _banner = {
        'roomId': r.room.id,
        'roomName': r.room.name,
        'sender': r.lastSenderName ?? 'Guest',
        'text': r.room.lastMessage,
      };
      _bannerTimer = Timer(const Duration(seconds: 4), () {
        _banner = null;
        notifyListeners();
      });
      // Notifikasi sistem (Android/Windows), kalau diaktifkan di pengaturan.
      if (_notifEnabled) {
        unawaited(showMessageNotification(
          roomId: r.room.id,
          roomName: r.room.name,
          sender: r.lastSenderName ?? 'Guest',
          text: r.room.lastMessage,
        ));
      }
    }
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _roomsTimer?.cancel();
    _bannerTimer?.cancel();
    super.dispose();
  }

  // Bersihkan seluruh data lokal (dipakai tombol "Bersihkan data" di
  // pengaturan) lalu kembali ke kondisi awal seperti baru di-install.
  Future<void> resetLocalData() async {
    stopPolling();
    _roomsTimer?.cancel();
    _bannerTimer?.cancel();
    await _repo?.clearAllData();
    _rooms = List.from(DummyData.rooms);
    _messagesByRoom.clear();
    _membersByRoom.clear();
    _unreadByRoom.clear();
    _lastSeen.clear();
    _lastMessageId.clear();
    _myRoomIds = {};
    _joinedIds = {};
    _lastRoomsSig = null;
    _banner = null;
    _token = null;
    _hasSession = false;
    _isGuest = false;
    _displayName = 'User';
    _currentUserId = 'me';
    _saveSession(clear: true);
    notifyListeners();
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
          realName: _realName,
          nim: _nim,
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
