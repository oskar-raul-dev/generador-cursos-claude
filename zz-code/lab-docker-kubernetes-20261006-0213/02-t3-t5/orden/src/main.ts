import { NestFactory } from '@nestjs/core';
import type { NextFunction, Request, Response } from 'express';
import { AppModule } from './app.module.js';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);
  // Una línea de texto por petición: método, ruta y estado. JSON recién en G7.
  app.use((req: Request, res: Response, next: NextFunction) => {
    res.on('finish', () => console.log(`${req.method} ${req.path} ${res.statusCode}`));
    next();
  });
  await app.listen(process.env.PORT ?? 8080); // 8080 por defecto, como todo el laboratorio
}
await bootstrap();
