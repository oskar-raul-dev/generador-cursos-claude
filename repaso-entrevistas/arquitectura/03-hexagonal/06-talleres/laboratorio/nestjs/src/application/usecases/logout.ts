import type { Clock, TokenRevocationStore } from "../ports.js";

export class Logout {
  constructor(
    private readonly revocations: TokenRevocationStore,
    private readonly clock: Clock,
  ) {}

  async execute(tokenId: string, expiresAt: Date): Promise<void> {
    const remaining = Math.ceil((expiresAt.getTime() - this.clock.now().getTime()) / 1000);
    if (remaining <= 0) {
      return; // ya expiró: no hay nada que recordar
    }
    await this.revocations.revoke(tokenId, remaining);
  }
}
