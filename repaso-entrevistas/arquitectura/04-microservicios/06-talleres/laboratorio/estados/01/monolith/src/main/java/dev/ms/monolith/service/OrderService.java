package dev.ms.monolith.service;

import dev.ms.monolith.entity.Notification;
import dev.ms.monolith.entity.Order;
import dev.ms.monolith.entity.OrderLine;
import dev.ms.monolith.entity.Reservation;
import dev.ms.monolith.repository.InventoryRepository;
import dev.ms.monolith.repository.NotificationRepository;
import dev.ms.monolith.repository.OrderRepository;
import dev.ms.monolith.repository.PaymentRepository;
import dev.ms.monolith.repository.ProductRepository;
import dev.ms.monolith.repository.ReservationRepository;
import dev.ms.monolith.repository.UserRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.ArrayList;
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
    private final InventoryRepository inventory;
    private final ReservationRepository reservations;
    private final PaymentRepository payments;
    private final NotificationRepository notifications;
    private final UserRepository users;
    private final Idempotency idempotency;
    private final tools.jackson.databind.json.JsonMapper json;

    public OrderService(OrderRepository orders, ProductRepository products, InventoryRepository inventory,
                        ReservationRepository reservations, PaymentRepository payments,
                        NotificationRepository notifications, UserRepository users, Idempotency idempotency,
                        tools.jackson.databind.json.JsonMapper json) {
        this.orders = orders; this.products = products; this.inventory = inventory; this.reservations = reservations;
        this.payments = payments; this.notifications = notifications; this.users = users;
        this.idempotency = idempotency; this.json = json;
    }

    // Crear el pedido Y reservar el stock en el mismo acto, en una transacción: el contrato v1
    // responde 201 con el stock ya apartado, o 409 sin haber creado nada.
    @Transactional
    public Created create(Actor actor, List<LineRequest> lines, String idempotencyKey) {
        var replay = idempotency.lookup(idempotencyKey, actor, lines);
        if (replay.isPresent()) return new Created(200, replay.get().body(), true, null);

        var skus = lines.stream().map(LineRequest::sku).distinct().toList();
        Map<String, ProductRepository.ProductStock> stock = products.lockForOrder(skus).stream()
            .collect(Collectors.toMap(ProductRepository.ProductStock::getSku, Function.identity()));

        var orderLines = new ArrayList<OrderLine>();
        for (int i = 0; i < lines.size(); i++) {
            var line = lines.get(i);
            var product = stock.get(line.sku());
            if (product == null) throw new Errors.ProductNotFound(line.sku());
            if (product.getAvailable() < line.quantity())
                throw new Errors.InsufficientInventory(line.sku(), i, line.quantity(), product.getAvailable());
            orderLines.add(new OrderLine(line.sku(), product.getName(), line.quantity(), product.getUnitPrice()));
        }

        var order = orders.save(new Order(UUID.randomUUID(), actor.id(), orderLines));
        for (var line : orderLines) {
            inventory.findById(line.getSku()).orElseThrow().take(line.getQuantity());
            reservations.save(new Reservation(order.getId(), line.getSku(), line.getQuantity()));
        }
        var view = Views.OrderView.of(order, null);
        idempotency.remember(idempotencyKey, actor, lines, 201, view);
        return new Created(201, json.writeValueAsString(view), false, order.getId().toString());
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
        releaseReservations(order.getId());
        order.setStatus("CANCELLED");
        var recipient = users.findById(order.getCustomerId()).orElseThrow().getEmail();
        notifications.save(new Notification(order.getId(), "ORDER_CANCELLED", recipient));
        return Views.OrderView.of(order, payment);
    }

    public void releaseReservations(UUID orderId) {
        for (var r : reservations.findByOrderIdAndStatus(orderId, "RESERVED")) {
            inventory.findById(r.getSku()).orElseThrow().giveBack(r.getQuantity());
            r.setStatus("RELEASED");
        }
    }

    public void consumeReservations(UUID orderId) {
        reservations.findByOrderIdAndStatus(orderId, "RESERVED").forEach(r -> r.setStatus("CONSUMED"));
    }

    static Order visible(Actor actor, Order order) {
        // el pedido de otro cliente es 404, no 403: no se revela que existe
        if (!actor.isOperator() && !order.getCustomerId().equals(actor.id())) throw new Errors.OrderNotFound();
        return order;
    }
}
