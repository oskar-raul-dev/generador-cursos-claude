# 📦 Fase 06 — Formatos en la caja

> Python para desarrolladores Java senior · Fase 6 de 18 · Bloque A
> Depende de: Fase 05 · Habilita: Fase 07
> Registro de esta fase: **script** — un archivo, stdlib pura · **cierra el Bloque A**
> Proyecto que avanza: el CLI · **y se paga la deuda 💸 de la Fase 01**
> Fecha de verificación de las versiones: 12/09/2026

---

## 🎯 1. Propósito

Cerrar el Bloque A demostrando cuánto trabajo real se hace sin instalar nada — y **pagar la
deuda** que el curso contrajo a propósito en la Fase 01.

Seis fases atrás, `read_rows` partía las líneas con `split(",")`. Funcionaba, y el docstring decía
en qué fase se iba a arreglar. Hoy llega el archivo con un paciente que se llama
`Cárdenas, Carlos Efrén` y el script se cae — y si alguien le hubiera puesto un `except` encima
para que no se cayera, habría facturado **$360.000 donde debía facturar $1.345.000**. Esa factura
se paga hoy, con los dos números delante.

---

## ✅ 2. Qué queda listo al terminar

- [ ] `aur` lee los diez exports del cierre aunque vengan en seis formatos distintos, con dos
      encodings y tres separadores.
- [ ] La deuda 💸 de la Fase 01 está pagada, y puedes leer la factura con
      `git diff fase-01 fase-06 -- aur_cli.py`.
- [ ] Sabes qué es un BOM, por qué Excel lo pone, y cómo se lee sin verlo.
- [ ] Puedes explicar por qué `errors="ignore"` es una decisión y no un arreglo.
- [ ] Las tarifas de los aliados viven en un TOML y cambiarlas ya no es cambiar código.
- [ ] El histórico está en `sqlite3` con su índice, y responder *"¿esto ya lo facturamos?"* cuesta
      microsegundos.
- [ ] El miniproyecto de la sección 7 corre y cumple sus criterios de aceptación.

---

## 🚫 3. Qué NO entra todavía

- **Bases de datos servidor** → Fase 11. `sqlite3` aquí es el almacén local de un script, no una
  base de datos de una aplicación, y la diferencia es todo el tema de esa fase.
- **Empaquetar todo esto** → Fase 07, la que viene. Hoy el archivo ya pesa demasiado y eso es
  parte del argumento.
- **Validación con esquema** (Pydantic) → Fase 10.
- **XML.** Áurea genera XML para la DIAN y la biblioteca estándar lo trae
  (`xml.etree.ElementTree`), pero el XML de factura electrónica colombiana tiene firma digital y
  un esquema oficial que cambia por resolución. **Se queda fuera del curso con su razón escrita:**
  enseñar a producirlo bien exigiría material normativo que envejece cada año. El curso genera el
  XML como texto en la Fase 05 y lo firma con el binario del proveedor, que es lo que Áurea hace
  de verdad.

---

## 🧠 4. Concepto mínimo

### Tu instinto de Java dice… y esta vez se equivoca

**El reflejo, y es el que el Bloque A entero viene atacando:** *"busco una biblioteca para esto"*.

En tu mundo agregar una dependencia es gratis. Una línea en el `pom.xml`, un artefacto firmado en
el repositorio corporativo, y a otra cosa. Necesitas leer un CSV: OpenCSV. JSON: Jackson. Un ZIP:
Commons Compress. La biblioteca estándar de Java es buena y aun así el reflejo es correcto allá,
porque el costo de la dependencia es casi cero.

Aquí el costo no es cero, y la Fase 07 lo va a medir: cada dependencia es algo que se resuelve,
que se instala, que puede romperse, y que **Patricia va a tener que tener en su portátil**. Y la
mitad de las veces, la respuesta ya viene en la caja.

Lo que trae la biblioteca estándar y que este perfil no sabe que trae:

| Lo que necesitas | Lo que buscarías | Lo que ya tienes |
|---|---|---|
| Leer y escribir CSV | OpenCSV, Commons CSV | `csv`, con dialectos y comillas |
| JSON | Jackson, Gson | `json` |
| Configuración | SnakeYAML, Typesafe Config | `tomllib` (leer), `configparser` |
| Base de datos embebida | H2, SQLite JDBC | `sqlite3` |
| ZIP y TAR | Commons Compress | `zipfile`, `tarfile` |
| Fechas | — | `datetime`, `zoneinfo` |
| HTTP servidor de prueba | Jetty embebido | `http.server` |
| Hashes y HMAC | Commons Codec | `hashlib`, `hmac` |

**El segundo reflejo**, y este lo comparte todo el mundo que lleva quince años sin pensar en
encodings: **asumir UTF-8**. En tu mundo la JVM ya normalizó casi todo, las herramientas te
protegen, y hace años que no ves un carácter roto. En este cierre de mes vas a ver dos.

### Encoding, donde de verdad duele

Tres cosas que hay que tener claras, porque en el cierre de mes de Áurea aparecen las tres:

**El `latin-1` del export de Odontovía.** El sistema es de 2014 y exporta en ISO-8859-1. Leerlo
como UTF-8 lanza `UnicodeDecodeError` —si tienes suerte— o produce `CÃ¡rdenas` en vez de
`Cárdenas`. La solución no es adivinar: es **saber** y declararlo:

```python
path.read_text(encoding="latin-1")
```

**El BOM que pone Excel.** Cuando alguien guarda un CSV desde Excel como "UTF-8 con BOM", el
archivo empieza con tres bytes invisibles (`EF BB BF`). Leído como `utf-8`, esos bytes se
convierten en un carácter invisible **pegado al primer nombre de columna**, así que tu encabezado
deja de llamarse `documento` y pasa a llamarse `﻿documento`. El síntoma es un `KeyError` sobre
una llave que ves con tus propios ojos en el archivo.

```python
path.read_text(encoding="utf-8-sig")   # utf-8 que se come el BOM si está, y si no, no pasa nada
```

> 💡 **`utf-8-sig` es seguro por defecto para archivos que vienen de otra gente.** Si hay BOM lo
> quita; si no hay, se comporta como `utf-8`. Para archivos que escribes tú, usa `utf-8` a secas:
> ponerle BOM a un archivo que va a leer un programa es regalarle el problema a otro.

**Y `errors=` es una decisión, no un arreglo.** Cuando el byte no se puede decodificar, tienes tres
opciones y ninguna es neutral:

```python
path.read_text(encoding="utf-8")                     # lanza. La opción honesta por defecto
path.read_text(encoding="utf-8", errors="replace")   # pone � y sigue. Visible: puedes detectarlo
path.read_text(encoding="utf-8", errors="ignore")    # borra el byte. Silencioso: NADIE se entera
```

`errors="ignore"` sobre el nombre de un paciente le borra las tildes y nadie lo nota hasta que la
aseguradora rechaza el registro por no coincidir con la cédula. **Si vas a usarlo, que sea una
decisión escrita en un comentario con su razón.** `replace` es casi siempre mejor: el `�` se puede
buscar.

### Esto sí funciona igual

**SQL es SQL.** Todo lo que sabes de modelado, índices, transacciones, claves y planes de
ejecución vale exactamente igual con `sqlite3`. Es la parte del curso donde tu experiencia
transfiere al 100%, y donde vas a ir más rápido que cualquier pythonista de dos años.

**Las transacciones son transacciones.** `BEGIN`, `COMMIT`, `ROLLBACK`, y el mismo criterio sobre
dónde ponen los límites.

**Y los índices cuestan lo que siempre han costado:** espacio en disco y escrituras más lentas, a
cambio de lecturas más rápidas. La sección 6 lo mide, y el resultado no te va a sorprender — lo
que sorprende es cuánto.

### Diccionario de traducción

| Java | Python | Dónde se rompe el paralelo |
|---|---|---|
| OpenCSV / Commons CSV | `csv` | En la caja. Maneja dialectos, comillas y saltos de línea dentro de celda |
| Jackson / Gson | `json` | Sin anotaciones ni *binding* automático: entra y sale `dict`. Fase 10 trae lo otro |
| `Properties` / YAML | `tomllib` | **Solo lee**: para escribir TOML hace falta biblioteca. Y es deliberado |
| JDBC + SQLite | `sqlite3` | En la caja, con la API DB-API 2.0 en vez de JDBC. Mismo SQL |
| `PreparedStatement` | `?` en `execute(sql, params)` | Idéntico, y por la misma razón: nunca concatenes SQL |
| `try (Connection c = ...)` | `with sqlite3.connect(...)` | ⚠️ **El `with` de `sqlite3` hace commit, NO cierra**. §5.4 |
| `ZipFile` de Commons | `zipfile` | En la caja, con soporte de lectura en flujo |
| `new String(bytes, UTF_8)` | `bytes.decode("utf-8")` | Igual, y aquí el valor por defecto del sistema sí te puede morder |
| `Charset.defaultCharset()` | `locale.getpreferredencoding()` | En Windows **no es UTF-8**. Declara siempre el encoding |
| `BufferedReader` línea a línea | el archivo es un iterador | Fase 02: no hace falta envolverlo en nada |

> 📝 **Nota de ecosistema — `tomllib` solo lee, y es a propósito.** TOML entró a la biblioteca
> estándar en 3.11 (PEP 680) como formato de configuración, porque `pyproject.toml` lo había
> convertido en el estándar de facto del ecosistema. Solo trae el lector: escribir TOML preservando
> comentarios y formato es un problema mucho más difícil, y se dejó a bibliotecas externas. Para lo
> que un script necesita —leer configuración que edita una persona— alcanza y sobra. Antes de 3.11
> lo normal era `configparser` (INI), YAML con una dependencia, o JSON — que es malo como formato
> de configuración porque no admite comentarios.

### `csv`, y por qué `split(",")` nunca fue suficiente

El formato CSV parece trivial y no lo es. Lo que el módulo `csv` maneja y tu `split` no:

**Comas dentro de una celda entrecomillada.** `"Cárdenas, Carlos Efrén"` es **un** campo. Tu
`split(",")` ve dos, y a partir de ahí todas las columnas de esa fila están corridas un lugar: el
valor termina en la columna del código, y el script suma texto o revienta.

**Comillas dentro de comillas.** `"Retenedor fijo 3x3, ""tipo Hawley"""` es un campo cuyo
contenido lleva comillas. La regla de escape del formato es duplicarlas.

**Saltos de línea dentro de una celda.** Una nota clínica escrita en dos renglones produce un
campo que ocupa dos líneas del archivo. Leer el archivo línea por línea —como venimos haciendo
desde la Fase 02— rompe esa fila en dos.

**Dialectos.** El separador no siempre es una coma: los sistemas configurados en español suelen
usar punto y coma, porque la coma es el separador decimal. Odontovía exporta con `;`.

```python
import csv

with path.open(encoding="latin-1", newline="") as file:
    reader = csv.DictReader(file, delimiter=";")
    for row in reader:
        row["paciente"]    # 'Cárdenas, Carlos Efrén', entero y en su sitio
```

> ⚠️ **`newline=""` no es opcional y no es cosmético.** La documentación de `csv` lo exige: sin
> él, el módulo no puede manejar los saltos de línea dentro de celda, y en Windows además
> aparecen líneas en blanco al escribir. Es el detalle más fácil de olvidar de toda la fase.

---

## 💻 5. Código mínimo con comentarios

### 5.1 La deuda, pagada

Esto es lo que decía `read_rows` en la Fase 01:

```python
# Fase 01 — con su deuda declarada
def read_rows(path):
    with open(path, encoding="utf-8") as file:
        next(file)
        for line in file:
            line = line.strip()
            if not line:
                continue
            yield tuple(line.split(","))
```

Y esto es lo que dice hoy:

```python
import csv
from dataclasses import dataclass
from decimal import Decimal
from pathlib import Path


@dataclass(frozen=True, slots=True)
class Row:
    """Una fila del export, ya normalizada, venga del formato que venga."""

    document: str
    patient: str
    branch: str
    date: str
    code: str
    description: str
    amount: Decimal


def read_rows(path: Path, *, encoding: str = "utf-8-sig", delimiter: str = ","):
    """Lee un export y produce filas normalizadas.

    💸 Deuda de la Fase 01 PAGADA. El `split(",")` partía en dos el nombre
    'Cárdenas, Carlos Efrén' y corría todas las columnas de esa fila un lugar,
    sin lanzar nada. El módulo `csv` lo resuelve, y de paso resuelve las
    comillas escapadas y los saltos de línea dentro de celda.

    El encoding y el separador son parámetros porque las diez sedes no se
    pusieron de acuerdo: seis exportan latin-1 con punto y coma, una trae BOM
    de Excel, y Zipaquirá usa tabuladores.
    """
    with path.open(encoding=encoding, newline="") as file:
        for record in csv.DictReader(file, delimiter=delimiter):
            yield Row(
                document=record["documento"].strip(),
                patient=record["paciente"].strip(),
                branch=record["sede"].strip(),
                date=record["fecha"].strip(),
                code=record["codigo"].strip(),
                description=record.get("descripcion", "").strip(),
                amount=parse_amount(record["valor"]),
            )
```

