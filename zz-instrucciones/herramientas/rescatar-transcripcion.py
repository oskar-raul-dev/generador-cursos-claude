#!/usr/bin/env python3
"""Rescata de la transcripción de una sesión de Claude Code el código que la sesión escribió y corrió.

Sirve para los cursos producidos antes de la regla 7 de zz-code/README.md, cuando las pruebas vivían
en el scratchpad o en /tmp y el sistema ya las borró: la transcripción (.jsonl) guarda completo cada
archivo escrito con Write o con `cat > archivo <<EOF`, cada comando y su salida.

Uso:
    python3 rescatar-transcripcion.py <destino> <sesión> [--nombre DIR] [--cwd RUTA]
                                      [--sin-ediciones] [--solo-perdidos] [--todo]
                                      [--incluir REGEX] [--excluir REGEX] [--transcripciones DIR]
    python3 rescatar-transcripcion.py --inventario <sesión>... [--bash] [--transcripciones DIR]

<sesión> es el id completo (el nombre del .jsonl sin extensión). Por omisión las transcripciones se
buscan en ~/.claude/projects/<ruta del repositorio con / cambiado por ->/, y la sesión arranca en la
raíz del repositorio (--cwd la cambia). Se incluyen los subagentes de la sesión.

Escribe en <destino>/<DIR o los 8 primeros caracteres de la sesión>/:

- archivos/ y archivos.tsv: cada archivo creado con Write o con `cat > ruta <<EOF`, con sus Edit
  posteriores aplicados, si la ruta pasa --incluir y no --excluir. Salvo con --todo, omite lo que sigue
  en disco igual (existe-igual), lo que vive en un curso publicado o en ~/.claude y sigue existiendo,
  y todo Markdown dentro del repositorio: lo que importa es el código de prueba que se perdería.
  --solo-perdidos deja solo lo que ya no existe en disco. La ruta guardada es la original relativa al
  repositorio (o la absoluta sin la / inicial), con un _ delante de cada carpeta que los .gitignore
  excluyen (_tmp/, _salidas/…), para que git la versione; archivos.tsv guarda la ruta original y el
  estado (no-existe o existe-distinto). Un curso que se movió de la raíz a su familia
  (<repo>/<curso>/ → <repo>/cursos-<familia>/<curso>/) se busca en su lugar nuevo, y el estado lo dice
  («movido a …»).
- scripts/NNN-HHMM-{verifica|edita}.{py,sh,js}: cada script en línea (`python3 - <<'PY'`, `bash <<EOF`)
  y cada comando Bash de varias líneas que no lo es, con un comentario de sesión, hora y descripción, y
  su .salida.txt: lo que la sesión vio (hasta 20.000 caracteres), la referencia de una corrida nueva.
  Se marca "edita" el que escribe archivos (por patrón: write_text, sed -i, open(…, 'w')…);
  --sin-ediciones los omite, y siguen en comandos.sh.
- comandos.sh: todos los comandos Bash en orden, con hora y descripción. Una bitácora, no un script.
- bitacora.md: los comandos que ejecutaron código (docker, uv, pytest, go, dotnet, `python3 x.py`…;
  el cuerpo de un heredoc no cuenta, así que escribir prosa que menciona dotnet no es ejecutar), con
  los primeros 1.500 caracteres de su salida.

--inventario solo lista, por sesión, los archivos tocados con Write/Edit y, con --bash, los comandos.

Solo lee las transcripciones y nunca ejecuta lo que extrae. Una salida anterior con el mismo nombre se
reemplaza solo si tiene comandos.sh (es decir, si la hizo esta herramienta).

El seguimiento del directorio actual es aproximado: sigue los cd de nivel superior (no los de un
subshell, un bucle o un texto entre comillas), resuelve `mkdir -p X && cd $_` y, como el shell no
siempre conservaba el cd entre comandos, colapsa un tramo repetido (src/a/src/b) cuando eso cae en un
directorio que existe. Conviene revisar archivos.tsv.
Solo biblioteca estándar.
"""

import collections
import glob
import json
import os
import re
import shutil
import sys

REPO = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
TRANSCRIPCIONES = os.path.join(os.path.expanduser("~/.claude/projects"), REPO.replace("/", "-"))

