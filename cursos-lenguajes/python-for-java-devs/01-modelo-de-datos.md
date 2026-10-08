# 🧬 Fase 01 — El modelo de datos

> Python para desarrolladores Java senior · Fase 1 de 18 · Bloque A
> Depende de: Fase 00 · Habilita: Fase 02
> Registro de esta fase: **script** — un archivo, stdlib pura, sin clases
> Proyecto que avanza: **nace el CLI de Patricia** (`aur_cli.py`)
> Fecha de verificación de las versiones: 12/09/2026

---

## 🎯 1. Propósito

Recalibrar qué es un valor en Python, que es donde este perfil arrastra los errores más
silenciosos: los que no revientan, no aparecen en ninguna traza, y se descubren tres meses
después cuando un franquiciado revisa una liquidación.

No es una fase de sintaxis. Es la fase donde decides, con conocimiento de causa, **qué hace que
dos registros del mismo paciente sean el mismo paciente** — que es una pregunta de diseño, no de
lenguaje, pero que en Python se responde tocando cosas (`__eq__`, `__hash__`, mutabilidad) que
en Java resolvías con un `record` y el generador del IDE.

Y es donde nace el CLI de Patricia: cuarenta líneas que van a seguir vivas dieciséis fases
después.

---

## ✅ 2. Qué queda listo al terminar

- [ ] Puedes explicar, sin metáforas, qué pasa en memoria cuando escribes `b = a` y qué pasa
      cuando escribes `b = a[:]`.
- [ ] Sabes cuándo `is` es correcto y cuándo es un error que funciona por accidente, y puedes
      demostrar el accidente con dos líneas.
- [ ] Reconoces el argumento por defecto mutable en código ajeno a primera vista y sabes por qué
      el lenguaje se comporta así.
- [ ] `aur_cli.py` existe, corre sobre el export de una sede y produce el resumen del mes.
- [ ] Su deuda 💸 está escrita en el propio archivo, con la fase donde se paga.
- [ ] Puedes decir, con el número de la sección 6 delante, por qué `documento in pacientes` es
      una decisión de diseño y no un detalle.
- [ ] El miniproyecto de la sección 7 corre y cumple sus criterios de aceptación.

---

## 🚫 3. Qué NO entra todavía

- **Clases propias, `dataclass` y `Protocol`** → Fase 03. Esta fase trabaja con tuplas y
  diccionarios a propósito, y en la 03 vas a ver qué gana y qué pierde el cambio.
- **Manejo de errores** → Fase 04. Aquí los errores revientan el proceso con su traza, que para
  un script es una decisión defendible y no un descuido.
- **`argparse`** → Fase 05. El CLI lee `sys.argv` a mano, que para dos argumentos es
  perfectamente razonable y para seis deja de serlo. Vas a sentir exactamente cuándo.
- **El módulo `csv`** → Fase 06, y esa espera es deliberada: es la deuda 💸 de esta fase.
- **Generadores y procesamiento perezoso** → Fase 02. Hoy cargamos el archivo completo en una
  lista, que con el export de una sede está bien y con el del trimestre no.

---

## 🧠 4. Concepto mínimo

### Todo es objeto, y las variables son etiquetas

En Java tienes primitivos y referencias, y la diferencia te importa todos los días: `int` contra
`Integer`, el *autoboxing*, `==` que compara valores para uno y referencias para el otro.

En Python esa distinción no existe: **todo es un objeto**, incluidos los enteros, los booleanos,
las funciones y las clases. Y una variable no es una caja que contiene un valor: es una
**etiqueta pegada a un objeto**. Asignar no copia nada; pega otra etiqueta al mismo objeto.

```python
a = [1, 2, 3]
b = a           # no hay copia: dos etiquetas, un objeto
b.append(4)
print(a)        # [1, 2, 3, 4]
```

Hasta aquí el paralelo con las referencias de Java funciona, y funciona bien. **Dónde se
rompe:** en Java sabes qué es mutable porque lo dice el tipo, y buena parte de tu instinto está
calibrado sobre tipos que no mutan —`String`, los *wrappers*, los `record`, todo lo que devuelve
`List.of()`—. En Python la línea pasa por otro lado y hay que aprendérsela, porque no está en la
sintaxis:

- **Inmutables:** `int`, `float`, `str`, `bool`, `bytes`, `tuple`, `frozenset`, `None`.
- **Mutables:** `list`, `dict`, `set`, `bytearray`, y todo objeto que definas tú salvo que te
  esfuerces.

La consecuencia práctica es que `str` y `tuple` se comportan como esperas —una cadena nunca
cambia bajo tus pies— y que `list` y `dict` viajan por tu programa como referencias vivas que
cualquiera puede modificar. Un diccionario que pasas a una función puede volver distinto, y
nada en la firma te lo advierte.

### Quién puede ser llave

De la mutabilidad sale una regla que en Java conoces como *"si mutas un objeto después de usarlo
como llave de un `HashMap`, lo perdiste"*, y que Python convierte en algo más estricto: **los
objetos mutables no pueden ser llaves**.

```python
{("Chapinero", "2026-03"): 41}   # ✅ tupla: inmutable, hashable
{["Chapinero", "2026-03"]: 41}   # ❌ TypeError: unhashable type: 'list'
```

Esto es mejor de lo que parece. Java te deja meter un `ArrayList` mutable en un `HashSet` y
convertirlo en basura silenciosa; Python te lo prohíbe en el sitio. Y te da una herramienta
gratis: **la llave compuesta es una tupla**, sin `Pair`, sin `record` y sin `equals`/`hashCode`
escritos a mano. `by_branch[("Chapinero", "2026-03")]` es idiomático y es lo que vas a usar todo
el curso.

### Tu instinto de Java dice… y esta vez se equivoca

Esta fase tiene dos reflejos, y los dos cuestan dinero real en Áurea.

#### Primera mitad: `is` no es `==`, y está al revés de lo que crees

En Java el reflejo está tallado a fuego: `==` compara referencias, `equals` compara contenido, y
usar `==` con cadenas es el error clásico de la primera entrevista de trabajo. Ese reflejo, traído
aquí, produce esto:

```python
# ❌ Lo que escribe alguien que viene de Java, "para comparar bien"
if branch is "Chapinero":
    ...
```

