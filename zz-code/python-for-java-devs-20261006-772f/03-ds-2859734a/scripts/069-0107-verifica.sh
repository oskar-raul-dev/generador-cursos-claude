# rescatado de la sesión 2859734a, 2026-09-14T01:07:09Z · Run the reproducibility measurement
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs/src/ds06-notebooks-y-reproducibilidad
python3 generar_cuadernos.py --salida cuadernos >/dev/null && ls cuadernos
time uv run --python 3.14 --with 'papermill==2.7.0' python check_reproducibility.py --cuadernos cuadernos --json resultado.json 2>&1 | tail -12
