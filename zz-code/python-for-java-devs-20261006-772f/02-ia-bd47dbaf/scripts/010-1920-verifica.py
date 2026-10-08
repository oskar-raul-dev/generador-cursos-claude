# rescatado de la sesión bd47dbaf, 2026-09-13T19:20:03Z · Inspect remaining cursos-ia reference context
import pathlib

p = pathlib.Path('prompts/propuestas-temas-opcionales.md'); t = p.read_text()
t = t.replace("""convención del `CLAUDE.md` del repositorio— está en la §2.""",
"""convenciones de nombre del curso— está en la §2 y su definición en la guía de estilo §8.2.""")
old = t[t.index("> `cursos-ia`.")-400:]
# localizar el párrafo exacto
i = t.index("`cursos-ia`.")
ctx = t[max(0,i-300):i+20]
print("CONTEXTO:\n", ctx)
