import { Injectable } from "@nestjs/common";
import type { Notifier } from "../../../application/ports.js";
import type { DomainEvent } from "../../../domain/domain-event.js";
import { PrismaService } from "./prisma.service.js";

// El Notifier de las partes 1–3 "entrega" escribiendo una fila. El id de la notificación es el
// del evento: una segunda entrega del mismo hecho no crea una segunda fila.
@Injectable()
export class TableNotifier implements Notifier {
  constructor(private readonly prisma: PrismaService) {}

  async notify(event: DomainEvent, recipient: string): Promise<void> {
    const exists = await this.prisma.db.notifications.count({ where: { id: event.eventId } });
    if (exists > 0) return; // ya entregado
    await this.prisma.db.notifications.create({
      data: {
        id: event.eventId, order_id: event.orderId, type: event.type, recipient,
        payload: { eventId: event.eventId, occurredAt: event.occurredAt.toISOString() }, created_at: new Date(),
      },
    });
  }
}
