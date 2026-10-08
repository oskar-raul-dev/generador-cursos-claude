#!/usr/bin/env python3
"""Verificador de los bancos de preguntas de `preguntas-entrevista/`.

Subclase de `verificador_base.py` (copia del verificador común de los cursos, 2026-10-07): las
validaciones base —enlaces y anclas (con el U+FE0F que GitHub conserva y los enlaces cuyo texto
cruza un salto de línea), restos de plantilla, emoji en ###, callouts— vienen de allí. Los bancos no
tienen guía de estilo propia: su formato es el que declara el CLAUDE.md del repositorio, «pregunta en
negrita numerada + 🟢🟡🟠🔴, respuesta en el párrafo siguiente», y es el que se comprueba aquí.

Uso, desde `preguntas-entrevista/`:
    python3 -B prompts/verificar-corpus.py
    python3 -B prompts/verificar-corpus.py --corregir-fe0f    # reescribe las anclas ANCLA-FE0F

Lo que cambia respecto de la base:
  - No hay capítulos con «🧠 Preguntas» ni solucionario: cada banco `NN-*.md` (también los de
    `springboot/`) se valida con las reglas de abajo.
  - Sin «Vigencia» obligatoria en el encabezado, y 🧭 es callout admitido (el cierre de cada banco).

Validaciones propias, además de las base:
  ERROR PREGUNTA   línea que empieza como pregunta (`**N.`) y no es `**N. 🟢 Enunciado**`
  ERROR NUMERO     preguntas que no van 1, 2, 3… sin saltos ni repetidas
  ERROR TOTAL      el título dice «N preguntas» y el banco tiene otro número
  ERROR PARTE      pregunta fuera del rango «(a–b)» de su sección `##`
  ERROR RESPUESTA  pregunta sin respuesta en la línea siguiente
"""

import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from verificador_base import PerfilRepasoEntrevistas, main  # noqa: E402

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
BANCO_RE = re.compile(r"^\d{2}-.*\.md$")
INICIO_RE = re.compile(r"^\*\*(\d+)\.")
PREGUNTA_RE = re.compile(r"^\*\*(\d+)\. [🟢🟡🟠🔴] \S.*\*\*\s*$")
PARTE_RE = re.compile(r"\((\d+)[–-](\d+)\)\s*$")
TOTAL_RE = re.compile(r"\b(\d+) preguntas\b")


class VerificadorBancos(PerfilRepasoEntrevistas):
    CALLOUTS = PerfilRepasoEntrevistas.CALLOUTS | {"🧭"}
    CAMPOS_ENCABEZADO = ()
    CAPITULO_RE = re.compile(r"^$")          # no hay capítulos con solucionario: ver abajo

    def verificar_documento_extra(self, ruta, lineas, texto):
        if not BANCO_RE.match(os.path.basename(ruta)):
            return
        nombre = self.rel(ruta)
        siguiente = dict(lineas)
        numeros, rango = [], None
        for n, linea in lineas:
            if linea.startswith("## "):
                m = PARTE_RE.search(linea)
                rango = (int(m.group(1)), int(m.group(2))) if m else None
                continue
            inicio = INICIO_RE.match(linea)
            if not inicio:
                continue
            k = int(inicio.group(1))
            numeros.append(k)
            if not PREGUNTA_RE.match(linea):
                self.error("PREGUNTA", f"{nombre}:{n} → {linea.strip()[:80]}")
            if rango and not rango[0] <= k <= rango[1]:
                self.error("PARTE", f"{nombre}:{n} → la pregunta {k} está en la parte ({rango[0]}–{rango[1]})")
            respuesta = siguiente.get(n + 1, "")
            if not respuesta.strip() or INICIO_RE.match(respuesta):
                self.error("RESPUESTA", f"{nombre}:{n} → la pregunta {k} no tiene respuesta debajo")
        if numeros != list(range(1, len(numeros) + 1)):
            saltos = [b for a, b in zip([0] + numeros, numeros) if b != a + 1]
            self.error("NUMERO", f"{nombre}: la numeración salta o se repite en {saltos[:5]}")
        titulo = next((l for _, l in lineas if l.startswith("# ")), "")
        total = TOTAL_RE.search(titulo)
        if total and int(total.group(1)) != len(numeros):
            self.error("TOTAL", f"{nombre}: el título dice {total.group(1)} preguntas y hay {len(numeros)}")


if __name__ == "__main__":
    sys.exit(main(VerificadorBancos, RAIZ))
