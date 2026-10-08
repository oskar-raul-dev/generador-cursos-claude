# ⚖️ wf08 — Veredicto: el cierre nocturno en cuatro orquestadores

> Python para desarrolladores Java senior · **Carta** · Track `wf` — Orquestación de trabajos y
> flujos · sección 8 de 8
> Se lee suelta: no hace falta ninguna otra sección de la carta, aunque esta cierra el track y
> enlaza a las siete anteriores.
> Versiones verificadas contra PyPI el 05/10/2026 · Código probado en parte el 05/10/2026 con
> Python 3.14.7, en contenedor: la suma de memoria de procesos; la de contenedores y la medición
> entera quedan sin ejecutar (`⏳`), y las salidas rotuladas «Salida esperada, sin correr» lo dicen.

---

## 🎯 1. Qué problema resuelve

El track recorrió los cuatro escalones del eje ([`wf01`](op022-wf01-el-eje.md)): colas de tareas
([`wf02`](op023-wf02-colas-de-tareas.md)), planificación en proceso
([`wf03`](op024-wf03-programacion-en-proceso.md)), grafos con Airflow
([`wf04`](op025-wf04-airflow.md)) y con Prefect y Dagster ([`wf05`](op026-wf05-prefect-y-dagster.md)),
flujos durables con Temporal ([`wf06`](op027-wf06-temporal.md)), y lo transversal que ninguno resuelve
por ti ([`wf07`](op028-wf07-lo-transversal.md)). Falta la pregunta del principio, con números: **¿qué
gana y qué cuesta la noche de Áurea en cada escalón?**

La propuesta del track pedía este veredicto **medido**: el mismo cierre nocturno en `cron`, en Celery,
en Prefect y en Temporal, comparando líneas escritas, minutos de puesta en marcha, memoria en reposo y
qué pasa cuando se cae a la mitad. Esta sección publica esa medición entera —hipótesis, condiciones,
competidores y comandos— y **deja las celdas en `⏳`**, porque ninguna se ejecutó al escribir el curso.
Es el mismo método del resto del curso: la especificación es el contenido; el número lo pone quien la
corra, con su máquina.

---

## 🧠 2. El modelo

Cuatro competidores, todos implementando **la misma noche**: el grafo de seis trabajos de `wf01`, con las
mismas funciones del dominio y las mismas claves de efecto de `wf07` (así la idempotencia no favorece a
nadie).

| Competidor | Por qué es defendible | Configuración |
|---|---|---|
| **`cron` + tabla de avance** | Es la elección de la Fase 15 y la línea base | Un `crontab` por trabajo, con la dependencia resuelta por la tabla |
| **Celery** (5.6.3) | La cola más usada; `chain` y `chord` expresan el grafo | Valkey como *broker*, un *worker*, `acks_late=True` |
| **Prefect** (3.8.7) | El grafo como funciones, con servidor propio | Servidor de Prefect y un *worker* de proceso |
| **Temporal** (`temporalio` 1.34.0) | El flujo durable de referencia | `temporal server start-dev` y un *worker* |

Y cinco cosas que se miden, porque son las cinco que deciden para un equipo de una persona:

1. **Líneas escritas** para la noche completa, sin contar las funciones del dominio (que son las
   mismas en los cuatro).
2. **Minutos de puesta en marcha** desde una máquina limpia hasta la primera noche corriendo, con la
   documentación oficial como única ayuda.
3. **Memoria en reposo** de todo lo que el escalón deja corriendo entre noches (RSS sumado de procesos y
   contenedores).
4. **Comportamiento ante una caída a la mitad**: se mata el proceso que corre `radicar` y se mide qué se
   rehace, qué se pierde y cuánto tarda en terminar la noche.
5. **Piezas a operar**: cuántos servicios hay que actualizar, respaldar y vigilar.

---

## 💻 3. El ejemplo que corre

Lo que se puede publicar con certeza es el **arnés** de la medición: el script que toma la memoria en
reposo de lo que cada escalón deja corriendo. Sin dependencias.

`memoria_en_reposo.py`:

```python
"""Memoria en reposo de un escalón: RSS de sus procesos y memoria de sus contenedores."""

import json
import subprocess
import sys


def process_rss_mb(pattern: str) -> float:
    """Suma el RSS de los procesos cuyo comando contiene el patrón (Linux y macOS)."""
    out = subprocess.run(["ps", "-axo", "rss=,command="], capture_output=True, text=True, check=True)
    total_kb = sum(int(line.split(None, 1)[0]) for line in out.stdout.splitlines()
                   if pattern in line and "memoria_en_reposo" not in line)
    return total_kb / 1024


def container_mb(label: str) -> float:
    """Suma la memoria de los contenedores con la etiqueta del escalón."""
    ids = subprocess.run(["docker", "ps", "-q", "--filter", f"label={label}"],
                         capture_output=True, text=True, check=True).stdout.split()
    if not ids:
        return 0.0
    stats = subprocess.run(["docker", "stats", "--no-stream", "--format", "{{json .}}", *ids],
                           capture_output=True, text=True, check=True).stdout.splitlines()
    units = {"KiB": 1 / 1024, "MiB": 1, "GiB": 1024}
    total = 0.0
    for line in stats:
        used = json.loads(line)["MemUsage"].split("/")[0].strip()
        number, unit = used[:-3], used[-3:]
        total += float(number) * units[unit]
    return total


if __name__ == "__main__":
    step, pattern, label = sys.argv[1], sys.argv[2], sys.argv[3]
    print(f"{step}: procesos {process_rss_mb(pattern):.0f} MB · contenedores {container_mb(label):.0f} MB")
```

```bash
python3 memoria_en_reposo.py celery "celery -A noche" escalon=celery
```

Salida esperada, sin correr (la forma; el número es el de tu máquina):

```text
celery: procesos ⏳ MB · contenedores ⏳ MB
```

### La medición

**Hipótesis.** Para la noche de Áurea —seis trabajos, una dependencia de profundidad tres, una vez al
día—, `cron` con tabla de avance es el escalón con menos costo total, y cada escalón superior agrega más
costo de operación (memoria en reposo, piezas, puesta en marcha) que el beneficio que da ante una caída.
La hipótesis cae si algún escalón superior **rehace menos trabajo ante la caída y cuesta menos de
cuatro horas de puesta en marcha**.

**Condiciones.** Una máquina con Linux, cuatro núcleos y 8 GB; Python 3.14.7; las versiones de la tabla
de §2; Valkey 9.0.6 y PostgreSQL 18 en contenedores donde haga falta; la noche de `wf01` con trabajos de
duración simulada (`time.sleep`) de 30 a 120 segundos; la caída, con `kill -9` al proceso que corre
`radicar` a los 20 segundos de empezar. Cinco repeticiones de la caída por competidor.

**Comandos.** Cada competidor vive en su carpeta con su `README`; la medición se corre con
`memoria_en_reposo.py` después de 30 minutos sin trabajos, y la caída con un script que lanza la noche,
espera 20 segundos y mata el proceso por su nombre.

| | `cron` + tabla | Celery | Prefect | Temporal |
|---|---|---|---|---|
| Líneas de la noche (sin dominio) | ⏳ | ⏳ | ⏳ | ⏳ |
| Minutos hasta la primera noche | ⏳ | ⏳ | ⏳ | ⏳ |
| Memoria en reposo (MB) | ⏳ | ⏳ | ⏳ | ⏳ |
| Trabajos rehechos tras la caída | ⏳ | ⏳ | ⏳ | ⏳ |
| Minutos hasta terminar la noche tras la caída | ⏳ | ⏳ | ⏳ | ⏳ |
| Piezas a operar | 1 | 3 | 3 | 2 |

La última fila no necesita medición, y es la que más pesa: `cron` es parte del sistema operativo;
Celery suma *broker* y *worker*; Prefect, servidor (con su base de datos) y *worker*; Temporal, servidor
de desarrollo —en producción, servidor y base de datos— y *worker*.

**Veredicto, separado en expectativa y umbral.** *Expectativa:* `cron` con tabla gana en memoria en
reposo (cero procesos residentes) y en puesta en marcha; Temporal gana en "rehace solo lo que faltaba"
sin código propio; Prefect y Celery quedan en medio. *Umbral por determinar:* cuánto trabajo rehace
`cron` con tabla tras la caída depende de la tabla de avance de la Fase 15, que ya rehace solo el
trabajo pendiente, así que la diferencia con Temporal en esa fila puede ser **cero** para esta noche, y
eso decidiría la comparación a favor de `cron`.

---

## ⚠️ 4. Lo que se rompe

**Medir la herramienta en vez de la noche.** Comparar "lo rápido que encola Celery" no dice nada de la
noche de Áurea, que tiene seis trabajos al día. Lo que importa a esta escala es el costo de tener el
escalón ahí, no su rendimiento.