**La factura, con números.** Cuatro filas del export, dos de ellas con una coma dentro del nombre
—que es lo que produce cualquier sistema que escriba `apellido, nombre`—:

```text
documento,paciente,sede,fecha,codigo,valor
1019283746,Ana María Robledo,Centro,2026-03-04,D8010,180000
52847193,"Cárdenas, Carlos Efrén",Centro,2026-03-04,D2740,890000
79541226,Luz Dary Peña,Centro,2026-03-19,D8010,180000
1090957655,"Neira, Yenny Paola",Centro,2026-03-22,D8020,95000
```

| | Filas leídas | Pacientes | Total facturado |
|---|---|---|---|
| `split(",")` de la Fase 01 | 2 de 4 | 2 | **$360.000** |
| `csv.DictReader` | 4 de 4 | 4 | **$1.345.000** |

**Y conviene ser preciso sobre cómo falla, porque no es como uno esperaría.** El `split` produce
siete campos donde había seis, así que `row[5]` deja de ser el valor y pasa a ser el código: al
convertirlo, `Decimal("D2740")` levanta `InvalidOperation`. En la Fase 01 no había manejo de
errores, así que **el script muere con su traza en la primera fila con coma** — ruidoso, feo, y
honesto.

El daño silencioso aparece cuando alguien, para que "no se caiga", envuelve eso en un
`except Exception: continue`. Ahí el script sobrevive, salta las dos filas, y reporta
$360.000 con toda tranquilidad: **un 73% menos**, sin una sola advertencia. Es exactamente el
error 1 de la Fase 04, y esta es su factura en pesos.

**Y la factura en código:**

```bash
git diff fase-01 fase-06 -- aur_cli.py
```

Léela entera una vez. Lo que vas a ver no es un cambio de tres líneas: es que **el arreglo tocó la
firma de la función, la forma de la fila, y todo lo que dependía de que el orden de las columnas
fuera fijo**. Ese es el costo real de una deuda que se deja crecer seis fases, y es barato solo
porque el curso la acotó a propósito: estaba declarada, tenía fecha de pago, y nadie construyó
encima suponiendo que estaba bien.

> 🧭 **La lección del mecanismo 💸, que vale más que el módulo `csv`:** una deuda técnica
> intencional no es un atajo. Es un atajo **con tres cosas escritas**: qué sería lo correcto, por
> qué no se hace ahora, y en qué momento se paga. Sin esas tres, no es una deuda: es un error que
> todavía no ha dado la cara.

### 5.2 El valor, que no siempre es un número

Tres sedes escriben el valor de tres maneras y el consolidado tiene que aceptar las tres:

```python
import re
from decimal import Decimal, InvalidOperation

# Zipaquirá transcribe del cuaderno con separador de miles: '890.000'.
# El Google Sheet trae notas dentro de la celda: '180000 (pendiente confirmar)'.
NOTE = re.compile(r"\s*\(.*\)\s*$")


def parse_amount(raw: str) -> Decimal:
    """Convierte el valor a Decimal, aceptando las tres formas de las sedes.

    Levanta:
        InvalidRow: si después de limpiar sigue sin ser un número.
    """
    cleaned = NOTE.sub("", raw).strip()

    # El punto como separador de miles, que es la convención colombiana.
    # Se quita solo cuando NO hay decimales: '890.000' es ochocientos noventa mil.
    if cleaned.count(".") == 1 and len(cleaned.rsplit(".", 1)[1]) == 3:
        cleaned = cleaned.replace(".", "")

    try:
        return Decimal(cleaned)
    except InvalidOperation:
        raise InvalidRow(0, "valor", f"no es un número: {raw!r}") from None
```

**Detalles con intención**

- **La heurística del punto está acotada y declarada.** `890.000` es ochocientos noventa mil;
  `890.00` serían ochocientos noventa con centavos. La regla —un punto, tres dígitos detrás— cubre
  el caso de Áurea y **va a fallar** con `1.500` si alguna vez significara mil quinientos con
  centavos. Está escrito porque una heurística silenciosa es una bomba.
- **La nota se borra, no se ignora.** El ejercicio 9 pregunta si borrarla es correcto: una nota que
  dice *"pendiente confirmar"* es información de negocio, y tirarla es una decisión que alguien
  debería tomar a conciencia.
- **Y a la salida, el dinero con dos decimales siempre.** `Decimal("150000")` se escribe
  `150000`, y el mismo monto calculado se escribe `150000.00`: dos archivos con el mismo valor que no
  se comparan como texto. Se fija con `quantize(Decimal("0.01"))` antes de escribir. El formato
  colombiano para una persona —`1.234.567,50`— no sale de `locale`, que depende de la máquina
  (Fase 01, ejercicio 13), sino de `f"{monto:,.2f}".translate(str.maketrans(",.", ".,"))`.
- **El archivo del trimestre de la Fase 02 no tiene la columna `descripcion`**, y es a propósito:
  aquel generador produce citas y este, procedimientos facturables. Son dos esquemas distintos y
  no se cruzan.

### 5.3 La configuración deja de ser código

En la Fase 03 las tarifas de los aliados eran un diccionario en Python, y la fase prometió que la
06 las sacaría de ahí. Aquí está:

```toml
# tarifas.toml — lo edita Patricia, no requiere tocar código.
# Vigente desde el 1 de enero de 2026.

[general]
vigente_desde = 2026-01-01          # TOML tiene tipo fecha nativo, sin comillas
moneda = "COP"

[aliados]
P001 = 0.15
P002 = 0.12
P003 = 0.20
P004 = 0.10
P005 = 0.18
P006 = 0.10

[reglas_especiales]
P004 = { tipo = "minimo_por_caso", valor = 150000 }
P005 = { tipo = "tope_mensual", valor = 2000000 }
P006 = { tipo = "por_especialidad", implantologia = 0.20, endodoncia = 0.12 }
```

