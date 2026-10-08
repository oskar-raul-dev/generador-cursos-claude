"""Genera los seis cuadernos del análisis del Embudo, con sus defectos sembrados.

    python generar_cuadernos.py --salida cuadernos

Son seis `.ipynb` escritos como los escribiría cualquiera analizando el Embudo de `ds04`: a
mano, en una tarde, ejecutando celdas en el orden en que se le ocurrieron. **Cinco de los
seis tienen un defecto de reproducibilidad y uno está limpio**, y los defectos son los que
aparecen de verdad, no los que se inventarían para un ejercicio.

Cada cuaderno se guarda **con sus salidas**, como salen de la máquina de quien lo escribió:
ahí está la trampa entera. Un cuaderno con salidas se lee como si funcionara.

⚠️ Los `execution_count` no son decorativos. En `estado-oculto.ipynb` van 1, 3, 2: es la
huella de que las celdas se ejecutaron fuera de orden, y es lo único que delata el problema
antes de correrlo.
"""

from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path

KERNEL = {
    "kernelspec": {"display_name": "Python 3", "language": "python", "name": "python3"},
    "language_info": {"name": "python", "version": "3.14.5"},
}


def cell(source: str, count: int | None = None, output: str | None = None) -> dict:
    """Una celda de código, opcionalmente con su salida guardada.

    El `id` se deriva del contenido y del `execution_count`, no se sortea: `nbformat` lo
    exige desde la versión 4.5 y un identificador aleatorio haría que el archivo cambiara
    en cada generación, que es justo lo contrario de lo que enseña esta sección.
    """
    outputs = []
    if output is not None:
        outputs = [{"output_type": "stream", "name": "stdout", "text": [output]}]
    digest = hashlib.sha1(f"{count}:{source}".encode()).hexdigest()[:8]
    return {"cell_type": "code", "id": digest, "execution_count": count, "metadata": {},
            "source": source.strip().splitlines(keepends=True), "outputs": outputs}


def notebook(cells: list[dict]) -> dict:
    return {"cells": cells, "metadata": KERNEL, "nbformat": 4, "nbformat_minor": 5}


# --- Los seis cuadernos --------------------------------------------------------------

def clean() -> dict:
    """El que sí reejecuta. Existe para que la medición tenga un control."""
    return notebook([
        cell("canales = ['tiktok', 'instagram', 'google']\n"
             "gasto = {'tiktok': 2020, 'instagram': 2020, 'google': 2020}", 1),
        cell("adquiridos = {'tiktok': 182, 'instagram': 529, 'google': 1275}", 2),
        cell("for canal in canales:\n"
             "    print(canal, round(gasto[canal] * 1e6 / adquiridos[canal]))", 3,
             "tiktok 11098901\ninstagram 3818525\ngoogle 1584314\n"),
    ])


def hidden_state() -> dict:
    """El clásico: la celda 2 usa algo que define la celda 3.

    Funcionó porque quien lo escribió ejecutó la 3 antes que la 2 mientras exploraba, y los
    `execution_count` lo delatan: 1, 3, 2. De arriba abajo revienta con `NameError`.
    """
    return notebook([
        cell("gasto = {'tiktok': 2020, 'instagram': 2020, 'google': 2020}", 1),
        cell("costos = {c: gasto[c] * 1e6 / adquiridos[c] for c in gasto}\n"
             "print(sorted(costos, key=costos.get))", 3,
             "['google', 'instagram', 'tiktok']\n"),
        cell("adquiridos = {'tiktok': 182, 'instagram': 529, 'google': 1275}", 2),
    ])


def deleted_cell() -> dict:
    """Peor que el anterior: la celda que definía `leads` **ya no está**.

    Alguien la borró después de ejecutarla porque "ya no hacía falta". El cuaderno conserva
    la salida, así que parece correcto, y no hay ningún `execution_count` raro que avise.
    """
    return notebook([
        cell("total = sum(leads.values())\n"
             "print(f'{total:,} leads')", 2, "32,550 leads\n"),
        cell("print('conversión:', round(6065 / total * 100, 1), '%')", 3,
             "conversión: 18.6 %\n"),
    ])


def absolute_path() -> dict:
    """La ruta de la máquina de quien lo escribió. El defecto más común de todos."""
    return notebook([
        cell("import csv\n"
             "ruta = '/Users/marcela/Escritorio/aurea/data/leads.csv'\n"
             "with open(ruta, encoding='utf-8') as f:\n"
             "    leads = list(csv.DictReader(f))\n"
             "print(len(leads))", 1, "32550\n"),
    ])


def undeclared_dependency() -> dict:
    """Importa algo que está en la máquina del autor y en ninguna otra."""
    return notebook([
        cell("import unaBibliotecaQueNadieDeclaro as helper\n"
             "print(helper.version)", 1, "0.4.2\n"),
    ])


def unseeded_randomness() -> dict:
    """Este **sí corre**, y da otro número cada vez. Es el defecto más difícil de ver.

    No falla, no avisa, y el informe del mes pasado no se puede reproducir. La medición de
    la sección 6 lo cuenta aparte por eso: "corre" y "es reproducible" no son lo mismo.
    """
    return notebook([
        cell("import random\n"
             "muestra = random.sample(range(32550), 500)\n"
             "print('conversión estimada:', round(sum(1 for i in muestra if i % 5 == 0)"
             " / 5, 1), '%')", 1, "conversión estimada: 20.0 %\n"),
    ])


NOTEBOOKS = {
    "limpio.ipynb": clean,
    "estado-oculto.ipynb": hidden_state,
    "celda-borrada.ipynb": deleted_cell,
    "ruta-absoluta.ipynb": absolute_path,
    "dependencia-no-declarada.ipynb": undeclared_dependency,
    "azar-sin-semilla.ipynb": unseeded_randomness,
}


def main() -> None:
    parser = argparse.ArgumentParser(description="Los seis cuadernos del Embudo.")
    parser.add_argument("--salida", type=Path, default=Path("cuadernos"))
    args = parser.parse_args()

    args.salida.mkdir(parents=True, exist_ok=True)
    for name, build in NOTEBOOKS.items():
        (args.salida / name).write_text(
            json.dumps(build(), indent=1, ensure_ascii=False) + "\n", encoding="utf-8")
        print(f"{args.salida / name}")

    print(f"\n{len(NOTEBOOKS)} cuadernos · uno limpio, cinco con su defecto sembrado.")
    print("Todos traen sus salidas guardadas: por eso los seis parecen correctos.")


if __name__ == "__main__":
    main()
