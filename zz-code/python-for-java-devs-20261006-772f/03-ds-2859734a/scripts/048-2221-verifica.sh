# rescatado de la sesión 2859734a, 2026-09-13T22:21:29Z · Check whether root docs know about the tracks
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs
echo "=== ¿el README y la ESTRUCTURA conocen los tracks? ==="; grep -c "ia01\|track \`ia\`\|complementos" README.md 0-ESTRUCTURA-CURSO.md
echo "=== números más citados ==="; sed -n '/## 🧮 Los números que más se citan/,/^---/p' BENCHMARKS.md | head -25
