<?php

declare(strict_types=1);

namespace Hex\Application\UseCase;

use Hex\Application\Error\NotFound;
use Hex\Application\Port\Inventory;
use Hex\Application\Port\Products;

final readonly class GetProduct
{
    public function __construct(private Products $products, private Inventory $inventory) {}

    public function execute(string $sku): ProductWithStock
    {
        $product = $this->products->find($sku);
        if ($product === null) {
            throw new NotFound('PRODUCT', $sku);
        }

        return new ProductWithStock($product, $this->inventory->availableFor([$sku])[$sku] ?? 0);
    }
}
