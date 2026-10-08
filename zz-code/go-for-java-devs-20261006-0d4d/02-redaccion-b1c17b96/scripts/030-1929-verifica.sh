# rescatado de la sesión b1c17b96, 2026-09-12T19:29:06Z · Check sibling proposal and lab structure
cd /Users/oskar/Developer/Learning/courses-ia-generated/propuestas-cursos
echo "=== complemento-docker README ==="; head -40 propuesta-complemento-docker/README.md 2>/dev/null || ls propuesta-complemento-docker
echo; echo "=== lab-docker: 00-instrucciones (encabezados) ==="
grep -E '^#{1,3} ' propuesta-lab-docker/00-instrucciones.md | head -25
echo; echo "=== 06-anillo-0 (encabezados) ==="
grep -E '^#{1,3} ' propuesta-lab-docker/06-anillo-0-refinamiento-y-hoja-de-ruta.md | head -25
