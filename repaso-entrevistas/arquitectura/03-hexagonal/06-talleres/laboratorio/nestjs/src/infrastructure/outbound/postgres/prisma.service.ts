import { Inject, Injectable, type OnModuleDestroy } from "@nestjs/common";
import { PrismaPg } from "@prisma/adapter-pg";
import { AsyncLocalStorage } from "node:async_hooks";
import type { HexConfig } from "../../config/config.js";
import { CONFIG } from "../../config/tokens.js";
import { type Prisma, PrismaClient } from "./generated/client.js";

// El cliente Prisma y la transacción "actual". Todos los adaptadores de PostgreSQL consultan
// `db`, que es la transacción en curso si la hay y el cliente raíz si no. Así dos repositorios
// comparten la misma transacción sin que el caso de uso les pase un `tx` por parámetro (lo que
// filtraría infraestructura al núcleo). AsyncLocalStorage propaga el contexto por la cadena de
// awaits; se usa SOLO para esto, nunca para actor ni autorización.
@Injectable()
export class PrismaService implements OnModuleDestroy {
  readonly client: PrismaClient;
  private readonly current = new AsyncLocalStorage<Prisma.TransactionClient>();

  constructor(@Inject(CONFIG) config: HexConfig) {
    this.client = new PrismaClient({ adapter: new PrismaPg({ connectionString: config.databaseUrl }) });
  }

  get db(): Prisma.TransactionClient {
    return this.current.getStore() ?? this.client;
  }

  // Una transacción interactiva; si ya hay una en curso, se reutiliza (unidades de trabajo anidadas).
  transaction<T>(work: () => Promise<T>): Promise<T> {
    if (this.current.getStore()) return work();
    return this.client.$transaction((tx) => this.current.run(tx, work));
  }

  onModuleDestroy(): Promise<void> {
    return this.client.$disconnect();
  }
}
