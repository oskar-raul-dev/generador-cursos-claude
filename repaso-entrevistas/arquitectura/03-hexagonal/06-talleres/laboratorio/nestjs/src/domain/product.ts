import { Money } from "./money.js";

// Catálogo: qué se vende y a qué precio. El stock vive en el inventario (otra unidad de
// consistencia y, en la parte 3, otra base).
export class Product {
  constructor(
    readonly sku: string,
    readonly name: string,
    readonly unitPrice: Money,
  ) {
    if (!/^SKU-[0-9]{3,}$/.test(sku)) {
      throw new Error(`invalid sku: ${sku}`);
    }
  }
}
