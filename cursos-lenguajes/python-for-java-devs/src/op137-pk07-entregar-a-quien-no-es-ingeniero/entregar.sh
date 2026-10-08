set -euo pipefail
median_ms() { for _ in 1 2 3 4 5; do s=$(date +%s%N); "$@" >/dev/null; echo $(( ($(date +%s%N) - s) / 1000000 )); done | sort -n | sed -n 3p; }

python3 -m zipapp regalias -m regalias:main -o regalias-zipapp.pyz
python3 regalias-zipapp.pyz 2>&1 | tail -1 | cut -c1-60 || true

shiv -q -o regalias-shiv.pyz -e regalias:main --site-packages regalias httpx orjson 2>/dev/null
pex httpx orjson -D regalias -e regalias:main -o regalias.pex >/dev/null 2>&1

for f in regalias-shiv.pyz regalias.pex; do
  python3 "$f" >/dev/null                                          # primera ejecución: desempaqueta
  printf '%-18s %6s KB · arranque %4s ms · %s\n' "$f" "$(( $(stat -c %s "$f") / 1024 ))" "$(median_ms python3 "$f")" "$(python3 "$f")"
done

rm -rf ~/.cache/uv
s=$(date +%s%N); uv run --quiet regalias_pep723.py >/dev/null; first=$(( ($(date +%s%N) - s) / 1000000 ))
printf '%-18s primera vez %5s ms (descarga) · después %4s ms\n' "PEP 723 (uv run)" "$first" "$(median_ms uv run --quiet regalias_pep723.py)"
unzip -l regalias.pex | grep -o 'orjson[^/]*\.whl\|orjson-[^/]*/orjson[^/]*\.so' | head -1
