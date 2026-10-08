# rescatado de la sesión 2859734a, 2026-09-14T00:59:24Z · Count tests per file and compare with the documented figures
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs/src
for f in ds0*/test_*.py; do printf "%-58s %s\n" "$f" "$(grep -c '^def test_' $f)"; done
echo "--- lo que dicen los README y prompts ---"
grep -rn "pruebas" ds0*/README.md ../prompts/README.md | grep -oE "[0-9]+ pruebas|47 pruebas" | sort | uniq -c
