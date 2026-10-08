import type { Order } from "../../domain/order.js";
import type { Actor } from "../actor.js";
import { NotFound } from "../errors.js";
import type { Orders } from "../ports.js";

// Un customer solo ve lo suyo; lo ajeno responde "no existe".
export class GetOrder {
  constructor(private readonly orders: Orders) {}

  async execute(actor: Actor, orderId: string): Promise<Order> {
    const order = await this.orders.find(orderId);
    if (!order || !actor.canSee(order)) {
      throw new NotFound("ORDER", orderId);
    }
    return order;
  }
}
