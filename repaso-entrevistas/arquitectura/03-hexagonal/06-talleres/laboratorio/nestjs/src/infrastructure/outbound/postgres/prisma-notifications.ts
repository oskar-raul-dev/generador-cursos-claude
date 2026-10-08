import { Injectable } from "@nestjs/common";
import type { Page, PageRequest } from "../../../application/page.js";
import type { Notification, Notifications } from "../../../application/ports.js";
import { decodeTimeCursor, encodeTimeCursor } from "./cursors.js";
import { PrismaService } from "./prisma.service.js";

@Injectable()
export class PrismaNotifications implements Notifications {
  constructor(private readonly prisma: PrismaService) {}

  async list(orderId: string | null, page: PageRequest): Promise<Page<Notification>> {
    const cursor = decodeTimeCursor(page.cursor);
    const rows = await this.prisma.db.notifications.findMany({
      where: {
        ...(orderId ? { order_id: orderId } : {}),
        ...(cursor ? { OR: [{ created_at: { lt: cursor.ts } }, { created_at: cursor.ts, id: { lt: cursor.id } }] } : {}),
      },
      orderBy: [{ created_at: "desc" }, { id: "desc" }],
      take: page.limit + 1,
    });
    const more = rows.length > page.limit;
    const pageRows = more ? rows.slice(0, page.limit) : rows;
    const last = pageRows[pageRows.length - 1];
    return {
      items: pageRows.map((n) => ({ id: n.id, orderId: n.order_id, type: n.type, recipient: n.recipient, createdAt: n.created_at })),
      nextCursor: more && last ? encodeTimeCursor(last.created_at, last.id) : null,
    };
  }
}
