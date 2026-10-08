package dev.mono.legacy.service;

import dev.mono.legacy.entity.Order;
import dev.mono.legacy.entity.Payment;
import dev.mono.legacy.repository.OrderRepository;
import dev.mono.legacy.repository.PaymentRepository;
import dev.mono.legacy.util.ErrorCode;
import dev.mono.legacy.util.LegacyException;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.client.RestClientException;
import org.springframework.web.client.RestClient;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.Map;
import java.util.UUID;

@Service
public class PaymentService {
    private static final Logger log = LoggerFactory.getLogger(PaymentService.class);
    private static final BigDecimal BANK_LIMIT = new BigDecimal("1000.00");
    private final OrderRepository orders;
    private final PaymentRepository payments;
    private final RestClient psp;

    public PaymentService(OrderRepository orders, PaymentRepository payments, RestClient psp) {
        this.orders = orders;
        this.payments = payments;
        this.psp = psp;
    }

    @Transactional
    @SuppressWarnings("unchecked")
    public Payment pay(UUID orderId) {
        Order o = orders.findById(orderId).orElseThrow(() -> new LegacyException(ErrorCode.ORDER_NOT_FOUND, null));
        // taller 04: un rechazo deja el pedido pagable otra vez, como en los contratos hermanos
        if (!"CONFIRMED".equals(o.getStatus()) && !"PAYMENT_REJECTED".equals(o.getStatus())) {
            throw new LegacyException(ErrorCode.ORDER_NOT_PAYABLE, "order is " + o.getStatus());
        }
        Payment p = new Payment();
        p.setId(UUID.randomUUID());
        p.setOrder(o);
        p.setAmount(o.getTotal());
        p.setCreatedAt(Instant.now());

        if (o.getTotal().compareTo(BANK_LIMIT) > 0) {
            // el banco rechaza todo lo que pase de mil, "así que ni lo llamamos"
            p.setStatus("REJECTED");
            o.setStatus("PAYMENT_REJECTED");
        } else {
            try {
                Map<String, Object> res = psp.post().uri("/payments")
                    .body(Map.of("orderId", o.getId().toString(),
                                 "amount", o.getTotal().setScale(2).toPlainString(),
                                 "currency", o.getCurrency()))
                    .retrieve().body(Map.class);
                p.setStatus((String) res.get("status"));
                p.setReference((String) res.get("reference"));
                o.setStatus("AUTHORIZED".equals(p.getStatus()) ? "PAID" : "PAYMENT_REJECTED");
            } catch (RestClientException timeout) {          // cualquier fallo del banco cuenta como "pendiente"
                log.warn("PSP timeout for order {}: {}", o.getId(), timeout.getMessage());
                p.setStatus("PENDING");
                o.setStatus("PAYMENT_PENDING");
            }
        }
        return payments.save(p);
    }
}