EXEC = re.compile(r"\b(docker|podman|uv (run|pip)|pytest|go (run|test|build|vet)|dotnet|python3? [\w./-]+\.py|\.venv/bin/)")
HEREDOC_BODY = re.compile(r"<<-?\s*'?\"?(\w+)'?\"?\n.*?\n\1\s*$", re.S | re.M)
HEREDOC_FILE = re.compile(r"cat\s+>\s*(\S+)\s*<<-?\s*'?\"?(\w+)'?\"?\n(.*?)\n\2\s*$", re.S | re.M)
HEREDOC_INLINE = re.compile(r"(python3?|bash|sh|node)\s+(?:-\s+)?<<-?\s*'?\"?(\w+)'?\"?\n(.*?)\n\2\s*$", re.S | re.M)
WRITES = re.compile(r"write_text|\.write\(|open\([^)]*['\"][wa]b?['\"]|sed -i|> *[\w$/.-]+\.(md|py|cs|go)\b|os\.(rename|remove)|shutil\.")
ASSIGN = re.compile(r"(?:^|[;&\s])([A-Z][A-Z0-9_]*)=(\"[^\"]*\"|'[^']*'|[^\s;&]+)")
MKDIR = re.compile(r"mkdir\s+(?:-p\s+)?(?:\S+\s+)*?(\"[^\"]*\"|'[^']*'|[^\s;&|)]+)\s*(?:&&|;)\s*cd\s+\$_")
CD = re.compile(r"(?:^|[;&|(]\s*|\n\s*)cd\s+(\"[^\"]*\"|'[^']*'|[^\s;&|)]+)")
IGNORADOS = {"tmp", "salidas", "node_modules", "target", "build", "dist", "out", ".venv", "venv",
             "__pycache__", "bin", "obj", "vendor", "coverage"}
ENTRE_COMILLAS = 99


def archivos_de_sesion(base, sid):
    files = [os.path.join(base, sid + ".jsonl")]
    files += sorted(glob.glob(os.path.join(base, sid, "**", "*.jsonl"), recursive=True))
    return [f for f in files if os.path.exists(f)]


def eventos(path):
    """(hora, tipo, datos): tipo 'uso' con (herramienta, entrada, id) o 'resultado' con (id, texto)."""
    with open(path, encoding="utf-8") as fh:
        for line in fh:
            try:
                rec = json.loads(line)
            except json.JSONDecodeError:
                continue
            content = (rec.get("message") or {}).get("content")
            if not isinstance(content, list):
                continue
            ts = rec.get("timestamp", "")
            for part in content:
                if part.get("type") == "tool_use":
                    yield ts, "uso", (part["name"], part.get("input") or {}, part.get("id"))
                elif part.get("type") == "tool_result":
                    c = part.get("content")
                    if isinstance(c, list):
                        c = "\n".join(x.get("text", "") for x in c if isinstance(x, dict))
                    yield ts, "resultado", (part.get("tool_use_id"), c or "")


def expandir(word, env):
    word = word.strip("\"'")
    word = re.sub(r"\$\{?([A-Z][A-Z0-9_]*|_)\}?", lambda m: env.get(m.group(1), m.group(0)), word)
    return os.path.expanduser(word)


def resolver(cwd, word, env):
    p = expandir(word, env)
    return os.path.normpath(p if p.startswith("/") else os.path.join(cwd, p))


def anidamiento(cmd):
    """Profundidad de subshell o bucle en cada carácter, para que un cd dentro de (...) o do...done no
    persista; el texto entre comillas se marca aparte y sus cd se ignoran."""
    depth, d, i = [0] * (len(cmd) + 1), 0, 0
    tokens = r"'[^']*'|\"(?:\\.|[^\"\\])*\"|\(|\)|\bdo\b|\bdone\b|<<-?\s*'?\"?(\w+)'?\"?\n.*?\n\1\s*$"
    for tok in re.finditer(tokens, cmd, re.S | re.M):
        for k in range(i, tok.start()):
            depth[k] = d
        i = tok.start()
        t = tok.group(0)
        if t[0] in "'\"":
            for k in range(tok.start(), tok.end()):
                depth[k] = ENTRE_COMILLAS
            i = tok.end()
        elif t in ("(", "do"):
            d += 1
        elif t in (")", "done"):
            d = max(0, d - 1)
    for k in range(i, len(cmd) + 1):
        depth[k] = d
    return depth


def recorrer(cmd, cwd):
    """(ruta y contenido de cada `cat > ruta <<EOF`, directorio que queda) siguiendo cd y VAR= en orden."""
    env, marcas = {}, []
    depth = anidamiento(cmd)
    local = cwd
    evs = [(m.start(), "asigna", m) for m in ASSIGN.finditer(cmd)]
    evs += [(m.start(), "cd", m) for m in CD.finditer(cmd)]
    evs += [(m.start(), "mkdir", m) for m in MKDIR.finditer(cmd)]
    evs += [(m.start(), "archivo", m) for m in HEREDOC_FILE.finditer(cmd)]
    for _, kind, m in sorted(evs, key=lambda e: e[0]):
        if kind == "asigna":
            env[m.group(1)] = expandir(m.group(2), env)
        elif kind == "mkdir":
            env["_"] = os.path.join(local, expandir(m.group(1), env))
        elif depth[m.start()] == ENTRE_COMILLAS:
            continue
        elif kind == "cd":
            local = resolver(local, m.group(1), env)
            if depth[m.start()] == 0:
                cwd = local
        else:
            marcas.append((resolver(local, m.group(1), env), m.group(3)))
    return marcas, cwd


