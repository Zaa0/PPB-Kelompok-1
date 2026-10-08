import 'package:flutter/material.dart';
import '../models/room.dart';
import '../widgets/room_card.dart';
import 'chat_screen.dart';

// Layout: Scaffold + header + search + ListView + FAB
class DashboardScreen extends StatefulWidget {
  final String nama;

  const DashboardScreen({super.key, required this.nama});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String _query = '';

  void _buatRoom(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Buat Room'),
        content: const TextField(
          decoration: InputDecoration(
            labelText: 'Nama room',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Buat'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final rooms = dummyRooms
        .where((r) =>
            r.nama.toLowerCase().contains(_query.toLowerCase()) ||
            r.deskripsi.toLowerCase().contains(_query.toLowerCase()))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('Halo, ${widget.nama}'),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 12),
            child: CircleAvatar(child: Icon(Icons.person, size: 20)),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                'Ruang Diskusi',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Text(
                'Gabung room mata kuliah, organisasi, atau topik anonim.',
                style: TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 12),
              TextField(
                onChanged: (v) => setState(() => _query = v),
                decoration: const InputDecoration(
                  hintText: 'Cari room / kode undangan...',
                  prefixIcon: Icon(Icons.search),
                ),
              ),
              const SizedBox(height: 12),
              for (final room in rooms)
                RoomCard(
                  room: room,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChatScreen(room: room),
                      ),
                    );
                  },
                ),
              if (rooms.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'Room tidak ditemukan. Coba kata kunci lain.',
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _buatRoom(context),
        icon: const Icon(Icons.add),
        label: const Text('Buat Room'),
      ),
    );
  }
}
