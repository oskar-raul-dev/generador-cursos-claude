// Cliente de la API del legado. Hasta el taller 03 confiaba en el código de estado y en la forma que
// había visto la última vez; desde el 04 sigue al contrato (contrato/openapi.yaml): páginas con
// `items`, dinero como { amount, currency } y errores en problem+json con un `code` estable.

export type Money = { amount: string; currency: string };
export type Product = { sku: string; name: string; unitPrice: Money; stock: number };
export type OrderLine = { sku: string; name: string; quantity: number; unitPrice: Money; lineTotal: Money };
export type Order = { id: string; status: string; total: Money; lines: OrderLine[] };
export type Page<T> = { items: T[]; nextCursor: string | null };
type Problem = { title?: string; detail?: string; code?: string };

export class ApiError extends Error {
  status: number;
  code: string;
  constructor(status: number, code: string, message: string) {
    super(message);
    this.status = status;
    this.code = code;
  }
}

let base = "";
let token = "";

export function configure(options: { baseUrl?: string }) {
  base = options.baseUrl ?? "";
}

async function call<T>(method: string, path: string, body?: unknown, key?: string): Promise<T> {
  const res = await fetch(base + path, {
    method,
    headers: {
      Accept: "application/json, application/problem+json",
      ...(body !== undefined ? { "Content-Type": "application/json" } : {}),
      ...(token ? { Authorization: `Bearer ${token}` } : {}),
      ...(key ? { "Idempotency-Key": key } : {}),
    },
    body: body !== undefined ? JSON.stringify(body) : undefined,
  });
  if (!res.ok) {
    const problem: Problem = await res.json().catch(() => ({}));
    // el cliente decide por `code`; el texto que ve el usuario es detail, o el título si no hay detalle
    throw new ApiError(res.status, problem.code ?? "UNKNOWN", problem.detail ?? problem.title ?? res.statusText);
  }
  return res.json() as Promise<T>;
}

export async function login(email: string, password: string): Promise<void> {
  const data = await call<{ accessToken: string }>("POST", "/api/v1/auth/login", { email, password });
  token = data.accessToken;
}

export const listProducts = async () => (await call<Page<Product>>("GET", "/api/v1/products?limit=100")).items;
export const listOrders = async () => (await call<Page<Order>>("GET", "/api/v1/orders?limit=100")).items;
export const getOrder = (id: string) => call<Order>("GET", `/api/v1/orders/${id}`);
// taller 07: una clave por intención de compra (un clic), no por petición. Si la red falla y el
// cliente reintenta, reusa la misma clave y el servidor devuelve el pedido ya creado.
export const createOrder = (sku: string, quantity: number, key: string = crypto.randomUUID()) =>
  call<Order>("POST", "/api/v1/orders", { lines: [{ sku, quantity }] }, key);
