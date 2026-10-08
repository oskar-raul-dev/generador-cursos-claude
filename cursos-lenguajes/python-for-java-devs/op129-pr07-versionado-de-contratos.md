# 🧪 pr07 — Versionado y pruebas de contratos

> Python para desarrolladores Java senior · **Carta** · Track `pr` — Protocolos y contratos más
> allá de REST · sección 7 de 8
> Se lee suelta: no hace falta ninguna otra sección de la carta.
> Versiones verificadas contra PyPI el 05/10/2026 · Código probado el 05/10/2026 con Python 3.14.7,
> en contenedor: las salidas son las de esa corrida.

---

## 🎯 1. Qué problema resuelve

Un contrato roto entre dos servicios es el error más caro de una arquitectura distribuida, y la respuesta habitual —"lo hablamos en el chat"— es la que este
perfil ya sufrió en Java. La API de cartera de Áurea publica su OpenAPI, y dos cosas pasan con él que nadie prueba. La primera: **la API no cumple su propio
contrato** —acepta valores que el OpenAPI permite y responde 500 con ellos—. La segunda: **una versión nueva cambia el contrato** de una forma que rompe a
los clientes, y nadie lo nota hasta que el portal de franquiciados deja de funcionar.

Python tiene herramientas para las dos. **`schemathesis`** lee el OpenAPI y genera cientos de peticiones válidas según el esquema —incluidas las que nadie
escribiría a mano—, y verifica que las respuestas cumplan el contrato. Para la evolución, un contrato se compara con el anterior antes de publicarlo: un
campo obligatorio nuevo en la petición, o uno quitado de la respuesta, rompe a los clientes. **`pact-python`** lleva la idea más lejos, con contratos
escritos desde el consumidor.

---

## 🧠 2. El modelo

| Herramienta | Versión | Qué prueba | Cuándo |
|---|---|---|---|
| `schemathesis` | 4.29.3 | **El proveedor contra su propio OpenAPI**: genera peticiones del esquema (pruebas de propiedades, `qa04`) | En el CI del proveedor |
| Comparar dos OpenAPI | (un *script*, o `oasdiff`) | **Que la versión nueva no rompa** a los clientes de la vieja | Antes de publicar una versión |
| `pact-python` | 3.4.1 | **Lo que cada consumidor necesita** del proveedor, escrito por el consumidor | Con varios consumidores conocidos |

| Cambio en el contrato | ¿Rompe a los clientes? |
|---|---|
| Agregar un campo a la respuesta | No |
| Agregar un parámetro **opcional** | No |
| Agregar un parámetro **obligatorio** | **Sí** |
| Quitar o renombrar un campo de la respuesta | **Sí** |
| Restringir un valor permitido (un `enum` más chico, un mínimo más alto) | **Sí** |

### Tu instinto de Java dice… y esta vez se equivoca

Con Spring Cloud Contract o Pact en Java, el instinto asocia "pruebas de contrato" con una infraestructura de *brokers* y *stubs* que no vale la pena para
un equipo chico. La forma más barata de prueba de contrato no necesita nada de eso: `schemathesis` contra el OpenAPI que FastAPI ya genera, en el CI. Una
línea de comando.

---

## 💻 3. El ejemplo que corre

```bash
uv add fastapi uvicorn schemathesis
```

`cartera_api.py` —la API, con un error que nadie probó—:

```python
"""La API de cartera: calcula en cuántas cuotas se paga un saldo."""

from fastapi import FastAPI, Query

app = FastAPI(title="Cartera de Áurea", version="1.0.0")


@app.get("/cuotas")
def cuotas(saldo: int = Query(ge=0), cuota: int = Query(ge=0)) -> dict:
    return {"saldo": saldo, "cuota": cuota, "cuotas": -(-saldo // cuota)}   # techo de la división
```

```bash
uvicorn cartera_api:app --port 8141 &
schemathesis run http://127.0.0.1:8141/openapi.json --checks not_a_server_error --max-examples 200
```

`romper.py` compara el contrato publicado con el de la versión siguiente, y avisa de lo que rompería a los clientes:

