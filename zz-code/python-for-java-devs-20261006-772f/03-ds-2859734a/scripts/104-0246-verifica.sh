# rescatado de la sesión 2859734a, 2026-09-14T02:46:39Z · Cross-check figures cited between sections
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs
echo "=== cifras que una sección cita de otra ==="
echo "-- CAC de ds01/ds04 citado fuera:"; grep -rn "siete veces\|seis veces\|9.394.725\|11.098.164\|1.583.564" ds0*.md BENCHMARKS.md INSTINTOS.md | grep -v pytest
echo; echo "-- la banda de ds04 (1,06 / 7,96 / 7,5×):"; grep -rn "7,5×\|7.96\|1,06" ds0*.md BENCHMARKS.md INSTINTOS.md | head -12
echo; echo "-- la línea base de ds07 (0,799 / 0,526):"; grep -rn "0,799\|0,526\|0.799" ds0*.md BENCHMARKS.md INSTINTOS.md | head -12
echo; echo "-- el 77 MB de ds02 citado en ds03:"; grep -rn "76,9 MB\|77 MB" ds0*.md BENCHMARKS.md | head
