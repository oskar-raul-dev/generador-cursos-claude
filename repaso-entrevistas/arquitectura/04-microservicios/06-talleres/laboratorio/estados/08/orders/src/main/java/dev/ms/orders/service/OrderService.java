package dev.ms.orders.service;

import dev.ms.orders.catalog.Catalog;
import dev.ms.orders.entity.Notification;
import dev.ms.orders.entity.Order;
import dev.ms.orders.entity.OrderLine;
import dev.ms.orders.events.OrderEvents;
import dev.ms.orders.inventory.Inventory;
import dev.ms.orders.repository.NotificationRepository;
import dev.ms.orders.repository.OrderRepository;
import dev.ms.orders.repository.PaymentRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.transaction.support.TransactionTemplate;
import tools.jackson.databind.json.JsonMapper;

import java.util.List;
import java.util.UUID;

// Los pedidos, fuera del monolito (taller 04). El flujo de alta es el que dejó el taller 02 —reservar
// primero, guardar después en una transacción corta, compensar si algo falla—, con tres
// dependencias remotas en vez de tablas: el catálogo (HTTP, monolito), el inventario (gRPC) y los
// pagos (HTTP, en PaymentService).
@Service
public class OrderService {

    public record LineRequest(String sku, int quantity) {}
    public record Created(int status, String body, boolean replay, String orderId) {}

    private final OrderRepository orders;
    private final Catalog catalog;
    private final Inventory inventory;
    private final PaymentRepository payments;
    private final NotificationRepository notifications;
    private final Idempotency idempotency;
    private final TransactionTemplate tx;
    private final JsonMapper json;
    private final OrderEvents events;

    public OrderService(OrderRepository orders, Catalog catalog, Inventory inventory, PaymentRepository payments,
                        NotificationRepository notifications, Idempotency idempotency, TransactionTemplate tx,
                        JsonMapper json, OrderEvents events) {
        this.orders = orders; this.catalog = catalog; this.inventory = inventory; this.payments = payments;
        this.notifications = notifications; this.idempotency = idempotency; this.tx = tx; this.json = json;
        this.events = events;
    }

    public Created create(Actor actor, List<LineRequest> lines, String idempotencyKey) {
        var replay = tx.execute(s -> idempotency.lookup(idempotencyKey, actor, lines));
        if (replay.isPresent()) return new Created(200, replay.get().body(), true, null);

        var products = catalog.find(lines.stream().map(LineRequest::sku).distinct().toList());
        for (var line : lines) if (!products.containsKey(line.sku())) throw new Errors.ProductNotFound(line.sku());

        var orderId = UUID.randomUUID();
        try {
            inventory.reserve(orderId, lines.stream().map(l -> new Inventory.Line(l.sku(), l.quantity())).toList());
        } catch (Errors.InventoryUnavailable e) {
            // un DEADLINE_EXCEEDED no es un "no": inventory pudo retener; se compensa por la misma referencia
            try { inventory.release(orderId); } catch (Errors.InventoryUnavailable ignored) { }
            throw e;
        }
        try {
            return tx.execute(s -> {
                var orderLines = lines.stream().map(l -> {
                    var p = products.get(l.sku());
                    return new OrderLine(l.sku(), p.name(), l.quantity(), p.unitPrice());
                }).toList();
                var order = orders.save(new Order(orderId, actor.id(), actor.email(), orderLines));
                events.placed(order);                          // taller 06: en la misma transacción que el pedido
                var view = Views.OrderView.of(order, null);
                idempotency.remember(idempotencyKey, actor, lines, 201, view);
                return new Created(201, json.writeValueAsString(view), false, orderId.toString());
            });
        } catch (RuntimeException e) {
            inventory.release(orderId);
            throw e;
        }
    }

    // Contrato v2 (taller 08): el alta NO reserva. Guarda el pedido en PENDING y registra OrderPlaced en
    // la misma transacción; la saga decide después. Por eso responde 202: "lo he apuntado", no "está hecho".
    public Created createV2(Actor actor, List<LineRequest> lines, String idempotencyKey) {
        var key = idempotencyKey == null ? null : "v2:" + idempotencyKey;   // no se mezcla con las claves de v1
        var replay = tx.execute(s -> idempotency.lookup(key, actor, lines));
        if (replay.isPresent()) return new Created(replay.get().status(), replay.get().body(), true, null);

        var products = catalog.find(lines.stream().map(LineRequest::sku).distinct().toList());
        for (var line : lines) if (!products.containsKey(line.sku())) throw new Errors.ProductNotFound(line.sku());

        var orderId = UUID.randomUUID();
        return tx.execute(s -> {
            var orderLines = lines.stream().map(l -> {
                var p = products.get(l.sku());
                return new OrderLine(l.sku(), p.name(), l.quantity(), p.unitPrice());
            }).toList();
            var order = orders.save(new Order(orderId, actor.id(), actor.email(), orderLines, "PENDING"));
            events.placedForSaga(order);                       // la saga empieza cuando esto se confirme
            var view = Views.OrderView.of(order, null);
            idempotency.remember(key, actor, lines, 202, view);
            return new Created(202, json.writeValueAsString(view), false, orderId.toString());
        });
    }

    @Transactional(readOnly = true)
    public Views.OrderView get(Actor actor, UUID id) {
        var order = visible(actor, orders.findById(id).orElseThrow(Errors.OrderNotFound::new));
        return Views.OrderView.of(order, payments.findFirstByOrderIdOrderByCreatedAtDesc(id).orElse(null));
    }

    @Transactional(readOnly = true)
    public List<Views.OrderView> list(Actor actor) {
        var found = actor.isOperator() ? orders.findAllByOrderByCreatedAtDesc() : orders.findByCustomerIdOrderByCreatedAtDesc(actor.id());
        return found.stream().map(o -> Views.OrderView.of(o, payments.findFirstByOrderIdOrderByCreatedAtDesc(o.getId()).orElse(null))).toList();
    }

    // Cancelar: la liberación va DESPUÉS del commit y fuera de la transacción, igual que el
    // inventario en PaymentService; la notificación sigue en la misma transacción que el estado
    // (en esta base funciona; el taller 06 muestra qué pasa cuando el aviso es un mensaje).
    public Views.OrderView cancel(Actor actor, UUID id) {
        var result = tx.execute(s -> {
            var order = visible(actor, orders.findForUpdate(id).orElseThrow(Errors.OrderNotFound::new));
            var payment = payments.findFirstByOrderIdOrderByCreatedAtDesc(id).orElse(null);
            if ("CANCELLED".equals(order.getStatus())) return new Object[]{Views.OrderView.of(order, payment), false};
            if ("PAID".equals(order.getStatus())) throw new Errors.OrderNotCancellable("PAID");
            order.setStatus("CANCELLED");
            events.cancelled(order);                           // taller 06
            notifications.save(new Notification(order.getId(), "ORDER_CANCELLED", order.getCustomerEmail()));
            return new Object[]{Views.OrderView.of(order, payment), true};
        });
        if ((boolean) result[1]) inventory.release(id);
        return (Views.OrderView) result[0];
    }

    static Order visible(Actor actor, Order order) {
        if (!actor.isOperator() && !order.getCustomerId().equals(actor.id())) throw new Errors.OrderNotFound();
        return order;
    }
}
