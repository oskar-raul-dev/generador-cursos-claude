package dev.mono.legacy.reports.internal;

import dev.mono.legacy.orders.OrderService;
import dev.mono.legacy.orders.OrderSnapshot;
import dev.mono.legacy.reports.web.SummaryView;
import dev.mono.legacy.shared.Money;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.TreeMap;

// "el lote de resumen": se calcula en cada petición recorriendo todos los pedidos
@Service
public class ReportService {
    private final OrderService orders;
    private final BatchRunRepository runs;

    public ReportService(OrderService orders, BatchRunRepository runs) {
        this.orders = orders;
        this.runs = runs;
    }

    // taller 06: lo que el controlador leía directamente del repositorio (ArchitectureTest)
    public Optional<BatchRun> batch(Long id) {
        return runs.findById(id);
    }

    @Transactional(readOnly = true)
    public SummaryView ordersSummary() {
        Map<String, int[]> counts = new TreeMap<>();
        Map<String, BigDecimal> open = new TreeMap<>();
        for (OrderSnapshot o : orders.snapshots()) {
            String customer = o.customerId().toString();
            int[] acc = counts.computeIfAbsent(customer, k -> new int[2]);
            acc[0]++;
            if ("CANCELLED".equals(o.status())) {
                acc[1]++;
            } else if (!"PAID".equals(o.status())) {
                open.merge(customer, o.total(), BigDecimal::add);
            }
        }
        List<SummaryView.Row> items = new ArrayList<>();
        counts.forEach((k, v) -> items.add(
            new SummaryView.Row(k, v[0], v[1], Money.of(open.getOrDefault(k, BigDecimal.ZERO), "USD"))));
        return new SummaryView(items);
    }
}
