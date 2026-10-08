#!/usr/bin/env bash
#
# check-course.sh — verificación de integridad del curso Docker Legacy Node.
#
# Corre desde cualquier sitio; se sitúa solo en la raíz del curso.
# Devuelve 0 si todo pasa y 1 si algo falla, para poder colgarlo de un hook o de CI.
#
#   ./prompts/check-course.sh          # todas las comprobaciones
#   ./prompts/check-course.sh -q       # solo lo que falla
#
# La explicación de qué hace cada comprobación y por qué existe está en
# prompts/explicacion_script_integridad.md

set -uo pipefail

# nos situamos en la raíz del curso, que es el directorio padre de este script
CURSO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$CURSO" || exit 1

SILENCIOSO=0
[[ "${1:-}" == "-q" ]] && SILENCIOSO=1

FALLOS=0
TOTAL=0

# ok <nombre> <detalle>  ·  falla <nombre> <detalle>
ok()    { TOTAL=$((TOTAL+1)); [[ $SILENCIOSO -eq 1 ]] || printf '  ✅ %-46s %s\n' "$1" "${2:-}"; }
falla() { TOTAL=$((TOTAL+1)); FALLOS=$((FALLOS+1)); printf '  ❌ %-46s %s\n' "$1" "${2:-}"; }

# ejecuta un bloque de python y decide según su salida:
# no imprime nada -> pasa; imprime algo -> falla y se muestra
comprobar() {
    local nombre="$1"; shift
    local salida
    salida="$(python3 - "$@" 2>&1)"
    if [[ -z "$salida" ]]; then
        ok "$nombre"
    else
        falla "$nombre"
        printf '%s\n' "$salida" | sed 's/^/       /'
    fi
}

echo "🔍 Verificando el curso en $CURSO"
echo

# ─────────────────────────────────────────────────────────────────────────────
# 1. Todos los enlaces .md resuelven a un archivo que existe
# ─────────────────────────────────────────────────────────────────────────────
comprobar "enlaces .md resuelven" <<'PY'
import re, os, glob
malos = []
def sin_codigo(t):
    # los ejemplos dentro de `backticks` o de bloques ``` no son enlaces reales
    t = re.sub(r'```.*?```', '', t, flags=re.S)
    return re.sub(r'`[^`\n]*`', '', t)
for f in glob.glob('**/*.md', recursive=True):
    base = os.path.dirname(f)
    for m in re.finditer(r'\]\(([^)#][^)]*\.md)\)', sin_codigo(open(f, encoding='utf-8').read())):
        destino = os.path.normpath(os.path.join(base, m.group(1)))
        if not os.path.isfile(destino):
            malos.append(f'{f} → {m.group(1)}')
for x in malos[:20]: print('enlace roto:', x)
if len(malos) > 20: print(f'... y {len(malos)-20} más')
PY

# ─────────────────────────────────────────────────────────────────────────────
# 2. Ningún documento se enlaza a sí mismo
# ─────────────────────────────────────────────────────────────────────────────
comprobar "sin autoenlaces" <<'PY'
import re, glob, os
def sin_codigo(t):
    t = re.sub(r'```.*?```', '', t, flags=re.S)
    return re.sub(r'`[^`\n]*`', '', t)
for f in glob.glob('*.md'):
    n = len(re.findall(r'\[[^\]]*\]\(' + re.escape(os.path.basename(f)) + r'\)',
                       sin_codigo(open(f, encoding='utf-8').read())))
    if n: print(f'{f}: {n} autoenlace(s)')
PY

# ─────────────────────────────────────────────────────────────────────────────
# 3. La numeración de ejercicios es correlativa dentro de cada documento
# ─────────────────────────────────────────────────────────────────────────────
comprobar "ejercicios numerados 1..N" <<'PY'
import re, glob
for f in sorted(glob.glob('[0-9]*.md')) + sorted(glob.glob('a[0-9]*.md')):
    nums = [int(m.group(1)) for m in re.finditer(
        r'^### [🟢🟡🟠🔴🔥💀] Ejercicio (\d+) —', open(f, encoding='utf-8').read(), re.M)]
    if nums and nums != list(range(1, len(nums) + 1)):
        print(f'{f}: {nums}')
PY

