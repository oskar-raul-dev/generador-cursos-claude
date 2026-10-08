# 🔁 wf05 — Prefect, Dagster y el *asset*

> Python para desarrolladores Java senior · **Carta** · Track `wf` — Orquestación de trabajos y
> flujos · sección 5 de 8
> Se lee suelta: no hace falta ninguna otra sección de la carta.
> Versiones verificadas contra PyPI el 05/10/2026 · Código probado el 05/10/2026 con Python 3.14.7,
> en contenedor: Prefect 3.8.7 y Dagster 1.13.25, sin servidor.

---

## 🎯 1. Qué problema resuelve

Airflow describe un grafo en un archivo que un procesador lee una y otra vez, y pide operar cuatro
piezas. La generación siguiente de orquestadores de Python partió de una queja concreta contra eso:
*"mi flujo ya es código de Python, ¿por qué tengo que describirlo aparte?"*. De ahí salen dos
respuestas distintas, y las dos valen la pena:

- **Prefect** (3.8.7, del 2026-09-27): **el flujo es una función**. Decoras tus funciones con
  `@flow` y `@task`, y Prefect les agrega reintentos, concurrencia, registro de ejecuciones y un panel,
  sin cambiar cómo se llaman entre sí.
- **Dagster** (1.13.25, del 2026-10-01): **la unidad no es la tarea sino el dato**. Declaras los
  *assets* —"el consolidado RIPS de la noche", "la radicación", "las regalías"— y de qué depende cada
  uno, y Dagster deduce el grafo y sabe qué está desactualizado.

Las dos corren en tu máquina sin servidor, y las dos tienen panel cuando lo quieres. Esta sección
escribe la noche de Áurea en cada una para que la diferencia de modelo se vea en el código.

---

## 🧠 2. El modelo

La diferencia de fondo es **qué cosa nombras**:

| | Airflow | Prefect | Dagster |
|---|---|---|---|
| La unidad | La tarea | La función (`@task`) dentro de un flujo (`@flow`) | El dato que existe después (`@asset`) |
| Cómo se arma el grafo | Declarando dependencias entre tareas | Llamando funciones: el grafo es el que ejecuta Python | Por los parámetros de cada *asset*: dependes de lo que recibes |
| La pregunta que contesta bien | ¿Qué corrió y cuándo? | ¿Qué pasó en esta ejecución? | ¿Este dato está al día y de dónde salió? |
| Sin servidor | `airflow dags test` | Llamar al flujo como una función | `materialize([...])` |

El *asset* de Dagster es el cambio de modelo más grande del track: en vez de *"corre la tarea
calcular_regalías"*, dices *"las regalías del trimestre son un dato que se obtiene del consolidado"*.
Si el consolidado cambia, Dagster sabe que las regalías quedaron desactualizadas aunque nadie las haya
pedido. Para un sistema cuyo producto es **datos** —el cierre de Áurea lo es—, esa es la pregunta
correcta.

### Tu instinto de Java dice… y esta vez se equivoca

El reflejo es elegir la herramienta como se elige un framework en Java: la más completa, la que más se
usa, la que trae más integraciones —que es Airflow—. Para un equipo pequeño con un grafo modesto, lo que
decide es **cuánto cuesta tener el primer flujo corriendo y cuánto cuesta mantenerlo**, y ahí la
respuesta suele ser la contraria: el flujo de Prefect es tu función con un decorador, y el día que lo
quieras quitar, quitas el decorador.

---

## 💻 3. El ejemplo que corre

```bash
uv add prefect dagster
```

### Prefect: el flujo es una función

`noche_prefect.py`:

```python
"""La noche de Áurea en Prefect: funciones con decorador, reintentos y concurrencia."""

from prefect import flow, task

ATTEMPTS = {"radicar": 0}


@task(retries=2, retry_delay_seconds=1)
def consolidar(day: str) -> str:
    return f"/datos/rips/{day}.json"


@task(retries=2, retry_delay_seconds=1)
def radicar(batch: str) -> int:
    ATTEMPTS["radicar"] += 1
    if ATTEMPTS["radicar"] == 1:
        raise ConnectionError("el portal de la aseguradora no responde")
    return 12


@task
def regalias(batch: str) -> int:
    return 6


@flow(log_prints=True)
def noche_aurea(day: str) -> str:
    batch = consolidar(day)
    # .submit lanza las dos tareas a la vez; .result() espera a cada una.
    filed, settled = radicar.submit(batch), regalias.submit(batch)
    summary = f"radicadas {filed.result()}, liquidaciones {settled.result()}"
    print(summary)
    return summary


if __name__ == "__main__":
    print(noche_aurea("2026-10-05"))
```

