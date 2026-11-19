// Regression test BUG-02 (QA Fitri, TC-06):
// Setelah token mati (misal database di-reseed), aplikasi wajib kembali
// ke halaman welcome - tidak boleh stuck di halaman chat.
import 'package:flutter_test/flutter_test.dart';
import 'package:project_pertama/data/api_client.dart';
import 'package:project_pertama/data/app_repository.dart';
import 'package:project_pertama/models/app_data.dart';
import 'package:project_pertama/main.dart';
import 'package:project_pertama/state/app_state.dart';

// API tiruan: semua panggilan daftar room dibalakangani 401
// (simulasi token mati setelah database di-reseed).
class ApiTokenMati extends ApiClient {
  ApiTokenMati() : super(baseUrl: 'http://test.local');

  // Token mati: semua panggilan berprotokol dibalas 401 persis seperti
  // Sanctum saat sesi dicabut (database di-reseed).
  @override
  Future<List<ApiRoom>> fetchRooms(String token) async =>
      throw ApiException('Unauthenticated.', 401);

  @override
  Future<AuthResult> me(String token) async =>
      throw ApiException('Unauthenticated.', 401);
}

class RepoSesiMati implements AppRepository {
  final Map<String, String> settings = {};
  Map<String, dynamic>? session;

  @override
  Future<void> init() async {}

  @override
  Future<SessionData?> loadSession() async {
    final s = session;
    if (s == null) return null;
    return SessionData(
      isGuest: s['isGuest'] as bool,
      displayName: s['displayName'] as String,
      realName: s['realName'] as String?,
      nim: s['nim'] as String?,
      token: s['token'] as String?,
      userId: s['userId'] as String?,
    );
  }

  @override
  Future<void> saveSession(SessionData s) async {
    session = {
      'isGuest': s.isGuest,
      'displayName': s.displayName,
      'realName': s.realName,
      'nim': s.nim,
      'token': s.token,
      'userId': s.userId,
    };
  }

  @override
  Future<void> clearSession() async {
    session = null;
  }

  @override
  Future<String?> loadSetting(String key) async => settings[key];

  @override
  Future<void> saveSetting(String key, String value) async {
    settings[key] = value;
  }

  @override
  Future<void> clearAllData() async {
    session = null;
    settings.clear();
  }

  @override
  Future<String?> findAccountNameByEmail(String email) async => null;

  @override
  Future<void> saveAccount({
    required String name,
    required String email,
  }) async {}

  @override
  Future<List<ChatRoom>?> loadRooms() async => null;

  @override
  Future<void> saveRooms(List<ChatRoom> rooms) async {}

  @override
  Future<List<ChatMessage>?> loadMessages(String roomId) async => null;

  @override
  Future<void> saveMessages(String roomId, List<ChatMessage> messages) async {}
}

void main() {
  testWidgets('BUG-02: token mati setelah reseed -> otomatis ke welcome', (
    tester,
  ) async {
    final repo = RepoSesiMati();
    // Sesi lama dengan token yang akan mati di sisi server.
    await repo.saveSession(
      SessionData(
        isGuest: false,
        displayName: 'Andrian Yuza',
        realName: 'Andrian Yuza',
        nim: '2401020157',
        token: 'token-lama-mati',
        userId: '4',
      ),
    );

    final app = AppState(repository: repo, api: ApiTokenMati());
    await app.restore();
    await tester.pumpWidget(UniTalkApp(state: app));
    await tester.pump(const Duration(milliseconds: 300));

    // Token mati tervalidasi -> sesi dibersihkan -> wajib kembali ke welcome.
    expect(find.text('Mulai Berdiskusi Sekarang'), findsOneWidget);
    expect(app.hasSession, isFalse);
    expect(app.nim, '2401020157'); // data profil tetap terbaca dari sesi
  });

  testWidgets('BUG-01: guest tetap bisa masuk saat backend hidup kembali', (
    tester,
  ) async {
    final app = AppState(api: ApiTokenMati());
    app.startSession(isGuest: true, userName: 'Guest');
    await tester.pumpWidget(UniTalkApp(state: app));
    await tester.pumpAndSettle(const Duration(seconds: 1));

    // Guest masuk; daftar room tampil dari cache walau API sedang gagal.
    expect(app.isGuest, isTrue);
    expect(app.rooms, isNotEmpty);
  });
}
