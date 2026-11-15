<?php

use Illuminate\Auth\AuthenticationException;
use Illuminate\Foundation\Application;
use Illuminate\Foundation\Configuration\Exceptions;
use Illuminate\Foundation\Configuration\Middleware;
use Illuminate\Http\Request;
use Symfony\Component\Routing\Exception\RouteNotFoundException;

return Application::configure(basePath: dirname(__DIR__))
    ->withRouting(
        web: __DIR__.'/../routes/web.php',
        api: __DIR__.'/../routes/api.php',
        commands: __DIR__.'/../routes/console.php',
        health: '/up',
    )
    ->withMiddleware(function (Middleware $middleware): void {
        //
    })
    ->withExceptions(function (Exceptions $exceptions): void {
        $exceptions->shouldRenderJsonWhen(
            fn (Request $request) => $request->is('api/*') || $request->expectsJson(),
        );

        // Aplikasi ini API-only (tidak ada halaman login web), jadi semua
        // akses tanpa token dibalas 401 JSON — bukan redirect ke /login.
        $exceptions->render(function (AuthenticationException $e, Request $request) {
            return response()->json(['message' => 'Belum login atau token tidak valid.'], 401);
        });
        $exceptions->render(function (RouteNotFoundException $e, Request $request) {
            return response()->json(['message' => 'Belum login atau token tidak valid.'], 401);
        });
    })->create();
