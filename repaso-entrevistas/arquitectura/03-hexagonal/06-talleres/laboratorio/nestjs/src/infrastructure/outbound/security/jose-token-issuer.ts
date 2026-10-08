import { Inject, Injectable } from "@nestjs/common";
import { SignJWT } from "jose";
import { randomUUID } from "node:crypto";
import type { IssuedToken, TokenIssuer, User } from "../../../application/ports.js";
import type { HexConfig } from "../../config/config.js";
import { CLOCK, CONFIG } from "../../config/tokens.js";
import type { Clock } from "../../../application/ports.js";

// Emite el JWT del contrato con jose: sub, email, role, jti y exp. El jti es lo que /logout revoca.
@Injectable()
export class JoseTokenIssuer implements TokenIssuer {
  private readonly key: Uint8Array;

  constructor(
    @Inject(CONFIG) private readonly config: HexConfig,
    @Inject(CLOCK) private readonly clock: Clock,
  ) {
    this.key = new TextEncoder().encode(config.jwtSecret);
  }

  async issue(user: User): Promise<IssuedToken> {
    const now = this.clock.now();
    const expiresAt = new Date(now.getTime() + this.config.jwtTtlSeconds * 1000);
    const jti = randomUUID();
    const value = await new SignJWT({ email: user.email, role: user.role })
      .setProtectedHeader({ alg: "HS256" })
      .setSubject(user.id)
      .setJti(jti)
      .setIssuedAt(Math.floor(now.getTime() / 1000))
      .setExpirationTime(Math.floor(expiresAt.getTime() / 1000))
      .sign(this.key);
    return { value, tokenId: jti, expiresAt, expiresInSeconds: this.config.jwtTtlSeconds };
  }
}
