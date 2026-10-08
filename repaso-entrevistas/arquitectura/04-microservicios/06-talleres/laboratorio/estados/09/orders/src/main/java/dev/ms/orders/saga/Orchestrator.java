package dev.ms.orders.saga;

import dev.ms.orders.config.OrdersProperties;
import dev.ms.orders.entity.Order;
import dev.ms.orders.entity.Payment;
import dev.ms.orders.events.OrderEvents;
import dev.ms.orders.inventory.Inventory;
import dev.ms.orders.payments.Payments;
import dev.ms.orders.repository.OrderRepository;
import dev.ms.orders.repository.PaymentRepository;
import dev.ms.orders.service.Errors;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;
import org.springframework.transaction.support.TransactionTemplate;

import java.time.Duration;
import java.util.UUID;

// La misma saga que 06/08, con dueño (taller 09). orders decide el ORDEN y las COMPENSACIONES; las
// reglas de cada paso siguen en su servicio (¿hay stock?: inventory; ¿se cobra?: payments y el PSP).
//
//   RESERVE_INVENTORY ──ok──► AUTHORIZE_PAYMENT ──AUTHORIZED──► COMMIT_INVENTORY ──► DONE   (PAID)
//        │ sin stock                │ REJECTED ─────────────────► RELEASE_INVENTORY ──► DONE   (PAYMENT_REJECTED)
//        ▼                          │ payments caído y plazo vencido ► RELEASE_INVENTORY ► DONE (CANCELLED)
//      DONE (CANCELLED)             │ PENDING: reintentar con LA MISMA clave; plazo vencido ► ESCALATED (PAYMENT_PENDING)
//
// El cobro es el pivote: después de AUTHORIZED ya no se compensa, solo se reintenta (COMMIT_INVENTORY).
// Los comandos ReserveInventory, AuthorizePayment y ReleaseInventory viajan por las interfaces que ya
// existían (gRPC y HTTP): lo que hace orquestación a esto no es la mensajería, es el estado y el tiempo.
@Component
@ConditionalOnProperty(name = "ms.saga.mode", havingValue = "orchestration")
public class Orchestrator {

    private static final Logger log = LoggerFactory.getLogger(Orchestrator.class);
    private static final Duration LEASE = Duration.ofSeconds(30);

    private final SagaStore sagas;
    private final OrderRepository orders;
    private final PaymentRepository payments;
    private final Inventory inventory;
    private final Payments psp;
    private final OrderEvents events;
    private final TransactionTemplate tx;
    private final int deadline;

    public Orchestrator(SagaStore sagas, OrderRepository orders, PaymentRepository payments, Inventory inventory,
                        Payments psp, OrderEvents events, TransactionTemplate tx, OrdersProperties props) {
        this.sagas = sagas; this.orders = orders; this.payments = payments; this.inventory = inventory;
        this.psp = psp; this.events = events; this.tx = tx; this.deadline = props.saga().stepDeadlineSeconds();
    }

    @Scheduled(fixedDelayString = "${ms.saga.poll-ms}")
    public void tick() {
        var due = tx.execute(s -> sagas.claim(10, LEASE));
        for (var d : due) {
            try {
                run(d);
            } catch (RuntimeException e) {                  // un fallo inesperado no para al resto
                log.error("saga {} {}: {}", d.orderId(), d.step(), e.toString());
                tx.executeWithoutResult(s -> sagas.retryLater(d.orderId(), d.step(), d.attempts(), e.toString()));
            }
        }
    }

