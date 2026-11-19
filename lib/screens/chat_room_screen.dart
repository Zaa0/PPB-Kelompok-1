import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';

import '../data/api_client.dart';
import '../theme/chat_theme.dart';
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
  bool _sending = false; // pesan sedang dikirim ke server?
  Uint8List? _attachmentBytes; // lampiran yang siap dikirim
  String? _attachmentName;

  @override
  void initState() {
    super.initState();
    // Ambil pesan & anggota dari API, lalu polling pesan baru tiap 1 detik.
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
    if ((text.isEmpty && _attachmentBytes == null) || _sending) return;
    setState(() => _sending = true);
    final sukses = await _app.sendMessage(
      widget.room,
      text,
      attachmentBytes: _attachmentBytes,
      attachmentName: _attachmentName,
    );
    _msgCtrl.clear();
    if (mounted) {
      setState(() {
        _sending = false;
        _attachmentBytes = null;
        _attachmentName = null;
      });
      if (!sukses) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pesan gagal terkirim, coba lagi')),
        );
      }
    }
  }

  Future<void> _pilihLampiran() async {
    final files = await FilePicker.pickFiles();
    if (files.isEmpty) return;
    final f = files.first;
    final ukuran = await f.length();
    if (ukuran != null && ukuran > 10 * 1024 * 1024) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ukuran lampiran maksimal 10 MB')),
      );
      return;
    }
    final bytes = await f.readAsBytes();
    if (!mounted) return;
    setState(() {
      _attachmentBytes = bytes;
      _attachmentName = f.name;
    });
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
      resizeToAvoidBottomInset: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
                  tooltip: 'Kembali',
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
                tooltip: 'Menu room',
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
                        ? 'Kamu sedang mode Guest. Kamu tetap bisa mengirim pesan di room ini.'
                        : 'Kamu sedang mode Guest. Login untuk mengirim pesan.',
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
                  // Gabung bubble berurutan dari pengirim yang sama:
                  // nama+avatar hanya di awal grup, jam+centang di akhir grup.
                  final prev = i > 0 ? messages[i - 1] : null;
                  final next =
                      i + 1 < messages.length ? messages[i + 1] : null;
                  bool jedaTengah(ChatMessage? a, ChatMessage? b) =>
                      a == null ||
                      b == null ||
                      a.senderId != b.senderId ||
                      b.createdAt.difference(a.createdAt).inMinutes >= 5;
                  final mulaiGrup = jedaTengah(prev, msg);
                  final akhirGrup = jedaTengah(msg, next);
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
                          showHeader: mulaiGrup,
                          showTime: akhirGrup,
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
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
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
    final border = Theme.of(context).brightness == Brightness.dark
        ? UniTalkChatTheme.darkBorder
        : UniTalkChatTheme.lightBorder;
    return Container(
      // Hanya garis pemisah tipis di atas - field-nya yang diberi kotak
      // sendiri supaya tidak ada kotak dobel/tumpang tindih.
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: border)),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
            child: Row(
              children: [
                IconButton(
                  tooltip: 'Lampirkan foto atau dokumen (maks 10 MB)',
                  icon: Icon(
                    Icons.attach_file_outlined,
                    color: _attachmentBytes != null
                        ? Theme.of(context).colorScheme.primary
                        : const Color(0xFF64748B),
                  ),
                  onPressed: _pilihLampiran,
                ),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? UniTalkChatTheme.darkInputBg
                          : Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: border),
                    ),
                    child: TextField(
                      controller: _msgCtrl,
                      maxLines: null,
                      keyboardType: TextInputType.multiline,
                      textCapitalization: TextCapitalization.sentences,
                      onChanged: (v) {
                        // Di desktop/web: Enter mengirim, Shift+Enter baris baru.
                        if (v.endsWith('\n') &&
                            !HardwareKeyboard.instance.isShiftPressed) {
                          final bersih = v.substring(0, v.length - 1);
                          _msgCtrl.value = TextEditingValue(
                            text: bersih,
                            selection: TextSelection.collapsed(
                              offset: bersih.length,
                            ),
                          );
                          _sendMessage();
                        }
                      },
                      decoration: InputDecoration(
                        hintText: 'Tulis pesan...',
                        hintStyle: TextStyle(
                          fontSize: 14,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurfaceVariant,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Tombol kirim dinamis ala chat modern: kosong = ikon suara,
                // ada teks = paper plane; saat mengirim tampil spinner.
                ValueListenableBuilder<TextEditingValue>(
                  valueListenable: _msgCtrl,
                  builder: (context, value, _) {
                    final adaTeks = value.text.trim().isNotEmpty || _sending;
                    return Tooltip(
                      message: 'Kirim pesan',
                      child: GestureDetector(
                        onTap: _sendMessage,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            gradient: adaTeks
                                ? const LinearGradient(
                                    colors: [
                                      Color(0xFF1E3A8A),
                                      Color(0xFF3B82F6),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  )
                                : null,
                            color: adaTeks ? null : Colors.grey.shade300,
                            shape: BoxShape.circle,
                          ),
                          child: _sending
                              ? const Padding(
                                  padding: EdgeInsets.all(11),
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 180),
                                  transitionBuilder: (child, anim) =>
                                      ScaleTransition(scale: anim, child: child),
                                  child: Icon(
                                    adaTeks
                                        ? Icons.send_rounded
                                        : Icons.keyboard_voice_rounded,
                                    key: ValueKey(adaTeks),
                                    color: adaTeks
                                        ? Colors.white
                                        : Colors.grey.shade500,
                                    size: 20,
                                  ),
                                ),
                        ),
                      ),
                    );
                  },
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
        color: Theme.of(context).colorScheme.surface,
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
                  child: Text(
                    'Login untuk mengirim pesan...',
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
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
    final gelap = Theme.of(context).brightness == Brightness.dark;
    final bg = gelap
        ? UniTalkChatTheme.darkInputBg
        : UniTalkChatTheme.lightBubbleOther;
    final warnaTeks = gelap
        ? UniTalkChatTheme.darkTextSecondary
        : UniTalkChatTheme.lightTextSecondary;
    final garis = gelap
        ? UniTalkChatTheme.darkBorder
        : UniTalkChatTheme.lightBorder;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Expanded(child: Divider(color: garis)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: garis),
              ),
              child: Text(
                date,
                style: TextStyle(fontSize: 11, color: warnaTeks),
              ),
            ),
          ),
          Expanded(
            child: Divider(
              color: Theme.of(
                context,
              ).colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isMe;
  final bool showHeader; // tampil avatar + nama (awal grup)
  final bool showTime; // tampil jam + centang (akhir grup)
  const _MessageBubble({
    required this.message,
    required this.isMe,
    this.showHeader = true,
    this.showTime = true,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: showTime ? 8 : 2,
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
            // Slot avatar tetap ada biar bubble lanjutan tetap sejajar.
            if (showHeader)
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
              )
            else
              const SizedBox(width: 40),
          ],
          Flexible(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                crossAxisAlignment: isMe
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  if (!isMe && showHeader)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 3, left: 4),
                      child: Text(
                        message.senderName,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? UniTalkChatTheme.darkSenderName
                              : UniTalkChatTheme.lightSenderName,
                        ),
                      ),
                    ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: isMe
                          ? (Theme.of(context).brightness == Brightness.dark
                                ? UniTalkChatTheme.darkBubbleMe
                                : UniTalkChatTheme.lightBubbleMe)
                          : (Theme.of(context).brightness == Brightness.dark
                                ? UniTalkChatTheme.darkBubbleOther
                                : UniTalkChatTheme.lightBubbleOther),
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
                        color: isMe
                            ? Colors.white
                            : (Theme.of(context).brightness == Brightness.dark
                                  ? UniTalkChatTheme.darkTextPrimary
                                  : UniTalkChatTheme.lightTextPrimary),
                        height: 1.4,
                      ),
                    ),
                  ),
                  if (showTime) ...[
                    const SizedBox(height: 3),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            message.timeLabel,
                            style: TextStyle(
                              fontSize: 10,
                              color: Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? UniTalkChatTheme.darkTextSecondary
                                  : UniTalkChatTheme.lightTextSecondary,
                            ),
                          ),
                          // Centang terkirim: satu = masih lokal, dua = sudah di server.
                          if (isMe) ...[
                            const SizedBox(width: 3),
                            Icon(
                              message.pending ? Icons.done : Icons.done_all,
                              size: 12,
                              color: message.pending
                                  ? Colors.grey.shade400
                                  : const Color(0xFF3B82F6),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
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
