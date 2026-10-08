<?php

declare(strict_types=1);

// HandleCors ya está en la pila global de Laravel; esto es lo que el contrato exige exponer.
return [
    'paths' => ['api/*', 'health'],
    'allowed_methods' => ['GET', 'POST', 'OPTIONS'],
    'allowed_origins' => [env('HEX_CORS_ORIGIN', 'http://localhost:5173')],
    'allowed_origins_patterns' => [],
    'allowed_headers' => ['Authorization', 'Content-Type', 'Idempotency-Key', 'Accept'],
    'exposed_headers' => ['Location', 'Idempotent-Replay'],
    'max_age' => 0,
    'supports_credentials' => false,
];
