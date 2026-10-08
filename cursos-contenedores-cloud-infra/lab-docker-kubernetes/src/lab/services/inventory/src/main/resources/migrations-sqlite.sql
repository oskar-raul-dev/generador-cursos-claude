-- G13 (Fase 26): SQLite no tiene ADD COLUMN IF NOT EXISTS. Migrator corre este archivo aparte y sigue si una
-- sentencia falla (la columna ya existía). Los índices sí se pueden repetir.
ALTER TABLE sales ADD COLUMN idempotency_key TEXT;
ALTER TABLE loans ADD COLUMN idempotency_key TEXT;
CREATE UNIQUE INDEX IF NOT EXISTS sales_idempotency_key ON sales (idempotency_key) WHERE idempotency_key IS NOT NULL;
CREATE UNIQUE INDEX IF NOT EXISTS loans_idempotency_key ON loans (idempotency_key) WHERE idempotency_key IS NOT NULL;
