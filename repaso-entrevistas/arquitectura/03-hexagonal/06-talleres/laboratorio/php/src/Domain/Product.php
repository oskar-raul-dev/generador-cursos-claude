<?php

declare(strict_types=1);

namespace Hex\Domain;

use InvalidArgumentException;

/**
 * Catálogo: qué se vende y a qué precio. El stock vive en el inventario (otra unidad de
 * consistencia y, en la parte 3, otra base).
 */
final readonly class Product
{
    public function __construct(public string $sku, public string $name, public Money $unitPrice)
    {
        if (preg_match('/^SKU-[0-9]{3,}$/', $sku) !== 1) {
            throw new InvalidArgumentException("invalid sku: {$sku}");
        }
        if ($name === '') {
            throw new InvalidArgumentException('empty product name');
        }
    }
}
