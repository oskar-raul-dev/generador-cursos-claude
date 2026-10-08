# 🔤 tx08 — Texto difícil: Unicode e internacionalización

> Python para desarrolladores Java senior · **Carta** · Track `tx` — Texto, plantillas y
> documentación · sección 8 de 9
> Se lee suelta: no hace falta ninguna otra sección de la carta.
> Versiones verificadas contra PyPI el 05/10/2026 · Código probado el 05/10/2026 con Python 3.14.7,
> en contenedor: las salidas son las de esa corrida.

---

## 🎯 1. Qué problema resuelve

Tres quejas de las sedes, de la misma semana. En Chapinero, la búsqueda de pacientes no encuentra a **Muñoz** aunque
está en la lista: el nombre llegó de una exportación hecha en un Mac y la `ñ` viene como dos caracteres. En Usaquén, el
listado alfabético pone a **Álvarez** después de **Zuluaga**. Y el recordatorio por SMS de una paciente llegó cortado
con un símbolo raro al final, donde iba un emoji.

Python 3 tiene cadenas Unicode desde el principio, y este perfil asume que "el texto ya está resuelto". Unicode resuelve
**qué** caracteres existen; no resuelve que el mismo texto tenga dos representaciones, que el orden alfabético dependa
del idioma, ni que lo que una persona ve como un carácter sean dos o siete puntos de código. Esta sección es la caja de
herramientas para eso, más la otra mitad del tema: mostrar números, plata y fechas como se escriben en Colombia.

---

## 🧠 2. El modelo

| Problema | Por qué pasa | La herramienta |
|---|---|---|
| `"Muñoz" != "Muñoz"` | `ñ` puede ser un punto de código (NFC) o `n` + tilde combinante (NFD) | `unicodedata.normalize("NFC", s)` al entrar |
| `Álvarez` después de `Zuluaga` | `sorted` compara puntos de código; `Á` (U+00C1) va después de `Z` (U+005A) | Una clave de orden por idioma; PyICU para hacerlo bien |
| Mayúsculas y minúsculas | `lower()` no es suficiente para comparar (la `ß` alemana, la `İ` turca) | `casefold()` |
| El emoji cortado | Lo que se ve como un carácter puede ser varios puntos de código | `regex` con `\X` (grafemas) |
| `$1.234.567,50` | El separador de miles y el decimal dependen del país | `babel` |
| Traducir la interfaz | — | `gettext` (biblioteca estándar) y `babel` para extraer cadenas |

La regla que ataja la mitad: **normalizar a NFC en la frontera**, en el momento en que el texto entra al sistema
(formulario, importación, API), igual que se valida cualquier otro dato.

### Tu instinto de Java dice… y esta vez se equivoca

En Java, `String.length()` cuenta unidades UTF-16, y este perfil aprendió a desconfiar de ella con los emojis. En Python,
`len()` cuenta puntos de código, que es mejor, y el instinto concluye que ya está bien. No está: `len("👍🏽")` es 2 (el
pulgar y el tono de piel), y `len` de la `ñ` en NFD también es 2. Lo que la persona ve como uno es un **grafema**, y ni
Java ni Python lo cuentan sin ayuda.

---

## 💻 3. El ejemplo que corre

```bash
uv add regex babel
```

`texto.py`:

```python
"""Normalización, orden en español, grafemas y formatos de Colombia."""

import unicodedata
from datetime import date
from decimal import Decimal

import regex
from babel.dates import format_date
from babel.numbers import format_currency, format_decimal

# ------------------------------------------------- 1. dos representaciones del mismo nombre
typed = "Muñoz"                                         # escrito en el formulario: NFC
exported = unicodedata.normalize("NFD", "Muñoz")       # llegó de la exportación del Mac
print("iguales:", typed == exported, "| largo:", len(typed), len(exported))
print("normalizados:", unicodedata.normalize("NFC", exported) == typed)

# ------------------------------------------------- 2. orden alfabético
names = ["Zuluaga", "Álvarez", "ávila", "Nuñez", "Ñañez", "Ochoa", "Mendoza"]


def strip_accents(s: str) -> str:
    return "".join(c for c in unicodedata.normalize("NFD", s.casefold())
                   if unicodedata.category(c) != "Mn")


def spanish_key(s: str) -> str:
    """Sin tildes, pero con la ñ como letra propia entre la n y la o."""
    s = unicodedata.normalize("NFC", s.casefold()).replace("ñ", "n￿")
    return strip_accents(s)


print("sorted:          ", sorted(names))
print("sin tildes:      ", sorted(names, key=strip_accents))
print("español:         ", sorted(names, key=spanish_key))

# ------------------------------------------------- 3. grafemas
sms = "Te esperamos mañana 👍🏽"
print("puntos de código:", len(sms), "| grafemas:", len(regex.findall(r"\X", sms)))
print("cortado a 21:    ", repr(sms[:21]))
print("cortado bien:    ", repr("".join(regex.findall(r"\X", sms)[:21])))

# ------------------------------------------------- 4. plata, números y fechas de Colombia
print(format_currency(Decimal("1234567.5"), "COP", locale="es_CO"))
print(format_decimal(Decimal("0.866"), format="#,##0.0 %", locale="es_CO"))
print(format_date(date(2026, 10, 5), format="full", locale="es_CO"))
```

