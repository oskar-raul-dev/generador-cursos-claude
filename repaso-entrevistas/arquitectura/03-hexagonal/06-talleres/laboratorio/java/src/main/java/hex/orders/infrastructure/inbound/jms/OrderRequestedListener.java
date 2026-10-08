package hex.orders.infrastructure.inbound.jms;

import hex.orders.application.Actor;
import hex.orders.application.error.IdempotencyKeyReused;
import hex.orders.application.error.NotFound;
import hex.orders.application.port.out.Users;
import hex.orders.application.usecase.CreateOrder;
import hex.orders.domain.InsufficientInventory;
import hex.orders.infrastructure.inbound.http.IdempotencyKeys;
import hex.orders.infrastructure.inbound.jms.JmsMessages.OrderReply;
import hex.orders.infrastructure.inbound.jms.JmsMessages.OrderRequested;
import jakarta.jms.BytesMessage;
import jakarta.jms.JMSException;
import jakarta.jms.Message;
import jakarta.jms.Queue;
import jakarta.jms.TextMessage;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.jms.annotation.JmsListener;
import org.springframework.jms.core.JmsTemplate;
import org.springframework.stereotype.Component;
import tools.jackson.databind.ObjectMapper;

import java.nio.charset.StandardCharsets;
import java.util.UUID;

// Taller 08. Un adaptador de ENTRADA más, sobre el mismo caso de uso que sirve POST /api/v1/orders.
// Traduce el mensaje a un comando, la identidad del emisor a un Actor y el resultado a una
// respuesta correlacionada. Tres destinos posibles para un mensaje:
//   - aceptado o rechazado por negocio → respuesta y commit (el broker no vuelve a entregarlo);
//   - ilegible o fallo técnico → excepción, rollback, redelivery y, tras N intentos, DLQ;
//   - repetido (mismo operationId) → la misma respuesta de la primera vez, sin segundo pedido.
@Component
public class OrderRequestedListener {

    private static final Logger log = LoggerFactory.getLogger(OrderRequestedListener.class);

    private final CreateOrder createOrder;
    private final Users users;
    private final JmsTemplate jms;
    private final ObjectMapper json;
    private final String replyQueue;

    public OrderRequestedListener(CreateOrder createOrder, Users users, JmsTemplate jms, ObjectMapper json,
                                  hex.orders.infrastructure.config.HexProperties properties) {
        this.createOrder = createOrder;
        this.users = users;
        this.jms = jms;
        this.json = json;
        this.replyQueue = properties.jms().reply();
    }

    // Se recibe el Message crudo y no @Payload String: un cliente STOMP con content-length entrega
    // un BytesMessage, uno JMS un TextMessage, y las cabeceras de un mensaje STOMP no siempre traen
    // JMSMessageID. El borde asume lo mínimo del emisor.
    @JmsListener(destination = "${hex.jms.inbound}")
    public void onOrderRequested(Message message) throws JMSException {
        String body = bodyOf(message);
        String messageId = message.getJMSMessageID() != null ? message.getJMSMessageID() : "msg-" + UUID.randomUUID();
        String correlationId = message.getJMSCorrelationID();
        // JMSReplyTo solo si es una cola: un cliente STOMP que ponga `reply-to` sin más llega aquí
        // como un destino de tipo topic y el envío fallaría ("does not support MULTICAST routing").
        Queue replyTo = message.getJMSReplyTo() instanceof Queue queue ? queue : null;
        Integer deliveryCount = message.propertyExists("JMSXDeliveryCount") ? message.getIntProperty("JMSXDeliveryCount") : null;
        String chaos = message.propertyExists("hexChaos") ? message.getStringProperty("hexChaos") : null;
        String correlation = correlationId != null ? correlationId : messageId;
        log.info("jms: OrderRequested received (delivery #{}, correlation {})", deliveryCount, correlation);

        // Un cuerpo ilegible NO se responde: no hay a quién ni con qué operationId. Se lanza y el
        // broker reintenta hasta apartarlo en la DLQ (mensaje envenenado).
        OrderRequested request = json.readValue(body, OrderRequested.class);
        OrderReply reply = handle(request);

        if ("crash-after-commit".equals(chaos) && (deliveryCount == null || deliveryCount <= 1)) {
            // Solo laboratorio: la base ya confirmó (el caso de uso cerró su transacción) y la sesión
            // JMS todavía no (el ACK ocurre cuando este método vuelve). Justo la ventana. Solo en la
            // primera entrega: un mensaje que matara a cada consumidor que lo recibe sería un
            // mensaje envenenado, no una caída transitoria.
            log.error("jms: CHAOS crash-after-commit — halting the JVM before the JMS ACK");
            Runtime.getRuntime().halt(137);
        }
        // La respuesta viaja en la misma sesión transaccionada: sale con el commit, o no sale.
        String payload = json.writeValueAsString(reply);
        if (replyTo != null) {
            jms.convertAndSend(replyTo, payload, m -> { m.setJMSCorrelationID(correlation); return m; });
        } else {
            jms.convertAndSend(replyQueue, payload, m -> { m.setJMSCorrelationID(correlation); return m; });
        }
        log.info("jms: replied {} for operation {}", reply.status(), request.operationId());
    }

    // El emisor es un sistema de confianza (se autenticó en el broker); a nombre de quién actúa lo
    // dice el mensaje, y el Actor se construye con el usuario real, nunca con lo que el mensaje diga
    // de su rol.
    private OrderReply handle(OrderRequested request) {
        String operationId = request.operationId();
        if (operationId == null || operationId.length() < 8 || operationId.length() > 128
            || request.lines() == null || request.lines().isEmpty() || request.customerEmail() == null) {
            return OrderReply.rejected(String.valueOf(operationId), "VALIDATION_FAILED", "operationId, customerEmail and lines are required");
        }
        var user = users.findByEmail(request.customerEmail());
        if (user.isEmpty()) {
            return OrderReply.rejected(operationId, "UNKNOWN_CUSTOMER", request.customerEmail());
        }
        var actor = new Actor(user.get().id(), user.get().email(), Actor.Role.valueOf(user.get().role().name()));
        try {
            var result = createOrder.execute(new CreateOrder.Command(actor, operationId,
                IdempotencyKeys.hash(request.canonical()),
                request.lines().stream().map(l -> new CreateOrder.LineRequest(l.sku(), l.quantity())).toList()));
            return OrderReply.accepted(operationId, result.order(), result.replayed());
        } catch (NotFound e) {
            return OrderReply.rejected(operationId, "PRODUCT_NOT_FOUND", e.identifier());
        } catch (InsufficientInventory e) {
            return OrderReply.rejected(operationId, "INSUFFICIENT_INVENTORY", e.getMessage());
        } catch (IdempotencyKeyReused e) {
            return OrderReply.rejected(operationId, "IDEMPOTENCY_KEY_REUSED", e.getMessage());
        }
    }

    private static String bodyOf(Message message) throws JMSException {
        if (message instanceof TextMessage text) {
            return text.getText();
        }
        if (message instanceof BytesMessage bytes) {
            byte[] raw = new byte[(int) bytes.getBodyLength()];
            bytes.readBytes(raw);
            return new String(raw, StandardCharsets.UTF_8);
        }
        throw new IllegalArgumentException("unsupported JMS message type: " + message.getClass().getSimpleName());
    }
}
