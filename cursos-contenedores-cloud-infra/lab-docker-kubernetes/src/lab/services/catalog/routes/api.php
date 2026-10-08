<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Route;
use App\Support\Metrics;
use Prometheus\RenderTextFormat;

// Salud. La liveness nunca consulta dependencias.
Route::get('/health/live', fn () => response()->json(['status' => 'live']));
// La readiness (G4): lista solo si la base contesta. Llega por nginx y por PHP-FPM, así que también
// dice que los dos procesos del pod atienden. Ningún vecino: eso sería una cascada.
Route::get('/health/ready', function () {
    try {
        DB::select('select 1');
    } catch (\Throwable $e) {
        Log::warning('no listo: la base no contesta', ['error' => $e->getMessage()]);

        return response()->json(['status' => 'not_ready'], 503);
    }

    return response()->json(['status' => 'ready']);
});

// G6: lo que Prometheus viene a buscar cada 15 s, en su formato de texto.
Route::get('/metrics', fn () => response(
    (new RenderTextFormat())->render(Metrics::registry()->getMetricFamilySamples()),
    200,
    ['Content-Type' => RenderTextFormat::MIME_TYPE],
));

// G1: el catálogo en su propio almacén. Los datos maestros se editan; descontinuar exige un código.
$error = fn (int $status, string $code, string $message) =>
    response()->json(['error' => $code, 'message' => $message], $status);

$product = fn (object $row) => [
    'sku' => $row->sku,
    'name' => $row->name,
    'category' => $row->category,
    'status' => $row->status,
    'statusReasonCode' => $row->status_reason_code,
];

$categories = fn () => DB::table('categories')->pluck('name')->all();

$activeReason = fn (?string $code) => $code !== null
    && DB::table('reason_codes')->where('code', $code)->where('active', true)->exists();

Route::get('/products', function (Request $request) use ($product, $error) {
    $status = $request->query('status', 'ACTIVE');
    if (! in_array($status, ['ACTIVE', 'DISCONTINUED', 'all'], true)) {
        return $error(422, 'unprocessable', 'status es ACTIVE, DISCONTINUED o all');
    }
    $query = DB::table('products')->orderBy('sku');
    if ($status !== 'all') {
        $query->where('status', $status);
    }

    return response()->json($query->get()->map($product)->values());
});

Route::post('/products', function (Request $request) use ($product, $error, $categories) {
    $sku = $request->json('sku');
    $name = $request->json('name');
    $category = $request->json('category');
    if (! is_string($sku) || ! preg_match('/^SKU-[0-9]{4}$/', $sku) || ! is_string($name) || $name === ''
        || ! in_array($category, $categories(), true)) {
        return $error(422, 'unprocessable', 'se esperan sku (SKU-0000), name y una categoría existente');
    }
    if (DB::table('products')->where('sku', $sku)->exists()) {
        return $error(409, 'conflict', "el producto $sku ya existe");
    }
    DB::table('products')->insert(['sku' => $sku, 'name' => $name, 'category' => $category]);

    return response()->json($product(DB::table('products')->where('sku', $sku)->first()), 201);
});

Route::get('/products/{sku}', function (string $sku) use ($product, $error) {
    $row = DB::table('products')->where('sku', $sku)->first();

    return $row ? response()->json($product($row)) : $error(404, 'not_found', "no existe $sku");
});

Route::patch('/products/{sku}', function (Request $request, string $sku) use ($product, $error, $categories, $activeReason) {
    $row = DB::table('products')->where('sku', $sku)->first();
    if (! $row) {
        return $error(404, 'not_found', "no existe $sku");
    }
    $patch = $request->json()->all();
    $allowed = ['name', 'category', 'status', 'reasonCode'];
    if ($patch === [] || array_diff(array_keys($patch), $allowed) !== []) {
        return $error(422, 'unprocessable', 'solo se cambian name, category y status (con reasonCode al descontinuar)');
    }
    $changes = [];
    if (array_key_exists('name', $patch)) {
        $changes['name'] = $patch['name'];
    }
    if (array_key_exists('category', $patch)) {
        if (! in_array($patch['category'], $categories(), true)) {
            return $error(422, 'unprocessable', 'la categoría no existe');
        }
        $changes['category'] = $patch['category'];
    }
    $status = $patch['status'] ?? null;
    if ($status === 'DISCONTINUED') {
        if (! $activeReason($patch['reasonCode'] ?? null)) {
            return $error(422, 'unprocessable', 'descontinuar exige un reasonCode existente y activo');
        }
        $changes += ['status' => 'DISCONTINUED', 'status_reason_code' => $patch['reasonCode']];
    } elseif ($status === 'ACTIVE') {
        $changes += ['status' => 'ACTIVE', 'status_reason_code' => null];
    } elseif ($status !== null || array_key_exists('reasonCode', $patch)) {
        return $error(422, 'unprocessable', 'status es ACTIVE o DISCONTINUED; reasonCode solo al descontinuar');
    }
    DB::table('products')->where('sku', $sku)->update($changes);

    return response()->json($product(DB::table('products')->where('sku', $sku)->first()));
});

Route::get('/categories', fn () => response()->json($categories()));

Route::get('/reason-codes', fn () => response()->json(
    DB::table('reason_codes')->orderBy('code')->get()->map(fn ($r) => [
        'code' => $r->code, 'description' => $r->description, 'active' => (bool) $r->active,
    ])->values()
));

// Todo lo demás todavía no existe.
Route::fallback(fn () => response()->json(['error' => 'not_found'], 404));
