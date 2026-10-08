package dev.ms.monolith.service;

import dev.ms.monolith.entity.Notification;
import dev.ms.monolith.entity.Order;
import dev.ms.monolith.entity.OrderLine;
import dev.ms.monolith.entity.Product;
import dev.ms.monolith.inventory.Inventory;
import dev.ms.monolith.repository.NotificationRepository;
import dev.ms.monolith.repository.OrderRepository;
import dev.ms.monolith.repository.PaymentRepository;
import dev.ms.monolith.repository.ProductRepository;
import dev.ms.monolith.repository.UserRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.transaction.support.TransactionTemplate;
import tools.jackson.databind.json.JsonMapper;

import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.function.Function;
import java.util.stream.Collectors;

@Service
public class OrderService {

    public record LineRequest(String sku, int quantity) {}
    public record Created(int status, String body, boolean replay, String orderId) {}

    private final OrderRepository orders;
    private final ProductRepository products;
    private final Inventory inventory;
    private final PaymentRepository payments;
    private final NotificationRepository notifications;
    private final UserRepository users;
    private final Idempotency idempotency;
    private final TransactionTemplate tx;
    private final JsonMapper json;

    public OrderService(OrderRepository orders, ProductRepository products, Inventory inventory,
                        PaymentRepository payments, NotificationRepository notifications, UserRepository users,
                        Idempotency idempotency, TransactionTemplate tx, JsonMapper json) {
        this.orders = orders; this.products = products; this.inventory = inventory; this.payments = payments;
        this.notifications = notifications; this.users = users; this.idempotency = idempotency;
        this.tx = tx; this.json = json;
    }

    // El contrato v1 sigue siendo el mismo: 201 con el stock ya reservado, o 409 sin haber creado
    // nada. Lo que cambió es el orden: primero se reserva (en Inventory, sea local o remoto) y
    // después se guarda el pedido en una transacción corta. Si el guardado falla, se libera lo
    // reservado: sin transacción común, la atomicidad pasa a ser una compensación (talleres 08-09).
    public Created create(Actor actor, List<LineRequest> lines, String idempotencyKey) {
        var replay = tx.execute(s -> idempotency.lookup(idempotencyKey, actor, lines));
        if (replay.isPresent()) return new Created(200, replay.get().body(), true, null);

        Map<String, Product> catalog = products.findAllById(lines.stream().map(LineRequest::sku).distinct().toList())
            .stream().collect(Collectors.toMap(Product::getSku, Function.identity()));
        for (var line : lines) if (!catalog.containsKey(line.sku())) throw new Errors.ProductNotFound(line.sku());

        var orderId = UUID.randomUUID();
        try {
            inventory.reserve(orderId, lines.stream().map(l -> new Inventory.Line(l.sku(), l.quantity())).toList());
        } catch (Errors.InventoryUnavailable e) {
            // Un timeout no es un "no": inventory pudo retener y responder tarde (06/02 §9). Se
            // compensa con un release por la misma referencia, que es idempotente; si tampoco
            // llega, la retención queda huérfana hasta que caduque (taller 09).
            try { inventory.release(orderId); } catch (Errors.InventoryUnavailable ignored) { }
            throw e;
        }
        try {
            return tx.execute(s -> {
                var orderLines = lines.stream().map(l -> {
                    var p = catalog.get(l.sku());
                    return new OrderLine(l.sku(), p.getName(), l.quantity(), p.getUnitPrice());
                }).toList();
                var order = orders.save(new Order(orderId, actor.id(), orderLines));
                var view = Views.OrderView.of(order, null);
                idempotency.remember(idempotencyKey, actor, lines, 201, view);
                return new Created(201, json.writeValueAsString(view), false, orderId.toString());
            });
        } catch (RuntimeException e) {
            inventory.release(orderId);          // compensación: la reserva no puede quedar huérfana
            throw e;
        }
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

    // Cancelar libera la reserva y deja la notificación escrita en la MISMA transacción que el cambio
    // de estado. Aquí funciona porque todo es una base; el día que el aviso sea un mensaje a otro
    // servicio, esta forma de hacerlo pierde o inventa avisos (taller 06).
    @Transactional
    public Views.OrderView cancel(Actor actor, UUID id) {
        var order = visible(actor, orders.findForUpdate(id).orElseThrow(Errors.OrderNotFound::new));
        var payment = payments.findFirstByOrderIdOrderByCreatedAtDesc(id).orElse(null);
        switch (order.getStatus()) {
            case "CANCELLED" -> { return Views.OrderView.of(order, payment); }          // idempotente
            case "PAID" -> throw new Errors.OrderNotCancellable("PAID");
            default -> { }
        }
        inventory.release(order.getId());
        order.setStatus("CANCELLED");
        var recipient = users.findById(order.getCustomerId()).orElseThrow().getEmail();
        notifications.save(new Notification(order.getId(), "ORDER_CANCELLED", recipient));
        return Views.OrderView.of(order, payment);
    }

    static Order visible(Actor actor, Order order) {
        // el pedido de otro cliente es 404, no 403: no se revela que existe
        if (!actor.isOperator() && !order.getCustomerId().equals(actor.id())) throw new Errors.OrderNotFound();
        return order;
    }
}