Y lo peor que puede pasar es que **funcione**. En Python, `==` es la comparación por contenido
—la que en Java sería `equals`— e `is` compara identidad, que es la que en Java hace `==`. Está
exactamente al revés, y el código de arriba puede dar `True` porque el intérprete reutiliza
cadenas literales cortas. Deja de darlo en cuanto la cadena viene de un archivo:

```python
branch = "Chapi" + "nero"     # el intérprete lo resuelve al compilar
branch is "Chapinero"         # True  ← y aquí es donde te confías

branch = input()              # o una línea leída de un CSV
branch is "Chapinero"         # False ← el mismo texto, otro objeto
branch == "Chapinero"         # True  ← lo que querías preguntar
```

El caso famoso son los enteros, y conviene verlo una vez para no olvidarlo:

```python
a, b = 256, 256
a is b        # True  — CPython precrea los enteros de -5 a 256
a, b = 257, 257
a is b        # False — a partir de 257 son objetos distintos
```

> ⚠️ **Ese comportamiento es un detalle de implementación de CPython, no una promesa del
> lenguaje.** No escribas nada que dependa de él, y desconfía de cualquier explicación que lo
> presente como una regla: en otro intérprete, o en otra versión, puede cambiar.

**La regla, corta:** `is` se usa para `None`, `True` y `False`, y para preguntar literalmente
*"¿es este mismo objeto?"*. Para todo lo demás, `==`. `if value is None` es la forma canónica y
la que verás en todo el código del ecosistema; `if value == None` funciona pero delata a alguien
que no entendió la diferencia, y `ruff` te lo marca.

#### Segunda mitad, la cara: *"copio la lista para no modificar la original"*

Este es el que cuesta dinero. En Áurea, concretamente, cuesta una liquidación mal repartida.

El reflejo viene de `new ArrayList<>(original)`, que en Java hace lo que esperas casi siempre
porque lo que contiene esa lista suele ser inmutable. Traído aquí:

```python
# Las filas del export vienen como listas: [documento, paciente, sede, fecha, código, valor]
original = [["1019", "Ana", "Centro", "2026-03-04", "D8010", "180000"]]

copia = original[:]            # "copio la lista para no tocar la original"
copia[0][4] = "D0000"          # y cambio algo en mi copia

print(original[0][4])          # 'D0000'  ← también cambió el original
```

La copia es **superficial**: copió la lista externa, y los elementos de adentro son los mismos
objetos. Tienes dos listas y un solo conjunto de filas. En Java te pasaría exactamente lo mismo
con una lista de objetos mutables — la diferencia es que allá rara vez tienes listas de cosas
mutables, y aquí es la forma por defecto de representar un registro hasta que llegue la Fase 03.

Las tres salidas, con su costo:

```python
import copy

superficial = original[:]                 # o list(original) — copia el contenedor
profunda = copy.deepcopy(original)        # copia todo el árbol: correcto y caro
inmutable = [tuple(row) for row in original]   # lo que de verdad quieres casi siempre
```

**Qué se escribe en su lugar**, y es la lección transferible de esta fase: en vez de defenderte
copiando, **haz que el dato no se pueda modificar**. Una tupla no necesita copia defensiva. Es
el mismo argumento que ya te sabes a favor de los objetos inmutables, solo que aquí el lenguaje
te da menos ayuda por defecto y la decisión es tuya, fila por fila.

#### La trampa que se cae sola: el argumento por defecto mutable

```python
# ❌ Parece razonable y es el bug más famoso del lenguaje
def add_appointment(appointment, batch=[]):
    batch.append(appointment)
    return batch

add_appointment("cita 1")    # ['cita 1']
add_appointment("cita 2")    # ['cita 1', 'cita 2']  ← ¿de dónde salió la primera?
```

El valor por defecto **se evalúa una vez, cuando se define la función**, no en cada llamada. Esa
lista es un objeto que vive pegado a la función para siempre, y todas las llamadas comparten la
misma. Es el equivalente exacto de un campo `static` que no sabías que habías declarado.

```python
# ✅ La forma canónica, y la vas a ver en todo el código del ecosistema
def add_appointment(appointment, batch=None):
    if batch is None:      # y aquí `is` sí es lo correcto
        batch = []
    batch.append(appointment)
    return batch
```

`ruff` lo marca con la regla `B006` si configuraste `B` en la Fase 00 — compruébalo, porque es la
primera vez que el linter te va a salvar de algo serio.

### Esto sí funciona igual

Mucho más de lo que este arranque sugiere.

**Tu criterio sobre igualdad de dominio se transfiere entero.** La pregunta *"¿qué campos hacen
que dos registros sean la misma entidad?"* es la misma que ya te haces al escribir `equals`, y
la respuesta sigue siendo de negocio y no de lenguaje. Lo único que cambia es cómo se expresa.

**El contrato entre igualdad y hash es idéntico.** Si dos objetos son iguales, sus hashes tienen
que coincidir; si mutas lo que usaste como llave, rompiste el diccionario. Es la misma regla de
`equals`/`hashCode`, palabra por palabra, y por las mismas razones.

**La aritmética de dinero.** Todo lo que sabes sobre no usar `double` para plata vale idéntico
aquí: `float` es el mismo IEEE 754 de siempre, con los mismos errores de representación, y
`Decimal` es el equivalente directo de `BigDecimal`, incluido que hay que construirlo desde una
cadena y no desde un flotante. `Decimal("0.1") * 3` da exactamente `0.3`; `0.1 * 3` no.

**Y las estructuras de datos.** `list` es `ArrayList`, `dict` es `LinkedHashMap` —ordenado por
inserción y garantizado por el lenguaje desde 3.7—, `set` es `HashSet`, `tuple` es lo más
parecido a un `record` sin nombres. Las complejidades son las que esperas, y la medición de la
sección 6 lo confirma con números.

### Diccionario de traducción

