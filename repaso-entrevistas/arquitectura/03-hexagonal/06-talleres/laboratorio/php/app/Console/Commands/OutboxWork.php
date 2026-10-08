<?php

declare(strict_types=1);

namespace App\Console\Commands;

use Hex\Application\UseCase\DeliverPendingPublications;
use Illuminate\Console\Command;
use Throwable;

/**
 * El disparador de la outbox (parte 2). PHP no tiene un hilo de fondo dentro del servidor HTTP:
 * cada petición es un proceso corto. El trabajo periódico es OTRO proceso, como `queue:work`.
 * Un solo bucle secuencial: no solapa rondas por construcción. SIGINT/SIGTERM lo paran limpio.
 */
final class OutboxWork extends Command
{
    protected $signature = 'outbox:work {--interval=500 : milisegundos entre rondas} {--once : una ronda y salir}';

    protected $description = 'Entrega los hechos pendientes de la outbox al Notifier';

    private bool $stopping = false;

    public function handle(DeliverPendingPublications $deliver): int
    {
        pcntl_async_signals(true);
        foreach ([SIGINT, SIGTERM] as $signal) {
            pcntl_signal($signal, function (): void {
                $this->stopping = true;
            });
        }
        $interval = max(50, (int) $this->option('interval')) * 1000;
        $this->info('outbox worker started (interval='.($interval / 1000).'ms)');

        do {
            try {
                $delivered = $deliver->execute(50);
                if ($delivered > 0) {
                    $this->info("outbox: delivered {$delivered} event(s)");
                }
            } catch (Throwable $e) {
                $this->error('outbox: delivery round failed: '.$e->getMessage());   // la siguiente ronda reintenta
            }
            if ($this->option('once')) {
                break;
            }
            usleep($interval);
        } while (! $this->stopping);

        $this->info('outbox worker stopped');

        return self::SUCCESS;
    }
}
