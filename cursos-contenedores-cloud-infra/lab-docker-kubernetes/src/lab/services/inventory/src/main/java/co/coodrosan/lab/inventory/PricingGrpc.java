package co.coodrosan.lab.inventory;

import co.coodrosan.lab.pricing.v1.GetPriceRequest;
import co.coodrosan.lab.pricing.v1.Price;
import co.coodrosan.lab.pricing.v1.PricingGrpc.PricingBlockingStub;
import io.grpc.CallOptions;
import io.grpc.Channel;
import io.grpc.ClientCall;
import io.grpc.ClientInterceptor;
import io.grpc.ForwardingClientCall;
import io.grpc.ManagedChannel;
import io.grpc.Metadata;
import io.grpc.MethodDescriptor;
import io.grpc.netty.shaded.io.grpc.netty.GrpcSslContexts;
import io.grpc.netty.shaded.io.grpc.netty.NettyChannelBuilder;
import java.time.Duration;
import java.util.concurrent.TimeUnit;
import javax.net.ssl.SSLException;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.slf4j.MDC;
import org.springframework.boot.ssl.SslBundle;

// G10 (Fase 23): el precio por gRPC. El canal usa el mismo bundle "pricing" de G8 (certificado de cliente y CA),
// se rearma cuando el bundle se renueva, y lleva el x-request-id de G7 en los metadatos. El balanceo lo decide el
// target: "pricing.apps.svc…:9090" (un Service normal: una conexión, una réplica) o "dns:///pricing-grpc…:9090"
// (un Service headless: todas las réplicas, round_robin en el cliente). Ese es todo el tema de la Fase 23.
class PricingGrpc {

    private static final Logger log = LoggerFactory.getLogger(PricingGrpc.class);
    private static final Metadata.Key<String> REQUEST_ID = Metadata.Key.of("x-request-id", Metadata.ASCII_STRING_MARSHALLER);

    private final String target;
    private final String policy;
    private final Duration deadline;
    private volatile ManagedChannel channel;
    private volatile PricingBlockingStub stub;

    PricingGrpc(String target, String policy, Duration deadline, SslBundle bundle) {
        this.target = target;
        this.policy = policy;
        this.deadline = deadline;
        rebuild(bundle);
    }

    /** Arma el canal con el bundle, y cierra el anterior (si lo había) cuando terminan sus llamadas. */
    synchronized void rebuild(SslBundle bundle) {
        ManagedChannel old = channel;
        try {
            channel = NettyChannelBuilder.forTarget(target)
                    .sslContext(GrpcSslContexts.forClient()
                            .keyManager(bundle.getManagers().getKeyManagerFactory())
                            .trustManager(bundle.getManagers().getTrustManagerFactory())
                            .build())
                    .defaultLoadBalancingPolicy(policy)
                    .intercept(requestId())
                    .build();
        } catch (SSLException e) {
            throw new IllegalStateException("no se pudo armar el TLS del canal de pricing", e);
        }
        stub = co.coodrosan.lab.pricing.v1.PricingGrpc.newBlockingStub(channel);
        log.info("canal gRPC a pricing: {} ({})", target, policy);
        if (old != null) {
            old.shutdown();
        }
    }

    /** El precio, con el plazo de G9 en cada llamada (en gRPC se llama deadline). */
    Price getPrice(String sku, String store) {
        return stub.withDeadlineAfter(deadline.toMillis(), TimeUnit.MILLISECONDS)
                .getPrice(GetPriceRequest.newBuilder().setSku(sku).setStore(store).build());
    }

    private static ClientInterceptor requestId() {
        return new ClientInterceptor() {
            @Override
            public <Q, R> ClientCall<Q, R> interceptCall(MethodDescriptor<Q, R> method, CallOptions options, Channel next) {
                return new ForwardingClientCall.SimpleForwardingClientCall<>(next.newCall(method, options)) {
                    @Override
                    public void start(Listener<R> listener, Metadata headers) {
                        String id = MDC.get("request_id");
                        if (id != null) {
                            headers.put(REQUEST_ID, id);
                        }
                        super.start(listener, headers);
                    }
                };
            }
        };
    }
}
