# 04 — Firestore, Bigtable y NoSQL

> **Objetivo:** diseñar a partir de access patterns en vez de a partir del esquema, y saber
> cuándo el problema es de Firestore y cuándo de Bigtable.
> **Se asume leído:** [`03` — almacenamiento y bases SQL](03-almacenamiento-y-bases-sql.md).
> **Se toca sobre todo con:** [`03`](03-almacenamiento-y-bases-sql.md) y
> [`07` — Pub/Sub, Eventarc e integración](07-pubsub-eventarc-integracion.md).
> **Dónde se practica:** [`L06` — datos y eventos](l06-datos-y-eventos-firestore-pubsub-y-eventarc.md),
> con escritura idempotente, transacciones y el índice compuesto que el emulador no exige.
> **Vigencia:** 6 de septiembre de 2026.

## 1. 🧭 Qué es NoSQL

Las bases NoSQL sacrifican parte del modelo relacional (joins nativos,
esquema rígido, normalización) a cambio de escalabilidad horizontal y
acceso predecible según patrones de consulta conocidos de antemano.

### Modelo de documentos

Datos agrupados en documentos con estructura flexible, organizados en
colecciones. Es el modelo de **Firestore**.

### Modelo wide-column

Datos organizados en tablas con filas identificadas por una **row key**,
donde las columnas se agrupan en **column families** y pueden variar
entre filas. Es el modelo de **Bigtable**.

### Diferencias conceptuales con SQL

| | SQL | NoSQL (documentos/wide-column) |
|---|---|---|
| Esquema | Rígido, definido por adelantado | Flexible, puede variar por documento/fila |
| Joins | Nativos | No nativos (se resuelven desnormalizando o en la aplicación) |
| Diseño | Empieza por las entidades y su normalización | Empieza por los access patterns |
| Escalado | Vertical primero, horizontal con más esfuerzo | Horizontal por diseño |

> En Firestore el modelo se diseña principalmente a partir de los access
> patterns y los índices compuestos necesarios, no de las entidades
> relacionales.

---

# Parte I — Firestore

## 2. 🧱 Database, Collection, Document, Field

```text
Database
└── Collection: users
    └── Document: users/123
        ├── Field: name = "Ana"
        ├── Field: email = "ana@example.com"
        └── Subcollection: users/123/orders
            └── Document: users/123/orders/o1
```

- **Database**: el contenedor de nivel superior dentro de un proyecto.
- **Collection**: agrupa documentos.
- **Document**: unidad de datos, identificada por un ID dentro de su
  colección.
- **Field**: un dato dentro del documento.
- **Subcollection**: una colección anidada bajo un documento específico.

## 3. 🧭 Access patterns primero

Antes de modelar, se listan las consultas que la aplicación
necesita:

```text
1. Obtener usuario por ID
2. Listar órdenes de un usuario, más recientes primero
3. Obtener una orden por ID
4. Listar productos de una categoría, ordenados por precio
```

Y después se diseñan colecciones, subcolecciones e índices para que esas
consultas sean eficientes.

Ejemplo:

```text
Collection: users/{userId}
Subcollection: users/{userId}/orders/{orderId}
```

Este diseño resuelve directamente el access pattern 2 (listar órdenes de
un usuario) con una query sobre la subcolección, sin necesitar un join.

## 4. 🧱 Consultas simples y compuestas

Una **consulta simple** filtra u ordena por un solo campo. Una **consulta
compuesta** combina varias condiciones (múltiples `where`, o `where` +
`order by` sobre campos distintos).

```text
Simple:    where status == "pending"
Compuesta: where status == "pending" AND orderBy createdAt desc
```

## 5. 🧱 Índices de campo único y compuestos

- **Índices de campo único**: se crean **automáticamente** para cada
  campo de cada documento.
- **Índices compuestos**: deben **declararse explícitamente** cuando una
  consulta combina condiciones sobre múltiples campos de una forma que el
  índice automático no cubre.

```text
Consulta simple vs consulta compuesta (requiere índice compuesto)
```

> Si una consulta compuesta falla en producción con un error pidiendo
> crear un índice, no es un bug de la aplicación: es Firestore señalando
> que ese access pattern necesita un índice compuesto declarado
> explícitamente antes de poder ejecutarse.

## 6. 🧱 Consistencia

Firestore ofrece **consistencia fuerte** para lecturas de un documento
por ID y para la mayoría de las queries.

> No respondas simplemente "Firestore siempre es fuertemente consistente
> para cualquier tipo de consulta". Es una sobregeneralización cómoda
> pero imprecisa: hay escenarios (por ejemplo ciertas agregaciones o
> lecturas a través de réplicas específicas según la configuración) donde
> aplican matices de consistencia eventual. Para la gran mayoría de
> lecturas por ID y queries estándar, la consistencia es fuerte — pero
> conviene nombrar el matiz en vez de afirmarlo como regla absoluta sin
> excepción.

## 7. 💰 Modo de facturación

Firestore factura por **operaciones de documento**: lecturas, escrituras
y eliminaciones — no por unidades de capacidad reservada tipo RCU/WCU.

```text
Regla: el costo de Firestore escala con cuántos documentos lees/escribes/eliminas,
no con throughput reservado de antemano.
```

## 8. 🧱 Transactions

Firestore soporta transacciones que garantizan atomicidad sobre múltiples
documentos, incluso entre distintas colecciones.

## 9. 🧱 TTL policies

Permiten marcar documentos con un campo de expiración para que Firestore
los elimine automáticamente de forma eventual (no exactamente al segundo
del timestamp).

## 10. 🧱 Firestore in Datastore mode

Nota histórica: **Datastore mode** es el modo original de lo que hoy se
conoce como Firestore. Es **legacy** frente a **Native mode**, que es el
modo recomendado para nuevas aplicaciones y el que tiene el modelo de
documentos/colecciones/subcolecciones descrito arriba.

