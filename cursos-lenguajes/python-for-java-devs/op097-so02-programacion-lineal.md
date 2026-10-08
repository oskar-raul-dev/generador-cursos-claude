# 📐 so02 — Programación lineal y entera

> Python para desarrolladores Java senior · **Carta** · Track `so` — Optimización, simulación y
> decisiones · sección 2 de 7
> Se lee suelta: no hace falta ninguna otra sección de la carta.
> Versiones verificadas contra PyPI el 05/10/2026 · Código probado el 05/10/2026 con Python 3.14.7,
> en contenedor: las salidas son las de esa corrida.

---

## 🎯 1. Qué problema resuelve

Chapinero, sede propia, tiene dos unidades odontológicas (las sillas) y un rehabilitador del Centro que va tres tardes por
semana. Cada semana, la agenda mezcla controles de ortodoncia, limpiezas, blanqueamientos y carillas, que ocupan la silla tiempos
distintos y dejan márgenes muy distintos. Julián quiere saber qué mezcla conviene, y la pregunta que de verdad le importa viene
después: **¿cuánto se ganaría con una silla más, o con una tarde más del rehabilitador?**

Es un problema de **programación lineal**: decisiones que son cantidades, restricciones que son sumas, y un objetivo que es una
suma. La familia tiene dos variantes que importan: la **lineal continua** (las cantidades pueden ser fraccionarias), que se resuelve
rapidísimo y además responde la pregunta de Julián con los **precios sombra**; y la **entera** (las cantidades son enteras: no hay
media carilla), que es la respuesta que se puede agendar. Desde Python se modelan con **PuLP** y se resuelven con **HiGHS**, el
solucionador abierto que hoy compite con los comerciales.

---

## 🧠 2. El modelo

| Versión | Variables | Qué da | Costo |
|---|---|---|---|
| Lineal (LP) | Continuas | El óptimo **y los precios sombra** de cada restricción | Muy barato, aun con millones de variables |
| Entera (MIP) | Enteras o binarias | La respuesta que se puede ejecutar | Puede ser caro: el problema general es NP-difícil |

**Precio sombra** (*dual*, en el vocabulario técnico): cuánto mejora el objetivo si una restricción se afloja en una unidad. Si el precio
sombra de los minutos de silla es $1.500, un minuto más de silla vale $1.500 de margen, **mientras ese precio se mantenga** —y el ejemplo
muestra que puede mantenerse muy poco—.

| Biblioteca | Versión | Para qué |
|---|---|---|
| PuLP | 4.0.0 | Modelar con sintaxis de Python; núcleo en Rust desde la 4 |
| `highspy` | 1.15.1 | HiGHS desde Python: el solucionador, y su propia API de modelado |
| Pyomo | 6.10.1 | Modelos grandes y no lineales, muchos solucionadores |
| `mip` | 2.0.0 | MIP con CBC, enfocado en enteros |

### Tu instinto de Java dice… y esta vez se equivoca

El instinto mira un problema con enteros y concluye que hay que probar combinaciones. Para cuatro procedimientos, sí; para cuarenta, la
explosión combinatoria lo hace imposible. El solucionador entero no prueba combinaciones: resuelve versiones continuas, ramifica donde
hay fracciones y descarta ramas enteras con cotas. Es la diferencia entre un bucle y setenta años de algoritmos.

---

## 💻 3. El ejemplo que corre

```bash
uv add pulp highspy
```

`mezcla_chapinero.py`:

