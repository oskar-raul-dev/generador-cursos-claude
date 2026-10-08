# rescatado de la sesión b1c17b96, 2026-09-12T14:18:22Z · Check code fences and next-phase chain
cd /Users/oskar/Developer/Learning/courses-ia-generated/go-for-java-devs
echo "=== BLOQUES DE CÓDIGO SIN CERRAR (nº impar de ``` por archivo) ==="
for f in *.md; do
  n=$(grep -c '^```' "$f")
  [ $((n % 2)) -ne 0 ] && echo "⚠️  $f: $n vallas (impar)"
done
echo "(sin salida = todos cerrados)"
echo
echo "=== CADENA 'Qué sigue' → ¿menciona la fase siguiente? ==="
for i in $(seq -w 0 16); do
  f=$(ls ${i}-*.md 2>/dev/null | grep -v convencion | head -1); [ -z "$f" ] && continue
  nxt=$(printf "%02d" $((10#$i + 1)))
  if sed -n '/^### Qué sigue/,/^### La señal/p' "$f" | grep -qE "Fase $nxt|Fase ${nxt#0}"; then
    echo "✅ $f → Fase $nxt"
  else
    echo "⚠️  $f NO menciona la Fase $nxt en 'Qué sigue'"
  fi
done
