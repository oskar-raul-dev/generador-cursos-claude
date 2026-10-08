package dev.mono.legacy.notifications.internal;

import dev.mono.legacy.notifications.Notifications;
import dev.mono.legacy.orders.OrderCancelled;
import org.springframework.context.event.EventListener;
import org.springframework.stereotype.Component;

// Taller 08, versión final: el despachador de la outbox de orders entrega el evento dentro de su
// transacción, y este oyente escribe la notificación en esa misma transacción. Si falla, el evento
// sigue pendiente y vuelve a llegar; el eventId como id de la notificación evita duplicados.
@Component
class OrderCancelledListener {
    private final Notifications notifications;

    OrderCancelledListener(Notifications notifications) {
        this.notifications = notifications;
    }

    @EventListener
    public void on(OrderCancelled event) {
        notifications.orderCancelled(event.eventId(), event.orderId(), event.recipient());
    }
}
