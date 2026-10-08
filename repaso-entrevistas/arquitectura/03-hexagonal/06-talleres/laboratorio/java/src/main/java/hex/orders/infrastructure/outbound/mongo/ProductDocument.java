package hex.orders.infrastructure.outbound.mongo;

import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.mapping.Document;

// Parte 3. Documento de hex_catalog.products, con la forma de seed/products.json.
@Document("products")
public class ProductDocument {

    @Id
    String id;              // el sku, como en products.json (_id)

    String sku;
    String name;
    UnitPrice unitPrice;

    public static class UnitPrice {
        String amount;      // texto decimal, como en el contrato
        String currency;
    }
}
