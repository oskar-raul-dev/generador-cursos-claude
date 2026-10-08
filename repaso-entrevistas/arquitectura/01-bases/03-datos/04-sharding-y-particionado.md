# 04 — Sharding y particionado

> Cómo se reparte un conjunto de datos que ya no cabe en una máquina: estrategias de reparto,
> el problema del rebalanceo, las consultas que cruzan particiones, y por qué el sharding es la
> decisión más cara de revertir de todo el bloque.
> Asume leído [`03` — Relacional, NoSQL y DynamoDB](03-relacional-nosql-y-dynamodb.md).
>
> **Vigencia:** 2026-09-18.

---

## 1. 🎯 El problema

La base de datos ya no da más. Antes de partirla, hay que agotar lo que es mucho más barato, y
enumerarlo en voz alta es la mitad de la respuesta:

```text
1. Índices y consultas       → el 80 % de los "problemas de escala" son un plan de ejecución malo
2. Escalar vertical          → duplicar la máquina es un ticket, no un proyecto
3. Réplicas de lectura       → si el problema son lecturas, esto lo resuelve entero (cap. 05)
4. Caché                     → si las mismas lecturas se repiten (cap. 07)
5. Archivar lo frío          → el 90 % de las filas suelen ser histórico que nadie consulta
6. Separar por dominio       → una base por servicio antes que un shard
── y SOLO ENTONCES ──
7. Sharding                  → partir el conjunto entre máquinas que no se conocen
```

> **Regla importante:** el sharding solo resuelve un problema —**escritura que no cabe en una
> máquina**— y crea muchos. Si el cuello es de lectura, los pasos 3 y 4 lo resuelven sin
> ninguna de sus consecuencias.

---

## 2. 🧱 Particionado y sharding: la distinción

**Qué es.** Dos palabras que se usan como sinónimos y no lo son.

```text
Particionado  → dividir una tabla DENTRO del mismo motor (particiones de Postgres).
                Sigue habiendo una base de datos, un JOIN, una transacción.
Sharding      → repartir entre INSTANCIAS independientes que no se conocen.
                Se acabaron los JOIN entre shards y las transacciones que los cruzan.
```

- El particionado local es barato y reversible: mejora el mantenimiento y el rendimiento de
  consultas que filtran por la clave de partición, sin cambiar el modelo de programación.
- El sharding cambia el modelo de programación entero, y **es prácticamente irreversible**.

**Cuándo sí particionado.** Tablas grandes con un criterio natural —fecha, tenant— donde borrar
lo viejo debería ser instantáneo: eliminar una partición es una operación de metadatos, no un
`DELETE` de mil millones de filas.

**Cuándo no.** Cuando las consultas no filtran por la clave de partición: entonces el motor las
recorre todas y no ganas nada.

> **Veredicto:** el particionado local resuelve muchos "problemas de escala" que la gente ataca
> con sharding. Proponerlo primero demuestra criterio y ahorra un proyecto de seis meses.

---

## 3. 🔀 Estrategias de reparto

**Por rango.** Cada shard cubre un intervalo de la clave: A–F, G–M, N–Z.

- Bueno para consultas de rango: "pedidos entre dos fechas" toca pocos shards.
- Malo para el reparto: los datos rara vez se distribuyen uniformemente, y una clave temporal
  concentra **toda la escritura de hoy en un shard**. Es el modo de fallo clásico.

**Por hash.** `shard = hash(clave) mod N`.

- Reparto uniforme casi garantizado.
- Se pierde la localidad: una consulta de rango toca **todos** los shards.
- Y tiene un problema grave: cambiar `N` reubica casi todos los datos.

**Hash consistente.** Las claves y los nodos se colocan en un anillo, y cada clave va al
siguiente nodo. Añadir o quitar un nodo solo mueve **la fracción que le corresponde**, no todo.

```text
mod N   → añadir un nodo de 4 a 5 mueve ~80 % de las claves
anillo  → añadir un nodo de 4 a 5 mueve ~20 % de las claves
```

- Es lo que usan Cassandra, DynamoDB y los clústeres de Redis, con *nodos virtuales* para
  suavizar el reparto.

**Por entidad de negocio (directorio).** Una tabla de enrutamiento dice qué shard tiene cada
tenant o cliente. Máxima flexibilidad —puedes mover un cliente grande a su propio shard— a
cambio de una indirección que hay que consultar y cachear, y que es un punto único de fallo.

**Cuándo sí cada una.** Rango si las consultas son de rango y la clave reparte bien. Hash si lo
único que importa es el reparto. Consistente si los nodos van a cambiar. Directorio si hay
tenants de tamaños muy dispares.

> **Veredicto:** la estrategia se elige por **cómo consultas**, no por cómo escribes. Elegir hash
> y descubrir después que el 90 % de las consultas son por rango es un error que no se corrige
> sin migrar.

---

## 4. ⚖️ El rebalanceo

**Qué es.** Qué pasa cuando añades o quitas un nodo. Es el problema que la gente descubre en
producción.

