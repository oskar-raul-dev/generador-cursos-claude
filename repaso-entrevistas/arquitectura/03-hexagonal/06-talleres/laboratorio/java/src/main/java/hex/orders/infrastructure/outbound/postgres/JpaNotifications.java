package hex.orders.infrastructure.outbound.postgres;

import hex.orders.application.Page;
import hex.orders.application.PageRequest;
import hex.orders.application.port.out.Notifications;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Component;

import java.util.List;
import java.util.UUID;

@Component
public class JpaNotifications implements Notifications {

    private final NotificationRepository repository;

    public JpaNotifications(NotificationRepository repository) {
        this.repository = repository;
    }

    @Override
    public Page<Notification> list(UUID orderId, PageRequest page) {
        Pageable limit = Pageable.ofSize(page.limit() + 1);
        List<NotificationEntity> rows = Cursors.TimeCursor.decode(page.cursor())
            .map(c -> repository.pageAfter(orderId, c.ts(), c.id(), limit))
            .orElseGet(() -> repository.firstPage(orderId, limit));
        boolean more = rows.size() > page.limit();
        List<NotificationEntity> pageRows = more ? rows.subList(0, page.limit()) : rows;
        String next = more ? Cursors.TimeCursor.encode(pageRows.getLast().createdAt, pageRows.getLast().id) : null;
        return new Page<>(pageRows.stream()
            .map(n -> new Notification(n.id, n.orderId, n.type, n.recipient, n.createdAt))
            .toList(), next);
    }
}
