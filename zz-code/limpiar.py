#!/usr/bin/env python3
"""Libera disco en zz-code/ borrando SOLO lo regenerable: dependencias, salidas de build y salidas/ de las pruebas.

Uso:
    python3 zz-code/limpiar.py                      # vista previa de todo zz-code/: lista y tamaños
    python3 zz-code/limpiar.py <id> [<id> …]        # vista previa de esos directorios
    python3 zz-code/limpiar.py <id> --borrar        # borra lo listado, y nada más

Reglas, que el script hace cumplir:
  - solo actúa dentro de zz-code/, y solo sobre los <id> que existen ahí;
  - solo borra directorios cuyo nombre está en REGENERABLE (node_modules, target, .venv…);
  - no sigue enlaces simbólicos ni entra en lo que va a borrar;
  - sin --borrar no toca nada.
El código fuente, el MANIFIESTO.md y los datos se quedan. Solo biblioteca estándar.
"""

import argparse
import os
import shutil
import sys

RAIZ = os.path.dirname(os.path.abspath(__file__))

REGENERABLE = {
    "salidas",                      # logs y copias de las pruebas: se rehacen corriéndolas
    "node_modules", ".pnpm-store", ".next", ".nuxt", ".angular", ".parcel-cache",
    "target", ".gradle", "build", "dist", "out",
    ".venv", "venv", "__pycache__", ".pytest_cache", ".mypy_cache", ".ruff_cache", ".tox",
    "bin", "obj",                   # .NET
    "vendor",                       # PHP (composer install) y Go (go mod vendor)
    "coverage", ".nyc_output",
}


def tamano(ruta):
    total = 0
    for base, _, archivos in os.walk(ruta):
        for a in archivos:
            try:
                total += os.lstat(os.path.join(base, a)).st_size
            except OSError:
                pass
    return total


def legible(n):
    for unidad in ("B", "KB", "MB", "GB"):
        if n < 1024:
            return f"{n:.0f} {unidad}"
        n /= 1024
    return f"{n:.1f} TB"


def candidatos(directorio):
    for base, dirs, _ in os.walk(directorio):
        borrables = [d for d in dirs if d in REGENERABLE and not os.path.islink(os.path.join(base, d))]
        for d in borrables:
            yield os.path.join(base, d)
        # no se entra en lo que se va a borrar ni en enlaces simbólicos
        dirs[:] = [d for d in dirs if d not in REGENERABLE and not os.path.islink(os.path.join(base, d))]


def main():
    p = argparse.ArgumentParser(description="Borra solo lo regenerable dentro de zz-code/.")
    p.add_argument("ids", nargs="*", help="directorios de zz-code/ (por defecto, todos)")
    p.add_argument("--borrar", action="store_true", help="borra de verdad; sin esto, solo lista")
    p.add_argument("--raiz", default=RAIZ, help="otra raíz (solo para pruebas)")
    a = p.parse_args()

    raiz = os.path.realpath(a.raiz)
    ids = a.ids or sorted(d for d in os.listdir(raiz)
                          if os.path.isdir(os.path.join(raiz, d)) and not d.startswith("."))
    objetivos = []
    for ident in ids:
        ruta = os.path.realpath(os.path.join(raiz, ident))
        if os.path.dirname(ruta) != raiz or not os.path.isdir(ruta):
            sys.exit(f"No es un directorio de zz-code/: {ident}")
        objetivos.extend(candidatos(ruta))

    total = 0
    for ruta in objetivos:
        if os.path.commonpath([raiz, os.path.realpath(ruta)]) != raiz:
            sys.exit(f"Fuera de zz-code/, no se toca: {ruta}")
        t = tamano(ruta)
        total += t
        print(f"{legible(t):>10}  {os.path.relpath(ruta, raiz)}")
    print(f"{legible(total):>10}  en {len(objetivos)} directorios regenerables")

    if not a.borrar:
        print("Vista previa: no se borró nada. Para borrar, repite con --borrar.")
        return
    for ruta in objetivos:
        shutil.rmtree(ruta)
    print(f"Borrados {len(objetivos)} directorios regenerables.")


if __name__ == "__main__":
    main()
