"""Visualizar algoritmos con matplotlib: grabar los estados de dos ordenamientos y animarlos; cuánto dura cada historia."""

import os
import random
import time

import matplotlib

matplotlib.use("Agg")                                 # sin ventana: la animación se escribe a un archivo
import matplotlib.pyplot as plt
from matplotlib.animation import FuncAnimation, PillowWriter


def bubble(values):
    """Devuelve los estados: uno por comparación, marcando los dos índices comparados."""
    a, states = list(values), []
    for end in range(len(a) - 1, 0, -1):
        for i in range(end):
            states.append((list(a), (i, i + 1), "compara"))
            if a[i] > a[i + 1]:
                a[i], a[i + 1] = a[i + 1], a[i]
                states.append((list(a), (i, i + 1), "intercambia"))
    return states


def merge_sort(values):
    """Merge sort de abajo arriba, guardando un estado por cada escritura en la lista."""
    a, states, width = list(values), [], 1
    while width < len(a):
        for lo in range(0, len(a), 2 * width):
            mid, hi = min(lo + width, len(a)), min(lo + 2 * width, len(a))
            merged, i, j = [], lo, mid
            while i < mid or j < hi:
                states.append((list(a), (i, j), "compara"))
                if j >= hi or (i < mid and a[i] <= a[j]):
                    merged.append(a[i]); i += 1
                else:
                    merged.append(a[j]); j += 1
            for k, v in enumerate(merged):
                a[lo + k] = v
                states.append((list(a), (lo + k, lo + k), "escribe"))
        width *= 2
    return states


def animate(states, filename, fps=30):
    fig, ax = plt.subplots(figsize=(4, 2.5), dpi=80)
    bars = ax.bar(range(len(states[0][0])), states[0][0], color="#9aa5b1")
    ax.set_xticks([]); ax.set_yticks([])

    def draw(frame):
        values, marked, _ = states[frame]
        for k, (bar, v) in enumerate(zip(bars, values)):
            bar.set_height(v)
            bar.set_color("#d64545" if k in marked else "#9aa5b1")
        return bars

    start = time.perf_counter()
    FuncAnimation(fig, draw, frames=len(states), blit=True).save(filename, writer=PillowWriter(fps=fps))
    plt.close(fig)
    return time.perf_counter() - start


random.seed(11)
data = random.sample(range(1, 31), 30)
print(f"{'algoritmo':<11} {'cuadros':>8} {'compara':>8} {'mueve':>6} {'duración a 30 c/s':>18} {'GIF':>8} {'render':>7}")
for name, states in (("burbuja", bubble(data)), ("merge sort", merge_sort(data))):
    assert states[-1][0] == sorted(data)
    filename = name.replace(" ", "_") + ".gif"
    seconds = animate(states, filename)
    compares = sum(1 for s in states if s[2] == "compara")
    print(f"{name:<11} {len(states):>8} {compares:>8} {len(states) - compares:>6} {len(states) / 30:>16.1f} s "
          f"{os.path.getsize(filename) / 1024:>5.0f} KB {seconds:>6.1f} s")
