#!/usr/bin/env python3
"""Verificador base de un curso en Markdown.

Es la base común de los `prompts/verificar-corpus.py` de cada curso: trae las validaciones que todo
curso necesita, configurables por atributos de clase, y deja ganchos para que cada curso agregue las
suyas. Solo biblioteca estándar.

Uso directo (validaciones base, con la configuración por defecto o la de un repositorio):
    python3 verificador_base.py <carpeta-del-curso> [bloque] [--perfil=base|repaso|courses-ia|publicacion]
    python3 verificador_base.py <carpeta-del-curso> --corregir-fe0f   # reescribe las ANCLA-FE0F

Uso en un curso: se copian este archivo y `verificar-corpus.py` a `prompts/`, y se ajusta la
subclase de `verificar-corpus.py` (ver ese archivo).

Errores (salida con código 1):
  ROTO      enlace interno a un archivo que no existe
  ANCLA     enlace a un ancla que no existe en el destino
  ANCLA-FE0F el ancla de un encabezado con ⚠️, ⚖️, ⚙️… escrita sin el U+FE0F que GitHub conserva
  FUERA     enlace relativo que sale del curso (si AUTOCONTENIDO)
  PROMPTS   documento publicado que enlaza prompts/ o un _desechable-* (PROHIBIR_ENLACES_A_PROMPTS)
  ZZ-CODE   documento publicado que cita zz-code/, el código intermedio que no viaja con el curso
  PRIVADO   documento publicado que cita material privado (solo en --perfil=publicacion)
  RESTO     resto de plantilla fuera de código: {{...}} o una nota «✏️ **Plantilla:**»
  MOJIBAKE  codificación rota tras una sustitución (Ã, â€) fuera de código
  EMOJI     emoji en un encabezado ###, salvo la escala de dificultad (EMOJI_PERMITIDOS_H3)
  SECCION   capítulo sin una sección obligatoria (SECCIONES_OBLIGATORIAS)
  SINCRO    capítulo con distinto número de preguntas que su solucionario
  LITERAL   enunciado del solucionario que no es copia literal del capítulo (si LITERAL_ES_ERROR)
  FALTA     pregunta del capítulo sin entrada en el solucionario
  SOBRA     entrada del solucionario sin pregunta en el capítulo

Avisos (a revisar a mano):
  LARGO     capítulo fuera de la banda de líneas (BANDA_LINEAS)
  BANDA     capítulo fuera de la banda de preguntas (BANDA_PREGUNTAS)
  ORDEN     preguntas que no van de menor a mayor dificultad
  CALLOUT   callout con un emoji fuera de CALLOUTS
  ENCAB     encabezado sin un campo obligatorio (CAMPOS_ENCABEZADO)
  ANCHO     línea de prosa más larga que ANCHO_MAXIMO (si se fija)
  SIN-SOL   bloque o capítulo sin solucionario
  PENDIENTE solucionario con la palabra "pendiente"
  CAPAS     respuesta sin sus capas (CAPAS)
"""

import bisect
import fnmatch
import os
import re
import sys
import unicodedata

FENCE_RE = re.compile(r"^\s*(`{3,}|~{3,})")
LINK_RE = re.compile(r"(?<!!)\[[^\]]*\]\(([^)\s]+)(?:\s+\"[^\"]*\")?\)")
MARCA_PLANTILLA_RE = re.compile(r"✏️\s*\*\*Plantilla")   # la nota de plantilla; ✏️ suelto es contenido
PLACEHOLDER_RE = re.compile(r"\{\{(?![\s.$]|json\b|range\b|if\b|end\b|with\b)")   # no plantillas de Go
HEADING_RE = re.compile(r"^(#{1,6})\s+(.+?)\s*#*\s*$")
INLINE_RE = re.compile(r"(`+)(.+?)\1")
DIFICULTAD = {"🟢": 0, "🟡": 1, "🟠": 2, "🔴": 3}


# ---------------------------------------------------------------------------- utilidades


def leer(ruta):
    with open(ruta, encoding="utf-8") as f:
        return f.read()


def lineas_sin_codigo(texto):
    """[(número de línea, línea)] fuera de los bloques de código cercados."""
    salida, abierto = [], None
    for n, linea in enumerate(texto.split("\n"), 1):
        m = FENCE_RE.match(linea)
        if m:
            marca = m.group(1)
            if abierto is None:
                abierto = marca
                continue
            if marca[0] == abierto[0] and len(marca) >= len(abierto) and linea.strip() == marca:
                abierto = None
                continue
        if abierto is None:
            salida.append((n, linea))
    return salida


def sin_inline(linea):
    return INLINE_RE.sub("", linea)


def lineas_sin_inline(lineas):
    """Como `lineas_sin_codigo`, pero además borra el código en línea aunque cruce un salto de línea
    dentro del mismo párrafo (GitHub lo pinta igual)."""
    numeros = [n for n, _ in lineas]
    texto = "\n".join(l for _, l in lineas)
    texto = re.sub(r"(`+)((?:(?!\n\s*\n).)+?)\1",
                   lambda m: re.sub(r"[^\n]", " ", m.group(0)), texto, flags=re.S)
    return list(zip(numeros, texto.split("\n")))


