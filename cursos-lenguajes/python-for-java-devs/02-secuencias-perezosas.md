# 🔁 Fase 02 ⭐ — Secuencias perezosas

> Python para desarrolladores Java senior · Fase 2 de 18 · Bloque A
> Depende de: Fase 01 · Habilita: Fase 03
> Registro de esta fase: **script** — un archivo, stdlib pura, sin clases
> Proyecto que avanza: el CLI · **y nace el arnés de medición del curso**
> Fecha de verificación de las versiones: 12/09/2026

---

## 🎯 1. Propósito

Que dejes de materializar colecciones completas, que es el hábito de Java que más caro sale en
Python.

No es una cuestión de elegancia. Es que el archivo de citas del trimestre de Áurea tiene 482.074
filas, y la diferencia entre las dos formas de recorrerlo —medida en la sección 6— es **291 MB de
memoria contra 0.15 MB**. Mil novecientas veces. Ese número es la fase entera.

Y aquí se construye el **arnés de medición del curso**: el archivo que las quince fases
siguientes van a usar para producir todos sus números. Con biblioteca estándar, pequeño, y sin
nada que haya que aprender a usar.

---

## ✅ 2. Qué queda listo al terminar

- [ ] Puedes explicar qué hace `yield` sin decir "pausa la función", y demostrar con código en qué
      momento exacto se ejecuta cada línea de un generador.
- [ ] Reconoces un generador agotado por su síntoma —el segundo recorrido devuelve vacío, sin
      error— y sabes qué hacer al respecto.
- [ ] `bench.py` existe en tu repositorio, mide tiempo y memoria, y declara el entorno.
- [ ] `generar_citas.py` produce el archivo del trimestre, y lo vas a reutilizar en las fases 06,
      14, 15 y 16.
- [ ] `read_rows` de `aur_cli.py` es un generador, y el CLI procesa el archivo grande sin que la
      memoria crezca.
- [ ] Sabes cuáles seis funciones de `itertools` usas de verdad, y puedes decir qué resuelve cada
      una.
- [ ] El miniproyecto de la sección 7 corre y cumple sus criterios de aceptación.

---

## 🚫 3. Qué NO entra todavía

- **`async` y las corrutinas** → Fase 14. Comparten la palabra clave con los generadores y no
  son lo mismo; mezclarlos aquí desordena las dos fases.
- **Clases propias** → Fase 03. Vas a escribir un iterador sin escribir una clase, que es
  justamente el punto.
- **Manejo de errores dentro de la tubería** → Fase 04. Hoy, si una fila viene mal, revienta.
- **`csv`** → Fase 06. La deuda 💸 de la Fase 01 sigue viva y sigue partiendo por comas.

---

## 🧠 4. Concepto mínimo

### El protocolo, que es más simple de lo que parece

Un iterable es cualquier objeto que sabe devolver un iterador cuando se lo piden (`__iter__`). Un
iterador es cualquier objeto que sabe dar el siguiente elemento (`__next__`) y levantar
`StopIteration` cuando se acabó. El `for` no hace más que eso: pedir el iterador, llamar a
`__next__` hasta que se acabe.

Hasta aquí es `Iterable`/`Iterator` de Java, y el paralelo aguanta. **Dónde se rompe:** en Python
esto no es una interfaz que alguien declare implementar, es un protocolo que se cumple teniendo
los métodos. Y sobre todo: **la biblioteca estándar está construida entera sobre él**, así que un
archivo abierto es un iterador de líneas, un `dict` es un iterable de llaves, `zip` devuelve un
iterador, y `range` no es una lista aunque lo parezca.

```python
file = open("data/citas-2026-Q1.csv", encoding="utf-8")
next(file)   # la primera línea: el encabezado
next(file)   # la segunda
# El archivo ES el iterador. Nadie leyó 27 MB para esto.
```

### Generadores: funciones que se recuerdan

Una función con `yield` no es una función que devuelve valores: es una fábrica de iteradores.
Llamarla **no ejecuta nada**, y eso es lo primero que sorprende:

```python
def rows_of(path):
    print("¿cuándo se imprime esto?")
    with open(path, encoding="utf-8") as file:
        next(file)
        for line in file:
            yield line.rstrip("\n").split(",")

gen = rows_of("data/citas-2026-Q1.csv")   # no imprime nada: el cuerpo no corrió
first = next(gen)                          # ahora sí imprime, y para en el primer yield
```

El cuerpo corre hasta el primer `yield`, entrega el valor, y **se congela ahí con todo su estado
local**: las variables, la posición del archivo, el punto del bucle. La siguiente llamada lo
descongela justo donde estaba.

Esa es la diferencia con el *stream* de Java, y es a favor de Python: allá construyes una tubería
declarativa con operaciones predefinidas; aquí escribes una **función normal**, con sus `if`, sus
bucles anidados y sus variables, que resulta ser perezosa. Cualquier cosa que sepas escribir en un
`for` la sabes escribir como generador.

Y hay tres formas de escribir lo mismo, que conviene reconocer de un vistazo:

```python
squares = [x * x for x in numbers]        # comprehension: lista completa, en memoria
squares = (x * x for x in numbers)        # expresión generadora: perezosa, un paréntesis
squares = map(lambda x: x * x, numbers)   # map: perezoso también, y casi nunca más legible
```

> ⚠️ **El paréntesis contra el corchete es la diferencia entre 291 MB y 0.15 MB**, y no hay nada
> en el código que grite cuál es cuál. Es el detalle tipográfico más caro del lenguaje.

### Tu instinto de Java dice… y esta vez se equivoca

**El reflejo:** materializar. Leer el archivo a una lista, filtrar a otra lista, transformar a una
tercera, y después recorrer. Es lo que uno hace cuando viene de colecciones, y en Java suele ser
inofensivo porque la colección cabe. Aquí, cuando no cabe, no hay aviso: hay un proceso que crece
hasta que el sistema operativo decide.

