<?php

namespace App\Http\Middleware;

use App\Support\Metrics;
use Closure;
use Illuminate\Http\Request;

// G6: cada petición, al histograma que el contrato fija para los cuatro backends. uri es el patrón de la
// ruta (/products/{sku}) y nunca la ruta cruda; lo que cae en la ruta de "todo lo demás" se cuenta junto,
// como /**.
class MeasureRequest
{
    private const BUCKETS = [0.005, 0.01, 0.025, 0.05, 0.1, 0.25, 0.5, 1, 2.5, 5, 10];

    public function handle(Request $request, Closure $next)
    {
        $start = hrtime(true);
        $response = $next($request);
        $route = $request->route();
        $uri = ($route === null || $route->isFallback) ? '/**' : '/'.ltrim($route->uri(), '/');
        Metrics::registry()
            ->getOrRegisterHistogram('http_server', 'requests_seconds',
                'Duración de las peticiones HTTP atendidas, en segundos.', ['method', 'uri', 'status'], self::BUCKETS)
            ->observe((hrtime(true) - $start) / 1e9, [$request->method(), $uri, (string) $response->getStatusCode()]);

        return $response;
    }
}