| Java | Python | Dónde se rompe el paralelo |
|---|---|---|
| `==` sobre referencias | `is` | `is` casi nunca es lo que quieres: úsalo solo con `None`, `True`, `False` |
| `.equals()` | `==` | Es el operador por defecto, y `==` sobre objetos sin `__eq__` cae en identidad |
| `hashCode()` | `__hash__` | Los mutables simplemente no lo tienen, así que el error es en tiempo de inserción y no silencioso |
| `null` | `None` | Es un objeto único y con tipo (`NoneType`), no la ausencia de valor. Se compara con `is` |
| `Optional<T>` | `T \| None` | Una anotación, no un envoltorio: no hay `.map()` ni `.orElse()`, y nadie la verifica hasta la Fase 08 |
| `record Point(int x, int y)` | `tuple` hoy, `dataclass` desde la Fase 03 | La tupla no tiene nombres de campo: legible con dos elementos, ilegible con siete |
| `List.of(...)` inmutable | `tuple` | No hay versión inmutable de `dict` en la caja; hay `frozenset` para conjuntos |
| `new ArrayList<>(otra)` | `lista[:]` o `list(otra)` | Las dos son superficiales; la diferencia es que aquí lo de adentro suele ser mutable |
| `BigDecimal` | `decimal.Decimal` | Igual de estricto, y con el mismo requisito de construirlo desde texto |
| `if (s != null && !s.isEmpty())` | `if s:` | La verdad es una propiedad de todo objeto: `0`, `""`, `[]`, `{}` y `None` son falsos. Cómodo y peligroso |
| `Map.Entry<K,V>` | una tupla `(k, v)` | `for k, v in d.items()` desempaqueta sola, sin `getKey()` |

> 📝 **Nota de ecosistema — `dict` ordenado.** Hasta 3.6 los diccionarios no garantizaban orden,
> y montones de código y de respuestas de internet siguen escritos bajo ese supuesto. Desde 3.7
> **el orden de inserción es parte del lenguaje**, no un detalle de implementación. Si encuentras
> un `OrderedDict` en código nuevo, casi siempre sobra; en código viejo, no estaba mal — hacía
> falta. `OrderedDict` todavía tiene un par de usos legítimos (`move_to_end` y una igualdad que
> sí mira el orden), y fuera de eso es historia.

### La verdad de los objetos, y dónde muerde

Cualquier objeto se puede evaluar como condición, y hay una tabla corta que hay que saberse:
son falsos `None`, `False`, `0`, `0.0`, `Decimal("0")`, `""`, `[]`, `{}`, `set()` y `()`. Todo
lo demás es verdadero.

Eso hace que `if rows:` sea idiomático y legible. Y hace que esto sea un error de negocio:

```python
# ❌ El descuento de 0 pesos y "no hay descuento" no son lo mismo,
#    y este código los trata igual.
if discount:
    apply(discount)

# ✅ Si la ausencia significa algo distinto de cero, se pregunta por la ausencia.
if discount is not None:
    apply(discount)
```

En Áurea eso es literal: un plan con `discount = Decimal("0")` es un plan al que se le aplicó la
política de descuento y resultó cero; un plan con `discount = None` es uno que nadie ha
revisado. Distinguirlos es la diferencia entre una glosa y una llamada de Clara.

---

## 💻 5. Código mínimo con comentarios

### 5.1 Los datos: el export de una sede

Odontovía exporta un plano delimitado por comas, sin comillas, con esta forma — y estas seis
columnas son el formato que el curso va a usar todo el Bloque A:

```text
documento,paciente,sede,fecha,codigo,valor
1019283746,Ana María Robledo,Centro,2026-03-04,D8010,180000
52847193,Carlos Efrén Neira,Centro,2026-03-04,D2740,890000
1019283746,Ana María Robledo,Centro,2026-03-18,D8020,95000
79541226,Luz Dary Peña,Centro,2026-03-19,D8010,180000
```

Guárdalo como `data/centro-2026-03.csv`. Es un fragmento de verdad: seis columnas, sin comillas,
con tildes, y con el valor en pesos sin separadores ni decimales.

### 5.2 Nace `aur_cli.py`

```python
"""aur — la caja de herramientas de Patricia.

Fase 01: lee el export de una sede y produce el resumen del mes.

Uso:
    python aur_cli.py resumen data/centro-2026-03.csv
"""

import sys
from decimal import Decimal

# El orden de las columnas del export de Odontovía. Es un contrato con un sistema
# que no controlamos, así que se declara arriba y se toca en un solo lugar.
DOCUMENT, PATIENT, BRANCH, DATE, CODE, AMOUNT = range(6)


def read_rows(path):
    """Lee el export y devuelve la lista de filas, cada una como tupla.

    💸 DEUDA INTENCIONAL — se paga en la Fase 06.
    Partir por comas a mano funciona con este archivo y va a fallar con el primer
    nombre o descripción que traiga una coma adentro ("Robledo, Ana María"), con
    las comillas que pone Excel al exportar, y con el BOM del export de Zipaquirá.
    Lo correcto es el módulo `csv` de la biblioteca estándar, que ya resuelve las
    tres cosas. Se deja así a propósito para que la Fase 06 pueda cobrar la factura
    con un `git diff fase-01 fase-06`.
    """
    rows = []
    with open(path, encoding="utf-8") as file:
        next(file)  # el encabezado
        for line in file:
            line = line.strip()
            if not line:  # el export de Odontovía termina con una línea vacía
                continue
            # Las filas son tuplas y no listas: nadie las va a modificar, y así
            # nadie puede. Es la lección de la sección 4 aplicada al primer archivo.
            rows.append(tuple(line.split(",")))
    return rows


def summarize(rows):
    """Resumen del mes: cuántos procedimientos, cuánto se facturó y a cuántos pacientes.

    Devuelve un diccionario porque todavía no hay clases (llegan en la Fase 03).
    """
    total = Decimal("0")
    patients = set()  # un conjunto, y la sección 6 explica por qué importa
    by_code = {}

    for row in rows:
        # Decimal se construye desde texto. Decimal(float) arrastra el error del
        # flotante y en una liquidación de regalías eso termina en una discusión.
        amount = Decimal(row[AMOUNT])
        total += amount
        patients.add(row[DOCUMENT])
        by_code[row[CODE]] = by_code.get(row[CODE], Decimal("0")) + amount

    return {
        "procedimientos": len(rows),
        "pacientes": len(patients),
        "total": total,
        "por_codigo": by_code,
    }


def render(summary, path):
    """La salida que ve Patricia. En español, alineada, pegable en un correo."""
    lines = [
        f"Resumen de {path}",
        f"  procedimientos: {summary['procedimientos']}",
        f"  pacientes distintos: {summary['pacientes']}",
        f"  facturado: ${summary['total']:,.0f}",
        "  por código:",
    ]
    # sorted sobre los ítems ordena por la primera posición de la tupla: el código.
    for code, amount in sorted(summary["por_codigo"].items()):
        lines.append(f"    {code}  ${amount:>12,.0f}")
    return "\n".join(lines)


if __name__ == "__main__":
    # sys.argv[0] es el nombre del script. argparse llega en la Fase 05, y para
    # dos argumentos leerlos a mano es perfectamente razonable.
    if len(sys.argv) != 3 or sys.argv[1] != "resumen":
        print("uso: python aur_cli.py resumen <archivo.csv>", file=sys.stderr)
        sys.exit(2)  # 2 es la convención para "me invocaste mal"

    path = sys.argv[2]
    print(render(summarize(read_rows(path)), path))
```

