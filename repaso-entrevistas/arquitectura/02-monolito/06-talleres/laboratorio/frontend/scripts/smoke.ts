// Recorre en Node los mismos caminos que la interfaz, con el mismo cliente y los mismos textos.
// Uso: node scripts/smoke.ts  (Node 24 ejecuta TypeScript quitando los tipos)
import { ApiError, configure, createOrder, getOrder, listProducts, login } from "../src/api.ts";
import { catalogLine, created, failure, lineSummary } from "../src/view.ts";

configure({ baseUrl: process.env.LEGACY_URL ?? "http://localhost:38081" });

async function step(name: string, action: () => Promise<string>) {
  try {
    console.log(`${name}\n  la interfaz muestra: ${await action()}`);
  } catch (e) {
    const shown = e instanceof ApiError ? failure(e.status, e.code, e.message) : `💥 ${(e as Error).constructor.name}: ${(e as Error).message}`;
    console.log(`${name}\n  la interfaz muestra: ${shown}`);
  }
}

await login("ana@mono.local", "ana-12345");
// taller 04: el catálogo también, porque es lo primero que pinta la interfaz
await step("0. cargar el catálogo", async () => (await listProducts()).slice(0, 2).map(catalogLine).join(" | "));
await step("1. comprar SKU-002 (hay stock)", async () => created(await createOrder("SKU-002", 1)));
await step("2. comprar SKU-004 (sin stock)", async () => created(await createOrder("SKU-004", 1)));
await step("3. comprar SKU-999 (no existe)", async () => created(await createOrder("SKU-999", 1)));
await step("4. ver un pedido que no existe", async () =>
  lineSummary(await getOrder("00000000-0000-4000-8000-000000000000")));
// taller 07: el mismo clic reintentado (misma clave) no compra dos veces
const click = crypto.randomUUID();
await step("5. comprar SKU-001 y reintentar con la misma clave", async () =>
  `${created(await createOrder("SKU-001", 1, click))} | ${created(await createOrder("SKU-001", 1, click))}`);
