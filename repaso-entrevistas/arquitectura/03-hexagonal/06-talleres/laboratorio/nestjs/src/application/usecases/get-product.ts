import { NotFound } from "../errors.js";
import type { Inventory, Products } from "../ports.js";
import type { ProductWithStock } from "./list-products.js";

export class GetProduct {
  constructor(
    private readonly products: Products,
    private readonly inventory: Inventory,
  ) {}

  async execute(sku: string): Promise<ProductWithStock> {
    const product = await this.products.find(sku);
    if (!product) {
      throw new NotFound("PRODUCT", sku);
    }
    const stock = await this.inventory.availableFor([sku]);
    return { product, stock: stock.get(sku) ?? 0 };
  }
}
