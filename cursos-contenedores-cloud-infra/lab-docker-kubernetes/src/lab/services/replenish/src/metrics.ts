import { Controller, Get, Res } from '@nestjs/common';
import type { NextFunction, Request, Response } from 'express';
import { collectDefaultMetrics, Histogram, register } from '@prometheus-io/client';

// G6: el histograma que el contrato fija para los cuatro backends, con el mismo nombre, las mismas
// etiquetas y los mismos segundos; más las métricas del proceso y del event loop que trae la librería.
// @prometheus-io/client es la heredera oficial de prom-client, que quedó deprecada en 2026.
collectDefaultMetrics();

const requestDuration = new Histogram({
  name: 'http_server_requests_seconds',
  help: 'Duración de las peticiones HTTP atendidas, en segundos.',
  labelNames: ['method', 'uri', 'status'],
  buckets: [0.005, 0.01, 0.025, 0.05, 0.1, 0.25, 0.5, 1, 2.5, 5, 10],
});

// La ruta con la que Express atendió, en la forma del contrato (/replenishment-orders/{id}) y nunca la
// cruda: con el id adentro habría una serie por orden. Lo que no tiene ruta se cuenta junto, como /**.
export function routeOf(req: Request): string {
  const path = req.route?.path as string | undefined;
  if (!path) return '/**';
  return (req.baseUrl + path).replace(/:(\w+)/g, '{$1}');
}

export function measure(req: Request, res: Response, next: NextFunction) {
  const end = requestDuration.startTimer();
  // req.route recién existe cuando Express eligió la ruta: por eso se lee al terminar.
  res.on('finish', () => end({ method: req.method, uri: routeOf(req), status: String(res.statusCode) }));
  next();
}

@Controller('metrics')
export class MetricsController {
  @Get()
  async metrics(@Res() res: Response) {
    res.type(register.contentType).send(await register.metrics());
  }
}
