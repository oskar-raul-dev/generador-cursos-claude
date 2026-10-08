# 13 — BigQuery y analítica

> **Objetivo:** entender qué cambia cuando el almacén deja de ser operacional, y saber cuándo un
> data warehouse reemplaza a una base transaccional y cuándo no.
> **Se asume leído:** [`03` — almacenamiento y bases SQL](03-almacenamiento-y-bases-sql.md).
> **Se toca sobre todo con:** [`03`](03-almacenamiento-y-bases-sql.md) y
> [`04` — Firestore, Bigtable y NoSQL](04-firestore-bigtable-nosql.md).
> **Dónde se practica:** como drill opcional de
> [`L00` §9](l00-idea-lab-practico.md#9--ampliaciones-opcionales): la cuota Always Free de 1 TiB de
> consulta al mes cubre el ejercicio entero, pero el sistema del laboratorio es transaccional y un
> data warehouse no aportaría nada a su flujo.
> **Vigencia:** 6 de septiembre de 2026.

## 1. 🧭 Qué es un data warehouse serverless

**BigQuery** es un data warehouse analítico completamente administrado y
**serverless**: no aprovisionas clusters ni nodos por adelantado para
consultar (salvo que optes explícitamente por capacidad reservada, ver
§7). Está optimizado para escanear **grandes volúmenes de datos
históricos** con SQL, no para transacciones de baja latencia sobre un
registro individual.

```text
BigQuery vs Cloud SQL/AlloyDB (analítico vs operacional)
```

| | BigQuery | Cloud SQL / AlloyDB |
|---|---|---|
| Tipo de carga | Analítica (OLAP) | Operacional (OLTP) |
| Consulta típica | Agregar/escanear millones o miles de millones de filas | Leer/escribir pocas filas por transacción, baja latencia |
| Escalado | Serverless, administrado por Google | Verticalmente, con read replicas para lectura |

> BigQuery no reemplaza a una base operacional: no está diseñado para
> servir la lectura de "el pedido con ID 12345" a 10ms bajo carga
> transaccional constante — para eso siguen siendo la elección correcta
> Cloud SQL o AlloyDB.

---

## 2. 🧱 Dataset, Table, Schema

```text
Dataset: analytics
└── Table: orders
    └── Schema: order_id (STRING), user_id (STRING), amount (NUMERIC), created_at (TIMESTAMP)
```

- **Dataset**: contenedor de tablas, con su propia configuración de
  ubicación y permisos.
- **Table**: los datos en sí, con un schema definido.
- **Schema**: la definición de columnas y tipos.

---

## 3. 🧱 Particionado de tablas

Divide una tabla en segmentos según una columna (típicamente de fecha o
tiempo de ingestión), de forma que una query que filtra por esa columna
solo escanea las particiones relevantes en lugar de toda la tabla.

```text
Table: events (particionada por fecha)
├── partition 2026-08-31
├── partition 2026-09-01
└── partition 2026-09-02
```

```sql
SELECT COUNT(*) FROM events WHERE event_date = '2026-09-02'
-- Solo escanea la partición del 2026-09-02, no toda la tabla
```

---

## 4. 🧱 Clustering

Ordena físicamente los datos **dentro de cada partición** (o de toda la
tabla, si no está particionada) según una o más columnas, de forma que
filtros/agregaciones sobre esas columnas escaneen menos bloques de datos.

```text
Particionado vs Clustering
```

| | Particionado | Clustering |
|---|---|---|
| Granularidad | Segmentos grandes de la tabla (ej. por día) | Ordenamiento fino dentro de cada segmento |
| Columna típica | Fecha/tiempo de ingestión | Columnas de alta cardinalidad usadas en filtros frecuentes (ej. `user_id`) |
| Se combinan | ✅ — clustering dentro de una tabla particionada es un patrón común | |

---

## 5. 💰 Slots y modelo de facturación

Un **slot** es una unidad de capacidad de cómputo que BigQuery usa para
ejecutar una query.

```text
On-demand pricing vs capacidad reservada
```

| | On-demand | Capacidad reservada |
|---|---|---|
| Se cobra por | Bytes escaneados por cada query | Slots reservados durante un período, independiente de cuántos bytes escanean las queries |
| Uso típico | Carga de consultas variable/impredecible | Carga de consultas constante y predecible, donde reservar sale más barato que pagar por escaneo |

---

## 6. ⚖ Streaming inserts vs carga batch

| | Streaming inserts | Carga batch |
|---|---|---|
| Latencia hasta que el dato es consultable | Casi en tiempo real | Depende del job de carga (minutos a horas, según el pipeline) |
| Uso típico | Eventos que necesitan estar disponibles casi inmediatamente | Cargas periódicas desde un data lake o un export |

---

## 7. 🧱 Vistas y vistas materializadas

- **Vista**: una consulta guardada que se re-ejecuta contra los datos
  base en cada acceso — no almacena resultados.
- **Vista materializada**: almacena (y mantiene actualizado de forma
  incremental) el resultado de una consulta, sirviendo lecturas repetidas
  más rápido que recalcular la vista cada vez, a nivel introductorio.

---

## 8. 🧱 BigQuery ML y BI Engine

A nivel de mención, sin profundizar:

- **BigQuery ML**: permite entrenar y aplicar modelos de machine learning
  usando SQL directamente sobre los datos de BigQuery, sin exportarlos a
  otra herramienta.
- **BI Engine**: capa de aceleración en memoria para consultas de
  dashboards/BI de baja latencia sobre datos de BigQuery.

---

## 9. 🧱 De dónde vienen los datos en una arquitectura típica

```text
Pub/Sub          ──► BigQuery   (streaming de eventos)
Cloud Storage    ──► BigQuery   (carga batch desde archivos/data lake)
Cloud Logging sinks ──► BigQuery (logs exportados para análisis)
```

Esto conecta directamente con los documentos [`07`](07-pubsub-eventarc-integracion.md) (Pub/Sub) y [`08`](08-observabilidad-auditoria-gobierno.md)
(log sinks de Cloud Logging): BigQuery suele ser el **destino analítico**
de datos que se generan operacionalmente en otros servicios.

---

## 10. ⚖ BigQuery vs Firestore

```text
BigQuery vs Firestore (SQL sobre grandes volúmenes vs acceso transaccional por documento)
```

| | BigQuery | Firestore |
|---|---|---|
| Modelo de acceso | SQL sobre grandes volúmenes históricos | Acceso transaccional por documento, access patterns definidos |
| Latencia típica | Segundos (queries analíticas) | Milisegundos (lectura por ID/query indexada) |
| Uso típico | Reporting, analítica, BI | Estado operacional de la aplicación |

---

## 🧠 Preguntas rápidas

1. ¿BigQuery necesita que aprovisiones clusters por adelantado para consultar bajo el modelo on-demand?
2. ¿Qué diferencia a BigQuery de Cloud SQL en el tipo de carga para el que están optimizados?
3. ¿Qué es una partición y qué columna se usa típicamente para particionar?
4. ¿Qué diferencia al particionado del clustering?
5. ¿Qué es un slot?
6. ¿Qué diferencia al pricing on-demand del de capacidad reservada?
7. ¿Qué diferencia a un streaming insert de una carga batch en cuanto a latencia hasta que el dato es consultable?
8. ¿Una vista almacena resultados?
9. ¿De dónde suelen venir los datos que terminan en BigQuery en una arquitectura típica de esta guía?
10. ¿BigQuery reemplaza a Firestore para el estado operacional de una aplicación?

---

## 📚 Referencias oficiales

- BigQuery overview: https://cloud.google.com/bigquery/docs/introduction
- Datasets: https://cloud.google.com/bigquery/docs/datasets-intro
- Introduction to partitioned tables: https://cloud.google.com/bigquery/docs/partitioned-tables
- Introduction to clustered tables: https://cloud.google.com/bigquery/docs/clustered-tables
- Slots overview: https://cloud.google.com/bigquery/docs/slots
- Pricing overview (on-demand vs capacity): https://cloud.google.com/bigquery/pricing
- Streaming data into BigQuery: https://cloud.google.com/bigquery/docs/streaming-data-into-bigquery
- Loading data into BigQuery: https://cloud.google.com/bigquery/docs/loading-data
- Introduction to materialized views: https://cloud.google.com/bigquery/docs/materialized-views-intro
- BigQuery ML overview: https://cloud.google.com/bigquery/docs/bqml-introduction
- BI Engine overview: https://cloud.google.com/bigquery/docs/bi-engine-intro
