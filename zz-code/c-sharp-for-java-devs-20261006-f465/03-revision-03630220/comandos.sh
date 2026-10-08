# Comandos Bash de la sesión 03630220-8285-47af-bd48-9f631cee549b, en orden. Una bitácora, no un script: no se corre entera.

# --- 2026-09-13T18:22:11 · Count lines and list prompts/src
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/c-sharp-for-java-devs && wc -l *.md && echo "--- PROMPTS ---" && ls -la prompts/ && echo "--- SRC ---" && ls src/

# --- 2026-09-13T18:22:16 · Search for cross-course references in markdown
grep -rniE "cursos-|curso de (angular|react|nosql|docker|python|java)|python-for-java|ruta-nosql|docker-container|angular|react|otro curso|curso hermano|curso vecino|propuestas-cursos|_oskar|\.\./" --include=*.md . | head -80

# --- 2026-09-13T18:22:19 · Search cross-course references
grep -rniE "cursos-|curso de (angular|react|nosql|docker|python|java)|python-for-java|ruta-nosql|docker-container|angular|react|otro curso|curso hermano|curso vecino|propuestas-cursos|_oskar|\.\./" --include="*.md" . | head -100

# --- 2026-09-13T18:22:23 · Read style guide section and scope
cd prompts && sed -n '630,690p' guia-de-estilo-y-convenciones.md && echo "=== ALCANCE 130-215 ===" && sed -n '130,215p' alcance-del-proyecto.md

# --- 2026-09-13T18:22:30 · Read README and structure doc
cd .. && cat README.md && echo "==================== ESTRUCTURA ====================" && cat 0-ESTRUCTURA-CURSO.md

# --- 2026-09-13T18:22:36 · Grep repo-level references in published files
grep -nE "repositorio|CLAUDE\.md|cursos-ia|curso hermano|otros cursos|otro curso" *.md | grep -v "^prompts/"

# --- 2026-09-13T18:22:49 · Inspect BENCHMARKS structure
head -80 BENCHMARKS.md; echo "======== IDs en BENCHMARKS ========"; grep -nE "^\|?\s*\*?\*?M[0-9]+|^#{2,4} .*M[0-9]+" BENCHMARKS.md | head -60

# --- 2026-09-13T18:22:55 · List headings of BENCHMARKS and INSTINTOS
grep -nE "^#{2,3} " BENCHMARKS.md; echo "=== INSTINTOS ==="; grep -nE "^#{2,3} " INSTINTOS.md

# --- 2026-09-13T18:23:01 · Read benchmark index and chapter template
sed -n '160,200p' BENCHMARKS.md; echo "=== PLANTILLA ==="; grep -nE "^#|^\|" prompts/plantillas-de-capitulo.md | head -60

# --- 2026-09-13T18:23:04 · List section headings of every phase
for f in 0[0-9]-*.md 1[0-9]-*.md 2[0-4]-*.md; do case "$f" in 00-convencion*) continue;; esac; echo "### $f"; grep -nE "^## " "$f" | sed 's/^/   /'; done

# --- 2026-09-13T18:23:11 · Inspect suspicious headings in phase 24
sed -n '330,380p' 24-veredicto-y-defensa.md; echo "-----555-600-----"; sed -n '552,600p' 24-veredicto-y-defensa.md

# --- 2026-09-13T18:23:16 · Tally domain figures
grep -nE "procedimientos|formularios|títulos|equipos|empleados|sellos|almacenes" *.md | grep -oE "[0-9][0-9.,]*[0-9]? (procedimientos|formularios|títulos|equipos|empleados|sellos|almacenes)" | sort | uniq -c | sort -rn

# --- 2026-09-13T18:23:20 · Check contexts for conflicting figures
grep -nE "69[0-9] procedimientos|700 procedimientos|11\.000|18\.000|33[0-9] formularios|340 formularios" *.md prompts/congelamiento-de-nombres.md prompts/alcance-del-proyecto.md prompts/historia-propuesta-1-cordillera.md

# --- 2026-09-13T18:23:28 · Compare form-count contexts
sed -n '240,255p' prompts/congelamiento-de-nombres.md; echo "=== 12:50-62 ==="; sed -n '50,62p' 12-winforms-en-net-10.md; echo "=== 14:52-62 ==="; sed -n '52,62p' 14-veredicto-del-escritorio.md; echo "=== 24:58-70 ==="; sed -n '58,70p' 24-veredicto-y-defensa.md; echo "=== 24:485-495 ==="; sed -n '485,495p' 24-veredicto-y-defensa.md

# --- 2026-09-13T18:23:36 · Find canonical forms list
grep -nE "formulario|FR[A-Z_]*|Form" prompts/congelamiento-de-nombres.md | head -50

# --- 2026-09-13T18:23:47 · Trace which forms the course actually writes
grep -nE "StockForm|formulario de existencias|Sige\.Forms" *.md | head -30; echo "=== 14 prototipos ==="; sed -n '195,240p' 14-veredicto-del-escritorio.md

# --- 2026-09-13T18:24:00 · Dump headers and closings for phases 00-06
for f in 00-ambiente*.md 01-*.md 02-*.md 03-*.md 04-*.md 05-*.md 06-*.md; do echo "########## $f"; sed -n '1,15p' "$f"; echo "   ...[cierre]..."; awk '/^## 🚀 10\./,/^## 📌/' "$f" | head -45; done

# --- 2026-09-13T18:24:13 · Grep spelled-out counts
grep -rnE "veinticinco|veinticuatro|veintitrés|veintitres" *.md | grep -viE "^prompts" 

# --- 2026-09-13T18:24:40 · Extract all phase header metadata lines
grep -hnE "^> C# para desarrolladores|^> Depende de:|^> Estilo de esta fase|^> Proyecto que avanza" 0*.md 1*.md 2*.md | grep -v convencion

# --- 2026-09-13T18:24:45 · Check phase 20 closing
awk '/^## 🚀 10\./,/^## 📌/' 20-contenedor-y-la-factura.md | head -25

# --- 2026-09-13T18:24:56 · List debt markers across phases
grep -nE "💸" *.md | grep -viE "^(INSTINTOS|BENCHMARKS)" | sed 's/\(.\{200\}\).*/\1/' | head -80

# --- 2026-09-13T18:25:02 · Debts 15-24 and internal doc references
grep -nE "💸" 1[5-9]-*.md 2[0-4]-*.md | sed 's/\(.\{190\}\).*/\1/'; echo "=== libro de deudas §7.1 ==="; grep -nE "§7\.1|§8\.1|propuesta-fases|libro de deudas" *.md

# --- 2026-09-13T18:25:18 · Check the archive-age figure
grep -rnE "4[5-8] años|cuarenta y (seis|siete|cinco|ocho)|1979|desde 1979" *.md | sed 's/\(.\{170\}\).*/\1/'

# --- 2026-09-13T18:25:28 · Inventory character mentions
grep -ohrE "\b(Wilson|Duván|Ximena|Nohora|Gustavo|Clara|Fernando|Fabio|Almenara|Convivir|SIGE)\b" *.md | sort | uniq -c; echo "=== roles ==="; grep -rhnoE "(Wilson|Duván|Ximena|Nohora|Gustavo|Clara|don Fernando)[^.。]{0,70}" *.md | sed -E 's/^[0-9]+://' | sort -u | head -70

# --- 2026-09-13T18:25:37 · Version consistency audit
echo "--- SDK ---"; grep -rhoE "10\.0\.[0-9]+" *.md | sort | uniq -c
echo "--- EF Core / libs ---"; grep -rhoE "(EF Core|Dapper|xUnit[^ ]*|Testcontainers|NSubstitute|BenchmarkDotNet|Serilog|Polly)[ v]*[0-9]+\.[0-9]+\.[0-9]+" *.md | sort | uniq -c
echo "--- C#/Java/VS ---"; grep -rhoE "(C# [0-9.]+|Java [0-9]+( LTS)?|Visual Studio [A-Za-z]* ?[0-9]+(, [0-9.]+)?|SQL Server [0-9]+|\.NET Framework [0-9.]+|\.NET [0-9]+)" *.md | sort | uniq -c | sort -rn | head -40

# --- 2026-09-13T18:25:41 · Locate version outliers
grep -rn "10\.0\.4[^0]" *.md | head; echo "=== 4.5 ==="; grep -rn "Framework 4\.5" *.md; echo "=== xunit ==="; grep -rniE "xunit[^ ]* ?v?[0-9]" *.md | sed 's/\(.\{150\}\).*/\1/' | head -20

# --- 2026-09-13T18:25:46 · Validate relative markdown links
grep -ohE "\]\(([^)h][^)]*)\)" *.md | sed -E 's/^\]\(//; s/\)$//' | sed 's/#.*//' | sort -u | while read -r l; do [ -z "$l" ] && continue; [ -e "$l" ] || echo "ROTO: $l"; done

# --- 2026-09-13T18:25:52 · Verify exercise counts
for f in 0[0-9]-*.md 1[0-9]-*.md 2[0-4]-*.md; do case "$f" in 00-convencion*) continue;; esac; d=$(grep -oE "^## 🧪 8\. Ejercicios \(([0-9]+)\)" "$f" | grep -oE "[0-9]+"); n=$(awk '/^## 🧪 8\./{f=1;next} /^## 📚 9\./{f=0} f' "$f" | grep -cE "^[0-9]+\. "); echo "$f  declarado=$d  contados=$n"; done

# --- 2026-09-13T18:25:58 · Verify git tags in each phase
for i in $(seq -w 0 24); do f=$(ls ${i}-*.md 2>/dev/null | grep -v convencion); [ -z "$f" ] && continue; t1=$(grep -c "git tag -a fase-$i" "$f"); t2=$(grep -c "git tag -a mini-$i" "$f"); echo "F$i  fase-tag=$t1 mini-tag=$t2  $f"; done

# --- 2026-09-13T18:26:04 · Inspect src layout
find src -maxdepth 3 | head -60; echo "=== slnx ==="; cat src/Cordillera.slnx 2>/dev/null | head -40; echo "=== global.json ==="; cat src/global.json

# --- 2026-09-13T18:26:13 · Closings for phases 07-14
for f in 07-*.md 08-*.md 09-*.md 10-*.md 11-*.md 12-*.md 13-*.md 14-*.md; do echo "########## $f"; awk '/^## 🚀 10\./{f=1} /^> 🏷️/{exit} f' "$f" | head -30; done

# --- 2026-09-13T18:26:19 · Check desktop options count in phase 14
grep -nE "Blazor Hybrid|tres tecnologías|cuatro opciones|WinUI 3" 14-veredicto-del-escritorio.md | sed 's/\(.\{160\}\).*/\1/' | head -30

# --- 2026-09-13T18:26:30 · Read the F14 verdict table
sed -n '336,460p' 14-veredicto-del-escritorio.md

# --- 2026-09-13T18:26:37 · Read the four options list
sed -n '63,90p' 14-veredicto-del-escritorio.md

# --- 2026-09-13T18:26:42 · Closings for phases 15-23
for f in 15-*.md 16-*.md 17-*.md 18-*.md 19-*.md 21-*.md 22-*.md 23-*.md; do echo "########## $f"; awk '/^## 🚀 10\./{f=1} /^> 🏷️/{exit} f' "$f" | tail -n +2 | head -22; done

# --- 2026-09-13T18:26:50 · Sweep recurring domain quantities
for k in "cuatro segundos" "seis horas" "1.900" "500.000" "50.000" "400 manuscritos" "treinta tablas" "cuatro módulos" "noventa equipos" "cuatro sellos" "tres oficinas" "26.000" "26.400" "4.100"; do echo "--- $k ---"; grep -rhoE ".{55}$k.{45}" *.md | sort -u | head -6; done

# --- 2026-09-13T18:26:57 · Check recurring story details
grep -rniE "incidente de marzo|traductor externo|dos años de acceso|hora cinco|seis horas|cuatro segundos|1\.900|400 manuscritos" *.md | sed 's/\(.\{155\}\).*/\1/' | sort -t: -k1,1 | head -60

# --- 2026-09-13T18:27:05 · Check employee count in story doc
grep -nE "empleados|340" prompts/historia-propuesta-1-cordillera.md | head -12

# --- 2026-09-13T18:27:17 · Read phase 24 consolidation section
sed -n '380,445p' 24-veredicto-y-defensa.md

# --- 2026-09-13T18:27:28 · Read exact text around cross-course references
sed -n '58,72p' 21-datos-y-onnx.md; echo "=== 22 ==="; sed -n '64,72p' 22-ia-aplicada.md; echo "=== EST 125,130 ==="; sed -n '125,131p' 0-ESTRUCTURA-CURSO.md; echo "=== EST 200,206 ==="; sed -n '200,206p' 0-ESTRUCTURA-CURSO.md; echo "=== 24:70,76 ==="; sed -n '68,78p' 24-veredicto-y-defensa.md; echo "=== 24:788,798 ==="; sed -n '788,798p' 24-veredicto-y-defensa.md

# --- 2026-09-13T18:27:41 · Remove cross-course and repo-level references
python3 - <<'PY'
import io,re
def rep(path, pairs):
    s=io.open(path,encoding='utf-8').read()
    for a,b in pairs:
        assert s.count(a)==1, (path, a, s.count(a))
        s=s.replace(a,b)
    io.open(path,'w',encoding='utf-8').write(s)

rep('21-datos-y-onnx.md', [(
"""- **Teoría de aprendizaje automático.** Declarado fuera y con destino: para eso está `cursos-ia` en este
  repositorio. Aquí entra la canalización de datos, el servicio de la predicción y **la evaluación honesta** —
  que es lo que le toca a quien escribe el sistema.""",
"""- **Teoría de aprendizaje automático.** Declarado fuera, y es un tema con bibliografía propia. Aquí entra la
  canalización de datos, el servicio de la predicción y **la evaluación honesta** — que es lo que le toca a
  quien escribe el sistema.""")])

rep('22-ia-aplicada.md', [(
"""- **Afinado de modelos y entrenamiento.** Declarado fuera, con destino: `cursos-ia` en este repositorio. Aquí
  entra usar un modelo, no producirlo.""",
"""- **Afinado de modelos y entrenamiento.** Declarado fuera, y es un tema con bibliografía propia. Aquí entra
  usar un modelo, no producirlo.""")])

rep('0-ESTRUCTURA-CURSO.md', [
("""> 📝 **Sobre el tiempo:** el curso **no publica horas por fase**, a diferencia de otros cursos del
> repositorio. Lo único que estima es el miniproyecto, **de dos a cinco horas**, porque es lo que""",
 """> 📝 **Sobre el tiempo:** el curso **no publica horas por fase**, y es una decisión tomada a
> propósito. Lo único que estima es el miniproyecto, **de dos a cinco horas**, porque es lo que"""),
("""**Y no se corrigieron**, por la regla de bloqueo de contenido del `CLAUDE.md` del repositorio: una vez
publicado un curso, renombrar fases y reordenar bloques rompe el material y los enlaces de quien ya lo
está leyendo.""",
 """**Y no se corrigieron**, por la regla de bloqueo de contenido que este curso se impone: una vez
publicado, renombrar fases y reordenar bloques rompe el material y los enlaces de quien ya lo
está leyendo."""),
])

