# Audit UI/UX & Aksesibilitas UniTalk

Dokumen ini mencatat hasil audit antarmuka UniTalk pada tahap 3 (UI/UX &
aksesibilitas), perbandingan dengan proposal, temuan responsif, perbaikan kecil
yang dikerjakan, serta bukti sebelum/sesudah.

- **Pelaksana:** Salsadilla Frisca (2401020164)
- **Branch:** `ui/polish`
- **Lingkungan:** Flutter Web (debug) `http://127.0.0.1:8090`, backend Laravel
  `http://127.0.0.1:8000`, Chrome headless + Chrome DevTools Protocol
- **Tanggal audit:** 19 November 2026
- **Metode:** aplikasi dijalankan dengan sesi mahasiswa dan guest, tangkapan
  layar diambil pada lebar 320, 360, 800, dan 1400 piksel; tema terang dan gelap
  diuji; pohon aksesibilitas (`flt-semantics`) diperiksa lewat CDP.

## 1. Perbandingan dengan proposal (Gambar 2–7)

Gambar proposal disimpan di `proposal/`, tangkapan aplikasi di `before/` dan
`after/`.

| Gambar | Halaman | Sudah sesuai | Perbedaan / catatan |
| --- | --- | --- | --- |
| 2 | Welcome | Latar navy, logo, tagline, tiga baris fitur, panel putih berisi dua tombol CTA | Proposal memakai ikon gelembung chat; aplikasi memakai logo aplikasi. Proporsi dua kolom hanya aktif pada lebar >= 900 px. |
| 3 | Login | Judul "Selamat Datang!", field email & password, tautan Lupa Password, tombol Masuk, tautan Daftar, pemisah "atau", tombol guest | Aplikasi menambahkan header logo + "UniTalk / Login Akun Mahasiswa". "Lupa Password?" masih berupa snackbar placeholder. |
| 4 | Home mahasiswa | Header navy, avatar, sapaan, status, pencarian, tiga tab kategori, daftar room, navigasi bawah | Sapaan memakai nama tampilan (bukan NIM). Search bar berbentuk outline, bukan putih solid. Navigasi bawah berisi 3 item (ada Pengaturan). FAB tanpa label, membuka menu Buat Room/Gabung Kode. |
| 5 | Profil mahasiswa | Header gradien, avatar inisial, NIM, badge "Mahasiswa Aktif", daftar menu, tombol keluar | Nama tampilan menjadi teks utama dan NIM menjadi pill; ada baris "Nama tampil" yang bisa diedit. Menu bertambah Bantuan dan Tentang. Navigasi bawah 3 item. FAB icon-only. |
| 6 | Home guest | Sapaan guest, badge GUEST, pencarian, tiga tab, daftar room, aksi gabung kode | Teks status "Mode Guest – Fitur terbatas" (proposal: "Hanya bisa melihat"). FAB icon-only dengan menu Gabung Kode. |
| 7 | Profil guest | Header guest, banner oranye "Mode Guest Aktif", daftar menu | Teks ajakan login diubah menjadi "Login untuk bisa membuat room dan bergabung sepenuhnya". Navigasi bawah 3 item. |

Perbedaan di atas bersifat keputusan desain yang sudah ada sebelumnya, bukan
regresi dari perbaikan tahap ini.

## 2. Temuan responsif

| Lebar | Temuan sebelum perbaikan | Status |
| --- | --- | --- |
| 320 | Label tab kategori terpotong ("Mata Kuli", "Organisasi" terpangkas) | **Diperbaiki** (`cfb8470`) |
| 320 | Tombol pilihan tema pecah per suku kata ("Sist em", "Tera ng", "Gela p") | **Diperbaiki** (`4f58ec2`, `276177d`) |
| 320 | Kartu room sempit, judul panjang terpotong dengan elipsis; tidak ada overflow | Diterima (desain kartu) |
| 360 | Semua layar rapi; tab dan pilihan tema utuh | Lolos |
| 800 | Daftar room memenuhi lebar layar, sedangkan Profil/Pengaturan dibatasi 720 px sehingga margin tidak konsisten | Dicatat sebagai temuan, belum diubah (perlu keputusan desain) |
| 1400 | Layout dua panel berjalan: sidebar room 400 px + panel chat | Lolos |
| 1400 | Navigasi bawah membentang penuh (3 x 467 px) sementara konten dibatasi 720 px / sidebar 400 px | Dicatat sebagai temuan, belum diubah |
| 320–1400 | Tidak ditemukan elemen yang saling tumpang tindih setelah perbaikan | Lolos |

Bukti: `before/<layar>-<lebar>.png` dan `after/<layar>-<lebar>.png` untuk
welcome, login, home, chat, profil, pengaturan, home guest, dan profil guest.

## 3. Temuan aksesibilitas

1. **Tombol ikon header tanpa nama aksesibel.** Sebelum perbaikan, node
   `role=button` untuk notifikasi, menu room, tombol kirim, dan tombol kembali
   tidak memiliki label pada pohon aksesibilitas. Perbaikan menambahkan
   `Tooltip` sehingga pembaca layar dan pengguna mouse mendapat nama aksi.
2. **Kartu room.** Node kartu memiliki `role=button` tetapi `aria-label` kosong;
   teks isi kartu masih terbaca sebagai konten anak. Belum diubah karena
   penamaan kartu perlu menggabungkan nama room, pesan terakhir, dan jumlah
   anggota.
