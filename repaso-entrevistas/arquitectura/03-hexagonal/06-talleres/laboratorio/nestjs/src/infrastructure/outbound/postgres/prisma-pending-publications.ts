import { Injectable } from "@nestjs/common";
import type { PendingPublications } from "../../../application/ports.js";
import { type DomainEvent, OrderCancelled } from "../../../domain/domain-event.js";
import { PrismaService } from "./prisma.service.js";

// La outbox en PostgreSQL. `add` corre dentro de la transacción del caso de uso; `nextBatch` y
// `markPublished` desde la ronda del dispatcher.
@Injectable()
export class PrismaPendingPublications implements PendingPublications {
  constructor(private readonly prisma: PrismaService) {}

  async add(event: DomainEvent): Promise<void> {
    await this.prisma.db.outbox.create({
      data: {
        id: event.eventId, aggregate_type: "Order", aggregate_id: event.orderId, event_type: event.type,
        payload: { orderId: event.orderId, customerId: event.customerId }, occurred_at: event.occurredAt, attempts: 0,
      },
    });
  }

  async nextBatch(size: number): Promise<DomainEvent[]> {
    const rows = await this.prisma.db.outbox.findMany({ where: { published_at: null }, orderBy: { occurred_at: "asc" }, take: size });
    if (rows.length > 0) {
      await this.prisma.db.outbox.updateMany({ where: { id: { in: rows.map((r) => r.id) } }, data: { attempts: { increment: 1 } } });
    }
    return rows.map((r) => {
      const payload = r.payload as { customerId: string };
      return new OrderCancelled(r.id, r.aggregate_id, payload.customerId, r.occurred_at);
    });
  }

  async markPublished(eventId: string): Promise<void> {
    await this.prisma.db.outbox.update({ where: { id: eventId }, data: { published_at: new Date() } });
  }
}
