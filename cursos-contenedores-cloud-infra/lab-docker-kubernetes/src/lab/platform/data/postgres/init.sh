#!/bin/sh
# Una base y un usuario por servicio (Fase 12), con la contraseña de cada uno desde el Secret
# postgres-users. Corre una sola vez: la imagen oficial ejecuta /docker-entrypoint-initdb.d/ solo
# cuando la carpeta de datos está vacía.
set -eu
for svc in pricing inventory catalog replenish; do
  var=$(echo "$svc" | tr '[:lower:]' '[:upper:]')_DB_PASSWORD
  eval pass=\$$var
  psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname postgres <<SQL
CREATE ROLE $svc LOGIN PASSWORD '$pass';
CREATE DATABASE $svc OWNER $svc;
REVOKE ALL ON DATABASE $svc FROM PUBLIC;
SQL
done
