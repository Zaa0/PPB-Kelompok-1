import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/api_client.dart';
import '../models/app_data.dart';
import '../state/app_state.dart';
import 'welcome_screen.dart';

class ChatRoomScreen extends StatefulWidget {
  final ChatRoom room;
  final bool embedded; // true saat ditampilkan di panel kanan (desktop/tablet)
  final VoidCallback? onRoomDeleted;
  final VoidCallback? onClose;

  const ChatRoomScreen({
    super.key,
    required this.room,
    this.embedded = false,
    this.onRoomDeleted,
    this.onClose,
  });

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  final TextEditingController _msgCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  late final AppState _app = context.read<AppState>();
  int _lastMsgCount = 0;
  bool _pinnedBottom = true; // sedang di posisi chat paling bawah?

  @override
  void initState() {
    super.initState();
    // Ambil pesan & anggota dari API, lalu polling pesan baru tiap 3 detik.
    _app.startPolling(widget.room);
    unawaited(_app.loadMessages(widget.room));
    unawaited(_app.loadMembers(widget.room));
    _scrollCtrl.addListener(_onScroll);
  }

  // Pantau posisi user: kalau lagi scroll ke atas, jangan paksa turun.
  void _onScroll() {
    if (!_scrollCtrl.hasClients) return;
    final pos = _scrollCtrl.position;
    _pinnedBottom = pos.maxScrollExtent - pos.pixels < 120;
  }

  void _scrollToBottom({bool animate = false}) {
    if (!_scrollCtrl.hasClients) return;
    final pos = _scrollCtrl.position;
    if (animate) {
      _scrollCtrl.animateTo(
        pos.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    } else {
      _scrollCtrl.jumpTo(pos.maxScrollExtent);
    }
  }

  @override
  void dispose() {
    _app.stopPolling();
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty) return;
    await _app.sendMessage(widget.room, text);
    _msgCtrl.clear();
  }

  // Guest diarahkan ke layar login, bukan sekadar kembali.
  void _goToLogin() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final messages = app.messagesFor(widget.room);

