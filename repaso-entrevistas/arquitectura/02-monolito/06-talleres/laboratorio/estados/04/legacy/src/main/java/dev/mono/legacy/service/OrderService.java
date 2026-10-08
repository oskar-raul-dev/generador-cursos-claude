package dev.mono.legacy.service;

import dev.mono.legacy.dto.CreateOrderRequest;
import dev.mono.legacy.entity.Notification;
import dev.mono.legacy.entity.Order;
import dev.mono.legacy.entity.OrderLine;
import dev.mono.legacy.entity.Product;
import dev.mono.legacy.repository.NotificationRepository;
import dev.mono.legacy.repository.OrderRepository;
import dev.mono.legacy.repository.UserRepository;
import dev.mono.legacy.util.ErrorCode;
import dev.mono.legacy.util.LegacyException;
import dev.mono.legacy.util.OrderCache;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.List;
import java.util.Map;
import java.util.UUID;

@Service
public class OrderService {
    private final OrderRepository orders;
    private final UserRepository users;
    private final NotificationRepository notifications;
    private final OrderCache cache;

    @Autowired                                // el ciclo con InventoryService solo arranca así
    private InventoryService inventory;

    public OrderService(OrderRepository orders, UserRepository users, NotificationRepository notifications,
                        OrderCache cache) {
        this.orders = orders;
        this.users = users;
        this.notifications = notifications;
        this.cache = cache;
    }

    @Transactional
    public Order create(UUID customerId, List<CreateOrderRequest.Line> lines) {
        Order order = new Order();
        order.setId(UUID.randomUUID());
        order.setCustomer(users.getReferenceById(customerId));
        order.setStatus("CONFIRMED");
        order.setCreatedAt(Instant.now());
        double total = 0;
        for (int i = 0; i < lines.size(); i++) {
            String sku = lines.get(i).sku();
            int qty = lines.get(i).quantity();
            Product p;
            try {
                p = inventory.take(sku, qty);
            } catch (LegacyException e) {
                if (e.code() != ErrorCode.INSUFFICIENT_INVENTORY) {
                    throw e;
                }
                // el contrato dice qué línea falló; la cantidad pedida y la disponible van en el mensaje
                throw new LegacyException(e.code(), e.getMessage(), List.of(Map.of(
                    "field", "lines[" + i + "].quantity",
                    "message", e.getMessage().substring(e.getMessage().indexOf(": ") + 2))));
            }
            OrderLine line = new OrderLine();
            line.setOrder(order);
            line.setSku(sku);
            line.setProductName(p.getName());
            line.setQuantity(qty);
            line.setUnitPrice(p.getPrice());
            order.getLines().add(line);
            total += p.getPrice() * qty;
        }
        order.setTotal(total);
        return orders.save(order);
    }

    public Order findEntity(UUID id) {
        Order cached = cache.get(id);
        if (cached != null) {
            return cached;
        }
        return orders.findById(id).orElse(null);
    }

    public List<Order> list(UUID customerId, boolean operator) {
        return operator ? orders.findAllByOrderByCreatedAtDesc() : orders.findByCustomerIdOrderByCreatedAtDesc(customerId);
    }

    // el estado cambia aquí; el stock lo devuelve un trigger de la base
    @Transactional
    public Order cancel(UUID id) {
        Order o = orders.findById(id).orElseThrow(() -> new LegacyException(ErrorCode.ORDER_NOT_FOUND, null));
        if ("CANCELLED".equals(o.getStatus())) {
            return o;
        }
        o.setStatus("CANCELLED");
        Notification n = new Notification();
        n.setId(UUID.randomUUID());
        n.setOrderId(o.getId());
        n.setType("ORDER_CANCELLED");
        n.setRecipient(o.getCustomer().getEmail());
        n.setCreatedAt(Instant.now());
        notifications.save(n);
        return o;
    }
}
