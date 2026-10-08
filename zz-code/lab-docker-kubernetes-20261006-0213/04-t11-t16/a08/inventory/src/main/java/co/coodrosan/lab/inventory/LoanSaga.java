package co.coodrosan.lab.inventory;

import io.micrometer.core.instrument.Counter;
import io.micrometer.core.instrument.MeterRegistry;
import io.opentelemetry.api.GlobalOpenTelemetry;
import io.opentelemetry.api.trace.Span;
import io.opentelemetry.api.trace.StatusCode;
import io.opentelemetry.api.trace.Tracer;
import io.opentelemetry.context.Context;
import io.opentelemetry.context.Scope;
import java.time.Instant;
import java.time.ZoneOffset;
import java.time.format.DateTimeFormatter;
import java.time.temporal.ChronoUnit;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.function.Supplier;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.slf4j.MDC;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.MediaType;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.support.GeneratedKeyHolder;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;
import org.springframework.transaction.support.TransactionTemplate;
import org.springframework.web.client.ResourceAccessException;

// G11 (Fase 24): el préstamo entre droguerías como saga orquestada. inventory es el orquestador: guarda el estado
// de cada préstamo en su base, da un paso a la vez y, si uno falla, deshace los anteriores en orden inverso.
// Ninguna base de datos ve la saga entera: cada paso es una transacción local o una llamada a un vecino, y lo que
// la mantiene unida es este registro (loans y loan_steps).
//
//   RESERVE  LOAN_OUT en el origen         ↩ ADJUSTMENT +q con LOAN_RELEASED
//   DISPATCH la orden en replenish (moto)  ↩ cancelarla con SAGA_COMPENSATION (G13: con clave; por la clave si no hay número)
//   CHARGE   el cobro en el destino        (último: con el cobro hecho, la saga solo va hacia adelante)
//   RECEIVE  LOAN_IN en el destino
@Component
public class LoanSaga {

    private static final Logger log = LoggerFactory.getLogger(LoanSaga.class);
    // La hora con milisegundos fijos: el barrido compara updated_at como texto, y Instant.toString() no siempre
    // escribe la misma cantidad de decimales.
    private static final DateTimeFormatter STAMP =
            DateTimeFormatter.ofPattern("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'").withZone(ZoneOffset.UTC);
    private static final List<String> OPEN = List.of("STARTED", "RESERVED", "DISPATCHED", "CHARGED", "COMPENSATING");

    record LoanStep(String step, String action, String outcome, String detail, String at) { }

    record Loan(String id, String sku, String originStore, String destinationStore, int quantity, String status,
                String saleId, String replenishmentOrderId, String failure, List<LoanStep> steps) { }

    private record Row(long id, String sku, String origin, String destination, int quantity, String status,
                       String saleId, String orderId, String failure, String updatedAt) {
        String loanId() {
            return "LOAN-%06d".formatted(id);
        }
    }

    private final JdbcTemplate jdbc;
    private final TransactionTemplate tx;
    private final StockController stock;
    private final SalesController sales;
    private final Tracer tracer = GlobalOpenTelemetry.getTracer("inventory.loan-saga");
    private final MeterRegistry meters;
    private final long staleMs;

    LoanSaga(JdbcTemplate jdbc, TransactionTemplate tx, StockController stock, SalesController sales,
             MeterRegistry meters, @Value("${lab.saga.stale-ms:30000}") long staleMs) {
        this.jdbc = jdbc;
        this.tx = tx;
        this.stock = stock;
        this.sales = sales;
        this.meters = meters;
        this.staleMs = staleMs;
    }

    private static String now() {
        return STAMP.format(Instant.now());
    }

    static long parseId(String loanId) {
        return loanId != null && loanId.matches("^LOAN-[0-9]{6}$") ? Long.parseLong(loanId.substring(5)) : -1;
    }

    // ── La API ──────────────────────────────────────────────────────────────────────────────────────────────────