    // Auto-scroll ala WA: saat chat dibuka langsung ke pesan terbaru;
    // pesan baru turun mengikuti kalau kita sedang di posisi paling bawah
    // (atau pesannya dari kita sendiri); kalau lagi baca chat di atas, tetap.
    if (messages.length != _lastMsgCount) {
      final firstLoad = _lastMsgCount == 0;
      final pesanDariSaya =
          messages.isNotEmpty && messages.last.isSentBy(app.userId);
      final adaPesanBaru =
          messages.length > _lastMsgCount && _lastMsgCount > 0;
      _lastMsgCount = messages.length;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (firstLoad || pesanDariSaya || (adaPesanBaru && _pinnedBottom)) {
          _scrollToBottom(animate: pesanDariSaya || adaPesanBaru);
        }
      });
    }

    final body = _buildBody(app);
    if (widget.embedded) {
      return Column(
        children: [
          _buildAppBar(app),
          Expanded(child: body),
        ],
      );
    }
    return Scaffold(
      backgroundColor: const Color(0xFFF0F6FF),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(65),
        child: _buildAppBar(app),
      ),
      body: body,
    );
  }

  Widget _buildAppBar(AppState app) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1E3A8A), Color(0xFF1D4ED8)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            children: [
              if (!widget.embedded)
                IconButton(
                  icon: const Icon(
                    Icons.arrow_back_ios,
                    color: Colors.white,
                    size: 20,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: widget.room.color.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(widget.room.icon, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      widget.room.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${widget.room.memberCount} anggota • ${widget.room.category == 'matkul'
                          ? 'Mata Kuliah'
                          : widget.room.category == 'organisasi'
                          ? 'Organisasi'
                          : 'Topik Bebas'}',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 11,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: Colors.white),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                onSelected: (val) {
                  if (val == 'Anggota') {
                    _memberSheet();
                  } else if (val == 'Keluar') {
                    if (widget.embedded) {
                      widget.onClose?.call();
                    } else {
                      Navigator.pop(context);
                    }
                  } else if (val == 'HapusRoom') {
                    _confirmHapusRoom();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Fitur "$val" belum tersedia'),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    );
                  }
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: 'Anggota',
                    child: Text('Lihat Anggota'),
                  ),
                  const PopupMenuItem(value: 'Cari', child: Text('Cari Pesan')),
                  const PopupMenuItem(
                    value: 'Mute',
                    child: Text('Mute Notifikasi'),
                  ),
                  const PopupMenuItem(
                    value: 'Keluar',
                    child: Text(
                      'Keluar dari Room',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                  if (app.isAdmin(widget.room))
                    const PopupMenuItem(
                      value: 'HapusRoom',
                      child: Text(
                        'Hapus Room',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(AppState app) {
    final messages = app.messagesFor(widget.room);
    return Column(
      children: [
        // Guest banner
        if (app.isGuest)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: Colors.orange.shade50,
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Colors.orange.shade700,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.room.allowGuest
                        ? 'Anda dalam mode Guest. Anda tetap bisa mengirim pesan di room ini.'
                        : 'Anda dalam mode Guest. Login untuk mengirim pesan.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.orange.shade700,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: _goToLogin,
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                  ),
                  child: Text(
                    'Login',
                    style: TextStyle(
                      color: Colors.orange.shade800,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        // Messages
        Expanded(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: ListView.builder(
                controller: _scrollCtrl,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                itemCount: messages.length,
                itemBuilder: (context, i) {
                  final msg = messages[i];
                  final showDate = i == 0;
                  return Column(
                    children: [
                      if (showDate) const _DateDivider(date: 'Hari ini'),
                      GestureDetector(
                        onLongPress:
                            (msg.isSentBy(app.userId) ||
                                app.isAdmin(widget.room))
                            ? () => _confirmHapus(msg)
                            : null,
                        child: _MessageBubble(
                          message: msg,
                          isMe: msg.isSentBy(app.userId),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
        // Input
        if (app.canPostIn(widget.room))
          _buildInputBar()
        else
          _buildGuestBar(),
      ],
    );
  }

  // ── Admin: hapus pesan ──
  void _confirmHapus(ChatMessage msg) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus pesan?'),
        content: Text('"${msg.text}" akan dihapus untuk semua anggota.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await _app.deleteMessage(widget.room, msg);
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  // ── Admin: lihat + keluarkan anggota ──
  void _memberSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        final app = ctx.watch<AppState>();
        final members = app.membersFor(widget.room);
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Anggota (${widget.room.memberCount})',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Menampilkan ${members.length} anggota',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  for (final m in members)
                    ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        child: Text(
                          m.name.isNotEmpty ? m.name[0].toUpperCase() : '?',
                        ),
                      ),
                      title: Text(m.name),
                      subtitle: m.isAdmin
                          ? const Text('Admin')
                          : (m.isGuest ? const Text('Guest') : null),
                      trailing: (app.isAdmin(widget.room) && m.id != app.userId)
                          ? TextButton(
                              onPressed: () async {
                                await app.kickMember(widget.room, m);
                                if (!mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('${m.name} dikeluarkan'),
                                  ),
                                );
                              },
                              child: const Text(
                                'Keluarkan',
                                style: TextStyle(color: Colors.red),
                              ),
                            )
                          : null,
                    ),
                  if (!app.isAdmin(widget.room))
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text(
                        'Hanya admin room yang bisa mengeluarkan anggota.',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ── Admin: hapus room ──
  void _confirmHapusRoom() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus room?'),
        content: Text('"${widget.room.name}" akan dihapus untuk semua anggota.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await _app.deleteRoom(widget.room);
              } on ApiException catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(e.message)),
                );
                return;
              }
              if (!mounted) return;
              if (widget.embedded) {
                widget.onRoomDeleted?.call();
              } else {
                Navigator.pop(context, true); // true = home ikut hapus
              }
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.attach_file_outlined,
                    color: Color(0xFF64748B),
                  ),
                  onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Lampiran file belum tersedia'),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: TextField(
                      controller: _msgCtrl,
                      maxLines: null,
                      keyboardType: TextInputType.multiline,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        hintText: 'Tulis pesan...',
                        hintStyle: TextStyle(
                          color: Color(0xFFB0BAC8),
                          fontSize: 14,
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _sendMessage,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.send_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGuestBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: const Text(
                    'Login untuk mengirim pesan...',
                    style: TextStyle(color: Color(0xFFB0BAC8), fontSize: 14),
                  ),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: _goToLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E3A8A),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Text('Login'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DateDivider extends StatelessWidget {
  final String date;
  const _DateDivider({required this.date});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Expanded(child: Divider(color: Colors.grey.shade300)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                date,
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
              ),
            ),
          ),
          Expanded(child: Divider(color: Colors.grey.shade300)),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isMe;
  const _MessageBubble({required this.message, required this.isMe});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: 8,
        left: isMe ? 48 : 0,
        right: isMe ? 0 : 48,
      ),
      child: Row(
        mainAxisAlignment: isMe
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            Container(
              width: 32,
              height: 32,
              margin: const EdgeInsets.only(right: 8, bottom: 2),
              decoration: BoxDecoration(
                color: colorForSender(
                  message.senderName,
                ).withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  message.senderInitial,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: colorForSender(message.senderName),
                  ),
                ),
              ),
            ),
          ],
          Flexible(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                crossAxisAlignment: isMe
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  if (!isMe)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 3, left: 4),
                      child: Text(
                        message.senderName,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: colorForSender(message.senderName),
                        ),
                      ),
                    ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: isMe ? const Color(0xFF1E3A8A) : Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(16),
                        topRight: const Radius.circular(16),
                        bottomLeft: isMe
                            ? const Radius.circular(16)
                            : const Radius.circular(4),
                        bottomRight: isMe
                            ? const Radius.circular(4)
                            : const Radius.circular(16),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Text(
                      message.text,
                      style: TextStyle(
                        fontSize: 14,
                        color: isMe ? Colors.white : const Color(0xFF0F172A),
                        height: 1.4,
                      ),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      message.timeLabel,
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade400,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isMe) const SizedBox(width: 4),
        ],
      ),
    );
  }
}
