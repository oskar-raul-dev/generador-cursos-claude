#!/bin/sh
# Arranque de catalog. Con SQLite (G1, y compose desde G3): crea la base y aplica el esquema. Con
# Postgres (G3): no migra; lo hace el Job, una sola vez, antes del rollout (Fase 12).
set -e
if [ -z "$DATABASE_URL" ]; then
  DB="${DB_DATABASE:-${DATA_DIR:-/var/lib/catalog}/catalog.db}"
  touch "$DB"
  php artisan migrate --force --no-interaction
fi
# exec: FPM reemplaza al shell y recibe las señales (Fase 03).
exec php-fpm
