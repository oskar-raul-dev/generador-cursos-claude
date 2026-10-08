package hex.orders.infrastructure.config;

import hex.orders.application.port.out.AppliedEvents;
import hex.orders.application.port.out.EventPublisher;
import hex.orders.application.port.out.IdGenerator;
import hex.orders.application.port.out.IdempotencyStore;
import hex.orders.application.port.out.Inventory;
import hex.orders.application.port.out.Notifications;
import hex.orders.application.port.out.Notifier;
import hex.orders.application.port.out.Orders;
import hex.orders.application.port.out.OrdersSummary;
import hex.orders.application.port.out.PasswordHasher;
import hex.orders.application.port.out.PaymentGateway;
import hex.orders.application.port.out.Payments;
import hex.orders.application.port.out.PendingPublications;
import hex.orders.application.port.out.Products;
import hex.orders.application.port.out.TokenIssuer;
import hex.orders.application.port.out.TokenRevocationStore;
import hex.orders.application.port.out.UnitOfWork;
import hex.orders.application.port.out.Users;
import hex.orders.application.usecase.AdjustStock;
import hex.orders.application.usecase.AuthorizePayment;
import hex.orders.application.usecase.CancelOrder;
import hex.orders.application.usecase.CreateOrder;
import hex.orders.application.usecase.CreateProduct;
import hex.orders.application.usecase.DeliverPendingPublications;
import hex.orders.application.usecase.GetOrder;
import hex.orders.application.usecase.GetOrdersSummary;
import hex.orders.application.usecase.GetProduct;
import hex.orders.application.usecase.ListNotifications;
import hex.orders.application.usecase.ListOrders;
import hex.orders.application.usecase.ListProducts;
import hex.orders.application.usecase.Login;
import hex.orders.application.usecase.Logout;
import hex.orders.application.usecase.NotifyCustomer;
import hex.orders.application.usecase.ProjectOrdersSummary;
import hex.orders.application.usecase.PublishPendingEvents;
import hex.orders.infrastructure.outbound.mongo.MongoProducts;
import hex.orders.infrastructure.outbound.postgres.JpaProducts;
import org.springframework.boot.context.properties.EnableConfigurationProperties;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.transaction.PlatformTransactionManager;
import org.springframework.transaction.support.TransactionTemplate;

import java.time.Clock;
import java.util.UUID;
import java.util.function.Supplier;

// Composition root. Es el único lugar que conoce a la vez los casos de uso y los adaptadores.
// Los casos de uso son clases Java sin anotaciones; aquí se construyen con sus puertos.
@Configuration
@EnableConfigurationProperties(HexProperties.class)
public class OrdersConfiguration {

    // ---------------------------------------------------------------- puertos que son detalle de JDK

    @Bean
    Clock clock() {
        return Clock.systemUTC();
    }

    @Bean
    IdGenerator idGenerator() {
        return UUID::randomUUID;
    }

    // El límite transaccional como puerto: TransactionTemplate es el adaptador. Ningún caso de
    // uso lleva @Transactional, así que no hay proxy que una self-invocation pueda saltarse.
    @Bean
    UnitOfWork unitOfWork(PlatformTransactionManager transactionManager) {
        var template = new TransactionTemplate(transactionManager);
        return new UnitOfWork() {
            @Override
            public <T> T run(Supplier<T> work) {
                return template.execute(status -> work.get());
            }
        };
    }

    // ---------------------------------------------------------------- el catálogo: parte 3

    // Un solo bean Products; qué implementación depende de hex.catalog. Cambiar el catálogo de base
    // es cambiar esta selección: el resto del grafo no se entera.
    @Bean
    Products products(HexProperties properties, JpaProducts jpa, MongoProducts mongo) {
        return "mongo".equals(properties.catalog()) ? mongo : jpa;
    }

    // ---------------------------------------------------------------- casos de uso

    @Bean
    Login login(Users users, PasswordHasher hasher, TokenIssuer tokens) {
        return new Login(users, hasher, tokens);
    }

    @Bean
    Logout logout(TokenRevocationStore revocations, Clock clock) {
        return new Logout(revocations, clock);
    }

    @Bean
    ListProducts listProducts(Products products, Inventory inventory) {
        return new ListProducts(products, inventory);
    }

    @Bean
    GetProduct getProduct(Products products, Inventory inventory) {
        return new GetProduct(products, inventory);
    }

    @Bean
    CreateProduct createProduct(Products products, Inventory inventory, UnitOfWork unitOfWork) {
        return new CreateProduct(products, inventory, unitOfWork);
    }

    @Bean
    CreateOrder createOrder(Products products, Inventory inventory, Orders orders, IdempotencyStore idempotency,
                            PendingPublications pending, IdGenerator ids, Clock clock, UnitOfWork unitOfWork) {
        return new CreateOrder(products, inventory, orders, idempotency, pending, ids, clock, unitOfWork);
    }

    @Bean
    GetOrder getOrder(Orders orders) {
        return new GetOrder(orders);
    }

    @Bean
    ListOrders listOrders(Orders orders) {
        return new ListOrders(orders);
    }

    @Bean
    AuthorizePayment authorizePayment(Orders orders, Payments payments, PaymentGateway gateway,
                                      IdempotencyStore idempotency, UnitOfWork unitOfWork) {
        return new AuthorizePayment(orders, payments, gateway, idempotency, unitOfWork);
    }

    @Bean
    CancelOrder cancelOrder(Orders orders, Inventory inventory, PendingPublications pending, Clock clock, UnitOfWork unitOfWork) {
        return new CancelOrder(orders, inventory, pending, clock, unitOfWork);
    }

    @Bean
    ListNotifications listNotifications(Notifications notifications) {
        return new ListNotifications(notifications);
    }

    @Bean
    NotifyCustomer notifyCustomer(Users users, Notifier notifier) {
        return new NotifyCustomer(users, notifier);
    }

    @Bean
    DeliverPendingPublications deliverPendingPublications(PendingPublications pending, NotifyCustomer notify, UnitOfWork unitOfWork) {
        return new DeliverPendingPublications(pending, notify, unitOfWork);
    }

    // ---------------------------------------------------------------- taller 11

    @Bean
    AdjustStock adjustStock(Inventory inventory, UnitOfWork unitOfWork) {
        return new AdjustStock(inventory, unitOfWork);
    }

    // ---------------------------------------------------------------- taller 09

    @Bean
    PublishPendingEvents publishPendingEvents(PendingPublications pending, EventPublisher publisher, UnitOfWork unitOfWork) {
        return new PublishPendingEvents(pending, publisher, unitOfWork);
    }

    @Bean
    ProjectOrdersSummary projectOrdersSummary(AppliedEvents applied, OrdersSummary summary, UnitOfWork unitOfWork) {
        return new ProjectOrdersSummary(applied, summary, unitOfWork);
    }

    @Bean
    GetOrdersSummary getOrdersSummary(OrdersSummary summary) {
        return new GetOrdersSummary(summary);
    }
}