```python
# ❌ Lo que sale solo, y funciona perfectamente con el export de una sede
with open(path, encoding="utf-8") as file:
    lines = file.readlines()          # 482.074 cadenas en memoria
rows = [line.split(",") for line in lines]      # y ahora 482.074 listas más
no_shows = [row for row in rows if row[4] == "no_show"]   # y una tercera lista

# ✅ La misma lógica, sin materializar nada
with open(path, encoding="utf-8") as file:
    next(file)
    rows = (line.rstrip("\n").split(",") for line in file)
    no_shows = (row for row in rows if row[4] == "no_show")
    for row in no_shows:
        ...
```

Las dos versiones se leen casi igual. La primera reserva 291 MB; la segunda, 0.15 MB constantes
—los mide la sección 6—. Y la segunda además es **el doble de rápida**, que es el resultado que
menos gente espera: no es solo cuestión de memoria.

**Y ahora la parte contra-instintiva, que es donde el reflejo de Java duele de verdad.** Sabes
que un *stream* se consume una vez; eso lo tienes claro y no te va a sorprender. Lo que sí te va a
sorprender son las otras tres cosas:

```python
rows = (line.split(",") for line in file)

len(rows)                # ❌ TypeError: object of type 'generator' has no len()
rows[0]                  # ❌ TypeError: 'generator' object is not subscriptable

total = sum(1 for _ in rows)     # 482073
total = sum(1 for _ in rows)     # 0  ← y esto NO lanza ninguna excepción
```

La tercera es la que hace daño. Un *stream* de Java reutilizado lanza `IllegalStateException` y te
enteras; **un generador agotado simplemente devuelve vacío**, en silencio, y tu reporte sale con
ceros. En Áurea eso es un informe de inasistencia que dice que nadie faltó.

Las tres salidas, con su costo:

```python
rows = list(rows)                    # materializar: correcto si de verdad cabe
rows_a, rows_b = itertools.tee(gen)  # duplicar el iterador: guarda lo consumido por uno
                                     # y no por el otro — puede crecer tanto como una lista
def rows_of(path): ...               # la buena: una función que devuelve un generador NUEVO
for row in rows_of(path): ...        # cada llamada, una pasada limpia
```

> 🧭 **La regla, y es la que evita el 90% de los errores de esta fase:** no pases generadores por
> tu programa — pasa **funciones que los producen**. Un generador es un recurso de un solo uso; la
> función que lo fabrica se puede llamar las veces que haga falta.

### Esto sí funciona igual

**Tu instinto sobre no hacer dos pasadas cuando basta una** se transfiere entero, y aquí vale más
porque las pasadas sobre un generador cuestan releer el archivo.

**La idea de tubería es la misma idea.** Si sabes leer una cadena de `stream().filter().map()`,
sabes leer una cadena de expresiones generadoras. El orden de las operaciones importa igual —
filtrar antes de transformar, siempre— y por la misma razón.

**Y el criterio sobre legibilidad no cambia.** Una comprehension de cuatro cláusulas anidadas es
tan ilegible como un `stream` con seis operaciones y dos lambdas de tres líneas. En los dos casos
la respuesta es la misma: un `for` con nombres.

### Diccionario de traducción

| Java | Python | Dónde se rompe el paralelo |
|---|---|---|
| `Iterable<T>` / `Iterator<T>` | el protocolo `__iter__` / `__next__` | Nadie lo declara: se cumple teniéndolo. Y toda la stdlib está construida encima |
| `stream()` | expresión generadora | No hay `.stream()`: **cualquier** iterable ya sirve. Y se escribe como función, no como cadena |
| `.filter(p)` | `(x for x in it if p(x))` o `filter(p, it)` | Igual, y perezoso igual |
| `.map(f)` | `(f(x) for x in it)` o `map(f, it)` | Igual. La comprehension suele leerse mejor que `map` con `lambda` |
| `.collect(toList())` | `list(it)` | Explícito: nada te obliga a terminar la tubería |
| `.limit(n)` | `itertools.islice(it, n)` | En un módulo, no en el objeto. Se importa |
| `.reduce(...)` | `functools.reduce` / `sum` / `math.prod` | `reduce` existe y casi nadie lo usa: hay función específica para casi todo |
| `Collectors.groupingBy` | `itertools.groupby` **o un `dict`** | ⚠️ `groupby` **exige la entrada ordenada** por la llave. Es la trampa del miniproyecto |
| `IntStream.range(n)` | `range(n)` | `range` no es una lista: es una secuencia perezosa, con `len` e índices |
| *stream* reutilizado → `IllegalStateException` | generador agotado → **vacío, sin error** | Esta es la diferencia que muerde |
| `.parallel()` | no existe aquí | La concurrencia es la Fase 14, y no es una llamada en la cadena |

> 📝 **Nota de ecosistema — `groupby` no es `groupingBy`.** El nombre invita al error y la
> documentación lo advierte en la primera línea: `itertools.groupby` agrupa **elementos
> consecutivos** con la misma llave. Sobre una entrada sin ordenar produce grupos repetidos y
> parciales — sin fallar, que es lo peor. Es correcto, es útil, y es una herramienta distinta de
> la que crees estar usando. Si no puedes ordenar la entrada, lo que quieres es un diccionario
> acumulador.

### Las seis de `itertools` que usas de verdad

`itertools` tiene veintitantas funciones y la mayoría no las vas a usar nunca. Estas seis sí:

**`islice(it, n)`** — los primeros `n` sin materializar el resto. Es lo que usas para mirar un
archivo grande: `list(islice(rows, 5))`.

**`chain(a, b, c)`** — recorrer varios iterables como si fueran uno. Los diez exports de las sedes,
uno detrás de otro, sin concatenar listas. Y `chain.from_iterable` cuando los iterables vienen en
un iterable.

