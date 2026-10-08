"""Compara el chart renderizado con el YAML plano de la Fase 12, objeto por objeto (Fase 13).

Uso (desde src/lab/, a través del Taskfile):
    task chart:compare

Lee lo que `helm template` imprime por stdin y los manifiestos de deploy/manifests y deploy/jobs, y
lista, para cada objeto, los campos que solo están en uno de los dos o que cambian de valor. No
compara comentarios ni el orden: compara lo que le llega a la API.
"""
import sys
from pathlib import Path

import yaml

LAB = Path(__file__).resolve().parents[2]
# Lo que no es del sistema: el namespace lo crea task deploy, y los Job de experimentos no se despliegan.
SKIP = {"namespace.yaml", "catalog-migrate-dos-a-la-vez.yaml"}


def load(stream: str) -> dict:
    objs = {}
    for doc in yaml.safe_load_all(stream):
        if doc:
            objs[(doc["kind"], doc["metadata"]["name"])] = doc
    return objs


def plain() -> dict:
    files = sorted((LAB / "deploy" / "manifests").rglob("*.yaml")) + sorted((LAB / "deploy" / "jobs").glob("*.yaml"))
    return load("\n---\n".join(f.read_text(encoding="utf-8") for f in files if f.name not in SKIP))


def flatten(node, prefix=""):
    """Un objeto anidado como pares ruta → valor; las listas por posición."""
    if isinstance(node, dict):
        for k, v in node.items():
            yield from flatten(v, f"{prefix}.{k}" if prefix else str(k))
    elif isinstance(node, list) and node and all(isinstance(i, (dict, list)) for i in node):
        for i, v in enumerate(node):
            yield from flatten(v, f"{prefix}[{i}]")
    else:
        yield prefix, node


def main() -> int:
    chart, before = load(sys.stdin.read()), plain()
    differences = 0
    # El resumen agrupa por campo: 24 veces el mismo namespace es una sola explicación.
    classes: dict[str, int] = {}
    for key in sorted(before.keys() | chart.keys()):
        if key not in chart:
            print(f"{key[0]}/{key[1]}: solo en el YAML plano")
            classes[f"- {key[0]}/{key[1]} (el objeto entero)"] = 1
            differences += 1
            continue
        if key not in before:
            print(f"{key[0]}/{key[1]}: solo en el chart")
            classes[f"+ {key[0]}/{key[1]} (el objeto entero)"] = 1
            differences += 1
            continue
        a, b = dict(flatten(before[key])), dict(flatten(chart[key]))
        lines = [f"  - {p} = {a[p]!r}" for p in sorted(a.keys() - b.keys())]
        lines += [f"  + {p} = {b[p]!r}" for p in sorted(b.keys() - a.keys())]
        lines += [f"  ~ {p}: {a[p]!r} → {b[p]!r}" for p in sorted(a.keys() & b.keys()) if a[p] != b[p]]
        for line in lines:
            field = line[4:].split(" = ")[0].split(":")[0]
            classes[f"{line[2]} {field}"] = classes.get(f"{line[2]} {field}", 0) + 1
        if lines:
            print(f"{key[0]}/{key[1]}:")
            print("\n".join(lines))
            differences += len(lines)
    print(f"\n{len(chart)} objetos en el chart, {len(before)} en el YAML plano; {differences} diferencias, por campo:")
    for field, n in sorted(classes.items(), key=lambda kv: (-kv[1], kv[0])):
        print(f"  {n:3}  {field}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
