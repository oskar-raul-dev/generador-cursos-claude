# rescatado de la sesión 2859734a, 2026-09-14T02:54:07Z · Final verification sweep
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs
find . \( -name "__pycache__" -o -name ".pytest_cache" -o -name ".ruff_cache" \) -type d -prune -exec rm -rf {} + 2>/dev/null
rm -rf src/*/data src/*/modelos src/*/salida src/*/cuadernos 2>/dev/null
echo "=== VERIFICACIÓN FINAL ==="
echo "1. referencias externas:"; grep -rniE "go-for-java|c-sharp|csharp|curso hermano|el curso de go|claude\.md|courses-ia-generated|cursos-algoritmos" . 2>/dev/null | grep -v ruff_cache || echo "   ninguna ✅"
echo "2. lint:"; uvx ruff@0.16.7 check src/ >/dev/null 2>&1 && echo "   todo src/ limpio ✅" || echo "   ❌ quedan avisos"
echo "3. pruebas ds:"
t=0; for d in src/ds0*/; do
  n=$(cd $d && timeout 500 uv run --python 3.14 --with pytest --with 'numpy==2.5.3' --with 'pandas==3.0.5' --with 'polars==1.44.2' --with 'duckdb==1.5.5' --with 'matplotlib==3.11.2' --with 'plotly==7.0.0' --with 'altair==6.2.2' --with 'papermill==2.7.0' --with 'jupyterlab==4.6.3' --with 'marimo==0.24.2' --with 'scikit-learn==1.9.1' --with 'torch==2.14.0' --with 'skl2onnx==1.20.0' --with 'onnxruntime==1.30.0' --with 'fastapi==0.141.1' python -m pytest -q -p no:warnings 2>&1 | tail -1)
  printf "   %-44s %s\n" "$(basename $d)" "$n"
done
