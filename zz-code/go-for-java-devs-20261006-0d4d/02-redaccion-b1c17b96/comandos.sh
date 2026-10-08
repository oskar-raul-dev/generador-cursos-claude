# Comandos Bash de la sesión b1c17b96-6d1e-4b11-8dfe-ad530444b436, en orden. Una bitácora, no un script: no se corre entera.

# --- 2026-09-12T03:37:55 · List course files and line counts
cd /Users/oskar/Developer/Learning/courses-ia-generated/go-for-java-devs && find . -type f | sort && echo "---SIZES---" && wc -l $(find . -type f -name '*.md' | sort)

# --- 2026-09-12T03:38:01 · Read README and scope
cat README.md && echo "=====ALCANCE=====" && cat prompts/alcance-del-proyecto.md

# --- 2026-09-12T03:38:05 · Read phase proposal
cd /Users/oskar/Developer/Learning/courses-ia-generated/go-for-java-devs/prompts && cat propuesta-fases-y-alcance.md

# --- 2026-09-12T03:38:09 · Read phase table
sed -n '40,300p' propuesta-fases-y-alcance.md

# --- 2026-09-12T03:38:11 · Read rest of phase proposal
sed -n '300,681p' propuesta-fases-y-alcance.md

# --- 2026-09-12T03:38:15 · Read style guide
cat guia-de-estilo-y-convenciones.md

# --- 2026-09-12T03:38:17 · Read style guide part 2
sed -n '45,400p' guia-de-estilo-y-convenciones.md

# --- 2026-09-12T03:38:20 · Read style guide part 3
sed -n '400,705p' guia-de-estilo-y-convenciones.md

# --- 2026-09-12T03:38:24 · Read extended prompts head and headings
head -120 prompts-extendidos-fases.md; echo "...[GREP HEADINGS]..."; grep -n '^#' prompts-extendidos-fases.md

# --- 2026-09-12T03:38:27 · Read phase block sample and final section
sed -n '118,215p' prompts-extendidos-fases.md; echo "=====FINAL====="; sed -n '960,976p' prompts-extendidos-fases.md

# --- 2026-09-12T03:38:30 · Read benchmark format and templates
cat formato-de-benchmarks.md; echo "==========PLANTILLAS=========="; head -80 plantillas-de-capitulo.md; echo "...."; grep -n '^#\{1,3\} ' plantillas-de-capitulo.md

# --- 2026-09-12T03:38:35 · Read project docs
for f in proyecto-01-opsreport.md proyecto-02-eventrelay.md proyecto-03-atlassync.md proyecto-04-clearinghouse.md; do echo "=========== $f"; sed -n '1,60p' $f; echo "   --- headings:"; grep -n '^#\{1,3\} ' $f; done

# --- 2026-09-12T06:03:24 · Count lines of all course documents
cd /Users/oskar/Developer/Learning/courses-ia-generated/go-for-java-devs && wc -l *.md | sort -k2 && echo "---" && wc -l *.md | tail -1

# --- 2026-09-12T14:15:03 · Check section numbering per phase
cd /Users/oskar/Developer/Learning/courses-ia-generated/go-for-java-devs
echo "=== SECCIONES POR FASE (deben ser 10, en orden) ==="
for f in [01][0-9]-*.md; do
  printf "%-40s " "$f"
  grep -oE '^## [^ ]+ ([0-9]+)\.' "$f" | grep -oE '[0-9]+\.' | tr -d '.' | tr '\n' ' '
  echo
done

# --- 2026-09-12T14:15:30 · Verify exercise counts vs declared
cd /Users/oskar/Developer/Learning/courses-ia-generated/go-for-java-devs
echo "=== EJERCICIOS: declarado vs numerado vs rangos ==="
printf "%-38s %-10s %-8s %s\n" ARCHIVO DECLARADO NUMERADO RANGOS
for f in [01][0-9]-*.md; do
  [ "$f" = "00-convencion-de-git-y-tags.md" ] && continue
  decl=$(grep -oE '^## 🧪 8\. Ejercicios \(([0-9]+)\)' "$f" | grep -oE '[0-9]+\)' | tr -d ')')
  # contar items numerados entre la sección 8 y la 9
  n=$(awk '/^## 🧪 8\. Ejercicios/,/^## 📚 9\./' "$f" | grep -cE '^[0-9]+\. ')
  rangos=$(awk '/^## 🧪 8\. Ejercicios/,/^## 📚 9\./' "$f" | grep -oE '\*\*(🟢|🟡|🟠|🔴) [^(]+\(([0-9]+–[0-9]+)\)' | grep -oE '\([0-9]+–[0-9]+\)' | tr '\n' ' ')
  printf "%-38s %-10s %-8s %s\n" "$f" "$decl" "$n" "$rangos"
done

# --- 2026-09-12T14:15:43 · Check mandatory sections present
cd /Users/oskar/Developer/Learning/courses-ia-generated/go-for-java-devs
echo "=== SECCIONES OBLIGATORIAS ==="
printf "%-38s %-4s %-4s %-4s %-4s %-4s %-4s %-4s %-4s\n" ARCHIVO 🪞 🩻 🧨 ⚰️ 📖 ⚖️ 🏷️ 📌
for f in [01][0-9]-*.md; do
  [ "$f" = "00-convencion-de-git-y-tags.md" ] && continue
  a=$(grep -c '🪞' "$f"); b=$(grep -c '🩻' "$f"); c=$(grep -c '🧨 Rompe a propósito\|🧨 \*\*Rompe' "$f")
  d=$(grep -c '⚰️ Autopsia' "$f"); e=$(grep -c '📖 Diccionario' "$f"); g=$(grep -c '⚖️ Cuándo NO\|⚖️ El veredicto honesto' "$f")
  h=$(grep -c 'git tag -a fase-' "$f"); i=$(grep -c '📌 Bloque de autoría' "$f")
  printf "%-38s %-4s %-4s %-4s %-4s %-4s %-4s %-4s %-4s\n" "$f" "$a" "$b" "$c" "$d" "$e" "$g" "$h" "$i"
done

# --- 2026-09-12T14:15:58 · Inspect phase 17 dictionary and phase 15 missing section
cd /Users/oskar/Developer/Learning/courses-ia-generated/go-for-java-devs
echo "--- Fase 17: cómo se llama su diccionario ---"; grep -n '📖' 17-capstone.md | head
echo; echo "--- Fase 15: busca 'funciona igual' ---"; grep -n 'funciona igual\|🩻' 15-rendimiento-y-profiling.md | head
echo; echo "--- Encabezados de §4 en la fase 15 ---"; sed -n '/^## 🧠 4\./,/^## 🛠️ 5\./p' 15-rendimiento-y-profiling.md | grep -n '^###'

# --- 2026-09-12T14:16:13 · Check file links and benchmark ID coherence
cd /Users/oskar/Developer/Learning/courses-ia-generated/go-for-java-devs
echo "=== ENLACES A ARCHIVOS: ¿existen? ==="
grep -ohE '\]\(([0-9A-Za-z._/-]+\.md)\)' *.md | grep -oE '\(.*\)' | tr -d '()' | sort -u | while read -r p; do
  [ -e "$p" ] || echo "❌ ROTO: $p"
done
echo "(sin salida = todos existen)"
echo
echo "=== IDs de benchmark citados en las fases vs definidos en BENCHMARKS.md ==="
cited=$(grep -ohE '\bB-[0-9]{2}\b' [01][0-9]-*.md | sort -u)
defined=$(grep -oE '^## B-[0-9]{2}' BENCHMARKS.md | grep -oE 'B-[0-9]{2}' | sort -u)
echo "citados:   $(echo $cited | tr '\n' ' ')"
echo "definidos: $(echo $defined | tr '\n' ' ')"
echo "--- citados y NO definidos:"; comm -23 <(echo "$cited") <(echo "$defined")
echo "--- definidos y NO citados:"; comm -13 <(echo "$cited") <(echo "$defined")

# --- 2026-09-12T14:16:25 · Verify proposed benchmark IDs only in authorship blocks
cd /Users/oskar/Developer/Learning/courses-ia-generated/go-for-java-devs
echo "=== ¿Dónde aparecen B-25..B-31? (deben estar SOLO en bloques 📌 de autoría) ==="
for f in [01][0-9]-*.md; do
  line=$(grep -nE '\bB-(2[5-9]|3[01])\b' "$f" | cut -d: -f1)
  [ -z "$line" ] && continue
  autoria=$(grep -n '📌 Bloque de autoría' "$f" | cut -d: -f1)
  for l in $line; do
    if [ "$l" -lt "${autoria:-999999}" ]; then echo "⚠️  $f:$l está ANTES del bloque de autoría"; else echo "✅ $f:$l en autoría"; fi
  done
done

# --- 2026-09-12T14:16:35 · Check every debt marker declares its paying phase
cd /Users/oskar/Developer/Learning/courses-ia-generated/go-for-java-devs
echo "=== 💸 DEUDAS: cada una debe declarar su fase de cobro ==="
for f in [01][0-9]-*.md; do
  grep -n '💸' "$f" | grep -viE 'fase [0-9]+|se paga|pagada|pagar|deuda del|deudas|inventario|sin pagar' | sed "s|^|$f:|"
done
echo "(sin salida = todas declaran destino en la misma línea)"