# Caracteres que GitHub borra al calcular un ancla: generado el 2026-10-04 desde github-slugger 2.0.0
# (regex.js), la librería que replica el algoritmo de GitHub. Rangos de code points en hexadecimal.
_SLUG_QUITAR = (
    "0-1f,21-2c,2e-2f,3a-40,5b-5e,60,7b-a9,ab-b4,b6-b9,bb-bf,d7,f7,2c2-2c5,2d2-2df,2e5-2eb,2ed,2ef-"
    "2ff,375,378-379,37e,380-385,387,38b,38d,3a2,3f6,482,530,557-558,55a-55f,589-"
    "590,5be,5c0,5c3,5c6,5c8-5cf,5eb-5ee,5f3-60f,61b-61f,66a-66d,6d4,6dd-6de,6e9,6fd-6fe,700-70f,74b-"
    "74c,7b2-7bf,7f6-7f9,7fb-7fc,7fe-7ff,82e-83f,85c-85f,86b-89f,8b5,8c8-8d2,8e2,964-965,970,984,98d-"
    "98e,991-992,9a9,9b1,9b3-9b5,9ba-9bb,9c5-9c6,9c9-9ca,9cf-9d6,9d8-9db,9de,9e4-9e5,9f2-9fb,9fd,9ff-"
    "a00,a04,a0b-a0e,a11-a12,a29,a31,a34,a37,a3a-a3b,a3d,a43-a46,a49-a4a,a4e-a50,a52-a58,a5d,a5f-"
    "a65,a76-a80,a84,a8e,a92,aa9,ab1,ab4,aba-abb,ac6,aca,ace-acf,ad1-adf,ae4-ae5,af0-af8,b00,b04,b0d-"
    "b0e,b11-b12,b29,b31,b34,b3a-b3b,b45-b46,b49-b4a,b4e-b54,b58-b5b,b5e,b64-b65,b70,b72-b81,b84,b8b-"
    "b8d,b91,b96-b98,b9b,b9d,ba0-ba2,ba5-ba7,bab-bad,bba-bbd,bc3-bc5,bc9,bce-bcf,bd1-bd6,bd8-be5,bf0-"
    "bff,c0d,c11,c29,c3a-c3c,c45,c49,c4e-c54,c57,c5b-c5f,c64-c65,c70-c7f,c84,c8d,c91,ca9,cb4,cba-"
    "cbb,cc5,cc9,cce-cd4,cd7-cdd,cdf,ce4-ce5,cf0,cf3-cff,d0d,d11,d45,d49,d4f-d53,d58-d5e,d64-d65,d70-"
    "d79,d80,d84,d97-d99,db2,dbc,dbe-dbf,dc7-dc9,dcb-"
    "dce,dd5,dd7,de0-de5,df0-df1,df4-e00,e3b-e3f,e4f,e5a-e80,e83,e85,e8b,ea4,ea6,ebe-ebf,ec5,ec7,ece-"
    "ecf,eda-edb,ee0-eff,f01-f17,f1a-f1f,f2a-f34,f36,f38,f3a-f3d,f48,f6d-f70,f85,f98,fbd-fc5,fc7-"
    "fff,104a-104f,109e-109f,10c6,10c8-10cc,10ce-10cf,10fb,1249,124e-124f,1257,1259,125e-"
    "125f,1289,128e-128f,12b1,12b6-12b7,12bf,12c1,12c6-12c7,12d7,1311,1316-1317,135b-135c,1360-"
    "137f,1390-139f,13f6-13f7,13fe-1400,166d-166e,1680,169b-169f,16eb-16ed,16f9-16ff,170d,1715-"
    "171f,1735-173f,1754-175f,176d,1771,1774-177f,17d4-17d6,17d8-17db,17de-17df,17ea-180a,180e-"
    "180f,181a-181f,1879-187f,18ab-18af,18f6-18ff,191f,192c-192f,193c-1945,196e-196f,1975-197f,19ac-"
    "19af,19ca-19cf,19da-19ff,1a1c-1a1f,1a5f,1a7d-1a7e,1a8a-1a8f,1a9a-1aa6,1aa8-1aaf,1ac1-1aff,1b4c-"
    "1b4f,1b5a-1b6a,1b74-1b7f,1bf4-1bff,1c38-1c3f,1c4a-1c4c,1c7e-1c7f,1c89-1c8f,1cbb-1cbc,1cc0-"
    "1ccf,1cd3,1cfb-1cff,1dfa,1f16-1f17,1f1e-1f1f,1f46-1f47,1f4e-1f4f,1f58,1f5a,1f5c,1f5e,1f7e-"
    "1f7f,1fb5,1fbd,1fbf-1fc1,1fc5,1fcd-1fcf,1fd4-1fd5,1fdc-1fdf,1fed-1ff1,1ff5,1ffd-203e,2041-"
    "2053,2055-2070,2072-207e,2080-208f,209d-20cf,20f1-2101,2103-2106,2108-2109,2114,2116-2118,211e-"
    "2123,2125,2127,2129,212e,213a-213b,2140-2144,214a-214d,214f-215f,2189-24b5,24ea-"
    "2bff,2c2f,2c5f,2ce5-2cea,2cf4-2cff,2d26,2d28-2d2c,2d2e-2d2f,2d68-2d6e,2d70-2d7e,2d97-"
    "2d9f,2da7,2daf,2db7,2dbf,2dc7,2dcf,2dd7,2ddf,2e00-2e2e,2e30-3004,3008-3020,3030,3036-3037,303d-"
    "3040,3097-3098,309b-309c,30a0,30fb,3100-3104,3130,318f-319f,31c0-31ef,3200-33ff,4dc0-4dff,9ffd-"
    "9fff,a48d-a4cf,a4fe-a4ff,a60d-a60f,a62c-a63f,a673,a67e,a6f2-a716,a720-a721,a789-a78a,a7c0-"
    "a7c1,a7cb-a7f4,a828-a82b,a82d-a83f,a874-a87f,a8c6-a8cf,a8da-a8df,a8f8-a8fa,a8fc,a92e-a92f,a954-"
    "a95f,a97d-a97f,a9c1-a9ce,a9da-a9df,a9ff,aa37-aa3f,aa4e-aa4f,aa5a-aa5f,aa77-aa79,aac3-aada,aade-"
    "aadf,aaf0-aaf1,aaf7-ab00,ab07-ab08,ab0f-ab10,ab17-ab1f,ab27,ab2f,ab5b,ab6a-ab6f,abeb,abee-"
    "abef,abfa-abff,d7a4-d7af,d7c7-d7ca,d7fc-d7ff,e000-f8ff,fa6e-fa6f,fada-faff,fb07-fb12,fb18-"
    "fb1c,fb29,fb37,fb3d,fb3f,fb42,fb45,fbb2-fbd2,fd3e-fd4f,fd90-fd91,fdc8-fdef,fdfc-"
    "fdff,fe10-fe1f,fe30-fe32,fe35-fe4c,fe50-fe6f,fe75,fefd-"
    "ff0f,ff1a-ff20,ff3b-ff3e,ff40,ff5b-ff65,ffbf-ffc1,ffc8-ffc9,ffd0-ffd1,ffd8-ffd9,ffdd-ffff,1000c,"
    "10027,1003b,1003e,1004e-1004f,1005e-1007f,100fb-1013f,10175-101fc,101fe-1027f,1029d-1029f,102d1-"
    "102df,102e1-102ff,10320-1032c,1034b-1034f,1037b-1037f,1039e-1039f,103c4-103c7,103d0,103d6-"
    "103ff,1049e-1049f,104aa-104af,104d4-104d7,104fc-104ff,10528-1052f,10564-105ff,10737-1073f,10756-"
    "1075f,10768-107ff,10806-10807,10809,10836,10839-1083b,1083d-1083e,10856-1085f,10877-1087f,1089f-"
    "108df,108f3,108f6-108ff,10916-1091f,1093a-1097f,109b8-109bd,109c0-109ff,10a04,10a07-"
    "10a0b,10a14,10a18,10a36-10a37,10a3b-10a3e,10a40-10a5f,10a7d-10a7f,10a9d-10abf,10ac8,10ae7-"
    "10aff,10b36-10b3f,10b56-10b5f,10b73-10b7f,10b92-10bff,10c49-10c7f,10cb3-10cbf,10cf3-10cff,10d28-"
    "10d2f,10d3a-10e7f,10eaa,10ead-10eaf,10eb2-10eff,10f1d-10f26,10f28-10f2f,10f51-10faf,10fc5-"
    "10fdf,10ff7-10fff,11047-11065,11070-1107e,110bb-110cf,110e9-110ef,110fa-110ff,11135,11140-"
    "11143,11148-1114f,11174-11175,11177-1117f,111c5-111c8,111cd,111db,111dd-111ff,11212,11238-"
    "1123d,1123f-1127f,11287,11289,1128e,1129e,112a9-112af,112eb-112ef,112fa-112ff,11304,1130d-"
    "1130e,11311-11312,11329,11331,11334,1133a,11345-11346,11349-1134a,1134e-1134f,11351-11356,11358-"
    "1135c,11364-11365,1136d-1136f,11375-113ff,1144b-1144f,1145a-1145d,11462-1147f,114c6,114c8-"
    "114cf,114da-1157f,115b6-115b7,115c1-115d7,115de-115ff,11641-11643,11645-1164f,1165a-1167f,116b9-"
    "116bf,116ca-116ff,1171b-1171c,1172c-1172f,1173a-117ff,1183b-1189f,118ea-118fe,11907-11908,1190a-"
    "1190b,11914,11917,11936,11939-1193a,11944-1194f,1195a-1199f,119a8-119a9,119d8-119d9,119e2,119e5-"
    "119ff,11a3f-11a46,11a48-11a4f,11a9a-11a9c,11a9e-11abf,11af9-11bff,11c09,11c37,11c41-11c4f,11c5a-"
    "11c71,11c90-11c91,11ca8,11cb7-11cff,11d07,11d0a,11d37-11d39,11d3b,11d3e,11d48-11d4f,11d5a-"
    "11d5f,11d66,11d69,11d8f,11d92,11d99-11d9f,11daa-11edf,11ef7-11faf,11fb1-11fff,1239a-123ff,1246f-"
    "1247f,12544-12fff,1342f-143ff,14647-167ff,16a39-16a3f,16a5f,16a6a-16acf,16aee-16aef,16af5-"
    "16aff,16b37-16b3f,16b44-16b4f,16b5a-16b62,16b78-16b7c,16b90-16e3f,16e80-16eff,16f4b-16f4e,16f88-"
    "16f8e,16fa0-16fdf,16fe2,16fe5-16fef,16ff2-16fff,187f8-187ff,18cd6-18cff,18d09-1afff,1b11f-"
    "1b14f,1b153-1b163,1b168-1b16f,1b2fc-1bbff,1bc6b-1bc6f,1bc7d-1bc7f,1bc89-1bc8f,1bc9a-1bc9c,1bc9f-"
    "1d164,1d16a-1d16c,1d173-1d17a,1d183-1d184,1d18c-1d1a9,1d1ae-1d241,1d245-1d3ff,1d455,1d49d,1d4a0-"
    "1d4a1,1d4a3-1d4a4,1d4a7-1d4a8,1d4ad,1d4ba,1d4bc,1d4c4,1d506,1d50b-"
    "1d50c,1d515,1d51d,1d53a,1d53f,1d545,1d547-1d549,1d551,1d6a6-"
    "1d6a7,1d6c1,1d6db,1d6fb,1d715,1d735,1d74f,1d76f,1d789,1d7a9,1d7c3,1d7cc-1d7cd,1d800-1d9ff,1da37-"
    "1da3a,1da6d-1da74,1da76-1da83,1da85-1da9a,1daa0,1dab0-1dfff,1e007,1e019-1e01a,1e022,1e025,1e02b-"
    "1e0ff,1e12d-1e12f,1e13e-1e13f,1e14a-1e14d,1e14f-1e2bf,1e2fa-1e7ff,1e8c5-1e8cf,1e8d7-1e8ff,1e94c-"
    "1e94f,1e95a-1edff,1ee04,1ee20,1ee23,1ee25-1ee26,1ee28,1ee33,1ee38,1ee3a,1ee3c-1ee41,1ee43-"
    "1ee46,1ee48,1ee4a,1ee4c,1ee50,1ee53,1ee55-1ee56,1ee58,1ee5a,1ee5c,1ee5e,1ee60,1ee63,1ee65-"
    "1ee66,1ee6b,1ee73,1ee78,1ee7d,1ee7f,1ee8a,1ee9c-1eea0,1eea4,1eeaa,1eebc-1f12f,1f14a-1f14f,1f16a-"
    "1f16f,1f18a-1fbef,1fbfa-1ffff,2a6de-2a6ff,2b735-2b73f,2b81e-2b81f,2cea2-2ceaf,2ebe1-2f7ff,2fa1e-"
    "2ffff,3134b-e00ff,e01f0-10ffff"
)
_RANGOS = [tuple(int(x, 16) for x in (r.split("-") + [r])[:2]) for r in "".join(_SLUG_QUITAR).split(",")]
_INICIOS = [a for a, _ in _RANGOS]


