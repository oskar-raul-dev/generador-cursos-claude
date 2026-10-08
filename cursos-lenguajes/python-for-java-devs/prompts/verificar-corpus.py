#!/usr/bin/env python3
"""Verificador del curso Python para desarrolladores Java senior.

Hereda las validaciones base de `verificador_base.py` (enlaces, anclas, restos de plantilla,
codificación, callouts) con el perfil del repositorio, y agrega las de la carta (guía §14).

Uso, desde la raíz del curso:
    python3 prompts/verificar-corpus.py

Validaciones propias, solo sobre las secciones de la carta (`opNNN-<tt>NN-<slug>.md`):
  ERROR CARTA-ENCAB    el encabezado no dice «Carta», el track y si el código se ejecutó
  ERROR CARTA-EJ       menos de 8 o más de 12 ejercicios, o el título no coincide con los numerados
  ERROR CARTA-CRIT     un ejercicio numerado sin «Criterio:»
  ERROR CARTA-TAG      falta el bloque 🏷️ con `op-<tt>-fase-NN`, o el número no coincide
  ERROR CARTA-ADELANTE un enlace a una sección de la carta con número mayor que el propio
  aviso CARTA-RUBRICA  un ejercicio 🔴 sin «Rúbrica:»
  aviso CARTA-SALIDA   un bloque `text` justo después de un comando sin el rótulo de su salida
"""

import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from verificador_base import PerfilCoursesIA, main  # noqa: E402

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

CARTA_RE = re.compile(r"^op(\d{3})-([a-z]{2})(\d{2})-[a-z0-9-]+\.md$")
ENLACE_CARTA_RE = re.compile(r"\]\((?:\./)?op(\d{3})-[a-z]{2}\d{2}-[a-z0-9-]+\.md")
ROTULO = "Salida esperada, sin correr"
ROTULO_PROBADO = "Salida (Python 3.14.7"


class VerificadorDelCurso(PerfilCoursesIA):
    # Marcadores y callouts de la guía §7.
    CALLOUTS = {"💸", "🔥", "⭐", "🧱", "📏", "🏷️", "🪦", "🧨", "📌",
                "📝", "📚", "⚠️", "💡", "🧭", "⚖️", "🧠",
                "🪞", "🩻", "⚰️", "📖", "🍽️", "✅"}
    EMOJI_PERMITIDOS_H3 = PerfilCoursesIA.EMOJI_PERMITIDOS_H3 | CALLOUTS | {c.replace("️", "") for c in CALLOUTS}
    # El encabezado de las fases y de los complementos (plantilla de fase).
    CAMPOS_ENCABEZADO = ("Python para desarrolladores Java senior",)
    NO_CAPITULO = PerfilCoursesIA.NO_CAPITULO + ("historia", "convencion")

    def verificar_documento_extra(self, ruta, lineas, texto):
        nombre = os.path.basename(ruta)
        m = CARTA_RE.match(nombre)
        if not m:
            return
        numero, track, seccion = int(m.group(1)), m.group(2), m.group(3)
        crudas = texto.splitlines()
        self.verificar_encabezado_carta(nombre, crudas, track)
        self.verificar_ejercicios_carta(nombre, lineas)
        self.verificar_tag_carta(nombre, texto, track, seccion)
        for destino in ENLACE_CARTA_RE.findall(texto):
            if int(destino) > numero:
                self.error("CARTA-ADELANTE", f"{nombre}: enlaza op{destino}, posterior a op{numero:03d}")
        self.verificar_salidas(nombre, crudas)

    def verificar_encabezado_carta(self, nombre, crudas, track):
        encabezado = "\n".join(l for l in crudas[:12] if l.startswith(">"))
        for campo in ("Carta", f"Track `{track}`"):
            if campo not in encabezado:
                self.error("CARTA-ENCAB", f"{nombre}: el encabezado no dice «{campo}»")
        if "sin ejecutar" not in encabezado and "Código probado" not in encabezado:
            self.error("CARTA-ENCAB", f"{nombre}: el encabezado no dice si el código se ejecutó")

    def verificar_ejercicios_carta(self, nombre, lineas):
        declarado, numerados, dentro, rojos = None, [], False, False
        actual = None
        for _, linea in lineas:
            if linea.startswith("## "):
                if actual:
                    numerados.append(actual)
                    actual = None
                m = re.match(r"^## 🧪 6\. Ejercicios \((\d+)\)", linea)
                dentro = bool(m)
                if m:
                    declarado = int(m.group(1))
                continue
            if not dentro:
                continue
            if linea.startswith("**🔴"):
                rojos = True
            elif re.match(r"^\*\*(🟢|🟡|🟠)", linea):
                rojos = False
            if re.match(r"^\d+\. ", linea):
                if actual:
                    numerados.append(actual)
                actual = {"texto": linea, "rojo": rojos}
            elif actual is not None:
                actual["texto"] += "\n" + linea
        if actual:
            numerados.append(actual)
        if declarado is None:
            self.error("CARTA-EJ", f"{nombre}: falta «## 🧪 6. Ejercicios (N)»")
            return
        if declarado != len(numerados) or not 8 <= len(numerados) <= 12:
            self.error("CARTA-EJ", f"{nombre}: el título dice {declarado}, hay {len(numerados)} (banda 8–12)")
        for i, ej in enumerate(numerados, 1):
            if "Criterio:" not in ej["texto"]:
                self.error("CARTA-CRIT", f"{nombre}: el ejercicio {i} no tiene «Criterio:»")
            if ej["rojo"] and "Rúbrica:" not in ej["texto"]:
                self.aviso("CARTA-RUBRICA", f"{nombre}: el ejercicio {i} es 🔴 y no tiene «Rúbrica:»")

    def verificar_tag_carta(self, nombre, texto, track, seccion):
        esperado = f"op-{track}-fase-{seccion}"
        if "🏷️" not in texto or esperado not in texto:
            self.error("CARTA-TAG", f"{nombre}: falta el bloque 🏷️ con `{esperado}`")

    def verificar_salidas(self, nombre, crudas):
        # Un bloque `text` que sigue de cerca a un bloque de comandos es una salida: entre los dos
        # tiene que estar el rótulo.
        bloques, abierto = [], None
        for i, linea in enumerate(crudas):
            if not linea.startswith("```"):
                continue
            if abierto is None:
                abierto = (linea[3:].strip(), i)
            else:
                bloques.append((abierto[0], abierto[1], i))
                abierto = None
        for (lang_a, _, fin_a), (lang_b, ini_b, _) in zip(bloques, bloques[1:]):
            arbol = ini_b + 1 < len(crudas) and crudas[ini_b + 1].rstrip().endswith("/")
            if lang_a in ("bash", "console") and lang_b == "text" and ini_b - fin_a <= 4 and not arbol:
                entre = "\n".join(crudas[fin_a:ini_b])
                if ROTULO not in entre and ROTULO_PROBADO not in entre:
                    self.aviso("CARTA-SALIDA", f"{nombre}:{ini_b + 1}: salida sin el rótulo «{ROTULO}»")


if __name__ == "__main__":
    sys.exit(main(VerificadorDelCurso, RAIZ))
