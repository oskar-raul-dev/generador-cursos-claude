# Bitácora de ejecución · sesión 03630220-8285-47af-bd48-9f631cee549b

Comandos que ejecutaron código, con el inicio de su salida.

### ⏱️ 2026-09-13T18:22:16Z · Search for cross-course references in markdown

~~~~~~bash
grep -rniE "cursos-|curso de (angular|react|nosql|docker|python|java)|python-for-java|ruta-nosql|docker-container|angular|react|otro curso|curso hermano|curso vecino|propuestas-cursos|_oskar|\.\./" --include=*.md . | head -80
~~~~~~

~~~~~~text
(eval):1: no matches found: --include=*.md
~~~~~~

### ⏱️ 2026-09-13T18:22:19Z · Search cross-course references

~~~~~~bash
grep -rniE "cursos-|curso de (angular|react|nosql|docker|python|java)|python-for-java|ruta-nosql|docker-container|angular|react|otro curso|curso hermano|curso vecino|propuestas-cursos|_oskar|\.\./" --include="*.md" . | head -100
~~~~~~

~~~~~~text
08-caracterizar-y-probar.md:311:        await ExecuteScriptsAsync("../../../../legacy/Sige.Database/esquema");
08-caracterizar-y-probar.md:312:        await ExecuteScriptsAsync("../../../../legacy/Sige.Database/procedimientos");
22-ia-aplicada.md:68:- **Afinado de modelos y entrenamiento.** Declarado fuera, con destino: `cursos-ia` en este repositorio. Aquí
INSTINTOS.md:477:directo en Java: lo más cercano son los reactive streams, con mucho más aparato y suscripción explícita.
11-migrar-el-runtime.md:269:         y el nullable vienen de ../Directory.Build.props, salvo uno: -->
0-ESTRUCTURA-CURSO.md:13:**Bloque 0 · el ambiente** *(fase 00)*. En otro curso esto sería un apéndice de instalación. Aquí
0-ESTRUCTURA-CURSO.md:254:Este curso **no tiene apéndices**, y no es un detalle de organización. Todo lo que en otro curso
18-blazor-server-wasm-mvc.md:63:- **Un framework de JavaScript.** Declarado fuera, con su razón y sin condescendencia: React, Angular o Vue
18-blazor-server-wasm-mvc.md:199:| SPA (React/Angular) + API REST | **Blazor WebAssembly** + la API de la F15 | Mismo modelo, con el componente en C#. La carga inicial pesa más que un paquete de JavaScript equivalente |
18-blazor-server-wasm-mvc.md:772:- Investiga cuánto pesaría la misma pantalla en React con una API, y compáralo con el paquete de WebAssembly.
21-datos-y-onnx.md:62:- **Teoría de aprendizaje automático.** Declarado fuera y con destino: para eso está `cursos-ia` en este
21-datos-y-onnx.md:68:- **Un registro de
~~~~~~

### ⏱️ 2026-09-13T18:40:08Z · Clean remaining repo-authority phrasing and verify

~~~~~~bash
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
~~~~~~

~~~~~~text
ok
23-el-duelo.md:866:  subárbol del repositorio** y hay que declararlo: el curso tenía la regla de "dos subárboles, `legacy/` y
16-identidad-secretos-y-configuracion.md:102:3. secretos de usuario                  ← SOLO en desarrollo. Fuera del repositorio, en el perf
16-identidad-secretos-y-configuracion.md:254:| — | `dotnet user-secrets` | **No tiene equivalente directo.** Guarda secretos de desarrollo f
16-identidad-secretos-y-configuracion.md:729:1. Configura `dotnet user-secrets` y demuestra que el valor no está en el árbol del repositorio
00-ambiente-visual-studio-y-ecosistema.md:28:- [ ] `src/global.json` fija el SDK del repositorio, y cambiarlo cambia la respuesta anterior.
00-ambiente-visual-studio-y-ecosistema.md:156:| `mvn versions:set` | `Directory.Packages.props` | La versión vive en un solo archivo del rep
00-ambiente-visual-studio-y-ecosistema.md:189:// src/global.json — el SDK del repositorio, fijado. Es el equivalente funcional de fijar la
00-ambiente-visual-studio-y-ecosistema.md:204:- El archivo va en `src/`, no en la raíz del repositorio, porque la resolución **sube** por el
prompts/alcance-del-proyecto.md:207:  heredado que después se migra— igual que los cursos hermanos, y por la misma razón: quien
prompts/propuesta-fases-y-alcance.md:29:hermanos atacan uno; este ataca los dos, y por eso tiene un bloque de lenguaje *y* un bloque de
~~~~~~