def _se_borra(c):
    i = bisect.bisect_right(_INICIOS, ord(c)) - 1
    return i >= 0 and _RANGOS[i][0] <= ord(c) <= _RANGOS[i][1]


def slug_github(encabezado):
    """Ancla de GitHub, como github-slugger: minúsculas, se borran los caracteres de _SLUG_QUITAR y los
    espacios pasan a guiones. Cada carácter borrado deja su espacio (`## 2. 🧱 X` → `2--x`), y el
    selector de variación de emojis como ⚠️ NO se borra (`## ⚠️ X` → `️-x`, con U+FE0F)."""
    texto = re.sub(r"\[([^\]]*)\]\([^)]*\)", r"\1", encabezado).strip().lower()
    return "".join(c for c in texto if not _se_borra(c)).replace(" ", "-")


def es_emoji(c):
    cp = ord(c)
    return unicodedata.category(c) == "So" or 0x1F000 <= cp <= 0x1FAFF or 0x2600 <= cp <= 0x27BF


def normalizar(texto):
    """Texto visible para comparar enunciados: sin negritas y con los enlaces reducidos a su texto."""
    texto = re.sub(r"\[([^\]]*)\]\([^)]*\)", r"\1", texto)
    texto = texto.replace("**", "")
    return re.sub(r"\s+", " ", texto).strip()


