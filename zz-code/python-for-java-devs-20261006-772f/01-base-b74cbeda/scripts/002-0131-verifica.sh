# rescatado de la sesión b74cbeda, 2026-09-13T01:31:14Z · Benchmark pip-tools cold and warm
set -e
cd /tmp/claude-501/mgr
export PIP_CACHE_DIR=/tmp/claude-501/mgr/cache-pip
rm -rf .venv-pip reqs.txt "$PIP_CACHE_DIR"
/opt/homebrew/bin/python3.14 -m venv .venv-pip
./.venv-pip/bin/python -m pip install -q --disable-pip-version-check pip-tools==7.6.1
echo "--- compile FRIO ---"; { time ./.venv-pip/bin/pip-compile -q --no-strip-extras -o reqs.txt reqs.in ; } 2>&1 | grep real
echo "--- sync FRIO ---";    { time ./.venv-pip/bin/pip-sync -q reqs.txt ; } 2>&1 | grep real
du -sh .venv-pip | cut -f1 | xargs echo "tamaño entorno:"
echo "--- compile CALIENTE ---"; rm -f reqs.txt; { time ./.venv-pip/bin/pip-compile -q --no-strip-extras -o reqs.txt reqs.in ; } 2>&1 | grep real
echo "--- recrear entorno CALIENTE ---"
rm -rf .venv-pip2
{ time ( /opt/homebrew/bin/python3.14 -m venv .venv-pip2 && ./.venv-pip2/bin/python -m pip install -q --disable-pip-version-check -r reqs.txt ) ; } 2>&1 | grep real
grep -c '==' reqs.txt | xargs echo "paquetes en el lock:"
du -sh "$PIP_CACHE_DIR" | cut -f1 | xargs echo "caché:"
