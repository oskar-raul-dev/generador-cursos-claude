# Java del corpus: la LTS vigente, con driver, pool y bibliotecas en version exacta.
# Versiones verificadas: ver `prompts/dominio-entorno-y-datos-fijos.md` §4.6.

# Etapa 1: Maven resuelve las dependencias del pom.xml y las copia a una carpeta.
FROM maven:3.9.16-eclipse-temurin-25 AS dependencias
COPY pom.xml /tmp/pom.xml
RUN mvn -q -f /tmp/pom.xml dependency:copy-dependencies -DoutputDirectory=/opt/lib

# Etapa 2: la imagen que se usa, con los jar y sin Maven.
FROM eclipse-temurin:25.0.4_7-jdk
COPY --from=dependencias /opt/lib/ /opt/lib/
# CLASSPATH apunta a la carpeta: asi `java Fichero.java` (ejecucion de un fichero
# fuente, sin compilar aparte) encuentra todas las bibliotecas sin mas.
ENV CLASSPATH=/opt/lib/*
WORKDIR /codigo
