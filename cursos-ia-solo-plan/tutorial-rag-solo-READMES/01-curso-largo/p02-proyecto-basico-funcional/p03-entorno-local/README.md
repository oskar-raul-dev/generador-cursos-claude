# P03 — Entorno local

**Guía de proyecto · ~2 h**

## Qué construyes

El setup reproducible. Docker Compose que levanta Java, PostgreSQL, pgvector, Ollama. Todo local, sin cuentas externas.

## Contenidos

- Dockerfile para la aplicación Java
- docker-compose.yml con todos los servicios
- Scripts de inicialización
- Verificación de que todo está listo
- Documentación de troubleshooting

## Criterio de finalización

`docker compose up` levanta todo. Un segundo `docker compose up` verifica que está corriendo. Los modelos de Ollama responden.

## Después de esta guía

Pasás a P04 con infraestructura lista. Todo lo que sigue asume que el entorno funciona.
