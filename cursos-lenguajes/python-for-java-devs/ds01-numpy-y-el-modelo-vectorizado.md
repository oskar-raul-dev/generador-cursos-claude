# 🧮 ds01 — NumPy y el modelo vectorizado

> Python para desarrolladores Java senior · Track `ds` · sección 1 de 9
> Depende de: Fase 02 (el arnés), Fase 06 (formatos), Fase 07 (`uv`) · Habilita: `ds02`
> El track `ds` **no necesita el track `ia`**: los dos arrancan desde el camino base.
> Registro de esta sección: script — un archivo, ejecutado a mano, con **una** dependencia
> Proyecto que avanza: Embudo — nace el costo por paciente adquirido

---

## 🎯 1. Propósito

Marcela lleva dos años pagando pauta en Instagram, TikTok y Google y no sabe cuánto le cuesta un
paciente. No es que no tenga los datos: los tiene, en un CSV de cuarenta y nueve mil filas que
exporta cada mes y que nadie ha sumado nunca. La primera versión de esa cuenta la vas a escribir
con un `for`, va a estar bien, y va a tardar siete milisegundos.

Esta sección es sobre **cuándo eso deja de ser suficiente, y sobre por qué la respuesta no es la
que esperas**. Al terminar vas a poder mirar un cálculo sobre datos tabulares y decir si vale la
pena vectorizarlo, con el número al lado — incluido el caso, que es frecuente, en que **la
respuesta es que no**.

> 🧭 **La pregunta que ordena la sección: ¿quién es dueño del layout de tus datos?** Si tus
> números llegan como una lista de diccionarios y se van en cuanto terminas la cuenta, vectorizar
> te va a costar más de lo que te ahorra. Si llegan en columnas y se quedan, cambia todo. El
> tamaño del dato importa mucho menos de lo que dice la fama.

---

## ✅ 2. Qué queda listo al terminar

- [ ] El conjunto del Embudo está generado y lo puedes regenerar byte a byte con la misma semilla.
- [ ] `acquisition.py` calcula el costo por paciente adquirido por canal en **tres versiones** que
      devuelven exactamente lo mismo, y tienes la prueba que lo comprueba.
- [ ] Sabes decir, sin mirar el código, qué tipo tiene cada columna del array y por qué no es
      `object`.
- [ ] Puedes explicar qué imprime `costos[:5] = 0` sobre el original, y cuándo eso es una ventaja.
- [ ] Reprodujiste el desbordamiento de `int32` **con los datos reales de Áurea** y sabes en qué
      fila ocurre.
- [ ] `bench_vectorized.py` produce la tabla de la sección 6 en tu máquina, y sabes si tu umbral
      coincide con el del curso o no.
- [ ] El miniproyecto de la sección 7 corre y cumple sus criterios de aceptación.

---

## 🚫 3. Qué NO entra todavía

- **DataFrames, índices y `join`** → `ds02`. Aquí no hay tabla: hay columnas sueltas que tú
  mantienes alineadas a mano. Ver el dolor de eso es el motivo de que `ds02` exista.
- **El modelo perezoso: Polars y DuckDB** → `ds03`, con la comparación de cuatro esquinas.
- **Los dos modelos de atribución** → `ds04`. Aquí la atribución es al último toque, a secas, y
  está mal a propósito: `ds04` demuestra que la respuesta cambia según el modelo, y para eso
  necesita que aquí haya una respuesta con la que discrepar.
- **Gráficos** → `ds05`. Todo lo de esta sección sale por `stdout` en tablas de texto.
- **Álgebra lineal, FFT, `einsum` y el resto de NumPy** → fuera del curso. Esta sección usa NumPy
  como motor de agregación sobre datos tabulares, que es el 90% de lo que un backend hace con él,
  y no pretende ser una introducción al cálculo numérico.
- **Arrays multidimensionales más allá de dos ejes** → fuera del curso, por la misma razón.

---

## 🧠 4. Concepto mínimo

### El problema, antes de la herramienta

La pauta de Áurea llega así, una fila por día, campaña y sede:

```
fecha,canal,campana,interes,sede,impresiones,clics,costo_cop
2024-01-01,instagram,ig-brackets-adolescente,ortodoncia,Centro,8926,113,160649
2024-01-01,tiktok,tt-antes-y-despues,ortodoncia,Centro,20811,481,197975
```

Y la pregunta de Marcela es una división: **cuánto gasté en cada canal, dividido por cuántos
pacientes trajo ese canal**. Con el `csv` de la Fase 06 y un diccionario acumulador, son ocho
líneas y funcionan. El resultado, sobre los datos de la red:

```
tiktok      · 11.098.164 COP por paciente adquirido   (182 pacientes)
instagram   ·  3.819.254                              (529)
google      ·  1.583.564                              (1.275)
```

Ahí ya hay material para una junta. TikTok cuesta **siete veces** lo que cuesta Google por
paciente, sobre un plan que vale entre ocho y veintidós millones — con esa tabla, la conversación
del jueves es si se apaga TikTok. Y todavía no hemos escrito una línea de NumPy. **Esto es
importante: el bucle no es el problema. El bucle es la línea base, y a este tamaño es también la
respuesta correcta.**

> ⚠️ **Y esa tabla, que es correcta, probablemente es mentira.** Los 182 pacientes de TikTok son
> los que tenían a TikTok como **último** toque antes de aceptar el plan. Si el paciente descubrió
> Áurea en un video, lo pensó dos meses y al final buscó *"ortodoncia Bogotá"* en Google, esta
> cuenta le da el mérito entero a Google. `ds04` calcula la misma tabla con el primer toque y le
> da vuelta al ranking. No lo arreglamos aquí: lo dejamos anotado, porque la lección de esta
> sección es de motor y la de `ds04` es de método.

