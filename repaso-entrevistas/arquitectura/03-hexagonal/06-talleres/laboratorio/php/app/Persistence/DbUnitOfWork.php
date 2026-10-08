<?php

declare(strict_types=1);

namespace App\Persistence;

use Closure;
use Hex\Application\Port\UnitOfWork;
use Illuminate\Database\ConnectionInterface;

/**
 * La unidad de trabajo es la transacción de la conexión de Laravel. Todos los adaptadores de
 * PostgreSQL reciben ESTA misma conexión (el contenedor la entrega como singleton), así que
 * comparten la transacción sin que el caso de uso les pase nada: en PHP una petición es un
 * proceso y la conexión es su "contexto". Si ya hay una transacción abierta, Laravel anida con un
 * SAVEPOINT y confirma todo al cerrar la exterior.
 */
final readonly class DbUnitOfWork implements UnitOfWork
{
    public function __construct(private ConnectionInterface $db) {}

    public function run(Closure $work): mixed
    {
        return $this->db->transaction($work);
    }
}
