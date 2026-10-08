import { Order } from "../../domain/order.js";
import { OrderLine } from "../../domain/order-line.js";
import type { Actor } from "../actor.js";
import { IdempotencyKeyReused, NotFound } from "../errors.js";
import type { Clock, IdGenerator, IdempotencyStore, Inventory, Orders, Products, UnitOfWork } from "../ports.js";

export type LineRequest = { sku: string; quantity: number };
export type CreateOrderCommand = { actor: Actor; idempotencyKey: string; requestHash: string; lines: LineRequest[] };
export type CreateOrderResult = { order: Order; replayed: boolean };

// Crear un pedido reservando el inventario de todas sus líneas, o nada. Una transacción rodea
// idempotencia, catálogo, pedido, reserva y clave: si algo falla, todo se revierte.
export class CreateOrder {
  constructor(
    private readonly products: Products,
    private readonly inventory: Inventory,
    private readonly orders: Orders,
    private readonly idempotency: IdempotencyStore,
    private readonly ids: IdGenerator,
    private readonly clock: Clock,
    private readonly unitOfWork: UnitOfWork,
  ) {}

  execute(command: CreateOrderCommand): Promise<CreateOrderResult> {
    return this.unitOfWork.run(async () => {
      const actorId = command.actor.id;
      const stored = await this.idempotency.find(actorId, command.idempotencyKey);
      if (stored) {
        if (stored.requestHash !== command.requestHash) {
          throw new IdempotencyKeyReused();
        }
        const previous = await this.orders.find(stored.body);
        if (!previous) throw new Error(`idempotency key points to a missing order ${stored.body}`);
        return { order: previous, replayed: true };
      }

      // Catálogo primero (404), inventario después (409): un SKU inexistente no deja reservas.
      const lines: OrderLine[] = [];
      for (const line of command.lines) {
        const product = await this.products.find(line.sku);
        if (!product) throw new NotFound("PRODUCT", line.sku);
        lines.push(new OrderLine(product.sku, product.name, line.quantity, product.unitPrice));
      }

      const order = Order.place(this.ids.next(), actorId, lines, this.clock.now());
      await this.orders.save(order);                       // primero el pedido: las reservas lo referencian
      await this.inventory.reserve(order.id, lines);       // lanza InsufficientInventory → rollback de todo
      await this.idempotency.save(actorId, command.idempotencyKey, command.requestHash, 201, order.id);
      return { order, replayed: false };
    });
  }
}
