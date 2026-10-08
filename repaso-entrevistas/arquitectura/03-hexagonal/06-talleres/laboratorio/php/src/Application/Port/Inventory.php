<?php

declare(strict_types=1);

namespace Hex\Application\Port;

use Hex\Domain\OrderLine;

/**
 * reserve descuenta todas las líneas o lanza InsufficientInventory; la atomicidad la da la unidad
 * de trabajo que rodea al caso de uso.
 */
interface Inventory
{
    /**
     * @param  list<string>  $skus
     * @return array<string, int>
     */
    public function availableFor(array $skus): array;

    public function initialize(string $sku, int $quantity): void;

    /** @param list<OrderLine> $lines */
    public function reserve(string $orderId, array $lines): void;

    public function release(string $orderId): void;
}