**`groupby(it, key)`** — agrupa consecutivos, con la advertencia de arriba.

**`accumulate(it)`** — sumas corridas. El saldo de un plan de pagos mes a mes, que en Áurea es
exactamente lo que hace falta.

**`tee(it, n)`** — duplica un iterador. Útil y peligroso: guarda en memoria todo lo que un ramal
consumió y el otro no, así que si recorres uno entero antes de tocar el otro, gastaste lo mismo
que una lista.

**`count()` y `cycle()`** — contadores y repetición infinita, casi siempre acompañados de
`islice` o de un `break`.

El resto se busca cuando haga falta. Lo importante es saber que el módulo existe y que la mitad de
los bucles con índice que ibas a escribir ya están ahí.

---

## 💻 5. Código mínimo con comentarios

### 5.1 El archivo grande

Las fases anteriores trabajaban con el export de una sede: seiscientas filas. Para ver el
problema hace falta el archivo del trimestre de toda la red, y se genera —no se descarga— con
semilla fija:

```python
"""Genera el archivo de citas del primer trimestre de 2026 de toda la red.

Uso:  python generar_citas.py
Produce data/citas-2026-Q1.csv, unas 480.000 filas, con semilla fija.
Es el archivo grande del curso: las fases 06, 14, 15 y 16 lo reutilizan.
"""

import random
from datetime import date, timedelta
from pathlib import Path

BRANCHES = ["Centro", "Chapinero", "Suba", "Kennedy", "Usaquen",
            "Engativa", "Fontibon", "Restrepo", "Soacha", "Zipaquira"]
STATUSES = ["asistio", "no_show", "cancelada", "reprogramada"]
WEIGHTS = [76, 19, 3, 2]          # el 19% de inasistencia es dato del dominio
CODES = ["D8010", "D8020", "D2740", "D7140", "D1110", "D8670"]


def main() -> None:
    random.seed(2026)
    Path("data").mkdir(exist_ok=True)
    target = Path("data") / "citas-2026-Q1.csv"

    start = date(2026, 1, 1)
    with target.open("w", encoding="utf-8", newline="\n") as file:
        file.write("documento,sede,fecha,hora,estado,codigo,valor\n")
        rows = 0
        for day_offset in range(90):
            day = start + timedelta(days=day_offset)
            if day.weekday() == 6:          # domingo no se atiende
                continue
            for branch in BRANCHES:
                for _ in range(random.randint(550, 700)):
                    document = random.randint(10_000_000, 1_299_999_999)
                    hour = random.randint(7, 18)
                    minute = random.choice((0, 20, 40))
                    status = random.choices(STATUSES, WEIGHTS)[0]
                    code = random.choice(CODES)
                    value = random.choice((75000, 95000, 120000, 180000, 210000, 890000))
                    file.write(f"{document},{branch},{day.isoformat()},"
                               f"{hour:02d}:{minute:02d},{status},{code},{value}\n")
                    rows += 1
    print(f"{target}: {rows:,} filas · {target.stat().st_size / 1e6:.1f} MB")


if __name__ == "__main__":
    main()
```

```bash
python generar_citas.py
# data/citas-2026-Q1.csv: 482,074 filas · 27.1 MB
```

Veintisiete megabytes. Cabe en memoria — ese es justamente el problema, porque el código malo va a
funcionar y no vas a enterarte hasta que Áurea tenga tres años de historia.

### 5.2 El arnés del curso

Esto lo vas a usar en quince fases más. Es deliberadamente pequeño: **un arnés que hay que
aprender a usar deja de usarse.**

```python
"""El arnés de medición del curso. Biblioteca estándar, y nada más.

Tres responsabilidades y ninguna más: cronometrar con reloj monótono y
repeticiones, medir el pico de memoria, y declarar el entorno.

Uso:
    from bench import measure, render
    print(render([measure("perezosa", lambda: report(path))]))
"""

import platform
import statistics
import time
import tracemalloc
from collections.abc import Callable
from typing import Any


def environment() -> str:
    """Sin esto, un número no es reproducible y por lo tanto no es un número."""
    return (
        f"{platform.python_implementation()} {platform.python_version()} · "
        f"{platform.system()} {platform.release()} · {platform.machine()}"
    )


def measure(label: str, work: Callable[[], Any], repetitions: int = 5) -> dict[str, Any]:
    """Ejecuta `work` varias veces y devuelve tiempos y pico de memoria.

    Se reportan mediana y percentil 95, nunca el promedio solo: el promedio
    esconde la cola, que es justo lo que importa cuando algo se degrada.

    El pico de memoria se mide en una corrida APARTE, porque tracemalloc
    instrumenta cada asignación y distorsionaría el tiempo si corrieran juntos.
    """
    timings: list[float] = []
    for _ in range(repetitions):
        started = time.perf_counter()   # reloj monótono: no lo afecta el reloj del sistema
        work()
        timings.append((time.perf_counter() - started) * 1000)
    timings.sort()

    tracemalloc.start()
    work()
    _, peak = tracemalloc.get_traced_memory()
    tracemalloc.stop()

    return {
        "etiqueta": label,
        "mediana_ms": statistics.median(timings),
        "p95_ms": timings[max(0, int(len(timings) * 0.95) - 1)],
        "pico_mb": peak / 1e6,
        "repeticiones": repetitions,
    }


def render(results: list[dict[str, Any]]) -> str:
    """La tabla, lista para pegar en el documento de la fase."""
    lines = [f"Entorno: {environment()}", ""]
    lines.append(f"{'opción':<28}{'mediana':>12}{'p95':>12}{'pico':>12}")
    for result in results:
        lines.append(
            f"{result['etiqueta']:<28}{result['mediana_ms']:>10.0f} ms"
            f"{result['p95_ms']:>10.0f} ms{result['pico_mb']:>9.1f} MB"
        )
    return "\n".join(lines)
```

