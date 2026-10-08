# 🧮 so01 — Describir el problema en vez de programarlo

> Python para desarrolladores Java senior · **Carta** · Track `so` — Optimización, simulación y
> decisiones · sección 1 de 7
> Se lee suelta: no hace falta ninguna otra sección de la carta.
> Versiones verificadas contra PyPI el 05/10/2026 · Código probado el 05/10/2026 con Python 3.14.7,
> en contenedor: las salidas son las de esa corrida.

---

## 🎯 1. Qué problema resuelve

Los sábados, Áurea no tiene especialistas en todas las sedes: los ortodoncistas y rehabilitadores que trabajan entre semana en
el Centro se reparten para cubrir las sedes que tienen agenda de sábado. Patricia arma el reparto en una hoja: cada especialista
a una sede, ninguna sede sin cubrir, y que nadie cruce la ciudad si puede evitarlo. Le toma una hora, y el resultado depende de
por qué sede empezó.

El reflejo de un senior de Java ante este problema es escribir el algoritmo: ordenar, recorrer, asignar al más cercano, manejar
los casos especiales. Funciona, da una respuesta, y casi nunca es la mejor. Este track propone el giro contrario, que es el más
importante de todos: **describir el problema** —qué se decide, qué no se puede violar, qué se quiere minimizar— y dejar que un
**solucionador** encuentre la respuesta. Se parece más a escribir SQL que a escribir un algoritmo: se declara qué se quiere, no
cómo buscarlo. Y Python es la interfaz estándar de esa disciplina: los solucionadores están en C++ y se manejan desde aquí.

---

## 🧠 2. El modelo

| Pieza | Qué es | En el reparto del sábado |
|---|---|---|
| **Variables de decisión** | Lo que el solucionador elige | `x[e, s] = 1` si el especialista `e` va a la sede `s` |
| **Restricciones** | Lo que no se puede violar | Cada sede, cubierta; cada especialista, en una sede como máximo |
| **Función objetivo** | Lo que se minimiza o maximiza | Los minutos de desplazamiento totales |
| **Solucionador** | Quien busca | HiGHS, CBC, CP-SAT (`so02`, `so03`) |

```mermaid
flowchart LR
    D["Datos<br/>(minutos de cada especialista a cada sede)"] --> M["Modelo<br/>variables + restricciones + objetivo"]
    M --> S["Solucionador<br/>(HiGHS)"]
    S --> R["Reparto óptimo<br/>y la prueba de que lo es"]
```

### Tu instinto de Java dice… y esta vez se equivoca

El instinto dice: "lo programo yo, un algoritmo voraz bien pensado basta". El voraz es rápido y da una respuesta razonable; lo que
no da es **la mejor**, ni la certeza de cuánto se aleja de ella. Y el día que llega una regla nueva —"la ortodoncista 3 no puede ir a
Soacha", "el Centro necesita dos"—, el voraz se reescribe y el modelo recibe una línea.

---

## 💻 3. El ejemplo que corre

```bash
uv add pulp highspy
```

`reparto_sabado.py`:

```python
"""El reparto de especialistas del sábado: el algoritmo voraz contra el modelo declarado."""

import random

import pulp

SEDES = ["Chapinero", "Kennedy", "Usaquén", "Engativá", "Fontibón", "Restrepo", "Soacha"]   # sedes propias; las franquicias tienen su personal
SPECIALISTS = [f"esp-{i:02d}" for i in range(1, 11)]
random.seed(10)
minutes = {(e, s): random.randint(10, 90) for e in SPECIALISTS for s in SEDES}


# ------------------------------------------------- 1. lo que escribiría el instinto: voraz por sede
def greedy() -> dict[str, str]:
    free, plan = set(SPECIALISTS), {}
    for s in SEDES:
        best = min(free, key=lambda e: minutes[e, s])
        plan[s] = best
        free.remove(best)
    return plan


# ------------------------------------------------- 2. el problema descrito
def model(extra_rules: bool = False) -> tuple[dict[str, list[str]], float, str]:
    prob = pulp.LpProblem("reparto_sabado", pulp.LpMinimize)
    x = prob.add_variable_dicts("x", [(e, s) for e in SPECIALISTS for s in SEDES], cat="Binary")   # PuLP 4: desde el problema
    prob += pulp.lpSum(minutes[e, s] * x[e, s] for e in SPECIALISTS for s in SEDES)          # objetivo
    for s in SEDES:
        prob += pulp.lpSum(x[e, s] for e in SPECIALISTS) >= (2 if extra_rules and s == "Kennedy" else 1)
    for e in SPECIALISTS:
        prob += pulp.lpSum(x[e, s] for s in SEDES) <= 1
    if extra_rules:
        prob += x["esp-03", "Soacha"] == 0                                                  # una regla, una línea
    stats = prob.solve(pulp.HiGHS(msg=False))                                                  # PuLP 4: devuelve el resultado
    plan = {s: [e for e in SPECIALISTS if x[e, s].value() > 0.5] for s in SEDES}
    return plan, stats.objective, stats.status.name


g = greedy()
print("voraz:          ", sum(minutes[e, s] for s, e in g.items()), "minutos")
plan, total, status = model()
print("modelo:         ", int(total), "minutos ·", status)
plan2, total2, status2 = model(extra_rules=True)
print("con dos reglas: ", int(total2), "minutos ·", status2, "· Kennedy:", plan2["Kennedy"], "· Soacha:", plan2["Soacha"])
```

```bash
python3 reparto_sabado.py
```

Salida (Python 3.14.7, 05/10/2026):

```text
voraz:           147 minutos
modelo:          134 minutos · Optimal
con dos reglas:  157 minutos · Optimal · Kennedy: ['esp-01', 'esp-03'] · Soacha: ['esp-06']
```

El voraz recorre las sedes en orden y le da a cada una su especialista más cercano libre: 147 minutos de desplazamiento. El modelo
encuentra un reparto de 134, un 10 % menos, y lo declara `Optimal`: no hay uno mejor. No es un caso elegido para que el voraz pierda:
con veinte semillas distintas, el voraz empató con el óptimo en seis y perdió en catorce, por entre 2 % y 61 %, con una mediana cercana
al 12 %. Lo que el voraz no puede hacer en ningún caso es decir en cuál de los veinte está. El voraz perdió porque las primeras sedes se
llevaron especialistas que a las últimas les habrían servido más, que es exactamente lo que un algoritmo voraz no puede ver. Y las dos
reglas nuevas —Kennedy necesita dos, esp-03 no va a Soacha— fueron dos líneas: el modelo encontró el nuevo óptimo sin cambiar nada más.

**Detalles con intención**

- **`prob.add_variable_dicts(..., cat="Binary")`** crea una variable 0/1 por cada par (especialista, sede): 70 variables. El modelo no
  dice cómo elegir; dice qué se elige.
- **PuLP 4.0.0 (25/09/2026) reescribió su núcleo en Rust** y las variables ahora se crean desde el problema. El `pulp.LpVariable.dicts`
  de todos los tutoriales y respuestas en internet falla con `AttributeError: type object 'LpVariable' has no attribute 'dicts'`, y
  `pulp.LpStatus[prob.status]` también desapareció: `solve()` devuelve ahora un `LpSolveStats` con `status` (un enum) y `objective`. Las
  dos primeras corridas de este ejemplo lo encontraron, una cada vez. Con un proyecto existente, se fija `pulp<4` hasta migrar.
- **Las restricciones se escriben como en el enunciado**: "cada sede, al menos uno" es una suma `>= 1` por sede; "cada especialista,
  como máximo una" es una suma `<= 1` por especialista.
- **`Optimal`** es la parte que el voraz nunca puede decir: el solucionador **demuestra** que no hay un reparto con menos minutos.
- **HiGHS** es un solucionador de código abierto, rápido, que PuLP usa a través de `highspy`. PuLP trae además CBC, pero no en todas
  las plataformas; declararlo explícitamente evita sorpresas.

---

## ⚠️ 4. Lo que se rompe

**Modelar con `if` de Python.** `if x[e, s].value() == 1:` dentro del modelo no hace nada: las variables no tienen valor hasta que el
solucionador termina. Las condiciones del problema se escriben como restricciones lineales, no como código.

