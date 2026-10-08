<?php

declare(strict_types=1);

namespace Hex\Domain;

use InvalidArgumentException;

/** Foto del catálogo en el momento de la venta. */
final readonly class OrderLine
{
    public function __construct(public string $sku, public string $name, public int $quantity, public Money $unitPrice)
    {
        if ($quantity < 1) {
            throw new InvalidArgumentException('quantity must be positive');
        }
    }

    public function lineTotal(): Money
    {
        return $this->unitPrice->times($this->quantity);
    }
}
