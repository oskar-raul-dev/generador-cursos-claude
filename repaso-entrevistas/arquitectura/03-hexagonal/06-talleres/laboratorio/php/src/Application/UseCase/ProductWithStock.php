<?php

declare(strict_types=1);

namespace Hex\Application\UseCase;

use Hex\Domain\Product;

final readonly class ProductWithStock
{
    public function __construct(public Product $product, public int $stock) {}
}
