package dev.mono.legacy.service;

import dev.mono.legacy.dto.Money;
import dev.mono.legacy.dto.SummaryView;
import dev.mono.legacy.entity.Order;
import dev.mono.legacy.repository.OrderRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

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
        List<SummaryView.Row> items = new ArrayList<>();
        byCustomer.forEach((k, v) -> items.add(new SummaryView.Row(k, (int) v[0], (int) v[1], Money.of(v[2], "USD"))));
        return new SummaryView(items);
    }
}
