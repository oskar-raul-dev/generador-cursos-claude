package hex.orders.infrastructure.outbound.postgres;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.Collection;
import java.util.List;

public interface InventoryRepository extends JpaRepository<InventoryEntity, String> {

    List<InventoryEntity> findBySkuIn(Collection<String> skus);

    // El descuento atómico: una sola sentencia que solo actúa si hay unidades. Devuelve 0 filas si
    // no las hay, y el adaptador convierte ese 0 en InsufficientInventory. Sin SELECT + UPDATE
    // separados no hay carrera entre dos pedidos por la última unidad.
    @Modifying
    @Query("UPDATE InventoryEntity i SET i.available = i.available - :quantity, i.version = i.version + 1 "
         + "WHERE i.sku = :sku AND i.available >= :quantity")
    int reserve(@Param("sku") String sku, @Param("quantity") int quantity);

    @Modifying
    @Query("UPDATE InventoryEntity i SET i.available = i.available + :quantity, i.version = i.version + 1 WHERE i.sku = :sku")
    int release(@Param("sku") String sku, @Param("quantity") int quantity);
}
