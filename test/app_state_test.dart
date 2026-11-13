import 'package:flutter_test/flutter_test.dart';
import 'package:project_pertama/data/app_repository.dart';
import 'package:project_pertama/models/app_data.dart';
import 'package:project_pertama/state/app_state.dart';

// Repository tiruan di memori, buat ngetes alur persistensi tanpa plugin.
class _MemoryRepo implements AppRepository {
  Map<String, dynamic>? session;
  List<Map<String, dynamic>>? rooms;
  final Map<String, List<Map<String, dynamic>>> messages = {};
  final Map<String, String> accounts = {};

  @override
  Future<void> init() async {}

  @override
  Future<SessionData?> loadSession() async {
    final s = session;
    if (s == null) return null;
    return SessionData(
      isGuest: s['isGuest'] as bool,
      displayName: s['displayName'] as String,
    );
  }

  @override
  Future<void> saveSession(SessionData s) async {
    session = {'isGuest': s.isGuest, 'displayName': s.displayName};
  }

  @override
  Future<void> clearSession() async {
    session = null;
  }

  @override
  Future<String?> findAccountNameByEmail(String email) async =>
      accounts[email.toLowerCase()];

  @override
  Future<void> saveAccount({
    required String name,
    required String email,
  }) async {
    accounts[email.toLowerCase()] = name;
  }

  @override
  Future<List<ChatRoom>?> loadRooms() async =>
      rooms?.map(ChatRoom.fromJson).toList();

  @override
  Future<void> saveRooms(List<ChatRoom> list) async {
    rooms = list.map((r) => r.toJson()).toList();
  }

  @override
  Future<List<ChatMessage>?> loadMessages(String roomId) async =>
      messages[roomId]?.map(ChatMessage.fromJson).toList();

  @override
  Future<void> saveMessages(String roomId, List<ChatMessage> list) async {
    messages[roomId] = list.map((m) => m.toJson()).toList();
  }
}

