# rescatado de la sesión c9051874, 2026-09-13T19:51:39Z · Scan for external paths and prompt references from published docs
echo "=== ../ links ==="; grep -rnE "\]\(\.\./|\]\(/Users|/Users/oskar" . | head -30
echo "=== convención repo-wide ==="; grep -rn "repo-wide\|todo el repositorio de cursos\|convención del repositorio\|nombres son repo\|guía del repositorio\|estándar del repositorio\|defaults del repositorio" .
echo "=== propuestas ==="; grep -rn "propuesta-fases-y-alcance\|alcance-del-proyecto\|guia-de-estilo\|aprendizaje\.md\|plantillas-de-capitulo\|formato-de-benchmarks\|proyecto-0" --include=*.md . | grep -v "^./prompts/" | head -40
