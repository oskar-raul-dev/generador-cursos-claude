"""Tres formas de leer el mismo código: fichas, árbol tolerante y árbol exacto."""

import ast

import tree_sitter_python
from pygments.lexers import PythonLexer
from pygments.token import Number
from tree_sitter import Language, Parser

SOURCE = """\
def cerrar_caja(pagos):
    saldo = 0.0
    tasa = 0.19
    for pago in pagos:
        saldo += pago.monto
    return saldo
"""
BROKEN = SOURCE.replace("for pago in pagos:", "for pago in pagos")      # falta el ':'
MONEY = ("saldo", "monto", "valor", "total", "abono")

# ------------------------------------------------- 1. fichas (Pygments)
floats = [v for t, v in PythonLexer().get_tokens(SOURCE) if t in Number.Float]
print("Pygments ve números decimales:", floats, "— pero no a qué se asignan")

# ------------------------------------------------- 2. árbol tolerante (tree-sitter)
parser = Parser(Language(tree_sitter_python.language()))


def ts_findings(code: str) -> list[str]:
    tree = parser.parse(code.encode())
    found, stack = [], [tree.root_node]
    while stack:
        node = stack.pop()
        stack.extend(node.children)
        if node.type == "assignment":
            left, right = node.child_by_field_name("left"), node.child_by_field_name("right")
            if right is not None and right.type == "float" and left.text.decode().startswith(MONEY):
                found.append(f"línea {node.start_point[0] + 1}: {left.text.decode()} = {right.text.decode()}")
    return found


print("tree-sitter, código sano:", ts_findings(SOURCE))
print("tree-sitter, código roto:", ts_findings(BROKEN))


# ------------------------------------------------- 3. árbol exacto (ast): la regla de la casa
class NoFloatMoney(ast.NodeVisitor):
    def __init__(self):
        self.found = []

    def visit_Assign(self, node: ast.Assign):
        is_float = isinstance(node.value, ast.Constant) and isinstance(node.value.value, float)
        for target in node.targets:
            if is_float and isinstance(target, ast.Name) and target.id.startswith(MONEY):
                self.found.append(f"línea {node.lineno}: '{target.id}' es plata y no puede ser float")
        self.generic_visit(node)


def ast_findings(code: str) -> list[str]:
    try:
        checker = NoFloatMoney()
        checker.visit(ast.parse(code))
        return checker.found
    except SyntaxError as e:
        return [f"sin árbol: {e.msg} (línea {e.lineno})"]


print("ast, código sano:", ast_findings(SOURCE))
print("ast, código roto:", ast_findings(BROKEN))
