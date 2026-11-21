SKRIP DEMONSTRASI APLIKASI UNITALK
Durasi: ±7 Menit
1. Pembukaan dan pengenalan aplikasi (00:00–00:45)
"Selamat pagi/siang. Pada kesempatan ini, kami akan mendemonstrasikan aplikasi UniTalk.
UniTalk merupakan aplikasi mobile chat room yang dirancang untuk membantu mahasiswa berkomunikasi dan berdiskusi berdasarkan kategori seperti mata kuliah, organisasi, dan topik bebas.
Aplikasi ini dibuat menggunakan Flutter sebagai frontend, Laravel 13 sebagai backend, dan MySQL sebagai basis datanya.
Tujuan aplikasi ini adalah mempermudah komunikasi mahasiswa tanpa harus membagikan nomor telepon pribadi."
2. Registrasi dan login (00:45–01:40)
"Pertama, kita akan melihat halaman awal aplikasi. Pengguna dapat masuk menggunakan akun mahasiswa atau mencoba aplikasi melalui mode Guest.
Pada demonstrasi ini, kita menggunakan akun mahasiswa untuk masuk ke dalam aplikasi.
Setelah berhasil login, pengguna akan diarahkan ke halaman utama. Sistem menyimpan sesi login sehingga pengguna tidak perlu terus-menerus memasukkan akun selama sesi masih berlaku."
Yang ditampilkan:
•	Halaman welcome.
•	Halaman login.
•	Proses login.
•	Halaman utama.
3. Melihat dan bergabung ke room (01:40–02:40)
"Selanjutnya, kita masuk ke fitur room. Room merupakan ruang diskusi yang dikelompokkan berdasarkan kategori, yaitu Mata Kuliah, Organisasi, dan Topik Bebas.
Mahasiswa dapat melihat daftar room dan bergabung menggunakan kode undangan unik.
Selain itu, pengguna juga dapat membuat room baru dengan menentukan nama dan kategori. Pembuat room secara otomatis memiliki hak sebagai admin."
Yang ditampilkan:
•	Daftar room.
•	Kategori room.
•	Fitur pencarian atau gabung room menggunakan kode.
•	Proses membuat room jika tersedia.
4. Demonstrasi fitur chat realtime (02:40–04:00)
"Berikutnya adalah fitur utama UniTalk, yaitu komunikasi melalui chat room.
Ketika pengguna mengirim pesan, pesan akan disimpan ke database dan ditampilkan pada ruang percakapan.
Untuk memperlihatkan komunikasi realtime, kami menggunakan dua akun berbeda yang masuk ke room yang sama. Ketika akun pertama mengirim pesan, akun kedua akan menerima pesan tersebut secara otomatis melalui mekanisme polling setiap tiga detik."
Yang ditampilkan:
•	Dua jendela Chrome dengan akun berbeda.
•	Kedua akun masuk ke room yang sama.
•	Mengirim pesan dari akun pertama.
•	Memperlihatkan pesan pada akun kedua.
5. Demonstrasi hak akses admin (04:00–05:00)
"UniTalk juga menyediakan fitur pengelolaan room oleh admin.
Admin dapat menghapus pesan, mengeluarkan anggota, dan menghapus room yang dibuatnya.
Fitur ini bertujuan menjaga diskusi agar tetap teratur. Sementara itu, pengguna biasa hanya memiliki hak akses sesuai perannya."
Yang ditampilkan:
•	Akun pembuat room.
•	Fitur moderasi pesan.
•	Pengelolaan anggota jika tersedia.
6. Demonstrasi fitur offline-first (05:00–06:15)
"Selanjutnya, UniTalk memiliki konsep offline-first. Fitur ini dirancang agar aplikasi tetap dapat dibuka ketika koneksi ke server terputus.
Data terakhir yang tersimpan di cache dapat ditampilkan kembali. Aplikasi juga menyediakan indikator offline dan mekanisme penyimpanan pesan lokal untuk sinkronisasi ketika koneksi kembali tersedia."
Yang ditampilkan:
•	Kondisi aplikasi saat backend tidak dapat dijangkau.
•	Tampilan data yang tersimpan di cache.
•	Indikator offline.
•	Sinkronisasi setelah server kembali tersedia, jika berhasil diuji.
7. Penutup (06:15–07:00)
"Dari demonstrasi tersebut, dapat disimpulkan bahwa UniTalk menyediakan ruang komunikasi mahasiswa berdasarkan kategori diskusi, dilengkapi dengan autentikasi, pengelolaan room, chat realtime, hak akses admin, dan dukungan offline-first.
Kami berharap aplikasi ini dapat membantu mahasiswa mengelola komunikasi akademik maupun organisasi dengan lebih terstruktur.
Demikian demonstrasi aplikasi UniTalk dari kelompok kami. Terima kasih."

