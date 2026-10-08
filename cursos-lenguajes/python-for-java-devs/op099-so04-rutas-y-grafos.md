# 🗺️ so04 — Rutas y grafos

> Python para desarrolladores Java senior · **Carta** · Track `so` — Optimización, simulación y
> decisiones · sección 4 de 7
> Se lee suelta: no hace falta ninguna otra sección de la carta.
> Versiones verificadas contra PyPI el 05/10/2026 · Código probado el 05/10/2026 con Python 3.14.7,
> en contenedor: las salidas son las de esa corrida.

---

## 🎯 1. Qué problema resuelve

Las prótesis, las carillas y los alineadores los fabrica un laboratorio dental externo, y un mensajero en moto los lleva a las
sedes y recoge los moldes nuevos. Hace la ruta todos los días, en el orden que aprendió el primer mes. Cada sede que se abrió después
se agregó "donde quedaba más cerca", y nadie revisó si el orden sigue siendo bueno. Cada kilómetro de más es tiempo del mensajero y
retraso en la entrega.

Es el problema del viajante (*TSP*) y su familia: visitar un conjunto de puntos y volver, con el menor recorrido. Es famoso por
difícil —el número de órdenes posibles crece como el factorial— y a la vez se resuelve en la práctica muy bien para tamaños como el de
Áurea. Desde Python se trabaja con **`networkx`** (grafos y algoritmos clásicos, incluidas aproximaciones al viajante) y, cuando el
problema crece o tiene ventanas de horario, con el módulo de rutas de **OR-Tools**. La sección mide lo que este perfil haría primero
—ir siempre al más cercano— contra las alternativas.

---

## 🧠 2. El modelo

| Método | Garantía | Costo | En `networkx` 3.7 |
|---|---|---|---|
| Fuerza bruta | Óptimo | Factorial: 10 puntos, 362 880 órdenes; 15, más de 87 mil millones | (a mano, con `itertools`) |
| Vecino más cercano (voraz) | Ninguna; en el ejemplo, 15 % arriba | Muy barato | `greedy_tsp` |
| Christofides | A lo sumo 1,5 veces el óptimo, con distancias métricas | Barato | `christofides` |
| Recocido simulado | Ninguna; mejora una solución inicial | Ajustable | `simulated_annealing_tsp` |
| OR-Tools *routing* | Óptimo o casi, con ventanas de tiempo y capacidades | Ajustable | (OR-Tools, ejercicio 7) |

El grafo es la representación: cada sede es un nodo, cada par de sedes una arista con su distancia. Con el grafo construido, la misma
estructura sirve para la ruta, el camino más corto entre dos sedes (Dijkstra) o la sede más central.

### Tu instinto de Java dice… y esta vez se equivoca

El instinto escribe el vecino más cercano: es intuitivo, rápido y "suficientemente bueno". Lo que el instinto no mide es cuánto
queda arriba del óptimo, y en una ruta diaria ese porcentaje se paga trescientos días al año. Medir contra el óptimo —que con diez
sedes se puede calcular— es lo que dice si vale la pena hacer algo mejor.

---

## 💻 3. El ejemplo que corre

```bash
uv add networkx
```

`mensajero.py`:

