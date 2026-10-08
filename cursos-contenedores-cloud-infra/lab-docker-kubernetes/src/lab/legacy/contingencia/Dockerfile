# maven:3.10.0-eclipse-temurin-21
FROM maven@sha256:1f4555322b25bc65c1ae2b87d0558047754ef766abf9bd8a0df8bd342d136eb5 AS build
WORKDIR /src
# Primero el pom: las dependencias se cachean mientras el pom no cambie.
COPY pom.xml .
RUN mvn -q -B dependency:go-offline
COPY src ./src
RUN mvn -q -B package -DskipTests

# ghcr.io/eclipse-ee4j/glassfish:8.0.4 (corre con JDK 21)
FROM ghcr.io/eclipse-ee4j/glassfish@sha256:29269d033eb2b1dbdd11fef0a0b119106792e6d8a963da395066da676a2f5faa
# El driver de Postgres va en el servidor, como lo instaló Andrés en 2016 en cada sitio.
ADD --chmod=644 --checksum=sha256:6e0e4cc2d8cae902084f8a2b18728b073a6fd9d1f87c9d8bff8f298c18185b93 https://repo1.maven.org/maven2/org/postgresql/postgresql/42.7.13/postgresql-42.7.13.jar /opt/gfinstall/glassfish/lib/
COPY --chmod=755 custom/init.sh /opt/gfinstall/custom/init.sh
COPY --from=build /src/target/contingencia.war /deploy/contingencia.war
# La carpeta de traslados, de GlassFish: un volumen nuevo hereda este dueño. Sin esto, con Docker
# el lote no puede escribir y el préstamo queda despachado sin archivo que lo avise.
USER root
RUN mkdir -p /var/lib/contingencia/traslados && chown glassfish:glassfish /var/lib/contingencia/traslados
USER glassfish
