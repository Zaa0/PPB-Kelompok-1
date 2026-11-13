<?php

namespace Database\Seeders;

use App\Models\Message;
use App\Models\Room;
use App\Models\User;
use Illuminate\Database\Seeder;

class DatabaseSeeder extends Seeder
{
    /**
     * Data awal UniTalk: akun kelompok + mahasiswa contoh, 10 room dummy
     * (sama seperti versi mock), membership, dan isi chat per kategori.
     */
    public function run(): void
    {
        // ── Akun kelompok (password demo: password123) ──
        $kelompok = [
            ['Fitri Arfiana', 'fitri2401020135@student.umrah.ac.id'],
            ['Aisyah Nazwa', 'aisyah2401020136@student.umrah.ac.id'],
            ['Solahudin Putra', 'solahudin2401020137@student.umrah.ac.id'],
            ['Andrian Yuza', 'yuza2401020157@student.umrah.ac.id'],
            ['Salsadilla Frisca', 'salsa2401020164@student.umrah.ac.id'],
            ['Munfarida', 'munfarida2401020166@student.umrah.ac.id'],
        ];
        $users = [];
        foreach ($kelompok as [$name, $email]) {
            $users[$email] = User::create([
                'name' => $name,
                'email' => $email,
                'password' => 'password123',
            ]);
        }

        // ── Mahasiswa contoh biar room terasa ramai ──
        foreach ([
            ['Budi', 'budi@sampel.ac.id'],
            ['Sari', 'sari@sampel.ac.id'],
            ['Rina', 'rina@sampel.ac.id'],
            ['Deni', 'deni@sampel.ac.id'],
        ] as [$name, $email]) {
            $users[$email] = User::create([
                'name' => $name,
                'email' => $email,
                'password' => 'password123',
            ]);
        }
        $semuaUser = array_values($users);
        $budi = $users['budi@sampel.ac.id'];
        $sari = $users['sari@sampel.ac.id'];
        $rina = $users['rina@sampel.ac.id'];
        $deni = $users['deni@sampel.ac.id'];
        $yuza = $users['yuza2401020157@student.umrah.ac.id'];

        // ── 10 room dummy: [nama, kategori, kode, allowGuest, pembuat] ──
        $rooms = [
            ['Pemrograman Mobile', 'matkul', 'UT-101', false, $yuza],
            ['Basis Data', 'matkul', 'UT-102', false, $budi],
            ['Algoritma & Pemrograman', 'matkul', 'UT-103', false, $sari],
            ['Kalkulus', 'matkul', 'UT-104', false, $deni],
            ['BEM Fakultas', 'organisasi', 'UT-201', false, $rina],
            ['Himpunan Mahasiswa IF', 'organisasi', 'UT-202', false, $budi],
            ['UKM Robotika', 'organisasi', 'UT-203', false, $yuza],
            ['Tips & Trik Kuliah', 'topik', 'UT-301', true, $sari],
            ['Loker & Magang', 'topik', 'UT-302', true, $deni],
            ['Sharing Tugas Akhir', 'topik', 'UT-303', false, $rina],
        ];

        foreach ($rooms as [$name, $kategori, $kode, $allowGuest, $pembuat]) {
            $room = Room::create([
                'name' => $name,
                'description' => "Room $kategori: $name",
                'category' => $kategori,
                'invite_code' => $kode,
                'allow_guest' => $allowGuest,
                'created_by' => $pembuat->id,
            ]);

            // Semua user jadi anggota room dummy (biar terasa publik).
            foreach ($semuaUser as $u) {
                $room->members()->attach($u->id);
            }

            // ── Isi chat contoh per kategori (sama seperti versi mock) ──
            $teks = match ($kategori) {
                'matkul' => [
                    [$sari, 'Selamat datang di ' . $name . ' 👋', '08:40'],
                    [$budi, 'Ada yang sudah baca materi minggu ini?', '08:45'],
                    [$yuza, 'Sudah, tapi bagian akhir masih belum paham', '08:50'],
                    [$rina, 'Nanti aku share catatannya ya', '08:52'],
                    [$deni, 'Tugas kelompok dikumpul kapan?', '09:10'],
                    [$sari, 'Minggu depan Jumat, jangan lupa ya', '09:12'],
                ],
                'organisasi' => [
                    [$rina, 'Halo semua, ini room ' . $name, '08:30'],
                    [$budi, 'Rapat rutin besok jam 14.00 di aula ya', '08:35'],
                    [$yuza, 'Siap, aku hadir', '08:37'],
                    [$deni, 'Yang belum bisa hadir tolong kabari', '08:40'],
                    [$sari, 'Nanti aku catat hasil rapatnya', '08:44'],
                ],
                default => [
                    [$deni, 'Halo! Ini room ' . $name, '09:00'],
                    [$sari, 'Boleh share pengalaman kalian di sini?', '09:05'],
                    [$yuza, 'Boleh banget, nanti aku tulis juga', '09:08'],
                    [$budi, 'Terima kasih infonya, sangat membantu', '09:15'],
                    [$rina, 'Kalau ada yang mau ditanyakan, langsung tulis aja', '09:20'],
                ],
            };

            foreach ($teks as [$pengirim, $isi, $jam]) {
                Message::create([
                    'room_id' => $room->id,
                    'sender_id' => $pengirim->id,
                    'text' => $isi,
                    'created_at' => \Illuminate\Support\Carbon::today()->setTimeFromTimeString($jam),
                    'updated_at' => \Illuminate\Support\Carbon::today()->setTimeFromTimeString($jam),
                ]);
            }
        }
    }
}
