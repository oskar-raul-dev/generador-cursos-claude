import { randomUUID } from 'node:crypto';
import type { LoggerService } from '@nestjs/common';
import type { NextFunction, Request, Response } from 'express';
import { routeOf } from './metrics.js';

// G7: una línea JSON por evento a stdout, con los mismos campos que los otros tres: time, level, service
// y msg. Nest escribe por defecto texto con colores; este logger lo reemplaza para todo, también para los
// mensajes del arranque de Nest.
export function logLine(level: 'INFO' | 'WARN' | 'ERROR' | 'DEBUG', msg: string, fields: Record<string, unknown> = {}) {
  process.stdout.write(
    JSON.stringify({ time: new Date().toISOString(), level, service: 'replenish', msg, ...fields }) + '\n',
  );
}

export class JsonLogger implements LoggerService {
  log(message: unknown, context?: string) {
    logLine('INFO', String(message), context ? { context } : {});
  }
  warn(message: unknown, context?: string) {
    logLine('WARN', String(message), context ? { context } : {});
  }
  error(message: unknown, trace?: string, context?: string) {
    logLine('ERROR', String(message), { ...(context ? { context } : {}), ...(trace ? { trace } : {}) });
  }
  debug(message: unknown, context?: string) {
    logLine('DEBUG', String(message), context ? { context } : {});
  }
  verbose(message: unknown, context?: string) {
    logLine('DEBUG', String(message), context ? { context } : {});
  }
}

// La línea de cada petición. El request_id viene en X-Request-Id (lo pone la puerta, o inventory al
// avisar una venta) o se inventa.
export function logRequests(req: Request, res: Response, next: NextFunction) {
  const start = process.hrtime.bigint();
  const requestId = req.get('x-request-id') || randomUUID();
  res.on('finish', () =>
    logLine('INFO', 'request', {
      method: req.method,
      uri: routeOf(req),
      path: req.path,
      status: res.statusCode,
      duration_ms: Number(process.hrtime.bigint() - start) / 1e6,
      request_id: requestId,
    }),
  );
  next();
}
