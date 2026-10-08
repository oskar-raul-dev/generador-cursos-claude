# Comandos Bash de la sesión c9051874-1218-483a-96ca-bbd129a78447, en orden. Una bitácora, no un script: no se corre entera.

# --- 2026-09-13T19:46:29 · Read course README and list prompts
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/go-for-java-devs && cat README.md && echo "=====PROMPTS=====" && ls -la prompts/

# --- 2026-09-13T19:46:30 · Read course structure and line counts
cat 0-ESTRUCTURA-CURSO.md | head -200 && echo "=====WC=====" && wc -l *.md

# --- 2026-09-13T19:46:34 · Read structure tail and go ideas proposal
sed -n '200,275p' 0-ESTRUCTURA-CURSO.md; echo "=====IDEAS====="; head -60 ../../propuestas-cursos/ideas-proyectos-go.md

# --- 2026-09-13T19:51:13 · Check current file state and git status
ls -la && echo "=== git status ===" && git status --short -- . ../../propuestas-cursos/

# --- 2026-09-13T19:51:17 · Find references to renamed files
echo "=== ambiente-y-tooling refs ==="; grep -rn "00-ambiente-y-tooling\|ambiente-y-tooling" . | head -60
echo "=== historia refs ==="; grep -rn "historia-de-la-empresa-meridian" . | head -60

# --- 2026-09-13T19:51:19 · Find references to CLAUDE.md and other courses
echo "=== CLAUDE.md refs ==="; grep -rn "CLAUDE\.md" . | head -60
echo "=== other courses refs ==="; grep -rniE "cursos-[a-z-]+|propuestas-cursos|_oskar|courses-ia-generated|ruta-nosql|angular|for-java-devs|python-for|c-sharp|docker-container|repositorio|del repo\b|repo\b" . | grep -v "^Binary" | head -80

# --- 2026-09-13T19:51:26 · Find repo-rule and other-course references
grep -rn "regla del repositorio\|del repositorio:\|otros cursos\|este repositorio\|el repositorio de cursos\|curso hermano\|otro curso" . 

# --- 2026-09-13T19:51:29 · Read context around repo-rule mentions
sed -n '1195,1215p' 17-capstone.md; echo "--- 1390,1420 capstone"; sed -n '1390,1420p' 17-capstone.md; echo "=== 13-lotes 1985,2000"; sed -n '1985,2000p' 13-lotes-scheduling-y-asincronia.md; echo "=== 15 1750,1770"; sed -n '1750,1770p' 15-rendimiento-y-profiling.md; echo "=== 14 2230,2245"; sed -n '2230,2245p' 14-observabilidad-y-hardening.md; echo "=== BENCH 1180,1200"; sed -n '1180,1200p' BENCHMARKS.md

# --- 2026-09-13T19:51:39 · Scan for external paths and prompt references from published docs
echo "=== ../ links ==="; grep -rnE "\]\(\.\./|\]\(/Users|/Users/oskar" . | head -30
echo "=== convención repo-wide ==="; grep -rn "repo-wide\|todo el repositorio de cursos\|convención del repositorio\|nombres son repo\|guía del repositorio\|estándar del repositorio\|defaults del repositorio" .
echo "=== propuestas ==="; grep -rn "propuesta-fases-y-alcance\|alcance-del-proyecto\|guia-de-estilo\|aprendizaje\.md\|plantillas-de-capitulo\|formato-de-benchmarks\|proyecto-0" --include=*.md . | grep -v "^./prompts/" | head -40

# --- 2026-09-13T19:51:42 · Find published docs referencing prompts machinery
grep -rn "propuesta-fases-y-alcance\|alcance-del-proyecto\|guia-de-estilo\|aprendizaje\.md\|plantillas-de-capitulo\|formato-de-benchmarks\|proyecto-01-\|proyecto-02-\|proyecto-03-\|proyecto-04-\|prompts/" *.md

# --- 2026-09-13T19:51:48 · Scan prompts dir for external references
cd prompts && grep -rniE "CLAUDE\.md|otros cursos|otro curso|curso hermano|del repositorio|cursos-|repo-wide|courses-ia" . 

# --- 2026-09-13T19:51:55 · Rewrite references to the renamed tooling file
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/go-for-java-devs && \
sed -i '' 's|00-ambiente-y-tooling\.md|00-instalacion-ambiente-y-tooling.md|g' README.md 0-ESTRUCTURA-CURSO.md prompts/prompts-extendidos-fases.md prompts/alcance-del-proyecto.md prompts/propuesta-fases-y-alcance.md && \
grep -rn "00-instalacion-ambiente-y-tooling" README.md 0-ESTRUCTURA-CURSO.md prompts/

# --- 2026-09-13T19:52:00 · Read relevant sections of alcance-del-proyecto
sed -n '95,110p;258,300p;340,360p' prompts/alcance-del-proyecto.md

# --- 2026-09-13T19:52:13 · Fix external references in alcance-del-proyecto
python3 - <<'PY'
import io,re
p='prompts/alcance-del-proyecto.md'
s=io.open(p,encoding='utf-8').read()

reps = [
("[`historia-de-la-empresa-meridian.md`](historia-de-la-empresa-meridian.md)",
 "[`00-historia-de-la-empresa-meridian.md`](../00-historia-de-la-empresa-meridian.md)"),

("""Divergencia declarada frente al `CLAUDE.md` del repositorio: **este curso no
tiene apéndices**. Lo que en otros cursos sería un apéndice —el detalle del
tooling, la tabla de equivalencias, la comparación con Spring— vive dentro de la
fase que lo necesita,""",
 """Decisión de estructura declarada: **este curso no tiene apéndices**. Lo que
normalmente sería un apéndice —el detalle del tooling, la tabla de equivalencias,
la comparación con Spring— vive dentro de la fase que lo necesita,"""),

("""  00-convencion-de-git-y-tags.md Ramas, tags, prefijos de commit
  INSTINTOS.md                   Catálogo de reflejos Java ☕ (índice vivo)
  BENCHMARKS.md                  Banco de pruebas y resultados
  00-instalacion-ambiente-y-tooling.md""",
 """  00-convencion-de-git-y-tags.md Ramas, tags, prefijos de commit
  00-historia-de-la-empresa-meridian.md  La empresa ficticia: fuente de verdad narrativa
  INSTINTOS.md                   Catálogo de reflejos Java ☕ (índice vivo)
  BENCHMARKS.md                  Banco de pruebas y resultados
  00-instalacion-ambiente-y-tooling.md"""),

("Los nombres de fase siguen la convención del repositorio: `NN-tema.md`,",
 "Los nombres de fase siguen la convención del curso: `NN-tema.md`,"),

("viven en un `compose.yaml` del repositorio que la Fase 00 deja",
 "viven en un `compose.yaml` del monorepo que la Fase 00 deja"),

("| Apéndices | **No hay** | Todo vive en su fase; divergencia declarada del `CLAUDE.md` |",
 "| Apéndices | **No hay** | Todo vive en su fase; decisión de estructura declarada en §9 |"),

("| Ejercicios | **20 mínimo, 24 ideal, hasta 30** en las densas | Dentro del rango por defecto del repositorio |",
 "| Ejercicios | **20 mínimo, 24 ideal, hasta 30** en las densas | El rango que fija la guía de estilo del curso |"),
]
for a,b in reps:
    assert a in s, a[:60]
    s=s.replace(a,b)
io.open(p,'w',encoding='utf-8').write(s)
print("ok")
PY

# --- 2026-09-13T19:52:18 · Read historia header and related sections
sed -n '1,15p;385,400p' 00-historia-de-la-empresa-meridian.md; echo "=== fmt bench 1,12 ==="; sed -n '1,12p' prompts/formato-de-benchmarks.md; echo "=== estructura 212,225 ==="; sed -n '212,225p' 0-ESTRUCTURA-CURSO.md

# --- 2026-09-13T19:52:26 · Fix structure, benchmark format and historia references
python3 - <<'PY'
import io
def fix(p, reps):
    s=io.open(p,encoding='utf-8').read()
    for a,b in reps:
        assert a in s, (p, a[:70])
        s=s.replace(a,b)
    io.open(p,'w',encoding='utf-8').write(s)
    print("ok", p)

fix('0-ESTRUCTURA-CURSO.md', [(
"""**Nota de alcance:** este curso **no tiene apéndices**. Es una divergencia
declarada del `CLAUDE.md` del repositorio: lo que en otros cursos sería un apéndice
vive dentro de la fase que lo necesita, porque el formato "diciendo y haciendo"
pierde sentido si hay que saltar a otro archivo para poder ejecutar el siguiente
comando. El precio es que algunas fases son largas; se acepta.""",
"""**Nota de alcance:** este curso **no tiene apéndices**, y es una decisión
deliberada: lo que normalmente sería un apéndice vive dentro de la fase que lo
necesita, porque el formato "diciendo y haciendo" pierde sentido si hay que saltar
a otro archivo para poder ejecutar el siguiente comando. El precio es que algunas
fases son largas; se acepta.""")])

fix('prompts/formato-de-benchmarks.md', [(
"Regla del repositorio y de este curso: **ninguna afirmación de rendimiento se",
"Regla de este curso: **ninguna afirmación de rendimiento se")])

fix('00-historia-de-la-empresa-meridian.md', [
("> **Relación con los otros documentos.** `alcance-del-proyecto.md` §5 define el dominio y su",
 "> **Relación con los otros documentos.** `prompts/alcance-del-proyecto.md` §5 define el dominio y su"),
("`alcance-del-proyecto.md` §5.2, y **ninguno reemplaza a Nexo ni al ERP**. Lo que sigue es de dónde\nsale cada uno en la empresa; el alcance técnico está en su `proyecto-NN-*.md`.",
 "`prompts/alcance-del-proyecto.md` §5.2, y **ninguno reemplaza a Nexo ni al ERP**. Lo que sigue es de\ndónde sale cada uno en la empresa; el alcance técnico está en su `prompts/proyecto-NN-*.md`."),
])
PY

# --- 2026-09-13T19:52:37 · Rewrite repo-rule mentions as course-rule
python3 - <<'PY'
import io
def fix(p, reps):
    s=io.open(p,encoding='utf-8').read()
    for a,b in reps:
        assert a in s, (p, a[:70])
        s=s.replace(a,b)
    io.open(p,'w',encoding='utf-8').write(s)
    print("ok", p)

fix('17-capstone.md', [(
"""> **tres de ellas respaldan afirmaciones que el curso hace sin medir** — lo que
> incumple la regla del `CLAUDE.md` del repositorio. **Hay dos salidas honestas:**""",
"""> **tres de ellas respaldan afirmaciones que el curso hace sin medir** — lo que
> incumple la regla de medición del curso. **Hay dos salidas honestas:**""")])

fix('15-rendimiento-y-profiling.md', [(
"""**ejercicio**, lo que técnicamente incumple la regla del repositorio. **Recomiendo""",
"""**ejercicio**, lo que técnicamente incumple la regla de medición del curso. **Recomiendo""")])

fix('14-observabilidad-y-hardening.md', [(
"""pequeña con `LogAttrs` y no tanto con `slog.Any`" y **eso no está medido**, lo
que incumple la regla del repositorio. **O se mide en la Fase 15 o se suaviza la""",
"""pequeña con `LogAttrs` y no tanto con `slog.Any`" y **eso no está medido**, lo
que incumple la regla de medición del curso. **O se mide en la Fase 15 o se suaviza la""")])

fix('13-lotes-scheduling-y-asincronia.md', [(
"""segundo" incumple la regla del repositorio. **Propuesta: B-27, o encajarla en""",
"""segundo" incumple la regla de medición del curso. **Propuesta: B-27, o encajarla en""")])

fix('BENCHMARKS.md', [(
"""respaldan afirmaciones que el curso hace sin medir, lo que incumple la regla del
repositorio. **Decisión editorial pendiente:**""",
"""respaldan afirmaciones que el curso hace sin medir, lo que incumple la regla de
medición del curso. **Decisión editorial pendiente:**""")])
PY

# --- 2026-09-13T19:52:43 · Replace remaining repo-rule mentions
python3 - <<'PY'
import io
for p in ['15-rendimiento-y-profiling.md','14-observabilidad-y-hardening.md','13-lotes-scheduling-y-asincronia.md','BENCHMARKS.md']:
    s=io.open(p,encoding='utf-8').read()
    n=s.count('regla del repositorio')
    s=s.replace('incumple la regla del repositorio','incumple la regla de medición del curso')
    s=s.replace('incumple la regla del\nrepositorio','incumple la regla de\nmedición del curso')
    io.open(p,'w',encoding='utf-8').write(s)
    print(p, n, '->', s.count('regla del repositorio'))
