# rescatado de la sesión 2859734a, 2026-09-14T02:46:49Z · Check INSTINTOS numbering and the ia measurement claim
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs
echo "=== numeración de INSTINTOS ==="; grep -nE "^### [0-9]+\." INSTINTOS.md | awk -F'[.#]' '{print $0}' | sed 's/\(### [0-9]*\).*/\1/' | tr '\n' ' '; echo
echo; echo "=== la afirmación de las mediciones ia en BENCHMARKS ==="; sed -n '/Complementos `ia` — pendientes/,+10p' BENCHMARKS.md | head -12
echo; echo "=== filas de la tabla ia ==="; sed -n '/| Sección | Qué compara | Estado |/,/^$/p' BENCHMARKS.md | grep -c "^| \[" 
