# 🐚 Fase 05 ⭐ — El shell con esteroides

> Python para desarrolladores Java senior · Fase 5 de 18 · Bloque A
> Depende de: Fase 04 · Habilita: Fase 06
> Registro de esta fase: **script** — un archivo, stdlib pura
> Proyecto que avanza: el CLI · **gana `argparse`, `pathlib` y el firmador**
> Fecha de verificación de las versiones: 12/09/2026

---

## 🎯 1. Propósito

Demostrar la tesis del Bloque A: **la biblioteca estándar es el reemplazo del shell**, y un
script de Python es un ciudadano de primera del sistema operativo — no un programa que
casualmente corre ahí.

Si al terminar esta fase no has cambiado de opinión sobre cuánto viene en la caja, la fase falló.
Y si sigues pensando que para orquestar procesos, manejar rutas y hablar con el sistema hace falta
un `.sh` en Linux y un `.bat` en Windows, también.

Es la fase donde tu script deja de ser un programa que lee y escribe archivos, y pasa a ser algo
que **invoca a otros programas, sobrevive a que se cuelguen, y le reporta a quien lo llamó si
puede seguir**. Que es exactamente lo que el cierre de mes de Áurea necesita.

---

## ✅ 2. Qué queda listo al terminar

- [ ] No vuelves a concatenar cadenas para armar una ruta, y puedes decir qué se rompe cuando lo
      haces.
- [ ] Invocas procesos externos con lista de argumentos, con `timeout`, y **mirando el código de
      retorno**.
- [ ] Puedes explicar en una frase por qué `shell=True` está prohibido en el resto del curso.
- [ ] El CLI usa `argparse` con subcomandos, y `sys.argv` a mano quedó atrás.
- [ ] Un `Ctrl-C` a mitad del proceso no deja archivos a medias ni procesos hijos huérfanos.
- [ ] Tus códigos de salida significan algo, y hay un documento de una línea que dice cuál es cuál.
- [ ] El miniproyecto de la sección 7 corre y cumple sus criterios de aceptación.

---

## 🚫 3. Qué NO entra todavía

- **Distribuir la herramienta** → Fase 09. Hoy sigue siendo un `.py` que corres tú.
- **`logging`** → Fase 16. Los mensajes siguen yendo a `stderr` con `print`.
- **Concurrencia real** —lanzar cinco firmadores a la vez— → Fase 14. Hoy los procesos se
  invocan en serie, y la sección 6 mide exactamente cuánto cuesta eso.
- **`csv`, `json` y los formatos** → Fase 06, la que viene. La deuda 💸 de la Fase 01 sigue viva.
- **HTTP saliente** → Fase 13. `subprocess` no es para llamar a `curl`: si necesitas HTTP, hay
  biblioteca.

---

## 🧠 4. Concepto mínimo

### Tu instinto de Java dice… y esta vez se equivoca

Esta fase tiene dos reflejos y los dos son caros. El primero rompe tu script en una plataforma;
el segundo hace que reporte éxito sobre trabajo que no se hizo.

#### Primero: concatenar cadenas

```python
# ❌ Las tres formas que salen solas, y las tres están mal
path = directory + "/" + filename
path = "%s/%s" % (directory, filename)
command = f"firmador --entrada {path} --salida {target}"
```

Las dos primeras fallan en Windows —donde el separador es `\`— y fallan en todas partes cuando
`directory` ya termina en barra. La tercera falla de una forma peor: si el archivo se llama
`factura de marzo.xml`, el comando ve tres argumentos donde debía ver uno.

```python
# ✅ Las rutas son objetos, y el operador que las une es /
from pathlib import Path

path = Path(directory) / filename          # funciona igual en las tres plataformas
target = path.with_suffix(".firmado.xml")  # y esto reemplaza medio módulo os.path

# ✅ Y los comandos son listas: cada elemento es un argumento, punto.
subprocess.run(["firmador", "--entrada", str(path), "--salida", str(target)])
```

`Path` sobrecarga el operador `/` para unir rutas, y la primera vez se ve raro. A la tercera vez
ya no, y a cambio se acabaron los separadores, los `os.path.join` anidados y los espacios.

**Por qué este reflejo es tan persistente:** en Java trabajas con `String` para rutas más de lo
que te gusta admitir, y `File` y `Path` llegaron tarde a una API que ya tenía costumbres. Aquí
`pathlib` es la forma normal desde 3.4 y el módulo `os.path` —que es el equivalente de manipular
cadenas— sigue existiendo por compatibilidad. Si ves `os.path.join` en código nuevo, es un hábito
viejo.

#### Segundo, y es el que cuesta dinero: ignorar el código de retorno

```python
# ❌ Esto "funciona" y es una bomba
subprocess.run(["firmador", "--entrada", str(path), "--salida", str(target)])
print("✅ facturas firmadas")     # ¿seguro?
```

En Java, una llamada que falla te lanza algo. `subprocess.run` **no lanza nada** cuando el
programa invocado falla: devuelve un objeto con `returncode` distinto de cero, y si nadie lo mira,
tu script sigue adelante tan tranquilo. Un cierre de mes que reporta éxito sobre cuarenta facturas
sin firmar es exactamente así como ocurre.

```python
# ✅ Las dos formas correctas, y la elección es de diseño
result = subprocess.run([...], capture_output=True, text=True, timeout=30)
if result.returncode != 0:
    ...  # decides qué hacer con este caso concreto

