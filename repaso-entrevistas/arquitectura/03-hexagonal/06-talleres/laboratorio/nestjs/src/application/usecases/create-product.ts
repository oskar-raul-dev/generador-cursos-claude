import type { Money } from "../../domain/money.js";
import { Product } from "../../domain/product.js";
import type { Actor } from "../actor.js";
import { ProductAlreadyExists } from "../errors.js";
import type { Inventory, Products, UnitOfWork } from "../ports.js";
import type { ProductWithStock } from "./list-products.js";

export class CreateProduct {
  constructor(
    private readonly products: Products,
    private readonly inventory: Inventory,
    private readonly unitOfWork: UnitOfWork,
  ) {}

  async execute(actor: Actor, sku: string, name: string, unitPrice: Money, stock: number): Promise<ProductWithStock> {
    actor.requireOperator();
    const product = new Product(sku, name, unitPrice);
    return this.unitOfWork.run(async () => {
      if (await this.products.exists(product.sku)) {
        throw new ProductAlreadyExists(product.sku);
      }
      await this.products.save(product);
      await this.inventory.initialize(product.sku, stock);
      return { product, stock };
    });
  }
}
