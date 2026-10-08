# 🎲 so06 — Cuando no hay modelo

> Python para desarrolladores Java senior · **Carta** · Track `so` — Optimización, simulación y
> decisiones · sección 6 de 7
> Se lee suelta: no hace falta ninguna otra sección de la carta.
> Versiones verificadas contra PyPI el 05/10/2026 · Código probado el 05/10/2026 con Python 3.14.7,
> en contenedor: las salidas son las de esa corrida.

---

## 🎯 1. Qué problema resuelve

Áurea manda dos recordatorios por WhatsApp antes de cada cita, y la pregunta de cuándo mandarlos no tiene una fórmula: muy temprano y
el paciente lo olvida, muy tarde y no alcanza a reorganizarse; dos muy seguidos molestan. Lo que sí hay es una forma de **evaluar** una
política: el simulador del ausentismo que se calibró con la historia de citas (`ds08`) dice, para una pareja de horas,
qué porcentaje de pacientes faltaría. Es una caja negra: se le dan dos números y devuelve otro, con ruido.

Las secciones anteriores tenían un modelo explícito —restricciones lineales, reglas lógicas— que el solucionador aprovechaba. Aquí no
hay nada que aprovechar: solo se puede **probar** puntos y mirar qué sale. Es el terreno de la **optimización de caja negra**:
`scipy.optimize` para las funciones razonables, metaheurísticas (evolución diferencial, algoritmos genéticos) para las difíciles, y
**Optuna** cuando cada evaluación es cara. La pregunta honesta de esta sección es otra: **cuántas evaluaciones cuesta acercarse**, y
cuándo "bueno y rápido" le gana a "óptimo y tarde".

---

## 🧠 2. El modelo

| Método | Usa la forma de la función | Evaluaciones típicas | Para qué |
|---|---|---|---|
| Rejilla exhaustiva | No | Todas las combinaciones | Pocos parámetros con pocos valores; la vara de medir |
| `scipy.optimize.minimize` (Nelder-Mead, BFGS…) | Supone suavidad | Pocas | Funciones suaves, sin mucho ruido |
| `scipy.optimize.differential_evolution` | No | Cientos | Funciones con varios mínimos o ruido |
| Optuna (TPE) | No; aprende de las evaluaciones anteriores | Decenas | **Evaluaciones caras**: hiperparámetros, simulaciones lentas |
| `deap` (algoritmos genéticos) | No | Miles | Espacios raros: permutaciones, estructuras |

### Tu instinto de Java dice… y esta vez se equivoca

El instinto prueba todas las combinaciones con dos `for` anidados. Con dos parámetros y una evaluación de milisegundos, está bien, y el
ejemplo lo usa como vara. Con cinco parámetros, o con una simulación que tarda un minuto, la rejilla deja de ser posible, y la pregunta
pasa a ser cuántas evaluaciones se pueden pagar.

---

## 💻 3. El ejemplo que corre

```bash
uv add scipy optuna numpy
```

`recordatorios.py`:

```python
"""¿Cuándo mandar los dos recordatorios? Caja negra con ruido: rejilla, SciPy y Optuna, contando evaluaciones."""

import itertools
import math

import numpy as np
import optuna
from scipy.optimize import differential_evolution

calls = 0


def no_show_rate(first_h: float, second_h: float, patients: int = 4_000, seed: int | None = None) -> float:
    """Simulador de ausentismo (de juguete): horas antes de la cita del primer y del segundo recordatorio."""
    global calls
    calls += 1
    rng = np.random.default_rng(seed)
    base = 0.09 + 0.02 * math.log1p(abs(first_h - 30) / 6) + 0.025 * math.log1p(abs(second_h - 3) / 1.5)
    annoyed = 0.03 if abs(first_h - second_h) < 4 else 0.0          # dos mensajes casi seguidos molestan
    return rng.binomial(patients, min(base + annoyed, 1.0)) / patients


def objective(h):                                                  # ruido incluido: cada llamada es una simulación nueva
    return no_show_rate(h[0], h[1])


def report(name: str, h1: float, h2: float):
    global calls
    used, calls = calls, 0
    check = no_show_rate(h1, h2, patients=400_000, seed=1)           # reevaluación grande, casi sin ruido
    calls = 0
    print(f"{name:<24} primero {h1:5.1f} h · segundo {h2:4.1f} h · ausentismo {check:6.2%} · {used:4d} evaluaciones")


grid = min(itertools.product(range(1, 73), range(1, 13)), key=objective)
report("rejilla (72 × 12)", *grid)

de = differential_evolution(objective, bounds=[(1, 72), (1, 12)], seed=3, maxiter=20, polish=False)
report("evolución diferencial", *de.x)

optuna.logging.set_verbosity(optuna.logging.WARNING)
study = optuna.create_study(sampler=optuna.samplers.TPESampler(seed=3))
study.optimize(lambda t: objective((t.suggest_float("first", 1, 72), t.suggest_float("second", 1, 12))), n_trials=60)
report("Optuna (TPE)", study.best_params["first"], study.best_params["second"])

report("lo que se hace hoy", 48, 24)
```

```bash
python3 recordatorios.py
```

Salida (Python 3.14.7, 05/10/2026):

```text
rejilla (72 × 12)        primero  29.0 h · segundo  3.0 h · ausentismo  9.28% ·  864 evaluaciones
evolución diferencial    primero  30.6 h · segundo  3.0 h · ausentismo  9.17% ·  630 evaluaciones
Optuna (TPE)             primero  30.8 h · segundo  1.3 h · ausentismo 11.12% ·   60 evaluaciones
lo que se hace hoy       primero  48.0 h · segundo 24.0 h · ausentismo 18.51% ·    0 evaluaciones
```

Los tres métodos mejoran mucho lo que se hace hoy (18,5 % de ausentismo), y no por igual. La rejilla, con 864 evaluaciones, encuentra 29 y
3 horas: 9,3 %. La evolución diferencial, con 630, llega un poco más abajo (9,2 %) porque busca en valores continuos, no solo en horas
enteras. Optuna, con 60, encontró bien el primer recordatorio y se quedó corta en el segundo: 11,1 %. Es la cuenta honesta del método:
**con un 7 % de las evaluaciones recorrió la mayor parte del camino**, no todo. Si cada evaluación tarda un minuto, 60 son una hora y 864
son catorce; con ese presupuesto, se corre Optuna con más intentos (ejercicio 2) antes que la rejilla.

**Detalles con intención**

- **El simulador es de juguete** y está a la vista para que el ejemplo corra solo; en Áurea sería el modelo de ausentismo calibrado. Lo que
  importa es que el optimizador **no lo ve por dentro**: solo le pasa números y recibe un porcentaje con ruido.
- **La reevaluación con 400 000 pacientes** separa el ruido del resultado: el mejor punto de una búsqueda con ruido suele ser, en parte, un
  punto con suerte. Se confirma con una evaluación grande antes de creerlo.
- **`polish=False`** en la evolución diferencial: el pulido final usa un método de gradiente que con ruido se confunde.
- **Optuna** propone el siguiente punto según lo que vio antes (TPE): no recorre el espacio parejo, se concentra donde los resultados fueron
  buenos. Con ruido, a veces se concentra en un punto que tuvo suerte; por eso también se reevalúa.

---

## ⚠️ 4. Lo que se rompe

**Creerle al mejor valor visto.** Con ruido, el mínimo de 864 evaluaciones ruidosas está sesgado hacia abajo: es el punto que tuvo más
suerte. Por eso la reevaluación grande.

**Gradientes sobre una simulación.** `minimize` con BFGS calcula derivadas por diferencias finitas; con ruido, las derivadas son ruido. Para
cajas negras ruidosas, métodos sin gradiente.

**El óptimo en el borde.** Si el mejor punto está en el límite del rango (72 horas, 1 hora), probablemente el rango está mal, no el
fenómeno. Se amplía y se vuelve a buscar.

