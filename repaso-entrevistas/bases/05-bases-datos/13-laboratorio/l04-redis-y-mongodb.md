# l04 — Redis y MongoDB

> Una caché con caducidad en Redis y la **estampida** que se produce cuando caduca bajo carga,
> provocada con 50 peticiones a la vez y corregida con un candado; y una colección de MongoDB
> cargada desde PostgreSQL, con su `explain` antes y después de un índice y una agregación que da,
> céntimo a céntimo, lo mismo que su `GROUP BY`. **Tiempo estimado:** 30 minutos. **Asume
> levantado:** el entorno de [`l00`](l00-el-entorno-y-los-datos.md), con el perfil `lenguajes`
> construido. **Asume leído:**
> [`10/07`](../10-interfaz-con-los-lenguajes/07-clientes-de-redis-y-mongodb.md), los clientes de los
> dos. **Vigencia:** 26 de septiembre de 2026.

---

## Salto rápido

- [1. Qué vas a ver](#1--qué-vas-a-ver) · [2. La caché con
  caducidad](#2--paso-1--la-caché-con-caducidad)
- [3. La estampida](#3--paso-2--la-estampida) · [4. Cargar MongoDB](#4--paso-3--cargar-mongodb)
- [5. `explain` y el índice](#5--paso-4--explain-y-el-índice) · [6. La
  agregación](#6--paso-5--la-agregación-frente-al-group-by) · [Ejercicios](#-ejercicios) ·
  [Preguntas](#-preguntas)

---

## 1. 🎯 Qué vas a ver

Redis y MongoDB tienen sus propios bloques, el 07 y el 08, que lista el [README de la
raíz](../README.md). Este lab no los sustituye: toca con las manos las dos cosas que más se
preguntan de cada uno. De Redis, **qué pasa cuando la caché falla a la vez para todos**. De MongoDB,
**cómo se sabe si una consulta usa un índice** y si el modelo de documento cuenta lo mismo que las
tablas.

Los nombres son los del documento de dominio: la clave `pedido:PED-00042` en Redis y la colección
`tienda.pedidos` en MongoDB, con el pedido como documento y sus líneas dentro. **Ninguna de las dos
existe al empezar, y las dos se borran al terminar.**

> **📝 Contexto.** Todo está corrido contra el entorno del corpus: PostgreSQL solo se lee, y lo que
> se crea en Redis y MongoDB se borra en su paso. La estampida se corrió tres veces con el mismo
> resultado de consultas; los milisegundos variaron poco —de 404 a 442 sin protección—. Los pasos 3
> a 5 se volvieron a correr el 26 de septiembre contra MongoDB 8.0.20 (§4.1 del dominio dice por qué
> esa versión): mismos documentos, mismos planes y mismas sumas; solo cambian los milisegundos.
> **Longitud:** unas 415 líneas; lab normal.

---

## 2. 🧱 Paso 1 — La caché con caducidad

```bash
docker exec -it bd-lab-redis redis-cli
```

- `-it` conecta tu terminal al contenedor en modo interactivo, y `redis-cli` abre la consola de
  Redis contra el servidor del propio contenedor.

```text
127.0.0.1:6379> SET pedido:PED-00042 "{\"estado\": \"PAGADO\"}" EX 5
OK
127.0.0.1:6379> GET pedido:PED-00042
"{\"estado\": \"PAGADO\"}"
127.0.0.1:6379> TTL pedido:PED-00042
(integer) 3
127.0.0.1:6379> LPUSH pedido:PED-00042 linea1
(error) WRONGTYPE Operation against a key holding the wrong kind of value
127.0.0.1:6379> GET pedido:PED-00042
(nil)
127.0.0.1:6379> TTL pedido:PED-00042
(integer) -2
```

- `SET … EX 5` guarda la cadena con una caducidad de cinco segundos, en la misma orden: no hay un
  instante en que la clave exista sin caducidad. `TTL` dice los segundos que le quedan.
- **El error, a propósito**: `LPUSH` trata la clave como una lista, y es una cadena. **Cada clave de
  Redis tiene un tipo**, y las órdenes de otro tipo fallan; el nombre `pedido:` no dice nada de eso,
  es una convención.
- **Cinco segundos después la clave no existe**: `GET` da `(nil)` y `TTL` da `-2`, que significa «no
  existe» —`-1` sería «existe y no caduca»—. La caducidad es su propio teardown.

---

## 3. 🩺 Paso 2 — La estampida

**El caso**: la ficha de `PED-00042` se sirve desde Redis y, si no está, se lee de PostgreSQL y se
guarda —el patrón *cache-aside*—. Mientras la clave existe, PostgreSQL no se entera. **El problema
aparece en el instante en que caduca**: todas las peticiones que llegan a la vez la encuentran vacía
y van a la base a la vez.

El programa lo provoca con 50 hilos que llegan juntos, y una consulta que tarda 200 ms a propósito.
Lo esencial de las dos versiones:

```python
def ingenuo():                                  # cache-aside sin protección
    v = r.get(CLAVE)
    if v is None:
        v = cargar()                            # SELECT … FROM pedidos, pg_sleep(0.2) …
        r.set(CLAVE, v, ex=30)
    return v

def con_candado():                              # solo quien consigue el candado va a la base
    v = r.get(CLAVE)
    while v is None:
        if r.set(CLAVE + ":candado", "1", nx=True, ex=5):
            v = cargar()
            r.set(CLAVE, v, ex=30)
            r.delete(CLAVE + ":candado")
        else:
            time.sleep(0.05)
            v = r.get(CLAVE)
    return v
```

```bash
docker compose -f 13-laboratorio/entorno/docker-compose.yml run --rm -q python python estampida.py
```

- `run --rm -q python` arranca el contenedor de Python del perfil `lenguajes` con `estampida.py` de
  la carpeta `codigo/`, que escribes tú, y lo borra al terminar. Se conecta a `redis` y a `postgres`
  por su nombre de servicio.

```text
sin protección       50 peticiones -> 50 consultas a PostgreSQL en  405 ms
con candado SET NX   50 peticiones ->  1 consultas a PostgreSQL en  283 ms
en caché: {"codigo" : "PED-00042", "estado" : "PAGADO", "total" : 3186.23} · caduca en 30 s
```

- **Sin protección, cincuenta consultas idénticas** para una sola respuesta. Aquí son 50 de 200 ms y
  la base lo aguanta; con mil peticiones por segundo y una consulta de dos segundos, la caducidad de
  una clave es un pico de carga sobre la base que puede tumbarla, y justo cuando la caché no la
  protege.
- **Con el candado, una.** `SET … NX` escribe la clave solo si no existe, y es atómico: de los 50
  hilos, uno lo consigue y va a la base; los demás esperan a que aparezca el valor. Tardó menos en
  total porque la base atendió una consulta de 200 ms en vez de cincuenta compitiendo entre sí.
- **El candado lleva su propia caducidad** —`ex=5`—: si el proceso que lo tiene muere a mitad, el
  candado desaparece solo y otro puede cargar. Un candado sin caducidad es un bloqueo permanente
  esperando a pasar.

**Teardown de este paso:** el programa termina con `r.delete(CLAVE)`; `DBSIZE` en `redis-cli` tiene
que responder `0`.

> **💡 Truco.** Hay otras dos defensas, y se combinan: **caducidades con un poco de azar** —30 s más
> o menos 5—, para que no caduquen juntas mil claves creadas a la vez, y **refresco anticipado**,
> recargar la clave un poco antes de que caduque. El candado protege una clave; el azar, un lote.

---

## 4. 🧱 Paso 3 — Cargar MongoDB

**Qué es:** los pedidos de PostgreSQL convertidos en documentos, uno por pedido, con sus líneas
dentro. Se acota a los pedidos hasta `PED-99999`: 99 999 documentos, bastantes para que un índice se
note. PostgreSQL escribe cada documento en JSON extendido, el dialecto que `mongoimport` entiende:

```sql
SELECT json_build_object(
         '_id', p.codigo,
         'cliente_id', p.cliente_id,
         'estado', p.estado,
         'total', json_build_object('$numberDecimal', p.total::text),
         'creado_en', json_build_object('$date', to_char(p.creado_en AT TIME ZONE 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS.MS"Z"')),
         'lineas', (SELECT json_agg(json_build_object('linea', l.linea, 'producto_id', l.producto_id,
                                                      'cantidad', l.cantidad,
                                                      'precio_unit', json_build_object('$numberDecimal', l.precio_unit::text))
                                    ORDER BY l.linea)
                      FROM pedido_lineas l WHERE l.pedido_id = p.id))
  FROM pedidos p
 WHERE p.id <= 99999
 ORDER BY p.id;
```

- **`$numberDecimal` y `$date` conservan los tipos**: sin ellos, el importe llegaría como número de
  coma flotante y la fecha como texto, las dos trampas de
  [`10/03`](../10-interfaz-con-los-lenguajes/03-mapeo-de-tipos.md) §4 y §5.
- Se escribe con `psql -At -f … > 13-laboratorio/entorno/datos/pedidos-mongo.json`: `-A` sin
  alineación, `-t` sin cabeceras, un documento por línea. 1,7 s y 52 MB.

**El error, a propósito**: importar sin credenciales.

```bash
docker exec bd-lab-mongo mongoimport -d tienda -c pedidos --file /entorno/datos/pedidos-mongo.json
```

- `mongoimport` corre dentro del contenedor, que ve `datos/` en `/entorno/datos`. `-d` es la base,
  `-c` la colección y `--file` el fichero.

```text
2026-09-26T23:42:16.711+0000	connected to: mongodb://localhost/
2026-09-26T23:42:16.734+0000	Failed:  connection(localhost:27017[-3]) incomplete read of message header: connection closed unexpectedly by the other side: EOF: connection(localhost:27017[-3]) incomplete read of message header: connection closed unexpectedly by the other side: EOF
2026-09-26T23:42:16.734+0000	0 document(s) imported successfully. 0 document(s) failed to import.
```

- **El mensaje no dice «autenticación»**: dice que el servidor cerró la conexión. La causa está en
  el registro del servidor —`docker logs bd-lab-mongo`—, que anota para esa conexión `Connection not
  authenticating`. El entorno arranca MongoDB con un usuario `root`, y sin credenciales no se puede
  escribir.

La corrección:

```bash
docker exec bd-lab-mongo mongoimport -u root -p root --authenticationDatabase admin \
  -d tienda -c pedidos --file /entorno/datos/pedidos-mongo.json
```

- `--authenticationDatabase admin` dice dónde está definido el usuario: `root` se creó en la base
  `admin`, no en `tienda`.

```text
2026-09-26T23:42:16.907+0000	connected to: mongodb://localhost/
2026-09-26T23:42:19.372+0000	99999 document(s) imported successfully. 0 document(s) failed to import.
```

---

## 5. 🩺 Paso 4 — `explain` y el índice

```bash
docker exec -it bd-lab-mongo mongosh -u root -p root --authenticationDatabase admin tienda
```

- `mongosh` es la consola de MongoDB; el último argumento es la base, y el prompt lo dice:
  `tienda>`.

```text
tienda> db.pedidos.countDocuments()
99999
tienda> db.pedidos.findOne({_id: "PED-00042"}, {lineas: 0})
{
  _id: 'PED-00042',
  cliente_id: 26446,
  estado: 'PAGADO',
  total: Decimal128('3186.23'),
  creado_en: ISODate('2025-02-21T03:08:09.349Z')
}
tienda> db.pedidos.insertOne({_id: "PED-00042", estado: "ENVIADO"})
Uncaught MongoServerError: E11000 duplicate key error collection: tienda.pedidos index: _id_ dup key: { _id: "PED-00042" }
```

- `{lineas: 0}` es una **proyección**: devuelve el documento sin ese campo. `Decimal128` e `ISODate`
  confirman que los tipos llegaron bien.
- **El error, a propósito**: `_id` es la clave primaria de toda colección, con su índice único
  —`_id_`—, y `E11000` es el código del duplicado. Es el `unique_violation` de PostgreSQL con otro
  nombre.

Para leer el plan sin su documento entero, una función que resume lo que importa:

```text
tienda> const plan = (c) => { const e = c.explain("executionStats"); return {etapa: e.queryPlanner.winningPlan.stage, entrada: e.queryPlanner.winningPlan.inputStage?.stage, devueltos: e.executionStats.nReturned, docs_examinados: e.executionStats.totalDocsExamined, claves_examinadas: e.executionStats.totalKeysExamined, ms: e.executionStats.executionTimeMillis} }

tienda> plan(db.pedidos.find({cliente_id: 311}))
{
  etapa: 'COLLSCAN',
  entrada: undefined,
  devueltos: 7,
  docs_examinados: 99999,
  claves_examinadas: 0,
  ms: 33
}
tienda> db.pedidos.createIndex({cliente_id: 1})
cliente_id_1
tienda> plan(db.pedidos.find({cliente_id: 311}))
{
  etapa: 'FETCH',
  entrada: 'IXSCAN',
  devueltos: 7,
  docs_examinados: 7,
  claves_examinadas: 7,
  ms: 0
}
```

- **`COLLSCAN` es el `Seq Scan` de MongoDB**: examinó 99 999 documentos en 33 ms para devolver 7.
  `explain("executionStats")` ejecuta la consulta, como el `ANALYZE` de `EXPLAIN`.
- **Con el índice, `IXSCAN` dentro de un `FETCH`**: recorre 7 claves del índice y trae 7 documentos,
  en menos de un milisegundo. Es el `Index Scan` de [`l01`](l01-explain-e-indices-medidos.md) §3,
  con otros nombres.
- **La cifra que hay que comparar es `docs_examinados` frente a `devueltos`**: cuando se parecen, la
  consulta hace el trabajo justo; 99 999 contra 7 es la señal de que falta un índice.

---

## 6. 🩺 Paso 5 — La agregación frente al `GROUP BY`

El total por estado, en MongoDB y en PostgreSQL, sobre los mismos 99 999 pedidos:

```text
tienda> db.pedidos.aggregate([{$group: {_id: "$estado", pedidos: {$sum: 1}, importe: {$sum: "$total"}}}, {$sort: {pedidos: -1}}])
[
  {
    _id: 'ENTREGADO',
    pedidos: 29906,
    importe: Decimal128('154675979.07')
  },
  { _id: 'ENVIADO', pedidos: 27040, importe: Decimal128('139677851.34') },
  { _id: 'PAGADO', pedidos: 24910, importe: Decimal128('128230797.61') },
  {
    _id: 'PENDIENTE',
    pedidos: 12183,
    importe: Decimal128('63394890.47')
  },
  { _id: 'ANULADO', pedidos: 5960, importe: Decimal128('30986780.66') }
]
```

```text
tienda=# SELECT estado, count(*) AS pedidos, sum(total) AS importe FROM pedidos WHERE id <= 99999 GROUP BY estado ORDER BY pedidos DESC;
  estado   | pedidos |   importe
-----------+---------+--------------
 ENTREGADO |   29906 | 154675979.07
 ENVIADO   |   27040 | 139677851.34
 PAGADO    |   24910 | 128230797.61
 PENDIENTE |   12183 |  63394890.47
 ANULADO   |    5960 |  30986780.66
(5 filas)
```

- **Iguales al céntimo**, porque `total` viajó como `$numberDecimal` y se sumó como `Decimal128`.
  Con el importe en coma flotante, la suma de MongoDB tendría decimales de más.
- **`$group` es el `GROUP BY` y `$sort` el `ORDER BY`**, como etapas de una tubería: cada una recibe
  los documentos de la anterior. El `_id` del resultado es la clave de agrupación.

**Teardown de este paso:**

```bash
docker exec bd-lab-mongo mongosh --quiet -u root -p root --authenticationDatabase admin tienda --eval 'db.pedidos.drop()'
rm 13-laboratorio/entorno/datos/pedidos-mongo.json
```

- `drop()` borra la colección con su índice y responde `true`. `db.getCollectionNames()` vuelve a
  dar `[]`, que es el estado del entorno.

---

## 7. 📜 Estándar, motor y convención

> **📜 Estándar o motor.** Ni Redis ni MongoDB tienen un estándar como ISO/IEC 9075: cada uno es su
> propia especificación. Lo que se compara es con qué pieza de SQL se corresponde cada cosa.

| Pieza | PostgreSQL 18 | Redis 8.10 | MongoDB 8.0 |
|---|---|---|---|
| Plan de una consulta | `EXPLAIN (ANALYZE)` | No aplica: cada orden es un acceso por clave | `explain("executionStats")` |
| Recorrido completo | `Seq Scan` | — | `COLLSCAN` |
| Acceso por índice | `Index Scan` | — | `FETCH` sobre `IXSCAN` |
| Duplicado en la clave | SQLSTATE `23505` | `SET NX` no escribe y responde nulo | `E11000` |
| Caducidad de un dato | No tiene | `EX` en `SET`, o `EXPIRE` | Índice TTL sobre una fecha |

**Convención, la que más se repite.** *«Con una caché delante, la base descansa»* — descansa
mientras la clave vive. En el instante en que caduca, sin protección, recibe todas las peticiones a
la vez: la caché no quita la carga, la concentra.

---

## ⚠️ Errores frecuentes

| Se dice | Lo preciso |
|---|---|
| "Con caché, la base no recibe picos" | Al caducar, 50 peticiones fueron 50 consultas a la vez |
| "Un candado en Redis es un `SET` y ya" | Sin caducidad propia, un proceso muerto lo deja puesto para siempre |
| "`TTL` -2 y -1 son lo mismo" | -2 es que la clave no existe; -1, que existe y no caduca |
| "El error de `mongoimport` es de red" | Es de autenticación, y solo lo dice el registro del servidor |
| "MongoDB no usa índices como una base SQL" | `COLLSCAN` frente a `IXSCAN`: 99 999 documentos examinados frente a 7 |

---

## 🧪 Ejercicios

1. Guarda `pedido:PED-00042` sin caducidad y comprueba qué responde `TTL`. Bórrala con `DEL`. 🟢
2. Cambia la consulta de §3 a 1 s y repite la estampida: compara el tiempo total de las dos
   versiones. 🟡
3. Añade a la versión ingenua caducidades con azar para cien claves distintas y mide cuántas caducan
   en el mismo segundo con y sin azar. 🟡
4. Cuenta en MongoDB las unidades vendidas por producto con `$unwind` sobre `lineas` y compáralo con
   el `GROUP BY` equivalente en PostgreSQL. 🟠
5. Crea un índice compuesto `{cliente_id: 1, creado_en: -1}` y comprueba con `explain` si la
   consulta de los pedidos de un cliente ordenados por fecha necesita una etapa `SORT`. 🟠
6. Diseña la caché de la ficha de cliente de la tienda: clave, caducidad, invalidación al cambiar un
   pedido y defensa contra la estampida. Escribe las órdenes. 🔴
7. Provoca la estampida con el candado pero haz que el proceso que lo tiene muera antes de borrarlo,
   y mide cuánto tardan los demás en recuperarse. 🔥 *(fuera de conteo)*

---

## 📚 Para profundizar

- **Documentación** — Redis, `SET`: las opciones `EX` y `NX`.
  <https://redis.io/docs/latest/commands/set/>
- **Documentación** — Redis, `TTL`: los valores -1 y -2.
  <https://redis.io/docs/latest/commands/ttl/>
- **Documentación** — MongoDB, «Explain Results».
  <https://www.mongodb.com/docs/manual/reference/explain-results/>
- **Documentación** — MongoDB, `mongoimport`.
  <https://www.mongodb.com/docs/database-tools/mongoimport/>
- **Documentación** — MongoDB, `$group`.
  <https://www.mongodb.com/docs/manual/reference/operator/aggregation/group/>

---

## 🧠 Preguntas

1. ¿Qué hace `SET clave valor EX 5`, y qué responde `TTL` después? 🟢
2. ¿Qué es el patrón *cache-aside*? 🟢
3. ¿Qué son `COLLSCAN` e `IXSCAN` en un `explain` de MongoDB? 🟢
4. ¿Qué significa el error `E11000`? 🟢
5. Distingue los valores -1 y -2 de `TTL`. 🟡
6. ¿Por qué `SET … NX` sirve de candado, y por qué necesita caducidad? 🟡
7. ¿Por qué el importe se exportó como `$numberDecimal` y no como número? 🟡
8. ¿Qué parte de este lab tiene equivalente en SQL y cuál no? Da dos ejemplos. 🟡
9. ¿Qué es una estampida de caché, y por qué ocurre justo al caducar una clave? 🟠
10. ¿Por qué la versión con candado tardó menos en total que la ingenua? 🟠
11. ¿Por qué el error de `mongoimport` sin credenciales despista, y dónde se ve la causa? 🟠
12. ¿Qué dos cifras de `explain("executionStats")` delatan que falta un índice? 🟠
13. ¿Qué otras dos defensas contra la estampida hay además del candado, y qué protege cada una? 🟠
14. Diagnostica: cada hora en punto la base recibe un pico de consultas idénticas y la latencia se
    dispara durante unos segundos. Da la hipótesis, cómo la confirmarías y dos correcciones. 🔴
15. Diseña la comprobación de que una colección de MongoDB cargada desde PostgreSQL tiene los mismos
    datos: qué agregaciones y qué consultas SQL compararías. 🔴

---

**Anterior:** [`l03`](l03-respaldo-y-restauracion.md) — respaldo y restauración · **Siguiente:**
[`l05`](l05-los-otros-modelos.md) — los otros modelos · **Relacionado:**
[`10/07`](../10-interfaz-con-los-lenguajes/07-clientes-de-redis-y-mongodb.md) — los clientes de
Redis y MongoDB y sus tiempos de espera.