3. **Kontras mode gelap.**
   - Layar login: judul "UniTalk", tautan "Lupa Password?", "Daftar", dan teks
     tombol guest memakai navy/gray yang hampir menyatu dengan latar gelap.
   - Pembatas tanggal chat: teks abu terang di atas pill abu terang.
   - Kartu room: warna kartu dan latar hampir sama sehingga batas kartu tidak
     terlihat.
4. **Target sentuh.** Tombol ikon berukuran 40–48 px; masih memenuhi batas
   minimum 44 px pada umumnya, kecuali beberapa ikon header 40 px di layar
   sempit. Belum diubah.
5. **Fokus keyboard.** Urutan fokus mengikuti urutan widget, tetapi belum ada
   penanda fokus kustom yang menonjol. Belum diubah.

## 4. Perbaikan yang dikerjakan

Setiap perbaikan berada pada commit terpisah di branch `ui/polish`.

| # | Perbaikan | Commit |
| --- | --- | --- |
| 1 | Tooltip untuk tombol ikon header yang belum berlabel (notifikasi, menu room, kirim pesan, kembali) | `87f3acc` |
| 2 | Kontras teks, tautan, border input, dan tombol pada layar login mode gelap | `f44504c` |
| 3 | Kontras pembatas tanggal chat pada mode gelap | `1d96777` |
| 4 | Garis tepi kartu room agar tidak menyatu dengan latar gelap | `8501f6e` |
| 5 | Label tab kategori tidak terpotong pada lebar 320 px | `cfb8470` |
| 6 | Tombol pilihan tema tidak pecah kata pada lebar 320 px | `4f58ec2`, `276177d` |
| 7 | Sapaan guest diseragamkan ("Kamu") dan kalimat ajakan login diperbaiki | `c93fbe6` |
| 8 | Ekspektasi tes ikon room disesuaikan dengan pemetaan `iconForRoomName` (tes lama sudah usang) | `4414575` |

Detail teknis singkat:

- Tooltip memakai properti `tooltip` pada `IconButton`/`FloatingActionButton`
  dan `Tooltip` untuk tombol kirim kustom.
- Warna aksen memakai `UniTalkChatTheme.brandNavy` untuk tema terang dan
  `darkSenderName` untuk tema gelap melalui helper `_brandInk(context)`.
- Pembatas tanggal memakai `darkInputBg`, `darkTextSecondary`, dan `darkBorder`
  pada tema gelap.
- Tab memakai `labelPadding` 6 px dan ukuran font 12 px.
- `SegmentedButton` memakai padding rapat, font 12 px, tanpa ikon dan tanpa
  ikon centang pilihan pada lebar < 280 px.

## 5. Bukti visual

| Sebelum | Sesudah |
| --- | --- |
| `before/home-320.png` (tab terpotong) | `after/home-320.png` (tab utuh) |
| `before/settings-320.png` (kata terpecah) | `after/settings-320.png` (label utuh) |
| `before/login-1400-dark.png` (teks navy tak terbaca) | `after/login-1400-dark.png` (teks cyan/terang) |
| `before/chat-1400-dark.png` (pembatas tanggal pudar) | `after/chat-1400-dark.png` (pembatas terbaca) |
| `before/home-1400-dark.png` (kartu menyatu) | `after/home-1400-dark.png` (kartu bergaris) |
| — | `after/tooltip-notifikasi-1400.png` |
| — | `after/tooltip-menu-room-1400.png` |
| — | `after/tooltip-menu-aksi-360.png` |

## 6. Verifikasi

- `flutter analyze` → **No issues found!**
- `flutter test` → **23 tes lulus** (termasuk tes responsif 320/360/1400).
- Audit manual ulang pada 320, 360, 800, dan 1400 px setelah perbaikan: tidak
  ada overflow atau teks terpotong pada elemen yang diperbaiki.
- Pohon aksesibilitas setelah perbaikan memuat nama untuk "Notifikasi",
  "Menu room", dan "Menu aksi".

## 7. Temuan yang belum diperbaiki

1. Navigasi bawah selebar layar pada 1400 px tidak sejajar dengan panel konten.
2. Margin daftar room (8–16 px) berbeda dengan Profil/Pengaturan (720 px
   terpusat) pada 800 px.
3. Kartu room belum memiliki `aria-label` gabungan.
4. Tombol "Lupa Password?" dan beberapa menu profil masih berupa placeholder
   (snackbar).
5. Notifikasi in-app dapat menutupi header saat muncul di layar sempit.
6. Beberapa perbedaan istilah dengan proposal ("Fitur terbatas" vs "Hanya bisa
   melihat") dibiarkan agar konsisten dengan fitur yang tersedia.

## 8. Cara mereproduksi

1. Jalankan backend: `php artisan migrate:fresh --seed` lalu
   `php artisan serve` di folder `backend/`.
2. Jalankan aplikasi: `flutter run -d web-server --web-port 8090`.
3. Buka `http://127.0.0.1:8090`, ubah lebar viewport ke 320, 360, 800, dan
   1400 px.
4. Untuk tema gelap, aktifkan lewat Pengaturan → Tema aplikasi → Gelap.
5. Tangkapan layar otomatis dapat dibuat ulang dengan skrip CDP di
   `C:\Users\ASUS\AppData\Local\Temp\opencode\cdp` (tidak disimpan di repo).
