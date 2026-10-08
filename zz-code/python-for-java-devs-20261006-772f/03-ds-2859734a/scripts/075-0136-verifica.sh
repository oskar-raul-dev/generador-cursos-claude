# rescatado de la sesión 2859734a, 2026-09-14T01:36:48Z · Re-verify the lint debt list and check scikit-learn
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs
echo "=== ¿sigue en pie la lista de deuda de lint? ==="
uvx ruff@0.16.7 check src/ --output-format concise 2>&1 | grep -v "^src/ds" | tail -20
echo "=== sklearn ==="
cd /tmp && uv run --python 3.14 --with 'scikit-learn==1.9.1' --with 'numpy==2.5.3' python -c "
import sklearn, numpy; print('scikit-learn', sklearn.__version__, '· numpy', numpy.__version__)" 2>&1|tail -2