PY
grep -rn "regla del repositorio\|CLAUDE" *.md prompts/*.md

# --- 2026-09-13T19:52:47 · Check BENCHMARKS repo mention
grep -rn "repositorio\." BENCHMARKS.md; sed -n '1188,1194p' BENCHMARKS.md

# --- 2026-09-13T19:52:52 · Verify no CLAUDE refs and read doc-index sections
grep -rn "CLAUDE" . ; echo "--- estructura §8"; sed -n '186,200p' 0-ESTRUCTURA-CURSO.md; echo "--- README tail"; sed -n '85,100p' README.md

# --- 2026-09-13T19:53:02 · Index the historia document in README and structure
python3 - <<'PY'
import io
def fix(p, reps):
    s=io.open(p,encoding='utf-8').read()
    for a,b in reps:
        assert a in s, (p, a[:70])
        s=s.replace(a,b,1)
    io.open(p,'w',encoding='utf-8').write(s)
    print("ok", p)

fix('0-ESTRUCTURA-CURSO.md', [(
"""- [`00-convencion-de-git-y-tags.md`](00-convencion-de-git-y-tags.md) — commits y tags
- [`INSTINTOS.md`](INSTINTOS.md)""",
"""- [`00-convencion-de-git-y-tags.md`](00-convencion-de-git-y-tags.md) — commits y tags
- [`00-historia-de-la-empresa-meridian.md`](00-historia-de-la-empresa-meridian.md) — la empresa
  ficticia: personajes, cifras y los incidentes que originaron cada servicio. **Fuente de verdad
  de todo lo narrativo**; ninguna fase inventa un dato de Meridian por su cuenta
- [`INSTINTOS.md`](INSTINTOS.md)""")])

fix('README.md', [(
"""Documentos transversales: [`INSTINTOS.md`](INSTINTOS.md) (el catálogo de reflejos
☕), [`BENCHMARKS.md`](BENCHMARKS.md) (el banco de pruebas) y
[`00-convencion-de-git-y-tags.md`](00-convencion-de-git-y-tags.md).""",
"""Documentos transversales:
[`00-historia-de-la-empresa-meridian.md`](00-historia-de-la-empresa-meridian.md)
(quién es Meridian y de dónde sale cada servicio),
[`INSTINTOS.md`](INSTINTOS.md) (el catálogo de reflejos ☕),
[`BENCHMARKS.md`](BENCHMARKS.md) (el banco de pruebas) y
[`00-convencion-de-git-y-tags.md`](00-convencion-de-git-y-tags.md).""")])
PY

# --- 2026-09-13T19:53:11 · Audit relative markdown links across the course
python3 - <<'PY'
import re,os,io,glob
root='.'
bad=[]
for f in glob.glob('*.md')+glob.glob('prompts/*.md'):
    s=io.open(f,encoding='utf-8').read()
    for m in re.finditer(r'\]\(([^)]+)\)', s):
        t=m.group(1).split('#')[0].strip()
        if not t or t.startswith(('http','mailto:','#')): continue
        d=os.path.normpath(os.path.join(os.path.dirname(f), t))
        if not os.path.exists(d):
            ln=s[:m.start()].count('\n')+1
            bad.append(f"{f}:{ln} -> {t}")
print('\n'.join(sorted(set(bad))) or 'sin enlaces rotos')
PY

# --- 2026-09-13T19:53:19 · Fix template link and scan for appendix/external mentions
sed -i '' 's|](00-convencion-de-git-y-tags.md)|](../00-convencion-de-git-y-tags.md)|' prompts/plantillas-de-capitulo.md
echo "=== apendice ==="; grep -rni "apéndice\|apendice" *.md | grep -vi "no tiene apéndices\|no los tiene" | head -20
echo "=== externos ==="; grep -rniE "tu empresa|de tu trabajo|proyecto real tuyo|en el curso de|curso anterior|siguiente curso|otro curso" *.md | head -20

# --- 2026-09-13T19:53:28 · Check historia references in prompts and directory listings
grep -rni "historia" prompts/*.md | head -20; echo "=== raiz ==="; grep -rln "Meridian" *.md | head; echo "=== tree listings in prompts ==="; grep -rn "prompts/$\|prompts/  \|go-for-java-devs/" prompts/*.md | head -20

# --- 2026-09-13T19:53:36 · Final verification of references and links
echo "=== restos ==="; grep -rn "CLAUDE\|00-ambiente-y-tooling\|regla del repositorio\|del \`CLAUDE" . ; echo "(vacío = ok)"
echo; echo "=== links rotos ==="; python3 - <<'PY'
import re,os,io,glob
bad=[]
for f in glob.glob('*.md')+glob.glob('prompts/*.md'):
    s=io.open(f,encoding='utf-8').read()
    for m in re.finditer(r'\]\(([^)\s]+\.md)\)', s):
        t=m.group(1).split('#')[0]
        d=os.path.normpath(os.path.join(os.path.dirname(f), t))
        if not os.path.exists(d):
            bad.append(f"{f}:{s[:m.start()].count(chr(10))+1} -> {t}")
print('\n'.join(sorted(set(bad))) or 'ninguno')
PY
echo; echo "=== git ==="; git status --short -- .

# --- 2026-09-13T19:56:01 · Audit external refs and rough exercise counts
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/go-for-java-devs
echo "=== 1. refs a otros cursos / proyecto raiz ==="
grep -rniE "cursos-algoritmos|cursos-[a-z]+/|propuestas-cursos|_oskar|courses-ia-generated|CLAUDE\.md|ruta-nosql|angular|python-for-java|c-sharp|docker-container|/Users/" . || echo "ninguna"
echo
echo "=== 2. conteo de ejercicios declarado por fase (§8) ==="
for f in 0[0-9]-*.md 1[0-7]-*.md; do
  n=$(grep -cE "^[0-9]+\. " "$f" 2>/dev/null)
  echo "$f  lineas-numeradas:$n"
done

# --- 2026-09-13T19:56:10 · Count exercises per phase inside the exercises section
python3 - <<'PY'
import re,io,glob
for f in sorted(glob.glob('[01][0-9]-*.md')):
    if 'convencion' in f or 'historia' in f: continue
    s=io.open(f,encoding='utf-8').read()
    lines=s.split('\n')
    # find section 8 heading (Ejercicios) and section 9 (Referencias)
    st=en=None
    for i,l in enumerate(lines):
        if re.match(r'^##\s', l):
            if st is None and 'jercicio' in l: st=i
            elif st is not None and en is None and re.match(r'^##\s', l): en=i
    body='\n'.join(lines[st:en]) if st is not None else ''
    ex=re.findall(r'^(\d+)\.\s', body, re.M)
    d=re.findall(r'\*\*D[123]\b', body)
    print(f"{f:42s} sec8={'sí' if st else 'NO'}  ejercicios={len(ex)} max={max(map(int,ex)) if ex else 0}  D={len(set(d))}")
PY

# --- 2026-09-13T19:56:18 · List top-level sections of every phase
python3 - <<'PY'
import re,io,glob
for f in sorted(glob.glob('[01][0-9]-*.md')):
    if 'convencion' in f or 'historia' in f: continue
    s=io.open(f,encoding='utf-8').read()
    h=[l for l in s.split('\n') if re.match(r'^##\s',l)]
    print(f"--- {f} ({len(h)} secciones)")
    for l in h: print("   ",l[:80])
PY

# --- 2026-09-13T19:56:24 · Show heading hierarchy of phase 08
grep -n "^#\{2,4\} " 08-migracion-a-go-moderno.md | sed -n '1,80p'

# --- 2026-09-13T19:56:27 · Inspect the misleveled block in phase 08
sed -n '1055,1070p' 08-migracion-a-go-moderno.md

# --- 2026-09-13T19:56:35 · Re-audit section template ignoring fenced blocks
python3 - <<'PY'
import re,io,glob
tpl=['Propósito','Qué queda listo','Qué NO entra','Concepto mínimo','CLI de la fase','Construcción guiada','Autopsia','Ejercicios','Referencias','Veredicto']
for f in sorted(glob.glob('[01][0-9]-*.md')):
    if 'convencion' in f or 'historia' in f: continue
    s=io.open(f,encoding='utf-8').read(); infence=False; hs=[]
    for l in s.split('\n'):
        if l.lstrip().startswith('```'): infence = not infence; continue
        if not infence and re.match(r'^##\s',l): hs.append(l)
    num=[h for h in hs if re.match(r'^##\s+\S+\s+\d+\.',h)]
    ok = len(num)==10 and all(t.lower() in num[i].lower() for i,t in enumerate(tpl))
    print(f"{f:42s} secciones={len(hs)} numeradas={len(num)} plantilla={'OK' if ok else 'REVISAR'}")
    if not ok:
        for h in hs: print("      ",h[:70])
PY

# --- 2026-09-13T19:56:40 · List benchmark IDs and headings
echo "=== IDs en BENCHMARKS.md ==="; grep -oE "^#{2,3} .*B-[0-9]{2}|B-[0-9]{2}" BENCHMARKS.md | grep -oE "B-[0-9]{2}" | sort -u | tr '\n' ' '; echo
echo "=== entradas (encabezados) ==="; grep -nE "^#{2,3} " BENCHMARKS.md | head -50

# --- 2026-09-13T19:56:48 · Check benchmark entry count and proposed IDs
grep -nE "^## B-" BENCHMARKS.md | wc -l; grep -n "B-2[4-9]" BENCHMARKS.md; echo "=== B-25..B-31 en fases ==="; grep -rn "B-2[5-9]\|B-3[01]" *.md

# --- 2026-09-13T19:56:57 · Cross-check benchmark assignments per phase
python3 - <<'PY'
import re,io,glob
exp={'00':['B-01'],'01':['B-02','B-03','B-04'],'02':['B-05'],'03':['B-06'],'04':[],'05':[],
 '06':['B-07','B-08','B-09','B-10'],'07':[],'08':['B-11','B-12'],'09':['B-13','B-14','B-15','B-16'],
 '10':[],'11':[],'12':['B-17','B-18'],'13':['B-19','B-20'],'14':['B-21'],'15':['B-22','B-23'],'16':['B-24'],'17':[]}
for f in sorted(glob.glob('[01][0-9]-*.md')):
    if 'convencion' in f or 'historia' in f: continue
    n=f[:2]; s=io.open(f,encoding='utf-8').read()
    i=s.find('## 📐')
    sec=s[i:] if i>0 else ''
    got=sorted(set(re.findall(r'B-\d{2}', sec)))
    e=sorted(exp[n])
    miss=[x for x in e if x not in got]; extra=[x for x in got if x not in e]
    print(f"F{n} esperado={e} en📐={got} {'OK' if not miss else 'FALTA:'+str(miss)} {'extra:'+str(extra) if extra else ''}")
PY

# --- 2026-09-13T19:57:08 · Verify every declared mini project appears in its phase
python3 - <<'PY'
import re,io,glob
labs={'00':['hello-go','build-info','crossbuild'],'01':['movement-parser','text-toolkit','log-grep'],
'02':['shapes','store-registry','notifier'],'03':['error-chain','config-loader','json-codec'],
'04':['validator-tests','fake-clock','golden-report'],'05':['tiny-router','middleware-chain','httptest-lab'],
'06':['race-counter','deadlock-lab','leak-lab','unbounded-queue'],
'07':['cancellable-worker','timeout-client','graceful-server','leak-detector'],
'09':['pool-lab','tx-lab','cursor-vs-offset'],'10':['client-timeouts','backoff-lab','recorded-responses'],
'11':['bson-lab','aggregation-lab'],'12':['cache-aside-lab','stampede-lab','ratelimit-lab'],
'13':['chunked-stream','checkpoint-lab','outbox-lab'],'14':['slog-lab','metrics-lab','distroless-lab'],
'15':['benchstat-lab','escape-lab','pool-vs-alloc']}
files={f[:2]:io.open(f,encoding='utf-8').read() for f in glob.glob('[01][0-9]-*.md') if 'conv' not in f and 'hist' not in f}
tot=0
for n,ls in sorted(labs.items()):
    tot+=len(ls)
    miss=[l for l in ls if l not in files.get(n,'')]
    print(f"F{n}: {len(ls)} labs {'OK' if not miss else 'FALTAN EN LA FASE: '+str(miss)}")
print("total labs declarados:", tot)
PY

# --- 2026-09-13T19:57:13 · Check hours total and tag conventions
python3 - <<'PY'
h=[5,7,7,7,8,8,9,7,8,9,8,7,6,8,7,7,8,5]
print("suma horas:",sum(h),"fases:",len(h))
PY
echo "=== tags declarados en la convención ==="
grep -nE "fase-|bloque-a-completo|plataforma/|duelo/|meridian/|curso-completo|proyecto" 00-convencion-de-git-y-tags.md | head -40

# --- 2026-09-13T19:57:20 · Read the monorepo layout section of the git convention
sed -n '14,70p' 00-convencion-de-git-y-tags.md

# --- 2026-09-13T19:57:23 · Read stale tag notes in phases 07 and 17
sed -n '1715,1725p' 07-context-y-ciclo-de-vida.md; echo "=== F17 1408,1425 ==="; sed -n '1406,1426p' 17-capstone.md

# --- 2026-09-13T19:57:34 · Fix stale tag notes and lab count
python3 - <<'PY'
import io
def fix(p,reps):
    s=io.open(p,encoding='utf-8').read()
    for a,b in reps:
        assert a in s,(p,a[:60]); s=s.replace(a,b,1)
    io.open(p,'w',encoding='utf-8').write(s); print("ok",p)

fix('00-convencion-de-git-y-tags.md',[
("  labs/                    los 28 mini proyectos",
 "  labs/                    los 46 mini proyectos")])

fix('07-context-y-ciclo-de-vida.md',[(
"""- **El tag `bloque-a-completo`** — no está en la convención de nombres de
  `propuesta-fases-y-alcance.md` §4, que solo contempla `fase-NN` y los de
  proyecto. **Hay que añadirlo a `00-convencion-de-git-y-tags.md` o quitarlo de
  aquí.** Recomiendo añadirlo: el `git diff` entre ese tag y `fase-08` es un
  entregable declarado de la Fase 08.""",
"""- **El tag `bloque-a-completo`** — amplía la convención original de
  `prompts/propuesta-fases-y-alcance.md` §4, que solo contemplaba `fase-NN` y los
  de proyecto. **Ya está recogido en `00-convencion-de-git-y-tags.md` §3.3**, que
  es donde manda: el `git diff` entre ese tag y `fase-08` es un entregable
  declarado de la Fase 08. Resuelto.""")])

fix('17-capstone.md',[(
"""### Convención de tags — divergencias introducidas

El curso introduce tres tags que **no están en
`propuesta-fases-y-alcance.md` §4**, que solo contempla `fase-NN` y los de proyecto:

- `bloque-a-completo` (F07) — **usado dos veces en la F08** y en el cierre. Es un
  entregable declarado de la migración.
- `plataforma/v1.0-rc1` y `-rc2` (F14, F15).
- `duelo/v1.0` (F16), `meridian/v1.0` y `curso-completo` (F17).

**Hay que añadirlos a `00-convencion-de-git-y-tags.md` o retirarlos.** El primero
es el más importante: sin él, el `git diff bloque-a-completo fase-08` que la Fase
08 promete no funciona.""",
"""### Convención de tags — ampliación ya recogida

El curso amplía la convención original de `prompts/propuesta-fases-y-alcance.md`
§4 —que solo contemplaba `fase-NN` y los de proyecto— con cinco tags de hito:

- `bloque-a-completo` (F07) — **usado dos veces en la F08** y en el cierre. Es un
  entregable declarado de la migración.
- `plataforma/v1.0-rc1` y `-rc2` (F14, F15).
- `duelo/v1.0` (F16), `meridian/v1.0` y `curso-completo` (F17).

**Los cinco están recogidos en `00-convencion-de-git-y-tags.md` §3.3**, que es la
fuente de verdad de los tags. El más importante es el primero: sin él, el
`git diff bloque-a-completo fase-08` que la Fase 08 promete no funciona. Resuelto.""")])
PY

# --- 2026-09-13T19:57:40 · Read the path-leak passage in phase 14
sed -n '1105,1125p' 14-observabilidad-y-hardening.md

# --- 2026-09-13T19:57:43 · Remove author path and check canonical Meridian figures
sed -i '' 's|`/Users/oskar/dev/meridian/\.\.\.`|`/Users/tu/dev/meridian/...`|' 14-observabilidad-y-hardening.md
grep -rn "/Users/oskar" . || echo "sin rutas del autor"
echo "=== cifras canónicas de Meridian ==="
grep -rnoiE "(ciento cuarenta|140) tiendas|(treinta|30) socios|11 países|once países" *.md | sort | uniq -c | sort -rn | head -20

# --- 2026-09-13T19:57:50 · Count debt markers per phase
python3 - <<'PY'
import re,io,glob
for f in sorted(glob.glob('[01][0-9]-*.md')):
    if 'conv' in f or 'hist' in f: continue
    s=io.open(f,encoding='utf-8').read()
    d=len(re.findall('💸',s))
    print(f"{f[:2]}: 💸={d}")
PY
echo "=== deudas: 'se paga en la Fase' / 'paga la deuda' ==="
grep -rniE "deuda .{0,40}(Fase [0-9]+)|se paga en la Fase [0-9]+|paga la deuda" *.md | wc -l

# --- 2026-09-13T19:57:57 · Read closed-debts section of phase 14
awk '/^## 📌 Deudas cerradas/,/^## 📌 Pendientes/' 14-observabilidad-y-hardening.md | head -40

# --- 2026-09-13T19:58:05 · Collect open editorial decisions from authorship blocks
python3 - <<'PY'
import re,io,glob
pat=re.compile(r'(Decisión (editorial )?(necesaria|pendiente)|Decidir(:| antes)|Hay que (añadir|decidir)|Recomiendo|Propuesta: B-|hay que |NO cerrada|sin resolver)',re.I)
for f in sorted(glob.glob('*.md')):
    s=io.open(f,encoding='utf-8').read()
    i=s.find('## 📌')
    if i<0: continue
    for j,l in enumerate(s[i:].split('\n')):
        if pat.search(l):
            print(f"{f}: {l.strip()[:150]}")
PY

# --- 2026-09-13T19:58:10 · Read the course closing status block
awk '/^## 📌 Estado del curso al cierre/,/^## ☕/' 17-capstone.md | head -120

# --- 2026-09-13T19:58:18 · Verify the open pending items are still genuinely open
echo "goleak en F08:"; grep -c "goleak" 08-migracion-a-go-moderno.md
echo "testify en F09:"; grep -c "testify" 09-sql-postgres-sqlite.md
echo "rowserrcheck en F00:"; grep -c "rowserrcheck" 00-instalacion-ambiente-y-tooling.md
echo "claimed_at en F09:"; grep -c "claimed_at" 09-sql-postgres-sqlite.md
echo "replSet en F00:"; grep -c "replSet" 00-instalacion-ambiente-y-tooling.md
echo "replSet en F11:"; grep -c "replSet" 11-mongodb-y-modelado-documental.md
echo "container/heap en F06:"; grep -c "container/heap" 06-concurrencia.md
echo "httptrace en F15:"; grep -c "httptrace" 15-rendimiento-y-profiling.md
echo "pre-commit en F14:"; grep -c "pre-commit" 14-observabilidad-y-hardening.md

# --- 2026-09-13T19:58:21 · Inspect the ambiguous pending items
echo "--- goleak F08:"; grep -n "goleak" 08-migracion-a-go-moderno.md
echo "--- testify F09:"; grep -n "testify" 09-sql-postgres-sqlite.md
echo "--- claimed_at F09:"; grep -n "claimed_at" 09-sql-postgres-sqlite.md
echo "--- heap F06:"; grep -n "container/heap" 06-concurrencia.md
echo "--- httptrace F15:"; grep -n "httptrace" 15-rendimiento-y-profiling.md

# --- 2026-09-13T19:58:32 · Read the debts summary table tail
sed -n '178,186p' 0-ESTRUCTURA-CURSO.md

# --- 2026-09-13T19:58:38 · Complete the debts summary table with the unpaid debt
python3 - <<'PY'
import io
p='0-ESTRUCTURA-CURSO.md'
s=io.open(p,encoding='utf-8').read()
a="| `Makefile` sin validación · umbral de cobertura | F00 | F14 |"
b=("| `Makefile` sin validación · umbral de cobertura | F00 | F14 |\n"
   "| Retroceso lineal sin jitter | F02 | F10 |\n"
   "| `import _ \"time/tzdata\"` en imagen mínima | F09 | F14 |\n"
   "| ⚠️ **Hook de pre-commit** | **F00** | **sin pagar** |\n"
   "\n> ⚠️ **Una deuda de diecisiete sigue sin pagar:** el hook de pre-commit que la\n"
   "> Fase 00 anotó para la Fase 14 y que quedó implícito en `make ci`. Es la única\n"
   "> excepción del inventario, y está declarada como decisión abierta en el bloque de\n"
   "> autoría de la Fase 17.")
assert a in s
s=s.replace(a,b,1)
io.open(p,'w',encoding='utf-8').write(s)
print("ok")
PY
sed -n '170,195p' 0-ESTRUCTURA-CURSO.md

# --- 2026-09-13T19:58:49 · Reorder and relabel the debts inventory
python3 - <<'PY'
import io
p='0-ESTRUCTURA-CURSO.md'
s=io.open(p,encoding='utf-8').read()
old = s[s.index("Cada 💸 del curso declara su fase de cobro."):s.index("> autoría de la Fase 17.")+len("> autoría de la Fase 17.")]
new = """Cada 💸 del curso declara su fase de cobro. Este es el inventario completo; la
Fase 17 lo repite en su bloque de autoría con el detalle de cada sección.

| Deuda | Declarada | Pagada |
|---|---|---|
| `Makefile` sin validación · umbral de cobertura | F00 | F14 |
| Verificación por pantalla | F01 | F04 |
| `memstore` no concurrente | F02 | F06 |
| Retroceso lineal sin jitter | F02 | F10 |
| **SSRF en la URL del endpoint** | **F02** | **F14** |
| Logger provisional | F03 | F14 |
| Enrutado a mano | F05 | F08 |
| Sin apagado ordenado | F05 | F07 |
| Cola en memoria · `time.Timer` por entrega | F06 | F09 |
| Apagado sin plazo | F06 | F07 |
| `import _ "time/tzdata"` en imagen mínima | F09 | F14 |
| AtlasSync sin persistencia · caché en memoria | F10 | F11 · F12 |
| Firma HMAC sin verificar | F10 | F14 |
| ⚠️ **Hook de pre-commit** | **F00** | **sin pagar** |

> ⚠️ **Una deuda de diecisiete sigue sin pagar:** el hook de pre-commit que la
> Fase 00 anotó para la Fase 14 y que quedó implícito en `make ci`. Es la única
> excepción del inventario, y está declarada como decisión abierta en el bloque de
> autoría de la Fase 17."""
s=s.replace(old,new,1)
io.open(p,'w',encoding='utf-8').write(s)
print("ok")
PY

# --- 2026-09-13T19:58:57 · Final sweep of external refs and links
echo "=== refs externas (final) ==="
grep -rniE "cursos-[a-z]+/|propuestas-cursos|_oskar|courses-ia-generated|CLAUDE\.md|ruta-nosql|/Users/oskar|regla del repositorio|otros cursos|00-ambiente-y-tooling" . || echo "  ninguna ✅"
echo
echo "=== enlaces rotos (final) ==="
python3 - <<'PY'
import re,os,io,glob
bad=[]
for f in glob.glob('*.md')+glob.glob('prompts/*.md'):
    s=io.open(f,encoding='utf-8').read()
    for m in re.finditer(r'\]\(([^)\s]+\.md)\)', s):
        t=m.group(1).split('#')[0]
        if not os.path.exists(os.path.normpath(os.path.join(os.path.dirname(f),t))):
            bad.append(f"{f}:{s[:m.start()].count(chr(10))+1} -> {t}")
print('\n'.join(sorted(set(bad))) or '  ninguno ✅')
PY
echo
echo "=== archivos del curso ==="; ls *.md | tr '\n' ' '; echo; ls prompts/ | tr '\n' ' '

# --- 2026-09-13T19:59:02 · Check INSTINTOS coverage across phases
grep -cE "^#{2,3} " INSTINTOS.md; grep -oE "Fase [0-9]{2}|F[0-9]{2}\b" INSTINTOS.md | sort -u | tr '\n' ' '; echo; echo "--- encabezados:"; grep -nE "^## " INSTINTOS.md

# --- 2026-09-13T19:59:09 · Verify required recurring blocks in every phase
python3 - <<'PY'
import re,io,glob
for f in sorted(glob.glob('[01][0-9]-*.md')):
    if 'conv' in f or 'hist' in f: continue
    s=io.open(f,encoding='utf-8').read()
    i=s.find('## ⚖️ 10.')
    sec=s[i:]
    m={'📖 diccionario':'📖' in sec,'🏷️ tag':'🏷️' in sec or 'git tag' in sec,
       '🪞 instinto':'🪞' in s,'🩻 igual':'🩻' in s,'⚰️ autopsia':'⚰️' in s,
       '🧨 rompe':'🧨' in s,'⚖️ cuándo NO':'Cuándo NO usar' in sec or 'cuándo NO usar' in sec}
    falta=[k for k,v in m.items() if not v]
    print(f"{f[:2]}: {'OK' if not falta else 'FALTA '+', '.join(falta)}")
PY

# --- 2026-09-13T19:59:13 · Inspect phase 16 closing section
awk '/^## ⚖️ 10\./,0' 16-go-frente-a-spring-boot.md | grep -nE "^### |^## " | head -20

# --- 2026-09-13T19:59:16 · Read phase 16 honest verdict
awk '/^### ⚖️ El veredicto honesto/,/^### 📖/' 16-go-frente-a-spring-boot.md | head -70

# --- 2026-09-13T19:59:34 · Verify the compose replSet blocker
grep -n -A6 "mongo" 00-instalacion-ambiente-y-tooling.md | sed -n '1,40p'; echo "=== F11 ej 20 ==="; awk '/^## 🧪 8\./,/^## 📚/' 11-mongodb-y-modelado-documental.md | grep -n -A4 "^20\."

# --- 2026-09-13T19:59:40 · Read F11 replSet notes
grep -n -B3 -A6 "replSet" 11-mongodb-y-modelado-documental.md

# --- 2026-09-13T19:59:49 · Qualify prompts-file references with their directory
python3 - <<'PY'
import re,io,glob
names=['formato-de-benchmarks.md','alcance-del-proyecto.md','propuesta-fases-y-alcance.md',
       'guia-de-estilo-y-convenciones.md','plantillas-de-capitulo.md','aprendizaje.md']
tot=0
for f in glob.glob('*.md'):
    s=io.open(f,encoding='utf-8').read(); o=s
    for n in names:
        s=re.sub(r'(?<!prompts/)(?<![\w/.-])'+re.escape(n), 'prompts/'+n, s)
    if s!=o:
        io.open(f,'w',encoding='utf-8').write(s)
        c=sum(s.count('prompts/'+n)-o.count('prompts/'+n) for n in names)
        tot+=c; print(f"{f}: +{c}")
print("total",tot)
PY
grep -rn "prompts/prompts/" *.md || echo "sin dobles ✅"

# --- 2026-09-13T19:59:57 · Final verification pass
grep -rn "prompts/formato\|prompts/alcance\|prompts/propuesta\|prompts/guia\|prompts/plantillas\|prompts/aprendizaje" *.md | head -25
echo "=== verificacion final: enlaces + refs externas ==="
python3 - <<'PY'
import re,os,io,glob
bad=[]
for f in glob.glob('*.md')+glob.glob('prompts/*.md'):
    s=io.open(f,encoding='utf-8').read()
    for m in re.finditer(r'\]\(([^)\s]+\.md)\)', s):
        t=m.group(1).split('#')[0]
        if not os.path.exists(os.path.normpath(os.path.join(os.path.dirname(f),t))):
            bad.append(f"{f} -> {t}")
print('enlaces rotos:', '\n'.join(sorted(set(bad))) or 'ninguno ✅')
PY
grep -rniE "cursos-[a-z]+/|propuestas-cursos|_oskar|courses-ia|CLAUDE\.md|/Users/oskar" . || echo "refs externas: ninguna ✅"

# --- 2026-09-13T20:01:28 · Read the compose section of phase 00
sed -n '700,790p' 00-instalacion-ambiente-y-tooling.md

# --- 2026-09-13T20:01:46 · Add replica-set Mongo service to the compose in phase 00
python3 - <<'PY'
import io
p='00-instalacion-ambiente-y-tooling.md'
s=io.open(p,encoding='utf-8').read()

old = """  valkey:
    image: valkey/valkey:8-alpine
    container_name: meridian-valkey
    ports:
      - "6379:6379"
    healthcheck:
      test: ["CMD", "valkey-cli", "ping"]
      interval: 2s
      timeout: 3s
      retries: 15

volumes:
  postgres-data:
  mongo-data:
```

```bash
make up
docker compose ps
make down
```
"""

new = """  valkey:
    image: valkey/valkey:8-alpine
    container_name: meridian-valkey
    ports:
      - "6379:6379"
    healthcheck:
      test: ["CMD", "valkey-cli", "ping"]
      interval: 2s
      timeout: 3s
      retries: 15

  # Mongo en conjunto de réplicas de un solo nodo. NO arranca con `make up`:
  # vive tras un perfil porque solo lo necesita un ejercicio de la Fase 11, el de
  # transacciones multi-documento. El `mongo` de arriba es una instancia suelta y
  # se queda así a propósito: ese ejercicio pide demostrar que la transacción
  # FALLA contra una instancia suelta antes de hacerla funcionar aquí.
  mongo-rs:
    image: mongo:7
    container_name: meridian-mongo-rs
    profiles: ["rs"]
    command: ["mongod", "--replSet", "rs0", "--bind_ip_all"]
    ports:
      - "27018:27017"
    volumes:
      - mongo-rs-data:/data/db
    healthcheck:
      # Se inicia solo la primera vez: rs.status() falla mientras no haya conjunto,
      # y entonces rs.initiate() lo crea. Idempotente, que es lo que quieres en un
      # healthcheck.
      test: >
        mongosh --quiet --eval
        "try { rs.status().ok } catch (e) { rs.initiate({_id:'rs0',members:[{_id:0,host:'localhost:27017'}]}).ok }"
      interval: 2s
      timeout: 5s
      retries: 30

volumes:
  postgres-data:
  mongo-data:
  mongo-rs-data:
```

```bash
make up
docker compose ps
make down
```

**Y el conjunto de réplicas, solo cuando un ejercicio lo pida:**

```bash
docker compose --profile rs up -d mongo-rs
# Cadena de conexión: mongodb://localhost:27018/?replicaSet=rs0&directConnection=true
docker compose --profile rs down
```

> 📝 **Por qué dos Mongo y no uno con `--replSet`.** Un conjunto de réplicas de un
> nodo soporta todo lo que soporta una instancia suelta, así que sería más simple
> dejar solo el segundo. Pero entonces el curso nunca vería el error que da una
> transacción multi-documento contra una topología que no la admite —que es poco
> obvio y que **todo el mundo se come una vez en producción**—. El ejercicio 20 de
> la Fase 11 lo provoca a propósito. Dos contenedores, y uno apagado por defecto,
> es el precio de poder enseñarlo.
"""
assert old in s
s=s.replace(old,new,1)
io.open(p,'w',encoding='utf-8').write(s)
print("ok")
PY

# --- 2026-09-13T20:01:49 · Read golangci-lint config in phase 00
sed -n '835,930p' 00-instalacion-ambiente-y-tooling.md

# --- 2026-09-13T20:02:03 · Add rowserrcheck and sqlclosecheck linters to phase 00
python3 - <<'PY'
import io
p='00-instalacion-ambiente-y-tooling.md'
s=io.open(p,encoding='utf-8').read()
old="""    - errorlint     # comparaciones de error con == en vez de errors.Is
"""
new="""    - errorlint     # comparaciones de error con == en vez de errors.Is
    - rowserrcheck  # rows.Err() sin comprobar tras recorrer un sql.Rows: la Fase 09
    - sqlclosecheck # sql.Rows y sql.Stmt sin cerrar: la otra mitad del mismo bug
"""
assert old in s; s=s.replace(old,new,1)

old2="""De esta lista, dos merecen un comentario. **`errcheck`** es el que más va a
protestar al principio y el que más valor da: en Go se puede ignorar un error
escribiendo `_`, y ese es el agujero real que las excepciones comprobadas de Java
no tienen (lo discutimos en serio en la Fase 03). **`bodyclose`** y **`noctx`**
todavía no tienen nada que revisar, porque no hay clientes HTTP, pero los dejamos
puestos desde ahora para que cuando llegue el código, el linter ya esté vigilando."""
new2="""De esta lista, dos merecen un comentario. **`errcheck`** es el que más va a
protestar al principio y el que más valor da: en Go se puede ignorar un error
escribiendo `_`, y ese es el agujero real que las excepciones comprobadas de Java
no tienen (lo discutimos en serio en la Fase 03). **`bodyclose`** y **`noctx`**
todavía no tienen nada que revisar, porque no hay clientes HTTP, pero los dejamos
puestos desde ahora para que cuando llegue el código, el linter ya esté vigilando.

Lo mismo vale para **`rowserrcheck`** y **`sqlclosecheck`**, que no verán una
línea de SQL hasta la Fase 09. Se quedan aquí porque los dos errores que detectan
—recorrer un `sql.Rows` y no mirar `rows.Err()` al salir del bucle, y dejar el
`Rows` sin cerrar— **no fallan el test: devuelven menos filas en silencio y filtran
conexiones del pool**. Son el tipo de bug que en Java no existe porque el
`try-with-resources` y las excepciones lo cubren, y en Go se te cuela entero hasta
producción. Que el linter esté puesto desde el primer día evita tener que ir a
buscarlos después."""
assert old2 in s; s=s.replace(old2,new2,1)
io.open(p,'w',encoding='utf-8').write(s)
print("ok")
PY

# --- 2026-09-13T20:02:08 · Read the orphan-delivery recovery passage in phase 09
sed -n '855,915p' 09-sql-postgres-sqlite.md

# --- 2026-09-13T20:02:10 · Locate the deliveries migration and claim SQL
grep -n "CREATE TABLE deliveries\|claimPendingSQL\|next_attempt\|in_flight" 09-sql-postgres-sqlite.md | head -30

# --- 2026-09-13T20:02:13 · Read deliveries table DDL and claim SQL
sed -n '525,570p' 09-sql-postgres-sqlite.md; echo "=== 830,856 ==="; sed -n '830,856p' 09-sql-postgres-sqlite.md

# --- 2026-09-13T20:02:36 · Add claimed_at column, reaper index and claim sealing to phase 09
python3 - <<'PY'
import io
p='09-sql-postgres-sqlite.md'
s=io.open(p,encoding='utf-8').read()

# 1. DDL: columna claimed_at + indice del recuperador
old="""    next_attempt TIMESTAMPTZ NOT NULL,
    last_error   TEXT        NOT NULL DEFAULT '',
    created_at   TIMESTAMPTZ NOT NULL,
    delivered_at TIMESTAMPTZ,

    CONSTRAINT deliveries_status_valid CHECK (
        status IN ('pending','in_flight','delivered','failing','dead','cancelled')
    )
);"""
new="""    next_attempt TIMESTAMPTZ NOT NULL,
    last_error   TEXT        NOT NULL DEFAULT '',
    created_at   TIMESTAMPTZ NOT NULL,
    delivered_at TIMESTAMPTZ,

    -- Cuándo la reclamó una instancia. NULL mientras está pendiente. Es lo que
    -- permite al recuperador distinguir una entrega en curso de una huérfana:
    -- sin esta columna, una instancia que muere deja la fila en in_flight para
    -- siempre y nadie puede saber desde cuándo. Ver §6.4.
    claimed_at   TIMESTAMPTZ,

    CONSTRAINT deliveries_status_valid CHECK (
        status IN ('pending','in_flight','delivered','failing','dead','cancelled')
    )
);"""
assert old in s; s=s.replace(old,new,1)

old="""CREATE INDEX deliveries_endpoint_idx ON deliveries (endpoint_id, created_at DESC);"""
new="""CREATE INDEX deliveries_endpoint_idx ON deliveries (endpoint_id, created_at DESC);

-- El índice del recuperador de huérfanas (§6.4). También parcial, y por el mismo
-- motivo: las in_flight son siempre unas pocas, y el barrido periódico tiene que
-- costar lo que cuestan ellas, no lo que ocupa el histórico.
CREATE INDEX deliveries_reaper_idx
    ON deliveries (claimed_at)
    WHERE status = 'in_flight';"""
assert old in s; s=s.replace(old,new,1)

# 2. La consulta de reclamación escribe claimed_at
old="""UPDATE deliveries d
SET status = 'in_flight',
    attempts = d.attempts + 1
FROM ("""
new="""UPDATE deliveries d
SET status = 'in_flight',
    attempts = d.attempts + 1,
    -- Se sella la reclamación con la hora. Es lo único que el recuperador de
    -- §6.4 necesita para decidir si esta entrega sigue viva o su instancia murió.
    claimed_at = $1
FROM ("""
assert old in s; s=s.replace(old,new,1)

old="""RETURNING d.id, d.event_id, d.endpoint_id, d.status, d.attempts,
          d.max_attempts, d.next_attempt, d.last_error, d.created_at;"""
new="""RETURNING d.id, d.event_id, d.endpoint_id, d.status, d.attempts,
          d.max_attempts, d.next_attempt, d.last_error, d.created_at,
          d.claimed_at;"""
assert old in s; s=s.replace(old,new,1)

# 3. El bloque ⚠️: ya no "obliga a añadir", la columna está
old="""> Eso obliga a añadir una columna `claimed_at`, y **es exactamente el tipo de
> detalle que separa una cola de juguete de una que funciona**. El plazo del
> recuperador tiene que ser mayor que el plazo máximo de una entrega, o
> recuperarás trabajo que sigue en curso y entregarás dos veces."""
new="""> Por eso la tabla lleva la columna `claimed_at` y el índice parcial
> `deliveries_reaper_idx` que viste en §6.2, y por eso la consulta de reclamación
> la sella: **es exactamente el tipo de detalle que separa una cola de juguete de
> una que funciona**, y se paga en el esquema, no en el código.
>
> Dos reglas al configurarlo, y las dos se aprenden rompiéndolas:
>
> - **El plazo del recuperador tiene que ser mayor que el plazo máximo de una
>   entrega.** Si no, recuperas trabajo que sigue en curso y entregas dos veces.
>   Con el `timeout` de cliente que la Fase 10 le pone a EventRelay, cinco minutos
>   sobra de largo.
> - **Recuperar no es reintentar gratis.** La fila vuelve a `pending` con su
>   `attempts` ya incrementado, porque el intento ocurrió aunque no sepamos cómo
>   acabó. Restarlo convertiría una instancia que muere en bucle en entregas
>   infinitas contra el socio.
>
> El recuperador es un trabajo periódico, y el sitio donde se programa de verdad
> —con su `context`, su cancelación y su solapamiento— es la Fase 13."""
assert old in s; s=s.replace(old,new,1)
io.open(p,'w',encoding='utf-8').write(s)
print("ok")
PY

# --- 2026-09-13T20:02:41 · Read section 6.6 of phase 14
grep -n "6.6" 14-observabilidad-y-hardening.md | head; echo "---"; sed -n '1040,1112p' 14-observabilidad-y-hardening.md

# --- 2026-09-13T20:03:03 · Implement the pre-commit hook in phase 14
python3 - <<'PY'
import io
p='14-observabilidad-y-hardening.md'
s=io.open(p,encoding='utf-8').read()
old="""".PHONY: ci
ci: fmt vet lint test-race cover-check vuln ## Todo lo que CI ejecuta
```
""".strip('"')
new=""".PHONY: ci
ci: fmt vet lint test-race cover-check vuln ## Todo lo que CI ejecuta

.PHONY: hooks
hooks: ## Instala el hook de pre-commit (deuda de la Fase 00)
	git config core.hooksPath .githooks
	@echo "hooks instalados: $$(git config core.hooksPath)"
```

**Y el hook, que es la última deuda que la Fase 00 dejó abierta:**

```bash
# .githooks/pre-commit
#!/usr/bin/env bash
set -euo pipefail

# Rápido a propósito. Un hook que tarda más de unos segundos se termina saltando
# con --no-verify, y un hook que se salta no existe. Lo lento (los tests con
# -race, la cobertura, govulncheck) es trabajo de `make ci`, no de aquí.

# 1. Formato: sobre los archivos en el índice, no sobre todo el repositorio.
staged=$(git diff --cached --name-only --diff-filter=ACM -- '*.go')
[ -z "$staged" ] && exit 0

unformatted=$(gofmt -l $staged)
if [ -n "$unformatted" ]; then
  echo "❌ sin formatear:"; echo "$unformatted"
  echo "   corrige con: gofmt -w $unformatted"
  exit 1
fi

# 2. go vet sobre los paquetes tocados.
pkgs=$(echo "$staged" | xargs -n1 dirname | sort -u | sed 's|^|./|')
go vet $pkgs

# 3. El linter, solo sobre el diff. --new-from-rev evita que el hook te bloquee
#    por deuda que ya estaba ahí antes de tu commit.
golangci-lint run --new-from-rev=HEAD --fix=false $pkgs
```

```bash
chmod +x .githooks/pre-commit
make hooks
```

> 🧭 **`core.hooksPath` en vez de `.git/hooks/`.** Los hooks de `.git/hooks/` no se
> versionan y cada persona del equipo tiene los suyos, que es como no tener
> ninguno. `core.hooksPath` apunta a un directorio del repositorio, así que el hook
> se revisa en un PR como cualquier otro código. El precio es que cada clon tiene
> que ejecutar `make hooks` una vez, y por eso está en el `Makefile` y no en un
> README que nadie lee.

> ⚠️ **Un hook no sustituye a CI, y creerlo es el error.** Cualquiera puede pasar
> `--no-verify`, y hay que poder: a veces necesitas commitear roto en tu rama. El
> hook está para ahorrarte el viaje de ida y vuelta al pipeline por una errata de
> formato, no para ser la puerta. **La puerta es `make ci`**, que corre en el
> servidor, donde nadie puede saltársela.
"""
assert old in s; s=s.replace(old,new,1)

# Cerrar la deuda en la tabla y quitar el aviso
old2="""| Hook de pre-commit | Fase 00 📌 | **NO cerrada** | ⚠️ |

> ⚠️ **El hook de pre-commit** lo anotó la Fase 00 como pendiente para esta fase y
> **no se ha implementado**. Está implícito en `make ci`, que es defendible, pero la
> promesa era explícita. **Decidir: añadirlo a §6.6 (son diez líneas con un
> `.githooks/pre-commit` y `core.hooksPath`) o retirar el pendiente de la Fase 00.**
> Recomiendo añadirlo."""
new2="""| Hook de pre-commit | Fase 00 📌 | §6.6 (`.githooks/` + `make hooks`) | ✅ |

> ✅ **Las siete deudas que esta fase tenía asignadas quedan cerradas.** La del
> hook de pre-commit era la última y estuvo a punto de quedarse implícita en
> `make ci`; se implementó explícitamente porque la promesa de la Fase 00 era
> explícita, y porque `--new-from-rev` lo hace útil en vez de molesto."""
assert old2 in s; s=s.replace(old2,new2,1)
io.open(p,'w',encoding='utf-8').write(s)
print("ok")
PY

# --- 2026-09-13T20:03:13 · Read proposed benchmark notes in phases 10 and 04
sed -n '2070,2095p' 10-clientes-http-y-apis-externas.md; echo "=== F04 1865,1880 ==="; sed -n '1865,1880p' 04-testing-dobles-cobertura.md

# --- 2026-09-13T20:03:24 · Read the BENCHMARKS header and rules
sed -n '1,66p' BENCHMARKS.md

# --- 2026-09-13T20:03:27 · Read a full benchmark entry as template
sed -n '223,262p' BENCHMARKS.md

# --- 2026-09-13T20:03:31 · Find insertion point in BENCHMARKS
grep -n "^## B-24\|^## 📋 Mediciones propuestas\|^---" BENCHMARKS.md | tail -20; echo "---"; sed -n '1145,1215p' BENCHMARKS.md

# --- 2026-09-13T20:04:43 · Add benchmarks B-25 to B-29 and resolve the proposals block
python3 - <<'PY'
import io
p='BENCHMARKS.md'
s=io.open(p,encoding='utf-8').read()

nuevas = """
## B-25 — Amplificación del reintento: retroceso fijo frente a exponencial con jitter

**Fase:** 10 · **Proyecto:** EventRelay + `labs/backoff-lab` · **Fecha:** _____

### Hipótesis
Ante un socio que devuelve 503 durante 60 segundos, **el retroceso fijo multiplica
la carga sobre el socio caído en vez de aliviarla**, y el exponencial con jitter la
mantiene por debajo de la carga nominal. La hipótesis falsable: con 500 entregas
en vuelo, el retroceso fijo de 1 s produce **más de diez veces** las peticiones por
segundo que el exponencial con jitter completo, y el socio tarda más en
recuperarse aunque la carga entrante sea la misma.

### Condiciones
REF-1 · Go moderno · `fakeconsumer` configurado para devolver 503 durante 60 s y
luego 200 · 500 entregas encoladas · una sola instancia de EventRelay ·
`max_attempts=8`.

### Cómo reproducirlo
```bash
# El fakeconsumer registra la marca de tiempo de cada petición recibida.
go test -run TestRetryAmplification -v ./services/eventrelay/internal/delivery

# Histograma de peticiones por segundo, a partir del log del consumidor.
go run ./labs/backoff-lab -input fakeconsumer.log -bucket 1s
```

### Resultados

| Estrategia | Pico pet/s | Total de peticiones | Tiempo hasta drenar la cola | Entregas muertas |
|---|---|---|---|---|
| Sin retroceso (inmediato) | | | | |
| Fijo, 1 s | | | | |
| Exponencial sin jitter | | | | |
| Exponencial + jitter completo | | | | |

**Histograma** — peticiones por segundo, los primeros 120 s, una fila por
estrategia. Es el entregable de la entrada: el número medio miente aquí, la forma
de la curva no.

### Veredicto
Provisional: **el retroceso sin jitter no arregla el problema, lo reprograma.**
Todas las entregas fallan a la vez, esperan lo mismo y vuelven a la vez: el pico
se conserva y se desplaza. **El jitter es lo que rompe la sincronización**, y por
eso es la parte no negociable de la política, no un adorno del retroceso.

Si tus números muestran que el exponencial sin jitter ya basta, mira cuántas
entregas entraron en vuelo a la vez: con pocas, la sincronización no se nota y la
entrada no demuestra nada.

### Qué NO demuestra
Un solo socio y un solo modo de fallo (503 limpio y rápido). Un socio que responde
lento en vez de fallar produce otra foto, y es la peor de las dos. No cubre la
doble capa de reintento (aplicación + malla de servicios), que multiplica los
intentos y se discute en el ⚖️ de la Fase 10 sin medirse. No mide el efecto sobre
el resto de socios sanos, que es el argumento real del aislamiento.

---

## B-26 — MongoDB: `$push` sin límite frente al tamaño del documento

**Fase:** 11 · **Proyecto:** AtlasSync + `labs/bson-lab` · **Fecha:** _____

### Hipótesis
El array que crece sin límite dentro del documento **degrada la lectura mucho
antes de acercarse al límite de 16 MB**. Hipótesis falsable: con 10.000 elementos
en el array, la lectura del documento completo cuesta más de diez veces lo que
costaba con 100, aunque la consulta solo necesite tres campos de la raíz.

### Condiciones
REF-1 · Mongo 7 en Docker · un documento por variante · proyección explícita
frente a lectura completa · driver v2.

### Cómo reproducirlo
```bash
go test -run '^$' -bench BenchmarkDocumentGrowth -benchmem -count=10 ./labs/bson-lab
mongosh --eval 'db.products.stats().avgObjSize'
```

### Resultados

| Elementos en el array | Tamaño del doc | Lectura completa (ms) | Con proyección (ms) | `$push` (ms) |
|---|---|---|---|---|
| 100 | | | | |
| 1.000 | | | | |
| 10.000 | | | | |
| 100.000 | | | | |

### Veredicto
Provisional: **"los documentos no crecen sin límite" deja de ser un consejo y pasa
a ser un hecho medido.** El patrón de subcolección de la Fase 11 no es purismo de
modelado: es lo que mantiene plana la curva. Y la proyección explícita es el
parche barato cuando el modelo ya está mal y no se puede cambiar hoy.

### Qué NO demuestra
Un documento, sin concurrencia y sin contención de escritura. El caso feo real es
`$push` concurrente sobre el mismo documento, donde el coste no es el tamaño sino
el bloqueo. Tampoco mide el efecto sobre el conjunto de trabajo en RAM, que es
donde esto de verdad duele en producción.

---

## B-27 — El despachador del outbox frente al número de instancias

**Fase:** 13 · **Proyecto:** OpsReport + EventRelay · **Fecha:** _____

### Hipótesis
La cola en base de datos con `SKIP LOCKED` **escala de forma útil hasta unas pocas
instancias y luego deja de hacerlo**, porque la contención sobre el índice parcial
y el viaje de ida y vuelta a PostgreSQL dominan. Hipótesis falsable: pasar de 1 a
4 instancias multiplica el rendimiento por más de 2,5; pasar de 4 a 8 lo multiplica
por menos de 1,3.

**Esta es la entrada que sostiene el ⚖️ de la Fase 13**, donde se afirma que la
cola en base de datos aguanta "unos pocos miles de mensajes por segundo" antes de
que convenga un bróker.

### Condiciones
REF-1 · PostgreSQL 16 en Docker con `cpus=4` · 100.000 filas en el outbox ·
`fakeconsumer` respondiendo 200 en menos de 1 ms · lote de reclamación de 100 ·
todas las instancias en la misma máquina.

### Cómo reproducirlo
```bash
make up
go run ./tools/outbox-seed -rows 100000
for n in 1 2 4 8 16; do
  ./scripts/dispatch-bench.sh --instances "$n" --duration 60s
done
```

### Resultados

| Instancias | Mensajes/s | p99 de reclamación (ms) | Reclamaciones vacías | CPU de PostgreSQL |
|---|---|---|---|---|
| 1 | | | | |
| 2 | | | | |
| 4 | | | | |
| 8 | | | | |
| 16 | | | | |

### Veredicto
Provisional: **hay un punto en el que añadir instancias solo añade carga a la base
de datos.** Ese punto —y no una cifra citada de un blog— es el que decide cuándo
la cola en base de datos deja de bastar y toca Kafka, NATS o Rabbit. Si tus
números lo sitúan mucho más arriba de lo esperado, mira el porcentaje de
reclamaciones vacías: es el primer indicador de que las instancias se estorban.

### Qué NO demuestra
Todas las instancias en la misma máquina y contra la misma base de datos local:
sin latencia de red real, el techo aparece **antes** de donde aparecería en
producción, no después. No mide el coste operativo del bróker alternativo, que es
la otra mitad de la decisión. No cubre el particionado por clave, que es lo que
hace escalar a un bróker de verdad.

---

## B-28 — Coste del middleware de observabilidad por petición

**Fase:** 15 · **Proyecto:** OpsReport · **Fecha:** _____

**Pedida por tres fases** —la 05, la 10 y la 14— y medida aquí, que es donde el
banco de pruebas ya existe.

### Hipótesis
La cadena completa de middleware (request-id, logging estructurado, métricas y
traza) cuesta **menos de 50 µs por petición** y la parte cara es el muestreo de la
traza, no el logging. Hipótesis falsable: con la traza al 100% el coste supera al
resto de la cadena junto.

### Condiciones
REF-1 · Go moderno · endpoint que no toca la base de datos, para aislar el
middleware del trabajo real · `httptest` y carga con `hey`.

### Cómo reproducirlo
```bash
go test -run '^$' -bench BenchmarkMiddlewareChain -benchmem -count=10 \\
  ./services/opsreport/internal/httpapi | tee mw.txt
benchstat mw.txt
```

### Resultados

| Cadena | ns/op | B/op | allocs/op | Δ sobre la cadena vacía |
|---|---|---|---|---|
| Sin middleware | | | | — |
| + request-id | | | | |
| + logging (`slog`, `LogAttrs`) | | | | |
| + métricas | | | | |
| + traza, muestreo 100% | | | | |
| + traza, muestreo 1% | | | | |

### Veredicto
Provisional: **la observabilidad se paga y el precio es barato, pero no es cero,
y conviene saber qué línea de la cadena lo cuesta.** El muestreo no es un ajuste
de coste de almacenamiento: es también un ajuste de latencia.

Esta entrada también resuelve la afirmación que la Fase 14 §6.2 hacía sobre el
coste de `slog`: la fila de logging la mide con atributos tipados, y el ejercicio
23 de esta fase la extiende a `slog.Any` y a la forma variádica.

### Qué NO demuestra
Un endpoint trivial maximiza el peso relativo del middleware. Sobre un endpoint
que hace una consulta a PostgreSQL, todo esto se vuelve ruido — y ese es
justamente el veredicto útil. No mide el coste del *exporter* ni el de la red
hacia el colector, que son asíncronos pero no gratis.

---

## B-29 — Fake frente a mock generado: tiempo de suite

**Fase:** 10 · **Proyecto:** los cuatro servicios · **Fecha:** _____

La candidata que `prompts/formato-de-benchmarks.md` §1 nombra desde el principio y
que la Fase 04 dejó anotada. Se mide aquí, donde `go.uber.org/mock` entra en el
curso.

### Hipótesis
El fake escrito a mano **no es más rápido por magia**: gana en tiempo de suite
sobre todo porque no hay generación previa ni reflexión en la verificación de
expectativas. Hipótesis falsable: sobre la misma suite, la variante con mocks
generados tarda más del 20% adicional, y la diferencia crece con el número de
expectativas por test.

### Condiciones
REF-1 · la misma suite implementada dos veces sobre la misma interfaz ·
`-count=1` con caché limpia · se mide también el `go generate` previo, porque en
CI se paga en cada corrida.

### Cómo reproducirlo
```bash
go clean -testcache
time go generate ./...
time go test ./services/... -run 'Fake'
time go test ./services/... -run 'Mock'
```

### Resultados

| Variante | Tiempo de suite | `go generate` | Líneas de doble | Líneas generadas |
|---|---|---|---|---|
| Fake a mano | | — | | — |
| `go.uber.org/mock` | | | | |

### Veredicto
Provisional: **la diferencia de tiempo es pequeña y el argumento real no es el
tiempo.** El fake gana en legibilidad del fallo —el test dice qué pasó, no qué
expectativa no se cumplió— y pierde cuando la interfaz es grande o cuando de
verdad necesitas verificar la interacción. Si tus números muestran una diferencia
de tiempo grande, cuenta las expectativas por test antes de sacar conclusiones:
probablemente estés midiendo un estilo de test, no una herramienta.

### Qué NO demuestra
Una suite y un tamaño de interfaz. El coste del mock generado crece con el número
de métodos, y el del fake también: por eso la regla de la Fase 02 sobre interfaces
pequeñas decide más que la elección de herramienta. No mide el coste de
mantenimiento, que es donde la decisión se paga de verdad y que ningún benchmark
captura.

---
"""

marcador = "\n## 📋 Mediciones propuestas sin identificador"
assert marcador in s
s = s.replace(marcador, nuevas + marcador, 1)

old_block = s[s.index("## 📋 Mediciones propuestas sin identificador"):s.index("## 📖 Numeración")]
new_block = """## 📋 Mediciones propuestas y no asignadas

Siete propuestas surgieron durante la escritura del curso. **Cinco se asignaron**
—B-25 a B-29, arriba— y **dos se resolvieron suavizando la afirmación** en vez de
midiéndola, que es la otra salida honesta que el formato admite:

| Propuesta | Pedida por | Resolución |
|---|---|---|
| Amplificación del reintento (histograma) | F10 | ✅ **B-25** |
| `$push` frente al tamaño del documento | F11 | ✅ **B-26** |
| Rendimiento del outbox por instancias | F13 | ✅ **B-27** |
| Coste del middleware por petición | F05, F10, F14 | ✅ **B-28**, medida en la F15 |
| Fake frente a mock en tiempo de suite | F04, F10, formato §1 | ✅ **B-29** |
| `slog` frente a `log.Printf` | F14 | 🔤 afirmación suavizada a lo estructural, y la fila de logging de **B-28** la cubre |
| `ctx.Value` por profundidad del árbol | F07 | 🔤 afirmación suavizada a lo estructural |
| Efecto de `MaxIdleConnsPerHost` | F10 | 📎 sección de **B-23** |

> 🧭 **Las dos suavizadas no son una derrota.** El formato §3 dice que ante una
> afirmación sin medición hay dos salidas —medir o no afirmar—, y para un dato que
> no cambia ninguna decisión de diseño, la segunda es la barata y la honesta. Lo
> que no se admite es la tercera: escribirla igual con un "suele ser".

---

"""
s = s.replace(old_block, new_block, 1)
io.open(p,'w',encoding='utf-8').write(s)
print("ok")
PY
grep -c "^## B-" BENCHMARKS.md

# --- 2026-09-13T20:04:48 · Locate the two unmeasured claims
grep -n "LogAttrs" 14-observabilidad-y-hardening.md | head; echo "=== ctx.Value F07 ==="; grep -n "ctx.Value\|profundidad" 07-context-y-ciclo-de-vida.md | head -20

# --- 2026-09-13T20:04:51 · Read the two unmeasured claims in context
sed -n '600,615p' 14-observabilidad-y-hardening.md; echo "=== F07 175,200 ==="; sed -n '176,200p' 07-context-y-ciclo-de-vida.md; echo "=== F07 1758,1770 ==="; sed -n '1758,1770p' 07-context-y-ciclo-de-vida.md

# --- 2026-09-13T20:05:08 · Soften the two unmeasured performance claims
python3 - <<'PY'
import io
def fix(p,reps):
    s=io.open(p,encoding='utf-8').read()
    for a,b in reps:
        assert a in s,(p,a[:70]); s=s.replace(a,b,1)
    io.open(p,'w',encoding='utf-8').write(s); print("ok",p)

# F07: suavizar ctx.Value a lo estructural
fix('07-context-y-ciclo-de-vida.md',[
("""3. **`Value` es una búsqueda lineal por la cadena de padres.** No es un mapa: cada
   `Value` recorre el árbol hacia arriba. Con veinte valores en un camino caliente,
   se nota.""",
 """3. **`Value` es una búsqueda lineal por la cadena de padres.** No es un mapa:
   cada `WithValue` envuelve el contexto anterior, y cada `Value` recorre esa
   cadena hacia arriba comparando claves hasta encontrar la suya. Es un hecho
   **estructural**, verificable leyendo `context.valueCtx` en la biblioteca
   estándar, y el argumento contra el abuso es ese, no un número: **el curso no lo
   ha medido y por eso no afirma cuánto cuesta.** Lo que sí se sostiene sin medir
   es que el coste crece con la profundidad de la cadena y que un valor en el
   fondo cuesta más que uno en la punta."""),
("""- **Sin ID — Coste de `ctx.Value` por profundidad del árbol.** La búsqueda lineal
  se menciona en §4 como argumento contra el abuso, y **el curso no la ha medido**.
  Según la regla de `prompts/formato-de-benchmarks.md`, o se mide o no se afirma.
  **Propuesta: medirla en la Fase 15** (con 1, 5 y 20 valores en la cadena) o
  suavizar la afirmación de §4 a lo que sí es verificable: que es una búsqueda
  lineal por la cadena de padres, que es un hecho estructural, no de rendimiento.""",
 """- **Coste de `ctx.Value` por profundidad del árbol — resuelto sin medir.** La
  búsqueda lineal se mencionaba en §4 con un *"con veinte valores en un camino
  caliente, se nota"* que era una afirmación de rendimiento sin entrada en
  `BENCHMARKS.md`. **Se suavizó a lo estructural**: §4 ahora describe el mecanismo
  —cada `WithValue` envuelve al anterior y `Value` recorre la cadena— y dice
  explícitamente que el curso no ha medido el coste. Es la segunda salida que
  admite `prompts/formato-de-benchmarks.md`, y la correcta aquí: el argumento
  contra meter datos de negocio en el contexto es de diseño, no de nanosegundos, y
  darle un número lo debilitaría.""")])

# F14: suavizar slog y apuntar a B-28
fix('14-observabilidad-y-hardening.md',[
("""- **Rendimiento.** `slog` con `JSONHandler` es más caro que `log.Printf`. Con
  `LogAttrs` y atributos tipados la diferencia es pequeña; con la forma variádica y
  `slog.Any`, no tanto. Se mide en la Fase 15.""",
 """- **Rendimiento.** `slog` con `JSONHandler` hace más trabajo que `log.Printf`:
  serializa a JSON en vez de concatenar, y **`slog.Any` pasa por reflexión mientras
  que los atributos tipados (`slog.String`, `slog.Int`) no**. Esa es la diferencia
  estructural, y es lo único que el curso afirma aquí: **cuánto cuesta no está
  medido en esta fase**. La fila de logging de **B-28** (Fase 15) lo cuantifica
  dentro de la cadena de middleware, y el ejercicio 23 de esa fase lo extiende a
  `slog.Any` y a la forma variádica.""")])
PY

# --- 2026-09-13T20:05:13 · Read the benchmark format doc section 5
grep -n "B-2[0-9]\|^## \|^### " prompts/formato-de-benchmarks.md | tail -40

# --- 2026-09-13T20:05:16 · Read numbering and minimum entries sections
sed -n '100,145p' prompts/formato-de-benchmarks.md; echo "===1. sec ==="; sed -n '15,34p' prompts/formato-de-benchmarks.md

# --- 2026-09-13T20:05:23 · Register the five new benchmarks in the format document
python3 - <<'PY'
import io
p='prompts/formato-de-benchmarks.md'
s=io.open(p,encoding='utf-8').read()
old="| B-24 | **El duelo completo**: Go frente a Spring Boot y `native-image` | 16 |"
new="""| B-24 | **El duelo completo**: Go frente a Spring Boot y `native-image` | 16 |
| B-25 | Amplificación del reintento: retroceso fijo frente a exponencial con jitter | 10 |
| B-26 | MongoDB: `$push` sin límite frente al tamaño del documento | 11 |
| B-27 | El despachador del outbox frente al número de instancias | 13 |
| B-28 | Coste del middleware de observabilidad por petición | 15 |
| B-29 | Fake frente a mock generado: tiempo de suite | 10 |

**Las cinco últimas se añadieron al cerrar el curso**, cuando el repaso de
continuidad encontró afirmaciones apoyadas en mediciones propuestas y nunca
asignadas. Dos propuestas más —el coste de `slog` frente a `log.Printf` y el de
`ctx.Value` por profundidad— **se resolvieron por la otra salida**: suavizar la
afirmación de la fase a lo estructural, que es lo que §3 admite cuando el dato no
cambia ninguna decisión de diseño."""
assert old in s; s=s.replace(old,new,1)
io.open(p,'w',encoding='utf-8').write(s)
print("ok")
PY

# --- 2026-09-13T20:05:40 · Update measurement blocks in phases 10, 04 and 11
python3 - <<'PY'
import io
def fix(p,reps):
    s=io.open(p,encoding='utf-8').read()
    for a,b in reps:
        assert a in s,(p,a[:70]); s=s.replace(a,b,1)
    io.open(p,'w',encoding='utf-8').write(s); print("ok",p)

fix('10-clientes-http-y-apis-externas.md',[
("""Esta fase **no tiene entradas asignadas** en `prompts/formato-de-benchmarks.md` §5, y
produce tres candidatas serias:

- **Sin ID — Amplificación del reintento.** El histograma del 🧨: peticiones por
  segundo tras un fallo, con retroceso fijo frente a exponencial con jitter, y el
  tiempo de recuperación del socio en los dos casos. **Es la medición más
  didáctica de la fase** y hoy no está en el plan. **Propuesta: B-25.**""",
 """Esta fase produce **dos entradas propias, B-25 y B-29**, y alimenta una tercera:

- **B-25 — Amplificación del reintento.** El histograma del 🧨: peticiones por
  segundo tras un fallo, con retroceso fijo frente a exponencial con jitter, y el
  tiempo de recuperación del socio en los dos casos. **Es la medición más
  didáctica de la fase** y sostiene la parte no negociable de la política: el
  jitter. Asignada al cerrar el curso."""),
("""- **Sin ID — Fake frente a mock generado en tiempo de suite.**
  `prompts/formato-de-benchmarks.md` §1 la menciona explícitamente como candidata y **sigue
  sin ID asignado** (lo anotó ya la Fase 04). Con `go.uber.org/mock` introducido
  aquí, este es el momento de medirla o de retirarla del documento de formato.
  **Decidir antes de publicar.**""",
 """- **B-29 — Fake frente a mock generado en tiempo de suite.**
  `prompts/formato-de-benchmarks.md` §1 la nombraba como candidata desde el
  principio y la Fase 04 la dejó anotada. Con `go.uber.org/mock` introducido aquí,
  este es su sitio. Asignada al cerrar el curso. Ojo con su veredicto: **el
  argumento real a favor del fake no es el tiempo**, y la entrada lo dice.""")])

fix('04-testing-dobles-cobertura.md',[
("""- Comparación fake vs. mock generado en **tiempo de suite** — está en el alcance
  de la Fase 10 (`prompts/formato-de-benchmarks.md` §1 la menciona). No tiene ID asignado;
  **proponer B-25 o encajarla como sección de la entrada de la Fase 10.**""",
 """- Comparación fake vs. mock generado en **tiempo de suite** — es **B-29**, y se
  mide en la Fase 10, donde entra `go.uber.org/mock`. Aquí solo se anota la
  intuición que esta fase deja: el fake gana en legibilidad del fallo, no
  necesariamente en tiempo. La entrada existe para comprobar si esa intuición
  aguanta.""")])

fix('11-mongodb-y-modelado-documental.md',[
("""  crecen" de consejo en hecho.** Propuesta: **B-26**.""",
 """  crecen" de consejo en hecho.** Asignada al cerrar el curso: **B-26**.""")])
PY

# --- 2026-09-13T20:05:45 · Read remaining measurement notes
sed -n '1985,2000p' 13-lotes-scheduling-y-asincronia.md; echo "=== F15 1748,1772 ==="; sed -n '1748,1772p' 15-rendimiento-y-profiling.md; echo "=== F16 1228,1240 ==="; sed -n '1228,1240p' 16-go-frente-a-spring-boot.md

# --- 2026-09-13T20:06:07 · Update measurement blocks in phases 13, 15 and 16
python3 - <<'PY'
import io
def fix(p,reps):
    s=io.open(p,encoding='utf-8').read()
    for a,b in reps:
        assert a in s,(p,a[:70]); s=s.replace(a,b,1)
    io.open(p,'w',encoding='utf-8').write(s); print("ok",p)

fix('13-lotes-scheduling-y-asincronia.md',[
("""- Propuesta nueva, sin ID: **rendimiento del despachador del outbox frente al
  número de instancias**. Sale del ejercicio 14 y del 27 de la Fase 09. Responde la
  pregunta del ⚖️ —cuándo la cola en base de datos deja de bastar— con un número
  propio en vez de con un orden de magnitud citado. **Es la medición que le falta
  al veredicto de esta fase**, y sin ella la afirmación de "unos pocos miles por
  segundo" incumple la regla de medición del curso. **Propuesta: B-27, o encajarla en
  B-24 (Fase 16) como una fila más del duelo.**""",
 """- **B-27 — rendimiento del despachador del outbox frente al número de
  instancias.** Sale del ejercicio 14 y del 27 de la Fase 09. Responde la pregunta
  del ⚖️ —cuándo la cola en base de datos deja de bastar— con un número propio en
  vez de con un orden de magnitud citado, y por eso **es la medición que sostiene
  el veredicto de esta fase**: sin ella, "unos pocos miles por segundo" sería una
  afirmación sin respaldo. Asignada al cerrar el curso, como entrada propia y no
  como fila de B-24: el duelo compara con Spring, y esto compara la cola consigo
  misma al escalar, que es otra pregunta.""")])

fix('15-rendimiento-y-profiling.md',[
("""- **Coste del middleware de observabilidad por petición** — propuesto **sin ID por
  la Fase 05, la Fase 10 y la Fase 14**. Tres fases pidiéndolo. **Esta es la fase
  donde el banco existe y es barato de medir.** No se ha incluido como entrada.
  **Decisión necesaria: asignarle ID (¿B-28?) y medirlo aquí, o retirarlo de las
  tres fases.** Es la anotación más repetida del curso sin resolver.
- **Coste de `slog` frente a `log.Printf`** — propuesto por la **Fase 14** porque
  allí se afirma sin medir. **Recogido aquí como ejercicio 23**, que además avisa
  al estudiante de que puede estar escribiendo una entrada nueva. Aceptable, pero
  **la afirmación de la Fase 14 sigue sin respaldo hasta que alguien haga el
  ejercicio**, lo que técnicamente incumple la regla de medición del curso. **Recomiendo
  suavizar la frase de la Fase 14 a lo estructural.**
- **Coste de `ctx.Value` por profundidad** — propuesto por la **Fase 07**, con dos
  salidas: medirlo aquí o suavizar la afirmación. **No se ha medido.** Misma
  decisión pendiente.""",
 """- **B-28 — coste del middleware de observabilidad por petición.** Pedido **por la
  Fase 05, la Fase 10 y la Fase 14**: tres fases, y era la anotación más repetida
  del curso sin resolver. Se mide aquí porque es la fase donde el banco ya existe
  y el experimento es barato. Asignada al cerrar el curso. **La cadena vacía es la
  línea base**, y sin ella las otras cinco filas no significan nada.
- **Coste de `slog` frente a `log.Printf`** — la Fase 14 lo afirmaba sin medir.
  **Resuelto por las dos vías a la vez:** la afirmación de la Fase 14 §6.2 se
  suavizó a lo estructural (JSON frente a concatenación, reflexión de `slog.Any`
  frente a atributos tipados), y la fila de logging de **B-28** da el número
  dentro de la cadena. **El ejercicio 23 sigue siendo el sitio donde el estudiante
  extiende la entrada** a `slog.Any` y a la forma variádica.
- **Coste de `ctx.Value` por profundidad** — propuesto por la **Fase 07**.
  **Resuelto suavizando la afirmación**, no midiéndola: §4 de la Fase 07 ahora
  describe el mecanismo —cada `WithValue` envuelve al anterior— y dice que el
  curso no ha medido el coste. Es deliberado: el argumento contra meter datos de
  negocio en el contexto es de diseño, y un número lo debilitaría.""")])

fix('16-go-frente-a-spring-boot.md',[
("""- **El rendimiento del despachador del outbox frente al número de instancias** — la
  **Fase 13** propuso encajarlo aquí como una fila más de B-24 (propuesta B-27).
  **No está incluido.** Sin ese dato, la afirmación del ⚖️ de la Fase 13 sobre
  "unos pocos miles de mensajes por segundo" sigue sin respaldo propio. **Decisión
  necesaria.**""",
 """- **El rendimiento del despachador del outbox frente al número de instancias** —
  la **Fase 13** propuso encajarlo aquí como una fila más de B-24. **Resuelto como
  entrada propia, B-27, en la Fase 13**, y no como fila del duelo: B-24 compara Go
  con Spring, y B-27 compara la cola en base de datos consigo misma al escalar.
  Mezclarlas habría contaminado las dos. Cadena cerrada.""")])
PY

# --- 2026-09-13T20:06:19 · Read goleak promise and phase 08 adoption section
grep -n "goleak" 07-context-y-ciclo-de-vida.md 06-concurrencia.md | head; echo "=== F08 6.5 ==="; sed -n '1013,1056p' 08-migracion-a-go-moderno.md

# --- 2026-09-13T20:06:36 · Introduce goleak in phase 08
python3 - <<'PY'
import io
p='08-migracion-a-go-moderno.md'
s=io.open(p,encoding='utf-8').read()
old="""- **`for range` sobre enteros** en los arranques de workers y en los bucles de
  repetición.
"""
new="""- **`for range` sobre enteros** en los arranques de workers y en los bucles de
  repetición.
- **`go.uber.org/goleak`.** No es una novedad del lenguaje sino una librería, y
  entra aquí porque la Fase 07 lo dejó escrito: el detector de fugas de §6.4 de
  aquella fase está hecho a mano a propósito, y **ahora se sustituye para ver la
  diferencia.** Ver abajo.
"""
assert old in s; s=s.replace(old,new,1)

old2="""### 6.6 El entregable: `docs/rechazos.md`"""
new2="""**Y una librería, no una novedad del lenguaje: `goleak`.**

La Fase 07 §6.4 escribió un detector de fugas a mano —cuenta goroutines antes y
después del test— y dijo explícitamente que esta fase lo sustituiría. Se cumple:

```go
// services/opsreport/internal/jobs/main_test.go
package jobs

import (
	"testing"

	"go.uber.org/goleak"
)

// TestMain envuelve TODOS los tests del paquete. Es la forma correcta de usarlo:
// una fuga se detecta al final de la suite, no test a test, porque una goroutine
// puede tardar en morir y test a test genera falsos positivos.
func TestMain(m *testing.M) {
	goleak.VerifyTestMain(m,
		// El pool de conexiones de database/sql mantiene goroutines vivas
		// legítimamente mientras el proceso viva. Sin esta exclusión, goleak
		// grita en cada paquete que toca la base de datos.
		goleak.IgnoreTopFunction("database/sql.(*DB).connectionOpener"),
	)
}
```

> 🪞 **Lo que el contador a mano no podía hacer.** El detector de la Fase 07
> contaba goroutines: sabía **cuántas** sobraban, no **cuáles**. `goleak` inspecciona
> las pilas, así que te dice la función en la que cada goroutine fugada está
> parada —que es el 90% del trabajo de arreglarla— y sabe distinguir las legítimas
> del runtime y de las librerías. Ese es el salto, y solo se aprecia habiendo
> escrito antes el contador.

> ⚠️ **La lista de `Ignore...` es deuda, no configuración.** Cada exclusión que
> añades es una fuga que decides no mirar. Escribe al lado **por qué** es legítima,
> como arriba. Una lista de ocho exclusiones sin comentarios significa que el
> paquete tiene fugas y nadie lo sabe.

### 6.6 El entregable: `docs/rechazos.md`"""
assert old2 in s; s=s.replace(old2,new2,1)

# cerrar el pendiente
old3="""- **`goleak`** — la Fase 07 dejó escrito que esta fase lo introduciría sustituyendo"""
i=s.index(old3); j=s.index('\n- ',i+10)
print(repr(s[i:j]))
PY

# --- 2026-09-13T20:06:44 · Close the goleak pending note in phase 08
python3 - <<'PY'
import io
p='08-migracion-a-go-moderno.md'
s=io.open(p,encoding='utf-8').read()
old="""- **`goleak`** — la Fase 07 dejó escrito que esta fase lo introduciría sustituyendo
  la implementación a mano. **NO está en §6, y es un cabo suelto.** Recomendación:
  añadirlo al salto 1.17–1.18 junto a `golang.org/x/sync` (mismo argumento: es
  semi-oficial, de Uber, estable) **o** mover la promesa a la Fase 14, junto a la
  observabilidad. **Decidir antes de publicar.**"""
new="""- **`goleak`** — la Fase 07 dejó escrito que esta fase lo introduciría sustituyendo
  la implementación a mano, y **se cumple en §6.5**, con `VerifyTestMain` y la
  advertencia de que cada `Ignore...` es deuda. El valor didáctico depende de que
  el estudiante haya escrito antes el contador a mano: si se salta la Fase 07,
  `goleak` parece magia en vez de una mejora medible sobre algo propio. Cadena
  cerrada."""
assert old in s; s=s.replace(old,new,1)
io.open(p,'w',encoding='utf-8').write(s); print("ok")
PY
grep -c "goleak" 08-migracion-a-go-moderno.md

# --- 2026-09-13T20:07:02 · Actually write the goleak section into phase 08
python3 - <<'PY'
import io
p='08-migracion-a-go-moderno.md'
s=io.open(p,encoding='utf-8').read()
old="""- **`for range` sobre enteros** en los arranques de workers y en los bucles de
  repetición.
"""
new="""- **`for range` sobre enteros** en los arranques de workers y en los bucles de
  repetición.
- **`go.uber.org/goleak`.** No es una novedad del lenguaje sino una librería, y
  entra aquí porque la Fase 07 lo dejó escrito: el detector de fugas de su §6.4
  está hecho a mano a propósito, y **ahora se sustituye para ver la diferencia.**
  Ver abajo.
"""
assert old in s, "1"; s=s.replace(old,new,1)

old2="### 6.6 El entregable: `docs/rechazos.md`"
new2="""**Y una librería, no una novedad del lenguaje: `goleak`.**

La Fase 07 §6.4 escribió un detector de fugas a mano —cuenta goroutines antes y
después del test— y dijo explícitamente que esta fase lo sustituiría. Se cumple:

```go
// services/opsreport/internal/jobs/main_test.go
package jobs

import (
	"testing"

	"go.uber.org/goleak"
)

// TestMain envuelve TODOS los tests del paquete. Es la forma correcta de usarlo:
// la fuga se comprueba al final de la suite, no test a test, porque una goroutine
// legítima puede tardar en morir y test a test da falsos positivos.
func TestMain(m *testing.M) {
	goleak.VerifyTestMain(m,
		// El pool de database/sql mantiene goroutines vivas legítimamente
		// mientras viva el proceso. Sin esta exclusión, goleak grita en cada
		// paquete que toca la base de datos.
		goleak.IgnoreTopFunction("database/sql.(*DB).connectionOpener"),
	)
}
```

> 🪞 **Lo que el contador a mano no podía hacer.** El detector de la Fase 07
> contaba goroutines: sabía **cuántas** sobraban, no **cuáles**. `goleak` inspecciona
> las pilas, así que nombra la función donde cada goroutine fugada quedó parada
> —que es el 90% del trabajo de arreglarla— y distingue las legítimas del runtime
> y de las librerías. Ese es el salto, y solo se aprecia habiendo escrito antes el
> contador.

> ⚠️ **La lista de `Ignore...` es deuda, no configuración.** Cada exclusión es una
> fuga que decides no mirar. Escribe al lado **por qué** es legítima, como arriba.
> Ocho exclusiones sin comentarios significan que el paquete tiene fugas y nadie lo
> sabe.

### 6.6 El entregable: `docs/rechazos.md`"""
assert old2 in s, "2"; s=s.replace(old2,new2,1)
io.open(p,'w',encoding='utf-8').write(s); print("ok")
PY
grep -c "goleak" 08-migracion-a-go-moderno.md

# --- 2026-09-13T20:07:07 · Read the testify rule and phase 09 pending
grep -n -B3 -A10 "testify" prompts/guia-de-estilo-y-convenciones.md | head -40; echo "=== F09 2245,2252 ==="; sed -n '2255,2270p' 09-sql-postgres-sqlite.md

# --- 2026-09-13T20:07:09 · Find the integration test section in phase 09
grep -n "testcontainers\|tags=integration\|integration" 09-sql-postgres-sqlite.md | head -20

# --- 2026-09-13T20:07:11 · Read the integration test body in phase 09
sed -n '1590,1660p' 09-sql-postgres-sqlite.md

# --- 2026-09-13T20:07:32 · Introduce testify/require in phase 09 integration tests
python3 - <<'PY'
import io
p='09-sql-postgres-sqlite.md'
s=io.open(p,encoding='utf-8').read()
old="""> **La mentira de la pantalla:** si las dos pasan, todavía puede haber divergencia.
> `memstore` ordena los resultados por iteración de mapa —aleatoria—, y PostgreSQL
> por el `ORDER BY`. Si tu suite de contrato no verifica el orden, ese contrato
> está incompleto. **Añade un caso que lo verifique y comprueba si `memstore`
> falla.** Si falla, acabas de encontrar una divergencia real entre tu doble y tu
> implementación, que es exactamente el error común #8 de la Fase 04.

---"""
new="""> **La mentira de la pantalla:** si las dos pasan, todavía puede haber divergencia.
> `memstore` ordena los resultados por iteración de mapa —aleatoria—, y PostgreSQL
> por el `ORDER BY`. Si tu suite de contrato no verifica el orden, ese contrato
> está incompleto. **Añade un caso que lo verifique y comprueba si `memstore`
> falla.** Si falla, acabas de encontrar una divergencia real entre tu doble y tu
> implementación, que es exactamente el error común #8 de la Fase 04.

#### Y aquí, y solo aquí, entra `testify/require`

Mira el `setupPostgres` de arriba: cinco bloques `if err != nil { t.Fatalf(...) }`
seguidos, todos diciendo lo mismo. En un test unitario ese ruido no existe porque
hay una o dos comprobaciones; en un arranque de integración hay ocho, y ninguna
aporta nada al leerlo.

```go
import "github.com/stretchr/testify/require"

func setupPostgres(t *testing.T) *sql.DB {
	t.Helper()
	ctx := context.Background()

	container, err := postgres.Run(ctx, "postgres:16-alpine" /* ... */)
	require.NoError(t, err, "levantando postgres")
	t.Cleanup(func() { _ = container.Terminate(context.Background()) })

	dsn, err := container.ConnectionString(ctx, "sslmode=disable")
	require.NoError(t, err, "obteniendo el dsn")

	db, err := sql.Open("pgx", dsn)
	require.NoError(t, err, "abriendo la conexión")
	t.Cleanup(func() { db.Close() })

	require.NoError(t, goose.Up(db, "../../migrations"), "aplicando migraciones")
	return db
}
```

> 🧭 **La regla del curso, y es estrecha a propósito.** `testify/require` **solo en
> tests de integración**, y solo para el andamiaje: levantar el contenedor, aplicar
> migraciones, abrir conexiones. **Las aserciones sobre el comportamiento siguen
> siendo `if got != want { t.Errorf(...) }`**, porque ahí el `want` explícito es lo
> que hace el test legible, y porque `require` aborta: una comprobación de
> comportamiento que aborta te oculta las tres que venían detrás.
>
> `require`, no `assert`: si el contenedor no levantó, seguir ejecutando solo
> produce una cascada de fallos que no dicen nada.
>
> Y **`testify/mock` y `testify/suite` no entran en el curso**. El primero compite
> con `go.uber.org/mock` (Fase 10) sin ninguna ventaja; el segundo reintroduce el
> `setUp`/`tearDown` de JUnit que Go ya resolvió con `t.Cleanup`, y volver a él es
> justo el reflejo que la Fase 04 desmonta.

🪞 **Tu instinto de Java dice** que si `require` mejora estas ocho líneas, mejorará
las doscientas del resto de la suite — es lo que hizo AssertJ en tu proyecto. **Y
esta vez se equivoca por un detalle de Go:** `require.Equal` compara con reflexión
y su mensaje de fallo es un volcado de dos structs, mientras que `if got != want`
falla en tiempo de compilación si los tipos no son comparables y te deja escribir
el mensaje que de verdad explica el caso. La stdlib no trae aserciones a propósito;
el sitio donde eso duele es el andamiaje, y por eso el parche llega solo hasta ahí.

---"""
assert old in s; s=s.replace(old,new,1)

old2="""- **`testify/require`** — la guía de estilo §7.4 dice que entra en esta fase,"""
i=s.index(old2); j=s.index('\n- ',i+5)
print(repr(s[i:j]))
io.open(p,'w',encoding='utf-8').write(s)
PY

# --- 2026-09-13T20:07:44 · Close testify and claimed_at pendings in phase 09
python3 - <<'PY'
import io
p='09-sql-postgres-sqlite.md'
s=io.open(p,encoding='utf-8').read()
old="""- **`testify/require`** — la guía de estilo §7.4 dice que entra en esta fase,
  **acotado a los tests de integración**. **No se ha usado en §6.11**, donde los
  tests siguen con `if got != want`. Decidir: o se introduce explícitamente allí
  con su justificación (encadenar diez comprobaciones sin abortar es ruido), o se
  corrige la guía. **Recomiendo introducirlo en §6.11** con un párrafo corto: es
  justo el caso que la guía describe."""
new="""- **`testify/require`** — introducido en §6.11 como manda la guía de estilo §7.4:
  **acotado al andamiaje de los tests de integración**, con la regla explícita de
  que las aserciones de comportamiento siguen en `if got != want`. Lleva su 🪞,
  porque el reflejo de extenderlo a toda la suite es exactamente lo que hace
  AssertJ en Java. Cadena cerrada.

- **La columna `claimed_at`** — el recuperador de entregas huérfanas de §6.4 la
  necesitaba y el esquema de §6.2 no la tenía. **Corregido:** la columna, el índice
  parcial `deliveries_reaper_idx` y el sellado en la consulta de reclamación están
  en §6.2, y §6.4 añade las dos reglas de configuración del recuperador (plazo
  mayor que el de entrega, y no restar el intento al recuperar)."""
assert old in s; s=s.replace(old,new,1)

old2="""- **`rowserrcheck`** — este linter detecta exactamente los dos errores que §6.3"""
i=s.index(old2) if old2 in s else -1
print("rowserr idx", i)
io.open(p,'w',encoding='utf-8').write(s); print("ok")
PY
grep -n -A5 "rowserrcheck" 09-sql-postgres-sqlite.md

# --- 2026-09-13T20:07:53 · Close rowserrcheck pending and fix the linter mention
python3 - <<'PY'
import io
p='09-sql-postgres-sqlite.md'
s=io.open(p,encoding='utf-8').read()
old="""- **`rowserrcheck`** — nombrado en los errores comunes #1 y #2 como linter que los
  detecta. **No está en el `.golangci.yml` de la Fase 00.** Hay que añadirlo aquí o
  retirar la afirmación.
- **La columna `claimed_at`** del recuperador de entregas huérfanas (§6.4) — se
  menciona en el ⚠️ pero **no está en la migración de §6.2**. Corregir la migración
  o marcarla explícitamente como ejercicio 13."""
new="""- **`rowserrcheck`** — nombrado en los errores comunes #1 y #2 como el linter que
  los detecta. **Añadido al `.golangci.yml` de la Fase 00 §6.9**, junto a
  `sqlclosecheck`, que cubre la otra mitad del mismo error. Los dos se quedan
  puestos desde la Fase 00 aunque no vean SQL hasta aquí, igual que `bodyclose` y
  `noctx`. Cadena cerrada."""
assert old in s; s=s.replace(old,new,1)
io.open(p,'w',encoding='utf-8').write(s); print("ok")
PY
sed -i '' 's|`Query`. El linter `rowserrcheck` lo detecta; añádelo al `.golangci.yml`.|`Query`. El linter `sqlclosecheck` lo detecta, y está en el `.golangci.yml` desde\nla Fase 00.|' 09-sql-postgres-sqlite.md
sed -n '1818,1830p' 09-sql-postgres-sqlite.md

# --- 2026-09-13T20:07:58 · Fix second linter mention and read F11 pending
sed -i '' 's|\*Fix mínimo:\* comprobarlo siempre después del bucle. `rowserrcheck` también.|*Fix mínimo:* comprobarlo siempre después del bucle. `rowserrcheck` lo detecta, y\ntambién está puesto desde la Fase 00.|' 09-sql-postgres-sqlite.md
echo "=== F11 pendiente replSet ==="; sed -n '1820,1832p' 11-mongodb-y-modelado-documental.md

# --- 2026-09-13T20:08:06 · Close the compose pending in phase 11
python3 - <<'PY'
import io
p='11-mongodb-y-modelado-documental.md'
s=io.open(p,encoding='utf-8').read()
old="""- **Transacciones multi-documento y el `compose.yaml`** — el ejercicio 20 requiere
  un conjunto de réplicas, y el `compose.yaml` de la Fase 00 levanta una instancia
  suelta. **Hay que actualizar el compose** con `--replSet` y su inicialización, o
  el ejercicio no se puede hacer. **Pendiente concreto y bloqueante.**"""
new="""- **Transacciones multi-documento y el `compose.yaml`** — resuelto en la Fase 00
  §6.8: el compose lleva ahora un segundo servicio, `mongo-rs`, con `--replSet` y
  su inicialización idempotente en el healthcheck, **tras un perfil de Docker
  Compose para que no arranque con `make up`**. La instancia suelta se queda como
  está a propósito, porque el criterio (b) del ejercicio 20 pide demostrar que la
  transacción falla contra ella. Cadena cerrada."""
assert old in s; s=s.replace(old,new,1)
io.open(p,'w',encoding='utf-8').write(s); print("ok")
PY
grep -n -A8 "^20\. Implementa la ingesta con transacción" 11-mongodb-y-modelado-documental.md

# --- 2026-09-13T20:08:14 · Make exercise 20 self-sufficient with the compose profile
python3 - <<'PY'
import io
p='11-mongodb-y-modelado-documental.md'
s=io.open(p,encoding='utf-8').read()
old="""20. Implementa la ingesta con transacción multi-documento contra un conjunto de
    réplicas en contenedor. *Criterio:* (a) funciona; (b) demuestras que falla
    contra una instancia suelta y pegas el error; (c) explicas por qué AtlasSync
    **no** la usa en su camino normal."""
new="""20. Implementa la ingesta con transacción multi-documento contra un conjunto de
    réplicas en contenedor: `docker compose --profile rs up -d mongo-rs`, y la
    cadena `mongodb://localhost:27018/?replicaSet=rs0&directConnection=true`.
    *Criterio:* (a) funciona; (b) demuestras que falla contra la instancia suelta
    del compose —el `mongo` del puerto 27017— y pegas el error literal, que es de
    los menos obvios de Mongo; (c) explicas por qué AtlasSync **no** la usa en su
    camino normal."""
assert old in s; s=s.replace(old,new,1)
io.open(p,'w',encoding='utf-8').write(s); print("ok")
PY

# --- 2026-09-13T20:08:23 · Locate the remaining pending items
echo "=== F06 heap ==="; sed -n '2193,2200p' 06-concurrencia.md
echo "=== F05 negociacion ==="; grep -n "negociación de contenido\|Negociación de contenido" 05-http-rest-stdlib.md 13-lotes-scheduling-y-asincronia.md
echo "=== F03 errWriter ==="; grep -n "errWriter" 03-errores-paquetes-io.md 13-lotes-scheduling-y-asincronia.md
echo "=== F12 metricas ==="; grep -n "Fase 14" 12-cache-con-valkey.md | tail -5
echo "=== F13 ResponseController ==="; grep -n "ResponseController" 13-lotes-scheduling-y-asincronia.md 14-observabilidad-y-hardening.md
echo "=== JSONB ==="; grep -n "JSONB" 09-sql-postgres-sqlite.md 11-mongodb-y-modelado-documental.md | head

# --- 2026-09-13T20:08:32 · Read F13 pendings and F14 timeout section
sed -n '1920,1950p' 13-lotes-scheduling-y-asincronia.md; echo "=== F14 timeouts ==="; grep -n "WriteTimeout\|ReadHeaderTimeout\|los sitios de timeout\|sitios donde" 14-observabilidad-y-hardening.md | head

# --- 2026-09-13T20:08:35 · Read F14 timeouts list and F13 CSV writer
sed -n '1535,1580p' 14-observabilidad-y-hardening.md; echo "=== F13 6.6 csv ==="; grep -n "csv.NewWriter\|encoding/csv\|Write(\[\]string" 13-lotes-scheduling-y-asincronia.md | head

# --- 2026-09-13T20:08:38 · Find the CSV generator in phase 13
grep -n "6.6" 13-lotes-scheduling-y-asincronia.md | head -5; echo "---"; grep -n "csv\|CSV" 13-lotes-scheduling-y-asincronia.md | sed -n '1,25p'

# --- 2026-09-13T20:08:40 · Read the streaming reports section of phase 13
sed -n '1020,1110p' 13-lotes-scheduling-y-asincronia.md

# --- 2026-09-13T20:08:44 · Read the rest of section 6.6
sed -n '1110,1180p' 13-lotes-scheduling-y-asincronia.md

# --- 2026-09-13T20:09:15 · Add errWriter pattern and content-negotiation rationale to phase 13
python3 - <<'PY'
import io
p='13-lotes-scheduling-y-asincronia.md'
s=io.open(p,encoding='utf-8').read()

old="""> Es la adopción de la Fase 08 que no vimos entonces y aquí resuelve un problema
> real.

