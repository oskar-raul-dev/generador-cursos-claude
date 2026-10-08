import { Injectable } from "@nestjs/common";
import type { Page, PageRequest } from "../../../application/page.js";
import type { Products } from "../../../application/ports.js";
import { Money } from "../../../domain/money.js";
import { Product } from "../../../domain/product.js";
import { decodeCursor, encodeCursor } from "./cursors.js";
import { Prisma } from "./generated/client.js";
import { PrismaService } from "./prisma.service.js";

// Catálogo en PostgreSQL (partes 1 y 2). El composition root elige entre este y MongoProducts.
@Injectable()
export class PrismaProducts implements Products {
  constructor(private readonly prisma: PrismaService) {}

  async find(sku: string): Promise<Product | null> {
    const row = await this.prisma.db.products.findUnique({ where: { sku } });
    return row && toProduct(row);
  }

  async exists(sku: string): Promise<boolean> {
    return (await this.prisma.db.products.count({ where: { sku } })) > 0;
  }

  async list(page: PageRequest): Promise<Page<Product>> {
    const after = decodeCursor(page.cursor);
    // una fila más que el límite para saber si hay página siguiente sin contar
    const rows = await this.prisma.db.products.findMany({
      where: after ? { sku: { gt: after } } : undefined,
      orderBy: { sku: "asc" },
      take: page.limit + 1,
    });
    const more = rows.length > page.limit;
    const pageRows = more ? rows.slice(0, page.limit) : rows;
    return { items: pageRows.map(toProduct), nextCursor: more ? encodeCursor(pageRows[pageRows.length - 1]!.sku) : null };
  }

  async save(product: Product): Promise<void> {
    const now = new Date();
    await this.prisma.db.products.upsert({
      where: { sku: product.sku },
      create: { sku: product.sku, name: product.name, unit_price: new Prisma.Decimal(product.unitPrice.amountAsText()),
        currency: product.unitPrice.currency, created_at: now, updated_at: now },
      update: { name: product.name, unit_price: new Prisma.Decimal(product.unitPrice.amountAsText()),
        currency: product.unitPrice.currency, updated_at: now },
    });
  }
}

function toProduct(row: { sku: string; name: string; unit_price: Prisma.Decimal; currency: string }): Product {
  return new Product(row.sku, row.name, Money.of(row.unit_price.toFixed(2), row.currency));
}
