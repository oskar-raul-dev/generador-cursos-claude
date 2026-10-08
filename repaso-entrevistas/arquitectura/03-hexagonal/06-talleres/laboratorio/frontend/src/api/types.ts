// Tipos del contrato (laboratorio/contrato/openapi.yaml), escritos a mano y a propósito:
// son la forma pública de la API, no el modelo del frontend. Si el contrato cambia, cambia esto.

export type Money = { amount: string; currency: string };

export type Product = { sku: string; name: string; unitPrice: Money; stock: number };

export type Page<T> = { items: T[]; nextCursor: string | null };

export type OrderStatus = "CONFIRMED" | "PAID" | "PAYMENT_REJECTED" | "PAYMENT_PENDING" | "CANCELLED";

export type PaymentStatus = "AUTHORIZED" | "REJECTED" | "PENDING";

export type Payment = { status: PaymentStatus; operationId: string; reference?: string | null };

export type OrderLine = {
  sku: string;
  name: string;
  quantity: number;
  unitPrice: Money;
  lineTotal: Money;
};

export type Order = {
  id: string;
  customerId: string;
  status: OrderStatus;
  lines: OrderLine[];
  total: Money;
  payment: Payment | null;
  createdAt: string;
};

export type OrderLineRequest = { sku: string; quantity: number };

export type PaymentResponse = { orderId: string; orderStatus: OrderStatus; payment: Payment };

export type Notification = {
  id: string;
  orderId: string;
  type: "ORDER_CANCELLED";
  recipient: string;
  createdAt: string;
};

export type TokenResponse = { accessToken: string; tokenType: "Bearer"; expiresIn: number };

export type ProblemCode =
  | "VALIDATION_FAILED"
  | "INVALID_CREDENTIALS"
  | "UNAUTHENTICATED"
  | "TOKEN_REVOKED"
  | "FORBIDDEN"
  | "PRODUCT_NOT_FOUND"
  | "PRODUCT_ALREADY_EXISTS"
  | "ORDER_NOT_FOUND"
  | "INSUFFICIENT_INVENTORY"
  | "IDEMPOTENCY_KEY_REQUIRED"
  | "IDEMPOTENCY_KEY_REUSED"
  | "ORDER_NOT_PAYABLE"
  | "ORDER_NOT_CANCELLABLE"
  | "INTERNAL_ERROR";

export type Problem = {
  type?: string;
  title: string;
  status: number;
  detail?: string;
  instance?: string;
  code: ProblemCode;
  errors?: { field: string; message: string }[];
};
