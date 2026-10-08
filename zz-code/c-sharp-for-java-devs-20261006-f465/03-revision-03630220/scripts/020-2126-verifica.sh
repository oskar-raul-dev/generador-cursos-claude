# rescatado de la sesión 03630220, 2026-09-13T21:26:55Z · Final checks and full battery
echo "── I. §6: ¿alguna celda con número en vez de ⏳? ──"
for f in $(ls [0-9][0-9]-*.md|grep -vE 'convencion|historia'); do
  awk '/^## 📏 6\./{f=1;next}/^## 🧱 7\./{f=0}f' $f | grep -E "^\|" | grep -vE "⏳|🔜|💲|---|Criterio|Opción|Pregunta|Métrica|^\| *\*\*" | grep -E "\| *[0-9]+([.,][0-9]+)? *(ms|s|MB|KB|%)" | sed "s|^|  $f: |"
done; echo "  (vacío = ninguna cifra inventada en una tabla de medición)"
echo
echo "── J. §2 de cada fase declara avance de proyecto ──"
n=0; for f in $(ls [0-9][0-9]-*.md|grep -vE 'convencion|historia'); do grep -q "^> Proyecto que avanza:" $f || { echo "  ❌ $f"; n=1; }; done; [ $n = 0 ] && echo "  ✅ las 25"
echo
echo "── K. Batería completa ──"
b=0
grep -rqnE "CLAUDE\.md|cursos-[a-z]|curso(s)? hermano|curso de (Go|Python|Angular|React|Rust|Node)|otros cursos del|python-for-java|propuestas-cursos|_oskar" . --include="*.md" && { echo "  ❌ refs externas"; b=1; } || echo "  ✅ cero referencias a otros cursos"
n=0; for f in *.md; do for l in $(grep -ohE "\]\(([^)h][^)]*)\)" "$f"|sed -E 's/^\]\(//;s/\)$//;s/#.*//'); do [ -e "$l" ]||n=1; done; done; for f in prompts/*.md; do for l in $(grep -ohE "\]\(([^)h][^)]*)\)" "$f"|sed -E 's/^\]\(//;s/\)$//;s/#.*//'); do [ -e "prompts/$l" ]||n=1; done; done; [ $n = 0 ] && echo "  ✅ enlaces" || { echo "  ❌ enlaces"; b=1; }
[ $b = 0 ] && echo && echo "════ TODO EN VERDE ════"
