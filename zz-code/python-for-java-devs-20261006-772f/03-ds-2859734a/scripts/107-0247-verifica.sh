# rescatado de la sesión 2859734a, 2026-09-14T02:47:14Z · Read INSTINTOS intro and count the base reflexes
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs
sed -n 1,20p INSTINTOS.md
echo "=== los 18 del camino base ==="; python3 -c "
import re
lines=open('INSTINTOS.md',encoding='utf-8').read().splitlines()
base=[l for l in lines[:400] if re.match(r'^## \d+\.', l)]
print(len(base), 'reflejos de camino base ·', base[0], '...', base[-1])"
