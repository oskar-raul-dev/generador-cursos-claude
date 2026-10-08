import { DomainEvent, OrderCancelled } from "./domain-event.js";
import { EmptyOrder, OrderNotCancellable, OrderNotPayable } from "./errors.js";
import { Money } from "./money.js";
import { OrderLine } from "./order-line.js";
import { Payment } from "./payment.js";

export type OrderStatus = "CONFIRMED" | "PAID" | "PAYMENT_REJECTED" | "PAYMENT_PENDING" | "CANCELLED";

// El agregado: protege que haya líneas y que las transiciones sean las del contrato. No sabe de
// HTTP, Prisma ni del proveedor de pagos.
export class Order {
  private events: DomainEvent[] = [];

  private constructor(
    readonly id: string,
    readonly customerId: string,
    readonly lines: readonly OrderLine[],
    readonly total: Money,
    readonly createdAt: Date,
    private _status: OrderStatus,
    private _payment: Payment | null,
    readonly version: number,
  ) {}

  static place(id: string, customerId: string, lines: OrderLine[], now: Date): Order {
    if (lines.length === 0) {
      throw new EmptyOrder();
    }
    const total = lines.map((l) => l.lineTotal()).reduce((a, b) => a.plus(b));
    return new Order(id, customerId, [...lines], total, now, "CONFIRMED", null, 0);
  }

  static reconstitute(
    id: string, customerId: string, lines: OrderLine[], total: Money, createdAt: Date,
    status: OrderStatus, payment: Payment | null, version: number,
  ): Order {
    return new Order(id, customerId, [...lines], total, createdAt, status, payment, version);
  }

  get status(): OrderStatus {
    return this._status;
  }

  get payment(): Payment | null {
    return this._payment;
  }

  isPayable(): boolean {
    return this._status === "CONFIRMED" || this._status === "PAYMENT_REJECTED";
  }

  isCancellable(): boolean {
    return this._status === "CONFIRMED" || this._status === "PAYMENT_REJECTED" || this._status === "PAYMENT_PENDING";
  }

  // PENDING no es un rechazo: el pedido queda a la espera y no vuelve a ser pagable.
  applyPayment(result: Payment): void {
    if (!this.isPayable()) {
      throw new OrderNotPayable(this._status);
    }
    this._payment = result;
    this._status = result.status === "AUTHORIZED" ? "PAID" : result.status === "REJECTED" ? "PAYMENT_REJECTED" : "PAYMENT_PENDING";
  }

  // Idempotente: la segunda vez no cambia nada ni emite el hecho. Devuelve true si hubo transición.
  cancel(now: Date, eventId: string): boolean {
    if (this._status === "CANCELLED") {
      return false;
    }
    if (!this.isCancellable()) {
      throw new OrderNotCancellable(this._status);
    }
    this._status = "CANCELLED";
    this.events.push(new OrderCancelled(eventId, this.id, this.customerId, now));
    return true;
  }

  pullEvents(): DomainEvent[] {
    const pulled = this.events;
    this.events = [];
    return pulled;
  }
}
