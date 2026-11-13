import '../models/app_data.dart';

// Sesi yang tersimpan antar buka-tutup aplikasi.
class SessionData {
  final bool isGuest;
  final String displayName;

  const SessionData({required this.isGuest, required this.displayName});
}

// Batas sumber data aplikasi. Implementasinya sekarang lokal
// (shared_preferences + Hive); nanti tinggal ditambah implementasi REST
// untuk Laravel tanpa perlu menyentuh UI maupun AppState.
abstract class AppRepository {
  Future<void> init();

  Future<SessionData?> loadSession();
  Future<void> saveSession(SessionData session);
  Future<void> clearSession();

  // Akun terdaftar (mock lokal; password sengaja tidak disimpan —
  // auth beneran menyusul di stage backend).
  Future<String?> findAccountNameByEmail(String email);
  Future<void> saveAccount({required String name, required String email});

  // null artinya belum pernah ada data tersimpan (kondisi pertama kali),
  // supaya bisa dibedakan dengan data kosong yang memang dihapus user.
  Future<List<ChatRoom>?> loadRooms();
  Future<void> saveRooms(List<ChatRoom> rooms);

  Future<List<ChatMessage>?> loadMessages(String roomId);
  Future<void> saveMessages(String roomId, List<ChatMessage> messages);
}
