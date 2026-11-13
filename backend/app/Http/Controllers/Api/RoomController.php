<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Resources\RoomResource;
use App\Models\Room;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class RoomController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $rooms = Room::query()
            ->with(['members:id', 'lastMessage'])
            ->withCount('members')
            ->orderBy('id')
            ->get();

        return response()->json(['rooms' => RoomResource::collection($rooms)]);
    }

    public function store(Request $request): JsonResponse
    {
        if ($request->user()->is_guest) {
            return response()->json(['message' => 'Guest tidak bisa membuat room.'], 403);
        }

        $data = $request->validate([
            'name' => ['required', 'string', 'max:100'],
            'description' => ['nullable', 'string', 'max:200'],
            'category' => ['required', 'in:matkul,organisasi,topik'],
        ]);

        $room = Room::create([
            'name' => $data['name'],
            'description' => $data['description'] ?? null,
            'category' => $data['category'],
            'invite_code' => $this->newInviteCode(),
            // Room topik bebas otomatis boleh diisi guest, sama seperti konsep app.
            'allow_guest' => $data['category'] === 'topik',
            'created_by' => $request->user()->id,
        ]);
        $room->members()->attach($request->user()->id);

        return response()->json([
            'message' => 'Room dibuat',
            'room' => new RoomResource($this->freshRoom($room)),
        ], 201);
    }

    public function join(Request $request): JsonResponse
    {
        $data = $request->validate([
            'code' => ['required', 'string'],
        ]);

        $room = Room::where('invite_code', strtoupper(trim($data['code'])))->first();

        if (! $room) {
            return response()->json(['message' => 'Kode tidak ditemukan'], 404);
        }

        $room->members()->syncWithoutDetaching([$request->user()->id]);

        return response()->json([
            'message' => 'Berhasil gabung room',
            'room' => new RoomResource($this->freshRoom($room)),
        ]);
    }

    public function destroy(Request $request, Room $room): JsonResponse
    {
        if ($room->created_by !== $request->user()->id) {
            return response()->json(['message' => 'Hanya pembuat room yang bisa menghapus.'], 403);
        }

        // Pesan & membership ikut terhapus lewat FK cascade.
        $room->delete();

        return response()->json(['message' => 'Room dihapus']);
    }

    private function freshRoom(Room $room): Room
    {
        return $room->fresh(['members:id', 'lastMessage'])->loadCount('members');
    }

    private function newInviteCode(): string
    {
        do {
            $code = 'UT-' . random_int(1000, 9999);
        } while (Room::where('invite_code', $code)->exists());

        return $code;
    }
}
