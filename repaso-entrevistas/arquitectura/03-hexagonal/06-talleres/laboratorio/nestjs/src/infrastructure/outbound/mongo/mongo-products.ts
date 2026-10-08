import { Inject, Injectable, type OnModuleDestroy, type OnModuleInit } from "@nestjs/common";
import { type Collection, MongoClient } from "mongodb";
import type { Page, PageRequest } from "../../../application/page.js";
import type { Products } from "../../../application/ports.js";
import { Money } from "../../../domain/money.js";
import { Product } from "../../../domain/product.js";
import type { HexConfig } from "../../config/config.js";
import { CONFIG } from "../../config/tokens.js";

type ProductDoc = { _id: string; sku: string; name: string; unitPrice: { amount: string; currency: string } };

// Parte 3: el catálogo en MongoDB detrás del mismo puerto Products. Sin Prisma: el driver oficial.
@Injectable()
export class MongoProducts implements Products, OnModuleInit, OnModuleDestroy {
  private readonly client: MongoClient;
  private collection!: Collection<ProductDoc>;

  constructor(@Inject(CONFIG) config: HexConfig) {
    this.client = new MongoClient(config.mongoUrl);
  }

  async onModuleInit(): Promise<void> {
    await this.client.connect();
    this.collection = this.client.db().collection<ProductDoc>("products");
  }

  onModuleDestroy(): Promise<void> {
    return this.client.close();
  }

  async find(sku: string): Promise<Product | null> {
    const doc = await this.collection.findOne({ _id: sku });
    return doc && toProduct(doc);
  }

  async exists(sku: string): Promise<boolean> {
    return (await this.collection.countDocuments({ _id: sku }, { limit: 1 })) > 0;
  }

  async list(page: PageRequest): Promise<Page<Product>> {
    const after = page.cursor ? Buffer.from(page.cursor, "base64url").toString("utf8") : null;
    const docs = await this.collection.find(after ? { sku: { $gt: after } } : {}).sort({ sku: 1 }).limit(page.limit + 1).toArray();
    const more = docs.length > page.limit;
    const pageDocs = more ? docs.slice(0, page.limit) : docs;
    return {
      items: pageDocs.map(toProduct),
      nextCursor: more ? Buffer.from(pageDocs[pageDocs.length - 1]!.sku, "utf8").toString("base64url") : null,
    };
  }

  async save(product: Product): Promise<void> {
    await this.collection.updateOne(
      { _id: product.sku },
      { $set: { sku: product.sku, name: product.name, unitPrice: { amount: product.unitPrice.amountAsText(), currency: product.unitPrice.currency } } },
      { upsert: true },
    );
  }
}

function toProduct(doc: ProductDoc): Product {
  return new Product(doc.sku, doc.name, Money.of(doc.unitPrice.amount, doc.unitPrice.currency));
}
