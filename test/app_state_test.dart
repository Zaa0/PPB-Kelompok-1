import 'package:flutter_test/flutter_test.dart';
import 'package:project_pertama/models/app_data.dart';
import 'package:project_pertama/state/app_state.dart';

// Unit test logika inti AppState: kode undangan, aturan guest/admin,
// membership, kirim pesan, dan roundtrip JSON model.
void main() {
  group('AppState', () {
    test('kode undangan buat room selalu unik', () {
      final app = AppState();
      final kode = <String>{};
      for (var i = 0; i < 20; i++) {
        final room = app.createRoom(name: 'Room $i');
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

    test('gabung via kode menambah membership dan jumlah anggota', () {
      final app = AppState();
      app.startSession(isGuest: false, userName: 'Yuza');
      final sebelum = DummyData.rooms
          .firstWhere((r) => r.id == '1')
          .memberCount;
      final room = app.joinByCode('ut-101'); // huruf kecil harus tetap kena
      expect(room, isNotNull);
      expect(room!.memberCount, sebelum + 1);
      expect(app.joinByCode('UT-999'), isNull);
    });

    test('kirim pesan menambah chat dan update lastMessage room', () {
      final app = AppState();
      app.startSession(isGuest: false, userName: 'Yuza');
      final room = DummyData.rooms.first;
      final sebelum = app.messagesFor(room).length;

      app.sendMessage(room, 'Tes kirim pesan');

      final msgs = app.messagesFor(room);
      expect(msgs.length, sebelum + 1);
      expect(msgs.last.text, 'Tes kirim pesan');
      expect(msgs.last.isSentBy(app.userId), isTrue);
      final updated = app.rooms.firstWhere((r) => r.id == room.id);
      expect(updated.lastMessage, 'Tes kirim pesan');
    });

    test('admin hanya untuk pembuat room', () {
      final app = AppState();
      app.startSession(isGuest: false, userName: 'Yuza');
      final dummy = DummyData.rooms.first;
      expect(app.isAdmin(dummy), isFalse);

      final buatan = app.createRoom(name: 'Roomku');
      expect(app.isAdmin(buatan), isTrue);
    });

    test('pindah room tidak menghilangkan pesan yang sudah dikirim', () {
      final app = AppState();
      app.startSession(isGuest: false, userName: 'Yuza');
      final room1 = DummyData.rooms.firstWhere((r) => r.id == '1');
      final room2 = DummyData.rooms.firstWhere((r) => r.id == '2');

      app.sendMessage(room1, 'Pesan bertahan');
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
}
