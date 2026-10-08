import { HttpResponse, http, type HttpHandler } from "msw";
import type { Order, OrderLine, OrderLineRequest, Problem } from "../api/types";
import {
  CANCELLABLE,
  PAYABLE,
  createState,
  decidePayment,
  money,
  problem,
  toCents,
  uuid,
  type MockState,
  type MockUser,
} from "./state";

// Handlers de MSW para el contrato completo (v1 y v1.1). Se usan en el navegador (modo mock) y en
// las pruebas del adaptador (msw/node). `resetMockState()` devuelve la semilla entre pruebas.

let state: MockState = createState();
export function resetMockState(): void {
  state = createState();
}

const JSON_PROBLEM = { "Content-Type": "application/problem+json" };
function fail(p: Problem) {
  return HttpResponse.json(p, { status: p.status, headers: JSON_PROBLEM });
}

// ------------------------------------------------------------------ autenticación

type Actor = { user: MockUser; jti: string };

function authenticate(request: Request): Actor | Problem {
  const header = request.headers.get("Authorization") ?? "";
  const token = header.startsWith("Bearer ") ? header.slice(7) : "";
  const session = state.sessions.get(token);
  if (!session) return problem(401, "UNAUTHENTICATED", "Unauthenticated");
  if (session.revoked) return problem(401, "TOKEN_REVOKED", "Token revoked");
  const user = state.users.find((u) => u.id === session.userId)!;
  return { user, jti: session.jti };
}
function isProblem(x: unknown): x is Problem {
  return typeof x === "object" && x !== null && "code" in x && "status" in x;
}

// ------------------------------------------------------------------ idempotencia

function idempotencyKey(request: Request): string | null {
  const key = request.headers.get("Idempotency-Key");
  return key && key.length >= 8 ? key : null;
}
function replay(actor: Actor, key: string, requestHash: string) {
  const saved = state.idempotency.get(`${actor.user.id}:${key}`);
  if (!saved) return null;
  if (saved.requestHash !== requestHash) {
    return fail(problem(422, "IDEMPOTENCY_KEY_REUSED", "Idempotency-Key reused with a different payload"));
  }
  return HttpResponse.json(saved.body as Record<string, unknown>, { status: 200, headers: { "Idempotent-Replay": "true" } });
}
function remember(actor: Actor, key: string, requestHash: string, status: number, body: unknown) {
  state.idempotency.set(`${actor.user.id}:${key}`, { requestHash, status, body });
}

// ------------------------------------------------------------------ paginación por cursor opaco

function paginate<T>(items: T[], url: URL): { items: T[]; nextCursor: string | null } {
  const limit = Math.min(Number(url.searchParams.get("limit") ?? 20) || 20, 100);
  const cursor = url.searchParams.get("cursor");
  const start = cursor ? Number(atob(cursor)) : 0;
  const page = items.slice(start, start + limit);
  const next = start + limit < items.length ? btoa(String(start + limit)) : null;
  return { items: page, nextCursor: next };
}

// ------------------------------------------------------------------ handlers

