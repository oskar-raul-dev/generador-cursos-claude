// Cliente de la API del legado, escrito como se escribe un cliente limpio: confía en el código de
// estado HTTP y en la forma que devolvió la última vez. Es justo lo que el legado castiga (taller 02).

export type Product = { sku: string; name: string; price: number; stock: number };
export type OrderLine = { sku: string; productName: string; quantity: number; unitPrice: number };
export type Order = { id: string; status: string; total: number; lines: OrderLine[] };

export class ApiError extends Error {
  status: number;
  constructor(status: number, message: string) {
    super(message);
    this.status = status;
  }
}

let base = "";
let token = "";

export function configure(options: { baseUrl?: string }) {
  base = options.baseUrl ?? "";
}

async function call<T>(method: string, path: string, body?: unknown): Promise<T> {
  const res = await fetch(base + path, {
    method,
    headers: {
      Accept: "application/json",
      ...(body !== undefined ? { "Content-Type": "application/json" } : {}),
      ...(token ? { Authorization: `Bearer ${token}` } : {}),
    },
    body: body !== undefined ? JSON.stringify(body) : undefined,
  });
  if (!res.ok) {
    const data = await res.json().catch(() => ({}));
    // lo que el servidor diga que pasó: message, o el texto de estado
    throw new ApiError(res.status, data.message ?? res.statusText);
  }
  return res.json() as Promise<T>;
}

export async function login(email: string, password: string): Promise<void> {
  const data = await call<{ accessToken: string }>("POST", "/api/v1/auth/login", { email, password });
  token = data.accessToken;
}

export const listProducts = () => call<Product[]>("GET", "/api/v1/products");
export const listOrders = () => call<Order[]>("GET", "/api/v1/orders");
export const getOrder = (id: string) => call<Order>("GET", `/api/v1/orders/${id}`);
export const createOrder = (sku: string, quantity: number) =>
  call<Order>("POST", "/api/v1/orders", { lines: [{ sku, quantity }] });
