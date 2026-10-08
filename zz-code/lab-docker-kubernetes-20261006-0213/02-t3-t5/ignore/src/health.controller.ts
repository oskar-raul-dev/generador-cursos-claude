import { Controller, Get } from '@nestjs/common';

// Salud de G0: trivial. La readiness se vuelve real en G4.
@Controller('health')
export class HealthController {
  @Get('live')
  live() {
    return { status: 'live' };
  }

  @Get('ready')
  ready() {
    return { status: 'ready' };
  }
}
