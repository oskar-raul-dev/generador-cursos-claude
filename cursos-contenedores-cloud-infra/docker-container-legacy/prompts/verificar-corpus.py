#!/usr/bin/env python3
"""Verificador del curso Docker Legacy Node (guía de estilo §16.3).

Hereda las validaciones base de `verificador_base.py` (enlaces, anclas, restos de plantilla,
codificación, emoji en ###, callouts, encabezado de fase) con el perfil del repositorio, y agrega
las de este curso. Las trece comprobaciones de integridad propias (ejercicios, referencias
`FNN §x.y`, punteros a `src/`, índice contra árbol…) siguen en `check-course.sh`: este script no
las duplica.

Uso, desde la raíz del curso:
    python3 prompts/verificar-corpus.py                  # todo el curso
    python3 prompts/verificar-corpus.py --publicacion    # además, lo que exige la etapa E9

Validaciones propias de este curso, además de las base:
  aviso DIAGRAMA   un bloque `text` con forma de diagrama de flujo o de cajas; va en Mermaid (D-12)
  con --publicacion, los errores PROMPTS, ZZ-CODE y PRIVADO del perfil de publicación
"""

import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from verificador_base import PerfilCoursesIA, PerfilPublicacion, main  # noqa: E402

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

# Un diagrama de flujo o de cajas: esquinas de caja, o flechas verticales que unen pasos.
# Los árboles de archivos, las anatomías de un nombre (`└── tag`), las correspondencias `a → b` y las
# fichas de «Resultado de la fase» no llevan ninguna de las dos, y se quedan en `text` (guía §16.1).
DIAGRAMA_RE = re.compile(r"[┌┐┘▼↓]")


class VerificadorDelCurso(PerfilCoursesIA):
    # Marcadores (guía §7.2) y callouts (guía §7.3).
    CALLOUTS = {"💸", "🔥", "💀", "⭐", "🚧",
                "📝", "📚", "⚠️", "💡", "🧠", "🩺", "🪦", "🧭", "🚨", "🦭", "⚰️"}
    # Seis callouts de un solo uso, heredados del curso ya publicado: se toleran y no se multiplican
    # (guía §16.2).
    CALLOUTS_HEREDADOS = {"🥇", "⚔️", "🛑", "🥊", "🗓️", "🧾"}
    CALLOUTS = CALLOUTS | CALLOUTS_HEREDADOS
    # Emoji en ### con moderación (guía §3 y §16.2): la escala de dificultad, los marcadores y los
    # títulos de ruta y de bloque que ya existen. El verificador compara carácter por carácter, así que
    # van también sin el U+FE0F.
    EMOJI_H3 = {"🎓", "🧭", "🐧", "🍎", "🕵️", "🧬", "🧟", "🧠", "🐳", "⌨️", "🩺", "📝", "🚩"}
    EMOJI_PERMITIDOS_H3 = (PerfilCoursesIA.EMOJI_PERMITIDOS_H3 | CALLOUTS | EMOJI_H3
                           | {c.replace("️", "") for c in CALLOUTS | EMOJI_H3})
    # El encabezado de fase (guía §7.1): «Curso» y «Objetivo» no faltan nunca. La fecha va solo donde
    # hubo verificación ejecutada o revisión de documentación externa (guía §16.2).
    CAMPOS_ENCABEZADO = ("**Curso:**", "**Objetivo")
    # 00-PARTE-I-taller.md y 00-PARTE-II-laboratorio.md llevan número pero son entradas de Parte.
    NO_CAPITULO = PerfilCoursesIA.NO_CAPITULO + ("parte",)

    def verificar_documento_extra(self, ruta, lineas, texto):
        # `lineas` llega sin los bloques de código: los diagramas se buscan en el texto crudo.
        bloque, inicio = None, 0
        for n, linea in enumerate(texto.splitlines(), 1):
            if bloque is None and linea.strip() == "```text":
                bloque, inicio = [], n
            elif bloque is not None and linea.strip() == "```":
                if sum(1 for l in bloque if DIAGRAMA_RE.search(l)) >= 2:
                    self.aviso("DIAGRAMA", f"{self.rel(ruta)}:{inicio}: bloque text con forma de diagrama;"
                                           " va en Mermaid (D-12)")
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
