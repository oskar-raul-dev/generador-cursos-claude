package hex.orders.infrastructure.inbound.jms;

import hex.orders.domain.Money;
import hex.orders.domain.Order;

import java.util.List;

// Los mensajes del contrato asyncapi.yaml. Son la forma pública del borde de mensajes, como los
// DTO de ApiDtos lo son del borde HTTP. El núcleo nunca los ve.
public final class JmsMessages {

    private JmsMessages() {}

    public record Line(String sku, Integer quantity) {}

    public record OrderRequested(String operationId, String customerEmail, List<Line> lines) {

        // Misma huella canónica que el cuerpo HTTP: un pedido igual por HTTP o por cola es la misma operación.
        public String canonical() {
            return lines.stream().map(l -> l.sku() + ":" + l.quantity()).reduce((a, b) -> a + "," + b).orElse("");
        }
    }

    public record MoneyDto(String amount, String currency) {
        static MoneyDto from(Money m) {
            return new MoneyDto(m.amountAsText(), m.currency());
        }
    }

    public record OrderReply(String operationId, String status, String orderId, String orderStatus,
                             MoneyDto total, Boolean replayed, String code, String message) {

        static OrderReply accepted(String operationId, Order order, boolean replayed) {
            return new OrderReply(operationId, "ACCEPTED", order.id().toString(), order.status().name(),
                MoneyDto.from(order.total()), replayed, null, null);
        }

        static OrderReply rejected(String operationId, String code, String message) {
            return new OrderReply(operationId, "REJECTED", null, null, null, null, code, message);
        }
    }
}
