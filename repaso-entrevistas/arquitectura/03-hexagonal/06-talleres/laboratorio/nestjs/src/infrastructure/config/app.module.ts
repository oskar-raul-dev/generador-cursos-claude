import { Module } from "@nestjs/common";
import { APP_FILTER, APP_GUARD } from "@nestjs/core";
import { randomUUID } from "node:crypto";
import type { Clock, IdGenerator, Inventory, Notifications, Notifier, Orders, PasswordHasher, PaymentGateway, Payments, PendingPublications, Products, TokenIssuer, TokenRevocationStore, UnitOfWork, Users, IdempotencyStore } from "../../application/ports.js";
import { AuthorizePayment } from "../../application/usecases/authorize-payment.js";
import { CancelOrder } from "../../application/usecases/cancel-order.js";
import { CreateOrder } from "../../application/usecases/create-order.js";
import { CreateProduct } from "../../application/usecases/create-product.js";
import { DeliverPendingPublications } from "../../application/usecases/deliver-pending-publications.js";
import { GetOrder } from "../../application/usecases/get-order.js";
import { GetProduct } from "../../application/usecases/get-product.js";
import { ListNotifications } from "../../application/usecases/list-notifications.js";
import { ListOrders } from "../../application/usecases/list-orders.js";
import { ListProducts } from "../../application/usecases/list-products.js";
import { Login } from "../../application/usecases/login.js";
import { Logout } from "../../application/usecases/logout.js";
import { AuthController } from "../inbound/http/auth.controller.js";
import { AuthGuard } from "../inbound/http/auth.guard.js";
import { HealthController } from "../inbound/http/health.controller.js";
import { NotificationsController } from "../inbound/http/notifications.controller.js";
import { OrdersController } from "../inbound/http/orders.controller.js";
import { ProblemFilter } from "../inbound/http/problem.filter.js";
import { ProductsController } from "../inbound/http/products.controller.js";
import { MongoProducts } from "../outbound/mongo/mongo-products.js";
import { OutboxDispatcher } from "../outbound/notification/outbox-dispatcher.js";
import { DeterministicPaymentGateway } from "../outbound/payment/deterministic-payment-gateway.js";
import { PrismaIdempotencyStore } from "../outbound/postgres/prisma-idempotency-store.js";
import { PrismaInventory } from "../outbound/postgres/prisma-inventory.js";
import { PrismaNotifications } from "../outbound/postgres/prisma-notifications.js";
import { PrismaOrders } from "../outbound/postgres/prisma-orders.js";
import { PrismaPayments } from "../outbound/postgres/prisma-payments.js";
import { PrismaPendingPublications } from "../outbound/postgres/prisma-pending-publications.js";
import { PrismaProducts } from "../outbound/postgres/prisma-products.js";
import { PrismaUnitOfWork } from "../outbound/postgres/prisma-unit-of-work.js";
import { PrismaUsers } from "../outbound/postgres/prisma-users.js";
import { PrismaService } from "../outbound/postgres/prisma.service.js";
import { TableNotifier } from "../outbound/postgres/table-notifier.js";
import { RedisTokenRevocationStore } from "../outbound/redis/redis-token-revocation-store.js";
import { BcryptPasswordHasher } from "../outbound/security/bcrypt-password-hasher.js";
import { JoseTokenIssuer } from "../outbound/security/jose-token-issuer.js";
import { type HexConfig, loadConfig } from "./config.js";
import { CLOCK, CONFIG, ID_GENERATOR, IDEMPOTENCY_STORE, INVENTORY, NOTIFICATIONS, NOTIFIER, ORDERS, PASSWORD_HASHER, PAYMENT_GATEWAY, PAYMENTS, PENDING_PUBLICATIONS, PRODUCTS, TOKEN_ISSUER, TOKEN_REVOCATION_STORE, UNIT_OF_WORK, USERS } from "./tokens.js";

