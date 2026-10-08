# 🔑 db06 — Clave-valor: Valkey

> Python para desarrolladores Java senior · **Carta** · Track `db` — Hablarle a cada sistema de
> datos desde Python · sección 6 de 15
> Se lee suelta: no hace falta ninguna otra sección de la carta.
> Versiones verificadas contra PyPI el 05/10/2026 · Código probado el 05/10/2026 con Python 3.14.7,
> en contenedor: las salidas son las de esa corrida.

---

## 🎯 1. Qué problema resuelve

El tablero de cartera consulta los totales del día de cada sede cada vez que alguien lo abre, y la consulta a Postgres tarda
dos segundos. La agenda en línea necesita bloquear un turno mientras el paciente termina de llenar el formulario, y soltarlo
solo si no lo confirma en cinco minutos. Las dos cosas son el caso de un almacén clave-valor en memoria: guardar un valor
calculado con un vencimiento, y guardar una marca que desaparece sola.

**Valkey** es la bifurcación de Redis que mantiene la Linux Foundation desde que Redis cambió de licencia en 2024; habla el
mismo protocolo y se usa desde Python con los mismos clientes: `redis` (redis-py) o `valkey` (valkey-py, su bifurcación).
Conectarse es una línea. Lo que sorprende viene después, y son tres cosas: **todo vuelve como `bytes`**, el **vencimiento**
es parte del dato y no de la aplicación, y hay un comando, **`KEYS`**, que en producción es un incidente.

---

## 🧠 2. El modelo

| Cliente | Versión | Nota |
|---|---|---|
| `redis` (redis-py) | 8.1.0 | El de siempre; funciona contra Valkey |
| `valkey` (valkey-py) | 6.1.1 | Bifurcación de redis-py para Valkey; sin versiones desde agosto de 2025 |

| Lo que se quiere | El comando | Desde Python |
|---|---|---|
| Guardar con vencimiento | `SET clave valor EX 300` | `r.set(k, v, ex=300)` |
| Guardar solo si no existe (bloquear un turno) | `SET clave valor NX EX 300` | `r.set(k, v, nx=True, ex=300)` |
| Muchas operaciones en un viaje | *Pipeline* | `with r.pipeline() as p:` |
| Recorrer claves | **`SCAN`**, nunca `KEYS` | `r.scan_iter(match="…")` |

Valkey ejecuta los comandos **de a uno**, en un solo hilo de ejecución de comandos. Es lo que lo hace rápido y predecible, y es
lo que convierte a un comando lento en un bloqueo de todos los demás clientes.

### Tu instinto de Java dice… y esta vez se equivoca

Con Jedis o Lettuce y Spring Data Redis, la serialización la configura el `RedisTemplate`, y el instinto espera recibir el
`String` o el objeto que guardó. `redis-py` devuelve los **`bytes`** que hay en el servidor, y ni siquiera con
`decode_responses=True` devuelve un número: el `12` que se guardó vuelve como `'12'`. La conversión de tipos es
responsabilidad de quien lee.

---

## 💻 3. El ejemplo que corre

```bash
uv add redis
```

`valkey_trampas.py`:

```python
"""Valkey desde Python: bytes, vencimiento, el turno bloqueado, y lo que cuesta KEYS."""

import os
import statistics
import threading
import time

import redis

HOST = os.environ.get("AUREA_VALKEY", "valkey")
r = redis.Redis(host=HOST)
for _ in range(30):
    try:
        r.ping()
        break
    except redis.ConnectionError:
        time.sleep(1)
print("servidor:", r.info("server").get("valkey_version") or r.info("server")["redis_version"])

# 1. todo vuelve como bytes
r.set("cartera:Suba:hoy", 12_450_000)
print("get:", repr(r.get("cartera:Suba:hoy")))
text = redis.Redis(host=HOST, decode_responses=True)
print("con decode_responses:", repr(text.get("cartera:Suba:hoy")))

# 2. el turno bloqueado que se suelta solo
taken = r.set("turno:Suba:2026-10-06T09:00", "paciente-anonimo-1", nx=True, ex=2)
again = r.set("turno:Suba:2026-10-06T09:00", "paciente-anonimo-2", nx=True, ex=2)
print("primer bloqueo:", taken, "· segundo:", again, "· vence en", r.ttl("turno:Suba:2026-10-06T09:00"), "s")
time.sleep(2.1)
print("después de 2,1 s:", r.get("turno:Suba:2026-10-06T09:00"))

# 3. KEYS bloquea a todos; SCAN no
with r.pipeline(transaction=False) as p:
    for i in range(500_000):
        p.set(f"cita:{i}", 1)
    p.execute()

latencies, stop = [], threading.Event()


def ping_loop():
    other = redis.Redis(host=HOST)
    while not stop.is_set():
        start = time.perf_counter()
        other.ping()
        latencies.append((time.perf_counter() - start) * 1000)


for label, action in [("KEYS", lambda: r.keys("cita:*")), ("SCAN", lambda: sum(1 for _ in r.scan_iter("cita:*", count=1000)))]:
    latencies.clear()
    stop.clear()
    t = threading.Thread(target=ping_loop)
    t.start()
    start = time.perf_counter()
    found = action()
    took = time.perf_counter() - start
    stop.set()
    t.join()
    print(f"{label}: {len(found) if isinstance(found, list) else found} claves en {took:.2f} s · "
          f"PING de otro cliente: mediana {statistics.median(latencies):.1f} ms, peor {max(latencies):.0f} ms")
```

```bash
docker run -d --name aurea-valkey -p 6379:6379 valkey/valkey:9.1
AUREA_VALKEY=localhost python3 valkey_trampas.py
```

Salida (Python 3.14.7, 05/10/2026):

```text
servidor: 9.1.2
get: b'12450000'
con decode_responses: '12450000'
primer bloqueo: True · segundo: None · vence en 2 s
después de 2,1 s: None
KEYS: 500000 claves en 0.32 s · PING de otro cliente: mediana 315.8 ms, peor 316 ms
SCAN: 500000 claves en 0.43 s · PING de otro cliente: mediana 0.8 ms, peor 6 ms
```

Las dos primeras líneas son la trampa de los tipos: el número vuelve como `bytes`, o como `str` con `decode_responses`. El
turno se bloqueó una vez, el segundo intento recibió `None`, y a los dos segundos el bloqueo ya no estaba. Y las dos últimas son
la razón de la regla de `KEYS`: mientras recorría medio millón de claves, el `PING` de **otro** cliente esperó los 316 ms
completos, porque el servidor no atendía a nadie más; con `SCAN`, que tardó un poco más en total, ese mismo `PING` respondió en
menos de un milisegundo. Con cinco millones de claves, `KEYS` congela la agenda en línea durante segundos.

**Detalles con intención**

- **`nx=True`** es el bloqueo del turno: el segundo `SET` devuelve `None` porque la clave ya existe. Con `ex=2`, el bloqueo se
  suelta solo si el paciente no confirma, sin un proceso que limpie.
- **El *pipeline*** manda las 500 000 escrituras en lotes, sin esperar la respuesta de cada una. Sin él, cada `SET` es un viaje
  de ida y vuelta por la red.
- **`scan_iter(count=1000)`** pide las claves de a mil por llamada. Cada llamada es corta, y entre una y otra el servidor atiende
  a los demás clientes. `KEYS` las devuelve todas en un solo comando que no se interrumpe.
- **Las claves llevan prefijo** (`cartera:`, `turno:`, `cita:`). Es la única "estructura" que tiene un almacén clave-valor, y
  la que permite recorrer, vencer o borrar por grupo.

---

## ⚠️ 4. Lo que se rompe

**`KEYS *` en producción.** Por lo que mide el ejemplo. Algunos equipos lo deshabilitan en la configuración del servidor
(`rename-command`), y es una buena idea.

**El caché sin vencimiento.** `r.set(k, v)` sin `ex=` guarda para siempre. Con los totales de cartera, el tablero muestra los de
la semana pasada hasta que alguien reinicie el servidor. Todo lo que es caché lleva `ex=`.

