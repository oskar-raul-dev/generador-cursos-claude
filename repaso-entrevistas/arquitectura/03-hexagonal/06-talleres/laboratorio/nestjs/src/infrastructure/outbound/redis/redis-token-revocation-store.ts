import { Inject, Injectable, type OnModuleDestroy, type OnModuleInit } from "@nestjs/common";
import { createClient, type RedisClientType } from "redis";
import type { TokenRevocationStore } from "../../../application/ports.js";
import type { HexConfig } from "../../config/config.js";
import { CONFIG } from "../../config/tokens.js";

// Revocación por jti con TTL: Redis olvida la clave cuando el token habría expirado.
@Injectable()
export class RedisTokenRevocationStore implements TokenRevocationStore, OnModuleInit, OnModuleDestroy {
  private static readonly PREFIX = "hex:revoked:";
  private readonly client: RedisClientType;

  constructor(@Inject(CONFIG) config: HexConfig) {
    this.client = createClient({ url: config.redisUrl });
  }

  async onModuleInit(): Promise<void> {
    await this.client.connect();
  }

  async onModuleDestroy(): Promise<void> {
    await this.client.quit();
  }

  async revoke(tokenId: string, timeToLiveSeconds: number): Promise<void> {
    await this.client.set(RedisTokenRevocationStore.PREFIX + tokenId, "1", { EX: timeToLiveSeconds });
  }

  async isRevoked(tokenId: string): Promise<boolean> {
    return (await this.client.exists(RedisTokenRevocationStore.PREFIX + tokenId)) === 1;
  }
}
