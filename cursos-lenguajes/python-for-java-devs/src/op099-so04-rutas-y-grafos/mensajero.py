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
