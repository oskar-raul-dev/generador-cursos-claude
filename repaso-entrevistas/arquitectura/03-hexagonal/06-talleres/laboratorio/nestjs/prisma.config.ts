import { defineConfig } from "prisma/config";

// Prisma 7: la URL de la base vive aquí (para `prisma db pull` / `generate`), no en el schema.
// En runtime la conexión la abre el adaptador pg con la misma URL leída de la configuración.
export default defineConfig({
  schema: "prisma/schema.prisma",
  datasource: {
    url: process.env.DATABASE_URL ?? "postgresql://hex:hex-lab-pass@localhost:15432/hex_orders",
  },
});
