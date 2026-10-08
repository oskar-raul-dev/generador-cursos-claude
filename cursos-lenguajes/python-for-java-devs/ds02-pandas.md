# 🐼 ds02 — pandas y el modelo de DataFrame

> Python para desarrolladores Java senior · Track `ds` · sección 2 de 9
> Depende de: `ds01`, Fase 11 (Postgres) · Habilita: `ds03`
> Registro de esta sección: script — un archivo por informe, ejecutado a mano
> Proyecto que avanza: Embudo — nace el informe de cobranza

---

## 🎯 1. Propósito

En `ds01` mantuviste cuatro columnas alineadas a pulso y te quedaste con la sospecha de que
eso no escala más allá de un cálculo. Tenías razón. Esta sección trae la estructura que
resuelve esa alineación —el DataFrame— y te cobra la comodidad de tres formas que conviene
conocer antes de aceptarla.

El encargo es de Marcela y es el que abre el proyecto Embudo: **un plan aceptado no es plata
cobrada**. El ingreso llega en veinticuatro cuotas, así que *"ventas del mes"* y *"caja del
mes"* son dos cifras distintas y solo una de las dos paga la nómina. Al terminar tienes ese
informe, y —lo que de verdad importa— sabes en qué orden se unen y se agregan los datos para
que no cueste veinticuatro veces lo que debería.

> 🧭 **La pregunta que ordena la sección: ¿en qué orden uno y agrego?** No es una pregunta de
> estilo. Unir 81.000 filas para producir 20 cuesta 287 ms; agregar primero y unir después,
> 11. Es la misma tabla y la misma biblioteca.

---

## ✅ 2. Qué queda listo al terminar

- [ ] `collections_report.py` produce la tabla de cobranza por sede e interés en **tres
      versiones** que devuelven exactamente lo mismo, con la prueba que lo comprueba.
- [ ] Todo `merge` del informe lleva `validate=`, y sabes qué excepción lanza cuando la llave
      no es la que creías.
- [ ] Puedes explicar por qué `df[df.x > 1]["y"] = 0` no hace nada en pandas 3.0, y qué hacía
      antes de 2.0.
- [ ] Sabes leer `memory_usage(deep=True)` y decir cuánta memoria es del DataFrame y cuánta es
      de pandas por existir.
- [ ] `bench_merge.py` produce la tabla de la sección 6 en tu máquina, con su línea base de
      memoria descontada.
- [ ] Puedes calcular, sin correrlo, cuántas filas produciría un `merge` por una columna que no
      es llave — y por qué eso tumba el proceso.
- [ ] El miniproyecto de la sección 7 corre y cumple sus criterios de aceptación.

---

## 🚫 3. Qué NO entra todavía

- **Polars, DuckDB y el modelo perezoso** → `ds03`, donde pandas deja de ser el único
  candidato y la comparación se hace con números.
- **Series temporales, resampleo y estacionalidad** → `ds04`. Aquí se agrupa por mes con un
  `astype`, y se dice que es la versión corta.
- **Los dos modelos de atribución** → `ds04`.
- **Gráficos** → `ds05`. `df.plot()` existe, es cómodo y no se usa hasta entonces.
- **`MultiIndex` más allá de dos niveles, `pivot_table`, `stack`/`unstack`** → fuera del curso.
  Son potentes y son el camino más corto a un informe que nadie puede leer seis meses después.
  Cuando la respuesta pida eso, casi siempre la pregunta era SQL.
- **`read_sql` contra la base de la Fase 11** → `ds03`, donde tiene con qué compararse.

---

## 🧠 4. Concepto mínimo

### El problema, antes de la herramienta

La cobranza de Áurea vive en dos archivos. Uno tiene los planes —6.065 filas, una por plan
aceptado, con su sede, su interés y su valor total— y el otro las cuotas: 81.274 filas, una
por cuota programada, con su `fecha_pago` vacía cuando nadie la pagó.

La pregunta de Marcela es *"¿cuánto de lo que vendimos hemos cobrado de verdad, por sede?"*, y
tiene tres pasos: decidir qué cuotas están pagadas, sumarlas por plan, y llevar esa suma a la
sede del plan. En SQL son seis líneas y las escribiste mil veces. Con las columnas sueltas de
`ds01` tendrías que emparejar `plan_id` contra `plan_id` a mano, y eso ya no es un cálculo: es
un `join`, y escribirlo tú es exactamente lo que no quieres hacer.

### Qué es un DataFrame, y qué no

Un DataFrame es **un diccionario ordenado de columnas que comparten un índice**. Cada columna
es un array como los de `ds01` —tipada, contigua— y el índice es el que mantiene la alineación
que tú mantenías a pulso.

Y ahora los tres límites, porque la analogía fácil es la que hace daño:

- **No es una tabla de base de datos.** No hay esquema que se valide, no hay llave primaria, no
  hay restricción de unicidad, no hay transacción. El índice **puede tener duplicados** y pandas
  no dice nada.
