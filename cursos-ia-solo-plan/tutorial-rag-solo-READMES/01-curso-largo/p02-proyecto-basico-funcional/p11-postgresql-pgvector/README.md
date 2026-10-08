# P11 — PostgreSQL y pgvector

**Guía de proyecto · ~3 h**

## Qué construyes

Esquema de base de datos con pgvector. Migraciones con Flyway que se ejecutan automáticamente. El esquema se recrea desde cero en un comando.

## Contenidos

- Extensión pgvector en PostgreSQL
- Tablas: documents, chunks, embeddings
- Índices: por documento, por distancia vectorial
- Migraciones Flyway: versionadas y reversibles
- Test de conexión

## Criterio de finalización

`flyway:migrate` ejecuta todas las migraciones. `mvn clean` + `mvn spring-boot:run` recrea el esquema desde cero sin errores.

## Después de esta guía

Pasás a P12 con la base de datos lista. Ahora armás el pipeline completo de ingestión.
