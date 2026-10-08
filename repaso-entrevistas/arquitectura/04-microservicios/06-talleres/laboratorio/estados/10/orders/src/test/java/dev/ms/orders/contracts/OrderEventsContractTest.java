package dev.ms.orders.contracts;

import au.com.dius.pact.provider.PactVerifyProvider;
import au.com.dius.pact.provider.junit5.MessageTestTarget;
import au.com.dius.pact.provider.junit5.PactVerificationContext;
import au.com.dius.pact.provider.junit5.PactVerificationInvocationContextProvider;
import au.com.dius.pact.provider.junitsupport.Provider;
import au.com.dius.pact.provider.junitsupport.State;
import au.com.dius.pact.provider.junitsupport.loader.PactFolder;
import dev.ms.orders.entity.Order;
import dev.ms.orders.entity.OrderLine;
import dev.ms.orders.events.OrderEvents;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.TestTemplate;
import org.junit.jupiter.api.extension.ExtendWith;
import tools.jackson.databind.json.JsonMapper;

import java.math.BigDecimal;
import java.util.List;
import java.util.UUID;

// orders como PROVEEDOR de hechos (taller 10). Lee de contrato/pacts los pactos de mensajes en los que
// orders es proveedor —hoy, el de inventory sobre OrderPaid— y comprueba que el cuerpo que OrderEvents
// construye de verdad cumple lo que el consumidor declaró que lee. Sin Kafka ni base: solo el cuerpo.
@Provider("orders")
@PactFolder("../contrato/pacts")
class OrderEventsContractTest {

    @TestTemplate
    @ExtendWith(PactVerificationInvocationContextProvider.class)
    void verify(PactVerificationContext context) {
        context.verifyInteraction();
    }

    @BeforeEach
    void target(PactVerificationContext context) {
        context.setTarget(new MessageTestTarget());
    }

    // el estado que el consumidor pidió: aquí no hay nada que preparar (el mensaje se construye en
    // memoria), pero Pact exige que el proveedor lo reconozca, y eso ya es parte del acuerdo
    @State("an order has been paid")
    void anOrderHasBeenPaid() {
    }

    @PactVerifyProvider("an OrderPaid event")
    String orderPaid() {
        var order = new Order(UUID.randomUUID(), UUID.randomUUID(), "ana@ms.local",
            List.of(new OrderLine("SKU-002", "USB-C cable", 2, new BigDecimal("9.90"))));
        order.setStatus("PAID");
        return OrderEvents.payload(JsonMapper.builder().build(), UUID.randomUUID(), "OrderPaid", order);
    }
}
