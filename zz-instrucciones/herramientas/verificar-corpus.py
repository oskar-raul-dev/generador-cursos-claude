#!/usr/bin/env python3
"""Verificador del curso {{nombre-del-curso}} (§{{N}} de la guía).

Plantilla: se copia a `prompts/verificar-corpus.py` junto con `prompts/verificador_base.py`, se
ajustan los atributos de la subclase y se agregan las validaciones propias en los ganchos. Las
validaciones base (enlaces, anclas, restos de plantilla, emoji en ###, sincronía con el solucionario,
bandas, callouts…) vienen de `verificador_base.py` y no se copian aquí.

Uso, desde la raíz del curso:
    python3 prompts/verificar-corpus.py               # todo el curso
    python3 prompts/verificar-corpus.py 04-bloque     # solo un bloque

Validaciones propias de este curso, además de las base:
  ERROR {{CODIGO}}  {{qué comprueba}}
  aviso {{CODIGO}}  {{qué comprueba}}
"""

import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from verificador_base import PerfilCoursesIA, PerfilRepasoEntrevistas, Verificador, main  # noqa: E402,F401

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


class VerificadorDelCurso(Verificador):  # o PerfilRepasoEntrevistas, o PerfilCoursesIA
    # --- configuración: los valores de la guía de este curso
    CALLOUTS = {"⚠️", "🧠", "💡", "🩺", "💰", "📝", "📚"}          # guía §11
    SECCIONES_OBLIGATORIAS = ("🎯 El problema", "🧠 Preguntas")   # guía §6
    BANDA_PREGUNTAS = (20, 30)                                    # guía §8.2
    BANDA_LINEAS = (200, 450)                                     # guía §9
    CAMPOS_ENCABEZADO = ("Vigencia",)
    ANCHO_MAXIMO = None                                           # p. ej. 100
    AUTOCONTENIDO = True                                          # D-03 del alcance
    TAG_DE_FASE = "fase-{slug}"                                   # convención de git §3; None si no hay código

    # --- validaciones propias (ejemplos: borrar o reemplazar)

    def verificar_capitulo(self, ruta, lineas, texto, solucionario):
        """Si la banda cambia por bloque, se decide aquí antes de llamar a la base."""
        bloque = os.path.basename(os.path.dirname(ruta))
        if bloque.startswith("{{NN}}-"):               # p. ej. el bloque de talleres
            self.BANDA_PREGUNTAS = (8, 12)
        else:
            self.BANDA_PREGUNTAS = type(self).BANDA_PREGUNTAS
        super().verificar_capitulo(ruta, lineas, texto, solucionario)

    def verificar_capitulo_extra(self, ruta, lineas, texto, preguntas):
        """Ejemplo: cada capítulo cierra con pie de navegación."""
        if "⬅️" not in texto and "Anterior" not in texto:
            self.aviso("PIE", f"{self.rel(ruta)}: sin pie de navegación")

    def verificar_corpus_extra(self):
        """Ejemplo: cada ficha del prompt-base tiene su archivo (o un aviso si aún no existe)."""
        base = os.path.join(RAIZ, "prompts", "prompt-base.md")
        if not os.path.exists(base):
            return
        for codigo in re.findall(r"^## `(\d{2}/\d{2})`", open(base, encoding="utf-8").read(), re.M):
            bloque, cap = codigo.split("/")
            carpetas = [d for d in os.listdir(RAIZ) if d.startswith(bloque + "-")]
            if not carpetas or not any(f.startswith(cap + "-") for f in os.listdir(os.path.join(RAIZ, carpetas[0]))):
                self.aviso("FICHA", f"{codigo} tiene ficha y todavía no tiene archivo")


if __name__ == "__main__":
    sys.exit(main(VerificadorDelCurso, RAIZ))
