# Comandos Bash de la sesión 5c52573d-4a56-4998-bca3-5d686d0c5368, en orden. Una bitácora, no un script: no se corre entera.

# --- 2026-10-05T14:59:51 · List guidelines and course files
cd /Users/oskar/Developer/Learning/courses-ia-generated; ls -la zz-instrucciones; find zz-instrucciones -type f | head -50; wc -l $(find zz-instrucciones -type f -name '*.md'); echo; ls cursos-algoritmos-lenguajes; ls -la cursos-algoritmos-lenguajes/c-sharp-for-java-devs; cat ~/.claude/projects/-Users-oskar-Developer-Learning-courses-ia-generated/memory/lineamientos-zz-instrucciones-y-zz-code.md ~/.claude/projects/-Users-oskar-Developer-Learning-courses-ia-generated/memory/csharp-java-devs-redaccion.md

# --- 2026-10-05T14:59:55 · Read guidelines README and per-repo doc
cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-instrucciones; cat README.md 04-usar-en-cada-repositorio.md

# --- 2026-10-05T14:59:58 · Read workflow and course types docs
cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-instrucciones; cat 00-workflow-de-un-curso.md 01-tipos-de-curso.md

# --- 2026-10-05T15:00:03 · Read production lessons and grep mermaid rules
cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-instrucciones; cat 03-lecciones-de-produccion.md; grep -rn "D-12\|ermaid\|diagrama" --include=*.md . | grep -v "^./03-"

# --- 2026-10-05T15:00:07 · Find D-12 rule and stage prompts outline
cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-instrucciones; grep -rn "D-12\|ermaid" . | grep -v "^./0[0-4]-\|^./README" ; echo ---; sed -n 1,80p 02-prompts-de-etapa.md; grep -n "^##\|^###" 02-prompts-de-etapa.md

# --- 2026-10-05T15:00:10 · Read E8 prompt, guide D-12 and pending-test notes
cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-instrucciones; sed -n 377,429p 02-prompts-de-etapa.md; sed -n 100,125p plantillas/guia-de-estilo-y-convenciones.md; sed -n 50,120p _desechable-prueba-pendiente.md; sed -n 200,270p _desechable-prueba-pendiente.md

# --- 2026-10-05T15:00:14 · Read per-course procedure and zz-code README
cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-instrucciones; sed -n 120,200p _desechable-prueba-pendiente.md; ls ../zz-code; cat ../zz-code/README.md | head -80

# --- 2026-10-05T15:00:17 · Create zz-code dir and inventory course prompts
cd /Users/oskar/Developer/Learning/courses-ia-generated; python3 zz-code/nuevo.py c-sharp-for-java-devs --proposito "validación contra zz-instrucciones y migración de diagramas a Mermaid"; C=cursos-algoritmos-lenguajes/c-sharp-for-java-devs; ls -la $C/prompts; wc -l $C/prompts/*; find $C/src -maxdepth 3 | head -60

# --- 2026-10-05T15:00:21 · Run base verifier with courses-ia profile
cd /Users/oskar/Developer/Learning/courses-ia-generated; Z=zz-code/c-sharp-for-java-devs-20261005-f6c7; mkdir -p $Z/salidas; C=cursos-algoritmos-lenguajes/c-sharp-for-java-devs; python3 -B zz-instrucciones/herramientas/verificador_base.py $C --perfil=courses-ia > $Z/salidas/antes.log 2>&1; echo rc=$?; wc -l $Z/salidas/antes.log; awk '{print $1}' $Z/salidas/antes.log | sort | uniq -c | sort -rn | head -30; tail -15 $Z/salidas/antes.log; cat $Z/MANIFIESTO.md

# --- 2026-10-05T15:00:24 · Group verifier warnings by type
cd /Users/oskar/Developer/Learning/courses-ia-generated; Z=zz-code/c-sharp-for-java-devs-20261005-f6c7; awk '{print $2}' $Z/salidas/antes.log | sort | uniq -c; grep -v ENCAB $Z/salidas/antes.log | head -80

# --- 2026-10-05T15:00:34 · Run publication profile and outline course guide
cd /Users/oskar/Developer/Learning/courses-ia-generated; Z=zz-code/c-sharp-for-java-devs-20261005-f6c7; C=cursos-algoritmos-lenguajes/c-sharp-for-java-devs; python3 -B zz-instrucciones/herramientas/verificador_base.py $C --perfil=publicacion > $Z/salidas/publicacion.log 2>&1; grep -v "EMOJI\|ENCAB" $Z/salidas/publicacion.log | head -40; grep -n "CALLOUT" $Z/salidas/antes.log; grep -n "^#" $C/prompts/guia-de-estilo-y-convenciones.md

# --- 2026-10-05T15:00:38 · Check publication result and guide sections
cd /Users/oskar/Developer/Learning/courses-ia-generated; Z=zz-code/c-sharp-for-java-devs-20261005-f6c7; C=cursos-algoritmos-lenguajes/c-sharp-for-java-devs; tail -1 $Z/salidas/publicacion.log; grep -v aviso $Z/salidas/publicacion.log | head; sed -n 1,14p $C/prompts/guia-de-estilo-y-convenciones.md; sed -n 382,440p $C/prompts/guia-de-estilo-y-convenciones.md; sed -n 642,697p $C/prompts/guia-de-estilo-y-convenciones.md

# --- 2026-10-05T15:00:49 · Scan course markdown for ASCII diagrams
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/c-sharp-for-java-devs; cat > ../../zz-code/c-sharp-for-java-devs-20261005-f6c7/buscar_diagramas.py <<'EOF'
"""Lista los bloques de código de los .md del curso que parecen diagramas (cajas, flechas, árboles)."""
import re, sys, pathlib
root = pathlib.Path(sys.argv[1])
BOX = re.compile(r"[─│┌┐└┘├┤┬┴┼═║╔╗╚╝▶▼▲◀►→←↓↑⟶]|-->|==>|\+--|--\+|\|\s*$")
for md in sorted(root.rglob("*.md")):
    lines = md.read_text(encoding="utf-8").splitlines()
    i = 0
    while i < len(lines):
        m = re.match(r"^(\s*)(```+|~~~+)(\S*)", lines[i])
        if m:
            fence, lang, start = m.group(2), m.group(3), i
            j = i + 1
            while j < len(lines) and not lines[j].strip().startswith(fence):
                j += 1
            body = lines[start+1:j]
            hits = sum(1 for l in body if BOX.search(l))
            if lang in ("", "text", "txt", "mermaid", "plaintext", "ascii") and hits >= 2:
                print(f"{md.relative_to(root)}:{start+1} lang={lang or '-'} lineas={len(body)} marcas={hits}")
            i = j + 1
        else:
            i += 1
EOF
python3 ../../zz-code/c-sharp-for-java-devs-20261005-f6c7/buscar_diagramas.py . | tee ../../zz-code/c-sharp-for-java-devs-20261005-f6c7/salidas/diagramas.log; grep -rn '```mermaid' . | wc -l

# --- 2026-10-05T15:00:53 · Show first diagram candidates
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/c-sharp-for-java-devs; show(){ sed -n "$(( $2 - 3 )),$(( $2 + $3 + 2 ))p" $1 | cat -n | sed "s/^/[$1] /"; echo ======; }; show 00-convencion-de-git-y-tags.md 14 6; show 00-instalacion-ambiente-visual-studio-y-ecosistema.md 213 9; show 11-migrar-el-runtime.md 313 25; show 11-migrar-el-runtime.md 418 4; show 12-winforms-en-net-10.md 423 7

# --- 2026-10-05T15:00:57 · Show diagram candidates in lessons
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/c-sharp-for-java-devs; bash -c 'show(){ echo "=== $1:$2"; sed -n "$(( $2 - 4 )),$(( $2 + $3 + 2 ))p" "$1"; }; show 00-instalacion-ambiente-visual-studio-y-ecosistema.md 213 9; show 11-migrar-el-runtime.md 313 25; show 11-migrar-el-runtime.md 418 4; show 12-winforms-en-net-10.md 423 7; show 16-identidad-secretos-y-configuracion.md 99 5; show 16-identidad-secretos-y-configuracion.md 448 20; show 23-el-duelo.md 636 12'

# --- 2026-10-05T15:02:12 · Show diagram candidates in lessons (read-only)
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/c-sharp-for-java-devs; for spec in "00-instalacion-ambiente-visual-studio-y-ecosistema.md 213 9" "11-migrar-el-runtime.md 313 25" "11-migrar-el-runtime.md 418 4" "12-winforms-en-net-10.md 423 7" "16-identidad-secretos-y-configuracion.md 99 5" "16-identidad-secretos-y-configuracion.md 448 20" "23-el-duelo.md 636 12"; do set -- $spec; echo "=== $1:$2"; sed -n "$(( $2 - 4 )),$(( $2 + $3 + 2 ))p" "$1"; done

# --- 2026-10-05T15:02:32 · List every text/untagged code block in course
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/c-sharp-for-java-devs; python3 - <<'EOF'
import re, pathlib
for md in sorted(pathlib.Path('.').rglob('*.md')):
    L = md.read_text(encoding='utf-8').splitlines(); i=0
    while i < len(L):
        m = re.match(r'^\s*(```+)(\S*)', L[i])
        if m:
            j=i+1
            while j<len(L) and not L[j].strip().startswith(m.group(1)): j+=1
            if m.group(2) in ('','text','txt'):
                print(f"{md}:{i+1} [{m.group(2) or '-'}] {len(L[i+1:j])}l | {L[i+1][:70] if i+1<j else ''}")
            i=j+1
        else: i+=1
EOF

# --- 2026-10-05T15:02:36 · Inspect remaining borderline blocks
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/c-sharp-for-java-devs; sed -n 486,508p 16-identidad-secretos-y-configuracion.md; echo ====; sed -n 70,90p prompts/propuesta-fases-y-alcance.md; echo ===; sed -n 1262,1285p prompts/propuesta-fases-y-alcance.md

# --- 2026-10-05T15:02:39 · Inspect blocks in propuesta
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/c-sharp-for-java-devs; sed -n 70,90p prompts/propuesta-fases-y-alcance.md; echo '-----'; sed -n 1262,1285p prompts/propuesta-fases-y-alcance.md

# --- 2026-10-05T15:02:55 · Check code language rule and declared exceptions
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/c-sharp-for-java-devs; sed -n 192,233p prompts/guia-de-estilo-y-convenciones.md; echo -----; grep -n -i "excepci\|diverg\|CLAUDE.md\|instrucciones del proyecto" prompts/guia-de-estilo-y-convenciones.md prompts/alcance-del-proyecto.md prompts/README.md | head -40

# --- 2026-10-05T15:03:02 · Check gitignore, README src mention, alcance decisions
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/c-sharp-for-java-devs; cat .gitignore; echo -----; find . -name .gitignore -not -path ./.gitignore; echo -----; grep -n "src/" README.md | head; echo -----; grep -n "^#\|D-[0-9]\|⚖️ D" prompts/alcance-del-proyecto.md | head -50

# --- 2026-10-05T15:03:08 · Read alcance decisions section
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/c-sharp-for-java-devs; sed -n 393,419p prompts/alcance-del-proyecto.md; ls src; grep -n "^## \|^### " prompts/propuesta-fases-y-alcance.md | sed -n 1,200p | grep -i -n "decisi\|registro\|deuda" 

# --- 2026-10-05T15:03:16 · Count exercises and multiline links
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/c-sharp-for-java-devs; python3 - <<'EOF'
import re, pathlib, sys
sys.path.insert(0,'../../zz-instrucciones/herramientas')
import verificador_base as vb
slug = getattr(vb,'slug_github')
files = sorted(pathlib.Path('.').glob('[0-9]*.md'))
for f in files:
    t=f.read_text(encoding='utf-8')
    c={e:len(re.findall(r'^(?:\*\*|#+ |- |\d+\. )?\**'+e, t, re.M)) for e in '🟢🟡🟠🔴'}
    print(f.name[:40].ljust(40), c, sum(c.values()))
# multiline link texts pointing to anchors
for f in sorted(pathlib.Path('.').rglob('*.md')):
    t=f.read_text(encoding='utf-8')
    for m in re.finditer(r'\[([^\]]*\n[^\]]*)\]\(([^)]*)\)', t):
        print('MULTILINEA', f, repr(m.group(2)))
EOF

# --- 2026-10-05T15:03:19 · Inspect exercise section format
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/c-sharp-for-java-devs; grep -n "^## .*jercicio" 01-tipos-valor-y-referencia.md; awk '/^## .*jercicio/{f=1} /^## /&&!/jercicio/{f=0} f' 01-tipos-valor-y-referencia.md | grep -n "^###\|^\*\*[0-9]\|^[0-9]\+\.\|^#### " | head -40

# --- 2026-10-05T15:03:23 · List declared exercise counts per phase
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/c-sharp-for-java-devs; for f in [0-9][0-9]-*.md; do h=$(grep -m1 "^## .*Ejercicios" "$f"); echo "$f | $h"; done | grep -v historia | grep -v convencion

# --- 2026-10-05T15:03:29 · Read exercise rules and check solutions/criteria
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/c-sharp-for-java-devs; sed -n 506,558p prompts/guia-de-estilo-y-convenciones.md; for f in 0[0-9]-*.md 1*.md 2*.md; do awk '/^## 🧪/{f=1;next} /^## /{f=0} f' "$f" > /tmp/x 2>/dev/null; echo "$f details=$(grep -c '<details' /tmp/x) criterio=$(grep -ci 'criterio' /tmp/x)"; done 2>/dev/null | grep -v "historia\|convencion"

# --- 2026-10-05T15:03:36 · Inspect phase header format
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/c-sharp-for-java-devs; sed -n 1,14p 05-async-await-y-cancelacion.md; grep -n "Vigencia\|verificad" zz 2>/dev/null; grep -n -i "vigencia\|fecha de verificación" prompts/plantillas-de-capitulo.md ../../zz-instrucciones/plantillas/plantillas-de-capitulo.md | head

# --- 2026-10-05T15:03:45 · Compare README src description with src tree
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/c-sharp-for-java-devs; sed -n 120,150p README.md; find src -maxdepth 2 -type d | sort

# --- 2026-10-05T15:05:05 · Set TB direction and render diagrams with mmdc
cd /Users/oskar/Developer/Learning/courses-ia-generated; C=cursos-algoritmos-lenguajes/c-sharp-for-java-devs; perl -CSD -Mutf8 -0pi -e 's/(Cada caja es una categoría, y cada flecha va de la API heredada a lo que la reemplaza:\n\n```mermaid\n)flowchart LR/$1flowchart TB/' $C/11-migrar-el-runtime.md; grep -n "flowchart" $C/11-migrar-el-runtime.md; Z=zz-code/c-sharp-for-java-devs-20261005-f6c7/salidas; which mmdc; for f in 11-migrar-el-runtime 24-veredicto-y-defensa; do mmdc -i $C/$f.md -o $Z/$f.md > $Z/$f.mmdc.log 2>&1 && echo "OK $f" || { echo "FALLA $f"; tail -5 $Z/$f.mmdc.log; }; done; ls $Z

# --- 2026-10-05T15:05:13 · Render diagrams to PNG for visual check
cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/c-sharp-for-java-devs-20261005-f6c7/salidas; for f in 11-migrar-el-runtime 24-veredicto-y-defensa; do mmdc -i $f-1.svg -o x.png >/dev/null 2>&1; done; C=../../../cursos-algoritmos-lenguajes/c-sharp-for-java-devs; python3 - <<'EOF'
import re
for f,o in [("11-migrar-el-runtime","f11"),("24-veredicto-y-defensa","f24")]:
    t=open(f"../../../cursos-algoritmos-lenguajes/c-sharp-for-java-devs/{f}.md",encoding="utf-8").read()
    m=re.search(r"```mermaid\n(.*?)```",t,re.S); open(f"{o}.mmd","w",encoding="utf-8").write(m.group(1))
EOF
mmdc -i f11.mmd -o f11.png -w 1400 -b white >/dev/null 2>&1; mmdc -i f24.mmd -o f24.png -w 1400 -b white >/dev/null 2>&1; ls *.png

# --- 2026-10-05T15:05:18 · Debug PNG rendering
cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/c-sharp-for-java-devs-20261005-f6c7/salidas; ls; mmdc -i f11.mmd -o f11.png -w 1400 -b white 2>&1 | tail -5

# --- 2026-10-05T15:05:21 · Render PNGs with scale option
cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/c-sharp-for-java-devs-20261005-f6c7/salidas; mmdc -i f11.mmd -o f11.png -b white -s 1.5 2>&1 | tail -2; mmdc -i f24.mmd -o f24.png -b white -s 1.5 2>&1 | tail -2; ls *.png

# --- 2026-10-05T15:05:41 · Check fase 07 and database contents
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/c-sharp-for-java-devs; find src/fases src/legacy/Sige.Database -type f | head -20

# --- 2026-10-05T15:05:48 · Check guide ending and references to sections
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/c-sharp-for-java-devs; tail -5 prompts/guia-de-estilo-y-convenciones.md; grep -n "guía\|guia-de-estilo" prompts/README.md | head; grep -n "§1[34]" prompts/*.md | head

# --- 2026-10-05T15:06:04 · Append exceptions section 14 to course guide
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/c-sharp-for-java-devs; cat >> prompts/guia-de-estilo-y-convenciones.md <<'EOF'

---

## 14. Excepciones a los lineamientos del repositorio

> 📝 **Sección agregada el 05/10/2026**, en la revisión del curso contra los lineamientos de
> producción del repositorio. Va después del checklist para no renumerar nada (§13 sigue siendo el
> checklist, y así lo citan los demás documentos de `prompts/`). Esta guía se escribió antes de que
> esos lineamientos existieran: lo que aquí se declara ya era la práctica del curso, y desde ahora
> está escrito como decisión.

El `CLAUDE.md` del repositorio da **valores por defecto**, y la guía de un curso los reemplaza cuando
lo declara: la regla general, el valor nuevo y por qué. Lo que esta sección no menciona se hereda tal
cual. **Esto matiza la cascada de §12**: las "instrucciones del proyecto" que encabezan esa lista dan
el valor por defecto, y cada excepción de esta sección manda sobre ellas.

| Regla general del repositorio | Lo que hace este curso | Por qué |
|---|---|---|
| Comentarios dentro del código en inglés | **En español, con tildes**, igual que los mensajes de error y de log (§5) | El comentario es el canal del *porqué*, y el curso piensa en español; los identificadores siguen en inglés |
| 20–30 ejercicios por sección | **20 mínimo, 25 techo** (§9) | El miniproyecto 🧱 consolida la fase; pasar de 25 es relleno |
| Cada ejercicio con solución de referencia o rúbrica | **Sin solución ni rúbrica publicadas.** La evaluación verificable de cada fase es el miniproyecto, con sus criterios de aceptación (`formato-de-miniproyectos.md`); los ejercicios son enunciados accionables (§9) | Decisión del 05/10/2026: 625 soluciones duplicarían el curso, y para este lector el criterio del ejercicio está en su enunciado y en la medición que pide |
| Apéndices `aNN-` | **Ninguno** (alcance §6) | Todo es fase o sección de fase |
| Diagramas a criterio de quien escribe | **Mermaid** para los diagramas; ASCII en `text` solo para árboles de archivos, muestras de datos y salidas (D-12, abajo) | Pedido explícito del autor en la revisión del 05/10/2026 |

### 14.1 D-12 · Diagramas en Mermaid

**Decidido el 05/10/2026 por el autor, en la revisión del curso.** Todo diagrama del curso —flujo,
árbol de decisión, secuencia, categorías con su correspondencia— va en un bloque `mermaid`, con una
frase antes que diga qué mirar en él. Quedan en bloque `text` los árboles de archivos, las muestras de
datos (CSV, ancho fijo), las salidas de terminal y las listas con formato, que no son diagramas.

La revisión convirtió los dos que había: el árbol de decisión de la fase 24 (§5.1) y las tres
categorías de APIs de la fase 11 (§5.2). Las demás piezas en `text` se revisaron y se quedan como
están, por ser de las clases de arriba.

### 14.2 Lo que el curso no tiene, y por qué

- **Plan de producción:** el curso se escribió antes de que los lineamientos lo pidieran y está
  cerrado; no se reconstruye.
- **Diccionario de términos y contrato de nombres** con esos nombres de archivo: hacen ese papel
  §5.2 de esta guía (el diccionario del dominio) y `congelamiento-de-nombres.md` (los nombres
  técnicos congelados). No se renombran, por el bloqueo de contenido.
- **Verificador:** `prompts/verificar-corpus.py`, subclase del perfil `courses-ia` de
  `prompts/verificador_base.py`, con los callouts y marcadores de §7. Se corre desde la raíz del
  curso con `python3 prompts/verificar-corpus.py`.
EOF
tail -3 prompts/guia-de-estilo-y-convenciones.md

# --- 2026-10-05T15:06:10 · Compute total exercises and fix figure
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/c-sharp-for-java-devs; python3 -c "
import re,glob;print(sum(int(re.search(r'^## 🧪 8\. Ejercicios \((\d+)\)',open(f,encoding='utf-8').read(),re.M).group(1)) for f in glob.glob('[0-2][0-9]-*.md') if re.search(r'^## 🧪 8\. Ejercicios',open(f,encoding='utf-8').read(),re.M)))"; perl -CSD -Mutf8 -pi -e 's/625 soluciones duplicarían/619 soluciones duplicarían/' prompts/guia-de-estilo-y-convenciones.md; grep -c "619 soluciones" prompts/guia-de-estilo-y-convenciones.md

# --- 2026-10-05T15:06:26 · Read verifier template and base config attributes
cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-instrucciones/herramientas; cat verificar-corpus.py; grep -n "^class\|^    [A-Z_]\+ *=\|def main\|argv\|--perfil" verificador_base.py | head -80

# --- 2026-10-05T15:06:29 · Inspect base verifier config and profiles
cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-instrucciones/herramientas; sed -n 206,260p verificador_base.py; sed -n 540,620p verificador_base.py; grep -n "EMOJI\|def verificar_capitulo\b\|def verificar_capitulo(\|CAMPOS_ENCABEZADO\|ENCAB\|CALLOUT\|EMOJI_H3\|ERROR_EMOJI" verificador_base.py | head -30

# --- 2026-10-05T15:06:40 · Read chapter template header and hooks
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/c-sharp-for-java-devs; sed -n 1,40p prompts/plantillas-de-capitulo.md; grep -n "^## " 05-async-await-y-cancelacion.md; grep -n "verificar_capitulo_extra\|verificar_corpus_extra\|def correr" ../../zz-instrucciones/herramientas/verificador_base.py

# --- 2026-10-05T15:06:43 · Read chapter verification logic
sed -n 395,425p /Users/oskar/Developer/Learning/courses-ia-generated/zz-instrucciones/herramientas/verificador_base.py; sed -n 340,366p /Users/oskar/Developer/Learning/courses-ia-generated/zz-instrucciones/herramientas/verificador_base.py

# --- 2026-10-05T15:07:02 · Copy base verifier, write course subclass, run it
cd /Users/oskar/Developer/Learning/courses-ia-generated; cp zz-instrucciones/herramientas/verificador_base.py cursos-algoritmos-lenguajes/c-sharp-for-java-devs/prompts/verificador_base.py; cat > cursos-algoritmos-lenguajes/c-sharp-for-java-devs/prompts/verificar-corpus.py <<'EOF'
#!/usr/bin/env python3
"""Verificador del curso C# para desarrolladores Java senior (guía de estilo §14.2).

Hereda las validaciones base de `verificador_base.py` (enlaces, anclas, restos de plantilla,
codificación, callouts, encabezado) con el perfil del repositorio, y agrega las de este curso.

Uso, desde la raíz del curso:
    python3 prompts/verificar-corpus.py

Validaciones propias de este curso, además de las base:
  ERROR EJERCICIOS  el título «## 🧪 8. Ejercicios (N)» no coincide con los ejercicios numerados
  aviso BANDA       una fase con menos de 20 o más de 25 ejercicios (guía §9)
  aviso SECCION     una fase sin alguna de las 10 secciones de la plantilla (guía §8)
  aviso DIAGRAMA    un bloque `text` que parece diagrama y no es árbol de archivos (D-12, guía §14.1)
"""

import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from verificador_base import PerfilCoursesIA, main  # noqa: E402

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

# Las 10 secciones de la plantilla de fase (guía §8), por el texto que sigue al número.
SECCIONES_DE_FASE = ("1. Propósito", "2. Qué queda listo", "3. Qué NO entra", "4. Concepto mínimo",
                     "5. Código mínimo", "6. Medición", "7. Miniproyecto", "8. Ejercicios",
                     "9. Referencias", "10. Cierre")
CAJAS_RE = re.compile(r"[┌┐└┘├┤┬┴┼─│═║╔╗╚╝]")
RAMA_ARBOL_RE = re.compile(r"^\s*[│├└]─")


class VerificadorDelCurso(PerfilCoursesIA):
    # Marcadores y callouts de la guía §7 (7.1, 7.2 y 7.3).
    CALLOUTS = {"💸", "🔥", "⭐", "🧬", "🧱", "📏", "🏷️", "🪦", "🧨", "📌",
                "📝", "📚", "⚠️", "💡", "🧭", "⚖️", "🧠",
                "🪞", "🩻", "⚰️", "📖"}
    # Emoji con moderación en ###: los de las secciones recurrentes y los marcadores no avisan.
    EMOJI_PERMITIDOS_H3 = PerfilCoursesIA.EMOJI_PERMITIDOS_H3 | CALLOUTS
    # El encabezado de fase de la plantilla (guía §8.1).
    CAMPOS_ENCABEZADO = ("Fase ", "Depende de", "Estilo de esta fase", "Proyecto que avanza")
    # 00-historia y 00-convencion llevan número de fase pero no son fases.
    NO_CAPITULO = PerfilCoursesIA.NO_CAPITULO + ("historia", "convencion")

    def verificar_capitulo_extra(self, ruta, lineas, texto, preguntas):
        nombre = self.rel(ruta)
        titulos = [l for _, l in lineas if l.startswith("## ")]
        for seccion in SECCIONES_DE_FASE:
            if not any(seccion in t for t in titulos):
                self.aviso("SECCION", f"{nombre}: falta «{seccion}»")
        self.verificar_ejercicios(nombre, lineas)
        self.verificar_diagramas(nombre, lineas)

    def verificar_ejercicios(self, nombre, lineas):
        declarado, numerados, dentro = None, 0, False
        for _, linea in lineas:
            if linea.startswith("## "):
                m = re.match(r"^## 🧪 8\. Ejercicios \((\d+)\)", linea)
                dentro = bool(m)
                if m:
                    declarado = int(m.group(1))
                continue
            if dentro and re.match(r"^\d+\. ", linea):
                numerados += 1
        if declarado is None:
            return
        if declarado != numerados:
            self.error("EJERCICIOS", f"{nombre}: el título dice {declarado} y hay {numerados} numerados")
        if not 20 <= numerados <= 25:
            self.aviso("BANDA", f"{nombre}: {numerados} ejercicios (banda 20–25, guía §9)")

    def verificar_diagramas(self, nombre, lineas):
        bloque, inicio = None, 0
        for n, linea in lineas:
            if bloque is None and linea.startswith("```text"):
                bloque, inicio = [], n
            elif bloque is not None and linea.startswith("```"):
                cajas = sum(1 for l in bloque if CAJAS_RE.search(l))
                arbol = bloque and bloque[0].rstrip().endswith("/")
                if cajas >= 2 and not arbol and any(RAMA_ARBOL_RE.match(l) or "┌" in l for l in bloque):
                    self.aviso("DIAGRAMA", f"{nombre}:{inicio}: bloque text con forma de diagrama; va en Mermaid (D-12)")
                bloque = None
            elif bloque is not None:
                bloque.append(linea)


if __name__ == "__main__":
    sys.exit(main(VerificadorDelCurso, RAIZ))
EOF
cd cursos-algoritmos-lenguajes/c-sharp-for-java-devs; python3 -B prompts/verificar-corpus.py | tee ../../zz-code/c-sharp-for-java-devs-20261005-f6c7/salidas/despues.log | tail -40

# --- 2026-10-05T15:07:14 · Adjust subclass and rerun verifier
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/c-sharp-for-java-devs; python3 - <<'EOF'
p='prompts/verificar-corpus.py'; t=open(p,encoding='utf-8').read()
t=t.replace('''    EMOJI_PERMITIDOS_H3 = PerfilCoursesIA.EMOJI_PERMITIDOS_H3 | CALLOUTS
''','''    # (el verificador revisa carácter por carácter: van también sin el U+FE0F).
    EMOJI_PERMITIDOS_H3 = PerfilCoursesIA.EMOJI_PERMITIDOS_H3 | CALLOUTS | {c.replace("\\ufe0f", "") for c in CALLOUTS}
''')
t=t.replace('''        for seccion in SECCIONES_DE_FASE:
            if not any(seccion in t for t in titulos):''','''        for seccion in SECCIONES_DE_FASE:
            # La F24 no tiene software nuevo: su sección 5 es «Lo que se escribe en esta fase».
            alternativas = (seccion, "5. Lo que se escribe") if seccion.startswith("5.") else (seccion,)
            if not any(a in t for a in alternativas for t in titulos):''')
open(p,'w',encoding='utf-8').write(t)
EOF
python3 -B prompts/verificar-corpus.py | tee ../../zz-code/c-sharp-for-java-devs-20261005-f6c7/salidas/despues.log | tail -16

# --- 2026-10-05T15:07:23 · Add pending markers, test verifier with seeded errors
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/c-sharp-for-java-devs; perl -CSD -Mutf8 -pi -e 's/("🪞", "🩻", "⚰️", "📖"\})/"🪞", "🩻", "⚰️", "📖",\n                "⏳", "🔜"}  # las dos convenciones de lo pendiente (formato-de-mediciones §2.6 y §2.9)/' prompts/verificar-corpus.py; sed -n 36,42p prompts/verificar-corpus.py; python3 -B prompts/verificar-corpus.py | tail -1
Z=../../zz-code/c-sharp-for-java-devs-20261005-f6c7/salidas/copia-sembrada; mkdir -p $Z; cp -R *.md prompts $Z/ ; cd $Z
perl -CSD -Mutf8 -pi -e 's/^## 🧪 8\. Ejercicios \(25\)/## 🧪 8. Ejercicios (26)/' 01-tipos-valor-y-referencia.md
perl -CSD -Mutf8 -pi -e 's/^## 📏 6\. Medición/## 📏 6. Medida/' 05-async-await-y-cancelacion.md
printf '\n```text\n┌────┐\n│ a  │\n└────┘\n├─ b\n```\n' >> 02-nullable-y-pattern-matching.md
printf '\n> 💲 **x**\n' >> 03-linq-y-evaluacion-diferida.md
python3 -B prompts/verificar-corpus.py | grep -v "EMOJI\|CALLOUT   [1B]" 

# --- 2026-10-05T15:07:29 · Check how lines are passed to hooks
cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-instrucciones/herramientas; grep -n "def lineas_fuera\|def leer\|lineas_sin_codigo\|fuera_de_codigo\|def lineas" verificador_base.py; sed -n "$(grep -n 'def correr' verificador_base.py | cut -d: -f1),+25p" verificador_base.py

# --- 2026-10-05T15:07:38 · Move diagram check to raw text and retest
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/c-sharp-for-java-devs; python3 - <<'EOF'
p='prompts/verificar-corpus.py'; t=open(p,encoding='utf-8').read()
t=t.replace('''        self.verificar_ejercicios(nombre, lineas)
        self.verificar_diagramas(nombre, lineas)
''','''        self.verificar_ejercicios(nombre, lineas)

    def verificar_documento_extra(self, ruta, lineas, texto):
        # `lineas` llega sin los bloques de código: los diagramas se buscan en el texto crudo.
        self.verificar_diagramas(self.rel(ruta), enumerate(texto.splitlines(), 1))
''')
open(p,'w',encoding='utf-8').write(t)
EOF
python3 -B prompts/verificar-corpus.py | tail -1; Z=../../zz-code/c-sharp-for-java-devs-20261005-f6c7/salidas/copia-sembrada; cp prompts/verificar-corpus.py $Z/prompts/; cd $Z; python3 -B prompts/verificar-corpus.py | grep -v "EMOJI\|CALLOUT   [1B]"; cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/c-sharp-for-java-devs; git stash list >/dev/null; python3 - <<'EOF'
# prueba: el verificador marcaría los dos diagramas originales (versión de HEAD)
import subprocess,re
for f in ["11-migrar-el-runtime.md","24-veredicto-y-defensa.md"]:
    t=subprocess.run(["git","show",f"HEAD:./{f}"],capture_output=True,text=True).stdout
    open(f"../../zz-code/c-sharp-for-java-devs-20261005-f6c7/salidas/copia-sembrada/{f}","w",encoding="utf-8").write(t)
EOF
cd ../../zz-code/c-sharp-for-java-devs-20261005-f6c7/salidas/copia-sembrada; python3 -B prompts/verificar-corpus.py | grep DIAGRAMA

# --- 2026-10-05T15:07:46 · Final verification runs and diff summary
cd /Users/oskar/Developer/Learning/courses-ia-generated; C=cursos-algoritmos-lenguajes/c-sharp-for-java-devs; Z=zz-code/c-sharp-for-java-devs-20261005-f6c7/salidas; python3 -B zz-instrucciones/herramientas/verificador_base.py $C --perfil=courses-ia > $Z/despues-courses-ia.log; tail -1 $Z/despues-courses-ia.log; grep -c "^ERROR" $Z/despues-courses-ia.log; python3 -B zz-instrucciones/herramientas/verificador_base.py $C --perfil=publicacion > $Z/despues-publicacion.log; grep "^ERROR" $Z/despues-publicacion.log | grep -v EMOJI; grep -rl "Ã\|â€" $C --include=*.md --include=*.py; git status --short $C; git diff --stat $C

# --- 2026-10-05T15:07:49 · Check encoding and show git status/diff
cd /Users/oskar/Developer/Learning/courses-ia-generated; C=cursos-algoritmos-lenguajes/c-sharp-for-java-devs; grep -rl 'Ã\|â€' $C --include='*.md' --include='*.py'; echo "mojibake: $?"; git status --short $C; git diff --stat $C

# --- 2026-10-05T15:08:10 · Add memory index pointer
cd /Users/oskar/.claude/projects/-Users-oskar-Developer-Learning-courses-ia-generated/memory; echo '- [Revisión de cursos de lenguajes contra zz-instrucciones](revision-cursos-lenguajes-zz-instrucciones.md) — C# hecho el 05/10/2026 (Mermaid, guía §14, verificador); siguen go y python.' >> MEMORY.md; tail -2 MEMORY.md

# --- 2026-10-05T15:13:22 · Inspect and delete the stray temp file
ls -la /tmp/x && head -c 200 /tmp/x; echo; rm /tmp/x; ls /tmp/x 2>&1

# --- 2026-10-05T15:13:25 · Create zz-code dir and inventory go course
cd /Users/oskar/Developer/Learning/courses-ia-generated; python3 zz-code/nuevo.py go-for-java-devs --proposito "validación contra zz-instrucciones y migración de diagramas a Mermaid"; G=cursos-algoritmos-lenguajes/go-for-java-devs; ls -la $G; ls -la $G/prompts; wc -l $G/prompts/* | tail -1; find $G -name .gitignore; git log --oneline -3 -- $G; git status --short $G | head

# --- 2026-10-05T15:13:32 · Run verifiers and diagram scan on go course
cd /Users/oskar/Developer/Learning/courses-ia-generated; G=cursos-algoritmos-lenguajes/go-for-java-devs; Z=zz-code/go-for-java-devs-20261005-ab98; mkdir -p $Z/salidas; cp zz-code/c-sharp-for-java-devs-20261005-f6c7/buscar_diagramas.py $Z/; python3 -B zz-instrucciones/herramientas/verificador_base.py $G --perfil=courses-ia > $Z/salidas/antes.log 2>&1; python3 -B zz-instrucciones/herramientas/verificador_base.py $G --perfil=publicacion > $Z/salidas/publicacion.log 2>&1; tail -1 $Z/salidas/antes.log; awk '{print $1,$2}' $Z/salidas/antes.log | sort | uniq -c; echo; grep "^ERROR" $Z/salidas/antes.log | head -20; echo; grep "^ERROR" $Z/salidas/publicacion.log | grep -v EMOJI | head; echo; grep "CALLOUT" $Z/salidas/antes.log | awk '{print $NF}' | sort | uniq -c; echo; python3 $Z/buscar_diagramas.py $G | tee $Z/salidas/diagramas.log; grep -rn '```mermaid' $G | wc -l

# --- 2026-10-05T15:13:38 · Dump all diagram candidates to a file
cd /Users/oskar/Developer/Learning/courses-ia-generated; G=cursos-algoritmos-lenguajes/go-for-java-devs; Z=zz-code/go-for-java-devs-20261005-ab98; python3 - "$G" "$Z/salidas/diagramas.log" > $Z/salidas/candidatos.txt <<'EOF'
import sys,re
g,log=sys.argv[1],sys.argv[2]
for l in open(log):
    f,n=l.split()[0].rsplit(':',1); n=int(n)
    L=open(f"{g}/{f}",encoding='utf-8').read().splitlines()
    j=n
    while not L[j].startswith('```'): j+=1
    print(f"=== {f}:{n}  (contexto: {L[n-3][:90]!r})")
    print("\n".join(L[n-1:j+1]))
EOF
wc -l $Z/salidas/candidatos.txt

# --- 2026-10-05T15:13:48 · Read go README and guide outline
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/go-for-java-devs; cat README.md; grep -n "^#\|^## " prompts/guia-de-estilo-y-convenciones.md

# --- 2026-10-05T15:13:51 · Read guide code, callouts, exercises, coherence sections
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/go-for-java-devs; sed -n 154,242p prompts/guia-de-estilo-y-convenciones.md; sed -n 337,351p prompts/guia-de-estilo-y-convenciones.md; sed -n 436,500p prompts/guia-de-estilo-y-convenciones.md; sed -n 590,637p prompts/guia-de-estilo-y-convenciones.md; sed -n 706,760p prompts/guia-de-estilo-y-convenciones.md

# --- 2026-10-05T15:14:05 · Check exercise counts, rubrics, Spring Boot version
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/go-for-java-devs; python3 - <<'EOF'
import re,glob
for f in sorted(glob.glob('[0-1][0-9]-*.md')):
    L=open(f,encoding='utf-8').read().splitlines()
    dec=None; num=0; dentro=False; rub=0; rojos=False; nrojos=0; desafios=0; sec=[]
    for l in L:
        if l.startswith('## '):
            sec.append(l)
            m=re.match(r'^## 🧪 8\. Ejercicios \((\d+)\)',l); dentro=bool(m)
            if m: dec=int(m.group(1))
            continue
        if not dentro: continue
        if re.match(r'^\*\*🔴',l) and 'Desaf' not in l: rojos=True
        if re.match(r'^\*\*(🔥|D\d)',l) or l.startswith('### '): rojos=False
        if re.match(r'^\d+\. ',l):
            num+=1
            if rojos: nrojos+=1
        if re.search(r'[Rr]úbrica|<details',l): rub+=1
        if re.match(r'^\*\*D\d',l): desafios+=1
    if dec is not None or 'historia' not in f and 'convencion' not in f:
        print(f"{f[:38]:38} dec={dec} num={num} rojos={nrojos} rubricas/details={rub} desafios={desafios} secciones={len(sec)}")
EOF
grep -n "Spring Boot [0-9]" 16-go-frente-a-spring-boot.md README.md 0-ESTRUCTURA-CURSO.md prompts/alcance-del-proyecto.md | head

# --- 2026-10-05T15:14:12 · Investigate shipped Spring code claim and red rubrics
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/go-for-java-devs; sed -n 15,30p 16-go-frente-a-spring-boot.md; grep -n "entrega hech\|el curso entrega\|repositorio del curso\|src/\|github.com/meridian\|incluido en el curso" *.md | grep -v "^BENCH" | head -20; awk '/^## 🧪 8/{f=1} /^## 📚|^## 🚀/{f=0} f' 05-http-rest-stdlib.md | sed -n '/🔴 Muy/,/Desaf/p' | head -40

# --- 2026-10-05T15:14:17 · Find where the Java twin is supposed to live
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/go-for-java-devs; sed -n 474,490p 00-historia-de-la-empresa-meridian.md; grep -n -i "gemelo\|clearinghouse-java\|twin" 16-go-frente-a-spring-boot.md prompts/proyecto-04-clearinghouse.md prompts/alcance-del-proyecto.md | head -20

# --- 2026-10-05T15:14:24 · Check whether benchmark figures are real or pending
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/go-for-java-devs; sed -n 1,60p BENCHMARKS.md; grep -c "⏳" BENCHMARKS.md; grep -n -i "ilustrativ\|esperad\|sin ejecutar\|no se ejecut\|pendiente de corrida\|referencia, no" BENCHMARKS.md 15-rendimiento-y-profiling.md | head

# --- 2026-10-05T15:14:28 · Check context of numeric outputs in F15
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/go-for-java-devs; sed -n 140,175p 15-rendimiento-y-profiling.md; sed -n 1268,1295p 15-rendimiento-y-profiling.md

# --- 2026-10-05T15:14:34 · Search for execution/output rules in go prompts
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/go-for-java-devs; grep -n -i "ejecut\|ilustrativ\|salida esperada\|salidas\b\|no verificad\|inventad" prompts/alcance-del-proyecto.md prompts/guia-de-estilo-y-convenciones.md prompts/formato-de-benchmarks.md prompts/plantillas-de-capitulo.md | head -20; grep -n "^## \|^### " prompts/alcance-del-proyecto.md | head -40

# --- 2026-10-05T15:14:37 · Read versions, file structure, decisions
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/go-for-java-devs; sed -n 152,224p prompts/alcance-del-proyecto.md; sed -n 263,290p prompts/alcance-del-proyecto.md; sed -n 335,380p prompts/alcance-del-proyecto.md

# --- 2026-10-05T15:14:50 · Check aprendizaje.md role and pinned versions
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/go-for-java-devs; sed -n 1,25p prompts/aprendizaje.md; grep -ln "aprendizaje" *.md prompts/*.md; grep -n -i "go1\.2[0-9]\|go 1\.2[0-9]\|verificad.*20[0-9][0-9]\|septiembre de 2026\|2026" 00-instalacion-ambiente-y-tooling.md | head -15

# --- 2026-10-05T15:14:53 · See how published docs mention aprendizaje
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/go-for-java-devs; grep -n "aprendizaje" 10-clientes-http-y-apis-externas.md 13-lotes-scheduling-y-asincronia.md INSTINTOS.md BENCHMARKS.md 16-go-frente-a-spring-boot.md 17-capstone.md | head

# --- 2026-10-05T15:26:31 · Replace seven text diagrams with Mermaid in go course
cd /Users/oskar/Developer/Learning/courses-ia-generated; cat > zz-code/go-for-java-devs-20261005-ab98/migrar_diagramas.py <<'PYEOF'
"""Reemplaza los siete bloques text de go-for-java-devs por su versión Mermaid (D-12)."""
import pathlib, re, sys
C = pathlib.Path(sys.argv[1])

def bloque(archivo, primera_linea):
    t = (C / archivo).read_text(encoding="utf-8")
    patron = re.compile(r"```text\n" + re.escape(primera_linea) + r"\n.*?\n```\n", re.S)
    hallados = patron.findall(t)
    assert len(hallados) == 1, (archivo, primera_linea, len(hallados))
    return t, hallados[0]

CAMBIOS = [
("17-capstone.md", "┌─────────────┐  sync HTTP   ┌──────────────────┐", '''```mermaid
flowchart TD
    SA["storeagent<br/>(SQLite)"] -- "sync HTTP · F10" --> CH["ClearingHouse<br/>(PostgreSQL)"]
    CH -- "cierre por lotes · F13" --> OR["OpsReport<br/>(PostgreSQL)"]
    OR -- "F13" --> OB["outbox<br/>(misma tx)"]
    OR -- "reporte en streaming · F13" --> RP["CSV/JSON/HTML"]
    OB -- "SKIP LOCKED" --> ER["EventRelay<br/>(PostgreSQL)"]
    ER -- "HMAC, reintentos · F10, F12" --> FC["fakeconsumer"]
    FC -- "tipo de cambio · F11, F12" --> AS["AtlasSync<br/>(Mongo+Valkey)"]
```
'''),
("13-lotes-scheduling-y-asincronia.md", "┌─ TRANSACCIÓN ────────────────────────────────────┐", '''```mermaid
flowchart TD
    subgraph TX["TRANSACCIÓN"]
        direction TB
        S1["1. leer N movimientos desde el último cursor"] --> S2["2. conciliarlos"]
        S2 --> S3["3. escribir los asientos resultantes"]
        S3 --> S4["4. ESCRIBIR EL PUNTO DE CONTROL<br/>(nuevo cursor)"]
    end
    TX --> CM(["COMMIT"])
```
'''),
("13-lotes-scheduling-y-asincronia.md", "commit del trabajo → ☠️ fallo → punto de control NO escrito", '''```mermaid
flowchart TD
    subgraph V1["Primero el trabajo, después el punto de control"]
        direction LR
        A1["commit del trabajo"] --> F1["☠️ fallo"] --> N1["punto de control NO escrito"]
        N1 --> R1["al reanudar, se reprocesa lo ya hecho<br/>→ DUPLICADOS (salvo idempotencia)"]
    end
    subgraph V2["Primero el punto de control, después el trabajo"]
        direction LR
        A2["punto de control escrito"] --> F2["☠️ fallo"] --> N2["commit del trabajo NO hecho"]
        N2 --> R2["al reanudar, se salta trabajo<br/>→ PÉRDIDA SILENCIOSA, que es peor"]
    end
    V1 ~~~ V2
    style R2 stroke:#d9534f,stroke-width:2px
```
'''),
("12-cache-con-valkey.md", "leer:     mirar caché → si falla, leer origen → guardar en caché → devolver", '''```mermaid
flowchart TD
    subgraph LE["leer"]
        direction LR
        L1{"mirar caché"} -- "acierto" --> L4["devolver"]
        L1 -- "falla" --> L2["leer origen"] --> L3["guardar en caché"] --> L4
    end
    subgraph ES["escribir"]
        direction LR
        E1["escribir origen"] --> E2["INVALIDAR la clave<br/>(no actualizarla)"]
    end
    LE ~~~ ES
```
'''),
("12-cache-con-valkey.md", "t0  Goroutine A: falla la caché, lee de Mongo → obtiene población 52.000.000", '''```mermaid
sequenceDiagram
    participant A as Goroutine A
    participant K as Caché
    participant M as Mongo
    participant B as Goroutine B
    Note over A,B: t0
    A->>K: Get: falla la caché
    A->>M: lee de Mongo
    M-->>A: población 52.000.000
    Note over A,B: t1
    B->>M: escribe población 53.000.000
    B->>K: invalida la clave
    Note over A,B: t2
    A->>K: guarda el valor VIEJO (52.000.000)
    Note over K: La caché queda con un dato obsoleto,<br/>y el TTL es lo único que lo arregla.
```
'''),
("16-go-frente-a-spring-boot.md", "JVM:", '''```mermaid
flowchart TD
    subgraph JV["JVM"]
        direction LR
        J1["arranque"] --> J2["interpretar bytecode"] --> J3["perfilar qué<br/>se ejecuta mucho"]
        J3 --> J4["compilar a código<br/>máquina con C1"] --> J5["recompilar con C2 optimizando<br/>AGRESIVAMENTE con la información<br/>de ejecución real"]
    end
    subgraph GO["Go"]
        direction LR
        G1["compilar todo a código máquina ANTES"] --> G2["ejecutar"]
    end
    JV ~~~ GO
```
'''),
("01-sintaxis-y-valores.md", "slice = { ptr → arreglo de respaldo,  len,  cap }", '''```mermaid
flowchart LR
    MV["movements<br/>cabecera: ptr · len=4 · cap=4"] -- "ptr" --> AR
    FT["firstTwo<br/>cabecera: ptr · len=2 · cap=4"] -- "ptr" --> AR
    AR["arreglo de respaldo, el MISMO para los dos<br/>[SALE] [REFUND] [VOID] [DEPOSIT]"]
```
'''),
]

nuevos = {}
for archivo, primera, mermaid in CAMBIOS:
    t = nuevos.get(archivo) or (C / archivo).read_text(encoding="utf-8")
    patron = re.compile(r"```text\n" + re.escape(primera) + r"\n.*?\n```\n", re.S)
    hallados = patron.findall(t)
    assert len(hallados) == 1, (archivo, primera, len(hallados))
    nuevos[archivo] = t.replace(hallados[0], mermaid, 1)
for archivo, t in nuevos.items():
    (C / archivo).write_text(t, encoding="utf-8")
    print("escrito", archivo)
PYEOF
python3 zz-code/go-for-java-devs-20261005-ab98/migrar_diagramas.py cursos-algoritmos-lenguajes/go-for-java-devs && git diff --stat cursos-algoritmos-lenguajes/go-for-java-devs

# --- 2026-10-05T15:26:37 · Render go Mermaid diagrams to PNG
cd /Users/oskar/Developer/Learning/courses-ia-generated; G=cursos-algoritmos-lenguajes/go-for-java-devs; S=zz-code/go-for-java-devs-20261005-ab98/salidas; python3 - "$G" "$S" <<'EOF'
import re,sys,pathlib
g,s=map(pathlib.Path,sys.argv[1:])
i=0
for f in ["01-sintaxis-y-valores.md","12-cache-con-valkey.md","13-lotes-scheduling-y-asincronia.md","16-go-frente-a-spring-boot.md","17-capstone.md"]:
    for m in re.findall(r"```mermaid\n(.*?)```",(g/f).read_text(encoding="utf-8"),re.S):
        i+=1; (s/f"d{i}-{f[:2]}.mmd").write_text(m,encoding="utf-8")
print(i)
EOF
cd $S; for f in d*.mmd; do mmdc -i $f -o ${f%.mmd}.png -b white -s 1.5 >/dev/null 2>&1 && echo "OK $f" || echo "FALLA $f"; done

# --- 2026-10-05T15:26:55 · Outline 0-ESTRUCTURA and README verdict section
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/go-for-java-devs; grep -n "^#\|^> " 0-ESTRUCTURA-CURSO.md | head -40; sed -n 76,88p README.md

# --- 2026-10-05T15:27:15 · Show endings of guide and alcance
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/go-for-java-devs; tail -8 prompts/guia-de-estilo-y-convenciones.md; tail -4 prompts/alcance-del-proyecto.md

# --- 2026-10-05T15:27:34 · Append D-12 rows to alcance and section 14 to guide
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/go-for-java-devs; cat >> prompts/alcance-del-proyecto.md <<'EOF'
| Diagramas | **Mermaid** (D-12, 05/10/2026, en la revisión del curso) | Árboles de archivos, salidas y correspondencias siguen en `text`; guía §14.1 |
| Gemelo Spring Boot | **Deuda declarada** (05/10/2026): `reference/clearinghouse-spring/` no se publicó | La F16 y el README lo avisan; la fase se lee y se prepara, el duelo espera al gemelo; guía §14.2 |
EOF
cat >> prompts/guia-de-estilo-y-convenciones.md <<'EOF'

---

## 14. Excepciones a los lineamientos del repositorio

> 📝 **Sección agregada el 05/10/2026**, en la revisión del curso contra los lineamientos de
> producción del repositorio. Va después del checklist para no renumerar nada: §13 sigue siendo el
> checklist. Esta guía se escribió antes de que esos lineamientos existieran; lo que aquí se declara
> ya era la práctica del curso, y desde ahora está escrito como decisión.

El `CLAUDE.md` del repositorio da **valores por defecto**, y esta guía los reemplaza donde lo
declara: la regla general, el valor nuevo y por qué. Lo que esta sección no menciona se hereda tal
cual.

| Regla general del repositorio | Lo que hace este curso | Por qué |
|---|---|---|
| Comentarios dentro del código en inglés | **En español, con tildes**, igual que los mensajes de error (§5) | El comentario es el canal del *porqué*, y el curso piensa en español; los identificadores siguen en inglés |
| Apéndices `aNN-` | **Ninguno** (alcance §9) | "Diciendo y haciendo" pierde sentido si hay que saltar a otro archivo para ejecutar el siguiente comando |
| Código ejecutable del curso en `src/` | **No hay `src/` ni `.gitignore` de curso**: el lector construye los cuatro servicios en su propio repositorio (`00-convencion-de-git-y-tags.md`) | El curso enseña a escribirlos; entregarlos hechos le quitaría el ejercicio. La única pieza que sí se entregaría hecha es el gemelo Spring Boot (§14.2) |
| Ninguna salida inventada; lo no ejecutado se marca | **Las salidas de las fases son ilustrativas**, y así se le declara al lector en `0-ESTRUCTURA-CURSO.md` §6 y en el README. Las cifras que cuentan las mide el lector en `BENCHMARKS.md` | Decisión del 05/10/2026: las salidas no se ejecutaron al escribir el curso. Enseñan a leer la herramienta; ninguna sostiene una afirmación |
| Diagramas a criterio de quien escribe | **Mermaid**, salvo árboles de archivos, salidas y correspondencias (D-12, §14.1) | Pedido explícito del autor en la revisión del 05/10/2026 |

### 14.1 D-12 · Diagramas en Mermaid

**Decidido el 05/10/2026 por el autor, en la revisión del curso.** Todo diagrama —arquitectura, flujo,
secuencia, estructura en memoria— va en un bloque `mermaid`, con una frase antes que diga qué mirar.
Quedan en `text` los árboles de archivos, las salidas de terminal, las correspondencias en columnas
(`cpu → ¿dónde se gasta…?`), las listas de pasos con flechas y las líneas de tiempo de un incidente,
que no son diagramas.

La revisión convirtió siete: el slice compartido (F01), cache-aside y su carrera, como
`sequenceDiagram` (F12), la transacción con punto de control y sus dos ventanas de fallo (F13), JVM
frente a Go (F16) y la plataforma del capstone (F17).

### 14.2 Deudas y ausencias declaradas

- **El gemelo Spring Boot no se publicó.** El alcance §13, la historia §7, `proyecto-04-clearinghouse.md`
  y la F16 lo dan por entregado en `reference/clearinghouse-spring/`, y no existe; el alcance §9
  tampoco lo incluye en la estructura. Desde el 05/10/2026 la F16 y el README lo avisan al lector.
  Cuando se escriba, se revisa además la versión: el curso nombra **Spring Boot 3**, y conviene
  medir contra la línea vigente con fecha y fuente.
- **Las versiones no tienen fecha ni fuente** (go1.25.1, PostgreSQL 16, MongoDB 7, Valkey 8). Quedan
  como están; la próxima sesión que toque el curso las verifica antes de cambiar nada.
- **Plan de producción, diccionario de términos, contrato de nombres y README de `prompts/`** no
  existen con esos nombres: el curso es anterior a los lineamientos y está cerrado. Hacen su papel el
  diccionario del dominio del alcance §5.2, los `proyecto-0N-*.md` (nombres de cada servicio) y
  `prompts-extendidos-fases.md` (los prompts de fase).
- **`aprendizaje.md` está en `prompts/`, pero es para el lector**: el método de estudio. Como
  `prompts/` no se publica, si se quiere que el lector lo tenga hay que sacarlo a la raíz del curso.
- **Verificador:** `prompts/verificar-corpus.py`, subclase del perfil `courses-ia` de
  `prompts/verificador_base.py`, con los marcadores y callouts de §8. Se corre desde la raíz del curso
  con `python3 prompts/verificar-corpus.py`.
EOF
tail -2 prompts/alcance-del-proyecto.md | cut -c1-80

# --- 2026-10-05T15:27:40 · Inspect go phase header and sections
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/go-for-java-devs; sed -n 1,12p 05-http-rest-stdlib.md; grep -n "^## " 05-http-rest-stdlib.md 08-migracion-a-go-moderno.md 17-capstone.md 14-observabilidad-y-hardening.md

# --- 2026-10-05T15:28:02 · Write go verifier subclass and run it
cd /Users/oskar/Developer/Learning/courses-ia-generated; G=cursos-algoritmos-lenguajes/go-for-java-devs; cp zz-instrucciones/herramientas/verificador_base.py $G/prompts/verificador_base.py; cat > $G/prompts/verificar-corpus.py <<'EOF'
#!/usr/bin/env python3
"""Verificador del curso Go para desarrolladores Java senior (guía de estilo §14.2).

Hereda las validaciones base de `verificador_base.py` (enlaces, anclas, restos de plantilla,
codificación, callouts, encabezado) con el perfil del repositorio, y agrega las de este curso.

Uso, desde la raíz del curso:
    python3 prompts/verificar-corpus.py

Validaciones propias de este curso, además de las base:
  ERROR EJERCICIOS  el título «## 🧪 8. Ejercicios (N)» no coincide con los ejercicios numerados
  aviso BANDA       una fase con menos de 20 o más de 30 ejercicios (guía §10)
  aviso DESAFIOS    una fase sin sus tres 🔴 desafíos de cierre D1–D3 (guía §9.2)
  aviso SECCION     una fase sin alguna de las 10 secciones de la plantilla (guía §9)
  aviso DIAGRAMA    un bloque `text` que parece diagrama y no es árbol de archivos (D-12, guía §14.1)
"""

import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from verificador_base import PerfilCoursesIA, main  # noqa: E402

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

# Las 10 secciones de la plantilla de fase (guía §9), por el texto que sigue al número.
SECCIONES_DE_FASE = ("1. Propósito", "2. Qué queda listo", "3. Qué NO entra", "4. Concepto mínimo",
                     "5. CLI de la fase", "6. Construcción guiada", "7. Autopsia", "8. Ejercicios",
                     "9. Referencias", "10. Veredicto")
CAJAS_RE = re.compile(r"[┌┐└┘├┤┬┴┼─│═║╔╗╚╝]")
RAMA_ARBOL_RE = re.compile(r"^\s*[│├└]─")


class VerificadorDelCurso(PerfilCoursesIA):
    # Marcadores y callouts de la guía §8 (8.1, 8.2 y 8.3).
    CALLOUTS = {"☕", "🩻", "🕰️", "💸", "⭐", "🔥", "📐", "🧨", "🏷️",
                "🧭", "🧠", "⚠️", "💡", "📝", "📚",
                "🪞", "⚰️", "📖", "🛠️", "🧪", "⚖️", "📌"}
    # Emoji con moderación en ###: los marcadores y las secciones recurrentes no avisan
    # (el verificador revisa carácter por carácter: van también sin el U+FE0F).
    EMOJI_PERMITIDOS_H3 = PerfilCoursesIA.EMOJI_PERMITIDOS_H3 | CALLOUTS | {c.replace("️", "") for c in CALLOUTS}
    # El encabezado de fase de la plantilla.
    CAMPOS_ENCABEZADO = ("Fase ", "Época", "Depende de", ("Proyecto que avanza", "Proyectos que avanzan"))
    # 00-historia y 00-convencion llevan número de fase pero no son fases.
    NO_CAPITULO = PerfilCoursesIA.NO_CAPITULO + ("historia", "convencion")

    def verificar_capitulo_extra(self, ruta, lineas, texto, preguntas):
        nombre = self.rel(ruta)
        titulos = [l for _, l in lineas if l.startswith("## ")]
        for seccion in SECCIONES_DE_FASE:
            if not any(seccion in t for t in titulos):
                self.aviso("SECCION", f"{nombre}: falta «{seccion}»")
        self.verificar_ejercicios(nombre, lineas)

    def verificar_documento_extra(self, ruta, lineas, texto):
        # `lineas` llega sin los bloques de código: los diagramas se buscan en el texto crudo.
        self.verificar_diagramas(self.rel(ruta), enumerate(texto.splitlines(), 1))

    def verificar_ejercicios(self, nombre, lineas):
        # El número declarado cuenta solo los numerados del recorrido base: los 🔥 y los
        # desafíos de cierre D1–D3 quedan fuera (guía §10).
        declarado, numerados, desafios, dentro = None, 0, set(), False
        for _, linea in lineas:
            if linea.startswith("## "):
                m = re.match(r"^## 🧪 8\. Ejercicios \((\d+)\)", linea)
                dentro = bool(m)
                if m:
                    declarado = int(m.group(1))
                continue
            if not dentro:
                continue
            if re.match(r"^\d+\. ", linea):
                numerados += 1
            d = re.match(r"^\*\*(D[1-3])\b", linea)
            if d:
                desafios.add(d.group(1))
        if declarado is None:
            return
        if declarado != numerados:
            self.error("EJERCICIOS", f"{nombre}: el título dice {declarado} y hay {numerados} numerados")
        if not 20 <= numerados <= 30:
            self.aviso("BANDA", f"{nombre}: {numerados} ejercicios (banda 20–30, guía §10)")
        if desafios != {"D1", "D2", "D3"}:
            self.aviso("DESAFIOS", f"{nombre}: desafíos de cierre {sorted(desafios) or 'ninguno'} (guía §9.2)")

    def verificar_diagramas(self, nombre, lineas):
        bloque, inicio = None, 0
        for n, linea in lineas:
            if bloque is None and linea.startswith("```text"):
                bloque, inicio = [], n
            elif bloque is not None and linea.startswith("```"):
                cajas = sum(1 for l in bloque if CAJAS_RE.search(l))
                arbol = bloque and bloque[0].rstrip().endswith("/")
                if cajas >= 2 and not arbol and any(RAMA_ARBOL_RE.match(l) or "┌" in l for l in bloque):
                    self.aviso("DIAGRAMA", f"{nombre}:{inicio}: bloque text con forma de diagrama; va en Mermaid (D-12)")
                bloque = None
            elif bloque is not None:
                bloque.append(linea)


if __name__ == "__main__":
    sys.exit(main(VerificadorDelCurso, RAIZ))
EOF
cd $G; python3 -B prompts/verificar-corpus.py | tee ../../zz-code/go-for-java-devs-20261005-ab98/salidas/despues.log | awk '{print $1,$2}' | sort | uniq -c; grep -v "EMOJI" ../../zz-code/go-for-java-devs-20261005-ab98/salidas/despues.log | head -30

# --- 2026-10-05T15:28:09 · Compare callout warnings before and after
cd /Users/oskar/Developer/Learning/courses-ia-generated; grep CALLOUT zz-code/go-for-java-devs-20261005-ab98/salidas/antes.log | awk '{print $3}' | cut -d: -f1 | sort | uniq -c

# --- 2026-10-05T15:28:12 · Inspect an earlier callout warning
cd /Users/oskar/Developer/Learning/courses-ia-generated; grep CALLOUT zz-code/go-for-java-devs-20261005-ab98/salidas/antes.log | head -4; sed -n "$(grep CALLOUT zz-code/go-for-java-devs-20261005-ab98/salidas/antes.log | sed -n 2p | awk '{print $3}' | cut -d: -f2)p" cursos-algoritmos-lenguajes/go-for-java-devs/01-sintaxis-y-valores.md

# --- 2026-10-05T15:28:21 · Seed errors in a copy and run final checks
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/go-for-java-devs; Z=../../zz-code/go-for-java-devs-20261005-ab98/salidas/copia-sembrada; mkdir -p $Z; cp -R *.md prompts $Z/; cd $Z
perl -CSD -Mutf8 -pi -e 's/^## 🧪 8\. Ejercicios \(24\)/## 🧪 8. Ejercicios (25)/' 01-sintaxis-y-valores.md
perl -CSD -Mutf8 -pi -e 's/^## 🛠️ 5\. CLI de la fase/## 🛠️ 5. Línea de comandos/' 03-errores-paquetes-io.md
perl -CSD -Mutf8 -pi -e 's/^\*\*D3\b/**X3/' 05-http-rest-stdlib.md
printf '\n```text\n┌────┐\n│ a  │\n└────┘\n```\n' >> 07-context-y-ciclo-de-vida.md
python3 -B prompts/verificar-corpus.py | grep -v "EMOJI\|CALLOUT\|ENCAB"; cd /Users/oskar/Developer/Learning/courses-ia-generated; python3 -B zz-instrucciones/herramientas/verificador_base.py cursos-algoritmos-lenguajes/go-for-java-devs --perfil=courses-ia | tail -1; python3 -B zz-instrucciones/herramientas/verificador_base.py cursos-algoritmos-lenguajes/go-for-java-devs --perfil=publicacion | grep "^ERROR" | grep -vc EMOJI; git status --short cursos-algoritmos-lenguajes/go-for-java-devs

# --- 2026-10-05T15:28:36 · Write go manifest and update memory
cd /Users/oskar/Developer/Learning/courses-ia-generated; cat > zz-code/go-for-java-devs-20261005-ab98/MANIFIESTO.md <<'EOF'
# go-for-java-devs-20261005-ab98

- **Curso:** go-for-java-devs
- **Tanda:** — (revisión del curso cerrado contra `zz-instrucciones/`)
- **Creado:** 2026-10-05
- **Propósito:** validación contra zz-instrucciones y migración de diagramas a Mermaid
- **Estado:** extraído
- **Cómo regenerar lo que limpiar.py borra:** `salidas/` se rehace corriendo los verificadores
  (`python3 -B zz-instrucciones/herramientas/verificador_base.py <curso> --perfil=courses-ia`, y
  `python3 -B prompts/verificar-corpus.py` desde la raíz del curso) y `mmdc` sobre los `.mmd`.

## Qué hay

- `buscar_diagramas.py` — copia del de la sesión de C#: lista bloques `text` con forma de diagrama.
- `migrar_diagramas.py` — los siete reemplazos `text` → Mermaid, ya aplicados (falla si un bloque
  no aparece exactamente una vez).
- `salidas/antes.log`, `publicacion.log`, `diagramas.log`, `candidatos.txt` — el estado inicial.
- `salidas/d*.mmd`, `d*.png` — los siete diagramas dibujados con `mmdc` 12.0.0.
- `salidas/despues.log` — el verificador del curso al cerrar.
- `salidas/copia-sembrada/` — copia con cuatro errores sembrados para probar `verificar-corpus.py`
  (los cuatro detectados).

## Qué sirvió

- La búsqueda de diagramas pasó, reducida, al aviso `DIAGRAMA` de `prompts/verificar-corpus.py`.
EOF
python3 - <<'EOF'
p='/Users/oskar/.claude/projects/-Users-oskar-Developer-Learning-courses-ia-generated/memory/revision-cursos-lenguajes-zz-instrucciones.md'
t=open(p,encoding='utf-8').read()
t=t.replace("description: Revisión de los cursos de cursos-algoritmos-lenguajes contra zz-instrucciones, con diagramas a Mermaid; C# hecho el 05/10/2026, go y python pendientes.",
"description: Revisión de los cursos de cursos-algoritmos-lenguajes contra zz-instrucciones, con diagramas a Mermaid; C# y go hechos el 05/10/2026, python pendiente.")
t=t.replace("**Siguen:** `go-for-java-devs` y `python-for-java-devs` (ver [[python-java-devs-estado]]).",
"""**Go (hecho el 05/10/2026, sin commit):**
- Siete diagramas a Mermaid (F01, F12 ×2 —uno como `sequenceDiagram`—, F13 ×2, F16, F17).
- Guía §14 y dos filas en el alcance §13.
- Oskar confirmó que **las salidas de las fases no se ejecutaron**: se declaran ilustrativas en
  `0-ESTRUCTURA-CURSO.md` §6 y en el README.
- El gemelo Spring Boot (`reference/clearinghouse-spring/`) **no existe**: queda como deuda declarada,
  con avisos en la F16 y el README.
- Quedan abiertos: versiones sin fecha (go1.25.1…), `aprendizaje.md` atrapado en `prompts/`, y la
  versión Spring Boot 3 a revisar cuando se escriba el gemelo.

**Sigue:** `python-for-java-devs` (ver [[python-java-devs-estado]]: camino base sin commitear).""")
open(p,'w',encoding='utf-8').write(t)
m='/Users/oskar/.claude/projects/-Users-oskar-Developer-Learning-courses-ia-generated/memory/MEMORY.md'
s=open(m,encoding='utf-8').read().replace("— C# hecho el 05/10/2026 (Mermaid, guía §14, verificador); siguen go y python.","— C# y go hechos el 05/10/2026 (Mermaid, guía §14, verificador); sigue python.")
open(m,'w',encoding='utf-8').write(s)
EOF
tail -1 /Users/oskar/.claude/projects/-Users-oskar-Developer-Learning-courses-ia-generated/memory/MEMORY.md

# --- 2026-10-05T15:34:01 · Compare zz-instrucciones and zz-code between repos
J=/Users/oskar/Developer/job-interview-sept-2026; C=/Users/oskar/Developer/Learning/courses-ia-generated; diff -rq $J/zz-instrucciones $C/zz-instrucciones; echo ---; ls -la $J/zz-code | grep -v "^d.*-20[0-9]\{6\}-"; echo ---; for f in README.md .gitignore nuevo.py limpiar.py; do cmp -s $J/zz-code/$f $C/zz-code/$f && echo "igual $f" || echo "DISTINTO $f"; done; ls $J/zz-code

# --- 2026-10-05T15:35:00 · Recompare zz-instrucciones and check job-interview git state
J=/Users/oskar/Developer/job-interview-sept-2026; C=/Users/oskar/Developer/Learning/courses-ia-generated; diff -rq -x __pycache__ $J/zz-instrucciones $C/zz-instrucciones; echo "rc=$?"; for d in zz-instrucciones zz-code; do echo "== $d"; ls -laT $J/$d | grep -v "^d" | awk '{print $6,$7,$8,$9,$10}'; done; git -C $J status --short zz-instrucciones zz-code; git -C $J log --oneline -3 -- zz-instrucciones zz-code

# --- 2026-10-05T15:35:20 · Read python course memory and inventory
cat /Users/oskar/.claude/projects/-Users-oskar-Developer-Learning-courses-ia-generated/memory/python-java-devs-estado.md; P=/Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs; ls -la $P $P/prompts; git -C $P status --short . | head -40

# --- 2026-10-05T15:35:25 · Outline the optional topics proposal
P=/Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs/prompts; grep -n "^#\|^## \|^### " $P/propuestas-temas-opcionales.md | head -120

# --- 2026-10-05T15:35:27 · Read the carta criteria and nomenclature
P=/Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs/prompts; sed -n 1,264p $P/propuestas-temas-opcionales.md

# --- 2026-10-05T15:35:30 · Read carta order and open issues
P=/Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs/prompts; sed -n 1086,1200p $P/propuestas-temas-opcionales.md; grep -c "^| \`\?[a-z][a-z][0-9][0-9]" $P/propuestas-temas-opcionales.md

# --- 2026-10-05T15:35:38 · Count planned sections per carta track
P=/Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs/prompts; python3 - "$P/propuestas-temas-opcionales.md" <<'EOF'
import re,sys,collections
t=open(sys.argv[1],encoding='utf-8').read()
ids=re.findall(r'^\|\s*\**`?([a-z]{2})(\d{2})`?',t,re.M)
c=collections.OrderedDict()
for tr,n in ids: c.setdefault(tr,set()).add(n)
tot=0
for k,v in c.items(): print(k,len(v),sorted(v)[:3],'…'); tot+=len(v)
print('total',tot)
EOF
sed -n 265,300p $P/propuestas-temas-opcionales.md

# --- 2026-10-05T15:36:41 · Outline python guide and find carta references
P=/Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs/prompts; grep -n "^## \|^### " $P/guia-de-estilo-y-convenciones.md; grep -n "carta\|op0\|opNNN" $P/guia-de-estilo-y-convenciones.md $P/plantillas-de-capitulo.md $P/README.md $P/alcance-del-proyecto.md ../../../ 2>/dev/null | head -40

# --- 2026-10-05T15:36:44 · Read guide intro, code language, markers, template, exercises
P=/Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs/prompts; sed -n 1,60p $P/guia-de-estilo-y-convenciones.md; sed -n 179,240p $P/guia-de-estilo-y-convenciones.md; sed -n 327,533p $P/guia-de-estilo-y-convenciones.md

# --- 2026-10-05T15:36:48 · Read template carta note, prompts README, story outline
P=/Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs; sed -n 18,40p $P/prompts/plantillas-de-capitulo.md; sed -n 1,60p $P/prompts/README.md; grep -n "^#" $P/00-historia-de-aurea.md

# --- 2026-10-05T15:36:51 · Read Áurea characters, Odontovía and constraints
P=/Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs; sed -n 1,23p $P/00-historia-de-aurea.md; sed -n 190,260p $P/00-historia-de-aurea.md; sed -n 350,374p $P/00-historia-de-aurea.md; sed -n 628,640p $P/00-historia-de-aurea.md

# --- 2026-10-05T15:37:05 · Create zz-code dir and test PyPI access
cd /Users/oskar/Developer/Learning/courses-ia-generated; python3 zz-code/nuevo.py python-for-java-devs --tanda P-carta --proposito "preparación y redacción de la carta opcional (opNNN)"; curl -s -o /dev/null -w "%{http_code}\n" https://pypi.org/pypi/playwright/json; curl -s https://pypi.org/pypi/playwright/json | python3 -c "import json,sys;d=json.load(sys.stdin);print(d['info']['version'], d['releases'][d['info']['version']][0]['upload_time'])"; python3 --version; docker --version 2>&1 | head -1

# --- 2026-10-05T15:37:36 · Read production plan template
sed -n 1,335p /Users/oskar/Developer/Learning/courses-ia-generated/zz-instrucciones/plantillas/plan-de-produccion.md | grep -v "^$" | head -200

# --- 2026-10-05T15:38:14 · Run inventory check against PyPI
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs; python3 -B prompts/check-inventario.py 2>&1 | tail -3; grep -c "^| \`" prompts/inventario-verificado.md; grep "❌\|💤" prompts/inventario-verificado.md | sort -u

# --- 2026-10-05T15:41:37 · Compare claimed versions against PyPI
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs; grep -E "\`(SQLAlchemy|Django|peewee|pony|tortoise-orm|piccolo|sqlmodel|ormar|PyPika|aiosql|dataset|masonite-orm|yagmail|paramiko|mediapipe|insightface|rembg|playwright|psycopg|redis|pymongo|cryptography|pydantic|fastapi|uv|anthropic)\`" prompts/inventario-verificado.md | sort -u; grep -n "3.14\|Python 3" prompts/alcance-del-proyecto.md | head -5

# --- 2026-10-05T15:41:59 · Check guide ending and references section
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs; tail -5 prompts/guia-de-estilo-y-convenciones.md; grep -n "^## 1[0-9]" prompts/guia-de-estilo-y-convenciones.md; sed -n 533,566p prompts/guia-de-estilo-y-convenciones.md

# --- 2026-10-05T15:42:28 · Append carta section 14 to python guide
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs; cat >> prompts/guia-de-estilo-y-convenciones.md <<'EOF'

---

## 14. La carta: forma, excepciones y reglas de producción

> 📝 **Sección agregada el 05/10/2026**, al abrir la escritura de la carta. Va después del
> checklist para no renumerar nada: §13 sigue siendo el checklist del camino base y de los
> complementos. Lo que aquí se decide manda sobre la carta y solo sobre la carta. Las decisiones
> marcadas *por defecto* las tomó la sesión para no bloquearse y esperan revisión del autor.

### 14.1 Lo que el autor decidió (05/10/2026)

- **Se escribe la carta entera**, encadenada, en el orden de `propuestas-temas-opcionales.md` §19
  (primero los tracks con encargo en Áurea, después los demás). El orden y el estado viven en
  [`plan-de-produccion-carta.md`](plan-de-produccion-carta.md).
- **Forma ligera, unas 400 líneas por sección**: problema → modelo → ejemplo que corre → lo que se
  rompe → cuándo NO usarla → ejercicios → referencias → cierre. El esqueleto está en
  [`plantillas-de-capitulo.md`](plantillas-de-capitulo.md), *Plantilla de sección de la carta*.
- **El código se escribe por inspección, sin ejecutar.** Cada sección lo declara en su
  encabezado, y toda salida que muestre va rotulada **«Salida esperada, sin correr»**. La deuda de
  ejecución se lleva en el plan, y una tanda de verificación final la paga.

### 14.2 Excepciones a las reglas de la carta y del repositorio

| Regla general | Lo que hace la carta | Por qué |
|---|---|---|
| 20–30 ejercicios por sección (valor por defecto del repositorio; 20–25 en este curso, §9) | **8 a 12 ejercicios**, con el mismo reparto 🟢🟡🟠🔴 y la misma escala de §9 | Decisión del autor: una sección suelta de 400 líneas no sostiene veinte ejercicios sin relleno |
| Cada ejercicio con solución de referencia o rúbrica | **Cada ejercicio cierra con `**Criterio:**` verificable**; los 🔴 llevan además una rúbrica de tres o cuatro puntos. No se publican soluciones | *Por defecto, a revisar*: el criterio verificable es lo que el lector necesita para saber si terminó, y una solución escrita por inspección sería código sin correr presentado como respuesta |
| El código de cada documento vive en `src/<nombre del documento>/` (§8.2) | **El código va en la sección**, completo y en un solo bloque por archivo; `src/opNNN-…/` se crea en la tanda de verificación, al ejecutarlo | *Por defecto, a revisar*: escribir cada archivo dos veces sin poder correrlo duplica el riesgo de que diverjan, que es justo lo que la regla de `src/` quiere evitar |
| Ninguna salida inventada | Las salidas van **rotuladas como esperadas y sin correr**; ningún número de rendimiento se presenta como medido | Mismo método que las mediciones `⏳` del curso: la especificación se publica, el número espera |
| Diagramas a criterio de quien escribe | **Mermaid**, salvo árboles de archivos, salidas y correspondencias en columnas, que van en `text` | *Por defecto, a revisar*: es la elección que el autor pidió el 05/10/2026 para los cursos de esta familia; el camino base no se convierte aquí |
| Una sección por plataforma | **Linux y macOS**; lo que solo corre en Windows se dice y no se escribe | El curso no fija Windows, y la carta no lo agrega |

### 14.3 Reglas de producción que heredan todas las secciones

- **Versiones desde [`inventario-verificado.md`](inventario-verificado.md)**, que genera
  `check-inventario.py` contra PyPI. Una sección no nombra una versión que no esté ahí; si nombra
  un paquete nuevo, se agrega al inventario y se regenera antes. Un paquete marcado 💤 se nombra con
  su fecha y su veredicto (quieto porque está terminado, o quieto porque está muerto: §18 de la
  propuesta).
- **URL por código de estado**, verificadas al cerrar cada tanda. Aterrizar en la portada de la
  documentación cuenta como roto.
- **Autocontenida y suelta**: una sección enlaza fases del camino base y documentos del curso, y
  secciones de la carta **anteriores** a ella; nunca una posterior, y nunca otra cosa de fuera de
  esta carpeta.
- **Áurea cuando le sirve al tema**, con los nombres de la historia y el diccionario de §5.1; un
  ejemplo propio cuando no. Ningún dato clínico identificable en ningún ejemplo (historia §5).
- **Los servicios corren en contenedores** con un `compose.yaml` dentro de la sección, imágenes
  oficiales con etiqueta fija y puertos por defecto (el lector los reconoce).
- **Fusiones y mudanzas de la propuesta, ya aplicadas a la numeración** (plan §5): `cl` vive dentro
  de `ui` como `ui10`–`ui12`; `ed05` se muda a `ui01`; `au04` se muda a `qa09` y el track `au`
  queda en siete secciones; `vz` se recorta a cuatro; EPUB es un 🔴 desafío de `ar06`.
- **Reparto de `qa` y `ob`** alrededor del cierre nocturno (*por defecto, a revisar*): `qa` prueba
  el cierre **antes** de que corra —integración, propiedades, carga—; `ob` lo observa **mientras**
  corre y después —bitácoras, métricas, trazas, alertas—. Ninguna sección de un track repite un
  ejemplo del otro.
- **Track `cv`**: camino (a) de la propuesta §13. La técnica se enseña con rostros del propio lector
  o sintéticos, y **ninguna imagen de paciente** aparece ni se sugiere; `cv05` y `cv08` dicen por
  qué Áurea no puede desplegar reconocimiento.

### 14.4 Checklist de una sección de la carta

- [ ] Encabezado con track, posición, «se lee suelta», fecha de versiones y la declaración de
      código sin ejecutar.
- [ ] Se lee sin haber leído ninguna otra sección de la carta.
- [ ] Explica qué problema resuelve la herramienta **y cuándo no usarla** (⚖️).
- [ ] Un ejemplo completo, con su instalación (`uv add …` o `compose.yaml`), identificadores en
      inglés y comentarios en español.
- [ ] Toda salida rotulada «Salida esperada, sin correr»; ningún número presentado como medido.
- [ ] Toda versión nombrada está en `inventario-verificado.md`; los 💤 llevan su fecha.
- [ ] Ninguna comparación sin número, o sin la medición `⏳` que la sostendría.
- [ ] 8–12 ejercicios con rangos 🟢🟡🟠🔴, cada uno con `**Criterio:**`, y rúbrica en los 🔴.
- [ ] Referencias con URL completa y verificada, y orden de lectura.
- [ ] Cierra con La señal de que quedó bien y el bloque 🏷️ `op-<tt>-fase-NN`.
- [ ] Enlaza solo hacia atrás, y nada de fuera de esta carpeta.
EOF
echo ok

# --- 2026-10-05T15:42:40 · Append carta section template
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs; tail -3 prompts/plantillas-de-capitulo.md; cat >> prompts/plantillas-de-capitulo.md <<'EOF'

---

# 🍽️ Plantilla de sección de la carta

Agregada el 05/10/2026 (guía §14). Es **guía y no molde**: las ocho secciones van en este orden,
pero una sección puede fundir dos si el tema lo pide, y 🪞, 🩻 y 📖 aparecen solo cuando hay un
reflejo de Java que recalibrar. Unas 400 líneas.

````markdown
# {{emoji}} {{tt}}{{NN}} — {{Nombre}}

> Python para desarrolladores Java senior · **Carta** · Track `{{tt}}` — {{nombre del track}} ·
> sección {{N}} de {{M}}
> Se lee suelta: no hace falta ninguna otra sección de la carta. {{Conviene haber leído la Fase NN.}}
> Versiones verificadas contra PyPI el 05/10/2026 · Código escrito sin ejecutar: las salidas
> rotuladas «Salida esperada, sin correr» no salen de una corrida.

---

## 🎯 1. Qué problema resuelve

{{El problema concreto, y quién lo tiene. En Áurea si le sirve al tema; con su propio ejemplo si
no. Dos o tres párrafos.}}

## 🧠 2. El modelo

{{La idea que hace que el resto encaje. 🪞 si hay un reflejo de Java que se rompe; 📖 si hay
traducción en las dos direcciones; un diagrama Mermaid si hay estructura que mostrar.}}

## 💻 3. El ejemplo que corre

{{Instalación (`uv add …` o el `compose.yaml`), el código completo en un bloque por archivo,
cómo se ejecuta, y la salida rotulada.}}

## ⚠️ 4. Lo que se rompe

{{Las dos o tres trampas reales, cada una con su síntoma y su arreglo.}}

## ⚖️ 5. Cuándo NO usarla

{{Contra qué pierde, con número o con su medición ⏳; y la alternativa.}}

## 🧪 6. Ejercicios ({{8–12}})

**🟢 Fácil (1–{{n}})**
1. {{…}} **Criterio:** {{verificable}}.

**🟡 Intermedio** · **🟠 Difícil** · **🔴 Muy difícil** (con *Rúbrica:* de tres o cuatro puntos)

## 📚 7. Referencias

{{Documentación oficial, PyPI, artículos; orden de lectura sugerido.}}

## 🚀 8. Cierre

{{Qué te llevas, y La señal de que quedó bien.}}

> 🏷️ **Cierra la sección con su tag**, cuando los ejercicios que elegiste estén hechos:
>
> ```bash
> git tag -a op-{{tt}}-fase-{{NN}} -m "op {{tt}}{{NN}} cerrada: <lo que hiciste, en una línea>"
> ```
>
> Los commits llevan su prefijo (`op {{tt}}{{NN}}: …`) y los de ejercicio su número
> (`op {{tt}}{{NN}} ej07: …`).
````
EOF
echo ok

# --- 2026-10-05T15:43:23 · Define the carta list and numbering
mkdir -p /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516/salidas; cat > /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516/carta.py <<'EOF'
"""La lista única de la carta: track, nombre del track y secciones (slug, título). De aquí sale la
numeración opNNN del plan. Orden = propuesta §19 con las fusiones aplicadas (guía §14.3)."""
CARTA = [
 ("lg", "Legado e intercambio sectorial", [
  ("ancho-fijo-y-mainframe", "Ancho fijo y mainframe"),
  ("xml-en-serio", "XML en serio"),
  ("documentos-firmados", "Documentos firmados"),
  ("edi", "EDI: X12 y EDIFACT"),
  ("hl7-y-fhir", "Salud: HL7 v2 y FHIR"),
  ("archivos-planos-hostiles", "Archivos planos hostiles"),
  ("veredicto", "Veredicto: escribir el parser o comprarlo")]),
 ("au", "Automatización externa", [
  ("http-contra-sistemas-ajenos", "HTTP contra sistemas ajenos"),
  ("scraping", "Scraping y su fragilidad"),
  ("playwright", "Playwright y los portales sin API"),
  ("ssh-y-sistemas-remotos", "SSH y sistemas remotos"),
  ("apis-de-saas", "APIs de SaaS y su OAuth"),
  ("desplegar-automatizaciones", "Desplegar automatizaciones"),
  ("veredicto", "Veredicto: la automatización que se rompe sola")]),
 ("co", "Comunicaciones y transferencia", [
  ("correo-saliente", "Correo saliente"),
  ("que-el-correo-llegue", "Que el correo llegue"),
  ("correo-entrante", "Correo entrante"),
  ("probar-correo", "Probar correo sin mandarlo"),
  ("transferencia-de-archivos", "Transferencia de archivos"),
  ("mensajeria", "Mensajería y notificaciones"),
  ("veredicto", "Veredicto: qué protocolo para qué")]),
 ("wf", "Orquestación de trabajos y flujos", [
  ("el-eje", "El eje: de cron al flujo durable"),
  ("colas-de-tareas", "Colas de tareas"),
  ("programacion-en-proceso", "Programación en proceso"),
  ("airflow", "Airflow: el grafo declarativo"),
  ("prefect-y-dagster", "Prefect, Dagster y el asset"),
  ("temporal", "Temporal: flujos durables"),
  ("lo-transversal", "Idempotencia, reanudación y backfill"),
  ("veredicto", "Veredicto: el cierre nocturno en cuatro orquestadores")]),
 ("qa", "Calidad, pruebas y mantenimiento", [
  ("la-piramide-para-uno", "La pirámide para un equipo de uno"),
  ("pytest-a-fondo", "pytest a fondo"),
  ("dobles-y-datos", "Dobles y datos de prueba"),
  ("integracion-de-verdad", "Integración de verdad con testcontainers"),
  ("propiedades-y-modelos", "Propiedades y modelos con Hypothesis"),
  ("medir-la-suite", "Medir la suite: cobertura y mutación"),
  ("carga-y-rendimiento", "Carga y rendimiento"),
  ("la-cadena-de-calidad", "La cadena de calidad"),
  ("e2e-con-playwright", "Pruebas e2e con Playwright"),
  ("veredicto", "Veredicto: qué vale la pena cuando eres uno")]),
 ("ob", "Observar el sistema propio", [
  ("las-senales", "Las señales y los eventos anchos"),
  ("bitacoras", "Bitácoras"),
  ("metricas", "Métricas"),
  ("trazas", "Trazas con OpenTelemetry"),
  ("perfilado-en-produccion", "Perfilado en producción"),
  ("errores-como-producto", "Errores como producto"),
  ("veredicto", "Veredicto: el presupuesto de observabilidad")]),
 ("se", "Seguridad aplicada y criptografía", [
  ("el-modelo", "El modelo: qué pregunta contesta cada primitiva"),
  ("cryptography-y-pynacl", "cryptography y PyNaCl"),
  ("contrasenas-y-tokens", "Contraseñas y tokens"),
  ("identidad-delegada", "Identidad delegada: OAuth2 y OIDC"),
  ("secretos", "Secretos en reposo y en tránsito"),
  ("tls-de-verdad", "TLS de verdad"),
  ("defensa-de-la-aplicacion", "Defensa de la aplicación"),
  ("veredicto", "Veredicto: qué implementar y qué dejar de implementar")]),
 ("tx", "Texto, plantillas y documentación", [
  ("el-eje", "El eje: concatenar, formatear, plantilla, árbol"),
  ("jinja2-a-fondo", "Jinja2 a fondo"),
  ("las-otras-plantillas", "Las otras plantillas"),
  ("codigo-como-dato", "Colorear y entender código"),
  ("markdown", "Markdown y su ecosistema"),
  ("documentacion", "Documentación como producto"),
  ("generacion-de-codigo", "Generación de código y andamiaje"),
  ("texto-dificil", "Texto difícil: Unicode e internacionalización"),
  ("veredicto", "Veredicto: plantilla o lenguaje mal hecho")]),
 ("ui", "Interfaces y entregables sin frontend", [
  ("el-modelo-y-su-costo", "El modelo y su costo"),
  ("gradio", "Gradio"),
  ("streamlit", "Streamlit y su re-ejecución"),
  ("dash", "Dash y los callbacks"),
  ("nicegui-y-compania", "NiceGUI y compañía"),
  ("marimo", "marimo: el notebook que es una app"),
  ("presentaciones", "Presentaciones programáticas"),
  ("reportes", "Reportes: HTML, PDF y Excel"),
  ("escritorio", "Escritorio"),
  ("cli-mas-alla-de-argparse", "CLI más allá de argparse"),
  ("rich-e-interaccion", "rich e interacción en terminal"),
  ("textual", "TUI completas con Textual"),
  ("veredicto", "Veredicto: prototipo o frontend")]),
 ("db", "Hablarle a cada sistema de datos", [
  ("el-db-api", "El panorama y el DB-API 2.0"),
  ("mysql-y-mariadb", "MySQL y MariaDB"),
  ("sql-server-y-oracle", "SQL Server y Oracle"),
  ("sqlite-a-fondo", "SQLite a fondo"),
  ("duckdb", "DuckDB"),
  ("valkey", "Clave-valor: Valkey"),
  ("mongodb", "Documental: MongoDB"),
  ("cassandra", "Columnar ancho: Cassandra y ScyllaDB"),
  ("neo4j", "Grafo: Neo4j"),
  ("series-de-tiempo", "Series de tiempo: TimescaleDB e InfluxDB"),
  ("vectorial", "Vectorial: pgvector y Qdrant"),
  ("busqueda", "Búsqueda: OpenSearch y Meilisearch"),
  ("objetos-s3", "Objetos: S3 y MinIO"),
  ("bitacora-de-eventos", "Bitácora de eventos: Kafka y NATS"),
  ("veredicto", "Veredicto: el árbol de decisión")]),
 ("jv", "Convivir con tu stack Java", [
  ("los-formatos-de-la-jvm", "Los formatos que la JVM ya produce"),
  ("jpype-y-py4j", "JPype y Py4J"),
  ("graalpy-y-jython", "GraalPy y Jython"),
  ("la-arquitectura-mixta", "La arquitectura mixta: dónde poner la frontera")]),
 ("so", "Optimización, simulación y decisiones", [
  ("describir-en-vez-de-programar", "Describir el problema en vez de programarlo"),
  ("programacion-lineal", "Programación lineal y entera"),
  ("or-tools", "OR-Tools y CP-SAT"),
  ("rutas-y-grafos", "Rutas y grafos"),
  ("simulacion-con-simpy", "Simulación de eventos discretos"),
  ("cuando-no-hay-modelo", "Cuando no hay modelo"),
  ("veredicto", "Veredicto: cuándo paga y cuándo bastaba la hoja")]),
 ("or", "ORMs y acceso a datos", [
  ("el-eje", "El eje: mapeo, constructor, SQL"),
  ("sqlalchemy-a-fondo", "SQLAlchemy a fondo"),
  ("active-record", "Active Record: Django ORM, Peewee, Piccolo"),
  ("pony", "Pony ORM: generadores a SQL"),
  ("los-asincronos", "Los ORM asíncronos"),
  ("sin-orm", "Sin ORM"),
  ("migraciones", "Migraciones fuera de Alembic"),
  ("veredicto", "Veredicto: la misma consulta en seis bibliotecas")]),
 ("vz", "Visualización y gráficos", [
  ("el-modelo-y-matplotlib", "El modelo y Matplotlib"),
  ("la-gramatica", "La gramática: Altair, plotnine, Great Tables"),
  ("graficos-que-no-son-datos", "Gráficos que no son datos"),
  ("el-grafico-que-miente", "Veredicto: el gráfico que miente")]),
 ("sy", "El sistema operativo y los procesos", [
  ("subprocess-a-fondo", "subprocess a fondo"),
  ("las-envolturas", "Las envolturas: plumbum, sh, invoke"),
  ("inspeccion-del-sistema", "Inspección del sistema"),
  ("el-sistema-de-archivos", "El sistema de archivos en serio"),
  ("reaccionar-a-cambios", "Reaccionar a cambios"),
  ("convivir-con-el-sistema", "Convivir con systemd"),
  ("sincronizacion-y-respaldo", "Sincronización y respaldo"),
  ("veredicto", "Veredicto: dónde deja de servir el script de shell")]),
 ("pr", "Protocolos y contratos más allá de REST", [
  ("el-eje", "El eje: contrato implícito, esquema, IDL"),
  ("grpc-y-protobuf", "gRPC y Protobuf"),
  ("formatos-binarios", "Los formatos binarios"),
  ("graphql", "GraphQL desde Python"),
  ("tiempo-real", "Tiempo real: WebSocket y SSE"),
  ("mensajeria-como-contrato", "Mensajería como contrato"),
  ("versionado-de-contratos", "Versionado y pruebas de contratos"),
  ("veredicto", "Veredicto: REST y las tres excepciones")]),
 ("pk", "El panorama de gestores y empaquetado", [
  ("el-modelo-real", "El modelo real de un entorno"),
  ("pip-venv-y-pip-tools", "pip, venv y pip-tools"),
  ("uv", "uv"),
  ("conda-y-compania", "conda, mamba y Miniforge"),
  ("poetry-y-pdm", "Poetry y PDM"),
  ("empaquetar-y-publicar", "Empaquetar y publicar"),
  ("entregar-a-quien-no-es-ingeniero", "Entregar a quien no es ingeniero"),
  ("veredicto", "Veredicto: uno, quince o una plataforma")]),
 ("ff", "La frontera nativa", [
  ("el-modelo", "El modelo: GIL y módulos de extensión"),
  ("ctypes-y-cffi", "ctypes y cffi"),
  ("cython", "Cython"),
  ("numba", "numba"),
  ("rust-y-cpp", "PyO3, pybind11 y nanobind"),
  ("el-buffer-compartido", "El buffer compartido y la copia cero"),
  ("paralelismo-real", "Paralelismo real: subintérpretes y sin GIL"),
  ("veredicto", "Veredicto: la misma función en cuatro fronteras")]),
 ("ar", "Archivos y multimedia", [
  ("binario-de-verdad", "Binario de verdad"),
  ("pillow", "Pillow"),
  ("opencv-y-svg", "OpenCV, scikit-image y SVG"),
  ("pdf", "PDF"),
  ("office", "Office: Word, Excel y PowerPoint"),
  ("markdown-html-y-pandoc", "Markdown, HTML y pandoc"),
  ("latex-y-typst", "LaTeX y Typst"),
  ("video", "Vídeo"),
  ("audio", "Audio"),
  ("veredicto", "Veredicto: el pegamento contra el binario")]),
 ("gi", "Geoespacial", [
  ("el-modelo", "El modelo: geometría, proyección, topología"),
  ("vectorial", "Vectorial: shapely, geopandas, pyproj"),
  ("postgis", "PostGIS desde Python"),
  ("raster", "Ráster y teledetección"),
  ("rutas-y-direcciones", "Rutas y direcciones"),
  ("mapas-como-entregable", "Mapas como entregable"),
  ("veredicto", "Veredicto: cuándo basta con lat y lon")]),
 ("cv", "Visión por computador", [
  ("el-modelo", "El modelo: píxeles, características, red"),
  ("deteccion", "Detección"),
  ("puntos-faciales", "Puntos de referencia faciales"),
  ("morphing", "Morphing desde cero"),
  ("reconocimiento", "Reconocimiento e identidad"),
  ("segmentacion-y-edicion", "Segmentación y edición"),
  ("video-con-modelos", "Vídeo con modelos"),
  ("veredicto", "Veredicto ético y legal")]),
 ("ed", "Didáctica, divulgación y juguetes", [
  ("turtle", "turtle"),
  ("juegos", "Juegos como vehículo"),
  ("notebooks-para-explicar", "Notebooks para explicar"),
  ("visualizar-algoritmos", "Visualizar algoritmos"),
  ("veredicto", "Veredicto: cuándo simplificar ayuda y cuándo miente")]),
]

def numerar():
    n = 0
    for tt, nombre, secs in CARTA:
        for i, (slug, titulo) in enumerate(secs, 1):
            n += 1
            yield n, tt, nombre, i, len(secs), slug, titulo, f"op{n:03d}-{tt}{i:02d}-{slug}.md"

if __name__ == "__main__":
    filas = list(numerar())
    print(len(filas))
EOF
cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516; python3 carta.py

# --- 2026-10-05T15:43:56 · Generate the carta production plan
cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516; python3 - <<'EOF'
from carta import CARTA, numerar
filas = list(numerar())
P = "/Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs/prompts/plan-de-produccion-carta.md"
tandas = []
n = 0
for k, (tt, nombre, secs) in enumerate(CARTA, 1):
    a, b = n + 1, n + len(secs); n = b
    tandas.append((f"T{k}", tt, nombre, len(secs), a, b))
out = []
w = out.append
w("""# 🗓️ Plan de producción de la carta

> Curso *Python para desarrolladores Java senior* · **material a la carta** (`opNNN-<tt>NN-<slug>.md`).
> Nace el 05/10/2026, cuando el autor pidió escribir la carta entera, encadenada. Es operativo:
> **cualquier sesión que retome la carta empieza leyendo §3 (estado), §6 (deuda), §7 (bitácora) y
> §8 (checklist).** No se cita desde ningún documento publicado.
>
> - El qué y el orden de los tracks: [`propuestas-temas-opcionales.md`](propuestas-temas-opcionales.md) §3–§19.
> - La forma y las excepciones: [`guia-de-estilo-y-convenciones.md`](guia-de-estilo-y-convenciones.md) §14.
> - El esqueleto: [`plantillas-de-capitulo.md`](plantillas-de-capitulo.md), *Plantilla de sección de la carta*.
> - Las versiones: [`inventario-verificado.md`](inventario-verificado.md), que genera `check-inventario.py`.
> - **El orden y la numeración los manda este documento.**
>
> **Vigencia:** 2026-10-05.

**Salto rápido:** [1](#1--las-reglas-de-orden) · [2](#2--qué-es-una-tanda) · [3](#3--estado) · [4](#4--las-verificaciones) · [5](#5--la-numeración-completa) · [6](#6--deuda-de-enlaces-abierta) · [7](#7--bitácora) · [8](#8--checklist-final) · [9](#9--directorios-de-zz-code)

---

## 1. 🧭 Las reglas de orden

Son **176 secciones en 22 tracks**, después de aplicar las fusiones y mudanzas de la propuesta
(guía §14.3). Se escriben **un track por tanda**, en el orden de la propuesta §19: primero los
once con encargo en Áurea, después los seis del segundo turno y al final los cinco del tercero.

1. **El número `opNNN` es el orden de escritura** (propuesta §2), y está asignado de antemano en §5
   porque la escritura es secuencial y el orden de las tandas está fijo. Si una tanda se salta o se
   reordena, se renumera **antes** de escribir el primer archivo afectado, nunca después.
2. **Ningún enlace apunta a una sección que todavía no existe.** Una sección enlaza fases del
   camino base y secciones anteriores de la carta; lo que querría enlazar hacia adelante va en
   prosa y a §6.
3. **El `README.md` y el `0-ESTRUCTURA-CURSO.md` del curso solo se tocan en T23**, que agrega la
   carta a los dos.
4. **Nada se nombra sin comprobarlo**: versiones desde `inventario-verificado.md`; URL por código
   de estado al cerrar cada tanda.
5. **El código se escribe por inspección** (decisión del autor, guía §14.1). La casilla *corrida*
   de §5 queda ⬜ en todas, y la deuda de ejecución la paga T24.
6. **Encadenado** (pedido del autor): al cerrar una tanda se abre la siguiente sin esperar, pero
   cada una se cierra completa —verificador, URL, §3, §7 y §8— antes de abrir la otra.
7. **Secuencial y sin agentes. Git lo hace el autor**: los tags de cada sección quedan escritos en
   la propia sección y en la bitácora.
8. **El código intermedio va a `zz-code/`**, registrado en §9; nada en el scratchpad.

```mermaid
flowchart LR
    P["P1–P3<br/>preparación"] --> T1["T1–T11<br/>primer turno"]
    T1 --> T12["T12–T17<br/>segundo turno"]
    T12 --> T18["T18–T22<br/>tercer turno"]
    T18 --> T23["T23<br/>README y estructura"]
    T23 --> T24["T24<br/>verificación: ejecutar"]
```

---

## 2. 📦 Qué es una tanda

**Una tanda de escritura es un track entero.** La rutina, igual en todas:

1. Releer la ficha del track en la propuesta y su fila en §19; lo que dice es el piso.
2. Comprobar en `inventario-verificado.md` cada paquete que se va a nombrar; si falta uno, se
   agrega a `check-inventario.py` y se regenera el track (`python3 prompts/check-inventario.py <tt>`).
3. Escribir las secciones en orden, con el checklist de la guía §14.4 al cerrar cada una.
4. Correr §4.
5. Actualizar §3, §5 (casilla *escrita*), §6, §7 y §8.

---

## 3. 📊 Estado

Leyenda: ⬜ pendiente · 🟡 en curso · ✅ terminada y verificada.

| Tanda | Entrega | Secciones | Números | Estado |
|---|---|---|---|---|
| **P1** | Decisiones del autor y por defecto, guía §14, plantilla de sección | — | — | ✅ |
| **P2** | `check-inventario.py` e `inventario-verificado.md` (373 paquetes) | — | — | ✅ |
| **P3** | Verificador del curso: `verificador_base.py` + `verificar-corpus.py` | — | — | ⬜ |""")
for t, tt, nombre, cnt, a, b in tandas:
    w(f"| **{t}** | `{tt}` — {nombre} | {cnt} | op{a:03d}–op{b:03d} | ⬜ |")
w("""| **T23** | La carta en el `README.md` y en `0-ESTRUCTURA-CURSO.md` | — | — | ⬜ |
| **T24** | Verificación: ejecutar el código de la carta, crear `src/opNNN-…/` y quitar los rótulos | — | — | ⬜ |

> 🚦 **Dónde está la producción (05/10/2026).** Preparación en curso; sigue P3 y después T1 (`lg`).

---

## 4. 🔍 Las verificaciones

Desde la raíz del curso, al cerrar cada tanda:

```bash
python3 prompts/verificar-corpus.py                 # enlaces, anclas, restos, callouts, carta
python3 prompts/check-inventario.py <tt>             # si la tanda agregó paquetes
grep -rl "Ã\\|â€" --include='*.md' .                 # codificación sana: vacío
```

Y las URL de las secciones nuevas, por código de estado (el conductor vive en el directorio de
`zz-code/` de la sesión, §9): 200 vale; 3xx se sigue y se mira el destino; 4xx, 5xx o la portada
de la documentación cuentan como rotas y se corrigen antes de cerrar.

---

## 5. 🔢 La numeración completa

El nombre de archivo es exacto; el título puede ajustarse al escribir sin cambiar el archivo.

| Número | Archivo | Título | Escrita | Corrida |
|---|---|---|---|---|""")
for n, tt, nombre, i, m, slug, titulo, f in filas:
    w(f"| op{n:03d} | `{f}` | {titulo} | ⬜ | ⬜ |")
w("""
---

## 6. 🧾 Deuda de enlaces abierta

| Origen | Destino pendiente | La cierra |
|---|---|---|
| — | — | — |

---

## 7. 📓 Bitácora

**2026-10-05 · P1 y P2 cerradas.** Pedido del autor: *"termina el material a la carta"*, con
**toda la carta encadenada**, **forma ligera (~400 líneas)** y **código por inspección**.
Decisiones por defecto, a revisar (guía §14.2–§14.3): criterio verificable en vez de solución
publicada; código en la sección y `src/` en T24; Mermaid; reparto `qa`/`ob`; camino (a) en `cv`.
`check-inventario.py` verificó 373 paquetes contra PyPI: 41 quietos (💤) y uno que no existe con
ese nombre (`graalpy`, que no se distribuye por PyPI). **Trampa para la próxima sesión:** el
inventario ya avanzó respecto del camino base —SQLAlchemy está en 2.1.3 y el camino base fija
2.0.x—; la carta cita la versión del inventario y dice cuándo difiere de la del camino base.
**`zz-code/`:** `python-for-java-devs-20261005-f516` creado. **Siguiente:** P3.

---

## 8. ✅ Checklist final

- [x] Guía §14 y plantilla de sección escritas
- [x] `inventario-verificado.md` generado
- [ ] Verificador del curso copiado y ajustado a la carta
- [ ] Las 176 secciones escritas (§5, casilla *escrita*)
- [ ] URL de todas las secciones verificadas
- [ ] La carta en el `README.md` y en `0-ESTRUCTURA-CURSO.md` (T23)
- [ ] El código ejecutado y `src/opNNN-…/` creado (T24, casilla *corrida*)
- [ ] `zz-code/` sin directorios *vigentes* y `limpiar.py` en vista previa

---

## 9. 🧪 Directorios de `zz-code/`

| Directorio | Tanda | Propósito | Estado |
|---|---|---|---|
| `python-for-java-devs-20261005-f516` | P1– | La lista de la carta (`carta.py`), el conductor de URL y las salidas de los verificadores | vigente |
""")
open(P, "w", encoding="utf-8").write("\n".join(out))
print("ok", len(out))
EOF

# --- 2026-10-05T15:44:03 · Inspect headers and run base verifier on python
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs; sed -n 1,8p 05-shell-con-esteroides.md; sed -n 1,8p ds04-embudo.md; grep -n "^## " 05-shell-con-esteroides.md | head -14; ls prompts/*.py; cp ../../../zz-instrucciones/herramientas/verificador_base.py prompts/; python3 -B ../../../zz-instrucciones/herramientas/verificador_base.py . --perfil=courses-ia | tail -1; python3 -B ../../../zz-instrucciones/herramientas/verificador_base.py . --perfil=courses-ia | grep -v "^aviso EMOJI" | head -20

# --- 2026-10-05T15:44:07 · Copy base verifier and run it on python course
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs; R=/Users/oskar/Developer/Learning/courses-ia-generated; cp $R/zz-instrucciones/herramientas/verificador_base.py prompts/; python3 -B $R/zz-instrucciones/herramientas/verificador_base.py . --perfil=courses-ia > $R/zz-code/python-for-java-devs-20261005-f516/salidas/antes.log; tail -1 $R/zz-code/python-for-java-devs-20261005-f516/salidas/antes.log; grep -v "^aviso EMOJI" $R/zz-code/python-for-java-devs-20261005-f516/salidas/antes.log | awk '{print $1,$2}' | sort | uniq -c; grep "^ERROR" $R/zz-code/python-for-java-devs-20261005-f516/salidas/antes.log | head

# --- 2026-10-05T15:44:41 · Run python course verifier
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs; python3 -B prompts/verificar-corpus.py | tail -1; python3 -B prompts/verificar-corpus.py | grep -v "EMOJI" | head

# --- 2026-10-05T15:44:53 · Write URL checker and smoke-test it
cat > /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516/verificar_urls.py <<'EOF'
"""Verifica por código de estado las URL de los .md que se le pasan (guía §14.3).

Uso: python3 verificar_urls.py <archivo.md>...
Imprime una línea por URL que no responde 200 (después de seguir redirecciones), con el destino
final cuando cambió de dominio o cayó en una portada. Sin dependencias.
"""
import re, sys, urllib.request, urllib.error, urllib.parse, concurrent.futures as cf

URL_RE = re.compile(r"https?://[^\s<>()`\"'\]]+")
CABECERAS = {"User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 14_0) verificador-curso/1.0"}

def limpiar(u):
    return u.rstrip(".,;:*_")

def consultar(url):
    for metodo in ("HEAD", "GET"):
        try:
            req = urllib.request.Request(url, method=metodo, headers=CABECERAS)
            with urllib.request.urlopen(req, timeout=25) as r:
                return r.status, r.geturl()
        except urllib.error.HTTPError as e:
            if metodo == "HEAD" and e.code in (403, 405, 400, 404, 429, 501):
                continue
            return e.code, url
        except Exception as e:  # red, TLS, tiempo
            if metodo == "HEAD":
                continue
            return f"ERR {type(e).__name__}", url
    return "?", url

def main(archivos):
    urls = {}
    for f in archivos:
        for u in URL_RE.findall(open(f, encoding="utf-8").read()):
            u = limpiar(u)
            if "localhost" in u or "127.0.0.1" in u or "example." in u:
                continue
            urls.setdefault(u, f)
    malas = 0
    with cf.ThreadPoolExecutor(8) as ex:
        for (u, f), (st, final) in zip(urls.items(), ex.map(consultar, urls)):
            portada = urllib.parse.urlparse(final).path in ("", "/") and urllib.parse.urlparse(u).path not in ("", "/")
            if st != 200 or portada:
                malas += 1
                print(f"{st}\t{f}\t{u}" + (f"\t→ {final}" if final != u else ""))
    print(f"— {len(urls)} URL, {malas} a revisar")

if __name__ == "__main__":
    main(sys.argv[1:])
EOF
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs; python3 ../../../zz-code/python-for-java-devs-20261005-f516/verificar_urls.py ds04-embudo.md | tail -5

# --- 2026-10-05T15:44:57 · Smoke-test URL checker on existing sections
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs; python3 ../../zz-code/python-for-java-devs-20261005-f516/verificar_urls.py ds04-embudo.md ia01-el-modelo-de-acceso-de-un-llm.md | tail -6

# --- 2026-10-05T15:45:05 · Mark P3 done and show lg versions
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs; python3 - <<'EOF'
p='prompts/plan-de-produccion-carta.md'; t=open(p,encoding='utf-8').read()
t=t.replace("| **P3** | Verificador del curso: `verificador_base.py` + `verificar-corpus.py` | — | — | ⬜ |","| **P3** | Verificador del curso: `verificador_base.py` + `verificar-corpus.py` | — | — | ✅ |")
t=t.replace("| **T1** | `lg`","| **T1** | `lg`").replace("- [ ] Verificador del curso copiado y ajustado a la carta","- [x] Verificador del curso copiado y ajustado a la carta")
t=t.replace("Preparación en curso; sigue P3 y después T1 (`lg`).","Preparación cerrada (P1–P3); T1 (`lg`) en curso.")
open(p,'w',encoding='utf-8').write(t)
EOF
sed -n '/^## `lg`/,/^## `au`/p' prompts/inventario-verificado.md

# --- 2026-10-05T15:45:12 · Find insurer and format facts in the story
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs; grep -n -i "asegurador\|prepagad\|RIPS\|DIAN\|glosa\|FTP\|portal\|EPS" 00-historia-de-aurea.md | head -40

# --- 2026-10-05T15:45:15 · Read aur and Cartera project details
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs; sed -n 376,415p 00-historia-de-aurea.md; sed -n 502,546p 00-historia-de-aurea.md; ls src | head -30; grep -n "struct\|EBCDIC\|ancho fijo" 05-shell-con-esteroides.md 06-formatos-en-la-caja.md | head

# --- 2026-10-05T15:45:19 · Outline base phases 06 and 13
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs; grep -n "^## \|^### " 06-formatos-en-la-caja.md 13-integraciones.md | head -50; grep -n -i "xml\|ElementTree\|defused\|xxe" 06-formatos-en-la-caja.md | head -12

# --- 2026-10-05T15:47:04 · Fix lg01 details and run verifiers
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs; python3 - <<'EOF'
p='op001-lg01-ancho-fijo-y-mainframe.md'; t=open(p,encoding='utf-8').read()
t=t.replace('''servidor ya lo convirtió de EBCDIC a ASCII **y de paso destrozó los campos empaquetados**, porque
los bytes `0x0D` y `0x25` son saltos de línea en un juego de caracteres y dígitos en el otro. El''','''servidor ya lo convirtió de EBCDIC a ASCII **y de paso destrozó los campos empaquetados**: trató
cada byte como un carácter, y en un campo empaquetado `0x25` no es un salto de línea EBCDIC sino
los dígitos 2 y 5. El''')
t=t.replace('from __future__ import annotations\n\nimport datetime as dt','import datetime as dt')
t=t.replace('from pathlib import Path\nfrom typing import Iterator\n','from collections.abc import Iterator\nfrom pathlib import Path\n')
open(p,'w',encoding='utf-8').write(t)
EOF
grep -n "collections.abc\|0x25" op001-lg01-ancho-fijo-y-mainframe.md; python3 -B prompts/verificar-corpus.py | grep -v EMOJI | tail -5; python3 ../../zz-code/python-for-java-devs-20261005-f516/verificar_urls.py op001-*.md; wc -l op001-*.md

# --- 2026-10-05T15:48:37 · Verify NIT check digit and run checks
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs; python3 -c "
w=(3,7,13,17,19,23,29,37,41,43,47,53,59,67,71)
def dv(n):
  t=sum(int(d)*x for d,x in zip(reversed(n),w)); r=t%11; return r if r in (0,1) else 11-r
print(dv('900123456'))"; sed -i '' 's/<cbc:CompanyID schemeID="7">900123456/<cbc:CompanyID schemeID="8">900123456/' op002-lg02-xml-en-serio.md; grep -c 'schemeID="8"' op002-lg02-xml-en-serio.md; python3 -B prompts/verificar-corpus.py | grep -v "EMOJI\|BENCHMARKS" | tail -3; python3 ../../zz-code/python-for-java-devs-20261005-f516/verificar_urls.py op002-*.md

# --- 2026-10-05T15:49:56 · Check lg03 URLs and verifier
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs; python3 ../../zz-code/python-for-java-devs-20261005-f516/verificar_urls.py op003-*.md; python3 -B prompts/verificar-corpus.py | grep -v "EMOJI\|BENCHMARKS" | tail -3

# --- 2026-10-05T15:50:08 · Check extra package names on PyPI
for p in xsdata python-pkcs11 bots-edi bots pydifact fhir.resources hl7 hl7apy python-hl7; do printf "%-16s " $p; curl -s https://pypi.org/pypi/$p/json | python3 -c "import json,sys
try:
 d=json.load(sys.stdin);v=d['info']['version'];print(v, (d['releases'][v] or [{'upload_time':'?'}])[0]['upload_time'][:10])
except Exception: print('NO EXISTE')"; done

# --- 2026-10-05T15:50:17 · Add new lg packages to inventory list
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs; python3 - <<'EOF'
p='prompts/check-inventario.py'; t=open(p,encoding='utf-8').read()
t=t.replace('"defusedxml", "ebcdic"],','"defusedxml", "ebcdic", "xsdata", "python-pkcs11", "pydifact", "bots"],')
open(p,'w',encoding='utf-8').write(t)
EOF
grep -n '"bots"' prompts/check-inventario.py

# --- 2026-10-05T15:50:26 · Build and measure an X12 ISA segment
python3 - <<'EOF'
isa = "ISA*00*" + " "*10 + "*00*" + " "*10 + "*ZZ*" + "AUREA".ljust(15) + "*ZZ*" + "ASEGURADORA".ljust(15) + "*260928*1200*^*00501*000000905*0*T*:~"
print(len(isa)); print(isa); print(repr(isa[3]), repr(isa[104]), repr(isa[105]), repr(isa[82]))
EOF

# --- 2026-10-05T15:51:49 · Fix escape bug and smoke-test the tokenizer
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs; python3 - <<'EOF'
p='op004-lg04-edi.md'; t=open(p,encoding='utf-8').read()
old='''def split_escaped(text: str, separator: str, release: str | None) -> list[str]:
    """Corta por el separador respetando el carácter de escape de EDIFACT."""
    if not release:
        return text.split(separator)
    parts, current, escaped = [], [], False
    for char in text:
        if escaped:
            current.append(char)
            escaped = False'''
new='''def split_escaped(text: str, separator: str, release: str | None,
                  unescape: bool = False) -> list[str]:
    """Corta por el separador respetando el carácter de escape de EDIFACT.

    En los niveles de segmento y de elemento el escape se conserva (`?+` sigue siendo `?+`),
    porque el nivel siguiente todavía tiene que saber que ese `+` no separa nada. Solo el último
    nivel, el de componentes, lo quita.
    """
    if not release:
        return text.split(separator)
    parts, current, escaped = [], [], False
    for char in text:
        if escaped:
            current.append(char if unescape else release + char)
            escaped = False'''
assert old in t; t=t.replace(old,new)
old2='''        result.append([split_escaped(e, delims.component, delims.release) for e in elements])'''
new2='''        result.append([split_escaped(e, delims.component, delims.release, unescape=True)
                       for e in elements])'''
assert old2 in t; t=t.replace(old2,new2)
t=t.replace('''- **El tokenizador no valida.**''','''- **El escape se quita al final.** Si el nivel de segmentos lo quitara, el `+` protegido de la
  observación volvería a ser un separador al cortar los elementos. Es el error que cometí en el
  primer borrador de este archivo, y el que cometen casi todos los tokenizadores caseros.
- **El tokenizador no valida.**''')
open(p,'w',encoding='utf-8').write(t)
EOF
mkdir -p ../../zz-code/python-for-java-devs-20261005-f516/salidas/lg04; python3 - <<'EOF'
import re
t=open('op004-lg04-edi.md',encoding='utf-8').read()
code=re.search(r"```python\n(\"\"\"Tokenizador.*?)```",t,re.S).group(1)
open('../../zz-code/python-for-java-devs-20261005-f516/salidas/lg04/edi.py','w').write(code)
EOF
echo "(prueba de humo del tokenizador, fuera del curso)"; python3 ../../zz-code/python-for-java-devs-20261005-f516/salidas/lg04/edi.py

# --- 2026-10-05T15:52:00 · Record initial Docker inventory
Z=/Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516/salidas; { date; docker ps -a --format '{{.Names}}\t{{.Image}}\t{{.Status}}'; echo ---; docker volume ls -q; echo ---; docker images --format '{{.Repository}}:{{.Tag}}' | grep -i python; } > $Z/docker-inventario-inicial.log 2>&1; wc -l $Z/docker-inventario-inicial.log; grep -i python $Z/docker-inventario-inicial.log | head

# --- 2026-10-05T15:52:09 · Smoke-test lg01 in a python container
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs; S=/Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516/salidas; mkdir -p $S/lg01; python3 - <<'EOF'
import re
t=open('op001-lg01-ancho-fijo-y-mainframe.md',encoding='utf-8').read()
code=re.search(r"```python\n(\"\"\"Lee el archivo de glosas.*?)```",t,re.S).group(1)
open('/Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516/salidas/lg01/glosas_mainframe.py','w').write(code)
EOF
docker run --rm --label curso=python-for-java-devs -v $S/lg01:/w -w /w python:3.14.7 python glosas_mainframe.py

# --- 2026-10-05T15:53:40 · Smoke-test lg05 in container with deps
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs; S=/Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516/salidas; mkdir -p $S/lg05; python3 - <<'EOF'
import re
t=open('op005-lg05-hl7-y-fhir.md',encoding='utf-8').read()
code=re.search(r"```python\n(\"\"\"Lee el aviso.*?)```",t,re.S).group(1)
open('/Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516/salidas/lg05/radiologia.py','w').write(code)
EOF
docker run --rm --label curso=python-for-java-devs -v $S/lg05:/w -w /w python:3.14.7 sh -c "pip install -q hl7==0.4.5 fhir.resources==8.3.0 2>&1 | tail -1; python radiologia.py" 2>&1 | tail -40

# --- 2026-10-05T15:54:02 · Fix timezone in lg05 and rerun smoke test
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs; python3 - <<'EOF'
p='op005-lg05-hl7-y-fhir.md'; t=open(p,encoding='utf-8').read()
rep=[
('''import datetime as dt

import hl7''','''import datetime as dt
from zoneinfo import ZoneInfo

import hl7'''),
('''MESSAGE = "\\r".join([''','''# HL7 v2 casi nunca manda la zona horaria: la hora es la local del emisor, y hay que saber cuál es.
SENDER_ZONE = ZoneInfo("America/Bogota")

MESSAGE = "\\r".join(['''),
('''def parse_hl7_timestamp(value: str) -> dt.datetime:
    # HL7 v2 permite precisión variable: AAAA, AAAAMM, AAAAMMDD, AAAAMMDDHHMM…
    formats = {4: "%Y", 6: "%Y%m", 8: "%Y%m%d", 12: "%Y%m%d%H%M", 14: "%Y%m%d%H%M%S"}
    digits = value.split("+")[0].split("-")[0]
    return dt.datetime.strptime(digits, formats[len(digits)])''','''def parse_hl7_timestamp(value: str) -> dt.datetime:
    # HL7 v2 permite precisión variable (AAAA, AAAAMM, AAAAMMDD, AAAAMMDDHHMM…) y un desplazamiento
    # opcional al final, que casi nadie manda. Si no viene, la hora es la del emisor.
    formats = {4: "%Y", 6: "%Y%m", 8: "%Y%m%d", 12: "%Y%m%d%H%M", 14: "%Y%m%d%H%M%S"}
    digits = value.split("+")[0].split("-")[0]
    naive = dt.datetime.strptime(digits, formats[len(digits)])
    return naive.replace(tzinfo=SENDER_ZONE)'''),
('''  "effectiveDateTime": "2026-09-28T09:30:00",''','''  "effectiveDateTime": "2026-09-28T09:30:00-05:00",'''),
('''**Mezclar R4 y R5.**''','''**La hora sin zona.** FHIR exige desplazamiento en un `dateTime` que trae hora, y HL7 v2 casi
nunca lo manda. Sin el `replace(tzinfo=…)` del ejemplo, `model_validate` rechaza
`2026-09-28T09:30:00` con *"DateTime value string does not match spec regex"*, que no menciona la
zona. Esta sección lo descubrió así, en su prueba de humo: el desplazamiento se decide con el
emisor, por escrito, y no se adivina.

**Mezclar R4 y R5.**'''),
]
for a,b in rep:
    assert a in t,(a[:40]); t=t.replace(a,b)
open(p,'w',encoding='utf-8').write(t)
EOF
S=/Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516/salidas; python3 - <<'EOF'
import re
t=open('op005-lg05-hl7-y-fhir.md',encoding='utf-8').read()
code=re.search(r"```python\n(\"\"\"Lee el aviso.*?)```",t,re.S).group(1)
open('/Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516/salidas/lg05/radiologia.py','w').write(code)
EOF
docker run --rm --label curso=python-for-java-devs -v $S/lg05:/w -w /w python:3.14.7 sh -c "pip install -q --root-user-action=ignore hl7==0.4.5 fhir.resources==8.3.0 >/dev/null 2>&1; python radiologia.py" 2>&1 | tail -40

# --- 2026-10-05T15:54:23 · Smoke-test lg03 and lg04 in containers
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs; S=/Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516/salidas; mkdir -p $S/lg03; python3 - <<'EOF'
import re
B='/Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516/salidas/'
t=open('op003-lg03-documentos-firmados.md',encoding='utf-8').read()
open(B+'lg03/firmar.py','w').write(re.search(r"```python\n(\"\"\"Firma y verifica.*?)```",t,re.S).group(1))
t2=open('op002-lg02-xml-en-serio.md',encoding='utf-8').read()
open(B+'lg03/factura.xml','w').write(re.search(r"`factura.xml`:\n\n```xml\n(.*?)```",t2,re.S).group(1))
EOF
docker run --rm --label curso=python-for-java-devs -v $S/lg03:/w -w /w python:3.14.7 sh -c "pip install -q --root-user-action=ignore cryptography==50.0.2 signxml==5.1.0 lxml==6.1.3 >/dev/null 2>&1; python firmar.py" 2>&1 | tail -15; docker run --rm --label curso=python-for-java-devs -v $S/lg04:/w -w /w python:3.14.7 python edi.py

# --- 2026-10-05T15:54:37 · Smoke-test runnable parts of lg02
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs; S=/Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516/salidas; mkdir -p $S/lg02; python3 - <<'EOF'
import re
B='/Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516/salidas/lg02/'
t=open('op002-lg02-xml-en-serio.md',encoding='utf-8').read()
open(B+'factura_xml.py','w').write(re.search(r"```python\n(\"\"\"Lee, valida y transforma.*?)```",t,re.S).group(1))
open(B+'factura.xml','w').write(re.search(r"`factura.xml`:\n\n```xml\n(.*?)```",t,re.S).group(1))
bomba=re.search(r"Guarda esto como `bomba.xml`.*?```xml\n(.*?)```",t,re.S).group(1)
open(B+'bomba.xml','w').write(bomba)
open(B+'prueba.py','w').write('''from pathlib import Path
from lxml import etree
import factura_xml as f
print(f.summarize(f.load(Path("factura.xml"))))
print(len(etree.parse("bomba.xml").getroot().text or ""))
print(etree.parse("bomba.xml", f.SAFE_PARSER).getroot().text)
''')
EOF
docker run --rm --label curso=python-for-java-devs -v $S/lg02:/w -w /w python:3.14.7 sh -c "pip install -q --root-user-action=ignore lxml==6.1.3 >/dev/null 2>&1; python prueba.py" 2>&1 | tail -8

# --- 2026-10-05T15:55:02 · Formalize smoke-test rule and update headers
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs; python3 - <<'EOF'
import re
g='prompts/guia-de-estilo-y-convenciones.md'; t=open(g,encoding='utf-8').read()
old='''  rotulada **«Salida esperada, sin correr»**. La deuda de
  ejecución se lleva en el plan, y una tanda de verificación final la paga.'''
assert old in t
t=t.replace(old,'''  rotulada **«Salida esperada, sin correr»**. La deuda de
  ejecución se lleva en el plan, y una tanda de verificación final la paga.
- **Prueba de humo cuando es barata** (*por defecto, a revisar*). Si el ejemplo corre con
  dependencias de PyPI y sin servicios, la sesión lo corre en un contenedor `python:3.14.7` antes de
  cerrar la sección. Entonces el encabezado dice **«Código probado el 05/10/2026 con Python 3.14.7,
  en contenedor»** (o «probado en parte», diciendo qué), y sus salidas se rotulan **«Salida
  (Python 3.14.7, 05/10/2026)»**. En las cinco primeras secciones la prueba encontró dos errores
  reales —un dígito de verificación mal calculado y una fecha sin zona que FHIR rechaza—: por eso
  se hace aunque el autor no la exija.''')
open(g,'w',encoding='utf-8').write(t)
v='prompts/verificar-corpus.py'; t=open(v,encoding='utf-8').read()
t=t.replace('ROTULO = "Salida esperada, sin correr"','ROTULO = "Salida esperada, sin correr"\nROTULO_PROBADO = "Salida (Python 3.14.7"')
t=t.replace('''        for campo in ("Carta", f"Track `{track}`", "sin ejecutar"):
            if campo not in encabezado:
                self.error("CARTA-ENCAB", f"{nombre}: el encabezado no dice «{campo}»")''','''        for campo in ("Carta", f"Track `{track}`"):
            if campo not in encabezado:
                self.error("CARTA-ENCAB", f"{nombre}: el encabezado no dice «{campo}»")
        if "sin ejecutar" not in encabezado and "Código probado" not in encabezado:
            self.error("CARTA-ENCAB", f"{nombre}: el encabezado no dice si el código se ejecutó")''')
t=t.replace('''                if ROTULO not in "\\n".join(crudas[fin_a:ini_b]):''','''                entre = "\\n".join(crudas[fin_a:ini_b])
                if ROTULO not in entre and ROTULO_PROBADO not in entre:''')
t=t.replace("aviso CARTA-SALIDA   un bloque `text` justo después de un comando sin el rótulo de salida esperada","aviso CARTA-SALIDA   un bloque `text` justo después de un comando sin el rótulo de salida (esperada o probada)")
t=t.replace("ERROR CARTA-ENCAB    el encabezado no dice «Carta», el track y la declaración de código sin ejecutar","ERROR CARTA-ENCAB    el encabezado no dice «Carta», el track y si el código se ejecutó")
open(v,'w',encoding='utf-8').write(t)

PROB='> Versiones verificadas contra PyPI el 05/10/2026 · Código probado el 05/10/2026 con Python 3.14.7,\n> en contenedor: las salidas son las de esa corrida.'
OLD='> Versiones verificadas contra PyPI el 05/10/2026 · Código escrito sin ejecutar: las salidas\n> rotuladas «Salida esperada, sin correr» no salen de una corrida.'
for f in ['op001-lg01-ancho-fijo-y-mainframe.md','op003-lg03-documentos-firmados.md','op004-lg04-edi.md','op005-lg05-hl7-y-fhir.md']:
    t=open(f,encoding='utf-8').read(); assert OLD in t, f
    t=t.replace(OLD,PROB).replace('Salida esperada, sin correr:','Salida (Python 3.14.7, 05/10/2026):')
    open(f,'w',encoding='utf-8').write(t)
f='op002-lg02-xml-en-serio.md'; t=open(f,encoding='utf-8').read()
t=t.replace(OLD,'> Versiones verificadas contra PyPI el 05/10/2026 · Código probado en parte el 05/10/2026 con\n> Python 3.14.7, en contenedor —el resumen y la bomba—; la validación con XSD queda sin ejecutar,\n> porque sus dos esquemas importados son el ejercicio 4.')
t=t.replace('Salida esperada, sin correr:\n\n```text\n{','Salida (Python 3.14.7, 05/10/2026) del resumen; la línea `válida` es la esperada, sin correr:\n\n```text\n{')
t=t.replace('El parser de la sección no expande las entidades en absoluto: el texto queda vacío y la entidad\nqueda en el árbol como un nodo sin resolver.','En la prueba de humo, el parser por defecto devolvió 10.000 caracteres y el de la sección `None`:\nno expande las entidades en absoluto, y la entidad queda en el árbol como un nodo sin resolver.')
open(f,'w',encoding='utf-8').write(t)
EOF
grep -c "Código probado" op00*.md; python3 -B prompts/verificar-corpus.py | grep -v "EMOJI\|BENCHMARKS" | tail -4; python3 ../../zz-code/python-for-java-devs-20261005-f516/verificar_urls.py op004-*.md op005-*.md

# --- 2026-10-05T15:55:08 · Locate guide text and recheck UNECE URL
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs; grep -n "Salida esperada" prompts/guia-de-estilo-y-convenciones.md; curl -s -o /dev/null -w "%{http_code} %{url_effective}\n" -L -A "Mozilla/5.0" https://unece.org/trade/uncefact/introducing-unedifact

# --- 2026-10-05T15:55:14 · Find working EDIFACT reference URL
for u in https://service.unece.org/trade/untdid/ https://service.unece.org/trade/untdid/d96a/trmd/orders_c.htm https://en.wikipedia.org/wiki/EDIFACT; do curl -s -o /dev/null -w "%{http_code} $u\n" -A "Mozilla/5.0" $u; done; sed -n 684,690p /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs/prompts/guia-de-estilo-y-convenciones.md

# --- 2026-10-05T15:55:34 · Apply smoke-test rule, headers and URL fix
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs; python3 - <<'EOF'
g='prompts/guia-de-estilo-y-convenciones.md'; t=open(g,encoding='utf-8').read()
old='''  encabezado, y toda salida que muestre va rotulada **«Salida esperada, sin correr»**. La deuda de
  ejecución se lleva en el plan, y una tanda de verificación final la paga.'''
assert old in t
t=t.replace(old,old+'''
- **Prueba de humo cuando es barata** (*por defecto, a revisar*). Si el ejemplo corre con
  dependencias de PyPI y sin servicios, la sesión lo corre en un contenedor `python:3.14.7` antes de
  cerrar la sección. Entonces el encabezado dice **«Código probado el 05/10/2026 con Python 3.14.7,
  en contenedor»** (o «probado en parte», diciendo qué), y sus salidas se rotulan **«Salida
  (Python 3.14.7, 05/10/2026)»**. En las cinco primeras secciones la prueba encontró dos errores
  reales —un dígito de verificación mal calculado y una fecha sin zona que FHIR rechaza—: por eso
  se hace aunque el autor no la exija.''')
t=t.replace('- [ ] Toda salida rotulada «Salida esperada, sin correr»; ningún número presentado como medido.','- [ ] Toda salida rotulada («Salida esperada, sin correr» o la de la prueba de humo); ningún\n      número presentado como medido.')
open(g,'w',encoding='utf-8').write(t)
v='prompts/verificar-corpus.py'; t=open(v,encoding='utf-8').read()
t=t.replace('ROTULO = "Salida esperada, sin correr"\n','ROTULO = "Salida esperada, sin correr"\nROTULO_PROBADO = "Salida (Python 3.14.7"\n',1)
a='''        for campo in ("Carta", f"Track `{track}`", "sin ejecutar"):
            if campo not in encabezado:
                self.error("CARTA-ENCAB", f"{nombre}: el encabezado no dice «{campo}»")'''
assert a in t
t=t.replace(a,'''        for campo in ("Carta", f"Track `{track}`"):
            if campo not in encabezado:
                self.error("CARTA-ENCAB", f"{nombre}: el encabezado no dice «{campo}»")
        if "sin ejecutar" not in encabezado and "Código probado" not in encabezado:
            self.error("CARTA-ENCAB", f"{nombre}: el encabezado no dice si el código se ejecutó")''')
b='''                if ROTULO not in "\\n".join(crudas[fin_a:ini_b]):'''
assert b in t
t=t.replace(b,'''                entre = "\\n".join(crudas[fin_a:ini_b])
                if ROTULO not in entre and ROTULO_PROBADO not in entre:''')
t=t.replace("aviso CARTA-SALIDA   un bloque `text` justo después de un comando sin el rótulo de salida esperada","aviso CARTA-SALIDA   un bloque `text` justo después de un comando sin el rótulo de su salida")
t=t.replace("ERROR CARTA-ENCAB    el encabezado no dice «Carta», el track y la declaración de código sin ejecutar","ERROR CARTA-ENCAB    el encabezado no dice «Carta», el track y si el código se ejecutó")
open(v,'w',encoding='utf-8').write(t)
PROB='> Versiones verificadas contra PyPI el 05/10/2026 · Código probado el 05/10/2026 con Python 3.14.7,\n> en contenedor: las salidas son las de esa corrida.'
OLD='> Versiones verificadas contra PyPI el 05/10/2026 · Código escrito sin ejecutar: las salidas\n> rotuladas «Salida esperada, sin correr» no salen de una corrida.'
for f in ['op001-lg01-ancho-fijo-y-mainframe.md','op003-lg03-documentos-firmados.md','op004-lg04-edi.md','op005-lg05-hl7-y-fhir.md']:
    t=open(f,encoding='utf-8').read(); assert OLD in t, f
    t=t.replace(OLD,PROB).replace('Salida esperada, sin correr:','Salida (Python 3.14.7, 05/10/2026):')
    open(f,'w',encoding='utf-8').write(t)
f='op002-lg02-xml-en-serio.md'; t=open(f,encoding='utf-8').read(); assert OLD in t
t=t.replace(OLD,'> Versiones verificadas contra PyPI el 05/10/2026 · Código probado en parte el 05/10/2026 con\n> Python 3.14.7, en contenedor —el resumen y la bomba—; la validación con XSD queda sin ejecutar,\n> porque sus dos esquemas importados son el ejercicio 4.')
a='Salida esperada, sin correr:\n\n```text\n{'; assert a in t
t=t.replace(a,'Salida (Python 3.14.7, 05/10/2026) del resumen; la línea `válida` es la esperada, sin correr:\n\n```text\n{')
a='El parser de la sección no expande las entidades en absoluto: el texto queda vacío y la entidad\nqueda en el árbol como un nodo sin resolver.'; assert a in t
t=t.replace(a,'En la prueba de humo, el parser por defecto devolvió 10.000 caracteres y el de la sección `None`:\nno expande las entidades en absoluto, y la entidad queda en el árbol como un nodo sin resolver.')
open(f,'w',encoding='utf-8').write(t)
f='op004-lg04-edi.md'; t=open(f,encoding='utf-8').read()
a='''- UN/EDIFACT, los directorios de mensajes en la UNECE:
  https://unece.org/trade/uncefact/introducing-unedifact'''; assert a in t
t=t.replace(a,'''- UN/EDIFACT, panorama del estándar y de sus directorios de mensajes:
  https://en.wikipedia.org/wiki/EDIFACT (el sitio de la UNECE, que es la fuente primaria, rechaza
  a los clientes automáticos y no se pudo verificar)''')
t=t.replace("**Orden de lectura sugerido:** la introducción de la UNECE para entender la familia de mensajes;","**Orden de lectura sugerido:** el panorama de EDIFACT para entender la familia de mensajes;")
open(f,'w',encoding='utf-8').write(t)
EOF
grep -c "Código probado" op00*.md; python3 -B prompts/verificar-corpus.py | grep -v "EMOJI\|BENCHMARKS" | tail -4; python3 ../../zz-code/python-for-java-devs-20261005-f516/verificar_urls.py op004-*.md

# --- 2026-10-05T15:55:46 · Read Fase 06 encoding and csv parts
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs; sed -n 86,125p 06-formatos-en-la-caja.md; sed -n 162,194p 06-formatos-en-la-caja.md

# --- 2026-10-05T15:57:05 · Smoke-test lg06 in container
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs; S=/Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516/salidas; mkdir -p $S/lg06; python3 - <<'EOF'
import re
t=open('op006-lg06-archivos-planos-hostiles.md',encoding='utf-8').read()
open('/Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516/salidas/lg06/limpiar_plano.py','w').write(re.search(r"```python\n(\"\"\"Lee un plano hostil.*?)```",t,re.S).group(1))
EOF
docker run --rm --label curso=python-for-java-devs -v $S/lg06:/w -w /w python:3.14.7 sh -c "pip install -q --root-user-action=ignore charset-normalizer==3.5.2 ftfy==6.3.1 >/dev/null 2>&1; python limpiar_plano.py" 2>&1 | tail -12

# --- 2026-10-05T15:57:19 · Update lg06 with real smoke-test output
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs; python3 - <<'EOF'
f='op006-lg06-archivos-planos-hostiles.md'; t=open(f,encoding='utf-8').read()
rep=[
('> Versiones verificadas contra PyPI el 05/10/2026 · Código escrito sin ejecutar: las salidas\n> rotuladas «Salida esperada, sin correr» no salen de una corrida.','> Versiones verificadas contra PyPI el 05/10/2026 · Código probado el 05/10/2026 con Python 3.14.7,\n> en contenedor: las salidas son las de esa corrida.'),
('Salida esperada, sin correr:','Salida (Python 3.14.7, 05/10/2026):'),
('charset-normalizer dice: cp1252\n','charset-normalizer dice: hp_roman8\n'),
('  cuarentena línea 5: 7 columnas','  cuarentena línea 5: 8 columnas'),
('''Lee la última línea dos veces:''','''La primera línea es la que no esperaba al escribir esta sección: sobre el archivo mezclado, el
detector eligió **`hp_roman8`**, un juego de caracteres de impresoras HP de los años ochenta. No es
un fallo de la biblioteca: no existe un encoding único que explique bytes UTF-8 y Windows-1252 a la
vez, y el detector devuelve el que menos se equivoca. Por eso su opinión va al informe y no a la
decisión. Y la fila rota tiene **ocho** columnas, no siete: la nota traía su propio punto y coma.

Lee la última línea dos veces:'''),
]
for a,b in rep:
    assert a in t,a[:50]; t=t.replace(a,b)
open(f,'w',encoding='utf-8').write(t)
EOF
python3 -B prompts/verificar-corpus.py | grep -v "EMOJI\|BENCHMARKS" | tail -3; python3 ../../zz-code/python-for-java-devs-20261005-f516/verificar_urls.py op006-*.md

# --- 2026-10-05T15:58:27 · Smoke-test golden test mechanism in container
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs; python3 - <<'EOF'
f='op007-lg07-veredicto.md'; t=open(f,encoding='utf-8').read()
a='''import json
from decimal import Decimal'''
b='''import dataclasses
import json
from decimal import Decimal'''
assert a in t; t=t.replace(a,b)
a='''    rows = [item.__dict__ if hasattr(item, "__dict__") else
            {f: getattr(item, f) for f in item.__slots__} for item in read_fixed(path)]'''
b='''    rows = [dataclasses.asdict(item) for item in read_fixed(path)]'''
assert a in t; t=t.replace(a,b)
open(f,'w',encoding='utf-8').write(t)
EOF
S=/Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516/salidas; mkdir -p $S/lg07/tests/golden; cp $S/lg01/glosas_mainframe.py $S/lg07/; cp $S/lg01/glosas.dat $S/lg07/tests/golden/glosas-2026-09.dat; python3 - <<'EOF'
import re
B='/Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516/salidas/lg07/'
t=open('op007-lg07-veredicto.md',encoding='utf-8').read()
open(B+'tests/test_golden.py','w').write(re.search(r"```python\n(\"\"\"Pruebas doradas.*?)```",t,re.S).group(1))
open(B+'conftest.py','w').write(re.search(r"`conftest.py`:\n\n```python\n(.*?)```",t,re.S).group(1))
EOF
docker run --rm --label curso=python-for-java-devs -v $S/lg07:/w -w /w -e PYTHONPATH=/w python:3.14.7 sh -c "pip install -q --root-user-action=ignore pytest >/dev/null 2>&1; pytest -q tests/test_golden.py --update-golden 2>&1 | tail -1; pytest -q tests/test_golden.py 2>&1 | tail -1; python -c \"d=open('tests/golden/glosas-2026-09.dat','rb').read(); open('tests/golden/glosas-2026-10.dat','wb').write(d[:20]+b'@@'+d[20:]); import shutil; shutil.copy('tests/golden/glosas-2026-09.expected.json','tests/golden/glosas-2026-10.expected.json')\"; pytest -q tests/test_golden.py 2>&1 | grep FAILED"

# --- 2026-10-05T15:58:37 · Get full failure message of golden test
S=/Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516/salidas; docker run --rm --label curso=python-for-java-devs -v $S/lg07:/w -w /w -e PYTHONPATH=/w -e COLUMNS=200 python:3.14.7 sh -c "pip install -q --root-user-action=ignore pytest >/dev/null 2>&1; pytest -q -rf tests/test_golden.py 2>&1 | grep FAILED"

# --- 2026-10-05T15:58:52 · Update lg07 with real output and verify
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs; python3 - <<'EOF'
f='op007-lg07-veredicto.md'; t=open(f,encoding='utf-8').read()
rep=[
('> Versiones verificadas contra PyPI el 05/10/2026 · Código escrito sin ejecutar: las salidas\n> rotuladas «Salida esperada, sin correr» no salen de una corrida.','> Versiones verificadas contra PyPI el 05/10/2026 · Código probado el 05/10/2026 con Python 3.14.7,\n> en contenedor: las salidas son las de esa corrida.'),
('''Salida esperada, sin correr, el mes en que la aseguradora agrega dos bytes a un campo:

```text
FAILED tests/test_golden.py::test_golden[glosas-2026-10.dat] - ValueError: registro en el byte 0: registro de 85 bytes; el copybook dice 83
```''','''Salida (Python 3.14.7, 05/10/2026), con un archivo al que se le insertaron dos bytes dentro del
número de factura, que es lo que pasa el mes en que la aseguradora agranda un campo:

```text
FAILED tests/test_golden.py::test_golden[glosas-2026-10.dat] - ValueError: registro en el byte 0: time data '  202609' does not match format '%Y%m%d'
```

El error no habla del largo, y eso es lo interesante: el lector corta de a 83 bytes, así que los dos
bytes de más no cambian el tamaño de ningún registro sino **dónde cae cada campo**, y lo primero que
se nota es una fecha que empieza con dos espacios. La validación de cada campo es la que atrapa el
cambio; el largo del registro, solo, no lo habría atrapado nunca.'''),
]
for a,b in rep:
    assert a in t,a[:50]; t=t.replace(a,b)
open(f,'w',encoding='utf-8').write(t)
EOF
python3 -B prompts/verificar-corpus.py | grep -v "EMOJI\|BENCHMARKS" | tail -3; python3 ../../zz-code/python-for-java-devs-20261005-f516/verificar_urls.py op007-*.md; wc -l op00*.md | tail -1

# --- 2026-10-05T15:59:00 · Teach verifier to skip file trees
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs; python3 - <<'EOF'
v='prompts/verificar-corpus.py'; t=open(v,encoding='utf-8').read()
a='''            if lang_a in ("bash", "console") and lang_b == "text" and ini_b - fin_a <= 4:'''
b='''            arbol = ini_b + 1 < len(crudas) and crudas[ini_b + 1].rstrip().endswith("/")
            if lang_a in ("bash", "console") and lang_b == "text" and ini_b - fin_a <= 4 and not arbol:'''
assert a in t; t=t.replace(a,b); open(v,'w',encoding='utf-8').write(t)
EOF
python3 -B prompts/verificar-corpus.py | grep -v "EMOJI\|BENCHMARKS" | tail -2

# --- 2026-10-05T15:59:15 · Fix inventory script to merge per track
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs; python3 - <<'EOF'
p='prompts/check-inventario.py'; t=open(p,encoding='utf-8').read()
start=t.index('def main(tracks: list[str]) -> int:')
end=t.index('if __name__ == "__main__":')
new='''def main(tracks: list[str]) -> int:
    hoy = dt.date.today()
    elegidos = tracks or list(INVENTARIO)
    # Las secciones de los tracks que no se piden se conservan tal cual, con su fecha.
    secciones: dict[str, str] = {}
    if SALIDA.exists():
        for bloque in SALIDA.read_text(encoding="utf-8").split("\\n## `")[1:]:
            secciones[bloque.split("`", 1)[0]] = "## `" + bloque.rstrip() + "\\n"
    cache: dict[str, tuple[str, str] | None] = {}
    for track in elegidos:
        lineas = [f"## `{track}`", "", f"Verificado el {hoy.isoformat()}.", "",
                  "| Paquete | Versión | Publicada | |", "|---|---|---|---|"]
        for paquete in INVENTARIO[track]:
            if paquete not in cache:
                cache[paquete] = consultar(paquete)
                time.sleep(0.3)
            dato = cache[paquete]
            if dato is None:
                lineas.append(f"| `{paquete}` | — | — | ❌ |")
                continue
            version, fecha = dato
            quieto = fecha and hoy - dt.date.fromisoformat(fecha) > QUIETO
            lineas.append(f"| `{paquete}` | {version} | {fecha} | {'💤' if quieto else ''} |")
        secciones[track] = "\\n".join(lineas) + "\\n"
    cabecera = [
        "# 📋 Inventario verificado contra PyPI",
        "",
        "> Generado por `check-inventario.py`. No se edita a mano: se regenera, entero o por track.",
        "> Cada track lleva la fecha de su última verificación. Las secciones de la carta citan de",
        "> aquí la versión que nombran.",
        "> 💤 = más de dos años sin publicar; ❌ = no existe en PyPI con ese nombre.",
        "",
    ]
    orden = [t for t in INVENTARIO if t in secciones]
    SALIDA.write_text("\\n".join(cabecera) + "\\n".join(secciones[t] for t in orden), encoding="utf-8")
    print(f"escrito {SALIDA.name}: {len(cache)} paquetes consultados, {len(orden)} tracks")
    return 0


'''
t=t[:start]+new+t[end:]
open(p,'w',encoding='utf-8').write(t)
EOF
python3 -B prompts/check-inventario.py 2>&1 | tail -1; grep -c "^## \`" prompts/inventario-verificado.md; python3 -B prompts/check-inventario.py lg | tail -1; grep -c "^## \`" prompts/inventario-verificado.md; grep -A3 '^## `lg`' prompts/inventario-verificado.md; grep "pydifact\|bots\b\|xsdata" prompts/inventario-verificado.md

# --- 2026-10-05T16:02:55 · Write plan helper and close T1 in plan
cat > /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516/plan.py <<'EOF'
"""Marca filas del plan de la carta: python3 plan.py <desde> <hasta> <escrita> <corrida>
y tandas: python3 plan.py tanda T1 ✅   ·   bitácora: python3 plan.py bitacora 'texto'"""
import re, sys, pathlib
P = pathlib.Path("/Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs/prompts/plan-de-produccion-carta.md")
t = P.read_text(encoding="utf-8")
a = sys.argv[1:]
if a[0] == "tanda":
    t = re.sub(rf"^(\| \*\*{a[1]}\*\* \|.*\| )(⬜|🟡|✅) \|$", rf"\g<1>{a[2]} |", t, flags=re.M)
elif a[0] == "bitacora":
    t = t.replace("## 7. 📓 Bitácora\n\n", "## 7. 📓 Bitácora\n\n" + a[1].strip() + "\n\n", 1)
elif a[0] == "dondeesta":
    t = re.sub(r"> 🚦 \*\*Dónde está la producción.*?(?=\n\n)", "> 🚦 **Dónde está la producción " + a[1], t, flags=re.S)
else:
    desde, hasta, esc, cor = int(a[0]), int(a[1]), a[2], a[3]
    for n in range(desde, hasta + 1):
        t = re.sub(rf"^(\| op{n:03d} \| .*? \| .*? \| )(\S+) \| (\S+) \|$", rf"\g<1>{esc} | {cor} |", t, flags=re.M)
P.write_text(t, encoding="utf-8")
EOF
cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516; python3 plan.py 1 7 ✅ ✅; python3 plan.py 2 2 ✅ 🟡; python3 plan.py tanda T1 ✅; python3 plan.py dondeesta "(05/10/2026).** T1 (\`lg\`) cerrada; T2 (\`au\`) en curso."; python3 plan.py bitacora "**2026-10-05 · T1 (\`lg\`) cerrada.** Escritas op001–op007 (2.442 líneas, 68 ejercicios). **Pruebas de humo** en \`python:3.14.7\` (contenedor, \`--label curso=python-for-java-devs\`, \`--rm\`): seis completas y \`lg02\` en parte (su XSD importado es el ejercicio 4). **Encontraron cuatro defectos propios**, corregidos antes de cerrar: el dígito de verificación del NIT del ejemplo de \`lg02\` (7 → 8); el tokenizador de \`lg04\` consumía el escape de EDIFACT en el nivel de segmento; la fecha sin zona de \`lg05\`, que FHIR rechaza; y la salida prevista de \`lg06\` y \`lg07\`, distinta de la real (el detector dijo \`hp_roman8\`; el fallo dorado es de fecha, no de largo). **Decisión por defecto, a revisar:** prueba de humo cuando es barata, con rótulo propio (guía §14.1). **Comprobado:** URL de las siete secciones por código de estado (la de la UNECE responde 403 a clientes automáticos y se reemplazó). Inventario: +4 paquetes (\`xsdata\`, \`python-pkcs11\`, \`pydifact\`, \`bots\`); \`check-inventario.py\` ahora actualiza por track. **Trampa:** \`verificar_urls.py\` y los extractores de humo viven en \`zz-code/\`; las secciones no los citan. **Tags para el autor:** \`op-lg-fase-01\` … \`op-lg-fase-07\` (el mensaje está en cada sección). **Siguiente:** T2 (\`au\`)."; grep -n "op00[1-7] \|\*\*T1\*\*\|Dónde está" /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs/prompts/plan-de-produccion-carta.md | head -12

# --- 2026-10-05T16:03:14 · Update plan rule and save carta memory
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs; python3 - <<'EOF'
p='prompts/plan-de-produccion-carta.md'; t=open(p,encoding='utf-8').read()
a='''5. **El código se escribe por inspección** (decisión del autor, guía §14.1). La casilla *corrida*
   de §5 queda ⬜ en todas, y la deuda de ejecución la paga T24.'''
b='''5. **El código se escribe por inspección** (decisión del autor, guía §14.1), y se corre una
   **prueba de humo** en contenedor cuando es barata. En §5, *corrida* ✅ = prueba de humo completa,
   🟡 = en parte, ⬜ = sin correr (lo que necesita servicios o credenciales). T24 paga la deuda
   restante y crea `src/opNNN-…/`.'''
assert a in t; t=t.replace(a,b); open(p,'w',encoding='utf-8').write(t)
EOF
cat > /Users/oskar/.claude/projects/-Users-oskar-Developer-Learning-courses-ia-generated/memory/python-carta-produccion.md <<'EOF'
---
name: python-carta-produccion
description: Carta opcional de python-for-java-devs en producción desde el 05/10/2026 — 176 secciones opNNN en 22 tracks, encadenadas; estado en prompts/plan-de-produccion-carta.md.
metadata:
  type: project
---

El 05/10/2026 Oskar pidió **terminar el material a la carta** de `python-for-java-devs`. Eligió:
**toda la carta encadenada** (sin pausas entre tandas), **forma ligera ~400 líneas** y **código por
inspección**. Son **176 secciones en 22 tracks** (fusiones aplicadas: `cl` dentro de `ui`, `vz` a
cuatro, `au04`→`qa09`, `ed05`→`ui01`, EPUB como desafío de `ar06`), una tanda por track en el orden
de la propuesta §19, más T23 (README y 0-ESTRUCTURA) y T24 (ejecutar y crear `src/`).

Dónde está todo:
- Estado, numeración opNNN completa (casillas escrita/corrida) y bitácora:
  `prompts/plan-de-produccion-carta.md`. Empezar siempre por §3, §5, §7.
- Reglas y excepciones de la carta: guía §14 (8–12 ejercicios con `**Criterio:**`, rúbrica en 🔴,
  código en la sección y `src/` en T24, Mermaid, reparto qa/ob, camino (a) en `cv`).
- Plantilla: `plantillas-de-capitulo.md`, *Plantilla de sección de la carta*.
- Versiones: `prompts/inventario-verificado.md`, generado por `prompts/check-inventario.py` (por
  track: `python3 prompts/check-inventario.py <tt>`). Paquete nuevo → agregarlo a la lista y regenerar.
- Verificador: `prompts/verificar-corpus.py` (chequeos CARTA-*).
- `zz-code/python-for-java-devs-20261005-f516/`: `carta.py` (lista única), `plan.py` (marca filas,
  tandas y bitácora), `verificar_urls.py`, y `salidas/<tt>NN/` con las pruebas de humo.

Método que funcionó en T1: escribir la sección → prueba de humo en `python:3.14.7` con
`docker run --rm --label curso=python-for-java-devs` → si corre, encabezado «Código probado el
05/10/2026 con Python 3.14.7, en contenedor» y rótulo «Salida (Python 3.14.7, 05/10/2026)». En T1 la
prueba encontró 4 defectos propios de 7 secciones: **vale la pena aunque Oskar no la exija**.

**How to apply:** al retomar, leer el plan §3/§7 y seguir con la siguiente tanda ⬜ sin preguntar
(Oskar pidió encadenar). Ver [[python-java-devs-estado]], [[lineamientos-zz-instrucciones-y-zz-code]],
[[feedback-pruebas-en-contenedor]].
EOF
cd /Users/oskar/.claude/projects/-Users-oskar-Developer-Learning-courses-ia-generated/memory; echo '- [Carta de python-for-java-devs en producción](python-carta-produccion.md) — 176 secciones opNNN encadenadas desde el 05/10/2026; estado en prompts/plan-de-produccion-carta.md; T1 lg cerrada.' >> MEMORY.md; tail -1 MEMORY.md

# --- 2026-10-05T16:03:21 · Show au versions and Fase 13 client coverage
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs; sed -n '/^## `au`/,/^## `co`/p' prompts/inventario-verificado.md; sed -n 174,208p 13-integraciones.md; grep -n "httpx\|tenacity\|stamina" 13-integraciones.md | head -8

# --- 2026-10-05T16:04:42 · Fix token request and smoke-test au01
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs; python3 - <<'EOF'
f='op008-au01-http-contra-sistemas-ajenos.md'; t=open(f,encoding='utf-8').read()
rep=[('''import time
from collections.abc import Iterator''','''import base64
import time
from collections.abc import Iterator'''),
('''    def _token_request(self) -> httpx.Request:
        return httpx.Request("POST", self._token_url, data={"grant_type": "client_credentials"},
                             auth=self._credentials)''','''    def _token_request(self) -> httpx.Request:
        # Las credenciales van en Basic (RFC 6749 §2.3.1). httpx.Request no acepta auth=: eso es
        # del cliente, así que el encabezado se arma aquí.
        basic = base64.b64encode(":".join(self._credentials).encode()).decode()
        return httpx.Request("POST", self._token_url, data={"grant_type": "client_credentials"},
                             headers={"Authorization": f"Basic {basic}"})''')]
for a,b in rep:
    assert a in t; t=t.replace(a,b)
open(f,'w',encoding='utf-8').write(t)
EOF
S=/Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516/salidas; mkdir -p $S/au01; python3 - <<'EOF'
import re
t=open('op008-au01-http-contra-sistemas-ajenos.md',encoding='utf-8').read()
open('/Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516/salidas/au01/prepagada.py','w').write(re.search(r"```python\n(\"\"\"Cliente de la API.*?)```",t,re.S).group(1))
EOF
docker run --rm --label curso=python-for-java-devs -v $S/au01:/w -w /w python:3.14.7 sh -c "pip install -q --root-user-action=ignore httpx==0.28.1 >/dev/null 2>&1; python prepagada.py" 2>&1 | tail -12

# --- 2026-10-05T16:05:02 · Create smoke-test helpers and mark au01
Z=/Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516; cat > $Z/humo.py <<'EOF'
"""Prueba de humo de una sección de la carta, en contenedor.

Uso: python3 humo.py <seccion.md> <dir> <archivo=inicio-del-bloque>... [--pip paq==v ...] [--cmd "python x.py"]
- Cada <archivo=inicio> extrae el primer bloque de código cuyo contenido empieza con <inicio>
  (o, si <inicio> es '@archivo', el bloque que sigue a la línea "`archivo`:").
- Corre <cmd> en python:3.14.7 con --rm y la etiqueta del curso, montando salidas/<dir>.
"""
import pathlib, re, subprocess, sys

Z = pathlib.Path(__file__).parent
CARTA = pathlib.Path("/Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs")
args = sys.argv[1:]
md, d = CARTA / args[0], Z / "salidas" / args[1]
d.mkdir(parents=True, exist_ok=True)
pips, cmd, specs, mode = [], None, [], "spec"
for a in args[2:]:
    if a == "--pip": mode = "pip"; continue
    if a == "--cmd": mode = "cmd"; continue
    if mode == "pip": pips.append(a)
    elif mode == "cmd": cmd = a
    else: specs.append(a)
text = md.read_text(encoding="utf-8")
blocks = re.findall(r"(?:^|\n)(.*)\n\n?```[a-z]*\n(.*?)\n```", text, re.S)
for spec in specs:
    name, start = spec.split("=", 1)
    found = None
    for before, body in blocks:
        if start.startswith("@") and before.strip().rstrip(":").strip("`").endswith(start[1:]):
            found = body; break
        if not start.startswith("@") and body.startswith(start):
            found = body; break
    if found is None:
        sys.exit(f"no encontré el bloque para {spec}")
    (d / name).parent.mkdir(parents=True, exist_ok=True)
    (d / name).write_text(found + "\n", encoding="utf-8")
inst = f"pip install -q --root-user-action=ignore {' '.join(pips)} >/dev/null 2>&1; " if pips else ""
r = subprocess.run(["docker", "run", "--rm", "--label", "curso=python-for-java-devs", "-v", f"{d}:/w",
                    "-w", "/w", "-e", "PYTHONPATH=/w", "-e", "COLUMNS=200", "python:3.14.7", "sh", "-c", inst + (cmd or "true")],
                   capture_output=True, text=True)
print(r.stdout[-6000:], r.stderr[-4000:], sep="\n")
EOF
cat > $Z/probado.py <<'EOF'
"""Marca una sección como probada: encabezado y rótulos. Uso: python3 probado.py <seccion.md> [parcial: texto]"""
import pathlib, sys
CARTA = pathlib.Path("/Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs")
p = CARTA / sys.argv[1]
t = p.read_text(encoding="utf-8")
OLD = "> Versiones verificadas contra PyPI el 05/10/2026 · Código escrito sin ejecutar: las salidas\n> rotuladas «Salida esperada, sin correr» no salen de una corrida."
NEW = "> Versiones verificadas contra PyPI el 05/10/2026 · Código probado el 05/10/2026 con Python 3.14.7,\n> en contenedor: las salidas son las de esa corrida."
assert OLD in t, "el encabezado no es el estándar"
t = t.replace(OLD, NEW).replace("Salida esperada, sin correr", "Salida (Python 3.14.7, 05/10/2026)")
p.write_text(t, encoding="utf-8")
print("probado:", p.name)
EOF
cd $Z; python3 probado.py op008-au01-http-contra-sistemas-ajenos.md; cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs; python3 -B prompts/verificar-corpus.py | grep -v "EMOJI\|BENCHMARKS" | tail -2; python3 ../../zz-code/python-for-java-devs-20261005-f516/verificar_urls.py op008-*.md

# --- 2026-10-05T16:05:16 · Skip .example domains in URL checker
sed -i '' 's/if "localhost" in u or "127.0.0.1" in u or "example." in u:/if "localhost" in u or "127.0.0.1" in u or "example." in u or ".example" in u:/' /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516/verificar_urls.py; grep -n '".example"' /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516/verificar_urls.py | head -2

# --- 2026-10-05T16:06:20 · Smoke-test au02 scraper
cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516; python3 humo.py op009-au02-scraping.md au02 'circulares.py="""Extrae las circulares' --pip httpx==0.28.1 selectolax==1.0.0 beautifulsoup4==4.15.0 --cmd "python circulares.py"

# --- 2026-10-05T16:06:29 · Fix block extractor and smoke-test au02
cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516; python3 - <<'EOF'
p='humo.py'; t=open(p).read()
a='''blocks = re.findall(r"(?:^|\\n)(.*)\\n\\n?```[a-z]*\\n(.*?)\\n```", text, re.S)'''
b='''def fenced(text):
    """(línea no vacía anterior a la cerca, contenido) de cada bloque de nivel superior."""
    out, lines, i = [], text.splitlines(), 0
    while i < len(lines):
        m = re.match(r"^(`{3,})[\\w-]*\\s*$", lines[i])
        if m:
            fence, j = m.group(1), i + 1
            while j < len(lines) and lines[j].rstrip() != fence:
                j += 1
            before = next((l for l in reversed(lines[:i]) if l.strip()), "")
            out.append((before, "\\n".join(lines[i + 1:j])))
            i = j + 1
        else:
            i += 1
    return out
blocks = fenced(text)'''
assert a in t; t=t.replace(a,b); open(p,'w').write(t)
EOF
python3 humo.py op009-au02-scraping.md au02 'circulares.py="""Extrae las circulares' --pip httpx==0.28.1 selectolax==1.0.0 beautifulsoup4==4.15.0 --cmd "python circulares.py"

# --- 2026-10-05T16:06:39 · Fix au02 output and mark tested
cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516; sed -i '' 's/2026-09-30 Nuevo soporte para ortodoncia: foto intra https/2026-09-30 Nuevo soporte para ortodoncia: foto intr https/' ../../cursos-algoritmos-lenguajes/python-for-java-devs/op009-au02-scraping.md; python3 probado.py op009-au02-scraping.md; cd ../../cursos-algoritmos-lenguajes/python-for-java-devs; python3 -B prompts/verificar-corpus.py | grep -v "EMOJI\|BENCHMARKS" | tail -2; python3 ../../zz-code/python-for-java-devs-20261005-f516/verificar_urls.py op009-*.md

# --- 2026-10-05T16:07:56 · Smoke-test au03 with Playwright in container
cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516; python3 humo.py op010-au03-playwright.md au03 'portal/index.html=<!doctype html>' 'portal/glosas.csv=factura;codigo;valor' 'radicar.py="""Radica' --pip playwright==1.63.0 --cmd "playwright install --with-deps chromium >/tmp/inst.log 2>&1 || tail -5 /tmp/inst.log; (python -m http.server 8000 --directory portal --bind 127.0.0.1 >/dev/null 2>&1 &) ; sleep 1; PORTAL_USER=aurea PORTAL_PASSWORD=prueba python radicar.py; ls -la rastro.zip glosas.csv | awk '{print \$5, \$9}'" 2>&1 | tail -15

# --- 2026-10-05T16:08:49 · Mark au03 and check base images for SSH test
cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516; python3 probado.py op010-au03-playwright.md; for i in debian:trixie-slim python:3.14.7-slim; do docker image inspect $i >/dev/null 2>&1 && echo "local $i" || echo "falta $i"; done; curl -s "https://hub.docker.com/v2/repositories/library/debian/tags/trixie-slim" | python3 -c "import json,sys;d=json.load(sys.stdin);print(d.get('name'),d.get('last_updated'))"

# --- 2026-10-05T16:10:01 · Run au04 SSH smoke test on private docker network
cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516; python3 humo.py op011-au04-ssh-y-sistemas-remotos.md au04 'sede/Dockerfile=FROM debian:trixie-slim' 'revisar_respaldos.py="""Revisa por SSH' >/dev/null; cd salidas/au04; rm -f revisor revisor.pub; ssh-keygen -q -t ed25519 -N "" -f revisor -C "revisor de respaldos" && cp revisor.pub sede/; sed -i '' 's/SITES = {"Centro": ("127.0.0.1", 2201), "Suba": ("127.0.0.1", 2202)}/SITES = {"Centro": ("pfjd-centro", 22), "Suba": ("pfjd-suba", 22)}/' revisar_respaldos.py; grep -n "^SITES" revisar_respaldos.py; docker build -q --label curso=python-for-java-devs -t pfjd-sede:humo sede 2>&1 | tail -1; docker network create --label curso=python-for-java-devs pfjd-au04 >/dev/null; for s in centro suba; do docker run -d --rm --label curso=python-for-java-devs --network pfjd-au04 --name pfjd-$s pfjd-sede:humo >/dev/null; done; docker exec pfjd-centro sh -c 'head -c 2000000 /dev/urandom > /respaldos/odontovia.sql.gz'; docker exec pfjd-suba sh -c 'head -c 900000 /dev/urandom > /respaldos/odontovia.sql.gz && touch -d "120 days ago" /respaldos/odontovia.sql.gz'; docker run --rm --label curso=python-for-java-devs --network pfjd-au04 -v $PWD:/w -w /w python:3.14.7 sh -c "pip install -q --root-user-action=ignore paramiko==5.0.0 >/dev/null 2>&1; ssh-keyscan -t ed25519 pfjd-centro > known_hosts 2>/dev/null; ssh-keyscan -t ed25519 pfjd-suba >> known_hosts 2>/dev/null; python revisar_respaldos.py"

# --- 2026-10-05T16:10:22 · Rebuild sede image with visible errors
cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516/salidas/au04; ls sede; docker build --progress=plain --label curso=python-for-java-devs -t pfjd-sede:humo sede 2>&1 | grep -i "error\|ERROR\|failed" | head -10

# --- 2026-10-05T16:10:36 · Find which command in Dockerfile failed
cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516/salidas/au04; docker build --progress=plain --no-cache --label curso=python-for-java-devs -t pfjd-sede:humo sede 2>&1 | grep -B2 -A2 "mkdir\|exists\|cannot" | tail -12

# --- 2026-10-05T16:10:48 · Show the failing step's own output
cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516/salidas/au04; docker build --progress=plain --no-cache --label curso=python-for-java-devs -t pfjd-sede:humo sede 2>&1 | grep "^#6" | tail -8

# --- 2026-10-05T16:11:09 · Fix Dockerfile and rerun SSH smoke test
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs; sed -i '' 's|    \&\& rm -rf /var/lib/apt/lists/\* \&\& mkdir /run/sshd /respaldos \\|    \&\& rm -rf /var/lib/apt/lists/* \&\& mkdir -p /run/sshd /respaldos \\|' op011-au04-ssh-y-sistemas-remotos.md; grep -n "mkdir -p /run/sshd" op011-au04-ssh-y-sistemas-remotos.md; cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516/salidas/au04; sed -i '' 's|mkdir /run/sshd /respaldos|mkdir -p /run/sshd /respaldos|' sede/Dockerfile; docker build -q --label curso=python-for-java-devs -t pfjd-sede:humo sede >/dev/null 2>&1 && echo construida; for s in centro suba; do docker run -d --rm --label curso=python-for-java-devs --network pfjd-au04 --name pfjd-$s pfjd-sede:humo >/dev/null; done; sleep 2; docker exec pfjd-centro sh -c 'head -c 2000000 /dev/urandom > /respaldos/odontovia.sql.gz'; docker exec pfjd-suba sh -c 'head -c 900000 /dev/urandom > /respaldos/odontovia.sql.gz && touch -d "120 days ago" /respaldos/odontovia.sql.gz'; docker run --rm --label curso=python-for-java-devs --network pfjd-au04 -v $PWD:/w -w /w python:3.14.7 sh -c "pip install -q --root-user-action=ignore paramiko==5.0.0 >/dev/null 2>&1; ssh-keyscan -t ed25519 pfjd-centro > known_hosts 2>/dev/null; ssh-keyscan -t ed25519 pfjd-suba >> known_hosts 2>/dev/null; python revisar_respaldos.py"

# --- 2026-10-05T16:11:36 · Test Fabric snippet then clean up docker resources
cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516/salidas/au04; cat > fab.py <<'EOF'
from fabric import Connection
conn = Connection("pfjd-centro", port=22, user="revisor",
                  connect_kwargs={"key_filename": "revisor", "look_for_keys": False})
result = conn.run("stat -c '%s %Y' /respaldos/odontovia.sql.gz", hide=True, warn=True)
print(result.ok, result.stdout.strip().split()[0])
bad = conn.run("stat /no/existe", hide=True, warn=True)
print(bad.ok, bad.exited)
EOF
docker run --rm --label curso=python-for-java-devs --network pfjd-au04 -v $PWD:/w -w /w python:3.14.7 sh -c "pip install -q --root-user-action=ignore fabric==3.2.3 >/dev/null 2>&1; mkdir -p ~/.ssh && cp known_hosts ~/.ssh/known_hosts; python fab.py"; docker rm -f -v pfjd-centro pfjd-suba >/dev/null 2>&1; docker network rm pfjd-au04 >/dev/null; docker image rm pfjd-sede:humo >/dev/null; docker ps -a --filter label=curso=python-for-java-devs --format '{{.Names}}'; docker network ls --filter label=curso=python-for-java-devs -q; echo limpio

# --- 2026-10-05T16:11:51 · Mark au04 tested and verify
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs; python3 - <<'EOF'
f='op011-au04-ssh-y-sistemas-remotos.md'; t=open(f,encoding='utf-8').read()
OLD='> Versiones verificadas contra PyPI el 05/10/2026 · Código escrito sin ejecutar: las salidas\n> rotuladas «Salida esperada, sin correr» no salen de una corrida.'
NEW='> Versiones verificadas contra PyPI el 05/10/2026 · Código probado el 05/10/2026 con Python 3.14.7,\n> en contenedor: el revisor y el fragmento de Fabric, contra dos sedes construidas con este mismo\n> `Dockerfile` en una red privada de Docker (sin los puertos del `compose.yaml`).'
assert OLD in t; t=t.replace(OLD,NEW).replace('Salida esperada, sin correr (el espacio libre depende de tu disco):','Salida (Python 3.14.7, 05/10/2026):')
t=t.replace('''- **Un fallo de conexión es un resultado, no una excepción.**''','''- **`mkdir -p /run/sshd`** en el `Dockerfile`: en Debian trixie el paquete ya crea ese directorio, y
  sin `-p` la imagen no se construye. Lo encontró la prueba de esta sección.
- **Un fallo de conexión es un resultado, no una excepción.**''')
open(f,'w',encoding='utf-8').write(t)
EOF
python3 -B prompts/verificar-corpus.py | grep -v "EMOJI\|BENCHMARKS" | tail -2; python3 ../../zz-code/python-for-java-devs-20261005-f516/verificar_urls.py op010-*.md op011-*.md

# --- 2026-10-05T16:11:55 · Recheck Ansible docs URL after pause
sleep 20; curl -s -o /dev/null -w "%{http_code}\n" -A "Mozilla/5.0" https://docs.ansible.com/ansible/latest/getting_started/index.html

# --- 2026-10-05T16:12:20 · Retry Ansible URL and alternative
sleep 60; for u in https://docs.ansible.com/ansible/latest/getting_started/index.html https://github.com/ansible/ansible; do curl -s -o /dev/null -w "%{http_code} $u\n" -A "Mozilla/5.0 (Macintosh)" $u; done

# --- 2026-10-05T16:12:26 · Replace Ansible link and recheck
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs; curl -s -o /dev/null -w "%{http_code}\n" https://github.com/ansible/ansible; python3 - <<'EOF'
f='op011-au04-ssh-y-sistemas-remotos.md'; t=open(f,encoding='utf-8').read()
a='- Ansible, para la frontera: https://docs.ansible.com/ansible/latest/getting_started/index.html'
b='- Ansible, para la frontera: https://github.com/ansible/ansible (su sitio de documentación,\n  `docs.ansible.com`, responde 429 a los clientes automáticos y no se pudo verificar)'
assert a in t; open(f,'w',encoding='utf-8').write(t.replace(a,b))
EOF
python3 ../../zz-code/python-for-java-devs-20261005-f516/verificar_urls.py op011-*.md

# --- 2026-10-05T16:13:47 · Check keyring version and smoke-test au05
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs; grep '`keyring`' prompts/inventario-verificado.md; cd ../../zz-code/python-for-java-devs-20261005-f516; python3 humo.py op012-au05-apis-de-saas.md au05 'agenda_franquicia.py="""Lee la agenda' 'prueba_agenda.py="""Prueba la renovación' --pip authlib==1.8.0 httpx==0.28.1 keyring --cmd "pip show keyring | grep Version; python prueba_agenda.py"

# --- 2026-10-05T16:14:00 · Investigate httpx2 deprecation in authlib
for p in httpx2 httpx; do printf "%-8s " $p; curl -s https://pypi.org/pypi/$p/json | python3 -c "import json,sys
try:
 d=json.load(sys.stdin);i=d['info'];v=i['version'];print(v,(d['releases'][v] or [{'upload_time':'?'}])[0]['upload_time'][:10],'|',i.get('summary'),'|',i.get('home_page') or (i.get('project_urls') or {}).get('Homepage') or (i.get('project_urls') or {}).get('Source'))
except Exception as e: print('NO EXISTE',e)"; done; S=/Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516/salidas/au05; docker run --rm --label curso=python-for-java-devs -v $S:/w -w /w python:3.14.7 sh -c "pip install -q --root-user-action=ignore authlib==1.8.0 >/dev/null 2>&1; sed -n 1,30p /usr/local/lib/python3.14/site-packages/authlib/integrations/httpx_client/_compat.py"

# --- 2026-10-05T16:14:10 · Read httpx2 README from its repository
curl -s https://raw.githubusercontent.com/pydantic/httpx2/main/README.md | head -60

# --- 2026-10-05T16:14:26 · Add httpx2 notes, inventory and mark au05
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs; python3 - <<'EOF'
f='op008-au01-http-contra-sistemas-ajenos.md'; t=open(f,encoding='utf-8').read()
a='''`httpx` (0.28.1, publicada el 2024-12-06) lleva casi dos años sin versión nueva y sigue siendo el
cliente recomendado del camino base; es una biblioteca estable, no una abandonada, pero conviene
mirar la fecha antes de cada proyecto nuevo.'''
b='''`httpx` (0.28.1, publicada el 2024-12-06) lleva casi dos años sin versión nueva y es el cliente que
usa el camino base.

> 📝 **Nota de ecosistema — `httpx2`.** En 2026 Pydantic tomó la continuación del proyecto bajo el
> nombre **`httpx2`** (2.13.1, del 2026-09-23), con la API de `httpx` y el `import httpx2`, porque
> `httpx` "ha tenido actividad limitada" según su propio anuncio. Algunas bibliotecas ya lo
> prefieren: `authlib` 1.8 avisa que su integración con `httpx` está deprecada. Todo lo de esta
> sección vale igual con `httpx2` cambiando el `import`; para un proyecto nuevo, mira el estado de
> los dos antes de elegir.'''
assert a in t; open(f,'w',encoding='utf-8').write(t.replace(a,b))
f='op012-au05-apis-de-saas.md'; t=open(f,encoding='utf-8').read()
a='''- **`OAuth2Client` es un `httpx.Client`**: por eso recibe `transport=` y se prueba con
  `MockTransport` igual que cualquier otro cliente.'''
b='''- **`OAuth2Client` es un `httpx.Client`**: por eso recibe `transport=` y se prueba con
  `MockTransport` igual que cualquier otro cliente.

> 📝 **Nota de ecosistema.** Al correr la prueba, `authlib` 1.8.0 imprime
> `AuthlibDeprecationWarning: The httpx module is deprecated; please use httpx2 instead.`: la
> integración ya prefiere **`httpx2`** (2.13.1, del 2026-09-23), la continuación de `httpx` que
> mantiene Pydantic, y usa `httpx` solo como respaldo. El código de esta sección funciona igual con
> los dos; con `httpx2` instalado, el aviso desaparece.'''
assert a in t; open(f,'w',encoding='utf-8').write(t.replace(a,b))
p='prompts/check-inventario.py'; t=open(p,encoding='utf-8').read()
a='"au": ["httpx", "requests",'; assert a in t; open(p,'w',encoding='utf-8').write(t.replace(a,'"au": ["httpx", "httpx2", "requests",'))
EOF
cd ../../zz-code/python-for-java-devs-20261005-f516; python3 probado.py op012-au05-apis-de-saas.md; python3 probado.py op011-au04-ssh-y-sistemas-remotos.md 2>&1 | tail -1; cd ../../cursos-algoritmos-lenguajes/python-for-java-devs; python3 -B prompts/verificar-corpus.py | grep -v "EMOJI\|BENCHMARKS" | tail -2; python3 ../../zz-code/python-for-java-devs-20261005-f516/verificar_urls.py op012-*.md

# --- 2026-10-05T16:14:36 · Skip code URLs and find authlib docs URL
python3 - <<'EOF'
p='/Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516/verificar_urls.py'; t=open(p).read()
a='''        for u in URL_RE.findall(open(f, encoding="utf-8").read()):'''
b='''        texto = re.sub(r"```.*?```", "", open(f, encoding="utf-8").read(), flags=re.S)  # el código no es referencia
        for u in URL_RE.findall(texto):'''
assert a in t; open(p,'w').write(t.replace(a,b))
EOF
for u in https://docs.authlib.org/en/latest/client/httpx.html https://docs.authlib.org/en/stable/client/httpx.html https://docs.authlib.org/en/latest/ https://docs.authlib.org/; do curl -s -o /dev/null -w "%{http_code} %{url_effective}\n" -L $u; done

# --- 2026-10-05T16:14:41 · Find httpx page in authlib docs index
curl -s https://docs.authlib.org/en/latest/ | grep -o 'href="[^"]*httpx[^"]*"' | sort -u | head; curl -s https://docs.authlib.org/en/latest/ | grep -o 'href="[^"]*client[^"]*"' | sort -u | head -20

# --- 2026-10-05T16:14:47 · Fix authlib URL and recheck au URLs
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs; sed -i '' 's|https://docs.authlib.org/en/latest/client/httpx.html|https://docs.authlib.org/en/latest/oauth2/client/http/httpx.html|' op012-au05-apis-de-saas.md; python3 ../../zz-code/python-for-java-devs-20261005-f516/verificar_urls.py op008-*.md op009-*.md op010-*.md op011-*.md op012-*.md

# --- 2026-10-05T16:14:54 · Check base coverage of cron/systemd/containers
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs; grep -n -i "cron\|systemd\|timer\|launchd\|contenedor\|Dockerfile" 15-el-proceso-nocturno.md 16-operacion-y-rendimiento.md | head -30

# --- 2026-10-05T16:16:11 · Smoke-test PEP 723 script with uv
cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516; python3 humo.py op013-au06-desplegar-automatizaciones.md au06 'revisar_circulares.py=# /// script' 'aurea-circulares.service=[Unit]
Description=Revisión' 'aurea-circulares.timer=[Unit]
Description=Todos' --pip uv==0.12.23 --cmd "PORTAL_TOKEN=prueba uv run -q --script revisar_circulares.py" 2>&1 | grep -v "^$" | tail -5; ls salidas/au06

# --- 2026-10-05T16:16:22 · Verify systemd unit syntax in Debian container
S=/Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516/salidas/au06; docker run --rm --label curso=python-for-java-devs -v $S:/w -w /w debian:trixie-slim sh -c "apt-get update -qq >/dev/null && apt-get install -y -qq systemd >/dev/null 2>&1; useradd aurea; mkdir -p /opt/aurea /var/cache/aurea /etc/aurea/credenciales; printf '#!/bin/sh\n' > /usr/local/bin/uv; chmod +x /usr/local/bin/uv; cp revisar_circulares.py /opt/aurea/; echo prueba > /etc/aurea/credenciales/portal-token; cp aurea-circulares.service aurea-circulares.timer /etc/systemd/system/; printf '[Unit]\nDescription=Aviso de fallo de %%i\n[Service]\nType=oneshot\nExecStart=/bin/true\n' > /etc/systemd/system/aurea-aviso@.service; echo '--- verify'; systemd-analyze verify /etc/systemd/system/aurea-circulares.service /etc/systemd/system/aurea-circulares.timer 2>&1; echo \"rc=\$?\"; echo '--- calendar'; systemd-analyze calendar --iterations=2 '*-*-* 06:30:00 America/Bogota' 2>&1 | head -6"

# --- 2026-10-05T16:16:44 · Mark au06 partially tested and verify
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs; python3 - <<'EOF'
f='op013-au06-desplegar-automatizaciones.md'; t=open(f,encoding='utf-8').read()
OLD='> Versiones verificadas contra PyPI el 05/10/2026 · Código escrito sin ejecutar: las salidas\n> rotuladas «Salida esperada, sin correr» no salen de una corrida.'
NEW='> Versiones verificadas contra PyPI el 05/10/2026 · Código probado en parte el 05/10/2026 con\n> Python 3.14.7, en contenedor: el script con `uv run --script` y las dos unidades con\n> `systemd-analyze verify`; el timer no se corrió en una máquina con `systemd` activo.'
assert OLD in t; t=t.replace(OLD,NEW)
a='Salida esperada, sin correr (la primera vez, `uv` resuelve e instala las dos dependencias antes):'
assert a in t; t=t.replace(a,'Salida (Python 3.14.7, 05/10/2026); la primera vez, `uv` resuelve e instala las dos dependencias antes:')
a='''`systemd-analyze verify` revisa la sintaxis de las dos unidades antes de habilitarlas.'''
assert a in t; t=t.replace(a,'''`systemd-analyze verify` revisa la sintaxis de las dos unidades antes de habilitarlas (en la prueba
de esta sección, sobre Debian trixie, no dio ningún aviso).''')
open(f,'w',encoding='utf-8').write(t)
EOF
python3 -B prompts/verificar-corpus.py | grep -v "EMOJI\|BENCHMARKS" | tail -2; python3 ../../zz-code/python-for-java-devs-20261005-f516/verificar_urls.py op013-*.md

# --- 2026-10-05T16:16:51 · Switch systemd man links to man7.org
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs; for u in https://man7.org/linux/man-pages/man5/systemd.timer.5.html https://man7.org/linux/man-pages/man5/systemd.exec.5.html; do curl -s -o /dev/null -w "%{http_code} $u\n" $u; done; sed -i '' 's|https://www.freedesktop.org/software/systemd/man/latest/systemd.timer.html|https://man7.org/linux/man-pages/man5/systemd.timer.5.html|; s|https://www.freedesktop.org/software/systemd/man/latest/systemd.exec.html|https://man7.org/linux/man-pages/man5/systemd.exec.5.html|' op013-au06-desplegar-automatizaciones.md; python3 ../../zz-code/python-for-java-devs-20261005-f516/verificar_urls.py op013-*.md

# --- 2026-10-05T16:18:02 · Compute break-even, fix claim, smoke-test au07
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs; python3 -c "
fix=8.5/3
for n in range(3,7): print(n, round((8-n)*4 - n*fix,2))
print('doble', 20-17)"; python3 - <<'EOF'
f='op014-au07-veredicto.md'; t=open(f,encoding='utf-8').read()
a='''once horas y media en dos meses, porque cada corrida buena reemplaza media jornada de clics. Si su
tasa de rotura subiera al 60% con los mismos arreglos, el neto seguiría positivo; si cada arreglo
tomara el doble, ya no tanto —y esa es la pregunta que hay que hacerse cada trimestre—.'''
b='''once horas y media en dos meses, porque cada corrida buena reemplaza media jornada de clics. Pero el
margen es más angosto de lo que parece: con la misma duración media de arreglo (2,8 horas), **cinco
fallas de ocho** ya dan un neto negativo (−2,2 horas), mientras que con tres fallas y arreglos del
doble de largos todavía quedan tres horas a favor. La tasa de rotura pesa más que el tiempo de
arreglo, y esa es la pregunta que hay que hacerse cada trimestre.'''
assert a in t; open(f,'w',encoding='utf-8').write(t.replace(a,b))
EOF
cd ../../zz-code/python-for-java-devs-20261005-f516; python3 humo.py op014-au07-veredicto.md au07 'cuenta_robots.py="""¿Siguen valiendo' --cmd "python cuenta_robots.py"

# --- 2026-10-05T16:18:09 · Close T2 checks: inventory, verifier, URLs
cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516; python3 probado.py op014-au07-veredicto.md; cd ../../cursos-algoritmos-lenguajes/python-for-java-devs; python3 -B prompts/check-inventario.py au | tail -1; grep '`httpx2`' prompts/inventario-verificado.md; python3 -B prompts/verificar-corpus.py | grep -v "EMOJI\|BENCHMARKS" | tail -2; python3 ../../zz-code/python-for-java-devs-20261005-f516/verificar_urls.py op014-*.md; grep -rl "Ã\|â€" op0*.md; wc -l op008* op009* op010* op011* op012* op013* op014* | tail -1; docker ps -a --filter label=curso=python-for-java-devs -q | wc -l

# --- 2026-10-05T16:18:23 · Inspect mojibake hits
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs; grep -n "Ã\|â€" op009-au02-scraping.md op006-lg06-archivos-planos-hostiles.md | head

# --- 2026-10-05T16:18:34 · Close T2 in production plan
cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516; python3 plan.py 8 14 ✅ ✅; python3 plan.py 13 13 ✅ 🟡; python3 plan.py tanda T2 ✅; python3 plan.py dondeesta "(05/10/2026).** T1 (\`lg\`) y T2 (\`au\`) cerradas; T3 (\`co\`) en curso."; python3 plan.py bitacora "**2026-10-05 · T2 (\`au\`) cerrada.** Escritas op008–op014 (2.311 líneas, 68 ejercicios). Pruebas de humo: seis completas y \`au06\` en parte (script con \`uv\` y \`systemd-analyze verify\` de las unidades; el timer no corrió con \`systemd\` activo). \`au03\` corrió con Chromium real (Playwright 1.63.0) contra un portal falso servido en el contenedor; \`au04\` contra dos sedes SSH en una red privada de Docker, sin puertos publicados, borradas al terminar (contenedores, red e imagen \`pfjd-sede:humo\`). **Defectos propios encontrados:** \`httpx.Request\` no acepta \`auth=\` (\`au01\`); \`mkdir /run/sshd\` rompe la imagen en Debian trixie (\`au04\`); el recorte a 40 caracteres de \`au02\`; y una afirmación falsa de \`au07\` sobre el umbral de rotura, recalculada (cinco fallas de ocho dan neto negativo). **Hallazgo de ecosistema, pendiente para el autor (📌):** Pydantic continúa \`httpx\` como **\`httpx2\`** 2.13.1 (2026-09-23) y \`authlib\` 1.8 ya trata a \`httpx\` como deprecado; el camino base usa \`httpx\` 0.28.1 (2024-12) en Fase 13 y otras —no se tocó, por bloqueo de contenido—; la carta lo dice en notas de ecosistema de \`au01\` y \`au05\`. URL: \`docs.ansible.com\` (429) y \`freedesktop.org\` (418) rechazan clientes automáticos; reemplazadas por GitHub y \`man7.org\`. \`verificar_urls.py\` ya ignora las URL dentro de bloques de código. **Recursos:** se descargó \`debian:trixie-slim\` (no estaba): borrar al cerrar la carta. Mojibake intencional en \`lg06\` y \`au02\`. **Tags:** \`op-au-fase-01\` … \`op-au-fase-07\`. **Siguiente:** T3 (\`co\`)."; grep -n "\*\*T2\*\*" ../../cursos-algoritmos-lenguajes/python-for-java-devs/prompts/plan-de-produccion-carta.md

# --- 2026-10-05T16:18:41 · Show co versions and story mail facts
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs; sed -n '/^## `co`/,/^## `wf`/p' prompts/inventario-verificado.md; grep -n -i "correo\|smtp\|liquidaci" 00-historia-de-aurea.md | head -12; grep -rn "smtplib\|email.message" 1[0-7]-*.md | head -5

# --- 2026-10-05T16:19:51 · Find sede and franchisee names in story
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs; grep -n -i "sede\b\|sedes\|franquiciad\|Chía\|Zipaquirá\|Suba\|Kennedy\|Usaquén\|Soacha\|Centro" 00-historia-de-aurea.md | head -40

# --- 2026-10-05T16:20:10 · Replace invented franchise and fix au05 key
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs; python3 - <<'EOF'
f='op015-co01-correo-saliente.md'; t=open(f,encoding='utf-8').read()
rep=[('from email.utils import formataddr, make_msgid','from email.utils import formataddr, formatdate, make_msgid'),
('''    # EmailMessage agrega Date al enviar si falta; se pone explícito para que el mensaje guardado lo traiga.
    msg["Date"] = __import__("email.utils").utils.formatdate(localtime=True)''','''    # smtplib no agrega Date; sin él, el servidor lo pone a su manera y algunos filtros lo penalizan.
    msg["Date"] = formatdate(localtime=True)'''),
('''    Path("liquidacion-chia-2026T3.pdf").write_bytes(b"%PDF-1.4\\n% Chia\\n")''','''    Path("liquidacion-zipaquira-2026T3.pdf").write_bytes(b"%PDF-1.4\\n% Zipaquira\\n")'''),
('''        Settlement("Chía", "Lorena Vargas", "lorena.vargas@franquicias.example", "$ 11.075.500",
                   Path("liquidacion-chia-2026T3.pdf")),''','''        Settlement("Zipaquirá", "equipo de Zipaquirá", "sede.zipaquira@franquicias.example",
                   "$ 11.075.500", Path("liquidacion-zipaquira-2026T3.pdf")),'''),
('Chía: aceptado por el servidor','Zipaquirá: aceptado por el servidor'),
('1. Cambia el PDF de Chía por el de Suba en la lista.','1. Cambia el PDF de Zipaquirá por el de Suba en la lista.'),
]
for a,b in rep:
    assert a in t,a[:40]; t=t.replace(a,b)
open(f,'w',encoding='utf-8').write(t)
f='op012-au05-apis-de-saas.md'; t=open(f,encoding='utf-8').read()
n=t.count('"zipaquira"'); t=t.replace('"zipaquira"','"sede-calendar"'); open(f,'w',encoding='utf-8').write(t); print("au05 claves cambiadas:",n)
EOF
grep -n "zipaquira\|Zipaquirá" op012-au05-apis-de-saas.md | head; grep -n 'franchise.lower() not in' op015-co01-correo-saliente.md

# --- 2026-10-05T16:20:22 · Fix accent comparison and smoke-test co01
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs; python3 - <<'EOF'
f='op015-co01-correo-saliente.md'; t=open(f,encoding='utf-8').read()
rep=[('''import ssl
from dataclasses import dataclass''','''import ssl
import unicodedata
from dataclasses import dataclass'''),
('''def check_attachment(item: Settlement) -> None:
    # La regla que evita el error del trimestre pasado: el PDF tiene que ser de esta sede.
    if item.franchise.lower() not in item.pdf.name.lower():''','''def ascii_slug(text: str) -> str:
    # "Zipaquirá" y "zipaquira" tienen que coincidir: los nombres de archivo no llevan tildes.
    return unicodedata.normalize("NFKD", text).encode("ascii", "ignore").decode().lower()


def check_attachment(item: Settlement) -> None:
    # La regla que evita el error del trimestre pasado: el PDF tiene que ser de esta sede.
    if ascii_slug(item.franchise) not in ascii_slug(item.pdf.name):'''),
('''- **Todos los adjuntos se validan antes de mandar el primer correo.**''','''- **`ascii_slug` antes de comparar.** Sin él, "Zipaquirá" nunca coincide con
  `liquidacion-zipaquira-…pdf` y el programa se niega a mandar un correo correcto.
- **Todos los adjuntos se validan antes de mandar el primer correo.**''')]
for a,b in rep:
    assert a in t,a[:40]; t=t.replace(a,b)
open(f,'w',encoding='utf-8').write(t)
EOF
cd ../../zz-code/python-for-java-devs-20261005-f516; python3 humo.py op015-co01-correo-saliente.md co01 'liquidaciones.py="""Manda a cada franquiciado' --pip aiosmtpd==1.4.6 --cmd "(python -m aiosmtpd -n -l 127.0.0.1:8025 > smtp.log 2>&1 &); sleep 1; SMTP_HOST=127.0.0.1 SMTP_PORT=8025 SMTP_TLS=0 python liquidaciones.py; sleep 1; grep -c 'Content-Type: application/pdf' smtp.log; grep -m2 '^Subject' smtp.log"

# --- 2026-10-05T16:20:34 · Check aiosmtpd output buffering
S=/Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516/salidas/co01; wc -c $S/smtp.log; head -5 $S/smtp.log; docker run --rm --label curso=python-for-java-devs -v $S:/w -w /w -e PYTHONPATH=/w python:3.14.7 sh -c "pip install -q --root-user-action=ignore aiosmtpd==1.4.6 >/dev/null 2>&1; (python -u -m aiosmtpd -n -l 127.0.0.1:8025 > smtp2.log 2>&1 &); sleep 1; SMTP_HOST=127.0.0.1 SMTP_PORT=8025 SMTP_TLS=0 python liquidaciones.py >/dev/null; sleep 1; grep -c 'Content-Type: application/pdf' smtp2.log; grep -m2 -i '^Subject' smtp2.log; python -m aiosmtpd --help | grep -A2 -- '-c'"

# --- 2026-10-05T16:20:51 · Mark co01 and probe real SPF/DMARC records
cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516; python3 probado.py op015-co01-correo-saliente.md; docker run --rm --label curso=python-for-java-devs python:3.14.7 sh -c "pip install -q --root-user-action=ignore dnspython==2.8.0 >/dev/null 2>&1; python -c \"
import dns.resolver
for name in ['gmail.com','_dmarc.gmail.com']:
    for r in dns.resolver.resolve(name,'TXT'):
        s=b''.join(r.strings).decode()
        if s.startswith(('v=spf1','v=DMARC1')): print(name, '→', s)
\""

# --- 2026-10-05T16:21:57 · Fix import and smoke-test co02
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs; python3 - <<'EOF'
f='op016-co02-que-el-correo-llegue.md'; t=open(f,encoding='utf-8').read()
for a,b in [('''import dkim
import dns.resolver''','''import base64

import dkim
import dns.resolver'''),('record = b"v=DKIM1; k=rsa; p=" + __import__("base64").b64encode(public_der)','record = b"v=DKIM1; k=rsa; p=" + base64.b64encode(public_der)')]:
    assert a in t; t=t.replace(a,b)
open(f,'w',encoding='utf-8').write(t)
EOF
cd ../../zz-code/python-for-java-devs-20261005-f516; python3 humo.py op016-co02-que-el-correo-llegue.md co02 'diagnostico_correo.py="""Diagnóstico de entrega' --pip dnspython==2.8.0 dkimpy==1.1.8 cryptography==50.0.2 --cmd "python diagnostico_correo.py"

# --- 2026-10-05T16:22:06 · Mark co02 and check URLs
cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516; python3 probado.py op016-co02-que-el-correo-llegue.md; cd ../../cursos-algoritmos-lenguajes/python-for-java-devs; python3 ../../zz-code/python-for-java-devs-20261005-f516/verificar_urls.py op015-*.md op016-*.md; python3 -B prompts/verificar-corpus.py | grep -v "EMOJI\|BENCHMARKS" | tail -2

# --- 2026-10-05T16:22:36 · Recheck Google support URL with curl
curl -s -o /dev/null -m 30 -w "%{http_code} %{url_effective}\n" -L -A "Mozilla/5.0" https://support.google.com/a/answer/81126

# --- 2026-10-05T16:22:42 · Use canonical Google support URL
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs; sed -i '' 's|https://support.google.com/a/answer/81126|https://support.google.com/mail/answer/81126|' op016-co02-que-el-correo-llegue.md; curl -s -o /dev/null -m 30 -w "%{http_code}\n" -A "Mozilla/5.0" https://support.google.com/mail/answer/81126

# --- 2026-10-05T16:23:58 · Smoke-test co03 sanitizing
cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516; python3 humo.py op017-co03-correo-entrante.md co03 'buzon_cartera.py="""Procesa el buzón' 'prueba_buzon.py="""Mensajes de prueba' --pip imap-tools==1.15.0 --cmd "python prueba_buzon.py"

# --- 2026-10-05T16:24:07 · Find current GreenMail image tag
curl -s "https://hub.docker.com/v2/repositories/greenmail/standalone/tags?page_size=5&ordering=last_updated" | python3 -c "import json,sys;[print(t['name'],t['last_updated'][:10]) for t in json.load(sys.stdin)['results']]"

# --- 2026-10-05T16:24:21 · Test IMAP processing against GreenMail
S=/Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516/salidas/co03; cat > $S/prueba_imap.py <<'EOF'
import functools, smtplib, time
import imap_tools
from prueba_buzon import message
imap_tools.MailBox = functools.partial(imap_tools.MailBoxUnencrypted, port=3143)  # GreenMail de pruebas, sin TLS
import buzon_cartera
H = "pfjd-mail"
with smtplib.SMTP(H, 3025) as s:
    s.sendmail("glosas@prepagada.example", ["cartera@aurea.example"], message("glosas@prepagada.example", "glosas sept.pdf", b"%PDF-1.7 x"))
    s.sendmail("x@phishing.example", ["cartera@aurea.example"], message("x@phishing.example", "glosas.pdf", b"%PDF-1.7"))
    s.sendmail("cartera@aseguradora.example", ["cartera@aurea.example"], message("cartera@aseguradora.example", "pago.pdf", b"%PDF-1.7 y"))
time.sleep(1)
with imap_tools.MailBox(H).login("cartera", "secreto") as box:
    for f in ("Revisar", "Procesados"):
        box.folder.create(f)
buzon_cartera.process_mailbox(H, "cartera", "secreto")
with imap_tools.MailBox(H).login("cartera", "secreto") as box:
    for f in ("INBOX", "Revisar", "Procesados"):
        box.folder.set(f); print(f, len(list(box.fetch(mark_seen=False))))
import os; print(sorted(os.listdir("entrantes")))
EOF
docker network create --label curso=python-for-java-devs pfjd-co03 >/dev/null; docker run -d --rm --label curso=python-for-java-devs --network pfjd-co03 --name pfjd-mail -e GREENMAIL_OPTS="-Dgreenmail.setup.test.all -Dgreenmail.hostname=0.0.0.0 -Dgreenmail.users=cartera:secreto@aurea.example -Dgreenmail.users.login=local_part" greenmail/standalone:2.1.14 >/dev/null; sleep 8; docker run --rm --label curso=python-for-java-devs --network pfjd-co03 -v $S:/w -w /w -e PYTHONPATH=/w python:3.14.7 sh -c "pip install -q --root-user-action=ignore imap-tools==1.15.0 >/dev/null 2>&1; python prueba_imap.py" 2>&1 | tail -12; docker rm -f -v pfjd-mail >/dev/null 2>&1; docker network rm pfjd-co03 >/dev/null; docker image rm greenmail/standalone:2.1.14 >/dev/null; echo limpio

# --- 2026-10-05T16:24:49 · Mark co03 tested and verify
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs; python3 - <<'EOF'
f='op017-co03-correo-entrante.md'; t=open(f,encoding='utf-8').read()
OLD='> Versiones verificadas contra PyPI el 05/10/2026 · Código escrito sin ejecutar: las salidas\n> rotuladas «Salida esperada, sin correr» no salen de una corrida.'
NEW='> Versiones verificadas contra PyPI el 05/10/2026 · Código probado el 05/10/2026 con Python 3.14.7,\n> en contenedor: el saneamiento, y el procesamiento del buzón contra un servidor GreenMail 2.1.14 de\n> pruebas (dos mensajes a "Procesados", uno a "Revisar").'
assert OLD in t; t=t.replace(OLD,NEW).replace("Salida esperada, sin correr:","Salida (Python 3.14.7, 05/10/2026):")
t=t.replace("4. Levanta un servidor IMAP de pruebas en un contenedor (GreenMail o Dovecot) y corre","4. Levanta un servidor IMAP de pruebas en un contenedor (`greenmail/standalone`, por ejemplo) y corre")
open(f,'w',encoding='utf-8').write(t)
EOF
python3 -B prompts/verificar-corpus.py | grep -v "EMOJI\|BENCHMARKS" | tail -2; python3 ../../zz-code/python-for-java-devs-20261005-f516/verificar_urls.py op017-*.md

# --- 2026-10-05T16:24:59 · Check MailHog and Mailpit release dates
for r in mailhog/MailHog axllent/mailpit; do curl -s https://api.github.com/repos/$r/releases/latest | python3 -c "import json,sys;d=json.load(sys.stdin);print('$r', d.get('tag_name'), (d.get('published_at') or '')[:10])"; done; curl -s "https://hub.docker.com/v2/repositories/axllent/mailpit/tags?page_size=3&ordering=last_updated" | python3 -c "import json,sys;[print(t['name'],t['last_updated'][:10]) for t in json.load(sys.stdin)['results']]"; python3 -c "import sys; print(sys.version)"; 

# --- 2026-10-05T16:25:59 · Smoke-test co04 pytest and Mailpit levels
cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516; python3 humo.py op018-co04-probar-correo.md co04 'envio.py="""Arma y manda' 'test_envio.py="""Pruebas del correo' --pip pytest aiosmtpd==1.4.6 --cmd "pytest -q -p no:cacheprovider test_envio.py 2>&1 | tail -2" | grep -v "^$"; S=salidas/co04; docker network create --label curso=python-for-java-devs pfjd-co04 >/dev/null; docker run -d --rm --label curso=python-for-java-devs --network pfjd-co04 --name pfjd-mailpit axllent/mailpit:v1.31.4 >/dev/null 2>&1; sleep 3; docker run --rm --label curso=python-for-java-devs --network pfjd-co04 -v $PWD/$S:/w -w /w -e PYTHONPATH=/w python:3.14.7 sh -c "python -c \"from envio import build_settlement, send; send(build_settlement('Suba', 'edgar.rojas@franquicias.example', 'liquidacion-suba.pdf', b'%PDF'), 'pfjd-mailpit', 1025)\"; python -c \"import json,urllib.request; d=json.load(urllib.request.urlopen('http://pfjd-mailpit:8025/api/v1/messages')); m=d['messages'][0]; print(d['total'], m['Subject'], m['Attachments'])\""; docker rm -f -v pfjd-mailpit >/dev/null 2>&1; docker network rm pfjd-co04 >/dev/null; docker image rm axllent/mailpit:v1.31.4 >/dev/null 2>&1; echo limpio

# --- 2026-10-05T16:26:17 · Mark co04 tested and verify
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs; python3 - <<'EOF'
f='op018-co04-probar-correo.md'; t=open(f,encoding='utf-8').read()
OLD='> Versiones verificadas contra PyPI el 05/10/2026 · Código escrito sin ejecutar: las salidas\n> rotuladas «Salida esperada, sin correr» no salen de una corrida.'
NEW='> Versiones verificadas contra PyPI el 05/10/2026 · Código probado el 05/10/2026 con Python 3.14.7,\n> en contenedor: las dos pruebas con `pytest`, y el envío a Mailpit v1.31.4 consultado por su API\n> (en una red privada de Docker, sin los puertos del `compose.yaml`).'
assert OLD in t; t=t.replace(OLD,NEW).replace("Salida esperada, sin correr:","Salida (Python 3.14.7, 05/10/2026):").replace("2 passed in 0.31s","2 passed in 0.07s")
open(f,'w',encoding='utf-8').write(t)
EOF
python3 -B prompts/verificar-corpus.py | grep -v "EMOJI\|BENCHMARKS" | tail -2; python3 ../../zz-code/python-for-java-devs-20261005-f516/verificar_urls.py op018-*.md

# --- 2026-10-05T16:27:32 · Inspect paramiko prefetch semantics
docker run --rm --label curso=python-for-java-devs python:3.14.7 sh -c "pip install -q --root-user-action=ignore paramiko==5.0.0 >/dev/null 2>&1; python - <<'EOF'
import inspect, paramiko.sftp_file as f
src = inspect.getsource(f.SFTPFile.prefetch)
print(src[:1600])
print('ctx:', hasattr(paramiko.SFTPClient, '__enter__'))
EOF"

# --- 2026-10-05T16:27:49 · Fix prefetch and test co05 against real SFTP
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs; python3 - <<'EOF'
f='op019-co05-transferencia-de-archivos.md'; t=open(f,encoding='utf-8').read()
a='''        source.prefetch(entry.st_size - offset)        # pide los bloques por adelantado: mucho más rápido'''
b='''        source.prefetch(entry.st_size)                 # el tamaño TOTAL, no lo que falta: pide por adelantado'''
assert a in t; t=t.replace(a,b)
a='''- **El `.part` se retoma** con `seek`:'''
b='''- **`prefetch` recibe el tamaño total del archivo**, no lo que falta por bajar: su documentación lo
  describe como el valor que devolvería `stat`. El primer borrador de esta sección le pasaba lo que
  faltaba, y al retomar no habría pedido el final del archivo.
- **El `.part` se retoma** con `seek`:'''
assert a in t; t=t.replace(a,b)
open(f,'w',encoding='utf-8').write(t)
EOF
S=/Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516/salidas/co05; mkdir -p $S/sftp; cd ../../zz-code/python-for-java-devs-20261005-f516; python3 humo.py op019-co05-transferencia-de-archivos.md co05 'descargar_pagos.py="""Baja las relaciones' >/dev/null; cd $S; rm -f aurea_ed25519*; ssh-keygen -q -t ed25519 -N "" -f aurea_ed25519 -C aurea; cp aurea_ed25519.pub sftp/; cat > sftp/Dockerfile <<'EOF'
FROM debian:trixie-slim
RUN apt-get update && apt-get install -y --no-install-recommends openssh-server \
    && rm -rf /var/lib/apt/lists/* && mkdir -p /run/sshd /salida/aurea \
    && useradd -m -s /bin/bash aurea && chown aurea /salida/aurea
COPY aurea_ed25519.pub /home/aurea/.ssh/authorized_keys
RUN chown -R aurea /home/aurea/.ssh && chmod 600 /home/aurea/.ssh/authorized_keys
CMD ["/usr/sbin/sshd", "-D", "-e"]
EOF
docker build -q --label curso=python-for-java-devs -t pfjd-sftp:humo sftp >/dev/null && echo construida; docker network create --label curso=python-for-java-devs pfjd-co05 >/dev/null; docker run -d --rm --label curso=python-for-java-devs --network pfjd-co05 --name pfjd-sftp pfjd-sftp:humo >/dev/null; sleep 2; docker exec -u aurea pfjd-sftp sh -c 'cd /salida/aurea && python3 -c 1 2>/dev/null; head -c 48213 /dev/zero | tr "\0" "a" > pagos-septiembre.csv && touch -d "2 hours ago" pagos-septiembre.csv && head -c 12002 /dev/zero | tr "\0" "b" > pagos-octubre-1.csv && touch pagos-octubre-1.csv.ok && head -c 500 /dev/zero > pagos-octubre-2.csv'; docker run --rm --label curso=python-for-java-devs --network pfjd-co05 -v $S:/w -w /w python:3.14.7 sh -c "pip install -q --root-user-action=ignore paramiko==5.0.0 >/dev/null 2>&1; ssh-keyscan -t ed25519 pfjd-sftp > known_hosts 2>/dev/null; python descargar_pagos.py pfjd-sftp 22; python descargar_pagos.py pfjd-sftp 22"

# --- 2026-10-05T16:28:16 · Test resume and replacement detection, then clean up
S=/Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516/salidas/co05; cd $S; head -c 20000 pagos/pagos-septiembre.csv > pagos/pagos-septiembre.csv.part; rm pagos/pagos-septiembre.csv; python3 -c "import json;p='pagos/.descargados.json';d=json.load(open(p));d.pop('pagos-septiembre.csv');json.dump(d,open(p,'w'))"; docker exec -u aurea pfjd-sftp sh -c 'cd /salida/aurea && printf "corregido\n" >> pagos-octubre-1.csv && touch pagos-octubre-1.csv.ok'; docker run --rm --label curso=python-for-java-devs --network pfjd-co05 -v $S:/w -w /w python:3.14.7 sh -c "pip install -q --root-user-action=ignore paramiko==5.0.0 >/dev/null 2>&1; python descargar_pagos.py pfjd-sftp 22; sha256sum pagos/pagos-septiembre.csv | cut -c1-12"; docker rm -f -v pfjd-sftp >/dev/null 2>&1; docker network rm pfjd-co05 >/dev/null; docker image rm pfjd-sftp:humo >/dev/null; echo limpio

# --- 2026-10-05T16:28:29 · Update co05 output and mark tested
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs; python3 - <<'EOF'
f='op019-co05-transferencia-de-archivos.md'; t=open(f,encoding='utf-8').read()
OLD='> Versiones verificadas contra PyPI el 05/10/2026 · Código escrito sin ejecutar: las salidas\n> rotuladas «Salida esperada, sin correr» no salen de una corrida.'
NEW='> Versiones verificadas contra PyPI el 05/10/2026 · Código probado el 05/10/2026 con Python 3.14.7,\n> en contenedor, contra un servidor SFTP de OpenSSH: la descarga, la segunda corrida, la retoma desde\n> un `.part` cortado y el archivo reemplazado. El fragmento de FTPS queda sin ejecutar.'
assert OLD in t; t=t.replace(OLD,NEW).replace("Salida esperada, sin correr:","Salida (Python 3.14.7, 05/10/2026):")
t=t.replace("bajado pagos-septiembre.csv (48213 bytes, sha256 3f0c9a1d2b7e…)","bajado pagos-septiembre.csv (48213 bytes, sha256 5088ecd4b1b2…)")
t=t.replace("bajado pagos-octubre-1.csv (12002 bytes, sha256 a81d6e0f44c9…)","bajado pagos-octubre-1.csv (12002 bytes, sha256 e5f48a0965af…)")
open(f,'w',encoding='utf-8').write(t)
EOF
grep -n "5088ecd4b1b2\|e5f48a0965af" op019-*.md | head -3; python3 -B prompts/verificar-corpus.py | grep -v "EMOJI\|BENCHMARKS" | tail -2; python3 ../../zz-code/python-for-java-devs-20261005-f516/verificar_urls.py op019-*.md

# --- 2026-10-05T16:29:41 · Smoke-test co06 and check its URLs
cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516; python3 humo.py op020-co06-mensajeria.md co06 'notificar.py="""Un notificador' --pip httpx==0.28.1 --cmd "python notificar.py"; for u in https://docs.slack.dev/messaging/sending-messages-using-incoming-webhooks/ https://core.telegram.org/bots/api https://www.twilio.com/docs/whatsapp/tutorial/send-whatsapp-notification-messages-templates "https://www.suin-juriscol.gov.co/viewDocument.asp?ruta=Leyes/1684507"; do curl -s -o /dev/null -m 30 -w "%{http_code} $u\n" -L -A "Mozilla/5.0" "$u"; done

# --- 2026-10-05T16:29:54 · Verify the SUIN URL is Ley 1581
curl -s -m 30 -A "Mozilla/5.0" "https://www.suin-juriscol.gov.co/viewDocument.asp?ruta=Leyes/1684507" | python3 -c "import sys,re,html; t=html.unescape(sys.stdin.read()); m=re.search(r'LEY\s+1581\s+DE\s+2012',t,re.I); print('contiene LEY 1581 DE 2012' if m else 'NO es la 1581'); print(re.sub(r'\s+',' ',re.sub('<[^>]+>',' ',t))[:200])"

# --- 2026-10-05T16:30:00 · Verify Función Pública URL for Ley 1581
curl -s -m 30 -A "Mozilla/5.0" "https://www.funcionpublica.gov.co/eva/gestornormativo/norma.php?i=49981" | python3 -c "import sys,re,html; t=html.unescape(sys.stdin.read()); m=re.search(r'Ley\s+1581\s+de\s+2012',t,re.I); print('contiene' if m else 'NO', '|', re.search(r'<title>(.*?)</title>',t,re.S).group(1).strip()[:120] if '<title>' in t else '')"

# --- 2026-10-05T16:30:08 · Fix law link and output, mark co06
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs; python3 - <<'EOF'
f='op020-co06-mensajeria.md'; t=open(f,encoding='utf-8').read()
a='''- Ley 1581 de 2012 (habeas data), en el Sistema Único de Información Normativa:
  https://www.suin-juriscol.gov.co/viewDocument.asp?ruta=Leyes/1684507'''
b='''- Ley 1581 de 2012 (habeas data), en el gestor normativo de Función Pública:
  https://www.funcionpublica.gov.co/eva/gestornormativo/norma.php?i=49981'''
assert a in t; t=t.replace(a,b)
a='''hooks.slack.com ← {"text":"\\u274c El cierre nocturno fall\\u00f3 en la sede Suba a las 02:47"}
api.twilio.com ← From=whatsapp%3A%2B5716000000&To=whatsapp%3A%2B573001234567&ContentSid=HX0001&Content'''
b='''hooks.slack.com ← {"text":"❌ El cierre nocturno falló en la sede Suba a las 02:47"}
api.twilio.com ← From=whatsapp%3A%2B5716000000&To=whatsapp%3A%2B573001234567&ContentSid=HX0001&ContentVaria'''
assert a in t, "salida"; t=t.replace(a,b)
open(f,'w',encoding='utf-8').write(t)
EOF
cd ../../zz-code/python-for-java-devs-20261005-f516; python3 probado.py op020-co06-mensajeria.md; cd ../../cursos-algoritmos-lenguajes/python-for-java-devs; python3 -B prompts/verificar-corpus.py | grep -v "EMOJI\|BENCHMARKS" | tail -2

# --- 2026-10-05T16:30:15 · Locate output and link lines in co06
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs; grep -n "hooks.slack.com ←\|api.twilio.com ←\|suin-juriscol\|Sistema Único" op020-co06-mensajeria.md

# --- 2026-10-05T16:30:22 · Apply co06 output and link fixes
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs; python3 - <<'EOF'
f='op020-co06-mensajeria.md'; t=open(f,encoding='utf-8').read()
a='ContentSid=HX0001&Content\n'; assert t.count(a)==1; t=t.replace(a,'ContentSid=HX0001&ContentVaria\n')
a='''- Ley 1581 de 2012 (habeas data), en el Sistema Único de Información Normativa:
  https://www.suin-juriscol.gov.co/viewDocument.asp?ruta=Leyes/1684507'''
assert a in t; t=t.replace(a,'''- Ley 1581 de 2012 (habeas data), en el gestor normativo de Función Pública:
  https://www.funcionpublica.gov.co/eva/gestornormativo/norma.php?i=49981''')
open(f,'w',encoding='utf-8').write(t)
EOF
sed -n 165,170p op020-co06-mensajeria.md; python3 ../../zz-code/python-for-java-devs-20261005-f516/verificar_urls.py op020-*.md

# --- 2026-10-05T16:31:17 · Smoke-test co07 classification
cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516; python3 humo.py op021-co07-veredicto.md co07 'canales.py="""Clasifica los envíos' --cmd "python canales.py"

# --- 2026-10-05T16:31:24 · Fix co07 percentage, mark and run T3 checks
cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516; sed -i '' 's/      18 envíos al mes (0.5%)/      18 envíos al mes (0.4%)/' ../../cursos-algoritmos-lenguajes/python-for-java-devs/op021-co07-veredicto.md; python3 probado.py op021-co07-veredicto.md; cd ../../cursos-algoritmos-lenguajes/python-for-java-devs; grep -c "18 envíos al mes (0.4%)" op021-co07-veredicto.md; python3 -B prompts/check-inventario.py co | tail -1; python3 -B prompts/verificar-corpus.py | grep -v "EMOJI\|BENCHMARKS" | tail -2; python3 ../../zz-code/python-for-java-devs-20261005-f516/verificar_urls.py op021-*.md; wc -l op015* op016* op017* op018* op019* op020* op021* | tail -1; docker ps -a --filter label=curso=python-for-java-devs -q | wc -l; docker network ls --filter label=curso=python-for-java-devs -q | wc -l

# --- 2026-10-05T16:31:41 · Close T3 in production plan
cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516; python3 plan.py 15 21 ✅ ✅; python3 plan.py 19 19 ✅ 🟡; python3 plan.py tanda T3 ✅; python3 plan.py dondeesta "(05/10/2026).** T1–T3 (\`lg\`, \`au\`, \`co\`) cerradas; T4 (\`wf\`) en curso."; python3 plan.py bitacora "**2026-10-05 · T3 (\`co\`) cerrada.** Escritas op015–op021 (2.058 líneas, 68 ejercicios). Pruebas de humo: seis completas y \`co05\` en parte (el fragmento FTPS sin correr). Servicios reales en contenedor, en redes privadas y borrados al terminar: **GreenMail 2.1.14** (IMAP de \`co03\`), **Mailpit v1.31.4** (\`co04\`) y un **SFTP de OpenSSH** (\`co05\`, con retoma desde \`.part\` y archivo reemplazado). **Defectos propios encontrados:** \`prefetch\` de Paramiko recibe el tamaño total, no lo que falta (\`co05\`: al retomar no habría pedido el final); comparación de sede con tilde contra nombre de archivo sin tilde (\`co01\`); porcentaje 0,5 → 0,4 (\`co07\`). **Correcciones de narrativa:** \`co01\` usaba una sede «Chía» y una franquiciada inventadas (la historia no las tiene): ahora Zipaquirá, sin persona; y \`au05\` (T2) usaba la clave \`zipaquira\` para la franquicia de Google Calendar, que según la historia es otra sede: ahora \`sede-calendar\`. **Hallazgos:** \`aiosmtpd\` necesita \`python -u\` para escribir su registro redirigido (va en \`co04\`); la cifra de la propuesta «el correo gana en el 60% de los casos» no tenía medición: \`co07\` la reemplaza por la cuenta por tipo y por volumen (50% y 2%). URL: SUIN carga la ley por JavaScript y no se pudo verificar; se enlaza la Ley 1581 en Función Pública (verificada con \`curl\`; \`urllib\` rechaza su cadena de certificados). **Imágenes descargadas y borradas:** \`greenmail/standalone:2.1.14\`, \`axllent/mailpit:v1.31.4\`, \`pfjd-sftp:humo\`. **Tags:** \`op-co-fase-01\` … \`op-co-fase-07\`. **Siguiente:** T4 (\`wf\`)."; grep -n "\*\*T3\*\*" ../../cursos-algoritmos-lenguajes/python-for-java-devs/prompts/plan-de-produccion-carta.md

# --- 2026-10-05T16:31:50 · Update memory, show wf versions and Fase 15 outline
sed -i '' 's/; T1 lg cerrada\./; T1–T3 (lg, au, co) cerradas el 05\/10\/2026./' /Users/oskar/.claude/projects/-Users-oskar-Developer-Learning-courses-ia-generated/memory/MEMORY.md; cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs; sed -n '/^## `wf`/,/^## `qa`/p' prompts/inventario-verificado.md; grep -n "^## \|^### " 15-el-proceso-nocturno.md | head -30

# --- 2026-10-05T16:31:53 · Read Fase 15 scheduler and translation sections
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs; sed -n 448,494p 15-el-proceso-nocturno.md; sed -n 195,215p 15-el-proceso-nocturno.md

# --- 2026-10-05T16:32:56 · Smoke-test wf01 graph runner twice
cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516; python3 humo.py op022-wf01-el-eje.md wf01 'noche.py="""La noche de Áurea' --cmd "python noche.py; python noche.py | tail -7 | head -6"

# --- 2026-10-05T16:33:05 · Update wf01 order and mark tested
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs; python3 - <<'EOF'
f='op022-wf01-el-eje.md'; t=open(f,encoding='utf-8').read()
a='''consolidar_rips      ok
radicar              falló: el portal de la aseguradora no responde
regalias             ok
'''
b='''consolidar_rips      ok
regalias             ok
radicar              falló: el portal de la aseguradora no responde
'''
assert a in t; t=t.replace(a,b)
t=t.replace("Salida esperada, sin correr (el orden de los trabajos del mismo nivel puede variar):","Salida esperada, sin correr (el orden de los trabajos del mismo nivel puede variar entre corridas):")
open(f,'w',encoding='utf-8').write(t)
EOF
cd ../../zz-code/python-for-java-devs-20261005-f516; python3 probado.py op022-wf01-el-eje.md; cd ../../cursos-algoritmos-lenguajes/python-for-java-devs; python3 -B prompts/verificar-corpus.py | grep -v "EMOJI\|BENCHMARKS" | tail -1; python3 ../../zz-code/python-for-java-devs-20261005-f516/verificar_urls.py op022-*.md

# --- 2026-10-05T16:33:19 · Find Valkey image tag and redis client version
curl -s "https://hub.docker.com/v2/repositories/valkey/valkey/tags?page_size=8&ordering=last_updated" | python3 -c "import json,sys;[print(t['name'],t['last_updated'][:10]) for t in json.load(sys.stdin)['results']]"; cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs; grep -n '`redis`\|`valkey`' prompts/inventario-verificado.md | head -3

# --- 2026-10-05T16:34:27 · Smoke-test RQ with Valkey and Huey with SQLite
cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516; python3 humo.py op023-wf02-colas-de-tareas.md wf02 'tareas.py="""La tarea: generar' 'encolar_rq.py="""Encola las liquidaciones' 'cola_huey.py="""La misma tarea en Huey' >/dev/null; S=$PWD/salidas/wf02; docker network create --label curso=python-for-java-devs pfjd-wf02 >/dev/null; docker run -d --rm --label curso=python-for-java-devs --network pfjd-wf02 --name pfjd-valkey valkey/valkey:9.0.6-alpine >/dev/null 2>&1; sleep 2; docker run --rm --label curso=python-for-java-devs --network pfjd-wf02 -v $S:/w -w /w -e PYTHONPATH=/w python:3.14.7 sh -c "pip install -q --root-user-action=ignore rq==2.12.0 huey==3.4.0 >/dev/null 2>&1; rm -rf liquidaciones intentos.log cola.db; echo '--- RQ'; (rq worker liquidaciones --url redis://pfjd-valkey:6379 --with-scheduler > worker.log 2>&1 &); REDIS_URL=redis://pfjd-valkey:6379 timeout 60 python encolar_rq.py; echo '--- Huey'; (huey_consumer cola_huey.huey --workers 2 > huey.log 2>&1 &); sleep 1; timeout 60 python -c \"
from cola_huey import build_settlement_pdf
results = [build_settlement_pdf(s, '2026T4') for s in ('Suba', 'Zipaquirá')]
print([r.get(blocking=True, timeout=30) for r in results])\"; echo '--- intentos'; sort intentos.log | uniq -c"; docker rm -f -v pfjd-valkey >/dev/null 2>&1; docker network rm pfjd-wf02 >/dev/null; echo limpio

# --- 2026-10-05T16:34:52 · Test RQ burst worker without scheduler
S=/Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516/salidas/wf02; docker network create --label curso=python-for-java-devs pfjd-wf02 >/dev/null; docker run -d --rm --label curso=python-for-java-devs --network pfjd-wf02 --name pfjd-valkey valkey/valkey:9.0.6-alpine >/dev/null 2>&1; sleep 2; docker run --rm --label curso=python-for-java-devs --network pfjd-wf02 -v $S:/w -w /w -e PYTHONPATH=/w python:3.14.7 sh -c "pip install -q --root-user-action=ignore rq==2.12.0 >/dev/null 2>&1; rm -rf liquidaciones intentos.log; (REDIS_URL=redis://pfjd-valkey:6379 timeout 25 python encolar_rq.py > productor.log 2>&1 &); sleep 1; rq worker liquidaciones --url redis://pfjd-valkey:6379 --burst 2>&1 | grep -i 'retry\|schedul\|Suba\|finished\|failed' | head -8; sleep 26; echo '--- productor'; cat productor.log | tail -3"; docker rm -f -v pfjd-valkey >/dev/null 2>&1; docker network rm pfjd-wf02 >/dev/null; docker image rm valkey/valkey:9.0.6-alpine >/dev/null 2>&1; echo limpio

# --- 2026-10-05T16:35:40 · Fix RQ scheduler issue in wf02 and verify
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs; python3 - <<'EOF'
f='op023-wf02-colas-de-tareas.md'; t=open(f,encoding='utf-8').read()
rep=[
('''rq worker liquidaciones --url redis://127.0.0.1:6379 --burst &   # --burst: termina cuando la cola se vacía''',
 '''rq worker liquidaciones --url redis://127.0.0.1:6379 --with-scheduler &   # el planificador hace los reintentos con espera'''),
('''Suba finished generado liquidacion-suba-2026T3.pdf
Zipaquirá finished generado liquidacion-zipaquirá-2026T3.pdf''','''Suba JobStatus.FINISHED generado liquidacion-suba-2026T3.pdf
Zipaquirá JobStatus.FINISHED generado liquidacion-zipaquirá-2026T3.pdf'''),
('''- **`--burst`** hace que el *worker* termine cuando la cola se vacía, que es lo que se quiere en un
  proceso nocturno lanzado por `cron`; un *worker* permanente va bajo `systemd`.''','''- **`--with-scheduler`** arranca, junto al *worker*, el planificador que mueve las tareas programadas
  —los reintentos con espera— a la cola cuando les toca. Sin él, `Retry(interval=…)` deja la tarea
  esperando para siempre (§4).'''),
('''**Encolar objetos que no se pueden serializar.**''','''**El reintento que nunca llega.** En RQ, un reintento con `interval` no vuelve a la cola: queda
**programado**, y lo mueve el planificador. La primera versión de esta sección arrancaba el *worker*
con `--burst` —que termina cuando la cola se vacía— y sin `--with-scheduler`. En la prueba, Suba falló,
su reintento quedó programado, el *worker* vio la cola vacía y se fue, y el productor se quedó
esperando sin ningún error. El *worker* que procesa reintentos con espera lleva planificador y no es
`--burst`.

**Encolar objetos que no se pueden serializar.**'''),
]
for a,b in rep:
    assert a in t,a[:50]; t=t.replace(a,b)
OLD='> Versiones verificadas contra PyPI el 05/10/2026 · Código escrito sin ejecutar: las salidas\n> rotuladas «Salida esperada, sin correr» no salen de una corrida.'
NEW='> Versiones verificadas contra PyPI el 05/10/2026 · Código probado el 05/10/2026 con Python 3.14.7,\n> en contenedor: RQ contra Valkey 9.0.6 (en una red privada) y Huey sobre SQLite.'
assert OLD in t; t=t.replace(OLD,NEW).replace("Salida esperada, sin correr:","Salida (Python 3.14.7, 05/10/2026):")
open(f,'w',encoding='utf-8').write(t)
EOF
python3 -B prompts/verificar-corpus.py | grep -v "EMOJI\|BENCHMARKS" | tail -1; python3 ../../zz-code/python-for-java-devs-20261005-f516/verificar_urls.py op023-*.md

# --- 2026-10-05T16:36:47 · Smoke-test wf03 twice and schedule tz
cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516; python3 humo.py op024-wf03-programacion-en-proceso.md wf03 'agenda_cache.py="""Dos réplicas' --pip apscheduler==3.11.3 schedule==1.2.2 --cmd "python agenda_cache.py; echo ---; python agenda_cache.py; echo ---; python -c \"
import schedule
j = schedule.every().day.at('08:00', 'America/Bogota').do(print)
print(j.next_run)\""

# --- 2026-10-05T16:37:02 · Check pytz and retest schedule tz
curl -s https://pypi.org/pypi/pytz/json | python3 -c "import json,sys;d=json.load(sys.stdin);v=d['info']['version'];print(v,d['releases'][v][0]['upload_time'][:10])"; cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs; python3 - <<'EOF'
p='prompts/check-inventario.py'; t=open(p,encoding='utf-8').read()
a='"APScheduler", "schedule",'; assert a in t; open(p,'w',encoding='utf-8').write(t.replace(a,'"APScheduler", "schedule", "pytz",'))
EOF
docker run --rm --label curso=python-for-java-devs python:3.14.7 sh -c "pip install -q --root-user-action=ignore schedule==1.2.2 pytz >/dev/null 2>&1; python -c \"
import schedule
j = schedule.every().day.at('08:00', 'America/Bogota').do(print)
print(type(j.next_run).__name__, j.next_run.tzinfo)\""

# --- 2026-10-05T16:37:15 · Add pytz trap to wf03 and mark tested
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs; python3 - <<'EOF'
f='op024-wf03-programacion-en-proceso.md'; t=open(f,encoding='utf-8').read()
a='''`schedule` es legible y no tiene hilos propios: corre en el bucle que tú escribes. A cambio, no tiene
`coalesce`, ni `max_instances`, ni persistencia. Está quieto desde mayo de 2024, y para lo que hace —un
bucle con horarios— casi no necesita cambiar.'''
b='''`schedule` es legible y no tiene hilos propios: corre en el bucle que tú escribes. A cambio, no tiene
`coalesce`, ni `max_instances`, ni persistencia. Está quieto desde mayo de 2024, y para lo que hace —un
bucle con horarios— casi no necesita cambiar.

> ⚠️ **La zona horaria de `schedule` necesita `pytz`, y no lo declara.** `.at("08:00",
> "America/Bogota")` importa `pytz` por dentro, pero el paquete no lo instala: sin él, la línea falla
> con `ModuleNotFoundError: No module named 'pytz'`. Lo encontró la prueba de esta sección. La
> instalación es `uv add schedule pytz` (`pytz` 2026.5, del 2026-10-04).'''
assert a in t; t=t.replace(a,b)
OLD='> Versiones verificadas contra PyPI el 05/10/2026 · Código escrito sin ejecutar: las salidas\n> rotuladas «Salida esperada, sin correr» no salen de una corrida.'
NEW='> Versiones verificadas contra PyPI el 05/10/2026 · Código probado el 05/10/2026 con Python 3.14.7,\n> en contenedor: las dos réplicas con APScheduler, y la zona horaria de `schedule`.'
assert OLD in t; t=t.replace(OLD,NEW).replace("Salida esperada, sin correr:","Salida (Python 3.14.7, 05/10/2026):")
open(f,'w',encoding='utf-8').write(t)
EOF
python3 -B prompts/check-inventario.py wf | tail -1; python3 -B prompts/verificar-corpus.py | grep -v "EMOJI\|BENCHMARKS" | tail -1; python3 ../../zz-code/python-for-java-devs-20261005-f516/verificar_urls.py op024-*.md

# --- 2026-10-05T16:38:29 · Install Airflow 3.3.2 and run dags test
cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516; mkdir -p salidas/wf04/dags; python3 humo.py op025-wf04-airflow.md wf04 'dags/noche_aurea.py="""La noche de Áurea como DAG' >/dev/null; ls salidas/wf04/dags; docker run --rm --label curso=python-for-java-devs -v $PWD/salidas/wf04:/w -w /w python:3.14.7 sh -c "pip install -q --root-user-action=ignore 'apache-airflow==3.3.2' > pip.log 2>&1; echo pip=\$?; tail -3 pip.log; export AIRFLOW_HOME=/w/airflow-home AIRFLOW__CORE__DAGS_FOLDER=/w/dags AIRFLOW__CORE__LOAD_EXAMPLES=False; airflow version; airflow db migrate > migrate.log 2>&1; echo migrate=\$?; airflow dags test noche_aurea 2026-10-05 > test.log 2>&1; echo test=\$?; grep -E 'success|radicadas|DagRun|ERROR|Error' test.log | head -20" > salidas/wf04/humo.out 2>&1; cat salidas/wf04/humo.out | tail -30

# --- 2026-10-05T16:39:25 · Read Airflow smoke test output
cat /private/tmp/claude-501/-Users-oskar-Developer-Learning-courses-ia-generated/5c52573d-4a56-4998-bca3-5d686d0c5368/tasks/bq1g8nvst.output | tail -30

# --- 2026-10-05T16:39:44 · Fix Airflow 3 interval semantics and real output
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs; python3 - <<'EOF'
f='op025-wf04-airflow.md'; t=open(f,encoding='utf-8').read()
rep=[
('''- **La fecha lógica y el intervalo de datos.** Cada ejecución corresponde a un intervalo —"la noche
  del 4 al 5 de octubre"— y la tarea recibe ese intervalo. La tarea correcta procesa **su** intervalo,
  no "lo que haya hoy": así, relanzar la ejecución de anteayer procesa los datos de anteayer.''',
'''- **La fecha lógica.** Cada ejecución tiene una fecha lógica —"la noche del 5 de octubre"— y la tarea
  la recibe. La tarea correcta procesa **su** fecha, no "lo que haya hoy": así, relanzar la ejecución
  de anteayer procesa los datos de anteayer. En Airflow 3, un `schedule` escrito como expresión `cron`
  usa por defecto un *timetable* de disparo: el intervalo de datos se reduce a un punto
  (`data_interval_start` igual a `data_interval_end`), que es un cambio respecto de Airflow 2, donde
  cada ejecución cubría el intervalo anterior. Si tus tareas razonan en intervalos, eso se configura
  explícitamente.'''),
('''Salida esperada, sin correr (resumida: Airflow escribe varias líneas por tarea):

```text
... Task instance in success state ... task_id=consolidar ...
... Task instance in success state ... task_id=radicar ...
... Task instance in success state ... task_id=regalias ...
radicadas 12, liquidaciones 6
... Task instance in success state ... task_id=informe ...
... DagRun Finished: dag_id=noche_aurea, logical_date=2026-10-05 ... state=success ...
```''','''Salida (Python 3.14.7, 05/10/2026), recortada: Airflow escribe varias líneas por tarea.

```text
... get next_dagrun_info_v2 ... run_after=DateTime(2026, 10, 5, 7, 0, 0, tzinfo=Timezone('UTC')) ...
... Task instance state updated ... new_state=success ...
... Task instance state updated ... new_state=success ...
... Task instance state updated ... new_state=success ...
radicadas 12, liquidaciones 6
... Task instance state updated ... new_state=success ...
... DagRun Finished: dag_id=noche_aurea, logical_date=2026-10-05 00:00:00+00:00, ... state=success,
    ... data_interval_start=2026-10-05 00:00:00+00:00, data_interval_end=2026-10-05 00:00:00+00:00
```

Dos datos que da esta salida y que valen la sección: la próxima ejecución programada es a las
**07:00 UTC, que son las 2:00 de Bogotá** —el `start_date` con zona hizo su trabajo—, y el intervalo de
datos empieza y termina en el mismo instante, que es la semántica de Airflow 3 descrita en §2.'''),
]
for a,b in rep:
    assert a in t,a[:50]; t=t.replace(a,b)
OLD='> Versiones verificadas contra PyPI el 05/10/2026 · Código escrito sin ejecutar: las salidas\n> rotuladas «Salida esperada, sin correr» no salen de una corrida.'
NEW='> Versiones verificadas contra PyPI el 05/10/2026 · Código probado el 05/10/2026 con Python 3.14.7,\n> en contenedor: `airflow db migrate` y `airflow dags test` con Airflow 3.3.2 y SQLite.'
assert OLD in t; t=t.replace(OLD,NEW)
open(f,'w',encoding='utf-8').write(t)
EOF
python3 -B prompts/verificar-corpus.py | grep -v "EMOJI\|BENCHMARKS" | tail -1; python3 ../../zz-code/python-for-java-devs-20261005-f516/verificar_urls.py op025-*.md op026-*.md

# --- 2026-10-05T16:39:58 · Smoke-test Prefect and Dagster flows
cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516; python3 humo.py op026-wf05-prefect-y-dagster.md wf05 'noche_prefect.py="""La noche de Áurea en Prefect' 'noche_dagster.py="""La noche de Áurea en Dagster' >/dev/null; S=$PWD/salidas/wf05; docker run --rm --label curso=python-for-java-devs -v $S:/w -w /w python:3.14.7 sh -c "pip install -q --root-user-action=ignore prefect==3.8.7 > pip-p.log 2>&1; echo pip=\$?; timeout 240 python noche_prefect.py 2>&1 | grep -E 'Retry|radicadas|Finished|Error|error' | cut -c1-230 | head -8" ; docker run --rm --label curso=python-for-java-devs -v $S:/w -w /w python:3.14.7 sh -c "pip install -q --root-user-action=ignore dagster==1.13.25 > pip-d.log 2>&1; echo pip=\$?; timeout 240 python noche_dagster.py 2>/dev/null | tail -3"

# --- 2026-10-05T16:40:56 · Update wf05 with real Prefect output and mark
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs; python3 - <<'EOF'
f='op026-wf05-prefect-y-dagster.md'; t=open(f,encoding='utf-8').read()
a='''Salida esperada, sin correr (resumida: Prefect registra el inicio y el fin de cada tarea):

```text
... Task run 'radicar-…' - Task run failed with exception: ConnectionError('el portal de la aseguradora no responde') - Retry 1/2 will start 1 second(s) from now
... radicadas 12, liquidaciones 6
... Finished in state Completed()
radicadas 12, liquidaciones 6
```'''
b='''Salida (Python 3.14.7, 05/10/2026), filtrada a las líneas que importan:

```text
16:40:29.217 | INFO | Task run 'consolidar-723' - Finished in state Completed()
16:40:29.219 | INFO | Task run 'radicar-ec9' - Task run failed with exception: ConnectionError('el portal de la aseguradora no responde') - Retry 1/2 will start 1 second(s) from now
16:40:29.220 | INFO | Task run 'regalias-4b3' - Finished in state Completed()
16:40:30.232 | INFO | Task run 'radicar-ec9' - Finished in state Completed()
16:40:30.236 | INFO | Flow run 'tall-quokka' - radicadas 12, liquidaciones 6
16:40:31.219 | INFO | Flow run 'tall-quokka' - Finished in state Completed()
radicadas 12, liquidaciones 6
```

Fíjate en las marcas de tiempo: `regalias` terminó mientras `radicar` esperaba su reintento —las dos
corrían a la vez gracias a `.submit`—, y el reintento llegó un segundo después, como se pidió.'''
assert a in t; t=t.replace(a,b)
OLD='> Versiones verificadas contra PyPI el 05/10/2026 · Código escrito sin ejecutar: las salidas\n> rotuladas «Salida esperada, sin correr» no salen de una corrida.'
NEW='> Versiones verificadas contra PyPI el 05/10/2026 · Código probado el 05/10/2026 con Python 3.14.7,\n> en contenedor: Prefect 3.8.7 y Dagster 1.13.25, sin servidor.'
assert OLD in t; t=t.replace(OLD,NEW).replace("Salida esperada, sin correr (sin las líneas de registro de Dagster):","Salida (Python 3.14.7, 05/10/2026), sin las líneas de registro de Dagster:")
open(f,'w',encoding='utf-8').write(t)
EOF
python3 -B prompts/verificar-corpus.py | grep -v "EMOJI\|BENCHMARKS" | tail -1

# --- 2026-10-05T16:42:07 · Smoke-test Temporal workflow with time skipping
cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516; python3 humo.py op027-wf06-temporal.md wf06 'aprobacion.py="""La aprobación trimestral' 'prueba_aprobacion.py="""Dos trimestres' --pip temporalio==1.34.0 --cmd "timeout 300 python prueba_aprobacion.py"

# --- 2026-10-05T16:42:22 · Mark wf06 tested and verify URLs
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs; python3 - <<'EOF'
f='op027-wf06-temporal.md'; t=open(f,encoding='utf-8').read()
a='''El segundo trimestre "esperó" diez días en una fracción de segundo:'''
b='''Antes de esas líneas, el servidor de pruebas imprime un aviso (`WARN … heartbeat details may be lost
on failure`): el servidor que descarga el entorno de pruebas es más viejo que lo que el SDK espera para
una función que este ejemplo no usa, y no afecta al resultado.

El segundo trimestre "esperó" diez días en una fracción de segundo:'''
assert a in t; t=t.replace(a,b)
OLD='> Versiones verificadas contra PyPI el 05/10/2026 · Código escrito sin ejecutar: las salidas\n> rotuladas «Salida esperada, sin correr» no salen de una corrida.'
NEW='> Versiones verificadas contra PyPI el 05/10/2026 · Código probado el 05/10/2026 con Python 3.14.7,\n> en contenedor, con el entorno de pruebas de Temporal que salta el tiempo.'
assert OLD in t; t=t.replace(OLD,NEW).replace("Salida esperada, sin correr (la primera vez, el entorno descarga el servidor de pruebas de Temporal):","Salida (Python 3.14.7, 05/10/2026); la primera vez, el entorno descarga el servidor de pruebas de Temporal:")
open(f,'w',encoding='utf-8').write(t)
EOF
python3 -B prompts/verificar-corpus.py | grep -v "EMOJI\|BENCHMARKS" | tail -1; python3 ../../zz-code/python-for-java-devs-20261005-f516/verificar_urls.py op027-*.md

# --- 2026-10-05T16:43:42 · Neutralize franchise names and smoke-test wf07
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs; python3 - <<'EOF'
f='op028-wf07-lo-transversal.md'; t=open(f,encoding='utf-8').read()
a='FRANCHISES = ["Suba", "Zipaquirá", "Kennedy", "Usaquén", "Engativá", "Fontibón"]'
b='# La historia de Áurea nombra dos de las seis franquicias; las otras cuatro van sin nombre.\nFRANCHISES = ["Suba", "Zipaquirá", "franquicia-3", "franquicia-4", "franquicia-5", "franquicia-6"]'
assert a in t; t=t.replace(a,b)
for old,new in [("Kennedy","franquicia-3"),("Usaquén","franquicia-4"),("Engativá","franquicia-5"),("Fontibón","franquicia-6")]:
    t=t.replace(f"pid-100: {old} facturada",f"pid-100: {new} facturada").replace(f"pid-102: {old} facturada",f"pid-102: {new} facturada").replace(f"pid-99: {old} ya estaba",f"pid-99: {new} ya estaba").replace(f"pid-99: {old} facturada",f"pid-99: {new} facturada")
open(f,'w',encoding='utf-8').write(t)
EOF
grep -c "Kennedy\|Usaquén\|Engativá\|Fontibón" op028-wf07-lo-transversal.md; cd ../../zz-code/python-for-java-devs-20261005-f516; python3 humo.py op028-wf07-lo-transversal.md wf07 'ejecuciones.py="""Ejecuciones con clave' --cmd "python ejecuciones.py"

# --- 2026-10-05T16:43:55 · Flush before crash and rerun wf07
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs; python3 - <<'EOF'
f='op028-wf07-lo-transversal.md'; t=open(f,encoding='utf-8').read()
a='''            print(f"{owner}: se cae a la mitad")
            os._exit(1)                         # sin limpiar nada: como un kill -9'''
b='''            print(f"{owner}: se cae a la mitad", flush=True)
            os._exit(1)                         # sin limpiar nada: como un kill -9'''
assert a in t; t=t.replace(a,b)
a='''        print(f"{owner}: {franchise} {'facturada' if written else 'ya estaba'}")'''
b='''        # flush: os._exit no vacía el búfer, y sin esto lo que imprimió la copia que se cae se pierde.
        print(f"{owner}: {franchise} {'facturada' if written else 'ya estaba'}", flush=True)'''
assert a in t; t=t.replace(a,b)
open(f,'w',encoding='utf-8').write(t)
EOF
cd ../../zz-code/python-for-java-devs-20261005-f516; python3 humo.py op028-wf07-lo-transversal.md wf07 'ejecuciones.py="""Ejecuciones con clave' --cmd "python ejecuciones.py" | sed -n 9,14p

# --- 2026-10-05T16:44:08 · Mark wf07 and read measurement format
cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516; python3 probado.py op028-wf07-lo-transversal.md; cd ../../cursos-algoritmos-lenguajes/python-for-java-devs; python3 -B prompts/verificar-corpus.py | grep -v "EMOJI\|BENCHMARKS" | tail -1; python3 ../../zz-code/python-for-java-devs-20261005-f516/verificar_urls.py op028-*.md; sed -n 1,60p prompts/formato-de-mediciones.md | head -60

# --- 2026-10-05T16:45:09 · Partial test of wf08 harness and T4 checks
cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516; python3 humo.py op029-wf08-veredicto.md wf08 'memoria_en_reposo.py="""Memoria en reposo' --cmd "(sleep 30 &); python -c \"import memoria_en_reposo as m; print(round(m.process_rss_mb('sleep 30'),1), 'MB'); print(m.container_mb.__doc__)\"" | head -3; cd ../../cursos-algoritmos-lenguajes/python-for-java-devs; python3 -B prompts/verificar-corpus.py | grep -v "EMOJI\|BENCHMARKS" | tail -1; python3 ../../zz-code/python-for-java-devs-20261005-f516/verificar_urls.py op029-*.md; wc -l op022* op023* op024* op025* op026* op027* op028* op029* | tail -1; docker ps -a --filter label=curso=python-for-java-devs -q | wc -l

# --- 2026-10-05T16:45:25 · Mark wf08 partial and close T4
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs; python3 - <<'EOF'
f='op029-wf08-veredicto.md'; t=open(f,encoding='utf-8').read()
OLD='> Versiones verificadas contra PyPI el 05/10/2026 · Código escrito sin ejecutar: las salidas\n> rotuladas «Salida esperada, sin correr» no salen de una corrida.'
NEW='> Versiones verificadas contra PyPI el 05/10/2026 · Código probado en parte el 05/10/2026 con\n> Python 3.14.7, en contenedor: la suma de memoria de procesos; la de contenedores y la medición\n> entera quedan sin ejecutar (`⏳`), y las salidas rotuladas «Salida esperada, sin correr» lo dicen.'
assert OLD in t; open(f,'w',encoding='utf-8').write(t.replace(OLD,NEW))
EOF
cd ../../zz-code/python-for-java-devs-20261005-f516; python3 plan.py 22 29 ✅ ✅; python3 plan.py 29 29 ✅ 🟡; python3 plan.py tanda T4 ✅; python3 plan.py dondeesta "(05/10/2026).** T1–T4 (\`lg\`, \`au\`, \`co\`, \`wf\`) cerradas; T5 (\`qa\`) en curso."; python3 plan.py bitacora "**2026-10-05 · T4 (\`wf\`) cerrada.** Escritas op022–op029 (2.366 líneas, 78 ejercicios). Pruebas de humo: siete completas y \`wf08\` en parte (su medición queda en \`⏳\` con especificación completa, como el resto del curso). Corrieron de verdad, en contenedor: RQ contra **Valkey 9.0.6** y Huey sobre SQLite (\`wf02\`), APScheduler y \`schedule\` (\`wf03\`), **Airflow 3.3.2** con \`airflow dags test\` sobre Python 3.14 (\`wf04\`), Prefect 3.8.7 y Dagster 1.13.25 (\`wf05\`), y Temporal con el entorno que salta el tiempo (\`wf06\`). **Defectos propios encontrados:** el *worker* de RQ con \`--burst\` y sin \`--with-scheduler\` dejaba el reintento programado para siempre y el productor colgado (\`wf02\`, ahora es su trampa principal); \`get_status()\` devuelve el enum; la zona horaria de \`schedule\` necesita \`pytz\` y no lo declara (\`wf03\`, agregado al inventario); la semántica del intervalo de datos que describí era la de Airflow 2 —en Airflow 3 un \`cron\` usa *timetable* de disparo e intervalo puntual— (\`wf04\`); \`os._exit\` perdía la salida de la copia que se cae (\`wf07\`). **Narrativa:** \`wf07\` llamaba franquicias a cuatro sedes que la historia no identifica como tales; ahora van sin nombre. **Imágenes descargadas y borradas:** \`valkey/valkey:9.0.6-alpine\`. **Tags:** \`op-wf-fase-01\` … \`op-wf-fase-08\`. **Siguiente:** T5 (\`qa\`)."; sed -i '' 's/T1–T3 (lg, au, co) cerradas el 05\/10\/2026\./T1–T4 (lg, au, co, wf) cerradas el 05\/10\/2026./' /Users/oskar/.claude/projects/-Users-oskar-Developer-Learning-courses-ia-generated/memory/MEMORY.md; grep -n "\*\*T4\*\*" ../../cursos-algoritmos-lenguajes/python-for-java-devs/prompts/plan-de-produccion-carta.md

# --- 2026-10-05T16:45:32 · Outline Fase 08 and show qa versions
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs; grep -n "^## \|^### " 08-el-contrato-del-codigo.md | head -30; grep -n -i "fixture\|parametrize\|hypothesis\|mock\|cobertura\|coverage\|mutmut\|testcontainers" 08-el-contrato-del-codigo.md | head -15; sed -n '/^## `qa`/,/^## `ob`/p' prompts/inventario-verificado.md

# --- 2026-10-05T16:46:28 · Smoke-test qa01 suite
cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516; python3 humo.py op030-qa01-la-piramide-para-uno.md qa01 'pyproject.toml=[tool.pytest.ini_options]' 'liquidacion.py="""Regalías del trimestre' 'test_liquidacion.py="""Unitarias y propiedades' --pip pytest==9.1.1 hypothesis==6.168.4 --cmd "pytest -p no:cacheprovider -m 'not integration' --durations=3 2>&1 | tail -2; pytest -p no:cacheprovider -m integration 2>&1 | tail -3"

# --- 2026-10-05T16:46:41 · Fix qa01 output details and mark tested
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs; python3 - <<'EOF'
f='op030-qa01-la-piramide-para-uno.md'; t=open(f,encoding='utf-8').read()
for a,b in [("4 passed, 1 deselected in 0.41s","4 passed, 1 deselected in 0.53s"),("SKIPPED [1] test_liquidacion.py:30:","SKIPPED [1] test_liquidacion.py:31:"),("1 skipped, 4 deselected in 0.05s","1 skipped, 4 deselected in 0.09s"),("Salida esperada, sin correr (la primera línea, recortada):","Salida (Python 3.14.7, 05/10/2026), recortada:")]:
    assert a in t,a; t=t.replace(a,b)
OLD='> Versiones verificadas contra PyPI el 05/10/2026 · Código escrito sin ejecutar: las salidas\n> rotuladas «Salida esperada, sin correr» no salen de una corrida.'
NEW='> Versiones verificadas contra PyPI el 05/10/2026 · Código probado el 05/10/2026 con Python 3.14.7,\n> en contenedor: las salidas son las de esa corrida.'
assert OLD in t; open(f,'w',encoding='utf-8').write(t.replace(OLD,NEW))
EOF
python3 -B prompts/verificar-corpus.py | grep -v "EMOJI\|BENCHMARKS" | tail -1; python3 ../../zz-code/python-for-java-devs-20261005-f516/verificar_urls.py op030-*.md

# --- 2026-10-05T16:47:53 · Clean plugin, fix count, smoke-test qa02
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs; python3 - <<'EOF'
f='op031-qa02-pytest-a-fondo.md'; t=open(f,encoding='utf-8').read()
a=t[t.index("def pytest_addoption(parser):"):t.index("```\n\n`test_regalias.py`:")]
b='''def pytest_addoption(parser):
    parser.addoption("--budget", type=float, default=None,
                     help="falla la sesión si alguna prueba tarda más de estos segundos")


BUDGET: list[float | None] = [None]
SLOW: list[tuple[str, float]] = []


def pytest_configure(config):
    BUDGET[0] = config.getoption("--budget")


def pytest_runtest_logreport(report):
    if BUDGET[0] is not None and report.when == "call" and report.duration > BUDGET[0]:
        SLOW.append((report.nodeid, report.duration))


def pytest_terminal_summary(terminalreporter, exitstatus, config):
    if SLOW:
        terminalreporter.section("fuera del presupuesto")
        for nodeid, duration in SLOW:
            terminalreporter.write_line(f"{duration:.2f} s  {nodeid}")


def pytest_sessionfinish(session, exitstatus):
    if SLOW and session.exitstatus == 0:
        session.exitstatus = 1                         # una prueba lenta hace fallar la suite rápida
'''
t=t.replace(a,b)
t=t.replace("..........                                                               [100%]",".........                                                                [100%]").replace("10 passed in 1.02s","9 passed in 1.02s").replace("Diez pruebas pasaron, y la sesión termina","Nueve pruebas pasaron, y la sesión termina")
open(f,'w',encoding='utf-8').write(t)
EOF
cd ../../zz-code/python-for-java-devs-20261005-f516; python3 humo.py op031-qa02-pytest-a-fondo.md qa02 'conftest.py="""Fixtures compartidas' 'test_regalias.py="""Pruebas que usan' --pip pytest==9.1.1 --cmd "pytest -q -p no:cacheprovider --budget 0.5 test_regalias.py; echo exit=\$?; pytest -q -p no:cacheprovider --collect-only test_regalias.py | head -6"

# --- 2026-10-05T16:48:09 · Add id escaping trap to qa02 and mark
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs; python3 - <<'EOF'
f='op031-qa02-pytest-a-fondo.md'; t=open(f,encoding='utf-8').read()
t=t.replace("9 passed in 1.02s","9 passed in 0.83s")
a='''**Los ganchos con nombres mal escritos.**'''
b='''**Las tildes en los identificadores.** `pytest` escapa los caracteres no ASCII de los parámetros al
armar el nombre de cada caso: en la prueba de esta sección, la combinación de Zipaquirá aparece como
`test_billed_is_sum_of_tariffs[codes0-Zipaquir\\xe1]`. Para seleccionar ese caso con `-k` hay que
escribirlo así, o ponerle un `id=` en ASCII. La opción que desactiva el escape existe y su nombre ya
advierte que pierdes el soporte de la comunidad.

**Los ganchos con nombres mal escritos.**'''
assert a in t; t=t.replace(a,b,1)
OLD='> Versiones verificadas contra PyPI el 05/10/2026 · Código escrito sin ejecutar: las salidas\n> rotuladas «Salida esperada, sin correr» no salen de una corrida.'
NEW='> Versiones verificadas contra PyPI el 05/10/2026 · Código probado el 05/10/2026 con Python 3.14.7,\n> en contenedor: las salidas son las de esa corrida.'
assert OLD in t; t=t.replace(OLD,NEW).replace("Salida esperada, sin correr:","Salida (Python 3.14.7, 05/10/2026):")
t=t.replace("—`test_billed_is_sum_of_tariffs[codes0-Suba]`…—","—`test_billed_is_sum_of_tariffs[codes0-Suba]`, `[codes1-Zipaquir\\xe1]`…—")
open(f,'w',encoding='utf-8').write(t)
EOF
grep -n 'Zipaquir' op031-qa02-pytest-a-fondo.md | head -3; python3 -B prompts/verificar-corpus.py | grep -v "EMOJI\|BENCHMARKS" | tail -1; python3 ../../zz-code/python-for-java-devs-20261005-f516/verificar_urls.py op031-*.md

# --- 2026-10-05T16:49:24 · Verify dates, holidays pkg, smoke-test qa03
python3 -c "
import datetime as dt
print(dt.date(2026,10,5).strftime('%A'))
def due(d,n=15):
    r=n
    while r:
        d+=dt.timedelta(days=1)
        if d.weekday()<5: r-=1
    return d
print(due(dt.date(2026,9,18)), due(dt.date(2026,9,25)))"; curl -s https://pypi.org/pypi/holidays/json | python3 -c "import json,sys;d=json.load(sys.stdin);v=d['info']['version'];print('holidays',v,d['releases'][v][0]['upload_time'][:10])"; cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516; python3 humo.py op032-qa03-dobles-y-datos.md qa03 'glosas.py="""Glosas notificadas' 'test_glosas.py="""La red simulada' --pip pytest==9.1.1 httpx==0.28.1 pydantic==2.13.5 respx==0.23.1 time-machine==3.5.1 polyfactory==3.3.0 Faker==40.40.0 --cmd "pytest -q -s -p no:cacheprovider test_glosas.py 2>&1 | tail -15"

# --- 2026-10-05T16:49:42 · Update qa03 output, inventory, mark tested
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs; python3 - <<'EOF'
f='op032-qa03-dobles-y-datos.md'; t=open(f,encoding='utf-8').read()
rep=[("....Valentina Rodríguez Gómez 482913.57\n.\n5 passed in 0.62s","....Camilo Santiago Espinosa 528274.55\n.\n5 passed in 0.15s"),
("Salida esperada, sin correr (el nombre y el monto los inventa `Faker` en cada corrida):","Salida (Python 3.14.7, 05/10/2026); el nombre y el monto los inventa `Faker` en cada corrida:"),
("(el paquete `holidays` los trae, o una lista propia del\n   año)","(el paquete `holidays`, 0.105, los trae; o una lista propia\n   del año)")]
for a,b in rep:
    assert a in t,a[:40]; t=t.replace(a,b)
OLD='> Versiones verificadas contra PyPI el 05/10/2026 · Código escrito sin ejecutar: las salidas\n> rotuladas «Salida esperada, sin correr» no salen de una corrida.'
NEW='> Versiones verificadas contra PyPI el 05/10/2026 · Código probado el 05/10/2026 con Python 3.14.7,\n> en contenedor: las salidas son las de esa corrida.'
assert OLD in t; open(f,'w',encoding='utf-8').write(t.replace(OLD,NEW))
p='prompts/check-inventario.py'; t=open(p,encoding='utf-8').read()
a='"pytest-playwright", "coverage", "syrupy"],'; assert a in t; open(p,'w',encoding='utf-8').write(t.replace(a,'"pytest-playwright", "coverage", "syrupy", "holidays", "pytest-timeout"],'))
EOF
python3 -B prompts/verificar-corpus.py | grep -v "EMOJI\|BENCHMARKS" | tail -1; python3 ../../zz-code/python-for-java-devs-20261005-f516/verificar_urls.py op032-*.md

# --- 2026-10-05T16:49:58 · Find current Postgres 18 tag and local images
curl -s "https://hub.docker.com/v2/repositories/library/postgres/tags?page_size=10&ordering=last_updated&name=18" | python3 -c "import json,sys;[print(t['name'],t['last_updated'][:10]) for t in json.load(sys.stdin)['results']]" | head -8; docker images --format '{{.Repository}}:{{.Tag}}' | grep -i postgres | head

# --- 2026-10-05T16:50:58 · Smoke-test qa04 with testcontainers via docker socket
cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516; docker ps -a --format '{{.Names}} {{.Image}}' | grep -c . ; python3 humo.py op033-qa04-integracion-de-verdad.md qa04 'esquema.sql=CREATE TABLE settlements' 'conftest.py="""Un PostgreSQL de verdad' 'test_liquidaciones_db.py="""Lo que SQLite deja pasar' >/dev/null; S=$PWD/salidas/qa04; docker run --rm --label curso=python-for-java-devs -v /var/run/docker.sock:/var/run/docker.sock -v $S:/w -w /w -e TESTCONTAINERS_RYUK_DISABLED=true -e TESTCONTAINERS_HOST_OVERRIDE=host.docker.internal python:3.14.7 sh -c "pip install -q --root-user-action=ignore pytest==9.1.1 'testcontainers[postgres]==4.15.0' sqlalchemy 'psycopg[binary]' >/dev/null 2>&1; pytest -q -p no:cacheprovider test_liquidaciones_db.py 2>&1 | tail -4"; docker ps -a --format '{{.Names}} {{.Image}}' | grep -c . ; docker ps -a --filter ancestor=postgres:18.6 --format '{{.Names}} {{.Status}}'

# --- 2026-10-05T16:51:14 · Inspect testcontainers import warning
S=/Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516/salidas/qa04; docker run --rm --label curso=python-for-java-devs -v $S:/w -w /w python:3.14.7 sh -c "pip install -q --root-user-action=ignore 'testcontainers[postgres]==4.15.0' >/dev/null 2>&1; python -W always -c 'from testcontainers.postgres import PostgresContainer' 2>&1 | head -4"

# --- 2026-10-05T16:51:27 · Switch to community import and retest qa04
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs; python3 - <<'EOF'
f='op033-qa04-integracion-de-verdad.md'; t=open(f,encoding='utf-8').read()
a='from testcontainers.postgres import PostgresContainer'
assert a in t; t=t.replace(a,'from testcontainers.community.postgres import PostgresContainer')
a='''- **La imagen tiene etiqueta fija** (`postgres:18.6`),'''
b='''- **`testcontainers.community.postgres`**: en la versión 4.15 los módulos de cada servicio se mudaron a
  `testcontainers.community`, y el import de siempre (`testcontainers.postgres`) sigue funcionando con
  un `DeprecationWarning`. La prueba de esta sección lo encontró así.
- **La imagen tiene etiqueta fija** (`postgres:18.6`),'''
assert a in t; t=t.replace(a,b)
open(f,'w',encoding='utf-8').write(t)
EOF
cd ../../zz-code/python-for-java-devs-20261005-f516; python3 humo.py op033-qa04-integracion-de-verdad.md qa04 'conftest.py="""Un PostgreSQL de verdad' >/dev/null; S=$PWD/salidas/qa04; docker run --rm --label curso=python-for-java-devs -v /var/run/docker.sock:/var/run/docker.sock -v $S:/w -w /w -e TESTCONTAINERS_RYUK_DISABLED=true -e TESTCONTAINERS_HOST_OVERRIDE=host.docker.internal python:3.14.7 sh -c "pip install -q --root-user-action=ignore pytest==9.1.1 'testcontainers[postgres]==4.15.0' sqlalchemy 'psycopg[binary]' >/dev/null 2>&1; pytest -q -p no:cacheprovider test_liquidaciones_db.py 2>&1 | tail -2"; docker ps -a --format '{{.Names}}' | grep -c .

# --- 2026-10-05T16:51:44 · Mark qa04 tested and verify
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs; python3 - <<'EOF'
f='op033-qa04-integracion-de-verdad.md'; t=open(f,encoding='utf-8').read()
t=t.replace("5 passed in 4.10s","5 passed in 1.65s")
OLD='> Versiones verificadas contra PyPI el 05/10/2026 · Código escrito sin ejecutar: las salidas\n> rotuladas «Salida esperada, sin correr» no salen de una corrida.'
NEW='> Versiones verificadas contra PyPI el 05/10/2026 · Código probado el 05/10/2026 con Python 3.14.7,\n> en contenedor, con `testcontainers` levantando un `postgres:18.6` hermano por el *socket* de Docker.'
assert OLD in t; t=t.replace(OLD,NEW).replace("Salida esperada, sin correr (la primera vez, Docker descarga la imagen de PostgreSQL):","Salida (Python 3.14.7, 05/10/2026); la primera vez, Docker descarga la imagen de PostgreSQL:")
open(f,'w',encoding='utf-8').write(t)
EOF
python3 -B prompts/verificar-corpus.py | grep -v "EMOJI\|BENCHMARKS" | tail -1; python3 ../../zz-code/python-for-java-devs-20261005-f516/verificar_urls.py op033-*.md

# --- 2026-10-05T16:52:48 · Smoke-test qa05 stateful machine
cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516; python3 humo.py op034-qa05-propiedades-y-modelos.md qa05 'agenda.py="""La agenda de un odontólogo' 'test_agenda_estado.py="""La agenda contra un modelo' --pip pytest==9.1.1 hypothesis==6.168.4 --cmd "pytest -q -p no:cacheprovider test_agenda_estado.py 2>&1 | grep -E 'AssertionError|Falsifying|state|bookings_|failed|passed' | head -12"

# --- 2026-10-05T16:53:01 · Get full falsifying example and test the fix
cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516/salidas/qa05; docker run --rm --label curso=python-for-java-devs -v $PWD:/w -w /w -e COLUMNS=200 python:3.14.7 sh -c "pip install -q --root-user-action=ignore pytest==9.1.1 hypothesis==6.168.4 >/dev/null 2>&1; pytest -q -p no:cacheprovider test_agenda_estado.py 2>&1 | sed -n '/^E   *AssertionError/,\$p' | head -20; echo; cat > fix.py <<'EOF'
import agenda, inspect
src = inspect.getsource(agenda)
EOF
sed -i 's/        # El error sembrado: el espacio viejo nunca se libera. Lo encuentra la máquina de abajo./        if new_slot != old_slot:\n            del self.taken[old_slot]/' agenda.py; pytest -q -p no:cacheprovider test_agenda_estado.py 2>&1 | tail -1"

# --- 2026-10-05T16:53:20 · Update qa05 with real Hypothesis output
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs; python3 - <<'EOF'
f='op034-qa05-propiedades-y-modelos.md'; t=open(f,encoding='utf-8').read()
a=t[t.index("Salida esperada, sin correr (recortada; Hypothesis imprime la secuencia mínima que encontró):"):t.index("**Detalles con intención**")]
b='''Salida (Python 3.14.7, 05/10/2026), recortada a lo que imprime Hypothesis:

```text
E       AssertionError: assert {'08:40': 'PA...:00': 'PAC-1'} == {'08:00': 'PAC-1'}
E         Left contains 1 more item:
E         {'08:40': 'PAC-1'}
E       Failing test case:
E       state = AgendaMachine()
E       state.agenda_matches_model()
E       bookings_0 = state.book(patient='PAC-1', slot='08:40')
E       state.agenda_matches_model()
E       state.reschedule(booking=bookings_0, new_slot='08:00')
E       state.agenda_matches_model()
E       state.teardown()
FAILED test_agenda_estado.py::TestAgenda::runTest - AssertionError: …
1 failed in 0.59s
```

Dos pasos. Entre todas las secuencias de hasta veinte operaciones que probó, Hypothesis redujo el fallo a
la más corta posible: **reservar y reagendar**. La agenda dice que el espacio de las 8:40 sigue ocupado
por un paciente que ya se mudó a las 8:00, y nadie más puede reservarlo. Arreglar el error es una línea
en `reschedule` —liberar el espacio viejo cuando cambia (`del self.taken[old_slot]`)—, y con ella la misma
máquina pasa (`1 passed in 0.62s` en la misma corrida).

'''
t=t.replace(a,b)
t=t.replace("**La señal de que quedó bien:** *\"Hypothesis encontró en dos pasos el error de reagendar que habría dejado\nel espacio de las 8:00 bloqueado para siempre.\"*","**La señal de que quedó bien:** *\"Hypothesis encontró en dos pasos el error de reagendar que habría dejado\nun espacio bloqueado para siempre.\"*")
OLD='> Versiones verificadas contra PyPI el 05/10/2026 · Código escrito sin ejecutar: las salidas\n> rotuladas «Salida esperada, sin correr» no salen de una corrida.'
NEW='> Versiones verificadas contra PyPI el 05/10/2026 · Código probado el 05/10/2026 con Python 3.14.7,\n> en contenedor: el error sembrado, y la máquina en verde con el arreglo.'
assert OLD in t; t=t.replace(OLD,NEW)
open(f,'w',encoding='utf-8').write(t)
EOF
grep -n "8:00 bloqueado" op034-*.md; python3 -B prompts/verificar-corpus.py | grep -v "EMOJI\|BENCHMARKS" | tail -1; python3 ../../zz-code/python-for-java-devs-20261005-f516/verificar_urls.py op034-*.md

# --- 2026-10-05T16:54:18 · Run coverage and mutmut on weak suite
cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516; mkdir -p salidas/qa06/tests; python3 humo.py op035-qa06-medir-la-suite.md qa06 'regalias.py="""La regalía trimestral' 'tests/test_regalias.py=from decimal import Decimal' 'pyproject.toml=[tool.mutmut]' >/dev/null; S=$PWD/salidas/qa06; docker run --rm --label curso=python-for-java-devs -v $S:/w -w /w -e COLUMNS=120 python:3.14.7 sh -c "pip install -q --root-user-action=ignore pytest==9.1.1 pytest-cov==7.1.0 mutmut==3.8.0 >/dev/null 2>&1; pytest -q -p no:cacheprovider --cov=regalias --cov-branch --cov-report=term-missing 2>&1 | grep -A3 '^Name'; mutmut run > run1.log 2>&1; mutmut results 2>&1 | tail -12; echo; mutmut results 2>&1 | grep -c survived"

# --- 2026-10-05T16:54:41 · Coverage report and mutmut on both suites
S=/Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516/salidas/qa06; cd $S; rm -rf mutants run1.log; printf '[tool.mutmut]\nsource_paths = ["regalias.py"]\npytest_add_cli_args_test_selection = ["tests/"]\n' > pyproject.toml; cat > tests/test_precisa.py <<'EOF'
from decimal import Decimal

import pytest

from regalias import royalty


@pytest.mark.parametrize(("billed", "refunds", "expected"), [
    ("18420000", "0", "1105200"),       # la tasa: cualquier cambio a 0.06 falla aquí
    ("18420000", "420000", "1080000"),  # las devoluciones se restan, no se suman
    ("100", "500", "0"),                # el piso: negativo se vuelve cero
    ("100", "100", "0"),                # el borde del piso: exactamente cero
    ("25", "0", "2"),                   # 1,50 → 2 con redondeo bancario, y no 1
])
def test_royalty_exact(billed, refunds, expected):
    assert royalty(Decimal(billed), Decimal(refunds)) == Decimal(expected)
EOF
docker run --rm --label curso=python-for-java-devs -v $S:/w -w /w -e COLUMNS=120 python:3.14.7 sh -c "pip install -q --root-user-action=ignore pytest==9.1.1 pytest-cov==7.1.0 mutmut==3.8.0 >/dev/null 2>&1; mv tests/test_precisa.py /tmp/; pytest -q -p no:cacheprovider --cov=regalias --cov-branch --cov-report=term-missing tests/ 2>&1 | grep -B2 -A4 'regalias'; mutmut run >/dev/null 2>&1; echo debil: \$(mutmut results 2>&1 | grep -c survived); mutmut show regalias.x_royalty__mutmut_3 2>&1 | grep '^[-+][^-+]' ; mv /tmp/test_precisa.py tests/; rm -rf mutants; mutmut run >/dev/null 2>&1; echo precisa: \$(mutmut results 2>&1 | grep -c survived); mutmut results 2>&1 | grep survived; for m in \$(mutmut results 2>&1 | grep survived | cut -d: -f1); do mutmut show \$m 2>&1 | grep '^[-+][^-+]'; done"

# --- 2026-10-05T16:55:15 · Rerun coverage and mutmut with fixed config
S=/Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516/salidas/qa06; cd $S; rm -rf mutants; printf '[tool.pytest.ini_options]\npythonpath = ["."]\n\n[tool.mutmut]\nsource_paths = ["regalias.py"]\npytest_add_cli_args_test_selection = ["tests/"]\n' > pyproject.toml; sed -i '' 's/    ("25", "0", "2"),                   # 1,50 → 2 con redondeo bancario, y no 1/    ("75", "0", "4"),                   # 4,50 → 4 con redondeo bancario (y 5 hacia arriba)/' tests/test_precisa.py; grep -n '"75"' tests/test_precisa.py; docker run --rm --label curso=python-for-java-devs -v $S:/w -w /w -e COLUMNS=120 python:3.14.7 sh -c "pip install -q --root-user-action=ignore pytest==9.1.1 pytest-cov==7.1.0 mutmut==3.8.0 >/dev/null 2>&1; mv tests/test_precisa.py /tmp/; pytest -q -p no:cacheprovider --cov=regalias --cov-branch --cov-report=term-missing tests/ 2>&1 | grep -A4 '^Name'; mutmut run >/dev/null 2>&1; echo debil: \$(mutmut results 2>&1 | grep -c survived); mv /tmp/test_precisa.py tests/; rm -rf mutants; mutmut run >/dev/null 2>&1; echo precisa: \$(mutmut results 2>&1 | grep -c survived); python -c 'from decimal import *; print(Decimal(4.5).quantize(Decimal(1), rounding=ROUND_HALF_UP), Decimal(4.5).quantize(Decimal(1)), getcontext().rounding)'"

# --- 2026-10-05T16:55:50 · Rewrite qa06 results with real mutation data
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs; python3 - <<'EOF'
f='op035-qa06-medir-la-suite.md'; t=open(f,encoding='utf-8').read()
rep=[
('''`pyproject.toml`, la configuración de `mutmut`:

```toml
[tool.mutmut]
paths_to_mutate = ["regalias.py"]
tests_dir = ["tests/"]
```''','''`pyproject.toml`:

```toml
[tool.pytest.ini_options]
pythonpath = ["."]          # sin esto, pytest no encuentra regalias.py desde tests/

[tool.mutmut]
source_paths = ["regalias.py"]
pytest_add_cli_args_test_selection = ["tests/"]
```

`mutmut` 3.8 renombró sus claves: `paths_to_mutate` y `tests_dir` siguen funcionando, con un aviso de
deprecación, y casi todos los ejemplos de internet todavía las usan.'''),
('''Salida esperada, sin correr (recortada):

```text
Name          Stmts   Miss Branch BrPart  Cover   Missing
---------------------------------------------------------
regalias.py       8      0      2      0   100%
...
regalias.x_royalty__mutmut_3: survived
regalias.x_royalty__mutmut_5: survived
regalias.x_royalty__mutmut_7: survived
...
```

Cien por ciento de líneas y de ramas, y varios mutantes vivos. `mutmut show regalias.x_royalty__mutmut_3`
muestra el cambio exacto de cada uno —por ejemplo, la tasa cambiada o el `<` del piso convertido en
`<=`— y cada uno es una pregunta: *¿por qué ninguna prueba se dio cuenta?* La respuesta es la misma en
todos: las aserciones no miran el número.''','''Salida (Python 3.14.7, 05/10/2026), recortada:

```text
Name          Stmts   Miss Branch BrPart  Cover   Missing
---------------------------------------------------------
regalias.py       7      0      2      0   100%
...
    regalias.x_royalty__mutmut_2: survived
    regalias.x_royalty__mutmut_3: survived
    regalias.x_royalty__mutmut_4: survived
    regalias.x_royalty__mutmut_7: survived
    regalias.x_royalty__mutmut_9: survived
    regalias.x_royalty__mutmut_11: survived
    regalias.x_royalty__mutmut_12: survived
```

Cien por ciento de líneas y de ramas, y **siete mutantes vivos**. `mutmut show` muestra el cambio exacto
de cada uno —la tasa alterada, las devoluciones sumadas en vez de restadas, el piso movido— y cada uno es
una pregunta: *¿por qué ninguna prueba se dio cuenta?* La respuesta es la misma en todos: las aserciones
no miran el número.'''),
('''    ("25", "0", "2"),                   # 1,50 → 2 con redondeo bancario, y no 1''','''    ("75", "0", "4"),                   # 4,50 → 4 con redondeo bancario (y 5 hacia arriba)'''),
('''**Detalles con intención**

- **`--cov-branch`**''','''Con esta suite sobreviven **cinco** mutantes, y la parte instructiva es que **los cinco son
equivalentes**: cambian el código sin cambiar ningún resultado posible.

```text
-    if base < 0:                    +    if base <= 0:              con base 0, el resultado es 0 igual
-    if base < 0:                    +    if base < 1:               toda base menor que 1 da menos de 0,06: redondea a 0
-        base = Decimal(0)           +        base = Decimal(1)      1 × 0,06 = 0,06: redondea a 0
-    ….quantize(…, rounding=ROUND_HALF_EVEN)  +  rounding=None        None usa el contexto, que ya es HALF_EVEN
-    ….quantize(…, rounding=ROUND_HALF_EVEN)  +  (sin el argumento)   lo mismo
```

Dos lecturas útiles salen de ahí. La primera: el redondeo explícito **coincide con el que trae el
contexto por defecto de `decimal`**, así que quitarlo no cambia nada… hasta el día que alguien cambie el
contexto en otro lado del programa. El argumento explícito sigue valiendo; la mutación no lo puede
defender, y eso se acepta por escrito. La segunda: el caso `75 → 4` sí mata a un mutante que cambiara el
modo a `ROUND_HALF_UP` (4,50 daría 5); el `25 → 2` que tenía el primer borrador de esta sección no
distinguía los dos modos, porque 1,50 da 2 en ambos.

**Detalles con intención**

- **`--cov-branch`**'''),
('''- **`25 → 2`** es el caso del redondeo: 25 × 0,06 = 1,50, y el redondeo bancario lleva a 2 (el par más
  cercano). Un mutante que cambie el modo de redondeo sobrevive sin este caso.''','''- **`75 → 4`** es el caso del redondeo: 75 × 0,06 = 4,50, y el redondeo bancario lleva al par más
  cercano, 4; hacia arriba daría 5. Un caso que termine en ,50 con parte entera impar no distingue los
  dos modos.'''),
('''- **`paths_to_mutate` apunta a un solo módulo**:''','''- **`source_paths` apunta a un solo módulo**:'''),
('''**Los mutantes equivalentes.** Algunas mutaciones no cambian el comportamiento: cambiar `base < 0` por
`base <= 0` cuando el resultado para `base == 0` es cero en los dos casos. Ninguna prueba puede matarlo,
porque no hay diferencia observable. Se revisan y se marcan como aceptados, con su razón; perseguirlos es
tiempo perdido.''','''**Los mutantes equivalentes.** En el ejemplo son cinco de doce: mutaciones que no cambian ningún
resultado posible. Ninguna prueba puede matarlas, porque no hay diferencia observable. Se revisan una vez,
se marcan como aceptadas con su razón, y perseguirlas es tiempo perdido. Lo que no se hace es
"arreglarlas" quitando del código el redondeo explícito para que la herramienta quede contenta.'''),
('''**La señal de que quedó bien:** *"El módulo de regalías tenía 100% de cobertura y siete mutantes vivos;
ahora tiene los mismos 100% y ninguno, con cinco casos más."*''','''**La señal de que quedó bien:** *"El módulo de regalías tenía 100% de cobertura y siete mutantes vivos;
ahora tiene el mismo 100% y cinco vivos, los cinco equivalentes y explicados por escrito."*'''),
]
for a,b in rep:
    assert a in t,a[:60]; t=t.replace(a,b)
OLD='> Versiones verificadas contra PyPI el 05/10/2026 · Código escrito sin ejecutar: las salidas\n> rotuladas «Salida esperada, sin correr» no salen de una corrida.'
NEW='> Versiones verificadas contra PyPI el 05/10/2026 · Código probado el 05/10/2026 con Python 3.14.7,\n> en contenedor: la cobertura y las dos corridas de `mutmut` (siete sobrevivientes y cinco).'
assert OLD in t; t=t.replace(OLD,NEW)
open(f,'w',encoding='utf-8').write(t)
EOF
python3 -B prompts/verificar-corpus.py | grep -v "EMOJI\|BENCHMARKS" | tail -1; python3 ../../zz-code/python-for-java-devs-20261005-f516/verificar_urls.py op035-*.md

# --- 2026-10-05T16:55:58 · Count total mutants generated
S=/Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516/salidas/qa06; docker run --rm --label curso=python-for-java-devs -v $S:/w -w /w python:3.14.7 sh -c "pip install -q --root-user-action=ignore pytest==9.1.1 mutmut==3.8.0 >/dev/null 2>&1; mutmut results --all true 2>&1 | grep -c 'x_royalty__mutmut'; mutmut results --all true 2>&1 | awk -F': ' '{print \$2}' | sort | uniq -c"

# --- 2026-10-05T16:56:08 · Fix mutant total to fourteen
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs; grep -c "cinco de doce" op035-*.md; sed -i '' 's/En el ejemplo son cinco de doce: mutaciones/En el ejemplo son cinco de catorce: mutaciones/' op035-qa06-medir-la-suite.md; grep -c "cinco de catorce" op035-*.md

# --- 2026-10-05T16:56:15 · Check base path load testing tools
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs; grep -n -i "locust\|oha\|wrk\|generador de carga\|k6\|hey\b" 16-operacion-y-rendimiento.md 17-el-duelo-y-el-veredicto.md BENCHMARKS.md | head -12

# --- 2026-10-05T16:56:19 · Read base path load-generator confession
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs; sed -n 360,372p 17-el-duelo-y-el-veredicto.md; sed -n 505,515p BENCHMARKS.md

# --- 2026-10-05T16:57:28 · Smoke-test Locust load and pytest-benchmark
cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516; python3 humo.py op036-qa07-carga-y-rendimiento.md qa07 'agenda_api.py="""AgendaAPI mínima' 'locustfile.py="""Una auxiliar' 'test_rendimiento.py="""El cálculo de vencimientos' --pip fastapi uvicorn locust==2.46.7 pytest==9.1.1 pytest-benchmark==5.3.0 --cmd "(uvicorn agenda_api:app --port 8000 --workers 2 > uvicorn.log 2>&1 &); sleep 3; locust -f locustfile.py --headless -u 60 -r 20 -t 20s --host http://127.0.0.1:8000 --only-summary 2>&1 | grep -E 'Type|/disponibilidad|/reservas|Aggregated|CPU|percentiles' | head -10; pytest -q -p no:cacheprovider test_rendimiento.py --benchmark-autosave 2>&1 | tail -2; pytest -q -p no:cacheprovider test_rendimiento.py --benchmark-compare --benchmark-compare-fail=mean:20% 2>&1 | tail -2"

# --- 2026-10-05T16:58:16 · Mark qa07 with confirmed estimate
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs; python3 - <<'EOF'
f='op036-qa07-carga-y-rendimiento.md'; t=open(f,encoding='utf-8').read()
a='''Sesenta usuarios son unas seis auxiliares por sede con margen; con su tiempo de espera, producen unas
treinta peticiones por segundo, que es lo que importa simular: **el pico real de Áurea**, no el máximo
teórico del servidor.'''
b='''Sesenta usuarios son unas seis auxiliares por sede con margen; con su tiempo de espera, producen unas
treinta peticiones por segundo, que es lo que importa simular: **el pico real de Áurea**, no el máximo
teórico del servidor. En la prueba de esta sección, el agregado dio **29,3 req/s** con cero errores, que
confirma la cuenta. Las latencias de esa corrida no se publican como medición: salieron de un contenedor
en un portátil, con generador y servidor en la misma máquina, que es justo lo que §4 pide declarar.'''
assert a in t; t=t.replace(a,b)
OLD='> Versiones verificadas contra PyPI el 05/10/2026 · Código escrito sin ejecutar: las salidas\n> rotuladas «Salida esperada, sin correr» no salen de una corrida.'
NEW='> Versiones verificadas contra PyPI el 05/10/2026 · Código probado el 05/10/2026 con Python 3.14.7,\n> en contenedor: los comandos corren; las cifras de carga van en `⏳` porque no son una medición con\n> condiciones declaradas, y la salida rotulada «Salida esperada, sin correr» muestra su forma.'
assert OLD in t; t=t.replace(OLD,NEW)
open(f,'w',encoding='utf-8').write(t)
EOF
python3 -B prompts/verificar-corpus.py | grep -v "EMOJI\|BENCHMARKS" | tail -1; python3 ../../zz-code/python-for-java-devs-20261005-f516/verificar_urls.py op036-*.md

# --- 2026-10-05T16:58:25 · Check pre-commit hook tags on GitHub
for r in astral-sh/ruff-pre-commit pre-commit/mirrors-mypy PyCQA/bandit; do curl -s "https://api.github.com/repos/$r/tags?per_page=3" | python3 -c "import json,sys;print('$r', [t['name'] for t in json.load(sys.stdin)][:3])"; done

# --- 2026-10-05T16:59:26 · Run the quality chain tools on sample module
cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516; mkdir -p salidas/qa08/cartera; python3 humo.py op037-qa08-la-cadena-de-calidad.md qa08 'cartera/reporte.py="""Un módulo con un defecto' 'pyproject.toml=[project]' --pip ruff==0.16.10 mypy==2.4.0 bandit==1.9.4 deptry==0.25.1 vulture==2.16 requests --cmd "touch cartera/__init__.py; echo '--- ruff'; ruff check cartera/ --output-format concise 2>&1 | tail -6; echo '--- mypy'; mypy cartera/ 2>&1 | tail -6; echo '--- bandit'; bandit -q -r cartera/ 2>&1 | grep -E 'Issue|Location' ; echo '--- deptry'; deptry . 2>&1 | grep -v '^Scanning\|^$' | head -4; echo '--- vulture'; vulture cartera/"

# --- 2026-10-05T16:59:57 · Replace qa08 output with real tool output
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs; python3 - <<'EOF'
f='op037-qa08-la-cadena-de-calidad.md'; t=open(f,encoding='utf-8').read()
a=t[t.index("```bash\nruff check cartera/\n"):t.index("`.pre-commit-config.yaml`, para que todo esto corra antes de cada commit:")]
b='''```bash
ruff check cartera/ --output-format concise
mypy cartera/
bandit -q -r cartera/
deptry .
vulture cartera/
```

Salida (Python 3.14.7, 05/10/2026), con una línea en blanco entre herramientas:

```text
cartera/reporte.py:3:1: I001 [*] Import block is un-sorted or un-formatted
cartera/reporte.py:4:8: F401 [*] `os` imported but unused
cartera/reporte.py:16:5: S602 `subprocess` call with `shell=True` identified, security issue

cartera/reporte.py:12: error: Incompatible return value type (got "Decimal | Literal[0]", expected "Decimal")  [return-value]
cartera/reporte.py:15: error: Missing type arguments for generic type "dict"  [type-arg]
cartera/reporte.py:22: error: Module "requests" does not explicitly export attribute "__version__"  [attr-defined]

>> Issue: [B404:blacklist] Consider possible security implications associated with the subprocess module.
>> Issue: [B602:subprocess_popen_with_shell_equals_true] subprocess call with shell=True identified, security issue.

cartera/reporte.py:8:8: DEP003 'requests' imported but it is a transitive dependency

cartera/reporte.py:4: unused import 'os' (90% confidence)
cartera/reporte.py:11: unused function 'total' (60% confidence)
cartera/reporte.py:15: unused function 'export' (60% confidence)
cartera/reporte.py:21: unused function 'old_report' (60% confidence)
```

Cada herramienta encontró el defecto sembrado para ella, y casi todas encontraron algo más. Tres de esos
extras valen la pena:

- **El `return-value` de `mypy` es el más sutil**: `sum([])` devuelve el entero `0`, no un `Decimal`, y el
  día que una sede no tenga facturas, `total` devuelve un tipo distinto del que promete. El arreglo es
  `sum(amounts, Decimal(0))`. El modo estricto agregó además el `dict` sin parámetros, que es lo que pide.
- **`deptry` dijo `DEP003`, no `DEP001`**: en el entorno de la prueba `requests` estaba instalado aunque el
  proyecto no lo declara, así que lo vio como dependencia que llega por otra (transitiva). En un entorno
  sin `requests` habría dicho `DEP001`, "no declarada". Las dos son el mismo problema: el día que la
  dependencia intermedia lo suelte, el `import` revienta.
- **`vulture` marcó `total` y `export`**, que sí se usan, solo que desde otro módulo que este ejemplo no
  tiene. Es el falso positivo del que habla el detalle de abajo: el 60% de confianza es una pregunta, no
  una orden de borrar.

'''
t=t.replace(a,b)
OLD='> Versiones verificadas contra PyPI el 05/10/2026 · Código escrito sin ejecutar: las salidas\n> rotuladas «Salida esperada, sin correr» no salen de una corrida.'
NEW='> Versiones verificadas contra PyPI el 05/10/2026 · Código probado el 05/10/2026 con Python 3.14.7,\n> en contenedor: las cinco herramientas sobre el módulo de ejemplo; el `pre-commit` y el `noxfile.py`\n> quedan sin ejecutar.'
assert OLD in t; t=t.replace(OLD,NEW)
t=t.replace("1. Arregla los cinco defectos de `reporte.py`. **Criterio:** las cinco herramientas pasan sin ningún\n   `noqa` ni `nosec`.","1. Arregla los defectos de `reporte.py`. **Criterio:** las cinco herramientas pasan, con a lo sumo un\n   `# nosec B404` justificado por escrito.")
open(f,'w',encoding='utf-8').write(t)
EOF
python3 -B prompts/verificar-corpus.py | grep -v "EMOJI\|BENCHMARKS" | tail -1; python3 ../../zz-code/python-for-java-devs-20261005-f516/verificar_urls.py op037-*.md

# --- 2026-10-05T17:00:54 · Smoke-test qa09 e2e without python-multipart
cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516; python3 humo.py op038-qa09-e2e-con-playwright.md qa09 'sitio.py="""El sitio de reservas' 'conftest.py="""Levanta el sitio' 'test_reserva_e2e.py="""El camino que no puede' --pip fastapi uvicorn pytest==9.1.1 pytest-playwright==0.9.0 --cmd "playwright install --with-deps chromium >/tmp/inst.log 2>&1; pytest -q -p no:cacheprovider --base-url http://127.0.0.1:8765 --tracing retain-on-failure test_reserva_e2e.py 2>&1 | tail -4"

# --- 2026-10-05T17:01:48 · Add python-multipart and rerun qa09
curl -s https://pypi.org/pypi/python-multipart/json | python3 -c "import json,sys;d=json.load(sys.stdin);v=d['info']['version'];print('python-multipart',v,d['releases'][v][0]['upload_time'][:10])"; cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs; python3 - <<'EOF'
f='op038-qa09-e2e-con-playwright.md'; t=open(f,encoding='utf-8').read()
a='''```bash
uv add fastapi uvicorn
uv add --dev pytest pytest-playwright
uv run playwright install chromium
```'''
b='''```bash
uv add fastapi uvicorn python-multipart
uv add --dev pytest pytest-playwright
uv run playwright install chromium
```

`python-multipart` no es opcional: sin él, el primer formulario que recibe FastAPI falla con
`RuntimeError: Form data requires "python-multipart" to be installed.` FastAPI no lo instala solo,
porque no todas las API reciben formularios.'''
assert a in t; open(f,'w',encoding='utf-8').write(t.replace(a,b))
p='prompts/check-inventario.py'; t=open(p,encoding='utf-8').read()
a='"python-fasthtml", "click",'; assert a in t; open(p,'w',encoding='utf-8').write(t.replace(a,'"python-fasthtml", "python-multipart", "fastapi", "uvicorn", "click",'))
EOF
cd ../../zz-code/python-for-java-devs-20261005-f516; python3 humo.py op038-qa09-e2e-con-playwright.md qa09 'sitio.py="""El sitio de reservas' --pip fastapi uvicorn python-multipart pytest==9.1.1 pytest-playwright==0.9.0 --cmd "playwright install --with-deps chromium >/tmp/inst.log 2>&1; pytest -q -p no:cacheprovider --base-url http://127.0.0.1:8765 --tracing retain-on-failure test_reserva_e2e.py 2>&1 | tail -3"

# --- 2026-10-05T17:02:41 · Mark qa09 tested and verify
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs; sed -i '' 's/2 passed in 2.31s/2 passed in 0.93s/' op038-qa09-e2e-con-playwright.md; cd ../../zz-code/python-for-java-devs-20261005-f516; python3 probado.py op038-qa09-e2e-con-playwright.md; cd ../../cursos-algoritmos-lenguajes/python-for-java-devs; python3 -B prompts/verificar-corpus.py | grep -v "EMOJI\|BENCHMARKS" | tail -1; python3 ../../zz-code/python-for-java-devs-20261005-f516/verificar_urls.py op038-*.md

# --- 2026-10-05T17:02:47 · Find Playwright Python docs alternative
for u in https://playwright.dev/python/docs/writing-tests https://playwright.dev/python/docs/locators https://playwright.dev/docs/best-practices; do curl -s -o /dev/null -w "%{http_code} $u\n" $u; done

# --- 2026-10-05T17:02:53 · Fix Playwright best-practices link
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs; python3 - <<'EOF'
f='op038-qa09-e2e-con-playwright.md'; t=open(f,encoding='utf-8').read()
a='- Buenas prácticas de Playwright: https://playwright.dev/python/docs/best-practices'
b='- Escribir pruebas: https://playwright.dev/python/docs/writing-tests\n- Buenas prácticas (la página está en la documentación general, con ejemplos en JavaScript; las reglas\n  valen igual): https://playwright.dev/docs/best-practices'
assert a in t; open(f,'w',encoding='utf-8').write(t.replace(a,b))
EOF
python3 ../../zz-code/python-for-java-devs-20261005-f516/verificar_urls.py op038-*.md

# --- 2026-10-05T17:03:46 · Smoke-test qa10 budget script on qa01 suite
cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516; python3 humo.py op039-qa10-veredicto.md qa01 'presupuesto.py="""Lee el reporte JUnit' --pip pytest==9.1.1 hypothesis==6.168.4 --cmd "pytest -q -p no:cacheprovider -m 'not integration' --junitxml=reporte.xml >/dev/null 2>&1; python presupuesto.py reporte.xml; echo exit=\$?"

# --- 2026-10-05T17:04:10 · Mark qa10, run checks, close T5 in plan
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs; python3 - <<'EOF'
f='op039-qa10-veredicto.md'; t=open(f,encoding='utf-8').read()
a='''4 pruebas en 0.45 s (presupuesto 10 s)
las tres más lentas:
    0.41 s  test_liquidacion::test_never_negative_and_never_above_rate
    0.01 s  test_liquidacion::test_known_cases[18420000-0-1105200]
    0.00 s  test_liquidacion::test_known_cases[18420000-420000-1080000]
por archivo: {'test_liquidacion': 0.45}'''
b='''4 pruebas en 0.05 s (presupuesto 10 s)
las tres más lentas:
    0.05 s  test_liquidacion::test_never_negative_and_never_above_rate
    0.00 s  test_liquidacion::test_known_cases[18420000-0-1105200]
    0.00 s  test_liquidacion::test_known_cases[18420000-420000-1080000]
por archivo: {'test_liquidacion': 0.05}'''
assert a in t; t=t.replace(a,b).replace("Salida esperada, sin correr, sobre la suite de `qa01`:","Salida (Python 3.14.7, 05/10/2026), sobre la suite de `qa01`:")
t=t.replace("La prueba más lenta es la de propiedades, que genera cien ejemplos: es el costo esperado de Hypothesis, y\nel número dice que todavía cabe en el presupuesto con mucho margen.","La prueba más lenta es la de propiedades, que genera cien ejemplos: es el costo esperado de Hypothesis, y\nel número dice que la suite entera cabe doscientas veces en el presupuesto.")
OLD='> Versiones verificadas contra PyPI el 05/10/2026 · Código escrito sin ejecutar: las salidas\n> rotuladas «Salida esperada, sin correr» no salen de una corrida.'
NEW='> Versiones verificadas contra PyPI el 05/10/2026 · Código probado el 05/10/2026 con Python 3.14.7,\n> en contenedor: las salidas son las de esa corrida.'
assert OLD in t; open(f,'w',encoding='utf-8').write(t.replace(OLD,NEW))
EOF
python3 -B prompts/check-inventario.py qa ui | tail -1; python3 -B prompts/verificar-corpus.py | grep -v "EMOJI\|BENCHMARKS" | tail -1; python3 ../../zz-code/python-for-java-devs-20261005-f516/verificar_urls.py op039-*.md; wc -l op03[0-9]-qa* | tail -1; docker ps -a --filter label=curso=python-for-java-devs -q | wc -l; cd ../../zz-code/python-for-java-devs-20261005-f516; python3 plan.py 30 39 ✅ ✅; python3 plan.py tanda T5 ✅; python3 plan.py dondeesta "(05/10/2026).** T1–T5 (\`lg\`, \`au\`, \`co\`, \`wf\`, \`qa\`) cerradas: 39 de 176; T6 (\`ob\`) en curso."; python3 plan.py bitacora "**2026-10-05 · T5 (\`qa\`) cerrada.** Escritas op030–op039 (10 secciones, 94 ejercicios). **Las diez probadas en contenedor**: \`pytest\` 9.1.1 con marcas y *plugin* propio; \`respx\`, \`time-machine\`, \`polyfactory\`, \`Faker\`; **\`testcontainers\` 4.15.0** levantando \`postgres:18.6\` hermano por el *socket* de Docker (sin Ryuk; la cuenta de contenedores igual antes y después); Hypothesis con \`RuleBasedStateMachine\` encontrando el error sembrado en dos pasos; **\`mutmut\` 3.8.0** (14 mutantes: 7 vivos con la suite débil, 5 con la precisa, los cinco equivalentes); Locust 2.46.7 (29,3 req/s, confirma la estimación; cifras no publicadas como medición); \`ruff\`, \`mypy\` 2.4.0, \`bandit\`, \`deptry\`, \`vulture\`; \`pytest-playwright\` con Chromium. **Defectos propios y hallazgos:** \`testcontainers.postgres\` deprecado → \`testcontainers.community.postgres\`; \`mutmut\` 3.8 renombró \`paths_to_mutate\`/\`tests_dir\`; el caso de redondeo \`25 → 2\` no distinguía HALF_EVEN de HALF_UP (ahora \`75 → 4\`); los cinco sobrevivientes son equivalentes porque el redondeo explícito coincide con el contexto por defecto; \`pytest\` escapa no ASCII en los ids (\`Zipaquir\\\\xe1\`); \`pytest\` sin \`pythonpath\` no encontraba el módulo; FastAPI necesita \`python-multipart\` para formularios; la salida de la cadena de calidad tenía más hallazgos que los sembrados (DEP003, B404, falsos positivos de \`vulture\`), publicados tal cual; el enlace de buenas prácticas de Playwright no existe para Python. Inventario: +\`holidays\`, \`pytest-timeout\`, \`python-multipart\`, \`fastapi\`, \`uvicorn\`. **Tags:** \`op-qa-fase-01\` … \`op-qa-fase-10\`. **Siguiente:** T6 (\`ob\`)."; sed -i '' 's/T1–T4 (lg, au, co, wf) cerradas el 05\/10\/2026\./T1–T5 (lg, au, co, wf, qa) cerradas el 05\/10\/2026: 39 de 176./' /Users/oskar/.claude/projects/-Users-oskar-Developer-Learning-courses-ia-generated/memory/MEMORY.md

# --- 2026-10-05T17:04:57 · Outline Fase 16 observability and ob versions
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs; grep -n "^## \|^### " 16-operacion-y-rendimiento.md | head -24; grep -n -i "structlog\|logging\.\|prometheus\|opentelemetry\|py-spy\|sentry\|tracemalloc\|memray" 16-operacion-y-rendimiento.md | head -14; sed -n '/^## `ob`/,/^## `se`/p' prompts/inventario-verificado.md

# --- 2026-10-05T17:05:57 · Smoke-test ob01 and check URLs
cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516; python3 humo.py op040-ob01-las-senales.md ob01 'eventos.py="""Un evento ancho' --cmd "python eventos.py; head -c 300 eventos-cierre.jsonl"; cd ../../cursos-algoritmos-lenguajes/python-for-java-devs; python3 ../../zz-code/python-for-java-devs-20261005-f516/verificar_urls.py op040-*.md

# --- 2026-10-05T17:06:05 · Update ob01 output and mark tested
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs; sed -i '' 's/¿qué sede tardó más? Centro · mediana 44 ms/¿qué sede tardó más? Centro · mediana 52 ms/; s/Salida esperada, sin correr (las duraciones dependen de la máquina):/Salida (Python 3.14.7, 05\/10\/2026); las duraciones dependen de la máquina:/' op040-ob01-las-senales.md; python3 - <<'EOF'
f='op040-ob01-las-senales.md'; t=open(f,encoding='utf-8').read()
OLD='> Versiones verificadas contra PyPI el 05/10/2026 · Código escrito sin ejecutar: las salidas\n> rotuladas «Salida esperada, sin correr» no salen de una corrida.'
NEW='> Versiones verificadas contra PyPI el 05/10/2026 · Código probado el 05/10/2026 con Python 3.14.7,\n> en contenedor: las salidas son las de esa corrida.'
assert OLD in t; open(f,'w',encoding='utf-8').write(t.replace(OLD,NEW))
EOF
python3 -B prompts/verificar-corpus.py | grep -v "EMOJI\|BENCHMARKS" | tail -1

# --- 2026-10-05T17:07:01 · Smoke-test ob02 logging config
cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516; python3 humo.py op041-ob02-bitacoras.md ob02 'registro.py="""logging configurado' --pip structlog==26.1.0 httpx==0.28.1 --cmd "python registro.py"; cd ../../cursos-algoritmos-lenguajes/python-for-java-devs; python3 ../../zz-code/python-for-java-devs-20261005-f516/verificar_urls.py op041-*.md

# --- 2026-10-05T17:07:14 · Update ob02 output and mark tested
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs; python3 - <<'EOF'
f='op041-ob02-bitacoras.md'; t=open(f,encoding='utf-8').read()
a=t[t.index('{"invoices": 12, "event": "radicación iniciada", "request_id"'):t.index('```\n\nLas tres líneas tienen el mismo formato')]
b='''{"invoices": 12, "event": "radicación iniciada", "branch": "Suba", "request_id": "846709c3", "logger": "cartera.radicacion", "level": "info", "timestamp": "2026-10-05T17:07:04.971079Z"}
{"event": "HTTP Request: GET https://api.prepagada.example/v2/glosas \\"HTTP/1.1 200 OK\\"", "branch": "Suba", "request_id": "846709c3", "logger": "httpx", "level": "info", "timestamp": "2026-10-05T17:07:04.971527Z"}
{"event": "código viejo que usa logging directo", "branch": "Suba", "request_id": "846709c3", "logger": "cartera.legacy", "level": "warning", "timestamp": "2026-10-05T17:07:04.971610Z"}
'''
t=t.replace(a,b).replace("Salida esperada, sin correr (una línea por registro; el `request_id` y la hora cambian):","Salida (Python 3.14.7, 05/10/2026); el `request_id` y la hora cambian en cada corrida:")
OLD='> Versiones verificadas contra PyPI el 05/10/2026 · Código escrito sin ejecutar: las salidas\n> rotuladas «Salida esperada, sin correr» no salen de una corrida.'
NEW='> Versiones verificadas contra PyPI el 05/10/2026 · Código probado el 05/10/2026 con Python 3.14.7,\n> en contenedor: las salidas son las de esa corrida.'
assert OLD in t; open(f,'w',encoding='utf-8').write(t.replace(OLD,NEW))
EOF
python3 -B prompts/verificar-corpus.py | grep -v "EMOJI\|BENCHMARKS" | tail -1

# --- 2026-10-05T17:08:15 · Smoke-test ob03 and check atomic write
cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516; python3 humo.py op042-ob03-metricas.md ob03 'metricas_cierre.py="""Métricas de un proceso' --pip prometheus-client==0.26.0 --cmd "python metricas_cierre.py | grep -v '^# HELP\|_created'; python -c \"import inspect, prometheus_client.exposition as e; src=inspect.getsource(e.write_to_textfile); print('replace' in src or 'rename' in src)\""

# --- 2026-10-05T17:08:33 · Update ob03 with real metrics output
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs; python3 - <<'EOF'
f='op042-ob03-metricas.md'; t=open(f,encoding='utf-8').read()
a=t[t.index("Salida esperada, sin correr (recortada a las líneas que importan):"):t.index("Y la regla de alerta que convierte")]
b='''Salida (Python 3.14.7, 05/10/2026), sin las líneas `# HELP` ni las `_created`:

```text
promedio: 267 s · p50 ≈ 110 s · p95 ≈ 1500 s · máximo real: 1700 s
# TYPE cierre_sede_duration_seconds histogram
cierre_sede_duration_seconds_bucket{le="30.0"} 0.0
cierre_sede_duration_seconds_bucket{le="60.0"} 0.0
cierre_sede_duration_seconds_bucket{le="120.0"} 6.0
cierre_sede_duration_seconds_bucket{le="300.0"} 9.0
cierre_sede_duration_seconds_bucket{le="600.0"} 9.0
cierre_sede_duration_seconds_bucket{le="1200.0"} 9.0
cierre_sede_duration_seconds_bucket{le="1800.0"} 10.0
cierre_sede_duration_seconds_bucket{le="+Inf"} 10.0
cierre_sede_duration_seconds_count 10.0
cierre_sede_duration_seconds_sum 2672.153236165427
# TYPE cierre_filas_rechazadas_total counter
cierre_filas_rechazadas_total{motivo="sin_codigo"} 35.0
cierre_filas_rechazadas_total{motivo="fecha_futura"} 5.0
# TYPE cierre_ultimo_exito_timestamp_seconds gauge
cierre_ultimo_exito_timestamp_seconds 1.7912200979857388e+09
```

La primera línea es la sección entera. El promedio, **267 segundos**, no describe a ninguna sede: nueve
tardaron entre 90 y 150 y una tardó 1.700. La mediana, unos 110, describe a las nueve normales; el p95,
unos 1.500 —interpolado dentro del *bucket* de 1.200 a 1.800—, apunta a la que hay que mirar. Y los
*buckets* cuentan la misma historia sin calcular nada: seis sedes hasta 2 minutos, tres hasta 5, y una sola
entre 20 y 30.

Las líneas `_created` que la salida omite las agrega la biblioteca por cada contador e histograma (la hora en
que se creó la serie); se desactivan con la variable de entorno `PROMETHEUS_DISABLE_CREATED_SERIES=True`.

'''
t=t.replace(a,b)
OLD='> Versiones verificadas contra PyPI el 05/10/2026 · Código escrito sin ejecutar: las salidas\n> rotuladas «Salida esperada, sin correr» no salen de una corrida.'
NEW='> Versiones verificadas contra PyPI el 05/10/2026 · Código probado el 05/10/2026 con Python 3.14.7,\n> en contenedor: las salidas son las de esa corrida.'
assert OLD in t; open(f,'w',encoding='utf-8').write(t.replace(OLD,NEW))
EOF
python3 -B prompts/verificar-corpus.py | grep -v "EMOJI\|BENCHMARKS" | tail -1; python3 ../../zz-code/python-for-java-devs-20261005-f516/verificar_urls.py op042-*.md

# --- 2026-10-05T17:08:40 · Check OpenTelemetry instrumentation packages
for p in opentelemetry-instrumentation-httpx opentelemetry-instrumentation-fastapi; do curl -s https://pypi.org/pypi/$p/json | python3 -c "import json,sys;d=json.load(sys.stdin);v=d['info']['version'];print('$p',v,d['releases'][v][0]['upload_time'][:10])"; done

# --- 2026-10-05T17:09:34 · Smoke-test ob04 OpenTelemetry tracing
cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516; python3 humo.py op043-ob04-trazas.md ob04 'trazas_cierre.py="""Trazas del cierre' --pip opentelemetry-sdk==1.45.0 opentelemetry-instrumentation-httpx==0.66b0 httpx==0.28.1 --cmd "python trazas_cierre.py"; cd ../../cursos-algoritmos-lenguajes/python-for-java-devs; python3 ../../zz-code/python-for-java-devs-20261005-f516/verificar_urls.py op043-*.md

# --- 2026-10-05T17:09:50 · Try instrument_client with MockTransport
cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516/salidas/ob04; sed -e 's/^HTTPXClientInstrumentor().instrument()      # todas las peticiones de httpx crean su tramo/# (global desactivado para la prueba)/' -e 's/    with httpx.Client(transport=httpx.MockTransport(agenda_api)) as client:/    with httpx.Client(transport=httpx.MockTransport(agenda_api)) as client:\n        HTTPXClientInstrumentor.instrument_client(client)/' trazas_cierre.py > trazas_cliente.py; grep -n "instrument" trazas_cliente.py; docker run --rm --label curso=python-for-java-devs -v $PWD:/w -w /w python:3.14.7 sh -c "pip install -q --root-user-action=ignore opentelemetry-sdk==1.45.0 opentelemetry-instrumentation-httpx==0.66b0 httpx==0.28.1 >/dev/null 2>&1; python trazas_cliente.py"

# --- 2026-10-05T17:10:13 · Fix ob04 instrumentation and real output
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs; python3 - <<'EOF'
f='op043-ob04-trazas.md'; t=open(f,encoding='utf-8').read()
rep=[
("HTTPXClientInstrumentor().instrument()      # todas las peticiones de httpx crean su tramo\n","" ),
("""    with httpx.Client(transport=httpx.MockTransport(agenda_api)) as client:
        close_branch("Kennedy", client)""","""    with httpx.Client(transport=httpx.MockTransport(agenda_api)) as client:
        # Este cliente en concreto: instrument() global no cubre MockTransport (ver los detalles).
        HTTPXClientInstrumentor.instrument_client(client)
        close_branch("Kennedy", client)"""),
]
for a,b in rep:
    assert a in t,a[:50]; t=t.replace(a,b)
a=t[t.index("Salida esperada, sin correr (los identificadores y los tiempos cambian):"):t.index("Dos cosas que solo una traza dice:")]
b='''Salida (Python 3.14.7, 05/10/2026); los identificadores y los tiempos cambian en cada corrida:

```text
cierre_sede             104.8 ms  {'sede': 'Kennedy', 'citas': 812}
  leer_export              29.1 ms  {'filas': 4210}
  consultar_agenda         60.8 ms  {}
    GET                      60.3 ms  {'http.method': 'GET', 'http.url': 'https://agenda.aurea.example/citas', 'http.status_code': 200}
  conciliar                14.7 ms  {}
traceparent recibido por AgendaAPI: 00-9bec3891ea5a998208d38f82ab864514-9417778281774b2f-03
trace_id del cierre:               9bec3891ea5a998208d38f82ab864514
```

'''
t=t.replace(a,b)
a='''- **`HTTPXClientInstrumentor().instrument()`** crea el tramo `GET` y agrega el `traceparent` sin tocar
  `close_branch`. Con FastAPI pasa lo mismo del lado del servidor: lee el encabezado y continúa la traza.'''
b='''- **`instrument_client(client)` y no `instrument()`.** La forma global, `HTTPXClientInstrumentor().instrument()`,
  envuelve los transportes **reales** de `httpx`; un cliente con `MockTransport` no pasa por ellos, y en la
  prueba de esta sección no apareció ni el tramo `GET` ni el `traceparent`. En producción, con transporte
  real, la forma global alcanza; en las pruebas, se instrumenta el cliente. Del lado del servidor, la
  instrumentación de FastAPI lee el encabezado y continúa la traza.'''
assert a in t; t=t.replace(a,b)
a='''**Los nombres de atributos que cambian entre versiones.** Las convenciones semánticas de OpenTelemetry
renombraron atributos HTTP (`http.method` pasó a `http.request.method`, por ejemplo). Un panel construido con
los nombres viejos queda vacío después de actualizar la instrumentación. Las versiones de los paquetes de
instrumentación se actualizan juntas y se revisan los paneles.'''
b='''**Los nombres de atributos que cambian entre versiones.** Las convenciones semánticas de OpenTelemetry
renombraron los atributos HTTP —`http.method` a `http.request.method`, `http.url` a `url.full`—, y la
instrumentación de `httpx` de esta versión todavía emite **los viejos por defecto**, como muestra la salida;
los nuevos se activan con la variable `OTEL_SEMCONV_STABILITY_OPT_IN`. El día que el valor por defecto
cambie, un panel construido con los nombres viejos queda vacío. Las versiones de los paquetes de
instrumentación se actualizan juntas y se revisan los paneles.'''
assert a in t; t=t.replace(a,b)
OLD='> Versiones verificadas contra PyPI el 05/10/2026 · Código escrito sin ejecutar: las salidas\n> rotuladas «Salida esperada, sin correr» no salen de una corrida.'
NEW='> Versiones verificadas contra PyPI el 05/10/2026 · Código probado el 05/10/2026 con Python 3.14.7,\n> en contenedor: las salidas son las de esa corrida.'
assert OLD in t; t=t.replace(OLD,NEW)
t=t.replace("**Criterio:** demuestras qué tramos se pierden y lo\n   arreglas.","**Criterio:** demuestras qué tramos se pierden y lo\n   arreglas.")
open(f,'w',encoding='utf-8').write(t)
EOF
grep -n "instrument" op043-ob04-trazas.md | head -8; python3 -B prompts/verificar-corpus.py | grep -v "EMOJI\|BENCHMARKS" | tail -1

# --- 2026-10-05T17:10:18 · Rerun corrected ob04 code
cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516; python3 humo.py op043-ob04-trazas.md ob04 'trazas_cierre.py="""Trazas del cierre' --pip opentelemetry-sdk==1.45.0 opentelemetry-instrumentation-httpx==0.66b0 httpx==0.28.1 --cmd "python trazas_cierre.py" | grep -E "GET|traceparent"

# --- 2026-10-05T17:10:31 · Check py-spy support for Python 3.14
docker run --rm --label curso=python-for-java-devs --cap-add SYS_PTRACE python:3.14.7 sh -c "pip install -q --root-user-action=ignore py-spy==0.4.2 memray==1.20.0 >/dev/null 2>&1; python -c 'import time
def hot():
    s=0
    for i in range(10**9): s+=i*i
hot()' & sleep 2; py-spy dump --pid \$! 2>&1 | head -8; py-spy --version; python -m memray --version 2>&1 | head -1"

# --- 2026-10-05T17:11:40 · Run full live profiling diagnosis in container
cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516; python3 humo.py op044-ob05-perfilado-en-produccion.md ob05 'agenda_con_fuga.py="""Un servicio con una fuga' >/dev/null; docker run --rm --label curso=python-for-java-devs --cap-add SYS_PTRACE -v $PWD/salidas/ob05:/w -w /w python:3.14.7 sh -c "pip install -q --root-user-action=ignore py-spy==0.4.2 >/dev/null 2>&1; python agenda_con_fuga.py > servicio.log 2>&1 & PID=\$!; sleep 2; py-spy dump --pid \$PID 2>&1 | sed -n '3,6p'; kill -USR1 \$PID; sleep 5; kill -USR1 \$PID; sleep 1; py-spy record --pid \$PID --duration 5 -o perfil.svg > record.log 2>&1; kill \$PID; cat servicio.log; ls -la perfil.svg | awk '{print \$5, \$9}'; tail -2 record.log"

# --- 2026-10-05T17:12:10 · Fix leak example and rerun diagnosis
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs; python3 - <<'EOF'
f='op044-ob05-perfilado-en-produccion.md'; t=open(f,encoding='utf-8').read()
a='    _cache[request_id] = b"x" * 2048          # 2 KB por petición, para siempre'
b='    _cache[request_id] = bytes(2048)          # 2 KB nuevos por petición, para siempre'
assert a in t; open(f,'w',encoding='utf-8').write(t.replace(a,b))
EOF
cd ../../zz-code/python-for-java-devs-20261005-f516; python3 humo.py op044-ob05-perfilado-en-produccion.md ob05 'agenda_con_fuga.py="""Un servicio con una fuga' >/dev/null; docker run --rm --label curso=python-for-java-devs --cap-add SYS_PTRACE -v $PWD/salidas/ob05:/w -w /w python:3.14.7 sh -c "pip install -q --root-user-action=ignore py-spy==0.4.2 >/dev/null 2>&1; python agenda_con_fuga.py > servicio.log 2>&1 & PID=\$!; sleep 2; py-spy dump --pid \$PID 2>&1 | sed -n '3,6p'; kill -USR1 \$PID; sleep 5; kill -USR1 \$PID; sleep 1; kill \$PID; cat servicio.log; python -c 'import dis; dis.dis(compile(\"b\\\"x\\\" * 2048\",\"\",\"eval\"))' | head -3"

# --- 2026-10-05T17:12:35 · Update ob05 with real diagnosis and constant folding lesson
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs; python3 - <<'EOF'
f='op044-ob05-perfilado-en-produccion.md'; t=open(f,encoding='utf-8').read()
a=t[t.index("Salida esperada, sin correr (recortada):"):t.index("**Detalles con intención**")]
b='''Salida (Python 3.14.7, 05/10/2026), recortada; el `pid` y los tamaños cambian:

```text
Thread 10 (active+gil)
    compute_slots (agenda_con_fuga.py:19)
    <module> (agenda_con_fuga.py:44)
foto base tomada
creció: /w/agenda_con_fuga.py:13: size=876 KiB (+510 KiB), count=426 (+248), average=2107 B
creció: /w/agenda_con_fuga.py:43: size=19.8 KiB (+11.6 KiB), count=425 (+248), average=48 B
```

Dos respuestas sin haber reiniciado nada. `py-spy dump` dice que el hilo principal está en
`compute_slots`, línea 19: es el punto caliente. Y la comparación de fotos dice que la memoria que creció
viene de la línea 13 —`_cache[request_id] = bytes(2048)`—, en bloques de unos 2 KB: es la fuga, con su
línea. La segunda línea que crece, la 43, son las claves `f"req-{n}"` de esa misma caché: 48 bytes cada una,
tan perdidas como los valores.

> ⚠️ **La primera versión de este ejemplo no tenía fuga.** Usaba `b"x" * 2048` como valor, y `tracemalloc`
> mostró que lo único que crecía eran las claves. La razón: `b"x" * 2048` es una expresión con constantes, y
> el compilador de Python la **pliega** en una sola constante (`dis` la muestra como un único `LOAD_CONST`):
> todas las entradas de la caché apuntaban al mismo objeto. Es una lección que sirve fuera del ejemplo: antes
> de culpar a una línea, mira qué objetos crea de verdad; `bytes(2048)` crea uno nuevo en cada llamada.

'''
t=t.replace(a,b)
OLD='> Versiones verificadas contra PyPI el 05/10/2026 · Código escrito sin ejecutar: las salidas\n> rotuladas «Salida esperada, sin correr» no salen de una corrida.'
NEW='> Versiones verificadas contra PyPI el 05/10/2026 · Código probado el 05/10/2026 con Python 3.14.7,\n> en un contenedor con `--cap-add SYS_PTRACE`: `py-spy` 0.4.2 adjuntado al proceso vivo y las dos fotos de\n> `tracemalloc`.'
assert OLD in t; t=t.replace(OLD,NEW)
open(f,'w',encoding='utf-8').write(t)
EOF
python3 -B prompts/verificar-corpus.py | grep -v "EMOJI\|BENCHMARKS" | tail -1; python3 ../../zz-code/python-for-java-devs-20261005-f516/verificar_urls.py op044-*.md

# --- 2026-10-05T17:13:38 · Smoke-test ob06 with and without before_send
cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516; python3 humo.py op045-ob06-errores-como-producto.md ob06 'errores.py="""Captura de errores con sentry-sdk' --pip sentry-sdk==2.71.0 --cmd "python errores.py; echo '--- sin before_send'; sed 's/    before_send=before_send,/    before_send=None,/' errores.py > sin.py; python -c \"
import sin, json
for e in sin.SENT[:1]:
    ex = e['exception']['values'][0]
    print('mensaje:', ex['value'])
    print('vars del marco:', [f.get('vars') for f in ex['stacktrace']['frames'] if f.get('vars')][-1:])
\""

# --- 2026-10-05T17:13:48 · Run ob06 without before_send properly
cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516/salidas/ob06; docker run --rm --label curso=python-for-java-devs -v $PWD:/w -w /w python:3.14.7 sh -c "pip install -q --root-user-action=ignore sentry-sdk==2.71.0 >/dev/null 2>&1; python -c \"
import runpy, io, contextlib
with contextlib.redirect_stdout(io.StringIO()):
    g = runpy.run_path('sin.py', run_name='__main__')
ex = g['SENT'][0]['exception']['values'][0]
print('mensaje:', ex['value'])
print('vars del marco de book:', [f['vars'] for f in ex['stacktrace']['frames'] if f.get('function') == 'book'])
\""

# --- 2026-10-05T17:14:00 · Add real leak evidence to ob06 and mark
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs; python3 - <<'EOF'
f='op045-ob06-errores-como-producto.md'; t=open(f,encoding='utf-8').read()
a='''Los dos eventos salen con el mismo mensaje —sin documento—, la misma pila y la misma versión: el servidor
los agrupa en **un** problema con dos apariciones. Sin `before_send`, cada uno llevaría la cédula en el
mensaje y en la variable local `patient_document`, y el servidor, además, los vería como mensajes distintos.'''
b='''Los dos eventos salen con el mismo mensaje —sin documento—, la misma pila y la misma versión: el servidor
los agrupa en **un** problema con dos apariciones. Y lo que habría salido sin `before_send`, con
`send_default_pii=False` puesto, es esto —comprobado en la misma corrida, cambiando solo esa línea—:

```text
mensaje: la cita del paciente 1023456789 no tiene sede
vars del marco de book: [{'patient_document': "'1023456789'", 'branch': 'None'}]
```

La cédula, dos veces: en el mensaje y en la variable local. `send_default_pii=False` controla otras cosas
—direcciones IP, cookies, usuarios—; las variables locales y el texto del mensaje son tuyos.'''
assert a in t; t=t.replace(a,b)
OLD='> Versiones verificadas contra PyPI el 05/10/2026 · Código escrito sin ejecutar: las salidas\n> rotuladas «Salida esperada, sin correr» no salen de una corrida.'
NEW='> Versiones verificadas contra PyPI el 05/10/2026 · Código probado el 05/10/2026 con Python 3.14.7,\n> en contenedor, con el transporte de captura (sin mandar nada a ningún servidor).'
assert OLD in t; t=t.replace(OLD,NEW).replace("Salida esperada, sin correr:","Salida (Python 3.14.7, 05/10/2026):")
open(f,'w',encoding='utf-8').write(t)
EOF
python3 -B prompts/verificar-corpus.py | grep -v "EMOJI\|BENCHMARKS" | tail -1; python3 ../../zz-code/python-for-java-devs-20261005-f516/verificar_urls.py op045-*.md

# --- 2026-10-05T17:14:53 · Smoke-test ob07 daily digest
cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516; python3 humo.py op046-ob07-veredicto.md ob07 'resumen_diario.py="""El resumen de las 7:00' --cmd "python resumen_diario.py"; cd ../../cursos-algoritmos-lenguajes/python-for-java-devs; python3 ../../zz-code/python-for-java-devs-20261005-f516/verificar_urls.py op046-*.md

# --- 2026-10-05T17:15:06 · Mark ob07, run checks, close T6
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs; sed -i '' 's/🐢 Kennedy: ⏳ s, su mediana de la semana es ⏳ s/🐢 Kennedy: 322 s, su mediana de la semana es 192 s/' op046-ob07-veredicto.md; cd ../../zz-code/python-for-java-devs-20261005-f516; python3 probado.py op046-ob07-veredicto.md; cd ../../cursos-algoritmos-lenguajes/python-for-java-devs; python3 -B prompts/check-inventario.py ob | tail -1; python3 -B prompts/verificar-corpus.py | grep -v "EMOJI\|BENCHMARKS" | tail -1; wc -l op04[0-6]-ob* | tail -1; docker ps -a --filter label=curso=python-for-java-devs -q | wc -l; cd ../../zz-code/python-for-java-devs-20261005-f516; python3 plan.py 40 46 ✅ ✅; python3 plan.py tanda T6 ✅; python3 plan.py dondeesta "(05/10/2026).** T1–T6 (\`lg\`, \`au\`, \`co\`, \`wf\`, \`qa\`, \`ob\`) cerradas: 46 de 176; T7 (\`se\`) en curso."; python3 plan.py bitacora "**2026-10-05 · T6 (\`ob\`) cerrada.** Escritas op040–op046 (7 secciones, 68 ejercicios), **las siete probadas en contenedor**. **Hallazgos y defectos propios:** \`HTTPXClientInstrumentor().instrument()\` global no cubre \`MockTransport\` (sin tramo ni \`traceparent\`); se usa \`instrument_client\` y se explica; la instrumentación de \`httpx\` 0.66b0 emite los nombres **viejos** de atributos (\`http.method\`) por defecto, al revés de lo que había escrito; \`py-spy\` 0.4.2 sí soporta Python 3.14 (con \`--cap-add SYS_PTRACE\`); **la fuga de \`ob05\` no existía**: \`b\"x\" * 2048\` se pliega en una sola constante (verificado con \`dis\`), ahora \`bytes(2048)\` y la sección lo cuenta; \`prometheus-client\` agrega series \`_created\`; \`sentry-sdk\` sin \`before_send\` manda la cédula en el mensaje y en la variable local aunque \`send_default_pii=False\` (comprobado y publicado). Las salidas reales reemplazaron a las previstas en cinco secciones (orden de campos, tiempos, líneas). **Tags:** \`op-ob-fase-01\` … \`op-ob-fase-07\`. **Siguiente:** T7 (\`se\`)."; sed -i '' 's/T1–T5 (lg, au, co, wf, qa) cerradas el 05\/10\/2026: 39 de 176\./T1–T6 (lg, au, co, wf, qa, ob) cerradas el 05\/10\/2026: 46 de 176./' /Users/oskar/.claude/projects/-Users-oskar-Developer-Learning-courses-ia-generated/memory/MEMORY.md

# --- 2026-10-05T17:15:22 · Read Fase 16 security parts and se versions
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs; sed -n 184,207p 16-operacion-y-rendimiento.md; sed -n 333,364p 16-operacion-y-rendimiento.md; sed -n '/^## `se`/,/^## `tx`/p' prompts/inventario-verificado.md

# --- 2026-10-05T17:16:23 · Smoke-test se01 and verify book URL
cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516; python3 humo.py op047-se01-el-modelo.md se01 'protecciones.py="""La misma notificación' --pip cryptography==50.0.2 --cmd "python protecciones.py"; cd ../../cursos-algoritmos-lenguajes/python-for-java-devs; python3 ../../zz-code/python-for-java-devs-20261005-f516/verificar_urls.py op047-*.md; curl -s -A "Mozilla/5.0" https://nostarch.com/serious-cryptography-2nd-edition | grep -o -i "<title>[^<]*</title>\|20[0-9][0-9]</[^>]*>" | head -3

# --- 2026-10-05T17:16:31 · Confirm book publication year
curl -s -A "Mozilla/5.0" https://nostarch.com/serious-cryptography-2nd-edition | python3 -c "import sys,re,html; t=html.unescape(sys.stdin.read()); [print(m) for m in re.findall(r'(?:Publication date|Print ISBN|Published)[^<]{0,80}', t)[:4]]; print(re.findall(r'(?:January|February|March|April|May|June|July|August|September|October|November|December)\s+20\d\d', t)[:3])"

# --- 2026-10-05T17:16:35 · Mark se01 tested
cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516; python3 probado.py op047-se01-el-modelo.md; cd ../../cursos-algoritmos-lenguajes/python-for-java-devs; python3 -B prompts/verificar-corpus.py | grep -v "EMOJI\|BENCHMARKS" | tail -1

# --- 2026-10-05T17:17:36 · Smoke-test se02 crypto examples
cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516; python3 humo.py op048-se02-cryptography-y-pynacl.md se02 'cifrado_backoffice.py="""Una columna cifrada' --pip cryptography==50.0.2 pynacl==1.6.2 --cmd "python cifrado_backoffice.py"; cd ../../cursos-algoritmos-lenguajes/python-for-java-devs; python3 ../../zz-code/python-for-java-devs-20261005-f516/verificar_urls.py op048-*.md

# --- 2026-10-05T17:17:43 · Mark se02 tested
cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516; python3 probado.py op048-se02-cryptography-y-pynacl.md; cd ../../cursos-algoritmos-lenguajes/python-for-java-devs; python3 -B prompts/verificar-corpus.py | grep -v "EMOJI\|BENCHMARKS" | tail -1

# --- 2026-10-05T17:19:40 · Review smoke-test helper usage
cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516 && sed -n 1,40p humo.py && ls salidas | tail -3

# --- 2026-10-05T17:19:44 · Smoke-test se03 example in container
python3 humo.py op049-se03-contrasenas-y-tokens.md se03 'acceso.py=@acceso.py' --pip argon2-cffi==25.1.0 pyjwt==2.15.1 --cmd "python acceso.py" 2>&1 | tail -20

# --- 2026-10-05T17:19:51 · Check bcrypt 5 behaviour with long passwords
docker run --rm --label curso=python-for-java-devs python:3.14.7 sh -c 'pip install -q bcrypt==5.0.0 2>/dev/null; python -c "
import bcrypt
try:
    bcrypt.hashpw(b\"x\"*80, bcrypt.gensalt()); print(\"sin error\")
except Exception as e: print(type(e).__name__, e)
"'

# --- 2026-10-05T17:19:57 · Mark se03 tested, run corpus and URL checks
python3 probado.py op049-se03-contrasenas-y-tokens.md && grep -n "Salida\|Código" ../../cursos-algoritmos-lenguajes/python-for-java-devs/op049-se03-contrasenas-y-tokens.md | head; cd ../../cursos-algoritmos-lenguajes/python-for-java-devs && python3 prompts/verificar-corpus.py 2>&1 | tail -3; python3 ../../zz-code/python-for-java-devs-20261005-f516/verificar_urls.py op049-se03-contrasenas-y-tokens.md 2>&1 | tail -8

# --- 2026-10-05T17:20:01 · Mark op049 written and tested in plan
cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516 && python3 plan.py 49 49 ✅ ✅ 2>&1 | tail -2

# --- 2026-10-05T17:20:03 · Confirm plan rows are marked
grep -n "op049\|op048" /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs/prompts/plan-de-produccion-carta.md

# --- 2026-10-05T17:20:07 · Mark op047-op048 and count marked rows
python3 plan.py 47 48 ✅ ✅; grep -n "op04[0-9]" ../../cursos-algoritmos-lenguajes/python-for-java-devs/prompts/plan-de-produccion-carta.md | grep -c "✅ | ✅"

# --- 2026-10-05T17:20:13 · Look up auth library versions in inventory
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs && grep -n -i "authlib\|joserfc\|keycloak\|httpx \|httpx|\|cryptography" prompts/inventario-verificado.md | head

# --- 2026-10-05T17:21:12 · Smoke-test se04 OIDC example in container
cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516 && python3 humo.py op050-se04-oauth2-y-oidc.md se04 'oidc.py=@oidc.py' --pip authlib==1.8.0 joserfc==1.7.5 --cmd "python oidc.py" 2>&1 | tail -20

# --- 2026-10-05T17:21:21 · Fix output line, mark se04 tested, run checks
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs && f=op050-se04-oauth2-y-oidc.md && python3 - "$f" <<'EOF'
import sys,pathlib
p=pathlib.Path(sys.argv[1]);t=p.read_text()
t=t.replace("code_challenge: … (va en la redirección; el verifier se queda aquí)","code_challenge: D5R-dq6X2Pt84cAP …  (va en la redirección; el verifier se queda aquí)")
t=t.replace("Salida esperada, sin correr:\n\n```text\ncode_challenge","Salida esperada, sin correr (el `code_challenge` cambia en cada corrida):\n\n```text\ncode_challenge")
p.write_text(t)
EOF
cd ../../zz-code/python-for-java-devs-20261005-f516 && python3 probado.py $f && python3 plan.py 50 50 ✅ ✅ && cd - >/dev/null && python3 prompts/verificar-corpus.py 2>&1 | tail -1; python3 ../../zz-code/python-for-java-devs-20261005-f516/verificar_urls.py $f 2>&1 | tail -6

# --- 2026-10-05T17:21:27 · Find working authlib and joserfc doc URLs
grep -ho "https://[a-z.]*authlib[^ )]*" op0*.md | sort -u; for u in https://jose.authlib.org/en/guide/jwt/ https://jose.authlib.org/en/dev/guide/jwt/ https://jose.authlib.org/ https://docs.authlib.org/en/stable/client/index.html https://docs.authlib.org/ ; do echo "$(curl -s -o /dev/null -w '%{http_code} %{redirect_url}' -L "$u") $u"; done

# --- 2026-10-05T17:21:33 · Probe candidate authlib client doc URLs
grep -ln "docs.authlib.org/en/latest/oauth2/client/http/httpx.html" op0*.md; for u in https://docs.authlib.org/en/latest/oauth2/client/http/httpx.html https://docs.authlib.org/en/latest/client/ https://docs.authlib.org/en/latest/oauth2/client/ https://docs.authlib.org/en/latest/oauth2/client/web/starlette.html; do echo "$(curl -s -o /dev/null -w '%{http_code}' -L "$u") $u"; done

# --- 2026-10-05T17:21:39 · Replace broken URLs and recheck
f=op050-se04-oauth2-y-oidc.md && sed -i '' -e 's#- `authlib`, cliente OAuth: https://docs.authlib.org/en/latest/client/index.html#- `authlib`, cliente OAuth con Starlette: https://docs.authlib.org/en/latest/oauth2/client/web/starlette.html#' -e 's#https://jose.authlib.org/en/latest/guide/jwt/#https://jose.authlib.org/en/guide/jwt/#' $f && python3 ../../zz-code/python-for-java-devs-20261005-f516/verificar_urls.py $f | tail -1

# --- 2026-10-05T17:21:47 · Look up secrets-related versions
grep -n -i "pydantic\|hvac\|keyring\|sops\|python-dotenv\|detect-secrets" prompts/inventario-verificado.md | head

# --- 2026-10-05T17:22:44 · Smoke-test se05 and check its URLs
cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516 && python3 humo.py op051-se05-secretos.md se05 'config.py=@config.py' --pip pydantic-settings==2.15.0 pydantic==2.13.5 --cmd "python config.py" 2>&1 | tail -10; cd ../../cursos-algoritmos-lenguajes/python-for-java-devs && python3 ../../zz-code/python-for-java-devs-20261005-f516/verificar_urls.py op051-se05-secretos.md | tail -4

# --- 2026-10-05T17:22:56 · Fix secret file name and rerun smoke test
python3 - <<'EOF'
import pathlib
p=pathlib.Path("op051-se05-secretos.md");t=p.read_text()
old='(secrets_dir / "cartera_db_password").write_text("Cartera-9f3K!")'
assert old in t
t=t.replace(old,'(secrets_dir / "aurea_cartera_db_password").write_text("Cartera-9f3K!")   # con el prefijo')
old2="""- **`secrets_dir`** lee cada campo de un archivo con su nombre, que es exactamente la forma de los secretos de
  Docker (`/run/secrets/<nombre>`) y de los volúmenes de secretos de Kubernetes."""
assert old2 in t
t=t.replace(old2,"""- **`secrets_dir`** lee cada campo de un archivo con su nombre, que es exactamente la forma de los secretos de
  Docker (`/run/secrets/<nombre>`) y de los volúmenes de secretos de Kubernetes. El nombre del archivo **lleva
  el `env_prefix`** (`aurea_cartera_db_password`): sin él, Pydantic no lo encuentra y falla con *Field
  required*, un error que no dice nada de archivos y que este ejemplo cometió en su primera corrida.""")
p.write_text(t)
EOF
cd ../../zz-code/python-for-java-devs-20261005-f516 && python3 humo.py op051-se05-secretos.md se05 'config.py=@config.py' --pip pydantic-settings==2.15.0 pydantic==2.13.5 --cmd "python config.py" 2>&1 | tail -6

# --- 2026-10-05T17:23:04 · Mark se05 tested and run corpus verifier
python3 probado.py op051-se05-secretos.md && python3 plan.py 51 51 ✅ ✅ && cd ../../cursos-algoritmos-lenguajes/python-for-java-devs && python3 prompts/verificar-corpus.py 2>&1 | tail -1

# --- 2026-10-05T17:23:10 · Look up TLS-related versions
grep -n "| \`httpx\`\|truststore\|certifi" prompts/inventario-verificado.md | head -4

# --- 2026-10-05T17:24:09 · Smoke-test se06 TLS example and check URLs
cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516 && python3 humo.py op052-se06-tls-y-certificados.md se06 'tls.py=@tls.py' --pip httpx==0.28.1 cryptography==50.0.2 --cmd "python tls.py" 2>&1 | tail -8; cd ../../cursos-algoritmos-lenguajes/python-for-java-devs && python3 ../../zz-code/python-for-java-devs-20261005-f516/verificar_urls.py op052-se06-tls-y-certificados.md | tail -4

# --- 2026-10-05T17:24:28 · Add certificate extensions and rerun se06
python3 - <<'EOF'
import pathlib
p=pathlib.Path("op052-se06-tls-y-certificados.md");t=p.read_text()
def rep(a,b):
    global t
    assert t.count(a)==1,a
    t=t.replace(a,b)
rep("""           .add_extension(x509.BasicConstraints(ca=True, path_length=0), critical=True)
           .sign(ca_key, hashes.SHA256()))""","""           .add_extension(x509.BasicConstraints(ca=True, path_length=0), critical=True)
           .add_extension(x509.KeyUsage(digital_signature=False, content_commitment=False,
                                        key_encipherment=False, data_encipherment=False,
                                        key_agreement=False, key_cert_sign=True, crl_sign=True,
                                        encipher_only=False, decipher_only=False), critical=True)
           .add_extension(x509.SubjectKeyIdentifier.from_public_key(ca_key.public_key()), critical=False)
           .sign(ca_key, hashes.SHA256()))""")
rep("""            .add_extension(x509.SubjectAlternativeName([x509.DNSName("localhost")]), critical=False)
            .sign(ca_key, hashes.SHA256()))""","""            .add_extension(x509.SubjectAlternativeName([x509.DNSName("localhost")]), critical=False)
            .add_extension(x509.AuthorityKeyIdentifier.from_issuer_public_key(ca_key.public_key()),
                           critical=False)
            .sign(ca_key, hashes.SHA256()))""")
rep("""- **El certificado del servidor dura 90 días**""","""- **`KeyUsage`, `SubjectKeyIdentifier` y `AuthorityKeyIdentifier`** no son adorno: desde Python 3.13,
  `create_default_context()` activa `VERIFY_X509_STRICT`, y un certificado sin el identificador de la clave
  de su emisor se rechaza con `Missing Authority Key Identifier`. La primera versión de este ejemplo no los
  tenía y falló exactamente así.
- **El certificado del servidor dura 90 días**""")
rep("""**`verify=False` "solo en desarrollo".**""","""**La CA vieja que deja de servir al actualizar Python.** Una CA interna hecha hace años con un script de
OpenSSL mínimo funcionaba con Python 3.12 y falla con 3.13 o posterior por `VERIFY_X509_STRICT` (§3). La
tentación es quitar el modo estricto (`ctx.verify_flags &= ~ssl.VERIFY_X509_STRICT`); la corrección es volver a
emitir los certificados con las extensiones que exige el RFC 5280. Lo primero es aceptable como puente de días,
con fecha de retiro escrita.

**`verify=False` "solo en desarrollo".**""")
p.write_text(t)
EOF
cd ../../zz-code/python-for-java-devs-20261005-f516 && python3 humo.py op052-se06-tls-y-certificados.md se06 'tls.py=@tls.py' --pip httpx==0.28.1 cryptography==50.0.2 --cmd "python tls.py" 2>&1 | tail -5

# --- 2026-10-05T17:24:38 · Fix table cell, mark se06 tested, verify corpus
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs && sed -i '' 's/| \*\*Nombre\*\* | ¿Es para el nombre al que me conecté? | `Hostname mismatch` |/| **Nombre** | ¿Es para el nombre al que me conecté? | `Hostname mismatch` (o `IP address mismatch`) |/' op052-se06-tls-y-certificados.md && grep -c "IP address mismatch\`)" op052-se06-tls-y-certificados.md && cd ../../zz-code/python-for-java-devs-20261005-f516 && python3 probado.py op052-se06-tls-y-certificados.md && python3 plan.py 52 52 ✅ ✅ && cd - >/dev/null && python3 prompts/verificar-corpus.py | tail -1

# --- 2026-10-05T17:24:43 · Look up app-defence tool versions
grep -n -i "bandit\|pip-audit\|pyyaml\|jinja2\|semgrep\|ruff\b\|| \`ruff" prompts/inventario-verificado.md | head; sed -n '/INVENTARIO = {/,/^}/p' prompts/check-inventario.py | grep -n '"se"' 

# --- 2026-10-05T17:24:46 · Find se track entry in inventory script
grep -n '"se"\|pip-audit' prompts/check-inventario.py | head

# --- 2026-10-05T17:24:49 · Show se track package list
sed -n 46,49p prompts/check-inventario.py

# --- 2026-10-05T17:24:52 · Add packages to se track and refresh inventory
sed -i '' '48s/"detect-secrets", "itsdangerous", "truststore"\],/"detect-secrets", "itsdangerous", "truststore", "PyYAML", "Jinja2", "pydantic-settings",\n           "httpx"],/' prompts/check-inventario.py && sed -n 46,50p prompts/check-inventario.py && python3 prompts/check-inventario.py se 2>&1 | tail -3 && grep -n "PyYAML" prompts/inventario-verificado.md

# --- 2026-10-05T17:26:07 · Smoke-test se07 and run bandit in container
cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516 && python3 humo.py op053-se07-defensa-de-la-aplicacion.md se07 'puertas.py=@puertas.py' --pip PyYAML==6.0.3 Jinja2==3.1.6 bandit==1.9.4 --cmd 'python puertas.py; echo ---; bandit -q -f custom --msg-template "{line}: {test_id} {severity} {msg}" puertas.py' 2>&1 | tail -20; cd ../../cursos-algoritmos-lenguajes/python-for-java-devs && python3 ../../zz-code/python-for-java-devs-20261005-f516/verificar_urls.py op053-se07-defensa-de-la-aplicacion.md | tail -4

# --- 2026-10-05T17:26:28 · Fix Jinja payload, rerun example and bandit
python3 - <<'EOF'
import pathlib
p=pathlib.Path("op053-se07-defensa-de-la-aplicacion.md");t=p.read_text()
a="""            "{{ cycler.__init__.__globals__.os.popen('echo código del atacante (jinja)').read() }}")"""
assert a in t
t=t.replace(a,"""            "{{ lipsum.__globals__.__builtins__.__import__('os')"
            ".popen('echo código del atacante (jinja)').read() }}")""")
p.write_text(t)
EOF
cd ../../zz-code/python-for-java-devs-20261005-f516 && python3 humo.py op053-se07-defensa-de-la-aplicacion.md se07 'puertas.py=@puertas.py' --pip PyYAML==6.0.3 Jinja2==3.1.6 bandit==1.9.4 --cmd 'python puertas.py' 2>&1 | tail -6; docker run --rm --label curso=python-for-java-devs -v "$PWD/salidas/se07:/w" -w /w python:3.14.7 sh -c 'pip install -q bandit==1.9.4 2>/dev/null; bandit -q -f custom --msg-template "{line}: {test_id} {severity} {msg}" puertas.py'

# --- 2026-10-05T17:26:42 · Remove parentheses from payload and rerun
sed -i '' "s/.popen('echo código del atacante (jinja)')/.popen('echo código del atacante: jinja')/" op053-se07-defensa-de-la-aplicacion.md && grep -c "atacante: jinja" op053-se07-defensa-de-la-aplicacion.md && cd ../../zz-code/python-for-java-devs-20261005-f516 && python3 humo.py op053-se07-defensa-de-la-aplicacion.md se07 'puertas.py=@puertas.py' --pip PyYAML==6.0.3 Jinja2==3.1.6 --cmd 'python puertas.py' 2>&1 | tail -6 | cat -A | cut -c1-120 | sed -n 1,8p

# --- 2026-10-05T17:26:48 · Rerun se07 showing line ends
python3 humo.py op053-se07-defensa-de-la-aplicacion.md se07 'puertas.py=@puertas.py' --pip PyYAML==6.0.3 Jinja2==3.1.6 --cmd 'python puertas.py' 2>&1 | tail -6 | cat -e

# --- 2026-10-05T17:27:02 · Update se07 outputs and mark it tested
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs && python3 - <<'EOF'
import pathlib
p=pathlib.Path("op053-se07-defensa-de-la-aplicacion.md");t=p.read_text()
def rep(a,b):
    global t
    assert t.count(a)==1,a
    t=t.replace(a,b)
rep("""Template:       Hola Andrés, tu cita es mañana. código del atacante (jinja)

Sandboxed:      rechazado: access to attribute '__init__' of 'Cycler' object is unsafe.""",
"""Template:       Hola Andrés, tu cita es mañana. código del atacante: jinja

Sandboxed:      rechazado: access to attribute '__globals__' of 'function' object is unsafe.""")
rep("""26: B301 MEDIUM Pickle and modules that wrap it can be unpickled when used to deserialize untrusted data, possible security issue.
32: B701 HIGH By default, jinja2 sets autoescape to False. Consider using autoescape=True or use the select_autoescape function to mitigate XSS vulnerabilities.
```

`bandit` encontró el YAML y el `pickle`. En la plantilla, avisa del `autoescape` —que es otro problema, el de
inyectar HTML— pero **no** de que la plantilla venga del usuario: eso no lo ve ninguna herramienta estática,
porque depende de dónde sale el texto.""",
"""26: B301 MEDIUM Pickle and modules that wrap it can be unsafe when used to deserialize untrusted data, possible security issue.
```

`bandit` encontró el YAML y el `pickle`, y **no dice nada de la plantilla**: su regla de Jinja2 (B701, el
`autoescape` apagado) mira las llamadas a `Environment`, no a `Template`, y de todos modos trata otro problema,
el de inyectar HTML. Que el texto de la plantilla lo escriba un usuario no lo ve ninguna herramienta estática,
porque depende de dónde sale el texto.

Una nota de la corrida: la primera versión de la carga de Jinja2 terminaba en `(jinja)`, y `os.popen` la pasó
por `sh`, que falló con `Syntax error: "(" unexpected`. El error salió en la consola del servidor, no en la
respuesta: la carga sí se había ejecutado. Así se ve muchas veces una inyección real en una bitácora.""")
rep("| Plantilla del usuario | `jinja2.Template(texto_del_usuario)` | `SandboxedEnvironment`, o variables en vez de plantillas | revisión (bandit ve el `autoescape`) |",
    "| Plantilla del usuario | `jinja2.Template(texto_del_usuario)` | `SandboxedEnvironment`, o variables en vez de plantillas | Solo revisión humana |")
p.write_text(t)
EOF
cd ../../zz-code/python-for-java-devs-20261005-f516 && python3 probado.py op053-se07-defensa-de-la-aplicacion.md && grep -n "Salida" ../../cursos-algoritmos-lenguajes/python-for-java-devs/op053-se07-defensa-de-la-aplicacion.md

# --- 2026-10-05T17:27:09 · Label bandit output, verify, mark plan
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs && sed -i '' 's/^Y lo que dice `bandit` del mismo archivo:$/Y lo que dice `bandit` del mismo archivo (bandit 1.9.4, 05\/10\/2026):/' op053-se07-defensa-de-la-aplicacion.md && grep -n "bandit 1.9.4, 05" op053-se07-defensa-de-la-aplicacion.md && python3 prompts/verificar-corpus.py | tail -1 && python3 ../../zz-code/python-for-java-devs-20261005-f516/plan.py 53 53 ✅ ✅

# --- 2026-10-05T17:28:04 · Smoke-test se08 audit script and check URLs
cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516 && python3 humo.py op054-se08-veredicto.md se08 'auditoria.py="""Las siete' --cmd 'python auditoria.py' 2>&1 | tail -10; cd ../../cursos-algoritmos-lenguajes/python-for-java-devs && python3 ../../zz-code/python-for-java-devs-20261005-f516/verificar_urls.py op054-se08-veredicto.md | tail -3

# --- 2026-10-05T17:28:22 · Recheck the two failing URLs with curl
for u in https://owasp.org/www-project-application-security-verification-standard/ "https://www.funcionpublica.gov.co/eva/gestornormativo/norma.php?i=49981"; do echo "$(curl -s -o /dev/null -w '%{http_code}' -L -m 20 "$u") $u"; done; grep -l "norma.php?i=49981" /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs/op0*.md

# --- 2026-10-05T17:28:48 · Follow OWASP ASVS redirect
curl -s -o /dev/null -w '%{http_code} %{url_effective}\n' -L -m 20 --max-redirs 10 https://owasp.org/www-project-application-security-verification-standard/; curl -sI -m 20 https://owasp.org/www-project-application-security-verification-standard/ | grep -i location

# --- 2026-10-05T17:29:27 · Try OWASP ASVS without trailing slash and GitHub
for u in https://owasp.org/www-project-application-security-verification-standard https://github.com/OWASP/ASVS; do echo "$(curl -s -o /dev/null -w '%{http_code}' -m 20 "$u") $u"; done

# --- 2026-10-05T17:29:51 · Replace OWASP URL; inspect Python URL failure
sed -i '' 's#- OWASP, \*Application Security Verification Standard\*: https://owasp.org/www-project-application-security-verification-standard/#- OWASP, *Application Security Verification Standard* (el repositorio, con la versión vigente): https://github.com/OWASP/ASVS#' op054-se08-veredicto.md && grep -n "OWASP/ASVS" op054-se08-veredicto.md && python3 -c "
import urllib.request
try: urllib.request.urlopen('https://www.funcionpublica.gov.co/eva/gestornormativo/norma.php?i=49981',timeout=20)
except Exception as e: print(e)"

# --- 2026-10-05T17:30:00 · Close T7 in plan with log entry
cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516 && python3 probado.py op054-se08-veredicto.md && python3 plan.py 54 54 ✅ ✅ && python3 plan.py tanda T7 ✅ && python3 plan.py dondeesta "T1–T7 cerradas (54 de 176). Sigue T8 tx (op055)." && python3 plan.py bitacora "T7 se (op047–op054), 05/10/2026: las ocho secciones probadas en contenedor. La corrida encontró: el archivo de secretos de pydantic-settings lleva el env_prefix (se05); Python 3.13+ exige AKI/SKI/KeyUsage por VERIFY_X509_STRICT (se06); la carga SSTI con cycler ya no funciona en Jinja2 3.1.6 y bandit no marca Template() (se07); bcrypt 5 lanza ValueError con más de 72 bytes (confirmado). URL: dos rutas de docs de authlib/joserfc cambiadas; owasp.org reemplazado por GitHub (bucle de redirección); funcionpublica.gov.co sirve cadena incompleta (válida en navegador y curl, falla en Python)." && cd ../../cursos-algoritmos-lenguajes/python-for-java-devs && python3 prompts/verificar-corpus.py | tail -1 && grep -n "Dónde está\|dondeesta\|^> \*\*Estado" prompts/plan-de-produccion-carta.md | head -3

# --- 2026-10-05T17:30:05 · Inspect status line and plan.py handler
cd /Users/oskar/Developer/Learning/courses-ia-generated && sed -n 102,106p cursos-algoritmos-lenguajes/python-for-java-devs/prompts/plan-de-produccion-carta.md; grep -n "dondeesta" -A6 zz-code/python-for-java-devs-20261005-f516/plan.py | head -12

# --- 2026-10-05T17:30:12 · Fix plan.py status format and verify T7 rows
cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516 && python3 - <<'EOF'
import pathlib
p=pathlib.Path("plan.py");t=p.read_text()
a='''"> 🚦 **Dónde está la producción " + a[1]'''
assert a in t
t=t.replace(a,'''"> 🚦 **Dónde está la producción (" + __import__("datetime").date.today().strftime("%d/%m/%Y") + "):** " + a[1]''')
p.write_text(t)
EOF
python3 plan.py dondeesta "T1–T7 cerradas (54 de 176). Sigue T8 tx (op055)." && grep -n "🚦" ../../cursos-algoritmos-lenguajes/python-for-java-devs/prompts/plan-de-produccion-carta.md; grep -n "| \*\*T7\*\*\|T7 se (op047" ../../cursos-algoritmos-lenguajes/python-for-java-devs/prompts/plan-de-produccion-carta.md | cut -c1-120

# --- 2026-10-05T17:30:16 · Compare bitácora entry format
sed -n 300,322p ../../cursos-algoritmos-lenguajes/python-for-java-devs/prompts/plan-de-produccion-carta.md | cut -c1-160

# --- 2026-10-05T17:30:25 · Rewrite T7 log entry; count exercises
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs && python3 - <<'EOF'
import pathlib,re
p=pathlib.Path("prompts/plan-de-produccion-carta.md");t=p.read_text()
old=re.search(r"^T7 se \(op047–op054\).*$",t,re.M).group(0)
new=("**2026-10-05 · T7 (`se`) cerrada.** Escritas op047–op054 (8 secciones, 76 ejercicios), **las ocho probadas "
"en contenedor**. **Hallazgos y defectos propios:** el archivo de secretos de `pydantic-settings` lleva el "
"`env_prefix` (se05, falló con *Field required*); Python 3.13+ activa `VERIFY_X509_STRICT` y rechaza la CA sin "
"`AuthorityKeyIdentifier` (se06); la carga SSTI clásica con `cycler` ya no funciona en Jinja2 3.1.6 y se cambió "
"por `lipsum.__globals__`, y `bandit` no marca `Template()` (se07: se quitó un B701 inventado); la carga con "
"paréntesis rompió el `sh` de `os.popen`; `bcrypt` 5 lanza `ValueError` con más de 72 bytes (confirmado). "
"**URL:** dos rutas de docs de `authlib`/`joserfc` cambiadas; owasp.org reemplazado por GitHub (bucle de "
"redirección); funcionpublica.gov.co sirve cadena incompleta —válida en navegador y curl, falla en Python—, se "
"conserva. **Inventario:** `PyYAML`, `Jinja2`, `pydantic-settings` y `httpx` agregados al track `se`.")
t=t.replace(old,new)
p.write_text(t)
EOF
sed -n '/## 7. 📓 Bitácora/,+3p' prompts/plan-de-produccion-carta.md | cut -c1-120; grep -c "^### 🧪\|^## 🧪" op04[7-9]*.md op05[0-4]*.md >/dev/null; for f in op04[7-9]*.md op05[0-4]*.md; do grep -o "Ejercicios ([0-9]*)" $f; done | tr '\n' ' '

# --- 2026-10-05T17:30:30 · Fix exercise count; read memory entries
sed -i '' 's/Escritas op047–op054 (8 secciones, 76 ejercicios)/Escritas op047–op054 (8 secciones, 78 ejercicios)/' prompts/plan-de-produccion-carta.md && grep -c "78 ejercicios" prompts/plan-de-produccion-carta.md; M=/Users/oskar/.claude/projects/-Users-oskar-Developer-Learning-courses-ia-generated/memory; grep -n "carta" $M/MEMORY.md; sed -n 1,12p $M/python-carta-produccion.md

# --- 2026-10-05T17:30:34 · Update memory index line for T7
M=/Users/oskar/.claude/projects/-Users-oskar-Developer-Learning-courses-ia-generated/memory; sed -i '' 's/T1–T6 (lg, au, co, wf, qa, ob) cerradas el 05\/10\/2026: 46 de 176\./T1–T7 (lg, au, co, wf, qa, ob, se) cerradas el 05\/10\/2026: 54 de 176; sigue T8 tx./' $M/MEMORY.md && grep -n "54 de 176" $M/MEMORY.md | cut -c1-80; grep -n "T1\|46\|T6" $M/python-carta-produccion.md | head

# --- 2026-10-05T17:30:39 · List tx rows and prompts directory
grep -n "| op0[5-6][0-9] .*tx" prompts/plan-de-produccion-carta.md; ls prompts/ | head -30; sed -n '/"tx"/,/\]/p' prompts/check-inventario.py

# --- 2026-10-05T17:30:42 · Locate tx track in proposals doc
grep -n "tx" prompts/propuestas-temas-opcionales.md | head -20

# --- 2026-10-05T17:30:47 · Read tx proposal and tx versions
sed -n 457,495p prompts/propuestas-temas-opcionales.md; grep -n "| \`\(Jinja2\|Mako\|Chameleon\|chevron\|Pygments\|rich\|tree-sitter\|tree-sitter-python\|markdown-it-py\|mistune\|Markdown\|docutils\|Sphinx\|mkdocs\|mkdocs-material\|pdoc\|griffe\|cookiecutter\|copier\|Faker\|regex\|Babel\|Unidecode\|ftfy\|htpy\|dominate\|libcst\|PyICU\|Django\)\`" prompts/inventario-verificado.md | sort -u -t'|' -k2,2

# --- 2026-10-05T17:30:53 · Read start of Áurea narrative
sed -n 1,40p 00-historia-de-aurea.md | cut -c1-200

# --- 2026-10-05T17:31:54 · Smoke-test tx01 and check URLs
cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516 && python3 humo.py op055-tx01-el-eje.md tx01 'eje.py=@eje.py' --pip Jinja2==3.1.6 htpy==26.5.1 --cmd 'python eje.py' 2>&1 | tail -7; cd ../../cursos-algoritmos-lenguajes/python-for-java-devs && python3 ../../zz-code/python-for-java-devs-20261005-f516/verificar_urls.py op055-tx01-el-eje.md | tail -3

# --- 2026-10-05T17:32:04 · Fix htpy output, mark tx01 tested
python3 - <<'EOF'
import pathlib
p=pathlib.Path("op055-tx01-el-eje.md");t=p.read_text()
a="árbol       ✅ <p>Hola <strong>María José D&#x27;Alessandro</strong>"
assert t.count(a)==1
t=t.replace(a,"árbol       ✅ <p>Hola <strong>María José D&#39;Alessandro</strong>")
a2="(`&#x27;` y `&#39;` son el mismo apóstrofo)"
assert a2 in t
t=t.replace(a2,"(`&#x27;` es el de `html.escape` y `&#39;` el de MarkupSafe, que usan Jinja2 y `htpy`: el mismo apóstrofo)")
p.write_text(t)
EOF
cd ../../zz-code/python-for-java-devs-20261005-f516 && python3 probado.py op055-tx01-el-eje.md && python3 plan.py 55 55 ✅ ✅ && cd - >/dev/null && python3 prompts/verificar-corpus.py | tail -1

# --- 2026-10-05T17:32:59 · Smoke-test tx02 report and check URLs
cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516 && python3 humo.py op056-tx02-jinja2-a-fondo.md tx02 'reporte.py=@reporte.py' --pip Jinja2==3.1.6 --cmd 'python reporte.py' 2>&1 | tail -18 | cat -e; cd ../../cursos-algoritmos-lenguajes/python-for-java-devs && python3 ../../zz-code/python-for-java-devs-20261005-f516/verificar_urls.py op056-tx02-jinja2-a-fondo.md | tail -3

# --- 2026-10-05T17:33:10 · Fix tx02 output, mark tested, verify
python3 - <<'EOF'
import pathlib
p=pathlib.Path("op056-tx02-jinja2-a-fondo.md");t=p.read_text()
def rep(a,b):
    global t
    assert t.count(a)==1,a
    t=t.replace(a,b)
rep("<p>Franquiciado: Édgar Rojas</p>\n<table>\n<tr><td>Facturado","<p>Franquiciado: Édgar Rojas</p><table>\n<tr><td>Facturado")
rep("""  como YAML—.
- **`DictLoader`**""","""  como YAML—. También tienen su costo, visible en la salida: `<table>` quedó pegado al párrafo del
  franquiciado, porque `trim_blocks` se comió el salto de línea que seguía a `{% endif %}`. Cuando importa, se
  controla etiqueta por etiqueta con `{%-` y `-%}`.
- **`DictLoader`**""")
p.write_text(t)
EOF
cd ../../zz-code/python-for-java-devs-20261005-f516 && python3 probado.py op056-tx02-jinja2-a-fondo.md && python3 plan.py 56 56 ✅ ✅ && cd - >/dev/null && python3 prompts/verificar-corpus.py | tail -1

# --- 2026-10-05T17:34:09 · Smoke-test tx03 six engines and check URLs
cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516 && python3 humo.py op057-tx03-las-otras-plantillas.md tx03 'seis.py=@seis.py' --pip Jinja2==3.1.6 Django==6.1.1 Mako==1.4.3 Chameleon==4.6.0 chevron==0.14.0 --cmd 'python seis.py' 2>&1 | tail -10; cd ../../cursos-algoritmos-lenguajes/python-for-java-devs && python3 ../../zz-code/python-for-java-devs-20261005-f516/verificar_urls.py op057-tx03-las-otras-plantillas.md | tail -3

# --- 2026-10-05T17:34:29 · Fill measured times, correct Mako claim, mark tested
python3 - <<'EOF'
import pathlib
p=pathlib.Path("op057-tx03-las-otras-plantillas.md");t=p.read_text()
def rep(a,b):
    global t
    assert t.count(a)==1,a
    t=t.replace(a,b)
for label,ms in [("string.Template       ❌",9),("Jinja2 (por defecto)  ❌",44),("Django                ✅",55),("Mako (por defecto)    ❌",44),("Mako con h            ✅",51),("Chameleon             ✅",35),("chevron               ✅",51)]:
    rep(f"{label}     … ms/10k", f"{label} {ms:7d} ms/10k")
rep("Salida esperada, sin correr (los tiempos son de la máquina que corre):","Salida esperada, sin correr (los tiempos son de la máquina que corre; estos, de un contenedor en un portátil):")
rep("""explícitamente en la configuración aunque coincida con lo que quieres.""","""explícitamente en la configuración aunque coincida con lo que quieres.

Y los tiempos dicen lo contrario de lo que suele repetirse: diez mil renderizados cuestan entre 35 y 55 ms en
cualquiera de los motores de verdad, es decir, unos 5 microsegundos por correo. Para los pocos miles de
recordatorios diarios de Áurea, **la velocidad no decide el motor**; deciden el escape por defecto y cuánta lógica
deja meter.""")
rep("""- **Mako compila la plantilla a un módulo de Python**, y por eso suele salir entre los más rápidos. El mismo hecho es
  su riesgo: `<% import os %>` dentro de una plantilla de Mako es Python normal.""","""- **Mako compila la plantilla a un módulo de Python**, y tiene fama de ser el más rápido. En esta medición empata con
  Jinja2 (que también compila a Python) y pierde con Chameleon: la fama viene de comparaciones de hace quince años.
  Lo que sí es cierto es su riesgo: `<% import os %>` dentro de una plantilla de Mako es Python normal.
- **`chevron` vuelve a analizar la plantilla en cada llamada**, porque recibe la cadena y no un objeto compilado; aun
  así queda en el mismo rango.""")
p.write_text(t)
EOF
cd ../../zz-code/python-for-java-devs-20261005-f516 && python3 probado.py op057-tx03-las-otras-plantillas.md && grep -n "Salida (Python" ../../cursos-algoritmos-lenguajes/python-for-java-devs/op057-tx03-las-otras-plantillas.md && python3 plan.py 57 57 ✅ ✅

# --- 2026-10-05T17:35:28 · Smoke-test tx04 and check URLs
python3 humo.py op058-tx04-codigo-como-dato.md tx04 'plata.py=@plata.py' --pip Pygments==2.21.0 tree-sitter==0.26.0 tree-sitter-python==0.25.0 --cmd 'python plata.py' 2>&1 | tail -8; cd ../../cursos-algoritmos-lenguajes/python-for-java-devs && python3 ../../zz-code/python-for-java-devs-20261005-f516/verificar_urls.py op058-tx04-codigo-como-dato.md | tail -3

# --- 2026-10-05T17:35:36 · Mark tx04 tested and verify corpus
cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516 && python3 probado.py op058-tx04-codigo-como-dato.md && python3 plan.py 58 58 ✅ ✅ && cd - >/dev/null && python3 prompts/verificar-corpus.py | tail -1

# --- 2026-10-05T17:36:30 · Smoke-test tx05 and check URLs
cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516 && python3 humo.py op059-tx05-markdown.md tx05 'procedimiento.py=@procedimiento.py' --pip markdown-it-py==4.2.0 mistune==3.3.4 Markdown==3.11 --cmd 'python procedimiento.py' 2>&1 | tail -12; cd ../../cursos-algoritmos-lenguajes/python-for-java-devs && python3 ../../zz-code/python-for-java-devs-20261005-f516/verificar_urls.py op059-tx05-markdown.md | tail -3

# --- 2026-10-05T17:36:40 · Check mistune escape option in container
cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516 && ls salidas/tx05/; head -2 salidas/tx05/*.txt 2>/dev/null; docker run --rm --label curso=python-for-java-devs python:3.14.7 sh -c 'pip install -q mistune==3.3.4 2>/dev/null; python -c "
import mistune
print(mistune.create_markdown(escape=True)(\"<script>x</script>\n\n- a\n  - b\"))"'

# --- 2026-10-05T17:36:48 · Add mistune escape variant and rerun tx05
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs && python3 - <<'EOF'
import pathlib
p=pathlib.Path("op059-tx05-markdown.md");t=p.read_text()
def rep(a,b):
    global t
    assert t.count(a)==1,a
    t=t.replace(a,b)
rep('''    "mistune": mistune.html,
''','''    "mistune (html)": mistune.html,
    "mistune (escape=True)": mistune.create_markdown(escape=True),
''')
rep("| `mistune` 3.3.4 | CommonMark casi completo | Según la función | Sí: su AST como dicts | Velocidad, *plugins* simples |",
    "| `mistune` 3.3.4 | CommonMark casi completo | **Pasa** con `mistune.html`; `escape=True` lo escapa | Sí: su AST como dicts | Velocidad, *plugins* simples |")
p.write_text(t)
EOF
cd ../../zz-code/python-for-java-devs-20261005-f516 && python3 humo.py op059-tx05-markdown.md tx05 'procedimiento.py=@procedimiento.py' --pip markdown-it-py==4.2.0 mistune==3.3.4 Markdown==3.11 --cmd 'python procedimiento.py' 2>&1 | tail -13 | head -5

# --- 2026-10-05T17:36:57 · Capture exact tx05 output lines
python3 humo.py op059-tx05-markdown.md tx05 'procedimiento.py=@procedimiento.py' --pip markdown-it-py==4.2.0 mistune==3.3.4 Markdown==3.11 --cmd 'python procedimiento.py' 2>/dev/null | grep "lista anidada" > /private/tmp/claude-501/-Users-oskar-Developer-Learning-courses-ia-generated/5c52573d-4a56-4998-bca3-5d686d0c5368/scratchpad/tx05.txt; cat /private/tmp/claude-501/-Users-oskar-Developer-Learning-courses-ia-generated/5c52573d-4a56-4998-bca3-5d686d0c5368/scratchpad/tx05.txt

# --- 2026-10-05T17:37:08 · Write real tx05 output, mark tested
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs && python3 - <<'EOF'
import pathlib,re
S="/private/tmp/claude-501/-Users-oskar-Developer-Learning-courses-ia-generated/5c52573d-4a56-4998-bca3-5d686d0c5368/scratchpad/tx05.txt"
real=pathlib.Path(S).read_text().rstrip("\n")
p=pathlib.Path("op059-tx05-markdown.md");t=p.read_text()
old=re.search(r"```text\nmarkdown-it \(commonmark\).*?python-markdown[^\n]*",t,re.S).group(0)
t=t.replace(old,"```text\n"+real)
def rep(a,b):
    global t
    assert t.count(a)==1,a
    t=t.replace(a,b)
rep("""Cuatro configuraciones, tres comportamientos. La que más se usa en tutoriales —`markdown.markdown(texto)`— aplana la
lista que la administradora escribió con dos espacios y deja pasar el `<script>`. El *preset* `js-default` de
`markdown-it-py` —el que imita a `markdown-it` de JavaScript— hace las dos cosas bien.""","""Cinco configuraciones, y tres de ellas dejan pasar el `<script>`. La que más se usa en tutoriales
—`markdown.markdown(texto)`— además aplana la lista que la administradora escribió con dos espacios. `mistune.html`, la
función que su documentación muestra primero, también deja pasar el HTML: hay que crear el *renderer* con
`escape=True`. El *preset* `js-default` de `markdown-it-py` —el que imita a `markdown-it` de JavaScript— y `mistune`
con `escape=True` hacen las dos cosas bien.""")
p.write_text(t)
EOF
sed -n '/^```text$/,/^```$/p' op059-tx05-markdown.md | head -8; cd ../../zz-code/python-for-java-devs-20261005-f516 && python3 probado.py op059-tx05-markdown.md && python3 plan.py 59 59 ✅ ✅ && cd - >/dev/null && python3 prompts/verificar-corpus.py | tail -1

# --- 2026-10-05T17:38:04 · Smoke-test tx06 doctest and pdoc
cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516 && python3 humo.py op060-tx06-documentacion.md tx06 'cartera.py=@cartera.py' --pip pdoc==16.0.0 --cmd 'python -m doctest -v cartera.py | tail -3; pdoc cartera.py -o docs && ls docs; echo ----; sed -i "s/tasa_mensual_pct: int = 15/tasa_mensual_pct: int = 18/" cartera.py; python -m doctest cartera.py | head -8' 2>&1 | tail -16; cd ../../cursos-algoritmos-lenguajes/python-for-java-devs && python3 ../../zz-code/python-for-java-devs-20261005-f516/verificar_urls.py op060-tx06-documentacion.md | tail -3

# --- 2026-10-05T17:38:15 · Capture tail of doctest verbose summary
cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516 && python3 humo.py op060-tx06-documentacion.md tx06 'cartera.py=@cartera.py' --cmd 'python -m doctest -v cartera.py | tail -9' 2>&1 | tail -11

# --- 2026-10-05T17:38:22 · Fix doctest count in tx06, mark tested
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs && python3 - <<'EOF'
import pathlib
p=pathlib.Path("op060-tx06-documentacion.md");t=p.read_text()
def rep(a,b):
    global t
    assert t.count(a)==1,a
    t=t.replace(a,b)
rep("""3 items passed all tests:
5 tests in 3 items.
5 passed.
Test passed.""","""6 tests in 3 items.
6 passed.
Test passed.""")
rep("Cinco ejemplos que son pruebas,","Seis ejemplos que son pruebas,")
rep("""- **La salida del primer bloque pasa por `tail -3`**, y por eso muestra la línea de resumen de `doctest -v`
  incompleta: es el final de un informe más largo.
""","""- **La salida del primer bloque pasa por `tail -3`**: `doctest -v` imprime cada ejemplo y su resultado, y el resumen
  es lo único que interesa en un informe.
""")
rep("**Criterio:** los cinco aparecen como pruebas de `pytest`.","**Criterio:** reportas cuántas pruebas cuenta `pytest` y por qué no son seis.")
p.write_text(t)
EOF
cd ../../zz-code/python-for-java-devs-20261005-f516 && python3 probado.py op060-tx06-documentacion.md && python3 plan.py 60 60 ✅ ✅ && cd - >/dev/null && python3 prompts/verificar-corpus.py | tail -1

# --- 2026-10-05T17:39:17 · Smoke-test tx07 generator and check URLs
cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516 && python3 humo.py op061-tx07-generacion-de-codigo.md tx07 'generar.py="""Generar Python' --cmd 'python generar.py' 2>&1 | tail -22; cd ../../cursos-algoritmos-lenguajes/python-for-java-devs && python3 ../../zz-code/python-for-java-devs-20261005-f516/verificar_urls.py op061-tx07-generacion-de-codigo.md | tail -3

# --- 2026-10-05T17:39:21 · Get the strings-version error line
cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516 && python3 humo.py op061-tx07-generacion-de-codigo.md tx07 'generar.py="""Generar Python' --cmd 'python generar.py' 2>&1 | grep -- "--- cadenas"

# --- 2026-10-05T17:39:30 · Fix tx07 output, mark tested
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs && python3 - <<'EOF'
import pathlib
p=pathlib.Path("op061-tx07-generacion-de-codigo.md");t=p.read_text()
def rep(a,b):
    global t
    assert t.count(a)==1,a
    t=t.replace(a,b)
rep("--- cadenas: NO compila — invalid syntax (línea 9)","--- cadenas: NO compila — unterminated string literal (detected at line 9) (línea 9)")
rep("""La versión con cadenas tiene dos errores y no compila; los dos son de datos, no de la plantilla, y aparecieron el día
que el catálogo trajo una columna que nadie había previsto.""","""La versión con cadenas tiene dos errores y no compila; los dos son de datos, no de la plantilla, y aparecieron el día
que el catálogo trajo una columna que nadie había previsto. El compilador solo reporta el de la línea 9 —la comilla—
aunque el de la línea 8 está antes: el analizador léxico corre primero sobre todo el archivo. Quien corrija la comilla
se encuentra después con el `class`, en una segunda vuelta.""")
p.write_text(t)
EOF
cd ../../zz-code/python-for-java-devs-20261005-f516 && python3 probado.py op061-tx07-generacion-de-codigo.md && python3 plan.py 61 61 ✅ ✅ && cd - >/dev/null && python3 prompts/verificar-corpus.py | tail -1

# --- 2026-10-05T17:40:36 · Smoke-test tx08 and check URLs
cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516 && python3 humo.py op062-tx08-texto-dificil.md tx08 'texto.py=@texto.py' --pip regex==2026.9.29 Babel==2.18.0 --cmd 'python texto.py' 2>&1 | tail -13; cd ../../cursos-algoritmos-lenguajes/python-for-java-devs && python3 ../../zz-code/python-for-java-devs-20261005-f516/verificar_urls.py op062-tx08-texto-dificil.md | tail -3

# --- 2026-10-05T17:40:49 · Fix tx08 outputs, mark tested
python3 - <<'EOF'
import pathlib
p=pathlib.Path("op062-tx08-texto-dificil.md");t=p.read_text()
def rep(a,b):
    global t
    assert t.count(a)==1,a
    t=t.replace(a,b)
rep("sorted:           ['Mendoza', 'Nuñez', 'Ochoa', 'Zuluaga', 'ávila', 'Álvarez', 'Ñañez']","sorted:           ['Mendoza', 'Nuñez', 'Ochoa', 'Zuluaga', 'Álvarez', 'Ñañez', 'ávila']")
rep("$ 1.234.567,50\n","$1.234.567,50\n")
rep("`sorted` manda todo lo que\nlleva tilde al final;","`sorted` manda todo lo que\nlleva tilde al final, en el orden de sus puntos de código (`Á` es U+00C1, `Ñ` U+00D1, `á` U+00E1);")
p.write_text(t)
EOF
cd ../../zz-code/python-for-java-devs-20261005-f516 && python3 probado.py op062-tx08-texto-dificil.md && python3 plan.py 62 62 ✅ ✅ && cd - >/dev/null && python3 prompts/verificar-corpus.py | tail -1

# --- 2026-10-05T17:41:44 · Smoke-test tx09 and check URLs
cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516 && python3 humo.py op063-tx09-veredicto.md tx09 'densidad.py=@densidad.py' --pip Jinja2==3.1.6 --cmd 'python densidad.py' 2>&1 | tail -4; cd ../../cursos-algoritmos-lenguajes/python-for-java-devs && python3 ../../zz-code/python-for-java-devs-20261005-f516/verificar_urls.py op063-tx09-veredicto.md | tail -3

# --- 2026-10-05T17:41:58 · Fix lexer token handling and rerun tx09
python3 - <<'EOF'
import pathlib
p=pathlib.Path("op063-tx09-veredicto.md");t=p.read_text()
def rep(a,b):
    global t
    assert t.count(a)==1,a
    t=t.replace(a,b)
rep('ARITHMETIC = {"add", "sub", "mul", "div", "floordiv", "mod", "pow"}','ARITHMETIC = {"+", "-", "*", "/", "//", "%", "**"}')
rep("""    for _, kind, value in env.lex(source):
        if kind == "data":""","""    for _, kind, value in env.lex(source):          # tokens crudos: (línea, tipo, valor)
        if kind == "whitespace":
            continue
        if kind == "data":""")
rep("""        elif kind in ARITHMETIC:""","""        elif kind == "operator" and value in ARITHMETIC:""")
rep("""- **`env.lex`** devuelve los mismos *tokens* que Jinja2 usa para compilar: la medición no adivina con expresiones
  regulares (`tx04`).""","""- **`env.lex`** devuelve los mismos *tokens* que Jinja2 usa para compilar: la medición no adivina con expresiones
  regulares (`tx04`). Son los *tokens* **crudos**: los espacios dentro de `{% %}` llegan como `whitespace` y los
  operadores como `operator` con su símbolo. La primera versión de este ejemplo esperaba los nombres ya procesados
  (`add`, `sub`) y declaró "plantilla" a las dos.""")
p.write_text(t)
EOF
cd ../../zz-code/python-for-java-devs-20261005-f516 && python3 humo.py op063-tx09-veredicto.md tx09 'densidad.py=@densidad.py' --pip Jinja2==3.1.6 --cmd 'python densidad.py' 2>&1 | tail -4

# --- 2026-10-05T17:42:09 · Write tx09 output, mark, refresh tx inventory
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs && python3 - <<'EOF'
import pathlib
p=pathlib.Path("op063-tx09-veredicto.md");t=p.read_text()
a="""recordatorio.html  texto= 98  lógica= 0  set=0  aritmética=0  → plantilla
cartera.html       texto=… lógica=…  set=3  aritmética=3  → programa: mover la lógica a Python"""
assert a in t
t=t.replace(a,"""recordatorio.html  texto=102  lógica= 0  set=0  aritmética=0  → plantilla
cartera.html       texto=133  lógica=12  set=3  aritmética=3  → programa: mover la lógica a Python""")
p.write_text(t)
EOF
cd ../../zz-code/python-for-java-devs-20261005-f516 && python3 probado.py op063-tx09-veredicto.md && python3 plan.py 63 63 ✅ ✅ && cd - >/dev/null && python3 prompts/verificar-corpus.py | tail -1; sed -i '' 's/"regex", "Babel", "Unidecode", "ftfy", "htpy", "dominate", "libcst", "PyICU"\],/"regex", "Babel", "Unidecode", "ftfy", "htpy", "dominate", "libcst", "PyICU", "Django",\n           "nh3", "mdit-py-plugins", "mkdocstrings"],/' prompts/check-inventario.py && sed -n '/"tx"/,/\],/p' prompts/check-inventario.py && python3 prompts/check-inventario.py tx | tail -1; grep -n "| \`nh3\`\|mdit-py-plugins\|mkdocstrings\`" prompts/inventario-verificado.md

# --- 2026-10-05T17:42:35 · Compare tested versions against refreshed inventory
for kv in Jinja2:3.1.6 Mako:1.4.3 Chameleon:4.6.0 chevron:0.14.0 Django:6.1.1 Pygments:2.21.0 tree-sitter:0.26.0 tree-sitter-python:0.25.0 markdown-it-py:4.2.0 mistune:3.3.4 Markdown:3.11 pdoc:16.0.0 regex:2026.9.29 Babel:2.18.0 htpy:26.5.1; do k=${kv%%:*}; v=${kv#*:}; grep -q "| \`$k\` | $v |" prompts/inventario-verificado.md || echo "CAMBIÓ $k (probado $v): $(grep "| \`$k\` |" prompts/inventario-verificado.md | head -1)"; done; echo listo

# --- 2026-10-05T17:42:45 · Close T8 in plan with log entry
cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516 && python3 plan.py tanda T8 ✅ && python3 plan.py dondeesta "T1–T8 cerradas (63 de 176). Sigue T9 ui (op064)." && cd ../../cursos-algoritmos-lenguajes/python-for-java-devs && python3 - <<'EOF'
import pathlib
p=pathlib.Path("prompts/plan-de-produccion-carta.md");t=p.read_text()
anchor="## 7. 📓 Bitácora\n\n"
assert anchor in t
entry=("**2026-10-05 · T8 (`tx`) cerrada.** Escritas op055–op063 (9 secciones, 88 ejercicios), **las nueve probadas en "
"contenedor**. **Hallazgos y defectos propios:** `htpy` escapa el apóstrofo como `&#39;` (MarkupSafe), no `&#x27;` (tx01); "
"`trim_blocks` pega `<table>` al párrafo anterior (tx02); en la medición de seis motores Mako empata con Jinja2 y Chameleon "
"es el más rápido —se corrigió la afirmación de que Mako era el más rápido— y los siete renderizan 10 000 correos en 9–55 ms "
"(tx03); `mistune.html` deja pasar `<script>`, se agregó la variante `escape=True` (tx05); el resumen de `doctest -v` cuenta "
"6 pruebas, no 5 (tx06); el compilador reporta primero la comilla sin cerrar de la línea 9 y no el `class` de la línea 8 "
"(tx07); `sorted` ordena `Á` < `Ñ` < `á` por punto de código y Babel escribe `$1.234.567,50` sin espacio (tx08); `env.lex` "
"devuelve *tokens* crudos (`whitespace`, `operator`) y la primera versión del medidor no contaba nada (tx09). tx04 salió "
"exacta a la primera. **Inventario:** `Django`, `nh3`, `mdit-py-plugins` y `mkdocstrings` agregados al track `tx`; "
"ninguna versión probada cambió.\n\n")
t=t.replace(anchor,anchor+entry,1)
p.write_text(t)
EOF
for f in op05[5-9]*.md op06[0-3]*.md; do grep -o "Ejercicios ([0-9]*)" $f; done | grep -o "[0-9]*" | paste -sd+ - | bc; grep -n "T8\*\*" prompts/plan-de-produccion-carta.md | head -2

# --- 2026-10-05T17:42:52 · Update memory; list ui rows and proposal
M=/Users/oskar/.claude/projects/-Users-oskar-Developer-Learning-courses-ia-generated/memory; sed -i '' 's/T1–T7 (lg, au, co, wf, qa, ob, se) cerradas el 05\/10\/2026: 54 de 176; sigue T8 tx\./T1–T8 (lg…tx) cerradas el 05\/10\/2026: 63 de 176; sigue T9 ui./' $M/MEMORY.md && grep -c "63 de 176" $M/MEMORY.md; cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs && grep -n "| op0\(6[4-9]\|7[0-9]\) .*ui" prompts/plan-de-produccion-carta.md; grep -n "## .*Track \`ui\`" prompts/propuestas-temas-opcionales.md

# --- 2026-10-05T17:42:56 · Read ui proposal and fusion notes
sed -n 265,300p prompts/propuestas-temas-opcionales.md; grep -n "ed05\|cl0[1-3]\|fusi" prompts/plan-de-produccion-carta.md | head -12; sed -n '/"ui"/,/\],/p' prompts/check-inventario.py

# --- 2026-10-05T17:43:01 · Read plan header notes and ui versions
sed -n 20,60p prompts/plan-de-produccion-carta.md; grep -n "Track \`cl\`\|^| cl0\|ed05" prompts/propuestas-temas-opcionales.md | head; grep -n "^| \`\(gradio\|streamlit\|dash\|plotly\|nicegui\|reflex\|shiny\|panel\|flet\|marimo\|python-pptx\|WeasyPrint\|XlsxWriter\|great-tables\|PySide6\|typer\|click\|cyclopts\|textual\|rich\|questionary\|prompt-toolkit\|tqdm\|python-fasthtml\|fastapi\|uvicorn\)\`" prompts/inventario-verificado.md | sort -u -t'|' -k2,2

# --- 2026-10-05T17:43:06 · Find how ed05 and cl merge into ui
grep -n "ed05\|\`cl\`\|cl05\|cl06\|ui01" prompts/guia-de-estilo-y-convenciones.md prompts/plan-de-produccion-carta.md | head; sed -n 686,715p prompts/propuestas-temas-opcionales.md; grep -n "Patricia" 00-historia-de-aurea.md | head -5

# --- 2026-10-05T17:43:10 · Read Patricia and staff section of story
sed -n 200,240p 00-historia-de-aurea.md; sed -n 720,730p prompts/guia-de-estilo-y-convenciones.md

# --- 2026-10-05T17:44:19 · Smoke-test ui01 and check URLs
cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516 && python3 humo.py op064-ui01-el-modelo-y-su-costo.md ui01 'entregas.py="""Los dos escalones' --cmd 'python entregas.py' 2>&1 | tail -4; cd ../../cursos-algoritmos-lenguajes/python-for-java-devs && python3 ../../zz-code/python-for-java-devs-20261005-f516/verificar_urls.py op064-ui01-el-modelo-y-su-costo.md | tail -2

# --- 2026-10-05T17:44:24 · Get all three ui01 output lines
cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516 && python3 humo.py op064-ui01-el-modelo-y-su-costo.md ui01 'entregas.py="""Los dos escalones' --cmd 'python entregas.py' 2>/dev/null | grep bytes

# --- 2026-10-05T17:44:30 · Fix byte counts, mark ui01 tested
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs && python3 - <<'EOF'
import pathlib
p=pathlib.Path("op064-ui01-el-modelo-y-su-costo.md");t=p.read_text()
for a,b in [("cartera_ingenuo.csv   146 bytes","cartera_ingenuo.csv   143 bytes"),("cartera_excel.csv     149 bytes","cartera_excel.csv     146 bytes"),("cartera.html          … bytes","cartera.html          567 bytes")]:
    assert t.count(a)==1,a
    t=t.replace(a,b)
p.write_text(t)
EOF
cd ../../zz-code/python-for-java-devs-20261005-f516 && python3 probado.py op064-ui01-el-modelo-y-su-costo.md && python3 plan.py 64 64 ✅ ✅ && cd - >/dev/null && python3 prompts/verificar-corpus.py | tail -1

# --- 2026-10-05T17:45:27 · Smoke-test Gradio app and client in container
cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516 && python3 humo.py op065-ui02-gradio.md ui02 'mora_app.py=@mora_app.py' 'cliente.py=@cliente.py' --pip gradio==6.29.1 --cmd 'GRADIO_ANALYTICS_ENABLED=False python mora_app.py > app.log 2>&1 & for i in $(seq 60); do python -c "import urllib.request;urllib.request.urlopen(\"http://127.0.0.1:7860/\")" 2>/dev/null && break; sleep 1; done; python cliente.py; pip show gradio-client | grep Version' 2>&1 | tail -8; cd ../../cursos-algoritmos-lenguajes/python-for-java-devs && python3 ../../zz-code/python-for-java-devs-20261005-f516/verificar_urls.py op065-ui02-gradio.md | tail -3

# --- 2026-10-05T17:45:55 · Inspect Gradio API endpoint names
cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516 && python3 humo.py op065-ui02-gradio.md ui02 'mora_app.py=@mora_app.py' 'cliente.py=@cliente.py' --pip gradio==6.29.1 --cmd 'GRADIO_ANALYTICS_ENABLED=False python mora_app.py > app.log 2>&1 & for i in $(seq 60); do python -c "import urllib.request;urllib.request.urlopen(\"http://127.0.0.1:7860/\")" 2>/dev/null && break; sleep 1; done; python -c "
from gradio_client import Client
c=Client(\"http://127.0.0.1:7860/\",verbose=False)
print(c.view_api(print_info=False, return_format=\"dict\"))"; pip show gradio-client | grep Version' 2>&1 | tail -4

# --- 2026-10-05T17:46:31 · Fix endpoint name and rerun ui02 test
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs && python3 - <<'EOF'
import pathlib
p=pathlib.Path("op065-ui02-gradio.md");t=p.read_text()
def rep(a,b,n=1):
    global t
    assert t.count(a)==n,(a,t.count(a))
    t=t.replace(a,b)
rep("api_name='/predict'","api_name='/mora'",2)
rep("dict_keys(['/predict'])","dict_keys(['/mora'])")
rep("La aplicación publica un *endpoint* `/predict` que nadie declaró,","La aplicación publica un *endpoint* `/mora` —el nombre de la función— que nadie declaró, con el *docstring* como\ndescripción,")
rep("""- **`precision=0`** hace que `gr.Number` entregue enteros… como `float` igual en algunas versiones; por eso la función
  convierte con `int()` antes de calcular. La plata no viaja en `float` más allá de la frontera.""","""- **`precision=0`** hace que `gr.Number` entregue enteros, y la API los anuncia como `integer`. El `int()` de la función
  sigue ahí porque la API se puede llamar con cualquier cosa: la plata no viaja en `float` más allá de la frontera.""")
rep("""- **`api_name='/predict'`** es el nombre que `Interface` le da a su función. En `Blocks`, cada evento se nombra con
  `api_name=`, y `api_name=False` lo saca de la API.""","""- **`api_name='/mora'`** sale del nombre de la función, y el *docstring* se publica como su documentación: lo que se
  escribe para el desarrollador lo lee cualquiera que abra "Use via API". En `Blocks`, cada evento se nombra con
  `api_name=`, y `api_name=False` lo saca de la API. (Versiones anteriores de Gradio llamaban `/predict` a la función de
  `Interface`; muchos tutoriales todavía lo usan, y fallan con `Cannot find a function with api_name`.)""")
p.write_text(t)
EOF
cd ../../zz-code/python-for-java-devs-20261005-f516 && python3 humo.py op065-ui02-gradio.md ui02 'mora_app.py=@mora_app.py' 'cliente.py=@cliente.py' --pip gradio==6.29.1 --cmd 'GRADIO_ANALYTICS_ENABLED=False python mora_app.py > app.log 2>&1 & for i in $(seq 60); do python -c "import urllib.request;urllib.request.urlopen(\"http://127.0.0.1:7860/\")" 2>/dev/null && break; sleep 1; done; python cliente.py' 2>&1 | tail -4

# --- 2026-10-05T17:47:04 · Apply ui02 fixes in order and rerun
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs && grep -c "/predict" op065-ui02-gradio.md && python3 - <<'EOF'
import pathlib
p=pathlib.Path("op065-ui02-gradio.md");t=p.read_text()
def rep(a,b,n=1):
    global t
    assert t.count(a)==n,(a,t.count(a))
    t=t.replace(a,b)
rep("""- **`api_name='/predict'`** es el nombre que `Interface` le da a su función. En `Blocks`, cada evento se nombra con
  `api_name=`, y `api_name=False` lo saca de la API.""","""- **`api_name='/mora'`** sale del nombre de la función, y el *docstring* se publica como su documentación: lo que se
  escribe para el desarrollador lo lee cualquiera que abra "Use via API". En `Blocks`, cada evento se nombra con
  `api_name=`, y `api_name=False` lo saca de la API. (Versiones anteriores de Gradio llamaban `/predict` a la función de
  `Interface`; muchos tutoriales todavía lo usan, y fallan con `Cannot find a function with api_name`.)""")
rep("api_name='/predict'","api_name='/mora'")
rep("dict_keys(['/predict'])","dict_keys(['/mora'])")
rep("La aplicación publica un *endpoint* `/predict` que nadie declaró,","La aplicación publica un *endpoint* `/mora` —el nombre de la función— que nadie declaró, con el *docstring* como\ndescripción,")
rep("""- **`precision=0`** hace que `gr.Number` entregue enteros… como `float` igual en algunas versiones; por eso la función
  convierte con `int()` antes de calcular. La plata no viaja en `float` más allá de la frontera.""","""- **`precision=0`** hace que `gr.Number` entregue enteros, y la API los anuncia como `integer`. El `int()` de la función
  sigue ahí porque la API se puede llamar con cualquier cosa: la plata no viaja en `float` más allá de la frontera.""")
p.write_text(t)
EOF
cd ../../zz-code/python-for-java-devs-20261005-f516 && python3 humo.py op065-ui02-gradio.md ui02 'mora_app.py=@mora_app.py' 'cliente.py=@cliente.py' --pip gradio==6.29.1 --cmd 'GRADIO_ANALYTICS_ENABLED=False python mora_app.py > app.log 2>&1 & for i in $(seq 60); do python -c "import urllib.request;urllib.request.urlopen(\"http://127.0.0.1:7860/\")" 2>/dev/null && break; sleep 1; done; python cliente.py' 2>&1 | tail -4

# --- 2026-10-05T17:47:32 · Confirm full ui02 output and leftover mentions
python3 humo.py op065-ui02-gradio.md ui02 'mora_app.py=@mora_app.py' 'cliente.py=@cliente.py' --pip gradio==6.29.1 --cmd 'GRADIO_ANALYTICS_ENABLED=False python mora_app.py > app.log 2>&1 & for i in $(seq 60); do python -c "import urllib.request;urllib.request.urlopen(\"http://127.0.0.1:7860/\")" 2>/dev/null && break; sleep 1; done; python cliente.py' 2>/dev/null | tail -3; grep -n "/predict" ../../cursos-algoritmos-lenguajes/python-for-java-devs/op065-ui02-gradio.md

# --- 2026-10-05T17:47:59 · Capture complete client output
python3 humo.py op065-ui02-gradio.md ui02 'mora_app.py=@mora_app.py' 'cliente.py=@cliente.py' --pip gradio==6.29.1 --cmd 'GRADIO_ANALYTICS_ENABLED=False python mora_app.py > app.log 2>&1 & for i in $(seq 60); do python -c "import urllib.request;urllib.request.urlopen(\"http://127.0.0.1:7860/\")" 2>/dev/null && break; sleep 1; done; python cliente.py > out.txt 2>&1; cat out.txt' 2>/dev/null | grep -v "^$" | tail -4

# --- 2026-10-05T17:48:27 · Mark ui02 tested and verify
python3 probado.py op065-ui02-gradio.md && python3 plan.py 65 65 ✅ ✅ && cd ../../cursos-algoritmos-lenguajes/python-for-java-devs && python3 prompts/verificar-corpus.py | tail -1

# --- 2026-10-05T17:49:26 · Smoke-test Streamlit app with AppTest
cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516 && python3 humo.py op066-ui03-streamlit.md ui03 'contador.py=@contador.py' 'cartera_app.py=@cartera_app.py' 'prueba_app.py="""Simula a Patricia' --pip streamlit==1.65.0 --cmd 'python prueba_app.py' 2>&1 | tail -6; cd ../../cursos-algoritmos-lenguajes/python-for-java-devs && python3 ../../zz-code/python-for-java-devs-20261005-f516/verificar_urls.py op066-ui03-streamlit.md | tail -3

# --- 2026-10-05T17:49:32 · Rerun ui03 smoke test with block prefix
cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516 && python3 humo.py op066-ui03-streamlit.md ui03 'contador.py=calls = {' 'cartera_app.py=@cartera_app.py' 'prueba_app.py="""Simula a Patricia' --pip streamlit==1.65.0 --cmd 'python prueba_app.py' 2>&1 | tail -6

# --- 2026-10-05T17:49:59 · Note AppTest warning, mark ui03 tested
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs && python3 - <<'EOF'
import pathlib
p=pathlib.Path("op066-ui03-streamlit.md");t=p.read_text()
a="""  y operarlos. Es lo que va en el CI."""
assert t.count(a)==1
t=t.replace(a,"""  y operarlos. Es lo que va en el CI. Al terminar escribe en la salida de error un aviso de `missing ScriptRunContext`
  que la propia biblioteca dice que se puede ignorar fuera del servidor.""")
p.write_text(t)
EOF
cd ../../zz-code/python-for-java-devs-20261005-f516 && python3 probado.py op066-ui03-streamlit.md && python3 plan.py 66 66 ✅ ✅ && cd - >/dev/null && python3 prompts/verificar-corpus.py | tail -1

# --- 2026-10-05T17:50:54 · Smoke-test Dash callbacks and URLs
cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516 && python3 humo.py op067-ui04-dash.md ui04 'tablero.py=@tablero.py' 'prueba_tablero.py="""El callback es' --pip dash==4.4.1 --cmd 'python prueba_tablero.py' 2>&1 | tail -6; cd ../../cursos-algoritmos-lenguajes/python-for-java-devs && python3 ../../zz-code/python-for-java-devs-20261005-f516/verificar_urls.py op067-ui04-dash.md | tail -3

# --- 2026-10-05T17:51:08 · Mark ui04 tested and verify
cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516 && python3 probado.py op067-ui04-dash.md && python3 plan.py 67 67 ✅ ✅ && cd - >/dev/null && python3 prompts/verificar-corpus.py | tail -1

# --- 2026-10-05T17:52:17 · Serve NiceGUI and Shiny apps and fetch pages
cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516 && python3 humo.py op068-ui05-nicegui-y-compania.md ui05 'app_nicegui.py=@app_nicegui.py' 'app_shiny.py=@app_shiny.py' 'medir.py="""Lo que pesa' --pip nicegui==3.17.1 shiny==1.8.0 --cmd 'python app_nicegui.py > ng.log 2>&1 & shiny run app_shiny.py --port 8082 > sh.log 2>&1 & for i in $(seq 60); do python -c "import urllib.request as u;u.urlopen(\"http://127.0.0.1:8081/\");u.urlopen(\"http://127.0.0.1:8082/\")" 2>/dev/null && break; sleep 1; done; python -c "
import urllib.request as u, re
for p in (8081, 8082):
    h = u.urlopen(f\"http://127.0.0.1:{p}/\").read().decode()
    print(p, len(h), \"Cartera por sede\" in h, \"Facturado\" in h, re.findall(r\"<title>(.*?)</title>\", h))"' 2>&1 | tail -4

# --- 2026-10-05T17:52:23 · Rerun ui05 app serving test with block prefixes
python3 humo.py op068-ui05-nicegui-y-compania.md ui05 'app_nicegui.py="""La pantalla de cartera en NiceGUI' 'app_shiny.py="""La misma pantalla en Shiny' 'medir.py="""Lo que pesa' --pip nicegui==3.17.1 shiny==1.8.0 --cmd 'python app_nicegui.py > ng.log 2>&1 & shiny run app_shiny.py --port 8082 > sh.log 2>&1 & for i in $(seq 60); do python -c "import urllib.request as u;u.urlopen(\"http://127.0.0.1:8081/\");u.urlopen(\"http://127.0.0.1:8082/\")" 2>/dev/null && break; sleep 1; done; python -c "
import urllib.request as u, re
for p in (8081, 8082):
    h = u.urlopen(f\"http://127.0.0.1:{p}/\").read().decode()
    print(p, len(h), \"Cartera por sede\" in h, \"Facturado\" in h, re.findall(r\"<title>(.*?)</title>\", h))"; tail -3 ng.log sh.log' 2>&1 | tail -12

# --- 2026-10-05T17:54:17 · Run framework weight benchmark in container
python3 humo.py op068-ui05-nicegui-y-compania.md ui05 'medir.py="""Lo que pesa' --cmd 'python medir.py' > salidas/ui05/medir.out 2>&1; tail -12 salidas/ui05/medir.out

# --- 2026-10-05T17:54:24 · Add initial-HTML observation to ui05
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs && python3 - <<'EOF'
import pathlib
p=pathlib.Path("op068-ui05-nicegui-y-compania.md");t=p.read_text()
a="""- **En Shiny, la dependencia es implícita**: `facturado` lee `input.sede()`, y Shiny anota que depende de ella. No hay
  `Input(...)` declarado como en Dash (`ui04`); la lectura es la declaración."""
assert t.count(a)==1
t=t.replace(a,a+"""
- **El HTML inicial dice mucho del modelo.** En la prueba de humo, la página de NiceGUI (10 515 bytes) ya trae el texto
  "Facturado: …"; la de Shiny (2 419 bytes) no lo trae: la salida se calcula cuando el navegador abre su *websocket* y la
  sesión empieza. Una página de Shiny sin JavaScript, o detrás de un proxy que corta *websockets*, muestra la lista y nada
  más.""")
p.write_text(t)
EOF
grep -n "is_kernel_connection\|marimo" prompts/inventario-verificado.md | head -3

# --- 2026-10-05T17:55:24 · Smoke-test marimo notebooks and URLs
cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516 && python3 humo.py op069-ui06-marimo.md ui06 'estado_oculto.py="""El estado oculto' 'regalias.py=@regalias.py' 'malo.py=@malo.py' --pip marimo==0.25.1 --cmd 'python estado_oculto.py; echo ---; python regalias.py; echo ---; python malo.py' 2>&1 | tail -25; cd ../../cursos-algoritmos-lenguajes/python-for-java-devs && python3 ../../zz-code/python-for-java-devs-20261005-f516/verificar_urls.py op069-ui06-marimo.md | tail -3

# --- 2026-10-05T17:55:35 · Label marimo blocks and rerun test
python3 - <<'EOF'
import pathlib
p=pathlib.Path("op069-ui06-marimo.md");t=p.read_text()
def rep(a,b):
    global t
    assert t.count(a)==1,a
    t=t.replace(a,b)
rep("""Ahora el notebook de marimo, `regalias.py`. Se edita con `marimo edit regalias.py`, que guarda exactamente esto:
""","""Ahora el notebook de marimo. Se edita con `marimo edit regalias.py`, que guarda exactamente esto:

`regalias.py`:
""")
rep("""Y la regla que lo garantiza, en `malo.py`: dos celdas que definen la misma variable.
""","""Y la regla que lo garantiza: dos celdas que definen la misma variable.

`malo.py`:
""")
p.write_text(t)
EOF
cd ../../zz-code/python-for-java-devs-20261005-f516 && python3 humo.py op069-ui06-marimo.md ui06 'estado_oculto.py="""El estado oculto' 'regalias.py=@regalias.py' 'malo.py=@malo.py' --pip marimo==0.25.1 --cmd 'python estado_oculto.py; echo ---; python regalias.py; echo ---; python malo.py' 2>&1 | tail -25

# --- 2026-10-05T17:55:57 · Paste real marimo error, mark ui06, check benchmark
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs && python3 - <<'EOF'
import pathlib
p=pathlib.Path("op069-ui06-marimo.md");t=p.read_text()
def rep(a,b):
    global t
    assert t.count(a)==1,a
    t=t.replace(a,b)
rep("""Salida esperada, sin correr:

```text
… MultipleDefinitionError … 'tasa' …
```

En Jupyter, dos celdas que definen `tasa` son normales, y el valor que vale depende de cuál corrió último. En marimo es un
error antes de ejecutar nada.""","""Salida esperada, sin correr (sin el *traceback* intermedio):

```text
critical[multiple-definitions]: Variable 'tasa' is defined in multiple cells
 --> /w/malo.py:7:1
   7 | def _():
   8 |     tasa = 0.05
     |     ^
   9 |     return (tasa,)
   ...
  13 | def _():
  14 |     tasa = 0.045
     |     ^
  15 |     return (tasa,)
hint: Variables must be unique across cells. Alternatively, they can be private with an underscore prefix (i.e. `_tasa`.)
…
marimo._ast.errors.MultipleDefinitionError: This app can't be run because it has multiple definitions of the name tasa
```

En Jupyter, dos celdas que definen `tasa` son normales, y el valor que vale depende de cuál corrió último. En marimo es un
error antes de ejecutar nada, con las dos celdas señaladas. La pista del final es la otra regla del modelo: una variable que
empieza con `_` es privada de su celda y no entra al grafo, que es la forma de usar nombres temporales (`_i`, `_df`) sin
choques.""")
p.write_text(t)
EOF
cd ../../zz-code/python-for-java-devs-20261005-f516 && python3 probado.py op069-ui06-marimo.md && python3 plan.py 69 69 ✅ ✅ && cd - >/dev/null && python3 prompts/verificar-corpus.py | tail -1; tail -12 /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516/salidas/ui05/medir.out

# --- 2026-10-05T17:56:50 · Smoke-test python-pptx deck and URLs
cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516 && python3 humo.py op070-ui07-presentaciones.md ui07 'comite.py=@comite.py' --pip python-pptx==1.0.2 --cmd 'python comite.py' 2>&1 | tail -6; cd ../../cursos-algoritmos-lenguajes/python-for-java-devs && python3 ../../zz-code/python-for-java-devs-20261005-f516/verificar_urls.py op070-ui07-presentaciones.md | tail -3

# --- 2026-10-05T17:57:00 · Mark ui07 and view benchmark progress
cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516 && python3 probado.py op070-ui07-presentaciones.md && python3 plan.py 70 70 ✅ ✅ && cat salidas/ui05/medir.out | tail -12

# --- 2026-10-05T17:57:08 · Look up openpyxl and related versions
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs && grep -n "| \`openpyxl\`\|| \`great-tables\`\|| \`pypdf\`\|| \`polars\`\|| \`pandas\`" prompts/inventario-verificado.md | head

# --- 2026-10-05T17:58:01 · Read framework benchmark results
cat /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516/salidas/ui05/medir.out | grep -v "^$" | tail -12

# --- 2026-10-05T17:58:14 · Fill ui05 benchmark, mark tested, verify
python3 - <<'EOF'
import pathlib,re
p=pathlib.Path("op068-ui05-nicegui-y-compania.md");t=p.read_text()
real="""biblioteca  paquetes     MB  importar (s)
nicegui           49    114          0.31
shiny             32    110          0.22
panel             31    354          0.48
reflex            40     71          0.00
flet              12     23          0.04
streamlit         36    418          0.16
dash              28    136          0.16
gradio            53    326          1.19"""
old=re.search(r"biblioteca  paquetes     MB  importar \(s\)\n(?:[a-z]+ +… +… +…\n)+",t).group(0)
t=t.replace(old,real+"\n")
a="""**Detalles con intención**

- **En NiceGUI, `@ui.page("/")`**"""
assert t.count(a)==1
t=t.replace(a,"""Las bibliotecas del track van de 23 MB a más de 400, y de 12 a 53 paquetes que vigilar. Streamlit y Panel pesan lo que
pesan por arrastrar pandas, NumPy y PyArrow; Gradio, además, tarda más de un segundo en importarse, que se paga en cada
arranque y en cada prueba. Dos cifras engañan y conviene leerlas bien: Reflex "se importa" en 0,00 s porque carga sus
módulos de forma perezosa —el costo se muda al primer uso y a la construcción con Node—, y Flet pesa 23 MB porque el
cliente de Flutter no viene en el paquete: se descarga la primera vez que corre.

**Detalles con intención**

- **En NiceGUI, `@ui.page("/")`**""")
p.write_text(t)
EOF
sed -i '' 's/^Salida esperada, sin correr (los números dependen de la máquina y de la red; la columna de importación es la mejor de tres):/Salida esperada, sin correr (los números dependen de la máquina; la columna de importación es la mejor de tres):/' op068-ui05-nicegui-y-compania.md; cd ../../zz-code/python-for-java-devs-20261005-f516 && python3 probado.py op068-ui05-nicegui-y-compania.md && python3 plan.py 68 68 ✅ ✅ && cd - >/dev/null && grep -n "^Salida" op068-ui05-nicegui-y-compania.md && python3 ../../zz-code/python-for-java-devs-20261005-f516/verificar_urls.py op068-ui05-nicegui-y-compania.md | tail -2 && python3 prompts/verificar-corpus.py | tail -1

# --- 2026-10-05T17:58:23 · Adjust dependency claim and verify it
sed -i '' 's/Streamlit y Panel pesan lo que$/Streamlit y Panel pesan lo que/' op068-ui05-nicegui-y-compania.md && python3 - <<'EOF'
import pathlib
p=pathlib.Path("op068-ui05-nicegui-y-compania.md");t=p.read_text()
a="pesan por arrastrar pandas, NumPy y PyArrow;"
assert t.count(a)==1
t=t.replace(a,"pesan por arrastrar pandas y NumPy (Streamlit, además, PyArrow; Panel, Bokeh);")
p.write_text(t)
EOF
docker run --rm --label curso=python-for-java-devs python:3.14.7 sh -c 'pip install -q --disable-pip-version-check streamlit==1.65.0 panel==1.9.4 2>/dev/null; pip show streamlit panel | grep -i "^requires"'

# --- 2026-10-05T17:58:52 · Smoke-test ui08 with and without Pango
cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516 && python3 humo.py op071-ui08-reportes.md ui08 'reporte_mensual.py=@reporte_mensual.py' --pip WeasyPrint==70.0 XlsxWriter==3.2.9 Jinja2==3.1.6 openpyxl==3.1.5 --cmd 'python reporte_mensual.py 2>&1 | tail -3; echo ---; apt-get update -qq >/dev/null && apt-get install -y -qq libpango-1.0-0 libpangoft2-1.0-0 >/dev/null 2>&1; python reporte_mensual.py' 2>&1 | tail -8; cd ../../cursos-algoritmos-lenguajes/python-for-java-devs && python3 ../../zz-code/python-for-java-devs-20261005-f516/verificar_urls.py op071-ui08-reportes.md | tail -3

# --- 2026-10-05T17:59:12 · Fix Jinja filter registration, rerun ui08
python3 - <<'EOF'
import pathlib
p=pathlib.Path("op071-ui08-reportes.md");t=p.read_text()
def rep(a,b):
    global t
    assert t.count(a)==1,a
    t=t.replace(a,b)
rep("from jinja2 import Template\n","from jinja2 import Environment\n")
rep('PAGE = Template("""<!doctype html>','env = Environment(autoescape=True)\nenv.filters["pesos"] = lambda v: "$" + f"{v:,}".replace(",", ".")\nPAGE = env.from_string("""<!doctype html>')
rep('PAGE.environment.filters["pesos"] = lambda v: "$" + f"{v:,}".replace(",", ".")\n',"")
p.write_text(t)
EOF
cd ../../zz-code/python-for-java-devs-20261005-f516 && python3 humo.py op071-ui08-reportes.md ui08 'reporte_mensual.py=@reporte_mensual.py' --pip WeasyPrint==70.0 XlsxWriter==3.2.9 Jinja2==3.1.6 openpyxl==3.1.5 --cmd 'python reporte_mensual.py 2>&1 | tail -2; echo ---; apt-get update -qq >/dev/null && apt-get install -y -qq libpango-1.0-0 libpangoft2-1.0-0 >/dev/null 2>&1; python reporte_mensual.py' 2>&1 | tail -8

# --- 2026-10-05T17:59:27 · Test WeasyPrint import in slim image
docker image inspect python:3.14.7-slim >/dev/null 2>&1 && echo "ya existía" || echo "no existía"; docker run --rm --label curso=python-for-java-devs python:3.14.7-slim sh -c 'pip install -q --disable-pip-version-check WeasyPrint==70.0 2>/dev/null; python -c "import weasyprint" 2>&1 | tail -2'

# --- 2026-10-05T17:59:39 · Capture WeasyPrint import error in slim image
docker run --rm --label curso=python-for-java-devs python:3.14.7-slim sh -c 'pip install -q --disable-pip-version-check WeasyPrint==70.0 >/dev/null 2>&1; python -c "import weasyprint" > /tmp/e 2>&1; echo exit=$?; grep -i "error\|cannot\|library" /tmp/e | tail -3'

# --- 2026-10-05T17:59:49 · Verify Pango packages fix slim, then remove image
docker run --rm --label curso=python-for-java-devs python:3.14.7-slim sh -c 'apt-get update -qq >/dev/null && apt-get install -y -qq libpango-1.0-0 libpangoft2-1.0-0 >/dev/null 2>&1; pip install -q --disable-pip-version-check WeasyPrint==70.0 >/dev/null 2>&1; python -c "from weasyprint import HTML; print(len(HTML(string=\"<p>hola</p>\").render().pages), \"página\")"'; docker rmi python:3.14.7-slim >/dev/null && echo "imagen slim borrada"

# --- 2026-10-05T18:00:11 · Correct WeasyPrint error text, mark ui08
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs && python3 - <<'EOF'
import pathlib
p=pathlib.Path("op071-ui08-reportes.md");t=p.read_text()
def rep(a,b):
    global t
    assert t.count(a)==1,a
    t=t.replace(a,b)
rep("""WeasyPrint necesita Pango del sistema operativo. En Debian o Ubuntu:""","""WeasyPrint necesita Pango del sistema operativo. La imagen completa de Python (`python:3.14.7`) ya lo trae; en una
mínima (`-slim`), en Debian o Ubuntu:""")
rep("""**WeasyPrint sin Pango.** Es una biblioteca de Python con dependencias del sistema operativo. En un contenedor mínimo, el
`import` falla con un error de `cannot load library 'libpango…'`.""","""**WeasyPrint sin Pango.** Es una biblioteca de Python con dependencias del sistema operativo. En `python:3.14.7-slim`, el
`import` falla con `OSError: cannot load library 'libgobject-2.0-0'` —una biblioteca de GLib, que el mensaje no relaciona
con Pango—, y los dos paquetes de arriba lo resuelven, comprobado en esa imagen.""")
p.write_text(t)
EOF
cd ../../zz-code/python-for-java-devs-20261005-f516 && python3 probado.py op071-ui08-reportes.md && python3 plan.py 71 71 ✅ ✅ && cd - >/dev/null && python3 prompts/verificar-corpus.py | tail -1

# --- 2026-10-05T18:01:09 · Smoke-test Tkinter app under Xvfb
cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516 && python3 humo.py op072-ui09-escritorio.md ui09 'mora_tk.py=@mora_tk.py' --cmd 'apt-get update -qq >/dev/null && apt-get install -y -qq xvfb xauth >/dev/null 2>&1; xvfb-run -a python mora_tk.py' 2>&1 | tail -5; cd ../../cursos-algoritmos-lenguajes/python-for-java-devs && python3 ../../zz-code/python-for-java-devs-20261005-f516/verificar_urls.py op072-ui09-escritorio.md | tail -3

# --- 2026-10-05T18:01:29 · Fill Tk version, mark ui09 tested
sed -i '' 's/^Tk 8\.6\.…$/Tk 8.6.16/' op072-ui09-escritorio.md && sed -i '' 's/^python3 mora_tk.py$/python3 mora_tk.py          # en un servidor sin pantalla: xvfb-run -a python3 mora_tk.py/' op072-ui09-escritorio.md && grep -n "Tk 8.6.16\|xvfb-run -a python3" op072-ui09-escritorio.md && cd ../../zz-code/python-for-java-devs-20261005-f516 && python3 probado.py op072-ui09-escritorio.md && python3 plan.py 72 72 ✅ ✅ && cd - >/dev/null && python3 prompts/verificar-corpus.py | tail -1

# --- 2026-10-05T18:02:30 · Smoke-test three CLIs comparison
cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516 && python3 humo.py op073-ui10-cli-mas-alla-de-argparse.md ui10 'cli_argparse.py=@cli_argparse.py' 'cli_typer.py=@cli_typer.py' 'cli_cyclopts.py=@cli_cyclopts.py' 'comparar.py="""Arranque, salida' --pip typer==0.27.2 cyclopts==5.1.1 --cmd 'python comparar.py; echo ---; python cli_cyclopts.py 1.250.000 45; echo "exit=$?"' 2>&1 | tail -16; cd ../../cursos-algoritmos-lenguajes/python-for-java-devs && python3 ../../zz-code/python-for-java-devs-20261005-f516/verificar_urls.py op073-ui10-cli-mas-alla-de-argparse.md | tail -3

# --- 2026-10-05T18:02:49 · Fill CLI measurements, mark ui10
python3 - <<'EOF'
import pathlib,re
p=pathlib.Path("op073-ui10-cli-mas-alla-de-argparse.md");t=p.read_text()
def rep(a,b):
    global t
    assert t.count(a)==1,a
    t=t.replace(a,b)
old=re.search(r"cli_argparse\.py   arranque … ms.*?\ncli_typer\.py .*?\ncli_cyclopts\.py .*?bytes",t,re.S).group(0)
t=t.replace(old,"""cli_argparse.py   arranque   29 ms · json → 28125 · con puntos: salida 2, stdout 0 bytes, stderr 97 bytes
cli_typer.py      arranque  102 ms · json → 28125 · con puntos: salida 2, stdout 0 bytes, stderr 684 bytes
cli_cyclopts.py   arranque  114 ms · json → 28125 · con puntos: salida 2, stdout 0 bytes, stderr 603 bytes""")
rep("Salida esperada, sin correr (los milisegundos son de la máquina que corre):","Salida esperada, sin correr (los milisegundos son de la máquina que corre; estos, de un contenedor en un portátil):")
rep("""**Detalles con intención**

- **`--json`** es la línea""","""Las tres hacen lo mismo y las tres se portan bien con la entrada inválida: código 2, nada en `stdout`, el mensaje en
`stderr`. Lo que las separa es el arranque: `argparse` arranca en 29 ms y las otras dos en más de 100, unas 3,5 veces más,
porque importan `rich` para dibujar la ayuda y los errores en recuadros (de ahí los 600 bytes de `stderr` contra 97). Para
un comando que el ingeniero escribe a mano, 70 ms no se notan; para uno que un script llama diez mil veces en un
reproceso, son doce minutos.

**Detalles con intención**

- **`--json`** es la línea""")
rep("| `cyclopts` 5.1.1 | Las anotaciones de tipo, sin Click debajo | Pocas |","| `cyclopts` 5.1.1 | Las anotaciones de tipo, sin Click debajo | `rich` y pocas más |")
p.write_text(t)
EOF
cd ../../zz-code/python-for-java-devs-20261005-f516 && python3 probado.py op073-ui10-cli-mas-alla-de-argparse.md && python3 plan.py 73 73 ✅ ✅ && cd - >/dev/null && python3 prompts/verificar-corpus.py | tail -1

# --- 2026-10-05T18:03:51 · Smoke-test rich output for cron vs person
cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516 && python3 humo.py op074-ui11-rich-e-interaccion.md ui11 'reproceso.py=@reproceso.py' 'comparar_salidas.py="""La misma herramienta' --pip rich==15.0.0 --cmd 'python comparar_salidas.py' 2>&1 | tail -18; cd ../../cursos-algoritmos-lenguajes/python-for-java-devs && python3 ../../zz-code/python-for-java-devs-20261005-f516/verificar_urls.py op074-ui11-rich-e-interaccion.md | tail -3

# --- 2026-10-05T18:04:08 · Paste exact rich output into ui11
S=/private/tmp/claude-501/-Users-oskar-Developer-Learning-courses-ia-generated/5c52573d-4a56-4998-bca3-5d686d0c5368/scratchpad; cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516 && python3 humo.py op074-ui11-rich-e-interaccion.md ui11 'reproceso.py=@reproceso.py' 'comparar_salidas.py="""La misma herramienta' --pip rich==15.0.0 --cmd 'python comparar_salidas.py' 2>/dev/null | sed -n '/^cron (sin terminal)/,/^persona/p' > $S/ui11.txt; cat -e $S/ui11.txt | head -3; cd ../../cursos-algoritmos-lenguajes/python-for-java-devs && python3 - "$S/ui11.txt" <<'EOF'
import pathlib,re,sys
real=pathlib.Path(sys.argv[1]).read_text().rstrip("\n")
p=pathlib.Path("op074-ui11-rich-e-interaccion.md");t=p.read_text()
old=re.search(r"cron \(sin terminal\)      … bytes.*?persona \(FORCE_COLOR\)[^\n]*",t,re.S).group(0)
t=t.replace(old,real)
a="Sin terminal, cero códigos de escape:"
assert t.count(a)==1
t=t.replace(a,"Sin terminal, 477 bytes y cero códigos de escape; para una persona, 1 438 bytes y 101 escapes:")
p.write_text(t)
EOF
sed -n '/^```text$/,/^```$/p' op074-ui11-rich-e-interaccion.md | head -18

# --- 2026-10-05T18:04:18 · Explain missing echo, mark ui11
python3 - <<'EOF'
import pathlib
p=pathlib.Path("op074-ui11-rich-e-interaccion.md");t=p.read_text()
a="La pregunta rechazó `Bogotá` —que no es una sede de la lista— y aceptó `Suba`."
assert t.count(a)==1
t=t.replace(a,"La pregunta rechazó `Bogotá` —que no es una sede de la lista— y aceptó `Suba`; las respuestas no aparecen después de\nlos dos puntos porque llegaron por una tubería, y una tubería no tiene eco.")
p.write_text(t)
EOF
cd ../../zz-code/python-for-java-devs-20261005-f516 && python3 probado.py op074-ui11-rich-e-interaccion.md && python3 plan.py 74 74 ✅ ✅ && cd - >/dev/null && python3 prompts/verificar-corpus.py | tail -1

# --- 2026-10-05T18:05:10 · Fix column keys and smoke-test Textual app
python3 - <<'EOF'
import pathlib
p=pathlib.Path("op075-ui12-textual.md");t=p.read_text()
def rep(a,b):
    global t
    assert t.count(a)==1,a
    t=t.replace(a,b)
rep('        table.add_columns("Sede", "Estado", "Segundos")\n','        for label in ("Sede", "Estado", "Segundos"):\n            table.add_column(label, key=label.lower())\n')
rep('table.update_cell(row_key, "Estado", "reprocesada")','table.update_cell(row_key, "estado", "reprocesada")')
rep("Para que `update_cell` encuentre la columna por nombre, las columnas se agregan con clave. La prueba,","Las columnas se agregan con clave (`key=`) para que `update_cell` encuentre la del estado por nombre. La prueba,")
p.write_text(t)
EOF
cd ../../zz-code/python-for-java-devs-20261005-f516 && python3 humo.py op075-ui12-textual.md ui12 'cierre_tui.py=@cierre_tui.py' 'prueba_tui.py="""Opera la TUI' --pip textual==8.2.8 --cmd 'python prueba_tui.py' 2>&1 | tail -6; cd ../../cursos-algoritmos-lenguajes/python-for-java-devs && python3 ../../zz-code/python-for-java-devs-20261005-f516/verificar_urls.py op075-ui12-textual.md | tail -3

# --- 2026-10-05T18:05:20 · Mark ui12 tested and verify
cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516 && python3 probado.py op075-ui12-textual.md && python3 plan.py 75 75 ✅ ✅ && cd - >/dev/null && python3 prompts/verificar-corpus.py | tail -1

# --- 2026-10-05T18:06:06 · Smoke-test ui13 decision function
cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516 && python3 humo.py op076-ui13-veredicto.md ui13 'escalon.py="""¿Qué escalón?' --cmd 'python escalon.py' 2>&1 | tail -9; cd ../../cursos-algoritmos-lenguajes/python-for-java-devs && python3 ../../zz-code/python-for-java-devs-20261005-f516/verificar_urls.py op076-ui13-veredicto.md | tail -2

# --- 2026-10-05T18:06:16 · Mark ui13, refresh ui inventory, compare versions
cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516 && python3 probado.py op076-ui13-veredicto.md && python3 plan.py 76 76 ✅ ✅ && cd ../../cursos-algoritmos-lenguajes/python-for-java-devs && sed -i '' 's/           "justpy"\],/           "justpy", "openpyxl", "pyinstaller", "briefcase", "pytest-textual-snapshot"],/' prompts/check-inventario.py && python3 prompts/check-inventario.py ui | tail -1 && for kv in gradio:6.29.1 streamlit:1.65.0 dash:4.4.1 nicegui:3.17.1 shiny:1.8.0 panel:1.9.4 reflex:0.9.12 flet:1.0.3 marimo:0.25.1 python-pptx:1.0.2 WeasyPrint:70.0 XlsxWriter:3.2.9 openpyxl:3.1.5 typer:0.27.2 cyclopts:5.1.1 rich:15.0.0 textual:8.2.8 PySide6:6.11.2 click:8.5.0 questionary:2.1.1 prompt-toolkit:3.0.53; do k=${kv%%:*}; v=${kv#*:}; grep -q "| \`$k\` | $v |" prompts/inventario-verificado.md || echo "CAMBIÓ $k (probado $v): $(grep "| \`$k\` |" prompts/inventario-verificado.md | head -1)"; done; echo revisado; python3 prompts/verificar-corpus.py | tail -1

# --- 2026-10-05T18:07:00 · Close T9 in plan, log entry, update memory
cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516 && python3 plan.py tanda T9 ✅ && python3 plan.py dondeesta "T1–T9 cerradas (76 de 176). Sigue T10 db (op077)." && cd ../../cursos-algoritmos-lenguajes/python-for-java-devs && n=$(for f in op06[4-9]*.md op07[0-6]*.md; do grep -o "Ejercicios ([0-9]*)" $f; done | grep -o "[0-9]*" | paste -sd+ - | bc) && echo "ejercicios=$n" && python3 - "$n" <<'EOF'
import pathlib,sys
p=pathlib.Path("prompts/plan-de-produccion-carta.md");t=p.read_text()
anchor="## 7. 📓 Bitácora\n\n"
entry=(f"**2026-10-05 · T9 (`ui`) cerrada.** Escritas op064–op076 (13 secciones, {sys.argv[1]} ejercicios), **las trece probadas "
"en contenedor**; ui01 absorbe `ed05` (Patricia) y ui10–ui12 son el antiguo `cl`. **Hallazgos y defectos propios:** el "
"*endpoint* de Gradio 6 se llama como la función (`/mora`), no `/predict`, y publica el *docstring* (ui02); `AppTest` de "
"Streamlit confirmó 5 cargas sin caché contra 1 con caché (ui03); la medición de ocho bibliotecas da de 23 MB (Flet) a "
"418 MB (Streamlit) e importaciones de 0,04 s a 1,19 s (Gradio), con Reflex en 0,00 s por carga perezosa (ui05); el HTML "
"inicial de Shiny no trae las salidas (ui05); el error de marimo por definición múltiple sugiere `_tasa` (ui06); `Template()` "
"compila al crearse y el filtro tiene que estar antes en el `Environment` (ui08, defecto propio); WeasyPrint en "
"`python:3.14.7-slim` falla con `libgobject-2.0-0`, no con Pango, y la imagen completa ya lo trae (ui08; la imagen slim se "
"bajó y se borró); argparse arranca en 29 ms contra 102–114 ms de Typer y `cyclopts` (ui10); `rich` escribe 0 escapes sin "
"terminal y 101 con `FORCE_COLOR` (ui11); en Textual, `update_cell` necesita columnas con `key=` (ui12, defecto propio "
"atrapado antes de correr). **Inventario:** `openpyxl`, `pyinstaller`, `briefcase` y `pytest-textual-snapshot` agregados "
"al track `ui`; ninguna versión probada cambió.\n\n")
t=t.replace(anchor,anchor+entry,1)
p.write_text(t)
EOF
M=/Users/oskar/.claude/projects/-Users-oskar-Developer-Learning-courses-ia-generated/memory; sed -i '' 's/T1–T8 (lg…tx) cerradas el 05\/10\/2026: 63 de 176; sigue T9 ui\./T1–T9 (lg…ui) cerradas el 05\/10\/2026: 76 de 176; sigue T10 db./' $M/MEMORY.md && grep -c "76 de 176" $M/MEMORY.md

# --- 2026-10-05T18:07:05 · Read db track rows and proposal
grep -n "| op0[7-9][0-9] .*db" prompts/plan-de-produccion-carta.md; n=$(grep -n "Track \`db\`" prompts/propuestas-temas-opcionales.md | head -1 | cut -d: -f1); sed -n "${n},$((n+40))p" prompts/propuestas-temas-opcionales.md; sed -n '/"db"/,/\],/p' prompts/check-inventario.py

# --- 2026-10-05T18:07:19 · Check architecture and zz-code helpers
uname -m; docker info --format '{{.Architecture}} {{.MemTotal}} {{.NCPU}}'; cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516 && ls; sed -n '/## 9/,$p' ../../cursos-algoritmos-lenguajes/python-for-java-devs/prompts/plan-de-produccion-carta.md | head -30

# --- 2026-10-05T18:07:22 · Read manifest and humo.py remainder
cat MANIFIESTO.md | head -30; ls salidas | tr '\n' ' '; ls salidas/qa0* | head -20; sed -n 40,80p humo.py

# --- 2026-10-05T18:07:27 · Check qa testing approach and Docker inventory
cd /Users/oskar/Developer/Learning/courses-ia-generated && grep -o "T5 (\`qa\`) cerrada.\{0,900\}" cursos-algoritmos-lenguajes/python-for-java-devs/prompts/plan-de-produccion-carta.md | head -1; cat zz-code/python-for-java-devs-20261005-f516/salidas/docker-inventario-inicial.log | head -30; docker images --format '{{.Repository}}:{{.Tag}} {{.Size}}' | head -30

# --- 2026-10-05T18:07:35 · List remaining Docker images and networks
docker images --format '{{.Repository}}:{{.Tag}} {{.Size}}' | sed -n 31,80p; docker network ls --format '{{.Name}}' | head -20

# --- 2026-10-05T18:08:10 · Record pulled images; list db versions
printf "# Imágenes que la carta bajó y que hay que borrar al terminar (las demás son de otros cursos: no se tocan)\ndebian:trixie-slim\n" > zz-code/python-for-java-devs-20261005-f516/salidas/imagenes-bajadas.txt; grep -n "| \`psycopg\`\|| \`psycopg-binary\`\|| \`mysqlclient\`\|| \`PyMySQL\`\|| \`asyncmy\`\|| \`duckdb\`\|| \`redis\`\|| \`valkey\`\|| \`pymongo\`\|| \`beanie\`\|| \`cassandra-driver\`\|| \`scylla-driver\`\|| \`neo4j\`\|| \`py2neo\`\|| \`influxdb\|| \`pgvector\`\|| \`qdrant-client\`\|| \`opensearch-py\`\|| \`meilisearch\`\|| \`typesense\`\|| \`boto3\`\|| \`fsspec\`\|| \`s3fs\`\|| \`confluent-kafka\`\|| \`nats-py\`\|| \`minio\`\|| \`pyodbc\`\|| \`pymssql\`\|| \`oracledb\`" cursos-algoritmos-lenguajes/python-for-java-devs/prompts/inventario-verificado.md | sort -u -t'|' -k2,2

# --- 2026-10-05T18:09:13 · Smoke-test db01 against Postgres service
cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516 && python3 humo_servicio.py op077-db01-el-db-api.md db01 'dbapi.py=@dbapi.py' --svc pg=postgres:18.6 --env pg:POSTGRES_PASSWORD=aurea-local --pip "psycopg[binary]==3.3.6" --cmd 'python dbapi.py' 2>&1 | tail -8; docker ps -a --filter label=curso=python-for-java-devs --format '{{.Names}}'; docker network ls --filter label=curso=python-for-java-devs --format '{{.Name}}'

# --- 2026-10-05T18:09:22 · Mark db01, check URLs and corpus
python3 probado.py op077-db01-el-db-api.md && python3 plan.py 77 77 ✅ ✅ && cd ../../cursos-algoritmos-lenguajes/python-for-java-devs && python3 ../../zz-code/python-for-java-devs-20261005-f516/verificar_urls.py op077-db01-el-db-api.md | tail -2 && python3 prompts/verificar-corpus.py | tail -1

# --- 2026-10-05T18:10:22 · Smoke-test MySQL and MariaDB traps
cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516 && python3 humo_servicio.py op078-db02-mysql-y-mariadb.md db02 'trampas.py=@trampas.py' --svc mysql=mysql:9.7.2 --env mysql:MYSQL_ROOT_PASSWORD=aurea-local --svc maria=mariadb:12.3.3 --env maria:MARIADB_ROOT_PASSWORD=aurea-local --pip PyMySQL==1.2.3 --cmd 'python trampas.py' 2>&1 | tail -16; docker ps -a --filter label=curso=python-for-java-devs --format '{{.Names}}'

# --- 2026-10-05T18:10:27 · Rerun db02 with content prefix
python3 humo_servicio.py op078-db02-mysql-y-mariadb.md db02 'trampas.py="""Las tres trampas' --svc mysql=mysql:9.7.2 --env mysql:MYSQL_ROOT_PASSWORD=aurea-local --svc maria=mariadb:12.3.3 --env maria:MARIADB_ROOT_PASSWORD=aurea-local --pip PyMySQL==1.2.3 --cmd 'python trampas.py' 2>&1 | tail -16; docker ps -a --filter label=curso=python-for-java-devs --format '{{.Names}}'

# --- 2026-10-05T18:10:42 · Fill MariaDB line, mark db02, verify
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs && sed -i '' 's/^--- MariaDB 12.3.3-MariaDB-… · colación …$/--- MariaDB 12.3.3-MariaDB-ubu2404 · colación utf8mb4_uca1400_ai_ci/' op078-db02-mysql-y-mariadb.md && grep -c "uca1400_ai_ci" op078-db02-mysql-y-mariadb.md && cd ../../zz-code/python-for-java-devs-20261005-f516 && python3 probado.py op078-db02-mysql-y-mariadb.md && python3 plan.py 78 78 ✅ ✅ && cd - >/dev/null && python3 ../../zz-code/python-for-java-devs-20261005-f516/verificar_urls.py op078-db02-mysql-y-mariadb.md | tail -3 && python3 prompts/verificar-corpus.py | tail -1

# --- 2026-10-05T18:10:49 · Probe MySQL and MariaDB doc URLs
for u in https://dev.mysql.com/doc/refman/9.4/en/charset-unicode-sets.html https://dev.mysql.com/doc/refman/8.4/en/charset-unicode-sets.html https://mariadb.com/docs/server/reference/data-types/string-data-types/character-sets/unicode https://mariadb.com/kb/en/unicode/ https://mariadb.com/kb/en/sql-mode/ https://en.wikipedia.org/wiki/UTF-8; do echo "$(curl -s -o /dev/null -w '%{http_code}' -L -m 20 "$u") $u"; done

# --- 2026-10-05T18:11:07 · Check disk and Docker space usage
df -h / | tail -1; docker system df --format '{{.Type}} {{.Size}} {{.Reclaimable}}'

# --- 2026-10-05T18:11:12 · Pull Oracle Free and SQL Server images
echo "gvenzl/oracle-free:23-slim" >> /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516/salidas/imagenes-bajadas.txt; echo "mcr.microsoft.com/mssql/server:2022-latest" >> /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516/salidas/imagenes-bajadas.txt; (docker pull -q gvenzl/oracle-free:23-slim; docker pull -q --platform linux/amd64 mcr.microsoft.com/mssql/server:2022-latest) 2>&1 | tail -4

# --- 2026-10-05T18:12:18 · Fix fetch line; check image pulls
python3 - <<'EOF'
import pathlib
p=pathlib.Path("op079-db03-sql-server-y-oracle.md");t=p.read_text()
a='    print("  VARCHAR / NVARCHAR:", cur.execute("SELECT v, nv FROM #nota") or cur.fetchone())\n'
assert t.count(a)==1
t=t.replace(a,'    cur.execute("SELECT v, nv FROM #nota")\n    print("  VARCHAR / NVARCHAR:", cur.fetchone())\n')
p.write_text(t)
EOF
cat /private/tmp/claude-501/-Users-oskar-Developer-Learning-courses-ia-generated/5c52573d-4a56-4998-bca3-5d686d0c5368/tasks/buskgajtd.output; docker images --format '{{.Repository}}:{{.Tag}} {{.Size}}' | grep -i "oracle\|mssql"

# --- 2026-10-05T18:13:14 · Smoke-test SQLite traps and URLs
cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516 && python3 humo.py op080-db04-sqlite-a-fondo.md db04 'sqlite_trampas.py="""Las tres trampas de SQLite' --cmd 'rm -f agenda.db*; python sqlite_trampas.py' 2>&1 | tail -8; cd ../../cursos-algoritmos-lenguajes/python-for-java-devs && python3 ../../zz-code/python-for-java-devs-20261005-f516/verificar_urls.py op080-db04-sqlite-a-fondo.md | tail -2

# --- 2026-10-05T18:13:24 · Add DDL commit and rerun db04
python3 - <<'EOF'
import pathlib
p=pathlib.Path("op080-db04-sqlite-a-fondo.md");t=p.read_text()
def rep(a,b):
    global t
    assert t.count(a)==1,a
    t=t.replace(a,b)
rep('''db.execute("CREATE TABLE cita (sede TEXT REFERENCES sede(codigo))")
''','''db.execute("CREATE TABLE cita (sede TEXT REFERENCES sede(codigo))")
db.commit()                                                            # el DDL también es transaccional
''')
rep("""- **`PRAGMA foreign_keys` es por conexión**""","""- **El `commit()` después de los `CREATE TABLE`** no es decorativo: en SQLite, como en Postgres, el DDL es transaccional, y el
  `rollback()` de la fila huérfana se habría llevado también las tablas. La primera versión de este ejemplo no lo tenía y
  falló con `no such table: cita`. (En MySQL y Oracle, en cambio, el DDL confirma solo.)
- **`PRAGMA foreign_keys` es por conexión**""")
p.write_text(t)
EOF
cd ../../zz-code/python-for-java-devs-20261005-f516 && python3 humo.py op080-db04-sqlite-a-fondo.md db04 'sqlite_trampas.py="""Las tres trampas de SQLite' --cmd 'rm -f agenda.db*; python sqlite_trampas.py' 2>&1 | tail -8

# --- 2026-10-05T18:13:31 · Set measured wait, mark db04; confirm images
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs && sed -i '' 's/^segundo escritor: database is locked tras 0.5 s$/segundo escritor: database is locked tras 0.6 s/' op080-db04-sqlite-a-fondo.md && grep -c "tras 0.6 s" op080-db04-sqlite-a-fondo.md && cd ../../zz-code/python-for-java-devs-20261005-f516 && python3 probado.py op080-db04-sqlite-a-fondo.md && python3 plan.py 80 80 ✅ ✅; docker images --format '{{.Repository}}:{{.Tag}} {{.Size}} {{.ID}}' | grep -i "mssql\|oracle"

# --- 2026-10-05T18:13:38 · Smoke-test SQL Server and Oracle example
python3 humo_servicio.py op079-db03-sql-server-y-oracle.md db03 'aliados.py=@aliados.py' --svc mssql=mcr.microsoft.com/mssql/server:2022-latest --env mssql:ACCEPT_EULA=Y --env 'mssql:MSSQL_SA_PASSWORD=Aurea-Local-2026!' --svc oracle=gvenzl/oracle-free:23-slim --env oracle:ORACLE_PASSWORD=aurea-local --pip pyodbc==5.3.0 pymssql==2.4.2 oracledb==26.0.1 --cmd 'python aliados.py' 2>&1 | tail -14; docker ps -a --filter label=curso=python-for-java-devs --format '{{.Names}}'

# --- 2026-10-05T18:14:02 · Use fresh cursor for fetch_decimals and rerun
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs && python3 - <<'EOF'
import pathlib
p=pathlib.Path("op079-db03-sql-server-y-oracle.md");t=p.read_text()
def rep(a,b):
    global t
    assert t.count(a)==1,a
    t=t.replace(a,b)
rep('''    oracledb.defaults.fetch_decimals = True
    cur.execute("SELECT valor FROM abono")
    print("  con fetch_decimals:", repr(cur.fetchone()[0]))
    cur.execute("DROP TABLE abono")''','''    oracledb.defaults.fetch_decimals = True               # vale para los cursores que se creen después
    with conn.cursor() as cur2:
        cur2.execute("SELECT valor FROM abono")
        print("  con fetch_decimals:", repr(cur2.fetchone()[0]))
    cur.execute("DROP TABLE abono")''')
rep('''    print("pymssql conectado a SQL Server", cur.fetchone()[0])''','''    print("pymssql conectado a SQL Server", cur.fetchone()[0])     # sql_variant: llega como bytes''')
p.write_text(t)
EOF
cd ../../zz-code/python-for-java-devs-20261005-f516 && python3 humo_servicio.py op079-db03-sql-server-y-oracle.md db03 'aliados.py=@aliados.py' --svc mssql=mcr.microsoft.com/mssql/server:2022-latest --env mssql:ACCEPT_EULA=Y --env 'mssql:MSSQL_SA_PASSWORD=Aurea-Local-2026!' --svc oracle=gvenzl/oracle-free:23-slim --env oracle:ORACLE_PASSWORD=aurea-local --pip pyodbc==5.3.0 pymssql==2.4.2 oracledb==26.0.1 --cmd 'python aliados.py' 2>&1 | tail -9; docker ps -a --filter label=curso=python-for-java-devs --format '{{.Names}}'

# --- 2026-10-05T18:14:24 · Fill db03 outputs, mark tested, verify
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs && python3 - <<'EOF'
import pathlib
p=pathlib.Path("op079-db03-sql-server-y-oracle.md");t=p.read_text()
def rep(a,b):
    global t
    assert t.count(a)==1,a
    t=t.replace(a,b)
rep("pymssql conectado a SQL Server 16.0.…","pymssql conectado a SQL Server b'16.0.4295.3'")
rep("oracledb modo thin: True · Oracle 23.…","oracledb modo thin: True · Oracle 23.26.3.0.0")
rep("""- **`oracledb.defaults.fetch_decimals = True`** es global al proceso. Para plata, se pone al arrancar y no se vuelve a tocar.
  También se puede pedir por columna con un *output type handler*.""","""- **`oracledb.defaults.fetch_decimals = True`** es global al proceso y **solo vale para los cursores que se crean después**: en la
  primera versión de este ejemplo se cambió a mitad de camino sobre el mismo cursor y el monto siguió llegando como `float`.
  Para plata, se pone al arrancar, antes de la primera conexión, y no se vuelve a tocar. También se puede pedir por columna con
  un *output type handler*.
- **`b'16.0.4295.3'`** llega como `bytes` porque `SERVERPROPERTY` devuelve un `sql_variant`, y `pymssql` no sabe a qué
  convertirlo. Se pide con `CAST(… AS NVARCHAR(128))`.""")
p.write_text(t)
EOF
cd ../../zz-code/python-for-java-devs-20261005-f516 && python3 probado.py op079-db03-sql-server-y-oracle.md && python3 plan.py 79 79 ✅ ✅ && cd - >/dev/null && python3 ../../zz-code/python-for-java-devs-20261005-f516/verificar_urls.py op079-db03-sql-server-y-oracle.md | tail -3 && python3 prompts/verificar-corpus.py | tail -1

# --- 2026-10-05T18:14:32 · Remove pulled DB images and record it
docker rmi gvenzl/oracle-free:23-slim mcr.microsoft.com/mssql/server:2022-latest 2>&1 | grep -c "Untagged\|Deleted"; F=/Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516/salidas/imagenes-bajadas.txt; sed -i '' 's#^gvenzl/oracle-free:23-slim$#gvenzl/oracle-free:23-slim  (borrada al cerrar db03)#; s#^mcr.microsoft.com/mssql/server:2022-latest$#mcr.microsoft.com/mssql/server:2022-latest  (borrada al cerrar db03)#' $F; cat $F

# --- 2026-10-05T18:15:27 · Clean timing code and smoke-test DuckDB
python3 - <<'EOF'
import pathlib
p=pathlib.Path("op081-db05-duckdb.md");t=p.read_text()
a='''for f in ("abonos.csv", "abonos.parquet"):
    best = min(timeit for timeit in (
        (lambda s: (con.sql(QUERY.format(f=f)).fetchall(), time.perf_counter() - s)[1])(time.perf_counter())
        for _ in range(3)))
    print(f"consulta sobre {f:<15} {best * 1000:5.0f} ms")
'''
assert t.count(a)==1
t=t.replace(a,'''

def best_of_three(sql: str) -> float:
    times = []
    for _ in range(3):
        start = time.perf_counter()
        con.sql(sql).fetchall()
        times.append(time.perf_counter() - start)
    return min(times)


for f in ("abonos.csv", "abonos.parquet"):
    print(f"consulta sobre {f:<15} {best_of_three(QUERY.format(f=f)) * 1000:5.0f} ms")
''')
p.write_text(t)
EOF
cd ../../zz-code/python-for-java-devs-20261005-f516 && python3 humo.py op081-db05-duckdb.md db05 'abonos.py=@abonos.py' --pip duckdb==1.5.6 --cmd 'rm -f aurea.duckdb* abonos.*; python abonos.py' 2>&1 | tail -10; cd ../../cursos-algoritmos-lenguajes/python-for-java-devs && python3 ../../zz-code/python-for-java-devs-20261005-f516/verificar_urls.py op081-db05-duckdb.md | tail -3

# --- 2026-10-05T18:15:38 · Rerun DuckDB test with precise cleanup
cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516 && python3 humo.py op081-db05-duckdb.md db05 'abonos.py=@abonos.py' --pip duckdb==1.5.6 --cmd 'rm -f aurea.duckdb aurea.duckdb.wal abonos.csv abonos.parquet; python abonos.py' 2>&1 | tail -10

# --- 2026-10-05T18:15:51 · Fill DuckDB output, mark db05
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs && python3 - <<'EOF'
import pathlib,re
p=pathlib.Path("op081-db05-duckdb.md");t=p.read_text()
old=re.search(r"```text\nabonos\.csv        … MB.*?\n```",t,re.S).group(0)
t=t.replace(old,"""```text
abonos.csv        27.1 MB
abonos.parquet     6.2 MB
consulta sobre abonos.csv        118 ms
consulta sobre abonos.parquet     18 ms
  Suba       2026-03  Decimal('3377879908')
  Restrepo   2026-03  Decimal('3374611485')
  Centro     2026-08  Decimal('3373695850')
segundo proceso: _duckdb.IOException: IO Error: Could not set lock on file "/w/aurea.duckdb": Conflicting lock is held in /usr/
```

Un millón de abonos, y la misma consulta sobre los dos formatos: el Parquet ocupa 4,4 veces menos y responde 6,5 veces más
rápido (18 ms contra 118). Los montos llegan como `Decimal`. Y el segundo proceso que intenta abrir `aurea.duckdb` mientras el
primero lo tiene abierto falla con un bloqueo, que es el límite de diseño de la sección.""")
t=t.replace("Salida esperada, sin correr (los milisegundos son de la máquina que corre):","Salida esperada, sin correr (los milisegundos son de la máquina que corre; estos, de un contenedor en un portátil):")
p.write_text(t)
EOF
cd ../../zz-code/python-for-java-devs-20261005-f516 && python3 probado.py op081-db05-duckdb.md && python3 plan.py 81 81 ✅ ✅ && cd - >/dev/null && python3 prompts/verificar-corpus.py | tail -1

# --- 2026-10-05T18:16:45 · Smoke-test Valkey example and URLs
cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516 && python3 humo_servicio.py op082-db06-valkey.md db06 'valkey_trampas.py=@valkey_trampas.py' --svc valkey=valkey/valkey:9.1 --pip redis==8.1.0 --cmd 'python valkey_trampas.py' 2>&1 | tail -9; docker ps -a --filter label=curso=python-for-java-devs --format '{{.Names}}'; cd ../../cursos-algoritmos-lenguajes/python-for-java-devs && python3 ../../zz-code/python-for-java-devs-20261005-f516/verificar_urls.py op082-db06-valkey.md | tail -2

# --- 2026-10-05T18:17:05 · Fill Valkey measurements, mark db06
python3 - <<'EOF'
import pathlib
p=pathlib.Path("op082-db06-valkey.md");t=p.read_text()
def rep(a,b):
    global t
    assert t.count(a)==1,a
    t=t.replace(a,b)
rep("servidor: 9.1.…","servidor: 9.1.2")
rep("KEYS: 500000 claves en … s · PING de otro cliente: mediana … ms, peor … ms","KEYS: 500000 claves en 0.32 s · PING de otro cliente: mediana 315.8 ms, peor 316 ms")
rep("""SCAN: 500000 claves en … s · PING de otro cliente: mediana … ms, peor … ms
```
""","""SCAN: 500000 claves en 0.43 s · PING de otro cliente: mediana 0.8 ms, peor 6 ms
```

Las dos primeras líneas son la trampa de los tipos: el número vuelve como `bytes`, o como `str` con `decode_responses`. El
turno se bloqueó una vez, el segundo intento recibió `None`, y a los dos segundos el bloqueo ya no estaba. Y las dos últimas son
la razón de la regla de `KEYS`: mientras recorría medio millón de claves, el `PING` de **otro** cliente esperó los 316 ms
completos, porque el servidor no atendía a nadie más; con `SCAN`, que tardó un poco más en total, ese mismo `PING` respondió en
menos de un milisegundo. Con cinco millones de claves, `KEYS` congela la agenda en línea durante segundos.
""")
p.write_text(t)
EOF
cd ../../zz-code/python-for-java-devs-20261005-f516 && python3 probado.py op082-db06-valkey.md && python3 plan.py 82 82 ✅ ✅ && cd - >/dev/null && python3 prompts/verificar-corpus.py | tail -1

# --- 2026-10-05T18:17:59 · Smoke-test MongoDB example and URLs
cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516 && python3 humo_servicio.py op083-db07-mongodb.md db07 'citas_mongo.py=@citas_mongo.py' --svc mongo=mongo:8.0.20 --pip pymongo==4.18.2 --cmd 'python citas_mongo.py' 2>&1 | tail -10; docker ps -a --filter label=curso=python-for-java-devs --format '{{.Names}}'; cd ../../cursos-algoritmos-lenguajes/python-for-java-devs && python3 ../../zz-code/python-for-java-devs-20261005-f516/verificar_urls.py op083-db07-mongodb.md | tail -3

# --- 2026-10-05T18:18:16 · Fill MongoDB output, mark db07
python3 - <<'EOF'
import pathlib
p=pathlib.Path("op083-db07-mongodb.md");t=p.read_text()
def rep(a,b):
    global t
    assert t.count(a)==1,a
    t=t.replace(a,b)
rep("sin índice: COLLSCAN, 200000 documentos examinados para …","sin índice: COLLSCAN, 200000 documentos examinados para 18722")
rep("con índice: IXSCAN, … documentos examinados para …","con índice: IXSCAN, 18722 documentos examinados para 18722")
rep("documento de la sede: BSON document too large (… bytes) - the connected server supports BSON document sizes up to 16777216 bytes.","documento de la sede: BSON document too large (22069027 bytes) - the connected server supports BSON document siz")
rep("Decimal: cannot encode object: Decimal('1250000.10'), of type: <class 'decimal.Decimal'>","Decimal: Invalid document: cannot encode object: Decimal('1250000.10'), of type: <class 'decimal.Decimal'>")
rep("""fecha leída: datetime.datetime(2026, 1, 1, 7, 0)
```
""","""fecha leída: datetime.datetime(2026, 1, 1, 7, 0)
```

Para devolver 18 722 citas de Suba, la consulta sin índice examinó las 200 000 de la colección; con el índice, exactamente las
18 722. Nada en el resultado dice cuál de las dos pasó: solo `explain()`. El documento de la sede con sus 80 000 recordatorios
pesaba 22 MB y el cliente lo rechazó antes de mandarlo. El `Decimal` no se pudo guardar hasta envolverlo en `Decimal128`, y la
fecha guardada en UTC volvió sin zona.
""")
p.write_text(t)
EOF
cd ../../zz-code/python-for-java-devs-20261005-f516 && python3 probado.py op083-db07-mongodb.md && python3 plan.py 83 83 ✅ ✅ && cd - >/dev/null && python3 prompts/verificar-corpus.py | tail -1

# --- 2026-10-05T18:19:14 · Smoke-test Cassandra example
cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516 && python3 humo_servicio.py op084-db08-cassandra.md db08 'mensajeria.py=@mensajeria.py' --svc cassandra=cassandra:5.0 --env cassandra:MAX_HEAP_SIZE=512M --env cassandra:HEAP_NEWSIZE=128M --pip cassandra-driver==3.30.1 --cmd 'python mensajeria.py' 2>&1 | tail -10; docker ps -a --filter label=curso=python-for-java-devs --format '{{.Names}}'

# --- 2026-10-05T18:20:22 · Fill Cassandra output, mark db08, verify
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs && python3 - <<'EOF'
import pathlib
p=pathlib.Path("op084-db08-cassandra.md");t=p.read_text()
def rep(a,b):
    global t
    assert t.count(a)==1,a
    t=t.replace(a,b)
rep("servidor: 5.0.…","servidor: 5.0.9")
rep('rechazada: "Cannot execute this query as it might involve data filtering and thus may have unpredictable performance. If you want','rechazada: "Cannot execute this query as it might involve data filtering and thus may have unpredictable performance. If ')
rep('''got estado"
```
''','''got estado"
```

La consulta para la que se diseñó la tabla devuelve los tres últimos eventos de Suba ya ordenados, sin ordenar nada. La paginación
trajo 100 filas y el resto al iterar. Y las dos consultas que en Postgres serían triviales —filtrar por `estado`, ordenar por
`estado`— el servidor las rechaza antes de ejecutar: la primera porque `estado` no es parte de la clave, la segunda porque el orden
de la partición ya está fijado.
''')
p.write_text(t)
EOF
cd ../../zz-code/python-for-java-devs-20261005-f516 && python3 probado.py op084-db08-cassandra.md && python3 plan.py 84 84 ✅ ✅ && cd - >/dev/null && python3 ../../zz-code/python-for-java-devs-20261005-f516/verificar_urls.py op084-db08-cassandra.md | tail -3 && python3 prompts/verificar-corpus.py | tail -1

# --- 2026-10-05T18:21:23 · Smoke-test Neo4j example
cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516 && python3 humo_servicio.py op085-db09-neo4j.md db09 'derivaciones.py=@derivaciones.py' --svc neo4j=neo4j:2026.09.0-community --env neo4j:NEO4J_AUTH=neo4j/aurea-local-2026 --pip neo4j==6.4.0 --cmd 'python derivaciones.py' 2>&1 | tail -10; docker ps -a --filter label=curso=python-for-java-devs --format '{{.Names}}'

# --- 2026-10-05T18:21:48 · Fill Neo4j output, mark db09, verify
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs && python3 - <<'EOF'
import pathlib
p=pathlib.Path("op085-db09-neo4j.md");t=p.read_text()
def rep(a,b):
    global t
    assert t.count(a)==1,a
    t=t.replace(a,b)
rep("""derivaciones de Suba: [{'destino': 'Centro', 'planes': …}] en … ms
sedes de PL-12345: […]
accesos a la base: sin índice … · con índice …
tipo de la fecha: neo4j.time.DateTime → datetime.datetime(2026, 9, 1, 10, 0, tzinfo=…)
```
""","""derivaciones de Suba: [{'destino': 'Centro', 'planes': 960}] en 193 ms
sedes de PL-12345: ['Usaquén']
accesos a la base: sin índice 40004 · con índice 5
tipo de la fecha: neo4j.time.DateTime → datetime.datetime(2026, 9, 1, 10, 0, tzinfo=pytz.FixedOffset(-300))
```

La pregunta de la liquidación se responde con un recorrido: 960 planes de Suba siguieron en el Centro. Encontrar un plan por su
código sin índice costó 40 004 accesos a la base —dos por cada uno de los veinte mil planes—; con el índice, 5. El recorrido desde
ese plan es igual de barato en los dos casos: lo caro era encontrar dónde empezar. Y la fecha llegó como `neo4j.time.DateTime`,
que `.to_native()` convierte a un `datetime` con su zona… de `pytz`, que el *driver* todavía usa por dentro.
""")
rep("""- **`execute_query`** es la API corta""","""- **`neo4j://` hace enrutamiento** (pregunta al servidor por la topología del clúster); mientras el servidor arranca, los reintentos de
  `verify_connectivity` escriben `Unable to retrieve routing information` en la salida de error. Con un solo servidor, `bolt://` no
  enruta y no los escribe.
- **`execute_query`** es la API corta""")
p.write_text(t)
EOF
cd ../../zz-code/python-for-java-devs-20261005-f516 && python3 probado.py op085-db09-neo4j.md && python3 plan.py 85 85 ✅ ✅ && cd - >/dev/null && python3 ../../zz-code/python-for-java-devs-20261005-f516/verificar_urls.py op085-db09-neo4j.md | tail -3 && python3 prompts/verificar-corpus.py | tail -1

# --- 2026-10-05T18:21:56 · List recent InfluxDB image tags
curl -s "https://hub.docker.com/v2/repositories/library/influxdb/tags?page_size=40&ordering=last_updated" | python3 -c "import json,sys; print([t['name'] for t in json.load(sys.stdin)['results']])"

# --- 2026-10-05T18:22:08 · Pull InfluxDB 3 Core and inspect entrypoint
echo "influxdb:3.12.0-core" >> /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516/salidas/imagenes-bajadas.txt; docker image inspect influxdb:3.12.0-core >/dev/null 2>&1 && echo ya-estaba || docker pull -q influxdb:3.12.0-core; docker image inspect influxdb:3.12.0-core --format '{{.Config.Entrypoint}} {{.Config.Cmd}} {{.Architecture}}'

# --- 2026-10-05T18:23:09 · Smoke-test TimescaleDB and InfluxDB example
cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516 && python3 humo_servicio.py op086-db10-series-de-tiempo.md db10 'espera.py="""La misma semana' --svc tsdb=timescale/timescaledb:2.30.1-pg18 --env tsdb:POSTGRES_PASSWORD=aurea-local --svc influx=influxdb:3.12.0-core --args 'influx:influxdb3 serve --node-id aurea --object-store memory --without-auth' --pip "psycopg[binary]==3.3.6" influxdb3-python==0.21.0 --cmd 'python espera.py' 2>&1 | tail -12; docker ps -a --filter label=curso=python-for-java-devs --format '{{.Names}}'

# --- 2026-10-05T18:24:31 · Use placeholder token and rerun db10
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs && python3 - <<'EOF'
import pathlib
p=pathlib.Path("op086-db10-series-de-tiempo.md");t=p.read_text()
def rep(a,b):
    global t
    assert t.count(a)==1,a
    t=t.replace(a,b)
rep('influx = InfluxDBClient3(host=os.environ.get("AUREA_INFLUX", "http://influx:8181"), database="sedes", token="")',
    'influx = InfluxDBClient3(host=os.environ.get("AUREA_INFLUX", "http://influx:8181"), database="sedes",\n                         token="local")                       # el servidor sin auth lo ignora, pero no acepta uno vacío')
rep("""- **`--without-auth`** es solo para el contenedor local del ejemplo. En cualquier otro lado, InfluxDB 3 se usa con *token*.""",
"""- **`--without-auth`** es solo para el contenedor local del ejemplo. En cualquier otro lado, InfluxDB 3 se usa con *token*. Aun sin
  autenticación, el cliente necesita un *token* no vacío: con `token=""` manda un encabezado `Authorization: Token ` incompleto y el
  servidor responde `400 Authorization header was malformed`, que fue el primer error de este ejemplo.""")
p.write_text(t)
EOF
cd ../../zz-code/python-for-java-devs-20261005-f516 && python3 humo_servicio.py op086-db10-series-de-tiempo.md db10 'espera.py="""La misma semana' --svc tsdb=timescale/timescaledb:2.30.1-pg18 --env tsdb:POSTGRES_PASSWORD=aurea-local --svc influx=influxdb:3.12.0-core --args 'influx:influxdb3 serve --node-id aurea --object-store memory --without-auth' --pip "psycopg[binary]==3.3.6" influxdb3-python==0.21.0 --cmd 'python espera.py' 2>&1 | tail -10; docker ps -a --filter label=curso=python-for-java-devs --format '{{.Names}}'

# --- 2026-10-05T18:26:07 · Fill db10 output honestly, adjust exercise, mark
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs && python3 - <<'EOF'
import pathlib,re
p=pathlib.Path("op086-db10-series-de-tiempo.md");t=p.read_text()
old=re.search(r"```text\nmediciones: 100800\n.*?\n```\n",t,re.S).group(0)
t=t.replace(old,"""```text
mediciones: 100800
TimescaleDB: carga 0.2 s · 7 particiones de un día
  Suba por día: [('2026-09-28', Decimal('8.84')), ('2026-09-29', Decimal('9.05')), ('2026-09-30', Decimal('9.03'))]
InfluxDB 3: carga 11.0 s
  devuelve: pyarrow.Table
  Suba por día: [('2026-09-28', 8.84), ('2026-09-29', 9.05), ('2026-09-30', 9.03)]
```

Las dos bases dan los mismos promedios diarios —TimescaleDB como `Decimal`, porque la columna es `numeric`; InfluxDB como `float`—,
y TimescaleDB partió la semana en siete particiones de un día. Los tiempos de carga **no son una comparación de motores** y no
deben leerse así: los 0,2 s de TimescaleDB son un `COPY`, el camino más rápido de Postgres; los 11 s de InfluxDB son, en su mayor
parte, el cliente construyendo cien mil objetos `Point` en Python. Escribir el *line protocol* directamente, o un `DataFrame`, es
el ejercicio 7 y cambia la cifra.
""")
p.write_text(t)
EOF
sed -i '' 's/^7\. Mide una consulta de un mes sobre los dos motores con un año de datos\. \*\*Criterio:\*\* la tabla de tiempos, con las versiones\./7. Carga la semana en InfluxDB escribiendo el *line protocol* como texto, y como `DataFrame`, en vez de objetos `Point`. **Criterio:** los tres tiempos de carga, y cuánto de los 11 s era el cliente./' op086-db10-series-de-tiempo.md && grep -c "cuánto de los 11 s era el cliente" op086-db10-series-de-tiempo.md && cd ../../zz-code/python-for-java-devs-20261005-f516 && python3 probado.py op086-db10-series-de-tiempo.md && python3 plan.py 86 86 ✅ ✅ && cd - >/dev/null && python3 ../../zz-code/python-for-java-devs-20261005-f516/verificar_urls.py op086-db10-series-de-tiempo.md | tail -3 && python3 prompts/verificar-corpus.py | tail -1

# --- 2026-10-05T18:26:35 · Probe TimescaleDB documentation URLs
for u in https://docs.timescale.com/use-timescale/latest/hypertables/ https://docs.timescale.com/api/latest/hyperfunctions/time_bucket/ https://www.tigerdata.com/docs/use-timescale/latest/hypertables https://github.com/timescale/timescaledb; do echo "$(curl -s -o /dev/null -w '%{http_code} %{url_effective}' -L -m 20 "$u") <- $u"; done

# --- 2026-10-05T18:27:39 · Find final time_bucket doc URL
for u in https://www.tigerdata.com/docs/api/latest/hyperfunctions/time_bucket https://www.tigerdata.com/docs/api/latest/hyperfunctions/time_bucket/ https://www.tigerdata.com/docs/reference/timescaledb/hyperfunctions/time_bucket; do echo "$(curl -s -o /dev/null -w '%{http_code} %{redirect_url}' -m 20 "$u") <- $u"; done

# --- 2026-10-05T18:28:28 · Replace TimescaleDB URLs and recheck
u=https://www.tigerdata.com/docs/reference/timescaledb/hyperfunctions/time-series-utilities/time_bucket; echo "$(curl -s -o /dev/null -w '%{http_code}' -L -m 30 $u) $u"; cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs && sed -i '' -e 's#- TimescaleDB, hipertablas: https://docs.timescale.com/use-timescale/latest/hypertables/#- TimescaleDB (hoy de Tiger Data), hipertablas: https://www.tigerdata.com/docs/learn/hypertables/understand-hypertables#' -e "s#- TimescaleDB, \`time_bucket\`: https://docs.timescale.com/api/latest/hyperfunctions/time_bucket/#- TimescaleDB, \`time_bucket\`: $u#" op086-db10-series-de-tiempo.md && python3 ../../zz-code/python-for-java-devs-20261005-f516/verificar_urls.py op086-db10-series-de-tiempo.md | tail -2

# --- 2026-10-05T18:30:48 · Replace recreate_collection, get numpy version
grep -m1 "| \`numpy\`" prompts/inventario-verificado.md; python3 - <<'EOF'
import pathlib
p=pathlib.Path("op087-db11-vectorial.md");t=p.read_text()
a='qd.recreate_collection("respuesta", vectors_config=models.VectorParams(size=DIM, distance=models.Distance.EUCLID))\n'
assert t.count(a)==1
t=t.replace(a,'if qd.collection_exists("respuesta"):\n    qd.delete_collection("respuesta")\nqd.create_collection("respuesta", vectors_config=models.VectorParams(size=DIM, distance=models.Distance.EUCLID))\n')
p.write_text(t)
EOF
echo ok

# --- 2026-10-05T18:30:53 · Smoke-test pgvector and Qdrant recall
cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516 && python3 humo_servicio.py op087-db11-vectorial.md db11 'vecinos.py=@vecinos.py' --svc pgv=pgvector/pgvector:0.8.6-pg18 --env pgv:POSTGRES_PASSWORD=aurea-local --svc qdrant=qdrant/qdrant:v1.19.1 --pip "psycopg[binary]==3.3.6" pgvector==0.5.0 qdrant-client==1.19.1 numpy==2.5.3 --cmd 'python vecinos.py' 2>&1 | tail -12; docker ps -a --filter label=curso=python-for-java-devs --format '{{.Names}}'

# --- 2026-10-05T18:31:29 · Force Qdrant indexing and rerun db11
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs && python3 - <<'EOF'
import pathlib
p=pathlib.Path("op087-db11-vectorial.md");t=p.read_text()
def rep(a,b):
    global t
    assert t.count(a)==1,a
    t=t.replace(a,b)
rep('''qd.create_collection("respuesta", vectors_config=models.VectorParams(size=DIM, distance=models.Distance.EUCLID))
qd.upload_collection("respuesta", vectors=vectors, ids=range(N), batch_size=2_000)
while qd.get_collection("respuesta").status != models.CollectionStatus.GREEN:
    time.sleep(0.5)
''','''qd.create_collection("respuesta", vectors_config=models.VectorParams(size=DIM, distance=models.Distance.EUCLID),
                     optimizers_config=models.OptimizersConfigDiff(indexing_threshold=1_000))   # en KB; ver el detalle
qd.upload_collection("respuesta", vectors=vectors, ids=range(N), batch_size=2_000)
while (info := qd.get_collection("respuesta")).status != models.CollectionStatus.GREEN or info.indexed_vectors_count < N:
    time.sleep(0.5)
print("  Qdrant   vectores en el índice HNSW:", info.indexed_vectors_count)
''')
rep("""- **El *recall* se mide contra la búsqueda exacta**""","""- **`indexing_threshold=1_000`** obliga a Qdrant a construir el índice. Por defecto no indexa segmentos de menos de unos 20 MB y
  los busca de forma exhaustiva: con los 12,8 MB de este ejemplo, la primera corrida dio *recall* 1,00 con cualquier `hnsw_ef` y el
  mismo tiempo que la búsqueda exacta, porque **no había índice**. Es una buena decisión del motor para colecciones chicas, y una
  trampa para quien mide.
- **El *recall* se mide contra la búsqueda exacta**""")
p.write_text(t)
EOF
cd ../../zz-code/python-for-java-devs-20261005-f516 && python3 humo_servicio.py op087-db11-vectorial.md db11 'vecinos.py=@vecinos.py' --svc pgv=pgvector/pgvector:0.8.6-pg18 --env pgv:POSTGRES_PASSWORD=aurea-local --svc qdrant=qdrant/qdrant:v1.19.1 --pip "psycopg[binary]==3.3.6" pgvector==0.5.0 qdrant-client==1.19.1 numpy==2.5.3 --cmd 'python vecinos.py' 2>&1 | tail -12; docker ps -a --filter label=curso=python-for-java-devs --format '{{.Names}}'

# --- 2026-10-05T18:32:07 · Create single-segment experiment variant
sed 's/optimizers_config=models.OptimizersConfigDiff(indexing_threshold=1_000))/optimizers_config=models.OptimizersConfigDiff(indexing_threshold=1_000, default_segment_number=1, max_segment_size=1_000_000))/' salidas/db11/vecinos.py > salidas/db11/vecinos_1seg.py && grep -c default_segment_number salidas/db11/vecinos_1seg.py && sed -i '' 's/^  Qdrant   vectores en el índice HNSW:", info.indexed_vectors_count)$/  Qdrant   vectores en el índice HNSW:", info.indexed_vectors_count, "segmentos:", info.segments_count)/' salidas/db11/vecinos_1seg.py; grep -n "segments_count\|print(\"  Qdrant   vectores" salidas/db11/vecinos_1seg.py

# --- 2026-10-05T18:32:15 · Compare multi vs single segment Qdrant recall
python3 - <<'EOF'
import pathlib
p=pathlib.Path("salidas/db11/vecinos_1seg.py");t=p.read_text()
t=t.replace('print("  Qdrant   vectores en el índice HNSW:", info.indexed_vectors_count)','print("  Qdrant   vectores en el índice HNSW:", info.indexed_vectors_count, "segmentos:", info.segments_count)')
p.write_text(t)
q=pathlib.Path("salidas/db11/vecinos.py");s=q.read_text()
s=s.replace('print("  Qdrant   vectores en el índice HNSW:", info.indexed_vectors_count)','print("  Qdrant   vectores en el índice HNSW:", info.indexed_vectors_count, "segmentos:", info.segments_count)')
pathlib.Path("salidas/db11/vecinos_nseg.py").write_text(s)
EOF
cat > salidas/db11/correr.sh <<'EOF'
python vecinos_nseg.py | grep Qdrant
echo ---
python vecinos_1seg.py | grep Qdrant
EOF
python3 humo_servicio.py op087-db11-vectorial.md db11 --svc pgv=pgvector/pgvector:0.8.6-pg18 --env pgv:POSTGRES_PASSWORD=aurea-local --svc qdrant=qdrant/qdrant:v1.19.1 --pip "psycopg[binary]==3.3.6" pgvector==0.5.0 qdrant-client==1.19.1 numpy==2.5.3 --cmd 'sh correr.sh' 2>&1 | tail -14

# --- 2026-10-05T18:37:11 · Publish segment config and rerun full db11
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs && python3 - <<'EOF'
import pathlib
p=pathlib.Path("op087-db11-vectorial.md");t=p.read_text()
def rep(a,b):
    global t
    assert t.count(a)==1,a
    t=t.replace(a,b)
rep('''                     optimizers_config=models.OptimizersConfigDiff(indexing_threshold=1_000))   # en KB; ver el detalle''',
'''                     optimizers_config=models.OptimizersConfigDiff(         # ver el detalle: sin esto, no hay HNSW que medir
                         indexing_threshold=1_000, default_segment_number=1, max_segment_size=1_000_000))''')
rep('''print("  Qdrant   vectores en el índice HNSW:", info.indexed_vectors_count)''','''print("  Qdrant   vectores en el índice HNSW:", info.indexed_vectors_count, "· segmentos:", info.segments_count)''')
rep("""- **`indexing_threshold=1_000`** obliga a Qdrant a construir el índice. Por defecto no indexa segmentos de menos de unos 20 MB y
  los busca de forma exhaustiva: con los 12,8 MB de este ejemplo, la primera corrida dio *recall* 1,00 con cualquier `hnsw_ef` y el
  mismo tiempo que la búsqueda exacta, porque **no había índice**. Es una buena decisión del motor para colecciones chicas, y una
  trampa para quien mide.""","""- **La configuración de optimizadores** es lo que hace que haya un HNSW que medir, y costó dos corridas descubrirlo. En la primera,
  Qdrant no construyó el índice: por defecto no indexa segmentos de menos de unos 20 MB (`indexing_threshold`), y estos vectores
  pesan 12,8 MB. En la segunda, con el índice construido, repartió los vectores en cuatro segmentos chicos y los siguió recorriendo
  enteros, porque prefiere la búsqueda exhaustiva cuando lo que hay que recorrer es chico (`full_scan_threshold`, 10 MB por
  defecto). Las dos veces dio *recall* 1,00 con cualquier `hnsw_ef` y el mismo tiempo que la búsqueda exacta. Con segmentos grandes,
  la curva es la de pgvector. Son buenas decisiones del motor para colecciones chicas, y una trampa para quien mide.""")
p.write_text(t)
EOF
cd ../../zz-code/python-for-java-devs-20261005-f516 && rm salidas/db11/vecinos_1seg.py salidas/db11/vecinos_nseg.py salidas/db11/correr.sh && python3 humo_servicio.py op087-db11-vectorial.md db11 'vecinos.py=@vecinos.py' --svc pgv=pgvector/pgvector:0.8.6-pg18 --env pgv:POSTGRES_PASSWORD=aurea-local --svc qdrant=qdrant/qdrant:v1.19.1 --pip "psycopg[binary]==3.3.6" pgvector==0.5.0 qdrant-client==1.19.1 numpy==2.5.3 --cmd 'python vecinos.py' 2>&1 | tail -12; docker ps -a --filter label=curso=python-for-java-devs --format '{{.Names}}'

# --- 2026-10-05T18:40:12 · Fill db11 output, mark, verify
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs && python3 - <<'EOF'
import pathlib,re
p=pathlib.Path("op087-db11-vectorial.md");t=p.read_text()
old=re.search(r"```text\n  pgvector exacto \(sin índice\)        … ms.*?\n```\n",t,re.S).group(0)
t=t.replace(old,"""```text
  pgvector exacto (sin índice)        5.62 ms por consulta
  pgvector HNSW, ef_search=10         0.28 ms por consulta · recall@10 0.34
  pgvector HNSW, ef_search=40         0.51 ms por consulta · recall@10 0.61
  pgvector HNSW, ef_search=200        1.66 ms por consulta · recall@10 0.90
  Qdrant   vectores en el índice HNSW: 50000 · segmentos: 2
  Qdrant   exacto                     5.44 ms por consulta · recall@10 1.00
  Qdrant   HNSW, hnsw_ef=10           0.83 ms por consulta · recall@10 0.34
  Qdrant   HNSW, hnsw_ef=40           0.94 ms por consulta · recall@10 0.62
  Qdrant   HNSW, hnsw_ef=200          1.39 ms por consulta · recall@10 0.90
```

Las dos bases dibujan la misma curva, porque las dos usan HNSW. Con `ef = 10`, la búsqueda es veinte veces más rápida que la exacta en
pgvector y acierta un tercio de los diez mejores; con `ef = 200`, sigue siendo tres o cuatro veces más rápida y acierta nueve de cada
diez. Los vectores aleatorios de 64 dimensiones son el peor caso para un índice aproximado; con *embeddings* reales, que tienen
estructura, el *recall* para el mismo `ef` suele ser más alto. Por eso se mide con los datos propios.
""")
t=t.replace("Salida esperada, sin correr (los milisegundos son de la máquina que corre):","Salida esperada, sin correr (los milisegundos son de la máquina que corre; estos, de contenedores en un portátil):")
p.write_text(t)
EOF
cd ../../zz-code/python-for-java-devs-20261005-f516 && python3 probado.py op087-db11-vectorial.md && python3 plan.py 87 87 ✅ ✅ && cd - >/dev/null && python3 ../../zz-code/python-for-java-devs-20261005-f516/verificar_urls.py op087-db11-vectorial.md | tail -3 && python3 prompts/verificar-corpus.py | tail -1

# --- 2026-10-05T18:40:23 · List Meilisearch tags and client versions
curl -s "https://hub.docker.com/v2/repositories/getmeili/meilisearch/tags?page_size=15&ordering=last_updated" | python3 -c "import json,sys; print([t['name'] for t in json.load(sys.stdin)['results']])"; grep -m3 "| \`opensearch-py\`\|| \`meilisearch\`\|| \`typesense\`" /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs/prompts/inventario-verificado.md

# --- 2026-10-05T18:40:28 · Pull Meilisearch image and record it
echo "getmeili/meilisearch:v1.54.3" >> /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516/salidas/imagenes-bajadas.txt; docker image inspect getmeili/meilisearch:v1.54.3 >/dev/null 2>&1 && echo ya-estaba || docker pull -q getmeili/meilisearch:v1.54.3

# --- 2026-10-05T18:41:38 · Smoke-test OpenSearch and Meilisearch example
cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516 && python3 humo_servicio.py op088-db12-busqueda.md db12 'faq.py=@faq.py' --svc search=opensearchproject/opensearch:3.8.0 --env search:discovery.type=single-node --env search:DISABLE_SECURITY_PLUGIN=true --env search:DISABLE_INSTALL_DEMO_CONFIG=true --env "search:OPENSEARCH_JAVA_OPTS=-Xms512m -Xmx512m" --svc meili=getmeili/meilisearch:v1.54.3 --pip opensearch-py==3.2.0 meilisearch==0.43.0 --cmd 'python faq.py' 2>&1 | tail -16; docker ps -a --filter label=curso=python-for-java-devs --format '{{.Names}}'

# --- 2026-10-05T18:46:00 · Fix spanish analyzer output, mark db12
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs && python3 - <<'EOF'
import pathlib
p=pathlib.Path("op088-db12-busqueda.md");t=p.read_text()
def rep(a,b):
    global t
    assert t.count(a)==1,a
    t=t.replace(a,b)
rep("  analizador spanish  → ['limpiez', 'duel']","  analizador spanish  → ['limpiez', 'duelen']")
rep("""- **El analizador `spanish`** quita palabras vacías ("las", "no") y reduce a la raíz ("limpiezas" → "limpiez"), así "limpieza" y
  "limpiezas" se encuentran mutuamente.""","""- **El analizador `spanish`** quita palabras vacías ("las", "no") y reduce a la raíz ("limpiezas" → "limpiez"), así "limpieza" y
  "limpiezas" se encuentran mutuamente. Con los verbos es menos hábil: "duelen" quedó igual, y no se encontraría buscando "duele".
  Es un reductor de raíces por reglas, no un diccionario.""")
rep("""          "\\u0000""","""          "\\u0000""") if False else None
p.write_text(t)
EOF
sed -n '/^\*\*Detalles con intención/,/^- \*\*`indices/p' op088-db12-busqueda.md | head -6; cd ../../zz-code/python-for-java-devs-20261005-f516 && python3 probado.py op088-db12-busqueda.md && python3 plan.py 88 88 ✅ ✅ && cd - >/dev/null && python3 ../../zz-code/python-for-java-devs-20261005-f516/verificar_urls.py op088-db12-busqueda.md | tail -3 && python3 prompts/verificar-corpus.py | tail -1

# --- 2026-10-05T18:46:09 · Align Mermaid diagram tokens with output
grep -n 'limpiez → doc 3' op088-db12-busqueda.md && sed -i '' 's#    A --> I\["Índice invertido:<br/>limpiez → doc 3<br/>duel → doc 3"\]#    A --> I["Índice invertido:<br/>limpiez → docs 1, 4<br/>duelen → …"]#' op088-db12-busqueda.md && grep -n "Índice invertido" op088-db12-busqueda.md

# --- 2026-10-05T18:46:18 · Check MinIO and alternatives image tags
curl -s "https://hub.docker.com/v2/repositories/minio/minio/tags?page_size=8&ordering=last_updated" | python3 -c "import json,sys; [print(t['name'], t['last_updated'][:10]) for t in json.load(sys.stdin)['results']]"; echo ---; for r in chrislusf/seaweedfs dxflrs/garage rustfs/rustfs; do curl -s "https://hub.docker.com/v2/repositories/$r/tags?page_size=4&ordering=last_updated" | python3 -c "import json,sys; print('$r', [(t['name'], t['last_updated'][:10]) for t in json.load(sys.stdin).get('results',[])])"; done

# --- 2026-10-05T18:46:25 · Inspect MinIO Docker Hub and README status
curl -s "https://hub.docker.com/v2/repositories/minio/minio/" | python3 -c "import json,sys; d=json.load(sys.stdin); print({k:d.get(k) for k in ('last_updated','status_description','description')})"; curl -s "https://hub.docker.com/v2/namespaces/minio/repositories/minio/tags?page_size=5" | head -c 600; echo; curl -s -o /dev/null -w '%{http_code}\n' https://github.com/minio/minio; curl -sL https://raw.githubusercontent.com/minio/minio/master/README.md | head -40 | grep -i -m5 "docker\|binar\|community\|maintenance\|archiv"

# --- 2026-10-05T18:46:30 · Read top of MinIO README
curl -sL https://raw.githubusercontent.com/minio/minio/master/README.md | head -20

# --- 2026-10-05T18:46:42 · Pull RustFS and inspect configuration
echo "rustfs/rustfs:1.0.1" >> /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516/salidas/imagenes-bajadas.txt; docker pull -q rustfs/rustfs:1.0.1 && docker image inspect rustfs/rustfs:1.0.1 --format '{{.Config.Entrypoint}} {{.Config.Cmd}} {{.Config.Env}} {{.Config.ExposedPorts}} {{.Architecture}}'

# --- 2026-10-05T18:47:40 · Verify MinIO image availability on Docker Hub
curl -s "https://hub.docker.com/v2/repositories/minio/minio/tags?page_size=3" | head -c 400; echo; curl -s -o /dev/null -w '%{http_code}\n' "https://hub.docker.com/r/minio/minio"; curl -s "https://registry.hub.docker.com/v2/repositories/minio/minio" | head -c 300; echo; docker manifest inspect minio/minio:latest 2>&1 | head -3

# --- 2026-10-05T18:47:53 · Smoke-test S3 example against RustFS
python3 - <<'EOF'
import pathlib
p=pathlib.Path("op089-db13-objetos-s3.md");t=p.read_text()
a="repository is no longer maintained\"*, y su imagen pública dejó de publicarse."
assert t.count(a)==1
t=t.replace(a,"repository is no longer maintained\"*, y la imagen `minio/minio` ya no está en Docker Hub (comprobado el 05/10/2026: la página\nresponde 404 y el registro niega el manifiesto).")
p.write_text(t)
EOF
cd ../../zz-code/python-for-java-devs-20261005-f516 && python3 humo_servicio.py op089-db13-objetos-s3.md db13 'exportes.py=@exportes.py' --svc s3=rustfs/rustfs:1.0.1 --env s3:RUSTFS_ACCESS_KEY=aurea-local --env s3:RUSTFS_SECRET_KEY=aurea-local-secret --pip boto3==1.43.108 s3fs==2026.9.0 --cmd 'python exportes.py' 2>&1 | tail -10; docker ps -a --filter label=curso=python-for-java-devs --format '{{.Names}}'

# --- 2026-10-05T18:48:07 · Show pip conflict between boto3 and s3fs
docker run --rm --label curso=python-for-java-devs python:3.14.7 sh -c 'pip install -q --root-user-action=ignore boto3==1.43.108 s3fs==2026.9.0 2>&1 | tail -6; echo ---; pip install -q --root-user-action=ignore s3fs==2026.9.0 boto3 2>&1 | tail -2; pip show boto3 botocore aiobotocore 2>/dev/null | grep -E "^(Name|Version)"'

# --- 2026-10-05T18:48:36 · Document the conflict and rerun db13
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs && python3 - <<'EOF'
import pathlib
p=pathlib.Path("op089-db13-objetos-s3.md");t=p.read_text()
def rep(a,b):
    global t
    assert t.count(a)==1,a
    t=t.replace(a,b)
rep("| `boto3` | 1.43.108 | La API completa de S3 |","| `boto3` | 1.43.108 (con `s3fs`, 1.43.106: ver §4) | La API completa de S3 |")
rep("""**Depender de MinIO sin mirar.**""","""**`boto3` y `s3fs` en el mismo proyecto.** `s3fs` usa `aiobotocore`, que fija un rango estrecho de `botocore`, y `boto3` exige su
`botocore` exacto. El 05/10/2026, `pip install boto3==1.43.108 s3fs==2026.9.0` falla con `ResolutionImpossible`; sin fijar `boto3`, el
resolvedor baja a 1.43.106, la última que `aiobotocore` 3.9.2 acepta. Con `uv` pasa lo mismo, y el archivo de bloqueo lo deja escrito.
Se fija `s3fs` y se deja que él elija `boto3`, no al revés.

**Depender de MinIO sin mirar.**""")
p.write_text(t)
EOF
cd ../../zz-code/python-for-java-devs-20261005-f516 && python3 humo_servicio.py op089-db13-objetos-s3.md db13 'exportes.py=@exportes.py' --svc s3=rustfs/rustfs:1.0.1 --env s3:RUSTFS_ACCESS_KEY=aurea-local --env s3:RUSTFS_SECRET_KEY=aurea-local-secret --pip s3fs==2026.9.0 boto3 --cmd 'python exportes.py' 2>&1 | tail -10; docker ps -a --filter label=curso=python-for-java-devs --format '{{.Names}}'

# --- 2026-10-05T18:49:06 · Mark db13, check URLs and corpus
python3 probado.py op089-db13-objetos-s3.md && python3 plan.py 89 89 ✅ ✅ && cd ../../cursos-algoritmos-lenguajes/python-for-java-devs && python3 ../../zz-code/python-for-java-devs-20261005-f516/verificar_urls.py op089-db13-objetos-s3.md | tail -3 && python3 prompts/verificar-corpus.py | tail -1

# --- 2026-10-05T18:49:18 · List NATS image tags
curl -s "https://hub.docker.com/v2/repositories/library/nats/tags?page_size=12&ordering=last_updated" | python3 -c "import json,sys; print([t['name'] for t in json.load(sys.stdin)['results']])"

# --- 2026-10-05T18:49:23 · Pull NATS image and record it
echo "nats:2.15.0" >> /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516/salidas/imagenes-bajadas.txt; docker image inspect nats:2.15.0 >/dev/null 2>&1 && echo ya-estaba || docker pull -q nats:2.15.0

# --- 2026-10-05T18:50:25 · Smoke-test Kafka and NATS example
python3 - <<'EOF'
import pathlib
p=pathlib.Path("op090-db14-bitacora-de-eventos.md");t=p.read_text()
a='admin = AdminClient({"bootstrap.servers": BROKER})\n'
assert t.count(a)==1
t=t.replace(a,'admin = AdminClient({"bootstrap.servers": BROKER})\nadmin.list_topics(timeout=60)                           # espera a que el broker responda\n')
p.write_text(t)
EOF
cd ../../zz-code/python-for-java-devs-20261005-f516 && python3 humo_servicio.py op090-db14-bitacora-de-eventos.md db14 'eventos.py=@eventos.py' --svc kafka=apache/kafka:4.3.1 --env kafka:KAFKA_NODE_ID=1 --env kafka:KAFKA_PROCESS_ROLES=broker,controller --env kafka:KAFKA_LISTENERS=PLAINTEXT://:9092,CONTROLLER://:9093 --env kafka:KAFKA_ADVERTISED_LISTENERS=PLAINTEXT://kafka:9092 --env kafka:KAFKA_CONTROLLER_LISTENER_NAMES=CONTROLLER --env kafka:KAFKA_LISTENER_SECURITY_PROTOCOL_MAP=CONTROLLER:PLAINTEXT,PLAINTEXT:PLAINTEXT --env kafka:KAFKA_CONTROLLER_QUORUM_VOTERS=1@kafka:9093 --env kafka:KAFKA_OFFSETS_TOPIC_REPLICATION_FACTOR=1 --env kafka:KAFKA_TRANSACTION_STATE_LOG_REPLICATION_FACTOR=1 --env kafka:KAFKA_TRANSACTION_STATE_LOG_MIN_ISR=1 --env kafka:KAFKA_GROUP_INITIAL_REBALANCE_DELAY_MS=0 --svc nats=nats:2.15.0 --args 'nats:-js' --pip confluent-kafka==2.15.1 nats-py==2.16.0 --cmd 'python eventos.py' 2>&1 | tail -10; docker ps -a --filter label=curso=python-for-java-devs --format '{{.Names}}'

# --- 2026-10-05T18:50:56 · Fill partition, add listener note, mark db14
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs && python3 - <<'EOF'
import pathlib
p=pathlib.Path("op090-db14-bitacora-de-eventos.md");t=p.read_text()
def rep(a,b):
    global t
    assert t.count(a)==1,a
    t=t.replace(a,b)
rep("  Suba siempre en la misma partición: {…} · orden de Suba: [0, 2, 4]","  Suba siempre en la misma partición: {2} · orden de Suba: [0, 2, 4]")
rep("""- **`nats-py` es asíncrono**""","""- **El *listener* anunciado.** El contenedor de Kafka de las instrucciones anuncia `localhost:9092`, que sirve para un cliente en el
  mismo equipo. Si el programa de Python corre en otro contenedor, el cliente recibe esa dirección del broker y no puede conectarse:
  hay que configurar `KAFKA_ADVERTISED_LISTENERS` con el nombre del servicio en la red (la prueba de humo de esta sección lo tuvo que
  hacer, junto con las demás variables de un nodo KRaft).
- **`nats-py` es asíncrono**""")
p.write_text(t)
EOF
cd ../../zz-code/python-for-java-devs-20261005-f516 && python3 probado.py op090-db14-bitacora-de-eventos.md && python3 plan.py 90 90 ✅ ✅ && cd - >/dev/null && python3 ../../zz-code/python-for-java-devs-20261005-f516/verificar_urls.py op090-db14-bitacora-de-eventos.md | tail -3 && python3 prompts/verificar-corpus.py | tail -1

# --- 2026-10-05T18:51:04 · Check NATS docs URL with curl and Python
echo "$(curl -s -o /dev/null -w '%{http_code}' -L -m 20 https://docs.nats.io/nats-concepts/jetstream) docs.nats.io"; python3 -c "
import urllib.request
try: urllib.request.urlopen('https://docs.nats.io/nats-concepts/jetstream', timeout=20); print('ok')
except Exception as e: print(e)"

# --- 2026-10-05T18:52:19 · Remove unverifiable claim, test db15
sed -i '' 's/(O'"'"'Reilly, 2017; segunda edición en preparación)/(O'"'"'Reilly, 2017)/' op091-db15-veredicto.md && grep -c "O'Reilly, 2017)\." op091-db15-veredicto.md; cd ../../zz-code/python-for-java-devs-20261005-f516 && python3 humo.py op091-db15-veredicto.md db15 'arbol.py="""¿Postgres o un especializado?' --cmd 'python arbol.py' 2>&1 | tail -10; cd - >/dev/null && python3 ../../zz-code/python-for-java-devs-20261005-f516/verificar_urls.py op091-db15-veredicto.md | tail -2

# --- 2026-10-05T18:52:26 · Confirm first output line of db15
cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516 && python3 humo.py op091-db15-veredicto.md db15 'arbol.py="""¿Postgres o un especializado?' --cmd 'python arbol.py' 2>/dev/null | head -1

# --- 2026-10-05T18:52:33 · Mark db15, refresh db inventory, compare versions
python3 probado.py op091-db15-veredicto.md && python3 plan.py 91 91 ✅ ✅ && cd ../../cursos-algoritmos-lenguajes/python-for-java-devs && python3 prompts/check-inventario.py db | tail -1 && for kv in psycopg:3.3.6 PyMySQL:1.2.3 pyodbc:5.3.0 pymssql:2.4.2 oracledb:26.0.1 duckdb:1.5.6 redis:8.1.0 pymongo:4.18.2 cassandra-driver:3.30.1 neo4j:6.4.0 influxdb3-python:0.21.0 pgvector:0.5.0 qdrant-client:1.19.1 opensearch-py:3.2.0 meilisearch:0.43.0 boto3:1.43.108 s3fs:2026.9.0 confluent-kafka:2.15.1 nats-py:2.16.0; do k=${kv%%:*}; v=${kv#*:}; grep -q "| \`$k\` | $v |" prompts/inventario-verificado.md || echo "CAMBIÓ $k (probado $v): $(grep "| \`$k\` |" prompts/inventario-verificado.md | head -1)"; done; echo revisado; python3 prompts/verificar-corpus.py | tail -1

# --- 2026-10-05T18:54:10 · Close T10 in plan, log entry, update memory
cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516 && python3 plan.py tanda T10 ✅ && python3 plan.py dondeesta "T1–T10 cerradas (91 de 176). Sigue T11 jv (op092)." && cd ../../cursos-algoritmos-lenguajes/python-for-java-devs && n=$(for f in op07[7-9]*.md op08*.md op09[01]*.md; do grep -o "Ejercicios ([0-9]*)" $f; done | grep -o "[0-9]*" | paste -sd+ - | bc) && echo "ejercicios=$n" && python3 - "$n" <<'EOF'
import pathlib,sys
p=pathlib.Path("prompts/plan-de-produccion-carta.md");t=p.read_text()
anchor="## 7. 📓 Bitácora\n\n"
entry=(f"**2026-10-05 · T10 (`db`) cerrada.** Escritas op077–op091 (15 secciones, {sys.argv[1]} ejercicios), **las quince probadas en "
"contenedor contra el servicio real**, con un ayudante nuevo en `zz-code` (`humo_servicio.py`: red propia etiquetada, servicios sin "
"puertos publicados, limpieza garantizada; nunca quedó un contenedor ni una red). Imágenes de otros cursos usadas sin tocarlas "
"(postgres 18.6, mysql 9.7.2, mariadb 12.3.3, valkey 9.1, mongo 8.0.20, cassandra 5.0, neo4j 2026.09.0, timescaledb 2.30.1, "
"pgvector 0.8.6, qdrant 1.19.1, opensearch 3.8.0, kafka 4.3.1); bajadas para la carta y anotadas en `salidas/imagenes-bajadas.txt`: "
"oracle-free 23-slim y mssql 2022 (ya borradas), influxdb 3.12.0-core, meilisearch 1.54.3, rustfs 1.0.1, nats 2.15.0. "
"**Hallazgos y defectos propios:** en SQLite el DDL es transaccional y el `rollback` se llevó las tablas (db04, defecto propio); "
"`fetch_decimals` de `oracledb` solo vale para cursores nuevos y `pymssql` devuelve `sql_variant` como `bytes` (db03); con `KEYS` el "
"`PING` de otro cliente esperó 316 ms contra 0,8 ms con `SCAN` (db06); 200 000 documentos examinados sin índice contra 18 722 con "
"índice en MongoDB, y 40 004 contra 5 accesos en Neo4j (db07, db09); el *driver* de Neo4j devuelve zonas de `pytz`; InfluxDB 3 "
"rechaza un *token* vacío aun sin autenticación, y los 11 s de carga son del cliente, no del motor —se dijo así— (db10); Qdrant no "
"construye HNSW bajo `indexing_threshold` y en segmentos chicos busca exhaustivo, dos corridas con *recall* 1,00 engañoso hasta "
"configurar los segmentos (db11); el analizador `spanish` no reduce verbos (db12); **MinIO dejó de mantener su edición abierta y "
"`minio/minio` ya no está en Docker Hub** —db13 usa RustFS y lo dice—, y `boto3` 1.43.108 no instala junto a `s3fs` 2026.9.0 "
"(db13); Kafka en otro contenedor necesita `KAFKA_ADVERTISED_LISTENERS` (db14). **URL:** docs de TimescaleDB movidas a tigerdata.com; "
"dev.mysql.com, tigerdata.com y docs.nats.io rechazan al cliente de Python y responden 200 a curl: se conservan. **Inventario:** "
"ninguna versión probada cambió.\n\n")
t=t.replace(anchor,anchor+entry,1)
p.write_text(t)
EOF
M=/Users/oskar/.claude/projects/-Users-oskar-Developer-Learning-courses-ia-generated/memory; sed -i '' 's/T1–T9 (lg…ui) cerradas el 05\/10\/2026: 76 de 176; sigue T10 db\./T1–T10 (lg…db) cerradas el 05\/10\/2026: 91 de 176; sigue T11 jv. Imágenes bajadas por la carta en zz-code\/…\/salidas\/imagenes-bajadas.txt (borrarlas al final)./' $M/MEMORY.md && grep -c "91 de 176" $M/MEMORY.md

# --- 2026-10-05T18:54:15 · Read jv track rows and proposal
grep -n "| op09[2-9] .*jv\|| op10[0-9] .*jv" prompts/plan-de-produccion-carta.md; n=$(grep -n "Track \`jv\`" prompts/propuestas-temas-opcionales.md | head -1 | cut -d: -f1); sed -n "${n},$((n+45))p" prompts/propuestas-temas-opcionales.md; sed -n '/"jv"/,/\],/p' prompts/check-inventario.py

# --- 2026-10-05T18:54:24 · Look for Spring Boot project and JDK images
ls src 2>/dev/null | head -30; ls src/17* 2>/dev/null | head; grep -rn "3.5.16" --include=*.md -l . | head -5; docker images --format '{{.Repository}}:{{.Tag}}' | grep -i "temurin\|maven\|openjdk\|graalpy\|graalvm" 

# --- 2026-10-05T18:54:27 · Find Phase 17 Spring Boot material
ls *.md | head -30; grep -ln "Spring Boot 3.5" *.md | head; grep -rn "spring-boot" --include=pom.xml -l . 2>/dev/null | head

# --- 2026-10-05T18:54:32 · Skim Phase 17 for the Java service contract
grep -n "Spring Boot 3.5\|/abonos\|/citas\|endpoint\|contrato" 17-el-duelo-y-el-veredicto.md | head -20; grep -n "^## \|^### " 17-el-duelo-y-el-veredicto.md | head -30

# --- 2026-10-05T18:54:35 · Read Phase 17 endpoint code for both sides
sed -n 119,245p 17-el-duelo-y-el-veredicto.md

# --- 2026-10-05T18:55:03 · Check Temurin tags and Maven jar versions
curl -s "https://hub.docker.com/v2/repositories/library/eclipse-temurin/tags?page_size=30&name=21" | python3 -c "import json,sys; print([t['name'] for t in json.load(sys.stdin)['results'] if 'jdk' in t['name'] and 'alpine' not in t['name'] and 'windows' not in t['name']][:10])"; for g in "org/apache/avro/avro" "com/fasterxml/jackson/core/jackson-databind" "org/slf4j/slf4j-api" "org/jolokia/jolokia-agent-jvm"; do echo "$g: $(curl -s https://repo1.maven.org/maven2/$g/maven-metadata.xml | grep -o '<release>[^<]*' | cut -d'>' -f2)"; done

# --- 2026-10-05T18:55:14 · Pull JDK image and list Avro dependencies
echo "eclipse-temurin:21.0.12.1_1-jdk" >> /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516/salidas/imagenes-bajadas.txt; (docker image inspect eclipse-temurin:21.0.12.1_1-jdk >/dev/null 2>&1 || docker pull -q eclipse-temurin:21.0.12.1_1-jdk) | tail -1; curl -s https://repo1.maven.org/maven2/org/apache/avro/avro/1.12.2/avro-1.12.2.pom | python3 -c "
import sys,re
t=sys.stdin.read()
for d in re.findall(r'<dependency>(.*?)</dependency>',t,re.S):
    g=re.search(r'<groupId>(.*?)</groupId>',d).group(1); a=re.search(r'<artifactId>(.*?)</artifactId>',d).group(1)
    v=re.search(r'<version>(.*?)</version>',d); s=re.search(r'<scope>(.*?)</scope>',d); o=re.search(r'<optional>(.*?)</optional>',d)
    print(g,a,v.group(1) if v else '-', s.group(1) if s else 'compile', 'optional' if o else '')"; curl -s https://repo1.maven.org/maven2/org/apache/avro/avro-parent/1.12.2/avro-parent-1.12.2.pom | grep -o "<jackson-bom.version>[^<]*\|<slf4j.version>[^<]*\|<commons-compress.version>[^<]*"

# --- 2026-10-05T18:56:24 · Extract files and run Java Avro writer
cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516 && grep -m1 "| \`fastavro\`" ../../cursos-algoritmos-lenguajes/python-for-java-devs/prompts/inventario-verificado.md; python3 humo.py op092-jv01-los-formatos-de-la-jvm.md jv01 'abono.avsc={"type": "record"' 'EscribeAbonos.java=import java.io.File;' 'lee_abonos.py="""Leer en Python' --cmd 'true' >/dev/null; ls salidas/jv01; M=https://repo1.maven.org/maven2; docker run --rm --label curso=python-for-java-devs -v "$PWD/salidas/jv01:/w" -w /w eclipse-temurin:21.0.12.1_1-jdk sh -c "mkdir -p lib && cd lib && for j in org/apache/avro/avro/1.12.2/avro-1.12.2.jar com/fasterxml/jackson/core/jackson-core/2.22.1/jackson-core-2.22.1.jar com/fasterxml/jackson/core/jackson-databind/2.22.1/jackson-databind-2.22.1.jar com/fasterxml/jackson/core/jackson-annotations/2.22/jackson-annotations-2.22.jar org/apache/commons/commons-compress/1.28.0/commons-compress-1.28.0.jar org/slf4j/slf4j-api/2.0.18/slf4j-api-2.0.18.jar; do curl -sfLO $M/\$j || echo FALTA \$j; done; cd .. && java -version 2>&1 | head -1 && java -cp 'lib/*' EscribeAbonos.java" 2>&1 | tail -6

# --- 2026-10-05T18:56:36 · Read Java-written Avro from Python
docker run --rm --label curso=python-for-java-devs -v "$PWD/salidas/jv01:/w" -w /w python:3.14.7 sh -c 'pip install -q --root-user-action=ignore fastavro==1.12.2 >/dev/null 2>&1; python lee_abonos.py' 2>&1 | tail -6

# --- 2026-10-05T18:56:52 · Fix codec print and rerun Python reader
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs && python3 - <<'EOF'
import pathlib
p=pathlib.Path("op092-jv01-los-formatos-de-la-jvm.md");t=p.read_text()
def rep(a,b):
    global t
    assert t.count(a)==1,a
    t=t.replace(a,b)
rep('''    print("esquema del archivo:", reader.writer_schema["name"], "· escrito por:", reader.metadata.get("avro.codec"))''','''    print("esquema del archivo:", reader.writer_schema["name"], "· códec:", reader.codec)''')
rep("esquema del archivo: co.aurea.cartera.Abono · escrito por: null","esquema del archivo: co.aurea.cartera.Abono · códec: null")
rep("""- **El archivo Avro lleva su esquema adentro**""","""- **Las tres líneas `SLF4J(W): No SLF4J providers were found`** que imprime Java no son un error: Avro registra con SLF4J y en `lib/`
  no hay implementación. En un servicio de verdad la pone Spring Boot (Logback); aquí se agrega `slf4j-nop` o se ignoran.
- **El archivo Avro lleva su esquema adentro**""")
p.write_text(t)
EOF
cd ../../zz-code/python-for-java-devs-20261005-f516 && python3 humo.py op092-jv01-los-formatos-de-la-jvm.md jv01 'lee_abonos.py="""Leer en Python' --cmd 'true' >/dev/null && docker run --rm --label curso=python-for-java-devs -v "$PWD/salidas/jv01:/w" -w /w python:3.14.7 sh -c 'pip install -q --root-user-action=ignore fastavro==1.12.2 >/dev/null 2>&1; python lee_abonos.py' 2>&1 | head -2

# --- 2026-10-05T18:57:03 · Mark jv01 tested with dual-runtime label
python3 probado.py op092-jv01-los-formatos-de-la-jvm.md && cd ../../cursos-algoritmos-lenguajes/python-for-java-devs && grep -n "^Salida" op092-jv01-los-formatos-de-la-jvm.md && sed -i '' 's/^Salida (Python 3.14.7, 05\/10\/2026):$/Salida (Java 21.0.12.1 con Avro 1.12.2, y Python 3.14.7 con fastavro 1.12.2; 05\/10\/2026):/' op092-jv01-los-formatos-de-la-jvm.md && grep -n "^Salida" op092-jv01-los-formatos-de-la-jvm.md && python3 ../../zz-code/python-for-java-devs-20261005-f516/plan.py 92 92 ✅ ✅ && python3 ../../zz-code/python-for-java-devs-20261005-f516/verificar_urls.py op092-jv01-los-formatos-de-la-jvm.md | tail -3 && python3 prompts/verificar-corpus.py | tail -1

# --- 2026-10-05T18:57:12 · Show new verifier warning for jv01
python3 prompts/verificar-corpus.py | grep -i "op092\|jv01"

# --- 2026-10-05T18:57:18 · Use standard label prefix and re-verify
sed -i '' 's/^Salida (Java 21.0.12.1 con Avro 1.12.2, y Python 3.14.7 con fastavro 1.12.2; 05\/10\/2026):$/Salida (Python 3.14.7, 05\/10\/2026; la primera línea es del lado Java, con Java 21.0.12.1 y Avro 1.12.2):/' op092-jv01-los-formatos-de-la-jvm.md && python3 prompts/verificar-corpus.py | tail -1

# --- 2026-10-05T18:57:30 · Look up jv versions and Debian JDK packages
grep -m6 "| \`JPype1\`\|| \`py4j\`\|| \`graalpy\`\|| \`jmxquery\`\|| \`protobuf\`\|| \`pyarrow\`" prompts/inventario-verificado.md; docker run --rm python:3.14.7 sh -c 'apt-cache policy openjdk-21-jdk-headless openjdk-25-jdk-headless 2>/dev/null | grep -E "^openjdk|Candidate"' 

# --- 2026-10-05T18:57:35 · Check JDK packages available in Debian image
docker run --rm --label curso=python-for-java-devs python:3.14.7 sh -c 'apt-get update -qq >/dev/null 2>&1; apt-cache policy openjdk-21-jdk-headless openjdk-25-jdk-headless | grep -E "^openjdk|Candidate"'

# --- 2026-10-05T18:58:36 · Smoke-test JPype and Py4J calls
cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516 && python3 humo.py op093-jv02-jpype-y-py4j.md jv02 'co/aurea/Regalias.java=package co.aurea;' 'llamar_java.py="""La liquidación Java' --pip JPype1==1.7.1 py4j==0.10.9.9 --cmd 'apt-get update -qq >/dev/null 2>&1 && apt-get install -y -qq openjdk-21-jdk-headless >/dev/null 2>&1; rm -rf build regalias.jar; javac -d build co/aurea/Regalias.java && jar cf regalias.jar -C build . && python llamar_java.py' 2>&1 | tail -8

# --- 2026-10-05T18:59:09 · Move Java sources to java/ and rerun jv02
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs && python3 - <<'EOF'
import pathlib
p=pathlib.Path("op093-jv02-jpype-y-py4j.md");t=p.read_text()
def rep(a,b):
    global t
    assert t.count(a)==1,a
    t=t.replace(a,b)
rep("El código Java, `co/aurea/Regalias.java` —la versión mínima de la que lleva años en producción—:","El código Java, `java/co/aurea/Regalias.java` —la versión mínima de la que lleva años en producción—:")
rep("javac -d build co/aurea/Regalias.java && jar cf regalias.jar -C build .","javac -d build java/co/aurea/Regalias.java && jar cf regalias.jar -C build .")
rep("""**JPype y la JVM correcta.**""","""**Un directorio `co/` junto al script.** La primera corrida de este ejemplo tenía el código Java en `co/aurea/` al lado de
`llamar_java.py`, y `from co.aurea import Regalias` falló con `ImportError: cannot import name 'Regalias' from 'co.aurea' (unknown
location)`: Python encontró el directorio, lo tomó como un paquete de espacio de nombres (PEP 420) y nunca le preguntó a la JVM. Las
fuentes Java van en su propio directorio (`java/`, `src/main/java/`), fuera del camino de importación de Python.

**JPype y la JVM correcta.**""")
p.write_text(t)
EOF
cd ../../zz-code/python-for-java-devs-20261005-f516 && rm -rf salidas/jv02/co salidas/jv02/build salidas/jv02/regalias.jar && python3 humo.py op093-jv02-jpype-y-py4j.md jv02 'java/co/aurea/Regalias.java=package co.aurea;' 'llamar_java.py="""La liquidación Java' --pip JPype1==1.7.1 py4j==0.10.9.9 --cmd 'apt-get update -qq >/dev/null 2>&1 && apt-get install -y -qq openjdk-21-jdk-headless >/dev/null 2>&1; rm -rf build regalias.jar; javac -d build java/co/aurea/Regalias.java && jar cf regalias.jar -C build . && python llamar_java.py' 2>&1 | tail -8

# --- 2026-10-05T18:59:43 · Use src/main/java layout and rerun jv02
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs && python3 - <<'EOF'
import pathlib
p=pathlib.Path("op093-jv02-jpype-y-py4j.md");t=p.read_text()
def rep(a,b):
    global t
    assert t.count(a)==1,a
    t=t.replace(a,b)
rep("El código Java, `java/co/aurea/Regalias.java`","El código Java, `src/main/java/co/aurea/Regalias.java`")
rep("javac -d build java/co/aurea/Regalias.java","javac -d build src/main/java/co/aurea/Regalias.java")
rep("""location)`: Python encontró el directorio, lo tomó como un paquete de espacio de nombres (PEP 420) y nunca le preguntó a la JVM. Las
fuentes Java van en su propio directorio (`java/`, `src/main/java/`), fuera del camino de importación de Python.""","""location)`: Python encontró el directorio, lo tomó como un paquete de espacio de nombres (PEP 420) y nunca le preguntó a la JVM. La
segunda corrida, con las fuentes en `java/co/aurea/`, falló igual con `from java.math import BigDecimal`: ahora el directorio `java/`
tapaba el paquete `java` de la JVM. Las fuentes Java van en `src/main/java/`, cuya raíz no coincide con ningún paquete Java, o en
cualquier lugar fuera del camino de importación de Python.""")
p.write_text(t)
EOF
cd ../../zz-code/python-for-java-devs-20261005-f516 && rm -rf salidas/jv02/java salidas/jv02/build salidas/jv02/regalias.jar && python3 humo.py op093-jv02-jpype-y-py4j.md jv02 'src/main/java/co/aurea/Regalias.java=package co.aurea;' 'llamar_java.py="""La liquidación Java' --pip JPype1==1.7.1 py4j==0.10.9.9 --cmd 'apt-get update -qq >/dev/null 2>&1 && apt-get install -y -qq openjdk-21-jdk-headless >/dev/null 2>&1; rm -rf build regalias.jar; javac -d build src/main/java/co/aurea/Regalias.java && jar cf regalias.jar -C build . && python llamar_java.py' 2>&1 | tail -8

# --- 2026-10-05T19:00:16 · Fix constant folding in reference and rerun
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs && python3 - <<'EOF'
import pathlib
p=pathlib.Path("op093-jv02-jpype-y-py4j.md");t=p.read_text()
a="py = per_call_us(lambda: (142_900_000 * 450 + 5_000) // 10_000, 100_000)"
assert t.count(a)==1
t=t.replace(a,"sales, bps = 142_900_000, 450                 # en variables: con constantes, Python precalcula la cuenta\npy = per_call_us(lambda: (sales * bps + 5_000) // 10_000, 100_000)")
p.write_text(t)
EOF
cd ../../zz-code/python-for-java-devs-20261005-f516 && python3 humo.py op093-jv02-jpype-y-py4j.md jv02 'src/main/java/co/aurea/Regalias.java=package co.aurea;' 'llamar_java.py="""La liquidación Java' --pip JPype1==1.7.1 py4j==0.10.9.9 --cmd 'apt-get update -qq >/dev/null 2>&1 && apt-get install -y -qq openjdk-21-jdk-headless >/dev/null 2>&1; rm -rf build regalias.jar; javac -d build src/main/java/co/aurea/Regalias.java && jar cf regalias.jar -C build . && python llamar_java.py' 2>&1 | tail -5

# --- 2026-10-05T19:00:49 · Fill jv02 output, mark, verify
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs && python3 - <<'EOF'
import pathlib
p=pathlib.Path("op093-jv02-jpype-y-py4j.md");t=p.read_text()
def rep(a,b):
    global t
    assert t.count(a)==1,a
    t=t.replace(a,b)
rep("""JPype regalia: 6430500 BigDecimal → Decimal('6430500')
JPype franquicias: ['Suba', 'Zipaquirá'] · …
Py4J regalia: 6430500
por llamada: Python … µs · JPype … µs · Py4J … µs
```
""","""JPype regalia: 6430500 java.math.BigDecimal → Decimal('6430500')
JPype franquicias: ['Suba', 'Zipaquirá'] · java.util.ImmutableCollections.List12
Py4J regalia: 6430500
por llamada: Python 0.09 µs · JPype 0.57 µs · Py4J 141 µs
```

El mismo cálculo Java, el mismo resultado por los dos caminos, y tres órdenes de magnitud entre ellos. Con JPype, una llamada cuesta
medio microsegundo —unas seis veces la cuenta hecha en Python—: un millón de escenarios, medio segundo. Con Py4J, cada llamada cuesta
141 µs —unas 250 veces más que JPype—: el mismo millón, dos minutos y medio. La lista que devuelve Java llega como una lista
inmutable de Java, no como una `list` de Python; se itera igual, y se convierte con `list()` si sale de la frontera.
""")
rep("Salida esperada, sin correr:\n\n```text\nJPype regalia","Salida esperada, sin correr (los microsegundos son de la máquina que corre; estos, de un contenedor en un portátil):\n\n```text\nJPype regalia")
p.write_text(t)
EOF
cd ../../zz-code/python-for-java-devs-20261005-f516 && python3 probado.py op093-jv02-jpype-y-py4j.md && python3 plan.py 93 93 ✅ ✅ && cd - >/dev/null && python3 ../../zz-code/python-for-java-devs-20261005-f516/verificar_urls.py op093-jv02-jpype-y-py4j.md | tail -3 && python3 prompts/verificar-corpus.py | tail -1

# --- 2026-10-05T19:00:56 · Correct the time estimate wording
sed -i '' 's/141 µs —unas 250 veces más que JPype—: el mismo millón, dos minutos y medio\./141 µs —unas 250 veces más que JPype—: el mismo millón, dos minutos y veinte segundos./' op093-jv02-jpype-y-py4j.md && grep -c "dos minutos y veinte" op093-jv02-jpype-y-py4j.md

# --- 2026-10-05T19:01:07 · Check GraalPy release and Jython version
curl -s https://api.github.com/repos/oracle/graalpython/releases/latest | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('tag_name'), d.get('published_at')); [print(' ',a['name'], round(a['size']/1e6)) for a in d.get('assets',[]) if 'linux' in a['name'] and 'aarch64' in a['name'] and a['name'].endswith('.tar.gz')]"; echo "jython: $(curl -s https://repo1.maven.org/maven2/org/python/jython-standalone/maven-metadata.xml | grep -o '<release>[^<]*' | cut -d'>' -f2)"; echo "graalpy maven: $(curl -s https://repo1.maven.org/maven2/org/graalvm/python/python-community/maven-metadata.xml | grep -o '<release>[^<]*' | cut -d'>' -f2)"

# --- 2026-10-05T19:02:05 · Run CPython, GraalPy and Jython comparisons
curl -s -o /dev/null -w '%{http_code}\n' https://repo1.maven.org/maven2/org/python/jython-standalone/2.7.4/jython-standalone-2.7.4.jar; cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516 && python3 humo.py op094-jv03-graalpy-y-jython.md jv03 'cuenta.py="""El mismo bucle' --cmd 'apt-get update -qq >/dev/null 2>&1 && apt-get install -y -qq openjdk-21-jre-headless >/dev/null 2>&1; [ -d graalpy ] || (curl -sfL -o g.tgz https://github.com/oracle/graalpython/releases/download/graal-25.4.4/graalpy3.13-community-25.4.4-linux-aarch64.tar.gz && mkdir graalpy && tar xzf g.tgz -C graalpy --strip-components=1 && rm g.tgz); [ -f jython.jar ] || curl -sfL -o jython.jar https://repo1.maven.org/maven2/org/python/jython-standalone/2.7.4/jython-standalone-2.7.4.jar; python cuenta.py; graalpy/bin/graalpy cuenta.py; echo ---; for i in 1 2 3; do /usr/bin/time -f "python -c pass %e s" python -c pass; done 2>&1 | sort | head -1; for i in 1 2 3; do /usr/bin/time -f "graalpy -c pass %e s" graalpy/bin/graalpy -c pass; done 2>&1 | sort | head -1; echo ---; java -jar jython.jar -c "print \"Python 2 sí\""; java -jar jython.jar -c "sede = \"Suba\"; print(f\"regalía de {sede}\")"' 2>&1 | tail -25

# --- 2026-10-05T19:02:44 · Measure startup time of the three runtimes
cat > salidas/jv03/arranque.py <<'EOF'
import subprocess, time
for name, cmd in [("CPython", ["python", "-c", "pass"]), ("GraalPy", ["graalpy/bin/graalpy", "-c", "pass"]),
                  ("Jython", ["java", "-jar", "jython.jar", "-c", "pass"])]:
    best = min((lambda s: (subprocess.run(cmd, check=True), time.perf_counter() - s)[1])(time.perf_counter()) for _ in range(3))
    print(f"arranque {name}: {best:.2f} s")
EOF
docker run --rm --label curso=python-for-java-devs -v "$PWD/salidas/jv03:/w" -w /w python:3.14.7 sh -c 'apt-get update -qq >/dev/null 2>&1 && apt-get install -y -qq openjdk-21-jre-headless >/dev/null 2>&1; python arranque.py' 2>&1 | tail -3

# --- 2026-10-05T19:03:22 · Correct jv03 claims with measurements, mark tested
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs && python3 - <<'EOF'
import pathlib,re
p=pathlib.Path("op094-jv03-graalpy-y-jython.md");t=p.read_text()
def rep(a,b):
    global t
    assert t.count(a)==1,a
    t=t.replace(a,b)
rep("| Arranque | Rápido | Lento | Lento |","| Arranque (`-c pass`, medido) | 0,01 s | 0,16 s (lanzador nativo) | 0,64 s (la JVM) |")
rep("| Código Python puro, ya caliente | La referencia | **Puede ser varias veces más rápido** | Más lento |","| Código Python puro, ya caliente | La referencia | **Mucho más rápido** (el ejemplo lo mide) | Más lento |")
old=re.search(r"```text\nCPython 3\.14\.7\n  ronda 1: … s.*?SyntaxError: …\n```\n",t,re.S).group(0)
t=t.replace(old,"""```text
CPython 3.14.7
  ronda 1: 0.265 s  (11248680650000)
  ronda 2: 0.283 s  (11248680650000)
  ronda 3: 0.267 s  (11248680650000)
  ronda 4: 0.282 s  (11248680650000)
  ronda 5: 0.266 s  (11248680650000)
GraalVM 3.13.14
  ronda 1: 0.180 s  (11248680650000)
  ronda 2: 0.128 s  (11248680650000)
  ronda 3: 0.013 s  (11248680650000)
  ronda 4: 0.012 s  (11248680650000)
  ronda 5: 0.003 s  (11248680650000)
Python 2 s??

  File "<string>", line 1
    sede = "Suba"; print(f"regal??a de {sede}")
                         ^
SyntaxError: no viable alternative at input '"regal??a de {sede}"'
```

El mismo resultado en los dos intérpretes, y dos curvas distintas. CPython tarda lo mismo en las cinco rondas, unos 0,27 s. GraalPy
empieza apenas más rápido (0,18 s) mientras compila, y desde la tercera ronda el JIT ya optimizó el bucle: 0,003 s en la quinta, unas
noventa veces menos. Un bucle de enteros sin llamadas es el mejor caso posible para un JIT; con objetos, `Decimal` o llamadas a bibliotecas,
la ventaja se achica (ejercicio 4). Y Jython hace dos cosas de Python 2 en dos líneas: imprime la "í" como `??` —las cadenas de
Python 2 no son Unicode por defecto— y no reconoce la f-string.

Medido aparte en el mismo contenedor (el mejor de tres `-c pass`): CPython arranca en 0,01 s, GraalPy en 0,16 s y Jython en 0,64 s.
""")
rep("""**El arranque en *scripts* cortos.** Un *script* de cron que corre medio segundo en CPython puede tardar varios segundos solo en
arrancar GraalPy. El JIT no tiene tiempo de ayudar.""","""**El calentamiento en *scripts* cortos.** El lanzador de GraalPy es un binario nativo y arranca en 0,16 s —dieciséis veces lo de CPython,
pero no es lo que pesa—. Lo que pesa es que la primera ronda del ejemplo fue solo 1,5 veces más rápida que CPython: un *script* de cron
que termina antes de que el JIT compile no cosecha nada. Y GraalPy incrustado en una aplicación Java arranca con la JVM, que es otra
cuenta.""")
rep("""- **`platform.python_implementation()`** dice en qué Python se está corriendo; es la forma de que un mismo *script* sepa si está en
  GraalPy.""","""- **`platform.python_implementation()`** dice en qué Python se está corriendo, y en GraalPy devuelve **`GraalVM`**, no `GraalPy`: el
  código que pregunte por `"GraalPy"` no lo va a encontrar.""")
p.write_text(t)
EOF
sed -i '' 's/^Salida esperada, sin correr (los segundos son de la máquina que corre):$/Salida esperada, sin correr (los segundos son de la máquina que corre; estos, de un contenedor en un portátil, con GraalPy community 25.4.4 y Jython 2.7.4 sobre OpenJDK 21):/' op094-jv03-graalpy-y-jython.md; cd ../../zz-code/python-for-java-devs-20261005-f516 && rm salidas/jv03/arranque.py && python3 probado.py op094-jv03-graalpy-y-jython.md && python3 plan.py 94 94 ✅ ✅ && cd - >/dev/null && grep -n "^Salida" op094-jv03-graalpy-y-jython.md && python3 ../../zz-code/python-for-java-devs-20261005-f516/verificar_urls.py op094-jv03-graalpy-y-jython.md | tail -3 && python3 prompts/verificar-corpus.py | tail -1

# --- 2026-10-05T19:03:28 · Find working GraalPy embedding doc URL
for u in https://www.graalvm.org/latest/reference-manual/python/Embedding-Getting-Started/ https://www.graalvm.org/latest/reference-manual/python/ https://www.graalvm.org/python/docs/ https://www.graalvm.org/latest/reference-manual/python/Embedding/; do echo "$(curl -s -o /dev/null -w '%{http_code} %{url_effective}' -L -m 20 "$u") <- $u"; done

# --- 2026-10-05T19:03:33 · Replace broken GraalPy URL and recheck
sed -i '' 's#- GraalPy, incrustar en Java: https://www.graalvm.org/latest/reference-manual/python/Embedding-Getting-Started/#- GraalPy, documentación (incluye cómo incrustarlo en Java): https://www.graalvm.org/python/docs/#' op094-jv03-graalpy-y-jython.md && python3 ../../zz-code/python-for-java-devs-20261005-f516/verificar_urls.py op094-jv03-graalpy-y-jython.md | tail -1

# --- 2026-10-05T19:04:41 · Smoke-test Java HTTP frontier from Python
cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516 && python3 humo.py op095-jv04-la-arquitectura-mixta.md jv04 'ServidorRegalias.java=import com.sun.net.httpserver.HttpServer;' 'frontera.py="""El costo de una frontera' --pip httpx==0.28.1 --cmd 'apt-get update -qq >/dev/null 2>&1 && apt-get install -y -qq openjdk-21-jdk-headless >/dev/null 2>&1; java ServidorRegalias.java > java.log 2>&1 & python frontera.py; cat java.log' 2>&1 | tail -6

# --- 2026-10-05T19:06:45 · Rerun jv04 with TCP_NODELAY on JDK server
python3 humo.py op095-jv04-la-arquitectura-mixta.md jv04 'ServidorRegalias.java=import com.sun.net.httpserver.HttpServer;' 'frontera.py="""El costo de una frontera' --pip httpx==0.28.1 --cmd 'apt-get update -qq >/dev/null 2>&1 && apt-get install -y -qq openjdk-21-jdk-headless >/dev/null 2>&1; java -Dsun.net.httpserver.nodelay=true ServidorRegalias.java > java.log 2>&1 & python frontera.py' 2>&1 | tail -4

# --- 2026-10-05T19:07:15 · Capture all three jv04 output lines
python3 humo.py op095-jv04-la-arquitectura-mixta.md jv04 'ServidorRegalias.java=import com.sun.net.httpserver.HttpServer;' 'frontera.py="""El costo de una frontera' --pip httpx==0.28.1 --cmd 'apt-get update -qq >/dev/null 2>&1 && apt-get install -y -qq openjdk-21-jdk-headless >/dev/null 2>&1; java -Dsun.net.httpserver.nodelay=true ServidorRegalias.java > java.log 2>&1 & python frontera.py' 2>/dev/null | grep "µs\|diferencias"

# --- 2026-10-05T19:07:55 · Fill jv04 results and Nagle trap, mark, verify
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs && python3 - <<'EOF'
import pathlib
p=pathlib.Path("op095-jv04-la-arquitectura-mixta.md");t=p.read_text()
def rep(a,b):
    global t
    assert t.count(a)==1,a
    t=t.replace(a,b)
rep("java ServidorRegalias.java &\n","java -Dsun.net.httpserver.nodelay=true ServidorRegalias.java &      # el porqué de la opción, en §4\n")
rep("| HTTP, una llamada por operación | **el ejemplo lo mide** | Contrato | Error de red, reintento | Aquí |","| HTTP, una llamada por operación | ≈ 430 µs (en el mismo contenedor) | Contrato | Error de red, reintento | Aquí |")
rep("| HTTP, en lote | **el ejemplo lo mide** | Contrato | Error de red, reintento | Aquí |","| HTTP, en lote | ≈ 0,7 µs por elemento | Contrato | Error de red, reintento | Aquí |")
rep("""HTTP, una llamada por regalía:     … µs por regalía (2000 llamadas)
HTTP, en lote:                     … µs por regalía (100000 en una llamada)
diferencias Java contra Python: 0 de 100000 · sueltas contra lote: 0
```
""","""HTTP, una llamada por regalía:   432.3 µs por regalía (2000 llamadas)
HTTP, en lote:                     0.7 µs por regalía (100000 en una llamada)
diferencias Java contra Python: 0 de 100000 · sueltas contra lote: 0
```

La misma regalía, la misma regla, y seiscientas veces de diferencia según cómo se cruce la frontera: 432 µs por llamada suelta —el viaje
de ida y vuelta, aun dentro de un mismo contenedor—, 0,7 µs por regalía cuando cien mil viajan en una sola llamada. El lote queda en el
orden de JPype (`jv02`) sin meter la JVM en el proceso de Python. Y la prueba de equivalencia da cero diferencias en cien mil montos.
""")
rep("""**La llamada HTTP dentro del bucle.**""","""**Los 40 ms del JDK.** La primera corrida de este ejemplo midió **46 458 µs por llamada suelta**: cien veces lo de arriba. Es la
combinación clásica del algoritmo de Nagle con el ACK diferido de TCP: el servidor HTTP del JDK escribe las cabeceras y el cuerpo en dos
escrituras, Nagle retiene la segunda hasta recibir el ACK de la primera, y el cliente demora ese ACK unos 40 ms. Con
`-Dsun.net.httpserver.nodelay=true` (que activa `TCP_NODELAY` en el servidor), bajó a 432 µs. Cualquier servicio pequeño de petición y
respuesta que mida decenas de milisegundos sin razón merece esta sospecha antes que cualquier otra.

**La llamada HTTP dentro del bucle.**""")
p.write_text(t)
EOF
cd ../../zz-code/python-for-java-devs-20261005-f516 && python3 probado.py op095-jv04-la-arquitectura-mixta.md && python3 plan.py 95 95 ✅ ✅ && cd - >/dev/null && sed -i '' 's/^Salida (Python 3.14.7, 05\/10\/2026) (los microsegundos son de la máquina que corre):$/Salida (Python 3.14.7, 05\/10\/2026; el servicio, con OpenJDK 21.0.12 en el mismo contenedor) (los microsegundos son de la máquina que corre):/' op095-jv04-la-arquitectura-mixta.md && grep -n "^Salida" op095-jv04-la-arquitectura-mixta.md && python3 ../../zz-code/python-for-java-devs-20261005-f516/verificar_urls.py op095-jv04-la-arquitectura-mixta.md | tail -3 && python3 prompts/verificar-corpus.py | tail -1

# --- 2026-10-05T19:08:12 · Close T11 in plan, log entry, update memory
python3 prompts/check-inventario.py jv | tail -1 && for kv in fastavro:1.12.2 JPype1:1.7.1 py4j:0.10.9.9 httpx:0.28.1; do k=${kv%%:*}; v=${kv#*:}; grep -q "| \`$k\` | $v |" prompts/inventario-verificado.md || echo "CAMBIÓ $k"; done; cd ../../zz-code/python-for-java-devs-20261005-f516 && python3 plan.py tanda T11 ✅ && python3 plan.py dondeesta "T1–T11 cerradas (95 de 176): primer turno completo. Sigue T12 so (op096)." && cd - >/dev/null && python3 - <<'EOF'
import pathlib
p=pathlib.Path("prompts/plan-de-produccion-carta.md");t=p.read_text()
anchor="## 7. 📓 Bitácora\n\n"
entry=("**2026-10-05 · T11 (`jv`) cerrada — primer turno completo.** Escritas op092–op095 (4 secciones, 36 ejercicios), **las cuatro "
"probadas en contenedor con Java de verdad**: OpenJDK 21 (Temurin 21.0.12.1 bajada para jv01, y el paquete de Debian dentro de "
"`python:3.14.7` para jv02–jv04). **Hallazgos y defectos propios:** Java escribe Avro con `decimal` y `timestamp-millis` y `fastavro` "
"los lee como `Decimal` y `datetime` UTC (jv01); un directorio `co/` y luego uno `java/` junto al script taparon los paquetes Java en "
"JPype (PEP 420) hasta usar `src/main/java/` (jv02, dos defectos propios); la referencia en Python estaba plegada por constantes y "
"daba 0,02 µs (jv02, defecto propio, el mismo de ob05); JPype 0,57 µs contra Py4J 141 µs por llamada; GraalPy 25.4.4 (Python 3.13) "
"baja de 0,18 s a 0,003 s en cinco rondas contra 0,27 s constantes de CPython, arranca en 0,16 s (no en segundos, como decía el "
"borrador: corregido) y se declara `GraalVM` en `python_implementation()`; Jython 2.7.4 rompe la tilde y la f-string (jv03); el servidor "
"HTTP del JDK dio **46 458 µs por llamada** por Nagle y ACK diferido, 432 µs con `sun.net.httpserver.nodelay`, y 0,7 µs por elemento "
"en lote, con cero diferencias en 100 000 montos (jv04). **URL:** la guía de incrustación de GraalPy cambió de ruta. "
"**Inventario:** `graalpy` sigue sin estar en PyPI (se distribuye por GitHub y Maven); ninguna versión probada cambió.\n\n")
t=t.replace(anchor,anchor+entry,1)
p.write_text(t)
EOF
M=/Users/oskar/.claude/projects/-Users-oskar-Developer-Learning-courses-ia-generated/memory; sed -i '' 's/T1–T10 (lg…db) cerradas el 05\/10\/2026: 91 de 176; sigue T11 jv\./T1–T11 (primer turno) cerradas el 05\/10\/2026: 95 de 176; sigue T12 so./' $M/MEMORY.md && grep -c "95 de 176" $M/MEMORY.md

# --- 2026-10-05T19:08:23 · Read so track rows and proposal
grep -n "| op09[6-9] .*so\|| op10[0-9] .*so" prompts/plan-de-produccion-carta.md; n=$(grep -n "Track \`so\`" prompts/propuestas-temas-opcionales.md | head -1 | cut -d: -f1); sed -n "${n},$((n+40))p" prompts/propuestas-temas-opcionales.md; sed -n '/"so"/,/\],/p' prompts/check-inventario.py

# --- 2026-10-05T19:08:31 · Look up so track package versions
for k in ortools PuLP highspy mip Pyomo cvxpy simpy salabim scipy networkx deap optuna mesa; do grep -m1 "| \`$k\` |" prompts/inventario-verificado.md; done

# --- 2026-10-05T19:09:29 · Fix annotation and smoke-test so01
sed -i '' 's/def model(extra_rules: bool = False) -> tuple\[dict\[str, list\[str\]\], float\]:/def model(extra_rules: bool = False) -> tuple[dict[str, list[str]], float, str]:/' op096-so01-describir-en-vez-de-programar.md && grep -c "float, str\]:" op096-so01-describir-en-vez-de-programar.md && cd ../../zz-code/python-for-java-devs-20261005-f516 && python3 humo.py op096-so01-describir-en-vez-de-programar.md so01 'reparto_sabado.py=@reparto_sabado.py' --pip PuLP==4.0.0 highspy==1.15.1 --cmd 'python reparto_sabado.py' 2>&1 | tail -5

# --- 2026-10-05T19:09:46 · Inspect PuLP 4 variable API
docker run --rm --label curso=python-for-java-devs python:3.14.7 sh -c 'pip install -q --root-user-action=ignore PuLP==4.0.0 >/dev/null 2>&1; python -c "
import pulp, inspect
print([n for n in dir(pulp.LpVariable) if not n.startswith(\"__\")][:60])
print([n for n in dir(pulp.LpProblem) if \"var\" in n.lower()])
print([n for n in dir(pulp) if \"var\" in n.lower() or \"dict\" in n.lower()])
"; pip show pulp | grep -i "^version"; python - <<EOF
import pulp, re, pathlib
root = pathlib.Path(pulp.__file__).parent
for f in root.glob(\"*.md\"): print(f)
EOF
ls $(python -c "import pulp,os;print(os.path.dirname(pulp.__file__))") | head -30'

# --- 2026-10-05T19:09:57 · Print PuLP 4 variable creation signatures
docker run --rm --label curso=python-for-java-devs python:3.14.7 sh -c 'pip install -q --root-user-action=ignore PuLP==4.0.0 >/dev/null 2>&1; python -c "
import pulp, inspect
for n in (\"add_variable\",\"add_variable_dicts\",\"add_variable_dict\"):
    f=getattr(pulp.LpProblem,n); print(n, inspect.signature(f)); print((f.__doc__ or \"\").strip()[:300]); print()
"'

# --- 2026-10-05T19:10:11 · Migrate to PuLP 4 API, document, rerun
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs && python3 - <<'EOF'
import pathlib
p=pathlib.Path("op096-so01-describir-en-vez-de-programar.md");t=p.read_text()
def rep(a,b):
    global t
    assert t.count(a)==1,a
    t=t.replace(a,b)
rep('    x = pulp.LpVariable.dicts("x", [(e, s) for e in SPECIALISTS for s in SEDES], cat="Binary")',
    '    x = prob.add_variable_dicts("x", [(e, s) for e in SPECIALISTS for s in SEDES], cat="Binary")   # PuLP 4: desde el problema')
rep("""- **`LpVariable.dicts(..., cat="Binary")`** crea una variable 0/1 por cada par (especialista, sede): 108 variables. El modelo no dice
  cómo elegir; dice qué se elige.""","""- **`prob.add_variable_dicts(..., cat="Binary")`** crea una variable 0/1 por cada par (especialista, sede): 108 variables. El modelo no
  dice cómo elegir; dice qué se elige.
- **PuLP 4.0.0 (25/09/2026) reescribió su núcleo en Rust** y las variables ahora se crean desde el problema. El `pulp.LpVariable.dicts`
  de todos los tutoriales y respuestas en internet falla con `AttributeError: type object 'LpVariable' has no attribute 'dicts'`: la
  primera corrida de este ejemplo lo encontró. Con un proyecto existente, se fija `pulp<4` hasta migrar.""")
p.write_text(t)
EOF
cd ../../zz-code/python-for-java-devs-20261005-f516 && python3 humo.py op096-so01-describir-en-vez-de-programar.md so01 'reparto_sabado.py=@reparto_sabado.py' --pip PuLP==4.0.0 highspy==1.15.1 --cmd 'python reparto_sabado.py' 2>&1 | tail -5

# --- 2026-10-05T19:10:25 · Find PuLP 4 status API
docker run --rm --label curso=python-for-java-devs python:3.14.7 sh -c 'pip install -q --root-user-action=ignore PuLP==4.0.0 >/dev/null 2>&1; python -c "
import pulp
print([n for n in dir(pulp) if \"tatus\" in n])
print([n for n in dir(pulp.LpProblem) if \"tatus\" in n or n==\"objective\" or \"value\" in n.lower()])
from pulp import constants as c; print([n for n in dir(c) if \"tatus\" in n])
"'

# --- 2026-10-05T19:10:37 · Probe PuLP 4 solve status and value API
docker run --rm --label curso=python-for-java-devs python:3.14.7 sh -c 'pip install -q --root-user-action=ignore PuLP==4.0.0 highspy==1.15.1 >/dev/null 2>&1; python -c "
import pulp, inspect
print(list(pulp.LpSolveStatus) if hasattr(pulp.LpSolveStatus, \"__iter__\") else pulp.LpSolveStatus)
p = pulp.LpProblem(\"t\", pulp.LpMinimize)
x = p.add_variable(\"x\", 0, 5)
p += x
p += x >= 2
r = p.solve(pulp.HiGHS(msg=False))
print(\"solve devuelve:\", repr(r), type(r))
print([n for n in dir(p) if not n.startswith(\"_\")])
print(\"value:\", pulp.value(p.objective) if hasattr(pulp,\"value\") else \"sin pulp.value\", x.value())
"'

# --- 2026-10-05T19:10:55 · Migrate status API and rerun so01
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs && python3 - <<'EOF'
import pathlib
p=pathlib.Path("op096-so01-describir-en-vez-de-programar.md");t=p.read_text()
def rep(a,b):
    global t
    assert t.count(a)==1,a
    t=t.replace(a,b)
rep('''    prob.solve(pulp.HiGHS(msg=False))
    plan = {s: [e for e in SPECIALISTS if x[e, s].value() > 0.5] for s in SEDES}
    return plan, pulp.value(prob.objective), pulp.LpStatus[prob.status]''','''    stats = prob.solve(pulp.HiGHS(msg=False))                                                  # PuLP 4: devuelve el resultado
    plan = {s: [e for e in SPECIALISTS if x[e, s].value() > 0.5] for s in SEDES}
    return plan, stats.objective, stats.status.name''')
rep("""  de todos los tutoriales y respuestas en internet falla con `AttributeError: type object 'LpVariable' has no attribute 'dicts'`: la
  primera corrida de este ejemplo lo encontró. Con un proyecto existente, se fija `pulp<4` hasta migrar.""","""  de todos los tutoriales y respuestas en internet falla con `AttributeError: type object 'LpVariable' has no attribute 'dicts'`, y
  `pulp.LpStatus[prob.status]` también desapareció: `solve()` devuelve ahora un `LpSolveStats` con `status` (un enum) y `objective`. Las
  dos primeras corridas de este ejemplo lo encontraron, una cada vez. Con un proyecto existente, se fija `pulp<4` hasta migrar.""")
rep("""`Infeasible`. El código lee el estado **antes** de leer la solución;""","""`Infeasible`. El código lee el estado (`stats.status`) **antes** de leer la solución;""")
p.write_text(t)
EOF
cd ../../zz-code/python-for-java-devs-20261005-f516 && python3 humo.py op096-so01-describir-en-vez-de-programar.md so01 'reparto_sabado.py=@reparto_sabado.py' --pip PuLP==4.0.0 highspy==1.15.1 --cmd 'python reparto_sabado.py' 2>&1 | tail -5

# --- 2026-10-05T19:11:12 · Fill so01 output, mark, verify
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs && python3 - <<'EOF'
import pathlib
p=pathlib.Path("op096-so01-describir-en-vez-de-programar.md");t=p.read_text()
a="""voraz:           … minutos
modelo:          … minutos · Optimal
con dos reglas:  … minutos · Optimal · Suba: [… , …] · Soacha: [...]
```
"""
assert t.count(a)==1
t=t.replace(a,"""voraz:           176 minutos
modelo:          161 minutos · Optimal
con dos reglas:  196 minutos · Optimal · Suba: ['esp-03', 'esp-05'] · Soacha: ['esp-07']
```

El voraz recorre las sedes en orden y le da a cada una su especialista más cercano libre: 176 minutos de desplazamiento. El modelo
encuentra un reparto de 161, un 9 % menos, y lo declara `Optimal`: no hay uno mejor. El voraz perdió porque las primeras sedes se
llevaron especialistas que a las últimas les habrían servido más, que es exactamente lo que un algoritmo voraz no puede ver. Y las dos
reglas nuevas —Suba necesita dos, esp-03 no va a Soacha— fueron dos líneas: el modelo encontró el nuevo óptimo sin cambiar nada más.
""")
p.write_text(t)
EOF
cd ../../zz-code/python-for-java-devs-20261005-f516 && python3 probado.py op096-so01-describir-en-vez-de-programar.md && python3 plan.py 96 96 ✅ ✅ && cd - >/dev/null && python3 ../../zz-code/python-for-java-devs-20261005-f516/verificar_urls.py op096-so01-describir-en-vez-de-programar.md | tail -3 && python3 prompts/verificar-corpus.py | tail -1

# --- 2026-10-05T19:12:07 · Smoke-test so02 LP and MIP
cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516 && python3 humo.py op097-so02-programacion-lineal.md so02 'mezcla_suba.py=@mezcla_suba.py' --pip PuLP==4.0.0 highspy==1.15.1 --cmd 'python mezcla_suba.py' 2>&1 | tail -8

# --- 2026-10-05T19:12:32 · Probe constraint API and fractional data
cat > salidas/so02/sonda.py <<'EOF'
import pulp, inspect
import mezcla_suba as m
for rehab in (450, 500, 630):
    m.REHAB_MINUTES = rehab
    prob, mix, st = m.solve(False)
    cs = prob.constraints()
    print(rehab, {p: round(v, 3) for p, v in mix.items()}, st.objective, type(cs).__name__)
c = list(prob.constraints().items())[0][1] if hasattr(prob.constraints(), "items") else prob.constraints()[0]
print(type(c).__name__, [n for n in dir(c) if not n.startswith("_")])
EOF
sed -i '' 's/^prob, mix, stats = solve(integer=False)$/if __name__ == "__main__":\n  prob, mix, stats = solve(integer=False)/' salidas/so02/mezcla_suba.py; python3 - <<'EOF'
import pathlib
p=pathlib.Path("salidas/so02/mezcla_suba.py"); t=p.read_text()
head, tail = t.split('if __name__ == "__main__":\n',1)
tail = "\n".join(("    "+l.lstrip() if l.strip() else l) for l in tail.splitlines())
p.write_text(head+'if __name__ == "__main__":\n'+tail+"\n")
EOF
docker run --rm --label curso=python-for-java-devs -v "$PWD/salidas/so02:/w" -w /w python:3.14.7 sh -c 'pip install -q --root-user-action=ignore PuLP==4.0.0 highspy==1.15.1 >/dev/null 2>&1; python sonda.py' 2>&1 | tail -6

# --- 2026-10-05T19:12:52 · Probe constraint API with standalone script
rm salidas/so02/mezcla_suba.py && cat > salidas/so02/sonda.py <<'EOF'
import pulp
PROCS = {"control": (30, 0, 80_000, 120), "limpieza": (40, 0, 60_000, 60),
         "blanqueamiento": (60, 30, 250_000, 12), "carilla": (120, 120, 900_000, 6)}
def solve(chair, rehab, integer):
    prob = pulp.LpProblem("m", pulp.LpMaximize)
    n = prob.add_variable_dicts("n", list(PROCS), lowBound=0, cat="Integer" if integer else "Continuous")
    prob += pulp.lpSum(PROCS[p][2] * n[p] for p in PROCS)
    prob += pulp.lpSum(PROCS[p][0] * n[p] for p in PROCS) <= chair, "silla"
    prob += pulp.lpSum(PROCS[p][1] * n[p] for p in PROCS) <= rehab, "rehabilitador"
    for p in PROCS:
        prob += n[p] <= PROCS[p][3], f"demanda_{p}"
    st = prob.solve(pulp.HiGHS(msg=False))
    return prob, {p: n[p].value() for p in PROCS}, st
for rehab in (450, 500, 630):
    prob, mix, st = solve(6480, rehab, False)
    print(rehab, {p: round(v, 3) for p, v in mix.items()}, st.objective)
cs = prob.constraints()
print(type(cs).__name__)
c = list(cs.values())[0] if hasattr(cs, "values") else cs[0]
print(type(c).__name__, [n for n in dir(c) if not n.startswith("_")])
EOF
docker run --rm --label curso=python-for-java-devs -v "$PWD/salidas/so02:/w" -w /w python:3.14.7 sh -c 'pip install -q --root-user-action=ignore PuLP==4.0.0 highspy==1.15.1 >/dev/null 2>&1; python sonda.py' 2>&1 | tail -6

# --- 2026-10-05T19:13:22 · Move example to Chapinero, fix API, rerun
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs && python3 - <<'EOF'
import pathlib
p=pathlib.Path("op097-so02-programacion-lineal.md");t=p.read_text()
def rep(a,b,n=1):
    global t
    assert t.count(a)==n,(a,t.count(a))
    t=t.replace(a,b)
rep("""Suba tiene dos unidades odontológicas (las sillas) y un rehabilitador que va dos tardes por semana. Cada semana, la agenda
mezcla controles de ortodoncia, limpiezas, blanqueamientos y carillas, que ocupan la silla tiempos distintos y dejan márgenes
muy distintos. Édgar Rojas quiere saber qué mezcla le conviene, y la pregunta que de verdad le importa viene después: **¿cuánto
ganaría con una silla más, o con una tarde más del rehabilitador?**""","""Chapinero, sede propia, tiene dos unidades odontológicas (las sillas) y un rehabilitador del Centro que va tres tardes por
semana. Cada semana, la agenda mezcla controles de ortodoncia, limpiezas, blanqueamientos y carillas, que ocupan la silla tiempos
distintos y dejan márgenes muy distintos. Julián quiere saber qué mezcla conviene, y la pregunta que de verdad le importa viene
después: **¿cuánto se ganaría con una silla más, o con una tarde más del rehabilitador?**""")
rep('"""La mezcla semanal de Suba: lineal (con precios sombra) y entera (la que se agenda)."""','"""La mezcla semanal de Chapinero: lineal (con precios sombra) y entera (la que se agenda)."""')
rep("`mezcla_suba.py`:","`mezcla_chapinero.py`:")
rep("python3 mezcla_suba.py","python3 mezcla_chapinero.py")
rep('REHAB_MINUTES = 2 * 4 * 60              # dos tardes de cuatro horas','REHAB_MINUTES = 3 * 210                 # tres tardes de tres horas y media')
rep('    prob = pulp.LpProblem("mezcla_suba", pulp.LpMaximize)','    prob = pulp.LpProblem("mezcla_chapinero", pulp.LpMaximize)')
rep('''for name, c in prob.constraints.items():
    if c.pi:
        print(f"  precio sombra de {name}: ${c.pi:,.0f} por unidad")''','''for c in prob.constraints():                     # PuLP 4: un método que devuelve la lista
    if c.pi:
        print(f"  precio sombra de {c.name}: ${c.pi:,.0f} por unidad")''')
rep("""- **Las restricciones llevan nombre**""","""- **`prob.constraints()` es un método en PuLP 4** (en la 3 era un diccionario, `prob.constraints.items()`): otro cambio de la reescritura
  que encontró la primera corrida.
- **Las restricciones llevan nombre**""")
rep("10. Prepara para Édgar la respuesta a \"¿me conviene una tercera silla?\".","10. Prepara para Julián la respuesta a \"¿nos conviene una tercera silla en Chapinero?\".")
rep("""**La señal de que quedó bien:** *"Édgar preguntó si le convenía otra silla, y la respuesta llegó con el número y con el rango en que ese
número vale."*""","""**La señal de que quedó bien:** *"Julián preguntó si convenía otra silla en Chapinero, y la respuesta llegó con el número y con el rango en
que ese número vale."*""")
rep('git tag -a op-so-fase-02 -m "op so02 cerrada: la mezcla de Suba, lineal con precios sombra y entera"','git tag -a op-so-fase-02 -m "op so02 cerrada: la mezcla de Chapinero, lineal con precios sombra y entera"')
p.write_text(t)
EOF
grep -n "Suba\|Édgar" op097-so02-programacion-lineal.md; cd ../../zz-code/python-for-java-devs-20261005-f516 && rm -f salidas/so02/sonda.py && python3 humo.py op097-so02-programacion-lineal.md so02 'mezcla_chapinero.py=@mezcla_chapinero.py' --pip PuLP==4.0.0 highspy==1.15.1 --cmd 'python mezcla_chapinero.py' 2>&1 | tail -8

# --- 2026-10-05T19:13:49 · Fill so02 output with dual interpretation, mark
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs && python3 - <<'EOF'
import pathlib
p=pathlib.Path("op097-so02-programacion-lineal.md");t=p.read_text()
def rep(a,b):
    global t
    assert t.count(a)==1,a
    t=t.replace(a,b)
rep("rapidísimo y además responde la pregunta de Édgar con los **precios sombra**","rapidísimo y además responde la pregunta de Julián con los **precios sombra**")
rep("""sombra de los minutos de silla es $1.200, un minuto más de silla vale $1.200 de margen; una silla nueva, que agrega 3 240 minutos por
semana, vale unos $3,9 millones semanales mientras ese precio se mantenga.""","""sombra de los minutos de silla es $1.500, un minuto más de silla vale $1.500 de margen, **mientras ese precio se mantenga** —y el ejemplo
muestra que puede mantenerse muy poco—.""")
rep("""lineal: {…} · margen $…
  precio sombra de …: $… por unidad
entera: {…} · margen $…
```
""","""lineal: {'control': 120.0, 'limpieza': 56.25, 'blanqueamiento': 0.0, 'carilla': 5.25} · margen $17,700,000
  precio sombra de silla: $-1,500 por unidad
  precio sombra de rehabilitador: $-6,000 por unidad
  precio sombra de demanda_control: $-35,000 por unidad
entera: {'control': 120, 'limpieza': 55, 'blanqueamiento': 1, 'carilla': 5} · margen $17,650,000
```

La versión lineal agenda 56,25 limpiezas y 5,25 carillas: el óptimo de un mundo con cuartos de carilla. La entera agenda 55 y 5, más un
blanqueamiento que usa los minutos sobrantes del rehabilitador, y deja $50.000 menos de margen: es el precio de que las carillas vengan
enteras. Los precios sombra responden la pregunta de Julián, con dos lecturas que hay que hacer con cuidado. La primera: **el signo es la
convención de HiGHS** para un problema de maximización con restricciones `<=`; lo que importa es la magnitud. Un minuto de silla vale $1.500
—el margen por minuto de la limpieza, que es el procedimiento que absorbería el minuto extra—, un minuto del rehabilitador vale $6.000, y
un control más de demanda, $35.000. La segunda: esos valores valen **en un rango**. La limpieza está a 3,75 de su tope de demanda (60), así
que el precio de $1.500 por minuto de silla dura unos 150 minutos; una tercera silla, con 3 240 minutos, no vale 3 240 × $1.500. Para
saberlo, se vuelve a resolver con tres sillas (ejercicio 2).
""")
p.write_text(t)
EOF
cd ../../zz-code/python-for-java-devs-20261005-f516 && python3 probado.py op097-so02-programacion-lineal.md && python3 plan.py 97 97 ✅ ✅ && cd - >/dev/null && python3 ../../zz-code/python-for-java-devs-20261005-f516/verificar_urls.py op097-so02-programacion-lineal.md | tail -3 && python3 prompts/verificar-corpus.py | tail -1

# --- 2026-10-05T19:14:05 · Remove franchises from so01 and rerun
python3 - <<'EOF'
import pathlib
p=pathlib.Path("op096-so01-describir-en-vez-de-programar.md");t=p.read_text()
def rep(a,b):
    global t
    assert t.count(a)==1,a
    t=t.replace(a,b)
rep('SEDES = ["Chapinero", "Suba", "Kennedy", "Usaquén", "Engativá", "Fontibón", "Restrepo", "Soacha", "Zipaquirá"]\nSPECIALISTS = [f"esp-{i:02d}" for i in range(1, 13)]',
    'SEDES = ["Chapinero", "Kennedy", "Usaquén", "Engativá", "Fontibón", "Restrepo", "Soacha"]   # sedes propias; las franquicias tienen su personal\nSPECIALISTS = [f"esp-{i:02d}" for i in range(1, 11)]')
rep('(2 if extra_rules and s == "Suba" else 1)','(2 if extra_rules and s == "Kennedy" else 1)')
rep('print("con dos reglas: ", int(total2), "minutos ·", status2, "· Suba:", plan2["Suba"], "· Soacha:", plan2["Soacha"])','print("con dos reglas: ", int(total2), "minutos ·", status2, "· Kennedy:", plan2["Kennedy"], "· Soacha:", plan2["Soacha"])')
rep("108 variables","70 variables")
p.write_text(t)
EOF
grep -n "Suba" op096-so01-describir-en-vez-de-programar.md; cd ../../zz-code/python-for-java-devs-20261005-f516 && python3 humo.py op096-so01-describir-en-vez-de-programar.md so01 'reparto_sabado.py=@reparto_sabado.py' --pip PuLP==4.0.0 highspy==1.15.1 --cmd 'python reparto_sabado.py' 2>&1 | tail -4

# --- 2026-10-05T19:14:21 · Get full so01 output after change
python3 humo.py op096-so01-describir-en-vez-de-programar.md so01 'reparto_sabado.py=@reparto_sabado.py' --pip PuLP==4.0.0 highspy==1.15.1 --cmd 'python reparto_sabado.py' 2>/dev/null | grep -v "^$"

# --- 2026-10-05T19:14:36 · Scan seeds for greedy vs optimal gap
cat > salidas/so01/semillas.py <<'EOF'
import random, re, pathlib
src = pathlib.Path("reparto_sabado.py").read_text()
body = src.split("g = greedy()")[0]
for seed in range(1, 21):
    ns = {}
    exec(body.replace("random.seed(4)", f"random.seed({seed})"), ns)
    g = ns["greedy"](); gm = sum(ns["minutes"][e, s] for s, e in g.items())
    _, opt, _ = ns["model"]()
    print(seed, gm, int(opt), f"{(gm/opt-1)*100:.0f}%")
EOF
docker run --rm --label curso=python-for-java-devs -v "$PWD/salidas/so01:/w" -w /w python:3.14.7 sh -c 'pip install -q --root-user-action=ignore PuLP==4.0.0 highspy==1.15.1 >/dev/null 2>&1; python semillas.py' 2>&1 | tail -20 | tr '\n' ' '

# --- 2026-10-05T19:14:53 · Switch to seed 10 and rerun so01
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs && sed -i '' 's/^random.seed(4)$/random.seed(10)/' op096-so01-describir-en-vez-de-programar.md && cd ../../zz-code/python-for-java-devs-20261005-f516 && rm salidas/so01/semillas.py && python3 humo.py op096-so01-describir-en-vez-de-programar.md so01 'reparto_sabado.py=@reparto_sabado.py' --pip PuLP==4.0.0 highspy==1.15.1 --cmd 'python reparto_sabado.py' 2>/dev/null | grep -v "^$"

# --- 2026-10-05T19:15:11 · Update so01 output and seed statistics
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs && python3 - <<'EOF'
import pathlib
p=pathlib.Path("op096-so01-describir-en-vez-de-programar.md");t=p.read_text()
def rep(a,b):
    global t
    assert t.count(a)==1,a
    t=t.replace(a,b)
rep("""voraz:           176 minutos
modelo:          161 minutos · Optimal
con dos reglas:  196 minutos · Optimal · Suba: ['esp-03', 'esp-05'] · Soacha: ['esp-07']""","""voraz:           147 minutos
modelo:          134 minutos · Optimal
con dos reglas:  157 minutos · Optimal · Kennedy: ['esp-01', 'esp-03'] · Soacha: ['esp-06']""")
rep("""El voraz recorre las sedes en orden y le da a cada una su especialista más cercano libre: 176 minutos de desplazamiento. El modelo
encuentra un reparto de 161, un 9 % menos, y lo declara `Optimal`: no hay uno mejor.""","""El voraz recorre las sedes en orden y le da a cada una su especialista más cercano libre: 147 minutos de desplazamiento. El modelo
encuentra un reparto de 134, un 10 % menos, y lo declara `Optimal`: no hay uno mejor. No es un caso elegido para que el voraz pierda:
con veinte semillas distintas, el voraz empató con el óptimo en seis y perdió en catorce, por entre 2 % y 61 %, con una mediana cercana
al 12 %. Lo que el voraz no puede hacer en ningún caso es decir en cuál de los veinte está.""")
rep("""reglas nuevas —Suba necesita dos, esp-03 no va a Soacha— fueron dos líneas""","""reglas nuevas —Kennedy necesita dos, esp-03 no va a Soacha— fueron dos líneas""")
p.write_text(t)
EOF
grep -n "Suba" op096-so01-describir-en-vez-de-programar.md; python3 prompts/verificar-corpus.py | tail -1

# --- 2026-10-05T19:16:25 · Fix names and feasibility, smoke-test CP-SAT
python3 - <<'EOF'
import pathlib
p=pathlib.Path("op098-so03-or-tools.md");t=p.read_text()
def rep(a,b,n=1):
    global t
    assert t.count(a)==n,(a,t.count(a))
    t=t.replace(a,b)
rep('''STAFF = {"Yuli": "Centro", "Andrea": "Centro", "Paola": "Chapinero", "Leidy": "Chapinero",
         "Marisol": "Kennedy", "Daniela": "Kennedy", "Johana": "Usaquén", "Carolina": "Usaquén"}''','''STAFF = {"Yuli": "Centro", "rec-02": "Centro", "rec-03": "Chapinero", "rec-04": "Chapinero", "rec-05": "Kennedy",
         "rec-06": "Kennedy", "rec-07": "Usaquén", "rec-08": "Usaquén", "rec-09": "Centro"}''')
rep('    m.add(sum(work[p, s, d, t] for s in SEDES for d in DAYS for t in SHIFTS) <= 10)      # tope semanal','    m.add(sum(work[p, s, d, t] for s in SEDES for d in DAYS for t in SHIFTS) <= 6)       # tope semanal')
rep('for s in SEDES:                                          # Paola no cierra los viernes\n    m.add(work["Paola", s, "vie", "tarde"] == 0)','for s in SEDES:                                          # rec-03 no cierra los viernes\n    m.add(work["rec-03", s, "vie", "tarde"] == 0)')
rep('most, least = m.new_int_var(0, 10, "most"), m.new_int_var(0, 10, "least")','most, least = m.new_int_var(0, 6, "most"), m.new_int_var(0, 6, "least")')
rep("""Los turnos de recepción son el problema que más tiempo le quita a Patricia cada mes. Cuatro sedes propias con recepción mañana y
tarde, de lunes a sábado; ocho recepcionistas, cada una con su tope de turnos, su día de descanso, y preferencias que se han
negociado durante años: Yuli Chaparro no trabaja sábados porque estudia, otra no puede cerrar los viernes, nadie hace mañana y
tarde el mismo día.""","""Los turnos de recepción son el problema que más tiempo le quita a Patricia cada mes. Cuatro sedes propias con recepción mañana y
tarde, de lunes a sábado; nueve recepcionistas, cada una con su tope de turnos, su sede habitual, y reglas que se han negociado
durante años: Yuli Chaparro no trabaja sábados, otra no puede cerrar los viernes, nadie hace mañana y tarde el mismo día.""")
rep("| Tope (dura) | Nadie hace más de 10 turnos por semana | `sum(...) <= 10` |","| Tope (dura) | Nadie hace más de 6 turnos por semana | `sum(...) <= 6` |")
rep("Con ocho personas, cuatro sedes y doce turnos por\ndía-sede de la semana, las asignaciones posibles son del orden de 8⁴⁸","Con nueve personas y 48 turnos en la semana (cuatro\nsedes, seis días, mañana y tarde), las asignaciones posibles son del orden de 9⁴⁸")
rep("(persona, sede, día, turno): 384 variables booleanas","(persona, sede, día, turno): 432 variables booleanas")
rep("1. Corre el ejemplo. **Criterio:** verificas a mano que Yuli no trabaja el sábado y que Paola no cierra el viernes.","1. Corre el ejemplo. **Criterio:** verificas a mano que Yuli no trabaja el sábado y que rec-03 no cierra el viernes.")
rep("2. Baja el tope semanal a 5 turnos. **Criterio:** el estado que devuelve y por qué.","2. Baja el tope semanal a 5 turnos. **Criterio:** el estado que devuelve, y la cuenta que lo explica (nueve personas, 48 turnos).")
p.write_text(t)
EOF
grep -n "Paola\|Andrea\|ocho" op098-so03-or-tools.md; grep -m1 "| \`ortools\`" prompts/inventario-verificado.md; cd ../../zz-code/python-for-java-devs-20261005-f516 && python3 humo.py op098-so03-or-tools.md so03 'turnos.py=@turnos.py' --pip ortools==9.15.6755 --cmd 'python turnos.py' 2>&1 | tail -7

# --- 2026-10-05T19:16:51 · Show short codes in schedule and rerun
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs && python3 - <<'EOF'
import pathlib
p=pathlib.Path("op098-so03-or-tools.md");t=p.read_text()
a='''    row = [next(p for p in STAFF if solver.value(work[p, s, d, t]))[:3] for d in DAYS for t in SHIFTS]
    print(f"  {s:<10}", " ".join(row))'''
assert t.count(a)==1
t=t.replace(a,'''    row = [next(p for p in STAFF if solver.value(work[p, s, d, t])) for d in DAYS for t in SHIFTS]
    print(f"  {s:<10}", " ".join("Yu" if p == "Yuli" else p[-2:] for p in row))''')
p.write_text(t)
EOF
cd ../../zz-code/python-for-java-devs-20261005-f516 && python3 humo.py op098-so03-or-tools.md so03 'turnos.py=@turnos.py' --pip ortools==9.15.6755 --cmd 'python turnos.py' 2>/dev/null | grep -v "^$"

# --- 2026-10-05T19:17:14 · Fill so03 output, mark, verify
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs && python3 - <<'EOF'
import pathlib,re
p=pathlib.Path("op098-so03-or-tools.md");t=p.read_text()
old=re.search(r"```text\nOPTIMAL en … s.*?\n```\n",t,re.S).group(0)
t=t.replace(old,"""```text
OPTIMAL en 0.03 s · fuera de su sede: 0 turnos · carga entre 4 y 6
  Centro     09 02 Yu 02 Yu 09 Yu 02 Yu 09 02 09
  Chapinero  04 03 03 04 04 03 04 03 03 04 03 04
  Kennedy    06 05 05 06 06 05 06 05 06 05 06 05
  Usaquén    08 07 07 08 07 08 08 07 08 07 08 07
```

Las columnas son lunes mañana, lunes tarde, y así hasta el sábado tarde. En 0,03 segundos, CP-SAT encontró un horario y **demostró**
que es óptimo: nadie trabaja fuera de su sede, Yuli (`Yu`) hace cuatro mañanas y ningún sábado, y rec-03 no cierra el viernes (la
décima columna de Chapinero es de rec-04). La carga va de 4 a 6 turnos, y no es un descuido de la equidad: es su precio. Con la sede
habitual pesando diez veces más, el Centro reparte sus doce turnos entre tres personas (4 cada una) y las otras sedes entre dos (6
cada una); igualar las cargas exigiría mandar gente del Centro a otras sedes. Si Patricia prefiere la equidad, cambia un peso, no el
programa.
""")
p.write_text(t)
EOF
cd ../../zz-code/python-for-java-devs-20261005-f516 && python3 probado.py op098-so03-or-tools.md && python3 plan.py 98 98 ✅ ✅ && cd - >/dev/null && python3 ../../zz-code/python-for-java-devs-20261005-f516/verificar_urls.py op098-so03-or-tools.md | tail -3 && python3 prompts/verificar-corpus.py | tail -1

# --- 2026-10-05T19:18:20 · Restructure so04 loop and smoke-test
python3 - <<'EOF'
import pathlib
p=pathlib.Path("op099-so04-rutas-y-grafos.md");t=p.read_text()
a='''methods = {
    "vecino más cercano": lambda: approx.greedy_tsp(G, source="Laboratorio"),
    "Christofides": lambda: approx.traveling_salesman_problem(G, cycle=True, method=approx.christofides),
    "recocido simulado": lambda: approx.simulated_annealing_tsp(G, "greedy", source="Laboratorio", seed=7),
    "óptimo (fuerza bruta)": exact,
}
best = None
for name, solve in methods.items():
    start = time.perf_counter()
    tour = solve()
    took = time.perf_counter() - start
    km = length(tour)
    best = km if name.startswith("óptimo") else best
    print(f"{name:<22} {km:6.1f} km  en {took * 1000:8.1f} ms")
print("ruta óptima:", " → ".join(exact()))'''
assert t.count(a)==1
t=t.replace(a,'''start = time.perf_counter()
optimal = exact()
print(f"{'óptimo (fuerza bruta)':<22} {length(optimal):6.1f} km  en {(time.perf_counter() - start) * 1000:8.1f} ms")

methods = {
    "vecino más cercano": lambda: approx.greedy_tsp(G, source="Laboratorio"),
    "Christofides": lambda: approx.traveling_salesman_problem(G, cycle=True, method=approx.christofides),
    "recocido simulado": lambda: approx.simulated_annealing_tsp(G, "greedy", source="Laboratorio", seed=7),
}
for name, solve in methods.items():
    start = time.perf_counter()
    km = length(solve())
    took = time.perf_counter() - start
    print(f"{name:<22} {km:6.1f} km  en {took * 1000:8.1f} ms  ({km / length(optimal) - 1:+.0%} sobre el óptimo)")
print("ruta óptima:", " → ".join(optimal))''')
p.write_text(t)
EOF
cd ../../zz-code/python-for-java-devs-20261005-f516 && python3 humo.py op099-so04-rutas-y-grafos.md so04 'mensajero.py=@mensajero.py' --pip networkx==3.7 --cmd 'python mensajero.py' 2>&1 | tail -6

# --- 2026-10-05T19:18:29 · Get optimum line of so04 output
python3 humo.py op099-so04-rutas-y-grafos.md so04 'mensajero.py=@mensajero.py' --pip networkx==3.7 --cmd 'python mensajero.py' 2>/dev/null | head -1

# --- 2026-10-05T19:18:47 · Fill so04 output, mark, verify
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs && python3 - <<'EOF'
import pathlib,re
p=pathlib.Path("op099-so04-rutas-y-grafos.md");t=p.read_text()
old=re.search(r"```text\nvecino más cercano       … km.*?\n```\n",t,re.S).group(0)
t=t.replace(old,"""```text
óptimo (fuerza bruta)    65.4 km  en    948.1 ms
vecino más cercano       75.3 km  en      0.6 ms  (+15% sobre el óptimo)
Christofides             76.5 km  en      2.9 ms  (+17% sobre el óptimo)
recocido simulado        75.3 km  en      4.3 ms  (+15% sobre el óptimo)
ruta óptima: Laboratorio → Centro → Restrepo → Soacha → Kennedy → Fontibón → Engativá → Suba → Usaquén → Chapinero → Laboratorio
```

La ruta óptima mide 65,4 km y la del vecino más cercano 75,3: diez kilómetros de más cada día, unos tres mil al año. Dos resultados
merecen leerse con cuidado. Christofides quedó **peor** que el voraz: su garantía (a lo sumo 1,5 veces el óptimo) es para el peor caso,
no una promesa de ganarle a una heurística simple en cada instancia. Y el recocido simulado, que arranca desde la solución voraz, terminó
exactamente donde empezó: con sus parámetros por defecto no encontró por dónde mejorar. La fuerza bruta tardó casi un segundo con nueve
sedes; con doce tardaría horas.
""")
t=t.replace("Salida esperada, sin correr (los milisegundos son de la máquina que corre):","Salida esperada, sin correr (los milisegundos son de la máquina que corre; estos, de un contenedor en un portátil):")
p.write_text(t)
EOF
cd ../../zz-code/python-for-java-devs-20261005-f516 && python3 probado.py op099-so04-rutas-y-grafos.md && python3 plan.py 99 99 ✅ ✅ && cd - >/dev/null && python3 ../../zz-code/python-for-java-devs-20261005-f516/verificar_urls.py op099-so04-rutas-y-grafos.md | tail -3 && python3 prompts/verificar-corpus.py | tail -1

# --- 2026-10-05T19:18:56 · Correct brute-force and greedy claims
python3 - <<'EOF'
import pathlib
p=pathlib.Path("op099-so04-rutas-y-grafos.md");t=p.read_text()
def rep(a,b):
    global t
    assert t.count(a)==1,a
    t=t.replace(a,b)
rep("La fuerza bruta tardó casi un segundo con nueve\nsedes; con doce tardaría horas.","La fuerza bruta tardó casi un segundo con nueve\nsedes; con doce, a ese ritmo, unos veinte minutos, y con trece, horas.")
rep("| Vecino más cercano (voraz) | Ninguna; suele quedar 20–25 % arriba | Muy barato | `greedy_tsp` |","| Vecino más cercano (voraz) | Ninguna; en el ejemplo, 15 % arriba | Muy barato | `greedy_tsp` |")
p.write_text(t)
EOF
python3 prompts/verificar-corpus.py | tail -1

# --- 2026-10-05T19:19:55 · Simplify care time and run SimPy model
python3 - <<'EOF'
import pathlib
p=pathlib.Path("op100-so05-simulacion-con-simpy.md");t=p.read_text()
def rep(a,b):
    global t
    assert t.count(a)==1,a
    t=t.replace(a,b)
rep("CARE_MEAN = 11.0            # atención en la silla (controles y limpiezas)\n","")
rep("        yield env.timeout(random.lognormvariate(2.3, 0.4) * CARE_MEAN / 10.9)","        yield env.timeout(random.lognormvariate(2.3, 0.4))      # atención en la silla: media ≈ 10,8 min")
p.write_text(t)
EOF
cd ../../zz-code/python-for-java-devs-20261005-f516 && python3 humo.py op100-so05-simulacion-con-simpy.md so05 'sala_de_espera.py=@sala_de_espera.py' --pip simpy==4.1.2 --cmd 'python sala_de_espera.py' 2>&1 | tail -4

# --- 2026-10-05T19:20:04 · Get all three SimPy scenario lines
python3 humo.py op100-so05-simulacion-con-simpy.md so05 'sala_de_espera.py=@sala_de_espera.py' --pip simpy==4.1.2 --cmd 'python sala_de_espera.py' 2>/dev/null | grep recepción

# --- 2026-10-05T19:20:19 · Fill SimPy output, mark so05, verify
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs && python3 - <<'EOF'
import pathlib,re
p=pathlib.Path("op100-so05-simulacion-con-simpy.md");t=p.read_text()
old=re.search(r"```text\n1 recepción, 2 sillas · espera en recepción: media … min.*?\n```\n",t,re.S).group(0)
t=t.replace(old,"""```text
1 recepción, 2 sillas · espera en recepción: media  28.1 min, p90  70.0 · espera por silla: media   7.9, p90  22.5
1 recepción, 3 sillas · espera en recepción: media  27.7 min, p90  69.7 · espera por silla: media   1.1, p90   4.3
2 recepción, 2 sillas · espera en recepción: media   1.5 min, p90   5.7 · espera por silla: media  10.6, p90  28.5
```

Quinientos sábados por escenario, y la respuesta contradice a todos. Hoy, un paciente espera en promedio 28 minutos en el mostrador y 8
por una silla: 36 en total, y uno de cada diez espera más de una hora solo para registrarse. La tercera silla deja la espera por silla
casi en cero y **no toca la del mostrador**: el total baja de 36 a 29 minutos. La segunda recepcionista baja el mostrador a minuto y
medio, y el total a 12, aunque la espera por silla **suba** un poco: los pacientes llegan antes a las sillas, y ahí se forma ahora la fila
que antes se formaba adelante. El cuello de botella estaba en el mostrador, con una ocupación cercana al 92 %, y un recurso tan cargado
genera colas desproporcionadas.
""")
p.write_text(t)
EOF
cd ../../zz-code/python-for-java-devs-20261005-f516 && python3 probado.py op100-so05-simulacion-con-simpy.md && python3 plan.py 100 100 ✅ ✅ && cd - >/dev/null && python3 ../../zz-code/python-for-java-devs-20261005-f516/verificar_urls.py op100-so05-simulacion-con-simpy.md | tail -3 && python3 prompts/verificar-corpus.py | tail -1

# --- 2026-10-05T19:20:26 · Mark utilisation figure as theoretical
sed -i '' 's/El cuello de botella estaba en el mostrador, con una ocupación cercana al 92 %, y un recurso tan cargado/El cuello de botella estaba en el mostrador, con una ocupación teórica de 6 \/ 6,5 ≈ 92 % (registro medio sobre llegada media), y un recurso tan cargado/' op100-so05-simulacion-con-simpy.md && grep -c "ocupación teórica" op100-so05-simulacion-con-simpy.md

# --- 2026-10-05T19:21:21 · Fix ds08 reference and run black-box search
sed -i '' 's/con la historia de citas (`ds08` del camino base) dice/con la historia de citas (`ds08`) dice/' op101-so06-cuando-no-hay-modelo.md && grep -c "(\`ds08\`) dice" op101-so06-cuando-no-hay-modelo.md && cd ../../zz-code/python-for-java-devs-20261005-f516 && python3 humo.py op101-so06-cuando-no-hay-modelo.md so06 'recordatorios.py=@recordatorios.py' --pip scipy==1.18.1 optuna==5.0.0 numpy==2.5.3 --cmd 'python recordatorios.py' 2>&1 | tail -6

# --- 2026-10-05T19:21:53 · Fill so06 output honestly, mark, verify
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs && python3 - <<'EOF'
import pathlib,re
p=pathlib.Path("op101-so06-cuando-no-hay-modelo.md");t=p.read_text()
def rep(a,b):
    global t
    assert t.count(a)==1,a
    t=t.replace(a,b)
old=re.search(r"```text\nrejilla \(72 × 12\)        primero … h.*?\n```\n",t,re.S).group(0)
t=t.replace(old,"""```text
rejilla (72 × 12)        primero  29.0 h · segundo  3.0 h · ausentismo  9.28% ·  864 evaluaciones
evolución diferencial    primero  30.6 h · segundo  3.0 h · ausentismo  9.17% ·  630 evaluaciones
Optuna (TPE)             primero  30.8 h · segundo  1.3 h · ausentismo 11.12% ·   60 evaluaciones
lo que se hace hoy       primero  48.0 h · segundo 24.0 h · ausentismo 18.51% ·    0 evaluaciones
```

Los tres métodos mejoran mucho lo que se hace hoy (18,5 % de ausentismo), y no por igual. La rejilla, con 864 evaluaciones, encuentra 29 y
3 horas: 9,3 %. La evolución diferencial, con 630, llega un poco más abajo (9,2 %) porque busca en valores continuos, no solo en horas
enteras. Optuna, con 60, encontró bien el primer recordatorio y se quedó corta en el segundo: 11,1 %. Es la cuenta honesta del método:
**con un 7 % de las evaluaciones recorrió la mayor parte del camino**, no todo. Si cada evaluación tarda un minuto, 60 son una hora y 864
son catorce; con ese presupuesto, se corre Optuna con más intentos (ejercicio 2) antes que la rejilla.
""")
rep("""- **Optuna** propone el siguiente punto según lo que vio antes (TPE); con 60 evaluaciones se acerca a lo que la rejilla encuentra con 864.
  Cuando cada evaluación es una simulación de un minuto, esa diferencia es de horas.""","""- **Optuna** propone el siguiente punto según lo que vio antes (TPE): no recorre el espacio parejo, se concentra donde los resultados fueron
  buenos. Con ruido, a veces se concentra en un punto que tuvo suerte; por eso también se reevalúa.""")
rep("""**La señal de que quedó bien:** *"La política nueva de recordatorios salió del simulador con 60 evaluaciones, y la prueba en Kennedy confirmó la
mejora."*""","""**La señal de que quedó bien:** *"La política nueva de recordatorios salió del simulador con un presupuesto de evaluaciones decidido de
antemano, y la prueba en Kennedy confirmó la mejora."*""")
p.write_text(t)
EOF
cd ../../zz-code/python-for-java-devs-20261005-f516 && python3 probado.py op101-so06-cuando-no-hay-modelo.md && python3 plan.py 101 101 ✅ ✅ && cd - >/dev/null && python3 ../../zz-code/python-for-java-devs-20261005-f516/verificar_urls.py op101-so06-cuando-no-hay-modelo.md | tail -3 && python3 prompts/verificar-corpus.py | tail -1

# --- 2026-10-05T19:22:41 · Smoke-test so07 calculator and URL
cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516 && python3 humo.py op102-so07-veredicto.md so07 'paga.py="""¿Paga el modelo?' --cmd 'python paga.py' 2>/dev/null | grep -v "^$"; cd ../../cursos-algoritmos-lenguajes/python-for-java-devs && python3 ../../zz-code/python-for-java-devs-20261005-f516/verificar_urls.py op102-so07-veredicto.md | tail -2

# --- 2026-10-05T19:22:58 · Fill so07 output and align closing line
python3 - <<'EOF'
import pathlib,re
p=pathlib.Path("op102-so07-veredicto.md");t=p.read_text()
def rep(a,b):
    global t
    assert t.count(a)==1,a
    t=t.replace(a,b)
old=re.search(r"```text\nso01 reparto del sábado \(10 % de desplazamiento\)       → ….*?\n```\n",t,re.S).group(0)
t=t.replace(old,"""```text
so01 reparto del sábado (10 % de desplazamiento)       → no, la hoja basta (vale 0.9 veces su costo)
so02 ¿una silla más? (decisión de una vez)             → no, la hoja basta (vale 0.0 veces su costo)
so03 turnos de recepción (4 h de Patricia al mes)      → no, la hoja basta (vale 0.9 veces su costo)
so04 ruta del mensajero (3 000 km al año)              → dudoso (vale 1.6 veces su costo)
so05 recepcionista en vez de silla (evita una compra)  → sí (vale 16.7 veces su costo)
so06 recordatorios (ausentismo a la mitad)             → no: nadie lo mantendría
```

El veredicto es más duro de lo que el entusiasmo del track sugería, y por eso hay que leerlo. Con la construcción cargada al primer año,
solo la simulación de la sala de espera se paga sola de lejos: cuesta unas treinta horas y evita una compra de sesenta millones. La ruta del
mensajero queda en duda. El reparto del sábado y los turnos quedan apenas por debajo de su costo (0,9): no porque no mejoren, sino porque
la mejora es chica frente a construir el modelo, y a tres años probablemente sí pagan (ejercicio 4). Y el caso más valioso de todos, los
recordatorios, se cae por la regla que más proyectos mata: sin alguien que mantenga el simulador, el modelo dura lo que dura su
calibración.
""")
rep("""**La señal de que quedó bien:** *"De los seis modelos del año, construimos tres, dejamos dos en la hoja, y uno espera a que alguien pueda
mantenerlo."*""","""**La señal de que quedó bien:** *"De los seis modelos del año, construimos el que se pagaba solo, dejamos tres en la hoja con su cuenta
escrita, uno quedó en prueba, y el más valioso espera a que alguien pueda mantenerlo."*""")
rep("La pregunta del veredicto es la que Julián haría","La pregunta del veredicto es la que Julián haría,")
p.write_text(t)
EOF
grep -n "Julián haría" op102-so07-veredicto.md | head -2

# --- 2026-10-05T19:23:06 · Fix punctuation, mark so07, refresh inventory
sed -i '' 's/la que Julián haría,: \*\*¿paga,/la que Julián haría: **¿paga,/' op102-so07-veredicto.md && grep -c "Julián haría: " op102-so07-veredicto.md && cd ../../zz-code/python-for-java-devs-20261005-f516 && python3 probado.py op102-so07-veredicto.md && python3 plan.py 102 102 ✅ ✅ && cd - >/dev/null && python3 prompts/verificar-corpus.py | tail -1 && python3 prompts/check-inventario.py so | tail -1 && for kv in ortools:9.15.6755 PuLP:4.0.0 highspy:1.15.1 simpy:4.1.2 scipy:1.18.1 networkx:3.7 optuna:5.0.0; do k=${kv%%:*}; v=${kv#*:}; grep -q "| \`$k\` | $v |" prompts/inventario-verificado.md || echo "CAMBIÓ $k"; done; echo revisado

# --- 2026-10-05T19:23:30 · Close T12 in plan, log entry, update memory
cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516 && python3 plan.py tanda T12 ✅ && python3 plan.py dondeesta "T1–T12 cerradas (102 de 176). Sigue T13 or (op103)." && cd ../../cursos-algoritmos-lenguajes/python-for-java-devs && n=$(for f in op09[6-9]*.md op10[0-2]*.md; do grep -o "Ejercicios ([0-9]*)" $f; done | grep -o "[0-9]*" | paste -sd+ - | bc) && echo "ejercicios=$n" && python3 - "$n" <<'EOF'
import pathlib,sys
p=pathlib.Path("prompts/plan-de-produccion-carta.md");t=p.read_text()
anchor="## 7. 📓 Bitácora\n\n"
entry=(f"**2026-10-05 · T12 (`so`) cerrada.** Escritas op096–op102 (7 secciones, {sys.argv[1]} ejercicios), **las siete probadas en "
"contenedor**. Dominio adaptado: la propuesta hablaba de terapeutas y visitas domiciliarias (de una versión anterior de la empresa); "
"se usaron especialistas, sillas, recepción y el mensajero del laboratorio dental. **Coherencia con la historia:** so01 mandaba "
"especialistas a las franquicias y so02 ponía carillas en Suba, que según la historia no tiene rehabilitador: los dos se corrigieron "
"(sedes propias; Chapinero). Las recepcionistas sin nombre en la historia van con código (`rec-02`…). **Hallazgos y defectos propios:** "
"**PuLP 4.0.0 (25/09/2026) reescribió su núcleo en Rust y rompió la API**: sin `LpVariable.dicts` (ahora `prob.add_variable_dicts`), "
"sin `pulp.LpStatus` (`solve()` devuelve `LpSolveStats`), `constraints` es un método; HiGHS da precios sombra negativos en "
"maximización (so01, so02); con ocho recepcionistas el problema era inviable por construcción, 47 turnos posibles para 48 (so03, "
"defecto propio); con 20 semillas el voraz empata con el óptimo en 6 y pierde hasta 61 % (so01); Christofides quedó peor que el voraz y "
"el recocido no mejoró (so04); la simulación mostró el cuello de botella en el mostrador, 36 → 12 min con una recepcionista contra 29 con "
"una silla (so05); Optuna con 60 evaluaciones llegó a 11,1 % y no al 9,3 % de la rejilla, y se corrigió el texto que decía que se "
"acercaba (so06); el veredicto con costos al primer año dejó solo un caso que paga solo (so07). **Inventario:** ninguna versión "
"probada cambió.\n\n")
t=t.replace(anchor,anchor+entry,1)
p.write_text(t)
EOF
M=/Users/oskar/.claude/projects/-Users-oskar-Developer-Learning-courses-ia-generated/memory; sed -i '' 's/T1–T11 (primer turno) cerradas el 05\/10\/2026: 95 de 176; sigue T12 so\./T1–T12 cerradas el 05\/10\/2026: 102 de 176; sigue T13 or./' $M/MEMORY.md && grep -c "102 de 176" $M/MEMORY.md

# --- 2026-10-05T19:23:36 · Read or track rows and proposal
grep -n "| op1[0-1][0-9] .*\`op1[0-9]*-or" prompts/plan-de-produccion-carta.md; n=$(grep -n "Track \`or\`" prompts/propuestas-temas-opcionales.md | head -1 | cut -d: -f1); sed -n "${n},$((n+32))p" prompts/propuestas-temas-opcionales.md; sed -n '/"or"/,/\],/p' prompts/check-inventario.py

# --- 2026-10-05T19:23:44 · Look up or track package versions
for k in SQLAlchemy Django peewee pony tortoise-orm piccolo sqlmodel ormar PyPika aiosql records dataset sqlglot yoyo-migrations alembic pugsql aiosqlite; do grep -m1 "| \`$k\` |" prompts/inventario-verificado.md || echo "falta $k"; done

# --- 2026-10-05T19:24:44 · Smoke-test or01 axis example
cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516 && python3 humo.py op103-or01-el-eje.md or01 'eje.py=@eje.py' --pip SQLAlchemy==2.1.3 PyPika==0.51.1 --cmd 'python eje.py' 2>&1 | tail -6; cd ../../cursos-algoritmos-lenguajes/python-for-java-devs && python3 ../../zz-code/python-for-java-devs-20261005-f516/verificar_urls.py op103-or01-el-eje.md | tail -2

# --- 2026-10-05T19:25:01 · Fill or01 output, mark, verify
python3 - <<'EOF'
import pathlib,re
p=pathlib.Path("op103-or01-el-eje.md");t=p.read_text()
old=re.search(r"```text\nSQL                     1 sentencias → \[…\].*?\n```\n",t,re.S).group(0)
t=t.replace(old,"""```text
SQL                     1 sentencias → [('PL-033', 6350000), ('PL-024', 5400000), ('PL-051', 4750000)]
PyPika genera: SELECT "plan"."codigo",SUM("fase"."valor") "saldo" FROM "plan" JOIN "fase" ON "fase"."plan_id"= …
SQLAlchemy Core         1 sentencias → [('PL-033', 6350000), ('PL-024', 5400000), ('PL-051', 4750000)]
ORM, navegando         21 sentencias → [('PL-033', 6350000), ('PL-024', 5400000), ('PL-051', 4750000)]
```

Los tres puntos del eje dan la misma respuesta. El SQL y el constructor mandan una sentencia y traen tres filas. El ORM, navegando, manda
**veintiuna**: una para los veinte planes de Suba y una por cada plan para traer sus fases. Es el N+1, y no hay nada en el código del ORM que
lo delate: `pl.fases` parece un atributo y es una consulta.
""")
p.write_text(t)
EOF
cd ../../zz-code/python-for-java-devs-20261005-f516 && python3 probado.py op103-or01-el-eje.md && python3 plan.py 103 103 ✅ ✅ && cd - >/dev/null && python3 prompts/verificar-corpus.py | tail -1

# --- 2026-10-05T19:26:01 · Smoke-test or02 SQLAlchemy features
cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516 && python3 humo.py op104-or02-sqlalchemy-a-fondo.md or02 'a_fondo.py=@a_fondo.py' --pip SQLAlchemy==2.1.3 --cmd 'python a_fondo.py' 2>&1 | tail -8; cd ../../cursos-algoritmos-lenguajes/python-for-java-devs && python3 ../../zz-code/python-for-java-devs-20261005-f516/verificar_urls.py op104-or02-sqlalchemy-a-fondo.md | tail -3

# --- 2026-10-05T19:26:19 · Fill or02 output, mark, verify
python3 - <<'EOF'
import pathlib,re
p=pathlib.Path("op104-or02-sqlalchemy-a-fondo.md");t=p.read_text()
old=re.search(r"```text\nlazy \(por defecto\)   21 sentencias · saldo de Suba \$….*?\n```\n",t,re.S).group(0)
t=t.replace(old,"""```text
lazy (por defecto)   21 sentencias · saldo de Suba $56,100,000
selectinload          2 sentencias · saldo de Suba $56,100,000
joinedload            1 sentencias · saldo de Suba $56,100,000
raiseload             1 sentencias · InvalidRequestError: 'Plan.fases' is not available due to lazy='raise'…
hybrid en SQL         1 sentencia  · [('PL-033', Decimal('6350000')), ('PL-024', Decimal('5400000')), ('PL-051', Decimal('4750000'))]
```

El mismo saldo de Suba con 21, 2 o 1 sentencias según una línea de `options`. Con `raiseload`, la consulta de los planes se manda y el primer
`p.fases` lanza el error: en una prueba, ese error es el N+1 atrapado antes de producción. Y el `hybrid_property` calculado en SQL da los mismos
tres planes que `or01`, con un detalle que vale la pena notar: los saldos llegan como `Decimal` también desde la subconsulta, porque SQLAlchemy
propaga el tipo `Pesos` a través de `sum` y `coalesce`.
""")
p.write_text(t)
EOF
cd ../../zz-code/python-for-java-devs-20261005-f516 && python3 probado.py op104-or02-sqlalchemy-a-fondo.md && python3 plan.py 104 104 ✅ ✅ && cd - >/dev/null && python3 prompts/verificar-corpus.py | tail -1

# --- 2026-10-05T19:27:20 · Split semicolon lines and run or03
python3 - <<'EOF'
import pathlib,re
p=pathlib.Path("op105-or03-active-record.md");t=p.read_text()
t=re.sub(r"^(\s*)(\w+\.\w+ = \"[^\"]+\"); (\w+(?:_s)?\.(?:save|commit)\(\))(\s*#.*)?$", lambda m: f"{m.group(1)}{m.group(2)}{m.group(4) or ''}\n{m.group(1)}{m.group(3)}", t, flags=re.M)
p.write_text(t)
print(t.count("; "))
EOF
grep -n '\.save()\|_s.commit()' op105-or03-active-record.md | head; cd ../../zz-code/python-for-java-devs-20261005-f516 && python3 humo.py op105-or03-active-record.md or03 'perdida.py=@perdida.py' --pip peewee==4.5.2 Django==6.1.1 SQLAlchemy==2.1.3 --cmd 'python perdida.py' 2>&1 | tail -5

# --- 2026-10-05T19:27:37 · Inspect split lines, mark or03, verify
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs && sed -n 86,91p op105-or03-active-record.md && cd ../../zz-code/python-for-java-devs-20261005-f516 && python3 probado.py op105-or03-active-record.md && python3 plan.py 105 105 ✅ ✅ && cd - >/dev/null && python3 ../../zz-code/python-for-java-devs-20261005-f516/verificar_urls.py op105-or03-active-record.md | tail -3 && python3 prompts/verificar-corpus.py | tail -1

# --- 2026-10-05T19:27:44 · Normalize inline comment spacing
sed -i '' -E 's/^(reception\.sede = "Centro") +# la recepción lo traslada$/\1  # la recepción lo traslada/; s/^(billing\.estado = "pagado") +# el cobro lo marca pagado$/\1  # el cobro lo marca pagado/' op105-or03-active-record.md && sed -n 87,89p op105-or03-active-record.md

# --- 2026-10-05T19:27:52 · Probe Pony ORM on Python 3.14
docker run --rm --label curso=python-for-java-devs python:3.14.7 sh -c 'pip install -q --root-user-action=ignore pony==0.7.20 >/dev/null 2>&1; python -c "
from pony.orm import *
db = Database(); 
class Plan(db.Entity):
    codigo = Required(str); sede = Required(str); fases = Set(\"Fase\")
class Fase(db.Entity):
    plan = Required(Plan); valor = Required(int); estado = Required(str)
db.bind(provider=\"sqlite\", filename=\":memory:\"); db.generate_mapping(create_tables=True)
with db_session:
    p = Plan(codigo=\"PL-1\", sede=\"Suba\"); Fase(plan=p, valor=5_000_000, estado=\"pendiente\")
    q = select(p for p in Plan if p.sede == \"Suba\" and sum(f.valor for f in p.fases if f.estado == \"pendiente\") > 4_000_000)
    print(q[:]); print(q.get_sql())
" 2>&1 | tail -8'

# --- 2026-10-05T19:28:44 · Hedge version claim and run Pony example
python3 - <<'EOF'
import pathlib
p=pathlib.Path("op106-or04-pony.md");t=p.read_text()
a="""funciona con Python 3.14 (este ejemplo lo comprueba), pero históricamente cada versión nueva de Python dejó a Pony unos meses sin soporte. Para un
proyecto que sigue la última versión de Python apenas sale, es un riesgo concreto."""
assert t.count(a)==1
t=t.replace(a,"""funciona con Python 3.14 (este ejemplo lo comprueba), pero el soporte de cada versión nueva depende de que Pony actualice su descompilador, y no
llega el mismo día que la versión de Python (el ejercicio 9 pide medir cuánto tardó con las anteriores). Para un proyecto que sigue la última
versión de Python apenas sale, es un riesgo concreto.""")
p.write_text(t)
EOF
cd ../../zz-code/python-for-java-devs-20261005-f516 && python3 humo.py op106-or04-pony.md or04 'pony_saldos.py=@pony_saldos.py' --pip pony==0.7.20 --cmd 'python pony_saldos.py' 2>&1 | tail -22

# --- 2026-10-05T19:28:55 · Probe Pony behaviour with Python function
cat > salidas/or04/sonda.py <<'EOF'
exec(open("pony_saldos.py").read().split("def is_overdue")[0])
def is_overdue(plan_code: str) -> bool:
    return plan_code.endswith("3")
from pony.orm import set_sql_debug
with db_session:
    q = select(p for p in Plan if is_overdue(p.codigo))
    r = q[:]
    print(len(r), [x.codigo for x in r][:5])
    print(q.get_sql())
EOF
docker run --rm --label curso=python-for-java-devs -v "$PWD/salidas/or04:/w" -w /w python:3.14.7 sh -c 'pip install -q --root-user-action=ignore pony==0.7.20 >/dev/null 2>&1; python sonda.py 2>&1 | tail -12'

# --- 2026-10-05T19:29:08 · Test which Python functions Pony can't translate
cat > salidas/or04/sonda.py <<'EOF'
exec(open("pony_saldos.py").read().split("def is_overdue")[0].replace('print(query.get_sql())', ''))
import re
def f_regex(c): return re.search(r"\d3$", c) is not None
def f_loop(c):
    for ch in c:
        if ch == "3": return True
    return False
def f_int(c): return int(c[-3:]) % 7 == 0
for fn_ in (f_regex, f_loop, f_int):
    with db_session:
        try:
            q = select(p for p in Plan if fn_(p.codigo))
            print(fn_.__name__, "OK", len(q[:]), q.get_sql().replace("\n", " ")[-60:])
        except Exception as e:
            print(fn_.__name__, type(e).__name__, str(e)[:100])
EOF
docker run --rm --label curso=python-for-java-devs -v "$PWD/salidas/or04:/w" -w /w python:3.14.7 sh -c 'pip install -q --root-user-action=ignore pony==0.7.20 >/dev/null 2>&1; python sonda.py 2>&1 | tail -3'

# --- 2026-10-05T19:29:25 · Rewrite translation demo and rerun or04
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs && python3 - <<'EOF'
import pathlib
p=pathlib.Path("op106-or04-pony.md");t=p.read_text()
def rep(a,b):
    global t
    assert t.count(a)==1,a
    t=t.replace(a,b)
rep('''def is_overdue(plan_code: str) -> bool:                # una función de Python cualquiera
    return plan_code.endswith("3")


with db_session:
    try:
        select(p for p in Plan if is_overdue(p.codigo))[:]
    except Exception as e:
        print(f"\\nno se puede traducir: {type(e).__name__}: {str(e)[:90]}")''','''def ends_in_3(code: str) -> bool:                      # simple: Pony la descompila y la mete en el SQL
    return code.endswith("3")


def has_a_3(code: str) -> bool:                         # con un bucle: no hay SQL que la represente
    for ch in code:
        if ch == "3":
            return True
    return False


with db_session:
    for check in (ends_in_3, has_a_3):
        try:
            q = select(p for p in Plan if check(p.codigo))
            print(f"\\n{check.__name__}: {len(q[:])} planes ·", q.get_sql().splitlines()[-1])
        except Exception as e:
            print(f"\\n{check.__name__}: {type(e).__name__}: {e}")''')
rep("""**Funciones de Python dentro del generador.** Pony traduce lo que conoce: atributos, comparaciones, operadores, sus funciones de agregado y
algunas de cadenas y fechas. Una función propia como `is_overdue` no tiene traducción a SQL, y la consulta falla. La lógica se escribe con lo
traducible o se filtra después en Python.""","""**Funciones de Python dentro del generador.** Pony va más lejos de lo que parece: una función propia **simple** la descompila también y la
mete en el SQL —`ends_in_3` se volvió `LIKE '%3'`, cosa que la primera versión de este ejemplo daba por imposible y la corrida desmintió—. Lo que
no puede traducir es lo que no tiene forma de SQL: un bucle, una expresión regular (`re.search` falla dentro de sus propias funciones internas),
una llamada a otra biblioteca. Ahí la consulta falla con `TranslationError`, y la lógica se escribe con lo traducible o se filtra después en
Python.""")
rep("3. Reescribe `is_overdue` con lo que Pony traduce (`p.codigo.endswith(\"3\")` dentro del generador). **Criterio:** la consulta corre.","3. Reescribe `has_a_3` con lo que Pony traduce (`\"3\" in p.codigo`). **Criterio:** la consulta corre, y muestras el SQL que generó.")
p.write_text(t)
EOF
cd ../../zz-code/python-for-java-devs-20261005-f516 && rm salidas/or04/sonda.py && python3 humo.py op106-or04-pony.md or04 'pony_saldos.py=@pony_saldos.py' --pip pony==0.7.20 --cmd 'python pony_saldos.py' 2>&1 | tail -5

# --- 2026-10-05T19:29:37 · Fill or04 output, mark, verify
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs && python3 - <<'EOF'
import pathlib,re
p=pathlib.Path("op106-or04-pony.md");t=p.read_text()
old=re.search(r"```text\nlos tres con más saldo: .*?\n```\n",t,re.S).group(0)
t=t.replace(old,"""```text
los tres con más saldo: [('PL-033', 6350000), ('PL-024', 5400000), ('PL-051', 4750000)]
SELECT "p"."codigo", (
    SELECT coalesce(SUM("f"."valor"), 0)
    FROM "Fase" "f"
    WHERE "p"."id" = "f"."plan"
      AND "f"."estado" = 'pendiente'
    )
FROM "Plan" "p"
WHERE "p"."sede" = 'Suba'
ORDER BY 2 DESC

ends_in_3: 6 planes · WHERE "p"."codigo" LIKE '%3'

has_a_3: TranslationError: has_a_3(...) is too complex to decompile
```

Los mismos tres planes que en `or01` y `or02`, con una consulta que se lee como Python y un SQL que es exactamente el que se escribiría a mano: la
suma condicional como subconsulta correlacionada, una sola sentencia. Y las dos funciones propias muestran el borde de la traducción: la simple
la descompiló y la convirtió en `LIKE '%3'`; la del bucle no tiene SQL posible, y Pony lo dice antes de mandar nada.
""")
p.write_text(t)
EOF
cd ../../zz-code/python-for-java-devs-20261005-f516 && python3 probado.py op106-or04-pony.md && python3 plan.py 106 106 ✅ ✅ && cd - >/dev/null && python3 ../../zz-code/python-for-java-devs-20261005-f516/verificar_urls.py op106-or04-pony.md | tail -3 && python3 prompts/verificar-corpus.py | tail -1

# --- 2026-10-05T19:29:48 · Add async drivers to or inventory
sed -i '' 's/           "yoyo-migrations", "alembic", "pugsql"\],/           "yoyo-migrations", "alembic", "pugsql", "aiosqlite", "asyncpg", "greenlet"],/' prompts/check-inventario.py && sed -n '/"or"/,/\],/p' prompts/check-inventario.py && python3 prompts/check-inventario.py or | tail -1 && grep -m3 "| \`aiosqlite\`\|| \`asyncpg\`\|| \`greenlet\`" prompts/inventario-verificado.md

# --- 2026-10-05T19:30:56 · Smoke-test async ORMs example
cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516 && python3 humo.py op107-or05-los-asincronos.md or05 'asincronos.py=@asincronos.py' --pip "SQLAlchemy[asyncio]==2.1.3" aiosqlite==0.22.1 tortoise-orm==1.1.8 --cmd 'python asincronos.py' 2>&1 | tail -8; cd ../../cursos-algoritmos-lenguajes/python-for-java-devs && python3 ../../zz-code/python-for-java-devs-20261005-f516/verificar_urls.py op107-or05-los-asincronos.md | tail -3

# --- 2026-10-05T19:31:09 · Run or05 with dev mode to locate warning
cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516 && python3 humo.py op107-or05-los-asincronos.md or05 'asincronos.py=@asincronos.py' --pip "SQLAlchemy[asyncio]==2.1.3" aiosqlite==0.22.1 tortoise-orm==1.1.8 --cmd 'python -X dev asincronos.py 2>&1 | head -30' 2>&1 | head -30

# --- 2026-10-05T19:31:27 · Fill or05 output with warning, mark, verify
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs && python3 - <<'EOF'
import pathlib,re
p=pathlib.Path("op107-or05-los-asincronos.md");t=p.read_text()
def rep(a,b):
    global t
    assert t.count(a)==1,a
    t=t.replace(a,b)
old=re.search(r"```text\nSQLAlchemy, perezoso: MissingGreenlet.*?\n```\n",t,re.S).group(0)
t=t.replace(old,"""```text
SQLAlchemy, perezoso: StatementError: (sqlalchemy.exc.MissingGreenlet) greenlet_spawn has not been called; c…
SQLAlchemy, selectinload: 2050000
Tortoise, relación sin esperar: ReverseRelation
Tortoise, await .all(): 2050000
Tortoise, prefetch_related: 2050000
```

Y al terminar, en la salida de error:

```text
RuntimeWarning: coroutine 'Connection.cursor' was never awaited
```

La misma relación, tres comportamientos. En SQLAlchemy, tocarla sin cargarla falla —con `MissingGreenlet` envuelto en un `StatementError`, que
es lo que hay que buscar en una bitácora—, y con `selectinload` funciona. En Tortoise, `loaded.fases` es una `ReverseRelation`, un objeto que
se espera: no hay forma de tocarla por accidente. Y el aviso final es un efecto secundario del intento fallido: SQLAlchemy alcanzó a pedir un
cursor al *driver* asíncrono antes de fallar, y esa corrutina quedó sin esperar. Aparece lejos del error, al cerrar el programa, y es una pista
más de que en algún lado se tocó una relación sin cargar.
""")
rep("- **`MissingGreenlet`** es el error de tocar una relación no cargada en una `AsyncSession`:","- **`MissingGreenlet`** (dentro de un `StatementError`) es el error de tocar una relación no cargada en una `AsyncSession`:")
p.write_text(t)
EOF
cd ../../zz-code/python-for-java-devs-20261005-f516 && python3 probado.py op107-or05-los-asincronos.md && python3 plan.py 107 107 ✅ ✅ && cd - >/dev/null && grep -n "^Salida\|^Y al terminar" op107-or05-los-asincronos.md && python3 prompts/verificar-corpus.py | tail -1

# --- 2026-10-05T19:32:18 · Smoke-test aiosql and sqlglot example
cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516 && python3 humo.py op108-or06-sin-orm.md or06 'cartera.sql=-- name: crear_tablas#' 'reporte.py=@reporte.py' --pip aiosql==15.0 sqlglot==30.21.0 --cmd 'python reporte.py' 2>&1 | tail -10

# --- 2026-10-05T19:32:32 · Add aiosql parameter lists and rerun
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs && python3 - <<'EOF'
import pathlib
p=pathlib.Path("op108-or06-sin-orm.md");t=p.read_text()
def rep(a,b):
    global t
    assert t.count(a)==1,a
    t=t.replace(a,b)
rep("-- name: nuevo_plan<!","-- name: nuevo_plan(codigo, sede)<!")
rep("-- name: nueva_fase!","-- name: nueva_fase(plan_id, valor, estado)!")
rep("-- name: saldos_por_sede\n","-- name: saldos_por_sede(sede, n)\n")
rep("""- **Los sufijos de los nombres** dicen qué devuelve cada consulta en `aiosql`:""","""- **La lista de parámetros en el nombre** (`nueva_fase(plan_id, valor, estado)`) es obligatoria desde `aiosql` 15: sin ella, el archivo no carga y
  falla con `SQLParseException: missing mandatory parameter list`, que fue el primer error de este ejemplo. Los tutoriales anteriores no la
  llevan.
- **Los sufijos de los nombres** dicen qué devuelve cada consulta en `aiosql`:""")
p.write_text(t)
EOF
cd ../../zz-code/python-for-java-devs-20261005-f516 && python3 humo.py op108-or06-sin-orm.md or06 'cartera.sql=-- name: crear_tablas#' 'reporte.py=@reporte.py' --pip aiosql==15.0 sqlglot==30.21.0 --cmd 'python reporte.py' 2>&1 | tail -6

# --- 2026-10-05T19:32:44 · Wrap generator in list and rerun or06
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs && python3 - <<'EOF'
import pathlib
p=pathlib.Path("op108-or06-sin-orm.md");t=p.read_text()
a='print("los tres con más saldo:", queries.saldos_por_sede(conn, sede="Suba", n=3))'
assert t.count(a)==1
t=t.replace(a,'print("los tres con más saldo:", list(queries.saldos_por_sede(conn, sede="Suba", n=3)))   # aiosql 15: un generador')
p.write_text(t)
EOF
cd ../../zz-code/python-for-java-devs-20261005-f516 && python3 humo.py op108-or06-sin-orm.md or06 'cartera.sql=-- name: crear_tablas#' 'reporte.py=@reporte.py' --pip aiosql==15.0 sqlglot==30.21.0 --cmd 'python reporte.py' 2>/dev/null | grep -v "^$"

# --- 2026-10-05T19:33:01 · Fill or06 output, mark, verify
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs && python3 - <<'EOF'
import pathlib,re
p=pathlib.Path("op108-or06-sin-orm.md");t=p.read_text()
def rep(a,b):
    global t
    assert t.count(a)==1,a
    t=t.replace(a,b)
old=re.search(r"```text\nfunciones generadas: \[…\].*?\n```\n",t,re.S).group(0)
t=t.replace(old,"""```text
funciones generadas: ['crear_tablas', 'nueva_fase', 'nuevo_plan', 'saldos_por_sede']
los tres con más saldo: [('PL-033', 6350000), ('PL-024', 5400000), ('PL-051', 4750000)]
tablas que toca: ['fase', 'plan']
en postgres: SELECT p.codigo, SUM(f.valor) AS saldo FROM plan AS p JOIN fase AS f ON f.plan_id = p.id WHERE p.sede = 'Suba' AND f.estado = 'pendiente' GROUP BY p.codigo ORDER BY saldo DESC NULLS LAST LIMIT 3
en tsql: SELECT TOP 3 p.codigo, SUM(f.valor) AS saldo FROM plan AS p JOIN fase AS f ON f.plan_id = p.id WHERE p.sede = 'Suba' AND f.estado = 'pendiente' GROUP BY p.codigo ORDER BY saldo DESC
```

Cada consulta del archivo es una función de Python, y el reporte da los mismos tres planes que el resto del track. La traducción de `sqlglot`
tiene un detalle que vale la sección entera: al pasar a Postgres agregó **`NULLS LAST`**. En SQLite, un orden descendente deja los nulos al final; en
Postgres, al principio. `sqlglot` no tradujo solo la sintaxis, conservó el significado. En T-SQL, el `LIMIT` se volvió `TOP 3`.
""")
rep("""- **`sqlglot` entiende el SQL** como árbol (`tx04`): puede listar las tablas que toca una consulta —útil para saber qué reportes se rompen al
  cambiar una tabla— y traducirla a otro motor. En T-SQL, el `LIMIT` se volvió `TOP 3`.""","""- **`sqlglot` entiende el SQL** como árbol (`tx04`): puede listar las tablas que toca una consulta —útil para saber qué reportes se rompen al
  cambiar una tabla— y traducirla a otro motor.
- **`aiosql` 15 devuelve un generador** en las consultas de selección, no una lista: se envuelve en `list()` si se va a recorrer dos veces o
  imprimir.""")
p.write_text(t)
EOF
sed -i '' 's/^en postgres: SELECT p.codigo, SUM(f.valor) AS saldo FROM plan AS p JOIN fase AS f ON … LIMIT 3$//' op108-or06-sin-orm.md; cd ../../zz-code/python-for-java-devs-20261005-f516 && python3 probado.py op108-or06-sin-orm.md && python3 plan.py 108 108 ✅ ✅ && cd - >/dev/null && python3 ../../zz-code/python-for-java-devs-20261005-f516/verificar_urls.py op108-or06-sin-orm.md | tail -3 && python3 prompts/verificar-corpus.py | tail -1

# --- 2026-10-05T19:34:00 · Smoke-test yoyo migrations example
cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516 && python3 humo.py op109-or07-migraciones.md or07 'migraciones/0001_planes.sql=@0001_planes.sql' 'migraciones/0001_planes.rollback.sql=@0001_planes.rollback.sql' 'migraciones/0002_fases.sql=@0002_fases.sql' 'migraciones/0002_fases.rollback.sql=@0002_fases.rollback.sql' 'migrar.py=@migrar.py' --pip yoyo-migrations==9.0.0 --cmd 'rm -f aurea.db; python migrar.py; yoyo list --database sqlite:///aurea.db migraciones' 2>&1 | tail -14

# --- 2026-10-05T19:34:13 · Use rollback_one and rerun or07
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs && python3 - <<'EOF'
import pathlib
p=pathlib.Path("op109-or07-migraciones.md");t=p.read_text()
a='''    last = [m for m in read_migrations("migraciones") if m.id == "0002_fases"]
    backend.rollback_migrations(backend.to_rollback(last))'''
assert t.count(a)==1
t=t.replace(a,'''    backend.rollback_one(next(m for m in read_migrations("migraciones") if m.id == "0002_fases"))''')
p.write_text(t)
EOF
cd ../../zz-code/python-for-java-devs-20261005-f516 && python3 humo.py op109-or07-migraciones.md or07 'migraciones/0001_planes.sql=@0001_planes.sql' 'migraciones/0001_planes.rollback.sql=@0001_planes.rollback.sql' 'migraciones/0002_fases.sql=@0002_fases.sql' 'migraciones/0002_fases.rollback.sql=@0002_fases.rollback.sql' 'migrar.py=@migrar.py' --pip yoyo-migrations==9.0.0 --cmd 'rm -f aurea.db; python migrar.py; yoyo list --database sqlite:///aurea.db migraciones' 2>&1 | tail -12

# --- 2026-10-05T19:34:27 · Fill or07 output, mark, verify
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs && python3 - <<'EOF'
import pathlib
p=pathlib.Path("op109-or07-migraciones.md");t=p.read_text()
a="""pendientes tras editar 0001: [] · ¿tiene la columna activo? False
```
"""
assert t.count(a)==1
t=t.replace(a,"""pendientes tras editar 0001: [] · ¿tiene la columna activo? False
STATUS    ID           SOURCE
--------  -----------  -----------
A         0001_planes  migraciones
A         0002_fases   migraciones
```

Aplicar, revertir la segunda y volver a aplicarla funciona como en Flyway. La última línea del programa y el `yoyo list` muestran el problema: la
migración `0001` se editó para agregar una columna, y para `yoyo` sigue aplicada (`A`), sin pendientes y sin aviso. La base no tiene la columna.
Flyway, en el mismo caso, se negaría a seguir porque compara una suma de verificación de cada migración; `yoyo` no lo hace, y por eso la prueba
del ejercicio 8 hace falta.
""")
p.write_text(t)
EOF
cd ../../zz-code/python-for-java-devs-20261005-f516 && python3 probado.py op109-or07-migraciones.md && python3 plan.py 109 109 ✅ ✅ && cd - >/dev/null && python3 ../../zz-code/python-for-java-devs-20261005-f516/verificar_urls.py op109-or07-migraciones.md | tail -3 && python3 prompts/verificar-corpus.py | tail -1

# --- 2026-10-05T19:35:36 · Run six-library measured comparison
cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516 && python3 humo.py op110-or08-veredicto.md or08 'seis.py=@seis.py' --pip SQLAlchemy==2.1.3 peewee==4.5.2 Django==6.1.1 pony==0.7.20 aiosql==15.0 --cmd 'rm -f aurea.db; python seis.py' 2>&1 | tail -14

# --- 2026-10-05T19:35:41 · Rerun or08 with content prefix
python3 humo.py op110-or08-veredicto.md or08 'seis.py="""La misma consulta en seis' --pip SQLAlchemy==2.1.3 peewee==4.5.2 Django==6.1.1 pony==0.7.20 aiosql==15.0 --cmd 'rm -f aurea.db; python seis.py' 2>&1 | tail -14

# --- 2026-10-05T19:36:04 · Use forward relations for Django and rerun
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs && python3 - <<'EOF'
import pathlib
p=pathlib.Path("op110-or08-veredicto.md");t=p.read_text()
def rep(a,b):
    global t
    assert t.count(a)==1,a
    t=t.replace(a,b)
rep('''def with_django_navigating():
    owed = {p.codigo: sum(f.valor for f in p.fases.all() if f.estado == "pendiente")
            for p in DjPlan.objects.filter(sede="Suba")}
    return sorted(owed.items(), key=lambda kv: -kv[1])[:3]


def with_django_aggregating():
    q = (DjPlan.objects.filter(sede="Suba")
         .annotate(saldo=Sum("fases__valor", filter=Q(fases__estado="pendiente")))
         .order_by("-saldo").values_list("codigo", "saldo")[:3])
    return list(q)''','''def with_django_navigating():
    owed = {p.codigo: sum(f.valor for f in DjFase.objects.filter(plan=p) if f.estado == "pendiente")
            for p in DjPlan.objects.filter(sede="Suba")}
    return sorted(owed.items(), key=lambda kv: -kv[1])[:3]


def with_django_aggregating():
    q = (DjFase.objects.filter(plan__sede="Suba", estado="pendiente").values("plan__codigo")
         .annotate(saldo=Sum("valor")).order_by("-saldo").values_list("plan__codigo", "saldo")[:3])
    return list(q)''')
rep("from django.db.models import Q, Sum  # noqa: E402","from django.db.models import Sum  # noqa: E402")
rep("| Django ORM | ORM | Active Record | `plan.fases.all()` | `annotate(Sum(...))` |","| Django ORM | ORM | Active Record | Fases de cada plan | `values(...).annotate(Sum(...))` |")
rep("""- **Solo se cuentan los `SELECT`**:""","""- **Django se escribe desde `DjFase`**: en un *script* sin aplicación instalada, Django no registra las relaciones inversas (`plan.fases`) y la
  primera corrida falló con `Cannot resolve keyword 'fases'`. En un proyecto Django normal, las dos direcciones funcionan; la medición no
  cambia.
- **Solo se cuentan los `SELECT`**:""")
p.write_text(t)
EOF
cd ../../zz-code/python-for-java-devs-20261005-f516 && python3 humo.py op110-or08-veredicto.md or08 'seis.py="""La misma consulta en seis' --pip SQLAlchemy==2.1.3 peewee==4.5.2 Django==6.1.1 pony==0.7.20 aiosql==15.0 --cmd 'rm -f aurea.db; python seis.py' 2>&1 | tail -14

# --- 2026-10-05T19:36:28 · Fill or08 results, mark, verify
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs && python3 - <<'EOF'
import pathlib,re
p=pathlib.Path("op110-or08-veredicto.md");t=p.read_text()
old=re.search(r"```text\nversión                       sentencias      ms  líneas  ¿mismo resultado\?\nsqlite3                                1       …       …  True\n…\n```\n",t,re.S).group(0)
t=t.replace(old,"""```text
versión                       sentencias      ms  líneas  ¿mismo resultado?
sqlite3                                1    0.09       3  True
aiosql                                 1    0.09       1  True
sqlalchemy_navigating                 21    3.94       4  True
sqlalchemy_aggregating                 1    0.30       4  True
peewee_navigating                     21    1.66       3  True
peewee_aggregating                     1    0.22       5  True
django_navigating                     21    4.14       3  True
django_aggregating                     1    0.35       3  True
pony                                   1    0.29       4  True
```

Nueve versiones, el mismo resultado, y tres conclusiones que salen de las columnas y no de la preferencia. Primera: **la forma de escribir
la consulta pesa más que la biblioteca**. Las tres versiones "navegando" mandan 21 sentencias y tardan entre 18 y 46 veces lo que el SQL a mano;
las mismas tres bibliotecas, "agregando", mandan una. Segunda: **el ORM cuesta, pero poco**: la versión agregada de SQLAlchemy, Peewee, Django o
Pony tarda entre 0,22 y 0,35 ms contra 0,09 del SQL, dos a cuatro veces, que es la maquinaria de cada biblioteca y en una consulta real contra
una base en red queda en el ruido. Tercera: **las líneas no distinguen** —todas entre 1 y 5—, y la de `aiosql` engaña: su línea es la llamada, y el
SQL vive en el archivo.
""")
t=t.replace("Salida esperada, sin correr (los milisegundos son de la máquina que corre):","Salida esperada, sin correr (los milisegundos son de la máquina que corre; estos, de un contenedor en un portátil, 50 repeticiones):")
p.write_text(t)
EOF
cd ../../zz-code/python-for-java-devs-20261005-f516 && python3 probado.py op110-or08-veredicto.md && python3 plan.py 110 110 ✅ ✅ && cd - >/dev/null && python3 ../../zz-code/python-for-java-devs-20261005-f516/verificar_urls.py op110-or08-veredicto.md | tail -2 && python3 prompts/verificar-corpus.py | tail -1

# --- 2026-10-05T19:36:44 · Close T13 in plan, log entry, update memory
python3 prompts/check-inventario.py or | tail -1 && for kv in SQLAlchemy:2.1.3 PyPika:0.51.1 peewee:4.5.2 Django:6.1.1 pony:0.7.20 tortoise-orm:1.1.8 aiosqlite:0.22.1 aiosql:15.0 sqlglot:30.21.0 yoyo-migrations:9.0.0; do k=${kv%%:*}; v=${kv#*:}; grep -q "| \`$k\` | $v |" prompts/inventario-verificado.md || echo "CAMBIÓ $k"; done; cd ../../zz-code/python-for-java-devs-20261005-f516 && python3 plan.py tanda T13 ✅ && python3 plan.py dondeesta "T1–T13 cerradas (110 de 176). Sigue T14 vz (op111)." && cd - >/dev/null && n=$(for f in op10[3-9]*.md op110*.md; do grep -o "Ejercicios ([0-9]*)" $f; done | grep -o "[0-9]*" | paste -sd+ - | bc) && echo "ejercicios=$n" && python3 - "$n" <<'EOF'
import pathlib,sys
p=pathlib.Path("prompts/plan-de-produccion-carta.md");t=p.read_text()
anchor="## 7. 📓 Bitácora\n\n"
entry=(f"**2026-10-05 · T13 (`or`) cerrada.** Escritas op103–op110 (8 secciones, {sys.argv[1]} ejercicios), **las ocho probadas en "
"contenedor**, todas sobre la misma consulta (los tres planes de Suba con más saldo pendiente) y los mismos datos. **Hallazgos y defectos "
"propios:** el ORM navegando manda 21 sentencias contra 1 (or01); SQLAlchemy 2.1 propaga el tipo `Pesos` a través de `sum` y `coalesce` "
"(or02); Peewee y Django pierden la actualización con dos objetos de la misma fila y SQLAlchemy no (or03); **Pony descompila también las "
"funciones propias simples** (`endswith` → `LIKE '%3'`): el borrador decía lo contrario y se corrigió; falla con bucles y `re` (or04); en "
"`AsyncSession` el `MissingGreenlet` llega dentro de un `StatementError` y deja un `RuntimeWarning` de corrutina sin esperar (or05); "
"`aiosql` 15 exige la lista de parámetros en el nombre y devuelve generadores, y `sqlglot` agrega `NULLS LAST` al traducir a Postgres "
"(or06); `yoyo` no detecta una migración editada (Flyway sí, por la suma de verificación) y `to_rollback` no acepta listas (or07); en "
"un *script* Django sin aplicación no hay relaciones inversas (or08); la medición final: navegando 21 sentencias y 18–46 veces el tiempo "
"del SQL, agregando 1 sentencia y 2–4 veces. **Inventario:** `aiosqlite`, `asyncpg` y `greenlet` agregados; ninguna versión probada "
"cambió.\n\n")
t=t.replace(anchor,anchor+entry,1)
p.write_text(t)
EOF
M=/Users/oskar/.claude/projects/-Users-oskar-Developer-Learning-courses-ia-generated/memory; sed -i '' 's/T1–T12 cerradas el 05\/10\/2026: 102 de 176; sigue T13 or\./T1–T13 cerradas el 05\/10\/2026: 110 de 176; sigue T14 vz./' $M/MEMORY.md && grep -c "110 de 176" $M/MEMORY.md

# --- 2026-10-05T19:37:03 · Read vz track rows and proposal
grep -n "| op11[1-9] .*vz" prompts/plan-de-produccion-carta.md; n=$(grep -n "Track \`vz\`" prompts/propuestas-temas-opcionales.md | head -1 | cut -d: -f1); sed -n "${n},$((n+36))p" prompts/propuestas-temas-opcionales.md; sed -n '/"vz"/,/\],/p' prompts/check-inventario.py; grep -n "vz" prompts/guia-de-estilo-y-convenciones.md | head -5

# --- 2026-10-05T19:37:14 · Look up vz package versions
for k in matplotlib seaborn plotnine altair vl-convert-python great-tables graphviz networkx drawsvg diagrams svg.py pandas polars; do grep -m1 "| \`$k\` |" prompts/inventario-verificado.md || echo "falta $k"; done

# --- 2026-10-05T19:37:20 · Add vz packages to inventory and refresh
sed -i '' 's/           "diagrams", "datashader", "pydeck", "folium", "svg.py", "svgwrite"\],/           "diagrams", "datashader", "pydeck", "folium", "svg.py", "svgwrite", "vl-convert-python", "pandas",\n           "polars", "colorspacious"],/' prompts/check-inventario.py && sed -n '/"vz"/,/\],/p' prompts/check-inventario.py && python3 prompts/check-inventario.py vz | tail -1 && for k in vl-convert-python pandas polars colorspacious; do grep -m1 "| \`$k\` |" prompts/inventario-verificado.md; done

# --- 2026-10-05T19:38:27 · Smoke-test pyplot vs Figure memory
cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516 && python3 humo.py op111-vz01-el-modelo-y-matplotlib.md vz01 'recaudo.py=@recaudo.py' --pip matplotlib==3.11.2 --cmd 'python recaudo.py; ls recaudo-*.png | wc -l' 2>&1 | tail -6; cd ../../cursos-algoritmos-lenguajes/python-for-java-devs && python3 ../../zz-code/python-for-java-devs-20261005-f516/verificar_urls.py op111-vz01-el-modelo-y-matplotlib.md | tail -3

# --- 2026-10-05T19:38:59 · Fill vz01 output, mark, verify
python3 - <<'EOF'
import pathlib,re
p=pathlib.Path("op111-vz01-el-modelo-y-matplotlib.md");t=p.read_text()
old=re.search(r"```text\npyplot sin cerrar  figuras vivas en pyplot: 30 · memoria retenida:  … MB.*?\n```\n",t,re.S).group(0)
t=t.replace(old,"""```text
pyplot sin cerrar  figuras vivas en pyplot: 30 · memoria retenida:  27.9 MB · avisos: 1
   More than 20 figures have been opened. Figures created through the pyplot interface (`matplotlib.pyp …
Figure             figuras vivas en pyplot:  0 · memoria retenida:   9.1 MB · avisos: 0
```

Tres noches de diez imágenes. Con `pyplot` sin cerrar, las treinta figuras siguen vivas en el registro global y retienen 27,9 MB; con `Figure`, no
queda ninguna. Los 9,1 MB del segundo caso no son una fuga: son los cachés que Matplotlib carga una vez (fuentes, entre otros) y que el primer caso
también tiene adentro. La diferencia, unos 19 MB en tres noches, crece con cada noche; la del segundo caso, no. Y de las treinta figuras olvidadas,
Matplotlib avisó **una vez**, al pasar de veinte.
""")
p.write_text(t)
EOF
cd ../../zz-code/python-for-java-devs-20261005-f516 && python3 probado.py op111-vz01-el-modelo-y-matplotlib.md && python3 plan.py 111 111 ✅ ✅ && cd - >/dev/null && python3 prompts/verificar-corpus.py | tail -1

# --- 2026-10-05T19:39:51 · Smoke-test grammar of graphics example
cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516 && python3 humo.py op112-vz02-la-gramatica.md vz02 'gramatica.py=@gramatica.py' --pip altair==6.3.0 vl-convert-python==1.9.0.post1 plotnine==0.15.8 great-tables==1.0.0 pandas==3.0.6 --cmd 'python gramatica.py; ls *.png' 2>&1 | tail -12; cd ../../cursos-algoritmos-lenguajes/python-for-java-devs && python3 ../../zz-code/python-for-java-devs-20261005-f516/verificar_urls.py op112-vz02-la-gramatica.md | tail -3

# --- 2026-10-05T19:40:46 · Fix Great Tables extraction and rerun
python3 - <<'EOF'
import pathlib
p=pathlib.Path("op112-vz02-la-gramatica.md");t=p.read_text()
def rep(a,b):
    global t
    assert t.count(a)==1,a
    t=t.replace(a,b)
rep('print("Great Tables: HTML de", len(html), "bytes; primera cifra:", html.split("sem 1")[1].split("$")[1][:12].strip())',
    'print("Great Tables: HTML de", len(html), "bytes; primera cifra:", re.search(r"\\$\\s?[\\d.]+", html).group())')
rep("import json\nimport random\n","import json\nimport random\nimport re\n")
p.write_text(t)
EOF
cd ../../zz-code/python-for-java-devs-20261005-f516 && python3 humo.py op112-vz02-la-gramatica.md vz02 'gramatica.py=@gramatica.py' --pip altair==6.3.0 vl-convert-python==1.9.0.post1 plotnine==0.15.8 great-tables==1.0.0 pandas==3.0.6 --cmd 'python gramatica.py' 2>/dev/null | grep -v "^$"

# --- 2026-10-05T19:41:38 · Fill vz02 output, mark, verify
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs && python3 - <<'EOF'
import pathlib,re
p=pathlib.Path("op112-vz02-la-gramatica.md");t=p.read_text()
old=re.search(r"```text\nAltair: lo que cambia entre barras y líneas.*?\n```\n",t,re.S).group(0)
t=t.replace(old,"""```text
Altair: lo que cambia entre barras y líneas en la especificación: ['mark'] → {'type': 'bar'} / {'type': 'line', 'point': True}
Altair: tamaño de la especificación: 1335 bytes
plotnine: recaudo-plotnine.png
Great Tables: HTML de 11010 bytes; primera cifra: $49.000.000
Altair con 6 000 filas: MaxRowsError: The number of rows in your dataset (6000) is greater than the maximum allowed (5
```

Entre el gráfico de barras y el de líneas, la especificación de Altair difiere en **una sola clave**, `mark`; los datos, los canales y los títulos son
los mismos. El gráfico entero, con sus dieciséis filas de datos adentro, pesa 1,3 KB de JSON. Great Tables formateó el primer monto como
`$49.000.000`, con el punto de miles de Colombia, sin tocar el dato. Y la última línea es la trampa de la sección: con 6 000 filas, Altair se niega
antes de dibujar nada.
""")
p.write_text(t)
EOF
cd ../../zz-code/python-for-java-devs-20261005-f516 && python3 probado.py op112-vz02-la-gramatica.md && python3 plan.py 112 112 ✅ ✅ && cd - >/dev/null && python3 prompts/verificar-corpus.py | tail -1

# --- 2026-10-05T19:42:30 · Test diagrams with and without dot binary
cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516 && python3 humo.py op113-vz03-graficos-que-no-son-datos.md vz03 'diagramas.py=@diagramas.py' --pip graphviz==0.21 drawsvg==2.4.2 --cmd 'python diagramas.py 2>&1 | tail -3; echo ---; apt-get update -qq >/dev/null 2>&1 && apt-get install -y -qq graphviz >/dev/null 2>&1; python diagramas.py; ls -la *.svg | wc -l' 2>&1 | tail -14; cd ../../cursos-algoritmos-lenguajes/python-for-java-devs && python3 ../../zz-code/python-for-java-devs-20261005-f516/verificar_urls.py op113-vz03-graficos-que-no-son-datos.md | tail -3

# --- 2026-10-05T19:42:49 · Mark vz03 and note verified error
cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516 && python3 probado.py op113-vz03-graficos-que-no-son-datos.md && python3 plan.py 113 113 ✅ ✅ && cd ../../cursos-algoritmos-lenguajes/python-for-java-devs && python3 - <<'EOF'
import pathlib
p=pathlib.Path("op113-vz03-graficos-que-no-son-datos.md");t=p.read_text()
a="**`graphviz` sin el binario.** El paquete de Python solo escribe DOT; quien dibuja es el programa `dot`, que se instala aparte. Sin él,\n`render` falla con `ExecutableNotFound`."
assert t.count(a)==1
t=t.replace(a,"**`graphviz` sin el binario.** El paquete de Python solo escribe DOT; quien dibuja es el programa `dot`, que se instala aparte. Sin él,\n`render` falla con `ExecutableNotFound: failed to execute PosixPath('dot')` —comprobado en la imagen de Python, que no lo trae—.")
p.write_text(t)
EOF
python3 prompts/verificar-corpus.py | tail -1

# --- 2026-10-05T19:43:50 · Smoke-test visual lies measurements
cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516 && python3 humo.py op114-vz04-el-grafico-que-miente.md vz04 'mentiras.py=@mentiras.py' --pip numpy==2.5.3 matplotlib==3.11.2 --cmd 'python mentiras.py' 2>&1 | tail -8; cd ../../cursos-algoritmos-lenguajes/python-for-java-devs && python3 ../../zz-code/python-for-java-devs-20261005-f516/verificar_urls.py op114-vz04-el-grafico-que-miente.md | tail -3

# --- 2026-10-05T19:44:20 · Fill vz04, mark, close T14, update log and memory
python3 - <<'EOF'
import pathlib
p=pathlib.Path("op114-vz04-el-grafico-que-miente.md");t=p.read_text()
a="""jet      L* de …, máximo … · cambios de dirección: …
viridis  L* de …, máximo … · cambios de dirección: 0
verde contra rojo: ΔE … con visión típica · … con deuteranopía
```
"""
assert t.count(a)==1
t=t.replace(a,"""jet      L* de  12.9 a  25.4, máximo  95.9 · cambios de dirección: 5
viridis  L* de  14.9 a  90.9, máximo  90.9 · cambios de dirección: 0
verde contra rojo: ΔE 100.8 con visión típica ·  15.8 con deuteranopía
```

Tres números, tres mentiras. Con el eje desde 45 millones, el Centro parece recaudar más del doble que Suba cuando recauda 8 % más: un factor de
mentira de 16. El mapa `jet` sube de luminosidad hasta 95,9 en el medio y vuelve a bajar a 25,4, con cinco cambios de dirección: el ojo ve el
amarillo del centro como "lo más alto" aunque el valor más alto sea el rojo oscuro del final; `viridis` sube siempre. Y el verde y el rojo del
semáforo de `vz03`, a una distancia de 100,8 para la visión típica, quedan a 15,8 para alguien con deuteranopía: dos tonos de un mismo café.
""")
p.write_text(t)
EOF
cd ../../zz-code/python-for-java-devs-20261005-f516 && python3 probado.py op114-vz04-el-grafico-que-miente.md && python3 plan.py 114 114 ✅ ✅ && python3 plan.py tanda T14 ✅ && python3 plan.py dondeesta "T1–T14 cerradas (114 de 176). Sigue T15 sy (op115)." && cd - >/dev/null && python3 prompts/verificar-corpus.py | tail -1 && python3 - <<'EOF'
import pathlib
p=pathlib.Path("prompts/plan-de-produccion-carta.md");t=p.read_text()
anchor="## 7. 📓 Bitácora\n\n"
entry=("**2026-10-05 · T14 (`vz`) cerrada.** Escritas op111–op114 (4 secciones, 36 ejercicios; el track recortado a cuatro, como "
"decidió la guía), **las cuatro probadas en contenedor**, con la frontera de la propuesta: aquí la imagen es un entregable del sistema, "
"no exploración. **Hallazgos:** tres noches con `pyplot` sin cerrar dejan 30 figuras y 27,9 MB contra 9,1 MB de cachés con `Figure`, y "
"Matplotlib avisa una sola vez (vz01); entre barras y líneas la especificación de Altair difiere solo en `mark`, y Altair rechaza 6 000 "
"filas con `MaxRowsError` (vz02); `graphviz` sin el binario falla con `ExecutableNotFound` y el diagrama del cierre sale de la misma "
"definición en DOT y Mermaid (vz03); factor de mentira 16 con el eje desde 45 M, `jet` con cinco cambios de dirección de luminosidad, y el "
"semáforo pasa de ΔE 100,8 a 15,8 con deuteranopía (vz04). **Inventario:** `vl-convert-python`, `pandas`, `polars` y `colorspacious` "
"agregados al track; ninguna versión probada cambió.\n\n")
t=t.replace(anchor,anchor+entry,1)
p.write_text(t)
EOF
M=/Users/oskar/.claude/projects/-Users-oskar-Developer-Learning-courses-ia-generated/memory; sed -i '' 's/T1–T13 cerradas el 05\/10\/2026: 110 de 176; sigue T14 vz\./T1–T14 cerradas el 05\/10\/2026: 114 de 176; sigue T15 sy./' $M/MEMORY.md && grep -c "114 de 176" $M/MEMORY.md

# --- 2026-10-05T19:44:27 · Fix T14 count; read sy track rows and proposal
for f in op11[1-4]*.md; do grep -o "Ejercicios ([0-9]*)" $f; done | grep -o "[0-9]*" | paste -sd+ - | bc && sed -i '' 's/Escritas op111–op114 (4 secciones, 36 ejercicios;/Escritas op111–op114 (4 secciones, 38 ejercicios;/' prompts/plan-de-produccion-carta.md && grep -c "38 ejercicios; el track recortado" prompts/plan-de-produccion-carta.md; grep -n "| op11[5-9] .*sy\|| op12[0-9] .*sy" prompts/plan-de-produccion-carta.md; n=$(grep -n "Track \`sy\`" prompts/propuestas-temas-opcionales.md | head -1 | cut -d: -f1); sed -n "${n},$((n+30))p" prompts/propuestas-temas-opcionales.md; sed -n '/"sy"/,/\],/p' prompts/check-inventario.py

# --- 2026-10-05T19:45:19 · Smoke-test subprocess traps
cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516 && python3 humo.py op115-sy01-subprocess-a-fondo.md sy01 'trampas_subprocess.py="""Las tres trampas de subprocess' --cmd 'python trampas_subprocess.py' 2>&1 | tail -8; cd ../../cursos-algoritmos-lenguajes/python-for-java-devs && python3 ../../zz-code/python-for-java-devs-20261005-f516/verificar_urls.py op115-sy01-subprocess-a-fondo.md | tail -2

# --- 2026-10-05T19:45:36 · Correct orphan count in sy01, mark
python3 - <<'EOF'
import pathlib
p=pathlib.Path("op115-sy01-subprocess-a-fondo.md");t=p.read_text()
def rep(a,b):
    global t
    assert t.count(a)==1,a
    t=t.replace(a,b)
rep("run(timeout=1): procesos 'sleep 30' vivos después: 1","run(timeout=1): procesos 'sleep 30' vivos después: 2")
rep("""- **`run(timeout=…)`** mata al hijo (`sh`), pero el `sleep 30 &` que el hijo lanzó en segundo plano queda huérfano y sigue corriendo. En un cierre
  nocturno, esos huérfanos se acumulan noche tras noche.""","""- **`run(timeout=…)`** mata al hijo (`sh`) y a nadie más: **los dos** `sleep 30` que `sh` lanzó —el de segundo plano y el que esperaba— quedan
  huérfanos y siguen corriendo. El borrador de esta sección esperaba uno; la corrida encontró dos, porque matar a `sh` no mata a ninguno de sus
  hijos. En un cierre nocturno, esos huérfanos se acumulan noche tras noche.""")
rep("| **El nieto huérfano** | `timeout` mata al hijo; los procesos que el hijo lanzó siguen vivos |","| **El nieto huérfano** | `timeout` mata al hijo; **todos** los procesos que el hijo lanzó siguen vivos |")
p.write_text(t)
EOF
cd ../../zz-code/python-for-java-devs-20261005-f516 && python3 probado.py op115-sy01-subprocess-a-fondo.md && python3 plan.py 115 115 ✅ ✅ && cd - >/dev/null && python3 prompts/verificar-corpus.py | tail -1

# --- 2026-10-05T19:45:44 · Look up sy track package versions
for k in plumbum sh invoke psutil watchdog filelock pexpect python-daemon systemd-python supervisor sdnotify; do grep -m1 "| \`$k\` |" prompts/inventario-verificado.md || echo "falta $k"; done

# --- 2026-10-05T19:46:29 · Smoke-test wrappers and invoke tasks
cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516 && python3 humo.py op116-sy02-las-envolturas.md sy02 'envolturas.py=@envolturas.py' 'tasks.py=from invoke import task' --pip plumbum==2.0.2 sh==2.4.0 invoke==3.0.3 --cmd 'rm -f cierre.csv.gz; python envolturas.py; echo ---; invoke --list; invoke respaldo' 2>&1 | tail -18; cd ../../cursos-algoritmos-lenguajes/python-for-java-devs && python3 ../../zz-code/python-for-java-devs-20261005-f516/verificar_urls.py op116-sy02-las-envolturas.md | tail -2

# --- 2026-10-05T19:46:46 · Fill sy02 output, mark, verify
python3 - <<'EOF'
import pathlib,re
p=pathlib.Path("op116-sy02-las-envolturas.md");t=p.read_text()
old=re.search(r"```text\nsubprocess: … bytes.*?\n```\n",t,re.S).group(0)
t=t.replace(old,"""```text
subprocess: 577 bytes
plumbum:    577 bytes
sh:         577 bytes

subprocess sin check: returncode 1 · nada se lanzó
plumbum    lanzó ProcessExecutionError
sh         lanzó ErrorReturnCode_1

por llamada a 'true': subprocess 0.26 ms · plumbum 0.30 ms · sh 2.47 ms
Available tasks:

  comprimir   Comprime el cierre del día.
  respaldo    Comprime y reporta el tamaño.

respaldo listo: 577 bytes
```

La misma tubería da los mismos 577 bytes en las tres formas. Ante el archivo que no existe, `subprocess` devolvió un código de salida y siguió; las dos
envolturas lanzaron. Y el costo del azúcar es desparejo: plumbum casi no agrega nada sobre `subprocess` (0,30 contra 0,26 ms), mientras que sh tarda
**casi diez veces más** por llamada (2,47 ms), porque arma hilos propios para leer la salida de cada proceso. En un respaldo nocturno con diez
llamadas no importa; en un bucle que llama a un programa diez mil veces, son veinte segundos contra dos y medio.
""")
p.write_text(t)
EOF
cd ../../zz-code/python-for-java-devs-20261005-f516 && python3 probado.py op116-sy02-las-envolturas.md && python3 plan.py 116 116 ✅ ✅ && cd - >/dev/null && python3 prompts/verificar-corpus.py | tail -1

# --- 2026-10-05T19:46:52 · Correct time estimate in sy02
sed -i '' 's/llamadas no importa; en un bucle que llama a un programa diez mil veces, son veinte segundos contra dos y medio\./llamadas no importa; en un bucle que llama a un programa diez mil veces, son veinticinco segundos contra dos y medio./' op116-sy02-las-envolturas.md && grep -c "veinticinco segundos" op116-sy02-las-envolturas.md

# --- 2026-10-05T19:47:39 · Smoke-test system inspection agent
cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516 && python3 humo.py op117-sy03-inspeccion-del-sistema.md sy03 'agente.py=@agente.py' --pip psutil==7.2.2 --cmd 'python agente.py' 2>&1 | tail -8; cd ../../cursos-algoritmos-lenguajes/python-for-java-devs && python3 ../../zz-code/python-for-java-devs-20261005-f516/verificar_urls.py op117-sy03-inspeccion-del-sistema.md | tail -2

# --- 2026-10-05T19:47:53 · Fix psutil URL, fill output, mark sy03
echo "$(curl -s -o /dev/null -w '%{http_code}' -L -m 20 https://psutil.io/)"; cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs && python3 - <<'EOF'
import pathlib
p=pathlib.Path("op117-sy03-inspeccion-del-sistema.md");t=p.read_text()
def rep(a,b):
    global t
    assert t.count(a)==1,a
    t=t.replace(a,b)
rep("- `psutil`: https://psutil.readthedocs.io/en/latest/","- `psutil`: https://psutil.io/")
rep("""agente pid …: memoria … MB · disco libre … GB (… %)
hijo sin recoger: zombie
después de waitpid: ya no existe
con límite 64: abrió … archivos y falló con errno 24 (Too many open files)""","""agente pid 10: memoria 13 MB · disco libre 973.1 GB (95 %)
hijo sin recoger: zombie
después de waitpid: ya no existe
con límite 64: abrió 61 archivos y falló con errno 24 (Too many open files)""")
p.write_text(t)
EOF
cd ../../zz-code/python-for-java-devs-20261005-f516 && python3 probado.py op117-sy03-inspeccion-del-sistema.md && python3 plan.py 117 117 ✅ ✅ && cd - >/dev/null && python3 ../../zz-code/python-for-java-devs-20261005-f516/verificar_urls.py op117-sy03-inspeccion-del-sistema.md | tail -1 && python3 prompts/verificar-corpus.py | tail -1

# --- 2026-10-05T19:48:51 · Run sy04 unguarded to see 3.14 behaviour
cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516 && python3 humo.py op118-sy04-el-sistema-de-archivos.md sy04 'atomico.py=@atomico.py' --pip filelock==4.0.12 --cmd 'timeout 120 python atomico.py; echo "exit=$?"; python -c "import multiprocessing as m; print(m.get_start_method())"' 2>&1 | tail -12

# --- 2026-10-05T19:49:08 · Add main guard, document 3.14 change, rerun
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs && python3 - <<'EOF'
import pathlib
p=pathlib.Path("op118-sy04-el-sistema-de-archivos.md");t=p.read_text()
start=t.index("random.seed(1)\nfor writer in (naive, atomic):")
end=t.index('    print(f"contador {\'con\' if lock else \'sin\'} filelock: {open(\'contador.txt\').read():>4} (esperado 1000)")')
end=t.index("\n", end)
new='''# ------------------------------------------------- un contador en un archivo, desde cuatro procesos
def bump(path: str, n: int, lock: bool):
    for _ in range(n):
        with FileLock(path + ".lock") if lock else open(os.devnull):
            value = int(open(path).read())
            with open(path, "w") as f:
                f.write(str(value + 1))


if __name__ == "__main__":                                # obligatorio con multiprocessing en Python 3.14 (ver §4)
    random.seed(1)
    for writer in (naive, atomic):
        broken = 0
        for _ in range(20):
            atomic("estado.json")                         # un estado válido de la noche anterior
            p = mp.Process(target=writer, args=("estado.json",))
            p.start()
            time.sleep(random.uniform(0.001, 0.02))       # el corte llega en cualquier momento
            os.kill(p.pid, signal.SIGKILL)
            p.join()
            broken += not is_valid("estado.json")
        print(f"{writer.__name__:<7} con SIGKILL a mitad de camino: {broken:>2} de 20 archivos quedaron rotos")

    for lock in (False, True):
        with open("contador.txt", "w") as f:
            f.write("0")
        procs = [mp.Process(target=bump, args=("contador.txt", 250, lock)) for _ in range(4)]
        for p in procs:
            p.start()
        for p in procs:
            p.join()
        print(f"contador {'con' if lock else 'sin'} filelock: {open('contador.txt').read():>4} (esperado 1000)")'''
t=t[:start]+new+t[end:]
a="""**Abrir con `"w"` el archivo que se quiere conservar.**"""
assert t.count(a)==1
t=t.replace(a,"""**`multiprocessing` sin `if __name__ == "__main__"` en Python 3.14.** Desde la 3.14, el método de arranque por defecto en Linux es `forkserver`, no
`fork`: cada proceso hijo vuelve a importar el módulo principal. Un *script* sin la guarda vuelve a ejecutarse en cada hijo, y la primera versión de
este ejemplo falló con `ConnectionResetError` desde el servidor de *fork*. Código que funcionaba en 3.13 se rompe al actualizar; la guarda lo arregla.

**Abrir con `"w"` el archivo que se quiere conservar.**""")
p.write_text(t)
EOF
sed -n '/^# ------------------------------------------------- un contador/,/^```$/p' op118-sy04-el-sistema-de-archivos.md | head -5; cd ../../zz-code/python-for-java-devs-20261005-f516 && python3 humo.py op118-sy04-el-sistema-de-archivos.md sy04 'atomico.py=@atomico.py' --pip filelock==4.0.12 --cmd 'timeout 200 python atomico.py; echo "exit=$?"' 2>&1 | tail -6

# --- 2026-10-05T19:49:28 · Make kill timing deterministic and rerun
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs && python3 - <<'EOF'
import pathlib
p=pathlib.Path("op118-sy04-el-sistema-de-archivos.md");t=p.read_text()
def rep(a,b):
    global t
    assert t.count(a)==1,a
    t=t.replace(a,b)
rep('STATE = {"fecha": "2026-10-05", "sedes": {f"sede-{i:02d}": {"estado": "ok", "filas": i * 1000} for i in range(4000)}}',
    'STATE = {"fecha": "2026-10-05", "sedes": {f"sede-{i:05d}": {"estado": "ok", "filas": i * 1000} for i in range(40_000)}}')
rep('''def naive(path: str):
    with open(path, "w") as f:
        for i in range(0, len(PAYLOAD), 4096):''','''def naive(path: str, started=None):
    with open(path, "w") as f:
        if started:
            started.set()                                 # avisa que ya abrió (y truncó) el archivo
        for i in range(0, len(PAYLOAD), 4096):''')
rep('''def atomic(path: str):
    tmp = path + ".tmp"
    with open(tmp, "w") as f:
        for i in range(0, len(PAYLOAD), 4096):''','''def atomic(path: str, started=None):
    tmp = path + ".tmp"
    with open(tmp, "w") as f:
        if started:
            started.set()
        for i in range(0, len(PAYLOAD), 4096):''')
rep('''            p = mp.Process(target=writer, args=("estado.json",))
            p.start()
            time.sleep(random.uniform(0.001, 0.02))       # el corte llega en cualquier momento
            os.kill(p.pid, signal.SIGKILL)
            p.join()''','''            started = mp.Event()
            p = mp.Process(target=writer, args=("estado.json", started))
            p.start()
            started.wait(10)
            time.sleep(random.uniform(0, 0.005))          # el corte llega en cualquier momento de la escritura
            try:
                os.kill(p.pid, signal.SIGKILL)
            except ProcessLookupError:                    # alcanzó a terminar: no hubo corte
                pass
            p.join()''')
p.write_text(t)
EOF
cd ../../zz-code/python-for-java-devs-20261005-f516 && python3 humo.py op118-sy04-el-sistema-de-archivos.md sy04 'atomico.py=@atomico.py' --pip filelock==4.0.12 --cmd 'timeout 250 python atomico.py; echo "exit=$?"' 2>&1 | tail -6

# --- 2026-10-05T19:49:46 · Tolerate empty read and rerun sy04
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs && python3 - <<'EOF'
import pathlib
p=pathlib.Path("op118-sy04-el-sistema-de-archivos.md");t=p.read_text()
def rep(a,b):
    global t
    assert t.count(a)==1,a
    t=t.replace(a,b)
rep("            value = int(open(path).read())\n","            value = int(open(path).read() or 0)          # sin bloqueo, a veces lo lee recién truncado: vacío\n")
rep("""- **El contador sin bloqueo pierde actualizaciones** por la misma razón que el `save()` de `or03`: leer, sumar y escribir no es una operación. Con
  `FileLock`, un solo proceso a la vez hace las tres.""","""- **El contador sin bloqueo pierde actualizaciones** por la misma razón que el `save()` de `or03`: leer, sumar y escribir no es una operación. Y
  peor: a veces un proceso lee el archivo justo después de que otro lo truncó, y encuentra una cadena vacía —la primera versión de este ejemplo
  se cayó con `ValueError: invalid literal for int() with base 10: ''`—; el `or 0` reproduce lo que pasaría en la realidad: el contador vuelve a
  cero. Con `FileLock`, un solo proceso a la vez hace las tres.""")
p.write_text(t)
EOF
cd ../../zz-code/python-for-java-devs-20261005-f516 && python3 humo.py op118-sy04-el-sistema-de-archivos.md sy04 'atomico.py=@atomico.py' --pip filelock==4.0.12 --cmd 'timeout 250 python atomico.py; echo "exit=$?"' 2>&1 | tail -6

# --- 2026-10-05T19:49:55 · Capture full sy04 output
python3 humo.py op118-sy04-el-sistema-de-archivos.md sy04 'atomico.py=@atomico.py' --pip filelock==4.0.12 --cmd 'timeout 250 python atomico.py' 2>/dev/null | grep -v "^$"

# --- 2026-10-05T19:50:12 · Fill sy04 output, mark, verify
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs && python3 - <<'EOF'
import pathlib
p=pathlib.Path("op118-sy04-el-sistema-de-archivos.md");t=p.read_text()
a="""naive   con SIGKILL a mitad de camino: … de 20 archivos quedaron rotos
atomic  con SIGKILL a mitad de camino:  0 de 20 archivos quedaron rotos
contador sin filelock:  … (esperado 1000)
contador con filelock: 1000 (esperado 1000)
```
"""
assert t.count(a)==1
t=t.replace(a,"""naive   con SIGKILL a mitad de camino: 20 de 20 archivos quedaron rotos
atomic  con SIGKILL a mitad de camino:  0 de 20 archivos quedaron rotos
contador sin filelock:    6 (esperado 1000)
contador con filelock: 1000 (esperado 1000)
```

Veinte cortes en cada versión. La escritura ingenua dejó **los veinte** archivos rotos: desde el `open(..., "w")`, el estado de la noche anterior ya no
existía, y cualquier corte posterior dejaba un JSON a medias. La atómica no rompió ninguno: el corte encontraba el archivo viejo entero, porque el
nuevo solo reemplaza al viejo en el `os.replace`. El contador sin bloqueo terminó en 6 de 1 000 —en otra corrida, 4: el número cambia, el desastre
no—, porque además de pisarse las sumas, cada lectura de un archivo recién truncado lo devolvía a cero. Con `FileLock`, 1 000 exactos.
""")
p.write_text(t)
EOF
cd ../../zz-code/python-for-java-devs-20261005-f516 && python3 probado.py op118-sy04-el-sistema-de-archivos.md && python3 plan.py 118 118 ✅ ✅ && cd - >/dev/null && python3 ../../zz-code/python-for-java-devs-20261005-f516/verificar_urls.py op118-sy04-el-sistema-de-archivos.md | tail -2 && python3 prompts/verificar-corpus.py | tail -1

# --- 2026-10-05T19:51:07 · Smoke-test watchdog inbox example
cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516 && grep -m1 "| \`watchdog\`" ../../cursos-algoritmos-lenguajes/python-for-java-devs/prompts/inventario-verificado.md; python3 humo.py op119-sy05-reaccionar-a-cambios.md sy05 'entrada.py=@entrada.py' --pip watchdog==6.0.0 --cmd 'rm -rf entrada; python entrada.py' 2>&1 | tail -5; cd ../../cursos-algoritmos-lenguajes/python-for-java-devs && python3 ../../zz-code/python-for-java-devs-20261005-f516/verificar_urls.py op119-sy05-reaccionar-a-cambios.md | tail -2

# --- 2026-10-05T19:51:28 · Fill sy05 output with findings, mark
python3 - <<'EOF'
import pathlib
p=pathlib.Path("op119-sy05-reaccionar-a-cambios.md");t=p.read_text()
a="""al crearse      ['lote-1.csv: 0 filas']
al cerrarse     ['lote-1.csv: 50000 filas']
al renombrarse  ['lote-2.csv: 50000 filas']
```
"""
assert t.count(a)==1
t=t.replace(a,"""al crearse      ['lote-1.csv: 1 filas', 'lote-1.csv: 1 filas', 'lote-2.csv: 50000 filas']
al cerrarse     ['lote-1.csv: 50000 filas']
al renombrarse  ['lote-2.csv: 50000 filas']
```

Tres lecciones en tres líneas. El lote escrito con su nombre definitivo disparó `created` con **una** fila de cincuenta mil: el manejador ingenuo habría
procesado una autorización y descartado el resto. Además, `watchdog` entregó **dos** eventos `created` para el mismo archivo, que es la razón práctica
para que el procesamiento sea idempotente. El `closed` llegó con el archivo completo. Y el lote escrito como `.part` y renombrado llegó completo **por
los dos caminos**: el `moved`, y también un `created` del nombre definitivo, que aparece recién cuando el archivo ya está entero. Con el contrato del
renombrado, hasta un manejador ingenuo lee bien.
""")
p.write_text(t)
EOF
cd ../../zz-code/python-for-java-devs-20261005-f516 && python3 probado.py op119-sy05-reaccionar-a-cambios.md && python3 plan.py 119 119 ✅ ✅ && cd - >/dev/null && python3 prompts/verificar-corpus.py | tail -1

# --- 2026-10-05T19:52:31 · Test sd_notify protocol and supervisord restarts
cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516 && python3 humo.py op120-sy06-convivir-con-el-sistema.md sy06 'vigilante.py=@vigilante.py' 'probar_vigilante.py="""Hacer de systemd' 'supervisord.conf=[supervisord]' --pip supervisor==4.3.0 --cmd 'python probar_vigilante.py; echo ---; timeout 6 supervisord -c supervisord.conf >/dev/null 2>&1; grep -c "error irrecuperable" /tmp/vigilante.log; grep -E "spawned|exited|gave up" /tmp/supervisord.log | sed "s/^[0-9-]* [0-9:,]* //" | head -8' 2>&1 | tail -16; cd ../../cursos-algoritmos-lenguajes/python-for-java-devs && python3 ../../zz-code/python-for-java-devs-20261005-f516/verificar_urls.py op120-sy06-convivir-con-el-sistema.md | tail -3

# --- 2026-10-05T19:52:41 · Replace systemd URL and rerun sy06
echo "$(curl -s -o /dev/null -w '%{http_code}' -L -m 20 https://man7.org/linux/man-pages/man5/systemd.service.5.html)" && sed -i '' 's#- `systemd.service`: https://www.freedesktop.org/software/systemd/man/latest/systemd.service.html#- `systemd.service(5)`: https://man7.org/linux/man-pages/man5/systemd.service.5.html#' op120-sy06-convivir-con-el-sistema.md && cd ../../zz-code/python-for-java-devs-20261005-f516 && python3 humo.py op120-sy06-convivir-con-el-sistema.md sy06 'vigilante.py="""Un servicio que convive' 'probar_vigilante.py="""Hacer de systemd' 'supervisord.conf=[supervisord]' --pip supervisor==4.3.0 --cmd 'python probar_vigilante.py; echo ---; timeout 6 supervisord -c supervisord.conf >/dev/null 2>&1; grep -c "error irrecuperable" /tmp/vigilante.log; grep -E "spawned|exited|gave up" /tmp/supervisord.log | sed "s/^[0-9-]* [0-9:,]* //" | head -8' 2>&1 | tail -16

# --- 2026-10-05T19:53:12 · Fill sy06 output, partial-test header, mark 🟡
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs && python3 - <<'EOF'
import pathlib,re
p=pathlib.Path("op120-sy06-convivir-con-el-sistema.md");t=p.read_text()
old=re.search(r"```text\navisos recibidos: \['READY=1', 'STOPPING=1', 'WATCHDOG=1'\] · WATCHDOG: ….*?\n```\n",t,re.S).group(0)
t=t.replace(old,"""```text
avisos recibidos: ['READY=1', 'STOPPING=1', 'WATCHDOG=1'] · WATCHDOG: 5
salida (lo que vería el journal): ['<6>vigilante arrancando', '<6>configuración recargada', '<6>terminando en orden después de 5 ciclos']
código de salida: 0
3
INFO spawned: 'vigilante' with pid 14
WARN exited: vigilante (exit status 1; not expected)
INFO spawned: 'vigilante' with pid 15
WARN exited: vigilante (exit status 1; not expected)
INFO spawned: 'vigilante' with pid 16
```

El servicio avisó que estaba listo, mandó cinco latidos de *watchdog*, recargó la configuración con `SIGHUP` (el intervalo bajó a la mitad, por eso
alcanzó cinco ciclos) y terminó en orden con `SIGTERM`, con código 0, avisando `STOPPING=1`. Su salida son tres líneas con nivel, que es todo lo que el
journal necesita. Y con `AUREA_FALLAR`, supervisord lo vio salir con 1 —"not expected"— y lo volvió a lanzar cada vez: tres errores irrecuperables en
seis segundos, tres reinicios.
""")
p.write_text(t)
EOF
cd ../../zz-code/python-for-java-devs-20261005-f516 && python3 probado.py op120-sy06-convivir-con-el-sistema.md && cd - >/dev/null && python3 - <<'EOF'
import pathlib
p=pathlib.Path("op120-sy06-convivir-con-el-sistema.md");t=p.read_text()
old_start=t.index("> Versiones verificadas contra PyPI el 05/10/2026 · Código probado")
old_end=t.index("\n\n---",old_start)
t=t[:old_start]+"""> Versiones verificadas contra PyPI el 05/10/2026 · Código probado en parte el 05/10/2026 con Python 3.14.7,
> en contenedor: el protocolo `sd_notify`, las señales y supervisord, sí; la unidad de systemd, no (necesita systemd
> como PID 1; es el ejercicio 7)."""+t[old_end:]
p.write_text(t)
EOF
head -9 op120-sy06-convivir-con-el-sistema.md | tail -4; python3 ../../zz-code/python-for-java-devs-20261005-f516/plan.py 120 120 ✅ 🟡 && python3 prompts/verificar-corpus.py | tail -1

# --- 2026-10-05T19:53:20 · Make supervisord restart claim precise
python3 - <<'EOF'
import pathlib
p=pathlib.Path("op120-sy06-convivir-con-el-sistema.md");t=p.read_text()
a="""y lo volvió a lanzar cada vez: tres errores irrecuperables en
seis segundos, tres reinicios."""
assert t.count(a)==1
t=t.replace(a,"""y lo volvió a lanzar: tres salidas con error en los seis segundos
de la prueba, cada una seguida de un proceso nuevo.""")
p.write_text(t)
EOF
grep -c "seguida de un proceso nuevo" op120-sy06-convivir-con-el-sistema.md

# --- 2026-10-05T19:54:24 · Fix dict line and test rsync snapshots
sed -i '' 's/    inodes = {(p.stat().st_ino) : p.stat().st_size for p in path.rglob("\*") if p.is_file()}/    inodes = {p.stat().st_ino: p.stat().st_size for p in path.rglob("*") if p.is_file()}/' op121-sy07-sincronizacion-y-respaldo.md && grep -c 'inodes = {p.stat().st_ino:' op121-sy07-sincronizacion-y-respaldo.md && cd ../../zz-code/python-for-java-devs-20261005-f516 && python3 humo.py op121-sy07-sincronizacion-y-respaldo.md sy07 'respaldo.py=@respaldo.py' --cmd 'apt-get update -qq >/dev/null 2>&1 && apt-get install -y -qq rsync >/dev/null 2>&1; mkdir -p /tmp/t && cp respaldo.py /tmp/t/ && cd /tmp/t && python respaldo.py' 2>&1 | tail -7; cd ../../cursos-algoritmos-lenguajes/python-for-java-devs && python3 ../../zz-code/python-for-java-devs-20261005-f516/verificar_urls.py op121-sy07-sincronizacion-y-respaldo.md | tail -3

# --- 2026-10-05T19:54:41 · Create backups parent dir and rerun sy07
python3 - <<'EOF'
import pathlib
p=pathlib.Path("op121-sy07-sincronizacion-y-respaldo.md");t=p.read_text()
def rep(a,b):
    global t
    assert t.count(a)==1,a
    t=t.replace(a,b)
rep("SRC.mkdir()\n","SRC.mkdir()\nBACKUPS.mkdir()                                              # rsync solo crea el último nivel del destino\n")
rep("""**La barra final de `rsync`.**""","""**El destino cuyo padre no existe.** `rsync` crea la carpeta final del destino, pero no las intermedias: con `respaldos/` inexistente, copiar a
`respaldos/2026-10-04/` termina con código 11 (error de E/S), que fue el primer error de este ejemplo. Se crea el padre antes, o se usa
`--mkpath` (rsync 3.2.3 en adelante); y como siempre, `check=True` para que el fallo no pase en silencio.

**La barra final de `rsync`.**""")
p.write_text(t)
EOF
cd ../../zz-code/python-for-java-devs-20261005-f516 && python3 humo.py op121-sy07-sincronizacion-y-respaldo.md sy07 'respaldo.py=@respaldo.py' --cmd 'apt-get update -qq >/dev/null 2>&1 && apt-get install -y -qq rsync >/dev/null 2>&1; mkdir -p /tmp/t && cp respaldo.py /tmp/t/ && cd /tmp/t && python respaldo.py' 2>&1 | tail -6

# --- 2026-10-05T19:54:49 · Get first output line of sy07
python3 humo.py op121-sy07-sincronizacion-y-respaldo.md sy07 'respaldo.py=@respaldo.py' --cmd 'apt-get update -qq >/dev/null 2>&1 && apt-get install -y -qq rsync >/dev/null 2>&1; mkdir -p /tmp/t && cp respaldo.py /tmp/t/ && cd /tmp/t && python respaldo.py' 2>/dev/null | head -1

# --- 2026-10-05T19:55:07 · Compare source vs backup hashes for changed files
cat > salidas/sy07/sonda.py <<'EOF'
exec(open("respaldo.py").read().split("one_day =")[0])
import hashlib
for name in ("exporte-03.csv", "exporte-07.csv", "exporte-50.csv", "exporte-20.csv"):
    s = hashlib.sha256((SRC / name).read_bytes()).hexdigest()[:8]
    b = hashlib.sha256((BACKUPS / "2026-10-05" / name).read_bytes()).hexdigest()[:8]
    print(name, "origen", s, "respaldo", b, "igual" if s == b else "DISTINTO")
EOF
python3 humo.py op121-sy07-sincronizacion-y-respaldo.md sy07 'respaldo.py=@respaldo.py' --cmd 'apt-get update -qq >/dev/null 2>&1 && apt-get install -y -qq rsync >/dev/null 2>&1; mkdir -p /tmp/t && cp respaldo.py sonda.py /tmp/t/ && cd /tmp/t && python sonda.py' 2>&1 | tail -5

# --- 2026-10-05T19:55:31 · Rewrite sy07 example with source manifest and rerun
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs && python3 - <<'EOF'
import pathlib,re
p=pathlib.Path("op121-sy07-sincronizacion-y-respaldo.md");t=p.read_text()
start=t.index("`respaldo.py`:\n\n```python\n")+len("`respaldo.py`:\n\n```python\n")
end=t.index("```",start)
code='''"""Instantáneas con rsync, manifiesto calculado del origen, la copia que no copió, y el daño compartido por enlaces duros."""

import hashlib
import json
import os
import pathlib
import random
import shutil
import subprocess

SRC, BACKUPS = pathlib.Path("exportes"), pathlib.Path("respaldos")
for d in (SRC, BACKUPS, pathlib.Path("restaurado")):
    shutil.rmtree(d, ignore_errors=True)
SRC.mkdir()
BACKUPS.mkdir()                                              # rsync solo crea el último nivel del destino
random.seed(3)
for i in range(50):
    (SRC / f"exporte-{i:02d}.csv").write_bytes(random.randbytes(100_000))


def sha256(path: pathlib.Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def snapshot(day: str, previous: str | None, checksum: bool = False) -> list[str]:
    target = BACKUPS / day
    shutil.rmtree(target, ignore_errors=True)
    cmd = ["rsync", "-a", "--delete"] + (["--checksum"] if checksum else [])
    if previous:
        cmd.append(f"--link-dest=../{previous}")             # relativo al destino
    manifest = {p.name: sha256(p) for p in sorted(SRC.glob("*.csv"))}    # lo que DEBERÍA quedar respaldado
    subprocess.run([*cmd, f"{SRC}/", f"{target}/"], check=True)
    (target / "manifiesto.json").write_text(json.dumps(manifest))
    return verify(target)


def verify(snapshot_dir: pathlib.Path) -> list[str]:
    manifest = json.loads((snapshot_dir / "manifiesto.json").read_text())
    return [name for name, digest in manifest.items() if sha256(snapshot_dir / name) != digest]


def used_mb(path: pathlib.Path) -> float:
    inodes = {p.stat().st_ino: p.stat().st_size for p in path.rglob("*.csv")}
    return sum(inodes.values()) / 1e6


print("2026-10-04:", snapshot("2026-10-04", None) or "verificada")
for i in (3, 7):                                             # dos exportes cambian (mismo tamaño, mismo segundo)
    (SRC / f"exporte-{i:02d}.csv").write_bytes(random.randbytes(100_000))
(SRC / "exporte-50.csv").write_bytes(random.randbytes(100_000))
print("2026-10-05 con -a:        no coinciden con el origen", snapshot("2026-10-05", "2026-10-04"))
print("2026-10-05 con --checksum: no coinciden con el origen", snapshot("2026-10-05", "2026-10-04", checksum=True))
print(f"las dos instantáneas parecen de {2 * 5.05:.1f} MB y ocupan {used_mb(BACKUPS):.1f} MB")

shutil.copytree(BACKUPS / "2026-10-05", "restaurado")
print("restauración de prueba:", verify(pathlib.Path("restaurado")) or "verificada")

# Un sector del disco de respaldo se daña: un byte de un archivo que no cambió entre los dos días.
victim = BACKUPS / "2026-10-04" / "exporte-20.csv"
data = bytearray(victim.read_bytes())
data[5_000] ^= 0xFF
with open(victim, "r+b") as f:                               # escribir en el mismo inodo, como el daño real
    f.write(data)
for day in ("2026-10-04", "2026-10-05"):
    print(f"verificación de {day}: dañados {verify(BACKUPS / day)}")
print("¿es el mismo archivo en disco?",
      os.path.samefile(BACKUPS / "2026-10-04" / "exporte-20.csv", BACKUPS / "2026-10-05" / "exporte-20.csv"))
'''
t=t[:start]+code+t[end:]
p.write_text(t)
EOF
cd ../../zz-code/python-for-java-devs-20261005-f516 && rm salidas/sy07/sonda.py && python3 humo.py op121-sy07-sincronizacion-y-respaldo.md sy07 'respaldo.py=@respaldo.py' --cmd 'apt-get update -qq >/dev/null 2>&1 && apt-get install -y -qq rsync >/dev/null 2>&1; mkdir -p /tmp/t && cp respaldo.py /tmp/t/ && cd /tmp/t && python respaldo.py' 2>/dev/null | grep -v "^$"

# --- 2026-10-05T19:55:49 · Pin mtimes to reproduce rsync quick-check miss
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs && python3 - <<'EOF'
import pathlib
p=pathlib.Path("op121-sy07-sincronizacion-y-respaldo.md");t=p.read_text()
def rep(a,b):
    global t
    assert t.count(a)==1,a
    t=t.replace(a,b)
rep('''for i in (3, 7):                                             # dos exportes cambian (mismo tamaño, mismo segundo)
    (SRC / f"exporte-{i:02d}.csv").write_bytes(random.randbytes(100_000))''','''for i in (3, 7):                                             # dos exportes cambian, con el mismo tamaño y la misma
    path = SRC / f"exporte-{i:02d}.csv"                      # fecha de modificación: como un cambio en el mismo segundo,
    before = path.stat()                                     # o una herramienta que conserva la fecha al reescribir
    path.write_bytes(random.randbytes(100_000))
    os.utime(path, ns=(before.st_atime_ns, before.st_mtime_ns))''')
p.write_text(t)
EOF
cd ../../zz-code/python-for-java-devs-20261005-f516 && python3 humo.py op121-sy07-sincronizacion-y-respaldo.md sy07 'respaldo.py=@respaldo.py' --cmd 'apt-get update -qq >/dev/null 2>&1 && apt-get install -y -qq rsync >/dev/null 2>&1; mkdir -p /tmp/t && cp respaldo.py /tmp/t/ && cd /tmp/t && python respaldo.py' 2>/dev/null | grep -v "^$"

# --- 2026-10-05T19:56:08 · Fill sy07 output with quick-check finding, mark
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs && python3 - <<'EOF'
import pathlib,re
p=pathlib.Path("op121-sy07-sincronizacion-y-respaldo.md");t=p.read_text()
def rep(a,b):
    global t
    assert t.count(a)==1,a
    t=t.replace(a,b)
old=re.search(r"```text\ncada instantánea parece de 5\.1 MB.*?\n```\n",t,re.S).group(0)
t=t.replace(old,"""```text
2026-10-04: verificada
2026-10-05 con -a:        no coinciden con el origen ['exporte-03.csv', 'exporte-07.csv']
2026-10-05 con --checksum: no coinciden con el origen []
las dos instantáneas parecen de 10.1 MB y ocupan 5.3 MB
restauración de prueba: verificada
verificación de 2026-10-04: dañados ['exporte-20.csv']
verificación de 2026-10-05: dañados ['exporte-20.csv']
¿es el mismo archivo en disco? True
```

La segunda línea es la que da sentido a la sección. Con `rsync -a`, la instantánea del 5 de octubre **no tiene los dos cambios del día**: `rsync`
decide si un archivo cambió mirando el tamaño y la fecha de modificación, y estos dos tenían los mismos; los dio por iguales y enlazó la versión
vieja. El proceso terminó sin errores, y solo la verificación contra el manifiesto **del origen** lo detectó. Con `--checksum`, que compara el
contenido, la instantánea queda bien. Las dos instantáneas ocupan 5,3 MB en vez de 10,1. Y el final: el byte dañado en el respaldo del 4 de octubre
aparece también en el del 5, porque es el mismo archivo en el disco.
""")
rep("""- **El manifiesto se guarda dentro de la instantánea**, calculado en el momento del respaldo. Verificar es volver a calcular y comparar.""","""- **El manifiesto se calcula del origen**, en el momento del respaldo, y se guarda dentro de la instantánea. Verificar es calcular el *hash* de lo
  respaldado y comparar. La primera versión de este ejemplo calculaba el manifiesto **de la instantánea**, y por eso certificaba como correcta una
  copia a la que le faltaban los cambios: un manifiesto de lo que se copió no prueba que se copió lo que había.
- **`os.utime`** deja en los archivos cambiados la fecha que tenían: simula un cambio en el mismo segundo, o una herramienta que conserva la fecha al
  reescribir. En la primera corrida pasó sin forzarlo, porque todo ocurrió dentro del mismo segundo; en la siguiente, no. Es un error que depende del
  reloj, que es la peor clase.""")
rep("""**`--delete` apuntando al lugar equivocado.**""","""**La comparación rápida de `rsync`.** Por defecto, `rsync` da por igual un archivo con el mismo tamaño y la misma fecha de modificación, sin leer el
contenido. Un exporte que se regenera en el mismo segundo, con el mismo tamaño, no se respalda, y el respaldo termina sin errores. `--checksum` lee y
compara todo (más lento), y la verificación contra el manifiesto del origen lo detecta en cualquier caso.

**`--delete` apuntando al lugar equivocado.**""")
p.write_text(t)
EOF
cd ../../zz-code/python-for-java-devs-20261005-f516 && python3 probado.py op121-sy07-sincronizacion-y-respaldo.md && python3 plan.py 121 121 ✅ ✅ && cd - >/dev/null && python3 prompts/verificar-corpus.py | tail -1

# --- 2026-10-05T19:56:15 · Update exercise 1 figures in sy07
grep -n "5,4 MB\|5.4 MB" op121-sy07-sincronizacion-y-respaldo.md; sed -i '' 's/explicas los 5,4 MB y por qué el daño aparece en los dos días\./explicas los 5,3 MB, por qué `-a` no copió dos cambios, y por qué el daño aparece en los dos días./' op121-sy07-sincronizacion-y-respaldo.md && grep -c "explicas los 5,3 MB" op121-sy07-sincronizacion-y-respaldo.md

# --- 2026-10-05T19:57:08 · Smoke-test shell vs Python comparison
cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516 && python3 humo.py op122-sy08-veredicto.md sy08 'ingenuo.sh=for f in $(ls entrada)' 'cuidadoso.sh=set -euo pipefail' 'contar.py=@contar.py' --cmd 'python contar.py' 2>&1 | tail -7; cd ../../cursos-algoritmos-lenguajes/python-for-java-devs && python3 ../../zz-code/python-for-java-devs-20261005-f516/verificar_urls.py op122-sy08-veredicto.md | tail -2

# --- 2026-10-05T19:57:25 · Fill sy08 output with careful-bash finding, mark
python3 - <<'EOF'
import pathlib
p=pathlib.Path("op122-sy08-veredicto.md");t=p.read_text()
def rep(a,b):
    global t
    assert t.count(a)==1,a
    t=t.replace(a,b)
rep("""python:      correcto
ingenuo.sh   … de 4 lotes bien · código … · errores: … líneas
cuidadoso.sh 4 de 4 lotes bien · código 0 · errores: 0 líneas
tubería con error sin pipefail: código 0 · ['0', 'siguió', 'como', 'si', 'nada']
tubería con error con pipefail: código 1 · […]
```
""","""python:      correcto
ingenuo.sh   2 de 4 lotes bien · código 0 · errores: 4 líneas
cuidadoso.sh 3 de 4 lotes bien · código 0 · errores: 0 líneas
tubería con error sin pipefail: código 0 · ['0', 'siguió', 'como', 'si', 'nada']
tubería con error con pipefail: código 1 · ['0']
```

Python contó bien los cuatro lotes sin hacer nada especial. El bash ingenuo contó bien dos, imprimió cuatro líneas de error y **terminó con código 0**:
el cron lo habría dado por exitoso. Y el bash cuidadoso, con todos sus trucos, contó bien **tres**: el lote con un salto de línea en el nombre lo rompió
el `sort` del final, que ordena líneas y partió ese nombre en dos. Arreglarlo exige un séptimo truco (`printf '%s\\0'` y `sort -z`). La última pareja de
líneas es la otra mitad del veredicto: sin `pipefail`, una tubería cuyo primer comando falla termina con código 0 y el script sigue; con `pipefail`, se
detiene.
""")
rep("""- **La versión cuidadosa funciona**, y para escribirla hace falta saber `-print0`, `IFS=`, `read -r -d ''`, las comillas dobles y `--`. Cada una corrige un
  incidente distinto; olvidar una reabre el incidente.""","""- **La versión cuidadosa casi funciona**, y para escribirla hace falta saber `-print0`, `IFS=`, `read -r -d ''`, las comillas dobles y `--`. Cada una corrige un
  incidente distinto; olvidar una reabre el incidente —y el `sort` del final, que el borrador de esta sección daba por inofensivo, era la que faltaba—.""")
rep("""bash cuidadoso funciona y exige saber seis trucos, y Python lo hace bien sin saber ninguno.""","""bash cuidadoso falla con un nombre de los cuatro aunque aplica seis trucos, y Python lo hace bien sin saber ninguno.""")
p.write_text(t)
EOF
cd ../../zz-code/python-for-java-devs-20261005-f516 && python3 probado.py op122-sy08-veredicto.md && python3 plan.py 122 122 ✅ ✅ && cd - >/dev/null && python3 prompts/verificar-corpus.py | tail -1

# --- 2026-10-05T19:57:42 · Close T15 in plan, log entry, update memory
python3 prompts/check-inventario.py sy | tail -1 && for kv in plumbum:2.0.2 sh:2.4.0 invoke:3.0.3 psutil:7.2.2 watchdog:6.0.0 filelock:4.0.12 supervisor:4.3.0; do k=${kv%%:*}; v=${kv#*:}; grep -q "| \`$k\` | $v |" prompts/inventario-verificado.md || echo "CAMBIÓ $k: $(grep "| \`$k\` |" prompts/inventario-verificado.md|head -1)"; done; cd ../../zz-code/python-for-java-devs-20261005-f516 && python3 plan.py tanda T15 ✅ && python3 plan.py dondeesta "T1–T15 cerradas (122 de 176). Sigue T16 pr (op123)." && cd - >/dev/null && n=$(for f in op11[5-9]*.md op12[0-2]*.md; do grep -o "Ejercicios ([0-9]*)" $f; done | grep -o "[0-9]*" | paste -sd+ - | bc) && echo "ejercicios=$n" && python3 - "$n" <<'EOF'
import pathlib,sys
p=pathlib.Path("prompts/plan-de-produccion-carta.md");t=p.read_text()
anchor="## 7. 📓 Bitácora\n\n"
entry=(f"**2026-10-05 · T15 (`sy`) cerrada.** Escritas op115–op122 (8 secciones, {sys.argv[1]} ejercicios); siete probadas en contenedor y "
"**sy06 en parte** (🟡: `sd_notify`, señales y supervisord, sí; la unidad de systemd necesita systemd como PID 1 y queda para T24). "
"**Hallazgos y defectos propios:** `run(timeout=)` deja huérfanos **los dos** `sleep` de `sh`, no uno (sy01); sh cuesta 2,47 ms por llamada "
"contra 0,26 de `subprocess` (sy02); 61 archivos antes de `EMFILE` con límite 64 (sy03); **Python 3.14 usa `forkserver` por defecto y un "
"*script* con `multiprocessing` sin guarda `__main__` falla con `ConnectionResetError`**; la escritura ingenua rompió 20 de 20 archivos y la "
"atómica 0; sin bloqueo, el contador terminó en 4–6 de 1 000 porque las lecturas encuentran el archivo recién truncado (sy04); `watchdog` "
"entrega `created` dos veces y con una fila, y el renombrado hace que hasta `created` llegue completo (sy05); supervisord relanza en cada "
"salida con error (sy06); **`rsync -a` no copió dos cambios de mismo tamaño y misma fecha**, y el manifiesto calculado de la instantánea lo "
"certificaba: se pasó a manifiesto del origen y `--checksum`; `rsync` no crea directorios intermedios (código 11) (sy07); el bash cuidadoso "
"también falló, en el `sort` con un nombre con salto de línea (sy08). **URL:** psutil se mudó a psutil.io; freedesktop.org responde 418 "
"(reemplazado por man7.org, como en T1). **Inventario:** ninguna versión probada cambió.\n\n")
t=t.replace(anchor,anchor+entry,1)
p.write_text(t)
EOF
M=/Users/oskar/.claude/projects/-Users-oskar-Developer-Learning-courses-ia-generated/memory; sed -i '' 's/T1–T14 cerradas el 05\/10\/2026: 114 de 176; sigue T15 sy\./T1–T15 cerradas el 05\/10\/2026: 122 de 176; sigue T16 pr./' $M/MEMORY.md && grep -c "122 de 176" $M/MEMORY.md

# --- 2026-10-05T19:57:54 · Read pr track rows and proposal
grep -n "| op12[3-9] .*\`op12[0-9]-pr\|| op13[0-9] .*\`op13[0-9]-pr" prompts/plan-de-produccion-carta.md; n=$(grep -n "Track \`pr\`" prompts/propuestas-temas-opcionales.md | head -1 | cut -d: -f1); sed -n "${n},$((n+32))p" prompts/propuestas-temas-opcionales.md; sed -n '/"pr"/,/\],/p' prompts/check-inventario.py

# --- 2026-10-05T19:58:06 · Look up pr track package versions
for k in grpcio grpcio-tools betterproto protobuf fastavro msgspec msgpack cbor2 orjson strawberry-graphql ariadne graphene websockets sse-starlette paho-mqtt pika aio-pika nats-py schemathesis pact-python datamodel-code-generator jsonschema pydantic; do grep -m1 "| \`$k\` |" prompts/inventario-verificado.md || echo "falta $k"; done

# --- 2026-10-05T19:58:57 · Smoke-test contract evolution example
cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516 && python3 humo.py op123-pr01-el-eje.md pr01 'v1/cita.proto=@v1/cita.proto' 'v2/cita.proto=@v2/cita.proto' 'eje.py=@eje.py' --pip pydantic==2.13.5 grpcio-tools==1.84.0 protobuf==7.36.2 --cmd 'python -m grpc_tools.protoc -I v1 --python_out=v1 v1/cita.proto && python -m grpc_tools.protoc -I v2 --python_out=v2 v2/cita.proto && python eje.py; pip list 2>/dev/null | grep -i "^protobuf"' 2>&1 | tail -8

# --- 2026-10-05T19:59:08 · Label v2 proto block and rerun pr01
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs && python3 - <<'EOF'
import pathlib
p=pathlib.Path("op123-pr01-el-eje.md");t=p.read_text()
a="""`v2/cita.proto` —el cambio del viernes, hecho con las reglas del formato: el campo 1 cambia de nombre, y el identificador numérico es un campo
**nuevo**, el 3—:
"""
assert t.count(a)==1
t=t.replace(a,"""El cambio del viernes, hecho con las reglas del formato: el campo 1 cambia de nombre, y el identificador numérico es un campo **nuevo**, el 3.
`v2/cita.proto`:
""")
p.write_text(t)
EOF
cd ../../zz-code/python-for-java-devs-20261005-f516 && python3 humo.py op123-pr01-el-eje.md pr01 'v1/cita.proto=@v1/cita.proto' 'v2/cita.proto=@v2/cita.proto' 'eje.py=@eje.py' --pip pydantic==2.13.5 grpcio-tools==1.84.0 protobuf==7.36.2 --cmd 'python -m grpc_tools.protoc -I v1 --python_out=v1 v1/cita.proto && python -m grpc_tools.protoc -I v2 --python_out=v2 v2/cita.proto && python eje.py; pip list 2>/dev/null | grep -i "^protobuf"' 2>&1 | tail -8

# --- 2026-10-05T19:59:31 · Add proto packages and rerun pr01
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs && python3 - <<'EOF'
import pathlib
p=pathlib.Path("op123-pr01-el-eje.md");t=p.read_text()
def rep(a,b):
    global t
    assert t.count(a)==1,a
    t=t.replace(a,b)
rep('''syntax = "proto3";
message CitaConfirmada {
  string sede = 1;''','''syntax = "proto3";
package aurea.v1;
message CitaConfirmada {
  string sede = 1;''')
rep('''syntax = "proto3";
message CitaConfirmada {
  string sede_nombre = 1;''','''syntax = "proto3";
package aurea.v2;
message CitaConfirmada {
  string sede_nombre = 1;''')
rep('''python -m grpc_tools.protoc -I v1 --python_out=v1 v1/cita.proto
python -m grpc_tools.protoc -I v2 --python_out=v2 v2/cita.proto''','''python -m grpc_tools.protoc -I . --python_out=. v1/cita.proto v2/cita.proto''')
rep("""**La versión del código generado.**""","""**Dos versiones del mismo archivo en un proceso.** Protobuf registra cada archivo y cada mensaje en un *pool* global del proceso: dos `cita.proto`
generados con `-I v1` y `-I v2` se llaman igual adentro, y el segundo `import` falla con `duplicate file name cita.proto`, que fue el primer error de
este ejemplo. Las versiones conviven con un `package` distinto (`aurea.v1`, `aurea.v2`) y generando desde la raíz, para que la ruta forme parte del
nombre.

**La versión del código generado.**""")
p.write_text(t)
EOF
cd ../../zz-code/python-for-java-devs-20261005-f516 && rm -f salidas/pr01/v1/*_pb2.py salidas/pr01/v2/*_pb2.py && python3 humo.py op123-pr01-el-eje.md pr01 'v1/cita.proto=@v1/cita.proto' 'v2/cita.proto=@v2/cita.proto' 'eje.py=@eje.py' --pip pydantic==2.13.5 grpcio-tools==1.84.0 protobuf==7.36.2 --cmd 'python -m grpc_tools.protoc -I . --python_out=. v1/cita.proto v2/cita.proto && python eje.py' 2>&1 | tail -6

# --- 2026-10-05T19:59:46 · Fill byte count, mark pr01, verify
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs && sed -i '' "s/^protobuf:  el lector v1 lee sede='Suba', hora='09:00' · … bytes en el cable$/protobuf:  el lector v1 lee sede='Suba', hora='09:00' · 15 bytes en el cable/" op123-pr01-el-eje.md && grep -c "15 bytes en el cable" op123-pr01-el-eje.md && cd ../../zz-code/python-for-java-devs-20261005-f516 && python3 probado.py op123-pr01-el-eje.md && python3 plan.py 123 123 ✅ ✅ && cd - >/dev/null && python3 ../../zz-code/python-for-java-devs-20261005-f516/verificar_urls.py op123-pr01-el-eje.md | tail -2 && python3 prompts/verificar-corpus.py | tail -1

# --- 2026-10-05T20:00:41 · Smoke-test gRPC service and client
cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516 && python3 humo.py op124-pr02-grpc-y-protobuf.md pr02 'agenda.proto=@agenda.proto' 'agenda.py=@agenda.py' --pip grpcio==1.84.0 grpcio-tools==1.84.0 protobuf==7.36.2 --cmd 'python -m grpc_tools.protoc -I . --python_out=. --grpc_python_out=. agenda.proto && python agenda.py' 2>&1 | tail -6; cd ../../cursos-algoritmos-lenguajes/python-for-java-devs && python3 ../../zz-code/python-for-java-devs-20261005-f516/verificar_urls.py op124-pr02-grpc-y-protobuf.md | tail -2

# --- 2026-10-05T20:00:46 · Rerun pr02 with content prefix
cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516 && python3 humo.py op124-pr02-grpc-y-protobuf.md pr02 'agenda.proto=@agenda.proto' 'agenda.py="""Un servicio gRPC de prueba' --pip grpcio==1.84.0 grpcio-tools==1.84.0 protobuf==7.36.2 --cmd 'python -m grpc_tools.protoc -I . --python_out=. --grpc_python_out=. agenda.proto && python agenda.py' 2>&1 | tail -6

# --- 2026-10-05T20:00:59 · Fill gRPC timing, mark pr02
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs && sed -i '' 's/^500 llamadas unarias: … ms por llamada$/500 llamadas unarias: 0.53 ms por llamada/' op124-pr02-grpc-y-protobuf.md && grep -c "0.53 ms por llamada" op124-pr02-grpc-y-protobuf.md && cd ../../zz-code/python-for-java-devs-20261005-f516 && python3 probado.py op124-pr02-grpc-y-protobuf.md && python3 plan.py 124 124 ✅ ✅ && cd - >/dev/null && python3 prompts/verificar-corpus.py | tail -1

# --- 2026-10-05T20:01:53 · Run seven-codec benchmark
cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516 && python3 humo.py op125-pr03-formatos-binarios.md pr03 'evento.proto=@evento.proto' 'formatos.py=@formatos.py' --pip orjson==3.12.0 msgspec==0.22.0 msgpack==1.2.3 cbor2==6.1.5 protobuf==7.36.2 grpcio-tools==1.84.0 fastavro==1.12.2 --cmd 'python -m grpc_tools.protoc -I . --python_out=. evento.proto && python formatos.py' 2>&1 | tail -14; cd ../../cursos-algoritmos-lenguajes/python-for-java-devs && python3 ../../zz-code/python-for-java-devs-20261005-f516/verificar_urls.py op125-pr03-formatos-binarios.md | tail -2

# --- 2026-10-05T20:02:09 · Find current msgspec docs URL
for u in https://jcristharif.com/msgspec/benchmarks.html https://msgspec.dev/benchmarks.html https://jcristharif.com/msgspec/ https://github.com/jcrist/msgspec; do echo "$(curl -s -o /dev/null -w '%{http_code} %{url_effective}' -L -m 20 "$u") <- $u"; done

# --- 2026-10-05T20:02:22 · Fill pr03 results, fix URL, mark
python3 - <<'EOF'
import pathlib,re
p=pathlib.Path("op125-pr03-formatos-binarios.md");t=p.read_text()
def rep(a,b):
    global t
    assert t.count(a)==1,a
    t=t.replace(a,b)
rep("- `msgspec`, comparación de rendimiento: https://jcristharif.com/msgspec/benchmarks.html","- `msgspec`, comparación de rendimiento: https://msgspec.dev/benchmarks")
old=re.search(r"```text\nformato              bytes   ida y vuelta\njson \(estándar\)        ….*?\n```\n",t,re.S).group(0)
t=t.replace(old,"""```text
formato              bytes   ida y vuelta
json (estándar)  1,039,069        12.8 ms
orjson             939,070         4.8 ms
msgspec json       939,070         2.9 ms
msgspec msgpack    699,308         2.6 ms
msgpack            699,308         7.2 ms
cbor2              699,308        16.8 ms
protobuf           369,681         8.7 ms
avro (fastavro)    300,361        24.0 ms
una fecha en json   → TypeError: Object of type datetime is not JSON serializable
una fecha en orjson → b'{"m":"2026-10-05T07:00:00+00:00"}'
una fecha en cbor2  → datetime.datetime(2026, 10, 5, 7, 0, tzinfo=datetime.timezone.utc)
```

La tabla confirma la conclusión adelantada y agrega una sorpresa. Pasar de `json` a `orjson` divide el tiempo por 2,7 sin cambiar un byte del contrato, y
`msgspec` lo divide por 4,4 —y además valida—. Los binarios sin esquema ahorran un tercio del tamaño; con esquema, Protobuf y Avro ocupan entre un tercio y
algo menos de un tercio de lo que ocupa JSON. La sorpresa es el tiempo: **Protobuf en Python es más lento que `orjson`** (8,7 contra 4,8 ms), porque construir
diez mil objetos de mensaje desde diccionarios cuesta, y Avro, el más compacto, es el más lento de todos. En Python, los formatos con esquema se eligen por
el contrato y el tamaño, no por la velocidad.
""")
t=t.replace("Salida esperada, sin correr (los milisegundos son de la máquina que corre):","Salida esperada, sin correr (los milisegundos son de la máquina que corre; estos, de un contenedor en un portátil, el mejor de tres):")
p.write_text(t)
EOF
cd ../../zz-code/python-for-java-devs-20261005-f516 && python3 probado.py op125-pr03-formatos-binarios.md && python3 plan.py 125 125 ✅ ✅ && cd - >/dev/null && python3 ../../zz-code/python-for-java-devs-20261005-f516/verificar_urls.py op125-pr03-formatos-binarios.md | tail -1 && python3 prompts/verificar-corpus.py | tail -1

# --- 2026-10-05T20:03:17 · Smoke-test Strawberry N+1 and DataLoader
cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516 && python3 humo.py op126-pr04-graphql.md pr04 'portal.py=@portal.py' --pip strawberry-graphql==0.331.2 --cmd 'python portal.py' 2>&1 | tail -6; cd ../../cursos-algoritmos-lenguajes/python-for-java-devs && python3 ../../zz-code/python-for-java-devs-20261005-f516/verificar_urls.py op126-pr04-graphql.md | tail -2

# --- 2026-10-05T20:03:30 · Fill pr04 output, mark, verify
python3 - <<'EOF'
import pathlib
p=pathlib.Path("op126-pr04-graphql.md");t=p.read_text()
a="""sin DataLoader: … consultas a la base · 2 sedes, 30 planes · total $…
con DataLoader:  4 consultas a la base · 2 sedes, 30 planes · total $…
[…]
```
"""
assert t.count(a)==1
t=t.replace(a,"""sin DataLoader: 33 consultas a la base · 2 sedes, 30 planes · total $195,250,000
con DataLoader:  4 consultas a la base · 2 sedes, 30 planes · total $195,250,000
['type Fase {', '  valor: Int!', '}']
```

La misma consulta, la misma respuesta, y 33 consultas a la base contra 4. Sin `DataLoader`: una para las sedes, una por sede para sus planes (2) y una por
plan para sus fases (30). Con él, las 30 del último nivel se volvieron una sola con `IN (…)`. Las tres líneas finales son el comienzo del esquema en SDL,
generado desde las clases: el contrato que se publica.
""")
p.write_text(t)
EOF
cd ../../zz-code/python-for-java-devs-20261005-f516 && python3 probado.py op126-pr04-graphql.md && python3 plan.py 126 126 ✅ ✅ && cd - >/dev/null && python3 prompts/verificar-corpus.py | tail -1

# --- 2026-10-05T20:04:25 · Smoke-test SSE resume and WebSocket broadcast
cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516 && python3 humo.py op127-pr05-tiempo-real.md pr05 'tiempo_real.py=@tiempo_real.py' --pip fastapi==0.142.2 uvicorn==0.54.0 sse-starlette==3.5.0 websockets==17.2 httpx==0.28.1 --cmd 'timeout 60 python tiempo_real.py' 2>&1 | tail -8; cd ../../cursos-algoritmos-lenguajes/python-for-java-devs && python3 ../../zz-code/python-for-java-devs-20261005-f516/verificar_urls.py op127-pr05-tiempo-real.md | tail -2

# --- 2026-10-05T20:04:38 · Mark pr05 tested and verify
cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516 && python3 probado.py op127-pr05-tiempo-real.md && python3 plan.py 127 127 ✅ ✅ && cd - >/dev/null && python3 prompts/verificar-corpus.py | tail -1

# --- 2026-10-05T20:04:48 · Check RabbitMQ tags; add jsonschema to inventory
curl -s "https://hub.docker.com/v2/repositories/library/rabbitmq/tags?page_size=20&ordering=last_updated" | python3 -c "import json,sys; print([t['name'] for t in json.load(sys.stdin)['results'] if 'alpine' in t['name']][:8])"; cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs && sed -i '' 's/           "pact-python", "datamodel-code-generator"\],/           "pact-python", "datamodel-code-generator", "jsonschema", "PyYAML"],/' prompts/check-inventario.py && python3 prompts/check-inventario.py pr | tail -1 && grep -m1 "| \`jsonschema\`" prompts/inventario-verificado.md

# --- 2026-10-05T20:05:42 · List RabbitMQ image tags
curl -s "https://hub.docker.com/v2/repositories/library/rabbitmq/tags?page_size=40&ordering=last_updated" | python3 -c "import json,sys; print([t['name'] for t in json.load(sys.stdin)['results']][:30])"

# --- 2026-10-05T20:05:48 · Pull RabbitMQ image and record it
echo "rabbitmq:4.3.6-alpine" >> /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516/salidas/imagenes-bajadas.txt; docker image inspect rabbitmq:4.3.6-alpine >/dev/null 2>&1 && echo ya-estaba || docker pull -q rabbitmq:4.3.6-alpine

# --- 2026-10-05T20:06:50 · Smoke-test AsyncAPI contract with RabbitMQ
cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516 && python3 humo_servicio.py op128-pr06-mensajeria-como-contrato.md pr06 'asyncapi.yaml=@asyncapi.yaml' 'contrato.py=@contrato.py' --svc rabbit=rabbitmq:4.3.6-alpine --pip aio-pika==10.1.0 jsonschema==4.26.0 PyYAML==6.0.3 --cmd 'timeout 120 python contrato.py' 2>&1 | tail -8; docker ps -a --filter label=curso=python-for-java-devs --format '{{.Names}}'

# --- 2026-10-05T20:07:09 · Declare durable queues and rerun pr06
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs && python3 - <<'EOF'
import pathlib
p=pathlib.Path("op128-pr06-mensajeria-como-contrato.md");t=p.read_text()
def rep(a,b):
    global t
    assert t.count(a)==1,a
    t=t.replace(a,b)
rep('''        exchange = await ch.declare_exchange("agenda", aio_pika.ExchangeType.TOPIC)
        dead = await ch.declare_exchange("agenda.muertos", aio_pika.ExchangeType.FANOUT)
        invalid_q = await ch.declare_queue("citas.invalidas")
        await invalid_q.bind(dead)
        queue = await ch.declare_queue("recordatorios", arguments={"x-dead-letter-exchange": "agenda.muertos"})''','''        exchange = await ch.declare_exchange("agenda", aio_pika.ExchangeType.TOPIC, durable=True)
        dead = await ch.declare_exchange("agenda.muertos", aio_pika.ExchangeType.FANOUT, durable=True)
        invalid_q = await ch.declare_queue("citas.invalidas", durable=True)       # RabbitMQ 4: colas durables
        await invalid_q.bind(dead)
        queue = await ch.declare_queue("recordatorios", durable=True,
                                       arguments={"x-dead-letter-exchange": "agenda.muertos"})''')
rep("""**El contrato que solo valida el productor.**""","""**Las colas no durables en RabbitMQ 4.** `declare_queue("x")` sin `durable=True` declara una cola transitoria y compartida, y RabbitMQ 4.3 ya no las
permite por defecto: la conexión se cierra con `INTERNAL_ERROR - Feature transient_nonexcl_queues is deprecated`, que fue el primer error de este ejemplo. El
código de casi todos los tutoriales tiene esa línea. Las colas compartidas se declaran durables (o exclusivas, si son de una sola conexión).

**El contrato que solo valida el productor.**""")
p.write_text(t)
EOF
cd ../../zz-code/python-for-java-devs-20261005-f516 && python3 humo_servicio.py op128-pr06-mensajeria-como-contrato.md pr06 'asyncapi.yaml=@asyncapi.yaml' 'contrato.py=@contrato.py' --svc rabbit=rabbitmq:4.3.6-alpine --pip aio-pika==10.1.0 jsonschema==4.26.0 PyYAML==6.0.3 --cmd 'timeout 120 python contrato.py' 2>&1 | tail -6; docker ps -a --filter label=curso=python-for-java-devs --format '{{.Names}}'

# --- 2026-10-05T20:07:24 · Fill pr06 output, mark, verify
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs && python3 - <<'EOF'
import pathlib,re
p=pathlib.Path("op128-pr06-mensajeria-como-contrato.md");t=p.read_text()
old=re.search(r"```text\nproductor no publica 102: \[.*?\n```\n",t,re.S).group(0)
t=t.replace(old,"""```text
productor no publica 102: ["sede: 'Bogotá' is not one of ['Centro', 'Chapinero', 'Suba', 'Kennedy', 'Usaquén', 'Engativá', 'Fontibón', 'Restrepo', 'Soacha', 'Zipaquirá']", "hora: '9am' does not match '^([01][0-9]|2[0-3]):[0-5][0-9]$'"]
consumidor procesa 101: recordatorio para Suba a las 09:00
consumidor rechaza 103: ["(raíz): 'sede' is a required property", "(raíz): 'hora' is a required property", "(raíz): Additional properties are not allowed ('sede_id' was unexpected)"]
en citas.invalidas: {"cita": 103, "sede_id": 3} · motivo: rejected
```

El productor que respeta el contrato no publicó la cita 102 y dijo por qué: sede inexistente, hora en otro formato. La 101 llegó y se procesó. La 103, del
productor viejo, llegó porque nadie la validó al salir; el consumidor la rechazó con tres motivos, y RabbitMQ la llevó a `citas.invalidas` con la cabecera
`x-death` que dice que fue rechazada. Nada se perdió y nada se atascó.
""")
p.write_text(t)
EOF
cd ../../zz-code/python-for-java-devs-20261005-f516 && python3 probado.py op128-pr06-mensajeria-como-contrato.md && python3 plan.py 128 128 ✅ ✅ && cd - >/dev/null && python3 ../../zz-code/python-for-java-devs-20261005-f516/verificar_urls.py op128-pr06-mensajeria-como-contrato.md | tail -2 && python3 prompts/verificar-corpus.py | tail -1

# --- 2026-10-05T20:08:20 · Run schemathesis against API and breaking check
cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516 && python3 humo.py op129-pr07-versionado-de-contratos.md pr07 'cartera_api.py=@cartera_api.py' 'romper.py=@romper.py' --pip fastapi==0.142.2 uvicorn==0.54.0 schemathesis==4.29.3 --cmd 'uvicorn cartera_api:app --port 8141 --log-level error & sleep 3; schemathesis run http://127.0.0.1:8141/openapi.json --checks not_a_server_error --max-examples 200 2>&1 | tail -25; echo "exit=$?"; python romper.py' 2>&1 | tail -34; cd ../../cursos-algoritmos-lenguajes/python-for-java-devs && python3 ../../zz-code/python-for-java-devs-20261005-f516/verificar_urls.py op129-pr07-versionado-de-contratos.md | tail -2

# --- 2026-10-05T20:08:26 · Rerun pr07 with content prefix
cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516 && python3 humo.py op129-pr07-versionado-de-contratos.md pr07 'cartera_api.py="""La API de cartera' 'romper.py=@romper.py' --pip fastapi==0.142.2 uvicorn==0.54.0 schemathesis==4.29.3 --cmd 'uvicorn cartera_api:app --port 8141 --log-level error & sleep 3; schemathesis run http://127.0.0.1:8141/openapi.json --checks not_a_server_error --max-examples 200 2>&1 | tail -28; python romper.py' 2>&1 | tail -36

# --- 2026-10-05T20:08:32 · Run pr07 with both content prefixes
python3 humo.py op129-pr07-versionado-de-contratos.md pr07 'cartera_api.py="""La API de cartera' 'romper.py="""¿La versión nueva' --pip fastapi==0.142.2 uvicorn==0.54.0 schemathesis==4.29.3 --cmd 'uvicorn cartera_api:app --port 8141 --log-level error & sleep 3; schemathesis run http://127.0.0.1:8141/openapi.json --checks not_a_server_error --max-examples 200 2>&1 | tail -28; python romper.py' 2>&1 | tail -36

# --- 2026-10-05T20:09:01 · Capture clean schemathesis report
python3 humo.py op129-pr07-versionado-de-contratos.md pr07 'cartera_api.py="""La API de cartera' 'romper.py="""¿La versión nueva' --pip fastapi==0.142.2 uvicorn==0.54.0 schemathesis==4.29.3 --cmd 'uvicorn cartera_api:app --port 8141 --log-level critical > uvicorn.log 2>&1 & sleep 3; schemathesis run http://127.0.0.1:8141/openapi.json --checks not_a_server_error --max-examples 200 > st.log 2>&1; echo "exit=$?"; cat st.log | tail -30; python romper.py' 2>/dev/null | tail -40

# --- 2026-10-05T20:09:29 · Fill pr07 output excerpt, mark, verify
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs && python3 - <<'EOF'
import pathlib,re
p=pathlib.Path("op129-pr07-versionado-de-contratos.md");t=p.read_text()
old=re.search(r"```text\n… \(el informe de schemathesis.*?\n```\n",t,re.S).group(0)
t=t.replace(old,"""```text
    `Internal Server Error`

Reproduce with:

    curl -X GET 'http://127.0.0.1:8141/cuotas?saldo=1&cuota=0'
…
Failures:
  ❌ Server error: 1

Test cases:
  24 generated, 1 found 1 unique failures
…
[
 "GET /cuotas: parámetro obligatorio nuevo 'sede'",
 "GET /cuotas: la respuesta ya no trae 'cuotas'"
]
```

`schemathesis` generó 24 peticiones válidas según el OpenAPI, encontró la que da 500 —`cuota=0`, que el contrato permite— y terminó con código 1, que hace
fallar el CI. Además entrega el `curl` que la reproduce. El comparador, por su lado, encontró los dos cambios de la v2 que romperían a los clientes de la v1.
""")
t=t.replace("Salida esperada, sin correr:\n\n```text\n    `Internal","Salida esperada, sin correr (fragmentos del informe de `schemathesis`, y la salida de `romper.py`):\n\n```text\n    `Internal")
p.write_text(t)
EOF
cd ../../zz-code/python-for-java-devs-20261005-f516 && python3 probado.py op129-pr07-versionado-de-contratos.md && python3 plan.py 129 129 ✅ ✅ && cd - >/dev/null && grep -n "^Salida" op129-pr07-versionado-de-contratos.md && python3 prompts/verificar-corpus.py | tail -1

# --- 2026-10-05T20:10:11 · Smoke-test pr08 decision function
cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516 && python3 humo.py op130-pr08-veredicto.md pr08 'protocolo.py="""¿REST o una' --cmd 'python protocolo.py' 2>/dev/null | grep -v "^$"; cd ../../cursos-algoritmos-lenguajes/python-for-java-devs && python3 ../../zz-code/python-for-java-devs-20261005-f516/verificar_urls.py op130-pr08-veredicto.md | tail -2

# --- 2026-10-05T20:10:19 · Mark pr08, refresh pr inventory, compare versions
cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516 && python3 probado.py op130-pr08-veredicto.md && python3 plan.py 130 130 ✅ ✅ && cd ../../cursos-algoritmos-lenguajes/python-for-java-devs && python3 prompts/verificar-corpus.py | tail -1 && python3 prompts/check-inventario.py pr | tail -1 && for kv in grpcio:1.84.0 grpcio-tools:1.84.0 protobuf:7.36.2 orjson:3.12.0 msgspec:0.22.0 msgpack:1.2.3 cbor2:6.1.5 strawberry-graphql:0.331.2 websockets:17.2 sse-starlette:3.5.0 aio-pika:10.1.0 jsonschema:4.26.0 schemathesis:4.29.3; do k=${kv%%:*}; v=${kv#*:}; grep -q "| \`$k\` | $v |" prompts/inventario-verificado.md || echo "CAMBIÓ $k: $(grep "| \`$k\` |" prompts/inventario-verificado.md|head -1)"; done; echo revisado

# --- 2026-10-05T20:10:49 · Retest pr04 with Strawberry 0.331.5
cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516 && python3 humo.py op126-pr04-graphql.md pr04 'portal.py=@portal.py' --pip strawberry-graphql==0.331.5 --cmd 'python portal.py' 2>/dev/null | grep -v "^$" && cd ../../cursos-algoritmos-lenguajes/python-for-java-devs && sed -i '' 's/| Strawberry | 0.331.2 | \*\*Clases con anotaciones de tipo\*\* (`@strawberry.type`) |/| Strawberry | 0.331.5 | **Clases con anotaciones de tipo** (`@strawberry.type`) |/' op126-pr04-graphql.md && grep -c "0.331.5" op126-pr04-graphql.md

# --- 2026-10-05T20:11:06 · Close T16 in plan, log entry, update memory
cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516 && python3 plan.py tanda T16 ✅ && python3 plan.py dondeesta "T1–T16 cerradas (130 de 176). Sigue T17 pk (op131)." && cd ../../cursos-algoritmos-lenguajes/python-for-java-devs && n=$(for f in op12[3-9]*.md op130*.md; do grep -o "Ejercicios ([0-9]*)" $f; done | grep -o "[0-9]*" | paste -sd+ - | bc) && echo "ejercicios=$n" && python3 - "$n" <<'EOF'
import pathlib,sys
p=pathlib.Path("prompts/plan-de-produccion-carta.md");t=p.read_text()
anchor="## 7. 📓 Bitácora\n\n"
entry=(f"**2026-10-05 · T16 (`pr`) cerrada.** Escritas op123–op130 (8 secciones, {sys.argv[1]} ejercicios), **las ocho probadas en "
"contenedor** (pr06 contra RabbitMQ 4.3.6, bajada y anotada). **Hallazgos y defectos propios:** Protobuf comparte un *pool* global de "
"descriptores y dos `cita.proto` en un proceso chocan; se resolvió con paquetes versionados (pr01); gRPC a 0,53 ms por llamada y "
"`DEADLINE_EXCEEDED` con plazo (pr02); medidos siete formatos: `orjson` divide por 2,7 el costo de `json`, `msgspec` por 4,4, y **Protobuf "
"en Python es más lento que `orjson`** (8,7 contra 4,8 ms) aunque ocupa un tercio (pr03); 33 consultas contra 4 con `DataLoader` "
"(pr04, revalidado con Strawberry 0.331.5, publicada el mismo día); SSE reanuda con `Last-Event-ID` (pr05); **RabbitMQ 4.3 rechaza las colas "
"no durables** (`transient_nonexcl_queues`), el código de casi todos los tutoriales (pr06); `schemathesis` encontró `cuota=0` en 24 "
"peticiones (pr07). **URL:** la documentación de `msgspec` se mudó a msgspec.dev. **Inventario:** `jsonschema` y `PyYAML` agregados al "
"track; Strawberry pasó a 0.331.5 durante la tanda.\n\n")
t=t.replace(anchor,anchor+entry,1)
p.write_text(t)
EOF
M=/Users/oskar/.claude/projects/-Users-oskar-Developer-Learning-courses-ia-generated/memory; sed -i '' 's/T1–T15 cerradas el 05\/10\/2026: 122 de 176; sigue T16 pr\./T1–T16 cerradas el 05\/10\/2026: 130 de 176; sigue T17 pk./' $M/MEMORY.md && grep -c "130 de 176" $M/MEMORY.md

# --- 2026-10-05T20:11:13 · Read pk track rows and proposal
grep -n "| op13[1-9] .*\`op13[0-9]-pk\|| op14[0-9] .*\`op14[0-9]-pk" prompts/plan-de-produccion-carta.md; n=$(grep -n "## 15. Track \`pk\`" prompts/propuestas-temas-opcionales.md | head -1 | cut -d: -f1); sed -n "${n},$((n+38))p" prompts/propuestas-temas-opcionales.md; sed -n '/"pk"/,/\],/p' prompts/check-inventario.py

# --- 2026-10-05T20:11:18 · Survey BENCHMARKS.md for packaging entries
grep -n "^## \|^### " BENCHMARKS.md | head -60; grep -n -i "uv\b\|pip-tools\|miniforge\|zipapp\|pyinstaller\|PEP 723" BENCHMARKS.md | head -20

# --- 2026-10-05T20:11:23 · Read benchmarks 07 and 09; list pk versions
sed -n 207,270p BENCHMARKS.md; for k in pip pip-tools uv poetry pdm hatch build twine pipx pyinstaller Nuitka shiv pex conda-lock; do grep -m1 "| \`$k\` |" prompts/inventario-verificado.md || echo "falta $k"; done

# --- 2026-10-05T20:12:14 · Smoke-test venv anatomy example
cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516 && python3 humo.py op131-pk01-el-modelo-real.md pk01 'entorno.py="""Abrir un entorno virtual' --cmd 'mkdir -p /tmp/t && cp entorno.py /tmp/t/ && cd /tmp/t && python entorno.py' 2>&1 | tail -9; cd ../../cursos-algoritmos-lenguajes/python-for-java-devs && python3 ../../zz-code/python-for-java-devs-20261005-f516/verificar_urls.py op131-pk01-el-modelo-real.md | tail -2

# --- 2026-10-05T20:12:26 · Fill pk01 output, mark, verify
python3 - <<'EOF'
import pathlib,re
p=pathlib.Path("op131-pk01-el-modelo-real.md");t=p.read_text()
old=re.search(r"```text\ncrear el entorno sin pip: … s.*?\n```\n",t,re.S).group(0)
t=t.replace(old,"""```text
crear el entorno sin pip: 0.14 s
crear el entorno con pip: 1.93 s
pyvenv.cfg: ['home = /usr/local/bin', 'include-system-site-packages = false', 'version = 3.14.7', 'executable = /usr/local/bin/python3.14', 'command = /usr/local/bin/python -m venv /tmp/t/demo-venv']
bin/python es un enlace a: /usr/local/bin/python
python del entorno, sin 'activar': ¿en un entorno? True · site-packages: /tmp/t/demo-venv/lib/python3.14/site-packages
con el PATH 'activado', 'python' es: /tmp/t/demo-venv/bin/python
tamaño del entorno con pip: 11.5 MB
```

Crear la carpeta del entorno toma 0,14 s; instalarle `pip` adentro, casi dos segundos más, y la mayor parte de sus 11,5 MB. El `pyvenv.cfg` dice dónde
está el Python base y con qué comando se creó; `bin/python` es un enlace a ese Python. Llamado directamente, sin activar nada, ya sabe que está en un entorno.
Y "activar" resultó ser lo que se esperaba: con el `bin` del entorno primero en el `PATH`, la palabra `python` encuentra el del entorno.
""")
p.write_text(t)
EOF
cd ../../zz-code/python-for-java-devs-20261005-f516 && python3 probado.py op131-pk01-el-modelo-real.md && python3 plan.py 131 131 ✅ ✅ && cd - >/dev/null && python3 prompts/verificar-corpus.py | tail -1

# --- 2026-10-05T20:13:15 · Smoke-test pip-compile with hashes
cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516 && python3 humo.py op132-pk02-pip-venv-y-pip-tools.md pk02 'requirements.in=@requirements.in' 'fijar.sh=@fijar.sh' --cmd 'mkdir -p /tmp/t && cp requirements.in fijar.sh /tmp/t/ && cd /tmp/t && python3 -m venv .venv && .venv/bin/pip install -q pip-tools==7.6.1 && bash fijar.sh' 2>&1 | tail -12; cd ../../cursos-algoritmos-lenguajes/python-for-java-devs && python3 ../../zz-code/python-for-java-devs-20261005-f516/verificar_urls.py op132-pk02-pip-venv-y-pip-tools.md | tail -2

# --- 2026-10-05T20:13:55 · Alter all hashes, add strip-extras, rerun pk02
python3 - <<'EOF'
import pathlib
p=pathlib.Path("op132-pk02-pip-venv-y-pip-tools.md");t=p.read_text()
def rep(a,b):
    global t
    assert t.count(a)==1,a
    t=t.replace(a,b)
rep(".venv/bin/pip-compile --quiet --generate-hashes --output-file requirements.txt requirements.in",".venv/bin/pip-compile --quiet --strip-extras --generate-hashes --output-file requirements.txt requirements.in")
rep('''# Alguien (o algo) altera un hash: el paquete descargado ya no coincide.
sed -i '0,/--hash=sha256:[0-9a-f]\\{4\\}/s//--hash=sha256:0000/' requirements.txt''','''# Alguien (o algo) altera los hashes: lo que se descarga ya no coincide con ninguno.
sed -i 's/--hash=sha256:[0-9a-f]\\{4\\}/--hash=sha256:0000/g' requirements.txt''')
rep("""- **Una línea en `requirements.in`, seis paquetes fijados**: `httpx` trae `anyio`, `certifi`, `h11`, `httpcore` e `idna`. Sin `pip-compile`, esas cinco quedan a la
  suerte del día de la instalación.""","""- **Una línea en `requirements.in`, siete paquetes fijados**: `httpx` trae `anyio`, `certifi`, `h11`, `httpcore`, `idna` y `typing-extensions`. Sin `pip-compile`,
  esas seis quedan a la suerte del día de la instalación.
- **Dos *hashes* por paquete** (la rueda y el código fuente): `pip` acepta el archivo si coincide con **cualquiera** de los dos. La primera versión de este ejemplo
  alteró uno solo y la instalación pasó igual, porque descargó la rueda, cuyo *hash* seguía bien. La protección es contra un archivo distinto, no contra
  una línea editada del `requirements.txt`; esa la protege la revisión del *diff*.
- **`--strip-extras`** quita los *extras* (`paquete[extra]`) del archivo compilado; `pip-tools` avisa que será el comportamiento por defecto en la versión 8, y
  conviene fijarlo ya.""")
p.write_text(t)
EOF
cd ../../zz-code/python-for-java-devs-20261005-f516 && python3 humo.py op132-pk02-pip-venv-y-pip-tools.md pk02 'requirements.in=@requirements.in' 'fijar.sh=@fijar.sh' --cmd 'rm -rf /tmp/t && mkdir -p /tmp/t && cp requirements.in fijar.sh /tmp/t/ && cd /tmp/t && python3 -m venv .venv && .venv/bin/pip install -q pip-tools==7.6.1 && bash fijar.sh' 2>&1 | tail -11

# --- 2026-10-05T20:14:23 · Fill pk02 output, mark, verify
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs && python3 - <<'EOF'
import pathlib,re
p=pathlib.Path("op132-pk02-pip-venv-y-pip-tools.md");t=p.read_text()
old=re.search(r"```text\npaquetes fijados: … · hashes: ….*?\n```\n",t,re.S).group(0)
t=t.replace(old,"""```text
paquetes fijados: 7 · hashes: 14
anyio==4.15.1
certifi==2026.7.22
h11==0.16.0
httpcore==1.0.9
httpx==0.28.1
idna==3.20
typing-extensions==4.16.0
instalación verificada: OK
ERROR: THESE PACKAGES DO NOT MATCH THE HASHES FROM THE REQUIREMENTS FILE. If you have updated the package versions, please update the hashes. Otherwise, examine the package contents carefully; someone may have tampered with them.
```

Una dependencia pedida, siete fijadas con catorce *hashes*. La instalación en un entorno limpio verificó cada archivo contra su *hash*; con los *hashes* alterados,
`pip` se negó a instalar y dijo por qué, sugiriendo exactamente la sospecha correcta.
""")
t=t.replace("1. Corre el ejemplo. **Criterio:** los seis paquetes fijados y explicas por qué falló la segunda instalación.","1. Corre el ejemplo. **Criterio:** los siete paquetes fijados y explicas por qué falló la segunda instalación.")
p.write_text(t)
EOF
cd ../../zz-code/python-for-java-devs-20261005-f516 && python3 probado.py op132-pk02-pip-venv-y-pip-tools.md && python3 plan.py 132 132 ✅ ✅ && cd - >/dev/null && python3 prompts/verificar-corpus.py | tail -1

# --- 2026-10-05T20:14:29 · Find new verifier warning in pk02
python3 prompts/verificar-corpus.py | grep op132; grep -n "^Salida\|^\`\`\`bash" op132-pk02-pip-venv-y-pip-tools.md | head

# --- 2026-10-05T20:14:32 · Inspect lines around the warning
sed -n 54,70p op132-pk02-pip-venv-y-pip-tools.md

# --- 2026-10-05T20:14:39 · Refence requirements.in block and re-verify
python3 - <<'EOF'
import pathlib
p=pathlib.Path("op132-pk02-pip-venv-y-pip-tools.md");t=p.read_text()
a="`requirements.in`:\n\n```text\nhttpx\n```"
assert t.count(a)==1
t=t.replace(a,"`requirements.in`:\n\n```pip-requirements\nhttpx\n```")
p.write_text(t)
EOF
python3 prompts/verificar-corpus.py | tail -1

# --- 2026-10-05T20:15:35 · Smoke-test uv lock and release cadence
cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516 && python3 humo.py op133-pk03-uv.md pk03 'probar_uv.sh=@probar_uv.sh' 'ritmo.py="""Cuántas versiones' --pip uv==0.12.23 --cmd 'rm -rf /tmp/t && mkdir -p /tmp/t && cp probar_uv.sh ritmo.py /tmp/t/ && cd /tmp/t && bash probar_uv.sh; python ritmo.py uv pip poetry pdm' 2>&1 | tail -12; cd ../../cursos-algoritmos-lenguajes/python-for-java-devs && python3 ../../zz-code/python-for-java-devs-20261005-f516/verificar_urls.py op133-pk03-uv.md | tail -2

# --- 2026-10-05T20:15:55 · Fill pk03 output, mark, verify
cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516 && docker run --rm --label curso=python-for-java-devs python:3.14.7 sh -c 'pip install -q --root-user-action=ignore uv==0.12.23 >/dev/null 2>&1; uv --version' && cd ../../cursos-algoritmos-lenguajes/python-for-java-devs && python3 - <<'EOF'
import pathlib,re,subprocess
p=pathlib.Path("op133-pk03-uv.md");t=p.read_text()
old=re.search(r"```text\nuv 0\.12\.23 \(…\).*?\n```\n",t,re.S).group(0)
t=t.replace(old,"""```text
uv 0.12.23
paquetes en el lock: 11
plataformas distintas en las ruedas de psycopg-binary: macosx manylinux manylinux2014_ppc64le manylinux2014_x86 musllinux win_amd64
httpx==0.28.1
psycopg==3.3.6
psycopg-binary==3.3.6 ; implementation_name != 'pypy'
sync desde el lock: OK
uv          31 versiones en 90 días · última: 0.12.23
pip          2 versiones en 90 días · última: 26.2.1
poetry       4 versiones en 90 días · última: 2.5.1
pdm          5 versiones en 90 días · última: 2.29.2
```

Dos dependencias pedidas, once paquetes en el *lock*, y en él las ruedas de `psycopg-binary` para macOS, Linux (glibc y musl, varias arquitecturas) y Windows: el mismo
archivo sirve en el portátil y en el servidor. `uv export` lo devuelve como `requirements.txt`, con el marcador que dice que `psycopg-binary` no aplica en PyPy. Y la
cifra que la tabla del camino base no tenía: **`uv` publicó 31 versiones en 90 días**, una cada tres días; `pip`, dos. Es un proyecto vivísimo, y una herramienta
que hay que fijar.
""")
p.write_text(t)
EOF
cd ../../zz-code/python-for-java-devs-20261005-f516 && python3 probado.py op133-pk03-uv.md && python3 plan.py 133 133 ✅ ✅ && cd - >/dev/null && python3 prompts/verificar-corpus.py | tail -1

# --- 2026-10-05T20:21:05 · Check background task and running containers
sleep 1; cat /private/tmp/claude-501/-Users-oskar-Developer-Learning-courses-ia-generated/5c52573d-4a56-4998-bca3-5d686d0c5368/tasks/bm1abw3g8.output; docker ps --filter label=curso=python-for-java-devs --format '{{.ID}} {{.Status}} {{.Command}}'

# --- 2026-10-05T20:21:14 · Stop hung container and retry uv version
docker stop 7584df7219d2 >/dev/null && echo detenido; sleep 2; docker run --rm --label curso=python-for-java-devs python:3.14.7 sh -c 'timeout 120 pip install -q --root-user-action=ignore uv==0.12.23 >/dev/null 2>&1; uv --version'

# --- 2026-10-05T20:21:29 · Inspect what the background task applied
cat /private/tmp/claude-501/-Users-oskar-Developer-Learning-courses-ia-generated/5c52573d-4a56-4998-bca3-5d686d0c5368/tasks/bm1abw3g8.output; cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs && grep -n "^uv 0.12.23\|^Salida\|Código probado\|sin ejecutar" op133-pk03-uv.md | head; grep -n "op133" prompts/plan-de-produccion-carta.md

# --- 2026-10-05T20:21:40 · Apply pk03 output replacement and verify
python3 - <<'EOF'
import pathlib,re
p=pathlib.Path("op133-pk03-uv.md");t=p.read_text()
old=re.search(r"```text\nuv 0\.12\.23 \(…\).*?\n```\n",t,re.S).group(0)
t=t.replace(old,"""```text
uv 0.12.23 (aarch64-unknown-linux-gnu)
paquetes en el lock: 11
plataformas distintas en las ruedas de psycopg-binary: macosx manylinux manylinux2014_ppc64le manylinux2014_x86 musllinux win_amd64
httpx==0.28.1
psycopg==3.3.6
psycopg-binary==3.3.6 ; implementation_name != 'pypy'
sync desde el lock: OK
uv          31 versiones en 90 días · última: 0.12.23
pip          2 versiones en 90 días · última: 26.2.1
poetry       4 versiones en 90 días · última: 2.5.1
pdm          5 versiones en 90 días · última: 2.29.2
```

Dos dependencias pedidas, once paquetes en el *lock*, y en él las ruedas de `psycopg-binary` para macOS, Linux (glibc y musl, varias arquitecturas) y Windows: el mismo
archivo sirve en el portátil y en el servidor. `uv export` lo devuelve como `requirements.txt`, con el marcador que dice que `psycopg-binary` no aplica en PyPy. Y la
cifra que la tabla del camino base no tenía: **`uv` publicó 31 versiones en 90 días**, una cada tres días; `pip`, dos. Es un proyecto vivísimo, y una herramienta
que hay que fijar.
""")
p.write_text(t)
EOF
grep -c "31 versiones en 90 días" op133-pk03-uv.md && python3 prompts/verificar-corpus.py | tail -1

# --- 2026-10-05T20:21:50 · List Miniforge image tags
curl -s "https://hub.docker.com/v2/repositories/condaforge/miniforge3/tags?page_size=12&ordering=last_updated" | python3 -c "import json,sys; print([t['name'] for t in json.load(sys.stdin)['results']])"

# --- 2026-10-05T20:21:55 · Pull Miniforge image and record it
echo "condaforge/miniforge3:26.7.2-0" >> /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516/salidas/imagenes-bajadas.txt; docker image inspect condaforge/miniforge3:26.7.2-0 >/dev/null 2>&1 && echo ya-estaba || timeout 500 docker pull -q condaforge/miniforge3:26.7.2-0

# --- 2026-10-05T20:22:48 · Run pip vs conda GDAL comparison
cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516 && python3 humo.py op134-pk04-conda-y-compania.md pk04 'binario.sh=#!/bin/sh' --cmd 'true' >/dev/null; D=$PWD/salidas/pk04; timeout 280 docker run --rm --label curso=python-for-java-devs -v "$D:/w" python:3.14.7 sh /w/binario.sh 2>&1 | tail -3; echo ===; timeout 580 docker run --rm --label curso=python-for-java-devs -v "$D:/w" condaforge/miniforge3:26.7.2-0 sh /w/binario.sh 2>&1 | tail -6

# --- 2026-10-05T20:23:01 · Inspect pip GDAL install error lines
D=/Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516/salidas/pk04; timeout 280 docker run --rm --label curso=python-for-java-devs python:3.14.7 sh -c 'pip install --no-cache-dir gdal 2>&1 | grep -iE "gdal-config|could not find|not found" | head -3'

# --- 2026-10-05T20:23:12 · Rerun GDAL comparison in both images
python3 - <<'EOF'
import pathlib
p=pathlib.Path("op134-pk04-conda-y-compania.md");t=p.read_text()
a='  pip install --no-cache-dir gdal 2>&1 | grep -m1 -iE "gdal-config|error:" || echo "pip: instaló"'
assert t.count(a)==1
t=t.replace(a,'  pip install --no-cache-dir gdal 2>&1 | grep -m1 "gdal-config" || echo "pip: instaló"')
p.write_text(t)
EOF
cd ../../zz-code/python-for-java-devs-20261005-f516 && python3 humo.py op134-pk04-conda-y-compania.md pk04 'binario.sh=#!/bin/sh' --cmd 'true' >/dev/null; D=$PWD/salidas/pk04; timeout 280 docker run --rm --label curso=python-for-java-devs -v "$D:/w" python:3.14.7 sh /w/binario.sh 2>&1 | tail -2; echo "-----"; timeout 580 docker run --rm --label curso=python-for-java-devs -v "$D:/w" condaforge/miniforge3:26.7.2-0 sh /w/binario.sh 2>&1 | tail -6

# --- 2026-10-05T20:23:49 · Get conda version from Miniforge image
timeout 120 docker run --rm --label curso=python-for-java-devs condaforge/miniforge3:26.7.2-0 conda --version 2>/dev/null

# --- 2026-10-05T20:23:59 · Fill pk04 output, mark, verify
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs && python3 - <<'EOF'
import pathlib
p=pathlib.Path("op134-pk04-conda-y-compania.md");t=p.read_text()
a="""… gdal-config …
conda 26.…
conda create con gdal: … s
GDAL 3.…
tamaño del entorno: …
paquetes en el entorno: …
```
"""
assert t.count(a)==1
t=t.replace(a,"""      FileNotFoundError: [Errno 2] No such file or directory: 'gdal-config'
conda 26.7.2
conda create con gdal: 23 s
GDAL 3.13.3
tamaño del entorno: 517M
paquetes en el entorno: 81
```

En la imagen de Python, `pip` no llegó ni a compilar: el instalador de GDAL busca `gdal-config`, que viene con las bibliotecas de desarrollo del sistema, y no
está. En Miniforge, `conda` creó el entorno en 23 segundos con GDAL 3.13.3 funcionando —el `import` de `osgeo` lo confirma— y el costo que se paga por eso:
**81 paquetes y 517 MB**, porque cada biblioteca de C que GDAL necesita viene adentro, compilada. Es el problema binario resuelto a la manera de conda: traer
todo, para no depender de nada del sistema.
""")
p.write_text(t)
EOF
cd ../../zz-code/python-for-java-devs-20261005-f516 && python3 probado.py op134-pk04-conda-y-compania.md && python3 plan.py 134 134 ✅ ✅ && cd - >/dev/null && sed -i '' 's/^Salida (Python 3.14.7, 05\/10\/2026):$/Salida (Python 3.14.7 y Miniforge 26.7.2-0, 05\/10\/2026):/' op134-pk04-conda-y-compania.md; grep -n "^Salida" op134-pk04-conda-y-compania.md; python3 ../../zz-code/python-for-java-devs-20261005-f516/verificar_urls.py op134-pk04-conda-y-compania.md | tail -2 && python3 prompts/verificar-corpus.py | tail -1

# --- 2026-10-05T20:24:50 · Run Poetry, PDM and uv measurement
python3 - <<'EOF'
import pathlib
p=pathlib.Path("op135-pk05-poetry-y-pdm.md");t=p.read_text()
a='''  printf '%-7s fría %6.1f s · caliente %5.1f s · entorno %s\\n' "$1" \\
    "$(echo "$mid - $start" | bc)" "$(echo "$(now) - $mid" | bc)" "$(du -sh "$4" | cut -f1)"'''
assert t.count(a)==1, "no"
t=t.replace(a,'''  printf '%-7s fría %6.1f s · caliente %5.1f s · entorno %s\\n' "$1" \\
    "$(awk "BEGIN{print $mid - $start}")" "$(awk "BEGIN{print $(now) - $mid}")" "$(du -sh "$4" | cut -f1)"''')
p.write_text(t)
EOF
cd ../../zz-code/python-for-java-devs-20261005-f516 && python3 humo.py op135-pk05-poetry-y-pdm.md pk05 'medir_gestores.sh=@medir_gestores.sh' --pip poetry==2.5.1 pdm==2.29.2 uv==0.12.23 --cmd 'rm -rf /tmp/t && mkdir -p /tmp/t && cp medir_gestores.sh /tmp/t/ && cd /tmp/t && bash medir_gestores.sh' 2>&1 | tail -6

# --- 2026-10-05T20:24:55 · Rerun pk05 with content prefix
python3 humo.py op135-pk05-poetry-y-pdm.md pk05 'medir_gestores.sh=set -euo pipefail' --pip poetry==2.5.1 pdm==2.29.2 uv==0.12.23 --cmd 'rm -rf /tmp/t && mkdir -p /tmp/t && cp medir_gestores.sh /tmp/t/ && cd /tmp/t && bash medir_gestores.sh' 2>&1 | tail -6

# --- 2026-10-05T20:35:06 · Add packaging tools to pk inventory
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs && sed -i '' 's/           "pyinstaller", "Nuitka", "shiv", "pex", "conda-lock"\],/           "pyinstaller", "Nuitka", "shiv", "pex", "conda-lock", "pypiserver", "hatchling", "check-wheel-contents"],/' prompts/check-inventario.py && sed -n '/"pk"/,/\],/p' prompts/check-inventario.py && python3 prompts/check-inventario.py pk | tail -1 && for k in pypiserver hatchling check-wheel-contents; do grep -m1 "| \`$k\` |" prompts/inventario-verificado.md; done

# --- 2026-10-05T20:36:10 · Check pk05 background measurement status
cat /private/tmp/claude-501/-Users-oskar-Developer-Learning-courses-ia-generated/5c52573d-4a56-4998-bca3-5d686d0c5368/tasks/bgnaldjjm.output | tail -5; docker ps --filter label=curso=python-for-java-devs --format '{{.ID}} {{.Status}}'

# --- 2026-10-05T20:36:14 · Inspect progress inside measurement container
docker exec dfd3b0a066ff sh -c 'ls /tmp/t 2>/dev/null; ls /tmp/t/p-poetry 2>/dev/null; ps aux | grep -E "poetry|pdm|uv|pip" | grep -v grep | head -5'

# --- 2026-10-05T20:36:19 · Test PyPI connectivity from a container
timeout 60 docker run --rm --label curso=python-for-java-devs python:3.14.7 sh -c 'time python -c "import urllib.request,time; t=time.time(); urllib.request.urlopen(\"https://pypi.org/simple/poetry/\", timeout=20).read(); print(\"pypi ok\", round(time.time()-t,2))"; python -c "import urllib.request,time; t=time.time(); urllib.request.urlopen(\"https://files.pythonhosted.org/\", timeout=20); print(\"files ok\", round(time.time()-t,2))"' 2>&1 | tail -4

# --- 2026-10-05T20:36:28 · Retry pk05 measurement with timeouts
docker stop dfd3b0a066ff >/dev/null && echo detenido; cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516 && python3 humo.py op135-pk05-poetry-y-pdm.md pk05 'medir_gestores.sh=set -euo pipefail' --cmd 'timeout 200 pip install -q --root-user-action=ignore uv==0.12.23 && timeout 300 uv pip install --system -q poetry==2.5.1 pdm==2.29.2 && echo herramientas-listas && rm -rf /tmp/t && mkdir -p /tmp/t && cp medir_gestores.sh /tmp/t/ && cd /tmp/t && timeout 900 bash medir_gestores.sh' 2>&1 | tail -6

# --- 2026-10-05T20:36:35 · Smoke-test packaging and private index
cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516 && python3 humo.py op136-pk06-empaquetar-y-publicar.md pk06 'aurea-cartera/pyproject.toml=@aurea-cartera/pyproject.toml' 'aurea-cartera/src/aurea_cartera/__init__.py=@aurea-cartera/src/aurea_cartera/__init__.py' 'aurea-cartera/src/aurea_cartera/cli.py=@aurea-cartera/src/aurea_cartera/cli.py' 'publicar.sh=@publicar.sh' --cmd 'timeout 200 pip install -q --root-user-action=ignore uv==0.12.23 && timeout 300 uv pip install --system -q twine==7.0.0 pypiserver==2.4.2 && rm -rf /tmp/t && mkdir -p /tmp/t && cp -r aurea-cartera publicar.sh /tmp/t/ && cd /tmp/t && timeout 400 bash publicar.sh' 2>&1 | tail -18

# --- 2026-10-05T20:36:42 · Rerun pk06 with content prefix
python3 humo.py op136-pk06-empaquetar-y-publicar.md pk06 'aurea-cartera/pyproject.toml=@aurea-cartera/pyproject.toml' 'aurea-cartera/src/aurea_cartera/__init__.py=@aurea-cartera/src/aurea_cartera/__init__.py' 'aurea-cartera/src/aurea_cartera/cli.py=@aurea-cartera/src/aurea_cartera/cli.py' 'publicar.sh=set -euo pipefail' --cmd 'timeout 200 pip install -q --root-user-action=ignore uv==0.12.23 && timeout 300 uv pip install --system -q twine==7.0.0 pypiserver==2.4.2 && rm -rf /tmp/t && mkdir -p /tmp/t && cp -r aurea-cartera publicar.sh /tmp/t/ && cd /tmp/t && timeout 400 bash publicar.sh' 2>&1 | tail -18

# --- 2026-10-05T20:37:05 · Inspect second upload to pypiserver
python3 humo.py op136-pk06-empaquetar-y-publicar.md pk06 'publicar.sh=set -euo pipefail' --cmd 'timeout 200 pip install -q --root-user-action=ignore uv==0.12.23 && timeout 300 uv pip install --system -q twine==7.0.0 pypiserver==2.4.2 && rm -rf /tmp/t && mkdir -p /tmp/t && cp -r aurea-cartera /tmp/t/ && cd /tmp/t && (cd aurea-cartera && uv build --quiet) && mkdir -p indice && (pypi-server run -p 8151 -a . -P . indice >/dev/null 2>&1 &) && sleep 2 && twine upload --repository-url http://127.0.0.1:8151 -u x -p x aurea-cartera/dist/*.whl 2>&1 | tail -2; echo "-- segunda --"; twine upload --repository-url http://127.0.0.1:8151 -u x -p x aurea-cartera/dist/*.whl 2>&1 | tail -4; echo "exit=$?"; ls indice' 2>&1 | tail -12

# --- 2026-10-05T20:37:21 · Read pk05 measurement results
cat /private/tmp/claude-501/-Users-oskar-Developer-Learning-courses-ia-generated/5c52573d-4a56-4998-bca3-5d686d0c5368/tasks/bz89xcshw.output | tail -6

# --- 2026-10-05T20:37:24 · Extract all measurement lines for pk05
cat /private/tmp/claude-501/-Users-oskar-Developer-Learning-courses-ia-generated/5c52573d-4a56-4998-bca3-5d686d0c5368/tasks/bz89xcshw.output | grep -E "fría|herramientas"

# --- 2026-10-05T20:37:37 · Fill pk05, fix pk06 grep and rerun
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs && python3 - <<'EOF'
import pathlib
p=pathlib.Path("op135-pk05-poetry-y-pdm.md");t=p.read_text()
a="""poetry  fría … s · caliente … s · entorno …
pdm     fría … s · caliente … s · entorno …
uv      fría … s · caliente … s · entorno …
```
"""
assert t.count(a)==1
t=t.replace(a,"""poetry  fría    5.2 s · caliente   1.0 s · entorno 45M
pdm     fría   12.1 s · caliente   2.9 s · entorno 38M
uv      fría    1.0 s · caliente   0.1 s · entorno 38M
```

El mismo encargo, en la misma máquina y la misma red. `uv` agregó las cinco dependencias con la caché vacía en un segundo y recreó el entorno desde el *lock* en una
décima: **cinco veces más rápido que Poetry en frío y diez en caliente**, doce y veintinueve veces más que PDM. Poetry, que tiene fama de lento, le ganó a PDM con
holgura. Los entornos ocupan casi lo mismo: lo que se instala es lo mismo. (La cifra en frío de `uv` es mayor que la de `BENCHMARKS.md` §07 —0,4 s— porque es otra
máquina y otra red; por eso las tres se midieron juntas.)
""")
p.write_text(t)
q=pathlib.Path("op136-pk06-empaquetar-y-publicar.md");s=q.read_text()
b='twine upload --repository-url http://127.0.0.1:8151 -u x -p x aurea-cartera/dist/*.whl 2>&1 | grep -m1 -E "409|already exists|Conflict" || true'
assert s.count(b)==1
s=s.replace(b,'twine upload --repository-url http://127.0.0.1:8151 -u x -p x aurea-cartera/dist/*.whl 2>&1 | grep -m1 -oE "HTTPError: [0-9]+ [A-Za-z ]+" || true')
q.write_text(s)
EOF
cd ../../zz-code/python-for-java-devs-20261005-f516 && python3 probado.py op135-pk05-poetry-y-pdm.md && python3 plan.py 135 135 ✅ ✅ && python3 humo.py op136-pk06-empaquetar-y-publicar.md pk06 'publicar.sh=set -euo pipefail' --cmd 'timeout 200 pip install -q --root-user-action=ignore uv==0.12.23 && timeout 300 uv pip install --system -q twine==7.0.0 pypiserver==2.4.2 && rm -rf /tmp/t && mkdir -p /tmp/t && cp -r aurea-cartera publicar.sh /tmp/t/ && cd /tmp/t && timeout 400 bash publicar.sh' 2>&1 | tail -3

# --- 2026-10-05T20:37:55 · Capture publish and duplicate-upload lines
python3 humo.py op136-pk06-empaquetar-y-publicar.md pk06 'publicar.sh=set -euo pipefail' --cmd 'timeout 200 pip install -q --root-user-action=ignore uv==0.12.23 && timeout 300 uv pip install --system -q twine==7.0.0 pypiserver==2.4.2 && rm -rf /tmp/t && mkdir -p /tmp/t && cp -r aurea-cartera publicar.sh /tmp/t/ && cd /tmp/t && timeout 400 bash publicar.sh' 2>/dev/null | grep -E "publicado|HTTPError|^\\$"

# --- 2026-10-05T20:38:15 · Fill pk06 output, mark, verify URLs
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs && python3 - <<'EOF'
import pathlib
p=pathlib.Path("op136-pk06-empaquetar-y-publicar.md");t=p.read_text()
def rep(a,b):
    global t
    assert t.count(a)==1,a
    t=t.replace(a,b)
rep("""publicado en el índice privado
… 409 …
$28.125
```
""","""publicado en el índice privado
HTTPError: 400 Bad Request from http
$28.125
```

La rueda trae el código, los metadatos y el `entry_points.txt` que declara `aurea-mora`. Publicada en el índice privado, la "franquicia" la instaló con `pip` desde ese
índice y el comando apareció solo, calculando la misma mora de toda la carta. El segundo intento de subir la misma versión lo rechazó el índice —`pypiserver` responde
400; PyPI también responde 400, con el motivo "File already exists"—: una versión publicada no se reemplaza.
""")
rep("""- **El segundo `upload` falla**: la misma versión no se puede volver a subir. Es la regla que protege a quien ya instaló `1.2.0`.""","""- **El segundo `upload` falla**: la misma versión no se puede volver a subir. Es la regla que protege a quien ya instaló `1.2.0`. El código de error no es el 409 que uno
  esperaría (la primera versión de este ejemplo lo buscaba y no lo encontró): `pypiserver` y PyPI responden 400.""")
p.write_text(t)
EOF
cd ../../zz-code/python-for-java-devs-20261005-f516 && python3 probado.py op136-pk06-empaquetar-y-publicar.md && python3 plan.py 136 136 ✅ ✅ && cd - >/dev/null && for f in op135-pk05-poetry-y-pdm.md op136-pk06-empaquetar-y-publicar.md; do python3 ../../zz-code/python-for-java-devs-20261005-f516/verificar_urls.py $f | tail -1; done; python3 prompts/verificar-corpus.py | tail -1

# --- 2026-10-05T20:40:09 · Review humo.py usage
cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516 && sed -n 1,60p humo.py

# --- 2026-10-05T20:40:15 · Run pk07 delivery measurement in container
timeout 600 python3 humo.py op137-pk07-entregar-a-quien-no-es-ingeniero.md pk07 'regalias/regalias.py=@regalias/regalias.py' 'regalias_pep723.py=# /// script' 'entregar.sh=set -euo pipefail' --pip shiv pex uv --cmd "apt-get -qq update >/dev/null 2>&1; apt-get -qq install -y unzip >/dev/null 2>&1; bash entregar.sh 2>&1"

# --- 2026-10-05T20:40:30 · Rerun pk07 measurement
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs && python3 - <<'EOF'
p='op137-pk07-entregar-a-quien-no-es-ingeniero.md'
s=open(p).read()
s=s.replace("python3 regalias-zipapp.pyz 2>&1 | tail -1 | cut -c1-60\n","python3 regalias-zipapp.pyz 2>&1 | tail -1 | cut -c1-60 || true\n")
open(p,'w').write(s)
EOF
cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516 && timeout 600 python3 humo.py op137-pk07-entregar-a-quien-no-es-ingeniero.md pk07 'regalias/regalias.py=@regalias/regalias.py' 'regalias_pep723.py=# /// script' 'entregar.sh=set -euo pipefail' --pip shiv pex uv --cmd "apt-get -qq update >/dev/null 2>&1; apt-get -qq install -y unzip >/dev/null 2>&1; bash entregar.sh 2>&1; ls -la *.pyz *.pex"

# --- 2026-10-05T20:41:09 · Rerun pk07 with pex output silenced
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs && python3 - <<'EOF'
p='op137-pk07-entregar-a-quien-no-es-ingeniero.md'
s=open(p).read()
s=s.replace("pex httpx orjson -D regalias -e regalias:main -o regalias.pex\n","pex httpx orjson -D regalias -e regalias:main -o regalias.pex >/dev/null 2>&1\n")
open(p,'w').write(s)
EOF
cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516 && timeout 600 python3 humo.py op137-pk07-entregar-a-quien-no-es-ingeniero.md pk07 'regalias/regalias.py=@regalias/regalias.py' 'regalias_pep723.py=# /// script' 'entregar.sh=set -euo pipefail' --pip shiv pex uv --cmd "apt-get -qq update >/dev/null 2>&1; apt-get -qq install -y unzip >/dev/null 2>&1; bash entregar.sh 2>&1; pip list 2>/dev/null | grep -iE '^(shiv|pex|uv) '"

# --- 2026-10-05T20:41:47 · Final pk07 run
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs && python3 - <<'EOF'
p='op137-pk07-entregar-a-quien-no-es-ingeniero.md'
s=open(p).read()
s=s.replace("--site-packages regalias httpx orjson\n","--site-packages regalias httpx orjson 2>/dev/null\n")
open(p,'w').write(s)
EOF
cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516 && timeout 600 python3 humo.py op137-pk07-entregar-a-quien-no-es-ingeniero.md pk07 'regalias/regalias.py=@regalias/regalias.py' 'regalias_pep723.py=# /// script' 'entregar.sh=set -euo pipefail' --pip shiv pex uv --cmd "apt-get -qq update >/dev/null 2>&1; apt-get -qq install -y unzip >/dev/null 2>&1; bash entregar.sh 2>&1"

# --- 2026-10-05T20:42:23 · Rerun pk07 without root pip warning
timeout 600 python3 humo.py op137-pk07-entregar-a-quien-no-es-ingeniero.md pk07 'regalias/regalias.py=@regalias/regalias.py' 'regalias_pep723.py=# /// script' 'entregar.sh=set -euo pipefail' --pip shiv pex uv --cmd "export PIP_ROOT_USER_ACTION=ignore; apt-get -qq update >/dev/null 2>&1; apt-get -qq install -y unzip >/dev/null 2>&1; bash entregar.sh 2>&1"

# --- 2026-10-05T20:43:10 · Fill pk07 output, mark tested, check URLs
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs && python3 - <<'EOF'
p='op137-pk07-entregar-a-quien-no-es-ingeniero.md'
s=open(p).read()
i=s.index("Salida esperada, sin correr (los milisegundos")
j=s.index("---\n\n## ⚠️")
new='''Salida esperada, sin correr (los milisegundos son de la máquina que corre):

```text
ModuleNotFoundError: No module named 'httpx'
regalias-shiv.pyz     700 KB · arranque   90 ms · {"Suba":6430500,"Zipaquirá":2778750}
regalias.pex         1700 KB · arranque  801 ms · {"Suba":6430500,"Zipaquirá":2778750}
PEP 723 (uv run)   primera vez  1408 ms (descarga) · después   32 ms
orjson-3.12.0-cp314-cp314-manylinux_2_17_aarch64.manylinux2014_aarch64.whl
```

El `.pyz` de `zipapp` pesa 758 bytes y no corre: no lleva las dependencias, y falla en el primer `import` de terceros. `shiv` y `pex` sí funcionan, con dos
sorpresas que §09 no podía mostrar. La primera, el arranque: **`shiv` arranca en 90 ms y `pex` en 801**, nueve veces más, porque `pex` revisa en cada ejecución su
entorno y vuelve a lanzar el intérprete antes de correr el código. La segunda, la etiqueta de la rueda de `orjson` dentro del `.pex`: **`cp314`, `manylinux`,
`aarch64`**. Ese archivo corre con Python 3.14, en Linux, en ARM; en el Windows de Patricia, no. El *script* PEP 723 tardó 1,4 s la primera vez, descargando, y
32 ms después, desde el caché de `uv`.

**Detalles con intención**

- **El `.pyz` de `zipapp` falla** en el primer `import` de terceros: `zipapp` empaqueta la carpeta, no las dependencias. Y aunque se las copiaran adentro, Python no
  puede cargar una extensión compilada (`.so`) desde un zip. Es el límite que el camino base no vio porque su herramienta no tenía dependencias.
- **`shiv` y `pex` llevan las dependencias**, incluida la rueda compilada de `orjson` para la plataforma donde se construyeron, y la desempaquetan a un caché la
  primera vez. La etiqueta de la rueda dice para qué máquina es el archivo.
- **PEP 723 no lleva nada**: declara. La primera ejecución descarga e instala `httpx` y `orjson` (y necesita internet); las siguientes usan el caché de `uv`.
- **El arranque se mide después de una ejecución de calentamiento**, para no mezclar el desempaquetado inicial con el arranque de todos los días.

'''
s=s[:i]+new+s[j:]
s=s.replace("**`shiv` o `pex` para máquinas de plataformas distintas.** Un archivo por plataforma deja de ser \"un archivo\"; `uv tool` instala en cada una.",
"**`shiv` o `pex` para máquinas de plataformas distintas.** Un archivo por plataforma deja de ser \"un archivo\"; `uv tool` instala en cada una.\n\n**`pex` para algo que se ejecuta muchas veces seguidas.** 801 ms por ejecución contra 90 de `shiv`: en un *script* que corre una vez al día no importa; en uno que\nllama otro programa por cada archivo, sí.")
s=s.replace("| `.pex` | Sí, también compiladas | Sí | **Sí**, si hay compiladas | Desempaqueta a un caché |","| `.pex` | Sí, también compiladas | Sí | **Sí**, si hay compiladas | Desempaqueta a un caché; arranque lento (medido abajo) |")
s=s.replace("Con dependencias de terceros, las formas de entregar se separan: `zipapp` no puede con extensiones compiladas; `shiv` y `pex` sí, pero el archivo queda atado a una\nplataforma;",
"Con dependencias de terceros, las formas de entregar se separan: `zipapp` no lleva dependencias y no puede con extensiones compiladas; `shiv` (90 ms) y `pex` (801 ms) sí,\npero el archivo queda atado a una plataforma;")
open(p,'w').write(s)
EOF
cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516 && python3 probado.py ../../cursos-algoritmos-lenguajes/python-for-java-devs/op137-pk07-entregar-a-quien-no-es-ingeniero.md 2>&1 | tail -3; python3 plan.py 137 137 ✅ ✅ 2>&1 | tail -2; python3 verificar_urls.py ../../cursos-algoritmos-lenguajes/python-for-java-devs/op137-pk07-entregar-a-quien-no-es-ingeniero.md 2>&1 | tail -4

# --- 2026-10-05T20:43:16 · Check plan rows and header state
cd /Users/oskar/Developer/Learning/courses-ia-generated && grep -n "op137\|op138" cursos-algoritmos-lenguajes/python-for-java-devs/prompts/plan-de-produccion-carta.md | head; sed -n 1,12p cursos-algoritmos-lenguajes/python-for-java-devs/op137-pk07-entregar-a-quien-no-es-ingeniero.md; grep -n "Salida" cursos-algoritmos-lenguajes/python-for-java-devs/op137-pk07-entregar-a-quien-no-es-ingeniero.md; ls cursos-algoritmos-lenguajes/python-for-java-devs/prompts/ | grep -i verif

# --- 2026-10-05T20:43:19 · Read previous verdict section and benchmarks anchors
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs && ls op1[23]*veredicto* ; cat $(ls op130*); grep -n "§07\|§09\|## 07\|## 09" BENCHMARKS.md | head

# --- 2026-10-05T20:43:23 · Gather pk01/pk02/pk06 outputs for verdict
ls op13[1-6]*; for f in op131* op132* op136*; do echo "== $f"; sed -n '/^Salida (Python/,/^```$/p' $f | head -30; done

# --- 2026-10-05T20:43:58 · Run pk08 verdict function in container
cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516 && python3 humo.py op138-pk08-veredicto.md pk08 'gestor.py=@gestor.py' --cmd "python3 gestor.py"

# --- 2026-10-05T20:44:01 · Run pk08 with content prefix
cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516 && python3 humo.py op138-pk08-veredicto.md pk08 'gestor.py="""¿uv' --cmd "python3 gestor.py"

# --- 2026-10-05T20:44:09 · Mark pk08, verify, check pk inventory
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs && python3 - <<'EOF'
p='op138-pk08-veredicto.md'
s=open(p).read()
s=s.replace('''API de cartera                               → uv, con versión fija en el CI
…
''','''API de cartera                               → uv, con versión fija en el CI
Agente de sincronización de sedes            → uv, con versión fija en el CI
Análisis geográfico de pacientes             → conda (Miniforge), con conda-lock
Herramienta de la franquicia de Zipaquirá    → se queda en poetry; pyproject.toml en PEP 621
aurea-cartera (biblioteca compartida)        → uv build + índice privado
Reporte de regalías para Patricia            → uv tool install (o shiv, si todos usan la misma plataforma)
Cron del servidor de la sede Restrepo        → pip + pip-tools, con hashes (el lock lo genera el CI)
''')
open(p,'w').write(s)
EOF
cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516 && python3 probado.py ../../cursos-algoritmos-lenguajes/python-for-java-devs/op138-pk08-veredicto.md && python3 plan.py 138 138 ✅ ✅ && python3 verificar_urls.py ../../cursos-algoritmos-lenguajes/python-for-java-devs/op138-pk08-veredicto.md | tail -2; cd ../../cursos-algoritmos-lenguajes/python-for-java-devs && python3 prompts/verificar-corpus.py op137-pk07-entregar-a-quien-no-es-ingeniero.md op138-pk08-veredicto.md 2>&1 | tail -8; python3 prompts/check-inventario.py pk 2>&1 | tail -15

# --- 2026-10-05T20:44:31 · Check verifier usage and pk inventory entries
head -20 prompts/verificar-corpus.py | grep -iE "uso|usage|argv" ; grep -n "pk\b\|^## .*pk\|shiv\|pex\|orjson" prompts/inventario-verificado.md | head -20; grep -n '"pk"' prompts/check-inventario.py

# --- 2026-10-05T20:44:34 · Verifier usage and pk inventory table
sed -n 1,25p prompts/verificar-corpus.py | sed -n '/Uso/,+6p'; sed -n 462,490p prompts/inventario-verificado.md

# --- 2026-10-05T20:44:37 · Run corpus verifier, filter pk07/pk08
python3 prompts/verificar-corpus.py 2>&1 | grep -E "op13[78]|errores" | head

# --- 2026-10-05T20:44:41 · Check plan.py commands and bitácora location
cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516 && grep -nE "argv|def " plan.py | head -20; grep -n "Bitácora\|### T16\|T16 —\|T16 " ../../cursos-algoritmos-lenguajes/python-for-java-devs/prompts/plan-de-produccion-carta.md | head

# --- 2026-10-05T20:44:44 · plan.py subcommands; exercise counts
sed -n 1,40p plan.py | grep -nE 'a\[0\]|==' | head; grep -c "^[0-9]*\. " ../../cursos-algoritmos-lenguajes/python-for-java-devs/op13[1-8]*.md

# --- 2026-10-05T20:44:47 · Show plan.py subcommand args
sed -n 6,13p plan.py

# --- 2026-10-05T20:44:55 · Close T17 in production plan
python3 plan.py tanda T17 ✅ && python3 plan.py dondeesta "T1–T17 cerradas (138 de 176). Sigue T18 ff (op139)." && python3 plan.py bitacora '**2026-10-05 · T17 (`pk`) cerrada.** Escritas op131–op138 (8 secciones, 78 ejercicios), **las ocho probadas en contenedor** (pk04 contra Miniforge 26.7.2-0, bajada y anotada). **Hallazgos y defectos propios:** crear un entorno sin `pip` tarda 0,14 s contra 1,93 s con él (pk01); un `requirements.txt` compilado con `--generate-hashes` lleva dos *hashes* por paquete (rueda y fuente), se escribe con `--strip-extras` y el paquete alterado se rechaza (pk02); `uv` publicó 31 versiones en 90 días contra 2 de `pip`, y su *lock* trae las ruedas de seis familias de plataformas (pk03); `pip install gdal` falla sin `gdal-config`, conda lo resuelve en 23 s con 81 paquetes y 517 MB (pk04); medidos juntos, `uv` 1,0/0,1 s, Poetry 5,2/1,0 s y PDM 12,1/2,9 s en frío/caliente: **Poetry le gana a PDM**, contra su fama (pk05); pypiserver y PyPI rechazan la versión duplicada con **400, no 409** (pk06); el `.pyz` de `zipapp` no lleva dependencias, `shiv` arranca en 90 ms y **`pex` en 801**, y la rueda dentro del `.pex` queda atada a `cp314-aarch64` (pk07). **Ambiente:** las instalaciones con `pip` dentro del contenedor se colgaron dos veces; se pararon solo los contenedores del curso y se repitió con `uv pip install --system` y `timeout`. **Inventario:** `pypiserver`, `hatchling` y `check-wheel-contents` agregados al track.' && grep -n "T17" ../../cursos-algoritmos-lenguajes/python-for-java-devs/prompts/plan-de-produccion-carta.md | head -4

# --- 2026-10-05T20:44:59 · Update memory index for carta progress
cd /Users/oskar/.claude/projects/-Users-oskar-Developer-Learning-courses-ia-generated/memory && sed -i '' 's/T1–T16 cerradas el 05\/10\/2026: 130 de 176; sigue T17 pk\./T1–T17 cerradas el 05\/10\/2026: 138 de 176; sigue T18 ff./' MEMORY.md && grep -n "python-java-devs\|T1–T1" MEMORY.md; grep -n "T1–T16\|130 de 176" python-java-devs-estado.md

# --- 2026-10-05T20:45:04 · Inspect T18 ff plan rows and spec
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs && grep -n "T1[6-7]\|130\|138" /Users/oskar/.claude/projects/-Users-oskar-Developer-Learning-courses-ia-generated/memory/python-carta-produccion.md; sed -n 96,100p prompts/plan-de-produccion-carta.md; grep -n "op139\|op14[0-9]\|op15[0-2]" prompts/plan-de-produccion-carta.md | head -20; grep -n "\`ff\`\|^### .*ff" prompts/*.md | head

# --- 2026-10-05T20:45:07 · Read ff track proposal and inventory
sed -n 799,870p prompts/propuestas-temas-opcionales.md; sed -n 486,510p prompts/inventario-verificado.md; grep -n "1130" /dev/null; sed -n 1125,1135p prompts/propuestas-temas-opcionales.md

# --- 2026-10-05T20:45:10 · List benchmark sections and GIL mentions
grep -n "^### " BENCHMARKS.md; grep -n -i "gil\|free-thread\|3.14t\|sin GIL" BENCHMARKS.md | head

# --- 2026-10-05T20:45:13 · Read GIL and ds01 benchmark details
sed -n 384,420p BENCHMARKS.md; sed -n 588,612p BENCHMARKS.md

# --- 2026-10-05T20:45:24 · How base course obtained free-threaded Python
grep -n -i "3.14t\|free-threading\|python3.14t" 14-concurrencia-y-gil.md | head; ls src 2>/dev/null | head -30

# --- 2026-10-05T20:45:33 · Check container CPUs and GIL status
mkdir -p /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516/salidas/ff01 && cd $_ && cat > frontera.py <<'EOF'
"""Dónde está la frontera: el mismo trabajo en Python puro y en C, con y sin hilos."""

import hashlib
import sys
import threading
import time

import numpy as np

print("numpy está escrito en:", np.core._multiarray_umath.__file__.rsplit("/", 1)[-1] if hasattr(np, "core") else "")
EOF
docker run --rm --label curso=python-for-java-devs python:3.14.7 sh -c 'nproc; python -c "import sys; print(sys._is_gil_enabled())"'

# --- 2026-10-05T20:45:46 · Measure ff01 native frontier demo
cat > frontera.py <<'EOF'
"""Dónde está la frontera con C: qué ya es nativo, cuánto cuesta el bucle, y quién suelta el GIL."""

import hashlib
import pathlib
import sys
import threading
import time

import numpy as np

# 1) Lo que ya es C sin que nadie lo dijera
core = pathlib.Path(np.__file__).parent
print("numpy: archivos .py", len(list(core.rglob("*.py"))), "· extensiones .so", len(list(core.rglob("*.so"))))
print("el corazón de numpy:", pathlib.Path(np._core._multiarray_umath.__file__).name)
import json.decoder
print("json usa su acelerador en C:", json.decoder.scanstring.__module__)

# 2) El mismo cálculo a los dos lados de la frontera
values = [i * 0.001 for i in range(5_000_000)]
array = np.array(values)
def best(fn, n=3):
    times = []
    for _ in range(n):
        start = time.perf_counter(); fn(); times.append(time.perf_counter() - start)
    return min(times) * 1000
def loop():
    total = 0.0
    for v in values:
        total += v * v
    return total
print(f"suma de cuadrados, 5M · bucle {best(loop):6.1f} ms · sum() {best(lambda: sum(v * v for v in values)):6.1f} ms"
      f" · numpy {best(lambda: float(array @ array)):5.1f} ms")

# 3) El GIL: quién lo suelta
def pure(): 
    x = 0
    for i in range(3_000_000):
        x += i
blob = b"x" * 64_000_000
def native():
    hashlib.sha256(blob).digest()
def speedup(work, threads=4):
    start = time.perf_counter()
    for _ in range(threads):
        work()
    sequential = time.perf_counter() - start
    start = time.perf_counter()
    pool = [threading.Thread(target=work) for _ in range(threads)]
    for t in pool: t.start()
    for t in pool: t.join()
    return sequential / (time.perf_counter() - start)
print(f"GIL activo: {sys._is_gil_enabled()} · 4 hilos, Python puro: {speedup(pure):.2f}× · 4 hilos, sha256 en C: {speedup(native):.2f}×")
EOF
docker run --rm --label curso=python-for-java-devs -v "$PWD:/w" -w /w python:3.14.7 sh -c 'pip install -q --root-user-action=ignore numpy==2.5.3 >/dev/null 2>&1; python frontera.py'

# --- 2026-10-05T20:45:58 · Check header format and probado.py replacements
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs && sed -n 1,30p op131-pk01-el-modelo-real.md | head -12; grep -n "probado\|sin correr\|Salida esperada" /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516/probado.py | head

# --- 2026-10-05T20:46:56 · Re-run ff01 from doc, mark, check URLs
python3 - <<'EOF'
p='op139-ff01-el-modelo.md'
s=open(p).read()
old='''3. Importa `json` con el acelerador deshabilitado (`import json.decoder; json.decoder.c_scanstring = None` antes de cargar) y mide `json.loads` de un archivo grande.
   **Criterio:** los dos tiempos.'''
new='''3. Compara `json.decoder.scanstring` (C) con `json.decoder.py_scanstring` (Python) sobre una cadena JSON de un millón de caracteres. **Criterio:** los dos tiempos.'''
assert old in s
s=s.replace(old,new); open(p,'w').write(s)
EOF
cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516 && python3 humo.py op139-ff01-el-modelo.md ff01 'frontera.py=@frontera.py' --pip numpy==2.5.3 --cmd "python frontera.py; python -c 'import json.decoder as d; print(d.py_scanstring, d.scanstring)'" && python3 plan.py 139 139 ✅ ✅ | tail -1; python3 verificar_urls.py ../../cursos-algoritmos-lenguajes/python-for-java-devs/op139-ff01-el-modelo.md | tail -3

# --- 2026-10-05T20:47:28 · Measure ctypes vs cffi in container
mkdir -p /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516/salidas/ff02 && cd $_ && cat > suavizado.c <<'EOF'
/* Exponential smoothing: out[i] = alpha * x[i] + (1 - alpha) * out[i - 1]. */
void ema(const double *x, double *out, long n, double alpha) {
    double s = x[0];
    for (long i = 0; i < n; i++) {
        s = alpha * x[i] + (1.0 - alpha) * s;
        out[i] = s;
    }
}

double add(double a, double b) { return a + b; }
EOF
cat > frontera_c.py <<'EOF'
"""La misma función en Python y en C, llamada con ctypes y con cffi, y el primer segfault."""

import array
import ctypes
import math
import subprocess
import sys
import time

from cffi import FFI

subprocess.run(["gcc", "-O2", "-shared", "-fPIC", "-o", "libsuavizado.so", "suavizado.c"], check=True)

N, ALPHA = 2_000_000, 0.1
x = array.array("d", (math.sin(i / 1000) * 100 + 500 for i in range(N)))


def ema_python(x, alpha):
    out, s = [0.0] * len(x), x[0]
    for i, v in enumerate(x):
        s = alpha * v + (1 - alpha) * s
        out[i] = s
    return out


def timed(fn):
    best = min(_once(fn) for _ in range(3))
    return f"{best * 1000:7.1f} ms"


def _once(fn):
    start = time.perf_counter(); fn(); return time.perf_counter() - start


# ctypes: se declara la firma a mano
lib = ctypes.CDLL("./libsuavizado.so")
lib.ema.argtypes = [ctypes.POINTER(ctypes.c_double), ctypes.POINTER(ctypes.c_double), ctypes.c_long, ctypes.c_double]
lib.ema.restype = None
lib.add.argtypes, lib.add.restype = [ctypes.c_double, ctypes.c_double], ctypes.c_double
out_c = array.array("d", bytes(8 * N))
as_ptr = lambda a: (ctypes.c_double * len(a)).from_buffer(a)


def ema_ctypes():
    lib.ema(as_ptr(x), as_ptr(out_c), N, ALPHA)


# cffi, modo ABI: la firma se copia del encabezado de C
ffi = FFI()
ffi.cdef("void ema(const double *x, double *out, long n, double alpha); double add(double a, double b);")
clib = ffi.dlopen("./libsuavizado.so")
out_f = array.array("d", bytes(8 * N))


def ema_cffi():
    clib.ema(ffi.from_buffer("double[]", x), ffi.from_buffer("double[]", out_f), N, ALPHA)


print(f"ema de {N:,} valores · Python {timed(lambda: ema_python(x, ALPHA))} · ctypes {timed(ema_ctypes)} · cffi {timed(ema_cffi)}")
ref = ema_python(x, ALPHA)
print("los tres coinciden:", max(abs(a - b) for a, b in zip(ref, out_c)) < 1e-9 and list(out_c) == list(out_f))

# El costo de cruzar: un millón de llamadas a una suma
calls = 1_000_000
py_add = lambda a, b: a + b
for name, f in (("Python", py_add), ("ctypes", lib.add), ("cffi", clib.add)):
    start = time.perf_counter()
    for _ in range(calls):
        f(1.0, 2.0)
    print(f"1M llamadas a add() · {name:<6} {(time.perf_counter() - start) * 1000:6.0f} ms")

# El primer segfault: leer la dirección 0
r = subprocess.run([sys.executable, "-X", "faulthandler", "-c", "import ctypes; ctypes.string_at(0)"],
                   capture_output=True, text=True)
print("código de salida:", r.returncode, "·", r.stderr.splitlines()[0])
EOF
docker run --rm --label curso=python-for-java-devs -v "$PWD:/w" -w /w python:3.14.7 sh -c 'pip install -q --root-user-action=ignore cffi==2.1.1 >/dev/null 2>&1; python frontera_c.py'

# --- 2026-10-05T20:48:31 · Re-run ff02 from doc plus restype check
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs && python3 - <<'EOF'
p='op140-ff02-ctypes-y-cffi.md'
s=open(p).read()
old=s[s.index("**El GIL tomado.**"):s.index("---\n\n## ⚖️ 5")]
new='''**El GIL suelto sin saberlo.** `ctypes` (con `CDLL`; `PyDLL` no) y `cffi` sueltan el GIL durante la llamada. Es lo que permite paralelizar con hilos, y también lo
que permite que dos hilos de Python entren a la vez en una biblioteca de C que no es segura para hilos y corrompan su estado. Se protege con un `threading.Lock`
o se lee la documentación de la biblioteca antes.

'''
s=s.replace(old,new); open(p,'w').write(s)
EOF
cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516 && python3 humo.py op140-ff02-ctypes-y-cffi.md ff02 'suavizado.c=@suavizado.c' 'frontera_c.py="""La misma' --pip cffi==2.1.1 --cmd "python frontera_c.py; python -c 'import ctypes; l=ctypes.CDLL(\"./libsuavizado.so\"); l.add.argtypes=[ctypes.c_double]*2; print(\"sin restype:\", l.add(1.0, 2.0))'"

# --- 2026-10-05T20:48:42 · Mark ff02, URLs, verifier
python3 plan.py 140 140 ✅ ✅ | tail -1; python3 verificar_urls.py ../../cursos-algoritmos-lenguajes/python-for-java-devs/op140-ff02-ctypes-y-cffi.md | tail -2; cd ../../cursos-algoritmos-lenguajes/python-for-java-devs && python3 prompts/verificar-corpus.py 2>&1 | grep -E "op139|op140|errores"

# --- 2026-10-05T20:48:53 · Draft Cython variants
mkdir -p /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516/salidas/ff03 && cd $_ && cat > ema_v0.pyx <<'EOF'
# Paso 0: el mismo código de Python, sin una sola anotación.
def ema(x, alpha):
    out, s = [0.0] * len(x), x[0]
    for i, v in enumerate(x):
        s = alpha * v + (1 - alpha) * s
        out[i] = s
    return out
EOF
cat > ema_v1.pyx <<'EOF'
# Paso 1: tipos de C para los escalares.
def ema(x, double alpha):
    cdef double s = x[0], v
    cdef Py_ssize_t i
    out = [0.0] * len(x)
    for i in range(len(x)):
        v = x[i]
        s = alpha * v + (1 - alpha) * s
        out[i] = s
    return out
EOF
cat > ema_v2.pyx <<'EOF'
# Paso 2: memoryviews tipadas: el bucle ya no toca objetos de Python.
def ema(double[:] x, double alpha):
    cdef Py_ssize_t i, n = x.shape[0]
    cdef double s = x[0]
    cdef double[:] out = bytearray(8 * n).cast("d") if False else None
    import array
    res = array.array("d", bytes(8 * n))
    out = res
    for i in range(n):
        s = alpha * x[i] + (1 - alpha) * s
        out[i] = s
    return res
EOF
echo draft

# --- 2026-10-05T20:49:05 · Build and measure Cython variants
cat > ema_v2.pyx <<'EOF'
# Paso 2: memoryviews tipadas; el bucle ya no toca objetos de Python.
from cpython cimport array
import array


def ema(double[:] x, double alpha):
    cdef Py_ssize_t i, n = x.shape[0]
    cdef double s = x[0]
    result = array.array("d", bytes(8 * n))
    cdef double[:] out = result
    for i in range(n):
        s = alpha * x[i] + (1 - alpha) * s
        out[i] = s
    return result
EOF
sed -e '1s/.*/# Paso 3: sin revisión de límites ni índices negativos./' -e 's/^def ema/@cython.boundscheck(False)\n@cython.wraparound(False)\ndef ema/' ema_v2.pyx | sed '2i cimport cython' > ema_v3.pyx
cat ema_v3.pyx
cat > medir.py <<'EOF'
"""El suavizado en Python y en cuatro pasos de Cython, medido, y cuántas líneas siguen tocando Python."""

import array
import math
import re
import subprocess
import time

subprocess.run(["cythonize", "-q", "-i", "-3", "-a", "ema_v0.pyx", "ema_v1.pyx", "ema_v2.pyx", "ema_v3.pyx"],
               check=True, capture_output=True)
import ema_v0, ema_v1, ema_v2, ema_v3  # noqa: E401  — compilados recién


def ema_python(x, alpha):
    out, s = [0.0] * len(x), x[0]
    for i, v in enumerate(x):
        s = alpha * v + (1 - alpha) * s
        out[i] = s
    return out


N, ALPHA = 2_000_000, 0.1
x = array.array("d", (math.sin(i / 1000) * 100 + 500 for i in range(N)))
reference = ema_python(x, ALPHA)
for name, fn in (("Python", ema_python), ("Cython paso 0", ema_v0.ema), ("Cython paso 1", ema_v1.ema),
                 ("Cython paso 2", ema_v2.ema), ("Cython paso 3", ema_v3.ema)):
    best = min(_ for _ in [(lambda: (t := time.perf_counter(), fn(x, ALPHA), time.perf_counter() - t)[2])() for _ in range(3)])
    same = list(fn(x, ALPHA)) == reference
    module = name.replace("Cython paso ", "ema_v")
    yellow = ""
    if module != "Python":
        html = open(f"{module}.html", encoding="utf-8").read()
        yellow = f" · líneas que tocan Python: {len(re.findall(r'class=\"score-[1-9]', html))}"
    print(f"{name:<14} {best * 1000:7.1f} ms · igual: {same}{yellow}")
EOF
docker run --rm --label curso=python-for-java-devs -v "$PWD:/w" -w /w python:3.14.7 sh -c 'pip install -q --root-user-action=ignore Cython==3.3.0 >/dev/null 2>&1; python medir.py'

# --- 2026-10-05T20:49:15 · Rerun Cython measurement
cat > ema_v3.pyx <<'EOF'
# Paso 3: sin revisión de límites ni índices negativos.
cimport cython
from cpython cimport array
import array


@cython.boundscheck(False)
@cython.wraparound(False)
def ema(double[:] x, double alpha):
    cdef Py_ssize_t i, n = x.shape[0]
    cdef double s = x[0]
    result = array.array("d", bytes(8 * n))
    cdef double[:] out = result
    for i in range(n):
        s = alpha * x[i] + (1 - alpha) * s
        out[i] = s
    return result
EOF
python3 - <<'EOF'
p='medir.py'; s=open(p).read()
s=s.replace('''    best = min(_ for _ in [(lambda: (t := time.perf_counter(), fn(x, ALPHA), time.perf_counter() - t)[2])() for _ in range(3)])
''','''    times = []
    for _ in range(3):
        start = time.perf_counter(); fn(x, ALPHA); times.append(time.perf_counter() - start)
    best = min(times)
''')
open(p,'w').write(s)
EOF
docker run --rm --label curso=python-for-java-devs -v "$PWD:/w" -w /w python:3.14.7 sh -c 'pip install -q --root-user-action=ignore Cython==3.3.0 >/dev/null 2>&1; python medir.py; ls -la *.so | awk "{print \$5, \$9}"'

# --- 2026-10-05T20:49:24 · See cythonize error
docker run --rm --label curso=python-for-java-devs -v "$PWD:/w" -w /w python:3.14.7 sh -c 'pip install -q --root-user-action=ignore Cython==3.3.0 >/dev/null 2>&1; cythonize -q -i -3 -a ema_v0.pyx ema_v1.pyx ema_v2.pyx ema_v3.pyx 2>&1 | grep -v "^\s*$" | head -30'

# --- 2026-10-05T20:49:32 · Rerun with setuptools
docker run --rm --label curso=python-for-java-devs -v "$PWD:/w" -w /w python:3.14.7 sh -c 'pip install -q --root-user-action=ignore Cython==3.3.0 setuptools==84.0.0 >/dev/null 2>&1; python medir.py; ls -la *.so | awk "{print \$5, \$9}"'

# --- 2026-10-05T20:49:50 · Inspect Cython annotation HTML classes
grep -o 'class="[^"]*score[^"]*"' ema_v0.html | sort | uniq -c | head; grep -o 'class="[^"]*score[^"]*"' ema_v3.html | sort | uniq -c | head

# --- 2026-10-05T20:50:02 · Rerun Cython with diff and loop-line score, FMA check
python3 - <<'EOF'
p='medir.py'; s=open(p).read()
s=s.replace('''    same = list(fn(x, ALPHA)) == reference
''','''    diff = max(abs(a - b) for a, b in zip(fn(x, ALPHA), reference))
''')
s=s.replace('''        yellow = f" · líneas que tocan Python: {len(re.findall(r'class=\\"score-[1-9]', html))}"
    print(f"{name:<14} {best * 1000:7.1f} ms · igual: {same}{yellow}")''','''        score = re.search(r'score-(\\d+)"[^\\n]*s = alpha', html).group(1)
        yellow = f" · interacciones con Python en la línea del cálculo: {score}"
    print(f"{name:<14} {best * 1000:7.1f} ms · diferencia máx. {diff:.1e}{yellow}")''')
open(p,'w').write(s)
EOF
grep -n "score\|diff" medir.py; rm -f *.so *.c *.html; docker run --rm --label curso=python-for-java-devs -v "$PWD:/w" -w /w python:3.14.7 sh -c 'pip install -q --root-user-action=ignore Cython==3.3.0 setuptools==84.0.0 >/dev/null 2>&1; python medir.py; rm -f *.so; CFLAGS=-ffp-contract=off python medir.py | tail -2'

# --- 2026-10-05T20:50:30 · Test FMA hypothesis for float differences
cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516/salidas/ff02 && cat > fma.py <<'EOF'
import array, ctypes, math, subprocess
N, A = 2_000_000, 0.1
x = array.array("d", (math.sin(i / 1000) * 100 + 500 for i in range(N)))
ref, s = [], x[0]
for v in x:
    s = A * v + (1 - A) * s; ref.append(s)
for flags in ([], ["-ffp-contract=off"]):
    subprocess.run(["gcc", "-O2", *flags, "-shared", "-fPIC", "-o", "l.so", "suavizado.c"], check=True)
    lib = ctypes.CDLL("./l.so" if not flags else "./l2.so") if False else None
    so = "l%d.so" % len(flags); subprocess.run(["cp", "l.so", so])
    lib = ctypes.CDLL("./" + so)
    lib.ema.argtypes = [ctypes.POINTER(ctypes.c_double)] * 2 + [ctypes.c_long, ctypes.c_double]
    out = array.array("d", bytes(8 * N))
    p = lambda a: (ctypes.c_double * N).from_buffer(a)
    lib.ema(p(x), p(out), N, A)
    print(flags, max(abs(a - b) for a, b in zip(out, ref)))
EOF
docker run --rm --label curso=python-for-java-devs -v "$PWD:/w" -w /w python:3.14.7 python fma.py; rm -f l.so l0.so l1.so fma.py

# --- 2026-10-05T20:50:42 · Add FMA note to ff02, show medir.py
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs && python3 - <<'EOF'
p='op140-ff02-ctypes-y-cffi.md'; s=open(p).read()
old="- **`-X faulthandler`**"
new="""- **"Coinciden" es con tolerancia** (`< 1e-9`) contra Python, y exacto entre `ctypes` y `cffi`: el C compilado con `-O2` en ARM difiere de Python en 5,7e-13. Es
  gcc fusionando la multiplicación y la suma en una sola instrucción (FMA), que redondea una vez en vez de dos; con `-ffp-contract=off` la diferencia es 0,0.
- **`-X faulthandler`**"""
assert old in s; s=s.replace(old,new,1); open(p,'w').write(s)
EOF
cp /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516/salidas/ff03/medir.py /dev/stdout | sed -n 1,40p

# --- 2026-10-05T20:51:38 · Rerun ff03 from doc and fp-contract check
cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516 && rm -f salidas/ff03/*.so salidas/ff03/*.c salidas/ff03/*.html && python3 humo.py op141-ff03-cython.md ff03 'ema_v0.pyx=@ema_v0.pyx' 'ema_v1.pyx=@ema_v1.pyx' 'ema_v2.pyx=@ema_v2.pyx' 'ema_v3.pyx=@ema_v3.pyx' 'medir.py=@medir.py' --pip Cython==3.3.0 setuptools==84.0.0 --cmd 'python medir.py; rm -f *.so *.c *.html; CFLAGS="-ffp-contract=off" python medir.py 2>&1 | tail -2'

# --- 2026-10-05T20:51:42 · Rerun ff03 with content prefixes
cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516 && python3 humo.py op141-ff03-cython.md ff03 'ema_v0.pyx=# Paso 0' 'ema_v1.pyx=# Paso 1' 'ema_v2.pyx=# Paso 2' 'ema_v3.pyx=# Paso 3' 'medir.py=@medir.py' --pip Cython==3.3.0 setuptools==84.0.0 --cmd 'python medir.py; rm -f *.so *.c *.html; CFLAGS="-ffp-contract=off" python medir.py 2>&1 | tail -2'

# --- 2026-10-05T20:51:46 · Rerun ff03 extraction by prefix
cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516 && python3 humo.py op141-ff03-cython.md ff03 'ema_v0.pyx=# Paso 0' 'ema_v1.pyx=# Paso 1' 'ema_v2.pyx=# Paso 2' 'ema_v3.pyx=# Paso 3' 'medir.py="""El suavizado' --pip Cython==3.3.0 setuptools==84.0.0 --cmd 'python medir.py; rm -f *.so *.c *.html; CFLAGS="-ffp-contract=off" python medir.py 2>&1 | tail -2'

# --- 2026-10-05T20:52:16 · Fix ff03 FMA claims, mark, check URLs
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs && python3 - <<'EOF'
p='op141-ff03-cython.md'; s=open(p).read()
reps=[
("son la revisión del índice, que el procesador predice siempre bien en un bucle así.","son la revisión del índice, una comparación que en un bucle así siempre da lo mismo y casi no cuesta."),
("La diferencia de 5,7e-13 desde el paso 1 es el compilador de C\nfusionando la multiplicación y la suma en una instrucción (FMA, `ff02`), no un error de Cython.",
 "La diferencia de 5,7e-13 desde el paso 1 es el compilador de C\nfusionando la multiplicación y la suma en una instrucción (FMA, `ff02`), no un error de Cython: compilado con `CFLAGS=-ffp-contract=off`, la diferencia es\n0,0 y el paso 3 tarda **13,2 ms** en vez de 8,6. La FMA es más exacta y un 35% más rápida; lo que no es, es idéntica a Python."),
("6. Compila con `-ffp-contract=off` (variable `CFLAGS`). **Criterio:** la diferencia contra Python baja a cero, y el tiempo no cambia.",
 "6. Compila con `-ffp-contract=off` (variable `CFLAGS`). **Criterio:** la diferencia contra Python baja a cero, y explicas por qué el tiempo sube."),
]
for a,b in reps:
    assert a in s, a[:40]; s=s.replace(a,b)
open(p,'w').write(s)
EOF
cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516 && python3 plan.py 141 141 ✅ ✅ | tail -1; python3 verificar_urls.py ../../cursos-algoritmos-lenguajes/python-for-java-devs/op141-ff03-cython.md | tail -2

# --- 2026-10-05T20:52:32 · Measure numba JIT behavior in container
mkdir -p /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516/salidas/ff04 && cd $_ && cat > jit.py <<'EOF'
"""numba sobre el suavizado: el costo de compilar, el caché en disco, prange y lo que no compila."""

import math
import os
import time

import numpy as np
from numba import njit, prange
from numba.core.errors import TypingError


@njit(cache=True)
def ema(x, alpha):
    out = np.empty_like(x)
    s = x[0]
    for i in range(x.shape[0]):
        s = alpha * x[i] + (1 - alpha) * s
        out[i] = s
    return out


@njit(parallel=True, cache=True)
def ema_many(series, alpha):
    out = np.empty_like(series)
    for k in prange(series.shape[0]):          # cada serie es independiente: esas sí se reparten
        s = series[k, 0]
        for i in range(series.shape[1]):
            s = alpha * series[k, i] + (1 - alpha) * s
            out[k, i] = s
    return out


def ms(fn):
    start = time.perf_counter(); fn(); return (time.perf_counter() - start) * 1000


N, ALPHA = 2_000_000, 0.1
x = np.sin(np.arange(N) / 1000) * 100 + 500
print(f"primera llamada (compila o lee el caché): {ms(lambda: ema(x, ALPHA)):7.1f} ms")
print(f"segunda llamada:                         {min(ms(lambda: ema(x, ALPHA)) for _ in range(3)):7.1f} ms")

series = np.tile(x, (8, 1))
ema_many(series, ALPHA)
one_by_one = min(ms(lambda: [ema(s, ALPHA) for s in series]) for _ in range(3))
parallel = min(ms(lambda: ema_many(series, ALPHA)) for _ in range(3))
print(f"8 series · una tras otra {one_by_one:6.1f} ms · prange en {os.cpu_count()} núcleos {parallel:6.1f} ms ({one_by_one / parallel:.1f}×)")


@njit
def by_branch(names, amounts):
    totals = {}
    for name, amount in zip(names, amounts):
        totals[name] = totals.get(name, 0.0) + amount
    return totals


try:
    by_branch(["Centro", "Suba"], [1.0, 2.0])
except TypingError as error:
    print("lo que no compila:", str(error).splitlines()[0][:90])
EOF
docker run --rm --label curso=python-for-java-devs -v "$PWD:/w" -w /w python:3.14.7 sh -c 'pip install -q --root-user-action=ignore numba==0.68.0 >/dev/null 2>&1; pip list 2>/dev/null | grep -iE "^(numba|numpy|llvmlite) "; python jit.py; echo "--- segundo proceso"; python jit.py | head -1'

# --- 2026-10-05T20:52:54 · Rerun numba with Decimal unsupported example
python3 - <<'EOF'
p='jit.py'; s=open(p).read()
i=s.index("@njit\ndef by_branch")
s=s[:i]+'''@njit
def total_exact(amounts):
    return sum(Decimal(a) for a in amounts)       # un objeto de Python que numba no conoce


try:
    total_exact(np.array([1.0, 2.0]))
except TypingError as error:
    print("lo que no compila:", next(l for l in str(error).splitlines() if "Decimal" in l).strip())
'''
s=s.replace("import time\n","import time\nfrom decimal import Decimal\n")
open(p,'w').write(s)
EOF
rm -rf __pycache__; docker run --rm --label curso=python-for-java-devs -v "$PWD:/w" -w /w python:3.14.7 sh -c 'pip install -q --root-user-action=ignore numba==0.68.0 >/dev/null 2>&1; python jit.py; echo "--- segundo proceso"; python jit.py | head -1; ls __pycache__ | head'

# --- 2026-10-05T20:53:14 · Rerun numba with two unsupported cases
python3 - <<'EOF'
p='jit.py'; s=open(p).read()
s=s.replace('''@njit
def total_exact(amounts):
    return sum(Decimal(a) for a in amounts)       # un objeto de Python que numba no conoce


try:
    total_exact(np.array([1.0, 2.0]))
except TypingError as error:
    print("lo que no compila:", next(l for l in str(error).splitlines() if "Decimal" in l).strip())
''','''@njit
def total_with_generator(amounts):
    return sum(a for a in amounts)               # Python válido; numba no compila generadores aquí


@njit
def total_exact(amounts):
    total = Decimal(0)                           # un objeto de Python que numba no conoce
    for a in amounts:
        total += Decimal(a)
    return total


for fn in (total_with_generator, total_exact):
    try:
        fn(np.array([1.0, 2.0]))
    except NumbaError as error:
        reason = next(l for l in str(error).splitlines()[1:] if l.strip())
        print(f"{fn.__name__} no compila: {reason.strip()[:80]}")
''')
s=s.replace("from numba.core.errors import TypingError","from numba.core.errors import NumbaError")
open(p,'w').write(s)
EOF
rm -rf __pycache__; docker run --rm --label curso=python-for-java-devs -v "$PWD:/w" -w /w python:3.14.7 sh -c 'pip install -q --root-user-action=ignore numba==0.68.0 >/dev/null 2>&1; python jit.py 2>&1; echo "--- segundo proceso"; python jit.py 2>&1| head -1'

# --- 2026-10-05T20:53:33 · Measure numba import time
docker run --rm --label curso=python-for-java-devs -v "$PWD:/w" -w /w python:3.14.7 sh -c 'pip install -q --root-user-action=ignore numba==0.68.0 >/dev/null 2>&1; for i in 1 2 3; do python3 -X importtime -c "import numba" 2>&1 | tail -1; done; for i in 1 2 3; do python3 -X importtime -c "import numpy" 2>&1 | tail -1; done'

# --- 2026-10-05T20:53:48 · Show final jit.py
cat /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516/salidas/ff04/jit.py

# --- 2026-10-05T20:54:34 · Rerun ff04 from doc, check signatures claim
cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516 && rm -rf salidas/ff04/__pycache__ && python3 humo.py op142-ff04-numba.md ff04 'jit.py=@jit.py' --pip numba==0.68.0 --cmd 'python3 -X importtime -c "import numba" 2>&1 | tail -1; python3 jit.py; python3 jit.py | head -1; python3 -c "
import numpy as np, jit
jit.ema(np.zeros(3, dtype=np.float32), 0.1); print(jit.ema.signatures)" | tail -1'

# --- 2026-10-05T20:55:14 · Mark ff04, check URLs and YouTube titles
python3 plan.py 142 142 ✅ ✅ | tail -1; python3 verificar_urls.py ../../cursos-algoritmos-lenguajes/python-for-java-devs/op142-ff04-numba.md | tail -3; curl -s "https://www.youtube.com/oembed?url=https://www.youtube.com/watch?v=Ftnlz1dtpQU&format=json" | head -c 300; echo; curl -s "https://www.youtube.com/oembed?url=https://www.youtube.com/watch?v=P3AyI_u66Bw&format=json" | head -c 300

# --- 2026-10-05T20:55:30 · Verify replacement talk and update ff04
curl -s "https://www.youtube.com/oembed?url=https://www.youtube.com/watch?v=-3KMZEPXQNQ&format=json" | head -c 160; echo; cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs && python3 - <<'EOF'
p='op142-ff04-numba.md'; s=open(p).read()
old="- Stanley Seibert, *Numba: Flexible analytics written in Python with machine-code speeds* (PyData), la explicación de sus autores: https://www.youtube.com/watch?v=Ftnlz1dtpQU"
new="- Antoine Pitrou, *Numba, a JIT compiler for fast numerical code* (EuroPython 2015), de uno de sus desarrolladores; anterior a las versiones actuales, y el modelo\n  sigue igual: https://www.youtube.com/watch?v=-3KMZEPXQNQ"
assert old in s; s=s.replace(old,new); open(p,'w').write(s)
EOF

# --- 2026-10-05T20:55:38 · Check PyO3 crate versions
mkdir -p /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516/salidas/ff05/ema_rs/src && cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516/salidas/ff05 && curl -s https://crates.io/api/v1/crates/pyo3 -A "curso" | python3 -c "import json,sys; d=json.load(sys.stdin)['crate']; print(d['max_stable_version'], d['updated_at'])"; curl -s https://crates.io/api/v1/crates/numpy -A curso | python3 -c "import json,sys; d=json.load(sys.stdin)['crate']; print(d['max_stable_version'])"

# --- 2026-10-05T20:56:17 · Build PyO3/pybind11/nanobind extensions and measure
mkdir -p ema_pb ema_nb && cat > ema_rs/Cargo.toml <<'EOF'
[package]
name = "ema_rs"
version = "0.1.0"
edition = "2021"

[lib]
crate-type = ["cdylib"]

[dependencies]
pyo3 = "0.29.3"
numpy = "0.29.0"
EOF
cat > ema_rs/pyproject.toml <<'EOF'
[build-system]
requires = ["maturin>=1.15,<2"]
build-backend = "maturin"

[project]
name = "ema-rs"
version = "0.1.0"
EOF
cat > ema_rs/src/lib.rs <<'EOF'
use numpy::{PyArray1, PyReadonlyArray1};
use pyo3::prelude::*;

/// Exponential smoothing over a NumPy array.
#[pyfunction]
fn ema<'py>(py: Python<'py>, x: PyReadonlyArray1<'py, f64>, alpha: f64) -> PyResult<Bound<'py, PyArray1<f64>>> {
    let x = x.as_slice()?;
    let mut out = Vec::with_capacity(x.len());
    let mut s = x[0];
    for &v in x {
        s = alpha * v + (1.0 - alpha) * s;
        out.push(s);
    }
    Ok(PyArray1::from_vec(py, out))
}

#[pymodule]
fn ema_rs(m: &Bound<'_, PyModule>) -> PyResult<()> {
    m.add_function(wrap_pyfunction!(ema, m)?)
}
EOF
cat > ema_pb/ema_pb.cpp <<'EOF'
#include <pybind11/numpy.h>
#include <pybind11/pybind11.h>

namespace py = pybind11;

// Exponential smoothing over a NumPy array.
py::array_t<double> ema(py::array_t<double, py::array::c_style | py::array::forcecast> x, double alpha) {
    auto in = x.unchecked<1>();
    py::ssize_t n = in.shape(0);
    py::array_t<double> out(n);
    auto o = out.mutable_unchecked<1>();
    double s = in(0);
    for (py::ssize_t i = 0; i < n; i++) {
        s = alpha * in(i) + (1 - alpha) * s;
        o(i) = s;
    }
    return out;
}

PYBIND11_MODULE(ema_pb, m) { m.def("ema", &ema); }
EOF
cat > ema_pb/pyproject.toml <<'EOF'
[build-system]
requires = ["scikit-build-core>=1.1", "pybind11>=3.1"]
build-backend = "scikit_build_core.build"

[project]
name = "ema-pb"
version = "0.1.0"
EOF
cat > ema_pb/CMakeLists.txt <<'EOF'
cmake_minimum_required(VERSION 3.15...3.31)
project(ema_pb LANGUAGES CXX)
find_package(Python COMPONENTS Interpreter Development.Module REQUIRED)
find_package(pybind11 CONFIG REQUIRED)
pybind11_add_module(ema_pb ema_pb.cpp)
install(TARGETS ema_pb LIBRARY DESTINATION .)
EOF
cat > ema_nb/ema_nb.cpp <<'EOF'
#include <nanobind/nanobind.h>
#include <nanobind/ndarray.h>

namespace nb = nanobind;
using Out = nb::ndarray<nb::numpy, double, nb::ndim<1>>;

// Exponential smoothing over a NumPy array.
Out ema(nb::ndarray<const double, nb::ndim<1>, nb::c_contig> x, double alpha) {
    size_t n = x.shape(0);
    const double *in = x.data();
    double *out = new double[n];
    nb::capsule owner(out, [](void *p) noexcept { delete[] static_cast<double *>(p); });
    double s = in[0];
    for (size_t i = 0; i < n; i++) {
        s = alpha * in[i] + (1 - alpha) * s;
        out[i] = s;
    }
    return Out(out, {n}, owner);
}

NB_MODULE(ema_nb, m) { m.def("ema", &ema); }
EOF
sed -e 's/ema-pb/ema-nb/' -e 's/pybind11>=3.1/nanobind>=2.0/' ema_pb/pyproject.toml > ema_nb/pyproject.toml
cat > ema_nb/CMakeLists.txt <<'EOF'
cmake_minimum_required(VERSION 3.15...3.31)
project(ema_nb LANGUAGES CXX)
find_package(Python COMPONENTS Interpreter Development.Module REQUIRED)
find_package(nanobind CONFIG REQUIRED)
nanobind_add_module(ema_nb ema_nb.cpp)
install(TARGETS ema_nb LIBRARY DESTINATION .)
EOF
cat > construir.sh <<'EOF'
set -euo pipefail
for pkg in ema_rs ema_pb ema_nb; do
  start=$(date +%s)
  pip wheel --quiet --no-deps --wheel-dir dist "./$pkg" >/dev/null 2>&1 || { echo "$pkg: falló la construcción"; continue; }
  wheel=$(ls dist/"${pkg/_/_}"*.whl)
  printf '%-7s construcción %3s s · rueda %4s KB · %s\n' "$pkg" "$(( $(date +%s) - start ))" "$(( $(stat -c %s "$wheel") / 1024 ))" "$(basename "$wheel")"
done
pip install --quiet dist/*.whl
EOF
cat > medir.py <<'EOF'
"""La misma función en Rust (PyO3), C++ (pybind11) y C++ (nanobind), llamada desde Python y medida."""

import time

import numpy as np
import ema_nb
import ema_pb
import ema_rs

N, ALPHA = 2_000_000, 0.1
x = np.sin(np.arange(N) / 1000) * 100 + 500
reference = ema_pb.ema(x, ALPHA)
for name, module in (("PyO3", ema_rs), ("pybind11", ema_pb), ("nanobind", ema_nb)):
    times = []
    for _ in range(5):
        start = time.perf_counter(); result = module.ema(x, ALPHA); times.append(time.perf_counter() - start)
    calls = time.perf_counter()
    for _ in range(100_000):
        module.ema(x[:1], ALPHA)
    per_call = (time.perf_counter() - calls) * 10                          # µs por llamada
    print(f"{name:<9} {min(times) * 1000:5.1f} ms · llamada mínima {per_call:4.2f} µs · igual: {np.array_equal(result, reference)}")
EOF
docker run --rm --label curso=python-for-java-devs -v "$PWD:/w" -w /w python:3.14.7 sh -c 'apt-get -qq update >/dev/null 2>&1; apt-get -qq install -y cargo >/dev/null 2>&1; rustc --version; export PIP_ROOT_USER_ACTION=ignore; pip install -q numpy==2.5.3 cmake >/dev/null 2>&1; bash construir.sh; python medir.py' 2>&1 | tail -20

# --- 2026-10-05T20:57:05 · Diagnose Rust build failure
mv ema_rs rs && mv ema_pb pb && mv ema_nb nb && rm -rf dist && docker run --rm --label curso=python-for-java-devs -v "$PWD:/w" -w /w python:3.14.7 sh -c 'apt-get -qq update >/dev/null 2>&1; apt-get -qq install -y cargo >/dev/null 2>&1; export PIP_ROOT_USER_ACTION=ignore; pip wheel --no-deps -w dist ./rs 2>&1 | grep -iE "error|requires|rustc" | head -15'

# --- 2026-10-05T20:57:30 · Show maturin error details
docker run --rm --label curso=python-for-java-devs -v "$PWD:/w" -w /w python:3.14.7 sh -c 'apt-get -qq update >/dev/null 2>&1; apt-get -qq install -y cargo >/dev/null 2>&1; export PIP_ROOT_USER_ACTION=ignore; pip wheel --no-deps -w dist ./rs 2>&1 | grep -B2 -A8 -iE "💥|error:|rust-version|msrv" | head -40'

# --- 2026-10-05T20:57:56 · Rebuild all three and measure
printf '\n[tool.maturin]\nmodule-name = "ema_rs"\n' >> rs/pyproject.toml && cat > construir.sh <<'EOF'
set -euo pipefail
for dir in rs pb nb; do
  start=$(date +%s)
  pip wheel --quiet --no-deps --wheel-dir "dist/$dir" "./$dir" >/dev/null 2>&1 || { echo "$dir: falló la construcción"; continue; }
  wheel=$(ls dist/"$dir"/*.whl)
  printf '%-3s construcción %3s s · rueda %4s KB · %s\n' "$dir" "$(( $(date +%s) - start ))" "$(( $(stat -c %s "$wheel") / 1024 ))" "$(basename "$wheel")"
done
pip install --quiet dist/*/*.whl
EOF
rm -rf dist; docker run --rm --label curso=python-for-java-devs -v "$PWD:/w" -w /w python:3.14.7 sh -c 'apt-get -qq update >/dev/null 2>&1; apt-get -qq install -y cargo >/dev/null 2>&1; export PIP_ROOT_USER_ACTION=ignore; pip install -q numpy==2.5.3 cmake >/dev/null 2>&1; bash construir.sh; python medir.py' 2>&1 | tail -20

# --- 2026-10-05T20:59:01 · Measure with Python reference and per-call
cat > medir.py <<'EOF'
"""La misma función en Rust (PyO3), C++ (pybind11) y C++ (nanobind), llamada desde Python y medida."""

import time

import numpy as np
import ema_nb
import ema_pb
import ema_rs


def ema_python(x, alpha):
    out, s = [], x[0]
    for v in x:
        s = alpha * v + (1 - alpha) * s
        out.append(s)
    return np.array(out)


N, ALPHA = 2_000_000, 0.1
x = np.sin(np.arange(N) / 1000) * 100 + 500
reference = ema_python(x.tolist(), ALPHA)
one = x[:1]
for name, module in (("PyO3", ema_rs), ("pybind11", ema_pb), ("nanobind", ema_nb)):
    times = []
    for _ in range(5):
        start = time.perf_counter(); result = module.ema(x, ALPHA); times.append(time.perf_counter() - start)
    start = time.perf_counter()
    for _ in range(100_000):
        module.ema(one, ALPHA)
    per_call = (time.perf_counter() - start) * 10                         # µs por llamada
    print(f"{name:<9} {min(times) * 1000:4.1f} ms · llamada con un elemento {per_call:4.2f} µs"
          f" · diferencia con Python {np.abs(result - reference).max():.1e}")
EOF
docker run --rm --label curso=python-for-java-devs -v "$PWD:/w" -w /w python:3.14.7 sh -c 'export PIP_ROOT_USER_ACTION=ignore; pip install -q numpy==2.5.3 >/dev/null 2>&1; pip install -q dist/*/*.whl; python medir.py; wc -l rs/src/lib.rs pb/ema_pb.cpp nb/ema_nb.cpp | head -3'

# --- 2026-10-05T20:59:15 · Show generated pyproject files
cat nb/pyproject.toml rs/pyproject.toml

# --- 2026-10-05T21:00:20 · Rerun ff05 entirely from the doc
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs && python3 - <<'EOF'
p='op143-ff05-rust-y-cpp.md'; s=open(p).read()
old="""El costo por llamada es de fracciones de microsegundo en las tres, centenares de
veces menos que los 0,5 µs… por llamada de `ctypes` en un millón (`ff02`: 497 ms); nanobind, que promete el menor costo, fue el más alto en esta llamada, porque
el resultado se crea con una cápsula que lo libera."""
new="""El costo por llamada es de **0,23 a 0,51 µs**, del orden del de `ctypes` con una suma
(`ff02`: 0,5 µs), aunque aquí cada llamada recibe y crea un arreglo de NumPy; nanobind, que promete el menor costo, fue el más alto en esta llamada, porque el
resultado se crea con una cápsula que lo libera."""
assert old in s; s=s.replace(old,new); open(p,'w').write(s)
EOF
cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516 && rm -rf salidas/ff05b && python3 humo.py op143-ff05-rust-y-cpp.md ff05b 'rs/Cargo.toml=[package]' 'rs/pyproject.toml=[build-system]
requires = ["maturin' 'rs/src/lib.rs=use numpy' 'pb/ema_pb.cpp=#include <pybind11' 'pb/pyproject.toml=[build-system]
requires = ["scikit-build-core>=1.1", "pybind11' 'pb/CMakeLists.txt=cmake_minimum_required(VERSION 3.15...3.31)
project(ema_pb' 'nb/ema_nb.cpp=#include <nanobind' 'nb/pyproject.toml=[build-system]
requires = ["scikit-build-core>=1.1", "nanobind' 'nb/CMakeLists.txt=cmake_minimum_required(VERSION 3.15...3.31)
project(ema_nb' 'construir.sh=set -euo pipefail
for dir' 'medir.py="""La misma función en Rust' --cmd 'apt-get -qq update >/dev/null 2>&1; apt-get -qq install -y cargo >/dev/null 2>&1; export PIP_ROOT_USER_ACTION=ignore; pip install -q numpy==2.5.3 cmake >/dev/null 2>&1; bash construir.sh; cd /tmp && python /w/medir.py' 2>&1 | tail -8

# --- 2026-10-05T21:01:21 · Mark ff05, URLs, verifier
python3 plan.py 143 143 ✅ ✅ | tail -1; python3 verificar_urls.py ../../cursos-algoritmos-lenguajes/python-for-java-devs/op143-ff05-rust-y-cpp.md | tail -2; cd ../../cursos-algoritmos-lenguajes/python-for-java-devs && python3 prompts/verificar-corpus.py 2>&1 | grep -E "op14[0-3]|op139|errores"

# --- 2026-10-05T21:01:42 · Measure zero-copy scenarios in container
mkdir -p /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516/salidas/ff06 && cd $_ && cat > copia_cero.py <<'EOF'
"""Copiar o compartir: memoryview, NumPy, memoria compartida entre procesos y Arrow mapeado de disco."""

import os
import time
from multiprocessing import Process, Queue, shared_memory

import numpy as np
import pyarrow as pa


def rss_mb():
    with open("/proc/self/statm") as f:
        return int(f.read().split()[1]) * os.sysconf("SC_PAGE_SIZE") / 2**20


def timed(fn):
    start = time.perf_counter(); result = fn(); return result, (time.perf_counter() - start) * 1000


def consume_pickled(queue):
    data = queue.get()
    queue.put(float(data.sum()))


def consume_shared(name, n, queue):
    shm = shared_memory.SharedMemory(name=name)
    data = np.ndarray((n,), dtype=np.float64, buffer=shm.buf)
    queue.put(float(data.sum()))
    del data
    shm.close()


if __name__ == "__main__":
    N = 25_000_000                                            # 200 MB de float64
    blob = bytes(200 * 2**20)

    # 1) Rebanar: bytes copia, memoryview no
    before = rss_mb()
    part, ms = timed(lambda: blob[: 100 * 2**20])
    print(f"bytes[:100 MB]      {ms:7.2f} ms · memoria +{rss_mb() - before:5.0f} MB")
    del part
    before = rss_mb()
    view, ms = timed(lambda: memoryview(blob)[: 100 * 2**20])
    print(f"memoryview[:100 MB] {ms:7.2f} ms · memoria +{rss_mb() - before:5.0f} MB")

    # 2) NumPy sobre un buffer ajeno: la misma memoria
    raw = bytearray(8 * 4)
    shared = np.frombuffer(raw, dtype=np.float64)
    shared[0] = 42.0
    print("np.frombuffer comparte la memoria:", raw[:8] == np.float64(42.0).tobytes())

    # 3) Entre procesos: serializar contra memoria compartida
    data = np.random.default_rng(7).random(N)
    queue = Queue()
    worker = Process(target=consume_pickled, args=(queue,))
    start = time.perf_counter(); worker.start(); queue.put(data); result = queue.get(); worker.join()
    print(f"proceso, serializado        {(time.perf_counter() - start) * 1000:7.1f} ms · suma {result:,.0f}")

    shm = shared_memory.SharedMemory(create=True, size=data.nbytes)
    np.ndarray(data.shape, dtype=data.dtype, buffer=shm.buf)[:] = data
    worker = Process(target=consume_shared, args=(shm.name, N, queue))
    start = time.perf_counter(); worker.start(); result = queue.get(); worker.join()
    print(f"proceso, memoria compartida {(time.perf_counter() - start) * 1000:7.1f} ms · suma {result:,.0f}")
    shm.close(); shm.unlink()

    # 4) Arrow: escribir una vez, mapear en vez de leer
    table = pa.table({"valor": data})
    with pa.OSFile("valores.arrow", "wb") as sink, pa.ipc.new_file(sink, table.schema) as writer:
        writer.write_table(table)
    before = rss_mb()
    mapped, ms = timed(lambda: pa.ipc.open_file(pa.memory_map("valores.arrow")).read_all())
    column = mapped.column("valor").to_numpy(zero_copy_only=True)
    print(f"Arrow mapeado de disco {ms:7.2f} ms · memoria +{rss_mb() - before:5.0f} MB · {len(column):,} valores")
    before = rss_mb()
    read, ms = timed(lambda: pa.ipc.open_file(pa.OSFile("valores.arrow")).read_all())
    print(f"Arrow leído a memoria  {ms:7.2f} ms · memoria +{rss_mb() - before:5.0f} MB")
    os.remove("valores.arrow")
EOF
docker run --rm --label curso=python-for-java-devs --shm-size=512m -v "$PWD:/w" -w /w python:3.14.7 sh -c 'pip install -q --root-user-action=ignore numpy==2.5.3 pyarrow==25.0.1 >/dev/null 2>&1; python copia_cero.py'

# --- 2026-10-05T21:08:28 · Check hung run and course containers
cat /private/tmp/claude-501/-Users-oskar-Developer-Learning-courses-ia-generated/5c52573d-4a56-4998-bca3-5d686d0c5368/tasks/b7dfb4m3j.output; docker ps --filter label=curso=python-for-java-devs --format '{{.ID}} {{.Image}} {{.Status}}'

# --- 2026-10-05T21:08:35 · Fix queue deadlock and rerun with timeouts
docker stop 0de06f2ba6cf >/dev/null; cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516/salidas/ff06 && python3 - <<'EOF'
p='copia_cero.py'; s=open(p).read()
reps=[
('''def consume_pickled(queue):
    data = queue.get()
    queue.put(float(data.sum()))''','''def consume_pickled(inbox, outbox):
    outbox.put(float(inbox.get().sum()))'''),
('''    queue = Queue()
    worker = Process(target=consume_pickled, args=(queue,))
    start = time.perf_counter(); worker.start(); queue.put(data); result = queue.get(); worker.join()''',
'''    inbox, queue = Queue(), Queue()                         # dos colas: quien envía no lee su propio envío
    worker = Process(target=consume_pickled, args=(inbox, queue))
    start = time.perf_counter(); worker.start(); inbox.put(data); result = queue.get(); worker.join()'''),
]
for a,b in reps:
    assert a in s; s=s.replace(a,b)
open(p,'w').write(s)
EOF
timeout 400 docker run --rm --label curso=python-for-java-devs --shm-size=512m -v "$PWD:/w" -w /w python:3.14.7 sh -c 'timeout 200 pip install -q --root-user-action=ignore numpy==2.5.3 pyarrow==25.0.1 >/dev/null 2>&1; echo instalado; timeout 150 python copia_cero.py'

# --- 2026-10-05T21:08:53 · Rerun ff06 with single-chunk zero copy
cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516/salidas/ff06 && sed -i '' 's/column = mapped.column("valor").to_numpy(zero_copy_only=True)/column = mapped.column("valor").chunk(0).to_numpy(zero_copy_only=True)   # un solo bloque: se puede sin copiar/' copia_cero.py && rm -f valores.arrow && timeout 400 docker run --rm --label curso=python-for-java-devs --shm-size=512m -v "$PWD:/w" -w /w python:3.14.7 sh -c 'timeout 200 pip install -q --root-user-action=ignore numpy==2.5.3 pyarrow==25.0.1 >/dev/null 2>&1; timeout 150 python copia_cero.py'

# --- 2026-10-05T21:09:05 · Check middle of ff06 script
cat /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516/salidas/ff06/copia_cero.py | sed -n 40,60p

# --- 2026-10-05T21:09:46 · Write ff06 doc and check BufferError claim
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs && python3 - <<'PYEOF'
code = open('/Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516/salidas/ff06/copia_cero.py').read().rstrip()
doc = '''# 🔗 ff06 — El buffer compartido y la copia cero

> Python para desarrolladores Java senior · **Carta** · Track `ff` — La frontera nativa ·
> sección 6 de 8
> Se lee suelta: no hace falta ninguna otra sección de la carta.
> Versiones verificadas contra PyPI el 05/10/2026 · Código probado el 05/10/2026 con Python 3.14.7,
> en contenedor: las salidas son las de esa corrida.

---

## 🎯 1. Qué problema resuelve

Las secciones anteriores cruzaron la frontera con arreglos sin copiarlos: `ctypes` con `from_buffer`, Cython con *memoryviews*, Rust con `as_slice`. Todo eso
descansa en una pieza de CPython que casi nadie nombra: el **protocolo de *buffers***, la forma en que un objeto le presta su memoria a otro sin copiarla. Es lo que
hace que NumPy, Arrow, `bytes`, `mmap` y las extensiones nativas se pasen arreglos de cientos de megas en microsegundos.

Cuando no se usa, el costo aparece en dos lugares: en memoria, porque cada rebanada es una copia, y entre procesos, porque `multiprocessing` serializa con `pickle`
todo lo que envía. Esta sección mide las dos cosas y sus alternativas: `memoryview`, `np.frombuffer`, `shared_memory` y Arrow mapeado desde disco.

---

## 🧠 2. El modelo

```mermaid
flowchart LR
    M[("Bloque de memoria<br/>200 MB")]
    B["bytes / bytearray"] -- dueño --> M
    V["memoryview"] -. presta .-> M
    N["np.frombuffer"] -. presta .-> M
    C["Extensión en C / Rust"] -. presta .-> M
    P["Otro proceso"] -. "shared_memory / mmap" .-> M
```

| Herramienta | Qué comparte | Con quién |
|---|---|---|
| `memoryview` | Una vista (o rebanada) de un objeto con *buffer* | El mismo proceso |
| `np.frombuffer`, `np.ndarray(buffer=…)` | La memoria de otro objeto, como arreglo | El mismo proceso |
| `multiprocessing.shared_memory` | Un bloque de memoria con nombre | Otros procesos de la máquina |
| `mmap`, `pa.memory_map` | Un archivo, como memoria | Cualquier proceso que lo abra; el sistema operativo carga las páginas al leerlas |
| Arrow (formato IPC) | Columnas con un formato fijo en memoria | Procesos y lenguajes (Java, Rust, C++) sin convertir |

### 🩻 Esto sí funciona igual

Es `ByteBuffer.slice()`, `asReadOnlyBuffer()` y `FileChannel.map()` de Java NIO: una vista sobre memoria que no se copia, y un archivo mapeado que el sistema operativo
pagina. Arrow es el mismo formato en Java y en Python; un archivo escrito por uno se mapea desde el otro.

---

## 💻 3. El ejemplo que corre

`copia_cero.py`:

```python
''' + code + '''
```

```bash
pip install numpy pyarrow
python3 copia_cero.py           # en Docker, con --shm-size=512m: shared_memory vive en /dev/shm
```

Salida (Python 3.14.7, 05/10/2026) (los milisegundos son de la máquina que corre):

```text
bytes[:100 MB]        24.87 ms · memoria +  100 MB
memoryview[:100 MB]    0.00 ms · memoria +    0 MB
np.frombuffer comparte la memoria: True
proceso, serializado          449.4 ms · suma 12,501,650
proceso, memoria compartida    26.5 ms · suma 12,501,650
Arrow mapeado de disco   14.53 ms · memoria +    1 MB · 25,000,000 valores
Arrow leído a memoria   222.47 ms · memoria +  192 MB
```

Rebanar 100 MB de un `bytes` copia los 100 MB y tarda 25 ms; la misma rebanada con `memoryview` no copia nada. Pasarle 200 MB a otro proceso por una cola
cuesta **449 ms** —serializar, enviar por una tubería y deserializar—; con `shared_memory` el otro proceso lee el mismo bloque y todo, **incluido arrancar el
proceso**, tarda **26,5 ms**. Y Arrow: abrir el archivo mapeado y tener los 25 millones de valores como arreglo de NumPy cuesta 14,5 ms y un mega; leerlo a memoria,
222 ms y 192 MB.

**Detalles con intención**

- **"memoria +1 MB" del mapeo** no significa que los datos no ocupen memoria: el sistema operativo carga cada página cuando se lee, y la cuenta como caché de archivo,
  compartida y liberable. Sumar la columna la traería entera; lo que no hay es una **copia** en la memoria del proceso.
- **`chunk(0).to_numpy(zero_copy_only=True)`**: una columna de Arrow puede estar en varios bloques; un arreglo de NumPy necesita uno contiguo. Con un bloque, se
  comparte; con varios, `zero_copy_only=True` falla en vez de copiar en silencio.
- **Dos colas en la versión serializada**: con una sola, el proceso principal puede leer su propio envío y el trabajador esperar para siempre. Pasó al probar esta
  sección.
- **`if __name__ == "__main__"`** es obligatorio: desde Python 3.14 el método de arranque por defecto en Linux es `forkserver`, que importa el módulo en cada
  proceso hijo.
- **`shm.unlink()`** borra el bloque del sistema; sin él, queda en `/dev/shm` aunque el programa termine.

---

## ⚠️ 4. Lo que se rompe

**El bloque compartido que nadie borra.** `shared_memory` crea un archivo en `/dev/shm`; un programa que muere sin `unlink()` lo deja ahí, ocupando RAM, hasta
reiniciar. Se envuelve en `try`/`finally` y, en servicios, se limpian los nombres conocidos al arrancar.

**Escribir mientras otro lee.** La memoria compartida no tiene candados: dos procesos que escriben el mismo bloque se pisan. Se comparte para leer, o se coordina con
un `Lock` de `multiprocessing`.

**El `memoryview` que retiene al dueño.** Mientras exista una vista, el objeto original no se libera ni puede cambiar de tamaño (`bytearray.extend` falla con
`BufferError`). Se libera con `view.release()` o saliendo del bloque `with`.

**`/dev/shm` chico en contenedores.** Docker da 64 MB por defecto; un bloque de 200 MB falla con `Bus error`. Se sube con `--shm-size`.

---

## ⚖️ 5. Cuándo NO usarlo

**Para datos chicos.** Serializar un diccionario de cien entradas cuesta microsegundos; la memoria compartida agrega nombres, limpieza y coordinación.

**Si cada proceso puede leer lo suyo.** El camino base lo midió: procesos que leen su propia parte ganan a los que reciben los datos (`BENCHMARKS.md` §14: 1,86×
contra 0,88×). Sin datos que viajen, no hay nada que compartir.

**Entre máquinas.** Esto es memoria de una máquina; entre máquinas, Arrow Flight o un formato en disco compartido.

---

## 🧪 6. Ejercicios (10)

**🟢 Fácil (1–3)**

1. Corre el ejemplo. **Criterio:** las siete líneas, y de dónde salen los 449 ms.
2. Rebana un `bytearray` con `memoryview`, modifica la vista y mira el original. **Criterio:** el cambio aparece en los dos.
3. Intenta `extend` sobre un `bytearray` con una vista viva. **Criterio:** el `BufferError` y cómo se evita.

**🟡 Intermedio (4–6)**

4. Corre la parte de Arrow sumando la columna mapeada. **Criterio:** el tiempo de la suma y la memoria del proceso antes y después.
5. Comparte el arreglo entre cuatro procesos que suman cada uno su cuarta parte. **Criterio:** el tiempo contra hacerlo con cuatro colas.
6. Lee con Java (Arrow para Java) el archivo `valores.arrow`. **Criterio:** los mismos 25 millones de valores, sin conversión.

**🟠 Difícil (7–9)**

7. Mata el proceso a la mitad (`kill -9`) sin `unlink`. **Criterio:** el bloque sigue en `/dev/shm`, y un *script* que lo limpia.
8. Escribe una extensión de Cython o Rust (`ff03`, `ff05`) que reciba un `memoryview` de un `mmap`. **Criterio:** procesa un archivo de 1 GB sin cargarlo.
9. Pasa el arreglo entre procesos con `multiprocessing.Pool` y con `concurrent.futures.ProcessPoolExecutor`. **Criterio:** los dos tiempos y por qué se parecen al
   serializado.

**🔴 Muy difícil (10)**

10. Diseña cómo se reparten 2 GB de datos entre ocho procesos trabajadores. **Criterio:** una página. *Rúbrica:* (a) serializar, compartir o que cada uno lea lo suyo,
    con números medidos; (b) quién crea y quién borra la memoria; (c) qué pasa si un trabajador muere; (d) qué cambia en un contenedor.

---

## 📚 7. Referencias

**Documentación oficial**

- `memoryview` y el protocolo de *buffers*: https://docs.python.org/3/library/stdtypes.html#memoryview
- `multiprocessing.shared_memory`: https://docs.python.org/3/library/multiprocessing.shared_memory.html
- Arrow, lectura y escritura del formato IPC: https://arrow.apache.org/docs/python/ipc.html

**Orden de lectura sugerido:** la documentación de `memoryview`; después la de `shared_memory`, en especial sus ejemplos con NumPy.

---

## 🚀 8. Cierre

El protocolo de *buffers* es lo que deja que Python, NumPy, Arrow y las extensiones se presten memoria sin copiarla. Usado a propósito, una rebanada no cuesta nada,
200 MB cruzan a otro proceso en 26 ms en vez de 449, y un archivo de Arrow se abre en 14 ms en vez de leerse en 222. El precio es administrar la memoria a mano: quién
la crea, quién la borra y quién escribe.

**La señal de que quedó bien:** *"Los datos grandes no viajan por colas: se comparten o se mapean, y cada bloque compartido tiene quien lo borre."*

> 🏷️ **Cierra la sección con su tag**, cuando los ejercicios que elegiste estén hechos:
>
> ```bash
> git tag -a op-ff-fase-06 -m "op ff06 cerrada: memoryview, memoria compartida y Arrow mapeado, medidos"
> ```
>
> Los commits llevan su prefijo (`op ff06: …`) y los de ejercicio su número
> (`op ff06 ej07: …`).
'''
open('op144-ff06-el-buffer-compartido.md','w').write(doc)
PYEOF
docker run --rm --label curso=python-for-java-devs python:3.14.7 python -c "
b=bytearray(10); v=memoryview(b)
try: b.extend(b'x')
except BufferError as e: print('BufferError:', e)"

# --- 2026-10-05T21:09:52 · Verify small /dev/shm failure mode
cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516/salidas/ff06 && timeout 300 docker run --rm --label curso=python-for-java-devs -v "$PWD:/w" -w /w python:3.14.7 sh -c 'df -h /dev/shm | tail -1; timeout 200 pip install -q --root-user-action=ignore numpy==2.5.3 >/dev/null 2>&1; timeout 60 python -c "
import numpy as np
from multiprocessing import shared_memory
s = shared_memory.SharedMemory(create=True, size=200*2**20)
try:
    np.ndarray((25_000_000,), dtype=np.float64, buffer=s.buf)[:] = 1.0
    print(\"ok\")
finally:
    s.close(); s.unlink()
"; echo "salida: $?"'

# --- 2026-10-05T21:10:05 · Add Bus error detail, mark ff06
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs && python3 - <<'EOF'
p='op144-ff06-el-buffer-compartido.md'; s=open(p).read()
old="**`/dev/shm` chico en contenedores.** Docker da 64 MB por defecto; un bloque de 200 MB falla con `Bus error`. Se sube con `--shm-size`."
new="**`/dev/shm` chico en contenedores.** Docker da 64 MB por defecto. Crear un bloque de 200 MB funciona; escribirlo mata el proceso con `Bus error` (código 135), sin\nexcepción, y el `resource_tracker` avisa al salir de un bloque huérfano. Se sube con `--shm-size`."
assert old in s; s=s.replace(old,new); open(p,'w').write(s)
EOF
cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516 && python3 plan.py 144 144 ✅ ✅ | tail -1; python3 verificar_urls.py ../../cursos-algoritmos-lenguajes/python-for-java-devs/op144-ff06-el-buffer-compartido.md | tail -2

# --- 2026-10-05T21:10:26 · Measure threads/processes/subinterpreters with and without GIL
mkdir -p /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516/salidas/ff07 && cd $_ && cat > paralelo.py <<'EOF'
"""Cuatro tareas de Python puro: secuencial, hilos, procesos y subintérpretes, con y sin GIL."""

import os
import sys
import time
from concurrent.futures import InterpreterPoolExecutor, ProcessPoolExecutor, ThreadPoolExecutor


def work(seed):
    """Suavizado de una serie pseudoaleatoria generada en el momento: CPU pura, sin E/S ni NumPy."""
    s, x = 0.0, seed
    for _ in range(2_000_000):
        x = (x * 1103515245 + 12345) % 2**31
        s = 0.1 * x + 0.9 * s
    return s


def run(label, executor_cls=None):
    seeds = [1, 2, 3, 4]
    start = time.perf_counter()
    if executor_cls is None:
        results = [work(s) for s in seeds]
    else:
        with executor_cls(max_workers=4) as pool:
            results = list(pool.map(work, seeds))
    elapsed = time.perf_counter() - start
    return label, elapsed, results


if __name__ == "__main__":
    build = "sin GIL (3.14t)" if not sys._is_gil_enabled() else "con GIL"
    rows = [run("secuencial"), run("hilos", ThreadPoolExecutor), run("procesos", ProcessPoolExecutor),
            run("subintérpretes", InterpreterPoolExecutor)]
    base = rows[0][1]
    assert all(r[2] == rows[0][2] for r in rows)
    print(f"Python {sys.version.split()[0]} {build}, {os.cpu_count()} núcleos")
    for label, elapsed, _ in rows:
        print(f"  {label:<15} {elapsed:5.2f} s · {base / elapsed:4.2f}×")
EOF
timeout 590 docker run --rm --label curso=python-for-java-devs -v "$PWD:/w" -w /w python:3.14.7 sh -c 'timeout 120 pip install -q --root-user-action=ignore uv==0.12.23 >/dev/null 2>&1; python paralelo.py; timeout 200 uv python install -q 3.14.7t && uv run -q -p 3.14.7t --no-project python paralelo.py'

# --- 2026-10-05T21:10:58 · Test GIL re-enable and numpy in subinterpreter
cp ../ff03/ema_v3.pyx . && cat > rompe.py <<'EOF'
"""Lo que se rompe: una extensión que no declara soporte sin GIL, y NumPy dentro de un subintérprete."""

import subprocess
import sys
from concurrent import interpreters

subprocess.run([sys.executable, "-m", "cython", "-3", "-q", "ema_v3.pyx"], check=True)
subprocess.run([sys.executable, "-c", "from setuptools import setup, Extension; setup(ext_modules=[Extension('ema_v3', ['ema_v3.c'])], script_args=['build_ext', '-i', '-q'])"],
               check=True, capture_output=True)
print("GIL antes de importar la extensión:", sys._is_gil_enabled())
import ema_v3  # noqa: E402,F401
print("GIL después:", sys._is_gil_enabled())

interp = interpreters.create()
try:
    interp.exec("import numpy")
except interpreters.ExecutionFailed as error:
    print("numpy en un subintérprete:", str(error).splitlines()[0][:110])
EOF
timeout 590 docker run --rm --label curso=python-for-java-devs -v "$PWD:/w" -w /w python:3.14.7 sh -c 'timeout 120 pip install -q --root-user-action=ignore uv==0.12.23 >/dev/null 2>&1; timeout 200 uv python install -q 3.14.7t; uv venv -q -p 3.14.7t /tmp/ft && timeout 200 uv pip install -q -p /tmp/ft/bin/python Cython==3.3.0 setuptools==84.0.0 numpy==2.5.3 && /tmp/ft/bin/python rompe.py' 2>&1 | grep -v "^\s*$"

# --- 2026-10-05T21:11:14 · Rerun break demo
python3 - <<'EOF'
p='rompe.py'; s=open(p).read()
i=s.index('subprocess.run([sys.executable, "-m", "cython"'); j=s.index('print("GIL antes')
s=s[:i]+'subprocess.run([sys.executable, "-m", "Cython.Build.Cythonize", "-q", "-i", "-3", "ema_v3.pyx"], check=True, capture_output=True)\n'+s[j:]
open(p,'w').write(s)
EOF
timeout 590 docker run --rm --label curso=python-for-java-devs -v "$PWD:/w" -w /w python:3.14.7 sh -c 'timeout 120 pip install -q --root-user-action=ignore uv==0.12.23 >/dev/null 2>&1; timeout 200 uv python install -q 3.14.7t; uv venv -q -p 3.14.7t /tmp/ft && timeout 200 uv pip install -q -p /tmp/ft/bin/python Cython==3.3.0 setuptools==84.0.0 numpy==2.5.3 && /tmp/ft/bin/python rompe.py' 2>&1 | grep -v "^\s*$"

# --- 2026-10-05T21:12:05 · Rerun with numpy subinterpreter message, both builds
python3 - <<'EOF'
p='rompe.py'; s=open(p).read()
s=s.replace('''    print("numpy en un subintérprete:", str(error).splitlines()[0][:110])
''','''    print("numpy en un subintérprete:", error.excinfo.type.__name__, "·", error.excinfo.msg[:100])
finally:
    interp.close()
''')
open(p,'w').write(s)
EOF
timeout 590 docker run --rm --label curso=python-for-java-devs -v "$PWD:/w" -w /w python:3.14.7 sh -c 'timeout 120 pip install -q --root-user-action=ignore uv==0.12.23 >/dev/null 2>&1; timeout 200 uv python install -q 3.14.7t; uv venv -q -p 3.14.7t /tmp/ft && timeout 200 uv pip install -q -p /tmp/ft/bin/python Cython==3.3.0 setuptools==84.0.0 numpy==2.5.3 && /tmp/ft/bin/python rompe.py; pip install -q --root-user-action=ignore numpy==2.5.3 >/dev/null 2>&1; python -c "
from concurrent import interpreters
i = interpreters.create()
try: i.exec(\"import numpy\")
except interpreters.ExecutionFailed as e: print(\"con GIL:\", e.excinfo.type.__name__, e.excinfo.msg[:100])
else: print(\"con GIL: importó\")
i.close()"' 2>&1 | grep -v "^\s*$"

# --- 2026-10-05T21:12:29 · Show full numpy subinterpreter error
timeout 300 docker run --rm --label curso=python-for-java-devs python:3.14.7 sh -c 'timeout 200 pip install -q --root-user-action=ignore numpy==2.5.3 >/dev/null 2>&1; python -c "
from concurrent import interpreters
i = interpreters.create()
try: i.exec(\"import numpy\")
except interpreters.ExecutionFailed as e: print(e.excinfo.msg)
i.close()"'

# --- 2026-10-05T21:12:41 · Final run of break demo
python3 - <<'EOF'
p='rompe.py'; s=open(p).read()
s=s.replace('''    print("numpy en un subintérprete:", error.excinfo.type.__name__, "·", error.excinfo.msg[:100])''','''    original = error.excinfo.msg.strip().splitlines()[-1]          # el mensaje de NumPy culpa a la instalación; la causa está al final
    print("numpy en un subintérprete:", error.excinfo.type.__name__, "·", original)''')
open(p,'w').write(s)
EOF
cat rompe.py; timeout 590 docker run --rm --label curso=python-for-java-devs -v "$PWD:/w" -w /w python:3.14.7 sh -c 'timeout 120 pip install -q --root-user-action=ignore uv==0.12.23 >/dev/null 2>&1; timeout 200 uv python install -q 3.14.7t; uv venv -q -p 3.14.7t /tmp/ft && timeout 200 uv pip install -q -p /tmp/ft/bin/python Cython==3.3.0 setuptools==84.0.0 numpy==2.5.3 && /tmp/ft/bin/python rompe.py' 2>&1 | grep -v "^\s*$"

# --- 2026-10-05T21:13:41 · Write ff07 doc; prep exercise 3 check
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs && python3 - <<'PYEOF'
z='/Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516/salidas/ff07/'
par=open(z+'paralelo.py').read().rstrip(); rom=open(z+'rompe.py').read().rstrip()
doc = '''# 🧵 ff07 — Paralelismo real: subintérpretes y sin GIL

> Python para desarrolladores Java senior · **Carta** · Track `ff` — La frontera nativa ·
> sección 7 de 8
> Se lee suelta: no hace falta ninguna otra sección de la carta.
> Versiones verificadas contra PyPI el 05/10/2026 · Código probado el 05/10/2026 con Python 3.14.7,
> en contenedor: las salidas son las de esa corrida.

---

## 🎯 1. Qué problema resuelve

Durante treinta años, la respuesta a "quiero usar los ocho núcleos con código de Python" fue `multiprocessing`: procesos aparte, cada uno con su intérprete y su
GIL, y los datos serializados de ida y vuelta. Python 3.14 trae dos respuestas más, las dos oficiales: los **subintérpretes** (PEP 734), varios intérpretes
aislados dentro de un mismo proceso, cada uno con su propio GIL; y la **compilación sin GIL** (PEP 703, soportada desde la PEP 779), un CPython donde los hilos
corren Python en paralelo de verdad, como en la JVM.

El camino base midió la compilación sin GIL contra una carga real (`BENCHMARKS.md` §14: 2,27× con aritmética pura, 1,14× con la conciliación). Esta sección
pone las cuatro formas lado a lado con la misma carga de Python puro, en los dos intérpretes, y mide **qué se rompe**: lo que las promesas no dicen.

---

## 🧠 2. El modelo

| Forma | Paralelismo de Python puro | Comparte objetos | Costo de arrancar | Lo que exige |
|---|---|---|---|---|
| Hilos, con GIL | No | Sí | Mínimo | — |
| **Hilos, sin GIL (`3.14t`)** | **Sí** | Sí | Mínimo | Extensiones que declaren soporte sin GIL |
| Procesos | Sí | No: serializa | Alto (un intérprete por proceso) | `if __name__ == "__main__"` |
| **Subintérpretes** | **Sí**, un GIL por intérprete | No: serializa o comparte *buffers* | Medio | Extensiones que soporten varios intérpretes |

### 🪞 Tu instinto de Java dice… y esta vez se equivoca

El instinto de la JVM es que hilos y paralelismo son lo mismo, y con `3.14t` por fin lo son también en Python. Lo que el instinto no ve es que el ecosistema de
Python se escribió durante treinta años **suponiendo** el GIL: una extensión de C que no declara que funciona sin él vuelve a encender el GIL al importarse, para
todo el proceso, con una advertencia y sin error. El intérprete sin GIL es tan paralelo como su extensión menos preparada.

---

## 💻 3. El ejemplo que corre

`paralelo.py` —la misma carga con las cuatro formas—:

```python
''' + par + '''
```

`rompe.py` —una extensión de Cython sin declarar soporte sin GIL (el `ema_v3.pyx` de `ff03`), y NumPy dentro de un subintérprete—:

```python
''' + rom + '''
```

```bash
pip install uv
python3 paralelo.py                                            # el CPython de siempre, con GIL
uv python install 3.14.7t
uv run -p 3.14.7t --no-project python paralelo.py              # la compilación sin GIL
uv venv -p 3.14.7t /tmp/ft && uv pip install -p /tmp/ft/bin/python cython setuptools numpy
/tmp/ft/bin/python rompe.py                                    # con ema_v3.pyx en la carpeta
```

Salida (Python 3.14.7, 05/10/2026) (8 núcleos; los segundos son de la máquina que corre):

```text
Python 3.14.7 con GIL, 8 núcleos
  secuencial       1.25 s · 1.00×
  hilos            1.28 s · 0.98×
  procesos         0.39 s · 3.19×
  subintérpretes   0.37 s · 3.43×
Python 3.14.7 sin GIL (3.14t), 8 núcleos
  secuencial       1.26 s · 1.00×
  hilos            0.43 s · 2.93×
  procesos         0.42 s · 3.02×
  subintérpretes   0.39 s · 3.21×
<frozen importlib._bootstrap>:491: RuntimeWarning: The global interpreter lock (GIL) has been enabled to load module 'ema_v3', which has not declared that it can run safely without the GIL. To override this behavior and keep the GIL disabled (at your own risk), run with PYTHON_GIL=0 or -Xgil=0.
GIL antes de importar la extensión: False
GIL después: True
numpy en un subintérprete: ImportError · Original error was: module numpy._core._multiarray_umath does not support loading in subinterpreters
```

Con GIL, los hilos no ganan nada (0,98×), y procesos y subintérpretes dan algo más de 3× con cuatro tareas. Los **subintérpretes ganan a los procesos** (3,43 contra
3,19), porque arrancan más rápido. Sin GIL, los hilos pasan de 0,98× a **2,93×** sin cambiar una línea; y el intérprete sin GIL no cobra nada en secuencial
(1,26 contra 1,25 s), lo mismo que midió el camino base. Las tres últimas líneas son la letra chica: importar **una** extensión que no declaró soporte sin GIL
enciende el GIL para todo el proceso, con una advertencia; y NumPy, la biblioteca más usada del ecosistema, **no carga en un subintérprete**, con un mensaje que
empieza culpando a la instalación y dice la causa real en la última línea.

**Detalles con intención**

- **`InterpreterPoolExecutor`** (nuevo en 3.14, en `concurrent.futures`) tiene la misma interfaz que los otros dos ejecutores: cambiar de procesos a subintérpretes es
  cambiar una clase. Los argumentos y resultados viajan serializados, como entre procesos.
- **`work` no usa NumPy ni E/S**: es la carga donde el GIL más pesa. Con NumPy, el trabajo ya corre en C y suelta el GIL (`ff01`), y la comparación sería otra.
- **El `assert`** comprueba que las cuatro formas devuelven lo mismo: el paralelismo no cambió el resultado.
- **Cuatro tareas, 8 núcleos, ~3×** y no 4×: arrancar trabajadores y repartir cuesta, y con tareas de un tercio de segundo ese costo pesa.
- **`PYTHON_GIL=0`** fuerza el GIL apagado aunque la extensión no lo declare. Es "bajo tu riesgo" en serio: si la extensión tiene estado global sin proteger, se
  corrompe.

---

## ⚠️ 4. Lo que se rompe

**La extensión que enciende el GIL.** En `3.14t`, cualquier módulo de C sin la declaración (`Py_mod_gil`) lo vuelve a encender. Se revisa con
`sys._is_gil_enabled()` **después** de importar todo, en una prueba del CI, y se tratan las advertencias `RuntimeWarning` como errores.

**NumPy (y casi todo) en subintérpretes.** Una extensión tiene que soportar varios intérpretes de forma explícita, y la mayoría todavía no lo hace. Hoy los
subintérpretes sirven para Python puro y la biblioteca estándar.

**Las ruedas de `3.14t`.** La compilación sin GIL tiene su propia ABI (`cp314t`): cada paquete con código nativo necesita ruedas aparte. Las que no las publican se
compilan al instalar, o no se instalan.

**Las carreras que el GIL escondía.** Código de Python puro que "funcionaba" con hilos porque el GIL serializaba operaciones puede tener carreras de datos sin él. Los
contadores compartidos se protegen con `threading.Lock` aunque antes no hiciera falta.

---

## ⚖️ 5. Cuándo NO usarlos

**`3.14t` si dependes de extensiones sin soporte.** El GIL vuelve con la primera, y se paga la complejidad sin la ganancia.

**Subintérpretes con NumPy, pandas o casi cualquier extensión científica.** No cargan. Procesos.

**Para E/S.** Hilos o `asyncio` ya la paralelizan con el GIL (`BENCHMARKS.md` §14: 3,95×).

**Si el trabajo ya está en C.** NumPy, `hashlib` o tu extensión que suelta el GIL ya corren en paralelo con hilos normales.

---

## 🧪 6. Ejercicios (10)

**🟢 Fácil (1–3)**

1. Corre `paralelo.py` en los dos intérpretes. **Criterio:** las dos tablas, y por qué los hilos cambian y los procesos no.
2. Corre `rompe.py` con `PYTHON_GIL=0`. **Criterio:** el GIL queda apagado, y explicas el riesgo.
3. Agrega `# cython: freethreading_compatible=True` a `ema_v3.pyx`. **Criterio:** la advertencia desaparece y el GIL sigue apagado.

**🟡 Intermedio (4–6)**

4. Repite la medición con 8 tareas y con 16. **Criterio:** cómo cambia la ganancia de cada forma.
5. Escribe un contador compartido incrementado por 4 hilos un millón de veces cada uno, en los dos intérpretes. **Criterio:** si pierde incrementos en alguno, y la
   corrección.
6. Lista qué paquetes de tu proyecto tienen ruedas `cp314t` en PyPI. **Criterio:** la lista, y los que no.

**🟠 Difícil (7–9)**

7. Pasa datos a un subintérprete con un `memoryview` compartido en vez de serializar. **Criterio:** el tiempo contra serializar un arreglo grande.
8. Mide un servicio FastAPI con `uvicorn` en `3.14t` con hilos de trabajo. **Criterio:** peticiones por segundo contra 3.14 con GIL, con una ruta de CPU pura.
9. Escribe una prueba de CI que importe todo el proyecto en `3.14t` y falle si el GIL se encendió. **Criterio:** la prueba, fallando con una extensión sin soporte.

**🔴 Muy difícil (10)**

10. Decide si un servicio con carga de CPU en Python pasa a `3.14t`, a subintérpretes o se queda en procesos. **Criterio:** una página. *Rúbrica:* (a) las mediciones
    con tu carga; (b) las extensiones del proyecto y su soporte; (c) las carreras que habría que revisar; (d) el plan si una dependencia enciende el GIL.

---

## 📚 7. Referencias

**Documentación oficial**

- PEP 734, subintérpretes en la biblioteca estándar: https://peps.python.org/pep-0734/
- PEP 779, criterios para el soporte de la compilación sin GIL: https://peps.python.org/pep-0779/
- Guía de Python sin GIL para mantenedores de extensiones: https://py-free-threading.github.io/

**Orden de lectura sugerido:** la guía de py-free-threading (el estado real del ecosistema); después la PEP 734, sobre qué se comparte entre subintérpretes.

---

## 🚀 8. Cierre

Python 3.14 tiene tres formas de usar varios núcleos con código de Python: procesos (3,19×), subintérpretes (3,43×) y, en `3.14t`, hilos (2,93×), sin costo en
secuencial. Las tres funcionan con Python puro. El límite es el ecosistema: una extensión sin soporte enciende el GIL para todo el proceso, y NumPy no carga en un
subintérprete. Se mide con la carga propia y se revisa cada dependencia antes de elegir.

**La señal de que quedó bien:** *"El CI importa todo en `3.14t` y verifica que el GIL siga apagado, y la decisión de paralelismo tiene sus números al lado."*

> 🏷️ **Cierra la sección con su tag**, cuando los ejercicios que elegiste estén hechos:
>
> ```bash
> git tag -a op-ff-fase-07 -m "op ff07 cerrada: procesos, subintérpretes y 3.14t medidos, y lo que se rompe"
> ```
>
> Los commits llevan su prefijo (`op ff07: …`) y los de ejercicio su número
> (`op ff07 ej07: …`).
'''
open('op145-ff07-paralelismo-real.md','w').write(doc)
PYEOF
cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516/salidas/ff07 && sed '1i\
# cython: freethreading_compatible=True
' ema_v3.pyx > ema_v3b.pyx 2>/dev/null; head -2 ema_v3b.pyx

# --- 2026-10-05T21:13:47 · Verify freethreading_compatible directive
mkdir -p ej3 && mv ema_v3b.pyx ej3/ema_v3.pyx && cp rompe.py ej3/ && timeout 590 docker run --rm --label curso=python-for-java-devs -v "$PWD/ej3:/w" -w /w python:3.14.7 sh -c 'timeout 120 pip install -q --root-user-action=ignore uv==0.12.23 >/dev/null 2>&1; timeout 200 uv python install -q 3.14.7t; uv venv -q -p 3.14.7t /tmp/ft && timeout 200 uv pip install -q -p /tmp/ft/bin/python Cython==3.3.0 setuptools==84.0.0 numpy==2.5.3 && /tmp/ft/bin/python rompe.py' 2>&1 | head -3

# --- 2026-10-05T21:14:07 · Mark ff07, URLs, verifier
cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516 && python3 plan.py 145 145 ✅ ✅ | tail -1; python3 verificar_urls.py ../../cursos-algoritmos-lenguajes/python-for-java-devs/op145-ff07-paralelismo-real.md | tail -2; cd ../../cursos-algoritmos-lenguajes/python-for-java-devs && python3 prompts/verificar-corpus.py 2>&1 | grep -E "op14[4-5]|errores"

# --- 2026-10-05T21:14:18 · Count wheels per package on PyPI
mkdir -p /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516/salidas/ff08 && cd $_ && cat > ruedas.py <<'EOF'
"""El costo de distribución que nadie mide: cuántas ruedas publica cada paquete en su última versión."""

import json
import urllib.request

PACKAGES = {
    "httpx": "Python puro",
    "numba": "LLVM (C++)",
    "scikit-learn": "Cython",
    "orjson": "Rust (PyO3)",
    "pydantic-core": "Rust (PyO3)",
    "cffi": "C",
}
for package, kind in PACKAGES.items():
    data = json.load(urllib.request.urlopen(f"https://pypi.org/pypi/{package}/json", timeout=20))
    wheels = [f["filename"] for f in data["urls"] if f["filename"].endswith(".whl")]
    free_threaded = sum("cp314t" in w for w in wheels)
    print(f"{package:<14} {kind:<12} {data['info']['version']:<9} {len(wheels):>3} ruedas · {free_threaded:>2} para 3.14t")
EOF
docker run --rm --label curso=python-for-java-devs -v "$PWD:/w" -w /w python:3.14.7 python ruedas.py

# --- 2026-10-05T21:14:38 · Run ff08 decision function
cat > frontera.py <<'EOF'
"""¿Dónde mover la frontera? El veredicto del track como función, aplicada a cinco funciones calientes."""

from dataclasses import dataclass


@dataclass
class HotFunction:
    name: str
    share_of_time: float               # fracción del tiempo total del programa que se va en ella
    vectorizable: bool = False         # ¿NumPy la expresa como operación de arreglo completo?
    numeric_loop: bool = True          # ¿números y arreglos, sin objetos de Python?
    long_running: bool = True          # ¿el proceso vive lo suficiente para pagar 340 ms de arranque?
    wraps_existing_c: bool = False
    team_writes: str = "Python"        # "Python", "Rust", "C++"


def decide(f: HotFunction) -> str:
    if f.share_of_time < 0.2:
        return "nada: no es el cuello de botella"
    if f.wraps_existing_c:
        return "cffi (ff02)"
    if f.vectorizable:
        return "NumPy, sin compilar nada (ds01)"
    if f.numeric_loop and f.long_running:
        return "numba (ff04)"
    if f.team_writes == "Rust":
        return "PyO3 + maturin (ff05), con cibuildwheel"
    if f.team_writes == "C++":
        return "nanobind (ff05), con cibuildwheel"
    return "Cython (ff03), con cibuildwheel"


FUNCTIONS = [
    HotFunction("Suavizado de la serie de recaudo", 0.7),
    HotFunction("Mora diaria de todos los saldos", 0.5, vectorizable=True),
    HotFunction("Validación de formularios", 0.05, numeric_loop=False),
    HotFunction("Lector de huellas del fabricante", 0.4, wraps_existing_c=True),
    HotFunction("Suavizado en un CLI de 0,3 s", 0.8, long_running=False),
    HotFunction("Normalizar nombres en lotes de texto", 0.6, numeric_loop=False, team_writes="Rust"),
]
for f in FUNCTIONS:
    print(f"{f.name:<38} → {decide(f)}")
EOF
docker run --rm --label curso=python-for-java-devs -v "$PWD:/w" -w /w python:3.14.7 python frontera.py

# --- 2026-10-05T21:15:18 · Write ff08, mark, verify, check ff inventory
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs && python3 - <<'PYEOF'
z='/Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516/salidas/ff08/'
fr=open(z+'frontera.py').read().rstrip(); ru=open(z+'ruedas.py').read().rstrip()
doc = '''# ⚖️ ff08 — Veredicto: la misma función en cuatro fronteras

> Python para desarrolladores Java senior · **Carta** · Track `ff` — La frontera nativa ·
> sección 8 de 8
> Se lee suelta: no hace falta ninguna otra sección de la carta, aunque esta cierra el track y
> enlaza a las siete anteriores.
> Versiones verificadas contra PyPI el 05/10/2026 · Código probado el 05/10/2026 con Python 3.14.7,
> en contenedor: las salidas son las de esa corrida.

---

## 🎯 1. Qué problema resuelve

El track escribió la misma función —un suavizado exponencial de dos millones de valores, donde cada resultado depende del anterior— en Python, en C llamado con
`ctypes` y `cffi` ([`ff02`](op140-ff02-ctypes-y-cffi.md)), en Cython ([`ff03`](op141-ff03-cython.md)), con numba ([`ff04`](op142-ff04-numba.md)) y en Rust y C++
([`ff05`](op143-ff05-rust-y-cpp.md)), sobre el modelo de [`ff01`](op139-ff01-el-modelo.md) y con los *buffers* de [`ff06`](op144-ff06-el-buffer-compartido.md) y
el paralelismo de [`ff07`](op145-ff07-paralelismo-real.md).

El veredicto es que **en velocidad empatan**: todas las fronteras bien hechas dejan el cálculo entre 4,5 y 8,7 ms, de 19 a 36 veces menos que Python. Lo que las
separa no está en el bucle. Está en lo que las comparaciones de internet no miden: el arranque, la cadena de herramientas, la exactitud y, sobre todo, **el costo
de distribuir**: un paquete de Python puro es una rueda; uno con código nativo, decenas.

---

## 🧠 2. El modelo

Las cifras del track, todas de este mismo contenedor:

| Frontera | Tiempo | Contra Python (163 ms) | Lo que cuesta fuera del bucle | Igual a Python |
|---|---|---|---|---|
| C con `ctypes` / `cffi` (`ff02`) | 5,1 ms | 32× | Firmas a mano; 0,5 µs por llamada con `ctypes` | No: FMA (5,7e-13) |
| Cython, *memoryviews* (`ff03`) | 8,7 ms | 19× | `setuptools`, compilar por plataforma; reservar el resultado | No: FMA |
| numba (`ff04`) | 4,5 ms | 36× | 151 ms de `import`, 186 ms la primera llamada | — |
| PyO3 (`ff05`) | 5,3 ms | 31× | 18 s de construcción, rueda de 292 KB | **Sí, bit a bit** |
| pybind11 (`ff05`) | 5,1 ms | 32× | 8 s, 65 KB | No: FMA |
| nanobind (`ff05`) | 5,1 ms | 32× | 6 s, 51 KB | No: FMA |

La memoria no entra en la tabla porque no separa a nadie: todas reciben el arreglo sin copiarlo (`ff06`) y crean uno del mismo tamaño para el resultado.

---

## 💻 3. El ejemplo que corre

Dos programas. `ruedas.py` mide en PyPI el costo de distribución: cuántas ruedas tiene que construir y publicar cada paquete en su última versión.

```python
''' + ru + '''
```

`frontera.py` es el veredicto como función, aplicado a seis funciones calientes:

```python
''' + fr + '''
```

```bash
python3 ruedas.py
python3 frontera.py
```

Salida (Python 3.14.7, 05/10/2026):

```text
httpx          Python puro  0.28.1      1 ruedas ·  0 para 3.14t
numba          LLVM (C++)   0.68.0     31 ruedas ·  4 para 3.14t
scikit-learn   Cython       1.9.1      42 ruedas ·  6 para 3.14t
orjson         Rust (PyO3)  3.12.0     64 ruedas ·  0 para 3.14t
pydantic-core  Rust (PyO3)  2.49.0    136 ruedas · 15 para 3.14t
cffi           C            2.1.1      99 ruedas · 11 para 3.14t
Suavizado de la serie de recaudo       → numba (ff04)
Mora diaria de todos los saldos        → NumPy, sin compilar nada (ds01)
Validación de formularios              → nada: no es el cuello de botella
Lector de huellas del fabricante       → cffi (ff02)
Suavizado en un CLI de 0,3 s           → Cython (ff03), con cibuildwheel
Normalizar nombres en lotes de texto   → PyO3 + maturin (ff05), con cibuildwheel
```

`httpx` publica **una** rueda, que sirve en todas partes. `pydantic-core` publica **136**: cada versión de Python, cada sistema operativo, cada arquitectura, y ahora
también cada variante sin GIL. Esa es la cifra que la tabla de §2 no tiene: mover la frontera convierte un `pip install` universal en una matriz de construcción. Y
`orjson`, con 64 ruedas, todavía no tiene ninguna para `3.14t`: quien usa el intérprete sin GIL lo compila al instalar, con Rust, o no lo usa.

**Detalles con intención**

- **La fracción del tiempo se evalúa primero**: una función que es el 5% del programa no justifica ninguna frontera, aunque se acelere 36 veces.
- **numba gana en procesos largos** porque no agrega ruedas propias (las de numba ya existen) ni cadena de herramientas; pierde en un CLI corto por sus 340 ms de
  arranque (151 de `import` más 186 de compilación).
- **"con cibuildwheel"** al lado de Cython, PyO3 y nanobind: es la herramienta que construye la matriz de ruedas en el CI. Elegir una de esas fronteras es elegir
  mantener esa matriz.
- **El umbral de 0,2** es una suposición a la vista: por debajo de un quinto del tiempo, la ganancia total del programa no alcanza a notarse.

---

## ⚠️ 4. Lo que se rompe

**Elegir por el *benchmark* del bucle.** Todas empatan en el bucle. La decisión real es de arranque, mantenimiento y distribución.

**Olvidar la exactitud.** Cuatro de las seis fronteras no dan el mismo resultado que Python, por la FMA. En un cálculo de dinero o en una prueba que compara con
`==`, importa.

**La matriz de ruedas que nadie mantiene.** La extensión que se construyó a mano para Linux x86 un día, y que nadie sabe reconstruir cuando llega Python 3.15 o un
portátil ARM.

---

## ⚖️ 5. Cuándo NO usar este veredicto

**Si la función es de cadenas, objetos o E/S.** Ninguna frontera del track fue medida con eso; con cadenas, convertir puede costar más que el cálculo.

**Si el código ya vive en un ecosistema nativo.** Si el equipo mantiene una biblioteca de C++ grande, nanobind no es "una opción más": es el puente natural.

---

## 🧪 6. Ejercicios (8)

**🟢 Fácil (1–2)**

1. Agrega a `ruedas.py` tres paquetes que uses. **Criterio:** cuántos son Python puro y cuántas ruedas publica el que más.
2. Cambia el umbral de 0,2 a 0,1. **Criterio:** qué función cambia de decisión y si estás de acuerdo.

**🟡 Intermedio (3–4)**

3. Agrega la dimensión "necesita resultado exacto a Python" y úsala. **Criterio:** una función que pase de numba o C++ a PyO3 o a quedarse en Python.
4. Escribe las pruebas de `decide` con un caso por regla. **Criterio:** siete casos, todos pasan.

**🟠 Difícil (5–6)**

5. Configura `cibuildwheel` para la extensión de nanobind de `ff05` con Python 3.13, 3.14 y 3.14t en Linux x86 y ARM. **Criterio:** cuántas ruedas y cuánto tarda el CI.
6. Mide el suavizado con las seis fronteras en tu máquina. **Criterio:** la tabla de §2 con tus números, y si cambia algún orden.

**🔴 Muy difícil (7–8)**

7. Escribe la política de código nativo de tu equipo. **Criterio:** una página. *Rúbrica:* (a) cuándo se permite mover la frontera; (b) qué herramienta por defecto y por
   qué; (c) quién mantiene la matriz de ruedas; (d) cómo se prueba la exactitud contra Python.
8. Audita las dependencias nativas de un proyecto real. **Criterio:** una tabla. *Rúbrica:* (a) cada paquete con su lenguaje nativo; (b) si tiene ruedas para tus
   plataformas y para `3.14t`; (c) cuáles se compilan al instalar; (d) cuáles reemplazarías.

---

## 📚 7. Referencias

- `cibuildwheel`: https://cibuildwheel.pypa.io/en/stable/
- Ralf Gommers y otros, *pypackaging-native*, el problema de empaquetar código nativo contado por quienes lo mantienen: https://pypackaging-native.github.io/

**Orden de lectura sugerido:** *pypackaging-native*, para ver el problema completo; después la documentación de `cibuildwheel`. El resto del track tiene sus
referencias en cada sección.

---

## 🚀 8. Cierre

Bien hechas, todas las fronteras dejan el bucle entre 19 y 36 veces más rápido, y en eso empatan. Se elige por lo demás: numba si el proceso vive lo suficiente,
`cffi` para envolver C que ya existe, PyO3 o nanobind si el equipo los mantiene, y en todos los casos con la matriz de ruedas a la vista: 1 contra 136.

**La señal de que quedó bien:** *"Cada función nativa del proyecto tiene al lado su fracción del tiempo, su herramienta elegida y quién construye sus ruedas."*

> 🏷️ **Cierra la sección con su tag**, cuando los ejercicios que elegiste estén hechos:
>
> ```bash
> git tag -a op-ff-fase-08 -m "op ff08 cerrada: empatan en el bucle; se elige por arranque, exactitud y ruedas"
> ```
>
> Los commits llevan su prefijo (`op ff08: …`) y los de ejercicio su número
> (`op ff08 ej07: …`).
'''
open('op146-ff08-veredicto.md','w').write(doc)
PYEOF
cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516 && python3 plan.py 146 146 ✅ ✅ | tail -1; python3 verificar_urls.py ../../cursos-algoritmos-lenguajes/python-for-java-devs/op146-ff08-veredicto.md | tail -2; cd ../../cursos-algoritmos-lenguajes/python-for-java-devs && python3 prompts/verificar-corpus.py 2>&1 | grep -E "op146|errores"; python3 prompts/check-inventario.py ff 2>&1 | tail -1; sed -n '/^## `ff`/,/^## `ar`/p' prompts/inventario-verificado.md | grep -E "cffi|Cython|numba|maturin|pybind11|nanobind|pyarrow|numpy|setuptools|scikit-build"

# --- 2026-10-05T21:16:32 · Check numba exactness vs Python
cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516/salidas/ff04 && timeout 400 docker run --rm --label curso=python-for-java-devs -v "$PWD:/w" -w /w python:3.14.7 sh -c 'timeout 200 pip install -q --root-user-action=ignore numba==0.68.0 >/dev/null 2>&1; python -c "
import numpy as np
from numba import njit
@njit
def ema(x, alpha):
    out = np.empty_like(x); s = x[0]
    for i in range(x.shape[0]):
        s = alpha * x[i] + (1 - alpha) * s; out[i] = s
    return out
x = np.sin(np.arange(2_000_000) / 1000) * 100 + 500
ref = []; s = x[0]
for v in x.tolist():
    s = 0.1 * v + 0.9 * s; ref.append(s)
print(np.abs(ema(x, 0.1) - np.array(ref)).max())"'

# --- 2026-10-05T21:17:04 · Update ff08/ff04 exactness, close T18, update memory
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs && python3 - <<'EOF'
p='op146-ff08-veredicto.md'; s=open(p).read()
a="| numba (`ff04`) | 4,5 ms | 36× | 151 ms de `import`, 186 ms la primera llamada | — |"
b="| numba (`ff04`) | 4,5 ms | 36× | 151 ms de `import`, 186 ms la primera llamada | **Sí, bit a bit** (sin `fastmath`) |"
assert a in s; s=s.replace(a,b); open(p,'w').write(s)
p='op142-ff04-numba.md'; s=open(p).read()
a="- **El 5,7× en 8 núcleos**"
b="- **El resultado es idéntico al de Python**, bit a bit: numba no fusiona multiplicación y suma (FMA) salvo que se le pida con `fastmath=True`, a diferencia del C de\n  `ff02` y `ff03` (comprobado aparte, con la misma serie).\n- **El 5,7× en 8 núcleos**"
assert a in s; s=s.replace(a,b,1); open(p,'w').write(s)
EOF
cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516 && python3 plan.py tanda T18 ✅ && python3 plan.py dondeesta "T1–T18 cerradas (146 de 176). Sigue T19 ar (op147)." && python3 plan.py bitacora '**2026-10-05 · T18 (`ff`) cerrada.** Escritas op139–op146 (8 secciones, 78 ejercicios), **las ocho probadas en contenedor**, con un ejemplo propio (el suavizado exponencial de dos millones de valores) en lugar de Áurea, como permite la propuesta. **Hallazgos y defectos propios:** con el GIL activo, cuatro hilos ganan 1,09× en Python puro y 3,76× con `sha256` en C (ff01); `ctypes` cuesta 0,5 µs por llamada, nueve veces más que Python (ff02); **gcc fusiona multiplicación y suma (FMA) en ARM** y el C difiere de Python en 5,7e-13, con `-ffp-contract=off` es exacto pero un 35% más lento; Rust y numba dan el mismo resultado que Python bit a bit (ff02–ff05); `cythonize -i` necesita `setuptools` desde que no hay `distutils`, y los decoradores `boundscheck`/`wraparound` no dieron nada medible (ff03); numba: 151 ms de `import`, 186 ms la primera llamada, 88 con caché; no compila generadores ni `Decimal` (ff04); `maturin` falla si el nombre del proyecto tiene guion y no se declara `module-name`; un directorio con el nombre del módulo lo tapa (ff05); `shared_memory` de 200 MB en un `/dev/shm` de 64 MB muere con `Bus error` (ff06); en `3.14t` una extensión sin declarar soporte **reactiva el GIL para todo el proceso** y **NumPy no carga en subintérpretes**, con un mensaje que culpa a la instalación (ff07); `pydantic-core` publica 136 ruedas y `orjson` ninguna para `3.14t` (ff08). **Defecto propio corregido:** la versión con una sola cola de `ff06` se colgaba (el proceso principal leía su propio envío). **URL:** `verificar_urls.py` da 200 a videos de YouTube inexistentes; desde ff04 los videos se comprueban con oEmbed (uno corregido en ff04); queda revisar así los de T1–T17 en T24.' && grep -c "op1[34][0-9].*✅ | ✅" ../../cursos-algoritmos-lenguajes/python-for-java-devs/prompts/plan-de-produccion-carta.md; sed -i '' 's/T1–T17 cerradas el 05\/10\/2026: 138 de 176; sigue T18 ff\./T1–T18 cerradas el 05\/10\/2026: 146 de 176; sigue T19 ar; revisar videos de YouTube con oEmbed en T24./' /Users/oskar/.claude/projects/-Users-oskar-Developer-Learning-courses-ia-generated/memory/MEMORY.md; grep -c "T1–T18" /Users/oskar/.claude/projects/-Users-oskar-Developer-Learning-courses-ia-generated/memory/MEMORY.md

# --- 2026-10-05T21:17:11 · Check all YouTube links in carta via oEmbed
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs && grep -oE "https://(www\.)?(youtube\.com/watch\?v=|youtu\.be/)[A-Za-z0-9_-]+" op*.md | sort -u | while IFS=: read -r f u1 u2; do u="$u1:$u2"; code=$(curl -s -o /dev/null -w '%{http_code}' "https://www.youtube.com/oembed?url=$u&format=json"); [ "$code" != 200 ] && echo "$code $f $u"; done; echo fin; grep -oE "https://(www\.)?youtube\.com/watch\?v=[A-Za-z0-9_-]+" op*.md | wc -l

# --- 2026-10-05T21:17:17 · Fix bitácora note; read ar track spec
sed -i '' 's/desde ff04 los videos se comprueban con oEmbed (uno corregido en ff04); queda revisar así los de T1–T17 en T24\./desde ff04 los videos se comprueban con oEmbed: uno corregido en ff04, y los tres videos de toda la carta responden./' prompts/plan-de-produccion-carta.md && grep -c "tres videos de toda la carta" prompts/plan-de-produccion-carta.md; sed -i '' 's/; revisar videos de YouTube con oEmbed en T24\././' /Users/oskar/.claude/projects/-Users-oskar-Developer-Learning-courses-ia-generated/memory/MEMORY.md; grep -n "ar —\|\`ar\`" prompts/propuestas-temas-opcionales.md | head -5; sed -n '/^## `ar`/,/^## `gi`/p' prompts/inventario-verificado.md

# --- 2026-10-05T21:17:20 · Read ar track proposal and plan rows
sed -n 295,370p prompts/propuestas-temas-opcionales.md; grep -n "op14[7-9]\|op15[0-6]" prompts/plan-de-produccion-carta.md

# --- 2026-10-05T21:17:42 · Run ar01 binary demo
mkdir -p /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516/salidas/ar01 && cd $_ && cat > binario.py <<'EOF'
"""Binario de verdad: registros con struct, acceso con mmap, mojibake, zip con zstd y el filtro de tar."""

import io
import mmap
import os
import struct
import tarfile
import time
import zipfile

RECORD = struct.Struct("<i d 8s")             # id (int32), monto (float64), sede (8 bytes); little endian, sin relleno
N = 1_000_000
BRANCHES = [b"CENTRO", b"CHAPIN", b"SUBA", b"KENNEDY", b"USAQUEN", b"ENGATIVA", b"FONTIBON", b"RESTREPO"]

with open("pagos.bin", "wb") as f:
    for i in range(N):
        f.write(RECORD.pack(i, 1000.0 + i % 997, BRANCHES[i % 8]))
print(f"registro de {RECORD.size} bytes · archivo de {os.path.getsize('pagos.bin') / 2**20:.1f} MB")

# 1) Leer todo: un unpack por registro contra iter_unpack
data = open("pagos.bin", "rb").read()
start = time.perf_counter()
total = 0.0
for offset in range(0, len(data), RECORD.size):
    total += RECORD.unpack_from(data, offset)[1]
loop = time.perf_counter() - start
start = time.perf_counter()
total_iter = sum(amount for _, amount, _ in RECORD.iter_unpack(data))
print(f"unpack_from en bucle {loop * 1000:5.0f} ms · iter_unpack {(time.perf_counter() - start) * 1000:5.0f} ms · iguales: {total == total_iter}")

# 2) Un registro del medio, sin leer el archivo
with open("pagos.bin", "rb") as f, mmap.mmap(f.fileno(), 0, access=mmap.ACCESS_READ) as m:
    rid, amount, branch = RECORD.unpack_from(m, 700_000 * RECORD.size)
    print(f"registro 700000 por mmap: id={rid} monto={amount} sede={branch.rstrip(b'\0').decode()}")

# 3) Mojibake: UTF-8 leído como Latin-1, y de vuelta
broken = "Engativá · Usaquén".encode("utf-8").decode("latin-1")
print(f"mojibake: {broken!r} · reparado: {broken.encode('latin-1').decode('utf-8')!r}")

# 4) zip: el mismo archivo con cada compresión (ZIP_ZSTANDARD es nuevo en 3.14)
for name, method in (("stored", zipfile.ZIP_STORED), ("deflate", zipfile.ZIP_DEFLATED), ("bzip2", zipfile.ZIP_BZIP2),
                     ("lzma", zipfile.ZIP_LZMA), ("zstd", zipfile.ZIP_ZSTANDARD)):
    buffer = io.BytesIO()
    start = time.perf_counter()
    with zipfile.ZipFile(buffer, "w", compression=method) as z:
        z.write("pagos.bin")
    packed = time.perf_counter() - start
    start = time.perf_counter()
    with zipfile.ZipFile(buffer) as z:
        z.read("pagos.bin")
    print(f"zip {name:<8} {buffer.tell() / 2**20:5.2f} MB · comprimir {packed * 1000:5.0f} ms · leer {(time.perf_counter() - start) * 1000:4.0f} ms")

# 5) tar: un miembro que intenta salir de la carpeta de destino
evil = io.BytesIO()
with tarfile.open(fileobj=evil, mode="w") as t:
    info = tarfile.TarInfo("../fuera.txt"); payload = b"no deberia estar aqui"; info.size = len(payload)
    t.addfile(info, io.BytesIO(payload))
evil.seek(0)
try:
    with tarfile.open(fileobj=evil) as t:
        t.extractall("destino")
    print("tar: extrajo ../fuera.txt")
except tarfile.FilterError as error:
    print(f"tar: {type(error).__name__}: {error}")
os.remove("pagos.bin")
EOF
timeout 300 docker run --rm --label curso=python-for-java-devs -v "$PWD:/w" -w /w python:3.14.7 python binario.py

# --- 2026-10-05T21:18:03 · Rerun ar01 with truncation demo
python3 - <<'EOF'
p='binario.py'; s=open(p).read()
s=s.replace('''print(f"registro de {RECORD.size} bytes · archivo de {os.path.getsize('pagos.bin') / 2**20:.1f} MB")
''','''print(f"registro de {RECORD.size} bytes · archivo de {os.path.getsize('pagos.bin') / 2**20:.1f} MB")
print("CHAPINERO en 8s:", RECORD.unpack(RECORD.pack(0, 0.0, b"CHAPINERO"))[2])   # struct corta sin avisar
''')
open(p,'w').write(s)
EOF
rm -rf destino; timeout 300 docker run --rm --label curso=python-for-java-devs -v "$PWD:/w" -w /w python:3.14.7 python binario.py; ls

# --- 2026-10-05T21:18:21 · Test unzip on a zstd zip
timeout 300 docker run --rm --label curso=python-for-java-devs -v "$PWD:/w" -w /tmp python:3.14.7 sh -c 'apt-get -qq update >/dev/null 2>&1; apt-get -qq install -y unzip >/dev/null 2>&1; python -c "
import zipfile
with zipfile.ZipFile(\"z.zip\",\"w\",compression=zipfile.ZIP_ZSTANDARD) as z: z.writestr(\"a.txt\",\"hola \"*1000)"; unzip -o z.zip 2>&1 | tail -2; echo "salida: $?"'

# --- 2026-10-05T21:19:07 · Write ar01 doc; verify alignment and default filter claims
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs && python3 - <<'PYEOF'
code=open('/Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516/salidas/ar01/binario.py').read().rstrip()
doc='''# 🧮 ar01 — Binario de verdad

> Python para desarrolladores Java senior · **Carta** · Track `ar` — Archivos y multimedia ·
> sección 1 de 10
> Se lee suelta: no hace falta ninguna otra sección de la carta.
> Versiones verificadas contra PyPI el 05/10/2026 · Código probado el 05/10/2026 con Python 3.14.7,
> en contenedor: las salidas son las de esa corrida.

---

## 🎯 1. Qué problema resuelve

Antes de Pillow, de los PDF y del vídeo, hay bytes. Un archivo de registros de ancho fijo que exporta el datáfono, un `.zip` con los reportes del mes, un `.tar`
que llega del proveedor, un CSV que alguien guardó en Latin-1. Este track trata de transformar archivos, y empieza por lo que la biblioteca estándar ya resuelve
sin instalar nada: **`struct`** para leer y escribir registros binarios, **`mmap`** para tratar un archivo como memoria, las **codificaciones** de texto, y
**`zipfile`** y **`tarfile`**.

Dos novedades de Python 3.14 cambian la respuesta habitual: `zipfile` ahora comprime con **Zstandard**, y `tarfile` **filtra por defecto** los miembros que intentan
escribir fuera de la carpeta de destino. Esta sección mide la primera y prueba la segunda.

---

## 🧠 2. El modelo

| Pieza | Para qué | El equivalente en Java |
|---|---|---|
| `struct.Struct("<i d 8s")` | Empaquetar y desempaquetar registros de ancho fijo | `ByteBuffer` con `order(LITTLE_ENDIAN)` y `getInt`, `getDouble` |
| `struct.iter_unpack` | Recorrer un *buffer* de registros sin bucle de Python por campo | — |
| `mmap` | El archivo como memoria: leer un registro sin leer el archivo | `FileChannel.map` |
| `bytes.decode("utf-8")` | Bytes a texto, con la codificación dicha en voz alta | `new String(bytes, UTF_8)` |
| `zipfile`, `tarfile` | Contenedores de archivos, con compresión | `java.util.zip`, Commons Compress |

### 🩻 Esto sí funciona igual

El modelo es el de `ByteBuffer`: un formato declarado (orden de bytes, tamaño de cada campo) y lecturas en posiciones calculadas. `<` en el formato de `struct` es
`ByteOrder.LITTLE_ENDIAN`; sin él, `struct` usa el orden y la alineación de la máquina, como un `ByteBuffer` sin `order`, y el archivo deja de ser portable.

---

## 💻 3. El ejemplo que corre

`binario.py`:

```python
''' + code + '''
```

```bash
python3 binario.py              # solo la biblioteca estándar
```

Salida (Python 3.14.7, 05/10/2026) (los milisegundos son de la máquina que corre):

```text
registro de 20 bytes · archivo de 19.1 MB
CHAPINERO en 8s: b'CHAPINER'
unpack_from en bucle   155 ms · iter_unpack    84 ms · iguales: True
registro 700000 por mmap: id=700000 monto=1106.0 sede=CENTRO
mojibake: 'EngativÃ¡ Â· UsaquÃ©n' · reparado: 'Engativá · Usaquén'
zip stored   19.07 MB · comprimir    35 ms · leer   12 ms
zip deflate   4.15 MB · comprimir   476 ms · leer   36 ms
zip bzip2     1.75 MB · comprimir   800 ms · leer  284 ms
zip lzma      0.58 MB · comprimir  9339 ms · leer   83 ms
zip zstd      1.91 MB · comprimir    69 ms · leer   28 ms
tar: OutsideDestinationError: '../fuera.txt' would be extracted to '/w/fuera.txt', which is outside the destination
```

Seis lecturas. `struct` **corta sin avisar**: `CHAPINERO` en un campo de 8 bytes queda `CHAPINER`. `iter_unpack` lee el millón de registros en la mitad del tiempo
que el bucle. `mmap` saca el registro 700.000 sin leer los 19 MB. El *mojibake* se repara deshaciendo el error al revés. En compresión, **zstd** deja el archivo
en 1,91 MB en **69 ms**: menos de la mitad del tamaño de `deflate` y siete veces más rápido; `lzma` comprime tres veces más que zstd y tarda **135 veces más**. Y el
`.tar` con un `../fuera.txt` adentro no se extrae: `OutsideDestinationError`, sin haber pedido ningún filtro.

**Detalles con intención**

- **`<`** al principio del formato fija el orden de bytes y quita el relleno de alineación: el registro mide 4 + 8 + 8 = 20 bytes. Con el orden nativo (`@`, el
  valor por defecto) mediría 24, porque el `double` se alinea a 8.
- **`8s`** es un campo de bytes de ancho fijo: rellena con ceros los cortos y corta los largos. Al leer, `rstrip(b"\\0")` quita el relleno.
- **El *mojibake*** `Ã¡` es la firma de UTF-8 leído como Latin-1. Se repara con `.encode("latin-1").decode("utf-8")`, siempre que nadie haya guardado ya el texto
  roto con otra codificación encima.
- **`ZIP_ZSTANDARD`** usa el módulo `compression.zstd`, nuevo en 3.14. No hay que instalar nada.
- **El filtro de `tarfile`** es `"data"` por defecto desde 3.14: rechaza rutas absolutas, `..`, enlaces que salen del destino y archivos de dispositivo. Antes de 3.14
  extraía todo, y era una vulnerabilidad clásica (CVE-2007-4559).

---

## ⚠️ 4. Lo que se rompe

**El zip con zstd que nadie más abre.** Python 3.14 lo escribe y lo lee; `unzip` de Debian lo salta con `skipping: a.txt  need PK compat. v6.3 (can do v4.6)`, y
el explorador de Windows tampoco lo abre. Para archivos que van a otras personas, `deflate`; zstd para lo que solo lee Python (o herramientas que lo soporten).

**El campo que se corta.** `struct` no valida longitudes: un nombre de sede largo se trunca y el archivo sale "bien". Se valida el largo antes de empaquetar.

**El orden de bytes implícito.** Un formato sin `<` ni `>` funciona en el portátil y produce otro archivo en una máquina *big endian* o con otra alineación.

**`open()` sin `encoding`.** Desde Python 3.15 el valor por defecto será UTF-8 en todas partes (PEP 686); hasta entonces, en Windows depende de la configuración
regional. Se escribe `encoding="utf-8"` siempre.

---

## ⚖️ 5. Cuándo NO usarlo

**Para formatos que ya tienen biblioteca.** Un PNG, un PDF o un Parquet no se leen con `struct`: Pillow, `pypdf` o Arrow (`ar02`, `ar04`).

**Para archivos binarios grandes con muchos registros numéricos.** `np.fromfile` con un `dtype` estructurado lee el millón de registros como arreglo, sin bucle.

**zstd en un archivo que va a un cliente.** El formato no es el problema: las herramientas del otro lado sí.

---

## 🧪 6. Ejercicios (10)

**🟢 Fácil (1–3)**

1. Corre el ejemplo. **Criterio:** las once líneas, y por qué el registro mide 20 bytes.
2. Cambia `<` por `@` en el formato. **Criterio:** el nuevo tamaño del registro y del archivo.
3. Repara un texto con doble *mojibake* (codificado mal dos veces). **Criterio:** el texto original.

**🟡 Intermedio (4–6)**

4. Lee `pagos.bin` con `np.fromfile` y un `dtype` estructurado. **Criterio:** el total y el tiempo contra `iter_unpack`.
5. Valida el largo de la sede antes de empaquetar y lanza un error claro. **Criterio:** `CHAPINERO` falla con un mensaje que dice el campo y el máximo.
6. Comprime con zstd en niveles 1, 3, 10 y 19 (`compresslevel`). **Criterio:** la tabla de tamaño y tiempo.

**🟠 Difícil (7–9)**

7. Arma un `.tar` con un enlace simbólico a `/etc/passwd` y extráelo con los filtros `"data"`, `"tar"` y `"fully_trusted"`. **Criterio:** qué hace cada uno.
8. Escribe un lector de un formato de ancho fijo real (por ejemplo, el de un datáfono o un banco) con `struct`. **Criterio:** los registros leídos y una prueba.
9. Detecta la codificación de un CSV con `charset-normalizer`. **Criterio:** acierta en UTF-8, Latin-1 y cp1252, y dónde se equivoca.

**🔴 Muy difícil (10)**

10. Diseña el formato de intercambio de un archivo binario entre un servicio Java y uno de Python. **Criterio:** una página. *Rúbrica:* (a) el formato de
    `struct` y su equivalente en `ByteBuffer`; (b) el orden de bytes y la versión del formato; (c) cómo se validan los largos; (d) por qué no Protobuf o Arrow, o
    por qué sí.

---

## 📚 7. Referencias

**Documentación oficial**

- `struct`: https://docs.python.org/3/library/struct.html
- `zipfile` (incluye `ZIP_ZSTANDARD`): https://docs.python.org/3/library/zipfile.html
- Los filtros de extracción de `tarfile`: https://docs.python.org/3/library/tarfile.html#tarfile-extraction-filter

**Orden de lectura sugerido:** la tabla de formatos de `struct` (orden de bytes y alineación); después la sección de filtros de `tarfile`.

---

## 🚀 8. Cierre

La biblioteca estándar lee y escribe binario de verdad: `struct` con el orden de bytes explícito, `mmap` para no leer lo que no hace falta, codificaciones dichas
en voz alta. En 3.14, zstd comprime más que `deflate` siete veces más rápido —para archivos que solo abre Python—, y `tarfile` ya no extrae fuera del destino.

**La señal de que quedó bien:** *"Cada formato binario tiene su `<` o `>`, cada campo su validación de largo, y cada `open` su `encoding`."*

> 🏷️ **Cierra la sección con su tag**, cuando los ejercicios que elegiste estén hechos:
>
> ```bash
> git tag -a op-ar-fase-01 -m "op ar01 cerrada: struct, mmap, codificaciones, zip con zstd y tar filtrado"
> ```
>
> Los commits llevan su prefijo (`op ar01: …`) y los de ejercicio su número
> (`op ar01 ej07: …`).
'''
open('op147-ar01-binario-de-verdad.md','w').write(doc)
PYEOF
timeout 100 docker run --rm --label curso=python-for-java-devs python:3.14.7 python -c "
import struct; print(struct.calcsize('@i d 8s'))
import tarfile; print(tarfile.TarFile.extraction_filter)"

# --- 2026-10-05T21:19:15 · Check escape, mark ar01, URLs
cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516 && grep -n 'rstrip(b' ../../cursos-algoritmos-lenguajes/python-for-java-devs/op147-ar01-binario-de-verdad.md | head -3; python3 plan.py 147 147 ✅ ✅ | tail -1; python3 verificar_urls.py ../../cursos-algoritmos-lenguajes/python-for-java-devs/op147-ar01-binario-de-verdad.md | tail -2

# --- 2026-10-05T21:19:34 · Run Pillow thumbnail pipeline
mkdir -p /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516/salidas/ar02 && cd $_ && cat > miniaturas.py <<'EOF'
"""Un pipeline de miniaturas con Pillow: orientación EXIF, GPS que se va, draft y formatos de salida."""

import io
import time

from PIL import ExifTags, Image, ImageDraw, ImageOps, features

# Una foto de muestra sintética de 4000×3000, "tomada con el teléfono de lado" y con coordenadas GPS
photo = Image.radial_gradient("L").resize((4000, 3000)).convert("RGB")
ImageDraw.Draw(photo).text((100, 100), "ARRIBA", fill="red", font_size=400)
exif = Image.Exif()
exif[ExifTags.Base.Orientation] = 6                       # "rotar 90° a la derecha para ver bien"
exif[ExifTags.Base.Make] = "Teléfono de prueba"
exif.get_ifd(ExifTags.IFD.GPSInfo).update({ExifTags.GPS.GPSLatitudeRef: "N", ExifTags.GPS.GPSLatitude: (4.0, 41.0, 53.0)})
photo.save("muestra.jpg", quality=92, exif=exif)


def thumbnail(path, use_draft):
    start = time.perf_counter()
    with Image.open(path) as img:
        if use_draft:
            img.draft("RGB", (800, 800))                  # el decodificador JPEG reduce mientras lee
        img = ImageOps.exif_transpose(img)               # aplica la orientación y la quita del EXIF
        img.thumbnail((800, 800))
    return img, (time.perf_counter() - start) * 1000


plain, ms_plain = thumbnail("muestra.jpg", use_draft=False)
fast, ms_draft = thumbnail("muestra.jpg", use_draft=True)
print(f"miniatura sin draft {ms_plain:5.0f} ms · con draft {ms_draft:4.0f} ms · tamaño {fast.size}")

with Image.open("muestra.jpg") as original:
    naive = original.copy(); naive.thumbnail((800, 800))
    print(f"sin exif_transpose: {naive.size} (acostada) · con: {fast.size} (de pie)")
    print("GPS en el original:", bool(original.getexif().get_ifd(ExifTags.IFD.GPSInfo)))

for fmt, options in (("JPEG", {"quality": 85}), ("WEBP", {"quality": 80}), ("AVIF", {"quality": 60}), ("PNG", {})):
    if fmt == "AVIF" and not features.check("avif"):
        print("AVIF: no disponible en esta compilación de Pillow"); continue
    buffer = io.BytesIO()
    start = time.perf_counter()
    fast.save(buffer, fmt, **options)
    elapsed = (time.perf_counter() - start) * 1000
    buffer.seek(0)
    gps = bool(Image.open(buffer).getexif().get_ifd(ExifTags.IFD.GPSInfo))
    print(f"{fmt:<5} {buffer.getbuffer().nbytes / 1024:6.1f} KB · {elapsed:5.1f} ms · GPS: {gps}")
EOF
timeout 300 docker run --rm --label curso=python-for-java-devs -v "$PWD:/w" -w /w python:3.14.7 sh -c 'timeout 200 pip install -q --root-user-action=ignore Pillow==12.3.0 >/dev/null 2>&1; python miniaturas.py'

# --- 2026-10-05T21:19:45 · Rerun ar02 with EXIF-preservation pitfall
cat >> miniaturas.py <<'EOF'

# Conservar el EXIF "para no perder la fecha" arrastra también el GPS
buffer = io.BytesIO()
fast.save(buffer, "JPEG", quality=85, exif=fast.getexif())
buffer.seek(0)
print("JPEG con exif=fast.getexif(): GPS:", bool(Image.open(buffer).getexif().get_ifd(ExifTags.IFD.GPSInfo)))
EOF
timeout 300 docker run --rm --label curso=python-for-java-devs -v "$PWD:/w" -w /w python:3.14.7 sh -c 'timeout 200 pip install -q --root-user-action=ignore Pillow==12.3.0 >/dev/null 2>&1; python miniaturas.py'; rm -f muestra.jpg

# --- 2026-10-05T21:20:33 · Write ar02; verify MAX_IMAGE_PIXELS and RGBA claims
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs && python3 - <<'PYEOF'
code=open('/Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516/salidas/ar02/miniaturas.py').read().rstrip()
doc='''# 🖼️ ar02 — Pillow

> Python para desarrolladores Java senior · **Carta** · Track `ar` — Archivos y multimedia ·
> sección 2 de 10
> Se lee suelta: no hace falta ninguna otra sección de la carta.
> Versiones verificadas contra PyPI el 05/10/2026 · Código probado el 05/10/2026 con Python 3.14.7,
> en contenedor: las salidas son las de esa corrida.

---

## 🎯 1. Qué problema resuelve

Las fotos llegan del teléfono: grandes, de lado y con las coordenadas de dónde se tomaron. Antes de mostrarlas en una página o adjuntarlas a un correo, hay que
hacer tres cosas: reducirlas, enderezarlas y quitarles los metadatos que no deberían viajar. **Pillow** es la biblioteca de imágenes de Python desde hace quince años
(el sucesor de PIL), y hace las tres; la pregunta es si las hace **por defecto**, y la respuesta es que no del todo.

La sección arma un *pipeline* de miniaturas sobre una imagen de muestra sintética —un degradado con una palabra, de 4000×3000, marcada "de lado" en su EXIF y con
coordenadas GPS—, y mide lo que importa: cuánto ahorra `draft` al decodificar, qué pasa si no se aplica la orientación, qué formato de salida rinde más, y por dónde se
escapa el GPS.

---

## 🧠 2. El modelo

| Paso | Qué hace | El error si se omite |
|---|---|---|
| `Image.open` | Lee el encabezado; los píxeles, cuando se necesitan | — |
| `img.draft("RGB", (800, 800))` | Le pide al decodificador JPEG que reduzca **mientras lee** (por 2, 4 u 8) | Decodificar 12 megapíxeles para tirar 11 |
| `ImageOps.exif_transpose` | Rota según la etiqueta `Orientation` y la quita | Miniaturas acostadas |
| `img.thumbnail((800, 800))` | Reduce en el lugar, conservando la proporción | — |
| `img.save(..., exif=...)` | Guarda; **sin** `exif=`, no copia los metadatos | Con `exif=` del original, el GPS viaja |

### 🩻 Esto sí funciona igual

Es `ImageIO.read` y `Graphics2D.drawImage` con un `AffineTransform`, o Thumbnailator en Java: abrir, transformar, escribir. La orientación EXIF tampoco la aplica
`ImageIO` sola; quien vino de Java ya pasó por la foto acostada.

---

## 💻 3. El ejemplo que corre

`miniaturas.py`:

```python
''' + code + '''
```

```bash
pip install Pillow
python3 miniaturas.py
```

Salida (Python 3.14.7, 05/10/2026) (los milisegundos son de la máquina que corre; los tamaños, de una imagen sintética que comprime mucho mejor que una foto):

```text
miniatura sin draft    80 ms · con draft   41 ms · tamaño (600, 800)
sin exif_transpose: (800, 600) (acostada) · con: (600, 800) (de pie)
GPS en el original: True
JPEG    23.3 KB ·   7.2 ms · GPS: False
WEBP     5.4 KB ·  57.5 ms · GPS: False
AVIF     4.0 KB ·  35.7 ms · GPS: False
PNG     79.1 KB ·  30.0 ms · GPS: False
JPEG con exif=fast.getexif(): GPS: True
```

`draft` parte el tiempo a la mitad (80 → 41 ms) porque el decodificador entrega la imagen ya reducida a un cuarto. Sin `exif_transpose`, la miniatura sale **800×600,
acostada**: los píxeles del JPEG están de lado y solo la etiqueta dice cómo verlos. Los formatos: AVIF da el archivo más chico (4,0 KB) y JPEG el más rápido de
escribir (7,2 ms); WebP queda en medio en tamaño y es el más lento. Ninguno lleva el GPS, porque `save` sin `exif=` no copia metadatos. Pero la última línea es
la trampa: guardar con `exif=` "para no perder la fecha de la foto" **se lleva también las coordenadas**.

**Detalles con intención**

- **`draft`** solo funciona con JPEG (y en parte con PCD), antes de cargar los píxeles, y reduce por potencias de dos: pide al menos el tamaño indicado.
- **`exif_transpose`** devuelve una imagen nueva, ya rotada, y borra la etiqueta `Orientation` para que nadie la vuelva a aplicar.
- **`features.check("avif")`**: el soporte de AVIF viene en las ruedas de Pillow desde la 11.2; una compilación propia puede no tenerlo.
- **La imagen es sintética** (un degradado con texto): los tamaños comparan formatos entre sí, no predicen lo que pesará una foto real.

---

## ⚠️ 4. Lo que se rompe

**Conservar el EXIF entero.** Fecha, cámara… y GPS. Se copian solo las etiquetas que se quieren (`exif = Image.Exif(); exif[ExifTags.Base.DateTime] = …`) o se borra la
sección GPS (`del exif[ExifTags.IFD.GPSInfo]`) antes de guardar.

**La bomba de descompresión.** Una imagen de 50.000×50.000 píxeles pesa unos kilobytes comprimida y gigas en memoria. Pillow avisa por encima de
`Image.MAX_IMAGE_PIXELS` (unos 89 millones) y falla al doble; no se sube ese límite para imágenes que manda un usuario.

**El modo de color.** Un PNG con transparencia (`RGBA`) no se guarda como JPEG: `OSError: cannot write mode RGBA as JPEG`. Se convierte a `RGB` sobre un fondo.

**El perfil de color que se pierde.** Las fotos de teléfonos recientes vienen en Display P3; guardar sin `icc_profile=` las deja con colores lavados en el navegador.

---

## ⚖️ 5. Cuándo NO usarlo

**Para miles de imágenes por minuto.** `pyvips` (libvips) procesa por bloques con poca memoria y es varias veces más rápido en *pipelines* grandes.

**Si el servicio ya tiene un CDN que redimensiona.** Las imágenes se suben una vez y el CDN entrega cada tamaño.

**Para visión por computador.** Detección, segmentación o filtros complejos son trabajo de OpenCV o scikit-image (`ar03`).

---

## 🧪 6. Ejercicios (10)

**🟢 Fácil (1–3)**

1. Corre el ejemplo. **Criterio:** las ocho líneas, y por qué la miniatura sin `exif_transpose` sale acostada.
2. Repite con una foto tuya (sin datos sensibles). **Criterio:** la tabla de formatos con una foto real, y cuánto cambia contra la sintética.
3. Guarda la miniatura conservando solo la fecha del EXIF. **Criterio:** la fecha está y el GPS no.

**🟡 Intermedio (4–6)**

4. Procesa una carpeta de 200 imágenes con `ProcessPoolExecutor`. **Criterio:** el tiempo con 1 y con 8 procesos.
5. Abre un PNG `RGBA` y guárdalo como JPEG sobre fondo blanco. **Criterio:** sin error, y sin bordes negros donde había transparencia.
6. Compara la calidad de JPEG 85 y AVIF 60 con una métrica (SSIM de scikit-image). **Criterio:** el número de cada uno.

**🟠 Difícil (7–9)**

7. Construye una imagen de 20.000×20.000 en un PNG y ábrela. **Criterio:** la advertencia de bomba de descompresión, y cómo la conviertes en error.
8. Conserva el perfil ICC al hacer la miniatura de una foto en Display P3. **Criterio:** la miniatura se ve igual que el original en el navegador.
9. Mide el mismo *pipeline* con `pyvips`. **Criterio:** tiempo y memoria máxima contra Pillow, con 200 imágenes.

**🔴 Muy difícil (10)**

10. Diseña el servicio de subida de imágenes de un sistema. **Criterio:** una página. *Rúbrica:* (a) el *pipeline* con sus pasos; (b) qué metadatos se conservan y por
    qué; (c) los límites contra bombas y archivos falsos; (d) los formatos de salida, con números.

---

## 📚 7. Referencias

**Documentación oficial**

- Pillow: https://pillow.readthedocs.io/en/stable/
- `ImageOps.exif_transpose`: https://pillow.readthedocs.io/en/stable/reference/ImageOps.html
- Formatos de imagen que Pillow lee y escribe: https://pillow.readthedocs.io/en/stable/handbook/image-file-formats.html

**Orden de lectura sugerido:** el tutorial de Pillow; después la página de formatos, en la sección de JPEG (`draft`, `quality`, `icc_profile`).

---

## 🚀 8. Cierre

Pillow hace las miniaturas, pero no endereza ni limpia sola: `exif_transpose` es obligatorio, `draft` parte el tiempo a la mitad, y el GPS se va solo si no se copia
el EXIF entero. AVIF da el archivo más chico, JPEG el más rápido. Y las imágenes de usuarios llegan con límites de tamaño, no con confianza.

**La señal de que quedó bien:** *"Ninguna miniatura sale acostada, ninguna lleva coordenadas, y el tamaño máximo de entrada está escrito en el código."*

> 🏷️ **Cierra la sección con su tag**, cuando los ejercicios que elegiste estén hechos:
>
> ```bash
> git tag -a op-ar-fase-02 -m "op ar02 cerrada: miniaturas con orientación, sin GPS, con draft y formatos medidos"
> ```
>
> Los commits llevan su prefijo (`op ar02: …`) y los de ejercicio su número
> (`op ar02 ej07: …`).
'''
open('op148-ar02-pillow.md','w').write(doc)
PYEOF
timeout 200 docker run --rm --label curso=python-for-java-devs python:3.14.7 sh -c 'timeout 150 pip install -q --root-user-action=ignore Pillow==12.3.0 >/dev/null 2>&1; python -c "
from PIL import Image; print(Image.MAX_IMAGE_PIXELS)
import io
try: Image.new(\"RGBA\",(10,10)).save(io.BytesIO(),\"JPEG\")
except OSError as e: print(e)"'

# --- 2026-10-05T21:20:43 · Hedge AVIF claim, mark ar02
sed -i '' 's/el soporte de AVIF viene en las ruedas de Pillow desde la 11.2; una compilación propia puede no tenerlo\./las ruedas oficiales de Pillow 12 traen AVIF (en esta corrida, sí); una compilación propia puede no tenerlo./' op148-ar02-pillow.md && grep -c "Pillow 12 traen AVIF" op148-ar02-pillow.md; cd ../../zz-code/python-for-java-devs-20261005-f516 && python3 plan.py 148 148 ✅ ✅ | tail -1; python3 verificar_urls.py ../../cursos-algoritmos-lenguajes/python-for-java-devs/op148-ar02-pillow.md | tail -2

# --- 2026-10-05T21:20:54 · Check opencv headless/pycairo wheels and libGL import
curl -s https://pypi.org/pypi/opencv-python-headless/json | python3 -c "import json,sys; d=json.load(sys.stdin); print(d['info']['version'])"; curl -s https://pypi.org/pypi/pycairo/1.29.2/json | python3 -c "import json,sys; d=json.load(sys.stdin); print([u['filename'] for u in d['urls']])"; timeout 300 docker run --rm --label curso=python-for-java-devs python:3.14.7 sh -c 'timeout 200 pip install -q --root-user-action=ignore opencv-python==5.0.0.93 >/dev/null 2>&1; python -c "import cv2" 2>&1 | tail -1'

# --- 2026-10-05T21:21:26 · Run ar03 OpenCV/skimage/svg/cairo demo
mkdir -p /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516/salidas/ar03 && cd $_ && cat > imagenes.py <<'EOF'
"""OpenCV contra scikit-image con el mismo trabajo, el BGR de OpenCV, y una insignia en SVG y en cairo."""

import time

import cairo
import cv2
import drawsvg
import numpy as np
from PIL import Image
from skimage import feature, filters

# Una imagen de muestra: figuras con ruido, 2000×2000 en grises
rng = np.random.default_rng(42)
img = np.zeros((2000, 2000), dtype=np.uint8)
cv2.rectangle(img, (300, 300), (900, 1100), 200, -1)
cv2.circle(img, (1400, 1200), 400, 140, -1)
img = cv2.add(img, rng.integers(0, 40, img.shape, dtype=np.uint8))


def best(fn, n=3):
    times = []
    for _ in range(n):
        start = time.perf_counter(); result = fn(); times.append(time.perf_counter() - start)
    return result, min(times) * 1000


edges_cv, ms_cv = best(lambda: cv2.Canny(cv2.GaussianBlur(img, (0, 0), 2), 50, 150))
edges_sk, ms_sk = best(lambda: feature.canny(filters.gaussian(img, sigma=2), low_threshold=0.05, high_threshold=0.15))
print(f"OpenCV      {ms_cv:6.1f} ms · salida {edges_cv.dtype}, valores {np.unique(edges_cv).tolist()}, bordes {int((edges_cv > 0).sum()):,}")
print(f"scikit-image {ms_sk:5.1f} ms · salida {edges_sk.dtype}, valores {np.unique(edges_sk).tolist()}, bordes {int(edges_sk.sum()):,}")
print(f"filters.gaussian devuelve {filters.gaussian(img, sigma=2).dtype} en [0, 1], no uint8")

# El BGR de OpenCV: un rojo en RGB, escrito con cv2.imwrite y leído con Pillow
red_rgb = np.zeros((10, 10, 3), dtype=np.uint8); red_rgb[..., 0] = 255
cv2.imwrite("rojo.png", red_rgb)
print("rojo RGB escrito con OpenCV, leído con Pillow:", Image.open("rojo.png").getpixel((0, 0)))

# La misma insignia como vector (drawsvg) y como mapa de bits (cairo)
svg = drawsvg.Drawing(320, 80)
svg.append(drawsvg.Rectangle(0, 0, 320, 80, rx=12, fill="#1f4e79"))
svg.append(drawsvg.Text("Sede Kennedy", 32, 24, 50, fill="white", font_family="sans-serif"))
svg.save_svg("insignia.svg")

surface = cairo.ImageSurface(cairo.FORMAT_ARGB32, 320, 80)
ctx = cairo.Context(surface)
ctx.set_source_rgb(0x1F / 255, 0x4E / 255, 0x79 / 255)
ctx.new_sub_path()
for x, y, a in ((308, 12, -np.pi / 2), (308, 68, 0), (12, 68, np.pi / 2), (12, 12, np.pi)):
    ctx.arc(x, y, 12, a, a + np.pi / 2)
ctx.close_path(); ctx.fill()
ctx.set_source_rgb(1, 1, 1); ctx.select_font_face("sans-serif"); ctx.set_font_size(32)
ctx.move_to(24, 50); ctx.show_text("Sede Kennedy")
surface.write_to_png("insignia.png")
import os
print(f"insignia.svg {os.path.getsize('insignia.svg')} bytes (texto, escala sin perder) · insignia.png {os.path.getsize('insignia.png')} bytes (320×80 fijos)")
EOF
timeout 590 docker run --rm --label curso=python-for-java-devs -v "$PWD:/w" -w /w python:3.14.7 sh -c 'apt-get -qq update >/dev/null 2>&1; apt-get -qq install -y libcairo2-dev pkg-config >/dev/null 2>&1; timeout 400 pip install -q --root-user-action=ignore opencv-python-headless==5.0.0.93 scikit-image==0.26.0 drawsvg==2.4.2 pycairo==1.29.2 Pillow==12.3.0 >/dev/null 2>&1; pip list 2>/dev/null | grep -iE "^(numpy|opencv|scikit-image|pycairo|drawsvg) "; python imagenes.py'

# --- 2026-10-05T21:22:56 · Write ar03; rerun from doc; verify saturation claim
python3 - <<'EOF'
p='imagenes.py'; s=open(p).read()
s=s.replace("\nimport os\nprint(f\"insignia.svg","\nprint(f\"insignia.svg").replace('"""\n\nimport time\n','"""\n\nimport os\nimport time\n',1)
open(p,'w').write(s)
EOF
grep -n "^import" imagenes.py; rm -f rojo.png insignia.*
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs && python3 - <<'PYEOF'
code=open('/Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516/salidas/ar03/imagenes.py').read().rstrip()
doc='''# 🎨 ar03 — OpenCV, scikit-image y SVG

> Python para desarrolladores Java senior · **Carta** · Track `ar` — Archivos y multimedia ·
> sección 3 de 10
> Se lee suelta: no hace falta ninguna otra sección de la carta.
> Versiones verificadas contra PyPI el 05/10/2026 · Código probado el 05/10/2026 con Python 3.14.7,
> en contenedor: las salidas son las de esa corrida.

---

## 🎯 1. Qué problema resuelve

Pillow (`ar02`) redimensiona, rota y convierte. Cuando el trabajo es **analizar** la imagen —encontrar bordes, contar figuras, enderezar un documento
fotografiado—, entran las dos bibliotecas de procesamiento: **OpenCV**, la de C++ con enlaces de Python que usa la industria, y **scikit-image**, la de la comunidad
científica, escrita sobre NumPy y SciPy. Las dos trabajan con arreglos de NumPy, y las dos hacen casi lo mismo; lo que las separa son la velocidad y las
convenciones, y las convenciones son las que muerden.

La otra mitad de la sección va en sentido contrario: **generar** imágenes en vez de leerlas. Un gráfico, una insignia, un diagrama: como vector con SVG
(**drawsvg**) o como mapa de bits con **cairo** (`pycairo`). El ejemplo propio es una imagen de figuras con ruido y una insignia con un nombre de sede.

---

## 🧠 2. El modelo

| | OpenCV (`cv2`) | scikit-image |
|---|---|---|
| Escrita en | C++ con enlaces | Python sobre NumPy, SciPy y Cython |
| Imagen | `ndarray` `uint8`, **BGR** | `ndarray`, **RGB**; muchos filtros devuelven `float64` en [0, 1] |
| Velocidad | La más alta, con varios hilos | Menor; código legible y documentado |
| Instalar en un servidor | **`opencv-python-headless`** | `scikit-image` |
| Lo que la distingue | Video, cámaras, detección | API consistente, algoritmos científicos |

| | SVG (drawsvg) | cairo (`pycairo`) |
|---|---|---|
| Qué produce | Texto XML: vectores | Píxeles (PNG), y también PDF y SVG |
| Escala | Sin perder | Fija al tamaño de la superficie |
| Instalar | Python puro | Necesita la biblioteca de C del sistema |

### 🪞 Tu instinto de Java dice… y esta vez se equivoca

En Java, una imagen es un `BufferedImage` con su tipo declarado (`TYPE_INT_RGB`), y la biblioteca sabe qué tiene. El instinto espera que un arreglo de imagen
también "sepa" su orden de canales. No sabe: es un `ndarray` de números. OpenCV supone BGR y scikit-image o Pillow suponen RGB, y un arreglo pasado de una a otra
cambia el rojo por el azul sin ningún error.

---

## 💻 3. El ejemplo que corre

`imagenes.py`:

```python
''' + code + '''
```

```bash
apt-get install libcairo2-dev pkg-config        # pycairo no publica ruedas para Linux: compila contra el cairo del sistema
pip install opencv-python-headless scikit-image drawsvg pycairo Pillow
python3 imagenes.py
```

Salida (Python 3.14.7, 05/10/2026) (los milisegundos son de la máquina que corre):

```text
OpenCV      7.5 ms · salida uint8, valores [0, 255], bordes 5,703
scikit-image 246.3 ms · salida bool, valores [False, True], bordes 5,650
filters.gaussian devuelve float64 en [0, 1], no uint8
rojo RGB escrito con OpenCV, leído con Pillow: (0, 0, 255)
insignia.svg 355 bytes (texto, escala sin perder) · insignia.png 4518 bytes (320×80 fijos)
```

El mismo trabajo —suavizar y buscar bordes con Canny— tarda **7,5 ms en OpenCV y 246 ms en scikit-image**, 33 veces más, y encuentran casi los mismos bordes
(5.703 contra 5.650 píxeles; los umbrales no son idénticos entre las dos). Pero devuelven tipos distintos: OpenCV un `uint8` con 0 y 255, scikit-image un `bool`; y
`filters.gaussian` convierte a `float64` en [0, 1], de modo que un umbral pensado en 0–255 no encuentra nada. El rojo escrito por OpenCV llega a Pillow como
**azul** (0, 0, 255). Y la insignia: 355 bytes de SVG que escalan a cualquier tamaño, contra 4,5 KB de PNG fijo.

**Detalles con intención**

- **`opencv-python-headless`** y no `opencv-python`: el segundo trae las ventanas de `cv2.imshow` y necesita `libGL`; en un servidor o un contenedor, el `import`
  falla con `ImportError: libGL.so.1: cannot open shared object file`.
- **`cv2.add`** suma con saturación (255 + 10 = 255); `img + ruido` en NumPy da la vuelta (255 + 10 = 9). Es otra convención que cambia entre bibliotecas.
- **`cv2.cvtColor(img, cv2.COLOR_BGR2RGB)`** es la conversión que falta antes de pasarle a Pillow o scikit-image una imagen de OpenCV.
- **La insignia en cairo** dibuja las esquinas redondeadas con cuatro arcos: cairo es una API de dibujo de bajo nivel, como `Graphics2D`.

---

## ⚠️ 4. Lo que se rompe

**`opencv-python` en el servidor.** Funciona en el portátil, falla en el contenedor por `libGL`. Y si alguna dependencia instala `opencv-python` y otra la versión
`-headless`, las dos pisan el mismo módulo `cv2`. Se instala una sola variante.

**El rojo que sale azul.** Cualquier imagen que cruza entre OpenCV y el resto pasa por `cvtColor`. Se escribe una función de frontera y se usa siempre.

**El umbral en la escala equivocada.** Un `float64` en [0, 1] comparado con 128 da todo falso. Se convierte con `skimage.util.img_as_ubyte` o se piensa el umbral en la
escala del tipo.

**pycairo que no instala.** Sin `libcairo2-dev` y `pkg-config`, `pip install pycairo` falla al compilar en Linux. En contenedores, el paquete del sistema va en el
`Dockerfile`.

---

## ⚖️ 5. Cuándo NO usarlas

**Para redimensionar y convertir.** Pillow (`ar02`) alcanza y pesa mucho menos que OpenCV.

**scikit-image en un bucle de video en tiempo real.** 33 veces más lenta que OpenCV en este trabajo; para prototipar y para ciencia, sí.

**cairo para un gráfico de datos.** Matplotlib o Altair (`vz`) ya dibujan ejes y leyendas; cairo es para dibujos propios.

---

## 🧪 6. Ejercicios (10)

**🟢 Fácil (1–3)**

1. Corre el ejemplo. **Criterio:** las cinco líneas, y por qué el rojo sale azul.
2. Corrige el rojo con `cv2.cvtColor`. **Criterio:** Pillow lee (255, 0, 0).
3. Abre `insignia.svg` en el navegador y amplíalo al 800%. **Criterio:** los bordes siguen nítidos; con el PNG, no.

**🟡 Intermedio (4–6)**

4. Cuenta las figuras de la imagen con `cv2.findContours` y con `skimage.measure.label`. **Criterio:** las dos dan 2.
5. Repite la medición de Canny con `cv2.setNumThreads(1)`. **Criterio:** cuánto de la ventaja de OpenCV venía de los hilos.
6. Genera con drawsvg un gráfico de barras de cinco valores con sus etiquetas. **Criterio:** un SVG válido de menos de 2 KB.

**🟠 Difícil (7–9)**

7. Endereza la foto de un documento (detecta sus cuatro esquinas y aplica `cv2.warpPerspective`). **Criterio:** el documento queda rectangular.
8. Haz que cairo escriba la insignia en PDF en vez de PNG (`cairo.PDFSurface`). **Criterio:** un PDF vectorial con el texto seleccionable.
9. Mide la memoria de un *pipeline* de 100 imágenes en OpenCV y en scikit-image. **Criterio:** la memoria máxima de cada uno y por qué difieren.

**🔴 Muy difícil (10)**

10. Decide la biblioteca de un servicio que procesa fotos de documentos. **Criterio:** una página. *Rúbrica:* (a) las operaciones que necesita; (b) los tiempos medidos
    de las dos; (c) cómo se maneja el orden de canales en la frontera; (d) qué se instala en el contenedor y cuánto pesa.

---

## 📚 7. Referencias

**Documentación oficial**

- OpenCV en Python: https://docs.opencv.org/5.x/d6/d00/tutorial_py_root.html
- scikit-image: https://scikit-image.org/docs/stable/
- drawsvg: https://github.com/cduck/drawsvg
- pycairo: https://pycairo.readthedocs.io/en/latest/

**Orden de lectura sugerido:** la guía de usuario de scikit-image sobre tipos de datos (la escala de cada `dtype`); después los tutoriales de OpenCV de procesamiento
de imágenes.

---

## 🚀 8. Cierre

OpenCV y scikit-image hacen el mismo trabajo sobre los mismos arreglos de NumPy, una 33 veces más rápido que la otra en este ejemplo, y con convenciones distintas
que no avisan: BGR contra RGB, `uint8` contra `float64` en [0, 1]. Para generar, SVG escala sin perder y cairo dibuja píxeles con la biblioteca de C del sistema.

**La señal de que quedó bien:** *"Toda imagen que cruza entre OpenCV y el resto pasa por una sola función de conversión, y el contenedor instala la variante
`-headless`."*

> 🏷️ **Cierra la sección con su tag**, cuando los ejercicios que elegiste estén hechos:
>
> ```bash
> git tag -a op-ar-fase-03 -m "op ar03 cerrada: OpenCV y scikit-image medidas, sus convenciones, SVG y cairo"
> ```
>
> Los commits llevan su prefijo (`op ar03: …`) y los de ejercicio su número
> (`op ar03 ej07: …`).
'''
open('op149-ar03-opencv-y-svg.md','w').write(doc)
PYEOF
cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516 && timeout 590 python3 humo.py op149-ar03-opencv-y-svg.md ar03 'imagenes.py=@imagenes.py' --cmd 'apt-get -qq update >/dev/null 2>&1; apt-get -qq install -y libcairo2-dev pkg-config >/dev/null 2>&1; timeout 400 pip install -q --root-user-action=ignore opencv-python-headless==5.0.0.93 scikit-image==0.26.0 drawsvg==2.4.2 pycairo==1.29.2 Pillow==12.3.0 >/dev/null 2>&1; python imagenes.py; python -c "
import numpy as np, cv2
from skimage import measure
img=np.zeros((50,50),np.uint8); a=np.uint8(250); print(\"numpy\", (np.array([250],np.uint8)+np.uint8(10))[0], \"cv2.add\", cv2.add(np.array([[250]],np.uint8), np.array([[10]],np.uint8))[0,0])"'

# --- 2026-10-05T21:23:35 · Fix exercise 4, mark ar03, URLs
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs && sed -i '' 's/4. Cuenta las figuras de la imagen con `cv2.findContours` y con `skimage.measure.label`. \*\*Criterio:\*\* las dos dan 2./4. Umbraliza la imagen y cuenta las figuras con `cv2.findContours` y con `skimage.measure.label`. **Criterio:** las dos dan 2, sin contar el ruido./' op149-ar03-opencv-y-svg.md && grep -c "sin contar el ruido" op149-ar03-opencv-y-svg.md; cd ../../zz-code/python-for-java-devs-20261005-f516 && python3 plan.py 149 149 ✅ ✅ | tail -1; python3 verificar_urls.py ../../cursos-algoritmos-lenguajes/python-for-java-devs/op149-ar03-opencv-y-svg.md | tail -3

# --- 2026-10-05T21:23:42 · Find a valid OpenCV Python tutorial URL
for u in https://docs.opencv.org/4.x/d6/d00/tutorial_py_root.html https://docs.opencv.org/5.x/ https://docs.opencv.org/5.0.0/d6/d00/tutorial_py_root.html https://docs.opencv.org/master/d6/d00/tutorial_py_root.html; do echo "$(curl -s -o /dev/null -w '%{http_code}' -L "$u") $u"; done

# --- 2026-10-05T21:23:47 · Retry OpenCV URLs with browser UA
UA="Mozilla/5.0 (Macintosh; Intel Mac OS X 14_0) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/130 Safari/537.36"; for u in https://docs.opencv.org/4.x/d6/d00/tutorial_py_root.html https://docs.opencv.org/5.x/d6/d00/tutorial_py_root.html https://docs.opencv.org/5.x/ ; do echo "$(curl -s -o /dev/null -w '%{http_code}' -A "$UA" -L "$u") $u"; done

# --- 2026-10-05T21:23:56 · Replace OpenCV docs link, recheck URLs
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs && sed -i '' 's#- OpenCV en Python: https://docs.opencv.org/5.x/d6/d00/tutorial_py_root.html#- `opencv-python`, sus cuatro variantes y cuál instalar en un servidor: https://github.com/opencv/opencv-python#' op149-ar03-opencv-y-svg.md && sed -i '' 's/después los tutoriales de OpenCV de procesamiento\nde imágenes\./X/' op149-ar03-opencv-y-svg.md && python3 - <<'EOF'
p='op149-ar03-opencv-y-svg.md'; s=open(p).read()
old="después los tutoriales de OpenCV de procesamiento\nde imágenes."
new="después el README de `opencv-python`, sobre\nlas variantes del paquete."
assert old in s; s=s.replace(old,new); open(p,'w').write(s)
EOF
cd ../../zz-code/python-for-java-devs-20261005-f516 && python3 verificar_urls.py ../../cursos-algoritmos-lenguajes/python-for-java-devs/op149-ar03-opencv-y-svg.md | tail -2

# --- 2026-10-05T21:24:20 · Run ar04 PDF demo
mkdir -p /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516/salidas/ar04 && cd $_ && cat > pdfs.py <<'EOF'
"""Un PDF de muestra: generarlo, extraer su texto y su tabla con tres bibliotecas, firmarlo y leerlo con OCR."""

import datetime as dt
import io
import time

import pdfplumber
import pymupdf
import pytesseract
from cryptography import x509
from cryptography.hazmat.primitives import hashes, serialization
from cryptography.hazmat.primitives.asymmetric import ec
from cryptography.x509.oid import NameOID
from PIL import Image
from pyhanko.pdf_utils.incremental_writer import IncrementalPdfFileWriter
from pyhanko.pdf_utils.reader import PdfFileReader
from pyhanko.sign import signers
from pyhanko.sign.validation import validate_pdf_signature
from pyhanko_certvalidator import ValidationContext
from pypdf import PdfReader
from reportlab.lib.pagesizes import letter
from reportlab.platypus import Paragraph, SimpleDocTemplate, Table, TableStyle
from reportlab.lib.styles import getSampleStyleSheet

ROWS = [["Sede", "Concepto", "Valor"], ["Kennedy", "Arriendo de octubre", "4.200.000"],
        ["Engativá", "Servicios públicos", "1.150.000"], ["Fontibón", "Mantenimiento de sillones", "780.000"]]

# 1) Generar con ReportLab
buffer = io.BytesIO()
doc = SimpleDocTemplate(buffer, pagesize=letter)
table = Table(ROWS)
table.setStyle(TableStyle([("GRID", (0, 0), (-1, -1), 0.5, "grey")]))
doc.build([Paragraph("Relación de gastos de muestra · octubre de 2026", getSampleStyleSheet()["Title"]), table])
pdf = buffer.getvalue()
print(f"ReportLab: {len(pdf):,} bytes")

# 2) Extraer: texto con pypdf y PyMuPDF, tabla con pdfplumber
for name, extract in (("pypdf", lambda: PdfReader(io.BytesIO(pdf)).pages[0].extract_text()),
                      ("PyMuPDF", lambda: pymupdf.open(stream=pdf).load_page(0).get_text())):
    start = time.perf_counter(); text = extract(); ms = (time.perf_counter() - start) * 1000
    print(f"{name:<8} {ms:5.1f} ms · {'Engativá' in text=} · línea de Kennedy: {next(l for l in text.splitlines() if 'Kennedy' in l)!r}")
with pdfplumber.open(io.BytesIO(pdf)) as plumber:
    print("pdfplumber, la tabla:", plumber.pages[0].extract_table()[1])

# 3) Firmar con un certificado de prueba y verificar; después alterar un byte
key = ec.generate_private_key(ec.SECP256R1())
name = x509.Name([x509.NameAttribute(NameOID.COMMON_NAME, "Firma de prueba")])
now = dt.datetime.now(dt.UTC)
cert = (x509.CertificateBuilder().subject_name(name).issuer_name(name).public_key(key.public_key())
        .serial_number(1).not_valid_before(now).not_valid_after(now + dt.timedelta(days=1))
        .sign(key, hashes.SHA256()))
open("clave.pem", "wb").write(key.private_bytes(serialization.Encoding.PEM, serialization.PrivateFormat.PKCS8,
                                                   serialization.NoEncryption()))
open("cert.pem", "wb").write(cert.public_bytes(serialization.Encoding.PEM))
signer = signers.SimpleSigner.load("clave.pem", "cert.pem")
signed = io.BytesIO()
signers.sign_pdf(IncrementalPdfFileWriter(io.BytesIO(pdf)), signers.PdfSignatureMetadata(field_name="Firma"),
                 signer=signer, output=signed)
context = ValidationContext(trust_roots=[signer.signing_cert])


def check(data):
    status = validate_pdf_signature(PdfFileReader(io.BytesIO(data)).embedded_signatures[0], context)
    return f"intacto={status.intact} · válido={status.valid}"


print("firmado:", check(signed.getvalue()))
tampered = signed.getvalue().replace(b"4.200.000", b"9.200.000")
print("con un valor cambiado:", check(tampered))

# 4) OCR: el PDF como imagen, leído por Tesseract
page = pymupdf.open(stream=pdf).load_page(0).get_pixmap(dpi=200)
image = Image.open(io.BytesIO(page.tobytes("png")))
start = time.perf_counter()
ocr = pytesseract.image_to_string(image, lang="spa")
print(f"OCR {(time.perf_counter() - start) * 1000:5.0f} ms · línea de Engativá: {next(l for l in ocr.splitlines() if 'Engativ' in l)!r}")
EOF
timeout 590 docker run --rm --label curso=python-for-java-devs -v "$PWD:/w" -w /w python:3.14.7 sh -c 'apt-get -qq update >/dev/null 2>&1; apt-get -qq install -y tesseract-ocr tesseract-ocr-spa >/dev/null 2>&1; tesseract --version 2>&1 | head -1; timeout 400 pip install -q --root-user-action=ignore reportlab==5.0.1 pypdf==6.19.0 pdfplumber==0.11.10 PyMuPDF==1.28.2 pyhanko==0.37.0 pytesseract==0.3.13 Pillow==12.3.0 >/dev/null 2>&1; python pdfs.py'

# --- 2026-10-05T21:25:10 · Rerun ar04 with proper tamper and OCR count
python3 - <<'EOF'
p='pdfs.py'; s=open(p).read()
reps=[
('''    print(f"{name:<8} {ms:5.1f} ms · {'Engativá' in text=} · línea de Kennedy: {next(l for l in text.splitlines() if 'Kennedy' in l)!r}")''',
 '''    lines = text.splitlines()
    print(f"{name:<8} {ms:4.1f} ms · {' | '.join(lines[lines.index('Kennedy') - 3:lines.index('Kennedy') + 3])}")'''),
('''tampered = signed.getvalue().replace(b"4.200.000", b"9.200.000")
print("con un valor cambiado:", check(tampered))''',
 '''tampered = signed.getvalue().replace(b"ReportLab", b"ReportLaX", 1)       # un byte dentro de lo firmado
print("con un byte cambiado:", check(tampered))'''),
('''print(f"OCR {(time.perf_counter() - start) * 1000:5.0f} ms · línea de Engativá: {next(l for l in ocr.splitlines() if 'Engativ' in l)!r}")''',
 '''found = [value for row in ROWS[1:] for value in row if value in ocr]
print(f"OCR {(time.perf_counter() - start) * 1000:5.0f} ms · reconoció {len(found)} de 9 celdas · faltan: {[v for row in ROWS[1:] for v in row if v not in found]}")'''),
]
for a,b in reps:
    assert a in s, a[:50]; s=s.replace(a,b)
open(p,'w').write(s)
EOF
timeout 590 docker run --rm --label curso=python-for-java-devs -v "$PWD:/w" -w /w python:3.14.7 sh -c 'apt-get -qq update >/dev/null 2>&1; apt-get -qq install -y tesseract-ocr tesseract-ocr-spa >/dev/null 2>&1; timeout 400 pip install -q --root-user-action=ignore reportlab==5.0.1 pypdf==6.19.0 pdfplumber==0.11.10 PyMuPDF==1.28.2 pyhanko==0.37.0 pytesseract==0.3.13 Pillow==12.3.0 >/dev/null 2>&1; python pdfs.py' 2>&1 | tail -12

# --- 2026-10-05T21:25:50 · Rerun ar04 with bottom_line
python3 - <<'EOF'
p='pdfs.py'; s=open(p).read()
a='''    return f"intacto={status.intact} · válido={status.valid}"'''
b='''    return f"intact={status.intact} · valid={status.valid} · bottom_line={status.bottom_line}"'''
assert a in s; s=s.replace(a,b); open(p,'w').write(s)
EOF
timeout 590 docker run --rm --label curso=python-for-java-devs -v "$PWD:/w" -w /w python:3.14.7 sh -c 'apt-get -qq update >/dev/null 2>&1; apt-get -qq install -y tesseract-ocr tesseract-ocr-spa >/dev/null 2>&1; timeout 400 pip install -q --root-user-action=ignore reportlab==5.0.1 pypdf==6.19.0 pdfplumber==0.11.10 PyMuPDF==1.28.2 pyhanko==0.37.0 pytesseract==0.3.13 Pillow==12.3.0 >/dev/null 2>&1; python pdfs.py' 2>&1 | tail -12; rm -f clave.pem cert.pem

# --- 2026-10-05T21:26:59 · Write ar04, mark, check URLs
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs && python3 - <<'PYEOF'
code=open('/Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516/salidas/ar04/pdfs.py').read().rstrip()
doc='''# 📄 ar04 — PDF

> Python para desarrolladores Java senior · **Carta** · Track `ar` — Archivos y multimedia ·
> sección 4 de 10
> Se lee suelta: no hace falta ninguna otra sección de la carta.
> Versiones verificadas contra PyPI el 05/10/2026 · Código probado el 05/10/2026 con Python 3.14.7,
> en contenedor: las salidas son las de esa corrida.

---

## 🎯 1. Qué problema resuelve

El PDF es el formato donde termina todo lo que se imprime, se firma o se manda a un ente externo: facturas, relaciones de gastos, certificados. Python tiene una
biblioteca para cada parte del ciclo, y conviene saber cuál es cuál: **ReportLab** genera; **pypdf** lee, une y corta; **pdfplumber** extrae tablas; **PyMuPDF**
lee rápido y convierte páginas a imágenes; **pyHanko** firma y verifica; y **Tesseract** (con `pytesseract` u `ocrmypdf`) lee el texto de un PDF que es solo una
imagen escaneada.

La sección recorre el ciclo completo con un documento de muestra —una relación de gastos de tres sedes—: lo genera, extrae su texto y su tabla, lo firma, lo
altera para ver qué dice la verificación, y lo lee con OCR. La verificación tiene una trampa en su API que vale la sección entera.

---

## 🧠 2. El modelo

| Biblioteca | Para qué | Licencia | El equivalente en Java |
|---|---|---|---|
| **ReportLab** | Generar PDF desde código (*platypus*: párrafos, tablas) | BSD | iText, OpenPDF |
| **pypdf** | Leer, unir, cortar, rotar; texto simple | BSD | PDFBox |
| **pdfplumber** | Extraer **tablas** y posiciones de caracteres | MIT | Tabula |
| **PyMuPDF** | Leer muy rápido, renderizar páginas a imagen | **AGPL** o comercial | — |
| **pyHanko** | Firmar (PAdES) y validar firmas | MIT | iText con firma, DSS |
| **Tesseract** (`pytesseract`, `ocrmypdf`) | OCR: texto desde imágenes | Apache | Tess4J |

### 🪞 Tu instinto de Java dice… y esta vez se equivoca

Un PDF parece un documento con texto y tablas. No lo es: es una lista de instrucciones de dibujo ("pon este glifo en esta coordenada"). No hay filas ni celdas, solo
caracteres en posiciones. Por eso extraer el texto da cada celda en su propia línea, y por eso extraer la tabla necesita una biblioteca que **reconstruya** las filas a
partir de las líneas dibujadas y las posiciones.

---

## 💻 3. El ejemplo que corre

`pdfs.py`:

```python
''' + code + '''
```

```bash
apt-get install tesseract-ocr tesseract-ocr-spa    # el motor de OCR y el idioma español; en el contenedor, Tesseract 5.5.0
pip install reportlab pypdf pdfplumber PyMuPDF pyhanko pytesseract Pillow
python3 pdfs.py
```

Salida (Python 3.14.7, 05/10/2026) (los milisegundos son de la máquina que corre):

```text
ReportLab: 1,927 bytes
pypdf     1.7 ms ·  Sede | Concepto | Valor | Kennedy | Arriendo de octubre | 4.200.000
PyMuPDF   2.3 ms · Sede | Concepto | Valor | Kennedy | Arriendo de octubre | 4.200.000
pdfplumber, la tabla: ['Kennedy', 'Arriendo de octubre', '4.200.000']
firmado: intact=True · valid=True · bottom_line=True
con un byte cambiado: intact=False · valid=True · bottom_line=False
OCR   389 ms · reconoció 9 de 9 celdas · faltan: []
```

ReportLab genera el documento en menos de 2 KB. pypdf y PyMuPDF extraen el texto en 2 ms, **una celda por línea**: la tabla se volvió una lista. pdfplumber la
reconstruye como filas. La firma se verifica, y con un solo byte cambiado dentro del rango firmado la verificación dice **`valid=True`** —la firma criptográfica sigue
siendo correcta— pero **`intact=False`**: el documento ya no es el que se firmó. El veredicto completo es `bottom_line`. Y el OCR, sobre la página convertida en imagen
a 200 ppp, reconoce las nueve celdas, tildes incluidas, en 389 ms: 200 veces más que extraer el texto, cuando hay texto que extraer.

**Detalles con intención**

- **`bottom_line`** es la respuesta a "¿confío en este documento?". `valid` solo dice que la firma corresponde al resumen guardado; `intact`, que el resumen
  corresponde al documento. Hacen falta las dos, y `bottom_line` las combina con la confianza en el certificado.
- **El certificado es autofirmado y vale un día**: para probar el mecanismo. Una firma con validez legal usa un certificado de una entidad acreditada y, para que valga
  años, un sello de tiempo (`pyhanko` lo pide con `timestamper=`).
- **`replace(b"ReportLab", b"ReportLaX", 1)`** cambia el nombre del productor, que está en el rango firmado y sin comprimir. Cambiar `4.200.000` no habría encontrado
  nada: el contenido de la página está comprimido con Flate.
- **`get_pixmap(dpi=200)`**: Tesseract necesita resolución; a 72 ppp falla en las tildes y los números.

---

## ⚠️ 4. Lo que se rompe

**Verificar con `valid`.** El código que revisa `status.valid` acepta un documento alterado después de firmar. Se revisa `bottom_line`.

**La licencia de PyMuPDF.** Es AGPL: usarla en un servicio que se ofrece por red obliga a publicar el código del servicio, o a comprar la licencia comercial. pypdf
y pdfplumber, con licencias permisivas, cubren casi todo lo demás.

**Extraer tablas con `extract_text`.** Una celda por línea, y las celdas con dos líneas de texto se mezclan con la siguiente. Tablas, con pdfplumber o Camelot.

**OCR sobre un PDF que ya tiene texto.** 200 veces más lento y con errores posibles. Primero se intenta extraer; si sale vacío, el PDF es una imagen y entra el OCR.
`ocrmypdf` lo decide solo y agrega una capa de texto al PDF.

---

## ⚖️ 5. Cuándo NO usarlo

**Para generar documentos con mucho diseño.** HTML y CSS con WeasyPrint, o Typst (`ar07`), son más fáciles de mantener que el código de ReportLab.

**OCR para documentos con estructura fija y volumen alto.** Un servicio de extracción de documentos (de la nube o un modelo de visión) entiende campos; Tesseract solo
devuelve texto.

**Firmar con validez legal desde un *script*.** La firma con certificado acreditado, sello de tiempo y custodia de la clave es un proceso; el código es la parte chica.

---

## 🧪 6. Ejercicios (10)

**🟢 Fácil (1–3)**

1. Corre el ejemplo. **Criterio:** las siete líneas, y la diferencia entre `valid`, `intact` y `bottom_line`.
2. Une el PDF de muestra con otro en uno solo con pypdf. **Criterio:** un PDF de dos páginas.
3. Extrae las posiciones de los caracteres de "Kennedy" con pdfplumber (`page.chars`). **Criterio:** las coordenadas de cada letra.

**🟡 Intermedio (4–6)**

4. Agrega al documento una celda con dos líneas de texto y vuelve a extraer la tabla. **Criterio:** qué hace pdfplumber y qué hace `extract_text`.
5. Corre el OCR a 72, 150 y 300 ppp. **Criterio:** celdas reconocidas y tiempo en cada resolución.
6. Pasa el PDF convertido a imagen por `ocrmypdf`. **Criterio:** el PDF resultante tiene texto seleccionable.

**🟠 Difícil (7–9)**

7. Firma dos veces el mismo PDF (dos firmantes) y altera el documento entre las dos firmas. **Criterio:** qué dice la validación de cada firma.
8. Agrega un sello de tiempo a la firma con un servidor TSA de prueba. **Criterio:** la validación muestra la hora del sello.
9. Extrae la tabla de un PDF real de un banco o un ente público. **Criterio:** las filas correctas, y lo que tuviste que configurar.

**🔴 Muy difícil (10)**

10. Diseña el flujo de un documento firmado que sale de un sistema y vuelve verificado. **Criterio:** una página. *Rúbrica:* (a) cómo se genera; (b) cómo se firma y
    dónde vive la clave; (c) cómo se verifica al volver, con `bottom_line`; (d) qué bibliotecas y sus licencias.

---

## 📚 7. Referencias

**Documentación oficial**

- pypdf: https://pypdf.readthedocs.io/en/stable/
- pdfplumber: https://github.com/jsvine/pdfplumber
- pyHanko: https://docs.pyhanko.eu/en/latest/
- ReportLab, la guía de usuario: https://docs.reportlab.com/reportlab/userguide/ch1_intro/

**Orden de lectura sugerido:** el README de pdfplumber, que explica cómo reconstruye las tablas; después la guía de validación de firmas de pyHanko.

---

## 🚀 8. Cierre

Un PDF son instrucciones de dibujo, no un documento con estructura: el texto sale celda por celda, las tablas hay que reconstruirlas, y el OCR es el último recurso,
200 veces más lento. Para firmar, pyHanko; para verificar, `bottom_line`, porque `valid` sigue en `True` con el documento alterado. Y PyMuPDF es la más rápida, con
licencia AGPL.

**La señal de que quedó bien:** *"La verificación de firmas revisa `bottom_line`, la extracción de tablas usa pdfplumber, y nadie usa PyMuPDF sin haber leído su
licencia."*

> 🏷️ **Cierra la sección con su tag**, cuando los ejercicios que elegiste estén hechos:
>
> ```bash
> git tag -a op-ar-fase-04 -m "op ar04 cerrada: generar, extraer, firmar, verificar con bottom_line y OCR"
> ```
>
> Los commits llevan su prefijo (`op ar04: …`) y los de ejercicio su número
> (`op ar04 ej07: …`).
'''
open('op150-ar04-pdf.md','w').write(doc)
PYEOF
cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516 && python3 plan.py 150 150 ✅ ✅ | tail -1; python3 verificar_urls.py ../../cursos-algoritmos-lenguajes/python-for-java-devs/op150-ar04-pdf.md | tail -3

# --- 2026-10-05T21:27:22 · Run ar05 Office demo
mkdir -p /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516/salidas/ar05 && cd $_ && cat > office.py <<'EOF'
"""Office desde Python: Excel con dos bibliotecas, la fórmula que nadie calculó, Word con plantilla y una diapositiva."""

import os
import time
import tracemalloc

import openpyxl
import xlsxwriter
from docx import Document
from pptx import Presentation
from pptx.chart.data import CategoryChartData
from pptx.enum.chart import XL_CHART_TYPE
from pptx.util import Inches

BRANCHES = ["Centro", "Chapinero", "Suba", "Kennedy", "Usaquén", "Engativá", "Fontibón", "Restrepo"]
N = 100_000


def measure(fn):
    tracemalloc.start(); start = time.perf_counter(); fn()
    elapsed = time.perf_counter() - start; peak = tracemalloc.get_traced_memory()[1]; tracemalloc.stop()
    return f"{elapsed:5.2f} s · memoria máx. {peak / 2**20:5.0f} MB"


# 1) 100.000 filas con openpyxl y con XlsxWriter (modo de memoria constante)
def with_openpyxl():
    wb = openpyxl.Workbook(); ws = wb.active
    ws.append(["fila", "sede", "valor"])
    for i in range(N):
        ws.append([i, BRANCHES[i % 8], i * 1.5])
    ws.append(["", "total", f"=SUM(C2:C{N + 1})"])
    wb.save("openpyxl.xlsx")


def with_xlsxwriter():
    wb = xlsxwriter.Workbook("xlsxwriter.xlsx", {"constant_memory": True}); ws = wb.add_worksheet()
    ws.write_row(0, 0, ["fila", "sede", "valor"])
    for i in range(N):
        ws.write_row(i + 1, 0, [i, BRANCHES[i % 8], i * 1.5])
    ws.write_row(N + 1, 1, ["total", f"=SUM(C2:C{N + 1})"])
    wb.close()


print(f"openpyxl   {measure(with_openpyxl)} · {os.path.getsize('openpyxl.xlsx') / 2**20:.1f} MB")
print(f"XlsxWriter {measure(with_xlsxwriter)} · {os.path.getsize('xlsxwriter.xlsx') / 2**20:.1f} MB")

# 2) La fórmula: openpyxl no calcula
total = openpyxl.load_workbook("openpyxl.xlsx").active.cell(N + 2, 3).value
cached = openpyxl.load_workbook("openpyxl.xlsx", data_only=True).active.cell(N + 2, 3).value
print(f"la celda del total: {total!r} · con data_only=True: {cached!r}")

# 3) Word: una plantilla con el marcador partido en dos "runs" por un cambio de formato
template = Document()
paragraph = template.add_paragraph("Informe de la sede ")
paragraph.add_run("{{se")
paragraph.add_run("de}}").bold = True                     # alguien puso en negrita la mitad del marcador
template.save("plantilla.docx")
doc = Document("plantilla.docx")
for p in doc.paragraphs:
    for run in p.runs:
        run.text = run.text.replace("{{sede}}", "Kennedy")
print(f"reemplazo run por run: {doc.paragraphs[0].text!r} · runs: {[r.text for r in doc.paragraphs[0].runs]}")

# 4) PowerPoint: una diapositiva con un gráfico nativo (editable en PowerPoint)
deck = Presentation()
slide = deck.slides.add_slide(deck.slide_layouts[5])
slide.shapes.title.text = "Filas por sede (muestra)"
data = CategoryChartData(); data.categories = BRANCHES; data.add_series("filas", [N // 8] * 8)
slide.shapes.add_chart(XL_CHART_TYPE.COLUMN_CLUSTERED, Inches(0.5), Inches(1.5), Inches(9), Inches(5), data)
deck.save("muestra.pptx")
print(f"muestra.pptx {os.path.getsize('muestra.pptx') / 1024:.0f} KB con un gráfico nativo")
for f in ("openpyxl.xlsx", "xlsxwriter.xlsx", "plantilla.docx", "muestra.pptx"):
    os.remove(f)
EOF
timeout 590 docker run --rm --label curso=python-for-java-devs -v "$PWD:/w" -w /w python:3.14.7 sh -c 'timeout 400 pip install -q --root-user-action=ignore openpyxl==3.1.5 XlsxWriter==3.2.9 python-docx==1.2.0 python-pptx==1.0.2 >/dev/null 2>&1; python office.py'

# --- 2026-10-05T21:27:59 · Rerun ar05 measuring time without tracemalloc
python3 - <<'EOF'
p='office.py'; s=open(p).read()
a='''def measure(fn):
    tracemalloc.start(); start = time.perf_counter(); fn()
    elapsed = time.perf_counter() - start; peak = tracemalloc.get_traced_memory()[1]; tracemalloc.stop()
    return f"{elapsed:5.2f} s · memoria máx. {peak / 2**20:5.0f} MB"'''
b='''def measure(fn):
    start = time.perf_counter(); fn(); elapsed = time.perf_counter() - start
    tracemalloc.start(); fn(); peak = tracemalloc.get_traced_memory()[1]; tracemalloc.stop()   # aparte: tracemalloc frena
    return f"{elapsed:5.2f} s · memoria máx. {peak / 2**20:5.0f} MB"'''
assert a in s; s=s.replace(a,b); open(p,'w').write(s)
EOF
timeout 590 docker run --rm --label curso=python-for-java-devs -v "$PWD:/w" -w /w python:3.14.7 sh -c 'timeout 400 pip install -q --root-user-action=ignore openpyxl==3.1.5 XlsxWriter==3.2.9 python-docx==1.2.0 python-pptx==1.0.2 >/dev/null 2>&1; python office.py'

# --- 2026-10-05T21:29:01 · Write ar05, mark, URLs
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs && python3 - <<'PYEOF'
code=open('/Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516/salidas/ar05/office.py').read().rstrip()
doc='''# 📊 ar05 — Office: Word, Excel y PowerPoint

> Python para desarrolladores Java senior · **Carta** · Track `ar` — Archivos y multimedia ·
> sección 5 de 10
> Se lee suelta: no hace falta ninguna otra sección de la carta.
> Versiones verificadas contra PyPI el 05/10/2026 · Código probado el 05/10/2026 con Python 3.14.7,
> en contenedor: las salidas son las de esa corrida.

---

## 🎯 1. Qué problema resuelve

Las personas que no son ingenieras trabajan en Excel, Word y PowerPoint, y la mitad de los encargos de automatización terminan en uno de esos archivos: el reporte
mensual en Excel, la carta con los datos de cada sede en Word, la presentación del comité con su gráfico. Los formatos de Office son *zips* con XML adentro (Office
Open XML), y Python tiene una biblioteca para cada uno: **openpyxl** y **XlsxWriter** para Excel, **python-docx** para Word y **python-pptx** para PowerPoint.

Ninguna de ellas **es** Office: escriben y leen el XML, pero no calculan fórmulas, no reacomodan texto ni dibujan nada. Esta sección mide las dos de Excel con
100.000 filas y muestra las dos trampas que más tiempo cuestan: la fórmula que nadie calculó y el marcador de plantilla partido en pedazos.

---

## 🧠 2. El modelo

| Biblioteca | Lee | Escribe | Lo que la distingue | El equivalente en Java |
|---|---|---|---|---|
| **openpyxl** | Sí | Sí | Modificar archivos existentes | Apache POI (XSSF) |
| **XlsxWriter** | **No** | Sí | Más rápida; memoria constante; gráficos y formatos completos | POI SXSSF |
| **python-docx** | Sí | Sí | Párrafos, *runs*, tablas, estilos | POI XWPF, docx4j |
| **python-pptx** | Sí | Sí | Diapositivas, formas, **gráficos nativos** editables | POI XSLF |

### 🩻 Esto sí funciona igual

Es Apache POI: el mismo modelo de libro, hoja y celda; de párrafo y *run*. Las trampas también son las mismas: POI tampoco calcula fórmulas al escribir sin
`FormulaEvaluator`, y los *runs* de Word parten el texto igual en Java que en Python.

---

## 💻 3. El ejemplo que corre

`office.py`:

```python
''' + code + '''
```

```bash
pip install openpyxl XlsxWriter python-docx python-pptx
python3 office.py
```

Salida (Python 3.14.7, 05/10/2026) (los segundos son de la máquina que corre):

```text
openpyxl    1.50 s · memoria máx.   102 MB · 1.7 MB
XlsxWriter  1.02 s · memoria máx.     1 MB · 1.7 MB
la celda del total: '=SUM(C2:C100001)' · con data_only=True: None
reemplazo run por run: 'Informe de la sede {{sede}}' · runs: ['Informe de la sede ', '{{se', 'de}}']
muestra.pptx 34 KB con un gráfico nativo
```

Con 100.000 filas, XlsxWriter en modo `constant_memory` tarda un tercio menos y usa **1 MB** de memoria contra **102** de openpyxl, que guarda todo el libro antes
de escribirlo. El archivo es el mismo. La fórmula del total se lee como texto, `'=SUM(C2:C100001)'`; con `data_only=True` la respuesta es **`None`**, porque el valor
calculado solo existe si Excel abrió y guardó el archivo. Y el marcador `{{sede}}` no se reemplazó: está partido en dos *runs* (`{{se` y `de}}`) porque media palabra
está en negrita, y ningún *run* contiene el marcador completo.

**Detalles con intención**

- **`constant_memory`** escribe cada fila al disco en cuanto se pasa a la siguiente: no se puede volver atrás a una fila ya escrita. Es el precio de 1 MB.
- **`data_only=True`** lee el valor en caché que guardó la última aplicación que calculó. Un archivo generado por Python no tiene caché; uno abierto y guardado en Excel,
  sí.
- **Los *runs*** son tramos de texto con el mismo formato. Una plantilla editada a mano suele partir los marcadores sin que se vea: un corrector ortográfico, un cambio
  de fuente o un "deshacer" bastan.
- **`add_chart`** crea un gráfico nativo de PowerPoint, con sus datos en una hoja incrustada: quien recibe la presentación lo edita como cualquier gráfico.

---

## ⚠️ 4. Lo que se rompe

**El total que sale vacío.** Un sistema que lee con `data_only=True` un Excel generado por otro sistema recibe `None` en cada fórmula. Se calcula en Python y se
escribe el valor, o se recalcula con LibreOffice sin interfaz (`soffice --headless --convert-to xlsx`).

**El marcador partido.** El reemplazo por *run* falla en silencio. Se reemplaza a nivel de párrafo (uniendo los *runs*, perdiendo formato dentro del marcador), o se
usa una biblioteca de plantillas como `docxtpl`, que usa Jinja sobre el XML y repara los marcadores.

**openpyxl con archivos grandes.** 102 MB para 100.000 filas de tres columnas; un reporte de un millón de filas y veinte columnas no cabe. XlsxWriter para escribir,
`read_only=True` de openpyxl para leer.

**Fechas como números.** Excel guarda fechas como días desde 1900 con formato; una celda sin formato muestra 46300 en vez de la fecha.

---

## ⚖️ 5. Cuándo NO usarlas

**Para entregar datos a otro sistema.** CSV o Parquet. Excel es para personas.

**Para documentos de diseño cuidado.** python-docx no maneja bien encabezados complejos ni secciones; una plantilla con `docxtpl` o un PDF desde HTML (`ar04`) se
mantienen mejor.

**Si el archivo tiene macros.** openpyxl las descarta al guardar salvo `keep_vba=True`, y ninguna biblioteca las ejecuta.

---

## 🧪 6. Ejercicios (10)

**🟢 Fácil (1–3)**

1. Corre el ejemplo. **Criterio:** las cinco líneas, y por qué el total es `None`.
2. Escribe el total calculado en Python en vez de la fórmula. **Criterio:** `data_only=True` lo lee.
3. Reemplaza el marcador a nivel de párrafo. **Criterio:** el texto dice "Kennedy", y qué formato se perdió.

**🟡 Intermedio (4–6)**

4. Lee el archivo de 100.000 filas con `read_only=True`. **Criterio:** el tiempo y la memoria contra el modo normal.
5. Haz la plantilla de Word con `docxtpl`. **Criterio:** el marcador partido se reemplaza.
6. Agrega a la hoja de XlsxWriter formato de moneda, una fila fija de encabezado y un filtro automático. **Criterio:** se ven al abrir en Excel o LibreOffice.

**🟠 Difícil (7–9)**

7. Recalcula el libro con LibreOffice sin interfaz y vuelve a leer con `data_only=True`. **Criterio:** el total aparece.
8. Genera la presentación mensual con un gráfico por sede desde un CSV. **Criterio:** una diapositiva por sede, con su gráfico editable.
9. Mide openpyxl y XlsxWriter con un millón de filas. **Criterio:** cuál termina y con cuánta memoria.

**🔴 Muy difícil (10)**

10. Diseña el reporte mensual en Excel de un área no técnica. **Criterio:** una página. *Rúbrica:* (a) la biblioteca y por qué, con números; (b) qué va como fórmula y
    qué como valor; (c) cómo se prueba que el archivo abre bien; (d) qué pasa el mes que crece diez veces.

---

## 📚 7. Referencias

**Documentación oficial**

- openpyxl: https://openpyxl.readthedocs.io/en/stable/
- XlsxWriter, el modo de memoria constante: https://xlsxwriter.readthedocs.io/working_with_memory.html
- python-docx: https://python-docx.readthedocs.io/en/latest/
- python-pptx: https://python-pptx.readthedocs.io/en/latest/

**Orden de lectura sugerido:** la página de memoria de XlsxWriter; después la explicación de *runs* en la documentación de python-docx.

---

## 🚀 8. Cierre

openpyxl, XlsxWriter, python-docx y python-pptx escriben el XML de Office, no son Office: no calculan fórmulas y no ven los marcadores partidos. XlsxWriter escribe
100.000 filas con 1 MB de memoria contra 102 de openpyxl; para leer, openpyxl. Las dos trampas se resuelven igual: saber qué hace el archivo por dentro.

**La señal de que quedó bien:** *"El reporte llega con los totales como valores, las plantillas de Word se llenan con `docxtpl`, y nadie lee `None` donde había una
fórmula."*

> 🏷️ **Cierra la sección con su tag**, cuando los ejercicios que elegiste estén hechos:
>
> ```bash
> git tag -a op-ar-fase-05 -m "op ar05 cerrada: Excel medido, la fórmula sin calcular y el marcador partido"
> ```
>
> Los commits llevan su prefijo (`op ar05: …`) y los de ejercicio su número
> (`op ar05 ej07: …`).
'''
open('op151-ar05-office.md','w').write(doc)
PYEOF
cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516 && python3 plan.py 151 151 ✅ ✅ | tail -1; python3 verificar_urls.py ../../cursos-algoritmos-lenguajes/python-for-java-devs/op151-ar05-office.md | tail -3

# --- 2026-10-05T21:29:10 · Verify docxtpl fixes split placeholder
cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516/salidas/ar05 && timeout 300 docker run --rm --label curso=python-for-java-devs -v "$PWD:/w" -w /tmp python:3.14.7 sh -c 'timeout 200 pip install -q --root-user-action=ignore docxtpl python-docx==1.2.0 >/dev/null 2>&1; pip list 2>/dev/null | grep -i docxtpl; python -c "
from docx import Document
from docxtpl import DocxTemplate
t=Document(); p=t.add_paragraph(\"Informe de la sede \"); p.add_run(\"{{se\"); p.add_run(\"de}}\").bold=True; t.save(\"p.docx\")
d=DocxTemplate(\"p.docx\"); d.render({\"sede\":\"Kennedy\"}); d.save(\"o.docx\")
print(Document(\"o.docx\").paragraphs[0].text)"'

# --- 2026-10-05T21:29:35 · Run ar06 pandoc demo
mkdir -p /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516/salidas/ar06 && cd $_ && cat > conversion.py <<'EOF'
"""pandoc orquestado desde Python: costo por llamada, lo que se pierde en el viaje y el HTML que deja pasar."""

import shutil
import subprocess
import time

import pypandoc
from markdown_it import MarkdownIt

SOURCE = """# Informe de la sede Suba

La franquicia **cumplió** la meta de octubre.

| Sede | Estado |
|---|---|
| Suba | Cumplió |
| Zipaquirá | Pendiente |

Nota al pie de la tabla[^1].

[^1]: Cifras de muestra.

<script>alert("hola")</script>
"""

print("pandoc:", subprocess.run(["pandoc", "--version"], capture_output=True, text=True).stdout.splitlines()[0])


def pandoc(text, *args):
    return subprocess.run(["pandoc", *args], input=text, capture_output=True, text=True, check=True).stdout


# 1) Costo por llamada: el binario contra una biblioteca en el proceso
md = MarkdownIt("commonmark").enable("table")
start = time.perf_counter()
for _ in range(50):
    pandoc(SOURCE, "-f", "markdown", "-t", "html")
per_pandoc = (time.perf_counter() - start) / 50 * 1000
start = time.perf_counter()
for _ in range(50):
    md.render(SOURCE)
per_lib = (time.perf_counter() - start) / 50 * 1000
print(f"Markdown a HTML · pandoc {per_pandoc:5.1f} ms por documento · markdown-it-py {per_lib:5.2f} ms")

# 2) El HTML crudo: pandoc lo deja pasar salvo que se le quite la extensión
html = pandoc(SOURCE, "-f", "markdown", "-t", "html")
safe = pandoc(SOURCE, "-f", "markdown-raw_html", "-t", "html")
print(f"<script> en la salida · por defecto: {'<script>' in html} · con markdown-raw_html: {'<script>' in safe}")

# 3) El viaje de ida y vuelta: Markdown → Word → Markdown
pypandoc.convert_text(SOURCE, "docx", format="markdown", outputfile="informe.docx")
back = pypandoc.convert_file("informe.docx", "gfm")
print("después de pasar por Word:")
print("\n".join("  " + line for line in back.strip().splitlines()))
print("pypandoc usa el mismo binario:", pypandoc.get_pandoc_path() == shutil.which("pandoc"))
EOF
timeout 590 docker run --rm --label curso=python-for-java-devs -v "$PWD:/w" -w /w python:3.14.7 sh -c 'apt-get -qq update >/dev/null 2>&1; apt-get -qq install -y pandoc >/dev/null 2>&1; timeout 300 pip install -q --root-user-action=ignore pypandoc==1.17 markdown-it-py >/dev/null 2>&1; python conversion.py'; rm -f informe.docx

# --- 2026-10-05T21:29:56 · Inspect pypandoc path
timeout 300 docker run --rm --label curso=python-for-java-devs python:3.14.7 sh -c 'apt-get -qq update >/dev/null 2>&1; apt-get -qq install -y pandoc >/dev/null 2>&1; timeout 200 pip install -q --root-user-action=ignore pypandoc==1.17 >/dev/null 2>&1; python -c "
import pypandoc, shutil; print(repr(pypandoc.get_pandoc_path()), shutil.which(\"pandoc\"), pypandoc.get_pandoc_version())"'

# --- 2026-10-05T21:30:16 · Rerun ar06 final
python3 - <<'EOF'
p='conversion.py'; s=open(p).read()
a='''print("pypandoc usa el mismo binario:", pypandoc.get_pandoc_path() == shutil.which("pandoc"))'''
b='''print(f"pypandoc llama al binario del sistema: {pypandoc.get_pandoc_path()!r} → {shutil.which('pandoc')}, versión {pypandoc.get_pandoc_version()}")'''
assert a in s; s=s.replace(a,b); open(p,'w').write(s)
EOF
timeout 590 docker run --rm --label curso=python-for-java-devs -v "$PWD:/w" -w /w python:3.14.7 sh -c 'apt-get -qq update >/dev/null 2>&1; apt-get -qq install -y pandoc >/dev/null 2>&1; timeout 300 pip install -q --root-user-action=ignore pypandoc==1.17 markdown-it-py >/dev/null 2>&1; pip list 2>/dev/null | grep -i markdown-it; python conversion.py'; rm -f informe.docx

# --- 2026-10-05T21:30:37 · Check inventory and latest pandoc release
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs && grep -n "markdown-it-py\|pypandoc\|docxtpl" prompts/inventario-verificado.md | head; curl -s https://pypi.org/pypi/pandoc/json >/dev/null; curl -s https://api.github.com/repos/jgm/pandoc/releases/latest | python3 -c "import json,sys; print(json.load(sys.stdin)['tag_name'])"

# --- 2026-10-05T21:31:20 · Write ar06, mark, URLs, verifier
python3 - <<'PYEOF'
code=open('/Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516/salidas/ar06/conversion.py').read().rstrip()
doc='''# 🔁 ar06 — Markdown, HTML y pandoc

> Python para desarrolladores Java senior · **Carta** · Track `ar` — Archivos y multimedia ·
> sección 6 de 10
> Se lee suelta: no hace falta ninguna otra sección de la carta.
> Versiones verificadas contra PyPI el 05/10/2026 · Código probado el 05/10/2026 con Python 3.14.7,
> en contenedor: las salidas son las de esa corrida.

---

## 🎯 1. Qué problema resuelve

El informe se escribe en Markdown, pero lo piden en Word; la página se publica en HTML, pero alguien quiere un PDF o un EPUB. **pandoc** es el convertidor universal
de documentos: lee unos cuarenta formatos y escribe más de sesenta, y lo hace mejor que cualquier combinación de bibliotecas de Python. No es de Python —está escrito
en Haskell—, y esa es la pregunta de esta sección y de todo el track: **¿envolver el binario, o llamarlo?**

`pypandoc` es el envoltorio, y resulta ser muy delgado: arma la línea de comandos y llama al mismo binario. La sección mide lo que cuesta cada llamada a pandoc contra
una biblioteca que corre en el proceso, muestra la conversión de ida y vuelta por Word, y la opción por defecto que deja pasar `<script>` de un Markdown a un HTML.

---

## 🧠 2. El modelo

| Tarea | La herramienta | Por qué |
|---|---|---|
| Markdown → HTML, muchas veces por segundo | `markdown-it-py` (en el proceso) | Sin arrancar un programa por documento |
| Markdown ⇄ Word, ODT, EPUB, LaTeX | **pandoc** | Nadie más lo hace con esa calidad |
| Llamar a pandoc desde Python | `subprocess` o `pypandoc` | `pypandoc` arma la línea de comandos; el trabajo es del binario |
| Ajustar la conversión | Filtros de pandoc (Lua, o Python con `panflute`) | Transforman el árbol del documento entre lectura y escritura |

```mermaid
flowchart LR
    MD["Markdown"] --> R["Lector"]
    DOCX["Word"] --> R
    HTML["HTML"] --> R
    R --> AST[("Árbol de pandoc")]
    AST --> F["Filtros<br/>(Lua, panflute)"]
    F --> W["Escritor"]
    W --> O1["HTML"]
    W --> O2["Word"]
    W --> O3["EPUB, PDF, LaTeX…"]
```

### 🩻 Esto sí funciona igual

Es el modelo de un compilador: un lector por formato, una representación intermedia común y un escritor por formato. En Java, Flexmark o Apache Tika siguen la
misma idea en un solo sentido; pandoc la hace en todas las direcciones.

---

## 💻 3. El ejemplo que corre

`conversion.py`:

```python
''' + code + '''
```

```bash
apt-get install pandoc          # el de Debian: 3.1.11.1; la última publicada es la 3.12
pip install pypandoc markdown-it-py
python3 conversion.py
```

Salida (Python 3.14.7, 05/10/2026) (los milisegundos son de la máquina que corre):

```text
pandoc: pandoc 3.1.11.1
Markdown a HTML · pandoc  17.1 ms por documento · markdown-it-py  0.17 ms
<script> en la salida · por defecto: True · con markdown-raw_html: False
después de pasar por Word:
  # Informe de la sede Suba
  
  La franquicia **cumplió** la meta de octubre.
  
  | Sede      | Estado    |
  |-----------|-----------|
  | Suba      | Cumplió   |
  | Zipaquirá | Pendiente |
  
  Nota al pie de la tabla[^1].
  
  [^1]: Cifras de muestra.
pypandoc llama al binario del sistema: 'pandoc' → /usr/bin/pandoc, versión 3.1.11.1
```

Cada llamada a pandoc cuesta **17 ms**; `markdown-it-py`, en el proceso, **0,17**: cien veces menos, porque no arranca un programa. Para convertir un documento, 17 ms
no importan; para renderizar cada comentario de una página, sí. Por defecto pandoc **deja pasar el `<script>`** del Markdown al HTML; quitándole la extensión
`raw_html` al lector, lo descarta. Y el viaje de ida y vuelta por Word conserva el título, la negrita, la tabla y la nota al pie: lo único que se perdió fue el
`<script>`, que Word no puede guardar. `pypandoc`, al final, llama a `pandoc` del `PATH`: el mismo binario, la misma versión.

**Detalles con intención**

- **`-f markdown-raw_html`**: el signo menos le quita una extensión al lector. pandoc tiene decenas (`+smart`, `-raw_html`, `+emoji`), y la conversión segura de texto de
  usuarios empieza por saber cuáles están activas (`pandoc --list-extensions=markdown`).
- **`gfm`** como formato de salida escribe el Markdown de GitHub, con tablas de tubería; `markdown` a secas escribe el dialecto de pandoc.
- **`subprocess.run(..., check=True)`**: si pandoc falla, la excepción trae el código de salida; `stderr` dice por qué (el manejo de errores del camino base, Fase 05).
- **La versión de Debian va atrás** de la publicada (3.1.11.1 contra 3.12). El paquete `pypandoc_binary` trae pandoc adentro, de la versión que fija; en un contenedor,
  conviene decidir cuál y escribirlo.

---

## ⚠️ 4. Lo que se rompe

**El `<script>` que pasa.** Convertir con pandoc el Markdown que escriben los usuarios a HTML sin `-raw_html` ni un sanitizador (`nh3`, del track `tx`) es una
inyección de JavaScript esperando ocurrir.

**pandoc por documento en un bucle caliente.** 17 ms por llamada son 17 segundos por cada mil documentos. Se usa una biblioteca en el proceso, o se juntan los
documentos en una sola llamada.

**La versión que cambia la salida.** Un contenedor que instala "el pandoc de la distribución" cambia de versión al cambiar la imagen base, y la salida HTML o Word
cambia con ella. Se fija la versión.

**El documento de Word con estilos propios.** pandoc escribe con sus estilos por defecto; para usar los de la casa se le pasa `--reference-doc=plantilla.docx`.

---

## ⚖️ 5. Cuándo NO usarlo

**Para Markdown a HTML en una aplicación web.** Una biblioteca en el proceso (`markdown-it-py`, `mistune`) y un sanitizador; pandoc es para documentos.

**Si solo se necesita Word con datos.** `docxtpl` (`ar05`) llena una plantilla con el formato exacto de la casa; pandoc convierte, no maqueta.

**Para PDF con diseño.** pandoc genera PDF pasando por LaTeX o Typst (`ar07`); para controlar el diseño, se escribe directamente en esos.

---

## 🧪 6. Ejercicios (10)

**🟢 Fácil (1–3)**

1. Corre el ejemplo. **Criterio:** las líneas, y por qué pandoc tarda cien veces más que `markdown-it-py`.
2. Convierte `informe.docx` a HTML con pandoc. **Criterio:** la tabla y la nota al pie en el HTML.
3. Lista las extensiones activas del lector `markdown` (`pandoc --list-extensions=markdown`). **Criterio:** las que tienen que ver con HTML crudo.

**🟡 Intermedio (4–6)**

4. Convierte el Markdown a Word con `--reference-doc` y una plantilla con otra fuente y otro color de títulos. **Criterio:** el Word sale con los estilos de la plantilla.
5. Escribe un filtro de pandoc en Lua que ponga en mayúsculas los títulos. **Criterio:** el HTML sale con títulos en mayúsculas.
6. Convierte cincuenta documentos con una sola llamada a pandoc (varias entradas, un separador). **Criterio:** el tiempo total contra cincuenta llamadas.

**🟠 Difícil (7–9)**

7. Escribe el mismo filtro con `panflute` en Python. **Criterio:** funciona igual, y el tiempo contra el de Lua.
8. Sanea la salida HTML de pandoc con `nh3` dejando pasar tablas y notas al pie. **Criterio:** el `<script>` no está y la tabla sí.
9. Fija pandoc 3.12 en un `Dockerfile` (binario oficial o `pypandoc_binary`). **Criterio:** la imagen dice la versión exacta.

**🔴 Muy difícil (10)**

10. Genera un EPUB con tres informes como capítulos (`pandoc -t epub3`), con portada y metadatos, y valídalo con EPUBCheck. **Criterio:** EPUBCheck sin errores.
    *Rúbrica:* (a) la estructura del EPUB por dentro (es un *zip* con XHTML y un OPF); (b) los metadatos (título, autor, idioma); (c) qué se ve distinto en dos lectores;
    (d) qué tuviste que corregir para pasar la validación.

---

## 📚 7. Referencias

**Documentación oficial**

- El manual de pandoc: https://pandoc.org/MANUAL.html
- Filtros de pandoc en Lua: https://pandoc.org/lua-filters.html
- pypandoc: https://github.com/JessicaTegner/pypandoc

**Orden de lectura sugerido:** la sección "Extensions" del manual (qué hace cada `+` y `-`); después la de filtros en Lua.

---

## 🚀 8. Cierre

pandoc es el binario que convierte documentos entre casi todos los formatos, y `pypandoc` es una capa delgada que lo llama. Cuesta 17 ms por llamada contra 0,17 de una
biblioteca en el proceso, deja pasar el HTML crudo salvo que se le diga, y su versión cambia con la imagen base. Para documentos, el binario; para renderizar en caliente,
la biblioteca.

**La señal de que quedó bien:** *"pandoc está fijado en su versión, convierte documentos y no comentarios, y el Markdown de usuarios no llega a HTML sin `-raw_html`."*

> 🏷️ **Cierra la sección con su tag**, cuando los ejercicios que elegiste estén hechos:
>
> ```bash
> git tag -a op-ar-fase-06 -m "op ar06 cerrada: pandoc orquestado, su costo por llamada y el HTML crudo"
> ```
>
> Los commits llevan su prefijo (`op ar06: …`) y los de ejercicio su número
> (`op ar06 ej07: …`).
'''
open('op152-ar06-markdown-html-y-pandoc.md','w').write(doc)
PYEOF
cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516 && python3 plan.py 152 152 ✅ ✅ | tail -1; python3 verificar_urls.py ../../cursos-algoritmos-lenguajes/python-for-java-devs/op152-ar06-markdown-html-y-pandoc.md | tail -3; cd ../../cursos-algoritmos-lenguajes/python-for-java-devs && python3 prompts/verificar-corpus.py 2>&1 | grep -E "op1(4[7-9]|5[0-2])|errores"

# --- 2026-10-05T21:31:41 · Run ar07 Typst vs LaTeX demo
mkdir -p /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516/salidas/ar07 && cd $_ && cat > informe.typ <<'EOF'
// The data arrives as JSON through sys.inputs: no string templating, nothing to escape.
#let rows = json(bytes(sys.inputs.at("rows")))
#set page(paper: "us-letter")
#set text(lang: "es")
= Relación de gastos de muestra · octubre de 2026
#table(
  columns: 3,
  [*Sede*], [*Concepto*], [*Valor*],
  ..rows.map(r => (r.sede, r.concepto, r.valor)).flatten()
)
EOF
cat > documentos.py <<'EOF'
"""El mismo informe con Typst (en el proceso) y con LaTeX (el binario), y el carácter que rompe la plantilla."""

import json
import os
import subprocess
import tempfile
import time

import typst

ROWS = [{"sede": "Kennedy", "concepto": "Arriendo de octubre", "valor": "4.200.000"},
        {"sede": "Engativá", "concepto": "Aseo & mantenimiento", "valor": "1.150.000"},
        {"sede": "Fontibón", "concepto": "Anticipo del 50% · cuenta #12_3", "valor": "780.000"}]

LATEX = r"""\documentclass{article}
\usepackage[T1]{fontenc}
\begin{document}
\section*{Relación de gastos de muestra · octubre de 2026}
\begin{tabular}{lll}
Sede & Concepto & Valor \\ \hline
%s
\end{tabular}
\end{document}
"""


def latex_pdf(rows, escape):
    def clean(text):
        if not escape:
            return text
        for char, repl in (("\\", r"\textbackslash{}"), ("&", r"\&"), ("%", r"\%"), ("$", r"\$"), ("#", r"\#"), ("_", r"\_"),
                           ("{", r"\{"), ("}", r"\}"), ("~", r"\textasciitilde{}"), ("^", r"\textasciicircum{}")):
            text = text.replace(char, repl)
        return text
    body = "\n".join(" & ".join(clean(r[k]) for k in ("sede", "concepto", "valor")) + r" \\" for r in rows)
    with tempfile.TemporaryDirectory() as tmp:
        with open(f"{tmp}/informe.tex", "w", encoding="utf-8") as f:
            f.write(LATEX % body)
        run = subprocess.run(["pdflatex", "-interaction=nonstopmode", "-halt-on-error", "informe.tex"], cwd=tmp,
                             capture_output=True, text=True)
        error = next((l for l in run.stdout.splitlines() if l.startswith("!")), None)
        return (os.path.getsize(f"{tmp}/informe.pdf") if run.returncode == 0 else None), error


start = time.perf_counter()
pdf = typst.compile("informe.typ", sys_inputs={"rows": json.dumps(ROWS)})
print(f"Typst (en el proceso)       {(time.perf_counter() - start) * 1000:6.0f} ms · {len(pdf):,} bytes")

start = time.perf_counter()
size, error = latex_pdf(ROWS, escape=False)
print(f"LaTeX sin escapar           {(time.perf_counter() - start) * 1000:6.0f} ms · falla: {error}")
start = time.perf_counter()
size, error = latex_pdf(ROWS, escape=True)
print(f"LaTeX escapando             {(time.perf_counter() - start) * 1000:6.0f} ms · {size:,} bytes")
EOF
timeout 590 docker run --rm --label curso=python-for-java-devs -v "$PWD:/w" -w /w python:3.14.7 sh -c 'apt-get -qq update >/dev/null 2>&1; s=$(date +%s); apt-get -qq install -y --no-install-recommends texlive-latex-base texlive-fonts-recommended >/dev/null 2>&1; echo "texlive instalado en $(( $(date +%s) - s )) s"; du -sh /usr/share/texlive /usr/share/texmf /var/lib/texmf 2>/dev/null | awk "{print \$1}" | paste -sd+ ; pdflatex --version | head -1; timeout 200 pip install -q --root-user-action=ignore typst==0.15.0 >/dev/null 2>&1; du -sh /usr/local/lib/python3.14/site-packages/typst* | head -2; python documentos.py'

# --- 2026-10-05T21:33:08 · Write ar07 doc; check backslash rendering
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs && python3 - <<'PYEOF'
z='/Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516/salidas/ar07/'
typ=open(z+'informe.typ').read().rstrip(); code=open(z+'documentos.py').read().rstrip()
doc='''# 📐 ar07 — LaTeX y Typst

> Python para desarrolladores Java senior · **Carta** · Track `ar` — Archivos y multimedia ·
> sección 7 de 10
> Se lee suelta: no hace falta ninguna otra sección de la carta.
> Versiones verificadas contra PyPI el 05/10/2026 · Código probado el 05/10/2026 con Python 3.14.7,
> en contenedor: las salidas son las de esa corrida.

---

## 🎯 1. Qué problema resuelve

Cuando el PDF tiene que verse bien —un certificado, un informe con tablas, un documento con fórmulas—, ReportLab (`ar04`) se queda corto y HTML con CSS no controla
la página. Los sistemas de composición tipográfica sí: **LaTeX**, el estándar académico de hace cuarenta años, y **Typst**, el que nació en 2023 con la misma idea, una
sintaxis legible y un compilador en Rust. Typst tiene además una ventaja para este curso: se instala con `pip install typst` y **compila dentro del proceso de
Python**, sin binarios aparte.

La sección compila el mismo informe con los dos y mide tiempo e instalación, pero el hallazgo importante es otro: llenar una plantilla de LaTeX con datos reales se
rompe con el primer `&` o `%` que trae un concepto de gasto. Y Typst permite no llenar plantillas con texto en absoluto: los datos entran como JSON.

---

## 🧠 2. El modelo

| | LaTeX (`pdflatex`) | Typst (`typst` de PyPI) |
|---|---|---|
| Se instala | TeX Live del sistema (aquí ~96 MB lo mínimo; completo, varios GB) | `pip install typst` (75 MB, con el compilador adentro) |
| Se llama | `subprocess`, con archivos temporales | `typst.compile()`, en el proceso |
| Datos desde Python | Texto interpolado en la plantilla, **escapando** | `sys_inputs`: el documento lee JSON |
| Caracteres especiales | `& % $ # _ { } ~ ^ \\` | `# $ * _ @` y otros, si se interpola texto |
| Errores | Mensajes famosamente crípticos | Mensajes con línea y explicación |
| Ecosistema | Enorme: plantillas de revistas, paquetes para todo | Joven, creciendo rápido |

### 🪞 Tu instinto de Java dice… y esta vez se equivoca

El instinto de quien llena plantillas (JSP, Thymeleaf, Jasper) es que el motor escapa por uno: en HTML, Thymeleaf convierte `<` en `&lt;` solo. Una plantilla de LaTeX
armada con `%` de Python o con Jinja **no escapa nada**, porque esos motores no saben que la salida es LaTeX. Es el mismo error que la inyección de SQL, con un
compilador de documentos del otro lado.

---

## 💻 3. El ejemplo que corre

`informe.typ`:

```typst
''' + typ + '''
```

`documentos.py`:

```python
''' + code + '''
```

```bash
apt-get install --no-install-recommends texlive-latex-base texlive-fonts-recommended   # 38 s en el contenedor
pip install typst
python3 documentos.py
```

Salida (Python 3.14.7, 05/10/2026) (los milisegundos son de la máquina que corre):

```text
Typst (en el proceso)           18 ms · 17,914 bytes
LaTeX sin escapar               45 ms · falla: ! Extra alignment tab has been changed to \\cr.
LaTeX escapando                656 ms · 20,399 bytes
```

Typst compila el informe en **18 ms**, dentro del proceso. LaTeX, la primera vez sin escapar, **falla**: el `&` de "Aseo & mantenimiento" es el separador de columnas de
una tabla de LaTeX, y la fila quedó con una columna de más; el `%` de "50%" habría comentado el resto de la línea, y `#` y `_` también son especiales. Escapando los diez
caracteres, compila en **656 ms**, 36 veces lo de Typst, porque arranca `pdflatex`, carga sus formatos y fuentes y escribe archivos auxiliares. Typst no escapó nada:
los datos entraron como JSON y el documento los leyó como datos, no como código.

**Detalles con intención**

- **`sys_inputs`** pasa cadenas al documento, que las lee con `sys.inputs`; `json(bytes(...))` las convierte en arreglos y diccionarios de Typst. Es una consulta
  parametrizada, no una concatenación.
- **El orden de los reemplazos** en `clean` importa: la barra invertida va primero, o se escaparían las barras que agregan los demás reemplazos.
- **`-interaction=nonstopmode -halt-on-error`**: sin esas opciones, `pdflatex` se detiene a preguntar en la terminal ante un error, y el `subprocess` se queda colgado.
- **El directorio temporal**: `pdflatex` deja `.aux` y `.log` junto al `.tex`; sin un directorio propio por compilación, dos compilaciones en paralelo se pisan.

---

## ⚠️ 4. Lo que se rompe

**El dato que trae un carácter especial.** El primer concepto con `&`, `%` o `_` rompe el PDF de LaTeX, o peor: con `\\input` o `\\write18` en los datos, alguien lee o
ejecuta en el servidor. Se escapa siempre, o se usa un paquete que lo haga (`pylatex` escapa al construir el documento).

**El `pdflatex` que espera en silencio.** Sin `nonstopmode`, un error deja el proceso esperando una tecla. Se usa `-halt-on-error` y un `timeout=` en el
`subprocess`.

**Interpolar texto en Typst.** `sys_inputs` evita el problema; armar el `.typ` con f-strings lo trae de vuelta: `#` y `$` son especiales en Typst también.

**Las fuentes.** Un documento que usa una fuente instalada en el portátil compila distinto en el contenedor. Typst trae las suyas y acepta `font_paths=`; LaTeX
depende de los paquetes del sistema.

---

## ⚖️ 5. Cuándo NO usarlos

**Para un PDF simple de una tabla.** ReportLab (`ar04`) o HTML con WeasyPrint, sin otro lenguaje que aprender.

**Typst si el documento va a una revista que exige LaTeX.** El ecosistema de plantillas académicas sigue siendo de LaTeX.

**LaTeX para generar miles de documentos por hora.** 656 ms por documento, más los archivos temporales; Typst, en el proceso, cuesta 36 veces menos.

---

## 🧪 6. Ejercicios (10)

**🟢 Fácil (1–3)**

1. Corre el ejemplo. **Criterio:** las tres líneas, y qué carácter rompió LaTeX primero.
2. Agrega a Typst una fila con `#`, `$` y `*` en el concepto. **Criterio:** el PDF los muestra tal cual, sin escapar nada.
3. Pon un pie de página con el número de página en el `.typ`. **Criterio:** "Página 1 de 1".

**🟡 Intermedio (4–6)**

4. Arma el `.typ` con una f-string en vez de `sys_inputs` y la misma fila. **Criterio:** el error de Typst y cómo se ve.
5. Genera el informe con `pylatex` en lugar de la plantilla de texto. **Criterio:** compila con la fila especial, sin escape manual.
6. Compila cien informes con Typst y con LaTeX. **Criterio:** el tiempo total de cada uno.

**🟠 Difícil (7–9)**

7. Agrega una fórmula (`$sum_(i=1)^n v_i$` en Typst, `\\sum` en LaTeX) y un gráfico en SVG. **Criterio:** los dos PDF los muestran.
8. Arma un `Dockerfile` para cada uno y compara el tamaño de las imágenes. **Criterio:** los dos tamaños.
9. Pon un `timeout=` en el `subprocess` de LaTeX y un documento que entre en un bucle (`\\loop`). **Criterio:** el proceso termina con un error claro.

**🔴 Muy difícil (10)**

10. Decide cómo se generan los certificados de un sistema (miles al mes, con logo, firma y tabla). **Criterio:** una página. *Rúbrica:* (a) LaTeX, Typst, ReportLab o HTML,
    con números; (b) cómo entran los datos sin inyección; (c) fuentes y reproducibilidad en el contenedor; (d) cómo se firma después (`ar04`).

---

## 📚 7. Referencias

**Documentación oficial**

- Typst: https://typst.app/docs/
- `typst` para Python: https://github.com/messense/typst-py
- LaTeX, el proyecto: https://www.latex-project.org/help/documentation/

**Libros**

- Leslie Lamport, *LaTeX: A Document Preparation System* (2.ª ed., Addison-Wesley, 1994): el libro de quien lo creó.

**Orden de lectura sugerido:** el tutorial de Typst (una hora); después la referencia de `sys.inputs` y `json`.

---

## 🚀 8. Cierre

Typst y LaTeX componen PDF de calidad tipográfica. Typst compila en el proceso en 18 ms, con datos que entran como JSON y no necesitan escaparse; LaTeX tarda 656 ms,
arranca un binario y se rompe con el primer `&` de los datos si no se escapan diez caracteres. LaTeX gana en ecosistema; Typst, en todo lo demás que se midió aquí.

**La señal de que quedó bien:** *"Ningún dato entra a un documento como texto interpolado: en Typst por `sys_inputs`, en LaTeX escapado por una función con pruebas."*

> 🏷️ **Cierra la sección con su tag**, cuando los ejercicios que elegiste estén hechos:
>
> ```bash
> git tag -a op-ar-fase-07 -m "op ar07 cerrada: Typst en el proceso, LaTeX escapado, los dos medidos"
> ```
>
> Los commits llevan su prefijo (`op ar07: …`) y los de ejercicio su número
> (`op ar07 ej07: …`).
'''
open('op153-ar07-latex-y-typst.md','w').write(doc)
PYEOF
grep -n 'changed to' op153-ar07-latex-y-typst.md; grep -n 'input` o' op153-ar07-latex-y-typst.md

# --- 2026-10-05T21:33:17 · Fix write18 claim, mark ar07, URLs, verifier
python3 - <<'EOF'
p='/Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs/op153-ar07-latex-y-typst.md'; s=open(p).read()
a="o peor: con `\\input` o `\\write18` en los datos, alguien lee o\nejecuta en el servidor."
assert a in s, "x"
s=s.replace(a,"o peor: un `\\input{/etc/passwd}` en los datos mete un archivo del\nservidor en el PDF, y `\\write18` ejecuta comandos si alguien habilitó `--shell-escape`.")
open(p,'w').write(s)
EOF
cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516 && python3 plan.py 153 153 ✅ ✅ | tail -1; python3 verificar_urls.py ../../cursos-algoritmos-lenguajes/python-for-java-devs/op153-ar07-latex-y-typst.md | tail -3; cd ../../cursos-algoritmos-lenguajes/python-for-java-devs && python3 prompts/verificar-corpus.py 2>&1 | grep -E "op153|errores"

# --- 2026-10-05T21:33:37 · Run ar08 video demo
mkdir -p /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516/salidas/ar08 && cd $_ && cat > video.py <<'EOF'
"""Vídeo: el binario de ffmpeg contra PyAV y MoviePy en el mismo trabajo, y el corte que no cae donde se pidió."""

import json
import subprocess
import time

import av
from moviepy import VideoFileClip


def ffmpeg(*args):
    subprocess.run(["ffmpeg", "-hide_banner", "-loglevel", "error", "-y", *args], check=True)


def duration_and_first_frame(path):
    probe = json.loads(subprocess.run(["ffprobe", "-v", "error", "-show_entries", "format=duration:stream=start_time",
                                       "-of", "json", path], capture_output=True, text=True).stdout)
    return float(probe["format"]["duration"])


def timed(fn):
    start = time.perf_counter(); fn(); return (time.perf_counter() - start) * 1000


# Un vídeo de muestra: 20 s de patrón de prueba, 1280×720 a 25 cuadros, un keyframe cada 4 s
ffmpeg("-f", "lavfi", "-i", "testsrc2=size=1280x720:rate=25:duration=20", "-c:v", "libx264", "-g", "100",
       "-pix_fmt", "yuv420p", "muestra.mp4")

# 1) Un cuadro por segundo como JPEG: el binario contra PyAV
ms_bin = timed(lambda: ffmpeg("-i", "muestra.mp4", "-vf", "fps=1", "cuadro_%02d.jpg"))


def frames_with_pyav():
    with av.open("muestra.mp4") as container:
        stream = container.streams.video[0]
        next_second = 0.0
        for frame in container.decode(stream):
            if frame.time >= next_second:
                frame.to_image().save(f"pyav_{int(next_second):02d}.jpg")
                next_second += 1


ms_av = timed(frames_with_pyav)
print(f"20 cuadros a JPEG · ffmpeg {ms_bin:5.0f} ms · PyAV {ms_av:5.0f} ms")

# 2) Cortar de 5 s a 10 s: copiar sin recodificar contra recodificar
ms_copy = timed(lambda: ffmpeg("-ss", "5", "-i", "muestra.mp4", "-t", "5", "-c", "copy", "corte_copia.mp4"))
ms_enc = timed(lambda: ffmpeg("-ss", "5", "-i", "muestra.mp4", "-t", "5", "-c:v", "libx264", "corte_recodificado.mp4"))
for name, path, ms in (("copia", "corte_copia.mp4", ms_copy), ("recodificado", "corte_recodificado.mp4", ms_enc)):
    with av.open(path) as c:
        first = next(c.decode(video=0))
        print(f"corte {name:<12} {ms:5.0f} ms · duración {duration_and_first_frame(path):5.2f} s · primer cuadro mostrado en t={first.time:.2f}")

# 3) MoviePy: el mismo corte, declarativo
clip = VideoFileClip("muestra.mp4")
ms_mp = timed(lambda: clip.subclipped(5, 10).write_videofile("corte_moviepy.mp4", codec="libx264", logger=None))
clip.close()
print(f"corte con MoviePy   {ms_mp:5.0f} ms · duración {duration_and_first_frame('corte_moviepy.mp4'):5.2f} s")
EOF
timeout 590 docker run --rm --label curso=python-for-java-devs -v "$PWD:/w" -w /w python:3.14.7 sh -c 'apt-get -qq update >/dev/null 2>&1; apt-get -qq install -y ffmpeg >/dev/null 2>&1; ffmpeg -version | head -1; timeout 300 pip install -q --root-user-action=ignore av==19.0.1 moviepy==2.2.1 >/dev/null 2>&1; pip list 2>/dev/null | grep -iE "^(av|moviepy|imageio-ffmpeg) "; python video.py; ls | head -3'

# --- 2026-10-05T21:34:48 · Identify which source frame starts each cut
cat > keyframe.py <<'EOF'
import av, numpy as np
def frames(path):
    with av.open(path) as c:
        return [(f.time, f.to_ndarray(format="gray")) for f in c.decode(video=0)]
src = dict((round(t, 2), a) for t, a in frames("muestra.mp4"))
for path in ("corte_copia.mp4", "corte_recodificado.mp4", "corte_moviepy.mp4"):
    fs = frames(path)
    first = fs[0][1].astype(int)
    match = min(src, key=lambda t: np.abs(src[t].astype(int) - first).mean())
    print(path, len(fs), "cuadros; el primero es el del segundo", match, "del original; tiempos", fs[0][0], fs[-1][0])
EOF
timeout 300 docker run --rm --label curso=python-for-java-devs -v "$PWD:/w" -w /w python:3.14.7 sh -c 'timeout 200 pip install -q --root-user-action=ignore av==19.0.1 numpy==2.5.3 >/dev/null 2>&1; python keyframe.py'

# --- 2026-10-05T21:35:14 · List keyframe timestamps
timeout 300 docker run --rm --label curso=python-for-java-devs -v "$PWD:/w" -w /w python:3.14.7 sh -c 'timeout 200 pip install -q --root-user-action=ignore av==19.0.1 >/dev/null 2>&1; python -c "
import av
for p in (\"muestra.mp4\", \"corte_copia.mp4\"):
    with av.open(p) as c:
        s=c.streams.video[0]
        print(p, [round(float(pk.pts*s.time_base),2) for pk in c.demux(s) if pk.is_keyframe and pk.pts is not None])"'

# --- 2026-10-05T21:35:33 · Rerun ar08 with hidden-frames count
python3 - <<'EOF'
p='video.py'; s=open(p).read()
a='''for name, path, ms in (("copia", "corte_copia.mp4", ms_copy), ("recodificado", "corte_recodificado.mp4", ms_enc)):
    with av.open(path) as c:
        first = next(c.decode(video=0))
        print(f"corte {name:<12} {ms:5.0f} ms · duración {duration_and_first_frame(path):5.2f} s · primer cuadro mostrado en t={first.time:.2f}")'''
b='''for name, path, ms in (("copia", "corte_copia.mp4", ms_copy), ("recodificado", "corte_recodificado.mp4", ms_enc)):
    with av.open(path) as c:
        stream = c.streams.video[0]
        packets = [p for p in c.demux(stream) if p.pts is not None]
        hidden = sum(p.pts * stream.time_base < 0 for p in packets)
        print(f"corte {name:<12} {ms:5.0f} ms · duración {duration(path):5.2f} s · cuadros guardados {len(packets)}"
              f" · antes de t=0, escondidos: {hidden}")'''
assert a in s; s=s.replace(a,b)
s=s.replace('''def duration_and_first_frame(path):
    probe = json.loads(subprocess.run(["ffprobe", "-v", "error", "-show_entries", "format=duration:stream=start_time",
                                       "-of", "json", path], capture_output=True, text=True).stdout)''','''def duration(path):
    probe = json.loads(subprocess.run(["ffprobe", "-v", "error", "-show_entries", "format=duration", "-of", "json", path],
                                      capture_output=True, text=True).stdout)''')
s=s.replace("duration_and_first_frame('corte_moviepy.mp4')","duration('corte_moviepy.mp4')")
open(p,'w').write(s)
EOF
grep -n "duration" video.py | head; rm -f *.mp4 *.jpg keyframe.py; timeout 590 docker run --rm --label curso=python-for-java-devs -v "$PWD:/w" -w /w python:3.14.7 sh -c 'apt-get -qq update >/dev/null 2>&1; apt-get -qq install -y ffmpeg >/dev/null 2>&1; timeout 300 pip install -q --root-user-action=ignore av==19.0.1 moviepy==2.2.1 >/dev/null 2>&1; python video.py'; rm -f *.mp4 *.jpg

# --- 2026-10-05T21:37:13 · Write ar08, mark, URLs
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs && python3 - <<'PYEOF'
code=open('/Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516/salidas/ar08/video.py').read().rstrip()
doc='''# 🎬 ar08 — Vídeo

> Python para desarrolladores Java senior · **Carta** · Track `ar` — Archivos y multimedia ·
> sección 8 de 10
> Se lee suelta: no hace falta ninguna otra sección de la carta.
> Versiones verificadas contra PyPI el 05/10/2026 · Código probado el 05/10/2026 con Python 3.14.7,
> en contenedor: las salidas son las de esa corrida.

---

## 🎯 1. Qué problema resuelve

Casi todo el vídeo del mundo pasa por **FFmpeg**, una colección de bibliotecas en C y un binario con una línea de comandos enorme. Desde Python hay tres formas de usarlo:
**llamar al binario** con `subprocess` (lo que el camino base enseñó en la Fase 05), **PyAV**, un enlace real a las bibliotecas de FFmpeg que entrega cuadro por cuadro,
y **MoviePy**, una capa declarativa para editar ("corta de 5 a 10, pon un título encima") que por debajo también usa FFmpeg.

Esta sección se escribe alrededor de una decisión, no de una biblioteca: **envolver el binario o llamarlo**. Mide las tres rutas con dos trabajos de todos los días
—sacar un cuadro por segundo y cortar un tramo— sobre un vídeo de prueba generado por FFmpeg, y muestra lo que hace un corte "sin recodificar" que nadie mira.

---

## 🧠 2. El modelo

| Ruta | Qué es | Cuándo gana |
|---|---|---|
| **`ffmpeg` por `subprocess`** | El binario, con sus opciones | Todo lo que la línea de comandos ya hace: convertir, cortar, extraer, escalar |
| **PyAV** (`av`) | Enlace a `libavformat` y `libavcodec` | Cuando hay que tocar **cada cuadro** en Python: analizar, filtrar con NumPy, decidir |
| **MoviePy** | Edición declarativa sobre FFmpeg | Montajes: concatenar, superponer texto, transiciones |

| Corte | Qué hace | Costo |
|---|---|---|
| `-c copy` | Copia los paquetes comprimidos, sin decodificar | Rapidísimo; solo puede empezar en un *keyframe* |
| Recodificar | Decodifica y vuelve a comprimir | Lento; empieza exactamente donde se pidió |

### 🪞 Tu instinto de Java dice… y esta vez se equivoca

El instinto de Java es buscar la biblioteca: JavaCV, Xuggler, JCodec. Para vídeo, la biblioteca que envuelve FFmpeg siempre va atrás de FFmpeg, y su superficie es
una fracción de la del binario. Xuggler está abandonado desde 2013. En Python pasa igual: los envoltorios que no tienen financiamiento se quedan atrás, y la ruta que
no se rompe es llamar al binario. La biblioteca se justifica solo cuando hay que entrar al cuadro.

---

## 💻 3. El ejemplo que corre

`video.py`:

```python
''' + code + '''
```

```bash
apt-get install ffmpeg          # FFmpeg 7.1.5 de Debian en el contenedor
pip install av moviepy
python3 video.py
```

Salida (Python 3.14.7, 05/10/2026) (los milisegundos son de la máquina que corre):

```text
20 cuadros a JPEG · ffmpeg   333 ms · PyAV  1353 ms
corte copia           62 ms · duración  5.08 s · cuadros guardados 152 · antes de t=0, escondidos: 25
corte recodificado   659 ms · duración  5.00 s · cuadros guardados 125 · antes de t=0, escondidos: 0
corte con MoviePy    1068 ms · duración  5.00 s
```

Sacar un cuadro por segundo cuesta **333 ms con el binario y 1.353 con PyAV**: el bucle de PyAV decodifica los 500 cuadros, convierte a imagen de Pillow y guarda,
pasando por Python en cada uno; el filtro `fps=1` de FFmpeg hace todo en C. Cortar copiando tarda **62 ms**, diez veces menos que recodificando, y dura 5,08 s; pero
guarda **152 cuadros, 25 de ellos escondidos antes de t=0**: el corte tuvo que empezar en el *keyframe* de los 4 segundos, y FFmpeg marcó el segundo sobrante para que
el reproductor no lo muestre. El archivo lo lleva. Recodificar da 125 cuadros exactos. MoviePy hace el mismo corte en 1.068 ms, con una línea.

**Detalles con intención**

- **`-g 100`** pone un *keyframe* cada 100 cuadros (4 s a 25 cuadros por segundo): es lo que hace visible el problema. Las cámaras y los teléfonos usan intervalos de
  uno a diez segundos.
- **`-ss` antes de `-i`** busca en la entrada (rápido, al *keyframe* anterior); después de `-i`, decodifica desde el principio hasta el punto pedido.
- **Los 25 cuadros escondidos** tienen marcas de tiempo negativas y una lista de edición que dice "empezar en 0". Un reproductor que la respeta no los muestra; una
  herramienta que no la respeta, o un editor que concatena archivos, sí.
- **`check=True`** y `-loglevel error`: FFmpeg escribe mucho en `stderr` aunque todo salga bien; así solo aparecen los errores, y un código de salida distinto de cero
  se vuelve una excepción.

---

## ⚠️ 4. Lo que se rompe

**El corte con `-c copy` que trae lo que no se pidió.** Para un recorte que va a publicarse o a concatenarse, se recodifica, o al menos se recodifica el tramo hasta el
primer *keyframe* (*smart cut*).

**El envoltorio abandonado.** `ffmpeg-python` no publica una versión desde 2019; `decord`, desde 2021. Funcionan hasta que FFmpeg cambia una opción. Se arma la línea de
comandos a mano, en una función con pruebas.

**El binario de otra versión.** El contenedor trae FFmpeg 7.1.5 de Debian; `imageio-ffmpeg` (que usa MoviePy) trae **su propio** binario. Dos versiones distintas en el
mismo proyecto dan resultados distintos.

**Los nombres de archivo que vienen de usuarios.** `subprocess` con lista de argumentos, nunca con `shell=True`; y un nombre que empieza con `-` se interpreta como opción:
se antepone `./` o `file:`.

---

## ⚖️ 5. Cuándo NO usar cada una

**PyAV para lo que el binario ya hace.** Cuatro veces más lento en este trabajo; se usa cuando el cuadro tiene que pasar por código propio.

**MoviePy en un servicio con volumen.** Es para montajes; para convertir mil vídeos, el binario.

**`-c copy` para cortes exactos.** Rápido y casi exacto; "casi" incluye un segundo escondido.

---

## 🧪 6. Ejercicios (10)

**🟢 Fácil (1–3)**

1. Corre el ejemplo. **Criterio:** las cuatro líneas, y de dónde salen los 25 cuadros escondidos.
2. Genera el vídeo con `-g 25` y repite el corte con copia. **Criterio:** cuántos cuadros escondidos quedan ahora.
3. Haz con `subprocess` una miniatura del cuadro del segundo 7. **Criterio:** un JPEG del cuadro correcto.

**🟡 Intermedio (4–6)**

4. Une dos cortes con copia (`concat`) y mira el resultado en un reproductor. **Criterio:** si aparece el segundo escondido en la unión.
5. Con PyAV, calcula el brillo medio de cada cuadro con NumPy. **Criterio:** la serie de 500 valores, y el tiempo.
6. Convierte el vídeo a 480p en H.265 y en AV1. **Criterio:** tamaño y tiempo de cada uno.

**🟠 Difícil (7–9)**

7. Escribe una función `cut(path, start, end, exact)` que copie si `start` cae en un *keyframe* y recodifique si no. **Criterio:** las pruebas de los dos casos.
8. Haz con MoviePy un video desde 20 imágenes con un título superpuesto. **Criterio:** el vídeo, y la misma tarea con el binario para comparar.
9. Compara la versión de FFmpeg de Debian con la de `imageio-ffmpeg`. **Criterio:** las dos versiones y una opción que se comporte distinto.

**🔴 Muy difícil (10)**

10. Diseña el procesamiento de los vídeos que suben los usuarios de un sistema. **Criterio:** una página. *Rúbrica:* (a) qué se hace con el binario y qué con PyAV, y por
    qué; (b) cómo se fija la versión de FFmpeg; (c) cómo se validan los nombres y formatos de entrada; (d) los tiempos medidos para un vídeo típico.

---

## 📚 7. Referencias

**Documentación oficial**

- FFmpeg: https://ffmpeg.org/ffmpeg.html
- PyAV: https://pyav.basswood-io.com/docs/stable/
- MoviePy: https://zulko.github.io/moviepy/

**Orden de lectura sugerido:** la sección de `-ss` en la documentación de FFmpeg (buscar en la entrada o en la salida); después la introducción de PyAV.

---

## 🚀 8. Cierre

Para vídeo, la ruta que no se rompe es llamar al binario de FFmpeg: hace en 333 ms lo que PyAV en 1.353. PyAV se justifica cuando el cuadro tiene que pasar por código
propio, y MoviePy cuando la tarea es un montaje. Y el corte sin recodificar, diez veces más rápido, guarda un segundo que no se pidió escondido antes de t=0.

**La señal de que quedó bien:** *"FFmpeg está fijado en una versión, se llama con una lista de argumentos, y los cortes que se publican se recodifican."*

> 🏷️ **Cierra la sección con su tag**, cuando los ejercicios que elegiste estén hechos:
>
> ```bash
> git tag -a op-ar-fase-08 -m "op ar08 cerrada: el binario contra PyAV y MoviePy, y el segundo escondido"
> ```
>
> Los commits llevan su prefijo (`op ar08: …`) y los de ejercicio su número
> (`op ar08 ej07: …`).
'''
open('op154-ar08-video.md','w').write(doc)
PYEOF
cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516 && python3 plan.py 154 154 ✅ ✅ | tail -1; python3 verificar_urls.py ../../cursos-algoritmos-lenguajes/python-for-java-devs/op154-ar08-video.md | tail -3

# --- 2026-10-05T21:37:20 · Hedge Xuggler claim
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs && sed -i '' 's/Xuggler está abandonado desde 2013\./Xuggler no publica una versión desde hace más de diez años./' op154-ar08-video.md && grep -c "más de diez años" op154-ar08-video.md

# --- 2026-10-05T21:37:27 · Test pydub import on 3.14
timeout 300 docker run --rm --label curso=python-for-java-devs python:3.14.7 sh -c 'timeout 200 pip install -q --root-user-action=ignore pydub==0.25.1 >/dev/null 2>&1; python -c "import pydub" 2>&1 | tail -1; curl -s https://pypi.org/pypi/audioop-lts/json | python -c "import json,sys; d=json.load(sys.stdin); print(d[\"info\"][\"version\"], max(f[\"upload_time\"] for r in d[\"releases\"].values() for f in r))"'

# --- 2026-10-05T21:37:51 · Run ar09 audio demo
mkdir -p /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516/salidas/ar09 && cd $_ && cat > audio.py <<'EOF'
"""Audio: escribir y comprimir, medir el tono con librosa, procesar con pedalboard y pydub, y etiquetar con mutagen."""

import os
import subprocess
import time

import librosa
import mutagen
import numpy as np
import soundfile as sf
from pedalboard import Compressor, Gain, Pedalboard, Reverb
from pydub import AudioSegment, effects

RATE, SECONDS = 44_100, 10
t = np.arange(RATE * SECONDS) / RATE
tone = 0.1 * np.sin(2 * np.pi * 440 * t) + 0.01 * np.random.default_rng(1).standard_normal(t.size)   # La 440 con ruido
stereo = np.column_stack([tone, tone]).astype(np.float32)

# 1) Formatos: el mismo audio sin comprimir, sin pérdida y con pérdida
sf.write("muestra.wav", stereo, RATE, subtype="PCM_16")
sf.write("muestra.flac", stereo, RATE)
for codec, out in (("libmp3lame", "muestra.mp3"), ("libopus", "muestra.opus")):
    subprocess.run(["ffmpeg", "-loglevel", "error", "-y", "-i", "muestra.wav", "-c:a", codec, "-b:a", "128k", out], check=True)
print(" · ".join(f"{f.split('.')[1]} {os.path.getsize(f) / 1024:,.0f} KB" for f in
                 ("muestra.wav", "muestra.flac", "muestra.mp3", "muestra.opus")))

# 2) librosa: qué nota es
y, sr = librosa.load("muestra.flac", sr=None, mono=True)
f0, voiced, _ = librosa.pyin(y[: sr * 2], fmin=100, fmax=1000, sr=sr)
print(f"librosa: frecuencia mediana {np.nanmedian(f0):.1f} Hz → {librosa.hz_to_note(np.nanmedian(f0))}")

# 3) Procesar: pedalboard (C++, sobre arreglos) contra pydub (Python, sobre muestras)
board = Pedalboard([Compressor(threshold_db=-25, ratio=4), Gain(gain_db=6), Reverb(room_size=0.3)])
start = time.perf_counter()
processed = board(stereo.T, RATE)
ms_pb = (time.perf_counter() - start) * 1000
segment = AudioSegment.from_wav("muestra.wav")
start = time.perf_counter()
normalized = effects.normalize(segment)
ms_pd = (time.perf_counter() - start) * 1000
print(f"pedalboard, compresor + ganancia + reverb: {ms_pb:5.1f} ms para {SECONDS} s de audio ({SECONDS * 1000 / ms_pb:,.0f}× tiempo real)")
print(f"pydub, normalizar: {ms_pd:5.1f} ms · pico antes {segment.max_dBFS:.1f} dBFS, después {normalized.max_dBFS:.1f} dBFS")

# 4) mutagen: etiquetas en FLAC y en MP3 con la misma interfaz
for path in ("muestra.flac", "muestra.mp3"):
    audio = mutagen.File(path, easy=True)
    audio["title"] = "Tono de prueba"; audio["artist"] = "Laboratorio de la carta"
    audio.save()
    again = mutagen.File(path, easy=True)
    print(f"{path}: {type(again).__name__} · {again['title'][0]} · {again.info.length:.2f} s · {again.info.sample_rate} Hz")
EOF
timeout 590 docker run --rm --label curso=python-for-java-devs -v "$PWD:/w" -w /w python:3.14.7 sh -c 'apt-get -qq update >/dev/null 2>&1; apt-get -qq install -y ffmpeg >/dev/null 2>&1; timeout 400 pip install -q --root-user-action=ignore librosa==1.0.0 mutagen==1.48.1 soundfile==0.14.0 pedalboard==0.9.25 pydub==0.25.1 audioop-lts==0.2.2 >/dev/null 2>&1; pip list 2>/dev/null | grep -iE "^(numba|numpy|librosa|pedalboard) "; python audio.py; rm -f muestra.*'

# --- 2026-10-05T21:39:19 · Measure librosa import and first-call cost
timeout 590 docker run --rm --label curso=python-for-java-devs python:3.14.7 sh -c 'timeout 400 pip install -q --root-user-action=ignore librosa==1.0.0 >/dev/null 2>&1; for i in 1 2; do python -X importtime -c "import librosa" 2>&1 | tail -1; done; python -c "
import time; s=time.perf_counter(); import librosa, numpy as np; y=np.zeros(44100); librosa.pyin(y, fmin=100, fmax=1000, sr=44100); print(round(time.perf_counter()-s,2), \"s hasta el primer pyin\")"'

# --- 2026-10-05T21:40:36 · Write ar09, mark, URLs
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs && python3 - <<'PYEOF'
code=open('/Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516/salidas/ar09/audio.py').read().rstrip()
doc='''# 🎧 ar09 — Audio

> Python para desarrolladores Java senior · **Carta** · Track `ar` — Archivos y multimedia ·
> sección 9 de 10
> Se lee suelta: no hace falta ninguna otra sección de la carta.
> Versiones verificadas contra PyPI el 05/10/2026 · Código probado el 05/10/2026 con Python 3.14.7,
> en contenedor: las salidas son las de esa corrida.

---

## 🎯 1. Qué problema resuelve

El audio llega como notas de voz, grabaciones de llamadas, música de espera o pódcasts, y hay que hacer cosas parecidas a las del vídeo (`ar08`): convertir formatos,
normalizar el volumen, cortar, etiquetar y, a veces, analizar. Python tiene una biblioteca por tarea: **soundfile** lee y escribe audio sin pérdida como arreglos de NumPy;
**librosa** analiza (tono, ritmo, espectro); **pedalboard**, de Spotify, aplica efectos en C++; **mutagen** lee y escribe etiquetas de cualquier formato; y **pydub**,
la más citada en tutoriales, hace edición simple.

La sección pasa un tono de prueba de diez segundos por las cinco, con FFmpeg para los formatos con pérdida. Y empieza con lo que el inventario marcaba como dormido:
pydub no publica una versión desde 2021, y en Python 3.14 **ya no importa** sin ayuda.

---

## 🧠 2. El modelo

| Biblioteca | Para qué | Por debajo | Estado |
|---|---|---|---|
| **soundfile** | Leer y escribir WAV, FLAC, OGG como `ndarray` | `libsndfile` (C) | Activa |
| **librosa** | Análisis: tono (`pyin`), ritmo, espectrogramas | NumPy, SciPy, **numba** | Activa (1.0 en 2026) |
| **pedalboard** | Efectos: compresor, ganancia, reverberación, filtros | C++ (JUCE) | Activa |
| **mutagen** | Etiquetas de MP3, FLAC, MP4, Ogg con una sola interfaz | Python puro | Activa |
| **pydub** | Edición simple: cortar, unir, normalizar | `audioop` y FFmpeg | **Dormida desde 2021** |
| **FFmpeg** (binario) | Codificar MP3, Opus, AAC | C | La ruta que no se rompe (`ar08`) |

### 🩻 Esto sí funciona igual

El audio es un arreglo de muestras con una frecuencia de muestreo, como en `javax.sound.sampled` con su `AudioFormat`. Lo que cambia es que en Python ese arreglo es de
NumPy, y todo el ecosistema científico lo procesa sin copiarlo.

---

## 💻 3. El ejemplo que corre

`audio.py`:

```python
''' + code + '''
```

```bash
apt-get install ffmpeg
pip install pydub && python3 -c "import pydub" 2>&1 | tail -1      # en Python 3.14, sin más
pip install librosa mutagen soundfile pedalboard audioop-lts
python3 audio.py
python3 -c "import time; s=time.perf_counter(); import librosa, numpy as np; librosa.pyin(np.zeros(44100), fmin=100, fmax=1000, sr=44100); print(round(time.perf_counter()-s,2), 's hasta el primer pyin')"
```

Salida (Python 3.14.7, 05/10/2026) (los milisegundos son de la máquina que corre):

```text
ModuleNotFoundError: No module named 'pyaudioop'
wav 1,723 KB · flac 585 KB · mp3 157 KB · opus 123 KB
librosa: frecuencia mediana 441.3 Hz → A4
pedalboard, compresor + ganancia + reverb:  17.8 ms para 10 s de audio (561× tiempo real)
pydub, normalizar:   1.2 ms · pico antes -16.5 dBFS, después -0.1 dBFS
muestra.flac: FLAC · Tono de prueba · 10.00 s · 44100 Hz
muestra.mp3: EasyMP3 · Tono de prueba · 10.03 s · 44100 Hz
4.5 s hasta el primer pyin
```

pydub **no importa** en Python 3.14: depende de `audioop`, que la biblioteca estándar quitó en 3.13 (PEP 594), y busca un reemplazo que no existe. El paquete
`audioop-lts`, mantenido por la comunidad, lo devuelve; con él, pydub normaliza en 1,2 ms. Los formatos: FLAC ocupa un tercio del WAV sin perder nada; MP3 y Opus a
128 kb/s, la décima parte. librosa reconoce el La 440 (441,3 Hz, A4). pedalboard procesa diez segundos con tres efectos en 17,8 ms, 561 veces más rápido que el
tiempo real. mutagen escribe y lee las etiquetas de FLAC y MP3 con la misma interfaz; el MP3 dura 10,03 s y no 10: el codificador agrega relleno al principio y al
final. Y la última línea: librosa tarda **4,5 segundos** en la primera llamada a `pyin`, aunque `import librosa` cueste milisegundos.

**Detalles con intención**

- **`import librosa`** es perezoso: no carga sus submódulos hasta que se usan. La primera llamada a `pyin` carga SciPy y **compila con numba** sus funciones internas
  (`ff04`): ese es el costo de 4,5 s.
- **`subtype="PCM_16"`** escribe el WAV en 16 bits, el formato de un CD; sin él, `soundfile` escribiría en el tipo del arreglo (32 bits flotantes), el doble de grande.
- **`board(stereo.T, RATE)`**: pedalboard espera los canales en la primera dimensión (`canales × muestras`); soundfile entrega `muestras × canales`. La traspuesta
  es la frontera entre las dos convenciones.
- **`mutagen.File(path, easy=True)`** usa nombres de etiqueta comunes (`title`, `artist`) para todos los formatos; sin `easy`, cada formato tiene los suyos (ID3 usa
  `TIT2`, `TPE1`).

---

## ⚠️ 4. Lo que se rompe

**pydub en Python 3.13 o posterior.** El tutorial de pydub falla en la primera línea. `audioop-lts` lo arregla hoy; la decisión de fondo es no apoyarse en un paquete
dormido: para cortar y unir, FFmpeg (`ar08`); para normalizar, pedalboard o NumPy.

**librosa en un CLI corto.** 4,5 s de arranque en cada ejecución. Se calienta una vez en un proceso que vive, o se usa el caché de numba.

**La frecuencia de muestreo que cambia sola.** `librosa.load` **remuestrea a 22.050 Hz** por defecto; sin `sr=None`, el audio de 44.100 Hz se convierte sin avisar.

**El orden de los canales.** `muestras × canales` contra `canales × muestras`: un arreglo al revés se procesa como 441.000 canales de dos muestras, o falla.

---

## ⚖️ 5. Cuándo NO usarlas

**Para convertir formatos.** El binario de FFmpeg; las bibliotecas que codifican MP3 desde Python lo llaman por debajo.

**librosa para un dato simple.** El volumen pico o la duración se calculan con NumPy y soundfile, sin 4,5 s de arranque.

**pydub en un proyecto nuevo.** Funciona con `audioop-lts`, pero es una dependencia dormida en el camino crítico.

---

## 🧪 6. Ejercicios (10)

**🟢 Fácil (1–3)**

1. Corre el ejemplo. **Criterio:** las ocho líneas, y por qué pydub falló sin `audioop-lts`.
2. Carga `muestra.flac` con `librosa.load` sin `sr=None`. **Criterio:** la frecuencia de muestreo que devuelve y el nuevo largo del arreglo.
3. Lee las etiquetas del MP3 sin `easy=True`. **Criterio:** los nombres ID3 de título y artista.

**🟡 Intermedio (4–6)**

4. Normaliza el audio con NumPy (pico a −0,1 dBFS) sin pydub. **Criterio:** el mismo pico que pydub, y el tiempo.
5. Corta los segundos 2 a 5 con FFmpeg y con pydub. **Criterio:** la duración de cada uno, exacta al milisegundo.
6. Activa el caché de numba para librosa (`NUMBA_CACHE_DIR`) y repite la primera llamada a `pyin` en un proceso nuevo. **Criterio:** el tiempo de la segunda vez.

**🟠 Difícil (7–9)**

7. Normaliza la sonoridad a −16 LUFS con el filtro `loudnorm` de FFmpeg y con `pyloudnorm`. **Criterio:** las dos mediciones finales.
8. Procesa con pedalboard un archivo de una hora sin cargarlo entero (`AudioFile` en bloques). **Criterio:** la memoria máxima.
9. Detecta los silencios de una grabación de voz con librosa (`librosa.effects.split`). **Criterio:** los tramos con voz, comparados con los que escuchas.

**🔴 Muy difícil (10)**

10. Diseña el procesamiento de las grabaciones de un sistema (notas de voz que llegan en formatos variados). **Criterio:** una página. *Rúbrica:* (a) qué hace el binario y
    qué las bibliotecas; (b) cómo se normaliza el volumen; (c) qué etiquetas se escriben y cuáles se quitan; (d) los tiempos y el arranque medidos.

---

## 📚 7. Referencias

**Documentación oficial**

- librosa: https://librosa.org/doc/latest/
- pedalboard: https://spotify.github.io/pedalboard/
- mutagen: https://mutagen.readthedocs.io/en/latest/
- PEP 594, los módulos que salieron de la biblioteca estándar en 3.13: https://peps.python.org/pep-0594/

**Orden de lectura sugerido:** la PEP 594, para saber qué más se fue (`audioop`, `aifc`, `sunau`…); después la guía de inicio de librosa.

---

## 🚀 8. Cierre

El audio en Python son arreglos de NumPy y una biblioteca por tarea: soundfile para leer, librosa para analizar (con 4,5 s de arranque en la primera llamada), pedalboard para
efectos a 561 veces el tiempo real, mutagen para etiquetas. pydub, la más citada, no importa en 3.14 sin `audioop-lts`. Y los formatos con pérdida los codifica FFmpeg.

**La señal de que quedó bien:** *"Ninguna dependencia de audio está dormida en el camino crítico, y librosa se carga una vez en un proceso que vive."*

> 🏷️ **Cierra la sección con su tag**, cuando los ejercicios que elegiste estén hechos:
>
> ```bash
> git tag -a op-ar-fase-09 -m "op ar09 cerrada: audio con cinco bibliotecas, pydub sin audioop y librosa en frío"
> ```
>
> Los commits llevan su prefijo (`op ar09: …`) y los de ejercicio su número
> (`op ar09 ej07: …`).
'''
open('op155-ar09-audio.md','w').write(doc)
PYEOF
cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516 && python3 plan.py 155 155 ✅ ✅ | tail -1; python3 verificar_urls.py ../../cursos-algoritmos-lenguajes/python-for-java-devs/op155-ar09-audio.md | tail -3

# --- 2026-10-05T21:40:43 · Verify librosa.load default sample rate
timeout 590 docker run --rm --label curso=python-for-java-devs python:3.14.7 sh -c 'timeout 400 pip install -q --root-user-action=ignore librosa==1.0.0 soundfile==0.14.0 >/dev/null 2>&1; python -c "
import inspect, librosa, numpy as np, soundfile as sf
print(inspect.signature(librosa.load))
sf.write(\"x.wav\", np.zeros(44100), 44100); y, sr = librosa.load(\"x.wav\"); print(sr, len(y))"'

# --- 2026-10-05T21:41:25 · Run ar10 decision function
mkdir -p /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516/salidas/ar10 && cd $_ && cat > pegamento.py <<'EOF'
"""¿Biblioteca en el proceso o binario por subprocess? El veredicto del track como función, aplicado a siete tareas."""

from dataclasses import dataclass


@dataclass
class Task:
    name: str
    binary_does_it_whole: bool          # ¿el binario hace la tarea completa con sus opciones?
    touches_each_item: bool = False     # ¿hay que mirar o decidir sobre cada cuadro, muestra o celda?
    calls_per_second: float = 0.01      # ¿cuántas veces se ejecuta?
    library_alive: bool = True          # ¿la biblioteca publica versiones?


def decide(t: Task) -> str:
    if t.touches_each_item:
        return "biblioteca en el proceso" + ("" if t.library_alive else " (y buscar reemplazo: está dormida)")
    if t.binary_does_it_whole and t.calls_per_second < 10:
        return "binario por subprocess, con versión fija"
    if t.library_alive:
        return "biblioteca en el proceso: el arranque del binario pesa"
    return "binario por subprocess: la biblioteca está dormida"


TASKS = [
    Task("Convertir un informe de Markdown a Word", binary_does_it_whole=True),
    Task("Renderizar Markdown de cada comentario", binary_does_it_whole=True, calls_per_second=200),
    Task("Sacar un cuadro por segundo de un vídeo", binary_does_it_whole=True),
    Task("Brillo medio de cada cuadro", binary_does_it_whole=False, touches_each_item=True),
    Task("Certificados en PDF, miles por hora", binary_does_it_whole=True, calls_per_second=20),
    Task("Cortar y unir notas de voz", binary_does_it_whole=True, library_alive=False),
    Task("Leer la tabla de un PDF", binary_does_it_whole=False, touches_each_item=True),
]
for t in TASKS:
    print(f"{t.name:<42} → {decide(t)}")
EOF
timeout 100 docker run --rm --label curso=python-for-java-devs -v "$PWD:/w" -w /w python:3.14.7 python pegamento.py

# --- 2026-10-05T21:42:00 · Write ar10, mark, verify, locate ar inventory list
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs && python3 - <<'PYEOF'
code=open('/Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516/salidas/ar10/pegamento.py').read().rstrip()
doc='''# ⚖️ ar10 — Veredicto: el pegamento contra el binario

> Python para desarrolladores Java senior · **Carta** · Track `ar` — Archivos y multimedia ·
> sección 10 de 10
> Se lee suelta: no hace falta ninguna otra sección de la carta, aunque esta cierra el track y
> enlaza a las nueve anteriores.
> Versiones verificadas contra PyPI el 05/10/2026 · Código probado el 05/10/2026 con Python 3.14.7,
> en contenedor: las salidas son las de esa corrida.

---

## 🎯 1. Qué problema resuelve

El track recorrió el binario de verdad ([`ar01`](op147-ar01-binario-de-verdad.md)), Pillow ([`ar02`](op148-ar02-pillow.md)), OpenCV y SVG
([`ar03`](op149-ar03-opencv-y-svg.md)), PDF ([`ar04`](op150-ar04-pdf.md)), Office ([`ar05`](op151-ar05-office.md)), pandoc
([`ar06`](op152-ar06-markdown-html-y-pandoc.md)), LaTeX y Typst ([`ar07`](op153-ar07-latex-y-typst.md)), vídeo ([`ar08`](op154-ar08-video.md)) y audio
([`ar09`](op155-ar09-audio.md)). En casi todas apareció la misma pregunta: **¿una biblioteca dentro del proceso de Python, o un binario llamado con `subprocess`?**

El veredicto es que **el binario gana cuando hace la tarea completa y se llama pocas veces**: FFmpeg sacó los cuadros cuatro veces más rápido que PyAV, pandoc
convierte entre formatos como nadie, y ninguno se rompe cuando un envoltorio deja de mantenerse. **La biblioteca gana en dos casos**: cuando hay que tocar cada
cuadro, muestra o celda con código propio, y cuando la tarea se repite tanto que el arranque del binario pesa: 17 ms de pandoc contra 0,17 de `markdown-it-py`, 656 ms
de LaTeX contra 18 de Typst.

---

## 🧠 2. El modelo

| Comparación del track | Binario | En el proceso | Quién ganó y por qué |
|---|---|---|---|
| Un cuadro por segundo a JPEG (`ar08`) | FFmpeg: 333 ms | PyAV: 1.353 ms | **Binario**: el filtro corre entero en C |
| Markdown a HTML (`ar06`) | pandoc: 17,1 ms | `markdown-it-py`: 0,17 ms | **Proceso**: el arranque del binario |
| Informe en PDF (`ar07`) | `pdflatex`: 656 ms | Typst: 18 ms | **Proceso**, y sin escapar texto |
| Cortar 5 s de vídeo (`ar08`) | FFmpeg: 62 ms (copia) / 659 (exacto) | MoviePy: 1.068 ms | **Binario**; MoviePy por comodidad |
| Comprimir 19 MB (`ar01`) | — | `zipfile` con zstd: 69 ms | La biblioteca estándar, sin binario |
| Editar audio (`ar09`) | FFmpeg | pydub: **no importa en 3.14** | **Binario**: la biblioteca está dormida |

Y lo que no está en la columna del tiempo: las licencias (PyMuPDF es AGPL, `ar04`), las versiones de los binarios (Debian trae pandoc 3.1.11 y FFmpeg 7.1.5, otras
bibliotecas traen el suyo) y las opciones por defecto que no protegen (`<script>` en pandoc, `valid` en pyHanko, el segundo escondido de `-c copy`).

---

## 💻 3. El ejemplo que corre

Sin dependencias. `pegamento.py` es la regla del track como función:

```python
''' + code + '''
```

```bash
python3 pegamento.py
```

Salida (Python 3.14.7, 05/10/2026):

```text
Convertir un informe de Markdown a Word    → binario por subprocess, con versión fija
Renderizar Markdown de cada comentario     → biblioteca en el proceso: el arranque del binario pesa
Sacar un cuadro por segundo de un vídeo    → binario por subprocess, con versión fija
Brillo medio de cada cuadro                → biblioteca en el proceso
Certificados en PDF, miles por hora        → biblioteca en el proceso: el arranque del binario pesa
Cortar y unir notas de voz                 → binario por subprocess, con versión fija
Leer la tabla de un PDF                    → biblioteca en el proceso
```

**Detalles con intención**

- **Tocar cada elemento se evalúa primero**: si el código tiene que decidir sobre cada cuadro o cada celda, el binario no sirve, por rápido que sea.
- **El umbral de 10 llamadas por segundo** es una suposición a la vista: con 17 ms de arranque, diez llamadas por segundo ya se comen un sexto de un núcleo.
- **"Con versión fija"** acompaña siempre al binario: el que se instala "de la distribución" cambia con la imagen base (`ar06`, `ar08`).
- **Las notas de voz van al binario** porque la biblioteca del caso (pydub) está dormida; con una biblioteca viva, la regla podría decir otra cosa.

---

## ⚠️ 4. Lo que se rompe

**Envolver por reflejo.** Buscar "el paquete de Python para X" cuando X es un binario maduro lleva a envoltorios dormidos (`ffmpeg-python`, pydub) que fallan el día que
cambia Python o el binario.

**Llamar al binario en el bucle caliente.** Cada llamada arranca un proceso; mil llamadas son mil arranques.

**Confiar en los valores por defecto.** Tres secciones del track encontraron un valor por defecto que no protege: el HTML crudo de pandoc, el `valid` de pyHanko y la copia
de FFmpeg que guarda lo que no se pidió.

---

## ⚖️ 5. Cuándo NO usar este veredicto

**Si la biblioteca y el binario son lo mismo.** `pypandoc` llama a pandoc; elegir entre ellos es elegir cómo se arma la línea de comandos, no el motor.

**En un entorno sin binarios.** Funciones en la nube o un contenedor mínimo sin `apt`: ahí la rueda que trae todo adentro (Typst, `imageio-ffmpeg`) gana aunque sea más
lenta.

---

## 🧪 6. Ejercicios (8)

**🟢 Fácil (1–2)**

1. Agrega tres tareas de archivos de tu trabajo. **Criterio:** la salida, y si estás de acuerdo.
2. Cambia el umbral de llamadas a 1 por segundo. **Criterio:** qué tarea cambia y si mejora la decisión.

**🟡 Intermedio (3–4)**

3. Agrega la dimensión "hay binario en el entorno de ejecución". **Criterio:** un caso que pase de binario a biblioteca.
4. Escribe las pruebas de `decide` con un caso por regla. **Criterio:** cuatro casos, todos pasan.

**🟠 Difícil (5–6)**

5. Mide el arranque de cada binario del track (`ffmpeg -version`, `pandoc --version`, `pdflatex --version`) en tu máquina. **Criterio:** la tabla, y cuántas llamadas por segundo
   aguantaría un núcleo con cada uno.
6. Escribe una función de frontera para FFmpeg (argumentos como lista, nombres validados, `check=True`, `timeout`). **Criterio:** sus pruebas, incluida una con un nombre
   que empieza con `-`.

**🔴 Muy difícil (7–8)**

7. Escribe la política de dependencias de archivos de un proyecto. **Criterio:** una página. *Rúbrica:* (a) cuándo binario y cuándo biblioteca; (b) cómo se fijan las
   versiones de los binarios; (c) cómo se detecta una dependencia dormida; (d) las licencias que se revisan.
8. Audita las dependencias de archivos de un proyecto real. **Criterio:** una tabla. *Rúbrica:* (a) cada tarea con su herramienta actual; (b) la decisión de la tabla; (c) las
   dependencias dormidas; (d) el costo de cambiar las que deberían.

---

## 📚 7. Referencias

- La documentación de `subprocess`, la frontera de todo binario: https://docs.python.org/3/library/subprocess.html

**Orden de lectura sugerido:** las secciones de seguridad y de `timeout` de `subprocess`; el resto del track tiene sus referencias en cada sección.

---

## 🚀 8. Cierre

El binario gana cuando hace la tarea completa y se llama pocas veces: es más rápido, más completo y no se queda dormido. La biblioteca gana cuando hay que tocar cada
elemento o cuando el arranque del binario se repite demasiado. En los dos casos, con la versión fija y los valores por defecto revisados.

**La señal de que quedó bien:** *"Cada tarea de archivos del proyecto dice si usa un binario o una biblioteca, con su versión fija y la razón al lado."*

> 🏷️ **Cierra la sección con su tag**, cuando los ejercicios que elegiste estén hechos:
>
> ```bash
> git tag -a op-ar-fase-10 -m "op ar10 cerrada: el binario para la tarea completa, la biblioteca para cada elemento"
> ```
>
> Los commits llevan su prefijo (`op ar10: …`) y los de ejercicio su número
> (`op ar10 ej07: …`).
'''
open('op156-ar10-veredicto.md','w').write(doc)
PYEOF
cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516 && python3 plan.py 156 156 ✅ ✅ | tail -1; python3 verificar_urls.py ../../cursos-algoritmos-lenguajes/python-for-java-devs/op156-ar10-veredicto.md | tail -2; cd ../../cursos-algoritmos-lenguajes/python-for-java-devs && python3 prompts/verificar-corpus.py 2>&1 | grep -E "op15[3-6]|errores"; grep -n '"ar":' prompts/check-inventario.py

# --- 2026-10-05T21:42:04 · Show ar inventory list
sed -n 88,93p prompts/check-inventario.py

# --- 2026-10-05T21:42:09 · Add packages to ar inventory and refresh
sed -i '' 's/"librosa", "mutagen", "soundfile", "pedalboard", "ffmpeg-python", "decord"\],/"librosa", "mutagen", "soundfile", "pedalboard", "ffmpeg-python", "decord",\n           "opencv-python-headless", "docxtpl", "audioop-lts", "markdown-it-py"],/' prompts/check-inventario.py && python3 prompts/check-inventario.py ar 2>&1 | tail -1 && sed -n '/^## `ar`/,/^## `gi`/p' prompts/inventario-verificado.md | grep -E "headless|docxtpl|audioop|markdown-it|Pillow|PyMuPDF|typst|librosa"

# --- 2026-10-05T21:42:53 · Close T19; read gi plan and inventory
cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516 && python3 plan.py tanda T19 ✅ && python3 plan.py dondeesta "T1–T19 cerradas (156 de 176). Sigue T20 gi (op157)." && python3 plan.py bitacora '**2026-10-05 · T19 (`ar`) cerrada.** Escritas op147–op156 (10 secciones, 98 ejercicios), **las diez probadas en contenedor**, con archivos de muestra generados en cada ejemplo (nada de fotografía real). **Hallazgos y defectos propios:** `struct` corta sin avisar (`CHAPINERO` en `8s`); zip con **zstd** (nuevo en 3.14): 1,91 MB en 69 ms contra 4,15 MB y 476 ms de `deflate`, pero `unzip` de Debian lo salta; `tarfile` ya filtra `../` por defecto (ar01); `draft` parte el tiempo de la miniatura a la mitad, y conservar el EXIF arrastra el GPS (ar02); `opencv-python` falla sin `libGL` en el contenedor, pycairo no tiene ruedas para Linux, OpenCV 33 veces más rápido que scikit-image en Canny (ar03); **pyHanko da `valid=True` con el documento alterado**: el veredicto es `bottom_line` (ar04); openpyxl 102 MB contra 1 MB de XlsxWriter, la fórmula sin calcular se lee como `None`, y el marcador partido en *runs* (docxtpl lo repara, comprobado) (ar05); pandoc 17 ms por llamada contra 0,17 de `markdown-it-py`, y deja pasar `<script>` salvo `-raw_html` (ar06); LaTeX se rompe con el `&` de los datos, Typst los recibe como JSON y compila 36 veces más rápido (ar07); **el corte con `-c copy` guarda 25 cuadros escondidos antes de t=0** (ar08); **pydub no importa en 3.14** sin `audioop-lts`, librosa remuestrea a 22.050 Hz por defecto y su primer `pyin` tarda 4,5 s (ar09). **Defectos propios corregidos:** la medición de openpyxl con `tracemalloc` activo inflaba el tiempo seis veces (9,46 s contra 1,50); se separaron tiempo y memoria. **URL:** docs.opencv.org bloquea toda petición automática; se reemplazó por el README de `opencv-python`. **Inventario:** `opencv-python-headless`, `docxtpl`, `audioop-lts` y `markdown-it-py` agregados al track.' && sed -i '' 's/T1–T18 cerradas el 05\/10\/2026: 146 de 176; sigue T19 ar\./T1–T19 cerradas el 05\/10\/2026: 156 de 176; sigue T20 gi./' /Users/oskar/.claude/projects/-Users-oskar-Developer-Learning-courses-ia-generated/memory/MEMORY.md && grep -c "T1–T19" /Users/oskar/.claude/projects/-Users-oskar-Developer-Learning-courses-ia-generated/memory/MEMORY.md; grep -n "op15[7-9]\|op16[0-3]" ../../cursos-algoritmos-lenguajes/python-for-java-devs/prompts/plan-de-produccion-carta.md; sed -n '/^## `gi`/,/^## `cv`/p' ../../cursos-algoritmos-lenguajes/python-for-java-devs/prompts/inventario-verificado.md; grep -n "Track \`gi\`" ../../cursos-algoritmos-lenguajes/python-for-java-devs/prompts/propuestas-temas-opcionales.md

# --- 2026-10-05T21:44:53 · Check memory and plan state for T19
cd /Users/oskar/Developer/Learning/courses-ia-generated && grep -n "T1–T1" /Users/oskar/.claude/projects/-Users-oskar-Developer-Learning-courses-ia-generated/memory/MEMORY.md; cat /Users/oskar/.claude/projects/-Users-oskar-Developer-Learning-courses-ia-generated/memory/python-carta-produccion.md; grep -n "T19\|Dónde está" cursos-algoritmos-lenguajes/python-for-java-devs/prompts/plan-de-produccion-carta.md | head

# --- 2026-10-05T21:44:57 · Check whether T19 bitácora entry exists
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs && grep -c "T19 (\`ar\`) cerrada" prompts/plan-de-produccion-carta.md; git diff --stat -- prompts/plan-de-produccion-carta.md | tail -1

# --- 2026-10-05T21:45:08 · Write T19 bitácora entry and update memory
cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516 && python3 plan.py bitacora '**2026-10-05 · T19 (`ar`) cerrada.** Escritas op147–op156 (10 secciones, 98 ejercicios), **las diez probadas en contenedor**, con archivos de muestra generados en cada ejemplo (nada de fotografía real). **Hallazgos y defectos propios:** `struct` corta sin avisar (`CHAPINERO` en `8s`); zip con **zstd** (nuevo en 3.14): 1,91 MB en 69 ms contra 4,15 MB y 476 ms de `deflate`, pero `unzip` de Debian lo salta; `tarfile` ya filtra `../` por defecto (ar01); `draft` parte el tiempo de la miniatura a la mitad, y conservar el EXIF arrastra el GPS (ar02); `opencv-python` falla sin `libGL` en el contenedor, pycairo no tiene ruedas para Linux, OpenCV 33 veces más rápido que scikit-image en Canny (ar03); **pyHanko da `valid=True` con el documento alterado**: el veredicto es `bottom_line` (ar04); openpyxl 102 MB contra 1 MB de XlsxWriter, la fórmula sin calcular se lee como `None`, y el marcador partido en *runs* (docxtpl lo repara, comprobado) (ar05); pandoc 17 ms por llamada contra 0,17 de `markdown-it-py`, y deja pasar `<script>` salvo `-raw_html` (ar06); LaTeX se rompe con el `&` de los datos, Typst los recibe como JSON y compila 36 veces más rápido (ar07); **el corte con `-c copy` guarda 25 cuadros escondidos antes de t=0** (ar08); **pydub no importa en 3.14** sin `audioop-lts`, librosa remuestrea a 22.050 Hz por defecto y su primer `pyin` tarda 4,5 s (ar09). **Defectos propios corregidos:** la medición de openpyxl con `tracemalloc` activo inflaba el tiempo seis veces (9,46 s contra 1,50); se separaron tiempo y memoria. **URL:** docs.opencv.org bloquea toda petición automática; se reemplazó por el README de `opencv-python`. **Inventario:** `opencv-python-headless`, `docxtpl`, `audioop-lts` y `markdown-it-py` agregados al track.' && grep -c "T19 (\`ar\`) cerrada" ../../cursos-algoritmos-lenguajes/python-for-java-devs/prompts/plan-de-produccion-carta.md && sed -i '' 's/T1–T18 cerradas el 05\/10\/2026: 146 de 176; sigue T19 ar\./T1–T19 cerradas el 05\/10\/2026: 156 de 176; sigue T20 gi./' /Users/oskar/.claude/projects/-Users-oskar-Developer-Learning-courses-ia-generated/memory/MEMORY.md && grep -c "T1–T19" /Users/oskar/.claude/projects/-Users-oskar-Developer-Learning-courses-ia-generated/memory/MEMORY.md

# --- 2026-10-05T21:45:17 · Cross-check plan vs files, headers; run verifier
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs && python3 - <<'EOF'
import re, pathlib
plan = open("prompts/plan-de-produccion-carta.md").read()
rows = re.findall(r"^\| op(\d{3}) \| `([^`]+)` \| [^|]+ \| (\S+) \| (\S+) \|$", plan, re.M)
upto = [r for r in rows if int(r[0]) <= 156]
print("filas hasta op156:", len(upto))
for n, f, w, t in upto:
    p = pathlib.Path(f)
    problems = []
    if not p.exists(): problems.append("no existe")
    else:
        s = p.read_text()
        if "sin correr" in s: problems.append("queda 'sin correr'")
        if "Código probado" not in s: problems.append("encabezado sin 'Código probado'")
    if (w, t) != ("✅", "✅"): problems.append(f"marcas {w}{t}")
    if problems: print(f"op{n} {f}: {', '.join(problems)}")
extra = sorted(set(x.name for x in pathlib.Path(".").glob("op*.md")) - {f for _, f, _, _ in rows})
print("archivos op*.md fuera del plan:", extra)
EOF
python3 prompts/verificar-corpus.py 2>&1 | tail -14

# --- 2026-10-05T21:45:24 · List course containers, networks and volumes
docker ps -a --filter label=curso=python-for-java-devs --format '{{.ID}} {{.Image}} {{.Status}} {{.Names}}'; echo "--- redes"; docker network ls --filter label=curso=python-for-java-devs --format '{{.ID}} {{.Name}}'; docker network ls --format '{{.Name}}' | grep '^pfjd-' ; echo "--- volúmenes"; docker volume ls --filter label=curso=python-for-java-devs --format '{{.Name}}'

# --- 2026-10-05T21:45:29 · Check unlabeled containers using carta images
cat /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516/salidas/imagenes-bajadas.txt; echo ---; docker ps -a --format '{{.ID}} {{.Image}} {{.Status}} {{.Names}} {{.Labels}}' | grep -E "python:3.14|trixie|influx|meili|rustfs|nats|temurin|rabbitmq|miniforge|oracle|mssql" || echo "ninguno"

# --- 2026-10-05T21:45:41 · Find references to se04/se06 names and op036 context
grep -rn "se04-identidad-delegada\|se06-tls-de-verdad\|se04-oauth2-y-oidc\|se06-tls-y-certificados" --include=*.md . ../../zz-code/python-for-java-devs-20261005-f516/carta.py 2>/dev/null | grep -v "^./op05[02]" | head; echo ---; grep -n "sin correr" op036-qa07-carga-y-rendimiento.md op002-lg02-xml-en-serio.md op029-wf08-veredicto.md | head; sed -n 1,9p op036-qa07-carga-y-rendimiento.md

# --- 2026-10-05T21:45:47 · Find references; mark op036 partial
grep -rln "se04-identidad-delegada\|se06-tls-de-verdad" . ../../../zz-code/python-for-java-devs-20261005-f516/*.py 2>/dev/null; echo ---; grep -rln "op050-se04-oauth2-y-oidc\|op052-se06-tls-y-certificados" . 2>/dev/null; cd ../../zz-code/python-for-java-devs-20261005-f516 && python3 plan.py 36 36 ✅ 🟡 | tail -1

# --- 2026-10-05T21:45:52 · Find references; mark op036 partial
cd /Users/oskar/Developer/Learning/courses-ia-generated && grep -rln "se04-identidad-delegada\|se06-tls-de-verdad" cursos-algoritmos-lenguajes/python-for-java-devs zz-code/python-for-java-devs-20261005-f516 2>/dev/null | grep -v salidas; echo ---; grep -rln "op050-se04-oauth2-y-oidc\|op052-se06-tls-y-certificados" cursos-algoritmos-lenguajes/python-for-java-devs; cd zz-code/python-for-java-devs-20261005-f516 && python3 plan.py 36 36 ✅ 🟡 | tail -1; grep -n "op036" ../../cursos-algoritmos-lenguajes/python-for-java-devs/prompts/plan-de-produccion-carta.md

# --- 2026-10-05T21:45:57 · Fix se04/se06 file names in plan
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs && grep -n "op050\|op052" prompts/plan-de-produccion-carta.md && sed -i '' -e 's/`op050-se04-identidad-delegada.md`/`op050-se04-oauth2-y-oidc.md`/' -e 's/`op052-se06-tls-de-verdad.md`/`op052-se06-tls-y-certificados.md`/' prompts/plan-de-produccion-carta.md && grep -n "op050\|op052" prompts/plan-de-produccion-carta.md; head -1 op050-se04-oauth2-y-oidc.md op052-se06-tls-y-certificados.md

# --- 2026-10-05T21:46:02 · Check internal markdown links in carta
python3 - <<'EOF'
import re, pathlib
bad = 0
for p in sorted(pathlib.Path(".").glob("op*.md")):
    for target in re.findall(r"\]\(([^)#\s]+\.md)(?:#[^)]*)?\)", p.read_text()):
        if target.startswith("http"): continue
        if not (p.parent / target).exists():
            bad += 1; print(p.name, "→", target)
print("enlaces rotos:", bad)
EOF

# --- 2026-10-05T21:46:06 · Check verificar_urls usage
cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516 && head -20 verificar_urls.py | grep -i "uso\|argv"; ls ../../cursos-algoritmos-lenguajes/python-for-java-devs/op*.md | wc -l

# --- 2026-10-05T21:46:09 · Verify all external URLs in the carta
python3 verificar_urls.py ../../cursos-algoritmos-lenguajes/python-for-java-devs/op*.md 2>&1 | tail -15

# --- 2026-10-05T21:47:21 · Recheck flagged URLs with curl
for u in "https://www.funcionpublica.gov.co/eva/gestornormativo/norma.php?i=49981" https://dev.mysql.com/doc/refman/9.4/en/charset-unicode-sets.html https://dev.mysql.com/doc/refman/9.4/en/sql-mode.html https://www.tigerdata.com/docs/learn/hypertables/understand-hypertables; do echo "$(curl -s -o /dev/null -w '%{http_code}' -L --max-time 30 "$u") $u"; done

# --- 2026-10-05T21:47:34 · List zz-instrucciones files and read README
cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-instrucciones && wc -l *.md plantillas/* herramientas/* 2>/dev/null; cat README.md

# --- 2026-10-05T21:47:38 · Read memory of the C#/Go review
cat /Users/oskar/.claude/projects/-Users-oskar-Developer-Learning-courses-ia-generated/memory/revision-cursos-lenguajes-zz-instrucciones.md; cat /Users/oskar/.claude/projects/-Users-oskar-Developer-Learning-courses-ia-generated/memory/lineamientos-zz-instrucciones-y-zz-code.md

# --- 2026-10-05T21:47:45 · Read repo usage and course types docs
cat 04-usar-en-cada-repositorio.md; sed -n 1,120p 01-tipos-de-curso.md

# --- 2026-10-05T21:47:49 · List python prompts and course root
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs && ls -la prompts/ | awk '{print $5, $9}'; ls; git status --short . | head -30

# --- 2026-10-05T21:47:59 · Diff verifier copy; run both profiles
cd /Users/oskar/Developer/Learning/courses-ia-generated && diff -q zz-instrucciones/herramientas/verificador_base.py cursos-algoritmos-lenguajes/python-for-java-devs/prompts/verificador_base.py; diff zz-instrucciones/herramientas/verificador_base.py cursos-algoritmos-lenguajes/python-for-java-devs/prompts/verificador_base.py | head -20; diff -q zz-instrucciones/herramientas/verificador_base.py cursos-algoritmos-lenguajes/c-sharp-for-java-devs/prompts/verificador_base.py; python3 zz-instrucciones/herramientas/verificador_base.py cursos-algoritmos-lenguajes/python-for-java-devs --perfil=courses-ia 2>&1 | awk '{print $1, $2}' | sort | uniq -c | sort -rn | head; echo ---; python3 zz-instrucciones/herramientas/verificador_base.py cursos-algoritmos-lenguajes/python-for-java-devs --perfil=publicacion 2>&1 | awk '{print $1, $2}' | sort | uniq -c | sort -rn | head

# --- 2026-10-05T21:48:06 · Show PROMPTS and ENCAB findings
python3 zz-instrucciones/herramientas/verificador_base.py cursos-algoritmos-lenguajes/python-for-java-devs --perfil=publicacion 2>&1 | grep -E "PROMPTS|ENCAB" | head -24

# --- 2026-10-05T21:48:14 · Compare section headings template vs course docs
for t in readme-de-prompts:README alcance-del-proyecto:alcance-del-proyecto guia-de-estilo-y-convenciones:guia-de-estilo-y-convenciones plan-de-produccion:plan-de-produccion-carta plantillas-de-capitulo:plantillas-de-capitulo prompts-de-fase:prompts-de-fase propuesta-fases-y-alcance:propuesta-fases-y-alcance; do tpl=${t%%:*}; doc=${t##*:}; echo "======== $tpl  ⇄  $doc"; paste -d'|' <(grep -E '^## ' zz-instrucciones/plantillas/$tpl.md | cut -c1-60) <(grep -E '^## ' cursos-algoritmos-lenguajes/python-for-java-devs/prompts/$doc.md | cut -c1-60) | column -t -s'|'; done 2>&1 | head -150

# --- 2026-10-05T21:48:30 · Check placeholders, headers, decisions, Mermaid, zz-code registry
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs/prompts && echo "== restos de plantilla"; grep -c '✏️ \*\*Plantilla' *.md | grep -v ':0'; grep -c '{{' *.md | grep -v ':0'; echo "== vigencia en el encabezado (primeras 15 líneas)"; for f in *.md; do head -15 "$f" | grep -qiE "vigencia|fecha de verificación|verificado el" && echo "sí  $f" || echo "NO  $f"; done; echo "== D-xx citadas"; grep -ohE "D-[0-9]{2}" *.md | sort | uniq -c | head -30; echo "== Mermaid / D-12"; grep -n -i "mermaid" alcance-del-proyecto.md guia-de-estilo-y-convenciones.md | head; echo "== zz-code en el plan"; sed -n '/## 9. 🧪 Directorios/,$p' plan-de-produccion-carta.md | head -20

# --- 2026-10-05T21:48:37 · Compare header fields in templates and C#/Go prompts
cd /Users/oskar/Developer/Learning/courses-ia-generated && for f in guia-de-estilo-y-convenciones alcance-del-proyecto readme-de-prompts prompts-de-fase; do echo "== plantilla $f"; sed -n 1,14p zz-instrucciones/plantillas/$f.md | grep -E "^>"; done; echo; for f in cursos-algoritmos-lenguajes/c-sharp-for-java-devs/prompts/*.md cursos-algoritmos-lenguajes/go-for-java-devs/prompts/*.md; do head -15 "$f" | grep -qiE "vigencia|fecha de verificación" && echo "sí  $f" || echo "NO  $f"; done

# --- 2026-10-05T21:48:47 · Read guía §14 of Python and C#
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes && sed -n '/^## 14\./,$p' python-for-java-devs/prompts/guia-de-estilo-y-convenciones.md | head -90; echo "=========== C#"; sed -n '/^## 14\./,$p' c-sharp-for-java-devs/prompts/guia-de-estilo-y-convenciones.md | head -60

# --- 2026-10-05T21:48:54 · Read guía §5 and alcance §13
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs && sed -n '/^## 5\./,/^## 6\./p' prompts/guia-de-estilo-y-convenciones.md | head -40; grep -n "^## 13\|^### 13\|Decisiones cerradas" prompts/alcance-del-proyecto.md; sed -n '/^## 13\./,$p' prompts/alcance-del-proyecto.md | head -40

# --- 2026-10-05T21:49:05 · Find English comments inside carta code blocks
python3 - <<'EOF'
import re, pathlib
EN = re.compile(r"\b(the|over|arrives|through|nothing|exponential|smoothing|returns|with|from|this|should|keep|data|value|values|file|set|use|first|only|for|and|not)\b", re.I)
ES = re.compile(r"[áéíóúñ¿¡]|\b(el|la|los|las|de|que|con|sin|para|una|un|por|se|del|al|es|no|cada|lo)\b", re.I)
for p in sorted(pathlib.Path(".").glob("op*.md")):
    inside = False
    for n, line in enumerate(p.read_text().splitlines(), 1):
        if line.startswith("```"):
            inside = not inside if line.strip() == "```" or not inside else inside
            if line.strip() != "```" and not inside: inside = True
            continue
        if not inside: continue
        m = re.search(r"(?:^\s*(?://|/\*|#(?!!)|--)\s*|\s(?://|#)\s+)(.+)$", line)
        if not m: continue
        text = m.group(1)
        if re.match(r"^(include|define|cython|pragma|noqa|type:|/ script|\s*$)", text): continue
        if EN.search(text) and not ES.search(text):
            print(f"{p.name}:{n}: {line.strip()[:110]}")
EOF

# --- 2026-10-05T21:49:14 · Translate English code comments to Spanish
grep -n "The data arrives\|Exponential smoothing" op1*.md && python3 - <<'EOF'
import pathlib
reps = {
 "op140-ff02-ctypes-y-cffi.md": [("/* Exponential smoothing: out[i] = alpha * x[i] + (1 - alpha) * out[i - 1]. */",
                                  "/* Suavizado exponencial: out[i] = alpha * x[i] + (1 - alpha) * out[i - 1]. */")],
 "op143-ff05-rust-y-cpp.md": [("/// Exponential smoothing over a NumPy array.", "/// Suavizado exponencial sobre un arreglo de NumPy."),
                              ("// Exponential smoothing over a NumPy array.", "// Suavizado exponencial sobre un arreglo de NumPy.")],
 "op153-ar07-latex-y-typst.md": [("// The data arrives as JSON through sys.inputs: no string templating, nothing to escape.",
                                  "// Los datos llegan como JSON por sys.inputs: no se interpola texto, no hay nada que escapar.")],
}
for f, rs in reps.items():
    p = pathlib.Path(f); s = p.read_text()
    for a, b in rs:
        assert a in s, (f, a); s = s.replace(a, b)
    p.write_text(s)
print("listo")
EOF
grep -c "Exponential smoothing\|The data arrives" op140-ff02-ctypes-y-cffi.md op143-ff05-rust-y-cpp.md op153-ar07-latex-y-typst.md

# --- 2026-10-05T21:49:29 · Check prompts README coverage and guía §9 solutions
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs/prompts && for f in *.md *.py; do grep -q "$f" README.md && echo "sí  $f" || echo "NO  $f"; done; echo; head -12 README.md; echo; sed -n '/^## 9\./,/^## 10\./p' guia-de-estilo-y-convenciones.md | grep -n -i "soluci\|rúbrica\|criterio" | head

# --- 2026-10-05T21:49:43 · Read guía §9 Ejercicios
sed -n '/^## 9\. Ejercicios/,/^## 10\./p' guia-de-estilo-y-convenciones.md | head -60

# --- 2026-10-05T21:50:07 · Update guía §14 and add §15 exceptions
python3 - <<'EOF'
p='guia-de-estilo-y-convenciones.md'; s=open(p).read()
reps=[
("""  se hace aunque el autor no la exija.
""","""  se hace aunque el autor no la exija.
- **Lo que pasó en la práctica (actualizado el 05/10/2026, al cerrar T19).** La prueba de humo
  dejó de ser la excepción: se extendió a servicios en contenedores con red propia y sin puertos
  publicados, y **de las 156 secciones de T1–T19, 150 están probadas enteras y 6 en parte**
  (op002, op013, op019, op029, op036 y op120, marcadas 🟡 en el plan, con lo que falta dicho en su
  encabezado). «Por inspección» queda como el piso, no como la norma: una sección nueva se prueba
  salvo que no se pueda, y entonces lo declara.
"""),
("- [ ] Encabezado con track, posición, «se lee suelta», fecha de versiones y la declaración de\n      código sin ejecutar.",
 "- [ ] Encabezado con track, posición, «se lee suelta», fecha de versiones y la declaración de\n      si el código se probó (entero, en parte —diciendo qué— o sin ejecutar)."),
("- [ ] Un ejemplo completo, con su instalación (`uv add …` o `compose.yaml`), identificadores en\n      inglés y comentarios en español.",
 "- [ ] Un ejemplo completo, con su instalación (`uv add …` o `compose.yaml`), identificadores en\n      inglés y comentarios en español **en todos los lenguajes**, también C, Rust o Typst (§5)."),
]
for a,b in reps:
    assert a in s, a[:60]; s=s.replace(a,b,1)
s=s.rstrip()+'''

---

## 15. Excepciones a los lineamientos del repositorio

> 📝 **Sección agregada el 05/10/2026**, en la revisión de `prompts/` contra los lineamientos de
> producción del repositorio (`zz-instrucciones/`). Va al final para no renumerar nada: §13 sigue
> siendo el checklist y §14 la carta, y así los citan los demás documentos. Esta guía se escribió
> antes de que esos lineamientos existieran: lo que aquí se declara ya era la práctica del curso, y
> desde ahora está escrito como decisión.

El `CLAUDE.md` del repositorio y las plantillas de los lineamientos dan **valores por defecto**; esta
guía los reemplaza donde lo dice. Lo que esta sección no menciona se hereda tal cual. Las
excepciones propias de la carta están en §14.2.

| Regla general | Lo que hace este curso | Por qué |
|---|---|---|
| Comentarios dentro del código en inglés (repositorio) | **En español, con tildes**, igual que los mensajes de error y de log (§5) | El comentario es el canal del *porqué*, y el curso piensa en español; los identificadores siguen en inglés |
| 20–30 ejercicios por sección (repositorio) | **20 mínimo, 25 ideal** por fase (§9); 8–12 en la carta (§14.2) | El miniproyecto obligatorio consolida la fase; más volumen sería relleno |
| Solución de referencia o rúbrica por ejercicio (repositorio); solución plegada en 🟢🟡 (plantilla) | **Sin soluciones publicadas.** En el camino base, la evaluación verificable es el miniproyecto con sus criterios de aceptación (`formato-de-miniproyectos.md`); en la carta, cada ejercicio cierra con `**Criterio:**` y los 🔴 con rúbrica | Los ejercicios son enunciados accionables y verificables (§9); escribir cientos de soluciones duplicaría el curso |
| Apéndices `aNN-` y su propuesta | **Ninguno** (alcance §6) | Todo es fase, complemento o sección de la carta |
| Diagramas a criterio de quien escribe (`D-12` de los lineamientos) | **Mermaid** para los diagramas; `text` para árboles de archivos, muestras de datos, salidas y correspondencias en columnas | Pedido explícito del autor el 05/10/2026 para los cursos de esta familia. La carta ya lo cumple; la conversión del camino base y de los complementos es una tarea aparte, pendiente |

### 15.1 Lo que el curso no tiene, y qué hace su papel

- **Diccionario de términos** con ese nombre de archivo: hace su papel §5.1 de esta guía (el
  diccionario del dominio, de español a identificador en inglés).
- **Contrato de nombres** con ese nombre de archivo: lo hacen [`contrato-del-cli.md`](contrato-del-cli.md)
  (los nombres del CLI de Patricia, congelados fase a fase) y §5.1. No se renombran, por el bloqueo
  de contenido.
- **Plan de producción del camino base y de los complementos:** se escribieron antes de que los
  lineamientos lo pidieran, y su registro está en `README.md` (las tandas T0–T13). La carta sí tiene
  el suyo: [`plan-de-produccion-carta.md`](plan-de-produccion-carta.md), con la forma de la
  plantilla (§1–§9, incluido el registro de directorios de `zz-code/`).
- **Propuesta de apéndices y prompts de apéndice:** no hay apéndices.
- **Fecha de versión en el encabezado** de cada documento de `prompts/`: solo la llevan el plan y
  el inventario, que cambian a diario. Los demás fechan cada cambio en el propio texto, como esta
  sección.
- **Verificador:** [`verificar-corpus.py`](verificar-corpus.py), subclase del perfil `courses-ia`
  de [`verificador_base.py`](verificador_base.py) (copia idéntica a la de los lineamientos), con los
  chequeos `CARTA-*` de la carta. Se corre desde la raíz del curso con
  `python3 prompts/verificar-corpus.py`. Con `--perfil=publicacion` todavía falla: emoji en `###`
  (permitidos en este repositorio) y dos enlaces de `ia01` a `prompts/`, que se resuelven en la
  etapa de publicación.
'''
open(p,'w').write(s+"\n")
EOF
tail -5 guia-de-estilo-y-convenciones.md

# --- 2026-10-05T21:50:34 · Check prompts links, verifier, pycache ignore
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs && python3 - <<'EOF'
import re, pathlib
bad=0
for p in sorted(pathlib.Path("prompts").glob("*.md")):
    for t in re.findall(r"\]\(([^)#\s]+)(?:#[^)]*)?\)", p.read_text()):
        if t.startswith(("http","mailto")): continue
        if not (p.parent/t).exists(): bad+=1; print(p.name,"→",t)
print("enlaces rotos en prompts/:", bad)
EOF
python3 prompts/verificar-corpus.py 2>&1 | tail -1; git check-ignore -v prompts/__pycache__ || echo "__pycache__ NO ignorado"; ls prompts/__pycache__

# --- 2026-10-05T21:50:49 · Log revision in bitácora and update memory
cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516 && python3 plan.py bitacora '**2026-10-05 · Corte después de T19: pruebas de conjunto y revisión de `prompts/` contra `zz-instrucciones/`.** **Pruebas (op001–op156):** plan contra archivos, encabezados y marcas; enlaces internos (0 rotos); 522 URL externas (las 4 que fallan con Python responden 200 a `curl`: se quedan); verificador del curso en 0 errores; ningún contenedor, red ni volumen del curso quedó en Docker. Se corrigió el plan: los nombres de archivo de op050 y op052 (los archivos y los enlaces de `se08` ya usaban `oauth2-y-oidc` y `tls-y-certificados`), y op036 pasa a ✅🟡 porque sus cifras de carga van en `⏳`. Quedan 6 secciones probadas en parte (op002, op013, op019, op029, op036, op120) para T24. **Defecto propio corregido:** cinco comentarios en inglés en el código C, Rust, C++ y Typst de ff02, ff05 y ar07, contra la guía §5. **Revisión de `prompts/`:** la copia de `verificador_base.py` es idéntica a la de los lineamientos; con `--perfil=courses-ia`, 0 errores; con `--perfil=publicacion`, los emoji en `###` (permitidos en el repositorio) y dos enlaces de `ia01` a `prompts/` (para la etapa de publicación). Se agregó la guía §15 (excepciones del curso a los lineamientos y documentos que no tiene, con qué hace su papel), se actualizaron §14.1 y §14.4 a la práctica real (probado en contenedor), D-12 en el alcance §13, y el `README.md` de `prompts/` ahora describe la carta, su plan, el inventario y los scripts.' && cd /Users/oskar/.claude/projects/-Users-oskar-Developer-Learning-courses-ia-generated/memory && python3 - <<'EOF'
p='revision-cursos-lenguajes-zz-instrucciones.md'; s=open(p).read()
s=s.replace("**Sigue:** `python-for-java-devs` (ver [[python-java-devs-estado]]: camino base sin commitear).",
"""**Python (parcial, 05/10/2026, al cortar la carta en T19):** `prompts/` validado contra
`zz-instrucciones/`: guía §15 nueva (excepciones: comentarios en español, 20–25 ejercicios, sin
soluciones publicadas, sin apéndices, Mermaid; documentos que no tiene y qué hace su papel), §14
actualizada a la práctica real de la carta, D-12 en alcance §13, `prompts/README.md` al día.
**Falta:** convertir a Mermaid los diagramas del camino base y de `ia`/`ds`, y los dos enlaces de
`ia01` a `prompts/` (bloquean `--perfil=publicacion`).

**Sigue:** terminar la carta (T20–T24) y después la conversión a Mermaid de python
(ver [[python-carta-produccion]]).""")
open(p,'w').write(s)
EOF
grep -c "Python (parcial" revision-cursos-lenguajes-zz-instrucciones.md; sed -i '' 's/— C# y go hechos el 05\/10\/2026 (Mermaid, guía §14, verificador); sigue python\./— C# y go hechos; python: prompts\/ validado el 05\/10\/2026 (guía §15), falta su Mermaid./' MEMORY.md; grep -n "Revisión de cursos" MEMORY.md

# --- 2026-10-05T21:56:44 · Read deletion and Docker rules from memory
cat /Users/oskar/.claude/projects/-Users-oskar-Developer-Learning-courses-ia-generated/memory/git-lo-maneja-el-usuario.md /Users/oskar/.claude/projects/-Users-oskar-Developer-Learning-courses-ia-generated/memory/feedback-pruebas-en-contenedor.md | grep -v "^---"

# --- 2026-10-05T21:56:53 · Log Docker inventory before cleanup
mkdir -p /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516/salidas && LOG=/Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516/salidas/inventario-docker-antes-de-limpiar.txt; { date; echo "== contenedores"; docker ps -a --format '{{.ID}} {{.Image}} {{.Status}} {{.Names}} {{.Labels}}'; echo "== volúmenes"; docker volume ls --format '{{.Name}} {{.Labels}}'; echo "== imágenes"; docker images --format '{{.Repository}}:{{.Tag}} {{.ID}} {{.Size}} {{.CreatedSince}}'; echo "== colgantes"; docker images -f dangling=true --format '{{.ID}} {{.Size}}'; echo "== redes"; docker network ls --format '{{.Name}}'; } > $LOG; cat $LOG | sed -n '/== contenedores/,/== volúmenes/p' | head -20; echo; grep -E "python:|trixie|influx|meili|rustfs|nats|temurin|rabbitmq|miniforge|oracle|mssql" $LOG; echo; sed -n '/== colgantes/,/== redes/p' $LOG

# --- 2026-10-05T21:57:01 · Remove carta images and labeled prune
for img in debian:trixie-slim influxdb:3.12.0-core getmeili/meilisearch:v1.54.3 rustfs/rustfs:1.0.1 nats:2.15.0 eclipse-temurin:21.0.12.1_1-jdk rabbitmq:4.3.6-alpine condaforge/miniforge3:26.7.2-0; do users=$(docker ps -a --filter ancestor=$img -q); if [ -n "$users" ]; then echo "SALTO $img: la usa $users"; else docker rmi $img >/dev/null && echo "borrada $img"; fi; done; docker image prune -f --filter label=curso=python-for-java-devs; docker volume ls --filter label=curso=python-for-java-devs -q | wc -l; docker images --format '{{.Repository}}:{{.Tag}}' | grep -E "trixie-slim|influx|meili|rustfs|nats|temurin|rabbitmq|miniforge" || echo "ninguna de la lista queda"

# --- 2026-10-05T21:57:08 · Annotate deleted images in list
cd /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/python-for-java-devs-20261005-f516/salidas && sed -i '' -E 's#^(debian:trixie-slim|influxdb:3.12.0-core|getmeili/meilisearch:v1.54.3|rustfs/rustfs:1.0.1|nats:2.15.0|eclipse-temurin:21.0.12.1_1-jdk|rabbitmq:4.3.6-alpine|condaforge/miniforge3:26.7.2-0)$#\1  (borrada el 05/10/2026, corte en T19)#' imagenes-bajadas.txt && cat imagenes-bajadas.txt

# --- 2026-10-05T21:57:13 · List build/cache dirs and check git tracking
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes && find . -type d \( -name __pycache__ -o -name target -o -name .pytest_cache -o -name .ruff_cache -o -name .mypy_cache -o -name build -o -name dist -o -name '*.egg-info' -o -name bin -o -name obj -o -name node_modules -o -name .venv -o -name venv -o -name .gradle -o -name .ipynb_checkpoints -o -name .numba_cache \) -prune -print | while read d; do n=$(find "$d" -type f | wc -l | tr -d ' '); t=$(git ls-files "$d" | wc -l | tr -d ' '); s=$(du -sh "$d" | cut -f1); echo "$s	archivos=$n	versionados=$t	$d"; done

# --- 2026-10-05T21:57:18 · Delete prompts __pycache__ and check strays
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs/prompts && rm __pycache__/verificador_base.cpython-313.pyc && rmdir __pycache__ && ls -d __pycache__ 2>/dev/null || echo "borrado"; cd ../.. && find . -name '*.pyc' -o -name '*.so' -o -name '*.o' | head

# --- 2026-10-05T21:57:26 · Final closure status check
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs && python3 - <<'EOF'
import re
plan=open("prompts/plan-de-produccion-carta.md").read()
rows=re.findall(r"^\| op(\d{3}) \| `[^`]+` \| [^|]+ \| (\S+) \| (\S+) \|$",plan,re.M)
upto=[r for r in rows if int(r[0])<=156]
print("escritas:",sum(r[1]=="✅" for r in upto),"de",len(upto),"· corridas enteras:",sum(r[2]=="✅" for r in upto),"· en parte:",[f"op{r[0]}" for r in upto if r[2]=="🟡"])
print("tandas:",re.findall(r"^\| \*\*(T\d+)\*\* \|.*\| (\S+) \|$",plan,re.M)[:19])
print(re.search(r"Dónde está la producción.*",plan).group(0))
EOF
PYTHONDONTWRITEBYTECODE=1 python3 prompts/verificar-corpus.py 2>&1 | tail -1; ls -d prompts/__pycache__ 2>/dev/null || echo "sin __pycache__"; docker ps -a --filter label=curso=python-for-java-devs -q | wc -l

