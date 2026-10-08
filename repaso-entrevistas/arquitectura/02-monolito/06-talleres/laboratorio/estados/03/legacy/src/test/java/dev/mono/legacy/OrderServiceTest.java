package dev.mono.legacy;

import dev.mono.legacy.entity.Product;
import dev.mono.legacy.entity.User;
import dev.mono.legacy.repository.ProductRepository;
import dev.mono.legacy.repository.UserRepository;
import dev.mono.legacy.service.OrderService;
import dev.mono.legacy.util.LegacyException;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;

import java.util.List;
import java.util.Map;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

@SpringBootTest
@ActiveProfiles("test")
class OrderServiceTest {
    static final UUID ANA = UUID.fromString("11111111-1111-4111-8111-111111111111");

    @Autowired OrderService orders;
    @Autowired ProductRepository products;
    @Autowired UserRepository users;

    @BeforeEach
    void seed() {
        User ana = new User();
        ana.setId(ANA);
        ana.setEmail("ana@mono.local");
        ana.setPasswordHash("x");
        ana.setRole("customer");
        users.save(ana);
        Product p = new Product();
        p.setSku("SKU-001");
        p.setName("Mechanical keyboard");
        p.setPrice(49.90);
        p.setStock(20);
        products.save(p);
    }

    @Test
    void createOrderTakesStock() {
        var order = orders.create(ANA, List.of(Map.of("sku", "SKU-001", "quantity", 2)));
        assertEquals("CONFIRMED", order.getStatus());
        assertEquals(99.8, order.getTotal(), 0.001);
        assertEquals(18, products.findById("SKU-001").orElseThrow().getStock());
    }

    @Test
    void notEnoughStock() {
        assertThrows(LegacyException.class,
            () -> orders.create(ANA, List.of(Map.of("sku", "SKU-001", "quantity", 50))));
    }
}
