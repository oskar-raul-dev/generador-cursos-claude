package dev.ms.orders.saga;

import org.springframework.jdbc.core.simple.JdbcClient;
import org.springframework.stereotype.Component;

import java.time.Duration;
import java.util.List;
import java.util.UUID;

// La tabla del orquestador (taller 09): order_sagas guarda el paso en curso de cada saga y su plazo;
// order_saga_log, cada transición. Todo con SQL a la vista: es la parte que hay que poder leer en un
// incidente.
@Component
public class SagaStore {

    public record Due(UUID orderId, String step, int attempts, boolean expired) {}

    private final JdbcClient jdbc;

    public SagaStore(JdbcClient jdbc) { this.jdbc = jdbc; }

    /** El primer paso, en la transacción que crea el pedido: la tabla hace de outbox del orquestador. */
    public void start(UUID orderId, int deadlineSeconds) {
        jdbc.sql("""
                INSERT INTO order_sagas (order_id, step, deadline_at)
                VALUES (?, 'RESERVE_INVENTORY', CASE WHEN ? > 0 THEN clock_timestamp() + make_interval(secs => ?) END)""")
            .params(orderId, deadlineSeconds, deadlineSeconds).update();
        log(orderId, "RESERVE_INVENTORY", "saga started");
    }

    /**
     * Reclama hasta `limit` pasos vencidos con un "lease": los aplaza `lease` para que ninguna otra
     * instancia los coja mientras esta llama a inventory o a payments. La llamada remota va FUERA de
     * esta transacción; si el proceso muere a mitad, el lease vence y otro lo reintenta.
     */
    public List<Due> claim(int limit, Duration lease) {
        return jdbc.sql("""
                UPDATE order_sagas s SET next_attempt_at = clock_timestamp() + make_interval(secs => ?),
                                         attempts = attempts + 1
                 WHERE order_id IN (SELECT order_id FROM order_sagas
                                     WHERE step NOT IN ('DONE', 'ESCALATED') AND next_attempt_at <= clock_timestamp()
                                     ORDER BY next_attempt_at LIMIT ? FOR UPDATE SKIP LOCKED)
                RETURNING order_id, step, attempts, coalesce(deadline_at < clock_timestamp(), false)""")
            .params(lease.toSeconds(), limit)
            .query((rs, n) -> new Due(rs.getObject(1, UUID.class), rs.getString(2), rs.getInt(3), rs.getBoolean(4)))
            .list();
    }

    /** Pasa al paso siguiente, con plazo nuevo y el contador de intentos a cero. */
    public void advance(UUID orderId, String step, int deadlineSeconds, String outcome) {
        if ("DONE".equals(step) || "ESCALATED".equals(step)) deadlineSeconds = 0;   // un paso final no vence
        jdbc.sql("""
                UPDATE order_sagas SET step = ?, attempts = 0, last_error = NULL, next_attempt_at = clock_timestamp(),
                       step_started_at = clock_timestamp(),
                       deadline_at = CASE WHEN ? > 0 THEN clock_timestamp() + make_interval(secs => ?) END
                 WHERE order_id = ?""")
            .params(step, deadlineSeconds, deadlineSeconds, orderId).update();
        log(orderId, step, outcome);
    }

    /** Mismo paso, otro intento más tarde: espera exponencial con tope de 5 s. */
    public void retryLater(UUID orderId, String step, int attempts, String error) {
        var delayMs = Math.min(5_000L, 250L << Math.min(attempts, 5));
        jdbc.sql("UPDATE order_sagas SET next_attempt_at = clock_timestamp() + make_interval(secs => ?), last_error = ? WHERE order_id = ?")
            .params(delayMs / 1000.0, error, orderId).update();
        log(orderId, step, "retry in " + delayMs + " ms: " + error);
    }

    public void log(UUID orderId, String step, String outcome) {
        jdbc.sql("INSERT INTO order_saga_log (order_id, step, outcome) VALUES (?, ?, ?)").params(orderId, step, outcome).update();
    }
}