- **No es una lista de objetos.** Una fila no es una entidad: es un corte transversal de `n`
  columnas, y construirla cuesta. Cada vez que pienses "recorro las filas", el modelo se te
  rompió.
- **No es una hoja de cálculo**, aunque se le parezca más que a las dos anteriores: aquí las
  operaciones son de columna entera y no de celda.

Lo más cercano que tienes en tu cabeza es **un `ResultSet` materializado, en columnas, sin
esquema y sin base de datos detrás**. Con eso alcanza para empezar.

### La alineación automática, que es la mitad de la magia y la mitad de los sustos

```python
committed = per_plan["comprometido_cop"]      # índice: plan_id
collected = per_plan["cobrado_cop"]           # índice: plan_id

collected / committed                         # se alinean por índice, no por posición
```

Esa es la propiedad que justifica todo el diseño: las dos Series se emparejan por **etiqueta**,
así que da igual en qué orden vengan. Y es la propiedad que produce el susto clásico: si una de
las dos tiene índices que la otra no, el resultado no falla — sale con `NaN` en esas filas, más
largo que las dos entradas, y sigue adelante.

> ⚠️ **La regla operativa, y vale para todo el track:** cuando una operación entre dos objetos de
> pandas te devuelve más filas de las que tenían los dos, no tienes un resultado: tienes un bug
> con forma de tabla.

### Tu instinto de Java dice… y esta vez se equivoca

Tu instinto es **pensar en filas**, y es razonable: llevas once años recorriendo `ResultSet`,
iterando listas de entidades y escribiendo la lógica de negocio dentro del bucle. Aplicado a
pandas, sale esto:

```python
# ❌ El reflejo. Es correcto, es legible, y es un bucle de Python con otro nombre.
merged["cobrado"] = merged.apply(
    lambda row: row["valor_cop"] if isinstance(row["fecha_pago"], str) else 0, axis=1)
```

`apply(axis=1)` **construye una Series por fila** para pasártela a la función. Ochenta y un mil
Series, ochenta y un mil llamadas a Python. Es el `for` de `ds01`, pero con un sobrecosto por
vuelta mucho peor.

```python
# ✅ La condición como máscara: una decisión sobre las 81.274 filas, en C.
merged["cobrado"] = merged["valor_cop"].where(merged["fecha_pago"].notna(), 0)
```

Un cambio de línea: **287 ms a 18 ms**, medido en la sección 6. Y no es que `apply` esté
prohibido —existe para lo que de verdad no es vectorizable—, es que casi nunca es lo que hace
falta. La pregunta correcta antes de escribirlo es *"¿esto es una condición sobre columnas?"*, y
la respuesta es que sí nueve de cada diez veces.

### Autopsia de anti-patrón: unir primero, agregar después

Es el más caro de los dos errores de esta sección y el más difícil de ver, porque el código está
bien y el resultado también.

```python
# ❌ Unir 81.274 cuotas con 6.065 planes, y después colapsar a 20 filas.
merged = installments.merge(plans, on="plan_id", how="left")
grouped = merged.groupby(["sede", "interes"]).agg(...)

# ✅ Colapsar las cuotas a 6.065 filas primero, y unir 6.065 contra 6.065.
per_plan = installments.assign(cobrado=collected).groupby("plan_id").agg(...)
merged = per_plan.merge(plans.set_index("plan_id"), left_index=True, right_index=True,
                        how="left", validate="1:1")
```

**El costo, medido:** 18,4 ms y 40,6 MB contra 11,1 ms y 30,4 MB. No es dramático a esta escala
—Áurea es pequeña, y decirlo es parte de la honestidad del curso—, pero la relación se mantiene
cuando el archivo crece, y hay un premio que no se ve en la tabla: la versión buena **se puede
verificar**. Con `validate="1:1"`, pandas falla si la llave dejó de ser única. La versión de
arriba no tiene dónde poner esa garantía.

Y la variante catastrófica del mismo error, que sí es dramática. Marcela pide *"el gasto de
pauta junto con los leads"* y alguien escribe:

```python
pauta.merge(leads, left_on="canal", right_on="canal_ultimo_toque")   # 🧨
```

`canal` no es una llave: es una columna con tres valores. El resultado son
**351.979.120 filas** —16.420 × 8.574 solo para Google, y otro tanto para los demás—, que a
sesenta bytes por fila son unos **21 GB**. El proceso muere, y lo que hay que saber es que
**murió por una línea que se lee perfectamente bien**. La cuenta se hace antes de correr nada:
por cada valor de la llave, filas de la izquierda por filas de la derecha.

### Esto sí funciona igual

- **El álgebra relacional.** `merge` es `JOIN`, `groupby().agg()` es `GROUP BY`, `query()` es
  `WHERE`, y si sabes cuándo un `LEFT JOIN` te duplica filas, ya sabes cuándo `merge` te las
  duplica. Es el conocimiento que más se transfiere de todo el curso.
