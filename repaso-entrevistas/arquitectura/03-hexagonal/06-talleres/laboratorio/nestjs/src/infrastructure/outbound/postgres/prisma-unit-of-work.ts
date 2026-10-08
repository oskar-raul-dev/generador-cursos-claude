import { Injectable } from "@nestjs/common";
import type { UnitOfWork } from "../../../application/ports.js";
import { PrismaService } from "./prisma.service.js";

// El adaptador del puerto UnitOfWork: una transacción interactiva de Prisma. Si `work` lanza,
// Prisma revierte; el caso de uso no sabe nada de esto.
@Injectable()
export class PrismaUnitOfWork implements UnitOfWork {
  constructor(private readonly prisma: PrismaService) {}

  run<T>(work: () => Promise<T>): Promise<T> {
    return this.prisma.transaction(work);
  }
}