```python
import tomllib
from decimal import Decimal
from pathlib import Path


def load_rates(path: Path = Path("tarifas.toml")) -> dict[str, Decimal]:
    """Lee las tarifas del archivo de configuración.

    tomllib abre en binario ('rb') y no en texto: el formato define su propio
    encoding (UTF-8 siempre), así que no hay nada que adivinar.
    """
    with path.open("rb") as file:
        config = tomllib.load(file)
    # str() antes de Decimal: tomllib devuelve float para 0.15, y construir un
    # Decimal desde un float arrastra el error de representación (Fase 01).
    return {partner: Decimal(str(rate)) for partner, rate in config["aliados"].items()}
```

**Detalles con intención**

- **`Decimal(str(rate))` y no `Decimal(rate)`.** TOML no tiene tipo decimal, así que `0.15` llega
  como `float`. `Decimal(0.15)` da `0.1499999999999999944488848768742172978818416595458984375`;
  `Decimal(str(0.15))` da `0.15`. Sobre una liquidación de cuarenta millones eso es plata.
- **`"rb"`, en binario.** `tomllib.load` lo exige y la razón es buena: el formato TOML **define**
  que es UTF-8, así que dejar que Python adivine el encoding sería peor.
- **Y ahora la promesa de la Fase 03 se cumple:** agregar el aliado veinticuatro es una línea en un
  archivo de texto que puede editar Patricia. Cero código, cero commit, cero despliegue.

### 5.4 El histórico, en `sqlite3`

Patricia necesita responder *"¿esto ya lo facturamos el mes pasado?"* — la regla 6 del validador
de la Fase 04, pero contra el histórico en vez de contra el lote.

```python
import sqlite3
from pathlib import Path

SCHEMA = """
CREATE TABLE IF NOT EXISTS billed (
    document    TEXT    NOT NULL,
    code        TEXT    NOT NULL,
    date        TEXT    NOT NULL,
    branch      TEXT    NOT NULL,
    amount      TEXT    NOT NULL,   -- TEXT: sqlite no tiene DECIMAL, y el dinero no es float
    batch       TEXT    NOT NULL,   -- de qué cierre salió: '2026-03'
    PRIMARY KEY (document, code, date)
);
CREATE INDEX IF NOT EXISTS idx_billed_batch ON billed(batch);
"""


def open_history(path: Path = Path("data/historico.sqlite3")) -> sqlite3.Connection:
    """Abre el histórico, creándolo si no existe."""
    connection = sqlite3.connect(path)
    connection.executescript(SCHEMA)
    return connection


def already_billed(connection, document: str, code: str, date: str) -> bool:
    """¿Este procedimiento ya se facturó? La consulta que Patricia hacía a ojo."""
    # Parámetros con ?, nunca concatenación: es el PreparedStatement de siempre,
    # y la inyección de SQL funciona igual aquí que en cualquier otro lado.
    row = connection.execute(
        "SELECT batch FROM billed WHERE document = ? AND code = ? AND date = ?",
        (document, code, date),
    ).fetchone()
    return row is not None


def record_batch(connection, rows, batch: str) -> int:
    """Registra el cierre completo. Todo o nada."""
    with connection:          # ← hace COMMIT al salir bien, ROLLBACK si lanza
        cursor = connection.executemany(
            "INSERT OR IGNORE INTO billed VALUES (?, ?, ?, ?, ?, ?)",
            ((r.document, r.code, r.date, r.branch, str(r.amount), batch) for r in rows),
        )
        return cursor.rowcount
```

**Detalles con intención**

- **El dinero se guarda como `TEXT`.** SQLite no tiene tipo decimal: guardar `Decimal` como `REAL`
  lo convierte en `float` y se pierde exactitud. Guardarlo como texto y reconstruirlo con
  `Decimal(row["amount"])` conserva el valor exacto. Es feo y es correcto, y es una decisión que
  vas a tener que defender en alguna revisión.
- **`PRIMARY KEY (document, code, date)`** convierte la regla de negocio de la Fase 04 —no puede
  haber dos procedimientos iguales el mismo día— en una **restricción del almacén**. Es más barato
  y más confiable que comprobarlo en código, y es el mismo argumento que la Fase 11 va a hacer con
  Postgres.
- **`INSERT OR IGNORE`** para que reprocesar el mismo cierre no falle ni duplique. El cierre de
  mes se corre más de una vez; asumir lo contrario es cómo se producen los duplicados.
- **`executemany` con un generador**, no con una lista: Fase 02, y aquí importa porque son miles
  de filas.

> ⚠️ **`with connection:` NO cierra la conexión**, que es la trampa que más gente comete viniendo
> de `try-with-resources`. Hace `COMMIT` al salir bien y `ROLLBACK` si el bloque lanza — que es
> muy útil— pero la conexión sigue abierta. Para cerrarla hay que llamar a `close()`, o envolverla
> en `contextlib.closing` (Fase 04).

**Prueba de fuego**

```bash
python aur_cli.py consolidar data/cierre/ --mes 2026-03
```

```text
✅ 6.271 filas consolidadas de 10 sedes
   · 6 exports latin-1 con separador ';'
   · 1 con BOM de Excel
   · 1 con las columnas en otro orden
   · 2 con el valor en formato libre
   · 18 filas ya estaban en el histórico: se omitieron
```

Y la mentira que te va a contar la salida si miras el lugar equivocado: **el total de filas**. Si
el consolidado suma 6.271 y las sedes reportaron 6.271, todo parece bien — pero si una fila se
partió mal por una coma, el total de filas es correcto y el **total facturado** no. Compara siempre
el dinero, no el conteo: `SELECT SUM(CAST(amount AS DECIMAL))` contra lo que dice cada sede.

---

## 📏 6. Medición — releer los CSV contra tener un índice

**Hipótesis.** Responder *"¿esto ya se facturó?"* releyendo los CSV históricos funciona mientras el
histórico sea pequeño, y deja de ser razonable mucho antes de lo que uno supone. Un `sqlite3` con
índice cuesta más disco y cambia la escala del problema.

**Condiciones.** CPython 3.14.5 · macOS 26.6 · Apple Silicon · el histórico simulado con 1, 6 y 24
meses de las diez sedes —6.000 filas por mes— con semilla fija · 50 consultas de pertenencia por
corrida, tomadas al azar del propio histórico · mediana de 3 repeticiones con `bench.py` · el
índice es `(document, code, date)`, exactamente el de la consulta.

**Competidores.** El CSV **en su mejor versión**, que importa: las 50 consultas se resuelven en
**una sola pasada** por los archivos, con un `set` de llaves buscadas (Fase 01 §6). Sería trivial
hacer que el competidor releyera el archivo una vez por consulta y obtener una ventaja de 50×
falsa; esta comparación no hace eso.

