package hex.orders.infrastructure.inbound.http;

import hex.orders.application.PageRequest;
import hex.orders.application.usecase.ListNotifications;
import hex.orders.infrastructure.inbound.http.ApiDtos.NotificationResponse;
import hex.orders.infrastructure.inbound.http.ApiDtos.PageResponse;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.UUID;

// Parte 2: ventana operativa a lo que entregó el Notifier.
@RestController
@RequestMapping("/api/v1/notifications")
public class NotificationController {

    private final ListNotifications listNotifications;
    private final ActorResolver actors;

    public NotificationController(ListNotifications listNotifications, ActorResolver actors) {
        this.listNotifications = listNotifications;
        this.actors = actors;
    }

    @GetMapping
    PageResponse<NotificationResponse> list(@AuthenticationPrincipal Jwt jwt,
                                            @RequestParam(required = false) UUID orderId,
                                            @RequestParam(required = false) String cursor,
                                            @RequestParam(required = false) Integer limit) {
        return PageResponse.from(listNotifications.execute(actors.from(jwt), orderId, PageRequest.of(cursor, limit))
            .map(NotificationResponse::from));
    }
}