- Con `mod N`, añadir un nodo reubica la mayoría de las claves: una migración masiva con el
  sistema en marcha.
- Con hash consistente, se mueve solo una fracción — pero **sigue habiendo movimiento**, y
  durante él una clave puede estar en dos sitios o en ninguno.
- La técnica que lo hace manejable: **muchas más particiones lógicas que nodos físicos**. Creas
  1.024 particiones lógicas desde el principio y las repartes; añadir un nodo es mover
  particiones enteras, sin recalcular claves.

> 💡 **Truco.** "Sobre-particionar desde el principio" es la respuesta madura: decides el número
> de particiones lógicas una vez —alto— y luego solo mueves particiones entre nodos. Es lo que
> hacen Kafka con sus particiones y Elasticsearch con sus shards, y por eso ambos piden ese
> número al crear.

> **Veredicto:** el coste del sharding no está en repartir, está en **re**partir. Quien no ha
> planificado el rebalanceo antes de shardear, lo va a sufrir con el sistema en producción.

---

## 5. 🕸️ Lo que se rompe

**Qué es.** La lista de cosas que dejan de funcionar, y es lo que hay que poder enumerar:

```text
JOIN entre shards        → no existe. Se resuelve en la aplicación o desnormalizando.
Transacciones cruzadas   → no existen. Vuelve la saga de 02-eventos.
Claves autoincrementales → dos shards generarían el mismo id. Hacen falta UUID o Snowflake.
Unicidad global          → "email único" ya no lo garantiza la base de datos.
Agregaciones             → COUNT y SUM globales exigen consultar todos los shards y sumar.
Ordenación y paginación  → "los 20 más recientes" obliga a pedir 20 a cada shard y ordenar.
Esquema                  → una migración hay que aplicarla N veces, y pueden divergir.
Backups                  → N backups que deben ser consistentes ENTRE SÍ en el tiempo.
```

- **La paginación es la que más duele y menos se anticipa.** Con `OFFSET 10000` sobre 8 shards,
  cada uno tiene que devolver 10.020 filas para poder ordenar globalmente. Por eso en sistemas
  shardeados se usa paginación por cursor —"dame lo posterior a esta clave"— y no por
  desplazamiento.
- **La unicidad global** se resuelve con un servicio dedicado, o eligiendo el campo único como
  clave de shard, que es más elegante.

> ⚠️ **Advertencia.** La pregunta de seguimiento favorita: *"¿y cómo haces `SELECT COUNT(*)`?"*.
> La respuesta honesta es que se consulta a todos y se suma, o se mantiene un contador
> aproximado, y que las cifras exactas en tiempo real dejan de estar disponibles.

> **Veredicto:** poder enumerar estas ocho cosas en voz alta es lo que demuestra que has shardeado de
> verdad. Quien solo habla de repartir datos todavía no ha llegado a producción.

---
## 6. 🔑 Elegir la clave de shard

**Qué es.** La decisión más importante y la más difícil de revertir, igual que la clave de
partición de DynamoDB.

Los tres criterios, en orden:

```text
1. CARDINALIDAD ALTA   → muchos valores distintos, o no repartes
2. REPARTO UNIFORME    → sin valores que concentren el tráfico
3. ALINEADA CON EL ACCESO → que las consultas frecuentes caigan en UN shard
```

- El tercero es el que la gente olvida y el que más cuesta. Si shardeas pedidos por `pedidoId`
  repartes perfecto, pero "todos los pedidos de este cliente" toca todos los shards. Si shardeas
  por `clienteId`, esa consulta cae en uno solo — a cambio de que un cliente enorme desequilibre.
- **Casi siempre la clave correcta es la entidad de negocio por la que consultas**: el cliente,
  el tenant, la cuenta. Es lo que mantiene juntas las cosas que se leen juntas.

**El caso multi-tenant** es el más frecuente y el más limpio: shardear por `tenantId` hace que
toda consulta de un cliente caiga en un shard, y permite mover un tenant grande a su propio shard
con una estrategia de directorio.

> **Veredicto:** la clave de shard se elige mirando las consultas, no los datos. Y se elige una
> vez: cambiarla es migrar el sistema entero.

---

## 7. 🧭 Cómo se elige

```text
¿El cuello de botella es de LECTURA?
    → Réplicas (cap. 05) y caché (cap. 07). NO shardees. Resuelto.

¿Es de ESCRITURA y ya agotaste índices, vertical, archivado y separación por dominio?
    → Ahora sí, sharding. Y antes de nada:

    ¿Por qué entidad consultas casi siempre?  → esa es tu clave candidata
    ¿Tiene cardinalidad alta y reparte bien?  → si no, busca otra o combina
    ¿Las consultas frecuentes caerán en un shard? → si no, vas a reconstruir en la app

    ¿Van a cambiar los nodos con el tiempo?
        Sí → hash consistente, y sobre-particiona: 1.024 particiones lógicas desde el día 1
        No → hash simple basta, pero asume que "no" casi nunca es cierto

    ¿Hay tenants de tamaños muy dispares?
        → directorio: te deja mover al grande a su propio shard

Y antes de firmar, enumera en voz alta lo que se rompe:
    JOIN · transacciones · ids · unicidad · agregaciones · paginación · migraciones · backups
```

