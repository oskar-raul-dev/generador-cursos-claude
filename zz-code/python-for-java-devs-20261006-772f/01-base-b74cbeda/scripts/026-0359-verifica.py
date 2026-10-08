# rescatado de la sesión b74cbeda, 2026-09-13T03:59:15Z · Build the fair LOC comparison
import ast, pathlib
src = pathlib.Path("app_duelo.py").read_text()
tree = ast.parse(src)
for n in ast.walk(tree):
    if isinstance(n,(ast.Module,ast.ClassDef,ast.FunctionDef)):
        if n.body and isinstance(n.body[0], ast.Expr) and isinstance(n.body[0].value, ast.Constant) and isinstance(n.body[0].value.value,str):
            n.body.pop(0)
print("FastAPI, solo el endpoint del duelo:", len([l for l in ast.unparse(tree).splitlines() if l.strip()]), "líneas")