### ⏱️ 2026-09-13T19:10:26Z · Verification batch 1

~~~~~~bash
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
~~~~~~

~~~~~~text
=== 1. Referencias a otros cursos / repo externo ===
16-identidad-secretos-y-configuracion.md:102:3. secretos de usuario                  ← SOLO en desarrollo. Fuera del repositorio, en el perfil del usuario.
16-identidad-secretos-y-configuracion.md:254:| — | `dotnet user-secrets` | **No tiene equivalente directo.** Guarda secretos de desarrollo fuera del repositorio, en el perfil del usuario, sin configurar nada |

=== 2. Enlaces relativos ===
  ✅ todos resuelven

=== 3. Cadena Depende/Habilita ===
  ✅ cadena 00→24 completa y cabeceras correctas
~~~~~~

### ⏱️ 2026-09-13T20:02:45Z · Verification batch 1

~~~~~~bash
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
~~~~~~

~~~~~~text
════ 1. REFERENCIAS A OTROS CURSOS / REPO ════
  ✅ cero

════ 2. ENLACES ════
  ✅ todos resuelven

════ 3. ESTRUCTURA ════
  archivos publicados: 31 · fases: 25
  ✅ cadena 00→24 sin huecos, cabeceras correctas
~~~~~~

### ⏱️ 2026-09-13T20:03:52Z · Wide sweep for external references

~~~~~~bash
echo "════ barrido amplio de referencias externas ════"
grep -rniE "otro curso|otros cursos|este repositorio|del repositorio|en el repositorio|curso de [A-Z]|cursos de |repositorio de cursos" . --include="*.md" \
 | grep -viE "SDK del repositorio|archivo del repositorio|raíz del repositorio|árbol del repositorio|subárbol del repositorio|fuera del repositorio|repositorio de (ejecuciones|dotnet)|en el repositorio si alguien|en el repositorio y en el historial|en el repositorio como prueba|se quedan en el repositorio|está en el repositorio" \
 | sed 's/\(.\{155\}\).*/\1/'
~~~~~~

~~~~~~text
════ barrido amplio de referencias externas ════
24-veredicto-y-defensa.md:441:> Y la verificación que sí pasó, que es la que protegía al curso de mentirse: **cero citas ilegales**. Ninguna de
09-acceso-a-datos-esquema-hostil.md:665:   archivo**, y una búsqueda en el repositorio demuestra que no hay ninguna conversión de `char(8)` a
09-acceso-a-datos-esquema-hostil.md:945:> vacío donde uno esperaba un cambio es la forma que tiene este curso de decir *"se envuelve, no se
11-migrar-el-runtime.md:573:4. **Ninguna API de la categoría 3 queda como está.** Una búsqueda en el repositorio lo demuestra: cada
BENCHMARKS.md:1598:| **Citas ilegales** —una fase que use una fila ⏳ o 🔜 como argumento— | **0** ✅ | es la verificación que protegía al curso de mentirse |
20-contenedor-y-la-factura.md:417://    ⏳ Las dos cifras se calculan en el miniproyecto. Es el ejemplo más claro del curso de un atajo
23-el-duelo.md:202:Este es el 📖 más completo del curso porque la fase lo permite: los dos lados existen en el repositorio.
00-convencion-de-git-y-tags.md:96:De ahí sale lo único que este curso le pide a git y que un curso de un solo runtime no necesita:
05-async-await-y-cancelacion.md:658:   búsqueda en el repositorio lo demuestra, y el resultado se pega en el commit.
18-blazor-server-wasm-mvc.md:883:  construir la mitad de un sistema de trazas y después tirarlo. Es el mejor ejemplo del curso de una deuda
00-historia-de-cordillera.md:547:a ser **empate** — que es la palabra que menos aparece en 
~~~~~~