### 6.7 La comparación con Spring Batch, con el código delante"""

new="""> Es la adopción de la Fase 08 que no vimos entonces y aquí resuelve un problema
> real.

#### Por qué `?format=csv` y no `Accept`

La Fase 05 dejó anotado que la negociación de contenido por `Accept` se volvería
necesaria aquí, con tres formatos de descarga. **Y la decisión es la contraria**,
así que hay que justificarla:

- **El cliente de esta ruta es un navegador o un `curl` en un cron**, no un
  cliente de API. Un enlace `<a href="...?format=csv">` funciona; pedirle a un
  usuario que ponga una cabecera `Accept` no.
- **`Accept` es negociación, no selección.** Un navegador manda
  `Accept: text/html,application/xhtml+xml,*/*;q=0.8`, con lo que la elección
  correcta según el estándar es HTML — que no es lo que el usuario quiso al pulsar
  "descargar CSV". Implementar `q` bien es más código del que parece, y el
  resultado sigue siendo ambiguo.
- **La URL con el formato dentro es cacheable y compartible.** Con `Accept`, dos
  respuestas distintas viven en la misma URL y hace falta `Vary: Accept` para que
  las cachés intermedias no mientan. Es otra cosa que hacer bien y que casi nadie
  hace.

> 🧭 **La regla, que vale más que el caso.** `Accept` para **representaciones** del
> mismo recurso a clientes que negocian de verdad; parámetro en la URL para
> **descargas** que un humano inicia. El ejercicio 🔥 de la Fase 05 sigue siendo
> útil: implementa `Accept` una vez, con su `Vary`, para ver por qué aquí no se usó.

#### El `errWriter` de Pike, en el escritor de CSV

La Fase 03 anotó este patrón para esta fase, y el escritor de CSV es su caso
literal: veinte escrituras seguidas con el mismo manejo de error.

```go
// services/opsreport/internal/report/csv.go

// errWriter acumula el primer error y convierte en no-op todo lo posterior.
// Es el patrón de "Errors are values" de Rob Pike, y existe por una razón muy
// concreta: sin él, escribir una fila de CSV son ocho `if err != nil` que
// devuelven el mismo error, y el ruido esconde la lógica.
type errWriter struct {
	w   *csv.Writer
	err error
}

func (ew *errWriter) write(record []string) {
	if ew.err != nil {
		return // ya falló antes: no se intenta más y no se pisa el error original
	}
	ew.err = ew.w.Write(record)
}

func WriteCSV(ctx context.Context, w io.Writer, rows iter.Seq2[report.Row, error]) (int64, error) {
	ew := &errWriter{w: csv.NewWriter(w)}
	ew.write([]string{"id", "tienda", "fecha", "concepto", "importe", "moneda", "estado"})

	var n int64
	for row, err := range rows {
		if err != nil {
			return n, fmt.Errorf("leyendo la fila %d: %w", n, err)
		}
		// Siete campos, ninguna comprobación de error entre ellos. Esa es toda
		// la ganancia del patrón, y es suficiente para justificarlo.
		ew.write([]string{
			row.ID, row.StoreID, row.Date.Format(time.RFC3339),
			row.Concept, row.Amount.String(), row.Currency, string(row.Status),
		})
		n++

		// El error se comprueba una vez por fila, no una vez por campo. Salir
		// temprano importa: si el cliente cortó la conexión, seguir leyendo
		// medio millón de filas de PostgreSQL es trabajo tirado.
		if ew.err != nil {
			return n, fmt.Errorf("escribiendo la fila %d: %w", n, ew.err)
		}
	}

	ew.w.Flush()                        // el Flush de la Fase 03, una vez más
	if err := ew.w.Error(); err != nil {
		return n, fmt.Errorf("vaciando el csv: %w", err)
	}
	return n, nil
}
```

> 🪞 **Tu instinto de Java dice** que esto es un `try/catch` envolviendo el bucle y
> ya está. **Y esta vez tiene razón a medias:** el `try` hace lo mismo con menos
> código. Lo que gana el `errWriter` es que **el error sigue siendo un valor**: se
> puede inspeccionar, envolver con `%w`, guardar en el struct, o decidir seguir
> escribiendo el resto y reportar al final. Un `catch` te saca del bucle y esa
> decisión ya no es tuya.
>
> ⚠️ **Y la trampa del patrón:** si `write` se llama cien veces sin comprobar
> `ew.err` ni una, el trabajo se hace igual —cien llamadas que no hacen nada— y el
> error llega cien iteraciones tarde. Por eso arriba se comprueba **una vez por
> fila**. El patrón elimina comprobaciones; no elimina pensar dónde va la que queda.

### 6.7 La comparación con Spring Batch, con el código delante"""
assert old in s; s=s.replace(old,new,1)
io.open(p,'w',encoding='utf-8').write(s); print("ok")
PY

