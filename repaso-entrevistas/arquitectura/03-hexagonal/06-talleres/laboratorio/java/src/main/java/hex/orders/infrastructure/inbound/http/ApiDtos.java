package hex.orders.infrastructure.inbound.http;

import hex.orders.application.Page;
import hex.orders.application.port.out.Notifications;
import hex.orders.application.usecase.ListProducts;
import hex.orders.domain.Money;
import hex.orders.domain.Order;
import hex.orders.domain.OrderLine;
import hex.orders.domain.Payment;
import jakarta.validation.Valid;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;

import java.time.Instant;
import java.util.List;
import java.util.UUID;

// Los DTO del contrato HTTP y sus mapeos desde el modelo de aplicación. Son la forma pública:
// nombres, tipos y validación de forma. El núcleo nunca los ve.
public final class ApiDtos {

    private ApiDtos() {}

    // ---------------------------------------------------------------- entrada

    public record LoginRequest(@NotBlank @Email String email, @NotBlank @Size(min = 8) String password) {}

    public record MoneyDto(
        @NotNull @Pattern(regexp = "^-?[0-9]+\\.[0-9]{2}$", message = "must be a decimal with two digits") String amount,
        @NotNull @Pattern(regexp = "^[A-Z]{3}$") String currency) {

        public Money toMoney() {
            return Money.of(amount, currency);
        }

        public static MoneyDto from(Money money) {
            return new MoneyDto(money.amountAsText(), money.currency());
        }
    }

    public record CreateProductRequest(
        @NotNull @Pattern(regexp = "^SKU-[0-9]{3,}$") String sku,
        @NotBlank @Size(max = 120) String name,
        @NotNull @Valid MoneyDto unitPrice,
        @NotNull @Min(0) Integer stock) {}

    public record LineRequest(
        @NotNull @Pattern(regexp = "^SKU-[0-9]{3,}$") String sku,
        @NotNull @Min(1) @Max(1000) Integer quantity) {}

    public record CreateOrderRequest(@NotNull @NotEmpty @Size(max = 50) List<@Valid LineRequest> lines) {

        // Huella canónica del cuerpo para la idempotencia: mismo contenido, misma huella.
        String canonical() {
            return lines.stream().map(l -> l.sku() + ":" + l.quantity()).reduce((a, b) -> a + "," + b).orElse("");
        }
    }

    // ---------------------------------------------------------------- salida

    public record TokenResponse(String accessToken, String tokenType, long expiresIn) {}

    public record ProductResponse(String sku, String name, MoneyDto unitPrice, int stock) {
        public static ProductResponse from(ListProducts.ProductWithStock p) {
            return new ProductResponse(p.product().sku(), p.product().name(), MoneyDto.from(p.product().unitPrice()), p.stock());
        }
    }

    public record OrderLineResponse(String sku, String name, int quantity, MoneyDto unitPrice, MoneyDto lineTotal) {
        public static OrderLineResponse from(OrderLine l) {
            return new OrderLineResponse(l.sku(), l.name(), l.quantity(), MoneyDto.from(l.unitPrice()), MoneyDto.from(l.lineTotal()));
        }
    }

    public record PaymentDto(String status, String operationId, String reference) {
        public static PaymentDto from(Payment p) {
            return p == null ? null : new PaymentDto(p.status().name(), p.operationId(), p.reference());
        }
    }

    public record OrderResponse(UUID id, UUID customerId, String status, List<OrderLineResponse> lines,
                                MoneyDto total, PaymentDto payment, Instant createdAt) {
        public static OrderResponse from(Order o) {
            return new OrderResponse(o.id(), o.customerId(), o.status().name(),
                o.lines().stream().map(OrderLineResponse::from).toList(),
                MoneyDto.from(o.total()), PaymentDto.from(o.payment()), o.createdAt());
        }
    }

    public record PaymentResponse(UUID orderId, String orderStatus, PaymentDto payment) {
        public static PaymentResponse from(Order o, Payment p) {
            return new PaymentResponse(o.id(), o.status().name(), PaymentDto.from(p));
        }
    }

    public record NotificationResponse(UUID id, UUID orderId, String type, String recipient, Instant createdAt) {
        public static NotificationResponse from(Notifications.Notification n) {
            return new NotificationResponse(n.id(), n.orderId(), n.type(), n.recipient(), n.createdAt());
        }
    }

    public record PageResponse<T>(List<T> items, String nextCursor) {
        public static <T> PageResponse<T> from(Page<T> page) {
            return new PageResponse<>(page.items(), page.nextCursor());
        }
    }
}
