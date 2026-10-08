# 🔁 wf01 — El eje: de cron al flujo durable

> Python para desarrolladores Java senior · **Carta** · Track `wf` — Orquestación de trabajos y
> flujos · sección 1 de 8
> Se lee suelta: no hace falta ninguna otra sección de la carta. **Empieza donde termina la
> [Fase 15](15-el-proceso-nocturno.md)**, que deja el cierre nocturno en `cron` y escribe cuándo
> dejaría de alcanzar.
> Versiones verificadas contra PyPI el 05/10/2026 · Código probado el 05/10/2026 con Python 3.14.7,
> en contenedor: las salidas son las de esa corrida.

---

## 🎯 1. Qué problema resuelve

La Fase 15 eligió `cron` para tres trabajos nocturnos sin dependencias entre ellos, y escribió las
tres condiciones en que esa elección deja de alcanzar: **dependencias entre trabajos**, muchos
trabajos con **reintentos diferidos**, y la necesidad de **verlos**. Un año después, la noche de Áurea
se parece más a esto:

- consolidar los lotes RIPS de las diez sedes;
- con los lotes listos, radicar ante las aseguradoras y calcular las regalías de los franquiciados;
- con la radicación hecha, marcar las glosas por vencer;
- con las regalías, liquidar las comisiones de los aliados;
- y al final, el informe para Patricia, que necesita todo lo anterior.

Seis trabajos, y la mitad depende de otros. `cron` no sabe de eso: o se programan con márgenes de
tiempo ("el informe a las 5, por si acaso") o se escribe un archivo de banderas que nadie entiende.
Esta sección pone nombre a los cuatro escalones de herramientas que existen para esto, y muestra con
la biblioteca estándar **qué agrega un orquestador** antes de instalar ninguno.

---

## 🧠 2. El modelo

Cuatro escalones, y cada uno resuelve un problema que el anterior no:

| Escalón | El modelo | Qué resuelve | Qué agrega de operación | En Python |
|---|---|---|---|---|
| **`cron`** | "A esta hora, este comando" | Cuándo | Nada: lo da el sistema operativo | `cron`, timers de `systemd` |
| **Cola de tareas** | "Haz esto, cuando puedas, con reintentos" | Trabajo diferido, reparto entre procesos, reintento | Un *broker* (Redis, RabbitMQ) y trabajadores | Celery, RQ, Dramatiq, `arq`, Huey |
| **Grafo dirigido** | "Esto, después de aquello" | Dependencias, paralelismo, reanudar desde el fallo, panel | Un planificador, una base de metadatos, una interfaz | Airflow, Prefect, Dagster |
| **Flujo durable** | "Este programa, aunque se reinicie la máquina" | Procesos de días o semanas con esperas, reintentos y estado | Un servidor que guarda la historia de cada ejecución | Temporal |

```mermaid
flowchart LR
    C["cron<br/>¿cuándo?"] --> Q["cola de tareas<br/>¿con reintentos,<br/>en paralelo?"]
    Q --> G["grafo dirigido<br/>¿después de qué?"]
    G --> D["flujo durable<br/>¿aunque tarde días<br/>y se caiga todo?"]
```

Lo que no aparece en la tabla, y es lo más importante del track: **ninguno de los cuatro hace tu
trabajo idempotente**. Si radicar dos veces la misma factura es un problema, lo es igual con `cron` que
con Temporal. Los orquestadores te dan reintentos; que reintentar sea seguro sigue siendo tuyo, y por
eso la sección que sostiene el track es `wf07`.

### Tu instinto de Java dice… y esta vez se equivoca

En el mundo Java el reflejo es Spring Batch más un planificador como Quartz o el de la plataforma, y
la tentación es buscar "el Spring Batch de Python". No existe uno, y no hace falta: lo que Spring Batch
da dentro del proceso (pasos, reanudación, repositorio de ejecuciones) en Python se reparte entre la
biblioteca estándar —el grafo, como se ve abajo— y un orquestador **fuera** del proceso cuando hace
falta un panel. Elegir mal el escalón cuesta más que elegir mal la herramienta dentro del escalón.

---

## 💻 3. El ejemplo que corre

Sin dependencias. `graphlib` está en la biblioteca estándar desde Python 3.9 y ordena un grafo de
dependencias. Con él y un `ThreadPoolExecutor`, `noche.py` es un orquestador de treinta líneas que
hace las dos cosas que separan un grafo de un `crontab`: **corre en paralelo lo que puede** y **no corre
lo que depende de algo que falló**.

