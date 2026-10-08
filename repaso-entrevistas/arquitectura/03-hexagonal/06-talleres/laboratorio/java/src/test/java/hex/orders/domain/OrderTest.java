package hex.orders.domain;

import org.junit.jupiter.api.Test;

import java.time.Instant;
import java.util.List;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

// Pruebas del agregado sin Spring, sin base y sin mocks: la máquina de estados del contrato.
class OrderTest {

    private static final Instant NOW = Instant.parse("2026-09-27T12:00:00Z");
    private static final UUID ANA = UUID.fromString("11111111-1111-4111-8111-111111111111");

    private static Order order(String amount) {
        return Order.place(UUID.randomUUID(), ANA,
            List.of(new OrderLine("SKU-001", "Mechanical keyboard", 1, Money.usd(amount))), NOW);
    }

    @Test
    void anOrderWithoutLinesIsRejected() {
        assertThrows(EmptyOrder.class, () -> Order.place(UUID.randomUUID(), ANA, List.of(), NOW));
    }

    @Test
    void aNewOrderIsConfirmedAndTotalsItsLines() {
        var order = Order.place(UUID.randomUUID(), ANA, List.of(
            new OrderLine("SKU-001", "Mechanical keyboard", 2, Money.usd("49.90")),
            new OrderLine("SKU-002", "USB-C cable", 1, Money.usd("9.90"))), NOW);
        assertEquals(OrderStatus.CONFIRMED, order.status());
        assertEquals("109.70", order.total().amountAsText());
    }

    @Test
    void authorizedPaymentMovesToPaidAndPaidIsNeitherPayableNorCancellable() {
        var order = order("9.90");
        order.applyPayment(new Payment(Payment.Status.AUTHORIZED, "op-1", "gw-op-1"));
        assertEquals(OrderStatus.PAID, order.status());
        assertThrows(OrderNotPayable.class, () -> order.applyPayment(new Payment(Payment.Status.AUTHORIZED, "op-2", null)));
        assertThrows(OrderNotCancellable.class, () -> order.cancel(NOW));
    }

    @Test
    void rejectedPaymentStaysPayableButPendingDoesNot() {
        var rejected = order("1499.00");
        rejected.applyPayment(new Payment(Payment.Status.REJECTED, "op-1", null));
        assertTrue(rejected.isPayable());

        var pending = order("666.00");
        pending.applyPayment(new Payment(Payment.Status.PENDING, "op-2", null));
        assertFalse(pending.isPayable());
        assertTrue(pending.isCancellable());
    }

    @Test
    void placeEmitsOrderCreatedWithTheTotal() {
        var order = order("9.90");
        var events = order.pullEvents();
        assertEquals(1, events.size());
        assertEquals("ORDER_CREATED", events.getFirst().type());
        assertEquals(0, order.pullEvents().size());
    }

    @Test
    void cancelIsIdempotentAndEmitsTheFactOnlyOnce() {
        var order = order("9.90");
        order.pullEvents();                       // taller 09: OrderCreated ya recogido al crear
        assertTrue(order.cancel(NOW));
        assertEquals(1, order.pullEvents().size());
        assertFalse(order.cancel(NOW));
        assertEquals(0, order.pullEvents().size());
        assertEquals(OrderStatus.CANCELLED, order.status());
    }
}
