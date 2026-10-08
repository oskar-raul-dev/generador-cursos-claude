<?php

declare(strict_types=1);

namespace Hex\Application\UseCase;

use Hex\Application\Page;
use Hex\Application\PageRequest;
use Hex\Application\Port\Inventory;
use Hex\Application\Port\Products;
use Hex\Domain\Product;

/**
 * Catálogo + stock: dos puertos, dos unidades de consistencia (y desde la parte 3, dos bases).
 * La composición ocurre aquí, no con un JOIN.
 */
final readonly class ListProducts
{
    public function __construct(private Products $products, private Inventory $inventory) {}

    /** @return Page<ProductWithStock> */
    public function execute(PageRequest $page): Page
    {
        $catalog = $this->products->list($page);
        $stock = $this->inventory->availableFor(array_map(fn (Product $p) => $p->sku, $catalog->items));

        return $catalog->map(fn (Product $p) => new ProductWithStock($p, $stock[$p->sku] ?? 0));
    }
}