# --- 2026-09-13T20:09:38 · Close errWriter, content negotiation and container/heap pendings
python3 - <<'PY'
import io
def fix(p,reps):
    s=io.open(p,encoding='utf-8').read()
    for a,b in reps:
        assert a in s,(p,a[:70]); s=s.replace(a,b,1)
    io.open(p,'w',encoding='utf-8').write(s); print("ok",p)

fix('13-lotes-scheduling-y-asincronia.md',[
("""- **El patrón `errWriter` de Rob Pike** — la **Fase 03** lo anotó como pendiente
  para esta fase, en el generador de CSV. **No se ha usado en §6.6.** Decidir: o se
  aplica en el escritor de CSV —que es exactamente el caso: veinte escrituras
  seguidas con el mismo manejo de error— o se retira el pendiente de la Fase 03.
  **Recomiendo aplicarlo**, es literal el caso de uso del artículo.""",
 """- **El patrón `errWriter` de Rob Pike** — aplicado en §6.6, en el escritor de CSV,
  que es su caso literal. Lleva su 🪞 (el `try/catch` de Java hace lo mismo con
  menos código; lo que gana el patrón es que el error sigue siendo un valor) y su
  ⚠️ sobre la trampa real: si nadie comprueba el acumulador, el error llega cien
  iteraciones tarde. Cadena cerrada con la Fase 03."""),

("""- **Negociación de contenido (`Accept`)** — la **Fase 05** anotó que aquí se
  volvería necesaria con los tres formatos de descarga. **En §6.6 el formato va por
  query param (`?format=csv`), no por `Accept`.** Es una decisión legítima —y más
  práctica para una descarga desde el navegador— pero **contradice lo anotado en la
  Fase 05**. Decidir y dejarlo coherente en las dos.""",
 """- **Negociación de contenido (`Accept`)** — la **Fase 05** anotó que aquí se
  volvería necesaria, y §6.6 elige lo contrario: query param. **Resuelto
  documentando la decisión** en un bloque propio de §6.6, con los tres argumentos
  (el cliente es un navegador, `Accept` negocia en vez de seleccionar, y la URL con
  formato es cacheable sin `Vary`) y con la regla general que queda: `Accept` para
  representaciones, parámetro para descargas. El 🔥 de la Fase 05 sigue en pie y
  ahora tiene sentido: implementarlo una vez para ver por qué aquí no se usa."""),

("""- **`container/heap`** — pendiente sin resolver desde la Fase 01, reabierto en la
  Fase 06. **Esta fase no lo necesita.** Propuesta: cerrarlo definitivamente como
  ejercicio 🔴 de la Fase 06 y quitarlo de los pendientes.""",
 """- **`container/heap`** — cerrado como ejercicio 🔴 de la Fase 06 (el 27), que es
  donde la complicación concurrente lo hace interesante. **Esta fase no lo
  necesita** y no lo reabre.""")])

