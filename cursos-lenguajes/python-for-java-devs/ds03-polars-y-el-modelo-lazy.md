# 🦆 ds03 — Polars, DuckDB y el modelo lazy

> Python para desarrolladores Java senior · Track `ds` · sección 3 de 9
> Depende de: `ds01`, `ds02`, Fase 11 (SQL) · Habilita: `ds04`
> Registro de esta sección: script — un archivo por informe, ejecutado a mano
> Proyecto que avanza: Embudo — nace el consolidado mensual de las diez sedes

---

## 🎯 1. Propósito

`ds02` terminó con dos números incómodos: el proceso pesaba 77 MB antes de leer un dato, y
el informe cargaba ochenta y un mil filas en memoria para producir veinte. La pregunta que
quedó abierta es de las buenas: **¿por qué el motor no mira la consulta entera antes de
empezar a leer?** Tu base de datos lo hace desde siempre. Se llama plan de ejecución, y
llevas once años leyéndolos.

Esta sección trae los dos motores que traen ese plan a los archivos —**Polars** en modo
perezoso y **DuckDB** sobre Parquet—, los pone a competir con pandas y con el bucle a mano
de la biblioteca estándar, y publica la conclusión con la que el track se juega su
credibilidad: **a la escala real de Áurea, el bucle a mano gana**.

> 🧭 **La pregunta que ordena la sección: ¿cuántas veces al día se responde esta pregunta?**
> Si es una al mes, el arranque de la dependencia pesa más que la consulta y el ganador es
> el que no tiene dependencias. Si es mil al día con el proceso ya caliente, el orden se da
> vuelta entero. Es la misma pregunta de `ds01` —*¿cuántas cuentas voy a hacer con esta
> carga?*— un nivel más arriba.

---

## ✅ 2. Qué queda listo al terminar

- [ ] `consolidation.py` produce el consolidado mensual por sede en **cinco motores** que
      devuelven exactamente la misma lista de tuplas, con la prueba que lo comprueba.
- [ ] Sabes leer un plan de Polars con `.explain()` y señalar dónde bajó la proyección y
      dónde bajó el filtro.
- [ ] Tus cuatro tablas están en Parquet y sabes cuánto ocupan comparadas con el CSV.
- [ ] `bench_engines.py` y `bench_punta_a_punta.py` producen las dos tablas de la sección 6
      en tu máquina, y entiendes por qué son dos y no una.
- [ ] Puedes decir, con el número al lado, a partir de cuántas filas deja de ganar el bucle.
- [ ] Sabes por qué la cifra de DuckDB cambia según qué **otras** bibliotecas tengas
      instaladas, y cómo se mide para que no cambie.
- [ ] El miniproyecto de la sección 7 corre y cumple sus criterios de aceptación.

---

## 🚫 3. Qué NO entra todavía

- **La atribución y las series temporales** → `ds04`, que es el proyecto Embudo completo.
- **Gráficos** → `ds05`.
- **Polars en modo ansioso (`pl.read_csv`)** → aparece una vez, para contrastar con
  `scan_csv`, y no se usa más. El modo perezoso es el tema.
- **DuckDB como base de datos persistente** —con su archivo, sus tablas y sus índices— →
  fuera del curso. Aquí se usa como motor de consulta sobre archivos, que es su papel en un
  análisis. Si el dato necesita vivir en una base, la respuesta es el Postgres de la Fase 11.
- **`read_sql` contra Postgres** → el ejercicio 22 lo mide contra estas cuatro filas. No
  entra a la tabla principal porque necesita un servicio corriendo y el resto de la sección
  no necesita nada.
- **Spark, Dask, Ray y la computación distribuida** → fuera del curso, y la razón es la
  tabla de la sección 6: a la escala de Áurea, un portátil sobra. Cuando alguien te proponga
  un clúster, esa tabla es la respuesta.

---

## 🧠 4. Concepto mínimo

### El problema, antes de la herramienta

El consolidado mensual de las diez sedes es lo primero que Marcela abre cada mes: una fila
por sede y por mes, con gasto de pauta, leads, planes aceptados, valor contratado y
**cobrado de verdad**. Cinco cifras que viven en cuatro archivos con granularidades
distintas, y un `join` que no se puede evitar —las cuotas no saben en qué sede se firmó el
plan—.

Escrito con el `csv` de la Fase 06 son veintiocho líneas y funcionan. Escrito en pandas son
veinticinco. En SQL sobre DuckDB, treinta y tres contando la consulta. **Ninguno de los
cuatro es notablemente más corto que los otros**, y esa es la primera sorpresa de la
sección: la diferencia no va a estar en las líneas.

### Qué significa "perezoso" aquí, y qué no

Un `Stream` de Java es perezoso: nada pasa hasta la operación terminal. Eso ya lo sabes, y
por eso el instinto va a fallar — porque **es perezoso de otra manera**.

```python
import polars as pl

spend = (pl.scan_csv("pauta.csv")              # no lee nada
         .select(sede=pl.col("sede"), costo=pl.col("costo_cop"))
         .group_by("sede").agg(pl.col("costo").sum()))
print(spend.explain())                          # el plan, antes de ejecutar
result = spend.collect()                        # aquí, por fin, se lee el archivo
```