# o, cuando cualquier fallo debe abortar:
subprocess.run([...], check=True)   # lanza CalledProcessError si el código no es 0
```

> 🧭 **La regla del curso, y aplica de aquí en adelante:** todo `subprocess.run` lleva **tres
> cosas**: lista de argumentos, `timeout`, y el código de retorno revisado. Un `run` sin las tres
> es un error de revisión.

### `shell=True`, el agujero

Existe una bandera que hace que `subprocess` acepte una cadena y se la pase al shell del sistema.
Y en ese momento el shell interpreta la cadena: comillas, variables, redirecciones, y `;`.

```python
# ❌ Nunca. Ni una sola vez en el resto de este curso.
subprocess.run(f"firmador --entrada {path}", shell=True)
```

Si `path` vale `factura.xml; rm -rf ~`, el shell hace las dos cosas. En Áurea el nombre del
archivo sale del export de una sede, es decir, de un dato que escribió otra persona — y ese es
literalmente el vector. No es un ejemplo de laboratorio: es cómo se ve una inyección de comandos
en un script de cierre de mes.

Con la lista de argumentos, `subprocess` invoca el programa **directamente**, sin shell de por
medio. No hay nada que interpretar, así que no hay nada que inyectar. Y además es más rápido,
porque no arranca un shell.

> ⚠️ **`shell=True` queda prohibido en el resto del curso.** Si algún día necesitas una tubería o
> una redirección, existen sin shell: `stdin=`, `stdout=`, y conectar dos procesos pasando el
> `stdout` del primero al `stdin` del segundo. El ejercicio 12 lo pide.

### Esto sí funciona igual

**Los procesos son los procesos.** Un proceso hijo, su entrada, su salida, su salida de error, y
un código de retorno que el padre recoge. Nada de eso cambia, y todo lo que sabes de
`ProcessBuilder` se traduce casi línea por línea — con la diferencia de que aquí cuesta la mitad
de código.

**Los códigos de salida significan lo mismo.** `0` es éxito, todo lo demás es un fallo cuyo
significado lo define el programa. Las convenciones que ya conoces —`1` para error genérico, `2`
para uso incorrecto— valen aquí igual.

**Y las variables de entorno son variables de entorno.** `os.environ` es un diccionario, y pasarle
un entorno modificado a un hijo es un parámetro (`env=`). La disciplina de no meter secretos en
la línea de comandos —porque los ve cualquiera con `ps`— vale idéntico.

### Diccionario de traducción

| Java | Python | Dónde se rompe el paralelo |
|---|---|---|
| `Paths.get(a, b)` | `Path(a) / b` | El operador `/` une rutas; se lee raro dos días y después no |
| `File.getName()` / `getParent()` | `path.name` / `path.parent` | Atributos, no métodos |
| `getNameWithoutExtension` (Guava) | `path.stem` | En la caja, sin biblioteca |
| `Files.readString(path)` | `path.read_text(encoding="utf-8")` | **El encoding no tiene un buen valor por defecto**: en Windows no es UTF-8. Siempre explícito |
| `Files.walk` | `path.rglob("*.xml")` | Devuelve un generador (Fase 02), no un stream |
| `ProcessBuilder` | `subprocess.run` | Una función, no un objeto que se configura |
| `Process.waitFor()` | `run` ya espera | Para no esperar, `subprocess.Popen` |
| `exitValue()` | `result.returncode` | **Nadie lo mira por ti, y nada lanza si es distinto de 0** |
| `redirectErrorStream(true)` | `stderr=subprocess.STDOUT` | Igual, y con el mismo riesgo de mezclar dos cosas distintas |
| `Runtime.exec(String)` | `shell=True` | Las dos son la forma peligrosa. Aquí está prohibida |
| `System.getenv()` | `os.environ` | Un diccionario mutable; los cambios afectan a los hijos |
| `System.exit(2)` | `sys.exit(2)` | Igual, y lanza `SystemExit` —que un `except Exception` no atrapa |
| `Runtime.addShutdownHook` | `signal.signal` / `atexit` | Dos mecanismos distintos, y hay que elegir bien: §5.4 |
| Apache Commons CLI / picocli | `argparse` | En la caja. Genera la ayuda, valida tipos y maneja subcomandos |

> 📝 **Nota de ecosistema — `pathlib` contra `os.path`.** `pathlib` llegó en 3.4 y hoy es la
> forma normal; `os.path` sigue ahí entero y funcionando, y vas a encontrarlo en todo el código
> anterior a 2015 y en mucho del posterior. No está roto. Lo que sí conviene saber es que las dos
> APIs conviven bien: casi toda la biblioteca estándar acepta un `Path` donde espera una ruta,
> gracias a un protocolo (`os.PathLike`). Cuando algo no lo acepte —suele ser código viejo o una
> extensión en C— `str(path)` resuelve.

### `argparse`, y por qué llega ahora

En la Fase 01 el CLI leía `sys.argv` a mano y eso estaba **bien**: dos argumentos, tres líneas de
código. Hoy tiene cuatro subcomandos, cada uno con sus opciones, y el `if` del despacho ya pesa.

Esa es la señal, y es la misma lógica de todo el Bloque A: **la herramienta llega cuando el dolor
existe.** Lo que `argparse` trae, y que escribir a mano cuesta doscientas líneas:

- Subcomandos con sus propias opciones (`aur resumen ...` contra `aur validar ...`).
- Conversión y validación de tipos: `type=Path`, `type=Decimal`, `choices=[...]`.
- `--help` generado, en cada nivel, sin escribirlo.
- Errores de uso con mensaje y **código de salida 2**, que es la convención.
- Argumentos obligatorios, opcionales, banderas, y valores por defecto.

Hay alternativas populares —`click`, `typer`— que son buenas y que **no entran al Bloque A**
porque son dependencias. Cuando lleguemos a la Fase 07 y las dependencias sean legítimas, la
pregunta va a ser si `argparse` sigue alcanzando; y la respuesta, adelantada, es que para este CLI
sí.

---

## 💻 5. Código mínimo con comentarios

### 5.1 Rutas, bien

```python
from pathlib import Path

DATA = Path("data")

# Unir, sin separadores a mano y sin importar la plataforma.
export = DATA / "centro-2026-03.csv"

# Las partes de una ruta son atributos, no métodos.
export.name        # 'centro-2026-03.csv'
export.stem        # 'centro-2026-03'
export.suffix      # '.csv'
export.parent      # PosixPath('data')

# Derivar nombres sin tocar cadenas.
signed = export.with_suffix(".firmado.xml")
backup = export.with_name(f"{export.stem}.bak{export.suffix}")

# Buscar, y es perezoso: devuelve un generador (Fase 02).
for csv_file in sorted(DATA.glob("*-2026-03.csv")):
    ...

