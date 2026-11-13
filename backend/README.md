# UniTalk API

REST API untuk aplikasi UniTalk (Flutter) — Laravel 13 + MySQL + Sanctum.

## Setup
```bash
composer install
# .env: DB_CONNECTION=mysql, DB_DATABASE=unitalk, DB_USERNAME=root
mysql -u root -e "CREATE DATABASE IF NOT EXISTS unitalk CHARACTER SET utf8mb4"
php artisan migrate:fresh --seed   # buat tabel + data demo
php artisan serve                  # http://localhost:8000
```

## Endpoint (prefix /api)
| Method | Path | Keterangan |
|---|---|---|
| POST | /register | daftar akun {name, email, password} |
| POST | /login | login, balas token + user (throttle 10/menit) |
| POST | /guest | buat sesi guest sementara + token |
| GET | /me | profil user yang login |
| PATCH | /me | ubah nama tampil {name} |
| POST | /logout | hapus token |
| GET | /rooms | daftar room + anggota + pesan terakhir |
| POST | /rooms | buat room (guest ditolak) |
| POST | /rooms/join | gabung lewat {code} undangan |
| DELETE | /rooms/{id} | hapus room (hanya pembuat) |
| GET | /rooms/{id}/messages?after= | isi chat; `after` untuk polling pesan baru |
| POST | /rooms/{id}/messages | kirim pesan (guest hanya room allow_guest) |
| DELETE | /messages/{id} | hapus pesan (pengirim/pembuat room) |
| GET | /rooms/{id}/members | daftar anggota |
| POST | /rooms/{id}/kick | keluarkan anggota {user_id} (hanya pembuat) |

Semua endpoint selain register/login/guest butuh header `Authorization: Bearer <token>`.

## Data demo
Seeder membuat 10 room (kode UT-101 s/d UT-303) + akun anggota kelompok
(password: `password123`) + isi chat contoh per kategori.

## Test
```bash
php artisan test   # feature test: auth, CRUD room, chat, aturan guest & admin
```
