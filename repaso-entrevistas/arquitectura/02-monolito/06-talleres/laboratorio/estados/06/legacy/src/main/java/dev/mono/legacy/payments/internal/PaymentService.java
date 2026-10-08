package dev.mono.legacy.payments.internal;

import dev.mono.legacy.orders.OrderService;
import dev.mono.legacy.orders.OrderSnapshot;
import dev.mono.legacy.shared.ErrorCode;
import dev.mono.legacy.shared.LegacyException;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.client.RestClient;
import org.springframework.web.client.RestClientException;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.Map;
import java.util.UUID;

@Service
public class PaymentService {
    private static final Logger log = LoggerFactory.getLogger(PaymentService.class);
    private static final BigDecimal BANK_LIMIT = new BigDecimal("1000.00");
    private final OrderService orders;
    private final PaymentRepository payments;
    private final RestClient psp;

    public PaymentService(OrderService orders, PaymentRepository payments, RestClient psp) {
        this.orders = orders;
        this.payments = payments;
        this.psp = psp;
    }

    public record Outcome(OrderSnapshot order, Payment payment) {}

    // el proveedor se sigue llamando DENTRO de la transacción: lo corrige el taller 07
    @Transactional
    @SuppressWarnings("unchecked")
    public Outcome pay(UUID orderId, UUID actor, boolean operator) {
        OrderSnapshot o = orders.snapshot(orderId, actor, operator);
        // un rechazo deja el pedido pagable otra vez, como en los contratos hermanos
        if (!"CONFIRMED".equals(o.status()) && !"PAYMENT_REJECTED".equals(o.status())) {
            throw new LegacyException(ErrorCode.ORDER_NOT_PAYABLE, "order is " + o.status());
        }
        Payment p = new Payment();
        p.setId(UUID.randomUUID());
        p.setOrderId(o.id());
        p.setAmount(o.total());
        p.setCreatedAt(Instant.now());

        String orderStatus;
        if (o.total().compareTo(BANK_LIMIT) > 0) {
            // el banco rechaza todo lo que pase de mil, "así que ni lo llamamos"
            p.setStatus("REJECTED");
            orderStatus = "PAYMENT_REJECTED";
        } else {
            try {
                Map<String, Object> res = psp.post().uri("/payments")
                    .body(Map.of("orderId", o.id().toString(),
                                 "amount", o.total().setScale(2).toPlainString(),
                                 "currency", o.currency()))
                    .retrieve().body(Map.class);
                p.setStatus((String) res.get("status"));
                p.setReference((String) res.get("reference"));
                orderStatus = "AUTHORIZED".equals(p.getStatus()) ? "PAID" : "PAYMENT_REJECTED";
            } catch (RestClientException timeout) {          // cualquier fallo del banco cuenta como "pendiente"
                log.warn("PSP timeout for order {}: {}", o.id(), timeout.getMessage());
                p.setStatus("PENDING");
                orderStatus = "PAYMENT_PENDING";
            }
        }
        payments.save(p);
        return new Outcome(orders.recordPaymentOutcome(o.id(), orderStatus), p);
    }
}
