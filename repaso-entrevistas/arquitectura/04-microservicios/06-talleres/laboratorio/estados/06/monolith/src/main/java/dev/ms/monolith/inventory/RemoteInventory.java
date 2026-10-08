package dev.ms.monolith.inventory;

import dev.ms.monolith.config.MsProperties;
import dev.ms.monolith.service.Errors;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.http.HttpStatus;
import org.springframework.http.client.JdkClientHttpRequestFactory;
import org.springframework.stereotype.Component;
import org.springframework.web.client.ResourceAccessException;
import org.springframework.web.client.RestClient;
import org.springframework.web.util.UriBuilder;

import java.net.http.HttpClient;
import java.time.Duration;
import java.util.Collection;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.stream.Collectors;

// El inventario, ahora como servicio remoto (Go). Esta clase es la capa anticorrupción: el
// servicio habla de stock en mano (onHand) y de retenciones (holds) bajo una referencia; el
// monolito sigue hablando de disponible y de reservas por pedido. La traducción vive AQUÍ y en
// ningún otro sitio: ni el catálogo ni los pedidos saben que existe un /holds.
@Component
@ConditionalOnProperty(name = "ms.inventory.mode", havingValue = "remote")
public class RemoteInventory implements Inventory {

    // la forma de las respuestas de inventory, tal cual; no sale de esta clase
    record StockItem(String sku, int onHand) {}
    record StockResponse(List<StockItem> items) {}
    record HoldItem(String sku, int qty) {}
    record HoldRequest(String reference, List<HoldItem> items) {}
    record Shortage(String sku, int requested, int onHand) {}
    record OutOfStock(String code, List<Shortage> shortages) {}

    private final RestClient http;

    public RemoteInventory(RestClient.Builder builder, MsProperties props) {
        var cfg = props.inventory();
        var jdk = HttpClient.newBuilder().connectTimeout(Duration.ofMillis(cfg.connectTimeoutMs())).build();
        var factory = new JdkClientHttpRequestFactory(jdk);
        // la primera llamada remota nace con timeout (decisión D7): 0 lo desactiva, y el taller
        // muestra qué pasa entonces
        if (cfg.readTimeoutMs() > 0) factory.setReadTimeout(Duration.ofMillis(cfg.readTimeoutMs()));
        this.http = builder.baseUrl(cfg.baseUrl()).requestFactory(factory).build();
    }

    @Override
    public Map<String, Integer> stockOf(Collection<String> skus) {
        var res = call(() -> http.get().uri((UriBuilder u) -> u.path("/stock").queryParam("sku", skus.toArray()).build())
            .retrieve().body(StockResponse.class));
        return res.items().stream().collect(Collectors.toMap(StockItem::sku, StockItem::onHand));
    }

    @Override
    public void reserve(UUID orderId, List<Line> lines) {
        var body = new HoldRequest(orderId.toString(), lines.stream().map(l -> new HoldItem(l.sku(), l.quantity())).toList());
        call(() -> http.post().uri("/holds").body(body).retrieve()
            .onStatus(s -> s.value() == HttpStatus.CONFLICT.value(), (req, res) -> {
                var oos = new tools.jackson.databind.json.JsonMapper().readValue(res.getBody(), OutOfStock.class);
                throw translate(oos, lines);
            })
            .toBodilessEntity());
    }

    @Override
    public void release(UUID orderId) {
        call(() -> http.post().uri("/holds/{ref}/release", orderId).retrieve().toBodilessEntity());
    }

    @Override
    public void consume(UUID orderId) {
        call(() -> http.post().uri("/holds/{ref}/commit", orderId).retrieve().toBodilessEntity());
    }

    // OUT_OF_STOCK con su lista de faltantes → el error del monolito, con el índice de la línea
    // que el contrato promete (lines[i].quantity). El servicio no sabe qué es una línea de pedido.
    private static Errors.InsufficientInventory translate(OutOfStock oos, List<Line> lines) {
        var first = oos.shortages().getFirst();
        for (int i = 0; i < lines.size(); i++) {
            if (lines.get(i).sku().equals(first.sku()))
                return new Errors.InsufficientInventory(first.sku(), i, lines.get(i).quantity(), first.onHand());
        }
        return new Errors.InsufficientInventory(first.sku(), 0, first.requested(), first.onHand());
    }

    private static <T> T call(java.util.function.Supplier<T> request) {
        try {
            return request.get();
        } catch (ResourceAccessException e) {        // timeout o conexión rechazada
            throw new Errors.InventoryUnavailable(e);
        }
    }
}
