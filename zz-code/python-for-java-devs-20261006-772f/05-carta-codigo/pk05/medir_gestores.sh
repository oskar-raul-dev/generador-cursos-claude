set -euo pipefail
DEPS="fastapi sqlalchemy httpx pytest uvicorn"
now() { date +%s.%N; }
measure() {                    # $1 nombre, $2 comando de instalación en frío, $3 comando de reinstalación en caliente
  local start mid
  start=$(now); eval "$2" >/dev/null 2>&1; mid=$(now)
  eval "$3" >/dev/null 2>&1
  printf '%-7s fría %6.1f s · caliente %5.1f s · entorno %s\n' "$1" \
    "$(awk "BEGIN{print $mid - $start}")" "$(awk "BEGIN{print $(now) - $mid}")" "$(du -sh "$4" | cut -f1)"
}

mkdir -p p-poetry && cd p-poetry
poetry init -n --python ">=3.14,<3.15" >/dev/null && poetry config virtualenvs.in-project true --local
export POETRY_CACHE_DIR=/tmp/cache-poetry
measure poetry "poetry add $DEPS" "rm -rf .venv && poetry install --no-root" .venv
cd ..

mkdir -p p-pdm && cd p-pdm
pdm init -n --python 3.14 >/dev/null 2>&1 || true
export PDM_CACHE_DIR=/tmp/cache-pdm
measure pdm "pdm add $DEPS" "rm -rf .venv && pdm install" .venv
cd ..

mkdir -p p-uv && cd p-uv
uv init --quiet --no-workspace . && export UV_CACHE_DIR=/tmp/cache-uv
measure uv "uv add $DEPS" "rm -rf .venv && uv sync" .venv
