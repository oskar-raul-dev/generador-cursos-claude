# rescatado de la sesión 2859734a, 2026-09-13T19:52:44Z · Find tanda records and read ds blocks
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs
echo "=== grep Tanda ==="; grep -rn "Tanda\|tanda" --include=*.md . | grep -v pytest_cache | head -30
echo; echo "=== ds blocks ==="; sed -n '/^## # ds01/,$p' prompts/prompts-de-tracks-ia-ds.md