def reparar(path):
    """Si el directorio no existe, quita el tramo entre dos segmentos iguales (src/a/src/b → src/b)
    cuando eso cae en un directorio que sí existe."""
    if os.path.isdir(os.path.dirname(path)):
        return path
    segs = path.split("/")
    for i in range(1, len(segs) - 1):
        for j in range(i + 1, len(segs) - 1):
            if segs[i] == segs[j]:
                cand = "/".join(segs[:i] + segs[j:])
                if os.path.isdir(os.path.dirname(cand)):
                    return cand
    return path


def ruta_guardada(path):
    rel = os.path.relpath(path, REPO) if path.startswith(REPO + "/") else path.lstrip("/")
    if rel.startswith("private/tmp/"):
        rel = rel[len("private/"):]
    return "/".join("_" + seg if seg in IGNORADOS else seg for seg in rel.split("/"))


def en_disco(path):
    """La ruta donde el archivo está hoy: la original o, si un curso se movió de la raíz a una familia
    (`<repo>/<curso>/…` → `<repo>/cursos-<familia>/<curso>/…`), la que quedó un nivel más abajo."""
    if os.path.isfile(path):
        return path
    if path.startswith(REPO + "/"):
        rel = os.path.relpath(path, REPO)
        movidos = [p for p in glob.glob(os.path.join(glob.escape(REPO), "*", rel)) if os.path.isfile(p)]
        if len(movidos) == 1:
            return movidos[0]
    return None


def aplicar_edit(text, inp):
    old, new = inp.get("old_string", ""), inp.get("new_string", "")
    if old not in text:
        return text, False
    if inp.get("replace_all"):
        return text.replace(old, new), True
    return text.replace(old, new, 1), True


def inventario(base, sids, con_bash):
    for sid in sids:
        tocados, bash = collections.Counter(), []
        for f in archivos_de_sesion(base, sid):
            for ts, kind, datos in eventos(f):
                if kind != "uso":
                    continue
                name, inp, _ = datos
                if name in ("Write", "Edit", "MultiEdit", "NotebookEdit"):
                    tocados[(name, inp.get("file_path") or inp.get("notebook_path"))] += 1
                elif name == "Bash":
                    bash.append((ts, inp.get("command", "")))
        print(f"=== {sid}")
        for (name, p), n in sorted(tocados.items(), key=lambda kv: kv[0][1] or ""):
            print(f"{name:10} {n:3} {p}")
        if con_bash:
            for ts, cmd in bash:
                print(f"BASH {ts[:19]} {cmd.splitlines()[0][:200] if cmd else ''}")