# --- 2026-09-12T14:16:48 · Inspect context of debt markers
cd /Users/oskar/Developer/Learning/courses-ia-generated/go-for-java-devs
for spec in "02-structs-interfaces-composicion.md:62" "02-structs-interfaces-composicion.md:1318" "02-structs-interfaces-composicion.md:1438" "03-errores-paquetes-io.md:62" "05-http-rest-stdlib.md:485" "05-http-rest-stdlib.md:541" "06-concurrencia.md:69" "06-concurrencia.md:1012"; do
  f=${spec%:*}; l=${spec#*:}
  echo "───── $spec"; sed -n "$((l-3)),$((l+1))p" "$f"; echo
done

# --- 2026-09-12T14:17:04 · Check epoch discipline in Bloque A
cd /Users/oskar/Developer/Learning/courses-ia-generated/go-for-java-devs
echo "=== DISCIPLINA DE ÉPOCA: APIs post-1.13 en fases 00-07 ==="
for f in 0[0-7]-*.md; do
  [ "$f" = "00-convencion-de-git-y-tags.md" ] && continue
  hits=$(grep -nE 'os\.ReadFile|os\.WriteFile|io\.ReadAll|os\.CreateTemp|log/slog|slog\.|slices\.|maps\.|errors\.Join|go\.work|any\)|\[T any\]|testing\.F|t\.Setenv|WithoutCancel|b\.Loop|iter\.Seq|min\(|max\(|PathValue|r\.Pattern|signal\.NotifyContext' "$f" | grep -vE '🕰️|Fase 0[89]|Fase 1[0-7]|no entra|NO entra|prohibi|1\.1[4-9]|1\.2[0-9]|moderno|comparación')
  if [ -n "$hits" ]; then echo "── $f"; echo "$hits" | head -12; echo; fi
done
echo "(revisar manualmente los que salgan)"

# --- 2026-09-12T14:17:21 · Verify hours and phase numbering coherence
cd /Users/oskar/Developer/Learning/courses-ia-generated/go-for-java-devs
echo "=== CABECERA DE CADA FASE: horas y 'Fase N de 17' ==="
for f in [01][0-9]-*.md; do
  [ "$f" = "00-convencion-de-git-y-tags.md" ] && continue
  printf "%-38s " "$f"; sed -n '3p' "$f"
done
echo
echo "=== ¿La tabla de 0-ESTRUCTURA coincide en horas? ==="
grep -oE '\| [0-9]+ \| [0-9]+ \|' 0-ESTRUCTURA-CURSO.md | head -20
echo
echo "=== suma de horas declaradas en las cabeceras ==="
grep -h '^> Go para desarrolladores' [01][0-9]-*.md | grep -oE '\*\*[0-9]+ horas?\*\*' | grep -oE '[0-9]+' | paste -sd+ | bc

# --- 2026-09-12T14:17:36 · Count mini projects and check README figures
cd /Users/oskar/Developer/Learning/courses-ia-generated/go-for-java-devs
echo "=== MINI PROYECTOS declarados en las cabeceras ==="
grep -h '^> Mini proyectos:' [01][0-9]-*.md | sed 's/^> Mini proyectos: //' | tr ',' '\n' | grep -oE '`[a-z-]+`' | tr -d '`' | sort -u | tee /tmp/labs.txt | tr '\n' ' '
echo; echo "TOTAL ÚNICOS: $(wc -l < /tmp/labs.txt)"
echo
echo "=== ¿coinciden con la tabla de 0-ESTRUCTURA §5? ==="
grep -oE '`[a-z-]+`' 0-ESTRUCTURA-CURSO.md | tr -d '`' | sort -u > /tmp/est.txt
comm -23 /tmp/labs.txt /tmp/est.txt | sed 's/^/en fases y NO en estructura: /'
echo
echo "=== README: cifras ==="; grep -nE '131|dieciocho|18 fases|veintiocho|treinta y tres' README.md

# --- 2026-09-12T14:17:49 · Compare mini projects against source prompts
cd /Users/oskar/Developer/Learning/courses-ia-generated/go-for-java-devs
echo "=== Mini proyectos declarados en prompts-extendidos-fases.md ==="
grep -A1 '^- Mini proyectos' prompts/prompts-extendidos-fases.md | grep -oE '`[a-z-]+`' | tr -d '`' | sort -u > /tmp/prompt.txt
wc -l < /tmp/prompt.txt
echo "--- en mis fases y NO en los prompts:"; comm -23 /tmp/labs.txt /tmp/prompt.txt
echo "--- en los prompts y NO en mis fases:"; comm -13 /tmp/labs.txt /tmp/prompt.txt

# --- 2026-09-12T14:18:05 · Locate the 28 vs 46 discrepancy
cd /Users/oskar/Developer/Learning/courses-ia-generated/go-for-java-devs
echo "=== Mini proyectos nombrados en propuesta-fases-y-alcance.md §3 ==="
grep -oE '`[a-z][a-z-]+`' prompts/propuesta-fases-y-alcance.md | tr -d '`' | sort -u | comm -12 - /tmp/prompt.txt | tr '\n' ' '
echo; echo "conteo: $(grep -oE '`[a-z][a-z-]+`' prompts/propuesta-fases-y-alcance.md | tr -d '`' | sort -u | comm -12 - /tmp/prompt.txt | wc -l)"
echo
echo "=== dónde se afirma 'veintiocho' ==="
grep -rn 'veintiocho\|28 mini\|28 mini proyectos' README.md 0-ESTRUCTURA-CURSO.md prompts/*.md

# --- 2026-09-12T14:18:22 · Check code fences and next-phase chain
cd /Users/oskar/Developer/Learning/courses-ia-generated/go-for-java-devs
echo "=== BLOQUES DE CÓDIGO SIN CERRAR (nº impar de ``` por archivo) ==="
for f in *.md; do
  n=$(grep -c '^```' "$f")
  [ $((n % 2)) -ne 0 ] && echo "⚠️  $f: $n vallas (impar)"
done
echo "(sin salida = todos cerrados)"
echo
echo "=== CADENA 'Qué sigue' → ¿menciona la fase siguiente? ==="
for i in $(seq -w 0 16); do
  f=$(ls ${i}-*.md 2>/dev/null | grep -v convencion | head -1); [ -z "$f" ] && continue
  nxt=$(printf "%02d" $((10#$i + 1)))
  if sed -n '/^### Qué sigue/,/^### La señal/p' "$f" | grep -qE "Fase $nxt|Fase ${nxt#0}"; then
    echo "✅ $f → Fase $nxt"
  else
    echo "⚠️  $f NO menciona la Fase $nxt en 'Qué sigue'"
  fi
done

# --- 2026-09-12T14:18:30 · Check unclosed code fences
cd /Users/oskar/Developer/Learning/courses-ia-generated/go-for-java-devs
echo "=== BLOQUES DE CODIGO SIN CERRAR ==="
for f in *.md; do
  n=$(grep -c '^```' "$f")
  if [ $((n % 2)) -ne 0 ]; then echo "IMPAR $f: $n"; fi
done
echo "(vacio = ok)"

# --- 2026-09-12T14:18:39 · Check next-phase chain
cd /Users/oskar/Developer/Learning/courses-ia-generated/go-for-java-devs
echo "=== CADENA 'Que sigue' -> menciona la fase siguiente ==="
for i in 00 01 02 03 04 05 06 07 08 09 10 11 12 13 14 15 16; do
  f=$(ls ${i}-*.md 2>/dev/null | grep -v convencion | head -1)
  [ -z "$f" ] && continue
  nxt=$(printf "%02d" $((10#$i + 1)))
  nxts=$((10#$i + 1))
  if sed -n '/^### Qué sigue/,/^### La señal/p' "$f" | grep -qE "Fase ${nxt}|Fase ${nxts}"; then
    echo "OK   $f -> Fase $nxt"
  else
    echo "FALTA $f no menciona Fase $nxt"
  fi
done

# --- 2026-09-12T14:18:51 · Check project tag ordering
cd /Users/oskar/Developer/Learning/courses-ia-generated/go-for-java-devs
echo "=== TAGS DE PROYECTO: orden monotono por servicio ==="
grep -ho 'git tag -a [a-z]*/v[0-9.]*' [01][0-9]-*.md | awk '{print $4}' | sort -t/ -k1,1 -V | awk -F/ '{print $1"\t"$2}'
echo
echo "=== TAGS DE HITO usados ==="
grep -ho 'git tag -a [a-z-]*[/-][a-z0-9.-]*' [01][0-9]-*.md | awk '{print $4}' | grep -vE '^(opsreport|eventrelay|atlassync|clearinghouse)/' | sort -u

# --- 2026-09-12T14:19:02 · Find duplicate project tags across phases
cd /Users/oskar/Developer/Learning/courses-ia-generated/go-for-java-devs
for t in "atlassync/v0.2" "clearinghouse/v0.5" "eventrelay/v0.9" "opsreport/v0.5"; do
  echo "── $t"
  grep -ln "git tag -a $t " [01][0-9]-*.md | tr '\n' ' '
  echo
done

# --- 2026-09-12T14:19:20 · Map cross-phase references
cd /Users/oskar/Developer/Learning/courses-ia-generated/go-for-java-devs
echo "=== REFERENCIAS CRUZADAS: 'Fase NN' citada desde cada archivo ==="
for f in [01][0-9]-*.md; do
  [ "$f" = "00-convencion-de-git-y-tags.md" ] && continue
  own=$(echo "$f" | grep -oE '^[0-9]+')
  refs=$(grep -ohE 'Fase [0-9]{2}' "$f" | grep -oE '[0-9]{2}' | sort -un | tr '\n' ' ')
  printf "%-38s propia=%s  cita: %s\n" "$f" "$own" "$refs"
done

# --- 2026-09-12T14:19:51 · Inspect phase 15 section 4 tail
cd /Users/oskar/Developer/Learning/courses-ia-generated/go-for-java-devs
sed -n '/^### 🪞 Tu instinto/,/^### Escape analysis/p' 15-rendimiento-y-profiling.md | tail -20

# --- 2026-09-12T14:20:18 · Fix dictionary heading and mini project count
cd /Users/oskar/Developer/Learning/courses-ia-generated/go-for-java-devs
# Fix 2: encabezado del diccionario en la fase 17
sed -i '' 's|^### 📖 El diccionario completo$|### 📖 Diccionario Java ⇄ Go: las diez entradas que más vas a usar|' 17-capstone.md
grep -n '📖' 17-capstone.md | head -3
echo "---"
# Fix 3: 28 -> 46 mini proyectos
sed -i '' 's|Más veintiocho mini proyectos|Más cuarenta y seis mini proyectos|' README.md
sed -i '' 's|18 fases · 4 servicios · 28 mini proyectos · 131 horas|18 fases · 4 servicios · 46 mini proyectos · 131 horas|' 0-ESTRUCTURA-CURSO.md
sed -i '' 's|^## 🧰 5. Los 28 mini proyectos$|## 🧰 5. Los 46 mini proyectos|' 0-ESTRUCTURA-CURSO.md
grep -n 'mini proyectos' README.md 0-ESTRUCTURA-CURSO.md | head

# --- 2026-09-12T14:20:35 · Locate insertion point and verify reading order sections
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

# --- 2026-09-12T14:20:48 · Check exact separator before section 9
cd /Users/oskar/Developer/Learning/courses-ia-generated/go-for-java-devs
l=$(grep -n '^## 📚 9\. Referencias' 01-sintaxis-y-valores.md | cut -d: -f1)
sed -n "$((l-3)),$((l))p" 01-sintaxis-y-valores.md | cat -A | head -5

# --- 2026-09-12T14:20:58 · Verify separator line before section 9
cd /Users/oskar/Developer/Learning/courses-ia-generated/go-for-java-devs
for f in [01][0-9]-*.md; do
  [ "$f" = "00-convencion-de-git-y-tags.md" ] && continue
  l=$(grep -n '^## 📚 9\. Referencias' "$f" | cut -d: -f1)
  prev=$(sed -n "$((l-2))p" "$f")
  printf "%-38s [%s]\n" "$f" "$prev"
done

# --- 2026-09-12T14:27:46 · Verify challenge sections added and counts unchanged
cd /Users/oskar/Developer/Learning/courses-ia-generated/go-for-java-devs
echo "=== Desafios de cierre presentes ==="
for f in [01][0-9]-*.md; do
  [ "$f" = "00-convencion-de-git-y-tags.md" ] && continue
  n=$(grep -c '^\*\*D[123] —' "$f")
  ok=$(grep -c '^### 🔴 Desafíos de cierre' "$f")
  printf "%-38s seccion=%s desafios=%s\n" "$f" "$ok" "$n"
done
echo
echo "=== el conteo declarado de ejercicios NO cambio ==="
for f in [01][0-9]-*.md; do
  [ "$f" = "00-convencion-de-git-y-tags.md" ] && continue
  d=$(grep -oE '^## 🧪 8\. Ejercicios \([0-9]+\)' "$f")
  n=$(awk '/^## 🧪 8\. Ejercicios/,/^## 📚 9\./' "$f" | grep -cE '^[0-9]+\. ')
  printf "%-38s %s numerados=%s\n" "$f" "$d" "$n"
done

# --- 2026-09-12T14:27:57 · Read style guide sections 9 and 10
cd /Users/oskar/Developer/Learning/courses-ia-generated/go-for-java-devs/prompts
sed -n '/^## 9. Plantilla obligatoria/,/^### 9.1/p' guia-de-estilo-y-convenciones.md
echo "======== §10"
sed -n '/^## 10. Ejercicios/,/^## 11\./p' guia-de-estilo-y-convenciones.md | head -40

# --- 2026-09-12T14:28:43 · Read template sections 8 and 9
cd /Users/oskar/Developer/Learning/courses-ia-generated/go-for-java-devs/prompts
sed -n '/^## 🧪 8. Ejercicios/,/^## 📚 9. Referencias/p' plantillas-de-capitulo.md
echo "════"
sed -n '/^## 📚 9. Referencias/,/^## ⚖️ 10./p' plantillas-de-capitulo.md

# --- 2026-09-12T14:29:55 · Full revalidation after edits
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

# --- 2026-09-12T14:30:08 · Validate challenges epoch discipline and totals
cd /Users/oskar/Developer/Learning/courses-ia-generated/go-for-java-devs
echo "=== 5. Desafios: 3 por fase, sin duplicar titulos ==="
grep -h '^\*\*D[123] —' [01][0-9]-*.md | wc -l | xargs echo "total desafios:"
echo
echo "=== 6. Epoca: desafios del Bloque A sin deps externas ==="
for f in 0[0-7]-*.md; do [ "$f" = "00-convencion-de-git-y-tags.md" ] && continue
  h=$(sed -n '/^### 🔴 Desafíos de cierre/,/^## 📚 9\./p' "$f" | grep -nE 'golang\.org/x|github\.com/|go\.uber' | grep -v '🕰️')
  [ -n "$h" ] && { echo "-- $f"; echo "$h"; }
done
echo "(revisar los que salgan)"
echo
echo "=== 7. Recuento final ==="
wc -l *.md | tail -1
echo "numerados: $(grep -h -E '^[0-9]+\. ' [01][0-9]-*.md | wc -l | tr -d ' ') (incluye listas fuera de §8)"

# --- 2026-09-12T19:21:39 · Verify new document
cd /Users/oskar/Developer/Learning/courses-ia-generated/go-for-java-devs
wc -l prompts/aprendizaje.md
n=$(grep -c '^```' prompts/aprendizaje.md); echo "vallas: $n (par=$((n%2==0)))"

# --- 2026-09-12T19:28:06 · Inspect docker lab proposal structure and README
cd /Users/oskar/Developer/Learning/courses-ia-generated/propuestas-cursos/propuesta-lab-docker
wc -l *.md && echo "=== src ===" && find src -type f | head -50 && echo "=== README ===" && cat README.md

# --- 2026-09-12T19:28:11 · Read proposals directory README
cd /Users/oskar/Developer/Learning/courses-ia-generated/propuestas-cursos
cat README.md 2>/dev/null | head -60
echo "=== hermanos ==="; ls

# --- 2026-09-12T19:28:15 · Read master plan first part
cd /Users/oskar/Developer/Learning/courses-ia-generated/propuestas-cursos/propuesta-lab-docker
sed -n '1,120p' 07-super-inventory-lab-plan-maestro.md

# --- 2026-09-12T19:28:19 · Read master plan services and rings
cd /Users/oskar/Developer/Learning/courses-ia-generated/propuestas-cursos/propuesta-lab-docker
sed -n '120,300p' 07-super-inventory-lab-plan-maestro.md

# --- 2026-09-12T19:28:24 · Read rings section
cd /Users/oskar/Developer/Learning/courses-ia-generated/propuestas-cursos/propuesta-lab-docker
sed -n '300,420p' 07-super-inventory-lab-plan-maestro.md

# --- 2026-09-12T19:29:06 · Check sibling proposal and lab structure
cd /Users/oskar/Developer/Learning/courses-ia-generated/propuestas-cursos
echo "=== complemento-docker README ==="; head -40 propuesta-complemento-docker/README.md 2>/dev/null || ls propuesta-complemento-docker
echo; echo "=== lab-docker: 00-instrucciones (encabezados) ==="
grep -E '^#{1,3} ' propuesta-lab-docker/00-instrucciones.md | head -25
echo; echo "=== 06-anillo-0 (encabezados) ==="
grep -E '^#{1,3} ' propuesta-lab-docker/06-anillo-0-refinamiento-y-hoja-de-ruta.md | head -25

# --- 2026-09-12T19:34:07 · Verify proposal files and links
cd /Users/oskar/Developer/Learning/courses-ia-generated/propuestas-cursos/propuesta-java-arquitectura
wc -l *.md
echo "--- enlaces internos ---"
grep -ohE '\]\([0-9A-Za-z._/-]+\.md\)' *.md | tr -d '()]' | sed 's/^\[//' | sort -u | while read p; do [ -e "$p" ] && echo "OK   $p" || echo "ROTO $p"; done

# --- 2026-09-12T19:56:49 · Read existing review course READMEs
cd /Users/oskar/Developer/Learning/courses-ia-generated
echo "═══ repaso-aws README ═══"; head -45 repaso-aws-entrevistas/README.md
echo; echo "═══ líneas por doc (aws) ═══"; wc -l repaso-aws-entrevistas/*.md | tail -3
echo; echo "═══ maestria-ia README ═══"; head -40 maestria-ia/README.md

# --- 2026-09-12T19:57:27 · Check track B and search for architecture patterns coverage
cd /Users/oskar/Developer/Learning/courses-ia-generated
echo "═══ track_b ═══"; ls maestria-ia/track_b/ && wc -l maestria-ia/track_b/*.md 2>/dev/null | tail -2
echo; echo "═══ react-16 track BE (Go) ═══"; wc -l react-16-legacy-for-backend-devs/be*.md react-16-legacy-for-backend-devs/bea*.md 2>/dev/null | tail -2
echo; echo "═══ ¿existe algo de patrones/DDD/microservicios en el repo? ═══"
grep -ril 'hexagonal\|bounded context\|microservices.io\|Gang of Four\|patrones GoF' --include='*.md' . 2>/dev/null | grep -v 'go-for-java-devs\|propuesta-java' | head -10
echo "(vacío = no existe)"

# --- 2026-09-12T19:59:38 · Verify plan document and links
cd /Users/oskar/Developer/Learning/courses-ia-generated
wc -l PLAN-REFRESCAMIENTO.md
grep -ohE '\]\([0-9A-Za-z._/-]+\.md\)' PLAN-REFRESCAMIENTO.md | tr -d '()]' | sed 's/^\[//' | while read p; do [ -e "$p" ] && echo "OK   $p" || echo "ROTO $p"; done

# --- 2026-09-12T20:05:00 · Check git status and remote
cd /Users/oskar/Developer/Learning/courses-ia-generated
git status --short
echo "--- ¿es público? remoto: ---"
git remote -v | head -2

# --- 2026-09-12T20:05:09 · Final count of Go course
cd /Users/oskar/Developer/Learning/courses-ia-generated/go-for-java-devs
echo "raíz:"; wc -l *.md | tail -1
echo "prompts (incluye aprendizaje.md):"; wc -l prompts/aprendizaje.md
echo "archivos en raíz: $(ls *.md | wc -l | tr -d ' ')"

# --- 2026-09-12T20:10:24 · Check root files and gitignore
cd /Users/oskar/Developer/Learning/courses-ia-generated
ls -a | head -15
echo "--- .gitignore ---"; cat .gitignore 2>/dev/null || echo "(no existe)"

# --- 2026-09-12T20:12:58 · 
cd /Users/oskar/Developer/Learning/courses-ia-generated
ls -1 *.md
echo "--- lineas ---"
wc -l PLAN-REFRESCAMIENTO.md nuevas-ideas.md claude-remote.md 2>/dev/null
echo "--- headings PLAN ---"
grep -n '^#\{1,3\} ' PLAN-REFRESCAMIENTO.md

# --- 2026-09-12T20:13:06 · 
cat PLAN-REFRESCAMIENTO.md

# --- 2026-09-12T20:13:18 · 
cd /Users/oskar/Developer/Learning/courses-ia-generated
grep -n '^#\{2,4\} ' go-for-java-devs/prompts/aprendizaje.md | head -60

# --- 2026-09-12T20:13:50 · 
cd /Users/oskar/Developer/Learning/courses-ia-generated
cat > REPASO-00-INDICE.md <<'EOF'
# 🗂️ Refrescamiento para entrevistas — índice

> **Qué es esto.** El conjunto de notas y bases del repaso profesional: la autopsia
> de lo que las entrevistas destapan, el esqueleto del material que falta, el método
> de estudio a jornada completa y el banco de preguntas e historias.
> **Qué no es.** Un curso. Nada de esto se publica; es material de trabajo personal.

---

## ⚠️ Antes que nada: este material está en el repositorio equivocado

`courses-ia-generated` es **público en GitHub**. Los documentos de esta familia
contienen información personal de búsqueda de empleo: entrevistas hechas, puntos
débiles detectados, huecos técnicos declarados y calendario propio.

La decisión ya tomada es que **lo de entrevistas vive en un repositorio aparte, más
privado**. Mientras ese repositorio no exista, la raíz de este funciona como
**zona de preparación**, con dos salvaguardas:

1. Todos los archivos de la familia se llaman `REPASO-*.md` más
   `PLAN-REFRESCAMIENTO.md`, así que se mueven con un solo `git mv` o `mv` el día
   que haya destino.
2. Están **excluidos en `.gitignore`**, de modo que un `git add .` distraído no los
   publica. Si en algún momento se decide que sí son públicos, se quita la
   exclusión a propósito, no por accidente.

> 🧭 El material de curso se comparte; el material de búsqueda de empleo, no. Es
> la única frontera de este repositorio que no se discute.

---

## 📚 Los documentos

| Documento | Qué contiene | Cuándo se toca |
|---|---|---|
| [`PLAN-REFRESCAMIENTO.md`](PLAN-REFRESCAMIENTO.md) | El **plan y el calendario**: seis semanas, jornada de 6 h, protocolo de interrupción, inventario del repositorio | Se revisa cuando cambia el calendario o entra material nuevo |
| [`REPASO-01-AUTOPSIA-Y-HUECOS.md`](REPASO-01-AUTOPSIA-Y-HUECOS.md) | La **autopsia de cada entrevista** y el mapa vivo de huecos técnicos | **Después de cada entrevista**, sin excepción |
| [`REPASO-02-BASES-ARQUITECTURA.md`](REPASO-02-BASES-ARQUITECTURA.md) | Las **bases del material que falta**: `repaso-arquitectura-entrevistas`, sus once documentos, su formato y el esqueleto de cada uno | Cuando se escriba ese material, y para decidir su alcance |
| [`REPASO-03-METODO-36H.md`](REPASO-03-METODO-36H.md) | El **método de estudio** a 36 h/semana: tarjetas, intervalos, sesión, semana, modo mantenimiento | Rara vez; es la infraestructura |
| [`REPASO-04-BANCO-Y-HISTORIAS.md`](REPASO-04-BANCO-Y-HISTORIAS.md) | El **banco de preguntas** para practicar en voz alta y el **libro de historias** con números | A diario, 30 min al cierre de la jornada |

---

## 🔁 Cómo se usan juntos

```text
Entrevista  ──►  REPASO-01 (autopsia)  ──►  huecos nuevos
                                             │
                                             ├─► PLAN (recoloca el calendario)
                                             ├─► REPASO-02 (¿hay que escribir algo?)
                                             └─► REPASO-04 (pregunta que no supiste
                                                            responder → al banco)

Jornada     ──►  REPASO-03 dicta la forma del día
                 REPASO-04 se alimenta en los últimos 30 min
```

El bucle completo tiene una sola condición para funcionar: **la autopsia se escribe
el mismo día de la entrevista**, mientras duele. A las 48 horas ya no recuerdas si
no lo sabías o no supiste decirlo, y esos dos fallos se arreglan de forma distinta.

---

## 📦 Material existente que este plan reutiliza

Nada de esto hay que escribirlo; ya está en el repositorio.

| Material | Qué aporta |
|---|---|
| `repaso-aws-entrevistas` | El **formato de referencia** (teoría + `P#` + solucionario + `L#`) y la semana de AWS |
| `repaso-gcp-entrevistas` | La semana de GCP y la tabla de equivalencias |
| `propuestas-cursos/propuesta-lab-docker/` | La **mitad práctica de todo el plan**: `super-inventory` |
| `propuestas-cursos/propuesta-java-arquitectura/` | La versión profunda de los huecos 1–5; aparcada, pero su mapa de fases sirve de fuente |
| `go-for-java-devs/prompts/aprendizaje.md` | El método de tarjetas del que [`REPASO-03`](REPASO-03-METODO-36H.md) es la versión a jornada completa |
| `maestria-ia/track_b` | Goteo de sábado |
EOF
wc -l REPASO-00-INDICE.md

# --- 2026-09-12T20:14:31 · 
cd /Users/oskar/Developer/Learning/courses-ia-generated
cat > REPASO-01-AUTOPSIA-Y-HUECOS.md <<'EOF'
# 🔬 Autopsia de entrevistas y mapa de huecos

> Documento **vivo**. Se escribe una entrada por entrevista, el mismo día, y de ahí
> sale el mapa de huecos que ordena el calendario de
> [`PLAN-REFRESCAMIENTO.md`](PLAN-REFRESCAMIENTO.md).

---

## 1. Por qué una autopsia y no una lista de temas

Una lista de temas dice *qué* preguntaron. La autopsia dice **por qué falló la
respuesta**, y eso es lo único accionable, porque los tres modos de fallo tienen
remedios distintos y se confunden con facilidad:

| Modo de fallo | Síntoma | Remedio | Lo que NO sirve |
|---|---|---|---|
| **No lo sabías** | No reconoces el término, ni por aproximación | Material nuevo: leer, practicar, medir | Repasar tarjetas de algo que no está en ninguna tarjeta |
| **No lo recordaste** | Al oír la respuesta piensas "claro, si eso lo sé" | Repetición espaciada: tarjeta, y que el sistema la programe | Volver a leer el tema entero |
| **No supiste decirlo** | Sabías la respuesta y salió desordenada, larga o dubitativa | Práctica en voz alta, cronometrada, de pie | Estudiar más del tema |

> 🧭 El tercero es el más común en perfiles senior y el que menos se entrena.
> Alguien con ocho años de Spring Boot **sabe** qué es un repositorio; lo que no ha
> hecho nunca es explicarlo en noventa segundos a alguien que lo está evaluando.

---

## 2. Plantilla de autopsia

Se copia tal cual por cada entrevista. Quince minutos, el mismo día.

```markdown
## YYYY-MM-DD · <empresa o rol> · <ronda>

**Formato:** <técnica / arquitectura / sistema / cultural>  ·  **Duración:** <min>
**Sensación general:** <una línea, sin maquillar>

### Preguntas que salieron
| # | Pregunta (como la recuerdes) | Modo de fallo | Acción |
|---|---|---|---|
| 1 |  | ✅ bien / ❌ no sabía / 🌫️ no recordé / 🗣️ no supe decirlo |  |

### Lo que salió bien
(Importa: es lo que hay que seguir contando, y son las historias que funcionan.)

### El momento peor
Uno solo, el que más escoció. Qué preguntaron, qué contestaste, qué había que
haber contestado.

### Señales del proceso
Qué preguntaron ellos sobre el equipo, el stack, la etapa. Dice más del puesto
que la oferta.

### Acciones concretas
- [ ] Tarjeta nueva: …
- [ ] Al banco de preguntas (REPASO-04): …
- [ ] Hueco nuevo en §4 de este documento: …
- [ ] Historia que falta en el libro: …
```

---

## 3. Entrevista 1 — la que disparó el plan

La primera entrevista del proceso dejó **ocho puntos de mejora anotados**. No están
clasificados por modo de fallo porque la autopsia se hizo a posteriori; a partir de
la siguiente sí.

Los ocho, en las palabras en que se anotaron:

1. **Patrones de diseño** — Gamma et al. (GoF).
2. **Patrones enterprise de Fowler** que apliquen (PoEAA).
3. **Microservicios y sus patrones** — el catálogo de microservices.io.
4. **Modelos arquitectónicos** — DDD, arquitectura hexagonal y otras.
5. **Patrones de resiliencia** — que viven dentro de microservicios.
6. **Alta disponibilidad** — escalado horizontal, pods y demás.
7. **Cloud AWS y GCP** — el eje principal del perfil.
8. **OpenShift y Azure** — a nivel de "tengo idea de estas tecnologías".

Más un noveno tema que no vino de la entrevista sino del mercado: **IA y agéntica**
como diferenciador.

> ⚠️ Lectura importante: los puntos 1–4 son **la misma familia** —cómo se diseña y
> se justifica un sistema— y son justo donde el repositorio no tenía ni una línea.
> No es casualidad que sea el bloque que la entrevista destapó.

---

## 4. Mapa de huecos

Estado actual, cruzado con lo que existe en el repositorio.

| # | Hueco | Estado | Material que ya existe | Semana |
|---|---|---|---|---|
| 1 | Patrones GoF | ❌ nada escrito | — | 1 |
| 2 | Fowler PoEAA | ❌ nada escrito | — | 1 |
| 3 | DDD estratégico y táctico, hexagonal / limpia / cebolla | ❌ nada escrito | `propuesta-java-arquitectura` (solo propuesta) | 1 |
| 4 | Microservicios y su catálogo | ❌ nada escrito | `propuesta-lab-docker` lo **opera**, no lo explica | 2 |
| 5 | Resiliencia | ⚠️ parcial | `repaso-aws/11`, `repaso-gcp/11`, `go-for-java-devs/10` (a fondo) | 2 |
| 6 | Alta disponibilidad y escalado | ⚠️ parcial | `repaso-aws/02`, `repaso-gcp/02`, `propuesta-lab-docker` | 2 |
| 7 | AWS | ✅ completo | `repaso-aws-entrevistas` | 3 |
| 8 | GCP | ✅ completo | `repaso-gcp-entrevistas` | 4 |
| 9 | OpenShift y Azure | ❌ nada escrito | Se apoya en lo que ya sabes de Kubernetes y AWS/GCP | 6, con reloj |
| 10 | IA y agéntica | ✅ existe | `maestria-ia/track_b` (B0–B5) | goteo de sábado |

### Cómo se actualiza

Un hueco solo se da por cerrado cuando **se puede explicar en voz alta en dos
minutos y hay una historia con un número detrás**. Haber leído el documento no
cierra nada; es la condición de entrada, no la de salida.

Cuando una entrevista destape algo que no está en la tabla, se añade una fila con
su semana asignada y se recoloca el calendario del plan. La tabla puede crecer;
lo que no puede es tener filas sin semana.

---

## 5. El patrón que hay que vigilar

Tres entrevistas bastan para ver el patrón real, que casi nunca es el que uno cree:

- Si se repite el **❌ no sabía** en la misma familia → falta material, hay que
  escribirlo o buscarlo.
- Si se repite el **🌫️ no recordé** → el sistema de tarjetas no cubre eso, o se
  está saltando el bloque de repaso.
- Si se repite el **🗣️ no supe decirlo** → el problema no es de estudio. Son los
  últimos 30 minutos de la jornada los que hay que dejar de saltarse.
- Si se repite el **✅ bien** en lo mismo → ya está; deja de repasarlo y usa esas
  horas en otra cosa. Estudiar lo que ya dominas es la forma más cómoda de no
  avanzar.
EOF
wc -l REPASO-01-AUTOPSIA-Y-HUECOS.md

# --- 2026-09-12T20:16:01 · 
cd /Users/oskar/Developer/Learning/courses-ia-generated
cat > REPASO-02-BASES-ARQUITECTURA.md <<'EOF'
# 🏛️ Bases de `repaso-arquitectura-entrevistas`

> El esqueleto del **único material nuevo** que el plan de refrescamiento necesita.
> Aquí está el formato, el alcance, el contenido documento por documento y las
> reglas que lo gobiernan. Con esto se puede escribir sin volver a decidir nada.

---

## 1. Qué es y qué no es

Es un **repaso**, no un curso. La distinción manda sobre todo lo demás:

| | Curso | Repaso |
|---|---|---|
| Para qué | aprender algo que no sabes | recuperar y ordenar lo que ya rozaste |
| Cuánto tarda | meses | días |
| Cómo se lee | en orden, una vez | en orden la primera vez; suelto para siempre |
| Qué produce | un sistema construido | **respuestas que sabes decir en dos minutos** |
| Qué mide | el sistema | tú, contra un banco de preguntas |

La versión curso de este mismo temario ya existe como propuesta en
[`propuestas-cursos/propuesta-java-arquitectura/`](propuestas-cursos/propuesta-java-arquitectura/)
(~128 h, dieciséis fases). Es excelente y **demasiado lenta para una búsqueda
activa**: queda aparcada hasta que haya empleo. Este repaso le roba el eje —*¿dónde
va esta frontera y qué cuesta moverla después?*— y se deja el resto.

---

## 2. El formato, que ya está probado

El de `repaso-aws-entrevistas`, sin inventar nada:

- **Documentos teóricos numerados** `01`–`09`, cada uno con índice de salto rápido
  al principio, pensados para releerse sueltos.
- **Una simulación de entrevista** (`10`) con preguntas numeradas `P#` y escenarios
  de diseño.
- **Un solucionario centralizado** (`11`), separado de las preguntas para que la
  recuperación sea real y no un vistazo.
- **Una serie práctica `L#`** — y aquí está la diferencia con AWS y GCP: la mitad
  práctica no es una cuenta de nube, es el **`super-inventory`** del laboratorio de
  contenedores, que no cuesta dinero y se puede romper a gusto.

### Por qué las preguntas van separadas de las respuestas

Porque leer la respuesta debajo de la pregunta se siente como estudiar y no lo es.
El efecto de examen —recuperar antes de comprobar— es de los pocos hallazgos de la
psicología del aprendizaje con evidencia sólida y tamaño de efecto grande. El
solucionario aparte es lo que fuerza el intento previo. Está argumentado en
[`REPASO-03-METODO-36H.md`](REPASO-03-METODO-36H.md).

---

## 3. Las reglas que gobiernan el material

Heredadas del repositorio, con una añadida propia del contexto de entrevista.

> 📐 **1. Ninguna afirmación de arquitectura se escribe sin su medición.**
> *"Los microservicios escalan mejor"* no se escribe sin decir **en qué eje** y **a
> partir de qué carga**. Cuando el número no se puede medir en el laboratorio, se
> declara como estimación y se dice de dónde sale.

> 📐 **2. Cada patrón se cierra con su veredicto de cuándo NO usarlo.**
> Es el reflejo que separa a un arquitecto de alguien que ha leído el catálogo. En
> entrevista es la respuesta que más sube el listón, porque casi nadie la da.

> 📐 **3. Todo lo que se explica tiene que caber en dos minutos hablados.**
> Regla específica de este material: si un concepto no se puede resumir en un
> párrafo defendible en voz alta, el documento no ha terminado con él. Cada sección
> teórica lleva su **"en dos minutos"** al final.

> 📐 **4. Se apoya en lo que ya existe; no lo repite.**
> Resiliencia ya está en `repaso-aws/11`, `repaso-gcp/11` y muy a fondo en
> `go-for-java-devs/10`. El documento `08` enlaza y añade el ángulo de diseño; no
> vuelve a explicar el backoff con jitter desde cero.

---

## 4. Los once documentos

Los `01`–`05` son los que la entrevista destapó y **no son negociables**. Los
`06`–`09` se solapan parcialmente con AWS, GCP y Go, y admiten versión corta si el
calendario aprieta (ver §6).

### `01` — Patrones GoF que se preguntan de verdad

No son veintitrés. En entrevista salen nueve, y salen siempre los mismos:
**Strategy, Factory Method / Abstract Factory, Builder, Adapter, Decorator,
Observer, Template Method, Command, Proxy**.

De cada uno: el problema que resuelve, la forma mínima en Java moderno —muchos se
reducen a una interfaz funcional o a un `record` desde Java 8—, **dónde lo tienes ya
usándolo sin saberlo en Spring** (`BeanPostProcessor` es Decorator, `@Transactional`
es Proxy, `JdbcTemplate` es Template Method), y el veredicto.

La sección que más rinde del documento es la última: **los que no se usan y por qué**
—Singleton como antipatrón de testabilidad, Visitor contra `sealed` + pattern
matching, Flyweight resuelto por el propio runtime— porque nombrar tres patrones que
*no* usarías y justificarlo demuestra criterio, no memoria.

### `02` — Fowler PoEAA aplicado hoy

El catálogo que Spring te da hecho y no sabes que estás usando. Lo que entra:
**Domain Model vs Transaction Script** (la decisión de verdad, y cuándo el
Transaction Script es la respuesta correcta), **Service Layer**, **Repository**,
**Unit of Work** (= tu `@Transactional`), **Data Mapper vs Active Record**,
**Identity Map** (= el contexto de persistencia de JPA), **Lazy Load** y su
`LazyInitializationException`, **DTO** y por qué Fowler lo consideraba un mal
necesario de los límites remotos.

El ángulo: **qué te da Spring/JPA ya implementado, qué precio pagas por ello, y qué
pasa cuando la abstracción se rompe.** El modelo anémico se trata aquí y se enlaza
con DDD táctico en `05`.

### `03` — Arquitecturas en capas: hexagonal, limpia y cebolla

Las tres dicen casi lo mismo y el mérito está en saber en qué se diferencian de
verdad. El núcleo común es **la regla de dependencia**: las dependencias apuntan
hacia dentro, y el dominio no conoce a nadie.

Contenido: puertos y adaptadores con nombres concretos, dónde va cada cosa en un
proyecto Spring real, **la inversión de dependencias en el borde de persistencia**
(el repositorio como puerto, JPA como adaptador), el coste en ceremonia —que existe
y hay que decirlo—, y el veredicto: **en un CRUD con reglas triviales, hexagonal es
carpeta ceremonial**.

Aquí va el primer artefacto que se enseña: el **diagrama C4** del `super-inventory`,
en sus cuatro niveles.

### `04` — DDD estratégico

La mitad del DDD que más se pregunta y menos se estudia. **Contexto acotado**,
**lenguaje ubicuo**, **subdominios** (núcleo, soporte, genérico) y el **mapa de
contextos** con sus patrones de relación: socio, cliente-proveedor, conformista,
capa anticorrupción, núcleo compartido, caminos separados, servicio de acceso
público.

El ángulo de entrevista: **el contexto acotado es la unidad de decisión de la
frontera**, y la ley de Conway te la impone aunque no la dibujes. La pregunta
*"¿cómo dividirías este sistema en microservicios?"* se responde desde aquí, no
desde el catálogo de `06`.

Práctica: dibujar el mapa de contextos **real** del `super-inventory` —el que tiene,
no el que debería tener— y señalar dónde falta una capa anticorrupción.

### `05` — DDD táctico

**Agregado** (y su regla de oro: una transacción, un agregado), **raíz de agregado**,
**entidad**, **objeto de valor**, **repositorio por agregado**, **servicio de
dominio**, **evento de dominio**, **fábrica**.

Lo que hace útil al documento es el conflicto real: **los agregados de DDD contra el
modelo relacional de JPA**. El agregado quiere cargarse entero y consistente; JPA
quiere cargar lo mínimo. De ahí salen la mitad de las decisiones de un servicio
Java, y es material de entrevista de primera.

El veredicto es obligatorio y honesto: **el DDD táctico completo sobre un dominio sin
invariantes es ceremonia cara.** Saber decirlo vale más que recitar los bloques.

### `06` — Microservicios: el catálogo

Lo aplicable de microservices.io, ordenado por frecuencia en entrevista:
**descomposición** (por capacidad de negocio vs por subdominio), **base de datos por
servicio** y lo que cuesta, **API gateway** y **BFF**, **saga** orquestada vs
coreografiada, **CQRS** y su ventana de inconsistencia, **event sourcing** (con su
veredicto de "casi nunca"), **outbox transaccional**, **descubrimiento de servicios**,
**configuración externalizada**, **strangler fig** para migrar.

Abre con lo que el catálogo no dice en voz alta: **el monolito modular es la
respuesta correcta más veces de las que se admite**, y el precio de separar es
latencia, consistencia, operación y dinero.

### `07` — Comunicación e integración

Síncrono vs asíncrono como decisión de **acoplamiento temporal**. REST, gRPC y
eventos con el criterio para elegir. **Contratos y versionado**, compatibilidad hacia
atrás y hacia adelante. **Idempotencia** y claves de idempotencia. Garantías de
entrega —*at-most-once*, *at-least-once*, la mentira de *exactly-once*— y la
deduplicación en el consumidor. Orden de mensajes y particionado.

El laboratorio ya tiene el defecto sembrado: el **fire-and-forget** entre `inventory`
y `replenish`. Ese es el caso de estudio del documento entero.

### `08` — Resiliencia

**Se apoya en `repaso-aws/11`, `repaso-gcp/11` y `go-for-java-devs/10`; no los
repite.** Lo que añade es el ángulo de diseño: timeout como primera línea y por qué
casi nadie lo pone, reintento con backoff exponencial **y jitter** —y por qué sin
jitter empeoras la caída—, circuit breaker y sus tres estados, bulkhead, degradación
elegante, límite de velocidad, presión hacia atrás.

La sección de cierre son los **antipatrones**: reintentar lo no idempotente,
reintentar en cada capa (el efecto multiplicador), el timeout que es mayor que el del
que te llama, y el circuit breaker que protege a quien no debía.

### `09` — Alta disponibilidad y escalado

Horizontal vs vertical y por qué la respuesta "horizontal" está incompleta sin
**"porque el servicio es sin estado, y lo es porque la sesión está fuera"**.
Réplicas y pods, autoescalado y sus métricas, balanceo y comprobaciones de salud
—**salud contra disponibilidad**, que son dos endpoints distintos—, zonas y
regiones, **RTO y RPO**, presupuesto de error, despliegues sin caída (azul-verde,
canario, rodante) y el coste real de cada nueve añadido.

### `10` — Simulación de entrevista

Sesenta preguntas `P#` repartidas por los nueve documentos, más **seis escenarios de
diseño** completos del tipo "diseña el sistema de X". Sin respuestas: van en `11`.

Los escenarios se eligen para que cada uno fuerce una frontera distinta: uno que
**no** debe separarse, uno con consistencia distribuida inevitable, uno de lectura
masiva, uno de escritura con picos, uno con integración de tercero poco fiable y uno
de migración de un monolito existente.

### `11` — Respuestas

Solucionario centralizado. Cada respuesta en tres capas: **la de treinta segundos**
(la que das primero), **la de dos minutos** (cuando te dicen "cuéntame más") y **el
detalle** (para estudiar, no para decir).

### `L0`–`L4` — La serie práctica sobre `super-inventory`

| Lab | Qué se hace | Qué queda |
|---|---|---|
| `L0` | Levantar el Anillo 0 y auditar lo que hay | C4 de los cuatro niveles y mapa de contextos real |
| `L1` | Refactorizar un servicio a puertos y adaptadores | La medida del coste en ceremonia, en líneas y en clases |
| `L2` | Romper el fire-and-forget y arreglarlo con outbox | Ventana de inconsistencia medida, antes y después |
| `L3` | Matar `catalog` bajo carga; poner timeout, reintento y circuit breaker | La curva de errores y latencia en cada escalón |
| `L4` | Escalar horizontalmente y provocar el fallo de estado | El número de la sesión perdida, y el fix |

Cada lab termina con **un ADR** y **una historia con número** para el libro de
[`REPASO-04`](REPASO-04-BANCO-Y-HISTORIAS.md). Esa es su razón de ser: sin el lab,
los patrones son vocabulario.

---

## 5. Estructura del directorio

Cuando se escriba, en el repositorio privado de entrevistas:

```text
repaso-arquitectura-entrevistas/
├── README.md                     índice, orden de lectura y vía rápida
├── 01-patrones-gof.md
├── 02-fowler-poeaa.md
├── 03-hexagonal-limpia-cebolla.md
├── 04-ddd-estrategico.md
├── 05-ddd-tactico.md
├── 06-microservicios-catalogo.md
├── 07-comunicacion-e-integracion.md
├── 08-resiliencia.md
├── 09-alta-disponibilidad-y-escalado.md
├── 10-simulacion-de-entrevista.md
├── 11-respuestas.md
└── labs/
    ├── l00-auditoria.md … l04-escalado.md
```

Nombres en minúsculas con guiones y numeración con cero delante, como el resto del
repositorio. Cada documento teórico abre con su índice de salto rápido y cierra con
**referencias** —documentación, libros, charlas— y con su **"en dos minutos"**.

---

## 6. Alcance mínimo, si el calendario aprieta

Si aparece una entrevista en cuatro días, esto es lo que se escribe y en qué orden:

1. `04` y `05` (**DDD**) — es de donde salen las respuestas de frontera.
2. `03` (**hexagonal**) — la pregunta más previsible del bloque.
3. `06` (**microservicios**) — el catálogo, aunque sea en tabla.
4. `10` + `11` (**simulación y respuestas**) — aunque sean veinte preguntas en vez
   de sesenta. Practicar en voz alta rinde más que un documento más.

`01` y `02` se pueden sustituir temporalmente por una **tabla de una página**: el
patrón, el problema, dónde lo usa Spring, cuándo no. `07`, `08` y `09` se cubren
enlazando a AWS, GCP y Go, que ya existen.

---

## 7. Lo que queda por decidir

Del plan, sin resolver:

1. ¿Once documentos completos o el **alcance mínimo** de §6? Depende de cómo venga
   el proceso de búsqueda en las dos primeras semanas.
2. ¿La mitad práctica es el laboratorio de contenedores o código Java suelto? El
   laboratorio da mucho más y exige tener el Anillo 0 levantado **antes** de empezar.
3. ¿`propuesta-java-arquitectura` se aparca formalmente, o se absorben sus fases
   `00`–`03` y `06` dentro de este repaso?
4. ¿OpenShift y Azure merecen material propio, o basta con un documento de
   equivalencias contra Kubernetes, AWS y GCP?
EOF
wc -l REPASO-02-BASES-ARQUITECTURA.md

# --- 2026-09-12T20:16:07 · 
cd /Users/oskar/Developer/Learning/courses-ia-generated
sed -n 258,300p go-for-java-devs/prompts/aprendizaje.md

# --- 2026-09-12T20:17:15 · 
cd /Users/oskar/Developer/Learning/courses-ia-generated
cat > REPASO-03-METODO-36H.md <<'EOF'
# 🧠 Método de estudio a jornada completa (36 h/semana)

> La versión a jornada completa del método de
> [`go-for-java-devs/prompts/aprendizaje.md`](go-for-java-devs/prompts/aprendizaje.md),
> que se escribió para 2 h/día de un solo curso. Aquí el presupuesto es **36 h
> semanales** repartidas entre varias fuentes, y el objetivo no es aprender un
> lenguaje: es **responder bien en una entrevista**. Eso cambia tres cosas, y el
> resto del método se mantiene tal cual.
>
> La teoría —curva del olvido con sus matices, efecto de espaciado, efecto de
> examen, dificultades deseables— está en aquel documento y **no se repite aquí**.

---

## 1. Las tres cosas que cambian al estudiar para entrevistas

**Primera: el criterio de éxito es hablado, no escrito.** En un curso, saber es
haber hecho funcionar el código. En una entrevista, saber es **explicarlo en dos
minutos, de pie, sin notas y con alguien evaluándote**. Son habilidades distintas y
la segunda solo se entrena practicándola. De ahí que los últimos 30 minutos de cada
jornada sean innegociables.

**Segunda: las fuentes son varias y compiten.** Arquitectura, AWS, GCP, laboratorio,
IA. Sin una regla de reparto, las horas se van a lo cómodo —que siempre es leer de
lo que ya sabes—. La regla está en §4.

**Tercera: el plan se va a interrumpir.** Entrevistas, pruebas técnicas, un proceso
que se acelera. Un plan de estudio de empleo que no sobrevive a tres entrevistas en
una semana no sirve. Para eso existe el modo mantenimiento de §6.

> 🧭 **El empleo es la prioridad; el plan no.** Cada vez que los dos choquen, gana
> el empleo, y el plan tiene que poder retomarse sin haber vuelto al punto de
> partida. Eso es exactamente lo que compra la repetición espaciada.

---

## 2. La jornada de 6 horas

Seis horas de lectura seguida no se sostienen y no se fijan. La forma:

```text
┌─ 00:00 – 00:45   REPASO Y RECONSTRUCCIÓN (45 min)
│  15 min de tarjetas, las que el sistema programe.
│  30 min de página en blanco: lo de ayer, de memoria, antes de abrir nada.
│  ⚠️ Es la parte que todo el mundo se salta y la que más rinde.
│
├─ 00:45 – 03:00   BLOQUE TEÓRICO (2 h 15)
│  Material nuevo, con el laboratorio abierto en otra ventana: cada patrón que
│  leas, búscalo o provócalo en el sistema que ya tienes corriendo.
│
├─ 03:00 – 03:30   DESCANSO — de verdad, fuera de la silla
│
├─ 03:30 – 05:30   LABORATORIO (2 h)
│  Manos. Docker, k8s, cuenta de nube o código. Nunca lectura.
│
└─ 05:30 – 06:00   CIERRE (30 min)
   · Tarjetas nuevas de lo de hoy
   · Dos líneas de bitácora
   · UNA pregunta de entrevista respondida EN VOZ ALTA y cronometrada
```

Fuera de esto quedan las ~2 h diarias de postulación y búsqueda de ofertas, que son
otro trabajo y no se mezclan con este. Mezclarlos convierte las dos cosas en ninguna.

### Por qué la reconstrucción va antes de abrir nada

Treinta minutos de página en blanco reconstruyendo lo de ayer se sienten
improductivos y son la parte más rentable del día. Recuperar sin pista es lo que
consolida; releer solo produce **fluidez**, que es la sensación de saber algo que
no sabrías decir. La trampa está en que la fluidez se siente igual que el
conocimiento hasta el momento exacto en que te lo preguntan.

### Los últimos 30 minutos

De pie, sin notas, cronómetro a dos minutos, en voz alta y **grabándote** al menos
una vez por semana. Escucharte es incómodo y es la corrección más rápida que
existe: las muletillas, el rodeo antes de contestar y los treinta segundos de
preámbulo se oyen de inmediato y no se ven de ninguna otra forma.

---

## 3. La semana

```text
Lu – Vi   6 h de jornada completa (§2)
Sábado    6 h con otra forma:
          2 h  Simulacro: 5 preguntas + 1 escenario de diseño, cronometrado
          2 h  Laboratorio libre — lo que quedó a medias entre semana
          1 h  Repaso de la semana + poda de tarjetas
          1 h  Goteo de IA (maestria-ia track_b) o lectura ligera
Domingo   Libre. No es opcional: es parte del método.
```

El domingo sin estudiar no es indisciplina. Seis días a seis horas es una jornada
laboral completa y el séptimo día es lo que evita que la semana ocho no exista.

---

## 4. El reparto entre fuentes

Con varias fuentes compitiendo, la regla que impide que las horas se vayan a lo
cómodo:

> 🧭 **En cada semana, el bloque teórico va a UNA fuente principal.** El calendario
> de [`PLAN-REFRESCAMIENTO.md`](PLAN-REFRESCAMIENTO.md) dice cuál. Las demás
> aparecen solo por tarjetas —que siguen viniendo de todo lo ya estudiado— y por el
> laboratorio, que es transversal por naturaleza.

Dicho de otro modo: **las tarjetas son transversales y el estudio nuevo es
monotemático**. Repasar de cinco fuentes a la vez está bien, porque el repaso
intercalado es justamente lo que conviene. Estudiar material nuevo de cinco fuentes
a la vez es no estudiar ninguna.

---

## 5. Las tarjetas

La regla de oro se mantiene sin cambios:

> 🧭 **Solo se hace tarjeta de lo que ya entendiste.** Una tarjeta no sirve para
> aprender algo: sirve para **no olvidar** algo que ya aprendiste ejecutándolo. Si
> la escribes antes de haberlo hecho, memorizas una frase, y una frase no se
> transfiere a una entrevista.

Herramienta: **Anki con FSRS**, retención objetivo del 90%. Sincroniza con el
teléfono, lo que convierte las salas de espera y los desplazamientos en repaso. Si
no quieres depender de una aplicación, una caja de Leitner de cinco compartimentos
es peor y es infinitamente mejor que no repasar.

### Los seis tipos, con las fuentes de este plan

| Tipo | Qué pregunta | De dónde sale aquí |
|---|---|---|
| **Definición defendible** | *"¿Qué es un agregado?"* — y la respuesta cabe en 30 s | Los "en dos minutos" de cada documento |
| **Decisión** | *"Monolito modular o microservicios, y qué lo decide"* | Los ⚖️ veredictos y los escenarios de `10` |
| **Diagnóstico** | *"El servicio se cae bajo carga y los reintentos empeoran la caída. ¿Qué está pasando?"* | Los antipatrones y los labs `L#` |
| **Traducción** | *"Unit of Work en Java es…"*, *"el equivalente de SQS en GCP es…"* | Los diccionarios y la tabla AWS ⇄ GCP |
| **Número** | *"¿Cuánta latencia añadió separar ese servicio?"* | Tus propias mediciones del laboratorio |
| **Historia** | *"Cuéntame algo que hayas roto en producción"* | [`REPASO-04`](REPASO-04-BANCO-Y-HISTORIAS.md) |

Los dos últimos tipos son los que no tiene nadie más y los que ganan entrevistas.
El de **número** solo se puede rellenar si el bloque de laboratorio se está
haciendo de verdad; si tus tarjetas de número están vacías al final de la semana,
esa semana fue solo lectura.

### La poda del sábado

Una tarjeta que llevas cuatro repasos acertándola sin dudar **se borra**. Una que
fallas tres veces seguidas no es una tarjeta mala: es que no entendiste el concepto
—vuelve al material y reescríbela después—. El mazo que crece sin podarse acaba
abandonado, que es el fallo más común del método.

---

## 6. Modo mantenimiento: cuando el plan se interrumpe

| Situación | Qué haces |
|---|---|
| Día con entrevista | Solo los 45 min de repaso. Nada más, y sin culpa |
| Semana cargada de procesos | 1 h/día: tarjetas + una pregunta en voz alta |
| Prueba técnica a la vista | El plan se para; se estudia lo que la prueba pida |
| Viaje, enfermedad, bajón | Solo tarjetas, aunque sean diez minutos en el móvil |

**Al volver**, una jornada entera de reentrada antes de seguir: tarjetas atrasadas
—todas, aunque sean muchas—, reconstrucción de la última semana estudiada y
relectura de la bitácora. **Y después** se continúa donde se dejó, sin reiniciar
nada.

---

## 7. La bitácora

Dos líneas al cierre de cada jornada, en un solo archivo. No es un diario:

```markdown
## 2026-09-14 · Arquitectura · DDD táctico
Hecho: docs 05 §1–4. Lab L1: el repositorio como puerto en `inventory`.
Abierto: el agregado de pedido carga 40 líneas para validar una; ¿es problema
del agregado o de JPA? — a resolver mañana antes de seguir.
```

El valor está en la segunda línea. Lo que quedó abierto es por donde se empieza al
día siguiente, y es lo que te devuelve al sitio después de tres días de entrevistas.
Es también la mejor fuente de historias: las cosas que te costaron un día son
exactamente las que se cuentan bien.

---

## 8. Cómo saber si funciona

Ninguna señal es "he leído mucho".

**Semana 2.** Explicas la diferencia entre hexagonal, limpia y cebolla sin notas, y
dices cuál usarías y por qué. Y sabes nombrar **tres patrones GoF que no usarías**,
con su razón.

**Semana 4.** Ante un escenario de diseño, tu primer reflejo es **preguntar por las
restricciones** —volumen, consistencia, equipo, presupuesto— en vez de proponer una
arquitectura. Ese cambio de reflejo es lo que se está entrenando de verdad.

**Semana 6.** Cada patrón que mencionas viene con una historia y un número.
*"Maté el servicio de catálogo bajo carga y perdí el 40% de las ventas; por eso el
circuit breaker devuelve el último catálogo conocido en vez de fallar"* juega en
otra liga que *"conozco el patrón circuit breaker"*.

**La contraseñal.** Si llevas dos semanas leyendo y el laboratorio no ha cambiado,
el plan se rompió. **Las historias salen del bloque de manos, no del de teoría.**

---

## 9. Errores que ya están identificados

- **Saltarse los 45 min iniciales** porque "hoy quiero avanzar". Es el error que
  más caro sale, y el más frecuente.
- **Saltarse los últimos 30 min** porque cansan. Son los que se parecen a la
  entrevista.
- **Hacer tarjetas mientras lees.** Al final de la sesión, de lo que ejecutaste.
- **Estudiar lo que ya dominas.** Es cómodo, se siente productivo y no mueve nada.
  Si AWS te sale bien tres veces seguidas, esas horas van a patrones.
- **Leer sobre el laboratorio en vez de levantarlo.** Sin manos no hay números, sin
  números no hay historias, y sin historias eres otro candidato que ha leído el
  catálogo.
- **Estudiar y postular en el mismo bloque.** Las dos tareas se contaminan; van en
  horarios separados.
EOF
wc -l REPASO-03-METODO-36H.md

# --- 2026-09-12T20:18:05 · 
cd /Users/oskar/Developer/Learning/courses-ia-generated
cat > REPASO-04-BANCO-Y-HISTORIAS.md <<'EOF'
# 🗣️ Banco de preguntas y libro de historias

> Los dos artefactos que se usan **a diario**, en los últimos 30 minutos de la
> jornada. El banco dice qué practicar; el libro guarda lo que ya sabes contar.
> Método y encaje en [`REPASO-03-METODO-36H.md`](REPASO-03-METODO-36H.md).

---

## 1. Cómo se usa el banco

Una pregunta al día. De pie, sin notas, cronómetro a dos minutos, en voz alta. Al
terminar, una marca:

| Marca | Significado | Qué pasa con la pregunta |
|---|---|---|
| ✅ | Clara, ordenada, dentro de tiempo | Vuelve dentro de un mes |
| 🌫️ | Sabía la respuesta, salió desordenada o larga | Vuelve en tres días |
| ❌ | No supe responderla | Al material, y vuelve mañana |

Una vez por semana, **grábate**. Escucharte corrige en cinco minutos lo que ningún
repaso corrige: el preámbulo de treinta segundos antes de contestar, las muletillas
y el rodeo cuando no estás seguro.

> 🧭 **La estructura de una buena respuesta de arquitectura tiene tres tiempos:**
> primero **preguntas por la restricción** que falta, después **decides y lo
> justificas**, y al final **dices qué pierdes con esa decisión**. El tercer tiempo
> es el que casi nadie da y el que te separa del resto.

---

## 2. El banco, semilla inicial

Las primeras preguntas, para empezar antes de que exista `repaso-arquitectura-entrevistas`.
Se numeran `P#` y crecen con cada entrevista: toda pregunta real que te hagan entra
aquí el mismo día, la hayas respondido bien o mal.

### Diseño y fronteras

- `P01` ¿Cómo dividirías este sistema en servicios? ¿Qué criterio usas?
- `P02` ¿Cuándo **no** separarías en microservicios? Dame tres razones concretas.
- `P03` ¿Qué es un contexto acotado y en qué se diferencia de un microservicio?
- `P04` ¿Qué es un agregado y cómo decides su tamaño?
- `P05` Hexagonal, limpia y cebolla: ¿en qué se diferencian de verdad?
- `P06` ¿Qué precio pagas por una arquitectura hexagonal? ¿Cuándo no compensa?
- `P07` ¿Qué es un modelo de dominio anémico y cuándo es aceptable?
- `P08` ¿Cómo migrarías un monolito sin parar el negocio?

### Patrones

- `P09` Tres patrones GoF que **no** usarías hoy, y por qué.
- `P10` ¿Dónde estás usando el patrón Proxy sin darte cuenta en Spring?
- `P11` Strategy contra un `switch`: ¿cuándo merece la pena?
- `P12` ¿Qué es Unit of Work y qué te lo da ya hecho?
- `P13` Repository de Fowler contra `JpaRepository` de Spring Data: ¿son lo mismo?

### Datos y consistencia

- `P14` Base de datos por servicio: ¿qué ganas y qué pierdes exactamente?
- `P15` Explica una saga. ¿Orquestada o coreografiada, y qué lo decide?
- `P16` ¿Qué haces si la compensación de una saga falla?
- `P17` ¿Qué es el patrón outbox y qué problema concreto resuelve?
- `P18` ¿Existe *exactly-once*? Explica qué se hace en la práctica.
- `P19` CQRS: ¿qué ventana de inconsistencia introduce y cómo se la explicas a negocio?

### Resiliencia y operación

- `P20` Un servicio del que dependes se degrada. ¿Qué pones, en qué orden?
- `P21` ¿Por qué el reintento sin jitter empeora una caída?
- `P22` Circuit breaker: sus tres estados y quién decide el paso entre ellos.
- `P23` Diferencia entre endpoint de salud y de disponibilidad. ¿Por qué son dos?
- `P24` ¿Qué es el presupuesto de error y para qué sirve en una discusión real?
- `P25` Tienes RTO de 4 h y RPO de 15 min. ¿Qué arquitectura implica eso?

### Escalado

- `P26` "Escalamos horizontalmente." ¿Qué tiene que ser cierto para que eso funcione?
- `P27` ¿Sobre qué métrica autoescalas y por qué no sobre CPU?
- `P28` Azul-verde, canario y rodante: cuándo cada uno.
- `P29` ¿Dónde está el estado de tu sistema? Enumera todos los sitios.

### Cloud

- `P30` Equivalencias AWS ⇄ GCP de los servicios que usas, **con la diferencia real**
  de cada una, no el mapeo de nombres.
- `P31` ¿Cómo controlas el coste de una arquitectura antes de desplegarla?
- `P32` ¿Qué te llevarías a gestionado y qué mantendrías tú, y con qué criterio?

### Las de siempre, que también se practican

- `P33` Háblame de una decisión técnica de la que te arrepientes.
- `P34` Cuéntame algo que hayas roto y cómo lo detectaste.
- `P35` ¿Cómo convences a un equipo que no está de acuerdo contigo?
- `P36` ¿Qué harías en tus primeros 90 días como arquitecto aquí?

---

## 3. El libro de historias

Una historia es un patrón **con algo que hiciste y un número detrás**. Es lo que
convierte "conozco el circuit breaker" en una respuesta de la que ya no se duda.

Regla de entrada: **cada lab del laboratorio y cada medición produce una historia**.
Si al terminar la semana no hay historia nueva, esa semana fue lectura.

### Plantilla

```markdown
### H## · <título corto, el que usarías al contarla>

**El patrón que ilustra:** circuit breaker / outbox / …
**Contexto (1 frase):**
**El problema, con su número:**
**Lo que hiciste:**
**El resultado, con su número:**
**Lo que te costó / lo que perdiste a cambio:**
**En 30 segundos:** ← la versión que dices primero
```

El último campo es el importante. Si no cabe en treinta segundos hablados, la
historia todavía no está lista: no se ha entendido lo bastante como para
comprimirla.

### Las historias que hay que tener sí o sí

Son las que cubren los arquetipos de pregunta más frecuentes. Si falta alguna,
sale del laboratorio.

| Arquetipo | Qué demuestra | De dónde sale |
|---|---|---|
| Algo que **rompiste** y detectaste | Que operas, no solo diseñas | `L3` — matar `catalog` bajo carga |
| Una **frontera que moviste** y su coste | Criterio de arquitecto | `L1` — puertos y adaptadores |
| Una **inconsistencia** que arreglaste | Consistencia distribuida entendida | `L2` — el fire-and-forget y el outbox |
| Un **escalado** que falló por estado | Alta disponibilidad real | `L4` |
| Una decisión en la que **elegiste no separar** | La más difícil de encontrar y la que más vale | Auditoría de `L0` |
| Un **número que contradijo** lo que esperabas | Honestidad técnica | Cualquiera; anótalo cuando pase |

> ⚠️ La quinta —"decidí no separar"— es la que a casi nadie se le ocurre preparar y
> la que mejor responde a la pregunta de si has diseñado o solo has implementado.

---

## 4. Registro de práctica

Una línea por sesión. Sirve para ver el patrón, no para llevar la cuenta.

```markdown
| Fecha | P# | Marca | Nota |
|---|---|---|---|
| 2026-09-14 | P05 | 🌫️ | Me fui a la historia de las tres arquitecturas en vez de responder la diferencia. Ir al grano en la primera frase |
```

Cuando la columna de notas repita el mismo comentario tres veces, eso —y no el
temario— es lo que hay que corregir.
EOF
wc -l REPASO-04-BANCO-Y-HISTORIAS.md

# --- 2026-09-12T20:18:22 · 
cd /Users/oskar/Developer/Learning/courses-ia-generated
python3 - <<'PY'
import re, io
p='PLAN-REFRESCAMIENTO.md'
s=open(p).read()

anchor="""Este documento no es un curso: es **el orden en que se recorre lo que ya existe y
lo que falta**, con su calendario. Se revisa cada vez que una entrevista aporte
información nueva.
"""
new=anchor+"""
Es una pieza de una familia de cuatro documentos más su índice; el resto está en
[`REPASO-00-INDICE.md`](REPASO-00-INDICE.md), que también explica por qué este
material está excluido del control de versiones mientras viva en un repositorio
público.
"""
assert anchor in s
s=s.replace(anchor,new,1)

old_method="""El método de tarjetas, intervalos y modo mantenimiento está en
[`go-for-java-devs/prompts/aprendizaje.md`](go-for-java-devs/prompts/aprendizaje.md)
— se escribió para Go y **aplica igual aquí**. Los seis tipos de tarjeta sirven tal
cual; solo cambian las fuentes."""
new_method="""El método completo —tarjetas, intervalos, reparto entre fuentes, bitácora y modo
mantenimiento— está en [`REPASO-03-METODO-36H.md`](REPASO-03-METODO-36H.md), que es
la versión a jornada completa del método de
[`go-for-java-devs/prompts/aprendizaje.md`](go-for-java-devs/prompts/aprendizaje.md).
La teoría del olvido y del espaciado sigue estando en aquel documento y no se
duplica."""
assert old_method in s
s=s.replace(old_method,new_method,1)

# §2 pointer to bases doc
old2="""El único material nuevo que este plan necesita, y el que desbloquea las tres primeras
semanas."""
new2="""El único material nuevo que este plan necesita, y el que desbloquea las tres primeras
semanas. Lo que sigue es el resumen; el esqueleto completo —formato, reglas,
contenido documento por documento, estructura de directorio y alcance mínimo si el
calendario aprieta— está en
[`REPASO-02-BASES-ARQUITECTURA.md`](REPASO-02-BASES-ARQUITECTURA.md)."""
assert old2 in s
s=s.replace(old2,new2,1)

# Semana 0 autopsia pointer
old3="""- **La autopsia de la entrevista que ya tuviste.** Tus puntos de mejora, uno por
  uno: ¿fue que no lo sabías, que no lo recordaste, o que no supiste decirlo? Las
  tres fallas tienen remedios distintos y conviene no confundirlas."""
new3="""- **La autopsia de la entrevista que ya tuviste.** Tus puntos de mejora, uno por
  uno: ¿fue que no lo sabías, que no lo recordaste, o que no supiste decirlo? Las
  tres fallas tienen remedios distintos y conviene no confundirlas. La plantilla y
  el mapa de huecos están en
  [`REPASO-01-AUTOPSIA-Y-HUECOS.md`](REPASO-01-AUTOPSIA-Y-HUECOS.md)."""
assert old3 in s
s=s.replace(old3,new3,1)

open(p,'w').write(s)
print("ok")
PY

# --- 2026-09-12T20:18:31 · 
cd /Users/oskar/Developer/Learning/courses-ia-generated
cat >> .gitignore <<'EOF'

# ============================================================
# Material personal de búsqueda de empleo (NO publicar)
# Destino: repositorio privado de entrevistas. Mientras tanto,
# la raíz de este repo es zona de preparación. Ver REPASO-00-INDICE.md
# ============================================================

PLAN-REFRESCAMIENTO.md
REPASO-*.md
EOF
git status --short
echo "--- comprobación: ¿los ignora? ---"
git check-ignore -v PLAN-REFRESCAMIENTO.md REPASO-00-INDICE.md REPASO-04-BANCO-Y-HISTORIAS.md

