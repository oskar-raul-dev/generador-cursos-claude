# ⚖️ pr08 — Veredicto: REST y las tres excepciones

> Python para desarrolladores Java senior · **Carta** · Track `pr` — Protocolos y contratos más
> allá de REST · sección 8 de 8
> Se lee suelta: no hace falta ninguna otra sección de la carta, aunque esta cierra el track y
> enlaza a las siete anteriores.
> Versiones verificadas contra PyPI el 05/10/2026 · Código probado el 05/10/2026 con Python 3.14.7,
> en contenedor: las salidas son las de esa corrida.

---

## 🎯 1. Qué problema resuelve

El track recorrió el eje de los contratos ([`pr01`](op123-pr01-el-eje.md)), gRPC ([`pr02`](op124-pr02-grpc-y-protobuf.md)), los formatos binarios
([`pr03`](op125-pr03-formatos-binarios.md)), GraphQL ([`pr04`](op126-pr04-graphql.md)), el tiempo real ([`pr05`](op127-pr05-tiempo-real.md)), la mensajería
como contrato ([`pr06`](op128-pr06-mensajeria-como-contrato.md)) y las pruebas de contratos ([`pr07`](op129-pr07-versionado-de-contratos.md)). Cada uno tenía
un caso donde ganaba.

El veredicto es que **REST con JSON y un OpenAPI sigue ganando casi siempre**: lo entiende cualquier cliente, se depura con `curl`, pasa por cualquier
*proxy*, y FastAPI genera su contrato solo. Y hay **tres situaciones concretas** en las que no: cuando el otro lado ya habla otra cosa (el operador con gRPC);
cuando el servidor tiene que avisar sin que le pregunten (SSE, eventos en una cola); y cuando muchos consumidores necesitan formas muy distintas de los mismos
datos (GraphQL). Fuera de esas tres, cambiar de REST es pagar un costo de operación sin una ganancia que se pueda medir.

---

## 🧠 2. El modelo

| Situación | La respuesta | El número del track que la apoya |
|---|---|---|
| Un cliente o una pantalla pide datos | **REST + JSON + OpenAPI** | `orjson` divide por 2,7 el costo del `json` estándar sin cambiar el contrato (`pr03`) |
| **Excepción 1**: el otro lado ya expone gRPC | gRPC desde Python | 0,53 ms por llamada; plazos obligatorios (`pr02`) |
| **Excepción 2**: el servidor avisa sin que le pregunten | SSE hacia pantallas; cola con contrato entre servicios | La reanudación con `Last-Event-ID` (`pr05`); la cola de muertos (`pr06`) |
| **Excepción 3**: muchas pantallas con formas distintas | GraphQL | 33 consultas contra 4 con `DataLoader`: el costo existe y se controla (`pr04`) |
| En cualquier caso | El contrato escrito y probado | `schemathesis` encontró el 500 en 24 peticiones (`pr07`) |

---

## 💻 3. El ejemplo que corre

Sin dependencias. `protocolo.py` es la tabla como función, aplicada a las integraciones de Áurea.

```python
"""¿REST o una de las tres excepciones? El veredicto como función, aplicado a las integraciones de Áurea."""

from dataclasses import dataclass


@dataclass
class Integration:
    name: str
    other_side_speaks: str = "nada todavía"        # "grpc", "rest", "cola"…
    server_pushes: bool = False                    # ¿el servidor avisa sin que le pregunten?
    to_browser: bool = False
    shapes_needed: int = 1                         # cuántas formas distintas de los mismos datos


def decide(i: Integration) -> str:
    if i.other_side_speaks not in ("nada todavía", "rest"):
        return f"{i.other_side_speaks} (excepción 1: el otro lado ya lo habla)"
    if i.server_pushes:
        return "SSE (excepción 2)" if i.to_browser else "eventos en una cola con contrato (excepción 2)"
    if i.shapes_needed >= 5:
        return "GraphQL (excepción 3), con DataLoader y límites"
    return "REST + JSON + OpenAPI"


INTEGRATIONS = [
    Integration("API de cartera para el portal", to_browser=True),
    Integration("Agenda del operador", other_side_speaks="grpc"),
    Integration("Pantalla de agenda en recepción", server_pushes=True, to_browser=True),
    Integration("Cita confirmada para tres procesos", server_pushes=True),
    Integration("Portal de franquiciados (12 pantallas)", to_browser=True, shapes_needed=12),
    Integration("Autorizaciones de la aseguradora", other_side_speaks="archivos en carpeta"),
    Integration("Liquidación de regalías (servicio Java)", other_side_speaks="rest"),
]
for i in INTEGRATIONS:
    print(f"{i.name:<42} → {decide(i)}")
```

```bash
python3 protocolo.py
```

Salida (Python 3.14.7, 05/10/2026):

