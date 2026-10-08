package hex.orders.application.usecase;

import hex.orders.application.Actor;
import hex.orders.application.Page;
import hex.orders.application.PageRequest;
import hex.orders.application.port.out.Notifications;

import java.util.UUID;

// Parte 2. Solo operator: es una ventana operativa a lo que entregó el Notifier.
public final class ListNotifications {

    private final Notifications notifications;

    public ListNotifications(Notifications notifications) {
        this.notifications = notifications;
    }

    public Page<Notifications.Notification> execute(Actor actor, UUID orderId, PageRequest page) {
        actor.requireOperator();
        return notifications.list(orderId, page);
    }
}
