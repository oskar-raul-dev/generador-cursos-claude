# rescatado de la sesión b1c17b96, 2026-09-12T14:20:35Z · Locate insertion point and verify reading order sections
cd /Users/oskar/Developer/Learning/courses-ia-generated/go-for-java-devs
echo "=== Lo que precede a la sección 9 en cada fase ==="
for f in [01][0-9]-*.md; do
  [ "$f" = "00-convencion-de-git-y-tags.md" ] && continue
  printf "%-38s " "$f"
  grep -n '^## 📚 9\. Referencias' "$f" | cut -d: -f1 | while read l; do sed -n "$((l-4))p" "$f"; done
done
echo
echo "=== ¿Todas tienen 'Orden de lectura sugerido' en §9? ==="
for f in [01][0-9]-*.md; do
  [ "$f" = "00-convencion-de-git-y-tags.md" ] && continue
  grep -q 'Orden de lectura sugerido' "$f" && echo "OK   $f" || echo "FALTA $f"
done
