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

// El puerto del frontend: lo que la UI necesita del sistema, en vocabulario del contrato.
// La UI depende de esta interfaz; las dos implementaciones (fetch real y mock MSW) dependen de ella.
export interface OrdersApi {
  login(email: string, password: string): Promise<TokenResponse>;
  logout(): Promise<void>;
  listProducts(cursor?: string): Promise<Page<Product>>;
  getProduct(sku: string): Promise<Product>;
  createOrder(lines: OrderLineRequest[], idempotencyKey: string): Promise<CreateOrderResult>;
  getOrder(orderId: string): Promise<Order>;
  listOrders(): Promise<Page<Order>>;
  authorizePayment(orderId: string, idempotencyKey: string): Promise<PaymentResponse>;
  cancelOrder(orderId: string): Promise<Order>;
  listNotifications(orderId?: string): Promise<Page<Notification>>;
}

// Un pedido creado o repetido: la UI distingue "creado" de "ya existía" solo para informar.
export type CreateOrderResult = { order: Order; replayed: boolean };

// Error de la API con el problem+json completo; la UI decide por `problem.code`, nunca por el texto.
export class ApiError extends Error {
  constructor(
    public readonly status: number,
    public readonly problem: Problem,
  ) {
    super(`${problem.code}: ${problem.detail ?? problem.title}`);
    this.name = "ApiError";
  }
}
