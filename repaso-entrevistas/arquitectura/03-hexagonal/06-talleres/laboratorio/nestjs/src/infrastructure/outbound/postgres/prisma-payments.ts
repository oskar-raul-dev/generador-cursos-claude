import { Injectable } from "@nestjs/common";
import { randomUUID } from "node:crypto";
import type { Payments } from "../../../application/ports.js";
import type { Money } from "../../../domain/money.js";
import type { Payment } from "../../../domain/payment.js";
import { Prisma } from "./generated/client.js";
import { PrismaService } from "./prisma.service.js";

@Injectable()
export class PrismaPayments implements Payments {
  constructor(private readonly prisma: PrismaService) {}

  async record(orderId: string, payment: Payment, amount: Money): Promise<void> {
    await this.prisma.db.payments.create({
      data: {
        id: randomUUID(), order_id: orderId, operation_id: payment.operationId, status: payment.status,
        reference: payment.reference, amount: new Prisma.Decimal(amount.amountAsText()), currency: amount.currency,
        created_at: new Date(),
      },
    });
  }
}
