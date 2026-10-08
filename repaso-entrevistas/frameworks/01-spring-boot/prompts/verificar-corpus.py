#!/usr/bin/env python3
"""Verificador del curso 01-spring-boot (guía §12 y §13).

Subclase de `verificador_base.py` (copiado de las plantillas generales el 2026-10-05): las
validaciones base —enlaces, anclas, restos de plantilla, emoji en ###, sincronía con el solucionario,
bandas, callouts— vienen de allí; aquí van los valores de la guía de este curso y sus validaciones
propias. Sustituye a los antiguos `verificar-anclas.py` y `verificar-preguntas.py`.

Uso, desde la raíz del curso (`frameworks/01-spring-boot/`):
    python3 -B prompts/verificar-corpus.py

El curso es plano (no tiene carpetas de bloque), así que no admite un bloque como argumento.

Lo que cambia respecto de la base:
  - Son documentos con preguntas los capítulos `01`–`25`, los labs `l00`–`l09` y los apéndices
    `a01`–`a04`; el solucionario `26-respuestas.md` los cubre a todos con entradas `### NN → n`,
    `### L01 → n` o `### A01 → n` y el enunciado en blockquote (guía §8.1).
  - Los enlaces cuyo texto cruza un salto de línea también se revisan (la base exige el `[` en la
    misma línea que el `](…)`, y en `26` hay más de cien así).

Validaciones propias, además de las base:
  ERROR VERSION     URL de docs.spring.io de Boot o Framework sin la versión en la ruta, fuera de A04 (guía §10.2)
  ERROR EJERCICIOS  el «## 🧪 Ejercicios (N)» no coincide con los ejercicios 🟢🟡🟠🔴 numerados (guía §8.2)
  aviso EJERCICIOS  lab o apéndice fuera de su banda de ejercicios (12–20 y 8–12), o sin la sección
  aviso ENCAB       documento sin «Vigencia» en el blockquote de sus primeras 40 líneas (guía §6)
  aviso CAPAS       entrada del solucionario sin «⏱️ 30 segundos» o sin «🗣️ 2 minutos» (guía §8.1)
"""

import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from verificador_base import PerfilRepasoEntrevistas, leer, lineas_sin_codigo, main, normalizar  # noqa: E402

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SOLUCIONARIO = "26-respuestas.md"
URL_SIN_VERSION_RE = re.compile(
    r"https://docs\.spring\.io/(spring-boot/(?!\d)|spring-framework/reference/(?!\d))\S*")
MULTILINEA_RE = re.compile(r"\]\(([^)\s]+)\)")


def clave(ruta):
    """`16-…` → «16»; `l04-…` → «L04»; `a02-…` → «A02», como en las entradas del solucionario."""
    nombre = os.path.basename(ruta)
    return nombre[:3].upper() if nombre[0] in "la" else nombre[:2]