**Detalles con intención**

- **`time.perf_counter` y no `time.time`.** El primero es monótono y de alta resolución; el
  segundo es el reloj de pared, que puede saltar hacia atrás si el sistema se sincroniza a mitad
  de la medición. Es el mismo criterio que `System.nanoTime()` contra `currentTimeMillis()`.
- **Mediana y p95, nunca el promedio solo.** El promedio esconde la cola, y la cola es lo que
  importa: un proceso que tarda 100 ms nueve veces y 3 s la décima tiene un promedio excelente y
  un problema serio.
- **La memoria se mide en una corrida aparte.** `tracemalloc` instrumenta cada asignación del
  intérprete: medir tiempo con él encendido daría números inflados y mentirosos.
- **`tracemalloc` mide lo que asigna Python**, no lo que el sistema operativo le da al proceso.
  Para lo segundo hace falta otra herramienta, y la Fase 16 la trae cuando el trabajo cruza a un
  proceso hijo.
- **No hay estadística sofisticada, ni gráficas, ni comparación automática.** A propósito.

### 5.3 El CLI se vuelve perezoso

El cambio en `aur_cli.py` es de dos líneas, y es todo lo que hace falta:

```python
def read_rows(path):
    """Lee el export y produce las filas de a una, sin cargar el archivo entero.

    💸 DEUDA INTENCIONAL — se paga en la Fase 06. (Sigue viva: partir por comas
    a mano se rompe con el primer nombre que traiga una coma adentro. El módulo
    `csv` lo resuelve, y hasta esa fase convivimos con esto a propósito.)
    """
    with open(path, encoding="utf-8") as file:
        next(file)  # el encabezado
        for line in file:
            line = line.strip()
            if not line:
                continue
            yield tuple(line.split(","))   # ← era rows.append(...); ahora es yield
```

Dos cambios: desapareció `rows = []` y `return rows`, y `append` se volvió `yield`. **`summarize`
no cambia ni una línea**, porque ya recorría con un `for` y al `for` le da igual qué le den.

> ⚠️ **Y aquí aparece el efecto secundario que hay que entender**, porque es el que produce los
> errores raros: el `with` de un generador **no cierra el archivo cuando la función retorna** —
> retorna en el primer `yield`—. El archivo queda abierto mientras alguien esté consumiendo, y se
> cierra cuando el generador se agota o se destruye. Si guardas el generador y no lo consumes,
> dejas un archivo abierto. En un script que corre y muere, no pasa nada; en el proceso nocturno
> de la Fase 15, que corre horas, sí.

**Prueba de fuego**

```bash
python -c "
import aur_cli
rows = aur_cli.read_rows('data/citas-2026-Q1.csv')
print(type(rows))
print(sum(1 for _ in rows))
print(sum(1 for _ in rows))
"
```

```text
<class 'generator'>
482074
0
```

**Ese `0` de la tercera línea es la lección de la fase.** No hay excepción, no hay aviso: el
generador ya se agotó. Míralo una vez aquí, en un sitio seguro, para reconocerlo cuando aparezca
dentro de un reporte.

**El patrón a memorizar**

> Lee perezoso, filtra perezoso, y materializa **solo el resultado** — que casi siempre es mucho
> más pequeño que la entrada. Un diccionario de diez sedes cabe en cualquier parte; el archivo que
> lo produjo, no necesariamente.

---

## 📏 6. Medición — la lista intermedia contra la tubería

**Hipótesis.** Una tubería perezosa procesa el archivo de citas en memoria constante, mientras que
la versión con listas intermedias crece linealmente con el archivo. El tiempo es secundario — o
eso creíamos.

**Condiciones.** CPython 3.14.5 · macOS 26.6 · Apple Silicon, 8 núcleos · el archivo
`data/citas-2026-Q1.csv` generado por `generar_citas.py` con semilla `2026`: 482.074 filas, 27.1
MB · el mismo cálculo en las dos formas: contar inasistencias por sede · 5 repeticiones para el
tiempo, una corrida aparte con `tracemalloc` para el pico · arnés: `bench.py` de §5.2.

**Competidores.** Las dos versiones del mismo cálculo, las dos escritas como las escribiría
alguien que sabe lo que hace: la primera con `readlines()` y comprehensions —que es código
perfectamente idiomático y que pasaría una revisión sin comentarios—, la segunda con expresiones
generadoras. **Se verificó que las dos producen exactamente el mismo resultado** antes de medir,
que es lo primero que hay que hacer y lo que más se olvida.

**Resultado.**

| Opción | Mediana | p95 | Pico de memoria |
|---|---|---|---|
| Lista intermedia | 349 ms | 357 ms | **291.0 MB** |
| Tubería perezosa | **171 ms** | 171 ms | **0.15 MB** |

Y el umbral, que es lo que convierte esto en criterio:

| Filas | Lista: tiempo / memoria | Perezosa: tiempo / memoria |
|---|---|---|
| 1.000 | 0.4 ms / 0.6 MB | 0.4 ms / 0.15 MB |
| 10.000 | 4.2 ms / 6.0 MB | 3.7 ms / 0.15 MB |
| 50.000 | 31.3 ms / 30.2 MB | 19.5 ms / 0.15 MB |
| 200.000 | 150.3 ms / 120.6 MB | 71.8 ms / 0.15 MB |
| 482.074 | 369.9 ms / 291.0 MB | 161.8 ms / 0.15 MB |

