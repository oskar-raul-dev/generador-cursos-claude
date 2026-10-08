package hex.orders.application.port.out;

import hex.orders.application.Page;
import hex.orders.application.PageRequest;
import hex.orders.domain.Product;

import java.util.Optional;

// El catálogo, en el lenguaje del núcleo. Ni JPA ni MongoDB asoman: la parte 3 cambia la
// implementación de este puerto y nada más.
public interface Products {

    Optional<Product> find(String sku);

    boolean exists(String sku);

    Page<Product> list(PageRequest page);

    void save(Product product);
}
