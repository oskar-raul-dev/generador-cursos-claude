# ⚖️ sy08 — Veredicto: dónde deja de servir el script de shell

> Python para desarrolladores Java senior · **Carta** · Track `sy` — El sistema operativo, los
> procesos y los archivos en movimiento · sección 8 de 8
> Se lee suelta: no hace falta ninguna otra sección de la carta, aunque esta cierra el track y
> enlaza a las siete anteriores.
> Versiones verificadas contra PyPI el 05/10/2026 · Código probado el 05/10/2026 con Python 3.14.7,
> en contenedor: las salidas son las de esa corrida.

---

## 🎯 1. Qué problema resuelve

El track recorrió `subprocess` ([`sy01`](op115-sy01-subprocess-a-fondo.md)), sus envolturas ([`sy02`](op116-sy02-las-envolturas.md)), la inspección del
sistema ([`sy03`](op117-sy03-inspeccion-del-sistema.md)), el sistema de archivos ([`sy04`](op118-sy04-el-sistema-de-archivos.md)), los cambios en carpetas
([`sy05`](op119-sy05-reaccionar-a-cambios.md)), systemd ([`sy06`](op120-sy06-convivir-con-el-sistema.md)) y los respaldos
([`sy07`](op121-sy07-sincronizacion-y-respaldo.md)). Su tesis era Python como **reemplazo honesto del script de shell de 400 líneas que nadie se atreve a
tocar**.

Honesto quiere decir que el veredicto no es "reemplaza todo el shell por Python". Un script de diez líneas que encadena tres comandos es la herramienta
correcta, y reescribirlo en Python lo empeora. La pregunta es **dónde está la línea**, y esta sección la busca con un experimento concreto: la misma
tarea —contar las filas de cada lote de la aseguradora— en bash escrito como se escribe, en bash escrito con cuidado, y en Python, sobre los nombres de
archivo que llegan en la vida real.

---

## 🧠 2. El modelo

| Señal | Hacia el shell | Hacia Python |
|---|---|---|
| Tamaño | Pocas líneas que encadenan programas | Más de una pantalla, o creciendo |
| Datos | Texto que pasa de un programa a otro | Estructuras: diccionarios, listas, JSON, fechas |
| Errores | "Si falla, que pare" alcanza | Hay que decidir qué hacer con cada error |
| Nombres de archivo | Controlados por quien escribe el script | **Llegan de afuera**: espacios, saltos de línea, guiones |
| Pruebas | Nadie las va a escribir | Hacen falta |
| Quién lo mantiene | Quien sabe bash | El equipo, que sabe Python |

### Tu instinto de Java dice… y esta vez se equivoca

El instinto de quien viene de Java es desconfiar del shell y escribir todo en el lenguaje "de verdad". Para pegar tres comandos en un cron, el shell es más
corto, más claro y no tiene dependencias; el error es el contrario —dejar que el script de diez líneas crezca hasta cuatrocientas sin darse cuenta—. La
señal no es el lenguaje, es lo que el script empezó a hacer.

---

## 💻 3. El ejemplo que corre

La carpeta de la aseguradora, con los nombres que de verdad llegan: un espacio, un salto de línea, un guion al principio.

`ingenuo.sh` —como se escribe la primera vez—:

```bash
for f in $(ls entrada); do
  echo "$f: $(wc -l < entrada/$f)"
done | sort
```

`cuidadoso.sh` —como se escribe después del primer incidente—:

```bash
set -euo pipefail
find entrada -maxdepth 1 -type f -name '*.csv' -print0 |
  while IFS= read -r -d '' f; do
    printf '%s: %s\n' "$(basename -- "$f")" "$(wc -l < "$f")"
  done | sort
```

`contar.py`:

```python
"""La misma tarea en Python, y el experimento que compara las tres versiones."""

import pathlib
import shutil
import subprocess

INBOX = pathlib.Path("entrada")
shutil.rmtree(INBOX, ignore_errors=True)
INBOX.mkdir()
for name, rows in [("lote 1.csv", 3), ("lote\n2.csv", 5), ("-n.csv", 7), ("normal.csv", 2)]:
    (INBOX / name).write_text("".join(f"fila {i}\n" for i in range(rows)))
expected = {"lote 1.csv": 3, "lote\n2.csv": 5, "-n.csv": 7, "normal.csv": 2}


def with_python() -> dict[str, int]:
    return {p.name: sum(1 for _ in p.open()) for p in INBOX.glob("*.csv")}


print("python:     ", "correcto" if with_python() == expected else with_python())
for script in ("ingenuo.sh", "cuidadoso.sh"):
    r = subprocess.run(["bash", script], capture_output=True, text=True)
    ok = sum(f"{name}: {rows}" in r.stdout for name, rows in expected.items())
    print(f"{script:<12} {ok} de {len(expected)} lotes bien · código {r.returncode} · errores: {len(r.stderr.splitlines())} líneas")

# El paso que falla en medio de una tubería: ¿se entera el script?
for flags in ("", "set -euo pipefail; "):
    r = subprocess.run(["bash", "-c", flags + "cat no-existe.csv | wc -l; echo 'siguió como si nada'"],
                       capture_output=True, text=True)
    print(f"tubería con error {'con' if flags else 'sin'} pipefail: código {r.returncode} · {r.stdout.split()}")
```

```bash
python3 contar.py
```

Salida (Python 3.14.7, 05/10/2026):

```text
python:      correcto
ingenuo.sh   2 de 4 lotes bien · código 0 · errores: 4 líneas
cuidadoso.sh 3 de 4 lotes bien · código 0 · errores: 0 líneas
tubería con error sin pipefail: código 0 · ['0', 'siguió', 'como', 'si', 'nada']
tubería con error con pipefail: código 1 · ['0']
```

Python contó bien los cuatro lotes sin hacer nada especial. El bash ingenuo contó bien dos, imprimió cuatro líneas de error y **terminó con código 0**:
el cron lo habría dado por exitoso. Y el bash cuidadoso, con todos sus trucos, contó bien **tres**: el lote con un salto de línea en el nombre lo rompió
el `sort` del final, que ordena líneas y partió ese nombre en dos. Arreglarlo exige un séptimo truco (`printf '%s\0'` y `sort -z`). La última pareja de
líneas es la otra mitad del veredicto: sin `pipefail`, una tubería cuyo primer comando falla termina con código 0 y el script sigue; con `pipefail`, se
detiene.

**Detalles con intención**

- **`for f in $(ls ...)`** parte los nombres por espacios y saltos de línea: `lote 1.csv` se vuelve dos "archivos" que no existen. Es la línea de bash más
  escrita y más rota.
- **`-n.csv`** es un nombre que empieza con guion: un programa que lo recibe sin `--` lo interpreta como opción. `basename -- "$f"` y `wc -l < "$f"` lo evitan.
- **La versión cuidadosa casi funciona**, y para escribirla hace falta saber `-print0`, `IFS=`, `read -r -d ''`, las comillas dobles y `--`. Cada una corrige un
  incidente distinto; olvidar una reabre el incidente —y el `sort` del final, que el borrador de esta sección daba por inofensivo, era la que faltaba—.
- **Sin `pipefail`**, el código de salida de una tubería es el del **último** comando: `cat` falla, `wc` cuenta cero líneas y termina bien, y el script sigue.

---

## ⚠️ 4. Lo que se rompe

**El script que crece sin que nadie lo decida.** Empezó con tres líneas en un cron; dos años después tiene cuatrocientas, funciones, un arreglo asociativo y un
`case` de cincuenta ramas. En algún punto de ese camino debió pasar a Python, y el mejor momento era la primera vez que necesitó una estructura de datos.

**Reescribir en Python un script que funciona.** El script de diez líneas que respalda una base con `pg_dump | gzip` y lleva cinco años sin fallar no mejora en
Python. Se reescribe lo que tiene incidentes o lo que hay que cambiar.

