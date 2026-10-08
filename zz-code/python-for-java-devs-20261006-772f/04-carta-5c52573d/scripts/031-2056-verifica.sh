# rescatado de la sesión 5c52573d, 2026-10-05T20:56:17Z · Build PyO3/pybind11/nanobind extensions and measure
set -euo pipefail
for pkg in ema_rs ema_pb ema_nb; do
  start=$(date +%s)
  pip wheel --quiet --no-deps --wheel-dir dist "./$pkg" >/dev/null 2>&1 || { echo "$pkg: falló la construcción"; continue; }
  wheel=$(ls dist/"${pkg/_/_}"*.whl)
  printf '%-7s construcción %3s s · rueda %4s KB · %s\n' "$pkg" "$(( $(date +%s) - start ))" "$(( $(stat -c %s "$wheel") / 1024 ))" "$(basename "$wheel")"
done
pip install --quiet dist/*.whl
