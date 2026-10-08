import type { Order } from "../../domain/order.js";
import type { Actor } from "../actor.js";
import { NotFound } from "../errors.js";
import type { Clock, IdGenerator, Inventory, Orders, PendingPublications, UnitOfWork } from "../ports.js";

// Parte 2. El agregado decide si puede; aplicación coordina liberar la reserva y dejar el hecho
// en la outbox, todo en la misma transacción. La entrega ocurre después del commit.
export class CancelOrder {
  constructor(
    private readonly orders: Orders,
    private readonly inventory: Inventory,
    private readonly pending: PendingPublications,
    private readonly ids: IdGenerator,
    private readonly clock: Clock,
    private readonly unitOfWork: UnitOfWork,
  ) {}

  execute(actor: Actor, orderId: string): Promise<Order> {
    return this.unitOfWork.run(async () => {
      const order = await this.orders.find(orderId);
      if (!order || !actor.canSee(order)) throw new NotFound("ORDER", orderId);
      const changed = order.cancel(this.clock.now(), this.ids.next());
      if (changed) {
        await this.inventory.release(order.id);
        await this.orders.save(order);
        for (const event of order.pullEvents()) await this.pending.add(event);
      }
      return order;
    });
  }
}
