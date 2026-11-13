<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * @mixin \App\Models\Room
 */
class RoomResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        $user = $request->user();

        return [
            'id' => $this->id,
            'name' => $this->name,
            'category' => $this->category,
            'description' => $this->description,
            'invite_code' => $this->invite_code,
            'allow_guest' => $this->allow_guest,
            'created_by' => $this->created_by,
            'member_count' => $this->members_count ?? $this->members()->count(),
            'members' => $this->members->pluck('id'),
            'is_member' => $user !== null && $this->members->contains('id', $user->id),
            'is_admin' => $user !== null && $this->created_by === $user->id,
            'last_message' => $this->lastMessage === null ? null : [
                'text' => $this->lastMessage->text,
                'created_at' => $this->lastMessage->created_at?->toIso8601String(),
            ],
        ];
    }
}
