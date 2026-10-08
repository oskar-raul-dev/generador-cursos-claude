import { Module } from '@nestjs/common';
import { Events } from './events.js';
import { HealthController } from './health.controller.js';
import { MetricsController } from './metrics.js';
import { ReplenishmentOrdersController } from './replenishment-orders.controller.js';
import { Store } from './store.js';

@Module({
  controllers: [HealthController, MetricsController, ReplenishmentOrdersController],
  // G12: Events escucha el bus si EVENT_BUS está puesta (Fase 25).
  providers: [Store, Events],
})
export class AppModule {}