**Optimizar sobre un simulador sin validar.** El resultado es tan bueno como el simulador. Antes de cambiar la política de recordatorios
con base en él, se prueba en una sede con una comparación A/B.

---

## ⚖️ 5. Cuándo NO usarlo

**Si hay un modelo explícito.** Si el problema se puede escribir con restricciones y objetivo (`so02`, `so03`), un solucionador encuentra el
óptimo y lo demuestra; una metaheurística no demuestra nada.

**Si se puede preguntar.** Una prueba A/B de dos políticas en dos sedes durante un mes dice más que mil evaluaciones de un simulador dudoso.

**Para ajustar diez parámetros con cien datos.** El optimizador va a encontrar una combinación que se ajusta al ruido de esos cien datos.

---

## 🧪 6. Ejercicios (10)

**🟢 Fácil (1–3)**

1. Corre el ejemplo. **Criterio:** cuánto mejora cada método sobre lo que se hace hoy, y cuántas evaluaciones costó.
2. Corre Optuna con 20, 60 y 200 intentos. **Criterio:** el ausentismo reevaluado de cada uno.
3. Quita la reevaluación y reporta el valor que encontró cada método. **Criterio:** cuánto más optimista es que el reevaluado.

**🟡 Intermedio (4–6)**

4. Usa `scipy.optimize.minimize` con Nelder-Mead desde (48, 24). **Criterio:** dónde termina y por qué.
5. Agrega una restricción: el segundo recordatorio no puede salir entre las 22:00 y las 7:00. **Criterio:** cómo la expresas en cada método.
6. Haz que cada evaluación tarde 50 ms (`time.sleep`). **Criterio:** el tiempo total de cada método.

**🟠 Difícil (7–9)**

7. Agrega un tercer parámetro: el canal del primer recordatorio (WhatsApp o SMS). **Criterio:** Optuna con un parámetro categórico.
8. Usa `deap` para buscar la secuencia de tres recordatorios como permutación de horas candidatas. **Criterio:** el mejor encontrado y las
   evaluaciones.
9. Diseña la prueba A/B que validaría la política nueva en dos sedes. **Criterio:** tamaño de muestra, duración y criterio de éxito.

**🔴 Muy difícil (10)**

10. Propón la política de recordatorios de Áurea. **Criterio:** una página. *Rúbrica:* (a) el simulador y su validación; (b) el método de
    búsqueda y el presupuesto de evaluaciones; (c) el resultado reevaluado contra lo actual; (d) la prueba en el mundo real antes de
    adoptarlo.

---

## 📚 7. Referencias

**Documentación oficial**

- `scipy.optimize`: https://docs.scipy.org/doc/scipy/reference/optimize.html
- Optuna: https://optuna.readthedocs.io/en/stable/
- `deap`: https://deap.readthedocs.io/en/master/

**Orden de lectura sugerido:** el tutorial de Optuna (que es corto y explica el muestreo); después la guía de `scipy.optimize` para saber qué
método supone qué.

---

## 🚀 8. Cierre

Cuando no hay modelo, solo se puede probar puntos. La rejilla es la vara cuando es barata; SciPy sirve para funciones suaves; la evolución
diferencial y Optuna para cajas negras con ruido, y Optuna cuando cada evaluación es cara. Con ruido, el mejor valor visto miente un poco: se
reevalúa, y lo que se adopta se prueba en el mundo real.

**La señal de que quedó bien:** *"La política nueva de recordatorios salió del simulador con un presupuesto de evaluaciones decidido de
antemano, y la prueba en Kennedy confirmó la mejora."*

> 🏷️ **Cierra la sección con su tag**, cuando los ejercicios que elegiste estén hechos:
>
> ```bash
> git tag -a op-so-fase-06 -m "op so06 cerrada: caja negra con ruido, evaluaciones contadas y reevaluadas"
> ```
>
> Los commits llevan su prefijo (`op so06: …`) y los de ejercicio su número
> (`op so06 ej07: …`).
