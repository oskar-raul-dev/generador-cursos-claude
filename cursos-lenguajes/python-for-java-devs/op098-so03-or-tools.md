# 🧩 so03 — OR-Tools y CP-SAT

> Python para desarrolladores Java senior · **Carta** · Track `so` — Optimización, simulación y
> decisiones · sección 3 de 7
> Se lee suelta: no hace falta ninguna otra sección de la carta.
> Versiones verificadas contra PyPI el 05/10/2026 · Código probado el 05/10/2026 con Python 3.14.7,
> en contenedor: las salidas son las de esa corrida.

---

## 🎯 1. Qué problema resuelve

Los turnos de recepción son el problema que más tiempo le quita a Patricia cada mes. Cuatro sedes propias con recepción mañana y
tarde, de lunes a sábado; nueve recepcionistas, cada una con su tope de turnos, su sede habitual, y reglas que se han negociado
durante años: Yuli Chaparro no trabaja sábados, otra no puede cerrar los viernes, nadie hace mañana y tarde el mismo día. Cada cambio de una regla obliga a rehacer la hoja entera.

Este es el tipo de problema que parece imposible por la cantidad de combinaciones, y que un solucionador moderno resuelve en
segundos. **CP-SAT**, el solucionador de restricciones de **OR-Tools** de Google, está hecho para esto: variables enteras y
booleanas, restricciones lógicas ("si trabaja la tarde, no la mañana"), y un objetivo que mezcla lo obligatorio con lo preferible.
Desde Python se escribe el modelo como en `so01`; la diferencia es el tipo de restricciones que acepta, mucho más expresivo que la
programación lineal.

---

## 🧠 2. El modelo

| Tipo de regla | Ejemplo en los turnos | Cómo se escribe en CP-SAT |
|---|---|---|
| Cobertura (dura) | Cada sede, cada día, una persona en la mañana y una en la tarde | `sum(...) == 1` |
| Tope (dura) | Nadie hace más de 6 turnos por semana | `sum(...) <= 6` |
| Exclusión (dura) | Nadie hace mañana y tarde el mismo día | `sum(...) <= 1` por persona y día |
| Indisponibilidad (dura) | Yuli no trabaja sábados | La variable fijada en 0 |
| Preferencia (blanda) | Que cada una trabaje en su sede habitual | Penalidad en el objetivo |
| Equidad (blanda) | Que la diferencia de turnos entre la que más y la que menos sea pequeña | Variables de máximo y mínimo |

| | Programación lineal entera (`so02`) | CP-SAT |
|---|---|---|
| Variables | Continuas y enteras | Enteras y booleanas |
| Restricciones | Lineales | Lineales **y lógicas**: implicaciones, `AllDifferent`, intervalos sin solape |
| Fuerte en | Mezclas, flujos, presupuestos | **Horarios, turnos, secuenciación, empaquetado** |

### Tu instinto de Java dice… y esta vez se equivoca

El instinto ante los turnos es *backtracking* escrito a mano, o una hoja con macros. Con nueve personas y 48 turnos en la semana (cuatro
sedes, seis días, mañana y tarde), las asignaciones posibles son del orden de 9⁴⁸: más que átomos en la Tierra. CP-SAT no las recorre; propaga
restricciones, aprende de los conflictos y usa varios hilos que buscan distinto. El resultado es un horario óptimo, o la demostración
de que con esas reglas no existe ninguno.

---

## 💻 3. El ejemplo que corre

```bash
uv add ortools
```

`turnos.py`:

