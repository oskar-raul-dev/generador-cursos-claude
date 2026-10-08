# rescatado de la sesión b74cbeda, 2026-09-13T03:59:00Z · Count lines and check Docker
import ast, pathlib, re
# Python
src = pathlib.Path("app.py").read_text()
tree = ast.parse(src)
for node in ast.walk(tree):
    if isinstance(node,(ast.Module,ast.ClassDef,ast.FunctionDef,ast.AsyncFunctionDef)):
        if node.body and isinstance(node.body[0], ast.Expr) and isinstance(node.body[0].value, ast.Constant) and isinstance(node.body[0].value.value,str):
            node.body.pop(0)
code = ast.unparse(tree)
# solo el endpoint de disponibilidad y sus modelos
py_loc = len([l for l in code.splitlines() if l.strip()])
print(f"FastAPI (app.py completo, incluye el POST de reservas): {py_loc} líneas")
# Java
total=0
for f in sorted(pathlib.Path("agenda-java/src/main/java").rglob("*.java")):
    lines=[l for l in f.read_text().splitlines()
           if l.strip() and not l.strip().startswith(("//","/*","*","*/"))]
    print(f"  {f.name}: {len(lines)}")
    total+=len(lines)
pom=len([l for l in pathlib.Path("agenda-java/pom.xml").read_text().splitlines() if l.strip()])
props=len([l for l in pathlib.Path("agenda-java/src/main/resources/application.properties").read_text().splitlines() if l.strip()])
print(f"Spring Boot: {total} líneas de Java + {pom} de pom.xml + {props} de properties = {total+pom+props}")
