import "reflect-metadata";
import { ValidationPipe } from "@nestjs/common";
import { NestFactory } from "@nestjs/core";
import { AppModule } from "./infrastructure/config/app.module.js";
import { CONFIG } from "./infrastructure/config/tokens.js";
import type { HexConfig } from "./infrastructure/config/config.js";
import { ValidationFailed, flattenValidationErrors } from "./infrastructure/inbound/http/dto.js";

// Arranque: pipes, CORS y cierre ordenado. Ninguna regla de negocio.
async function bootstrap(): Promise<void> {
  const app = await NestFactory.create(AppModule, { logger: ["log", "warn", "error"] });
  const config = app.get<HexConfig>(CONFIG);

  app.useGlobalPipes(new ValidationPipe({
    whitelist: true,                      // descarta campos que el DTO no declara
    transform: true,                      // construye instancias de los DTO (class-transformer)
    exceptionFactory: (errors) => new ValidationFailed(flattenValidationErrors(errors)),
  }));
  app.enableCors({
    origin: config.corsOrigin,
    methods: ["GET", "POST", "OPTIONS"],
    allowedHeaders: ["Authorization", "Content-Type", "Idempotency-Key", "Accept"],
    exposedHeaders: ["Location", "Idempotent-Replay"],
  });
  app.enableShutdownHooks();              // onModuleDestroy: Prisma, Mongo, Redis y el dispatcher cierran
  await app.listen(config.port);
  console.log(`hex-orders-nestjs listening on :${config.port} (catalog=${config.catalog})`);
}

void bootstrap();
