#!/usr/bin/env bash
# =============================================================================
#  verificar-corpus.sh — los siete controles que se corren antes de cerrar una tanda.
#  Los cuatro primeros viven aquí; los de texto (5 anclas, 6 ancho, 7 sincronía
#  literal), en prompts/controles-texto.py, que este guion llama al final.
#
#    bash prompts/verificar-corpus.sh          # desde la raíz del corpus
#
#  Sale con codigo 1 si algo falla, para poder encadenarlo.
#  `prompts/` queda fuera de todos: la guia nombra a su guia madre a proposito
#  (§1.1).
# =============================================================================
set -uo pipefail
cd "$(dirname "$0")/.." || exit 1

fallos=0
docs() { find . -name '*.md' -not -path './prompts/*' -not -path './node_modules/*'; }

# --- 1. Enlaces internos -----------------------------------------------------
echo "== 1. Enlaces internos =="
while IFS= read -r doc; do
  dir=$(dirname "$doc")
  # Captura el destino de cada enlace markdown, sin ancla y sin URL externa.
  grep -o '](\([^)]*\.md\)[^)]*)' "$doc" 2>/dev/null |
    sed 's/^](//; s/#.*//; s/)$//' | sort -u |
  while IFS= read -r destino; do
    [ -z "$destino" ] && continue
    case "$destino" in http*|mailto:*) continue;; esac
    [ -e "$dir/$destino" ] || echo "  ROTO  $doc  ->  $destino"
  done
done < <(docs) | tee /tmp/bd-enlaces.txt
[ -s /tmp/bd-enlaces.txt ] && fallos=$((fallos+1)) || echo "  (ninguno)"

# --- 2. Autocontenido --------------------------------------------------------
echo "== 2. Autocontenido =="
fuera=$(grep -rn '](\.\./\.\./' --include='*.md' . | grep -v 'prompts/')
otros=$(grep -rn 'repaso-\(aws\|gcp\|spring\|arquitectura\|bases\|microservicios\|apis\)\|preguntas-entrevista' \
        --include='*.md' . | grep -v 'prompts/')
if [ -n "$fuera$otros" ]; then
  printf '%s\n' "$fuera" "$otros" | grep -v '^$' | sed 's/^/  FUERA  /'
  fallos=$((fallos+1))
else
  echo "  (ninguno)"
fi

# --- 3. Preguntas contra solucionario ---------------------------------------
echo "== 3. Preguntas contra solucionario =="
for bloque in [0-9][0-9]-*/; do
  [ -d "$bloque" ] || continue
  suma=0
  for f in "$bloque"[0-9][0-9]-*.md "$bloque"l[0-9][0-9]-*.md; do
    [ -e "$f" ] || continue
    case "$f" in *respuestas*) continue;; esac
    n=$(sed -n '/^## 🧠 Preguntas/,$p' "$f" | grep -cE '^[0-9]+\. ')
    suma=$((suma+n))
  done
  sol=$(cat "$bloque"*-respuestas.md 2>/dev/null | grep -cE '^\*\*[0-9]{2} → [0-9]+\.' )
  sol=${sol:-0}
  if [ "$suma" -eq 0 ] && [ "$sol" -eq 0 ]; then
    printf '  %-42s sin preguntas todavía\n' "$bloque"
  elif [ "$suma" -eq "$sol" ]; then
    printf '  %-42s %4d preguntas = %4d respuestas  OK\n' "$bloque" "$suma" "$sol"
  else
    printf '  %-42s %4d preguntas ≠ %4d respuestas  DESINCRONIZADO\n' "$bloque" "$suma" "$sol"
    fallos=$((fallos+1))
  fi
done

# --- 4. Simulacion contra solucionario -------------------------------------
echo "== 4. Simulacion contra solucionario =="
for bloque in [0-9][0-9]-*/; do
  sim=$(ls "$bloque"*-simulacion-de-entrevista.md 2>/dev/null | head -1)
  [ -n "$sim" ] || continue
  nsim=$(grep -cE '^\*\*S[0-9]+\.\*\*' "$sim")
  nesc=$(grep -cE '^### Escenario [0-9]+' "$sim")
  nn=$(basename "$sim" | cut -c1-2)
  nres=$(cat "$bloque"*-respuestas.md 2>/dev/null | grep -cE "^\*\*$nn . S[0-9]+\.")
  neres=$(cat "$bloque"*-respuestas.md 2>/dev/null | grep -cE "^\*\*$nn . E[0-9]+\.")
  if [ "$nsim" -eq "$nres" ] && [ "$nesc" -eq "$neres" ]; then
    printf '  %-42s %3d S# = %3d  ·  %d escenarios = %d  OK\n' "$bloque" "$nsim" "$nres" "$nesc" "$neres"
  else
    printf '  %-42s %3d S# vs %3d  ·  %d escenarios vs %d  DESINCRONIZADO\n' "$bloque" "$nsim" "$nres" "$nesc" "$neres"
    fallos=$((fallos+1))
  fi
done

# --- 5, 6 y 7. Anclas, ancho y sincronía literal ----------------------------
python3 prompts/controles-texto.py || fallos=$((fallos+1))

echo
[ "$fallos" -eq 0 ] && { echo "Los siete controles limpios."; exit 0; }
echo "$fallos control(es) con fallos."; exit 1