# Y leer con el encoding SIEMPRE explícito.
content = export.read_text(encoding="utf-8")
```

**Detalles con intención**

- **`sorted()` alrededor de `glob`.** El orden que devuelve el sistema de archivos no está
  garantizado y difiere entre plataformas. Un cierre de mes que procese las sedes en orden
  distinto cada vez es un cierre que no se puede comparar con el del mes pasado.
- **El encoding explícito, siempre.** `read_text()` sin `encoding` usa el del sistema, que en
  Windows no es UTF-8. Es el error que produce esos `Ã©` en vez de `é` — y la Fase 06 lo convierte
  en tema.
- **`Path` para todo, `str` solo en el borde**, cuando algo viejo lo exija.

### 5.2 `subprocess`, bien

```python
import subprocess
from pathlib import Path

FIRMADOR = Path("herramientas") / "firmador"


def sign_invoice(source: Path, target: Path, timeout_seconds: float = 30) -> tuple[int, str]:
    """Firma una factura con el binario del proveedor.

    Devuelve el código de retorno y el mensaje del proveedor. No lanza cuando
    el proveedor falla: el que llama decide qué hacer con cada código, que es
    lo que la Fase 04 llamó "devuelve cuando el que llama tiene que decidir".

    Levanta:
        subprocess.TimeoutExpired: si el proveedor se cuelga.
    """
    result = subprocess.run(
        # 1. Lista de argumentos: nada que el shell pueda interpretar.
        [str(FIRMADOR), "--entrada", str(source), "--salida", str(target)],
        # 2. Capturar las dos salidas por separado: son cosas distintas.
        capture_output=True,
        # text=True las decodifica a str. Sin esto llegan como bytes.
        text=True,
        # El encoding de la frontera del proceso tampoco tiene buen valor por
        # defecto en Windows: se declara, igual que con los archivos.
        encoding="utf-8",
        errors="replace",
        # 3. Timeout: un proceso ajeno que se cuelga NO puede colgar el cierre.
        timeout=timeout_seconds,
    )
    # 4. Y el código de retorno se mira. Siempre.
    message = (result.stdout or "").strip() or (result.stderr or "").strip()
    return result.returncode, message
```

**Detalles con intención**

- **`capture_output=True` y no `stderr=subprocess.STDOUT`.** Mezclar las dos salidas es cómodo y
  pierde información: el miniproyecto de esta fase depende de poder distinguirlas, porque el
  binario del proveedor escribe errores en las dos.
- **`errors="replace"`** en vez de dejar que reviente: si el proveedor emite un byte raro en un
  mensaje de error, prefiero un carácter de reemplazo a perder el mensaje entero. Es una decisión
  con costo y está escrita.
- **El `timeout` no es opcional.** Sin él, `run` espera indefinidamente. Con él, lanza
  `TimeoutExpired` — y ojo con lo que sigue, porque es la parte que casi nadie hace bien.

> ⚠️ **`TimeoutExpired` mata al hijo, pero no siempre a sus nietos.** Si el programa que invocaste
> lanzó otros procesos, esos pueden quedar vivos. En el cierre de mes eso se ve como una máquina
> que va acumulando procesos zombis cada noche. La solución completa —grupos de procesos— depende
> del sistema operativo y queda fuera del camino base; lo que sí entra es **saber que el problema
> existe** y comprobarlo con `ps` después de un timeout. El ejercicio 22 lo pide.

### 5.3 `argparse` con subcomandos

```python
import argparse
from pathlib import Path


def build_parser() -> argparse.ArgumentParser:
    """La interfaz del CLI. Un solo sitio, y --help sale gratis."""
    parser = argparse.ArgumentParser(
        prog="aur",
        description="Cierre de mes de la red Áurea.",
        epilog="Códigos de salida: 0 todo bien · 1 error de datos · 2 uso incorrecto · 3 el proveedor falló",
    )
    parser.add_argument("--version", action="version", version="aur 0.5.0")

    commands = parser.add_subparsers(dest="command", required=True, metavar="<comando>")

    summary = commands.add_parser("resumen", help="Resumen del mes de una sede.")
    summary.add_argument("--sede", required=True, choices=sorted(BRANCHES),
                         help="Sede de la red.")
    summary.add_argument("--mes", required=True, help="Mes, en formato AAAA-MM.")
    summary.add_argument("--datos", type=Path, default=Path("data"),
                         help="Directorio de los exports (por defecto: ./data)")

    validate = commands.add_parser("validar", help="Valida un lote antes de facturar.")
    validate.add_argument("archivo", type=Path)

    sign = commands.add_parser("firmar", help="Firma el lote con el binario del proveedor.")
    sign.add_argument("directorio", type=Path)
    sign.add_argument("--timeout", type=float, default=30.0,
                      help="Segundos antes de dar por colgado al proveedor.")
    sign.add_argument("--reintentos", type=int, default=1)

    return parser
```

**Detalles con intención**

- **`choices=sorted(BRANCHES)`** hace que `--sede Chapinerp` falle **antes** de leer ningún
  archivo, con un mensaje que lista las diez sedes. Es validación gratis en la frontera, que es la
  idea que la Fase 10 va a convertir en principio.
- **`type=Path`** convierte en el parseo: hacia adentro ya es un `Path` y nadie vuelve a
  preguntárselo. Mismo principio que el `Decimal` de la Fase 03.
- **El `epilog` documenta los códigos de salida** donde alguien los va a leer: en `--help`. Es la
  documentación más barata que existe y la que más se agradece a las dos de la mañana.
- **`required=True` en el subparser**: sin eso, `aur` sin comando no falla, y llega hasta el
  despacho con `command=None`.

### 5.4 Salir limpio

Un cierre de mes puede tardar veinte minutos. Alguien va a apretar `Ctrl-C`, y lo que pase
entonces es parte del diseño, no un accidente:

```python
import signal
import sys

interrupted = False


