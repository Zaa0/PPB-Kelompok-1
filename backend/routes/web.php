<?php

use Illuminate\Support\Facades\Route;
use Illuminate\Support\Facades\Storage;

// Lampiran chat (foto/dokumen) - nama file acak, aman dipakai <img> langsung.
Route::get('/', fn () => response()->json(['app' => 'UniTalk API', 'status' => 'ok']));

Route::get('/attachments/{path}', function (string $path) {
    abort_if(str_contains($path, '..'), 400);
    return Storage::disk('public')->response('attachments/' . $path);
})->where('path', '.*');
