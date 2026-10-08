package co.coodrosan.lab.inventory;

import io.github.resilience4j.circuitbreaker.CallNotPermittedException;
import com.fasterxml.jackson.annotation.JsonInclude;
import io.grpc.Status;
import io.grpc.StatusRuntimeException;
import io.micrometer.core.instrument.Counter;
import io.micrometer.core.instrument.MeterRegistry;
import io.opentelemetry.context.Context;
import java.net.http.HttpClient;
import java.time.Duration;
import java.time.Instant;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.slf4j.MDC;
import org.springframework.beans.factory.ObjectProvider;
import org.springframework.boot.ssl.SslBundle;
import org.springframework.boot.ssl.SslBundles;
import org.springframework.dao.DuplicateKeyException;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.http.client.JdkClientHttpRequestFactory;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.support.GeneratedKeyHolder;
import org.springframework.transaction.support.TransactionTemplate;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.client.HttpClientErrorException;
import org.springframework.web.client.RestClient;
import org.springframework.web.client.RestClientException;

// G5: la venta completa. Es la primera vez que un servicio del sistema llama a otro por trabajo de negocio.
// G8: a pricing, con TLS mutuo cuando PRICING_URL es https.
// G9: cada llamada con timeouts (aquí, en el cliente) y las lecturas con reintentos y circuit breaker (Guard).
@RestController
public class SalesController {

    private static final Logger log = LoggerFactory.getLogger(SalesController.class);

    record SaleRequest(String store, String sku, Integer quantity) { }

    // G13: replenishmentRequested no se guarda; una venta repetida con su clave la devuelve sin ese campo.
    record Sale(String id, String store, String sku, int quantity, int unitPrice, int total,
                @JsonInclude(JsonInclude.Include.NON_NULL) Boolean replenishmentRequested) { }

    private final JdbcTemplate jdbc;
    private final TransactionTemplate tx;
    private final StockController stock;
    private final RestClient catalog;
    // G8: con mTLS, el cliente de pricing se rearma cuando cert-manager renueva el certificado.
    private volatile RestClient pricing;
    private final RestClient replenish;
    // G6: la métrica de negocio, la que el cluster no puede dar gratis. En Prometheus, lab_sales_total.
    private final Counter sales;
    private final Guard guard;
    // G10: pricing por gRPC, si PRICING_GRPC_TARGET está puesta (y con mTLS); si no, por HTTP como en G8.
    private final PricingGrpc pricingGrpc;
    // G12: el bus de eventos, si hay uno encendido.
    private final EventBus events;

    // G9: cuánto se espera a un vecino. Sin esto (hasta G8), una llamada podía esperar para siempre.
    private static final Duration CONNECT_TIMEOUT =
            Duration.ofMillis(Long.parseLong(System.getenv().getOrDefault("LAB_RESILIENCE_CONNECT_TIMEOUT_MS", "1000")));
    private static final Duration READ_TIMEOUT =
            Duration.ofMillis(Long.parseLong(System.getenv().getOrDefault("LAB_RESILIENCE_READ_TIMEOUT_MS", "2000")));

    SalesController(JdbcTemplate jdbc, TransactionTemplate tx, StockController stock, MeterRegistry registry,
                    ObjectProvider<SslBundles> sslBundles, Guard guard, EventBus events) {
        this.jdbc = jdbc;
        this.events = events;
        this.tx = tx;
        this.stock = stock;
        this.guard = guard;
        this.sales = Counter.builder("lab.sales").description("Ventas registradas").register(registry);
        // Las direcciones de los vecinos, del ConfigMap neighbors (Fase 09): por fin alguien las usa.
        this.catalog = client(neighbor("CATALOG_URL", "http://catalog:8080"));
        String pricingUrl = neighbor("PRICING_URL", "http://pricing:8080");
        if (pricingUrl.startsWith("https://")) {
            // G8 (Fase 19): pricing por TLS mutuo. El bundle "pricing" (spring.ssl.bundle.pem.pricing.*, que el
            // chart pone por variables) trae el certificado de cliente de inventory y la CA para verificar a
            // pricing; si los archivos cambian, Spring avisa y el cliente se arma de nuevo.
            SslBundles bundles = sslBundles.getObject();
            this.pricing = client(pricingUrl, bundles.getBundle("pricing"));
            String grpcTarget = System.getenv("PRICING_GRPC_TARGET");
            this.pricingGrpc = grpcTarget == null || grpcTarget.isBlank() ? null
                    : new PricingGrpc(grpcTarget, System.getenv().getOrDefault("PRICING_GRPC_POLICY", "pick_first"),
                            READ_TIMEOUT, bundles.getBundle("pricing"));
            bundles.addBundleUpdateHandler("pricing", bundle -> {
                this.pricing = client(pricingUrl, bundle);
                if (pricingGrpc != null) {
                    pricingGrpc.rebuild(bundle);
                }
                log.info("certificado de cliente para pricing renovado");
            });
        } else {
            this.pricing = client(pricingUrl);
            this.pricingGrpc = null;
        }
        this.replenish = client(neighbor("REPLENISH_URL", "http://replenish:8080"));
    }