def request_stop(signum, frame):
    """Marca que hay que parar. NO hace el trabajo de limpiar aquí.

    Un manejador de señal corre en medio de cualquier cosa: si se pone a cerrar
    archivos o a escribir, puede hacerlo a mitad de otra escritura. Lo único
    seguro es levantar una bandera y dejar que el bucle principal reaccione.
    """
    global interrupted
    interrupted = True
    print("\ninterrupción recibida: terminando la factura en curso...", file=sys.stderr)


signal.signal(signal.SIGINT, request_stop)
# SIGTERM es el que manda un cron o un contenedor al detenerse. En Windows no
# existe SIGTERM con esta semántica, así que se registra solo donde aplica.
if hasattr(signal, "SIGTERM"):
    signal.signal(signal.SIGTERM, request_stop)


def sign_batch(invoices, timeout_seconds):
    """Firma el lote, con salida limpia si alguien interrumpe."""
    signed = []
    for invoice in invoices:
        if interrupted:
            print(f"detenido: {len(signed)} de {len(invoices)} facturas firmadas",
                  file=sys.stderr)
            return signed, 130          # 130 es la convención para "terminado por SIGINT"
        ...
    return signed, 0
```

**Detalles con intención**

- **El manejador solo levanta una bandera.** Es la regla de oro de las señales y vale en todos los
  lenguajes: el manejador interrumpe al programa en un punto arbitrario, así que hacer trabajo ahí
  es pedir una corrupción difícil de reproducir.
- **Se termina la unidad en curso, no se corta en seco.** Una factura firmada a medias es peor que
  una sin firmar.
- **`130`** es la convención de shell para un proceso terminado por `SIGINT` (128 + 2). Usarla
  hace que quien invoque tu script desde un `.sh` pueda distinguir "lo cancelaron" de "falló".
- **Y `atomic_write` de la Fase 04 sigue puesto**, que es lo que garantiza que ninguna factura
  quede a medio escribir.

### 5.5 Los códigos de salida del CLI

Un documento de cinco líneas que va en el `--help` y que dentro de diez fases el proceso nocturno
va a leer para decidir si sigue:

| Código | Significa | Qué debería hacer quien lo invoca |
|---|---|---|
| `0` | Todo bien | Seguir |
| `1` | Error de datos: el lote no se puede facturar | Parar y avisarle a Patricia |
| `2` | Uso incorrecto del comando | Parar; es un error de quien invoca |
| `3` | El proveedor externo falló o se colgó | Reintentar más tarde: no es culpa de los datos |
| `130` | Interrumpido por el usuario | No reintentar automáticamente |

**Prueba de fuego**

```bash
python aur_cli.py firmar facturas/ --timeout 5 ; echo "código: $?"
```

Y la mentira que te va a contar la salida si miras el lugar equivocado: **la pantalla**. El
firmador imprime `OK firmado ...` para las facturas que salieron bien, así que la salida se ve
llena de éxitos aunque cuarenta hayan fallado. Lo único que resume la corrida es el código de
salida, y es lo único que el cron va a leer.

**El patrón a memorizar**

> Un proceso hijo es un contrato con tres partes: los argumentos que le pasas, las dos salidas que
> produce, y el código con que termina. Ignorar cualquiera de las tres es confiar en algo que no
> controlas.

---

## 📏 6. Medición — el costo de crear un proceso

**Hipótesis.** Crear un proceso cuesta lo suficiente como para que invocar al firmador una vez por
factura, en vez de una vez por lote, se note en el cierre de mes de Áurea.

**Condiciones.** CPython 3.14.5 · macOS 26.6 · Apple Silicon, 8 núcleos · 200 facturas generadas
con semilla `2026`, de las cuales **166 son medibles** —se excluyen las 34 que el simulador hace
fallar o colgarse a propósito, porque medirían otra cosa— · el firmador simulado de §7 tarda entre
40 y 120 ms por factura, determinado por el NIT, de modo que **el tiempo de trabajo es idéntico en
las dos formas** · mediana de 3 repeticiones · procesos invocados en serie, sin concurrencia
(eso es la Fase 14).

**Competidores.** La misma tarea de dos formas: `subprocess.run` una vez por factura, contra una
sola invocación con `--lote` y las 166 rutas. Las dos escritas bien: con lista de argumentos,
`timeout` y el código revisado.

**Resultado.**

| | Una invocación por factura | Una invocación por lote | Sobrecosto |
|---|---|---|---|
| 10 facturas | 1 198 ms | **889 ms** | +309 ms (1.3×) |
| 50 facturas | 5 975 ms | **4 242 ms** | +1 733 ms (1.4×) |
| 166 facturas | 20 299 ms | **14 300 ms** | **+5 999 ms** (1.4×) |

Y el dato que lo explica: **crear un proceso de Python vacío cuesta 25 ms** (mediana de 30
repeticiones, `python -c "pass"`).

> ⚖️ **Veredicto.** Agrupar ahorra un **30%** del tiempo total del cierre: seis segundos sobre
> las 166 facturas. El sobrecosto por factura es de unos **36 ms** —los 25 del proceso, más la
> tubería, la codificación de la salida y el arranque del propio firmador— y es constante, así que
> crece linealmente con el lote.
>
> **El umbral donde deja de compensar, que es lo que hay que llevarse:** el sobrecosto pesa en
> proporción a lo que dura el trabajo. Con un firmador que tarda ~80 ms por factura, esos 36 ms
> son el 30%. Si el proveedor tardara **dos segundos** por factura —que es perfectamente posible
> con un servicio de sellado remoto—, los mismos 36 ms serían el 1.8% y agrupar dejaría de ser
> una decisión de ingeniería para ser una manía. Y al revés: si el trabajo fuera de 5 ms por
> unidad, el proceso costaría siete veces más que el trabajo y agrupar sería obligatorio.
>
> **Dónde pierde agrupar, y es la razón por la que el miniproyecto no lo exige:** un solo proceso
> para 166 facturas significa que **un cuelgue mata el lote entero**, que el timeout hay que
> calcularlo para el total en vez de por unidad, y que reanudar después de un fallo es mucho más
> difícil — no sabes cuáles alcanzó a firmar. Invocar una por una cuesta seis segundos y te da
> control fino sobre cada fallo. **Para el cierre de mes de Áurea, esos seis segundos son el
> precio correcto**, y eso es exactamente lo contrario de lo que la tabla sugiere si se mira sola.
>
> **Y una advertencia que la tabla no dice:** estos 25 ms son de un proceso de **Python**. Un
> binario nativo pequeño arranca mucho más rápido, y uno de la JVM mucho más lento — el arranque
> en frío de la Fase 00 tenía la JVM en 42 ms. Si el firmador del proveedor fuera un JAR, el
> sobrecosto por factura sería del doble.

**Lo que no se midió:** la variante concurrente —cinco firmadores a la vez—, que es la Fase 14 y
que cambia el veredicto otra vez; el consumo de memoria; y el comportamiento en Windows, donde
crear un proceso es notoriamente más caro que en Unix y donde el antivirus inspecciona cada
proceso nuevo. En Windows la diferencia de esta tabla sería mayor.

---

## 🧱 7. Miniproyecto — *El firmador de facturas*

**El encargo**

Patricia te reenvía un correo del proveedor tecnológico y te escribe encima: *"Esto es lo que uso
para firmar. Se abre una ventana negra, uno arrastra el archivo, y a veces se queda pegada y toca
reiniciar el computador. Son como doscientas facturas al mes y las hago de a una. ¿Se puede
automatizar? El del proveedor dice que sí pero cobra."*

Orquesta el firmador para el lote del mes: con `timeout`, con un reintento, sin `shell=True`, y
con un código de salida que le diga a quien lo llamó desde `cron` si puede seguir.

**Por qué duele**

Porque el binario no es tuyo, no está documentado, y **miente**. Escribe parte de sus errores en
`stdout` y parte en `stderr`, uno de sus "éxitos" devuelve un código distinto de cero, y con
ciertas facturas se cuelga para siempre sin decir nada. Tu programa tiene que producir un
resultado confiable a partir de un componente que no lo es — que es, dicho sea de paso, la
descripción de la mitad del trabajo de integración que vas a hacer en tu vida.

**Datos de entrada**

El binario del proveedor es ficticio, así que el curso trae **su simulador**, con las rarezas del
de verdad. Guárdalo como `firmador_simulado.py` y trátalo como lo que es: un programa ajeno del
que solo conoces su línea de comandos.

```python
"""Simulador del binario firmador del proveedor tecnológico de Áurea.

Esto NO es código de ejemplo a imitar: imita a un programa ajeno, con sus
rarezas reales, para que el miniproyecto de la Fase 05 se pueda hacer sin
tener el binario del proveedor.

Uso:
    python firmador_simulado.py --entrada <archivo.xml> --salida <archivo.xml>
    python firmador_simulado.py --lote <archivo1.xml> <archivo2.xml> ...

Rarezas que imita, todas tomadas de programas de firma reales:
  · escribe parte de sus mensajes en stdout y parte en stderr, sin criterio
  · un "éxito con advertencias" que devuelve código 3, no 0
  · se cuelga con los NIT que terminan en 7 (simula el timeout del servicio)
  · devuelve código 2 para el certificado vencido y 9 para el XML mal formado
  · tarda entre 40 y 120 ms por factura, como el de verdad
"""