    private void run(SagaStore.Due d) {
        var id = d.orderId();
        var order = tx.execute(s -> orders.findById(id).orElseThrow());
        switch (d.step()) {
            case "RESERVE_INVENTORY" -> {                    // comando ReserveInventory
                try {
                    inventory.reserve(id, order.getLines().stream().map(l -> new Inventory.Line(l.getSku(), l.getQuantity())).toList());
                    move(id, "CONFIRMED", "AUTHORIZE_PAYMENT", "reserved");
                } catch (Errors.InsufficientInventory e) {
                    move(id, "CANCELLED", "DONE", "out of stock");
                } catch (Errors.InventoryUnavailable e) {
                    // un timeout no es un "no": inventory pudo retener. Vencido el plazo, se compensa por si acaso
                    if (d.expired()) move(id, "CANCELLED", "RELEASE_INVENTORY", "inventory unavailable until deadline");
                    else later(d, e.getMessage());
                }
            }
            case "AUTHORIZE_PAYMENT" -> {                    // comando AuthorizePayment, con la clave de la saga
                try {
                    var r = psp.authorize(id, order.getTotalAmount(), "saga-" + id);
                    recordPayment(order, "saga-" + id, r);
                    switch (r.status()) {
                        case "AUTHORIZED" -> {
                            move(id, "PAID", "COMMIT_INVENTORY", "payment authorized " + r.reference());   // el pivote
                            tx.executeWithoutResult(s -> events.paid(orders.findById(id).orElseThrow()));
                        }
                        case "REJECTED" -> move(id, "PAYMENT_REJECTED", "RELEASE_INVENTORY", "payment rejected " + r.reference());
                        default -> {
                            // PENDING: el proveedor quizá cobró. NO se compensa a ciegas: se vuelve a preguntar
                            // con la misma clave. Solo al vencer el plazo se escala a una persona.
                            if (d.expired()) escalate(id, "PAYMENT_PENDING", "payment still uncertain at deadline");
                            else later(d, "payment PENDING, will ask again with the same key");
                        }
                    }
                } catch (Errors.PaymentsUnavailable e) {
                    // aquí SÍ es seguro que no se cobró (06/03): vencido el plazo, compensar es correcto
                    if (d.expired()) move(id, "CANCELLED", "RELEASE_INVENTORY", "payments unavailable until deadline");
                    else later(d, e.getMessage());
                }
            }
            case "COMMIT_INVENTORY" -> {                     // después del pivote: solo se reintenta
                try {
                    var committed = inventory.consume(id);
                    if (committed == 0) escalate(id, null, "nothing to commit: the reservation expired before payment");
                    else move(id, null, "DONE", "committed " + committed + " lines");
                } catch (Errors.InventoryUnavailable e) {
                    later(d, e.getMessage());
                }
            }
            case "RELEASE_INVENTORY" -> {                    // comando ReleaseInventory: la compensación tiene que acabar
                try {
                    inventory.release(id);
                    move(id, null, "DONE", "released");
                } catch (Errors.InventoryUnavailable e) {
                    later(d, e.getMessage());
                }
            }
            default -> log.warn("saga {}: unknown step {}", id, d.step());
        }
    }

    // cambia el estado del pedido (si status no es null) y el paso de la saga en UNA transacción
    private void move(UUID id, String status, String next, String outcome) {
        tx.executeWithoutResult(s -> {
            var order = orders.findForUpdate(id).orElseThrow();
            var was = order.getStatus();
            if (status != null) order.setStatus(status);
            sagas.advance(id, next, deadline, outcome);
            log.info("saga {} → {} ({}; order {} → {})", id.toString().substring(0, 8), next, outcome, was, order.getStatus());
        });
    }

    private void escalate(UUID id, String status, String outcome) {
        tx.executeWithoutResult(s -> {
            var order = orders.findForUpdate(id).orElseThrow();
            if (status != null) order.setStatus(status);
            sagas.advance(id, "ESCALATED", 0, outcome);
            log.warn("saga {} ESCALATED: {} (order {})", id.toString().substring(0, 8), outcome, order.getStatus());
        });
    }

    private void later(SagaStore.Due d, String error) {
        tx.executeWithoutResult(s -> sagas.retryLater(d.orderId(), d.step(), d.attempts(), error));
        log.info("saga {} {} attempt {}: {}", d.orderId().toString().substring(0, 8), d.step(), d.attempts(), error);
    }

    // el pago se registra por su operationId, que se repite en cada intento (06/08 §9)
    private void recordPayment(Order order, String operationId, Payments.Result r) {
        tx.executeWithoutResult(s -> payments.findByOperationId(operationId).ifPresentOrElse(
            p -> p.resolve(r.status(), r.reference()),
            () -> payments.save(new Payment(order.getId(), operationId, r.status(), r.reference(), order.getTotalAmount()))));
    }
}
