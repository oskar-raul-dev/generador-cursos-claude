# 04 — DynamoDB y fundamentos NoSQL

> **Objetivo:** diseñar una tabla partiendo de los access patterns y no del modelo
> entidad-relación, y saber por qué esa inversión es el 80 % de DynamoDB.
> **Se asume leído:** [`03`](03-almacenamiento-y-bases-sql.md) — el contraste con SQL
> administrado.
> **Se conecta con:** [`07`](07-mensajeria-eventos-integracion.md) (Streams como fuente
> de eventos) y [`L03`](l03-backend-serverless-lambda-api-y-eventos.md), donde esto se practica.
> **Vigencia:** 6 de septiembre de 2026 (documentación oficial de AWS verificada en esa fecha).

**Salto rápido:** [Qué es DynamoDB](#1--qué-es-dynamodb) · [SQL-first vs DynamoDB-first](#2--sql-first-vs-dynamodb-first) · [Item, attribute y table](#3--item-attribute-y-table) · [Primary Key](#4--primary-key) · [Partition Key](#5--partition-key) · [Sort Key](#6--sort-key) · [Query](#7--query) · [Scan](#8--scan) · [Secondary Indexes](#9--secondary-indexes) · [Projections](#10--projections) · [Read consistency](#11--read-consistency) · [Capacity modes](#12--capacity-modes) · [RCU y WCU — concepto](#13--rcu-y-wcu--concepto) · [Hot partition](#14--hot-partition) · [Single-table design — idea](#15--single-table-design--idea) · [Conditional Writes](#16--conditional-writes) · [Transactions](#17--transactions) · [TTL — Time to Live](#18--ttl--time-to-live) · [DynamoDB Streams](#19--dynamodb-streams) · [Global Tables — idea base](#20--global-tables--idea-base) · [DynamoDB vs RDS](#21--dynamodb-vs-rds) · [Ejemplo de idempotencia](#22--ejemplo-de-idempotencia) · [Preguntas rápidas](#-preguntas-rápidas) · [Referencias oficiales](#-referencias-oficiales)

---

## 1. 🧭 Qué es DynamoDB

Amazon DynamoDB es una base NoSQL administrada orientada a modelos **key-value y document**.

La diferencia mental más importante respecto a SQL:

> En DynamoDB empiezas por los **access patterns** que la aplicación necesita, no por normalizar entidades y después improvisar consultas.

---

## 2. ⚖ SQL-first vs DynamoDB-first

### Mentalidad relacional

```text
Users
Orders
OrderItems
Products
```

Después:

```sql
SELECT ...
FROM users
JOIN orders ...
JOIN order_items ...
```

### Mentalidad DynamoDB

Primero preguntas:

```text
1. Obtener usuario por ID
2. Obtener órdenes de un usuario por fecha
3. Obtener orden por ID
4. Obtener órdenes pendientes de un merchant
5. Recuperar sesión por token
```

Después diseñas keys e índices.

---

## 3. 🧱 Item, attribute y table

### Table

Colección de items.

### Item

Unidad de datos comparable aproximadamente con un registro/documento.

### Attribute

Dato dentro del item.

Ejemplo conceptual:

```json
{
  "userId": "123",
  "name": "Ana",
  "email": "ana@example.com"
}
```

---

## 4. 🧱 Primary Key

DynamoDB admite dos formas principales.

### Simple primary key

Solo partition key:

```text
PK = userId
```

Cada valor debe identificar un item único.

### Composite primary key

Partition key + sort key:

```text
PK              SK
USER#123        ORDER#2026-001
USER#123        ORDER#2026-002
USER#456        ORDER#2026-003
```

La combinación PK+SK identifica de forma única el item.

---

## 5. 🧱 Partition Key

La partition key participa en cómo DynamoDB distribuye datos.

Diseño incorrecto típico:

```text
PK = country
```

si el 95 % del tráfico es:

```text
country = CO
```

puede concentrar carga en pocos valores.

Regla:

> Busca alta cardinalidad y distribución suficientemente uniforme respecto a tu carga.

AWS recomienda diseñar actividad uniforme entre partition keys. La capacidad adaptativa ayuda, pero no elimina la importancia del modelo.

---

## 6. 🧱 Sort Key

Agrupa y ordena items relacionados dentro de un valor de partition key.

Ejemplo:

```text
PK          SK
USER#123    ORDER#2026-01-01#001
USER#123    ORDER#2026-01-05#002
USER#123    ORDER#2026-02-10#003
```

Puedes consultar por:

- igualdad de PK;
- rangos de SK;
- `begins_with`;
- `between`;
- comparadores soportados.

Las sort keys compuestas permiten jerarquías:

```text
country#region#state#city
```

---

## 7. 🧱 Query

`Query` busca items basándose en una partition key concreta y, opcionalmente, condiciones sobre sort key.

Modelo:

```text
PK = USER#123
AND SK begins_with ORDER#
```

Es la operación que normalmente quieres favorecer mediante buen diseño de access patterns.

---

## 8. 🧱 Scan

`Scan` lee todos los items de una tabla o secondary index, hasta los límites por request y con paginación para continuar.

Regla de entrevista:

```text
Query → acceso dirigido por keys
Scan  → recorre tabla/index
```

Un FilterExpression sobre Scan se aplica **después** de leer los datos que el Scan evaluó; no convierte mágicamente el Scan en un acceso eficiente por índice.

Pregunta clásica:

> ¿Por qué un Scan frecuente en producción puede indicar mal modelado?

Porque estás pagando/consumiendo lectura de muchos items para encontrar pocos resultados que podrían quizá haberse modelado como un access pattern indexable.

---

## 9. 🧱 Secondary Indexes

Tu tabla responde perfectamente a "dame el usuario 123", porque esa es la pregunta que
codificaste en la primary key. Mañana el equipo de login necesita otra: "dame el usuario
cuyo email es `ana@example.com`". Esa pregunta la primary key no la contesta, y sin un
índice la única forma de responderla es un `Scan` de la tabla entera **en cada intento de
login** — el anti-patrón del §8, ahora en el camino crítico.

Un **secondary index** es una segunda vista de los mismos datos, con otras keys, que
DynamoDB mantiene por ti. Hay dos tipos y se distinguen por cuánta libertad te dan.

### GSI — Global Secondary Index

Puede tener partition key y sort key completamente diferentes de las de la tabla base.

Tabla base:

```text
PK = USER#123
SK = PROFILE
```

Necesidad nueva:

```text
buscar usuario por email
```

GSI:

```text
GSI1PK = EMAIL#ana@example.com
```

Y ahora el precio, que es la mitad de la respuesta y la que casi nadie da. El GSI es
una estructura aparte, con su propio particionado y su propia capacidad, y DynamoDB la
mantiene **de forma asíncrona** después de confirmar la escritura en la tabla base. De
ahí salen las dos consecuencias que sí se preguntan:

- las lecturas desde un GSI son **siempre eventually consistent**, y no existe la opción
  de pedir lectura fuerte como sí existe sobre la tabla base;
- cada escritura en la tabla base provoca además la escritura del índice, así que un
  GSI no es "una consulta más rápida gratis": es capacidad de escritura adicional y
  almacenamiento adicional, de forma permanente.

> ⚠️ Si el GSI se queda sin capacidad en modo provisioned, el throttling no se limita al
> índice: puede terminar frenando las escrituras de la tabla base. Un índice mal
> dimensionado degrada la tabla que pretendía ayudar.

### LSI — Local Secondary Index

Mantiene la misma partition key que la tabla base y solo cambia la sort key: sirve para
"los mismos items, ordenados por otra cosa", no para buscar por otra cosa.

Regla mental:

```text
GSI → alternate partition key posible
LSI → same partition key, alternate sort key
```

La restricción que lo hace poco frecuente no está en la tabla de comparación de ningún
manual, y es esta: **un LSI solo puede crearse al crear la tabla y no se puede añadir ni
eliminar después**. Un GSI se agrega y se borra sobre una tabla en producción. En un
sistema que va a evolucionar —o sea, en cualquiera— esa diferencia decide sola, y es la
razón de que en diseños modernos veas GSI mucho más que LSI.

---

## 10. 🧱 Projections

Cuando consultas un índice y el atributo que necesitas no está ahí, DynamoDB tiene que
ir a buscarlo a la tabla base. Eso funciona, pero es una lectura extra por item que no
aparece en tu código y sí en tu factura. La **projection** es la decisión de qué se
copia al índice para que eso no pase.

Tipos conceptuales:

- keys only;
- include ciertos attributes;
- all attributes.

Trade-off:

```text
más proyección
→ lecturas más autosuficientes
→ más almacenamiento/escritura de índice
```

La forma de decidirlo es mirar la consulta, no el modelo: proyecta exactamente los
atributos que devuelve esa consulta y nada más. `ALL` es cómodo y convierte al índice en
una copia completa de la tabla, con su almacenamiento y su costo de escritura
duplicados; `KEYS_ONLY` es el más barato y te obliga a una segunda lectura salvo que solo
necesites las keys. `INCLUDE` con la lista corta de lo que de verdad devuelves es, casi
siempre, la respuesta correcta.

> ⚠️ La projection de un GSI **no se puede cambiar después de crearlo**. Cambiar de
> `KEYS_ONLY` a `INCLUDE` significa crear un índice nuevo, esperar a que se rellene y
> borrar el viejo. Vale la pena pensarla una vez bien.

---

## 11. 🧱 Read consistency

DynamoDB guarda cada item en varias copias. Cuando escribes, la escritura se confirma en
cuanto hay suficientes copias al día, pero no todas lo están todavía — y una lectura que
aterrice en una copia rezagada te devuelve el valor anterior. De ahí salen los dos modos
de lectura, que no son una propiedad de la base sino **una decisión por operación**.

### Eventually consistent

El default. Puede observar durante un corto tiempo una versión previa después de una
escritura, y a cambio cuesta la mitad de capacidad de lectura que la otra opción.

### Strongly consistent

Se pide explícitamente en la llamada, y garantiza que ves la escritura confirmada más
reciente. Disponible sobre la tabla base y sobre un LSI, con tres costos que conviene
saber: consume el doble de capacidad, tiene algo más de latencia, y no está disponible
si la lectura viaja entre Regions.

### GSI

Las lecturas de GSI son **eventually consistent**, y aquí no hay elección: es
consecuencia del mantenimiento asíncrono del índice que vimos en §9.

Regla de entrevista:

> “DynamoDB es eventually consistent” es demasiado simplista. La consistencia depende de
> la operación/fuente de lectura.

Dónde importa de verdad: el patrón "escribo y leo inmediatamente para confirmar" —típico
de un `POST` que responde con el recurso creado— es el que se rompe con lectura
eventual. Si el flujo lo exige, pides lectura fuerte y pagas el doble; si no, la lectura
eventual es la respuesta correcta, y devolver el objeto que ya tienes en memoria en vez
de releerlo suele ser mejor que las dos.

---

## 12. 💰 Capacity modes

La pregunta que decide aquí no es "¿cuánto tráfico tengo?" sino "¿sé de antemano cuánto
tráfico voy a tener?".

### On-demand

AWS ajusta la capacidad para el tráfico sin que configures RCU/WCU previamente, y cobras
por request servida.

Útil cuando:

- tráfico impredecible;
- quieres simplicidad operativa;
- workload nuevo.

### Provisioned

Defines capacidad de lectura/escritura y puedes usar auto scaling. Pagas por la
capacidad reservada, se use o no.

Útil cuando:

- tráfico predecible;
- optimización de costos bajo patrones conocidos;
- control explícito de capacidad.

El trade-off real, en una frase: **on-demand paga de más por la tranquilidad, provisioned
paga de menos a cambio de que aciertes el número**. Con tráfico estable y conocido,
provisioned sale bastante más barato; con picos impredecibles, provisioned te obliga a
aprovisionar para el pico —y a pagarlo las veinticuatro horas— o a comerte el throttling
cuando llegue. Un workload nuevo empieza casi siempre en on-demand, se mide unas semanas,
y solo entonces tiene sentido plantearse el cambio.

> ⚠️ El auto scaling de provisioned reacciona en minutos, no en segundos. No te salva de
> un pico brusco: para eso está on-demand, que absorbe hasta el doble del máximo
> observado previamente sin avisar.

---

## 13. 💰 RCU y WCU — concepto

En provisioned mode DynamoDB expresa capacidad en unidades de lectura/escritura, y la
trampa de la unidad es que **no cuenta requests, cuenta trabajo**.

Factores:

- tamaño de item;
- consistencia de lectura;
- cantidad de lecturas/escrituras;
- transacciones consumen capacidad distinta.

Una lectura eventual de un item pequeño cuesta media unidad; la misma lectura pedida
fuerte cuesta una entera; el mismo item con diez veces más atributos cuesta varias. Por
eso dos aplicaciones con idéntico número de operaciones por segundo pueden necesitar
capacidades muy distintas, y por eso el tamaño de item es una decisión de costo y no solo
de modelado.

Para entrevista general basta con no decir nunca que la capacidad son "requests por
segundo": son requests por segundo **multiplicadas por el tamaño y por la consistencia**.

---

## 14. 🩺 Hot partition

DynamoDB reparte los datos en particiones según la partition key, y reparte también la
capacidad entre ellas. Si tu tráfico se concentra en pocos valores de key, concentras el
tráfico en pocas particiones: la tabla en conjunto está muy lejos de su límite, y aun así
esas requests reciben `ProvisionedThroughputExceededException`.

Síntoma conceptual:

```text
mucho tráfico → mismo partition key value / pocas partitions
```

Ejemplo malo:

```text
PK = CURRENT_DATE
```

si todo el mundo escribe hoy al mismo key range. Es el caso más traicionero porque en
desarrollo funciona perfecto —hay un solo día y poco volumen— y falla el día que hay
carga real, con una métrica global que dice que sobra capacidad.

Técnicas según caso:

- mejor cardinalidad;
- write sharding;
- composite keys;
- rediseñar access pattern.

El **write sharding** es el truco concreto detrás de las cuatro: en vez de
`PK = 2026-09-06`, escribes `PK = 2026-09-06#7` con un sufijo aleatorio entre 1 y N, y
repartes la carga entre N particiones. El precio es que leer ese día ya no es una Query,
son N queries que tienes que unir en tu código: has cambiado un problema de escritura por
uno de lectura, deliberadamente.

> 📝 **Contexto.** La capacidad adaptativa de DynamoDB reparte capacidad hacia las
> particiones calientes de forma automática, y aísla las más calientes. Alivia el
> problema y hace que muchos casos moderados ya no se noten, pero no lo elimina: el
> límite duro por partición sigue existiendo, y una key sin cardinalidad lo sigue
> alcanzando.

---

## 15. 🧭 Single-table design — idea

Puedes almacenar múltiples tipos de entidad en una sola tabla para satisfacer access patterns con pocas operaciones.

Ejemplo:

```text
PK          SK
USER#123    PROFILE
USER#123    ORDER#001
USER#123    ORDER#002
ORDER#001   PAYMENT#001
```

No es una obligación universal. Es una técnica potente que aumenta la importancia de diseñar bien keys, naming conventions y access patterns.

Para una entrevista básica:

> Entender partition/sort keys y GSI es más importante que defender dogmáticamente single-table design.

---

## 16. 🧱 Conditional Writes

Puedes condicionar una escritura a un estado esperado.

Ejemplo conceptual:

```text
crear item SOLO SI no existe
```

o actualizar si:

```text
version = 5
```

Esto permite implementar optimistic concurrency e idempotencia en ciertos diseños.

---

## 17. 🧱 Transactions

DynamoDB soporta transacciones ACID sobre múltiples items mediante APIs transaccionales.

Úsalas cuando el caso realmente requiere atomicidad multi-item. Tienen trade-offs de costo/capacidad/latencia frente a operaciones simples.

No respondas:

> “NoSQL significa no transactions.”

Eso es falso para DynamoDB.

---

## 18. 🧱 TTL — Time to Live

Permite marcar items con timestamp de expiración para que DynamoDB los elimine automáticamente de forma eventual.

Casos:

- sesiones;
- tokens temporales;
- datos efímeros;
- caches persistentes.

No diseñes lógica que requiera borrado exactamente al segundo de expiración; la eliminación TTL es asíncrona.

---

## 19. 🧱 DynamoDB Streams

Captura una secuencia temporal de modificaciones de items.

```text
DynamoDB write
      │
      ▼
DynamoDB Stream
      │
      ▼
Lambda/consumer
```

Casos:

- event-driven processing;
- proyecciones;
- notificaciones;
- integración/CDC.

El consumo real de un Stream desde Lambda —event source mapping, tamaño de lote y
fallos parciales— se practica en
[`L03` §8](l03-backend-serverless-lambda-api-y-eventos.md#8--event-source-mapping-dynamodb-streams).

---

## 20. 🧭 Global Tables — idea base

Replican tablas entre múltiples Regions para aplicaciones multi-Region.

Problemas que resuelven:

- acceso local en varias Regions;
- resiliencia regional;
- arquitectura active-active según diseño.

Añaden complejidad en conflictos, consistencia y diseño multi-Region. No son necesarias para una app regional normal.

---

## 21. ⚖ DynamoDB vs RDS

### Elegir RDS/Aurora cuando

- relaciones complejas;
- joins dinámicos;
- consultas ad hoc variadas;
- reporting relacional;
- integridad relacional fuerte y natural.

### Elegir DynamoDB cuando

- access patterns bien conocidos;
- key-value/document;
- escalabilidad administrada muy alta;
- latencia predecible a escala;
- workloads como sesiones, carts, metadata, gaming, IoT, idempotency stores.

No existe regla “NoSQL siempre escala mejor por lo tanto es mejor”. El modelo debe ajustarse al problema.

---

## 22. 🧪 Ejemplo de idempotencia

```text
PK = IDEMPOTENCY#payment-request-id
```

Worker intenta crear el item con condición “attribute_not_exists”.

```text
primera vez  → crea → procesa pago
reintento    → ya existe → no vuelve a cobrar
```

El diseño real debe considerar estados, expiración, errores parciales y atomicidad, pero es un patrón frecuente. La misma idea, aplicada al reintento de un mensaje, está en [`07` §8](07-mensajeria-eventos-integracion.md#8--idempotencia), y escrita con `ConditionExpression` sobre una tabla real en [`L03` §10](l03-backend-serverless-lambda-api-y-eventos.md#10--idempotencia).

---

## 🧠 Preguntas rápidas

1. ¿Partition key vs sort key?
2. ¿Por qué diseñar desde access patterns?
3. ¿Query vs Scan?
4. ¿Por qué FilterExpression no arregla un Scan costoso?
5. ¿GSI vs LSI?
6. ¿GSI soporta strongly consistent reads?
7. ¿On-demand vs provisioned?
8. ¿Qué es hot partition?
9. ¿TTL borra exactamente al alcanzar el timestamp?
10. ¿DynamoDB tiene transacciones?
11. ¿Qué resuelve Streams?
12. ¿Cuándo escogerías RDS en lugar de DynamoDB?

---

## 📚 Referencias oficiales

- DynamoDB Introduction: https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/Introduction.html
- Core components: https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/HowItWorks.CoreComponents.html
- Partition key design: https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/bp-partition-key-design.html
- Sort key best practices: https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/bp-sort-keys.html
- Query: https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/Query.html
- Scan: https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/Scan.html
- Secondary indexes: https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/SecondaryIndexes.html
- Read consistency: https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/HowItWorks.ReadConsistency.html
- Capacity modes: https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/capacity-mode.html
- Transactions: https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/transactions.html
- TTL: https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/TTL.html
- Streams: https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/Streams.html
- Global Tables: https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/GlobalTables.html
- Buenas prácticas de índices secundarios y projections: https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/bp-indexes-general.html
- Distribuir la carga uniformemente (hot partitions): https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/bp-partition-key-uniform-load.html
- Diseño NoSQL y single-table: https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/bp-general-nosql-design.html
- Throughput aprovisionado, RCU y WCU: https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/provisioned-capacity-mode.html
