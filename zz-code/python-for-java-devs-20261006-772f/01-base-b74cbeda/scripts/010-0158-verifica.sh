# rescatado de la sesión b74cbeda, 2026-09-13T01:58:19Z · Rigorous LOC count without docstrings
cd /tmp/claude-501/f03 && /opt/homebrew/bin/python3.14 - <<'EOF'
import ast, pathlib
for f in ("estilo_java.py", "estilo_python.py"):
    src = pathlib.Path(f).read_text()
    tree = ast.parse(src)
    # quita docstrings
    for node in ast.walk(tree):
        if isinstance(node, (ast.Module, ast.ClassDef, ast.FunctionDef, ast.AsyncFunctionDef)):
            if node.body and isinstance(node.body[0], ast.Expr) and isinstance(node.body[0].value, ast.Constant) and isinstance(node.body[0].value.value, str):
                node.body.pop(0)
    code = ast.unparse(tree)
    loc = len([l for l in code.splitlines() if l.strip()])
    stmts = sum(1 for n in ast.walk(tree) if isinstance(n, ast.stmt))
    classes = sum(1 for n in ast.walk(tree) if isinstance(n, ast.ClassDef))
    funcs = sum(1 for n in ast.walk(tree) if isinstance(n, (ast.FunctionDef, ast.AsyncFunctionDef)))
    print(f"{f:<20} líneas {loc:>3} · sentencias {stmts:>3} · clases {classes} · funciones {funcs}")
EOF
