<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Str;

// G7: una línea JSON por petición, con los mismos campos que los otros tres. El request_id viene en
// X-Request-Id (lo pone la puerta, o inventory al preguntar por un producto) o se inventa; withContext lo
// suma a cualquier otra línea que se escriba durante la petición.
class LogRequest
{
    public function handle(Request $request, Closure $next)
    {
        $start = hrtime(true);
        $requestId = $request->header('X-Request-Id') ?: (string) Str::uuid();
        Log::withContext(['request_id' => $requestId]);
        $response = $next($request);
        $route = $request->route();
        Log::info('request', [
            'method' => $request->method(),
            'uri' => ($route === null || $route->isFallback) ? '/**' : '/'.ltrim($route->uri(), '/'),
            'path' => '/'.ltrim($request->path(), '/'),
            'status' => $response->getStatusCode(),
            'duration_ms' => round((hrtime(true) - $start) / 1e6, 3),
        ]);

        return $response;
    }
}
