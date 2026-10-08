import { Injectable } from "@nestjs/common";
import type { IdempotencyStore, StoredResponse } from "../../../application/ports.js";
import { PrismaService } from "./prisma.service.js";

// La clave vive en PostgreSQL, en la misma transacción que el efecto. response_body es jsonb:
// se escribe y se lee como objeto, nunca como texto (jsonb normaliza el documento).
@Injectable()
export class PrismaIdempotencyStore implements IdempotencyStore {
  constructor(private readonly prisma: PrismaService) {}

  async find(actorId: string, key: string): Promise<StoredResponse | null> {
    const row = await this.prisma.db.idempotency_keys.findUnique({ where: { key_actor_id: { key, actor_id: actorId } } });
    if (!row) return null;
    const body = row.response_body as { ref: string };
    return { requestHash: row.request_hash, status: row.response_status, body: body.ref };
  }

  async save(actorId: string, key: string, requestHash: string, status: number, body: string): Promise<void> {
    await this.prisma.db.idempotency_keys.create({
      data: { key, actor_id: actorId, request_hash: requestHash, response_status: status, response_body: { ref: body }, created_at: new Date() },
    });
  }
}