rep('24-veredicto-y-defensa.md', [
("""  reordenar el curso ahora rompería el material publicado, y la regla de bloqueo de contenido del repositorio
  existe precisamente para eso.""",
 """  reordenar el curso ahora rompería el material publicado, y la regla de bloqueo de contenido que este curso
  se impone existe precisamente para eso."""),
("""  regla de bloqueo de contenido del `CLAUDE.md`, que conviene citar explícitamente para que no parezca pereza.""",
 """  regla de bloqueo de contenido, que conviene citar explícitamente para que no parezca pereza."""),
])
print("ok")
PY

# --- 2026-09-13T18:27:48 · Locate two numeric fixes
grep -n "Cuarenta y seis" 0-ESTRUCTURA-CURSO.md; grep -n "diecinueve fases anteriores" 20-contenedor-y-la-factura.md

# --- 2026-09-13T18:27:54 · Fix phase chain and archive age
python3 - <<'PY'
import io
def rep(path, pairs, expect=1):
    s=io.open(path,encoding='utf-8').read()
    for a,b,n in pairs:
        assert s.count(a)==n, (path, a, s.count(a))
        s=s.replace(a,b)
    io.open(path,'w',encoding='utf-8').write(s)

# 1. cadena de fases rota en la F20
rep('20-contenedor-y-la-factura.md', [
  ("> Depende de: 11, 15, 16, 17, 18, 19 · Habilita: 24",
   "> Depende de: 11, 15, 16, 17, 18, 19 · Habilita: 21", 1),
  ("las diecinueve fases anteriores", "las veinte fases anteriores", 3),
])

# 2. la edad del archivo de contratos: 47 años en todo el curso
rep('0-ESTRUCTURA-CURSO.md', [
  ("| 5 | **AcervoRAG** | Cuarenta y seis años de contratos",
   "| 5 | **AcervoRAG** | Cuarenta y siete años de contratos", 1),
])
print("ok")
PY
grep -n "Habilita: 21" 20-contenedor-y-la-factura.md; grep -n "Cuarenta y siete" 0-ESTRUCTURA-CURSO.md

# --- 2026-09-13T18:28:03 · Normalize form counts to 339
python3 - <<'PY'
import io
def rep(path, pairs):
    s=io.open(path,encoding='utf-8').read()
    for a,b,n in pairs:
        assert s.count(a)==n, (path, a, s.count(a))
        s=s.replace(a,b)
    io.open(path,'w',encoding='utf-8').write(s)

rep('12-winforms-en-net-10.md', [(
"""- **Los otros 339 formularios.** Se cuentan como historia: el curso construye tres —este, su versión WPF y
  el prototipo de la fase 14— y el reflejo que el lector se lleva es **no tocar los otros 337 sin motivo**.""",
"""- **Los otros 339 formularios.** Se cuentan como historia: el curso toca **uno** —este, que la fase 13 rehace
  en WPF y la 14 vuelve a levantar como prototipo— y el reflejo que el lector se lleva es **no tocar los otros
  339 sin motivo**.""", 1)])

rep('24-veredicto-y-defensa.md', [
("- **Los 336 formularios restantes, los 690 procedimientos y el módulo de inventario de Lima.**",
 "- **Los 339 formularios restantes, los 690 procedimientos y el módulo de inventario de Lima.**", 1),
("| Lo que no se migró | inventario, \"el Fox\", Crystal Reports, 690 procedimientos, 336 formularios |",
 "| Lo que no se migró | inventario, \"el Fox\", Crystal Reports, 690 procedimientos, 339 formularios |", 1),
])
print("ok")
PY
grep -rn "33[0-9] formularios" *.md

# --- 2026-09-13T18:28:10 · Align frozen-names doc with 339
cd prompts && python3 - <<'PY'
import io
p='congelamiento-de-nombres.md'
s=io.open(p,encoding='utf-8').read()
a="> 🧭 **Regla 2 de la guía §11 aplicada aquí.** Los otros 690 procedimientos, los 336 formularios"
b="> 🧭 **Regla 2 de la guía §11 aplicada aquí.** Los otros 690 procedimientos, los 339 formularios"
assert s.count(a)==1
io.open(p,'w',encoding='utf-8').write(s.replace(a,b))
print('ok')
PY

# --- 2026-09-13T18:28:14 · Re-list all veinticinco occurrences
cd .. && grep -n "veinticinco" README.md BENCHMARKS.md 24-veredicto-y-defensa.md 0-ESTRUCTURA-CURSO.md | sed 's/\(.\{175\}\).*/\1/'

# --- 2026-09-13T18:28:33 · Normalize measurement count to 24
python3 - <<'PY'
import io
def fix(path, edits):
    lines=io.open(path,encoding='utf-8').read().split('\n')
    for ln,a,b in edits:
        i=ln-1
        assert a in lines[i], (path, ln, lines[i])
        lines[i]=lines[i].replace(a,b)
    io.open(path,'w',encoding='utf-8').write('\n'.join(lines))

fix('README.md', [(144,'Y las veinticinco mediciones se publican','Y las veinticuatro mediciones se publican')])

fix('BENCHMARKS.md', [
 (191,'**consolida las veinticinco**','**consolida las veinticuatro**'),
 (1585,'el estado de las veinticinco','el estado de las veinticuatro'),
 (1603,'Las veinticinco tablas','Las veinticuatro tablas'),
 (1612,'aplicado a las veinticinco entradas','aplicado a las veinticuatro entradas'),
])

fix('0-ESTRUCTURA-CURSO.md', [
 (199,'usa una sola vez en veinticinco entradas','usa una sola vez en veinticuatro entradas'),
])

fix('24-veredicto-y-defensa.md', [
 (45,'las veinticinco entradas revisadas','las veinticuatro entradas revisadas'),
 (169,'exactamente una vez en veinticinco entradas','exactamente una vez en veinticuatro entradas'),
 (380,'consolida las veinticinco','consolida las veinticuatro'),
 (383,'consolidar las veinticinco anteriores','consolidar las veinticuatro anteriores'),
 (389,'// Veinticinco entradas escritas','// Veinticuatro entradas escritas'),
 (428,'veinticinco entradas,','veinticuatro entradas,'),
 (429,'> veinticinco sin ejecutar','> veinticuatro sin ejecutar'),
 (432,'Las veinticinco tablas','Las veinticuatro tablas'),
 (437,'> veinticinco mediciones son expectativas','> veinticuatro mediciones son expectativas'),
 (485,'`BENCHMARKS.md`, 25 entradas','`BENCHMARKS.md`, 24 entradas'),
 (655,'Ejecuta las veinticinco mediciones','Ejecuta las veinticuatro mediciones'),
 (713,'Las cifras de las veinticinco mediciones','Las cifras de las veinticuatro mediciones'),
 (726,'Las veinticinco mediciones están escritas','Las veinticuatro mediciones están escritas'),
 (794,'las veinticinco tablas están en ⏳','las veinticuatro tablas están en ⏳'),
 (797,'veinticinco entradas — y conviene','veinticuatro entradas — y conviene'),
])
print('ok')
PY
grep -n "veinticinco" README.md BENCHMARKS.md 24-veredicto-y-defensa.md 0-ESTRUCTURA-CURSO.md | sed 's/\(.\{120\}\).*/\1/'

# --- 2026-09-13T18:28:41 · Verify rewritten passages read correctly
sed -n '426,438p' 24-veredicto-y-defensa.md; echo "=== BENCH 1598,1618 ==="; sed -n '1598,1618p' BENCHMARKS.md

# --- 2026-09-13T18:28:51 · Final verification sweep
echo "== cross-curso restante en material publicado =="; grep -nE "cursos-ia|cursos-[a-z]+|CLAUDE\.md|otros cursos del repositorio|curso hermano|python-for-java|ruta-nosql" *.md
echo "== enlaces =="; grep -ohE "\]\(([^)h][^)]*)\)" *.md | sed -E 's/^\]\(//; s/\)$//' | sed 's/#.*//' | sort -u | while read -r l; do [ -z "$l" ] && continue; [ -e "$l" ] || echo "ROTO: $l"; done
echo "== cadena de fases =="; grep -h "^> Depende de:" *.md | sort

# --- 2026-09-13T18:29:08 · List cross-course references in prompts
cd prompts && grep -nE "cursos-ia|cursos-[a-z]|curso hermano|cursos de Angular|cursos de legacy|python-for-java|otros cursos|CLAUDE\.md|repositorio tiene" *.md | sed 's/\(.\{175\}\).*/\1/'

# --- 2026-09-13T18:29:21 · Read prompts passages to rewrite
sed -n '3,10p' historia-propuesta-1-cordillera.md; echo "=== alcance 141-150 ==="; sed -n '141,150p' alcance-del-proyecto.md; echo "=== alcance 176-182 ==="; sed -n '176,182p' alcance-del-proyecto.md; echo "=== alcance 201,206 ==="; sed -n '201,206p' alcance-del-proyecto.md; echo "=== guia 505,513 ==="; sed -n '505,513p' guia-de-estilo-y-convenciones.md; echo "=== mini 3,8 / 36,42 ==="; sed -n '3,8p' formato-de-miniproyectos.md; sed -n '36,42p' formato-de-miniproyectos.md

# --- 2026-09-13T18:29:44 · Clean cross-course references in prompts
python3 - <<'PY'
import io
def rep(path,pairs):
    s=io.open(path,encoding='utf-8').read()
    for a,b in pairs:
        assert s.count(a)==1,(path,a,s.count(a))
        s=s.replace(a,b)
    io.open(path,'w',encoding='utf-8').write(s)

rep('historia-propuesta-1-cordillera.md',[(
"""> **Estado:** candidata principal. Esta historia nació como propuesta para el curso de Python
> y se reencuadró completa hacia el ecosistema Microsoft; la versión Python **queda viva y
> utilizable** en `python-for-java-devs/prompts/historia-propuesta-1-cordillera.md`, aparcada
> para una edición posterior con otra cohorte. Este documento ya no la menciona: es la
> historia de C#, entera y por sí sola.""",
"""> **Estado:** candidata principal. Esta historia se reencuadró completa hacia el ecosistema
> Microsoft y este documento es el resultado: la historia de C#, entera y por sí sola.""")])

rep('alcance-del-proyecto.md',[
("""Decisión cerrada, heredada del curso hermano de Python y confirmada aquí.

En los cursos de Angular del repositorio, el material de consulta —el ambiente, las
herramientas, el puente entre versiones— vive en apéndices `aNN-`. **Aquí no.** Todo lo que en
otro curso sería un apéndice es, en este, **una fase o una sección de una fase**.""",
 """Decisión cerrada.

Lo habitual es que el material de consulta —el ambiente, las herramientas, el puente entre
versiones— viva en apéndices `aNN-`. **Aquí no.** Todo lo que en otro curso sería un apéndice
es, en este, **una fase o una sección de una fase**."""),
("""  mecanismo principal de consolidación del curso y sustituye al cuaderno de incidentes de los
  cursos de legacy del repositorio. Su formato está en""",
 """  mecanismo principal de consolidación del curso y sustituye al cuaderno de incidentes que
  sería habitual en un curso de sistemas heredados. Su formato está en"""),
("""- **Teoría de aprendizaje automático.** El repositorio tiene `cursos-ia`. Aquí entra la IA
  **aplicada**, con evaluación seria, y el resto se enlaza declarando la exclusión.""",
 """- **Teoría de aprendizaje automático.** Es un tema con bibliografía propia. Aquí entra la IA
  **aplicada**, con evaluación seria, y el resto se enlaza declarando la exclusión."""),
])

rep('guia-de-estilo-y-convenciones.md',[(
"""- **Cantidad: 20 mínimo, 25 ideal por fase.** El curso invierte en el miniproyecto lo que los
  cursos de legacy del repositorio invierten en volumen de ejercicios, y eso está declarado
  como divergencia: la banda del repositorio es 20-30, y aquí se usa la mitad baja a propósito.""",
"""- **Cantidad: 20 mínimo, 25 ideal por fase.** El curso invierte en el miniproyecto lo que otro
  curso invertiría en volumen de ejercicios, y eso está declarado como divergencia: la banda de
  referencia es 20-30, y aquí se usa la mitad baja a propósito.""")])

rep('formato-de-miniproyectos.md',[
("""mecanismo principal de consolidación del curso: ocupa el lugar que en los cursos de legacy del
repositorio ocupa el cuaderno de incidentes.""",
 """mecanismo principal de consolidación del curso: ocupa el lugar que en un curso de sistemas
heredados ocuparía el cuaderno de incidentes."""),
("""Los cursos de legacy del repositorio enseñan a **arreglar** un sistema que ya existe, y por eso
su unidad de práctica es el incidente: un síntoma, una reproducción, una causa raíz.""",
 """Un curso de sistemas heredados enseña a **arreglar** un sistema que ya existe, y por eso su
unidad de práctica es el incidente: un síntoma, una reproducción, una causa raíz."""),
])

rep('propuesta-fases-y-alcance.md',[
("""miniproyecto ocupa el lugar del cuaderno de incidentes de los cursos de legacy; el avance de""",
 """miniproyecto ocupa el lugar del cuaderno de incidentes de un curso de sistemas heredados; el avance de"""),
("""**El curso tiene una restricción que ningún otro del repositorio tiene: no puede apagar el""",
 """**El curso tiene una restricción que casi ningún curso se impone: no puede apagar el"""),
("""**No entra:** orquestación avanzada, declarada fuera; el repositorio tiene un curso para eso.""",
 """**No entra:** orquestación avanzada, declarada fuera; es una especialidad con material propio."""),
("""**No entra:** teoría de aprendizaje automático, y se declara — el repositorio tiene `cursos-ia`.""",
 """**No entra:** teoría de aprendizaje automático, y se declara — es un tema con bibliografía propia."""),
("""material. Es divergencia declarada frente a los cursos de Angular del repositorio, que sí las""",
 """material. Es divergencia declarada frente a la práctica habitual de otros cursos, que sí las"""),
])
print('ok')
PY
grep -nE "cursos-ia|cursos de (Angular|legacy)|curso hermano|python-for-java|otro del repositorio" *.md

# --- 2026-09-13T18:29:52 · Tighten self-containment rule and verify
python3 - <<'PY'
import io
p='guia-de-estilo-y-convenciones.md'
s=io.open(p,encoding='utf-8').read()
a="""- **Autocontención.** El curso no remite a otros cursos del repositorio como material
  necesario. Puede enlazarlos como profundización opcional, declarándolo — y en particular
  **no nombra al curso hermano de Python**, con el que comparte el origen de la historia de
  Cordillera pero ninguna dependencia."""