**Resultado.**

| Histórico | Filas | Releer CSV | `sqlite3` con índice | Disco CSV | Disco `.sqlite3` |
|---|---|---|---|---|---|
| 1 mes | 6.000 | 3.0 ms | **0.30 ms** | 0.2 MB | 0.4 MB |
| 6 meses | 36.000 | 18.8 ms | **0.37 ms** | 1.2 MB | 2.6 MB |
| 24 meses | 144.000 | 70.6 ms | **0.28 ms** | 5.0 MB | 10.6 MB |

> ⚖️ **Veredicto.** Con un mes de histórico, releer los CSV cuesta 3 ms y **no hay ningún
> problema que resolver**: montar SQLite ahí sería ceremonia. Con dos años, el CSV cuesta 70.6 ms
> y SQLite 0.28 ms — **252 veces menos**— y la diferencia crece linealmente porque el CSV recorre
> todo el histórico mientras el índice no.
>
> **Lo que de verdad decide no es el factor, es la forma de la curva.** El tiempo de SQLite es
> **plano**: 0.30, 0.37 y 0.28 ms, que es ruido de medición. El del CSV se duplica cuando se
> duplica el histórico. Un sistema cuyo tiempo de respuesta crece con la edad de la empresa es un
> sistema que va a fallar, y la única pregunta es cuándo.
>
> **El costo, dicho sin adornos: el doble de disco.** 10.6 MB contra 5.0 MB para los mismos datos,
> y la mayor parte de esa diferencia es el índice. También cuesta que ahora hay un archivo binario
> que Patricia no puede abrir en Excel — y eso no es un detalle menor en Áurea, donde la
> capacidad de "abrir el archivo y mirar" es lo que hace que la herramienta se use.
>
> **El umbral, que es la respuesta útil:** por debajo de unas **20.000 filas** —tres meses de
> Áurea— el CSV está bien y el `sqlite3` es complejidad sin pago. Por encima de cien mil, el CSV
> es insostenible. Y hay un segundo umbral que no es de tamaño sino de forma: **en el momento en
> que necesites una consulta que no sea "recórrelo todo"** —agrupar, ordenar, unir con otra tabla—
> el CSV pierde aunque sea pequeño, porque eso hay que escribirlo a mano y la base de datos ya lo
> sabe hacer.

**Lo que no se midió:** el costo de **construir** la base (una pasada completa sobre los CSV, que
se paga una vez por cierre), la escritura concurrente —SQLite tiene un bloqueo de escritor único, y
eso es la Fase 14—, y el comportamiento con el archivo en un disco de red, donde SQLite se
comporta mal y está documentado que no debe usarse así.

---

## 🧱 7. Miniproyecto — *El consolidador con memoria*

**El encargo**

Patricia, el primer día hábil del mes: *"Ya me llegaron los diez archivos. Seis son el export de
siempre, dos me los manda el otro programa con las columnas al revés, uno es un Excel que yo misma
exporto, y el de Zipaquirá lo transcribo yo del cuaderno. Me toca abrirlos uno por uno y pegarlos
en una hoja. Y lo peor: el mes pasado facturé dos veces tres procedimientos porque la sede me los
mandó repetidos en dos archivos, y me tocó hacer una nota crédito."*

Escribe el consolidador del cierre: lee los diez, los normaliza, detecta lo que ya se facturó
antes, y produce el consolidado del mes con su histórico.

**Por qué duele**

Porque los diez archivos son **seis formatos distintos** y ninguno está mal: cada sistema exporta
como sabe. Y porque la detección de lo ya facturado necesita memoria entre corridas, que es
exactamente lo que un script no tiene — hasta hoy.

**Datos de entrada**

Los diez exports del cierre, que genera este script con la suciedad real del dominio:

```python
"""Genera los exports del cierre de mes de las diez sedes, cada uno con su suciedad.

Uso:  python generar_exports_sucios.py
Produce data/cierre/ con seis formatos distintos, como llegan de verdad.
"""

import csv
import random
from pathlib import Path

BRANCHES = ["Centro", "Chapinero", "Suba", "Kennedy", "Usaquen",
            "Engativa", "Fontibon", "Restrepo", "Soacha", "Zipaquira"]
CODES = {"D8010": 180000, "D8020": 95000, "D2740": 890000,
         "D7140": 210000, "D1110": 75000, "D8670": 120000}
DESCRIPTIONS = {
    "D8010": "Control de ortodoncia, arco superior",
    "D8020": "Cambio de ligaduras",
    "D2740": "Corona en zirconio, cara vestibular, tono A2",
    "D7140": "Exodoncia simple",
    "D1110": "Profilaxis",
    "D8670": 'Retenedor fijo 3x3, "tipo Hawley"',
}
FIRST = ["Ana María", "Carlos Efrén", "Luz Dary", "Jhon Fredy", "Diana Marcela",
         "Óscar Iván", "Yenny Paola", "Wílmer Andrés", "Sandra Milena", "José Ángel"]
LAST = ["Robledo", "Neira", "Peña", "Chaparro", "Ocampo", "Guzmán", "Rojas",
        "Buitrago", "Cárdenas", "Quintero", "Mahecha", "Bermúdez"]

FIELDS = ["documento", "paciente", "sede", "fecha", "codigo", "descripcion", "valor"]


def rows_for(branch, count, rng):
    for _ in range(count):
        code = rng.choice(list(CODES))
        yield {
            "documento": str(rng.randint(10_000_000, 1_299_999_999)),
            # La coma dentro del nombre: esto es lo que rompe el script de la Fase 01.
            "paciente": f"{rng.choice(LAST)}, {rng.choice(FIRST)}",
            "sede": branch,
            "fecha": f"2026-03-{rng.randint(1, 31):02d}",
            "codigo": code,
            "descripcion": DESCRIPTIONS[code],
            "valor": str(CODES[code]),
        }


def main() -> None:
    rng = random.Random(2026)
    out = Path("data/cierre")
    out.mkdir(parents=True, exist_ok=True)

    for index, branch in enumerate(BRANCHES):
        rows = list(rows_for(branch, rng.randint(550, 700), rng))
        path = out / f"{branch.lower()}.csv"

        if index < 6:
            # Las seis sedes con Odontovía: latin-1, separado por punto y coma.
            with path.open("w", encoding="latin-1", newline="") as file:
                writer = csv.DictWriter(file, FIELDS, delimiter=";")
                writer.writeheader()
                writer.writerows(rows)
        elif index == 6:
            # La que exporta desde Excel: UTF-8 con BOM.
            with path.open("w", encoding="utf-8-sig", newline="") as file:
                writer = csv.DictWriter(file, FIELDS)
                writer.writeheader()
                writer.writerows(rows)
        elif index == 7:
            # El otro software: las columnas en otro orden.
            order = ["fecha", "sede", "documento", "valor", "codigo", "paciente", "descripcion"]
            with path.open("w", encoding="utf-8", newline="") as file:
                writer = csv.DictWriter(file, order)
                writer.writeheader()
                writer.writerows(rows)
        elif index == 8:
            # El Google Sheet: notas dentro de la celda de valor.
            for row in rows[::37]:
                row["valor"] = f"{row['valor']} (pendiente confirmar)"
            with path.open("w", encoding="utf-8", newline="") as file:
                writer = csv.DictWriter(file, FIELDS)
                writer.writeheader()
                writer.writerows(rows)
        else:
            # Zipaquirá: el cuaderno transcrito, con separador de miles y tabuladores.
            for row in rows:
                row["valor"] = f"{int(row['valor']):,}".replace(",", ".")
            with path.open("w", encoding="utf-8", newline="") as file:
                writer = csv.DictWriter(file, FIELDS, delimiter="\t")
                writer.writeheader()
                writer.writerows(rows)

        print(f"{path}: {len(rows)} filas")


if __name__ == "__main__":
    main()
```

