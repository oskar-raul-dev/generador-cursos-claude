# rescatado de la sesión bd47dbaf, 2026-09-13T19:22:18Z · Inspect last two external references
import pathlib

# Los dos últimos, en prompts/
p = pathlib.Path('prompts/prompts-de-fase.md'); t = p.read_text()
i = t.index("contenedores ni de orquestación, y lo demás se enlaza a `cursos-contenedores-cloud-infra`")
print("CONTEXTO fase:", repr(t[i-200:i+160]))
p2 = pathlib.Path('prompts/propuesta-fases-y-alcance.md'); t2 = p2.read_text()
j = t2.index("resto se enlaza a `cursos-contenedores-cloud-infra`")
print()
print("CONTEXTO propuesta:", repr(t2[j-260:j+180]))