```python
"""La ruta del mensajero del laboratorio: vecino más cercano, Christofides, recocido y el óptimo exacto."""

import itertools
import math
import time

import networkx as nx
from networkx.algorithms import approximation as approx

# Posiciones aproximadas en km respecto del Centro (para el ejemplo; las distancias reales, en `gi05`).
POINTS = {"Laboratorio": (-3, 2), "Centro": (0, 0), "Chapinero": (1, 4), "Usaquén": (3, 12), "Suba": (-5, 11),
          "Engativá": (-8, 5), "Fontibón": (-10, 1), "Kennedy": (-8, -4), "Restrepo": (-1, -4), "Soacha": (-10, -12)}

G = nx.Graph()
for (a, pa), (b, pb) in itertools.combinations(POINTS.items(), 2):
    G.add_edge(a, b, weight=math.dist(pa, pb))


def length(tour: list[str]) -> float:
    return sum(G[u][v]["weight"] for u, v in itertools.pairwise(tour))


def exact() -> list[str]:
    others = [p for p in POINTS if p != "Laboratorio"]
    best = min(itertools.permutations(others), key=lambda o: length(["Laboratorio", *o, "Laboratorio"]))
    return ["Laboratorio", *best, "Laboratorio"]


start = time.perf_counter()
optimal = exact()
print(f"{'óptimo (fuerza bruta)':<22} {length(optimal):6.1f} km  en {(time.perf_counter() - start) * 1000:8.1f} ms")

methods = {
    "vecino más cercano": lambda: approx.greedy_tsp(G, source="Laboratorio"),
    "Christofides": lambda: approx.traveling_salesman_problem(G, cycle=True, method=approx.christofides),
    "recocido simulado": lambda: approx.simulated_annealing_tsp(G, "greedy", source="Laboratorio", seed=7),
}
for name, solve in methods.items():
    start = time.perf_counter()
    km = length(solve())
    took = time.perf_counter() - start
    print(f"{name:<22} {km:6.1f} km  en {took * 1000:8.1f} ms  ({km / length(optimal) - 1:+.0%} sobre el óptimo)")
print("ruta óptima:", " → ".join(optimal))
```

```bash
python3 mensajero.py
```

Salida (Python 3.14.7, 05/10/2026) (los milisegundos son de la máquina que corre; estos, de un contenedor en un portátil):

```text
óptimo (fuerza bruta)    65.4 km  en    948.1 ms
vecino más cercano       75.3 km  en      0.6 ms  (+15% sobre el óptimo)
Christofides             76.5 km  en      2.9 ms  (+17% sobre el óptimo)
recocido simulado        75.3 km  en      4.3 ms  (+15% sobre el óptimo)
ruta óptima: Laboratorio → Centro → Restrepo → Soacha → Kennedy → Fontibón → Engativá → Suba → Usaquén → Chapinero → Laboratorio
```

La ruta óptima mide 65,4 km y la del vecino más cercano 75,3: diez kilómetros de más cada día, unos tres mil al año. Dos resultados
merecen leerse con cuidado. Christofides quedó **peor** que el voraz: su garantía (a lo sumo 1,5 veces el óptimo) es para el peor caso,
no una promesa de ganarle a una heurística simple en cada instancia. Y el recocido simulado, que arranca desde la solución voraz, terminó
exactamente donde empezó: con sus parámetros por defecto no encontró por dónde mejorar. La fuerza bruta tardó casi un segundo con nueve
sedes; con doce, a ese ritmo, unos veinte minutos, y con trece, horas.

**Detalles con intención**

- **`math.dist`** da la distancia en línea recta. Es una simplificación deliberada: en Bogotá, la distancia por calles y el tiempo con
  tráfico son otra cosa, y se obtienen de un servicio de rutas (`gi05`). El modelo no cambia; cambian los pesos de las aristas.
- **La fuerza bruta es posible aquí** —nueve sedes, 362 880 órdenes— y por eso sirve de vara para medir a las demás. Con quince sedes
  serían 87 mil millones; ahí la vara es OR-Tools.
- **`greedy_tsp` con `source`** arranca en el laboratorio, como el mensajero. Christofides arranca donde le conviene, pero un ciclo es un
  ciclo: se puede rotar para empezar en el laboratorio sin cambiar su longitud.

---

## ⚠️ 4. Lo que se rompe

**Distancias que no cumplen la desigualdad triangular.** La garantía de Christofides (1,5 veces el óptimo) supone que ir directo nunca es
más largo que pasar por un tercero. Con tiempos de tráfico reales eso no siempre se cumple, y la garantía desaparece.

**Ida y vuelta asimétricas.** Con calles de un solo sentido, ir de A a B no cuesta lo mismo que de B a A. `nx.Graph` es simétrico; hace
falta un `DiGraph` y un algoritmo para el caso asimétrico (OR-Tools lo maneja).

**Ventanas de horario.** "Soacha solo recibe antes de las 10" no se expresa en un TSP de `networkx`. Es un problema de rutas con ventanas de
tiempo, y es el caso para el módulo de rutas de OR-Tools.