// Unit test logika inti AppState: kode undangan, aturan guest/admin,
// membership, kirim pesan, dan roundtrip JSON model.
void main() {
  group('AppState', () {
    test('kode undangan buat room selalu unik', () async {
      final app = AppState();
      final kode = <String>{};
      for (var i = 0; i < 20; i++) {
        final room = await app.createRoom(name: 'Room $i');
        expect(room.inviteCode, startsWith('UT-'));
        kode.add(room.inviteCode);
      }
      expect(kode.length, 20);
    });

    test('guest hanya boleh kirim pesan di room allowGuest', () {
      final app = AppState();
      app.startSession(isGuest: true, userName: 'Guest');
      final roomGuest = DummyData.rooms.firstWhere((r) => r.allowGuest);
      final roomBiasa = DummyData.rooms.firstWhere((r) => !r.allowGuest);
      expect(app.canPostIn(roomGuest), isTrue);
      expect(app.canPostIn(roomBiasa), isFalse);

      app.startSession(isGuest: false, userName: 'Yuza');
      expect(app.canPostIn(roomBiasa), isTrue);
    });

    test('gabung via kode menambah membership dan jumlah anggota', () async {
      final app = AppState();
      app.startSession(isGuest: false, userName: 'Yuza');
      final sebelum = DummyData.rooms
          .firstWhere((r) => r.id == '1')
          .memberCount;
      final room = await app.joinByCode('ut-101'); // huruf kecil harus tetap kena
      expect(room, isNotNull);
      expect(room!.memberCount, sebelum + 1);
      expect(await app.joinByCode('UT-999'), isNull);
    });

    test('kirim pesan menambah chat dan update lastMessage room', () async {
      final app = AppState();
      app.startSession(isGuest: false, userName: 'Yuza');
      final room = DummyData.rooms.first;
      final sebelum = app.messagesFor(room).length;

      await app.sendMessage(room, 'Tes kirim pesan');

      final msgs = app.messagesFor(room);
      expect(msgs.length, sebelum + 1);
      expect(msgs.last.text, 'Tes kirim pesan');
      expect(msgs.last.isSentBy(app.userId), isTrue);
      final updated = app.rooms.firstWhere((r) => r.id == room.id);
      expect(updated.lastMessage, 'Tes kirim pesan');
    });

    test('admin hanya untuk pembuat room', () async {
      final app = AppState();
      app.startSession(isGuest: false, userName: 'Yuza');
      final dummy = DummyData.rooms.first;
      expect(app.isAdmin(dummy), isFalse);

      final buatan = await app.createRoom(name: 'Roomku');
      expect(app.isAdmin(buatan), isTrue);
    });

    test('pindah room tidak menghilangkan pesan yang sudah dikirim', () async {
      final app = AppState();
      app.startSession(isGuest: false, userName: 'Yuza');
      final room1 = DummyData.rooms.firstWhere((r) => r.id == '1');
      final room2 = DummyData.rooms.firstWhere((r) => r.id == '2');

      await app.sendMessage(room1, 'Pesan bertahan');
      // Buka room lain lalu kembali ke room1.
      app.messagesFor(room2);
      final kembali = app.messagesFor(room1);

      expect(kembali.any((m) => m.text == 'Pesan bertahan'), isTrue);
    });

    test('model room & pesan roundtrip JSON', () {
      final room = DummyData.rooms.first;
      final room2 = ChatRoom.fromJson(room.toJson());
      expect(room2.id, room.id);
      expect(room2.name, room.name);
      expect(room2.category, room.category);
      expect(room2.inviteCode, room.inviteCode);
      expect(room2.allowGuest, room.allowGuest);
      expect(room2.memberCount, room.memberCount);
      // Icon memang tidak ikut diserialisasi; diturunkan dari kategori.
      expect(room2.icon, iconForCategory(room.category));

      final msg = ChatMessage(
        id: 'm1',
        senderId: 'me',
        senderName: 'Yuza',
        text: 'halo',
        createdAt: DateTime(2026, 1, 2, 8, 30),
      );
      final msg2 = ChatMessage.fromJson(msg.toJson());
      expect(msg2.senderName, msg.senderName);
      expect(msg2.senderId, msg.senderId);
      expect(msg2.createdAt.hour, 8);
      expect(msg2.senderInitial, 'Y');
      expect(msg2.isSentBy('me'), isTrue);
    });
  });

  group('AppState persistensi', () {
    test('restore memuat room, chat, dan sesi tersimpan', () async {
      final repo = _MemoryRepo();
      repo.rooms = [
        const ChatRoom(
          id: 'x',
          name: 'Room Awet',
          category: 'matkul',
          lastMessage: 'halo',
          lastTime: '09:00',
          unreadCount: 0,
          memberIds: ['me'],
          createdById: 'me',
          inviteCode: 'UT-777',
        ).toJson(),
      ];
      repo.messages['x'] = [
        ChatMessage(
          id: 'm1',
          senderId: 'me',
          senderName: 'Yuza',
          text: 'pesan lama',
          createdAt: DateTime(2026, 1, 1, 9),
        ).toJson(),
      ];

      final app = AppState(repository: repo);
      await app.restore();

      final room = app.rooms.firstWhere((r) => r.id == 'x');
      expect(room.name, 'Room Awet');
      expect(app.isAdmin(room), isTrue); // createdById = 'me'
      expect(app.messagesFor(room).first.text, 'pesan lama');
    });

    test('aksi state ikut tersimpan ke repository', () async {
      final repo = _MemoryRepo();
      final app = AppState(repository: repo);
      app.startSession(isGuest: false, userName: 'Yuza');
      await app.createRoom(name: 'Baru');
      await app.sendMessage(DummyData.rooms.first, 'cek simpan');
      await Future<void>.delayed(Duration.zero); // tunggu simpan selesai

      expect(repo.rooms!.length, DummyData.rooms.length + 1);
      expect(repo.session, {
        'isGuest': false,
        'displayName': 'Yuza',
      });
      expect(repo.messages['1']!.last['text'], 'cek simpan');
    });

    test('logout menghapus sesi tapi data room tetap ada', () async {
      final repo = _MemoryRepo();
      final app = AppState(repository: repo);
      app.startSession(isGuest: false, userName: 'Yuza');
      await app.createRoom(name: 'Roomku');
      await Future<void>.delayed(Duration.zero);

      app.logout();
      await Future<void>.delayed(Duration.zero);

      expect(repo.session, isNull);
      expect(app.hasSession, isFalse);
      expect(repo.rooms!.any((r) => r['name'] == 'Roomku'), isTrue);
    });

    test('akun terdaftar bisa dicari ulang via email', () async {
      final repo = _MemoryRepo();
      final app = AppState(repository: repo);
      await app.saveAccount(name: 'Fitri', email: 'Fitri@Kampus.ac.id');
      await Future<void>.delayed(Duration.zero);

      expect(await app.lookupAccountName('fitri@kampus.ac.id'), 'Fitri');
      expect(await app.lookupAccountName('lain@kampus.ac.id'), isNull);
    });
  });
}