- **La disciplina de la llave.** `validate="1:1"` es la restricción de unicidad que en la base
  de datos te daba el motor. Aquí te la das tú, y por eso hay que dársela siempre.
- **Filtrar temprano.** Reducir antes de unir es la misma regla que te enseñó el plan de
  ejecución de Postgres en la Fase 11.
- **Los tipos importan y cuestan.** Lo de `ds01` sigue vigente un nivel más arriba: cada columna
  tiene su dtype y eso es memoria.

### Diccionario de traducción

| Java / SQL | pandas | Dónde se rompe el paralelo |
|---|---|---|
| `ResultSet` | `DataFrame` | El `ResultSet` se recorre una vez y va por filas; el DataFrame está entero en memoria y se opera por columnas |
| `JOIN ... ON` | `df.merge(other, on=…)` | Sin `validate=`, pandas no sabe ni le importa si la llave es única |
| `GROUP BY` | `df.groupby(…).agg(…)` | El resultado queda **indexado** por las llaves del grupo, no como columnas. `reset_index()` es el puente |
| `PRIMARY KEY` | el índice | El índice admite duplicados y valores nulos. No es una restricción: es una etiqueta |
| `NULL` | `NaN` / `NA` | `NaN` es un flotante, así que una columna de enteros con un ausente **se convierte en flotante** salvo que uses los tipos nulables |
| `Stream.map` | asignación de columna | El stream es perezoso y de a uno; la columna es ansiosa y de golpe. Lo perezoso llega en `ds03` |
| `entity.setPrice(0)` | `df.loc[mask, "price"] = 0` | En pandas se asigna sobre un conjunto de filas, nunca sobre una "entidad" |
| `List.subList` | `df[mask]` | En pandas 3.0 el resultado es una copia perezosa: escribir en él **no** toca el original |

> 📝 **Nota de ecosistema — pandas 3.0 borró la pregunta más frecuente de su propia historia.**
> Durante una década, la duda número uno de pandas fue el `SettingWithCopyWarning`: *"¿esto que
> acabo de escribir modificó mi DataFrame o no?"*. La respuesta era "depende", y dependía de cómo
> NumPy hubiera decidido darte una vista o una copia. Desde pandas 3.0, **Copy-on-Write es el
> comportamiento por defecto y la pregunta desapareció**: filtrar siempre da una copia lógica, y
> escribir en ella nunca toca el original.
>
> ```python
> subset = plans[plans["interes"] == "estetica"]
> subset["valor_total_cop"] = 0      # seguro, silencioso, y no toca `plans`
>
> plans[plans["interes"] == "estetica"]["valor_total_cop"] = 0
> # ChainedAssignmentError: A value is being set on a copy… — avisa, y no hace nada
> ```
>
> Esto importa por dos razones prácticas. La primera: **todo lo que encuentres en internet sobre
> `SettingWithCopyWarning` describe un pandas que ya no existe**, y buena parte de los trucos que
> recomienda —`.copy()` defensivos por todas partes— hoy solo gastan memoria. La segunda: si
> heredas código escrito para pandas 1.x, puede que alguna parte de él **dependiera** de que la
> vista modificara el original. Ese código ahora falla en silencio, y ningún linter te lo va a
> decir.
>
> El otro cambio de 3.0 que se nota enseguida: las columnas de texto se infieren como dtype
> `str` en vez de `object`. Verás `object` en cualquier tutorial anterior y `str` en tu terminal;
> es lo mismo para lo que haces aquí.

---

## 💻 5. Código mínimo con comentarios

El registro sigue siendo **script**: un archivo por informe, `uv run`, sin capas. Lo que cambia
respecto de `ds01` es que ahora hay dos dependencias y una estructura de datos con opiniones.

```bash
uv run --with pandas==3.0.5 python collections_report.py
```

### 5.1 Leer con intención

```python
# src/ds02-pandas/collections_report.py

PLAN_COLUMNS = ["plan_id", "sede", "interes", "valor_total_cop"]
INSTALLMENT_COLUMNS = ["plan_id", "valor_cop", "fecha_pago"]

# `category` guarda un código entero por fila y el diccionario una sola vez.
LEAN_DTYPES = {"sede": "category", "interes": "category", "plan_id": "string"}


def read_installments(path: Path, *, lean: bool = False) -> pd.DataFrame:
    """Las cuotas. `fecha_pago` vacío significa **no pagada**, y eso no es lo mismo que cero."""
    if not lean:
        return pd.read_csv(path)
    return pd.read_csv(path, usecols=INSTALLMENT_COLUMNS,
                       dtype={"plan_id": "string", "valor_cop": "int64"})
```

**Detalles con intención**

