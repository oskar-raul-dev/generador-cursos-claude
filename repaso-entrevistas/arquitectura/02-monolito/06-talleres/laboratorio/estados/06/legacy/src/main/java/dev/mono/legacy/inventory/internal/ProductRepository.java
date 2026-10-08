package dev.mono.legacy.inventory.internal;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;


public interface ProductRepository extends JpaRepository<Product, String> {
    @Modifying(flushAutomatically = true)          // antes, los cambios pendientes (el estado del pedido)
    @Query("update Product p set p.stock = p.stock + :quantity where p.sku = :sku")
    int addStock(String sku, int quantity);
}
