import { describe, expect, it } from "vitest";
import { EmptyOrder, OrderNotCancellable, OrderNotPayable } from "./errors.js";
import { Money } from "./money.js";
import { Order } from "./order.js";
import { OrderLine } from "./order-line.js";
import { Payment } from "./payment.js";

// Pruebas del agregado sin Nest, sin base y sin mocks: la máquina de estados del contrato.
const NOW = new Date("2026-09-27T12:00:00Z");
const ANA = "11111111-1111-4111-8111-111111111111";
const order = (amount: string) => Order.place("o-1", ANA, [new OrderLine("SKU-001", "Mechanical keyboard", 1, Money.usd(amount))], NOW);

describe("Order", () => {
  it("rejects an order without lines", () => {
    expect(() => Order.place("o-1", ANA, [], NOW)).toThrow(EmptyOrder);
  });

  it("is CONFIRMED when placed and totals its lines without floating point", () => {
    const o = Order.place("o-1", ANA, [
      new OrderLine("SKU-001", "Mechanical keyboard", 2, Money.usd("49.90")),
      new OrderLine("SKU-002", "USB-C cable", 1, Money.usd("9.90")),
    ], NOW);
    expect(o.status).toBe("CONFIRMED");
    expect(o.total.amountAsText()).toBe("109.70");
  });

  it("authorized → PAID, and PAID is neither payable nor cancellable", () => {
    const o = order("9.90");
    o.applyPayment(new Payment("AUTHORIZED", "op-1", "gw-op-1"));
    expect(o.status).toBe("PAID");
    expect(() => o.applyPayment(new Payment("AUTHORIZED", "op-2", null))).toThrow(OrderNotPayable);
    expect(() => o.cancel(NOW, "e-1")).toThrow(OrderNotCancellable);
  });

  it("rejected stays payable; pending does not but is cancellable", () => {
    const rejected = order("1499.00");
    rejected.applyPayment(new Payment("REJECTED", "op-1", null));
    expect(rejected.isPayable()).toBe(true);
    const pending = order("666.00");
    pending.applyPayment(new Payment("PENDING", "op-2", null));
    expect(pending.isPayable()).toBe(false);
    expect(pending.isCancellable()).toBe(true);
  });

  it("cancel is idempotent and emits the fact once", () => {
    const o = order("9.90");
    expect(o.cancel(NOW, "e-1")).toBe(true);
    expect(o.pullEvents()).toHaveLength(1);
    expect(o.cancel(NOW, "e-2")).toBe(false);
    expect(o.pullEvents()).toHaveLength(0);
    expect(o.status).toBe("CANCELLED");
  });
});