b="""- **Autocontención.** El curso no remite a ningún otro curso como material necesario, ni
  siquiera para nombrarlo. Lo que haga falta se explica aquí o se enlaza a documentación
  oficial; nada del material publicado supone que el lector tenga acceso a otra cosa."""
assert s.count(a)==1
io.open(p,'w',encoding='utf-8').write(s.replace(a,b))
print('ok')
PY
cd .. && grep -rnE "cursos-ia|cursos de (Angular|legacy)|curso hermano|python-for-java|otros cursos del repositorio" . --include="*.md"; echo "(sin resultados = limpio)"

# --- 2026-09-13T18:29:58 · Review edited passages
git -C /Users/oskar/Developer/Learning/courses-ia-generated diff --stat 2>/dev/null; echo "--- untracked, así que diff vacío es esperado ---"; grep -c "" README.md >/dev/null; echo "== relectura de pasajes editados =="; sed -n '141,147p' prompts/alcance-del-proyecto.md; echo "..."; sed -n '55,60p' 12-winforms-en-net-10.md

# --- 2026-09-13T18:39:25 · Find all CLAUDE.md references
grep -rn "CLAUDE\.md" . --include="*.md"

# --- 2026-09-13T18:39:31 · Read context around every CLAUDE.md mention
cd prompts && sed -n '25,32p' README.md; echo "--- 124,130 ---"; sed -n '124,130p' README.md; echo "=== prompts-de-fase 24,34 ==="; sed -n '24,34p' prompts-de-fase.md; echo "=== propuesta 13,17 ==="; sed -n '13,17p' propuesta-fases-y-alcance.md; echo "=== propuesta 1285,1291 ==="; sed -n '1285,1291p' propuesta-fases-y-alcance.md; echo "=== como-escribir 22,32 ==="; sed -n '22,32p' como-escribir-el-curso.md; echo "=== guia 644,652 ==="; sed -n '644,652p' guia-de-estilo-y-convenciones.md; echo "=== congelamiento 547,554 ==="; sed -n '547,554p' congelamiento-de-nombres.md; echo "=== mediciones 93,99 ==="; sed -n '93,99p' formato-de-mediciones.md

# --- 2026-09-13T18:39:46 · Remove all CLAUDE.md references
python3 - <<'PY'
import io
def rep(path,pairs):
    s=io.open(path,encoding='utf-8').read()
    for a,b in pairs:
        assert s.count(a)==1,(path,a,s.count(a))
        s=s.replace(a,b)
    io.open(path,'w',encoding='utf-8').write(s)

rep('README.md',[
("""> escritorio después de la web—. **No se corrigieron**, por la regla de bloqueo de contenido del
> `CLAUDE.md`, y quedan escritas como errores documentados también en `0-ESTRUCTURA-CURSO.md` §4.""",
 """> escritorio después de la web—. **No se corrigieron**, por la regla de bloqueo de contenido que
> este curso se impone, y quedan escritas como errores documentados también en
> `0-ESTRUCTURA-CURSO.md` §4."""),
("| `alcance-del-proyecto.md` | Encuadre, versiones, plataforma e inventario de nube | Todo salvo el `CLAUDE.md` del repositorio |",
 "| `alcance-del-proyecto.md` | Encuadre, versiones, plataforma e inventario de nube | Todo salvo las instrucciones del proyecto |"),
])

rep('prompts-de-fase.md',[
("1. El `CLAUDE.md` del repositorio.",
 "1. Las instrucciones del proyecto."),
])

rep('propuesta-fases-y-alcance.md',[
("""> corrigieron**, por la regla de bloqueo de contenido del `CLAUDE.md`.""",
 """> corrigieron**, por la regla de bloqueo de contenido que este curso se impone."""),
("""escriben, llevan su propio prefijo de dos letras según la convención del `CLAUDE.md` del
repositorio.""",
 """escriben, llevan su propio prefijo de dos letras, que es la convención de nombres de este
curso."""),
])

rep('como-escribir-el-curso.md',[
("""**Orden de autoridad**, cuando dos se contradigan: (1) el `CLAUDE.md` del repositorio,
(2) `alcance-del-proyecto.md`,""",
 """**Orden de autoridad**, cuando dos se contradigan: (1) las instrucciones del proyecto,
(2) `alcance-del-proyecto.md`,"""),
])

rep('guia-de-estilo-y-convenciones.md',[
("""- **Fuentes de verdad, en este orden:** (1) instrucciones del proyecto y el `CLAUDE.md` del
  repositorio, (2) `alcance-del-proyecto.md`,""",
 """- **Fuentes de verdad, en este orden:** (1) las instrucciones del proyecto,
  (2) `alcance-del-proyecto.md`,"""),
])

rep('congelamiento-de-nombres.md',[
("""  extensión. Es la convención del `CLAUDE.md` del repositorio.""",
 """  extensión. Es la convención de nombres de este curso."""),
])

rep('formato-de-mediciones.md',[
("""> cambio que la regla de bloqueo de contenido del `CLAUDE.md` del repositorio existe para impedir.""",
 """> cambio que la regla de bloqueo de contenido de este curso existe para impedir."""),
])
print('ok')
PY
cd .. && grep -rn "CLAUDE\.md" . --include="*.md"; echo "(vacío = limpio)"

# --- 2026-09-13T18:39:51 · Check leftovers and links
grep -rnE "del repositorio|repositorio tiene" prompts/*.md | sed 's/\(.\{150\}\).*/\1/'; echo "== enlaces =="; grep -ohE "\]\(([^)h][^)]*)\)" *.md prompts/*.md | sed -E 's/^\]\(//; s/\)$//' | sed 's/#.*//' | sort -u | while read -r l; do [ -z "$l" ] && continue; [ -e "$l" ] || [ -e "prompts/$l" ] || echo "ROTO: $l"; done; echo "(vacío = ok)"

# --- 2026-09-13T18:39:58 · Read remaining repo-authority passages
cd prompts && sed -n '43,47p' como-escribir-el-curso.md; echo "--- 122,126 ---"; sed -n '122,126p' como-escribir-el-curso.md; echo "=== guia 418,424 ==="; sed -n '418,424p' guia-de-estilo-y-convenciones.md; echo "=== historia 306,312 ==="; sed -n '306,312p' historia-propuesta-1-cordillera.md; echo "=== propuesta 22,28 ==="; sed -n '22,28p' propuesta-fases-y-alcance.md; echo "=== propuesta 1244,1250 ==="; sed -n '1244,1250p' propuesta-fases-y-alcance.md

# --- 2026-09-13T18:40:08 · Clean remaining repo-authority phrasing and verify
python3 - <<'PY'
import io
def rep(path,pairs):
    s=io.open(path,encoding='utf-8').read()
    for a,b in pairs:
        assert s.count(a)==1,(path,a,s.count(a))
        s=s.replace(a,b)
    io.open(path,'w',encoding='utf-8').write(s)

rep('como-escribir-el-curso.md',[
("3. Los documentos del marco, o la instrucción de leerlos del repositorio.",
 "3. Los documentos del marco, o la instrucción de leerlos."),
("""que la citen. Ninguna versión se da por buena de memoria: es la regla del repositorio y no tiene
excepción.""",
 """que la citen. Ninguna versión se da por buena de memoria: es una regla del curso y no tiene
excepción."""),
])

rep('guia-de-estilo-y-convenciones.md',[
("""Micro-secciones con nombre fijo, que aparecen cuando el contenido las pide. Las cuatro
primeras son las del repositorio y **son obligatorias donde la fase las pida**:""",
 """Micro-secciones con nombre fijo, que aparecen cuando el contenido las pide. Las cuatro
primeras son las canónicas y **son obligatorias donde la fase las pida**:"""),
])

rep('historia-propuesta-1-cordillera.md',[
("""contenedores. Pero tampoco puede ser un folleto. La regla es la del resto del repositorio:
**cada servicio gestionado""",
 """contenedores. Pero tampoco puede ser un folleto. La regla del curso es una sola:
**cada servicio gestionado"""),
])

rep('propuesta-fases-y-alcance.md',[
("""Cuatro rasgos que lo separan de sus hermanos del repositorio, y que explican casi todas las
decisiones de abajo.""",
 """Cuatro rasgos que lo separan de un curso de lenguaje corriente, y que explican casi todas las
decisiones de abajo."""),
("""da por buena de memoria: es la regla del repositorio y no tiene excepción.""",
 """da por buena de memoria: es una regla del curso y no tiene excepción."""),
])
print('ok')
PY
cd .. && grep -rnE "CLAUDE\.md|del repositorio|repositorio tiene|cursos-|curso hermano|hermanos" . --include="*.md" | grep -viE "repositorio de (ejecuciones|dotnet)" | sed 's/\(.\{140\}\).*/\1/'

# --- 2026-09-13T18:40:13 · Read last two sibling references
cd prompts && sed -n '205,210p' alcance-del-proyecto.md; echo "---"; sed -n '26,32p' propuesta-fases-y-alcance.md

# --- 2026-09-13T18:40:20 · Final cleanup and verification
python3 - <<'PY'
import io
def rep(path,pairs):
    s=io.open(path,encoding='utf-8').read()
    for a,b in pairs:
        assert s.count(a)==1,(path,a,s.count(a))
        s=s.replace(a,b)
    io.open(path,'w',encoding='utf-8').write(s)

rep('alcance-del-proyecto.md',[(
"""  heredado que después se migra— igual que los cursos hermanos, y por la misma razón: quien
  lee código ajeno no distingue decisión de accidente.""",
"""  heredado que después se migra—, y la razón es concreta: quien lee código ajeno no distingue
  decisión de accidente.""")])

rep('propuesta-fases-y-alcance.md',[(
"""estructura de Java— y el de arquitectura —reescribirlo todo o no tocar nada—. Los cursos
hermanos atacan uno; este ataca los dos, y por eso tiene un bloque de lenguaje *y* un bloque de
sistema heredado.""",
"""estructura de Java— y el de arquitectura —reescribirlo todo o no tocar nada—. Un curso de
lenguaje ataca uno; este ataca los dos, y por eso tiene un bloque de lenguaje *y* un bloque de
sistema heredado.""")])
print('ok')
PY
cd .. && grep -rnE "CLAUDE\.md|cursos hermanos|curso hermano|cursos-[a-z]|otros cursos" . --include="*.md"; echo "(vacío = limpio)"

# --- 2026-09-13T18:40:25 · Re-verify links
grep -ohE "\]\(([^)h][^)]*)\)" *.md prompts/*.md | sed -E 's/^\]\(//; s/\)$//' | sed 's/#.*//' | sort -u | while read -r l; do [ -z "$l" ] && continue; [ -e "$l" ] || [ -e "prompts/$l" ] || echo "ROTO: $l"; done; echo "enlaces ok"

# --- 2026-09-13T18:43:08 · Find all exercise-band declarations
cd prompts && grep -n "20-30\|20 mínimo\|25 ideal\|20-25\|banda" *.md | sed 's/\(.\{170\}\).*/\1/'

# --- 2026-09-13T18:43:22 · Make the exercise band self-justified
python3 - <<'PY'
import io
def rep(path,pairs):
    s=io.open(path,encoding='utf-8').read()
    for a,b in pairs:
        assert s.count(a)==1,(path,a,s.count(a))
        s=s.replace(a,b)
    io.open(path,'w',encoding='utf-8').write(s)

rep('guia-de-estilo-y-convenciones.md',[(
"""- **Cantidad: 20 mínimo, 25 ideal por fase.** El curso invierte en el miniproyecto lo que otro
  curso invertiría en volumen de ejercicios, y eso está declarado como divergencia: la banda de
  referencia es 20-30, y aquí se usa la mitad baja a propósito.""",
"""- **Cantidad: la banda de este curso es 20 mínimo, 25 ideal por fase**, y la razón está en el
  presupuesto de horas del lector y no en una costumbre heredada. Una fase se consolida con **el
  miniproyecto**, que pide de dos a cinco horas; los ejercicios lo preparan y lo repasan, no
  compiten con él. Pasar de 25 obliga a rellenar con variaciones del mismo problema —que es lo
  que un dev Java senior abandona en el ejercicio 14— y bajar de 20 deja reflejos de la fase sin
  un ejercicio que los ataque. **Veinticinco es el techo, no la meta:** una fase con 22 bien
  calibrados está mejor que una con 25 donde tres son relleno.""")])

rep('propuesta-fases-y-alcance.md',[(
"| Práctica por fase | **Un miniproyecto obligatorio**, difícil | Sustituye al cuaderno de incidentes; los ejercicios bajan a 20-25 |",
"| Práctica por fase | **Un miniproyecto obligatorio**, difícil | Sustituye al cuaderno de incidentes; los ejercicios se quedan en la banda propia de 20-25 |")])
print('ok')
PY
cd .. && sed -n '505,516p' prompts/guia-de-estilo-y-convenciones.md

# --- 2026-09-13T18:43:29 · Verify band and actual counts
grep -rn "20-30\|banda del repositorio\|costumbre heredada" . --include="*.md"; echo "--- conteos reales por fase ---"; for f in 0[0-9]-*.md 1[0-9]-*.md 2[0-4]-*.md; do case "$f" in 00-convencion*) continue;; esac; grep -oE "^## 🧪 8\. Ejercicios \([0-9]+\)" "$f" | grep -oE "\([0-9]+\)"; done | sort | uniq -c

# --- 2026-09-13T19:10:26 · Verification batch 1
echo "=== 1. Referencias a otros cursos / repo externo ==="
grep -rnE "CLAUDE\.md|cursos-[a-z]|curso hermano|cursos hermanos|otros cursos del|cursos de (Angular|legacy|Python|React)|python-for-java|ruta-nosql|docker-container|propuestas-cursos|_oskar|del repositorio" . --include="*.md" | grep -viE "SDK del repositorio|archivo del repositorio|raíz del repositorio|árbol del repositorio|subárbol del repositorio" || echo "  ✅ ninguna"
echo
echo "=== 2. Enlaces relativos ==="
grep -ohE "\]\(([^)h][^)]*)\)" *.md prompts/*.md | sed -E 's/^\]\(//; s/\)$//' | sed 's/#.*//' | sort -u | while read -r l; do [ -z "$l" ] && continue; [ -e "$l" ] || [ -e "prompts/$l" ] || echo "  ❌ ROTO: $l"; done; echo "  ✅ todos resuelven"
echo
echo "=== 3. Cadena Depende/Habilita ==="
python3 - <<'PY'
import re,glob,io
ok=True
for f in sorted(glob.glob('[0-9][0-9]-*.md')):
    if 'convencion' in f: continue
    n=int(f[:2]); s=io.open(f,encoding='utf-8').read()
    m=re.search(r'> Depende de: (.+?) · Habilita: (.+)', s)
    dep,hab=m.group(1).strip(),m.group(2).strip()
    exp_h = 'ninguna' if n==24 else f'{n+1:02d}'
    exp_d = 'ninguna' if n==0 else None
    if hab!=exp_h: print(f'  ❌ F{n:02d} Habilita={hab} esperado {exp_h}'); ok=False
    if n>0 and f'{n-1:02d}' not in dep: print(f'  ❌ F{n:02d} Depende={dep} no incluye {n-1:02d}'); ok=False
    fm=re.search(r'Fase (\d+) de 24', s)
    if int(fm.group(1))!=n: print(f'  ❌ F{n:02d} cabecera dice Fase {fm.group(1)}'); ok=False
