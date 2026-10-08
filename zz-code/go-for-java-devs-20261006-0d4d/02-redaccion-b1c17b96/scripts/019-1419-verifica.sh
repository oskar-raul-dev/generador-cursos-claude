# rescatado de la sesión b1c17b96, 2026-09-12T14:19:20Z · Map cross-phase references
cd /Users/oskar/Developer/Learning/courses-ia-generated/go-for-java-devs
echo "=== REFERENCIAS CRUZADAS: 'Fase NN' citada desde cada archivo ==="
for f in [01][0-9]-*.md; do
  [ "$f" = "00-convencion-de-git-y-tags.md" ] && continue
  own=$(echo "$f" | grep -oE '^[0-9]+')
  refs=$(grep -ohE 'Fase [0-9]{2}' "$f" | grep -oE '[0-9]{2}' | sort -un | tr '\n' ' ')
  printf "%-38s propia=%s  cita: %s\n" "$f" "$own" "$refs"
done
