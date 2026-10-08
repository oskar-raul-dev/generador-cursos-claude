import { OrderNotPayable } from "../../domain/errors.js";
import type { Order } from "../../domain/order.js";
import type { Payment } from "../../domain/payment.js";
import type { Actor } from "../actor.js";
import { IdempotencyKeyReused, NotFound } from "../errors.js";
import type { IdempotencyStore, Orders, PaymentGateway, Payments, UnitOfWork } from "../ports.js";

export type AuthorizePaymentResult = { order: Order; payment: Payment; replayed: boolean };

// La llamada al proveedor queda FUERA de la transacción: una transacción abierta durante una
// llamada remota bloquea filas mientras espera a un tercero. Dos unidades de trabajo.
export class AuthorizePayment {
  constructor(
    private readonly orders: Orders,
    private readonly payments: Payments,
    private readonly gateway: PaymentGateway,
    private readonly idempotency: IdempotencyStore,
    private readonly unitOfWork: UnitOfWork,
  ) {}

  async execute(actor: Actor, orderId: string, idempotencyKey: string): Promise<AuthorizePaymentResult> {
    const requestHash = `payment:${orderId}`;

    // 1. Comprobar: repetición, existencia, visibilidad y estado pagable.
    const order = await this.unitOfWork.run(async () => {
      const stored = await this.idempotency.find(actor.id, idempotencyKey);
      if (stored) {
        if (stored.requestHash !== requestHash) throw new IdempotencyKeyReused();
        return null; // repetición: se resuelve abajo
      }
      const found = await this.load(actor, orderId);
      if (!found.isPayable()) throw new OrderNotPayable(found.status);
      return found;
    });
    if (!order) {
      const previous = await this.load(actor, orderId);
      return { order: previous, payment: previous.payment!, replayed: true };
    }

    // 2. Proveedor, sin transacción abierta. La clave del intento es la del cliente y no se regenera.
    const payment = await this.gateway.authorize(idempotencyKey, order.total);

    // 3. Aplicar el resultado y guardar la clave con el efecto.
    return this.unitOfWork.run(async () => {
      const current = await this.load(actor, orderId);
      current.applyPayment(payment);
      await this.orders.save(current);
      await this.payments.record(current.id, payment, current.total);
      await this.idempotency.save(actor.id, idempotencyKey, requestHash, 200, current.id);
      return { order: current, payment, replayed: false };
    });
  }

  private async load(actor: Actor, orderId: string): Promise<Order> {
    const order = await this.orders.find(orderId);
    if (!order || !actor.canSee(order)) throw new NotFound("ORDER", orderId);
    return order;
  }
}