    private static RestClient client(String baseUrl) {
        return client(baseUrl, null);
    }

    // G7: cada llamada a un vecino lleva el X-Request-Id de la petición que la originó (del MDC). G8: con un
    // bundle, la conexión es TLS mutuo con el SSLContext que arma Spring a partir de los PEM. G9: los dos
    // timeouts, el de conectar y el de esperar la respuesta.
    private static RestClient client(String baseUrl, SslBundle ssl) {
        HttpClient.Builder http = HttpClient.newBuilder().connectTimeout(CONNECT_TIMEOUT);
        if (ssl != null) {
            http.sslContext(ssl.createSslContext());
        }
        JdkClientHttpRequestFactory factory = new JdkClientHttpRequestFactory(http.build());
        factory.setReadTimeout(READ_TIMEOUT);
        RestClient.Builder builder = RestClient.builder().baseUrl(baseUrl).requestFactory(factory);
        return builder.requestInterceptor((request, body, execution) -> {
            String requestId = MDC.get("request_id");
            if (requestId != null) {
                request.getHeaders().set("X-Request-Id", requestId);
            }
            return execution.execute(request, body);
        }).build();
    }

    private static String neighbor(String variable, String fallback) {
        return System.getenv().getOrDefault(variable, fallback);
    }

    private static ResponseEntity<Object> error(HttpStatus status, String code, String message) {
        return ResponseEntity.status(status).body(Map.of("error", code, "message", message));
    }

    // G11: el precio vigente de un producto en una droguería, por gRPC si está encendido y si no por HTTP, con los
    // reintentos y el circuito de G9. Lo usan la venta y el cobro del préstamo; los errores los traduce quien llama.
    int priceFor(String sku, String store) {
        if (pricingGrpc != null) {
            return (int) guard.call("pricing", () -> pricingGrpc.getPrice(sku, store)).getPrice();
        }
        Map<?, ?> price = guard.call("pricing",
                () -> pricing.get().uri("/prices/{sku}?store={store}", sku, store).retrieve().body(Map.class));
        return ((Number) price.get("price")).intValue();
    }

    // G11: una fila de sales, dentro de la transacción de quien llama. La venta la acompaña de un movimiento SALE;
    // el cobro de un préstamo no, porque la unidad sale de la existencia de otra droguería.
    String insertSale(String store, String sku, int quantity, int unitPrice) {
        return insertSale(store, sku, quantity, unitPrice, null);
    }

    // G13: con la clave de idempotencia, si la trae. El índice único rechaza la segunda venta con la misma clave.
    String insertSale(String store, String sku, int quantity, int unitPrice, String idempotencyKey) {
        GeneratedKeyHolder key = new GeneratedKeyHolder();
        jdbc.update(connection -> {
            var statement = connection.prepareStatement(
                    "INSERT INTO sales (store, sku, quantity, unit_price, total, created_at, idempotency_key) VALUES (?, ?, ?, ?, ?, ?, ?)",
                    new String[] {"id"});
            statement.setString(1, store);
            statement.setString(2, sku);
            statement.setInt(3, quantity);
            statement.setInt(4, unitPrice);
            statement.setInt(5, unitPrice * quantity);
            statement.setString(6, Instant.now().toString());
            statement.setString(7, idempotencyKey);
            return statement;
        }, key);
        return "SALE-%06d".formatted(key.getKey().longValue());
    }

