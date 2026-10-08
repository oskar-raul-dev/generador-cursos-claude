import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module.js';
import { JsonLogger, logRequests } from './logger.js';
import { measure } from './metrics.js';

async function bootstrap() {
  // G7: el logger JSON desde el primer mensaje del arranque.
  const app = await NestFactory.create(AppModule, { logger: new JsonLogger() });
  app.use(logRequests); // G7: una línea JSON por petición, con su request_id
  app.use(measure); // G6: cada petición, al histograma de /metrics
  // G5: el apagado limpio. Con los ganchos de apagado, Nest atiende SIGTERM: cierra el servidor (deja de
  // aceptar conexiones y espera las que están en vuelo) y llama a onModuleDestroy, que cierra el pool de
  // la base. Sin esto, Node como proceso 1 ignora SIGTERM y el kubelet lo mata a los 30 s (Fase 03).
  app.enableShutdownHooks(['SIGTERM', 'SIGINT']);
  await app.listen(process.env.PORT ?? 8080); // 8080 por defecto, como todo el laboratorio
}
await bootstrap();
