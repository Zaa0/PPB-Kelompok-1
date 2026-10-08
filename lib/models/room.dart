// Model Room - dummy dulu, nanti diganti dari API Laravel GET /api/rooms
class Room {
  final String id;
  final String nama;
  final String deskripsi;
  final String kode;
  final int jumlahAnggota;

  const Room({
    required this.id,
    required this.nama,
    required this.deskripsi,
    required this.kode,
    required this.jumlahAnggota,
  });
}

// Data contoh biar layout bisa direkam tanpa backend
const dummyRooms = [
  Room(
    id: '1',
    nama: 'IF501 - PPB',
    deskripsi: 'Diskusi Flutter, Dart, dan tugas kelompok.',
    kode: 'PPB-501',
    jumlahAnggota: 24,
  ),
  Room(
    id: '2',
    nama: 'Himpunan Informatika',
    deskripsi: 'Info acara, lomba, dan kas himpunan.',
    kode: 'HIM-IFO',
    jumlahAnggota: 87,
  ),
  Room(
    id: '3',
    nama: 'Anonim Curhat Kampus',
    deskripsi: 'Berbagi cerita anonim sesama mahasiswa.',
    kode: 'RKG-007',
    jumlahAnggota: 132,
  ),
];
