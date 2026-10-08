package dev.mono.legacy.notifications.web;

import dev.mono.legacy.notifications.internal.NotificationQueries;
import dev.mono.legacy.shared.ErrorCode;
import dev.mono.legacy.shared.LegacyException;
import dev.mono.legacy.shared.Page;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.*;

import java.util.UUID;

@RestController
public class NotificationController {
    private final NotificationQueries notifications;

    public NotificationController(NotificationQueries notifications) {
        this.notifications = notifications;
    }

    @GetMapping("/api/v1/notifications")
    public Page<NotificationView> list(@AuthenticationPrincipal Jwt jwt, @RequestParam(required = false) UUID orderId,
                                       @RequestParam(required = false) String cursor,
                                       @RequestParam(required = false) Integer limit) {
        if (!"operator".equals(jwt.getClaimAsString("role"))) {
            throw new LegacyException(ErrorCode.FORBIDDEN, null);
        }
        return Page.slice(notifications.latestFirst(orderId), cursor, limit, NotificationView::from);
    }
}
