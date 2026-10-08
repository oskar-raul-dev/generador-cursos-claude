package dev.mono.legacy.inventory.internal;

import org.springframework.data.jpa.repository.JpaRepository;



public interface ProductRepository extends JpaRepository<Product, String> {
    // taller 09: el bloqueo y los incrementos del stock pasaron a StockStore, que conoce las dos tablas
}
