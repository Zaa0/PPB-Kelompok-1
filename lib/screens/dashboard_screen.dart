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
      // Responsif ala Solahudin (6a5ccee): breakpoint mobile < 600,
      // web/desktop >= 900 tampil 2 kolom
      body: LayoutBuilder(
        builder: (context, constraints) {
          final bool isMobile = constraints.maxWidth < 600;
          final int kolom = constraints.maxWidth >= 900 ? 2 : 1;
          final double padding = isMobile ? 16 : 24;

          Widget kartu(Room room) => RoomCard(
                room: room,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChatScreen(room: room),
                    ),
                  );
                },
              );

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(padding),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Ruang Diskusi',
                            style: TextStyle(
                              fontSize: isMobile ? 22 : 26,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Text(
                            'Gabung room mata kuliah, organisasi, atau topik anonim.',
                            style: TextStyle(color: Colors.black54),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            onChanged: (v) =>
                                setState(() => _query = v),
                            decoration: const InputDecoration(
                              hintText: 'Cari room / kode undangan...',
                              prefixIcon: Icon(Icons.search),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (kolom == 1)
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, i) => Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: padding,
                            vertical: 4,
                          ),
                          child: kartu(rooms[i]),
                        ),
                        childCount: rooms.length,
                      ),
                    )
                  else
                    SliverGrid(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisExtent: 124,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, i) => kartu(rooms[i]),
                        childCount: rooms.length,
                      ),
                    ),
                  if (rooms.isEmpty)
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Text(
                          'Room tidak ditemukan. Coba kata kunci lain.',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _buatRoom(context),
        icon: const Icon(Icons.add),
        label: const Text('Buat Room'),
      ),
    );
  }
}
