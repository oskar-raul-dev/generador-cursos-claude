# rescatado de la sesión bd47dbaf, 2026-09-13T19:18:40Z · Inspect miniproject format references
import pathlib, re

# formato-de-miniproyectos
p = pathlib.Path('prompts/formato-de-miniproyectos.md'); t = p.read_text()
old = t[t.index("mecanismo principal de consolidación del curso: ocupa el lugar que en los cursos hermanos del"):]
head = old.split("\n\n")[0]
print("ANTES:", head[:400])