La diferencia con el `Stream` es de naturaleza, no de grado. Un `Stream` difiere la
ejecución **elemento a elemento** y respeta el orden en que escribiste las operaciones:
nadie reordena tu `filter`, nadie decide no leer un campo. `scan_csv` construye un **plan
declarativo** que un optimizador reescribe entero antes de tocar el disco, y que hace tres
cosas que ningún `Stream` hace:

- **Bajar la proyección** (*projection pushdown*): de las ocho columnas de `pauta.csv` solo
  se leen las dos que el plan usa. Las otras seis no se parsean.
- **Bajar el filtro** (*predicate pushdown*): un `filter` escrito al final se ejecuta al
  leer, y en Parquet ni siquiera se leen los bloques cuyas estadísticas dicen que no pueden
  contener nada.
- **Reordenar y fusionar**: dos agrupaciones sobre la misma fuente pueden convertirse en una
  sola pasada.

Es, punto por punto, lo que hace el planificador de Postgres cuando lees un `EXPLAIN`. **El
modelo mental correcto no es "streams perezosos", es "una base de datos sin base de
datos".**

### Parquet: el formato es la mitad de la historia

Un CSV es texto plano por filas y no sabe nada de sí mismo: para saber qué hay en la columna
`costo_cop` hay que leer y parsear el archivo entero. Parquet guarda **cada columna por
separado**, con su tipo escrito, comprimida, y con estadísticas por bloque —mínimo, máximo,
cuántos nulos—. Las tres propiedades juntas son lo que permite no leer.

Sobre los datos de Áurea, la conversión pesa esto:

```
      mes:     11.116 filas · CSV     0,6 MB · Parquet  0,03 MB (24× más chico)
       e1:    298.581 filas · CSV    15,9 MB · Parquet   0,7 MB (24× más chico)
      e16:  4.200.081 filas · CSV   206,9 MB · Parquet   4,9 MB (42× más chico)
```

Veinticuatro veces más chico no es magia de compresión general: es que una columna de
identificadores `TP000123` comprime como un sueño cuando está sola y comprime mal cuando
está intercalada con fechas y números, que es exactamente lo que hace un CSV.

> ⚠️ **Y el costo, que casi nadie publica:** convertir esas mismas tablas a Parquet cuesta
> entre **222 y 431 ms** según el tamaño. Si conviertes cada vez que vas a consultar, acabas
> de perder la partida antes de empezar. Parquet paga cuando se escribe una vez y se lee
> muchas — que es, otra vez, la pregunta de `ds01` con otro disfraz.

### Tu instinto de Java dice… y esta vez se equivoca

Tu instinto dice **"esto ya lo tengo: `Stream` es perezoso y yo escribo *streams* desde
Java 8"**. Y la parte que se transfiere es real: la operación terminal, el no materializar
intermedios, el encadenar transformaciones. Hasta ahí el paralelo funciona.

Donde se rompe es en quién manda. En un `Stream` mandas tú: el orden de las operaciones es
el orden de ejecución, y si pones el `filter` al final, se ejecuta al final.

```java
// El orden es el que escribiste. Nadie lo mejora.
rows.stream().map(this::parse).filter(r -> r.branch().equals("Centro")).toList();
```

```python
# El orden es una sugerencia. El optimizador baja el filtro hasta la lectura.
pl.scan_csv("pauta.csv").with_columns(...).filter(pl.col("sede") == "Centro")
```

Y hay un segundo instinto, más peligroso porque también viene de la JVM: **"perezoso =
lazy loading = N+1"**. En Hibernate, lo perezoso es una promesa de ir a buscar cada cosa
cuando se toque, y eso produce el desastre que ya conoces. Aquí es lo contrario: perezoso
significa **acumular la consulta completa para ir al disco una sola vez y mejor**. Si
traduces "lazy" por lo que significa en tu ORM, vas a desconfiar de lo que deberías usar.

### Esto sí funciona igual

- **El SQL.** El de DuckDB es SQL de verdad: CTEs, `FULL JOIN ... USING`, funciones de
  ventana. Lo que sabes se aplica sin traducción, y esa es su mayor ventaja para este
  perfil.
- **Leer un plan de ejecución.** `.explain()` de Polars y `EXPLAIN` de DuckDB se leen como
  el de Postgres: de adentro hacia afuera, buscando dónde se materializa algo grande.
- **Filtrar y agregar temprano.** La regla de `ds02` sigue mandando, con la diferencia de
  que ahora hay un optimizador que la aplica por ti cuando se te olvida.
- **El costo de una dependencia se paga en cada invocación.** Es la medición de la Fase 00
  —cuatro `import` de la biblioteca estándar costaban 6,6 ms— cobrada a otra escala: pandas
  cuesta 317 ms de arranque.

### Diccionario de traducción

