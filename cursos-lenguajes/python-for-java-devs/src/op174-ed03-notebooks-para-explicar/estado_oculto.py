"""El estado oculto de un notebook: se fabrica, se detecta, se reejecuta de arriba abajo, y se compara con marimo."""

import re
import subprocess

import jupytext
import nbformat
from nbclient import NotebookClient
from nbclient.exceptions import CellExecutionError

# 1. Un notebook "explicativo" tal como quedó guardado: el autor corrió la celda 3 y después volvió a correr la 2
nb = nbformat.v4.new_notebook()
cells = [
    ("price = 100_000\nrate = 0.19", 1, None),
    ("total = price * (1 + rate)\ntotal", 4, "116000.0"),
    ("rate = 0.16   # la tarifa nueva, que el autor probó y después borró del texto", 3, None),
    ("print(f'El total con IVA es {total:,.0f}')", 5, "El total con IVA es 116,000\n"),
    ("discount", 2, "5000"),                          # su definición estaba en una celda que ya no existe
]
for source, count, output in cells:
    cell = nbformat.v4.new_code_cell(source, execution_count=count)
    if output and output.endswith("\n"):
        cell.outputs = [nbformat.v4.new_output("stream", name="stdout", text=output)]
    elif output:
        cell.outputs = [nbformat.v4.new_output("execute_result", data={"text/plain": output}, execution_count=count)]
    nb.cells.append(cell)
nbformat.write(nb, "explicacion.ipynb")

# 2. Detectarlo sin correr nada: el orden de ejecución guardado no es el orden de lectura
counts = [c.execution_count for c in nb.cells]
print("orden de ejecución guardado:", counts, "→", "en orden" if counts == sorted(counts) else "FUERA DE ORDEN")

# 3. Reiniciar y correr todo de arriba abajo, como lo haría el lector
fresh = nbformat.read("explicacion.ipynb", as_version=4)
try:
    NotebookClient(fresh, timeout=60, kernel_name="python3").execute()
except CellExecutionError as error:
    last_line = str(error).strip().splitlines()[-1]
    print("de arriba abajo:", re.sub(r"\x1b\[[0-9;]*m", "", last_line))   # sin los colores ANSI de IPython
for i in (1, 3):
    stored = "".join(o.get("text", "") or o.get("data", {}).get("text/plain", "") for o in nb.cells[i].outputs).strip()
    rerun = "".join(o.get("text", "") or o.get("data", {}).get("text/plain", "") for o in fresh.cells[i].outputs).strip()
    print(f"celda {i + 1}: guardada {stored!r} · reejecutada {rerun!r}")

# 4. El mismo notebook como texto: jupytext lo convierte en un .py que se lee en un diff
jupytext.write(nb, "explicacion.py", fmt="py:percent")
text = open("explicacion.py", encoding="utf-8").read()
print(f"\njupytext: {len(text.splitlines())} líneas de texto · celdas marcadas con '# %%': {text.count('# %%')}")

# 5. La misma lógica en marimo: un nombre solo puede definirse en una celda
with open("explicacion_marimo.py", "w", encoding="utf-8") as f:
    f.write('''import marimo

app = marimo.App()


@app.cell
def _():
    price = 100_000
    rate = 0.19
    return price, rate


@app.cell
def _(price, rate):
    total = price * (1 + rate)
    return (total,)


@app.cell
def _():
    rate = 0.16
    return (rate,)


if __name__ == "__main__":
    app.run()
''')
result = subprocess.run(["python", "explicacion_marimo.py"], capture_output=True, text=True)
last = (result.stderr or result.stdout).strip().splitlines()
print("marimo:", next((line for line in last if "rate" in line), last[-1] if last else "(sin salida)"))