    // Registra el préstamo y arranca la saga en un hilo aparte: quien pidió el préstamo recibe 202 sin esperar.
    Loan start(String sku, String origin, String destination, int quantity, String idempotencyKey) {
        String at = now();
        GeneratedKeyHolder key = new GeneratedKeyHolder();
        jdbc.update(connection -> {
            var statement = connection.prepareStatement(
                    "INSERT INTO loans (sku, origin_store, destination_store, quantity, status, created_at, updated_at, idempotency_key) "
                            + "VALUES (?, ?, ?, ?, 'STARTED', ?, ?, ?)", new String[] {"id"});
            statement.setString(1, sku);
            statement.setString(2, origin);
            statement.setString(3, destination);
            statement.setInt(4, quantity);
            statement.setString(5, at);
            statement.setString(6, at);
            statement.setString(7, idempotencyKey);   // G13: única cuando está
            return statement;
        }, key);
        long id = key.getKey().longValue();
        Loan started = find(id);
        log.info("préstamo {}: {} × {} de {} a {}", started.id(), quantity, sku, origin, destination);
        // Como el aviso de la venta (G5, G10): el hilo nuevo no hereda el MDC ni la traza.
        String requestId = MDC.get("request_id");
        Thread.ofVirtual().start(Context.current().wrap(() -> {
            MDC.put("request_id", requestId);
            advance(id);
        }));
        return started;
    }

    // G13: el préstamo pedido con esta clave, si existe.
    Loan findByKey(String idempotencyKey) {
        List<Long> ids = jdbc.queryForList("SELECT id FROM loans WHERE idempotency_key = ?", Long.class, idempotencyKey);
        return ids.isEmpty() ? null : find(ids.getFirst());
    }

    Loan find(long id) {
        Row row = load(id);
        if (row == null) {
            return null;
        }
        List<LoanStep> steps = jdbc.query(
                "SELECT step, action, outcome, detail, at FROM loan_steps WHERE loan_id = ? ORDER BY id",
                (rs, i) -> new LoanStep(rs.getString(1), rs.getString(2), rs.getString(3), rs.getString(4), rs.getString(5)),
                id);
        return new Loan(row.loanId(), row.sku(), row.origin(), row.destination(), row.quantity(), row.status(),
                row.saleId(), row.orderId(), row.failure(), steps);
    }

    // ── El motor de la saga ─────────────────────────────────────────────────────────────────────────────────────

    // Da pasos hasta que el préstamo termina o hay que esperar (una compensación que falló vuelve con el barrido).
    void advance(long id) {
        boolean more = true;
        while (more) {
            Row loan = load(id);
            more = switch (loan.status()) {
                case "STARTED" -> reserve(loan);
                case "RESERVED" -> dispatch(loan);
                case "DISPATCHED" -> charge(loan);
                case "CHARGED" -> receive(loan);
                case "COMPENSATING" -> compensate(loan);
                default -> false;   // COMPLETED, COMPENSATED o BACKORDERED: terminado
            };
        }
    }

    // 1. RESERVE: la unidad sale de la existencia del origen, con la fila bloqueada (como la venta, G5).
    private boolean reserve(Row loan) {
        return traced(loan, "RESERVE", "DO", () -> tx.execute(status -> {
            StockController.StockLevel level = stock.findForUpdate(loan.origin(), loan.sku());
            if (level == null || level.quantity() < loan.quantity()) {
                // El "pendiente" de la historia: la vecina no tiene. Nada que deshacer; se avisa al cliente.
                String why = "%s no tiene %d unidades de %s".formatted(loan.origin(), loan.quantity(), loan.sku());
                step(loan.id(), "RESERVE", "DO", "FAILED", why);
                finish(loan.id(), "BACKORDERED", why);
                log.warn("préstamo {} pendiente: {}; se avisa al cliente en {}", loan.loanId(), why, loan.destination());
                return false;
            }
            jdbc.update("UPDATE stock_levels SET quantity = ? WHERE store = ? AND sku = ?",
                    level.quantity() - loan.quantity(), loan.origin(), loan.sku());
            StockController.Recorded movement = stock.record(loan.origin(), loan.sku(), "LOAN_OUT", -loan.quantity(), null, loan.loanId());
            step(loan.id(), "RESERVE", "DO", "OK", movement.id() + " en " + loan.origin());
            status(loan.id(), "RESERVED");
            return true;
        }));
    }

    // 2. DISPATCH: la moto. Con timeout (G9). G13 (Fase 26): con la clave del préstamo como Idempotency-Key, la
    // misma moto pedida dos veces es una sola orden. Eso cambia qué hacer con un timeout: hasta G12 era una falla y
    // se compensaba (y quedaba una orden huérfana si replenish la había creado); ahora es un "no sé", y lo seguro es
    // preguntar otra vez con la misma clave. Un error que replenish contestó (4xx, 5xx) sí es una falla.
    private static final int DISPATCH_ATTEMPTS = 3;

