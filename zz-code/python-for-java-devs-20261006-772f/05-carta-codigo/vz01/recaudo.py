"""Diez imágenes de recaudo con pyplot (estado global) y con Figure (sin estado): memoria y figuras vivas."""

import random
import tracemalloc
import warnings

import matplotlib

matplotlib.use("Agg")                                     # sin pantalla: el servidor no tiene una
import matplotlib.pyplot as plt  # noqa: E402
from matplotlib.figure import Figure  # noqa: E402
from matplotlib.ticker import FuncFormatter  # noqa: E402

SEDES = ["Centro", "Chapinero", "Suba", "Kennedy", "Usaquén", "Engativá", "Fontibón", "Restrepo", "Soacha", "Zipaquirá"]
pesos = FuncFormatter(lambda v, _: "$" + f"{v / 1e6:.0f}" + " M")


def data(sede: str) -> list[int]:
    random.seed(sede)
    return [random.randint(2_000_000, 9_000_000) for _ in range(30)]


def with_pyplot(sede: str, path: str):
    plt.figure(figsize=(8, 3))
    plt.bar(range(1, 31), data(sede), color="#2E6F9E")
    plt.title(f"Recaudo diario de {sede}, septiembre de 2026")
    plt.gca().yaxis.set_major_formatter(pesos)
    plt.savefig(path, dpi=100)                            # y nadie llama a plt.close()


def with_figure(sede: str, path: str):
    fig = Figure(figsize=(8, 3))
    ax = fig.subplots()
    ax.bar(range(1, 31), data(sede), color="#2E6F9E")
    ax.set_title(f"Recaudo diario de {sede}, septiembre de 2026")
    ax.yaxis.set_major_formatter(pesos)
    fig.savefig(path, dpi=100)


for label, draw in [("pyplot sin cerrar", with_pyplot), ("Figure", with_figure)]:
    tracemalloc.start()
    with warnings.catch_warnings(record=True) as caught:
        warnings.simplefilter("always")
        for night in range(3):                            # tres noches del proceso
            for sede in SEDES:
                draw(sede, f"recaudo-{sede}.png")
    current, _ = tracemalloc.get_traced_memory()
    tracemalloc.stop()
    print(f"{label:<18} figuras vivas en pyplot: {len(plt.get_fignums()):>2} · memoria retenida: {current / 1e6:5.1f} MB ·"
          f" avisos: {len(caught)}")
    if caught:
        print("  ", str(caught[0].message)[:100], "…")
    plt.close("all")
