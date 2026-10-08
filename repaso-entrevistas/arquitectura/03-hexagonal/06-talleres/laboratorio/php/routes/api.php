<?php

declare(strict_types=1);

use App\Http\Controllers\AuthController;
use App\Http\Controllers\NotificationController;
use App\Http\Controllers\OrderController;
use App\Http\Controllers\ProductController;
use Illuminate\Support\Facades\Route;

// Las rutas del contrato, bajo el prefijo api/v1 que pone bootstrap/app.php.
Route::post('/auth/login', [AuthController::class, 'login']);

Route::middleware('hex.auth')->group(function (): void {
    Route::post('/auth/logout', [AuthController::class, 'logout']);

    Route::get('/products', [ProductController::class, 'list']);
    Route::get('/products/{sku}', [ProductController::class, 'get']);
    Route::post('/products', [ProductController::class, 'create']);

    Route::post('/orders', [OrderController::class, 'create']);
    Route::get('/orders', [OrderController::class, 'list']);
    Route::get('/orders/{orderId}', [OrderController::class, 'get']);
    Route::post('/orders/{orderId}/payment', [OrderController::class, 'pay']);
    Route::post('/orders/{orderId}/cancel', [OrderController::class, 'cancel']);   // parte 2

    Route::get('/notifications', [NotificationController::class, 'list']);       // parte 2
});
