# rescatado de la sesión 2859734a, 2026-09-13T22:29:10Z · Verify ds04 after the partner fix
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs/src/ds04-embudo
uv run --python 3.14 --with pytest python -m pytest -q 2>&1|tail -3
echo "--- ¿cambió la atribución? ---"
python3 bench_attribution.py --datos data 2>&1 | sed -n '15,22p'
