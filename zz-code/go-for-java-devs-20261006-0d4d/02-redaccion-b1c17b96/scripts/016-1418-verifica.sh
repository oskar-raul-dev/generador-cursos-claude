# rescatado de la sesión b1c17b96, 2026-09-12T14:18:39Z · Check next-phase chain
cd /Users/oskar/Developer/Learning/courses-ia-generated/go-for-java-devs
echo "=== CADENA 'Que sigue' -> menciona la fase siguiente ==="
for i in 00 01 02 03 04 05 06 07 08 09 10 11 12 13 14 15 16; do
  f=$(ls ${i}-*.md 2>/dev/null | grep -v convencion | head -1)
  [ -z "$f" ] && continue
  nxt=$(printf "%02d" $((10#$i + 1)))
  nxts=$((10#$i + 1))
  if sed -n '/^### Qué sigue/,/^### La señal/p' "$f" | grep -qE "Fase ${nxt}|Fase ${nxts}"; then
    echo "OK   $f -> Fase $nxt"
  else
    echo "FALTA $f no menciona Fase $nxt"
  fi
done
