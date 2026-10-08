import type { Actor } from "../actor.js";
import type { Page, PageRequest } from "../page.js";
import type { Notification, Notifications } from "../ports.js";

// Parte 2. Solo operator: una ventana operativa a lo que entregó el Notifier.
export class ListNotifications {
  constructor(private readonly notifications: Notifications) {}

  execute(actor: Actor, orderId: string | null, page: PageRequest): Promise<Page<Notification>> {
    actor.requireOperator();
    return this.notifications.list(orderId, page);
  }
}
