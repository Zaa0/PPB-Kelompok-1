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
        $query = $room->messages()->with('sender:id,name,alias')->orderBy('id');

        // ?after=<id> dipakai polling: ambil pesan baru saja.
        if ($after = $request->integer('after')) {
            $query->where('id', '>', $after);
        }

        return response()->json([
            'messages' => $query->get()->map(fn (Message $m) => $this->format($m, $this->isImage($m))),
        ]);
    }

    public function store(Request $request, Room $room): JsonResponse
    {
        if ($request->user()->is_guest && ! $room->allow_guest) {
            return response()->json(['message' => 'Guest hanya bisa mengirim pesan di room yang mengizinkan tamu.'], 403);
        }

        $request->validate([
            // Teks boleh kosong kalau mengirim lampiran (dan sebaliknya).
            'text' => ['nullable', 'string', 'max:1000', 'required_without:file'],
            'file' => ['nullable', 'file', 'max:10240'],
        ]);

        // User non-guest yang mengirim pesan otomatis jadi anggota room.
        if (! $request->user()->is_guest) {
            $room->members()->syncWithoutDetaching([$request->user()->id]);
        }

        $attachmentPath = null;
        $attachmentName = null;
        $isImage = false;

        if ($request->hasFile('file')) {
            $file = $request->file('file');
            $attachmentPath = $file->store('attachments', 'public');
            $attachmentName = $file->getClientOriginalName();
            $isImage = str_starts_with($file->getMimeType() ?? '', 'image/');
        }

        $message = $room->messages()->create([
            'sender_id' => $request->user()->id,
            'text' => $request->input('text'),
            'attachment_path' => $attachmentPath,
            'attachment_name' => $attachmentName,
        ]);

        return response()->json(['message' => $this->format($message, $isImage)], 201);
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

    private function format(Message $m, bool $isImage = false): array
    {
        return [
            'id' => $m->id,
            'room_id' => $m->room_id,
            'sender_id' => $m->sender_id,
            'sender_name' => $m->sender?->alias ?? $m->sender?->name ?? 'Guest',
            'text' => $m->text,
            // Path relatif - Flutter menambahkan origin server supaya
            // bisa diakses dari HP (bukan localhost saja).
            'attachment_url' => $m->attachment_path
                ? '/attachments/' . $m->attachment_path
                : null,
            'attachment_name' => $m->attachment_name,
            'is_image' => $isImage,
            'created_at' => $m->created_at?->toIso8601String(),
        ];
    }

    private function isImage(Message $m): bool
    {
        return $m->attachment_path !== null
            && preg_match('/\.(jpe?g|png|gif|webp)$/i', $m->attachment_path) === 1;
    }
}
