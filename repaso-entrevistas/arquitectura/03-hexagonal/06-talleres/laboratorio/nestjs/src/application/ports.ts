import type { DomainEvent } from "../domain/domain-event.js";
import type { Money } from "../domain/money.js";
import type { Order } from "../domain/order.js";
import type { OrderLine } from "../domain/order-line.js";
import type { Payment } from "../domain/payment.js";
import type { Product } from "../domain/product.js";
import type { Role } from "./actor.js";
import type { Page, PageRequest } from "./page.js";

// Los puertos de salida: lo que el núcleo necesita, en su vocabulario. Son interfaces TypeScript
// y por tanto desaparecen en runtime: el composition root las enlaza con tokens (Symbol).

export type User = { id: string; email: string; passwordHash: string; role: Role };

export interface Users {
  findByEmail(email: string): Promise<User | null>;
  findById(id: string): Promise<User | null>;
}

export interface PasswordHasher {
  matches(rawPassword: string, hash: string): Promise<boolean>;
}

export type IssuedToken = { value: string; tokenId: string; expiresAt: Date; expiresInSeconds: number };

export interface TokenIssuer {
  issue(user: User): Promise<IssuedToken>;
}

export interface TokenRevocationStore {
  revoke(tokenId: string, timeToLiveSeconds: number): Promise<void>;
  isRevoked(tokenId: string): Promise<boolean>;
}

// El catálogo. Ni Prisma ni MongoDB asoman: la parte 3 cambia la implementación y nada más.
export interface Products {
  find(sku: string): Promise<Product | null>;
  exists(sku: string): Promise<boolean>;
  list(page: PageRequest): Promise<Page<Product>>;
  save(product: Product): Promise<void>;
}

// `reserve` descuenta todas las líneas o lanza InsufficientInventory; la atomicidad la da la
// unidad de trabajo que rodea al caso de uso.
export interface Inventory {
  availableFor(skus: string[]): Promise<Map<string, number>>;
  initialize(sku: string, quantity: number): Promise<void>;
  reserve(orderId: string, lines: OrderLine[]): Promise<void>;
  release(orderId: string): Promise<void>;
}

export interface Orders {
  find(id: string): Promise<Order | null>;
  save(order: Order): Promise<void>;
  list(customerId: string | null, page: PageRequest): Promise<Page<Order>>;
}

export interface PaymentGateway {
  authorize(operationId: string, amount: Money): Promise<Payment>;
}

export interface Payments {
  record(orderId: string, payment: Payment, amount: Money): Promise<void>;
}

export type StoredResponse = { requestHash: string; status: number; body: string };

// La clave se persiste con el efecto, en la misma transacción.
export interface IdempotencyStore {
  find(actorId: string, key: string): Promise<StoredResponse | null>;
  save(actorId: string, key: string, requestHash: string, status: number, body: string): Promise<void>;
}

export interface PendingPublications {
  add(event: DomainEvent): Promise<void>;
  nextBatch(size: number): Promise<DomainEvent[]>;
  markPublished(eventId: string): Promise<void>;
}

export interface Notifier {
  notify(event: DomainEvent, recipient: string): Promise<void>;
}

export type Notification = { id: string; orderId: string; type: string; recipient: string; createdAt: Date };

export interface Notifications {
  list(orderId: string | null, page: PageRequest): Promise<Page<Notification>>;
}

// El límite transaccional como capacidad: "ejecuta esto y confirma todo o nada".
export interface UnitOfWork {
  run<T>(work: () => Promise<T>): Promise<T>;
}

export interface IdGenerator {
  next(): string;
}

export interface Clock {
  now(): Date;
}
