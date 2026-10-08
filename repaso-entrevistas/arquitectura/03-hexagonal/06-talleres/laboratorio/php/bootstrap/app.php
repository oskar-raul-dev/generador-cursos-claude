<?php

declare(strict_types=1);

use App\Http\Middleware\Authenticate;
use App\Http\Problems\MissingIdempotencyKey;
use App\Http\Problems\Problems;
use App\Http\Problems\Unauthenticated;
use App\Http\Problems\ValidationFailed;
use Hex\Application\Error\ApplicationError;
use Hex\Domain\Error\DomainError;
use Illuminate\Foundation\Application;
use Illuminate\Foundation\Configuration\Exceptions;
use Illuminate\Foundation\Configuration\Middleware;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;

/*
 * El arranque de Laravel 11+: sin Kernel HTTP, sin grupo `api` (que traería throttle:api, 60/min,
 * y la suite hace 85 peticiones en tres segundos). Las rutas se registran a mano con `using`.
 */
return Application::configure(basePath: dirname(__DIR__))
    ->withRouting(
        using: function (): void {
            Route::get('/health', fn () => response()->json(['status' => 'UP']));
            Route::prefix('api/v1')->group(base_path('routes/api.php'));
        },
        commands: __DIR__.'/../routes/console.php',
    )
    ->withMiddleware(function (Middleware $middleware): void {
        $middleware->alias(['hex.auth' => Authenticate::class]);  // el guardián del borde, por nombre
    })
    ->withExceptions(function (Exceptions $exceptions): void {
        // Laravel REPORTA (registra como ERROR) toda excepción antes de traducirla. Un rechazo de
        // negocio esperado (401, 404, 409) no es un error del sistema: no se reporta.
        $exceptions->dontReport([DomainError::class, ApplicationError::class, Unauthenticated::class, MissingIdempotencyKey::class, ValidationFailed::class]);
        // Un solo traductor: cualquier Throwable termina en problem+json con el código del contrato.
        $exceptions->render(fn (Throwable $e, Request $request) => Problems::render($e, $request));
    })->create();