- **`usecols`** es la optimización más barata y la que más se olvida: de las cinco columnas de
  `cuotas.csv` el informe usa tres, y las otras dos son 81.274 filas de memoria que se paga sin
  usarse. Entre `usecols` y los dtypes, la entrada del informe baja de 17,3 a 10,4 MB.
- **`fecha_pago` se deja ausente**, no se rellena con cero ni con una fecha centinela. Un
  `NaT`, un `None` y un cero son tres cosas distintas, y confundirlas es cómo se fabrica un
  informe de cartera que dice que todo está al día.
- **`category` ahorra, y menos de lo que dice la fama.** Medido: `cuotas.csv` pasa de 15,4 a
  11,4 MB y `planes_de_tratamiento.csv` de 1,84 a 1,16 MB. Es un 26% y un 37%, no un orden de
  magnitud. La ganancia grande de esta sección está en otra parte, y la sección 6 dice dónde.

### 5.2 El informe, en el orden correcto

```python
def collected_lean(plans: pd.DataFrame, installments: pd.DataFrame) -> pd.DataFrame:
    # La columna se calcula ANTES de agrupar, y se agrupa sumando. La tentación es
    # `agg(lambda grupo: ...)`, que es legible y vuelve a ser un bucle de Python: una llamada
    # por grupo, y aquí hay 6.100 grupos.
    collected = installments["valor_cop"].where(installments["fecha_pago"].notna(), 0)
    per_plan = (installments.assign(cobrado=collected)
                .groupby("plan_id", observed=True)
                .agg(cobrado_cop=("cobrado", "sum"),
                     comprometido_cop=("valor_cop", "sum")))

    merged = per_plan.merge(plans.set_index("plan_id"), left_index=True, right_index=True,
                            how="left", validate="1:1")
    grouped = merged.groupby(["sede", "interes"], observed=True)[
        ["cobrado_cop", "comprometido_cop"]].sum()
    return finish(grouped)
```

Tres decisiones y ninguna es de estilo:

- **`.where(cond, 0)` en vez de `apply`.** La condición se evalúa sobre la columna entera.
- **`groupby` antes del `merge`.** 81.274 filas se vuelven 6.065 antes de tocar la otra tabla.
- **`validate="1:1"`.** Es la línea que convierte un error silencioso en una excepción, y el
  mensaje que lanza es de los buenos: nombra la llave y te imprime los duplicados. Así se ve
  cuando de verdad salta —este es el del ejercicio 8, uniendo `etapas` con `toques`, donde la
  llave no es única de ninguno de los dos lados—:

```
MergeError: Merge keys are not unique in either left or right dataset;
not a one-to-one merge.
Duplicates in left:  lead_id  L0000002  L0000002  L0000002 …
```

### 5.3 El remate compartido, y por qué el orden se fija a mano

```python
def finish(grouped: pd.DataFrame) -> pd.DataFrame:
    result = grouped.copy()
    result["cobrado_pct"] = (result["cobrado_cop"] / result["comprometido_cop"] * 100).round(1)
    return result.sort_index()
```

El `sort_index()` no es cosmética. El orden que deja `groupby` depende de los dtypes —una
columna `category` ordena por el orden de sus categorías y una de texto alfabéticamente—, así
que sin esa línea **la misma tabla sale en dos órdenes según cómo se leyó el CSV**. Un informe
que cambia de orden entre corridas es un informe que nadie puede comparar con el del mes pasado,
y `diff` deja de servir.

### 5.4 La medición mide el proceso, no el asignador

El arnés de la Fase 02 mide memoria con `tracemalloc`, y aquí **no sirve**: `tracemalloc` solo
ve lo que asigna el asignador de Python, y pandas guarda buena parte de sus datos en búferes
que viven fuera de él. Un número bonito y falso.

```python
def peak_rss_mb() -> float:
    """Pico de memoria residente del proceso, en MB.

    `ru_maxrss` es una marca de agua alta: nunca baja. Por eso hace falta un proceso por
    variante — dentro del mismo proceso, la segunda mediría el pico de la primera.
    En macOS viene en bytes y en Linux en kilobytes, y esa diferencia ha arruinado más de
    una tabla de benchmarks publicada.
    """
    raw = resource.getrusage(resource.RUSAGE_SELF).ru_maxrss
    return raw / 1e6 if sys.platform == "darwin" else raw / 1e3
```

El arnés **no se reemplaza: se amplía**, que es la regla del curso. `measure` sigue dando el
tiempo con sus repeticiones; el pico lo da el sistema operativo, y cada variante corre en su
propio proceso porque `ru_maxrss` nunca baja.

**El patrón a memorizar**
> Agrega hasta la granularidad de la respuesta **antes** de unir, y ponle `validate=` a todo
> `merge`. Las dos reglas juntas te ahorran el 90% de los informes que no caben en memoria.

**Prueba de fuego**

```bash
uv run --with pandas==3.0.5 --with pytest pytest test_collections_report.py -q
```