**El modelo sin solución.** Si las reglas se contradicen (más sedes que especialistas, o dos reglas incompatibles), el estado es
`Infeasible`. El código lee el estado (`stats.status`) **antes** de leer la solución; leer variables de un problema sin solución da basura.

**Datos sucios en el objetivo.** El solucionador optimiza lo que se le da: si un tiempo de desplazamiento está mal (0 en vez de 90),
el óptimo lo aprovecha sin dudar. Validar los datos es parte del modelo.

---

## ⚖️ 5. Cuándo NO usarlo

**Si el voraz es suficiente y nadie se queja.** Con cuatro sedes y cinco especialistas, Patricia lo resuelve a ojo, y bien.

**Si el problema no es de decisión.** Calcular una regalía no se optimiza: se calcula.

**Si no se puede escribir el objetivo.** "Que quede bien" no es una función objetivo. Si no se puede poner en números qué es mejor, no
hay nada que el solucionador pueda hacer (`so06`).

---

## 🧪 6. Ejercicios (10)

**🟢 Fácil (1–3)**

1. Corre el ejemplo. **Criterio:** cuántos minutos más usa el voraz, en porcentaje.
2. Cambia la semilla diez veces. **Criterio:** en cuántas el voraz coincide con el óptimo.
3. Agrega una sede más que especialistas. **Criterio:** el estado que reporta el modelo, y lo que haría el voraz.

**🟡 Intermedio (4–6)**

4. Agrega la regla "esp-07 y esp-08 no pueden ir a la misma sede". **Criterio:** una línea de restricción, y el reparto la cumple.
5. Cambia el objetivo a "minimizar el desplazamiento más largo" (justicia, no suma). **Criterio:** el modelo con una variable auxiliar y
   el nuevo reparto.
6. Escribe el voraz que cumpla las dos reglas del ejemplo. **Criterio:** cuántas líneas cambiaste en el voraz y cuántas en el modelo.

**🟠 Difícil (7–9)**

7. Haz que cada especialista tenga una especialidad y cada sede una demanda por especialidad. **Criterio:** el modelo y una solución
   `Optimal`.
8. Mide el tiempo del modelo con 30 sedes y 50 especialistas. **Criterio:** el tiempo de construcción y el de resolución.
9. Exporta el modelo a formato LP (`prob.writeLP`) y léelo. **Criterio:** reconoces cada restricción del código en el archivo.

**🔴 Muy difícil (10)**

10. Lleva el reparto de los sábados de Áurea a un modelo. **Criterio:** una página y el código. *Rúbrica:* (a) variables, restricciones
    y objetivo escritos en palabras antes que en código; (b) qué datos necesita y de dónde salen; (c) cómo se valida un reparto contra la
    hoja de Patricia; (d) qué pasa cuando no hay solución.

---

## 📚 7. Referencias

**Documentación oficial**

- PuLP: https://coin-or.github.io/pulp/
- HiGHS: https://highs.dev/

**Libro**

- H. Paul Williams, *Model Building in Mathematical Programming*, 5.ª ed. (Wiley, 2013). El libro de referencia para aprender a
  describir problemas.

**Orden de lectura sugerido:** el inicio rápido de PuLP; después los primeros capítulos de Williams, que enseñan a modelar sin depender
de ningún solucionador.

---

## 🚀 8. Cierre

Hay problemas que se describen en vez de programarse: variables, restricciones y objetivo, y un solucionador que encuentra la respuesta y
demuestra que es la mejor. El voraz que escribiría el instinto da una respuesta; el modelo da la óptima, y una regla nueva es una línea.

**La señal de que quedó bien:** *"Patricia ya no arma el reparto del sábado: revisa el que sale del modelo, y cuando cambia una regla,
cambia una línea."*

> 🏷️ **Cierra la sección con su tag**, cuando los ejercicios que elegiste estén hechos:
>
> ```bash
> git tag -a op-so-fase-01 -m "op so01 cerrada: el reparto del sábado descrito, no programado"
> ```
>
> Los commits llevan su prefijo (`op so01: …`) y los de ejercicio su número
> (`op so01 ej07: …`).
