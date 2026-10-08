# 🎁 sy02 — Las envolturas: plumbum, sh, invoke

> Python para desarrolladores Java senior · **Carta** · Track `sy` — El sistema operativo, los
> procesos y los archivos en movimiento · sección 2 de 8
> Se lee suelta: no hace falta ninguna otra sección de la carta.
> Versiones verificadas contra PyPI el 05/10/2026 · Código probado el 05/10/2026 con Python 3.14.7,
> en contenedor: las salidas son las de esa corrida.

---

## 🎯 1. Qué problema resuelve

El script de respaldo de Áurea en Python llama a `pg_dump`, lo comprime, cuenta los bytes y lo sube. Con `subprocess` (`sy01`), cada
paso son tres líneas de `Popen`, tuberías y `communicate`, y el script termina siendo más largo que el de shell que reemplazó. Hay
bibliotecas que envuelven `subprocess` para que llamar a un programa se parezca a llamar a una función: **plumbum** (con tuberías al
estilo del shell), **sh** (cada programa como una función), e **invoke** (tareas con nombre, como un `Makefile` en Python).

La pregunta de la sección es la de siempre con el azúcar: **cuándo vale la pena**. Se paga en una dependencia, en un poco de tiempo por
llamada, y en un comportamiento por defecto distinto del de `subprocess` que hay que conocer —en particular, qué hace cada una cuando el
programa falla—.

---

## 🧠 2. El modelo

| Biblioteca | Versión | El estilo | Si el programa falla |
|---|---|---|---|
| `subprocess` | biblioteca estándar | `run(["gzip", "-c", f])` | **No lanza nada** salvo `check=True` |
| plumbum | 2.0.2 | `(local["gzip"]["-c", f] \| local["wc"]["-c"])()` | Lanza `ProcessExecutionError` |
| sh | 2.4.0 | `sh.gzip("-c", f)` | Lanza `ErrorReturnCode_N` |
| invoke | 3.0.3 | `c.run("gzip -c x \| wc -c")` dentro de una `@task` | Lanza `UnexpectedExit` (y usa un shell) |

### Tu instinto de Java dice… y esta vez se equivoca

En Java no hay un equivalente común (Apache Commons Exec es lo más cercano, y casi nadie lo usa), y el instinto supone que las envolturas son
cosméticas. No lo son en un punto: **cambian el comportamiento ante un error**. Un script que pasa de `subprocess.run` a `sh` empieza a lanzar
excepciones donde antes seguía con el código de salida en una variable; uno que pasa en sentido contrario empieza a ignorar errores.

---

## 💻 3. El ejemplo que corre

```bash
uv add plumbum sh invoke
```

`envolturas.py`:

```python
"""La misma tubería en subprocess, plumbum y sh; qué hace cada una ante un error; y cuánto cuesta el azúcar."""

import subprocess
import time

import sh
from plumbum import local
from plumbum.commands.processes import ProcessExecutionError

with open("cierre.csv", "w") as f:
    f.write("sede,valor\n" + "Suba,1250000\n" * 20_000)

# ------------------------------------------------- la misma tubería: gzip -c cierre.csv | wc -c
gz = subprocess.Popen(["gzip", "-c", "cierre.csv"], stdout=subprocess.PIPE)
wc = subprocess.run(["wc", "-c"], stdin=gz.stdout, capture_output=True, text=True)
gz.wait()
print("subprocess:", wc.stdout.strip(), "bytes")
print("plumbum:   ", (local["gzip"]["-c", "cierre.csv"] | local["wc"]["-c"])().strip(), "bytes")
print("sh:        ", str(sh.wc("-c", _in=sh.gzip("-c", "cierre.csv", _piped=True))).strip(), "bytes")

# ------------------------------------------------- un programa que falla
r = subprocess.run(["gzip", "-c", "no-existe.csv"], capture_output=True)
print("\nsubprocess sin check: returncode", r.returncode, "· nada se lanzó")
for name, call, error in [("plumbum", lambda: local["gzip"]("-c", "no-existe.csv"), ProcessExecutionError),
                          ("sh", lambda: sh.gzip("-c", "no-existe.csv"), sh.ErrorReturnCode)]:
    try:
        call()
    except error as e:
        print(f"{name:<10} lanzó {type(e).__name__}")


# ------------------------------------------------- lo que cuesta cada llamada
def per_call_ms(fn, n=200) -> float:
    start = time.perf_counter()
    for _ in range(n):
        fn()
    return (time.perf_counter() - start) / n * 1000


print(f"\npor llamada a 'true': subprocess {per_call_ms(lambda: subprocess.run(['true'])):.2f} ms ·"
      f" plumbum {per_call_ms(lambda: local['true']()):.2f} ms · sh {per_call_ms(lambda: sh.true()):.2f} ms")
```

