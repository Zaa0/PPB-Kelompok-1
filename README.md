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
- Login + registrasi + mode Guest (auth token via REST API)
- Dashboard daftar room: Mata Kuliah, Organisasi, Topik Bebas
- Pencarian room, buat room baru (kode undangan otomatis), gabung room lewat kode
- Chat room: kirim pesan (tersimpan di database), bubble chat, info anggota
- Pesan baru muncul otomatis (polling tiap 3 detik selama chat dibuka)
- Admin room (pembuat room): hapus pesan, keluarkan anggota, hapus room
- Guest hanya bisa mengirim pesan di room yang mengizinkan tamu (dicek server)
- Profil: ubah nama tampil, daftar room saya, bantuan, tentang aplikasi, logout
- Cache offline-first: data terakhir tetap tampil walau server mati (mode offline)

## Arsitektur
```
Flutter (Android / Web)  --HTTP/JSON-->  Laravel API  ---->  MySQL (db: unitalk)
        |                                     |
        +-- Hive + shared_preferences         +-- Sanctum (auth token)
            (cache offline-first & sesi)      +-- REST: /api/auth, /api/rooms, /api/messages
```
- Aplikasi otomatis dua mode: **online** (backend jalan) dan **offline**
  (backend mati → pakai cache, ada tanda "Offline" di header).
- Proyek backend ada di folder terpisah: `../unitalk-api`.

## Menjalankan backend (Laragon)
1. Start MySQL lewat Laragon (atau biarkan `php artisan` yang menghubungi).
2. Siapkan database:
   ```bash
   mysql -u root -e "CREATE DATABASE IF NOT EXISTS unitalk CHARACTER SET utf8mb4"
   ```
3. Install & isi data awal:
   ```bash
   cd unitalk-api
   composer install
   php artisan install:api      # jika belum
   php artisan migrate:fresh --seed
   php artisan serve            # jalan di http://localhost:8000
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

Mode Guest tidak perlu akun — tekan "Masuk sebagai Guest".

## Menjalankan aplikasi
```bash
flutter pub get
flutter run -d chrome          # web (API ke http://localhost:8000)
flutter run                    # emulator Android (API ke http://10.0.2.2:8000)
```
Demo pakai HP fisik (WiFi yang sama dengan laptop):
```bash
flutter run --dart-define=API_URL=http://<IP-LAPTOP>:8000/api
```

## Menjalankan test
```bash
flutter analyze
flutter test                   # unit + widget test
cd ../unitalk-api && php artisan test   # feature test API
```

## Responsif
- Android / HP: satu kolom, navigasi bawah, tombol aksi berbentuk FAB
- Tablet, laptop, PC, dan web: dua panel (daftar room di kiri, chat di kanan)
- Konten dibatasi lebarnya di layar besar supaya tidak melebar berlebihan

## Struktur
- `lib/main.dart` - entry point, tema, routing, inisialisasi state + API
- `lib/config/app_config.dart` - URL API per platform (bisa di-override)
- `lib/data/api_client.dart` - klien REST (auth, room, chat, anggota)
- `lib/data/app_repository.dart` - kontrak penyimpanan lokal
- `lib/data/local_repository.dart` - cache offline (Hive + shared_preferences)
- `lib/state/app_state.dart` - state terpusat: sesi, room, chat, polling
- `lib/screens/welcome_screen.dart` - welcome + login/registrasi
- `lib/screens/home_screen.dart` - dashboard room, profil, layout responsif
- `lib/screens/chat_room_screen.dart` - halaman/panel chat
- `lib/models/app_data.dart` - model data (ChatRoom, ChatMessage, JSON mapping)
