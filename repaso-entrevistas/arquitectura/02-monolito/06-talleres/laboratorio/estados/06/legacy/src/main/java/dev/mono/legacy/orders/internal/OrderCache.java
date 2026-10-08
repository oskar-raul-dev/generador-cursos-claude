package dev.mono.legacy.orders.internal;

import org.springframework.stereotype.Component;

import java.util.Map;
import java.util.UUID;
import java.util.concurrent.ConcurrentHashMap;

// caché de pedidos para que GET /orders/{id} "no pegue a la base"; la llena el cierre diario
@Component
public class OrderCache {
    private final Map<UUID, Order> byId = new ConcurrentHashMap<>();

    public Order get(UUID id) { return byId.get(id); }

    public void put(Order order) { byId.put(order.getId(), order); }

    public void clear() { byId.clear(); }

    public int size() { return byId.size(); }
}
