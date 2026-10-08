package hex.orders.application.usecase;

import hex.orders.application.Actor;
import hex.orders.application.Page;
import hex.orders.application.PageRequest;
import hex.orders.application.error.IdempotencyKeyReused;
import hex.orders.application.port.out.IdempotencyStore;
import hex.orders.application.port.out.Inventory;
import hex.orders.application.port.out.Orders;
import hex.orders.application.port.out.PendingPublications;
import hex.orders.application.port.out.Products;
import hex.orders.application.port.out.UnitOfWork;
import hex.orders.domain.DomainEvent;
import hex.orders.domain.InsufficientInventory;
import hex.orders.domain.Money;
import hex.orders.domain.Order;
import hex.orders.domain.OrderLine;
import hex.orders.domain.Product;
import org.junit.jupiter.api.Test;

import java.time.Clock;
import java.time.Instant;
import java.time.ZoneOffset;
import java.util.Collection;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;
import java.util.function.Supplier;
import java.util.stream.Collectors;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

// El caso de uso con dobles fieles a los puertos: fakes en memoria que respetan el contrato (el
// inventario rechaza lo que no hay, la clave se guarda con el efecto). Se observa el estado
// resultante, no cuántas veces se llamó a un mock.
class CreateOrderTest {

    private static final Actor ANA = new Actor(UUID.fromString("11111111-1111-4111-8111-111111111111"), "ana@hex.local", Actor.Role.CUSTOMER);

    private final InMemoryProducts products = new InMemoryProducts();
    private final InMemoryInventory inventory = new InMemoryInventory();
    private final InMemoryOrders orders = new InMemoryOrders();
    private final InMemoryIdempotency idempotency = new InMemoryIdempotency();
    private final InMemoryPending pending = new InMemoryPending();
    private final CreateOrder createOrder = new CreateOrder(products, inventory, orders, idempotency, pending,
        UUID::randomUUID, Clock.fixed(Instant.parse("2026-09-27T12:00:00Z"), ZoneOffset.UTC),
        new SnapshotUnitOfWork(orders, inventory, idempotency));

    CreateOrderTest() {
        products.save(new Product("SKU-001", "Mechanical keyboard", Money.usd("49.90")));
        products.save(new Product("SKU-004", "Webcam", Money.usd("59.00")));
        inventory.initialize("SKU-001", 20);
        inventory.initialize("SKU-004", 0);
    }

    @Test
    void reservesStockAndRemembersTheKey() {
        var result = createOrder.execute(command("key-0001", List.of(new CreateOrder.LineRequest("SKU-001", 2))));
        assertFalse(result.replayed());
        assertEquals("99.80", result.order().total().amountAsText());
        assertEquals(18, inventory.availableFor(List.of("SKU-001")).get("SKU-001"));
        assertTrue(orders.find(result.order().id()).isPresent());
        // taller 09: el hecho OrderCreated queda en la outbox, en la misma unidad de trabajo
        assertEquals(1, pending.data.size());
        assertEquals("ORDER_CREATED", pending.data.getFirst().type());
    }

    @Test
    void sameKeySameBodyReplaysWithoutReservingAgain() {
        var first = createOrder.execute(command("key-0002", List.of(new CreateOrder.LineRequest("SKU-001", 2))));
        var again = createOrder.execute(command("key-0002", List.of(new CreateOrder.LineRequest("SKU-001", 2))));
        assertTrue(again.replayed());
        assertEquals(first.order().id(), again.order().id());
        assertEquals(18, inventory.availableFor(List.of("SKU-001")).get("SKU-001"));
    }

    @Test
    void sameKeyDifferentBodyIsRejected() {
        createOrder.execute(command("key-0003", List.of(new CreateOrder.LineRequest("SKU-001", 1))));
        assertThrows(IdempotencyKeyReused.class,
            () -> createOrder.execute(command("key-0003", List.of(new CreateOrder.LineRequest("SKU-001", 3)))));
    }

    @Test
    void insufficientInventoryLeavesNothingBehind() {
        assertThrows(InsufficientInventory.class, () -> createOrder.execute(command("key-0004",
            List.of(new CreateOrder.LineRequest("SKU-001", 1), new CreateOrder.LineRequest("SKU-004", 1)))));
        // El caso de uso guarda el pedido ANTES de reservar (las reservas lo referencian). Lo que
        // deja el sistema limpio no es el orden de las llamadas sino la unidad de trabajo, que
        // revierte pedido, reservas y clave. El doble SnapshotUnitOfWork hace exactamente eso;
        // con un UnitOfWork que no revirtiera, esta prueba fallaría, y debe fallar.
        assertEquals(20, inventory.availableFor(List.of("SKU-001")).get("SKU-001"));
        assertTrue(orders.all().isEmpty());
        assertTrue(idempotency.find(ANA.id(), "key-0004").isEmpty());
    }

