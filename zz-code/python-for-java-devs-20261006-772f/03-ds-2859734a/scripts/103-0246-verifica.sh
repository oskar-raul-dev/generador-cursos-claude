# rescatado de la sesión 2859734a, 2026-09-14T02:46:17Z · Check the dependency chain across both tracks
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs
echo "=== cadena Depende/Habilita y numeración de los tracks ==="
for f in ia0*.md ds0*.md; do printf "%-40s" "$f"; sed -n '3,6p' $f | tr '\n' ' ' | sed 's/> //g' | cut -c1-135; echo; done
