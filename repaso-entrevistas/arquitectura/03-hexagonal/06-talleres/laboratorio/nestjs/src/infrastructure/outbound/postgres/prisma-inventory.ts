import { Injectable } from "@nestjs/common";
import { randomUUID } from "node:crypto";
import type { Inventory } from "../../../application/ports.js";
import { InsufficientInventory } from "../../../domain/errors.js";
import type { OrderLine } from "../../../domain/order-line.js";
import { PrismaService } from "./prisma.service.js";

// Existencias y reservas. `reserve` descuenta línea a línea con un UPDATE condicional
// (updateMany con `available >= q`); al primer 0 lanza, y la transacción del caso de uso revierte
// lo ya descontado. La atomicidad no está aquí: está en la unidad de trabajo.
@Injectable()
export class PrismaInventory implements Inventory {
  constructor(private readonly prisma: PrismaService) {}

  async availableFor(skus: string[]): Promise<Map<string, number>> {
    if (skus.length === 0) return new Map();
    const rows = await this.prisma.db.inventory.findMany({ where: { sku: { in: skus } } });
    return new Map(rows.map((r) => [r.sku, r.available]));
  }

  async initialize(sku: string, quantity: number): Promise<void> {
    await this.prisma.db.inventory.create({ data: { sku, available: quantity, version: 0n, updated_at: new Date() } });
  }

  async reserve(orderId: string, lines: OrderLine[]): Promise<void> {
    for (const [i, line] of lines.entries()) {
      const updated = await this.prisma.db.inventory.updateMany({
        where: { sku: line.sku, available: { gte: line.quantity } },
        data: { available: { decrement: line.quantity }, version: { increment: 1 }, updated_at: new Date() },
      });
      if (updated.count === 0) {
        const row = await this.prisma.db.inventory.findUnique({ where: { sku: line.sku } });
        throw new InsufficientInventory(line.sku, line.quantity, row?.available ?? 0, i);
      }
      await this.prisma.db.inventory_reservations.create({
        data: { id: randomUUID(), order_id: orderId, sku: line.sku, quantity: line.quantity, status: "RESERVED",
          created_at: new Date(), updated_at: new Date() },
      });
    }
  }

  async release(orderId: string): Promise<void> {
    const reservations = await this.prisma.db.inventory_reservations.findMany({ where: { order_id: orderId, status: "RESERVED" } });
    for (const r of reservations) {
      await this.prisma.db.inventory.update({
        where: { sku: r.sku },
        data: { available: { increment: r.quantity }, version: { increment: 1 }, updated_at: new Date() },
      });
      await this.prisma.db.inventory_reservations.update({ where: { id: r.id }, data: { status: "RELEASED", updated_at: new Date() } });
    }
  }
}