fix('06-concurrencia.md',[
("""- **`container/heap`** — pendiente desde la Fase 01 (ejercicio 24) y reaparece
  aquí en el ejercicio 27 con la complicación concurrente. **No hay fase que lo
  trate formalmente.** Decidir: o se queda como ejercicio 🔴 aquí, o se le da una
  sección corta en la Fase 13 (donde la cola de lotes lo justificaría).""",
 """- **`container/heap`** — abierto en la Fase 01 (ejercicio 24) y cerrado **aquí,
  como ejercicio 🔴 27**, con la complicación concurrente que es lo que lo hace
  interesante. **Decisión tomada: no tiene sección propia en ninguna fase.** La
  Fase 13 lo consideró para la cola de lotes y no lo necesita; darle una sección
  sería enseñar una estructura de datos, que no es de lo que va el curso. Cadena
  cerrada en las tres fases.""")])

fix('05-http-rest-stdlib.md',[
("""- **Negociación de contenido (JSON/CSV por `Accept`)** — ejercicio 🔥 aquí. Se""",
 """- **Negociación de contenido (JSON/CSV por `Accept`)** — ejercicio 🔥 aquí, y
  **la Fase 13 decidió lo contrario**: sus descargas van por query param, con los
  tres argumentos documentados en su §6.6. El 🔥 se queda porque implementarlo una
  vez —con su `Vary: Accept`— es lo que hace entender por qué allí no se usa. Se""")])