    // G11: el mismo cliente de replenish del aviso (con timeouts y el X-Request-Id), para la saga.
    RestClient replenish() {
        return replenish;
    }

    // G13: la venta ya registrada con esta clave. Con el mismo cuerpo, se devuelve tal cual (201, como la primera vez);
    // con otro, la clave se está usando para otra cosa, y es un error de quien llama.
    private ResponseEntity<Object> replay(String key, SaleRequest request) {
        List<Sale> previous = jdbc.query(
                "SELECT id, store, sku, quantity, unit_price, total FROM sales WHERE idempotency_key = ?",
                (rs, i) -> new Sale("SALE-%06d".formatted(rs.getLong(1)), rs.getString(2), rs.getString(3), rs.getInt(4),
                        rs.getInt(5), rs.getInt(6), null), key);
        if (previous.isEmpty()) {
            return null;
        }
        Sale sale = previous.getFirst();
        if (!sale.store().equals(request.store()) || !sale.sku().equals(request.sku()) || sale.quantity() != request.quantity()) {
            return error(HttpStatus.UNPROCESSABLE_CONTENT, "unprocessable", "la clave " + key + " ya se usó con otra venta");
        }
        log.info("venta repetida con la clave {}: se devuelve {}", key, sale.id());
        return ResponseEntity.status(HttpStatus.CREATED).body(sale);
    }

