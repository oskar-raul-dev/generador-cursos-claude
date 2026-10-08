package hex.orders.application.usecase;

import hex.orders.application.Actor;
import hex.orders.application.error.IdempotencyKeyReused;
import hex.orders.application.error.NotFound;
import hex.orders.application.port.out.IdGenerator;
import hex.orders.application.port.out.IdempotencyStore;
import hex.orders.application.port.out.Inventory;
import hex.orders.application.port.out.Orders;
import hex.orders.application.port.out.PendingPublications;
import hex.orders.application.port.out.Products;
import hex.orders.application.port.out.UnitOfWork;
import hex.orders.domain.Order;
import hex.orders.domain.OrderLine;

import java.time.Clock;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

// Crear un pedido reservando el inventario de todas sus líneas, o nada. Una transacción rodea
// la comprobación de idempotencia, el catálogo, la reserva, el pedido y la clave: si algo falla
// después de descontar una línea, el descuento se revierte con el resto.
public final class CreateOrder {

    public record LineRequest(String sku, int quantity) {}

    public record Command(Actor actor, String idempotencyKey, String requestHash, List<LineRequest> lines) {}

    public record Result(Order order, boolean replayed) {}

    private final Products products;
    private final Inventory inventory;
    private final Orders orders;
    private final IdempotencyStore idempotency;
    private final PendingPublications pending;
    private final IdGenerator ids;
    private final Clock clock;
    private final UnitOfWork unitOfWork;

    public CreateOrder(Products products, Inventory inventory, Orders orders, IdempotencyStore idempotency,
                       PendingPublications pending, IdGenerator ids, Clock clock, UnitOfWork unitOfWork) {
        this.products = products;
        this.inventory = inventory;
        this.orders = orders;
        this.idempotency = idempotency;
        this.pending = pending;
        this.ids = ids;
        this.clock = clock;
        this.unitOfWork = unitOfWork;
    }

    public Result execute(Command command) {
        return unitOfWork.run(() -> {
            var actorId = command.actor().id();
            var stored = idempotency.find(actorId, command.idempotencyKey());
            if (stored.isPresent()) {
                if (!stored.get().requestHash().equals(command.requestHash())) {
                    throw new IdempotencyKeyReused();
                }
                var previous = orders.find(UUID.fromString(stored.get().body())).orElseThrow();
                return new Result(previous, true);
            }

            // Catálogo primero (404 si falta algo), inventario después (409): así un SKU
            // inexistente no deja reservas a medias que haya que revertir.
            List<OrderLine> lines = new ArrayList<>();
            for (var line : command.lines()) {
                var product = products.find(line.sku()).orElseThrow(() -> NotFound.product(line.sku()));
                lines.add(new OrderLine(product.sku(), product.name(), line.quantity(), product.unitPrice()));
            }

            var order = Order.place(ids.next(), actorId, lines, clock.instant());
            orders.save(order);                            // primero el pedido: las reservas lo referencian
            inventory.reserve(order.id(), lines);          // lanza InsufficientInventory → rollback de todo
            idempotency.save(actorId, command.idempotencyKey(), command.requestHash(), 201, order.id().toString());
            order.pullEvents().forEach(pending::add);        // taller 09: OrderCreated a la outbox, misma transacción
            return new Result(order, false);
        });
    }
}
