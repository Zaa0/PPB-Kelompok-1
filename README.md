# UniTalk

Aplikasi diskusi dan berbagi informasi bagi mahasiswa, dibuat dengan Flutter.
Tugas kelompok mata kuliah Pemrograman Perangkat Mobile, Teknik Informatika UMRAH.

## Kelompok 1
- Fitri Arfiana (2401020135)
- Aisyah Nazwa Ramadhani (2401020136)
- Solahudin Putra Akbar (2401020137)
- Andrian Yuza Swanda (2401020157)
- Salsadilla Frisca Anjani (2401020164)
- Munfarida (2401020166)

## Fitur
UI mockup dengan data dummy (belum ada backend):
- Login + registrasi + mode Guest (validasi form)
- Dashboard daftar room: Mata Kuliah, Organisasi, Topik Bebas
- Pencarian room, buat room baru (dengan kode undangan unik), gabung room lewat kode
- Chat room: kirim pesan, bubble chat, info anggota
- Admin room (pembuat room): hapus pesan, keluarkan anggota, hapus room
- Guest hanya bisa mengirim pesan di room yang mengizinkan tamu
- Profil: ubah nama tampil, daftar room saya, bantuan, tentang aplikasi, logout

## Responsif
- Android / HP: satu kolom, navigasi bawah, tombol aksi berbentuk FAB
- Tablet, laptop, PC, dan web: dua panel (daftar room di kiri, chat di kanan)
- Konten dibatasi lebarnya di layar besar supaya tidak melebar berlebihan

Backend Laravel + MySQL menyusul pada tahap integrasi API.

## Cara jalan
```bash
flutter pub get
flutter run
```

Jalankan di target tertentu:
```bash
flutter run -d chrome     # web
flutter run -d windows    # desktop Windows
flutter run               # device Android yang terhubung
```

## Build
```bash
flutter build apk --release
flutter build web --release
flutter build windows --release
```

## Struktur
- `lib/main.dart` - entry point, tema, dan routing
- `lib/screens/welcome_screen.dart` - welcome + login/registrasi
- `lib/screens/home_screen.dart` - dashboard room, profil, layout responsif
- `lib/screens/chat_room_screen.dart` - halaman/panel chat
- `lib/models/app_data.dart` - model data dan dummy data