PY

# --- 2026-09-13T20:09:45 · Read F14 and F12 pendings on metrics and ResponseController
sed -n '2250,2270p' 14-observabilidad-y-hardening.md; echo "=== F12 1790,1800 ==="; sed -n '1790,1800p' 12-cache-con-valkey.md; echo "=== F14 metricas cache ==="; grep -n "cache_\|caché" 14-observabilidad-y-hardening.md | grep -i "metric\|contador\|cache_" | head

# --- 2026-09-13T20:09:48 · Read the metrics section of phase 14
grep -n "6.3" 14-observabilidad-y-hardening.md | head -3; echo "---"; awk '/^### 6.3/,/^### 6.4/' 14-observabilidad-y-hardening.md | grep -n "prometheus\|NewCounter\|Name:\|promauto" | head -25

# --- 2026-09-13T20:09:52 · Locate the business metrics block
grep -n "meridian_outbox_oldest_pending_seconds" 14-observabilidad-y-hardening.md; sed -n '880,915p' 14-observabilidad-y-hardening.md

# --- 2026-09-13T20:09:54 · Read the business metrics definitions
sed -n '700,740p' 14-observabilidad-y-hardening.md

# --- 2026-09-13T20:10:19 · Export cache metrics and add ResponseController to phase 14
python3 - <<'PY'
import io
p='14-observabilidad-y-hardening.md'
s=io.open(p,encoding='utf-8').read()