# ---------------------------------------------------------------------------- el verificador


class Verificador:
    """Validaciones base. Un curso las ajusta con atributos y las amplía con los ganchos."""

    # --- dónde están las cosas
    EXCLUIR_DIRS = {"node_modules", "vendor", ".git", "target", "__pycache__", ".venv", "build", "dist"}
    DIR_PROMPTS = "prompts"                 # maquinaria: se revisan sus enlaces, no su contenido
    BLOQUE_RE = re.compile(r"^\d{2}-")      # carpeta de bloque (repasos); si no hay, el curso es plano
    CAPITULO_RE = re.compile(r"^(\d{2})-.*\.md$")
    NO_CAPITULO = ("respuestas", "simulacion", "readme")   # partes del nombre que no son capítulo
    SOLUCIONARIO_RE = re.compile(r"respuestas\.md$")

    # --- reglas de forma
    AUTOCONTENIDO = True                    # error si un enlace relativo sale del curso
    RESTOS_DE_PLANTILLA = True              # error si queda {{ o ✏️
    ARCHIVOS_CON_HUECOS = ()                # patrones de archivos publicados donde {{…}} es un hueco
                                            # para el lector, p. ej. ("cuaderno-incidentes*.md",)
    # en prompts/, los documentos que SON plantillas llevan {{…}} a propósito (la nota ✏️ sí se revisa)
    PLANTILLAS_EN_PROMPTS = ("plantilla*.md", "formato-*.md", "prompts-*.md")
    EMOJI_EN_H3_ES_ERROR = True
    EMOJI_PERMITIDOS_H3 = {"🟢", "🟡", "🟠", "🔴", "🔥", "💀"}   # la escala de dificultad sí va en ###
    PROHIBIR_ENLACES_A_PROMPTS = True      # False si el curso enlaza su guía desde el README
    # texto que un documento publicado no puede contener, ni en la prosa ni en el código: {texto: código}
    PROHIBIDOS_EN_PUBLICADOS = {"zz-code/": "ZZ-CODE"}
    CALLOUTS = {"⚠️", "🧠", "💡", "🩺", "💰", "📝", "📚"}
    # campos que el blockquote de encabezado debe nombrar; una tupla interna son alternativas
    CAMPOS_ENCABEZADO = (("Vigencia", "Fecha de verificación"),)
    SECCIONES_OBLIGATORIAS = ()             # p. ej. ("🎯 El problema", "🧠 Preguntas")
    ANCHO_MAXIMO = None                     # p. ej. 100 caracteres de prosa
    BANDA_LINEAS = None                     # p. ej. (200, 450)

    # --- preguntas y solucionario
    SECCION_PREGUNTAS = "🧠 Preguntas"
    PREGUNTA_RE = re.compile(r"^(\d+)\. (.+)$")
    BANDA_PREGUNTAS = None                  # p. ej. (20, 30)
    ORDEN_DIFICULTAD = True                 # aviso si no van de menor a mayor
    # Entrada del solucionario: `**NN → P. enunciado**` o `**NN → P.** enunciado`
    ENTRADA_RE = re.compile(r"^\*\*(\d{2}) → (\d+)\.\s*(?:\*\*\s*)?(.*?)\s*(?:\*\*)?\s*$")
    LITERAL_ES_ERROR = True
    CAPAS = ("⏱️", "🗣️", "🔬")              # () si el curso no usa respuesta en capas

    def __init__(self, raiz):
        self.raiz = os.path.abspath(raiz)
        self.errores, self.avisos = [], []
        self.correcciones = []              # (archivo, enlace escrito, enlace correcto) para --corregir-fe0f
        self._anclas = {}

    # --- informe
    def error(self, codigo, mensaje):
        self.errores.append(f"{codigo:<9} {mensaje}")

    def aviso(self, codigo, mensaje):
        self.avisos.append(f"{codigo:<9} {mensaje}")

    def rel(self, ruta):
        return os.path.relpath(ruta, self.raiz)

    # --- recorrido
    def archivos(self, alcance=None):
        for base, dirs, nombres in os.walk(alcance or self.raiz):
            dirs[:] = sorted(d for d in dirs if d not in self.EXCLUIR_DIRS and not d.startswith("."))
            for n in sorted(nombres):
                if n.endswith(".md"):
                    yield os.path.join(base, n)

    def es_de_prompts(self, ruta):
        partes = self.rel(ruta).split(os.sep)
        return self.DIR_PROMPTS in partes

    def es_capitulo(self, ruta):
        nombre = os.path.basename(ruta)
        if self.es_de_prompts(ruta) or not self.CAPITULO_RE.match(nombre):
            return False
        return not any(p in nombre.lower() for p in self.NO_CAPITULO)

    def bloques(self):
        dirs = [os.path.join(self.raiz, d) for d in sorted(os.listdir(self.raiz))
                if self.BLOQUE_RE.match(d) and os.path.isdir(os.path.join(self.raiz, d))]
        return dirs or [self.raiz]           # curso plano: la raíz es el único bloque

    # --- anclas
    def anclas(self, ruta):
        if ruta not in self._anclas:
            vistas, conjunto = {}, set()
            texto = leer(ruta)
            for _, linea in lineas_sin_codigo(texto):
                m = HEADING_RE.match(linea)
                if m:
                    base = slug_github(m.group(2))
                    k = vistas.get(base, 0)
                    conjunto.add(base if k == 0 else f"{base}-{k}")
                    vistas[base] = k + 1
            conjunto.update(re.findall(r"<a\s+(?:id|name)=\"([^\"]+)\"", texto))
            self._anclas[ruta] = conjunto
        return self._anclas[ruta]

    def ancla_con_fe0f(self, ruta, ancla):
        """Si el ancla fallida es la de un encabezado con un emoji como ⚠️ escrita sin su U+FE0F
        (el error más común), devuelve el ancla que GitHub genera de verdad."""
        for buena in self.anclas(ruta):
            if "\ufe0f" in buena and buena.replace("\ufe0f", "") == ancla:
                return buena
        return None

    # --- validaciones de todo documento
    def verificar_enlaces(self, ruta, lineas):
        for n, linea in lineas:
            for destino in LINK_RE.findall(sin_inline(linea)):
                if re.match(r"^[a-z][a-z0-9+.-]*:", destino) or destino.startswith("{{"):
                    continue
                camino, _, ancla = destino.partition("#")
                objetivo = os.path.normpath(os.path.join(os.path.dirname(ruta), camino)) if camino else ruta
                donde = f"{self.rel(ruta)}:{n} → {destino}"
                if self.AUTOCONTENIDO and os.path.commonpath([self.raiz, objetivo]) != self.raiz:
                    self.error("FUERA", donde)
                elif camino and not os.path.exists(objetivo):
                    self.error("ROTO", donde)
                elif ancla and objetivo.endswith(".md") and ancla not in self.anclas(objetivo):
                    correcta = self.ancla_con_fe0f(objetivo, ancla)
                    if correcta:
                        self.error("ANCLA-FE0F", f"{donde} (en GitHub es #{correcta})")
                        self.correcciones.append((ruta, destino, f"{camino}#{correcta}"))
                    else:
                        self.error("ANCLA", donde)
                elif self.PROHIBIR_ENLACES_A_PROMPTS and not self.es_de_prompts(ruta) and (
                        f"{self.DIR_PROMPTS}/" in camino or "_desechable-" in camino):
                    self.error("PROMPTS", donde)

    def verificar_prohibidos(self, ruta, texto):
        if self.es_de_prompts(ruta):
            return
        for n, linea in enumerate(texto.split("\n"), 1):
            for prohibido, codigo in self.PROHIBIDOS_EN_PUBLICADOS.items():
                if prohibido in linea:
                    self.error(codigo, f"{self.rel(ruta)}:{n} → cita «{prohibido}»")

    def verificar_texto(self, ruta, lineas):
        publicado = not self.es_de_prompts(ruta)
        nombre = os.path.basename(ruta)
        desechable = nombre.startswith("_desechable-")
        huecos = desechable or any(fnmatch.fnmatch(nombre, p) for p in self.ARCHIVOS_CON_HUECOS) or (
            not publicado and any(fnmatch.fnmatch(nombre, p) for p in self.PLANTILLAS_EN_PROMPTS))
        limpias = dict(lineas_sin_inline(lineas))
        for n, linea in lineas:
            limpia = limpias[n]
            if self.RESTOS_DE_PLANTILLA and not desechable and (
                    MARCA_PLANTILLA_RE.search(limpia) or (not huecos and PLACEHOLDER_RE.search(limpia))):
                self.error("RESTO", f"{self.rel(ruta)}:{n} → {linea.strip()[:80]}")
            if "Ã" in limpia or "â€" in limpia:
                self.error("MOJIBAKE", f"{self.rel(ruta)}:{n}")
            if not publicado:
                continue
            m = HEADING_RE.match(linea)
            if m and len(m.group(1)) == 3 and any(
                    es_emoji(c) and c not in self.EMOJI_PERMITIDOS_H3 for c in m.group(2)):
                registrar = self.error if self.EMOJI_EN_H3_ES_ERROR else self.aviso
                registrar("EMOJI", f"{self.rel(ruta)}:{n} → {linea.strip()}")
            c = re.match(r"^> (\S+) \*\*", linea)
            if c and c.group(1) not in self.CALLOUTS and c.group(1) != "✏️" and any(es_emoji(x) for x in c.group(1)):
                self.aviso("CALLOUT", f"{self.rel(ruta)}:{n} → {c.group(1)}")
            if (self.ANCHO_MAXIMO and len(linea) > self.ANCHO_MAXIMO and not linea.startswith("|")
                    and not re.fullmatch(r"\s*(<?https?://\S+>?|\[[^\]]*\]\([^)]*\))\s*", linea)):
                self.aviso("ANCHO", f"{self.rel(ruta)}:{n} ({len(linea)} caracteres)")

    # --- capítulos
    def secciones(self, lineas):
        return [linea[3:].strip() for _, linea in lineas if linea.startswith("## ")]

    def preguntas(self, lineas):
        """{número: (enunciado normalizado, dificultad o None)} bajo la sección de preguntas."""
        dentro, salida, actual = False, {}, None
        for _, linea in lineas:
            if linea.startswith("## ") or linea.startswith("### "):
                if dentro and linea.startswith("## "):
                    break
                dentro = dentro or self.SECCION_PREGUNTAS in linea
                continue
            if not dentro:
                continue
            m = self.PREGUNTA_RE.match(linea)
            if m:
                actual = int(m.group(1))
                salida[actual] = m.group(2)
            elif actual and re.match(r"^\s{2,}\S", linea):
                salida[actual] += " " + linea.strip()
            else:
                actual = None
        resultado = {}
        for k, v in salida.items():
            dif = next((DIFICULTAD[c] for c in reversed(v) if c in DIFICULTAD), None)
            resultado[k] = (normalizar(v), dif)
        return resultado

    def verificar_capitulo(self, ruta, lineas, texto, solucionario):
        nombre = self.rel(ruta)
        for obligatoria in self.SECCIONES_OBLIGATORIAS:
            if not any(obligatoria in s for s in self.secciones(lineas)):
                self.error("SECCION", f"{nombre}: falta «{obligatoria}»")
        encabezado = "\n".join(l for _, l in lineas[:25] if l.startswith(">"))
        for campo in self.CAMPOS_ENCABEZADO:
            alternativas = (campo,) if isinstance(campo, str) else campo
            if not any(a in encabezado for a in alternativas):
                self.aviso("ENCAB", f"{nombre}: el encabezado no dice «{' » o «'.join(alternativas)}»")
        if self.BANDA_LINEAS:
            total = texto.count("\n")
            if not self.BANDA_LINEAS[0] <= total <= self.BANDA_LINEAS[1]:
                self.aviso("LARGO", f"{nombre}: {total} líneas (banda {self.BANDA_LINEAS[0]}–{self.BANDA_LINEAS[1]})")
        preg = self.preguntas(lineas)
        if self.BANDA_PREGUNTAS and not self.BANDA_PREGUNTAS[0] <= len(preg) <= self.BANDA_PREGUNTAS[1]:
            self.aviso("BANDA", f"{nombre}: {len(preg)} preguntas (banda {self.BANDA_PREGUNTAS[0]}–{self.BANDA_PREGUNTAS[1]})")
        if self.ORDEN_DIFICULTAD:
            difs = [preg[k][1] for k in sorted(preg) if preg[k][1] is not None]
            if any(b < a for a, b in zip(difs, difs[1:])):
                self.aviso("ORDEN", f"{nombre}: las preguntas no van de menor a mayor dificultad")
        self.verificar_sincronia(ruta, preg, solucionario)
        self.verificar_capitulo_extra(ruta, lineas, texto, preg)

    # --- solucionario
    def leer_solucionario(self, carpeta):
        """{capítulo NN: {pregunta: enunciado}}, el archivo y su texto; None si no hay."""
        candidatos = [f for f in sorted(os.listdir(carpeta)) if self.SOLUCIONARIO_RE.search(f)]
        if not candidatos:
            return None
        ruta = os.path.join(carpeta, candidatos[0])
        texto = leer(ruta)
        entradas, lineas = {}, [l for _, l in lineas_sin_codigo(texto)]
        for i, linea in enumerate(lineas):
            if not re.match(r"^\*\*\d{2} → ", linea):
                continue
            # el enunciado puede seguir en las líneas siguientes: hasta la línea en blanco, hasta
            # cerrar con su emoji de dificultad (y la negrita), o hasta que empiece una capa
            j = i
            while j + 1 < len(lineas) and lineas[j + 1].strip():
                cerrada = re.search(r"[🟢🟡🟠🔴]\s*(\*\*)?\s*$", linea) and linea.count("**") % 2 == 0
                siguiente = lineas[j + 1].strip()
                if cerrada or siguiente.startswith(tuple(self.CAPAS) + ("- ", ">", "|", "#")):
                    break
                j += 1
                linea += " " + siguiente
            m = self.ENTRADA_RE.match(linea)
            if m:
                entradas.setdefault(m.group(1), {})[int(m.group(2))] = normalizar(m.group(3))
        if re.search(r"\bpendiente\b", texto, re.I):
            self.aviso("PENDIENTE", f"{self.rel(ruta)} dice «pendiente»")
        if self.CAPAS:
            for bloque in re.split(r"\n(?=\*\*\d{2} → |#)", texto):
                if not re.match(r"\*\*\d{2} → \d+\.", bloque):
                    continue                # simulaciones y ejercicios tienen otro formato
                if not all(c in bloque for c in self.CAPAS):
                    self.aviso("CAPAS", f"{self.rel(ruta)}: {bloque.split(chr(10))[0][:60]}")
        return {"ruta": ruta, "entradas": entradas}

    def verificar_sincronia(self, ruta, preg, solucionario):
        if not preg:
            return
        nombre = self.rel(ruta)
        if solucionario is None:
            self.aviso("SIN-SOL", f"{nombre}: no hay solucionario en su carpeta")
            return
        if not solucionario["entradas"]:
            if not solucionario.get("avisado"):
                solucionario["avisado"] = True
                self.aviso("FORMATO", f"{self.rel(solucionario['ruta'])}: ninguna entrada reconocida;"
                                      " ajustar ENTRADA_RE al formato del curso")
            return
        nn = os.path.basename(ruta)[:2]
        resp = solucionario["entradas"].get(nn, {})
        if len(resp) != len(preg):
            self.error("SINCRO", f"{nombre}: {len(preg)} preguntas, {len(resp)} en el solucionario")
        for k in sorted(set(preg) - set(resp)):
            self.error("FALTA", f"{nombre}: la pregunta {k} no está en el solucionario")
        for k in sorted(set(resp) - set(preg)):
            self.error("SOBRA", f"{self.rel(solucionario['ruta'])}: {nn} → {k}")
        for k in sorted(set(preg) & set(resp)):
            capitulo = re.sub(r"\s*[🟢🟡🟠🔴]\s*", " ", preg[k][0]).strip()
            respuesta = re.sub(r"\s*[🟢🟡🟠🔴]\s*", " ", resp[k]).strip()
            if capitulo != respuesta:
                registrar = self.error if self.LITERAL_ES_ERROR else self.aviso
                registrar("LITERAL", f"{nombre} → {k}: el solucionario dice «{respuesta[:70]}»"
                                     f" y el capítulo «{capitulo[:70]}»")

    # --- ganchos para el curso
    def verificar_documento_extra(self, ruta, lineas, texto):
        """Validaciones propias del curso sobre cualquier documento publicado."""

    def verificar_capitulo_extra(self, ruta, lineas, texto, preguntas):
        """Validaciones propias del curso sobre cada capítulo."""

    def verificar_corpus_extra(self):
        """Validaciones globales propias del curso (rutas del README, inventario contra fichas…)."""

    # --- orquestación
    def correr(self, alcance=None):
        alcance = os.path.join(self.raiz, alcance) if alcance else self.raiz
        for ruta in self.archivos(alcance):
            texto = leer(ruta)
            lineas = lineas_sin_codigo(texto)
            self.verificar_enlaces(ruta, lineas)
            self.verificar_texto(ruta, lineas)
            self.verificar_prohibidos(ruta, texto)
            if not self.es_de_prompts(ruta):
                self.verificar_documento_extra(ruta, lineas, texto)
        for carpeta in self.bloques():
            if os.path.commonpath([alcance, carpeta]) not in (alcance, carpeta):
                continue
            solucionario = self.leer_solucionario(carpeta)
            for nombre in sorted(os.listdir(carpeta)):
                ruta = os.path.join(carpeta, nombre)
                if os.path.isfile(ruta) and self.es_capitulo(ruta):
                    texto = leer(ruta)
                    self.verificar_capitulo(ruta, lineas_sin_codigo(texto), texto, solucionario)
        if alcance == self.raiz:
            self.verificar_corpus_extra()
        return self.informe()

    def corregir_fe0f(self):
        """Reescribe cada enlace ANCLA-FE0F con su ancla correcta. Solo toca `](enlace)` exactos."""
        por_archivo = {}
        for ruta, viejo, nuevo in self.correcciones:
            por_archivo.setdefault(ruta, set()).add((viejo, nuevo))
        total = 0
        for ruta, cambios in sorted(por_archivo.items()):
            texto = leer(ruta)
            for viejo, nuevo in cambios:
                total += texto.count(f"]({viejo})")
                texto = texto.replace(f"]({viejo})", f"]({nuevo})")
            with open(ruta, "w", encoding="utf-8") as f:
                f.write(texto)
        print(f"corregidos {total} enlaces en {len(por_archivo)} archivos")

    def informe(self):
        for linea in self.errores:
            print("ERROR", linea)
        for linea in self.avisos:
            print("aviso", linea)
        print(f"— {len(self.errores)} errores, {len(self.avisos)} avisos")
        return 1 if self.errores else 0