| Java / SQL | Polars · DuckDB | Dónde se rompe el paralelo |
|---|---|---|
| `Stream` perezoso | `LazyFrame` | El `Stream` respeta tu orden; el `LazyFrame` lo reescribe |
| `stream.collect(...)` | `.collect()` | Igual de terminal, pero es aquí donde ocurre **toda** la lectura |
| `EXPLAIN` de Postgres | `.explain()` · `EXPLAIN` | Igual en espíritu. El de Polars se lee de abajo hacia arriba |
| `PreparedStatement` | `execute(sql, params)` | Igual: los parámetros no se interpolan en el texto |
| Vista materializada | `.collect()` guardado en Parquet | La vista la mantiene el motor; el Parquet lo mantienes tú |
| `ResultSet` sobre JDBC | `read_parquet(...)` | No hay servidor, no hay conexión, no hay red |
| Lazy loading de Hibernate | **nada** | Falso amigo. Aquí perezoso significa *planear antes de leer*, no *ir a buscar después* |
| `SELECT *` | `pl.scan_csv(...)` sin `select` | En Polars no cuesta escribirlo: el optimizador poda igual. En SQL sobre CSV, sí cuesta |

> 📝 **Nota de ecosistema.** Los tres motores hablan **Arrow**, un formato columnar en
> memoria que dejó de ser un detalle interno para volverse la lingua franca del análisis en
> Python: es lo que permite que DuckDB lea un DataFrame de Polars sin copiar un byte y que
> pandas 3.0 guarde sus cadenas donde las guarda. Cuando leas "zero-copy" en la
> documentación de cualquiera de los tres, es esto.
>
> Y dos apuntes de madurez que importan al elegir: **Polars llegó a 1.0 en 2024** y su API
> se estabilizó ahí —el material anterior a esa versión usa nombres que ya no existen—, y
> **DuckDB es a la analítica lo que SQLite a las bases transaccionales**: embebido, sin
> servidor, un archivo o ninguno. Esa comparación es la que mejor lo explica para este
> perfil, y es también su límite: no hay usuarios, ni permisos, ni escrituras concurrentes.

---

## 💻 5. Código mínimo con comentarios

Registro **script**: un archivo, `uv run`, sin capas. Lo nuevo es que ahora hay cuatro
implementaciones de la misma cosa, y que **tienen que devolver lo mismo**.

```bash
uv run --with duckdb==1.5.5 python preparar_tamanos.py --salida data
uv run --with polars==1.44.2 python consolidation.py
```

### 5.1 La misma pregunta, cuatro veces

El módulo `consolidation.py` tiene una función por motor y ninguna auxiliar compartida
—salvo el SQL, que comparten las dos variantes de DuckDB—. Es deliberado: la sección 6
cuenta líneas de código por motor, y repartir una implementación en tres funciones le
regalaría el número.

```python
# src/ds03-polars-y-el-modelo-lazy/consolidation.py

Row = tuple[str, str, int, int, int, int, int]

COLUMNS = ("sede", "mes", "gasto_cop", "leads", "planes",
           "valor_contratado_cop", "cobrado_cop")
```

Una tupla y no un `dataclass`, porque el resultado se ordena y se compara entre cinco
motores, y una tupla ya sabe hacer las dos cosas.

### 5.2 El bucle, que sigue siendo el competidor de verdad

```python
    with (data / "cuotas.csv").open(encoding="utf-8", newline="") as file:
        for row in csv.DictReader(file):
            # La cuota se cuenta en el mes en que **se pagó**, no en el que se programó: es
            # caja, no devengo. Las impagadas no tienen mes y no entran en ninguna fila.
            if row["fecha_pago"]:
                collected[(branch_of_plan[row["plan_id"]], row["fecha_pago"][:7])] += int(
                    row["valor_cop"])
```

Ese `branch_of_plan[...]` es el `join`, escrito a mano con un diccionario. Funciona, es
rápido, y es exactamente lo que hace un motor por dentro cuando construye una tabla hash
para un *hash join*. Verlo escrito es la mejor forma de entender qué te están cobrando los
otros tres.

### 5.3 Polars: el plan primero

```python
    spend = (pl.scan_csv(data / "pauta.csv")
             .select(sede=pl.col("sede"), mes=pl.col("fecha").str.slice(0, 7),
                     costo=pl.col("costo_cop"))
             .group_by("sede", "mes").agg(gasto_cop=pl.col("costo").sum()))
    ...
    table = spend
    for other in (leads, plans, collected):
        table = table.join(other, on=["sede", "mes"], how="full", coalesce=True)
```

Hasta aquí **no se ha leído un solo byte**. `table` es un plan: cuatro fuentes, cuatro
agrupaciones y tres uniones. `collect()` lo ejecuta, y antes lo optimiza.

```python
print(table.explain())
```

Lo que hay que buscar en esa salida son dos cosas, y solo dos: el `PROJECT` que dice cuántas
columnas se van a leer de cada archivo —si dice `2/8`, el pushdown funcionó— y dónde quedó
cada `FILTER`. Si un filtro aparece arriba del todo, no bajó, y probablemente sea porque lo
escribiste sobre una columna que el plan creó después.

**Detalles con intención**

- **`how="full", coalesce=True`.** Sin `coalesce`, Polars deja las dos columnas de llave
  —`sede` y `sede_right`— y la fila que solo existía de un lado se queda con la mitad en
  nulo. Es el error que más tarda en verse porque la tabla **parece** bien.