El problema aparece cuando la misma cuenta hay que hacerla por canal, por sede y por mes, y
después otra vez con otro modelo de atribución, y después sobre tres años de historia en vez de
dos. Entonces las ocho líneas se convierten en tres bucles anidados y los siete milisegundos se
multiplican por las 1.620 combinaciones que Marcela quiere ver.

### Qué es un `ndarray`, en términos operativos

Una lista de Python es un bloque de **punteros**: cada elemento es un objeto completo en otra
parte de la memoria, con su contador de referencias, su tipo y su valor. Sumar un millón de ellos
significa un millón de saltos de puntero, un millón de comprobaciones de tipo y un millón de
asignaciones de objetos intermedios.

Un `ndarray` es un bloque de **valores**: `n` enteros de 64 bits, contiguos, sin objetos, sin
punteros, sin tipo por elemento —el tipo lo tiene el array entero, una vez—. Sumarlo es un bucle
en C sobre memoria contigua que el procesador puede leer de a varios a la vez.

```python
import sys
import numpy as np

numbers = list(range(1_000_000))          # 8 MB de punteros + ~28 MB de objetos int
array = np.arange(1_000_000, dtype=np.int64)   # 8 MB, y ya

print(sys.getsizeof(numbers) / 1e6)       # ~8.0 MB, y MIENTE: no cuenta los objetos
print(array.nbytes / 1e6)                 # 8.0 MB, y no miente
```

Esa segunda línea es media sección: `getsizeof` sobre una lista devuelve el tamaño del bloque de
punteros, no el de las cosas apuntadas. El array sabe exactamente cuánto ocupa porque **no hay
nada apuntado**.

### El dtype no es una anotación, es la memoria

En Java, `long[]` y `List<Long>` son cosas distintas y lo sabes desde el primer día: una es
memoria plana de primitivos y la otra es un contenedor de objetos con boxing. **NumPy te devuelve
esa distinción, que Python te había quitado.** Y con ella te devuelve lo que venía en el paquete:

```python
spend = np.array([2_000_000_000, 2_000_000_000], dtype=np.int32)

print(spend + spend)              # [-294967296 -294967296] ¬ ni excepción, ni aviso, ni nada
print(spend.sum())                # 4000000000, correcto: `sum` acumula en int64 por su cuenta
print(spend.sum(dtype=np.int32))  # -294967296, porque se lo pediste
```

Las tres líneas juntas son la lección, y la del medio es la que confunde: **`sum` te protege y el
`+` no**. NumPy elige un acumulador más ancho para las reducciones, así que la suma "simple" suele
salir bien mientras la aritmética elemento a elemento se desborda en silencio. Depender de esa
cortesía es mala idea: desaparece en cuanto alguien escriba `dtype=` para ahorrar memoria.

El primer número está mal y nadie te lo dijo. Es exactamente lo que hace `int` en Java, y exactamente
lo que **no** hace `int` en Python, donde los enteros crecen hasta que se acaba la memoria. Si
llevas once años en la JVM ya tienes el reflejo de pensar en rangos; lo que tienes que recuperar
es *acordarte de que aquí vuelve a aplicar*, después de años de que no aplicara.

### Broadcasting: la regla que reemplaza al bucle interno

Cuando una operación mezcla dos arrays de formas distintas, NumPy estira el más pequeño en vez de
fallar:

```python
cost = np.array([160_649, 197_975, 476_711], dtype=np.int64)

cost * 2                  # escalar contra vector: el 2 se "estira" a los tres
cost / cost.sum()         # la fracción de cada uno, sin dividir uno por uno
```

La regla completa es corta: dos formas son compatibles si, comparadas de derecha a izquierda,
cada par de dimensiones es igual o una de las dos es 1. Es todo. Y donde te va a morder es donde
**no falla**: dos arrays de 1.000 y de 1 se combinan sin protestar aunque tu intención fuera que
el segundo tuviera 1.000 y se te haya quedado en uno por un filtro anterior.

### Tu instinto de Java dice… y esta vez se equivoca

Tu instinto **no** es escribir un bucle malo. Ese es el instinto de otro perfil. El tuyo es
escribir un bucle **correcto, legible y defendible**:

```python
# ❌ El reflejo. No tiene ni un error. En Java sería la versión que gana.
total: dict[str, int] = {}
for row in rows:
    channel = row["canal"]
    total[channel] = total.get(channel, 0) + int(row["costo_cop"])
```

En la JVM esto lo compila el JIT a algo muy parecido a lo que escribirías a mano, y cualquier
intento de "vectorizarlo" con streams te daría lo mismo o peor. **Aquí no.** Aquí cada vuelta del
bucle es un `dict.__getitem__`, un `int()` que construye un objeto nuevo, una búsqueda de hash y
un almacenamiento — todo interpretado.

```python
# ✅ La suma agrupada, en una llamada. `bincount` con pesos ES un GROUP BY por clave entera.
totals = np.bincount(channel_codes, weights=cost.astype(np.float64),
                     minlength=len(channels))
```

Y ahora la parte que casi ningún material dice: **la versión de arriba solo gana si
`channel_codes` y `cost` ya existen**. Construirlos desde la lista de diccionarios cuesta más que
todo el bucle. La sección 6 lo mide, y el resultado es incómodo.

