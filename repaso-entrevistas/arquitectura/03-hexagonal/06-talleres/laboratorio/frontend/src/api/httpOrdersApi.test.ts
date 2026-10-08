import { setupServer } from "msw/node";
import { afterAll, afterEach, beforeAll, beforeEach, describe, expect, it } from "vitest";
import { handlers, resetMockState } from "../mock/handlers";
import { HttpOrdersApi } from "./httpOrdersApi";
import { ApiError } from "./ordersApi";

// Prueba del adaptador HTTP contra los mismos handlers que usa el navegador en modo mock.
// Lo que se verifica es la traducción: rutas, cabeceras, problem+json → ApiError, replay idempotente.
// La lógica de negocio del mock está aquí solo como contraparte; no es lo que se prueba.

const server = setupServer(...handlers);
const BASE = "http://hex.test";

beforeAll(() => server.listen({ onUnhandledRequest: "error" }));
beforeEach(() => resetMockState());
afterEach(() => server.resetHandlers());
afterAll(() => server.close());

async function expectApiError(promise: Promise<unknown>, status: number, code: string): Promise<ApiError> {
  try {
    await promise;
  } catch (e) {
    expect(e).toBeInstanceOf(ApiError);
    const err = e as ApiError;
    expect(err.status).toBe(status);
    expect(err.problem.code).toBe(code);
    return err;
  }
  throw new Error(`esperaba ApiError ${status} ${code}`);
}

describe("autenticación", () => {
  it("login devuelve un bearer y lo usa en las siguientes peticiones", async () => {
    const api = new HttpOrdersApi(BASE);
    const token = await api.login("ana@hex.local", "ana-12345");
    expect(token.tokenType).toBe("Bearer");
    expect(token.expiresIn).toBe(900);
    const page = await api.listProducts();
    expect(page.items.map((p) => p.sku)).toEqual(["SKU-001", "SKU-002", "SKU-003", "SKU-004", "SKU-005"]);
  });

  it("credenciales inválidas → ApiError 401 INVALID_CREDENTIALS", async () => {
    const api = new HttpOrdersApi(BASE);
    await expectApiError(api.login("ana@hex.local", "nope-nope"), 401, "INVALID_CREDENTIALS");
  });

  it("sin token → UNAUTHENTICATED; tras logout → TOKEN_REVOKED", async () => {
    const api = new HttpOrdersApi(BASE);
    await expectApiError(api.listProducts(), 401, "UNAUTHENTICATED");
    await api.login("ana@hex.local", "ana-12345");
    await api.logout();
    // el adaptador olvidó el token al hacer logout; la siguiente petición va sin Authorization
    await expectApiError(api.listProducts(), 401, "UNAUTHENTICATED");
  });
});

describe("pedidos", () => {
  it("crea un pedido, descuenta stock y repite idempotentemente con la misma clave", async () => {
    const api = new HttpOrdersApi(BASE);
    await api.login("ana@hex.local", "ana-12345");
    const key = "test-order-0001";
    const first = await api.createOrder([{ sku: "SKU-001", quantity: 2 }, { sku: "SKU-002", quantity: 1 }], key);
    expect(first.replayed).toBe(false);
    expect(first.order.status).toBe("CONFIRMED");
    expect(first.order.total).toEqual({ amount: "109.70", currency: "USD" });
    expect((await api.getProduct("SKU-001")).stock).toBe(18);

    const again = await api.createOrder([{ sku: "SKU-001", quantity: 2 }, { sku: "SKU-002", quantity: 1 }], key);
    expect(again.replayed).toBe(true);
    expect(again.order.id).toBe(first.order.id);
    expect((await api.getProduct("SKU-001")).stock).toBe(18);
  });

  it("misma clave con otro cuerpo → 422 IDEMPOTENCY_KEY_REUSED", async () => {
    const api = new HttpOrdersApi(BASE);
    await api.login("ana@hex.local", "ana-12345");
    await api.createOrder([{ sku: "SKU-001", quantity: 1 }], "test-order-0002");
    await expectApiError(api.createOrder([{ sku: "SKU-001", quantity: 3 }], "test-order-0002"), 422, "IDEMPOTENCY_KEY_REUSED");
  });

  it("inventario insuficiente → 409 con detalle y errors; no reserva nada", async () => {
    const api = new HttpOrdersApi(BASE);
    await api.login("ana@hex.local", "ana-12345");
    const err = await expectApiError(
      api.createOrder([{ sku: "SKU-001", quantity: 1 }, { sku: "SKU-004", quantity: 1 }], "test-order-0003"),
      409, "INSUFFICIENT_INVENTORY");
    expect(err.problem.detail).toContain("SKU-004");
    expect(err.problem.errors?.[0]?.field).toBe("lines[1].quantity");
    expect((await api.getProduct("SKU-001")).stock).toBe(20);
  });

  it("el pedido de otro cliente responde 404, no 403", async () => {
    const ana = new HttpOrdersApi(BASE);
    await ana.login("ana@hex.local", "ana-12345");
    const { order } = await ana.createOrder([{ sku: "SKU-002", quantity: 1 }], "test-order-0004");
    const ops = new HttpOrdersApi(BASE);
    await ops.login("ops@hex.local", "ops-12345");
    expect((await ops.getOrder(order.id)).id).toBe(order.id); // operator ve todo
    await expectApiError(ana.getOrder("00000000-0000-4000-8000-ffffffffffff"), 404, "ORDER_NOT_FOUND");
  });
});