    private boolean dispatch(Row loan) {
        return traced(loan, "DISPATCH", "DO", () -> {
            for (int attempt = 1; ; attempt++) {
                try {
                    Map<?, ?> order = sales.replenish().post().uri("/replenishment-orders").contentType(MediaType.APPLICATION_JSON)
                            .header("Idempotency-Key", loan.loanId())
                            .body(Map.of("sku", loan.sku(), "destinationStore", loan.destination(),
                                    "originStore", loan.origin(), "quantity", loan.quantity()))
                            .retrieve().body(Map.class);
                    String orderId = String.valueOf(order.get("id"));
                    int tries = attempt;
                    tx.executeWithoutResult(status -> {
                        jdbc.update("UPDATE loans SET replenishment_order_id = ? WHERE id = ?", orderId, loan.id());
                        step(loan.id(), "DISPATCH", "DO", "OK", tries == 1 ? orderId : orderId + " (intento " + tries + ")");
                        status(loan.id(), "DISPATCHED");
                    });
                    return true;
                } catch (ResourceAccessException e) {
                    // Sin respuesta: no se sabe si la orden existe. Se pregunta otra vez, con la misma clave.
                    if (attempt == DISPATCH_ATTEMPTS) {
                        return fail(loan, "DISPATCH", "replenish no contestó en " + attempt + " intentos: " + e.getMessage());
                    }
                    log.warn("préstamo {}: DISPATCH sin respuesta (intento {}); se repite con la misma clave", loan.loanId(), attempt);
                    sleep(500L * attempt);
                } catch (RuntimeException e) {
                    return fail(loan, "DISPATCH", "replenish: " + e.getMessage());
                }
            }
        });
    }

    private static void sleep(long ms) {
        try {
            Thread.sleep(ms);
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
        }
    }

    // 3. CHARGE: el cobro al cliente en el destino, al precio de pricing. Con el cobro hecho, ya no hay vuelta atrás.
    private boolean charge(Row loan) {
        return traced(loan, "CHARGE", "DO", () -> {
            int unitPrice;
            try {
                unitPrice = sales.priceFor(loan.sku(), loan.destination());
            } catch (RuntimeException e) {
                return fail(loan, "CHARGE", "pricing: " + e.getMessage());
            }
            tx.executeWithoutResult(status -> {
                String saleId = sales.insertSale(loan.destination(), loan.sku(), loan.quantity(), unitPrice);
                jdbc.update("UPDATE loans SET sale_id = ? WHERE id = ?", saleId, loan.id());
                step(loan.id(), "CHARGE", "DO", "OK", "%s por %d".formatted(saleId, unitPrice * loan.quantity()));
                status(loan.id(), "CHARGED");
            });
            return true;
        });
    }

    // 4. RECEIVE: la unidad entra a la existencia del destino (la crea si no existía, como el primer RESTOCK).
    private boolean receive(Row loan) {
        return traced(loan, "RECEIVE", "DO", () -> tx.execute(status -> {
            jdbc.update("INSERT INTO stock_levels (store, sku, quantity, reorder_threshold) VALUES (?, ?, 0, 0) "
                    + "ON CONFLICT (store, sku) DO NOTHING", loan.destination(), loan.sku());
            StockController.StockLevel level = stock.findForUpdate(loan.destination(), loan.sku());
            jdbc.update("UPDATE stock_levels SET quantity = ? WHERE store = ? AND sku = ?",
                    level.quantity() + loan.quantity(), loan.destination(), loan.sku());
            StockController.Recorded movement = stock.record(loan.destination(), loan.sku(), "LOAN_IN", loan.quantity(), null, loan.loanId());
            step(loan.id(), "RECEIVE", "DO", "OK", movement.id() + " en " + loan.destination());
            finish(loan.id(), "COMPLETED", null);
            log.info("préstamo {} completo", loan.loanId());
            return false;
        }));
    }

    // Un paso falló: queda anotado, y la saga pasa a deshacer lo hecho.
    private boolean fail(Row loan, String step, String why) {
        log.warn("préstamo {}: falló {} ({}); se compensa", loan.loanId(), step, why);
        tx.executeWithoutResult(status -> {
            step(loan.id(), step, "DO", "FAILED", why);
            jdbc.update("UPDATE loans SET status = 'COMPENSATING', failure = ?, updated_at = ? WHERE id = ?", why, now(), loan.id());
        });
        Span.current().setStatus(StatusCode.ERROR, why);
        return true;
    }