def rescatar(base, dest, sid, opts, banderas, cwd):
    inc = re.compile(opts.get("--incluir", "."))
    exc = re.compile(opts["--excluir"]) if "--excluir" in opts else None
    out = os.path.join(dest, opts.get("--nombre", sid[:8]))
    if os.path.isdir(out):
        if not os.path.isfile(os.path.join(out, "comandos.sh")):
            sys.exit(f"{out} existe y no es una salida de esta herramienta: no se toca")
        shutil.rmtree(out)
    os.makedirs(os.path.join(out, "scripts"), exist_ok=True)

    files, fallidas, comandos, resultados = {}, [], [], {}
    for f in archivos_de_sesion(base, sid):
        for ts, kind, datos in eventos(f):
            if kind == "resultado":
                resultados[datos[0]] = datos[1]
                reset = re.search(r"Shell cwd was reset to (\S+)", datos[1])
                if reset:
                    cwd = reset.group(1)
                continue
            name, inp, uid = datos
            path = inp.get("file_path")
            if name == "Write" and path:
                files[path] = inp.get("content", "")
            elif name == "Edit" and path in files:
                files[path], ok = aplicar_edit(files[path], inp)
                if not ok:
                    fallidas.append((ts, path))
            elif name == "MultiEdit" and path in files:
                for e in inp.get("edits", []):
                    files[path], ok = aplicar_edit(files[path], e)
                    if not ok:
                        fallidas.append((ts, path))
            elif name == "Bash":
                cmd = inp.get("command", "")
                comandos.append((ts, inp.get("description", ""), cmd, uid))
                marcas, cwd = recorrer(cmd, cwd)
                for target, body in marcas:
                    files[reparar(target)] = body + "\n"

    guardados = 0
    with open(os.path.join(out, "archivos.tsv"), "w", encoding="utf-8") as index:
        index.write("estado\truta original\n")
        for path, text in sorted(files.items()):
            if not inc.search(path) or (exc and exc.search(path)):
                continue
            hoy = en_disco(path)
            if hoy:
                with open(hoy, encoding="utf-8", errors="replace") as fh:
                    estado = "existe-igual" if fh.read() == text else "existe-distinto"
                if hoy != path:
                    estado += f" (movido a {os.path.relpath(hoy, REPO)})"
            else:
                estado = "no-existe"
            publicado = re.search(r"/cursos-[^/]+/|/\.claude/", hoy or path)
            if "--solo-perdidos" in banderas and estado != "no-existe":
                continue
            if "--todo" not in banderas and (estado.startswith("existe-igual") or (publicado and estado != "no-existe")
                                             or (path.endswith(".md") and path.startswith(REPO + "/"))):
                continue
            index.write(f"{estado}\t{path}\n")
            target = os.path.join(out, "archivos", ruta_guardada(path))
            os.makedirs(os.path.dirname(target), exist_ok=True)
            with open(target, "w", encoding="utf-8") as fh:
                fh.write(text)
            guardados += 1

    n = ejecuciones = 0
    with open(os.path.join(out, "comandos.sh"), "w", encoding="utf-8") as sh, \
            open(os.path.join(out, "bitacora.md"), "w", encoding="utf-8") as log:
        sh.write(f"# Comandos Bash de la sesión {sid}, en orden. Una bitácora, no un script: no se corre entera.\n\n")
        log.write(f"# Bitácora de ejecución · sesión {sid}\n\nComandos que ejecutaron código, con el inicio de su salida.\n\n")
        for ts, desc, cmd, uid in comandos:
            sh.write(f"# --- {ts[:19]} · {desc}\n{cmd}\n\n")
            scripts = [(m.group(1), m.group(3)) for m in HEREDOC_INLINE.finditer(cmd)]
            if not scripts and cmd.count("\n") >= 2 and not HEREDOC_FILE.search(cmd):
                scripts = [("bash", cmd)]
            for interp, body in scripts:
                rol = "edita" if WRITES.search(body) else "verifica"
                if rol == "edita" and "--sin-ediciones" in banderas:
                    continue
                n += 1
                ext = ".py" if interp.startswith("python") else ".js" if interp == "node" else ".sh"
                hdr = "//" if ext == ".js" else "#"
                name = f"{n:03d}-{ts[11:13]}{ts[14:16]}-{rol}{ext}"
                with open(os.path.join(out, "scripts", name), "w", encoding="utf-8") as fh:
                    fh.write(f"{hdr} rescatado de la sesión {sid[:8]}, {ts[:19]}Z · {desc}\n{body}\n")
                if uid in resultados:
                    with open(os.path.join(out, "scripts", os.path.splitext(name)[0] + ".salida.txt"), "w",
                              encoding="utf-8") as fh:
                        fh.write(resultados[uid][:20000] + "\n")
            if EXEC.search(HEREDOC_BODY.sub("<<heredoc", cmd)):
                ejecuciones += 1
                res = resultados.get(uid, "")
                log.write(f"### ⏱️ {ts[:19]}Z · {desc}\n\n~~~~~~bash\n{cmd}\n~~~~~~\n\n~~~~~~text\n{res[:1500]}\n~~~~~~\n\n")

    if ejecuciones == 0:
        os.remove(os.path.join(out, "bitacora.md"))
    if guardados == 0:
        os.remove(os.path.join(out, "archivos.tsv"))
    if n == 0:
        os.rmdir(os.path.join(out, "scripts"))
    print(f"{sid[:8]}: {guardados} archivos, {n} scripts, {len(comandos)} comandos, {len(fallidas)} ediciones sin aplicar")
    for ts, path in fallidas:
        print(f"  edición sin aplicar {ts[:19]} {path}")


def main():
    args = sys.argv[1:]
    opts = {}
    for flag in ("--incluir", "--excluir", "--nombre", "--cwd", "--transcripciones"):
        if flag in args:
            i = args.index(flag)
            opts[flag] = args[i + 1]
            del args[i:i + 2]
    banderas = {a for a in args if a.startswith("--")}
    args = [a for a in args if not a.startswith("--")]
    base = opts.get("--transcripciones", TRANSCRIPCIONES)
    if "--inventario" in banderas:
        inventario(base, args, "--bash" in banderas)
    elif len(args) == 2:
        rescatar(base, args[0], args[1], opts, banderas, opts.get("--cwd", REPO))
    else:
        sys.exit(__doc__)


if __name__ == "__main__":
    main()
