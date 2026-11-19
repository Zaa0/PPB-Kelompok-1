# Release Notes UniTalk v1.0

Penulis: Aisyah Nazwa Ramadhani (2401020136)

Versi 1.0 adalah versi yang sudah terhubung backend, pengembangan dari
prototipe antarmuka (mock data) yang ada di proposal.

## Fitur Baru Dibanding Prototipe

- Data tersimpan di database MySQL lewat REST API Laravel, tidak lagi hanya di memori aplikasi.
- Login dan registrasi memakai token (Laravel Sanctum), dengan field NIM saat daftar.
- Pesan baru dari anggota lain muncul otomatis lewat polling selama chat dibuka.
- Mode offline-first: data terakhir tetap tampil dari cache (Hive dan shared_preferences) saat server mati, dengan tanda "Offline" di header.
- Server ikut memeriksa hak akses, misalnya guest ditolak mengirim pesan di room yang tidak mengizinkan tamu.
- Halaman Profil lebih lengkap: ubah nama tampil, Room Saya, Bantuan, Tentang Aplikasi, dan Logout.
- Tampilan responsif: satu kolom di HP, dua panel (daftar room dan chat) di layar besar.
- Navigasi bawah bertambah menu Pengaturan.

## Perbaikan Dibanding Prototipe

- State aplikasi dipusatkan di satu tempat (lib/state/app_state.dart), tidak lagi tersebar di tiap layar.
- Kode dipisah per lapisan: klien API, repositori lokal, state, layar, dan model.
- Logo aplikasi diganti dari ikon chat menjadi huruf "U".

## Bug dan Keterbatasan yang Diketahui

- Pesan error validasi dari server masih berbahasa Inggris, misalnya "The email has already been taken." dan "The password field must be at least 6 characters.", sementara tampilan lainnya berbahasa Indonesia.
- Pengiriman pesan masih memakai polling, belum WebSocket (Laravel Reverb di proposal belum dipakai).