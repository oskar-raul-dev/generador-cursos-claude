import type { Product } from "../../domain/product.js";
import { mapPage, type Page, type PageRequest } from "../page.js";
import type { Inventory, Products } from "../ports.js";

export type ProductWithStock = { product: Product; stock: number };

// Catálogo + stock: dos puertos, dos unidades de consistencia (y desde la parte 3, dos bases).
// La composición ocurre aquí, no con un JOIN.
export class ListProducts {
  constructor(
    private readonly products: Products,
    private readonly inventory: Inventory,
  ) {}

  async execute(page: PageRequest): Promise<Page<ProductWithStock>> {
    const catalog = await this.products.list(page);
    const stock = await this.inventory.availableFor(catalog.items.map((p) => p.sku));
    return mapPage(catalog, (product) => ({ product, stock: stock.get(product.sku) ?? 0 }));
  }
}