describe("pagos y cancelación", () => {
  it("autorizado, rechazado y pendiente según el importe", async () => {
    const api = new HttpOrdersApi(BASE);
    await api.login("ana@hex.local", "ana-12345");
    const cheap = (await api.createOrder([{ sku: "SKU-002", quantity: 1 }], "test-pay-cheap")).order;
    const paid = await api.authorizePayment(cheap.id, "test-pay-cheap-1");
    expect(paid.payment.status).toBe("AUTHORIZED");
    expect(paid.orderStatus).toBe("PAID");
    await expectApiError(api.authorizePayment(cheap.id, "test-pay-cheap-2"), 409, "ORDER_NOT_PAYABLE");

    const expensive = (await api.createOrder([{ sku: "SKU-005", quantity: 1 }], "test-pay-exp")).order;
    expect((await api.authorizePayment(expensive.id, "test-pay-exp-1")).orderStatus).toBe("PAYMENT_REJECTED");

    const uncertain = (await api.createOrder([{ sku: "SKU-003", quantity: 3 }], "test-pay-unc")).order;
    expect(uncertain.total.amount).toBe("666.00");
    expect((await api.authorizePayment(uncertain.id, "test-pay-unc-1")).orderStatus).toBe("PAYMENT_PENDING");
    await expectApiError(api.authorizePayment(uncertain.id, "test-pay-unc-2"), 409, "ORDER_NOT_PAYABLE");
  });

  it("cancelar libera stock, es idempotente y no aplica a un pedido pagado", async () => {
    const api = new HttpOrdersApi(BASE);
    await api.login("ana@hex.local", "ana-12345");
    const order = (await api.createOrder([{ sku: "SKU-001", quantity: 2 }], "test-cancel-1")).order;
    expect((await api.getProduct("SKU-001")).stock).toBe(18);
    expect((await api.cancelOrder(order.id)).status).toBe("CANCELLED");
    expect((await api.getProduct("SKU-001")).stock).toBe(20);
    expect((await api.cancelOrder(order.id)).status).toBe("CANCELLED");
    expect((await api.getProduct("SKU-001")).stock).toBe(20);

    const paid = (await api.createOrder([{ sku: "SKU-002", quantity: 1 }], "test-cancel-2")).order;
    await api.authorizePayment(paid.id, "test-cancel-2-pay");
    await expectApiError(api.cancelOrder(paid.id), 409, "ORDER_NOT_CANCELLABLE");
  });

  it("la cancelación deja una notificación que solo el operator lee", async () => {
    const ana = new HttpOrdersApi(BASE);
    await ana.login("ana@hex.local", "ana-12345");
    const order = (await ana.createOrder([{ sku: "SKU-002", quantity: 1 }], "test-notify-1")).order;
    await ana.cancelOrder(order.id);
    await expectApiError(ana.listNotifications(), 403, "FORBIDDEN");

    const ops = new HttpOrdersApi(BASE);
    await ops.login("ops@hex.local", "ops-12345");
    const page = await ops.listNotifications(order.id);
    expect(page.items).toHaveLength(1);
    expect(page.items[0]).toMatchObject({ orderId: order.id, type: "ORDER_CANCELLED", recipient: "ana@hex.local" });
  });
});
