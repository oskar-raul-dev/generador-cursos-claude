import { Module } from '@nestjs/common';
import { HealthController } from './health.controller.js';
import { ReplenishmentOrdersController } from './replenishment-orders.controller.js';

@Module({
  controllers: [HealthController, ReplenishmentOrdersController],
})
export class AppModule {}
