package hex.orders.infrastructure.outbound.payment.grpc;

import hex.orders.domain.Money;
import hex.orders.domain.Payment;
import hex.payments.v1.AuthorizeRequest;
import hex.payments.v1.AuthorizeResponse;
import hex.payments.v1.PaymentServiceGrpc;
import io.grpc.ManagedChannel;
import io.grpc.Server;
import io.grpc.Status;
import io.grpc.inprocess.InProcessChannelBuilder;
import io.grpc.inprocess.InProcessServerBuilder;
import io.grpc.stub.StreamObserver;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import java.io.IOException;
import java.util.concurrent.atomic.AtomicReference;
import java.util.function.Consumer;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

// El adaptador contra un servidor en proceso (sin red, sin Boot): qué manda y cómo traduce cada
// código. Es la prueba del anillo "adaptador aislado" para un cliente gRPC.
class GrpcPaymentGatewayTest {

    private final AtomicReference<Consumer<StreamObserver<AuthorizeResponse>>> answer = new AtomicReference<>();
    private final AtomicReference<AuthorizeRequest> received = new AtomicReference<>();
    private Server server;
    private ManagedChannel channel;
    private GrpcPaymentGateway gateway;

    @BeforeEach
    void start() throws IOException {
        String name = InProcessServerBuilder.generateName();
        server = InProcessServerBuilder.forName(name).directExecutor().addService(new PaymentServiceGrpc.PaymentServiceImplBase() {
            @Override
            public void authorize(AuthorizeRequest request, StreamObserver<AuthorizeResponse> observer) {
                received.set(request);
                answer.get().accept(observer);   // cada prueba programa la respuesta del proveedor
            }
        }).build().start();
        channel = InProcessChannelBuilder.forName(name).directExecutor().build();
        gateway = new GrpcPaymentGateway(channel, 500);
    }

    @AfterEach
    void stop() {
        channel.shutdownNow();
        server.shutdownNow();
    }

    @Test
    void sendsMoneyAsTextAndMapsAuthorized() {
        answer.set(o -> { o.onNext(AuthorizeResponse.newBuilder().setStatus(AuthorizeResponse.Status.AUTHORIZED).setReference("gw-1").build()); o.onCompleted(); });
        var payment = gateway.authorize("op-1", Money.usd("49.90"));
        assertEquals(Payment.Status.AUTHORIZED, payment.status());
        assertEquals("gw-1", payment.reference());
        assertEquals("49.90", received.get().getAmount().getAmount());   // texto, no double
        assertEquals("op-1", received.get().getOperationId());
    }

    @Test
    void unavailableIsPendingNotRejected() {
        answer.set(o -> o.onError(Status.UNAVAILABLE.withDescription("down").asRuntimeException()));
        assertEquals(Payment.Status.PENDING, gateway.authorize("op-2", Money.usd("10.00")).status());
    }

    @Test
    void deadlineExceededIsPendingNotRejected() {
        answer.set(o -> o.onError(Status.DEADLINE_EXCEEDED.asRuntimeException()));
        assertEquals(Payment.Status.PENDING, gateway.authorize("op-3", Money.usd("10.00")).status());
    }

    @Test
    void otherStatusesAreFailuresNotDecisions() {
        answer.set(o -> o.onError(Status.INVALID_ARGUMENT.withDescription("bad money").asRuntimeException()));
        assertThrows(IllegalStateException.class, () -> gateway.authorize("op-4", Money.usd("10.00")));
    }
}
