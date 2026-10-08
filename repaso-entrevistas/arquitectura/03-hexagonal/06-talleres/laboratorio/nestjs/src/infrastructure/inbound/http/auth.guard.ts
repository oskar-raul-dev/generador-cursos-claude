import { type CanActivate, type ExecutionContext, Inject, Injectable, SetMetadata } from "@nestjs/common";
import { Reflector } from "@nestjs/core";
import type { Request } from "express";
import { jwtVerify } from "jose";
import { Actor, type Role } from "../../../application/actor.js";
import type { TokenRevocationStore } from "../../../application/ports.js";
import type { HexConfig } from "../../config/config.js";
import { CONFIG, TOKEN_REVOCATION_STORE } from "../../config/tokens.js";

export const IS_PUBLIC = "hex:public";
export const Public = () => SetMetadata(IS_PUBLIC, true);

export class Unauthenticated extends Error {
  constructor(readonly code: "UNAUTHENTICATED" | "TOKEN_REVOKED") {
    super(code);
    this.name = "Unauthenticated";
  }
}

export type TokenContext = { jti: string; expiresAt: Date };
export type AuthenticatedRequest = Request & { actor?: Actor; token?: TokenContext };

// Verifica el JWT (firma, expiración) y la revocación por jti, y deja en la petición un Actor de
// aplicación: id, email y rol. Ninguna regla de "puede ver este pedido" vive aquí.
@Injectable()
export class AuthGuard implements CanActivate {
  private readonly key: Uint8Array;

  constructor(
    private readonly reflector: Reflector,
    @Inject(CONFIG) config: HexConfig,
    @Inject(TOKEN_REVOCATION_STORE) private readonly revocations: TokenRevocationStore,
  ) {
    this.key = new TextEncoder().encode(config.jwtSecret);
  }

  async canActivate(context: ExecutionContext): Promise<boolean> {
    if (this.reflector.getAllAndOverride<boolean>(IS_PUBLIC, [context.getHandler(), context.getClass()])) {
      return true;
    }
    const request = context.switchToHttp().getRequest<AuthenticatedRequest>();
    const header = request.headers.authorization ?? "";
    if (!header.startsWith("Bearer ")) throw new Unauthenticated("UNAUTHENTICATED");
    let payload;
    try {
      ({ payload } = await jwtVerify(header.slice(7), this.key, { algorithms: ["HS256"] }));
    } catch {
      throw new Unauthenticated("UNAUTHENTICATED");
    }
    if (!payload.sub || !payload.jti || !payload.exp) throw new Unauthenticated("UNAUTHENTICATED");
    if (await this.revocations.isRevoked(payload.jti)) throw new Unauthenticated("TOKEN_REVOKED");
    request.actor = new Actor(payload.sub, String(payload["email"]), payload["role"] as Role);
    request.token = { jti: payload.jti, expiresAt: new Date(payload.exp * 1000) };
    return true;
  }
}