**Criterios de aceptación**

- [ ] Un solo archivo, `consolidador.py`, biblioteca estándar pura, con `argparse`.
- [ ] Lee los diez exports **detectando o declarando** el formato de cada uno, y produce un
      consolidado único y normalizado.
- [ ] Ningún nombre de paciente sale partido. Compruébalo buscando el nombre con coma en la
      salida.
- [ ] Guarda el cierre en `sqlite3` y, al correrlo dos veces, **la segunda no duplica nada** y lo
      reporta.
- [ ] Responde *"¿este procedimiento ya se facturó?"* contra el histórico, y el consolidado excluye
      lo ya facturado con un reporte de qué excluyó y de dónde venía.
- [ ] Produce además un `.zip` con el consolidado en CSV y un `resumen.json` con los totales por
      sede — que es lo que Patricia le manda al contador.
- [ ] **Medición:** filas consolidadas, total facturado, y cuánto tardó. Además, **cuántas filas
      pierde el `split(",")` de la Fase 01** sobre los exports separados por coma, y cuánto dinero
      son. Ese par de números es la factura de la deuda 💸 y va en el mensaje del tag.

**Restricciones de registro**

> Esto es un **script** — el último del Bloque A, y el más grande. Un archivo, stdlib pura,
> `argparse`, `dataclass`, funciones sueltas. Si a estas alturas el archivo te parece que ya no
> cabe en un archivo, **anótalo**: esa sensación es literalmente el tema de la Fase 07, y llevarla
> escrita vale más que cualquier explicación que te dé el material.

**La trampa**

Vas a detectar el encoding probando: intentar UTF-8, y si lanza, probar latin-1. Y **va a
funcionar casi siempre**, que es lo peligroso: latin-1 **nunca falla al decodificar** —cualquier
byte es un carácter válido en latin-1— así que si lo pruebas primero, o si tu fallback es él, vas
a leer archivos UTF-8 como latin-1 sin que nada lance, y los nombres van a salir con `Ã¡` en vez de
`á`. Silencioso, otra vez.

Y la segunda: el archivo de Zipaquirá trae `890.000`. Si tu conversión quita todos los puntos sin
pensar, funciona; pero si alguna sede manda `890.50` con decimales de verdad, acabas de multiplicar
una factura por cien.

**Pistas**

<details><summary>Pista 1 — el enfoque</summary>

Separa **detectar el formato** de **leer el archivo**. Lo primero se hace una vez por archivo y con
información: las primeras líneas en bytes te dicen casi todo —el BOM se ve, el separador se cuenta,
y el encoding se puede intentar en el orden correcto—. Lo segundo ya es el `csv.DictReader` de
siempre.

Y una alternativa perfectamente válida que el enunciado permite: **declarar** el formato de cada
sede en el `tarifas.toml` en vez de detectarlo. Son diez sedes, cambian cada dos años, y una tabla
explícita es más honesta que una heurística. Si eliges ese camino, defiéndelo por escrito.
</details>

<details><summary>Pista 2 — la herramienta</summary>