```bash
python3 noche_prefect.py
```

Salida (Python 3.14.7, 05/10/2026), filtrada a las líneas que importan:

```text
16:40:29.217 | INFO | Task run 'consolidar-723' - Finished in state Completed()
16:40:29.219 | INFO | Task run 'radicar-ec9' - Task run failed with exception: ConnectionError('el portal de la aseguradora no responde') - Retry 1/2 will start 1 second(s) from now
16:40:29.220 | INFO | Task run 'regalias-4b3' - Finished in state Completed()
16:40:30.232 | INFO | Task run 'radicar-ec9' - Finished in state Completed()
16:40:30.236 | INFO | Flow run 'tall-quokka' - radicadas 12, liquidaciones 6
16:40:31.219 | INFO | Flow run 'tall-quokka' - Finished in state Completed()
radicadas 12, liquidaciones 6
```

Fíjate en las marcas de tiempo: `regalias` terminó mientras `radicar` esperaba su reintento —las dos
corrían a la vez gracias a `.submit`—, y el reintento llegó un segundo después, como se pidió.

`noche_aurea` se llama como cualquier función y devuelve lo que devuelve. El reintento de `radicar`
lo hizo Prefect, y queda en el registro de la ejecución.

### Dagster: el dato es la unidad

`noche_dagster.py`:

```python
"""La noche de Áurea en Dagster: assets que dependen de los assets que reciben."""

from dagster import asset, materialize


@asset
def rips_consolidado() -> list[dict]:
    return [{"sede": "Suba", "valor": 185000}, {"sede": "Centro", "valor": 95000}]


@asset
def radicacion(rips_consolidado: list[dict]) -> int:
    # Depende de rips_consolidado porque lo recibe por nombre: no hay que declararlo aparte.
    return len(rips_consolidado)


@asset
def regalias(rips_consolidado: list[dict]) -> dict[str, float]:
    return {r["sede"]: r["valor"] * 0.06 for r in rips_consolidado if r["sede"] != "Centro"}


@asset
def informe_patricia(radicacion: int, regalias: dict[str, float]) -> str:
    return f"radicadas {radicacion}, regalías {regalias}"


if __name__ == "__main__":
    result = materialize([rips_consolidado, radicacion, regalias, informe_patricia])
    print("éxito:", result.success)
    print(result.output_for_node("informe_patricia"))
```

```bash
python3 noche_dagster.py
```

Salida (Python 3.14.7, 05/10/2026), sin las líneas de registro de Dagster:

```text
éxito: True
radicadas 2, regalías {'Suba': 11100.0}
```

En Dagster nadie escribió "regalías va después de consolidado": `regalias` recibe un parámetro llamado
`rips_consolidado`, y eso **es** la dependencia. Con `dagster dev -f noche_dagster.py` se abre la
interfaz, que muestra el grafo de *assets*, cuándo se materializó cada uno y cuáles quedaron
desactualizados.

**Detalles con intención**

- **Las funciones de Prefect se pueden llamar sin Prefect** quitando el decorador, o con `.fn` (por
  ejemplo, `radicar.fn("…")`), que es como se prueban.
- **El 6% de regalías es un número de ejemplo**, no la regla de Áurea: la liquidación real está en la
  Fase 15 y en el track de complementos.
- **Los *assets* de Dagster devuelven datos pequeños en el ejemplo.** En producción, cada *asset* se
  guarda con un *IO manager* (archivos, Parquet, una base de datos), y lo que pasa entre ellos es lo que
  ese gestor sabe guardar y leer.

---

## ⚠️ 4. Lo que se rompe

**El servidor temporal de Prefect.** Al correr un flujo sin servidor configurado, Prefect 3 levanta uno
temporal en el mismo proceso para registrar la ejecución, y la primera corrida tarda unos segundos más.
Para producción se configura un servidor (propio o el de Prefect Cloud), y los flujos programados se
sirven con `flow.serve()` o con *workers*.

**Mezclar el modelo de tareas con el de *assets*.** Dagster también tiene operaciones y trabajos al
estilo de Airflow (`@op`, `@job`), y un proyecto que mezcla los dos modelos sin criterio pierde la
ventaja de los *assets*: el grafo de datos deja de decir la verdad sobre qué está al día.

**Pasar objetos grandes entre tareas de Prefect.** Los resultados de las tareas pueden persistirse para
reanudar, y un DataFrame enorme serializado en cada tarea es lento y ocupa disco. Como en Airflow: se
pasan rutas o identificadores.

---

## ⚖️ 5. Cuándo NO usarla

