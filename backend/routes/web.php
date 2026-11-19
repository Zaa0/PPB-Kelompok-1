<?php

use Illuminate\Support\Facades\Route;
use Illuminate\Support\Facades\Storage;

// Lampiran chat (foto/dokumen) - nama file acak, aman dipakai <img> langsung.
Route::get('/', fn () => response()->json(['app' => 'UniTalk API', 'status' => 'ok']));

Route::get('/attachments/{path}', function (string $path) {
    abort_if(str_contains($path, '..'), 400);
    // CORS: browser (Flutter web) menolak memuat gambar dari server lain
    // tanpa header ini - HP tidak terkena karena tidak lewat browser.
    $response = Storage::disk('public')->response($path);
    $response->headers->set('Access-Control-Allow-Origin', '*');
    $response->headers->set('Access-Control-Allow-Headers', 'Origin, Content-Type, Accept');
    return $response;
})->where('path', '.*');