print('  ✅ cadena 00→24 completa y cabeceras correctas' if ok else '')
PY

# --- 2026-09-13T19:10:38 · Verification batch 2
echo "=== 4. BENCHMARKS: una entrada por fase 00-23 + consolidación ==="
grep -cE "^## 📐 F[0-9]{2} ·" BENCHMARKS.md | xargs echo "  entradas 📐:"; grep -cE "^## 🧮 F24" BENCHMARKS.md | xargs echo "  consolidación 🧮:"
python3 - <<'PY'
import re,io
s=io.open('BENCHMARKS.md',encoding='utf-8').read()
ids=[int(m) for m in re.findall(r'^## 📐 F(\d{2}) ·', s, re.M)]
print('  ✅ F00–F23 sin huecos ni duplicados' if ids==list(range(24)) else f'  ❌ {ids}')
idx=re.findall(r'^\| (\d{2}) \| ', s, re.M)
print('  ✅ índice con 25 filas, una por fase' if [int(i) for i in idx]==list(range(25)) else f'  ❌ índice: {idx}')
PY
echo
echo "=== 5. Cada fase tiene su §6 Medición y su 🧱 §7 ==="
for f in $(ls [0-9][0-9]-*.md | grep -v convencion); do a=$(grep -c "^## 📏 6\." $f); b=$(grep -c "^## 🧱 7\." $f); [ "$a$b" = "11" ] || echo "  ❌ $f  medicion=$a mini=$b"; done; echo "  ✅ las 25"
echo
echo "=== 6. INSTINTOS: enlaces 'Desarrollado en' ==="
grep -oE "\[fase [0-9]+\]\([0-9]+-[a-z0-9-]+\.md\)" INSTINTOS.md | sort -u | while read -r r; do n=$(echo "$r"|grep -oE "fase [0-9]+"|grep -oE "[0-9]+"); fl=$(echo "$r"|grep -oE "[0-9]+-[a-z0-9-]+\.md"); case "$fl" in $(printf %02d $n)-*) ;; *) echo "  ❌ $r";; esac; done; echo "  ✅ cada reflejo apunta a su fase"

# --- 2026-09-13T19:10:51 · Verification batch 3
echo "=== 7. Ejercicios: declarado vs real, dentro de la banda 20-25 ==="
for f in $(ls [0-9][0-9]-*.md|grep -v convencion); do d=$(grep -oE "^## 🧪 8\. Ejercicios \([0-9]+\)" $f|grep -oE "[0-9]+$"); n=$(awk '/^## 🧪 8\./{f=1;next}/^## 📚 9\./{f=0}f' $f|grep -cE "^[0-9]+\. "); [ "$d" = "$n" ] && [ "$d" -ge 20 ] && [ "$d" -le 25 ] || echo "  ❌ $f decl=$d real=$n"; done; echo "  ✅ las 25 coinciden y caen en 20-25"
echo
echo "=== 8. Tags ==="
for i in $(seq -w 0 24); do f=$(ls ${i}-*.md 2>/dev/null|grep -v convencion); [ $(grep -c "git tag -a fase-$i" $f) = 1 ] && [ $(grep -c "git tag -a mini-$i" $f) = 1 ] || echo "  ❌ F$i"; done; echo "  ✅ fase-NN y mini-NN en las 25"
echo
echo "=== 9. Cifras del dominio ==="
grep -rhoE "[0-9][0-9.]*[0-9]? (procedimientos|formularios|títulos|equipos|empleados)" *.md | sort | uniq -c | sort -rn
echo "  -- años de contratos --"; grep -rhoE "(4[0-9] años|[Cc]uarenta y [a-z]+ años)" *.md | sort | uniq -c
echo
echo "=== 10. Conteos escritos ==="
grep -rhoE "veinticinco (fases|mediciones|entradas|tablas|documentos|miniproyectos)|veinticuatro (fases|mediciones|entradas|tablas)" *.md | sort | uniq -c

# --- 2026-09-13T19:11:04 · Fix exercise check and list project progression
echo "=== 7bis. Ejercicios ==="
for f in $(ls [0-9][0-9]-*.md|grep -v convencion); do d=$(sed -nE 's/^## 🧪 8\. Ejercicios \(([0-9]+)\)/\1/p' $f); n=$(awk '/^## 🧪 8\./{f=1;next}/^## 📚 9\./{f=0}f' $f|grep -cE "^[0-9]+\. "); if [ "$d" != "$n" ] || [ "$d" -lt 20 ] || [ "$d" -gt 25 ]; then echo "  ❌ $f decl=$d real=$n"; fi; done; echo "  ✅ declarado = real, y todo en 20-25"
echo
echo "=== 11. 'Proyecto que avanza' vs tabla de 0-ESTRUCTURA ==="
for f in $(ls [0-9][0-9]-*.md|grep -v convencion); do printf "F%s  " ${f:0:2}; grep -m1 "^> Proyecto que avanza:" $f | sed -E 's/^> Proyecto que avanza: //' | cut -c1-70; done

# --- 2026-09-13T19:11:14 · Inventory src and its declared role
find src -type f | sed 's/^/  /'; echo "=== qué dice el curso sobre src/fases ==="; grep -rn "src/fases\|src\\\\fases" *.md prompts/*.md | sed 's/\(.\{140\}\).*/\1/' | head -20

# --- 2026-09-13T19:11:29 · Check solution files and empty dirs
grep -rn "Sige.sln\|Cordillera.slnx" *.md | sed 's/\(.\{150\}\).*/\1/'; echo "=== dirs vacíos en src ==="; find src -type d -empty

# --- 2026-09-13T19:11:43 · Check gitignore and where Sige.sln is created
cat .gitignore; echo "=== F00 210,235 ==="; sed -n '210,235p' 00-ambiente-visual-studio-y-ecosistema.md; echo "=== F07: crea Sige.sln? ==="; grep -n "Sige.sln\|solución heredada\|\.sln" 07-el-sistema-que-heredas.md | sed 's/\(.\{140\}\).*/\1/'

# --- 2026-09-13T19:11:54 · Read legacy project GUIDs
grep -iE "ProjectGuid|AssemblyName|RootNamespace|TargetFrameworkVersion|OutputType" src/legacy/Sige.DataAccess/Sige.DataAccess.csproj src/legacy/Sige.Forms/Sige.Forms.csproj; echo "=== refs entre proyectos ==="; grep -A3 -i "ProjectReference" src/legacy/Sige.Forms/Sige.Forms.csproj

# --- 2026-09-13T19:12:07 · Create the missing legacy solution and keep placeholders
cat > src/Sige.sln <<'EOF'
Microsoft Visual Studio Solution File, Format Version 12.00
# Visual Studio 15
VisualStudioVersion = 15.0.28307.905
MinimumVisualStudioVersion = 10.0.40219.1
Project("{FAE04EC0-301F-11D3-BF4B-00C04F79EFBC}") = "Sige.DataAccess", "legacy\Sige.DataAccess\Sige.DataAccess.csproj", "{7F3A9C21-4E8B-4D6A-9C15-2B7E0A4F1D93}"
EndProject
Project("{FAE04EC0-301F-11D3-BF4B-00C04F79EFBC}") = "Sige.Forms", "legacy\Sige.Forms\Sige.Forms.csproj", "{3E9D1F84-77C2-4A6B-9E01-5D8B3C2A7F16}"
EndProject
Global
	GlobalSection(SolutionConfigurationPlatforms) = preSolution
		Debug|Any CPU = Debug|Any CPU
		Release|Any CPU = Release|Any CPU
	EndGlobalSection
	GlobalSection(ProjectConfigurationPlatforms) = postSolution
		{7F3A9C21-4E8B-4D6A-9C15-2B7E0A4F1D93}.Debug|Any CPU.ActiveCfg = Debug|Any CPU
		{7F3A9C21-4E8B-4D6A-9C15-2B7E0A4F1D93}.Debug|Any CPU.Build.0 = Debug|Any CPU
		{7F3A9C21-4E8B-4D6A-9C15-2B7E0A4F1D93}.Release|Any CPU.ActiveCfg = Release|Any CPU
		{7F3A9C21-4E8B-4D6A-9C15-2B7E0A4F1D93}.Release|Any CPU.Build.0 = Release|Any CPU
		{3E9D1F84-77C2-4A6B-9E01-5D8B3C2A7F16}.Debug|Any CPU.ActiveCfg = Debug|Any CPU
		{3E9D1F84-77C2-4A6B-9E01-5D8B3C2A7F16}.Debug|Any CPU.Build.0 = Debug|Any CPU
		{3E9D1F84-77C2-4A6B-9E01-5D8B3C2A7F16}.Release|Any CPU.ActiveCfg = Release|Any CPU
		{3E9D1F84-77C2-4A6B-9E01-5D8B3C2A7F16}.Release|Any CPU.Build.0 = Release|Any CPU
	EndGlobalSection
	GlobalSection(SolutionProperties) = preSolution
		HideSolutionNode = FALSE
	EndGlobalSection
EndGlobal
EOF
for d in src/fases/*/demo src/fases/*/mini; do [ -d "$d" ] && [ -z "$(ls -A $d)" ] && touch "$d/.gitkeep"; done
find src -maxdepth 1 -type f | sort; echo "--- placeholders ---"; find src/fases -name .gitkeep

# --- 2026-09-13T19:12:17 · Final verification
echo "=== VERIFICACIÓN FINAL ==="
echo "-- referencias externas --"
grep -rnE "CLAUDE\.md|cursos-[a-z]|curso(s)? hermano|otros cursos del|python-for-java|ruta-nosql|propuestas-cursos|_oskar" . --include="*.md" || echo "   ✅ cero"
echo "-- enlaces --"
grep -ohE "\]\(([^)h][^)]*)\)" *.md prompts/*.md | sed -E 's/^\]\(//; s/\)$//' | sed 's/#.*//' | sort -u | while read -r l; do [ -z "$l" ] && continue; [ -e "$l" ] || [ -e "prompts/$l" ] || echo "   ❌ $l"; done; echo "   ✅ todos resuelven"
echo "-- rutas de src citadas en las fases --"
grep -rhoE "src[\\\\/][A-Za-z0-9._\\\\/-]+" *.md | tr '\\' '/' | sed 's#/$##' | sort -u | while read -r p; do case "$p" in *Bench.Cli*|*Cordillera.Domain*|*Cordillera.Ops*|*Sige.Desktop*|*Sige.Billing*|*modern/Sige.Forms*|*duelo*|*datos-generados*) continue;; esac; [ -e "$p" ] || echo "   ⚠️  no existe aún: $p"; done | sort -u | head -20
echo "-- estructura --"
ls [0-9]*.md | wc -l | xargs echo "   documentos numerados:"; echo "   ✅ 25 fases + convención de git"

# --- 2026-09-13T19:12:25 · Check the App.config discrepancy
grep -rn "Sige.Forms/App.config\|Sige.Forms\\\\App.config" *.md | sed 's/\(.\{150\}\).*/\1/'; echo "=== lo que F07 escribe ==="; grep -n "App.config" 07-el-sistema-que-heredas.md | sed 's/\(.\{150\}\).*/\1/'; echo "=== App.config existente ==="; cat src/legacy/Sige.DataAccess/App.config

# --- 2026-09-13T19:12:35 · Read both App.config diff commands
sed -n '111,128p' 00-convencion-de-git-y-tags.md; echo "=== 16: 876,890 ==="; sed -n '876,890p' 16-identidad-secretos-y-configuracion.md; echo "=== 16: 278,292 ==="; sed -n '278,292p' 16-identidad-secretos-y-configuracion.md

# --- 2026-09-13T19:12:43 · Fix App.config path and check Cordillera.Data
python3 - <<'PY'
import io
p='00-convencion-de-git-y-tags.md'
s=io.open(p,encoding='utf-8').read()
a="git diff fase-07 fase-16 -- src/legacy/Sige.Forms/App.config"
b="git diff fase-07 fase-16 -- src/legacy/Sige.DataAccess/App.config"
assert s.count(a)==1
io.open(p,'w',encoding='utf-8').write(s.replace(a,b))
print('ok')
PY
echo "=== el otro diff del doc de convención vs la F09 ==="
grep -n "Cordillera.Data" *.md | sed 's/\(.\{150\}\).*/\1/'

# --- 2026-09-13T19:12:54 · Confirm the canonical F02→F09 diff command
sed -n '932,942p' 09-acceso-a-datos-esquema-hostil.md; echo "--- F02 ---"; sed -n '531,538p' 02-nullable-y-pattern-matching.md

# --- 2026-09-13T19:12:58 · Align convention doc example with the phases
python3 - <<'PY'
import io
p='00-convencion-de-git-y-tags.md'
s=io.open(p,encoding='utf-8').read()
a="git diff fase-02 fase-09 -- src/modern/Cordillera.Data/"
b="git diff fase-02 fase-09 -- src/fases/02-nullable-y-pattern-matching/"
assert s.count(a)==1
io.open(p,'w',encoding='utf-8').write(s.replace(a,b))
print('ok')
PY
sed -n '115,124p' 00-convencion-de-git-y-tags.md

# --- 2026-09-13T19:13:05 · Audit all debt git diff commands
echo "=== todos los git diff de deuda ==="; grep -rhoE "git diff fase-[0-9]+ fase-[0-9]+ -- [^\`\"]*" *.md | sed 's/ *$//' | sort -u
echo
echo "=== rutas citadas en comentarios de código (// src/... o <!-- src/...) ==="
grep -rhoE "(//|<!--) src/[A-Za-z0-9._/-]+\.(cs|csproj|xaml|config|props|json|sql|razor)" *.md | sed -E 's#^(//|<!--) ##' | sort -u | wc -l | xargs echo "  rutas distintas:"

# --- 2026-09-13T19:13:11 · Check the F14 to F18 diff commands
grep -rn -B4 -A4 "git diff fase-14 fase-18" *.md | sed 's/\(.\{160\}\).*/\1/'

# --- 2026-09-13T19:13:17 · Read F14 closing block
sed -n '740,762p' 14-veredicto-del-escritorio.md