**Comparar con la configuración por defecto de unos y la buena de otros.** Celery con `acks_late=False`
pierde la tarea en la caída y queda mal parado por una configuración, no por la herramienta. Cada
competidor va con la configuración que recomienda su documentación para no perder trabajo.

**Olvidar las horas.** Los minutos de puesta en marcha y las piezas a operar se convierten en horas del
único ingeniero, todos los meses. Es el costo que no aparece en ninguna tabla de rendimiento.

---

## ⚖️ 5. El veredicto del track

Con la medición pendiente, el veredicto que el track sí puede sostener es de **forma**, y es el mismo que
la Fase 15 dejó escrito: el escalón se sube cuando aparece su problema.

- **Hoy, la noche de Áurea está en el primer escalón**, `cron` con tabla de avance y claves de efecto
  (`wf07`), y la razón es de tamaño, no de calidad de las herramientas.
- **Sube a una cola** cuando aparezca trabajo diferido desde el back-office —las liquidaciones de
  `wf02`—, y Huey sobre SQLite es la opción que no agrega ningún servicio.
- **Sube a un grafo** con varias decenas de trabajos con dependencias, o cuando el panel deje de ser un
  lujo; Prefect o Dagster antes que Airflow, salvo que la empresa ya opere Airflow.
- **Un flujo durable** se justifica por **procesos de días con esperas humanas** —la aprobación de la
  liquidación de `wf06`—, no por la noche.

---

## 🧪 6. Ejercicios (8)

**🟢 Fácil (1–2)**

1. Corre `memoria_en_reposo.py` contra lo que tengas corriendo hoy en tu máquina (un Postgres, un
   Valkey). **Criterio:** reportas el número y verificas a mano con `docker stats` que la suma cuadra.
2. Cuenta las piezas a operar de cada escalón según tu propia instalación. **Criterio:** una tabla que
   coincide o discrepa con la de §3, con la razón.

**🟡 Intermedio (3–4)**

3. Implementa la noche con `cron` y la tabla de avance, y con Celery (`chain`/`chord`).
   **Criterio:** las dos producen los mismos efectos, contados con la tabla de `wf07`.
4. Escribe el script de la caída: lanza la noche, espera 20 segundos y mata el proceso de `radicar`.
   **Criterio:** funciona contra las dos implementaciones del ejercicio anterior.

**🟠 Difícil (5–6)**

5. Llena las filas de memoria en reposo y de caída para `cron` y Celery. **Criterio:** cinco repeticiones
   de la caída por competidor, con mediana, y la máquina declarada.
6. Agrega Prefect y Temporal y llena la tabla completa. **Criterio:** la tabla sin ningún `⏳`, y una nota
   por cada número que te sorprendió.

**🔴 Muy difícil (7–8)**

7. Contrasta la hipótesis con tus números. **Criterio:** dices si cae o se sostiene. *Rúbrica:* (a) usas
   el umbral escrito en la hipótesis, no uno nuevo; (b) si cae, dices qué escalón la tumbó y en qué
   fila; (c) separas lo medido de lo estimado; (d) el empate se llama empate.
8. Repite la medición con una noche de 40 trabajos y dependencias de profundidad seis. **Criterio:** la
   misma tabla para la noche grande. *Rúbrica:* (a) el grafo se genera, no se escribe a mano; (b) dices
   en qué tamaño de noche cambia el ganador, si cambia; (c) la caída se mide igual; (d) el veredicto
   sobre Áurea se actualiza o se ratifica con esa evidencia.

---

## 📚 7. Referencias

- `ps`, el formato de columnas: https://man7.org/linux/man-pages/man1/ps.1.html
- `docker stats`: https://docs.docker.com/reference/cli/docker/container/stats/

Las del resto del track, en cada sección.

---

## 🚀 8. Cierre

El track `wf` termina donde empezó la Fase 15: el escalón se elige por el problema que tienes, no por la
herramienta que existe. La medición que lo decidiría con números está escrita entera y espera su
máquina; lo que no espera nada es la regla de `wf07`, que vale en los cuatro escalones.

**La señal de que quedó bien:** *"Cuando nos preguntaron por qué no usamos Airflow, mostramos la tabla
—y la primera fila llena era la de las piezas a operar."*

> 🏷️ **Cierra la sección con su tag**, cuando los ejercicios que elegiste estén hechos:
>
> ```bash
> git tag -a op-wf-fase-08 -m "op wf08 cerrada: la medición de los cuatro escalones, especificada"
> ```
>
> Los commits llevan su prefijo (`op wf08: …`) y los de ejercicio su número
> (`op wf08 ej07: …`).
