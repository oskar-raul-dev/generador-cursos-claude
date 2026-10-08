package dev.mono.legacy.dto;

import dev.mono.legacy.entity.Order;
import dev.mono.legacy.entity.Payment;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.Comparator;
import java.util.List;
import java.util.UUID;

// Lo que el contrato dice de un pedido. Sustituye a la entidad Order serializada tal cual (que
// arrastraba al cliente con su passwordHash y las listas perezosas de Hibernate).
public record OrderView(UUID id, UUID customerId, String status, List<Line> lines, Money total,
                        PaymentView payment, Instant createdAt) {

    public record Line(String sku, String name, int quantity, Money unitPrice, Money lineTotal) {}

    public static OrderView from(Order o) {
        var lines = o.getLines().stream()
            .map(l -> new Line(l.getSku(), l.getProductName(), l.getQuantity(),
                               Money.of(l.getUnitPrice(), o.getCurrency()),
                               Money.of(l.getUnitPrice().multiply(BigDecimal.valueOf(l.getQuantity())), o.getCurrency())))
            .toList();
        Payment last = o.getPayments().stream().max(Comparator.comparing(Payment::getCreatedAt)).orElse(null);
        return new OrderView(o.getId(), o.getCustomer().getId(), o.getStatus(), lines,
                             Money.of(o.getTotal(), o.getCurrency()), PaymentView.from(last), o.getCreatedAt());
    }
}
