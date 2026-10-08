# RuangKampus (project_pertama)

Aplikasi mobile diskusi dan berbagi informasi anonim bagi mahasiswa, dibuat dengan Flutter.
Tugas kelompok mata kuliah Pemrograman Perangkat Mobile, Teknik Informatika UMRAH.

## Kelompok 1
- Fitri Arfiana (2401020135)
- Aisyah Nazwa Ramadhani (2401020136)
- Solahudin Putra Akbar (2401020137)
- Andrian Yuza Swanda (2401020157)
- Salsadilla Frisca Anjani (2401020164)
- Munfarida (2401020166)

## Status
UI mockup (data dummy, belum ada backend):
- Login + Guest mode (form validasi)
- Dashboard daftar room + search + buat room
- Chat room + kirim pesan (setState)
- Profil + logout
- Responsif: HP 1 kolom, web/desktop 2 kolom (LayoutBuilder)

Backend Laravel + MySQL menyusul tahap integrasi API.

## Cara jalan
```bash
flutter pub get
flutter run
```

## Struktur
- `lib/main.dart` - tema + navigasi bawah
- `lib/screens/` - login, dashboard, chat, profile
- `lib/widgets/` - room_card, chat_bubble
- `lib/models/` - room, chat_message (dummy)
