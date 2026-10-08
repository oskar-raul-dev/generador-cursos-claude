# 03 — Mapeo de tipos

> La misma fila de `PED-00042` leída desde Java, Python, TypeScript y Go, y lo que cada driver
> entrega por cada columna: el dinero que llega como cadena, el entero de 64 bits que no cabe, la
> fecha que se desplaza cinco horas, el nulo que en un lenguaje es un cero y en otro un error. Es la
> lista de trampas por lenguaje, corrida. **Asume leído:**
> [`01`](01-el-driver-la-conexion-y-el-pool.md) —los drivers y los contenedores— y
> [`02/01`](../02-sql/01-familias-del-lenguaje-y-tipos.md), que es donde se elige el tipo de cada
> columna; aquí solo se ve cómo llega. **Vigencia:** 23 de septiembre de 2026.

---

## Salto rápido

- [1. El problema](#1--el-problema) · [2. La sonda](#2--la-sonda)
- [3. Lo que llega a cada lenguaje](#3-️-lo-que-llega-a-cada-lenguaje) · [4. Dinero y enteros
  grandes](#4--dinero-y-enteros-grandes)
- [5. Fechas y zonas](#5--fechas-y-zonas) · [6. Nulos, UUID, JSON y
  arrays](#6--nulos-uuid-json-y-arrays)
- [7. Estándar, motor y convención](#7--estándar-motor-y-convención) · [Errores
  frecuentes](#️-errores-frecuentes) · [Para profundizar](#-para-profundizar) ·
  [Preguntas](#-preguntas)

---

## 1. 🎯 El problema

Tres incidentes de la misma semana, en tres servicios que leen la misma tabla `pedidos`:

```text
El servicio en Node suma 10 € de envío al total, y el pedido muestra "3186.2310".
El informe de pedidos "de ayer" sale distinto desde el servicio Java y desde el de Python.
En Node, los pedidos creados a las 03:08 aparecen como creados a las 08:08.
```

Ninguno es un error de SQL: la consulta es correcta y los datos también. Es el **mapeo de tipos**:
lo que cada driver decide entregar a tu lenguaje por cada columna, y que casi nunca es lo que
esperabas en el caso raro. En Node, `total + 10` es una concatenación, porque `total` llega como
cadena. El informe depende de la zona horaria de la **sesión**, y un driver la cambia sin avisar. Y
una fecha sin zona se interpreta en la zona del proceso que la lee.

> **📝 Contexto.** Todo está **corrido** en los contenedores de lenguaje, y **con `TZ=America/Bogota`
> en el proceso**, cinco horas por detrás de UTC: con el proceso en UTC, las trampas de fechas no se
> ven, y en producción rara vez está en UTC el portátil de quien depura. El servidor sigue en
> `Etc/UTC`, que es su configuración de fábrica.

---

## 2. 🧱 La sonda

**Qué es:** una sola consulta que devuelve, para `PED-00042`, una columna de cada tipo con trampa.
La misma en los cuatro lenguajes, leída de un fichero:

```sql
SELECT p.total, p.id,
       (SELECT count(*) FROM pedido_lineas l WHERE l.pedido_id = p.id) AS lineas,
       p.creado_en, p.creado_en::timestamp AS sin_zona, p.actualizado_en, NULL::bigint AS nulo,
       md5(p.codigo)::uuid AS ref,
       (SELECT e.carga FROM eventos_pedido e WHERE e.pedido_id = p.id ORDER BY e.id LIMIT 1) AS carga,
       (SELECT array_agg(l.cantidad ORDER BY l.linea) FROM pedido_lineas l WHERE l.pedido_id = p.id) AS cantidades
  FROM pedidos p WHERE p.codigo = $1
```

- **`total`** es `numeric(12,2)`; **`id`** y **`lineas`**, `bigint` —`count(*)` siempre devuelve
  `bigint`—; **`creado_en`**, `timestamptz`, y **`sin_zona`**, la misma fecha convertida a
  `timestamp` sin zona **en la zona de la sesión**.
- **`actualizado_en`** es nulo en este pedido, y **`nulo`** es un `bigint` nulo a propósito.
- **`ref`** es un `uuid` derivado del código, para que salga igual en cada corrida; **`carga`**, el
  primer evento del pedido en `jsonb`; y **`cantidades`**, un *array* de `integer`.

Desde `psql`, en la zona del servidor, así se ve la fila —es la referencia contra la que comparar—:

```text
total          | 3186.23
id             | 42
lineas         | 3
creado_en      | 2025-02-21 03:08:09.349067+00
sin_zona       | 2025-02-21 03:08:09.349067
actualizado_en |
ref            | 4cc23f8e-4baf-a114-cbd3-e8cad657270b
carga          | {"estado": "PAGADO", "origen": "web", "importe": 3186.23, "version": 2}
cantidades     | {1,5,3}
```

---

## 3. ⚖️ Lo que llega a cada lenguaje

Cada programa imprime, por columna, el tipo que eligió el driver y el valor. Salida literal de los
cuatro:

```text
-- Java, pgjdbc, con getObject()
total        java.math.BigDecimal         3186.23
id           java.lang.Long               42
lineas       java.lang.Long               3
creado_en    java.sql.Timestamp           2025-02-20 22:08:09.349067
sin_zona     java.sql.Timestamp           2025-02-20 22:08:09.349067
actualizado_en null                         null
nulo         null                         null
ref          java.util.UUID               4cc23f8e-4baf-a114-cbd3-e8cad657270b
carga        org.postgresql.util.PGobject {"estado": "PAGADO", "origen": "web", "importe": 3186.23, "version": 2}
cantidades   org.postgresql.jdbc.PgArray  {1,5,3}
```

```text
-- Python, psycopg
total        Decimal      Decimal('3186.23')
id           int          42
lineas       int          3
creado_en    datetime     datetime.datetime(2025, 2, 21, 3, 8, 9, 349067, tzinfo=zoneinfo.ZoneInfo(key='Etc/UTC'))
sin_zona     datetime     datetime.datetime(2025, 2, 21, 3, 8, 9, 349067)
actualizado_en NoneType     None
nulo         NoneType     None
ref          UUID         UUID('4cc23f8e-4baf-a114-cbd3-e8cad657270b')
carga        dict         {'estado': 'PAGADO', 'origen': 'web', 'importe': 3186.23, 'version': 2}
cantidades   list         [1, 5, 3]
```

```text
-- TypeScript, pg
total        string/String    "3186.23"
id           string/String    "42"
lineas       string/String    "3"
creado_en    object/Date      2025-02-21T03:08:09.349Z
sin_zona     object/Date      2025-02-21T08:08:09.349Z
actualizado_en null             null
nulo         null             null
ref          string/String    "4cc23f8e-4baf-a114-cbd3-e8cad657270b"
carga        object/Object    {"estado":"PAGADO","origen":"web","importe":3186.23,"version":2}
cantidades   object/Array     [1,5,3]
```

```text
-- Go, pgx, con rows.Values()
total        pgtype.Numeric           {318623 -2 false finite true}
id           int64                    42
lineas       int64                    3
creado_en    time.Time                2025-02-20 22:08:09.349067 -0500 -05
sin_zona     time.Time                2025-02-21 03:08:09.349067 +0000 UTC
actualizado_en <nil>                    <nil>
nulo         <nil>                    <nil>
ref          [16]uint8                [76 194 63 142 75 175 161 20 203 211 232 202 214 87 39 11]
carga        map[string]interface {}  map[estado:PAGADO importe:3186.23 origen:web version:2]
cantidades   []interface {}           [1 5 3]
```

El resumen, que es la tabla que conviene tener en la cabeza:

| Columna | Java | Python | TypeScript | Go |
|---|---|---|---|---|
| `numeric` | `BigDecimal` | `Decimal` | **`string`** | **`pgtype.Numeric`** |
| `bigint` | `Long` | `int` | **`string`** | `int64` |
| `timestamptz` | `Timestamp`, en la zona de la JVM | `datetime` con zona | `Date`, **sin microsegundos** | `time.Time`, en la zona del proceso |
| `timestamp` | `Timestamp` | `datetime` sin zona | `Date`, **leída como hora local** | `time.Time` marcado UTC |
| `uuid` | `UUID` | `UUID` | `string` | **`[16]uint8`** |
| `jsonb` | **`PGobject`**, texto sin analizar | `dict` | objeto | `map[string]any` |
| *array* | **`PgArray`** | `list` | `Array` | `[]any` |

**Quién lo manda:** **driver**, entero. El motor manda cada valor con su tipo —el OID de `pg_type`:
20 es `int8`, 1700 `numeric`, 1184 `timestamptz`— y el driver decide a qué lo convierte. Por eso la
misma fila, del mismo motor, llega como cuatro cosas distintas.

---

## 4. 🩺 Dinero y enteros grandes

**Qué es:** los dos tipos que un lenguaje no puede representar sin perder algo, y la decisión que
toma cada driver para no perderlo.

- **Java y Python convierten a un decimal exacto**: `BigDecimal` y `Decimal`. `3186.23` es
  exactamente `3186.23`, y la suma de envíos no pierde un céntimo.
- **Node lo entrega como cadena**, y no es un descuido: el único número de JavaScript es de coma
  flotante de 64 bits, que no representa `0.1` exacto ni enteros por encima de 2⁵³. `pg` prefiere
  darte el texto antes que un valor equivocado. El precio es el incidente de §1: `"3186.23" + 10` es
  `"3186.2310"`, porque `+` con una cadena concatena.
- **Lo mismo con `bigint`**, y con todo `count(*)`, que es `bigint`: `"42"` y `"3"` son cadenas. Un
  `if (lineas > 2)` funciona por conversión implícita; un `lineas + 1` concatena.
- **Go no elige**: `pgtype.Numeric` guarda el entero y el exponente —`{318623 -2 …}` es 318 623 ×
  10⁻²— y te deja escanearlo al tipo que tú declares. Si escaneas a `float64`, la pérdida es tuya.

La corrección en Node es decirle al driver qué hacer con cada OID. Corrida:

```typescript
// Los OID de los tipos, del catálogo pg_type: 20 = int8, 1114 = timestamp sin zona
pg.types.setTypeParser(20, (texto) => BigInt(texto));         // entero de 64 bits sin perder nada
pg.types.setTypeParser(1114, (texto) => texto);               // sin zona: se deja como texto
```

```text
bigint 42n | string 2025-02-21 03:08:09.349067 | string 3186.23
```

- **`BigInt` para los enteros** conserva el valor exacto, a cambio de que no se mezcla con `number`
  sin convertir. Para `numeric`, lo sensato es dejarlo en texto y operar con una biblioteca decimal,
  o hacer la aritmética del dinero **en la base**.
- **El JSON tiene su propia trampa**: el `importe` de `carga` llega como `3186.23` en coma flotante
  en Python, en TypeScript y en Go, porque un número JSON se analiza como flotante. En `jsonb` los
  importes van como texto, o se leen con un analizador que devuelva decimales.

**Cuánto cuesta equivocarse:** céntimos que no cuadran en la conciliación, identificadores de más de
2⁵³ que se redondean y apuntan a otra fila. **Cuándo se nota:** tarde, con datos reales.

> **Veredicto:** el dinero se lee a un decimal exacto o se deja en texto; nunca a coma flotante. Si
> el lenguaje no tiene decimal, la aritmética se hace en SQL, donde `numeric` sí lo es.

---

## 5. 🩺 Fechas y zonas

**Qué es:** la fuente más cara de errores del bloque, porque **en `timestamptz` el motor guarda un
instante**, y cada driver decide en qué zona te lo enseña; y **en `timestamp` guarda una hora de
reloj sin zona**, y cada driver decide qué zona suponerle.

Lo que se ve en las salidas de §3, con el proceso en Bogotá:

- **Python** devuelve `creado_en` como `datetime` **con zona** —`Etc/UTC`, la de la sesión—, que es
  el mismo instante escrito en UTC; y `sin_zona` como `datetime` **sin zona**, las 03:08 tal cual.
- **Go** devuelve `creado_en` en la **zona del proceso**, `22:08 -0500`: el mismo instante, bien. Y
  `sin_zona` marcado como UTC, que no es una zona: es una etiqueta puesta a una hora que no la
  tenía.
- **Node** devuelve `creado_en` como `Date`, el mismo instante pero **sin microsegundos**: `.349Z`
  donde había `.349067`. Y **`sin_zona` desplazado cinco horas**, `08:08Z`: `pg` interpreta un
  `timestamp` como hora local del proceso y lo convierte a instante. Es el tercer incidente de §1.
- **Java** enseña las dos columnas a las **22:08**, y la segunda es la sorpresa: `sin_zona` no
  debería haber cambiado. La causa se ve preguntando a la sesión:

```text
$ docker compose run --rm -e TZ=America/Bogota java java Zona.java
TimeZone de la sesión: America/Bogota
$ docker compose run --rm java java Zona.java
TimeZone de la sesión: Etc/UTC
$ docker compose run --rm -e TZ=America/Bogota python python -c \
    "import psycopg; print('psycopg:', psycopg.connect('').execute('SHOW timezone').fetchone()[0])"
psycopg: Etc/UTC
```

- **pgjdbc fija la zona de la sesión con la de la JVM al conectar**, y psycopg no toca la del
  servidor. La conversión `creado_en::timestamp` la hace **el servidor, en la zona de la sesión**,
  así que la misma consulta da las 22:08 desde Java y las 03:08 desde Python. Y con ella, cualquier
  `::date`, cualquier `date_trunc('day', …)` y cualquier «pedidos de ayer»: es el segundo incidente
  de §1.
- **La forma segura en Java** es pedir el tipo exacto: `getObject(…, OffsetDateTime.class)` devolvió
  `2025-02-21T03:08:09.349067Z`, en UTC siempre, como dice la documentación del driver.

**Quién lo manda:** **motor** para la diferencia entre `timestamptz` y `timestamp`, y para hacer las
conversiones en la zona de la sesión; **driver** para la zona que fija al conectar y para cómo
entrega cada valor. **Cuánto cuesta:** informes que no cuadran entre servicios y eventos con la hora
equivocada, sin un solo error en ningún log.

> **⚠️ Advertencia.** Un informe que agrupa por día tiene que **fijar la zona en la consulta** —`AT
> TIME ZONE 'America/Bogota'`— o en la sesión, a propósito. Dejar que la decida el driver es dejar
> que la decida la configuración de la máquina donde corre el servicio. Qué columna usar para cada
> caso horario es una decisión de diseño, del bloque 12, que lista el [README de la
> raíz](../README.md).

---

## 6. 🧱 Nulos, UUID, JSON y *arrays*

**Los nulos**, que cada lenguaje resuelve a su manera, y dos de las cuatro son trampas:

```text
-- Java
getLong(nulo)             0  wasNull=true
-- Go
Scan(NULL) en int64: can't scan into dest[0] (col: int8): cannot scan NULL into *int64
Scan(NULL) en *int64: <nil> <nil>
```

- **En Java, `getLong` sobre un nulo devuelve 0**: los tipos primitivos no pueden ser nulos, y el
  driver solo lo avisa si preguntas después con `wasNull()`. Un saldo nulo leído así es un saldo
  cero. Se evita pidiendo el objeto —`getObject(…, Long.class)`— que sí puede ser `null`.
- **En Go, escanear un nulo a `int64` es un error**, no un cero, y es la opción más segura de las
  cuatro: te obliga a declarar un puntero —`*int64`— o un tipo que admita nulo.
- **Python y TypeScript** devuelven `None` y `null`, y la trampa pasa al código que los usa.

**El UUID** llega como tipo propio en Java y en Python, como cadena en TypeScript, y como **16
bytes** en Go, `[16]uint8`, que se imprime ilegible: se escanea a `pgtype.UUID` o a `string` para
tener el texto de siempre. **El JSON** llega ya analizado en Python, TypeScript y Go, y como
**`PGobject`** en Java, que es el texto sin analizar: hay que pasarlo por un analizador de JSON.
**El *array*** llega como lista en tres lenguajes y como **`PgArray`** en Java, que se convierte con
`getArray()`.

**Quién lo manda:** **driver** para todo, y **lenguaje** para lo que puede ser nulo. **Cuánto
cuesta:** en Java, datos silenciosamente falsos; en Go, un error en producción la primera vez que la
columna trae un nulo que nadie había visto en pruebas.

> **Veredicto:** por cada columna que puede ser nula, el tipo de tu lenguaje también tiene que poder
> serlo. Si no, el nulo se convierte en un cero o en un error, y los dos llegan tarde.

---

## 7. 📜 Estándar, motor y convención

> **📜 Estándar o motor.** ISO/IEC 9075 es de pago y **no he verificado sus cláusulas**. Define los
> tipos de columna —`NUMERIC`, `BIGINT`, `TIMESTAMP WITH TIME ZONE`— y no dice nada de cómo llegan a
> un lenguaje: eso lo decide cada driver, y en Java en parte la especificación JDBC.

| Afirmación | Estándar | PostgreSQL 18.6 | Drivers del corpus |
|---|---|---|---|
| `TIMESTAMP` y `TIMESTAMP WITH TIME ZONE` son tipos distintos | Sí | Sí: `timestamp` y `timestamptz` | Cada uno los entrega distinto |
| `timestamptz` guarda la zona que se le dio | No | **No**: guarda un instante en UTC | — |
| Las conversiones usan la zona de la sesión | — | Sí, `TimeZone` | pgjdbc la fija con la de la JVM; los otros tres, no |
| `count(*)` devuelve `BIGINT` | No verificado | Sí | Cadena en `pg`, entero en los demás |
| `numeric` llega exacto | — | Sí, se transmite como texto o binario exacto | Sí en Java y Python; cadena en `pg`; `pgtype.Numeric` en pgx |
| Un nulo puede llegar a cualquier tipo | Sí | Sí | Java da 0 en primitivos; Go da error en no punteros |

**Convención, las dos que más se repiten.** *«`timestamptz` guarda la zona horaria»* — guarda un
instante; la zona con que se escribió se pierde, y la que ves al leer es la de la sesión o la del
driver. Y *«el driver ya convierte los tipos bien»* — convierte a lo que cabe en tu lenguaje, que en
JavaScript es una cadena para el dinero y una hora local para cualquier fecha sin zona.

---

## ⚠️ Errores frecuentes

| Se dice | Lo preciso |
|---|---|
| "En Node, `total + 10` suma" | `total` llega como cadena y `+` concatena: `"3186.2310"` |
| "`count(*)` es un número" | Es `bigint`, y en `pg` llega como cadena |
| "Un `timestamp` sin zona se lee igual en todas partes" | `pg` lo interpreta en la zona del proceso: salió desplazado cinco horas |
| "La zona de la sesión es la del servidor" | pgjdbc la cambia a la de la JVM al conectar; psycopg la deja |
| "`getLong` de una columna nula devuelve `null`" | Devuelve 0. Solo `wasNull()` o `getObject` dicen la verdad |
| "`Date` de JavaScript guarda la fecha exacta" | Guarda milisegundos: los microsegundos de PostgreSQL se pierden |
| "Si el JSON es `jsonb`, los importes son exactos" | Al analizarlo en el lenguaje, un número JSON es coma flotante |

---

## 📚 Para profundizar

- **Documentación** — PostgreSQL 18, «Data Types»: los tipos del motor, `timestamptz` incluido.
  <https://www.postgresql.org/docs/18/datatype.html>
- **Documentación** — pgjdbc, «Issuing a Query and Processing the Result»: la tabla de tipos de
  fecha de Java 8 y por qué `OffsetDateTime` sale en UTC.
  <https://jdbc.postgresql.org/documentation/query/>
- **Documentación** — psycopg 3, «Adapting basic Python types»: qué tipo de Python sale de cada tipo
  de PostgreSQL. <https://www.psycopg.org/psycopg3/docs/basic/adapt.html>
- **Documentación** — node-postgres, «Data Types»: las conversiones por defecto y cómo cambiarlas
  con `setTypeParser`. <https://node-postgres.com/features/types>
- **Documentación** — pgx, «pgtype»: los tipos de PostgreSQL en Go, `Numeric` y `UUID` incluidos.
  <https://pkg.go.dev/github.com/jackc/pgx/v5/pgtype>

---

## 🧠 Preguntas

1. ¿Qué tipo de TypeScript entrega `pg` para una columna `numeric`, y por qué? 🟢
2. ¿Qué devuelve `getLong` de JDBC cuando la columna es nula? 🟢
3. ¿Qué tipo de Go entrega pgx para un `uuid` si lo lees con `rows.Values()`? 🟢
4. ¿Qué guarda de verdad una columna `timestamptz`? 🟢
5. ¿Qué tipo tiene el resultado de `count(*)` en PostgreSQL, y cómo llega a cada uno de los cuatro
   lenguajes? 🟢
6. Distingue `timestamp` de `timestamptz`: qué guarda cada uno y qué hace el driver al leerlo. 🟡
7. ¿La conversión de un `timestamptz` a fecha la hace el motor o el driver, y en qué zona? 🟡
8. ¿Está en el estándar SQL cómo llega un `NUMERIC` a Java o a Python? Responde para la norma, para
   JDBC y para los otros drivers. 🟡
9. Diferencia lo que hacen Java y Go cuando leen un nulo en un tipo que no admite nulos. 🟡
10. Un informe de «pedidos de ayer» da cifras distintas desde un servicio Java y desde uno Python
    contra la misma base. Explica el mecanismo y dos formas de corregirlo. 🟠
11. En Node, un pedido creado a las 03:08 aparece a las 08:08. Da la causa exacta y la corrección
    con su código. 🟠
12. ¿Por qué `pg` entrega el dinero como cadena y no como número, y qué harías en un servicio Node
    que tiene que sumar importes? 🟠
13. Un importe guardado dentro de un `jsonb` aparece con un céntimo de diferencia en un informe.
    ¿Dónde se pierde, y cómo lo evitas? 🟠
14. ¿Qué se pierde al leer un `timestamptz` en un `Date` de JavaScript, y cuándo importa? 🟠
15. En Java, ¿qué tipo pedirías para leer un `timestamptz` sin depender de la zona de la JVM, y qué
    zona trae el valor? 🟠
16. Escribe el fragmento que lee `actualizado_en`, que puede ser nulo, en el lenguaje que prefieras,
    sin que un nulo se convierta en un valor por defecto. 🔴
17. Diseña la configuración de tipos de un servicio en Node que lee pedidos —dinero, identificadores
    y fechas— para que ningún valor se pierda ni se desplace, y di qué OID tocas. 🔴
18. Diagnostica: tras migrar un servicio de Python a Java, los totales diarios del panel cambian a
    partir de las 19:00 de cada día. Da la hipótesis más probable, la consulta que la confirma y la
    corrección. 🔴

---

**Anterior:** [`02`](02-parametrizadas-e-inyeccion.md) — el parámetro y la inyección ·
**Siguiente:** [`04`](04-transacciones-y-resultados-grandes.md) — transacciones y resultados grandes
· **Relacionado:** [`02/01`](../02-sql/01-familias-del-lenguaje-y-tipos.md) — el tipo de cada
columna, que aquí se lee ·
[`01/06`](../01-fundamentos-y-modelo-relacional/06-nulos-y-logica-de-tres-valores.md) — el nulo en
el motor, antes de llegar al lenguaje.
