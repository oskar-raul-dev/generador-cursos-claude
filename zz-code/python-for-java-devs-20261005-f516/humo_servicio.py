"""Prueba de humo con servicios: una red propia, los servicios sin puertos publicados, y el contenedor de Python.

Uso: python3 humo_servicio.py <seccion.md> <dir> <archivo=inicio>... --svc alias=imagen [--env alias:K=V ...]
         [--args alias:"argumentos"] [--pip paq==v ...] --cmd "..."
- Todo lleva la etiqueta curso=python-for-java-devs; al final se borran los servicios y la red, pase lo que pase.
- Las imágenes no se borran aquí: las que se bajen para la carta se anotan en salidas/imagenes-bajadas.txt.
"""
import pathlib
import re
import shlex
import subprocess
import sys

Z = pathlib.Path(__file__).parent
CARTA = pathlib.Path("/Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs")
LABEL = ["--label", "curso=python-for-java-devs"]

args = sys.argv[1:]
md, d = CARTA / args[0], Z / "salidas" / args[1]
d.mkdir(parents=True, exist_ok=True)
specs, pips, svcs, envs, svc_args, cmd, mode = [], [], {}, {}, {}, None, "spec"
it = iter(args[2:])
for a in it:
    if a == "--pip": mode = "pip"; continue
    if a == "--cmd": cmd = next(it); continue
    if a == "--svc": alias, image = next(it).split("=", 1); svcs[alias] = image; continue
    if a == "--env": alias, kv = next(it).split(":", 1); envs.setdefault(alias, []).append(kv); continue
    if a == "--args": alias, rest = next(it).split(":", 1); svc_args[alias] = shlex.split(rest); continue
    (pips if mode == "pip" else specs).append(a)

text = md.read_text(encoding="utf-8")
lines, blocks, i = text.splitlines(), [], 0
while i < len(lines):
    m = re.match(r"^(`{3,})[\w-]*\s*$", lines[i])
    if m:
        fence, j = m.group(1), i + 1
        while j < len(lines) and lines[j].rstrip() != fence:
            j += 1
        before = next((l for l in reversed(lines[:i]) if l.strip()), "")
        blocks.append((before, "\n".join(lines[i + 1:j])))
        i = j + 1
    else:
        i += 1
for spec in specs:
    name, start = spec.split("=", 1)
    found = next((body for before, body in blocks
                  if (start.startswith("@") and before.strip().rstrip(":").strip("`").endswith(start[1:]))
                  or (not start.startswith("@") and body.startswith(start))), None)
    if found is None:
        sys.exit(f"no encontré el bloque para {spec}")
    (d / name).parent.mkdir(parents=True, exist_ok=True)
    (d / name).write_text(found + "\n", encoding="utf-8")

net = f"pfjd-{args[1]}"
started = []
subprocess.run(["docker", "network", "create", *LABEL, net], capture_output=True)
try:
    for alias, image in svcs.items():
        name = f"pfjd-{args[1]}-{alias}"
        env = sum((["-e", kv] for kv in envs.get(alias, [])), [])
        r = subprocess.run(["docker", "run", "-d", "--rm", *LABEL, "--network", net, "--network-alias", alias,
                            "--name", name, *env, image, *svc_args.get(alias, [])], capture_output=True, text=True)
        if r.returncode:
            sys.exit(f"no arrancó {alias}: {r.stderr[-800:]}")
        started.append(name)
    inst = f"pip install -q --root-user-action=ignore {' '.join(pips)} >/dev/null 2>&1; " if pips else ""
    r = subprocess.run(["docker", "run", "--rm", *LABEL, "--network", net, "-v", f"{d}:/w", "-w", "/w",
                        "-e", "PYTHONPATH=/w", "-e", "COLUMNS=200", "python:3.14.7", "sh", "-c", inst + (cmd or "true")],
                       capture_output=True, text=True)
    print(r.stdout[-8000:], r.stderr[-4000:], sep="\n")
finally:
    for name in started:
        subprocess.run(["docker", "rm", "-f", name], capture_output=True)
    subprocess.run(["docker", "network", "rm", net], capture_output=True)
