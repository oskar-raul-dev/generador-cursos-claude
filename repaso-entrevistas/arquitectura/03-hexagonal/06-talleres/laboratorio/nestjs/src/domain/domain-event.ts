// Hechos del dominio con identidad propia desde que nacen: la outbox y el consumidor deduplican
// por eventId, y nunca se regenera por intento.
export type DomainEvent = OrderCancelled;

export class OrderCancelled {
  readonly type = "ORDER_CANCELLED" as const;

  constructor(
    readonly eventId: string,
    readonly orderId: string,
    readonly customerId: string,
    readonly occurredAt: Date,
  ) {}
}