# ---------------------------------------------------------------------------- perfiles por repositorio


class PerfilRepasoEntrevistas(Verificador):
    """Valores de `job-interview-sept-2026/repaso-entrevistas`: callouts del CLAUDE.md, sin emoji en
    ###, y autocontención editorial (los otros corpus se enlazan como sugerencia y el README enlaza
    la guía)."""
    AUTOCONTENIDO = False
    PROHIBIR_ENLACES_A_PROMPTS = False
    CALLOUTS = {"⚠️", "🧠", "💡", "🩺", "💰", "📝", "📚"}


class PerfilCoursesIA(Verificador):
    """Valores de `Learning/courses-ia-generated`: cursos autocontenidos, emoji "con moderación" en
    subsecciones (aviso, no error), y los callouts que esos cursos usan de verdad."""
    AUTOCONTENIDO = True
    PROHIBIR_ENLACES_A_PROMPTS = False
    EMOJI_EN_H3_ES_ERROR = False
    ARCHIVOS_CON_HUECOS = ("cuaderno-incidentes*.md",)
    CALLOUTS = {"📝", "🧭", "🧠", "⚠️", "💡", "🏷️", "⚖️", "💸", "🪞", "🩺", "📐", "🪦", "🔥",
                "🩻", "🔎", "⚰️", "🧪", "📏", "🦭", "🧨", "🧰", "📚", "📖", "🚧", "🌩️"}
    CAPAS = ()


