"""Generar Python desde datos: con cadenas y con el árbol de sintaxis."""

import ast
import keyword

# Lo que sale del catálogo de la base de Cartera (simplificado).
TABLE = "abono"
COLUMNS = [
    ("id", "int", None),
    ("valor", "int", 0),
    ("class", "str", "efectivo"),                 # la columna se llama así en la base heredada
    ("nota", "str", "pago d'Alessandro"),         # un valor por defecto con comilla
]


def with_strings() -> str:
    lines = ["from dataclasses import dataclass", "", "", "@dataclass",
             f"class {TABLE.title()}:"]
    for name, typ, default in COLUMNS:
        suffix = "" if default is None else f" = '{default}'" if typ == "str" else f" = {default}"
        lines.append(f"    {name}: {typ}{suffix}")
    return "\n".join(lines) + "\n"


def with_ast() -> str:
    body = []
    for name, typ, default in COLUMNS:
        attr = f"{name}_" if keyword.iskeyword(name) else name   # PEP 8: 'class' -> 'class_'
        body.append(ast.AnnAssign(
            target=ast.Name(attr, ast.Store()), annotation=ast.Name(typ, ast.Load()),
            value=None if default is None else ast.Constant(default), simple=1))
    module = ast.Module(body=[
        ast.ImportFrom("dataclasses", [ast.alias("dataclass")], 0),
        ast.ClassDef(name=TABLE.title(), bases=[], keywords=[], body=body,
                     decorator_list=[ast.Name("dataclass", ast.Load())], type_params=[]),
    ], type_ignores=[])
    return ast.unparse(ast.fix_missing_locations(module)) + "\n"


for label, generate in [("cadenas", with_strings), ("ast", with_ast)]:
    code = generate()
    try:
        compile(code, f"<{label}>", "exec")
        print(f"--- {label}: compila\n{code}")
    except SyntaxError as e:
        print(f"--- {label}: NO compila — {e.msg} (línea {e.lineno})\n{code}")