Diez pruebas. La que importa es `test_las_tres_versiones_dan_la_misma_tabla`; la que más se
disfruta es `test_validate_atrapa_la_union_muchos_a_muchos`, que es un `pytest.raises` sobre el
error que te habría costado la tarde.

La mentira que te va a contar la salida si miras el lugar equivocado: la columna de memoria de
la sección 6 arranca en **76,9 MB para un proceso que no hizo nada**. Si comparas los totales
crudos vas a concluir que el `apply` gasta un 22% más que la versión buena; si descuentas la línea
base, la relación real es 54,3 contra 30,4 — un 79% más. Publicar la columna sin descontar el intérprete es
contar pandas dos veces.

---

## 📏 6. Medición

**Hipótesis.** El orden de las operaciones domina sobre todo lo demás: agregar antes de unir le
gana a unir antes de agregar en tiempo y en memoria, y las dos le ganan por un orden de magnitud
a la versión con `apply`. Los dtypes ayudan, y ayudan mucho menos de lo que se cree.

**Condiciones.** CPython 3.14.5, pandas 3.0.5, macOS 26.6.2 sobre Apple Silicon de 8 núcleos —el
entorno de referencia del curso—. Datos reales del Embudo con semilla 20260913: 6.065 planes y
81.274 cuotas, que es el tamaño verdadero de Áurea y no una proyección. Cinco repeticiones por
variante. **Cada variante corre en su propio proceso** y se reporta el pico de RSS que ve el
sistema operativo, no `tracemalloc` — pandas asigna fuera del asignador de Python y
`tracemalloc` no lo ve. La fila «solo importar» es la línea base: un proceso que importa pandas
y no hace nada más.

**Competidores.** Las tres son pandas idiomático y las tres dan la misma tabla —hay una prueba
que lo verifica—. No hay hombre de paja: `apply(axis=1)` es lo que recomiendan la mitad de las
respuestas de internet, y unir antes de agregar es lo que sale solo cuando uno traduce el SQL
mentalmente.

**Resultado.**

| Variante | Mediana | p95 | Pico RSS | Sobre la línea base | Entrada |
|---|---|---|---|---|---|
| solo importar pandas | — | — | 76,9 MB | — | — |
| unir + `apply` | 286,7 ms | 295,8 ms | 131,2 MB | 54,3 MB | 17,3 MB |
| unir + máscara | 18,4 ms | 19,6 ms | 117,5 MB | 40,6 MB | 17,3 MB |
| **agregar + unir** | **11,1 ms** | **11,5 ms** | **107,3 MB** | **30,4 MB** | 10,4 MB |

81.274 cuotas de entrada, 20 filas de salida.

```bash
uv run --with pandas==3.0.5 python bench_merge.py --datos data
```

> ⚖️ **Veredicto.** Quitar el `apply` es el cambio más rentable que existe en pandas: **15,6× en
> tiempo** por una línea, y ninguna pérdida de legibilidad. Cambiar el orden —agregar y después
> unir— agrega otro **1,7×**, para un total de **26×** contra la versión ingenua, y sobre todo
> **baja la memoria del trabajo casi a la mitad** (54,3 → 30,4 MB sobre la línea base), que es lo
> que decide si el informe corre o no en la máquina virtual de dos núcleos de Áurea.
>
> **Y el umbral, dicho honestamente: a este tamaño nada de esto importa.** Son 287 ms contra 11,
> una vez al mes, en un informe que Marcela lee tomando café. La diferencia se vuelve una
> decisión cuando el informe entra al cierre nocturno de la Fase 15 y compite por la ventana, o
> cuando alguien lo corre por sede y por mes en un bucle y multiplica por 270. Lo que sí importa
> a cualquier tamaño es `validate=`: eso no es rendimiento, es corrección.
>
> **Los 76,9 MB de la línea base son el número incómodo de la tabla.** El informe entero maneja
> 10 MB de datos y el proceso pesa cien. Para un script mensual da igual; para un contenedor que
> atiende peticiones, no, y es una de las razones por las que `ds03` existe.

> 📝 **Lo que esta medición no dice.** No mide lectura de disco —`read_csv` está fuera del
> cronómetro, deliberadamente, porque es igual para las tres—. No mide a escalas mayores que las
> de Áurea: los 81.274 registros son los de verdad, y extrapolar de aquí a diez millones sería
> exactamente lo que el curso no hace. Y no compara contra SQL: la misma pregunta contra
> Postgres, que ya tiene estos datos desde la Fase 11, es la primera fila de la tabla de `ds03`.

---

## 🧱 7. Miniproyecto — La cartera de Yuli, por tramos

**El encargo.** Yuli lleva la cartera y te dice: *"Necesito saber cuánto me deben y desde
cuándo. No me sirve el total: necesito cuatro columnas —al día, 1 a 30 días, 31 a 90, más de
90— por sede, y una lista de los veinte planes con más plata vencida. Y lo necesito igual todos
los meses, para poder comparar con el mes pasado."*