- **El cast antes del `fill_null`.** `pl.len()` devuelve `UInt32`, así que rellenar los
  `pl.Int64` dejaba la columna de leads con nulos y el resultado dejaba de coincidir con los
  otros motores. Lo encontró la prueba de igualdad, no la lectura del código.

### 5.4 DuckDB: el SQL que ya sabes

```sql
WITH spend AS (
    SELECT sede, strftime(fecha, '%Y-%m') AS mes, sum(costo_cop) AS gasto_cop
    FROM read_parquet($pauta) GROUP BY 1, 2),
...
SELECT sede, mes, coalesce(gasto_cop, 0)::BIGINT, ...
FROM spend FULL JOIN leads USING (sede, mes)
           FULL JOIN plans USING (sede, mes)
           FULL JOIN collected USING (sede, mes)
ORDER BY sede, mes
```

No hay que crear una tabla, ni cargar nada, ni abrir un archivo de base de datos:
`read_parquet` lee los archivos donde están. `USING` coalesce las llaves por ti, que es
justo lo que en Polars había que pedir a mano.

**Detalles con intención**

- **Los cuatro caminos van como parámetros** (`$pauta`, `$leads`, …), no interpolados en el
  texto. Es la misma razón de siempre y no cambia porque el "servidor" esté embebido.
- **La misma consulta sirve para CSV y para Parquet**: solo cambia el nombre de la función
  de lectura. Eso es lo que hace legítimo comparar los dos formatos — si el SQL fuera
  distinto, estaríamos midiendo dos consultas y llamándolo formato.

### 5.5 El experimento que rompe a propósito

Este no rompe el programa: rompe la **medición**, que es peor porque no se nota.

```bash
# En un entorno donde solo está instalado duckdb
uv run --with duckdb==1.5.5 python bench_punta_a_punta.py --motor 'duckdb (parquet)'
#   duckdb (parquet)         97 ms

# El mismo comando, en un entorno donde además está instalado pandas
uv run --with duckdb==1.5.5 --with pandas==3.0.5 python bench_punta_a_punta.py --motor 'duckdb (parquet)'
#   duckdb (parquet)        433 ms
```

**El mismo código, los mismos datos, 4,5× más lento por una dependencia que no se usa.** La
causa es el mecanismo de sustitución de nombres de DuckDB: al ejecutar la consulta busca si
algún nombre referenciado es un objeto de pandas o de Arrow, y para averiguarlo **importa
pandas**. Se puede comprobar:

```python
import sys, duckdb
duckdb.connect().execute("select 42").fetchall()
print("pandas" in sys.modules)      # False
consolidate_duckdb_parquet(Path("data/mes/parquet"))
print("pandas" in sys.modules)      # True
```

La consecuencia metodológica es la que hay que llevarse: **medir los cuatro motores en el
mismo entorno le cobra a DuckDB el precio de una dependencia que no usa**. Por eso la
segunda tabla de la sección 6 se toma con un entorno por motor, y por eso se dice.

**Prueba de fuego**

```bash
uv run --with pandas==3.0.5 --with polars==1.44.2 --with duckdb==1.5.5 \
       --with pytest pytest test_consolidation.py -q
```

Once pruebas. La primera —`test_los_cinco_motores_dan_la_misma_tabla`— es la que sostiene
toda la sección 6.

La mentira que te va a contar la salida si miras el lugar equivocado: la tabla de la sección
6 tiene **dos** partes, y la primera dice que DuckDB sobre Parquet es cinco veces más rápido
que el bucle en el tamaño más chico. Es cierto y es irrelevante para Áurea, porque esa tabla
mide la consulta con el motor ya cargado. El informe mensual de Marcela arranca un proceso.

---

## 📏 6. Medición

**Hipótesis.** Que el motor perezoso le gana al ansioso y los dos le ganan al bucle, **y que
todo eso deja de ser cierto en el tamaño y la frecuencia reales de Áurea**, donde el
arranque de la dependencia domina sobre la consulta.

**Condiciones.** CPython 3.14.5, pandas 3.0.5, Polars 1.44.2, DuckDB 1.5.5; macOS 26.6.2
sobre Apple Silicon de 8 núcleos —el entorno de referencia del curso—. Datos del Embudo con
semilla 20260913. Seis tamaños, y **solo los cuatro primeros son Áurea**:

| tamaño | filas | qué es |
|---|---|---|
| `mes` | 11.116 | marzo de 2026 — **real** |
| `trimestre` | 30.392 | el primer trimestre de 2026 — **real** |
| `ano` | 115.332 | los doce meses hasta el corte — **real** |
| `e1` | 298.581 | la historia completa, 2024-01 a 2026-03 — **real** |
| `e4` | 1.074.946 | el generador a `--escala 4` — **sintético** |
| `e16` | 4.200.081 | el generador a `--escala 16` — **sintético** |

Cinco repeticiones por celda (dos para el bucle en `e16`, declarado). Cada par motor×tamaño
corre en su propio proceso y el pico de memoria lo da `ru_maxrss` del sistema operativo, no
`tracemalloc`: ninguno de los tres motores asigna dentro del asignador de Python.

