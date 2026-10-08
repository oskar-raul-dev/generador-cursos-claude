package dev.mono.legacy.controller;

import dev.mono.legacy.dto.NotificationView;
import dev.mono.legacy.dto.Page;
import dev.mono.legacy.repository.NotificationRepository;
import dev.mono.legacy.util.ErrorCode;
import dev.mono.legacy.util.LegacyException;
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
    public Page<NotificationView> list(@AuthenticationPrincipal Jwt jwt, @RequestParam(required = false) UUID orderId,
                                       @RequestParam(required = false) String cursor,
                                       @RequestParam(required = false) Integer limit) {
        if (!"operator".equals(jwt.getClaimAsString("role"))) {
            throw new LegacyException(ErrorCode.FORBIDDEN, null);
        }
        var all = orderId == null ? notifications.findAllByOrderByCreatedAtDesc()
                                  : notifications.findByOrderIdOrderByCreatedAtDesc(orderId);
        return Page.slice(all, cursor, limit, NotificationView::from);
    }
}
