package dev.mono.legacy.repository;

import dev.mono.legacy.entity.Notification;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;
import java.util.UUID;

public interface NotificationRepository extends JpaRepository<Notification, UUID> {
    List<Notification> findAllByOrderByCreatedAtDesc();

    List<Notification> findByOrderIdOrderByCreatedAtDesc(UUID orderId);
}
