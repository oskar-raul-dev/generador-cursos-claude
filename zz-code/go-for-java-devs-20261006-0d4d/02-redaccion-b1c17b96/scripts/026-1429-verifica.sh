# rescatado de la sesión b1c17b96, 2026-09-12T14:29:55Z · Full revalidation after edits
cd /Users/oskar/Developer/Learning/courses-ia-generated/go-for-java-devs
echo "=== 1. Secciones: 10 en orden ==="
bad=0; for f in [01][0-9]-*.md; do [ "$f" = "00-convencion-de-git-y-tags.md" ] && continue
  s=$(grep -oE '^## [^ ]+ ([0-9]+)\.' "$f" | grep -oE '[0-9]+' | tr '\n' ' ')
  [ "$s" = "1 2 3 4 5 6 7 8 9 10 " ] || { echo "MAL $f: $s"; bad=1; }; done
[ $bad -eq 0 ] && echo "OK 18/18"
echo
echo "=== 2. Obligatorias 🪞 🩻 📖 ⚖️ 🧨 ==="
bad=0; for f in [01][0-9]-*.md; do [ "$f" = "00-convencion-de-git-y-tags.md" ] && continue
  for m in '🪞 Tu instinto' '🩻 Esto sí funciona igual' '📖 Diccionario' '🧨' '### 🔴 Desafíos de cierre' '## 📚 9. Referencias' 'Orden de lectura sugerido'; do
    grep -q "$m" "$f" || { echo "FALTA [$m] en $f"; bad=1; }; done; done
[ $bad -eq 0 ] && echo "OK 18/18"
echo
echo "=== 3. Vallas de codigo pares ==="
bad=0; for f in *.md; do n=$(grep -c '^```' "$f"); [ $((n%2)) -ne 0 ] && { echo "IMPAR $f"; bad=1; }; done
[ $bad -eq 0 ] && echo "OK"
echo
echo "=== 4. Enlaces a archivos ==="
grep -ohE '\]\(([0-9A-Za-z._/-]+\.md)\)' *.md | tr -d '()]' | sed 's/^\[//' | sort -u | while read p; do [ -e "$p" ] || echo "ROTO $p"; done
echo "OK si vacio"
