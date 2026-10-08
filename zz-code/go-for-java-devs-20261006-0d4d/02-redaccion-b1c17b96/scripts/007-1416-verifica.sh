# rescatado de la sesión b1c17b96, 2026-09-12T14:16:35Z · Check every debt marker declares its paying phase
cd /Users/oskar/Developer/Learning/courses-ia-generated/go-for-java-devs
echo "=== 💸 DEUDAS: cada una debe declarar su fase de cobro ==="
for f in [01][0-9]-*.md; do
  grep -n '💸' "$f" | grep -viE 'fase [0-9]+|se paga|pagada|pagar|deuda del|deudas|inventario|sin pagar' | sed "s|^|$f:|"
done
echo "(sin salida = todas declaran destino en la misma línea)"
