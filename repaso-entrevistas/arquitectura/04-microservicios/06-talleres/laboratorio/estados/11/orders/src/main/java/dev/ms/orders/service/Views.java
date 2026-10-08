package dev.ms.orders.service;

import dev.ms.orders.entity.Notification;
import dev.ms.orders.entity.Order;
import dev.ms.orders.entity.Payment;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.util.List;

// La forma JSON del contrato (openapi.yaml). El dinero viaja como texto con dos decimales.
public final class Views {
    private Views() {}

    public record Money(String amount, String currency) {
        public static Money of(BigDecimal amount, String currency) {
            return new Money(amount.setScale(2, RoundingMode.UNNECESSARY).toPlainString(), currency);
        }
    }
    public record ProductView(String sku, String name, Money unitPrice, int stock) {}
    public record LineView(String sku, String name, int quantity, Money unitPrice, Money lineTotal) {}
    public record PaymentView(String status, String operationId, String reference) {
        static PaymentView of(Payment p) { return p == null ? null : new PaymentView(p.getStatus(), p.getOperationId(), p.getReference()); }
    }
    public record OrderView(String id, String customerId, String status, List<LineView> lines, Money total,
                            PaymentView payment, String createdAt) {
        public static OrderView of(Order o, Payment p) {
            var lines = o.getLines().stream().map(l -> new LineView(l.getSku(), l.getProductName(), l.getQuantity(),
                Money.of(l.getUnitPrice(), o.getCurrency()), Money.of(l.lineTotal(), o.getCurrency()))).toList();
            return new OrderView(o.getId().toString(), o.getCustomerId().toString(), o.getStatus(), lines,
                Money.of(o.getTotalAmount(), o.getCurrency()), PaymentView.of(p), o.getCreatedAt().toString());
        }
    }
    public record PaymentResponse(String orderId, String orderStatus, PaymentView payment) {}
    public record NotificationView(String id, String orderId, String type, String recipient, String createdAt) {
        public static NotificationView of(Notification n) {
            return new NotificationView(n.getId().toString(), n.getOrderId().toString(), n.getType(),
                n.getRecipient(), n.getCreatedAt().toString());
        }
    }
    public record Items<T>(List<T> items) {}
    public record TokenResponse(String accessToken, String tokenType, long expiresIn) {}
}