```python
"""¿La versión nueva del contrato rompe a los clientes de la anterior? Parámetros obligatorios y campos quitados."""

import json

V1 = {"paths": {"/cuotas": {"get": {"parameters": [{"name": "saldo", "required": True}, {"name": "cuota", "required": True}],
      "responses": {"200": {"properties": ["saldo", "cuota", "cuotas"]}}}}}}
V2 = {"paths": {"/cuotas": {"get": {"parameters": [{"name": "saldo", "required": True}, {"name": "cuota", "required": True},
                                                   {"name": "sede", "required": True}],
      "responses": {"200": {"properties": ["saldo", "cuota", "numero_cuotas"]}}}}}}


def breaking(old: dict, new: dict) -> list[str]:
    found = []
    for path, ops in old["paths"].items():
        for method, op in ops.items():
            new_op = new["paths"].get(path, {}).get(method)
            if new_op is None:
                found.append(f"{method.upper()} {path}: desapareció")
                continue
            before = {p["name"] for p in op["parameters"]}
            for p in new_op["parameters"]:
                if p["required"] and p["name"] not in before:
                    found.append(f"{method.upper()} {path}: parámetro obligatorio nuevo '{p['name']}'")
            gone = set(op["responses"]["200"]["properties"]) - set(new_op["responses"]["200"]["properties"])
            found += [f"{method.upper()} {path}: la respuesta ya no trae '{g}'" for g in sorted(gone)]
    return found


print(json.dumps(breaking(V1, V2), ensure_ascii=False, indent=1))
```

```bash
python3 romper.py
```

Salida (Python 3.14.7, 05/10/2026) (fragmentos del informe de `schemathesis`, y la salida de `romper.py`):

```text
    `Internal Server Error`

Reproduce with:

    curl -X GET 'http://127.0.0.1:8141/cuotas?saldo=1&cuota=0'
…
Failures:
  ❌ Server error: 1

Test cases:
  24 generated, 1 found 1 unique failures
…
[
 "GET /cuotas: parámetro obligatorio nuevo 'sede'",
 "GET /cuotas: la respuesta ya no trae 'cuotas'"
]
```

`schemathesis` generó 24 peticiones válidas según el OpenAPI, encontró la que da 500 —`cuota=0`, que el contrato permite— y terminó con código 1, que hace
fallar el CI. Además entrega el `curl` que la reproduce. El comparador, por su lado, encontró los dos cambios de la v2 que romperían a los clientes de la v1.

**Detalles con intención**

- **`Query(ge=0)`** es el contrato: el OpenAPI dice que `cuota` puede ser 0. `schemathesis` genera exactamente eso —es uno de los primeros valores que prueba,
  porque los bordes del esquema son donde viven los errores— y la división por cero devuelve 500. La corrección es del contrato (`gt=0`, que devuelve 422) o
  del código; las dos son defendibles, y la prueba obliga a decidir.
- **`--checks not_a_server_error`** pide solo la verificación más básica: ninguna respuesta 5xx. `schemathesis` tiene más (que la respuesta cumpla el esquema,
  que los códigos de estado estén documentados); se agregan de a una.
- **`romper.py` es un comparador mínimo**, sobre una versión simplificada del OpenAPI, para mostrar la regla. Para un OpenAPI real, `oasdiff` lo hace con
  todas las reglas, y se corre en el CI antes de publicar.

---

## ⚠️ 4. Lo que se rompe

**El OpenAPI que miente.** Si el código acepta algo que el OpenAPI no declara (o al revés), `schemathesis` encuentra la diferencia, pero solo si el OpenAPI se
genera del código (FastAPI) o se prueba contra él. Un OpenAPI escrito a mano y nunca verificado es un contrato implícito con formato (`pr01`).

**Pruebas de contrato sin datos.** `schemathesis` genera peticiones válidas para el esquema, no para la base: un `GET /planes/{id}` con ids al azar devuelve casi
siempre 404. Se le dan ejemplos o datos semilla para que llegue al código interesante.

**Versionar en la URL sin plan de retiro.** `/v1/` y `/v2/` resuelven la ruptura, y a los dos años hay que operar cuatro versiones. Cada versión nueva trae la
fecha de retiro de la anterior, comunicada a los clientes.

