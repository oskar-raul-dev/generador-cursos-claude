# Commands of session 5c52573d (05/10/2026) that touched go-for-java-devs-20261005-ab98, in order, as they ran.
# A log, not a script: run one block at a time, from the directory each block cd's into.
# Rescued from the session transcript by ../python-for-java-devs-20261006-772f/04-carta-5c52573d/comandos.sh.

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