# ─────────────────────────────────────────────────────────────────────────────
# 4. El conteo del título coincide con los ejercicios obligatorios reales
# ─────────────────────────────────────────────────────────────────────────────
comprobar "conteo del título = obligatorios reales" <<'PY'
import re, glob
for f in sorted(glob.glob('[0-9][0-9]-*.md')) + sorted(glob.glob('a[0-9][0-9]-*.md')):
    s = open(f, encoding='utf-8').read()
    t = re.search(r'🧪 Ejercicios[^\n(]*\((\d+)\)', s)
    if not t: continue
    real = len(re.findall(r'^### [🟢🟡🟠🔴] Ejercicio', s, re.M))
    if int(t.group(1)) != real:
        print(f'{f}: el título dice {t.group(1)} y hay {real}')
PY

# ─────────────────────────────────────────────────────────────────────────────
# 5. Las referencias del tipo «F14 §5.1» apuntan a una sección que existe
# ─────────────────────────────────────────────────────────────────────────────
comprobar "referencias FNN §x.y resuelven" <<'PY'
import re, glob
secs = {}
for f in glob.glob('[0-9]*.md') + glob.glob('a[0-9]*.md'):
    m = re.match(r'^(\d{2}|a\d{2})', f)
    if not m: continue
    clave = ('F' + m.group(1)) if m.group(1).isdigit() else m.group(1)
    secs[clave] = {mm.group(1) for mm in re.finditer(
        r'^#{2,3} (\d+(?:\.\d+)?)\.? ', open(f, encoding='utf-8').read(), re.M)}
for f in glob.glob('[0-9]*.md') + glob.glob('a[0-9]*.md'):
    txt = open(f, encoding='utf-8').read()
    # la ventana de 60 caracteres absorbe el enlace markdown entre el código y el §
    for ref, sec in re.findall(r'\b(F\d{2}|a\d{2})\b[^\n]{0,60}?§(\d+(?:\.\d+)?)', txt):
        if ref not in secs: continue
        raiz = sec.split('.')[0]
        if not any(x == raiz or x.startswith(raiz + '.') for x in secs[ref]):
            print(f'{f}: {ref} §{sec} no existe')
PY

# ─────────────────────────────────────────────────────────────────────────────
# 6. Cada apéndice tiene al menos un enlace entrante desde una fase
# ─────────────────────────────────────────────────────────────────────────────
comprobar "ningún apéndice huérfano" <<'PY'
import re, glob
fases = [f for f in glob.glob('[0-9][0-9]-*.md')]
cuerpo = '\n'.join(open(f, encoding='utf-8').read() for f in fases)
for a in sorted(glob.glob('a[0-9][0-9]-*.md')):
    if f']({a})' not in cuerpo:
        print(f'{a}: sin enlace entrante desde ninguna fase')
PY

# ─────────────────────────────────────────────────────────────────────────────
# 7. La banda de ejercicios obligatorios por fase práctica es 20–35
# ─────────────────────────────────────────────────────────────────────────────
comprobar "fases prácticas dentro de la banda 20–35" <<'PY'
import re, glob
EXENTAS = {'00-problema-y-contrato.md', '01-decisiones-debian-zonas-node.md',
           '34-proyecto-final.md', '35-referencias.md'}
for f in sorted(glob.glob('[0-9][0-9]-*.md')):
    if f in EXENTAS or f.startswith('00-PARTE'):
        continue
    n = len(re.findall(r'^### [🟢🟡🟠🔴] Ejercicio', open(f, encoding='utf-8').read(), re.M))
    if n and not 20 <= n <= 35:
        print(f'{f}: {n} obligatorios (la guía §9 fija 20–35)')
PY

# ─────────────────────────────────────────────────────────────────────────────
# 8. Ninguna fase repite exactamente el reparto de dificultad de la anterior
# ─────────────────────────────────────────────────────────────────────────────
comprobar "reparto 🟢🟡🟠🔴 distinto del de la fase previa" <<'PY'
import re, glob
from collections import Counter
previo, prev_f = None, None
for f in sorted(glob.glob('[0-9][0-9]-*.md')):
    if f.startswith('00-PARTE'):
        continue
    s = open(f, encoding='utf-8').read()
    tiers = re.findall(r'^### ([🟢🟡🟠🔴]) Ejercicio', s, re.M)
    if len(tiers) < 20:
        continue
    c = Counter(tiers)
    actual = (c['🟢'], c['🟡'], c['🟠'], c['🔴'])
    if actual == previo:
        print(f'{f}: repite {actual} de {prev_f}')
    previo, prev_f = actual, f
