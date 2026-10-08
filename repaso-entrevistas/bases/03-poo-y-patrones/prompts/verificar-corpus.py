#!/usr/bin/env python3
"""Verificador del corpus 03-poo-y-patrones (§11.4 de la guía).

Subclase de `verificador_base.py` (copiado de las plantillas generales el 2026-10-07): las
validaciones base —enlaces y anclas (con el U+FE0F que GitHub conserva y los enlaces cuyo texto cruza
un salto de línea), enlaces que salen del corpus, restos de plantilla, emoji en ###, callouts,
sincronía y literalidad con el solucionario, tres capas— vienen de allí; aquí van los valores de la
guía de este corpus y sus validaciones propias.

Uso, desde la raíz del corpus:
    python3 -B prompts/verificar-corpus.py                    # todo el corpus
    python3 -B prompts/verificar-corpus.py 04-creacionales    # solo un bloque
    python3 -B prompts/verificar-corpus.py --corregir-fe0f    # reescribe las anclas ANCLA-FE0F

Lo que cambia respecto de la base:
  - Ningún enlace relativo sale del corpus (§1.2): FUERA es error.
  - Callouts de §9.3: 🏷️ (precio) en vez de 💰.
  - Las bandas dependen del bloque (§4.6 y §13.2): preguntas 20–30 en los bloques 01–03, 12–20 en
    los demás y 8–12 en los talleres (bloque 14); líneas 200–450, o 300–650 en los talleres.

Validaciones propias, además de las base:
  ERROR SINCRO   taller con distinto número de ejercicios **E#.** que entradas **NN → E#.** (§13.2)
  ERROR RUTA     ruta del README con un capítulo que no existe, o con uno cuyo «asume leído» queda
                 fuera de la ruta (§12; la ruta «entrevista esta semana» está exenta)
  aviso BANDA    capítulo fuera de su banda de preguntas, o taller fuera de 3–5 ejercicios
  aviso LARGO    capítulo fuera de su banda de líneas
"""

import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from verificador_base import PerfilRepasoEntrevistas, leer, main  # noqa: E402

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
BLOQUE_TALLERES = 14                                                  # §13.2: el bloque opcional


class VerificadorPooYPatrones(PerfilRepasoEntrevistas):
    # --- configuración: los valores de la guía de este corpus
    AUTOCONTENIDO = True                                              # §1.2
    CALLOUTS = {"⚠️", "🧠", "💡", "🩺", "🏷️", "📝", "📚"}             # §9.3
    CAMPOS_ENCABEZADO = ("Vigencia",)                                 # §3, punto 2

    def bandas(self, ruta):
        """(banda de preguntas, banda de líneas) del capítulo, según su bloque."""
        bloque = int(os.path.basename(os.path.dirname(ruta))[:2])
        if bloque == BLOQUE_TALLERES:
            return (8, 12), (300, 650)
        return ((20, 30) if bloque <= 3 else (12, 20)), (200, 450)

    # --- capítulos
    def verificar_capitulo_extra(self, ruta, lineas, texto, preguntas):
        nombre = self.rel(ruta)
        banda_p, banda_l = self.bandas(ruta)
        if not banda_p[0] <= len(preguntas) <= banda_p[1]:
            self.aviso("BANDA", f"{nombre}: {len(preguntas)} preguntas (banda {banda_p[0]}–{banda_p[1]})")
        total = texto.count("\n")
        if not banda_l[0] <= total <= banda_l[1]:
            self.aviso("LARGO", f"{nombre}: {total} líneas (banda {banda_l[0]}–{banda_l[1]})")
        if int(os.path.basename(os.path.dirname(ruta))[:2]) == BLOQUE_TALLERES:
            self.verificar_ejercicios(ruta, lineas)

    def verificar_ejercicios(self, ruta, lineas):
        """Los ejercicios de un taller: párrafos que empiezan con **E#.** bajo «## … Ejercicios»."""
        dentro, n = False, 0
        for _, linea in lineas:
            if linea.startswith("## "):
                dentro = "Ejercicios" in linea
            elif dentro and re.match(r"^\*\*E\d+\.\*\* ", linea):
                n += 1
        nombre = self.rel(ruta)
        if not 3 <= n <= 5:
            self.aviso("BANDA", f"{nombre}: {n} ejercicios (banda 3–5)")
        carpeta = os.path.dirname(ruta)
        solucionarios = [f for f in sorted(os.listdir(carpeta)) if self.SOLUCIONARIO_RE.search(f)]
        if solucionarios:
            nn = os.path.basename(ruta)[:2]
            texto = leer(os.path.join(carpeta, solucionarios[0]))
            entradas = len(re.findall(rf"^\*\*{nn} → E\d+\.", texto, re.M))
            if entradas != n:
                self.error("SINCRO", f"{nombre}: {n} ejercicios, {entradas} en el solucionario")

    # --- rutas de estudio del README (§12)
    def codigo_de(self, ruta):
        bloque, nombre = os.path.basename(os.path.dirname(ruta)), os.path.basename(ruta)
        if self.BLOQUE_RE.match(bloque) and self.CAPITULO_RE.match(nombre):
            return f"{bloque[:2]}/{nombre[:2]}"
        return None

    def asume_leido(self, ruta):
        """Códigos NN/MM enlazados desde el blockquote de encabezado."""
        codigos = set()
        for linea in leer(ruta).split("\n")[1:]:
            if linea.startswith("##") or linea.strip() == "---":
                break
            if linea.startswith(">"):
                for destino in re.findall(r"\]\(([^)#\s]+)", linea):
                    codigo = self.codigo_de(os.path.normpath(os.path.join(os.path.dirname(ruta), destino)))
                    if codigo:
                        codigos.add(codigo)
        return codigos

    def verificar_corpus_extra(self):
        readme = os.path.join(self.raiz, "README.md")
        if not os.path.exists(readme):
            return
        tabla = {}
        for ruta in self.archivos():
            codigo = self.codigo_de(ruta)
            if codigo:
                tabla[codigo] = ruta
        rutas, actual = {}, None
        for linea in leer(readme).split("\n"):
            if linea.startswith("#"):
                actual = linea.lstrip("#").strip() if linea.startswith("### Ruta") else None
                if actual:
                    rutas[actual] = []
            elif actual:
                rutas[actual] += re.findall(r"\b(\d{2}/\d{2})\b", linea)
        for nombre, codigos in rutas.items():
            for codigo in codigos:
                if codigo not in tabla:
                    self.error("RUTA", f"«{nombre}»: {codigo} no existe")
                elif "esta semana" not in nombre:
                    for previo in sorted(self.asume_leido(tabla[codigo]) - set(codigos)):
                        self.error("RUTA", f"«{nombre}»: {codigo} asume leído {previo}, que no está en la ruta")


if __name__ == "__main__":
    sys.exit(main(VerificadorPooYPatrones, RAIZ))
