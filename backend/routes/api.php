<?php

use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\MemberController;
use App\Http\Controllers\Api\MessageController;
use App\Http\Controllers\Api\RoomController;
use Illuminate\Support\Facades\Route;

// ── Auth (terbuka) ──
Route::post('/register', [AuthController::class, 'register']);
Route::post('/login', [AuthController::class, 'login'])->middleware('throttle:10,1');
Route::post('/guest', [AuthController::class, 'guest']);

// ── Butuh token (Sanctum) ──
Route::middleware('auth:sanctum')->group(function () {
    Route::get('/me', [AuthController::class, 'me']);
    Route::patch('/me', [AuthController::class, 'updateName']);
    Route::post('/logout', [AuthController::class, 'logout']);

    Route::get('/rooms', [RoomController::class, 'index']);
    Route::post('/rooms/join', [RoomController::class, 'join']);
    Route::post('/rooms', [RoomController::class, 'store']);
    Route::delete('/rooms/{room}', [RoomController::class, 'destroy']);

    Route::get('/rooms/{room}/messages', [MessageController::class, 'index']);
    Route::post('/rooms/{room}/messages', [MessageController::class, 'store']);
    Route::delete('/messages/{message}', [MessageController::class, 'destroy']);

    Route::get('/rooms/{room}/members', [MemberController::class, 'index']);
    Route::post('/rooms/{room}/kick', [MemberController::class, 'kick']);
});
