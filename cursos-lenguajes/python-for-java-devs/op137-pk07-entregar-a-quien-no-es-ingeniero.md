# 🎁 pk07 — Entregar a quien no es ingeniero

> Python para desarrolladores Java senior · **Carta** · Track `pk` — El panorama de gestores y
> empaquetado · sección 7 de 8
> Se lee suelta: no hace falta ninguna otra sección de la carta.
> Versiones verificadas contra PyPI el 05/10/2026 · Código probado el 05/10/2026 con Python 3.14.7,
> en contenedor: las salidas son las de esa corrida.

---

## 🎯 1. Qué problema resuelve

La herramienta que genera el reporte de regalías tiene que correr en el computador de Patricia y en el de Édgar Rojas en Suba. Ninguno de los dos va a crear un
entorno virtual. El camino base midió las cinco formas de entregar una herramienta de Python (`BENCHMARKS.md` §09) y eligió `uv tool`; pero lo midió con una
herramienta **sin dependencias de terceros**, y lo dijo: es un dato que favorece a las opciones basadas en un archivo.

Esta sección mide lo que faltaba: la misma herramienta **con dependencias**, una de ellas compilada en C (`orjson`). Ahí aparecen las diferencias que importan: un
`.pyz` de `zipapp` no puede llevar una extensión compilada; **`shiv`** y **`pex`** sí, al costo de que el archivo es para una plataforma; y un *script* con PEP 723
resuelve las dependencias la primera vez que corre, con lo que eso implica para un computador sin internet.

---

## 🧠 2. El modelo

| Forma | Lleva las dependencias | Necesita Python instalado | Es para una plataforma | La primera ejecución |
|---|---|---|---|---|
| `uv tool install` / `pipx` | Sí, en su propio entorno | No (`uv`) / Sí (`pipx`) | No: se instala en cada máquina | Instala |
| `.pyz` de `zipapp` | **Solo Python puro** | Sí | No | Inmediata |
| `.pyz` de **`shiv`** | Sí, también compiladas | Sí | **Sí**, si hay compiladas | Desempaqueta a un caché |
| `.pex` | Sí, también compiladas | Sí | **Sí**, si hay compiladas | Desempaqueta a un caché; arranque lento (medido abajo) |
| *Script* PEP 723 con `uv run` | Las resuelve al correr | No (`uv`) | No | **Descarga e instala** |
| Congelado (PyInstaller) | Sí, y el intérprete | **No** | Sí | `--onefile` desempaqueta cada vez (§09: 3 s) |

### Tu instinto de Java dice… y esta vez se equivoca

En Java, un *fat jar* lleva todas las dependencias y corre en cualquier plataforma con una JVM, porque todo es *bytecode*. El instinto espera lo mismo de un `.pyz`:
un archivo, todas las dependencias, cualquier máquina. Con dependencias en Python puro, casi; con una sola extensión compilada (`orjson`, `psycopg`, `numpy`), el
archivo queda atado a la plataforma y la versión de Python donde se construyó.

---

## 💻 3. El ejemplo que corre

La herramienta, `regalias/regalias.py`:

```python
"""Reporte de regalías: lee un JSON de ventas y escribe el total por franquicia."""

import sys

import httpx  # noqa: F401  — para la versión que baja las ventas; aquí solo cuenta como dependencia pura
import orjson


def main() -> None:
    ventas = orjson.loads(sys.argv[1] if len(sys.argv) > 1 else '{"Suba": 142900000, "Zipaquirá": 61750000}')
    print(orjson.dumps({sede: round(v * 0.045) for sede, v in ventas.items()}).decode())


if __name__ == "__main__":
    main()
```

`regalias_pep723.py` —el mismo *script*, con sus dependencias declaradas en línea—:

```python
# /// script
# requires-python = ">=3.12"
# dependencies = ["httpx", "orjson"]
# ///
import sys

import orjson

ventas = orjson.loads(sys.argv[1] if len(sys.argv) > 1 else '{"Suba": 142900000, "Zipaquirá": 61750000}')
print(orjson.dumps({sede: round(v * 0.045) for sede, v in ventas.items()}).decode())
```

`entregar.sh` construye y mide cada forma (arranque: la mediana de cinco ejecuciones, después de una primera de calentamiento):