```python
"""Los turnos de recepción de una semana con CP-SAT: reglas duras, preferencias y equidad."""

from ortools.sat.python import cp_model

SEDES = ["Centro", "Chapinero", "Kennedy", "Usaquén"]
DAYS = ["lun", "mar", "mié", "jue", "vie", "sáb"]
SHIFTS = ["mañana", "tarde"]
STAFF = {"Yuli": "Centro", "rec-02": "Centro", "rec-03": "Chapinero", "rec-04": "Chapinero", "rec-05": "Kennedy",
         "rec-06": "Kennedy", "rec-07": "Usaquén", "rec-08": "Usaquén", "rec-09": "Centro"}

m = cp_model.CpModel()
work = {(p, s, d, t): m.new_bool_var(f"{p}_{s}_{d}_{t}") for p in STAFF for s in SEDES for d in DAYS for t in SHIFTS}

for s in SEDES:                                          # cobertura: una persona por sede, día y turno
    for d in DAYS:
        for t in SHIFTS:
            m.add_exactly_one(work[p, s, d, t] for p in STAFF)
for p in STAFF:
    m.add(sum(work[p, s, d, t] for s in SEDES for d in DAYS for t in SHIFTS) <= 6)       # tope semanal
    for d in DAYS:
        m.add_at_most_one(work[p, s, d, t] for s in SEDES for t in SHIFTS)              # un turno por día
for s in SEDES:                                          # Yuli no trabaja sábados
    for t in SHIFTS:
        m.add(work["Yuli", s, "sáb", t] == 0)
for s in SEDES:                                          # rec-03 no cierra los viernes
    m.add(work["rec-03", s, "vie", "tarde"] == 0)

away = sum(work[p, s, d, t] for p, home in STAFF.items() for s in SEDES if s != home for d in DAYS for t in SHIFTS)
load = {p: sum(work[p, s, d, t] for s in SEDES for d in DAYS for t in SHIFTS) for p in STAFF}
most, least = m.new_int_var(0, 6, "most"), m.new_int_var(0, 6, "least")
for p in STAFF:
    m.add(most >= load[p])
    m.add(least <= load[p])
m.minimize(10 * away + (most - least))                   # primero la sede habitual, después la equidad

solver = cp_model.CpSolver()
solver.parameters.max_time_in_seconds = 10
status = solver.solve(m)
print(solver.status_name(status), f"en {solver.wall_time:.2f} s · fuera de su sede: {int(solver.value(away))} turnos",
      f"· carga entre {solver.value(least)} y {solver.value(most)}")
for s in SEDES:
    row = [next(p for p in STAFF if solver.value(work[p, s, d, t])) for d in DAYS for t in SHIFTS]
    print(f"  {s:<10}", " ".join("Yu" if p == "Yuli" else p[-2:] for p in row))
```

```bash
python3 turnos.py
```

Salida (Python 3.14.7, 05/10/2026):

```text
OPTIMAL en 0.03 s · fuera de su sede: 0 turnos · carga entre 4 y 6
  Centro     09 02 Yu 02 Yu 09 Yu 02 Yu 09 02 09
  Chapinero  04 03 03 04 04 03 04 03 03 04 03 04
  Kennedy    06 05 05 06 06 05 06 05 06 05 06 05
  Usaquén    08 07 07 08 07 08 08 07 08 07 08 07
```

Las columnas son lunes mañana, lunes tarde, y así hasta el sábado tarde. En 0,03 segundos, CP-SAT encontró un horario y **demostró**
que es óptimo: nadie trabaja fuera de su sede, Yuli (`Yu`) hace cuatro mañanas y ningún sábado, y rec-03 no cierra el viernes (la
décima columna de Chapinero es de rec-04). La carga va de 4 a 6 turnos, y no es un descuido de la equidad: es su precio. Con la sede
habitual pesando diez veces más, el Centro reparte sus doce turnos entre tres personas (4 cada una) y las otras sedes entre dos (6
cada una); igualar las cargas exigiría mandar gente del Centro a otras sedes. Si Patricia prefiere la equidad, cambia un peso, no el
programa.

**Detalles con intención**

- **`new_bool_var` por cada combinación** (persona, sede, día, turno): 432 variables booleanas. CP-SAT trabaja bien con muchas variables
  booleanas; es su terreno.
- **`add_exactly_one` y `add_at_most_one`** son restricciones lógicas que CP-SAT trata mejor que la suma equivalente: le dicen al
  solucionador la estructura del problema.
- **El objetivo pondera**: un turno fuera de la sede habitual pesa diez veces más que un punto de desigualdad. Los pesos son una decisión
  de negocio, y se escriben donde Patricia los pueda discutir.
- **`max_time_in_seconds`** pone un límite: si no demuestra el óptimo a tiempo, devuelve `FEASIBLE` con la mejor solución encontrada. Para
  un horario semanal, diez segundos sobran.

---

## ⚠️ 4. Lo que se rompe

**Reglas que se contradicen.** Si se agregan reglas hasta que no existe horario posible, el estado es `INFEASIBLE` y no hay horario que
mostrar. La salida no es quitar reglas al azar: CP-SAT puede marcar las restricciones con literales de supuesto (`add_assumptions`) y
devolver un subconjunto en conflicto, que es la conversación que hay que tener con las personas.

