import type { Money, Notification, Order, OrderStatus, Payment, Problem, ProblemCode } from "../api/types";

// Estado en memoria del mock: la misma semilla que §11 de la guía y seed.sql.
// Es un backend de juguete sin arquitectura, a propósito: sirve para que la UI y las pruebas del
// adaptador funcionen sin Docker, y para sentir cuánto de la suite es negocio (ejercicio 8 de 06/01).

export type MockUser = { id: string; email: string; password: string; role: "customer" | "operator" };
type CatalogItem = { sku: string; name: string; unitPrice: Money };
type Session = { userId: string; jti: string; revoked: boolean };
type IdempotentResponse = { requestHash: string; status: number; body: unknown };

export type MockState = {
  users: MockUser[];
  catalog: Map<string, CatalogItem>;
  inventory: Map<string, number>;
  orders: Map<string, Order>;
  sessions: Map<string, Session>;
  idempotency: Map<string, IdempotentResponse>;
  notifications: Notification[];
  counter: number;
};

export const USERS: MockUser[] = [
  { id: "11111111-1111-4111-8111-111111111111", email: "ana@hex.local", password: "ana-12345", role: "customer" },
  { id: "22222222-2222-4222-8222-222222222222", email: "ops@hex.local", password: "ops-12345", role: "operator" },
];

const SEED_CATALOG: CatalogItem[] = [
  { sku: "SKU-001", name: "Mechanical keyboard", unitPrice: { amount: "49.90", currency: "USD" } },
  { sku: "SKU-002", name: "USB-C cable", unitPrice: { amount: "9.90", currency: "USD" } },
  { sku: "SKU-003", name: '27" monitor', unitPrice: { amount: "222.00", currency: "USD" } },
  { sku: "SKU-004", name: "Webcam", unitPrice: { amount: "59.00", currency: "USD" } },
  { sku: "SKU-005", name: "Workstation", unitPrice: { amount: "1499.00", currency: "USD" } },
];
const SEED_INVENTORY: [string, number][] = [
  ["SKU-001", 20], ["SKU-002", 100], ["SKU-003", 5], ["SKU-004", 0], ["SKU-005", 3],
];

export function createState(): MockState {
  return {
    users: USERS,
    catalog: new Map(SEED_CATALOG.map((p) => [p.sku, { ...p }])),
    inventory: new Map(SEED_INVENTORY),
    orders: new Map(),
    sessions: new Map(),
    idempotency: new Map(),
    notifications: [],
    counter: 0,
  };
}

// ------------------------------------------------------------------ utilidades de dominio de juguete

// Dinero en centavos enteros: el mock también evita el double.
export function toCents(amount: string): number {
  const [whole = "0", frac = "00"] = amount.split(".");
  return Number(whole) * 100 + Number(frac.padEnd(2, "0"));
}
export function money(cents: number, currency = "USD"): Money {
  return { amount: `${Math.floor(cents / 100)}.${String(cents % 100).padStart(2, "0")}`, currency };
}

// La regla determinista del PaymentGateway (§11 de la guía)
export function decidePayment(totalCents: number): Payment["status"] {
  if (totalCents > 100_000) return "REJECTED";
  if (totalCents === 66_600) return "PENDING";
  return "AUTHORIZED";
}

export const PAYABLE: OrderStatus[] = ["CONFIRMED", "PAYMENT_REJECTED"];
export const CANCELLABLE: OrderStatus[] = ["CONFIRMED", "PAYMENT_REJECTED", "PAYMENT_PENDING"];

export function problem(
  status: number,
  code: ProblemCode,
  title: string,
  detail?: string,
  errors?: Problem["errors"],
): Problem {
  return { type: "about:blank", title, status, code, ...(detail ? { detail } : {}), ...(errors ? { errors } : {}) };
}

export function uuid(state: MockState): string {
  // Determinista y con forma de UUID v4: la UI y las pruebas solo necesitan que sea único.
  const n = (++state.counter).toString(16).padStart(12, "0");
  return `00000000-0000-4000-8000-${n}`;
}
