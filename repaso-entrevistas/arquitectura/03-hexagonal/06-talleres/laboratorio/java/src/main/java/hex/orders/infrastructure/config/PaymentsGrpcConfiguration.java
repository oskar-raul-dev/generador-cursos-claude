package hex.orders.infrastructure.config;

import hex.orders.application.port.out.PaymentGateway;
import hex.orders.infrastructure.outbound.payment.grpc.GrpcPaymentGateway;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.grpc.client.GrpcChannelFactory;

// Taller 10. Con hex.payment.provider=grpc, el bean PaymentGateway es el cliente gRPC; el canal lo
// abre la fábrica de Boot con la dirección de spring.grpc.client.channels.payments.
@Configuration
@ConditionalOnProperty(name = "hex.payment.provider", havingValue = "grpc")
public class PaymentsGrpcConfiguration {

    @Bean
    PaymentGateway grpcPaymentGateway(GrpcChannelFactory channels, HexProperties properties) {
        return new GrpcPaymentGateway(channels.createChannel("payments"), properties.payment().deadlineMs());
    }
}
