<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Str;
use Illuminate\Validation\ValidationException;

class AuthController extends Controller
{
    public function register(Request $request): JsonResponse
    {
        $data = $request->validate([
            'name' => ['required', 'string', 'max:60'],
            'email' => ['required', 'email', 'max:120', 'unique:users,email'],
            'password' => ['required', 'string', 'min:6'],
        ]);

        $user = User::create([
            'name' => $data['name'],
            'email' => strtolower($data['email']),
            'password' => $data['password'],
            'is_guest' => false,
        ]);

        return $this->respondWithToken($user, 'Registrasi berhasil');
    }

    public function login(Request $request): JsonResponse
    {
        $data = $request->validate([
            'email' => ['required', 'email'],
            'password' => ['required', 'string'],
        ]);

        $user = User::where('email', strtolower($data['email']))->first();

        if (! $user || ! Hash::check($data['password'], $user->password)) {
            throw ValidationException::withMessages([
                'email' => ['Email atau password salah.'],
            ]);
        }

        return $this->respondWithToken($user, 'Login berhasil');
    }

    // Buat user guest sementara tanpa email, langsung dapat token.
    public function guest(Request $request): JsonResponse
    {
        $user = User::create([
            'name' => 'Guest' . Str::padLeft((string) random_int(0, 999), 3, '0'),
            'email' => null,
            'password' => Str::random(32),
            'is_guest' => true,
        ]);

        return $this->respondWithToken($user, 'Mode guest aktif');
    }

    public function logout(Request $request): JsonResponse
    {
        $request->user()->currentAccessToken()->delete();

        return response()->json(['message' => 'Logout berhasil']);
    }

    public function me(Request $request): JsonResponse
    {
        return response()->json(['user' => $this->formatUser($request->user())]);
    }

    public function updateName(Request $request): JsonResponse
    {
        $data = $request->validate([
            'name' => ['required', 'string', 'max:60'],
        ]);

        $user = $request->user();
        $user->name = $data['name'];
        $user->save();

        return response()->json([
            'message' => 'Nama diperbarui',
            'user' => $this->formatUser($user),
        ]);
    }

    private function respondWithToken(User $user, string $message): JsonResponse
    {
        return response()->json([
            'message' => $message,
            'token' => $user->createToken('unitalk')->plainTextToken,
            'user' => $this->formatUser($user),
        ]);
    }

    private function formatUser(User $user): array
    {
        return [
            'id' => $user->id,
            'name' => $user->name,
            'email' => $user->email,
            'is_guest' => $user->is_guest,
        ];
    }
}