**El Python que llama al shell para todo.** Un Python con veinte `subprocess.run(..., shell=True)` es un script de shell con más pasos y los problemas de los dos
(`sy01`). Si se pasa a Python, se usan `pathlib`, `shutil` y las bibliotecas.

---

## ⚖️ 5. Cuándo NO usar este veredicto

**En un equipo que sabe bash mejor que Python.** Las señales cambian: quien lo mantiene es parte de la decisión.

**Para herramientas que ya resuelven el problema.** Si el "script" es en realidad orquestación de trabajos con dependencias, la respuesta no es ni bash ni un
script de Python: es un orquestador (`wf`).

---

## 🧪 6. Ejercicios (8)

**🟢 Fácil (1–2)**

1. Corre el ejemplo. **Criterio:** explicas qué lotes rompió la versión ingenua y por qué.
2. Agrega un lote llamado `$(touch hackeado).csv` y corre las dos versiones de bash. **Criterio:** describes si alguna ejecutó el comando (en un directorio de
   prueba).

**🟡 Intermedio (3–4)**

3. Escribe una prueba con `pytest` que corra los tres y falle si alguno no cuenta bien los cuatro lotes. **Criterio:** la ingenua falla, las otras dos pasan.
4. Busca en un servidor tuyo los *scripts* de shell que usan `$(ls` o `for f in $(…)`. **Criterio:** la lista, con el riesgo de cada uno.

**🟠 Difícil (5–6)**

5. Toma un *script* de shell real de más de 100 líneas y aplícale las señales de §2. **Criterio:** la decisión de dejarlo o migrarlo, con su razón.
6. Pasa `shellcheck` sobre `ingenuo.sh`. **Criterio:** qué avisos da y cuál de ellos habría evitado cada error del ejemplo.

**🔴 Muy difícil (7–8)**

7. Escribe la política de *scripts* de Áurea. **Criterio:** una página. *Rúbrica:* (a) cuándo se escribe en shell y cuándo en Python; (b) las reglas mínimas
   del shell (`set -euo pipefail`, `shellcheck`); (c) cuándo un *script* se migra; (d) cómo se prueban los dos.
8. Migra a Python el *script* de shell más largo que tengas. **Criterio:** las dos versiones. *Rúbrica:* (a) líneas de cada una; (b) los errores que la versión
   en Python maneja y la de shell no; (c) las pruebas nuevas; (d) qué se perdió (dependencias, velocidad de arranque, claridad para quien sabe bash).

---

## 📚 7. Referencias

- *Bash Pitfalls* (la lista de errores comunes de bash, comunitaria): https://mywiki.wooledge.org/BashPitfalls
- ShellCheck: https://www.shellcheck.net/

**Orden de lectura sugerido:** las primeras diez entradas de *Bash Pitfalls* —el ejemplo de esta sección es la número uno—; el resto del track tiene sus
referencias en cada sección.

---

## 🚀 8. Cierre

El shell es la herramienta correcta para encadenar unos pocos programas en un cron; deja de serlo cuando el script necesita estructuras de datos, decidir
qué hacer con cada error, manejar nombres que llegan de afuera o tener pruebas. El experimento lo muestra: el bash ingenuo rompe con los nombres reales, el
bash cuidadoso falla con un nombre de los cuatro aunque aplica seis trucos, y Python lo hace bien sin saber ninguno.

**La señal de que quedó bien:** *"El script de 400 líneas del cierre ahora es un módulo de Python con pruebas, y el de diez líneas que respalda la base sigue
en bash, con `set -euo pipefail`."*

> 🏷️ **Cierra la sección con su tag**, cuando los ejercicios que elegiste estén hechos:
>
> ```bash
> git tag -a op-sy-fase-08 -m "op sy08 cerrada: la línea donde el shell deja de servir, medida"
> ```
>
> Los commits llevan su prefijo (`op sy08: …`) y los de ejercicio su número
> (`op sy08 ej07: …`).
