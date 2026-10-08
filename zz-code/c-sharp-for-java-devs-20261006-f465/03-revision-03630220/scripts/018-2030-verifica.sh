# rescatado de la sesión 03630220, 2026-09-13T20:30:40Z · Inspect marker outliers
echo "-- fases sin 💸 --"; for f in $(ls [0-9][0-9]-*.md|grep -vE 'convencion|historia'); do grep -q "💸" $f || echo "  $f"; done
echo "-- fases con 🔜 --"; grep -l "🔜" $(ls [0-9][0-9]-*.md|grep -vE 'convencion|historia')
echo "-- 🔜 en BENCHMARKS --"; grep -c "🔜" BENCHMARKS.md | xargs echo "  ocurrencias:"; grep -n "🔜" BENCHMARKS.md | sed 's/\(.\{125\}\).*/\1/'
