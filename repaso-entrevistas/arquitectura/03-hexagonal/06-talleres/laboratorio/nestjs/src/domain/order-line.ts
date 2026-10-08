import { Money } from "./money.js";

// Foto del catálogo en el momento de la venta.
export class OrderLine {
  constructor(
    readonly sku: string,
    readonly name: string,
    readonly quantity: number,
    readonly unitPrice: Money,
  ) {
    if (!Number.isInteger(quantity) || quantity < 1) {
      throw new Error("quantity must be a positive integer");
    }
  }

  lineTotal(): Money {
    return this.unitPrice.times(this.quantity);
  }
}
