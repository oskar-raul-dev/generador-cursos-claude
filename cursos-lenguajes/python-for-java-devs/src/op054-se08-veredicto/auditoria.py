"""Las siete formas de equivocarse del track, buscadas en el árbol de sintaxis."""

import ast
import pathlib
import sys

RULES = {
    "se02": "clave de cifrado escrita en el código",
    "se03": "jwt.decode sin algorithms=",
    "se03b": "resumen rápido (sha256/md5) cerca de una contraseña",
    "se05": "get_secret_value() dentro de una llamada a la bitácora",
    "se06": "verify=False",
    "se07": "yaml.load sin safe_load, o pickle.loads",
    "se07b": "jinja2.Template con texto que no es literal",
}
LOG_METHODS = {"debug", "info", "warning", "error", "exception", "critical"}


def dotted(node: ast.AST) -> str:
    if isinstance(node, ast.Attribute):
        return f"{dotted(node.value)}.{node.attr}"
    return node.id if isinstance(node, ast.Name) else ""


def check(tree: ast.AST) -> list[tuple[int, str]]:
    found = []
    for node in ast.walk(tree):
        if isinstance(node, ast.Assign) and isinstance(node.value, ast.Constant):
            names = [dotted(t).lower() for t in node.targets]
            if any("key" in n or "clave" in n for n in names) and isinstance(node.value.value, bytes):
                found.append((node.lineno, "se02"))
        if not isinstance(node, ast.Call):
            continue
        fn, kwargs = dotted(node.func), {k.arg: k.value for k in node.keywords}
        if fn == "jwt.decode" and "algorithms" not in kwargs:
            found.append((node.lineno, "se03"))
        if fn in {"hashlib.sha256", "hashlib.md5"} and "password" in ast.unparse(node).lower():
            found.append((node.lineno, "se03b"))
        if fn.split(".")[-1] in LOG_METHODS and "get_secret_value" in ast.unparse(node):
            found.append((node.lineno, "se05"))
        if isinstance(kwargs.get("verify"), ast.Constant) and kwargs["verify"].value is False:
            found.append((node.lineno, "se06"))
        if fn in {"yaml.load", "pickle.loads", "pickle.load"}:
            found.append((node.lineno, "se07"))
        if fn in {"Template", "jinja2.Template"} and node.args and not isinstance(node.args[0], ast.Constant):
            found.append((node.lineno, "se07b"))
    return sorted(found)


SAMPLE = '''
import hashlib, httpx, jwt, yaml
from jinja2 import Template
FERNET_KEY = b"q0Zt3Vh0bS1N2b3BtZ0pXc2U4bGJjZ3RmT1VzRkR5bE0="
def login(password, token, raw, text, settings, log):
    digest = hashlib.sha256(password.encode()).hexdigest()
    claims = jwt.decode(token, "secreto")
    log.error("fallo con %s", settings.db_password.get_secret_value())
    r = httpx.get("https://cartera.interno", verify=False)
    config = yaml.load(raw, Loader=yaml.Loader)
    return Template(text).render()
'''

if __name__ == "__main__":
    sources = {p: p.read_text() for p in map(pathlib.Path, sys.argv[1:])} or {"ejemplo.py": SAMPLE}
    total = 0
    for path, source in sources.items():
        for line, rule in check(ast.parse(source)):
            print(f"{path}:{line}  [{rule}] {RULES[rule]}")
            total += 1
    print(f"{total} hallazgos")
    sys.exit(1 if total else 0)
