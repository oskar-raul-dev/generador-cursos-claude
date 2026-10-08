# rescatado de la sesión b1c17b96, 2026-09-12T14:15:03Z · Check section numbering per phase
cd /Users/oskar/Developer/Learning/courses-ia-generated/go-for-java-devs
echo "=== SECCIONES POR FASE (deben ser 10, en orden) ==="
for f in [01][0-9]-*.md; do
  printf "%-40s " "$f"
  grep -oE '^## [^ ]+ ([0-9]+)\.' "$f" | grep -oE '[0-9]+\.' | tr -d '.' | tr '\n' ' '
  echo
done
