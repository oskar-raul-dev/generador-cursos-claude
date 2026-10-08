#!/usr/bin/env python3
"""Rehace desde cero los rescates de zz-code listados en rescates.tsv, a partir de las transcripciones.

Uso, desde cualquier sitio:
    python3 zz-code/regenerar-rescates.py                 # todos los directorios de rescates.tsv
    python3 zz-code/regenerar-rescates.py --dir <id>      # uno (repetible)
    python3 zz-code/regenerar-rescates.py --comprobar     # regenera aparte y compara; no toca nada
    python3 zz-code/regenerar-rescates.py --listar        # muestra qué se generaría, sin hacer nada

Cada fila de rescates.tsv es una carpeta generada dentro de un directorio de zz-code: o el rescate de
una sesión (lo hace zz-instrucciones/herramientas/rescatar-transcripcion.py con las opciones de la fila)
o un paso posterior (un comando con {dir} = el directorio y {dest} = la raíz de salida).

Lo generado se borra antes de rehacerlo, y solo eso: las carpetas y archivos que nombra la columna
«carpeta», siempre dentro de su directorio. Lo escrito a mano (README, MANIFIESTO, sondas, auxiliares)
no se toca. --comprobar escribe en <directorio>/salidas/regenerado/ (que git ignora), compara con lo que
hay y lo borra al terminar: sirve para saber que el rescate se puede rehacer idéntico antes de borrar.

Solo lee las transcripciones y nunca ejecuta lo que extrae; no llama a Docker. Biblioteca estándar.
"""

import argparse
import filecmp
import os
import shlex
import shutil
import subprocess
import sys

ZZ = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.dirname(ZZ)
TABLA = os.path.join(ZZ, "rescates.tsv")
HERRAMIENTA = os.path.join(REPO, "zz-instrucciones", "herramientas", "rescatar-transcripcion.py")


def filas():
    with open(TABLA, encoding="utf-8") as fh:
        lineas = [l.rstrip("\n") for l in fh if l.strip() and not l.startswith("#")]
    cab = lineas[0].split("\t")
    return [dict(zip(cab, l.split("\t"))) for l in lineas[1:]]


def dentro(base, rel):
    """La ruta de una carpeta generada, comprobando que no se sale de su directorio."""
    p = os.path.normpath(os.path.join(base, rel))
    if not p.startswith(base + os.sep) or rel in ("", ".", "salidas"):
        sys.exit(f"ruta generada fuera de su directorio o protegida: {rel}")
    return p


def borrar(p):
    if os.path.isdir(p):
        shutil.rmtree(p)
    elif os.path.exists(p):
        os.remove(p)


def generar(fila, dest):
    d = os.path.join(ZZ, fila["directorio"])
    if fila["sesion"] == "-":
        cmd = fila["opciones"].replace("{dir}", shlex.quote(d)).replace("{dest}", shlex.quote(dest))
        r = subprocess.run(cmd, shell=True, cwd=d, capture_output=True, text=True)
        print(f"  {fila['carpeta']}: {(r.stdout.strip().splitlines() or [''])[-1]}")
    else:
        args = [sys.executable, HERRAMIENTA, dest, fila["sesion"], "--nombre", fila["carpeta"]]
        args += shlex.split(fila["opciones"])
        r = subprocess.run(args, capture_output=True, text=True)
        print(f"  {fila['carpeta']}: {r.stdout.strip()}")
    if r.returncode:
        sys.exit(f"falló {fila['carpeta']}: {r.stderr.strip()[-800:]}")


def diferencias(a, b, rel=""):
    """Rutas que difieren entre dos árboles, recorriendo subcarpetas."""
    c = filecmp.dircmp(a, b)
    out = [os.path.join(rel, x) for x in c.left_only + c.right_only + c.funny_files]
    _, mismatch, errors = filecmp.cmpfiles(a, b, c.common_files, shallow=False)
    out += [os.path.join(rel, x) for x in mismatch + errors]
    for sub in c.common_dirs:
        out += diferencias(os.path.join(a, sub), os.path.join(b, sub), os.path.join(rel, sub))
    return out


def main():
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("--dir", action="append", help="limita a este directorio de zz-code (repetible)")
    ap.add_argument("--comprobar", action="store_true", help="regenera aparte y compara; no toca nada")
    ap.add_argument("--listar", action="store_true", help="solo muestra qué se generaría")
    a = ap.parse_args()

    todas = filas()
    if a.dir:
        desconocidos = set(a.dir) - {f["directorio"] for f in todas}
        if desconocidos:
            sys.exit(f"no están en rescates.tsv: {', '.join(sorted(desconocidos))}")
        todas = [f for f in todas if f["directorio"] in a.dir]

    por_dir = {}
    for f in todas:
        por_dir.setdefault(f["directorio"], []).append(f)

    total_dif = 0
    for directorio, fs in por_dir.items():
        d = os.path.join(ZZ, directorio)
        print(f"### {directorio}")
        if a.listar:
            for f in fs:
                print(f"  {f['carpeta']}  ←  {f['sesion'] if f['sesion'] != '-' else f['opciones']}")
            continue
        if a.comprobar:
            dest = os.path.join(d, "salidas", "regenerado")
            borrar(dest)
            os.makedirs(dest)
            for f in fs:
                generar(f, dest)
            for f in fs:
                nuevo, actual = os.path.join(dest, f["carpeta"]), dentro(d, f["carpeta"])
                if os.path.isdir(nuevo) and os.path.isdir(actual):
                    dif = diferencias(actual, nuevo)
                elif os.path.isfile(nuevo) and os.path.isfile(actual):
                    dif = [] if filecmp.cmp(actual, nuevo, shallow=False) else [f["carpeta"]]
                else:
                    dif = [f["carpeta"] + " (falta en uno de los dos)"]
                total_dif += len(dif)
                print(f"  {'igual' if not dif else f'{len(dif)} diferencias'}: {f['carpeta']}")
                for x in dif[:5]:
                    print(f"      {x}")
            borrar(dest)
        else:
            for f in fs:
                borrar(dentro(d, f["carpeta"]))
            for f in fs:
                generar(f, d)
    if a.comprobar:
        print(f"— {total_dif} diferencias en total")
        sys.exit(1 if total_dif else 0)


if __name__ == "__main__":
    main()