    @PostMapping("/sales")
    public ResponseEntity<Object> sell(@RequestBody SaleRequest request,
                                       @RequestHeader(value = "Idempotency-Key", required = false) String idempotencyKey) {
        if (request.store() == null || !request.store().matches("^DRO-[0-9]{3}$")
                || request.sku() == null || !request.sku().matches("^SKU-[0-9]{4}$")
                || request.quantity() == null || request.quantity() < 1) {
            return error(HttpStatus.UNPROCESSABLE_CONTENT, "unprocessable", "se esperan store (DRO-000), sku (SKU-0000) y quantity ≥ 1");
        }
        String store = request.store();
        String sku = request.sku();
        int quantity = request.quantity();
        // G13: un reintento no vuelve a preguntar a catalog ni a pricing, ni a descontar: devuelve lo que ya pasó.
        if (idempotencyKey != null) {
            ResponseEntity<Object> previous = replay(idempotencyKey, request);
            if (previous != null) {
                return previous;
            }
        }

        // 1. El producto existe y está activo, según catalog.
        Map<?, ?> product;
        try {
            product = guard.call("catalog", () -> catalog.get().uri("/products/{sku}", sku).retrieve().body(Map.class));
        } catch (HttpClientErrorException.NotFound e) {
            return error(HttpStatus.UNPROCESSABLE_CONTENT, "unprocessable", "catalog no conoce " + sku);
        } catch (CallNotPermittedException e) {
            // G9: el circuito está abierto. No se llama a catalog: se contesta ya.
            return error(HttpStatus.SERVICE_UNAVAILABLE, "unavailable", "catalog no disponible (circuito abierto)");
        } catch (RestClientException e) {
            log.warn("catalog no contesta: {}", e.getMessage());
            return error(HttpStatus.SERVICE_UNAVAILABLE, "unavailable", "catalog no contesta");
        }
        if (product == null || !"ACTIVE".equals(product.get("status"))) {
            return error(HttpStatus.UNPROCESSABLE_CONTENT, "unprocessable", sku + " está descontinuado");
        }

        // 2. El precio vigente en la droguería, con el tope regulado ya aplicado, según pricing.
        int unitPrice;
        try {
            unitPrice = priceFor(sku, store);
        } catch (StatusRuntimeException e) {
            if (e.getStatus().getCode() == Status.Code.NOT_FOUND) {
                return error(HttpStatus.UNPROCESSABLE_CONTENT, "unprocessable", sku + " no tiene precio en " + store);
            }
            log.warn("pricing no contesta (gRPC): {}", e.getStatus());
            return error(HttpStatus.SERVICE_UNAVAILABLE, "unavailable", "pricing no contesta");
        } catch (HttpClientErrorException.NotFound e) {
            return error(HttpStatus.UNPROCESSABLE_CONTENT, "unprocessable", sku + " no tiene precio en " + store);
        } catch (CallNotPermittedException e) {
            return error(HttpStatus.SERVICE_UNAVAILABLE, "unavailable", "pricing no disponible (circuito abierto)");
        } catch (RestClientException e) {
            log.warn("pricing no contesta: {}", e.getMessage());
            return error(HttpStatus.SERVICE_UNAVAILABLE, "unavailable", "pricing no contesta");
        }

        // 3. La existencia, descontada con la fila bloqueada: dos ventas a la vez no venden la misma unidad.
        record Done(Sale sale, int left, int threshold, String eventId) { }
        Done done;
        try {
            done = tx.execute(status -> {
                StockController.StockLevel level = stock.findForUpdate(store, sku);
                if (level == null || level.quantity() < quantity) {
                    return null;
                }
                int left = level.quantity() - quantity;
                jdbc.update("UPDATE stock_levels SET quantity = ? WHERE store = ? AND sku = ?", left, store, sku);
                String saleId = insertSale(store, sku, quantity, unitPrice, idempotencyKey);
                stock.record(store, sku, "SALE", -quantity, null, saleId);
                boolean replenishment = left < level.reorderThreshold();
                String eventId = replenishment && events.enabled() ? UUID.randomUUID().toString() : null;
                // G13: con NATS, el evento entra al outbox en esta misma transacción: la venta y su aviso se confirman
                // juntos o no se confirman. Lo publica el sidecar.
                if (eventId != null && events.outbox()) {
                    events.enqueue(jdbc, eventId, EventBus.stockLow(eventId, saleId, store, sku, level.reorderThreshold()));
                }
                return new Done(new Sale(saleId, store, sku, quantity, unitPrice, unitPrice * quantity, replenishment),
                        left, level.reorderThreshold(), eventId);
            });
        } catch (DuplicateKeyException e) {
            // G13: otra petición con la misma clave ganó la carrera; esta devuelve la venta de aquella.
            return replay(idempotencyKey, request);
        }
        if (done == null) {
            return error(HttpStatus.CONFLICT, "conflict", "no hay " + quantity + " unidades de " + sku + " en " + store);
        }
        sales.increment();

        // 4. Bajo el umbral: el aviso a replenish, SIN esperar su respuesta. La venta ya está hecha y no
        // puede fallar porque replenish no conteste; el resultado va al log. ¿Y si el aviso se pierde?
        // Esa pregunta es de la Fase 25.
        if (done.sale().replenishmentRequested()) {
            // El hilo nuevo no hereda el MDC ni la traza: el request_id se copia a mano, y el contexto de
            // OpenTelemetry se le pasa envolviendo la tarea (G10, Fase 23). Sin eso, el aviso es otra traza.
            String requestId = MDC.get("request_id");
            Thread.ofVirtual().start(Context.current().wrap(() -> {
                MDC.put("request_id", requestId);
                // G13: con NATS, el aviso ya quedó en el outbox con la venta; aquí no hay nada que mandar.
                if (events.outbox()) {
                    log.info("aviso de {} para {} en {} (quedan {}): evento {} en el outbox", done.sale().id(), sku, store,
                            done.left(), done.eventId());
                    return;
                }
                // G12 (Fase 25): con Valkey, el aviso es un evento publicado directo; inventory no sabe quién lo atiende.
                if (events.enabled()) {
                    try {
                        log.info("aviso de {} para {} en {} (quedan {}): {}", done.sale().id(), sku, store, done.left(),
                                events.publish(done.eventId(), EventBus.stockLow(done.eventId(), done.sale().id(), store, sku, done.threshold())));
                    } catch (Exception e) {
                        log.warn("aviso perdido para {} en {}: el bus no contestó ({})", sku, store, e.getMessage());
                    }
                    return;
                }
                try {
                    Map<?, ?> order = replenish.post().uri("/replenishment-orders").contentType(MediaType.APPLICATION_JSON)
                            .body(Map.of("sku", sku, "destinationStore", store, "quantity", done.threshold()))
                            .retrieve().body(Map.class);
                    log.info("aviso a replenish: {} para {} en {} (quedan {})", order.get("id"), sku, store, done.left());
                } catch (RestClientException e) {
                    log.warn("aviso a replenish perdido para {} en {}: {}", sku, store, e.getMessage());
                }
            }));
        }
        return ResponseEntity.status(HttpStatus.CREATED).body(done.sale());
    }
}
