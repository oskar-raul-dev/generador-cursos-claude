# 01 — Elegir motor

> La pregunta de diseño que más se hace en una entrevista de arquitectura —«¿qué base usarías
> aquí?»— respondida con criterio y con las cifras que el curso ya midió: el contador que PostgreSQL
> serializa a 4 373 escrituras por segundo y Redis sirve a 121 080; el pedido que MongoDB lee como
> un documento y el panel que su `$lookup` tarda 472 ms en montar frente a los 28 de un `JOIN`; el
> camino más corto que Neo4j encuentra en 25 ms; y los casos en que la respuesta correcta es «la que
> ya tienes». **Asume leído:** [`09/01`](../09-otros-modelos/01-mas-alla-de-las-tablas.md), CAP y el
> criterio de elección, que aquí se aplica entero. **Vigencia:** 27 de septiembre de 2026.

---

## Salto rápido

- [1. El problema](#1--el-problema) · [2. El punto de partida](#2--el-punto-de-partida)
- [3. El árbol de la decisión](#3--el-árbol-de-la-decisión) · [4. Las cifras que deciden, en una
  tabla](#4-️-las-cifras-que-deciden-en-una-tabla)
- [5. Lo que cuesta un motor más](#5--lo-que-cuesta-un-motor-más) · [6. Cuatro decisiones de la
  tienda](#6--cuatro-decisiones-de-la-tienda)
- [7. Estándar, motor y convención](#7--estándar-motor-y-convención) · [Errores
  frecuentes](#️-errores-frecuentes) · [Preguntas](#-preguntas)

---

## 1. 🎯 El problema

En una entrevista, la pregunta llega envuelta en un caso: «diseña el sistema de pedidos de una
tienda», «guarda la telemetría de diez mil dispositivos», «un buscador para el catálogo». El
candidato que empieza por el nombre de un producto suele perder la conversación en la segunda
repregunta, porque el entrevistador pregunta **por qué ese y no otro**, y la respuesta es una moda.

Lo que se evalúa es el camino: cómo se lee el dato, qué mecanismo falla y cuánto cuesta cada salida.
El curso ha medido ese camino motor a motor en los bloques 07, 08 y 09. Este capítulo no mide nada
nuevo: **pone las cifras juntas** y enseña a usarlas para defender una elección en dos minutos.

> **📝 Contexto.** **Capítulo de síntesis, sin sesiones nuevas**, como
> [`03/06`](../03-el-motor-por-dentro/06-cuando-el-indice-no-se-usa.md): cada cifra se cita con el
> capítulo donde se midió, y ahí está la sesión que la produjo. Lo que se afirma sin cifra es
> criterio, y va marcado como convención. **Longitud:** unas 245 líneas; capítulo normal.

---

## 2. 🧱 El punto de partida

**Qué es:** la regla de partida del curso es que **una aplicación empieza con una base relacional**
—aquí, PostgreSQL— y añade otro motor solo cuando una forma de acceso concreta lo pide, medido.

**Quién lo manda:** es **convención**, y tiene razones medibles:

- **Las consultas que aún no se conocen.** El relacional responde a preguntas que nadie previó al
  diseñar, con un índice más; Cassandra necesita una tabla nueva por consulta
  ([`09/02`](../09-otros-modelos/02-columnar-y-wide-column.md)) y DynamoDB, un índice declarado
  ([`07/06`](../07-clave-valor/06-dynamodb-diseno-desde-el-acceso.md)).
- **Las garantías que ya vienen**: tipos que el motor comprueba —rechazó un total como texto que
  MongoDB aceptó ([`08/01`](../08-documental/01-el-modelo-documental.md))—, transacciones y claves
  foráneas.
- **Lo que PostgreSQL ya resuelve dentro**: documentos con `jsonb` e índice GIN
  ([`08/05`](../08-documental/05-documental-relacional-o-jsonb.md)), series con TimescaleDB
  ([`09/04`](../09-otros-modelos/04-series-temporales.md)), texto con `tsvector`
  ([`09/05`](../09-otros-modelos/05-busqueda-de-texto.md)) y vectores con pgvector
  ([`09/06`](../09-otros-modelos/06-vectorial-y-embeddings.md)).

**Cuándo no** vale el punto de partida: cuando la escala o la forma de acceso ya se conocen y no
caben —veinte mil escrituras por segundo repartidas entre regiones— o cuando el producto ya vive en
un ecosistema que manda, como un servicio gestionado sin servidor que solo ofrece DynamoDB.

> **Veredicto:** empezar por el relacional no es conservadurismo: es no pagar por adelantado el
> precio de un modelo que aún no se necesita.

---

## 3. 🧭 El árbol de la decisión

Las cinco preguntas de [`09/01`](../09-otros-modelos/01-mas-alla-de-las-tablas.md) §6, en el orden
en que se contestan en una entrevista:

1. **¿Cómo se lee el dato?** Por clave; por entidad entera; por partición y rango de tiempo;
   recorriendo relaciones de profundidad variable; por relevancia de texto; por parecido. Si la
   respuesta es «de muchas formas, algunas aún desconocidas», el modelo es relacional.
2. **¿Qué mecanismo falla hoy, medido?** El bloqueo de una fila caliente, el `JOIN` repetido, el
   B-tree que no cabe en memoria, el `LIKE` sin índice. Sin mecanismo nombrado no hay caso.
3. **¿Lo resuelve algo dentro de la base actual?** Un índice, un `jsonb`, una extensión, una réplica
   de lectura, una vista materializada.
4. **¿Qué debe hacer el dato durante un fallo?** Un saldo no se lee viejo; un contador de visitas
   sí. Eso elige CP o AP, y el nivel de consistencia de cada operación.
5. **¿Quién lo opera, y cuántas copias habrá?** Cada motor es otra copia que sincronizar, otro
   respaldo y otra guardia ([`06`](../06-operacion/README.md)).

**Cuánto cuesta** saltarse cada una: la 1, un motor que no contesta la consulta del mes siguiente;
la 2 y la 3, una migración para lo que resolvía un índice; la 4, un error en producción o un dato
mal leído; la 5, un sistema que nadie sabe restaurar.

---

## 4. ⚖️ Las cifras que deciden, en una tabla

Cada fila es una forma de acceso, lo que mide el curso en PostgreSQL y en el motor que la resuelve
mejor, y lo que se paga por pasar a él:

| Forma de acceso | PostgreSQL | El motor especializado | Lo que se paga | Dónde se midió |
|---|---|---|---|---|
| Muchas escrituras sobre el mismo valor | 4 373 por segundo con 16 clientes, 3,7 ms de cola | Redis: 121 080 por segundo | RAM; perder el último segundo; solo se pregunta por clave | [`07/01`](../07-clave-valor/01-el-modelo-clave-valor.md) §4–§5 |
| La entidad entera, leída por su clave | El pedido con `JOIN`: 0,115 ms | MongoDB: un documento de 379 bytes | Tipos sin comprobar; las partes no se consultan solas | [`08/01`](../08-documental/01-el-modelo-documental.md) |
| Consultas que unen entidades | Ventas por país: 28 ms con `JOIN` | MongoDB `$lookup`: 472 ms | — | [`08/05`](../08-documental/05-documental-relacional-o-jsonb.md) |
| Carga masiva por partición | `COPY` de 409 998 eventos: 1,22 s | Cassandra, un nodo: 8,04 s | Sin `JOIN`; una consulta nueva es una tabla nueva | [`09/02`](../09-otros-modelos/02-columnar-y-wide-column.md) |
| Recorrido de profundidad fija | Recomendación: 143 ms | Neo4j: 305 ms | — | [`09/03`](../09-otros-modelos/03-grafo.md) §3 |
| Recorrido de profundidad variable | Camino más corto: 3,7 s; sin camino, 24,6 s | Neo4j: 25 ms y 2 ms | Otra copia; los supernodos | [`09/03`](../09-otros-modelos/03-grafo.md) §4 |
| Agregados de series largas | Un año en la tabla normal: 91 ms | TimescaleDB con agregado continuo: 1,3 ms | Va por detrás del dato; el pasado comprimido no se corrige | [`09/04`](../09-otros-modelos/04-series-temporales.md) |
| Texto con tildes, plurales y erratas | `tsvector`: la tilde sí, el singular no, 0 de 95 | OpenSearch: 95, y la errata también | Otra copia que se ve con retraso | [`09/05`](../09-otros-modelos/05-busqueda-de-texto.md) |
| Parecido por significado | pgvector | Qdrant: los mismos resultados | El modelo decide la calidad; el filtro puede vaciar el resultado | [`09/06`](../09-otros-modelos/06-vectorial-y-embeddings.md) |

Leída por columnas, la tabla repite la lección del bloque 09:

- **El motor especializado gana en su forma de acceso y en ninguna otra.** Redis no responde a una
  consulta por rango; Neo4j perdió la recomendación; Cassandra perdió la carga en una máquina.
- **La columna del precio nunca está vacía**, salvo donde el especializado ni siquiera gana, que son
  las filas con raya.
- **Tres de las nueve filas se resuelven sin salir de PostgreSQL**: TimescaleDB y pgvector son
  extensiones, y `tsvector` viene de serie.

---

## 5. 🧭 Lo que cuesta un motor más

Las cifras de §4 miden la consulta. Lo que no miden, y pesa tanto como ella, es lo que el bloque 06
enseñó a operar, multiplicado por cada motor:

- **Otra copia de los datos, con retraso**: el buscador que enseñó un cambio un segundo tarde
  ([`09/05`](../09-otros-modelos/05-busqueda-de-texto.md) §5); en una arquitectura real, lo que
  tarde la sincronización.
- **Otro respaldo y otra restauración de prueba**, con su propio RPO
  ([`06/02`](../06-operacion/02-respaldos-y-recuperacion.md)).
- **Otro sistema de permisos**, que hay que diseñar desde cero
  ([`06/01`](../06-operacion/01-usuarios-roles-y-permisos.md)).
- **Otra forma de migrar el esquema**, o de no tenerlo
  ([`08/05`](../08-documental/05-documental-relacional-o-jsonb.md)).
- **Otra guardia**: alguien que sepa qué hacer a las tres de la mañana cuando se para.

Es **convención** de arquitectura, no medición: ningún capítulo lo cronometró, y es la razón de que
el paso 3 del árbol vaya antes que el 5.

---

## 6. 🧭 Cuatro decisiones de la tienda

**El contador de visitas de `PRD-00017` en campaña.** Paso 1: por clave. Paso 2: el bloqueo de una
fila caliente, medido, 4 373 por segundo. Paso 3: agregar en la aplicación y volcar cada segundo con
un solo `UPDATE` quita casi toda la presión
([`07/01`](../07-clave-valor/01-el-modelo-clave-valor.md) §5). Paso 4: tolera perder un segundo.
**Decisión**: acumular y volcar; Redis si además hacen falta límites de uso o sesiones compartidas.

**El historial de estados de cada pedido.** Paso 1: por pedido, en orden. Paso 2: nada falla con
4,1 millones de eventos. **Decisión**: PostgreSQL, con un índice por pedido y fecha y partición por
mes; TimescaleDB si el panel agrega años; Cassandra solo con escala de telemetría.

**La ficha de producto con atributos distintos por categoría.** Paso 1: la entidad entera. Paso 3:
una columna `jsonb` con índice GIN y una `CHECK`
([`08/05`](../08-documental/05-documental-relacional-o-jsonb.md)). **Decisión**: `jsonb`, sin
MongoDB.

**La detección de cuentas conectadas por fraude.** Paso 1: recorrido de profundidad variable. Paso
2: la CTE recursiva tardó 24,6 s en descartar que no hay camino. Paso 4: la decisión puede esperar
unos segundos a que el grafo se sincronice. **Decisión**: Neo4j como copia alimentada desde
PostgreSQL, sin supernodos.

> **Veredicto:** de cuatro decisiones, una añade un motor, y lo hace por el mecanismo que falla, no
> por el volumen ni por la moda.

---

## 7. 📜 Estándar, motor y convención

> **📜 Estándar o motor.** No hay estándar de cómo elegir una base de datos. Las cifras de §4 son de
> cada motor, medidas en su capítulo; el árbol de §3 y el punto de partida relacional son convención
> de diseño, la de este curso.

| Afirmación | Categoría | Qué la sostiene |
|---|---|---|
| Un motor especializado gana en su forma de acceso | Motor | Redis 121 080 por segundo; Neo4j 25 ms en profundidad variable |
| Y pierde fuera de ella | Motor | Neo4j 305 ms en la recomendación; Cassandra 8,04 s cargando en un nodo |
| Tres de los modelos del bloque 09 caben en PostgreSQL | Motor | TimescaleDB, pgvector y `tsvector` |
| Empezar por el relacional | Convención | Consultas desconocidas y garantías que vienen dadas |
| Cada motor más es otra copia, otro respaldo y otra guardia | Convención | El bloque 06, multiplicado |
| Se elige por el mecanismo que falla, medido | Convención | El árbol de §3 |

**Convención, la que más se repite.** *«Microservicios, así que cada uno con su base distinta»* —
cada servicio con su propia base, sí; con un motor distinto, solo si su forma de acceso lo pide.
Diez servicios sobre diez motores son diez respaldos distintos y diez guardias.

---

## ⚠️ Errores frecuentes

| Se dice | Lo preciso |
|---|---|
| "Para escalar hace falta NoSQL" | Cada motor escala una forma de acceso; el contador caliente se arregló acumulando en la aplicación |
| "MongoDB es más rápido que PostgreSQL" | El documento se lee rápido; el panel con `$lookup` tardó 472 ms frente a 28 |
| "Neo4j es mejor para datos con relaciones" | Perdió la recomendación, 305 ms frente a 143; ganó el camino más corto |
| "Para buscar texto hace falta Elasticsearch" | `tsvector` arregló la tilde; el motor aparte se gana con volumen y erratas |
| "Una base vectorial para la IA" | El modelo decide la calidad; pgvector dio lo mismo que Qdrant |
| "Añadir un motor es gratis si es gestionado" | Sigue siendo otra copia, con su retraso, su respaldo y sus permisos |
| "Hay que elegir el motor definitivo al principio" | Se empieza por el relacional y se añade cuando una forma de acceso lo pide, medido |

---

## 📚 Para profundizar

Este capítulo no tiene referencias propias: cada cifra enlaza al capítulo que la midió, y cada uno
de esos capítulos lleva la documentación oficial de su motor. Para el criterio, el punto de partida
es [`09/01`](../09-otros-modelos/01-mas-alla-de-las-tablas.md) y su tabla comparada de las fichas.

---

## 🧠 Preguntas

1. ¿Cuál es el punto de partida del curso para elegir motor, y por qué? 🟢
2. ¿Cuáles son las cinco preguntas del árbol de la decisión? 🟢
3. ¿Qué modelos del bloque 09 se resuelven dentro de PostgreSQL? 🟢
4. ¿Por qué la primera pregunta es cómo se lee el dato, y no cuánto dato hay? 🟡
5. ¿Qué se pierde al pasar el pedido de la tienda a MongoDB, con las cifras del curso? 🟡
6. ¿En qué forma de acceso gana Neo4j y en cuál pierde, con números? 🟡
7. ¿Qué significa que «la columna del precio nunca está vacía»? 🟡
8. ¿Qué cuestan las operaciones de un motor más, según el bloque 06? 🟡
9. ¿Por qué el paso 3 va antes que el paso 5? 🟠
10. ¿Por qué el contador de visitas no pidió Redis como primera respuesta? 🟠
11. ¿Cuándo no vale el punto de partida relacional? 🟠
12. ¿Por qué «microservicios» no implica un motor distinto por servicio? 🟠
13. Un compañero propone Cassandra para el historial de estados de los pedidos de la tienda.
    ¿Qué le preguntas antes de opinar? 🟠
14. ¿Qué paso del árbol decide entre CP y AP, y con qué ejemplo de la tienda? 🟠
15. Diseña la arquitectura de datos de una tienda con buscador, recomendaciones y panel de ventas,
    diciendo qué motor atiende cada forma de acceso y por qué. 🔴
16. Diagnostica: un equipo migró el catálogo a MongoDB y el informe mensual de ventas por categoría
    pasó de segundos a minutos. 🔴
17. Defiende en dos minutos que la tienda no necesita ningún motor aparte de PostgreSQL hoy, y di
    qué cifra te haría cambiar de opinión para cada modelo. 🔴
18. Defiende o refuta «elegir PostgreSQL es la decisión aburrida y segura, sin más», con lo que
    enseña el capítulo. 🔴

---

**Anterior:** [README del bloque](README.md) · **Siguiente:**
[`02`](02-identidad-y-claves.md) — identidad y claves · **Relacionado:**
[`09/01`](../09-otros-modelos/01-mas-alla-de-las-tablas.md) — CAP y el criterio de elección.
