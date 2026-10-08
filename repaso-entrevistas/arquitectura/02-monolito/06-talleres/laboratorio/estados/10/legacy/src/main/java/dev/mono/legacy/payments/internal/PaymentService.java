package dev.mono.legacy.payments.internal;

import dev.mono.legacy.idempotency.Idempotency;
import dev.mono.legacy.orders.OrderService;
import dev.mono.legacy.orders.OrderSnapshot;
import dev.mono.legacy.shared.ErrorCode;
import dev.mono.legacy.shared.LegacyException;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.transaction.support.TransactionTemplate;
import org.springframework.web.client.RestClient;
import org.springframework.web.client.RestClientException;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.Map;
import java.util.UUID;
import java.util.function.Function;

@Service
public class PaymentService {
    private static final Logger log = LoggerFactory.getLogger(PaymentService.class);
    private static final BigDecimal BANK_LIMIT = new BigDecimal("1000.00");
    private final OrderService orders;
    private final PaymentRepository payments;
    private final RestClient psp;
    private final TransactionTemplate tx;
    private final Idempotency idempotency;

    public PaymentService(OrderService orders, PaymentRepository payments, RestClient psp, TransactionTemplate tx,
                          Idempotency idempotency) {
        this.idempotency = idempotency;
        this.orders = orders;
        this.payments = payments;
        this.psp = psp;
        this.tx = tx;
    }

    public record Outcome(OrderSnapshot order, Payment payment) {}

    // Taller 07: tres pasos y dos transacciones cortas. La llamada al proveedor, que puede tardar
    // segundos, ocurre SIN transacción y sin conexión de la base.
    public Idempotency.Stored pay(UUID orderId, UUID actor, boolean operator, String key,
                                  Function<Outcome, String> render) {
        String fingerprint = "POST /api/v1/orders/" + orderId + "/payment";
        // 1. reclamar la clave, validar y registrar el intento (transacción corta)
        Object claimed = tx.execute(status -> {
            switch (idempotency.claim(actor, key, fingerprint)) {
                case Idempotency.Replay r -> { return r.stored(); }
                case Idempotency.InProgress p -> throw new LegacyException(ErrorCode.ORDER_NOT_PAYABLE, "order is PAYMENT_PENDING");
                case Idempotency.Fresh f -> { }
            }
            OrderSnapshot o = orders.startPayment(orderId, actor, operator);
            Payment attempt = new Payment();
            attempt.setId(UUID.randomUUID());
            attempt.setOrderId(o.id());
            attempt.setAmount(o.total());
            attempt.setStatus("PENDING");
            attempt.setOperationId(key);
            attempt.setCreatedAt(Instant.now());
            return payments.save(attempt);
        });
        if (claimed instanceof Idempotency.Stored replay) {
            return replay;                              // la misma clave ya se respondió: no se vuelve a cobrar
        }
        Payment p = (Payment) claimed;
        // 2. preguntar al proveedor, fuera de cualquier transacción
        String result = authorize(p);
        // 3. registrar el resultado (otra transacción corta)
        return tx.execute(status -> {
            Payment stored = payments.findById(p.getId()).orElseThrow();
            stored.setStatus(result);
            stored.setReference(p.getReference());
            String orderStatus = switch (result) {
                case "AUTHORIZED" -> "PAID";
                case "REJECTED" -> "PAYMENT_REJECTED";
                default -> "PAYMENT_PENDING";            // resultado incierto: un estado, no un error
            };
            var outcome = new Outcome(orders.recordPaymentOutcome(orderId, orderStatus), stored);
            return idempotency.complete(actor, key, new Idempotency.Stored(200, render.apply(outcome), null, false));
        });
    }

    @SuppressWarnings("unchecked")
    private String authorize(Payment p) {
        if (p.getAmount().compareTo(BANK_LIMIT) > 0) {
            return "REJECTED";                          // el banco rechaza todo lo que pase de mil, "así que ni lo llamamos"
        }
        try {
            Map<String, Object> res = psp.post().uri("/payments")
                .header("Idempotency-Key", p.getOperationId())    // la misma clave, también para el banco
                .body(Map.of("orderId", p.getOrderId().toString(),
                             "amount", p.getAmount().setScale(2).toPlainString(),
                             "currency", "USD"))
                .retrieve().body(Map.class);
            p.setReference((String) res.get("reference"));
            return (String) res.get("status");
        } catch (RestClientException timeout) {          // cualquier fallo del banco cuenta como "pendiente"
            log.warn("PSP timeout for order {}: {}", p.getOrderId(), timeout.getMessage());
            return "PENDING";
        }
    }
}