PY

# ─────────────────────────────────────────────────────────────────────────────
# 9. ⭐ solo se usa en F35 (valoración bibliográfica), nunca para graduar
# ─────────────────────────────────────────────────────────────────────────────
comprobar "⭐ solo en 35-referencias.md" <<'PY'
import glob, os
IGNORAR = {'35-referencias.md'}
for f in glob.glob('*.md') + glob.glob('src/**/*.md', recursive=True):
    if os.path.basename(f) in IGNORAR:
        continue
    if '⭐' in open(f, encoding='utf-8').read():
        print(f'{f}: usa ⭐ fuera de F35')
PY

# ─────────────────────────────────────────────────────────────────────────────
# 10. No queda andamiaje de la reestructuración en documentos publicados
# ─────────────────────────────────────────────────────────────────────────────
comprobar "sin andamiaje (_source/, mapa-de-corte…)" <<'PY'
import re, glob, os
PROHIBIDO = re.compile(r'_source/|mapa-de-corte|ajuste_estructura\.md|mejoras(_v2)?\.md')
# prompts/ no es material publicado: la guía y la propuesta hablan del andamiaje
# precisamente porque documentan cómo se quitó
for f in glob.glob('**/*.md', recursive=True):
    if f.startswith('prompts/'):
        continue
    for i, ln in enumerate(open(f, encoding='utf-8'), 1):
        if PROHIBIDO.search(ln):
            print(f'{f}:{i}: {ln.strip()[:90]}')
PY

# ─────────────────────────────────────────────────────────────────────────────
# 11. Versiones fijadas: ningún :latest ni rango en los Dockerfiles del curso
# ─────────────────────────────────────────────────────────────────────────────
comprobar "Dockerfiles sin :latest ni rangos" <<'PY'
import re, glob
for f in glob.glob('src/**/*.Dockerfile', recursive=True) + glob.glob('src/**/Dockerfile', recursive=True):
    for i, ln in enumerate(open(f, encoding='utf-8'), 1):
        if ln.lstrip().startswith('#'):
            continue
        if re.search(r':latest\b|FROM\s+\S+:\d+\.x', ln):
            print(f'{f}:{i}: {ln.strip()[:90]}')
PY

# ─────────────────────────────────────────────────────────────────────────────
# 12. Todo lo que src/ promete existe, y toda fase con código lo apunta
# ─────────────────────────────────────────────────────────────────────────────
comprobar "punteros a src/ coherentes" <<'PY'
import re, glob, os
# cada 'Código de esta fase: src/X/' debe existir
for f in glob.glob('[0-9a]*.md'):
    for m in re.finditer(r'\*\*Código de esta fase:\*\*\s*\[`(src/[^`]+)`\]', open(f, encoding='utf-8').read()):
        if not os.path.isdir(m.group(1).rstrip('/')):
            print(f'{f}: apunta a {m.group(1)} y no existe')
# cada directorio de src/ (salvo all-dockerfiles) debe tener su documento
for d in sorted(os.listdir('src')):
    ruta = os.path.join('src', d)
    if not os.path.isdir(ruta) or d == 'all-dockerfiles':
        continue
    if not os.path.isfile(d + '.md'):
        print(f'src/{d}/ no tiene documento {d}.md')
PY

# ─────────────────────────────────────────────────────────────────────────────
# 13. El índice y el README declaran el mismo número de fases y apéndices
# ─────────────────────────────────────────────────────────────────────────────
comprobar "índice y README cuadran con el árbol" <<'PY'
import re, glob
fases = [f for f in glob.glob('[0-9][0-9]-*.md') if not f.startswith('00-PARTE')]
apes = glob.glob('a[0-9][0-9]-*.md')
for doc in ('README.md', '0-programa-del-curso.md'):
    s = open(doc, encoding='utf-8').read()
    if f'{len(fases)} fases' not in s:
        print(f'{doc}: no dice «{len(fases)} fases» (hay {len(fases)})')
    if f'{len(apes)} apéndices' not in s:
        print(f'{doc}: no dice «{len(apes)} apéndices» (hay {len(apes)})')
PY

echo
if [[ $FALLOS -eq 0 ]]; then
    echo "✅ $TOTAL comprobaciones, ninguna falla."
    exit 0
else
    echo "❌ $FALLOS de $TOTAL comprobaciones fallan."
    exit 1
fi