old="""	outboxOldestPending = prometheus.NewGauge(
		prometheus.GaugeOpts{
			Name: "meridian_outbox_oldest_pending_seconds",
			Help: "Antigüedad del evento pendiente más viejo del outbox.",
		},
	)
)
```
"""
new="""	outboxOldestPending = prometheus.NewGauge(
		prometheus.GaugeOpts{
			Name: "meridian_outbox_oldest_pending_seconds",
			Help: "Antigüedad del evento pendiente más viejo del outbox.",
		},
	)

	// LOS CONTADORES DE LA FASE 12, EXPORTADOS TAL CUAL.
	//
	// AtlasSync ya lleva doce fases contando aciertos y fallos de caché en
	// memoria, y la tentación aquí es inventar métricas nuevas "bien nombradas".
	// No: se exportan LAS QUE YA EXISTEN. Dos fuentes para el mismo número es
	// cómo se llega a un panel que contradice a otro panel.
	cacheRequests = prometheus.NewCounterVec(
		prometheus.CounterOpts{
			Name: "meridian_cache_requests_total",
			Help: "Consultas a la caché, por resultado.",
		},
		[]string{"cache", "result"},   // result: hit | miss | error
	)

	// La tasa de acierto NO se exporta como gauge: se calcula en Prometheus con
	// rate() sobre el contador. Un gauge de porcentaje calculado en el proceso
	// miente en cuanto hay más de una réplica, porque promediar porcentajes de
	// réplicas con tráfico distinto no da el porcentaje global.
	cacheOrigin = prometheus.NewHistogramVec(
		prometheus.HistogramOpts{
			Name:    "meridian_cache_origin_duration_seconds",
			Help:    "Latencia de la consulta al origen cuando la caché falla.",
			Buckets: prometheus.DefBuckets,
		},
		[]string{"cache"},
	)
)
```

> ⚠️ **La caché es la métrica que más se inventa dos veces.** La Fase 12 dejó los
> contadores escritos y dijo explícitamente que esta fase los exportara. Si aquí
> defines unos nuevos, acabas con `cache_hits` en el código de AtlasSync y
> `meridian_cache_requests_total{result="hit"}` en el panel, midiendo lo mismo
> desde sitios distintos y divergiendo en cuanto alguien toque uno. **Exporta los
> que existen; si no te gusta cómo se llaman, renómbralos en la Fase 12.**
"""
assert old in s; s=s.replace(old,new,1)

# ResponseController como sexto sitio de timeouts
old2="""//  5. El plazo de apagado, menor que el periodo de gracia
//
// La configuración de §6.6 valida que sean coherentes entre sí, que es lo que
// casi nunca se comprueba."""
new2="""//  5. El plazo de apagado, menor que el periodo de gracia
//  6. Y el sexto, que casi nadie enumera: el plazo POR CONEXIÓN, con
//     http.ResponseController.SetWriteDeadline. Es el de la Fase 13 §6.6, para
//     la descarga de reportes que dura más que el WriteTimeout global. Existe
//     justamente para no tener que subir el global y exponer a todos los
//     endpoints a un cliente lento.
//
// La configuración de §6.6 valida que sean coherentes entre sí, que es lo que
// casi nunca se comprueba. Y el sexto no se valida ahí: es local a un handler,
// y por eso se revisa leyendo el código, no la configuración."""
assert old2 in s; s=s.replace(old2,new2,1)

# cerrar los dos pendientes
old3="""- **Métricas de caché de la Fase 12** — la Fase 12 pidió que esta fase exportara
  **sus** contadores y no inventara otros. **No se ha hecho explícitamente en §6.3**,
  que solo muestra las de lote y outbox. **Añadir las de caché o anotarlo como
  ejercicio.**
- **`http.ResponseController`** — usado en la Fase 13 §6.6 y **no mencionado aquí**
  entre los cinco sitios de timeouts de §6.10. Es el sexto sitio y merece estar."""
new3="""- **Métricas de caché de la Fase 12** — resuelto en §6.3: `meridian_cache_requests_total`
  y `meridian_cache_origin_duration_seconds` se exportan **desde los contadores que
  la Fase 12 ya escribió**, con un ⚠️ sobre por qué no se inventan nuevos y con la
  nota de que la tasa de acierto se calcula en Prometheus y no como gauge en el
  proceso. Cadena cerrada con la Fase 12.
- **`http.ResponseController`** — añadido a §6.10 como **el sexto sitio de
  timeouts**, con el matiz que lo hace distinto de los otros cinco: es local a un
  handler y por eso la validación de configuración de §6.6 no lo cubre. Cadena
  cerrada con la Fase 13."""
assert old3 in s; s=s.replace(old3,new3,1)
io.open(p,'w',encoding='utf-8').write(s); print("ok")
PY

# --- 2026-09-13T20:10:27 · Close cache metrics chain and locate httptrace
python3 - <<'PY'
import io
p='12-cache-con-valkey.md'
s=io.open(p,encoding='utf-8').read()
old="""- **Métricas de caché a Prometheus** — los contadores existen aquí y se exportan en
  la **Fase 14**. Verificar que allí se usan estos y no se inventan otros."""
new="""- **Métricas de caché a Prometheus** — los contadores existen aquí y la **Fase 14
  §6.3 los exporta tal cual**, con un ⚠️ explícito sobre no inventar nombres nuevos
  y con la decisión de calcular la tasa de acierto en Prometheus en vez de
  exportarla como gauge (un porcentaje por réplica no promedia). Cadena verificada
  en las dos direcciones."""
assert old in s; s=s.replace(old,new,1)
io.open(p,'w',encoding='utf-8').write(s); print("ok")
PY
echo "=== httptrace F10 ==="; grep -n -B2 -A4 "httptrace" 10-clientes-http-y-apis-externas.md | head -25

# --- 2026-09-13T20:10:34 · Read the CLI section structure of phase 15
awk '/^## 🛠️ 5\. CLI de la fase/,/^## 💻 6\./' 15-rendimiento-y-profiling.md | grep -n "^### \|^\*\*" | head -20

# --- 2026-09-13T20:10:38 · Read end of the CLI section in phase 15
grep -n "^## 🛠️ 5\|^## 💻 6" 15-rendimiento-y-profiling.md; sed -n '/^## 🛠️ 5/,/^## 💻 6/p' 15-rendimiento-y-profiling.md | tail -40

# --- 2026-09-13T20:10:56 · Add httptrace to phase 15 CLI section
python3 - <<'PY'
import io
p='15-rendimiento-y-profiling.md'
s=io.open(p,encoding='utf-8').read()
old="""# Y el comando que evita la mitad de las mediciones malas: comprobar que la
# máquina está quieta antes de medir.
uptime                              # la carga media debería estar cerca de 0
pmset -g thermlevel 2>/dev/null     # macOS: nivel térmico
```
"""
new="""# CLIENTE HTTP: lo que pprof tampoco ve, porque el tiempo no se gasta en tu CPU.
# httptrace instrumenta el ciclo de vida de UNA petición: DNS, conexión, TLS,
# si reutilizó una conexión del pool, y cuánto tardó el primer byte.
go run ./labs/client-timeouts -trace -url https://api.frankfurter.app/latest

# Y el comando que evita la mitad de las mediciones malas: comprobar que la
# máquina está quieta antes de medir.
uptime                              # la carga media debería estar cerca de 0
pmset -g thermlevel 2>/dev/null     # macOS: nivel térmico
```

> 💡 **`httptrace` es el perfilador del lado cliente, y aquí es donde toca usarlo
> en serio.** La Fase 10 lo presentó para contar conexiones nuevas; en esta fase
> responde la pregunta que el perfil de CPU no puede responder: **por qué una
> llamada al socio tarda 400 ms cuando el socio dice que responde en 30.** La
> respuesta casi siempre está en `GotConn.Reused == false` —el pool no reutiliza y
> cada petición paga DNS más TLS— y eso no aparece en ningún perfil, porque el
> proceso está esperando, no trabajando.
>
> ```go
> ctx := httptrace.WithClientTrace(ctx, &httptrace.ClientTrace{
>     GotConn: func(i httptrace.GotConnInfo) {
>         log.Printf("reused=%v idle=%v idleFor=%v", i.Reused, i.WasIdle, i.IdleTime)
>     },
>     TLSHandshakeDone: func(cs tls.ConnectionState, err error) {
>         log.Printf("tls listo: %v", err)
>     },
> })
> ```
>
> ⚠️ **No lo dejes puesto en producción.** El `ClientTrace` se llama en el camino
> caliente de cada petición; es una herramienta de diagnóstico, no de
> observabilidad continua. Para lo continuo están las métricas de la Fase 14.
"""
assert old in s; s=s.replace(old,new,1)

old2="""- **`httptrace`** — la **Fase 10** anotó que su uso serio correspondía a esta fase.
  **No aparece.** Es una herramienta de diagnóstico legítima para el perfilado de
  clientes HTTP. **Añadir a §5 o retirar el pendiente de la Fase 10.**"""
new2="""- **`httptrace`** — añadido a §5 como el perfilador del lado cliente, con el caso
  que lo justifica (`GotConn.Reused == false`: el pool no reutiliza y cada petición
  paga DNS más TLS, que es tiempo que ningún perfil de CPU ve porque el proceso
  está esperando) y con el ⚠️ de no dejarlo puesto en producción. Cadena cerrada
  con la Fase 10."""
assert old2 in s; s=s.replace(old2,new2,1)
io.open(p,'w',encoding='utf-8').write(s); print("ok")
PY

# --- 2026-09-13T20:11:01 · Locate section 6.8 in phase 09
grep -n "^### 6.8\|^### 6.9" 09-sql-postgres-sqlite.md; sed -n '1120,1145p' 09-sql-postgres-sqlite.md

# --- 2026-09-13T20:11:03 · Read the end of the ORM debate section
sed -n '1240,1265p' 09-sql-postgres-sqlite.md

# --- 2026-09-13T20:11:18 · Add the JSONB comparison note to phase 09
python3 - <<'PY'
import io
p='09-sql-postgres-sqlite.md'
s=io.open(p,encoding='utf-8').read()
old="""### 6.9 ClearingHouse nace: `storeagent` con SQLite"""
new="""**Y una omisión que conviene declarar aquí, antes de que la Fase 11 la cobre.**

Este debate compara tres formas de hablar con PostgreSQL **asumiendo un modelo
relacional**. Hay una cuarta que no entra: **`JSONB`**. PostgreSQL guarda
documentos con índices GIN, consultas por camino (`payload -> 'address' ->> 'city'`)
y operadores de contención (`@>`), y `pgx` lo soporta de forma nativa sin
envoltorios. Para buena parte de lo que se resuelve con una base documental, **una
columna `JSONB` en una base que ya tienes montada es la respuesta correcta**, y no
tener que operar un segundo motor vale más que casi cualquier ventaja de modelado.

El curso no lo usa —AtlasSync va a MongoDB en la Fase 11— y esa decisión se toma
**allí, con el argumento delante**, no aquí por omisión. El desafío D1 de la Fase
11 pide precisamente modelar el catálogo de países en `JSONB` y comparar. Si al
hacerlo te sale que PostgreSQL bastaba, **ese es el resultado correcto y hay que
escribirlo**: es exactamente el tipo de conclusión que la regla 5 de honestidad del
banco de pruebas obliga a publicar.

> 🧭 **La regla que se lleva de aquí.** Antes de añadir un motor nuevo a la
> plataforma, comprueba si el que ya operas cubre el caso. El coste de un motor no
> es la librería: es la copia de seguridad, el monitoreo, la rotación de guardia,
> el parcheo y la persona que sepa depurarlo a las tres de la mañana.

### 6.9 ClearingHouse nace: `storeagent` con SQLite"""
assert old in s; s=s.replace(old,new,1)
io.open(p,'w',encoding='utf-8').write(s); print("ok")
PY
sed -n '1815,1826p' 11-mongodb-y-modelado-documental.md

# --- 2026-09-13T20:11:28 · Close JSONB pending and find phase 17 sections
python3 - <<'PY'
import io
p='11-mongodb-y-modelado-documental.md'
s=io.open(p,encoding='utf-8').read()
old="""- **`JSONB` de PostgreSQL** — se menciona en el ⚖️ como alternativa que cubre buena
  parte del caso documental. **La Fase 09 no lo trató** y es una omisión que pesa
  aquí: un lector puede preguntarse, con razón, por qué no se evaluó guardar los
  países en una columna `JSONB`. **Recomendación: añadir un párrafo corto a la Fase
  09 (§6.8, el debate del ORM) o un ejercicio aquí que lo compare.** Es la
  comparación honesta que falta."""
new="""- **`JSONB` de PostgreSQL** — resuelto por las dos vías. La **Fase 09 §6.8** cierra
  el debate del ORM declarando la omisión: dice que hay una cuarta forma que no
  entra, la nombra con sus operadores e índices, y remite aquí; y añade la regla
  general de comprobar si el motor que ya operas cubre el caso antes de añadir
  otro, porque el coste de un motor es la guardia, no la librería. Y el **desafío
  D1 de esta fase** pide modelarlo y compararlo, con la instrucción explícita de
  publicar el resultado aunque salga que PostgreSQL bastaba. Cadena cerrada."""
assert old in s; s=s.replace(old,new,1)
io.open(p,'w',encoding='utf-8').write(s); print("ok")
PY
echo "=== F17 6.6 ==="; grep -n "^### 6\." 17-capstone.md

# --- 2026-09-13T20:11:33 · Read phase 17 compose and verdict sections
sed -n '273,300p' 17-capstone.md; echo "...=== 700,720 ==="; sed -n '700,725p' 17-capstone.md

# --- 2026-09-13T20:11:37 · Read end of the integrated flow section
sed -n '400,432p' 17-capstone.md

# --- 2026-09-13T20:11:56 · Add the double retry layer warning to phase 17
python3 - <<'PY'
import io
p='17-capstone.md'
s=io.open(p,encoding='utf-8').read()
old="""### 6.3 La suite de integración de la plataforma"""
new="""> ⚠️ **La trampa que aparece el día que despliegas esto en un clúster: la doble
> capa de reintento.** La Fase 10 la dejó anotada para el cierre, y este es el
> sitio porque es la primera vez que ves la plataforma entera junta.
>
> EventRelay reintenta en la aplicación: hasta 8 intentos con retroceso
> exponencial y jitter. Una malla de servicios —Istio, Linkerd— reintenta en la
> capa de red, típicamente 2 o 3 veces por petición, y **lo hace por defecto**. Las
> dos capas no se ven entre sí, así que **se multiplican**: 8 × 3 son 24 peticiones
> al socio por cada entrega, y el socio caído recibe el triple de lo que tú crees
> que le mandas. Si además hay un balanceador con reintentos —y suele haberlo—, son
> tres capas.
>
> Peor: la malla reintenta **antes** de que tu retroceso entre en juego, sin jitter
> y en milisegundos. Es exactamente el pico que B-25 mide y que tu política
> existía para evitar. **Tu retroceso cuidadoso queda debajo de un martillo.**
>
> **La regla: el reintento vive en UNA capa, y se declara cuál.** Para EventRelay
> es la aplicación, porque es la única que sabe qué es idempotente, cuántos
> intentos quedan y cuándo dar una entrega por muerta. Entonces la malla se
> configura con `retries: 0` para esa ruta, **explícitamente y con un comentario
> que diga por qué**, porque el valor por defecto volverá en cuanto alguien
> regenere la configuración.
>
> 📖 En Spring es la misma conversación con otros nombres: `@Retryable` de
> Spring Retry, más los reintentos de Feign, más los de Ribbon o el gateway. El
> problema no es del lenguaje; es de que cada capa cree que es la única.

### 6.3 La suite de integración de la plataforma"""
assert old in s; s=s.replace(old,new,1)

old2="""- **La doble capa de reintento (aplicación + malla)** — pedido por la F10 para la
  F16 o la F17. **No aparece en ninguna.** Encaja en §6.6 de esta fase."""
new2="""- **La doble capa de reintento (aplicación + malla)** — pedido por la F10 para el
  cierre. **Recogido en §6.2**, donde la plataforma completa hace visible el
  problema: los reintentos de la aplicación y los de la malla se multiplican en vez
  de sumarse, y el pico resultante es el que mide B-25. Con la regla que queda —el
  reintento vive en una capa y se declara cuál— y su 📖 hacia Spring Retry + Feign,
  que es la misma conversación. Cadena cerrada."""
assert old2 in s; s=s.replace(old2,new2,1)
io.open(p,'w',encoding='utf-8').write(s); print("ok")
PY

# --- 2026-09-13T20:12:01 · Read the remaining pendings list in phase 17
awk '/^## 📌 Pendientes sin resolver al cierre/,/^## ☕/' 17-capstone.md