> ⚰️ **Autopsia del anti-patrón intermedio.** Entre el bucle y el vectorizado hay una versión que
> este perfil escribe en cuanto le dicen que "los bucles son lentos en Python": la comprehension
> por canal.
>
> ```python
> {channel: sum(int(r["costo_cop"]) for r in rows if r["canal"] == channel) / acquisitions[channel]
>  for channel in {r["canal"] for r in rows}}
> ```
>
> Es más corta, parece más pythónica, y **recorre la lista una vez por canal**: seis pasadas donde
> el bucle hacía una. Medida sobre un millón de filas: **273 ms contra los 150 ms del bucle, un
> 82% más lenta**. "Más pythónico" no es una unidad de medida, y esta es la demostración más
> barata que tiene el curso.

### Esto sí funciona igual

- **Pensar en layout de memoria.** Si ya razonabas sobre `long[]` contra `List<Long>`, cache
  lines y localidad, ese músculo sirve tal cual. Es más: es exactamente el músculo que hace falta,
  y el resto de Python te lo había dejado atrofiar.
- **El desbordamiento de enteros.** `np.int64` es `long`. Mismos 64 bits, mismo silencio al
  desbordar, mismo `Integer.MAX_VALUE` que hay que tener en la cabeza.
- **El orden de magnitud del algoritmo.** Vectorizar no cambia la complejidad: un `O(n²)`
  vectorizado sigue siendo `O(n²)`, solo que con una constante mucho menor. El día que la
  constante deje de alcanzar, el problema va a ser el mismo que sería en Java.
- **Medir antes de optimizar.** El arnés de la Fase 02 se usa aquí sin cambiarle una línea.

### Diccionario de traducción

| Java | NumPy | Dónde se rompe el paralelo |
|---|---|---|
| `long[]` | `np.ndarray` de `int64` | El array de NumPy conoce su forma y su tipo en tiempo de ejecución, y cambia de tipo solo al operar (NEP 50) |
| `List<Long>` | `list[int]` de Python | La lista de Python no tiene tipo declarado, así que puede tener un `str` en la posición 700 y no enterarte hasta ahí |
| `Arrays.copyOfRange(a, 1, 3)` | `a[1:3].copy()` | Sin el `.copy()` **no copia**: devuelve una vista que escribe sobre el original |
| `list.subList(1, 3)` | `a[1:3]` | El paralelo es bueno, y se rompe en que en NumPy también son vistas el `reshape`, la transposición y muchos `astype` |
| `IntStream.of(a).sum()` | `a.sum()` | El stream recorre objetos; `a.sum()` recorre bytes. La diferencia es de uno a dos órdenes de magnitud |
| `Collectors.groupingBy` | `np.bincount(codes, weights=…)` | Solo sirve si las claves ya son enteros pequeños y contiguos. Con claves de texto hay que codificarlas antes, y eso cuesta |
| `int` (32 bits, desborda) | `np.int32` | Igual. El que **no** se parece es el `int` de Python, que no desborda nunca |
| `ArithmeticException` | nada | NumPy no lanza al desbordar. Lo más parecido es `np.errstate`, y hay que pedirlo |

> 📝 **Nota de ecosistema.** NumPy 2.0 (2024) fue una ruptura de verdad, y el código que vas a
> encontrar por internet está escrito para 1.x. Dos cambios que te van a morder: **NEP 50** cambió
> las reglas de promoción de tipos, de modo que `np.int32(5) + 5` ya no promueve a `int64` según
> el valor sino según el tipo — más predecible y distinto de lo que dicen los tutoriales viejos—;
> y desaparecieron alias como `np.float_`, `np.unicode_` y, un par de versiones antes,
> `np.int`/`np.float`/`np.bool`, que durante años fueron la forma "corta" de escribir esto. El
> curso fija **NumPy 2.5.3** y todo lo de aquí asume las reglas nuevas.

---

## 💻 5. Código mínimo con comentarios

El registro es **script**: un archivo por cosa, `uv run` para ejecutarlo, sin capas, sin
configuración y sin clases más allá de un `dataclass` que agrupa columnas. Lo único que cambia
respecto al Bloque A es que ahora hay **una** dependencia, y se declara.

```bash
uv run --with numpy==2.5.3 python acquisition.py
```

> 🧭 **Una dependencia es una decisión, no un detalle.** El camino base llegó hasta la Fase 06 sin
> instalar nada. NumPy entra aquí porque hace algo que la biblioteca estándar no hace —aritmética
> sobre bloques de memoria tipada—, y entra con su versión exacta. Si alguna vez te descubres
> agregando NumPy para sumar doscientos números, ese es el reflejo contrario y cuesta igual.

### 5.1 Las columnas, y por qué la fila deja de existir

```python
# src/ds01-numpy-y-el-modelo-vectorizado/acquisition.py

@dataclass(frozen=True, slots=True)
class SpendArrays:
    """La pauta como columnas, no como filas.

    Es el cambio de modelo mental de la sección: una lista de diccionarios es una lista de
    objetos con sus campos; esto son tres bloques de memoria contigua, cada uno de un solo
    tipo. La fila deja de existir como cosa.
    """

    channel_codes: np.ndarray   # int64, índice dentro de `channels`
    cost: np.ndarray            # int64, pesos
    clicks: np.ndarray          # int64
    channels: list[str]         # el diccionario de códigos, en orden
```

Ese `channels: list[str]` al lado de tres arrays es la primera incomodidad del modelo, y conviene
sentirla entera: **nada garantiza que los cuatro sigan alineados**. Si filtras `cost` y te olvidas
de filtrar `channel_codes`, no pasa nada malo hoy y todo sale mal mañana. En una tabla de verdad
—la de `ds02`— el índice mantiene esa alineación por ti; aquí la mantienes tú.

