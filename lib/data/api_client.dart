import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../models/app_data.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, [this.statusCode]);

  @override
  String toString() => message;
}

class AuthResult {
  final String token;
  final int userId;
  final String name;
  final String? email;
  final bool isGuest;

  const AuthResult({
    required this.token,
    required this.userId,
    required this.name,
    required this.email,
    required this.isGuest,
  });
}

// Room dari API: model ChatRoom + flag hak akses untuk user sekarang.
class ApiRoom {
  final ChatRoom room;
  final bool isAdmin;
  final bool isMember;

  const ApiRoom({required this.room, required this.isAdmin, required this.isMember});
}

class ApiClient {
  final String _base;
  final http.Client _client;

  static const _timeout = Duration(seconds: 10);

  ApiClient({String? baseUrl, http.Client? client})
      : _base = baseUrl ?? apiBaseUrl(),
        _client = client ?? http.Client();

  // ── Auth ──

  Future<AuthResult> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final data = await _call(
      'POST',
      'register',
      body: {'name': name, 'email': email, 'password': password},
    );
    return _authFrom(data as Map<String, dynamic>);
  }

  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    final data = await _call(
      'POST',
      'login',
      body: {'email': email, 'password': password},
    );
    return _authFrom(data as Map<String, dynamic>);
  }

  Future<AuthResult> guest() async {
    final data = await _call('POST', 'guest');
    return _authFrom(data as Map<String, dynamic>);
  }

  Future<void> logout(String token) async {
    await _call('POST', 'logout', token: token);
  }

  Future<AuthResult> me(String token) async {
    final data = await _call('GET', 'me', token: token);
    final user = (data as Map<String, dynamic>)['user'] as Map<String, dynamic>;
    return AuthResult(
      token: token,
      userId: (user['id'] as num).toInt(),
      name: (user['name'] ?? 'User') as String,
      email: user['email'] as String?,
      isGuest: user['is_guest'] == true,
    );
  }

  Future<void> updateName(String token, String name) async {
    await _call('PATCH', 'me', token: token, body: {'name': name});
  }

  // ── Room ──

  Future<List<ApiRoom>> fetchRooms(String token) async {
    final data = await _call('GET', 'rooms', token: token);
    final list = (data as Map<String, dynamic>)['rooms'] as List<dynamic>;
    return list
        .map((j) => _roomFrom(j as Map<String, dynamic>))
        .toList();
  }

  Future<ApiRoom> createRoom(
    String token, {
    required String name,
    String description = '',
    required String category,
  }) async {
    final data = await _call(
      'POST',
      'rooms',
      token: token,
      body: {'name': name, 'description': description, 'category': category},
    );
    return _roomFrom((data as Map<String, dynamic>)['room'] as Map<String, dynamic>);
  }

  Future<ApiRoom> joinByCode(String token, String code) async {
    final data = await _call(
      'POST',
      'rooms/join',
      token: token,
      body: {'code': code},
    );
    return _roomFrom((data as Map<String, dynamic>)['room'] as Map<String, dynamic>);
  }

  Future<void> deleteRoom(String token, String roomId) async {
    await _call('DELETE', 'rooms/$roomId', token: token);
  }

  // ── Chat ──

  Future<List<ChatMessage>> fetchMessages(String token, String roomId, {int? after}) async {
    final path = after == null ? 'rooms/$roomId/messages' : 'rooms/$roomId/messages?after=$after';
    final data = await _call('GET', path, token: token);
    final list = (data as Map<String, dynamic>)['messages'] as List<dynamic>;
    return list.map((j) => _messageFrom(j as Map<String, dynamic>)).toList();
  }

  Future<ChatMessage> sendMessage(String token, String roomId, String text) async {
    final data = await _call(
      'POST',
      'rooms/$roomId/messages',
      token: token,
      body: {'text': text},
    );
    return _messageFrom((data as Map<String, dynamic>)['message'] as Map<String, dynamic>);
  }

  Future<void> deleteMessage(String token, String messageId) async {
    await _call('DELETE', 'messages/$messageId', token: token);
  }

  // ── Member ──

  Future<List<RoomMember>> fetchMembers(String token, String roomId) async {
    final data = await _call('GET', 'rooms/$roomId/members', token: token);
    final list = (data as Map<String, dynamic>)['members'] as List<dynamic>;
    return list
        .map((j) => RoomMember(
              id: '${(j as Map<String, dynamic>)['id']}',
              name: (j['name'] ?? 'User') as String,
              isAdmin: j['is_admin'] == true,
              isGuest: j['is_guest'] == true,
            ))
        .toList();
  }

  Future<void> kick(String token, String roomId, String userId) async {
    await _call('POST', 'rooms/$roomId/kick', token: token, body: {'user_id': int.parse(userId)});
  }

  // ── Mapping & HTTP helper ──

  AuthResult _authFrom(Map<String, dynamic> data) {
    final user = data['user'] as Map<String, dynamic>;
    return AuthResult(
      token: (data['token'] ?? '') as String,
      userId: (user['id'] as num).toInt(),
      name: (user['name'] ?? 'User') as String,
      email: user['email'] as String?,
      isGuest: user['is_guest'] == true,
    );
  }

  ApiRoom _roomFrom(Map<String, dynamic> j) {
    final category = (j['category'] ?? 'matkul') as String;
    final last = j['last_message'] as Map<String, dynamic>?;
    return ApiRoom(
      isAdmin: j['is_admin'] == true,
      isMember: j['is_member'] == true,
      room: ChatRoom(
        id: '${j['id']}',
        name: (j['name'] ?? '') as String,
        category: category,
        lastMessage: (last?['text'] ?? j['description'] ?? '') as String,
        lastTime: _shortTime(last?['created_at'] as String?),
        unreadCount: 0,
        memberIds: ((j['members'] as List<dynamic>?) ?? const [])
            .map((e) => '$e')
            .toList(),
        createdById: '${j['created_by'] ?? ''}',
        icon: iconForCategory(category),
        color: colorForCategory(category),
        inviteCode: (j['invite_code'] ?? '') as String,
        allowGuest: j['allow_guest'] == true,
      ),
    );
  }

  ChatMessage _messageFrom(Map<String, dynamic> j) => ChatMessage(
        id: '${j['id']}',
        senderId: '${j['sender_id'] ?? ''}',
        senderName: (j['sender_name'] ?? 'Guest') as String,
        text: (j['text'] ?? '') as String,
        createdAt: DateTime.tryParse((j['created_at'] ?? '') as String) ?? DateTime.now(),
      );

  String _shortTime(String? iso) {
    final dt = DateTime.tryParse(iso ?? '');
    if (dt == null) return '';
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  Future<dynamic> _call(
    String method,
    String path, {
    String? token,
    Map<String, dynamic>? body,
  }) async {
    http.Response res;
    final uri = Uri.parse('$_base/$path');
    final headers = <String, String>{
      'Accept': 'application/json',
      if (body != null) 'Content-Type': 'application/json; charset=utf-8',
      if (token != null) 'Authorization': 'Bearer $token',
    };

    try {
      switch (method) {
        case 'POST':
          res = await _client
              .post(uri, headers: headers, body: jsonEncode(body ?? {}))
              .timeout(_timeout);
        case 'PATCH':
          res = await _client
              .patch(uri, headers: headers, body: jsonEncode(body ?? {}))
              .timeout(_timeout);
        case 'DELETE':
          res = await _client.delete(uri, headers: headers).timeout(_timeout);
        default:
          res = await _client.get(uri, headers: headers).timeout(_timeout);
      }
    } catch (_) {
      throw ApiException('Tidak bisa terhubung ke server. Pastikan backend sudah jalan.');
    }

    if (res.statusCode >= 400) {
      String message = 'Terjadi kesalahan (kode ${res.statusCode})';
      try {
        final j = jsonDecode(res.body);
        if (j is Map && j['message'] != null) {
          message = j['message'].toString();
        }
      } catch (_) {
        // Body bukan JSON, pakai pesan default.
      }
      throw ApiException(message, res.statusCode);
    }

    if (res.body.isEmpty) return null;
    return jsonDecode(res.body);
  }
}