# --- 2026-09-13T20:12:23 · Replace the unresolved pendings with the closure inventory
python3 - <<'PY'
import io
p='17-capstone.md'
s=io.open(p,encoding='utf-8').read()
i=s.index("## 📌 Pendientes sin resolver al cierre")
j=s.index("## ☕ Reflejos para")
nuevo = """## 📌 Cabos sueltos: cómo se cerraron

El repaso de continuidad del cierre encontró catorce cadenas abiertas entre fases
—una fase promete algo para otra y la otra no lo recoge—. **Se cerraron todas**, y
el inventario queda aquí porque la forma de cerrar cada una dice más que la lista:

| Cabo | Abierto en | Cerrado |
|---|---|---|
| `compose.yaml` sin conjunto de réplicas | F11 (ej. 20, bloqueante) | F00 §6.8: servicio `mongo-rs` tras un perfil, y la instancia suelta se queda a propósito |
| `rowserrcheck` no configurado | F09 | F00 §6.9, con `sqlclosecheck` de paso |
| Columna `claimed_at` ausente | F09 §6.4 | F09 §6.2: columna, índice parcial del recuperador y sellado en la reclamación |
| Hook de pre-commit (💸 sin pagar) | F00 | F14 §6.6: `.githooks/` + `core.hooksPath` + `--new-from-rev` |
| `goleak` prometido y no entregado | F07 | F08 §6.5, con el 🪞 de qué añade sobre el contador a mano |
| `testify/require` en la guía y no en el código | guía §7.4 | F09 §6.11, acotado al andamiaje y con su 🪞 |
| `errWriter` de Pike | F03 | F13 §6.6, en el escritor de CSV |
| Negociación de contenido: contradicción | F05 ⇄ F13 | F13 §6.6 documenta por qué query param, y la regla general que queda |
| `container/heap` sin dueño | F01 → F06 → F13 | F06 ej. 27, y se declara que no tendrá sección propia |
| Métricas de caché no exportadas | F12 | F14 §6.3, reutilizando los contadores de la F12 |
| `http.ResponseController` | F13 | F14 §6.10, como el sexto sitio de timeouts |
| `httptrace` para uso serio | F10 | F15 §5, como perfilador del lado cliente |
| `JSONB` como alternativa documental | F11 | F09 §6.8 declara la omisión; el D1 de la F11 la mide |
| Doble capa de reintento | F10 | F17 §6.2 |

**Y la comparación del duelo sin Mongo ni Valkey**, que la F11 pidió: está en el
"qué NO demuestra" de **B-24**, con la instrucción de no extrapolar nada sobre
ellos. No se amplió el duelo a propósito — añadir dos motores a una comparación de
lenguajes la habría vuelto ilegible, y el veredicto de la F16 no depende de ellos.

> 🧭 **Lo que el ejercicio enseña, y por qué queda escrito.** De catorce cabos,
> **once eran una fase prometiendo algo que otra tenía que recoger**. Ninguno era
> un error de contenido: eran errores de *cadena*. En un curso de dieciocho fases
> escritas a lo largo de meses, ese es el modo de fallo dominante, y la única
> defensa es un repaso que siga cada promesa hasta su destino. **Es el mismo
> argumento que el curso hace sobre las deudas 💸: declararlas no sirve de nada si
> nadie comprueba que se pagaron.**

"""
s = s[:i] + nuevo + s[j:]
io.open(p,'w',encoding='utf-8').write(s); print("ok")
PY

# --- 2026-09-13T20:12:46 · Update the closing status block of phase 17
python3 - <<'PY'
import io
p='17-capstone.md'
s=io.open(p,encoding='utf-8').read()

old="""| **Hook de pre-commit** | **F00** | **—** | ⚠️ **sin pagar** |

> ⚠️ **Una deuda sin pagar de diecisiete.** El hook de pre-commit lo anotó la Fase
> 00 para la Fase 14 y quedó implícito en `make ci`. **Decidir antes de publicar:**
> añadirlo a la Fase 14 §6.6 (son diez líneas) o retirar el pendiente de la Fase 00.
> La guía de estilo §8.1 dice que un 💸 sin destino es un error de escritura, y esto
> lo es."""
new="""| Hook de pre-commit | F00 | F14 | ✅ |

> ✅ **Diecisiete de diecisiete.** La del hook de pre-commit fue la última y estuvo
> a punto de quedarse implícita en `make ci`; se implementó explícitamente porque
> la guía de estilo §8.1 dice que un 💸 sin destino es un error de escritura, y
> quedarse a una de diecisiete habría sido justo ese error."""
assert old in s; s=s.replace(old,new,1)

old2="""### Mediciones — cobertura del plan

Las 24 entradas de `prompts/formato-de-benchmarks.md` §5 están asignadas a su fase. **Y hay
cinco propuestas sin ID que se repiten a lo largo del curso y no se resolvieron:**

| Propuesta | Pedida por | Estado |
|---|---|---|
| Coste del middleware por petición | F05, F10, **F14** | ⚠️ **tres fases** |
| `slog` frente a `log.Printf` | F14, ejercicio en F15 | ⚠️ afirmación sin medir |
| `ctx.Value` por profundidad | F07 | ⚠️ afirmación sin medir |
| Amplificación del reintento (histograma) | F10 | ⚠️ **la más didáctica sin ID** |
| Rendimiento del outbox por instancias | F13 | ⚠️ **sostiene el ⚖️ de la F13** |
| `$push` frente al tamaño del documento | F11 | ⚠️ propuesta B-26 |
| Fake frente a mock en tiempo de suite | F04, F10, formato §1 | ⚠️ **en el documento de formato** |

> ⚠️ **Recomendación de cierre.** Son siete mediciones propuestas y no asignadas, y
> **tres de ellas respaldan afirmaciones que el curso hace sin medir** — lo que
> incumple la regla de medición del curso. **Hay dos salidas honestas:**
> asignarles ID (B-25 a B-31) y ampliar `prompts/formato-de-benchmarks.md` §5, o **suavizar
> las tres afirmaciones** a lo que sí es verificable estructuralmente. Recomiendo lo
> primero para las cuatro didácticas (middleware, amplificación, outbox, `$push`) y
> lo segundo para `slog` y `ctx.Value`."""
new2="""### Mediciones — cobertura del plan

**Las 29 entradas de `prompts/formato-de-benchmarks.md` §5 están asignadas a su
fase.** Empezaron siendo 24; siete propuestas quedaron sueltas durante la escritura
y el repaso de cierre las resolvió, cada una por la vía que le correspondía:

| Propuesta | Pedida por | Resolución |
|---|---|---|
| Amplificación del reintento (histograma) | F10 | ✅ **B-25** — la más didáctica de la F10 |
| `$push` frente al tamaño del documento | F11 | ✅ **B-26** |
| Rendimiento del outbox por instancias | F13 | ✅ **B-27** — sostiene el ⚖️ de la F13 |
| Coste del middleware por petición | F05, F10, F14 | ✅ **B-28**, medida en la F15 |
| Fake frente a mock en tiempo de suite | F04, F10, formato §1 | ✅ **B-29** |
| `slog` frente a `log.Printf` | F14 | 🔤 afirmación suavizada; la fila de logging de B-28 la cubre |
| `ctx.Value` por profundidad | F07 | 🔤 afirmación suavizada a lo estructural |

> 🧭 **Las dos suavizadas son la parte interesante.** El formato admite dos salidas
> ante una afirmación sin medición —medir o no afirmar— y las dos se usaron. Que
> `ctx.Value` sea una búsqueda lineal por la cadena de padres es **estructural**: se
> verifica leyendo `context.valueCtx`, no midiendo. Ponerle un número habría
> debilitado el argumento, porque el motivo para no meter datos de negocio en el
> contexto es de diseño y sigue en pie aunque la búsqueda fuera gratis.
>
> **Nunca se usó la tercera salida**, que es escribir la frase igual y suavizarla
> con un "suele ser". Esa es la que el curso prohíbe."""
assert old2 in s; s=s.replace(old2,new2,1)
io.open(p,'w',encoding='utf-8').write(s); print("ok")
PY

# --- 2026-09-13T20:12:51 · Read the measurements coverage block
grep -n "Mediciones — cobertura" 17-capstone.md; sed -n '1410,1440p' 17-capstone.md

# --- 2026-09-13T20:13:04 · Replace the measurements coverage block
python3 - <<'PY'
import io
p='17-capstone.md'
s=io.open(p,encoding='utf-8').read()
i=s.index("### Mediciones — cobertura del plan")
j=s.index("### Convención de tags — ampliación ya recogida")
new2="""### Mediciones — cobertura del plan

**Las 29 entradas de `prompts/formato-de-benchmarks.md` §5 están asignadas a su
fase.** Empezaron siendo 24; siete propuestas quedaron sueltas durante la escritura
y el repaso de cierre las resolvió, cada una por la vía que le correspondía:

| Propuesta | Pedida por | Resolución |
|---|---|---|
| Amplificación del reintento (histograma) | F10 | ✅ **B-25** — la más didáctica de la F10 |
| `$push` frente al tamaño del documento | F11 | ✅ **B-26** |
| Rendimiento del outbox por instancias | F13 | ✅ **B-27** — sostiene el ⚖️ de la F13 |
| Coste del middleware por petición | F05, F10, F14 | ✅ **B-28**, medida en la F15 |
| Fake frente a mock en tiempo de suite | F04, F10, formato §1 | ✅ **B-29** |
| `slog` frente a `log.Printf` | F14 | 🔤 afirmación suavizada; la fila de logging de B-28 la cubre |
| `ctx.Value` por profundidad | F07 | 🔤 afirmación suavizada a lo estructural |
| Efecto de `MaxIdleConnsPerHost` | F10 | 📎 sección de B-23 |

> 🧭 **Las dos suavizadas son la parte interesante.** El formato admite dos salidas
> ante una afirmación sin medición —medir o no afirmar— y las dos se usaron. Que
> `ctx.Value` sea una búsqueda lineal por la cadena de padres es **estructural**: se
> verifica leyendo `context.valueCtx`, no midiendo. Ponerle un número habría
> debilitado el argumento, porque el motivo para no meter datos de negocio en el
> contexto es de diseño y sigue en pie aunque la búsqueda fuera gratis.
>
> **Nunca se usó la tercera salida**, que es escribir la frase igual y suavizarla
> con un "suele ser". Esa es la que el curso prohíbe, y por eso conviene que quede
> escrito que no se usó.

"""
s = s[:i] + new2 + s[j:]
io.open(p,'w',encoding='utf-8').write(s); print("ok")
PY
grep -n "sin pagar\|diecisiete" 17-capstone.md | head

# --- 2026-09-13T20:13:07 · Read the debt table tail in phase 17
sed -n '1400,1412p' 17-capstone.md

# --- 2026-09-13T20:13:14 · Mark the pre-commit debt as paid in phase 17
python3 - <<'PY'
import io
p='17-capstone.md'
s=io.open(p,encoding='utf-8').read()
old="""| **Hook de pre-commit** | **F00** | **—** | ⚠️ **sin pagar** |

> ⚠️ **Una deuda sin pagar de diecisiete.** El hook de pre-commit lo anotó la Fase
> 00 para la Fase 14 y quedó implícito en `make ci`. **Decidir antes de publicar:**
> añadirlo a la Fase 14 §6.6 (son diez líneas) o retirar el pendiente de la Fase 00.
> La guía de estilo §8.1 dice que un 💸 sin destino es un error de escritura, y esto
> lo es."""
new="""| Hook de pre-commit | F00 | F14 | ✅ |

> ✅ **Diecisiete de diecisiete.** La del hook de pre-commit fue la última y estuvo
> a punto de quedarse implícita en `make ci`. Se implementó explícitamente porque
> la guía de estilo §8.1 dice que **un 💸 sin destino es un error de escritura**, y
> quedarse a una de diecisiete habría sido justo ese error — el mismo que el curso
> le reprocha a cualquier equipo que declara deuda técnica y no la cobra nunca."""
assert old in s; s=s.replace(old,new,1)
io.open(p,'w',encoding='utf-8').write(s); print("ok")
PY

# --- 2026-09-13T20:13:29 · Update the structure document measurements and debts
python3 - <<'PY'
import io
p='0-ESTRUCTURA-CURSO.md'
s=io.open(p,encoding='utf-8').read()

old="""| ⚠️ **Hook de pre-commit** | **F00** | **sin pagar** |

> ⚠️ **Una deuda de diecisiete sigue sin pagar:** el hook de pre-commit que la
> Fase 00 anotó para la Fase 14 y que quedó implícito en `make ci`. Es la única
> excepción del inventario, y está declarada como decisión abierta en el bloque de
> autoría de la Fase 17."""
new="""| Hook de pre-commit | F00 | F14 |

> ✅ **Diecisiete de diecisiete.** Ninguna deuda 💸 del curso queda sin cobrar. La
> más larga es la del SSRF: doce fases entre su declaración y su pago, y está así a
> propósito — es el tiempo que una deuda de seguridad sobrevive en un proyecto real
> cuando nadie la agenda."""
assert old in s; s=s.replace(old,new,1)

old2="""## 📐 6. Las 24 mediciones

Cada afirmación de rendimiento del curso tiene su entrada en
[`BENCHMARKS.md`](BENCHMARKS.md). Ninguna se escribe sin medir."""
new2="""## 📐 6. Las 29 mediciones

Cada afirmación de rendimiento del curso tiene su entrada en
[`BENCHMARKS.md`](BENCHMARKS.md). Ninguna se escribe sin medir."""
assert old2 in s; s=s.replace(old2,new2,1)

old3="| B-24 | **El duelo completo** | 16 |"
new3="""| B-24 | **El duelo completo** | 16 |
| B-25 | Amplificación del reintento: fijo frente a exponencial con jitter | 10 |
| B-26 | `$push` sin límite frente al tamaño del documento | 11 |
| B-27 | El despachador del outbox frente al número de instancias | 13 |
| B-28 | Coste del middleware de observabilidad por petición | 15 |
| B-29 | Fake frente a mock generado: tiempo de suite | 10 |

Las cinco últimas se asignaron al cerrar el curso, cuando el repaso de continuidad
encontró siete afirmaciones apoyadas en mediciones propuestas y nunca asignadas.
Las **dos restantes** —el coste de `slog` frente a `log.Printf` y el de `ctx.Value`
por profundidad— se resolvieron por la otra salida que el formato admite:
**suavizar la afirmación a lo estructural**, porque ninguna de las dos cambia una
decisión de diseño."""
assert old3 in s; s=s.replace(old3,new3,1)
io.open(p,'w',encoding='utf-8').write(s); print("ok")
PY
grep -n "24 mediciones\|24 entradas\|B-2[4-9]" README.md 0-ESTRUCTURA-CURSO.md | head

# --- 2026-09-13T20:13:42 · Final verification sweep
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/go-for-java-devs
echo "=== verificación final ==="
echo "-- entradas B:"; grep -c "^## B-" BENCHMARKS.md
echo "-- ejercicios y plantilla:"
python3 - <<'PY'
import re,io,glob
tot=0
for f in sorted(glob.glob('[01][0-9]-*.md')):
    if 'conv' in f or 'hist' in f: continue
    s=io.open(f,encoding='utf-8').read(); inf=False; hs=[]
    for l in s.split('\n'):
        if l.lstrip().startswith('```'): inf = not inf; continue
        if not inf and re.match(r'^##\s',l): hs.append(l)
    num=[h for h in hs if re.match(r'^##\s+\S+\s+\d+\.',h)]
    i=s.find('## 🧪'); j=s.find('## 📚',i)
    ex=re.findall(r'^(\d+)\.\s', s[i:j], re.M); tot+=len(ex)
    assert len(num)==10, (f,len(num))
print("plantilla 10 secciones: 18/18 OK · ejercicios:", tot)
PY
echo "-- refs externas:"; grep -rniE "cursos-[a-z]+/|propuestas-cursos|_oskar|courses-ia|CLAUDE\.md|/Users/oskar|regla del repositorio" . || echo "   ninguna ✅"
echo "-- enlaces:"; python3 - <<'PY'
import re,os,io,glob
bad=[]
for f in glob.glob('*.md')+glob.glob('prompts/*.md'):
    s=io.open(f,encoding='utf-8').read()
    for m in re.finditer(r'\]\(([^)\s]+\.md)\)', s):
        t=m.group(1).split('#')[0]
        if not os.path.exists(os.path.normpath(os.path.join(os.path.dirname(f),t))): bad.append(f"{f} -> {t}")
print('  ','\n'.join(sorted(set(bad))) or 'ninguno roto ✅')
PY
echo "-- pendientes abiertos:"; grep -rn "sin pagar\|NO cerrada\|Decidir antes de publicar\|Decisión necesaria\|Pendiente concreto y bloqueante\|sin resolver" *.md | grep -v "que no se usó" || echo "   ninguno ✅"

# --- 2026-09-13T20:13:46 · Read the last open decision in phase 14
sed -n '2330,2345p' 14-observabilidad-y-hardening.md

# --- 2026-09-13T20:13:48 · Read the rest of the measurements block in phase 14
sed -n '2343,2355p' 14-observabilidad-y-hardening.md

# --- 2026-09-13T20:13:58 · Close the last open decision in phase 14
python3 - <<'PY'
import io
p='14-observabilidad-y-hardening.md'
s=io.open(p,encoding='utf-8').read()
old="""- Propuesta, sin ID: **coste de `slog` frente a `log.Printf` por registro**, con
  `LogAttrs` tipado, forma variádica y `slog.Any`. §6.2 afirma que "la diferencia es
  pequeña con `LogAttrs` y no tanto con `slog.Any`" y **eso no está medido**, lo
  que incumple la regla de medición del curso. **O se mide en la Fase 15 o se suaviza la
  afirmación a lo estructural** (que `slog.Any` usa reflexión y los atributos
  tipados no). **Decidir antes de publicar.**
- Propuesta, sin ID: **coste del middleware de observabilidad por petición**
  (cadena vacía frente a request-id + logging + métricas + traza). La Fase 05 ya lo
  propuso sin ID y la Fase 10 lo repitió. **Con el banco de pruebas de la Fase 15
  montado, es barato y responde una preocupación real.** Tercera vez que se
  propone: o se le asigna ID en la Fase 15 o se retira de los tres sitios."""
new="""- **Coste de `slog` frente a `log.Printf` por registro** — §6.2 afirmaba que "la
  diferencia es pequeña con `LogAttrs` y no tanto con `slog.Any`" sin medirlo.
  **Resuelto por las dos vías:** la frase se suavizó a lo estructural (JSON frente
  a concatenación; `slog.Any` pasa por reflexión y los atributos tipados no) y
  **la fila de logging de B-28** da el número dentro de la cadena de middleware. El
  ejercicio 23 de la Fase 15 lo extiende a `slog.Any` y a la forma variádica.
- **Coste del middleware de observabilidad por petición** — pedido aquí, en la Fase
  05 y en la Fase 10: tres veces, y era la anotación más repetida del curso sin
  resolver. **Asignado como B-28 y medido en la Fase 15**, que es donde el banco de
  pruebas ya existe y el experimento es barato. La cadena vacía es la línea base de
  la entrada, sin la cual las otras filas no significan nada."""
assert old in s; s=s.replace(old,new,1)
io.open(p,'w',encoding='utf-8').write(s); print("ok")
PY
grep -rn "Decidir antes de publicar\|Decisión necesaria\|Decisión editorial pendiente\|sin resolver al cierre" *.md prompts/*.md || echo "ninguna decisión abierta ✅"

# --- 2026-09-13T20:14:05 · Final cross-check of benchmark IDs and state
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/go-for-java-devs
echo "=== B en fases vs BENCHMARKS ==="
python3 - <<'PY'
import re,io,glob
ids=set(re.findall(r'^## (B-\d{2})', io.open('BENCHMARKS.md',encoding='utf-8').read(), re.M))
usados=set()
for f in glob.glob('*.md'):
    usados |= set(re.findall(r'B-\d{2}', io.open(f,encoding='utf-8').read()))
print("entradas:", len(ids), sorted(ids)[-6:])
print("citados y no existentes:", sorted(usados-ids) or "ninguno ✅")
PY
echo "=== deudas 💸 ==="; grep -c "💸" *.md | grep -v ":0"
echo "=== wc final ==="; wc -l *.md | tail -1
echo "=== git (solo lectura) ==="; git status --short -- .