```bash
set -euo pipefail
median_ms() { for _ in 1 2 3 4 5; do s=$(date +%s%N); "$@" >/dev/null; echo $(( ($(date +%s%N) - s) / 1000000 )); done | sort -n | sed -n 3p; }

python3 -m zipapp regalias -m regalias:main -o regalias-zipapp.pyz
python3 regalias-zipapp.pyz 2>&1 | tail -1 | cut -c1-60 || true

shiv -q -o regalias-shiv.pyz -e regalias:main --site-packages regalias httpx orjson 2>/dev/null
pex httpx orjson -D regalias -e regalias:main -o regalias.pex >/dev/null 2>&1

for f in regalias-shiv.pyz regalias.pex; do
  python3 "$f" >/dev/null                                          # primera ejecución: desempaqueta
  printf '%-18s %6s KB · arranque %4s ms · %s\n' "$f" "$(( $(stat -c %s "$f") / 1024 ))" "$(median_ms python3 "$f")" "$(python3 "$f")"
done

rm -rf ~/.cache/uv
s=$(date +%s%N); uv run --quiet regalias_pep723.py >/dev/null; first=$(( ($(date +%s%N) - s) / 1000000 ))
printf '%-18s primera vez %5s ms (descarga) · después %4s ms\n' "PEP 723 (uv run)" "$first" "$(median_ms uv run --quiet regalias_pep723.py)"
unzip -l regalias.pex | grep -o 'orjson[^/]*\.whl\|orjson-[^/]*/orjson[^/]*\.so' | head -1
```

```bash
pip install shiv pex uv
bash entregar.sh
```

Salida (Python 3.14.7, 05/10/2026) (los milisegundos son de la máquina que corre):

```text
ModuleNotFoundError: No module named 'httpx'
regalias-shiv.pyz     700 KB · arranque   90 ms · {"Suba":6430500,"Zipaquirá":2778750}
regalias.pex         1700 KB · arranque  801 ms · {"Suba":6430500,"Zipaquirá":2778750}
PEP 723 (uv run)   primera vez  1408 ms (descarga) · después   32 ms
orjson-3.12.0-cp314-cp314-manylinux_2_17_aarch64.manylinux2014_aarch64.whl
```

El `.pyz` de `zipapp` pesa 758 bytes y no corre: no lleva las dependencias, y falla en el primer `import` de terceros. `shiv` y `pex` sí funcionan, con dos
sorpresas que §09 no podía mostrar. La primera, el arranque: **`shiv` arranca en 90 ms y `pex` en 801**, nueve veces más, porque `pex` revisa en cada ejecución su
entorno y vuelve a lanzar el intérprete antes de correr el código. La segunda, la etiqueta de la rueda de `orjson` dentro del `.pex`: **`cp314`, `manylinux`,
`aarch64`**. Ese archivo corre con Python 3.14, en Linux, en ARM; en el Windows de Patricia, no. El *script* PEP 723 tardó 1,4 s la primera vez, descargando, y
32 ms después, desde el caché de `uv`.

**Detalles con intención**

- **El `.pyz` de `zipapp` falla** en el primer `import` de terceros: `zipapp` empaqueta la carpeta, no las dependencias. Y aunque se las copiaran adentro, Python no
  puede cargar una extensión compilada (`.so`) desde un zip. Es el límite que el camino base no vio porque su herramienta no tenía dependencias.
- **`shiv` y `pex` llevan las dependencias**, incluida la rueda compilada de `orjson` para la plataforma donde se construyeron, y la desempaquetan a un caché la
  primera vez. La etiqueta de la rueda dice para qué máquina es el archivo.
- **PEP 723 no lleva nada**: declara. La primera ejecución descarga e instala `httpx` y `orjson` (y necesita internet); las siguientes usan el caché de `uv`.
- **El arranque se mide después de una ejecución de calentamiento**, para no mezclar el desempaquetado inicial con el arranque de todos los días.

---

## ⚠️ 4. Lo que se rompe

**El `.pyz` construido en el portátil y entregado a Windows.** Con dependencias compiladas, el archivo es para la plataforma, la arquitectura y la versión de Python
donde se construyó. Se construye uno por plataforma, en el CI, o se elige una forma que instala en cada máquina.

**PEP 723 sin internet.** El computador de Édgar en Suba a veces no tiene red. La primera ejecución falla; una vez cacheado, funciona. Se "precalienta" en la instalación, o
se elige otra forma.

