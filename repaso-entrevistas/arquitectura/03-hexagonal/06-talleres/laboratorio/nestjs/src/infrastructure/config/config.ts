// Configuración tipada y validada al arrancar. Valores por defecto: los de §11 de la guía.
export type HexConfig = {
  port: number;
  catalog: "postgres" | "mongo";
  databaseUrl: string;
  mongoUrl: string;
  redisUrl: string;
  jwtSecret: string;
  jwtTtlSeconds: number;
  outboxPollMs: number;
  corsOrigin: string;
};

export function loadConfig(env: NodeJS.ProcessEnv = process.env): HexConfig {
  const catalog = env.HEX_CATALOG ?? "postgres";
  if (catalog !== "postgres" && catalog !== "mongo") {
    throw new Error(`HEX_CATALOG must be postgres or mongo, was: ${catalog}`);
  }
  const jwtSecret = env.JWT_SECRET ?? "hex-lab-dev-secret-change-me-0123456789";
  if (Buffer.byteLength(jwtSecret) < 32) {
    throw new Error("JWT_SECRET must be at least 32 bytes for HS256");
  }
  return {
    port: Number(env.PORT ?? 8082),
    catalog,
    databaseUrl: env.DATABASE_URL ?? "postgresql://hex:hex-lab-pass@localhost:15432/hex_orders",
    mongoUrl: env.MONGO_URL ?? "mongodb://localhost:17017/hex_catalog",
    redisUrl: env.REDIS_URL ?? "redis://localhost:16379",
    jwtSecret,
    jwtTtlSeconds: Number(env.JWT_TTL_SECONDS ?? 900),
    outboxPollMs: Number(env.OUTBOX_POLL_MS ?? 500),
    corsOrigin: env.CORS_ORIGIN ?? "http://localhost:5173",
  };
}
