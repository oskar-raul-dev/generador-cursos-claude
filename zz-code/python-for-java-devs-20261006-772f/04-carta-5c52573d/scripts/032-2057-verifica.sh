# rescatado de la sesión 5c52573d, 2026-10-05T20:57:56Z · Rebuild all three and measure
set -euo pipefail
for dir in rs pb nb; do
  start=$(date +%s)
  pip wheel --quiet --no-deps --wheel-dir "dist/$dir" "./$dir" >/dev/null 2>&1 || { echo "$dir: falló la construcción"; continue; }
  wheel=$(ls dist/"$dir"/*.whl)
  printf '%-3s construcción %3s s · rueda %4s KB · %s\n' "$dir" "$(( $(date +%s) - start ))" "$(( $(stat -c %s "$wheel") / 1024 ))" "$(basename "$wheel")"
done
pip install --quiet dist/*/*.whl
