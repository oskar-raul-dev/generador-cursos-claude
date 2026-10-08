package dev.ms.monolith.repository;

import dev.ms.monolith.entity.Product;
import org.springframework.data.jpa.repository.JpaRepository;

// Solo el catálogo. El stock ya no se lee con JOIN: se pide a Inventory (taller 02).
public interface ProductRepository extends JpaRepository<Product, String> {
}
