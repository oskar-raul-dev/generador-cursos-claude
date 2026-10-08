package dev.mono.legacy.inventory.internal;

import jakarta.persistence.LockModeType;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Lock;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;

import java.util.Optional;


public interface ProductRepository extends JpaRepository<Product, String> {
    // taller 07: SELECT ... FOR UPDATE. El segundo comprador espera a que el primero confirme y lee
    // el stock que dejó, en lugar del que había antes.
    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("select p from Product p where p.sku = :sku")
    Optional<Product> findForUpdate(String sku);

    @Modifying(flushAutomatically = true)          // antes, los cambios pendientes (el estado del pedido)
    @Query("update Product p set p.stock = p.stock + :quantity where p.sku = :sku")
    int addStock(String sku, int quantity);
}