**Por qué duele.** Porque "vencido" no es una columna: es una comparación entre una fecha
programada y **una fecha de corte** que tú tienes que elegir, y esa elección es la mitad del
problema. La otra mitad es que la cuota no pagada no tiene fecha de pago, así que el tramo hay
que calcularlo sobre la fecha programada de las filas ausentes, y el instinto de filtrar por
`fecha_pago` deja fuera justo las que importan.

**Datos de entrada.** El conjunto del Embudo: `cuotas.csv`, `planes_de_tratamiento.csv` y
`leads.csv`. Regenéralo con `python ../ds01-numpy-y-el-modelo-vectorizado/generar_embudo.py
--salida data` si no lo tienes. El caso sucio está en los datos y es este: **hay cuotas pagadas
después de su fecha programada**. Pagar tarde y no pagar son cosas distintas y la cartera
solo debe contar las segundas — pero el informe del mes pasado sí contaba algunas de las
primeras, y parte del encargo es que los dos números se puedan comparar.

**Criterios de aceptación.**

1. `python cartera.py --corte 2026-03-31` imprime la tabla por sede con las cuatro columnas de
   tramo, en pesos, más el total. El `--corte` es **obligatorio**: el programa falla con un
   mensaje útil si no se lo das.
2. `--top 20` imprime los veinte planes con más saldo vencido, con su sede, su interés y los
   días del tramo más viejo.
3. Todo `merge` del programa lleva `validate=`, y hay al menos uno donde el valor no es `"1:1"`.
   Explica en un comentario por qué ese lleva otro.
4. El programa no usa `apply` con `axis=1` en ninguna parte. Ni uno.
5. Dos corridas con el mismo `--corte` producen **exactamente el mismo texto**, comprobable con
   `diff`. Esto implica que no hay `datetime.now()` en ninguna parte y que el orden de todas las
   tablas es explícito.
6. Una prueba compara tu total vencido contra la suma directa de las cuotas no pagadas con fecha
   programada anterior al corte. Los dos números coinciden al peso.
7. Reportas el tiempo y el pico de RSS de tu informe con el arnés de la sección 5.4.

**Restricciones de registro.** Script: un archivo, `argparse`, `uv run`, pandas y biblioteca
estándar. Sin base de datos, aunque estos datos podrían estar en la de la Fase 11 — y esa
tentación es material del ejercicio 24, no del miniproyecto.

**La trampa.** Son dos y van juntas. La primera: vas a querer comparar fechas como texto.
Funciona, porque son ISO y ordenan bien alfabéticamente, hasta que una columna tiene ausentes y
la comparación de un ausente contra una cadena te devuelve `False` en vez de fallar — y las
cuotas impagadas desaparecen de tu cartera en silencio. La segunda: el tramo de días se calcula
restando fechas, y restar dos columnas de texto no da días, da una excepción o, peor, algo.

**Pistas.**

<details><summary>Pista 1 — el enfoque</summary>

El informe tiene exactamente dos decisiones: qué filas cuentan como deuda, y a qué tramo va cada
una. La primera es una máscara; la segunda es asignar cada fila a un intervalo. Las dos se
resuelven sobre columnas enteras, sin recorrer nada.
</details>

<details><summary>Pista 2 — la herramienta</summary>

