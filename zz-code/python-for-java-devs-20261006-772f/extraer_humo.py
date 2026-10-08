#!/usr/bin/env python3
"""Pull every run of the carta's smoke harness out of a rescued comandos.sh.

Usage:
    python3 extraer_humo.py 04-carta-5c52573d/comandos.sh > 04-carta-5c52573d/humo-por-seccion.sh

Keeps, for each section id (the harness's second argument), the last Bash command in which the
session called `python3 humo.py` or `python3 humo_servicio.py`: the run whose output went into the
published section. The whole command is kept verbatim, cd and pipes included, as it ran.
"""

import re
import shlex
import sys

CALL = re.compile(r"python3 (humo(?:_servicio)?\.py) ")


def cut_call(segment):
    """The harness call up to the first top-level pipe or redirection, using shlex to respect quotes."""
    lex = shlex.shlex(segment, posix=False, punctuation_chars="|&;<>")
    lex.whitespace_split = True
    out = []
    for tok in lex:
        if tok in ("|", "||", "&&", ";", "&") or tok.startswith(("2>", ">")) or re.fullmatch(r"[0-9]*>+&?[0-9]*", tok):
            break
        out.append(tok)
    return " ".join(out)


def main():
    text = open(sys.argv[1], encoding="utf-8").read()
    last, order = {}, []
    for block in text.split("\n# --- ")[1:]:
        header, _, cmd = block.partition("\n")
        ts = header.split(" · ")[0]
        for m in CALL.finditer(cmd):
            call = cut_call(cmd[m.start():])
            parts = call.split()
            if len(parts) < 4:
                continue
            key = parts[3]
            if key not in last:
                order.append(key)
            last[key] = (ts, parts[2], cmd.rstrip())
    print("#!/usr/bin/env bash")
    print("# Last smoke-harness run per carta section, as session 5c52573d ran it (05/10/2026).")
    print("# A log of whole commands, not a script to run end to end: copy the block of one section.")
    print("# Most blocks cd into the carta's zz-code directory (python-for-java-devs-20261005-f516) themselves;")
    print("# the harness runs the code in a python:3.14.7 container labelled curso=python-for-java-devs.")
    print("set -uo pipefail\n")
    for key in sorted(order):
        ts, section, call = last[key]
        print(f"# --- {key} · {section} · {ts}Z")
        print(call + "\n")
    print(f"# {len(order)} secciones", file=sys.stderr)


if __name__ == "__main__":
    main()