`tasks.py`, para invoke —las tareas del respaldo con nombre, como un `Makefile`—:

```python
from invoke import task


@task
def comprimir(c):
    """Comprime el cierre del día."""
    c.run("gzip -kf cierre.csv")


@task(pre=[comprimir])
def respaldo(c):
    """Comprime y reporta el tamaño."""
    size = c.run("wc -c < cierre.csv.gz", hide=True).stdout.strip()
    print(f"respaldo listo: {size} bytes")
```

```bash
python3 envolturas.py
invoke --list
invoke respaldo
```

Salida (Python 3.14.7, 05/10/2026):

```text
subprocess: 577 bytes
plumbum:    577 bytes
sh:         577 bytes

subprocess sin check: returncode 1 · nada se lanzó
plumbum    lanzó ProcessExecutionError
sh         lanzó ErrorReturnCode_1

por llamada a 'true': subprocess 0.26 ms · plumbum 0.30 ms · sh 2.47 ms
Available tasks:

  comprimir   Comprime el cierre del día.
  respaldo    Comprime y reporta el tamaño.

respaldo listo: 577 bytes
```

La misma tubería da los mismos 577 bytes en las tres formas. Ante el archivo que no existe, `subprocess` devolvió un código de salida y siguió; las dos
envolturas lanzaron. Y el costo del azúcar es desparejo: plumbum casi no agrega nada sobre `subprocess` (0,30 contra 0,26 ms), mientras que sh tarda
**casi diez veces más** por llamada (2,47 ms), porque arma hilos propios para leer la salida de cada proceso. En un respaldo nocturno con diez
llamadas no importa; en un bucle que llama a un programa diez mil veces, son veinticinco segundos contra dos y medio.

**Detalles con intención**

- **plumbum arma la tubería con `|`** y la ejecuta con `()`, sin shell: cada programa es un proceso y la tubería la conecta Python. Es la forma más
  parecida al shell que no tiene el riesgo de inyección de `sy01`.
- **sh convierte cada programa en una función** con atributos mágicos (`sh.gzip`); `_piped=True` y `_in=` arman la tubería. Solo funciona en Linux y
  macOS.
- **invoke usa un shell** (`c.run("...")` es texto): las tuberías y redirecciones funcionan, y la inyección también si se interpolan datos. Su valor
  está en las tareas con nombre y dependencias (`pre=`), no en la llamada.
- **Las dos envolturas lanzan una excepción** con un programa que falla; `subprocess` no, salvo `check=True`. Pasar de una a otra cambia el manejo de
  errores del script entero.

---

## ⚠️ 4. Lo que se rompe

**sh en Windows.** No funciona: depende de `fork` y de las tuberías de Unix. Un script de operación que tenga que correr en el portátil Windows de una
sede no puede usar sh.

**invoke y la interpolación.** `c.run(f"gzip {archivo}")` es `shell=True` con otro nombre. Los datos que vienen de afuera se citan con `shlex.quote`
o se pasan a `subprocess` como lista.

