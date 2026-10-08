import { Controller, Get, Inject, Query } from "@nestjs/common";
import type { Actor } from "../../../application/actor.js";
import { mapPage, pageRequest } from "../../../application/page.js";
import { ListNotifications } from "../../../application/usecases/list-notifications.js";
import { CurrentActor } from "./actor.decorator.js";
import { toNotificationResponse, toPageResponse } from "./dto.js";

// Parte 2: ventana operativa a lo que entregó el Notifier.
@Controller("api/v1/notifications")
export class NotificationsController {
  constructor(@Inject(ListNotifications) private readonly listNotifications: ListNotifications) {}

  @Get()
  async list(
    @CurrentActor() actor: Actor,
    @Query("orderId") orderId?: string,
    @Query("cursor") cursor?: string,
    @Query("limit") limit?: string,
  ) {
    const page = await this.listNotifications.execute(actor, orderId ?? null, pageRequest(cursor, limit ? Number(limit) : null));
    return toPageResponse(mapPage(page, toNotificationResponse));
  }
}