import random
import sys
import time
from pathlib import Path


def sign_one(source: Path, target: Path) -> int:
    """Firma un archivo. Devuelve el código de salida del proveedor."""
    if not source.exists():
        print(f"ERR-404 archivo no encontrado: {source}", file=sys.stderr)
        return 9

    content = source.read_text(encoding="utf-8", errors="replace")
    nit = "".join(ch for ch in content if ch.isdigit())[:9] or "000000000"

    # Se cuelga con los NIT terminados en 7. El de verdad se colgaba cuando el
    # servicio de sellado del proveedor no respondía, que era imposible de predecir.
    if nit.endswith("7"):
        print("conectando con el servicio de sellado...", flush=True)
        time.sleep(3600)

    # Certificado vencido: código 2, y el mensaje va a stdout (no a stderr).
    if nit.endswith("3"):
        print(f"ERR-CERT certificado del emisor vencido (NIT {nit})")
        return 2

    # El tiempo depende de la factura y no del proceso: así el resultado es el
    # mismo se invoque una vez por factura o una vez por lote, que es lo que
    # hace que la medición de la fase compare lo que dice comparar.
    random.seed(int(nit))
    time.sleep(random.uniform(0.04, 0.12))
    target.write_text(f"<!-- firmado {nit} -->\n{content}", encoding="utf-8")

    # Éxito con advertencia: código 3. Está firmado, y el que no mire el
    # código de retorno con cuidado va a creer que falló.
    if nit.endswith("5"):
        print(f"WARN-011 firmado con certificado próximo a vencer (NIT {nit})",
              file=sys.stderr)
        return 3

    print(f"OK firmado {target.name}")
    return 0


def main(argv: list[str]) -> int:
    if len(argv) >= 5 and argv[1] == "--entrada" and argv[3] == "--salida":
        return sign_one(Path(argv[2]), Path(argv[4]))

    if len(argv) >= 3 and argv[1] == "--lote":
        worst = 0
        for raw in argv[2:]:
            source = Path(raw)
            code = sign_one(source, source.with_suffix(".firmado.xml"))
            worst = max(worst, code)
        return worst

    print("uso: firmador --entrada <xml> --salida <xml>", file=sys.stderr)
    print("     firmador --lote <xml> [<xml> ...]", file=sys.stderr)
    return 64


if __name__ == "__main__":
    sys.exit(main(sys.argv))
```

Y las 200 facturas del mes:

```python
"""Genera las 200 facturas XML del mes, para el firmador.

Uso:  python generar_facturas.py
"""

import random
from pathlib import Path


def main() -> None:
    random.seed(2026)
    folder = Path("facturas")
    folder.mkdir(exist_ok=True)
    for number in range(200):
        nit = str(random.randint(100_000_000, 999_999_999))
        value = random.randint(50_000, 900_000)
        (folder / f"fac-{number:04d}.xml").write_text(
            f"<factura><nit>{nit}</nit><valor>{value}</valor></factura>\n",
            encoding="utf-8",
        )
    print(f"200 facturas en {folder}/")


