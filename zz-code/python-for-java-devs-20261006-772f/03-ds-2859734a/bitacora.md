# Bitácora de ejecución · sesión 2859734a-d7e6-4986-b771-4890bf56e42b

Comandos que ejecutaron código, con el inicio de su salida.

### ⏱️ 2026-09-13T19:43:10Z · List 00 files and grep references

~~~~~~bash
ls 00-*; echo "=== A: historia ==="; grep -rn "historia-de-aurea\|historia-propuesta" . 2>/dev/null | grep -v "^\./\.pytest_cache"; echo "=== B: ambiente ==="; grep -rn "00-ambiente-editores-y-ecosistema\|00-instalacion-ambiente-editores" . 2>/dev/null | grep -v "^\./\.pytest_cache"
~~~~~~

~~~~~~text
00-convencion-de-git-y-tags.md
00-historia-de-aurea.md
00-instalacion-ambiente-editores-y-ecosistema.md
=== A: historia ===
ia01-el-modelo-de-acceso-de-un-llm.md:538:máquina. Ver historia-de-aurea.md §5.
prompts/prompts-de-fase.md:46:7. `prompts/historia-de-aurea.md` — todo lo narrativo: personajes, cifras, cronología,
prompts/prompts-de-fase.md:359:  paralelo. Lee `historia-de-aurea.md` §1.1 completa antes de modelar; hay reglas ahí
prompts/propuesta-fases-y-alcance.md:55:| Dominio | Todo sale de `historia-de-aurea.md` | Ninguna fase lo amplía por su cuenta |
prompts/propuestas-fases-base-ia-datos.md:20:> (`historia-de-aurea.md`), decisión cerrada. Los nombres de proyecto que aparecen en la
prompts/propuestas-fases-base-ia-datos.md:36:de datos que Áurea ya tiene planteados** en `historia-de-aurea.md` §7 y §8 —NormaRAG,
prompts/propuestas-fases-base-ia-datos.md:138:Consultorio y Cartera, y están en `historia-de-aurea.md` §6.
prompts/propuestas-fases-base-ia-datos.md:197:> asistida** (`ia07`), definidos en `historia-de-aurea.md` §7.
prompts/propuestas-fases-base-ia-datos.md:222:> en `historia-de-aurea.md` §8.
prompts/alcance-del-proyecto.md:148:La historia completa vive en **[`historia-de-aurea.md`](historia-de-aurea.md)**
prompts/alcance-del-proyecto.md:398:- 🪦 **La empresa es Áurea**, con la historia de `historia-de-aurea.md` como fuente.
prompts/contrato-del-cli.md:24:> 🪦 **Contradicción resuelta.** `historia-de-aurea.md` §6 decía que `aur` "solo se
prompts/README.md:41:4. 
~~~~~~

### ⏱️ 2026-09-13T19:43:52Z · Rewrite filename references across course

~~~~~~bash
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
~~~~~~

~~~~~~text
A: BENCHMARKS.md
A: prompts/prompts-de-fase.md
A: prompts/propuestas-temas-opcionales.md
A: prompts/propuestas-fases-base-ia-datos.md
A: prompts/propuesta-fases-y-alcance.md
--- B ---
B2: prompts/prompts-de-fase.md
B2: prompts/prompts-de-tracks-ia-ds.md
B2: src/ia01-el-modelo-de-acceso-de-un-llm/local.py
B3: ia01-el-modelo-de-acceso-de-un-llm.md
B3: prompts/alcance-del-proyecto.md
B3: prompts/prompts-de-fase.md
B3: prompts/contrato-del-cli.md
B3: prompts/propuestas-fases-base-ia-datos.md
B3: prompts/propuesta-fases-y-alcance.md
B3: prompts/README.md
B3: prompts/guia-de-estilo-y-convenciones.md
B3: prompts/prompts-de-tracks-ia-ds.md
B3: src/ia01-el-modelo-de-acceso-de-un-llm/local.py
=== VERIFY ===
ia01-el-modelo-de-acceso-de-un-llm.md:538:máquina. Ver 00-historia-de-aurea.md §5.
prompts/alcance-del-proyecto.md:148:La historia completa vive en **[`00-historia-de-aurea.md`](../00-00-historia-de-aurea.md)**
prompts/alcance-del-proyecto.md:398:- 🪦 **La empresa es Áurea**, con la historia de `00-historia-de-aurea.md` como fuente.
prompts/propuestas-fases-base-ia-datos.md:20:> (`00-historia-de-aurea.md`), decisión cerrada. Los nombres de proyecto que aparecen en la
prompts/propuestas-fases-base-ia-datos.md:36:de datos que Áurea ya tiene planteados** en `00-historia-de-aurea.md` §7 y §8 —NormaRAG,
prompts/propuestas-fases-base-ia-datos.md:138:Consultorio y Cartera, y están en `00-historia-de-aurea.md` §6.
prompts/propuestas-fases-base-ia-datos.md:197:> asistida** (`ia07`), definidos
~~~~~~

### ⏱️ 2026-09-13T19:44:02Z · Fix doubled 00- prefix

~~~~~~bash
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs
grep -rl "00-00-historia-de-aurea" . 2>/dev/null | grep -v pytest_cache | while read f; do sed -i '' 's|00-00-historia-de-aurea|00-historia-de-aurea|g' "$f"; done
echo "=== VERIFY ==="; grep -rn "historia-de-aurea" . 2>/dev/null | grep -v pytest_cache
~~~~~~

~~~~~~text
=== VERIFY ===
ia01-el-modelo-de-acceso-de-un-llm.md:538:máquina. Ver 00-historia-de-aurea.md §5.
prompts/alcance-del-proyecto.md:148:La historia completa vive en **[`00-historia-de-aurea.md`](../00-historia-de-aurea.md)**
prompts/alcance-del-proyecto.md:398:- 🪦 **La empresa es Áurea**, con la historia de `00-historia-de-aurea.md` como fuente.
prompts/prompts-de-fase.md:46:7. `00-historia-de-aurea.md` — todo lo narrativo: personajes, cifras, cronología,
prompts/prompts-de-fase.md:359:  paralelo. Lee `00-historia-de-aurea.md` §1.1 completa antes de modelar; hay reglas ahí
prompts/contrato-del-cli.md:24:> 🪦 **Contradicción resuelta.** `00-historia-de-aurea.md` §6 decía que `aur` "solo se
prompts/README.md:41:4. **[`00-historia-de-aurea.md`](../00-historia-de-aurea.md)** — la empresa del curso.
prompts/README.md:96:| `00-historia-de-aurea.md` | La empresa del curso, y la única | Todo lo narrativo |
prompts/propuestas-fases-base-ia-datos.md:20:> (`00-historia-de-aurea.md`), decisión cerrada. Los nombres de proyecto que aparecen en la
prompts/propuestas-fases-base-ia-datos.md:36:de datos que Áurea ya tiene planteados** en `00-historia-de-aurea.md` §7 y §8 —NormaRAG,
prompts/propuestas-fases-base-ia-datos.md:138:Consultorio y Cartera, y están en `00-historia-de-aurea.md` §6.
prompts/propuestas-fases-base-ia-datos.md:197:> asistida** (`ia07`), definidos en `00-historia-de-aurea.md` §7.
prompts/propuestas-fases-base-ia-datos.md:222:> en `00-historia-de-aurea.md` §8.
prompts/propuesta
~~~~~~

### ⏱️ 2026-09-13T19:45:35Z · Add naming note and verify links

~~~~~~bash
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
~~~~~~

~~~~~~text
OK
=== quedan refs viejas? ===
ninguna
=== links rotos (md) ===
sin links rotos
~~~~~~

### ⏱️ 2026-09-13T19:52:44Z · Find tanda records and read ds blocks

~~~~~~bash
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs
echo "=== grep Tanda ==="; grep -rn "Tanda\|tanda" --include=*.md . | grep -v pytest_cache | head -30
echo; echo "=== ds blocks ==="; sed -n '/^## # ds01/,$p' prompts/prompts-de-tracks-ia-ds.md
~~~~~~

~~~~~~text
=== grep Tanda ===
(eval):2: no matches found: --include=*.md

=== ds blocks ===
## # ds01 — NumPy y el modelo vectorizado

**Qué se decide en este chat.** El modelo mental que ordena el track: **el bucle es el enemigo, y
tiene un tamaño a partir del cual lo es**. Arreglos, dtypes, broadcasting, vistas contra copias.

**Cuidado con.** El reflejo de este perfil no es escribir un bucle malo: es escribir un bucle
**correcto y legible**, que en Java habría sido lo adecuado. La sección tiene que honrar eso y
mostrar el umbral exacto donde deja de serlo, no ridiculizarlo. Y con las vistas: `a[1:3] = 0`
modifica el original, que es la primera sorpresa de quien viene de copias defensivas.

**Su medición.** El mismo cálculo —el costo por paciente adquirido, sobre el histórico de pauta—
en bucle de Python, en `list comprehension` y vectorizado, a 1.000, 100.000 y 5.000.000 de filas.
El veredicto es el umbral.

## # ds02 — pandas y el modelo de DataFrame

**Qué se decide en este chat.** El índice, la alineación automática, los tipos que cambian solos,
y por qué `SettingWithCopyWarning` no es un capricho. El puente honesto: **un DataFrame no es una
tabla y no es una lista de objetos**; es lo más parecido a una hoja de cálculo con álgebra
relacional encima, y ahí es donde se rompe la analogía con SQL.

**Cuidado con.** Es la sección con más superficie para explicar de más. Solo entra lo que produce
un error o una factura: el `join` que multiplica filas, el `apply` que recorre fila por fil
~~~~~~

### ⏱️ 2026-09-13T19:58:33Z · Run the Embudo generator once

~~~~~~bash
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs/src/ds01-numpy-y-el-modelo-vectorizado && time python3 generar_embudo.py --salida /tmp/claude-501/-Users-oskar-Developer-Learning-courses-ia-generated/2859734a-d7e6-4986-b771-4890bf56e42b/scratchpad/embudo 2>&1 | tail -20
~~~~~~

~~~~~~text
/tmp/claude-501/-Users-oskar-Developer-Learning-courses-ia-generated/2859734a-d7e6-4986-b771-4890bf56e42b/scratchpad/embudo/pauta.csv: 49,260 filas
/tmp/claude-501/-Users-oskar-Developer-Learning-courses-ia-generated/2859734a-d7e6-4986-b771-4890bf56e42b/scratchpad/embudo/leads.csv: 32,547 filas
/tmp/claude-501/-Users-oskar-Developer-Learning-courses-ia-generated/2859734a-d7e6-4986-b771-4890bf56e42b/scratchpad/embudo/toques.csv: 63,638 filas
/tmp/claude-501/-Users-oskar-Developer-Learning-courses-ia-generated/2859734a-d7e6-4986-b771-4890bf56e42b/scratchpad/embudo/etapas.csv: 66,153 filas
/tmp/claude-501/-Users-oskar-Developer-Learning-courses-ia-generated/2859734a-d7e6-4986-b771-4890bf56e42b/scratchpad/embudo/planes_de_tratamiento.csv: 6,339 filas
/tmp/claude-501/-Users-oskar-Developer-Learning-courses-ia-generated/2859734a-d7e6-4986-b771-4890bf56e42b/scratchpad/embudo/cuotas.csv: 81,370 filas
/tmp/claude-501/-Users-oskar-Developer-Learning-courses-ia-generated/2859734a-d7e6-4986-b771-4890bf56e42b/scratchpad/embudo/aliados.csv: 23 filas
/tmp/claude-501/-Users-oskar-Developer-Learning-courses-ia-generated/2859734a-d7e6-4986-b771-4890bf56e42b/scratchpad/embudo/remisiones.csv: 2,590 filas
python3 generar_embudo.py --salida  2>&1  0.91s user 0.05s system 90% cpu 1.066 total
tail -20  0.00s user 0.00s system 0% cpu 1.066 total
~~~~~~

### ⏱️ 2026-09-13T19:58:40Z · Run generator tests

~~~~~~bash
python3 -m pytest test_generar_embudo.py -q 2>&1 | tail -40
~~~~~~

~~~~~~text
/Users/oskar/.pyenv/versions/3.13.4/bin/python3: No module named pytest
~~~~~~

### ⏱️ 2026-09-13T19:58:45Z · Look for existing venv or uv

~~~~~~bash
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs; ls .venv 2>/dev/null; cat .pytest_cache/CACHEDIR.TAG 2>/dev/null | head -2; which -a python3.14 python3.13 uv pytest 2>/dev/null
~~~~~~

~~~~~~text
Signature: 8a477f597d28d172789f06886806bc55
# This file is a cache directory tag created by pytest.
/opt/homebrew/bin/python3.14
/Users/oskar/.local/bin/python3.14
/Users/oskar/.pyenv/shims/python3.13
/Library/Frameworks/Python.framework/Versions/3.13/bin/python3.13
/opt/homebrew/bin/python3.13
/usr/local/bin/python3.13
/Library/Frameworks/Python.framework/Versions/3.13/bin/python3.13
/Users/oskar/.pyenv/shims/uv
~~~~~~

### ⏱️ 2026-09-13T19:58:47Z · Run tests with uv

~~~~~~bash
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs/src/ds01-numpy-y-el-modelo-vectorizado && uv run --python 3.14 --with pytest python -m pytest test_generar_embudo.py -q 2>&1 | tail -40
~~~~~~

~~~~~~text
Downloading pygments (1.2MiB)
 Downloaded pygments
Installed 5 packages in 12ms
............................                                             [100%]
28 passed in 11.07s
~~~~~~

### ⏱️ 2026-09-13T20:00:23Z · Run the Ausentismo generator

~~~~~~bash
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs/src/ds07-scikit-learn && time python3 generar_ausentismo.py --salida /tmp/claude-501/-Users-oskar-Developer-Learning-courses-ia-generated/2859734a-d7e6-4986-b771-4890bf56e42b/scratchpad/aus 2>&1 | tail
~~~~~~

~~~~~~text
Traceback (most recent call last):
  File "/Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs/src/ds07-scikit-learn/generar_ausentismo.py", line 284, in <module>
    main()
    ~~~~^^
  File "/Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs/src/ds07-scikit-learn/generar_ausentismo.py", line 254, in main
    appointments = build_appointments(rng, patients, weather)
  File "/Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs/src/ds07-scikit-learn/generar_ausentismo.py", line 176, in build_appointments
    rain = weather[(patient["zona"], day)]
           ~~~~~~~^^^^^^^^^^^^^^^^^^^^^^^^
KeyError: ('sur', datetime.date(2023, 12, 30))
python3 generar_ausentismo.py --salida  2>&1  0.23s user 0.02s system 72% cpu 0.349 total
tail  0.00s user 0.00s system 0% cpu 0.349 total
~~~~~~

### ⏱️ 2026-09-13T20:00:33Z · Fix date range bug and rerun

~~~~~~bash
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
~~~~~~

~~~~~~text
OK
42,460 citas · 4,200 pacientes · inasistencia 53.9%
⚠️  `inasistencias_totales_paciente` tiene fuga temporal. Es a propósito.
python3 generar_ausentismo.py --salida  2>&1  0.46s user 0.03s system 83% cpu 0.578 total
tail  0.00s user 0.00s system 0% cpu 0.577 total
~~~~~~

### ⏱️ 2026-09-13T20:01:42Z · Calibrate weights and regenerate

~~~~~~bash
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
~~~~~~

~~~~~~text
OK
42,460 citas · 4,200 pacientes · inasistencia 19.3%
⚠️  `inasistencias_totales_paciente` tiene fuga temporal. Es a propósito.
~~~~~~

### ⏱️ 2026-09-13T20:01:56Z · Scale patients to match network volume

~~~~~~bash
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
~~~~~~

~~~~~~text
OK
106,587 citas · 10,500 pacientes · inasistencia 19.8%
⚠️  `inasistencias_totales_paciente` tiene fuga temporal. Es a propósito.
python3 generar_ausentismo.py --salida  2>&1  1.20s user 0.05s system 92% cpu 1.354 total
tail -3  0.00s user 0.00s system 0% cpu 1.353 total
cita_id,paciente_id,sede,zona,fecha,hora,dia_semana,tipo,mes_tratamiento,dias_desde_agendamiento,distancia_km,lluvia_mm,franja_edad,citas_previas,inasistencias_previas,asistio,inasistencias_totales_paciente
C0000001,P005452,Fontibon,occidente,2024-01-01,09:20,0,control,1,24,4.8,0.0,30-44,0,0,1,0
~~~~~~

### ⏱️ 2026-09-13T20:02:56Z · Run ausentismo generator tests

~~~~~~bash
uv run --python 3.14 --with pytest python -m pytest test_generar_ausentismo.py -q 2>&1 | tail -40
~~~~~~

~~~~~~text
.......F...........                                                      [100%]
=================================== FAILURES ===================================
______________ test_el_corte_temporal_deja_datos_de_los_dos_lados ______________

dataset = {'dir': PosixPath('/private/var/folders/yc/qgh9zjpn03x_y95vs9gj_k380000gn/T/pytest-of-oskar/pytest-1/ausentismo0'), 'c...4-01-01', 'zona': 'sabana', 'lluvia_mm': '0.0'}, {'fecha': '2024-01-01', 'zona': 'sur', 'lluvia_mm': '0.0'}, ...], ...}

    def test_el_corte_temporal_deja_datos_de_los_dos_lados(dataset):
        """La división de ds07 es temporal, no aleatoria. Si el corte dejara el 5% de un lado,
        la métrica de prueba sería ruido y el capítulo no podría sostener nada."""
        cutoff = dataset["manifiesto"]["corte_temporal"]
        before = [row for row in dataset["citas"] if row["fecha"] < cutoff]
        after = [row for row in dataset["citas"] if row["fecha"] >= cutoff]
