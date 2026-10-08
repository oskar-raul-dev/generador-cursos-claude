# rescatado de la sesión 2859734a, 2026-09-13T19:53:48Z · Read history index and data projects section
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs
echo "=== indice historia ==="; grep -n "^## \|^### " 00-historia-de-aurea.md
echo "=== §8 ==="; sed -n '/^## 8\./,/^## 9\./p' 00-historia-de-aurea.md
