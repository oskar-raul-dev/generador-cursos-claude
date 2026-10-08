package dev.mono.legacy.repository;

import dev.mono.legacy.entity.Product;
import org.springframework.data.jpa.repository.JpaRepository;


public interface ProductRepository extends JpaRepository<Product, String> {
}