```python
"""La noche de Áurea como grafo: paralelo donde se puede, y nada que dependa de un fallo."""

import time
from concurrent.futures import FIRST_COMPLETED, ThreadPoolExecutor, wait
from graphlib import TopologicalSorter

# Cada trabajo y aquello de lo que depende.
NIGHT = {
    "consolidar_rips": set(),
    "radicar": {"consolidar_rips"},
    "regalias": {"consolidar_rips"},
    "glosas_por_vencer": {"radicar"},
    "comisiones_aliados": {"regalias"},
    "informe_patricia": {"glosas_por_vencer", "comisiones_aliados"},
}


def run_job(name: str) -> str:
    time.sleep(0.2)                         # el trabajo de verdad va aquí
    if name == "radicar":
        raise RuntimeError("el portal de la aseguradora no responde")
    return name


def run_night(graph: dict[str, set[str]], workers: int = 3) -> dict[str, str]:
    sorter = TopologicalSorter(graph)
    sorter.prepare()                        # lanza CycleError si alguien creó un ciclo
    state: dict[str, str] = {}
    failed: set[str] = set()
    with ThreadPoolExecutor(workers) as pool:
        running = {}
        while sorter.is_active():
            for job in sorter.get_ready():
                if graph[job] & failed:
                    state[job] = "omitido: depende de un fallo"
                    failed.add(job)         # el fallo se propaga hacia adelante
                    sorter.done(job)
                    continue
                running[pool.submit(run_job, job)] = job
            if not running:
                continue
            finished, _ = wait(running, return_when=FIRST_COMPLETED)
            for future in finished:
                job = running.pop(future)
                try:
                    future.result()
                    state[job] = "ok"
                except Exception as error:
                    state[job] = f"falló: {error}"
                    failed.add(job)
                sorter.done(job)
    return state


if __name__ == "__main__":
    print(list(TopologicalSorter(NIGHT).static_order()))
    start = time.perf_counter()
    for job, result in run_night(NIGHT).items():
        print(f"{job:20} {result}")
    print(f"{time.perf_counter() - start:.1f} s")
```

```bash
python3 noche.py
```

Salida (Python 3.14.7, 05/10/2026) (el orden de los trabajos del mismo nivel puede variar entre corridas):

```text
['consolidar_rips', 'radicar', 'regalias', 'glosas_por_vencer', 'comisiones_aliados', 'informe_patricia']
consolidar_rips      ok
regalias             ok
radicar              falló: el portal de la aseguradora no responde
glosas_por_vencer    omitido: depende de un fallo
comisiones_aliados   ok
informe_patricia     omitido: depende de un fallo
0.6 s
```

Tres cosas de esa salida son lo que un orquestador vende:

- **`regalias` corrió aunque `radicar` falló**, porque no depende de él. En un `crontab` en secuencia,
  el fallo de la radicación habría detenido todo lo que venía después.
- **`glosas_por_vencer` y el informe no corrieron**, porque calcular glosas sobre una radicación que no
  ocurrió produce un número falso. El fallo se propaga, en vez de esconderse.
- **0,6 segundos y no 1,2**: los trabajos del mismo nivel corren en paralelo.

Lo que **no** tiene este orquestador de treinta líneas es exactamente lo que se paga con los productos
del track: el registro persistente de qué corrió (para reanudar mañana desde `radicar` sin repetir lo
demás), los reintentos con espera, el panel, las alertas, y la ejecución repartida en varias máquinas.

**Detalles con intención**

- **`prepare()` detecta ciclos** antes de correr nada. Un grafo con ciclo no es un plan, es un error, y
  conviene que falle a las 2:00 y no que se quede esperando.
- **El fallo se marca y se propaga**, en vez de detener el ciclo: un orquestador decente separa "falló
  esto" de "no tiene sentido correr aquello".
- **`get_ready()` devuelve todo lo que ya se puede correr**, que es la definición de paralelismo en un
  grafo de dependencias.

---

## ⚠️ 4. Lo que se rompe

**Programar con márgenes de tiempo.** "El informe a las 5, porque el cierre suele terminar a las 4" es
una dependencia escrita como hora. Funciona hasta la noche en que el cierre tarda hasta las 5:20 y el
informe sale con datos de ayer, sin ningún error.

**Subir de escalón por el panel.** La razón más común para instalar Airflow es querer ver qué corrió.
Un registro en una tabla y una página que la muestre resuelven eso con mucho menos que mantener un
planificador, un *webserver* y una base de metadatos.

