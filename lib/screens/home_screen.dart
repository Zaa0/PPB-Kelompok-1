import 'package:flutter/material.dart';

import '../models/app_data.dart';
import 'chat_room_screen.dart';

class HomeScreen extends StatefulWidget {
  final bool isGuest;
  final String userName;

  const HomeScreen({super.key, required this.isGuest, required this.userName});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _bottomIndex = 0;
  String _searchQuery = '';
  late final List<ChatRoom> _rooms = List.from(DummyData.rooms);
  final Set<String> _myRoomIds = {}; // room yang saya buat = saya adminnya
  late String _displayName = widget.userName;
  ChatRoom? _selectedRoom;
  bool _selectedIsAdmin = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  bool get _isWide => MediaQuery.sizeOf(context).width >= 900;

  List<ChatRoom> _filteredRooms(String category) {
    final rooms = _rooms.where((r) => r.category == category).toList();
    if (_searchQuery.isEmpty) return rooms;
    return rooms
        .where((r) => r.name.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  String _generateInviteCode() {
    var n = 100 + _rooms.length + 1;
    while (_rooms.any((r) => r.inviteCode.toUpperCase() == 'UT-$n')) {
      n++;
    }
    return 'UT-$n';
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
              onPressed: () {
                if (namaCtrl.text.trim().isEmpty) return;
                final id = DateTime.now().millisecondsSinceEpoch.toString();
                final room = ChatRoom(
                  id: id,
                  name: namaCtrl.text.trim(),
                  category: kategori,
                  lastMessage: deskCtrl.text.trim().isEmpty
                      ? 'Room baru dibuat'
                      : deskCtrl.text.trim(),
                  lastTime: 'Baru saja',
                  unreadCount: 0,
                  memberCount: 1,
                  icon: kategori == 'matkul'
                      ? Icons.book_outlined
                      : kategori == 'organisasi'
                      ? Icons.groups_outlined
                      : Icons.topic_outlined,
                  color: const Color(0xFF3B82F6),
                  inviteCode: _generateInviteCode(),
                  allowGuest: kategori == 'topik',
                );
                setState(() {
                  _rooms.add(room);
                  _myRoomIds.add(id);
                  if (_isWide) {
                    _selectedRoom = room;
                    _selectedIsAdmin = true;
                  }
                });
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Room dibuat! Kode undangan: ${room.inviteCode}',
                    ),
                  ),
                );
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
            onPressed: () {
              final kode = kodeCtrl.text.trim().toUpperCase();
              final found = _rooms
                  .where((r) => r.inviteCode.toUpperCase() == kode)
                  .toList();
              Navigator.pop(ctx);
              if (found.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Kode tidak ditemukan')),
                );
                return;
              }
              _openRoom(found.first);
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
      setState(() {
        _selectedRoom = room;
        _selectedIsAdmin = _myRoomIds.contains(room.id);
      });
    } else {
      _openChat(room);
    }
  }

  Future<void> _openChat(ChatRoom room) async {
    final hapus = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatRoomScreen(
          room: room,
          isGuest: widget.isGuest,
          userName: _displayName,
          isAdmin: _myRoomIds.contains(room.id),
        ),
      ),
    );
    if (hapus == true && mounted) {
      setState(() {
        _rooms.removeWhere((r) => r.id == room.id);
        _myRoomIds.remove(room.id);
      });
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Room dihapus')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final wide = _isWide;
    return Scaffold(
      backgroundColor: const Color(0xFFF0F6FF),
      body: SafeArea(
        child: wide
            ? _buildWideLayout()
            : (_bottomIndex == 0 ? _buildHomeBody() : _buildProfileBody()),
      ),
      // FAB hanya di layar kecil; di desktop aksi ada di header.
      floatingActionButton: (!wide && _bottomIndex == 0)
          ? (widget.isGuest
                ? FloatingActionButton.extended(
                    onPressed: _joinDialog,
                    icon: const Icon(Icons.vpn_key_outlined),
                    label: const Text('Gabung Kode'),
                  )
                : FloatingActionButton.extended(
                    onPressed: _createDialog,
                    icon: const Icon(Icons.add),
                    label: const Text('Buat Room'),
                  ))
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _bottomIndex,
        onDestinationSelected: (i) => setState(() => _bottomIndex = i),
        backgroundColor: Colors.white,
        elevation: 8,
        indicatorColor: const Color(0xFFDBEAFE),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home, color: Color(0xFF1E3A8A)),
            label: 'Beranda',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person, color: Color(0xFF1E3A8A)),
            label: 'Profil',
          ),
        ],
      ),
    );
  }

  // ── Layout lebar: sidebar room + panel chat ──
  Widget _buildWideLayout() {
    if (_bottomIndex == 1) return _buildProfileBody();
    return Row(
      children: [
        SizedBox(width: 400, child: _buildSidebar()),
        const VerticalDivider(width: 1, thickness: 1),
        Expanded(child: _buildChatPane()),
      ],
    );
  }

  Widget _buildSidebar() {
    return Column(
      children: [
        _buildHeader(),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildRoomList('matkul'),
              _buildRoomList('organisasi'),
              _buildRoomList('topik'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHomeBody() {
    return Column(
      children: [
        _buildHeader(),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildRoomList('matkul'),
              _buildRoomList('organisasi'),
              _buildRoomList('topik'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildChatPane() {
    final room = _selectedRoom;
    if (room == null) {
      return const _EmptyChatPane();
    }
    return ChatRoomScreen(
      key: ValueKey(room.id),
      room: room,
      isGuest: widget.isGuest,
      userName: _displayName,
      isAdmin: _selectedIsAdmin,
      embedded: true,
      onClose: () => setState(() => _selectedRoom = null),
      onRoomDeleted: () {
        setState(() {
          _rooms.removeWhere((r) => r.id == room.id);
          _myRoomIds.remove(room.id);
          _selectedRoom = null;
        });
      },
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      color: const Color(0xFF1E3A8A),
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
                    _displayName.isNotEmpty
                        ? _displayName[0].toUpperCase()
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
                      'Halo, $_displayName! 👋',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      widget.isGuest
                          ? 'Mode Guest – Fitur terbatas'
                          : 'Mahasiswa Aktif',
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
              IconButton(
                tooltip: 'Gabung dengan kode',
                icon: const Icon(Icons.vpn_key_outlined, color: Colors.white),
                onPressed: _joinDialog,
              ),
              if (!widget.isGuest)
                IconButton(
                  tooltip: 'Buat room',
                  icon: const Icon(
                    Icons.add_circle_outline,
                    color: Colors.white,
                  ),
                  onPressed: _createDialog,
                ),
              if (widget.isGuest)
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
                            SnackBar(
                              content: const Text('3 notifikasi baru'),
                              behavior: SnackBarBehavior.floating,
                              backgroundColor: const Color(0xFF1E3A8A),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
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

  Widget _buildRoomList(String category) {
    final rooms = _filteredRooms(category);
    if (rooms.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off, size: 48, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text(
              'Tidak ada room ditemukan',
              style: TextStyle(color: Colors.grey.shade400),
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
        isGuest: widget.isGuest,
        selected: _isWide && _selectedRoom?.id == rooms[i].id,
        onTap: () => _openRoom(rooms[i]),
      ),
    );
  }

  Widget _buildProfileBody() {
    final myRooms = _rooms.where((r) => _myRoomIds.contains(r.id)).toList();
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
                          _displayName.isNotEmpty
                              ? _displayName[0].toUpperCase()
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Text(
                            _displayName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (!widget.isGuest)
                          IconButton(
                            tooltip: 'Ubah nama',
                            icon: const Icon(
                              Icons.edit_outlined,
                              color: Colors.white70,
                              size: 18,
                            ),
                            onPressed: () {
                              final ctrl = TextEditingController(
                                text: _displayName,
                              );
                              showDialog(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Ubah Nama Profil'),
                                  content: TextField(
                                    controller: ctrl,
                                    decoration: const InputDecoration(
                                      labelText: 'Nama tampil',
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
                                        if (ctrl.text.trim().isEmpty) return;
                                        setState(
                                          () => _displayName = ctrl.text.trim(),
                                        );
                                        Navigator.pop(ctx);
                                      },
                                      child: const Text('Simpan'),
                                    ),
                                  ],
                                ),
                              );
                            },
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
                        color: widget.isGuest
                            ? Colors.orange.withValues(alpha: 0.3)
                            : Colors.green.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        widget.isGuest ? 'Guest' : 'Mahasiswa Aktif',
                        style: TextStyle(
                          color: widget.isGuest
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
              if (widget.isGuest) ...[
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
                  onPressed: () => Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const _BackToWelcome()),
                    (route) => false,
                  ),
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

// Redirect ke welcome
class _BackToWelcome extends StatelessWidget {
  const _BackToWelcome();
  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.pushReplacementNamed(context, '/');
    });
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}

// Panel kosong saat belum ada room dipilih (desktop/tablet)
class _EmptyChatPane extends StatelessWidget {
  const _EmptyChatPane();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF6F8FC),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: const Color(0xFFE4ECFB),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.forum_outlined,
                size: 42,
                color: Color(0xFF1E3A8A),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Pilih room untuk mulai diskusi',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Daftar room ada di panel kiri. Pilih salah satu untuk\nmembaca dan mengirim pesan.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade500,
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
  final bool isGuest;
  final bool selected;
  final VoidCallback onTap;

  const _RoomCard({
    required this.room,
    required this.isGuest,
    required this.onTap,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFEFF6FF) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? const Color(0xFF1E3A8A) : Colors.transparent,
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
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    room.lastMessage,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
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
                            color: Colors.grey.shade400,
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
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
                ),
                const SizedBox(height: 6),
                if (room.unreadCount > 0)
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
                        '${room.unreadCount}',
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: const Color(0xFF1E3A8A), size: 20),
          ),
          title: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
          subtitle: Text(
            subtitle,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
          ),
          trailing: Icon(Icons.chevron_right, color: Colors.grey.shade300),
          onTap: onTap,
        ),
      ),
    );
  }
}