```python
def arrays_from_rows(rows: list[dict[str, str]]) -> SpendArrays:
    channels = sorted({row["canal"] for row in rows})
    index = {channel: code for code, channel in enumerate(channels)}

    return SpendArrays(
        # `fromiter` con `count` asigna el bloque UNA vez. La alternativa cómoda,
        # `np.array([...])`, construye antes la lista completa de Python y paga dos veces
        # la memoria: es el reflejo que esta sección ataca, cometido al cargar los datos.
        channel_codes=np.fromiter((index[row["canal"]] for row in rows),
                                  dtype=np.int64, count=len(rows)),
        cost=np.fromiter((int(row["costo_cop"]) for row in rows),
                         dtype=PESOS, count=len(rows)),
        clicks=np.fromiter((int(row["clics"]) for row in rows),
                           dtype=np.int64, count=len(rows)),
        channels=channels,
    )
```

**Detalles con intención**

- **`count=len(rows)`** — sin él, `fromiter` no sabe cuánto reservar y crece el bloque por
  duplicación, como un `ArrayList`. Con él, una sola asignación.
- **Los canales se codifican a enteros** en vez de guardarse como texto. Un array de cadenas en
  NumPy es de ancho fijo (`<U9`) o, peor, de tipo `object` — que son punteros otra vez, y ahí se
  acabó la ventaja.
- **`sorted(...)`** y no el orden de aparición: el código de un canal no puede depender de qué
  filas te tocaron, o dos corridas sobre recortes distintos dejan de ser comparables.
- **El dinero es `int64` y no `Decimal`**, contra la regla general del curso (guía §6.6). La
  excepción se declara en el código: esto es gasto publicitario agregado, que nadie factura. En
  una cuota de ortodoncia repartida entre tres profesionales, `Decimal` y no se discute.

### 5.2 El bucle, que se queda

```python
def cost_per_acquisition_loop(rows, acquisitions):
    """El reflejo: un bucle correcto, legible, y el que cualquiera aprobaría en revisión."""
    total: dict[str, int] = {}
    for row in rows:
        channel = row["canal"]
        total[channel] = total.get(channel, 0) + int(row["costo_cop"])
    return {channel: spent / acquisitions[channel]
            for channel, spent in total.items() if acquisitions.get(channel)}
```

Esta función **no se borra al final de la sección**. Se queda en el archivo, se queda en las
pruebas, y es contra ella que se mide todo lo demás. Un curso que presenta el bucle solo para
ridiculizarlo te deja sin línea base y sin criterio.

El `if acquisitions.get(channel)` del final tampoco es defensivo por costumbre: un canal con
gasto y cero pacientes adquiridos existe de verdad en los datos de Áurea, y dividir por cero en
NumPy **no lanza** — devuelve `inf` y sigue. Un infinito en una tabla que ve Marcela es peor que
un error.

### 5.3 La suma agrupada, en una llamada

```python
def cost_per_acquisition_vectorized(spend, acquisitions):
    # `minlength` evita que el resultado se acorte si el último canal no aparece en el
    # recorte de datos: sin él, el vector devuelto cambia de tamaño según los datos y el
    # `zip` de abajo se desalinea en silencio. Es un error que no levanta excepción.
    totals = np.bincount(spend.channel_codes,
                         weights=spend.cost.astype(np.float64),
                         minlength=len(spend.channels))
    return {channel: float(total) / acquisitions[channel]
            for channel, total in zip(spend.channels, totals, strict=True)
            if acquisitions.get(channel)}
```

`np.bincount` es la pieza que hay que memorizar de esta sección. Sin `weights` cuenta cuántas
veces aparece cada código; con `weights` **suma los pesos por código**, que es un `GROUP BY`
completo en una llamada. Su límite es igual de importante: solo funciona si las claves son
enteros no negativos y pequeños, porque reserva un hueco por cada valor entre 0 y el máximo. Con
códigos de sede (0–9) o de canal (0–5) es perfecto; con documentos de identidad como clave,
reservarías mil millones de huecos.

**Detalles con intención**

- **`weights` fuerza `float64`.** `bincount` devuelve flotantes cuando hay pesos, siempre. Sumar
  seis mil millones de pesos en `float64` es exacto —hasta 2⁵³ lo es—, pero conviene saber que el
  tipo cambió: `strict=True` en el `zip` existe por la misma familia de errores.
- **`strict=True`** es de Python 3.10 y aquí gana su sueldo: si `channels` y `totals` dejan de
  tener el mismo largo, el `zip` corta en silencio por el más corto y te devuelve una tabla
  incompleta que parece correcta.

**El patrón a memorizar**
> Codifica las claves a enteros, agrupa con `bincount`, y quédate con el diccionario de códigos
> al lado. Es el 80% de las agregaciones que hace un backend, y es lo que un DataFrame hace por
> dentro cuando le pides un `groupby`.

### 5.4 Vistas y copias: la primera sorpresa

```python
view = spend.cost[:5]     # NO es una copia
view[:] = 0               # y esto escribe sobre el original
print(spend.cost[:5])     # [0 0 0 0 0]

copy = spend.cost[:5].copy()
copy[:] = 0
print(spend.cost[:5])     # los valores originales, intactos
```

Para quien viene de copias defensivas, esto es incómodo el primer día y es la razón de que NumPy
sea rápido: un corte de un array de cinco millones de elementos cuesta nanosegundos porque no
mueve un solo byte. `subList` de Java se comporta igual, así que el paralelo abre la puerta. Y se
rompe enseguida: en NumPy también devuelven vistas el `reshape`, la transposición y el corte por
pasos, y **no hay nada en el tipo que distinga una vista de un array propio**. La forma de
preguntarlo es `array.base`, que es `None` cuando el array es dueño de su memoria.

