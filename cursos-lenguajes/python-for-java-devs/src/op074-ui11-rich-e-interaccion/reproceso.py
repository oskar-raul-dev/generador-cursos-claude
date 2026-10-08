"""Tabla, pregunta y progreso con rich, moderados solos cuando la salida no es una terminal."""

import sys
import time

from rich.console import Console
from rich.progress import track
from rich.prompt import Prompt
from rich.table import Table

console = Console()
CIERRE = {"Centro": ("ok", 118), "Chapinero": ("ok", 131), "Suba": ("falló", 0), "Kennedy": ("ok", 322)}

table = Table(title="Cierre del 2026-10-04")
table.add_column("Sede")
table.add_column("Estado")
table.add_column("Segundos", justify="right")
for sede, (status, secs) in CIERRE.items():
    style = "bold red" if status == "falló" else "green"
    table.add_row(sede, f"[{style}]{status}[/]", str(secs))
console.print(table)

sede = Prompt.ask("¿Qué sede reproceso?", choices=list(CIERRE), console=console)
for _ in track(range(5), description=f"Reprocesando {sede}…", console=console, transient=True):
    time.sleep(0.1)
console.print(f"[green]✔[/] {sede} reprocesada")
print(f"terminal: {console.is_terminal} · colores: {console.color_system}", file=sys.stderr)