**El cambio "compatible" que no lo es.** Cambiar el formato de una fecha dentro de un `string` no cambia el esquema y rompe a todos los clientes. El
comparador no lo ve; las pruebas con ejemplos del consumidor (Pact) sí.

---

## ⚖️ 5. Cuándo NO usarlo

**Pact con un solo consumidor que es del mismo equipo.** El contrato del consumidor y el del proveedor los escribe la misma persona; `schemathesis` y el
comparador alcanzan.

**`schemathesis` contra producción.** Genera peticiones raras a propósito; contra una base de verdad puede crear datos basura. Se corre contra una instancia de
prueba.

**Versiones de API para clientes internos que se despliegan juntos.** Si el portal y la API salen en el mismo despliegue, el contrato se prueba en el CI y no
hace falta mantener dos versiones vivas.

---

## 🧪 6. Ejercicios (10)

**🟢 Fácil (1–3)**

1. Corre `schemathesis` contra la API. **Criterio:** encuentras la petición que falla y su código de estado.
2. Cambia `cuota` a `Query(gt=0)` y vuelve a correr. **Criterio:** `schemathesis` ya no encuentra errores, y `cuota=0` responde 422.
3. Corre `romper.py`. **Criterio:** explicas por qué cada hallazgo rompe a un cliente.

**🟡 Intermedio (4–6)**

4. Agrega a `romper.py` la regla "un `enum` de la petición perdió un valor". **Criterio:** una prueba con un caso que rompe y uno que no.
5. Corre `schemathesis` con todas las verificaciones (`--checks all`). **Criterio:** lo nuevo que encuentra y si es un error de la API o del contrato.
6. Usa `oasdiff` sobre dos OpenAPI reales generados por FastAPI. **Criterio:** el informe de cambios rompedores.

**🟠 Difícil (7–9)**

7. Integra `schemathesis` en `pytest` con su API de Python (`schemathesis.openapi.from_asgi`). **Criterio:** la prueba corre en el CI sin levantar un servidor.
8. Escribe con `pact-python` el contrato del portal de franquiciados contra la API de cartera y verifícalo contra el proveedor. **Criterio:** romper un campo en el
   proveedor hace fallar la verificación.
9. Agrega `/v2/cuotas` con el cambio rompedor y mantén `/v1/cuotas` funcionando. **Criterio:** los dos responden, y el OpenAPI documenta la fecha de retiro de la v1.

**🔴 Muy difícil (10)**

10. Diseña la política de contratos de las APIs de Áurea. **Criterio:** una página. *Rúbrica:* (a) qué se prueba en el CI de cada proveedor; (b) cómo se detecta un
    cambio rompedor antes de publicar; (c) cuándo se versiona y cómo se retira una versión; (d) cuándo vale la pena Pact.

---

## 📚 7. Referencias

**Documentación oficial**

- `schemathesis`: https://schemathesis.readthedocs.io/en/stable/
- `pact-python`: https://docs.pact.io/implementation_guides/python
- `oasdiff`: https://github.com/oasdiff/oasdiff

**Orden de lectura sugerido:** el inicio rápido de `schemathesis`; después la introducción de Pact (*consumer-driven contracts*) para entender cuándo hace falta.

---

## 🚀 8. Cierre

Un contrato se prueba en dos direcciones: que el proveedor lo cumpla (`schemathesis`, generando peticiones desde el OpenAPI) y que la versión nueva no rompa a los
clientes de la vieja (un comparador en el CI). Pact agrega lo que cada consumidor necesita, cuando hay varios. Todo eso cuesta menos que un "lo hablamos en el
chat".

**La señal de que quedó bien:** *"El CI rechazó un pull request que agregaba un parámetro obligatorio a la API de cartera, antes de que el portal se enterara."*

> 🏷️ **Cierra la sección con su tag**, cuando los ejercicios que elegiste estén hechos:
>
> ```bash
> git tag -a op-pr-fase-07 -m "op pr07 cerrada: schemathesis contra el OpenAPI y el cambio rompedor detectado"
> ```
>
> Los commits llevan su prefijo (`op pr07: …`) y los de ejercicio su número
> (`op pr07 ej07: …`).
