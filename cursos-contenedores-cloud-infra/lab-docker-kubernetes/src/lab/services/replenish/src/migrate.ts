// El Job de migraciones de replenish (G3): aplica el esquema y termina, sin servir nada.
import { logLine } from './logger.js';
import { Store } from './store.js';

const store = new Store();
await store.migrate();
logLine('INFO', `migraciones aplicadas en ${store.engine}`);
await store.onModuleDestroy();
