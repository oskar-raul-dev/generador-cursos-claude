<?php

namespace App\Support;

use Prometheus\CollectorRegistry;
use Prometheus\Storage\APC;
use Prometheus\Storage\InMemory;

// G6: el registro de métricas de catalog. En PHP-FPM cada petición la atiende un hijo distinto y nada
// sobrevive entre peticiones, así que los contadores tienen que vivir fuera del proceso: en APCu, la
// memoria compartida de todos los hijos del mismo FPM. METRICS_STORAGE=memory deja el almacenamiento
// del proceso, solo para medir lo que se pierde sin APCu (Fase 17).
class Metrics
{
    private static ?CollectorRegistry $registry = null;

    public static function registry(): CollectorRegistry
    {
        return self::$registry ??= new CollectorRegistry(
            env('METRICS_STORAGE', 'apcu') === 'memory' ? new InMemory() : new APC(),
            false, // sin las métricas por defecto de la librería: solo trae php_info
        );
    }
}