**El orquestador como lugar del trabajo.** Las tareas de un orquestador deberían llamar a funciones del
dominio que también se pueden correr a mano y probar sin el orquestador. Si la lógica de las regalías
vive dentro de un operador de Airflow, cambiar de orquestador es reescribir las regalías.

---

## ⚖️ 5. Cuándo NO usarla

**El orquestador casero, en producción.** El de arriba es para **entender** qué agrega un grafo. En
producción, sin registro persistente ni reanudación, es una versión peor de cualquiera de los productos
del track. Si la noche crece hasta necesitar un grafo, se adopta uno mantenido.

**Un grafo para tres trabajos independientes.** Es la conclusión de la Fase 15, y sigue en pie: sin
dependencias, `cron` gana.

**Un flujo durable para un proceso que dura minutos.** Temporal brilla en procesos de días con esperas
humanas; para un cierre de veinte minutos, su servidor es más operación que beneficio.

---

## 🧪 6. Ejercicios (10)

**🟢 Fácil (1–3)**

1. Agrega el trabajo `respaldos_sedes` sin dependencias y haz que el informe dependa de él.
   **Criterio:** el orden estático lo ubica antes del informe, y corre en paralelo con el resto.
2. Crea un ciclo a propósito (`regalias` depende de `informe_patricia`). **Criterio:** el programa
   falla con `CycleError` antes de correr ningún trabajo, y el mensaje nombra el ciclo.
3. Haz que ningún trabajo falle. **Criterio:** los seis terminan en `ok` y el tiempo total es el de
   la ruta más larga del grafo, no la suma.

**🟡 Intermedio (4–6)**

4. Agrega reintentos: un trabajo que falla se reintenta dos veces con una espera creciente antes de
   marcarse como fallido. **Criterio:** un trabajo que falla una vez y después funciona termina en
   `ok` con la nota del reintento.
5. Busca en la documentación de `graphlib` qué devuelve `static_order` cuando hay varios órdenes
   válidos. **Criterio:** explicas por qué no se puede confiar en el orden entre hermanos.
6. Guarda el estado en un archivo JSON al terminar cada trabajo, y haz que una segunda corrida salte
   lo que ya terminó en `ok`. **Criterio:** relanzar después del fallo de `radicar` solo corre lo que
   faltaba.

**🟠 Difícil (7–9)**

7. Calcula la ruta crítica del grafo con las duraciones reales de una semana de trabajos.
   **Criterio:** la ruta crítica y cuánto se ahorraría si su trabajo más lento tardara la mitad.
8. Escribe el mismo grafo como un `crontab` con márgenes de tiempo y simula una noche en que el
   consolidado tarda el doble. **Criterio:** muestras qué trabajo corre con datos incompletos y por qué
   ningún error lo avisa.
9. Mide el orquestador casero con 200 trabajos sin dependencias y ocho trabajadores. **Criterio:**
   reportas el tiempo total y cuánto se va en la coordinación, con la máquina.

**🔴 Muy difícil (10)**

10. Decide en qué escalón debería estar la noche de Áurea hoy y dentro de dos años, con el crecimiento
    que esperas. **Criterio:** un documento de una página. *Rúbrica:* (a) cuenta trabajos,
    dependencias y frecuencia de fallos, con números; (b) dice quién opera el escalón elegido y
    cuántas horas al mes le cuesta; (c) nombra la señal concreta que haría subir al escalón siguiente;
    (d) dice qué parte del trabajo sigue siendo idempotente por diseño en cualquier escalón.

---

## 📚 7. Referencias

**Documentación oficial**

- `graphlib`: https://docs.python.org/3/library/graphlib.html
- `concurrent.futures`: https://docs.python.org/3/library/concurrent.futures.html

**Orden de lectura sugerido:** `graphlib` entera —es una página— y después las secciones del track,
cada una con su escalón.

---

## 🚀 8. Cierre

Hay cuatro escalones —horario, cola, grafo, flujo durable— y cada uno resuelve un problema que el
anterior no. Se sube un escalón cuando aparece su problema, no cuando aparece la herramienta. Y en
ninguno de los cuatro el orquestador hace por ti lo más difícil, que es que reintentar sea seguro.

**La señal de que quedó bien:** *"Falló la radicación, las regalías salieron igual, y el informe no
salió con datos de ayer."*

> 🏷️ **Cierra la sección con su tag**, cuando los ejercicios que elegiste estén hechos:
>
> ```bash
> git tag -a op-wf-fase-01 -m "op wf01 cerrada: los cuatro escalones y un grafo con graphlib"
> ```
>
> Los commits llevan su prefijo (`op wf01: …`) y los de ejercicio su número
> (`op wf01 ej07: …`).
