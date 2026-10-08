"""¿Dónde mover la frontera? El veredicto del track como función, aplicada a cinco funciones calientes."""

from dataclasses import dataclass


@dataclass
class HotFunction:
    name: str
    share_of_time: float               # fracción del tiempo total del programa que se va en ella
    vectorizable: bool = False         # ¿NumPy la expresa como operación de arreglo completo?
    numeric_loop: bool = True          # ¿números y arreglos, sin objetos de Python?
    long_running: bool = True          # ¿el proceso vive lo suficiente para pagar 340 ms de arranque?
    wraps_existing_c: bool = False
    team_writes: str = "Python"        # "Python", "Rust", "C++"


def decide(f: HotFunction) -> str:
    if f.share_of_time < 0.2:
        return "nada: no es el cuello de botella"
    if f.wraps_existing_c:
        return "cffi (ff02)"
    if f.vectorizable:
        return "NumPy, sin compilar nada (ds01)"
    if f.numeric_loop and f.long_running:
        return "numba (ff04)"
    if f.team_writes == "Rust":
        return "PyO3 + maturin (ff05), con cibuildwheel"
    if f.team_writes == "C++":
        return "nanobind (ff05), con cibuildwheel"
    return "Cython (ff03), con cibuildwheel"


FUNCTIONS = [
    HotFunction("Suavizado de la serie de recaudo", 0.7),
    HotFunction("Mora diaria de todos los saldos", 0.5, vectorizable=True),
    HotFunction("Validación de formularios", 0.05, numeric_loop=False),
    HotFunction("Lector de huellas del fabricante", 0.4, wraps_existing_c=True),
    HotFunction("Suavizado en un CLI de 0,3 s", 0.8, long_running=False),
    HotFunction("Normalizar nombres en lotes de texto", 0.6, numeric_loop=False, team_writes="Rust"),
]
for f in FUNCTIONS:
    print(f"{f.name:<38} → {decide(f)}")
