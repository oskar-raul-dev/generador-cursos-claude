package dev.ms.orders.contracts;

import au.com.dius.pact.consumer.MockServer;
import au.com.dius.pact.consumer.dsl.PactDslJsonBody;
import au.com.dius.pact.consumer.dsl.PactBuilder;
import au.com.dius.pact.consumer.junit5.PactConsumerTestExt;
import au.com.dius.pact.consumer.junit5.PactTestFor;
import au.com.dius.pact.core.model.V4Pact;
import au.com.dius.pact.core.model.annotations.Pact;
import dev.ms.orders.config.OrdersProperties;
import dev.ms.orders.payments.Payments;
import dev.ms.orders.payments.RemotePayments;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.springframework.web.client.RestClient;

import java.math.BigDecimal;
import java.util.Map;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;

// orders como CONSUMIDOR de payments (taller 10). Cada @Pact describe una interacción que orders
// necesita, y solo con los campos que orders LEE; el test ejecuta el cliente real (RemotePayments)
// contra el simulador que Pact levanta. Al pasar, Pact escribe contrato/pacts/orders-payments.json,
// que payments verificará en SU pipeline.
@ExtendWith(PactConsumerTestExt.class)
@PactTestFor(providerName = "payments")
class PaymentsContractTest {

    static final UUID ORDER = UUID.fromString("5f1c2a4e-0000-4000-8000-000000000001");

    @Pact(consumer = "orders")
    V4Pact authorizes(PactBuilder builder) {
        return builder.usingLegacyDsl()        // Pact 4.7 escribe pactos V4; el DSL clásico sigue sirviendo
            .given("the PSP authorizes payments")
            .uponReceiving("a payment below the PSP limit")
                .method("POST").path("/payments")
                .headers(Map.of("Idempotency-Key", "pact-authorize-0001", "Content-Type", "application/json"))
                .body(new PactDslJsonBody()
                    .stringValue("orderId", ORDER.toString())
                    .stringValue("amount", "19.80")
                    .stringValue("currency", "USD"))
            .willRespondWith()
                .status(201)
                .body(new PactDslJsonBody()
                    .stringMatcher("status", "AUTHORIZED|REJECTED|PENDING", "AUTHORIZED")
                    .stringType("reference", "psp-1a2b3c4d"))   // la forma, no el valor
            .toPact(V4Pact.class);
    }

    @Pact(consumer = "orders")
    V4Pact inProgress(PactBuilder builder) {
        return builder.usingLegacyDsl()
            .given("a payment with key pact-in-progress-0001 is in progress")
            .uponReceiving("a repeated payment while the first attempt is still running")
                .method("POST").path("/payments")
                .headers(Map.of("Idempotency-Key", "pact-in-progress-0001", "Content-Type", "application/json"))
                .body(new PactDslJsonBody()
                    .stringValue("orderId", ORDER.toString())
                    .stringValue("amount", "19.80")
                    .stringValue("currency", "USD"))
            .willRespondWith()
                // orders solo mira el CÓDIGO (409 → PENDING): el cuerpo y su tipo no son asunto suyo, y
                // declararlos haría fallar el pacto por cambios que no le afectan (06/10 §9)
                .status(409)
            .toPact(V4Pact.class);
    }

    @Test
    @PactTestFor(pactMethod = "authorizes")
    void authorizedPaymentHasAReference(MockServer server) {
        var result = client(server).authorize(ORDER, new BigDecimal("19.80"), "pact-authorize-0001");
        assertThat(result.status()).isEqualTo("AUTHORIZED");
        assertThat(result.reference()).isNotBlank();
    }

    @Test
    @PactTestFor(pactMethod = "inProgress")
    void paymentInProgressIsReadAsPending(MockServer server) {
        var result = client(server).authorize(ORDER, new BigDecimal("19.80"), "pact-in-progress-0001");
        assertThat(result).isEqualTo(new Payments.Result("PENDING", null));
    }

    // el cliente real, apuntado al simulador; sin reintentos para que cada interacción ocurra una vez
    static RemotePayments client(MockServer server) {
        var payments = new OrdersProperties.Payments(server.getUrl(), 500, 2500, true,
            new OrdersProperties.Payments.RetryProps(1, 10), new OrdersProperties.Payments.BulkheadProps(4),
            new OrdersProperties.Payments.Breaker(10, 4, 50, 10, 2));
        var props = new OrdersProperties(null, null, payments, null, null, null);
        return new RemotePayments(RestClient.builder(), props);
    }
}
