import { Inject, Injectable, Logger, type OnModuleDestroy, type OnModuleInit } from "@nestjs/common";
import { DeliverPendingPublications } from "../../../application/usecases/deliver-pending-publications.js";
import type { HexConfig } from "../../config/config.js";
import { CONFIG } from "../../config/tokens.js";

// El disparador de la outbox: un setInterval con dueño. Arranca con el módulo, se para con él
// (enableShutdownHooks) y no solapa rondas: si una tarda más que el intervalo, la siguiente espera.
@Injectable()
export class OutboxDispatcher implements OnModuleInit, OnModuleDestroy {
  private readonly log = new Logger(OutboxDispatcher.name);
  private timer: NodeJS.Timeout | null = null;
  private running = false;

  constructor(
    @Inject(DeliverPendingPublications) private readonly deliver: DeliverPendingPublications,
    @Inject(CONFIG) private readonly config: HexConfig,
  ) {}

  onModuleInit(): void {
    this.timer = setInterval(() => void this.poll(), this.config.outboxPollMs);
  }

  onModuleDestroy(): void {
    if (this.timer) clearInterval(this.timer);
  }

  private async poll(): Promise<void> {
    if (this.running) return;
    this.running = true;
    try {
      const delivered = await this.deliver.execute(50);
      if (delivered > 0) this.log.log(`outbox: delivered ${delivered} event(s)`);
    } catch (e) {
      this.log.warn(`outbox: delivery round failed: ${(e as Error).message}`); // la siguiente ronda reintenta
    } finally {
      this.running = false;
    }
  }
}