```bash
python3 texto.py
```

Salida (Python 3.14.7, 05/10/2026):

```text
iguales: False | largo: 5 6
normalizados: True
sorted:           ['Mendoza', 'Nuñez', 'Ochoa', 'Zuluaga', 'Álvarez', 'Ñañez', 'ávila']
sin tildes:       ['Álvarez', 'ávila', 'Mendoza', 'Ñañez', 'Nuñez', 'Ochoa', 'Zuluaga']
español:          ['Álvarez', 'ávila', 'Mendoza', 'Nuñez', 'Ñañez', 'Ochoa', 'Zuluaga']
puntos de código: 22 | grafemas: 21
cortado a 21:     'Te esperamos mañana 👍'
cortado bien:     'Te esperamos mañana 👍🏽'
$1.234.567,50
86,6 %
lunes, 5 de octubre de 2026
```

Cada bloque, una queja de las sedes. Los dos `Muñoz` no son iguales hasta normalizarlos. `sorted` manda todo lo que
lleva tilde al final, en el orden de sus puntos de código (`Á` es U+00C1, `Ñ` U+00D1, `á` U+00E1); quitar las tildes lo arregla casi todo, pero pone `Ñañez` antes de `Nuñez`, que en español es un
error; la clave propia trata la `ñ` como letra. Y el SMS cortado a 21 puntos de código separa el pulgar de su tono de
piel: el teléfono muestra un pulgar amarillo y, según el modelo, un cuadrado.

**Detalles con intención**

- **`unicodedata.category(c) != "Mn"`** descarta las marcas combinantes (tildes, diéresis) después de descomponer en
  NFD. Es la forma estándar de quitar tildes sin una tabla a mano.
- **`"n￿"`** pone la `ñ` después de cualquier `n` seguida de otra letra, que es lo que pide el orden del español.
  Es un truco para un idioma; el orden correcto para cualquier idioma es el algoritmo de *collation* de Unicode, que da
  **PyICU** (`icu.Collator.createInstance(icu.Locale("es_CO"))`), al costo de una dependencia nativa que no siempre trae
  ruedas para todas las plataformas.
- **`regex`** es compatible con `re` y agrega lo que `re` no tiene: `\X` para grafemas, `\p{L}` para "cualquier letra de
  cualquier idioma", y propiedades de Unicode en general.
- **`babel` usa los datos de CLDR**, los mismos que usan Java (`java.text` y `java.time` desde la 9), ICU y los
  navegadores. El formato de `es_CO` en Python coincide con el de una aplicación Java bien configurada.

---

## ⚠️ 4. Lo que se rompe

**Normalizar al comparar y no al guardar.** Si la base guarda NFC y NFD mezclados, cada consulta tiene que normalizar, y
el índice de la columna no sirve para buscar. Se normaliza al entrar y se guarda una sola forma.

**`locale.setlocale` en un servidor.** El módulo `locale` de la biblioteca estándar depende de los *locales* instalados
en el sistema operativo y es global al proceso: en un contenedor mínimo, `es_CO.UTF-8` no existe y la llamada falla, y en
un servidor con hilos, cambiarlo afecta a todos. `babel` trae sus propios datos y recibe el *locale* por argumento.

**`str.upper()` para comparar.** `"straße".upper()` es `"STRASSE"`, y `"İ".lower()` tiene dos puntos de código. Para
comparar sin mayúsculas, `casefold()`; para mostrar, `upper()`.