**Mezclar envolturas.** Un proyecto con `subprocess` en un módulo, plumbum en otro y sh en un tercero tiene tres formas de manejar errores. Se elige
una.

---

## ⚖️ 5. Cuándo NO usarlo

**Para una o dos llamadas.** `subprocess.run` con `check=True` es suficiente y no agrega dependencia.

**sh en código que debe correr en Windows.**

**invoke si ya hay un `Makefile` o `just`.** Para tareas del repositorio, la herramienta que el equipo ya usa; invoke se justifica cuando las tareas
tienen lógica que se escribe mejor en Python.

---

## 🧪 6. Ejercicios (10)

**🟢 Fácil (1–3)**

1. Corre el ejemplo e `invoke --list`. **Criterio:** los tres tamaños coinciden, y la lista muestra las dos tareas con su descripción.
2. Agrega `check=True` a la llamada que falla de `subprocess`. **Criterio:** la excepción y su atributo `returncode`.
3. Haz que sh no lance con el código 1 (`_ok_code=[0, 1]`). **Criterio:** la llamada devuelve sin excepción.

**🟡 Intermedio (4–6)**

4. Escribe la tubería `pg_dump | gzip | wc -c` con plumbum contra un Postgres de prueba (`db01`). **Criterio:** el tamaño del respaldo comprimido.
5. Agrega a `tasks.py` una tarea `subir` que dependa de `respaldo` y reciba el destino como argumento (`invoke subir --destino=...`). **Criterio:** la
   tarea corre con el argumento.
6. Pasa a sh y a plumbum un nombre de archivo con `; echo INYECTADO`. **Criterio:** muestras que ninguno de los dos lo ejecuta, y explicas por qué.

**🟠 Difícil (7–9)**

7. Lanza con plumbum un proceso en segundo plano (`& BG`) y espera su resultado más tarde. **Criterio:** el script hace otra cosa mientras tanto.
8. Mide el costo por llamada con 1 000 repeticiones en tu máquina. **Criterio:** la tabla, y si cambia tu elección.
9. Reescribe un script de shell real de 50 líneas con la envoltura que prefieras. **Criterio:** las dos versiones y su manejo de errores.

**🔴 Muy difícil (10)**

10. Elige la forma de llamar programas externos en los procesos de Áurea. **Criterio:** una página. *Rúbrica:* (a) `subprocess`, plumbum, sh o invoke, con
    su razón; (b) cómo se manejan los errores en todo el código; (c) en qué sistemas tiene que correr; (d) cómo se evita la inyección.

---

## 📚 7. Referencias

**Documentación oficial**

- plumbum: https://plumbum.readthedocs.io/en/latest/
- sh: https://sh.readthedocs.io/en/latest/
- invoke: https://docs.pyinvoke.org/en/stable/

**Orden de lectura sugerido:** la página de comandos locales de plumbum (las tuberías); después la de tareas de invoke.

---

## 🚀 8. Cierre

plumbum, sh e invoke hacen que llamar programas se parezca a llamar funciones o tareas. Cuestan una dependencia y algo de tiempo por llamada, y cambian
el comportamiento ante un error: lanzan donde `subprocess` callaba. plumbum arma tuberías sin shell; sh no corre en Windows; invoke usa un shell y vale
por sus tareas con nombre.

**La señal de que quedó bien:** *"El script de respaldo en Python es más corto que el de shell que reemplazó, y cuando `pg_dump` falla, el script se
detiene."*

> 🏷️ **Cierra la sección con su tag**, cuando los ejercicios que elegiste estén hechos:
>
> ```bash
> git tag -a op-sy-fase-02 -m "op sy02 cerrada: plumbum, sh e invoke, sus errores y su costo"
> ```
>
> Los commits llevan su prefijo (`op sy02: …`) y los de ejercicio su número
> (`op sy02 ej07: …`).
