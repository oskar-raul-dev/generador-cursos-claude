# Fase 2: Ingeniería de datos

**Duración:** 8–10 semanas | **Horas reales:** ~48–60 h | **Acumulado:** ~8.5 meses

## Resumen

Pipelines ETL reproducibles, almacenamiento analítico, calidad y validación. Base para todas las fases siguientes: ML es tan bueno como los datos que lo alimentan.

## Temas principales

- Modelado: esquemas relacionales vs. analíticos (estrella/copo de nieve)
- SQL analítico: window functions, CTEs, agregaciones complejas
- Formatos: filas vs. columnar (Parquet), particionamiento
- Pipelines ETL/ELT reproducibles: idempotencia, backfills, manejo de fallos
- Motores analíticos: DuckDB como laboratorio local
- Calidad y validación de datos: tests, anomalías, duplicados
- Orquestación básica: cuándo usar Airflow vs. cron
- Arquitectura bronze/silver/gold

## Recursos principales

- DataTalks.Club, *Data Engineering Zoomcamp* (gratuito, práctico)
- Martin Kleppmann, *Designing Data-Intensive Applications*

## Proyecto tesis — OBLIGATORIO

1. **Esquema de datos y pipeline ETL** de la plataforma logística (pedidos, rutas, entregas, inventario)
2. **Simulador de datos de operación** que genera históricos realistas con semilla reproducible, calibrado en dominios públicos de delivery

## Criterio de salida

Pipeline reproducible, formato columnar acelera analítica (y ralentizaría transaccional), simulador genera datasets consistentes.