**La ruta óptima que nadie sigue.** Si el mensajero tiene razones que el modelo no conoce (dónde se parquea, qué sede abre tarde), la ruta
"óptima" se ignora. Se le pregunta antes de modelar.

---

## ⚖️ 5. Cuándo NO usarlo

**Con cuatro paradas.** Hay 3 órdenes posibles (contando el sentido, 6); se ve a ojo.

**Si la ruta la manda una aplicación de entregas.** Los servicios de rutas comerciales ya optimizan con tráfico real; reimplementarlos no
paga.

**Si lo que cuesta no es la distancia.** Si el mensajero espera media hora en cada sede, optimizar los kilómetros mejora poco; el cuello de
botella está en la espera (`so05`).

---

## 🧪 6. Ejercicios (10)

**🟢 Fácil (1–3)**

1. Corre el ejemplo. **Criterio:** el porcentaje sobre el óptimo de cada método.
2. Agrega Zipaquirá en (5, 40). **Criterio:** cómo cambia la ruta óptima y el tiempo de la fuerza bruta.
3. Usa `nx.shortest_path` en un grafo no completo (solo aristas entre sedes vecinas). **Criterio:** el camino más corto del Centro a Soacha.

**🟡 Intermedio (4–6)**

4. Rota la ruta de Christofides para que empiece en el laboratorio. **Criterio:** la misma longitud y el laboratorio primero.
5. Mide el tiempo de la fuerza bruta con 8, 9, 10 y 11 sedes. **Criterio:** la tabla, y la proyección para 15.
6. Convierte el grafo en dirigido con un recargo del 20 % en un sentido para tres pares. **Criterio:** la ruta óptima asimétrica.

**🟠 Difícil (7–9)**

7. Resuelve la ruta con el módulo de rutas de OR-Tools. **Criterio:** la misma longitud que la fuerza bruta.
8. Agrega a OR-Tools la ventana "Soacha antes de las 10:00" con tiempos a 25 km/h. **Criterio:** la ruta la cumple, y cuánto más larga es.
9. Haz la ruta con dos mensajeros (problema de rutas de vehículos). **Criterio:** el reparto de sedes y la longitud de cada ruta.

**🔴 Muy difícil (10)**

10. Propón la ruta del mensajero de Áurea. **Criterio:** una página. *Rúbrica:* (a) las distancias reales y de dónde salen; (b) las
    restricciones que el mensajero conoce y el modelo no; (c) la ruta propuesta contra la actual, en kilómetros y minutos; (d) cómo se
    recalcula cuando se abre una sede.

---

## 📚 7. Referencias

**Documentación oficial**

- `networkx`, aproximaciones al viajante: https://networkx.org/documentation/stable/reference/algorithms/approximation.html
- OR-Tools, rutas de vehículos: https://developers.google.com/optimization/routing

**Libro**

- William J. Cook, *In Pursuit of the Traveling Salesman* (Princeton University Press, 2012). La historia y las ideas del problema, para
  leer sin fórmulas.

**Orden de lectura sugerido:** la guía de rutas de OR-Tools, que es la que se va a usar con restricciones reales; el libro de Cook, para
entender por qué el problema es como es.

---

## 🚀 8. Cierre

Las rutas son grafos: nodos, aristas con distancias, y algoritmos que buscan el recorrido corto. El vecino más cercano es el instinto, y con
diez sedes se puede medir contra el óptimo exacto para saber cuánto cuesta. Con ventanas de horario, asimetrías o varios vehículos, el
módulo de rutas de OR-Tools.

**La señal de que quedó bien:** *"El mensajero hace la ruta nueva desde hace un mes, y llega a la última sede veinte minutos antes."*

> 🏷️ **Cierra la sección con su tag**, cuando los ejercicios que elegiste estén hechos:
>
> ```bash
> git tag -a op-so-fase-04 -m "op so04 cerrada: la ruta del mensajero, cuatro métodos contra el óptimo exacto"
> ```
>
> Los commits llevan su prefijo (`op so04: …`) y los de ejercicio su número
> (`op so04 ej07: …`).
