#!/bin/bash
# Lo corre la imagen de GlassFish antes de arrancar el servidor. Crea el pool de conexiones con los
# datos de la base que llegan por variables de entorno. Si el pool ya existe (el contenedor se
# reinició), no hace nada.
set -e
if grep -q 'contingenciaPool' "${PATH_GF_DOMAIN}/config/domain.xml" 2>/dev/null; then
  exit 0
fi
cat > /tmp/contingencia.asadmin <<COMMANDS
start-domain ${AS_DOMAIN_NAME}
create-jdbc-connection-pool --datasourceclassname org.postgresql.ds.PGSimpleDataSource --restype javax.sql.DataSource --property serverName=${DB_HOST}:portNumber=5432:databaseName=${DB_NAME}:user=${DB_USER}:password=${DB_PASSWORD} contingenciaPool
create-jdbc-resource --connectionpoolid contingenciaPool jdbc/contingencia
stop-domain ${AS_DOMAIN_NAME}
COMMANDS
asadmin --passwordfile="${AS_ADMIN_PASSWORDFILE}" --interactive=false multimode -f /tmp/contingencia.asadmin
rm -f /tmp/contingencia.asadmin