export const handlers: HttpHandler[] = [
  http.get("*/health", () => HttpResponse.json({ status: "UP" })),

  http.post("*/api/v1/auth/login", async ({ request }) => {
    const body = (await request.json().catch(() => null)) as { email?: unknown; password?: unknown } | null;
    if (!body || typeof body.email !== "string" || typeof body.password !== "string" || !body.email.includes("@")) {
      return fail(problem(400, "VALIDATION_FAILED", "Validation failed", undefined, [{ field: "email", message: "must be an email" }]));
    }
    const user = state.users.find((u) => u.email === body.email && u.password === body.password);
    if (!user) return fail(problem(401, "INVALID_CREDENTIALS", "Invalid credentials"));
    const jti = uuid(state);
    const token = `mock.${user.id}.${jti}`;
    state.sessions.set(token, { userId: user.id, jti, revoked: false });
    return HttpResponse.json({ accessToken: token, tokenType: "Bearer", expiresIn: 900 });
  }),

  http.post("*/api/v1/auth/logout", ({ request }) => {
    const actor = authenticate(request);
    if (isProblem(actor)) return fail(actor);
    const token = request.headers.get("Authorization")!.slice(7);
    state.sessions.get(token)!.revoked = true;
    return new HttpResponse(null, { status: 204 });
  }),

  http.get("*/api/v1/products", ({ request }) => {
    const actor = authenticate(request);
    if (isProblem(actor)) return fail(actor);
    const all = [...state.catalog.values()].map((p) => ({ ...p, stock: state.inventory.get(p.sku) ?? 0 }));
    return HttpResponse.json(paginate(all, new URL(request.url)));
  }),

  http.get("*/api/v1/products/:sku", ({ request, params }) => {
    const actor = authenticate(request);
    if (isProblem(actor)) return fail(actor);
    const item = state.catalog.get(String(params.sku));
    if (!item) return fail(problem(404, "PRODUCT_NOT_FOUND", "Product not found", String(params.sku)));
    return HttpResponse.json({ ...item, stock: state.inventory.get(item.sku) ?? 0 });
  }),

  http.post("*/api/v1/products", async ({ request }) => {
    const actor = authenticate(request);
    if (isProblem(actor)) return fail(actor);
    if (actor.user.role !== "operator") return fail(problem(403, "FORBIDDEN", "Forbidden"));
    const body = (await request.json().catch(() => null)) as
      | { sku?: unknown; name?: unknown; unitPrice?: { amount?: unknown; currency?: unknown }; stock?: unknown }
      | null;
    const amount = body?.unitPrice?.amount;
    if (!body || typeof body.sku !== "string" || !/^SKU-\d{3,}$/.test(body.sku) || typeof body.name !== "string"
      || typeof amount !== "string" || !/^\d+\.\d{2}$/.test(amount) || typeof body.stock !== "number" || body.stock < 0) {
      return fail(problem(400, "VALIDATION_FAILED", "Validation failed", undefined, [{ field: "unitPrice.amount", message: "must be a decimal with two digits" }]));
    }
    if (state.catalog.has(body.sku)) return fail(problem(409, "PRODUCT_ALREADY_EXISTS", "Product already exists", `${body.sku} already exists`));
    const created = { sku: body.sku, name: body.name, unitPrice: { amount, currency: "USD" } };
    state.catalog.set(body.sku, created);
    state.inventory.set(body.sku, body.stock);
    return HttpResponse.json({ ...created, stock: body.stock }, { status: 201, headers: { Location: `/api/v1/products/${body.sku}` } });
  }),

  http.get("*/api/v1/orders", ({ request }) => {
    const actor = authenticate(request);
    if (isProblem(actor)) return fail(actor);
    const mine = [...state.orders.values()].filter((o) => actor.user.role === "operator" || o.customerId === actor.user.id);
    return HttpResponse.json(paginate(mine.reverse(), new URL(request.url)));
  }),

  http.post("*/api/v1/orders", async ({ request }) => {
    const actor = authenticate(request);
    if (isProblem(actor)) return fail(actor);
    const key = idempotencyKey(request);
    if (!key) return fail(problem(400, "IDEMPOTENCY_KEY_REQUIRED", "Idempotency-Key required"));
    const raw = await request.text();
    const replayed = replay(actor, key, raw);
    if (replayed) return replayed;

    let body: { lines?: OrderLineRequest[] } | null = null;
    try { body = JSON.parse(raw); } catch { body = null; }
    const lines = body?.lines;
    if (!Array.isArray(lines) || lines.length === 0
      || lines.some((l) => typeof l?.sku !== "string" || !Number.isInteger(l?.quantity) || l.quantity < 1)) {
      return fail(problem(400, "VALIDATION_FAILED", "Validation failed", "lines must contain at least one valid line", [{ field: "lines", message: "must not be empty" }]));
    }
    // catálogo primero (404), inventario después (409): no se reserva nada si una línea falla
    for (const l of lines) {
      if (!state.catalog.has(l.sku)) return fail(problem(404, "PRODUCT_NOT_FOUND", "Product not found", l.sku));
    }
    for (const [i, l] of lines.entries()) {
      const available = state.inventory.get(l.sku) ?? 0;
      if (available < l.quantity) {
        return fail(problem(409, "INSUFFICIENT_INVENTORY", "Insufficient inventory",
          `${l.sku}: requested ${l.quantity}, available ${available}`,
          [{ field: `lines[${i}].quantity`, message: `requested ${l.quantity}, available ${available}` }]));
      }
    }
    const orderLines: OrderLine[] = lines.map((l) => {
      const item = state.catalog.get(l.sku)!;
      state.inventory.set(l.sku, state.inventory.get(l.sku)! - l.quantity);
      return { sku: l.sku, name: item.name, quantity: l.quantity, unitPrice: item.unitPrice,
        lineTotal: money(toCents(item.unitPrice.amount) * l.quantity) };
    });
    const total = money(orderLines.reduce((sum, l) => sum + toCents(l.lineTotal.amount), 0));
    const order: Order = { id: uuid(state), customerId: actor.user.id, status: "CONFIRMED", lines: orderLines, total,
      payment: null, createdAt: new Date().toISOString() };
    state.orders.set(order.id, order);
    remember(actor, key, raw, 201, order);
    return HttpResponse.json(order, { status: 201, headers: { Location: `/api/v1/orders/${order.id}` } });
  }),

  http.get("*/api/v1/orders/:orderId", ({ request, params }) => {
    const actor = authenticate(request);
    if (isProblem(actor)) return fail(actor);
    const found = findOrder(actor, String(params.orderId));
    return isProblem(found) ? fail(found) : HttpResponse.json(found);
  }),

  http.post("*/api/v1/orders/:orderId/payment", ({ request, params }) => {
    const actor = authenticate(request);
    if (isProblem(actor)) return fail(actor);
    const key = idempotencyKey(request);
    if (!key) return fail(problem(400, "IDEMPOTENCY_KEY_REQUIRED", "Idempotency-Key required"));
    const order = findOrder(actor, String(params.orderId));
    if (isProblem(order)) return fail(order);
    const replayed = replay(actor, key, `payment:${order.id}`);
    if (replayed) return replayed;
    if (!PAYABLE.includes(order.status)) return fail(problem(409, "ORDER_NOT_PAYABLE", "Order not payable", `order is ${order.status}`));
    const status = decidePayment(toCents(order.total.amount));
    order.payment = { status, operationId: key, reference: status === "AUTHORIZED" ? `gw-${key}` : null };
    order.status = status === "AUTHORIZED" ? "PAID" : status === "REJECTED" ? "PAYMENT_REJECTED" : "PAYMENT_PENDING";
    const response = { orderId: order.id, orderStatus: order.status, payment: order.payment };
    remember(actor, key, `payment:${order.id}`, 200, response);
    return HttpResponse.json(response);
  }),

  http.post("*/api/v1/orders/:orderId/cancel", ({ request, params }) => {
    const actor = authenticate(request);
    if (isProblem(actor)) return fail(actor);
    const order = findOrder(actor, String(params.orderId));
    if (isProblem(order)) return fail(order);
    if (order.status === "CANCELLED") return HttpResponse.json(order); // idempotente, sin efecto
    if (!CANCELLABLE.includes(order.status)) return fail(problem(409, "ORDER_NOT_CANCELLABLE", "Order not cancellable", `order is ${order.status}`));
    for (const l of order.lines) state.inventory.set(l.sku, (state.inventory.get(l.sku) ?? 0) + l.quantity);
    order.status = "CANCELLED";
    const owner = state.users.find((u) => u.id === order.customerId)!;
    state.notifications.unshift({ id: uuid(state), orderId: order.id, type: "ORDER_CANCELLED", recipient: owner.email, createdAt: new Date().toISOString() });
    return HttpResponse.json(order);
  }),

  http.get("*/api/v1/notifications", ({ request }) => {
    const actor = authenticate(request);
    if (isProblem(actor)) return fail(actor);
    if (actor.user.role !== "operator") return fail(problem(403, "FORBIDDEN", "Forbidden"));
    const url = new URL(request.url);
    const orderId = url.searchParams.get("orderId");
    const all = orderId ? state.notifications.filter((n) => n.orderId === orderId) : state.notifications;
    return HttpResponse.json(paginate(all, url));
  }),
];

// Un customer solo ve lo suyo, y lo ajeno responde 404, como manda el contrato.
function findOrder(actor: Actor, orderId: string): Order | Problem {
  if (!/^[0-9a-f-]{36}$/.test(orderId)) return problem(400, "VALIDATION_FAILED", "Validation failed", "orderId must be a UUID");
  const order = state.orders.get(orderId);
  if (!order || (actor.user.role !== "operator" && order.customerId !== actor.user.id)) {
    return problem(404, "ORDER_NOT_FOUND", "Order not found");
  }
  return order;
}