**Competidores.** Los cuatro del encargo más un quinto que aparece solo: DuckDB sobre CSV,
para separar el efecto del **motor** del efecto del **formato**. El bucle de la biblioteca
estándar no es un hombre de paja — es el código que cualquiera de las dieciocho fases del
camino base habría escrito, y las cinco implementaciones devuelven exactamente la misma
tabla, comprobado por prueba.

### 6.1 La consulta, con el motor ya cargado

| Motor | Líneas | Importar | `mes` 11k | `e1` 299k | `e4` 1,1M | `e16` 4,2M |
|---|---|---|---|---|---|---|
| bucle (stdlib) | 28 | 23 MB | 6,3 ms | 276,2 ms | 847,8 ms | 3.148,3 ms |
| pandas | 25 | 105 MB | 12,2 ms | 85,4 ms | 259,4 ms | 916,2 ms |
| polars (lazy) | 27 | 57 MB | **3,6 ms** | 11,1 ms | 28,8 ms | 122,6 ms |
| duckdb (csv) | 33 | 45 MB | 146,6 ms | 196,2 ms | 258,0 ms | 346,8 ms |
| duckdb (parquet) | 32 | 45 MB | 8,4 ms | **12,3 ms** | **16,0 ms** | **25,1 ms** |

Pico de RSS del proceso, en los mismos cuatro tamaños:

| Motor | `mes` | `e1` | `e4` | `e16` |
|---|---|---|---|---|
| bucle (stdlib) | **23 MB** | **24 MB** | **29 MB** | **45 MB** |
| pandas | 118 MB | 165 MB | 355 MB | 721 MB |
| polars (lazy) | 93 MB | 168 MB | 314 MB | 601 MB |
| duckdb (csv) | 164 MB | 187 MB | 224 MB | 363 MB |
| duckdb (parquet) | 155 MB | 161 MB | 169 MB | 205 MB |

```bash
uv run --with pandas==3.0.5 --with polars==1.44.2 --with duckdb==1.5.5 \
       python bench_engines.py --datos data
```

### 6.2 El informe completo, de punta a punta

Lanzar el proceso, importar la dependencia, responder y salir. **Cada motor en un entorno
donde solo está instalada su propia dependencia**, por lo que explica la sección 5.5.

| Motor | `mes` 11k | `trimestre` 30k | `ano` 115k | `e1` 299k |
|---|---|---|---|---|
| bucle (stdlib) | **34 ms** | **49 ms** | 120 ms | 297 ms |
| duckdb (parquet) | 97 ms | 98 ms | **98 ms** | **103 ms** |
| polars (lazy) | 150 ms | 151 ms | 154 ms | 154 ms |
| pandas | 326 ms | 346 ms | 373 ms | 453 ms |

Y de dónde sale ese piso: arrancar el intérprete y no hacer nada cuesta **26,3 ms**;
importar DuckDB lo sube a 84,7; Polars, a 129,2; pandas, a **342,7**.

```bash
uv run python bench_punta_a_punta.py --motor bucle
uv run --with duckdb==1.5.5 python bench_punta_a_punta.py --motor 'duckdb (parquet)'
```

> ⚖️ **Veredicto, y son tres.**
>
> **1. Para el informe mensual de Áurea, gana el bucle de la biblioteca estándar.** A un mes
> de datos responde en 34 ms de punta a punta, tres veces más rápido que DuckDB y diez veces
> más rápido que pandas, sin instalar nada y con 23 MB de memoria. **El umbral está entre
> 30.000 y 115.000 filas** —entre un trimestre y un año de Áurea—: en `trimestre` el bucle
> todavía gana (49 contra 98 ms) y en `ano` ya pierde (120 contra 98). Áurea genera unas
> 11.000 filas al mes, así que para el informe mensual la respuesta es el bucle, y para el
> anual es DuckDB.
>
> **2. Con el proceso caliente, el orden se da vuelta y no está cerca.** Si esto vive dentro
> de un servicio que responde muchas veces, DuckDB sobre Parquet hace en 25,1 ms lo que al
> bucle le toma 3.148: **125×** a 4,2 millones de filas. Le cuesta cuatro veces y media más
> memoria —205 MB contra 45— y a cambio contesta ciento veinticinco veces antes. Las dos tablas son correctas y responden preguntas distintas; publicar solo una de
> las dos es el error que este curso documentó en su propia Fase 17.
>
> **3. El formato pesa más que el motor.** El mismo SQL, sobre los mismos datos, tarda 346,8
> ms sobre CSV y **25,1 ms sobre Parquet**: 14×. Y el Parquet ocupa entre 24 y 42 veces
> menos disco. Si tuvieras que hacer un solo cambio en un pipeline de datos que ya funciona,
> es este — con una condición: **convertir cuesta entre 222 y 431 ms**, así que paga cuando
> se escribe una vez y se lee muchas.
>
> **Y el empate, que también se dice:** en líneas de código efectivas, los cinco están entre
> **25 y 33**. El argumento de que "en SQL son cuatro líneas" no sobrevive a contar el SQL.

