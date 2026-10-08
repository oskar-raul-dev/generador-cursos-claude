#!/usr/bin/env python3
"""Verificador del curso Laboratorio de contenedores y Kubernetes local (guía de estilo §19.3).

Hereda las validaciones base de `verificador_base.py` (enlaces, anclas, restos de plantilla,
codificación, emoji en ###, callouts, encabezado de fase) con el perfil del repositorio, y agrega
las de este curso.

Uso, desde la raíz del curso:
    python3 prompts/verificar-corpus.py                  # todo el curso
    python3 prompts/verificar-corpus.py --publicacion    # además, lo que exige la etapa E9

Validaciones propias de este curso, además de las base:
  aviso DIAGRAMA   un bloque `text` con forma de diagrama de flujo o de cajas; va en Mermaid (D44)
  con --publicacion, los errores PROMPTS, ZZ-CODE y PRIVADO del perfil de publicación
"""

import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from verificador_base import PerfilCoursesIA, PerfilPublicacion, main  # noqa: E402

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

# Un diagrama de flujo o de cajas: esquinas de caja, o flechas verticales que unen pasos.
# Los árboles de archivos, las salidas de terminal y las correspondencias `a → b` no llevan ninguna
# de las dos, y se quedan en `text` (guía §19.1).
DIAGRAMA_RE = re.compile(r"[┌┐┘▼▲↓↑]")
# Lo que se queda en `text` aunque dibuje: las fichas de cierre de fase («… AL CERRAR LA FASE NN») y
# las capturas de pantalla de una terminal, como la de k9s en a04.
NO_ES_DIAGRAMA_RE = re.compile(r"\bAL CERRAR\b|^ Context: ")


class _Todos:
    """Un conjunto que lo contiene todo: la historia no tiene límite de emoji en ###."""
    def __contains__(self, _):
        return True


class VerificadorDelCurso(PerfilCoursesIA):
    # Marcadores (guía §8.2) y callouts (guía §8.3).
    CALLOUTS = PerfilCoursesIA.CALLOUTS | {"⭐", "🌊", "📏", "🌩️"}
    # Emoji en ### (guía §17, excepción 8): los marcadores de estado y el 🩺 de cada incidente, y el
    # 🏚️ del patrimonio. El verificador compara carácter por carácter, así que van también sin U+FE0F.
    EMOJI_H3 = {"🩺", "🦭", "🌊", "🏚️", "🚧", "🌩️", "💸"}
    EMOJI_PERMITIDOS_H3 = (PerfilCoursesIA.EMOJI_PERMITIDOS_H3 | EMOJI_H3
                           | {c.replace("️", "") for c in EMOJI_H3})
    # La historia de la empresa es narrativa, no una fase: no lleva fecha de verificación y su
    # cronología usa un emoji por año en ### (guía §17, excepción 8).
    NO_CAPITULO = PerfilCoursesIA.NO_CAPITULO + ("historia",)
    DOCUMENTOS_SIN_LIMITE_DE_EMOJI = ("00-historia-de-la-vecina.md",)

    def verificar_texto(self, ruta, lineas):
        if os.path.basename(ruta) not in self.DOCUMENTOS_SIN_LIMITE_DE_EMOJI:
            return super().verificar_texto(ruta, lineas)
        permitidos, self.EMOJI_PERMITIDOS_H3 = self.EMOJI_PERMITIDOS_H3, _Todos()
        try:
            return super().verificar_texto(ruta, lineas)
        finally:
            self.EMOJI_PERMITIDOS_H3 = permitidos

    def verificar_documento_extra(self, ruta, lineas, texto):
        # `lineas` llega sin los bloques de código: los diagramas se buscan en el texto crudo.
        if self.es_de_prompts(ruta):
            return
        bloque, inicio = None, 0
        for n, linea in enumerate(texto.splitlines(), 1):
            if bloque is None and linea.strip() == "```text":
                bloque, inicio = [], n
            elif bloque is not None and linea.strip() == "```":
                if (sum(1 for l in bloque if DIAGRAMA_RE.search(l)) >= 2
                        and not (bloque and NO_ES_DIAGRAMA_RE.search(bloque[0]))):
                    self.aviso("DIAGRAMA", f"{self.rel(ruta)}:{inicio}: bloque text con forma de diagrama;"
                                           " va en Mermaid (D44)")
                bloque = None
            elif bloque is not None:
                bloque.append(linea)


class VerificadorDePublicacion(VerificadorDelCurso):
    """Etapa E9: lo del curso, más lo que el repositorio público exige (sin `prompts/`)."""
    PROHIBIR_ENLACES_A_PROMPTS = True
    PROHIBIDOS_EN_PUBLICADOS = PerfilPublicacion.PROHIBIDOS_EN_PUBLICADOS


if __name__ == "__main__":
    clase = VerificadorDelCurso
    if "--publicacion" in sys.argv:
        sys.argv.remove("--publicacion")
        clase = VerificadorDePublicacion
    sys.exit(main(clase, RAIZ))