// Composition root. Es el único módulo Nest del proyecto y el único lugar que conoce a la vez los
// casos de uso y los adaptadores. Los casos de uso son clases sin decoradores: se construyen con
// useFactory y sus puertos, enlazados por token.
@Module({
  controllers: [HealthController, AuthController, ProductsController, OrdersController, NotificationsController],
  providers: [
    { provide: CONFIG, useFactory: () => loadConfig() },
    { provide: CLOCK, useValue: { now: () => new Date() } satisfies Clock },
    { provide: ID_GENERATOR, useValue: { next: () => randomUUID() } satisfies IdGenerator },

    // adaptadores (clases @Injectable) y su token de puerto
    PrismaService,
    PrismaUsers, PrismaProducts, PrismaInventory, PrismaOrders, PrismaPayments,
    PrismaIdempotencyStore, PrismaPendingPublications, PrismaNotifications, TableNotifier, PrismaUnitOfWork,
    MongoProducts, RedisTokenRevocationStore, JoseTokenIssuer, BcryptPasswordHasher, DeterministicPaymentGateway,
    { provide: USERS, useExisting: PrismaUsers },
    { provide: INVENTORY, useExisting: PrismaInventory },
    { provide: ORDERS, useExisting: PrismaOrders },
    { provide: PAYMENTS, useExisting: PrismaPayments },
    { provide: IDEMPOTENCY_STORE, useExisting: PrismaIdempotencyStore },
    { provide: PENDING_PUBLICATIONS, useExisting: PrismaPendingPublications },
    { provide: NOTIFICATIONS, useExisting: PrismaNotifications },
    { provide: NOTIFIER, useExisting: TableNotifier },
    { provide: UNIT_OF_WORK, useExisting: PrismaUnitOfWork },
    { provide: TOKEN_REVOCATION_STORE, useExisting: RedisTokenRevocationStore },
    { provide: TOKEN_ISSUER, useExisting: JoseTokenIssuer },
    { provide: PASSWORD_HASHER, useExisting: BcryptPasswordHasher },
    { provide: PAYMENT_GATEWAY, useExisting: DeterministicPaymentGateway },

    // el catálogo: parte 3. Un solo token Products; qué implementación, lo decide la configuración.
    {
      provide: PRODUCTS,
      useFactory: (cfg: HexConfig, prisma: PrismaProducts, mongo: MongoProducts): Products =>
        cfg.catalog === "mongo" ? mongo : prisma,
      inject: [CONFIG, PrismaProducts, MongoProducts],
    },

    // casos de uso
    { provide: Login, useFactory: (u: Users, h: PasswordHasher, t: TokenIssuer) => new Login(u, h, t), inject: [USERS, PASSWORD_HASHER, TOKEN_ISSUER] },
    { provide: Logout, useFactory: (r: TokenRevocationStore, c: Clock) => new Logout(r, c), inject: [TOKEN_REVOCATION_STORE, CLOCK] },
    { provide: ListProducts, useFactory: (p: Products, i: Inventory) => new ListProducts(p, i), inject: [PRODUCTS, INVENTORY] },
    { provide: GetProduct, useFactory: (p: Products, i: Inventory) => new GetProduct(p, i), inject: [PRODUCTS, INVENTORY] },
    { provide: CreateProduct, useFactory: (p: Products, i: Inventory, u: UnitOfWork) => new CreateProduct(p, i, u), inject: [PRODUCTS, INVENTORY, UNIT_OF_WORK] },
    {
      provide: CreateOrder,
      useFactory: (p: Products, i: Inventory, o: Orders, k: IdempotencyStore, ids: IdGenerator, c: Clock, u: UnitOfWork) =>
        new CreateOrder(p, i, o, k, ids, c, u),
      inject: [PRODUCTS, INVENTORY, ORDERS, IDEMPOTENCY_STORE, ID_GENERATOR, CLOCK, UNIT_OF_WORK],
    },
    { provide: GetOrder, useFactory: (o: Orders) => new GetOrder(o), inject: [ORDERS] },
    { provide: ListOrders, useFactory: (o: Orders) => new ListOrders(o), inject: [ORDERS] },
    {
      provide: AuthorizePayment,
      useFactory: (o: Orders, p: Payments, g: PaymentGateway, k: IdempotencyStore, u: UnitOfWork) => new AuthorizePayment(o, p, g, k, u),
      inject: [ORDERS, PAYMENTS, PAYMENT_GATEWAY, IDEMPOTENCY_STORE, UNIT_OF_WORK],
    },
    {
      provide: CancelOrder,
      useFactory: (o: Orders, i: Inventory, pp: PendingPublications, ids: IdGenerator, c: Clock, u: UnitOfWork) => new CancelOrder(o, i, pp, ids, c, u),
      inject: [ORDERS, INVENTORY, PENDING_PUBLICATIONS, ID_GENERATOR, CLOCK, UNIT_OF_WORK],
    },
    { provide: ListNotifications, useFactory: (n: Notifications) => new ListNotifications(n), inject: [NOTIFICATIONS] },
    {
      provide: DeliverPendingPublications,
      useFactory: (pp: PendingPublications, n: Notifier, u: Users, uow: UnitOfWork) => new DeliverPendingPublications(pp, n, u, uow),
      inject: [PENDING_PUBLICATIONS, NOTIFIER, USERS, UNIT_OF_WORK],
    },

    // borde HTTP transversal y disparador de la outbox
    OutboxDispatcher,
    { provide: APP_GUARD, useClass: AuthGuard },
    { provide: APP_FILTER, useClass: ProblemFilter },
  ],
})
export class AppModule {}
