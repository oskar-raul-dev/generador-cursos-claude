import { ApiError, type CreateOrderResult, type OrdersApi } from "./ordersApi";
import type {
  Notification,
  Order,
  OrderLineRequest,
  Page,
  PaymentResponse,
  Problem,
  Product,
  TokenResponse,
} from "./types";

// Adaptador HTTP del puerto OrdersApi. Conoce rutas, cabeceras, códigos y problem+json; la UI no.
// En modo mock, MSW intercepta el mismo `fetch`: este archivo no cambia.
export class HttpOrdersApi implements OrdersApi {
  private token: string | null = null;

  constructor(
    private readonly baseUrl: string,
    private readonly fetchImpl: typeof fetch = (...args) => fetch(...args),
  ) {}

  async login(email: string, password: string): Promise<TokenResponse> {
    const body = await this.request<TokenResponse>("POST", "/api/v1/auth/login", {
      json: { email, password },
      auth: false,
    });
    this.token = body.accessToken;
    return body;
  }

  async logout(): Promise<void> {
    await this.request<void>("POST", "/api/v1/auth/logout");
    this.token = null;
  }

  listProducts(cursor?: string): Promise<Page<Product>> {
    const query = cursor ? `?cursor=${encodeURIComponent(cursor)}` : "";
    return this.request("GET", `/api/v1/products${query}`);
  }

  getProduct(sku: string): Promise<Product> {
    return this.request("GET", `/api/v1/products/${encodeURIComponent(sku)}`);
  }

  async createOrder(lines: OrderLineRequest[], idempotencyKey: string): Promise<CreateOrderResult> {
    const { body, response } = await this.requestRaw<Order>("POST", "/api/v1/orders", {
      json: { lines },
      headers: { "Idempotency-Key": idempotencyKey },
    });
    // 201 crea; 200 con Idempotent-Replay es la misma creación devuelta otra vez
    return { order: body, replayed: response.headers.get("Idempotent-Replay") === "true" };
  }

  getOrder(orderId: string): Promise<Order> {
    return this.request("GET", `/api/v1/orders/${orderId}`);
  }

  listOrders(): Promise<Page<Order>> {
    return this.request("GET", "/api/v1/orders");
  }

  authorizePayment(orderId: string, idempotencyKey: string): Promise<PaymentResponse> {
    return this.request("POST", `/api/v1/orders/${orderId}/payment`, {
      headers: { "Idempotency-Key": idempotencyKey },
    });
  }

  cancelOrder(orderId: string): Promise<Order> {
    return this.request("POST", `/api/v1/orders/${orderId}/cancel`);
  }

  listNotifications(orderId?: string): Promise<Page<Notification>> {
    const query = orderId ? `?orderId=${encodeURIComponent(orderId)}` : "";
    return this.request("GET", `/api/v1/notifications${query}`);
  }

  // ------------------------------------------------------------------ transporte

  private async request<T>(method: string, path: string, options: RequestOptions = {}): Promise<T> {
    const { body } = await this.requestRaw<T>(method, path, options);
    return body;
  }

  private async requestRaw<T>(
    method: string,
    path: string,
    options: RequestOptions = {},
  ): Promise<{ body: T; response: Response }> {
    const headers: Record<string, string> = { Accept: "application/json", ...options.headers };
    if (options.json !== undefined) headers["Content-Type"] = "application/json";
    if (options.auth !== false && this.token) headers.Authorization = `Bearer ${this.token}`;

    const response = await this.fetchImpl(this.baseUrl + path, {
      method,
      headers,
      body: options.json === undefined ? undefined : JSON.stringify(options.json),
    });

    if (!response.ok) {
      // Todo error viene como problem+json; si no, se fabrica uno para que la UI tenga `code`
      const problem = await this.readProblem(response);
      if (problem.code === "TOKEN_REVOKED" || problem.code === "UNAUTHENTICATED") this.token = null;
      throw new ApiError(response.status, problem);
    }
    if (response.status === 204) return { body: undefined as T, response };
    return { body: (await response.json()) as T, response };
  }

  private async readProblem(response: Response): Promise<Problem> {
    try {
      const problem = (await response.json()) as Partial<Problem>;
      if (problem && typeof problem.code === "string") return problem as Problem;
    } catch {
      // cuerpo vacío o no JSON: se cae al problema genérico de abajo
    }
    return { title: response.statusText || "Error", status: response.status, code: "INTERNAL_ERROR" };
  }
}

type RequestOptions = {
  json?: unknown;
  headers?: Record<string, string>;
  auth?: boolean;
};