Cuarenta y tantas líneas. **Esto es el registro script**, y conviene mirarlo bien porque durante
seis fases vas a escribir así:

**Detalles con intención**

- **Funciones sueltas a nivel de módulo, y el trabajo bajo `if __name__ == "__main__":`.** No hay
  `class AurCli`, no hay `main()` ceremonioso, no hay inyección de nada. El módulo **es** el
  espacio de nombres; en Python no hace falta una clase para agrupar funciones.
- **Las filas son tuplas.** Cuestan lo mismo, no se pueden modificar por accidente, y pueden ser
  llaves de un diccionario si algún día hacen falta. Es la aplicación directa de la segunda
  mitad del 🪞.
- **Las constantes de columna arriba.** `row[AMOUNT]` se lee; `row[5]` no. Es lo más barato que
  puedes hacer hoy para que esto siga siendo legible en la Fase 06.
- **`Decimal` desde el primer día, construido desde texto.** Es la regla del curso y no se
  negocia: el dinero de Áurea se reparte entre tres profesionales y dos sedes, y ahí el
  redondeo de un `float` deja de ser teórico.
- **`sys.exit(2)` para el error de invocación.** Los códigos de salida significan algo porque
  dentro de catorce fases esto lo va a llamar un proceso nocturno, y lo único que ese proceso va
  a poder leer es el código.
- **`print(..., file=sys.stderr)` para el mensaje de error.** La salida útil va a `stdout` para
  poder redirigirla; los mensajes van a `stderr`. Es la misma disciplina de siempre.
- **Y no hay manejo de errores.** Si el archivo no existe, revienta con un `FileNotFoundError` y
  su traza. Para un script que corre una persona, eso es una decisión defendible: la traza dice
  exactamente qué pasó. La Fase 04 discute cuándo deja de serlo.

**El patrón a memorizar**

> Un script de Python no necesita andamio. Funciones a nivel de módulo, datos inmutables donde se
> pueda, el trabajo bajo `if __name__ == "__main__":`, y códigos de salida con significado. Si
> aparece una clase con un solo método, es una función.

**Prueba de fuego**

```bash
python aur_cli.py resumen data/centro-2026-03.csv
```

```text
Resumen de data/centro-2026-03.csv
  procedimientos: 4
  pacientes distintos: 3
  facturado: $1,345,000
  por código:
    D2740  $     890,000
    D8010  $     360,000
    D8020  $      95,000
```

Cuatro procedimientos y tres pacientes: Ana María aparece dos veces. **Esa diferencia entre 4 y 3
es toda la fase** — y es también la primera mentira que te va a contar la salida. Agrega al
archivo una fila con el mismo documento pero el nombre escrito distinto (`Ana Maria Robledo`,
sin tilde) y vuelve a correr: el conteo de pacientes no cambia, porque estás contando documentos.
Ahora cambia un dígito del documento y deja el nombre idéntico: el conteo sube a 4. **Ninguna de
las dos respuestas es obviamente la correcta**, y esa es exactamente la decisión que te va a
tocar tomar en el miniproyecto.

### 5.3 Lo que tu instinto te va a pedir agregar, y por qué no

Vas a mirar ese archivo y a querer arreglarlo. Los tres impulsos, en orden de probabilidad:

**"Esto necesita una clase `Row`."** La necesita, y llega en la Fase 03 con `dataclass`. Hoy no:
introducirla antes de que el dolor exista convierte la lección en un acto de fe. Anótalo.

**"Falta validar el archivo."** Falta, y llega en la Fase 04 con el manejo de errores. Hoy, si el
CSV viene mal, revienta — y eso, para una herramienta que corre una persona mirando la pantalla,
es defendible.

**"Debería aceptar varios archivos."** Debería, y es justo lo que fuerza a `argparse` en la Fase
05. Hoy son dos argumentos y `sys.argv` alcanza. Cuando intentes agregar el tercero con una
bandera opcional vas a entender por qué existe `argparse`.

> 🧭 **La disciplina del Bloque A:** cuando sientas que falta estructura, anótalo en vez de
> agregarlo. Esa lista de anotaciones es la que en la Fase 07 se convierte en el argumento de que
> esto ya no es un script, y ese argumento vale mucho más si lo escribiste tú mientras dolía.

---

## 📏 6. Medición — el costo de preguntar "¿ya está?"

**Hipótesis.** Buscar pertenencia en una lista es lineal y en un conjunto es constante, y sobre
los 2.800 pacientes activos de Áurea esa diferencia deja de ser teórica: es la diferencia entre
una consolidación que corre en un parpadeo y una que se nota.

**Condiciones.** macOS 26.6 · Apple Silicon, 8 núcleos · CPython 3.14.5 · 2.800 documentos
generados con semilla fija `2026` · 2.800 consultas, la mitad presentes y la mitad ausentes —que
es la proporción realista de una consolidación de dos sedes— en orden aleatorio · 15
repeticiones · se reporta mediana y p95 del recorrido completo de las 2.800 consultas.

**Competidores.** Las tres estructuras que un dev Java senior consideraría para esto, que son
las mismas tres de allá: `list` (`ArrayList`), `set` (`HashSet`) y `dict` (`HashMap`), esta
última porque casi siempre además del "¿está?" quieres el valor asociado.

**Resultado.**

| Estructura | Mediana | p95 | Memoria |
|---|---|---|---|
| `list` | 53.97 ms | 54.63 ms | 23 KB |
| `set` | 0.101 ms | 0.102 ms | 131 KB |
| `dict` | 0.106 ms | 0.106 ms | 104 KB |

La lista hace **1.750 comparaciones por consulta** en promedio; el conjunto hace una.

Y el umbral, que es lo que convierte esto en criterio:

| Tamaño | `list` | `set` | Diferencia |
|---|---|---|---|
| 10 | 1.0 µs | 0.5 µs | 1.9× |
| 50 | 16.7 µs | 1.7 µs | 9.5× |
| 200 | 263 µs | 6.2 µs | 42× |
| 1.000 | 6.7 ms | 31.8 µs | 209× |
| 2.800 | 52.9 ms | 84.7 µs | 624× |

> ⚖️ **Veredicto.** Sobre los 2.800 pacientes de Áurea, el conjunto es **534× más rápido** que la
> lista, y cuesta 5.7 veces más memoria: 131 KB contra 23 KB. Esa proporción de memoria suena
> mal y no lo es — son 108 KB de diferencia, y la lista pierde 53 milisegundos **por cada
> pasada**. Si tu script hace diez pasadas sobre el archivo, acabas de gastar medio segundo en
> preguntar cosas.
>
> **El umbral donde cambia la respuesta está alrededor de las cincuenta entradas.** Por debajo de
> eso la diferencia es de microsegundos y no justifica pensar: una lista de diez sedes se busca
> con `in` y nadie debería escribir un `set` para eso. Por encima de mil, no hay discusión
> posible. En la zona de en medio —entre cincuenta y mil— decide la frecuencia: si preguntas una
> vez, da igual; si preguntas dentro de un bucle, ya no.
>
> **Dónde pierde el conjunto, y hay que decirlo:** no conserva el orden, no admite duplicados
> —que a veces es información— y exige que sus elementos sean *hashables*, lo que descarta usar
> las filas completas si fueran listas. Por eso las filas de `aur_cli.py` son tuplas.
>
> **Y el empate real:** `set` y `dict` empatan en velocidad, dentro del ruido de medición. La
> elección entre ellos no es de rendimiento, es de si necesitas el valor asociado o solo la
> pregunta.

**Lo que no se midió:** el costo de *construir* cada estructura, que es lineal en los tres casos
y se paga una vez. Si tu programa construye el conjunto para hacer tres consultas, la lista gana
— y el ejercicio 17 te pide encontrar ese punto exacto.

---

## 🧱 7. Miniproyecto — *El consolidado que miente*

**El encargo**

Patricia te reenvía un correo de Julián y le agrega una línea: *"Julián quiere saber cuántos
pacientes distintos atendimos en la red en marzo. Yo le mandé la suma de las diez sedes: 4.117.
Él dice que eso no puede ser porque los activos son 2.800. Y los dos tenemos razón, porque hay
gente que se atiende en dos sedes y yo no tengo cómo saber cuál es cuál. ¿Me ayudas a contarlos
bien?"*

Escribe la herramienta que consolida los diez archivos y responde la pregunta de Julián — y que
además le dice a Patricia **cuáles** son los casos dudosos, porque el número solo no le sirve
para nada.

**Por qué duele**

Porque la pregunta *"¿son el mismo paciente?"* no tiene respuesta única, y el enunciado no la va
a tomar por ti. El documento debería bastar, y no basta: las sedes lo digitan a mano, hay
documentos con puntos, con guiones, con espacios al final, hay menores registrados con el
documento del acudiente, y hay al menos un caso donde dos personas comparten documento porque
alguien se equivocó al teclear. El nombre tampoco basta: tildes, orden de apellidos, segundos
nombres que unas sedes escriben y otras no.

**Datos de entrada**

Diez archivos con el formato del export de la sección 5.1, uno por sede, que generas tú con este
script — versionable, con semilla fija, y **la primera pieza de un patrón que el curso repite**:
los datos del curso se generan, no se descargan.

```python
"""Genera los diez exports de marzo de 2026, con la suciedad del mundo real.

Uso:  python generar_datos_f01.py
Produce data/<sede>-2026-03.csv para las diez sedes.
"""

import random
import unicodedata
from pathlib import Path

BRANCHES = ["Centro", "Chapinero", "Suba", "Kennedy", "Usaquen",
            "Engativa", "Fontibon", "Restrepo", "Soacha", "Zipaquira"]
CODES = {"D8010": 180000, "D8020": 95000, "D2740": 890000,
         "D7140": 210000, "D1110": 75000, "D8670": 120000}
FIRST = ["Ana María", "Carlos Efrén", "Luz Dary", "Jhon Fredy", "Diana Marcela",
         "Óscar Iván", "Yenny Paola", "Wílmer Andrés", "Sandra Milena", "José Ángel",
         "Nubia Esther", "Édinson Alberto", "Leidy Johana", "Fabián Ricardo",
         "Martha Liliana", "Héctor Julio", "Claudia Patricia", "Freddy Alexánder",
         "Rocío del Pilar", "Gustavo Adolfo", "Mónica Andrea", "Jairo Enrique",
         "Astrid Carolina", "Néstor Fabio"]
LAST = ["Robledo", "Neira", "Peña", "Chaparro", "Ocampo", "Guzmán", "Rojas",
        "Buitrago", "Cárdenas", "Quintero", "Mahecha", "Bermúdez", "Alfonso",
        "Chacón", "Piraquive", "Urrego", "Salamanca", "Bohórquez", "Trujillo",
        "Velandia", "Camargo", "Sáenz", "Pulido", "Lozano", "Forero", "Amaya",
        "Barbosa", "Gaitán", "Rincón", "Támara"]


def strip_accents(text):
    """Quita tildes. Algunas sedes digitan sin ellas y otras no."""
    return "".join(c for c in unicodedata.normalize("NFD", text)
                   if unicodedata.category(c) != "Mn")


def main():
    random.seed(2026)
    Path("data").mkdir(exist_ok=True)

    # 2.800 pacientes reales en la red, cada uno con su documento canónico y su nombre.
    # Los nombres se muestrean SIN repetición del producto completo: así el único homónimo
    # de los datos es el que sembramos abajo a propósito, y la señal no se pierde entre
    # coincidencias de azar. (En los datos reales de Áurea sí hay homónimos de verdad;
    # el ejercicio 🔥 del final te pide qué cambiaría si los hubiera.)
    all_names = [f"{first} {last1} {last2}"
                 for first in FIRST for last1 in LAST for last2 in LAST if last1 != last2]
    people = [(str(random.randint(10_000_000, 1_299_999_999)), name)
              for name in random.sample(all_names, 2800)]

    # 340 de ellos se atienden en una segunda sede: son los duplicados de verdad.
    shared = random.sample(people, 340)

    # Y los dos casos que ninguna normalización resuelve, sembrados a propósito y
    # repartidos en sedes concretas para que no dependan del azar del muestreo.
    # Están aquí porque existen en Áurea, no para hacer el ejercicio más difícil.
    document_a, name_a = people[7]
    document_b, name_b = people[11]
    swapped = document_b[:-2] + document_b[-1] + document_b[-2]   # dígitos cambiados al digitar

    seeded = {
        # Mismo documento, dos personas: alguien digitó mal la cédula al admitir a Gloria.
        "Centro": [(document_a, name_a)],
        "Kennedy": [(document_a, "Gloria Esperanza Mahecha Vargas")],
        # Misma persona, dos documentos: Suba le invirtió dos dígitos.
        "Chapinero": [(document_b, name_b)],
        "Suba": [(swapped, name_b)],
    }

    for branch in BRANCHES:
        rows = []
        for document, name in (random.sample(people, 260) + random.sample(shared, 40)
                               + seeded.get(branch, [])):
            # La suciedad: cada sede digita a su manera.
            if random.random() < 0.15:
                document = f"{document[:-3]}.{document[-3:]}"   # con puntos
            if random.random() < 0.10:
                document = document + " "                        # con espacio al final
            if random.random() < 0.25:
                name = strip_accents(name)                       # sin tildes
            if random.random() < 0.10:
                name = name.upper()                              # en mayúsculas
            for _ in range(random.randint(1, 3)):
                code = random.choice(list(CODES))
                day = random.randint(1, 28)
                rows.append(f"{document},{name},{branch},2026-03-{day:02d},{code},{CODES[code]}")

        path = Path("data") / f"{branch.lower()}-2026-03.csv"
        path.write_text("documento,paciente,sede,fecha,codigo,valor\n" + "\n".join(rows) + "\n",
                        encoding="utf-8")
        print(f"{path}: {len(rows)} filas")


if __name__ == "__main__":
    main()
```

