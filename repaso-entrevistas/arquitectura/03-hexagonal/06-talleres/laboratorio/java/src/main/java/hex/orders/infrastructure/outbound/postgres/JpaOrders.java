package hex.orders.infrastructure.outbound.postgres;

import hex.orders.application.Page;
import hex.orders.application.PageRequest;
import hex.orders.application.port.out.Orders;
import hex.orders.domain.Money;
import hex.orders.domain.Order;
import hex.orders.domain.OrderLine;
import hex.orders.domain.OrderStatus;
import hex.orders.domain.Payment;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Component;

import java.time.Clock;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

// Traduce entre Order (dominio) y OrderEntity (JPA). Al leer, reconstruye un agregado completo:
// líneas cargadas y último pago; nada de proxies que vayan a la base más tarde.
@Component
public class JpaOrders implements Orders {

    private final OrderRepository orders;
    private final PaymentRepository payments;
    private final Clock clock;

    public JpaOrders(OrderRepository orders, PaymentRepository payments, Clock clock) {
        this.orders = orders;
        this.payments = payments;
        this.clock = clock;
    }

    @Override
    public Optional<Order> find(UUID id) {
        return orders.findById(id).map(this::toOrder);
    }

    @Override
    public void save(Order order) {
        var entity = orders.findById(order.id()).orElseGet(() -> {
            var created = new OrderEntity();
            created.id = order.id();
            created.customerId = order.customerId();
            created.createdAt = order.createdAt();
            created.lines = order.lines().stream().map(JpaOrders::toLine).toList();
            return created;
        });
        entity.status = order.status().name();
        entity.totalAmount = order.total().amount();
        entity.currency = order.total().currency();
        entity.version = order.version() + 1;
        entity.updatedAt = clock.instant();
        orders.save(entity);
    }

    @Override
    public Page<Order> list(UUID customerId, PageRequest page) {
        Pageable limit = Pageable.ofSize(page.limit() + 1);
        List<OrderEntity> rows = Cursors.TimeCursor.decode(page.cursor())
            .map(c -> orders.pageAfter(customerId, c.ts(), c.id(), limit))
            .orElseGet(() -> orders.firstPage(customerId, limit));
        boolean more = rows.size() > page.limit();
        List<OrderEntity> pageRows = more ? rows.subList(0, page.limit()) : rows;
        String next = more ? Cursors.TimeCursor.encode(pageRows.getLast().createdAt, pageRows.getLast().id) : null;
        return new Page<>(pageRows.stream().map(this::toOrder).toList(), next);
    }

    private Order toOrder(OrderEntity e) {
        Payment payment = payments.findFirstByOrderIdOrderByCreatedAtDesc(e.id)
            .map(p -> new Payment(Payment.Status.valueOf(p.status), p.operationId, p.reference))
            .orElse(null);
        List<OrderLine> lines = e.lines.stream()
            .map(l -> new OrderLine(l.sku, l.productName, l.quantity, new Money(l.unitPrice, e.currency)))
            .toList();
        return Order.reconstitute(e.id, e.customerId, lines, new Money(e.totalAmount, e.currency),
            e.createdAt, OrderStatus.valueOf(e.status), payment, e.version);
    }

    private static OrderLineEmbeddable toLine(OrderLine line) {
        var l = new OrderLineEmbeddable();
        l.sku = line.sku();
        l.productName = line.name();
        l.quantity = line.quantity();
        l.unitPrice = line.unitPrice().amount();
        return l;
    }
}
