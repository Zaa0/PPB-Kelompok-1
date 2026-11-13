<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Message;
use App\Models\Room;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class MessageController extends Controller
{
    public function index(Request $request, Room $room): JsonResponse
    {
        $query = $room->messages()->with('sender:id,name')->orderBy('id');

        // ?after=<id> dipakai polling: ambil pesan baru saja.
        if ($after = $request->integer('after')) {
            $query->where('id', '>', $after);
        }

        return response()->json(['messages' => $query->get()->map(fn (Message $m) => $this->format($m))]);
    }

    public function store(Request $request, Room $room): JsonResponse
    {
        if ($request->user()->is_guest && ! $room->allow_guest) {
            return response()->json(['message' => 'Guest hanya bisa mengirim pesan di room yang mengizinkan tamu.'], 403);
        }

        $data = $request->validate([
            'text' => ['required', 'string', 'max:1000'],
        ]);

        // User non-guest yang mengirim pesan otomatis jadi anggota room.
        if (! $request->user()->is_guest) {
            $room->members()->syncWithoutDetaching([$request->user()->id]);
        }

        $message = $room->messages()->create([
            'sender_id' => $request->user()->id,
            'text' => $data['text'],
        ]);

        return response()->json(['message' => $this->format($message)], 201);
    }

    public function destroy(Request $request, Message $message): JsonResponse
    {
        $room = Room::findOrFail($message->room_id);

        $mayDelete = $message->sender_id === $request->user()->id
            || $room->created_by === $request->user()->id;

        if (! $mayDelete) {
            return response()->json(['message' => 'Tidak diizinkan menghapus pesan ini.'], 403);
        }

        $message->delete();

        return response()->json(['message' => 'Pesan dihapus']);
    }

    private function format(Message $m): array
    {
        return [
            'id' => $m->id,
            'room_id' => $m->room_id,
            'sender_id' => $m->sender_id,
            'sender_name' => $m->sender?->name ?? 'Guest',
            'text' => $m->text,
            'created_at' => $m->created_at?->toIso8601String(),
        ];
    }
}
