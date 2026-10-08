import { describe, expect, it } from "vitest";
import { InsufficientInventory } from "../../domain/errors.js";
import { Money } from "../../domain/money.js";
import type { Order } from "../../domain/order.js";
import type { OrderLine } from "../../domain/order-line.js";
import { Product } from "../../domain/product.js";
import { Actor } from "../actor.js";
import { IdempotencyKeyReused } from "../errors.js";
import type { Page, PageRequest } from "../page.js";
import type { IdempotencyStore, Inventory, Orders, Products, StoredResponse, UnitOfWork } from "../ports.js";
import { CreateOrder } from "./create-order.js";

// El caso de uso con dobles fieles a los puertos, y una unidad de trabajo de pruebas que restaura
// los fakes si el trabajo lanza: es lo que la transacción real hace, reducido a lo observable.
const ANA = new Actor("11111111-1111-4111-8111-111111111111", "ana@hex.local", "CUSTOMER");

class InMemoryProducts implements Products {
  readonly data = new Map<string, Product>();
  async find(sku: string) { return this.data.get(sku) ?? null; }
  async exists(sku: string) { return this.data.has(sku); }
  async list(_: PageRequest): Promise<Page<Product>> { return { items: [...this.data.values()], nextCursor: null }; }
  async save(p: Product) { this.data.set(p.sku, p); }
}

class InMemoryInventory implements Inventory {
  readonly available = new Map<string, number>();
  async availableFor(skus: string[]) { return new Map(skus.map((s) => [s, this.available.get(s) ?? 0])); }
  async initialize(sku: string, q: number) { this.available.set(sku, q); }
  async reserve(_: string, lines: OrderLine[]) {
    // como el adaptador real: descuenta línea a línea y lanza al primer faltante
    for (const [i, l] of lines.entries()) {
      const have = this.available.get(l.sku) ?? 0;
      if (have < l.quantity) throw new InsufficientInventory(l.sku, l.quantity, have, i);
      this.available.set(l.sku, have - l.quantity);
    }
  }
  async release() {}
}

class InMemoryOrders implements Orders {
  readonly data = new Map<string, Order>();
  async find(id: string) { return this.data.get(id) ?? null; }
  async save(o: Order) { this.data.set(o.id, o); }
  async list(): Promise<Page<Order>> { return { items: [...this.data.values()], nextCursor: null }; }
}

class InMemoryIdempotency implements IdempotencyStore {
  readonly data = new Map<string, StoredResponse>();
  async find(actorId: string, key: string) { return this.data.get(`${actorId}:${key}`) ?? null; }
  async save(actorId: string, key: string, requestHash: string, status: number, body: string) {
    this.data.set(`${actorId}:${key}`, { requestHash, status, body });
  }
}

class SnapshotUnitOfWork implements UnitOfWork {
  constructor(private readonly o: InMemoryOrders, private readonly i: InMemoryInventory, private readonly k: InMemoryIdempotency) {}
  async run<T>(work: () => Promise<T>): Promise<T> {
    const [o, i, k] = [new Map(this.o.data), new Map(this.i.available), new Map(this.k.data)];
    try {
      return await work();
    } catch (e) {
      this.o.data.clear(); o.forEach((v, key) => this.o.data.set(key, v));
      this.i.available.clear(); i.forEach((v, key) => this.i.available.set(key, v));
      this.k.data.clear(); k.forEach((v, key) => this.k.data.set(key, v));
      throw e;
    }
  }
}

function setup() {
  const products = new InMemoryProducts();
  const inventory = new InMemoryInventory();
  const orders = new InMemoryOrders();
  const idempotency = new InMemoryIdempotency();
  let n = 0;
  const createOrder = new CreateOrder(products, inventory, orders, idempotency,
    { next: () => `order-${++n}` }, { now: () => new Date("2026-09-27T12:00:00Z") },
    new SnapshotUnitOfWork(orders, inventory, idempotency));
  products.data.set("SKU-001", new Product("SKU-001", "Mechanical keyboard", Money.usd("49.90")));
  products.data.set("SKU-004", new Product("SKU-004", "Webcam", Money.usd("59.00")));
  inventory.available.set("SKU-001", 20);
  inventory.available.set("SKU-004", 0);
  return { products, inventory, orders, idempotency, createOrder };
}

const command = (key: string, lines: { sku: string; quantity: number }[]) => ({
  actor: ANA, idempotencyKey: key, requestHash: lines.map((l) => `${l.sku}:${l.quantity}`).join(","), lines,
});

describe("CreateOrder", () => {
  it("reserves stock and remembers the key", async () => {
    const { createOrder, inventory, orders } = setup();
    const result = await createOrder.execute(command("key-0001", [{ sku: "SKU-001", quantity: 2 }]));
    expect(result.replayed).toBe(false);
    expect(result.order.total.amountAsText()).toBe("99.80");
    expect(inventory.available.get("SKU-001")).toBe(18);
    expect(orders.data.has(result.order.id)).toBe(true);
  });

  it("same key, same body: replays without reserving again", async () => {
    const { createOrder, inventory } = setup();
    const first = await createOrder.execute(command("key-0002", [{ sku: "SKU-001", quantity: 2 }]));
    const again = await createOrder.execute(command("key-0002", [{ sku: "SKU-001", quantity: 2 }]));
    expect(again.replayed).toBe(true);
    expect(again.order.id).toBe(first.order.id);
    expect(inventory.available.get("SKU-001")).toBe(18);
  });

  it("same key, different body: rejected", async () => {
    const { createOrder } = setup();
    await createOrder.execute(command("key-0003", [{ sku: "SKU-001", quantity: 1 }]));
    await expect(createOrder.execute(command("key-0003", [{ sku: "SKU-001", quantity: 3 }]))).rejects.toThrow(IdempotencyKeyReused);
  });

  it("insufficient inventory leaves nothing behind (the unit of work reverts)", async () => {
    const { createOrder, inventory, orders, idempotency } = setup();
    await expect(createOrder.execute(command("key-0004", [{ sku: "SKU-001", quantity: 1 }, { sku: "SKU-004", quantity: 1 }])))
      .rejects.toThrow(InsufficientInventory);
    expect(inventory.available.get("SKU-001")).toBe(20);
    expect(orders.data.size).toBe(0);
    expect(idempotency.data.size).toBe(0);
  });
});
