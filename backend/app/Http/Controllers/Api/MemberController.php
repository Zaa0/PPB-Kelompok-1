<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Room;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class MemberController extends Controller
{
    public function index(Request $request, Room $room): JsonResponse
    {
        $members = $room->members()
            ->orderBy('users.name')
            ->get(['users.id', 'users.name', 'users.is_guest']);

        return response()->json(['members' => $members->map(fn ($m) => [
            'id' => $m->id,
            'name' => $m->name,
            'is_guest' => $m->is_guest,
            'is_admin' => $m->id === $room->created_by,
        ])]);
    }

    public function kick(Request $request, Room $room): JsonResponse
    {
        if ($room->created_by !== $request->user()->id) {
            return response()->json(['message' => 'Hanya admin room yang bisa mengeluarkan anggota.'], 403);
        }

        $data = $request->validate([
            'user_id' => ['required', 'integer'],
        ]);

        if ((int) $data['user_id'] === (int) $room->created_by) {
            return response()->json(['message' => 'Admin room tidak bisa dikeluarkan.'], 422);
        }

        $room->members()->detach($data['user_id']);

        return response()->json(['message' => 'Anggota dikeluarkan']);
    }
}