**El caché de `shiv` y `pex` que crece.** Cada versión desempaqueta en un directorio nuevo del caché del usuario, y nadie lo limpia. Se fija la ruta y se limpia al
actualizar.

**El congelado con antivirus.** Un ejecutable de PyInstaller sin firmar se parece a lo que hace el *malware* empaquetado igual (`ui09`).

---

## ⚖️ 5. Cuándo NO usar cada una

**`zipapp` con dependencias compiladas.** No funciona; para Python puro, sigue siendo la forma más liviana.

**`shiv` o `pex` para máquinas de plataformas distintas.** Un archivo por plataforma deja de ser "un archivo"; `uv tool` instala en cada una.

**`pex` para algo que se ejecuta muchas veces seguidas.** 801 ms por ejecución contra 90 de `shiv`: en un *script* que corre una vez al día no importa; en uno que
llama otro programa por cada archivo, sí.

**PEP 723 para alguien sin `uv` ni internet.** Es la forma más cómoda para el ingeniero, no para Patricia.

---

## 🧪 6. Ejercicios (10)

**🟢 Fácil (1–3)**

1. Corre la medición. **Criterio:** la tabla, y por qué falló el `.pyz` de `zipapp`.
2. Quita `orjson` de la herramienta (usa `json`) y vuelve a construir con `zipapp`. **Criterio:** funciona, y el tamaño contra los otros.
3. Lista el contenido del `.pex`. **Criterio:** encuentras la rueda de `orjson` y su etiqueta de plataforma.

**🟡 Intermedio (4–6)**

4. Construye el `.pex` para dos plataformas (`--platform`). **Criterio:** un archivo que corre en Linux x86 y en Linux ARM.
5. Instala la herramienta con `uv tool install` y con `pipx`. **Criterio:** el tiempo de cada uno y dónde quedó cada entorno.
6. Corre el *script* PEP 723 sin red después de haberlo corrido con red. **Criterio:** funciona desde el caché; con el caché borrado, el error exacto.

**🟠 Difícil (7–9)**

7. Congela la herramienta con PyInstaller `--onedir` y compara con la cifra de §09 (sin dependencias). **Criterio:** cuánto agregan las dependencias al tamaño y al arranque.
8. Construye en el CI un `.pex` para Linux y uno para macOS. **Criterio:** los dos artefactos publicados con su plataforma en el nombre.
9. Agrega a la herramienta una comprobación de versión al arrancar contra un archivo publicado (`ui09`). **Criterio:** una versión vieja avisa.

**🔴 Muy difícil (10)**

10. Decide cómo llega la herramienta de regalías a Patricia y a Édgar. **Criterio:** una página. *Rúbrica:* (a) sus sistemas operativos y si tienen internet; (b) la forma elegida,
    con las cifras de esta sección y de §09; (c) cómo se actualiza; (d) qué pasa el día que no funciona.

---

## 📚 7. Referencias

**Documentación oficial**

- `zipapp`: https://docs.python.org/3/library/zipapp.html
- `shiv`: https://shiv.readthedocs.io/en/latest/
- `pex`: https://docs.pex-tool.org/
- PEP 723: https://peps.python.org/pep-0723/

**Orden de lectura sugerido:** la documentación de `zipapp`, en especial la limitación con extensiones compiladas; después la de `pex` sobre plataformas.

---

## 🚀 8. Cierre

Con dependencias de terceros, las formas de entregar se separan: `zipapp` no lleva dependencias y no puede con extensiones compiladas; `shiv` (90 ms) y `pex` (801 ms) sí,
pero el archivo queda atado a una plataforma; PEP 723 no lleva nada y descarga la primera vez; `uv tool` instala en cada máquina y se actualiza con un comando. La elección sale de los computadores de
quienes lo van a usar, no de la herramienta.

**La señal de que quedó bien:** *"Édgar corre el reporte de regalías en Suba sin internet, y la versión que tiene es la que creemos que tiene."*

> 🏷️ **Cierra la sección con su tag**, cuando los ejercicios que elegiste estén hechos:
>
> ```bash
> git tag -a op-pk-fase-07 -m "op pk07 cerrada: entregar con dependencias compiladas, medido"
> ```
>
> Los commits llevan su prefijo (`op pk07: …`) y los de ejercicio su número
> (`op pk07 ej07: …`).
