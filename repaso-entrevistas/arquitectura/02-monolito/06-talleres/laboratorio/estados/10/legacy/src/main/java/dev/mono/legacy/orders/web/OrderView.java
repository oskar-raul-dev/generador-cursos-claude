package dev.mono.legacy.orders.web;

import dev.mono.legacy.orders.PaymentLookup;
import dev.mono.legacy.orders.internal.Order;
import dev.mono.legacy.shared.Money;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.List;
import java.util.UUID;

// Lo que el contrato dice de un pedido. El último pago llega por el puerto PaymentLookup.
public record OrderView(UUID id, UUID customerId, String status, List<Line> lines, Money total,
                        Payment payment, Instant createdAt) {

    public record Line(String sku, String name, int quantity, Money unitPrice, Money lineTotal) {}

    public record Payment(String status, String operationId, String reference) {}

    public static OrderView from(Order o, PaymentLookup payments) {
        var lines = o.getLines().stream()
            .map(l -> new Line(l.getSku(), l.getProductName(), l.getQuantity(),
                               Money.of(l.getUnitPrice(), o.getCurrency()),
                               Money.of(l.getUnitPrice().multiply(BigDecimal.valueOf(l.getQuantity())), o.getCurrency())))
            .toList();
        var last = payments.latestFor(o.getId())
            .map(p -> new Payment(p.status(), p.operationId(), p.reference())).orElse(null);
        return new OrderView(o.getId(), o.getCustomerId(), o.getStatus(), lines,
                             Money.of(o.getTotal(), o.getCurrency()), last, o.getCreatedAt());
    }
}