---

## ⚠️ Errores frecuentes

| Se dice | Lo preciso |
|---|---|
| "Shardeamos para escalar" | El sharding escala **escrituras**; si el cuello es lectura, no aporta |
| "Particionado y sharding son lo mismo" | Uno divide dentro del motor; el otro entre instancias que no se conocen |
| "Repartimos por fecha" | Toda la escritura de hoy cae en un shard: punto caliente garantizado |
| "Usamos `hash mod N`" | Añadir un nodo reubica casi todo; hace falta hash consistente |
| "La paginación funciona igual" | `OFFSET` obliga a cada shard a devolver todo el desplazamiento |
| "El id autoincremental sigue sirviendo" | Dos shards generarían el mismo; hacen falta UUID o Snowflake |
| "Podemos re-shardear después" | Es la decisión más cara de revertir del bloque |

---

## 📚 Para profundizar

- **Libro** — Martin Kleppmann, *Designing Data-Intensive Applications* (O'Reilly, 2017).
  Capítulo 6 completo: particionado, rebalanceo, enrutamiento de peticiones e índices
  secundarios en sistemas particionados. **El de este capítulo.**
- **Libro** — Alex Petrov, *Database Internals* (O'Reilly, 2019). Parte II: cómo implementan el
  reparto y el hash consistente los sistemas distribuidos reales.
- **Libro** — Mark Richards y Neal Ford, *Fundamentals of Software Architecture*, 2ª ed.
  Capítulo sobre descomposición de datos: cuándo el reparto es de dominio y no de volumen.
- [PostgreSQL — Table Partitioning](https://www.postgresql.org/docs/current/ddl-partitioning.html):
  el particionado local, con sus estrategias y sus límites.
- [DynamoDB — Best practices for partition keys](https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/bp-partition-key-design.html):
  los mismos principios de cardinalidad y reparto, en un sistema que los impone.
- [Jepsen — Consistency Models](https://jepsen.io/consistency): el contexto de qué garantías se
  pierden al repartir.
- **Video** — GOTO Conferences, charlas sobre particionado y hash consistente; y AWS re:Invent
  sobre diseño de claves de partición. Búscalas por título.

---

## 🧠 Preguntas

Sin respuestas aquí. Todas, con enunciado literal y respuesta en tres capas, en
[`10` — Respuestas](10-respuestas.md).

1. ¿Qué diferencia hay entre particionado y sharding? 🟢
2. Nombra cuatro estrategias de reparto. 🟢
3. ¿Qué es el hash consistente? 🟢
4. ¿Qué problema resuelve el sharding? 🟢
5. ¿Cuáles son los tres criterios para elegir la clave de shard? 🟢
6. ¿Por qué repartir por fecha produce un punto caliente? 🟡
7. ¿Qué problema tiene `hash mod N` al añadir un nodo? 🟡
8. ¿Qué es sobre-particionar y qué resuelve? 🟡
9. ¿Qué pasa con los ids autoincrementales al shardear? 🟡
10. ¿Por qué el reparto por rango es bueno para consultas de rango? 🟡
11. ¿Qué es la estrategia de directorio y cuándo se usa? 🟡
12. Enumera seis cosas que se rompen al shardear. 🟠
13. ¿Por qué la paginación por desplazamiento deja de funcionar? 🟠
14. ¿Cómo garantizas unicidad global tras shardear? 🟠
15. ¿Qué haces antes de shardear, y en qué orden? 🟠
16. ¿Por qué la estrategia se elige por cómo consultas y no por cómo escribes? 🟠
17. ¿Cómo haces un `COUNT(*)` global en un sistema shardeado? 🟠
18. ¿Por qué el caso multi-tenant es el más limpio para shardear? 🟠
19. ¿Qué pasa con las migraciones de esquema al shardear? 🟠
20. ¿Por qué el sharding es prácticamente irreversible? 🟠
21. Diseña el sharding de una plataforma multi-tenant con 5.000 clientes, donde
    tres concentran el 40 % del volumen. 🔴
22. Te dicen "la base de datos no aguanta, hay que shardear". ¿Qué preguntas y
    qué propones antes? 🔴
23. Tras shardear por `pedidoId`, la consulta "pedidos de un cliente" tarda 4
    segundos. Diagnostica y propón dos salidas. 🔴

---

**Anterior:** [`03` — Relacional, NoSQL y DynamoDB](03-relacional-nosql-y-dynamodb.md) ·
**Siguiente:** [`05` — Réplicas y lag](05-replicas-y-lag.md) ·
**Relacionado:** [`02-eventos/05` — Saga](../02-eventos/05-saga.md)
