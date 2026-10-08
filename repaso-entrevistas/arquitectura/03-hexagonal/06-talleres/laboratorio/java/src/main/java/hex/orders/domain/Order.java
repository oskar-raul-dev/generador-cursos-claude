package hex.orders.domain;

import java.time.Instant;
import java.util.ArrayList;
import java.util.List;
import java.util.Objects;
import java.util.UUID;

// El agregado. Protege dos cosas: que un pedido tenga líneas y que las transiciones de estado sean
// las del contrato. No sabe de HTTP, JPA ni del proveedor de pagos; recibe datos y devuelve hechos.
public final class Order {

    private final UUID id;
    private final UUID customerId;
    private final List<OrderLine> lines;
    private final Money total;
    private final Instant createdAt;
    private OrderStatus status;
    private Payment payment;
    private long version;
    private final List<DomainEvent> events = new ArrayList<>();

    private Order(UUID id, UUID customerId, List<OrderLine> lines, Money total, Instant createdAt,
                  OrderStatus status, Payment payment, long version) {
        this.id = id;
        this.customerId = customerId;
        this.lines = List.copyOf(lines);
        this.total = total;
        this.createdAt = createdAt;
        this.status = status;
        this.payment = payment;
        this.version = version;
    }

    // Crear un pedido: nace CONFIRMED (reservado, sin pagar). La reserva de inventario la coordina
    // el caso de uso; aquí solo se exige que haya algo que reservar.
    public static Order place(UUID id, UUID customerId, List<OrderLine> lines, Instant now) {
        Objects.requireNonNull(id, "id");
        Objects.requireNonNull(customerId, "customerId");
        if (lines == null || lines.isEmpty()) {
            throw new EmptyOrder();
        }
        Money total = lines.stream().map(OrderLine::lineTotal).reduce(Money::plus).orElseThrow();
        var order = new Order(id, customerId, lines, total, now, OrderStatus.CONFIRMED, null, 0);
        order.events.add(new DomainEvent.OrderCreated(UUID.randomUUID(), id, customerId, total, now));  // taller 09
        return order;
    }

    // Reconstruir desde persistencia sin volver a validar reglas de creación: el estado guardado ya
    // fue válido cuando se guardó.
    public static Order reconstitute(UUID id, UUID customerId, List<OrderLine> lines, Money total,
                                     Instant createdAt, OrderStatus status, Payment payment, long version) {
        return new Order(id, customerId, lines, total, createdAt, status, payment, version);
    }

    public boolean isPayable() {
        return status == OrderStatus.CONFIRMED || status == OrderStatus.PAYMENT_REJECTED;
    }

    public boolean isCancellable() {
        return status == OrderStatus.CONFIRMED
            || status == OrderStatus.PAYMENT_REJECTED
            || status == OrderStatus.PAYMENT_PENDING;
    }

    // Aplica el resultado del proveedor. PENDING no es un rechazo: el pedido queda a la espera y no
    // vuelve a ser pagable hasta que alguien consulte al proveedor.
    public void applyPayment(Payment result) {
        if (!isPayable()) {
            throw new OrderNotPayable(status);
        }
        this.payment = result;
        this.status = switch (result.status()) {
            case AUTHORIZED -> OrderStatus.PAID;
            case REJECTED -> OrderStatus.PAYMENT_REJECTED;
            case PENDING -> OrderStatus.PAYMENT_PENDING;
        };
    }

    // Cancelar es idempotente: la segunda vez no cambia nada ni emite el hecho otra vez.
    // Devuelve true si hubo transición (y por tanto hay reserva que liberar y evento que publicar).
    public boolean cancel(Instant now) {
        if (status == OrderStatus.CANCELLED) {
            return false;
        }
        if (!isCancellable()) {
            throw new OrderNotCancellable(status);
        }
        this.status = OrderStatus.CANCELLED;
        events.add(new DomainEvent.OrderCancelled(UUID.randomUUID(), id, customerId, total, now));
        return true;
    }

    // Aplicación recoge los eventos después de la mutación y decide qué hacer con ellos.
    public List<DomainEvent> pullEvents() {
        List<DomainEvent> pulled = List.copyOf(events);
        events.clear();
        return pulled;
    }

    public UUID id() { return id; }
    public UUID customerId() { return customerId; }
    public List<OrderLine> lines() { return lines; }
    public Money total() { return total; }
    public Instant createdAt() { return createdAt; }
    public OrderStatus status() { return status; }
    public Payment payment() { return payment; }
    public long version() { return version; }
}
