"""¿Biblioteca en el proceso o binario por subprocess? El veredicto del track como función, aplicado a siete tareas."""

from dataclasses import dataclass


@dataclass
class Task:
    name: str
    binary_does_it_whole: bool          # ¿el binario hace la tarea completa con sus opciones?
    touches_each_item: bool = False     # ¿hay que mirar o decidir sobre cada cuadro, muestra o celda?
    calls_per_second: float = 0.01      # ¿cuántas veces se ejecuta?
    library_alive: bool = True          # ¿la biblioteca publica versiones?


def decide(t: Task) -> str:
    if t.touches_each_item:
        return "biblioteca en el proceso" + ("" if t.library_alive else " (y buscar reemplazo: está dormida)")
    if t.binary_does_it_whole and t.calls_per_second < 10:
        return "binario por subprocess, con versión fija"
    if t.library_alive:
        return "biblioteca en el proceso: el arranque del binario pesa"
    return "binario por subprocess: la biblioteca está dormida"


TASKS = [
    Task("Convertir un informe de Markdown a Word", binary_does_it_whole=True),
    Task("Renderizar Markdown de cada comentario", binary_does_it_whole=True, calls_per_second=200),
    Task("Sacar un cuadro por segundo de un vídeo", binary_does_it_whole=True),
    Task("Brillo medio de cada cuadro", binary_does_it_whole=False, touches_each_item=True),
    Task("Certificados en PDF, miles por hora", binary_does_it_whole=True, calls_per_second=20),
    Task("Cortar y unir notas de voz", binary_does_it_whole=True, library_alive=False),
    Task("Leer la tabla de un PDF", binary_does_it_whole=False, touches_each_item=True),
]
for t in TASKS:
    print(f"{t.name:<42} → {decide(t)}")
