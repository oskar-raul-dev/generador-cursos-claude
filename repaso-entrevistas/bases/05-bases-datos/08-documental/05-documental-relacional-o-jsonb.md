# 05 — Documental, relacional o jsonb

> La decisión con la que cierra el bloque: dónde guardar un dato con forma de documento. Tres
> caminos medidos con la tienda: MongoDB con validación de esquema, que rechaza el total en texto
> que en [`01`](01-el-modelo-documental.md) entraba sin avisar; **`jsonb` en PostgreSQL**, que
> encuentra los ocho eventos con un importe entre 4,1 millones en 0,1 ms con un índice GIN y valida
> con un `CHECK`; y relacional puro. Y la trampa práctica de los servicios «compatibles con la API
> de MongoDB», que hablan su protocolo y no hacen todo lo que hace. **Asume leído:** los cuatro
> capítulos anteriores del bloque, y [`03/02`](../03-el-motor-por-dentro/02-familias-de-indices.md),
> las familias de índices de PostgreSQL. **Vigencia:** 27 de septiembre de 2026.

---

## Salto rápido

- [1. El problema](#1--el-problema) · [2. Validación de esquema en
  MongoDB](#2--validación-de-esquema-en-mongodb)
- [3. jsonb: la tercera vía](#3--jsonb-la-tercera-vía) · [4. Cómo se elige](#4--cómo-se-elige)
- [5. «Compatible con la API de MongoDB» no es
  MongoDB](#5--compatible-con-la-api-de-mongodb-no-es-mongodb)
- [6. Estándar, motor y convención](#6--estándar-motor-y-convención) · [Errores
  frecuentes](#️-errores-frecuentes) · [Preguntas](#-preguntas)

---

## 1. 🎯 El problema

La reunión de arquitectura llega a la pregunta de siempre: los eventos de pedido tienen una carga
con forma variable, el catálogo de productos va a necesitar atributos distintos por categoría, y
alguien propone «pasar esto a MongoDB, que para eso es documental». Otro recuerda el total en texto
de [`01`](01-el-modelo-documental.md) §4 y el `$lookup` de 472 ms de
[`02`](02-mongodb-consulta-y-agregacion.md) §6. Un tercero dice que la nube ofrece un servicio
«compatible con MongoDB» y que así no hay nada que operar.

Las tres posturas tienen parte de razón, y ninguna es la respuesta por defecto. **Hay tres caminos
para un dato con forma de documento**: una base documental, una columna `jsonb` dentro de
PostgreSQL, o tablas relacionales de siempre. Este capítulo mide lo que da y lo que cuesta cada uno
con la tienda, y cierra con la pregunta del servicio compatible, que se contesta leyendo su lista de
diferencias.

> **📝 Contexto.** La validación de §2 se corrió contra `bd-lab-mongo`, `mongo:8.0.20`, con los
> pedidos de `01`, y se retiró al terminar. La sesión de §3 corre contra `bd-lab-postgres` sobre
> `eventos_pedido.carga`, que ya es `jsonb` en el esquema del corpus: el índice GIN se creó y se
> borró, y el `CHECK` se añadió dentro de una transacción que se deshizo. **Amazon DocumentDB y
> Azure Cosmos DB no están en el entorno** —son servicios de pago—; lo que dice §5 sale de su
> documentación oficial. **Longitud:** unas 400 líneas; capítulo normal.

---

## 2. 🧱 Validación de esquema en MongoDB

**Qué es:** un validador que se asocia a la colección —una regla `$jsonSchema`— y que MongoDB
comprueba en cada inserción y actualización. Es la respuesta a la suma que perdió 5 971,28 en `01`.
Primero se buscan los documentos que ya no cumplen; después se activa:

```text
tienda> const esquema = {bsonType: "object", required: ["cliente", "estado", "total"], properties: {total: {bsonType: "decimal"}, estado: {enum: ["PENDIENTE", "PAGADO", "ENVIADO", "ENTREGADO", "ANULADO"]}}}

tienda> db.pedidos.countDocuments({$nor: [{$jsonSchema: esquema}]})
0
tienda> db.runCommand({collMod: "pedidos", validator: {$jsonSchema: esquema}, validationLevel: "strict", validationAction: "error"})
{ ok: 1 }
tienda> db.pedidos.updateOne({_id: "PED-99999"}, {$set: {total: "5971.28"}})
Uncaught:
MongoServerError: Document failed validation
Additional information: {
  failingDocumentId: 'PED-99999',
  details: {
    operatorName: '$jsonSchema',
    schemaRulesNotSatisfied: [
      {
        operatorName: 'properties',
        propertiesNotSatisfied: [
          {
            propertyName: 'total',
            details: [
              {
                operatorName: 'bsonType',
                specifiedAs: { bsonType: 'decimal' },
                reason: 'type did not match',
                consideredValue: '5971.28',
                consideredType: 'string'
              }
            ]
          }
        ]
      }
    ]
  }
}
tienda> db.pedidos.updateOne({_id: "PED-99999"}, {$set: {estado: "DEVUELTO"}})
Uncaught:
MongoServerError: Document failed validation
Additional information: {
  failingDocumentId: 'PED-99999',
  details: {
    operatorName: '$jsonSchema',
    schemaRulesNotSatisfied: [
      {
        operatorName: 'properties',
        propertiesNotSatisfied: [
          {
            propertyName: 'estado',
            details: [
              {
                operatorName: 'enum',
                specifiedAs: {
                  enum: [
                    'PENDIENTE',
                    'PAGADO',
                    'ENVIADO',
                    'ENTREGADO',
                    'ANULADO'
                  ]
                },
                reason: 'value was not found in enum',
                consideredValue: 'DEVUELTO'
              }
            ]
          }
        ]
      }
    ]
  }
}
tienda> db.runCommand({collMod: "pedidos", validator: {}, validationLevel: "off"})
{ ok: 1 }
```

- **`$nor` con `$jsonSchema` encuentra los que no cumplen** antes de activar la regla: cero. Si
  hubiera alguno, activarla en modo estricto haría fallar cualquier actualización suya.
- **El total en texto y el estado inventado se rechazan**, con el motivo exacto en `reason`: el tipo
  no coincide, y el valor no está en la lista. Es lo que en PostgreSQL hacen el tipo `numeric` y el
  `CHECK` de `estado`.
- **Dos palancas, según la documentación**: `validationLevel` en `strict` valida todo, y en
  `moderate` deja actualizar sin validar los documentos que ya no cumplían; `validationAction` en
  `error` rechaza, y en `warn` deja pasar y lo anota en el registro. La última orden quitó el
  validador.

**Quién lo manda:** **motor**; `$jsonSchema` sigue el borrador 4 de JSON Schema, con las extensiones
y omisiones que lista la documentación, y la regla la escribe el equipo. **Cuánto:** una
comprobación por escritura, y la disciplina de mantener la regla al día con el código. **Cuándo
sí:** siempre que varios servicios escriban en la misma colección. **Cuándo no:** la validación no
reemplaza los tipos: una colección validada sigue sin claves foráneas ni restricciones entre
documentos.

> **Veredicto:** MongoDB puede validar el esquema, y lo hace bien; hay que pedírselo, y es la
> diferencia entre un esquema flexible y un esquema ausente.

---

## 3. 🧱 jsonb: la tercera vía

**Qué es:** un tipo de PostgreSQL que guarda JSON en formato binario, con operadores para
consultarlo por dentro e índices para hacerlo rápido. La tienda ya lo usa: `eventos_pedido.carga`,
con el estado, el origen, el importe y la versión de cada evento. Los eventos cuyo importe es el de
`PED-00042`, sin índice y con un índice GIN:

```text
tienda=# \timing on
El despliegue de duración está activado.
tienda=# EXPLAIN (ANALYZE, BUFFERS) SELECT id, carga FROM eventos_pedido WHERE carga @> '{"importe": 3186.23}';
                                                       QUERY PLAN
------------------------------------------------------------------------------------------------------------------------
 Seq Scan on eventos_pedido  (cost=0.00..133268.00 rows=410 width=106) (actual time=325.874..556.773 rows=8.00 loops=1)
   Filter: (carga @> '{"importe": 3186.23}'::jsonb)
   Rows Removed by Filter: 4099992
   Buffers: shared hit=1129 read=80889
   I/O Timings: shared read=2.152
 Planning:
   Buffers: shared hit=54
 Planning Time: 0.405 ms
 Execution Time: 556.842 ms
(9 filas)

Duración: 559,930 ms
tienda=# CREATE INDEX eventos_carga_gin ON eventos_pedido USING gin (carga jsonb_path_ops);
CREATE INDEX
Duración: 1912,083 ms (00:01,912)
tienda=# SELECT pg_size_pretty(pg_relation_size('eventos_carga_gin')) AS indice, pg_size_pretty(pg_relation_size('eventos_pedido')) AS tabla;
 indice | tabla
--------+--------
 60 MB  | 641 MB
(1 fila)

Duración: 1,203 ms
tienda=# EXPLAIN (ANALYZE, BUFFERS) SELECT id, carga FROM eventos_pedido WHERE carga @> '{"importe": 3186.23}';
                                                          QUERY PLAN
-------------------------------------------------------------------------------------------------------------------------------
 Bitmap Heap Scan on eventos_pedido  (cost=9.01..461.14 rows=410 width=106) (actual time=0.031..0.088 rows=8.00 loops=1)
   Recheck Cond: (carga @> '{"importe": 3186.23}'::jsonb)
   Heap Blocks: exact=2
   Buffers: shared hit=5 read=1
   I/O Timings: shared read=0.048
   ->  Bitmap Index Scan on eventos_carga_gin  (cost=0.00..8.90 rows=410 width=0) (actual time=0.009..0.009 rows=8.00 loops=1)
         Index Cond: (carga @> '{"importe": 3186.23}'::jsonb)
         Index Searches: 1
         Buffers: shared hit=4
 Planning:
   Buffers: shared hit=11 read=1
   I/O Timings: shared read=0.295
 Planning Time: 0.398 ms
 Execution Time: 0.103 ms
(14 filas)

Duración: 0,856 ms
```

- **`@>` es la contención**: «la carga contiene este fragmento». Sin índice, 4,1 millones de filas
  y 641 MB leídos para devolver 8, en 557 ms. Las 8 son los tres eventos de `PED-00042` y cinco de
  otro pedido con el mismo importe.
- **Con el índice GIN, 0,103 ms y seis páginas**: el `Bitmap Index Scan` de
  [`03/02`](../03-el-motor-por-dentro/02-familias-de-indices.md) sobre el contenido del JSON.
  `jsonb_path_ops` es la clase de operadores que, según la documentación, admite `@>`, `@?` y `@@`,
  pero no los operadores de existencia de clave; a cambio, el índice es más pequeño: 60 MB para una
  tabla de 641.

Y la validación, que en PostgreSQL es un `CHECK` sobre el propio JSON:

```text
tienda=# BEGIN;
BEGIN
Duración: 0,263 ms
tienda=*# ALTER TABLE eventos_pedido ADD CONSTRAINT carga_importe_numero CHECK (jsonb_typeof(carga->'importe') = 'number');
ALTER TABLE
Duración: 743,726 ms
tienda=*# UPDATE eventos_pedido SET carga = jsonb_set(carga, '{importe}', '"3186.23"') WHERE id = 168;
ERROR:  new row for relation "eventos_pedido" violates check constraint "carga_importe_numero"
DETALLE:  Failing row contains (168, 42, VALIDADO, {"estado": "PAGADO", "origen": "web", "importe": "3186.23", "ver..., 2025-02-21 03:45:09.349067+00).
Duración: 3,619 ms
tienda=!# ROLLBACK;
ROLLBACK
Duración: 0,331 ms
tienda=# DROP INDEX eventos_carga_gin;
DROP INDEX
Duración: 10,859 ms
```

- **El `CHECK` comprobó las 4,1 millones de filas al añadirse**, en 0,74 s, y después rechazó el
  importe en texto en el evento 168, el `VALIDADO` de `PED-00042`. El `ROLLBACK` deshizo la
  restricción, y el índice se borró: la tabla vuelve a su estado.
- **El documento convive con lo relacional**: `carga` está en una fila con su `pedido_id`, que es
  una clave foránea, dentro de las mismas transacciones que el resto de la tienda.

**Quién lo manda:** **motor**, con base en el **estándar**: PostgreSQL dice que implementa el modelo
SQL/JSON, y `jsonb`, `@>` y GIN son suyos. **Cuánto:** el GIN ocupa —60 MB— y se escribe en cada
inserción; y un `jsonb` grande se reescribe entero al cambiar un campo. **Cuándo sí:** la parte
variable de un dato que por lo demás es relacional, como la carga de un evento. **Cuándo no:** para
lo que se consulta, se une y se valida siempre igual, que va en columnas: la documentación de
PostgreSQL pide que cada documento JSON sea un dato que no se modifique por partes.

> **Veredicto:** `jsonb` da documentos consultables, indexables y validables sin salir de
> PostgreSQL; es la opción honesta cuando solo una parte del dato es de verdad un documento.

---

## 4. 🧭 Cómo se elige

| Si el dato… | Entonces | Porque, medido en este bloque |
|---|---|---|
| Se consulta por muchas columnas, se une con otros y cuadra con dinero | **Relacional** | El `JOIN` de ventas por país tardó 28 ms; el tipo rechazó el total en texto |
| Es relacional salvo una parte de forma variable | **`jsonb`** en PostgreSQL | La carga del evento, con GIN: 0,1 ms; validada con `CHECK`; en la misma transacción |
| Se lee y se escribe siempre entero, como un agregado, y escala más allá de una instancia | **Documental** | El pedido como un documento de 379 bytes, con escritura atómica del agregado |
| Se va a informar sobre sus partes a menudo | Relacional, o `jsonb` con las partes en columnas | El top de productos con `$unwind`: 214 ms frente a 81 |

- **La pregunta que decide no es «¿tiene forma de JSON?»**, porque casi todo la tiene: es **cómo se
  lee y quién más lo consulta**. Si hay informes cruzados, gana el modelo que tiene planificador.
- **Dos motores son dos cosas que operar**: si la aplicación ya vive en PostgreSQL, `jsonb` resuelve
  la mayoría de los casos documentales sin una segunda base, un segundo respaldo y un segundo modelo
  de consistencia.

> **Veredicto:** relacional por defecto, `jsonb` para la parte variable, y documental cuando el
> agregado entero es la unidad de lectura y escritura y la escala lo pide.

---

## 5. 🩺 «Compatible con la API de MongoDB» no es MongoDB

Varios servicios gestionados hablan el **protocolo** de MongoDB, así que los drivers y `mongosh` se
conectan sin cambios. Eso no significa que ejecuten todo lo que ejecuta MongoDB. Lo que dicen de sí
mismos, en su documentación:

| Servicio | Lo que declara | Lo que su documentación reconoce que no hace |
|---|---|---|
| **Amazon DocumentDB** | Compatibilidad con MongoDB 4.0, 5.0 y 8.0: «la gran mayoría» de aplicaciones, drivers y herramientas funcionan con pocos cambios o ninguno | Publica una página de diferencias funcionales; entre ellas, no admite `$elemMatch` dentro de `$all` |
| **Azure Cosmos DB for MongoDB**, en su versión por unidades de solicitud | Soporta el protocolo de MongoDB y sus drivers | En su página de la versión 4.2: transacciones multidocumento **solo dentro de una colección sin fragmentar**, y `collMod`, con el que §2 puso el validador, **no se admite** |

- **La compatibilidad se declara por versión de API, no por comportamiento.** Un código que use
  `$elemMatch` dentro de `$all`, o una transacción entre dos colecciones, funciona en MongoDB y
  falla en el servicio compatible, y el fallo aparece en producción si las pruebas corren contra
  MongoDB.
- **La prueba útil es la de tus consultas**: la lista de diferencias de cada servicio contra las
  operaciones que usa tu código, y las pruebas de integración contra el servicio real, no contra un
  MongoDB local. Es la lección de [`11/05`](../11-orms/05-probar-contra-base-de-datos-real.md) con
  H2: una base que se parece no es la base.

**Quién lo manda:** **cada servicio**, que define su propia compatibilidad. **Cuánto:** en
**riesgo** de fallos que las pruebas locales no ven, y en tiempo de revisar la lista de diferencias
en cada cambio de versión. **Cuándo sí:** cuando las operaciones que usas están todas en la parte
compatible, comprobado. **Cuándo no:** cuando el diseño depende de transacciones entre colecciones,
de validación con `collMod` o de operadores poco comunes.

> **Veredicto:** «compatible con la API de MongoDB» significa que el driver conecta; lo que se
> ejecuta hay que comprobarlo contra la lista de diferencias de cada servicio.

---

## 6. 📜 Estándar, motor y convención

> **📜 Estándar o motor.** El estándar SQL tiene su parte para JSON, SQL/JSON, que PostgreSQL
> implementa según su documentación; no he verificado la cláusula. La validación de MongoDB y la
> compatibilidad de los servicios gestionados son de cada producto.

| Afirmación | Estándar | PostgreSQL 18 | MongoDB 8.0 |
|---|---|---|---|
| Se puede consultar por el contenido de un documento | SQL/JSON | `@>`, rutas y funciones SQL/JSON | Sí, es su lenguaje |
| Se puede indexar el contenido de un documento | — | GIN: de 557 ms a 0,103 | Índices sobre campos, también multikey |
| El documento se valida si se pide | `CHECK` | `CHECK` sobre el JSON: rechazó el texto | `$jsonSchema`: rechazó el texto y el estado |
| El documento convive con claves foráneas y transacciones | Sí | Sí: `carga` está en una fila con su `pedido_id` | Sin claves foráneas entre colecciones |
| Un servicio «compatible con MongoDB» hace lo mismo que MongoDB | — | — | No: cada uno publica sus diferencias |

**Convención, la que más se repite.** *«Si el dato es JSON, va en una base documental»* — casi todo
dato es JSON cuando viaja por una API. La pregunta es cómo se lee y quién más lo consulta, y para la
parte variable de un dato relacional, `jsonb` lo resuelve sin segunda base.

---

## ⚠️ Errores frecuentes

| Se dice | Lo preciso |
|---|---|
| "MongoDB no puede validar el esquema" | `$jsonSchema` rechazó el total en texto y el estado inventado, con el motivo exacto |
| "Activar la validación arregla los datos que ya había" | No los toca; con `moderate`, ni siquiera obliga a validarlos al actualizarlos |
| "El JSON en PostgreSQL es lento" | Con GIN, el `@>` bajó de 557 ms a 0,103 |
| "En `jsonb` no se puede validar nada" | Un `CHECK` con `jsonb_typeof` rechazó el importe en texto |
| "`jsonb_path_ops` es el GIN de siempre" | Admite `@>`, `@?` y `@@`, pero no los operadores de existencia de clave, y ocupa menos |
| "DocumentDB y Cosmos DB son MongoDB gestionado" | Hablan su protocolo; cada uno publica lo que no hace, como las transacciones entre colecciones en Cosmos DB |
| "Si las pruebas pasan contra MongoDB, pasan en el servicio compatible" | Solo si las operaciones usadas están en su parte compatible |

---

## 📚 Para profundizar

- **Documentación** — MongoDB 8.0, «Schema Validation».
  <https://www.mongodb.com/docs/v8.0/core/schema-validation/>
- **Documentación** — MongoDB 8.0, «Specify Validation Level for Existing Documents»: `strict` y
  `moderate`. <https://www.mongodb.com/docs/v8.0/core/schema-validation/specify-validation-level/>
- **Documentación** — PostgreSQL 18, «JSON Types»: `jsonb`, la contención y la indexación GIN.
  <https://www.postgresql.org/docs/18/datatype-json.html>
- **Documentación** — PostgreSQL 18, «JSON Functions and Operators»: SQL/JSON.
  <https://www.postgresql.org/docs/18/functions-json.html>
- **Documentación** — Amazon DocumentDB, «Amazon DocumentDB compatibility with MongoDB».
  <https://docs.aws.amazon.com/documentdb/latest/devguide/compatibility.html>
- **Documentación** — Amazon DocumentDB, «Functional differences: Amazon DocumentDB and MongoDB».
  <https://docs.aws.amazon.com/documentdb/latest/devguide/functional-differences.html>
- **Documentación** — Microsoft, «Azure Cosmos DB for MongoDB (RU) 4.2 feature support».
  <https://learn.microsoft.com/en-us/azure/cosmos-db/mongodb/feature-support-42>

---

## 🧠 Preguntas

1. ¿Qué es un validador `$jsonSchema` en MongoDB? 🟢
2. ¿Qué hace el operador `@>` sobre un `jsonb`? 🟢
3. ¿Qué significa que un servicio sea «compatible con la API de MongoDB»? 🟢
4. Distingue `validationLevel` `strict` de `moderate`, y `validationAction` `error` de `warn`. 🟡
5. Distingue `json` de `jsonb` en PostgreSQL, y di cuál se indexa con GIN. 🟡
6. Distingue la clase de operadores GIN por defecto de `jsonb_path_ops`. 🟡
7. ¿Qué parte de validar un documento es del estándar SQL, y qué parte es de cada motor? 🟡
8. ¿Qué garantías tiene `eventos_pedido.carga` en PostgreSQL que no tendría la misma carga en una
   colección de MongoDB? 🟡
9. ¿Por qué hay que buscar los documentos que no cumplen antes de activar un validador en modo
   `strict`? 🟠
10. ¿Por qué el `@>` bajó de 557 ms a 0,103 con el índice, y qué cuesta ese índice? 🟠
11. ¿Cuándo pondrías un dato en `jsonb` y cuándo en columnas, con la frase de la documentación de
    PostgreSQL? 🟠
12. ¿Por qué un código que funciona contra MongoDB puede fallar en Cosmos DB for MongoDB? Da dos
    ejemplos de la documentación. 🟠
13. ¿Por qué dos motores en una misma aplicación cuestan más que la suma de sus licencias? 🟠
14. Diseña cómo guardarías los atributos variables por categoría de los productos de la tienda
    —el audio con potencia, el libro con páginas— en PostgreSQL, con su índice y su validación. 🔴
15. Te proponen migrar a Amazon DocumentDB una aplicación que usa transacciones entre colecciones y
    `$elemMatch` dentro de `$all`. Da el plan de comprobación antes de decidir. 🔴
16. Defiende ante un equipo si los eventos de pedido deberían ir a MongoDB o quedarse en
    `eventos_pedido.carga`, con los números del bloque. 🔴
17. Diagnostica: tras activar un validador en una colección con años de datos, empiezan a fallar
    actualizaciones de documentos antiguos que nadie ha tocado en meses. Da la causa y dos formas de
    salir. 🔴

---

**Anterior:** [`04`](04-indices-transacciones-y-consistencia.md) — índices, transacciones y
consistencia · **Siguiente:** [`06`](06-simulacion-de-entrevista.md) — la simulación del bloque ·
**Relacionado:** [`03/02`](../03-el-motor-por-dentro/02-familias-de-indices.md) — GIN entre las
familias de índices · [`11/05`](../11-orms/05-probar-contra-base-de-datos-real.md) — probar contra
la base real y no contra una que se parece.
