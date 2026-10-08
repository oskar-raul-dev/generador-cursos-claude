# rescatado de la sesión b1c17b96, 2026-09-12T14:16:48Z · Inspect context of debt markers
cd /Users/oskar/Developer/Learning/courses-ia-generated/go-for-java-devs
for spec in "02-structs-interfaces-composicion.md:62" "02-structs-interfaces-composicion.md:1318" "02-structs-interfaces-composicion.md:1438" "03-errores-paquetes-io.md:62" "05-http-rest-stdlib.md:485" "05-http-rest-stdlib.md:541" "06-concurrencia.md:69" "06-concurrencia.md:1012"; do
  f=${spec%:*}; l=${spec#*:}
  echo "───── $spec"; sed -n "$((l-3)),$((l+1))p" "$f"; echo
done