> 📝 **Lo que esta medición no dice.** No mide contra Postgres —que ya tiene estos datos
> desde la Fase 11—: necesita un servicio corriendo y el resto de la sección no necesita
> nada, así que es el ejercicio 22 y su número entra aquí cuando alguien lo corra. No mide
> escritura, ni actualizaciones, ni concurrencia: los tres motores son de lectura en este
> uso. No mide con la memoria apretada, que es donde el bucle brillaría más todavía. Y los
> dos tamaños grandes son sintéticos: Áurea no tiene cuatro millones de filas y no las va a
> tener pronto.

---

## 🧱 7. Miniproyecto — El consolidado que Patricia corre el día 1

**El encargo.** Patricia te dice: *"El día primero de cada mes tengo que mandarle a los seis
franquiciados su consolidado y solo el suyo. Hoy lo hago a mano con el de Marcela, borrando
las filas de las otras sedes, y ya me equivoqué dos veces. Y necesito que el archivo que le
mando a Zipaquirá no contenga por dentro los datos de Suba, porque la última vez abrieron el
Excel y vieron todo."*

**Por qué duele.** Porque son dos requisitos que tiran en direcciones opuestas: **un solo
recorrido de los datos** —no seis— y **seis archivos que no se contaminen entre sí**. Y
porque el segundo no es un detalle técnico: un franquiciado que ve las cifras de otro es un
problema de contrato, no de formato.

**Datos de entrada.** El conjunto del Embudo preparado con `preparar_tamanos.py`. Trabaja
sobre `ano/`, que son 115.332 filas: el tamaño donde la respuesta de la sección 6 acaba de
darse vuelta, y por eso el interesante. El caso sucio está en los datos: **hay sedes sin
ninguna adquisición en algunos meses**, y el consolidado de esa sede ese mes no es una fila
de ceros ni una fila ausente — decide cuál de las dos es, y defiéndelo.

**Criterios de aceptación.**

1. `python consolidado_por_sede.py --datos data/ano --salida salida/` escribe **un archivo
   por sede franquiciada**, con el consolidado mensual de esa sede y nada más.
2. Los datos se leen **una sola vez**. No vale un bucle de seis consultas: si tu programa
   abre `cuotas.csv` seis veces, no pasó.
3. Una prueba verifica que ningún archivo de salida contiene el nombre de otra sede, ni en
   los datos ni en los metadatos. *(Si eliges Parquet como formato de salida, esta prueba es
   más interesante de lo que parece.)*
4. La suma de las seis salidas más las cuatro sedes propias es **exactamente** el
   consolidado completo de la sección 5. Compruébalo en una prueba, no a ojo.
5. El programa reporta su tiempo de punta a punta, y tú eliges el motor **con la tabla de la
   sección 6 en la mano** y justificas la elección en tres líneas del README. Cualquiera de
   los cuatro es defendible; lo que no es defendible es no haber mirado.
6. `--formato csv|parquet` decide la salida. Explica cuál le mandarías a Patricia y cuál al
   sistema contable, y por qué no son el mismo.

**Restricciones de registro.** Script: un archivo, `argparse`, `uv run`. Una sola
dependencia como máximo — la del motor que elijas— o ninguna, si eliges el bucle.

**La trampa.** El criterio 3. Parquet guarda estadísticas por columna **en los metadatos**,
incluidos el mínimo y el máximo de cada bloque. Si escribes el archivo de Zipaquirá filtrando
un DataFrame que contenía a las diez sedes, hay formas de que los metadatos sigan hablando de
las otras. No te digo cuáles: el trabajo es que lo compruebes y lo cierres.

**Pistas.**

<details><summary>Pista 1 — el enfoque</summary>

Un solo recorrido y seis salidas es un problema de particionado, no de filtrado. La pregunta
es dónde partes: al leer, al agregar o al escribir. Solo una de las tres respuestas lee los
datos una vez.
</details>

<details><summary>Pista 2 — la herramienta</summary>