```text
Firestore Native mode vs Datastore mode
```

| | Native mode | Datastore mode |
|---|---|---|
| Estado | Recomendado para nuevas apps | Legacy, modo de compatibilidad |
| Modelo | Documentos/colecciones/subcolecciones, listeners en tiempo real | Modelo original de Datastore (entidades/kinds) |

## 11. 🧱 Idempotency patterns

Como cualquier sistema distribuido, un cliente puede reintentar una
escritura tras un timeout sin saber si la primera escritura tuvo éxito.
Un patrón típico:

```text
Document ID = idempotency-key del request
     │
     ▼
create con condición "solo si no existe"
```

Un reintento con la misma idempotency key no duplica el efecto.

---

# Parte II — Bigtable

## 12. 🧱 Table, Row key, Column family

```text
Table: sensor_readings
Row key: device123#2026-09-02T10:00:00
Column family: metrics
  ├── metrics:temperature = 21.5
  └── metrics:humidity    = 40
```

- **Table**: colección de filas.
- **Row key**: identificador único de la fila; determina cómo Bigtable
  distribuye y ordena físicamente los datos.
- **Column family**: agrupación de columnas relacionadas, definida por
  adelantado (a diferencia de las columnas individuales, que pueden
  variar libremente dentro de la family).

## 13. 🧱 Diseño de row key y hot partitions

El diseño de la row key es la decisión más importante en Bigtable, porque
determina cómo se distribuyen las lecturas/escrituras entre los nodos.

Diseño problemático:

```text
Row key = timestamp actual
```

Si todas las escrituras recientes comparten un prefijo de row key
creciente en el tiempo, se concentran en un rango estrecho de la tabla,
generando un **hotspot** (hot partition) en lugar de distribuirse.

Mitigación típica: invertir o hashear parte de la key, o anteponer un
identificador de alta cardinalidad (ej. `device_id`) antes del
timestamp.

```text
Row key = device123#reverse(timestamp)
```

## 14. ⚖ Casos de uso

- series de tiempo (métricas, IoT);
- eventos de alto volumen;
- analítica de alto throughput con acceso predominante por row key.

## 15. ⚖ Cuándo Bigtable es mejor opción que Firestore

Bigtable se justifica cuando el **volumen y throughput** son extremos
(terabytes a petabytes, millones de operaciones por segundo) y el acceso
es predominantemente por row key, sin necesitar el modelo de
documentos/subcolecciones ni consultas ricas por múltiples campos que
ofrece Firestore.

```text
Firestore vs Bigtable
```

| | Firestore | Bigtable |
|---|---|---|
| Modelo | Documentos/colecciones | Wide-column, filas por row key |
| Consultas | Queries por campos, compuestas con índices | Predominantemente por row key/rango de row key |
| Escala típica | Apps operacionales estándar | Volumen y throughput extremos |
| Consistencia | Fuerte para la mayoría de lecturas | Fuerte por fila individual |

---

## 16. ⚖ Comparaciones clave

```text
Firestore vs Bigtable
Firestore Native mode vs Datastore mode
Firestore vs Cloud SQL
Consulta simple vs consulta compuesta (requiere índice compuesto)
Firestore vs BigQuery (operacional vs analítico)
```

| | Firestore | Cloud SQL |
|---|---|---|
| Modelo | Documentos, sin joins nativos | Relacional, con joins |
| Diseño | Por access patterns | Por normalización de entidades |
| Escalado horizontal | Nativo | Requiere trabajo adicional (sharding, read replicas) |

Firestore tampoco reemplaza a BigQuery: Firestore está pensado para
acceso transaccional por documento a baja latencia, no para escanear
grandes volúmenes históricos con SQL analítico (ver documento [`13`](13-bigquery-analitica.md)).

---

## 🧠 Preguntas rápidas

1. ¿Qué diferencia al modelo de documentos del modelo wide-column?
2. ¿Por qué en Firestore se diseña primero a partir de access patterns?
3. ¿Qué es una subcollection?
4. ¿Qué diferencia una consulta simple de una compuesta en Firestore?
5. ¿Los índices compuestos de Firestore se crean automáticamente?
6. ¿Firestore es siempre fuertemente consistente para cualquier tipo de consulta?
7. ¿Cómo factura Firestore sus operaciones?
8. ¿TTL en Firestore borra exactamente al alcanzar el timestamp?
9. ¿Qué diferencia a Firestore Native mode de Datastore mode?
10. ¿Qué determina la row key en Bigtable?
11. ¿Qué es una hot partition en Bigtable y cómo se mitiga?
12. ¿Cuándo elegirías Bigtable en lugar de Firestore?
13. ¿Firestore reemplaza a BigQuery para reporting analítico?

---

## 📚 Referencias oficiales

- Firestore overview: https://cloud.google.com/firestore/docs/overview
- Firestore data model: https://cloud.google.com/firestore/docs/data-model
- Firestore indexes: https://cloud.google.com/firestore/docs/query-data/indexing
- Firestore consistency: https://cloud.google.com/firestore/docs/reference/consistency
- Firestore pricing model: https://cloud.google.com/firestore/pricing
- Firestore transactions: https://cloud.google.com/firestore/docs/manage-data/transactions
- Firestore TTL policies: https://cloud.google.com/firestore/docs/ttl
- Choosing between Native mode and Datastore mode: https://cloud.google.com/datastore/docs/firestore-or-datastore
- Bigtable overview: https://cloud.google.com/bigtable/docs/overview
- Bigtable schema design: https://cloud.google.com/bigtable/docs/schema-design
- Bigtable row key design: https://cloud.google.com/bigtable/docs/schema-design#row-keys
