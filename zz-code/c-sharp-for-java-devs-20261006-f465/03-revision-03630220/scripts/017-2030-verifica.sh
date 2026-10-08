# rescatado de la sesión 03630220, 2026-09-13T20:30:30Z · New-angle checks: markers, sections, tracks, citations
echo "── A. Secciones narrativas obligatorias (guía §7.3) ──"
for f in $(ls [0-9][0-9]-*.md|grep -vE 'convencion|historia'); do
  m=""; grep -q "🪞" $f || m="$m 🪞"; grep -q "🩻" $f || m="$m 🩻"; grep -q "📖" $f || m="$m 📖"
  [ -n "$m" ] && echo "  $f falta:$m"
done; echo "  (vacío = las cuatro presentes donde toca)"
echo
echo "── B. Marcadores declarados en la guía vs usados ──"
grep -oE "^\| ([🪞🩻📖⚖️💸📏🧱🧬📌🔜⏳🪦💲🧪🧭📝⚠️💡🧠])" prompts/guia-de-estilo-y-convenciones.md | sort -u | head
for k in 🪞 🩻 📖 ⚖️ 💸 📏 🧱 🧬 📌 🔜 ⏳ 🪦 💲; do printf "  %s  fases=%s\n" "$k" "$(grep -l "$k" $(ls [0-9][0-9]-*.md|grep -vE 'convencion|historia') 2>/dev/null | wc -l | tr -d ' ')"; done
echo
echo "── C. Tracks opcionales ──"
grep -rhoE '`(ui|ar|au|db|cv)`' *.md | sort | uniq -c
echo
echo "── D. §2.6 citado por cuántos documentos ──"
grep -rl "§2\.6" *.md | wc -l | xargs echo "  documentos publicados que lo citan:"
grep -rn "veinticinco documentos publicados" prompts/*.md BENCHMARKS.md | sed 's/\(.\{130\}\).*/\1/'