    // ── Las compensaciones ──────────────────────────────────────────────────────────────────────────────────────

    // Deshace, en orden inverso, cada paso hecho que todavía no se deshizo. Deshacer es una operación de negocio
    // (cancelar la moto, devolver la unidad a la existencia), no un borrado: cada compensación deja su rastro.
    private boolean compensate(Row loan) {
        List<String> done = jdbc.queryForList(
                "SELECT step FROM loan_steps WHERE loan_id = ? AND action = 'DO' AND outcome = 'OK' ORDER BY id DESC",
                String.class, loan.id());
        List<String> undone = jdbc.queryForList(
                "SELECT step FROM loan_steps WHERE loan_id = ? AND action = 'UNDO' AND outcome = 'OK'", String.class, loan.id());
        List<String> pending = new ArrayList<>(done);
        pending.removeAll(undone);
        // G13: un DISPATCH que falló sin respuesta pudo haber creado la orden. Antes de liberar la reserva, se busca
        // por la clave del préstamo y, si existe, se cancela. Es lo que dejaba huérfanas hasta G12.
        boolean unknownDispatch = loan.orderId() == null && !undone.contains("DISPATCH") && jdbc.queryForObject(
                "SELECT count(*) FROM loan_steps WHERE loan_id = ? AND step = 'DISPATCH' AND action = 'DO'", Integer.class, loan.id()) > 0;
        if (unknownDispatch) {
            pending.addFirst("DISPATCH");
        }
        for (String step : pending) {
            boolean ok = switch (step) {
                case "DISPATCH" -> undoDispatch(loan);
                case "RESERVE" -> undoReserve(loan);
                default -> true;
            };
            if (!ok) {
                return false;   // queda en COMPENSATING: el barrido lo vuelve a intentar
            }
        }
        finish(loan.id(), "COMPENSATED", loan.failure());
        log.info("préstamo {} compensado: {}", loan.loanId(), loan.failure());
        return false;
    }

    private boolean undoDispatch(Row loan) {
        return traced(loan, "DISPATCH", "UNDO", () -> {
            try {
                String orderId = loan.orderId();
                if (orderId == null) {
                    // G13: la orden por la clave del préstamo. Si no hay ninguna, el DISPATCH de verdad no ocurrió.
                    List<?> found = sales.replenish().get().uri("/replenishment-orders?idempotencyKey={key}", loan.loanId())
                            .retrieve().body(List.class);
                    if (found == null || found.isEmpty()) {
                        step(loan.id(), "DISPATCH", "UNDO", "OK", "no había orden con la clave " + loan.loanId());
                        return true;
                    }
                    orderId = String.valueOf(((Map<?, ?>) found.getFirst()).get("id"));
                }
                sales.replenish().post().uri("/replenishment-orders/{id}/cancel", orderId)
                        .contentType(MediaType.APPLICATION_JSON)
                        .body(Map.of("reasonCode", "SAGA_COMPENSATION", "note", loan.loanId() + ": " + loan.failure()))
                        .retrieve().toBodilessEntity();
                step(loan.id(), "DISPATCH", "UNDO", "OK", orderId + " cancelada");
                return true;
            } catch (RuntimeException e) {
                step(loan.id(), "DISPATCH", "UNDO", "FAILED", "replenish: " + e.getMessage());
                Span.current().setStatus(StatusCode.ERROR, e.getMessage());
                log.error("préstamo {}: no se pudo cancelar {} ({}); se reintenta", loan.loanId(), loan.orderId(), e.getMessage());
                return false;
            }
        });
    }

    private boolean undoReserve(Row loan) {
        return traced(loan, "RESERVE", "UNDO", () -> tx.execute(status -> {
            StockController.StockLevel level = stock.findForUpdate(loan.origin(), loan.sku());
            jdbc.update("UPDATE stock_levels SET quantity = ? WHERE store = ? AND sku = ?",
                    level.quantity() + loan.quantity(), loan.origin(), loan.sku());
            StockController.Recorded movement =
                    stock.record(loan.origin(), loan.sku(), "ADJUSTMENT", loan.quantity(), "LOAN_RELEASED", loan.loanId());
            step(loan.id(), "RESERVE", "UNDO", "OK", movement.id() + " en " + loan.origin());
            return true;
        }));
    }

