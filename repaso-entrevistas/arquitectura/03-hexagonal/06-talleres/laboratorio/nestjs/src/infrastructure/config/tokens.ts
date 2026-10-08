// Una interfaz TypeScript no existe en runtime: NestJS necesita un token concreto para enlazar
// cada puerto con su implementación. Los tokens viven en el composition root, no en aplicación.
export const CONFIG = Symbol("HexConfig");
export const USERS = Symbol("Users");
export const PASSWORD_HASHER = Symbol("PasswordHasher");
export const TOKEN_ISSUER = Symbol("TokenIssuer");
export const TOKEN_REVOCATION_STORE = Symbol("TokenRevocationStore");
export const PRODUCTS = Symbol("Products");
export const INVENTORY = Symbol("Inventory");
export const ORDERS = Symbol("Orders");
export const PAYMENT_GATEWAY = Symbol("PaymentGateway");
export const PAYMENTS = Symbol("Payments");
export const IDEMPOTENCY_STORE = Symbol("IdempotencyStore");
export const PENDING_PUBLICATIONS = Symbol("PendingPublications");
export const NOTIFIER = Symbol("Notifier");
export const NOTIFICATIONS = Symbol("Notifications");
export const UNIT_OF_WORK = Symbol("UnitOfWork");
export const ID_GENERATOR = Symbol("IdGenerator");
export const CLOCK = Symbol("Clock");