class PerfilPublicacion(Verificador):
    """Etapa E9: lo que tiene que cumplir la carpeta de un curso antes de copiarla a su repositorio
    público (sin `prompts/`, que no se publica). Todo enlace que salga del curso o entre en `prompts/`
    se rompería allí, y nada privado puede viajar."""
    AUTOCONTENIDO = True
    PROHIBIR_ENLACES_A_PROMPTS = True
    PROHIBIDOS_EN_PUBLICADOS = {
        "zz-code/": "ZZ-CODE",
        "zz-instrucciones": "PRIVADO",
        "_desechable-": "PRIVADO",
        "Entrevistas/": "PRIVADO",
        "REPASO-": "PRIVADO",
        "PLAN-REFRESCAMIENTO": "PRIVADO",
        "_oskar/": "PRIVADO",
        "propuestas-cursos/": "PRIVADO",
    }


PERFILES = {"base": Verificador, "repaso": PerfilRepasoEntrevistas, "courses-ia": PerfilCoursesIA,
            "publicacion": PerfilPublicacion}


def main(clase=Verificador, raiz=None):
    """Punto de entrada. Un curso llama `main(MiVerificador, RAIZ)`; sin raíz, la toma de argv."""
    args = sys.argv[1:]
    for a in list(args):
        if a.startswith("--perfil="):
            args.remove(a)
            clase = PERFILES.get(a.split("=", 1)[1])
            if clase is None:
                print(f"Perfiles: {', '.join(PERFILES)}")
                return 2
    if raiz is None:
        if not args or not os.path.isdir(args[0]):
            print(__doc__)
            return 2
        raiz, args = args[0], args[1:]
    corregir = "--corregir-fe0f" in args
    args = [a for a in args if a != "--corregir-fe0f"]
    alcance = args[0] if args else None
    if alcance and not os.path.isdir(os.path.join(raiz, alcance)):
        print(f"No existe: {alcance}")
        return 2
    verificador = clase(raiz)
    codigo = verificador.correr(alcance)
    if corregir and verificador.correcciones:
        verificador.corregir_fe0f()
        codigo = clase(raiz).correr(alcance)        # segunda pasada, para ver lo que queda
    return codigo


if __name__ == "__main__":
    sys.exit(main())