    private static CreateOrder.Command command(String key, List<CreateOrder.LineRequest> lines) {
        String hash = lines.stream().map(l -> l.sku() + ":" + l.quantity()).collect(Collectors.joining(","));
        return new CreateOrder.Command(ANA, key, hash, lines);
    }

    // ------------------------------------------------------------ dobles fieles al puerto

    // Unidad de trabajo de pruebas: toma una foto de los fakes y la restaura si el trabajo lanza.
    // Es el comportamiento del TransactionTemplate real reducido a lo que el caso de uso observa.
    static final class SnapshotUnitOfWork implements UnitOfWork {
        private final InMemoryOrders orders;
        private final InMemoryInventory inventory;
        private final InMemoryIdempotency idempotency;

        SnapshotUnitOfWork(InMemoryOrders orders, InMemoryInventory inventory, InMemoryIdempotency idempotency) {
            this.orders = orders;
            this.inventory = inventory;
            this.idempotency = idempotency;
        }

        @Override
        public <T> T run(Supplier<T> work) {
            var ordersBefore = new HashMap<>(orders.data);
            var inventoryBefore = new HashMap<>(inventory.available);
            var keysBefore = new HashMap<>(idempotency.data);
            try {
                return work.get();
            } catch (RuntimeException e) {
                orders.data.clear(); orders.data.putAll(ordersBefore);
                inventory.available.clear(); inventory.available.putAll(inventoryBefore);
                idempotency.data.clear(); idempotency.data.putAll(keysBefore);
                throw e;
            }
        }
    }

    static final class InMemoryPending implements PendingPublications {
        final List<DomainEvent> data = new java.util.ArrayList<>();
        public void add(DomainEvent event) { data.add(event); }
        public List<DomainEvent> nextBatch(int size) { return List.copyOf(data); }
        public void markPublished(UUID eventId) { data.removeIf(e -> e.eventId().equals(eventId)); }
    }

    static final class InMemoryProducts implements Products {
        final Map<String, Product> data = new HashMap<>();
        public Optional<Product> find(String sku) { return Optional.ofNullable(data.get(sku)); }
        public boolean exists(String sku) { return data.containsKey(sku); }
        public Page<Product> list(PageRequest page) { return new Page<>(List.copyOf(data.values()), null); }
        public void save(Product product) { data.put(product.sku(), product); }
    }

    static final class InMemoryInventory implements Inventory {
        final Map<String, Integer> available = new HashMap<>();
        public Map<String, Integer> availableFor(Collection<String> skus) {
            return skus.stream().collect(Collectors.toMap(s -> s, s -> available.getOrDefault(s, 0)));
        }
        public void initialize(String sku, int quantity) { available.put(sku, quantity); }
        public void reserve(UUID orderId, List<OrderLine> lines) {
            // como el adaptador real: descuenta línea a línea y lanza al primer faltante; lo ya
            // descontado lo revierte la unidad de trabajo, no este método
            for (int i = 0; i < lines.size(); i++) {
                var l = lines.get(i);
                int have = available.getOrDefault(l.sku(), 0);
                if (have < l.quantity()) throw new InsufficientInventory(l.sku(), l.quantity(), have, i);
                available.put(l.sku(), have - l.quantity());
            }
        }
        public void release(UUID orderId) {}
        public int adjust(String sku, int delta) { available.merge(sku, delta, Integer::sum); return available.get(sku); }
    }

    static final class InMemoryOrders implements Orders {
        final Map<UUID, Order> data = new HashMap<>();
        public Optional<Order> find(UUID id) { return Optional.ofNullable(data.get(id)); }
        public void save(Order order) { data.put(order.id(), order); }
        public Page<Order> list(UUID customerId, PageRequest page) { return new Page<>(List.copyOf(data.values()), null); }
        Collection<Order> all() { return data.values(); }
    }

    static final class InMemoryIdempotency implements IdempotencyStore {
        final Map<String, StoredResponse> data = new HashMap<>();
        public Optional<StoredResponse> find(UUID actorId, String key) { return Optional.ofNullable(data.get(actorId + ":" + key)); }
        public void save(UUID actorId, String key, String requestHash, int status, String body) {
            data.put(actorId + ":" + key, new StoredResponse(requestHash, status, body));
        }
    }
}
