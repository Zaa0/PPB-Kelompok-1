<?php

namespace Tests\Feature;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class ApiFlowTest extends TestCase
{
    use RefreshDatabase;

    private function register(string $name, string $email): array
    {
        $res = $this->postJson('/api/register', [
            'name' => $name,
            'email' => $email,
            'password' => 'password123',
        ]);
        $res->assertOk();

        // Catatan: untuk penggantian user dalam satu test dipakai actingAs,
        // karena guard Sanctum meng-cache user per app instance saat test.
        return [
            'user' => User::find($res->json('user.id')),
            'token' => $res->json('token'),
        ];
    }

    private function guest(): array
    {
        $res = $this->postJson('/api/guest');
        $res->assertOk();

        return [
            'user' => User::find($res->json('user.id')),
            'token' => $res->json('token'),
        ];
    }

    public function test_register_login_dan_me(): void
    {
        $this->register('Yuza', 'yuza@sampel.ac.id');

        $login = $this->postJson('/api/login', [
            'email' => 'yuza@sampel.ac.id',
            'password' => 'password123',
        ])->assertOk();

        // Satu user per test: alur token bearer asli diuji apa adanya.
        $this->withToken($login->json('token'))->getJson('/api/me')
            ->assertOk()
            ->assertJsonPath('user.email', 'yuza@sampel.ac.id')
            ->assertJsonPath('user.is_guest', false);
    }

    public function test_login_salah_ditolak(): void
    {
        $this->register('Yuza', 'yuza@sampel.ac.id');

        $this->postJson('/api/login', [
            'email' => 'yuza@sampel.ac.id',
            'password' => 'ngasal',
        ])->assertStatus(422);
    }

    public function test_butuh_token(): void
    {
        $this->getJson('/api/rooms')->assertUnauthorized();
    }

    public function test_buat_room_gabung_kirim_pesan_hapus(): void
    {
        $a = $this->register('A', 'a@sampel.ac.id');
        $b = $this->register('B', 'b@sampel.ac.id');

        $room = $this->actingAs($a['user'], 'sanctum')->postJson('/api/rooms', [
            'name' => 'Room Uji',
            'category' => 'matkul',
        ])->assertCreated()->json('room');

        $this->assertSame('Room Uji', $room['name']);
        $this->assertTrue($room['is_admin']);

        // B gabung pakai kode undangan, huruf kecil tetap kena.
        $this->actingAs($b['user'], 'sanctum')->postJson('/api/rooms/join', [
            'code' => strtolower($room['invite_code']),
        ])->assertOk();

        // B kirim pesan lalu otomatis jadi anggota.
        $msg = $this->actingAs($b['user'], 'sanctum')->postJson("/api/rooms/{$room['id']}/messages", [
            'text' => 'halo',
        ])->assertCreated()->json('message');

        $this->assertSame('B', $msg['sender_name']);

        $this->actingAs($a['user'], 'sanctum')->getJson("/api/rooms/{$room['id']}/messages")
            ->assertOk()
            ->assertJsonFragment(['text' => 'halo']);

        // Polling pakai ?after= — pesan baru saja.
        $this->actingAs($b['user'], 'sanctum')->getJson("/api/rooms/{$room['id']}/messages?after={$msg['id']}")
            ->assertOk()
            ->assertJsonCount(0, 'messages');

        // A (admin room) bisa hapus pesan B.
        $this->actingAs($a['user'], 'sanctum')->deleteJson("/api/messages/{$msg['id']}")->assertOk();

        // Non-admin tidak bisa hapus room; admin bisa.
        $this->actingAs($b['user'], 'sanctum')->deleteJson("/api/rooms/{$room['id']}")->assertForbidden();
        $this->actingAs($a['user'], 'sanctum')->deleteJson("/api/rooms/{$room['id']}")->assertOk();

        // Room hilang, pesan ikut terhapus.
        $this->assertDatabaseMissing('rooms', ['id' => $room['id']]);
    }

    public function test_guest_dibatasi(): void
    {
        $a = $this->register('A', 'a@sampel.ac.id');
        $g = $this->guest();

        $roomBiasa = $this->actingAs($a['user'], 'sanctum')->postJson('/api/rooms', [
            'name' => 'X', 'category' => 'matkul',
        ])->json('room');
        $roomTopik = $this->actingAs($a['user'], 'sanctum')->postJson('/api/rooms', [
            'name' => 'Y', 'category' => 'topik',
        ])->json('room');

        $this->assertTrue($roomTopik['allow_guest']);

        // Guest tidak bisa buat room.
        $this->actingAs($g['user'], 'sanctum')->postJson('/api/rooms', [
            'name' => 'G', 'category' => 'matkul',
        ])->assertForbidden();

        // Guest tidak bisa posting di room biasa, tapi boleh di allow_guest.
        $this->actingAs($g['user'], 'sanctum')->postJson("/api/rooms/{$roomBiasa['id']}/messages", [
            'text' => 'hai',
        ])->assertForbidden();
        $this->actingAs($g['user'], 'sanctum')->postJson("/api/rooms/{$roomTopik['id']}/messages", [
            'text' => 'hai',
        ])->assertCreated();

        // Non-admin tidak bisa kick.
        $this->actingAs($g['user'], 'sanctum')->postJson("/api/rooms/{$roomTopik['id']}/kick", [
            'user_id' => $a['user']->id,
        ])->assertForbidden();
    }

    public function test_admin_bisa_kick_anggota_tapi_bukan_dirinya(): void
    {
        $a = $this->register('A', 'a@sampel.ac.id');
        $b = $this->register('B', 'b@sampel.ac.id');

        $room = $this->actingAs($a['user'], 'sanctum')->postJson('/api/rooms', [
            'name' => 'Room', 'category' => 'topik',
        ])->json('room');

        $this->actingAs($b['user'], 'sanctum')->postJson("/api/rooms/{$room['id']}/messages", ['text' => 'halo'])
            ->assertCreated();

        $this->actingAs($a['user'], 'sanctum')->postJson("/api/rooms/{$room['id']}/kick", [
            'user_id' => $a['user']->id, // admin tidak boleh dikeluarkan
        ])->assertStatus(422);

        $this->actingAs($a['user'], 'sanctum')->postJson("/api/rooms/{$room['id']}/kick", [
            'user_id' => $b['user']->id,
        ])->assertOk();

        $this->actingAs($a['user'], 'sanctum')->getJson("/api/rooms/{$room['id']}/members")
            ->assertOk()
            ->assertJsonCount(1, 'members');
    }
}