> ⚠️ **La consecuencia que muerde de verdad** no es que modifiques el original sin querer: es al
> revés. Si te quedas con `subset = big_array[:100]` para no cargar el resto, **el bloque grande
> no se libera**, porque tu vista lo mantiene vivo. Cien elementos que retienen cuarenta megas.
> Ahí `copy()` no es paranoia, es lo correcto.

### 5.5 El experimento que rompe a propósito

```python
def total_spend_with_dtype(spend, dtype):
    return int(np.sum(spend.cost.astype(dtype), dtype=dtype))
```

Con los datos reales de la red —cuarenta y nueve mil filas de pauta, dos años y tres meses—:

```
int64:  6.059.295.284 COP    ← correcto
int32:  1.764.327.988 COP    ← incorrecto, y nadie avisó
```

El desbordamiento ocurre en la **fila 18.205 de 49.260**: no es un caso de laboratorio, es la
mitad del archivo de Marcela. Y no hay excepción, ni advertencia, ni `nan`: hay un número
plausible, con la magnitud equivocada, en una tabla que alguien va a llevar a una junta.

**Prueba de fuego**

```bash
uv run --with numpy==2.5.3 --with pytest pytest test_acquisition.py -q
```

Nueve pruebas, y la que importa es `test_las_tres_versiones_dan_la_misma_respuesta`. Si algún día
falla, la tabla de la sección 6 deja de significar algo: estarías comparando tres programas
distintos y llamándolo benchmark.

La mentira que te va a contar la salida si miras el lugar equivocado: el `pico` de memoria del
bucle sale en **0.00 MB** en todas las filas de la tabla. No es que el bucle no use memoria — es
que la lista de diccionarios ya estaba asignada antes de empezar a medir, y `tracemalloc` solo ve
lo que se asigna durante la ejecución. Esa columna mide lo que **cuesta calcular**, no lo que
cuesta **tener los datos**. Lo segundo es el tema de `ds02`.

---

## 📏 6. Medición

**Hipótesis.** Vectorizar la suma agrupada le gana al bucle por al menos un orden de magnitud a
partir de unas decenas de miles de filas, **y el umbral en el que conviene hacerlo es mucho más
alto que eso** — porque el costo de convertir la lista de diccionarios en columnas se paga entero
y se paga cada vez.

**Condiciones.** CPython 3.14.5, NumPy 2.5.3, macOS 26.6.2 sobre Apple Silicon de 8 núcleos —el
entorno de referencia del curso—. Datos: `pauta.csv` del generador del Embudo, semilla 20260913,
49.260 filas reales. Los tamaños mayores son **el bloque real repetido**, porque Áurea no tiene
cinco millones de filas de pauta: lo que se mide ahí es el motor, no el negocio, y la cuenta da
lo mismo porque repetir el bloque no cambia el reparto por canal. Cinco repeticiones hasta el
millón de filas y tres a cinco millones, con el arnés de la Fase 02 —mediana, p95 y pico de
`tracemalloc`—. Las cuatro versiones corren **sobre las mismas filas en memoria**, no sobre cuatro
lecturas del CSV.

**Competidores.** El bucle de la sección 5.2, que es código que cualquiera aprobaría en una
revisión; la comprehension por canal, que es lo que este perfil escribe cuando le dicen que los
bucles son lentos; y las dos formas de contar el vectorizado: **con las columnas ya construidas**
y **pagando la conversión**. Publicar solo la primera sería comparar una función contra un
programa.

**Resultado.**

| Filas | bucle | comprehension | vectorizado | vectorizado + conversión |
|---|---|---|---|---|
| 1.000 | 0,128 ms | 0,196 ms | **0,007 ms** | 0,276 ms |
| 10.000 | 1,286 ms | 1,997 ms | **0,049 ms** | 2,840 ms |
| 100.000 | 14,8 ms | 29,9 ms | **0,526 ms** | 38,2 ms |
| 1.000.000 | 150 ms | 273 ms | **4,86 ms** | 395 ms |
| 5.000.000 | 787 ms | 1.387 ms | **24,2 ms** | 1.865 ms |

Pico de memoria del cálculo: 0,00 MB el bucle y la comprehension, 40 MB el vectorizado a cinco
millones de filas (8 bytes × 5M, que es exactamente la columna `float64` que crea `bincount`).

```bash
uv run --with numpy==2.5.3 python bench_vectorized.py --filas 1000 10000 100000 1000000 5000000
```

> ⚖️ **Veredicto.** Sobre columnas ya construidas, el vectorizado gana **32× a cinco millones de
> filas** y 18× a mil: la ventaja está desde el primer tamaño y crece. Pero **si hay que convertir
> desde la lista de diccionarios, vectorizar pierde en los cinco tamaños**, y a cinco millones
> pierde por 2,4×. No hay umbral de filas que salve esa cuenta, porque la conversión es `O(n)` con
> una constante peor que la del propio bucle: recorrer un millón de diccionarios para sacar
> enteros cuesta más que sumarlos de una vez.
>
> **El umbral real no es de tamaño, es de reúso:** vectorizar paga cuando la conversión se
> amortiza entre **tres o más operaciones** sobre las mismas columnas. La cuenta es directa: a
> cinco millones de filas la conversión cuesta 1.840 ms y cada agregación posterior 24 ms, así que
> `k` cuentas vectorizadas valen `1840 + 24k` contra los `787k` del bucle — con `k=2` gana el
> bucle (1.573 ms contra 1.889) y con `k=3` gana el array (2.360 ms contra 1.913). **Tres.** La
> otra salida es que los datos **nazcan** en columnas y nunca hayan sido diccionarios. Eso último es lo que hacen Parquet, `pandas.read_csv` y DuckDB, y es exactamente
> el tema de las dos secciones siguientes.

