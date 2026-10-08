<?php

declare(strict_types=1);

namespace Hex\Application\UseCase;

use Hex\Application\Actor;
use Hex\Application\Error\ProductAlreadyExists;
use Hex\Application\Port\Inventory;
use Hex\Application\Port\Products;
use Hex\Application\Port\UnitOfWork;
use Hex\Domain\Money;
use Hex\Domain\Product;

/** Alta de catálogo e inventario inicial, solo para operator. */
final readonly class CreateProduct
{
    public function __construct(private Products $products, private Inventory $inventory, private UnitOfWork $unitOfWork) {}

    public function execute(Actor $actor, string $sku, string $name, Money $unitPrice, int $stock): ProductWithStock
    {
        $actor->requireOperator();
        $product = new Product($sku, $name, $unitPrice);

        return $this->unitOfWork->run(function () use ($product, $stock): ProductWithStock {
            if ($this->products->exists($product->sku)) {
                throw new ProductAlreadyExists($product->sku);
            }
            $this->products->save($product);
            $this->inventory->initialize($product->sku, $stock);

            return new ProductWithStock($product, $stock);
        });
    }
}