**El SMS de 160 caracteres.** El límite de un SMS no es de caracteres sino de bytes en una codificación (GSM-7 o UCS-2):
una sola `ñ` no está en todas las variantes de GSM-7, y un emoji obliga a UCS-2 y baja el límite a 70. Lo calcula la
pasarela de SMS; el texto se corta por grafemas, nunca por puntos de código.

---

## ⚖️ 5. Cuándo NO usarlo

**PyICU, para ordenar una lista de diez sedes.** La clave propia alcanza para el español; PyICU se justifica con varios
idiomas o cuando el orden tiene consecuencias (un directorio impreso, un listado legal).

**`gettext`, para una interfaz en un solo idioma.** Áurea opera en Colombia, en español. Marcar todas las cadenas para
traducir es un costo sin beneficio hasta que exista el segundo idioma.

**`regex` cuando `re` alcanza.** Para validar una cédula o un código de sede, `re` es suficiente y no agrega una
dependencia.

---

## 🧪 6. Ejercicios (10)

**🟢 Fácil (1–3)**

1. Imprime los puntos de código de los dos `Muñoz` con `[hex(ord(c)) for c in s]`. **Criterio:** señalas cuál es la
   tilde combinante.
2. Compara `"Straße".casefold() == "STRASSE".casefold()` y con `lower()`. **Criterio:** los dos resultados y la razón.
3. Formatea con `babel` el mismo monto en `es_CO`, `es_ES` y `en_US`. **Criterio:** las tres salidas, y qué cambia en
   cada una.

**🟡 Intermedio (4–6)**

4. Escribe la función de búsqueda de pacientes que encuentra `Muñoz` escribiendo `munoz`. **Criterio:** una prueba con
   NFC, NFD, mayúsculas y sin tilde.
5. Normaliza a NFC en la frontera de un modelo de Pydantic (un validador). **Criterio:** el nombre exportado del Mac se
   guarda en NFC.
6. Corta el SMS a 70 grafemas para UCS-2. **Criterio:** ningún emoji queda partido, con una prueba que use tonos de
   piel y banderas.

**🟠 Difícil (7–9)**

7. Ordena la lista con PyICU y compara con `spanish_key`. **Criterio:** encuentras un caso donde difieren, o argumentas
   por qué no hay ninguno para nombres en español.
8. Extrae las cadenas de una interfaz pequeña con `pybabel extract` y tradúcelas al inglés con `gettext`. **Criterio:**
   la interfaz cambia de idioma con una variable.
9. Encuentra en la base (o en un CSV de prueba) los nombres que no están en NFC. **Criterio:** una consulta o un script
   que los lista, y la migración que los normaliza.

**🔴 Muy difícil (10)**

10. Define la política de texto de Áurea. **Criterio:** una página. *Rúbrica:* (a) en qué forma se guarda el texto y
    dónde se normaliza; (b) cómo se busca y cómo se ordena; (c) cómo se muestran plata, números y fechas; (d) qué
    pasaría si Áurea abriera una sede en Brasil.

---

## 📚 7. Referencias

**Documentación oficial**

- `unicodedata`: https://docs.python.org/3/library/unicodedata.html
- *Unicode HOWTO* de Python: https://docs.python.org/3/howto/unicode.html
- `regex`: https://github.com/mrabarnett/mrab-regex
- Babel: https://babel.pocoo.org/en/latest/
- Unicode, segmentación de texto (grafemas): https://www.unicode.org/reports/tr29/

**Orden de lectura sugerido:** el *Unicode HOWTO* de Python; después la sección de grafemas del informe 29 de Unicode.

---

## 🚀 8. Cierre

Unicode dice qué caracteres existen; el resto es trabajo. Se normaliza a NFC en la frontera, se compara con
`casefold()`, se ordena con una clave por idioma, se corta por grafemas y se formatea con los datos de CLDR que trae
`babel`. Ninguna de esas cosas la hace `str` por su cuenta.

**La señal de que quedó bien:** *"Buscaron `munoz` en Chapinero y apareció Muñoz, la del Mac, con su ñ."*

> 🏷️ **Cierra la sección con su tag**, cuando los ejercicios que elegiste estén hechos:
>
> ```bash
> git tag -a op-tx-fase-08 -m "op tx08 cerrada: normalizar, ordenar, cortar por grafemas y formatear para Colombia"
> ```
>
> Los commits llevan su prefijo (`op tx08: …`) y los de ejercicio su número
> (`op tx08 ej07: …`).
