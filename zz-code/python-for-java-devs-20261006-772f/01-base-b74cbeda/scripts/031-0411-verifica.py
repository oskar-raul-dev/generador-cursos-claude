# rescatado de la sesión b74cbeda, 2026-09-13T04:11:20Z · Verify section count and clean up images
import pathlib, re
t = pathlib.Path("17-el-duelo-y-el-veredicto.md").read_text()
# quita bloques de código antes de contar
sin_codigo = re.sub(r"```.*?```", "", t, flags=re.S)
print("Fase 17, secciones reales:", len(re.findall(r"^## ", sin_codigo, re.M)))
print("  = 10 de la plantilla + §6.b (el veredicto, exigido por la propuesta) + 📌 Pendientes")
