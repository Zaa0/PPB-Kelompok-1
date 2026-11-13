import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:project_pertama/data/api_client.dart';
import 'package:project_pertama/models/app_data.dart';

void main() {
  group('ApiClient', () {
    test('mapping JSON room dari API ke model ChatRoom', () async {
      final client = MockClient((request) async {
        return http.Response(
          '{"rooms": [{'
          '"id": 3, "name": "Algoritma", "category": "matkul",'
          '"invite_code": "UT-103", "allow_guest": false, "created_by": 4,'
          '"members": [1, 2, 4], "member_count": 3,'
          '"is_member": true, "is_admin": false,'
          '"last_message": {"text": "soal nomor 3?", "created_at": "2026-11-14T08:45:00.000Z"}'
          '}]}',
          200,
          headers: {'content-type': 'application/json'},
        );
      });
      final api = ApiClient(baseUrl: 'http://test.local/api', client: client);

      final rooms = await api.fetchRooms('token');

      expect(rooms, hasLength(1));
      final r = rooms.single;
      expect(r.room.id, '3');
      expect(r.room.name, 'Algoritma');
      expect(r.room.inviteCode, 'UT-103');
      expect(r.room.allowGuest, isFalse);
      expect(r.room.memberIds, ['1', '2', '4']);
      expect(r.room.memberCount, 3);
      expect(r.room.createdById, '4');
      expect(r.room.lastMessage, 'soal nomor 3?');
      expect(r.room.lastTime, isNotEmpty);
      expect(r.isMember, isTrue);
      expect(r.isAdmin, isFalse);
      expect(r.room.icon, iconForCategory('matkul'));
    });

    test('mapping pesan & polling ?after= dipakai di URL', () async {
      String? pathDipanggil;
      final client = MockClient((request) async {
        pathDipanggil = request.url.path + (request.url.query);
        return http.Response(
          '{"messages": [{'
          '"id": 9, "room_id": 1, "sender_id": 2,'
          '"sender_name": "Budi", "text": "halo",'
          '"created_at": "2026-11-14T09:12:00.000Z"'
          '}]}',
          200,
          headers: {'content-type': 'application/json'},
        );
      });
      final api = ApiClient(baseUrl: 'http://test.local/api', client: client);

      final msgs = await api.fetchMessages('token', '1', after: 8);

      expect(pathDipanggil, '/api/rooms/1/messagesafter=8');
      final m = msgs.single;
      expect(m.id, '9');
      expect(m.senderId, '2');
      expect(m.senderName, 'Budi');
      expect(m.senderInitial, 'B');
      expect(m.createdAt.hour, 9);
    });

    test('error API diubah jadi ApiException dengan pesan server', () async {
      final client = MockClient((request) async {
        return http.Response(
          '{"message": "Guest tidak bisa membuat room."}',
          403,
          headers: {'content-type': 'application/json'},
        );
      });
      final api = ApiClient(baseUrl: 'http://test.local/api', client: client);

      await expectLater(
        api.createRoom('token', name: 'G', category: 'matkul'),
        throwsA(
          isA<ApiException>()
              .having((e) => e.statusCode, 'statusCode', 403)
              .having((e) => e.message, 'message', 'Guest tidak bisa membuat room.'),
        ),
      );
    });

    test('server tidak terjangkau jadi ApiException yang ramah', () async {
      final client = MockClient((request) async => throw http.ClientException('mati'));
      final api = ApiClient(baseUrl: 'http://test.local/api', client: client);

      await expectLater(
        api.login(email: 'a@b.c', password: 'x'),
        throwsA(
          isA<ApiException>().having(
            (e) => e.message,
            'message',
            'Tidak bisa terhubung ke server. Pastikan backend sudah jalan.',
          ),
        ),
      );
    });

    test('login sukses memetakan token & user', () async {
      final client = MockClient((request) async {
        return http.Response(
          '{"message": "Login berhasil", "token": "12|abc",'
          '"user": {"id": 7, "name": "Andrian Yuza", "email": "yuza@kampus.ac.id", "is_guest": false}}',
          200,
          headers: {'content-type': 'application/json'},
        );
      });
      final api = ApiClient(baseUrl: 'http://test.local/api', client: client);

      final res = await api.login(email: 'yuza@kampus.ac.id', password: 'password123');

      expect(res.token, '12|abc');
      expect(res.userId, 7);
      expect(res.name, 'Andrian Yuza');
      expect(res.isGuest, isFalse);
    });
  });
}
