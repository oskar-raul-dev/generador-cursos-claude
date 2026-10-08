#!/usr/bin/env python3
"""Exporta cada diagrama Mermaid de uno o varios Markdown a PNG (o SVG), uno por archivo.

Uso:
    python3 exportar-diagramas.py <archivo.md | carpeta> [--salida diagramas] [--motor mmdc|npx|docker]
                                  [--formato png|svg] [--escala 2] [--tema default|dark|neutral|forest]

Por cada bloque ```mermaid escribe `<salida>/<archivo>-NN.mmd` y lo convierte con mermaid-cli:
    mmdc    el comando instalado con `npm install -g @mermaid-js/mermaid-cli` (por defecto)
    npx     el mismo, sin instalarlo: `npx -p @mermaid-js/mermaid-cli mmdc`
    docker  la imagen oficial `minlag/mermaid-cli`, sin Node en la máquina
Solo biblioteca estándar. No toca los Markdown: solo lee.
"""

import argparse
import os
import pathlib
import re
import shutil
import subprocess
import sys

# el bloque puede ir sangrado dentro de una viñeta: la sangría de la apertura se repite en el cierre
BLOCK = re.compile(r"^([ \t]*)```mermaid[ \t]*\n(.*?)^\1```[ \t]*$", re.S | re.M)
DOCKER_IMAGE = "minlag/mermaid-cli"


def find_markdown(path):
    p = pathlib.Path(path)
    if p.is_file():
        return [p]
    return sorted(f for f in p.rglob("*.md") if "node_modules" not in f.parts)


def converter(engine, out_dir):
    if engine == "mmdc":
        if not shutil.which("mmdc"):
            sys.exit("No encuentro mmdc: npm install -g @mermaid-js/mermaid-cli, o usa --motor npx|docker.")
        return lambda src, dst, extra: ["mmdc", "-i", str(src), "-o", str(dst), *extra]
    if engine == "npx":
        return lambda src, dst, extra: ["npx", "-y", "-p", "@mermaid-js/mermaid-cli", "mmdc",
                                        "-i", str(src), "-o", str(dst), *extra]
    # docker: the output folder is mounted at /data, the image's working directory
    user = [] if os.name == "nt" else ["-u", f"{os.getuid()}:{os.getgid()}"]
    mount = f"{out_dir.resolve()}:/data"
    return lambda src, dst, extra: ["docker", "run", "--rm", *user, "-v", mount, DOCKER_IMAGE,
                                    "-i", src.name, "-o", dst.name, *extra]


def main():
    ap = argparse.ArgumentParser(description="Exporta los diagramas Mermaid de Markdown a imágenes.")
    ap.add_argument("ruta", help="un archivo .md o una carpeta (se recorre entera)")
    ap.add_argument("--salida", default="diagramas", help="carpeta de salida (se crea)")
    ap.add_argument("--motor", choices=["mmdc", "npx", "docker"], default="mmdc")
    ap.add_argument("--formato", choices=["png", "svg"], default="png")
    ap.add_argument("--escala", default="2", help="factor de escala del PNG (más nítido con 2 o 3)")
    ap.add_argument("--tema", default="default")
    a = ap.parse_args()

    out_dir = pathlib.Path(a.salida)
    out_dir.mkdir(parents=True, exist_ok=True)
    run = converter(a.motor, out_dir)
    extra = ["-t", a.tema, "-b", "white"] + (["-s", a.escala] if a.formato == "png" else [])

    total = fails = 0
    for md in find_markdown(a.ruta):
        blocks = BLOCK.findall(md.read_text(encoding="utf-8"))
        for n, (indent, body) in enumerate(blocks, 1):
            if indent:  # se quita la sangría de la viñeta, línea por línea
                body = "".join(l[len(indent):] if l.startswith(indent) else l.lstrip(" \t")
                               for l in body.splitlines(keepends=True))
            src = out_dir / f"{md.stem}-{n:02d}.mmd"
            dst = src.with_suffix(f".{a.formato}")
            src.write_text(body, encoding="utf-8")
            total += 1
            r = subprocess.run(run(src, dst, extra), capture_output=True, text=True)
            if r.returncode == 0:
                print(f"ok    {md}  #{n}  → {dst}")
            else:
                fails += 1
                print(f"FALLA {md}  #{n}  → {src}\n      {(r.stderr or r.stdout).strip()[:300]}")
    print(f"— {total} diagramas, {fails} con error")
    sys.exit(1 if fails else 0)


if __name__ == "__main__":
    main()