**Para tres trabajos independientes.** Sigue siendo `cron` (Fase 15).

**Cuando la empresa ya opera Airflow.** Si hay un equipo de plataforma con Airflow funcionando, un flujo
más en Airflow cuesta menos que una herramienta nueva para un solo flujo, aunque esa herramienta sea
mejor.

**Kedro (1.7.0) como orquestador.** Kedro es un marco para **organizar proyectos de datos** —estructura,
catálogo de datos, *pipelines*— y se puede desplegar en Airflow o en Prefect; no compite con ellos como
planificador. Si lo que te falta es estructura de proyecto, es la herramienta; si lo que te falta es
quién corra las cosas a las 2:00, no.

---

## 🧪 6. Ejercicios (10)

**🟢 Fácil (1–3)**

1. Haz que `radicar` falle tres veces en Prefect. **Criterio:** el flujo termina en `Failed` con la
   excepción, y explicas qué pasó con `regalias`.
2. Agrega a Dagster el *asset* `glosas_por_vencer`, que depende de `radicacion`. **Criterio:** aparece en
   el grafo sin declarar la dependencia más que por el parámetro.
3. Prueba `radicar` sin Prefect usando `.fn`. **Criterio:** una prueba de `pytest` que no levanta ningún
   servidor.

**🟡 Intermedio (4–6)**

4. Busca en la documentación de Prefect cómo se programa un flujo con `serve` y prográmalo a las 2:00
   de Bogotá. **Criterio:** el panel muestra la próxima ejecución a la hora correcta.
5. Corre `dagster dev` y materializa solo `regalias`. **Criterio:** explicas qué hace Dagster con
   `rips_consolidado` si ya estaba materializado, y si no.
6. Agrega un *IO manager* de archivos a Dagster para que cada *asset* se guarde en disco.
   **Criterio:** después de materializar, los cuatro *assets* existen como archivos y una segunda
   materialización de `informe_patricia` los lee sin recalcularlos.

**🟠 Difícil (7–9)**

7. Haz que la noche de Prefect procese las diez sedes en paralelo con `.map`. **Criterio:** el panel
   muestra diez ejecuciones de la tarea, y una sede fallida no detiene a las otras nueve.
8. Agrega a Dagster una partición diaria a `rips_consolidado` y materializa tres noches. **Criterio:**
   la interfaz muestra tres particiones y puedes rematerializar una sola.
9. Mide el tiempo de una corrida de la noche en Prefect (con su servidor temporal) y en Dagster
   (`materialize`), con tareas vacías. **Criterio:** reportas cuánto cuesta el orquestador cuando el
   trabajo no cuesta nada.

**🔴 Muy difícil (10)**

10. Elige entre Prefect y Dagster para la noche de Áurea, con un prototipo de cada uno. **Criterio:** un
    documento de una página. *Rúbrica:* (a) compara qué pregunta contesta mejor cada uno para Patricia:
    "¿qué pasó anoche?" o "¿este número está al día?"; (b) cuenta las piezas que habría que operar con
    cada uno; (c) dice qué cuesta salir de cada uno dentro de dos años; (d) dice por qué no `cron`, con
    un número.

---

## 📚 7. Referencias

**Documentación oficial**

- Prefect, flujos y tareas: https://docs.prefect.io/v3/develop/write-flows
- Prefect, reintentos y concurrencia de tareas: https://docs.prefect.io/v3/develop/write-tasks
- Dagster, *assets*: https://docs.dagster.io/guides/build/assets
- Kedro, qué es y qué no es: https://docs.kedro.org/en/stable/

**Orden de lectura sugerido:** la página de *assets* de Dagster aunque termines eligiendo Prefect —el
modelo de datos como unidad cambia cómo piensas cualquier orquestador—; después la de flujos de
Prefect.

---

## 🚀 8. Cierre

Prefect convierte tus funciones en un flujo con un decorador; Dagster convierte tus datos en un grafo
que sabe qué está al día. Los dos corren sin servidor para empezar y con panel cuando hace falta, y los
dos se eligen por la pregunta que más le importa al negocio: qué corrió, o qué dato está bien.

**La señal de que quedó bien:** *"Cambió el consolidado de una sede y el sistema nos dijo qué informes
había que recalcular, en vez de recalcular todo."*

> 🏷️ **Cierra la sección con su tag**, cuando los ejercicios que elegiste estén hechos:
>
> ```bash
> git tag -a op-wf-fase-05 -m "op wf05 cerrada: la noche en Prefect y en assets de Dagster"
> ```
>
> Los commits llevan su prefijo (`op wf05: …`) y los de ejercicio su número
> (`op wf05 ej07: …`).