if __name__ == "__main__":
    main()
```

**Lo que el proveedor documentó** —y es todo lo que documentó—: `0` es éxito. Cualquier otra cosa,
según el correo, "revísela con soporte".

**Criterios de aceptación**

- [ ] Un solo archivo, `firmar_lote.py`, biblioteca estándar pura, con `argparse`.
- [ ] Firma las 200 facturas y produce un **resumen final**: cuántas firmadas, cuántas con
      advertencia, cuántas fallidas y cuántas colgadas, con el nombre de cada una de las que no
      salieron bien.
- [ ] **Ninguna factura cuelga el proceso.** Las que se cuelgan se abandonan por `timeout`, se
      reportan, y el lote continúa.
- [ ] Las que fallan se reintentan **una vez**, y las que fallan dos veces se reportan como
      definitivas. Las que se cuelgan **no se reintentan** — y tu código tiene que decir por qué
      en un comentario.
- [ ] Distingue el "éxito con advertencia" (código 3) del fallo real. Si tu programa reporta esas
      facturas como fallidas, no pasó.
- [ ] Cero `shell=True`. Todas las rutas con `pathlib`.
- [ ] El código de salida sigue la tabla de §5.5, y un `Ctrl-C` a mitad devuelve `130` sin dejar
      archivos a medias.
- [ ] **Medición:** tiempo total del lote, y cuántos segundos se fueron en las facturas colgadas.
      Esos dos números van en el mensaje del tag. *(Para que puedas comprobarte: de las 200
      facturas, **143 se firman limpias, 23 devuelven advertencia, 14 fallan por certificado
      vencido y 20 se cuelgan**. Si tus cuatro números no suman eso, algo está clasificando mal —
      y lo más probable es que sean las 23 de advertencia contadas como fallos.)*

**Restricciones de registro**

> Esto es un **script**. Un archivo, stdlib pura, `argparse`, funciones sueltas. Nada de
> `class FirmadorService` ni una capa de abstracción "por si mañana cambia el proveedor" — si
> cambia, cambias la función. Es exactamente el reflejo que la Fase 03 atacó.

**La trampa**

El binario escribe parte de sus errores en `stdout` y parte en `stderr`, y **no hay regla**: el
certificado vencido sale por `stdout`, la advertencia por `stderr`. Si construyes tu reporte
leyendo solo una de las dos, vas a perder la mitad de los mensajes — y vas a perderlos en
silencio, que es lo peor.

Y la segunda, que es la que de verdad separa las soluciones: **uno de sus "éxitos" devuelve código
3**. Si tu programa trata todo lo que no sea `0` como fallo, va a reportar como fallidas facturas
que están firmadas y en disco. Patricia las va a volver a mandar, y la aseguradora va a recibir el
duplicado que la Fase 04 te enseñó a detectar.

**Pistas**

<details><summary>Pista 1 — el enfoque</summary>

Antes de escribir el orquestador, **explora el binario**: córrelo a mano contra cinco o seis
facturas distintas y anota qué código devuelve cada una, qué imprime, y en cuál salida. Media
hora de eso ahorra el doble después, y es literalmente lo que harías con un componente ajeno en
el trabajo.

Después clasifica: hay tres clases de resultado —salió bien, falló de una forma que tiene sentido
reintentar, y falló de una forma que no—, y el reintento solo aplica a la del medio.
</details>

<details><summary>Pista 2 — la herramienta</summary>

- [`subprocess.run`](https://docs.python.org/3.14/library/subprocess.html#subprocess.run) con
  `capture_output`, `text`, `encoding` y `timeout`; y
  [`TimeoutExpired`](https://docs.python.org/3.14/library/subprocess.html#subprocess.TimeoutExpired),
  cuyo objeto trae la salida parcial que alcanzó a producir el hijo.
- [`argparse`](https://docs.python.org/3.14/library/argparse.html) para `--timeout`,
  `--reintentos` y el directorio.
- [`pathlib`](https://docs.python.org/3.14/library/pathlib.html) para recorrer y derivar nombres.
- Y el `atomic_write` de la Fase 04, si decides escribir un archivo de reporte.
</details>

<details><summary>Pista 3 — el esqueleto</summary>

```python
from enum import Enum

class Outcome(Enum):
    """Las cuatro cosas que le pueden pasar a una factura."""
    SIGNED = "firmada"
    WARNED = "firmada con advertencia"
    FAILED = "falló"
    HUNG = "se colgó"

def sign_one(source, target, timeout) -> tuple[Outcome, str]:
    """Una factura. No lanza: clasifica."""

def sign_batch(sources, timeout, retries) -> dict[Outcome, list[tuple[Path, str]]]:
    """El lote, con reintentos donde corresponde."""

def exit_code_for(results) -> int:
    """La tabla de §5.5, aplicada al resultado del lote."""
