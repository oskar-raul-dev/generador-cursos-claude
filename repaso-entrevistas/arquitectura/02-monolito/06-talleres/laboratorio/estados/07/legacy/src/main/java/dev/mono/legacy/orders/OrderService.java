package dev.mono.legacy.orders;

import dev.mono.legacy.auth.Customers;
import dev.mono.legacy.inventory.InventoryService;
import dev.mono.legacy.inventory.ReservedStock;
import dev.mono.legacy.notifications.Notifications;
import dev.mono.legacy.orders.internal.Order;
import dev.mono.legacy.orders.internal.OrderCache;
import dev.mono.legacy.orders.internal.OrderLine;
import dev.mono.legacy.orders.internal.OrderRepository;
import dev.mono.legacy.orders.web.CreateOrderRequest;
import dev.mono.legacy.shared.ErrorCode;
import dev.mono.legacy.shared.LegacyException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.Comparator;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.stream.IntStream;

// API de orders. Lo que antes estaba repartido entre OrderController, OrderService y el trigger de la
// base vive ahora aquí (la regla de cancelación) y en inventory (el stock).
@Service
public class OrderService {
    private final OrderRepository orders;
    private final InventoryService inventory;
    private final Customers customers;
    private final Notifications notifications;
    private final OrderCache cache;

    public OrderService(OrderRepository orders, InventoryService inventory, Customers customers,
                        Notifications notifications, OrderCache cache) {
        this.orders = orders;
        this.inventory = inventory;
        this.customers = customers;
        this.notifications = notifications;
        this.cache = cache;
    }

    @Transactional
    public Order create(UUID customerId, List<CreateOrderRequest.Line> lines) {
        Order order = new Order();
        order.setId(UUID.randomUUID());
        order.setCustomerId(customerId);
        order.setStatus("CONFIRMED");
        order.setCreatedAt(Instant.now());
        // taller 07: se reserva en orden de SKU, no en el del pedido. Dos pedidos con las mismas
        // líneas en distinto orden bloquearían las filas al revés y se esperarían para siempre.
        List<Integer> lockOrder = IntStream.range(0, lines.size()).boxed()
            .sorted(Comparator.comparing(i -> lines.get(i).sku())).toList();
        ReservedStock[] reservedByLine = new ReservedStock[lines.size()];
        for (int i : lockOrder) {
            try {
                reservedByLine[i] = inventory.reserve(lines.get(i).sku(), lines.get(i).quantity());
            } catch (LegacyException e) {
                if (e.code() != ErrorCode.INSUFFICIENT_INVENTORY) {
                    throw e;
                }
                // el contrato dice qué línea falló; la cantidad pedida y la disponible van en el mensaje
                throw new LegacyException(e.code(), e.getMessage(), List.of(Map.of(
                    "field", "lines[" + i + "].quantity",
                    "message", e.getMessage().substring(e.getMessage().indexOf(": ") + 2))));
            }
        }
        BigDecimal total = BigDecimal.ZERO;
        for (int i = 0; i < lines.size(); i++) {            // las líneas, en el orden del pedido
            String sku = lines.get(i).sku();
            int qty = lines.get(i).quantity();
            ReservedStock reserved = reservedByLine[i];
            OrderLine line = new OrderLine();
            line.setOrder(order);
            line.setSku(sku);
            line.setProductName(reserved.name());
            line.setQuantity(qty);
            line.setUnitPrice(reserved.unitPrice());
            order.getLines().add(line);
            total = total.add(reserved.unitPrice().multiply(BigDecimal.valueOf(qty)));
        }
        order.setTotal(total);
        return orders.save(order);
    }

    public Order findEntity(UUID id) {
        Order cached = cache.get(id);
        if (cached != null) {
            return cached;
        }
        return orders.findWithLinesById(id).orElse(null);
    }

    // el pedido de otro cliente responde igual que uno inexistente: no se revela que existe
    public Order findVisible(UUID id, UUID actor, boolean operator) {
        return visible(findEntity(id), actor, operator);
    }

    private static Order visible(Order o, UUID actor, boolean operator) {
        if (o == null || (!operator && !o.getCustomerId().equals(actor))) {
            throw new LegacyException(ErrorCode.ORDER_NOT_FOUND, null);
        }
        return o;
    }

    public List<Order> list(UUID customerId, boolean operator) {
        return operator ? orders.findAllByOrderByCreatedAtDesc() : orders.findByCustomerIdOrderByCreatedAtDesc(customerId);
    }

    public List<OrderSnapshot> snapshots() {
        return orders.findAll().stream().map(OrderService::toSnapshot).toList();
    }

    // Taller 07: empezar un pago bloquea la fila del pedido (SELECT ... FOR UPDATE) y lo pasa a
    // PAYMENT_PENDING en la misma transacción: dos intentos a la vez no pueden ver los dos CONFIRMED.
    @Transactional
    public OrderSnapshot startPayment(UUID id, UUID actor, boolean operator) {
        Order o = visible(orders.findForUpdateById(id).orElse(null), actor, operator);
        // un rechazo deja el pedido pagable otra vez, como en los contratos hermanos
        if (!"CONFIRMED".equals(o.getStatus()) && !"PAYMENT_REJECTED".equals(o.getStatus())) {
            throw new LegacyException(ErrorCode.ORDER_NOT_PAYABLE, "order is " + o.getStatus());
        }
        o.setStatus("PAYMENT_PENDING");
        return toSnapshot(o);
    }

    // taller 06: payments ya no escribe el estado del pedido por su cuenta; se lo pide a su dueño
    @Transactional
    public OrderSnapshot recordPaymentOutcome(UUID id, String newStatus) {
        Order o = orders.findById(id).orElseThrow(() -> new LegacyException(ErrorCode.ORDER_NOT_FOUND, null));
        o.setStatus(newStatus);
        return toSnapshot(o);
    }

    // taller 06: la regla, el estado y el stock en el mismo sitio (antes: controlador, servicio y trigger)
    @Transactional
    public Order cancel(UUID id) {
        Order o = orders.findWithLinesById(id).orElseThrow(() -> new LegacyException(ErrorCode.ORDER_NOT_FOUND, null));
        if ("PAID".equals(o.getStatus())) {                 // taller 06: antes vivía en el controlador
            throw new LegacyException(ErrorCode.ORDER_NOT_CANCELLABLE, "order is PAID");
        }
        if ("CANCELLED".equals(o.getStatus())) {
            return o;
        }
        o.setStatus("CANCELLED");
        o.getLines().forEach(l -> inventory.release(l.getSku(), l.getQuantity()));
        notifications.orderCancelled(o.getId(), customers.emailOf(o.getCustomerId()));
        return o;
    }

    // lo que el cierre diario hacía a mano con la caché de pedidos
    public int warmCache(Instant since) {
        List<Order> recent = orders.findByCreatedAtAfter(since);
        cache.clear();
        recent.forEach(cache::put);
        return recent.size();
    }

    private static OrderSnapshot toSnapshot(Order o) {
        return new OrderSnapshot(o.getId(), o.getCustomerId(), o.getStatus(), o.getTotal(), o.getCurrency(),
                                 o.getCreatedAt());
    }
}