**Valkey como base de datos principal.** Vive en memoria y su persistencia (RDB, AOF) es configurable y, por defecto, puede perder
los últimos segundos. Para el turno bloqueado, aceptable; para los abonos, no.

**Guardar objetos con `pickle`.** La forma rápida de guardar un objeto de Python es `pickle.dumps`, y es la puerta de `se07`: quien
pueda escribir en Valkey ejecuta código en quien lea. Se guarda JSON.

---

## ⚖️ 5. Cuándo NO usarlo

**Si Postgres responde a tiempo.** Un caché agrega invalidación, una cosa más que operar y datos que pueden estar viejos. Primero
se mira si un índice resuelve los dos segundos.

**Para colas con garantías.** Valkey tiene listas y *streams*, y sirven; para colas donde no se puede perder un mensaje, una cola
de verdad (`wf`, `db14`).

**Para datos que no caben en memoria.** Todo vive en RAM; el costo crece con los datos.

---

## 🧪 6. Ejercicios (10)

**🟢 Fácil (1–3)**

1. Corre el ejemplo. **Criterio:** la mediana y el peor PING con `KEYS` y con `SCAN`, en tu máquina.
2. Guarda el total de cartera como JSON y léelo como `dict`. **Criterio:** el monto llega como `int`.
3. Consulta `TTL` de una clave sin vencimiento. **Criterio:** el valor que devuelve y qué significa.

**🟡 Intermedio (4–6)**

4. Escribe el caché del tablero: si la clave existe, se usa; si no, se calcula y se guarda con 5 minutos. **Criterio:** la segunda
   llamada no consulta Postgres, demostrado con un contador.
5. Haz que la confirmación del turno borre el bloqueo solo si es del mismo paciente (con un script Lua o `WATCH`). **Criterio:**
   otro paciente no puede liberar un turno ajeno.
6. Repite la medición sin *pipeline* con 50 000 claves. **Criterio:** el tiempo con y sin *pipeline*.

**🟠 Difícil (7–9)**

7. Usa el cliente asíncrono (`redis.asyncio`) para 1 000 lecturas concurrentes. **Criterio:** el tiempo total contra el cliente
   síncrono.
8. Implementa la invalidación: cuando llega un abono nuevo, se borra el total de esa sede. **Criterio:** el tablero nunca muestra
   un total sin el abono que acaba de entrar.
9. Reinicia el contenedor de Valkey con y sin AOF. **Criterio:** qué claves sobreviven en cada caso.

**🔴 Muy difícil (10)**

10. Decide qué guarda Áurea en Valkey. **Criterio:** una página. *Rúbrica:* (a) cada uso con su vencimiento; (b) qué pasa si Valkey
    se reinicia y pierde todo; (c) cómo se invalida cada caché; (d) cómo se evita `KEYS` en el código y en la operación.

---

## 📚 7. Referencias

**Documentación oficial**

- Valkey: https://valkey.io/docs/
- Valkey, `SCAN`: https://valkey.io/commands/scan/
- redis-py: https://redis.readthedocs.io/en/stable/

**Orden de lectura sugerido:** la página de `SCAN`, que explica sus garantías (y lo que no garantiza); después la guía de
*pipelines* de redis-py.

---

## 🚀 8. Cierre

A Valkey se le habla desde Python con `redis` o `valkey`, y lo que vuelve son `bytes`: los tipos los pone quien lee. El
vencimiento es parte del dato —`ex=` en todo lo que es caché, `nx=True` para bloquear—, y como ejecuta los comandos de a uno,
`KEYS` detiene a todos los clientes: se recorre con `SCAN`.

**La señal de que quedó bien:** *"El tablero abre en milisegundos, los turnos sin confirmar se liberan solos, y `KEYS` no aparece
en ningún lado del código."*

> 🏷️ **Cierra la sección con su tag**, cuando los ejercicios que elegiste estén hechos:
>
> ```bash
> git tag -a op-db-fase-06 -m "op db06 cerrada: bytes, vencimiento, el turno bloqueado y KEYS contra SCAN"
> ```
>
> Los commits llevan su prefijo (`op db06: …`) y los de ejercicio su número
> (`op db06 ej07: …`).
