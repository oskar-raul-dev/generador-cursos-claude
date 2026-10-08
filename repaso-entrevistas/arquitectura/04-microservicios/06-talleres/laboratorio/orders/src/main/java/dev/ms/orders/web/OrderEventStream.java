package dev.ms.orders.web;

import dev.ms.orders.service.OrderService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.MediaType;
import org.springframework.jdbc.core.simple.JdbcClient;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.servlet.mvc.method.annotation.SseEmitter;

import java.io.IOException;
import java.util.Map;
import java.util.Set;
import java.util.UUID;
import java.util.concurrent.ConcurrentHashMap;

// El seguimiento del pedido por SSE (taller 11). Cada transición de la saga (order_saga_log, 06/09) es un
// evento con su `id`: si la conexión se corta, el cliente vuelve con Last-Event-ID y el servidor sigue
// desde ahí. Al llegar a un estado final se envía `end` y se cierra: sin ese aviso, un EventSource
// reconectaría para siempre.
@RestController
public class OrderEventStream {

    private static final Logger log = LoggerFactory.getLogger(OrderEventStream.class);
    private static final Set<String> FINAL = Set.of("DONE", "ESCALATED");

    record Follower(UUID orderId, SseEmitter emitter, long[] lastId) {}

    private final Map<SseEmitter, Follower> followers = new ConcurrentHashMap<>();
    private int ticks;
    private final JdbcClient jdbc;
    private final OrderService orders;

    public OrderEventStream(JdbcClient jdbc, OrderService orders) { this.jdbc = jdbc; this.orders = orders; }

    @GetMapping(path = "/api/v2/orders/{orderId}/events", produces = MediaType.TEXT_EVENT_STREAM_VALUE)
    SseEmitter follow(@RequestHeader(name = "x-jwt-payload", required = false) String payload, @PathVariable UUID orderId,
                      @RequestHeader(name = "Last-Event-ID", required = false) Long lastEventId) throws IOException {
        var view = orders.get(ActorResolver.from(payload), orderId);         // 404 si no es suyo, como el GET
        var emitter = new SseEmitter(0L);                                    // sin plazo propio: lo corta quien corte
        var follower = new Follower(orderId, emitter, new long[]{lastEventId == null ? 0 : lastEventId});
        emitter.send(SseEmitter.event().name("snapshot").data(Map.of("status", view.status())));   // sin id: no mueve la reanudación
        emitter.onCompletion(() -> followers.remove(emitter));
        emitter.onTimeout(() -> followers.remove(emitter));
        emitter.onError(e -> followers.remove(emitter));
        followers.put(emitter, follower);
        log.info("sse follow order={} from id {}", orderId.toString().substring(0, 8), follower.lastId()[0]);
        return emitter;
    }

    // cada 200 ms: lo nuevo del registro de cada saga seguida, desde el último id enviado
    @Scheduled(fixedDelay = 200)
    void push() {
        var heartbeat = ++ticks % 75 == 0;                                  // cada 15 s: un comentario ": ping"
        for (var f : followers.values()) {
            try {
                if (heartbeat) f.emitter().send(SseEmitter.event().comment("ping"));   // que un proxy no lo dé por muerto
                var rows = jdbc.sql("SELECT l.id, l.step, l.outcome, o.status FROM order_saga_log l JOIN orders o ON o.id = l.order_id "
                                    + "WHERE l.order_id = ? AND l.id > ? ORDER BY l.id")
                    .params(f.orderId(), f.lastId()[0])
                    .query((rs, n) -> new Object[]{rs.getLong(1), rs.getString(2), rs.getString(3), rs.getString(4)}).list();
                for (var r : rows) {
                    f.emitter().send(SseEmitter.event().id(String.valueOf(r[0])).name("step")
                        .data(Map.of("step", r[1], "outcome", r[2], "orderStatus", r[3])));
                    f.lastId()[0] = (long) r[0];
                    if (FINAL.contains((String) r[1])) {
                        f.emitter().send(SseEmitter.event().name("end").data(Map.of("orderStatus", r[3])));
                        f.emitter().complete();
                        followers.remove(f.emitter());
                        break;
                    }
                }
            } catch (IOException | IllegalStateException e) {                 // el cliente se fue
                followers.remove(f.emitter());
            }
        }
    }
}