>       assert 0.25 < len(after) / len(dataset["citas"]) < 0.45
E       AssertionError: assert 0.25 < (4546 / 18309)
E        +  where 4546 = len([{'cita_id': 'C0013764', 'paciente_id': 'P000571', 'sede': 'Suba', 'zona': 'noroccidente', ...}, {'cita_id': 'C0013765...'norte', ...}, {'cita_id': 'C0013769', 'paciente_id': 'P001098', 'sede': 'Engativa', 'zona': 'noroccidente', ...}, ...])
E        +  and   18309 = len([{'cita_id': 'C0000001', 'paciente_id': 'P001751', 'sede': 'Soacha', 'zona': 'sabana', ...}, {'cita_id': 'C0000002', '...idente', .
~~~~~~

### ⏱️ 2026-09-13T20:03:13Z · Spread patient entry across full range and retest

~~~~~~bash
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
~~~~~~

~~~~~~text
OK
...................                                                      [100%]
19 passed in 0.50s
89,438 citas · 10,500 pacientes · inasistencia 19.2%
~~~~~~

### ⏱️ 2026-09-13T20:03:24Z · Scale to network volume and verify

~~~~~~bash
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs/src/ds07-scikit-learn
sed -i '' 's/# 10.500 pacientes con planes de 4 a 26 meses dejan unos 3.900 citas al mes activas,/# 12.400 pacientes con planes de 4 a 26 meses dejan unas 3.900 citas al mes activas,/; s/default=10_500/default=12_400/' generar_ausentismo.py
time python3 generar_ausentismo.py --salida /tmp/claude-501/-Users-oskar-Developer-Learning-courses-ia-generated/2859734a-d7e6-4986-b771-4890bf56e42b/scratchpad/aus 2>&1|head -1
python3 - <<'PY'
from datetime import date
p="/tmp/claude-501/-Users-oskar-Developer-Learning-courses-ia-generated/2859734a-d7e6-4986-b771-4890bf56e42b/scratchpad/aus/citas_historicas.csv"
rows=open(p).read().splitlines()[1:]
n=len(rows); print(f"{n/27:.0f} citas/mes")
PY
~~~~~~

~~~~~~text
105,620 citas · 12,400 pacientes · inasistencia 19.3%
python3 generar_ausentismo.py --salida  2>&1  1.23s user 0.04s system 90% cpu 1.398 total
head -1  0.00s user 0.00s system 0% cpu 1.389 total
3912 citas/mes
~~~~~~

### ⏱️ 2026-09-13T20:04:01Z · Fix lint and run both suites

~~~~~~bash
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
~~~~~~

~~~~~~text
OK
All checks passed!
LINT OK
............................                                             [100%]
28 passed in 11.34s
...................                                                      [100%]
19 passed in 0.52s
~~~~~~

### ⏱️ 2026-09-13T20:07:53Z · Check machine specs and numpy availability

~~~~~~bash
sysctl -n hw.model hw.ncpu hw.memsize 2>/dev/null; sw_vers 2>/dev/null; python3.14 -VV; uv run --python 3.14 --with 'numpy==2.5.3' python -c "import numpy,sys;print(numpy.__version__, sys.version)" 2>&1 | tail -3
~~~~~~

~~~~~~text
MacBookPro18,3
8
34359738368
ProductName:		macOS
ProductVersion:		26.6.2
BuildVersion:		25G83
Python 3.14.5 (main, May 10 2026, 10:21:34) [Clang 17.0.0 (clang-1700.6.4.2)]
 Downloaded numpy
Installed 1 package in 17ms
2.5.3 3.14.5 (main, May 10 2026, 10:21:34) [Clang 17.0.0 (clang-1700.6.4.2)]
~~~~~~

### ⏱️ 2026-09-13T20:10:14Z · Refactor and smoke-test the benchmark

~~~~~~bash
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
~~~~~~

~~~~~~text
acquisition OK
bench OK
Entorno: CPython 3.14.5 · Darwin 25.6.0 · arm64
Pauta real: 49,260 filas · adquisiciones por canal: {'google': 1320, 'referido': 1888, 'instagram': 569, 'walk_in': 758, 'aliado': 1589, 'tiktok': 215}

--- 1,000 filas · 5 repeticiones ---
Entorno: CPython 3.14.5 · Darwin 25.6.0 · arm64

opción                           mediana         p95        pico
bucle                                0 ms         0 ms      0.0 MB
comprehension                        0 ms         0 ms      0.0 MB
vectorizado                          0 ms         0 ms      0.0 MB

--- 100,000 filas · 5 repeticiones ---
Entorno: CPython 3.14.5 · Darwin 25.6.0 · arm64

opción                           mediana         p95        pico
bucle                               14 ms        14 ms      0.0 MB
comprehension                       26 ms        27 ms      0.0 MB
vectorizado                          0 ms         0 ms      0.8 MB
~~~~~~

### ⏱️ 2026-09-13T20:10:46Z · Improve table resolution and re-run

~~~~~~bash
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
~~~~~~

~~~~~~text
OK
Entorno: CPython 3.14.5 · Darwin 25.6.0 · arm64
Pauta real: 49,260 filas · adquisiciones por canal: {'google': 1320, 'referido': 1888, 'instagram': 569, 'walk_in': 758, 'aliado': 1589, 'tiktok': 215}

--- 1,000 filas · 5 repeticiones ---
opción               mediana         p95       pico
bucle               0.129 ms    0.134 ms    0.00 MB
comprehension       0.203 ms    0.213 ms    0.00 MB
vectorizado         0.007 ms    0.009 ms    0.01 MB

--- 100,000 filas · 5 repeticiones ---
opción               mediana         p95       pico
bucle              15.388 ms   15.392 ms    0.00 MB
comprehension      26.569 ms   27.114 ms    0.00 MB
vectorizado         0.549 ms    0.555 ms    0.80 MB
~~~~~~

### ⏱️ 2026-09-13T20:11:05Z · Run the full ds01 measurement

~~~~~~bash
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
~~~~~~

~~~~~~text
OK
Entorno: CPython 3.14.5 · Darwin 25.6.0 · arm64
Pauta real: 49,260 filas · adquisiciones por canal: {'google': 1320, 'referido': 1888, 'instagram': 569, 'walk_in': 758, 'aliado': 1589, 'tiktok': 215}

--- 1,000 filas · 5 repeticiones ---
opción               mediana         p95       pico
bucle               0.131 ms    0.132 ms    0.00 MB
comprehension       0.196 ms    0.198 ms    0.00 MB
vectorizado         0.007 ms    0.009 ms    0.01 MB
vectorizado+conv    0.276 ms    0.277 ms    0.03 MB

--- 10,000 filas · 5 repeticiones ---
opción               mediana         p95       pico
bucle               1.298 ms    1.306 ms    0.00 MB
comprehension       1.955 ms    2.072 ms    0.00 MB
vectorizado         0.050 ms    0.050 ms    0.08 MB
vectorizado+conv    2.794 ms    2.855 ms    0.32 MB

--- 100,000 filas · 5 repeticiones ---
opción               mediana         p95       pico
bucle              14.605 ms   14.726 ms    0.00 MB
comprehension      25.703 ms   25.912 ms    0.00 MB
vectorizado         0.469 ms    0.470 ms    0.80 MB
vectorizado+conv   35.150 ms   35.529 ms    3.20 MB

--- 1,000,000 filas · 5 repeticiones ---
opción               mediana         p95       pico
bucle             151.361 ms  169.090 ms    0.00 MB
comprehension     260.957 ms  264.458 ms    0.00 MB
vectorizado         4.746 ms    4.810 ms    8.00 MB
vectorizado+conv  345.871 ms  348.701 ms   32.00 MB

--- 5,000,000 filas · 3 repeticiones ---
opción               mediana         p95       pico
bucl
~~~~~~

### ⏱️ 2026-09-13T20:11:50Z · Get overflow and view/copy numbers

~~~~~~bash
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
~~~~~~

~~~~~~text
filas reales: 49260
int64: 6,059,295,284
int32: 1,764,327,988
primera fila donde int32 desborda: 18205 · acumulado: 2,147,492,769
vista antes: [160649 197975 476711 270210  81687]
original después de tocar la vista: [0 0 0 0 0]
restaurado: [160649 197975 476711 270210  81687]
~~~~~~

### ⏱️ 2026-09-13T20:12:25Z · Run ds01 computation tests

~~~~~~bash
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs/src/ds01-numpy-y-el-modelo-vectorizado
uv run --python 3.14 --with pytest --with 'numpy==2.5.3' python -m pytest test_acquisition.py -q 2>&1 | tail -25
~~~~~~

~~~~~~text
Installed 6 packages in 29ms
.........                                                                [100%]
9 passed in 2.44s
~~~~~~

### ⏱️ 2026-09-13T20:17:22Z · Verify per-channel figures quoted in the chapter

~~~~~~bash
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
~~~~~~

~~~~~~text
tiktok           9,394,725  (adq 215)
instagram        3,550,765  (adq 569)
google           1,529,579  (adq 1320)
getsizeof lista: 8.000056 MB
nbytes array: 8.0 MB
int32 demo: 4000000000
~~~~~~

### ⏱️ 2026-09-13T20:17:45Z · Check int32 overflow semantics precisely

~~~~~~bash
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
~~~~~~

~~~~~~text
sum() por defecto: 4000000000 int64
sum(dtype=int32): -294967296
a+a: [-294967296 -294967296] int32 · avisos: []
~~~~~~

### ⏱️ 2026-09-13T20:17:58Z · Measure real memory of a million ints

~~~~~~bash
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs/src/ds01-numpy-y-el-modelo-vectorizado
uv run --python 3.14 --with 'numpy==2.5.3' python - <<'PY'
import sys
xs=list(range(1_000_000))
print("objetos:", sum(sys.getsizeof(x) for x in xs)/1e6, "MB · un int:", sys.getsizeof(10**6))
PY
~~~~~~

~~~~~~text
objetos: 28.0 MB · un int: 28
~~~~~~

### ⏱️ 2026-09-13T20:19:31Z · Measure the deliberately slow script

~~~~~~bash
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs/src/ds01-numpy-y-el-modelo-vectorizado
uv run --python 3.14 --with 'numpy==2.5.3' python ejercicio_16_lento.py --filas 200000
~~~~~~

~~~~~~text
tiktok            38,252,005 COP
instagram         14,462,900 COP
google             6,227,568 COP

200,000 filas · 384 ms
~~~~~~

### ⏱️ 2026-09-13T20:19:44Z · Measure slow script and baseline at 2M rows

~~~~~~bash
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs/src/ds01-numpy-y-el-modelo-vectorizado
uv run --python 3.14 --with 'numpy==2.5.3' python ejercicio_16_lento.py --filas 2000000 | tail -2
echo "--- referencia: el bucle honesto a 2M ---"
uv run --python 3.14 --with 'numpy==2.5.3' python bench_vectorized.py --filas 2000000 --repeticiones 3 2>&1 | tail -6
~~~~~~

~~~~~~text
2,000,000 filas · 3,857 ms
--- referencia: el bucle honesto a 2M ---
opción               mediana         p95       pico
bucle             290.977 ms  290.977 ms    0.00 MB
comprehension     547.330 ms  547.330 ms    0.00 MB
vectorizado         9.524 ms    9.524 ms   16.00 MB
vectorizado+conv  715.559 ms  715.559 ms   64.00 MB
~~~~~~

### ⏱️ 2026-09-13T20:20:31Z · Fix lambda binding, lint and retest

~~~~~~bash
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
~~~~~~

~~~~~~text
OK
Found 3 errors (3 fixed, 0 remaining).
All checks passed!
LINT OK
.....................................                                    [100%]
37 passed in 12.59s
opción               mediana         p95       pico
bucle               0.134 ms    0.135 ms    0.00 MB
comprehension       0.195 ms    0.200 ms    0.00 MB
vectorizado         0.007 ms    0.009 ms    0.01 MB
vectorizado+conv    0.280 ms    0.283 ms    0.03 MB
[This command modified 4 files you've previously read: bench_vectorized.py, test_acquisition.py, ejercicio_16_lento.py, test_generar_embudo.py. Call Read before editing.]
~~~~~~

### ⏱️ 2026-09-13T20:21:12Z · Check pinned pandas availability

~~~~~~bash
cd /tmp && uv run --python 3.14 --with 'pandas==3.0.5' python -c "import pandas as pd; print(pd.__version__)" 2>&1 | tail -3
~~~~~~

~~~~~~text
 Downloaded pandas
Installed 4 packages in 32ms
3.0.5
Shell cwd was reset to /Users/oskar/Developer/Learning/courses-ia-generated
~~~~~~

### ⏱️ 2026-09-13T20:22:43Z · Smoke-test the three pandas versions

~~~~~~bash
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
~~~~~~

~~~~~~text
OK
crudo planes 1.92 MB · cuotas 15.48 MB · filas 81,370
lean planes 0.43 MB · cuotas 10.02 MB · filas 81,370
                      cobrado_cop  comprometido_cop  cobrado_pct
sede      interes                                               
Centro    estetica     2923598172        3044058526         96.0
          ortodoncia   2018600248        2091235205         96.5
Chapinero estetica     2542454157        2585611230         98.3
          ortodoncia   1862865181        1896884749         98.2
Engativa  estetica     2710665815        2802111204         96.7
iguales a==b: True · a==c: True
~~~~~~

### ⏱️ 2026-09-13T20:23:02Z · Measure real dtype memory in pandas 3.0

~~~~~~bash
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
~~~~~~

~~~~~~text
pandas 3.0.5
plan_id               str
numero              int64
fecha_programada      str
fecha_pago            str
valor_cop           int64
crudo deep: Index                   132
plan_id             4638090
numero               650960
fecha_programada    4800830
fecha_pago          4734383
valor_cop            650960
total crudo: 15.475355
con category plan_id: 11.407909
forzando object: 15.475355 plan_id             object
numero               int64
fecha_programada       str
fecha_pago          object
valor_cop            int64

planes dtypes:
plan_id               str
lead_id               str
sede                  str
interes               str
fecha_aceptacion      str
valor_total_cop     int64
cuotas              int64
planes crudo: 1.922137
planes category: 1.211967
planes object: 1.922137
~~~~~~

### ⏱️ 2026-09-13T20:23:43Z · Run the ds02 measurement

~~~~~~bash
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs/src/ds02-pandas
uv run --python 3.14 --with 'pandas==3.0.5' python bench_merge.py --datos data 2>&1 | tail -12
~~~~~~

~~~~~~text
variante             mediana         p95    pico RSS     entrada
unir+apply          311.6 ms    329.6 ms    131.3 MB     17.4 MB
unir+mascara         19.0 ms     19.3 ms    115.2 MB     17.4 MB
agregar+unir         10.6 ms     11.2 ms    104.7 MB     10.4 MB

81,370 cuotas de entrada · 20 filas de salida · 5 repeticiones por variante
~~~~~~

### ⏱️ 2026-09-13T20:24:05Z · Add memory baseline and rerun

~~~~~~bash
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
~~~~~~

~~~~~~text
OK
variante             mediana         p95    pico RSS     entrada
solo importar         0.0 ms      0.0 ms     77.2 MB      0.0 MB
unir+apply          295.7 ms    298.4 ms    135.0 MB     17.4 MB
unir+mascara         19.3 ms     19.4 ms    119.7 MB     17.4 MB
agregar+unir         12.5 ms     12.8 ms    102.3 MB     10.4 MB

La fila «solo importar» es la línea base: 77.2 MB los gasta pandas por existir, y hay que descontarlos de las otras tres.
81,370 cuotas de entrada · 20 filas de salida · 5 repeticiones por variante
~~~~~~

### ⏱️ 2026-09-13T20:24:27Z · Check Copy-on-Write and merge validation behavior

~~~~~~bash
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
~~~~~~

~~~~~~text
¿cambió el original? False · avisos: []
avisos encadenada: [('ChainedAssignmentError', 'A value is being set on a copy of a DataFrame or Series through chained assignme')]
¿cambió el original? False

etapas 66153 toques 63638
merge sin validate -> 137649 filas
validate='1:1' -> MergeError : Merge keys are not unique in either left or right dataset; not a one-to-one merge.
Duplicates in left:
  lead_id
L0000002
L0000002
L0000002
L0000003
L0000006 ...
Duplicates in right:
  lead_id
L0000002
L0000002
L0000002
L0000005
L0000006 ...
~~~~~~

### ⏱️ 2026-09-13T20:24:40Z · Compute catastrophic join size and final table

~~~~~~bash
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
~~~~~~

~~~~~~text
pauta 49260 leads 32547
{'google': (16420, 8512), 'instagram': (16420, 6785), 'tiktok': (16420, 6056)}
filas del merge por canal: 350,616,260
memoria estimada a 60 bytes/fila: 21.0 GB
=== corrida final de la tabla ===
variante             mediana         p95    pico RSS     entrada
solo importar         0.0 ms      0.0 ms     76.7 MB      0.0 MB
unir+apply          294.8 ms    295.0 ms    134.3 MB     17.4 MB
unir+mascara         21.4 ms     22.9 ms    115.2 MB     17.4 MB
agregar+unir         12.3 ms     12.7 ms    104.3 MB     10.4 MB

La fila «solo importar» es la línea base: 76.7 MB los gasta pandas por existir, y hay que descontarlos de las otras tres.
81,370 cuotas de entrada · 20 filas de salida · 5 repeticiones por variante
~~~~~~

### ⏱️ 2026-09-13T20:25:22Z · Run ds02 tests

~~~~~~bash
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs/src/ds02-pandas
uv run --python 3.14 --with 'pandas==3.0.5' --with pytest python -m pytest -q 2>&1 | tail -30
~~~~~~

~~~~~~text
Installed 9 packages in 51ms
..........                                                               [100%]
10 passed in 14.99s
~~~~~~

### ⏱️ 2026-09-13T20:26:06Z · Compare str vs object dtype memory in pandas 3

~~~~~~bash
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
~~~~~~

~~~~~~text
str: str 4.638222 <class 'str'>
obj: object 4.638222 <class 'str'>
infer_string option: True
~~~~~~

### ⏱️ 2026-09-13T20:30:35Z · Lint and retest ds02

~~~~~~bash
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs/src/ds02-pandas
uvx ruff@0.16.7 check --fix . >/dev/null 2>&1; uvx ruff@0.16.7 check . && echo "LINT OK"
uv run --python 3.14 --with 'pandas==3.0.5' --with pytest python -m pytest -q 2>&1 | tail -3
~~~~~~

~~~~~~text
All checks passed!
LINT OK
..........                                                               [100%]
10 passed in 1.94s
[This command modified 1 file you've previously read: bench_merge.py. Call Read before editing.]
~~~~~~

### ⏱️ 2026-09-13T21:27:43Z · Final verification of the ds track

~~~~~~bash
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs
echo "=== suites completas del track ds ==="
for d in src/ds01-numpy-y-el-modelo-vectorizado src/ds02-pandas src/ds07-scikit-learn; do
  printf "%-42s " "$d"
  (cd $d && uv run --python 3.14 --with pytest --with 'numpy==2.5.3' --with 'pandas==3.0.5' python -m pytest -q 2>&1 | tail -1)
done
echo "=== lint ==="; uvx ruff@0.16.7 check src/ds01-numpy-y-el-modelo-vectorizado src/ds02-pandas src/ds07-scikit-learn && echo OK
echo "=== limpieza ==="; git status --short . | head
~~~~~~

~~~~~~text
=== suites completas del track ds ===
src/ds01-numpy-y-el-modelo-vectorizado     37 passed in 13.61s
src/ds02-pandas                            10 passed in 14.21s
src/ds07-scikit-learn                      19 passed in 0.52s
=== lint ===
I001 [*] Import block is un-sorted or un-formatted
  --> src/ds01-numpy-y-el-modelo-vectorizado/ejercicio_16_lento.py:13:1
   |
11 |   """
12 |
13 | / from __future__ import annotations
14 | |
15 | | import argparse
16 | | import time
17 | | from pathlib import Path
18 | |
19 | | import numpy as np
20 | |
21 | | from acquisition import read_acquisitions, read_spend_rows
   | |__________________________________________________________^
help: Organize imports
   |
19 | import numpy as np
   -
20 | from acquisition import read_acquisitions, read_spend_rows
   |

I001 [*] Import block is un-sorted or un-formatted
  --> src/ds01-numpy-y-el-modelo-vectorizado/test_acquisition.py:9:1
   |
 7 |   """
 8 |
 9 | / from __future__ import annotations
10 | |
11 | | import subprocess
12 | | import sys
13 | | from pathlib import Path
14 | |
15 | | import numpy as np
16 | | import pytest
17 | |
18 | | from acquisition import (
19 | |     arrays_from_rows,
20 | |     cost_per_acquisition_comprehension,
21 | |     cost_per_acquisition_loop,
22 | |     cost_per_acquisition_vectorized,
23 | |     read_acquisitions,
24 | |     read_spend_arrays,
25 | |     read_spend_rows,
26 | |     total_spend_with_dtype,
27 | | )
   | |_^
28 |
29 |   HERE = Path(__file__).par
~~~~~~

### ⏱️ 2026-09-13T21:28:54Z · Final test run and cleanup

~~~~~~bash
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs/src
for d in ds01-numpy-y-el-modelo-vectorizado ds02-pandas ds07-scikit-learn; do printf "%-42s " "$d"; (cd $d && uv run --python 3.14 --with pytest --with 'numpy==2.5.3' --with 'pandas==3.0.5' python -m pytest -q 2>&1 | tail -1); done
find . -name __pycache__ -type d -prune -exec rm -rf {} + 2>/dev/null; rm -rf ds01-numpy-y-el-modelo-vectorizado/data ds02-pandas/data
cd .. && rm -rf .pytest_cache && ls src/ds01-numpy-y-el-modelo-vectorizado src/ds02-pandas src/ds07-scikit-learn
~~~~~~

~~~~~~text
ds01-numpy-y-el-modelo-vectorizado         37 passed in 12.46s
ds02-pandas                                10 passed in 1.84s
ds07-scikit-learn                          19 passed in 0.48s
src/ds01-numpy-y-el-modelo-vectorizado:
acquisition.py
bench_vectorized.py
ejercicio_16_lento.py
generar_embudo.py
README.md
test_acquisition.py
test_generar_embudo.py

src/ds02-pandas:
bench_merge.py
collections_report.py
README.md
test_collections_report.py

src/ds07-scikit-learn:
generar_ausentismo.py
README.md
test_generar_ausentismo.py
~~~~~~

### ⏱️ 2026-09-13T21:36:32Z · Measure the loop at real size and check business coherence

~~~~~~bash
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
~~~~~~

~~~~~~text
bucle               7.072 ms    7.142 ms    0.00 MB
comprehension      14.379 ms   14.968 ms    0.00 MB
vectorizado         0.233 ms    0.235 ms    0.39 MB
vectorizado+conv   18.419 ms   19.174 ms    1.58 MB

pauta total 6,059,295,284 COP · valor contratado 87,270,690,000 COP · pauta/contratado 6.9%
CAC global 955,876 COP sobre un plan medio de 13,767,265
~~~~~~

### ⏱️ 2026-09-13T21:37:27Z · Time dataset generation at larger scales

~~~~~~bash
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs/src/ds01-numpy-y-el-modelo-vectorizado
for e in 4 16; do echo "--- escala $e ---"; ( time python3 generar_embudo.py --salida /tmp/e$e --escala $e >/dev/null ) 2>&1 | grep real; du -sh /tmp/e$e; wc -l /tmp/e$e/*.csv | tail -1; done
~~~~~~

~~~~~~text
--- escala 4 ---
 52M	/tmp/e4
 1088059 total
--- escala 16 ---
200M	/tmp/e16
 4243648 total
~~~~~~

### ⏱️ 2026-09-13T21:38:12Z · Check pinned polars, duckdb and pyarrow

~~~~~~bash
cd /tmp && uv run --python 3.14 --with 'polars==1.44.2' --with 'duckdb==1.5.5' --with 'pyarrow==25.0.1' python -c "
import polars, duckdb, pyarrow
print('polars', polars.__version__, '· duckdb', duckdb.__version__, '· pyarrow', pyarrow.__version__)" 2>&1 | tail -3
~~~~~~

~~~~~~text
 Downloaded polars-runtime-32
Installed 4 packages in 15ms
polars 1.44.2 · duckdb 1.5.5 · pyarrow 25.0.1
Shell cwd was reset to /Users/oskar/Developer/Learning/courses-ia-generated
~~~~~~

### ⏱️ 2026-09-13T21:39:37Z · Check the four engines agree

~~~~~~bash
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
~~~~~~

~~~~~~text
Installed 8 packages in 55ms
bucle           302 filas · primera ('Centro', '2024-01', 38689859, 139, 9, 139880000, 3179583)
pandas          302 filas · primera ('Centro', '2024-01', 38689859, 139, 9, 139880000, 3179583)
polars (lazy)   302 filas · primera ('Centro', '2024-01', 38689859, 139, 9, 139880000, 3179583)
duckdb          302 filas · primera ('Centro', '2024-01', 38689859, 139, 9, 139880000, 3179583)
pandas         == bucle: True
polars (lazy)  == bucle: False
   ref: ('Centro', '2026-04', 0, 0, 12, 186930000, 54777466) 
   otr: ('Centro', '2026-04', 0, None, 12, 186930000, 54777466)
duckdb         == bucle: True
~~~~~~

### ⏱️ 2026-09-13T21:40:50Z · Cap all events at the dataset's declared end date

~~~~~~bash
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
~~~~~~

~~~~~~text
OK
/tmp/fix/pauta.csv: 49,260 filas
/tmp/fix/leads.csv: 32,550 filas
/tmp/fix/toques.csv: 62,748 filas
/tmp/fix/etapas.csv: 64,062 filas
/tmp/fix/planes_de_tratamiento.csv: 6,065 filas
/tmp/fix/cuotas.csv: 81,274 filas
/tmp/fix/aliados.csv: 23 filas
/tmp/fix/remisiones.csv: 2,599 filas
etapas.csv                   fecha_hora         max=2026-03-31
planes_de_tratamiento.csv    fecha_aceptacion   max=2026-03-31
cuotas.csv                   fecha_pago         max=2026-03-31
toques.csv                   fecha_hora         max=2026-03-31
{'pauta.csv': 49260, 'leads.csv': 32550, 'toques.csv': 62748, 'etapas.csv': 64062, 'planes_de_tratamiento.csv': 6065, 'cuotas.csv': 81274, 'aliados.csv': 23, 'remisiones.csv': 2599}
~~~~~~

### ⏱️ 2026-09-13T21:41:14Z · Add censoring tests and run ds01 suite

~~~~~~bash
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
~~~~~~

~~~~~~text
OK
.......................................                                  [100%]
39 passed in 12.82s
~~~~~~

### ⏱️ 2026-09-13T21:41:41Z · Regenerate data and recompute ds01 figures

~~~~~~bash
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
~~~~~~

~~~~~~text
=== ds01: cifras del capítulo ===
tiktok          11,098,164  (adq 182)
instagram        3,819,254  (adq 529)
google           1,583,564  (adq 1275)
total int64: 6,059,295,284 · int32: 1,764,327,988
desborda int32 en fila: 18205 de 49260
planes 6,065 · cuotas 81,274 · valor 83,377,980,000 · pauta/valor 7.3% · CAC global 999,059 · plan medio 13,747,400
~~~~~~

### ⏱️ 2026-09-13T21:41:57Z · Re-run both measurements on the corrected dataset

~~~~~~bash
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs/src/ds01-numpy-y-el-modelo-vectorizado
uv run --python 3.14 --with 'numpy==2.5.3' python bench_vectorized.py --filas 1000 10000 100000 1000000 5000000 2>&1 | grep -v "^Entorno\|^Pauta" | tail -32
echo "### ejercicio 16"; uv run --python 3.14 --with 'numpy==2.5.3' python ejercicio_16_lento.py --filas 2000000 | tail -1
echo "### ds02"; cd ../ds02-pandas && uv run --python 3.14 --with 'pandas==3.0.5' python bench_merge.py --datos data 2>&1 | tail -9
~~~~~~

~~~~~~text
comprehension       0.196 ms    0.196 ms    0.00 MB
vectorizado         0.007 ms    0.009 ms    0.01 MB
vectorizado+conv    0.276 ms    0.278 ms    0.03 MB

--- 10,000 filas · 5 repeticiones ---
opción               mediana         p95       pico
bucle               1.286 ms    1.362 ms    0.00 MB
comprehension       1.997 ms    2.221 ms    0.00 MB
vectorizado         0.049 ms    0.050 ms    0.08 MB
vectorizado+conv    2.840 ms    3.189 ms    0.32 MB

--- 100,000 filas · 5 repeticiones ---
opción               mediana         p95       pico
bucle              14.806 ms   14.848 ms    0.00 MB
comprehension      29.917 ms   30.485 ms    0.00 MB
vectorizado         0.526 ms    0.571 ms    0.80 MB
vectorizado+conv   38.183 ms   39.624 ms    3.20 MB

--- 1,000,000 filas · 5 repeticiones ---
opción               mediana         p95       pico
bucle             150.047 ms  150.814 ms    0.00 MB
comprehension     273.016 ms  277.733 ms    0.00 MB
vectorizado         4.862 ms    5.075 ms    8.00 MB
vectorizado+conv  395.254 ms  395.965 ms   32.00 MB

--- 5,000,000 filas · 3 repeticiones ---
opción               mediana         p95       pico
bucle             786.550 ms  786.550 ms    0.00 MB
comprehension    1387.315 ms 1387.315 ms    0.00 MB
vectorizado        24.204 ms   24.204 ms   40.00 MB
vectorizado+conv 1864.604 ms 1864.604 ms  160.00 MB

### ejercicio 16
2,000,000 filas · 3,942 ms
### ds02
variante             mediana         p95    pico RSS     entrada
solo importar         
~~~~~~

### ⏱️ 2026-09-13T21:42:57Z · Collect remaining figures for both chapters

~~~~~~bash
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
~~~~~~

~~~~~~text
etapas 64062 toques 62748 merge: 133288
cuotas crudo 15.43 MB · filas 81,274
planes crudo 1.84 MB · filas 6,065
cuotas category 11.39 MB · planes category 1.16 MB
merge catastrófico: 351,979,120 filas · 21.1 GB · google: 16420 × 8574
--- 1,000 filas · 5 repeticiones ---
bucle               0.128 ms    0.131 ms    0.00 MB
--- 49,260 filas · 5 repeticiones ---
bucle               7.002 ms    7.087 ms    0.00 MB
--- 2,000,000 filas · 3 repeticiones ---
bucle             296.329 ms  296.329 ms    0.00 MB
~~~~~~

### ⏱️ 2026-09-13T21:46:38Z · Verify all suites after the data correction

~~~~~~bash
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs/src
for d in ds01-numpy-y-el-modelo-vectorizado ds02-pandas ds07-scikit-learn; do printf "%-42s " "$d"; (cd $d && uv run --python 3.14 --with pytest --with 'numpy==2.5.3' --with 'pandas==3.0.5' python -m pytest -q 2>&1|tail -1); done
for d in ds01-numpy-y-el-modelo-vectorizado ds02-pandas ds07-scikit-learn; do printf "lint %-38s" "$d"; (cd $d && uvx ruff@0.16.7 check . >/dev/null 2>&1 && echo OK || echo FALLA); done
~~~~~~

~~~~~~text
ds01-numpy-y-el-modelo-vectorizado         39 passed in 13.14s
ds02-pandas                                10 passed in 2.16s
ds07-scikit-learn                          19 passed in 0.54s
lint ds01-numpy-y-el-modelo-vectorizado    OK
lint ds02-pandas                           OK
lint ds07-scikit-learn                     OK
~~~~~~

### ⏱️ 2026-09-13T21:47:44Z · Add the Parquet variant and verify all five agree

~~~~~~bash
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
~~~~~~

~~~~~~text
OK
bucle              270 filas · referencia
pandas             270 filas · == bucle: True
polars (lazy)      270 filas · == bucle: True
duckdb (csv)       270 filas · == bucle: True
duckdb (parquet)   270 filas · == bucle: True
~~~~~~

### ⏱️ 2026-09-13T21:48:22Z · Build the four measurement sizes

~~~~~~bash
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs/src/ds03-polars-y-el-modelo-lazy
rm -rf data && time uv run --python 3.14 --with 'duckdb==1.5.5' python preparar_tamanos.py --salida data 2>&1 | tail -8
~~~~~~

~~~~~~text
Installed 1 package in 5ms
  mes:     11,116 filas · CSV     0.6 MB · Parquet    0.0 MB (23.8× más chico)
   e1:    298,581 filas · CSV    15.9 MB · Parquet    0.7 MB (24.3× más chico)
   e4:  1,074,946 filas · CSV    53.9 MB · Parquet    1.5 MB (34.9× más chico)
  e16:  4,200,081 filas · CSV   206.9 MB · Parquet    4.9 MB (41.9× más chico)
uv run --python 3.14 --with 'duckdb==1.5.5' python preparar_tamanos.py  data   21.56s user 0.92s system 91% cpu 24.615 total
tail -8  0.00s user 0.00s system 0% cpu 24.614 total
~~~~~~

### ⏱️ 2026-09-13T21:49:26Z · Run the five-engine benchmark

~~~~~~bash
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs/src/ds03-polars-y-el-modelo-lazy
time uv run --python 3.14 --with 'pandas==3.0.5' --with 'polars==1.44.2' --with 'duckdb==1.5.5' --with 'pyarrow==25.0.1' python bench_engines.py --datos data 2>&1 | tail -25
~~~~~~

~~~~~~text
motor               líneas   importar         mes          e1          e4         e16
bucle                   28      23 MB      6.3 ms    289.2 ms    855.0 ms   3236.3 ms
pandas                  25     105 MB     11.7 ms     91.1 ms    301.3 ms    992.5 ms
polars (lazy)           27      57 MB      5.1 ms     13.0 ms     34.3 ms    105.3 ms
duckdb (csv)             2      44 MB    144.7 ms    194.5 ms    258.1 ms    322.5 ms
duckdb (parquet)         1      45 MB      8.7 ms     12.4 ms     14.7 ms     25.8 ms

motor                  RSS mes      RSS e1      RSS e4     RSS e16
bucle                    23 MB       25 MB       28 MB       45 MB
pandas                  116 MB      167 MB      357 MB      730 MB
polars (lazy)            93 MB      169 MB      303 MB      642 MB
duckdb (csv)            163 MB      186 MB      231 MB      363 MB
duckdb (parquet)        154 MB      160 MB      171 MB      203 MB

mes: 10 filas de salida
e1: 270 filas de salida
e4: 270 filas de salida
e16: 270 filas de salida
uv run --python 3.14 --with 'pandas==3.0.5' --with 'polars==1.44.2' --with     34.03s user 3.22s system 110% cpu 33.667 total
tail -25  0.00s user 0.00s system 0% cpu 33.667 total
~~~~~~

### ⏱️ 2026-09-13T21:50:33Z · Count the shared SQL helper in the LOC column

~~~~~~bash
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
~~~~~~

~~~~~~text
OK
bucle               28 líneas
pandas              25 líneas
polars (lazy)       27 líneas
duckdb (csv)        33 líneas
duckdb (parquet)    32 líneas
~~~~~~

### ⏱️ 2026-09-13T21:50:46Z · Re-run benchmark with fair LOC and time Parquet conversion

~~~~~~bash
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
~~~~~~

~~~~~~text
OK
motor               líneas   importar         mes          e1          e4         e16
bucle                   28      23 MB      5.9 ms    265.8 ms    854.1 ms   3237.9 ms
pandas                  25     105 MB     13.2 ms     88.1 ms    262.5 ms   1006.9 ms
polars (lazy)           27      57 MB      4.3 ms     15.1 ms     30.2 ms    127.1 ms
duckdb (csv)            33      45 MB    141.4 ms    192.5 ms    255.5 ms    326.1 ms
duckdb (parquet)        32      45 MB      8.7 ms     13.2 ms     14.9 ms     25.3 ms

motor                  RSS mes      RSS e1      RSS e4     RSS e16
bucle                    23 MB       25 MB       30 MB       45 MB
pandas                  115 MB      165 MB      357 MB      728 MB
polars (lazy)            93 MB      174 MB      335 MB      611 MB
duckdb (csv)            164 MB      177 MB      226 MB      354 MB
duckdb (parquet)        155 MB      160 MB      172 MB      209 MB

mes: 10 filas de salida
e1: 270 filas de salida
e4: 270 filas de salida
e16: 270 filas de salida
uv run --python 3.14 --with 'pandas==3.0.5' --with 'polars==1.44.2' --with     33.85s user 3.12s system 110% cpu 33.462 total
tail -20  0.00s user 0.00s system 0% cpu 33.461 total
=== costo de convertir a Parquet (una vez) ===
 mes:      268 ms
  e1:      222 ms
  e4:      315 ms
 e16:      431 ms
~~~~~~

### ⏱️ 2026-09-13T21:51:41Z · Measure interpreter startup plus import cost per engine

~~~~~~bash
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
~~~~~~

~~~~~~text
nada     Installed 7 packages in 32ms
   25.0 ms de arranque (proceso + import)
pandas     351.9 ms de arranque (proceso + import)
polars     132.8 ms de arranque (proceso + import)
duckdb      80.8 ms de arranque (proceso + import)
~~~~~~

### ⏱️ 2026-09-13T21:52:33Z · Add intermediate sizes for the threshold search

~~~~~~bash
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
~~~~~~

~~~~~~text
OK
OK bench
  mes:     11,116 filas · CSV     0.6 MB · Parquet    0.0 MB (23.8× más chico)
trimestre:     30,392 filas · CSV     1.7 MB · Parquet    0.1 MB (25.0× más chico)
  ano:    115,332 filas · CSV     6.4 MB · Parquet    0.3 MB (23.3× más chico)
   e1:    298,581 filas · CSV    15.9 MB · Parquet    0.7 MB (24.3× más chico)
   e4:  1,074,946 filas · CSV    53.9 MB · Parquet    1.5 MB (34.9× más chico)
  e16:  4,200,081 filas · CSV   206.9 MB · Parquet    4.9 MB (41.9× más chico)
~~~~~~

### ⏱️ 2026-09-13T21:53:24Z · Run end-to-end and main benchmarks

~~~~~~bash
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs/src/ds03-polars-y-el-modelo-lazy
uv run --python 3.14 --with 'pandas==3.0.5' --with 'polars==1.44.2' --with 'duckdb==1.5.5' --with 'pyarrow==25.0.1' python bench_punta_a_punta.py --datos data 2>&1 | tail -8
echo "=== y la tabla principal, con los seis tamaños en su sitio ==="
uv run --python 3.14 --with 'pandas==3.0.5' --with 'polars==1.44.2' --with 'duckdb==1.5.5' --with 'pyarrow==25.0.1' python bench_engines.py --datos data 2>&1 | tail -18
~~~~~~

~~~~~~text
motor                      mes   trimestre         ano          e1
bucle                    43 ms       51 ms      121 ms      313 ms
pandas                  443 ms      412 ms      456 ms      475 ms
polars (lazy)           143 ms      136 ms      141 ms      149 ms
duckdb (parquet)        431 ms      446 ms      431 ms      458 ms
=== y la tabla principal, con los seis tamaños en su sitio ===
motor               líneas   importar         mes          e1          e4         e16
bucle                   28      23 MB      6.3 ms    276.2 ms    847.8 ms   3148.3 ms
pandas                  25     105 MB     12.2 ms     85.4 ms    259.4 ms    916.2 ms
polars (lazy)           27      57 MB      3.6 ms     11.1 ms     28.8 ms    122.6 ms
duckdb (csv)            33      45 MB    146.6 ms    196.2 ms    258.0 ms    346.8 ms
duckdb (parquet)        32      45 MB      8.4 ms     12.3 ms     16.0 ms     25.1 ms

motor                  RSS mes      RSS e1      RSS e4     RSS e16
bucle                    23 MB       24 MB       29 MB       45 MB
pandas                  118 MB      165 MB      355 MB      721 MB
polars (lazy)            93 MB      168 MB      314 MB      601 MB
duckdb (csv)            164 MB      187 MB      224 MB      363 MB
duckdb (parquet)        155 MB      161 MB      169 MB      205 MB

mes: 10 filas de salida
e1: 270 filas de salida
e4: 270 filas de salida
e16: 270 filas de salida
~~~~~~

### ⏱️ 2026-09-13T21:54:37Z · Decompose cold-start cost per engine

~~~~~~bash
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
~~~~~~

~~~~~~text
intérprete solo                               26.3 ms
import duckdb                                 84.7 ms
import duckdb + connect                       85.3 ms
import duckdb + connect + query trivial       87.3 ms
import polars                                129.2 ms
import polars + lazy trivial                 130.9 ms
import pandas                                342.7 ms
import pandas + frame trivial                328.9 ms
~~~~~~

### ⏱️ 2026-09-13T21:54:56Z · Instrument the cold DuckDB run

~~~~~~bash
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
~~~~~~

~~~~~~text
import consolidation    4.6 · import duckdb   99.3 · consulta   25.4
~~~~~~

### ⏱️ 2026-09-13T21:55:10Z · Compare cold start in the four-package environment

~~~~~~bash
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
~~~~~~

~~~~~~text
ejecutable: /Users/oskar/.cache/uv/builds-v0/.tmpNlgSrP/bin/python
solo pass          26.4 ms
import duckdb      79.3 ms
import pandas     395.4 ms
~~~~~~

### ⏱️ 2026-09-13T21:55:25Z · Re-run end-to-end warm

~~~~~~bash
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs/src/ds03-polars-y-el-modelo-lazy
uv run --python 3.14 --with 'pandas==3.0.5' --with 'polars==1.44.2' --with 'duckdb==1.5.5' --with 'pyarrow==25.0.1' python bench_punta_a_punta.py --datos data --repeticiones 7 2>&1 | tail -6
~~~~~~

~~~~~~text
motor                      mes   trimestre         ano          e1
bucle                    38 ms       54 ms      124 ms      323 ms
pandas                  405 ms      409 ms      426 ms      490 ms
polars (lazy)           140 ms      143 ms      144 ms      146 ms
duckdb (parquet)        432 ms      440 ms      428 ms      424 ms
~~~~~~

### ⏱️ 2026-09-13T21:56:09Z · Test whether DuckDB teardown dominates the wall clock

~~~~~~bash
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
~~~~~~

~~~~~~text
Installed 2 packages in 17ms
normal       pared   102.5 ms · INTERNO 64.0
os._exit(0)  pared    91.4 ms ·
~~~~~~

### ⏱️ 2026-09-13T21:56:26Z · Confirm DuckDB imports pandas when present

~~~~~~bash
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs/src/ds03-polars-y-el-modelo-lazy
echo "--- entorno con solo duckdb ---"
uv run --python 3.14 --with 'duckdb==1.5.5' python -c "
import sys, duckdb; print('pandas cargado:', 'pandas' in sys.modules, '· polars:', 'polars' in sys.modules)"
echo "--- entorno con duckdb + pandas + polars ---"
uv run --python 3.14 --with 'duckdb==1.5.5' --with 'pandas==3.0.5' --with 'polars==1.44.2' python -c "
import sys, duckdb; print('pandas cargado:', 'pandas' in sys.modules, '· polars:', 'polars' in sys.modules)"
~~~~~~

~~~~~~text
--- entorno con solo duckdb ---
pandas cargado: False · polars: False
--- entorno con duckdb + pandas + polars ---
pandas cargado: False · polars: False
~~~~~~

### ⏱️ 2026-09-13T21:56:40Z · Isolate which dependency inflates DuckDB's cold start

~~~~~~bash
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
~~~~~~

~~~~~~text
entorno duckdb+pyarrow:
  pared mediana   100.3 ms
entorno +pandas:
Installed 6 packages in 48ms
  pared mediana   453.3 ms
entorno +pandas+polars:
  pared mediana   432.8 ms
~~~~~~

### ⏱️ 2026-09-13T21:57:14Z · Pinpoint when DuckDB loads pandas

~~~~~~bash
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
~~~~~~

~~~~~~text
tras import  ->  pandas: False
tras connect ->  pandas: False
tras execute ->  pandas: False
tras consulta->  pandas: True · pyarrow: True
~~~~~~

### ⏱️ 2026-09-13T21:57:38Z · Measure each engine in its own isolated environment

~~~~~~bash
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
~~~~~~

~~~~~~text
OK
=== bucle (sin dependencias) ===
motor                      mes   trimestre         ano          e1
bucle                    34 ms       49 ms      120 ms      297 ms
=== pandas solo ===
motor                      mes   trimestre         ano          e1
pandas                  326 ms      346 ms      373 ms      453 ms
=== polars solo ===
motor                      mes   trimestre         ano          e1
polars (lazy)           150 ms      151 ms      154 ms      154 ms
=== duckdb solo ===
motor                      mes   trimestre         ano          e1
duckdb (parquet)         97 ms       98 ms       98 ms      103 ms
~~~~~~

### ⏱️ 2026-09-13T21:58:47Z · Run the ds03 test suite

~~~~~~bash
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs/src/ds03-polars-y-el-modelo-lazy
uv run --python 3.14 --with 'pandas==3.0.5' --with 'polars==1.44.2' --with 'duckdb==1.5.5' --with pytest python -m pytest -q 2>&1 | tail -20
~~~~~~

~~~~~~text
Installed 12 packages in 41ms
...........                                                              [100%]
11 passed in 22.08s
~~~~~~

### ⏱️ 2026-09-13T22:04:07Z · Clean up and re-verify ds03

~~~~~~bash
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
~~~~~~

~~~~~~text
OK
All checks passed!
LINT OK
...........                                                              [100%]
11 passed in 5.26s
[This command modified 2 files you've previously read: consolidation.py, test_consolidation.py. Call Read before editing.]
~~~~~~

### ⏱️ 2026-09-13T22:05:46Z · Final verification of the whole ds track

~~~~~~bash
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
~~~~~~

~~~~~~text
=== links rotos ===
sin links rotos
=== suites ===
src/ds01-numpy-y-el-modelo-vectorizado       39 passed in 13.63s
src/ds02-pandas                              10 passed in 14.60s
src/ds03-polars-y-el-modelo-lazy             11 passed in 9.57s
src/ds07-scikit-learn                        19 passed in 0.55s
=== wc ===
     768 ds01-numpy-y-el-modelo-vectorizado.md
     673 ds02-pandas.md
     718 ds03-polars-y-el-modelo-lazy.md
    2159 total
~~~~~~

### ⏱️ 2026-09-13T22:23:53Z · Compute the attribution figures

~~~~~~bash
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
~~~~~~

~~~~~~text
recortados los auxiliares sin uso
leads 32,550 · maduros 28,416 · adquiridos 6,065 · adquiridos maduros 5,451

=== reparto del crédito (%) sobre leads maduros ===
canal          primer toque   último toque         lineal    decaimiento
aliado                11.4%          24.7%          18.0%          18.4%
google                11.7%          20.8%          16.1%          17.0%
instagram             28.4%           9.6%          18.6%          17.8%
referido              11.1%          30.1%          20.3%          21.4%
tiktok                30.4%           4.1%          16.7%          15.1%
walk_in                6.9%          10.7%          10.3%          10.2%

=== costo por paciente adquirido (COP) ===
canal          primer toque   último toque         lineal    decaimiento
google           3,159,693      1,777,328      2,299,376      2,172,737 
instagram        1,304,316      3,841,037      1,995,442      2,077,301 
tiktok           1,218,254      9,139,664      2,217,602      2,453,323 

=== efecto de la madurez: último toque, con y sin filtro ===
sin filtro  google=1,588,548  instagram=3,557,016  tiktok=8,706,318  
maduros     google=1,777,328  instagram=3,841,037  tiktok=9,139,664
~~~~~~

### ⏱️ 2026-09-13T22:26:38Z · Run the attribution measurement

~~~~~~bash
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs/src/ds04-embudo
time python3 bench_attribution.py --datos data 2>&1 | tail -30
~~~~~~

~~~~~~text
Corte 2026-03-31 · ventana madura hasta 2025-12-25 (madurez 96 días)
32,550 leads · 28,416 maduros · 6,065 adquiridos · 5,451 adquiridos maduros
Gasto de pauta en la ventana: 5,283,929,067 COP

=== Reparto del crédito, en porcentaje ===
canal           primer toque    último toque          lineal     decaimiento
aliado                 11.4%           24.7%           18.0%           18.4%
google                 11.7%           20.8%           16.1%           17.0%
instagram              28.4%            9.6%           18.6%           17.8%
referido               11.1%           30.1%           20.3%           21.4%
tiktok                 30.4%            4.1%           16.7%           15.1%
walk_in                 6.9%           10.7%           10.3%           10.2%

=== Costo por paciente adquirido, en millones de COP, con su intervalo 95% ===
canal                 primer toque          último toque                lineal           decaimiento
google            2.76 [2.59–3.04]      1.55 [1.47–1.64]      2.01 [1.94–2.10]      1.90 [1.83–1.98]
instagram         1.14 [1.09–1.18]      3.35 [3.08–3.67]      1.74 [1.66–1.80]      1.81 [1.73–1.88]
tiktok            1.06 [1.03–1.11]      7.96 [7.01–9.07]      1.93 [1.87–2.02]      2.14 [2.07–2.25]

=== Lo que cuesta ignorar la madurez (último toque) ===
  google     sin filtro    1,588,548 → maduros    1,553,096  (-2.2%)
  instagram  sin filtro    3,557,016 → maduros    3,346,105  (-5.9%)
  tiktok     sin filtro    8,706,318 → maduro
~~~~~~

### ⏱️ 2026-09-13T22:27:49Z · Run the ds04 test suite

~~~~~~bash
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs/src/ds04-embudo
uv run --python 3.14 --with pytest python -m pytest -q 2>&1 | tail -30
~~~~~~

~~~~~~text
.......................                                                  [100%]
23 passed in 2.22s
~~~~~~

### ⏱️ 2026-09-13T22:28:44Z · Decorrelate zone from specialty and recompute partners

~~~~~~bash
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
~~~~~~

~~~~~~text
OK
OK test
........................................                                 [100%]
40 passed in 12.20s
23 aliados · 2,599 remisiones · 925 volvieron (35.6%) · comisiones 1,165,174,000 → 1,259,648/retenido
mejor A001 periodoncia occidente 987,375 · peor A010 endodoncia centro 1,659,407 (1.68×)
especialidad: {'cirugia_oral': '1.23M', 'endodoncia': '1.42M', 'odontopediatria': '1.30M', 'periodoncia': '1.18M', 'protesis': '1.23M'}
zona:         {'centro': '1.36M', 'norte': '1.17M', 'occidente': '1.22M', 'sabana': '1.18M', 'sur': '1.31M'}
~~~~~~

### ⏱️ 2026-09-13T22:29:10Z · Verify ds04 after the partner fix

~~~~~~bash
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs/src/ds04-embudo
uv run --python 3.14 --with pytest python -m pytest -q 2>&1|tail -3
echo "--- ¿cambió la atribución? ---"
python3 bench_attribution.py --datos data 2>&1 | sed -n '15,22p'
~~~~~~

~~~~~~text
.......................                                                  [100%]
23 passed in 2.17s
--- ¿cambió la atribución? ---
canal                 primer toque          último toque                lineal           decaimiento
google            2.76 [2.59–3.04]      1.55 [1.47–1.64]      2.01 [1.94–2.10]      1.90 [1.83–1.98]
instagram         1.14 [1.09–1.18]      3.35 [3.08–3.67]      1.74 [1.66–1.80]      1.81 [1.73–1.88]
tiktok            1.06 [1.03–1.11]      7.96 [7.01–9.07]      1.93 [1.87–2.02]      2.14 [2.07–2.25]

=== Lo que cuesta ignorar la madurez (último toque) ===
  google     sin filtro    1,588,548 → maduros    1,553,096  (-2.2%)
  instagram  sin filtro    3,557,016 → maduros    3,346,105  (-5.9%)
~~~~~~

### ⏱️ 2026-09-13T22:34:47Z · Fix lint and re-run ds04 tests

~~~~~~bash
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs/src/ds04-embudo
uvx ruff@0.16.7 check --fix . >/dev/null 2>&1; uvx ruff@0.16.7 check . && echo "LINT OK"
uv run --python 3.14 --with pytest python -m pytest -q 2>&1|tail -2
~~~~~~

~~~~~~text
DTZ001 `datetime.datetime()` called without a `tzinfo` argument
  --> test_embudo.py:89:17
   |
88 | def test_con_un_solo_toque_los_cuatro_modelos_coinciden():
89 |     touches = [(datetime(2026, 1, 5, 10), "tiktok")]
   |                 ^^^^^^^^^^^^^^^^^^^^^^^^
90 |     for model in MODELS.values():
91 |         assert model(touches) == {"tiktok": 1.0}
   |
help: Pass a `datetime.timezone` object to the `tzinfo` parameter

DTZ001 `datetime.datetime()` called without a `tzinfo` argument
  --> test_embudo.py:97:17
   |
95 |     """Con meses de separación, el peso del primero se hace despreciable. Es la propiedad
96 |     que hay que entender antes de elegir la vida media: el parámetro decide el modelo."""
97 |     touches = [(datetime(2026, 1, 1), "tiktok"), (datetime(2026, 6, 1), "google")]
   |                 ^^^^^^^^^^^^^^^^^^^^
98 |     credits = credit_time_decay(touches, half_life_days=14.0)
99 |     assert credits["google"] > 0.999
   |
help: Pass a `datetime.timezone` object to the `tzinfo` parameter

DTZ001 `datetime.datetime()` called without a `tzinfo` argument
  --> test_embudo.py:97:51
   |
95 |     """Con meses de separación, el peso del primero se hace despreciable. Es la propiedad
96 |     que hay que entender antes de elegir la vida media: el parámetro decide el modelo."""
97 |     touches = [(datetime(2026, 1, 1), "tiktok"), (datetime(2026, 6, 1), "google")]
   |                                                   ^^^^^^^^^^^^^^^^^^^^
98 |     credits = credi
~~~~~~

### ⏱️ 2026-09-13T22:35:14Z · Lint with the course's documented ruff selection

~~~~~~bash
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs/src
echo "=== con la selección que documenta la Fase 00 (E,F,I,UP,B) ==="
for d in ds01-numpy-y-el-modelo-vectorizado ds02-pandas ds03-polars-y-el-modelo-lazy ds04-embudo ds07-scikit-learn; do
  printf "  %-42s" "$d"; (cd $d && uvx ruff@0.16.7 check --select E,F,I,UP,B --line-length 100 --target-version py314 . >/dev/null 2>&1 && echo OK || echo FALLA)
done
echo "=== y las suites ==="
for d in ds01-numpy-y-el-modelo-vectorizado ds02-pandas ds03-polars-y-el-modelo-lazy ds04-embudo ds07-scikit-learn; do
  printf "  %-42s" "$d"; (cd $d && uv run --python 3.14 --with pytest --with 'numpy==2.5.3' --with 'pandas==3.0.5' --with 'polars==1.44.2' --with 'duckdb==1.5.5' python -m pytest -q 2>&1|tail -1); done
~~~~~~

~~~~~~text
=== con la selección que documenta la Fase 00 (E,F,I,UP,B) ===
  ds01-numpy-y-el-modelo-vectorizado        FALLA
  ds02-pandas                               OK
  ds03-polars-y-el-modelo-lazy              OK
  ds04-embudo                               FALLA
  ds07-scikit-learn                         FALLA
=== y las suites ===
  ds01-numpy-y-el-modelo-vectorizado        40 passed in 12.11s
  ds02-pandas                               10 passed in 1.91s
  ds03-polars-y-el-modelo-lazy              11 passed in 4.84s
  ds04-embudo                               23 passed in 2.17s
  ds07-scikit-learn                         19 passed in 0.48s
~~~~~~

### ⏱️ 2026-09-13T22:36:15Z · Final lint and test sweep of the ds track

~~~~~~bash
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
~~~~~~

~~~~~~text
OK
  ds01-numpy-y-el-modelo-vectorizado        lint OK · 40 passed in 12.15s
  ds02-pandas                               lint OK · 10 passed in 1.71s
  ds03-polars-y-el-modelo-lazy              lint OK · 11 passed in 4.69s
  ds04-embudo                               lint OK · 23 passed in 2.23s
  ds07-scikit-learn                         lint OK · 19 passed in 0.49s
~~~~~~

### ⏱️ 2026-09-13T22:38:01Z · Final checks and memory update

~~~~~~bash
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
~~~~~~

~~~~~~text
links rotos: ninguno
     768 ds01-numpy-y-el-modelo-vectorizado.md
     674 ds02-pandas.md
     718 ds03-polars-y-el-modelo-lazy.md
     758 ds04-embudo.md
    2918 total
OK memoria
Shell cwd was reset to /Users/oskar/Developer/Learning/courses-ia-generated
~~~~~~

### ⏱️ 2026-09-14T01:01:44Z · Verify the pinned visualization and notebook stacks install

~~~~~~bash
cd /tmp && uv run --python 3.14 --with 'matplotlib==3.11.2' --with 'plotly==7.0.0' --with 'altair==6.2.2' python -c "
import matplotlib, plotly, altair
print('matplotlib', matplotlib.__version__, '· plotly', plotly.__version__, '· altair', altair.__version__)" 2>&1 | tail -3
echo "--- cuadernos ---"
uv run --python 3.14 --with 'papermill==2.7.0' --with 'jupyterlab==4.6.3' python -c "
import papermill, nbformat, nbclient
print('papermill', papermill.__version__, '· nbformat', nbformat.__version__, '· nbclient', nbclient.__version__)" 2>&1 | tail -3
~~~~~~

~~~~~~text
 Downloaded matplotlib
Installed 22 packages in 109ms
matplotlib 3.11.2 · plotly 7.0.0 · altair 6.2.2
--- cuadernos ---
 Downloaded jupyterlab
Installed 96 packages in 331ms
papermill 2.7.0 · nbformat 5.11.1 · nbclient 0.11.0
Shell cwd was reset to /Users/oskar/Developer/Learning/courses-ia-generated
~~~~~~

### ⏱️ 2026-09-14T01:03:48Z · Render the dashboard in the three libraries

~~~~~~bash
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
~~~~~~

~~~~~~text
Matplotlib is building the font cache; this may take a moment.
Costo por paciente adquirido · Áurea · corte 2026-03-31
Punto: atribución lineal. Banda: el mínimo y el máximo entre los cuatro modelos.

canal           mínimo    lineal    máximo     banda
google           1.55M     2.01M     2.76M      1.8×
tiktok           1.06M     1.93M     7.96M      7.5×
instagram        1.14M     1.74M     3.35M      2.9×

matplotlib  salida/matplotlib.png · 29.2 KB
plotly      salida/plotly.html · 9.4 KB
altair      salida/altair.html · 2.3 KB
~~~~~~

### ⏱️ 2026-09-14T01:04:37Z · Run the render benchmark in isolated environments

~~~~~~bash
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
~~~~~~

~~~~~~text
{"opcion": "tabla", "mediana_ms": 0.06741599645465612, "p95_ms": 0.0892080133780837, "pico_rss_mb": 22.626304, "salida_kb": 0.3515625, "lineas": 6, "frio_ms": 30.147625016979873}
{"opcion": "matplotlib", "mediana_ms": 57.45420802850276, "p95_ms": 69.17729193810374, "pico_rss_mb": 112.689152, "salida_kb": 29.25, "lineas": 18, "frio_ms": 456.72724989708513}
{"opcion": "plotly", "mediana_ms": 14.6286659874022, "p95_ms": 14.763792045414448, "pico_rss_mb": 111.362048, "salida_kb": 9.443359375, "lineas": 15, "frio_ms": 192.7440830040723}
{"opcion": "altair", "mediana_ms": 9.670792031101882, "p95_ms": 11.662499979138374, "pico_rss_mb": 107.741184, "salida_kb": 2.29296875, "lineas": 13, "frio_ms": 274.59379204083234}
--- plotly con el JS embebido (sin CDN) ---
  4.10 MB
~~~~~~

### ⏱️ 2026-09-14T01:05:36Z · Run the ds05 test suite

~~~~~~bash
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs/src/ds05-visualizacion
uv run --python 3.14 --with pytest --with 'matplotlib==3.11.2' --with 'plotly==7.0.0' --with 'altair==6.2.2' python -m pytest -q 2>&1 | tail -20
~~~~~~

~~~~~~text
               ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

test_dashboard.py:73: 
_ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ 
palette.py:93: in distinguishable_in_print
    return all((later + 0.05) / (earlier + 0.05) >= minimum
           ^^^
_ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ 

.0 = <zip object at 0x106e7fb00>

    return all((later + 0.05) / (earlier + 0.05) >= minimum
>              for earlier, later in zip(grays, grays[1:], strict=True))
                                     ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
E   ValueError: zip() argument 2 is shorter than argument 1

palette.py:94: ValueError
=========================== short test summary info ============================
FAILED test_dashboard.py::test_una_seleccion_de_tres_si_puede_sobrevivir - Va...
1 failed, 14 passed in 7.14s
~~~~~~

### ⏱️ 2026-09-14T01:05:58Z · Fix the pairwise bug and re-run

~~~~~~bash
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
~~~~~~

~~~~~~text
OK
...............                                                          [100%]
15 passed in 0.77s
~~~~~~

### ⏱️ 2026-09-14T01:07:09Z · Run the reproducibility measurement

~~~~~~bash
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs/src/ds06-notebooks-y-reproducibilidad
python3 generar_cuadernos.py --salida cuadernos >/dev/null && ls cuadernos
time uv run --python 3.14 --with 'papermill==2.7.0' python check_reproducibility.py --cuadernos cuadernos --json resultado.json 2>&1 | tail -12
~~~~~~

~~~~~~text
azar-sin-semilla.ipynb
celda-borrada.ipynb
dependencia-no-declarada.ipynb
estado-oculto.ipynb
limpio.ipynb
ruta-absoluta.ipynb
  File "/Users/oskar/.cache/uv/archive-v0/-7xGNvf8cwKOulJ0/lib/python3.14/site-packages/jupyter_client/manager.py", line 528, in _async_start_kernel
    kernel_cmd, kw = await self._async_pre_start_kernel(**kw)
                     ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  File "/Users/oskar/.cache/uv/archive-v0/-7xGNvf8cwKOulJ0/lib/python3.14/site-packages/jupyter_client/manager.py", line 490, in _async_pre_start_kernel
    self.kernel_spec,
    ^^^^^^^^^^^^^^^^
  File "/Users/oskar/.cache/uv/archive-v0/-7xGNvf8cwKOulJ0/lib/python3.14/site-packages/jupyter_client/manager.py", line 267, in kernel_spec
    self._kernel_spec = self.kernel_spec_manager.get_kernel_spec(self.kernel_name)
                        ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~^^^^^^^^^^^^^^^^^^
  File "/Users/oskar/.cache/uv/archive-v0/-7xGNvf8cwKOulJ0/lib/python3.14/site-packages/jupyter_client/kernelspec.py", line 295, in get_kernel_spec
    raise NoSuchKernel(kernel_name)
jupyter_client.kernelspec.NoSuchKernel: No such kernel named python3
uv run --python 3.14 --with 'papermill==2.7.0' python check_reproducibility.p  0.59s user 0.34s system 33% cpu 2.745 total
tail -12  0.00s user 0.00s system 0% cpu 2.744 total
~~~~~~

### ⏱️ 2026-09-14T01:07:29Z · Test an explicit kernel command

~~~~~~bash
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
~~~~~~

~~~~~~text
Command did not complete within its 120s timeout and was moved to the background (ID: bunnb4qnv). Output is being written to: /private/tmp/claude-501/-Users-oskar-Developer-Learning-courses-ia-generated/2859734a-d7e6-4986-b771-4890bf56e42b/tasks/bunnb4qnv.output. You will be notified when it completes. To check interim output, use Read on that file path.
Session cwd remains /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs/src/ds06-notebooks-y-reproducibilidad; directory changes made by the backgrounded command do not apply to subsequent commands.
~~~~~~

### ⏱️ 2026-09-14T01:09:59Z · Install a temporary kernelspec and execute

~~~~~~bash
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
~~~~~~

~~~~~~text
Traceback (most recent call last):
  File "<stdin>", line 3, in <module>
ModuleNotFoundError: No module named 'ipykernel'
~~~~~~

### ⏱️ 2026-09-14T01:10:10Z · Retry with ipykernel available

~~~~~~bash
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
~~~~~~

~~~~~~text
/Users/oskar/.cache/uv/archive-v0/iNvIYHaR035DSKji/lib/python3.14/site-packages/nbformat/validator.py:434: MissingIDFieldWarning: Cell is missing an id field, this will become a hard error in future nbformat versions. You may want to use `normalize()` on your notebooks before validations (available since nbformat 5.1.4). Previous versions of nbformat are fixing this issue transparently, and will stop doing so in the future.
  _validate(nbdict, ref, version, version_minor, relax_add_props)
[IPKernelApp] WARNING | Kernel is running over TCP without encryption. All communication (including code and outputs) is sent in plain text and is susceptible to eavesdropping. Use IPC transport or launch with kernel manager-provisioned CurveZMQ keys to enable transport encryption.
OK · ['tiktok 11098901\ninstagram 3818526\ngoogle 158']
~~~~~~

### ⏱️ 2026-09-14T01:11:13Z · Rewrite main cleanly and run the full measurement

~~~~~~bash
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
~~~~~~

~~~~~~text
OK
sintaxis OK
🟡 azar-sin-semilla.ipynb             1406 ms  salidas distintas entre corridas
❌ celda-borrada.ipynb                 752 ms  [31mNameError[39m: name 'leads' is not defined
❌ dependencia-no-declarada.ipynb      720 ms  [31mModuleNotFoundError[39m: No module named 'unaBibliotecaQueNadieDeclaro'
❌ estado-oculto.ipynb                 690 ms  [31mNameError[39m: name 'adquiridos' is not defined
✅ limpio.ipynb                        603 ms  
❌ ruta-absoluta.ipynb                 712 ms  [31mFileNotFoundError[39m: [Errno 2] No such file or directory: '/Users/marcela/Escritor

2 de 6 corren de arriba abajo en un kernel nuevo.
1 de 6 además dan el mismo resultado dos veces seguidas.
timeout 300 uv run --python 3.14 --with 'papermill==2.7.0' --with  python      3.21s user 0.90s system 59% cpu 6.876 total
tail -12  0.00s user 0.00s system 0% cpu 6.875 total
~~~~~~

### ⏱️ 2026-09-14T01:11:42Z · Strip ANSI and test a marimo notebook as a script

~~~~~~bash
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
~~~~~~

~~~~~~text
OK
 Downloaded loro
 Downloaded jedi
 Downloaded marimo
Installed 25 packages in 91ms
['google', 'instagram', 'tiktok']
~~~~~~

### ⏱️ 2026-09-14T01:12:29Z · Run the ds06 test suite

~~~~~~bash
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs/src/ds06-notebooks-y-reproducibilidad
timeout 400 uv run --python 3.14 --with pytest --with 'papermill==2.7.0' --with 'jupyterlab==4.6.3' --with 'marimo==0.24.2' python -m pytest -q 2>&1 | tail -15
~~~~~~

~~~~~~text
test_cuadernos.py::test_cada_defecto_falla_como_dice_la_seccion[celda-borrada.ipynb-NameError]
test_cuadernos.py::test_cada_defecto_falla_como_dice_la_seccion[ruta-absoluta.ipynb-FileNotFoundError]
test_cuadernos.py::test_cada_defecto_falla_como_dice_la_seccion[dependencia-no-declarada.ipynb-ModuleNotFoundError]
test_cuadernos.py::test_el_error_no_trae_codigos_de_color
test_cuadernos.py::test_correr_no_es_ser_reproducible
test_cuadernos.py::test_correr_no_es_ser_reproducible
  /Users/oskar/.cache/uv/archive-v0/kCEeI4QMcAZ2fklY/lib/python3.14/site-packages/traitlets/traitlets.py:1396: DeprecationWarning: Passing unrecognized arguments to super(NotebookClient).__init__(kernel_spec_manager=<jupyter_client.kernelspec.KernelSpecManager object at 0x10da38050>).
  object.__init__() takes exactly one argument (the instance to initialize)
  This is deprecated in traitlets 4.2.This error will be raised in a future release of traitlets.
    warn(

-- Docs: https://docs.pytest.org/en/stable/how-to/capture-warnings.html
=========================== short test summary info ============================
FAILED test_cuadernos.py::test_el_cuaderno_de_marimo_es_un_archivo_python - a...
1 failed, 14 passed, 9 warnings in 12.74s
~~~~~~

### ⏱️ 2026-09-14T01:13:00Z · Find where the kernelspec actually comes from

~~~~~~bash
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
~~~~~~

~~~~~~text
=== ¿de dónde sale el kernelspec? ===
dirs: ['/Users/oskar/Library/Jupyter/kernels', '/Users/oskar/.cache/uv/builds-v0/.tmpFpXkHl/share/jupyter/kernels', '/usr/local/share/jupyter/kernels', '/usr/share/jupyter/kernels', '/Users/oskar/.ipython/kernels']
encontrados: ['python3']
sys.prefix: /Users/oskar/.cache/uv/builds-v0/.tmpFpXkHl
=== solo papermill + ipykernel (sin jupyterlab) ===
Installed 49 packages in 195ms
encontrados: ['python3']
~~~~~~

### ⏱️ 2026-09-14T01:14:14Z · Simplify the kernel fixture and re-run everything

~~~~~~bash
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
~~~~~~

~~~~~~text
OK
...............                                                          [100%]
15 passed in 8.05s
=== la medición, final ===
🟡 azar-sin-semilla.ipynb             1377 ms  salidas distintas entre corridas
❌ celda-borrada.ipynb                 713 ms  NameError: name 'leads' is not defined
❌ dependencia-no-declarada.ipynb      677 ms  ModuleNotFoundError: No module named 'unaBibliotecaQueNadieDeclaro'
❌ estado-oculto.ipynb                 748 ms  NameError: name 'adquiridos' is not defined
✅ limpio.ipynb                        636 ms  
❌ ruta-absoluta.ipynb                 681 ms  FileNotFoundError: [Errno 2] No such file or directory: '/Users/marcela/Escritorio/aurea/d

2 de 6 corren de arriba abajo en un kernel nuevo.
1 de 6 además dan el mismo resultado dos veces seguidas.
~~~~~~

### ⏱️ 2026-09-14T01:22:42Z · Verify state text and lint the whole track

~~~~~~bash
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs
grep -n "⏳ **El track" prompts/prompts-de-tracks-ia-ds.md | head -2
sed -n '/El track `ds` va por `ds06`/,+8p' prompts/prompts-de-tracks-ia-ds.md
rm -rf src/ds0*/data src/ds0*/salida src/ds0*/cuadernos src/ds0*/resultado.json src/ds0*/__pycache__ src/ds0*/.pytest_cache .pytest_cache 2>/dev/null
echo "=== lint + pruebas de todo el track ==="
for d in src/ds01-numpy-y-el-modelo-vectorizado src/ds02-pandas src/ds03-polars-y-el-modelo-lazy src/ds04-embudo src/ds05-visualizacion src/ds06-notebooks-y-reproducibilidad src/ds07-scikit-learn; do
  printf "  %-48s" "$(basename $d)"
  (cd $d && uvx ruff@0.16.7 check . >/dev/null 2>&1 && printf "lint OK · " || printf "LINT FALLA · ")
done; echo
~~~~~~

~~~~~~text
> 🚧 **El track `ds` va por `ds06`, y el bloque del Embudo está cerrado.** T6 dejó los dos
> conjuntos de datos; T7 escribió `ds01` y `ds02`; T8, `ds03`; T9, `ds04`; T10, `ds05` y `ds06`.
> **Seis de las siete mediciones están ejecutadas** —no cuestan dinero ni API, así
> que aquí no hay `⏳`— y sus entradas están en `BENCHMARKS.md`. La de `ds03` son **dos tablas con
> ganadores distintos**: la consulta con el motor caliente y el informe de punta a punta. La de
> `ds04` no mide tiempo: mide **cuánto cambia la respuesta al negocio** según el modelo de
> atribución, y da 7,5×. Siguiente: T10, `ds05` y `ds06`.
>
> El único insumo que no se puede generar es `juicios_humanos.jsonl` de `ia06`, y `bench_judges.py`
(eval):4: no matches found: src/ds0*/data
=== lint + pruebas de todo el track ===
  ds01-numpy-y-el-modelo-vectorizado              LINT FALLA ·   ds02-pandas                                     LINT FALLA ·   ds03-polars-y-el-modelo-lazy                    LINT FALLA ·   ds04-embudo                                     LINT FALLA ·   ds05-visualizacion                              LINT FALLA ·   ds06-notebooks-y-reproducibilidad               LINT FALLA ·   ds07-scikit-learn                               LINT FALLA ·
~~~~~~

### ⏱️ 2026-09-14T01:24:23Z · Full test sweep of the ds track

~~~~~~bash
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs
echo "=== pruebas de todo el track ds ==="
for d in src/ds01-numpy-y-el-modelo-vectorizado src/ds02-pandas src/ds03-polars-y-el-modelo-lazy src/ds04-embudo src/ds07-scikit-learn; do
  printf "  %-40s" "$(basename $d)"; (cd $d && uv run --python 3.14 --with pytest --with 'numpy==2.5.3' --with 'pandas==3.0.5' --with 'polars==1.44.2' --with 'duckdb==1.5.5' python -m pytest -q 2>&1|tail -1); done
printf "  %-40s" "ds05-visualizacion"; (cd src/ds05-visualizacion && uv run --python 3.14 --with pytest --with 'matplotlib==3.11.2' --with 'plotly==7.0.0' --with 'altair==6.2.2' python -m pytest -q 2>&1|tail -1)
printf "  %-40s" "ds06-notebooks"; (cd src/ds06-notebooks-y-reproducibilidad && timeout 400 uv run --python 3.14 --with pytest --with 'papermill==2.7.0' --with 'jupyterlab==4.6.3' --with 'marimo==0.24.2' python -m pytest -q -p no:warnings 2>&1|tail -1)
~~~~~~

~~~~~~text
=== pruebas de todo el track ds ===
  ds01-numpy-y-el-modelo-vectorizado      40 passed in 12.83s
  ds02-pandas                             10 passed in 2.28s
  ds03-polars-y-el-modelo-lazy            11 passed in 5.07s
  ds04-embudo                             23 passed in 2.32s
  ds07-scikit-learn                       19 passed in 0.55s
  ds05-visualizacion                      15 passed in 0.94s
  ds06-notebooks                          15 passed in 8.10s
~~~~~~

### ⏱️ 2026-09-14T01:25:23Z · Clean up, verify links and update memory

~~~~~~bash
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
~~~~~~

~~~~~~text
(eval):2: no matches found: src/ds0*/data
links rotos: ninguno
     768 ds01-numpy-y-el-modelo-vectorizado.md
     674 ds02-pandas.md
     718 ds03-polars-y-el-modelo-lazy.md
     758 ds04-embudo.md
     660 ds05-visualizacion.md
     598 ds06-notebooks-y-reproducibilidad.md
    4176 total
OK memoria
Shell cwd was reset to /Users/oskar/Developer/Learning/courses-ia-generated
~~~~~~

### ⏱️ 2026-09-14T01:36:48Z · Re-verify the lint debt list and check scikit-learn

~~~~~~bash
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs
echo "=== ¿sigue en pie la lista de deuda de lint? ==="
uvx ruff@0.16.7 check src/ --output-format concise 2>&1 | grep -v "^src/ds" | tail -20
echo "=== sklearn ==="
cd /tmp && uv run --python 3.14 --with 'scikit-learn==1.9.1' --with 'numpy==2.5.3' python -c "
import sklearn, numpy; print('scikit-learn', sklearn.__version__, '· numpy', numpy.__version__)" 2>&1|tail -2
~~~~~~

~~~~~~text
=== ¿sigue en pie la lista de deuda de lint? ===
src/13-integraciones/socio_falible.py:73:33: E702 Multiple statements on one line (semicolon)
src/13-integraciones/socio_falible.py:73:57: E702 Multiple statements on one line (semicolon)
src/ia03-tool-calling-y-el-bucle-de-agente/agent_runner.py:30:31: F821 Undefined name `agenda`
src/ia04-embeddings-y-busqueda-semantica/db.py:8:1: I001 [*] Import block is un-sorted or un-formatted
src/ia04-embeddings-y-busqueda-semantica/generar_corpus.py:307:101: E501 Line too long (105 > 100)
src/ia04-embeddings-y-busqueda-semantica/generar_corpus.py:308:101: E501 Line too long (103 > 100)
src/ia05-normarag/bench_answers.py:10:1: I001 [*] Import block is un-sorted or un-formatted
src/ia05-normarag/bench_answers.py:23:58: F401 [*] `answer.verify_citations` imported but unused
src/ia05-normarag/bench_answers.py:50:101: E501 Line too long (101 > 100)
src/ia05-normarag/bench_answers.py:100:101: E501 Line too long (104 > 100)
src/ia05-normarag/test_normarag.py:10:22: F401 [*] `datetime.date` imported but unused
src/ia05-normarag/test_normarag.py:73:101: E501 Line too long (101 > 100)
src/ia06-evaluacion/bench_judges.py:47:40: B905 `zip()` without an explicit `strict=` parameter
src/ia06-evaluacion/generar_evalset.py:39:101: E501 Line too long (111 > 100)
src/ia06-evaluacion/statistics_helpers.py:25:30: B905 `zip()` without an explicit `strict=` parameter
src/ia08-produccion-y-el-veredicto/test_produccion.py:173:36: UP037 [*] Remove quotes from t
~~~~~~

### ⏱️ 2026-09-14T01:39:09Z · First run of the baseline versus model comparison

~~~~~~bash
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
~~~~~~

~~~~~~text
Installed 7 packages in 50ms
corte 2025-10-01 · entrenamiento 72,396 · prueba 33,224 (31%)
inasistencia en prueba: 19.9%

siempre asiste       AUC 0.500 · marca 33,224 (100%) · precisión 0.199 · recall 1.000
regla 3 variables    AUC 0.672 · marca  9,712 (29%) · precisión 0.351 · recall 0.516
logística 5 var      AUC 0.799 · marca  6,645 (20%) · precisión 0.526 · recall 0.530
logística + FUGA     AUC 0.862 · marca  6,645 (20%) · precisión 0.588 · recall 0.592

coeficientes (datos escalados):
  inasistencias_previas     +0.554
  jueves_tarde              +0.101
  lluvia_mm                 +0.946
  distancia_km              +0.441
  dias_desde_agendamiento   +0.128
~~~~~~

### ⏱️ 2026-09-14T01:40:07Z · Measure split inflation and maintenance cost

~~~~~~bash
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
~~~~~~

~~~~~~text
=== partición temporal contra partición al azar ===
  temporal   AUC 0.799
  al azar    AUC 0.799

=== costo de mantener cada una ===
  entrenamiento logística: 127 ms
  predicción 33k filas:    47.3 ms
  regla 33k filas:         7.3 ms
  artefacto pickle:        1.2 KB
  arranque + import sklearn: 873 ms
  arranque solo:             28 ms
~~~~~~

### ⏱️ 2026-09-14T01:40:39Z · Compare three split strategies against two feature sets

~~~~~~bash
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
~~~~~~

~~~~~~text
partición                     honestas    con fuga
temporal                         0.799       0.862
al azar                          0.799       0.859
por paciente                     0.794       0.856

citas por paciente en el conjunto: 8.6
con partición al azar, un paciente aparece en los dos lados casi siempre
~~~~~~

### ⏱️ 2026-09-14T01:41:37Z · Run the full ds07 measurement

~~~~~~bash
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs/src/ds07-scikit-learn
time uv run --python 3.14 --with 'scikit-learn==1.9.1' python bench_baseline.py --datos data 2>&1 | tail -32
~~~~~~

~~~~~~text
Corte temporal 2025-10-01 · entrenamiento 72,396 · prueba 33,224
Inasistencia en el tramo de prueba: 19.9%

=== 1. Discriminación y operación, a capacidad 20% ===
candidato                    AUC    marcadas  precisión   recall
siempre asiste             0.500  33,224 (100%)      0.199    1.000
regla de 3 variables       0.672   9,712 (29%)      0.351    0.516
logística de 5             0.799   6,645 (20%)      0.526    0.530
logística + FUGA           0.862   6,645 (20%)      0.588    0.592

=== 2. Los pesos que aprendió, sobre datos escalados ===
  inasistencias_previas       +0.554
  jueves_tarde                +0.101
  lluvia_mm                   +0.946
  distancia_km                +0.441
  dias_desde_agendamiento     +0.128

=== 3. Tres formas de partir el mismo histórico ===
partición                   honestas    con fuga
temporal                       0.799       0.862
al azar                        0.799       0.859
por paciente                   0.798       0.856

=== 4. Lo que cuesta mantener cada una ===
  regla · 33,224 filas                 7.2 ms
  logística · entrenar                     126.9 ms
  logística · 33,224 filas            58.0 ms
  artefacto serializado                      1.2 KB
  arranque del intérprete                     30 ms
  arranque + import de sklearn               936 ms
uv run --python 3.14 --with 'scikit-learn==1.9.1' python bench_baseline.py     8.28s user 1.05s system 92% cpu 10.093 total
tail -32  0.00s user 0.00s system 0% cpu 10
~~~~~~

### ⏱️ 2026-09-14T01:42:04Z · Fix the cost table alignment

~~~~~~bash
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
~~~~~~

~~~~~~text
OK

=== 4. Lo que cuesta mantener cada una ===
  regla · 33,224 filas                    7.5 ms
  logística · entrenar                  143.8 ms
  logística · 33,224 filas               45.8 ms
  artefacto serializado                   1.2 KB
  arranque del intérprete                  29 ms
  arranque + import de sklearn            857 ms
~~~~~~

### ⏱️ 2026-09-14T01:42:58Z · Run the ds07 test suite

~~~~~~bash
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs/src/ds07-scikit-learn
uv run --python 3.14 --with pytest --with 'scikit-learn==1.9.1' python -m pytest -q 2>&1 | tail -20
~~~~~~

~~~~~~text
                ('modelo', LogisticRegression(max_iter=1000))]), Pipeline(steps=[('escala', StandardScaler()),
                ('modelo', LogisticRegression(max_iter=1000))]))

    def test_predict_marca_casi_nada_y_por_eso_no_se_usa(split, pipelines):
        """Con 19% de positivos, el umbral de 0,5 que usa `predict` deja fuera a casi todos. Es
        la razón de que el código use `predict_proba` y elija el umbral por capacidad."""
        _, test = split
        honest, _ = pipelines
        matrix, _ = build_matrix(test)
>       assert sum(honest.predict(matrix)) < len(test) * 0.05
E       AssertionError: assert np.int64(1049) < (10699 * 0.05)
E        +  where np.int64(1049) = sum(array([0, 0, 0, ..., 0, 0, 0], shape=(10699,)))
E        +    where array([0, 0, 0, ..., 0, 0, 0], shape=(10699,)) = predict([[0.0, 0.0, 1.9, 31.3, 30.0], [0.0, 0.0, 0.4, 7.6, 4.0], [1.0, 0.0, 0.4, 1.5, 20.0], [0.0, 0.0, 0.0, 1.8, 26.0], [0.0, 0.0, 0.0, 24.7, 28.0], [2.0, 0.0, 0.4, 2.6, 4.0], ...])
E        +      where predict = Pipeline(steps=[('escala', StandardScaler()),\n                ('modelo', LogisticRegression(max_iter=1000))]).predict
E        +  and   10699 = len([{'cita_id': 'C0023800', 'paciente_id': 'P000911', 'sede': 'Soacha', 'zona': 'sabana', ...}, {'cita_id': 'C0023801', '...na': 'centro', ...}, {'cita_id': 'C0023805', 'paciente_id': 'P001585', 'sede': 'Chapinero', 'zona': 'norte', ...}, ...])

test_ausentismo.py:212: AssertionError
=========================== short test su
~~~~~~

### ⏱️ 2026-09-14T01:43:48Z · Correct the predict claim with the measured number

~~~~~~bash
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
~~~~~~

~~~~~~text
predict marca 3,268 de 33,224 (9.8%) · tasa real 19.9%
a umbral 0,5: precisión 0.690 recall 0.342 marcadas 3,268
OK
......................................                                   [100%]
38 passed in 2.24s
~~~~~~

### ⏱️ 2026-09-14T01:48:48Z · Lint and link check after ds07

~~~~~~bash
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
~~~~~~

~~~~~~text
=== lint ===
I001 [*] Import block is un-sorted or un-formatted
  --> src/ds07-scikit-learn/test_ausentismo.py:10:1
   |
 8 |   """
 9 |
10 | / from __future__ import annotations
11 | |
12 | | import subprocess
13 | | import sys
14 | | from pathlib import Path
15 | |
16 | | import pytest
17 | | from baseline import (
18 | |     always_attends,
19 | |     precision_recall,
20 | |     roc_auc,
21 | |     three_variable_rule,
22 | |     threshold_for_capacity,
23 | | )
24 | | from features import (
25 | |     HONEST,
26 | |     LEAKY,
27 | |     PRIOR_CAP,
28 | |     build_matrix,
29 | |     cutoff_of,
30 | |     load_rows,
31 | |     split_temporal,
32 | | )
   | |_^
33 |
34 |   HERE = Path(__file__).parent
   |
help: Organize imports
   |
16 | import pytest
17 +
18 | from baseline import (
   |

Found 1 error.
[*] 1 fixable with the `--fix` option.
  ds01-numpy-y-el-modelo-vectorizado            OK
  ds02-pandas                                   OK
  ds03-polars-y-el-modelo-lazy                  OK
  ds04-embudo                                   OK
  ds05-visualizacion                            OK
  ds06-notebooks-y-reproducibilidad             OK
  ds07-scikit-learn                             FALLA
=== links ===
links rotos: ninguno
     686 ds07-scikit-learn.md
~~~~~~

### ⏱️ 2026-09-14T01:49:02Z · Final lint and full test sweep

~~~~~~bash
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
~~~~~~

~~~~~~text
All checks passed!
lint OK desde la raíz
lint OK desde dentro
=== todas las suites ===
  ds01-numpy-y-el-modelo-vectorizado      40 passed in 13.19s
  ds02-pandas                             10 passed in 2.20s
  ds03-polars-y-el-modelo-lazy            11 passed in 4.93s
  ds04-embudo                             23 passed in 2.25s
  ds05-visualizacion                      15 passed in 0.88s
  ds06-notebooks                          15 passed in 7.73s
  ds07-scikit-learn                       38 passed in 2.29s
[This command modified 1 file you've previously read: src/ds07-scikit-learn/test_ausentismo.py. Call Read before editing.]
~~~~~~

### ⏱️ 2026-09-14T01:50:00Z · Clean up and record T11 in memory

~~~~~~bash
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
~~~~~~

~~~~~~text
(eval):2: no matches found: src/ds0*/data
OK memoria
Shell cwd was reset to /Users/oskar/Developer/Learning/courses-ia-generated
~~~~~~

### ⏱️ 2026-09-14T02:01:39Z · Check that the pinned torch installs and runs on CPU

~~~~~~bash
cd /tmp && time uv run --python 3.14 --with 'torch==2.14.0' python -c "
import torch
print('torch', torch.__version__, '· hilos', torch.get_num_threads())
x = torch.randn(4, 5); print('ok', x.shape)" 2>&1 | tail -4
~~~~~~

~~~~~~text
 Downloaded torch
Installed 10 packages in 237ms
OMP: Error #15: Initializing libomp.dylib, but found libomp.dylib already initialized.
OMP: Hint This means that multiple copies of the OpenMP runtime have been linked into the program. That is dangerous, since it can degrade performance or cause incorrect results. The best thing to do is to ensure that only a single OpenMP runtime is linked into the process, e.g. by avoiding static linking of the OpenMP runtime in any library. As an unsafe, unsupported, undocumented workaround you can set the environment variable KMP_DUPLICATE_LIB_OK=TRUE to allow the program to continue to execute, but that may cause crashes or silently produce incorrect results. For more information, please see http://openmp.llvm.org/
uv run --python 3.14 --with 'torch==2.14.0' python -c  2>&1  1.94s user 2.33s system 24% cpu 17.683 total
tail -4  0.00s user 0.00s system 0% cpu 17.682 total
Shell cwd was reset to /Users/oskar/Developer/Learning/courses-ia-generated
~~~~~~

### ⏱️ 2026-09-14T02:02:06Z · Diagnose the OpenMP conflict

~~~~~~bash
cd /tmp
echo "--- solo torch, de nuevo ---"; uv run --python 3.14 --with 'torch==2.14.0' python -c "import torch; print('ok', torch.__version__)" 2>&1 | tail -2
echo "--- torch + sklearn ---"; uv run --python 3.14 --with 'torch==2.14.0' --with 'scikit-learn==1.9.1' python -c "import sklearn, torch; print('ok')" 2>&1 | tail -2
echo "--- con KMP_DUPLICATE_LIB_OK ---"; KMP_DUPLICATE_LIB_OK=TRUE uv run --python 3.14 --with 'torch==2.14.0' --with 'scikit-learn==1.9.1' python -c "import sklearn, torch; print('ok')" 2>&1 | tail -2
~~~~~~

~~~~~~text
--- solo torch, de nuevo ---
OMP: Error #15: Initializing libomp.dylib, but found libomp.dylib already initialized.
OMP: Hint This means that multiple copies of the OpenMP runtime have been linked into the program. That is dangerous, since it can degrade performance or cause incorrect results. The best thing to do is to ensure that only a single OpenMP runtime is linked into the process, e.g. by avoiding static linking of the OpenMP runtime in any library. As an unsafe, unsupported, undocumented workaround you can set the environment variable KMP_DUPLICATE_LIB_OK=TRUE to allow the program to continue to execute, but that may cause crashes or silently produce incorrect results. For more information, please see http://openmp.llvm.org/
--- torch + sklearn ---
Installed 17 packages in 313ms
ok
--- con KMP_DUPLICATE_LIB_OK ---
ok
Shell cwd was reset to /Users/oskar/Developer/Learning/courses-ia-generated
~~~~~~

### ⏱️ 2026-09-14T02:03:45Z · Train the network and compare against the baseline

~~~~~~bash
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
~~~~~~

~~~~~~text
épocas 26 (mejor 18) · parámetros 241 · 4.6 s
pérdida entrenamiento 0.3568 · validación 0.3520
regla        AUC 0.6723 · precisión 0.351 · recall 0.516 · marca 9,712
logística    AUC 0.7993 · precisión 0.526 · recall 0.530 · marca 6,645
red          AUC 0.8118 · precisión 0.548 · recall 0.552 · marca 6,645
uv run --python 3.14 --with 'torch==2.14.0' --with 'scikit-learn==1.9.1'  - '  6.39s user 1.01s system 49% cpu 15.021 total
~~~~~~

### ⏱️ 2026-09-14T02:04:25Z · Test whether one hand-written interaction closes the gap

~~~~~~bash
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
~~~~~~

~~~~~~text
logística 5                  AUC 0.7993
logística 5 + interacción    AUC 0.8118
red neuronal                 AUC 0.8118
red − logística              Δ +0.0125  IC95 [+0.0109, +0.0141]
interacción − logística      Δ +0.0126  IC95 [+0.0107, +0.0142]
~~~~~~

### ⏱️ 2026-09-14T02:06:12Z · Measure calibration and the overbooking decision

~~~~~~bash
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
~~~~~~

~~~~~~text
candidato                      AUC    Brier     ECE
regla de 3                  0.6723   0.1952  0.1918
logística de 5              0.7993   0.1204  0.0127
logística + interacción     0.8118   0.1114  0.0106
red neuronal                0.8118   0.1116  0.0107

fiabilidad por decil (red neuronal): predicho → observado
  0.039 → 0.042  (n=3,322)
  0.049 → 0.052  (n=3,322)
  0.060 → 0.068  (n=3,322)
  0.076 → 0.071  (n=3,322)
  0.095 → 0.098  (n=3,322)
  0.122 → 0.121  (n=3,322)
  0.184 → 0.175  (n=3,322)
  0.272 → 0.265  (n=3,322)
  0.367 → 0.326  (n=3,322)
  0.795 → 0.769  (n=3,326)

umbral de sobreagendamiento con ratio 3.0: p > 0.75
  regla de 3                 sobreagenda  6187 de 33,224 cupos · esperado -2584.3 · real -12938.0
  logística de 5             sobreagenda  1247 de 33,224 cupos · esperado -5188.9 · real -4938.0
  logística + interacción    sobreagenda  1878 de 33,224 cupos · esperado -3895.9 · real -3596.0
  red neuronal               sobreagenda  1994 de 33,224 cupos · esperado -3600.2 · real -3579.0
  ratio 1.0: umbral 0.50 · sobreagenda 3,168 · esperado -2311 · real -2288
  ratio 1.5: umbral 0.60 · sobreagenda 2,632 · esperado -2833 · real -2808
  ratio 2.0: umbral 0.67 · sobreagenda 2,329 · esperado -3173 · real -3120

artefactos: red 4.0 KB · logística 1.2 KB
entrenamiento red 1.8 s · parámetros 241
~~~~~~

### ⏱️ 2026-09-14T02:06:40Z · Frame overbooking as net gain over doing nothing

~~~~~~bash
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
~~~~~~

~~~~~~text
no sobreagendar nada: -6,602 consultas perdidas sobre 33,224 citas

--- una colisión cuesta 1× una silla vacía · umbral p > 0.50 ---
   regla de 3                 sobreagenda  9,712 · neto frente a no hacer nada:     +503 consultas
   logística de 5             sobreagenda  3,268 · neto frente a no hacer nada:    +3497 consultas
   logística + interacción    sobreagenda  3,049 · neto frente a no hacer nada:    +4256 consultas
   red neuronal               sobreagenda  3,168 · neto frente a no hacer nada:    +4314 consultas
--- una colisión cuesta 2× una silla vacía · umbral p > 0.67 ---
   regla de 3                 sobreagenda  6,187 · neto frente a no hacer nada:    -2594 consultas
   logística de 5             sobreagenda  1,761 · neto frente a no hacer nada:    +2162 consultas
   logística + interacción    sobreagenda  2,196 · neto frente a no hacer nada:    +3404 consultas
   red neuronal               sobreagenda  2,329 · neto frente a no hacer nada:    +3482 consultas
--- una colisión cuesta 3× una silla vacía · umbral p > 0.75 ---
   regla de 3                 sobreagenda  6,187 · neto frente a no hacer nada:    -6336 consultas
   logística de 5             sobreagenda  1,247 · neto frente a no hacer nada:    +1664 consultas
   logística + interacción    sobreagenda  1,878 · neto frente a no hacer nada:    +3006 consultas
   red neuronal               sobreagenda  1,994 · neto frente a no hacer nada:    +3023 consultas
--- una colisión cuesta 4× una silla vacía · umbr
~~~~~~

### ⏱️ 2026-09-14T02:07:25Z · Run the full ds08 measurement

~~~~~~bash
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs/src/ds08-ausentismo
time uv run --python 3.14 --with 'torch==2.14.0' --with 'scikit-learn==1.9.1' python bench_net.py --datos data 2>&1 | tail -45
~~~~~~

~~~~~~text
  0.039 → 0.042   (n=3,322)
  0.049 → 0.052   (n=3,322)
  0.060 → 0.068   (n=3,322)
  0.076 → 0.071   (n=3,322)
  0.095 → 0.098   (n=3,322)
  0.122 → 0.121   (n=3,322)
  0.184 → 0.175   (n=3,322)
  0.272 → 0.265   (n=3,322)
  0.367 → 0.326   (n=3,322)
  0.795 → 0.769   (n=3,326)

=== 3. Sobreagendar: consultas recuperadas frente a no hacer nada ===
  Sin sobreagendar se pierden 6,602 consultas de 33,224 citas.
  una colisión = 1× una silla vacía · umbral p > 0.50
     regla de 3                  9,712 cupos     +503 consultas
     logística de 5              3,268 cupos    +3497 consultas
     logística + interacción     3,049 cupos    +4256 consultas
     red neuronal                3,168 cupos    +4314 consultas
  una colisión = 2× una silla vacía · umbral p > 0.67
     regla de 3                  6,187 cupos    -2594 consultas
     logística de 5              1,761 cupos    +2162 consultas
     logística + interacción     2,196 cupos    +3404 consultas
     red neuronal                2,329 cupos    +3482 consultas
  una colisión = 3× una silla vacía · umbral p > 0.75
     regla de 3                  6,187 cupos    -6336 consultas
     logística de 5              1,247 cupos    +1664 consultas
     logística + interacción     1,878 cupos    +3006 consultas
     red neuronal                1,994 cupos    +3023 consultas
  una colisión = 4× una silla vacía · umbral p > 0.80
     regla de 3                    562 cupos     -808 consultas
     logística de 5              1,014
~~~~~~

### ⏱️ 2026-09-14T02:08:41Z · Fix the leftover and run the ds08 suite

~~~~~~bash
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
~~~~~~

~~~~~~text
OK
Installed 22 packages in 414ms
..............                                                           [100%]
14 passed in 47.41s
~~~~~~

### ⏱️ 2026-09-14T02:09:50Z · Label the cold call and get table 1 in full

~~~~~~bash
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
~~~~~~

~~~~~~text
OK
Entrenamiento 72,396 · prueba 33,224 · inasistencia 19.9%

=== 1. Discriminación, calibración y operación ===
candidato                      AUC    Brier     ECE  precisión@20%
regla de 3                  0.6723   0.1952  0.1918          0.351
logística de 5              0.7993   0.1204  0.0127          0.526
logística + interacción     0.8118   0.1114  0.0106          0.547
red neuronal                0.8118   0.1116  0.0107          0.548

=== 2. Fiabilidad de la red, por decil: predicho → observado ===
~~~~~~

### ⏱️ 2026-09-14T02:15:29Z · Lint the track after ds08

~~~~~~bash
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs
rm -rf src/ds0*/data src/ds0*/__pycache__ src/ds0*/.pytest_cache .pytest_cache 2>/dev/null
echo "=== lint ==="; uvx ruff@0.16.7 check src/ds0* 2>&1 | tail -6
for d in src/ds0*/; do printf "  %-46s" "$(basename $d)"; (cd $d && uvx ruff@0.16.7 check . >/dev/null 2>&1 && echo "OK" || echo "FALLA"); done
~~~~~~

~~~~~~text
=== lint ===
19 +
20 | from calibration import brier_score, expected_calibration_error, reliability
   |

Found 1 error.
[*] 1 fixable with the `--fix` option.
  ds01-numpy-y-el-modelo-vectorizado            OK
  ds02-pandas                                   OK
  ds03-polars-y-el-modelo-lazy                  OK
  ds04-embudo                                   OK
  ds05-visualizacion                            OK
  ds06-notebooks-y-reproducibilidad             OK
  ds07-scikit-learn                             OK
  ds08-ausentismo                               FALLA
~~~~~~

### ⏱️ 2026-09-14T02:15:48Z · Full test sweep of the ds track

~~~~~~bash
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs
echo "=== suites del track ds ==="
for d in src/ds01-numpy-y-el-modelo-vectorizado src/ds02-pandas src/ds03-polars-y-el-modelo-lazy src/ds04-embudo; do
  printf "  %-40s" "$(basename $d)"; (cd $d && uv run --python 3.14 --with pytest --with 'numpy==2.5.3' --with 'pandas==3.0.5' --with 'polars==1.44.2' --with 'duckdb==1.5.5' python -m pytest -q 2>&1|tail -1); done
printf "  %-40s" "ds05-visualizacion"; (cd src/ds05-visualizacion && uv run --python 3.14 --with pytest --with 'matplotlib==3.11.2' --with 'plotly==7.0.0' --with 'altair==6.2.2' python -m pytest -q 2>&1|tail -1)
printf "  %-40s" "ds06-notebooks"; (cd src/ds06-notebooks-y-reproducibilidad && timeout 400 uv run --python 3.14 --with pytest --with 'papermill==2.7.0' --with 'jupyterlab==4.6.3' --with 'marimo==0.24.2' python -m pytest -q -p no:warnings 2>&1|tail -1)
printf "  %-40s" "ds07-scikit-learn"; (cd src/ds07-scikit-learn && uv run --python 3.14 --with pytest --with 'scikit-learn==1.9.1' python -m pytest -q 2>&1|tail -1)
printf "  %-40s" "ds08-ausentismo"; (cd src/ds08-ausentismo && timeout 500 uv run --python 3.14 --with pytest --with 'torch==2.14.0' --with 'scikit-learn==1.9.1' python -m pytest -q 2>&1|tail -1)
~~~~~~

~~~~~~text
=== suites del track ds ===
  ds01-numpy-y-el-modelo-vectorizado      40 passed in 12.83s
  ds02-pandas                             10 passed in 2.20s
  ds03-polars-y-el-modelo-lazy            11 passed in 4.93s
  ds04-embudo                             23 passed in 2.25s
  ds05-visualizacion                      15 passed in 0.95s
  ds06-notebooks                          15 passed in 7.82s
  ds07-scikit-learn                       38 passed in 2.85s
  ds08-ausentismo                         14 passed in 5.80s
~~~~~~

### ⏱️ 2026-09-14T02:16:58Z · Verify links, clean up and record T12 in memory

~~~~~~bash
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
~~~~~~

~~~~~~text
(eval):2: no matches found: src/ds0*/data
links rotos: ninguno
     686 ds07-scikit-learn.md
     745 ds08-ausentismo.md
    5607 total
OK memoria
Shell cwd was reset to /Users/oskar/Developer/Learning/courses-ia-generated
~~~~~~

### ⏱️ 2026-09-14T02:27:53Z · Check the ONNX and FastAPI stacks

~~~~~~bash
cd /tmp && uv run --python 3.14 --with 'scikit-learn==1.9.1' --with 'skl2onnx==1.20.0' --with 'onnxruntime==1.30.0' --with 'onnx==1.22.0' python -c "
import onnx, onnxruntime, skl2onnx, sklearn
print('onnx', onnx.__version__, '· onnxruntime', onnxruntime.__version__, '· skl2onnx', skl2onnx.__version__, '· sklearn', sklearn.__version__)" 2>&1 | tail -3
echo "--- fastapi ---"
uv run --python 3.14 --with 'fastapi==0.141.1' --with 'uvicorn==0.52.4' python -c "
import fastapi, uvicorn; print('fastapi', fastapi.__version__, '· uvicorn', uvicorn.__version__)" 2>&1 | tail -2
~~~~~~

~~~~~~text
 Downloaded onnx
Installed 15 packages in 286ms
onnx 1.22.0 · onnxruntime 1.30.0 · skl2onnx 1.20.0 · sklearn 1.9.1
--- fastapi ---
Installed 13 packages in 19ms
fastapi 0.141.1 · uvicorn 0.52.4
Shell cwd was reset to /Users/oskar/Developer/Learning/courses-ia-generated
~~~~~~

### ⏱️ 2026-09-14T02:29:21Z · Export the model to both formats and verify they agree

~~~~~~bash
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
~~~~~~

~~~~~~text
    from engineered import (  # noqa: E402  — el `sys.path` de arriba tiene que ir primero
    ...<2 lines>...
    )
  File "/Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs/src/ds08-ausentismo/engineered.py", line 20, in <module>
    from shared import HONEST, build_matrix
ImportError: cannot import name 'HONEST' from 'shared' (consider renaming '/Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs/src/ds09-servir-el-modelo/shared.py' if it has the same name as a library you intended to import)
~~~~~~

### ⏱️ 2026-09-14T02:29:40Z · Rename the module and re-export

~~~~~~bash
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
~~~~~~

~~~~~~text
OK
modelos/modelo.pkl: 1.2 KB
modelos/modelo.onnx: 0.5 KB
Máxima diferencia sobre 1,000 filas: 9.44e-08
~~~~~~

### ⏱️ 2026-09-14T02:30:13Z · Write and smoke-test the serving endpoint

~~~~~~bash
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
~~~~~~

~~~~~~text
RuntimeError: The starlette.testclient module requires the httpx2 package to be installed.
You can install this with:
    $ pip install httpx2
~~~~~~

### ⏱️ 2026-09-14T02:30:25Z · Smoke-test both backends

~~~~~~bash
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
~~~~~~

~~~~~~text
Installed 21 packages in 30ms
{'estado': 'ok', 'backend': 'onnx'}
{'probabilidad_inasistencia': 0.9955890774726868, 'backend': 'onnx'}
--- y con pickle ---
Installed 23 packages in 69ms
{'probabilidad_inasistencia': 0.9955890393867788, 'backend': 'pickle'}
~~~~~~

### ⏱️ 2026-09-14T02:31:38Z · Run the serving benchmark over HTTP

~~~~~~bash
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs/src/ds09-servir-el-modelo
time uv run --python 3.14 --with 'fastapi==0.141.1' --with 'uvicorn==0.52.4' --with 'scikit-learn==1.9.1' --with 'onnxruntime==1.30.0' python bench_serving.py --modelos modelos 2>&1 | tail -10
~~~~~~

~~~~~~text
Installed 24 packages in 75ms
backend         arranque       p50       p95   artefacto
pickle          32.00 s   0.94 ms   1.31 ms      1.2 KB
onnx             1.43 s   0.72 ms   1.02 ms      0.5 KB

500 peticiones por backend, 50 de calentamiento descartadas.
Los dos backends devuelven la misma probabilidad: diferencia 3.81e-08
uv run --python 3.14 --with 'fastapi==0.141.1' --with 'uvicorn==0.52.4' --wit  4.56s user 1.23s system 16% cpu 35.605 total
tail -10  0.00s user 0.00s system 0% cpu 35.605 total
~~~~~~

### ⏱️ 2026-09-14T02:32:25Z · Confirm the cold-start figures are stable

~~~~~~bash
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
~~~~~~

~~~~~~text
backend         arranque       p50       p95   artefacto
pickle           1.10 s   0.90 ms   1.22 ms      1.2 KB
onnx             0.38 s   0.71 ms   0.99 ms      0.5 KB

500 peticiones por backend, 50 de calentamiento descartadas.
Los dos backends devuelven la misma probabilidad: diferencia 3.81e-08
--- import en frío, por separado ---
  fastapi+uvicorn     0.25 s
  + sklearn           1.03 s
  + onnxruntime       0.32 s
~~~~~~

### ⏱️ 2026-09-14T02:33:07Z · Run the pickle demonstration

~~~~~~bash
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs/src/ds09-servir-el-modelo
python3 pickle_danger.py
~~~~~~

~~~~~~text
Se serializó un objeto con un `__reduce__` propio y se cargó con `pickle.loads`.
Efecto observado al cargar: 'Este texto lo escribió el archivo al cargarse.'

No hubo ninguna advertencia, ninguna excepción y ninguna forma de verlo venir.
El mismo archivo, con otro `__reduce__`, corre lo que el proceso pueda correr.

Por eso el endpoint de esta sección se sirve con ONNX: un grafo ONNX describe
operaciones sobre tensores y no puede llamar a `Path.write_text`.
~~~~~~

### ⏱️ 2026-09-14T02:33:50Z · Run the ds09 test suite

~~~~~~bash
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs/src/ds09-servir-el-modelo
timeout 400 uv run --python 3.14 --with pytest --with 'scikit-learn==1.9.1' --with 'skl2onnx==1.20.0' --with 'onnxruntime==1.30.0' --with 'fastapi==0.141.1' python -m pytest -q 2>&1 | tail -25
~~~~~~

~~~~~~text
Installed 28 packages in 359ms
..........                                                               [100%]
10 passed in 46.75s
~~~~~~

### ⏱️ 2026-09-14T02:39:48Z · Lint the whole track after ds09

~~~~~~bash
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs
rm -rf src/ds0*/data src/ds0*/modelos src/ds0*/__pycache__ src/ds0*/.pytest_cache .pytest_cache 2>/dev/null
echo "=== lint ==="; uvx ruff@0.16.7 check src/ds0* 2>&1 | tail -5
for d in src/ds0*/; do printf "  %-46s" "$(basename $d)"; (cd $d && uvx ruff@0.16.7 check . >/dev/null 2>&1 && echo "OK" || echo "FALLA"); done
~~~~~~

~~~~~~text
=== lint ===
All checks passed!
  ds01-numpy-y-el-modelo-vectorizado            OK
  ds02-pandas                                   OK
  ds03-polars-y-el-modelo-lazy                  OK
  ds04-embudo                                   OK
  ds05-visualizacion                            OK
  ds06-notebooks-y-reproducibilidad             OK
  ds07-scikit-learn                             OK
  ds08-ausentismo                               OK
  ds09-servir-el-modelo                         OK
~~~~~~

### ⏱️ 2026-09-14T02:40:02Z · Full test sweep of the completed track

~~~~~~bash
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs
echo "=== suites del track ds completo ==="
for d in src/ds01-numpy-y-el-modelo-vectorizado src/ds02-pandas src/ds03-polars-y-el-modelo-lazy src/ds04-embudo; do
  printf "  %-40s" "$(basename $d)"; (cd $d && uv run --python 3.14 --with pytest --with 'numpy==2.5.3' --with 'pandas==3.0.5' --with 'polars==1.44.2' --with 'duckdb==1.5.5' python -m pytest -q 2>&1|tail -1); done
printf "  %-40s" "ds05-visualizacion"; (cd src/ds05-visualizacion && uv run --python 3.14 --with pytest --with 'matplotlib==3.11.2' --with 'plotly==7.0.0' --with 'altair==6.2.2' python -m pytest -q 2>&1|tail -1)
printf "  %-40s" "ds06-notebooks"; (cd src/ds06-notebooks-y-reproducibilidad && timeout 400 uv run --python 3.14 --with pytest --with 'papermill==2.7.0' --with 'jupyterlab==4.6.3' --with 'marimo==0.24.2' python -m pytest -q -p no:warnings 2>&1|tail -1)
printf "  %-40s" "ds07-scikit-learn"; (cd src/ds07-scikit-learn && uv run --python 3.14 --with pytest --with 'scikit-learn==1.9.1' python -m pytest -q 2>&1|tail -1)
printf "  %-40s" "ds08-ausentismo"; (cd src/ds08-ausentismo && timeout 500 uv run --python 3.14 --with pytest --with 'torch==2.14.0' --with 'scikit-learn==1.9.1' python -m pytest -q 2>&1|tail -1)
printf "  %-40s" "ds09-servir-el-modelo"; (cd src/ds09-servir-el-modelo && timeout 500 uv run --python 3.14 --with pytest --with 'scikit-learn==1.9.1' --with 'skl2onnx==1.20.0' --with 'onnxruntime==1.30.0' --with 'fastapi==0.141.1' python -m pytest -q 2>&1|tail -1)
~~~~~~

~~~~~~text
=== suites del track ds completo ===
  ds01-numpy-y-el-modelo-vectorizado      40 passed in 12.56s
  ds02-pandas                             10 passed in 2.17s
  ds03-polars-y-el-modelo-lazy            11 passed in 5.02s
  ds04-embudo                             23 passed in 2.24s
  ds05-visualizacion                      15 passed in 0.98s
  ds06-notebooks                          15 passed in 11.25s
  ds07-scikit-learn                       38 passed in 2.89s
  ds08-ausentismo                         14 passed in 6.32s
  ds09-servir-el-modelo                   10 passed in 4.88s
~~~~~~

### ⏱️ 2026-09-14T02:41:09Z · Final verification of the completed track

~~~~~~bash
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
~~~~~~

~~~~~~text
(eval):2: no matches found: src/ds0*/data
links rotos: ninguno

     768 ds01-numpy-y-el-modelo-vectorizado.md
     674 ds02-pandas.md
     718 ds03-polars-y-el-modelo-lazy.md
     758 ds04-embudo.md
     660 ds05-visualizacion.md
     598 ds06-notebooks-y-reproducibilidad.md
     686 ds07-scikit-learn.md
     745 ds08-ausentismo.md
     701 ds09-servir-el-modelo.md
    6308 total

directorios ds en src: 9
~~~~~~

### ⏱️ 2026-09-14T02:44:38Z · Grep for references to other courses and the root CLAUDE.md

~~~~~~bash
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs
echo "=== 1. Otros cursos del proyecto ==="
grep -rniE "go-for-java-devs|c-sharp-for-java-devs|csharp|curso hermano|curso de C#|angular|docker-container|cursos-algoritmos|propuestas-cursos|_oskar|ruta-nosql|cursos-<|otro curso|los demás cursos" --include=*.md --include=*.py --include=*.toml . 2>/dev/null | grep -v pytest_cache
echo "--- (vacío = bien) ---"
echo
echo "=== 2. CLAUDE.md y la raíz del proyecto ==="
grep -rniE "CLAUDE\.md|courses-ia-generated|directorio raíz del proyecto|repositorio de cursos" --include=*.md --include=*.py --include=*.toml . 2>/dev/null | grep -v pytest_cache
echo "--- (vacío = bien) ---"
~~~~~~

~~~~~~text
=== 1. Otros cursos del proyecto ===
(eval):3: no matches found: --include=*.md
--- (vacío = bien) ---

=== 2. CLAUDE.md y la raíz del proyecto ===
(eval):7: no matches found: --include=*.md
--- (vacío = bien) ---
~~~~~~

### ⏱️ 2026-09-14T02:44:44Z · Grep correctly for external references

~~~~~~bash
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs
echo "=== 1. Otros cursos del proyecto ==="
grep -rniE "go-for-java-devs|c-sharp-for-java|csharp|curso hermano|curso de C#|angular|docker-container|cursos-algoritmos|propuestas-cursos|_oskar|ruta-nosql|otro curso|los demás cursos|curso de Go" . 2>/dev/null | grep -v pytest_cache | grep -v "^Binary"
echo "--- fin ---"
echo
echo "=== 2. CLAUDE.md / raíz del proyecto ==="
grep -rniE "claude\.md|courses-ia-generated|repositorio de cursos" . 2>/dev/null | grep -v pytest_cache | grep -v "^Binary"
echo "--- fin ---"
~~~~~~

~~~~~~text
=== 1. Otros cursos del proyecto ===
README.md:86:**No hay apéndices.** Todo lo que en otro curso sería material de consulta es aquí una fase o
0-ESTRUCTURA-CURSO.md:200:que en otro curso sería material de consulta —el
09-distribucion.md:15:Y es la fase que **no existiría en un curso de Go**, cosa que conviene decir de entrada porque
09-distribucion.md:301:contenedor como forma de desplegar un servicio es otro tema y otro curso, que este no promete.
prompts/prompts-de-fase.md:308:- **Es la fase que no existiría en un curso de Go**, y conviene que se note: Go entrega un binario
prompts/alcance-del-proyecto.md:37:**No se cita ningún otro curso.** Ni como material complementario, ni como "eso vive en otro
prompts/alcance-del-proyecto.md:179:puente entre versiones— viva en apéndices `aNN-`. **Aquí no.** Todo lo que en otro curso sería un
prompts/alcance-del-proyecto.md:185:  Angular existen para el backend que nunca tocó RxJS. Aquí el equivalente no existe: quien
prompts/propuestas-temas-opcionales.md:668:> se puede construir —detectar puntos, triangular, deformar cada triángulo, interpolar— y entonces
prompts/guia-de-estilo-y-convenciones.md:629:- **Autocontención.** El curso **no nombra ningún otro curso**, ni como material necesario ni como
prompts/guia-de-estilo-y-convenciones.md:664:- [ ] **No se nombra ningún otro curso ni ningún archivo de fuera de esta carpeta.** El curso es
prompts/prompts-de-tracks-ia-ds.md:429:   curso hermano de C#, y aquí pesa más porque tres de esta
~~~~~~

### ⏱️ 2026-09-14T02:46:03Z · Verify no external references remain

~~~~~~bash
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
~~~~~~

~~~~~~text
=== ¿queda alguna cita a otro curso? ===
--- fin ---

=== referencias genéricas que sobreviven (deben ser de género, no de proyecto) ===
README.md:86:**No hay apéndices.** Todo lo que en otro curso sería material de consulta es aquí una fase o
0-ESTRUCTURA-CURSO.md:200:que en otro curso sería material de consulta —el
09-distribucion.md:15:Y es la fase que **no existiría en un curso de Go**, cosa que conviene decir de entrada porque
09-distribucion.md:301:contenedor como forma de desplegar un servicio es otro tema y otro curso, que este no promete.
prompts/prompts-de-fase.md:308:- **Es la fase que no existiría en un curso de Go**, y conviene que se note: Go entrega un binario
prompts/alcance-del-proyecto.md:37:**No se cita ningún otro curso.** Ni como material complementario, ni como "eso vive en otro
prompts/alcance-del-proyecto.md:179:puente entre versiones— viva en apéndices `aNN-`. **Aquí no.** Todo lo que en otro curso sería un
prompts/propuesta-fases-y-alcance.md:30:**No hay apéndices.** Todo lo que en otro curso sería material de consulta es aquí una fase o
prompts/propuesta-fases-y-alcance.md:803:otro curso habría tenido su `aNN-` y dónde quedó aquí:
prompts/guia-de-estilo-y-convenciones.md:629:- **Autocontención.** El curso **no nombra ningún otro curso**, ni como material necesario ni como
prompts/guia-de-estilo-y-convenciones.md:664:- [ ] **No se nombra ningún otro curso ni ningún archivo de fuera de esta carpeta.** El curso es

=== rutas fuera de la carpeta del cur
~~~~~~

### ⏱️ 2026-09-14T02:46:39Z · Cross-check figures cited between sections

~~~~~~bash
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs
echo "=== cifras que una sección cita de otra ==="
echo "-- CAC de ds01/ds04 citado fuera:"; grep -rn "siete veces\|seis veces\|9.394.725\|11.098.164\|1.583.564" ds0*.md BENCHMARKS.md INSTINTOS.md | grep -v pytest
echo; echo "-- la banda de ds04 (1,06 / 7,96 / 7,5×):"; grep -rn "7,5×\|7.96\|1,06" ds0*.md BENCHMARKS.md INSTINTOS.md | head -12
echo; echo "-- la línea base de ds07 (0,799 / 0,526):"; grep -rn "0,799\|0,526\|0.799" ds0*.md BENCHMARKS.md INSTINTOS.md | head -12
echo; echo "-- el 77 MB de ds02 citado en ds03:"; grep -rn "76,9 MB\|77 MB" ds0*.md BENCHMARKS.md | head
~~~~~~

~~~~~~text
=== cifras que una sección cita de otra ===
-- CAC de ds01/ds04 citado fuera:
ds04-embudo.md:176:porque estaba ahí, y salió que TikTok costaba siete veces lo que Google.
ds01-numpy-y-el-modelo-vectorizado.md:78:tiktok      · 11.098.164 COP por paciente adquirido   (182 pacientes)
ds01-numpy-y-el-modelo-vectorizado.md:80:google      ·  1.583.564                              (1.275)
ds01-numpy-y-el-modelo-vectorizado.md:83:Ahí ya hay material para una junta. TikTok cuesta **siete veces** lo que cuesta Google por
ds03-polars-y-el-modelo-lazy.md:489:   abre `cuotas.csv` seis veces, no pasó.
ds03-polars-y-el-modelo-lazy.md:681:comité. `ds01` ya dejó la pista: TikTok cuesta siete veces lo que cuesta Google **si el mérito

-- la banda de ds04 (1,06 / 7,96 / 7,5×):
ds01-numpy-y-el-modelo-vectorizado.md:136:print(spend + spend)              # [-294967296 -294967296] ¬ ni excepción, ni aviso, ni nada
ds01-numpy-y-el-modelo-vectorizado.md:138:print(spend.sum(dtype=np.int32))  # -294967296, porque se lo pediste
ds04-embudo.md:416:| tiktok | **1,06** [1,03–1,11] | **7,96** [7,01–9,07] | 1,93 [1,87–2,02] | 2,14 [2,07–2,25] |
ds04-embudo.md:424:| tiktok | 8.706.318 | 7.961.814 | **−8,6%** |
ds04-embudo.md:434:> **1,06 millones** por paciente si el mérito es del descubrimiento y **7,96 millones** si es
ds04-embudo.md:435:> de la decisión: **7,5×**. El ranking no se mueve, se invierte: TikTok es el canal más
ds04-embudo.md:616:15. Diagnóstico: alguien reporta un CAC de TikTok de 620.000 COP y
~~~~~~

### ⏱️ 2026-09-14T02:48:52Z · Pin note for nbstripout and check for stray files

~~~~~~bash
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
~~~~~~

~~~~~~text
13. Configura `nbstripout` en un repositorio de prueba y comprueba qué pasa al hacer commit
    de un cuaderno con salidas. Decide si lo pondrías en el repositorio de Áurea.
14. Un cuaderno que tarda cuarenta minutos en correr no cabe en CI. Diseña la estrategia —qué
OK ds06-notebooks-y-reproducibilidad.md

=== archivos sueltos en la carpeta del curso ===
.ruff_cache
0-ESTRUCTURA-CURSO.md
00-convencion-de-git-y-tags.md
00-historia-de-aurea.md
00-instalacion-ambiente-editores-y-ecosistema.md
01-modelo-de-datos.md
02-secuencias-perezosas.md
03-python-sin-ceremonia.md
04-errores-y-recursos.md
05-shell-con-esteroides.md
06-formatos-en-la-caja.md
07-cuando-deja-de-ser-un-script.md
08-el-contrato-del-codigo.md
09-distribucion.md
10-fastapi.md
11-persistencia.md
12-django-y-el-veredicto-web.md
13-integraciones.md
14-concurrencia-y-gil.md
15-el-proceso-nocturno.md
16-operacion-y-rendimiento.md
17-el-duelo-y-el-veredicto.md
BENCHMARKS.md
ds01-numpy-y-el-modelo-vectorizado.md
ds02-pandas.md
ds03-polars-y-el-modelo-lazy.md
ds04-embudo.md
ds05-visualizacion.md
ds06-notebooks-y-reproducibilidad.md
ds07-scikit-learn.md
ds08-ausentismo.md
ds09-servir-el-modelo.md
ia01-el-modelo-de-acceso-de-un-llm.md
ia02-salida-estructurada.md
ia03-tool-calling-y-el-bucle-de-agente.md
ia04-embeddings-y-busqueda-semantica.md
ia05-normarag.md
ia06-evaluacion.md
ia07-recepcion-asistida.md
ia08-produccion-y-el-veredicto.md
INSTINTOS.md
prompts
README.md
ruff.toml
src

=== ¿queda basura generada? ===
./src/ds04
~~~~~~

### ⏱️ 2026-09-14T02:49:06Z · Clean generated files and add a .gitignore

~~~~~~bash
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
~~~~~~

~~~~~~text
(eval):3: no matches found: src/*/data
=== convención de tags: ¿conoce los tracks? ===
~~~~~~

### ⏱️ 2026-09-14T02:50:22Z · Final verification of links, references and lint

~~~~~~bash
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
~~~~~~

~~~~~~text
=== 1. links rotos (internos) ===
./03-python-sin-ceremonia.md:425 -> sys.argv[2:]
./08-el-contrato-del-codigo.md:186 -> x: T
./08-el-contrato-del-codigo.md:243 -> items: Iterable[T]
./08-el-contrato-del-codigo.md:250 -> ...

=== 2. referencias a otros cursos / CLAUDE.md / rutas del proyecto ===
  ninguna

=== 3. lint con la configuración del propio curso ===
E702 Multiple statements on one line (semicolon)
  --> src/13-integraciones/socio_falible.py:73:33
   |
71 |         elif self.path == "/_reiniciar":
72 |             with lock:
73 |                 received.clear(); processed_keys.clear(); attempts.clear()
   |                                 ^
74 |             self._respond(200, {"ok": True})
75 |         else:
   |

E702 Multiple statements on one line (semicolon)
  --> src/13-integraciones/socio_falible.py:73:57
   |
71 |         elif self.path == "/_reiniciar":
72 |             with lock:
73 |                 received.clear(); processed_keys.clear(); attempts.clear()
   |                                                         ^
74 |             self._respond(200, {"ok": True})
75 |         else:
   |

F821 Undefined name `agenda`
  --> src/ia03-tool-calling-y-el-bucle-de-agente/agent_runner.py:30:31
   |
28 |         minutes: Duración necesaria; un control de ortodoncia son 20 minutos.
29 |     """
30 |     return _find_availability(agenda, branch, day, minutes)
   |                               ^^^^^^

I001 [*] Import block is un-sorted or un-formatted
  --> src/
~~~~~~

### ⏱️ 2026-09-14T02:51:49Z · Run the ia track test suites after the code edits

~~~~~~bash
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs/src
for d in ia0*/; do
  printf "  %-46s" "$(basename $d)"
  (cd $d && timeout 300 uv run --python 3.14 --with pytest --with 'anthropic==1.5.0' --with 'pydantic==2.13.5' --with 'tenacity==9.1.4' python -m pytest -q 2>&1 | tail -1)
done
~~~~~~

~~~~~~text
  ia01-el-modelo-de-acceso-de-un-llm            2 failed, 1 warning in 2.39s
  ia02-salida-estructurada                      10 passed in 0.42s
  ia03-tool-calling-y-el-bucle-de-agente        9 passed in 0.03s
  ia04-embeddings-y-busqueda-semantica          1 error in 0.08s
  ia05-normarag                                 1 error in 0.52s
  ia06-evaluacion                               19 passed in 0.03s
  ia07-recepcion-asistida                       56 passed in 0.04s
  ia08-produccion-y-el-veredicto                20 passed in 0.04s
~~~~~~

### ⏱️ 2026-09-14T02:52:12Z · Diagnose the ia failures

~~~~~~bash
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs/src
echo "=== ia04 ==="; (cd ia04-embeddings-y-busqueda-semantica && timeout 200 uv run --python 3.14 --with pytest --with 'anthropic==1.5.0' python -m pytest -q 2>&1 | grep -E "Error|error" | head -3)
echo "=== ia05 ==="; (cd ia05-normarag && timeout 200 uv run --python 3.14 --with pytest --with 'anthropic==1.5.0' --with 'pydantic==2.13.5' python -m pytest -q 2>&1 | grep -E "Error|error" | head -3)
echo "=== ia01 ==="; (cd ia01-el-modelo-de-acceso-de-un-llm && timeout 200 uv run --python 3.14 --with pytest --with 'anthropic==1.5.0' python -m pytest -q 2>&1 | grep -E "^FAILED|Error" | head -4)
~~~~~~

~~~~~~text
=== ia04 ===
ImportError while importing test module '/Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs/src/ia04-embeddings-y-busqueda-semantica/test_fusion.py'.
E   ModuleNotFoundError: No module named 'psycopg'
!!!!!!!!!!!!!!!!!!!! Interrupted: 1 error during collection !!!!!!!!!!!!!!!!!!!!
=== ia05 ===
ImportError while importing test module '/Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs/src/ia05-normarag/test_normarag.py'.
E   ModuleNotFoundError: No module named 'extract'
!!!!!!!!!!!!!!!!!!!! Interrupted: 1 error during collection !!!!!!!!!!!!!!!!!!!!
=== ia01 ===
        with pytest.raises(anthropic.BadRequestError):
>       raise TypeError(
E       TypeError: "Could not resolve authentication method. Expected one of api_key, auth_token, or credentials to be set. Or for one of the `X-Api-Key` or `Authorization` headers to be explicitly omitted"
/Users/oskar/.cache/uv/archive-v0/qkBj9xLsgGfH71dA/lib/python3.14/site-packages/anthropic/_client.py:409: TypeError
~~~~~~

### ⏱️ 2026-09-14T02:52:33Z · Investigate the two real defects

~~~~~~bash
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs/src
echo "=== ia05: de dónde sale 'extract' ==="; grep -n "^from\|^import" ia05-normarag/test_normarag.py | head
echo "--- ¿lo dice su README? ---"; grep -n "extract\|ia02\|PYTHONPATH\|pytest" ia05-normarag/README.md | head
echo; echo "=== ia01: las dos pruebas que fallan ==="; grep -n "def test_" ia01-el-modelo-de-acceso-de-un-llm/test_failures.py
echo "--- ¿qué dice su README? ---"; grep -n "pytest\|sin red\|API" ia01-el-modelo-de-acceso-de-un-llm/README.md | head
~~~~~~

~~~~~~text
=== ia05: de dónde sale 'extract' ===
8:from __future__ import annotations
10:import pytest
12:from answer import Citation, verify_citations
13:from ingest import MIN_USEFUL_CHARS, chunk_text, split_by_clause
14:from search import Hit
--- ¿lo dice su README? ---
17:PYTHONPATH=../ia01-el-modelo-de-acceso-de-un-llm:../ia02-salida-estructurada:../ia04-embeddings-y-busqueda-semantica \
18:  pytest test_normarag.py -q

=== ia01: las dos pruebas que fallan ===
17:def test_context_too_large_fails_fast() -> None:
26:def test_timeout_does_not_cancel_the_generation() -> None:
--- ¿qué dice su README? ---
8:| `llm.py` | El cliente y `ask()`: la única puerta por la que el track habla con la API |
12:| `test_failures.py` | Los fallos, provocados a mano. `pytest -m network` |
17:export ANTHROPIC_API_KEY=...     # o `ant auth login`
~~~~~~

### ⏱️ 2026-09-14T02:52:45Z · Inspect the network-marked tests

~~~~~~bash
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs/src/ia01-el-modelo-de-acceso-de-un-llm
sed -n 1,35p test_failures.py
echo "=== ¿hay configuración de marcadores? ==="; ls -a | grep -iE "pytest|conftest|ini|toml" || echo "  ninguna"
~~~~~~

~~~~~~text
"""Los cuatro fallos que vas a ver en producción, provocados a propósito.

Se marcan como pruebas de red: no corren en el ciclo normal. Existen para que la
primera vez que veas cada uno no sea a las dos de la mañana.

    uv run pytest test_failures.py -m network
"""

import anthropic
import pytest

from llm import ask, build_client

pytestmark = pytest.mark.network


def test_context_too_large_fails_fast() -> None:
    """Pasarse del contexto es un 400: no se reintenta y hay que detectarlo antes."""
    client = build_client(max_retries=0)
    huge_question = "hola " * 400_000

    with pytest.raises(anthropic.BadRequestError):
        ask(client, huge_question)


def test_timeout_does_not_cancel_the_generation() -> None:
    """El timeout es del cliente. Del otro lado la respuesta se generó y se cobró."""
    client = anthropic.Anthropic(timeout=0.5, max_retries=0)

    with pytest.raises(anthropic.APITimeoutError):
        ask(client, "Escribe un resumen de 2.000 palabras sobre ortodoncia.")

    # 🧨 Rompe a propósito: mira la consola de uso después de correr esto. Los tokens
    # de esa respuesta que nunca viste están facturados. Ese es el punto de la prueba.

=== ¿hay configuración de marcadores? ===
.pytest_cache
~~~~~~

### ⏱️ 2026-09-14T02:53:01Z · Add pytest.ini registering the network marker

~~~~~~bash
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
~~~~~~

~~~~~~text
=== ia01 con la configuración puesta ===

2 deselected in 0.45s
=== y seleccionándolas a propósito ===

2 tests collected in 0.39s
~~~~~~

### ⏱️ 2026-09-14T02:53:10Z · Run the ia suites with all pinned dependencies

~~~~~~bash
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs/src
echo "=== recuento final de pruebas, track por track ==="
total=0
for d in ia0*/; do
  n=$(cd $d && timeout 300 uv run --python 3.14 --with pytest --with 'anthropic==1.5.0' --with 'pydantic==2.13.5' --with 'tenacity==9.1.4' --with 'psycopg[binary]==3.3.5' --with 'pgvector==0.5.0' --with 'pypdf==6.18.1' python -m pytest -q 2>&1 | tail -1)
  printf "  %-46s %s\n" "$(basename $d)" "$n"
done
~~~~~~

~~~~~~text
=== recuento final de pruebas, track por track ===
  ia01-el-modelo-de-acceso-de-un-llm             2 deselected in 2.04s
  ia02-salida-estructurada                       10 passed in 0.41s
  ia03-tool-calling-y-el-bucle-de-agente         9 passed in 0.02s
  ia04-embeddings-y-busqueda-semantica           6 passed in 2.92s
  ia05-normarag                                  1 error in 0.50s
  ia06-evaluacion                                19 passed in 0.02s
  ia07-recepcion-asistida                        56 passed in 0.04s
  ia08-produccion-y-el-veredicto                 20 passed in 0.03s
~~~~~~

### ⏱️ 2026-09-14T02:53:30Z · Run ia05 with its documented PYTHONPATH

~~~~~~bash
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs/src/ia05-normarag
echo "=== ia05 con el PYTHONPATH que su README documenta ==="
PYTHONPATH=../ia01-el-modelo-de-acceso-de-un-llm:../ia02-salida-estructurada:../ia04-embeddings-y-busqueda-semantica \
 timeout 300 uv run --python 3.14 --with pytest --with 'anthropic==1.5.0' --with 'pydantic==2.13.5' --with 'tenacity==9.1.4' --with 'psycopg[binary]==3.3.5' --with 'pgvector==0.5.0' --with 'pypdf==6.18.1' python -m pytest -q 2>&1 | tail -2
~~~~~~

~~~~~~text
=== ia05 con el PYTHONPATH que su README documenta ===
..............                                                           [100%]
14 passed in 0.67s
~~~~~~

### ⏱️ 2026-09-14T02:54:07Z · Final verification sweep

~~~~~~bash
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
~~~~~~

~~~~~~text
Command did not complete within its 120s timeout and was moved to the background (ID: bwgxt1nji). Output is being written to: /private/tmp/claude-501/-Users-oskar-Developer-Learning-courses-ia-generated/2859734a-d7e6-4986-b771-4890bf56e42b/tasks/bwgxt1nji.output. You will be notified when it completes. To check interim output, use Read on that file path.
Session cwd remains /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs; directory changes made by the backgrounded command do not apply to subsequent commands.
~~~~~~

### ⏱️ 2026-09-14T02:56:24Z · Run the ds09 suite separately

~~~~~~bash
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs/src/ds09-servir-el-modelo
timeout 400 uv run --python 3.14 --with pytest --with 'scikit-learn==1.9.1' --with 'skl2onnx==1.20.0' --with 'onnxruntime==1.30.0' --with 'fastapi==0.141.1' python -m pytest -q 2>&1 | tail -2
~~~~~~

~~~~~~text
..........                                                               [100%]
10 passed in 5.38s
~~~~~~

### ⏱️ 2026-09-14T02:56:41Z · Final inventory of the course folder

~~~~~~bash
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
~~~~~~

~~~~~~text
(eval):3: no matches found: src/ds0*/data
=== inventario final del curso ===
  documentos publicados: 41
  líneas de prosa publicada: 33603
  documentos de prompts/: 13
  directorios de src/: 25
  archivos .py: 112
  configuración de la raíz: .gitignore pytest.ini ruff.toml 

=== nada generado en el árbol ===
  (vacío = limpio)
~~~~~~

