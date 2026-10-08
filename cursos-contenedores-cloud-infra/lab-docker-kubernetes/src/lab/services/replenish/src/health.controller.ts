import { Controller, Get, HttpException, Logger } from '@nestjs/common';
import { Store } from './store.js';

// La salud de replenish. La liveness nunca consulta dependencias.
@Controller('health')
export class HealthController {
  private readonly log = new Logger('health');

  constructor(private readonly store: Store) {}

  @Get('live')
  live() {
    return { status: 'live' };
  }

  // La readiness (G4): lista solo si la base contesta en un segundo. Ningún vecino: eso sería una cascada.
  @Get('ready')
  async ready() {
    try {
      await this.store.ping(1000);
    } catch (e) {
      this.log.warn(`no listo: la base no contesta: ${(e as Error).message}`);
      throw new HttpException({ status: 'not_ready' }, 503);
    }
    return { status: 'ready' };
  }
}
