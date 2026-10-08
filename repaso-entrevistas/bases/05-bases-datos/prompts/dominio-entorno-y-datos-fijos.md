# 🗃️ Dominio, entorno y datos fijos

> **Dueño único** del esquema, los identificadores, los volúmenes, los nombres de contenedor, los
> puertos y las versiones exactas de cada imagen. Ningún documento del corpus inventa un nombre, un
> número o una versión que no esté aquí.
>
> Manda sobre cualquier documento publicado, y solo cede ante
> [`guia-de-estilo-y-convenciones.md`](guia-de-estilo-y-convenciones.md) en cuestiones de forma.
>
> **Vigencia:** 2026-09-27. · **Versiones verificadas:** 2026-09-19 contra Docker Hub (§4.1);
> MongoDB y DynamoDB, 2026-09-26; texto y vectores del bloque 09 y migraciones del 06, 2026-09-27.
>
> **Entorno corrido y verificado:** 2026-09-19. Las 22 comprobaciones de `verificar.sql` pasan.

---

## Salto rápido

- [1. El dominio](#1--el-dominio)
- [2. El esquema](#2--el-esquema)
- [3. Los datos](#3--los-datos)
- [4. El entorno](#4--el-entorno)
- [5. Convenciones de la sesión](#5--convenciones-de-la-sesión)
- [6. Lo que está prohibido](#6--lo-que-está-prohibido)

---

## 1. 🎯 El dominio

Una tienda. Seis tablas, ni una más: todo el corpus —desde el álgebra relacional hasta el diseño
desde el patrón de acceso en DynamoDB— se explica sobre este mismo dominio.

Se eligió así a propósito. Un dominio por bloque obligaría al lector a recalibrar el vocabulario
cada vez, y el corpus perdería lo que más le sirve: **que reconozcas la misma tabla en el capítulo
de normalización, en el de planes, en el de bloqueos y en el de ORM, y veas cómo la misma decisión
de esquema se paga en cada uno**.

El dominio da de sí lo suficiente para todo el temario:

| Lo que hace falta enseñar | Dónde lo da el dominio |
|---|---|
| Clave natural frente a sustituta | `id` sustituto y `codigo` natural conviven en cada tabla |
| Clave compuesta | `pedido_lineas (pedido_id, linea)` |
| Relación N:M con atributos | `pedido_lineas` entre `pedidos` y `productos` |
| Dinero, y por qué nunca `float` | `numeric(12,2)` en tres tablas |
| Fechas con zona | `timestamptz` en todas las marcas de tiempo |
| Nulos con significado | `pagos.referencia`, `pedidos.actualizado_en` |
| Desnormalización deliberada | `pedidos.total`, redundante contra `pedido_lineas` |
| JSON dentro de relacional | `eventos_pedido.carga` |
| Serie temporal y alta cardinalidad | `eventos_pedido`, 4 millones de filas |

---

## 2. 🧱 El esquema

### 2.1 El DDL de referencia (PostgreSQL)

Es el esquema canónico. Los demás motores lo traducen (§2.3).

```sql
CREATE TABLE clientes (
  id             bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  codigo         text NOT NULL UNIQUE,              -- CLI-00311: la clave natural visible
  nombre         text NOT NULL,
  email          text NOT NULL UNIQUE,
  pais           char(2) NOT NULL,                  -- ISO 3166-1 alfa-2
  creado_en      timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE productos (
  id             bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  codigo         text NOT NULL UNIQUE,              -- PRD-00017
  nombre         text NOT NULL,
  categoria      text NOT NULL,
  precio         numeric(12,2) NOT NULL CHECK (precio >= 0),
  activo         boolean NOT NULL DEFAULT true
);

CREATE TABLE pedidos (
  id             bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  codigo         text NOT NULL UNIQUE,              -- PED-00042
  cliente_id     bigint NOT NULL REFERENCES clientes(id),
  estado         text NOT NULL
                 CHECK (estado IN ('PENDIENTE','PAGADO','ENVIADO','ENTREGADO','ANULADO')),
  total          numeric(12,2) NOT NULL DEFAULT 0 CHECK (total >= 0),  -- desnormalizado a propósito
  creado_en      timestamptz NOT NULL,
  actualizado_en timestamptz                        -- nulo mientras nadie lo ha tocado
);

CREATE TABLE pedido_lineas (
  pedido_id      bigint NOT NULL REFERENCES pedidos(id) ON DELETE CASCADE,
  linea          smallint NOT NULL,
  producto_id    bigint NOT NULL REFERENCES productos(id),
  cantidad       integer NOT NULL CHECK (cantidad > 0),
  precio_unit    numeric(12,2) NOT NULL,            -- precio congelado en el momento de la compra
  PRIMARY KEY (pedido_id, linea)                    -- clave compuesta, a propósito
);

CREATE TABLE pagos (
  id             bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  pedido_id      bigint NOT NULL REFERENCES pedidos(id),
  metodo         text NOT NULL CHECK (metodo IN ('TARJETA','TRANSFERENCIA','EFECTIVO')),
  importe        numeric(12,2) NOT NULL CHECK (importe > 0),
  pagado_en      timestamptz NOT NULL,
  referencia     text UNIQUE                        -- del proveedor; nulo en efectivo
);

CREATE TABLE eventos_pedido (
  id             bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  pedido_id      bigint NOT NULL REFERENCES pedidos(id) ON DELETE CASCADE,
  tipo           text NOT NULL,
  carga          jsonb NOT NULL,
  ocurrido_en    timestamptz NOT NULL DEFAULT now()
);
```

### 2.2 Lo que el esquema NO trae, y por qué

**Ningún índice más allá de los que crean `PRIMARY KEY` y `UNIQUE`.**

No es un descuido: es la condición para que el bloque 03 funcione. Si el esquema llegara indexado,
el capítulo de planes no podría enseñar el antes y el después, y `03/06` —"cuándo el índice no se
usa"— se quedaría sin material. **Los índices se crean dentro de los capítulos que los explican**, y
cada uno declara cuál crea.

Tampoco trae disparadores, vistas ni funciones: los crea el bloque 05, y los borra al terminar.

> **⚠️ Advertencia.** Si un capítulo necesita un índice para su ejemplo, lo crea, lo mide y **dice
> si lo deja o lo borra**. Un capítulo que deja índices sin declarar rompe los planes de los
> capítulos siguientes, y los planes pegados dejan de ser reproducibles.

### 2.3 El mismo esquema en los otros motores

Se traduce, no se reinventa. Los nombres de tabla y columna son idénticos en los cuatro.

| Concepto | PostgreSQL | MySQL / MariaDB | SQLite |
|---|---|---|---|
| Clave sustituta | `bigint GENERATED ALWAYS AS IDENTITY` | `BIGINT AUTO_INCREMENT` | `INTEGER PRIMARY KEY` |
| Texto | `text` | `VARCHAR(n)` / `TEXT` | `TEXT` |
| Dinero | `numeric(12,2)` | `DECIMAL(12,2)` | `TEXT` o entero de céntimos |
| Marca de tiempo con zona | `timestamptz` | `TIMESTAMP` (guarda en UTC) | `TEXT` en ISO-8601 |
| Booleano | `boolean` | `TINYINT(1)` | `INTEGER` 0/1 |
| JSON | `jsonb` | `JSON` | `TEXT` + funciones `json_*` |
| Juego de caracteres | UTF-8 de la base | **`utf8mb4` obligatorio** | UTF-8 siempre |

Las tres trampas que el corpus explota de esta tabla, y que ya tienen dueño:

- **SQLite no tiene tipo de fecha ni tipo booleano.** Su tipado es dinámico y por afinidad. Dueño:
  `02/01`.
- **`utf8` de MySQL no es UTF-8**: son tres bytes y no cubre los emoji. El que sirve es `utf8mb4`.
  Dueño: `02/01`.
- **El `TIMESTAMP` de MySQL convierte a la zona de la sesión al leer**, y `DATETIME` no convierte
  nada. Dueño: `12/03`.

---

## 3. 📊 Los datos

### 3.1 Identificadores fijos

Los mismos en todos los documentos, para que un ejemplo del capítulo 2 se reconozca en el capítulo
11:

```text
Cliente    CLI-00311   (52 pedidos, España, alta en 2024)
Cliente    CLI-00007   (cliente sin pedidos: el caso del LEFT JOIN)
Producto   PRD-00017   (categoría 'audio', el más vendido)
Producto   PRD-04980   (inactivo: el caso del filtro que nadie recuerda)
Pedido     PED-00042   (3 líneas, estado PAGADO, el pedido de ejemplo de todo el corpus)
Pedido     PED-99999   (ANULADO, sin pagos: el caso del anti-join)
```

**Si un ejemplo necesita un identificador que no está en esta lista, se añade aquí primero.**

**Los nombres en Redis y en MongoDB**, fijados el 24 de septiembre de 2026 para `10/07` y los
bloques 07 y 08. Nacen del mismo identificador canónico, para que se reconozca el pedido en los tres
motores:

```text
Redis     pedido:PED-00042          cadena con el pedido en JSON, con caducidad
MongoDB   tienda.pedidos            colección; documento con _id "PED-00042" y sus líneas dentro
```

**Las claves de Redis del bloque 07**, fijadas el 26 de septiembre de 2026, una por estructura y
todas colgadas de un identificador canónico:

```text
vistas:PRD-00017      cadena usada como contador: visitas a la ficha del producto
carrito:CLI-00311     hash: producto -> cantidad, el carrito abierto del cliente
vistos:CLI-00311      lista acotada: los últimos productos que miró el cliente
categoria:audio       conjunto: los productos activos de la categoría de PRD-00017
ranking:ventas        conjunto ordenado: producto -> unidades vendidas
eventos:pedidos       stream: los cambios de estado de los pedidos
limite:CLI-00311      contador con caducidad: la limitación de tasa del cliente
stock:PRD-00017       cadena usada como contador: unidades que quedan por reservar
```

Los miembros de esas estructuras —qué productos hay en `categoria:audio`, quién encabeza
`ranking:ventas`— **salen de una consulta real a PostgreSQL**, nunca del texto, igual que los
conjuntos de abajo.

**Las colecciones de MongoDB del bloque 08**, fijadas el 27 de septiembre de 2026, en la base
`tienda`. Se cargan desde PostgreSQL con `mongoimport`, como en `l04`, y se borran al terminar:

```text
tienda.pedidos     _id "PED-00042"; cliente "CLI-26446", estado, total Decimal128, creado_en, lineas [...]
tienda.clientes    _id "CLI-00311"; nombre, email, pais, creado_en
tienda.productos   _id "PRD-00017"; nombre, categoria, precio Decimal128, activo
tienda.eventos     los eventos de pedido, uno por documento o en cubos por hora: _id "2025-02-21T03"
```

**Ninguno de los dos existe al levantar el entorno**: los crea el capítulo que los usa y los borra
al terminar —`DEL` en Redis, `drop` de la colección en MongoDB—, igual que un índice del bloque 03.

**Excepción: los conjuntos.** Hay ejemplos que no van sobre una fila sino sobre varias —un top-N por
grupo, un ranking, una ventana— y declarar aquí diez clientes para eso ensuciaría la lista sin ganar
nada. En ese caso **se acota por un rango anclado en un identificador canónico**, nunca nombrando
códigos nuevos como si fueran de ejemplo:

```sql
WHERE codigo BETWEEN 'CLI-00310' AND 'CLI-00319'   -- anclado en CLI-00311
WHERE codigo LIKE 'CLI-0031_'                      -- lo mismo, más corto
```

Los códigos concretos que aparezcan en la salida **salen de la salida real**, no del texto: el
lector los ve una vez y no tiene que recordarlos. Lo prohibido sigue siendo escribir *"el cliente
`CLI-04277`"* en la narrativa como si fuera un identificador del dominio.

### 3.2 Volúmenes

```text
clientes            50 000
productos            5 000
pedidos          1 000 000
pedido_lineas    3 500 000     (media de 3,5 líneas por pedido)
pagos              820 000     (los pedidos PENDIENTE y ANULADO no tienen pago)
eventos_pedido   4 100 000
```

El reparto por estado también es fijo, porque de él sale el recuento de `pagos`:

```text
PENDIENTE   120 000        ANULADO      60 000     -> 180 000 sin pago
PAGADO      250 000        ENVIADO     270 000
ENTREGADO   300 000                                -> 820 000 con pago
```

El millón de pedidos no es capricho. **Con mil filas `EXPLAIN` no enseña nada**, porque el
planificador elige `Seq Scan` siempre y con razón: leer la tabla entera es más barato que bajar por
el índice. Todo el bloque 03 se quedaría sin demostración.

### 3.3 Cómo se cargan

**El conjunto de datos se genera con script; no se versiona.** Un `.sql` de cuatro millones de filas
no entra en git.

```text
13-laboratorio/entorno/
├── docker-compose.yml       -- los cinco servicios, con healthcheck y versión fija
├── docker-compose.otros.yml -- los cinco motores del bloque 09 y de l05 (§4.5)
├── esquema.sql              -- el DDL de §2.1 (PostgreSQL) y los tres roles
├── semilla.sql              -- la carga determinista: generate_series + setseed
├── verificar.sql            -- las 22 comprobaciones de §3.1 y §3.2
├── exportar-csv.sql         -- vuelca las seis tablas a datos/*.csv
├── esquema-mysql.sql        -- el mismo esquema traducido (§2.3)
├── semilla-mysql.sql        -- LOAD DATA LOCAL INFILE de esos CSV
├── verificar-mysql.sql      -- las 22, más 4 propias de la importación
├── esquema-sqlite.sql       -- el mismo esquema en SQLite
├── semilla-sqlite.sql       -- .import de esos CSV, con tabla de paso
├── verificar-sqlite.sql     -- 17 comprobaciones
├── lenguajes/               -- un Dockerfile por lenguaje, con versiones fijas (§4.6)
├── codigo/                  -- el código del lector, NO se versiona (.gitignore)
└── datos/                   -- artefactos, NO se versionan (.gitignore)
    ├── *.csv                -- ~1 GB
    └── tienda.db            -- la base de SQLite, 855 MB
```

**PostgreSQL es la fuente; los demás motores importan de él, no generan.** Es una decisión
deliberada y conviene entender por qué, porque la alternativa parece más simple y no lo es:

- MySQL no tiene `generate_series` ni `setseed`, y SQLite tampoco. Una semilla equivalente en cada
  motor produciría **otros clientes, otros importes y otras cardinalidades**.
- Y entonces el contraste de dialecto de `02/08` —*"la misma consulta, los tres motores"*— estaría
  comparando tres conjuntos de datos distintos, y no demostraría nada.
- Exportando de PostgreSQL e importando, **los cuatro motores tienen exactamente las mismas filas,
  con los mismos `id`**. Lo único que cambia es el motor, que es justo lo que el corpus quiere
  aislar.

Las tres conversiones que hay que hacer en la exportación, y qué rompen si se olvidan:

| Tipo | Qué escribe PostgreSQL | Qué pasa si no se convierte |
|---|---|---|
| `timestamptz` | `2023-05-01 12:00:00+00` | El `TIMESTAMP` de MySQL no sabe leer el sufijo de zona |
| `boolean` | `t` / `f` | El `TINYINT(1)` guarda 0 en ambos: **todos los productos quedan inactivos** |
| `NULL` | campo vacío en CSV | 273 126 cadenas vacías chocando contra el `UNIQUE` de `pagos.referencia` |

Por eso la exportación usa `NULL '\N'` y castea `activo::int` y las marcas de tiempo a texto UTC.

La semilla es determinista: **misma semilla, mismos datos, mismos planes**. Se consigue fijando
`setseed()` antes de cualquier `random()`, y se declara en el propio script.

```sql
-- Extracto de semilla.sql: los pedidos.
SELECT setseed(0.42);                      -- determinismo: sin esto los planes no se reproducen

INSERT INTO pedidos (codigo, cliente_id, estado, total, creado_en)
SELECT
  'PED-' || CASE WHEN s.g < 100000 THEN lpad(s.g::text, 5, '0') ELSE s.g::text END,
  1 + (random() * 49999)::int,             -- reparto no uniforme: hay clientes con muchos pedidos
  CASE WHEN s.n <= 120000 THEN 'PENDIENTE'
       WHEN s.n <= 180000 THEN 'ANULADO'
       WHEN s.n <= 430000 THEN 'PAGADO'
       WHEN s.n <= 700000 THEN 'ENVIADO'
       ELSE                    'ENTREGADO' END,
  0,                                       -- el total se calcula después, desde las líneas
  timestamptz '2023-01-01' + (random() * 1000) * interval '1 day'
FROM (
  SELECT g, row_number() OVER (ORDER BY md5(g::text)) AS n
  FROM generate_series(1, 1000000) AS g
) AS s
ORDER BY s.g;
```

- `setseed(0.42)` fija el generador pseudoaleatorio de la sesión. Sin esta línea, cada carga produce
  datos distintos y **ningún plan pegado en el corpus sería reproducible**.
- **El `CASE` en lugar de un `lpad` a secas, porque `lpad` trunca.** `lpad('100000', 5, '0')`
  devuelve `'10000'`, no `'100000'`: si el texto ya es más largo que el ancho pedido, PostgreSQL
  **corta por la derecha** en vez de dejarlo como está. Con un millón de pedidos eso colisiona
  contra el `UNIQUE` de `codigo` en la fila 100 000. El ancho mínimo de cinco se conserva porque los
  identificadores canónicos de §3.1 —`PED-00042`, `PED-99999`— tienen cinco dígitos; de ahí en
  adelante el código crece de ancho. `clientes` y `productos` sí usan `lpad(…, 5, '0')` sin `CASE`,
  porque sus máximos —50 000 y 5 000— caben.
- **El estado no se sortea: se reparte por cupo exacto** sobre una mezcla determinista
  (`row_number() OVER (ORDER BY md5(g))`). Sorteado, los recuentos bailarían en cada carga y
  `verificar.sql` no podría comprobar nada. Repartido por cupo sobre el `id` a secas, el estado
  quedaría correlacionado con el orden físico de la tabla y falsearía los ejemplos de BRIN y de
  correlación del bloque 03. La mezcla por `md5` da las dos cosas: cupo exacto y sin correlación.
- `generate_series(1, 1000000)` es la fuente de filas: genera la serie de enteros del 1 al millón, y
  el `INSERT ... SELECT` la convierte en un millón de pedidos en una sola sentencia.
- **`ORDER BY s.g` no es cosmético.** Es lo que hace que la columna `id` de `IDENTITY` siga a la
  serie, y por tanto que `PED-00042` sea de verdad el pedido de `id` 42. Sin él, el orden de
  inserción no está garantizado y los identificadores canónicos dejan de coincidir.

Al terminar, **`verificar.sql` compara los recuentos con §3.2**. Si no cuadran, la carga se repite:
un corpus con datos distintos a los declarados es un corpus con planes que nadie puede reproducir.

---

## 4. 🐳 El entorno

### 4.1 Versiones fijas

**Verificadas el 2026-09-18** contra Docker Hub y la web de cada proyecto. **Nunca `latest`**: una
imagen móvil invalida todos los planes pegados en el corpus.

| Servicio | Imagen | Por qué esa |
|---|---|---|
| PostgreSQL | `postgres:18.6` | Última estable de la rama 18, que es la mayor vigente |
| MySQL | `mysql:9.7.2` | La LTS actual. 📝 La rama de innovación va por otra numeración; para el corpus manda la LTS |
| MariaDB | `mariadb:12.3.3` | La LTS actual |
| Redis | `redis:8.10.1` | Última estable |
| MongoDB | `mongo:8.0.20` | Rama 8.0, la mayor con más rodaje. 📝 Existe una 8.3 más nueva, y la 8.0 va por la 8.0.32: la 8.0.21 y posteriores no arrancan en el núcleo de Docker Desktop (ver abajo) |
| SQLite | `3.53.4` | No es contenedor: es el binario, y se declara la versión usada. Publicada el 2026-07-24; es la última |

> **📝 Por qué MongoDB 8.0.20 y no la última 8.0.** El 26 de septiembre de 2026 Docker Desktop
> pasó a 4.92.0, cuya máquina virtual trae el núcleo **7.0.12**. MongoDB se niega a arrancar con los
> núcleos de 6.19 a 7.0.13 —`MongoDB cannot start: Linux kernel versions 6.19 and newer has a known
> incompatibility`—, por un fallo de TCMalloc con `rseq` (SERVER-121912). Las imágenes de Docker Hub
> de **8.0.21 a 8.0.32 traen esa guarda**, incluso para `mongod --version`, y `GLIBC_TUNABLES` no la
> salta. **La 8.0.20 es la más reciente que arranca**, y se comprobó con carga: 200 000 documentos,
> índice, agregación y, en otra corrida, ocho clientes escribiendo a la vez durante un minuto —unos
> 8,8 millones de inserciones—, sin un solo error fatal. Se vuelve a la última 8.0 cuando Docker
> Desktop traiga un núcleo 7.0.14 o posterior, que MongoDB ya acepta.

> **📝 Contexto.** Mucha documentación y muchos artículos que el lector va a encontrar hablan de
> **MySQL 5.7 y 8.0**, que siguen siendo lo más desplegado en empresas. El corpus fija la LTS actual
> para los ejemplos, pero **cuando un comportamiento cambió entre 5.7/8.0 y hoy, se dice**: es
> exactamente el tipo de detalle que separa una respuesta actualizada de una recitada.

**Procedimiento para actualizar una versión**, obligatorio y sin atajos: se consulta la página
oficial de la imagen o del proyecto, se anota la fecha de verificación en el encabezado de este
documento, y **se vuelven a correr los capítulos cuyos planes puedan cambiar**. Una versión escrita
de memoria tiene la misma gravedad que una URL inventada.

### 4.2 Servicios, nombres y puertos

Nombres de contenedor, variables y puertos **en inglés**, como todo lo ejecutable del repositorio.
El esquema y los datos van en español (§3 de la guía de estilo).

```text
bd-lab-postgres   PostgreSQL 18.6    5432
bd-lab-mysql      MySQL 9.7.2        3306
bd-lab-maria      MariaDB 12.3.3     3307    -- puerto distinto: convive con MySQL
bd-lab-redis      Redis 8.10.1       6379
bd-lab-mongo      MongoDB 8.0.20    27017
                  SQLite 3.53.4      —       -- fichero tienda.db, sin servicio
```

Credenciales iguales en todos, porque es un lab local y esconderlas no enseña nada:

```text
base tienda · usuario tienda_app · contraseña tienda_app · superusuario postgres/root
```

El `compose` vive en `13-laboratorio/entorno/docker-compose.yml`, lo levanta `l00` y **cada servicio
lleva su `healthcheck`**, para que la carga no arranque contra un motor que todavía no acepta
conexiones. El teardown (`docker compose down -v`) se escribe **junto al recurso** en cada lab, no
al final de la serie.

### 4.3 Los parámetros de PostgreSQL que el `compose` fija

**Un motor con parámetros por defecto elige planes distintos en cada máquina**, y entonces los
planes pegados en el corpus dejan de ser comparables entre capítulos. El `compose` los fija:

```text
shared_buffers=256MB              effective_cache_size=1GB
work_mem=8MB                      maintenance_work_mem=256MB
random_page_cost=1.1              -- disco SSD: leer al azar cuesta casi lo mismo que en secuencia
max_parallel_workers_per_gather=0 -- paralelismo APAGADO por defecto
jit=off                           -- la compilación JIT mete ruido en los tiempos
track_io_timing=on                -- habilita los tiempos de E/S de EXPLAIN (ANALYZE, BUFFERS)
```

- **El paralelismo apagado es la decisión con más consecuencias.** Con `Gather` de por medio, el
  número de *workers* depende de los núcleos de la máquina y **ningún plan del corpus sería
  reproducible**. El mismo `SELECT` da `Parallel Seq Scan` en un portátil de ocho núcleos y `Seq
  Scan` en uno de dos. Apagado, todos ven el mismo árbol.
- **El capítulo que enseña consulta paralela lo enciende a la vista**, con un `SET
  max_parallel_workers_per_gather = 2;` pegado en la sesión, y lo vuelve a apagar al terminar. Es la
  única forma admitida de que aparezca un `Gather` en el corpus.
- `jit=off` por el mismo motivo: PostgreSQL activa la compilación JIT a partir de cierto coste
  estimado, y cuando lo hace los milisegundos se disparan por la compilación, no por la consulta.

> **⚠️ Advertencia.** Lo anterior fija **la forma del plan y las filas reales**, que son
> reproducibles en cualquier máquina. **No fija los milisegundos** de `actual time`: dependen del
> disco, de la memoria y del estado de la caché. Un tiempo que no reproduces no es un error del
> corpus. Los tiempos pegados vienen todos de la misma máquina, declarada una vez en el README de la
> raíz.

### 4.3.1 Lo que mueve `rows=` y `cost=` aunque nadie toque los datos

**Corregido el 23 de septiembre de 2026**, cuando el plan de `03/05` §2 dejó de reproducirse: la
estimación había pasado de 1 033 a 1 014 filas y el coste de 678 a 1 040, sin que cambiara una sola
fila. Las estimaciones y los costes dependen de tres cosas que el motor cambia solo:

| Qué | Quién lo cambia | Qué mueve en el plan | ¿Se puede devolver al estado declarado? |
|---|---|---|---|
| La muestra de `ANALYZE` —30 000 filas al azar— | `ANALYZE` a mano o el autoanalyze tras escrituras grandes | `rows=` y, con él, los costes | **No**: cada muestra es distinta |
| El mapa de visibilidad | `VACUUM` a mano o el autovacuum | El coste y los `Heap Fetches` de un *index-only scan* | Sí, vaciándolo |
| El tamaño de los índices | Toda escritura confirmada | El coste de recorrerlos | Sí, reconstruyéndolos |

- **El estado declarado** es el que deja `semilla.sql`: índices recién construidos, `pedidos` en
  10 770 páginas, `pedidos_pkey` en 21 MB y el mapa de visibilidad de `pedidos` vacío —`03/03` §6 lo
  enseña con `relallvisible = 0`—.
- **Se devuelve con tres sentencias**, desde `psql` como superusuario:

```sql
REINDEX TABLE pedidos;                                   -- índices a su tamaño de carga
CREATE EXTENSION pg_visibility;
SELECT pg_truncate_visibility_map('pedidos');            -- mapa de visibilidad vacío
DROP EXTENSION pg_visibility;
UPDATE pg_class SET relallvisible = 0 WHERE oid = 'pedidos'::regclass;
```

- **La muestra no se devuelve.** Por eso, al verificar un plan pegado, lo que tiene que coincidir es
  la **forma** —qué nodos, en qué orden, qué índice— y las **filas reales**; un `rows=` o un `cost=`
  que difieran por la muestra no son un error del corpus, y el plan se vuelve a pegar corrido de
  nuevo, no se ajusta a mano.
- **Toda tanda que confirme escrituras masivas o corra un `VACUUM`** comprueba al cerrar el tamaño
  de `pedidos_pkey` y el `relallvisible` de `pedidos`, y aplica lo de arriba si se movieron.

### 4.4 Colisiones de puerto

Los cinco puertos de §4.2 son los estándar de cada motor, y por eso **chocan con cualquier otro
proyecto que tenga ese motor levantado** en la misma máquina. El síntoma es literal:

```text
Error response from daemon: failed to set up container networking:
Bind for 0.0.0.0:6379 failed: port is already allocated
```

Se resuelve parando el otro contenedor, no cambiando el puerto del corpus: los puertos de §4.2 están
declarados y cada sesión pegada los usa.

```bash
docker ps --format '{{.Names}}	{{.Ports}}'   # quién tiene tomado el puerto
```

### 4.5 Los motores del bloque 09

Cassandra, Neo4j, TimescaleDB, OpenSearch y Qdrant **no están en el `compose` principal**: pesan
demasiado para levantarlos en cada sesión y solo hacen falta en el bloque 09 y en `l05`. Van en un
`docker-compose.otros.yml` con perfil propio.

**Verificadas el 2026-09-24** contra Docker Hub —las imágenes oficiales de cada proyecto—, al
adelantar T31 para `l05`. Viven en `13-laboratorio/entorno/docker-compose.otros.yml`, proyecto
`bd-lab-otros`, con el perfil `otros`:

| Servicio | Imagen | Puerto | Por qué esa |
|---|---|---|---|
| `bd-lab-cassandra` | `cassandra:5.0.9` | 9042 | Última estable; la 6.0 está en alfa |
| `bd-lab-neo4j` | `neo4j:5.26.31-community` | 7474, 7687 | La LTS de la rama 5. 📝 Existe la `2026.09.0`, de la numeración por calendario |
| `bd-lab-timescale` | `timescale/timescaledb-ha:pg18.6-ts2.30.1` | 5433 | PostgreSQL 18.6, el del corpus, con TimescaleDB 2.30.1 **y pgvector 0.8.6** en la misma imagen |
| `bd-lab-opensearch` | `opensearchproject/opensearch:3.8.0` | 9200 | Última estable, sin el complemento de seguridad |
| `bd-lab-qdrant` | `qdrant/qdrant:v1.19.1` | 6333 | Última estable |

- **pgvector va dentro del contenedor de TimescaleDB**: el temario lo pone en `l05` y la imagen
  `-ha` lo trae, así que no hace falta un sexto servicio. Se activa con `CREATE EXTENSION vector`.
- **Credenciales**: `postgres`/`postgres` en TimescaleDB, `neo4j`/`tienda_neo4j` en Neo4j —la imagen
  exige ocho caracteres—; Cassandra, OpenSearch y Qdrant, sin autenticación, como lab local.
- **Se levantan de uno en uno**, porque juntos piden varios GB de memoria:
  `docker compose -f docker-compose.otros.yml --profile otros up -d <servicio>`. El teardown es
  `… down -v`, que borra también sus volúmenes.


### 4.6 Los lenguajes de los bloques 10, 11 y 13

**Verificadas el 2026-09-23** contra Docker Hub, la web de cada lenguaje y el registro oficial de
cada biblioteca —Maven Central, PyPI, npm y el proxy de módulos de Go—. Cada lenguaje es un servicio
del `compose` con **perfil `lenguajes`**: `docker compose up -d` no los levanta, y se usan de uno en
uno con `docker compose run --rm`.

| Servicio | Imagen base | Por qué esa | Driver y *pool* |
|---|---|---|---|
| `java` | `eclipse-temurin:25.0.4_7-jdk`, con las dependencias resueltas por `maven:3.9.16-eclipse-temurin-25` | Java 25, la LTS vigente; la 26 no es LTS | pgjdbc 42.7.13 · HikariCP 7.1.0 · slf4j 2.0.20 · spring-jdbc 7.0.9 · Hibernate 7.4.10.Final · jOOQ 3.21.8 · MyBatis 3.5.19 · H2 2.5.250 · Derby 10.17.1.0 · Jedis 8.0.1 · mongodb-driver-sync 5.12.0 · Testcontainers 2.0.5, `testcontainers-postgresql` |
| `python` | `python:3.14.7` | Última estable | psycopg 3.3.6 · psycopg-pool 3.3.3 · SQLAlchemy 2.0.54 · redis-py 8.1.0 · pymongo 4.18.2 · testcontainers 4.15.0 |
| `node` | `node:24.21.0` | La LTS activa (Krypton); ejecuta TypeScript sin compilar | `pg` 8.23.0, con su `pg.Pool` · `pg-cursor` 2.22.0 · Kysely 0.29.6 · drizzle-orm 0.45.3 · `redis` 6.2.1 · `mongodb` 7.6.0 · `pg-copy-streams` 7.0.0 · `testcontainers` y `@testcontainers/postgresql` 12.1.0 |
| `go` | `golang:1.27.1` | Última estable | pgx 5.11.0, con `pgxpool` y `stdlib` · GORM 1.31.2 con su driver 1.6.3 · go-redis 9.22.0 · mongo-driver 2.9.1 · testcontainers-go y su módulo `postgres` 0.44.0 · `modernc.org/sqlite` 1.59.0 · la herramienta sqlc 1.31.1 |

- **Añadidas el 2026-09-24 para el bloque 11**, verificadas en los mismos registros:
  Testcontainers en los cuatro lenguajes, `pg-copy-streams` para el `COPY` de `pg` y
  `modernc.org/sqlite`, SQLite en Go puro, como base en memoria de las pruebas de `11/05`. Con
  testcontainers-go, `pgx` sigue en 5.11.0. Testcontainers necesita el socket de Docker, que **no
  se monta en el `compose`**: se pasa en la orden que lo usa, con `-v
  /var/run/docker.sock:/var/run/docker.sock -e TESTCONTAINERS_HOST_OVERRIDE=host.docker.internal`,
  como explica `11/05` §5.
- **Las versiones de Java viven en `lenguajes/java/pom.xml`**, que Maven resuelve con sus
  dependencias en una etapa previa de la construcción; la imagen final no lleva Maven. Spring,
  Hibernate, jOOQ y MyBatis se fijan en su última versión estable: los registros marcan como más
  reciente versiones preliminares —7.1.0-M2, 8.0.0.Beta2— que no se usan. **Derby está retirado**
  desde el 10 de octubre de 2025, y la 10.17.1.0 es su última versión.
- **Los cuatro montan `13-laboratorio/entorno/codigo/`**, que no se versiona: escribir ese código es
  el ejercicio del lector, igual que los `.sql` de comprobación. En Go se monta dentro del módulo de
  la imagen, para que `go run` encuentre su `go.mod`.
- **Se conectan como `tienda_app`**, el rol de la aplicación, por el nombre del servicio `postgres`
  dentro de la red del `compose`. Python, Node y Go leen `PGHOST`, `PGUSER`… del entorno; pgjdbc no
  las lee y necesita la URL `jdbc:postgresql://postgres:5432/tienda`.
- **Cómo se construyen y se usan:**

```bash
docker compose -f 13-laboratorio/entorno/docker-compose.yml --profile lenguajes build
docker compose -f 13-laboratorio/entorno/docker-compose.yml run --rm java java Pedido.java
```

- `--profile lenguajes build` construye las cuatro imágenes desde `lenguajes/<lenguaje>/Dockerfile`,
  que fijan la versión de la imagen y de cada biblioteca; la primera vez descarga las imágenes base.
- `run --rm java java Pedido.java` arranca un contenedor efímero del servicio `java`, ejecuta el
  fichero fuente sin compilarlo aparte y lo borra al terminar. Con `-e TZ=America/Bogota` se cambia
  la zona del proceso, que es como `10/03` saca a la luz las trampas de fechas.

> **⚠️ Advertencia.** `docker compose run` arranca también `postgres` por la dependencia, y **si la
> configuración del servicio cambió desde que se creó su contenedor, lo recrea**. Los datos viven en
> el volumen y no se pierden, pero el proceso se reinicia y los contadores de `pg_stat_*` vuelven a
> cero.

### 4.7 DynamoDB del bloque 07

**Verificadas el 2026-09-26** contra Docker Hub —las imágenes oficiales de AWS— y el historial de
versiones de DynamoDB Local en la documentación de AWS. Van en el `compose` principal con **perfil
`dynamodb`**: `docker compose up -d` no los levanta, y los cinco servicios del entorno no cambian.

| Servicio | Imagen | Puerto | Para qué |
|---|---|---|---|
| `bd-lab-dynamodb` | `amazon/dynamodb-local:3.3.1` | 8000 | DynamoDB en un contenedor, sin cuenta y sin coste; arranca con `-sharedDb -inMemory` |
| `aws` | `amazon/aws-cli:2.37.4` | — | La CLI de AWS, efímera como los lenguajes; `AWS_ENDPOINT_URL` la apunta al local |

- **En memoria**: parar `bd-lab-dynamodb` borra las tablas, y ese es su teardown. Credenciales y
  región —`tienda`, `us-east-1`— no se comprueban en local, pero la CLI las exige.
- **La CLI monta `datos/`** en `/datos`, para leer los lotes de carga que genera PostgreSQL.
- **Lo que DynamoDB Local no reproduce**, según su documentación: ignora la capacidad aprovisionada,
  no particiona la tabla y sus lecturas eventuales parecen fuertes por velocidad. **Sí calcula la
  capacidad consumida** que devuelve `--return-consumed-capacity`.

**Los nombres**, sobre el mismo dominio. La tabla se llama como la de PostgreSQL porque guarda los
mismos pedidos, con otro modelo:

```text
Tabla        pedidos
Partición    cliente         S   CLI-00311
Orden        fecha_pedido    S   2025-02-21T03:08:09Z#PED-00042   (marca UTC, almohadilla y código)
Atributos    codigo S · estado S · total N · lineas L de M {producto S, cantidad N, precio_unit N}
LSI          por-total       cliente + total, proyección ALL
GSI          por-estado      estado + fecha_pedido, proyección KEYS_ONLY
Datos        los pedidos de CLI-0031_ y PED-00042: 242 elementos
```

**La tabla única de `07/06`**, fijada el 27 de septiembre de 2026. Claves genéricas, porque cada
tipo de elemento las usa para una cosa:

```text
Tabla        tienda            PK S · SK S
Pedido       PK PEDIDO#PED-00042 · SK PEDIDO · codigo, estado, total N, creado
             GSI1PK CLIENTE#CLI-26446 · GSI1SK 2025-02-21T03:08:09Z#PED-00042
             pendiente_de CLIENTE#… solo mientras está PENDIENTE
Línea        PK PEDIDO#PED-00042 · SK LINEA#01 · producto PRD-01395, cantidad N, precio_unit N
GSI          gsi1              GSI1PK + GSI1SK                los pedidos de un cliente
GSI          por-producto      producto + PK                  los pedidos que llevan un producto
GSI          pendientes        pendiente_de + GSI1SK          disperso: los pendientes de un cliente
Datos        los pedidos de CLI-00311 y PED-00042, con sus 178 líneas: 231 elementos
```


### 4.8 Texto, vectores y series del bloque 09

**Fijado el 27 de septiembre de 2026**, antes de escribir `09/04`–`09/06`. Los productos se llaman
«Producto N» y no tienen texto que buscar, y §1 dice seis tablas: **el esquema no cambia**. El texto
se **genera** desde `productos` con una consulta determinista, y solo se guarda en los motores que
lo enseñan —el índice de OpenSearch, la colección de Qdrant, una tabla en `bd-lab-timescale`— o en
un esquema de prueba de `bd-lab-postgres` que se borra al terminar.

**La descripción de cada producto** sale de su `id` y su `categoria`: un sustantivo, un complemento
y una coletilla, elegidos por aritmética sobre el `id`. Las palabras llevan tildes y plurales a
propósito —`cámara`, `batería`, `auriculares`—, que es lo que `09/05` necesita:

```sql
WITH frases (categoria, sustantivos, complementos) AS (VALUES
  ('audio', ARRAY['auriculares inalámbricos', 'altavoz portátil', 'cascos con cancelación de ruido',
     'barra de sonido', 'micrófono de condensador'],
   ARRAY['con batería de larga duración', 'resistentes al agua', 'con sonido envolvente',
     'con conexión Bluetooth', 'con graves potentes']),
  ('informatica', ARRAY['portátil ligero', 'ratón ergonómico', 'teclado mecánico', 'monitor curvo',
     'disco sólido externo'],
   ARRAY['con pantalla de alta resolución', 'para programadores', 'con conexión USB-C',
     'silencioso', 'con retroiluminación']),
  ('video', ARRAY['cámara deportiva', 'televisor inteligente', 'proyector compacto',
     'cámara de vigilancia', 'consola de videojuegos'],
   ARRAY['con grabación en 4K', 'con visión nocturna', 'con mando a distancia',
     'con estabilizador de imagen', 'para el salón']),
  ('libros', ARRAY['novela histórica', 'guía de viajes', 'libro de cocina',
     'cómic de ciencia ficción', 'diccionario ilustrado'],
   ARRAY['en tapa dura', 'con ilustraciones a color', 'en edición de bolsillo',
     'para lectores jóvenes', 'en edición revisada']),
  ('juguetes', ARRAY['puzle de mil piezas', 'coche teledirigido', 'muñeca articulada',
     'juego de construcción', 'peluche gigante'],
   ARRAY['para niños de seis años', 'con pilas incluidas', 'de madera natural', 'educativo',
     'para toda la familia']),
  ('hogar', ARRAY['cafetera espresso', 'aspiradora sin cable', 'lámpara de escritorio',
     'sartén antiadherente', 'robot de cocina'],
   ARRAY['de bajo consumo', 'fácil de limpiar', 'con temporizador', 'de acero inoxidable',
     'de diseño compacto']),
  ('deporte', ARRAY['balón de fútbol', 'zapatillas de running', 'bicicleta estática',
     'raqueta de tenis', 'esterilla de yoga'],
   ARRAY['para entrenamiento diario', 'de uso profesional', 'para interior y exterior',
     'con garantía de dos años', 'de talla única']))
SELECT p.codigo, p.categoria,
       f.sustantivos[1 + p.id % 5] || ' ' || f.complementos[1 + (p.id / 5) % 5] || '. ' ||
       (ARRAY['Ideal para regalar.', 'Envío en 24 horas.', 'Oferta de temporada.',
              'Últimas unidades.'])[1 + (p.id / 25) % 4] AS descripcion
FROM productos p JOIN frases f USING (categoria)
ORDER BY p.id;
```

```text
Producto     PRD-00017 (audio): cascos con cancelación de ruido con conexión Bluetooth. Ideal para regalar.
Variedad     7 categorías × 5 × 5 × 4 = 700 combinaciones; salen 696 distintas en 5 000 productos
```

**Los embeddings** de esas descripciones se calculan con **Ollama 0.34.2** y el modelo
`nomic-embed-text` (digest `0a109f422b47`, 768 dimensiones), en el anfitrión y no en el `compose`:
es una herramienta auxiliar, como el cliente de SQLite, y el vector resultante se guarda en
`13-laboratorio/entorno/datos/vectores/`, que no se versiona. Quien no tenga ese modelo puede
seguir `09/06` con los vectores aleatorios de su §5, que no dependen de él.

**Las series temporales de `09/04`** son `eventos_pedido` copiada a `bd-lab-timescale`: tabla
`eventos` con `ocurrido_en`, `pedido_id` y `tipo`, la misma forma que en `l05` §5.

**Nombres fijos** en los motores:

```text
OpenSearch   índice   productos      codigo keyword · categoria keyword · descripcion text
Qdrant       colección productos     768 dimensiones, distancia Cosine, payload codigo y categoria
Timescale    tabla    eventos        hipertabla por ocurrido_en · tabla productos_vec (codigo, embedding vector(768))
PostgreSQL   esquema  texto          productos_texto (codigo, categoria, descripcion), se borra al terminar
```


### 4.9 Herramientas de migración del bloque 06

**Verificadas el 2026-09-27** contra Docker Hub y PyPI, antes de escribir `06/03`. No entran en el
`compose`: se usan en contenedores efímeros, contra la copia aislada, y se tiran al terminar.

| Herramienta | Versión | Cómo se usa |
|---|---|---|
| Flyway | `flyway/flyway:13.8.0`, la imagen oficial | `docker run --rm` en la red de la copia, con las migraciones montadas en `/flyway/sql` |
| Alembic | 1.20.0, con SQLAlchemy 2.0.54 y psycopg 3.3.6 | `pip install` en un `python:3.14.7` efímero, el mismo del servicio `python` de §4.6 |

- **Flyway 13.8.0 avisa de que MySQL 9.7 es más nuevo que la última versión con la que se verificó,
  la 9.4**, y funciona igual. El aviso sale en cada orden contra MySQL y se deja en las sesiones.
- **Nombres**: las tablas de ejemplo son `cupones_flyway` y `cupones_alembic`, para no chocar con
  `cupones` de `06/01`; las tablas de historial son las de cada herramienta, `flyway_schema_history`
  y `alembic_version`.

---

## 5. 💻 Convenciones de la sesión

Cómo se pega una sesión en un documento, para que todas se lean igual:

```text
tienda=#        PostgreSQL, usuario normal        tienda=>  sin privilegios
mysql>          MySQL o MariaDB                   sqlite>   SQLite
127.0.0.1:6379> Redis                             tienda>   mongosh
```

- **El prompt se conserva.** Es lo que dice en qué motor estás sin tener que leer el párrafo.
- **La salida se pega entera**, incluida la línea de recuento de filas y el tiempo cuando lo hay.
  Recortar un plan es quitarle la evidencia.
- **Dos sesiones se marcan `-- sesión A` y `-- sesión B`** y se ordenan en el tiempo, con `⏸` donde
  una se bloquea y `▶` donde continúa.
- **Los tiempos se pegan como salieron.** No se redondean a números bonitos ni se ajustan para que
  cuadre la narrativa. Si la máquina donde se corrió es relevante, se dice una vez en el README del
  bloque.

---

## 6. 🚫 Lo que está prohibido

- **`foo`, `bar`, `tabla1`, `mi_tabla`, `test`, `usuarios`** y cualquier nombre fuera de §2.
- **Un identificador de ejemplo que no esté en §3.1.**
- **`latest`** en cualquier imagen, y cualquier versión escrita sin verificar.
- **Un plan de `EXPLAIN` inventado, recortado o adaptado.**
- **Datos cargados sin `setseed`**, porque producen planes que nadie puede reproducir.
- **Crear un índice, una vista o un disparador sin declarar si se queda o se borra.**
- **Credenciales reales o nombres de sistemas de trabajo**, aunque sea en un comentario.