# --- 2026-09-13T19:13:24 · Fix the F14/F18 retroactive-update contradiction
python3 - <<'PY'
import io
p='14-veredicto-del-escritorio.md'
s=io.open(p,encoding='utf-8').read()
a="""> **Y esta fase deja algo que ningún tag puede cerrar: una tabla incompleta a propósito.** Es la única
> actualización retroactiva que el curso permite, y está declarada en los dos sitios. Cuando la fase 18
> rellene la columna, `git diff fase-14 fase-18 -- 14-veredicto-del-escritorio.md` va a mostrar **un
> documento publicado que cambia porque llegó un dato**, y eso es lo más parecido que un curso puede
> ofrecer a cómo se decide de verdad."""
b="""> **Y esta fase deja algo que ningún tag puede cerrar: una tabla incompleta a propósito.** Es la única
> actualización retroactiva que el curso permite, y está declarada en los dos sitios. Cuando la fase 18
> rellene la columna, `git diff fase-14 fase-18 -- BENCHMARKS.md` va a mostrar **una celda que pasa de 🔜
> a ⏳ porque llegó un dato**, y eso es lo más parecido que un curso puede ofrecer a cómo se decide de
> verdad. El cambio entra en la entrada consolidada y **no en este documento**, que es la regla de §6: una
> fase no reescribe el material publicado de otra."""
assert s.count(a)==1
io.open(p,'w',encoding='utf-8').write(s.replace(a,b))
print('ok')
PY
grep -rhoE "git diff fase-14 fase-18 -- [^\`]*" *.md | sort -u

