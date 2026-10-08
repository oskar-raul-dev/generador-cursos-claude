# rescatado de la sesión 2859734a, 2026-09-14T02:52:45Z · Inspect the network-marked tests
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs/src/ia01-el-modelo-de-acceso-de-un-llm
sed -n 1,35p test_failures.py
echo "=== ¿hay configuración de marcadores? ==="; ls -a | grep -iE "pytest|conftest|ini|toml" || echo "  ninguna"