> 📝 **Lo que esta medición no dice.** No mide el costo de **tener** los datos en memoria —la
> tabla compara cálculos, no representaciones— y ahí la diferencia es enorme al revés: cinco
> millones de filas como diccionarios son gigas, y como cuatro columnas `int64` son 160 MB. `ds02`
> lo mide. Tampoco mide lectura de disco, que es igual para todas las opciones. Y no compara
> contra Java: sería interesante y no cabe en esta sección — queda como ejercicio 🔥 24.

---

## 🧱 7. Miniproyecto — El tablero de las tres llaves

**El encargo.** Marcela te escribe: *"Necesito el costo por paciente adquirido abierto por canal,
por sede y por mes, en una sola tabla. Y necesito saber cuánta plata se fue en días que la sede
tenía cerrada, porque sospecho que estamos pagando pauta los domingos."* Lo quiere para el comité
de franquicia del jueves, en texto, para pegarlo en el correo.

**Por qué duele.** Porque agrupar por una llave es lo que hiciste en la sección 5, y agrupar por
tres no es "lo mismo tres veces". Con seis canales, diez sedes y veintisiete meses hay 1.620
combinaciones posibles, la mayoría vacías, y la forma ingenua —un diccionario con tuplas de clave,
o tres bucles anidados— funciona con los datos de ejemplo y se cae de bruces cuando Marcela pida
lo mismo con tres años más.

**Datos de entrada.** El conjunto del Embudo, regenerado con `python generar_embudo.py --salida
data`. Necesitas `pauta.csv` para el gasto, y `leads.csv` más `etapas.csv` para las adquisiciones.
Y este caso sucio, que está en los datos y tienes que decidir qué haces con él: **hay filas de
pauta de sedes y meses donde no hubo ni una sola adquisición**. El costo por paciente ahí no es
cero ni es infinito: es una celda que significa otra cosa, y la tabla tiene que decir cuál.

**Criterios de aceptación.**

1. `python tablero.py --datos data` imprime una tabla de texto con una fila por combinación
   **con actividad** —canal, sede, mes, gasto, adquiridos, costo por adquisición— ordenada por
   costo descendente, y un pie con los totales.
2. Las combinaciones sin adquisiciones aparecen en un bloque aparte, con su gasto y la etiqueta
   explícita de que no hay denominador. No aparecen con `inf`, con `0` ni omitidas en silencio.
3. `--domingos` reporta cuánto se gastó en pauta en domingo, en pesos y como porcentaje del total.
4. La agregación completa **no usa ni un bucle de Python sobre las filas**: ni `for`, ni
   comprehension sobre `pauta.csv`. El único bucle permitido es el que imprime la tabla, que
   recorre resultados y no datos.
5. Sobre `pauta.csv` repetido hasta **dos millones de filas** (`--filas 2000000`), el cálculo
   completo tarda menos que la versión de bucle equivalente que escribas como línea base, y tu
   programa imprime las dos cifras. **Si tu versión vectorizada pierde, el entregable es esa
   medición y tu explicación de por qué** — es un resultado legítimo y esta sección acaba de
   mostrar un caso donde ocurre.
6. `pytest` corre y tienes al menos una prueba que compara tu agregación de tres llaves contra la
   misma cuenta hecha con un diccionario y tuplas, sobre un recorte pequeño. Los dos resultados
   coinciden exactamente.

**Restricciones de registro.** Esto es un **script**: un archivo, `argparse`, `uv run`, sin
capas, sin configuración, sin clases más allá de un `dataclass` que agrupe columnas. NumPy y la
biblioteca estándar, nada más — nada de pandas, que llega en `ds02` y que resuelve esto en tres
líneas. El objetivo de hacerlo a mano es que cuando `ds02` lo resuelva en tres líneas sepas
exactamente qué te está ahorrando.

**La trampa.** Vas a querer construir la clave compuesta como texto —`f"{canal}|{sede}|{mes}"`— y
agrupar sobre eso. Funciona, es legible, y convierte tu array en un array de objetos: a partir de
ahí, todo lo que hagas es un bucle de Python con sintaxis de NumPy. La salida va a ser correcta y
el criterio 5 no lo vas a pasar. La pregunta que tienes que contestar es **cómo se convierten tres
llaves en un solo entero sin perder ninguna combinación**, y la respuesta está en la documentación
de NumPy, no en esta sección.

**Pistas.**

<details><summary>Pista 1 — el enfoque</summary>

Si cada llave ya es un entero pequeño —canal de 0 a 5, sede de 0 a 9, mes de 0 a 26—, las tres
juntas son un número en base mixta, igual que una fecha es un número en base 12 y 31. Una sola
llave entera vuelve a poner el problema donde ya sabes resolverlo.
</details>

<details><summary>Pista 2 — la herramienta</summary>