# --- 2026-09-13T19:13:43 · Full closing verification
echo "=== CIERRE: verificación completa ==="
p=0
echo "1. Referencias externas:"; grep -rnE "CLAUDE\.md|cursos-[a-z]|curso(s)? hermano|otros cursos del|python-for-java|propuestas-cursos|_oskar" . --include="*.md" >/dev/null 2>&1 && { grep -rnE "CLAUDE\.md|cursos-[a-z]" . --include="*.md"; p=1; } || echo "   ✅ cero"
echo "2. Enlaces:"; n=$(grep -ohE "\]\(([^)h][^)]*)\)" *.md prompts/*.md | sed -E 's/^\]\(//;s/\)$//;s/#.*//' | sort -u | while read -r l; do [ -z "$l" ]||[ -e "$l" ]||[ -e "prompts/$l" ]||echo x; done | wc -l); [ "$n" = 0 ] && echo "   ✅ todos resuelven" || { echo "   ❌ $n rotos"; p=1; }
echo "3. Cadena 00→24:"; python3 -c "
import re,glob,io,sys
bad=0
for f in sorted(glob.glob('[0-9][0-9]-*.md')):
    if 'convencion' in f: continue
    n=int(f[:2]); s=io.open(f,encoding='utf-8').read()
    m=re.search(r'> Depende de: (.+?) · Habilita: (.+)',s)
    e='ninguna' if n==24 else '%02d'%(n+1)
    if m.group(2).strip()!=e: bad+=1
print('   ✅ sin huecos' if not bad else '   ❌ %d'%bad)"
echo "4. Ejercicios (decl=real, 20-25):"; b=0; for f in $(ls [0-9][0-9]-*.md|grep -v convencion); do d=$(sed -nE 's/^## 🧪 8\. Ejercicios \(([0-9]+)\)/\1/p' $f); n=$(awk '/^## 🧪 8\./{f=1;next}/^## 📚 9\./{f=0}f' $f|grep -cE "^[0-9]+\. "); { [ "$d" = "$n" ] && [ "$d" -ge 20 ] && [ "$d" -le 25 ]; } || b=$((b+1)); done; [ $b = 0 ] && echo "   ✅ las 25" || echo "   ❌ $b"
echo "5. Tags fase-NN/mini-NN:"; b=0; for i in $(seq -w 0 24); do f=$(ls ${i}-*.md|grep -v convencion); { [ $(grep -c "git tag -a fase-$i" $f) = 1 ] && [ $(grep -c "git tag -a mini-$i" $f) = 1 ]; } || b=$((b+1)); done; [ $b = 0 ] && echo "   ✅ las 25" || echo "   ❌ $b"
echo "6. BENCHMARKS F00–F23 + consolidación:"; python3 -c "
import re,io
s=io.open('BENCHMARKS.md',encoding='utf-8').read()
i=[int(m) for m in re.findall(r'^## 📐 F(\d{2}) ·',s,re.M)]
print('   ✅ 24 entradas + F24' if i==list(range(24)) and '## 🧮 F24' in s else '   ❌')"
echo "7. Plantilla de 10 secciones:"; b=0; for f in $(ls [0-9][0-9]-*.md|grep -v convencion); do for k in "🎯 1\." "✅ 2\." "🚫 3\." "🧠 4\." "💻 5\." "📏 6\." "🧱 7\." "🧪 8\." "📚 9\." "🚀 10\."; do grep -qE "^## $k" $f || b=$((b+1)); done; done; [ $b = 0 ] && echo "   ✅ las 25, en orden" || echo "   ❌ $b faltantes"
echo "8. git diff de deudas, rutas únicas por deuda:"; grep -rhoE "git diff fase-[0-9]+ fase-[0-9]+ -- [^\`\"]*" *.md | sed 's/ -->$//;s/ *$//' | sort | uniq -c | awk '$1>0{print "   "$0}' | head -30

# --- 2026-09-13T19:14:02 · Read the declared final src structure
sed -n '495,540p' prompts/congelamiento-de-nombres.md

# --- 2026-09-13T19:14:08 · Remove duplicated tree entry
cd prompts && python3 - <<'PY'
import io
p='congelamiento-de-nombres.md'
s=io.open(p,encoding='utf-8').read()
a="""    Cordillera.Catalog.Api/       ← CatalogAPI · nace en la F09
    Cordillera.Data/              ← el borde 🧬 · nace en la F09
    Cordillera.Ops/"""
b="""    Cordillera.Catalog.Api/       ← CatalogAPI · nace en la F09
    Cordillera.Ops/"""
assert s.count(a)==1
io.open(p,'w',encoding='utf-8').write(s.replace(a,b))
print('ok')
PY
grep -c "Cordillera.Data/  " congelamiento-de-nombres.md | xargs echo "Cordillera.Data en el árbol:"

# --- 2026-09-13T19:41:03 · Find all references to the phase 00 filename
cd .. && grep -rn "00-ambiente-visual-studio-y-ecosistema" . --include="*.md" | sed 's/\(.\{130\}\).*/\1/'; echo "--- en src ---"; find src -name "*ambiente*"

# --- 2026-09-13T19:41:10 · Rename phase 00 and update references
mv 00-ambiente-visual-studio-y-ecosistema.md 00-instalacion-ambiente-visual-studio-y-ecosistema.md
mv src/fases/00-ambiente-visual-studio-y-ecosistema src/fases/00-instalacion-ambiente-visual-studio-y-ecosistema
grep -rl "00-ambiente-visual-studio-y-ecosistema" . --include="*.md" | while read -r f; do
  python3 - "$f" <<'PY'
import sys,io
p=sys.argv[1]; s=io.open(p,encoding='utf-8').read()
io.open(p,'w',encoding='utf-8').write(s.replace('00-ambiente-visual-studio-y-ecosistema','00-instalacion-ambiente-visual-studio-y-ecosistema'))
PY
done
echo "--- verificación ---"; grep -rn "00-ambiente-visual-studio-y-ecosistema" . --include="*.md" || echo "  ✅ sin referencias viejas"
grep -rn "00-instalacion-ambiente" . --include="*.md" | sed 's/\(.\{140\}\).*/\1/'; find src -name "*ambiente*"

# --- 2026-09-13T19:41:16 · Check current state of phase 00 file
pwd; ls -1 *.md | head -5; ls 00-*.md

# --- 2026-09-13T19:41:29 · Check state and references to the story doc
ls prompts/ ; echo "=== referencias a la historia ==="; grep -rn "historia-propuesta-1-cordillera\|historia-cordillera\|historia-propuesta-cordillera" . --include="*.md" | sed 's/\(.\{150\}\).*/\1/'; echo "=== cabecera del archivo movido ==="; head -20 00-historia-propuesta-cordillera.md

# --- 2026-09-13T19:41:43 · Compare with the other non-phase 00 document
head -12 00-convencion-de-git-y-tags.md; echo "=== secciones de la historia ==="; grep -nE "^#{1,2} " 00-historia-propuesta-cordillera.md

# --- 2026-09-13T19:41:54 · Reframe story doc as published material
python3 - <<'PY'
import io
p='00-historia-propuesta-cordillera.md'
s=io.open(p,encoding='utf-8').read()
a="""# 🏔️ Propuesta de historia 1 — Cordillera Media

> Empresa ficticia candidata para el curso *C# para desarrolladores Java senior*.
>
> **Estado:** candidata principal. Esta historia se reencuadró completa hacia el ecosistema
> Microsoft y este documento es el resultado: la historia de C#, entera y por sí sola.
"""
b="""# 🏔️ Cordillera Media, la empresa del curso
## C# para desarrolladores Java senior

Documento de consulta, y **la fuente de verdad de todo lo narrativo**: la empresa, su sistema, sus
personajes, sus cifras y su cronología. Cuando una fase nombra a alguien, cita un año o usa un
número del negocio, sale de aquí — y si una fase y este documento se contradicen, gana este
documento y la fase se corrige.

Cordillera Media es ficticia, y conviene decirlo una vez: nada de lo que sigue describe a una
editorial real. Pero ninguna de sus incomodidades está inventada para que el curso quede bonito.
Cada decisión rara del sistema tiene un año y una razón que era correcta ese año, y esa es la
diferencia entre enseñar migración y burlarse del código heredado.
"""
assert s.count(a)==1
io.open(p,'w',encoding='utf-8').write(s.replace(a,b))
print('ok')
PY
head -14 00-historia-propuesta-cordillera.md

# --- 2026-09-13T19:44:33 · Check current file state
ls -1 0*.md; echo "--- prompts ---"; ls prompts/

# --- 2026-09-13T19:44:36 · Verify reframed header survived and list pending refs
head -14 00-historia-de-cordillera.md; echo "=== referencias pendientes ==="; grep -rn "historia-propuesta-1-cordillera\|historia-propuesta-cordillera" . --include="*.md" | sed 's/\(.\{140\}\).*/\1/'

# --- 2026-09-13T19:44:49 · Update all story-doc references in prompts
python3 - <<'PY'
import io,glob
OLD='historia-propuesta-1-cordillera.md'
NEW='00-historia-de-cordillera.md'
tot=0
for p in glob.glob('prompts/*.md'):
    s=io.open(p,encoding='utf-8').read(); o=s
    s=s.replace(f']({OLD})', f'](../{NEW})')          # enlaces: suben un nivel
    s=s.replace(f'prompts/{OLD}', NEW)                # ya no vive en prompts/
    s=s.replace(OLD, NEW)                             # menciones sueltas
    if s!=o:
        io.open(p,'w',encoding='utf-8').write(s); tot+=1
        print(f'  {p}')
print(f'{tot} archivos')
PY
echo "=== verificación ==="; grep -rn "historia-propuesta" . --include="*.md" || echo "  ✅ sin referencias viejas"
grep -rn "00-historia-de-cordillera" . --include="*.md" | sed 's/\(.\{145\}\).*/\1/'

# --- 2026-09-13T19:44:59 · Read the places that must now link the story
sed -n '270,285p' 0-ESTRUCTURA-CURSO.md; echo "=== README empresa ==="; sed -n '90,110p' README.md; echo "=== prompts/README 40,56 ==="; sed -n '40,56p' prompts/README.md; echo "=== prompts/README 120,140 ==="; sed -n '120,140p' prompts/README.md

# --- 2026-09-13T19:45:14 · Wire the story doc into the published material
python3 - <<'PY'
import io
def rep(path,pairs):
    s=io.open(path,encoding='utf-8').read()
    for a,b in pairs:
        assert s.count(a)==1,(path,a[:60],s.count(a))
        s=s.replace(a,b)
    io.open(path,'w',encoding='utf-8').write(s)

# 1. La historia entra en el índice de documentos de consulta del curso
rep('0-ESTRUCTURA-CURSO.md',[(
"""## 📚 7. Los documentos que acompañan a las fases

- **[`00-convencion-de-git-y-tags.md`](00-convencion-de-git-y-tags.md)** — commits, tags de fase y""",
"""## 📚 7. Los documentos que acompañan a las fases

- **[`00-historia-de-cordillera.md`](00-historia-de-cordillera.md)** — la empresa: su genealogía
  desde 1988, quién es quién, las cifras del negocio y la fecha de cada decisión incómoda del
  sistema. Es la fuente de verdad de todo lo narrativo, y se lee **antes que la fase 00**: las
  veinticinco fases dan por sabido quién es Duván y por qué el esquema se congeló en 1997.
- **[`00-convencion-de-git-y-tags.md`](00-convencion-de-git-y-tags.md)** — commits, tags de fase y""")])

# 2. El README enlaza la historia desde la sección de la empresa
rep('README.md',[(
"""Aquí nadie es el villano. Wilson no es desarrollador y nunca dijo que lo fuera; Duván sostiene
solo, desde hace nueve años, algo que no diseñó; y los tres pasantes hicieron en once meses lo
que nadie más quiso hacer.""",
"""Aquí nadie es el villano. Wilson no es desarrollador y nunca dijo que lo fuera; Duván sostiene
solo, desde hace nueve años, algo que no diseñó; y los tres pasantes hicieron en once meses lo
que nadie más quiso hacer.

La historia completa —la genealogía del sistema de 1988 a 2026, quién es quién, las cifras del
negocio y la fecha de cada decisión incómoda— está en
[`00-historia-de-cordillera.md`](00-historia-de-cordillera.md), y conviene leerla **antes de la
fase 00**: las veinticinco fases la dan por sabida.""")])

# 3. prompts/README: el documento ya no vive aquí, y hay que decirlo
rep('prompts/README.md',[
("""4. **[`00-historia-de-cordillera.md`](../00-historia-de-cordillera.md)** — la empresa del
   curso. Fuente de verdad de todo lo narrativo: personajes, cifras, cronología, reglas de negocio
   y la deuda técnica del sistema, con su fecha.""",
 """4. **[`00-historia-de-cordillera.md`](../00-historia-de-cordillera.md)** — la empresa del
   curso. Fuente de verdad de todo lo narrativo: personajes, cifras, cronología, reglas de negocio
   y la deuda técnica del sistema, con su fecha. **Es el único de estos documentos que vive fuera
   de `prompts/`**, en la raíz del curso, porque dejó de ser maquinaria: el lector lo lee.""" ),
("| `00-historia-de-cordillera.md` | La empresa del curso | Todo lo narrativo |",
 "| `../00-historia-de-cordillera.md` | La empresa del curso · **publicado, en la raíz** | Todo lo narrativo |"),
])
print('ok')
PY

# --- 2026-09-13T19:45:24 · Check remaining mentions of the story doc
grep -rn "historia" prompts/prompts-de-documentos-de-encuadre.md prompts/como-escribir-el-curso.md prompts/congelamiento-de-nombres.md | sed 's/\(.\{150\}\).*/\1/'

# --- 2026-09-13T19:45:28 · Read the como-escribir table row
sed -n '16,26p' prompts/como-escribir-el-curso.md

# --- 2026-09-13T19:45:36 · Final verification of both moves
python3 - <<'PY'
import io
p='prompts/como-escribir-el-curso.md'
s=io.open(p,encoding='utf-8').read()
a="| [`00-historia-de-cordillera.md`](../00-historia-de-cordillera.md) | La empresa: personajes, cifras, cronología, deuda técnica | Siempre que el material toque el dominio |"
b="| [`../00-historia-de-cordillera.md`](../00-historia-de-cordillera.md) | La empresa: personajes, cifras, cronología, deuda técnica · **publicado, en la raíz del curso** | Siempre que el material toque el dominio |"
assert s.count(a)==1
io.open(p,'w',encoding='utf-8').write(s.replace(a,b))
print('ok')
PY
echo "=== VERIFICACIÓN ==="
echo "1. Referencias viejas:"; grep -rn "historia-propuesta\|00-ambiente-visual-studio" . --include="*.md" || echo "   ✅ ninguna"
echo "2. Enlaces relativos (raíz y prompts):"
for f in *.md; do grep -ohE "\]\(([^)h][^)]*)\)" "$f" | sed -E 's/^\]\(//;s/\)$//;s/#.*//' | while read -r l; do [ -z "$l" ] || [ -e "$l" ] || echo "   ❌ $f → $l"; done; done
for f in prompts/*.md; do grep -ohE "\]\(([^)h][^)]*)\)" "$f" | sed -E 's/^\]\(//;s/\)$//;s/#.*//' | while read -r l; do [ -z "$l" ] || [ -e "prompts/$l" ] || echo "   ❌ $f → $l"; done; done
echo "   ✅ todos resuelven"
echo "3. Orden alfabético de los archivos publicados:"; ls -1 *.md

# --- 2026-09-13T20:02:45 · Verification batch 1
echo "════ 1. REFERENCIAS A OTROS CURSOS / REPO ════"
grep -rnE "CLAUDE\.md|cursos-[a-z]|curso(s)? hermano|otros cursos del|cursos de (Angular|legacy|Python|React|Go)|python-for-java|ruta-nosql|docker-container|propuestas-cursos|_oskar|del repositorio|repositorio tiene" . --include="*.md" \
 | grep -viE "SDK del repositorio|archivo del repositorio|raíz del repositorio|árbol del repositorio|subárbol del repositorio|Fuera del repositorio|fuera del repositorio" || echo "  ✅ cero"
echo
echo "════ 2. ENLACES ════"
b=0; for f in *.md; do for l in $(grep -ohE "\]\(([^)h][^)]*)\)" "$f" | sed -E 's/^\]\(//;s/\)$//;s/#.*//'); do [ -e "$l" ] || { echo "  ❌ $f → $l"; b=1; }; done; done
for f in prompts/*.md; do for l in $(grep -ohE "\]\(([^)h][^)]*)\)" "$f" | sed -E 's/^\]\(//;s/\)$//;s/#.*//'); do [ -e "prompts/$l" ] || { echo "  ❌ $f → $l"; b=1; }; done; done
[ $b = 0 ] && echo "  ✅ todos resuelven"
echo
echo "════ 3. ESTRUCTURA ════"
echo "  archivos publicados: $(ls *.md | wc -l | tr -d ' ') · fases: $(ls [0-9][0-9]-*.md | grep -vE 'convencion|historia' | wc -l | tr -d ' ')"
python3 -c "
import re,glob,io
bad=[]
for f in sorted(glob.glob('[0-9][0-9]-*.md')):
    if 'convencion' in f or 'historia' in f: continue
    n=int(f[:2]); s=io.open(f,encoding='utf-8').read()
    m=re.search(r'> Depende de: (.+?) · Habilita: (.+)',s)
    e='ninguna' if n==24 else '%02d'%(n+1)
    if m.group(2).strip()!=e: bad.append((n,m.group(2)))
    if int(re.search(r'Fase (\d+) de 24',s).group(1))!=n: bad.append((n,'cabecera'))
print('  ✅ cadena 00→24 sin huecos, cabeceras correctas' if not bad else '  ❌ %s'%bad)"

# --- 2026-09-13T20:02:58 · Verification batch 2
echo "════ 4. PLANTILLA, EJERCICIOS, TAGS ════"
b=0; for f in $(ls [0-9][0-9]-*.md|grep -vE 'convencion|historia'); do
 for k in "🎯 1\." "✅ 2\." "🚫 3\." "🧠 4\." "💻 5\." "📏 6\." "🧱 7\." "🧪 8\." "📚 9\." "🚀 10\."; do grep -qE "^## $k" $f || { echo "  ❌ $f falta §$k"; b=1; }; done
 d=$(sed -nE 's/^## 🧪 8\. Ejercicios \(([0-9]+)\)/\1/p' $f); n=$(awk '/^## 🧪 8\./{f=1;next}/^## 📚 9\./{f=0}f' $f|grep -cE "^[0-9]+\. ")
 { [ "$d" = "$n" ] && [ "$d" -ge 20 ] && [ "$d" -le 25 ]; } || { echo "  ❌ $f ejercicios decl=$d real=$n"; b=1; }
 i=${f:0:2}; { [ $(grep -c "git tag -a fase-$i" $f) = 1 ] && [ $(grep -c "git tag -a mini-$i" $f) = 1 ]; } || { echo "  ❌ $f tags"; b=1; }
done; [ $b = 0 ] && echo "  ✅ 10 secciones en orden · ejercicios decl=real y en 20-25 · tags fase/mini · las 25"
echo
echo "════ 5. BENCHMARKS ════"
python3 -c "
import re,io
s=io.open('BENCHMARKS.md',encoding='utf-8').read()
i=[int(m) for m in re.findall(r'^## 📐 F(\d{2}) ·',s,re.M)]
idx=[int(m) for m in re.findall(r'^\| (\d{2}) \| ',s,re.M)][:25]
print('  ✅ 24 entradas F00-F23 + consolidación F24 · índice de 25 filas' if i==list(range(24)) and '## 🧮 F24' in s and idx==list(range(25)) else '  ❌ %s'%i)"
echo
echo "════ 6. CONTEOS ESCRITOS ════"
grep -rhoE "veinticinco (fases|mediciones|entradas|tablas|documentos|miniproyectos)|veinticuatro (fases|mediciones|entradas|tablas)" *.md | sort | uniq -c
echo
echo "════ 7. CIFRAS DEL DOMINIO ════"
grep -rhoE "[0-9][0-9.]*[0-9]? (procedimientos|formularios|títulos|equipos|empleados)" *.md | sort | uniq -c | sort -rn
grep -rhoE "(4[0-9] años|[Cc]uarenta y [a-z]+ años)" *.md | sort | uniq -c

# --- 2026-09-13T20:03:12 · Audit the newly published story document
echo "════ 8. AUDITORÍA DEL DOCUMENTO RECIÉN PUBLICADO ════"
echo "-- lenguaje de propuesta / autor --"
grep -nE "propuesta|candidat|este documento propone|si se elige|habría que|el curso debería|opción [AB]|alternativa" 00-historia-de-cordillera.md | sed 's/\(.\{140\}\).*/\1/'
echo "-- referencias a maquinaria interna --"
grep -nE "prompts/|alcance-del-proyecto|propuesta-fases|guia-de-estilo|congelamiento|§[0-9]" 00-historia-de-cordillera.md | sed 's/\(.\{140\}\).*/\1/'
echo "-- conteos y fases --"
grep -nE "veinticinco|veinticuatro|2[0-9] fases|fase [0-9]+|F[0-9]{2}" 00-historia-de-cordillera.md | sed 's/\(.\{140\}\).*/\1/' | head -20

# --- 2026-09-13T20:03:19 · Read the meta sections of the story doc
sed -n '47,70p' 00-historia-de-cordillera.md; echo "..... §11 ....."; sed -n '494,512p' 00-historia-de-cordillera.md

# --- 2026-09-13T20:03:26 · Hunt other-course references and author voice
grep -rnE "curso de (Go|Java|Python|Angular|React|Rust|Node|C\+\+)|el curso de [A-Z]" . --include="*.md" | sed 's/\(.\{150\}\).*/\1/'
echo "--- voz de autor en el documento publicado ---"
grep -nE "el curso (tiene que|debe|debería|va a tener que|necesita|puede)|le da al curso|para el curso|este curso saca|sirve al curso" 00-historia-de-cordillera.md | sed 's/\(.\{135\}\).*/\1/'

# --- 2026-09-13T20:03:30 · Read the two Go-course passages
sed -n '529,560p' 00-historia-de-cordillera.md; echo "=== propuesta 1000,1008 ==="; sed -n '1000,1008p' prompts/propuesta-fases-y-alcance.md

# --- 2026-09-13T20:03:42 · Remove the Go-course references
python3 - <<'PY'
import io
def rep(path,pairs):
    s=io.open(path,encoding='utf-8').read()
    for a,b in pairs:
        assert s.count(a)==1,(path,a[:60],s.count(a))
        s=s.replace(a,b)
    io.open(path,'w',encoding='utf-8').write(s)

rep('00-historia-de-cordillera.md',[
("""En el curso de Go la frontera era 1.13 → moderno: una actualización de runtime. En C# la
frontera es mucho más grande, y esta empresa es la que la sostiene de punta a punta.""",
 """La frontera que este curso tiene que cruzar no es una actualización de runtime: es .NET
Framework 4.8 contra .NET 10, dos plataformas con instaladores distintos, modelos de proyecto
distintos y una convivencia que dura años. Esta empresa es la que la sostiene de punta a punta."""),
("""El curso de Go cerraba midiendo Go contra Spring Boot. Pero **el duelo más parejo que existe es
ASP.NET Core contra Spring Boot 3**: dos plataformas de la misma generación, el mismo perfil de
empresa, la misma clase de herramientas y equipos intercambiables.""",
 """**El duelo más parejo que existe es ASP.NET Core contra Spring Boot 3**: dos plataformas de la
misma generación, el mismo perfil de empresa, la misma clase de herramientas y equipos
intercambiables. Medir contra algo de otra categoría habría sido más fácil y habría enseñado
menos."""),
])

rep('prompts/propuesta-fases-y-alcance.md',[
("""  veredicto que el repositorio pide. Un bloque de escritorio que terminara siempre en "reescribe
  en web" no haría falta.""",
 """  veredicto que este curso existe para producir. Un bloque de escritorio que terminara siempre en
  "reescribe en web" no haría falta."""),
])
print('ok')
PY
grep -rnE "curso de (Go|Python|Angular|React|Rust|Node)|el repositorio pide" . --include="*.md" || echo "  ✅ cero"

# --- 2026-09-13T20:03:52 · Wide sweep for external references
echo "════ barrido amplio de referencias externas ════"
grep -rniE "otro curso|otros cursos|este repositorio|del repositorio|en el repositorio|curso de [A-Z]|cursos de |repositorio de cursos" . --include="*.md" \
 | grep -viE "SDK del repositorio|archivo del repositorio|raíz del repositorio|árbol del repositorio|subárbol del repositorio|fuera del repositorio|repositorio de (ejecuciones|dotnet)|en el repositorio si alguien|en el repositorio y en el historial|en el repositorio como prueba|se quedan en el repositorio|está en el repositorio" \
 | sed 's/\(.\{155\}\).*/\1/'

# --- 2026-09-13T20:04:02 · Check projects and tracks in the story vs structure
sed -n '340,350p' 00-historia-de-cordillera.md; echo "... nombres de proyecto en la historia ..."; grep -noE "CatalogAPI|NightPress|Redacción|AcervoRAG|EditorAgent|SIGE" 00-historia-de-cordillera.md | cut -d: -f2 | sort | uniq -c; echo "=== tracks ==="; sed -n '510,528p' 00-historia-de-cordillera.md

# --- 2026-09-13T20:04:09 · Read the project tables in the story
sed -n '346,360p' 00-historia-de-cordillera.md; echo "... §9 ..."; sed -n '428,440p' 00-historia-de-cordillera.md

# --- 2026-09-13T20:04:18 · Locate the contradictions
grep -n "4\.5\|cuarenta y seis\|Cuarenta y seis\|Durable Functions" 00-historia-de-cordillera.md | sed 's/\(.\{150\}\).*/\1/'; echo "--- ¿el curso usa Durable Functions? ---"; grep -rn "Durable Functions" --include="*.md" . | sed 's/\(.\{130\}\).*/\1/'

# --- 2026-09-13T20:04:28 · Fix the two contradictions and check Functions coverage
python3 - <<'PY'
import io
p='00-historia-de-cordillera.md'
s=io.open(p,encoding='utf-8').read()
for a,b in [
 ("| 1 ⭐ | **El sistema, por partes** | La migración | .NET Framework 4.5 → .NET 10, patrón *strangler fig* |",
  "| 1 ⭐ | **El sistema, por partes** | La migración | .NET Framework 4.8 → .NET 10, patrón *strangler fig* |"),
 ("responder: *\"¿tenemos los derechos en portugués de este título para Brasil?\"*. Cuarenta y seis",
  "responder: *\"¿tenemos los derechos en portugués de este título para Brasil?\"*. Cuarenta y siete"),
]:
    assert s.count(a)==1,(a[:50],s.count(a)); s=s.replace(a,b)
io.open(p,'w',encoding='utf-8').write(s)
print('ok')
PY
echo "--- ¿Azure Functions en las fases? ---"; grep -rn "Azure Functions\|Functions" 17-trabajo-de-fondo.md 20-contenedor-y-la-factura.md | sed 's/\(.\{140\}\).*/\1/' | head

# --- 2026-09-13T20:04:39 · Read the serverless bullet and check Service Bus coverage
sed -n '325,345p' 00-historia-de-cordillera.md; echo "=== mensajería en F17/F20 ==="; grep -rn "Service Bus" 17-trabajo-de-fondo.md 20-contenedor-y-la-factura.md | head -4 | sed 's/\(.\{130\}\).*/\1/'

# --- 2026-09-13T20:04:50 · Check which Azure services the phases actually cover
for k in "Blob Storage" "Azure DevOps" "GitHub Actions" "App Configuration" "Application Insights" "Azure OpenAI" "AI Search" "Semantic Kernel" "Entra ID" "Key Vault"; do printf "%-22s %s\n" "$k" "$(grep -rln "$k" [0-9][0-9]-*.md | grep -v historia | tr '\n' ' ')"; done

# --- 2026-09-13T20:04:56 · Looser grep for Azure services
for k in "Key Vault" "Blob" "DevOps" "Actions" "Functions" "Storage"; do printf "%-12s " "$k"; grep -rl "$k" [0-9][0-9]-*.md BENCHMARKS.md 2>/dev/null | grep -v historia | tr '\n' ' '; echo; done

# --- 2026-09-13T20:05:02 · Check how F16 handles the secret manager
grep -rn "Vault\|secreto gestionado\|gestor de secretos" 16-identidad-secretos-y-configuracion.md | head -8 | sed 's/\(.\{130\}\).*/\1/'; echo "--- 0-ESTRUCTURA fila 16 ---"; grep -n "Identidad, secretos" 0-ESTRUCTURA-CURSO.md README.md | sed 's/\(.\{150\}\).*/\1/'

# --- 2026-09-13T20:05:14 · Read the cloud inventory table
sed -n '315,345p' prompts/alcance-del-proyecto.md

# --- 2026-09-13T20:05:44 · Align the cloud inventory with what the phases deliver
python3 - <<'PY'
import io
def rep(path,pairs):
    s=io.open(path,encoding='utf-8').read()
    for a,b in pairs:
        assert s.count(a)==1,(path,a[:70],s.count(a))
        s=s.replace(a,b)
    io.open(path,'w',encoding='utf-8').write(s)

# El stack de NightPress: la F17 construye IHostedService y una cola en tabla, no Functions
rep('00-historia-de-cordillera.md',[
("| 4 | **NightPress** | Proceso de fondo | Worker Service (`IHostedService`) + Service Bus + Durable Functions |",
 "| 4 | **NightPress** | Proceso de fondo | Worker Service (`IHostedService`) + cola, medida contra mensajería administrada |"),
])

# El inventario de nube prometía tres servicios ejecutables que ninguna fase ejecuta
rep('prompts/alcance-del-proyecto.md',[
("""| Blob Storage | ▶️ Ejecutable | Azurite en contenedor | F17 |
| Colas y tablas de Storage | ▶️ Ejecutable | Azurite | F17 |
| Azure Functions y Durable Functions | ▶️ Ejecutable | Core Tools sobre Azurite | F17 · F20 |
| Telemetría |""",
 """| Telemetría |"""),
("""> 🧭 **La región por defecto del curso es East US 2**, y toda cifra de costo la nombra junto con""",
 """> 🪦 **Tres servicios estaban en este inventario y no entraron, y el curso lo dice en vez de
> disimularlo:** Blob Storage, las colas y tablas de Storage, y Azure Functions con Durable
> Functions, los tres planeados como ejecutables sobre Azurite para la F17 y la F20. La F17 se
> escribió con `IHostedService` y **una cola en tabla de SQL Server** —medida contra mensajería
> administrada—, y esa decisión resultó ser la lección de la fase: el atajo con su número al lado
> y su condición de salida escrita. Meter Azurite encima habría sido un cuarto competidor sin
> pregunta que lo pidiera. Quedan como 📌 pendientes con destino, no como deuda.

> 🧭 **La región por defecto del curso es East US 2**, y toda cifra de costo la nombra junto con"""),
])
print('ok')
PY
sed -n '322,340p' prompts/alcance-del-proyecto.md

# --- 2026-09-13T20:05:50 · Check remaining Azurite references
grep -rn "Azurite\|Core Tools" . --include="*.md" | sed 's/\(.\{140\}\).*/\1/'; echo "=== §10.8 de la propuesta ==="; grep -n "10.8" prompts/propuesta-fases-y-alcance.md | head -3

# --- 2026-09-13T20:05:53 · Read the remaining Azurite mention
sed -n '348,360p' prompts/alcance-del-proyecto.md

# --- 2026-09-13T20:06:05 · Final verification
python3 - <<'PY'
import io
p='prompts/alcance-del-proyecto.md'
s=io.open(p,encoding='utf-8').read()
a="""> 🧭 **El curso se completa sin una suscripción de Azure de pago.** Lo que tiene emulador o
> equivalente local se usa así —SQL Server en contenedor, Azurite para Blob y colas, el
> emulador de Service Bus o una alternativa local declarada—. Lo que no lo tiene se estudia"""
b="""> 🧭 **El curso se completa sin una suscripción de Azure de pago.** Lo que tiene emulador o
> equivalente local se usa así —SQL Server en contenedor, el emulador de Service Bus o una
> alternativa local declarada, un proveedor OIDC en contenedor, un modelo servido en
> local—. Lo que no lo tiene se estudia"""
assert s.count(a)==1
io.open(p,'w',encoding='utf-8').write(s.replace(a,b))
print('ok')
PY
echo "════ VERIFICACIÓN FINAL ════"
echo "1. Otros cursos / repo:"; grep -rnE "CLAUDE\.md|cursos-[a-z]|curso(s)? hermano|curso de (Go|Python|Angular|React|Rust|Node)|otros cursos del|python-for-java|propuestas-cursos|_oskar" . --include="*.md" || echo "   ✅ cero"
echo "2. Enlaces:"; b=0; for f in *.md; do for l in $(grep -ohE "\]\(([^)h][^)]*)\)" "$f"|sed -E 's/^\]\(//;s/\)$//;s/#.*//'); do [ -e "$l" ]||{ echo "   ❌ $f→$l"; b=1; }; done; done; for f in prompts/*.md; do for l in $(grep -ohE "\]\(([^)h][^)]*)\)" "$f"|sed -E 's/^\]\(//;s/\)$//;s/#.*//'); do [ -e "prompts/$l" ]||{ echo "   ❌ $f→$l"; b=1; }; done; done; [ $b = 0 ] && echo "   ✅ todos resuelven"
echo "3. Promesas de nube sin fase:"; for k in "Durable Functions" "Azurite"; do printf "   %-20s " "$k"; r=$(grep -rl "$k" [0-9][0-9]-*.md 2>/dev/null|tr '\n' ' '); [ -z "$r" ] && echo "ya no se promete en material publicado" || echo "$r"; done
echo "4. Framework 4.8 / 47 años:"; grep -rhoE "Framework 4\.[58]|4[0-9] años" *.md | sort | uniq -c

# --- 2026-09-13T20:06:15 · Declare serverless out in the story, verify the claim
python3 - <<'PY'
import io
p='00-historia-de-cordillera.md'
s=io.open(p,encoding='utf-8').read()
a="""- **Serverless** — Azure Functions y **Durable Functions** para la publicación programada en
  nueve husos, que es el caso de libro para una orquestación durable."""
b="""- **Serverless** — Azure Functions y Durable Functions serían el caso de libro para la publicación
  programada en nueve husos. **El curso lo declara fuera**, y con su razón: la F17 resuelve la
  reanudación con un proceso propio de doscientas líneas, y verla construida a mano enseña el
  mecanismo que una orquestación durable esconde."""
assert s.count(a)==1
io.open(p,'w',encoding='utf-8').write(s.replace(a,b))
print('ok')
PY
grep -rn "Durable Functions" [0-9][0-9]-*.md | sed 's/\(.\{135\}\).*/\1/'; echo "--- ¿la F17 dice 200 líneas? ---"; grep -n "doscientas líneas\|200 líneas" 17-trabajo-de-fondo.md | sed 's/\(.\{130\}\).*/\1/'

# --- 2026-09-13T20:06:36 · Complete closing checklist
echo "══════════ CIERRE ══════════"
b=0
printf "1  Referencias a otros cursos ......... "; grep -rqnE "CLAUDE\.md|cursos-[a-z]|curso(s)? hermano|curso de (Go|Python|Angular|React|Rust|Node)|otros cursos del|python-for-java|propuestas-cursos|_oskar" . --include="*.md" && { echo "❌"; b=1; } || echo "✅ cero"
printf "2  Enlaces relativos ................. "; n=0; for f in *.md; do for l in $(grep -ohE "\]\(([^)h][^)]*)\)" "$f"|sed -E 's/^\]\(//;s/\)$//;s/#.*//'); do [ -e "$l" ]||n=1; done; done; for f in prompts/*.md; do for l in $(grep -ohE "\]\(([^)h][^)]*)\)" "$f"|sed -E 's/^\]\(//;s/\)$//;s/#.*//'); do [ -e "prompts/$l" ]||n=1; done; done; [ $n = 0 ] && echo "✅ todos resuelven" || { echo "❌"; b=1; }
printf "3  Cadena 00→24 y cabeceras .......... "; python3 -c "
import re,glob,io
bad=0
for f in sorted(glob.glob('[0-9][0-9]-*.md')):
    if 'convencion' in f or 'historia' in f: continue
    n=int(f[:2]); s=io.open(f,encoding='utf-8').read()
    m=re.search(r'> Depende de: (.+?) · Habilita: (.+)',s)
    if m.group(2).strip()!=('ninguna' if n==24 else '%02d'%(n+1)): bad=1
    if int(re.search(r'Fase (\d+) de 24',s).group(1))!=n: bad=1
print('✅ sin huecos' if not bad else '❌')"
printf "4  Plantilla de 10 secciones ......... "; n=0; for f in $(ls [0-9][0-9]-*.md|grep -vE 'convencion|historia'); do for k in "🎯 1\." "✅ 2\." "🚫 3\." "🧠 4\." "💻 5\." "📏 6\." "🧱 7\." "🧪 8\." "📚 9\." "🚀 10\."; do grep -qE "^## $k" $f||n=1; done; done; [ $n = 0 ] && echo "✅ las 25, en orden" || { echo "❌"; b=1; }
printf "5  Ejercicios decl=real, banda 20-25 . "; n=0; for f in $(ls [0-9][0-9]-*.md|grep -vE 'convencion|historia'); do d=$(sed -nE 's/^## 🧪 8\. Ejercicios \(([0-9]+)\)/\1/p' $f); r=$(awk '/^## 🧪 8\./{f=1;next}/^## 📚 9\./{f=0}f' $f|grep -cE "^[0-9]+\. "); { [ "$d" = "$r" ]&&[ "$d" -ge 20 ]&&[ "$d" -le 25 ]; }||n=1; done; [ $n = 0 ] && echo "✅ las 25" || { echo "❌"; b=1; }
printf "6  Tags fase-NN / mini-NN ............ "; n=0; for i in $(seq -w 0 24); do f=$(ls ${i}-*.md|grep -vE 'convencion|historia'); { [ $(grep -c "git tag -a fase-$i" $f) = 1 ]&&[ $(grep -c "git tag -a mini-$i" $f) = 1 ]; }||n=1; done; [ $n = 0 ] && echo "✅ las 25" || { echo "❌"; b=1; }
printf "7  BENCHMARKS 24 entradas + F24 ...... "; python3 -c "
import re,io
s=io.open('BENCHMARKS.md',encoding='utf-8').read()
i=[int(m) for m in re.findall(r'^## 📐 F(\d{2}) ·',s,re.M)]
print('✅ F00-F23 + consolidación' if i==list(range(24)) and '## 🧮 F24' in s else '❌')"
printf "8  Servicios de nube prometidos ...... "; n=0; for k in "Durable Functions" "Azurite" "Blob Storage"; do grep -rq "$k" $(ls [0-9][0-9]-*.md|grep -vE 'historia') 2>/dev/null && n=1; done; [ $n = 0 ] && echo "✅ ninguno sin fase que lo cumpla" || { echo "❌"; b=1; }
echo; [ $b = 0 ] && echo "TODO EN VERDE" || echo "HAY FALLOS"

# --- 2026-09-13T20:23:18 · Check where F00 puts its demo and miniproject
grep -n "fases/00\|fases\\\\00\|Bench.Cli" 00-instalacion-ambiente-visual-studio-y-ecosistema.md | sed 's/\(.\{150\}\).*/\1/'

# --- 2026-09-13T20:23:24 · Check F07 placement and the stated rule
echo "=== F07: dónde viven demo y mini ==="; grep -n "fases/07\|fases\\\\07" 07-el-sistema-que-heredas.md | sed 's/\(.\{160\}\).*/\1/'
echo; echo "=== la regla: qué va en src/fases/ ==="; grep -n -B3 -A6 "fases/NN-nombre" 00-instalacion-ambiente-visual-studio-y-ecosistema.md prompts/congelamiento-de-nombres.md | sed 's/\(.\{150\}\).*/\1/'

# --- 2026-09-13T20:23:27 · Read the fases section of the frozen tree
sed -n '536,570p' prompts/congelamiento-de-nombres.md

# --- 2026-09-13T20:23:55 · Read the miniproject placement rule
grep -n -A12 "^## 5\." prompts/formato-de-miniproyectos.md | head -24

# --- 2026-09-13T20:24:14 · Remove spurious F00 dir and declare the exception
rm -rf src/fases/00-instalacion-ambiente-visual-studio-y-ecosistema
python3 - <<'PY'
import io
p='prompts/congelamiento-de-nombres.md'
s=io.open(p,encoding='utf-8').read()

# 1. El ejemplo del árbol: la F00 no tiene directorio de fase; la F07 sí
a="""  fases/
    00-instalacion-ambiente-visual-studio-y-ecosistema/
      demo/                       ← lo que la sección 5 de la fase ejecuta
      mini/                       ← el miniproyecto 🧱 de la fase
    01-tipos-valor-y-referencia/
    …"""
b="""  fases/
    01-tipos-valor-y-referencia/
      demo/                       ← lo que la sección 5 de la fase ejecuta
      mini/                       ← el miniproyecto 🧱 de la fase
    02-nullable-y-pattern-matching/
    …                             ← 🪦 la F00 no tiene directorio aquí: ver la regla de abajo"""
assert s.count(a)==1; s=s.replace(a,b)

# 2. La regla, con su excepción declarada
a2="""- **Los miniproyectos no tocan `legacy/` ni `modern/`** (`formato-de-miniproyectos.md` §5). Leen su salida,
  consumen su API o miden contra su implementación, y viven en `fases/NN-…/mini/`."""
b2="""- **Los miniproyectos no tocan `legacy/` ni `modern/`** (`formato-de-miniproyectos.md` §5). Leen su salida,
  consumen su API o miden contra su implementación, y viven en `fases/NN-…/mini/`.
- 🪦 **La F00 es la única excepción, y está declarada.** Su miniproyecto es `Cordillera.Bench.Cli`,
  que vive en `modern/` y **no** en `fases/00-…/mini/`. La razón es la misma que sostiene la regla,
  leída al revés: la regla existe para que un miniproyecto mal resuelto no arrastre el error hasta
  el final, y por eso se mantienen aparte de lo que el curso carga. El arnés **es** lo que el curso
  carga — las veinticuatro fases siguientes lo invocan en su sección 6 y ninguna mide con otra cosa.
  Meterlo en `fases/00-…/mini/` obligaría a las veinticuatro a apuntar a un directorio de fase, que
  es exactamente lo que esta estructura separa. **Consecuencia:** la F00 no tiene directorio bajo
  `fases/`, porque tampoco su sección 5 produce nada que viva ahí — lo que escribe es el esqueleto
  del repositorio y la biblioteca del arnés."""
assert s.count(a2)==1; s=s.replace(a2,b2)
io.open(p,'w',encoding='utf-8').write(s)
print('ok')
PY
echo "--- estado de src/fases ---"; find src/fases; echo "--- ¿alguna fase apunta a fases/00? ---"; grep -rn "fases/00\|fases\\\\00" . --include="*.md" || echo "  ninguna"

# --- 2026-09-13T20:24:24 · Check whether any phase uses a demo directory
echo "--- rutas fases/NN/... citadas por las fases ---"; grep -rhoE "fases[\\\\/][0-9]{2}-[a-z0-9-]+([\\\\/][a-z]+)?" *.md | tr '\\' '/' | sort -u
echo; echo "--- ¿alguien cita demo/? ---"; grep -rn "/demo\b\|\\\\demo\b" *.md prompts/*.md | sed 's/\(.\{140\}\).*/\1/'

# --- 2026-09-13T20:24:46 · Drop the unused demo/ slot from structure and disk
rmdir src/fases/07-el-sistema-que-heredas/demo 2>/dev/null || rm -rf src/fases/07-el-sistema-que-heredas/demo
python3 - <<'PY'
import io
def rep(path,pairs):
    s=io.open(path,encoding='utf-8').read()
    for a,b in pairs:
        assert s.count(a)==1,(path,a[:60],s.count(a))
        s=s.replace(a,b)
    io.open(path,'w',encoding='utf-8').write(s)

rep('00-instalacion-ambiente-visual-studio-y-ecosistema.md',[
("  fases/NN-nombre/      ← lo propio de una fase: su demo y su miniproyecto",
 "  fases/NN-nombre/mini/ ← el miniproyecto 🧱 de una fase, que no toca legacy/ ni modern/"),
])

rep('prompts/congelamiento-de-nombres.md',[
("""  fases/
    01-tipos-valor-y-referencia/
      demo/                       ← lo que la sección 5 de la fase ejecuta
      mini/                       ← el miniproyecto 🧱 de la fase
    02-nullable-y-pattern-matching/
    …                             ← 🪦 la F00 no tiene directorio aquí: ver la regla de abajo""",
 """  fases/
    01-tipos-valor-y-referencia/
      mini/                       ← el miniproyecto 🧱 de la fase, y nada más
    02-nullable-y-pattern-matching/
    …                             ← 🪦 la F00 no tiene directorio aquí: ver la regla de abajo"""),
("""- **El directorio de `fases/` se llama exactamente igual que el `.md` de su fase**, sin la
  extensión. Es la convención de nombres de este curso.""",
 """- **El directorio de `fases/` se llama exactamente igual que el `.md` de su fase**, sin la
  extensión. Es la convención de nombres de este curso.
- 🪦 **Y contiene `mini/` y nada más.** El plan original le daba también un `demo/` para "lo que la
  sección 5 de la fase ejecuta", y las veinticinco fases demostraron que no hacía falta: **ninguna
  sección 5 produce código desechable**. Lo que escribe cada fase entra en un proyecto que el curso
  carga —`Cordillera.Domain`, `Sige.DataAccess`, `Cordillera.Catalog.Api`— porque toda fase tiene
  que mover al menos uno. Un `demo/` habría sido el sitio donde se esconde el código que no se supo
  ubicar, que es el mismo argumento por el que este curso no tiene apéndices."""),
])
print('ok')
PY
find src/fases; echo "--- ¿queda alguna promesa de demo/? ---"; grep -rn "demo/" *.md prompts/*.md | sed 's/\(.\{145\}\).*/\1/' || echo "  ninguna"

# --- 2026-09-13T20:30:10 · Standard verification battery
b=0
printf "1  Referencias a otros cursos ......... "; grep -rqnE "CLAUDE\.md|cursos-[a-z]|curso(s)? hermano|curso de (Go|Python|Angular|React|Rust|Node|Java)|otros cursos del|python-for-java|ruta-nosql|propuestas-cursos|_oskar" . --include="*.md" && { echo "❌"; grep -rnE "CLAUDE\.md|cursos-[a-z]|curso de (Go|Python|Angular|React|Rust|Node|Java)" . --include="*.md"; b=1; } || echo "✅ cero"
printf "2  Enlaces relativos ................. "; n=0; for f in *.md; do for l in $(grep -ohE "\]\(([^)h][^)]*)\)" "$f"|sed -E 's/^\]\(//;s/\)$//;s/#.*//'); do [ -e "$l" ]||{ n=1; echo "❌ $f→$l"; }; done; done; for f in prompts/*.md; do for l in $(grep -ohE "\]\(([^)h][^)]*)\)" "$f"|sed -E 's/^\]\(//;s/\)$//;s/#.*//'); do [ -e "prompts/$l" ]||{ n=1; echo "❌ $f→$l"; }; done; done; [ $n = 0 ] && echo "✅" || b=1
printf "3  Cadena 00→24 + cabeceras .......... "; python3 -c "
import re,glob,io
bad=0
for f in sorted(glob.glob('[0-9][0-9]-*.md')):
    if 'convencion' in f or 'historia' in f: continue
    n=int(f[:2]); s=io.open(f,encoding='utf-8').read()
    if re.search(r'> Depende de: (.+?) · Habilita: (.+)',s).group(2).strip()!=('ninguna' if n==24 else '%02d'%(n+1)): bad=1
    if int(re.search(r'Fase (\d+) de 24',s).group(1))!=n: bad=1
print('✅' if not bad else '❌')"
printf "4  10 secciones · ejercicios · tags ... "; n=0; for f in $(ls [0-9][0-9]-*.md|grep -vE 'convencion|historia'); do for k in "🎯 1\." "✅ 2\." "🚫 3\." "🧠 4\." "💻 5\." "📏 6\." "🧱 7\." "🧪 8\." "📚 9\." "🚀 10\."; do grep -qE "^## $k" $f||n=1; done; d=$(sed -nE 's/^## 🧪 8\. Ejercicios \(([0-9]+)\)/\1/p' $f); r=$(awk '/^## 🧪 8\./{f=1;next}/^## 📚 9\./{f=0}f' $f|grep -cE "^[0-9]+\. "); { [ "$d" = "$r" ]&&[ "$d" -ge 20 ]&&[ "$d" -le 25 ]; }||n=1; i=${f:0:2}; { [ $(grep -c "git tag -a fase-$i" $f) = 1 ]&&[ $(grep -c "git tag -a mini-$i" $f) = 1 ]; }||n=1; done; [ $n = 0 ] && echo "✅ las 25" || { echo "❌"; b=1; }
printf "5  BENCHMARKS ........................ "; python3 -c "
import re,io
s=io.open('BENCHMARKS.md',encoding='utf-8').read()
i=[int(m) for m in re.findall(r'^## 📐 F(\d{2}) ·',s,re.M)]
print('✅ 24 + consolidación' if i==list(range(24)) and '## 🧮 F24' in s else '❌')"
printf "6  src/ coincide con lo declarado .... "; find src/fases -mindepth 1 -maxdepth 2 -type d | sort | tr '\n' ' '; echo
[ $b = 0 ] && echo "── base en verde ──"

# --- 2026-09-13T20:30:30 · New-angle checks: markers, sections, tracks, citations
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

# --- 2026-09-13T20:30:40 · Inspect marker outliers
echo "-- fases sin 💸 --"; for f in $(ls [0-9][0-9]-*.md|grep -vE 'convencion|historia'); do grep -q "💸" $f || echo "  $f"; done
echo "-- fases con 🔜 --"; grep -l "🔜" $(ls [0-9][0-9]-*.md|grep -vE 'convencion|historia')
echo "-- 🔜 en BENCHMARKS --"; grep -c "🔜" BENCHMARKS.md | xargs echo "  ocurrencias:"; grep -n "🔜" BENCHMARKS.md | sed 's/\(.\{125\}\).*/\1/'

# --- 2026-09-13T20:30:54 · Read the consolidated F14 entry
sed -n '871,935p' BENCHMARKS.md

# --- 2026-09-13T20:31:02 · Verify the 🔜 cell count claim
sed -n '130,150p' BENCHMARKS.md; echo "── conteo real de celdas 🔜 en el doc de la F14 ──"; grep -c "🔜" 14-veredicto-del-escritorio.md | xargs echo "  líneas con 🔜:"; grep -o "🔜" 14-veredicto-del-escritorio.md | wc -l | xargs echo "  ocurrencias:"; grep -n "🔜" 14-veredicto-del-escritorio.md | sed 's/\(.\{110\}\).*/\1/'

# --- 2026-09-13T20:31:47 · Read the loose 🔜 statements
sed -n '440,446p' 24-veredicto-y-defensa.md; echo "---"; sed -n '755,760p' 14-veredicto-del-escritorio.md

# --- 2026-09-13T20:32:01 · Fix the 🔜 destination rule and cell counts
python3 - <<'PY'
import io
def rep(path,pairs):
    s=io.open(path,encoding='utf-8').read()
    for a,b,n in pairs:
        assert s.count(a)==n,(path,a[:60],s.count(a))
        s=s.replace(a,b)
    io.open(path,'w',encoding='utf-8').write(s)

# 1. Las cuatro celdas 🔜 de la tabla C no nombraban su destino, que es obligación de la convención
rep('14-veredicto-del-escritorio.md',[
("| ¿Puede Duván cambiar un ancho de columna sin ayuda? | ⏳ | ⏳ | ⏳ | 🔜 |",
 "| ¿Puede Duván cambiar un ancho de columna sin ayuda? | ⏳ | ⏳ | ⏳ | 🔜 **fase 18** |",1),
("| ¿Puede desplegar una corrección él solo? | ⏳ | ⏳ | ⏳ | 🔜 |",
 "| ¿Puede desplegar una corrección él solo? | ⏳ | ⏳ | ⏳ | 🔜 **fase 18** |",1),
("| ¿Cuánto le costó entender el prototipo? *(medido en horas, preguntándole)* | ⏳ | ⏳ | ⏳ | 🔜 |",
 "| ¿Cuánto le costó entender el prototipo? *(medido en horas, preguntándole)* | ⏳ | ⏳ | ⏳ | 🔜 **fase 18** |",1),
("| ¿Se puede contratar a alguien que lo sepa, en Bogotá? | ⏳ | ⏳ | ⏳ | 🔜 |",
 "| ¿Se puede contratar a alguien que lo sepa, en Bogotá? | ⏳ | ⏳ | ⏳ | 🔜 **fase 18** |",1),
("""> rellene la columna, `git diff fase-14 fase-18 -- BENCHMARKS.md` va a mostrar **una celda que pasa de 🔜
> a ⏳ porque llegó un dato**,""",
 """> rellene la columna, `git diff fase-14 fase-18 -- BENCHMARKS.md` va a mostrar **nueve celdas que pasan de
> 🔜 a ⏳ porque llegó un dato**,""",1),
])

# 2. "la única celda 🔜" era en realidad una columna entera
rep('24-veredicto-y-defensa.md',[
("""las veinticuatro fases usa una fila ⏳ como argumento de una decisión, y la única celda 🔜 que existió —la
> cuarta columna del veredicto del escritorio— la llenó la fase 18.""",
 """las veinticuatro fases usa una fila ⏳ como argumento de una decisión, y la única columna 🔜 que existió —la
> cuarta del veredicto del escritorio, nueve celdas entre la tabla y sus respaldos— la llenó la fase 18.""",1),
])
print('ok')
PY
echo "── verificación: todo 🔜 nombra su fase ──"; grep -n "🔜" 14-veredicto-del-escritorio.md | grep -vE "fase 18|convención|null" | sed 's/\(.\{120\}\).*/\1/' || echo "  ✅ todos con destino"

# --- 2026-09-13T21:26:31 · Style, pendientes and references audit
echo "── E. Estilo declarado por fase vs tabla de 0-ESTRUCTURA ──"
python3 - <<'PY'
import re,io,glob
est=io.open('0-ESTRUCTURA-CURSO.md',encoding='utf-8').read()
tabla={}
for m in re.finditer(r'^\| (\d{2}) ⭐? \| [^|]+\| (nuevo|heredado|mixto 🧬|—) \|',est,re.M):
    tabla[int(m.group(1))]=m.group(2)
bad=[]
for f in sorted(glob.glob('[0-9][0-9]-*.md')):
    if 'convencion' in f or 'historia' in f: continue
    n=int(f[:2]); s=io.open(f,encoding='utf-8').read()
    m=re.search(r'> Estilo de esta fase: \*\*(.+?)\*\*',s)
    d=m.group(1).replace('mixto 🧬','mixto 🧬')
    t=tabla.get(n)
    if t and t.split()[0] not in d: bad.append((n,d,t))
print('  ✅ coinciden' if not bad else '  ❌ %s'%bad)
PY
echo
echo "── F. 📌 Pendientes en cada fase ──"
n=0; for f in $(ls [0-9][0-9]-*.md|grep -vE 'convencion|historia'); do grep -q "^## 📌 Pendientes" $f || { echo "  ❌ $f"; n=1; }; done; [ $n = 0 ] && echo "  ✅ las 25"
echo
echo "── G. Referencias §9: ¿URLs completas? ──"
for f in $(ls [0-9][0-9]-*.md|grep -vE 'convencion|historia'); do
  c=$(awk '/^## 📚 9\./{f=1;next}/^## 🚀 10\./{f=0}f' $f | grep -cE "https?://")
  [ "$c" -lt 5 ] && echo "  ⚠️  $f solo $c URLs"
done; echo "  (vacío = todas con 5+ referencias enlazadas)"
echo
echo "── H. ¿Alguna URL sospechosa de estar inventada? ──"
awk '/^## 📚 9\./{f=1}/^## 🚀 10\./{f=0}f' $(ls [0-9][0-9]-*.md|grep -vE 'convencion|historia') | grep -ohE "https?://[a-z0-9.-]+" | sort | uniq -c | sort -rn

# --- 2026-09-13T21:26:37 · Read phase 24 references
awk '/^## 📚 9\./{f=1;next}/^## 🚀 10\./{f=0}f' 24-veredicto-y-defensa.md | head -35

# --- 2026-09-13T21:26:55 · Final checks and full battery
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

# --- 2026-09-13T21:27:02 · Confirm the F04 table row is a header
awk '/^## 📏 6\./{f=1;next}/^## 🧱 7\./{f=0}f' 04-ceremonia-delegados-y-recursos.md | grep -E "^\|" | head -7