- [`csv.Sniffer`](https://docs.python.org/3.14/library/csv.html#csv.Sniffer) detecta el dialecto, y
  su documentación advierte que no es infalible. Léela antes de confiar en él.
- El BOM se detecta leyendo los primeros bytes en binario y comparando con
  `codecs.BOM_UTF8`.
- Para el encoding, el orden importa: intenta **UTF-8 primero** y usa latin-1 como último recurso,
  nunca al revés, por la razón de la trampa.
- [`zipfile.ZipFile`](https://docs.python.org/3.14/library/zipfile.html) con `writestr` te evita
  crear archivos temporales.
- Y [`json.dump`](https://docs.python.org/3.14/library/json.html) tiene un detalle: **no sabe
  serializar un `Decimal`**. El parámetro `default=` es la salida, y decidir a qué lo conviertes es
  una decisión de dominio.
</details>

<details><summary>Pista 3 — el esqueleto</summary>

```python
@dataclass(frozen=True, slots=True)
class ExportFormat:
    """Cómo se lee el archivo de una sede."""
    encoding: str
    delimiter: str

def detect_format(path: Path) -> ExportFormat:
    """Mira los primeros bytes. UTF-8 primero; latin-1 al final."""

def read_export(path: Path, fmt: ExportFormat) -> Iterator[Row]:
    """csv.DictReader, con las columnas mapeadas por nombre y no por posición."""

def consolidate(paths, connection) -> tuple[list[Row], list[Row]]:
    """Devuelve (nuevas, ya_facturadas)."""

def write_package(rows, totals, target: Path) -> None:
    """El .zip con el CSV y el resumen.json."""
```
</details>

**Cómo se entrega**

```bash
python generar_exports_sucios.py
python consolidador.py data/cierre/ --mes 2026-03
python consolidador.py data/cierre/ --mes 2026-03   # otra vez: no debe duplicar
```

```bash
git add consolidador.py generar_exports_sucios.py tarifas.toml
git commit -m "fase 06 mini: consolidador con histórico en sqlite3"
git tag -a mini-06 -m "Mini F6: consolidador · <N> filas, \$<T> facturado, <M> ms · deuda 💸: \$<D> de diferencia entre split y csv"
```

<details><summary>💡 Solución de referencia — las tres decisiones</summary>

**La decisión de diseño que se tomó.** Detectar el formato en vez de declararlo, con el orden de
intentos fijado: BOM → UTF-8 → latin-1. El otro camino —una tabla en `tarifas.toml` con el formato
de cada sede— es **igual de defendible y en algunos equipos mejor**: es explícito, se audita, y
cuando una sede cambia de sistema alguien tiene que enterarse en vez de que la heurística se
adapte en silencio. Se eligió detectar porque Áurea tiene diez sedes que cambian de software sin
avisar y Patricia no va a editar una tabla; en una empresa con control de cambios, la tabla gana.

**La trampa, entera.** latin-1 decodifica **cualquier** secuencia de bytes sin lanzar, porque cada
uno de los 256 valores posibles es un carácter válido. Eso lo convierte en el fallback perfecto y
en el primer intento catastrófico: probado primero, lee todo, incluido lo que era UTF-8, y produce
mojibake silencioso. El orden no es una preferencia: es la única forma de que la detección
funcione.

Y el separador de miles: la heurística de §5.2 —un punto, exactamente tres dígitos detrás— cubre el
caso de Áurea y está declarada con su límite. La alternativa honesta es **rechazar** el valor
ambiguo y pedirle a la sede que lo corrija, que es lo que haría un sistema serio y lo que Áurea no
puede permitirse el día 3 del mes.

**Qué se habría hecho distinto si el registro fuera otro.** Como herramienta —Bloque B— el formato
de cada sede sería configuración versionada con su fecha de cambio, habría una prueba por formato
con un archivo de ejemplo mínimo, y el histórico tendría migraciones de esquema. Como aplicación,
las sedes no mandarían archivos: publicarían en una API y la validación ocurriría en la frontera
(Fase 10), con lo cual **este miniproyecto entero dejaría de existir**. Ese es el argumento
comercial de AgendaAPI y el del back-office, y conviene tenerlo escrito para el día en que Julián
pregunte por qué construir la API si el consolidador ya funciona.
</details>

---

## 🧪 8. Ejercicios (25)

**🟢 Fácil (1–6)**

1. Lee el export de Centro —latin-1 con `;`— con `csv.DictReader` y comprueba que el nombre con
   coma sale entero. Después léelo con el `split(",")` de la Fase 01 y compara la misma fila.
2. Abre el archivo con BOM como `utf-8` y provoca el `KeyError` sobre `documento`. Imprime
   `repr(list(reader.fieldnames)[0])` para ver el carácter invisible.
3. Escribe un CSV con `csv.writer` que contenga un campo con coma, uno con comillas y uno con
   salto de línea. Ábrelo después y comprueba que vuelve igual.
4. Lee `tarifas.toml` con `tomllib` e imprime el tipo de cada valor. Fíjate en qué tipo tiene
   `vigente_desde`.
5. Crea una base `sqlite3` en memoria (`":memory:"`), inserta cinco filas y consúltalas. Es la
   forma de probar sin tocar el disco, y la Fase 08 la va a usar.
6. Empaqueta el consolidado y el resumen en un `.zip` con `zipfile`, sin crear archivos
   temporales.

**🟡 Intermedio (7–14)**

7. Usa `csv.Sniffer` sobre los diez exports y anota en cuáles acierta y en cuáles no. Lee la
   advertencia de su documentación y explica por qué falla donde falla.
8. Demuestra la trampa de latin-1: lee un archivo UTF-8 como latin-1, muestra el resultado, y
   comprueba que **no lanzó ninguna excepción**.
9. El Google Sheet trae `180000 (pendiente confirmar)`. Decide si esa nota se descarta o se
   conserva, impleméntalo, y escribe en tres líneas a quién habría que preguntarle.
10. Serializa a JSON un diccionario con `Decimal` adentro. Falla; arréglalo con `default=` y decide
    si conviertes a `str` o a `float`. Justifica con lo de la Fase 01.
11. Agrega un índice a la tabla del histórico y mide la consulta antes y después con `bench.py`.
    Después mira el plan con `EXPLAIN QUERY PLAN`.
12. Lee un `.zip` de 50 MB sin descomprimirlo a disco, procesando su CSV en flujo. Mide el pico de
    memoria.
13. Usa `zoneinfo` para convertir una fecha de cita a la zona de Bogotá y explica por qué Áurea
    —que opera en un solo huso— igual necesita esto. (Pista: las plataformas que reportan en
    semanas ISO.)
14. Averigua qué hace `csv.DictReader` cuando una fila tiene más columnas que el encabezado, y
    cuando tiene menos. Pruébalo y decide si ese comportamiento te sirve.

**🟠 Difícil (15–21)**

15. **Diagnóstico.** El consolidado suma $2.4 millones menos que la suma de las sedes. Hay tres
    causas posibles en esta fase —la coma, el separador de miles y la nota en la celda—.
    Reprodúcelas y escribe el comando que diagnostica cada una.
16. **Diagnóstico.** Una sede reporta que "sus filas no aparecen". El archivo existe, tiene datos,
    y el consolidador no lanza nada. Hay dos causas probables, y una de ellas tiene que ver con el
    encabezado. Reprodúcelas.
17. **Medición.** Reproduce la tabla de la sección 6 y encuentra **tu** umbral: ¿a partir de
    cuántas filas releer los CSV deja de ser razonable para tu máquina? Reporta con el arnés.
18. **Medición.** Compara insertar 100.000 filas en `sqlite3` de tres formas: un `execute` por
    fila sin transacción, un `execute` por fila dentro de una transacción, y un `executemany`.
    La diferencia entre la primera y las otras dos te va a sorprender: explícala.
19. **Medición.** Mide leer el archivo del trimestre (482.074 filas, de la Fase 02) con
    `csv.reader` contra `csv.DictReader` contra el `split(",")` original. Reporta tiempo y
    memoria, y decide qué usarías para ese tamaño.
20. **De registro.** El contador pide que el consolidado le llegue "en un Excel de verdad, con
    pestañas por sede". Decide qué implica, en qué registro cae, y qué le responderías sabiendo
    que Excel necesita una dependencia y que el Bloque A no la permite. Hay una respuesta que no
    rompe la regla.
21. **De registro.** Julián quiere que el histórico "lo pueda consultar cualquiera, no solo
    Patricia". Decide el registro. Es la primera vez en el curso que la respuesta correcta es
    claramente "aplicación", y conviene que puedas decir exactamente por qué.

**🔴 Muy difícil (22–25)**

22. **Adversarial.** Construye un CSV que rompa tu consolidador sin que lance ninguna excepción.
    Tienes al menos cuatro caminos: el encoding, el separador de miles, un salto de línea dentro de
    una celda y un encabezado duplicado. Documenta los cuatro con la salida que producen.
23. **Adversarial.** Haz que la base `sqlite3` quede corrupta o inconsistente. Investiga qué pasa
    si dos procesos escriben a la vez, y qué protege realmente el `with connection:`. Documenta lo
    que encontraste; la Fase 14 lo retoma.
24. **Defiende una decisión.** El curso guarda el dinero como `TEXT` en SQLite. Un colega dice que
    eso es horrible y que debería ser `INTEGER` en centavos. **Tiene razón en parte.** Implementa
    las dos, compáralas en exactitud, en tamaño y en qué tan legible queda una consulta de suma, y
    decide.
25. **Diseño.** El histórico tiene dos años y Patricia quiere borrar lo de hace más de cinco por
    política de retención — salvo que la historia clínica tiene retención obligatoria por ley.
    Diseña qué se archiva, qué se borra y qué se conserva, y dónde vive esa decisión en el código.
    Es un problema de dominio antes que de SQL.

**🔥 Opcionales**

- Lee la documentación de `sqlite3` sobre `row_factory` y haz que las consultas devuelvan objetos
  con nombres en vez de tuplas. Compáralo con lo que hace un ORM (Fase 11).
- Investiga el modo WAL de SQLite y qué problema de concurrencia resuelve. La Fase 14 lo vuelve a
  necesitar.
- Genera el consolidado también en formato **RIPS** —los planos delimitados que exige el país— y
  compara lo que cuesta producir un formato posicional contra uno delimitado.

---

## 📚 9. Referencias

**Documentación oficial**

- [`csv`](https://docs.python.org/3.14/library/csv.html) — dialectos, `DictReader`, `Sniffer`, y la
  advertencia sobre `newline=""`.
- [`sqlite3`](https://docs.python.org/3.14/library/sqlite3.html) — la API, las transacciones, y la
  sección de *how-to* sobre tipos adaptados.
- [`tomllib`](https://docs.python.org/3.14/library/tomllib.html) — corto, porque solo lee.
- [`json`](https://docs.python.org/3.14/library/json.html) — y en particular `default=` y los
  límites de lo que serializa.
- [`zipfile`](https://docs.python.org/3.14/library/zipfile.html) — lectura en flujo incluida.
- [`codecs` — encodings estándar](https://docs.python.org/3.14/library/codecs.html#standard-encodings)
  — la lista completa, incluido `utf-8-sig`.
- [Especificación de TOML](https://toml.io/es/) — está traducida al español y se lee en quince
  minutos.

**PEPs**

- [PEP 680](https://peps.python.org/pep-0680/) — `tomllib`, y por qué solo lee.
- [PEP 249](https://peps.python.org/pep-0249/) — la API de bases de datos que `sqlite3` implementa,
  y que es el equivalente conceptual de JDBC. La Fase 11 la usa entera.

**Orden de lectura sugerido.** Antes de escribir: la sección de dialectos de `csv`, que son diez
minutos y explican el 80% de los problemas de esta fase. Durante: `sqlite3`, por función. Después:
el PEP 249, que hace que la Fase 11 empiece con ventaja.

> ⚠️ URLs y contenidos cambian; fija 3.14 en el selector de la documentación.

---

## 🚀 10. Cierre y conexión con la siguiente fase

**Aquí termina el Bloque A**, y conviene mirar atrás un momento porque el recorrido es el argumento
del curso.

Siete fases, **cero dependencias**. Con eso construiste una herramienta que lee seis formatos de
archivo distintos con dos encodings, valida un lote de seis mil filas reportando todos sus errores
de una pasada, invoca a un binario ajeno que se cuelga y sobrevive, calcula un motor de comisiones
con reglas especiales, guarda un histórico consultable con índice, empaqueta su salida en un ZIP y
mide su propio rendimiento. Un dev de Java que llega a Python no tiene forma de saber que todo eso
viene en la caja, y ese desconocimiento es lo que produce el reflejo de la dependencia.

Y pagaste la primera deuda del curso. El `git diff fase-01 fase-06` es la factura, y lo que enseña
no es el módulo `csv`: es que **un atajo declarado, acotado y con fecha de pago es una herramienta
de ingeniería**, mientras que el mismo atajo sin esas tres cosas es un error esperando.

**La señal de que el Bloque A ya no alcanza** también está puesta, y probablemente la sentiste al
escribir el miniproyecto: `aur_cli.py` tiene cuatrocientas líneas y cuatro responsabilidades, lo
usan tres personas, probarlo exige correr el archivo entero, y nadie sabe qué versión tiene
Patricia. Esas son cinco señales concretas, y la **Fase 07** ⭐ —la fase de la tesis del curso— las
nombra una por una y enseña a cruzar la línea **sin reescribir nada**: el archivo se vuelve
paquete, moviendo lo que ya funciona.

> **La señal de que quedó bien:** la próxima vez que alguien proponga agregar una dependencia para
> leer un formato, tu primera pregunta no va a ser cuál biblioteca — va a ser si eso no viene en la
> caja. Y la mitad de las veces vas a tener razón.

> 🏷️ **No cierres la fase sin el tag.** Con el checklist de la sección 2 en verde, el
> miniproyecto corriendo y `git status` limpio:
>
> ```bash
> git tag -a fase-06 -m "F6 cerrada:
> - csv con dialectos y comillas: ningún nombre se parte, y la deuda de la F01 quedó pagada
> - latin-1, BOM y errors= entendidos y declarados; nada se adivina en silencio
> - tarifas.toml: la configuración dejó de ser código
> - histórico en sqlite3 con índice y clave primaria que impide el duplicado
> - el consolidado se empaqueta en zip con su resumen.json
> - Bloque A cerrado: siete fases, cero dependencias"
> ```
>
> Los commits de la fase llevan su prefijo (`fase 06: …`), los de ejercicio su número
> (`fase 06 ej12: …`) y el miniproyecto el suyo (`fase 06 mini: …`). El miniproyecto terminado
> lleva además su tag anotado `mini-06`, y **en el mensaje de ese tag va el número que arrojó su
> medición**. La convención completa está en
> [`00-convencion-de-git-y-tags.md`](00-convencion-de-git-y-tags.md).
