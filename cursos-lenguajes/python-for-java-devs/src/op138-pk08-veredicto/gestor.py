"""¿uv, lo que ya hay o conda? El veredicto del track como función, aplicado a los proyectos de Áurea."""

from dataclasses import dataclass


@dataclass
class Project:
    name: str
    current_tool: str = "ninguno"           # "poetry", "pip-tools", "conda"…
    works_today: bool = True
    needs_native_libs: bool = False         # GDAL, CUDA, compiladores
    target: str = "servidor"                # "servidor", "persona", "biblioteca"
    only_pip_available: bool = False


def decide(p: Project) -> str:
    if p.needs_native_libs:
        return "conda (Miniforge), con conda-lock"
    if p.only_pip_available:
        return "pip + pip-tools, con hashes (el lock lo genera el CI)"
    if p.current_tool not in ("ninguno", "uv") and p.works_today:
        return f"se queda en {p.current_tool}; pyproject.toml en PEP 621"
    if p.target == "persona":
        return "uv tool install (o shiv, si todos usan la misma plataforma)"
    if p.target == "biblioteca":
        return "uv build + índice privado"
    return "uv, con versión fija en el CI"


PROJECTS = [
    Project("API de cartera"),
    Project("Agente de sincronización de sedes", current_tool="pip-tools", works_today=False),
    Project("Análisis geográfico de pacientes", needs_native_libs=True),
    Project("Herramienta de la franquicia de Zipaquirá", current_tool="poetry"),
    Project("aurea-cartera (biblioteca compartida)", target="biblioteca"),
    Project("Reporte de regalías para Patricia", target="persona"),
    Project("Cron del servidor de la sede Restrepo", only_pip_available=True),
]
for p in PROJECTS:
    print(f"{p.name:<44} → {decide(p)}")
