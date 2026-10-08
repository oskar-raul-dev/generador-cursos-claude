import { Controller, Get } from '@nestjs/common';

// La lista fija de G0: la forma del contrato, sin datos detrás.
@Controller('replenishment-orders')
export class ReplenishmentOrdersController {
  @Get()
  list() {
    return [
      {
        id: 'RO-0001',
        sku: 'SKU-0003',
        destinationStore: 'DRO-007',
        originStore: 'DRO-003', // un préstamo de Girón a Chapinero
        quantity: 2,
        status: 'PENDING',
      },
    ];
  }
}
// cambio 1
// cambio 2
// cambio 3
