package dev.mono.legacy.service;

import dev.mono.legacy.entity.Order;
import dev.mono.legacy.repository.OrderRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.TreeMap;

// "el lote de resumen": se calcula en cada petición recorriendo todos los pedidos
@Service
public class ReportService {
    private final OrderRepository orders;

    public ReportService(OrderRepository orders) {
        this.orders = orders;
    }

    @Transactional(readOnly = true)
    public Map<String, Object> ordersSummary() {
        Map<String, double[]> byCustomer = new TreeMap<>();
        for (Order o : orders.findAll()) {
            String customer = o.getCustomer().getId().toString();          // un SELECT por pedido
            double[] acc = byCustomer.computeIfAbsent(customer, k -> new double[3]);
            acc[0]++;
            if ("CANCELLED".equals(o.getStatus())) {
                acc[1]++;
            } else if (!"PAID".equals(o.getStatus())) {
                acc[2] += o.getTotal();
            }
        }
        List<Map<String, Object>> items = new ArrayList<>();
        byCustomer.forEach((k, v) -> {
            Map<String, Object> row = new LinkedHashMap<>();
            row.put("customerId", k);
            row.put("ordersCreated", (int) v[0]);
            row.put("ordersCancelled", (int) v[1]);
            row.put("openAmount", v[2]);
            items.add(row);
        });
        return Map.of("items", items);
    }
}
