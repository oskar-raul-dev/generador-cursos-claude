import { Body, Controller, Get, Headers, HttpCode, Inject, Param, ParseUUIDPipe, Post, Query, Res } from "@nestjs/common";
import type { Response } from "express";
import type { Actor } from "../../../application/actor.js";
import { mapPage, pageRequest } from "../../../application/page.js";
import { AuthorizePayment } from "../../../application/usecases/authorize-payment.js";
import { CancelOrder } from "../../../application/usecases/cancel-order.js";
import { CreateOrder } from "../../../application/usecases/create-order.js";
import { GetOrder } from "../../../application/usecases/get-order.js";
import { ListOrders } from "../../../application/usecases/list-orders.js";
import { CurrentActor } from "./actor.decorator.js";
import { CreateOrderRequest, ValidationFailed, toOrderResponse, toPageResponse, toPaymentResponse } from "./dto.js";
import { requestHash, requireIdempotencyKey } from "./idempotency.js";

// Un id que no es UUID es un error de forma, no de existencia
const uuid = (field: string) => new ParseUUIDPipe({ exceptionFactory: () => new ValidationFailed([{ field, message: "must be a UUID" }]) });

// Traduce HTTP a intenciones y resultados a DTO, y aplica las decisiones del contrato: 201 +
// Location al crear, 200 + Idempotent-Replay al repetir. Ninguna regla de negocio.
@Controller("api/v1/orders")
export class OrdersController {
  constructor(
    @Inject(CreateOrder) private readonly createOrder: CreateOrder,
    @Inject(GetOrder) private readonly getOrder: GetOrder,
    @Inject(ListOrders) private readonly listOrders: ListOrders,
    @Inject(AuthorizePayment) private readonly authorizePayment: AuthorizePayment,
    @Inject(CancelOrder) private readonly cancelOrder: CancelOrder,
  ) {}

  @Post()
  async create(
    @CurrentActor() actor: Actor,
    @Headers("idempotency-key") idempotencyKey: string | undefined,
    @Body() body: CreateOrderRequest,
    @Res({ passthrough: true }) res: Response,
  ) {
    const key = requireIdempotencyKey(idempotencyKey);
    const result = await this.createOrder.execute({
      actor, idempotencyKey: key, requestHash: requestHash(body.canonical()),
      lines: body.lines.map((l) => ({ sku: l.sku, quantity: l.quantity })),
    });
    if (result.replayed) {
      res.status(200).setHeader("Idempotent-Replay", "true");
    } else {
      res.status(201).setHeader("Location", `/api/v1/orders/${result.order.id}`);
    }
    return toOrderResponse(result.order);
  }

  @Get(":orderId")
  async get(@CurrentActor() actor: Actor, @Param("orderId", uuid("orderId")) orderId: string) {
    return toOrderResponse(await this.getOrder.execute(actor, orderId));
  }

  @Get()
  async list(@CurrentActor() actor: Actor, @Query("cursor") cursor?: string, @Query("limit") limit?: string) {
    const page = await this.listOrders.execute(actor, pageRequest(cursor, limit ? Number(limit) : null));
    return toPageResponse(mapPage(page, toOrderResponse));
  }

  @Post(":orderId/payment")
  @HttpCode(200)
  async pay(
    @CurrentActor() actor: Actor,
    @Param("orderId", uuid("orderId")) orderId: string,
    @Headers("idempotency-key") idempotencyKey: string | undefined,
    @Res({ passthrough: true }) res: Response,
  ) {
    const key = requireIdempotencyKey(idempotencyKey);
    const result = await this.authorizePayment.execute(actor, orderId, key);
    if (result.replayed) res.setHeader("Idempotent-Replay", "true");
    return toPaymentResponse(result.order, result.payment);
  }

  @Post(":orderId/cancel")
  @HttpCode(200)
  async cancel(@CurrentActor() actor: Actor, @Param("orderId", uuid("orderId")) orderId: string) {
    return toOrderResponse(await this.cancelOrder.execute(actor, orderId));
  }
}
