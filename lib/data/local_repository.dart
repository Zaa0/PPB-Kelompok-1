import 'dart:convert';

import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_data.dart';
import 'app_repository.dart';

// Simpanan lokal: session + akun di shared_preferences,
// room & pesan di Hive (jalan di Android, web, dan desktop).
class LocalRepository implements AppRepository {
  static const _sessionKey = 'unitalk_session';
  static const _accountsKey = 'unitalk_accounts';
  static const _roomsBox = 'unitalk_rooms';
  static const _messagesBox = 'unitalk_messages';

  SharedPreferences? _prefs;
  Box? _rooms;
  Box? _messages;

  @override
  Future<void> init() async {
    await Hive.initFlutter();
    _rooms = await Hive.openBox(_roomsBox);
    _messages = await Hive.openBox(_messagesBox);
    _prefs = await SharedPreferences.getInstance();
  }

  // ── Sesi ──

  @override
  Future<SessionData?> loadSession() async {
    final raw = _prefs?.getString(_sessionKey);
    if (raw == null) return null;
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      return SessionData(
        isGuest: (json['isGuest'] ?? false) as bool,
        displayName: (json['displayName'] ?? 'User') as String,
        token: json['token'] as String?,
        userId: json['userId'] as String?,
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> saveSession(SessionData session) async {
    await _prefs?.setString(
      _sessionKey,
      jsonEncode({
        'isGuest': session.isGuest,
        'displayName': session.displayName,
        'token': session.token,
        'userId': session.userId,
      }),
    );
  }

  @override
  Future<void> clearSession() async {
    await _prefs?.remove(_sessionKey);
  }

  // ── Akun mock ──

  @override
  Future<String?> findAccountNameByEmail(String email) async {
    final list = _prefs?.getStringList(_accountsKey) ?? const [];
    final e = email.trim().toLowerCase();
    for (final raw in list) {
      try {
        final json = jsonDecode(raw) as Map<String, dynamic>;
        if (((json['email'] ?? '') as String).toLowerCase() == e) {
          return (json['name'] ?? '') as String;
        }
      } catch (_) {
        // Baris rusak diabaikan saja.
      }
    }
    return null;
  }

  @override
  Future<void> saveAccount({
    required String name,
    required String email,
  }) async {
    final prefs = _prefs;
    if (prefs == null) return;
    final list = List<String>.from(
      prefs.getStringList(_accountsKey) ?? const [],
    );
    final e = email.trim().toLowerCase();
    // Email yang sama berarti update nama, tidak dibuat dobel.
    list.removeWhere((raw) {
      try {
        final json = jsonDecode(raw) as Map<String, dynamic>;
        return ((json['email'] ?? '') as String).toLowerCase() == e;
      } catch (_) {
        return false;
      }
    });
    list.add(jsonEncode({'name': name, 'email': e}));
    await prefs.setStringList(_accountsKey, list);
  }

  // ── Room & pesan ──

  @override
  Future<List<ChatRoom>?> loadRooms() async {
    final raw = _rooms?.get('all');
    if (raw is! List) return null;
    return raw
        .whereType<Map>()
        .map((m) => ChatRoom.fromJson(Map<String, dynamic>.from(m)))
        .toList();
  }

  @override
  Future<void> saveRooms(List<ChatRoom> rooms) async {
    await _rooms?.put('all', rooms.map((r) => r.toJson()).toList());
  }

  @override
  Future<List<ChatMessage>?> loadMessages(String roomId) async {
    final raw = _messages?.get(roomId);
    if (raw is! List) return null;
    return raw
        .whereType<Map>()
        .map((m) => ChatMessage.fromJson(Map<String, dynamic>.from(m)))
        .toList();
  }

  @override
  Future<void> saveMessages(String roomId, List<ChatMessage> messages) async {
    await _messages?.put(roomId, messages.map((m) => m.toJson()).toList());
  }
}
