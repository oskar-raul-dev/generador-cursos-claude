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
                "🪞", "🩻", "⚰️", "📖",
                "⏳", "🔜"}  # las dos convenciones de lo pendiente (formato-de-mediciones §2.6 y §2.9)
    # Emoji con moderación en ###: los de las secciones recurrentes y los marcadores no avisan.
    # (el verificador revisa carácter por carácter: van también sin el U+FE0F).
    EMOJI_PERMITIDOS_H3 = PerfilCoursesIA.EMOJI_PERMITIDOS_H3 | CALLOUTS | {c.replace("\ufe0f", "") for c in CALLOUTS}
    # El encabezado de fase de la plantilla (guía §8.1).
    CAMPOS_ENCABEZADO = ("Fase ", "Depende de", "Estilo de esta fase", "Proyecto que avanza")
    # 00-historia y 00-convencion llevan número de fase pero no son fases.
    NO_CAPITULO = PerfilCoursesIA.NO_CAPITULO + ("historia", "convencion")

    def verificar_capitulo_extra(self, ruta, lineas, texto, preguntas):
        nombre = self.rel(ruta)
        titulos = [l for _, l in lineas if l.startswith("## ")]
        for seccion in SECCIONES_DE_FASE:
            # La F24 no tiene software nuevo: su sección 5 es «Lo que se escribe en esta fase».
            alternativas = (seccion, "5. Lo que se escribe") if seccion.startswith("5.") else (seccion,)
            if not any(a in t for a in alternativas for t in titulos):
                self.aviso("SECCION", f"{nombre}: falta «{seccion}»")
        self.verificar_ejercicios(nombre, lineas)

    def verificar_documento_extra(self, ruta, lineas, texto):
        # `lineas` llega sin los bloques de código: los diagramas se buscan en el texto crudo.
        self.verificar_diagramas(self.rel(ruta), enumerate(texto.splitlines(), 1))

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
