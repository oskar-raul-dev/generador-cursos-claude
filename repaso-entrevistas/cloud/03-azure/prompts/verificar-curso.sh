#!/usr/bin/env bash
# Verificaciones globales del curso: enlaces, preguntas ↔ solucionario, anclas y URLs. Se corre con bash desde
# 03-azure/: en zsh, los globs sin coincidencia abortan.
set -u
cd "$(dirname "$0")/.."

echo "== 6.1 enlaces internos"
rg -o '\]\([0-9al][^)#]*\.md' *.md | sed 's/.*](//' | sort -u | while read -r f; do
  [ -f "$f" ] || echo "ROTO: $f"
done

echo "== 6.2 y 6.3 preguntas ↔ solucionario"
for f in [0-9][0-9]-*.md l[0-9][0-9]-*.md a[0-9][0-9]-*.md; do
  [ -f "$f" ] || continue
  case "$f" in 18-*|19-*) continue;; esac
  id=$(echo "$f" | cut -d- -f1 | tr '[:lower:]' '[:upper:]')
  n=$(awk '/^## 🧠 Preguntas rápidas/{on=1;next} /^## /{on=0} on && /^[0-9]+\. /{c++} END{print c+0}' "$f")
  m=$(awk -v id="$id" '$0 ~ "^## "id" — "{on=1;next} /^# |^## /{on=0} on && /^[0-9]+\. \*\*/{c++} END{print c+0}' 19-respuestas.md)
  [ "$n" = "$m" ] && echo "$f: $n/$m" || echo "DESCUADRE $f: $n preguntas, $m respuestas"
  awk '/^## 🧠 Preguntas rápidas/{on=1;next} /^## /{on=0} on && /^[0-9]+\. /{sub(/^[0-9]+\. /,""); print}' "$f" |
  while IFS= read -r q; do grep -qF "**$q**" 19-respuestas.md || echo "NO LITERAL $f: $q"; done
done

echo "== P# de 18 ↔ solucionario"
if [ -f 18-preguntas-entrevista-y-mapa-mental.md ]; then
  n=$(grep -c '^- \*\*P[0-9]*\.\*\* ' 18-preguntas-entrevista-y-mapa-mental.md)
  m=$(grep -c '^- \*\*P[0-9]*\. ' 19-respuestas.md)
  [ "$n" = "$m" ] && echo "18: $n/$m" || echo "DESCUADRE 18: $n preguntas, $m respuestas"
  sed -n 's/^- \*\*\(P[0-9]*\)\.\*\* \(.*\)$/**\1. \2**/p' 18-preguntas-entrevista-y-mapa-mental.md |
  while IFS= read -r q; do grep -qF -- "$q" 19-respuestas.md || echo "NO LITERAL 18: $q"; done
fi

echo "== anclas"
python3 prompts/verificar-anclas.py

echo "== 6.4 URLs externas (código y redirecciones)"
rg -o --no-filename 'https://[^) >`]+' *.md | sort -u \
  | rg -v '…|management\.azure\.com|\.core\.windows\.net|prices\.azure\.com|login\.microsoftonline\.com|\.documents\.azure\.com|\.vault\.azure\.net|\.azurecr\.io|storage\.azure\.com|aka\.ms/devicelogin|microsoft\.com/devicelogin|graph\.microsoft\.com/v1\.0/|github\.com/microsoft/ApplicationInsights-Java/releases/download|token\.actions\.githubusercontent\.com|<|\$|maven\.apache\.org/xsd' \
  | while read -r u; do
      r=$(curl -4 -sL -m 30 -o /dev/null -w '%{http_code} %{url_effective}' "$u")
      code=${r%% *}; eff=${r#* }; base="${u%%#*}"; e2="${eff%%\?*}"
      [ "$code" = "200" ] || echo "$code $u"
      [ "$code" != "200" ] || [ "$base" = "$e2" ] || echo "REDIRIGE: $u -> $eff"
    done
echo "== fin"