    // ── El barrido ──────────────────────────────────────────────────────────────────────────────────────────────

    // Cada 30 s busca préstamos sin terminar que nadie toca hace más de lab.saga.stale-ms: el pod que los llevaba
    // murió, o una compensación falló. Sin el cobro, se compensan; con el cobro hecho, se terminan. Para que dos
    // réplicas no tomen el mismo, cada una lo reclama con un UPDATE condicionado a la hora que leyó.
    @Scheduled(fixedDelayString = "${lab.saga.sweep-ms:30000}", initialDelayString = "${lab.saga.sweep-ms:30000}")
    void sweep() {
        String limit = STAMP.format(Instant.now().minus(staleMs, ChronoUnit.MILLIS));
        List<Row> stale = jdbc.query(
                "SELECT id, sku, origin_store, destination_store, quantity, status, sale_id, replenishment_order_id, failure, updated_at "
                        + "FROM loans WHERE status IN ('STARTED', 'RESERVED', 'DISPATCHED', 'CHARGED', 'COMPENSATING') "
                        + "AND updated_at < ? ORDER BY id", LoanSaga::row, limit);
        for (Row loan : stale) {
            int claimed = jdbc.update("UPDATE loans SET updated_at = ? WHERE id = ? AND updated_at = ?",
                    now(), loan.id(), loan.updatedAt());
            if (claimed == 0) {
                continue;   // otra réplica lo tomó
            }
            Span span = tracer.spanBuilder("saga sweep").setNoParent().setAttribute("loan.id", loan.loanId())
                    .setAttribute("loan.status", loan.status()).startSpan();
            try (Scope scope = span.makeCurrent()) {
                if (List.of("STARTED", "RESERVED", "DISPATCHED").contains(loan.status())) {
                    String why = "sin terminar en " + loan.status() + " después de " + staleMs / 1000 + " s";
                    log.warn("préstamo {}: {}; se compensa", loan.loanId(), why);
                    jdbc.update("UPDATE loans SET status = 'COMPENSATING', failure = COALESCE(failure, ?), updated_at = ? WHERE id = ?",
                            why, now(), loan.id());
                } else {
                    log.info("préstamo {}: se retoma en {}", loan.loanId(), loan.status());
                }
                advance(loan.id());
            } finally {
                span.end();
            }
        }
    }

    // ── El registro ─────────────────────────────────────────────────────────────────────────────────────────────

    // Cada paso es un span hijo del préstamo: en Tempo se ve qué se hizo, qué falló y qué se deshizo.
    private boolean traced(Row loan, String step, String action, Supplier<Boolean> body) {
        Span span = tracer.spanBuilder("saga " + action + " " + step)
                .setAttribute("loan.id", loan.loanId()).setAttribute("saga.step", step).setAttribute("saga.action", action)
                .startSpan();
        try (Scope scope = span.makeCurrent()) {
            return body.get();
        } finally {
            span.end();
        }
    }

    private void step(long id, String step, String action, String outcome, String detail) {
        jdbc.update("INSERT INTO loan_steps (loan_id, step, action, outcome, detail, at) VALUES (?, ?, ?, ?, ?, ?)",
                id, step, action, outcome, detail, now());
    }

    private void status(long id, String status) {
        jdbc.update("UPDATE loans SET status = ?, updated_at = ? WHERE id = ?", status, now(), id);
    }

    private void finish(long id, String status, String failure) {
        jdbc.update("UPDATE loans SET status = ?, failure = ?, updated_at = ? WHERE id = ?", status, failure, now(), id);
        Counter.builder("lab.loans").description("Préstamos terminados, por cómo terminaron").tag("status", status)
                .register(meters).increment();
    }

    private Row load(long id) {
        List<Row> rows = jdbc.query(
                "SELECT id, sku, origin_store, destination_store, quantity, status, sale_id, replenishment_order_id, failure, updated_at "
                        + "FROM loans WHERE id = ?", LoanSaga::row, id);
        return rows.isEmpty() ? null : rows.getFirst();
    }

    private static Row row(java.sql.ResultSet rs, int i) throws java.sql.SQLException {
        return new Row(rs.getLong(1), rs.getString(2), rs.getString(3), rs.getString(4), rs.getInt(5), rs.getString(6),
                rs.getString(7), rs.getString(8), rs.getString(9), rs.getString(10));
    }
}