> ⚖️ **Veredicto.** La memoria de la tubería perezosa es **constante**: 0.15 MB con mil filas y
> 0.15 MB con medio millón. La de la lista crece linealmente y llega a **291 MB para procesar un
> archivo de 27 MB** — diez veces el tamaño del archivo, que es lo que cuesta convertir texto en
> objetos de Python.
>
> **Y el resultado que contradice la hipótesis:** la tubería no solo gasta menos memoria, es
> **2.3× más rápida**. Eso no estaba previsto y hay que explicarlo en vez de celebrarlo: reservar
> 291 MB cuesta trabajo —asignaciones, crecimiento del arreglo interno, presión sobre el
> recolector de basura— y ese trabajo es tiempo. La versión perezosa nunca lo hace.
>
> **El umbral está alrededor de las diez mil filas.** Por debajo, las dos versiones empatan en
> tiempo y la diferencia de memoria son megabytes que a nadie le importan: para el export de una
> sede, materializar está bien y es más fácil de depurar. Por encima de cien mil, no hay
> discusión. Entre ambas, decide cuántas veces corres el proceso y qué más está corriendo en esa
> máquina — y recuerda que la máquina virtual de Áurea tiene dos núcleos y poca RAM.
>
> **Dónde pierde la tubería perezosa**, que hay que decirlo porque parece gratis: no se puede
> recorrer dos veces, no tiene `len`, no se puede indexar, y **es más difícil de depurar** —
> poner un punto de quiebre dentro de una expresión generadora no es cómodo, y mirar el contenido
> "a mitad" no es posible sin consumirlo. Cuando estés diagnosticando algo raro, materializar un
> `islice` de diez filas es la técnica correcta y no una derrota.

**Lo que no se midió:** el tiempo de *generar* el archivo (1.2 s, irrelevante aquí), y el consumo
de memoria del proceso completo visto por el sistema operativo, que es mayor que el que reporta
`tracemalloc` porque incluye al intérprete mismo. La comparación es de lo que asigna Python, y
eso es lo que decide.

---

## 🧱 7. Miniproyecto — *El reporte que cabe en memoria*

**El encargo**

Julián, en una reunión de socios, suelta el problema: *"Marcela dice que las inasistencias son
peores en la tarde y yo digo que es en las sedes del sur. Llevamos dos años discutiendo esto sin
datos. Necesito el trimestre completo: inasistencia por sede y por franja horaria, y quiero poder
correrlo yo en mi portátil, que es el viejo."*

Escribe el informe trimestral de inasistencia por sede y franja horaria sobre el archivo completo,
con un tope de memoria como criterio de aceptación.

**Por qué duele**

Porque agrupar por dos dimensiones invita a materializar —primero junto todo por sede, después
dentro de cada sede junto por franja— y el archivo no te lo va a impedir: cabe. El tope de
memoria es lo que convierte la elegancia en un requisito verificable.

Y porque las franjas horarias no están en los datos: hay una hora, y la franja es una decisión
que tienes que tomar y defender.

**Datos de entrada**

`data/citas-2026-Q1.csv`, producido por el generador de §5.1. Siete columnas:

```text
documento,sede,fecha,hora,estado,codigo,valor
1019283746,Centro,2026-01-02,08:20,asistio,D8010,180000
52847193,Chapinero,2026-01-02,15:40,no_show,D2740,890000
```

Los estados son `asistio`, `no_show`, `cancelada` y `reprogramada`. **Y esa es la primera decisión
que el enunciado no toma por ti: ¿una cita cancelada cuenta como inasistencia?** En Áurea no es lo
mismo —una cancelación con aviso libera la silla y una inasistencia no— y tu informe tiene que
decir qué decidió.

**Criterios de aceptación**

- [ ] Un solo archivo, `informe_inasistencia.py`, biblioteca estándar pura, sin clases.
- [ ] Produce una tabla de inasistencia por sede × franja horaria, con el porcentaje y el conteo
      absoluto — el porcentaje solo miente cuando una celda tiene doce citas.
- [ ] **Pico de memoria por debajo de 10 MB**, medido con `bench.py` de §5.2. El archivo pesa 27
      MB: si tu pico se parece a eso, materializaste.
- [ ] Una sola pasada sobre el archivo. Si necesitas dos, dilo y justifica por qué.
- [ ] La definición de franja horaria y la decisión sobre las canceladas están escritas en el
      archivo, en comentarios, con su porqué.
- [ ] **Medición:** tiempo y pico de memoria de tu informe sobre el archivo completo. Esos dos
      números van en el mensaje del tag.

**Restricciones de registro**

> Esto es un **script**. Un archivo, stdlib pura, sin clases, sin `InasistenciaReporter` ni
> `FranjaHorariaStrategy`. Funciones sueltas y el trabajo bajo `if __name__ == "__main__":`. Y no
> toques `aur_cli.py`: el miniproyecto es de usar y tirar, y el CLI es el proyecto del curso.

**La trampa**

Vas a querer usar `itertools.groupby`, porque el nombre dice exactamente lo que necesitas. Y va a
producir un resultado **mal, sin fallar**: `groupby` agrupa elementos *consecutivos*, y el archivo
está ordenado por fecha, no por sede. Vas a obtener noventa grupos llamados "Centro" en vez de
uno.

La salida obvia es ordenar primero — y ordenar exige materializar los 482.074 registros, que es
exactamente lo que el criterio de los 10 MB prohíbe. **Hay una salida que no ordena y no
materializa**, y encontrarla es el ejercicio.

**Pistas**

<details><summary>Pista 1 — el enfoque</summary>

Pregúntate qué es lo que de verdad tiene que estar en memoria al final. No son las citas: es el
resultado, y el resultado tiene diez sedes por unas pocas franjas. Eso son decenas de celdas.

Si lo que necesitas son decenas de celdas, ¿por qué estarías guardando medio millón de filas?
</details>

<details><summary>Pista 2 — la herramienta</summary>

