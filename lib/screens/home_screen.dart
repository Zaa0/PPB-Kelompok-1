import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/api_client.dart';
import '../theme/chat_theme.dart';
import '../models/app_data.dart';
import '../state/app_state.dart';
import 'chat_room_screen.dart';
import 'settings_screen.dart';
import 'welcome_screen.dart';

class HomeScreen extends StatefulWidget {
  final bool isGuest;
  final String userName;

  // Parameternya tetap ada supaya screen bisa dipanggil langsung (mis. dari
  // test); kalau sesi sudah ada di AppState, parameternya diabaikan.
  const HomeScreen({super.key, this.isGuest = false, this.userName = 'User'});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _bottomIndex = 0;
  String _searchQuery = '';
  ChatRoom? _selectedRoom;
  bool _fabOpen = false; // menu animasi FAB terbuka?

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    context.read<AppState>().ensureSession(
          isGuest: widget.isGuest,
          userName: widget.userName,
        );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  bool get _isWide => MediaQuery.sizeOf(context).width >= 900;

  List<ChatRoom> _filteredRooms(AppState app, String category) {
    final rooms = app.rooms.where((r) => r.category == category).toList();
    if (_searchQuery.isEmpty) return rooms;
    return rooms
        .where((r) => r.name.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  // ── Buat room baru (khusus akun terdaftar) ──
  void _createDialog() {
    final namaCtrl = TextEditingController();
    final deskCtrl = TextEditingController();
    String kategori = 'matkul';
    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setDlg) => AlertDialog(
          title: const Text('Buat Room Baru'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: namaCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Nama room',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: deskCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Deskripsi',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children: ['matkul', 'organisasi', 'topik'].map((k) {
                    return ChoiceChip(
                      label: Text(k),
                      selected: kategori == k,
                      onSelected: (_) => setDlg(() => kategori = k),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (namaCtrl.text.trim().isEmpty) return;
                final app = context.read<AppState>();
                final nama = namaCtrl.text.trim();
                final desk = deskCtrl.text.trim();
                Navigator.pop(ctx);
                try {
                  final room = await app.createRoom(
                    name: nama,
                    description: desk,
                    category: kategori,
                  );
                  if (!mounted) return;
                  if (_isWide) {
                    setState(() => _selectedRoom = room);
                  }
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Room dibuat! Kode undangan: ${room.inviteCode}',
                      ),
                    ),
                  );
                } on ApiException catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(e.message)),
                  );
                }
              },
              child: const Text('Buat'),
            ),
          ],
        ),
      ),
    );
  }

  // ── Gabung room pakai kode undangan ──
  void _joinDialog() {
    final kodeCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Gabung dengan Kode'),
        content: TextField(
          controller: kodeCtrl,
          decoration: const InputDecoration(
            labelText: 'cth: UT-101',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.vpn_key_outlined),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
            ElevatedButton(
              onPressed: () async {
                final kode = kodeCtrl.text.trim();
                if (kode.isEmpty) return;
                final app = context.read<AppState>();
                Navigator.pop(ctx);
                try {
                  final room = await app.joinByCode(kode);
                  if (!mounted) return;
                  if (room == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Kode tidak ditemukan')),
                    );
                    return;
                  }
                  _openRoom(room);
                } on ApiException catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(e.message)),
                  );
                }
              },
              child: const Text('Gabung'),
            ),
        ],
      ),
    );
  }

  // ── Buka room: desktop pilih di panel kanan, mobile buka halaman baru ──
  void _openRoom(ChatRoom room) {
    if (_isWide) {
      setState(() => _selectedRoom = room);
    } else {
      _openChat(room);
    }
  }

  Future<void> _openChat(ChatRoom room) async {
    final hapus = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ChatRoomScreen(room: room)),
    );
    if (hapus == true && mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Room dihapus')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    // Kalau sesi API mati (token 401 dipaksa logout), kembali ke welcome.
    if (app.isOnline && !app.hasSession) {
      return const WelcomeScreen();
    }
    final wide = _isWide;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          SafeArea(
            child: wide
                ? _buildWideLayout(app)
                : switch (_bottomIndex) {
                    1 => const SettingsBody(),
                    2 => _buildProfileBody(app),
                    _ => _buildHomeBody(app),
                  },
          ),
          // Banner ala Telegram: pesan baru masuk di room lain.
          if (app.banner != null)
            _NewMessageBanner(
              key: ValueKey(
                '${app.banner!['roomId']}-${app.banner!['text']}',
              ),
              banner: app.banner!,
              onClose: () => app.clearBanner(),
              onOpen: () {
                final roomId = app.banner!['roomId'];
                final match = app.rooms
                    .where((r) => r.id == roomId)
                    .toList();
                app.clearBanner();
                if (match.isNotEmpty) _openRoom(match.first);
              },
            ),
        ],
      ),
      // FAB hanya di layar kecil dan di tab beranda; di desktop aksi ada di header.
      floatingActionButton:
          (!wide && _bottomIndex == 0) ? _buildSpeedDial(app) : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _bottomIndex,
        onDestinationSelected: (i) => setState(() => _bottomIndex = i),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 8,
        indicatorColor: Theme.of(
          context,
        ).colorScheme.primary.withValues(alpha: 0.15),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Beranda',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Pengaturan',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      ),
    );
  }

  // FAB ala WA: ikon bulat saja, ditekan muncul menu animasi pilihan aksi.
  Widget _buildSpeedDial(AppState app) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        IgnorePointer(
          ignoring: !_fabOpen,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 180),
            opacity: _fabOpen ? 1 : 0,
            child: AnimatedScale(
              duration: const Duration(milliseconds: 180),
              scale: _fabOpen ? 1 : 0.6,
              alignment: Alignment.bottomRight,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (!app.isGuest)
                    _dialItem(
                      icon: Icons.add_comment_outlined,
                      label: 'Buat Room',
                      onTap: () {
                        setState(() => _fabOpen = false);
                        _createDialog();
                      },
                    ),
                  const SizedBox(height: 10),
                  _dialItem(
                    icon: Icons.vpn_key_outlined,
                    label: 'Gabung dengan Kode',
                    onTap: () {
                      setState(() => _fabOpen = false);
                      _joinDialog();
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        FloatingActionButton(
          heroTag: 'fab-utama',
          onPressed: () => setState(() => _fabOpen = !_fabOpen),
          backgroundColor: const Color(0xFF1E3A8A),
          child: AnimatedRotation(
            turns: _fabOpen ? 0.125 : 0,
            duration: const Duration(milliseconds: 180),
            child: Icon(
              _fabOpen ? Icons.close : Icons.add_comment_outlined,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _dialItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
        const SizedBox(width: 10),
        FloatingActionButton.small(
          heroTag: 'dial-$label',
          onPressed: onTap,
          backgroundColor: Theme.of(context).colorScheme.surface,
          foregroundColor: Theme.of(context).colorScheme.primary,
          child: Icon(icon),
        ),
      ],
    );
  }

  // ── Layout lebar: sidebar room + panel chat ──
  Widget _buildWideLayout(AppState app) {
    if (_bottomIndex == 1) return const SettingsBody();
    if (_bottomIndex == 2) return _buildProfileBody(app);
    final gelap = Theme.of(context).brightness == Brightness.dark;
    final panelBg = gelap
        ? UniTalkChatTheme.darkSidebar
        : UniTalkChatTheme.lightSidebar;
    final garis = gelap
        ? UniTalkChatTheme.darkBorder
        : UniTalkChatTheme.lightBorder;
    return Row(
      children: [
        Container(
          width: 400,
          decoration: BoxDecoration(
            color: panelBg,
            border: Border(right: BorderSide(color: garis)),
          ),
          child: _buildSidebar(app),
        ),
        Expanded(child: _buildChatPane(app)),
      ],
    );
  }

  Widget _buildSidebar(AppState app) {
    return Column(
      children: [
        _buildHeader(app),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildRoomList(app, 'matkul'),
              _buildRoomList(app, 'organisasi'),
              _buildRoomList(app, 'topik'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHomeBody(AppState app) {
    return Column(
      children: [
        _buildHeader(app),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildRoomList(app, 'matkul'),
              _buildRoomList(app, 'organisasi'),
              _buildRoomList(app, 'topik'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildChatPane(AppState app) {
    final room = _selectedRoom;
    if (room == null) {
      return const _EmptyChatPane();
    }
    return ChatRoomScreen(
      key: ValueKey(room.id),
      room: room,
      embedded: true,
      onClose: () => setState(() => _selectedRoom = null),
      // Room sudah dihapus lewat AppState di ChatRoomScreen;
      // di sini cukup tutup panelnya.
      onRoomDeleted: () => setState(() => _selectedRoom = null),
    );
  }

  Widget _buildHeader(AppState app) {
    final gelap = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      decoration: BoxDecoration(
        color: gelap ? UniTalkChatTheme.darkHeader : null,
        gradient: gelap
            ? null
            : const LinearGradient(
                colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
        border: gelap
            ? const Border(bottom: BorderSide(color: UniTalkChatTheme.darkBorder))
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    app.displayName.isNotEmpty
                        ? app.displayName[0].toUpperCase()
                        : 'G',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Halo, ${app.displayName}! 👋',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      '${app.isGuest ? 'Mode Guest – Fitur terbatas' : 'Mahasiswa Aktif'}'
                      '${app.offlineMode ? ' • Offline' : ''}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              // Di desktop FAB tidak ada, aksi balik ke header.
              if (_isWide)
                IconButton(
                  tooltip: 'Gabung dengan kode',
                  icon: const Icon(Icons.vpn_key_outlined, color: Colors.white),
                  onPressed: _joinDialog,
                ),
              if (_isWide && !app.isGuest)
                IconButton(
                  tooltip: 'Buat room',
                  icon: const Icon(
                    Icons.add_circle_outline,
                    color: Colors.white,
                  ),
                  onPressed: _createDialog,
                ),
              if (app.isGuest)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.orange.withValues(alpha: 0.5),
                    ),
                  ),
                  child: const Text(
                    'GUEST',
                    style: TextStyle(
                      color: Colors.orange,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
              else
                Stack(
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.notifications_outlined,
                        color: Colors.white,
                      ),
                      onPressed: () =>
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('3 notifikasi baru'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          ),
                    ),
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        width: 16,
                        height: 16,
                        decoration: const BoxDecoration(
                          color: Color(0xFFEF4444),
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: Text(
                            '3',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 16),
          // Search bar
          Container(
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
            ),
            child: TextField(
              onChanged: (v) => setState(() => _searchQuery = v),
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                // Timpa tema global (fill putih) biar hint terbaca di header biru.
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.0),
                hintText: 'Cari chat room...',
                hintStyle: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 14,
                ),
                prefixIcon: Icon(
                  Icons.search,
                  color: Colors.white.withValues(alpha: 0.6),
                  size: 20,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TabBar(
            controller: _tabController,
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white60,
            labelStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
            tabs: const [
              Tab(text: 'Mata Kuliah'),
              Tab(text: 'Organisasi'),
              Tab(text: 'Topik Bebas'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRoomList(AppState app, String category) {
    final rooms = _filteredRooms(app, category);
    // Loading pertama saat ambil daftar room dari API.
    if (app.loadingRooms && app.rooms.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (rooms.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off, size: 48, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text(
              'Tidak ada room ditemukan',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 80),
      itemCount: rooms.length,
      itemBuilder: (context, i) => _RoomCard(
        room: rooms[i],
        unread: app.unreadFor(rooms[i].id),
        isGuest: widget.isGuest,
        selected: _isWide && _selectedRoom?.id == rooms[i].id,
        onTap: () => _openRoom(rooms[i]),
      ),
    );
  }

  Widget _buildProfileBody(AppState app) {
    final myRooms = app.myRooms;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const SizedBox(height: 20),
              // Profile card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.4),
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          app.displayName.isNotEmpty
                              ? app.displayName[0].toUpperCase()
                              : 'G',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 30,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Nama panjang asli (dari registrasi, bukan alias).
                        Text(
                          app.isGuest ? app.displayName : app.realName,
                          maxLines: 2,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (!app.isGuest && app.nim.isNotEmpty)
                          // NIM fix: sekali diisi saat daftar, tidak bisa diubah.
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.badge_outlined,
                                  color: Colors.white70,
                                  size: 14,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'NIM ${app.nim}',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(height: 8),
                        // Nama tampil (alias) di chat - ini yang bisa diubah.
                        GestureDetector(
                          onTap: !app.isGuest
                              ? () {
                                  final ctrl = TextEditingController(
                                    text: app.displayName,
                                  );
                                  showDialog(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      title: const Text('Ubah Nama Tampil'),
                                      content: TextField(
                                        controller: ctrl,
                                        decoration: const InputDecoration(
                                          labelText: 'Nama tampil di chat',
                                          border: OutlineInputBorder(),
                                        ),
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(ctx),
                                          child: const Text('Batal'),
                                        ),
                                        ElevatedButton(
                                          onPressed: () {
                                            if (ctrl.text.trim().isEmpty) {
                                              return;
                                            }
                                            context.read<AppState>().rename(
                                                  ctrl.text.trim(),
                                                );
                                            Navigator.pop(ctx);
                                          },
                                          child: const Text('Simpan'),
                                        ),
                                      ],
                                    ),
                                  );
                                }
                              : null,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 2,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Flexible(
                                  child: Text(
                                    app.isGuest
                                        ? 'Tanpa nama tampil'
                                        : 'Nama tampil: ${app.displayName}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                if (!app.isGuest)
                                  const Icon(
                                    Icons.edit_outlined,
                                    color: Colors.white70,
                                    size: 13,
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: app.isGuest
                            ? Colors.orange.withValues(alpha: 0.3)
                            : Colors.green.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        app.isGuest ? 'Guest' : 'Mahasiswa Aktif',
                        style: TextStyle(
                          color: app.isGuest
                              ? Colors.orange.shade200
                              : Colors.green.shade200,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              if (app.isGuest) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.orange.shade600),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Mode Guest Aktif',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.orange.shade800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Login untuk dapat membuat room dan bergabung penuh',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.orange.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              _ProfileMenuItem(
                icon: Icons.chat_bubble_outline,
                label: 'Room Saya',
                subtitle: '${myRooms.length} room dibuat',
                onTap: () => _showRoomSaya(myRooms),
              ),
              _ProfileMenuItem(
                icon: Icons.notifications_outlined,
                label: 'Notifikasi',
                subtitle: 'Kelola notifikasi',
                onTap: () => _showInfo(
                  'Notifikasi',
                  'Tidak ada notifikasi baru.\n\nNotifikasi room dan pesan akan muncul di sini pada versi berikutnya.',
                ),
              ),
              _ProfileMenuItem(
                icon: Icons.privacy_tip_outlined,
                label: 'Privasi & Keamanan',
                subtitle: 'Pengaturan akun',
                onTap: () => _showInfo(
                  'Privasi & Keamanan',
                  'Nama yang tampil di obrolan berupa alias, sedangkan akun asli tetap tercatat di sistem. '
                      'Nomor pribadi tidak dibagikan karena bergabung menggunakan kode undangan.',
                ),
              ),
              _ProfileMenuItem(
                icon: Icons.help_outline,
                label: 'Bantuan',
                subtitle: 'FAQ & dukungan',
                onTap: () => _showInfo(
                  'Bantuan',
                  'FAQ singkat:\n\n'
                      '• Gabung room: tekan ikon kunci lalu masukkan kode undangan.\n'
                      '• Buat room: tekan tombol Buat Room, khusus akun mahasiswa.\n'
                      '• Kirim pesan: guest hanya bisa di room bertanda allowGuest.\n'
                      '• Moderasi: admin room dapat menghapus pesan dan mengeluarkan anggota.',
                ),
              ),
              _ProfileMenuItem(
                icon: Icons.info_outline,
                label: 'Tentang UniTalk',
                subtitle: 'Versi 1.0.0',
                onTap: () => showAboutDialog(
                  context: context,
                  applicationIcon: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.asset(
                      'assets/icon/icon.png',
                      width: 48,
                      height: 48,
                      fit: BoxFit.cover,
                    ),
                  ),
                  applicationName: 'UniTalk',
                  applicationVersion: '1.0.0',
                  applicationLegalese: 'Kelompok 1 – Pemrograman Perangkat Bergerak, Teknik Informatika UMRAH',
                  children: const [
                    SizedBox(height: 12),
                    Text(
                      'Platform diskusi dan berbagi informasi anonim bagi mahasiswa.',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    context.read<AppState>().logout();
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const WelcomeScreen()),
                      (route) => false,
                    );
                  },
                  icon: const Icon(Icons.logout, color: Color(0xFFEF4444)),
                  label: const Text(
                    'Keluar',
                    style: TextStyle(
                      color: Color(0xFFEF4444),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFEF4444)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showInfo(String title, String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  void _showRoomSaya(List<ChatRoom> myRooms) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Room Saya'),
        content: myRooms.isEmpty
            ? const Text(
                'Kamu belum membuat room. Tekan tombol Buat Room untuk mulai.',
              )
            : SizedBox(
                width: 360,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final r in myRooms)
                        ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(r.icon, color: r.color),
                          title: Text(r.name),
                          subtitle: Text('Kode: ${r.inviteCode}'),
                        ),
                    ],
                  ),
                ),
              ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }
}

// Panel kosong saat belum ada room dipilih (desktop/tablet)
class _EmptyChatPane extends StatelessWidget {
  const _EmptyChatPane();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(
                Icons.forum_outlined,
                size: 42,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Pilih room untuk mulai diskusi',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Daftar room ada di panel kiri. Pilih salah satu untuk\nmembaca dan mengirim pesan.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoomCard extends StatelessWidget {
  final ChatRoom room;
  final int unread;
  final bool isGuest;
  final bool selected;
  final VoidCallback onTap;

  const _RoomCard({
    required this.room,
    required this.unread,
    required this.isGuest,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected
              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.08)
              : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? Theme.of(context).colorScheme.primary : Colors.transparent,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: room.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(room.icon, color: room.color, size: 26),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    room.name,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    room.lastMessage,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.people_outline,
                        size: 12,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          '${room.memberCount} anggota',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  room.lastTime,
                  style: TextStyle(
                    fontSize: 11,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 6),
                if (unread > 0)
                  Container(
                    constraints: const BoxConstraints(
                      minWidth: 22,
                      minHeight: 22,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    decoration: const BoxDecoration(
                      color: Color(0xFFEF4444),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '$unread',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileMenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback? onTap;

  const _ProfileMenuItem({
    required this.icon,
    required this.label,
    required this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: Theme.of(context).colorScheme.primary,
              size: 20,
            ),
          ),
          title: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
          subtitle: Text(
            subtitle,
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          trailing: Icon(
            Icons.chevron_right,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          onTap: onTap,
        ),
      ),
    );
  }
}

// Banner ala Telegram: pesan baru masuk di room yang tidak sedang dibuka.
class _NewMessageBanner extends StatelessWidget {
  final Map<String, String> banner;
  final VoidCallback onClose;
  final VoidCallback onOpen;

  const _NewMessageBanner({
    super.key,
    required this.banner,
    required this.onClose,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      // Ikut padding status bar supaya tidak tertutup punch-hole kamera.
      top: MediaQuery.paddingOf(context).top + 8,
      left: 8,
      right: 8,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: -1, end: 0),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        builder: (context, v, child) => Transform.translate(
          offset: Offset(0, v * 90),
          child: Opacity(opacity: (1 + v).clamp(0, 1), child: child),
        ),
        child: Material(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
          elevation: 6,
          shadowColor: Colors.black26,
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: onOpen,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Theme.of(context).colorScheme.outline),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.chat_bubble_rounded,
                      color: Theme.of(context).colorScheme.primary,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          banner['roomName'] ?? '',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12.5,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '${banner['sender']}: ${banner['text']}',
                          style: const TextStyle(fontSize: 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.close, size: 16),
                    color: Colors.grey,
                    onPressed: onClose,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
