package hex.payments;

import hex.payments.v1.AuthorizeRequest;
import hex.payments.v1.AuthorizeResponse;
import hex.payments.v1.PaymentServiceGrpc;
import io.grpc.Context;
import io.grpc.Status;
import io.grpc.stub.StreamObserver;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

// El proveedor: la regla determinista de §11 y tres cosas que un proveedor real tiene y un stub no:
// idempotencia por operation_id (misma clave, misma respuesta, aunque la primera se perdiera),
// fallos inyectables y respeto al deadline del cliente (si ya expiró, no se trabaja).
@Service
public class PaymentService extends PaymentServiceGrpc.PaymentServiceImplBase {

    private static final Logger log = LoggerFactory.getLogger(PaymentService.class);
    private static final BigDecimal LIMIT = new BigDecimal("1000.00");
    private static final BigDecimal UNCERTAIN = new BigDecimal("666.00");

    private final Faults faults;
    private final Map<String, AuthorizeResponse> answered = new ConcurrentHashMap<>();

    public PaymentService(Faults faults) {
        this.faults = faults;
    }

    @Override
    public void authorize(AuthorizeRequest request, StreamObserver<AuthorizeResponse> observer) {
        String operationId = request.getOperationId();
        String amount = request.getAmount().getAmount();
        Faults.Fault fault = faults.current();
        log.info("authorize {} {} {} (fault={})", operationId, amount, request.getAmount().getCurrency(), fault.mode());

        if (operationId.isBlank() || !amount.matches("^[0-9]+\\.[0-9]{2}$")) {
            observer.onError(Status.INVALID_ARGUMENT.withDescription("operation_id and amount (two decimals) are required").asRuntimeException());
            return;
        }
        // Fallos inyectados: latencia (el cliente verá DEADLINE_EXCEEDED si su plazo es menor) o caída.
        if ("latency".equals(fault.mode())) {
            sleep(fault.latencyMs());
            if (Context.current().isCancelled()) {
                log.warn("authorize {}: the client gave up before we answered", operationId);
                return;   // el deadline del cliente venció: no se responde a nadie
            }
        }
        if ("unavailable".equals(fault.mode())) {
            observer.onError(Status.UNAVAILABLE.withDescription("payments provider is down (injected)").asRuntimeException());
            return;
        }
        // Idempotencia del proveedor: la misma operación responde lo mismo, sin volver a decidir.
        AuthorizeResponse previous = answered.get(operationId);
        if (previous != null) {
            log.info("authorize {}: replaying previous answer", operationId);
            observer.onNext(previous);
            observer.onCompleted();
            return;
        }
        BigDecimal total = new BigDecimal(amount);
        if (total.compareTo(UNCERTAIN) == 0) {
            // el importe del resultado incierto: el proveedor "no respondió"
            observer.onError(Status.UNAVAILABLE.withDescription("provider did not answer").asRuntimeException());
            return;
        }
        var response = total.compareTo(LIMIT) > 0
            ? AuthorizeResponse.newBuilder().setStatus(AuthorizeResponse.Status.REJECTED).build()
            : AuthorizeResponse.newBuilder().setStatus(AuthorizeResponse.Status.AUTHORIZED).setReference("gw-" + operationId).build();
        answered.put(operationId, response);
        observer.onNext(response);
        observer.onCompleted();
    }

    private static void sleep(long ms) {
        try {
            Thread.sleep(ms);
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
        }
    }
}
