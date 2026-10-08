package dev.ms.orders.service;

import dev.ms.orders.repository.NotificationRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
@Transactional(readOnly = true)
public class NotificationService {
    private final NotificationRepository notifications;

    public NotificationService(NotificationRepository notifications) { this.notifications = notifications; }

    public List<Views.NotificationView> list(Actor actor) {
        var found = actor.isOperator() ? notifications.findAllByOrderByCreatedAt() : notifications.findByRecipientOrderByCreatedAt(actor.email());
        return found.stream().map(Views.NotificationView::of).toList();
    }
}