```text
API de cartera para el portal              → REST + JSON + OpenAPI
Agenda del operador                        → grpc (excepción 1: el otro lado ya lo habla)
Pantalla de agenda en recepción            → SSE (excepción 2)
Cita confirmada para tres procesos         → eventos en una cola con contrato (excepción 2)
Portal de franquiciados (12 pantallas)     → GraphQL (excepción 3), con DataLoader y límites
Autorizaciones de la aseguradora           → archivos en carpeta (excepción 1: el otro lado ya lo habla)
Liquidación de regalías (servicio Java)    → REST + JSON + OpenAPI
```

**Detalles con intención**

- **La excepción 1 se evalúa primero**: lo que el otro lado ya habla no se discute. La aseguradora con archivos en una carpeta (`sy05`) es la misma excepción que
  el operador con gRPC.
- **El umbral de cinco formas** para GraphQL es una suposición de esta sección, a la vista: con dos o tres pantallas, endpoints REST a la medida son más simples.
- **El portal de franquiciados cae en GraphQL** por su número de pantallas; el ejercicio 10 de `pr04` pide la decisión completa, con los permisos por sede, que
  pueden inclinarla hacia REST.

---

## ⚠️ 4. Lo que se rompe

**Elegir el protocolo por la charla.** gRPC, GraphQL y los WebSockets tienen casos donde ganan con claridad; adoptarlos fuera de ellos trae generación de código,
herramientas de depuración nuevas y configuración en cada *proxy*, sin una mejora medible.

**REST sin contrato.** El veredicto es REST **con** OpenAPI probado (`pr07`). Un REST de JSON implícito tiene los mismos problemas que cualquier contrato implícito
(`pr01`).

**Dos protocolos para lo mismo.** Una API en REST y en GraphQL "para que cada uno elija" son dos contratos que mantener sincronizados.

---

## ⚖️ 5. Cuándo NO usar este veredicto

**Con volúmenes donde el formato importa.** Millones de mensajes por minuto entre servicios cambian la cuenta: el tamaño de Protobuf o Avro (`pr03`) pesa.

**En un ecosistema que ya decidió.** Si toda la casa es gRPC, el servicio nuevo de Python habla gRPC aunque sea REST lo que ganaría en el vacío.

---

## 🧪 6. Ejercicios (8)

**🟢 Fácil (1–2)**

1. Agrega tres integraciones de un sistema tuyo. **Criterio:** la salida, y si estás de acuerdo.
2. Cambia el umbral de GraphQL a 3. **Criterio:** qué integración cambia y si la decisión mejora.

**🟡 Intermedio (3–4)**

3. Agrega la dimensión "volumen de mensajes por minuto" y un umbral para formatos binarios. **Criterio:** una integración de prueba que caiga en Protobuf.
4. Escribe las pruebas de `decide` con un caso por fila de §2. **Criterio:** cinco casos, todos pasan.

**🟠 Difícil (5–6)**

5. Para la pantalla de recepción, mide el costo de SSE contra un sondeo cada 5 segundos con 50 pantallas. **Criterio:** peticiones por minuto y conexiones abiertas.
6. Para el portal, escribe dos de sus pantallas en REST y en GraphQL. **Criterio:** líneas, consultas a la base y permisos, comparados.

**🔴 Muy difícil (7–8)**

7. Escribe la política de protocolos de Áurea. **Criterio:** una página. *Rúbrica:* (a) el protocolo por defecto y su contrato; (b) las tres excepciones, con su
   señal concreta; (c) cómo se prueban los contratos de cada uno; (d) quién aprueba una excepción nueva.
8. Audita las integraciones de un sistema real. **Criterio:** una tabla. *Rúbrica:* (a) cada integración con su protocolo actual; (b) la decisión de la tabla; (c) las
   que no coinciden y por qué; (d) el costo de cambiar las que deberían.

---

## 📚 7. Referencias

- Roy Fielding, *Architectural Styles and the Design of Network-based Software Architectures* (2000), el capítulo 5, que define REST:
  https://ics.uci.edu/~fielding/pubs/dissertation/rest_arch_style.htm

**Orden de lectura sugerido:** el capítulo 5 de Fielding, para separar REST de "JSON sobre HTTP"; el resto del track tiene sus referencias en cada sección.

---

## 🚀 8. Cierre

REST con JSON y un OpenAPI probado gana casi siempre. Las tres excepciones son concretas: el otro lado ya habla otra cosa; el servidor tiene que avisar sin que le
pregunten; o hay muchas pantallas con formas distintas de los mismos datos. Fuera de ellas, otro protocolo es costo sin ganancia medible.

**La señal de que quedó bien:** *"Cada integración de Áurea tiene su protocolo escrito al lado, y las tres que no son REST tienen la razón escrita al lado del
protocolo."*

> 🏷️ **Cierra la sección con su tag**, cuando los ejercicios que elegiste estén hechos:
>
> ```bash
> git tag -a op-pr-fase-08 -m "op pr08 cerrada: REST por defecto y las tres excepciones con su señal"
> ```
>
> Los commits llevan su prefijo (`op pr08: …`) y los de ejercicio su número
> (`op pr08 ej07: …`).
