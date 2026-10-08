import { Injectable } from "@nestjs/common";
import type { Page, PageRequest } from "../../../application/page.js";
import type { Orders } from "../../../application/ports.js";
import { Money } from "../../../domain/money.js";
import { Order, type OrderStatus } from "../../../domain/order.js";
import { OrderLine } from "../../../domain/order-line.js";
import { Payment, type PaymentStatus } from "../../../domain/payment.js";
import { decodeTimeCursor, encodeTimeCursor } from "./cursors.js";
import { Prisma } from "./generated/client.js";
import { PrismaService } from "./prisma.service.js";

type OrderRow = Prisma.ordersGetPayload<{ include: { order_lines: true } }>;

// Traduce entre Order (dominio) y las filas de orders/order_lines/payments. Al leer, reconstruye
// un agregado completo: líneas incluidas y último pago.
@Injectable()
export class PrismaOrders implements Orders {
  constructor(private readonly prisma: PrismaService) {}

  async find(id: string): Promise<Order | null> {
    const row = await this.prisma.db.orders.findUnique({ where: { id }, include: { order_lines: { orderBy: { line_no: "asc" } } } });
    return row && this.toOrder(row);
  }

  async save(order: Order): Promise<void> {
    const now = new Date();
    const existing = await this.prisma.db.orders.findUnique({ where: { id: order.id } });
    if (existing) {
      await this.prisma.db.orders.update({
        where: { id: order.id },
        data: { status: order.status, version: BigInt(order.version + 1), updated_at: now },
      });
      return;
    }
    await this.prisma.db.orders.create({
      data: {
        id: order.id, customer_id: order.customerId, status: order.status,
        total_amount: new Prisma.Decimal(order.total.amountAsText()), currency: order.total.currency,
        version: 0n, created_at: order.createdAt, updated_at: now,
        order_lines: {
          create: order.lines.map((l, i) => ({
            line_no: i, sku: l.sku, product_name: l.name, quantity: l.quantity,
            unit_price: new Prisma.Decimal(l.unitPrice.amountAsText()),
          })),
        },
      },
    });
  }

  async list(customerId: string | null, page: PageRequest): Promise<Page<Order>> {
    const cursor = decodeTimeCursor(page.cursor);
    // cursor sobre (created_at, id) descendente: estable aunque se creen pedidos entre páginas
    const rows = await this.prisma.db.orders.findMany({
      where: {
        ...(customerId ? { customer_id: customerId } : {}),
        ...(cursor ? { OR: [{ created_at: { lt: cursor.ts } }, { created_at: cursor.ts, id: { lt: cursor.id } }] } : {}),
      },
      orderBy: [{ created_at: "desc" }, { id: "desc" }],
      take: page.limit + 1,
      include: { order_lines: { orderBy: { line_no: "asc" } } },
    });
    const more = rows.length > page.limit;
    const pageRows = more ? rows.slice(0, page.limit) : rows;
    const last = pageRows[pageRows.length - 1];
    const items = await Promise.all(pageRows.map((r) => this.toOrder(r)));
    return { items, nextCursor: more && last ? encodeTimeCursor(last.created_at, last.id) : null };
  }

  private async toOrder(row: OrderRow): Promise<Order> {
    const last = await this.prisma.db.payments.findFirst({ where: { order_id: row.id }, orderBy: { created_at: "desc" } });
    const payment = last ? new Payment(last.status as PaymentStatus, last.operation_id, last.reference) : null;
    const lines = row.order_lines.map((l) => new OrderLine(l.sku, l.product_name, l.quantity, Money.of(l.unit_price.toFixed(2), row.currency)));
    return Order.reconstitute(row.id, row.customer_id, lines, Money.of(row.total_amount.toFixed(2), row.currency),
      row.created_at, row.status as OrderStatus, payment, Number(row.version));
  }
}