class VerificadorSpringBoot(PerfilRepasoEntrevistas):
    # --- configuración: los valores de la guía de este curso
    CALLOUTS = {"⚠️", "🧠", "💡", "🩺", "⏱️", "📝", "📚"}                 # guía §9.3: ⏱️ en vez de 💰
    CAPITULO_RE = re.compile(r"^(\d{2}|[la]\d{2})-.*\.md$")
    NO_CAPITULO = ("respuestas", "readme")                                # 25 sí tiene preguntas
    CAMPOS_ENCABEZADO = ()          # «Vigencia» se busca abajo: el contrato de los labs es largo
    LINEAS_ENCABEZADO = 40                                                # guía §6 y §10.4
    SECCION_PREGUNTAS = "🧠 Preguntas rápidas"
    ORDEN_DIFICULTAD = False                                              # guía §8.1: orden libre
    CAPAS = ("⏱️ 30 segundos", "🗣️ 2 minutos")                            # 🔬 puede omitirse
    BANDA_TEORIA = (200, 380)                                             # guía §4.6
    EXCEPCIONES_LARGO = {"01": 450, "20": 450}                            # declaradas en §4.6
    BANDA_PREG_CAPITULO = (10, 15)                                        # guía §8.1
    BANDA_PREG_APENDICE = (6, 12)
    BANDA_EJ_LAB = (12, 20)                                               # guía §8.2
    BANDA_EJ_APENDICE = (8, 12)
    SIN_EJERCICIOS = ("L00",)                                             # exención de §8.2
    SIN_URL_VERSIONADA = ("A04",)                                         # excepción de §10.2

    # --- enlaces: también los que cruzan un salto de línea
    def verificar_enlaces(self, ruta, lineas):
        super().verificar_enlaces(ruta, lineas)
        sueltos = []
        for n, linea in lineas:
            for m in MULTILINEA_RE.finditer(linea):
                if "[" not in linea[:m.start()]:
                    sueltos.append((n, f"[…]({m.group(1)})"))
        if sueltos:
            super().verificar_enlaces(ruta, sueltos)

    # --- documentos con preguntas
    def verificar_capitulo(self, ruta, lineas, texto, solucionario):
        k = clave(ruta)
        teoria = k.isdigit() and int(k) <= 24
        if teoria:
            self.BANDA_LINEAS = (self.BANDA_TEORIA[0], self.EXCEPCIONES_LARGO.get(k, self.BANDA_TEORIA[1]))
        else:
            self.BANDA_LINEAS = None                                      # labs, apéndices y 25
        if k == "25":
            self.BANDA_PREGUNTAS = None                                   # sesenta P#, a propósito
        elif k.startswith("A"):
            self.BANDA_PREGUNTAS = self.BANDA_PREG_APENDICE
        else:
            self.BANDA_PREGUNTAS = self.BANDA_PREG_CAPITULO
        self.SECCIONES_OBLIGATORIAS = (self.SECCION_PREGUNTAS, "📚 Referencias oficiales")
        super().verificar_capitulo(ruta, lineas, texto, solucionario)

    def verificar_capitulo_extra(self, ruta, lineas, texto, preguntas):
        k = clave(ruta)
        if not any(l.startswith(">") and "Vigencia" in l for _, l in lineas[:self.LINEAS_ENCABEZADO]):
            self.aviso("ENCAB", f"{self.rel(ruta)}: el encabezado no dice «Vigencia»")
        if k[0] in "LA" and k not in self.SIN_EJERCICIOS:
            self.verificar_ejercicios(ruta, lineas, k)

    def verificar_ejercicios(self, ruta, lineas, k):
        nombre = self.rel(ruta)
        titulo = next((l for _, l in lineas if l.startswith("## 🧪 Ejercicios")), None)
        if titulo is None:
            self.aviso("EJERCICIOS", f"{nombre}: sin «## 🧪 Ejercicios (N)»")
            return
        declarados = re.search(r"\((\d+)\)", titulo)
        numerados = sum(1 for _, l in lineas if re.match(r"^#### [🟢🟡🟠🔴] Ejercicio \d+", l))
        if not declarados or int(declarados.group(1)) != numerados:
            dice = declarados.group(1) if declarados else "sin número"
            self.error("EJERCICIOS", f"{nombre}: el título dice ({dice}) y hay {numerados} numerados")
        banda = self.BANDA_EJ_LAB if k.startswith("L") else self.BANDA_EJ_APENDICE
        if not banda[0] <= numerados <= banda[1]:
            self.aviso("EJERCICIOS", f"{nombre}: {numerados} ejercicios (banda {banda[0]}–{banda[1]})")

    # --- solucionario: «### NN → n» con el enunciado en blockquote
    def leer_solucionario(self, carpeta):
        ruta = os.path.join(carpeta, SOLUCIONARIO)
        if not os.path.exists(ruta):
            return None
        texto = leer(ruta)
        entradas, lineas = {}, [l for _, l in lineas_sin_codigo(texto)]
        for i, linea in enumerate(lineas):
            m = re.match(r"^### (\S+) → (\d+)$", linea)
            if not m:
                continue
            j, cita = i + 1, []
            while j < len(lineas) and not lineas[j].strip():
                j += 1
            while j < len(lineas) and lineas[j].startswith(">"):
                cita.append(lineas[j][1:].strip())
                j += 1
            entradas.setdefault(m.group(1), {})[int(m.group(2))] = normalizar(" ".join(cita))
        for bloque in re.split(r"\n(?=### )", texto):
            if re.match(r"### \S+ → \d+\n", bloque) and not all(c in bloque for c in self.CAPAS):
                self.aviso("CAPAS", f"{SOLUCIONARIO}: {bloque.split(chr(10))[0][4:]}")
        return {"ruta": ruta, "entradas": entradas}

    def verificar_sincronia(self, ruta, preg, solucionario):
        """La de la base, con la clave del documento (`L04`, `A02`) en vez de sus dos primeros caracteres."""
        if not preg or solucionario is None:
            return super().verificar_sincronia(ruta, preg, solucionario)
        nombre, k = self.rel(ruta), clave(ruta)
        resp = solucionario["entradas"].get(k, {})
        if len(resp) != len(preg):
            self.error("SINCRO", f"{nombre}: {len(preg)} preguntas, {len(resp)} en el solucionario")
        for n in sorted(set(preg) - set(resp)):
            self.error("FALTA", f"{nombre}: la pregunta {n} no está en el solucionario")
        for n in sorted(set(resp) - set(preg)):
            self.error("SOBRA", f"{SOLUCIONARIO}: {k} → {n}")
        for n in sorted(set(preg) & set(resp)):
            if preg[n][0] != resp[n]:
                self.error("LITERAL", f"{nombre} → {n}: el solucionario dice «{resp[n][:70]}»"
                                      f" y el documento «{preg[n][0][:70]}»")

    # --- cualquier documento publicado
    def verificar_documento_extra(self, ruta, lineas, texto):
        nombre = os.path.basename(ruta)
        if nombre[:3].upper() in self.SIN_URL_VERSIONADA:
            return
        for n, linea in lineas:
            for m in URL_SIN_VERSION_RE.finditer(linea):
                self.error("VERSION", f"{self.rel(ruta)}:{n} → {m.group(0)[:90]}")


if __name__ == "__main__":
    sys.exit(main(VerificadorSpringBoot, RAIZ))
