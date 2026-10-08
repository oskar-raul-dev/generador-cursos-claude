# Comandos Bash de la sesión 2859734a-d7e6-4986-b771-4890bf56e42b, en orden. Una bitácora, no un script: no se corre entera.

# --- 2026-09-13T19:41:24 · Read memory file and list course dirs
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs && echo "=== MEMORY FILE ===" && cat /Users/oskar/.claude/projects/-Users-oskar-Developer-Learning-courses-ia-generated/memory/python-java-devs-estado.md && echo "=== LS -R (dirs) ===" && ls prompts src && echo "=== WC ===" && wc -l *.md | tail -5

# --- 2026-09-13T19:41:29 · Check ds track state and prompts outline
echo "=== ds files? ===" && ls | grep -E '^ds' || echo "(ninguno)" && echo "=== prompts ds §  ===" && grep -n "^## \|^### " prompts/prompts-de-tracks-ia-ds.md | head -60 && echo "=== git ===" && git status --short . | head

# --- 2026-09-13T19:43:07 · Find current files and references
ls 00-* prompts/historia* 2>&1; echo "=== refs historia-de-aurea ==="; grep -rn "historia-de-aurea\|historia-propuesta" . --include=* -l 2>/dev/null; echo "=== refs 00-ambiente ==="; grep -rn "00-ambiente-editores-y-ecosistema\|00-instalacion-ambiente" . -l 2>/dev/null

# --- 2026-09-13T19:43:10 · List 00 files and grep references
ls 00-*; echo "=== A: historia ==="; grep -rn "historia-de-aurea\|historia-propuesta" . 2>/dev/null | grep -v "^\./\.pytest_cache"; echo "=== B: ambiente ==="; grep -rn "00-ambiente-editores-y-ecosistema\|00-instalacion-ambiente-editores" . 2>/dev/null | grep -v "^\./\.pytest_cache"

# --- 2026-09-13T19:43:22 · Check root README and estructura for phase 00 refs
echo "=== README root: fase 00 ==="; grep -n "00\|Ambiente\|ambiente\|Áurea\|historia" README.md | head -30; echo "=== ESTRUCTURA ==="; grep -n "00\|ambiente\|historia" 0-ESTRUCTURA-CURSO.md | head -40

# --- 2026-09-13T19:43:25 · Read context around Áurea history mentions
sed -n 110,120p 0-ESTRUCTURA-CURSO.md; echo "---README 35-45---"; sed -n 33,45p README.md

# --- 2026-09-13T19:43:32 · Read README reading order and style guide naming section
sed -n 90,105p README.md; echo "=== guia 8.2 ==="; grep -n "8.2" prompts/guia-de-estilo-y-convenciones.md | head; echo; sed -n '/### 8.2/,/### 8.3/p' prompts/guia-de-estilo-y-convenciones.md | head -60

# --- 2026-09-13T19:43:52 · Rewrite filename references across course
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs
# A. ambiente -> instalacion-ambiente
grep -rl "00-ambiente-editores-y-ecosistema" . 2>/dev/null | grep -v pytest_cache | while read f; do
  sed -i '' 's|00-ambiente-editores-y-ecosistema|00-instalacion-ambiente-editores-y-ecosistema|g' "$f"; echo "A: $f"; done
echo "--- B ---"
# B1: markdown links dentro de prompts/
sed -i '' 's|(historia-de-aurea\.md)|(../00-historia-de-aurea.md)|g' prompts/*.md
# B2: rutas explícitas prompts/historia-de-aurea.md
grep -rl "prompts/historia-de-aurea.md" . 2>/dev/null | grep -v pytest_cache | while read f; do
  sed -i '' 's|prompts/historia-de-aurea\.md|00-historia-de-aurea.md|g' "$f"; echo "B2: $f"; done
# B3: menciones sueltas
grep -rl "historia-de-aurea\.md" . 2>/dev/null | grep -v pytest_cache | while read f; do
  sed -i '' 's|\([^0-9/]\)historia-de-aurea\.md|\100-historia-de-aurea.md|g; s|^historia-de-aurea\.md|00-historia-de-aurea.md|g' "$f"; echo "B3: $f"; done
echo "=== VERIFY ==="; grep -rn "historia-de-aurea" . 2>/dev/null | grep -v pytest_cache

# --- 2026-09-13T19:44:02 · Fix doubled 00- prefix
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs
grep -rl "00-00-historia-de-aurea" . 2>/dev/null | grep -v pytest_cache | while read f; do sed -i '' 's|00-00-historia-de-aurea|00-historia-de-aurea|g' "$f"; done
echo "=== VERIFY ==="; grep -rn "historia-de-aurea" . 2>/dev/null | grep -v pytest_cache

# --- 2026-09-13T19:44:11 · Inspect prose contexts framing the history file
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs
for spec in "prompts/README.md:25:55" "prompts/README.md:88:100" "prompts/prompts-de-fase.md:38:56" "prompts/prompts-de-tracks-ia-ds.md:78:96" "prompts/alcance-del-proyecto.md:142:155" "prompts/guia-de-estilo-y-convenciones.md:560:572" "prompts/guia-de-estilo-y-convenciones.md:610:624"; do
 f=${spec%%:*}; r=${spec#*:}; a=${r%%:*}; b=${r##*:}
 echo "=== $f $a-$b ==="; sed -n "${a},${b}p" "$f"; done

# --- 2026-09-13T19:44:26 · Inspect moved history file and prompts README header
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs
echo "=== head historia ==="; sed -n 1,30p 00-historia-de-aurea.md
echo "=== refs internos historia ==="; grep -n "prompts/\|este documento\|Este documento" 00-historia-de-aurea.md | head -20
echo "=== head prompts/README ==="; sed -n 1,25p prompts/README.md
echo "=== prompts/README cuenta docs ==="; grep -n "doce\|trece\|catorce\|once\|documentos" prompts/README.md | head

# --- 2026-09-13T19:44:36 · Inspect root-docs prompt and README order section
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs
echo "=== prompts/README 56-86 ==="; sed -n 56,86p prompts/README.md
echo "=== prompts-documentos-raiz head ==="; sed -n 1,40p prompts/prompts-documentos-raiz.md

# --- 2026-09-13T19:44:49 · Grep root-document references
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs
echo "=== links a 00-convencion / documentos raiz en guia y alcance ==="; grep -rn "00-convencion" *.md prompts/*.md | head -20
echo "=== 'documentos de la raíz' ==="; grep -rn "raíz del curso" prompts/*.md *.md | head -20

# --- 2026-09-13T19:44:55 · Inspect root-doc inventories
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs
sed -n 8,20p prompts/alcance-del-proyecto.md; echo "=== propuesta-fases 815-822 ==="; sed -n 815,822p prompts/propuesta-fases-y-alcance.md

# --- 2026-09-13T19:45:17 · Apply prose updates for the move
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs
python3 - <<'PY'
import io,sys
def edit(path, old, new, count=1):
    s=open(path,encoding='utf-8').read()
    if s.count(old)<1:
        print("MISS",path,repr(old[:60])); return
    s=s.replace(old,new,count); open(path,'w',encoding='utf-8').write(s); print("OK",path)

# 1. prompts/README.md — orden de lectura
edit('prompts/README.md',
"""4. **[`00-historia-de-aurea.md`](../00-historia-de-aurea.md)** — la empresa del curso.
   Fuente de verdad de todo lo narrativo: personajes, cifras, cronología, reglas de negocio.""",
"""4. **[`00-historia-de-aurea.md`](../00-historia-de-aurea.md)** — la empresa del curso.
   Fuente de verdad de todo lo narrativo: personajes, cifras, cronología, reglas de negocio.
   **Vive en la raíz del curso, no aquí**: es el único documento narrativo y el lector también
   lo abre, así que se publica con las fases en vez de quedarse en la maquinaria.""")

# 2. prompts/README.md — tabla de autoridad
edit('prompts/README.md',
"| `00-historia-de-aurea.md` | La empresa del curso, y la única | Todo lo narrativo |",
"| `../00-historia-de-aurea.md` | La empresa del curso, y la única. **Está en la raíz, publicada** | Todo lo narrativo |")

# 3. prompts/README.md — sesión de escritura
edit('prompts/README.md',
"""3. `README.md` del curso

**Después las fases**""",
"""3. `README.md` del curso

`00-historia-de-aurea.md` también vive en la raíz, pero no sale de aquí: se escribió antes que
todo lo demás y es la fuente narrativa, no un entregable encargado por `prompts-documentos-raiz.md`.

**Después las fases**""")

# 4. prompts-documentos-raiz.md
edit('prompts/prompts-documentos-raiz.md',
"""Tres documentos viven en la **raíz del curso**, no en `prompts/`, y **se escribieron antes que
cualquier fase** porque las 18 fases los enlazan. Cada uno se redactó en su propio chat.""",
"""Tres documentos viven en la **raíz del curso**, no en `prompts/`, y **se escribieron antes que
cualquier fase** porque las 18 fases los enlazan. Cada uno se redactó en su propio chat.

📝 `00-historia-de-aurea.md` también está en la raíz y también precede a las fases, pero **no lo
encarga este documento**: es la fuente narrativa del curso, no un entregable de estructura.""")

# 5. 0-ESTRUCTURA-CURSO.md
edit('0-ESTRUCTURA-CURSO.md',
"""personajes, las cifras, las reglas de negocio y por qué el software está como está— vive en el
material de autoría del curso, y cada fase te da el pedazo que necesita.""",
"""personajes, las cifras, las reglas de negocio y por qué el software está como está— vive en
[`00-historia-de-aurea.md`](00-historia-de-aurea.md), y cada fase te da el pedazo que necesita.""")

# 6. README.md raíz — orden de lectura
edit('README.md',
"""Empieza por [`0-ESTRUCTURA-CURSO.md`](0-ESTRUCTURA-CURSO.md), sigue con
[`00-convencion-de-git-y-tags.md`](00-convencion-de-git-y-tags.md) y después con la Fase 00.""",
"""Empieza por [`0-ESTRUCTURA-CURSO.md`](0-ESTRUCTURA-CURSO.md), sigue con
[`00-convencion-de-git-y-tags.md`](00-convencion-de-git-y-tags.md) y con
[`00-historia-de-aurea.md`](00-historia-de-aurea.md) —la empresa para la que vas a construir
todo—, y después con la Fase 00.""")

# 7. listas de fuentes: marcar que la historia está en la raíz
edit('prompts/prompts-de-fase.md',
"""7. `00-historia-de-aurea.md` — todo lo narrativo: personajes, cifras, cronología,
   reglas de negocio.""",
"""7. `00-historia-de-aurea.md` —en la **raíz del curso**, no en `prompts/`— todo lo narrativo:
   personajes, cifras, cronología, reglas de negocio.""")
edit('prompts/prompts-de-tracks-ia-ds.md',
"""6. `00-historia-de-aurea.md` — **§5 (la historia clínica), §7 (los dos proyectos
   de IA) y §8 (los dos de datos)** son el encargo literal.""",
"""6. `00-historia-de-aurea.md`, en la **raíz del curso** — **§5 (la historia clínica), §7 (los dos
   proyectos de IA) y §8 (los dos de datos)** son el encargo literal.""")

# 8. alcance §Estado: inventario de la raíz
edit('prompts/alcance-del-proyecto.md',
"> raíz del curso, junto con `0-ESTRUCTURA-CURSO.md`, `00-convencion-de-git-y-tags.md`,",
"> raíz del curso, junto con `0-ESTRUCTURA-CURSO.md`, `00-convencion-de-git-y-tags.md`,\n> `00-historia-de-aurea.md`,")
PY

# --- 2026-09-13T19:45:35 · Add naming note and verify links
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs
python3 - <<'PY'
p='prompts/guia-de-estilo-y-convenciones.md'
s=open(p,encoding='utf-8').read()
old="""- **El camino base se lista contiguo.** Los dígitos ordenan antes que las letras, así que `00-` a
  `17-` quedan juntos y arriba, sin que ningún material posterior se intercale."""
new="""- **El camino base se lista contiguo.** Los dígitos ordenan antes que las letras, así que `00-` a
  `17-` quedan juntos y arriba, sin que ningún material posterior se intercale. Los dos documentos
  de encuadre que el lector abre antes de empezar —`00-convencion-de-git-y-tags.md` y
  `00-historia-de-aurea.md`— llevan el mismo `00-` y **el orden alfabético los deja delante de la
  Fase 00**, que por eso se llama `00-instalacion-ambiente-editores-y-ecosistema.md`: el nombre
  del archivo reproduce el orden de lectura sin necesidad de un índice."""
assert s.count(old)==1
open(p,'w',encoding='utf-8').write(s.replace(old,new))
print("OK")
PY
echo "=== quedan refs viejas? ==="
grep -rn "00-ambiente-editores\|prompts/historia-de-aurea\|(historia-de-aurea" . 2>/dev/null | grep -v pytest_cache || echo "ninguna"
echo "=== links rotos (md) ==="
python3 - <<'PY'
import re,os
bad=[]
for root,d,fs in os.walk('.'):
    if 'pytest_cache' in root or '/.git' in root: continue
    for f in fs:
        if not f.endswith('.md'): continue
        p=os.path.join(root,f)
        for i,l in enumerate(open(p,encoding='utf-8'),1):
            for m in re.finditer(r'\]\(([^)#:]+\.md)(?:#[^)]*)?\)',l):
                t=m.group(1)
                if not os.path.exists(os.path.normpath(os.path.join(root,t))): bad.append(f"{p}:{i} -> {t}")
print("\n".join(bad) or "sin links rotos")
PY

# --- 2026-09-13T19:45:47 · Update project memory with the moves
cd /Users/oskar/.claude/projects/-Users-oskar-Developer-Learning-courses-ia-generated/memory
python3 - <<'PY'
p='python-java-devs-estado.md'
s=open(p,encoding='utf-8').read()
old="""**El curso es autocontenido (Tanda 00, 13/09/2026).**"""
new="""**Dos movimientos de archivo el 13/09/2026.** `prompts/historia-de-aurea.md` pasó a la raíz como
**`00-historia-de-aurea.md`** (deja de ser maquinaria: es material publicado que el lector abre), y
la Fase 00 se renombró a **`00-instalacion-ambiente-editores-y-ecosistema.md`** para que el orden
alfabético de los tres `00-` reproduzca el orden de lectura: convención → historia → Fase 00.
La razón quedó escrita en la guía §8.2.

**El curso es autocontenido (Tanda 00, 13/09/2026).**"""
assert s.count(old)==1
s=s.replace(old,new)
s=s.replace("se eliminó `historia-propuesta-1-cordillera.md` (vive en el curso de C#) y\n`historia-propuesta-2-aurea.md` se renombró a **`historia-de-aurea.md`**.",
            "se eliminó `historia-propuesta-1-cordillera.md` (vive en el curso de C#) y\n`historia-propuesta-2-aurea.md` se renombró a `historia-de-aurea.md` y hoy es\n`00-historia-de-aurea.md` en la raíz.")
open(p,'w',encoding='utf-8').write(s)
print("OK")
PY

# --- 2026-09-13T19:52:37 · Read the 17-section map
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs
sed -n '/^## 🗺️ Las diecisiete secciones/,/^## § Marco común/p' prompts/prompts-de-tracks-ia-ds.md

# --- 2026-09-13T19:52:44 · Find tanda records and read ds blocks
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs
echo "=== grep Tanda ==="; grep -rn "Tanda\|tanda" --include=*.md . | grep -v pytest_cache | head -30
echo; echo "=== ds blocks ==="; sed -n '/^## # ds01/,$p' prompts/prompts-de-tracks-ia-ds.md

# --- 2026-09-13T19:52:55 · Read pinned versions section
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs
sed -n '/## 9\./,/## 10\./p' prompts/alcance-del-proyecto.md

# --- 2026-09-13T19:53:01 · List src tree
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs/src
for d in */; do echo "--- $d"; ls "$d" | head -12; done

# --- 2026-09-13T19:53:48 · Read history index and data projects section
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs
echo "=== indice historia ==="; grep -n "^## \|^### " 00-historia-de-aurea.md
echo "=== §8 ==="; sed -n '/^## 8\./,/^## 9\./p' 00-historia-de-aurea.md

# --- 2026-09-13T19:53:54 · Read base data generators
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs/src
echo "########## 01"; sed -n 1,80p 01-modelo-de-datos/generar_datos_f01.py
echo "########## 02 citas"; sed -n 1,70p 02-secuencias-perezosas/generar_citas.py

# --- 2026-09-13T19:54:37 · Record ds tandas in prompts README
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs
python3 - <<'PY'
p='prompts/README.md'
s=open(p,encoding='utf-8').read()

old="| 6 | Los complementos **`ia01`–`ia08`** y **`ds01`–`ds09`**, en ese orden | Construyen los cuatro proyectos de IA y datos sobre el código del camino base. El prompt sale de `prompts-de-tracks-ia-ds.md` |"
new="""| 6 | Los complementos **`ia01`–`ia08`** y **`ds01`–`ds09`**, en ese orden | Construyen los cuatro proyectos de IA y datos sobre el código del camino base. El prompt sale de `prompts-de-tracks-ia-ds.md` |

### Las tandas del turno 6

Una tanda es **un chat**. El turno 6 es demasiado grande para uno solo, así que se parte en
catorce: **T0–T5 son el track `ia`, y están cerradas**; **T6–T13 son el track `ds`**.

| Tanda | Qué produce | Por qué esa frontera |
|---|---|---|
| T0–T5 ✅ | El track `ia` entero: `ia01`–`ia08`, su `src/`, sus generadores y 134 pruebas | Cerradas el 13/09/2026 |
| **T6** 🚧 | **Maquinaria de datos.** Los dos conjuntos seudonimizados con semilla fija —Embudo en `src/ds01-…/`, Ausentismo en `src/ds07-…/`—, su esquema congelado y sus pruebas. **Sin prosa publicada** | `ds01`–`ds06` leen el mismo conjunto. Si el esquema cambia en `ds04`, hay que reescribir tres secciones. En `ia` esto se pagó caro: la colisión de nombres del generador de corpus hizo que el manifiesto mintiera |
| **T7** | `ds01` + `ds02` | Fijan el registro del track y el arnés de memoria que `ds03` reutiliza. La tesis de `ds02` es la respuesta a la de `ds01` |
| **T8** | `ds03` | Sola: cuatro motores por cuatro tamaños es la medición más cara del track, y puede obligar a matizar `ds02` |
| **T9** | `ds04` · **Proyecto Embudo** | Solo: importa las tres anteriores y sostiene dos atribuciones sobre los mismos datos |
| **T10** | `ds05` + `ds06` | `ds06` mide los cuadernos que producen `ds04` y `ds05`. Cierran el bloque Embudo |
| **T11** | `ds07` | Sola: fija la línea base que `ds08` tiene que vencer. Escribirla junto a `ds08` la contamina |
| **T12** | `ds08` · **Proyecto Ausentismo** | Solo: `torch` en CPU y la ética en el cuerpo del capítulo |
| **T13** | `ds09` + cierre del track | El ⚖️ veredicto necesita todas las mediciones hechas, y arrastra `BENCHMARKS.md`, `INSTINTOS.md`, el `README.md` del curso y `0-ESTRUCTURA-CURSO.md` |

📝 **Dos decisiones que T6 cierra** y que ninguna sección posterior reabre: los tamaños grandes de
la medición de `ds01` **son sintéticos y se declara** —Áurea hace 3.900 citas al mes, y el archivo
grande del camino base tiene 500.000 filas—; y los generadores **escriben archivos a `data/`**,
de modo que las demás secciones leen archivos y **no importan módulos de otro directorio de
sección**."""
assert s.count(old)==1
s=s.replace(old,new)

s=s.replace("""> ✅ **Track `ia` cerrado el 13/09/2026** — ocho secciones, su `src/`, sus generadores de datos y
> 134 pruebas. 🚧 **Track `ds` pendiente.**""",
"""> ✅ **Track `ia` cerrado el 13/09/2026** — ocho secciones, su `src/`, sus generadores de datos y
> 134 pruebas. 🚧 **Track `ds` pendiente, repartido en ocho tandas (T6–T13)**; la tabla está
> más abajo, en *Cómo abrir una sesión de escritura*.""")
open(p,'w',encoding='utf-8').write(s)
print("OK")
PY

# --- 2026-09-13T19:54:42 · Read ia generator and README for style
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs/src
sed -n 1,60p ia04-embeddings-y-busqueda-semantica/generar_corpus.py; echo "##### README ia04"; cat ia04-embeddings-y-busqueda-semantica/README.md

# --- 2026-09-13T19:55:21 · Read code style section of guide
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs
sed -n '/## 4\./,/## 5\./p' prompts/guia-de-estilo-y-convenciones.md | head -70

# --- 2026-09-13T19:55:26 · Read source language rule
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs
sed -n '/## 5. Idioma del código fuente/,/## 6\./p' prompts/guia-de-estilo-y-convenciones.md

# --- 2026-09-13T19:58:33 · Run the Embudo generator once
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs/src/ds01-numpy-y-el-modelo-vectorizado && time python3 generar_embudo.py --salida /tmp/claude-501/-Users-oskar-Developer-Learning-courses-ia-generated/2859734a-d7e6-4986-b771-4890bf56e42b/scratchpad/embudo 2>&1 | tail -20

# --- 2026-09-13T19:58:40 · Run generator tests
python3 -m pytest test_generar_embudo.py -q 2>&1 | tail -40

# --- 2026-09-13T19:58:45 · Look for existing venv or uv
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs; ls .venv 2>/dev/null; cat .pytest_cache/CACHEDIR.TAG 2>/dev/null | head -2; which -a python3.14 python3.13 uv pytest 2>/dev/null

# --- 2026-09-13T19:58:47 · Run tests with uv
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs/src/ds01-numpy-y-el-modelo-vectorizado && uv run --python 3.14 --with pytest python -m pytest test_generar_embudo.py -q 2>&1 | tail -40

# --- 2026-09-13T20:00:23 · Run the Ausentismo generator
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs/src/ds07-scikit-learn && time python3 generar_ausentismo.py --salida /tmp/claude-501/-Users-oskar-Developer-Learning-courses-ia-generated/2859734a-d7e6-4986-b771-4890bf56e42b/scratchpad/aus 2>&1 | tail

# --- 2026-09-13T20:00:33 · Fix date range bug and rerun
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs/src/ds07-scikit-learn
python3 - <<'PY'
p='generar_ausentismo.py'; s=open(p,encoding='utf-8').read()
old="""            day = entry + timedelta(days=30 * (month - 1) + rng.randint(-3, 3))
            if day > END or day.weekday() == 6 or is_holy_week(day):
                continue"""
new="""            # El jitter de la cita puede empujar la primera fuera del rango por abajo:
            # `entry` puede ser el propio 1 de enero y el sorteo restar tres días. Se
            # descarta en vez de recortarse, porque recortar amontona citas en el borde.
            day = entry + timedelta(days=30 * (month - 1) + rng.randint(-3, 3))
            if not START <= day <= END or day.weekday() == 6 or is_holy_week(day):
                continue"""
assert s.count(old)==1
open(p,'w',encoding='utf-8').write(s.replace(old,new)); print("OK")
PY
time python3 generar_ausentismo.py --salida /tmp/claude-501/-Users-oskar-Developer-Learning-courses-ia-generated/2859734a-d7e6-4986-b771-4890bf56e42b/scratchpad/aus 2>&1 | tail

# --- 2026-09-13T20:00:48 · Calibrate no-show rate
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs/src/ds07-scikit-learn
python3 - <<'PY'
import importlib, random, math
import generar_ausentismo as g
def rate(intercept, wprior, seed=20260913):
    g.INTERCEPT=intercept; g.W_PRIOR_NO_SHOWS=wprior
    rng=random.Random(seed)
    w=g.build_weather(rng); p=g.build_patients(rng,1200)
    rows=g.build_appointments(rng,p,w)
    ns=sum(1-r["asistio"] for r in rows)
    return ns/len(rows), len(rows)
for wp in (-0.35,-0.45):
    for ic in (1.6,2.0,2.4,2.8):
        r,n=rate(ic,wp); print(f"w={wp} ic={ic} -> {r:.3f} ({n} filas)")
PY

# --- 2026-09-13T20:01:04 · Test saturated prior effect
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs/src/ds07-scikit-learn
python3 - <<'PY'
import random, math, generar_ausentismo as g
src=open('generar_ausentismo.py').read()
# monkeypatch: reemplazo la función con versión saturada
def make(intercept, wprior, cap):
    def build(rng, patients, weather):
        rows=[]
        for patient in patients:
            entry=g.START+g.timedelta(days=rng.randint(0,640))
            months=rng.randint(4,26)
            ab=rng.randint(5,20) if rng.random()<0.11 else months+1
            pv=pn=0
            for month in range(1,min(months,ab)+1):
                day=entry+g.timedelta(days=30*(month-1)+rng.randint(-3,3))
                if not g.START<=day<=g.END or day.weekday()==6 or g.is_holy_week(day): continue
                hour=rng.choices(range(7,19),[4,7,9,10,9,6,5,8,10,11,9,6])[0]
                rng.choice((0,20,40)); lead=rng.randint(3,45)
                rain=weather[(patient["zona"],day)]
                th=int(day.weekday()==3 and hour>=16)
                logit=(intercept+wprior*min(pn,cap)-0.55*th-0.024*rain-0.045*patient["distancia_km"]
                       -0.011*lead-0.030*rain*patient["distancia_km"]+patient["propension_base"])
                a=int(rng.random()<1/(1+math.exp(-logit)))
                rng.choices(g.VISIT_TYPES,g.VISIT_WEIGHTS)
                rows.append(a); pv+=1; pn+=1-a
        return rows
    return build
for cap in (2,3):
    for ic in (1.4,1.7,2.0,2.3):
        rng=random.Random(20260913); w=g.build_weather(rng); p=g.build_patients(rng,1500)
        rows=make(ic,-0.62,cap)(rng,p,w)
        print(f"cap={cap} ic={ic} -> {1-sum(rows)/len(rows):.3f}  n={len(rows)}")
PY

# --- 2026-09-13T20:01:20 · Wider calibration scan
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs/src/ds07-scikit-learn
python3 - <<'PY'
import random, math, generar_ausentismo as g
def run(intercept,wprior,cap,n=1500,seed=20260913):
    rng=random.Random(seed); weather=g.build_weather(rng); patients=g.build_patients(rng,n)
    tot=att=0; th_no=th_n=0
    for patient in patients:
        entry=g.START+g.timedelta(days=rng.randint(0,640)); months=rng.randint(4,26)
        ab=rng.randint(5,20) if rng.random()<0.11 else months+1
        pn=0
        for month in range(1,min(months,ab)+1):
            day=entry+g.timedelta(days=30*(month-1)+rng.randint(-3,3))
            if not g.START<=day<=g.END or day.weekday()==6 or g.is_holy_week(day): continue
            hour=rng.choices(range(7,19),[4,7,9,10,9,6,5,8,10,11,9,6])[0]
            rng.choice((0,20,40)); lead=rng.randint(3,45)
            rain=weather[(patient["zona"],day)]; th=int(day.weekday()==3 and hour>=16)
            logit=(intercept+wprior*min(pn,cap)-0.55*th-0.024*rain-0.045*patient["distancia_km"]
                   -0.011*lead-0.030*rain*patient["distancia_km"]+patient["propension_base"])
            a=int(rng.random()<1/(1+math.exp(-logit))); rng.choices(g.VISIT_TYPES,g.VISIT_WEIGHTS)
            tot+=1; att+=a; pn+=1-a
            if th: th_n+=1; th_no+=1-a
    return 1-att/tot, th_no/max(th_n,1)
for wp in (-0.30,-0.40):
    for ic in (2.6,3.0,3.4,3.8):
        r,th=run(ic,wp,3); print(f"w={wp} ic={ic} -> global {r:.3f} · jueves tarde {th:.3f}")
PY

# --- 2026-09-13T20:01:42 · Calibrate weights and regenerate
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs/src/ds07-scikit-learn
python3 - <<'PY'
p='generar_ausentismo.py'; s=open(p,encoding='utf-8').read()
old="""# Los pesos del proceso real. `ds07` no los ve —los descubre—, pero quien escriba el
# capítulo necesita saber cuál es la respuesta correcta para poder decir si el modelo la
# encontró. El intercepto está calibrado para que la inasistencia global quede en 19%,
# que es el dato del dominio.
INTERCEPT = 1.98
W_PRIOR_NO_SHOWS = -0.62      # la variable que más pesa, y de lejos
W_THURSDAY_LATE = -0.55       # el jueves a las cuatro, que es la pregunta operativa
W_RAIN = -0.024               # por milímetro
W_DISTANCE = -0.045           # por kilómetro
W_LEAD_TIME = -0.011          # por día entre que se agenda y la cita
W_INTERACTION = -0.030        # lluvia × distancia: la única no linealidad, y es débil"""
new="""# Los pesos del proceso real. `ds07` no los ve —los descubre—, pero quien escriba el
# capítulo necesita saber cuál es la respuesta correcta para poder decir si el modelo la
# encontró. El intercepto está **calibrado numéricamente** para que la inasistencia global
# quede en el 19% del dominio: se buscó, no se supuso.
INTERCEPT = 3.40
W_PRIOR_NO_SHOWS = -0.40      # la variable que más pesa, y de lejos
W_THURSDAY_LATE = -0.55       # el jueves a las cuatro, que es la pregunta operativa
W_RAIN = -0.024               # por milímetro
W_DISTANCE = -0.045           # por kilómetro
W_LEAD_TIME = -0.011          # por día entre que se agenda y la cita
W_INTERACTION = -0.030        # lluvia × distancia: la única no linealidad, y es débil

# El historial satura: la tercera inasistencia ya no dice nada que la segunda no dijera.
# Sin este tope, el efecto se acumula sobre sí mismo —quien falta tiene más probabilidad
# de faltar, que a su vez sube el conteo— y la red entera termina en 54% de inasistencia,
# que es lo que pasó en la primera versión de este generador. El tope no es un parche de
# calibración: es la forma que tiene el fenómeno, y `ds07` lo va a encontrar en los datos.
PRIOR_NO_SHOW_CAP = 3"""
assert s.count(old)==1
s=s.replace(old,new)
old2="""                     + W_PRIOR_NO_SHOWS * prior_no_shows"""
new2="""                     + W_PRIOR_NO_SHOWS * min(prior_no_shows, PRIOR_NO_SHOW_CAP)"""
assert s.count(old2)==1
open(p,'w',encoding='utf-8').write(s.replace(old2,new2)); print("OK")
PY
python3 generar_ausentismo.py --salida /tmp/claude-501/-Users-oskar-Developer-Learning-courses-ia-generated/2859734a-d7e6-4986-b771-4890bf56e42b/scratchpad/aus 2>&1 | tail -3

# --- 2026-09-13T20:01:56 · Scale patients to match network volume
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs/src/ds07-scikit-learn
python3 - <<'PY'
p='generar_ausentismo.py'; s=open(p,encoding='utf-8').read()
old='''    parser.add_argument("--pacientes", type=int, default=4200)'''
new='''    # 10.500 pacientes con planes de 4 a 26 meses dejan unos 3.900 citas al mes activas,
    # que es el volumen que la historia de Áurea declara para la red. El número de
    # pacientes es el parámetro; el de citas al mes es la restricción que lo fija.
    parser.add_argument("--pacientes", type=int, default=10_500)'''
assert s.count(old)==1
open(p,'w',encoding='utf-8').write(s.replace(old,new)); print("OK")
PY
time python3 generar_ausentismo.py --salida /tmp/claude-501/-Users-oskar-Developer-Learning-courses-ia-generated/2859734a-d7e6-4986-b771-4890bf56e42b/scratchpad/aus 2>&1 | tail -3
head -2 /tmp/claude-501/-Users-oskar-Developer-Learning-courses-ia-generated/2859734a-d7e6-4986-b771-4890bf56e42b/scratchpad/aus/citas_historicas.csv

# --- 2026-09-13T20:02:56 · Run ausentismo generator tests
uv run --python 3.14 --with pytest python -m pytest test_generar_ausentismo.py -q 2>&1 | tail -40

# --- 2026-09-13T20:03:13 · Spread patient entry across full range and retest
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs/src/ds07-scikit-learn
python3 - <<'PY'
p='generar_ausentismo.py'; s=open(p,encoding='utf-8').read()
old="""        # Cada paciente entra al plan en un mes distinto y asiste a controles mensuales.
        entry = START + timedelta(days=rng.randint(0, 640))"""
new="""        # Cada paciente entra al plan en un mes distinto y asiste a controles mensuales.
        # La entrada se reparte por **todo** el rango, no solo por los primeros meses:
        # Áurea no deja de captar pacientes en 2025, y cortar las altas antes del final
        # adelgaza el tramo de prueba de `ds07` justo donde se mide.
        entry = START + timedelta(days=rng.randint(0, (END - START).days))"""
assert s.count(old)==1
open(p,'w',encoding='utf-8').write(s.replace(old,new)); print("OK")
PY
uv run --python 3.14 --with pytest python -m pytest test_generar_ausentismo.py -q 2>&1 | tail -20
python3 generar_ausentismo.py --salida /tmp/claude-501/-Users-oskar-Developer-Learning-courses-ia-generated/2859734a-d7e6-4986-b771-4890bf56e42b/scratchpad/aus 2>&1|head -1

# --- 2026-09-13T20:03:24 · Scale to network volume and verify
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs/src/ds07-scikit-learn
sed -i '' 's/# 10.500 pacientes con planes de 4 a 26 meses dejan unos 3.900 citas al mes activas,/# 12.400 pacientes con planes de 4 a 26 meses dejan unas 3.900 citas al mes activas,/; s/default=10_500/default=12_400/' generar_ausentismo.py
time python3 generar_ausentismo.py --salida /tmp/claude-501/-Users-oskar-Developer-Learning-courses-ia-generated/2859734a-d7e6-4986-b771-4890bf56e42b/scratchpad/aus 2>&1|head -1
python3 - <<'PY'
from datetime import date
p="/tmp/claude-501/-Users-oskar-Developer-Learning-courses-ia-generated/2859734a-d7e6-4986-b771-4890bf56e42b/scratchpad/aus/citas_historicas.csv"
rows=open(p).read().splitlines()[1:]
n=len(rows); print(f"{n/27:.0f} citas/mes")
PY

# --- 2026-09-13T20:03:31 · Lint the new generators
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs
ls ruff.toml pyproject.toml 2>/dev/null; uvx ruff@0.16.7 check src/ds01-numpy-y-el-modelo-vectorizado src/ds07-scikit-learn 2>&1 | tail -20

# --- 2026-09-13T20:03:44 · Show full lint output and config
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs
cat ruff.toml 2>/dev/null || echo "(sin ruff.toml en la raíz del curso)"
uvx ruff@0.16.7 check src/ds01-numpy-y-el-modelo-vectorizado src/ds07-scikit-learn 2>&1 | head -40

# --- 2026-09-13T20:03:49 · Apply ruff fixes
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs
uvx ruff@0.16.7 check --fix src/ds01-numpy-y-el-modelo-vectorizado src/ds07-scikit-learn 2>&1 | tail -20
echo "--- SIM113 restante ---"
uvx ruff@0.16.7 check src/ds01-numpy-y-el-modelo-vectorizado src/ds07-scikit-learn 2>&1 | tail -20

# --- 2026-09-13T20:04:01 · Fix lint and run both suites
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs/src/ds07-scikit-learn
python3 - <<'PY'
p='test_generar_ausentismo.py'; s=open(p,encoding='utf-8').read()
old="""        rows.sort(key=lambda row: (row["fecha"], row["hora"]))
        visits = misses = 0
        for row in rows:
            assert int(row["citas_previas"]) == visits, patient_id
            assert int(row["inasistencias_previas"]) == misses, patient_id
            visits += 1
            misses += 1 - int(row["asistio"])"""
new="""        rows.sort(key=lambda row: (row["fecha"], row["hora"]))
        misses = 0
        for visits, row in enumerate(rows):
            assert int(row["citas_previas"]) == visits, patient_id
            assert int(row["inasistencias_previas"]) == misses, patient_id
            misses += 1 - int(row["asistio"])"""
assert s.count(old)==1
open(p,'w',encoding='utf-8').write(s.replace(old,new)); print("OK")
PY
cd .. && uvx ruff@0.16.7 check ds01-numpy-y-el-modelo-vectorizado ds07-scikit-learn && echo "LINT OK"
cd ds01-numpy-y-el-modelo-vectorizado && uv run --python 3.14 --with pytest python -m pytest -q 2>&1|tail -3
cd ../ds07-scikit-learn && uv run --python 3.14 --with pytest python -m pytest -q 2>&1|tail -3

# --- 2026-09-13T20:05:29 · Mark T6 closed in prompts docs
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs
python3 - <<'PY'
# 1) prompts-de-tracks-ia-ds.md: el punto abierto nº3 ya está resuelto
p='prompts/prompts-de-tracks-ia-ds.md'; s=open(p,encoding='utf-8').read()
old="""3. **El conjunto de datos seudonimizado de `ds` hay que generarlo**, como se generaron los del
   camino base: un script con semilla fija en `src/ds01-…/`, con la estacionalidad real de Áurea
   —enero y febrero de ortodoncia, noviembre y diciembre de estética, el agujero de Semana
   Santa— y sin un solo dato clínico."""
new="""3. ✅ **Los conjuntos de datos de `ds` están generados (T6, 13/09/2026).** Son dos, no uno, y
   cada uno vive en el `src/` de la sección que lo estrena:

   - `src/ds01-numpy-y-el-modelo-vectorizado/generar_embudo.py` — el Embudo: pauta, toques,
     leads, etapas, planes, cuotas y aliados. Ocho CSV, ~32.500 leads, con la estacionalidad de
     Áurea y la Semana Santa **calculada** por año. 28 pruebas.
   - `src/ds07-scikit-learn/generar_ausentismo.py` — el histórico de citas con su clima.
     ~105.600 citas, 3.900 al mes, **19,3% de inasistencia** calibrado numéricamente. 19 pruebas.

   Semilla fija, solo biblioteca estándar, cero datos clínicos y salida reproducible byte a byte.
   Las demás secciones **leen archivos de `data/`**; ninguna importa un módulo de otro directorio
   de sección. El esquema queda congelado aquí: si una sección necesita una columna nueva, se
   agrega al generador y se vuelve a correr la suite, no se inventa en el capítulo.

   Dos decisiones que esos generadores cierran y que ninguna sección reabre: los tamaños grandes
   de la medición de `ds01` salen de `--escala` y **son sintéticos declarados** —Áurea no tiene
   cinco millones de filas—, y el proceso que genera el ausentismo es **casi lineal a propósito**,
   porque es lo que hace que la tesis de `ds08` —la línea base gana— sea comprobable en vez de
   proclamada."""
assert s.count(old)==1
open(p,'w',encoding='utf-8').write(s.replace(old,new)); print("OK tracks")

# 2) prompts/README.md: T6 cerrada
p='prompts/README.md'; s=open(p,encoding='utf-8').read()
old="""| **T6** 🚧 | **Maquinaria de datos.**"""
new="""| **T6** ✅ | **Maquinaria de datos**, cerrada el 13/09/2026: los dos generadores, sus dos `README.md` y **47 pruebas** que corren sin dependencias."""
assert s.count(old)==1
s=s.replace(old,new+" Lo que encargaba:")
s=s.replace("""> ✅ **Track `ia` cerrado el 13/09/2026** — ocho secciones, su `src/`, sus generadores de datos y
> 134 pruebas. 🚧 **Track `ds` pendiente, repartido en ocho tandas (T6–T13)**; la tabla está
> más abajo, en *Cómo abrir una sesión de escritura*.""",
"""> ✅ **Track `ia` cerrado el 13/09/2026** — ocho secciones, su `src/`, sus generadores de datos y
> 134 pruebas. 🚧 **Track `ds` en curso, repartido en ocho tandas (T6–T13)**: **T6 —los dos
> conjuntos de datos y sus 47 pruebas— está cerrada**, y la siguiente es T7 (`ds01` y `ds02`).
> La tabla está más abajo, en *Cómo abrir una sesión de escritura*.""")
open(p,'w',encoding='utf-8').write(s); print("OK readme")
PY
sed -n '/### Las tandas del turno 6/,/^📝/p' prompts/README.md | head -14

# --- 2026-09-13T20:05:37 · Polish the T6 row
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs
python3 - <<'PY'
p='prompts/README.md'; s=open(p,encoding='utf-8').read()
old="**47 pruebas** que corren sin dependencias. Lo que encargaba: Los dos conjuntos seudonimizados con semilla fija —Embudo en `src/ds01-…/`, Ausentismo en `src/ds07-…/`—, su esquema congelado y sus pruebas. **Sin prosa publicada**"
new="**47 pruebas** que corren sin dependencias. Encargaba los dos conjuntos seudonimizados con semilla fija —Embudo en `src/ds01-…/`, Ausentismo en `src/ds07-…/`—, su esquema congelado y sus pruebas, **sin prosa publicada**"
assert s.count(old)==1
open(p,'w',encoding='utf-8').write(s.replace(old,new)); print("OK")
PY
git -C /Users/oskar/Developer/Learning/courses-ia-generated status --short cursos-algoritmos-lenguajes/python-for-java-devs | head

# --- 2026-09-13T20:05:49 · Update project memory with T6
cd /Users/oskar/.claude/projects/-Users-oskar-Developer-Learning-courses-ia-generated/memory
python3 - <<'PY'
p='python-java-devs-estado.md'; s=open(p,encoding='utf-8').read()
old="**Lo siguiente es el track `ds` entero** (`ds01`–`ds09`)."
new="""**El track `ds` se reparte en ocho tandas, T6–T13**, definidas el 13/09/2026 en
`prompts/README.md` (§Cómo abrir una sesión de escritura → *Las tandas del turno 6*): T6
maquinaria de datos · T7 `ds01`+`ds02` · T8 `ds03` · T9 `ds04` · T10 `ds05`+`ds06` · T11 `ds07` ·
T12 `ds08` · T13 `ds09`+cierre. **T6 está cerrada**: `generar_embudo.py` (ocho CSV, ~32.500 leads,
Semana Santa calculada por año, atribución ambigua por construcción) en `src/ds01-…/` y
`generar_ausentismo.py` (~105.600 citas, 3.900/mes, 19,3% de inasistencia calibrado
numéricamente, con `inasistencias_totales_paciente` como fuga deliberada) en `src/ds07-…/`, más
sus dos README y **47 pruebas sin dependencias**. Dos decisiones cerradas ahí: los tamaños
grandes de `ds01` salen de `--escala` y son **sintéticos declarados**, y el proceso del ausentismo
es **casi lineal a propósito** para que la tesis de `ds08` sea comprobable. Dos bugs reales en T6:
el jitter de la primera cita se salía del rango por abajo, y el efecto acumulado del historial se
realimentaba hasta dejar la red en 54% de inasistencia (se resolvió con tope de saturación).
**Lo siguiente es T7.**"""
assert s.count(old)==1
open(p,'w',encoding='utf-8').write(s.replace(old,new)); print("OK")
PY

# --- 2026-09-13T20:06:28 · Read the chapter template
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs/prompts && wc -l plantillas-de-capitulo.md formato-de-miniproyectos.md formato-de-mediciones.md guia-de-estilo-y-convenciones.md && cat plantillas-de-capitulo.md

# --- 2026-09-13T20:06:30 · Read measurement and miniproject formats
cat formato-de-mediciones.md && echo "#################### MINIPROYECTOS" && cat formato-de-miniproyectos.md

# --- 2026-09-13T20:06:37 · Read common frame of the ia/ds tracks
sed -n '/^## § Marco común/,/^## # ia01/p' prompts-de-tracks-ia-ds.md

# --- 2026-09-13T20:06:42 · Read style guide part 1
sed -n '1,200p' guia-de-estilo-y-convenciones.md

# --- 2026-09-13T20:06:44 · Read style guide sections 6-10
sed -n '/^## 6\. El estilo de código del curso/,/^## 11\./p' guia-de-estilo-y-convenciones.md

# --- 2026-09-13T20:06:50 · Inspect an existing ia section structure
cd .. && sed -n 1,60p ia04-embeddings-y-busqueda-semantica.md && echo "......" && grep -n "^#\{1,3\} \|^\*\*🟢\|^\*\*🟡\|^\*\*🟠\|^\*\*🔴\|^\*\*🔥" ia04-embeddings-y-busqueda-semantica.md

# --- 2026-09-13T20:06:55 · Read measurement and miniproject of ia04
sed -n 527,660p ia04-embeddings-y-busqueda-semantica.md

# --- 2026-09-13T20:06:59 · Read closing block and the course harness
sed -n 752,800p ia04-embeddings-y-busqueda-semantica.md; echo "########## ARNÉS"; cat src/02-secuencias-perezosas/bench.py

# --- 2026-09-13T20:07:25 · See how ia sections reuse the harness
sed -n 1,45p src/ia04-embeddings-y-busqueda-semantica/bench_retrieval.py; echo "=== import bench en ia ==="; grep -rn "from bench import\|import bench" src/ | head

# --- 2026-09-13T20:07:44 · Read BENCHMARKS header and reference environment
sed -n 1,60p BENCHMARKS.md

# --- 2026-09-13T20:07:53 · Check machine specs and numpy availability
sysctl -n hw.model hw.ncpu hw.memsize 2>/dev/null; sw_vers 2>/dev/null; python3.14 -VV; uv run --python 3.14 --with 'numpy==2.5.3' python -c "import numpy,sys;print(numpy.__version__, sys.version)" 2>&1 | tail -3

# --- 2026-09-13T20:10:14 · Refactor and smoke-test the benchmark
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs/src/ds01-numpy-y-el-modelo-vectorizado
python3 - <<'PY'
# acquisition.py: extraer arrays_from_rows
p='acquisition.py'; s=open(p,encoding='utf-8').read()
old='''    rows = read_spend_rows(path)
    channels = sorted({row["canal"] for row in rows})
    index = {channel: code for code, channel in enumerate(channels)}

    return SpendArrays(
        channel_codes=np.fromiter((index[row["canal"]] for row in rows),
                                  dtype=np.int64, count=len(rows)),
        cost=np.fromiter((int(row["costo_cop"]) for row in rows),
                         dtype=PESOS, count=len(rows)),
        clicks=np.fromiter((int(row["clics"]) for row in rows),
                           dtype=np.int64, count=len(rows)),
        channels=channels,
    )'''
new='''    return arrays_from_rows(read_spend_rows(path))


def arrays_from_rows(rows: list[dict[str, str]]) -> SpendArrays:
    """Las columnas a partir de filas que ya están en memoria.

    Existe separada de `read_spend_arrays` por la medición: la sección 6 compara las tres
    versiones **sobre las mismas filas**, y volver a leer el CSV para la versión vectorizada
    metería el disco dentro del número.
    """
    channels = sorted({row["canal"] for row in rows})
    index = {channel: code for code, channel in enumerate(channels)}

    return SpendArrays(
        channel_codes=np.fromiter((index[row["canal"]] for row in rows),
                                  dtype=np.int64, count=len(rows)),
        cost=np.fromiter((int(row["costo_cop"]) for row in rows),
                         dtype=PESOS, count=len(rows)),
        clicks=np.fromiter((int(row["clics"]) for row in rows),
                           dtype=np.int64, count=len(rows)),
        channels=channels,
    )'''
assert s.count(old)==1
open(p,'w',encoding='utf-8').write(s.replace(old,new)); print("acquisition OK")

# bench: usar arrays_from_rows y borrar build_arrays
p='bench_vectorized.py'; s=open(p,encoding='utf-8').read()
s=s.replace("""from acquisition import (
    cost_per_acquisition_comprehension,""","""from acquisition import (
    arrays_from_rows,
    cost_per_acquisition_comprehension,""")
s=s.replace("        spend = build_arrays(rows)","        spend = arrays_from_rows(rows)")
start=s.index("def build_arrays(")
end=s.index("def assert_same_answer(")
s=s[:start]+s[end:]
open(p,'w',encoding='utf-8').write(s); print("bench OK")
PY
cp ../02-secuencias-perezosas/bench.py .
mkdir -p data && python3 generar_embudo.py --salida data >/dev/null && uv run --python 3.14 --with 'numpy==2.5.3' python bench_vectorized.py --filas 1000 100000 2>&1 | tail -25

# --- 2026-09-13T20:10:46 · Improve table resolution and re-run
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs/src/ds01-numpy-y-el-modelo-vectorizado
python3 - <<'PY'
p='bench_vectorized.py'; s=open(p,encoding='utf-8').read()
s=s.replace("    read_acquisitions,\n    read_spend_arrays,\n    read_spend_rows,","    read_acquisitions,\n    read_spend_rows,")
s=s.replace("""try:
    from bench import environment, measure, render
except ModuleNotFoundError:""","""try:
    from bench import environment, measure
except ModuleNotFoundError:""")
s=s.replace('''def tile_rows(rows: list[dict[str, str]], size: int) -> list[dict[str, str]]:
    """Repite las filas reales hasta llegar al tamaño pedido, y recorta."""''',
'''def render_table(results: list[dict]) -> str:
    """La tabla de esta sección, con tres decimales de milisegundo.

    El `render` del arnés imprime milisegundos enteros, que es lo correcto para la Fase 02
    —donde lo que se mide tarda segundos— y aquí dejaría una columna de ceros: a mil filas
    las tres versiones están por debajo del milisegundo. Se extiende el formato, **no el
    arnés**: `measure` sigue siendo el mismo y los números siguen siendo comparables con los
    del resto del curso.
    """
    lines = [f"{'opción':<16}{'mediana':>12}{'p95':>12}{'pico':>11}"]
    for result in results:
        lines.append(
            f"{result['etiqueta']:<16}{result['mediana_ms']:>9.3f} ms"
            f"{result['p95_ms']:>9.3f} ms{result['pico_mb']:>8.2f} MB")
    return "\\n".join(lines)


def tile_rows(rows: list[dict[str, str]], size: int) -> list[dict[str, str]]:
    """Repite las filas reales hasta llegar al tamaño pedido, y recorta.

    ⚠️ Lo que repite son **referencias al mismo diccionario**, no copias. Por eso la
    columna de memoria de la tabla mide lo que asigna el cálculo, no lo que ocupa tener los
    datos: tener cinco millones de filas de verdad en memoria cuesta gigas, y ese costo es
    el tema de `ds02`, no de esta sección.
    """''')
s=s.replace("        print(render(results))","        print(render_table(results))")
open(p,'w',encoding='utf-8').write(s); print("OK")
PY
uv run --python 3.14 --with 'numpy==2.5.3' python bench_vectorized.py --filas 1000 100000 2>&1 | tail -16

# --- 2026-09-13T20:11:05 · Run the full ds01 measurement
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs/src/ds01-numpy-y-el-modelo-vectorizado
python3 - <<'PY'
p='bench_vectorized.py'; s=open(p,encoding='utf-8').read()
old="""        results = [
            measure("bucle", lambda: cost_per_acquisition_loop(rows, acquisitions),
                    repetitions),
            measure("vectorizado",
                    lambda: cost_per_acquisition_vectorized(spend, acquisitions),
                    repetitions),
        ]"""
new="""        results = [
            measure("bucle", lambda: cost_per_acquisition_loop(rows, acquisitions),
                    repetitions),
            # Las dos filas vectorizadas son la parte honesta de esta tabla. La primera
            # asume que los datos YA están en columnas; la segunda paga la conversión desde
            # la lista de diccionarios, que es de donde salen de verdad cuando vienen de un
            # CSV. Publicar solo la primera sería comparar una función contra un programa.
            measure("vectorizado",
                    lambda: cost_per_acquisition_vectorized(spend, acquisitions),
                    repetitions),
            measure("vectorizado+conv",
                    lambda: cost_per_acquisition_vectorized(arrays_from_rows(rows),
                                                            acquisitions),
                    repetitions),
        ]"""
assert s.count(old)==1
open(p,'w',encoding='utf-8').write(s.replace(old,new)); print("OK")
PY
time uv run --python 3.14 --with 'numpy==2.5.3' python bench_vectorized.py --filas 1000 10000 100000 1000000 5000000 2>&1 | tail -45

# --- 2026-09-13T20:11:50 · Get overflow and view/copy numbers
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs/src/ds01-numpy-y-el-modelo-vectorizado
uv run --python 3.14 --with 'numpy==2.5.3' python - <<'PY'
import numpy as np
from acquisition import read_spend_arrays, total_spend_with_dtype, read_spend_rows, arrays_from_rows
from pathlib import Path
s = read_spend_arrays(Path("data/pauta.csv"))
print("filas reales:", len(s))
print("int64:", f"{total_spend_with_dtype(s, np.int64):,}")
print("int32:", f"{total_spend_with_dtype(s, np.int32):,}")
# ¿a partir de cuántas filas se rompe int32?
import itertools
cost = s.cost
run = np.cumsum(cost)
bad = np.argmax(run > 2**31-1)
print("primera fila donde int32 desborda:", bad, "· acumulado:", f"{int(run[bad]):,}")
# vistas y copias
a = s.cost[:5].copy()
view = s.cost[:5]
print("vista antes:", s.cost[:5])
view[:] = 0
print("original después de tocar la vista:", s.cost[:5])
s.cost[:5] = a
print("restaurado:", s.cost[:5])
PY

# --- 2026-09-13T20:12:25 · Run ds01 computation tests
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs/src/ds01-numpy-y-el-modelo-vectorizado
uv run --python 3.14 --with pytest --with 'numpy==2.5.3' python -m pytest test_acquisition.py -q 2>&1 | tail -25

# --- 2026-09-13T20:17:22 · Verify per-channel figures quoted in the chapter
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs/src/ds01-numpy-y-el-modelo-vectorizado
uv run --python 3.14 --with 'numpy==2.5.3' python - <<'PY'
import sys, numpy as np
from pathlib import Path
from acquisition import *
rows = read_spend_rows(Path("data/pauta.csv"))
sp = arrays_from_rows(rows)
acq = read_acquisitions(Path("data/leads.csv"), Path("data/etapas.csv"))
r = cost_per_acquisition_loop(rows, acq)
for k in sorted(r, key=lambda k:-r[k]): print(f"{k:10s} {r[k]:>15,.0f}  (adq {acq[k]})")
print("getsizeof lista:", sys.getsizeof(list(range(1_000_000)))/1e6, "MB")
print("nbytes array:", np.arange(1_000_000, dtype=np.int64).nbytes/1e6, "MB")
print("int32 demo:", np.array([2_000_000_000,2_000_000_000],dtype=np.int32).sum())
PY

# --- 2026-09-13T20:17:45 · Check int32 overflow semantics precisely
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs/src/ds01-numpy-y-el-modelo-vectorizado
uv run --python 3.14 --with 'numpy==2.5.3' python -W error::RuntimeWarning - <<'PY'
import numpy as np, warnings
a = np.array([2_000_000_000, 2_000_000_000], dtype=np.int32)
print("sum() por defecto:", a.sum(), a.sum().dtype)
print("sum(dtype=int32):", a.sum(dtype=np.int32))
with warnings.catch_warnings(record=True) as w:
    warnings.simplefilter("always")
    b = a + a
    print("a+a:", b, b.dtype, "· avisos:", [str(x.message) for x in w])
PY

# --- 2026-09-13T20:17:58 · Measure real memory of a million ints
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs/src/ds01-numpy-y-el-modelo-vectorizado
uv run --python 3.14 --with 'numpy==2.5.3' python - <<'PY'
import sys
xs=list(range(1_000_000))
print("objetos:", sum(sys.getsizeof(x) for x in xs)/1e6, "MB · un int:", sys.getsizeof(10**6))
PY

# --- 2026-09-13T20:18:30 · Correct figures and claims in ds01
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs
python3 - <<'PY'
p='ds01-numpy-y-el-modelo-vectorizado.md'; s=open(p,encoding='utf-8').read()

# 1. Las cifras reales de costo por adquisición
old="""Y la pregunta de Marcela es una división: **cuánto gasté en cada canal, dividido por cuántos
pacientes trajo ese canal**. Con el `csv` de la Fase 06 y un diccionario acumulador, son ocho
líneas y funcionan. El resultado, sobre los datos de la red:

```
google      · 6.088.318 COP por paciente adquirido
instagram   · 4.226.573
tiktok      · 2.977.694
```

Ahí ya hay material para una junta —TikTok trae al paciente más barato de los tres, que es
justamente lo que Marcela no creía—, y todavía no hemos escrito una línea de NumPy. **Esto es
importante: el bucle no es el problema. El bucle es la línea base, y a este tamaño es también la
respuesta correcta.**"""
new="""Y la pregunta de Marcela es una división: **cuánto gasté en cada canal, dividido por cuántos
pacientes trajo ese canal**. Con el `csv` de la Fase 06 y un diccionario acumulador, son ocho
líneas y funcionan. El resultado, sobre los datos de la red:

```
tiktok      · 9.394.725 COP por paciente adquirido   (215 pacientes)
instagram   · 3.550.765                              (569)
google      · 1.529.579                              (1.320)
```

Ahí ya hay material para una junta. TikTok cuesta **seis veces** lo que cuesta Google por paciente,
sobre un plan que vale entre ocho y veintidós millones — con esa tabla, la conversación del jueves
es si se apaga TikTok. Y todavía no hemos escrito una línea de NumPy. **Esto es importante: el
bucle no es el problema. El bucle es la línea base, y a este tamaño es también la respuesta
correcta.**

> ⚠️ **Y esa tabla, que es correcta, probablemente es mentira.** Los 215 pacientes de TikTok son
> los que tenían a TikTok como **último** toque antes de aceptar el plan. Si el paciente descubrió
> Áurea en un video, lo pensó dos meses y al final buscó *"ortodoncia Bogotá"* en Google, esta
> cuenta le da el mérito entero a Google. `ds04` calcula la misma tabla con el primer toque y da
> vuelta el ranking. No lo arreglamos aquí: lo dejamos anotado, porque la lección de esta sección
> es de motor y la de `ds04` es de método."""
assert s.count(old)==1
s=s.replace(old,new)

# 2. El ejemplo de int32 en §4
old2="""```python
spend = np.array([2_000_000_000, 2_000_000_000], dtype=np.int32)
print(spend.sum())        # -294967296 ¬ ni excepción, ni aviso, ni nada
```

Ese número está mal y nadie te lo dijo."""
new2="""```python
spend = np.array([2_000_000_000, 2_000_000_000], dtype=np.int32)

print(spend + spend)             # [-294967296 -294967296] ¬ ni excepción, ni aviso, ni nada
print(spend.sum())               # 4000000000, correcto: `sum` acumula en int64 por su cuenta
print(spend.sum(dtype=np.int32))  # -294967296, porque se lo pediste
```

Las tres líneas juntas son la lección, y la del medio es la que confunde: **`sum` te protege y el
`+` no**. NumPy elige un acumulador más ancho para las reducciones, así que la suma "simple" suele
salir bien y la aritmética elemento a elemento se desborda en silencio. Depender de esa cortesía
es mala idea — en cuanto alguien escriba `dtype=` para ahorrar memoria, desaparece.

El primer número está mal y nadie te lo dijo."""
assert s.count(old2)==1
s=s.replace(old2,new2)

# 3. El umbral de reúso
old3="""amortiza entre **tres o más operaciones** sobre las mismas columnas —a cinco millones de filas,
la conversión cuesta 1.751 ms y cada agregación posterior 24 ms, así que a partir de la
septuagésima cuenta el ahorro es total—, o cuando los datos **nacen** en columnas y nunca fueron
diccionarios."""
new3="""amortiza entre **tres o más operaciones** sobre las mismas columnas. La cuenta es directa: a
cinco millones de filas la conversión cuesta 1.751 ms y cada agregación posterior 24 ms, así que
`k` cuentas vectorizadas valen `1751 + 24k` contra los `746k` del bucle — con `k=2` gana el bucle
(1.492 ms contra 1.799) y con `k=3` gana el array (2.238 ms contra 1.823). **Tres.** O, la otra
salida, cuando los datos **nacen** en columnas y nunca fueron diccionarios."""
assert s.count(old3)==1
s=s.replace(old3,new3)

# 4. El 📌 del ejercicio 16 pasa a 🪦 (el archivo se escribe ahora)
old4="""- **El ejercicio 16 necesita su archivo.** `ejercicio_16_lento.py` se menciona y todavía no
  existe en `src/ds01-…/`. Tiene que traer exactamente dos defectos: una comparación de cadenas
  dentro del bucle vectorizado y un `astype` por iteración. **Escribirlo antes de publicar.**"""
new4="""- 🪦 **El ejercicio 16 ya tiene su archivo:** `src/ds01-…/ejercicio_16_lento.py`, con sus dos
  defectos sembrados —una comparación de cadenas por fila dentro de lo que dice ser vectorizado, y
  un `astype` dentro del bucle— y sin una sola pista en los comentarios."""
assert s.count(old4)==1
s=s.replace(old4,new4)
open(p,'w',encoding='utf-8').write(s); print("OK")
PY

# --- 2026-09-13T20:18:36 · Locate the passages to patch
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs && grep -n "amortiza\|septuagésima\|ejercicio 16 necesita" ds01-numpy-y-el-modelo-vectorizado.md | head

# --- 2026-09-13T20:18:39 · Show verdict lines verbatim
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs
sed -n 460,470p ds01-numpy-y-el-modelo-vectorizado.md

# --- 2026-09-13T20:19:04 · Apply corrections to ds01
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs
python3 - <<'PY'
p='ds01-numpy-y-el-modelo-vectorizado.md'; s=open(p,encoding='utf-8').read()

old="""> amortiza entre **tres o más operaciones** sobre las mismas columnas —a cinco millones de filas,
> la conversión cuesta 1.751 ms y cada agregación posterior 24 ms, así que a partir de la
> septuagésima cuenta el ahorro es total—, o cuando los datos **nacen** en columnas y nunca fueron
> diccionarios."""
new="""> amortiza entre **tres o más operaciones** sobre las mismas columnas. La cuenta es directa: a
> cinco millones de filas la conversión cuesta 1.751 ms y cada agregación posterior 24 ms, así que
> `k` cuentas vectorizadas valen `1751 + 24k` contra los `746k` del bucle — con `k=2` gana el
> bucle (1.492 ms contra 1.799) y con `k=3` gana el array (2.238 ms contra 1.823). **Tres.** La
> otra salida es que los datos **nazcan** en columnas y nunca hayan sido diccionarios."""
assert s.count(old)==1
s=s.replace(old,new)

old4="""- **El ejercicio 16 necesita su archivo.** `ejercicio_16_lento.py` se menciona y todavía no
  existe en `src/ds01-…/`. Tiene que traer exactamente dos defectos: una comparación de cadenas
  dentro del bucle vectorizado y un `astype` por iteración. **Escribirlo antes de publicar.**"""
new4="""- 🪦 **El ejercicio 16 ya tiene su archivo:** `src/ds01-…/ejercicio_16_lento.py`, con sus dos
  defectos sembrados —una comparación de cadenas por fila dentro de lo que dice ser vectorizado, y
  un `astype` dentro del bucle— y sin una sola pista en los comentarios."""
assert s.count(old4)==1
s=s.replace(old4,new4)

old1="""Y la pregunta de Marcela es una división: **cuánto gasté en cada canal, dividido por cuántos
pacientes trajo ese canal**. Con el `csv` de la Fase 06 y un diccionario acumulador, son ocho
líneas y funcionan. El resultado, sobre los datos de la red:

```
google      · 6.088.318 COP por paciente adquirido
instagram   · 4.226.573
tiktok      · 2.977.694
```

Ahí ya hay material para una junta —TikTok trae al paciente más barato de los tres, que es
justamente lo que Marcela no creía—, y todavía no hemos escrito una línea de NumPy. **Esto es
importante: el bucle no es el problema. El bucle es la línea base, y a este tamaño es también la
respuesta correcta.**"""
new1="""Y la pregunta de Marcela es una división: **cuánto gasté en cada canal, dividido por cuántos
pacientes trajo ese canal**. Con el `csv` de la Fase 06 y un diccionario acumulador, son ocho
líneas y funcionan. El resultado, sobre los datos de la red:

```
tiktok      · 9.394.725 COP por paciente adquirido   (215 pacientes)
instagram   · 3.550.765                              (569)
google      · 1.529.579                              (1.320)
```

Ahí ya hay material para una junta. TikTok cuesta **seis veces** lo que cuesta Google por
paciente, sobre un plan que vale entre ocho y veintidós millones — con esa tabla, la conversación
del jueves es si se apaga TikTok. Y todavía no hemos escrito una línea de NumPy. **Esto es
importante: el bucle no es el problema. El bucle es la línea base, y a este tamaño es también la
respuesta correcta.**

> ⚠️ **Y esa tabla, que es correcta, probablemente es mentira.** Los 215 pacientes de TikTok son
> los que tenían a TikTok como **último** toque antes de aceptar el plan. Si el paciente descubrió
> Áurea en un video, lo pensó dos meses y al final buscó *"ortodoncia Bogotá"* en Google, esta
> cuenta le da el mérito entero a Google. `ds04` calcula la misma tabla con el primer toque y le
> da vuelta al ranking. No lo arreglamos aquí: lo dejamos anotado, porque la lección de esta
> sección es de motor y la de `ds04` es de método."""
assert s.count(old1)==1
s=s.replace(old1,new1)

old2="""```python
spend = np.array([2_000_000_000, 2_000_000_000], dtype=np.int32)
print(spend.sum())        # -294967296 ¬ ni excepción, ni aviso, ni nada
```

Ese número está mal y nadie te lo dijo."""
new2="""```python
spend = np.array([2_000_000_000, 2_000_000_000], dtype=np.int32)

print(spend + spend)              # [-294967296 -294967296] ¬ ni excepción, ni aviso, ni nada
print(spend.sum())                # 4000000000, correcto: `sum` acumula en int64 por su cuenta
print(spend.sum(dtype=np.int32))  # -294967296, porque se lo pediste
```

Las tres líneas juntas son la lección, y la del medio es la que confunde: **`sum` te protege y el
`+` no**. NumPy elige un acumulador más ancho para las reducciones, así que la suma "simple" suele
salir bien mientras la aritmética elemento a elemento se desborda en silencio. Depender de esa
cortesía es mala idea: desaparece en cuanto alguien escriba `dtype=` para ahorrar memoria.

El primer número está mal y nadie te lo dijo."""
assert s.count(old2)==1
s=s.replace(old2,new2)
open(p,'w',encoding='utf-8').write(s); print("OK")
PY

# --- 2026-09-13T20:19:31 · Measure the deliberately slow script
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs/src/ds01-numpy-y-el-modelo-vectorizado
uv run --python 3.14 --with 'numpy==2.5.3' python ejercicio_16_lento.py --filas 200000

# --- 2026-09-13T20:19:44 · Measure slow script and baseline at 2M rows
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs/src/ds01-numpy-y-el-modelo-vectorizado
uv run --python 3.14 --with 'numpy==2.5.3' python ejercicio_16_lento.py --filas 2000000 | tail -2
echo "--- referencia: el bucle honesto a 2M ---"
uv run --python 3.14 --with 'numpy==2.5.3' python bench_vectorized.py --filas 2000000 --repeticiones 3 2>&1 | tail -6

# --- 2026-09-13T20:20:12 · Sync exercise 16 numbers and lint
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs
python3 - <<'PY'
p='src/ds01-numpy-y-el-modelo-vectorizado/ejercicio_16_lento.py'; s=open(p,encoding='utf-8').read()
s=s.replace('    uv run --with numpy==2.5.3 python ejercicio_16_lento.py --filas 200000',
            '    uv run --with numpy==2.5.3 python ejercicio_16_lento.py --filas 2000000')
s=s.replace("""Este script calcula lo mismo que `acquisition.py` y da el mismo resultado. Usa NumPy en
todas partes. Y es más lento que el bucle de la sección 5.2.""",
"""Este script calcula lo mismo que `acquisition.py` y, sobre las mismas filas, da el mismo
resultado. Usa NumPy en todas partes. Y a dos millones de filas tarda **trece veces más
que el bucle** de la sección 5.2.""")
s=s.replace('parser.add_argument("--filas", type=int, default=200_000)',
            'parser.add_argument("--filas", type=int, default=2_000_000)')
open(p,'w',encoding='utf-8').write(s)

p='ds01-numpy-y-el-modelo-vectorizado.md'; s=open(p,encoding='utf-8').read()
old="""16. Diagnóstico: te entregan un script que calcula el costo por adquisición y tarda cuatro
    segundos con 200.000 filas, aunque "está vectorizado". Está en el repositorio del curso
    con el nombre `ejercicio_16_lento.py`. Encuentra las dos líneas que lo arruinan y cuantifica
    cada una por separado."""
new="""16. Diagnóstico: `src/ds01-…/ejercicio_16_lento.py` calcula el costo por adquisición, usa NumPy
    en todas partes y tarda **3.857 ms con dos millones de filas** — trece veces más que el bucle
    de la sección 5.2, que tarda 291 ms sobre los mismos datos. Encuentra las **dos** líneas que lo
    arruinan y cuantifica cada una por separado con el arnés."""
assert s.count(old)==1
open(p,'w',encoding='utf-8').write(s.replace(old,new)); print("OK")
PY
cd src/ds01-numpy-y-el-modelo-vectorizado && uvx ruff@0.16.7 check . 2>&1 | tail -8

# --- 2026-09-13T20:20:17 · List remaining lint errors
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs/src/ds01-numpy-y-el-modelo-vectorizado
uvx ruff@0.16.7 check . 2>&1 | grep -E "^[A-Z][0-9]+|-->" | head -20

# --- 2026-09-13T20:20:31 · Fix lambda binding, lint and retest
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs/src/ds01-numpy-y-el-modelo-vectorizado
python3 - <<'PY'
p='bench_vectorized.py'; s=open(p,encoding='utf-8').read()
old="""        results = [
            measure("bucle", lambda: cost_per_acquisition_loop(rows, acquisitions),
                    repetitions),"""
new="""        # Los `rows=rows` de las lambdas no son adorno: sin ellos, cada lambda cerraría sobre
        # la variable del bucle y no sobre su valor, y `ruff` lo marca (B023). Aquí daría igual
        # porque `measure` las llama en el acto, pero el día que alguien guarde la lista de
        # lambdas para correrlas después, las cuatro medirían el último tamaño.
        results = [
            measure("bucle",
                    lambda rows=rows: cost_per_acquisition_loop(rows, acquisitions),
                    repetitions),"""
assert s.count(old)==1
s=s.replace(old,new)
s=s.replace("""            measure("vectorizado",
                    lambda: cost_per_acquisition_vectorized(spend, acquisitions),
                    repetitions),
            measure("vectorizado+conv",
                    lambda: cost_per_acquisition_vectorized(arrays_from_rows(rows),
                                                            acquisitions),
                    repetitions),""",
"""            measure("vectorizado",
                    lambda spend=spend: cost_per_acquisition_vectorized(spend, acquisitions),
                    repetitions),
            measure("vectorizado+conv",
                    lambda rows=rows: cost_per_acquisition_vectorized(
                        arrays_from_rows(rows), acquisitions),
                    repetitions),""")
s=s.replace("""            results.insert(1, measure(
                "comprehension",
                lambda: cost_per_acquisition_comprehension(rows, acquisitions),
                repetitions))""",
"""            results.insert(1, measure(
                "comprehension",
                lambda rows=rows: cost_per_acquisition_comprehension(rows, acquisitions),
                repetitions))""")
open(p,'w',encoding='utf-8').write(s); print("OK")
PY
uvx ruff@0.16.7 check --fix . 2>&1 | tail -3
uvx ruff@0.16.7 check . && echo "LINT OK"
uv run --python 3.14 --with pytest --with 'numpy==2.5.3' python -m pytest -q 2>&1 | tail -3
uv run --python 3.14 --with 'numpy==2.5.3' python bench_vectorized.py --filas 1000 2>&1 | tail -6

# --- 2026-09-13T20:21:12 · Check pinned pandas availability
cd /tmp && uv run --python 3.14 --with 'pandas==3.0.5' python -c "import pandas as pd; print(pd.__version__)" 2>&1 | tail -3

# --- 2026-09-13T20:22:43 · Smoke-test the three pandas versions
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs/src/ds02-pandas
python3 - <<'PY'
p='collections_report.py'; s=open(p,encoding='utf-8').read()
old="""    per_plan = installments.groupby("plan_id", observed=True).agg(
        cobrado_cop=("valor_cop", lambda values: 0),   # se reemplaza abajo; ver comentario
    )
    # La línea de arriba no sirve: `agg` con una lambda por grupo vuelve a ser un bucle de
    # Python. La forma correcta es calcular la columna ANTES de agrupar, y agrupar sumando.
    collected = installments["valor_cop"].where(installments["fecha_pago"].notna(), 0)"""
new="""    # La columna se calcula ANTES de agrupar, y se agrupa sumando. La tentación es
    # `agg(lambda grupo: ...)`, que es legible y vuelve a ser un bucle de Python: una llamada
    # por grupo, y aquí hay 6.300 grupos.
    collected = installments["valor_cop"].where(installments["fecha_pago"].notna(), 0)"""
assert s.count(old)==1
open(p,'w',encoding='utf-8').write(s.replace(old,new)); print("OK")
PY
cat > /tmp/smoke_ds02.py <<'PY'
from pathlib import Path
import sys
sys.path.insert(0, ".")
from collections_report import *
d = Path("data")
for lean in (False, True):
    plans = read_plans(d/"planes_de_tratamiento.csv", lean=lean)
    inst = read_installments(d/"cuotas.csv", lean=lean)
    print("lean" if lean else "crudo", f"planes {frame_memory_mb(plans):.2f} MB · cuotas {frame_memory_mb(inst):.2f} MB · filas {len(inst):,}")
plans = read_plans(d/"planes_de_tratamiento.csv"); inst = read_installments(d/"cuotas.csv")
a = collected_naive(plans, inst); b = collected_vectorized(plans, inst); c = collected_lean(plans, inst)
import pandas as pd
print(a.head())
print("iguales a==b:", a.equals(b), "· a==c:", a.astype(float).round(1).equals(c.astype(float).round(1)))
PY
mkdir -p data && python3 ../ds01-numpy-y-el-modelo-vectorizado/generar_embudo.py --salida data >/dev/null && uv run --python 3.14 --with 'pandas==3.0.5' python /tmp/smoke_ds02.py

# --- 2026-09-13T20:23:02 · Measure real dtype memory in pandas 3.0
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs/src/ds02-pandas
cat > /tmp/dtypes_ds02.py <<'PY'
import pandas as pd
from pathlib import Path
print("pandas", pd.__version__)
d=Path("data")
raw = pd.read_csv(d/"cuotas.csv")
print(raw.dtypes.to_string())
print("crudo deep:", raw.memory_usage(deep=True).to_string())
print("total crudo:", raw.memory_usage(deep=True).sum()/1e6)
cat = pd.read_csv(d/"cuotas.csv", dtype={"plan_id":"category","fecha_pago":"string"})
print("con category plan_id:", cat.memory_usage(deep=True).sum()/1e6)
obj = pd.read_csv(d/"cuotas.csv", dtype={"plan_id":"object","fecha_pago":"object"})
print("forzando object:", obj.memory_usage(deep=True).sum()/1e6, obj.dtypes.to_string())
pl = pd.read_csv(d/"planes_de_tratamiento.csv")
print("\nplanes dtypes:"); print(pl.dtypes.to_string()); print("planes crudo:", pl.memory_usage(deep=True).sum()/1e6)
plc = pd.read_csv(d/"planes_de_tratamiento.csv", dtype={"sede":"category","interes":"category"})
print("planes category:", plc.memory_usage(deep=True).sum()/1e6)
plo = pd.read_csv(d/"planes_de_tratamiento.csv", dtype={c:"object" for c in ["plan_id","lead_id","sede","interes","fecha_aceptacion"]})
print("planes object:", plo.memory_usage(deep=True).sum()/1e6)
PY
uv run --python 3.14 --with 'pandas==3.0.5' python /tmp/dtypes_ds02.py

# --- 2026-09-13T20:23:43 · Run the ds02 measurement
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs/src/ds02-pandas
uv run --python 3.14 --with 'pandas==3.0.5' python bench_merge.py --datos data 2>&1 | tail -12

# --- 2026-09-13T20:24:05 · Add memory baseline and rerun
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs/src/ds02-pandas
python3 - <<'PY'
p='bench_merge.py'; s=open(p,encoding='utf-8').read()
old='''def run_one(name: str, data: Path, repetitions: int) -> dict:
    """Corre una variante en este proceso y devuelve sus números."""
    function, lean = VARIANTS[name]'''
new='''def run_one(name: str, data: Path, repetitions: int) -> dict:
    """Corre una variante en este proceso y devuelve sus números."""
    if name == "solo importar":
        # La línea base de memoria. Sin esta fila, las otras tres parecen gastar cien megas
        # y en realidad gastan lo que gastan MENOS esto: importar pandas ya cuesta, y quien
        # publique la columna de RSS sin descontarlo está contando el intérprete dos veces.
        return {"etiqueta": name, "mediana_ms": 0.0, "p95_ms": 0.0,
                "pico_rss_mb": peak_rss_mb(), "entrada_mb": 0.0,
                "filas_entrada": 0, "filas_salida": 0, "repeticiones": 0}

    function, lean = VARIANTS[name]'''
assert s.count(old)==1
s=s.replace(old,new)
s=s.replace('''    parser.add_argument("--variante", choices=sorted(VARIANTS),''',
            '''    parser.add_argument("--variante", choices=[*sorted(VARIANTS), "solo importar"],''')
s=s.replace('''    results = []
    for name in VARIANTS:''','''    results = []
    for name in ("solo importar", *VARIANTS):''')
s=s.replace('''    print(f"\\n{results[0]['filas_entrada']:,} cuotas de entrada · "
          f"{results[0]['filas_salida']} filas de salida · "
          f"{results[0]['repeticiones']} repeticiones por variante")''',
'''    baseline = results[0]["pico_rss_mb"]
    print(f"\\nLa fila «solo importar» es la línea base: {baseline:.1f} MB los gasta pandas "
          f"por existir, y hay que descontarlos de las otras tres.")
    print(f"{results[1]['filas_entrada']:,} cuotas de entrada · "
          f"{results[1]['filas_salida']} filas de salida · "
          f"{results[1]['repeticiones']} repeticiones por variante")''')
open(p,'w',encoding='utf-8').write(s); print("OK")
PY
uv run --python 3.14 --with 'pandas==3.0.5' python bench_merge.py --datos data 2>&1 | tail -12

# --- 2026-09-13T20:24:27 · Check Copy-on-Write and merge validation behavior
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs/src/ds02-pandas
cat > /tmp/cow_ds02.py <<'PY'
import warnings, pandas as pd
from pathlib import Path
d=Path("data")
plans = pd.read_csv(d/"planes_de_tratamiento.csv")
# 1) asignación encadenada bajo Copy-on-Write
with warnings.catch_warnings(record=True) as w:
    warnings.simplefilter("always")
    sub = plans[plans["interes"]=="estetica"]
    sub["valor_total_cop"] = 0
    print("¿cambió el original?", (plans["valor_total_cop"]==0).any(), "· avisos:", [type(x.message).__name__ for x in w])
with warnings.catch_warnings(record=True) as w:
    warnings.simplefilter("always")
    try:
        plans[plans["interes"]=="estetica"]["valor_total_cop"] = 0
    except Exception as e:
        print("encadenada lanzó:", type(e).__name__, e)
    print("avisos encadenada:", [(type(x.message).__name__, str(x.message)[:80]) for x in w])
    print("¿cambió el original?", (plans["valor_total_cop"]==0).any())
# 2) merge m:m
etapas = pd.read_csv(d/"etapas.csv"); toques = pd.read_csv(d/"toques.csv")
print("\netapas", len(etapas), "toques", len(toques))
m = etapas.merge(toques, on="lead_id")
print("merge sin validate ->", len(m), "filas")
try:
    etapas.merge(toques, on="lead_id", validate="1:1")
except Exception as e:
    print("validate='1:1' ->", type(e).__name__, ":", e)
PY
uv run --python 3.14 --with 'pandas==3.0.5' python /tmp/cow_ds02.py

# --- 2026-09-13T20:24:40 · Compute catastrophic join size and final table
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs/src/ds02-pandas
uv run --python 3.14 --with 'pandas==3.0.5' python - <<'PY'
import pandas as pd
from pathlib import Path
d=Path("data")
p=pd.read_csv(d/"pauta.csv"); l=pd.read_csv(d/"leads.csv")
a=p.groupby("canal").size(); b=l.groupby("canal_ultimo_toque").size()
tot=sum(int(a[c])*int(b[c]) for c in a.index if c in b.index)
print("pauta", len(p), "leads", len(l))
print({c:(int(a[c]),int(b.get(c,0))) for c in a.index})
print("filas del merge por canal:", f"{tot:,}")
print("memoria estimada a 60 bytes/fila:", f"{tot*60/1e9:.1f} GB")
PY
echo "=== corrida final de la tabla ==="
uv run --python 3.14 --with 'pandas==3.0.5' python bench_merge.py --datos data 2>&1 | tail -10

# --- 2026-09-13T20:25:22 · Run ds02 tests
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs/src/ds02-pandas
uv run --python 3.14 --with 'pandas==3.0.5' --with pytest python -m pytest -q 2>&1 | tail -30

# --- 2026-09-13T20:26:06 · Compare str vs object dtype memory in pandas 3
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs/src/ds02-pandas
uv run --python 3.14 --with 'pandas==3.0.5' python - <<'PY'
import pandas as pd, sys
from pathlib import Path
d=Path("data")
s=pd.read_csv(d/"cuotas.csv")["plan_id"]
o=pd.read_csv(d/"cuotas.csv", dtype={"plan_id":"object"})["plan_id"]
print("str:", s.dtype, s.memory_usage(deep=True)/1e6, type(s.iloc[0]))
print("obj:", o.dtype, o.memory_usage(deep=True)/1e6, type(o.iloc[0]))
print("infer_string option:", pd.get_option("future.infer_string") if "future.infer_string" in [k for k in pd._config.config._registered_options] else "n/a")
PY

# --- 2026-09-13T20:30:28 · Fix ds02 claims and lint
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs
python3 - <<'PY'
p='ds02-pandas.md'; s=open(p,encoding='utf-8').read()

old="""> ⚖️ **Veredicto.** Quitar el `apply` es el cambio más rentable que existe en pandas: **24× en
> tiempo** por una línea, y ninguna pérdida de legibilidad. Cambiar el orden —agregar y después
> unir— agrega otro **1,7×** y, sobre todo, **baja la memoria del trabajo a la mitad** (57,6 →
> 27,6 MB sobre la línea base), que es lo que decide si el informe corre o no en la máquina
> virtual de dos núcleos de Áurea."""
new="""> ⚖️ **Veredicto.** Quitar el `apply` es el cambio más rentable que existe en pandas: **13,8× en
> tiempo** por una línea, y ninguna pérdida de legibilidad. Cambiar el orden —agregar y después
> unir— agrega otro **1,7×**, para un total de **24×** contra la versión ingenua, y sobre todo
> **baja la memoria del trabajo a la mitad** (57,6 → 27,6 MB sobre la línea base), que es lo que
> decide si el informe corre o no en la máquina virtual de dos núcleos de Áurea."""
assert s.count(old)==1
s=s.replace(old,new)

old2="""- **`validate="1:1"`.** Es la línea que convierte un error silencioso en una excepción, y el
  mensaje que lanza es de los buenos: nombra la llave y te imprime los duplicados.

```
MergeError: Merge keys are not unique in either left or right dataset;
not a one-to-one merge.
Duplicates in left:  lead_id  L0000002  L0000002  L0000002 …
```"""
new2="""- **`validate="1:1"`.** Es la línea que convierte un error silencioso en una excepción, y el
  mensaje que lanza es de los buenos: nombra la llave y te imprime los duplicados. Así se ve
  cuando de verdad salta —este es el del ejercicio 8, uniendo `etapas` con `toques`, donde la
  llave no es única de ninguno de los dos lados—:

```
MergeError: Merge keys are not unique in either left or right dataset;
not a one-to-one merge.
Duplicates in left:  lead_id  L0000002  L0000002  L0000002 …
```"""
assert s.count(old2)==1
s=s.replace(old2,new2)

old3="""- **`usecols`** es la optimización más barata y la que más se olvida: de las cinco columnas de
  `cuotas.csv` el informe usa tres, y las otras dos son 81.370 filas de memoria que se paga sin
  usarse. El informe baja de 17,4 a 10,4 MB de entrada solo por esto."""
new3="""- **`usecols`** es la optimización más barata y la que más se olvida: de las cinco columnas de
  `cuotas.csv` el informe usa tres, y las otras dos son 81.370 filas de memoria que se paga sin
  usarse. Entre `usecols` y los dtypes, la entrada del informe baja de 17,4 a 10,4 MB."""
assert s.count(old3)==1
s=s.replace(old3,new3)
open(p,'w',encoding='utf-8').write(s); print("OK")
PY
cd src/ds02-pandas && uvx ruff@0.16.7 check . 2>&1 | tail -5

# --- 2026-09-13T20:30:35 · Lint and retest ds02
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs/src/ds02-pandas
uvx ruff@0.16.7 check --fix . >/dev/null 2>&1; uvx ruff@0.16.7 check . && echo "LINT OK"
uv run --python 3.14 --with 'pandas==3.0.5' --with pytest python -m pytest -q 2>&1 | tail -3

# --- 2026-09-13T20:30:46 · Check whether ia entries exist in BENCHMARKS and INSTINTOS
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs
grep -n "^## \|^### " BENCHMARKS.md | tail -20; echo "=== INSTINTOS ==="; grep -n "^## \|^### " INSTINTOS.md | tail -20

# --- 2026-09-13T20:30:49 · Read the ia sections of BENCHMARKS and INSTINTOS
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs
sed -n 540,600p BENCHMARKS.md; echo "=== INSTINTOS 400-420 ==="; sed -n 400,420p INSTINTOS.md

# --- 2026-09-13T20:31:51 · Add ds01 and ds02 entries to BENCHMARKS
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs
python3 - <<'PY'
p='BENCHMARKS.md'; s=open(p,encoding='utf-8').read()
anchor = "---\n\n## ✍️ Cómo se agregan entradas"
new = """---

## 📊 Complementos `ds` — el track de datos

> ✅ **A diferencia del track de IA, estas mediciones están ejecutadas.** No cuestan dinero, no
> necesitan una API ni juicios humanos: corren en un portátil con dos dependencias. Se tomaron en
> el entorno de referencia de este documento, con CPython **3.14.5**.

### ds01 · El bucle, la comprehension y el array

**Afirmaba:** que vectorizar la suma agrupada le gana al bucle por un orden de magnitud, y que el
umbral en el que **conviene** hacerlo es mucho más alto que eso porque la conversión desde una
lista de diccionarios se paga entera y se paga cada vez.

**Condiciones:** NumPy 2.5.3. `pauta.csv` del generador del Embudo, semilla 20260913, 49.260 filas
reales; los tamaños mayores son **el bloque real repetido** —sintético y declarado—. Cinco
repeticiones hasta el millón de filas, tres a cinco millones. Las cuatro versiones corren sobre las
mismas filas en memoria y hay una prueba que verifica que devuelven lo mismo.

| Filas | bucle | comprehension | vectorizado | vectorizado + conversión |
|---|---|---|---|---|
| 1.000 | 0,131 ms | 0,196 ms | **0,007 ms** | 0,276 ms |
| 100.000 | 14,6 ms | 25,7 ms | **0,469 ms** | 35,2 ms |
| 5.000.000 | 746 ms | 1.320 ms | **23,9 ms** | 1.775 ms |

⚖️ **31× sobre columnas ya construidas, y una derrota de 2,4× si hay que convertir.** El umbral no
es de tamaño sino de reúso: `k` cuentas vectorizadas valen `1751 + 24k` ms contra `746k` del bucle,
así que **a partir de la tercera** agregación sobre las mismas columnas el array gana. Con una
sola, pierde a cualquier tamaño. Y la comprehension por canal —la versión "pythónica"— es **un 73%
más lenta que el bucle** al que pretende mejorar.

→ [`ds01-numpy-y-el-modelo-vectorizado.md`](ds01-numpy-y-el-modelo-vectorizado.md) §6

### ds02 · El orden de unir y agregar

**Afirmaba:** que el orden de las operaciones domina sobre todo lo demás, y que los dtypes ayudan
mucho menos de lo que se cree.

**Condiciones:** pandas 3.0.5. Datos **reales** de Áurea, sin repetir bloque: 6.339 planes y 81.370
cuotas, semilla 20260913. Cinco repeticiones. Cada variante corre **en su propio proceso** y se
reporta el pico de RSS del sistema operativo, no `tracemalloc` — pandas asigna fuera del asignador
de Python y `tracemalloc` no lo ve. Las tres variantes producen la misma tabla, verificado por
prueba.

| Variante | Mediana | p95 | Pico RSS | Sobre la línea base |
|---|---|---|---|---|
| solo importar pandas | — | — | 76,7 MB | — |
| unir + `apply` | 294,8 ms | 295,0 ms | 134,3 MB | 57,6 MB |
| unir + máscara | 21,4 ms | 22,9 ms | 115,2 MB | 38,5 MB |
| **agregar + unir** | **12,3 ms** | **12,7 ms** | **104,3 MB** | **27,6 MB** |

⚖️ **24× en total, y la mitad de la memoria.** Quitar `apply(axis=1)` da 13,8× por una línea;
cambiar el orden —agregar antes de unir— agrega otro 1,7× y baja el trabajo de 57,6 a 27,6 MB.
**El umbral, dicho entero: a la escala de Áurea nada de esto decide nada** —son 295 ms contra 12,
una vez al mes—; empieza a decidir cuando el informe entra al cierre nocturno de la Fase 15 o
alguien lo corre en un bucle por sede y por mes. Lo que sí importa a cualquier tamaño es
`validate=`, que no es rendimiento sino corrección.

**Y el número incómodo:** importar pandas cuesta **76,7 MB** antes de leer un solo dato, para un
informe que maneja 10 MB. Para un script mensual da igual; para un contenedor que atiende
peticiones, no.

→ [`ds02-pandas.md`](ds02-pandas.md) §6

---

## ✍️ Cómo se agregan entradas"""
assert s.count(anchor)==1
open(p,'w',encoding='utf-8').write(s.replace(anchor,new)); print("BENCHMARKS OK")
PY

# --- 2026-09-13T20:31:56 · See INSTINTOS structure before the method section
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs
sed -n 480,500p INSTINTOS.md

# --- 2026-09-13T21:26:06 · Add ds reflexes to INSTINTOS
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs
python3 - <<'PY'
p='INSTINTOS.md'; s=open(p,encoding='utf-8').read()
anchor = "---\n\n## 🧪 Los reflejos de método"
new = """---

## 📊 Los reflejos del track de datos

Los dos que aparecieron al construir el Embudo. Nacen de la misma raíz —**pensar en filas**— y se
corrigen con la misma pregunta: *¿de dónde vienen estos datos y cuántas cuentas voy a hacer con
ellos?*

### 27. "Vectorizar siempre gana"

No es un reflejo de Java: es el que el lector adquiere el primer día de NumPy, y también está mal.
El cálculo vectorizado gana **31×** sobre columnas ya construidas, y el **programa** pierde **2,4×**
si cada corrida tiene que convertir la lista de diccionarios en columnas. Lo que hay que preguntar
no es el tamaño del dato —que es lo que todo el mundo pregunta— sino **cuántas operaciones se hacen
sobre la misma carga**: con menos de tres, el bucle gana a cualquier tamaño.

Y el reflejo intermedio, que es peor que el original: la comprehension por canal, escrita porque
"los bucles son lentos en Python", recorre la lista una vez por categoría y sale **un 73% más
lenta** que el bucle que venía a mejorar. *(`ds01`)*

### 28. "Recorro las filas y decido"

Once años de `ResultSet` dejan este reflejo intacto, y pandas tiene una función que lo acepta sin
protestar: `apply(axis=1)` construye **una Series por fila** para pasártela. Ochenta y un mil
Series para decidir ochenta y un mil veces algo que era una comparación de columna. Cuesta **13,8×**
y se arregla con una línea.

Su hermano mayor es de diseño y es más caro de descubrir porque el resultado sale bien: **unir antes
de agregar**. Materializar 81.370 filas para producir veinte cuesta el doble de memoria que
colapsarlas primero — y, sobre todo, deja el `merge` sin el sitio donde poner `validate=`, que es la
única forma de que una llave que dejó de ser única te lance una excepción en vez de un total
equivocado. *(`ds02`)*

---

## 🧪 Los reflejos de método"""
assert s.count(anchor)==1
open(p,'w',encoding='utf-8').write(s.replace(anchor,new)); print("INSTINTOS OK")
PY

# --- 2026-09-13T21:26:24 · Update ds01 src README
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs/src/ds01-numpy-y-el-modelo-vectorizado
python3 - <<'PY'
p='README.md'; s=open(p,encoding='utf-8').read()
old="""> 🚧 **La sección todavía no está escrita.** Lo que hay aquí es la **maquinaria de datos** del
> track `ds`, que se escribió antes a propósito: seis secciones —`ds01` a `ds06`— leen este mismo
> conjunto, y descubrir en `ds04` que falta una columna obliga a reescribir tres capítulos.

| Archivo | Qué es |
|---|---|
| `generar_embudo.py` | El conjunto del Embudo: pauta, toques, leads, etapas, planes, cuotas y aliados |
| `test_generar_embudo.py` | 28 pruebas **sin dependencias**: `pytest test_generar_embudo.py` |"""
new="""> 📦 Este directorio guarda además la **maquinaria de datos** de todo el track: seis secciones
> —`ds01` a `ds06`— leen el mismo conjunto del Embudo, y por eso el generador se escribió antes que
> cualquier capítulo. Si una sección necesita una columna nueva, se agrega aquí y se vuelve a correr
> la suite; no se inventa en el texto.

| Archivo | Qué es |
|---|---|
| `generar_embudo.py` | El conjunto del Embudo: pauta, toques, leads, etapas, planes, cuotas y aliados |
| `acquisition.py` | El costo por paciente adquirido, en **tres versiones** que dan lo mismo |
| `bench_vectorized.py` | La medición de la sección 6: cuatro variantes por cinco tamaños |
| `ejercicio_16_lento.py` | El diagnóstico del ejercicio 16. Dos defectos sembrados, sin pistas |
| `test_generar_embudo.py` · `test_acquisition.py` | 37 pruebas: `pytest` |

## Antes de correr las mediciones

```bash
cp ../02-secuencias-perezosas/bench.py .      # el arnés del curso, el mismo de la Fase 02
uv run --with numpy==2.5.3 python bench_vectorized.py --filas 1000 100000 5000000
```

El arnés no se copia por comodidad: es **el mismo archivo** de la Fase 02, sin una línea
cambiada, porque los números de este track tienen que poder ponerse en la misma tabla que los del
camino base. Lo único que agrega `bench_vectorized.py` es el formato con tres decimales de
milisegundo — a mil filas, la tabla del arnés sería una columna de ceros."""
assert s.count(old)==1
open(p,'w',encoding='utf-8').write(s.replace(old,new)); print("OK")
PY

# --- 2026-09-13T21:26:49 · Clean artifacts and verify links
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs
# limpiar artefactos que no se versionan
rm -rf src/ds01-numpy-y-el-modelo-vectorizado/data src/ds02-pandas/data src/ds01-numpy-y-el-modelo-vectorizado/bench.py
find . -name __pycache__ -type d -prune -exec rm -rf {} + 2>/dev/null
echo "=== links rotos ==="
python3 - <<'PY'
import re,os
bad=[]
for root,d,fs in os.walk('.'):
    if 'pytest_cache' in root or '/.git' in root: continue
    for f in fs:
        if not f.endswith('.md'): continue
        p=os.path.join(root,f)
        for i,l in enumerate(open(p,encoding='utf-8'),1):
            for m in re.finditer(r'\]\((?!https?:)([^)#]+\.md)(?:#[^)]*)?\)',l):
                t=m.group(1)
                if not os.path.exists(os.path.normpath(os.path.join(root,t))): bad.append(f"{p}:{i} -> {t}")
print("\n".join(bad) or "sin links rotos")
PY
echo "=== wc ==="; wc -l ds01-numpy-y-el-modelo-vectorizado.md ds02-pandas.md src/ds0*/*.py | tail -20

# --- 2026-09-13T21:27:12 · Update track state documents
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs
python3 - <<'PY'
p='src/ds07-scikit-learn/README.md'; s=open(p,encoding='utf-8').read()
s=s.replace("Código de la sección [`ds07-scikit-learn.md`](../../ds07-scikit-learn.md).",
            "Código de la sección `ds07-scikit-learn.md`, **que todavía no existe** (se escribe en la\ntanda T11). El enlace se pone cuando el archivo esté.")
open(p,'w',encoding='utf-8').write(s)

# tabla de las 17 secciones: marcar ds01 y ds02 con ✅ y su medición real
p='prompts/prompts-de-tracks-ia-ds.md'; s=open(p,encoding='utf-8').read()
s=s.replace("| `ds01-numpy-y-el-modelo-vectorizado.md` | NumPy y el modelo vectorizado | Embudo | Bucle ⇄ vectorizado, por tamaño |",
            "| `ds01-numpy-y-el-modelo-vectorizado.md` ✅ | NumPy y el modelo vectorizado | Embudo | Bucle ⇄ vectorizado, por tamaño — **ejecutada** |")
s=s.replace("| `ds02-pandas.md` | pandas y el modelo de DataFrame | Embudo | Memoria de un `join` mal hecho, antes y después |",
            "| `ds02-pandas.md` ✅ | pandas y el modelo de DataFrame | Embudo | Memoria de un `join` mal hecho, antes y después — **ejecutada** |")
old = """> ✅ **El track `ia` está escrito y cerrado el 13/09/2026:** las ocho secciones con su `src/`, sus
> generadores de datos con semilla fija y **134 pruebas que corren sin red, sin modelo y sin
> Postgres**. Las mediciones están en `⏳` con su spec completa, salvo la fila léxica de `ia07`, que
> no llama al modelo y sí tiene número. **Pendiente: el track `ds` entero.**"""
new = """> ✅ **El track `ia` está escrito y cerrado el 13/09/2026:** las ocho secciones con su `src/`, sus
> generadores de datos con semilla fija y **134 pruebas que corren sin red, sin modelo y sin
> Postgres**. Las mediciones están en `⏳` con su spec completa, salvo la fila léxica de `ia07`, que
> no llama al modelo y sí tiene número.
>
> 🚧 **El track `ds` va por `ds02`.** T6 dejó los dos conjuntos de datos, T7 escribió `ds01` y
> `ds02` con **sus dos mediciones ejecutadas** —no cuestan dinero ni API, así que aquí no hay `⏳`—
> y sus entradas ya están en `BENCHMARKS.md`. Siguiente: T8, `ds03`."""
assert s.count(old)==1
s=s.replace(old,new)
open(p,'w',encoding='utf-8').write(s)

# prompts/README: T7 cerrada
p='prompts/README.md'; s=open(p,encoding='utf-8').read()
old2="| **T7** | `ds01` + `ds02` | Fijan el registro del track y el arnés de memoria que `ds03` reutiliza. La tesis de `ds02` es la respuesta a la de `ds01` |"
new2="| **T7** ✅ | `ds01` + `ds02`, cerradas el 13/09/2026: 1.439 líneas de prosa, **47 pruebas** y **las dos mediciones ejecutadas** en el entorno de referencia | Fijan el registro del track y el arnés de memoria que `ds03` reutiliza. La tesis de `ds02` es la respuesta a la de `ds01` |"
assert s.count(old2)==1
s=s.replace(old2,new2)
s=s.replace("""> conjuntos de datos y sus 47 pruebas— está cerrada**, y la siguiente es T7 (`ds01` y `ds02`).""",
            """> conjuntos de datos y sus 47 pruebas— y **T7** —`ds01` y `ds02`, con sus dos mediciones ya
> ejecutadas— están cerradas**; la siguiente es T8 (`ds03`).""")
open(p,'w',encoding='utf-8').write(s); print("OK")
PY
grep -n "T6\|T7\|T8" prompts/README.md | head -8

# --- 2026-09-13T21:27:21 · Fix nested bold in the status banner
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs
python3 - <<'PY'
p='prompts/README.md'; s=open(p,encoding='utf-8').read()
old="""> 134 pruebas. 🚧 **Track `ds` en curso, repartido en ocho tandas (T6–T13)**: **T6 —los dos
> conjuntos de datos y sus 47 pruebas— y **T7** —`ds01` y `ds02`, con sus dos mediciones ya
> ejecutadas— están cerradas**; la siguiente es T8 (`ds03`)."""
new="""> 134 pruebas. 🚧 **Track `ds` en curso, repartido en ocho tandas (T6–T13)**. Cerradas: **T6**,
> los dos conjuntos de datos con sus 47 pruebas, y **T7**, `ds01` y `ds02` con sus dos mediciones
> ya ejecutadas. La siguiente es **T8** (`ds03`)."""
assert s.count(old)==1
open(p,'w',encoding='utf-8').write(s.replace(old,new)); print("OK")
PY
sed -n 7,16p prompts/README.md

# --- 2026-09-13T21:27:36 · Record T7 in project memory
cd /Users/oskar/.claude/projects/-Users-oskar-Developer-Learning-courses-ia-generated/memory
python3 - <<'PY'
p='python-java-devs-estado.md'; s=open(p,encoding='utf-8').read()
old="**Lo siguiente es T7.**"
new="""**T7 cerrada el 13/09/2026**: `ds01-numpy-y-el-modelo-vectorizado.md` (766 líneas) y
`ds02-pandas.md` (673), con su `src/` y 19 pruebas propias. **Las dos mediciones se ejecutaron de
verdad** —esta máquina *es* el entorno de referencia declarado en `BENCHMARKS.md`: macOS 26.6.2,
Apple Silicon de 8 núcleos, CPython 3.14.5— así que el track `ds` no lleva `⏳` como el `ia`, y las
dos entradas ya están en `BENCHMARKS.md` y los dos reflejos (27 y 28) en `INSTINTOS.md`.

Los dos hallazgos que salieron de medir y que ordenan las secciones: en `ds01`, **vectorizar el
cálculo gana 31× y el programa pierde 2,4×** si hay que convertir la lista de diccionarios en
columnas cada vez —el umbral no es de tamaño sino de reúso: tres agregaciones—; en `ds02`, quitar
`apply(axis=1)` da 13,8× y agregar antes de unir otro 1,7× (24× en total) con la mitad de la
memoria, pero **a la escala real de Áurea ninguno de los dos decide nada** y eso se dice. Dos
verificaciones contra pandas 3.0.5 que cambiaron el guion previsto: **Copy-on-Write es el
comportamiento por defecto y `SettingWithCopyWarning` ya no existe** (la asignación encadenada
lanza `ChainedAssignmentError` y no hace nada), y el ahorro de `category` es del 26–37%, no un
orden de magnitud. La memoria de pandas se mide con **RSS del proceso, no `tracemalloc`** —pandas
asigna fuera del asignador de Python—, con una fila de línea base: importar pandas cuesta 76,7 MB.

**Lo siguiente es T8 (`ds03`).**"""
assert s.count(old)==1
open(p,'w',encoding='utf-8').write(s.replace(old,new)); print("OK")
PY

# --- 2026-09-13T21:27:43 · Final verification of the ds track
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs
echo "=== suites completas del track ds ==="
for d in src/ds01-numpy-y-el-modelo-vectorizado src/ds02-pandas src/ds07-scikit-learn; do
  printf "%-42s " "$d"
  (cd $d && uv run --python 3.14 --with pytest --with 'numpy==2.5.3' --with 'pandas==3.0.5' python -m pytest -q 2>&1 | tail -1)
done
echo "=== lint ==="; uvx ruff@0.16.7 check src/ds01-numpy-y-el-modelo-vectorizado src/ds02-pandas src/ds07-scikit-learn && echo OK
echo "=== limpieza ==="; git status --short . | head

# --- 2026-09-13T21:28:26 · Reconcile ruff import ordering across working directories
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs
uvx ruff@0.16.7 check --fix src/ds01-numpy-y-el-modelo-vectorizado src/ds02-pandas src/ds07-scikit-learn >/dev/null 2>&1
echo "desde la raíz del curso:"; uvx ruff@0.16.7 check src/ds0* && echo "  OK"
echo "desde dentro de cada dir:"
for d in src/ds01-numpy-y-el-modelo-vectorizado src/ds02-pandas src/ds07-scikit-learn; do printf "  %-42s" "$d"; (cd $d && uvx ruff@0.16.7 check . >/dev/null 2>&1 && echo OK || echo "FALLA"); done

# --- 2026-09-13T21:28:36 · Read the documented ruff configuration
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs
sed -n 440,475p 00-instalacion-ambiente-editores-y-ecosistema.md

# --- 2026-09-13T21:28:47 · Restore in-directory import ordering
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs/src
for d in ds01-numpy-y-el-modelo-vectorizado ds02-pandas ds07-scikit-learn; do
  (cd $d && uvx ruff@0.16.7 check --fix . >/dev/null 2>&1; printf "  %-42s" "$d"; uvx ruff@0.16.7 check . >/dev/null 2>&1 && echo "OK (desde dentro, que es como lo corre el lector)" || echo FALLA)
done

# --- 2026-09-13T21:28:54 · Final test run and cleanup
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs/src
for d in ds01-numpy-y-el-modelo-vectorizado ds02-pandas ds07-scikit-learn; do printf "%-42s " "$d"; (cd $d && uv run --python 3.14 --with pytest --with 'numpy==2.5.3' --with 'pandas==3.0.5' python -m pytest -q 2>&1 | tail -1); done
find . -name __pycache__ -type d -prune -exec rm -rf {} + 2>/dev/null; rm -rf ds01-numpy-y-el-modelo-vectorizado/data ds02-pandas/data
cd .. && rm -rf .pytest_cache && ls src/ds01-numpy-y-el-modelo-vectorizado src/ds02-pandas src/ds07-scikit-learn

# --- 2026-09-13T21:36:32 · Measure the loop at real size and check business coherence
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs/src/ds01-numpy-y-el-modelo-vectorizado
python3 generar_embudo.py --salida data >/dev/null
cp ../02-secuencias-perezosas/bench.py .
uv run --python 3.14 --with 'numpy==2.5.3' python bench_vectorized.py --filas 49260 2>&1 | tail -5
uv run --python 3.14 --with 'numpy==2.5.3' python - <<'PY'
import csv, json
from pathlib import Path
rows=list(csv.DictReader(open("data/pauta.csv",encoding="utf-8")))
plans=list(csv.DictReader(open("data/planes_de_tratamiento.csv",encoding="utf-8")))
spend=sum(int(r["costo_cop"]) for r in rows)
value=sum(int(p["valor_total_cop"]) for p in plans)
print(f"pauta total {spend:,} COP · valor contratado {value:,} COP · pauta/contratado {spend/value:.1%}")
print(f"CAC global {spend/len(plans):,.0f} COP sobre un plan medio de {value/len(plans):,.0f}")
PY

# --- 2026-09-13T21:36:52 · Correct ds01 figures and close the open pendiente
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs
python3 - <<'PY'
p='ds01-numpy-y-el-modelo-vectorizado.md'; s=open(p,encoding='utf-8').read()

old1="""exporta cada mes y que nadie ha sumado nunca. La primera versión de esa cuenta la vas a escribir
con un `for`, va a estar bien, y va a tardar quince milisegundos."""
new1="""exporta cada mes y que nadie ha sumado nunca. La primera versión de esa cuenta la vas a escribir
con un `for`, va a estar bien, y va a tardar siete milisegundos."""
assert s.count(old1)==1
s=s.replace(old1,new1)

old2="""El problema aparece cuando la misma cuenta hay que hacerla por canal, por sede y por mes, y
después otra vez con otro modelo de atribución, y después sobre tres años de historia en vez de
dos. Entonces las ocho líneas se convierten en tres bucles anidados y quince milisegundos se
convierten en minutos."""
new2="""El problema aparece cuando la misma cuenta hay que hacerla por canal, por sede y por mes, y
después otra vez con otro modelo de atribución, y después sobre tres años de historia en vez de
dos. Entonces las ocho líneas se convierten en tres bucles anidados y los siete milisegundos se
multiplican por las 1.620 combinaciones que Marcela quiere ver."""
assert s.count(old2)==1
s=s.replace(old2,new2)

old3="""- **Áurea gasta 6.059 millones de pesos de pauta en 27 meses** según el generador, unos 224
  millones al mes. Es alto para una red de diez sedes y nadie lo ha revisado contra el resto de
  la ficción. Si `ds04` decide que es demasiado, se ajusta en el generador —no en el texto— y se
  vuelven a correr las dos secciones."""
new3="""- 🪦 **La pauta de Áurea está revisada contra el resto de la ficción y cuadra.** Son 6.059
  millones de pesos en 27 meses —unos 224 al mes, que parecían muchos— contra **87.271 millones de
  valor contratado**: un **6,9%**, que para una compra electiva y cara es una cifra sana. El costo
  de adquisición global es de **955.876 COP sobre un plan medio de 13,8 millones**. Lo que se ve
  feo en la tabla de la sección 4 no es el negocio: es la atribución al último toque, que le carga
  a TikTok un tercio del gasto y le acredita 215 pacientes."""
assert s.count(old3)==1
s=s.replace(old3,new3)
open(p,'w',encoding='utf-8').write(s); print("OK")
PY
rm -rf src/ds01-numpy-y-el-modelo-vectorizado/data src/ds01-numpy-y-el-modelo-vectorizado/bench.py src/ds01-numpy-y-el-modelo-vectorizado/__pycache__

# --- 2026-09-13T21:37:27 · Time dataset generation at larger scales
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs/src/ds01-numpy-y-el-modelo-vectorizado
for e in 4 16; do echo "--- escala $e ---"; ( time python3 generar_embudo.py --salida /tmp/e$e --escala $e >/dev/null ) 2>&1 | grep real; du -sh /tmp/e$e; wc -l /tmp/e$e/*.csv | tail -1; done

# --- 2026-09-13T21:38:12 · Check pinned polars, duckdb and pyarrow
cd /tmp && uv run --python 3.14 --with 'polars==1.44.2' --with 'duckdb==1.5.5' --with 'pyarrow==25.0.1' python -c "
import polars, duckdb, pyarrow
print('polars', polars.__version__, '· duckdb', duckdb.__version__, '· pyarrow', pyarrow.__version__)" 2>&1 | tail -3

# --- 2026-09-13T21:39:37 · Check the four engines agree
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs/src/ds03-polars-y-el-modelo-lazy
mkdir -p data && python3 ../ds01-numpy-y-el-modelo-vectorizado/generar_embudo.py --salida data >/dev/null
uv run --python 3.14 --with 'pandas==3.0.5' --with 'polars==1.44.2' --with 'duckdb==1.5.5' --with 'pyarrow==25.0.1' python - <<'PY'
from pathlib import Path
from consolidation import ENGINES
out={}
for name, fn in ENGINES.items():
    try:
        rows = fn(Path("data")); out[name]=rows
        print(f"{name:14s} {len(rows):>4} filas · primera {rows[0]}")
    except Exception as e:
        print(f"{name:14s} ERROR {type(e).__name__}: {e}")
ref = out.get("bucle")
for name, rows in out.items():
    if name=="bucle": continue
    print(f"{name:14s} == bucle:", rows==ref)
    if rows!=ref:
        for a,b in zip(ref,rows):
            if a!=b: print("   ref:",a,"\n   otr:",b); break
PY

# --- 2026-09-13T21:40:13 · Check date ranges beyond the declared window
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs/src/ds03-polars-y-el-modelo-lazy
python3 - <<'PY'
import csv
from pathlib import Path
d=Path("data")
for name,col in [("etapas.csv","fecha_hora"),("planes_de_tratamiento.csv","fecha_aceptacion"),("cuotas.csv","fecha_pago"),("cuotas.csv","fecha_programada"),("toques.csv","fecha_hora"),("leads.csv","creado")]:
    vals=[r[col][:10] for r in csv.DictReader(open(d/name,encoding="utf-8")) if r[col]]
    print(f"{name:28s} {col:18s} max={max(vals)} min={min(vals)}")
PY

# --- 2026-09-13T21:40:50 · Cap all events at the dataset's declared end date
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs/src/ds01-numpy-y-el-modelo-vectorizado
python3 - <<'PY'
p='generar_embudo.py'; s=open(p,encoding='utf-8').read()

# 1) etapas y toques: nada después de END
old = """                for order, (channel, offset) in enumerate(zip(path, moments), start=1):
                    when = datetime.combine(day, datetime.min.time()) + timedelta(
                        days=offset, hours=rng.uniform(7, 22))
                    touches.append({"""
new = """                for order, (channel, offset) in enumerate(zip(path, moments), start=1):
                    when = datetime.combine(day, datetime.min.time()) + timedelta(
                        days=offset, hours=rng.uniform(7, 22))
                    # El conjunto es un export tomado el `END`, y un export no contiene el
                    # futuro. Un lead creado en marzo todavía no ha terminado su recorrido:
                    # sus toques y etapas posteriores al corte **no existen todavía**, y
                    # dejarlos dentro le daría al análisis de cohortes de `ds04` un dato que
                    # nadie podía tener. Esto es censura por la derecha, y es real.
                    if when.date() > END:
                        break
                    touches.append({"""
assert s.count(old)==1
s=s.replace(old,new)

old2 = """                for stage, odds in zip(STAGES, STAGE_ODDS[last]):
                    if rng.random() > odds:
                        break
                    clock += timedelta(days=rng.uniform(0.2, window / 3 + 1))
                    stages.append({"""
new2 = """                for stage, odds in zip(STAGES, STAGE_ODDS[last]):
                    if rng.random() > odds:
                        break
                    clock += timedelta(days=rng.uniform(0.2, window / 3 + 1))
                    if clock.date() > END:      # todavía no ha pasado: ver el comentario de arriba
                        break
                    stages.append({"""
assert s.count(old2)==1
s=s.replace(old2,new2)

# 2) cuotas pagadas: un pago futuro es una cuota que hoy está sin pagar
old3 = """            if index >= abandons_at:
                paid = ""
            else:
                # Pagar tarde es lo normal; no pagar es otra cosa. El curso necesita las
                # dos, y distinguirlas es trabajo de ds04, no del generador.
                paid = (due + timedelta(days=int(rng.expovariate(1 / 6)))).isoformat()"""
new3 = """            if index >= abandons_at:
                paid = ""
            else:
                # Pagar tarde es lo normal; no pagar es otra cosa. El curso necesita las
                # dos, y distinguirlas es trabajo de ds04, no del generador.
                paid_on = due + timedelta(days=int(rng.expovariate(1 / 6)))
                # Y un pago posterior al corte es un pago que hoy no ha ocurrido: la cuota
                # aparece impaga, que es exactamente lo que vería Yuli el día del export.
                paid = paid_on.isoformat() if paid_on <= END else \"\""""
assert s.count(old3)==1
s=s.replace(old3,new3)

# 3) el toque que se corta deja `moments` inconsistente: el reloj de etapas usa moments[-1]
old4 = """                # El avance por el embudo, etapa por etapa, con el reloj del último toque.
                clock = datetime.combine(day, datetime.min.time()) + timedelta(
                    days=moments[-1], hours=rng.uniform(8, 19))"""
new4 = """                # El avance por el embudo, etapa por etapa, con el reloj del último toque
                # **que de verdad ocurrió** antes del corte.
                clock = datetime.combine(day, datetime.min.time()) + timedelta(
                    days=moments[-1], hours=rng.uniform(8, 19))"""
assert s.count(old4)==1
s=s.replace(old4,new4)
open(p,'w',encoding='utf-8').write(s); print("OK")
PY
python3 generar_embudo.py --salida /tmp/fix 2>&1 | tail -9
python3 - <<'PY'
import csv, json
from pathlib import Path
d=Path("/tmp/fix")
for name,col in [("etapas.csv","fecha_hora"),("planes_de_tratamiento.csv","fecha_aceptacion"),("cuotas.csv","fecha_pago"),("toques.csv","fecha_hora")]:
    vals=[r[col][:10] for r in csv.DictReader(open(d/name,encoding="utf-8")) if r[col]]
    print(f"{name:28s} {col:18s} max={max(vals)}")
print(json.load(open(d/"manifiesto.json"))["filas"])
PY

# --- 2026-09-13T21:41:14 · Add censoring tests and run ds01 suite
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs/src/ds01-numpy-y-el-modelo-vectorizado
python3 - <<'PY'
p='test_generar_embudo.py'; s=open(p,encoding='utf-8').read()
anchor = "def test_las_etapas_avanzan_en_el_tiempo(dataset):"
new = '''def test_ningun_evento_ocurre_despues_del_corte(dataset):
    """El conjunto es un export tomado el 2026-03-31, y un export no contiene el futuro.

    La primera versión de este generador dejaba etapas en agosto de 2026 y pagos en mayo,
    porque el reloj del embudo seguía corriendo después de la última fecha declarada. Nada
    fallaba: simplemente el conjunto sabía cosas que nadie podía saber, y el análisis de
    cohortes de `ds04` habría medido conversiones que todavía no han ocurrido.
    """
    limit = gen.END.isoformat()
    for row in dataset["etapas.csv"]:
        assert row["fecha_hora"][:10] <= limit
    for row in dataset["toques.csv"]:
        assert row["fecha_hora"][:10] <= limit
    for row in dataset["planes_de_tratamiento.csv"]:
        assert row["fecha_aceptacion"] <= limit
    for row in dataset["cuotas.csv"]:
        assert row["fecha_programada"] <= limit
        assert not row["fecha_pago"] or row["fecha_pago"] <= limit


def test_hay_leads_censurados_por_la_derecha(dataset):
    """La consecuencia del corte, y es contenido de `ds04`: los leads recientes todavía no
    terminaron su recorrido. Si no hubiera ninguno, el corte no estaría haciendo nada."""
    reached = {row["lead_id"] for row in dataset["etapas.csv"]
               if row["etapa"] == "primera_cuota"}
    recent = [row for row in dataset["leads.csv"] if row["creado"] >= "2026-03-01"]
    assert recent
    assert sum(row["lead_id"] in reached for row in recent) / len(recent) < 0.20


def test_las_etapas_avanzan_en_el_tiempo(dataset):'''
assert s.count(anchor)==1
open(p,'w',encoding='utf-8').write(s.replace(anchor,new,1)); print("OK")
PY
uv run --python 3.14 --with pytest --with 'numpy==2.5.3' python -m pytest -q 2>&1 | tail -15

# --- 2026-09-13T21:41:41 · Regenerate data and recompute ds01 figures
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs/src
rm -rf ds01-numpy-y-el-modelo-vectorizado/data ds02-pandas/data ds03-polars-y-el-modelo-lazy/data
for d in ds01-numpy-y-el-modelo-vectorizado ds02-pandas ds03-polars-y-el-modelo-lazy; do
  mkdir -p $d/data && python3 ds01-numpy-y-el-modelo-vectorizado/generar_embudo.py --salida $d/data >/dev/null
done
cp 02-secuencias-perezosas/bench.py ds01-numpy-y-el-modelo-vectorizado/
echo "=== ds01: cifras del capítulo ==="
cd ds01-numpy-y-el-modelo-vectorizado
uv run --python 3.14 --with 'numpy==2.5.3' python - <<'PY'
import numpy as np
from pathlib import Path
from acquisition import *
rows=read_spend_rows(Path("data/pauta.csv")); sp=arrays_from_rows(rows)
acq=read_acquisitions(Path("data/leads.csv"), Path("data/etapas.csv"))
r=cost_per_acquisition_loop(rows,acq)
for k in sorted(r,key=lambda k:-r[k]): print(f"{k:10s} {r[k]:>15,.0f}  (adq {acq[k]})")
print("total int64:", f"{total_spend_with_dtype(sp,np.int64):,}", "· int32:", f"{total_spend_with_dtype(sp,np.int32):,}")
run=np.cumsum(sp.cost); print("desborda int32 en fila:", int(np.argmax(run>2**31-1)), "de", len(sp))
import csv
plans=list(csv.DictReader(open("data/planes_de_tratamiento.csv",encoding="utf-8")))
cuotas=sum(1 for _ in csv.DictReader(open("data/cuotas.csv",encoding="utf-8")))
val=sum(int(p["valor_total_cop"]) for p in plans); sp_tot=total_spend_with_dtype(sp,np.int64)
print(f"planes {len(plans):,} · cuotas {cuotas:,} · valor {val:,} · pauta/valor {sp_tot/val:.1%} · CAC global {sp_tot/len(plans):,.0f} · plan medio {val/len(plans):,.0f}")
PY

# --- 2026-09-13T21:41:57 · Re-run both measurements on the corrected dataset
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs/src/ds01-numpy-y-el-modelo-vectorizado
uv run --python 3.14 --with 'numpy==2.5.3' python bench_vectorized.py --filas 1000 10000 100000 1000000 5000000 2>&1 | grep -v "^Entorno\|^Pauta" | tail -32
echo "### ejercicio 16"; uv run --python 3.14 --with 'numpy==2.5.3' python ejercicio_16_lento.py --filas 2000000 | tail -1
echo "### ds02"; cd ../ds02-pandas && uv run --python 3.14 --with 'pandas==3.0.5' python bench_merge.py --datos data 2>&1 | tail -9

# --- 2026-09-13T21:42:57 · Collect remaining figures for both chapters
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs/src/ds02-pandas
uv run --python 3.14 --with 'pandas==3.0.5' python - <<'PY'
import pandas as pd
from pathlib import Path
from collections_report import *
d=Path("data")
e=pd.read_csv(d/"etapas.csv"); t=pd.read_csv(d/"toques.csv")
print("etapas", len(e), "toques", len(t), "merge:", len(e.merge(t,on="lead_id")))
for f,label in [("cuotas.csv","cuotas"),("planes_de_tratamiento.csv","planes")]:
    raw=pd.read_csv(d/f); print(f"{label} crudo {raw.memory_usage(deep=True).sum()/1e6:.2f} MB · filas {len(raw):,}")
lean_c=pd.read_csv(d/"cuotas.csv", dtype={"plan_id":"category","fecha_pago":"string"})
lean_p=pd.read_csv(d/"planes_de_tratamiento.csv", dtype={"sede":"category","interes":"category"})
print(f"cuotas category {lean_c.memory_usage(deep=True).sum()/1e6:.2f} MB · planes category {lean_p.memory_usage(deep=True).sum()/1e6:.2f} MB")
p=pd.read_csv(d/"pauta.csv"); l=pd.read_csv(d/"leads.csv")
a=p.groupby("canal").size(); b=l.groupby("canal_ultimo_toque").size()
tot=sum(int(a[c])*int(b[c]) for c in a.index)
print("merge catastrófico:", f"{tot:,}", "filas ·", f"{tot*60/1e9:.1f} GB", "· google:", int(a["google"]), "×", int(b["google"]))
PY
cd ../ds01-numpy-y-el-modelo-vectorizado
uv run --python 3.14 --with 'numpy==2.5.3' python bench_vectorized.py --filas 1000 49260 2000000 --sin-comprehension 2>&1 | grep -E "bucle|---"

# --- 2026-09-13T21:43:45 · Update ds01 figures after the data fix
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs
python3 - <<'PY'
import re
def sub(path, pairs):
    s=open(path,encoding='utf-8').read()
    for old,new in pairs:
        if s.count(old)!=1:
            raise SystemExit(f"{path}: {s.count(old)} coincidencias de {old[:70]!r}")
        s=s.replace(old,new)
    open(path,'w',encoding='utf-8').write(s); print("OK", path)

sub('ds01-numpy-y-el-modelo-vectorizado.md', [
("""tiktok      · 9.394.725 COP por paciente adquirido   (215 pacientes)
instagram   · 3.550.765                              (569)
google      · 1.529.579                              (1.320)""",
 """tiktok      · 11.098.164 COP por paciente adquirido   (182 pacientes)
instagram   ·  3.819.254                              (529)
google      ·  1.583.564                              (1.275)"""),
("Ahí ya hay material para una junta. TikTok cuesta **seis veces** lo que cuesta Google por",
 "Ahí ya hay material para una junta. TikTok cuesta **siete veces** lo que cuesta Google por"),
("> ⚠️ **Y esa tabla, que es correcta, probablemente es mentira.** Los 215 pacientes de TikTok son",
 "> ⚠️ **Y esa tabla, que es correcta, probablemente es mentira.** Los 182 pacientes de TikTok son"),
("""| 1.000 | 0,131 ms | 0,196 ms | **0,007 ms** | 0,276 ms |
| 10.000 | 1,298 ms | 1,955 ms | **0,050 ms** | 2,794 ms |
| 100.000 | 14,6 ms | 25,7 ms | **0,469 ms** | 35,2 ms |
| 1.000.000 | 151 ms | 261 ms | **4,75 ms** | 346 ms |
| 5.000.000 | 746 ms | 1.320 ms | **23,9 ms** | 1.775 ms |""",
 """| 1.000 | 0,128 ms | 0,196 ms | **0,007 ms** | 0,276 ms |
| 10.000 | 1,286 ms | 1,997 ms | **0,049 ms** | 2,840 ms |
| 100.000 | 14,8 ms | 29,9 ms | **0,526 ms** | 38,2 ms |
| 1.000.000 | 150 ms | 273 ms | **4,86 ms** | 395 ms |
| 5.000.000 | 787 ms | 1.387 ms | **24,2 ms** | 1.865 ms |"""),
("""> ⚖️ **Veredicto.** Sobre columnas ya construidas, el vectorizado gana **31× a cinco millones de
> filas** y 19× a mil: la ventaja está desde el primer tamaño y crece. Pero **si hay que convertir
> desde la lista de diccionarios, vectorizar pierde en los cinco tamaños**, y a cinco millones
> pierde por 2,4×.""",
 """> ⚖️ **Veredicto.** Sobre columnas ya construidas, el vectorizado gana **32× a cinco millones de
> filas** y 18× a mil: la ventaja está desde el primer tamaño y crece. Pero **si hay que convertir
> desde la lista de diccionarios, vectorizar pierde en los cinco tamaños**, y a cinco millones
> pierde por 2,4×."""),
("""> cinco millones de filas la conversión cuesta 1.751 ms y cada agregación posterior 24 ms, así que
> `k` cuentas vectorizadas valen `1751 + 24k` contra los `746k` del bucle — con `k=2` gana el
> bucle (1.492 ms contra 1.799) y con `k=3` gana el array (2.238 ms contra 1.823). **Tres.** La""",
 """> cinco millones de filas la conversión cuesta 1.840 ms y cada agregación posterior 24 ms, así que
> `k` cuentas vectorizadas valen `1840 + 24k` contra los `787k` del bucle — con `k=2` gana el
> bucle (1.573 ms contra 1.889) y con `k=3` gana el array (2.360 ms contra 1.913). **Tres.** La"""),
("""> millones de filas: **261 ms contra los 151 ms del bucle, un 73% más lenta**.""",
 """> millones de filas: **273 ms contra los 150 ms del bucle, un 82% más lenta**."""),
("""16. Diagnóstico: `src/ds01-…/ejercicio_16_lento.py` calcula el costo por adquisición, usa NumPy
    en todas partes y tarda **3.857 ms con dos millones de filas** — trece veces más que el bucle
    de la sección 5.2, que tarda 291 ms sobre los mismos datos.""",
 """16. Diagnóstico: `src/ds01-…/ejercicio_16_lento.py` calcula el costo por adquisición, usa NumPy
    en todas partes y tarda **3.942 ms con dos millones de filas** — trece veces más que el bucle
    de la sección 5.2, que tarda 296 ms sobre los mismos datos."""),
("""- 🪦 **La pauta de Áurea está revisada contra el resto de la ficción y cuadra.** Son 6.059
  millones de pesos en 27 meses —unos 224 al mes, que parecían muchos— contra **87.271 millones de
  valor contratado**: un **6,9%**, que para una compra electiva y cara es una cifra sana. El costo
  de adquisición global es de **955.876 COP sobre un plan medio de 13,8 millones**.""",
 """- 🪦 **La pauta de Áurea está revisada contra el resto de la ficción y cuadra.** Son 6.059
  millones de pesos en 27 meses —unos 224 al mes, que parecían muchos— contra **83.378 millones de
  valor contratado**: un **7,3%**, que para una compra electiva y cara es una cifra sana. El costo
  de adquisición global es de **999.059 COP sobre un plan medio de 13,7 millones**."""),
])
PY

# --- 2026-09-13T21:43:52 · Locate the comprehension figure
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs
grep -n "73%\|261 ms" ds01-numpy-y-el-modelo-vectorizado.md

# --- 2026-09-13T21:44:12 · Apply ds01 figure updates
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs
python3 - <<'PY'
def sub(path, pairs):
    s=open(path,encoding='utf-8').read()
    for old,new in pairs:
        if s.count(old)!=1:
            raise SystemExit(f"{path}: {s.count(old)} coincidencias de {old[:70]!r}")
        s=s.replace(old,new)
    open(path,'w',encoding='utf-8').write(s); print("OK", path)

sub('ds01-numpy-y-el-modelo-vectorizado.md', [
("""tiktok      · 9.394.725 COP por paciente adquirido   (215 pacientes)
instagram   · 3.550.765                              (569)
google      · 1.529.579                              (1.320)""",
 """tiktok      · 11.098.164 COP por paciente adquirido   (182 pacientes)
instagram   ·  3.819.254                              (529)
google      ·  1.583.564                              (1.275)"""),
("Ahí ya hay material para una junta. TikTok cuesta **seis veces** lo que cuesta Google por",
 "Ahí ya hay material para una junta. TikTok cuesta **siete veces** lo que cuesta Google por"),
("> ⚠️ **Y esa tabla, que es correcta, probablemente es mentira.** Los 215 pacientes de TikTok son",
 "> ⚠️ **Y esa tabla, que es correcta, probablemente es mentira.** Los 182 pacientes de TikTok son"),
("""| 1.000 | 0,131 ms | 0,196 ms | **0,007 ms** | 0,276 ms |
| 10.000 | 1,298 ms | 1,955 ms | **0,050 ms** | 2,794 ms |
| 100.000 | 14,6 ms | 25,7 ms | **0,469 ms** | 35,2 ms |
| 1.000.000 | 151 ms | 261 ms | **4,75 ms** | 346 ms |
| 5.000.000 | 746 ms | 1.320 ms | **23,9 ms** | 1.775 ms |""",
 """| 1.000 | 0,128 ms | 0,196 ms | **0,007 ms** | 0,276 ms |
| 10.000 | 1,286 ms | 1,997 ms | **0,049 ms** | 2,840 ms |
| 100.000 | 14,8 ms | 29,9 ms | **0,526 ms** | 38,2 ms |
| 1.000.000 | 150 ms | 273 ms | **4,86 ms** | 395 ms |
| 5.000.000 | 787 ms | 1.387 ms | **24,2 ms** | 1.865 ms |"""),
("""> ⚖️ **Veredicto.** Sobre columnas ya construidas, el vectorizado gana **31× a cinco millones de
> filas** y 19× a mil""",
 """> ⚖️ **Veredicto.** Sobre columnas ya construidas, el vectorizado gana **32× a cinco millones de
> filas** y 18× a mil"""),
("""> cinco millones de filas la conversión cuesta 1.751 ms y cada agregación posterior 24 ms, así que
> `k` cuentas vectorizadas valen `1751 + 24k` contra los `746k` del bucle — con `k=2` gana el
> bucle (1.492 ms contra 1.799) y con `k=3` gana el array (2.238 ms contra 1.823). **Tres.** La""",
 """> cinco millones de filas la conversión cuesta 1.840 ms y cada agregación posterior 24 ms, así que
> `k` cuentas vectorizadas valen `1840 + 24k` contra los `787k` del bucle — con `k=2` gana el
> bucle (1.573 ms contra 1.889) y con `k=3` gana el array (2.360 ms contra 1.913). **Tres.** La"""),
("""> el bucle hacía una. Medida sobre un millón de filas: **261 ms contra los 151 ms del bucle, un
> 73% más lenta**.""",
 """> el bucle hacía una. Medida sobre un millón de filas: **273 ms contra los 150 ms del bucle, un
> 82% más lenta**."""),
("""    en todas partes y tarda **3.857 ms con dos millones de filas** — trece veces más que el bucle
    de la sección 5.2, que tarda 291 ms sobre los mismos datos.""",
 """    en todas partes y tarda **3.942 ms con dos millones de filas** — trece veces más que el bucle
    de la sección 5.2, que tarda 296 ms sobre los mismos datos."""),
("""  millones de pesos en 27 meses —unos 224 al mes, que parecían muchos— contra **87.271 millones de
  valor contratado**: un **6,9%**, que para una compra electiva y cara es una cifra sana. El costo
  de adquisición global es de **955.876 COP sobre un plan medio de 13,8 millones**.""",
 """  millones de pesos en 27 meses —unos 224 al mes, que parecían muchos— contra **83.378 millones de
  valor contratado**: un **7,3%**, que para una compra electiva y cara es una cifra sana. El costo
  de adquisición global es de **999.059 COP sobre un plan medio de 13,7 millones**."""),
])
PY

# --- 2026-09-13T21:44:54 · Update ds02 figures after the data fix
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs
python3 - <<'PY'
def sub(path, pairs):
    s=open(path,encoding='utf-8').read()
    for old,new in pairs:
        if s.count(old)!=1: raise SystemExit(f"{path}: {s.count(old)} de {old[:70]!r}")
        s=s.replace(old,new)
    open(path,'w',encoding='utf-8').write(s); print("OK", path)

sub('ds02-pandas.md', [
("""> estilo. Unir 81.000 filas para producir 20 cuesta 295 ms; agregar primero y unir después,
> 12. Es la misma tabla y la misma biblioteca.""",
 """> estilo. Unir 81.000 filas para producir 20 cuesta 287 ms; agregar primero y unir después,
> 11. Es la misma tabla y la misma biblioteca."""),
("""La cobranza de Áurea vive en dos archivos. Uno tiene los planes —6.339 filas, una por plan
aceptado, con su sede, su interés y su valor total— y el otro las cuotas: 81.370 filas, una
por cuota programada, con su `fecha_pago` vacía cuando nadie la pagó.""",
 """La cobranza de Áurea vive en dos archivos. Uno tiene los planes —6.065 filas, una por plan
aceptado, con su sede, su interés y su valor total— y el otro las cuotas: 81.274 filas, una
por cuota programada, con su `fecha_pago` vacía cuando nadie la pagó."""),
("""`apply(axis=1)` **construye una Series por fila** para pasártela a la función. Ochenta y un mil
Series, ochenta y un mil llamadas a Python.""",
 """`apply(axis=1)` **construye una Series por fila** para pasártela a la función. Ochenta y un mil
Series, ochenta y un mil llamadas a Python."""),
("""# ✅ La condición como máscara: una decisión sobre las 81.370 filas, en C.""",
 """# ✅ La condición como máscara: una decisión sobre las 81.274 filas, en C."""),
("""Un cambio de línea: **295 ms a 21 ms**, medido en la sección 6.""",
 """Un cambio de línea: **287 ms a 18 ms**, medido en la sección 6."""),
("""# ❌ Unir 81.370 cuotas con 6.339 planes, y después colapsar a 20 filas.""",
 """# ❌ Unir 81.274 cuotas con 6.065 planes, y después colapsar a 20 filas."""),
("""# ✅ Colapsar las cuotas a 6.339 filas primero, y unir 6.339 contra 6.339.""",
 """# ✅ Colapsar las cuotas a 6.065 filas primero, y unir 6.065 contra 6.065."""),
("""**El costo, medido:** 21,4 ms y 38,5 MB contra 12,3 ms y 27,6 MB.""",
 """**El costo, medido:** 18,4 ms y 40,6 MB contra 11,1 ms y 30,4 MB."""),
("""`canal` no es una llave: es una columna con tres valores. El resultado son
**350.616.260 filas** —16.420 × 8.512 solo para Google, y otro tanto para los demás—, que a
sesenta bytes por fila son unos **21 GB**.""",
 """`canal` no es una llave: es una columna con tres valores. El resultado son
**351.979.120 filas** —16.420 × 8.574 solo para Google, y otro tanto para los demás—, que a
sesenta bytes por fila son unos **21 GB**."""),
("""- **`usecols`** es la optimización más barata y la que más se olvida: de las cinco columnas de
  `cuotas.csv` el informe usa tres, y las otras dos son 81.370 filas de memoria que se paga sin
  usarse. Entre `usecols` y los dtypes, la entrada del informe baja de 17,4 a 10,4 MB.""",
 """- **`usecols`** es la optimización más barata y la que más se olvida: de las cinco columnas de
  `cuotas.csv` el informe usa tres, y las otras dos son 81.274 filas de memoria que se paga sin
  usarse. Entre `usecols` y los dtypes, la entrada del informe baja de 17,3 a 10,4 MB."""),
("""- **`category` ahorra, y menos de lo que dice la fama.** Medido: `cuotas.csv` pasa de 15,5 a
  11,4 MB y `planes_de_tratamiento.csv` de 1,92 a 1,21 MB. Es un 26% y un 37%, no un orden de
  magnitud.""",
 """- **`category` ahorra, y menos de lo que dice la fama.** Medido: `cuotas.csv` pasa de 15,4 a
  11,4 MB y `planes_de_tratamiento.csv` de 1,84 a 1,16 MB. Es un 26% y un 37%, no un orden de
  magnitud."""),
("""- **`groupby` antes del `merge`.** 81.370 filas se vuelven 6.339 antes de tocar la otra tabla.""",
 """- **`groupby` antes del `merge`.** 81.274 filas se vuelven 6.065 antes de tocar la otra tabla."""),
("""**Condiciones.** CPython 3.14.5, pandas 3.0.5, macOS 26.6.2 sobre Apple Silicon de 8 núcleos —el
entorno de referencia del curso—. Datos reales del Embudo con semilla 20260913: 6.339 planes y
81.370 cuotas, que es el tamaño verdadero de Áurea y no una proyección.""",
 """**Condiciones.** CPython 3.14.5, pandas 3.0.5, macOS 26.6.2 sobre Apple Silicon de 8 núcleos —el
entorno de referencia del curso—. Datos reales del Embudo con semilla 20260913: 6.065 planes y
81.274 cuotas, que es el tamaño verdadero de Áurea y no una proyección."""),
("""| solo importar pandas | — | — | 76,7 MB | — | — |
| unir + `apply` | 294,8 ms | 295,0 ms | 134,3 MB | 57,6 MB | 17,4 MB |
| unir + máscara | 21,4 ms | 22,9 ms | 115,2 MB | 38,5 MB | 17,4 MB |
| **agregar + unir** | **12,3 ms** | **12,7 ms** | **104,3 MB** | **27,6 MB** | 10,4 MB |

81.370 cuotas de entrada, 20 filas de salida.""",
 """| solo importar pandas | — | — | 76,9 MB | — | — |
| unir + `apply` | 286,7 ms | 295,8 ms | 131,2 MB | 54,3 MB | 17,3 MB |
| unir + máscara | 18,4 ms | 19,6 ms | 117,5 MB | 40,6 MB | 17,3 MB |
| **agregar + unir** | **11,1 ms** | **11,5 ms** | **107,3 MB** | **30,4 MB** | 10,4 MB |

81.274 cuotas de entrada, 20 filas de salida."""),
("""> ⚖️ **Veredicto.** Quitar el `apply` es el cambio más rentable que existe en pandas: **13,8× en
> tiempo** por una línea, y ninguna pérdida de legibilidad. Cambiar el orden —agregar y después
> unir— agrega otro **1,7×**, para un total de **24×** contra la versión ingenua, y sobre todo
> **baja la memoria del trabajo a la mitad** (57,6 → 27,6 MB sobre la línea base), que es lo que
> decide si el informe corre o no en la máquina virtual de dos núcleos de Áurea.""",
 """> ⚖️ **Veredicto.** Quitar el `apply` es el cambio más rentable que existe en pandas: **15,6× en
> tiempo** por una línea, y ninguna pérdida de legibilidad. Cambiar el orden —agregar y después
> unir— agrega otro **1,7×**, para un total de **26×** contra la versión ingenua, y sobre todo
> **baja la memoria del trabajo casi a la mitad** (54,3 → 30,4 MB sobre la línea base), que es lo
> que decide si el informe corre o no en la máquina virtual de dos núcleos de Áurea."""),
("""> **Y el umbral, dicho honestamente: a este tamaño nada de esto importa.** Son 295 ms contra 12,
> una vez al mes,""",
 """> **Y el umbral, dicho honestamente: a este tamaño nada de esto importa.** Son 287 ms contra 11,
> una vez al mes,"""),
("""> **Los 76,7 MB de la línea base son el número incómodo de la tabla.**""",
 """> **Los 76,9 MB de la línea base son el número incómodo de la tabla.**"""),
("""de la sección 6 arranca en **76,7 MB para un proceso que no hizo nada**. Si comparas los totales
crudos vas a concluir que el `apply` gasta el doble que la versión buena; si descuentas la línea
base, la relación real es 57,6 contra 27,6.""",
 """de la sección 6 arranca en **76,9 MB para un proceso que no hizo nada**. Si comparas los totales
crudos vas a concluir que el `apply` gasta un 22% más que la versión buena; si descuentas la línea
base, la relación real es 54,3 contra 30,4 — un 79% más."""),
("""Esos dos números son la entrada de `ds03`. Porque hay una pregunta que esta sección no puede
contestar: **¿por qué estás cargando 81.370 filas en memoria para producir veinte?**""",
 """Esos dos números son la entrada de `ds03`. Porque hay una pregunta que esta sección no puede
contestar: **¿por qué estás cargando 81.274 filas en memoria para producir veinte?**"""),
("""`validate=` en todos los
`merge`, y con una regla que vale más que la biblioteca: **agrega hasta la granularidad de la
respuesta antes de unir**. También terminas con dos números incómodos: el proceso pesa 76,7 MB
antes de leer un solo dato,""",
 """`validate=` en todos los
`merge`, y con una regla que vale más que la biblioteca: **agrega hasta la granularidad de la
respuesta antes de unir**. También terminas con dos números incómodos: el proceso pesa 76,9 MB
antes de leer un solo dato,"""),
("""16. El `merge` catastrófico por `canal` produce 350.616.260 filas.""",
 """16. El `merge` catastrófico por `canal` produce 351.979.120 filas."""),
("""17. Toma las 81.370 cuotas y construye el informe sin pandas,""",
 """17. Toma las 81.274 cuotas y construye el informe sin pandas,"""),
("""23. Los 76,7 MB de la línea base son el precio de importar pandas.""",
 """23. Los 76,9 MB de la línea base son el precio de importar pandas."""),
("""8. Une `etapas.csv` con `toques.csv` por `lead_id` sin `validate=` y cuenta las filas.""",
 """8. Une `etapas.csv` con `toques.csv` por `lead_id` sin `validate=` y cuenta las filas."""),
])
PY

# --- 2026-09-13T21:45:00 · Locate remaining 76,7 mentions
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs
grep -n "76,7\|57,6 contra" ds02-pandas.md

# --- 2026-09-13T21:45:03 · Read the exact wrapping of that paragraph
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs
sed -n 355,360p ds02-pandas.md

# --- 2026-09-13T21:45:33 · Apply ds02 figure updates
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs
python3 - <<'PY'
def sub(path, pairs):
    s=open(path,encoding='utf-8').read()
    for old,new in pairs:
        if s.count(old)!=1: raise SystemExit(f"{path}: {s.count(old)} de {old[:70]!r}")
        s=s.replace(old,new)
    open(path,'w',encoding='utf-8').write(s); print("OK", path)

sub('ds02-pandas.md', [
("""> estilo. Unir 81.000 filas para producir 20 cuesta 295 ms; agregar primero y unir después,
> 12. Es la misma tabla y la misma biblioteca.""",
 """> estilo. Unir 81.000 filas para producir 20 cuesta 287 ms; agregar primero y unir después,
> 11. Es la misma tabla y la misma biblioteca."""),
("""La cobranza de Áurea vive en dos archivos. Uno tiene los planes —6.339 filas, una por plan
aceptado, con su sede, su interés y su valor total— y el otro las cuotas: 81.370 filas, una""",
 """La cobranza de Áurea vive en dos archivos. Uno tiene los planes —6.065 filas, una por plan
aceptado, con su sede, su interés y su valor total— y el otro las cuotas: 81.274 filas, una"""),
("# ✅ La condición como máscara: una decisión sobre las 81.370 filas, en C.",
 "# ✅ La condición como máscara: una decisión sobre las 81.274 filas, en C."),
("Un cambio de línea: **295 ms a 21 ms**, medido en la sección 6.",
 "Un cambio de línea: **287 ms a 18 ms**, medido en la sección 6."),
("# ❌ Unir 81.370 cuotas con 6.339 planes, y después colapsar a 20 filas.",
 "# ❌ Unir 81.274 cuotas con 6.065 planes, y después colapsar a 20 filas."),
("# ✅ Colapsar las cuotas a 6.339 filas primero, y unir 6.339 contra 6.339.",
 "# ✅ Colapsar las cuotas a 6.065 filas primero, y unir 6.065 contra 6.065."),
("**El costo, medido:** 21,4 ms y 38,5 MB contra 12,3 ms y 27,6 MB.",
 "**El costo, medido:** 18,4 ms y 40,6 MB contra 11,1 ms y 30,4 MB."),
("""**350.616.260 filas** —16.420 × 8.512 solo para Google""",
 """**351.979.120 filas** —16.420 × 8.574 solo para Google"""),
("""  `cuotas.csv` el informe usa tres, y las otras dos son 81.370 filas de memoria que se paga sin
  usarse. Entre `usecols` y los dtypes, la entrada del informe baja de 17,4 a 10,4 MB.""",
 """  `cuotas.csv` el informe usa tres, y las otras dos son 81.274 filas de memoria que se paga sin
  usarse. Entre `usecols` y los dtypes, la entrada del informe baja de 17,3 a 10,4 MB."""),
("""- **`category` ahorra, y menos de lo que dice la fama.** Medido: `cuotas.csv` pasa de 15,5 a
  11,4 MB y `planes_de_tratamiento.csv` de 1,92 a 1,21 MB.""",
 """- **`category` ahorra, y menos de lo que dice la fama.** Medido: `cuotas.csv` pasa de 15,4 a
  11,4 MB y `planes_de_tratamiento.csv` de 1,84 a 1,16 MB."""),
("- **`groupby` antes del `merge`.** 81.370 filas se vuelven 6.339 antes de tocar la otra tabla.",
 "- **`groupby` antes del `merge`.** 81.274 filas se vuelven 6.065 antes de tocar la otra tabla."),
("""entorno de referencia del curso—. Datos reales del Embudo con semilla 20260913: 6.339 planes y
81.370 cuotas, que es el tamaño verdadero de Áurea y no una proyección.""",
 """entorno de referencia del curso—. Datos reales del Embudo con semilla 20260913: 6.065 planes y
81.274 cuotas, que es el tamaño verdadero de Áurea y no una proyección."""),
("""| solo importar pandas | — | — | 76,7 MB | — | — |
| unir + `apply` | 294,8 ms | 295,0 ms | 134,3 MB | 57,6 MB | 17,4 MB |
| unir + máscara | 21,4 ms | 22,9 ms | 115,2 MB | 38,5 MB | 17,4 MB |
| **agregar + unir** | **12,3 ms** | **12,7 ms** | **104,3 MB** | **27,6 MB** | 10,4 MB |

81.370 cuotas de entrada, 20 filas de salida.""",
 """| solo importar pandas | — | — | 76,9 MB | — | — |
| unir + `apply` | 286,7 ms | 295,8 ms | 131,2 MB | 54,3 MB | 17,3 MB |
| unir + máscara | 18,4 ms | 19,6 ms | 117,5 MB | 40,6 MB | 17,3 MB |
| **agregar + unir** | **11,1 ms** | **11,5 ms** | **107,3 MB** | **30,4 MB** | 10,4 MB |

81.274 cuotas de entrada, 20 filas de salida."""),
("""> ⚖️ **Veredicto.** Quitar el `apply` es el cambio más rentable que existe en pandas: **13,8× en
> tiempo** por una línea, y ninguna pérdida de legibilidad. Cambiar el orden —agregar y después
> unir— agrega otro **1,7×**, para un total de **24×** contra la versión ingenua, y sobre todo
> **baja la memoria del trabajo a la mitad** (57,6 → 27,6 MB sobre la línea base), que es lo que
> decide si el informe corre o no en la máquina virtual de dos núcleos de Áurea.""",
 """> ⚖️ **Veredicto.** Quitar el `apply` es el cambio más rentable que existe en pandas: **15,6× en
> tiempo** por una línea, y ninguna pérdida de legibilidad. Cambiar el orden —agregar y después
> unir— agrega otro **1,7×**, para un total de **26×** contra la versión ingenua, y sobre todo
> **baja la memoria del trabajo casi a la mitad** (54,3 → 30,4 MB sobre la línea base), que es lo
> que decide si el informe corre o no en la máquina virtual de dos núcleos de Áurea."""),
("""> **Y el umbral, dicho honestamente: a este tamaño nada de esto importa.** Son 295 ms contra 12,
> una vez al mes,""",
 """> **Y el umbral, dicho honestamente: a este tamaño nada de esto importa.** Son 287 ms contra 11,
> una vez al mes,"""),
("> **Los 76,7 MB de la línea base son el número incómodo de la tabla.**",
 "> **Los 76,9 MB de la línea base son el número incómodo de la tabla.**"),
("""la sección 6 arranca en **76,7 MB para un proceso que no hizo nada**. Si comparas los totales
crudos vas a concluir que el `apply` gasta el doble que la versión buena; si descuentas la línea
base, la relación real es 57,6 contra 27,6.""",
 """la sección 6 arranca en **76,9 MB para un proceso que no hizo nada**. Si comparas los totales
crudos vas a concluir que el `apply` gasta un 22% más que la versión buena; si descuentas la línea
base, la relación real es 54,3 contra 30,4 — un 79% más."""),
("contestar: **¿por qué estás cargando 81.370 filas en memoria para producir veinte?**",
 "contestar: **¿por qué estás cargando 81.274 filas en memoria para producir veinte?**"),
("""respuesta antes de unir**. También terminas con dos números incómodos: el proceso pesa 76,7 MB
antes de leer un solo dato,""",
 """respuesta antes de unir**. También terminas con dos números incómodos: el proceso pesa 76,9 MB
antes de leer un solo dato,"""),
("16. El `merge` catastrófico por `canal` produce 350.616.260 filas.",
 "16. El `merge` catastrófico por `canal` produce 351.979.120 filas."),
("17. Toma las 81.370 cuotas y construye el informe sin pandas,",
 "17. Toma las 81.274 cuotas y construye el informe sin pandas,"),
("23. Los 76,7 MB de la línea base son el precio de importar pandas.",
 "23. Los 76,9 MB de la línea base son el precio de importar pandas."),
])
PY

# --- 2026-09-13T21:46:08 · Propagate corrected figures to BENCHMARKS, INSTINTOS and READMEs
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs
python3 - <<'PY'
def sub(path, pairs):
    s=open(path,encoding='utf-8').read()
    for old,new in pairs:
        if s.count(old)!=1: raise SystemExit(f"{path}: {s.count(old)} de {old[:60]!r}")
        s=s.replace(old,new)
    open(path,'w',encoding='utf-8').write(s); print("OK", path)

sub('BENCHMARKS.md', [
("""| 1.000 | 0,131 ms | 0,196 ms | **0,007 ms** | 0,276 ms |
| 100.000 | 14,6 ms | 25,7 ms | **0,469 ms** | 35,2 ms |
| 5.000.000 | 746 ms | 1.320 ms | **23,9 ms** | 1.775 ms |""",
 """| 1.000 | 0,128 ms | 0,196 ms | **0,007 ms** | 0,276 ms |
| 100.000 | 14,8 ms | 29,9 ms | **0,526 ms** | 38,2 ms |
| 5.000.000 | 787 ms | 1.387 ms | **24,2 ms** | 1.865 ms |"""),
("""⚖️ **31× sobre columnas ya construidas, y una derrota de 2,4× si hay que convertir.** El umbral no
es de tamaño sino de reúso: `k` cuentas vectorizadas valen `1751 + 24k` ms contra `746k` del bucle,
así que **a partir de la tercera** agregación sobre las mismas columnas el array gana. Con una
sola, pierde a cualquier tamaño. Y la comprehension por canal —la versión "pythónica"— es **un 73%
más lenta que el bucle** al que pretende mejorar.""",
 """⚖️ **32× sobre columnas ya construidas, y una derrota de 2,4× si hay que convertir.** El umbral no
es de tamaño sino de reúso: `k` cuentas vectorizadas valen `1840 + 24k` ms contra `787k` del bucle,
así que **a partir de la tercera** agregación sobre las mismas columnas el array gana. Con una
sola, pierde a cualquier tamaño. Y la comprehension por canal —la versión "pythónica"— es **un 82%
más lenta que el bucle** al que pretende mejorar."""),
("""**Condiciones:** pandas 3.0.5. Datos **reales** de Áurea, sin repetir bloque: 6.339 planes y 81.370
cuotas, semilla 20260913.""",
 """**Condiciones:** pandas 3.0.5. Datos **reales** de Áurea, sin repetir bloque: 6.065 planes y 81.274
cuotas, semilla 20260913."""),
("""| solo importar pandas | — | — | 76,7 MB | — |
| unir + `apply` | 294,8 ms | 295,0 ms | 134,3 MB | 57,6 MB |
| unir + máscara | 21,4 ms | 22,9 ms | 115,2 MB | 38,5 MB |
| **agregar + unir** | **12,3 ms** | **12,7 ms** | **104,3 MB** | **27,6 MB** |""",
 """| solo importar pandas | — | — | 76,9 MB | — |
| unir + `apply` | 286,7 ms | 295,8 ms | 131,2 MB | 54,3 MB |
| unir + máscara | 18,4 ms | 19,6 ms | 117,5 MB | 40,6 MB |
| **agregar + unir** | **11,1 ms** | **11,5 ms** | **107,3 MB** | **30,4 MB** |"""),
("""⚖️ **24× en total, y la mitad de la memoria.** Quitar `apply(axis=1)` da 13,8× por una línea;
cambiar el orden —agregar antes de unir— agrega otro 1,7× y baja el trabajo de 57,6 a 27,6 MB.
**El umbral, dicho entero: a la escala de Áurea nada de esto decide nada** —son 295 ms contra 12,""",
 """⚖️ **26× en total, y casi la mitad de la memoria.** Quitar `apply(axis=1)` da 15,6× por una línea;
cambiar el orden —agregar antes de unir— agrega otro 1,7× y baja el trabajo de 54,3 a 30,4 MB.
**El umbral, dicho entero: a la escala de Áurea nada de esto decide nada** —son 287 ms contra 11,"""),
("""**Y el número incómodo:** importar pandas cuesta **76,7 MB** antes de leer un solo dato, para un""",
 """**Y el número incómodo:** importar pandas cuesta **76,9 MB** antes de leer un solo dato, para un"""),
])

sub('INSTINTOS.md', [
("""El cálculo vectorizado gana **31×** sobre columnas ya construidas, y el **programa** pierde **2,4×**""",
 """El cálculo vectorizado gana **32×** sobre columnas ya construidas, y el **programa** pierde **2,4×**"""),
(""""los bucles son lentos en Python", recorre la lista una vez por categoría y sale **un 73% más
lenta** que el bucle que venía a mejorar.""",
 """"los bucles son lentos en Python", recorre la lista una vez por categoría y sale **un 82% más
lenta** que el bucle que venía a mejorar."""),
("""Series para decidir ochenta y un mil veces algo que era una comparación de columna. Cuesta **13,8×**
y se arregla con una línea.""",
 """Series para decidir ochenta y un mil veces algo que era una comparación de columna. Cuesta **15,6×**
y se arregla con una línea."""),
("""Su hermano mayor es de diseño y es más caro de descubrir porque el resultado sale bien: **unir antes
de agregar**. Materializar 81.370 filas para producir veinte cuesta el doble de memoria que""",
 """Su hermano mayor es de diseño y es más caro de descubrir porque el resultado sale bien: **unir antes
de agregar**. Materializar 81.274 filas para producir veinte cuesta un 79% más de memoria que"""),
])

sub('src/ds02-pandas/README.md', [
("""El informe usa dos de los ocho archivos: `planes_de_tratamiento.csv` (6.339 filas) y `cuotas.csv`
(81.370).""",
 """El informe usa dos de los ocho archivos: `planes_de_tratamiento.csv` (6.065 filas) y `cuotas.csv`
(81.274)."""),
("""fila «solo importar», que es la línea base: **76,7 MB los gasta pandas por existir**""",
 """fila «solo importar», que es la línea base: **76,9 MB los gasta pandas por existir**"""),
("""2. **`validate=` atrapa la unión muchos-a-muchos.** Unir `etapas` con `toques` por `lead_id` pasa
   de 66.153 filas a 137.649 sin que nadie avise""",
 """2. **`validate=` atrapa la unión muchos-a-muchos.** Unir `etapas` con `toques` por `lead_id` pasa
   de 64.062 filas a 133.288 sin que nadie avise"""),
])

sub('src/ds02-pandas/test_collections_report.py', [
("    assert len(exploded) > len(stages)            # 137.649 contra 66.153",
 "    assert len(exploded) > len(stages)            # 133.288 contra 64.062"),
])

sub('src/ds01-numpy-y-el-modelo-vectorizado/README.md', [
("""| `toques.csv` | ~64.000 | Cada punto de contacto, en orden. Es la materia de la atribución |
| `etapas.csv` | ~66.000 | El avance por el embudo, etapa por etapa y con su reloj |
| `planes_de_tratamiento.csv` | ~6.300 | Lo aceptado, con su valor entre 8 y 22 millones |
| `cuotas.csv` | ~81.000 | Veinticuatro cuotas por plan, con su fecha de pago o sin ella |""",
 """| `toques.csv` | ~62.700 | Cada punto de contacto, en orden. Es la materia de la atribución |
| `etapas.csv` | ~64.000 | El avance por el embudo, etapa por etapa y con su reloj |
| `planes_de_tratamiento.csv` | ~6.100 | Lo aceptado, con su valor entre 8 y 22 millones |
| `cuotas.csv` | ~81.300 | Veinticuatro cuotas por plan, con su fecha de pago o sin ella |"""),
("| `test_generar_embudo.py` · `test_acquisition.py` | 37 pruebas: `pytest` |",
 "| `test_generar_embudo.py` · `test_acquisition.py` | 39 pruebas: `pytest` |"),
])
PY

# --- 2026-09-13T21:46:19 · Find stale counts in code and prose
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs
grep -n "6\.300\|81\.000\|6.339\|81.370" src/ds02-pandas/collections_report.py ds02-pandas.md src/ds01-numpy-y-el-modelo-vectorizado/acquisition.py

# --- 2026-09-13T21:46:27 · Sync remaining counts in code and prose
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs
python3 - <<'PY'
import re
p='src/ds02-pandas/collections_report.py'; s=open(p,encoding='utf-8').read()
s=s.replace("81.000 filas","81.300 filas").replace("81.000 filas de una vez","81.300 filas de una vez")
s=s.replace("—6.300 filas—","—6.100 filas—").replace("81.300 filas contra 6.300 a unir 6.300 contra 6.300","81.300 filas contra 6.100 a unir 6.100 contra 6.100")
s=s.replace("aquí hay 6.300 grupos","aquí hay 6.100 grupos")
# el comentario de `category` prometía un orden de magnitud y la medición dio 26-37%
s=s.replace("# repetidas en 81.300 filas, la diferencia es de un orden de magnitud, y la sección 6 la mide.",
            "# repetidas en 81.300 filas ahorra entre un 26% y un 37%, medido en la sección 6 — bastante\n# menos de lo que promete su fama.")
open(p,'w',encoding='utf-8').write(s); print("OK código")

p='ds02-pandas.md'; s=open(p,encoding='utf-8').read()
s=s.replace("    # por grupo, y aquí hay 6.300 grupos.","    # por grupo, y aquí hay 6.100 grupos.")
s=s.replace("> de Áurea: los 81.370 registros son los de verdad","> de Áurea: los 81.274 registros son los de verdad")
s=s.replace('MB de pico sobre 81.370 cuotas','MB de pico sobre 81.274 cuotas')
open(p,'w',encoding='utf-8').write(s); print("OK prosa")
PY
grep -rn "6\.300\|81\.370\|81\.000" src/ds02-pandas/*.py ds02-pandas.md | head

# --- 2026-09-13T21:46:38 · Verify all suites after the data correction
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs/src
for d in ds01-numpy-y-el-modelo-vectorizado ds02-pandas ds07-scikit-learn; do printf "%-42s " "$d"; (cd $d && uv run --python 3.14 --with pytest --with 'numpy==2.5.3' --with 'pandas==3.0.5' python -m pytest -q 2>&1|tail -1); done
for d in ds01-numpy-y-el-modelo-vectorizado ds02-pandas ds07-scikit-learn; do printf "lint %-38s" "$d"; (cd $d && uvx ruff@0.16.7 check . >/dev/null 2>&1 && echo OK || echo FALLA); done

# --- 2026-09-13T21:47:44 · Add the Parquet variant and verify all five agree
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs/src/ds03-polars-y-el-modelo-lazy
python3 - <<'PY'
p='consolidation.py'; s=open(p,encoding='utf-8').read()
old="""    result = (table.with_columns(pl.col(pl.Int64).fill_null(0))
              .select(COLUMNS).sort("sede", "mes").collect())
    return [tuple(row) for row in result.iter_rows()]"""
new="""    # `fill_null` sobre `pl.Int64` no alcanza: `pl.len()` devuelve `UInt32`, así que la
    # columna de leads se quedaba con `null` en los meses sin leads y el resultado dejaba de
    # coincidir con los otros tres motores. Se castea primero y se rellena después.
    counters = [name for name in COLUMNS[2:]]
    result = (table.with_columns(pl.col(counters).cast(pl.Int64).fill_null(0))
              .select(COLUMNS).sort("sede", "mes").collect())
    return [tuple(row) for row in result.iter_rows()]"""
assert s.count(old)==1
s=s.replace(old,new)

old2='''ENGINES = {
    "bucle": consolidate_loop,
    "pandas": consolidate_pandas,
    "polars (lazy)": consolidate_polars,
    "duckdb": consolidate_duckdb,
}'''
new2='''def write_parquet(data: Path, target: Path) -> None:
    """Convierte los cuatro CSV a Parquet, con DuckDB y sin cargar nada en memoria.

    Se mide aparte, en la sección 6, porque es un costo que se paga **una vez** y que la
    comparación de motores esconde si se mete dentro. Quien convierte una vez y consulta
    cien veces no está en la misma situación que quien hace las dos cosas cada mañana.
    """
    import duckdb

    target.mkdir(parents=True, exist_ok=True)
    connection = duckdb.connect()
    for name in ("pauta", "leads", "planes_de_tratamiento", "cuotas"):
        connection.execute(
            f"COPY (SELECT * FROM read_csv('{data / name}.csv')) "
            f"TO '{target / name}.parquet' (FORMAT parquet, COMPRESSION zstd)")


def consolidate_duckdb_parquet(data: Path) -> list[Row]:
    """La misma consulta de DuckDB, sobre Parquet en vez de CSV.

    Es la única diferencia: el SQL es idéntico. Lo que cambia es que Parquet trae el
    esquema escrito, guarda cada columna por separado y anota estadísticas por bloque, así
    que el motor puede **no leer** lo que no necesita. La sección 6 dice cuánto vale eso.
    """
    return _duckdb_query(data, "read_parquet", ".parquet")


ENGINES = {
    "bucle": consolidate_loop,
    "pandas": consolidate_pandas,
    "polars (lazy)": consolidate_polars,
    "duckdb (csv)": consolidate_duckdb,
    "duckdb (parquet)": consolidate_duckdb_parquet,
}'''
assert s.count(old2)==1
s=s.replace(old2,new2)

# factorizar la consulta para las dos variantes de duckdb
old3='''    query = """'''
new3='''    return _duckdb_query(data, "read_csv", ".csv")


def _duckdb_query(data: Path, reader: str, suffix: str) -> list[Row]:
    """El SQL compartido por las dos variantes de DuckDB.

    Es la única función auxiliar compartida del módulo, y existe porque las dos variantes
    **tienen que ejecutar exactamente la misma consulta**: si el Parquet ganara por llevar
    un SQL distinto, la comparación no diría nada sobre el formato.
    """
    import duckdb

    query = f"""'''
assert s.count(old3)==1
s=s.replace(old3,new3)
s=s.replace("""        WITH spend AS (
            SELECT sede, strftime(fecha, '%Y-%m') AS mes, sum(costo_cop) AS gasto_cop
            FROM read_csv($pauta) GROUP BY 1, 2),
        leads AS (
            SELECT sede, strftime(creado, '%Y-%m') AS mes, count(*) AS leads
            FROM read_csv($leads) GROUP BY 1, 2),
        plans AS (
            SELECT sede, strftime(fecha_aceptacion, '%Y-%m') AS mes, count(*) AS planes,
                   sum(valor_total_cop) AS valor_contratado_cop
            FROM read_csv($planes) GROUP BY 1, 2),
        collected AS (
            SELECT p.sede, strftime(c.fecha_pago, '%Y-%m') AS mes,
                   sum(c.valor_cop) AS cobrado_cop
            FROM read_csv($cuotas) c JOIN read_csv($planes) p USING (plan_id)
            WHERE c.fecha_pago IS NOT NULL GROUP BY 1, 2)""",
"""        WITH spend AS (
            SELECT sede, strftime(fecha, '%Y-%m') AS mes, sum(costo_cop) AS gasto_cop
            FROM {reader}($pauta) GROUP BY 1, 2),
        leads AS (
            SELECT sede, strftime(creado, '%Y-%m') AS mes, count(*) AS leads
            FROM {reader}($leads) GROUP BY 1, 2),
        plans AS (
            SELECT sede, strftime(fecha_aceptacion, '%Y-%m') AS mes, count(*) AS planes,
                   sum(valor_total_cop) AS valor_contratado_cop
            FROM {reader}($planes) GROUP BY 1, 2),
        collected AS (
            SELECT p.sede, strftime(c.fecha_pago, '%Y-%m') AS mes,
                   sum(c.valor_cop) AS cobrado_cop
            FROM {reader}($cuotas) c JOIN {reader}($planes) p USING (plan_id)
            WHERE c.fecha_pago IS NOT NULL GROUP BY 1, 2)""")
s=s.replace("""    parameters = {"pauta": str(data / "pauta.csv"), "leads": str(data / "leads.csv"),
                  "planes": str(data / "planes_de_tratamiento.csv"),
                  "cuotas": str(data / "cuotas.csv")}""",
"""    parameters = {"pauta": str(data / f"pauta{suffix}"),
                  "leads": str(data / f"leads{suffix}"),
                  "planes": str(data / f"planes_de_tratamiento{suffix}"),
                  "cuotas": str(data / f"cuotas{suffix}")}""")
# quitar el import duplicado dentro de consolidate_duckdb
s=s.replace('''    Es la opción con el modelo mental más corto para este lector, y por eso su número
    importa más que su elegancia.
    """
    import duckdb

    return _duckdb_query''','''    Es la opción con el modelo mental más corto para este lector, y por eso su número
    importa más que su elegancia.
    """
    return _duckdb_query''')
open(p,'w',encoding='utf-8').write(s); print("OK")
PY
uv run --python 3.14 --with 'pandas==3.0.5' --with 'polars==1.44.2' --with 'duckdb==1.5.5' --with 'pyarrow==25.0.1' python - <<'PY'
from pathlib import Path
from consolidation import ENGINES, write_parquet
write_parquet(Path("data"), Path("data/parquet"))
ref=None
for name, fn in ENGINES.items():
    src = Path("data/parquet") if "parquet" in name else Path("data")
    rows = fn(src)
    if ref is None: ref=rows; print(f"{name:18s} {len(rows)} filas · referencia")
    else: print(f"{name:18s} {len(rows)} filas · == bucle: {rows==ref}")
PY

# --- 2026-09-13T21:48:22 · Build the four measurement sizes
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs/src/ds03-polars-y-el-modelo-lazy
rm -rf data && time uv run --python 3.14 --with 'duckdb==1.5.5' python preparar_tamanos.py --salida data 2>&1 | tail -8

# --- 2026-09-13T21:49:26 · Run the five-engine benchmark
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs/src/ds03-polars-y-el-modelo-lazy
time uv run --python 3.14 --with 'pandas==3.0.5' --with 'polars==1.44.2' --with 'duckdb==1.5.5' --with 'pyarrow==25.0.1' python bench_engines.py --datos data 2>&1 | tail -25

# --- 2026-09-13T21:50:33 · Count the shared SQL helper in the LOC column
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs/src/ds03-polars-y-el-modelo-lazy
python3 - <<'PY'
p='bench_engines.py'; s=open(p,encoding='utf-8').read()
s=s.replace("""from consolidation import ENGINES""",
"""from consolidation import ENGINES, _duckdb_query""")
s=s.replace('''def effective_lines(function) -> int:
    """Líneas de código efectivas: sin blancos, sin comentarios y sin docstring.

    La sección 6 publica esta columna junto al tiempo porque **el tamaño del código es un
    costo real** —alguien lo mantiene— y porque sin ella la comparación premiaría al motor
    más rápido aunque costara tres veces más código. Contar líneas crudas habría premiado
    al que menos comenta, que es justo el incentivo contrario al de este curso.
    """
    source = inspect.getsource(function)''',
'''def effective_lines(engine: str) -> int:
    """Líneas de código efectivas del motor: sin blancos, sin comentarios y sin docstring.

    La sección 6 publica esta columna junto al tiempo porque **el tamaño del código es un
    costo real** —alguien lo mantiene— y porque sin ella la comparación premiaría al motor
    más rápido aunque costara tres veces más código. Contar líneas crudas habría premiado
    al que menos comenta, que es justo el incentivo contrario al de este curso.

    Las dos variantes de DuckDB suman la auxiliar donde vive el SQL. La primera versión de
    esta función no lo hacía y les daba **una y dos líneas**: un número halagador y falso,
    porque la consulta que alguien tiene que mantener son veintitantas líneas de SQL que
    estaban ahí igual. Contar solo lo que se ve es la forma más fácil de mentir en esta
    columna.
    """
    return sum(_lines_of(function) for function in FUNCTIONS_OF[engine])


def _lines_of(function) -> int:
    source = inspect.getsource(function)''')
s=s.replace('''            "lineas": effective_lines(function),''','''            "lineas": effective_lines(engine),''')
s=s.replace('''            "lineas": effective_lines(ENGINES[engine])}''','''            "lineas": effective_lines(engine)}''')
s=s.replace('''def peak_rss_mb() -> float:''','''# Qué funciones cuenta la columna de líneas de cada motor. Las dos variantes de DuckDB
# delegan su SQL en la misma auxiliar, y esa auxiliar es código que alguien mantiene.
FUNCTIONS_OF = {
    engine: ((function, _duckdb_query) if "duckdb" in engine else (function,))
    for engine, function in ENGINES.items()
}


def peak_rss_mb() -> float:''')
open(p,'w',encoding='utf-8').write(s); print("OK")
PY
uv run --python 3.14 --with 'duckdb==1.5.5' python - <<'PY'
import bench_engines as b
for e in b.ENGINES: print(f"{e:18s} {b.effective_lines(e):>3} líneas")
PY

# --- 2026-09-13T21:50:46 · Re-run benchmark with fair LOC and time Parquet conversion
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs/src/ds03-polars-y-el-modelo-lazy
python3 - <<'PY'
p='bench_engines.py'; s=open(p,encoding='utf-8').read()
old='        "lineas": effective_lines(function),'
assert s.count(old)==1
open(p,'w',encoding='utf-8').write(s.replace(old,'        "lineas": effective_lines(engine),')); print("OK")
PY
time uv run --python 3.14 --with 'pandas==3.0.5' --with 'polars==1.44.2' --with 'duckdb==1.5.5' --with 'pyarrow==25.0.1' python bench_engines.py --datos data 2>&1 | tail -20
echo "=== costo de convertir a Parquet (una vez) ==="
uv run --python 3.14 --with 'duckdb==1.5.5' python - <<'PY'
import time, shutil
from pathlib import Path
from consolidation import write_parquet
for size in ("mes","e1","e4","e16"):
    d=Path("data")/size; t=d/"tmp_parquet"
    shutil.rmtree(t, ignore_errors=True)
    s=time.perf_counter(); write_parquet(d, t); ms=(time.perf_counter()-s)*1000
    shutil.rmtree(t)
    print(f"{size:>4}: {ms:>8.0f} ms")
PY

# --- 2026-09-13T21:51:41 · Measure interpreter startup plus import cost per engine
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs/src/ds03-polars-y-el-modelo-lazy
for m in "" pandas polars duckdb; do
  printf "%-8s " "${m:-nada}"
  uv run --python 3.14 --with 'pandas==3.0.5' --with 'polars==1.44.2' --with 'duckdb==1.5.5' python - <<PY
import subprocess, sys, time, statistics
code = "import ${m}" if "${m}" else "pass"
t=[]
for _ in range(7):
    s=time.perf_counter(); subprocess.run([sys.executable,"-c",code],check=True); t.append((time.perf_counter()-s)*1000)
t.sort(); print(f"{statistics.median(t):7.1f} ms de arranque (proceso + import)")
PY
done

# --- 2026-09-13T21:52:33 · Add intermediate sizes for the threshold search
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs/src/ds03-polars-y-el-modelo-lazy
python3 - <<'PY'
p='preparar_tamanos.py'; s=open(p,encoding='utf-8').read()
s=s.replace('''def slice_month(source: Path, target: Path, month: str) -> None:
    """Recorta cada CSV al mes pedido, conservando el encabezado.''',
'''def slice_months(source: Path, target: Path, months: tuple[str, ...]) -> None:
    """Recorta cada CSV a los meses pedidos, conservando el encabezado.''')
s=s.replace('            kept = [row for row in reader if row[column].startswith(month)]',
            '            kept = [row for row in reader if row[column][:7] in months]')
s=s.replace('''| `mes/`  | marzo de 2026, recortado del conjunto real | real |
| `e1/`   | la historia completa: 2024-01 a 2026-03 | real |''',
'''| `mes/`  | marzo de 2026, recortado del conjunto real | real |
| `trimestre/` | el primer trimestre de 2026 | real |
| `ano/`  | los doce meses hasta el corte | real |
| `e1/`   | la historia completa: 2024-01 a 2026-03 | real |''')
s=s.replace('''    generate(1, args.salida / "e1")
    slice_month(args.salida / "e1", args.salida / "mes", args.mes)
    for scale in (4, 16):
        generate(scale, args.salida / f"e{scale}")

    for name in ("mes", "e1", "e4", "e16"):''',
'''    generate(1, args.salida / "e1")
    slice_months(args.salida / "e1", args.salida / "mes", ("2026-03",))
    slice_months(args.salida / "e1", args.salida / "trimestre",
                 ("2026-01", "2026-02", "2026-03"))
    # Los doce meses hasta el corte: es el consolidado anual que Marcela lleva al comité de
    # franquicia, y el tamaño donde el umbral de la sección 6 se decide.
    year = tuple(f"2025-{month:02d}" for month in range(4, 13)) + \\
        ("2026-01", "2026-02", "2026-03")
    slice_months(args.salida / "e1", args.salida / "ano", year)
    for scale in (4, 16):
        generate(scale, args.salida / f"e{scale}")

    for name in ("mes", "trimestre", "ano", "e1", "e4", "e16"):''')
s=s.replace('    parser.add_argument("--mes", default="2026-03")\n','')
open(p,'w',encoding='utf-8').write(s); print("OK")

p='bench_engines.py'; s=open(p,encoding='utf-8').read()
s=s.replace('SIZES = ("mes", "e1", "e4", "e16")','SIZES = ("mes", "e1", "e4", "e16")\nALL_SIZES = ("mes", "trimestre", "ano", "e1", "e4", "e16")')
s=s.replace('parser.add_argument("--tamano", choices=[*SIZES, "linea-base"])','parser.add_argument("--tamano", choices=[*ALL_SIZES, "linea-base"])')
open(p,'w',encoding='utf-8').write(s); print("OK bench")
PY
rm -rf data && uv run --python 3.14 --with 'duckdb==1.5.5' python preparar_tamanos.py --salida data 2>&1 | tail -8

# --- 2026-09-13T21:53:24 · Run end-to-end and main benchmarks
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs/src/ds03-polars-y-el-modelo-lazy
uv run --python 3.14 --with 'pandas==3.0.5' --with 'polars==1.44.2' --with 'duckdb==1.5.5' --with 'pyarrow==25.0.1' python bench_punta_a_punta.py --datos data 2>&1 | tail -8
echo "=== y la tabla principal, con los seis tamaños en su sitio ==="
uv run --python 3.14 --with 'pandas==3.0.5' --with 'polars==1.44.2' --with 'duckdb==1.5.5' --with 'pyarrow==25.0.1' python bench_engines.py --datos data 2>&1 | tail -18

# --- 2026-09-13T21:54:37 · Decompose cold-start cost per engine
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs/src/ds03-polars-y-el-modelo-lazy
uv run --python 3.14 --with 'duckdb==1.5.5' --with 'polars==1.44.2' --with 'pandas==3.0.5' python - <<'PY'
import subprocess, sys, time, statistics
def cold(code, n=5):
    t=[]
    for _ in range(n):
        s=time.perf_counter(); subprocess.run([sys.executable,"-c",code],check=True,capture_output=True); t.append((time.perf_counter()-s)*1000)
    t.sort(); return statistics.median(t)
cases = {
 "intérprete solo": "pass",
 "import duckdb": "import duckdb",
 "import duckdb + connect": "import duckdb; duckdb.connect()",
 "import duckdb + connect + query trivial": "import duckdb; duckdb.connect().execute('select 42').fetchall()",
 "import polars": "import polars",
 "import polars + lazy trivial": "import polars as pl; pl.LazyFrame({'a':[1]}).collect()",
 "import pandas": "import pandas",
 "import pandas + frame trivial": "import pandas as pd; pd.DataFrame({'a':[1]}).groupby('a').size()",
}
for k,v in cases.items(): print(f"{k:<42} {cold(v):7.1f} ms")
PY

# --- 2026-09-13T21:54:56 · Instrument the cold DuckDB run
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs/src/ds03-polars-y-el-modelo-lazy
uv run --python 3.14 --with 'duckdb==1.5.5' python - <<'PY'
import subprocess, sys
code = '''
import time
t0=time.perf_counter()
from pathlib import Path
from consolidation import consolidate_duckdb_parquet
t1=time.perf_counter()
import duckdb
t2=time.perf_counter()
rows = consolidate_duckdb_parquet(Path("data/mes/parquet"))
t3=time.perf_counter()
print(f"import consolidation {1000*(t1-t0):6.1f} · import duckdb {1000*(t2-t1):6.1f} · consulta {1000*(t3-t2):6.1f}")
'''
subprocess.run([sys.executable,"-c",code],check=True)
PY

# --- 2026-09-13T21:55:10 · Compare cold start in the four-package environment
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs/src/ds03-polars-y-el-modelo-lazy
uv run --python 3.14 --with 'pandas==3.0.5' --with 'polars==1.44.2' --with 'duckdb==1.5.5' --with 'pyarrow==25.0.1' python - <<'PY'
import subprocess, sys, time, statistics
print("ejecutable:", sys.executable)
for label, code in [("solo pass","pass"),("import duckdb","import duckdb"),("import pandas","import pandas")]:
    t=[]
    for _ in range(5):
        s=time.perf_counter(); subprocess.run([sys.executable,"-c",code],check=True,capture_output=True); t.append((time.perf_counter()-s)*1000)
    t.sort(); print(f"{label:<16}{statistics.median(t):7.1f} ms")
PY

# --- 2026-09-13T21:55:25 · Re-run end-to-end warm
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs/src/ds03-polars-y-el-modelo-lazy
uv run --python 3.14 --with 'pandas==3.0.5' --with 'polars==1.44.2' --with 'duckdb==1.5.5' --with 'pyarrow==25.0.1' python bench_punta_a_punta.py --datos data --repeticiones 7 2>&1 | tail -6

# --- 2026-09-13T21:56:09 · Test whether DuckDB teardown dominates the wall clock
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs/src/ds03-polars-y-el-modelo-lazy
uv run --python 3.14 --with 'duckdb==1.5.5' --with 'pyarrow==25.0.1' python - <<'PY'
import subprocess, sys, time, statistics
code_full = '''
import time
t0=time.perf_counter()
from pathlib import Path
from consolidation import consolidate_duckdb_parquet
rows = consolidate_duckdb_parquet(Path("data/mes/parquet"))
print(f"INTERNO {1000*(time.perf_counter()-t0):.1f}")
'''
code_exit = code_full + "\nimport os; os._exit(0)\n"
for label, code in [("normal", code_full), ("os._exit(0)", code_exit)]:
    t=[]; out=None
    for _ in range(5):
        s=time.perf_counter(); r=subprocess.run([sys.executable,"-c",code],check=True,capture_output=True,text=True); t.append((time.perf_counter()-s)*1000); out=r.stdout.strip()
    t.sort(); print(f"{label:<12} pared {statistics.median(t):7.1f} ms · {out}")
PY

# --- 2026-09-13T21:56:26 · Confirm DuckDB imports pandas when present
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs/src/ds03-polars-y-el-modelo-lazy
echo "--- entorno con solo duckdb ---"
uv run --python 3.14 --with 'duckdb==1.5.5' python -c "
import sys, duckdb; print('pandas cargado:', 'pandas' in sys.modules, '· polars:', 'polars' in sys.modules)"
echo "--- entorno con duckdb + pandas + polars ---"
uv run --python 3.14 --with 'duckdb==1.5.5' --with 'pandas==3.0.5' --with 'polars==1.44.2' python -c "
import sys, duckdb; print('pandas cargado:', 'pandas' in sys.modules, '· polars:', 'polars' in sys.modules)"

# --- 2026-09-13T21:56:40 · Isolate which dependency inflates DuckDB's cold start
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs/src/ds03-polars-y-el-modelo-lazy
cat > /tmp/probe.py <<'PY'
import subprocess, sys, time, statistics
code = 'from pathlib import Path\nfrom consolidation import consolidate_duckdb_parquet\nrows = consolidate_duckdb_parquet(Path("data/mes/parquet"))\nassert rows\n'
t=[]
for _ in range(5):
    s=time.perf_counter(); subprocess.run([sys.executable,"-c",code],check=True,capture_output=True); t.append((time.perf_counter()-s)*1000)
t.sort(); print(f"  pared mediana {statistics.median(t):7.1f} ms")
PY
echo "entorno duckdb+pyarrow:"; uv run --python 3.14 --with 'duckdb==1.5.5' --with 'pyarrow==25.0.1' python /tmp/probe.py
echo "entorno +pandas:"; uv run --python 3.14 --with 'duckdb==1.5.5' --with 'pyarrow==25.0.1' --with 'pandas==3.0.5' python /tmp/probe.py
echo "entorno +pandas+polars:"; uv run --python 3.14 --with 'duckdb==1.5.5' --with 'pyarrow==25.0.1' --with 'pandas==3.0.5' --with 'polars==1.44.2' python /tmp/probe.py

# --- 2026-09-13T21:57:14 · Pinpoint when DuckDB loads pandas
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs/src/ds03-polars-y-el-modelo-lazy
uv run --python 3.14 --with 'duckdb==1.5.5' --with 'pyarrow==25.0.1' --with 'pandas==3.0.5' python -c "
import sys, duckdb
print('tras import  ->  pandas:', 'pandas' in sys.modules)
c = duckdb.connect()
print('tras connect ->  pandas:', 'pandas' in sys.modules)
c.execute('select 42').fetchall()
print('tras execute ->  pandas:', 'pandas' in sys.modules)
from pathlib import Path
from consolidation import consolidate_duckdb_parquet
consolidate_duckdb_parquet(Path('data/mes/parquet'))
print('tras consulta->  pandas:', 'pandas' in sys.modules, '· pyarrow:', 'pyarrow' in sys.modules)"

# --- 2026-09-13T21:57:38 · Measure each engine in its own isolated environment
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs/src/ds03-polars-y-el-modelo-lazy
python3 - <<'PY'
p='bench_punta_a_punta.py'; s=open(p,encoding='utf-8').read()
s=s.replace('''    parser.add_argument("--tamanos", nargs="+",
                        default=["mes", "trimestre", "ano", "e1"])
    args = parser.parse_args()

    print(f"{'motor':<18}" + "".join(f"{size:>12}" for size in args.tamanos))
    for engine, (function, parquet) in END_TO_END.items():''',
'''    parser.add_argument("--tamanos", nargs="+",
                        default=["mes", "trimestre", "ano", "e1"])
    parser.add_argument("--motor", choices=sorted(END_TO_END),
                        help="Mide solo este. Es como se toma la tabla honesta: cada motor "
                             "en un entorno donde SOLO está instalada su dependencia.")
    args = parser.parse_args()

    engines = {args.motor: END_TO_END[args.motor]} if args.motor else END_TO_END
    print(f"{'motor':<18}" + "".join(f"{size:>12}" for size in args.tamanos))
    for engine, (function, parquet) in engines.items():''')
s=s.replace('''Las dos mediciones son correctas y responden a preguntas distintas. Publicar solo la
primera sería el error que la Fase 17 del camino base cometió y documentó.
"""''',
'''Las dos mediciones son correctas y responden a preguntas distintas. Publicar solo la
primera sería el error que la Fase 17 del camino base cometió y documentó.

⚠️ **Cada motor se mide en un entorno donde solo está instalada su dependencia**, con
`--motor`. No es purismo: DuckDB carga pandas **durante la consulta** si pandas está
instalado —su mecanismo de sustitución de nombres lo busca— y eso le agrega 350 ms de
arranque que no son suyos. Medir los cuatro en el mismo entorno le carga a DuckDB el
precio de una dependencia que no usa. El efecto está medido y se publica.
"""''')
open(p,'w',encoding='utf-8').write(s); print("OK")
PY
echo "=== bucle (sin dependencias) ==="; uv run --python 3.14 python bench_punta_a_punta.py --datos data --motor bucle --repeticiones 7 2>&1|tail -2
echo "=== pandas solo ==="; uv run --python 3.14 --with 'pandas==3.0.5' python bench_punta_a_punta.py --datos data --motor pandas --repeticiones 7 2>&1|tail -2
echo "=== polars solo ==="; uv run --python 3.14 --with 'polars==1.44.2' python bench_punta_a_punta.py --datos data --motor 'polars (lazy)' --repeticiones 7 2>&1|tail -2
echo "=== duckdb solo ==="; uv run --python 3.14 --with 'duckdb==1.5.5' python bench_punta_a_punta.py --datos data --motor 'duckdb (parquet)' --repeticiones 7 2>&1|tail -2

# --- 2026-09-13T21:58:47 · Run the ds03 test suite
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs/src/ds03-polars-y-el-modelo-lazy
uv run --python 3.14 --with 'pandas==3.0.5' --with 'polars==1.44.2' --with 'duckdb==1.5.5' --with pytest python -m pytest -q 2>&1 | tail -20

# --- 2026-09-13T22:03:49 · Fix garbled sentence and lint ds03
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs
python3 - <<'PY'
p='ds03-polars-y-el-modelo-lazy.md'; s=open(p,encoding='utf-8').read()
old="""> de un servicio que responde muchas veces, DuckDB sobre Parquet hace en 25 ms lo que al
> bucle le toma 3.148: **125×** a 4,2 millones de filas, con 45 MB contra 3.148 ms de
> espera."""
new="""> de un servicio que responde muchas veces, DuckDB sobre Parquet hace en 25,1 ms lo que al
> bucle le toma 3.148: **125×** a 4,2 millones de filas. Le cuesta cuatro veces y media más
> memoria —205 MB contra 45— y a cambio contesta ciento veinticinco veces antes."""
assert s.count(old)==1
open(p,'w',encoding='utf-8').write(s.replace(old,new)); print("OK")
PY
cd src/ds03-polars-y-el-modelo-lazy && uvx ruff@0.16.7 check . 2>&1 | grep -E "^[A-Z][0-9]+" | head

# --- 2026-09-13T22:03:57 · Locate the unused import
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs/src/ds03-polars-y-el-modelo-lazy
uvx ruff@0.16.7 check . 2>&1 | grep -A4 "F401" | head -12

# --- 2026-09-13T22:04:01 · Inspect the duckdb function body
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs/src/ds03-polars-y-el-modelo-lazy
sed -n 148,165p consolidation.py

# --- 2026-09-13T22:04:07 · Clean up and re-verify ds03
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs/src/ds03-polars-y-el-modelo-lazy
python3 - <<'PY'
p='consolidation.py'; s=open(p,encoding='utf-8').read()
old='''    número importa más que su elegancia.
    """
    import duckdb

    return _duckdb_query(data, "read_csv", ".csv")'''
new='''    número importa más que su elegancia.
    """
    return _duckdb_query(data, "read_csv", ".csv")'''
assert s.count(old)==1
open(p,'w',encoding='utf-8').write(s.replace(old,new)); print("OK")
PY
uvx ruff@0.16.7 check --fix . >/dev/null 2>&1; uvx ruff@0.16.7 check . && echo "LINT OK"
uv run --python 3.14 --with 'pandas==3.0.5' --with 'polars==1.44.2' --with 'duckdb==1.5.5' --with pytest python -m pytest -q 2>&1|tail -2

# --- 2026-09-13T22:05:05 · Add ds03 to BENCHMARKS and INSTINTOS
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs
python3 - <<'PY'
def sub(path, pairs):
    s=open(path,encoding='utf-8').read()
    for old,new in pairs:
        if s.count(old)!=1: raise SystemExit(f"{path}: {s.count(old)} de {old[:60]!r}")
        s=s.replace(old,new)
    open(path,'w',encoding='utf-8').write(s); print("OK", path)

sub('BENCHMARKS.md', [("""---

## ✍️ Cómo se agregan entradas""", """### ds03 · Cuatro motores, dos preguntas y dos ganadores

**Afirmaba:** que el motor perezoso le gana al ansioso y los dos al bucle, **y que todo eso deja
de ser cierto al tamaño y la frecuencia reales de Áurea**, donde el arranque de la dependencia
pesa más que la consulta.

**Condiciones:** pandas 3.0.5, Polars 1.44.2, DuckDB 1.5.5. El consolidado mensual de las diez
sedes —cinco cifras, cuatro fuentes, un `join` inevitable— sobre seis tamaños, **cuatro de ellos
recortes reales** del conjunto del Embudo: un mes (11.116 filas), un trimestre (30.392), un año
(115.332) y la historia completa (298.581); los dos mayores, a escala 4 y 16, son sintéticos
declarados. Cinco repeticiones por celda. Un proceso por celda, pico de RSS del sistema
operativo. **Los cinco motores devuelven exactamente la misma tabla**, verificado por prueba.

**La consulta, con el motor ya cargado:**

| Motor | Líneas | Importar | 11k | 299k | 1,1M | 4,2M |
|---|---|---|---|---|---|---|
| bucle (stdlib) | 28 | 23 MB | 6,3 ms | 276,2 ms | 847,8 ms | 3.148,3 ms |
| pandas | 25 | 105 MB | 12,2 ms | 85,4 ms | 259,4 ms | 916,2 ms |
| polars (lazy) | 27 | 57 MB | **3,6 ms** | 11,1 ms | 28,8 ms | 122,6 ms |
| duckdb (csv) | 33 | 45 MB | 146,6 ms | 196,2 ms | 258,0 ms | 346,8 ms |
| duckdb (parquet) | 32 | 45 MB | 8,4 ms | **12,3 ms** | **16,0 ms** | **25,1 ms** |

**El informe completo, de punta a punta**, cada motor en un entorno con solo su dependencia:

| Motor | 11k | 30k | 115k | 299k |
|---|---|---|---|---|
| bucle (stdlib) | **34 ms** | **49 ms** | 120 ms | 297 ms |
| duckdb (parquet) | 97 ms | 98 ms | **98 ms** | **103 ms** |
| polars (lazy) | 150 ms | 151 ms | 154 ms | 154 ms |
| pandas | 326 ms | 346 ms | 373 ms | 453 ms |

⚖️ **Tres veredictos.** (1) **Para el informe mensual de Áurea gana la biblioteca estándar**: 34
ms contra 97 de DuckDB y 326 de pandas, sin instalar nada. El umbral está **entre 30.000 y
115.000 filas** —entre un trimestre y un año de la red—, y Áurea genera unas 11.000 filas al mes.
(2) **Con el proceso caliente el orden se invierte y no está cerca**: DuckDB sobre Parquet hace
en 25,1 ms lo que al bucle le toma 3.148, **125×** a 4,2 millones de filas. (3) **El formato pesa
más que el motor**: el mismo SQL tarda 346,8 ms sobre CSV y 25,1 sobre Parquet —**14×**— y el
Parquet ocupa entre 24 y 42 veces menos disco, con un costo de conversión de 222 a 431 ms que se
paga una sola vez.

**Y un empate que vale la pena:** en líneas de código efectivas los cinco motores están entre
**25 y 33**. "En SQL son cuatro líneas" no sobrevive a contar el SQL.

**Arranque en frío, que es de dónde sale todo lo anterior:** intérprete solo **26,3 ms**; con
DuckDB **84,7**; con Polars **129,2**; con pandas **342,7**.

→ [`ds03-polars-y-el-modelo-lazy.md`](ds03-polars-y-el-modelo-lazy.md) §6

---

## ✍️ Cómo se agregan entradas""")])

sub('INSTINTOS.md', [("""---

## 🧪 Los reflejos de método""", """### 29. "Lazy ya sé lo que es: es el lazy loading que me quemó"

Once años de ORM dejan "perezoso" asociado a una cosa muy concreta y muy mala: ir a buscar cada
dato cuando alguien lo toca, y descubrir el N+1 en producción. En Polars y DuckDB significa **lo
contrario**: acumular la consulta entera para ir al disco **una sola vez y mejor**, podando las
columnas que nadie usa y bajando los filtros hasta la lectura.

El `Stream` de Java tampoco es el paralelo correcto, aunque se le parezca más: un `Stream`
difiere la ejecución pero **respeta el orden que escribiste**. Aquí el optimizador lo reescribe,
exactamente como el planificador de tu base de datos. El modelo mental que sirve no es "streams
perezosos": es **una base de datos sin base de datos**. *(`ds03`)*

---

## 🧪 Los reflejos de método""")])
PY

# --- 2026-09-13T22:05:10 · Check the method reflexes section
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs
sed -n '/## 🧪 Los reflejos de método/,/^### Si los dos/p' INSTINTOS.md | head -20

# --- 2026-09-13T22:05:35 · Add method reflex and update track state
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs
python3 - <<'PY'
p='INSTINTOS.md'; s=open(p,encoding='utf-8').read()
old="""Estos no son de Java: son de cualquiera que mida. Aparecieron **escribiendo el curso**, y por eso
están aquí — los tres son errores que cometió quien lo escribió."""
new="""Estos no son de Java: son de cualquiera que mida. Aparecieron **escribiendo el curso**, y por eso
están aquí — todos son errores que cometió quien lo escribió."""
assert s.count(old)==1
s=s.replace(old,new)

anchor="### Si los dos números se parecen demasiado, mide al medidor"
new2="""### Tu benchmark depende de lo que tengas instalado al lado

El consolidado de `ds03` con DuckDB sobre Parquet tarda **97 ms** de punta a punta en un entorno
donde solo está DuckDB, y **433 ms** en uno donde además está pandas instalado. Mismo código,
mismos datos, 4,5×: DuckDB importa pandas **durante la consulta**, porque su mecanismo de
sustitución de nombres va a mirar si algún nombre referenciado es un objeto de pandas o de Arrow.

Nadie lo escribe en el `requirements.txt` y nadie lo ve en el perfil. La regla que deja: **cuando
midas una dependencia, mídela en un entorno donde esté sola**, y si no puedes, declara qué más
había instalado. Una tabla de motores tomada en un entorno con los cuatro le cobra a cada uno el
arranque de los otros tres.

→ `ds03`

### Si los dos números se parecen demasiado, mide al medidor"""
assert s.count(anchor)==1
open(p,'w',encoding='utf-8').write(s.replace(anchor,new2,1)); print("OK")
PY
echo "=== estado de prompts ==="
python3 - <<'PY'
def sub(path, pairs):
    s=open(path,encoding='utf-8').read()
    for old,new in pairs:
        if s.count(old)!=1: raise SystemExit(f"{path}: {s.count(old)} de {old[:60]!r}")
        s=s.replace(old,new)
    open(path,'w',encoding='utf-8').write(s); print("OK", path)

sub('prompts/README.md', [
("| **T8** | `ds03` | Sola: cuatro motores por cuatro tamaños es la medición más cara del track, y puede obligar a matizar `ds02` |",
 "| **T8** ✅ | `ds03`, cerrada el 13/09/2026: **dos** tablas medidas —la consulta y el informe de punta a punta— con ganadores distintos, y 11 pruebas | Sola: cuatro motores por cuatro tamaños es la medición más cara del track, y puede obligar a matizar `ds02` |"),
("""> 134 pruebas. 🚧 **Track `ds` en curso, repartido en ocho tandas (T6–T13)**. Cerradas: **T6**,
> los dos conjuntos de datos con sus 47 pruebas, y **T7**, `ds01` y `ds02` con sus dos mediciones
> ya ejecutadas. La siguiente es **T8** (`ds03`).""",
 """> 134 pruebas. 🚧 **Track `ds` en curso, repartido en ocho tandas (T6–T13)**. Cerradas: **T6**,
> los dos conjuntos de datos; **T7**, `ds01` y `ds02`; y **T8**, `ds03`. Las cuatro mediciones del
> track están **ejecutadas**, no en `⏳`. La siguiente es **T9** (`ds04`, el proyecto Embudo)."""),
])

sub('prompts/prompts-de-tracks-ia-ds.md', [
("| `ds03-polars-y-el-modelo-lazy.md` | Polars y el modelo lazy | Embudo | pandas ⇄ Polars ⇄ DuckDB ⇄ bucle, cuatro tamaños |",
 "| `ds03-polars-y-el-modelo-lazy.md` ✅ | Polars y el modelo lazy | Embudo | pandas ⇄ Polars ⇄ DuckDB ⇄ bucle, cuatro tamaños — **ejecutada, y son dos tablas** |"),
("""> 🚧 **El track `ds` va por `ds02`.** T6 dejó los dos conjuntos de datos, T7 escribió `ds01` y
> `ds02` con **sus dos mediciones ejecutadas** —no cuestan dinero ni API, así que aquí no hay `⏳`—
> y sus entradas ya están en `BENCHMARKS.md`. Siguiente: T8, `ds03`.""",
 """> 🚧 **El track `ds` va por `ds03`.** T6 dejó los dos conjuntos de datos; T7 escribió `ds01` y
> `ds02`; T8, `ds03`. **Las cuatro mediciones están ejecutadas** —no cuestan dinero ni API, así
> que aquí no hay `⏳`— y sus entradas están en `BENCHMARKS.md`. La de `ds03` son **dos tablas con
> ganadores distintos**: la consulta con el motor caliente y el informe de punta a punta.
> Siguiente: T9, `ds04`."""),
])
PY

# --- 2026-09-13T22:05:46 · Final verification of the whole ds track
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs
rm -rf src/ds0*/data src/ds0*/__pycache__ src/ds0*/.pytest_cache .pytest_cache 2>/dev/null
echo "=== links rotos ==="
python3 - <<'PY'
import re,os
bad=[]
for root,d,fs in os.walk('.'):
    if 'pytest_cache' in root: continue
    for f in fs:
        if not f.endswith('.md'): continue
        p=os.path.join(root,f)
        for i,l in enumerate(open(p,encoding='utf-8'),1):
            for m in re.finditer(r'\]\((?!https?:)([^)#]+\.md)(?:#[^)]*)?\)',l):
                t=m.group(1)
                if not os.path.exists(os.path.normpath(os.path.join(root,t))): bad.append(f"{p}:{i} -> {t}")
print("\n".join(bad) or "sin links rotos")
PY
echo "=== suites ==="
for d in src/ds01-numpy-y-el-modelo-vectorizado src/ds02-pandas src/ds03-polars-y-el-modelo-lazy src/ds07-scikit-learn; do
  printf "%-44s " "$d"; (cd $d && uv run --python 3.14 --with pytest --with 'numpy==2.5.3' --with 'pandas==3.0.5' --with 'polars==1.44.2' --with 'duckdb==1.5.5' python -m pytest -q 2>&1|tail -1); done
echo "=== wc ==="; wc -l ds0*.md | tail -4

# --- 2026-09-13T22:06:44 · Record T8 in project memory
cd /Users/oskar/.claude/projects/-Users-oskar-Developer-Learning-courses-ia-generated/memory
python3 - <<'PY'
p='python-java-devs-estado.md'; s=open(p,encoding='utf-8').read()
old="**Lo siguiente es T8 (`ds03`).**"
new="""**T8 cerrada el 13/09/2026**: `ds03-polars-y-el-modelo-lazy.md` (718 líneas), el consolidado
mensual escrito en **cinco motores** que devuelven la misma tabla, y **dos** mediciones con
ganadores distintos. Con el motor caliente gana DuckDB sobre Parquet (125× al bucle a 4,2M
filas); **de punta a punta —proceso, import, consulta y salida— gana el bucle de la biblioteca
estándar** a la escala real de Áurea (34 ms contra 97 de DuckDB y 326 de pandas), y el umbral
está entre 30.000 y 115.000 filas. Tercer hallazgo: el formato pesa más que el motor (mismo SQL,
14× entre CSV y Parquet; 24–42× menos disco). Empate declarado: los cinco motores caben en 25–33
líneas efectivas.

**Dos correcciones que salieron al escribir T8 y que tocaron T6 y T7.** (1) El generador del
Embudo dejaba **eventos posteriores al cierre declarado del conjunto** —etapas en agosto de 2026
con el export tomado el 2026-03-31—; se corrigió truncando todo en `END` (censura por la derecha,
que además es contenido de `ds04`) y eso cambió el conjunto entero: hubo que **re-ejecutar las
mediciones de `ds01` y `ds02`** y actualizar cifras en los dos capítulos, `BENCHMARKS.md`,
`INSTINTOS.md` y los README. (2) El `📌` abierto sobre si la pauta de Áurea era demasiado alta se
verificó y cuadra: 6.059 millones de pauta contra 83.378 de valor contratado, un 7,3%.

**El hallazgo de método de T8**, ya en `INSTINTOS.md`: **una medición depende de qué otras
dependencias haya instaladas**. DuckDB importa pandas *durante la consulta* si pandas está en el
entorno, y eso le suma 350 ms de arranque que no son suyos (97 ms → 433). Por eso la tabla de
punta a punta se toma con un entorno por motor (`--motor`).

**Lo siguiente es T9 (`ds04`, el proyecto Embudo).**"""
assert s.count(old)==1
open(p,'w',encoding='utf-8').write(s.replace(old,new)); print("OK")
PY

# --- 2026-09-13T22:21:29 · Check whether root docs know about the tracks
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs
echo "=== ¿el README y la ESTRUCTURA conocen los tracks? ==="; grep -c "ia01\|track \`ia\`\|complementos" README.md 0-ESTRUCTURA-CURSO.md
echo "=== números más citados ==="; sed -n '/## 🧮 Los números que más se citan/,/^---/p' BENCHMARKS.md | head -25

# --- 2026-09-13T22:21:42 · See how ESTRUCTURA mentions the tracks
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs
grep -n "ia01\|track \`ia\`\|complementos\|a la carta" 0-ESTRUCTURA-CURSO.md | head; echo "---"; sed -n '/complementos/,+12p' 0-ESTRUCTURA-CURSO.md | head -20

# --- 2026-09-13T22:21:48 · Read the root README to place the tracks section
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs
sed -n 55,80p README.md; echo "..."; sed -n 100,120p README.md

# --- 2026-09-13T22:22:10 · Fix stale claims and surface the tracks in the root docs
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs
python3 - <<'PY'
def sub(path, pairs):
    s=open(path,encoding='utf-8').read()
    for old,new in pairs:
        if s.count(old)!=1: raise SystemExit(f"{path}: {s.count(old)} de {old[:60]!r}")
        s=s.replace(old,new)
    open(path,'w',encoding='utf-8').write(s); print("OK", path)

sub('README.md', [
("""La tabla completa de las 18 fases, los cuatro proyectos y cómo se recorre están en
[`0-ESTRUCTURA-CURSO.md`](0-ESTRUCTURA-CURSO.md).

---""",
 """La tabla completa de las 18 fases, los cuatro proyectos y cómo se recorre están en
[`0-ESTRUCTURA-CURSO.md`](0-ESTRUCTURA-CURSO.md).

### Y después, dos tracks complementarios

Cuando el camino base termina, Áurea todavía tiene cuatro proyectos planteados y ninguno
construido. Los **complementos** los construyen, con la misma plantilla, la misma medición
obligatoria y el mismo miniproyecto que una fase:

- **Track `ia`** (`ia01`–`ia08`) — NormaRAG, que contesta qué cubre cada prepagada citando
  documento y cláusula o no contesta; y Recepción asistida, que atiende los novecientos mensajes
  diarios de WhatsApp y **escala ante cualquier síntoma**.
- **Track `ds`** (`ds01`–`ds09`) — Embudo, que mide cuánto cuesta de verdad un paciente
  adquirido; y Ausentismo, que predice el 19% de inasistencia y abre la discusión de qué se hace
  con esa predicción.

No son material a la carta: son la continuación del curso sobre el código que tú dejaste escrito.
Se toman después de la Fase 17 porque necesitan el CLI, la API y la base de datos funcionando.

---"""),
("""Y si quieres ver de qué se trata antes de empezar, dos atajos:
**[`BENCHMARKS.md`](BENCHMARKS.md)** tiene las dieciocho mediciones del curso con sus veredictos
—incluidos los cinco empates— y **[`INSTINTOS.md`](INSTINTOS.md)** tiene los dieciocho reflejos de
Java que el material recalibra, con lo que cuesta cada uno.""",
 """Y si quieres ver de qué se trata antes de empezar, dos atajos:
**[`BENCHMARKS.md`](BENCHMARKS.md)** tiene las mediciones del curso con sus veredictos —las
dieciocho del camino base, incluidos los cinco empates, más las de los complementos— y
**[`INSTINTOS.md`](INSTINTOS.md)** tiene los reflejos de Java que el material recalibra, con lo
que cuesta cada uno."""),
])

# ds02: ya no es la única medición sobre datos reales
sub('ds02-pandas.md', [
("""- **La medición de esta sección es la única del track que corre sobre los datos reales de Áurea
  sin repetir bloque.** Conviene que siga así: si `ds03` necesita tamaños mayores, que los
  declare como sintéticos igual que `ds01`.""",
 """- 🪦 **`ds03` mantuvo la costumbre:** sus cuatro tamaños chicos son recortes reales del conjunto
  —un mes, un trimestre, un año y la historia completa— y solo los dos grandes son sintéticos, y
  lo declaran. La medición de esta sección sigue siendo la única que no necesita ningún tamaño
  inventado para tener algo que medir."""),
])

sub('prompts/README.md', [
("cerradas el 13/09/2026: 1.439 líneas de prosa", "cerradas el 13/09/2026: 1.441 líneas de prosa"),
])

# BENCHMARKS: los números más citados, ahora que los tracks también miden
sub('BENCHMARKS.md', [
("""Si solo te llevas diez de este documento, que sean estos:""",
 """Si solo te llevas doce de este documento, que sean estos — los diez del camino base y los dos
que trajeron los complementos:"""),
("""| **87%** | Cuánto del cierre nocturno es esperar a la base de datos | 16 |""",
 """| **87%** | Cuánto del cierre nocturno es esperar a la base de datos | 16 |
| **34 ms contra 97** | El bucle a mano ganándole a DuckDB en el informe mensual de Áurea | `ds03` |
| **20 de 40** | Síntomas que el guardrail léxico deja pasar, y que deciden si Recepción asistida se despliega | `ia07` |"""),
])
PY

# --- 2026-09-13T22:22:16 · Locate the stale ds02 pendiente
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs
grep -n "única del track" ds02-pandas.md; sed -n '/única del track/,+3p' ds02-pandas.md

# --- 2026-09-13T22:22:27 · Apply the remaining corrections
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs
python3 - <<'PY'
def sub(path, pairs):
    s=open(path,encoding='utf-8').read()
    for old,new in pairs:
        if s.count(old)!=1: raise SystemExit(f"{path}: {s.count(old)} de {old[:60]!r}")
        s=s.replace(old,new)
    open(path,'w',encoding='utf-8').write(s); print("OK", path)

sub('ds02-pandas.md', [
("""- **La medición de esta sección es la única del track que corre sobre los datos reales de Áurea
  sin repetir el bloque.** Conviene que siga así: si `ds03` necesita tamaños mayores, que los
  declare como sintéticos igual que `ds01`.""",
 """- 🪦 **`ds03` mantuvo la costumbre:** sus cuatro tamaños chicos son recortes reales del conjunto
  —un mes, un trimestre, un año y la historia completa— y solo los dos grandes son sintéticos, y
  lo declaran. Esta medición sigue siendo la única que no necesita **ningún** tamaño inventado
  para tener algo que medir."""),
])
sub('prompts/README.md', [
("cerradas el 13/09/2026: 1.439 líneas de prosa", "cerradas el 13/09/2026: 1.441 líneas de prosa"),
])
sub('BENCHMARKS.md', [
("Si solo te llevas diez de este documento, que sean estos:",
 "Si solo te llevas doce de este documento, que sean estos — los diez del camino base y los dos\nque trajeron los complementos:"),
("| **87%** | Cuánto del cierre nocturno es esperar a la base de datos | 16 |",
 """| **87%** | Cuánto del cierre nocturno es esperar a la base de datos | 16 |
| **34 ms contra 97** | El bucle a mano ganándole a DuckDB en el informe mensual de Áurea | `ds03` |
| **20 de 40** | Síntomas que el guardrail léxico deja pasar, y que deciden si Recepción asistida se despliega | `ia07` |"""),
])
PY

# --- 2026-09-13T22:23:53 · Compute the attribution figures
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs/src/ds04-embudo
python3 - <<'PY'
p='attribution.py'; s=open(p,encoding='utf-8').read()
cut=s.index("def months_between(")
s=s[:cut].rstrip()+"\n"
open(p,'w',encoding='utf-8').write(s); print("recortados los auxiliares sin uso")
PY
mkdir -p data && python3 ../ds01-numpy-y-el-modelo-vectorizado/generar_embudo.py --salida data >/dev/null
python3 - <<'PY'
from datetime import date
from pathlib import Path
from attribution import *
d=Path("data")
journeys=load_journeys(d); acq=load_acquisitions(d); created=load_lead_created(d); spend=load_spend(d)
cutoff=date(2026,3,31)
mature=mature_leads(created,cutoff)
print(f"leads {len(created):,} · maduros {len(mature):,} · adquiridos {len(acq):,} · adquiridos maduros {len(set(acq)&mature):,}")
print("\n=== reparto del crédito (%) sobre leads maduros ===")
print(f"{'canal':<12}" + "".join(f"{m:>15}" for m in MODELS))
share={m: share_of_credit(credit_by_channel(journeys,acq,f,mature)) for m,f in MODELS.items()}
for c in sorted(share["primer toque"]):
    print(f"{c:<12}" + "".join(f"{share[m].get(c,0):>14.1f}%" for m in MODELS))
print("\n=== costo por paciente adquirido (COP) ===")
print(f"{'canal':<12}" + "".join(f"{m:>15}" for m in MODELS))
for c in sorted(spend):
    row=""
    for m,f in MODELS.items():
        cac=cost_per_acquisition(spend, credit_by_channel(journeys,acq,f,mature))
        row+=f"{cac.get(c,float('nan')):>14,.0f} "
    print(f"{c:<12}{row}")
print("\n=== efecto de la madurez: último toque, con y sin filtro ===")
for label, elig in (("sin filtro", None), ("maduros", mature)):
    cac=cost_per_acquisition(spend, credit_by_channel(journeys,acq,credit_last,elig))
    print(f"{label:<12}" + "".join(f"{c}={cac[c]:,.0f}  " for c in sorted(cac)))
PY

# --- 2026-09-13T22:24:30 · Recompute with a coherent window
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs/src/ds04-embudo
python3 - <<'PY'
p='attribution.py'; s=open(p,encoding='utf-8').read()
old='''def load_spend(data: Path) -> dict[str, int]:
    """Gasto de pauta por canal. Solo existen los tres canales pagos."""
    spend: defaultdict[str, int] = defaultdict(int)
    with (data / "pauta.csv").open(encoding="utf-8", newline="") as file:
        for row in csv.DictReader(file):
            spend[row["canal"]] += int(row["costo_cop"])
    return dict(spend)


def load_spend_by_branch(data: Path) -> dict[tuple[str, str], int]:
    spend: defaultdict[tuple[str, str], int] = defaultdict(int)
    with (data / "pauta.csv").open(encoding="utf-8", newline="") as file:
        for row in csv.DictReader(file):
            spend[(row["canal"], row["sede"])] += int(row["costo_cop"])
    return dict(spend)'''
new='''def load_spend(data: Path, until: date | None = None) -> dict[str, int]:
    """Gasto de pauta por canal, hasta `until` inclusive. Solo hay tres canales pagos.

    ⚠️ **`until` no es un adorno: es lo que hace comparable el cociente.** Si el denominador
    se recorta a los leads maduros —los creados hasta `corte - MATURITY`— y el numerador se
    queda con el gasto de todo el período, el costo por adquisición sale inflado por la
    pauta de unas semanas que todavía no pudo producir a nadie. La primera versión de este
    módulo tenía ese error y hacía que el filtro de madurez **empeorara** el número de
    TikTok en vez de mejorarlo, que era justo al revés de lo que decía el texto.
    """
    spend: defaultdict[str, int] = defaultdict(int)
    with (data / "pauta.csv").open(encoding="utf-8", newline="") as file:
        for row in csv.DictReader(file):
            if until is None or date.fromisoformat(row["fecha"]) <= until:
                spend[row["canal"]] += int(row["costo_cop"])
    return dict(spend)


def load_spend_by_branch(data: Path,
                         until: date | None = None) -> dict[tuple[str, str], int]:
    spend: defaultdict[tuple[str, str], int] = defaultdict(int)
    with (data / "pauta.csv").open(encoding="utf-8", newline="") as file:
        for row in csv.DictReader(file):
            if until is None or date.fromisoformat(row["fecha"]) <= until:
                spend[(row["canal"], row["sede"])] += int(row["costo_cop"])
    return dict(spend)'''
assert s.count(old)==1
open(p,'w',encoding='utf-8').write(s.replace(old,new)); print("OK")
PY
python3 - <<'PY'
from datetime import date
from pathlib import Path
from attribution import *
d=Path("data"); cutoff=date(2026,3,31); limit=cutoff-MATURITY
journeys=load_journeys(d); acq=load_acquisitions(d); created=load_lead_created(d)
mature=mature_leads(created,cutoff)
spend_all=load_spend(d); spend_mature=load_spend(d, until=limit)
print(f"ventana madura: hasta {limit} · gasto total {sum(spend_all.values()):,} → {sum(spend_mature.values()):,}")
print("\n=== CAC por modelo, ventana coherente ===")
print(f"{'canal':<12}" + "".join(f"{m:>16}" for m in MODELS))
cac={m: cost_per_acquisition(spend_mature, credit_by_channel(journeys,acq,f,mature)) for m,f in MODELS.items()}
for c in sorted(spend_mature):
    print(f"{c:<12}" + "".join(f"{cac[m][c]:>15,.0f} " for m in MODELS))
print("\n=== el efecto del filtro de madurez (último toque) ===")
a=cost_per_acquisition(spend_all, credit_by_channel(journeys,acq,credit_last,None))
b=cost_per_acquisition(spend_mature, credit_by_channel(journeys,acq,credit_last,mature))
for c in sorted(a): print(f"  {c:<10} sin filtro {a[c]:>12,.0f} → maduros {b[c]:>12,.0f}  ({(b[c]/a[c]-1)*100:+.1f}%)")
print("\n=== suma de créditos: ¿cuántos pacientes reparte cada modelo? ===")
for m,f in MODELS.items(): print(f"  {m:<14}{sanity_check(journeys,acq,f,mature):>10.1f}  (adquiridos maduros: {len(set(acq)&mature)})")
PY

# --- 2026-09-13T22:24:56 · Compute bootstrap intervals and the partner network figures
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs/src/ds04-embudo
python3 - <<'PY'
import csv, random
from collections import defaultdict
from datetime import date
from pathlib import Path
from attribution import *
d=Path("data"); cutoff=date(2026,3,31); limit=cutoff-MATURITY
journeys=load_journeys(d); acq=load_acquisitions(d); created=load_lead_created(d)
mature=mature_leads(created,cutoff); spend=load_spend(d, until=limit)
pool=[l for l in acq if l in mature]

def cac_of(sample, model, channel):
    tot=0.0
    for lead in sample:
        tot += model(journeys[lead]).get(channel, 0.0)
    return spend[channel]/tot if tot else float("nan")

rng=random.Random(20260913)
print("=== intervalo bootstrap 95% (200 remuestreos) ===")
for name,model in MODELS.items():
    row=f"{name:<14}"
    for ch in ("google","instagram","tiktok"):
        point=cac_of(pool,model,ch)
        sims=sorted(cac_of([pool[rng.randrange(len(pool))] for _ in pool],model,ch) for _ in range(200))
        row+=f"{ch[:3]} {point/1e6:.2f}M [{sims[4]/1e6:.2f}–{sims[194]/1e6:.2f}]  "
    print(row)

print("\n=== aliados: comisión contra pacientes que volvieron ===")
partners={r["aliado_id"]: r for r in csv.DictReader(open(d/"aliados.csv",encoding="utf-8"))}
ref=list(csv.DictReader(open(d/"remisiones.csv",encoding="utf-8")))
by=defaultdict(lambda: [0,0,0])
for r in ref:
    b=by[r["aliado_id"]]; b[0]+=1; b[1]+=int(r["volvio"]); b[2]+=int(r["comision_cop"])
rows=[(a, v[0], v[1]/v[0], v[2], v[2]/max(v[1],1)) for a,v in by.items() if v[0]>=30]
rows.sort(key=lambda r: r[4])
print(f"remisiones {len(ref):,} · aliados con ≥30 remisiones: {len(rows)}")
for a,n,rate,fee,per in rows[:3]+rows[-3:]:
    p=partners[a]
    print(f"  {a} {p['especialidad']:<16}{p['zona']:<10} n={n:>3} volvieron {rate:5.1%} comisión {fee:>12,} → {per:>11,.0f}/paciente")
tot_fee=sum(int(r["comision_cop"]) for r in ref); tot_ret=sum(int(r["volvio"]) for r in ref)
print(f"  TOTAL: {tot_fee:,} COP de comisiones · {tot_ret:,} de {len(ref):,} volvieron ({tot_ret/len(ref):.1%}) → {tot_fee/tot_ret:,.0f} por paciente que volvió")
PY

# --- 2026-09-13T22:26:38 · Run the attribution measurement
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs/src/ds04-embudo
time python3 bench_attribution.py --datos data 2>&1 | tail -30

# --- 2026-09-13T22:27:49 · Run the ds04 test suite
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs/src/ds04-embudo
uv run --python 3.14 --with pytest python -m pytest -q 2>&1 | tail -30

# --- 2026-09-13T22:28:09 · Collect funnel, seasonality and partner figures
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs/src/ds04-embudo
python3 - <<'PY'
from datetime import date
from pathlib import Path
from attribution import *
from funnel import *
from partners import *
d=Path("data"); CUT=date(2026,3,31)
created=load_lead_created(d); acq=load_acquisitions(d); interest=load_lead_interest(d)
print("=== embudo completo ===")
for stage,n,pct_total,pct_step in stage_rates(load_stage_reach(d), len(created)):
    print(f"  {stage:<22}{n:>7,}  {pct_total:>6.1f}% del total  {pct_step:>6.1f}% del paso anterior")
print("\n=== cohortes: las tres últimas maduras y las tres inmaduras ===")
co=cohort_conversion(created,set(acq),CUT,MATURITY)
items=list(co.items())
for m,(t,w,r,mat) in items[-8:]:
    print(f"  {m}  {t:>5} leads · {w:>4} aceptaron · {r:>5.1f}%  {'maduro' if mat else '⚠️ INMADURO'}")
print("\n=== estacionalidad (índice, 1.0 = promedio) ===")
for label, only in (("ortodoncia","ortodoncia"),("estetica","estetica")):
    idx=seasonal_index(leads_by_month(created,interest,only))
    print(f"  {label:<11}" + " ".join(f"{m:02d}:{v:.2f}" for m,v in idx.items()))
print("\n=== Semana Santa 2025 (Pascua 20/04) ===")
ins,out=holy_week_drop(created,2025,date(2025,4,20))
print(f"  dentro {ins:.1f} leads/día · fuera {out:.1f} leads/día · {ins/out:.0%} del ritmo normal")
print("\n=== red de aliados ===")
vals=load_partner_values(d); s=network_summary(vals)
print(f"  {s['aliados']:.0f} aliados · {s['remisiones']:,.0f} remisiones · {s['volvieron']:,.0f} volvieron ({s['tasa_retorno']:.1%})")
print(f"  comisiones {s['comisiones_cop']:,.0f} COP → {s['costo_por_retenido']:,.0f} por paciente retenido")
r=ranked(vals)
print(f"  mejor: {r[0].partner_id} {r[0].specialty} {r[0].zone} {r[0].cost_per_returned:,.0f} · peor: {r[-1].partner_id} {r[-1].specialty} {r[-1].zone} {r[-1].cost_per_returned:,.0f} ({r[-1].cost_per_returned/r[0].cost_per_returned:.2f}×)")
print("  por especialidad:", {k: f"{v/1e6:.2f}M" for k,v in by_dimension(vals,"specialty").items()})
print("  por zona:", {k: f"{v/1e6:.2f}M" for k,v in by_dimension(vals,"zone").items()})
PY

# --- 2026-09-13T22:28:44 · Decorrelate zone from specialty and recompute partners
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs/src/ds01-numpy-y-el-modelo-vectorizado
python3 - <<'PY'
p='generar_embudo.py'; s=open(p,encoding='utf-8').read()
old='''    partners = [{
        "aliado_id": f"A{index:03d}",
        "especialidad": SPECIALTIES[index % len(SPECIALTIES)],
        "zona": ZONES[(index * 3) % len(ZONES)],'''
new='''    # La especialidad se reparte en orden y la zona **se sortea**. Con las dos derivadas del
    # índice —`SPECIALTIES[i % 5]` y `ZONES[(i * 3) % 5]`— quedaban perfectamente
    # correlacionadas sobre veintitrés aliados, y agrupar por una o por otra daba exactamente
    # la misma tabla. Eso no es una propiedad de Áurea: es aritmética modular, y le habría
    # quitado el sentido a la pregunta de `ds04` sobre si el problema es el aliado o la
    # especialidad que se le remite.
    partners = [{
        "aliado_id": f"A{index:03d}",
        "especialidad": SPECIALTIES[index % len(SPECIALTIES)],
        "zona": rng.choice(ZONES),'''
assert s.count(old)==1
open(p,'w',encoding='utf-8').write(s.replace(old,new)); print("OK")
PY
python3 - <<'PY'
p='test_generar_embudo.py'; s=open(p,encoding='utf-8').read()
anchor='''def test_cada_remision_apunta_a_un_aliado_que_existe(dataset):'''
new='''def test_la_zona_y_la_especialidad_no_son_la_misma_particion(dataset):
    """Nacieron las dos del índice del aliado y quedaban perfectamente correlacionadas: con
    veintitrés aliados, `i % 5` y `(i * 3) % 5` parten el conjunto igual. Agrupar por zona o
    por especialidad daba la misma tabla, y `ds04` se quedaba sin poder preguntar si el
    problema es el aliado o el caso que se le remite."""
    pairs = {(row["especialidad"], row["zona"]) for row in dataset["aliados.csv"]}
    by_specialty: dict[str, set[str]] = {}
    for specialty, zone in pairs:
        by_specialty.setdefault(specialty, set()).add(zone)
    assert any(len(zones) > 1 for zones in by_specialty.values())


def test_cada_remision_apunta_a_un_aliado_que_existe(dataset):'''
assert s.count(anchor)==1
open(p,'w',encoding='utf-8').write(s.replace(anchor,new,1)); print("OK test")
PY
uv run --python 3.14 --with pytest --with 'numpy==2.5.3' python -m pytest -q 2>&1|tail -2
cd ../ds04-embudo && rm -rf data && mkdir -p data && python3 ../ds01-numpy-y-el-modelo-vectorizado/generar_embudo.py --salida data >/dev/null
python3 - <<'PY'
from pathlib import Path
from partners import *
vals=load_partner_values(Path("data")); s=network_summary(vals); r=ranked(vals)
print(f"{s['aliados']:.0f} aliados · {s['remisiones']:,.0f} remisiones · {s['volvieron']:,.0f} volvieron ({s['tasa_retorno']:.1%}) · comisiones {s['comisiones_cop']:,.0f} → {s['costo_por_retenido']:,.0f}/retenido")
print(f"mejor {r[0].partner_id} {r[0].specialty} {r[0].zone} {r[0].cost_per_returned:,.0f} · peor {r[-1].partner_id} {r[-1].specialty} {r[-1].zone} {r[-1].cost_per_returned:,.0f} ({r[-1].cost_per_returned/r[0].cost_per_returned:.2f}×)")
print("especialidad:", {k: f"{v/1e6:.2f}M" for k,v in by_dimension(vals,"specialty").items()})
print("zona:        ", {k: f"{v/1e6:.2f}M" for k,v in by_dimension(vals,"zone").items()})
PY

# --- 2026-09-13T22:29:10 · Verify ds04 after the partner fix
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs/src/ds04-embudo
uv run --python 3.14 --with pytest python -m pytest -q 2>&1|tail -3
echo "--- ¿cambió la atribución? ---"
python3 bench_attribution.py --datos data 2>&1 | sed -n '15,22p'

# --- 2026-09-13T22:33:53 · Compute the exact autopsy figures
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs/src/ds04-embudo
python3 - <<'PY'
from datetime import date
from pathlib import Path
from attribution import *
d=Path("data"); CUT=date(2026,3,31)
j=load_journeys(d); a=load_acquisitions(d); c=load_lead_created(d)
m=mature_leads(c,CUT); pool={l for l in a if l in m}
cred={n: credit_by_channel(j,a,f,m) for n,f in MODELS.items()}
print("pacientes maduros:", len(pool))
for ch in ("instagram","tiktok","google"):
    best=max(cred, key=lambda n: cred[n].get(ch,0))
    print(f"  {ch:<10} mejor modelo: {best:<14} se acredita {cred[best][ch]:>8.0f}")
tot=sum(max(cred[n].get(ch,0) for n in cred) for ch in ("instagram","tiktok","google"))
print(f"  suma de los tres, cada uno con su mejor modelo: {tot:,.0f}")
paid_last=sum(cred["último toque"].get(ch,0) for ch in ("instagram","tiktok","google"))
print(f"  con último toque, los tres pagos suman: {paid_last:,.0f}")
PY

# --- 2026-09-13T22:34:09 · Replace invented autopsy figures with measured ones
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs
python3 - <<'PY'
p='ds04-embudo.md'; s=open(p,encoding='utf-8').read()
old="""- Instagram se acredita 1.014 pacientes.
- TikTok se acredita 1.658.
- Google se acredita 1.134.
- Total: **3.806 pacientes de un canal pago**… sobre 5.451 adquiridos en total, de los
  cuales solo **1.936** tuvieron un canal pago como último toque.

Los números de arriba salen de aplicarle a cada canal su modelo más favorable, que es
exactamente lo que hace cada plataforma con sus propios datos. **La suma no cuadra porque no
puede cuadrar**: el mismo paciente está contado hasta tres veces."""
new="""- TikTok, con el modelo que más le favorece —primer toque—, se acredita **1.658**.
- Instagram, con el mismo, **1.549**.
- Google, con el suyo —último toque—, **1.136**.
- Total: **4.343 pacientes traídos por un canal pago**… cuando los tres canales pagos juntos
  solo fueron el último toque de **1.883** de los 5.451 adquiridos.

Cada plataforma aplica a sus propios datos el modelo que mejor la deja, que es lo que hace
cada una en la vida real. **La suma no cuadra porque no puede cuadrar**: el mismo paciente
está contado hasta tres veces, y sobran 2.460 conversiones que no existieron."""
assert s.count(old)==1
open(p,'w',encoding='utf-8').write(s.replace(old,new)); print("OK")
PY
grep -n "2.460\|4.343" ds04-embudo.md | head -3
python3 -c "print('sobran:', 4343-1883)"

# --- 2026-09-13T22:34:23 · Find a real three-touch journey for the chapter
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs/src/ds04-embudo
python3 - <<'PY'
import csv
from pathlib import Path
from attribution import *
d=Path("data")
j=load_journeys(d); a=load_acquisitions(d)
camp={}
for r in csv.DictReader(open(d/"toques.csv",encoding="utf-8")):
    camp[(r["lead_id"], r["fecha_hora"])] = r["campana"]
plans={r["lead_id"]: r for r in csv.DictReader(open(d/"planes_de_tratamiento.csv",encoding="utf-8"))}
for lead, t in j.items():
    if lead in a and len(t)==3 and [c for _,c in t]==["tiktok","instagram","google"]:
        print("lead", lead, "· plan", plans[lead]["valor_total_cop"], "· sede", plans[lead]["sede"])
        for when,ch in t: print(f"  {when.isoformat(sep=' ',timespec='minutes')}  {ch:<10} ({camp[(lead,when.isoformat(timespec='seconds'))]})")
        print(f"  {a[lead]}  plan_aceptado")
        break
else: print("no hay un recorrido tiktok→instagram→google; busco cualquiera de 3 toques distintos")
spend=load_spend(d)
print("\ngasto tiktok/mes:", f"{spend['tiktok']/27:,.0f}", "· instagram:", f"{spend['instagram']/27:,.0f}", "· google:", f"{spend['google']/27:,.0f}")
PY

# --- 2026-09-13T22:34:40 · Use the real journey and lint ds04
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs
python3 - <<'PY'
p='ds04-embudo.md'; s=open(p,encoding='utf-8').read()
old="""Este es un recorrido real del conjunto, el de un lead que aceptó un plan de catorce millones:

```
2025-07-14 20:11  tiktok      (tt-antes-y-despues)
2025-08-02 11:47  instagram   (ig-brackets-adolescente)
2025-09-19 09:03  google      (sem-ortodoncia-bogota)
2025-10-01 16:22  plan_aceptado
```

¿Qué canal trajo a este paciente? Las tres respuestas obvias son defendibles: TikTok, porque
sin el video no existiría; Google, porque es donde decidió; los tres, porque hicieron falta
los tres. Y cada una de las tres le da un costo por adquisición distinto a un canal en el que
Marcela gasta setenta millones al mes."""
new="""Este es el recorrido del lead `L0000097`, que aceptó un plan de 9.900.000 pesos en la sede de
Suba. Está en el conjunto, tal cual:

```
2024-01-09 18:29  tiktok      (tt-antes-y-despues)
2024-01-21 02:41  instagram   (ig-brackets-adolescente)
2024-01-21 05:13  google      (sem-ortodoncia-bogota)
2024-02-13        plan_aceptado
```

¿Qué canal trajo a este paciente? Las tres respuestas obvias son defendibles: TikTok, porque
sin el video no existiría; Google, porque es donde decidió; los tres, porque hicieron falta
los tres. Y cada una de las tres le da un costo por adquisición distinto a un canal en el que
Marcela gasta **casi setenta y cinco millones de pesos al mes** — los tres canales pagos
reciben casi lo mismo, y esa simetría del presupuesto es justamente lo que hace que la
diferencia de la sección 6 venga del reparto y no del gasto."""
assert s.count(old)==1
open(p,'w',encoding='utf-8').write(s.replace(old,new)); print("OK")
PY
cd src/ds04-embudo && uvx ruff@0.16.7 check . 2>&1 | grep -E "^[A-Z][0-9]+" | head

# --- 2026-09-13T22:34:47 · Fix lint and re-run ds04 tests
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs/src/ds04-embudo
uvx ruff@0.16.7 check --fix . >/dev/null 2>&1; uvx ruff@0.16.7 check . && echo "LINT OK"
uv run --python 3.14 --with pytest python -m pytest -q 2>&1|tail -2

# --- 2026-09-13T22:35:14 · Lint with the course's documented ruff selection
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs/src
echo "=== con la selección que documenta la Fase 00 (E,F,I,UP,B) ==="
for d in ds01-numpy-y-el-modelo-vectorizado ds02-pandas ds03-polars-y-el-modelo-lazy ds04-embudo ds07-scikit-learn; do
  printf "  %-42s" "$d"; (cd $d && uvx ruff@0.16.7 check --select E,F,I,UP,B --line-length 100 --target-version py314 . >/dev/null 2>&1 && echo OK || echo FALLA)
done
echo "=== y las suites ==="
for d in ds01-numpy-y-el-modelo-vectorizado ds02-pandas ds03-polars-y-el-modelo-lazy ds04-embudo ds07-scikit-learn; do
  printf "  %-42s" "$d"; (cd $d && uv run --python 3.14 --with pytest --with 'numpy==2.5.3' --with 'pandas==3.0.5' --with 'polars==1.44.2' --with 'duckdb==1.5.5' python -m pytest -q 2>&1|tail -1); done

# --- 2026-09-13T22:35:45 · Show the real lint failures
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs/src
for d in ds01-numpy-y-el-modelo-vectorizado ds04-embudo ds07-scikit-learn; do echo "--- $d"; (cd $d && uvx ruff@0.16.7 check --select E,F,I,UP,B --line-length 100 --target-version py314 . 2>&1 | grep -E "^[A-Z][0-9]+|-->" | head -8); done

# --- 2026-09-13T22:36:02 · Fix zip strictness and the unused loop variable
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs/src
python3 - <<'PY'
import re
def fix(path, pairs):
    s=open(path,encoding='utf-8').read()
    for old,new in pairs:
        if s.count(old)!=1: raise SystemExit(f"{path}: {s.count(old)} de {old[:60]!r}")
        s=s.replace(old,new)
    open(path,'w',encoding='utf-8').write(s); print("OK", path)

fix('ds01-numpy-y-el-modelo-vectorizado/generar_embudo.py', [
("                for order, (channel, offset) in enumerate(zip(path, moments), start=1):",
 "                for order, (channel, offset) in enumerate(zip(path, moments, strict=True),\n                                                          start=1):"),
("                for stage, odds in zip(STAGES, STAGE_ODDS[last]):",
 "                for stage, odds in zip(STAGES, STAGE_ODDS[last], strict=True):"),
])
for p in ('ds01-numpy-y-el-modelo-vectorizado/test_generar_embudo.py',
          'ds07-scikit-learn/test_generar_ausentismo.py'):
    fix(p, [('    return [dict(zip(header, line.split(","))) for line in lines[1:]]',
             '    # `strict=True` no es adorno: si una fila trae más o menos columnas que el\n'
             '    # encabezado, el `zip` silencioso la recortaría y la prueba pasaría sobre datos\n'
             '    # mutilados.\n'
             '    return [dict(zip(header, line.split(","), strict=True)) for line in lines[1:]]')])
fix('ds04-embudo/bench_attribution.py', [
("""    print("\\n=== La comprobación que ningún tablero pasa ===")
    for name, model in MODELS.items():
        total = sum(credit_by_channel(journeys, acquisitions, model, mature).values())""",
 """    print("\\n=== La comprobación que ningún tablero pasa ===")
    for name, model in MODELS.items():
        total = sum(credit_by_channel(journeys, acquisitions, model, mature).values())
        del model"""),
])
PY
sed -n 88,96p ds04-embudo/bench_attribution.py

# --- 2026-09-13T22:36:15 · Final lint and test sweep of the ds track
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs/src/ds04-embudo
python3 - <<'PY'
p='bench_attribution.py'; s=open(p,encoding='utf-8').read()
s=s.replace("""        for name, model in MODELS.items():
            point = cac_for(pool, journeys, model, spend, channel)""",
"""        for model in MODELS.values():
            point = cac_for(pool, journeys, model, spend, channel)""")
s=s.replace("""        total = sum(credit_by_channel(journeys, acquisitions, model, mature).values())
        del model
""","""        total = sum(credit_by_channel(journeys, acquisitions, model, mature).values())
""")
open(p,'w',encoding='utf-8').write(s); print("OK")
PY
cd .. && for d in ds01-numpy-y-el-modelo-vectorizado ds02-pandas ds03-polars-y-el-modelo-lazy ds04-embudo ds07-scikit-learn; do
  printf "  %-42s" "$d"; (cd $d && uvx ruff@0.16.7 check --select E,F,I,UP,B --line-length 100 --target-version py314 . >/dev/null 2>&1 && printf "lint OK · " || printf "LINT FALLA · "; uv run --python 3.14 --with pytest --with 'numpy==2.5.3' --with 'pandas==3.0.5' --with 'polars==1.44.2' --with 'duckdb==1.5.5' python -m pytest -q 2>&1|tail -1); done

# --- 2026-09-13T22:37:43 · Add ds04 to BENCHMARKS, INSTINTOS and the state documents
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs
python3 - <<'PY'
def sub(path, pairs):
    s=open(path,encoding='utf-8').read()
    for old,new in pairs:
        if s.count(old)!=1: raise SystemExit(f"{path}: {s.count(old)} de {old[:60]!r}")
        s=s.replace(old,new)
    open(path,'w',encoding='utf-8').write(s); print("OK", path)

sub('BENCHMARKS.md', [("""---

## ✍️ Cómo se agregan entradas""", """### ds04 · Cuatro atribuciones, cuatro respuestas

**Afirmaba:** que la elección del modelo de atribución mueve el costo por paciente adquirido
**más que cualquier diferencia real entre canales**, y que esa diferencia no es ruido de
muestreo.

**Condiciones:** biblioteca estándar, sin dependencias. Conjunto del Embudo con semilla
20260913: 32.550 leads y 6.065 adquiridos. Corte el 2026-03-31 con **madurez de 96 días** —el
rezago máximo del canal más lento—, que deja 28.416 leads maduros y **5.451 pacientes**. El
gasto se recorta a la misma ventana: 5.283.929.067 COP. Intervalo bootstrap por percentiles,
200 remuestreos, semilla fija. Los cuatro modelos corren sobre el mismo conjunto de pacientes y
**los cuatro reparten 5.451,0 créditos**, verificado por prueba.

Costo por paciente adquirido, en millones de COP, con su intervalo al 95%:

| Canal | Primer toque | Último toque | Lineal | Decaimiento |
|---|---|---|---|---|
| google | 2,76 [2,59–3,04] | **1,55** [1,47–1,64] | 2,01 [1,94–2,10] | 1,90 [1,83–1,98] |
| instagram | 1,14 [1,09–1,18] | 3,35 [3,08–3,67] | 1,74 [1,66–1,80] | 1,81 [1,73–1,88] |
| tiktok | **1,06** [1,03–1,11] | **7,96** [7,01–9,07] | 1,93 [1,87–2,02] | 2,14 [2,07–2,25] |

⚖️ **7,5× sobre los mismos 5.451 pacientes, y el ranking no se mueve: se invierte.** TikTok es
el canal más barato de los tres por primer toque y el más caro por un factor de cinco por último
toque. **No es ruido:** los intervalos al 95% ni se tocan —[1,03–1,11] contra [7,01–9,07]—, así
que la diferencia viene de quién decide que un video cuenta, no de qué pacientes tocaron. La
recomendación es reportar el **lineal** como cifra principal y publicar las dos esquinas al
lado: la banda entre modelos **es** la incertidumbre real.

**Y dos correcciones técnicas que casi nadie aplica**, con su efecto medido: esperar a que las
cohortes maduren y recortar el gasto a la misma ventana abaratan a TikTok un **8,6%**, a
Instagram un 5,9% y a Google un 2,2% —cuanto más lento el canal, más lo castiga el cálculo
ingenuo—. Son correcciones reales, y **mueven cuarenta veces menos que la elección del
modelo**.

**La red de aliados**, que nadie había calculado: 23 aliados, 2.599 remisiones, **925 pacientes
retenidos (35,6%)** y 1.165.174.000 COP de comisiones → **1.259.648 COP por paciente retenido**,
entre el costo de Google (1,55 M) y el de Instagram (3,35 M). Es el segundo canal más barato de
la empresa. Entre el mejor aliado y el peor hay 1,68×, más que entre especialidades (1,20×) o
zonas (1,16×).

→ [`ds04-embudo.md`](ds04-embudo.md) §6

---

## ✍️ Cómo se agregan entradas""")])

sub('INSTINTOS.md', [("""---

## 🧪 Los reflejos de método""", """### 30. "Cada hecho tiene un dueño"

Once años de sistemas transaccionales dejan esto por debajo de todo lo demás: una venta tiene un
vendedor, un pedido tiene un cliente, una fila tiene su llave foránea. Y el reflejo se aplica
solo: `SELECT canal, count(*) … GROUP BY canal`.

El problema es que **una conversión no tiene dueño**. El paciente vio un video en enero, escribió
en febrero y buscó en Google en marzo; el `GROUP BY` exige elegir una columna, y al elegirla
—`canal_ultimo_toque`, porque estaba ahí— tomaste una decisión de negocio sin enterarte. Sobre
los mismos 5.451 pacientes de Áurea, esa decisión mueve el costo de TikTok entre **1,06 y 7,96
millones**: 7,5×, con los intervalos al 95% sin tocarse.

Lo que se lleva el reflejo corregido no es un modelo mejor: es la obligación de **nombrar el
reparto en la salida** y publicar la banda entre modelos. Cuando dos modelos dan la misma
decisión, adelante. Cuando dan decisiones opuestas, el informe no puede decidir y lo que
corresponde es un experimento. *(`ds04`)*

---

## 🧪 Los reflejos de método""")])

sub('prompts/README.md', [
("| **T9** | `ds04` · **Proyecto Embudo** | Solo: importa las tres anteriores y sostiene dos atribuciones sobre los mismos datos |",
 "| **T9** ✅ | `ds04`, cerrada el 13/09/2026: **cuatro** modelos de atribución, su medición con intervalo bootstrap y 23 pruebas | Solo: importa las tres anteriores y sostiene dos atribuciones sobre los mismos datos |"),
("""> los dos conjuntos de datos; **T7**, `ds01` y `ds02`; y **T8**, `ds03`. Las cuatro mediciones del
> track están **ejecutadas**, no en `⏳`. La siguiente es **T9** (`ds04`, el proyecto Embudo).""",
 """> los dos conjuntos de datos; **T7**, `ds01` y `ds02`; **T8**, `ds03`; y **T9**, `ds04`. Las
> cinco mediciones del track están **ejecutadas**, no en `⏳`. La siguiente es **T10**
> (`ds05` + `ds06`)."""),
])

sub('prompts/prompts-de-tracks-ia-ds.md', [
("| `ds04-embudo.md` | **Proyecto · Embudo** | Embudo | Costo por paciente adquirido, por canal |",
 "| `ds04-embudo.md` ✅ | **Proyecto · Embudo** | Embudo | Costo por paciente adquirido, por canal — **ejecutada, cuatro modelos con intervalo** |"),
("""> 🚧 **El track `ds` va por `ds03`.** T6 dejó los dos conjuntos de datos; T7 escribió `ds01` y
> `ds02`; T8, `ds03`. **Las cuatro mediciones están ejecutadas**""",
 """> 🚧 **El track `ds` va por `ds04`.** T6 dejó los dos conjuntos de datos; T7 escribió `ds01` y
> `ds02`; T8, `ds03`; T9, `ds04`. **Las cinco mediciones están ejecutadas**"""),
("""> ganadores distintos**: la consulta con el motor caliente y el informe de punta a punta.
> Siguiente: T9, `ds04`.""",
 """> ganadores distintos**: la consulta con el motor caliente y el informe de punta a punta. La de
> `ds04` no mide tiempo: mide **cuánto cambia la respuesta al negocio** según el modelo de
> atribución, y da 7,5×. Siguiente: T10, `ds05` y `ds06`."""),
])
PY

# --- 2026-09-13T22:38:01 · Final checks and memory update
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs
rm -rf src/ds0*/data src/ds0*/__pycache__ src/ds0*/.pytest_cache .pytest_cache 2>/dev/null
python3 - <<'PY'
import re,os
bad=[]
for root,d,fs in os.walk('.'):
    if 'pytest_cache' in root: continue
    for f in fs:
        if not f.endswith('.md'): continue
        p=os.path.join(root,f)
        for i,l in enumerate(open(p,encoding='utf-8'),1):
            for m in re.finditer(r'\]\((?!https?:)([^)#]+\.md)(?:#[^)]*)?\)',l):
                t=m.group(1)
                if not os.path.exists(os.path.normpath(os.path.join(root,t))): bad.append(f"{p}:{i} -> {t}")
print("links rotos:", "\n".join(bad) or "ninguno")
PY
wc -l ds0*.md | tail -6
cd /Users/oskar/.claude/projects/-Users-oskar-Developer-Learning-courses-ia-generated/memory
python3 - <<'PY'
p='python-java-devs-estado.md'; s=open(p,encoding='utf-8').read()
old="**Lo siguiente es T9 (`ds04`, el proyecto Embudo).**"
new="""**T9 cerrada el 13/09/2026**: `ds04-embudo.md` (826 líneas), el proyecto Embudo entero, con
`attribution.py`, `funnel.py`, `partners.py` y 23 pruebas sin dependencias. La medición **no mide
tiempo**: mide cuánto cambia la respuesta al negocio según el modelo de atribución, y da **7,5×**
—TikTok cuesta 1,06 M por primer toque y 7,96 M por último, con los intervalos bootstrap al 95%
sin tocarse—. El ranking no se mueve: se invierte. Recomendación: reportar el lineal y publicar
las dos esquinas, porque la banda entre modelos **es** la incertidumbre real. Dos correcciones
técnicas medidas (madurez de 96 días + gasto recortado a la misma ventana) abaratan a TikTok un
8,6%: cuarenta veces menos que la elección del modelo. La red de aliados resultó ser el segundo
canal más barato de la empresa: **1.259.648 COP por paciente retenido**.

Tres defectos propios corregidos en T9: el filtro de madurez recortaba el denominador pero no el
gasto (y por eso *empeoraba* el número de TikTok); la zona y la especialidad de los aliados
nacían las dos del índice y partían igual el conjunto, así que agrupar por una o por otra daba la
misma tabla (ahora la zona se sortea; solo cambian `aliados.csv` y `remisiones.csv`, que ninguna
otra sección lee); y varios `zip()` sin `strict=`. **El lint del track se corre con la selección
que documenta la Fase 00 —`E,F,I,UP,B`, línea de 100—, no con los valores por defecto de ruff**,
que son más estrictos que el curso.

**Lo siguiente es T10 (`ds05` + `ds06`).**"""
assert s.count(old)==1
open(p,'w',encoding='utf-8').write(s.replace(old,new)); print("OK memoria")
PY

# --- 2026-09-13T22:38:07 · Correct the line count in memory
cd /Users/oskar/.claude/projects/-Users-oskar-Developer-Learning-courses-ia-generated/memory
sed -i '' 's/`ds04-embudo.md` (826 líneas)/`ds04-embudo.md` (758 líneas)/' python-java-devs-estado.md
grep -c "758" python-java-devs-estado.md

# --- 2026-09-14T00:59:24 · Count tests per file and compare with the documented figures
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs/src
for f in ds0*/test_*.py; do printf "%-58s %s\n" "$f" "$(grep -c '^def test_' $f)"; done
echo "--- lo que dicen los README y prompts ---"
grep -rn "pruebas" ds0*/README.md ../prompts/README.md | grep -oE "[0-9]+ pruebas|47 pruebas" | sort | uniq -c

# --- 2026-09-14T00:59:32 · Find every test-count claim
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs
grep -n "Nueve pruebas\|Diez pruebas\|Once pruebas\|Veintitrés pruebas\|28 pruebas\|39 pruebas\|47 pruebas\|31 pruebas" ds0*.md src/ds0*/README.md prompts/README.md

# --- 2026-09-14T00:59:46 · Add the course ruff config and verify linting both ways
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs
cat > ruff.toml <<'EOF'
# Configuración de ruff para todo el curso.
# Es la misma que imprime la Fase 00 y que el lector crea en su propio proyecto; vive aquí
# para que el código de `src/` se revise con la regla que el curso enseña y no con los
# valores por defecto de la herramienta, que son más estrictos.
# Todavía no existe pyproject.toml (llega en la Fase 07); cuando exista,
# esto se muda ahí bajo [tool.ruff] y este archivo desaparece.

target-version = "py314"
line-length = 100

[lint]
# El conjunto por defecto (E, F) más tres familias que este perfil agradece:
#   I  → ordena los imports, que es lo que hacía tu IDE en Java
#   UP → avisa cuando escribes una forma antigua que 3.14 ya no necesita
#   B  → bugbear: trampas reales, incluido el argumento por defecto mutable de la Fase 01
select = ["E", "F", "I", "UP", "B"]
EOF
echo "=== lint con la config del curso, desde la raíz y desde dentro ==="
uvx ruff@0.16.7 check src/ && echo "  raíz: OK"
for d in src/ds01-numpy-y-el-modelo-vectorizado src/ds02-pandas src/ds03-polars-y-el-modelo-lazy src/ds04-embudo src/ds07-scikit-learn; do printf "  %-46s" "$d"; (cd $d && uvx ruff@0.16.7 check . >/dev/null 2>&1 && echo OK || echo FALLA); done

# --- 2026-09-14T01:00:08 · Check whether the base course quotes the offending line
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs
grep -n "processed_keys.clear()" 13-integraciones.md src/13-integraciones/socio_falible.py
echo "=== ¿qué más del camino base falla con la config del curso? ==="
uvx ruff@0.16.7 check src/ 2>&1 | grep -E "^--> |  --> " | grep -v "ds0" | sort | uniq -c | head

# --- 2026-09-14T01:00:22 · List the non-I001 violations across the published src
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs
uvx ruff@0.16.7 check src/ --output-format concise 2>&1 | grep -v "I001" | sed 's/:.*\] / /' | awk '{print $1}' | sort | uniq -c | sort -rn
echo "--- detalle ---"
uvx ruff@0.16.7 check src/ --output-format concise 2>&1 | grep -v "I001"

# --- 2026-09-14T01:00:38 · Inspect the two undefined-name findings
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs
echo "=== ia03 agent_runner.py 20-40 ==="; sed -n 20,40p src/ia03-tool-calling-y-el-bucle-de-agente/agent_runner.py
echo "=== ia08 test_produccion.py 165-180 ==="; sed -n 165,180p src/ia08-produccion-y-el-veredicto/test_produccion.py

# --- 2026-09-14T01:00:50 · Read the two files to judge the findings
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs
echo "=== ia03 agent_runner.py (1-20) ==="; sed -n 1,20p src/ia03-tool-calling-y-el-bucle-de-agente/agent_runner.py
echo; echo "=== grep agenda en ia03 ==="; grep -rn "agenda" src/ia03-tool-calling-y-el-bucle-de-agente/*.py | head
echo; echo "=== ia08 head ==="; sed -n 1,15p src/ia08-produccion-y-el-veredicto/test_produccion.py

# --- 2026-09-14T01:01:21 · Fix test counts and record the lint debt
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs
python3 - <<'PY'
def sub(path, pairs):
    s=open(path,encoding='utf-8').read()
    for old,new in pairs:
        if s.count(old)!=1: raise SystemExit(f"{path}: {s.count(old)} de {old[:60]!r}")
        s=s.replace(old,new)
    open(path,'w',encoding='utf-8').write(s); print("OK", path)

sub('src/ds01-numpy-y-el-modelo-vectorizado/README.md', [
("| `test_generar_embudo.py` · `test_acquisition.py` | 39 pruebas: `pytest` |",
 "| `test_generar_embudo.py` · `test_acquisition.py` | 40 pruebas: `pytest` |"),
])
sub('prompts/README.md', [
("los dos generadores, sus dos `README.md` y **47 pruebas** que corren sin dependencias",
 "los dos generadores, sus dos `README.md` y **50 pruebas** que corren sin dependencias"),
("cerradas el 13/09/2026: 1.441 líneas de prosa, **47 pruebas** y **las dos mediciones ejecutadas**",
 "cerradas el 13/09/2026: 1.442 líneas de prosa, **19 pruebas nuevas** y **las dos mediciones ejecutadas**"),
])

# la deuda de lint del material publicado, anotada donde se ve
p='prompts/README.md'; s=open(p,encoding='utf-8').read()
anchor = "## ⚠️ Las tres cosas que más se rompen al escribir"
new = """## 🧹 Deuda declarada: el lint del material ya publicado

`ruff.toml` vive en la raíz del curso desde el 13/09/2026, con la misma selección que imprime
la Fase 00 (`E, F, I, UP, B`, línea de 100). Al aplicarlo sobre `src/` aparecen **14 avisos en
código ya publicado**, ninguno de los cuales rompe en ejecución:

| Dónde | Qué |
|---|---|
| `13-integraciones/socio_falible.py` | dos `E702`: tres sentencias separadas por punto y coma |
| `ia04/generar_corpus.py` · `ia05/bench_answers.py` · `ia05/test_normarag.py` · `ia06/generar_evalset.py` | seis `E501`: líneas de 101 a 111 columnas |
| `ia05/bench_answers.py` · `ia05/test_normarag.py` | dos `F401`: imports sin usar |
| `ia06/bench_judges.py` · `ia06/statistics_helpers.py` | dos `B905`: `zip()` sin `strict=` |
| `ia03/agent_runner.py` | `F821` sobre `agenda`, que es una inyección de módulo declarada y deliberada |
| `ia08/test_produccion.py` | `UP037` + `F821`: una anotación entrecomillada cuyo tipo se importa dentro de la función |

**No se corrigieron en T9 a propósito.** Son ocho secciones cerradas y varias de esas líneas
están transcritas en sus capítulos: arreglar el código sin arreglar la prosa produce deriva, que
es peor que el aviso. Merecen **una tanda de limpieza propia**, con sus capítulos al lado. Los dos
`B905` son los que más valen: son el mismo defecto que `ds01` §5.3 enseña a no cometer.

📝 El lint se corre **desde dentro de cada directorio de `src/`**, que es como el lector ejecuta
todo. Desde la raíz, `ruff` no reconoce como propios los módulos vecinos de cada sección y reporta
`I001` donde no lo hay.

---

## ⚠️ Las tres cosas que más se rompen al escribir"""
assert s.count(anchor)==1
open(p,'w',encoding='utf-8').write(s.replace(anchor,new,1)); print("OK deuda anotada")
PY
wc -l ds01-numpy-y-el-modelo-vectorizado.md ds02-pandas.md | tail -1

# --- 2026-09-14T01:01:44 · Verify the pinned visualization and notebook stacks install
cd /tmp && uv run --python 3.14 --with 'matplotlib==3.11.2' --with 'plotly==7.0.0' --with 'altair==6.2.2' python -c "
import matplotlib, plotly, altair
print('matplotlib', matplotlib.__version__, '· plotly', plotly.__version__, '· altair', altair.__version__)" 2>&1 | tail -3
echo "--- cuadernos ---"
uv run --python 3.14 --with 'papermill==2.7.0' --with 'jupyterlab==4.6.3' python -c "
import papermill, nbformat, nbclient
print('papermill', papermill.__version__, '· nbformat', nbformat.__version__, '· nbclient', nbclient.__version__)" 2>&1 | tail -3

# --- 2026-09-14T01:02:57 · Check the brand palette contrast figures
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs/src/ds05-visualizacion
python3 - <<'PY'
from palette import *
print("color      contraste  texto  barra   gris")
for name,(ratio,text,large) in check_palette().items():
    print(f"{name:<10} {ratio:>8.2f}  {'sí' if text else 'NO':<6}{'sí' if large else 'NO':<7}{to_grayscale(BRAND[name])}")
print("\nlegibles para texto:", readable_colors())
print("¿se distinguen impresos los cinco?", distinguishable_in_print(list(BRAND.values())))
sub=[BRAND[n] for n in ("carbon","teja","pizarra")]
print("¿y los tres oscuros?", distinguishable_in_print(sub))
PY

# --- 2026-09-14T01:03:48 · Render the dashboard in the three libraries
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs/src/ds05-visualizacion
mkdir -p salida && uv run --python 3.14 --with 'matplotlib==3.11.2' --with 'plotly==7.0.0' --with 'altair==6.2.2' python - <<'PY'
from pathlib import Path
from dashboard import *
print(as_table()); print()
for name, fn in (("matplotlib", as_matplotlib), ("plotly", as_plotly), ("altair", as_altair)):
    ext = ".png" if name=="matplotlib" else ".html"
    p = fn(target=Path("salida")/f"{name}{ext}")
    print(f"{name:<12}{p} · {p.stat().st_size/1024:.1f} KB")
PY

# --- 2026-09-14T01:04:37 · Run the render benchmark in isolated environments
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs/src/ds05-visualizacion
uv run --python 3.14 python bench_render.py --opcion tabla 2>&1 >/dev/null | tail -1
uv run --python 3.14 --with 'matplotlib==3.11.2' python bench_render.py --opcion matplotlib 2>&1 >/dev/null | tail -1
uv run --python 3.14 --with 'plotly==7.0.0' python bench_render.py --opcion plotly 2>&1 >/dev/null | tail -1
uv run --python 3.14 --with 'altair==6.2.2' python bench_render.py --opcion altair 2>&1 >/dev/null | tail -1
echo "--- plotly con el JS embebido (sin CDN) ---"
uv run --python 3.14 --with 'plotly==7.0.0' python - <<'PY'
from pathlib import Path
import plotly.graph_objects as go
from dashboard import AUREA_CAC, BRAND
ch=sorted(AUREA_CAC, key=lambda c:-AUREA_CAC[c][1])
f=go.Figure(go.Bar(x=[AUREA_CAC[c][1] for c in ch], y=ch, orientation="h"))
p=Path("salida/plotly-offline.html"); f.write_html(p, include_plotlyjs=True)
print(f"  {p.stat().st_size/1024/1024:.2f} MB")
PY

# --- 2026-09-14T01:05:36 · Run the ds05 test suite
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs/src/ds05-visualizacion
uv run --python 3.14 --with pytest --with 'matplotlib==3.11.2' --with 'plotly==7.0.0' --with 'altair==6.2.2' python -m pytest -q 2>&1 | tail -20

# --- 2026-09-14T01:05:58 · Fix the pairwise bug and re-run
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs/src/ds05-visualizacion
python3 - <<'PY'
p='palette.py'; s=open(p,encoding='utf-8').read()
s=s.replace("from __future__ import annotations\n",
            "from __future__ import annotations\n\nfrom itertools import pairwise\n")
old="""    grays = sorted(relative_luminance(to_grayscale(color)) for color in colors)
    return all((later + 0.05) / (earlier + 0.05) >= minimum
               for earlier, later in zip(grays, grays[1:], strict=True))"""
new="""    # `pairwise` y no `zip(grays, grays[1:], strict=True)`: la segunda lista es más corta
    # por construcción, así que el `strict=True` que el curso predica **revienta aquí**. Es
    # el reverso del consejo de `ds01`: `strict` es para secuencias que deben tener el mismo
    # largo, y un recorrido por pares nunca lo es.
    grays = sorted(relative_luminance(to_grayscale(color)) for color in colors)
    return all((later + 0.05) / (earlier + 0.05) >= minimum
               for earlier, later in pairwise(grays))"""
assert s.count(old)==1
open(p,'w',encoding='utf-8').write(s.replace(old,new)); print("OK")
PY
uv run --python 3.14 --with pytest --with 'matplotlib==3.11.2' --with 'plotly==7.0.0' --with 'altair==6.2.2' python -m pytest -q 2>&1 | tail -3

# --- 2026-09-14T01:07:09 · Run the reproducibility measurement
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs/src/ds06-notebooks-y-reproducibilidad
python3 generar_cuadernos.py --salida cuadernos >/dev/null && ls cuadernos
time uv run --python 3.14 --with 'papermill==2.7.0' python check_reproducibility.py --cuadernos cuadernos --json resultado.json 2>&1 | tail -12

# --- 2026-09-14T01:07:29 · Test an explicit kernel command
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs/src/ds06-notebooks-y-reproducibilidad
uv run --python 3.14 --with 'papermill==2.7.0' python - <<'PY'
import sys, tempfile, shutil
from pathlib import Path
import nbformat
from jupyter_client.manager import KernelManager
from nbclient import NotebookClient
km = KernelManager(kernel_name="python3")
km.kernel_cmd = [sys.executable, "-m", "ipykernel_launcher", "-f", "{connection_file}"]
with tempfile.TemporaryDirectory() as s:
    shutil.copy("cuadernos/limpio.ipynb", Path(s)/"n.ipynb")
    nb = nbformat.read(Path(s)/"n.ipynb", as_version=4)
    c = NotebookClient(nb, km=km, timeout=60, resources={"metadata":{"path":s}})
    c.execute()
    print("OK ·", [o.get("text","")[:40] for cell in nb.cells for o in cell.get("outputs",[])])
PY

# --- 2026-09-14T01:09:34 · Check the backgrounded kernel test
sleep 15; cat /private/tmp/claude-501/-Users-oskar-Developer-Learning-courses-ia-generated/2859734a-d7e6-4986-b771-4890bf56e42b/tasks/bunnb4qnv.output 2>/dev/null | tail -12

# --- 2026-09-14T01:09:59 · Install a temporary kernelspec and execute
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs/src/ds06-notebooks-y-reproducibilidad
timeout 110 uv run --python 3.14 --with 'papermill==2.7.0' python - <<'PY' 2>&1 | tail -6
import sys, tempfile, shutil
from pathlib import Path
from ipykernel.kernelspec import install
with tempfile.TemporaryDirectory() as prefix:
    path = install(user=False, prefix=prefix, kernel_name="python3")
    print("spec en:", path)
    import nbformat
    from jupyter_client.kernelspec import KernelSpecManager
    from nbclient import NotebookClient
    ksm = KernelSpecManager(kernel_dirs=[str(Path(prefix)/"share"/"jupyter"/"kernels")])
    with tempfile.TemporaryDirectory() as s:
        shutil.copy("cuadernos/limpio.ipynb", Path(s)/"n.ipynb")
        nb = nbformat.read(Path(s)/"n.ipynb", as_version=4)
        c = NotebookClient(nb, timeout=60, kernel_name="python3",
                           resources={"metadata":{"path":s}}, kernel_spec_manager=ksm)
        c.execute()
        print("OK ·", [o.get("text","").strip()[:40] for cell in nb.cells for o in cell.get("outputs",[])])
PY

# --- 2026-09-14T01:10:10 · Retry with ipykernel available
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs/src/ds06-notebooks-y-reproducibilidad
timeout 110 uv run --python 3.14 --with 'papermill==2.7.0' --with 'jupyterlab==4.6.3' python - <<'PY' 2>&1 | tail -6
import shutil, tempfile
from pathlib import Path
from ipykernel.kernelspec import install
with tempfile.TemporaryDirectory() as prefix:
    install(user=False, prefix=prefix, kernel_name="python3")
    import nbformat
    from jupyter_client.kernelspec import KernelSpecManager
    from nbclient import NotebookClient
    ksm = KernelSpecManager(kernel_dirs=[str(Path(prefix)/"share"/"jupyter"/"kernels")])
    with tempfile.TemporaryDirectory() as s:
        shutil.copy("cuadernos/limpio.ipynb", Path(s)/"n.ipynb")
        nb = nbformat.read(Path(s)/"n.ipynb", as_version=4)
        c = NotebookClient(nb, timeout=60, kernel_name="python3",
                           resources={"metadata":{"path":s}}, kernel_spec_manager=ksm)
        c.execute()
        print("OK ·", [o.get("text","").strip()[:44] for cell in nb.cells for o in cell.get("outputs",[])])
PY

# --- 2026-09-14T01:10:36 · Wire a temporary kernelspec into the checker
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs/src/ds06-notebooks-y-reproducibilidad
python3 - <<'PY'
p='generar_cuadernos.py'; s=open(p,encoding='utf-8').read()
s=s.replace('''def cell(source: str, count: int | None = None, output: str | None = None) -> dict:
    """Una celda de código, opcionalmente con su salida guardada."""
    outputs = []
    if output is not None:
        outputs = [{"output_type": "stream", "name": "stdout", "text": [output]}]
    return {"cell_type": "code", "execution_count": count, "metadata": {},
            "source": source.strip().splitlines(keepends=True), "outputs": outputs}''',
'''def cell(source: str, count: int | None = None, output: str | None = None) -> dict:
    """Una celda de código, opcionalmente con su salida guardada.

    El `id` se deriva del contenido y del `execution_count`, no se sortea: `nbformat` lo
    exige desde la versión 4.5 y un identificador aleatorio haría que el archivo cambiara
    en cada generación, que es justo lo contrario de lo que enseña esta sección.
    """
    outputs = []
    if output is not None:
        outputs = [{"output_type": "stream", "name": "stdout", "text": [output]}]
    digest = hashlib.sha1(f"{count}:{source}".encode()).hexdigest()[:8]
    return {"cell_type": "code", "id": digest, "execution_count": count, "metadata": {},
            "source": source.strip().splitlines(keepends=True), "outputs": outputs}''')
s=s.replace("import argparse\nimport json\n","import argparse\nimport hashlib\nimport json\n")
open(p,'w',encoding='utf-8').write(s)

p='check_reproducibility.py'; s=open(p,encoding='utf-8').read()
s=s.replace('''def run_once(path: Path, timeout: int = 120) -> tuple[bool, str, list[str]]:
    """Ejecuta un cuaderno en un kernel nuevo desde un directorio vacío.

    Devuelve si terminó, el tipo de error si no, y las salidas de texto que produjo.
    """
    import nbformat
    from nbclient import NotebookClient
    from nbclient.exceptions import CellExecutionError

    with tempfile.TemporaryDirectory() as scratch:''',
'''@contextmanager
def temporary_kernel():
    """Registra el kernel de este intérprete en un directorio temporal.

    Sin esto, `nbclient` busca un kernel llamado `python3` en la instalación de Jupyter del
    usuario y falla con `NoSuchKernel` en cualquier entorno efímero —el de `uv run`, el de
    CI—. Instalarlo "de verdad" con `python -m ipykernel install --user` funcionaría y
    ensuciaría la máquina de quien corra esto, que es exactamente lo que esta sección
    enseña a no hacer.
    """
    from ipykernel.kernelspec import install
    from jupyter_client.kernelspec import KernelSpecManager

    with tempfile.TemporaryDirectory() as prefix:
        install(user=False, prefix=prefix, kernel_name="python3")
        yield KernelSpecManager(
            kernel_dirs=[str(Path(prefix) / "share" / "jupyter" / "kernels")])


def run_once(path: Path, kernels, timeout: int = 120) -> tuple[bool, str, list[str]]:
    """Ejecuta un cuaderno en un kernel nuevo desde un directorio vacío.

    Devuelve si terminó, el tipo de error si no, y las salidas de texto que produjo.
    """
    import nbformat
    from nbclient import NotebookClient
    from nbclient.exceptions import CellExecutionError

    with tempfile.TemporaryDirectory() as scratch:''')
s=s.replace('''        client = NotebookClient(document, timeout=timeout, kernel_name="python3",
                                resources={"metadata": {"path": scratch}})''',
'''        client = NotebookClient(document, timeout=timeout, kernel_name="python3",
                                resources={"metadata": {"path": scratch}},
                                kernel_spec_manager=kernels)''')
s=s.replace("import argparse\nimport json\n","import argparse\nimport json\n")
s=s.replace("from pathlib import Path\n\n\ndef run_once","from contextlib import contextmanager\nfrom pathlib import Path\n\n\n@contextmanager\ndef _placeholder():\n    yield\n\n\ndef run_once")
open(p,'w',encoding='utf-8').write(s); print("OK")
PY
grep -n "_placeholder\|contextmanager" check_reproducibility.py | head

# --- 2026-09-14T01:10:56 · Restructure main around the temporary kernel
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs/src/ds06-notebooks-y-reproducibilidad
python3 - <<'PY'
p='check_reproducibility.py'; s=open(p,encoding='utf-8').read()
s=s.replace("import shutil\nimport tempfile\nimport time\nfrom pathlib import Path",
            "import shutil\nimport tempfile\nimport time\nfrom contextlib import contextmanager\nfrom pathlib import Path")
old="""    results = []
    for path in sorted(args.cuadernos.glob("*.ipynb")):
        started = time.perf_counter()
        ran, error, outputs = run_once(path)
        elapsed = (time.perf_counter() - started) * 1000

        stable = None
        if ran:
            # Segunda pasada: correr no es ser reproducible. Un cuaderno que da otro
            # número cada vez pasa la primera prueba y falla la que importa.
            _, _, again = run_once(path)"""
new="""    results = []
    # El kernel se registra una sola vez para toda la corrida: instalarlo por cuaderno
    # duplicaría el trabajo y mediría el registro en vez de la reejecución.
    with temporary_kernel() as kernels:
      for path in sorted(args.cuadernos.glob("*.ipynb")):
        started = time.perf_counter()
        ran, error, outputs = run_once(path, kernels)
        elapsed = (time.perf_counter() - started) * 1000

        stable = None
        if ran:
            # Segunda pasada: correr no es ser reproducible. Un cuaderno que da otro
            # número cada vez pasa la primera prueba y falla la que importa.
            _, _, again = run_once(path, kernels)"""
assert s.count(old)==1
s=s.replace(old,new)
# reindentar el resto del bucle
old2="""        results.append({"cuaderno": path.name, "corre": ran, "estable": stable,
                        "error": error, "ms": round(elapsed)})
        mark = "✅" if stable else ("🟡" if ran else "❌")
        detail = error if not ran else ("" if stable else "salidas distintas entre corridas")
        print(f"{mark} {path.name:<32}{elapsed:>7.0f} ms  {detail}")"""
new2="""        results.append({"cuaderno": path.name, "corre": ran, "estable": stable,
                        "error": error, "ms": round(elapsed)})
        mark = "✅" if stable else ("🟡" if ran else "❌")
        detail = error if not ran else ("" if stable else "salidas distintas entre corridas")
        print(f"{mark} {path.name:<32}{elapsed:>7.0f} ms  {detail}")"""
assert s.count(old2)==1
open(p,'w',encoding='utf-8').write(s)
PY
python3 - <<'PY'
# reindentación limpia del bloque del bucle
import re
p='check_reproducibility.py'; lines=open(p,encoding='utf-8').read().splitlines(keepends=True)
out=[]; inside=False
for line in lines:
    if line.startswith("      for path in sorted"):
        inside=True; out.append(line); continue
    if inside:
        if line.strip().startswith("total = len(results)"):
            inside=False
        elif line.strip():
            out.append("  "+line if line.startswith("        ") else line)
            continue
    out.append(line)
open(p,'w',encoding='utf-8').write("".join(out))
PY
python3 -c "import ast;ast.parse(open('check_reproducibility.py',encoding='utf-8').read());print('sintaxis OK')"
sed -n 86,120p check_reproducibility.py

# --- 2026-09-14T01:11:13 · Rewrite main cleanly and run the full measurement
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs/src/ds06-notebooks-y-reproducibilidad
python3 - <<'PY'
p='check_reproducibility.py'; s=open(p,encoding='utf-8').read()
start=s.index("def main() -> None:")
end=s.index('if __name__ == "__main__":')
new_main = '''def main() -> None:
    parser = argparse.ArgumentParser(description="¿Cuántos cuadernos sobreviven?")
    parser.add_argument("--cuadernos", type=Path, default=Path("cuadernos"))
    parser.add_argument("--json", type=Path, help="Guarda el detalle para la sección 6.")
    args = parser.parse_args()

    # El kernel se registra una sola vez para toda la corrida: instalarlo por cuaderno
    # duplicaría el trabajo y mediría el registro en vez de la reejecución.
    with temporary_kernel() as kernels:
        results = [check(path, kernels)
                   for path in sorted(args.cuadernos.glob("*.ipynb"))]

    total = len(results)
    ran = sum(result["corre"] for result in results)
    stable = sum(bool(result["estable"]) for result in results)
    print(f"\\n{ran} de {total} corren de arriba abajo en un kernel nuevo.")
    print(f"{stable} de {total} además dan el mismo resultado dos veces seguidas.")

    if args.json:
        args.json.write_text(json.dumps(results, indent=2, ensure_ascii=False) + "\\n",
                             encoding="utf-8")


def check(path: Path, kernels) -> dict:
    """Un cuaderno: se ejecuta, se informa, y si corrió se ejecuta otra vez."""
    started = time.perf_counter()
    ran, error, outputs = run_once(path, kernels)
    elapsed = (time.perf_counter() - started) * 1000

    stable = None
    if ran:
        # Segunda pasada: correr no es ser reproducible. Un cuaderno que da otro número
        # cada vez pasa la primera prueba y falla la que importa.
        _, _, again = run_once(path, kernels)
        stable = outputs == again

    mark = "✅" if stable else ("🟡" if ran else "❌")
    detail = error if not ran else ("" if stable else "salidas distintas entre corridas")
    print(f"{mark} {path.name:<32}{elapsed:>7.0f} ms  {detail}")
    return {"cuaderno": path.name, "corre": ran, "estable": stable,
            "error": error, "ms": round(elapsed)}


'''
open(p,'w',encoding='utf-8').write(s[:start]+new_main+s[end:]); print("OK")
PY
python3 -c "import ast;ast.parse(open('check_reproducibility.py',encoding='utf-8').read());print('sintaxis OK')"
time timeout 300 uv run --python 3.14 --with 'papermill==2.7.0' --with 'jupyterlab==4.6.3' python check_reproducibility.py --cuadernos cuadernos --json resultado.json 2>/dev/null | tail -12

# --- 2026-09-14T01:11:42 · Strip ANSI and test a marimo notebook as a script
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs/src/ds06-notebooks-y-reproducibilidad
python3 - <<'PY'
p='check_reproducibility.py'; s=open(p,encoding='utf-8').read()
s=s.replace("import argparse\nimport json\n","import argparse\nimport json\nimport re\n")
s=s.replace('''        except CellExecutionError as error:
            return False, str(error).splitlines()[-1][:90], []''',
'''        except CellExecutionError as error:
            # El traceback viene con códigos de color ANSI porque el kernel cree que habla
            # con una terminal. Sin quitarlos, el JSON de la medición queda ilegible.
            plain = ANSI.sub("", str(error).splitlines()[-1])
            return False, plain[:90], []''')
s=s.replace('EXTENSION = ', 'EXTENSION = ')
s=s.replace('from pathlib import Path\n\n\n@contextmanager',
            'from pathlib import Path\n\n# Los códigos de color que el kernel mete en el traceback.\nANSI = re.compile(r"\\x1b\\[[0-9;]*m")\n\n\n@contextmanager')
open(p,'w',encoding='utf-8').write(s); print("OK")
PY
cat > cuaderno_marimo.py <<'PY'
"""El mismo análisis en marimo. **Es un archivo `.py`**, y eso es la mitad del argumento.

    uv run --with marimo==0.24.2 python cuaderno_marimo.py     # corre como script
    uv run --with marimo==0.24.2 marimo edit cuaderno_marimo.py  # se edita como cuaderno

marimo no guarda salidas y no tiene `execution_count`: el orden lo decide el **grafo de
dependencias** entre celdas, no el orden en que alguien les dio a ejecutar. Por eso el
defecto de `estado-oculto.ipynb` no se puede escribir aquí — si una celda usa `adquiridos`,
marimo la ejecuta después de la que lo define, esté donde esté en el archivo.

Y por eso el diff de git es legible: es código Python, no un JSON con imágenes en base64.
"""

import marimo

app = marimo.App()


@app.cell
def _():
    gasto = {"tiktok": 2020, "instagram": 2020, "google": 2020}
    return (gasto,)


@app.cell
def _(gasto, adquiridos):
    # Esta celda está ANTES de la que define `adquiridos` y funciona igual: marimo resuelve
    # el orden por dependencias. En Jupyter, esto mismo es el bug de `estado-oculto.ipynb`.
    costos = {canal: gasto[canal] * 1e6 / adquiridos[canal] for canal in gasto}
    print(sorted(costos, key=costos.get))
    return (costos,)


@app.cell
def _():
    adquiridos = {"tiktok": 182, "instagram": 529, "google": 1275}
    return (adquiridos,)


if __name__ == "__main__":
    app.run()
PY
timeout 200 uv run --python 3.14 --with 'marimo==0.24.2' python cuaderno_marimo.py 2>&1 | tail -5

# --- 2026-09-14T01:12:29 · Run the ds06 test suite
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs/src/ds06-notebooks-y-reproducibilidad
timeout 400 uv run --python 3.14 --with pytest --with 'papermill==2.7.0' --with 'jupyterlab==4.6.3' --with 'marimo==0.24.2' python -m pytest -q 2>&1 | tail -15

# --- 2026-09-14T01:13:00 · Find where the kernelspec actually comes from
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs/src/ds06-notebooks-y-reproducibilidad
echo "=== ¿de dónde sale el kernelspec? ==="
timeout 120 uv run --python 3.14 --with 'papermill==2.7.0' --with 'jupyterlab==4.6.3' python -c "
from jupyter_client.kernelspec import KernelSpecManager
import sys
ks = KernelSpecManager()
print('dirs:', ks.kernel_dirs)
print('encontrados:', list(ks.find_kernel_specs()))
print('sys.prefix:', sys.prefix)"
echo "=== solo papermill + ipykernel (sin jupyterlab) ==="
timeout 120 uv run --python 3.14 --with 'papermill==2.7.0' --with ipykernel python -c "
from jupyter_client.kernelspec import KernelSpecManager
print('encontrados:', list(KernelSpecManager().find_kernel_specs()))"

# --- 2026-09-14T01:13:37 · Remove the patched file before rewriting
head -3 check_reproducibility.py && rm check_reproducibility.py && echo "eliminado para reescribir"

# --- 2026-09-14T01:14:14 · Simplify the kernel fixture and re-run everything
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs/src/ds06-notebooks-y-reproducibilidad
python3 - <<'PY'
p='test_cuadernos.py'; s=open(p,encoding='utf-8').read()
s=s.replace('''@pytest.fixture(scope="module")
def kernels():
    pytest.importorskip("ipykernel")
    pytest.importorskip("nbclient")
    from check_reproducibility import temporary_kernel

    with temporary_kernel() as manager:
        yield manager


''','''@pytest.fixture(scope="module", autouse=False)
def kernel():
    """Se salta el módulo entero si no hay kernel. No lo instala: lo comprueba."""
    pytest.importorskip("ipykernel")
    pytest.importorskip("nbclient")
    from check_reproducibility import require_kernel

    require_kernel()


''')
s=s.replace("def test_el_cuaderno_limpio_corre_y_es_estable(notebooks: Path, kernels):","def test_el_cuaderno_limpio_corre_y_es_estable(notebooks: Path, kernel):")
s=s.replace("def test_cada_defecto_falla_como_dice_la_seccion(notebooks: Path, kernels, name, expected):","def test_cada_defecto_falla_como_dice_la_seccion(notebooks: Path, kernel, name, expected):")
s=s.replace("def test_el_error_no_trae_codigos_de_color(notebooks: Path, kernels):","def test_el_error_no_trae_codigos_de_color(notebooks: Path, kernel):")
s=s.replace("def test_correr_no_es_ser_reproducible(notebooks: Path, kernels):","def test_correr_no_es_ser_reproducible(notebooks: Path, kernel):")
s=s.replace("run_once(notebooks / \"limpio.ipynb\", kernels)","run_once(notebooks / \"limpio.ipynb\")")
s=s.replace("run_once(notebooks / name, kernels)","run_once(notebooks / name)")
s=s.replace("run_once(notebooks / \"estado-oculto.ipynb\", kernels)","run_once(notebooks / \"estado-oculto.ipynb\")")
s=s.replace("run_once(notebooks / \"azar-sin-semilla.ipynb\", kernels)","run_once(notebooks / \"azar-sin-semilla.ipynb\")")
# la prueba de marimo era ingenua: el docstring del propio archivo menciona execution_count
s=s.replace('''    source = (HERE / "cuaderno_marimo.py").read_text(encoding="utf-8")
    assert "@app.cell" in source
    assert "execution_count" not in source
    assert "base64" not in source''',
'''    source = (HERE / "cuaderno_marimo.py").read_text(encoding="utf-8")
    assert "@app.cell" in source
    # Lo que no puede haber es el **campo** de un `.ipynb`, no la palabra: el docstring de
    # ese archivo explica justamente que no lo tiene. La primera versión de esta prueba
    # buscaba la palabra suelta y fallaba contra su propia explicación.
    assert '"execution_count"' not in source
    assert "image/png" not in source''')
open(p,'w',encoding='utf-8').write(s); print("OK")
PY
timeout 400 uv run --python 3.14 --with pytest --with 'papermill==2.7.0' --with 'jupyterlab==4.6.3' --with 'marimo==0.24.2' python -m pytest -q -p no:warnings 2>&1 | tail -5
echo "=== la medición, final ==="
timeout 300 uv run --python 3.14 --with 'papermill==2.7.0' --with 'jupyterlab==4.6.3' python check_reproducibility.py --cuadernos cuadernos --json resultado.json 2>/dev/null | tail -10

# --- 2026-09-14T01:21:46 · Write both src READMEs
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs/src
cat > ds05-visualizacion/README.md <<'EOF'
# `ds05` · Visualización, y cuándo una tabla gana

Código de la sección [`ds05-visualizacion.md`](../../ds05-visualizacion.md).

| Archivo | Qué es |
|---|---|
| `dashboard.py` | El mismo tablero en cuatro versiones: tabla, matplotlib, plotly y altair |
| `palette.py` | La paleta de Áurea, su contraste y qué queda de ella impresa |
| `bench_render.py` | La medición de la sección 6.1, una opción por entorno |
| `test_dashboard.py` | 15 pruebas: `pytest test_dashboard.py` |

## Correr las cosas

```bash
python dashboard.py                                   # la tabla, sin dependencias
uv run --with matplotlib==3.11.2 python bench_render.py --opcion matplotlib
uv run --with plotly==7.0.0     python bench_render.py --opcion plotly
uv run --with altair==6.2.2     python bench_render.py --opcion altair
uv run python bench_render.py --opcion tabla
```

**Cada opción se mide en un entorno donde solo está instalada su dependencia**, por lo que
descubrió `ds03`: una biblioteca puede importar otra si la encuentra, y entonces la tabla le
cobra a una el arranque de la otra.

## Las pruebas de la paleta no necesitan ninguna biblioteca de gráficos

El contraste es aritmética: luminancia relativa y un cociente. Por eso `palette.py` no
importa nada y sus pruebas corren en cualquier máquina, incluida una de CI sin con qué
dibujar. Las tres pruebas de renderizado se saltan solas con `importorskip`.

## Los dos hallazgos que este código deja fijados

1. **El dorado de la marca no pasa el contraste para texto** —3,25 contra el 4,5 de la
   norma— **y sí para una barra** (3:1). No se prohíbe el color: se le asigna el papel donde
   funciona, y eso termina la discusión con un número en vez de con un gusto.
2. **La paleta completa no sobrevive a una impresión en blanco y negro.** Teja `#A34E2A` y
   pizarra `#4A6670` son dos colores obviamente distintos en pantalla y el mismo gris en el
   papel: `#666666` y `#626262`, con 1,04 de contraste entre sí.

## ⚠️ Dos trampas de API que el código evita a propósito

- **`matplotlib.use("Agg")` antes de importar `pyplot`.** Sin eso, falla en cualquier máquina
  sin pantalla —todas las que corren tareas programadas— con un error que no menciona la
  palabra "pantalla".
- **`xerr` son distancias al punto, no los extremos.** Pasarle los extremos produce un
  gráfico que se dibuja sin quejarse y está mal.

Los archivos generados no se versionan.
EOF
cat > ds06-notebooks-y-reproducibilidad/README.md <<'EOF'
# `ds06` · Cuadernos y reproducibilidad

Código de la sección [`ds06-notebooks-y-reproducibilidad.md`](../../ds06-notebooks-y-reproducibilidad.md).

| Archivo | Qué es |
|---|---|
| `generar_cuadernos.py` | Los seis cuadernos del Embudo, cinco con su defecto sembrado |
| `check_reproducibility.py` | La medición: ejecutar cada uno en un kernel nuevo, dos veces |
| `cuaderno_marimo.py` | El mismo análisis en marimo. **Es un `.py`**, y eso es media tesis |
| `test_cuadernos.py` | 15 pruebas: `pytest -q` |

## Correr las cosas

```bash
python generar_cuadernos.py --salida cuadernos
uv run --with papermill==2.7.0 --with jupyterlab==4.6.3 \
       python check_reproducibility.py --cuadernos cuadernos --json resultado.json
uv run --with marimo==0.24.2 python cuaderno_marimo.py
```

La auditoría completa —ocho ejecuciones sobre seis cuadernos— tarda **siete segundos**.

## El kernel lo instala `ipykernel`, no papermill

Con papermill y nada más, esto falla con `NoSuchKernel: No such kernel named python3` y
quince líneas de traceback de `jupyter_client` que no dicen qué falta. Lo que registra el
kernel es `ipykernel`, que deja su especificación en `sys.prefix/share/jupyter/kernels/` al
instalarse. `require_kernel()` comprueba eso al arrancar y dice qué agregar.

## Qué mide, y por qué son dos columnas

Cada cuaderno se ejecuta **en un kernel nuevo, desde un directorio temporal vacío y de arriba
abajo**. Las tres condiciones son las que no se cumplen cuando alguien "lo corre otra vez" en
su propia máquina.

Y los que corren se ejecutan **dos veces**, porque **correr no es ser reproducible**:
`azar-sin-semilla.ipynb` pasa la primera prueba y falla la que importa. Es el defecto más
difícil de ver porque no produce ningún error.

**Resultado: 2 de 6 corren, 1 de 6 es estable** — y ese uno es el cuaderno de control, escrito
correcto a propósito.

## marimo resuelve uno de los cinco defectos

En `cuaderno_marimo.py`, la celda que usa `adquiridos` está **antes** que la que lo define, y
corre igual: el orden lo decide el grafo de dependencias. En Jupyter eso mismo es el bug de
`estado-oculto.ipynb`.

Lo que marimo **no** resuelve, y conviene decirlo en la misma frase: la ruta absoluta, la
dependencia no declarada y el azar sin semilla rompen igual.

Los cuadernos generados no se versionan.
EOF
echo OK

# --- 2026-09-14T01:22:33 · Add ds05 and ds06 to BENCHMARKS, INSTINTOS and the state docs
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs
python3 - <<'PY'
def sub(path, pairs):
    s=open(path,encoding='utf-8').read()
    for old,new in pairs:
        if s.count(old)!=1: raise SystemExit(f"{path}: {s.count(old)} de {old[:60]!r}")
        s=s.replace(old,new)
    open(path,'w',encoding='utf-8').write(s); print("OK", path)

sub('BENCHMARKS.md', [("""---

## ✍️ Cómo se agregan entradas""", """### ds05 · Cuatro formas del mismo tablero

**Afirmaba:** que las tres bibliotecas de gráficos cuestan bastante más que una tabla de texto
en las cuatro dimensiones que importan, y que la diferencia entre ellas es menor que la
diferencia con no usar ninguna.

**Condiciones:** matplotlib 3.11.2, plotly 7.0.0, altair 6.2.2. El mismo tablero —tres canales
con la banda de `ds04`—. Cinco repeticiones con la biblioteca cargada; cinco procesos nuevos
para el tiempo en frío. **Cada opción en un entorno donde solo está su dependencia.**

| Opción | Render | En frío | Pico RSS | Artefacto | Líneas |
|---|---|---|---|---|---|
| **tabla de texto** | **0,07 ms** | **30 ms** | **23 MB** | **0,35 KB** | **6** |
| altair | 9,7 ms | 275 ms | 108 MB | 2,3 KB | 13 |
| plotly | 14,6 ms | 193 ms | 111 MB | 9,4 KB | 15 |
| matplotlib | 57,5 ms | 457 ms | 113 MB | 29,3 KB | 18 |

⚖️ **Para las siete cifras del comité de franquicia, gana la tabla** — y no por los 30 ms, que
a nadie le importan, sino porque **cabe la columna de la banda**, se pega en un correo y se
compara con la del mes pasado con un `diff`. Entre las tres bibliotecas la elección es por
destino: matplotlib es la única que se ve sin navegador y cuesta el doble en frío que plotly;
altair da el archivo más chico y la especificación más revisable. **El umbral:** la tabla gana
mientras el dato quepa en una pantalla y lo que importe sean los valores; en cuanto la pregunta
sea *"¿sube o baja?"* sobre veintisiete meses, pierde y no está cerca.

**Dos números al margen que deciden más que la tabla:** el HTML de plotly pesa 9,4 KB con el
JavaScript traído de un CDN y **4,10 MB** con él embebido —435×, por un argumento— y el dorado
de la marca de Áurea da **3,25** de contraste: no sirve para texto (4,5 exige la norma) y sí
para una barra (3,0). Y la paleta completa **no sobrevive a una impresión en gris**: teja y
pizarra quedan a 1,04 de contraste entre sí.

⏳ **Pendiente, y es la que de verdad importa:** *tiempo hasta la primera decisión correcta* con
cinco personas sobre las tres presentaciones. El protocolo está completo en `ds05` §6.2; lo que
falta son cinco voluntarios. Es la única medición del track que no se puede hacer con un portátil.

→ [`ds05-visualizacion.md`](ds05-visualizacion.md) §6

### ds06 · Cuántos cuadernos vuelven a correr

**Afirmaba:** que de una carpeta de cuadernos escritos con normalidad la mayoría no reejecuta, y
que el subconjunto que además da el mismo resultado dos veces es todavía menor.

**Condiciones:** `nbclient` 0.11.0 vía papermill 2.7.0 y jupyterlab 4.6.3. Seis cuadernos del
análisis del Embudo —uno limpio y cinco con un defecto sembrado, todos guardados **con sus
salidas**—. Cada uno en un **kernel nuevo**, desde un **directorio temporal vacío**, de la
primera celda a la última. Los que corren se ejecutan **una segunda vez** y se comparan las
salidas.

| Cuaderno | Corre | Estable | Qué pasó |
|---|---|---|---|
| `limpio.ipynb` | ✅ | ✅ | — |
| `azar-sin-semilla.ipynb` | ✅ | ❌ | salidas distintas entre corridas |
| `estado-oculto.ipynb` | ❌ | — | `NameError` (contadores 1, 3, 2) |
| `celda-borrada.ipynb` | ❌ | — | `NameError`: la celda que la definía ya no está |
| `ruta-absoluta.ipynb` | ❌ | — | `FileNotFoundError` |
| `dependencia-no-declarada.ipynb` | ❌ | — | `ModuleNotFoundError` |

⚖️ **2 de 6 corren; 1 de 6 es estable**, y ese uno es el cuaderno de control escrito correcto a
propósito. La auditoría completa —ocho ejecuciones— tarda **siete segundos**. Esa desproporción
—siete segundos contra meses de cuadernos que nadie sabe si sirven— es el resultado. **Solo uno
de los cinco defectos es propio del formato** (el estado oculto, que marimo elimina por diseño);
la ruta absoluta y la dependencia no declarada rompen un `.py` exactamente igual.

📝 **No es una estadística del mundo:** son seis cuadernos generados con defectos puestos a
propósito. Lo que demuestra es que cada defecto se detecta y lo barato que es detectarlo. El
número sobre un repositorio real es el ejercicio 22 y está pendiente.

→ [`ds06-notebooks-y-reproducibilidad.md`](ds06-notebooks-y-reproducibilidad.md) §6

---

## ✍️ Cómo se agregan entradas""")])

sub('INSTINTOS.md', [("""---

## 🧪 Los reflejos de método""", """### 31. "La presentación es la capa final"

Once años de backend dejan el gráfico del lado de alguien más, al final del proceso y sin
consecuencias. Aquí la presentación es **donde se pierde la información**: todo el trabajo de
`ds04` —cuatro modelos, intervalos, madurez— cabe en una tabla de texto y **no cabe en un
gráfico de barras**. Elegir la barra simple no es una decisión estética: es tirar el hallazgo.

Y el corolario que cuesta aceptar: para las siete cifras del comité de Áurea, **la tabla gana**,
y gana porque cabe la columna de la banda, se pega en un correo y se compara con un `diff`. El
reflejo corregido es preguntar *"¿esto es para decidir, para ver una forma o para explorar?"*
antes de abrir cualquier biblioteca. *(`ds05`)*

### 32. "Los cuadernos son un desastre"

Este reflejo es **medio correcto**, y la mitad exacta se puede medir. De seis cuadernos del
análisis del Embudo, **dos corren de arriba abajo en un kernel nuevo y uno solo da el mismo
resultado dos veces**. Tienes razón en que un cuaderno no es un entregable.

Donde el reflejo falla es en la conclusión de no usarlos. **Cuatro de los cinco defectos no son
del formato** —una ruta absoluta y una dependencia no declarada rompen un `.py` igual—, y a
cambio estás dejando sobre la mesa lo único que un cuaderno hace mejor: cargar el dato una vez y
hacerle cuarenta preguntas. La regla que sale: **el cuaderno es para pensar, el módulo es para
entregar**, y la prueba que separa los dos cuesta siete segundos. *(`ds06`)*

---

## 🧪 Los reflejos de método""")])

sub('prompts/README.md', [
("| **T10** | `ds05` + `ds06` | `ds06` mide los cuadernos que producen `ds04` y `ds05`. Cierran el bloque Embudo |",
 "| **T10** ✅ | `ds05` + `ds06`, cerradas el 13/09/2026: la medición de render en cuatro opciones, la de contraste de la paleta, la auditoría de cuadernos y 30 pruebas | `ds06` mide los cuadernos que producen `ds04` y `ds05`. Cierran el bloque Embudo |"),
("""> los dos conjuntos de datos; **T7**, `ds01` y `ds02`; **T8**, `ds03`; y **T9**, `ds04`. Las
> cinco mediciones del track están **ejecutadas**, no en `⏳`. La siguiente es **T10**
> (`ds05` + `ds06`).""",
 """> los dos conjuntos de datos; **T7**, `ds01` y `ds02`; **T8**, `ds03`; **T9**, `ds04`; y
> **T10**, `ds05` y `ds06`. Seis secciones publicadas y **el bloque del Embudo cerrado**. De las
> siete mediciones, seis están **ejecutadas** y una en `⏳` —la de `ds05` §6.2, que necesita
> cinco personas—. La siguiente es **T11** (`ds07`)."""),
])

sub('prompts/prompts-de-tracks-ia-ds.md', [
("| `ds05-visualizacion.md` | Visualización | Embudo | Tiempo hasta la primera decisión correcta |",
 "| `ds05-visualizacion.md` ✅ | Visualización | Embudo | Tiempo hasta la primera decisión correcta — **⏳, necesita personas**; sí se ejecutó la de render y contraste |"),
("| `ds06-notebooks-y-reproducibilidad.md` | Cuadernos y reproducibilidad | Embudo | Reejecución limpia: cuántos cuadernos sobreviven |",
 "| `ds06-notebooks-y-reproducibilidad.md` ✅ | Cuadernos y reproducibilidad | Embudo | Reejecución limpia: cuántos cuadernos sobreviven — **ejecutada: 2 de 6** |"),
("""> 🚧 **El track `ds` va por `ds04`.** T6 dejó los dos conjuntos de datos; T7 escribió `ds01` y
> `ds02`; T8, `ds03`; T9, `ds04`. **Las cinco mediciones están ejecutadas**""",
 """> 🚧 **El track `ds` va por `ds06`, y el bloque del Embudo está cerrado.** T6 dejó los dos
> conjuntos de datos; T7 escribió `ds01` y `ds02`; T8, `ds03`; T9, `ds04`; T10, `ds05` y `ds06`.
> **Seis de las siete mediciones están ejecutadas**"""),
])
PY

# --- 2026-09-14T01:22:42 · Verify state text and lint the whole track
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs
grep -n "⏳ **El track" prompts/prompts-de-tracks-ia-ds.md | head -2
sed -n '/El track `ds` va por `ds06`/,+8p' prompts/prompts-de-tracks-ia-ds.md
rm -rf src/ds0*/data src/ds0*/salida src/ds0*/cuadernos src/ds0*/resultado.json src/ds0*/__pycache__ src/ds0*/.pytest_cache .pytest_cache 2>/dev/null
echo "=== lint + pruebas de todo el track ==="
for d in src/ds01-numpy-y-el-modelo-vectorizado src/ds02-pandas src/ds03-polars-y-el-modelo-lazy src/ds04-embudo src/ds05-visualizacion src/ds06-notebooks-y-reproducibilidad src/ds07-scikit-learn; do
  printf "  %-48s" "$(basename $d)"
  (cd $d && uvx ruff@0.16.7 check . >/dev/null 2>&1 && printf "lint OK · " || printf "LINT FALLA · ")
done; echo

# --- 2026-09-14T01:22:51 · See the actual lint failure
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs/src/ds02-pandas
uvx ruff@0.16.7 check . 2>&1 | head -20

# --- 2026-09-14T01:23:09 · Try a glob in the ruff src setting
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs
python3 - <<'PY'
p='ruff.toml'; s=open(p,encoding='utf-8').read()
s=s.replace('target-version = "py314"','''# Cada carpeta de `src/` es un proyecto independiente: sus módulos se importan por nombre
# desde su propio directorio, como los ejecuta el lector. Sin esta lista, `ruff` los trata
# como dependencias de terceros y reordena los imports al revés.
src = ["src/*"]

target-version = "py314"''')
open(p,'w',encoding='utf-8').write(s)
PY
cd src/ds02-pandas && uvx ruff@0.16.7 check . 2>&1 | tail -3

# --- 2026-09-14T01:23:17 · Verify linting from both working directories
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs
echo "=== desde la raíz del curso ==="; uvx ruff@0.16.7 check src/ds0* 2>&1 | tail -3
echo "=== desde dentro de cada sección ==="
for d in src/ds0*/; do printf "  %-48s" "$(basename $d)"; (cd $d && uvx ruff@0.16.7 check . >/dev/null 2>&1 && echo "lint OK" || echo "LINT FALLA"); done

# --- 2026-09-14T01:23:24 · List the ds05 and ds06 lint errors
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs
uvx ruff@0.16.7 check src/ds05-visualizacion src/ds06-notebooks-y-reproducibilidad --output-format concise

# --- 2026-09-14T01:23:43 · Exclude generated dirs and reconcile lint
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs
python3 - <<'PY'
p='ruff.toml'; s=open(p,encoding='utf-8').read()
s=s.replace('src = ["src/*"]','''src = ["src/*"]

# Lo que generan los scripts del curso no se revisa ni se versiona. Los cuadernos de `ds06`
# son el caso divertido: `ruff` les encuentra los defectos sembrados —`F821 Undefined name
# 'adquiridos'`— y tiene toda la razón, pero son la entrada de una medición, no código.
exclude = ["**/data", "**/salida", "**/cuadernos", "**/parquet"]''')
open(p,'w',encoding='utf-8').write(s); print("OK")
PY
uvx ruff@0.16.7 check --fix src/ds0* >/dev/null 2>&1
echo "=== desde la raíz ==="; uvx ruff@0.16.7 check src/ds0* && echo "  OK"
echo "=== desde dentro ==="
for d in src/ds0*/; do printf "  %-48s" "$(basename $d)"; (cd $d && uvx ruff@0.16.7 check . >/dev/null 2>&1 && echo "lint OK" || echo "LINT FALLA"); done

# --- 2026-09-14T01:24:12 · Add the ruff finding and fix the state text
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs
python3 - <<'PY'
def sub(path, pairs):
    s=open(path,encoding='utf-8').read()
    for old,new in pairs:
        if s.count(old)!=1: raise SystemExit(f"{path}: {s.count(old)} de {old[:70]!r}")
        s=s.replace(old,new)
    open(path,'w',encoding='utf-8').write(s); print("OK", path)

# el hallazgo de ruff sobre los cuadernos
sub('ds06-notebooks-y-reproducibilidad.md', [
("""**El patrón a memorizar**
> El cuaderno es para pensar; el módulo es para entregar.""",
""">💡 **Y un atajo que apareció al escribir la sección: `ruff` ya lee cuadernos.** Al aplicarle
> la configuración del curso a la carpeta generada, encuentra **sin ejecutar nada** dos de los
> cinco defectos:
>
> ```
> cuadernos/estado-oculto.ipynb:cell 2:1:31: F821 Undefined name `adquiridos`
> cuadernos/celda-borrada.ipynb:cell 1:1:13: F821 Undefined name `leads`
> ```
>
> Es exactamente lo que el ejercicio 7 pide construir con `ast`, ya hecho y en milisegundos.
> **Lo que no hace** —y por eso la medición sigue valiendo— es detectar la ruta absoluta como
> problema, la dependencia que no está instalada, ni el azar sin semilla; y un `F821` puede ser
> un falso positivo legítimo cuando una celda define nombres dinámicamente. El auditor del
> miniproyecto se apoya en `ruff` para lo que `ruff` hace bien, y no lo reimplementa.

**El patrón a memorizar**
> El cuaderno es para pensar; el módulo es para entregar."""),
("""7. Escribe la detección de estado oculto **sin ejecutar nada**, con `ast`: los nombres que
   cada celda define y los que usa, en orden de archivo. Es el ejercicio más útil de la lista.""",
 """7. Escribe la detección de estado oculto **sin ejecutar nada**, con `ast`: los nombres que
   cada celda define y los que usa, en orden de archivo. Después compara tu resultado con el
   `F821` que `ruff` ya reporta sobre los mismos cuadernos, y encuentra un caso donde tu
   versión acierte y la suya no —o al revés—. Es el ejercicio más útil de la lista."""),
("""- **La detección de estado oculto sin ejecutar** (ejercicio 7) es lo bastante valiosa como
  para estar en el cuerpo. Se dejó fuera porque `ast` para analizar alcance da para una
  sección propia; si el miniproyecto de alguien la resuelve bien, considerar promoverla.""",
 """- 🪦 **La detección de estado oculto sin ejecutar ya la hace `ruff`**, con `F821`, y se
  descubrió al linterar la carpeta generada. Está en la sección 5.4 como 💡 y cambió el
  ejercicio 7, que ahora pide comparar la versión propia con la de la herramienta en vez de
  escribirla a ciegas. Lo que sigue abierto es cuánto de los otros cuatro defectos se puede
  detectar estáticamente."""),
])

# el estado de prompts, que quedó contradiciéndose
sub('prompts/prompts-de-tracks-ia-ds.md', [
("""> **Seis de las siete mediciones están ejecutadas** —no cuestan dinero ni API, así
> que aquí no hay `⏳`— y sus entradas están en `BENCHMARKS.md`. La de `ds03` son **dos tablas con
> ganadores distintos**: la consulta con el motor caliente y el informe de punta a punta. La de
> `ds04` no mide tiempo: mide **cuánto cambia la respuesta al negocio** según el modelo de
> atribución, y da 7,5×. Siguiente: T10, `ds05` y `ds06`.""",
 """> **Seis de las siete mediciones están ejecutadas** —no cuestan dinero ni API— y sus entradas
> están en `BENCHMARKS.md`. La de `ds03` son **dos tablas con ganadores distintos**: la consulta
> con el motor caliente y el informe de punta a punta. La de `ds04` no mide tiempo: mide **cuánto
> cambia la respuesta al negocio** según el modelo de atribución, y da 7,5×. **La única en `⏳`
> del track es la §6.2 de `ds05`**, que necesita cinco personas y no un portátil. Siguiente:
> T11, `ds07`."""),
])
PY

# --- 2026-09-14T01:24:23 · Full test sweep of the ds track
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs
echo "=== pruebas de todo el track ds ==="
for d in src/ds01-numpy-y-el-modelo-vectorizado src/ds02-pandas src/ds03-polars-y-el-modelo-lazy src/ds04-embudo src/ds07-scikit-learn; do
  printf "  %-40s" "$(basename $d)"; (cd $d && uv run --python 3.14 --with pytest --with 'numpy==2.5.3' --with 'pandas==3.0.5' --with 'polars==1.44.2' --with 'duckdb==1.5.5' python -m pytest -q 2>&1|tail -1); done
printf "  %-40s" "ds05-visualizacion"; (cd src/ds05-visualizacion && uv run --python 3.14 --with pytest --with 'matplotlib==3.11.2' --with 'plotly==7.0.0' --with 'altair==6.2.2' python -m pytest -q 2>&1|tail -1)
printf "  %-40s" "ds06-notebooks"; (cd src/ds06-notebooks-y-reproducibilidad && timeout 400 uv run --python 3.14 --with pytest --with 'papermill==2.7.0' --with 'jupyterlab==4.6.3' --with 'marimo==0.24.2' python -m pytest -q -p no:warnings 2>&1|tail -1)

# --- 2026-09-14T01:25:23 · Clean up, verify links and update memory
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs
rm -rf src/ds0*/data src/ds0*/salida src/ds0*/cuadernos src/ds0*/resultado.json src/ds0*/__pycache__ src/ds0*/.pytest_cache .pytest_cache 2>/dev/null
python3 - <<'PY'
import re,os
bad=[]
for root,d,fs in os.walk('.'):
    if 'pytest_cache' in root: continue
    for f in fs:
        if not f.endswith('.md'): continue
        p=os.path.join(root,f)
        for i,l in enumerate(open(p,encoding='utf-8'),1):
            for m in re.finditer(r'\]\((?!https?:)([^)#]+\.md)(?:#[^)]*)?\)',l):
                t=m.group(1)
                if not os.path.exists(os.path.normpath(os.path.join(root,t))): bad.append(f"{p}:{i} -> {t}")
print("links rotos:", "\n".join(bad) or "ninguno")
PY
wc -l ds0*.md | tail -8
cd /Users/oskar/.claude/projects/-Users-oskar-Developer-Learning-courses-ia-generated/memory
python3 - <<'PY'
p='python-java-devs-estado.md'; s=open(p,encoding='utf-8').read()
old="**Lo siguiente es T10 (`ds05` + `ds06`).**"
new="""**T10 cerrada el 13/09/2026 y con ella el bloque del Embudo**: `ds05-visualizacion.md` (750
líneas) y `ds06-notebooks-y-reproducibilidad.md` (511), con 30 pruebas. `ds05` mide render, frío,
memoria, peso del artefacto y líneas en cuatro opciones y **la tabla de texto gana** para las
siete cifras del comité —no por los 30 ms, sino porque cabe la columna de la banda de `ds04`—;
la paleta de Áurea se valida por contraste (el dorado da 3,25: no sirve para texto y sí para
barra) y **no sobrevive a una impresión en gris**. Su §6.2 —tiempo hasta la primera decisión
correcta, con cinco personas— es **la única `⏳` del track** y queda con protocolo completo.
`ds06` ejecuta seis cuadernos en kernels nuevos: **2 de 6 corren y 1 de 6 es estable**, en siete
segundos; el prejuicio del lector es medio correcto y solo uno de los cinco defectos es propio
del formato.

**`ruff.toml` ya vive en la raíz del curso** con la selección que documenta la Fase 00
(`E,F,I,UP,B`, línea 100), más `src = ["src/*"]` —cada carpeta de `src/` es un proyecto
independiente— y `exclude` de lo generado. Con él aparecieron **14 avisos en material publicado
de `ia03`–`ia08` y la Fase 13**, anotados como deuda en `prompts/README.md`: no se corrigieron
porque varias de esas líneas están transcritas en capítulos cerrados y merecen una tanda de
limpieza propia.

Dos defectos propios de T10: `zip(grays, grays[1:], strict=True)` reventaba en
`distinguishable_in_print` —`strict` es para secuencias del mismo largo, y un recorrido por pares
nunca lo es; se usa `itertools.pairwise`—, y un `temporary_kernel` de treinta líneas que instalaba
un kernelspec temporal con una explicación convincente y **falsa**: `nbclient` ignoraba el
argumento y el kernel venía de `ipykernel` desde el principio.

**Lo siguiente es T11 (`ds07`).**"""
assert s.count(old)==1
open(p,'w',encoding='utf-8').write(s.replace(old,new)); print("OK memoria")
PY

# --- 2026-09-14T01:25:31 · Correct line counts in memory
cd /Users/oskar/.claude/projects/-Users-oskar-Developer-Learning-courses-ia-generated/memory
sed -i '' 's/`ds05-visualizacion.md` (750\nlíneas)/X/' python-java-devs-estado.md
python3 - <<'PY'
p='python-java-devs-estado.md'; s=open(p,encoding='utf-8').read()
s=s.replace("`ds05-visualizacion.md` (750\nlíneas) y `ds06-notebooks-y-reproducibilidad.md` (511)",
            "`ds05-visualizacion.md` (660\nlíneas) y `ds06-notebooks-y-reproducibilidad.md` (598)")
open(p,'w',encoding='utf-8').write(s); print("OK")
PY
grep -c "660" python-java-devs-estado.md

# --- 2026-09-14T01:36:48 · Re-verify the lint debt list and check scikit-learn
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs
echo "=== ¿sigue en pie la lista de deuda de lint? ==="
uvx ruff@0.16.7 check src/ --output-format concise 2>&1 | grep -v "^src/ds" | tail -20
echo "=== sklearn ==="
cd /tmp && uv run --python 3.14 --with 'scikit-learn==1.9.1' --with 'numpy==2.5.3' python -c "
import sklearn, numpy; print('scikit-learn', sklearn.__version__, '· numpy', numpy.__version__)" 2>&1|tail -2

# --- 2026-09-14T01:37:35 · Update the lint debt table to 17
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs
python3 - <<'PY'
def sub(path, pairs):
    s=open(path,encoding='utf-8').read()
    for old,new in pairs:
        if s.count(old)!=1: raise SystemExit(f"{path}: {s.count(old)} de {old[:60]!r}")
        s=s.replace(old,new)
    open(path,'w',encoding='utf-8').write(s); print("OK", path)

sub('prompts/README.md', [
("""`ruff.toml` vive en la raíz del curso desde el 13/09/2026, con la misma selección que imprime
la Fase 00 (`E, F, I, UP, B`, línea de 100). Al aplicarlo sobre `src/` aparecen **14 avisos en
código ya publicado**, ninguno de los cuales rompe en ejecución:

| Dónde | Qué |
|---|---|
| `13-integraciones/socio_falible.py` | dos `E702`: tres sentencias separadas por punto y coma |
| `ia04/generar_corpus.py` · `ia05/bench_answers.py` · `ia05/test_normarag.py` · `ia06/generar_evalset.py` | seis `E501`: líneas de 101 a 111 columnas |
| `ia05/bench_answers.py` · `ia05/test_normarag.py` | dos `F401`: imports sin usar |
| `ia06/bench_judges.py` · `ia06/statistics_helpers.py` | dos `B905`: `zip()` sin `strict=` |
| `ia03/agent_runner.py` | `F821` sobre `agenda`, que es una inyección de módulo declarada y deliberada |
| `ia08/test_produccion.py` | `UP037` + `F821`: una anotación entrecomillada cuyo tipo se importa dentro de la función |""",
 """`ruff.toml` vive en la raíz del curso desde el 13/09/2026, con la misma selección que imprime
la Fase 00 (`E, F, I, UP, B`, línea de 100), más `src = ["src/*"]` —cada carpeta de `src/` es un
proyecto independiente y sus módulos vecinos son de primera parte— y un `exclude` de lo que
generan los scripts. Al aplicarlo sobre `src/` aparecen **17 avisos en código ya publicado**,
ninguno de los cuales rompe en ejecución:

| Dónde | Qué |
|---|---|
| `13-integraciones/socio_falible.py` | dos `E702`: tres sentencias separadas por punto y coma |
| `ia04/generar_corpus.py` · `ia05/bench_answers.py` · `ia05/test_normarag.py` · `ia06/generar_evalset.py` | seis `E501`: líneas de 101 a 111 columnas |
| `ia04/db.py` · `ia05/bench_answers.py` | dos `I001`: bloques de import sin ordenar |
| `ia05/bench_answers.py` · `ia05/test_normarag.py` | dos `F401`: imports sin usar |
| `ia06/bench_judges.py` · `ia06/statistics_helpers.py` | dos `B905`: `zip()` sin `strict=` |
| `ia03/agent_runner.py` | `F821` sobre `agenda`, que es una inyección de módulo declarada y deliberada |
| `ia08/test_produccion.py` | `UP037` + `F821`: una anotación entrecomillada cuyo tipo se importa dentro de la función |"""),
])
PY

# --- 2026-09-14T01:39:09 · First run of the baseline versus model comparison
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs/src/ds07-scikit-learn
mkdir -p data && python3 generar_ausentismo.py --salida data >/dev/null
uv run --python 3.14 --with 'scikit-learn==1.9.1' python - <<'PY'
from pathlib import Path
from features import *
from baseline import *
from model import *
d=Path("data"); rows=load_rows(d); cut=cutoff_of(d)
train, test = split_temporal(rows, cut)
print(f"corte {cut} · entrenamiento {len(train):,} · prueba {len(test):,} ({len(test)/len(rows):.0%})")
_, y = build_matrix(test)
print(f"inasistencia en prueba: {sum(y)/len(y):.1%}\n")
cands = {
  "siempre asiste": always_attends(test),
  "regla 3 variables": three_variable_rule(test),
}
pipe = fit_logistic(train)
cands["logística 5 var"] = score_rows(pipe, test)
leaky_cols = HONEST + [LEAKY]
pipe_leak = fit_logistic(train, leaky_cols)
cands["logística + FUGA"] = score_rows(pipe_leak, test, leaky_cols)
for name, s in cands.items():
    auc = roc_auc(s, y)
    th = threshold_for_capacity(s, 0.20)
    p, r, n = precision_recall(s, y, th)
    print(f"{name:<20} AUC {auc:.3f} · marca {n:>6,} ({n/len(y):.0%}) · precisión {p:.3f} · recall {r:.3f}")
print("\ncoeficientes (datos escalados):")
for k,v in coefficients(pipe).items(): print(f"  {k:<26}{v:+.3f}")
PY

# --- 2026-09-14T01:40:07 · Measure split inflation and maintenance cost
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs/src/ds07-scikit-learn
uv run --python 3.14 --with 'scikit-learn==1.9.1' python - <<'PY'
import pickle, random, time, subprocess, sys, statistics
from pathlib import Path
from features import *
from baseline import *
from model import *
d=Path("data"); rows=load_rows(d); cut=cutoff_of(d)
train, test = split_temporal(rows, cut)

print("=== partición temporal contra partición al azar ===")
_, y = build_matrix(test)
pipe = fit_logistic(train)
print(f"  temporal   AUC {roc_auc(score_rows(pipe,test), y):.3f}")
rng=random.Random(20260913); shuffled=rows[:]; rng.shuffle(shuffled)
cutpoint=len(train)
rt, rs = shuffled[:cutpoint], shuffled[cutpoint:]
_, ry = build_matrix(rs)
print(f"  al azar    AUC {roc_auc(score_rows(fit_logistic(rt), rs), ry):.3f}")

print("\n=== costo de mantener cada una ===")
t=[]
for _ in range(5):
    s=time.perf_counter(); fit_logistic(train); t.append((time.perf_counter()-s)*1000)
print(f"  entrenamiento logística: {statistics.median(t):.0f} ms")
t=[]
for _ in range(5):
    s=time.perf_counter(); score_rows(pipe,test); t.append((time.perf_counter()-s)*1000)
print(f"  predicción 33k filas:    {statistics.median(t):.1f} ms")
t=[]
for _ in range(5):
    s=time.perf_counter(); three_variable_rule(test); t.append((time.perf_counter()-s)*1000)
print(f"  regla 33k filas:         {statistics.median(t):.1f} ms")
blob=pickle.dumps(pipe); print(f"  artefacto pickle:        {len(blob)/1024:.1f} KB")
def cold(code):
    tt=[]
    for _ in range(5):
        s=time.perf_counter(); subprocess.run([sys.executable,"-c",code],check=True,capture_output=True); tt.append((time.perf_counter()-s)*1000)
    tt.sort(); return statistics.median(tt)
print(f"  arranque + import sklearn: {cold('import sklearn.linear_model'):.0f} ms")
print(f"  arranque solo:             {cold('pass'):.0f} ms")
PY

# --- 2026-09-14T01:40:39 · Compare three split strategies against two feature sets
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs/src/ds07-scikit-learn
uv run --python 3.14 --with 'scikit-learn==1.9.1' python - <<'PY'
import random
from pathlib import Path
from features import *
from baseline import *
from model import *
d=Path("data"); rows=load_rows(d); cut=cutoff_of(d)
train, test = split_temporal(rows, cut)
rng=random.Random(20260913); shuffled=rows[:]; rng.shuffle(shuffled)
rt, rs = shuffled[:len(train)], shuffled[len(train):]
# partición por paciente: ningún paciente en los dos lados
patients=sorted({r["paciente_id"] for r in rows}); rng2=random.Random(7); rng2.shuffle(patients)
held=set(patients[:len(patients)//3])
gt=[r for r in rows if r["paciente_id"] not in held]; gs=[r for r in rows if r["paciente_id"] in held]
leaky=HONEST+[LEAKY]
print(f"{'partición':<26}{'honestas':>12}{'con fuga':>12}")
for name, (a,b) in {"temporal": (train,test), "al azar": (rt,rs), "por paciente": (gt,gs)}.items():
    _, y = build_matrix(b)
    h = roc_auc(score_rows(fit_logistic(a), b), y)
    l = roc_auc(score_rows(fit_logistic(a, leaky), b, leaky), y)
    print(f"{name:<26}{h:>12.3f}{l:>12.3f}")
print(f"\ncitas por paciente en el conjunto: {len(rows)/len(patients):.1f}")
same = sum(1 for r in rs if r["paciente_id"] in {x["paciente_id"] for x in rt[:5000]})
print("con partición al azar, un paciente aparece en los dos lados casi siempre")
PY

# --- 2026-09-14T01:41:37 · Run the full ds07 measurement
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs/src/ds07-scikit-learn
time uv run --python 3.14 --with 'scikit-learn==1.9.1' python bench_baseline.py --datos data 2>&1 | tail -32

# --- 2026-09-14T01:42:04 · Fix the cost table alignment
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs/src/ds07-scikit-learn
python3 - <<'PY'
p='bench_baseline.py'; s=open(p,encoding='utf-8').read()
old='''    print(f"  regla · {len(test):,} filas            "
          f"{timed(lambda: three_variable_rule(test)):>8.1f} ms")
    print(f"  logística · entrenar                  "
          f"{timed(lambda: fit_logistic(train)):>8.1f} ms")
    print(f"  logística · {len(test):,} filas        "
          f"{timed(lambda: score_rows(honest_pipeline, test)):>8.1f} ms")
    print(f"  artefacto serializado                 {len(artifact) / 1024:>8.1f} KB")
    print(f"  arranque del intérprete               {cold_start_ms('pass'):>8.0f} ms")
    print("  arranque + import de sklearn          "
          f"{cold_start_ms('import sklearn.linear_model'):>8.0f} ms")'''
new='''    costs = [
        (f"regla · {len(test):,} filas", f"{timed(lambda: three_variable_rule(test)):.1f} ms"),
        ("logística · entrenar", f"{timed(lambda: fit_logistic(train)):.1f} ms"),
        (f"logística · {len(test):,} filas",
         f"{timed(lambda: score_rows(honest_pipeline, test)):.1f} ms"),
        ("artefacto serializado", f"{len(artifact) / 1024:.1f} KB"),
        ("arranque del intérprete", f"{cold_start_ms('pass'):.0f} ms"),
        ("arranque + import de sklearn",
         f"{cold_start_ms('import sklearn.linear_model'):.0f} ms"),
    ]
    for label, value in costs:
        print(f"  {label:<34}{value:>12}")'''
assert s.count(old)==1
open(p,'w',encoding='utf-8').write(s.replace(old,new)); print("OK")
PY
uv run --python 3.14 --with 'scikit-learn==1.9.1' python bench_baseline.py --datos data 2>&1 | tail -8

# --- 2026-09-14T01:42:58 · Run the ds07 test suite
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs/src/ds07-scikit-learn
uv run --python 3.14 --with pytest --with 'scikit-learn==1.9.1' python -m pytest -q 2>&1 | tail -20

# --- 2026-09-14T01:43:48 · Correct the predict claim with the measured number
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs/src/ds07-scikit-learn
uv run --python 3.14 --with 'scikit-learn==1.9.1' python - <<'PY'
from pathlib import Path
from features import *
from model import *
from baseline import *
d=Path("data"); rows=load_rows(d); train,test=split_temporal(rows, cutoff_of(d))
m,y=build_matrix(test); pipe=fit_logistic(train)
marked=int(sum(pipe.predict(m)))
print(f"predict marca {marked:,} de {len(test):,} ({marked/len(test):.1%}) · tasa real {sum(y)/len(y):.1%}")
s=score_rows(pipe,test); p,r,n=precision_recall(s,y,0.5)
print(f"a umbral 0,5: precisión {p:.3f} recall {r:.3f} marcadas {n:,}")
PY
python3 - <<'PY'
p='test_ausentismo.py'; s=open(p,encoding='utf-8').read()
old='''def test_predict_marca_casi_nada_y_por_eso_no_se_usa(split, pipelines):
    """Con 19% de positivos, el umbral de 0,5 que usa `predict` deja fuera a casi todos. Es
    la razón de que el código use `predict_proba` y elija el umbral por capacidad."""
    _, test = split
    honest, _ = pipelines
    matrix, _ = build_matrix(test)
    assert sum(honest.predict(matrix)) < len(test) * 0.05'''
new='''def test_predict_marca_la_mitad_de_lo_que_deberia(split, pipelines):
    """`predict` decide con un umbral de 0,5 que nadie eligió. Con una clase positiva del
    20%, marca alrededor del 10%: la mitad de los que faltan no aparecen, y el número no lo
    decidió nadie. Por eso el código usa `predict_proba` y elige el umbral por capacidad."""
    _, test = split
    honest, _ = pipelines
    matrix, target = build_matrix(test)
    marked = sum(honest.predict(matrix)) / len(test)
    rate = sum(target) / len(target)
    assert marked < rate * 0.7'''
assert s.count(old)==1
open(p,'w',encoding='utf-8').write(s.replace(old,new)); print("OK")
PY
uv run --python 3.14 --with pytest --with 'scikit-learn==1.9.1' python -m pytest -q 2>&1 | tail -3

# --- 2026-09-14T01:48:38 · Add ds07 to BENCHMARKS, INSTINTOS and the state docs
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs
python3 - <<'PY'
def sub(path, pairs):
    s=open(path,encoding='utf-8').read()
    for old,new in pairs:
        if s.count(old)!=1: raise SystemExit(f"{path}: {s.count(old)} de {old[:60]!r}")
        s=s.replace(old,new)
    open(path,'w',encoding='utf-8').write(s); print("OK", path)

sub('BENCHMARKS.md', [("""---

## ✍️ Cómo se agregan entradas""", """### ds07 · La regla de ocho líneas contra la regresión logística

**Afirmaba:** que la logística de cinco variables le gana a la regla de tres, que la fuga infla
el AUC de forma visible, y que el costo de mantener el modelo es despreciable para el uso que
Áurea le da.

**Condiciones:** scikit-learn 1.9.1. Histórico de ausentismo con semilla 20260913: **105.620
citas de 12.400 pacientes**. Corte temporal en **2025-10-01**, tomado del manifiesto del
conjunto: 72.396 citas de entrenamiento y 33.224 de prueba, con 19,9% de inasistencia en el
tramo de prueba. Umbral por **capacidad del 20%**, que es la media mañana de Yuli, no el que
maximiza una métrica.

| Candidato | AUC | Marcadas | Precisión | Recall |
|---|---|---|---|---|
| siempre asiste | 0,500 | 33.224 (100%) | 0,199 | 1,000 |
| regla de 3 variables | 0,672 | 9.712 (29%) | 0,351 | 0,516 |
| **logística de 5** | **0,799** | **6.645 (20%)** | **0,526** | **0,530** |
| logística + FUGA | 0,862 | 6.645 (20%) | 0,588 | 0,592 |

⚖️ **El modelo gana, y donde importa:** a la misma capacidad, **0,526 de precisión contra
0,351** — de cada diez llamadas de Yuli aciertan cinco en vez de tres y media, **un 50% más por
el mismo tiempo de trabajo**. Y la regla trae un problema que el AUC no muestra: **no puede
operar a capacidad**, porque con cuatro puntajes distintos marca el 29% cuando le pides el 20%.

**La fuga regala 0,063 de AUC** —una columna de un `GROUP BY`, sin error ni advertencia— y lo
hace **con cualquier partición**, que es el hallazgo metodológico: la fuga es un problema de
columnas, no de partición.

| Partición | Variables honestas | Con la columna con fuga |
|---|---|---|
| temporal (la correcta) | 0,799 | 0,862 |
| al azar | 0,799 | 0,859 |
| por paciente | 0,798 | 0,856 |

⚖️ **Y el resultado que contradice al manual:** en este conjunto **partir al azar da exactamente
el mismo AUC que partir por fecha**. No hay inflación, y la razón se puede decir: el proceso que
genera los datos **no tiene deriva**. Eso no vuelve legítimo el atajo — lo que hace peligrosa a
la partición al azar es que **impide enterarse de si el conjunto tiene deriva**. Aquí no había
nada que esconder, y solo se sabe porque se partió por fecha.

**El costo de mantener:** entrenar 143,8 ms, predecir 33.224 filas 45,8 ms, artefacto **1,2 KB**,
y el arranque del intérprete pasa de 29 ms a **857 ms** al importar sklearn. La regla corre en
7,5 ms sin dependencia ninguna.

→ [`ds07-scikit-learn.md`](ds07-scikit-learn.md) §6

---

## ✍️ Cómo se agregan entradas""")])

sub('INSTINTOS.md', [("""---

## 🧪 Los reflejos de método""", """### 33. "Es una función: entra un caso, sale una predicción"

Once años de código determinista dejan la expectativa de que un modelo se prueba con una
aserción: entrada conocida, salida esperada, verde. Aquí **no hay correcto**: hay mejor o peor
que una línea base, y si no escribiste la línea base primero, tu cifra no significa nada.

Sobre el ausentismo de Áurea, el modelo que **no hace nada** —decir que todos asisten— acierta
el **80,1%** de las veces, porque solo falta el 19%. Cualquier informe que celebre una exactitud
del 81% está celebrando eso. La regla de ocho líneas que Patricia ya aplica en la cabeza saca
**0,672 de AUC**, y ese es el número contra el que hay que ganar — la logística lo hace, con
0,799, y por eso entra.

Los dos reflejos hermanos que vienen en el mismo paquete: **`predict` decide por ti** con un
umbral de 0,5 que nadie eligió —marca el 9,8% cuando falta el 20%—, y **la columna que sale de
un `GROUP BY` puede conocer el futuro**: `inasistencias_totales_paciente` regala 0,063 de AUC
sin lanzar nada. La pregunta que los desarma es siempre la misma: *¿cuándo se llena este campo?*
*(`ds07`)*

---

## 🧪 Los reflejos de método""")])

sub('prompts/README.md', [
("| **T11** | `ds07` | Sola: fija la línea base que `ds08` tiene que vencer. Escribirla junto a `ds08` la contamina |",
 "| **T11** ✅ | `ds07`, cerrada el 13/09/2026: dos líneas base, cuatro tablas medidas y 38 pruebas | Sola: fija la línea base que `ds08` tiene que vencer. Escribirla junto a `ds08` la contamina |"),
("""> **T10**, `ds05` y `ds06`. Seis secciones publicadas y **el bloque del Embudo cerrado**. De las
> siete mediciones, seis están **ejecutadas** y una en `⏳` —la de `ds05` §6.2, que necesita
> cinco personas—. La siguiente es **T11** (`ds07`).""",
 """> **T10**, `ds05` y `ds06`; y **T11**, `ds07`. Siete secciones publicadas: **el bloque del
> Embudo cerrado y la línea base de Ausentismo fijada en 0,799 de AUC**. De las ocho mediciones,
> siete están **ejecutadas** y una en `⏳` —la de `ds05` §6.2, que necesita cinco personas—. La
> siguiente es **T12** (`ds08`, el proyecto Ausentismo)."""),
])

sub('prompts/prompts-de-tracks-ia-ds.md', [
("| `ds07-scikit-learn.md` | scikit-learn y la línea base honesta | Ausentismo | Regla de tres variables ⇄ regresión logística |",
 "| `ds07-scikit-learn.md` ✅ | scikit-learn y la línea base honesta | Ausentismo | Regla de tres variables ⇄ regresión logística — **ejecutada: 0,672 ⇄ 0,799** |"),
("""> conjuntos de datos; T7 escribió `ds01` y `ds02`; T8, `ds03`; T9, `ds04`; T10, `ds05` y `ds06`.
> **Seis de las siete mediciones están ejecutadas**""",
 """> conjuntos de datos; T7 escribió `ds01` y `ds02`; T8, `ds03`; T9, `ds04`; T10, `ds05` y `ds06`;
> T11, `ds07`. **Siete de las ocho mediciones están ejecutadas**"""),
("""> del track es la §6.2 de `ds05`**, que necesita cinco personas y no un portátil. Siguiente:
> T11, `ds07`.""",
 """> del track es la §6.2 de `ds05`**, que necesita cinco personas y no un portátil. **La línea
> base que `ds08` tiene que vencer queda en 0,799 de AUC y 0,526 de precisión a capacidad del
> 20%.** Siguiente: T12, `ds08`."""),
])
PY

# --- 2026-09-14T01:48:48 · Lint and link check after ds07
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs
rm -rf src/ds0*/data src/ds0*/salida src/ds0*/cuadernos src/ds0*/resultado.json src/ds0*/__pycache__ src/ds0*/.pytest_cache .pytest_cache 2>/dev/null
echo "=== lint ==="; uvx ruff@0.16.7 check src/ds0* && echo "  OK desde la raíz"
for d in src/ds0*/; do printf "  %-46s" "$(basename $d)"; (cd $d && uvx ruff@0.16.7 check . >/dev/null 2>&1 && echo "OK" || echo "FALLA"); done
echo "=== links ==="
python3 - <<'PY'
import re,os
bad=[]
for root,d,fs in os.walk('.'):
    if 'pytest_cache' in root: continue
    for f in fs:
        if not f.endswith('.md'): continue
        p=os.path.join(root,f)
        for i,l in enumerate(open(p,encoding='utf-8'),1):
            for m in re.finditer(r'\]\((?!https?:)([^)#]+\.md)(?:#[^)]*)?\)',l):
                t=m.group(1)
                if not os.path.exists(os.path.normpath(os.path.join(root,t))): bad.append(f"{p}:{i} -> {t}")
print("links rotos:", "\n".join(bad) or "ninguno")
PY
wc -l ds07-scikit-learn.md

# --- 2026-09-14T01:49:02 · Final lint and full test sweep
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs
uvx ruff@0.16.7 check --fix src/ds07-scikit-learn >/dev/null 2>&1
uvx ruff@0.16.7 check src/ds0* && echo "lint OK desde la raíz"
(cd src/ds07-scikit-learn && uvx ruff@0.16.7 check . >/dev/null 2>&1 && echo "lint OK desde dentro")
echo "=== todas las suites ==="
for d in src/ds01-numpy-y-el-modelo-vectorizado src/ds02-pandas src/ds03-polars-y-el-modelo-lazy src/ds04-embudo; do
  printf "  %-40s" "$(basename $d)"; (cd $d && uv run --python 3.14 --with pytest --with 'numpy==2.5.3' --with 'pandas==3.0.5' --with 'polars==1.44.2' --with 'duckdb==1.5.5' python -m pytest -q 2>&1|tail -1); done
printf "  %-40s" "ds05-visualizacion"; (cd src/ds05-visualizacion && uv run --python 3.14 --with pytest --with 'matplotlib==3.11.2' --with 'plotly==7.0.0' --with 'altair==6.2.2' python -m pytest -q 2>&1|tail -1)
printf "  %-40s" "ds06-notebooks"; (cd src/ds06-notebooks-y-reproducibilidad && timeout 400 uv run --python 3.14 --with pytest --with 'papermill==2.7.0' --with 'jupyterlab==4.6.3' --with 'marimo==0.24.2' python -m pytest -q -p no:warnings 2>&1|tail -1)
printf "  %-40s" "ds07-scikit-learn"; (cd src/ds07-scikit-learn && uv run --python 3.14 --with pytest --with 'scikit-learn==1.9.1' python -m pytest -q 2>&1|tail -1)

# --- 2026-09-14T01:50:00 · Clean up and record T11 in memory
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs
rm -rf src/ds0*/data src/ds0*/__pycache__ src/ds0*/.pytest_cache .pytest_cache 2>/dev/null
cd /Users/oskar/.claude/projects/-Users-oskar-Developer-Learning-courses-ia-generated/memory
python3 - <<'PY'
p='python-java-devs-estado.md'; s=open(p,encoding='utf-8').read()
old="**Lo siguiente es T11 (`ds07`).**"
new="""**T11 cerrada el 13/09/2026**: `ds07-scikit-learn.md` (686 líneas) con `features.py`,
`baseline.py`, `model.py`, `bench_baseline.py` y 38 pruebas. **La línea base que `ds08` tiene
que vencer queda fijada: 0,799 de AUC y 0,526 de precisión a capacidad del 20%.** La regla de
tres variables saca 0,672 y el piso —"todos asisten"— acierta el 80,1%, que es por qué la
exactitud no se usa. Dos hallazgos fuera del guion: **la regla no puede operar a capacidad**
(marca 29% cuando le piden 20%, por empates —limitación que el AUC no muestra—) y **partir al
azar da exactamente el mismo AUC que partir por fecha** (0,799 contra 0,799), porque el
generador no tiene deriva por construcción. Eso no legitima el atajo y la explicación quedó
mejor que el tópico: la partición temporal es la que **detecta** la deriva, la aleatoria la
esconde. La fuga de `inasistencias_totales_paciente` regala **0,063 de AUC con cualquiera de
las tres particiones**: es un problema de columnas, no de partición.

Decisión de diseño que sostiene la cuarta tabla: **`baseline.py` no importa scikit-learn**. Si
lo hiciera, comparar el costo de mantener sería mentira —las dos pagarían los mismos 857 ms de
arranque—, así que el AUC y la precisión/recall están escritos a mano y probados contra los tres
casos que los definen.

**Lo siguiente es T12 (`ds08`, el proyecto Ausentismo).**"""
assert s.count(old)==1
open(p,'w',encoding='utf-8').write(s.replace(old,new)); print("OK memoria")
PY

# --- 2026-09-14T02:01:39 · Check that the pinned torch installs and runs on CPU
cd /tmp && time uv run --python 3.14 --with 'torch==2.14.0' python -c "
import torch
print('torch', torch.__version__, '· hilos', torch.get_num_threads())
x = torch.randn(4, 5); print('ok', x.shape)" 2>&1 | tail -4

# --- 2026-09-14T02:02:06 · Diagnose the OpenMP conflict
cd /tmp
echo "--- solo torch, de nuevo ---"; uv run --python 3.14 --with 'torch==2.14.0' python -c "import torch; print('ok', torch.__version__)" 2>&1 | tail -2
echo "--- torch + sklearn ---"; uv run --python 3.14 --with 'torch==2.14.0' --with 'scikit-learn==1.9.1' python -c "import sklearn, torch; print('ok')" 2>&1 | tail -2
echo "--- con KMP_DUPLICATE_LIB_OK ---"; KMP_DUPLICATE_LIB_OK=TRUE uv run --python 3.14 --with 'torch==2.14.0' --with 'scikit-learn==1.9.1' python -c "import sklearn, torch; print('ok')" 2>&1 | tail -2

# --- 2026-09-14T02:03:45 · Train the network and compare against the baseline
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs/src/ds08-ausentismo
mkdir -p data && python3 ../ds07-scikit-learn/generar_ausentismo.py --salida data >/dev/null
time uv run --python 3.14 --with 'torch==2.14.0' --with 'scikit-learn==1.9.1' python - <<'PY'
from pathlib import Path
from shared import *
from net import *
d=Path("data"); rows=load_rows(d); train,test=split_temporal(rows, cutoff_of(d))
_, y = build_matrix(test)
net, scaler, rep = train_network(train)
print(f"épocas {rep.epochs_run} (mejor {rep.best_epoch}) · parámetros {rep.parameters} · {rep.seconds:.1f} s")
print(f"pérdida entrenamiento {rep.train_loss:.4f} · validación {rep.validation_loss:.4f}")
s_net = score_network(net, scaler, test)
s_log = score_rows(fit_logistic(train), test)
s_rule = three_variable_rule(test)
for name, s in (("regla", s_rule), ("logística", s_log), ("red", s_net)):
    th = threshold_for_capacity(s, 0.20); p,r,n = precision_recall(s, y, th)
    print(f"{name:<12} AUC {roc_auc(s,y):.4f} · precisión {p:.3f} · recall {r:.3f} · marca {n:,}")
PY

# --- 2026-09-14T02:04:25 · Test whether one hand-written interaction closes the gap
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs/src/ds08-ausentismo
uv run --python 3.14 --with 'torch==2.14.0' --with 'scikit-learn==1.9.1' python - <<'PY'
import random
from pathlib import Path
from shared import *
from net import *
d=Path("data"); rows=load_rows(d); train,test=split_temporal(rows, cutoff_of(d))
_, y = build_matrix(test)

# la logística con el término de interacción que el generador SÍ tiene (lluvia × distancia)
import features as F
orig = F._value
def patched(row, column):
    if column == "lluvia_x_distancia":
        return float(row["lluvia_mm"]) * float(row["distancia_km"])
    return orig(row, column)
F._value = patched
cols = [*HONEST, "lluvia_x_distancia"]

net, scaler, rep = train_network(train)
cands = {
 "logística 5": score_rows(fit_logistic(train), test),
 "logística 5 + interacción": score_rows(fit_logistic(train, cols), test, cols),
 "red neuronal": score_network(net, scaler, test),
}
for n,s in cands.items(): print(f"{n:<28} AUC {roc_auc(s,y):.4f}")

# ¿es real la diferencia? bootstrap sobre el tramo de prueba
rng=random.Random(20260913); idx=list(range(len(y)))
base=cands["logística 5"]; nn=cands["red neuronal"]; inter=cands["logística 5 + interacción"]
diffs_nn=[]; diffs_in=[]
for _ in range(200):
    sample=[idx[rng.randrange(len(idx))] for _ in idx]
    yy=[y[i] for i in sample]
    a=roc_auc([base[i] for i in sample], yy)
    diffs_nn.append(roc_auc([nn[i] for i in sample], yy)-a)
    diffs_in.append(roc_auc([inter[i] for i in sample], yy)-a)
for name,dd in (("red − logística", diffs_nn), ("interacción − logística", diffs_in)):
    dd.sort(); print(f"{name:<28} Δ {sum(dd)/len(dd):+.4f}  IC95 [{dd[5]:+.4f}, {dd[194]:+.4f}]")
PY

# --- 2026-09-14T02:06:12 · Measure calibration and the overbooking decision
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs/src/ds08-ausentismo
uv run --python 3.14 --with 'torch==2.14.0' --with 'scikit-learn==1.9.1' python - <<'PY'
import pickle
from pathlib import Path
from shared import *
from net import *
from engineered import *
from calibration import *
from overbooking import *
d=Path("data"); rows=load_rows(d); train,test=split_temporal(rows, cutoff_of(d))
_, y = build_matrix(test)
net, scaler, rep = train_network(train)
cands = {
 "regla de 3": three_variable_rule(test),
 "logística de 5": score_rows(fit_logistic(train), test),
 "logística + interacción": score_with_interaction(fit_with_interaction(train), test),
 "red neuronal": score_network(net, scaler, test),
}
print(f"{'candidato':<26}{'AUC':>8}{'Brier':>9}{'ECE':>8}")
for n,s in cands.items():
    print(f"{n:<26}{roc_auc(s,y):>8.4f}{brier_score(s,y):>9.4f}{expected_calibration_error(s,y):>8.4f}")
print("\nfiabilidad por decil (red neuronal): predicho → observado")
for p,o,c in reliability(cands["red neuronal"], y): print(f"  {p:.3f} → {o:.3f}  (n={c:,})")
print(f"\numbral de sobreagendamiento con ratio {COLLISION_RATIO}: p > {break_even():.2f}")
for n,s in cands.items():
    dec = decide(s); over=sum(dec)
    print(f"  {n:<26} sobreagenda {over:>5} de {len(s):,} cupos", end="")
    if over: print(f" · esperado {expected_cost(s,dec):+.1f} · real {realised_cost(s,dec,y):+.1f}")
    else: print()
for ratio in (1.0, 1.5, 2.0):
    s=cands["red neuronal"]; dec=decide(s,ratio)
    print(f"  ratio {ratio}: umbral {break_even(ratio):.2f} · sobreagenda {sum(dec):,} · esperado {expected_cost(s,dec,ratio):+.0f} · real {realised_cost(s,dec,y,ratio):+.0f}")
print(f"\nartefactos: red {len(pickle.dumps(net))/1024:.1f} KB · logística {len(pickle.dumps(fit_logistic(train)))/1024:.1f} KB")
print(f"entrenamiento red {rep.seconds:.1f} s · parámetros {rep.parameters}")
PY

# --- 2026-09-14T02:06:40 · Frame overbooking as net gain over doing nothing
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs/src/ds08-ausentismo
uv run --python 3.14 --with 'torch==2.14.0' --with 'scikit-learn==1.9.1' python - <<'PY'
from pathlib import Path
from shared import *
from net import *
from engineered import *
from overbooking import *
d=Path("data"); rows=load_rows(d); train,test=split_temporal(rows, cutoff_of(d))
_, y = build_matrix(test)
net, scaler, _ = train_network(train)
cands = {
 "regla de 3": three_variable_rule(test),
 "logística de 5": score_rows(fit_logistic(train), test),
 "logística + interacción": score_with_interaction(fit_with_interaction(train), test),
 "red neuronal": score_network(net, scaler, test),
}
never = -sum(y)   # no sobreagendar nada: se pierde una consulta por cada inasistencia
print(f"no sobreagendar nada: {never:,} consultas perdidas sobre {len(y):,} citas\n")
for ratio in (1.0, 2.0, 3.0, 4.0):
    print(f"--- una colisión cuesta {ratio:g}× una silla vacía · umbral p > {break_even(ratio):.2f} ---")
    for n,s in cands.items():
        dec=decide(s,ratio); real=realised_cost(s,dec,y,ratio)
        print(f"   {n:<26} sobreagenda {sum(dec):>6,} · neto frente a no hacer nada: {real-never:+8.0f} consultas")
PY

# --- 2026-09-14T02:07:25 · Run the full ds08 measurement
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs/src/ds08-ausentismo
time uv run --python 3.14 --with 'torch==2.14.0' --with 'scikit-learn==1.9.1' python bench_net.py --datos data 2>&1 | tail -45

# --- 2026-09-14T02:08:41 · Fix the leftover and run the ds08 suite
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs/src/ds08-ausentismo
python3 - <<'PY'
p='test_red.py'; s=open(p,encoding='utf-8').read()
old="""    rule = three_variable_rule(test)
    logistic = score_rows(fit_logistic(test[:1] + test), test)  # entrenada abajo, ver nota
    del logistic

    rule_net = realised_cost(rule, decide(rule, 3.0), target, 3.0) - never
    assert rule_net < 0"""
new="""    rule = three_variable_rule(test)
    assert realised_cost(rule, decide(rule, 3.0), target, 3.0) - never < 0"""
assert s.count(old)==1
open(p,'w',encoding='utf-8').write(s.replace(old,new)); print("OK")
PY
timeout 500 uv run --python 3.14 --with pytest --with 'torch==2.14.0' --with 'scikit-learn==1.9.1' python -m pytest -q 2>&1 | tail -15

# --- 2026-09-14T02:09:50 · Label the cold call and get table 1 in full
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs/src/ds08-ausentismo
python3 - <<'PY'
p='bench_net.py'; s=open(p,encoding='utf-8').read()
s=s.replace('        ("logística · entrenar", f"{logistic_seconds * 1000:.0f} ms"),',
            '        ("logística · entrenar (1ª llamada)", f"{logistic_seconds * 1000:.0f} ms"),')
s=s.replace('''    for label, value in costs:
        print(f"  {label:<34}{value:>12}")''',
'''    for label, value in costs:
        print(f"  {label:<34}{value:>12}")
    print("  La primera llamada a la logística incluye el import de sklearn; en caliente,")
    print("  `ds07` §6.3 la mide en 143,8 ms.")''')
open(p,'w',encoding='utf-8').write(s); print("OK")
PY
uv run --python 3.14 --with 'torch==2.14.0' --with 'scikit-learn==1.9.1' python bench_net.py --datos data 2>&1 | head -10

# --- 2026-09-14T02:14:41 · Write the ds08 src README
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs/src/ds08-ausentismo
cat > README.md <<'EOF'
# `ds08` · Proyecto · Ausentismo

Código de la sección [`ds08-ausentismo.md`](../../ds08-ausentismo.md).

| Archivo | Qué es |
|---|---|
| `shared.py` | La línea base de `ds07`, importada en vez de copiada. **La única excepción del track** |
| `net.py` | La red neuronal en PyTorch, CPU, determinista y con parada temprana |
| `engineered.py` | La columna que iguala a la red: `lluvia × distancia` |
| `calibration.py` | Brier, ECE y la tabla de fiabilidad. **Sin torch ni sklearn** |
| `overbooking.py` | De la probabilidad a la decisión, con la asimetría de costos |
| `bench_net.py` | La medición de la sección 6: cinco tablas |
| `test_red.py` | 14 pruebas: `pytest -q` |

## Correr las cosas

```bash
python ../ds07-scikit-learn/generar_ausentismo.py --salida data
uv run --with torch==2.14.0 --with scikit-learn==1.9.1 python bench_net.py --datos data
```

Unos 23 segundos, de los cuales 2 son entrenar la red.

## ⚠️ PyTorch solo, en macOS, no arranca

```
OMP: Error #15: Initializing libomp.dylib, but found libomp.dylib already initialized.
```

En un entorno con **solo torch** esto aborta el proceso. Con scikit-learn al lado, funciona:
más de una biblioteca trae su copia del runtime de OpenMP y el enlazador encuentra dos. El
mensaje sugiere `KMP_DUPLICATE_LIB_OK=TRUE` y él mismo lo llama *unsafe, unsupported,
undocumented* — sirve para salir del paso, no para producción.

Por eso todos los comandos de esta carpeta traen las dos dependencias.

## `shared.py` es la única vez que una sección importa de otra

La regla del track es que cada carpeta de `src/` corre sola. Aquí se rompe, con motivo: la
comparación con `ds07` **solo vale si las dos usan exactamente las mismas variables**, el
mismo tope de historial y el mismo corte temporal. Copiar `features.py` habría garantizado que
algún día las dos definiciones divergieran sin que nadie se entere, y ese día la tabla de la
sección 6 dejaría de significar algo **sin dar ningún error**.

## Los tres resultados que este código sostiene

1. **La red gana, y la diferencia es real**: 0,8118 contra 0,7993 de AUC, con intervalo
   bootstrap [+0,0109, +0,0141] que no toca el cero.
2. **Una columna a mano la iguala.** `lluvia × distancia` lleva la logística a 0,8118 con un
   intervalo indistinguible. El generador tiene **una** interacción; la red la encuentra y
   escribirla cuesta una línea.
3. **Un puntaje que ordena bien puede decidir catastróficamente.** La regla de `ds07` tiene
   ECE de 0,1918: aplicada al sobreagendamiento pierde **6.336 consultas** contra no hacer
   nada, mientras los modelos calibrados recuperan unas 3.000.

## Lo que no depende de torch

`calibration.py` y `overbooking.py` son aritmética pura y tienen sus pruebas. Es deliberado:
**son los módulos que deciden plata**, y tienen que poder revisarse y correrse sin instalar
cientos de megas.

Los archivos generados no se versionan.
EOF
echo OK

# --- 2026-09-14T02:15:22 · Add ds08 to BENCHMARKS, INSTINTOS and the state docs
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs
python3 - <<'PY'
def sub(path, pairs):
    s=open(path,encoding='utf-8').read()
    for old,new in pairs:
        if s.count(old)!=1: raise SystemExit(f"{path}: {s.count(old)} de {old[:60]!r}")
        s=s.replace(old,new)
    open(path,'w',encoding='utf-8').write(s); print("OK", path)

sub('BENCHMARKS.md', [("""---

## ✍️ Cómo se agregan entradas""", """### ds08 · La red neuronal contra la línea base

**Afirmaba:** que la red le gana a la línea base de `ds07`, que la ventaja es pequeña, y que
**una columna de ingeniería de variables la iguala**.

**Condiciones:** PyTorch 2.14.0 en CPU y scikit-learn 1.9.1. Los mismos datos, corte y variables
de `ds07`: 72.396 citas de entrenamiento y 33.224 de prueba. Red de dos capas ocultas (16 y 8),
Adam, lotes de 512, semilla 20260913, parada temprana con paciencia 8 sobre el último 20% del
entrenamiento. Intervalos bootstrap de 200 remuestreos.

| Candidato | AUC | Brier | ECE | Precisión @20% |
|---|---|---|---|---|
| regla de 3 | 0,6723 | 0,1952 | **0,1918** | 0,351 |
| logística de 5 | 0,7993 | 0,1204 | 0,0127 | 0,526 |
| **logística + interacción** | **0,8118** | **0,1114** | **0,0106** | 0,547 |
| red neuronal | 0,8118 | 0,1116 | 0,0107 | 0,548 |

| Diferencia de AUC | Media | IC 95% |
|---|---|---|
| red − logística de 5 | +0,0125 | [+0,0109, +0,0141] |
| interacción − logística de 5 | +0,0126 | [+0,0107, +0,0142] |

⚖️ **La red gana, y gana exactamente lo que vale una columna.** La tesis que la historia de Áurea
daba por probable —*la red probablemente pierde*— **no se cumplió**: el intervalo de su ventaja
no toca el cero. Pero la misma logística con `lluvia × distancia` escrita a mano llega al mismo
0,8118 con un intervalo indistinguible. El proceso que genera estos datos tiene **una sola
interacción**; la red la encuentra y escribirla cuesta una línea. **La decisión deja de ser de
rendimiento y pasa a ser de mantenimiento:** 144 ms y 1,2 KB con seis coeficientes legibles,
contra PyTorch instalado, 4,0 KB y cinco decisiones de entrenamiento que alguien retoma cada vez
que los datos cambien.

**Y el hallazgo que más plata mueve, que no es sobre modelos sino sobre calibración.** Llevando
cada puntaje a la decisión de sobreagendar —con una colisión tres veces peor que una silla
vacía, umbral p > 0,75— sobre las 6.602 consultas que se pierden en el tramo de prueba:

| | Cupos sobreagendados | Consultas netas contra no hacer nada |
|---|---|---|
| regla de 3 (ECE 0,19) | 6.187 | **−6.336** |
| logística de 5 | 1.247 | +1.664 |
| logística + interacción | 1.878 | +3.006 |
| red neuronal | 1.994 | **+3.023** |

⚖️ **Un puntaje que ordena bien puede decidir catastróficamente.** La regla ordena
razonablemente —0,672 de AUC— y pierde más de lo que había para ganar, porque su 0,8 no
significa 80%. La diferencia entre 0,672 y 0,799 parecía moderada; en la decisión es la
diferencia entre ganar y destruir.

📝 **Falta el competidor que importaba:** un gradiente potenciado sobre las mismas cinco
variables, que para datos tabulares de este tamaño suele ganarles a todos. Dejarlo fuera le dio
a la red una comparación cómoda, y se declara.

→ [`ds08-ausentismo.md`](ds08-ausentismo.md) §6

---

## ✍️ Cómo se agregan entradas""")])

sub('INSTINTOS.md', [("""---

## 🧪 Los reflejos de método""", """### 34. "Si el modelo más complejo gana, uso el modelo más complejo"

Es el mismo criterio con el que eliges una estructura de datos, y ahí funciona: si el `HashMap`
gana, usas el `HashMap`, porque mantenerlo no cuesta nada. Un modelo sí cuesta.

Sobre el ausentismo de Áurea la red neuronal **gana de verdad** —0,8118 contra 0,7993, con un
intervalo al 95% que no toca el cero— y la conclusión correcta sigue siendo no usarla. Porque la
misma regresión logística con **una columna escrita a mano** —`lluvia × distancia`, que es
conocimiento que Julián ya tenía— llega al mismo 0,8118 con un intervalo indistinguible. La
ventaja no era de la red: era de la interacción que la línea base no tenía.

La pregunta que corrige el reflejo: **¿por cuánto gana, con qué intervalo, y qué le pasa a esa
ventaja si le escribo al competidor una variable que el dominio ya conocía?** Y su corolario,
que es de costo: 144 ms y seis coeficientes legibles contra PyTorch instalado y cinco decisiones
de entrenamiento que alguien retoma cada vez que los datos cambien. *(`ds08`)*

### 35. "El modelo decide"

No decide. El modelo produce una probabilidad; **la decisión es la asimetría de costos**, y esa
la pone la empresa. En Áurea, una colisión en la silla es unas tres veces peor que una silla
vacía, y de ahí sale —en una línea de álgebra— que solo conviene sobreagendar un cupo cuyo
paciente falte **tres de cada cuatro veces**. Ese 0,75 no salió de ningún modelo.

El reflejo tiene una consecuencia cara: un puntaje que **ordena** bien puede **decidir**
pésimo. La regla de tres variables saca 0,672 de AUC —decente— y un ECE de 0,1918: aplicada al
sobreagendamiento pierde 6.336 consultas contra no hacer nada, mientras cualquier modelo
calibrado recupera unas 3.000. Si tu puntaje va a multiplicar algo —plata, cupos, riesgo—, mide
la calibración antes de multiplicar. *(`ds08`)*

---

## 🧪 Los reflejos de método""")])

sub('prompts/README.md', [
("| **T12** | `ds08` · **Proyecto Ausentismo** | Solo: `torch` en CPU y la ética en el cuerpo del capítulo |",
 "| **T12** ✅ | `ds08`, cerrada el 13/09/2026: la red gana por 0,0125 de AUC y **una columna a mano la iguala**; cinco tablas y 14 pruebas | Solo: `torch` en CPU y la ética en el cuerpo del capítulo |"),
("""> **T10**, `ds05` y `ds06`; y **T11**, `ds07`. Siete secciones publicadas: **el bloque del
> Embudo cerrado y la línea base de Ausentismo fijada en 0,799 de AUC**. De las ocho mediciones,
> siete están **ejecutadas** y una en `⏳` —la de `ds05` §6.2, que necesita cinco personas—. La
> siguiente es **T12** (`ds08`, el proyecto Ausentismo).""",
 """> **T10**, `ds05` y `ds06`; **T11**, `ds07`; y **T12**, `ds08`. Ocho secciones publicadas: **los
> dos bloques —Embudo y Ausentismo— con sus proyectos cerrados**. De las nueve mediciones, ocho
> están **ejecutadas** y una en `⏳` —la de `ds05` §6.2, que necesita cinco personas—. La
> siguiente es **T13**: `ds09` y el cierre del track."""),
])

sub('prompts/prompts-de-tracks-ia-ds.md', [
("| `ds08-ausentismo.md` | **Proyecto · Ausentismo** | Ausentismo | Red neuronal ⇄ la línea base de `ds07` |",
 "| `ds08-ausentismo.md` ✅ | **Proyecto · Ausentismo** | Ausentismo | Red neuronal ⇄ la línea base de `ds07` — **ejecutada: la red gana 0,0125 y una columna a mano la iguala** |"),
("""> conjuntos de datos; T7 escribió `ds01` y `ds02`; T8, `ds03`; T9, `ds04`; T10, `ds05` y `ds06`;
> T11, `ds07`. **Siete de las ocho mediciones están ejecutadas**""",
 """> conjuntos de datos; T7 escribió `ds01` y `ds02`; T8, `ds03`; T9, `ds04`; T10, `ds05` y `ds06`;
> T11, `ds07`; T12, `ds08`. **Ocho de las nueve mediciones están ejecutadas**"""),
("""> base que `ds08` tiene que vencer queda en 0,799 de AUC y 0,526 de precisión a capacidad del
> 20%.** Siguiente: T12, `ds08`.""",
 """> base que `ds08` tenía que vencer quedó en 0,799 de AUC, y **la red la venció por 0,0125 — lo
> mismo que vale una columna de interacción escrita a mano**, que es el veredicto de `ds08`.
> Siguiente: T13, `ds09` y el cierre del track."""),
])
PY

# --- 2026-09-14T02:15:29 · Lint the track after ds08
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs
rm -rf src/ds0*/data src/ds0*/__pycache__ src/ds0*/.pytest_cache .pytest_cache 2>/dev/null
echo "=== lint ==="; uvx ruff@0.16.7 check src/ds0* 2>&1 | tail -6
for d in src/ds0*/; do printf "  %-46s" "$(basename $d)"; (cd $d && uvx ruff@0.16.7 check . >/dev/null 2>&1 && echo "OK" || echo "FALLA"); done

# --- 2026-09-14T02:15:37 · Fix ds08 lint and verify both directions
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs
uvx ruff@0.16.7 check --fix src/ds08-ausentismo >/dev/null 2>&1
uvx ruff@0.16.7 check src/ds0* && echo "lint OK desde la raíz"
(cd src/ds08-ausentismo && uvx ruff@0.16.7 check . >/dev/null 2>&1 && echo "lint OK desde dentro" || uvx ruff@0.16.7 check . 2>&1 | tail -20)

# --- 2026-09-14T02:15:48 · Full test sweep of the ds track
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs
echo "=== suites del track ds ==="
for d in src/ds01-numpy-y-el-modelo-vectorizado src/ds02-pandas src/ds03-polars-y-el-modelo-lazy src/ds04-embudo; do
  printf "  %-40s" "$(basename $d)"; (cd $d && uv run --python 3.14 --with pytest --with 'numpy==2.5.3' --with 'pandas==3.0.5' --with 'polars==1.44.2' --with 'duckdb==1.5.5' python -m pytest -q 2>&1|tail -1); done
printf "  %-40s" "ds05-visualizacion"; (cd src/ds05-visualizacion && uv run --python 3.14 --with pytest --with 'matplotlib==3.11.2' --with 'plotly==7.0.0' --with 'altair==6.2.2' python -m pytest -q 2>&1|tail -1)
printf "  %-40s" "ds06-notebooks"; (cd src/ds06-notebooks-y-reproducibilidad && timeout 400 uv run --python 3.14 --with pytest --with 'papermill==2.7.0' --with 'jupyterlab==4.6.3' --with 'marimo==0.24.2' python -m pytest -q -p no:warnings 2>&1|tail -1)
printf "  %-40s" "ds07-scikit-learn"; (cd src/ds07-scikit-learn && uv run --python 3.14 --with pytest --with 'scikit-learn==1.9.1' python -m pytest -q 2>&1|tail -1)
printf "  %-40s" "ds08-ausentismo"; (cd src/ds08-ausentismo && timeout 500 uv run --python 3.14 --with pytest --with 'torch==2.14.0' --with 'scikit-learn==1.9.1' python -m pytest -q 2>&1|tail -1)

# --- 2026-09-14T02:16:58 · Verify links, clean up and record T12 in memory
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs
rm -rf src/ds0*/data src/ds0*/__pycache__ src/ds0*/.pytest_cache .pytest_cache 2>/dev/null
python3 - <<'PY'
import re,os
bad=[]
for root,d,fs in os.walk('.'):
    if 'pytest_cache' in root: continue
    for f in fs:
        if not f.endswith('.md'): continue
        p=os.path.join(root,f)
        for i,l in enumerate(open(p,encoding='utf-8'),1):
            for m in re.finditer(r'\]\((?!https?:)([^)#]+\.md)(?:#[^)]*)?\)',l):
                t=m.group(1)
                if not os.path.exists(os.path.normpath(os.path.join(root,t))): bad.append(f"{p}:{i} -> {t}")
print("links rotos:", "\n".join(bad) or "ninguno")
PY
wc -l ds0*.md | tail -3
cd /Users/oskar/.claude/projects/-Users-oskar-Developer-Learning-courses-ia-generated/memory
python3 - <<'PY'
p='python-java-devs-estado.md'; s=open(p,encoding='utf-8').read()
old="**Lo siguiente es T12 (`ds08`, el proyecto Ausentismo).**"
new="""**T12 cerrada el 13/09/2026**: `ds08-ausentismo.md` (704 líneas) con `net.py` (PyTorch CPU),
`engineered.py`, `calibration.py`, `overbooking.py`, `shared.py` y 14 pruebas. **La tesis
anunciada no se cumplió y se escribió así: la red neuronal gana** —0,8118 contra 0,7993 de AUC,
con intervalo bootstrap [+0,0109, +0,0141] que no toca el cero—. Pero **gana exactamente lo que
vale una columna**: la misma logística con `lluvia × distancia` escrita a mano llega al mismo
0,8118 con un intervalo indistinguible, porque el generador tiene **una sola interacción** y la
red no encuentra nada más. La recomendación queda en la logística con la interacción, y el motivo
es de mantenimiento, no de rendimiento.

El hallazgo que más plata mueve no es sobre modelos sino sobre **calibración**: la regla de
`ds07` ordena decentemente (0,672) y tiene ECE de 0,1918, así que aplicada al sobreagendamiento
**pierde 6.336 consultas** contra no hacer nada, mientras los modelos calibrados recuperan unas
3.000. `overbooking.py` deriva el umbral de la asimetría de costos (`COLLISION_RATIO = 3`, número
**declarado como estimación, no medido**): hay que fallar 3 de cada 4 veces para que sobreagendar
no destruya valor.

La §6.6 —qué se puede hacer con la predicción y qué no— está **en el cuerpo**, con la prueba de
una sola pregunta ("si el paciente lo supiera, ¿te parecería bien contárselo?") y una consecuencia
técnica: el puntaje no se guarda en la ficha, vive en la lista del día. Dos cosas declaradas como
faltantes: el **gradiente potenciado**, que era el competidor real para datos tabulares y le dio a
la red una comparación cómoda, y que `COLLISION_RATIO` no está medido.

`shared.py` es **la única vez en los dos tracks que una sección importa código de otra**, con su
motivo escrito: copiar `features.py` habría hecho que las definiciones divergieran algún día sin
dar ningún error, y ese día la comparación dejaría de significar algo. Y un tropiezo real de
entorno: **`torch` solo aborta en macOS con `OMP: Error #15`**; con sklearn al lado funciona.

**Lo siguiente es T13: `ds09` y el cierre del track.**"""
assert s.count(old)==1
open(p,'w',encoding='utf-8').write(s.replace(old,new)); print("OK memoria")
PY

# --- 2026-09-14T02:17:04 · Correct the line count in memory
cd /Users/oskar/.claude/projects/-Users-oskar-Developer-Learning-courses-ia-generated/memory
python3 -c "
p='python-java-devs-estado.md'; s=open(p,encoding='utf-8').read()
s=s.replace('\`ds08-ausentismo.md\` (704 líneas)','\`ds08-ausentismo.md\` (745 líneas)')
open(p,'w',encoding='utf-8').write(s); print('OK')"

# --- 2026-09-14T02:27:53 · Check the ONNX and FastAPI stacks
cd /tmp && uv run --python 3.14 --with 'scikit-learn==1.9.1' --with 'skl2onnx==1.20.0' --with 'onnxruntime==1.30.0' --with 'onnx==1.22.0' python -c "
import onnx, onnxruntime, skl2onnx, sklearn
print('onnx', onnx.__version__, '· onnxruntime', onnxruntime.__version__, '· skl2onnx', skl2onnx.__version__, '· sklearn', sklearn.__version__)" 2>&1 | tail -3
echo "--- fastapi ---"
uv run --python 3.14 --with 'fastapi==0.141.1' --with 'uvicorn==0.52.4' python -c "
import fastapi, uvicorn; print('fastapi', fastapi.__version__, '· uvicorn', uvicorn.__version__)" 2>&1 | tail -2

# --- 2026-09-14T02:29:21 · Export the model to both formats and verify they agree
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs/src/ds09-servir-el-modelo
cat > shared.py <<'EOF'
"""Lo que esta sección toma de `ds07` y `ds08`.

    from shared import build_with_interaction, cutoff_of, load_rows, split_temporal

Misma excepción y mismo motivo que `ds08/shared.py`: el modelo que se sirve tiene que ser
**exactamente** el que `ds08` midió, con sus mismas variables y su misma interacción. Copiar
las definiciones garantizaría que algún día el modelo servido y el modelo medido dejaran de
ser el mismo, sin que nada fallara.
"""

from __future__ import annotations

import sys
from pathlib import Path

SRC = Path(__file__).resolve().parent.parent
for section in ("ds07-scikit-learn", "ds08-ausentismo"):
    path = str(SRC / section)
    if path not in sys.path:
        sys.path.insert(0, path)

from engineered import (  # noqa: E402  — el `sys.path` de arriba tiene que ir primero
    WITH_INTERACTION,
    build_with_interaction,
)
from features import HONEST, build_matrix, cutoff_of, load_rows, split_temporal  # noqa: E402

__all__ = ["HONEST", "WITH_INTERACTION", "build_matrix", "build_with_interaction",
           "cutoff_of", "load_rows", "split_temporal"]
EOF
mkdir -p data && python3 ../ds07-scikit-learn/generar_ausentismo.py --salida data >/dev/null
uv run --python 3.14 --with 'scikit-learn==1.9.1' --with 'skl2onnx==1.20.0' --with 'onnxruntime==1.30.0' python export.py --datos data --salida modelos 2>&1 | tail -6

# --- 2026-09-14T02:29:40 · Rename the module and re-export
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs/src/ds09-servir-el-modelo
git mv shared.py upstream.py 2>/dev/null || mv shared.py upstream.py
python3 - <<'PY'
p='upstream.py'; s=open(p,encoding='utf-8').read()
s=s.replace('''"""Lo que esta sección toma de `ds07` y `ds08`.

    from shared import build_with_interaction, cutoff_of, load_rows, split_temporal

Misma excepción y mismo motivo que `ds08/shared.py`: el modelo que se sirve tiene que ser
**exactamente** el que `ds08` midió, con sus mismas variables y su misma interacción. Copiar
las definiciones garantizaría que algún día el modelo servido y el modelo medido dejaran de
ser el mismo, sin que nada fallara.
"""''',
'''"""Lo que esta sección toma de `ds07` y `ds08`.

    from upstream import build_with_interaction, cutoff_of, load_rows, split_temporal

Misma excepción y mismo motivo que `ds08/shared.py`: el modelo que se sirve tiene que ser
**exactamente** el que `ds08` midió, con sus mismas variables y su misma interacción. Copiar
las definiciones garantizaría que algún día el modelo servido y el modelo medido dejaran de
ser el mismo, sin que nada fallara.

⚠️ **Este archivo se llamaba `shared.py` y hubo que renombrarlo.** `ds08` tiene un módulo con
ese nombre, el directorio del script va primero en `sys.path`, y el `shared.py` de aquí
tapaba al de allá: `ImportError: cannot import name 'HONEST' from 'shared'`. Es el costo real
del atajo de `sys.path` —**el espacio de nombres pasa a ser plano entre las tres carpetas**— y
conviene verlo una vez para saber por qué los proyectos de verdad usan paquetes.
"""''')
open(p,'w',encoding='utf-8').write(s)
p='export.py'; s=open(p,encoding='utf-8').read()
s=s.replace("from shared import build_with_interaction, cutoff_of, load_rows, split_temporal",
            "from upstream import build_with_interaction, cutoff_of, load_rows, split_temporal")
open(p,'w',encoding='utf-8').write(s); print("OK")
PY
uv run --python 3.14 --with 'scikit-learn==1.9.1' --with 'skl2onnx==1.20.0' --with 'onnxruntime==1.30.0' python export.py --datos data --salida modelos 2>&1 | tail -6

# --- 2026-09-14T02:30:13 · Write and smoke-test the serving endpoint
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs/src/ds09-servir-el-modelo
cat > serve.py <<'PYEOF'
"""El endpoint de predicción de AgendaAPI, con los dos formatos detrás.

    AUREA_BACKEND=pickle uvicorn serve:app --port 8100
    AUREA_BACKEND=onnx   uvicorn serve:app --port 8101

Misma API, mismo modelo, dos maneras de cargarlo. La sección 6 las mide de punta a punta
—por HTTP, no en proceso— porque es lo que aprendió la Fase 10 del camino base: el costo del
modelo de salida de FastAPI parecía un 33% medido en proceso y desapareció medido sobre HTTP.

🧭 **El backend se elige por variable de entorno y se anuncia en `/salud`.** Un servicio que
no dice qué modelo tiene cargado es un servicio que nadie puede depurar cuando las
predicciones cambien.
"""

from __future__ import annotations

import os
from pathlib import Path
from typing import Literal

from fastapi import FastAPI
from pydantic import BaseModel, Field

MODELS = Path(os.environ.get("AUREA_MODELOS", "modelos"))
BACKEND: Literal["pickle", "onnx"] = os.environ.get("AUREA_BACKEND", "onnx")  # type: ignore[assignment]


class Appointment(BaseModel):
    """Una cita a puntuar. Los nombres y el orden son los de `ds08`, y eso importa.

    Las seis columnas llegan **con nombre** y el servidor arma el vector en el orden del
    modelo. Aceptar una lista de seis números habría sido más corto y convierte cualquier
    reordenamiento en un error silencioso que nadie detecta hasta que las predicciones se
    vuelven raras.
    """

    inasistencias_previas: float = Field(ge=0)
    jueves_tarde: float = Field(ge=0, le=1)
    lluvia_mm: float = Field(ge=0)
    distancia_km: float = Field(gt=0)
    dias_desde_agendamiento: float = Field(ge=0)

    def vector(self) -> list[float]:
        return [self.inasistencias_previas, self.jueves_tarde, self.lluvia_mm,
                self.distancia_km, self.dias_desde_agendamiento,
                # La interacción se calcula aquí, no la manda el cliente: es parte del
                # modelo, y pedírsela a quien llama sería filtrar el modelo a la API.
                self.lluvia_mm * self.distancia_km]


class Prediction(BaseModel):
    probabilidad_inasistencia: float
    backend: str


def load_pickle():
    import pickle

    # ⚠️ Esto ejecuta código si el archivo no es el que crees. Ver `pickle_danger.py` y la
    # sección 5.4: la ruta se fija por configuración y el archivo lo escribe el proceso de
    # entrenamiento, nunca un cliente.
    with (MODELS / "modelo.pkl").open("rb") as file:
        pipeline = pickle.load(file)

    def predict(vector: list[float]) -> float:
        return float(pipeline.predict_proba([vector])[0][1])

    return predict


def load_onnx():
    import numpy as np
    import onnxruntime

    session = onnxruntime.InferenceSession(str(MODELS / "modelo.onnx"),
                                           providers=["CPUExecutionProvider"])
    name = session.get_inputs()[0].name

    def predict(vector: list[float]) -> float:
        batch = np.array([vector], dtype=np.float32)
        return float(session.run(None, {name: batch})[1][0][1])

    return predict


app = FastAPI(title="Ausentismo · Áurea", version="1.0")
_predict = (load_pickle if BACKEND == "pickle" else load_onnx)()


@app.get("/salud")
def health() -> dict[str, str]:
    return {"estado": "ok", "backend": BACKEND}


@app.post("/riesgo", response_model=Prediction)
def score(appointment: Appointment) -> Prediction:
    return Prediction(probabilidad_inasistencia=_predict(appointment.vector()),
                      backend=BACKEND)
PYEOF
uv run --python 3.14 --with 'fastapi==0.141.1' --with 'uvicorn==0.52.4' --with 'onnxruntime==1.30.0' python -c "
import os; os.environ['AUREA_BACKEND']='onnx'
from fastapi.testclient import TestClient
import serve
c=TestClient(serve.app)
print(c.get('/salud').json())
print(c.post('/riesgo', json={'inasistencias_previas':2,'jueves_tarde':1,'lluvia_mm':12.0,'distancia_km':18.0,'dias_desde_agendamiento':30}).json())" 2>&1 | tail -4

# --- 2026-09-14T02:30:25 · Smoke-test both backends
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs/src/ds09-servir-el-modelo
uv run --python 3.14 --with 'fastapi==0.141.1' --with 'uvicorn==0.52.4' --with 'onnxruntime==1.30.0' --with httpx2 python -c "
import os; os.environ['AUREA_BACKEND']='onnx'
from fastapi.testclient import TestClient
import serve
c=TestClient(serve.app)
print(c.get('/salud').json())
print(c.post('/riesgo', json={'inasistencias_previas':2,'jueves_tarde':1,'lluvia_mm':12.0,'distancia_km':18.0,'dias_desde_agendamiento':30}).json())" 2>&1 | tail -4
echo "--- y con pickle ---"
uv run --python 3.14 --with 'fastapi==0.141.1' --with 'uvicorn==0.52.4' --with 'scikit-learn==1.9.1' --with httpx2 python -c "
import os; os.environ['AUREA_BACKEND']='pickle'
from fastapi.testclient import TestClient
import serve
c=TestClient(serve.app)
print(c.post('/riesgo', json={'inasistencias_previas':2,'jueves_tarde':1,'lluvia_mm':12.0,'distancia_km':18.0,'dias_desde_agendamiento':30}).json())" 2>&1 | tail -2

# --- 2026-09-14T02:31:38 · Run the serving benchmark over HTTP
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs/src/ds09-servir-el-modelo
time uv run --python 3.14 --with 'fastapi==0.141.1' --with 'uvicorn==0.52.4' --with 'scikit-learn==1.9.1' --with 'onnxruntime==1.30.0' python bench_serving.py --modelos modelos 2>&1 | tail -10

# --- 2026-09-14T02:32:25 · Confirm the cold-start figures are stable
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs/src/ds09-servir-el-modelo
uv run --python 3.14 --with 'fastapi==0.141.1' --with 'uvicorn==0.52.4' --with 'scikit-learn==1.9.1' --with 'onnxruntime==1.30.0' python bench_serving.py --modelos modelos 2>&1 | tail -6
echo "--- import en frío, por separado ---"
uv run --python 3.14 --with 'fastapi==0.141.1' --with 'uvicorn==0.52.4' --with 'scikit-learn==1.9.1' --with 'onnxruntime==1.30.0' python - <<'PY'
import subprocess, sys, time, statistics
for label, code in [("fastapi+uvicorn","import fastapi, uvicorn"),
                    ("+ sklearn","import fastapi, uvicorn, sklearn.linear_model"),
                    ("+ onnxruntime","import fastapi, uvicorn, onnxruntime")]:
    t=[]
    for _ in range(3):
        s=time.perf_counter(); subprocess.run([sys.executable,"-c",code],check=True,capture_output=True); t.append(time.perf_counter()-s)
    t.sort(); print(f"  {label:<20}{statistics.median(t):.2f} s")
PY

# --- 2026-09-14T02:33:07 · Run the pickle demonstration
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs/src/ds09-servir-el-modelo
python3 pickle_danger.py

# --- 2026-09-14T02:33:50 · Run the ds09 test suite
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs/src/ds09-servir-el-modelo
timeout 400 uv run --python 3.14 --with pytest --with 'scikit-learn==1.9.1' --with 'skl2onnx==1.20.0' --with 'onnxruntime==1.30.0' --with 'fastapi==0.141.1' python -m pytest -q 2>&1 | tail -25

# --- 2026-09-14T02:38:52 · Write the ds09 src README
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs/src/ds09-servir-el-modelo
cat > README.md <<'EOF'
# `ds09` · Servir el modelo, y el ⚖️ veredicto del track

Código de la sección [`ds09-servir-el-modelo.md`](../../ds09-servir-el-modelo.md).

| Archivo | Qué es |
|---|---|
| `upstream.py` | Lo que se toma de `ds07` y `ds08`. Ver la nota de nombres, abajo |
| `export.py` | Entrena y exporta a `pickle` y a ONNX, **comprobando que coinciden** |
| `serve.py` | El endpoint `/riesgo` de AgendaAPI, con los dos backends |
| `pickle_danger.py` | 🧨 Diez líneas que demuestran que cargar un `.pkl` ejecuta código |
| `bench_serving.py` | La medición de la sección 6, **sobre HTTP contra un uvicorn real** |
| `test_servir.py` | 10 pruebas: `pytest -q` |

## Correr las cosas

```bash
python ../ds07-scikit-learn/generar_ausentismo.py --salida data
uv run --with scikit-learn==1.9.1 --with skl2onnx==1.20.0 --with onnxruntime==1.30.0 \
       python export.py --datos data --salida modelos
uv run --with fastapi==0.141.1 --with uvicorn==0.52.4 --with scikit-learn==1.9.1 \
       --with onnxruntime==1.30.0 python bench_serving.py --modelos modelos
python pickle_danger.py
```

## El resultado, en una tabla

| Backend | Arranque en frío | p50 | p95 | Artefacto |
|---|---|---|---|---|
| `pickle` + scikit-learn | 1,10 s | 0,90 ms | 1,22 ms | 1,2 KB |
| **ONNX** + onnxruntime | **0,38 s** | **0,71 ms** | **0,99 ms** | **0,5 KB** |

**La latencia no es el argumento** —0,23 ms de diferencia es irrelevante al lado de la red—.
Los argumentos son el arranque (2,9×), la imagen sin scikit-learn, y que **un grafo ONNX no
puede ejecutar código**.

## ⚠️ El exportador se niega a publicar si los formatos no coinciden

```python
if worst > TOLERANCE:
    raise SystemExit(f"El ONNX no coincide con el original: {worst:.2e} > {TOLERANCE:.0e}")
```

La tolerancia es `1e-6` porque ONNX calcula en `float32` y scikit-learn en `float64`. Sobre los
datos de Áurea la diferencia real es **9,44 × 10⁻⁸**. Un modelo exportado que predice distinto
del original es el peor error posible de esta sección: nada falla, y la diferencia aparece en
producción.

## 🧨 `pickle` ejecuta código al cargar

`pickle_danger.py` lo demuestra con un `__reduce__` propio y un efecto inofensivo. Hay una
prueba que **afirma que la vulnerabilidad existe**, porque el día que `pickle` deje de
comportarse así habría que reescribir media sección.

Y la comprobación que más convence, mirando los bytes:

```python
assert b"sklearn" in pickle_bytes      # el .pkl dice qué módulos va a importar
assert b"sklearn" not in onnx_bytes    # el .onnx no menciona ninguno
```

## Sobre el nombre `upstream.py`

Se llamaba `shared.py` y hubo que renombrarlo: `ds08` ya tiene un módulo con ese nombre, el
directorio del script va primero en `sys.path`, y el de aquí tapaba al de allá con un
`ImportError: cannot import name 'HONEST' from 'shared'` que no menciona al archivo culpable.

Es el costo real del atajo de `sys.path` —**el espacio de nombres pasa a ser plano entre las
tres carpetas**— y conviene verlo una vez para saber por qué los proyectos de verdad usan
paquetes.

Los archivos generados no se versionan.
EOF
echo OK

# --- 2026-09-14T02:39:21 · Add ds09 to BENCHMARKS, INSTINTOS and the state docs
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs
python3 - <<'PY'
def sub(path, pairs):
    s=open(path,encoding='utf-8').read()
    for old,new in pairs:
        if s.count(old)!=1: raise SystemExit(f"{path}: {s.count(old)} de {old[:60]!r}")
        s=s.replace(old,new)
    open(path,'w',encoding='utf-8').write(s); print("OK", path)

sub('BENCHMARKS.md', [("""---

## ✍️ Cómo se agregan entradas""", """### ds09 · El endpoint, con `pickle` y con ONNX

**Afirmaba:** que servir el modelo en ONNX arranca más rápido y responde igual o mejor, y que
**la diferencia de latencia es irrelevante** al lado de las dos razones de verdad: el arranque y
lo que hay que tener instalado.

**Condiciones:** FastAPI 0.141.1, uvicorn 0.52.4, scikit-learn 1.9.1, onnxruntime 1.30.0,
skl2onnx 1.20.0. El modelo ganador de `ds08`. **Medición sobre HTTP contra un uvicorn real** con
cliente de `urllib`, 500 peticiones por backend y 50 de calentamiento descartadas. Los dos
backends devuelven la misma probabilidad —diferencia 3,8 × 10⁻⁸—, verificado por prueba.

| Backend | Arranque en frío | p50 | p95 | Artefacto |
|---|---|---|---|---|
| `pickle` + scikit-learn | 1,10 s | 0,90 ms | 1,22 ms | 1,2 KB |
| **ONNX** + onnxruntime | **0,38 s** | **0,71 ms** | **0,99 ms** | **0,5 KB** |

⚖️ **ONNX gana, y no por la latencia.** La diferencia de p95 es de **0,23 ms**: real e
irrelevante al lado de cualquier red, y quien defienda ONNX con ese número pierde la discusión
con razón. Las tres razones que valen: **arranca 2,9× más rápido** —lo que espera un contenedor
que acaba de escalar—, **la imagen no necesita scikit-learn**, y **el artefacto no puede
ejecutar código**, que no es una optimización sino un cambio de categoría de riesgo.

**El umbral:** sirve `pickle` mientras el proceso que escribe el archivo y el que lo carga sean
tuyos y nadie pueda interponerse. En cuanto el modelo cruce una frontera organizativa, viaje por
un bucket o lo produzca alguien que no seas tú, la respuesta es un formato que solo describa
números.

📝 **La primera corrida de todas dio 32 segundos** de arranque para el backend de `pickle`,
porque el sistema de archivos no tenía nada de scikit-learn en caché. La tabla publica la cifra
estable; la nota existe porque en un contenedor recién creado la primera es la que vives. Y no
se midió con carga concurrente: 500 peticiones secuenciales contestan *"¿cuánto tarda una?"*, no
*"¿cuántas aguanta?"*.

→ [`ds09-servir-el-modelo.md`](ds09-servir-el-modelo.md) §6

---

## ✍️ Cómo se agregan entradas""")])

sub('INSTINTOS.md', [("""---

## 🧪 Los reflejos de método""", """### 36. "Serializar es serializar"

Este reflejo viene con una cicatriz que **sí** funciona: en la JVM ya aprendiste que
`ObjectInputStream` sobre datos ajenos es una vulnerabilidad de libro, y por eso hoy mandas
JSON. El problema es que la cicatriz no se dispara con un modelo.

Un `.pkl` no se siente como código: se siente como un binario opaco —*"es el modelo, qué le voy
a validar"*— y viaja por correo, por un bucket compartido o dentro de una imagen que construyó
alguien más. Y `pickle.load` **no lee datos: reconstruye objetos**, y para reconstruirlos ejecuta
lo que el archivo le diga. Diez líneas con un `__reduce__` propio lo demuestran, sin ninguna
advertencia y sin ninguna forma de verlo venir. **No hay validación previa posible:** para saber
qué hay dentro habría que interpretarlo, que es lo que produce el problema.

La regla que sale: **un `.pkl` solo se carga si tu propio proceso lo escribió**, en tu
infraestructura, y nadie pudo tocarlo desde entonces. Todo lo demás se convierte primero a un
formato que solo sepa describir números — y se comprueba mirando los bytes: el `.pkl` lleva
dentro la cadena `sklearn`, el `.onnx` del mismo modelo no menciona ningún módulo. *(`ds09`)*

---

## 🧪 Los reflejos de método""")])

sub('prompts/README.md', [
("| **T13** | `ds09` + cierre del track | El ⚖️ veredicto necesita todas las mediciones hechas, y arrastra `BENCHMARKS.md`, `INSTINTOS.md`, el `README.md` del curso y `0-ESTRUCTURA-CURSO.md` |",
 "| **T13** ✅ | `ds09` + el ⚖️ veredicto del track, cerrada el 13/09/2026: 10 pruebas y la novena medición ejecutada | El ⚖️ veredicto necesita todas las mediciones hechas, y arrastra `BENCHMARKS.md`, `INSTINTOS.md`, el `README.md` del curso y `0-ESTRUCTURA-CURSO.md` |"),
("""> **T10**, `ds05` y `ds06`; **T11**, `ds07`; y **T12**, `ds08`. Ocho secciones publicadas: **los
> dos bloques —Embudo y Ausentismo— con sus proyectos cerrados**. De las nueve mediciones, ocho
> están **ejecutadas** y una en `⏳` —la de `ds05` §6.2, que necesita cinco personas—. La
> siguiente es **T13**: `ds09` y el cierre del track.""",
 """> **T10**, `ds05` y `ds06`; **T11**, `ds07`; **T12**, `ds08`; y **T13**, `ds09`. ✅ **El track
> `ds` está completo**: nueve secciones, los dos proyectos de datos cerrados y su ⚖️ veredicto
> escrito en `ds09` §6.1. De las diez mediciones, **nueve están ejecutadas** y una en `⏳` —la de
> `ds05` §6.2, que necesita cinco personas y no un portátil."""),
])
PY

# --- 2026-09-14T02:39:41 · Close out the track in the state and root documents
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs
python3 - <<'PY'
def sub(path, pairs):
    s=open(path,encoding='utf-8').read()
    for old,new in pairs:
        if s.count(old)!=1: raise SystemExit(f"{path}: {s.count(old)} de {old[:70]!r}")
        s=s.replace(old,new)
    open(path,'w',encoding='utf-8').write(s); print("OK", path)

sub('prompts/prompts-de-tracks-ia-ds.md', [
("| `ds09-servir-el-modelo.md` | Servir el modelo y ⚖️ veredicto | Ausentismo | Latencia en la API: `pickle` ⇄ ONNX |",
 "| `ds09-servir-el-modelo.md` ✅ | Servir el modelo y ⚖️ veredicto | Ausentismo | Latencia en la API: `pickle` ⇄ ONNX — **ejecutada: la latencia no era el argumento** |"),
("""> 🚧 **El track `ds` va por `ds06`, y el bloque del Embudo está cerrado.** T6 dejó los dos
> conjuntos de datos; T7 escribió `ds01` y `ds02`; T8, `ds03`; T9, `ds04`; T10, `ds05` y `ds06`;
> T11, `ds07`; T12, `ds08`. **Ocho de las nueve mediciones están ejecutadas**""",
 """> ✅ **El track `ds` está completo (13/09/2026).** T6 dejó los dos conjuntos de datos; T7
> escribió `ds01` y `ds02`; T8, `ds03`; T9, `ds04`; T10, `ds05` y `ds06`; T11, `ds07`; T12,
> `ds08`; T13, `ds09` y el ⚖️ veredicto. **Nueve de las diez mediciones están ejecutadas**"""),
("""> base que `ds08` tenía que vencer quedó en 0,799 de AUC, y **la red la venció por 0,0125 — lo
> mismo que vale una columna de interacción escrita a mano**, que es el veredicto de `ds08`.
> Siguiente: T13, `ds09` y el cierre del track.""",
 """> base que `ds08` tenía que vencer quedó en 0,799 de AUC, y **la red la venció por 0,0125 — lo
> mismo que vale una columna de interacción escrita a mano**, que es el veredicto de `ds08`. Y
> `ds09` cierra con el del track entero: **los dos proyectos de datos valían la pena y casi
> ninguna de las herramientas modernas que se les asocian era necesaria**, con el umbral de cada
> veredicto escrito. **Lo único pendiente del track es la medición §6.2 de `ds05`.**"""),
])

# los dos documentos de la raíz que el cierre del track arrastra
sub('README.md', [
("""- **Track `ds`** (`ds01`–`ds09`) — Embudo, que mide cuánto cuesta de verdad un paciente
  adquirido; y Ausentismo, que predice el 19% de inasistencia y abre la discusión de qué se hace
  con esa predicción.""",
 """- **Track `ds`** (`ds01`–`ds09`) — Embudo, que mide cuánto cuesta de verdad un paciente
  adquirido; y Ausentismo, que predice el 19% de inasistencia y abre la discusión de qué se hace
  con esa predicción. Cierra con su propio ⚖️ veredicto: **los dos proyectos valían la pena y
  casi ninguna de las herramientas modernas que se les asocian era necesaria**, cada una con el
  umbral en el que esa respuesta cambia."""),
])
PY

# --- 2026-09-14T02:39:48 · Lint the whole track after ds09
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs
rm -rf src/ds0*/data src/ds0*/modelos src/ds0*/__pycache__ src/ds0*/.pytest_cache .pytest_cache 2>/dev/null
echo "=== lint ==="; uvx ruff@0.16.7 check src/ds0* 2>&1 | tail -5
for d in src/ds0*/; do printf "  %-46s" "$(basename $d)"; (cd $d && uvx ruff@0.16.7 check . >/dev/null 2>&1 && echo "OK" || echo "FALLA"); done

# --- 2026-09-14T02:40:02 · Full test sweep of the completed track
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs
echo "=== suites del track ds completo ==="
for d in src/ds01-numpy-y-el-modelo-vectorizado src/ds02-pandas src/ds03-polars-y-el-modelo-lazy src/ds04-embudo; do
  printf "  %-40s" "$(basename $d)"; (cd $d && uv run --python 3.14 --with pytest --with 'numpy==2.5.3' --with 'pandas==3.0.5' --with 'polars==1.44.2' --with 'duckdb==1.5.5' python -m pytest -q 2>&1|tail -1); done
printf "  %-40s" "ds05-visualizacion"; (cd src/ds05-visualizacion && uv run --python 3.14 --with pytest --with 'matplotlib==3.11.2' --with 'plotly==7.0.0' --with 'altair==6.2.2' python -m pytest -q 2>&1|tail -1)
printf "  %-40s" "ds06-notebooks"; (cd src/ds06-notebooks-y-reproducibilidad && timeout 400 uv run --python 3.14 --with pytest --with 'papermill==2.7.0' --with 'jupyterlab==4.6.3' --with 'marimo==0.24.2' python -m pytest -q -p no:warnings 2>&1|tail -1)
printf "  %-40s" "ds07-scikit-learn"; (cd src/ds07-scikit-learn && uv run --python 3.14 --with pytest --with 'scikit-learn==1.9.1' python -m pytest -q 2>&1|tail -1)
printf "  %-40s" "ds08-ausentismo"; (cd src/ds08-ausentismo && timeout 500 uv run --python 3.14 --with pytest --with 'torch==2.14.0' --with 'scikit-learn==1.9.1' python -m pytest -q 2>&1|tail -1)
printf "  %-40s" "ds09-servir-el-modelo"; (cd src/ds09-servir-el-modelo && timeout 500 uv run --python 3.14 --with pytest --with 'scikit-learn==1.9.1' --with 'skl2onnx==1.20.0' --with 'onnxruntime==1.30.0' --with 'fastapi==0.141.1' python -m pytest -q 2>&1|tail -1)

# --- 2026-09-14T02:41:09 · Final verification of the completed track
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs
rm -rf src/ds0*/data src/ds0*/modelos src/ds0*/__pycache__ src/ds0*/.pytest_cache .pytest_cache 2>/dev/null
python3 - <<'PY'
import re,os
bad=[]
for root,d,fs in os.walk('.'):
    if 'pytest_cache' in root: continue
    for f in fs:
        if not f.endswith('.md'): continue
        p=os.path.join(root,f)
        for i,l in enumerate(open(p,encoding='utf-8'),1):
            for m in re.finditer(r'\]\((?!https?:)([^)#]+\.md)(?:#[^)]*)?\)',l):
                t=m.group(1)
                if not os.path.exists(os.path.normpath(os.path.join(root,t))): bad.append(f"{p}:{i} -> {t}")
print("links rotos:", "\n".join(bad) or "ninguno")
PY
echo; wc -l ds0*.md | tail -11
echo; ls src/ | grep "^ds" | wc -l | xargs echo "directorios ds en src:"

# --- 2026-09-14T02:41:29 · Record the completed track in memory
cd /Users/oskar/.claude/projects/-Users-oskar-Developer-Learning-courses-ia-generated/memory
python3 - <<'PY'
p='python-java-devs-estado.md'; s=open(p,encoding='utf-8').read()
old="**Lo siguiente es T13: `ds09` y el cierre del track.**"
new="""**T13 cerrada el 13/09/2026, y con ella el track `ds` entero**: `ds09-servir-el-modelo.md`
(701 líneas) con `export.py`, `serve.py`, `pickle_danger.py`, `bench_serving.py`, `upstream.py`
y 10 pruebas. Medido **sobre HTTP contra un uvicorn real**: `pickle` arranca en 1,10 s y responde
1,22 ms de p95; ONNX, 0,38 s y 0,99 ms, con artefacto de 0,5 KB contra 1,2. **La latencia no es
el argumento** —0,23 ms al lado de la red— y decirlo así es parte del veredicto: los argumentos
son el arranque 2,9×, la imagen sin scikit-learn y que un grafo ONNX **no puede ejecutar
código**. `pickle_danger.py` lo demuestra con un `__reduce__` propio, y hay una prueba que
**afirma que la vulnerabilidad existe**. El exportador se niega a publicar si los dos formatos no
coinciden (tolerancia 1e-6; diferencia real 9,44e-08).

**Estado del curso: las 18 fases del camino base, el track `ia` (8 secciones) y el track `ds`
(9) están escritos.** El `ds` suma 6.308 líneas de prosa, 176 pruebas que pasan y **nueve de sus
diez mediciones ejecutadas**; la única en `⏳` es la §6.2 de `ds05` —tiempo hasta la primera
decisión correcta— porque necesita cinco personas y no un portátil.

El ⚖️ veredicto del track está en `ds09` §6.1: **los dos proyectos de datos valían la pena y
casi ninguna de las herramientas modernas que se les asocian era necesaria**, cada una con su
umbral escrito —la red neuronal (`ds08`), los motores de consulta a la escala de Áurea (`ds03`),
el tablero interactivo (`ds05`) y los cuadernos como entregable (`ds06`)—.

Dos tropiezos de T13: `shared.py` de `ds09` **tapaba** al de `ds08` (el directorio del script va
primero en `sys.path`), así que se renombró a `upstream.py` y quedó documentado como el costo
real del atajo; y la primera corrida del benchmark dio **32 s** de arranque para `pickle` por
caché de disco frío, contra 1,10 s estables — se publica la estable con la nota.

**Lo que sigue después del track `ds`** es el material *a la carta* (~23 tracks opcionales),
inventariado en `prompts/propuestas-temas-opcionales.md` §19, más las dos deudas declaradas: el
lint de las 17 líneas de `ia03`–`ia08` y la Fase 13 (`prompts/README.md`, sección de deuda), y
`prompts/check-inventario.py`."""
assert s.count(old)==1
open(p,'w',encoding='utf-8').write(s.replace(old,new)); print("OK memoria")
PY

# --- 2026-09-14T02:44:38 · Grep for references to other courses and the root CLAUDE.md
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs
echo "=== 1. Otros cursos del proyecto ==="
grep -rniE "go-for-java-devs|c-sharp-for-java-devs|csharp|curso hermano|curso de C#|angular|docker-container|cursos-algoritmos|propuestas-cursos|_oskar|ruta-nosql|cursos-<|otro curso|los demás cursos" --include=*.md --include=*.py --include=*.toml . 2>/dev/null | grep -v pytest_cache
echo "--- (vacío = bien) ---"
echo
echo "=== 2. CLAUDE.md y la raíz del proyecto ==="
grep -rniE "CLAUDE\.md|courses-ia-generated|directorio raíz del proyecto|repositorio de cursos" --include=*.md --include=*.py --include=*.toml . 2>/dev/null | grep -v pytest_cache
echo "--- (vacío = bien) ---"

# --- 2026-09-14T02:44:44 · Grep correctly for external references
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs
echo "=== 1. Otros cursos del proyecto ==="
grep -rniE "go-for-java-devs|c-sharp-for-java|csharp|curso hermano|curso de C#|angular|docker-container|cursos-algoritmos|propuestas-cursos|_oskar|ruta-nosql|otro curso|los demás cursos|curso de Go" . 2>/dev/null | grep -v pytest_cache | grep -v "^Binary"
echo "--- fin ---"
echo
echo "=== 2. CLAUDE.md / raíz del proyecto ==="
grep -rniE "claude\.md|courses-ia-generated|repositorio de cursos" . 2>/dev/null | grep -v pytest_cache | grep -v "^Binary"
echo "--- fin ---"

# --- 2026-09-14T02:44:59 · Read the contexts of the external references
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs
echo "=== propuesta-fases-y-alcance.md:36-42 ==="; sed -n 36,42p prompts/propuesta-fases-y-alcance.md
echo; echo "=== :96-113 ==="; sed -n 96,113p prompts/propuesta-fases-y-alcance.md
echo; echo "=== :526-532 ==="; sed -n 526,532p prompts/propuesta-fases-y-alcance.md
echo; echo "=== :816-820 ==="; sed -n 816,820p prompts/propuesta-fases-y-alcance.md
echo; echo "=== tracks:425-432 ==="; sed -n 425,432p prompts/prompts-de-tracks-ia-ds.md
echo; echo "=== alcance:183-188 ==="; sed -n 183,188p prompts/alcance-del-proyecto.md

# --- 2026-09-14T02:45:19 · Read the course's own self-containment rule
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs
echo "=== la regla propia del curso ==="; sed -n 625,635p prompts/guia-de-estilo-y-convenciones.md; echo "..."; sed -n 660,666p prompts/guia-de-estilo-y-convenciones.md
echo; echo "=== y la del alcance §0 ==="; sed -n 33,42p prompts/alcance-del-proyecto.md

# --- 2026-09-14T02:45:53 · Remove the four references to sibling courses
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs
python3 - <<'PY'
def sub(path, pairs):
    s=open(path,encoding='utf-8').read()
    for old,new in pairs:
        if s.count(old)!=1: raise SystemExit(f"{path}: {s.count(old)} de {old[:70]!r}")
        s=s.replace(old,new)
    open(path,'w',encoding='utf-8').write(s); print("OK", path)

sub('prompts/propuesta-fases-y-alcance.md', [
# 1. la nota de origen, que hablaba de otro curso del proyecto
("""> 📝 **Y una nota de origen.** El curso de Go partió de un esqueleto producido por otro modelo
> y se fue ordenando sobre la marcha. Aquí la estructura viene **antes** que el contenido: el
> alcance, la guía de estilo, la plantilla y el formato de miniproyectos ya están escritos, y
> este documento es el último eslabón que falta para empezar a redactar.""",
 """> 📝 **Y una nota de método.** Aquí la estructura viene **antes** que el contenido: el alcance,
> la guía de estilo, la plantilla y el formato de miniproyectos ya están escritos, y este
> documento es el último eslabón que falta para empezar a redactar. Ordenar sobre la marcha es
> la alternativa, y produce un temario que hay que renumerar tres veces."""),
# 2. la comparación sostenida contra otro curso
("""> 🧭 **Esta secuencia no es la del curso de Go con otros nombres.** Se diseñó desde las
> necesidades de este curso, y la prueba está en las fases que aquí existen y allá no tendrían
> sentido, y en las que allá existen y aquí se fueron al material opcional.

Lo que este curso necesita y el de Go no:

- **La frontera de Go es la versión del lenguaje; la de Python es el empaquetado.** Allá
  "migrar a Go moderno" es una fase; aquí el equivalente no existe, y en su lugar el Bloque B
  es donde vive la tesis.
- **Go entrega un binario y se acabó la conversación.** Python no, y por eso hay una fase
  entera —la 09— dedicada a **entregarle la herramienta a alguien que no es ingeniero**. Es la
  fase que más se parece al trabajo real del lector después del curso, y no tiene ningún
  análogo en un curso de Go.
- **Python tiene dos registros web legítimos y Go no.** La fase 12 existe para que la
  comparación se viva en vez de leerse.""",
 """> 🧭 **Esta secuencia se diseñó desde las necesidades de Python**, no calcando el temario de
> otro lenguaje. La prueba está en las tres fases que solo tienen sentido aquí:

- **La frontera de Python es el empaquetado.** En un lenguaje que compila a un binario, la
  frontera sería la versión del compilador o el modelo de módulos; aquí es el momento en que un
  script deja de caber en un archivo, y por eso el Bloque B es donde vive la tesis.
- **Python no entrega un binario y se acabó la conversación.** Por eso hay una fase entera —la
  09— dedicada a **entregarle la herramienta a alguien que no es ingeniero**, que es la que más
  se parece al trabajo real del lector después del curso.
- **Python tiene dos registros web legítimos.** La fase 12 existe para que la comparación entre
  FastAPI y Django se viva en vez de leerse."""),
# 3. la justificación de forma con el nombre de otro curso
("| Convención de git y tags | `00-convencion-de-git-y-tags.md`, en la raíz del curso — no es apéndice, es un documento de encuadre que el lector sí lee, igual que en `go-for-java-devs` |",
 "| Convención de git y tags | `00-convencion-de-git-y-tags.md`, en la raíz del curso — no es apéndice: es un documento de encuadre que el lector sí abre, antes de la Fase 00 |"),
# 4. y la fase 09, que volvía a apoyarse en la comparación
("""**Propósito.** La fase que no existe en un curso de Go y que más se parece al trabajo real del
lector: entregar software a alguien que no es ingeniero, en una máquina que no controlas.""",
 """**Propósito.** La fase que más se parece al trabajo real del lector: entregar software a
alguien que no es ingeniero, en una máquina que no controlas. En un lenguaje que produce un
binario estático esta conversación no existe; en Python es media docena de decisiones."""),
])

sub('prompts/prompts-de-tracks-ia-ds.md', [
("""1. **Las mediciones van con `⏳` hasta que alguien las corra.** Es la misma decisión que tomó el
   curso hermano de C#, y aquí pesa más porque tres de estas mediciones cuestan dinero real. Cada
   sección deja la spec completa y el comando; el número entra después, y `BENCHMARKS.md` marca
   cuáles están pendientes.""",
 """1. **Las mediciones van con `⏳` hasta que alguien las corra.** La alternativa —publicar una
   cifra plausible y corregirla después— es exactamente lo que un curso que se define por medir
   no puede hacer, y aquí pesa más porque tres de estas mediciones cuestan dinero real. Cada
   sección deja la spec completa y el comando; el número entra después, y `BENCHMARKS.md` marca
   cuáles están pendientes."""),
])
PY

# --- 2026-09-14T02:46:03 · Verify no external references remain
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs
echo "=== ¿queda alguna cita a otro curso? ==="
grep -rniE "go-for-java|c-sharp|curso hermano|el curso de Go|curso de C#|cursos-|/Users/oskar/Developer" . 2>/dev/null | grep -v pytest_cache
echo "--- fin ---"
echo
echo "=== referencias genéricas que sobreviven (deben ser de género, no de proyecto) ==="
grep -rn "curso de Go\|otro curso\|curso de Angular" . 2>/dev/null | grep -v pytest_cache
echo
echo "=== rutas fuera de la carpeta del curso ==="
grep -rnE "\.\./\.\./\.\.|~/Developer|/Users/(?!marcela)" --include="*.md" . 2>/dev/null | grep -v pytest_cache | head
grep -rn "/Users/" . 2>/dev/null | grep -v pytest_cache | grep -v "marcela" | head

# --- 2026-09-14T02:46:17 · Check the dependency chain across both tracks
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs
echo "=== cadena Depende/Habilita y numeración de los tracks ==="
for f in ia0*.md ds0*.md; do printf "%-40s" "$f"; sed -n '3,6p' $f | tr '\n' ' ' | sed 's/> //g' | cut -c1-135; echo; done

# --- 2026-09-14T02:46:39 · Cross-check figures cited between sections
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs
echo "=== cifras que una sección cita de otra ==="
echo "-- CAC de ds01/ds04 citado fuera:"; grep -rn "siete veces\|seis veces\|9.394.725\|11.098.164\|1.583.564" ds0*.md BENCHMARKS.md INSTINTOS.md | grep -v pytest
echo; echo "-- la banda de ds04 (1,06 / 7,96 / 7,5×):"; grep -rn "7,5×\|7.96\|1,06" ds0*.md BENCHMARKS.md INSTINTOS.md | head -12
echo; echo "-- la línea base de ds07 (0,799 / 0,526):"; grep -rn "0,799\|0,526\|0.799" ds0*.md BENCHMARKS.md INSTINTOS.md | head -12
echo; echo "-- el 77 MB de ds02 citado en ds03:"; grep -rn "76,9 MB\|77 MB" ds0*.md BENCHMARKS.md | head

# --- 2026-09-14T02:46:49 · Check INSTINTOS numbering and the ia measurement claim
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs
echo "=== numeración de INSTINTOS ==="; grep -nE "^### [0-9]+\." INSTINTOS.md | awk -F'[.#]' '{print $0}' | sed 's/\(### [0-9]*\).*/\1/' | tr '\n' ' '; echo
echo; echo "=== la afirmación de las mediciones ia en BENCHMARKS ==="; sed -n '/Complementos `ia` — pendientes/,+10p' BENCHMARKS.md | head -12
echo; echo "=== filas de la tabla ia ==="; sed -n '/| Sección | Qué compara | Estado |/,/^$/p' BENCHMARKS.md | grep -c "^| \[" 

# --- 2026-09-14T02:47:04 · Count reflexes per block and find stale count claims
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs
echo "=== encabezados de sección de INSTINTOS y su frase de conteo ==="
grep -n -A3 "^## 🤖 Los reflejos del track de IA\|^## 📊 Los reflejos del track de datos\|^## 🧪 Los reflejos de método" INSTINTOS.md | head -20
echo; echo "=== cuántos reflejos hay en cada bloque ==="
python3 - <<'PY'
import re
lines=open('INSTINTOS.md',encoding='utf-8').read().splitlines()
block=None; counts={}
for l in lines:
    if l.startswith('## '): block=l.strip()
    if re.match(r'^### \d+\.', l) or (block and 'método' in block and l.startswith('### ')):
        counts[block]=counts.get(block,0)+1
for k,v in counts.items(): print(f"  {v:>2}  {k}")
PY
echo; echo "=== claims de conteo en README y ESTRUCTURA ==="
grep -n "dieciocho mediciones\|dieciocho reflejos\|18 mediciones" README.md 0-ESTRUCTURA-CURSO.md BENCHMARKS.md INSTINTOS.md | head

# --- 2026-09-14T02:47:14 · Read INSTINTOS intro and count the base reflexes
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs
sed -n 1,20p INSTINTOS.md
echo "=== los 18 del camino base ==="; python3 -c "
import re
lines=open('INSTINTOS.md',encoding='utf-8').read().splitlines()
base=[l for l in lines[:400] if re.match(r'^## \d+\.', l)]
print(len(base), 'reflejos de camino base ·', base[0], '...', base[-1])"

# --- 2026-09-14T02:47:31 · Fix the stale counts in INSTINTOS and BENCHMARKS
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs
python3 - <<'PY'
def sub(path, pairs):
    s=open(path,encoding='utf-8').read()
    for old,new in pairs:
        if s.count(old)!=1: raise SystemExit(f"{path}: {s.count(old)} de {old[:70]!r}")
        s=s.replace(old,new)
    open(path,'w',encoding='utf-8').write(s); print("OK", path)

sub('INSTINTOS.md', [
# el intro, que solo hablaba de las 18 fases
("""Este documento recoge los reflejos que aparecieron a lo largo de las dieciocho fases: qué te
empuja a escribir tu experiencia previa, por qué eso era correcto donde lo aprendiste, y qué se
escribe en su lugar aquí.""",
 """Este documento recoge los reflejos que aparecieron a lo largo del curso —las dieciocho fases del
camino base y las diecisiete secciones de los complementos `ia` y `ds`—: qué te empuja a escribir
tu experiencia previa, por qué eso era correcto donde lo aprendiste, y qué se escribe en su lugar
aquí. Son **treinta y seis**, más cuatro de método."""),
# el bloque ia decía cinco y son ocho
("""Los cinco que aparecieron al construir NormaRAG y Recepción asistida. Van aparte porque el lector
llega a ellos con las dieciocho fases hechas, y porque todos nacen de una misma raíz: **tratar a un
modelo como si fuera una función**.""",
 """Los ocho que aparecieron al construir NormaRAG y Recepción asistida. Van aparte porque el lector
llega a ellos con las dieciocho fases hechas, y porque todos nacen de una misma raíz: **tratar a un
modelo como si fuera una función**."""),
# el bloque ds decía dos y son diez, y cubren los dos proyectos
("""Los dos que aparecieron al construir el Embudo. Nacen de la misma raíz —**pensar en filas**— y se
corrigen con la misma pregunta: *¿de dónde vienen estos datos y cuántas cuentas voy a hacer con
ellos?*""",
 """Los diez que aparecieron al construir el Embudo y Ausentismo. Los cuatro primeros nacen de la
misma raíz —**pensar en filas**— y se corrigen con la misma pregunta: *¿de dónde vienen estos
datos y cuántas cuentas voy a hacer con ellos?*. Los seis últimos son de otra familia y aparecen
cuando el análisis deja de describir y empieza a **decidir**: qué se compara, qué se calibra, qué
se despliega y qué se hace con una predicción sobre una persona."""),
])

sub('BENCHMARKS.md', [
("""> ⏳ **Las seis mediciones del track de IA están especificadas y no ejecutadas.** Cada una tiene su""",
 """> ⏳ **Las nueve mediciones del track de IA están especificadas y, salvo una fila, no ejecutadas.**
> Cada una tiene su"""),
])
PY
sed -n '/Complementos `ia` — pendientes/,+4p' BENCHMARKS.md

# --- 2026-09-14T02:47:40 · Tidy the BENCHMARKS note and inspect its structure
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs
python3 - <<'PY'
p='BENCHMARKS.md'; s=open(p,encoding='utf-8').read()
old="""> ⏳ **Las nueve mediciones del track de IA están especificadas y, salvo una fila, no ejecutadas.**
> Cada una tiene su
> hipótesis, sus condiciones, su competidor y su comando escritos en la sección 📏 de su lección;"""
new="""> ⏳ **Las nueve mediciones del track de IA están especificadas y, salvo una fila, sin ejecutar.**
> Cada una tiene su hipótesis, sus condiciones, su competidor y su comando escritos en su 📏;"""
assert s.count(old)==1
open(p,'w',encoding='utf-8').write(s.replace(old,new)); print("OK")
PY
sed -n '/Complementos `ia` — pendientes/,+9p' BENCHMARKS.md
echo
echo "=== ¿el track ds está anunciado en el índice de BENCHMARKS? ==="
grep -n "^## " BENCHMARKS.md

# --- 2026-09-14T02:47:57 · Mark ds09 as closer and scan for exercises needing external systems
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs
python3 - <<'PY'
def sub(path, pairs):
    s=open(path,encoding='utf-8').read()
    for old,new in pairs:
        if s.count(old)!=1: raise SystemExit(f"{path}: {s.count(old)} de {old[:70]!r}")
        s=s.replace(old,new)
    open(path,'w',encoding='utf-8').write(s); print("OK", path)

sub('ds09-servir-el-modelo.md', [
("> Python para desarrolladores Java senior · Track `ds` · sección 9 de 9",
 "> Python para desarrolladores Java senior · Track `ds` · sección 9 de 9 🏁"),
])
sub('ds01-numpy-y-el-modelo-vectorizado.md', [
("> Depende de: Fase 02 (el arnés), Fase 06 (formatos), Fase 07 (`uv`) · Habilita: `ds02`",
 "> Depende de: Fase 02 (el arnés), Fase 06 (formatos), Fase 07 (`uv`) · Habilita: `ds02`\n> El track `ds` **no necesita el track `ia`**: los dos arrancan desde el camino base."),
])
PY
echo "=== ejercicios o material que exija un sistema externo ==="
grep -rniE "descarga[rs]?|baja[rt]e?|kaggle|dataset público|internet|api key|token|cuenta en|regístrate|suscríb" ds0*.md ia0*.md 2>/dev/null | grep -viE "descargar el modelo la primera vez|sin internet|necesita internet|deja de funcionar sin internet|para dibujarse|carga Vega|cdn" | head -20

# --- 2026-09-14T02:48:18 · Fix the measurement counts in ds09
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs
grep -n "ocho mediciones\|nueve mediciones\|8 mediciones\|9 secciones" ds09-servir-el-modelo.md
python3 - <<'PY'
def sub(path, pairs):
    s=open(path,encoding='utf-8').read()
    for old,new in pairs:
        if s.count(old)!=1: raise SystemExit(f"{path}: {s.count(old)} de {old[:70]!r}")
        s=s.replace(old,new)
    open(path,'w',encoding='utf-8').write(s); print("OK", path)

sub('ds09-servir-el-modelo.md', [
("""Y después cierra el track: de los dos proyectos de datos que Áurea tenía planteados, **cuál
valía la pena y cuál no** — con las ocho mediciones de las secciones anteriores sobre la mesa.""",
 """Y después cierra el track: de los dos proyectos de datos que Áurea tenía planteados, **cuál
valía la pena y cuál no** — con las ocho mediciones ya ejecutadas de las secciones anteriores
sobre la mesa."""),
("""Nueve secciones, ocho mediciones ejecutadas y una pendiente. Esto es lo que Áurea se lleva.""",
 """Nueve secciones y diez mediciones: **nueve ejecutadas** y una pendiente —la §6.2 de `ds05`, que
necesita cinco personas—. Esto es lo que Áurea se lleva."""),
("""> git tag -a ds-track -m "Track ds completo: 9 secciones, 8 mediciones ejecutadas\"""",
 """> git tag -a ds-track -m "Track ds completo: 9 secciones, 9 mediciones ejecutadas de 10\""""),
])
PY

# --- 2026-09-14T02:48:28 · Audit exercises for external systems and unpinned tools
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs
echo "=== ejercicios que exijan un servicio externo o datos de fuera ==="
grep -rnE "^[0-9]+\. |^   " ds0*.md | grep -iE "un repositorio (público|de verdad|real)|tu propio trabajo|tu equipo|cinco personas|tu máquina|disco externo|volumen de red|Postgres" | head -12
echo
echo "=== ¿algún ejercicio pide instalar algo no fijado en alcance §9? ==="
grep -rnoE "\b(xgboost|lightgbm|dask|spark|ray|streamlit|dash|panel|shap|lime|jupytext|nbstripout|netron|seaborn|statsmodels|pyarrow|httpx|marimo)\b" ds0*.md | sort -t: -k3 | awk -F: '{print $3}' | sort | uniq -c | sort -rn

# --- 2026-09-14T02:48:52 · Pin note for nbstripout and check for stray files
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs
sed -n '/13. Configura `nbstripout`/,+2p' ds06-notebooks-y-reproducibilidad.md
python3 - <<'PY'
def sub(path, pairs):
    s=open(path,encoding='utf-8').read()
    for old,new in pairs:
        if s.count(old)!=1: raise SystemExit(f"{path}: {s.count(old)} de {old[:70]!r}")
        s=s.replace(old,new)
    open(path,'w',encoding='utf-8').write(s); print("OK", path)
sub('ds06-notebooks-y-reproducibilidad.md', [
("""13. Configura `nbstripout` en un repositorio de prueba y comprueba qué pasa al hacer commit
    de un cuaderno con salidas. Decide si lo pondrías en el repositorio de Áurea.""",
 """13. Configura `nbstripout` en un repositorio de prueba y comprueba qué pasa al hacer commit
    de un cuaderno con salidas. Decide si lo pondrías en el repositorio de Áurea. **No está en
    las versiones fijadas del curso**: si lo instalas, fija tú la suya y anótala, que es
    exactamente la disciplina de la Fase 07."""),
])
PY
echo; echo "=== archivos sueltos en la carpeta del curso ==="
ls -a | grep -vE "^\.$|^\.\.$"
echo; echo "=== ¿queda basura generada? ==="
find . -name "__pycache__" -o -name ".pytest_cache" -o -name "data" -type d -o -name "modelos" -type d -o -name "salida" -type d -o -name "cuadernos" -type d -o -name "*.pyc" | head

# --- 2026-09-14T02:49:06 · Clean generated files and add a .gitignore
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs
find . \( -name "__pycache__" -o -name ".pytest_cache" -o -name ".ruff_cache" \) -type d -prune -exec rm -rf {} + 2>/dev/null
rm -rf src/*/data src/*/modelos src/*/salida src/*/cuadernos src/*/resultado.json 2>/dev/null
cat > .gitignore <<'EOF'
# Lo que generan los scripts del curso. Cada README de `src/` lo dice: los archivos
# generados no se versionan — se regeneran con su semilla fija, que es el punto.
data/
modelos/
salida/
cuadernos/
resultado.json
*.png
*.html
*.parquet
*.pkl
*.onnx

# El entorno y las cachés de las herramientas.
.venv/
__pycache__/
*.py[cod]
.pytest_cache/
.ruff_cache/
.ipynb_checkpoints/

# El arnés de la Fase 02 se copia a la carpeta de la sección que lo use.
src/ds*/bench.py
EOF
echo "=== convención de tags: ¿conoce los tracks? ==="
grep -n "ia-fase\|ds-fase\|ia-mini\|ds-mini\|complemento\|track" 00-convencion-de-git-y-tags.md | head

# --- 2026-09-14T02:49:15 · Inspect the git convention document
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs
grep -n "^#\|^##\|^###" 00-convencion-de-git-y-tags.md
echo "---"; wc -l 00-convencion-de-git-y-tags.md
echo "=== cuántas secciones prometen esa convención ==="; grep -rc "La convención completa está en" ia0*.md ds0*.md | grep -v ":0"

# --- 2026-09-14T02:49:19 · Read the tags section to extend it
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs
sed -n 89,130p 00-convencion-de-git-y-tags.md

# --- 2026-09-14T02:49:33 · Extend the git convention to cover both tracks
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs
python3 - <<'PY'
def sub(path, pairs):
    s=open(path,encoding='utf-8').read()
    for old,new in pairs:
        if s.count(old)!=1: raise SystemExit(f"{path}: {s.count(old)} de {old[:70]!r}")
        s=s.replace(old,new)
    open(path,'w',encoding='utf-8').write(s); print("OK", path)

sub('00-convencion-de-git-y-tags.md', [
("""## 🏷️ Tags

Dos familias, las dos **anotadas** (`-a`), porque el mensaje es donde vive la información que
después se recupera.""",
 """## 🏷️ Tags

Dos familias por track, todas **anotadas** (`-a`), porque el mensaje es donde vive la
información que después se recupera."""),
("""### Ramas""",
 """### Y los complementos: `ia-fase-NN` y `ds-fase-NN`

Después de la Fase 17, el curso sigue con dos tracks complementarios —`ia01`–`ia08` y
`ds01`–`ds09`— que construyen los cuatro proyectos de IA y de datos de Áurea. **Cierran igual,
con su propio espacio de nombres:**

| | Camino base | Track `ia` | Track `ds` |
|---|---|---|---|
| Tag de sección | `fase-NN` | `ia-fase-NN` | `ds-fase-NN` |
| Tag de miniproyecto | `mini-NN` | `ia-mini-NN` | `ds-mini-NN` |
| Prefijo de commit | `fase NN: …` | `ia NN: …` | `ds NN: …` |
| Ejercicio | `fase NN ejMM: …` | `ia NN ejMM: …` | `ds NN ejMM: …` |

```bash
git tag -a ds-fase-07 -m "ds07 cerrada: <el checklist, una línea por ítem>"
git tag -a ds-mini-07 -m "Mini ds07: lista de Yuli · precisión 0.53 a cupo 20"
```

> 🧭 **Tres espacios de nombres y no uno, por una razón que se cobra el día que los uses:**
> `git tag -l 'fase-*'` devuelve exactamente el camino base, `'ia-*'` y `'ds-*'` cada
> complemento. Con un solo prefijo, esa consulta mezclaría treinta y cinco tags y dejaría de
> servir para orientarse.

La regla del `mini-NN` vale igual en los tres: **en el mensaje va el número que arrojó la
medición**, y es el único sitio donde queda guardado.

Y cuando un track termina, un tag más sin número de sección:

```bash
git tag -a ia-track -m "Track ia completo: 8 secciones"
git tag -a ds-track -m "Track ds completo: 9 secciones, 9 mediciones ejecutadas de 10"
```

### Ramas"""),
])
PY
grep -c "" 00-convencion-de-git-y-tags.md

# --- 2026-09-14T02:49:44 · Read the repository layout section
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs
sed -n 28,69p 00-convencion-de-git-y-tags.md

# --- 2026-09-14T02:49:59 · Verify nothing legit is ignored and extend the reader's gitignore lesson
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs
echo "=== ¿hay archivos que mi .gitignore taparía por error? ==="
find . -name "*.png" -o -name "*.html" -o -name "*.parquet" -o -name "*.pkl" -o -name "*.onnx" | head
echo "(vacío = ninguno)"
python3 - <<'PY'
def sub(path, pairs):
    s=open(path,encoding='utf-8').read()
    for old,new in pairs:
        if s.count(old)!=1: raise SystemExit(f"{path}: {s.count(old)} de {old[:60]!r}")
        s=s.replace(old,new)
    open(path,'w',encoding='utf-8').write(s); print("OK", path)

sub('00-convencion-de-git-y-tags.md', [
("""# Datos de Áurea: entran generados, no versionados (el generador sí se versiona).
data/*.csv
data/*.sqlite3
.env
```""",
 """# Datos de Áurea: entran generados, no versionados (el generador sí se versiona).
data/*.csv
data/*.sqlite3
.env
```

Y cuando llegues a los complementos `ia` y `ds`, esas tres líneas se quedan cortas: los tracks
generan corpus, conjuntos de datos, figuras, cuadernos ejecutados y **artefactos de modelo**.
Todo eso se regenera con su semilla fija, así que tampoco se versiona:

```gitignore
# Lo que generan los scripts de los complementos.
data/
modelos/
salida/
cuadernos/
*.parquet
*.png
*.html

# Artefactos de modelo. Y hay una segunda razón para esta línea, además del peso:
# un `.pkl` es código ejecutable, y un binario ejecutable que entra al repositorio
# sin que nadie lo revise es exactamente el problema que estudia `ds09`.
*.pkl
*.onnx
```"""),
])
PY

# --- 2026-09-14T02:50:06 · Check the structure document against the final state
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs
echo "=== 0-ESTRUCTURA: ¿describe el estado final de los complementos? ==="
sed -n '/Los \*\*complementos `ia` y `ds`\*\*/,+14p' 0-ESTRUCTURA-CURSO.md
echo
echo "=== ¿el README del curso y ESTRUCTURA se contradicen en conteos? ==="
grep -n "diecisiete\|17 secciones\|dieciocho fases\|18 fases" README.md 0-ESTRUCTURA-CURSO.md prompts/README.md | head

# --- 2026-09-14T02:50:22 · Final verification of links, references and lint
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs
echo "=== 1. links rotos (internos) ==="
python3 - <<'PY'
import re,os
bad=[]
for root,d,fs in os.walk('.'):
    if any(x in root for x in ('pytest_cache','ruff_cache','__pycache__')): continue
    for f in fs:
        if not f.endswith('.md'): continue
        p=os.path.join(root,f)
        for i,l in enumerate(open(p,encoding='utf-8'),1):
            for m in re.finditer(r'\]\((?!https?:)([^)#]+)(?:#[^)]*)?\)',l):
                t=m.group(1)
                if not os.path.exists(os.path.normpath(os.path.join(root,t))): bad.append(f"{p}:{i} -> {t}")
print("\n".join(bad) or "  ninguno")
PY
echo; echo "=== 2. referencias a otros cursos / CLAUDE.md / rutas del proyecto ==="
grep -rniE "go-for-java|c-sharp|csharp|curso hermano|el curso de go|claude\.md|courses-ia-generated|cursos-algoritmos" . 2>/dev/null | grep -vE "ruff_cache|pytest_cache" || echo "  ninguna"
echo; echo "=== 3. lint con la configuración del propio curso ==="
uvx ruff@0.16.7 check src/ && echo "  todo el src limpio" || echo "  (quedan los 17 avisos declarados del camino base y del track ia)"

# --- 2026-09-14T02:50:46 · Check which offending lines are transcribed in the chapters
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs
echo "=== ¿están transcritas en la prosa? ==="
for pat in "received.clear(); processed_keys.clear()" "_find_availability(agenda, branch" "from contextlib import contextmanager" "preguntas anotadas ({', '.join" "from answer import DraftAnswer, SYSTEM" "path.read_text(encoding=\"utf-8\") for path in sorted" "Omite el competidor 1" "from datetime import date" "pypdf devuelve vacío ante un escaneado" "zip(a, b))" "Requiere autorización previa" "zip(a, b) if x == y" "overrides: object"; do
  hits=$(grep -rl -- "$pat" ./*.md 2>/dev/null | tr '\n' ' ')
  printf "%-52s %s\n" "${pat:0:50}" "${hits:-—}"
done

# --- 2026-09-14T02:50:59 · Read the two contexts needing coordinated fixes
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs
echo "=== ia03 agent_runner: la inyección ==="; sed -n 10,16p src/ia03-tool-calling-y-el-bucle-de-agente/agent_runner.py
echo "--- y en la prosa:"; grep -n -B2 -A2 "_find_availability(agenda, branch" ia03-tool-calling-y-el-bucle-de-agente.md
echo; echo "=== ia06 statistics_helpers ==="; sed -n 18,28p src/ia06-evaluacion/statistics_helpers.py
echo "--- y en la prosa:"; grep -n -B3 -A2 "zip(a, b) if x == y" ia06-evaluacion.md

# --- 2026-09-14T02:51:17 · Fix the coordinated code and prose lint errors
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs
python3 - <<'PY'
def sub(path, pairs, count=1):
    s=open(path,encoding='utf-8').read()
    for old,new in pairs:
        if s.count(old)!=count: raise SystemExit(f"{path}: {s.count(old)} de {old[:60]!r}")
        s=s.replace(old,new)
    open(path,'w',encoding='utf-8').write(s); print("OK", path)

# --- 1. E702: tres sentencias con punto y coma (código + prosa) ---
for p in ('src/13-integraciones/socio_falible.py', '13-integraciones.md'):
    sub(p, [("                received.clear(); processed_keys.clear(); attempts.clear()",
             "                received.clear()\n                processed_keys.clear()\n                attempts.clear()")])

# --- 2. B905: zip sin strict (código + prosa) ---
for p in ('src/ia06-evaluacion/statistics_helpers.py', 'ia06-evaluacion.md'):
    sub(p, [("    return sum(1 for x, y in zip(a, b) if x == y) / len(a)",
             "    # `strict=True` es redundante con la comprobación de largos de arriba, y se pone\n"
             "    # igual: si alguien borra esa comprobación, el error sale aquí en vez de dar un\n"
             "    # acuerdo calculado sobre la serie más corta.\n"
             "    return sum(1 for x, y in zip(a, b, strict=True) if x == y) / len(a)")])

sub('src/ia06-evaluacion/bench_judges.py', [
("    similarity = sum(x * y for x, y in zip(a, b))",
 "    similarity = sum(x * y for x, y in zip(a, b, strict=True))")])

# --- 3. F821: la inyección de módulo de ia03 (código + prosa) ---
sub('src/ia03-tool-calling-y-el-bucle-de-agente/agent_runner.py', [
("""agenda: AgendaClient  # se inyecta al arrancar el proceso""",
 """# La agenda se inyecta al arrancar el proceso. Se declara con valor `None` y no solo con la
# anotación: una anotación suelta no crea el nombre, así que el módulo se importaría bien y
# fallaría con `NameError` en la primera llamada de la herramienta —a las siete de la mañana y
# dentro del bucle del agente, que es el peor sitio para enterarse—.
agenda: AgendaClient | None = None"""),
("    return _find_availability(agenda, branch, day, minutes)",
 """    if agenda is None:
        raise RuntimeError("La agenda no se inyectó: asigna `agent_runner.agenda` al arrancar.")
    return _find_availability(agenda, branch, day, minutes)"""),
])
sub('ia03-tool-calling-y-el-bucle-de-agente.md', [
("    return _find_availability(agenda, branch, day, minutes)",
 """    if agenda is None:
        raise RuntimeError("La agenda no se inyectó: asigna `agent_runner.agenda` al arrancar.")
    return _find_availability(agenda, branch, day, minutes)"""),
])

# --- 4. UP037 + F821 en ia08 ---
sub('src/ia08-produccion-y-el-veredicto/test_produccion.py', [
('def evento(**overrides: object) -> "Event":\n    from datetime import datetime\n\n    from telemetry import BOGOTA, Event, fingerprint',
 'def evento(**overrides: object):\n    """Construye un `Event` de telemetry. Sin anotación de retorno a propósito: el tipo se\n    importa dentro para que este archivo se pueda leer sin el módulo instalado."""\n    from datetime import datetime\n\n    from telemetry import BOGOTA, Event, fingerprint')])
PY

# --- 2026-09-14T02:51:24 · Autofix the rest and see what remains
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs
uvx ruff@0.16.7 check --fix src/ >/dev/null 2>&1
echo "=== lo que queda ==="; uvx ruff@0.16.7 check src/ --output-format concise

# --- 2026-09-14T02:51:37 · Wrap the long lines and verify the whole src is clean
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs
python3 - <<'PY'
def sub(path, pairs):
    s=open(path,encoding='utf-8').read()
    for old,new in pairs:
        if s.count(old)!=1: raise SystemExit(f"{path}: {s.count(old)} de {old[:60]!r}")
        s=s.replace(old,new)
    open(path,'w',encoding='utf-8').write(s); print("OK", path)

sub('src/ia04-embeddings-y-busqueda-semantica/generar_corpus.py', [
("""    print(f"{len(annotated)} preguntas anotadas ({', '.join(sorted(kinds))}) en {args.preguntas_salida}")
    print(f"Derogados: {sum(1 for r in manifest if r['vigente_hasta'])} fragmentos de {len(manifest)}")""",
 """    print(f"{len(annotated)} preguntas anotadas ({', '.join(sorted(kinds))}) "
          f"en {args.preguntas_salida}")
    derogados = sum(1 for r in manifest if r["vigente_hasta"])
    print(f"Derogados: {derogados} fragmentos de {len(manifest)}")""")])

sub('src/ia05-normarag/bench_answers.py', [
('    return "\\n\\n".join(path.read_text(encoding="utf-8") for path in sorted(corpus_dir.glob("*.txt")))',
 '    return "\\n\\n".join(path.read_text(encoding="utf-8")\n                       for path in sorted(corpus_dir.glob("*.txt")))'),
('        help="Omite el competidor 1. Es el más caro de los cuatro: paga el corpus entero por pregunta.",',
 '        help="Omite el competidor 1. Es el más caro de los cuatro: paga el corpus "\n             "entero por pregunta.",')])

sub('src/ia05-normarag/test_normarag.py', [
('    """pypdf devuelve vacío ante un escaneado y no lanza nada. Ese silencio se convierte en señal."""',
 '    """pypdf devuelve vacío ante un escaneado y no lanza nada: ese silencio se vuelve señal."""')])

sub('src/ia06-evaluacion/generar_evalset.py', [
('        " Requiere autorización previa." if row["autorizacion_previa"] else " No requiere autorización previa."',
 '        " Requiere autorización previa." if row["autorizacion_previa"]\n        else " No requiere autorización previa."')])
PY
echo "=== lint final de todo src/ ==="; uvx ruff@0.16.7 check src/ && echo "  ✅ limpio"

# --- 2026-09-14T02:51:49 · Run the ia track test suites after the code edits
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs/src
for d in ia0*/; do
  printf "  %-46s" "$(basename $d)"
  (cd $d && timeout 300 uv run --python 3.14 --with pytest --with 'anthropic==1.5.0' --with 'pydantic==2.13.5' --with 'tenacity==9.1.4' python -m pytest -q 2>&1 | tail -1)
done

# --- 2026-09-14T02:52:12 · Diagnose the ia failures
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs/src
echo "=== ia04 ==="; (cd ia04-embeddings-y-busqueda-semantica && timeout 200 uv run --python 3.14 --with pytest --with 'anthropic==1.5.0' python -m pytest -q 2>&1 | grep -E "Error|error" | head -3)
echo "=== ia05 ==="; (cd ia05-normarag && timeout 200 uv run --python 3.14 --with pytest --with 'anthropic==1.5.0' --with 'pydantic==2.13.5' python -m pytest -q 2>&1 | grep -E "Error|error" | head -3)
echo "=== ia01 ==="; (cd ia01-el-modelo-de-acceso-de-un-llm && timeout 200 uv run --python 3.14 --with pytest --with 'anthropic==1.5.0' python -m pytest -q 2>&1 | grep -E "^FAILED|Error" | head -4)

# --- 2026-09-14T02:52:33 · Investigate the two real defects
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs/src
echo "=== ia05: de dónde sale 'extract' ==="; grep -n "^from\|^import" ia05-normarag/test_normarag.py | head
echo "--- ¿lo dice su README? ---"; grep -n "extract\|ia02\|PYTHONPATH\|pytest" ia05-normarag/README.md | head
echo; echo "=== ia01: las dos pruebas que fallan ==="; grep -n "def test_" ia01-el-modelo-de-acceso-de-un-llm/test_failures.py
echo "--- ¿qué dice su README? ---"; grep -n "pytest\|sin red\|API" ia01-el-modelo-de-acceso-de-un-llm/README.md | head

# --- 2026-09-14T02:52:45 · Inspect the network-marked tests
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs/src/ia01-el-modelo-de-acceso-de-un-llm
sed -n 1,35p test_failures.py
echo "=== ¿hay configuración de marcadores? ==="; ls -a | grep -iE "pytest|conftest|ini|toml" || echo "  ninguna"

# --- 2026-09-14T02:53:01 · Add pytest.ini registering the network marker
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs
cat > pytest.ini <<'EOF'
# Configuración de pytest para todo el curso, hermana de `ruff.toml`.
#
# El curso promete que sus pruebas corren **sin red, sin modelo y sin base de datos**. Esa
# promesa necesitaba esta declaración: sin ella, `pytest` no conoce el marcador `network`,
# lo avisa como desconocido y **ejecuta igual** las pruebas que llaman a la API — que
# fallan sin credenciales y cuestan dinero con ellas.
#
# Para correr a propósito las que sí llaman a la API:
#     pytest -m network

[pytest]
markers =
    network: llama a la API de Claude. Cuesta dinero y no corre en el ciclo normal.
addopts = -m "not network"
EOF
echo "=== ia01 con la configuración puesta ==="
(cd src/ia01-el-modelo-de-acceso-de-un-llm && uv run --python 3.14 --with pytest --with 'anthropic==1.5.0' python -m pytest -q 2>&1 | tail -2)
echo "=== y seleccionándolas a propósito ==="
(cd src/ia01-el-modelo-de-acceso-de-un-llm && uv run --python 3.14 --with pytest --with 'anthropic==1.5.0' python -m pytest -q -m network --collect-only 2>&1 | tail -2)

# --- 2026-09-14T02:53:10 · Run the ia suites with all pinned dependencies
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs/src
echo "=== recuento final de pruebas, track por track ==="
total=0
for d in ia0*/; do
  n=$(cd $d && timeout 300 uv run --python 3.14 --with pytest --with 'anthropic==1.5.0' --with 'pydantic==2.13.5' --with 'tenacity==9.1.4' --with 'psycopg[binary]==3.3.5' --with 'pgvector==0.5.0' --with 'pypdf==6.18.1' python -m pytest -q 2>&1 | tail -1)
  printf "  %-46s %s\n" "$(basename $d)" "$n"
done

# --- 2026-09-14T02:53:30 · Run ia05 with its documented PYTHONPATH
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs/src/ia05-normarag
echo "=== ia05 con el PYTHONPATH que su README documenta ==="
PYTHONPATH=../ia01-el-modelo-de-acceso-de-un-llm:../ia02-salida-estructurada:../ia04-embeddings-y-busqueda-semantica \
 timeout 300 uv run --python 3.14 --with pytest --with 'anthropic==1.5.0' --with 'pydantic==2.13.5' --with 'tenacity==9.1.4' --with 'psycopg[binary]==3.3.5' --with 'pgvector==0.5.0' --with 'pypdf==6.18.1' python -m pytest -q 2>&1 | tail -2

# --- 2026-09-14T02:53:54 · Replace the paid lint debt with the configuration section
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs
python3 - <<'PY'
s=open('prompts/README.md',encoding='utf-8').read()
start=s.index("## 🧹 Deuda declarada: el lint del material ya publicado")
end=s.index("## ⚠️ Las tres cosas que más se rompen al escribir")
new = """## 🧹 Las tres configuraciones de la raíz del curso

Desde el 13/09/2026 la raíz del curso lleva tres archivos de herramienta, y los tres existen
para que una promesa del material sea verdad y no una intención:

| Archivo | Qué sostiene |
|---|---|
| `ruff.toml` | La misma selección que imprime la Fase 00 —`E, F, I, UP, B`, línea de 100—, más `src = ["src/*"]` porque **cada carpeta de `src/` es un proyecto independiente** y sus módulos vecinos son de primera parte, y un `exclude` de lo que generan los scripts |
| `pytest.ini` | Registra el marcador `network` y **lo deselecciona por defecto**. Sin esto, `pytest` no lo conocía, lo avisaba como desconocido y ejecutaba igual las dos pruebas de `ia01` que llaman a la API: fallan sin credenciales y cuestan dinero con ellas |
| `.gitignore` | Lo que generan los scripts —`data/`, `modelos/`, `salida/`, `cuadernos/`— y los artefactos de modelo. Cada `README.md` de `src/` decía "los archivos generados no se versionan" y nada lo hacía cumplir |

🪦 **La deuda de lint quedó pagada.** Al aplicar `ruff.toml` sobre `src/` aparecieron **17
avisos en código ya publicado** —dos `E702` en la Fase 13, seis `E501`, dos `I001`, dos `F401`,
dos `B905` y dos `F821` con su `UP037` en `ia03` e `ia08`—. Se corrigieron todos, **junto con
las tres líneas que sus capítulos transcribían** (`13-integraciones.md`,
`ia03-tool-calling-y-el-bucle-de-agente.md` y `ia06-evaluacion.md`), que era la razón por la que
se habían aplazado. Dos de los arreglos no eran cosméticos: el `agenda` de `ia03` era una
anotación suelta que **no creaba el nombre** —el módulo importaba bien y reventaba con
`NameError` en la primera llamada de la herramienta—, y los dos `zip()` sin `strict=` eran el
mismo defecto que `ds01` §5.3 enseña a no cometer.

📝 El lint se corre **desde dentro de cada directorio de `src/`** o desde la raíz del curso: con
`src = ["src/*"]` las dos formas dan el mismo resultado.

---

"""
open('prompts/README.md','w',encoding='utf-8').write(s[:start]+new+s[end:]); print("OK")
PY
grep -n "^## " prompts/README.md

# --- 2026-09-14T02:54:07 · Final verification sweep
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs
find . \( -name "__pycache__" -o -name ".pytest_cache" -o -name ".ruff_cache" \) -type d -prune -exec rm -rf {} + 2>/dev/null
rm -rf src/*/data src/*/modelos src/*/salida src/*/cuadernos 2>/dev/null
echo "=== VERIFICACIÓN FINAL ==="
echo "1. referencias externas:"; grep -rniE "go-for-java|c-sharp|csharp|curso hermano|el curso de go|claude\.md|courses-ia-generated|cursos-algoritmos" . 2>/dev/null | grep -v ruff_cache || echo "   ninguna ✅"
echo "2. lint:"; uvx ruff@0.16.7 check src/ >/dev/null 2>&1 && echo "   todo src/ limpio ✅" || echo "   ❌ quedan avisos"
echo "3. pruebas ds:"
t=0; for d in src/ds0*/; do
  n=$(cd $d && timeout 500 uv run --python 3.14 --with pytest --with 'numpy==2.5.3' --with 'pandas==3.0.5' --with 'polars==1.44.2' --with 'duckdb==1.5.5' --with 'matplotlib==3.11.2' --with 'plotly==7.0.0' --with 'altair==6.2.2' --with 'papermill==2.7.0' --with 'jupyterlab==4.6.3' --with 'marimo==0.24.2' --with 'scikit-learn==1.9.1' --with 'torch==2.14.0' --with 'skl2onnx==1.20.0' --with 'onnxruntime==1.30.0' --with 'fastapi==0.141.1' python -m pytest -q -p no:warnings 2>&1 | tail -1)
  printf "   %-44s %s\n" "$(basename $d)" "$n"
done

# --- 2026-09-14T02:56:13 · Wait for and read the final verification output
sleep 100; cat "/private/tmp/claude-501/-Users-oskar-Developer-Learning-courses-ia-generated/2859734a-d7e6-4986-b771-4890bf56e42b/tasks/bwgxt1nji.output" 2>/dev/null | tail -18

# --- 2026-09-14T02:56:16 · Read the verification output so far
cat "/private/tmp/claude-501/-Users-oskar-Developer-Learning-courses-ia-generated/2859734a-d7e6-4986-b771-4890bf56e42b/tasks/bwgxt1nji.output" 2>/dev/null | tail -18

# --- 2026-09-14T02:56:20 · Check if ds09 finished
cat "/private/tmp/claude-501/-Users-oskar-Developer-Learning-courses-ia-generated/2859734a-d7e6-4986-b771-4890bf56e42b/tasks/bwgxt1nji.output" 2>/dev/null | tail -3

# --- 2026-09-14T02:56:24 · Run the ds09 suite separately
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs/src/ds09-servir-el-modelo
timeout 400 uv run --python 3.14 --with pytest --with 'scikit-learn==1.9.1' --with 'skl2onnx==1.20.0' --with 'onnxruntime==1.30.0' --with 'fastapi==0.141.1' python -m pytest -q 2>&1 | tail -2

# --- 2026-09-14T02:56:41 · Final inventory of the course folder
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs
find . \( -name "__pycache__" -o -name ".pytest_cache" -o -name ".ruff_cache" \) -type d -prune -exec rm -rf {} + 2>/dev/null
rm -rf src/ds0*/data src/ds0*/modelos src/ds0*/salida src/ds0*/cuadernos 2>/dev/null
echo "=== inventario final del curso ==="
printf "  documentos publicados: %s\n" "$(ls *.md | wc -l | tr -d ' ')"
printf "  líneas de prosa publicada: %s\n" "$(cat *.md | wc -l | tr -d ' ')"
printf "  documentos de prompts/: %s\n" "$(ls prompts/*.md | wc -l | tr -d ' ')"
printf "  directorios de src/: %s\n" "$(ls -d src/*/ | wc -l | tr -d ' ')"
printf "  archivos .py: %s\n" "$(find src -name '*.py' | wc -l | tr -d ' ')"
printf "  configuración de la raíz: %s\n" "$(ls ruff.toml pytest.ini .gitignore 2>/dev/null | tr '\n' ' ')"
echo
echo "=== nada generado en el árbol ==="
find . \( -name "data" -o -name "modelos" -o -name "salida" -o -name "cuadernos" -o -name "__pycache__" -o -name "*.pkl" -o -name "*.onnx" -o -name "*.png" \) | head || true
echo "  (vacío = limpio)"

# --- 2026-09-14T02:57:01 · Record the closing audit in memory
cd /Users/oskar/.claude/projects/-Users-oskar-Developer-Learning-courses-ia-generated/memory
python3 - <<'PY'
p='python-java-devs-estado.md'; s=open(p,encoding='utf-8').read()
old="""**Lo que sigue después del track `ds`** es el material *a la carta* (~23 tracks opcionales),
inventariado en `prompts/propuestas-temas-opcionales.md` §19, más las dos deudas declaradas: el
lint de las 17 líneas de `ia03`–`ia08` y la Fase 13 (`prompts/README.md`, sección de deuda), y
`prompts/check-inventario.py`."""
new="""**Auditoría de cierre hecha el 13/09/2026 y el curso queda cerrable.** Lo que se corrigió:

- **Cuatro citas a otros cursos del proyecto**, que la propia regla del curso prohíbe
  (`alcance` §0): `go-for-java-devs` como justificación de forma, "el curso hermano de C#", la
  nota de origen sobre el curso de Go y la comparación sostenida "el curso de Go / allá" de
  `propuesta-fases-y-alcance.md` §4. Reescritas como afirmaciones sobre **el lenguaje**, no
  sobre otro curso. **Cero referencias a CLAUDE.md o a rutas del proyecto.**
- **La deuda de lint quedó pagada**: los 17 avisos de `ia03`–`ia08` y la Fase 13, junto con las
  tres líneas que sus capítulos transcribían. Dos no eran cosméticos: el `agenda` de `ia03` era
  una anotación suelta que no creaba el nombre (reventaba con `NameError` en la primera llamada)
  y dos `zip()` sin `strict=`.
- **`00-convencion-de-git-y-tags.md` no conocía los tracks**, y las 17 secciones complementarias
  cerraban diciendo "la convención completa está ahí": promesa rota. Ahora tiene la tabla de los
  tres espacios de nombres (`fase-`/`ia-fase-`/`ds-fase-`) y los tags de cierre de track.
- **Tres archivos de configuración en la raíz**: `ruff.toml` (con `src = ["src/*"]`),
  `pytest.ini` —que registra el marcador `network` y **lo deselecciona por defecto**, sin lo cual
  un `pytest` normal ejecutaba las dos pruebas de `ia01` que llaman a la API— y `.gitignore`.
- Conteos corregidos: INSTINTOS decía "cinco" reflejos de `ia` (son 8) y "dos" de `ds` (son 10);
  BENCHMARKS decía "seis mediciones" del track `ia` (son 9).

**Estado verificable:** 41 documentos publicados, 33.603 líneas de prosa, 25 directorios en
`src/`, 112 archivos `.py`. **310 pruebas pasan** —134 del track `ia` (`ia05` necesita el
`PYTHONPATH` que su README documenta) y 176 del `ds`— más 2 marcadas de red. `ruff` limpio sobre
todo `src/` con la configuración del propio curso. Sin links rotos.

**Lo que sigue** es el material *a la carta* (~23 tracks opcionales, orden en
`prompts/propuestas-temas-opcionales.md` §19) y `prompts/check-inventario.py`. Nada de eso
bloquea el cierre. **El curso sigue sin commitear.**"""
assert s.count(old)==1
open(p,'w',encoding='utf-8').write(s.replace(old,new)); print("OK memoria")
PY

