package dev.ms.orders.web;

import dev.ms.orders.config.OrdersProperties;
import dev.ms.orders.repository.OrderRepository;
import org.springframework.http.ResponseEntity;
import org.springframework.http.client.JdkClientHttpRequestFactory;
import org.springframework.jdbc.core.simple.JdbcClient;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.client.RestClient;
import org.springframework.web.client.RestClientException;
import org.springframework.web.util.UriBuilder;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.net.http.HttpClient;
import java.time.Duration;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;

// "Mis pedidos con su estado de pago" (taller 11), de dos maneras, para compararlas con los mismos datos:
//   composition  mis pedidos (base de orders) + el estado REAL de cada pago (payments, en una llamada por lote)
//   projection   una consulta a order_overview / customer_overview, que mantiene OverviewProjector
// Server-Timing dice cuánto tardó cada una; `degraded` dice si la composición tuvo que seguir sin payments.
@RestController
public class OverviewController {

    public record Item(String orderId, String status, String paymentStatus, String total) {}
    public record Overview(String source, List<Item> items, int paidOrders, String paidAmount, boolean degraded) {}
    record PaymentRow(String orderId, String status, String amount) {}
    record PaymentList(List<PaymentRow> items) {}

    private final OrderRepository orders;
    private final JdbcClient jdbc;
    private final RestClient payments;

    public OverviewController(OrderRepository orders, JdbcClient jdbc, RestClient.Builder builder, OrdersProperties props) {
        this.orders = orders; this.jdbc = jdbc;
        var factory = new JdkClientHttpRequestFactory(HttpClient.newBuilder().version(HttpClient.Version.HTTP_1_1).build());
        factory.setReadTimeout(Duration.ofMillis(props.overview().compositionTimeoutMs()));
        this.payments = builder.baseUrl(props.payments().baseUrl()).requestFactory(factory).build();
    }

    @GetMapping("/api/v2/orders/overview")
    ResponseEntity<Overview> overview(@RequestHeader(name = "x-jwt-payload", required = false) String payload,
                                      @RequestParam(defaultValue = "projection") String source) {
        var actor = ActorResolver.from(payload);
        var t0 = System.nanoTime();
        var view = "composition".equals(source) ? compose(actor.id()) : project(actor.id());
        var ms = (System.nanoTime() - t0) / 1e6;
        return ResponseEntity.ok().header("Server-Timing", source + ";dur=" + String.format(java.util.Locale.ROOT, "%.1f", ms)).body(view);
    }

    private Overview compose(UUID customer) {
        var mine = orders.findByCustomerIdOrderByCreatedAtDesc(customer);
        Map<String, PaymentRow> byOrder = new HashMap<>();
        var degraded = false;
        if (!mine.isEmpty()) {
            try {
                // UNA llamada con todos los pedidos (?orderId=…&orderId=…): uno a uno sería el N+1 de 02/02
                var list = payments.get().uri((UriBuilder u) -> {
                    var b = u.path("/payments");
                    mine.forEach(o -> b.queryParam("orderId", o.getId()));
                    return b.build();
                }).retrieve().body(PaymentList.class);
                list.items().forEach(p -> byOrder.put(p.orderId(), p));   // ordenados por fecha: gana el último
            } catch (RestClientException e) {
                degraded = true;                                         // sin payments: pedidos sí, pagos "UNKNOWN"
            }
        }
        var paid = BigDecimal.ZERO;
        var paidOrders = 0;
        var items = new java.util.ArrayList<Item>();
        for (var o : mine) {
            var p = byOrder.get(o.getId().toString());
            var paymentStatus = degraded ? "UNKNOWN" : p == null ? null : p.status();
            if ("AUTHORIZED".equals(paymentStatus)) { paid = paid.add(new BigDecimal(p.amount())); paidOrders++; }
            items.add(new Item(o.getId().toString(), o.getStatus(), paymentStatus, money(o.getTotalAmount())));
        }
        return new Overview("composition", items, paidOrders, money(paid), degraded);
    }

    private Overview project(UUID customer) {
        var items = jdbc.sql("""
                SELECT order_id, status, payment_status, total_amount FROM order_overview
                 WHERE customer_id = ? ORDER BY placed_at DESC""")
            .param(customer)
            .query((rs, n) -> new Item(rs.getString(1), rs.getString(2), rs.getString(3), money(rs.getBigDecimal(4))))
            .list();
        var summary = jdbc.sql("SELECT paid_orders, paid_amount FROM customer_overview WHERE customer_id = ?")
            .param(customer).query((rs, n) -> new Object[]{rs.getInt(1), rs.getBigDecimal(2)}).optional()
            .orElse(new Object[]{0, BigDecimal.ZERO});
        return new Overview("projection", items, (int) summary[0], money((BigDecimal) summary[1]), false);
    }

    private static String money(BigDecimal amount) { return amount.setScale(2, RoundingMode.HALF_UP).toPlainString(); }
}
