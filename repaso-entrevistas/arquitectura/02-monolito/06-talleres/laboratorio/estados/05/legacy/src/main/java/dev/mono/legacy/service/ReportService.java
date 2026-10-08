package dev.mono.legacy.service;

import dev.mono.legacy.dto.Money;
import dev.mono.legacy.dto.SummaryView;
import dev.mono.legacy.entity.Order;
import dev.mono.legacy.repository.OrderRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.util.ArrayList;
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
    public SummaryView ordersSummary() {
        Map<String, int[]> counts = new TreeMap<>();
        Map<String, BigDecimal> open = new TreeMap<>();
        for (Order o : orders.findAll()) {
            String customer = o.getCustomer().getId().toString();          // un SELECT por pedido
            int[] acc = counts.computeIfAbsent(customer, k -> new int[2]);
            acc[0]++;
            if ("CANCELLED".equals(o.getStatus())) {
                acc[1]++;
            } else if (!"PAID".equals(o.getStatus())) {
                open.merge(customer, o.getTotal(), BigDecimal::add);
            }
        }
        List<SummaryView.Row> items = new ArrayList<>();
        counts.forEach((k, v) -> items.add(
            new SummaryView.Row(k, v[0], v[1], Money.of(open.getOrDefault(k, BigDecimal.ZERO), "USD"))));
        return new SummaryView(items);
    }
}