```python
"""La mezcla semanal de Chapinero: lineal (con precios sombra) y entera (la que se agenda)."""

import pulp

PROCS = {                 # minutos de silla, minutos del rehabilitador, margen en pesos, máximo semanal de demanda
    "control": (30, 0, 80_000, 120),
    "limpieza": (40, 0, 60_000, 60),
    "blanqueamiento": (60, 30, 250_000, 12),
    "carilla": (120, 120, 900_000, 6),
}
CHAIR_MINUTES = 2 * 6 * 9 * 60          # dos sillas, seis días, nueve horas
REHAB_MINUTES = 3 * 210                 # tres tardes de tres horas y media


def solve(integer: bool):
    prob = pulp.LpProblem("mezcla_chapinero", pulp.LpMaximize)
    n = prob.add_variable_dicts("n", list(PROCS), lowBound=0, cat="Integer" if integer else "Continuous")
    prob += pulp.lpSum(PROCS[p][2] * n[p] for p in PROCS)
    prob += pulp.lpSum(PROCS[p][0] * n[p] for p in PROCS) <= CHAIR_MINUTES, "silla"
    prob += pulp.lpSum(PROCS[p][1] * n[p] for p in PROCS) <= REHAB_MINUTES, "rehabilitador"
    for p in PROCS:
        prob += n[p] <= PROCS[p][3], f"demanda_{p}"
    stats = prob.solve(pulp.HiGHS(msg=False))
    return prob, {p: n[p].value() for p in PROCS}, stats


prob, mix, stats = solve(integer=False)
print("lineal:", {p: round(v, 2) for p, v in mix.items()}, f"· margen ${stats.objective:,.0f}")
for c in prob.constraints():                     # PuLP 4: un método que devuelve la lista
    if c.pi:
        print(f"  precio sombra de {c.name}: ${c.pi:,.0f} por unidad")

_, mix_int, stats_int = solve(integer=True)
print("entera:", {p: int(v) for p, v in mix_int.items()}, f"· margen ${stats_int.objective:,.0f}")
```

```bash
python3 mezcla_chapinero.py
```

Salida (Python 3.14.7, 05/10/2026):

```text
lineal: {'control': 120.0, 'limpieza': 56.25, 'blanqueamiento': 0.0, 'carilla': 5.25} · margen $17,700,000
  precio sombra de silla: $-1,500 por unidad
  precio sombra de rehabilitador: $-6,000 por unidad
  precio sombra de demanda_control: $-35,000 por unidad
entera: {'control': 120, 'limpieza': 55, 'blanqueamiento': 1, 'carilla': 5} · margen $17,650,000
```

La versión lineal agenda 56,25 limpiezas y 5,25 carillas: el óptimo de un mundo con cuartos de carilla. La entera agenda 55 y 5, más un
blanqueamiento que usa los minutos sobrantes del rehabilitador, y deja $50.000 menos de margen: es el precio de que las carillas vengan
enteras. Los precios sombra responden la pregunta de Julián, con dos lecturas que hay que hacer con cuidado. La primera: **el signo es la
convención de HiGHS** para un problema de maximización con restricciones `<=`; lo que importa es la magnitud. Un minuto de silla vale $1.500
—el margen por minuto de la limpieza, que es el procedimiento que absorbería el minuto extra—, un minuto del rehabilitador vale $6.000, y
un control más de demanda, $35.000. La segunda: esos valores valen **en un rango**. La limpieza está a 3,75 de su tope de demanda (60), así
que el precio de $1.500 por minuto de silla dura unos 150 minutos; una tercera silla, con 3 240 minutos, no vale 3 240 × $1.500. Para
saberlo, se vuelve a resolver con tres sillas (ejercicio 2).

**Detalles con intención**

- **`prob.constraints()` es un método en PuLP 4** (en la 3 era un diccionario, `prob.constraints.items()`): otro cambio de la reescritura
  que encontró la primera corrida.
- **Las restricciones llevan nombre** (`"silla"`, `"rehabilitador"`): es lo que permite leer después el precio sombra de cada una por
  su nombre.
- **El precio sombra solo existe en la versión lineal**: en la entera, "aflojar una unidad" no tiene una derivada. Por eso se resuelven
  las dos: la lineal para entender, la entera para agendar.
- **Las restricciones de demanda** también tienen precio sombra: si es positivo, vender una unidad más de ese procedimiento mejoraría el
  margen, y la conversación es de mercadeo, no de sillas.

---

## ⚠️ 4. Lo que se rompe

**Redondear la solución lineal.** La lineal puede decir 4,5 carillas; redondear a 5 puede violar una restricción, y redondear a 4 puede no
ser el óptimo entero. Se resuelve la entera.

**Leer el precio sombra fuera de su rango.** El precio sombra vale mientras la base de la solución no cambie: un minuto más de silla vale
$X, pero tres mil minutos más quizás no, porque en algún punto otra restricción pasa a mandar. Para una decisión grande (una silla nueva),
se vuelve a resolver con la capacidad nueva.