Una llave compuesta es una tupla, y las tuplas pueden ser llaves de un diccionario — eso es de la
Fase 01, §4. Un `dict` indexado por `(sede, franja)` que se va actualizando fila a fila resuelve
el problema en una pasada y en memoria constante.

Si quieres que el acumulador sea más cómodo, mira
[`collections.Counter`](https://docs.python.org/3.14/library/collections.html#collections.Counter)
y [`collections.defaultdict`](https://docs.python.org/3.14/library/collections.html#collections.defaultdict).
Los dos son de la biblioteca estándar y los dos sirven aquí.

Y para la franja: `"15:40"` se parte con `split(":")` o se rebana; no hace falta `datetime` para
saber en qué hora del día cae algo.
</details>

<details><summary>Pista 3 — el esqueleto</summary>

```python
def rows_of(path):
    """Generador. Una FUNCIÓN que devuelve un generador nuevo cada vez."""

def time_slot(hour_text: str) -> str:
    """La franja. Tú decides cuáles son y lo justificas en un comentario."""

def tally(rows) -> dict[tuple[str, str], dict[str, int]]:
    """Acumula por (sede, franja). Una pasada, memoria proporcional al RESULTADO."""

def render(counts) -> str:
    """La tabla para Julián, con porcentaje y conteo."""
```
</details>

**Cómo se entrega**

```bash
python generar_citas.py               # una vez
python informe_inasistencia.py data/citas-2026-Q1.csv
```

```bash
git add informe_inasistencia.py generar_citas.py bench.py
git commit -m "fase 02 mini: informe trimestral de inasistencia en memoria constante"
git tag -a mini-02 -m "Mini F2: inasistencia por sede y franja · <N> ms, pico <M> MB"
```

<details><summary>💡 Solución de referencia — ábrela después de intentarlo</summary>

```python
"""Informe trimestral de inasistencia por sede y franja horaria.

Uso:  python informe_inasistencia.py data/citas-2026-Q1.csv
"""

import sys
from collections import defaultdict
from pathlib import Path

# Decisión 1 — las franjas. Áurea atiende de 7 a 19, y la discusión de Julián y
# Marcela es "mañana contra tarde", así que tres franjas alcanzan y una cuarta
# sobraría. El corte de las 12 es el almuerzo; el de las 16, el cambio de turno
# de las auxiliares.
SLOTS = (("mañana", 7, 12), ("mediodía", 12, 16), ("tarde", 16, 20))

# Decisión 2 — qué cuenta como inasistencia. Solo `no_show`. Una cancelación
# avisa y libera la silla, que es el recurso escaso; contarlas juntas mezcla dos
# problemas distintos y el informe dejaría de servir para decidir nada.
# Se reportan aparte para que nadie tenga que creerme.
MISSED = "no_show"


def rows_of(path: Path):
    """Produce las filas de a una. Es una función, no un generador guardado:
    llamarla dos veces da dos recorridos limpios (§4)."""
    with path.open(encoding="utf-8") as file:
        next(file)  # encabezado
        for line in file:
            line = line.rstrip("\n")
            if line:
                yield line.split(",")


def time_slot(hour_text: str) -> str:
    """'15:40' -> 'mediodía'. No hace falta datetime para esto."""
    hour = int(hour_text[:2])
    for name, start, end in SLOTS:
        if start <= hour < end:
            return name
    return "fuera de horario"


def tally(rows) -> dict[tuple[str, str], dict[str, int]]:
    """Una pasada. La memoria es proporcional al RESULTADO —diez sedes por tres
    franjas: treinta celdas—, no a las 482.074 filas de entrada."""
    counts: dict[tuple[str, str], dict[str, int]] = defaultdict(
        lambda: {"total": 0, "no_show": 0, "cancelada": 0}
    )
    for row in rows:
        branch, hour, status = row[1], row[3], row[4]
        cell = counts[(branch, time_slot(hour))]
        cell["total"] += 1
        if status == MISSED:
            cell["no_show"] += 1
        elif status == "cancelada":
            cell["cancelada"] += 1
    return counts


def render(counts) -> str:
    lines = [f"{'sede':<12}{'franja':<12}{'citas':>8}{'inasist.':>10}{'%':>8}{'cancel.':>9}"]
    for (branch, slot), cell in sorted(counts.items()):
        rate = 100 * cell["no_show"] / cell["total"] if cell["total"] else 0
        lines.append(
            f"{branch:<12}{slot:<12}{cell['total']:>8,}{cell['no_show']:>10,}"
            f"{rate:>7.1f}%{cell['cancelada']:>9,}"
        )
    return "\n".join(lines)


if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("uso: python informe_inasistencia.py <archivo.csv>", file=sys.stderr)
        sys.exit(2)
    print(render(tally(rows_of(Path(sys.argv[1])))))
```

**La decisión de diseño que se tomó.** Un diccionario acumulador en vez de `groupby`. El otro
camino defendible es ordenar el archivo por sede con `sorted` y usar `groupby` de verdad: produce
el mismo resultado, se lee muy bien, y **cuesta materializar las 482.074 filas**. Sería la
elección correcta si el archivo fuera de diez mil filas y el código lo fuera a mantener alguien
que ya conoce `groupby` — con datos de este tamaño, no.

**La trampa, entera.** `itertools.groupby` sobre este archivo sin ordenar produce un resultado
plausible y equivocado: como el archivo viene ordenado por fecha y dentro de cada día por sede,
salen **770 grupos** —diez sedes por los setenta y siete días hábiles del trimestre— en vez de
diez, y si los acumulas en un diccionario por error **el resultado final incluso coincide**. Donde se ve el fallo es si haces
`dict(groupby(...))` o si iteras los grupos esperando diez: ahí los números se caen. Cuesta
descubrirlo porque no hay excepción en ninguna parte.

Y un segundo detalle que muerde: los objetos que `groupby` entrega **comparten el iterador
subyacente**, así que si guardas los grupos para procesarlos después, están vacíos. Es el mismo
agotamiento de §4, con otra cara.

**Qué se habría hecho distinto si el registro fuera otro.** Como herramienta —Bloque B— esto sería
un subcomando de `aur` con sus tipos y sus pruebas, las franjas vendrían de un archivo de
configuración en vez de una constante, y la salida sería también CSV para que Julián la abra en
Excel. Como aplicación, sería una consulta SQL con un `GROUP BY` y no habría nada de esto — que
es exactamente el argumento de la Fase 11 y, dicho sea de paso, la razón por la que un `GROUP BY`
de verdad le gana a cualquier tubería que escribas: la base de datos también agrupa en una
pasada, y lo hace en C.
</details>

---

## 🧪 8. Ejercicios (25)

**🟢 Fácil (1–6)**

1. Escribe un generador que produzca solo las citas de una sede dada, y úsalo para contar cuántas
   hay en Suba. Demuestra con `bench.py` que el pico de memoria no depende del tamaño del archivo.
2. Convierte a expresión generadora esta comprehension y mide la diferencia de memoria:
   `[row for row in rows if row[4] == "no_show"]`.
3. Usa `islice` para imprimir las primeras cinco filas del archivo grande sin leerlo entero.
   Comprueba con el arnés que efectivamente no lo leyó.
4. Demuestra el agotamiento: crea un generador, recórrelo dos veces, y muestra que la segunda da
   vacío sin lanzar nada. Después arréglalo de las dos formas posibles.
5. Usa `chain` para recorrer los diez exports de la Fase 01 como si fueran un solo archivo, y
   cuenta el total de filas. Sin concatenar listas.
6. Usa `accumulate` para calcular el saldo corrido de un plan de pagos de veinticuatro cuotas.
   Imprime los primeros seis meses.

**🟡 Intermedio (7–14)**

7. Reescribe `summarize` de `aur_cli.py` para que reciba un iterable y funcione igual con una
   lista y con un generador. Demuestra las dos.
8. Averigua qué es `yield from` y reescribe con él un generador que recorra los diez archivos de
   sede. Compara con la versión que usa `chain`.
9. Consulta la documentación de `itertools.tee` y construye un caso donde duplicar un iterador
   gaste **más** memoria que haber materializado la lista. Mídelo.
10. Escribe un generador infinito de fechas de control mensual a partir de una fecha de inicio, y
    úsalo con `islice` para sacar los próximos doce controles de un paciente.
11. Demuestra con código en qué orden se ejecutan las líneas de un generador: pon `print` antes
    del `yield`, después del `yield`, y después del bucle. Explica la salida.
12. Usa `groupby` **correctamente**: ordena las filas de un archivo pequeño por sede y agrúpalas.
    Después córrelo sin ordenar y explica exactamente qué salió distinto.
13. Escribe una tubería de tres etapas —leer, filtrar, transformar— y comprueba con `print` en
    cada etapa que las filas pasan de a una y no por bloques. El orden de los mensajes es la
    demostración.
14. Averigua qué hace `enumerate(it, start=1)` y reescribe con él un bucle con contador manual de
    tu propio código de fases anteriores.

**🟠 Difícil (15–21)**

15. **Diagnóstico.** Te dan este código y dicen que "el informe sale vacío para algunas sedes":
    ```python
    rows = (line.split(",") for line in open(path))
    sedes = {row[1] for row in rows}
    for sede in sedes:
        total = sum(1 for row in rows if row[1] == sede)   # siempre 0
    ```
    Explica el mecanismo exacto, arréglalo de dos formas distintas, y mide cuál de las dos cuesta
    más.
16. **Diagnóstico.** Un script deja archivos abiertos y en Windows falla al intentar borrarlos.
    Reproduce el escenario con un generador que abre un archivo, y explica cuándo se cierra de
    verdad. Da dos formas de garantizar el cierre.
17. **Medición.** Reproduce la tabla de umbral de la sección 6 en tu máquina, con al menos cuatro
    tamaños. Encuentra **tu** punto de cruce y repórtalo con el formato del arnés.
18. **Medición.** Compara tres formas de contar inasistencias: comprehension con lista, expresión
    generadora con `sum`, y un bucle `for` explícito. Mide las tres y explica por qué la diferencia
    entre las dos últimas es tan pequeña.
19. **Medición.** Mide cuánto cuesta `tracemalloc` sobre la medición: corre el mismo trabajo con y
    sin él y reporta la diferencia. Es la razón por la que `bench.py` los separa, y conviene que
    tengas tu propio número.
20. **De registro.** Julián quiere que el informe de inasistencia "se actualice solo y lo pueda
    ver cuando quiera". Decide el registro, justifica con el costo de las tres opciones, y
    menciona qué parte de la solicitud contestarías con un "no". Guarda la respuesta: la Fase 15 y
    la Fase 12 la retoman desde lados opuestos.
21. **De registro.** Tu informe tarda 170 ms sobre medio millón de filas. Áurea crece 20% al año.
    Decide en qué momento —con qué número concreto— este script dejaría de ser la respuesta
    correcta, y qué sería la respuesta entonces.

**🔴 Muy difícil (22–25)**

22. **Adversarial.** Escribe una tubería perezosa que **sí** consuma memoria lineal, sin usar
    `list` ni `sorted` en ninguna parte. Hay al menos tres formas de lograrlo. Mídelas y explica
    cada una: son los tres escaparates donde la pereza se pierde sin que se note.
23. **Adversarial.** El archivo del trimestre tiene 482.074 filas. Genera uno de cinco millones
    cambiando la semilla y el rango, y corre tu informe. Después corre la versión con listas.
    Documenta qué pasó exactamente con la segunda: si no la mató el sistema operativo, di cuánta
    memoria llegó a pedir.
24. **Defiende una decisión.** Alguien revisa tu informe y dice: *"esto sería tres líneas con
    pandas"*. Tiene razón. Escribe la respuesta con las dos caras —qué gana pandas, qué cuesta
    aquí— sabiendo que la regla del Bloque A es no instalar nada y que esa regla tiene su propio
    porqué. Termina diciendo en qué caso concreto de Áurea cambiarías de opinión.
25. **Diseño y medición.** El proceso nocturno de la Fase 15 va a recorrer este archivo mientras
    otro proceso lo está escribiendo. Investiga qué pasa con un generador que lee un archivo que
    crece, escribe un experimento que lo demuestre, y propón qué harías al respecto. No hay una
    respuesta única y hay al menos dos malas.

**🔥 Opcionales**

- Lee la documentación completa de `itertools` y escribe, para cada función que **no** entró en
  las seis de §4, una línea diciendo en qué caso de Áurea la usarías. Muchas se van a quedar sin
  caso, y ese es el punto.
- Averigua qué son las *generator expressions* con múltiples `for` y escribe una que aplane una
  lista de listas. Después escríbelo con `chain.from_iterable` y decide cuál dejarías.
- Investiga `contextlib.closing` y `generator.close()`, y demuestra qué pasa cuando un generador
  se cierra a mitad de su ejecución. La Fase 04 vuelve sobre esto.

---

## 📚 9. Referencias

**Documentación oficial**

- [Tipos iterador](https://docs.python.org/3.14/library/stdtypes.html#iterator-types) — el
  protocolo, en dos párrafos.
- [`itertools`](https://docs.python.org/3.14/library/itertools.html) — la referencia completa, con
  las "recetas" del final, que son media biblioteca más.
- [`collections`](https://docs.python.org/3.14/library/collections.html) — `Counter` y
  `defaultdict`, que son los acumuladores del miniproyecto.
- [`tracemalloc`](https://docs.python.org/3.14/library/tracemalloc.html) — qué mide exactamente y
  qué no.
- [`time.perf_counter`](https://docs.python.org/3.14/library/time.html#time.perf_counter) — por
  qué este y no `time.time`.
- [Guía: expresiones generadoras y comprehensions](https://docs.python.org/3.14/tutorial/classes.html#generators)
  — corto y con ejemplos.

**PEPs**

- [PEP 255](https://peps.python.org/pep-0255/) — los generadores, de 2001. Se lee bien y explica
  el porqué del diseño.
- [PEP 289](https://peps.python.org/pep-0289/) — las expresiones generadoras, y por qué se
  agregaron después de las comprehensions.
- [PEP 380](https://peps.python.org/pep-0380/) — `yield from`.

**Libros / artículos**

- *Fluent Python*, de Luciano Ramalho — el capítulo de iteradores y generadores es la mejor
  explicación larga del tema. Verifica la edición antes de citar páginas.

**Orden de lectura sugerido.** Antes de escribir: los tipos iterador, que son dos párrafos.
Durante: `itertools` consultado por función, sin intentar leerlo entero. Después: el PEP 255, que
explica por qué el lenguaje tiene esto y no *streams*.

> ⚠️ URLs y contenidos cambian; fija 3.14 en el selector de versión de la documentación.

---

## 🚀 10. Cierre y conexión con la siguiente fase

Tienes tres cosas nuevas, y una de ellas te va a acompañar quince fases más.

**El hábito de no materializar**, que es el más caro de los que traías. Y con él, el
reconocimiento del síntoma cuando falla: el reporte que sale con ceros sin que nada haya lanzado
una excepción.

**El arnés**, `bench.py`, que a partir de aquí es como este curso afirma cosas. Cada vez que leas
una tabla 📏 en una fase, salió de ahí; y cada vez que quieras discutirle al curso un número,
tienes la herramienta para hacerlo con datos.

**Y el archivo del trimestre**, que las fases 06, 14, 15 y 16 van a reutilizar: 482.074 filas es
suficiente para que las diferencias se vean y poco para que las mediciones se puedan repetir.

La **Fase 03** es la más densa del curso y ataca el otro reflejo grande: la ceremonia. La clase con
un solo método, la jerarquía de tres niveles, los getters sobre atributos públicos. Ahí las filas
que hoy son tuplas se van a convertir en `dataclass` —y vas a medir qué cuesta esa conversión en
memoria sobre cien mil registros— y va a nacer el motor de comisiones de aliados, que es el
cálculo más difícil del dominio y el que la Fase 08 blinda con pruebas.

> **La señal de que quedó bien:** vas a empezar a notar el paréntesis. Cuando leas código ajeno,
> el corchete de una comprehension sobre algo grande te va a saltar a la vista como salta un
> `SELECT *` en una revisión.

> 🏷️ **No cierres la fase sin el tag.** Con el checklist de la sección 2 en verde, el
> miniproyecto corriendo y `git status` limpio:
>
> ```bash
> git tag -a fase-02 -m "F2 cerrada:
> - el protocolo de iteración entendido, y el agotamiento reproducido a propósito
> - bench.py mide tiempo, pico de memoria y declara el entorno
> - generar_citas.py produce el archivo del trimestre con semilla fija
> - read_rows es un generador y summarize no cambió ni una línea
> - las seis de itertools que se usan de verdad, con su caso
> - el informe de inasistencia corre en memoria constante bajo 10 MB"
> ```
>
> Los commits de la fase llevan su prefijo (`fase 02: …`), los de ejercicio su número
> (`fase 02 ej12: …`) y el miniproyecto el suyo (`fase 02 mini: …`). El miniproyecto terminado
> lleva además su tag anotado `mini-02`, y **en el mensaje de ese tag va el número que arrojó su
> medición**. La convención completa está en
> [`00-convencion-de-git-y-tags.md`](00-convencion-de-git-y-tags.md).
