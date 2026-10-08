<?php

declare(strict_types=1);

namespace Hex\Application\Port;

use Closure;

/** El límite transaccional como capacidad: "ejecuta esto y confirma todo o nada". */
interface UnitOfWork
{
    /**
     * @template T
     *
     * @param  Closure(): T  $work
     * @return T
     */
    public function run(Closure $work): mixed;
}
