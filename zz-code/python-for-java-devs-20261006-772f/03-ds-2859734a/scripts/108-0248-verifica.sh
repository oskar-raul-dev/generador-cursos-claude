# rescatado de la sesión 2859734a, 2026-09-14T02:48:28Z · Audit exercises for external systems and unpinned tools
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs
echo "=== ejercicios que exijan un servicio externo o datos de fuera ==="
grep -rnE "^[0-9]+\. |^   " ds0*.md | grep -iE "un repositorio (público|de verdad|real)|tu propio trabajo|tu equipo|cinco personas|tu máquina|disco externo|volumen de red|Postgres" | head -12
echo
echo "=== ¿algún ejercicio pide instalar algo no fijado en alcance §9? ==="
grep -rnoE "\b(xgboost|lightgbm|dask|spark|ray|streamlit|dash|panel|shap|lime|jupytext|nbstripout|netron|seaborn|statsmodels|pyarrow|httpx|marimo)\b" ds0*.md | sort -t: -k3 | awk -F: '{print $3}' | sort | uniq -c | sort -rn
