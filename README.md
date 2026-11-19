# UniTalk

Aplikasi chat room untuk diskusi dan berbagi informasi antar mahasiswa.
Klien dibangun dengan Flutter, API dengan Laravel, dan database MySQL.
Tugas kelompok mata kuliah Pemrograman Perangkat Bergerak, Teknik Informatika UMRAH.

**Status: Phase 3 - integrasi API. Belum final; demo dan laporan masih berjalan.**

## Kelompok 1

| Nama | NIM | Bagian |
|---|---|---|
| Fitri Arfiana | 2401020135 | QA dan test case |
| Aisyah Nazwa Ramadhani | 2401020136 | PRD dan dokumen desain |
| Solahudin Putra Akbar | 2401020137 | backend |
| Andrian Yuza Swanda | 2401020157 | lead developer |
| Salsadilla Frisca Anjani | 2401020164 | UI/UX dan audit aksesibilitas |
| Munfarida | 2401020166 | skrip demo dan rilis |

## Fitur

- Login, registrasi, dan mode Guest (autentikasi token lewat REST API)
- Daftar room: Mata Kuliah, Organisasi, dan Topik Bebas
- Pencarian room, buat room dengan kode undangan otomatis, gabung lewat kode
- Chat room: pesan tersimpan di database, bubble chat, daftar anggota
- Pesan baru muncul otomatis (polling 1 detik selama chat dibuka)
- Admin room: hapus pesan, keluarkan anggota, hapus room
- Guest hanya bisa mengirim di room yang mengizinkan tamu (dicek di server)
- Profil: ubah nama tampil, daftar room saya, bantuan, tentang aplikasi, logout
- Cache offline: data terakhir tetap tampil saat backend mati

## Arsitektur

```
Flutter (Android / Web)  --HTTP/JSON-->  Laravel API  ---->  MySQL (db: unitalk)
        |                                     |
        +-- Hive + shared_preferences         +-- Sanctum (token per perangkat)
            (cache offline & sesi)            +-- 15 endpoint REST di /api
```

- Dua mode otomatis: **online** saat backend jalan, **offline** saat mati
  (memakai cache, ada penanda "Offline" di header).
- Pesan di-polling tiap 1 detik; daftar room di-refresh tiap 5 detik.
- Backend ada di folder `backend/` dalam repo yang sama.

## Dokumentasi

- [PRD](docs/PRD.md) dan [PRD tambahan](docs/prd-tambahan.md)
- [Pembagian tugas](docs/pembagian-tugas.md)
- [Audit UI](docs/ui-audit.md)
- [Hasil pengujian QA](docs/qa/test-case.md)
- [Skrip demonstrasi](docs/demo/SKRIP_DEMONSTRASI_APLIKASI_UNITALK.md)
- [Release notes v1.0](docs/release-notes-v1.0.md)
- [Filosofi logo](docs/filosofi-logo.md)

## Menjalankan backend (Laragon)

1. Start MySQL lewat Laragon.
2. Siapkan database:
   ```bash
   mysql -u root -e "CREATE DATABASE IF NOT EXISTS unitalk CHARACTER SET utf8mb4"
   ```
3. Install dan isi data awal:
   ```bash
   cd backend
   composer install
   php artisan install:api      # jika belum
   php artisan migrate:fresh --seed
   php artisan serve            # http://localhost:8000
   ```

## Akun demo (password semua: `password123`)

| Nama | Email |
|---|---|
| Andrian Yuza | yuza2401020157@student.umrah.ac.id |
| Fitri Arfiana | fitri2401020135@student.umrah.ac.id |
| Aisyah Nazwa | aisyah2401020136@student.umrah.ac.id |
| Solahudin Putra | solahudin2401020137@student.umrah.ac.id |
| Salsadilla Frisca | salsa2401020164@student.umrah.ac.id |
| Munfarida | munfarida2401020166@student.umrah.ac.id |

Mode Guest tidak perlu akun, tekan "Masuk sebagai Guest".

## Menjalankan aplikasi

```bash
flutter pub get
flutter run -d chrome          # web, API ke http://localhost:8000
flutter run                    # emulator Android, API ke http://10.0.2.2:8000
```

Demo dengan HP fisik (WiFi sama dengan laptop):

```bash
flutter run --dart-define=API_URL=http://<IP-LAPTOP>:8000/api
```

## Menjalankan test

```bash
flutter analyze
flutter test                   # 23 test unit dan widget
cd backend && php artisan test # 7 feature test API
```

## Responsif

- HP dan Android: satu kolom, navigasi bawah, tombol aksi berbentuk FAB.
- Tablet, laptop, PC, dan web: dua panel (daftar room di kiri, chat di kanan).
- Lebar konten dibatasi di layar besar agar tidak melebar berlebihan.

## Struktur

- `lib/main.dart` - entry point, tema, routing, inisialisasi state dan API
- `lib/config/app_config.dart` - URL API per platform (bisa di-override)
- `lib/data/api_client.dart` - klien REST (auth, room, chat, anggota)
- `lib/data/app_repository.dart` - kontrak penyimpanan lokal
- `lib/data/local_repository.dart` - cache offline (Hive + shared_preferences)
- `lib/state/app_state.dart` - state terpusat: sesi, room, chat, polling
- `lib/screens/welcome_screen.dart` - welcome, login, registrasi
- `lib/screens/home_screen.dart` - dashboard room, profil, layout responsif
- `lib/screens/chat_room_screen.dart` - halaman/panel chat
- `lib/models/app_data.dart` - model data (ChatRoom, ChatMessage, mapping JSON)
