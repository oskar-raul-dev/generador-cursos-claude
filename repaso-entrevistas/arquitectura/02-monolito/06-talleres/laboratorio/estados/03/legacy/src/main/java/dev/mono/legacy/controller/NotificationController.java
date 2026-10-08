package dev.mono.legacy.controller;

import dev.mono.legacy.repository.NotificationRepository;
import dev.mono.legacy.util.Json;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.*;

import java.util.UUID;

@RestController
public class NotificationController {
    private final NotificationRepository notifications;

    public NotificationController(NotificationRepository notifications) {
        this.notifications = notifications;
    }

    @GetMapping("/api/v1/notifications")
    public Object list(@AuthenticationPrincipal Jwt jwt, @RequestParam(required = false) UUID orderId) {
        if (!"operator".equals(jwt.getClaimAsString("role"))) {
            return Json.error("Only operators can do this");
        }
        return orderId == null ? notifications.findAllByOrderByCreatedAtDesc()
                               : notifications.findByOrderIdOrderByCreatedAtDesc(orderId);
    }
}
