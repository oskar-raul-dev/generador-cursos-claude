<?php

use App\Models\Product;
use Illuminate\Support\Facades\Route;

Route::get('/', function () {
    $products = Product::orderBy('sku')->get();
    return view('catalog', [
        'products' => $products,
        'syncedAt' => $products->max('synced_at'),
    ]);
});
