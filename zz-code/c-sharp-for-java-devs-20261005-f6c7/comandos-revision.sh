# Commands of session 5c52573d (05/10/2026) that touched c-sharp-for-java-devs-20261005-f6c7, in order, as they ran.
# A log, not a script: run one block at a time, from the directory each block cd's into.
# Rescued from the session transcript by ../python-for-java-devs-20261006-772f/04-carta-5c52573d/comandos.sh.

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

# --- 2026-10-05T15:13:32 · Run verifiers and diagram scan on go course
cd /Users/oskar/Developer/Learning/courses-ia-generated; G=cursos-algoritmos-lenguajes/go-for-java-devs; Z=zz-code/go-for-java-devs-20261005-ab98; mkdir -p $Z/salidas; cp zz-code/c-sharp-for-java-devs-20261005-f6c7/buscar_diagramas.py $Z/; python3 -B zz-instrucciones/herramientas/verificador_base.py $G --perfil=courses-ia > $Z/salidas/antes.log 2>&1; python3 -B zz-instrucciones/herramientas/verificador_base.py $G --perfil=publicacion > $Z/salidas/publicacion.log 2>&1; tail -1 $Z/salidas/antes.log; awk '{print $1,$2}' $Z/salidas/antes.log | sort | uniq -c; echo; grep "^ERROR" $Z/salidas/antes.log | head -20; echo; grep "^ERROR" $Z/salidas/publicacion.log | grep -v EMOJI | head; echo; grep "CALLOUT" $Z/salidas/antes.log | awk '{print $NF}' | sort | uniq -c; echo; python3 $Z/buscar_diagramas.py $G | tee $Z/salidas/diagramas.log; grep -rn '```mermaid' $G | wc -l

