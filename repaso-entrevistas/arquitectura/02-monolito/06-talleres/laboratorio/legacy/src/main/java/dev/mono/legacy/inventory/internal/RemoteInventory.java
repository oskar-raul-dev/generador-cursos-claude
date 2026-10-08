package dev.mono.legacy.inventory.internal;

import dev.mono.legacy.shared.ErrorCode;
import dev.mono.legacy.shared.LegacyException;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.client.SimpleClientHttpRequestFactory;
import org.springframework.stereotype.Component;
import org.springframework.web.client.HttpClientErrorException;
import org.springframework.web.client.RestClient;

import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;

// Taller 10: el inventario en otro proceso (mono-inventory), a través de Toxiproxy. Un 404 o un 409 son
// respuestas del negocio; cualquier otra cosa —un timeout, un corte— es un fallo de red, y el resultado
// de la reserva es DESCONOCIDO: pudo aplicarse o no.
@Component
public class RemoteInventory {
    private final RestClient http;

    public RemoteInventory(RestClient.Builder builder, @Value("${legacy.inventory.url}") String url,
                           @Value("${legacy.inventory.timeout-ms}") int timeoutMs) {
        var factory = new SimpleClientHttpRequestFactory();
        factory.setConnectTimeout(timeoutMs);
        factory.setReadTimeout(timeoutMs);
        this.http = builder.baseUrl(url).requestFactory(factory).build();
    }

    @SuppressWarnings("unchecked")
    public void reserve(UUID reservationId, String sku, int quantity) {
        try {
            http.post().uri("/internal/reservations")
                .body(body(reservationId, sku, quantity)).retrieve().toBodilessEntity();
        } catch (HttpClientErrorException.NotFound e) {
            throw new LegacyException(ErrorCode.PRODUCT_NOT_FOUND, sku);
        } catch (HttpClientErrorException.Conflict e) {
            Map<String, Object> problem = e.getResponseBodyAs(Map.class);
            Object available = problem == null ? "?" : problem.getOrDefault("available", "?");
            throw new LegacyException(ErrorCode.INSUFFICIENT_INVENTORY,
                sku + ": requested " + quantity + ", available " + available);
        }
    }

    public void release(UUID reservationId, String sku, int quantity) {
        http.post().uri("/internal/releases").body(body(reservationId, sku, quantity)).retrieve().toBodilessEntity();
    }

    public void create(String sku, int stock) {
        http.post().uri("/internal/items").body(Map.of("sku", sku, "stock", stock)).retrieve().toBodilessEntity();
    }

    @SuppressWarnings("unchecked")
    public Map<String, Integer> stock(List<String> skus) {
        if (skus.isEmpty()) {
            return Map.of();
        }
        Map<String, Integer> out = http.get().uri(b -> b.path("/internal/stock").queryParam("sku", skus).build())
            .retrieve().body(Map.class);
        return out == null ? Map.of() : out;
    }

    private static Map<String, Object> body(UUID reservationId, String sku, int quantity) {
        Map<String, Object> m = new HashMap<>();
        m.put("reservationId", reservationId);           // null en la API ingenua
        m.put("sku", sku);
        m.put("quantity", quantity);
        return m;
    }
}
