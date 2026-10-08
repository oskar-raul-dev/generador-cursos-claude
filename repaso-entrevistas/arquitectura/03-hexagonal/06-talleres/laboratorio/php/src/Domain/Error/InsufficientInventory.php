<?php

declare(strict_types=1);

namespace Hex\Domain\Error;

/** La lanza el adaptador de inventario al primer faltante; la unidad de trabajo revierte el resto. */
final class InsufficientInventory extends DomainError
{
    public function __construct(
        public readonly string $sku,
        public readonly int $requested,
        public readonly int $available,
        public readonly int $lineIndex,
    ) {
        parent::__construct("{$sku}: requested {$requested}, available {$available}");
    }
}
