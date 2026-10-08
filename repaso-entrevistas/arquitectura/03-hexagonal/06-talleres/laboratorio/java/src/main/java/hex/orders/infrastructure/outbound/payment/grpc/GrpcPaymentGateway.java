package hex.orders.infrastructure.outbound.payment.grpc;

import hex.orders.application.port.out.PaymentGateway;
import hex.orders.domain.Money;
import hex.orders.domain.Payment;
import hex.payments.v1.AuthorizeRequest;
import hex.payments.v1.AuthorizeResponse;
import hex.payments.v1.PaymentServiceGrpc;
import io.grpc.Channel;
import io.grpc.Metadata;
import io.grpc.Status;
import io.grpc.StatusRuntimeException;
import io.grpc.stub.MetadataUtils;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.concurrent.TimeUnit;

// Taller 10. El proveedor de pagos por la red, detrás del MISMO puerto que el determinista: el caso
// de uso AuthorizePayment no cambia una línea. Tres decisiones que son del adaptador:
//   - el plazo (deadline) por llamada, siempre; sin plazo, una llamada colgada bloquea el hilo para siempre;
//   - la clave de idempotencia en metadata, para que un reintento sea "la misma operación" para el proveedor;
//   - la traducción de códigos: UNAVAILABLE y DEADLINE_EXCEEDED son "no sé si cobró" → PENDING, NUNCA REJECTED.
//     Un timeout no significa que no hubo cobro (04/02).
public class GrpcPaymentGateway implements PaymentGateway {

    private static final Logger log = LoggerFactory.getLogger(GrpcPaymentGateway.class);
    static final Metadata.Key<String> IDEMPOTENCY_KEY = Metadata.Key.of("idempotency-key", Metadata.ASCII_STRING_MARSHALLER);

    private final PaymentServiceGrpc.PaymentServiceBlockingStub stub;
    private final long deadlineMs;

    public GrpcPaymentGateway(Channel channel, long deadlineMs) {
        this.stub = PaymentServiceGrpc.newBlockingStub(channel);
        this.deadlineMs = deadlineMs;
    }

    @Override
    public Payment authorize(String operationId, Money amount) {
        var metadata = new Metadata();
        metadata.put(IDEMPOTENCY_KEY, operationId);
        var request = AuthorizeRequest.newBuilder()
            .setOperationId(operationId)
            .setAmount(hex.payments.v1.Money.newBuilder().setAmount(amount.amountAsText()).setCurrency(amount.currency()))
            .build();
        try {
            AuthorizeResponse response = stub
                .withInterceptors(MetadataUtils.newAttachHeadersInterceptor(metadata))
                .withDeadlineAfter(deadlineMs, TimeUnit.MILLISECONDS)   // nuevo plazo en cada llamada, nunca un stub con plazo fijo
                .authorize(request);
            return switch (response.getStatus()) {
                case AUTHORIZED -> new Payment(Payment.Status.AUTHORIZED, operationId, response.getReference());
                case REJECTED -> new Payment(Payment.Status.REJECTED, operationId, null);
                default -> throw new IllegalStateException("provider answered with status " + response.getStatus());
            };
        } catch (StatusRuntimeException e) {
            Status.Code code = e.getStatus().getCode();
            if (code == Status.Code.UNAVAILABLE || code == Status.Code.DEADLINE_EXCEEDED) {
                // no sabemos si cobró: el pedido queda pendiente y la misma clave decidirá después
                log.warn("payments: {} for operation {} → PENDING ({})", code, operationId, e.getStatus().getDescription());
                return new Payment(Payment.Status.PENDING, operationId, null);
            }
            throw new IllegalStateException("payments provider failed: " + e.getStatus(), e);   // INVALID_ARGUMENT, INTERNAL…: 500
        }
    }
}
