<?php

declare(strict_types=1);

// Configuración propia del taller. Valores por defecto: §11 de la guía. HEX_CATALOG elige la parte 3.
return [
    'catalog' => env('HEX_CATALOG', 'postgres'),                       // postgres | mongo
    'mongo_url' => env('HEX_MONGO_URL', 'mongodb://localhost:17017/hex_catalog'),
    'jwt_secret' => env('HEX_JWT_SECRET', 'hex-lab-dev-secret-change-me-0123456789'),
    'jwt_ttl_seconds' => (int) env('HEX_JWT_TTL_SECONDS', 900),
    'outbox_poll_ms' => (int) env('HEX_OUTBOX_POLL_MS', 500),
    'cors_origin' => env('HEX_CORS_ORIGIN', 'http://localhost:5173'),
];
