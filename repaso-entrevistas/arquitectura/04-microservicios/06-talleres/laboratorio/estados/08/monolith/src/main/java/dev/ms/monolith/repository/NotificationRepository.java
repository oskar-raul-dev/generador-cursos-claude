package dev.ms.monolith.repository;

import dev.ms.monolith.entity.Notification;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.UUID;

public interface NotificationRepository extends JpaRepository<Notification, UUID> {
    List<Notification> findByRecipientOrderByCreatedAt(String recipient);
    List<Notification> findAllByOrderByCreatedAt();
}
