set -euo pipefail
uv --version
uv init --quiet --no-workspace aurea-agente && cd aurea-agente
uv add --quiet httpx psycopg[binary]
echo "paquetes en el lock: $(grep -c '^\[\[package\]\]' uv.lock)"
echo "plataformas distintas en las ruedas de psycopg-binary: $(grep -o 'psycopg_binary-[^"]*\.whl' uv.lock | grep -oE '(manylinux|musllinux|macosx|win)[^.]*' | sed 's/_[0-9].*//' | sort -u | tr '\n' ' ')"
uv export --quiet --format requirements-txt --no-hashes | grep -E '^(httpx|psycopg)'
rm -rf .venv && uv sync --frozen --quiet && .venv/bin/python -c "import httpx, psycopg; print('sync desde el lock: OK')"
