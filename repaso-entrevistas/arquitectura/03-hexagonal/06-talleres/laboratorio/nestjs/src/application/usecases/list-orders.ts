import type { Order } from "../../domain/order.js";
import type { Actor } from "../actor.js";
import type { Page, PageRequest } from "../page.js";
import type { Orders } from "../ports.js";

export class ListOrders {
  constructor(private readonly orders: Orders) {}

  execute(actor: Actor, page: PageRequest): Promise<Page<Order>> {
    return this.orders.list(actor.isOperator() ? null : actor.id, page);
  }
}
