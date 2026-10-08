package hex.orders.infrastructure.inbound.http;

import hex.orders.application.port.out.OrdersSummary;
import hex.orders.application.usecase.GetOrdersSummary;
import hex.orders.infrastructure.inbound.http.ApiDtos.MoneyDto;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.time.Instant;
import java.util.List;
import java.util.UUID;

// Taller 09: la proyección orders_summary, tal cual está. Eventualmente consistente con /orders.
@RestController
@RequestMapping("/api/v1/reports")
public class ReportsController {

    public record SummaryRow(UUID customerId, int ordersCreated, int ordersCancelled, MoneyDto openAmount, Instant updatedAt) {
        static SummaryRow from(OrdersSummary.Row r) {
            return new SummaryRow(r.customerId(), r.ordersCreated(), r.ordersCancelled(), MoneyDto.from(r.openAmount()), r.updatedAt());
        }
    }

    public record SummaryResponse(List<SummaryRow> items) {}

    private final GetOrdersSummary getOrdersSummary;
    private final ActorResolver actors;

    public ReportsController(GetOrdersSummary getOrdersSummary, ActorResolver actors) {
        this.getOrdersSummary = getOrdersSummary;
        this.actors = actors;
    }

    @GetMapping("/orders-summary")
    SummaryResponse ordersSummary(@AuthenticationPrincipal Jwt jwt) {
        return new SummaryResponse(getOrdersSummary.execute(actors.from(jwt)).stream().map(SummaryRow::from).toList());
    }
}
