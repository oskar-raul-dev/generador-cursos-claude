package co.coodrosan.lab.inventory;

import io.valkey.JedisPooled;
import java.time.Instant;
import org.springframework.beans.factory.DisposableBean;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Component;

// G12 (Fase 25): el aviso de reposición como evento. inventory publica que el stock bajó y no sabe quién escucha.
// G13 (Fase 26): con EVENT_BUS=nats, inventory ya no publica: escribe el evento en la tabla outbox, en la misma
// transacción que la venta, y lo publica el sidecar outbox-relay (relay/main.go). Con EVENT_BUS=valkey sigue
// publicando directo, como en G12: Valkey es el bus frágil a propósito. Sin EVENT_BUS, no hay bus (G5).
@Component
public class EventBus implements DisposableBean {

    static final String STOCK_LOW = "lab.inventory.stock-low";

    private final String kind = System.getenv().getOrDefault("EVENT_BUS", "");
    private final JedisPooled valkey;

    EventBus() {
        valkey = kind.equals("valkey")
                ? new JedisPooled(java.net.URI.create(System.getenv().getOrDefault("VALKEY_URL", "redis://localhost:6379")))
                : null;
    }

    // Hay un bus: el aviso es un evento y no un POST.
    boolean enabled() {
        return kind.equals("valkey") || kind.equals("nats");
    }

    // G13: el evento va al outbox, no al bus.
    boolean outbox() {
        return kind.equals("nats");
    }

    static String stockLow(String eventId, String saleId, String store, String sku, int quantity) {
        return "{\"eventId\":\"%s\",\"type\":\"stock.low\",\"saleId\":\"%s\",\"store\":\"%s\",\"sku\":\"%s\",\"quantity\":%d,\"occurredAt\":\"%s\"}"
                .formatted(eventId, saleId, store, sku, quantity, Instant.now());
    }

    // G13: dentro de la transacción de quien llama. Si la venta se deshace, el evento también.
    void enqueue(JdbcTemplate jdbc, String eventId, String json) {
        jdbc.update("INSERT INTO outbox (id, subject, payload, created_at) VALUES (?, ?, ?, ?)",
                eventId, STOCK_LOW, json, Instant.now().toString());
    }

    // G12, solo Valkey: PUBLISH devuelve a cuántos suscriptores llegó. Cero es un mensaje que no existió nunca.
    String publish(String eventId, String json) {
        long receivers = valkey.publish(STOCK_LOW, json);
        return "evento " + eventId + " a " + receivers + " suscriptores (Valkey)";
    }

    @Override
    public void destroy() {
        if (valkey != null) {
            valkey.close();
        }
    }
}
