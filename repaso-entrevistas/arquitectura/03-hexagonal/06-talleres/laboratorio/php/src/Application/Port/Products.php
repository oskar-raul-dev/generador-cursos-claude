<?php

declare(strict_types=1);

namespace Hex\Application\Port;

use Hex\Application\Page;
use Hex\Application\PageRequest;
use Hex\Domain\Product;

/** El catálogo. Ni PDO ni MongoDB asoman: la parte 3 cambia la implementación y nada más. */
interface Products
{
    public function find(string $sku): ?Product;

    public function exists(string $sku): bool;

    /** @return Page<Product> */
    public function list(PageRequest $page): Page;

    public function save(Product $product): void;
}
