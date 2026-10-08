#!/bin/sh
# Los parámetros de la JVM de siempre, como en el script de arranque del servidor.
JAVA_OPTS="${JAVA_OPTS:--Xms256m}"
echo "inventory: arrancando con $JAVA_OPTS"
java $JAVA_OPTS -jar target/inventory-0.0.1-SNAPSHOT.jar