`pd.to_datetime` convierte la columna una sola vez y deja los ausentes como `NaT`. Para los
tramos, mira `pd.cut`, que reparte una columna numérica en intervalos con etiquetas: es
literalmente esta función.
[pandas.pydata.org/docs/reference/api/pandas.cut.html](https://pandas.pydata.org/docs/reference/api/pandas.cut.html)
</details>

<details><summary>Pista 3 — el esqueleto</summary>

```python
def overdue_installments(installments: pd.DataFrame, cutoff: pd.Timestamp) -> pd.DataFrame: ...
def by_branch(overdue: pd.DataFrame, plans: pd.DataFrame) -> pd.DataFrame: ...
def worst_plans(overdue: pd.DataFrame, plans: pd.DataFrame, top: int) -> pd.DataFrame: ...
```
</details>

**Cómo se entrega.**

```bash
git tag -a ds-mini-02 -m "Mini ds02: cartera por tramos · <X> ms y <Y> MB de pico sobre 81.274 cuotas"
```

---

## 🧪 8. Ejercicios (25)

**🟢 Fácil (1–6)**

1. Calcula el porcentaje cobrado por **interés** (ortodoncia contra estética) y explica en dos
   líneas por qué difieren. La respuesta está en la duración de los planes.
2. Reescribe `collected_naive` cambiando solo el `apply` por una máscara, y mide las dos con el
   arnés. Es el ejercicio más rentable de la sección.
3. Cuenta cuántos planes tienen al menos una cuota sin pagar, y cuántos tienen más de cinco. Los
   segundos son los abandonos.
4. Corre `df.info()` y `df.memory_usage(deep=True)` sobre `cuotas.csv` leído de las dos formas
   —crudo y con `usecols` más dtypes— y explica cada fila de la diferencia.
5. Provoca el `ChainedAssignmentError` a propósito, léelo entero, y escribe la versión correcta
   con `.loc`.
6. Agrupa las cuotas por mes de `fecha_programada` usando `astype("datetime64[M]")` y cuenta
   cuántas hay por mes. El resultado tiene la forma de la estacionalidad de Áurea.

**🟡 Intermedio (7–14)**

7. Añade una cuarta variante al `bench_merge.py`: agregar y unir, pero **sin** dtypes ni
   `usecols`. Aísla cuánto de la mejora era el orden y cuánto era la lectura.
8. Une `etapas.csv` con `toques.csv` por `lead_id` sin `validate=` y cuenta las filas. Después
   calcula ese número **antes** de correrlo, a partir de los conteos por lead. Tienen que
   coincidir.
9. Usa `df.query()` para el filtro de cuotas pagadas y mídelo contra la máscara booleana.
   Explica el resultado: `query` tiene que parsear una cadena.
10. Convierte el informe a `groupby(..., observed=False)` con columnas `category` y explica por
    qué aparecen filas que no existen en los datos.
11. Reproduce la alineación automática: toma `cobrado_cop` de un plan que existe y
    `comprometido_cop` de otro conjunto que no lo tiene, divídelas, y explica el `NaN`.
12. Escribe el informe con `pd.merge` y con `df.join`, y explica qué hace diferente `join` con el
    índice. Decide cuál dejarías y por qué.
13. Una columna de enteros con un ausente se convierte en flotante. Provócalo con `valor_cop`,
    míralo, y arréglalo con el tipo nulable `Int64`. Explica el costo del arreglo.
14. Mide el informe con `tracemalloc` y con `ru_maxrss` sobre el mismo trabajo, y cuantifica
    cuánto no ve `tracemalloc`. Es la justificación de la sección 5.4, comprobada por ti.

**🟠 Difícil (15–21)**

15. Diagnóstico: alguien entregó un informe de cobranza que da 4% más alto que el tuyo. La causa
    es un `how="outer"` donde debía ir `how="left"`. Reprodúcelo, y escribe la prueba que lo
    habría atrapado.
16. El `merge` catastrófico por `canal` produce 351.979.120 filas. **No lo corras**: calcula el
    número desde los conteos, estima la memoria, y después escribe la versión correcta de esa
    pregunta —gasto y leads por canal y mes— y mídela.
17. Toma las 81.274 cuotas y construye el informe sin pandas, con el `csv` y diccionarios de la
    Fase 06. Mide las dos. La pregunta interesante no es cuál gana, es cuántas líneas cuesta cada
    una y cuál entenderías dentro de un año.
18. Implementa el informe con `pivot_table` en vez de `groupby` y decide si lo dejarías. La
    sección 3 dice que `pivot_table` está fuera del curso; discútelo con tu resultado delante.
19. Haz que el informe falle ruidosamente si `cuotas.csv` trae un `plan_id` que no existe en
    `planes_de_tratamiento.csv`, y decide si eso debería ser un error o una fila "sin plan".
    Justifica con la operación de Áurea, no con la ingeniería.
20. **De registro.** Yuli quiere este informe todos los lunes y quiere poder pedir "el de hace
    tres meses". ¿Sigue siendo un script? Decide, y sostén la decisión con el costo de las otras
    dos opciones.
21. Mide el informe sobre el conjunto generado con `--escala 10` (unos 800.000 registros de
    cuotas) y compara la relación entre las tres variantes con la de la tabla de la sección 6. Si
    la relación cambió, eso es el hallazgo.

**🔴 Muy difícil (22–25)**

22. **Defiende lo contrario.** Construye el caso donde `apply(axis=1)` es la decisión correcta en
    Áurea: una regla de negocio que de verdad no se vectoriza. Tiene que ser realista, y tienes
    que decir cuánto cuesta.
23. Los 76,9 MB de la línea base son el precio de importar pandas. Mide cuánto de eso es pandas y
    cuánto sus dependencias, y escribe en cinco líneas en qué situación de Áurea ese número
    descalifica a pandas frente a la biblioteca estándar.
24. La misma pregunta contra Postgres, que ya tiene estos datos desde la Fase 11: escribe el SQL,
    mide de punta a punta —incluida la red local— y compáralo con la fila ganadora de la tabla.
    Este ejercicio es la entrada de `ds03`: tráelo con tus condiciones.
25. **De registro.** Toma el informe y decide dónde debería vivir en la arquitectura de Áurea:
    script de Marcela, comando de `aur`, endpoint de AgendaAPI o tarea del cierre nocturno de la
    Fase 15. Defiende **una**, con el costo de las otras tres y con el número de la sección 6 en
    la mano.

**🔥 Opcionales**

- Lee el informe con `pd.read_csv(..., engine="pyarrow")` y mide. Es un anticipo de `ds03`.
- Reescribe `finish` para que devuelva la tabla en formato Markdown y pégala en un correo. Es
  media hora y es lo que Marcela va a pedir de todos modos.

---

## 📚 9. Referencias

**Documentación oficial**

- [https://pandas.pydata.org/docs/user_guide/10min.html](https://pandas.pydata.org/docs/user_guide/10min.html)
  — la introducción oficial. Dura más de diez minutos.
- [https://pandas.pydata.org/docs/user_guide/copy_on_write.html](https://pandas.pydata.org/docs/user_guide/copy_on_write.html)
  — **la página que hay que leer** si vienes de pandas 1.x, y la que explica por qué el
  `SettingWithCopyWarning` ya no existe.
- [https://pandas.pydata.org/docs/user_guide/merging.html](https://pandas.pydata.org/docs/user_guide/merging.html)
  — `merge`, `join` y `concat`, con la sección de `validate=` que casi nadie lee.
- [https://pandas.pydata.org/docs/user_guide/groupby.html](https://pandas.pydata.org/docs/user_guide/groupby.html)
  — el modelo *split-apply-combine*, que es el que hay que tener en la cabeza.
- [https://pandas.pydata.org/docs/user_guide/scale.html](https://pandas.pydata.org/docs/user_guide/scale.html)
  — qué hacer cuando el DataFrame deja de caber. Su primera recomendación es cargar menos
  columnas, que es el `usecols` de la sección 5.1.
- [https://pandas.pydata.org/docs/whatsnew/v3.0.0.html](https://pandas.pydata.org/docs/whatsnew/v3.0.0.html)
  — las notas de la versión 3.0, con la lista de lo que cambió de comportamiento.

**Libros / artículos**

- *Python for Data Analysis*, de Wes McKinney —el autor de pandas—, tiene edición libre en línea.
  Está escrito para 1.x en buena parte: útil para el modelo mental, desactualizado en los
  detalles de copia y de tipos. Verifica el título y la URL antes de citarlo.

**Orden de lectura sugerido.** Antes de escribir código: *10 minutes* y la página de `groupby`.
Durante: *merging*, cuando aparezca el primer `merge`. Después, y no es opcional si vas a
mantener código ajeno: *copy on write* y las notas de 3.0.

> ⚠️ Las URLs, títulos y contenidos pueden haber cambiado; verifícalos. Aquí no se citan números
> de página ni ISBN que no se hayan comprobado.

---

## 🚀 10. Cierre y conexión con la siguiente sección

Terminas con el informe que separa lo vendido de lo cobrado, con `validate=` en todos los
`merge`, y con una regla que vale más que la biblioteca: **agrega hasta la granularidad de la
respuesta antes de unir**. También terminas con dos números incómodos: el proceso pesa 76,9 MB
antes de leer un solo dato, y el informe entero maneja 10 MB.

Esos dos números son la entrada de `ds03`. Porque hay una pregunta que esta sección no puede
contestar: **¿por qué estás cargando 81.274 filas en memoria para producir veinte?** Un motor
que mire la consulta completa antes de ejecutarla podría no leer las columnas que no usas, no
materializar el `merge` intermedio y no traer a memoria las filas que el filtro va a descartar.
Eso es un plan de ejecución, lo tiene tu base de datos desde siempre, y lo tienen Polars y
DuckDB sobre archivos.

`ds03` los pone a los cuatro a competir —pandas, Polars, DuckDB y el bucle a mano de `ds01`—
sobre la misma pregunta y a cuatro tamaños. Y trae la conclusión más incómoda del track, que ya
está anunciada: **a la escala de Áurea, puede que ninguno de los tres valga la dependencia**.

> **La señal de que quedó bien:** cuando escribas un `merge` y tu mano ponga `validate=` sin
> pensarlo, y cuando ante un informe lento tu primera pregunta sea *"¿en qué orden estoy uniendo
> y agregando?"* en vez de *"¿qué función de pandas me falta?"*.

> 🏷️ **No cierres la sección sin el tag.** Con el checklist de la sección 2 en verde, el
> miniproyecto corriendo y `git status` limpio:
>
> ```bash
> git tag -a ds-fase-02 -m "ds02 cerrada: <el checklist, en una línea por ítem>"
> ```
>
> Los commits de la sección llevan su prefijo (`ds 02: …`), los de ejercicio su número
> (`ds 02 ej12: …`) y el miniproyecto el suyo (`ds 02 mini: …`). El miniproyecto terminado lleva
> además su tag anotado `ds-mini-02`, con **el tiempo y el pico de memoria en el mensaje**. La
> convención completa está en
> [`00-convencion-de-git-y-tags.md`](00-convencion-de-git-y-tags.md).
