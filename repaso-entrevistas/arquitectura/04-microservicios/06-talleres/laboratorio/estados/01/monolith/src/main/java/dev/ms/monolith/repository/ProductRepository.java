package dev.ms.monolith.repository;

import dev.ms.monolith.entity.Product;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.math.BigDecimal;
import java.util.Collection;
import java.util.List;
import java.util.Optional;

public interface ProductRepository extends JpaRepository<Product, String> {

    // El catálogo con su stock, en UNA consulta que cruza dos módulos: products (catalog) e
    // inventory. Cómodo hoy; el día que inventory viva en otra base, esta línea deja de compilar
    // en la cabeza de alguien (taller 02).
    @Query(value = """
        SELECT p.sku, p.name, p.unit_price AS unitPrice, p.currency, i.available
          FROM products p JOIN inventory i ON i.sku = p.sku
         ORDER BY p.sku""", nativeQuery = true)
    List<ProductStock> findAllWithStock();

    @Query(value = """
        SELECT p.sku, p.name, p.unit_price AS unitPrice, p.currency, i.available
          FROM products p JOIN inventory i ON i.sku = p.sku
         WHERE p.sku = :sku""", nativeQuery = true)
    Optional<ProductStock> findWithStock(@Param("sku") String sku);

    // Lo que usa el alta de pedidos: precio, nombre y existencias de golpe, con las filas de
    // inventory bloqueadas hasta el commit. Es el JOIN de orders contra las tablas de inventory.
    @Query(value = """
        SELECT p.sku, p.name, p.unit_price AS unitPrice, p.currency, i.available
          FROM products p JOIN inventory i ON i.sku = p.sku
         WHERE p.sku IN (:skus)
           FOR UPDATE OF i""", nativeQuery = true)
    List<ProductStock> lockForOrder(@Param("skus") Collection<String> skus);

    interface ProductStock {
        String getSku();
        String getName();
        BigDecimal getUnitPrice();
        String getCurrency();
        Integer getAvailable();
    }
}
