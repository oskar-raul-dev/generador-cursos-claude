package dev.ms.orders.catalog;

import dev.ms.orders.config.OrdersProperties;
import dev.ms.orders.service.Errors;
import org.springframework.http.HttpHeaders;
import org.springframework.http.client.JdkClientHttpRequestFactory;
import org.springframework.stereotype.Component;
import org.springframework.web.client.ResourceAccessException;
import org.springframework.web.client.RestClient;
import org.springframework.web.context.request.RequestContextHolder;
import org.springframework.web.context.request.ServletRequestAttributes;

import java.math.BigDecimal;
import java.time.Duration;
import java.util.Collection;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

// El catálogo por HTTP contra el monolito, con el token del usuario reenviado (token relay): el
// monolito sigue exigiendo autenticación y orders no tiene credenciales propias. Es el atajo más
// corto; el taller 11 muestra la alternativa de una copia local alimentada por eventos.
@Component
public class HttpCatalog implements Catalog {

    record Money(String amount, String currency) {}
    record ProductView(String sku, String name, Money unitPrice) {}
    record Items(List<ProductView> items) {}

    private final RestClient http;

    public HttpCatalog(RestClient.Builder builder, OrdersProperties props) {
        var factory = new JdkClientHttpRequestFactory();
        factory.setReadTimeout(Duration.ofMillis(props.catalog().readTimeoutMs()));
        this.http = builder.baseUrl(props.catalog().baseUrl()).requestFactory(factory).build();
    }

    @Override
    public Map<String, Product> find(Collection<String> skus) {
        try {
            var all = http.get().uri("/api/v1/products")
                .headers(h -> h.set(HttpHeaders.AUTHORIZATION, currentAuthorization()))
                .retrieve().body(Items.class);
            return all.items().stream().filter(p -> skus.contains(p.sku()))
                .collect(Collectors.toMap(ProductView::sku, p -> new Product(p.sku(), p.name(), new BigDecimal(p.unitPrice().amount()))));
        } catch (ResourceAccessException e) {
            throw new Errors.CatalogUnavailable(e.getMessage());
        }
    }

    private static String currentAuthorization() {
        var attrs = (ServletRequestAttributes) RequestContextHolder.currentRequestAttributes();
        return attrs.getRequest().getHeader(HttpHeaders.AUTHORIZATION);
    }
}