`np.unique(array, return_inverse=True)` codifica cualquier columna a enteros contiguos y te
devuelve el diccionario de vuelta. `np.ravel_multi_index` combina varios índices en uno solo, y
`np.unravel_index` deshace la combinación para imprimir. Para el mes, mira `np.datetime64` con
unidad `'M'`: truncar a mes es un `astype`.
[numpy.org/doc/stable/reference/routines.indexing.html](https://numpy.org/doc/stable/reference/routines.indexing.html)
</details>

<details><summary>Pista 3 — el esqueleto</summary>

```python
def encode_keys(channels, branches, months) -> tuple[np.ndarray, tuple[int, int, int]]: ...
def aggregate(keys: np.ndarray, cost: np.ndarray, shape) -> np.ndarray: ...
def render(table: np.ndarray, dictionaries) -> str: ...
```
</details>

**Cómo se entrega.**

```bash
git tag -a ds-mini-01 -m "Mini ds01: tablero de tres llaves · vectorizado <X> ms contra bucle <Y> ms a 2M filas"
```

**El número va en el mensaje del tag**, los dos: el tuyo y el de tu línea base. Si el segundo es
menor, se escribe igual — es la medición.

---

## 🧪 8. Ejercicios (25)

**🟢 Fácil (1–6)**

1. Calcula el costo por **clic** por canal sobre `pauta.csv`, vectorizado. Compara el ranking de
   canales con el de costo por paciente adquirido: no es el mismo, y la diferencia es el tema de
   `ds04` en una línea.
2. Suma las impresiones totales de la red acumulando en `np.int32` y en `np.int64`. Reporta en qué
   fila se rompe la primera, usando `np.cumsum`.
3. Toma `spend.cost[:100]`, ponlo todo a cero y explica en una frase por qué cambió
   `spend.cost`. Después hazlo bien.
4. Convierte la columna `fecha` a `np.datetime64` y cuenta cuántas filas de pauta caen en domingo.
   El dato es entrada del miniproyecto.
5. Mide con `sys.getsizeof` una lista de 100.000 enteros y con `.nbytes` el array equivalente.
   Explica por qué la primera cifra miente y en cuánto.
6. Usa `np.bincount` sin `weights` para contar filas de pauta por canal, y compara con
   `collections.Counter` sobre las mismas filas. Mide las dos.

**🟡 Intermedio (7–14)**

7. Reescribe `cost_per_acquisition_vectorized` usando `np.add.at` en vez de `bincount` y mide las
   dos. Explica la diferencia de tiempo con lo que dice la documentación sobre `ufunc.at`.
8. `np.bincount` reserva un hueco por cada valor entre 0 y el máximo. Construye el caso que lo
   hace inviable —usa el documento del paciente como clave— y reporta cuánta memoria intentaría
   reservar antes de que tengas que matarlo. **No lo corras sin un límite.**
9. La columna `costo_cop` entra a `bincount` como `float64`. A partir de qué gasto total se
   perdería precisión, y cuántos años de pauta de Áurea harían falta para llegar ahí.
10. Agrega una cuarta versión a `bench_vectorized.py`: el bucle, pero sobre `tuple` en vez de
    `dict` por fila. Mide y explica la diferencia.
11. Usa `np.unique(..., return_counts=True)` sobre la columna de campañas y reproduce el resultado
    con un `Counter`. Mide las dos a 49.260 filas y a un millón.
12. Lee `pauta.csv` con `np.genfromtxt` y mide contra `arrays_from_rows`. Explica qué hace
    `genfromtxt` de más, y por qué el curso no lo usa.
13. Demuestra con un ejemplo de Áurea que el broadcasting **no falla** cuando debería: dos arrays
    de 10 y 1 elementos donde el segundo debería tener 10. Escribe la comprobación que lo habría
    detectado.
14. Mide el costo de `astype(np.float64)` sobre cinco millones de enteros por separado del
    `bincount`. ¿Qué porcentaje del tiempo "vectorizado" de la tabla es solo esa conversión?

**🟠 Difícil (15–21)**

15. Toma la fila "vectorizado + conversión" de la sección 6 y bájala. Objetivo: que la conversión
    cueste menos de la mitad. Pistas legítimas: leer el CSV una sola vez, evitar `int()` por
    celda, mirar `np.loadtxt` con `usecols`. Reporta el antes y el después con el arnés.
16. Diagnóstico: `src/ds01-…/ejercicio_16_lento.py` calcula el costo por adquisición, usa NumPy
    en todas partes y tarda **3.942 ms con dos millones de filas** — trece veces más que el bucle
    de la sección 5.2, que tarda 296 ms sobre los mismos datos. Encuentra las **dos** líneas que lo
    arruinan y cuantifica cada una por separado con el arnés.
17. La columna `canal` se codifica con `sorted()`. Escribe el caso donde codificar por orden de
    aparición produce dos tablas distintas para los mismos datos, y explica por qué es un error
    de reproducibilidad y no de rendimiento.
18. Implementa el filtro "solo sedes propias" de dos formas: con máscara booleana
    (`cost[mask]`) y con `np.compress`. Mide, y reporta cuál asigna memoria y cuánta.
19. Usa `np.errstate` para que la división por cero lance en vez de devolver `inf`, y decide si
    lo dejarías puesto en un script que corre Marcela. Justifica la respuesta en tres líneas.
20. **De registro.** Marcela pide este mismo tablero todos los lunes a las siete, por correo,
    para siempre. ¿Sigue siendo un script? Decide, y sostén la decisión con el costo de las otras
    dos opciones —herramienta instalable, o servicio con su tarea programada de la Fase 15—.
21. Reproduce la tabla de la sección 6 en tu máquina y compárala con la del curso. Si tu relación
    entre columnas es distinta, eso es un hallazgo: escríbelo con tus condiciones al lado.

**🔴 Muy difícil (22–25)**

22. **Defiende lo contrario.** Escribe el caso de negocio de Áurea —tamaño, frecuencia, quién lo
    corre, qué más se hace con los datos— donde **no** vectorizar es la decisión correcta, con la
    medición que lo sostiene. Tiene que ser un caso realista, no un contraejemplo de juguete.
23. El pico de memoria del bucle sale 0,00 MB en la tabla y eso es engañoso. Diseña la medición
    que sí captura el costo de **tener** cinco millones de filas en cada representación —lista de
    diccionarios, lista de tuplas, cuatro arrays— y córrela. Prepárate para esperar.
24. 🔥 Escribe la misma agregación en Java —`HashMap<String, Long>` sobre las mismas 5.000.000 de
    filas leídas de CSV— y mide contra las cuatro columnas de la sección 6, declarando el
    calentamiento del JIT. El resultado es material del curso: tráelo con sus condiciones.
25. **De registro.** El criterio 4 del miniproyecto prohíbe los bucles de Python sobre las filas.
    Argumenta si esa restricción es pedagógica o de ingeniería, y en qué caso la levantarías en un
    código de producción de Áurea. No hay respuesta correcta; hay respuestas defendibles.

**🔥 Opcionales**

- Perfila `arrays_from_rows` con `cProfile` y encuentra dónde se va el tiempo de verdad. La
  respuesta probablemente no es NumPy.
- NumPy libera el GIL en muchas operaciones. Vuelve a la Fase 14, mide la agregación con hilos, y
  comprueba si escala — es uno de los pocos casos donde los hilos ganan en Python.

---

## 📚 9. Referencias

**Documentación oficial**

- [https://numpy.org/doc/2.5/user/absolute_beginners.html](https://numpy.org/doc/2.5/user/absolute_beginners.html)
  — la introducción oficial. Fija la versión 2.5 en el selector: la documentación por defecto
  sirve la estable del día.
- [https://numpy.org/doc/2.5/user/basics.types.html](https://numpy.org/doc/2.5/user/basics.types.html)
  — los dtypes y sus rangos. Es la página del 🧨 de la sección 5.5.
- [https://numpy.org/doc/2.5/user/basics.copies.html](https://numpy.org/doc/2.5/user/basics.copies.html)
  — vistas contra copias, con la explicación de `base`.
- [https://numpy.org/doc/2.5/user/basics.broadcasting.html](https://numpy.org/doc/2.5/user/basics.broadcasting.html)
  — la regla completa, en una página.
- [https://numpy.org/doc/2.5/reference/generated/numpy.bincount.html](https://numpy.org/doc/2.5/reference/generated/numpy.bincount.html)
  — la función central de esta sección, con la advertencia sobre `minlength`.
- [https://numpy.org/doc/2.5/numpy_2_0_migration_guide.html](https://numpy.org/doc/2.5/numpy_2_0_migration_guide.html)
  — qué cambió en 2.0. Léelo antes de copiar cualquier respuesta de internet anterior a 2024.

**NEPs** (el equivalente de los PEPs en NumPy, y explican el porqué)

- [https://numpy.org/neps/nep-0050-scalar-promotion.html](https://numpy.org/neps/nep-0050-scalar-promotion.html)
  — por qué `np.int32(5) + 5` ya no hace lo que hacía. Es la ruptura que más código viejo rompió.

**PEPs**

- [https://peps.python.org/pep-3118/](https://peps.python.org/pep-3118/) — el protocolo de búfer,
  que es lo que permite que NumPy, `memoryview` y las bibliotecas de C compartan memoria sin
  copiarla. Explica por qué `ds03` va a poder pasarle datos a DuckDB sin serializar nada.

**Video / apoyo**

- Las charlas de PyData sobre memoria y layout columnar son buen material, y cambian de URL cada
  año. Búscalas por título en vez de por enlace.

> ⚠️ Las URLs, títulos y contenidos pueden haber cambiado; verifícalos. Aquí no se citan números
> de página, ISBN ni identificadores de video que no se hayan comprobado.

**Orden de lectura sugerido.** Antes de escribir código: *absolute beginners* y *basics.types*.
Durante: la página de `bincount` y la de broadcasting, cuando aparezca la duda. Después, y esto
importa: la **guía de migración a 2.0**, porque buena parte de lo que vas a encontrar buscando
respuestas está escrito para 1.x y te va a mentir con confianza.

---

## 🚀 10. Cierre y conexión con la siguiente sección

Terminas con la cuenta que Marcela llevaba dos años sin tener, con las tres versiones que la
producen y —lo que de verdad te llevas— con una tabla que dice que **vectorizar no siempre gana**.
El resultado incómodo de la sección 6 es el mejor material que produjo: la ventaja del array es
real y enorme, y se la come entera la conversión si tus datos viven como diccionarios.

Eso deja una pregunta abierta que no se puede resolver con más NumPy: **¿y si los datos nacieran
en columnas y se quedaran ahí?** Necesitarías algo que lea el CSV directo a memoria columnar, que
mantenga las columnas alineadas sin que tú las cuides una por una, y que sepa unir dos fuentes por
una llave sin que tengas que escribir el `join` a mano. Eso es un DataFrame, y es `ds02`.

También te llevas la incomodidad de haber mantenido `channels` alineado con tres arrays a pulso.
`ds02` la resuelve con el índice — y te va a cobrar esa comodidad en formas que todavía no
sospechas.

> **La señal de que quedó bien:** cuando ante un cálculo nuevo tu primera pregunta no sea *"¿esto
> lo vectorizo?"* sino *"¿de dónde vienen estos datos y cuántas cuentas más voy a hacer con
> ellos?"* — y cuando puedas decir que no vale la pena, con el número al lado.

> 🏷️ **No cierres la sección sin el tag.** Con el checklist de la sección 2 en verde, el
> miniproyecto corriendo y `git status` limpio:
>
> ```bash
> git tag -a ds-fase-01 -m "ds01 cerrada: <el checklist, en una línea por ítem>"
> ```
>
> Los commits de la sección llevan su prefijo (`ds 01: …`), los de ejercicio su número
> (`ds 01 ej12: …`) y el miniproyecto el suyo (`ds 01 mini: …`). El miniproyecto terminado lleva
> además su tag anotado `ds-mini-01`, con **los dos tiempos —vectorizado y línea base— en el
> mensaje**. La convención completa está en
> [`00-convencion-de-git-y-tags.md`](00-convencion-de-git-y-tags.md).