**Un modelo entero grande sin límite de tiempo.** Un MIP puede tardar horas en demostrar el óptimo. Se le pone límite de tiempo y de brecha
(`gapRel`), y se acepta "a menos de 1 % del óptimo" cuando es lo razonable.

**Coeficientes en escalas muy distintas.** Márgenes en millones junto a minutos en decenas producen problemas numéricos en cualquier
solucionador. Se escalan las unidades (margen en miles de pesos) si aparecen avisos numéricos.

---

## ⚖️ 5. Cuándo NO usarlo

**Si las relaciones no son lineales.** "El margen baja si hago demasiadas limpiezas seguidas" no es lineal; se aproxima por tramos o se pasa
a otra técnica (`so06`).

**Para una decisión de una vez con cuatro variables.** Una hoja de cálculo con Solver hace lo mismo, y Patricia ya la sabe usar.

**Si los datos no son confiables.** Los márgenes por procedimiento tienen que venir de la contabilidad; un modelo con márgenes inventados
da una mezcla óptima para un negocio que no existe.

---

## 🧪 6. Ejercicios (10)

**🟢 Fácil (1–3)**

1. Corre el ejemplo. **Criterio:** explicas qué restricción manda (la que tiene precio sombra) y por qué.
2. Agrega una silla (`CHAIR_MINUTES` con tres sillas) y vuelve a resolver. **Criterio:** el margen nuevo, contra lo que predecía el precio
   sombra.
3. Agrega una tarde más del rehabilitador. **Criterio:** cuánto vale en margen, y si conviene más que la silla.

**🟡 Intermedio (4–6)**

4. Resuelve el mismo modelo con la API de `highspy` directamente. **Criterio:** el mismo óptimo, y cuántas líneas más o menos.
5. Agrega una restricción: al menos 40 controles por semana (compromiso con los pacientes en tratamiento). **Criterio:** el costo de esa
   restricción en margen.
6. Lee la holgura (`slack`) de cada restricción. **Criterio:** cuántos minutos de silla quedan libres en la solución entera.

**🟠 Difícil (7–9)**

7. Haz el modelo para las diez sedes con un rehabilitador compartido que se reparte. **Criterio:** dónde conviene que pase sus tardes.
8. Agrega una variable binaria "abrir el sábado" con un costo fijo. **Criterio:** el modelo decide si abrir, y explicas cómo se escribe
   un costo fijo en un modelo lineal.
9. Escribe el mismo modelo en Pyomo. **Criterio:** el mismo óptimo, y qué te dio Pyomo que PuLP no.

**🔴 Muy difícil (10)**

10. Prepara para Julián la respuesta a "¿nos conviene una tercera silla en Chapinero?". **Criterio:** una página. *Rúbrica:* (a) el modelo y de dónde salen
    los datos; (b) el margen con dos y con tres sillas; (c) el precio sombra y su límite de validez; (d) qué supuestos podrían cambiar la
    respuesta.

---

## 📚 7. Referencias

**Documentación oficial**

- PuLP: https://coin-or.github.io/pulp/
- HiGHS: https://highs.dev/
- Pyomo: https://pyomo.readthedocs.io/en/stable/

**Libro**

- Robert J. Vanderbei, *Linear Programming: Foundations and Extensions*, 5.ª ed. (Springer, 2020).

**Orden de lectura sugerido:** el capítulo de dualidad de Vanderbei, que explica qué es un precio sombra y por qué existe; después la
documentación de HiGHS.

---

## 🚀 8. Cierre

La programación lineal decide cantidades bajo restricciones y, de paso, dice cuánto vale aflojar cada restricción. La entera da la respuesta
que se puede ejecutar. Se resuelven las dos: la lineal para entender y responder "¿cuánto vale una silla más?", la entera para agendar.

**La señal de que quedó bien:** *"Julián preguntó si convenía otra silla en Chapinero, y la respuesta llegó con el número y con el rango en
que ese número vale."*

> 🏷️ **Cierra la sección con su tag**, cuando los ejercicios que elegiste estén hechos:
>
> ```bash
> git tag -a op-so-fase-02 -m "op so02 cerrada: la mezcla de Chapinero, lineal con precios sombra y entera"
> ```
>
> Los commits llevan su prefijo (`op so02: …`) y los de ejercicio su número
> (`op so02 ej07: …`).
