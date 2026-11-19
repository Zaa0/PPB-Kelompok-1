# PRD Tambahan - User Story Baru UniTalk

Dokumen ini melanjutkan Bagian 4.3 PRD (US-01 sampai US-06).
Penulis: Aisyah Nazwa Ramadhani (2401020136)

## US-07 Ubah Nama Profil
Sebagai mahasiswa, saya ingin mengubah nama tampil di profil supaya
alias saya di chat sesuai keinginan saya.

Kriteria terima:
- Mahasiswa yang sudah login bisa mengubah nama lewat ikon edit di halaman Profil.
- Nama tidak boleh kosong; jika kosong, muncul pesan error yang jelas.
- Perubahan tersimpan di database, bukan hanya di memori aplikasi.
- Nama baru muncul pada pesan yang dikirim setelah perubahan.
- Guest tidak dapat mengubah nama profil.

## US-08 Cari Room
Sebagai pengguna, saya ingin mencari room berdasarkan nama supaya cepat
menemukan diskusi yang saya butuhkan.

Kriteria terima:
- Kolom pencarian di Beranda memfilter daftar room sesuai teks yang diketik.
- Pencarian tidak membedakan huruf besar dan kecil.
- Hasil mengikuti tab kategori yang sedang dibuka (Mata Kuliah, Organisasi, Topik Bebas).
- Jika tidak ada hasil, tampil pesan bahwa room tidak ditemukan.
- Guest dan mahasiswa sama-sama dapat menggunakan pencarian.

## US-09 Lihat Daftar Anggota Room
Sebagai anggota room, saya ingin melihat siapa saja anggota room supaya
tahu siapa yang ikut berdiskusi.

Kriteria terima:
- Daftar anggota tampil lewat lembar bawah (bottom sheet) di ruang obrolan.
- Yang tampil di daftar adalah alias/nama tampil, bukan identitas asli.
- Jumlah anggota di header room sama dengan jumlah anggota di daftar.
- Admin room diberi penanda khusus di daftar anggota.
- Daftar anggota bisa dibuka oleh semua anggota room, tidak hanya admin.
- Aksi mengeluarkan anggota dan batasannya diatur di US-05.