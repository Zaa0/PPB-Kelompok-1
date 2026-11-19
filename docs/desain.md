# Dokumen Desain UniTalk

Penulis: Aisyah Nazwa Ramadhani (2401020136)

Dokumen ini memperdalam persona dari proposal (Guest, Mahasiswa, Admin Room),
menambahkan skenario pemakaian, dan menjelaskan wireframe empat layar utama.

## 1. Persona

### Persona 1: Dina, Guest
- Mahasiswa semester 1 yang baru masuk kampus dan belum punya banyak kenalan.
- Kebutuhan: ingin lihat-lihat diskusi mata kuliah dulu tanpa harus bikin akun.
- Kekesalan: malas daftar-daftar untuk aplikasi yang belum ia kenal.
- Tujuan: mencoba UniTalk lewat mode Guest, membaca obrolan, dan ikut nimbrung di room yang mengizinkan tamu.

### Persona 2: Rina, Mahasiswa
- Mahasiswa semester 5, ikut beberapa grup mata kuliah dan organisasi.
- Kebutuhan: tempat diskusi tugas yang tidak tercampur obrolan santai.
- Kekesalan: info deadline tenggelam di grup chat, dan tidak nyaman kasih nomor pribadi ke orang yang belum dikenal.
- Tujuan: gabung room lewat kode undangan, tanya tugas, dan berdiskusi dengan nama tampil.

### Persona 3: Budi, Admin Room
- Mahasiswa semester 7, pengurus organisasi.
- Kebutuhan: ruang diskusi organisasi yang tertib.
- Kekesalan: pesan tidak pantas dan anggota yang mengganggu sulit ditertibkan.
- Tujuan: membuat room, membagikan kode undangan, menghapus pesan yang melanggar, dan mengeluarkan anggota bila perlu.

## 2. Skenario Pemakaian

### Skenario Dina (Guest)
Dina membuka UniTalk dan menekan "Masuk sebagai Guest". Ia melihat daftar
room di Beranda lalu membuka room Topik Bebas "Tips & Trik Kuliah". Di sana
ia masih bisa mengirim pesan. Saat ia membuka room mata kuliah, kolom ketik
diganti tombol "Login" karena room itu tidak mengizinkan tamu. Dina lalu
menekan Login dan membuat akun.

### Skenario Rina (Mahasiswa)
Rina login memakai email kampus. Di Beranda ia memilih tab Mata Kuliah dan
membuka room "Pemrograman Mobile". Ia bertanya soal deadline tugas dan teman
sekelas menjawab. Rina juga memakai kolom pencarian untuk menemukan room
lain, lalu mengganti nama tampilnya di halaman Profil.

### Skenario Budi (Admin Room)
Budi menekan tombol buat room, mengisi nama dan kategori, lalu aplikasi
membuat kode undangan otomatis. Ia membagikan kode itu ke anggota organisasi.
Saat ada pesan yang melanggar, Budi menghapusnya lewat sentuhan lama pada
pesan. Jika ada anggota yang terus mengganggu, ia membuka daftar anggota dan
mengeluarkannya.

## 3. Wireframe Deskriptif

### 3.1 Layar Welcome
- Tujuan: pintu masuk aplikasi; pengguna memilih login atau Guest.
- Latar biru tua dengan logo huruf "U", judul UniTalk, dan subjudul "Ruang Diskusi Mahasiswa".
- Tiga poin keunggulan: gabung grup mata kuliah dan organisasi, diskusi topik bebas, aman dan mudah digunakan.
- Kartu putih di bawah berisi tombol "Masuk dengan Akun" dan "Masuk sebagai Guest", serta teks syarat dan ketentuan.
- Alur: "Masuk dengan Akun" ke layar Login; "Masuk sebagai Guest" langsung ke Beranda.

### 3.2 Layar Login dan Daftar
- Tujuan: masuk atau mendaftar akun mahasiswa.
- Bagian atas: tombol kembali, logo, dan tulisan "Selamat Datang!".
- Form login: Email Kampus, Password (ada ikon mata untuk melihat/menyembunyikan), link "Lupa Password?", tombol "Masuk".
- Di bawahnya link "Belum punya akun? Daftar", pemisah "atau", dan tombol "Lanjutkan sebagai Guest".
- Form daftar menambah field Nama Panjang dan NIM (NIM tidak bisa diubah setelah daftar).
- Pesan error tampil sebagai kotak merah di bawah layar, misalnya saat email sudah dipakai atau password terlalu pendek.
- Alur: login atau daftar berhasil ke Beranda.

### 3.3 Layar Beranda
- Tujuan: menampilkan daftar room dan menjadi pusat navigasi.
- Header biru berisi sapaan, status ("Mahasiswa Aktif"), dan ikon lonceng dengan badge notifikasi.
- Kolom pencarian "Cari chat room..." di bawah header.
- Tiga tab kategori: Mata Kuliah, Organisasi, Topik Bebas.
- Tiap kartu room berisi ikon, nama room, pesan terakhir, jumlah anggota, jam, dan badge jumlah pesan belum dibaca.
- Tombol aksi melayang (FAB) di kanan bawah untuk membuat room.
- Navigasi bawah: Beranda, Pengaturan, Profil.
- Mode Guest: sapaan "Halo, Guest!", label GUEST, dan keterangan fitur terbatas.
- Alur: menekan kartu room membuka layar Chat.

### 3.4 Layar Chat
- Tujuan: ruang diskusi dalam satu room.
- Header biru: tombol kembali, ikon dan nama room, jumlah anggota dan kategori, serta menu titik tiga.
- Pesan orang lain: bubble putih di kiri, dengan avatar huruf dan nama pengirim berwarna.
- Pesan sendiri: bubble biru di kanan, dengan jam dan tanda terkirim.
- Bagian bawah: kolom "Tulis pesan..." dengan ikon lampiran dan mic.
- Mode Guest: banner oranye "Anda dalam mode Guest" dengan tombol Login. Di room yang tidak mengizinkan tamu, kolom ketik diganti tombol "Login".
- Alur: tombol kembali ke Beranda; menu titik tiga membuka daftar anggota dan aksi admin.

## 4. Perbedaan dengan Rancangan Proposal

- Navigasi bawah di proposal hanya Beranda dan Profil; sekarang ada tambahan Pengaturan.
- Logo di proposal berupa ikon chat; sekarang berupa huruf "U".
- Form daftar sekarang punya field NIM.
- Aplikasi sekarang tersambung ke backend Laravel dan MySQL, tidak lagi memakai data contoh di memori.