**Criterios de aceptación**

- [ ] Un solo archivo, `consolidado.py`, biblioteca estándar pura, que lee los diez CSV y
      responde con un número: cuántos pacientes distintos se atendieron en la red en marzo.
- [ ] Reporta además **cuántos pacientes se atendieron en más de una sede**, y en cuáles.
- [ ] Emite una lista de **casos dudosos**: mismo documento con nombres que no coinciden, y
      nombres iguales con documentos distintos. Con la sede y la fila donde aparece cada uno,
      para que Patricia pueda ir a mirar.
- [ ] La regla de identidad que elegiste está escrita **en el propio archivo**, en un comentario
      de tres líneas: qué normalizas, qué no, y qué caso sacrificas.
- [ ] Corre sobre los diez archivos completos en menos de dos segundos.
- [ ] **Medición:** reporta cuántos pacientes distintos salieron con tu regla y cuántos saldrían
      contando documentos en crudo, sin normalizar. La diferencia entre esos dos números es lo
      que va en el mensaje del tag.

**Restricciones de registro**

> Esto es un **script**. Un archivo, stdlib pura, sin dependencias, sin clases — todavía no las
> hemos visto y no hacen falta. Tuplas y diccionarios. Si te descubres escribiendo
> `class PatientMatcher` o pensando en una interfaz para "poder cambiar la estrategia de
> comparación", ese es exactamente el reflejo que el Bloque A ataca. Anótalo en una lista: en la
> Fase 03 vas a ver qué habría costado y qué habría dado.

**La trampa**

Vas a normalizar el documento y a dar el problema por resuelto. Y con los datos del generador te
va a dar un número razonable, así que vas a creer que está bien.

No lo está. Hay dos casos en esos archivos que tu normalización no cubre, y los dos existen en
Áurea de verdad: uno donde el mismo documento tiene dos nombres que no se parecen —dos personas
distintas, y una de las dos está mal registrada— y otro donde la misma persona aparece con dos
documentos distintos porque una sede le digitó el número al revés. **Si tu programa no los
señala, tu número está mal y Patricia no tiene forma de saberlo.** Esa es la diferencia entre
contar y consolidar.

**Pistas**

<details><summary>Pista 1 — el enfoque</summary>

Son dos problemas y conviene no mezclarlos. El primero es **normalizar**: llevar cada documento
y cada nombre a una forma canónica antes de comparar. El segundo es **detectar
inconsistencias**: encontrar dónde la normalización no alcanzó, lo que se descubre agrupando en
las dos direcciones — por documento, mirando qué nombres trae; y por nombre, mirando qué
documentos trae.

La estructura que resuelve las dos direcciones es la misma y ya la tienes en la sección 6.
</details>

<details><summary>Pista 2 — la herramienta</summary>

