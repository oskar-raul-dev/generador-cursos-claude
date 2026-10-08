# P04 — Proyecto Spring Boot

**Guía de proyecto · ~2.5 h**

## Qué construyes

El scaffold de la aplicación. Dependencias, perfiles de configuración, estructura de paquetes, endpoint de salud.

## Contenidos

- pom.xml con dependencias correctas
- application.yml con perfiles (dev, test, prod)
- Estructura de paquetes (config, domain, infrastructure, application)
- Endpoint de salud (/actuator/health)
- Logging configurado

## Criterio de finalización

`mvn spring-boot:run` arranca la aplicación. El endpoint de salud responde. Los logs aparecen con nivel correcto.

## Después de esta guía

Pasás a P05 con la estructura lista para agregar lógica de dominio.