```

`Enum` no ha salido en el curso y está en la caja: `from enum import Enum`. Cuatro líneas, y es
la primera vez que una constante con nombre gana de verdad sobre una cadena.
</details>

**Cómo se entrega**

```bash
python generar_facturas.py
python firmar_lote.py facturas/ --timeout 5 --reintentos 1 ; echo "código: $?"
```

```bash
git add firmar_lote.py firmador_simulado.py generar_facturas.py
git commit -m "fase 05 mini: orquestador del firmador del proveedor"
git tag -a mini-05 -m "Mini F5: firmador de lote · 200 facturas en <N> s, <M> s perdidos en cuelgues"
```

<details><summary>💡 Solución de referencia — las decisiones, y la trampa entera</summary>

**La decisión de diseño que se tomó.** Clasificar en cuatro resultados en vez de en dos —bien o
mal—, y tratar el `timeout` como una categoría propia. El otro camino defendible es tratar el
cuelgue como un fallo más y reintentarlo: es más simple y es lo que hace casi todo el mundo. Se
descartó por una razón que se puede defender con el número de la medición: **cada cuelgue cuesta
el timeout completo**, así que reintentar un cuelgue con 5 segundos de timeout convierte 20
facturas colgadas en 200 segundos perdidos en vez de 100. Un fallo rápido se reintenta; un cuelgue,
no.

**La trampa, entera.** Las dos mitades son la misma lección: **el contrato de un proceso son tres
cosas y hay que leer las tres.** El código de retorno solo, mal interpretado, convierte éxitos en
fallos —el código 3—. Las salidas solas, sin el código, no te dicen si el archivo quedó escrito.
Y una de las dos salidas sola pierde la mitad de los mensajes. La única lectura correcta es
combinar las tres, y por eso `sign_one` devuelve la clasificación **y** el mensaje.

Y hay un detalle que vale oro y que solo aparece midiendo: cuando `TimeoutExpired` se lanza, el
objeto de la excepción **trae la salida parcial** que el hijo alcanzó a producir (`error.stdout`).
En este caso trae `conectando con el servicio de sellado...`, que es exactamente la información
que necesitas para decirle al proveedor dónde se cuelga su programa. Tirarla y reportar solo "se
colgó" es perder la única pista que había.

**Qué se habría hecho distinto si el registro fuera otro.** Como herramienta —Bloque B— esto
tendría el timeout y los reintentos en configuración, un reporte en CSV para Patricia, y pruebas
con un firmador falso inyectado. Como aplicación, el firmado sería una tarea de cola con su
reintento y su *backoff* (Fase 15), y el cuelgue lo detectaría el propio sistema de colas en vez
de un `timeout` en el código — que es mejor, y que Áurea no necesita para doscientas facturas al
mes.
</details>

---

## 🧪 8. Ejercicios (25)

**🟢 Fácil (1–6)**

1. Reescribe con `pathlib` todas las manipulaciones de ruta que hayas hecho con cadenas en las
   fases anteriores. Cuenta cuántas eran.
2. Escribe un script que liste todos los CSV de `data/` ordenados por tamaño, usando solo
   `pathlib`. Sin `os`, sin `glob` del módulo `glob`.
3. Invoca al firmador simulado contra una factura y muestra por separado su `stdout`, su `stderr`
   y su `returncode`. Prueba con cinco facturas distintas y anota qué encontraste.
4. Toma un `subprocess.run` sin `timeout` y demuestra que se cuelga con una factura de NIT
   terminado en 7. Después agrégalo y demuestra que ya no.
5. Convierte el despacho de comandos del CLI a `argparse` y comprueba que `aur --help` y
   `aur resumen --help` producen ayudas distintas sin que hayas escrito ninguna.
6. Haz que el CLI falle con `--sede Chapinerp` **antes** de abrir ningún archivo. Copia el mensaje
   que genera `argparse`.

**🟡 Intermedio (7–14)**

7. Escribe un `subprocess.run` que le pase una variable de entorno al hijo sin modificar la del
   padre. Demuéstralo imprimiéndola desde el hijo.
8. Usa `tempfile.TemporaryDirectory` para que el firmador escriba en un directorio temporal que se
   borra solo. Demuestra que se borra incluso si el bloque lanza.
9. Consulta la documentación de `subprocess` y averigua la diferencia entre `run`, `Popen` y
   `check_output`. Escribe en qué caso de Áurea usarías cada uno.
10. Conecta dos procesos —la salida de uno a la entrada del otro— **sin `shell=True`**. Es el
    equivalente de una tubería de shell y está documentado.
11. Escribe un script que lea de `stdin` y escriba en `stdout`, y úsalo en una tubería real desde
    la terminal. Comprueba que funciona con `cat archivo | python script.py`.
12. Averigua qué hace `subprocess.run(..., cwd=...)` y úsalo para invocar al firmador desde otro
    directorio sin cambiar el del proceso padre. Explica por qué eso es mejor que `os.chdir`.
13. Haz que tu script detecte si su `stdout` es una terminal o una tubería
    (`sys.stdout.isatty()`) y cambie el formato de salida en consecuencia. Es lo que hacen `ls` y
    `git`.
14. Usa `argparse` con `type=` personalizado: un tipo que acepte `2026-03` y devuelva una tupla
    `(año, mes)`, rechazando lo demás con un mensaje en español.

**🟠 Difícil (15–21)**

15. **Diagnóstico.** Un script de cierre reporta éxito y no firma nada. Hay tres causas posibles y
    las tres están en esta fase. Reprodúcelas y da el comando que diagnostica cada una.
16. **Diagnóstico.** Tu script funciona en macOS y en Windows falla con un `FileNotFoundError`
    sobre una ruta que claramente existe. Enumera las tres causas más probables —una tiene que ver
    con la longitud de la ruta y otra con el separador— y cómo confirmarlas.
17. **Medición.** Reproduce la tabla de la sección 6 en tu máquina. Después mide qué pasa si en
    vez de un proceso de Python invocas uno nativo pequeño —`/bin/true` o `cmd /c exit`— y explica
    la diferencia.
18. **Medición.** Mide cuánto cuesta `capture_output=True` contra dejar que el hijo escriba
    directo a la terminal, sobre 100 invocaciones. Explica de dónde sale la diferencia.
19. **Medición.** Cronometra el lote completo con timeouts de 2, 5 y 30 segundos. Las facturas
    que se cuelgan son 20: calcula el tiempo perdido en cada caso y decide qué timeout dejarías,
    sabiendo que un firmado legítimo tarda 120 ms como máximo.
20. **De registro.** El proveedor ofrece una API HTTP en vez del binario, por una tarifa mensual.
    Decide qué cambiaría en tu solución, en qué registro quedaría, y qué le responderías a Julián
    con números — el binario tarda 20 segundos para el lote del mes.
21. **De registro.** Yuli pregunta si puede firmar ella las facturas de su sede sin llamar a
    Patricia. Decide si eso cambia el registro de la herramienta y qué haría falta. Guarda la
    respuesta: la Fase 09 la contesta.

**🔴 Muy difícil (22–25)**

22. **Adversarial.** Provoca un timeout y después comprueba con `ps` si quedó algún proceso hijo
    vivo. Si quedó, investiga los grupos de procesos de tu sistema operativo y propón —no hace
    falta implementarlo— cómo lo cerrarías. Documenta lo que encontraste.
23. **Adversarial.** Demuestra la inyección de comandos: escribe una versión con `shell=True` y un
    nombre de archivo malicioso que ejecute algo inofensivo pero visible (crear un archivo, no
    borrar nada). Después demuestra que con la lista de argumentos el mismo nombre no hace nada.
    **Hazlo en un directorio temporal.**
24. **Defiende una decisión.** Un colega dice que esto era un script de shell de veinte líneas y
    que Python está de más. Para el caso del firmador, tiene parte de razón. Escribe el `.sh`
    equivalente, compáralo honestamente —líneas, portabilidad a Windows, manejo del código 3,
    reporte final— y di cuándo elegirías cada uno.
25. **Diseño y medición.** El cierre de mes tarda 20 segundos con 200 facturas. Áurea crece 20% al
    año y el proveedor no va a mejorar. Calcula en qué año esto deja de caber en una ventana
    razonable, y diseña la solución **sin usar concurrencia** —que es la Fase 14—. Hay al menos
    dos respuestas, y una de ellas no es técnica.

**🔥 Opcionales**

- Averigua qué es `shlex.quote` y por qué existe, sabiendo que este curso prohíbe `shell=True`.
  Es la respuesta a "¿y si de verdad no tengo alternativa?".
- Investiga `os.spawn*`, `multiprocessing` y `concurrent.futures` como formas alternativas de
  lanzar trabajo, y anota cuál resolvería el ejercicio 25. La Fase 14 las retoma.
- Escribe un context manager que mida y reporte el tiempo de cada proceso hijo, y aplícalo al lote
  entero. Junta lo de la Fase 04 con lo de esta.

---

## 📚 9. Referencias

**Documentación oficial**

- [`pathlib`](https://docs.python.org/3.14/library/pathlib.html) — la referencia completa, con la
  tabla de correspondencia con `os.path` al final, que es muy útil para leer código viejo.
- [`subprocess`](https://docs.python.org/3.14/library/subprocess.html) — en particular *Security
  Considerations* y *Frequently Used Arguments*.
- [`argparse`](https://docs.python.org/3.14/library/argparse.html) y el
  [tutorial de argparse](https://docs.python.org/3.14/howto/argparse.html) — empieza por el
  segundo.
- [`signal`](https://docs.python.org/3.14/library/signal.html) — y sobre todo las advertencias
  sobre qué se puede y qué no se puede hacer dentro de un manejador.
- [`tempfile`](https://docs.python.org/3.14/library/tempfile.html) — archivos y directorios
  temporales que se limpian solos.
- [`os` — variables de entorno y procesos](https://docs.python.org/3.14/library/os.html).

**PEPs**

- [PEP 428](https://peps.python.org/pep-0428/) — `pathlib`, y la discusión sobre el operador `/`
  que hoy parece obvio y en su momento no lo era.

**Orden de lectura sugerido.** Antes de escribir: el tutorial de `argparse`, que son veinte
minutos y ahorran el doble. Durante: `subprocess`, consultado por argumento, y la sección de
seguridad entera. Después: las advertencias de `signal`, que se entienden mejor cuando ya
escribiste un manejador.

> ⚠️ URLs y contenidos cambian; fija 3.14 en el selector de la documentación.

---

## 🚀 10. Cierre y conexión con la siguiente fase

El script dejó de ser un programa que lee y escribe archivos. Ahora **invoca a otros programas,
sobrevive a que se cuelguen, entiende sus tres canales de comunicación, y le reporta a quien lo
llamó si puede seguir**. Eso es un ciudadano del sistema operativo, y es lo que el Bloque A venía
a demostrar: no hizo falta un `.sh`, ni un `.bat`, ni una biblioteca.

Y te llevas una regla que vale para cualquier integración con algo que no controlas: **el contrato
de un proceso son tres cosas —argumentos, salidas y código de retorno— y hay que leer las tres.**
En la Fase 13 vas a encontrar la misma idea con otro vestido, cuando lo que no controlas sea un
servicio HTTP.

La **Fase 06** cierra el Bloque A y **paga la deuda 💸 de la Fase 01**. Entran `csv` con sus
dialectos y sus comillas, `json`, `tomllib` para la configuración —que es donde las tasas de los
aliados dejan de ser código—, `sqlite3` como almacén local de verdad, y `zipfile`. Y entra el
encoding donde duele: el `latin-1` del export de Odontovía y el BOM que mete Excel. La factura de
la deuda se lee con un `git diff fase-01 fase-06`, y es la primera vez que el curso cobra uno de
sus propios atajos.

> **La señal de que quedó bien:** la próxima vez que alguien te pase un binario sin documentar,
> tu primer gesto no va a ser leer el correo del proveedor — va a ser correrlo seis veces con
> entradas distintas y anotar qué devuelve.

> 🏷️ **No cierres la fase sin el tag.** Con el checklist de la sección 2 en verde, el
> miniproyecto corriendo y `git status` limpio:
>
> ```bash
> git tag -a fase-05 -m "F5 cerrada:
> - pathlib en todas las rutas; ninguna concatenación de cadenas
> - subprocess con lista de argumentos, timeout y código de retorno revisado
> - shell=True entendido, demostrado y prohibido para el resto del curso
> - argparse con subcomandos, tipos y ayuda generada
> - Ctrl-C sale con 130 sin dejar archivos a medias
> - el lote de 200 facturas se firma, se clasifica en cuatro resultados y se reporta"
> ```
>
> Los commits de la fase llevan su prefijo (`fase 05: …`), los de ejercicio su número
> (`fase 05 ej12: …`) y el miniproyecto el suyo (`fase 05 mini: …`). El miniproyecto terminado
> lleva además su tag anotado `mini-05`, y **en el mensaje de ese tag va el número que arrojó su
> medición**. La convención completa está en
> [`00-convencion-de-git-y-tags.md`](00-convencion-de-git-y-tags.md).