Si vas por Polars, mira `partition_by` sobre el resultado ya agregado. Si vas por DuckDB,
mira `COPY (...) TO 'dir' (FORMAT parquet, PARTITION_BY (sede))`, que escribe el árbol de
directorios él solo. Los dos hacen lo mismo y se leen muy distinto.
[duckdb.org/docs/stable/sql/statements/copy](https://duckdb.org/docs/stable/sql/statements/copy)
</details>

<details><summary>Pista 3 — el esqueleto</summary>

```python
def consolidate(data: Path) -> "Table": ...
def split_by_branch(table: "Table", branches: list[str]) -> dict[str, "Table"]: ...
def write(tables: dict[str, "Table"], target: Path, fmt: str) -> None: ...
```
</details>

**Cómo se entrega.**

```bash
git tag -a ds-mini-03 -m "Mini ds03: consolidado por sede · <motor> · <X> ms punta a punta sobre 115.332 filas"
```

**En el mensaje del tag van el motor que elegiste y su tiempo.** Es lo que permite comparar
tu elección con la de otro lector que eligió distinto.

---

## 🧪 8. Ejercicios (25)

**🟢 Fácil (1–6)**

1. Corre `.explain()` sobre el plan de `consolidate_polars` y encuentra la línea que dice
   cuántas columnas se leen de `pauta.csv`. Son ocho en el archivo. ¿Cuántas lee?
2. Cambia `pl.scan_csv` por `pl.read_csv` en las cuatro fuentes y mide. La diferencia es la
   pereza, sin ningún otro cambio.
3. Convierte solo `cuotas.csv` a Parquet y compara el tamaño. Después ábrelo con
   `duckdb.sql("DESCRIBE read_parquet(...)")` y mira los tipos que dedujo.
4. Corre el consolidado sobre `mes/` con los cinco motores y ordénalos. Después hazlo sobre
   `e16/`. Es la sección 6 reproducida por ti.
5. Quita `coalesce=True` de los `join` de Polars y mira qué sale. La tabla parece bien hasta
   la tercera columna.
6. Mide el arranque en frío de tu máquina: `python -c pass`, `python -c "import pandas"`,
   `import polars`, `import duckdb`. Compara con los números de la sección 6.

**🟡 Intermedio (7–14)**

7. Añade un filtro por sede al final del plan de Polars y comprueba con `.explain()` que baja
   hasta la lectura. Después escríbelo sobre una columna que el plan **crea** —`mes`— y
   comprueba que ya no baja. Explica la diferencia.
8. El `strftime(fecha, '%Y-%m')` de DuckDB y el `str.slice(0, 7)` de Polars hacen lo mismo de
   formas muy distintas. Mide las dos y explica cuál puede aprovechar un índice de bloque de
   Parquet y cuál no.
9. Escribe la consulta de DuckDB con `PIVOT` en vez de los tres `FULL JOIN`. Mide, y decide
   cuál dejarías para que la lea otra persona.
10. Reproduce el experimento de la sección 5.5 en tu máquina: mide DuckDB con y sin pandas
    instalado. Si tu diferencia no es de 4×, reporta cuál es y con qué versiones.
11. Corre el consolidado de `e16` con `polars` limitando la memoria del proceso (`ulimit -v`).
    Encuentra el punto donde falla y compáralo con el pico que reporta la sección 6.
12. Usa `pl.scan_parquet` en vez de `scan_csv` y mide Polars sobre Parquet. Es la celda que
    falta en la tabla de la sección 6 — complétala y dinos si cambia algún veredicto.
13. Mide el costo de `write_parquet` por tamaño y calcula a partir de cuántas consultas se
    amortiza la conversión para el caso de `e1`.
14. DuckDB puede consultar un DataFrame de pandas directamente por su nombre de variable.
    Pruébalo, mídelo, y explica qué tiene que ver eso con lo que descubrió la sección 5.5.

**🟠 Difícil (15–21)**

15. Diagnóstico: el consolidado de Polars devuelve una fila con `leads` en nulo y las otras
    cuatro cifras bien. Reprodúcelo quitando el `cast` de la sección 5.3, explica por qué
    `pl.len()` tiene la culpa, y escribe la prueba que lo atrapa.
16. Las dos tablas de la sección 6 dan ganadores distintos. Escribe, en diez líneas, el
    criterio que usarías para decidir cuál citar ante una pregunta concreta de Áurea. Después
    aplícalo a estas tres: el informe mensual de Marcela, el tablero que `ds05` va a construir,
    y el endpoint de AgendaAPI que devuelve el consolidado de una sede.
17. Mide el consolidado sobre `e16` con el archivo en un disco externo o en un volumen de red.
    La relación entre los motores cambia, y el que más cambia es el que menos lee.
18. Implementa el consolidado como una vista materializada: calcula una vez, guarda en
    Parquet, y responde desde ahí. Mide las consultas posteriores y di a partir de cuántas
    vale la pena.
19. El bucle de la sección 5.2 construye un diccionario `branch_of_plan` con todos los planes.
    A `e16` son cientos de miles de entradas. Mide cuánta memoria es, y propón una forma de no
    tenerlo entero — con su costo.
20. **De registro.** Este consolidado lo va a pedir también AgendaAPI, por HTTP, para una sola
    sede y un solo mes. ¿Mismo código? Decide entre reutilizar, duplicar o mover a Postgres, y
    sostén la decisión con las dos tablas de la sección 6.
21. Reproduce las dos tablas completas en tu máquina y publica las diferencias con las del
    curso. Si algún veredicto se invierte, ese es el hallazgo y vale más que el ejercicio.

**🔴 Muy difícil (22–25)**

22. Escribe el consolidado en SQL contra el Postgres de la Fase 11, con los datos ya cargados,
    y mídelo de punta a punta —conexión incluida— contra las cuatro filas de la tabla 6.2.
    Declara si cuentas o no el costo de haber cargado los datos. **Es material de
    `BENCHMARKS.md`**: tráelo con sus condiciones.
23. **Defiende lo contrario.** Construye el caso realista de Áurea donde pandas es la respuesta
    correcta aunque pierda en las dos tablas. Existe, y tiene que ver con quién mantiene el
    código, no con el rendimiento.
24. 🔥 Toma el plan que imprime `.explain()` de Polars y el de `EXPLAIN` de DuckDB para la
    misma consulta y ponlos lado a lado. Explica las dos decisiones que toma uno y no el otro.
25. **De registro.** Áurea crece y compra tres redes más: el conjunto pasa a cuatro millones de
    filas y el consolidado se pide a diario. Con las dos tablas delante, escribe la
    recomendación de una página: qué motor, qué formato, dónde corre, y qué se rompe primero.

**🔥 Opcionales**

- Prueba `pl.scan_csv(..., n_rows=1000)` y mira si el plan lee solo esas mil. La respuesta
  depende del formato y es un buen recordatorio de que la pereza tiene límites.
- `duckdb.sql("FROM 'data/e1/parquet/*.parquet'")` lee un glob completo. Mira qué pasa cuando
  los archivos tienen esquemas distintos.

---

## 📚 9. Referencias

**Documentación oficial**

- [https://docs.pola.rs/user-guide/lazy/](https://docs.pola.rs/user-guide/lazy/) — la guía
  del modo perezoso, con la explicación del optimizador. Es la página central de esta sección.
- [https://docs.pola.rs/user-guide/lazy/query-plan/](https://docs.pola.rs/user-guide/lazy/query-plan/)
  — cómo se lee un plan. Léela con tu propio `.explain()` al lado.
- [https://docs.pola.rs/user-guide/migration/pandas/](https://docs.pola.rs/user-guide/migration/pandas/)
  — el diccionario pandas ⇄ Polars, útil si vienes de `ds02` con los dedos acostumbrados.
- [https://duckdb.org/docs/stable/data/parquet/overview](https://duckdb.org/docs/stable/data/parquet/overview)
  — leer y escribir Parquet desde SQL.
- [https://duckdb.org/docs/stable/guides/performance/file_formats](https://duckdb.org/docs/stable/guides/performance/file_formats)
  — por qué el formato importa, con los números de ellos. Compáralos con los tuyos.
- [https://parquet.apache.org/docs/](https://parquet.apache.org/docs/) — el formato, si
  quieres entender de dónde salen las estadísticas por bloque.
- [https://arrow.apache.org/docs/format/Columnar.html](https://arrow.apache.org/docs/format/Columnar.html)
  — la especificación columnar de Arrow. Es densa, y explica el "zero-copy" de una vez por
  todas.

**Artículos**

- La entrada del blog de DuckDB sobre *replacement scans* explica el mecanismo que la sección
  5.5 mide desde fuera. Busca por ese término en `duckdb.org/news`; las URL de blog cambian.

> ⚠️ Las URLs, títulos y contenidos pueden haber cambiado; verifícalos. Aquí no se citan
> números de página, ISBN ni identificadores de video que no se hayan comprobado.

**Orden de lectura sugerido.** Antes de escribir código: la guía del modo perezoso. Durante:
la página de planes de consulta, con tu `.explain()` al lado. Después: la de formatos de
DuckDB, para entender por qué la tercera parte del veredicto es la más rentable de las tres.

---

## 🚀 10. Cierre y conexión con la siguiente sección

Terminas con el consolidado mensual escrito cinco veces, con dos tablas que dan ganadores
distintos y con la parte más difícil de escribir de todo el track: **la que dice que la
herramienta moderna pierde en el caso real de la empresa del curso**. No pierde por poco ni
por casualidad —pierde por tres veces, y la razón es que el arranque de la dependencia cuesta
más que la consulta cuando la consulta es de once mil filas—.

Eso no descalifica a Polars ni a DuckDB: los descalifica **para el informe mensual de
Patricia**, y los consagra para cualquier cosa que corra caliente o que crezca. Saber decir
cuál de las dos situaciones tienes delante es el músculo entero de esta sección.

`ds04` es el proyecto Embudo completo, y va a usar todo esto para una pregunta que todavía no
tiene respuesta: **cuánto cuesta de verdad un paciente adquirido**. Ahí la herramienta pasa a
segundo plano y la pregunta difícil es de método: la misma tabla, con dos modelos de
atribución, da dos respuestas distintas, y una de las dos es la que Marcela va a llevar al
comité. `ds01` ya dejó la pista: TikTok cuesta siete veces lo que cuesta Google **si el mérito
es del último toque**.

> **La señal de que quedó bien:** cuando ante una herramienta nueva tu primera pregunta no sea
> *"¿cuánto más rápida es?"* sino *"¿más rápida midiendo qué, y cuántas veces al día voy a
> pagar su arranque?"* — y cuando puedas recomendar la biblioteca estándar sin sentir que te
> quedaste atrás.

> 🏷️ **No cierres la sección sin el tag.** Con el checklist de la sección 2 en verde, el
> miniproyecto corriendo y `git status` limpio:
>
> ```bash
> git tag -a ds-fase-03 -m "ds03 cerrada: <el checklist, en una línea por ítem>"
> ```
>
> Los commits de la sección llevan su prefijo (`ds 03: …`), los de ejercicio su número
> (`ds 03 ej12: …`) y el miniproyecto el suyo (`ds 03 mini: …`). El miniproyecto terminado
> lleva además su tag anotado `ds-mini-03`, con **el motor elegido y su tiempo** en el mensaje.
> La convención completa está en
> [`00-convencion-de-git-y-tags.md`](00-convencion-de-git-y-tags.md).