**Todo como regla dura.** Las preferencias escritas como restricciones duras vuelven el problema inviable con facilidad. Lo que se puede
negociar va al objetivo con un peso; lo que no, a las restricciones.

**Pesos sin escala.** Si una penalidad es 1 y otra 1 000 000, la pequeña no influye nunca. Los pesos se eligen sabiendo qué se está
intercambiando ("un turno fuera de sede vale lo mismo que diez de desigualdad").

**Un modelo sin probar con los datos del mes difícil.** El horario de una semana normal sale; el de la semana con dos vacaciones y una
incapacidad es el que importa. Se prueba con ese.

---

## ⚖️ 5. Cuándo NO usarlo

**Para una sede con dos recepcionistas.** Se hace a mano en cinco minutos.

**Si las reglas cambian cada semana y nadie las escribe.** El modelo necesita reglas explícitas; si viven en la cabeza de Patricia, el
primer trabajo es escribirlas, con o sin solucionador.

**Para problemas lineales con variables continuas.** HiGHS (`so02`) es mejor ahí.

---

## 🧪 6. Ejercicios (10)

**🟢 Fácil (1–3)**

1. Corre el ejemplo. **Criterio:** verificas a mano que Yuli no trabaja el sábado y que rec-03 no cierra el viernes.
2. Baja el tope semanal a 5 turnos. **Criterio:** el estado que devuelve, y la cuenta que lo explica (nueve personas, 48 turnos).
3. Quita el término de equidad del objetivo. **Criterio:** cómo cambia la diferencia de carga.

**🟡 Intermedio (4–6)**

4. Agrega la regla "nadie trabaja más de cuatro días seguidos". **Criterio:** la restricción y un horario que la cumple.
5. Haz que el sábado cuente doble para la equidad. **Criterio:** el modelo y cómo se reparten los sábados.
6. Con el tope en 5, usa `add_assumptions` para encontrar las reglas en conflicto. **Criterio:** la lista que devuelve CP-SAT.

**🟠 Difícil (7–9)**

7. Haz el horario de un mes con vacaciones de dos personas. **Criterio:** el tiempo de solución y el estado.
8. Agrega un horizonte de varias semanas con "nadie cierra más de dos viernes al mes". **Criterio:** la restricción y su cumplimiento.
9. Exporta el horario a un Excel para Patricia (`ui08`). **Criterio:** una hoja por sede, con colores por persona.

**🔴 Muy difícil (10)**

10. Lleva los turnos reales de Áurea a CP-SAT. **Criterio:** una página y el código. *Rúbrica:* (a) las reglas, separadas en duras y
    blandas, escritas con Patricia; (b) los pesos y su justificación; (c) qué pasa el mes en que no hay solución; (d) cómo se corrige a
    mano un horario sin romper las reglas.

---

## 📚 7. Referencias

**Documentación oficial**

- OR-Tools, CP-SAT: https://developers.google.com/optimization/cp/cp_solver
- OR-Tools, programación de turnos (el ejemplo de enfermería): https://developers.google.com/optimization/scheduling/employee_scheduling
- *CP-SAT Primer* (guía comunitaria, muy completa): https://d-krupke.github.io/cpsat-primer/

**Orden de lectura sugerido:** el ejemplo de programación de turnos de OR-Tools; después el *CP-SAT Primer*, que explica cómo modelar bien
y por qué.

---

## 🚀 8. Cierre

CP-SAT resuelve horarios y turnos que parecen imposibles por combinatoria: variables booleanas, restricciones lógicas y un objetivo que
pondera preferencias. Lo duro va a las restricciones y lo negociable al objetivo con un peso discutido; cuando no hay solución, el
solucionador puede decir qué reglas chocan.

**La señal de que quedó bien:** *"Patricia ya no arma los turnos: escribe las reglas del mes, y cuando no hay horario posible, sabe qué
reglas negociar."*

> 🏷️ **Cierra la sección con su tag**, cuando los ejercicios que elegiste estén hechos:
>
> ```bash
> git tag -a op-so-fase-03 -m "op so03 cerrada: los turnos de recepción en CP-SAT, con reglas, pesos y equidad"
> ```
>
> Los commits llevan su prefijo (`op so03: …`) y los de ejercicio su número
> (`op so03 ej07: …`).