Para el documento: `str.strip()`, `str.replace()` y
[`str.isdigit()`](https://docs.python.org/3.14/library/stdtypes.html#str.isdigit).

Para el nombre, lo que de verdad hace falta es
[`unicodedata.normalize`](https://docs.python.org/3.14/library/unicodedata.html#unicodedata.normalize)
con la forma `NFD`, que separa la letra de su tilde y permite descartar las marcas — el
generador de datos lo usa, y la razón de que exista es exactamente esta. `str.casefold()` es
mejor que `.lower()` para comparar, y la documentación explica por qué.

Y para agrupar en las dos direcciones,
[`dict.setdefault`](https://docs.python.org/3.14/library/stdtypes.html#dict.setdefault) o un
diccionario de conjuntos.
</details>

<details><summary>Pista 3 — el esqueleto</summary>

```python
def normalize_document(raw: str) -> str:
    """Forma canónica del documento. Decide tú qué se conserva."""

def normalize_name(raw: str) -> str:
    """Forma canónica del nombre, para comparar — no para mostrar."""

def load_all(folder) -> list[tuple]:
    """Las filas de los diez archivos, con su sede y su número de línea."""

def index_both_ways(rows) -> tuple[dict, dict]:
    """documento -> {nombres} y nombre -> {documentos}. Las dos direcciones."""

def suspicious(by_document, by_name) -> list[str]:
    """Los casos que la normalización no resolvió, en español y con su ubicación."""
```
</details>

**Cómo se entrega**

```bash
python generar_datos_f01.py      # una vez
python consolidado.py data/      # el consolidado
```

```bash
git add consolidado.py generar_datos_f01.py
git commit -m "fase 01 mini: consolidado de pacientes de las diez sedes"
git tag -a mini-01 -m "Mini F1: consolidado de pacientes · <N> distintos con normalización, <M> sin ella, <K> casos dudosos"
```

> 📝 **El generador sí se versiona; los CSV que produce, no.** El `.gitignore` de la Fase 00 ya
> los excluye. Es la primera aparición de una regla que el curso repite: lo que se puede
> reproducir con una semilla no ocupa lugar en la historia.

---

## 🧪 8. Ejercicios (25)

**🟢 Fácil (1–6)**

1. Escribe cinco líneas que demuestren que `a is b` y `a == b` pueden dar respuestas distintas
   para cadenas, y explica en un comentario por qué el resultado cambia según de dónde venga la
   cadena.
2. Toma el `by_code` de `summarize` y devuélvelo ordenado por valor facturado descendente en vez
   de por código. Una línea.
3. Agrega a `aur_cli.py` la cuenta de cuántos procedimientos hubo por sede, sabiendo que hoy el
   archivo es de una sola sede. Explica en un comentario por qué esa cuenta hoy no sirve de nada
   y en qué momento va a servir.
4. Demuestra con código que `Decimal("0.1") * 3 == Decimal("0.3")` es `True` y que
   `0.1 * 3 == 0.3` es `False`. Imprime el valor real de `0.1 * 3` con veinte decimales.
5. Convierte la lista de sedes de Áurea en una tupla y demuestra que ahora puede ser llave de un
   diccionario mientras que la lista no podía. Copia el mensaje exacto del error.
6. Escribe una función con el argumento por defecto mutable, llámala tres veces, y después
   arréglala. Deja las dos versiones en el archivo, con un comentario de una línea.

**🟡 Intermedio (7–14)**

7. Lee la documentación de `copy` y escribe un ejemplo con los datos de Áurea donde
   `copy.copy` y `copy.deepcopy` den resultados distintos. Mide cuánto tarda cada una sobre las
   filas de los diez archivos.
8. `id()` devuelve la identidad de un objeto. Úsala para demostrar qué pasa con `a = 256; b = 256`
   y con `a = 257; b = 257`, y escribe por qué **no** debes usar eso para nada.
9. Averigua qué es `sys.intern` y en qué caso concreto de esta fase serviría. Mide la memoria de
   las 2.800 cadenas de documento con y sin él.
10. Escribe una función que reciba una lista de filas y devuelva una versión "congelada"
    —inmutable en todos sus niveles— sin usar `copy.deepcopy`. Explica qué garantiza y qué no.
11. Consulta la documentación de `str.casefold` y demuestra con un caso en español dónde
    `.lower()` y `.casefold()` difieren. Si no encuentras uno en español, dilo y busca en otro
    idioma.
12. `dict.get`, `dict.setdefault` y `collections.defaultdict` resuelven parecido. Reescribe el
    `by_code` de `summarize` con los tres y argumenta cuál dejarías en un script y cuál no.
13. Toma la salida de `render` y haz que el formato de pesos use separador de miles con punto y
    decimales con coma, como se escribe en Colombia. Averigua por qué `locale` es una mala idea
    en un script que corre en la máquina de otra persona.
14. Demuestra con código que `{"a": 1} == {"a": 1}` es `True` pero `{"a": 1} is {"a": 1}` es
    `False`, y después encuentra un caso donde dos diccionarios iguales tengan orden de inserción
    distinto. ¿Cambia la igualdad? ¿Debería?

**🟠 Difícil (15–21)**

15. **Diagnóstico.** Te pasan esta función y te dicen que "a veces acumula datos de la corrida
    anterior":
    ```python
    def collect(row, seen={}, totals=[]):
        seen[row[0]] = row[1]
        totals.append(row[5])
        return seen, totals
    ```
    Reprodúcelo, explica el mecanismo exacto, arréglalo, y escribe la regla de `ruff` que lo
    habría atrapado.
16. **Diagnóstico.** Un script de Patricia calcula el total del mes y da $3 de diferencia contra
    Odontovía, siempre a favor. Reproduce el escenario con `float`, muestra de dónde salen los
    tres pesos, y demuestra que con `Decimal` desaparece. Explica por qué la diferencia es
    *siempre* en la misma dirección.
17. **Medición.** Encuentra el punto exacto donde construir un `set` deja de valer la pena porque
    se hacen pocas consultas. Es decir: para 2.800 elementos, ¿a partir de cuántas consultas el
    conjunto compensa su costo de construcción? Reporta con el formato de la sección 6.
18. **Medición.** Mide `in` sobre una lista de 2.800 documentos contra `in` sobre una **lista
    ordenada** usando `bisect`. Explica el resultado y di en qué caso real de Áurea preferirías
    `bisect` a un `set`.
19. Reescribe `read_rows` para que devuelva una lista de diccionarios en vez de tuplas. Mide
    tiempo y memoria de las dos versiones sobre los diez archivos, y decide cuál dejarías. Hay
    una respuesta defendible en las dos direcciones: la tuya tiene que venir con su número.
20. **De registro.** Patricia quiere que el consolidado del miniproyecto se corra "todos los
    meses, automáticamente, y que me llegue al correo". Decide si eso sigue siendo un script,
    pasa a ser una herramienta, o ya es una aplicación. Justifica con el costo de las tres
    opciones en términos de quién lo ejecuta, quién lo arregla cuando falle un domingo, y qué
    pasa cuando Patricia quiera cambiar el destinatario.
21. **De registro.** Julián pide que el consolidado "también deje ver el historial de los últimos
    seis meses". Enumera qué cambia técnicamente, decide el registro, y di explícitamente qué
    parte de esa solicitud **no deberías construir** y qué le responderías a Julián. La respuesta
    "no construyas esto" es legítima en este curso.

**🔴 Muy difícil (22–25)**

22. **Adversarial.** Construye un archivo de entrada que haga que `aur_cli.py` produzca un total
    incorrecto **sin lanzar ninguna excepción**. Tienes al menos tres formas: la deuda 💸 del
    `split(",")`, el encoding, y los espacios. Documenta las tres con la salida que producen, y
    di cuál de ellas se arregla en qué fase.
23. **Adversarial.** Escribe dos filas de pacientes distintos que tu regla de identidad del
    miniproyecto fusione en una sola, y dos filas del mismo paciente que tu regla separe. Después
    ajusta la regla para arreglar una de las dos cosas y demuestra que la otra empeoró. Escribe
    media página sobre qué error prefieres cometer en Áurea y por qué — contar de más o contar de
    menos no cuestan lo mismo cuando lo que se liquida es una regalía.
24. **Defiende una decisión.** Un colega revisa `aur_cli.py` y dice: *"esto necesita una clase
    `Procedure` con sus campos tipados; así no hay quien lo mantenga"*. Tiene parte de razón.
    Escribe la respuesta con las dos caras: qué gana esa clase, qué cuesta hoy, y cuál es la
    señal concreta —no la intuición— que te haría dársela. Guárdala: la Fase 03 la contesta y la
    Fase 07 la cobra.
25. **Medición y diseño.** Los 2.800 pacientes de Áurea crecen un 20% al año. Mide la
    consolidación del miniproyecto con 2.800, 5.600 y 11.200 pacientes, y proyecta a qué tamaño
    tu implementación deja de correr en menos de dos segundos. Después di cuál sería la primera
    cosa que cambiarías, y si esa cosa la puedes hacer hoy o necesitas algo que el curso todavía
    no te dio.

**🔥 Opcionales**

- Lee el modelo de datos en la referencia del lenguaje (`docs.python.org/3.14/reference/datamodel.html`)
  hasta donde aguantes. Es denso, es la fuente de verdad, y la Fase 03 lo va a citar.
- Averigua qué es `sys.getsizeof` y por qué el tamaño que reporta para una lista de cadenas es
  una mentira útil. Compáralo con lo que reporta para la misma lista de tuplas.
- Reescribe `summarize` sin bucles explícitos, usando solo comprehensions. Después decide
  honestamente cuál de las dos versiones dejarías en un archivo que va a mantener alguien que no
  eres tú.
- El generador siembra nombres únicos para que la señal del miniproyecto se vea. En los datos
  reales de Áurea hay homónimos de verdad — dos "Jhon Fredy Rojas Buitrago" que son dos personas.
  Modifica el generador para que produzca una docena de homónimos legítimos, vuelve a correr tu
  consolidado, y escribe qué le dirías a Patricia sobre la lista de dudosos que le sale ahora.

---

## 📚 9. Referencias

**Documentación oficial**

- [El modelo de datos](https://docs.python.org/3.14/reference/datamodel.html) — la fuente de
  verdad de todo lo de esta fase. Densa; se lee por partes y se vuelve a ella.
- [Tipos incorporados](https://docs.python.org/3.14/library/stdtypes.html) — `list`, `dict`,
  `set`, `tuple`, `str` y sus complejidades. La sección de *truth value testing* es la tabla de
  verdad de §4.
- [`decimal`](https://docs.python.org/3.14/library/decimal.html) — el equivalente de
  `BigDecimal`, con la explicación de por qué construirlo desde texto.
- [`copy`](https://docs.python.org/3.14/library/copy.html) — superficial contra profunda, y qué
  pasa con los ciclos.
- [`unicodedata`](https://docs.python.org/3.14/library/unicodedata.html) — normalización, para el
  miniproyecto.
- [Reglas `B` de ruff](https://docs.astral.sh/ruff/rules/#flake8-bugbear-b) — `B006` es el
  argumento por defecto mutable.

**PEPs**

- [PEP 468](https://peps.python.org/pep-0468/) y la nota de *What's New in Python 3.7* sobre el
  orden de los diccionarios — de dónde salió la garantía que hoy damos por hecha.

**Libros / artículos**

- *Fluent Python*, de Luciano Ramalho — los capítulos sobre el modelo de datos y sobre
  referencias y mutabilidad son la mejor explicación larga que existe de esta fase. Verifica la
  edición: la segunda cubre hasta 3.10 y algunas cosas cambiaron.

**Orden de lectura sugerido.** Antes de escribir código: la sección de *truth value testing* de
los tipos incorporados, que son dos páginas y evitan la mitad de los errores. Durante: `decimal`
y `unicodedata`, a medida que el miniproyecto los pida. Después: el modelo de datos, que se
disfruta mucho más cuando ya te estrellaste con la copia superficial.

> ⚠️ Las URL, los títulos y las ediciones cambian; verifícalos antes de citarlos.

---

## 🚀 10. Cierre y conexión con la siguiente fase

Tienes el modelo mental correcto de qué es un valor, y tienes las primeras cuarenta líneas del
CLI de Patricia, que van a seguir vivas dieciséis fases más — creciendo, migrando a paquete en la
07, distribuyéndose en la 09 y siendo importadas por el proceso nocturno en la 15.

Y tienes una deuda 💸 escrita en el propio archivo. No la arregles: es el mecanismo con el que
este curso enseña que los atajos se declaran, se acotan y se pagan en una fecha. En la Fase 06 la
vas a cobrar con un `git diff fase-01 fase-06` y vas a ver exactamente qué costó.

La **Fase 02** ⭐ es la primera pieza central del curso. Hoy `read_rows` construye la lista
completa antes de devolverla, lo cual con el export de una sede está perfecto y con el archivo de
citas del trimestre —quinientas mil filas— te deja sin memoria. Ahí se construye también **el
arnés de medición** que las quince fases siguientes van a usar, y que es lo que hace que este
curso pueda afirmar cosas en vez de opinarlas.

> **La señal de que quedó bien:** cuando leas código ajeno y veas `lista[:]`, ya no vas a pensar
> *"ah, copia defensiva"* — vas a pensar *"¿y lo de adentro?"*.

> 🏷️ **No cierres la fase sin el tag.** Con el checklist de la sección 2 en verde, el
> miniproyecto corriendo y `git status` limpio:
>
> ```bash
> git tag -a fase-01 -m "F1 cerrada:
> - identidad e igualdad entendidas, con el caso de los enteros demostrado
> - la copia superficial y el argumento por defecto mutable reproducidos y arreglados
> - aur_cli.py nace: lee el export de una sede y produce el resumen del mes
> - la deuda del split(',') declarada en el archivo, con su fase de pago
> - el consolidado de las diez sedes corre y reporta sus casos dudosos"
> ```
>
> Los commits de la fase llevan su prefijo (`fase 01: …`), los de ejercicio su número
> (`fase 01 ej12: …`) y el miniproyecto el suyo (`fase 01 mini: …`). El miniproyecto terminado
> lleva además su tag anotado `mini-01`, y **en el mensaje de ese tag va el número que arrojó su
> medición**. La convención completa está en
> [`00-convencion-de-git-y-tags.md`](00-convencion-de-git-y-tags.md).
