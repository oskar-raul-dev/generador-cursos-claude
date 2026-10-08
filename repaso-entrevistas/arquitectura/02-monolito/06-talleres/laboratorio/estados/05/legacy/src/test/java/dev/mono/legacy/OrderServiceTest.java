package dev.mono.legacy;

import dev.mono.legacy.dto.CreateOrderRequest;
import dev.mono.legacy.entity.Product;
import dev.mono.legacy.entity.User;
import dev.mono.legacy.repository.OrderRepository;
import dev.mono.legacy.repository.ProductRepository;
import dev.mono.legacy.repository.UserRepository;
import dev.mono.legacy.service.OrderService;
import dev.mono.legacy.util.LegacyException;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Disabled;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.context.annotation.Import;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.context.ActiveProfiles;

import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.Executors;
import java.util.concurrent.Future;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.atomic.AtomicInteger;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

// Taller 05: contra PostgreSQL en un contenedor, la misma base que en ejecución. Durante el taller
// corrió también contra SQLite (06/05 §6): allí la sobreventa no se ve y el dinero pierde la escala.
@SpringBootTest
@ActiveProfiles("test")
@Import(PostgresTestConfig.class)
class OrderServiceTest {
    static final UUID ANA = UUID.fromString("11111111-1111-4111-8111-111111111111");

    @Autowired OrderService orders;
    @Autowired OrderRepository orderRepository;
    @Autowired ProductRepository products;
    @Autowired UserRepository users;
    @Autowired JdbcTemplate jdbc;

    @BeforeEach
    void seed() {
        // cada prueba parte de la misma semilla, sin depender del orden en que corran
        jdbc.execute("DELETE FROM notifications");
        jdbc.execute("DELETE FROM order_lines");
        jdbc.execute("DELETE FROM payments");
        jdbc.execute("DELETE FROM orders");
        jdbc.execute("DELETE FROM products");
        jdbc.execute("DELETE FROM users");
        User ana = new User();
        ana.setId(ANA);
        ana.setEmail("ana@mono.local");
        ana.setPasswordHash("x");
        ana.setRole("customer");
        users.save(ana);
        product("SKU-001", "Mechanical keyboard", "49.90", 20);
        product("SKU-002", "USB-C cable", "9.90", 100);
        product("SKU-003", "27\" monitor", "222.00", 5);
    }

    private void product(String sku, String name, String price, int stock) {
        Product p = new Product();
        p.setSku(sku);
        p.setName(name);
        p.setPrice(new BigDecimal(price));
        p.setStock(stock);
        products.save(p);
    }

    @Test
    void createOrderTakesStock() {
        var order = orders.create(ANA, List.of(new CreateOrderRequest.Line("SKU-001", 2)));
        assertEquals("CONFIRMED", order.getStatus());
        assertEquals(new BigDecimal("99.80"), order.getTotal());
        assertEquals(18, products.findById("SKU-001").orElseThrow().getStock());
    }

    @Test
    void notEnoughStock() {
        assertThrows(LegacyException.class,
            () -> orders.create(ANA, List.of(new CreateOrderRequest.Line("SKU-001", 50))));
    }

    // con SQLite esta prueba no se podía escribir: el stock lo devuelve un trigger de PostgreSQL
    @Test
    void cancelReturnsStock() {
        var order = orders.create(ANA, List.of(new CreateOrderRequest.Line("SKU-001", 2)));
        orders.cancel(order.getId());
        assertEquals(20, products.findById("SKU-001").orElseThrow().getStock());
    }

    // el total que se cobra es exacto: 3 × 9.90 son 29.70, ni un poco más
    @Test
    void totalIsExact() {
        var order = orders.create(ANA, List.of(new CreateOrderRequest.Line("SKU-002", 3)));
        var stored = orderRepository.findById(order.getId()).orElseThrow();
        assertEquals(new BigDecimal("29.70"), stored.getTotal());
    }

    // veinte clientes compran a la vez el último monitor (hay 5): se venden 5, ni uno más
    @Disabled("en rojo contra PostgreSQL: leer-restar-escribir vende de más; lo corrige el taller 07")
    @Test
    void concurrentOrdersNeverOversell() throws Exception {
        var pool = Executors.newFixedThreadPool(20);
        var sold = new AtomicInteger();
        var start = new CountDownLatch(1);
        List<Future<?>> buyers = new ArrayList<>();
        for (int i = 0; i < 20; i++) {
            buyers.add(pool.submit(() -> {
                start.await();
                try {
                    orders.create(ANA, List.of(new CreateOrderRequest.Line("SKU-003", 1)));
                    sold.incrementAndGet();
                } catch (LegacyException expected) {
                    // sin stock: es lo que tiene que pasarle a los quince últimos
                }
                return null;
            }));
        }
        start.countDown();
        for (var buyer : buyers) {
            buyer.get(60, TimeUnit.SECONDS);
        }
        pool.shutdown();
        int stock = products.findById("SKU-003").orElseThrow().getStock();
        assertEquals(5, sold.get(), "pedidos confirmados");
        assertEquals(0, stock, "stock final");
    }
}
