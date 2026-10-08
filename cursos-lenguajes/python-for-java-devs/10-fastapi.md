# ⚡ Fase 10 — FastAPI y la validación en el borde

> Python para desarrolladores Java senior · Fase 10 de 18 · Bloque C
> Depende de: Fase 09 · Habilita: Fase 11
> Registro de esta fase: **aplicación** — y es el primer cambio de registro desde la Fase 07
> Proyecto que avanza: **nace AgendaAPI**, la agenda de la red
> Fecha de verificación de las versiones: 12/09/2026

---

## 🎯 1. Propósito

Entrar al registro *aplicación* con la idea que lo ordena: **se valida en la frontera, una sola
vez, y hacia adentro el dato ya es de fiar.**

Todo lo demás de esta fase cuelga de ahí. Si el dato entra validado, el resto del código no
necesita comprobar nada, las firmas dicen la verdad, y el error que ve el cliente sale del sitio
donde se puede explicar bien. Si no, cada función se defiende por su cuenta, la validación queda
repartida por todas partes, y ninguna capa confía en la anterior — que es exactamente el diseño
que produce el reflejo de este perfil.

Y nace el proyecto 2: **AgendaAPI**. Con 2.800 pacientes activos y control mensual, Áurea agenda
casi tres mil citas al mes por WhatsApp, y el 19% no se presenta. Esta API es lo primero que hay
que arreglar.

---

## ✅ 2. Qué queda listo al terminar

- [ ] AgendaAPI corre, responde la disponibilidad de una sede y acepta reservas.
- [ ] Puedes explicar la diferencia entre el modelo de **entrada**, el de **dominio** y el de
      **salida**, y por qué no son el mismo objeto con tres nombres.
- [ ] Sabes qué reglas van en el modelo de entrada y cuáles **no**, con un criterio que puedes
      enunciar.
- [ ] `/docs` muestra la API completa y sabes para qué sirve de verdad ese documento.
- [ ] Tus errores HTTP dicen qué pasó y qué hacer, y usas el código que corresponde.
- [ ] Puedes decir, con el número de la sección 6 delante, cuánto cuesta validar en la frontera.
- [ ] El miniproyecto de la sección 7 corre y cumple sus criterios de aceptación.

---

## 🚫 3. Qué NO entra todavía

- **Base de datos** → Fase 11. Hoy la disponibilidad se calcula y las reservas se guardan en
  memoria. Es incómodo a propósito: el problema de esta fase es la frontera, no el almacén.
- **Concurrencia en serio** → Fase 14. Entra `async` **lo justo** para no bloquear el bucle, y
  nada más. El caso de las dos auxiliares reservando las 3:40 se planta aquí y se resuelve allá.
- **Autenticación y permisos** → Fase 12, donde el back-office los necesita de verdad y donde son
  un requisito legal.
- **Despliegue, contenedor y observabilidad** → Fases 16 y 17.

---

## 🧠 4. Concepto mínimo

### Tu instinto de Java dice… y esta vez se equivoca

**El reflejo:** el DTO con su *mapper* escrito a mano, y la validación repartida por los
servicios.

En tu mundo esto es correcto y hay una razón: el framework no puede validar lo que no entiende, así
que declaras un DTO con anotaciones (`@NotNull`, `@Size`), escribes o generas un *mapper* al modelo
de dominio, y las reglas que no caben en una anotación las pones en el servicio. Tres capas, y cada
una desconfía un poco de la anterior.

```java
// Lo que traes
public class BookingRequestDTO {
    @NotBlank @Pattern(regexp = "\\d{6,12}") private String patientDocument;
    @NotNull private String branch;
    // ... y el mapper, y el servicio que vuelve a comprobar
}
```

Traído aquí, produce esto:

```python
# ❌ El reflejo: un modelo anémico y la validación en el servicio
class BookingRequest(BaseModel):
    patient_document: str
    branch: str
    starts_at: datetime


def create_booking(request: BookingRequest):
    if not request.patient_document.isdigit():        # otra vez
        raise HTTPException(400, "documento inválido")
    if request.branch not in VALID_BRANCHES:          # y otra vez
        raise HTTPException(400, "sede inválida")
    if request.starts_at.tzinfo is None:              # y otra
        raise HTTPException(400, "falta zona horaria")
    ...
```

**Por qué falla:** no porque no funcione —funciona— sino porque el modelo dejó de significar
nada. `BookingRequest` dice que `branch` es un `str`, y eso es falso: es una de cinco sedes. Cada
función que reciba ese objeto tiene que volver a preguntárselo, o confiar. Y el documento de la
API que se genera automáticamente va a decir "string", que es una mentira publicada.

```python
# ✅ El modelo ES el validador, y el tipo dice la verdad
class BookingRequest(BaseModel):
    patient_document: str = Field(min_length=6, max_length=12, pattern=r"^\d+$")
    branch: Branch                    # un StrEnum: cinco valores, no "cualquier cadena"
    phase: PhaseKind
    starts_at: datetime

    @field_validator("starts_at")
    @classmethod
    def must_be_timezone_aware(cls, value: datetime) -> datetime:
        """Áurea opera en un solo huso, pero el bot y la web mandan lo que sea."""
        if value.tzinfo is None:
            raise ValueError("la fecha debe traer zona horaria explícita")
        return value
```

Con eso, **la función que recibe el objeto ya no comprueba nada**: si llegó, es válido. El
`mapper` en gran parte desaparece, porque el modelo de entrada ya produce tipos del dominio. Y
`/docs` publica la verdad: cinco sedes, un patrón, una longitud.

> ⚠️ **Y la contrapartida honesta, que hay que decir antes de que la descubran:** Pydantic valida
> **en tiempo de ejecución**, y eso cuesta. No es gratis como una anotación que el compilador
> verifica y descarta. Cuánto cuesta exactamente está en la sección 6, y el número es más
> tranquilizador de lo que la mayoría supone — pero es un número, no una promesa.

### Los tres modelos, y por qué son tres

Es la distinción que más código ahorra y la que más gente se salta:

**El modelo de entrada** (`BookingRequest`) describe **lo que un cliente puede mandar**. Es la
frontera: valida forma, tipos y rangos. No sabe nada del negocio.

**El modelo de dominio** (`Booking`) describe **lo que la cosa es**. Tiene los campos que el
sistema calcula o asigna —el identificador, la duración según la fase, quién la creó—, y esos
campos **no pueden venir del cliente**.

**El modelo de salida** (`BookingResponse`) describe **lo que se publica**. Y su razón de existir
es la que menos se ve hasta que muerde: hay campos del dominio que **no deben salir**. En Áurea
eso no es una preferencia — el motivo de consulta de un paciente es historia clínica, y sale por
una ruta distinta, con auditoría, o no sale.

```python
class BookingRequest(BaseModel):     # lo que entra
    patient_document: str
    branch: Branch
    phase: PhaseKind
    starts_at: datetime


@dataclass(frozen=True, slots=True)  # lo que es: el dominio sigue siendo del curso, no del framework
class Booking:
    booking_id: str
    patient_document: str
    branch: Branch
    phase: PhaseKind
    starts_at: datetime
    minutes: int
    created_by: str
    clinical_note: str               # ← existe, y NO sale


class BookingResponse(BaseModel):    # lo que se publica
    booking_id: str
    branch: Branch
    starts_at: datetime
    minutes: int
```

> 🧭 **La regla que evita la fuga:** el modelo de salida se escribe **listando lo que sale**, nunca
> excluyendo lo que no sale. Un modelo que diga "todo menos la nota clínica" filtra el día que
> alguien agregue un campo nuevo al dominio y no se acuerde de excluirlo. La Fase 12 tiene esa
> misma regla con más consecuencias legales.

### Qué NO va en el modelo de entrada

Esta es la parte que separa un diseño que aguanta de uno que hay que rehacer en la Fase 12, y es
la trampa del miniproyecto.

El modelo de entrada valida **lo que se puede saber mirando la petición sola**. Todo lo que
necesite consultar el estado del sistema, aunque parezca validación, **es negocio**:

| Regla | ¿Dónde va? | Por qué |
|---|---|---|
| El documento tiene entre 6 y 12 dígitos | **Entrada** | Se ve en la petición |
| La sede es una de las diez | **Entrada** | Es un conjunto cerrado y conocido |
| La fecha trae zona horaria | **Entrada** | Se ve en el valor |
| La cita no puede ser en el pasado | **Negocio** | Depende del reloj, no de la petición |
| El espacio está libre | **Negocio** | Depende del estado del sistema |
| La duración corresponde a la fase del plan | **Negocio** | Depende del plan del paciente |
| Esa sede presta esa especialidad | **Negocio** | Depende de una tabla que cambia |

**Y la razón de fondo no es purismo:** una regla de negocio dentro del modelo de entrada solo se
aplica cuando el dato entra **por esa puerta**. El día que el back-office de la Fase 12 cree una
cita desde el admin de Django, o que el proceso nocturno de la Fase 15 reagende un lote, esa
regla no se va a ejecutar — y nadie va a notarlo hasta que haya dos citas en el mismo espacio.

La distinción práctica, para llevar:

> 🧭 **Si la regla necesita mirar algo que no está en la petición, no es validación de entrada.**
> Va en el dominio, donde la ven todas las puertas.

Y la heurística del separador de miles de la Fase 06 —`890.000` es ochocientos noventa mil— **no
cruza esta frontera**. Aquí el monto llega como número JSON o no llega: un texto ambiguo se
rechaza con un 422 en vez de adivinarse. La heurística sigue siendo necesaria para los CSV que
mandan las sedes, que no pasan por esta puerta, y la decisión de qué hacer con el valor ambiguo
sigue siendo de negocio.

### Esto sí funciona igual

**HTTP es HTTP.** Los verbos, los códigos, la idempotencia de `GET` y `PUT`, los encabezados, la
negociación de contenido. Nada de eso cambia y todo lo que sabes vale.

**Tu criterio sobre diseño de API se transfiere entero.** Qué es un recurso, cuándo `POST` y
cuándo `PUT`, cómo se pagina, por qué los identificadores no deberían ser secuenciales, y qué
información va en el cuerpo y cuál en la ruta.

**La inyección de dependencias es la misma idea.** `Depends` declara qué necesita un endpoint y
el framework lo provee, con alcance. Es Spring con otra sintaxis y sin contenedor: no hay un
grafo de *beans* montado al arrancar, hay funciones que llaman a funciones. La Fase 11 lo usa para
la sesión de base de datos, que es exactamente el caso donde brilla.

**Y la estructura por capas sigue siendo buena idea** — la que atacamos en el Bloque A era la
ceremonia sin contenido, no la separación. En el Bloque C hay frontera, dominio y almacén, y eso
es correcto.

### Diccionario de traducción

| Java / Spring | Python / FastAPI | Dónde se rompe el paralelo |
|---|---|---|
| `@RestController` | un módulo con funciones y `@app.get` | No hay clase: las rutas son funciones |
| `@RequestMapping` | `@app.get("/ruta")` | Igual, y el decorador lleva también el modelo de salida |
| DTO con `@Valid` + Bean Validation | un modelo de Pydantic | **El modelo es el validador**; no hay anotación aparte |
| `@Service`, `@Component` | funciones en un módulo | No hay contenedor: nada se "escanea" al arrancar |
| `@Autowired` | `Depends(...)` | Explícito en la firma; sin grafo global |
| `ResponseEntity<T>` | `response_model=T` | Declarado en el decorador; genera el esquema y **filtra** la salida |
| `@ExceptionHandler` | `@app.exception_handler(...)` | Igual |
| Springdoc / Swagger | OpenAPI generado, sin configurar | Sale de los tipos, así que si mientes en el tipo, mientes en la doc |
| `@Transactional` | no existe aquí | La transacción es explícita: Fase 11 |
| Jackson `@JsonIgnore` | un modelo de salida distinto | Se declara qué sale, en vez de excluir qué no |
| Servlet por petición | un bucle de eventos | **Una función `async` que bloquea, bloquea a todos.** §4 |

> 📝 **Nota de ecosistema — Pydantic v1 y v2 no son la misma biblioteca.** La v2 se reescribió con
> el núcleo en Rust en 2023 y cambió nombres que están en todas partes: `parse_obj` es ahora
> `model_validate`, `.dict()` es `model_dump()`, `@validator` es `@field_validator` y lleva
> `@classmethod`. La mitad de los ejemplos que encuentres en internet son de v1 y no van a correr.
> El curso fija **Pydantic 2.13.5**; si copias algo y falla con un `AttributeError` sobre un
> método que "existe", casi siempre es esto.

### `async`, lo justo

FastAPI corre sobre un bucle de eventos. Eso significa una cosa que hay que entender hoy y que la
Fase 14 desarrolla: **un endpoint `async` que hace trabajo bloqueante bloquea el proceso entero**,
no solo su petición.

```python
# ❌ La forma de arruinar el rendimiento sin que nada falle
@app.get("/reporte")
async def reporte():
    rows = leer_archivo_de_500_000_filas()    # bloqueante, dentro del bucle
    return resumen(rows)
```

Mientras esa función lee el archivo, **ninguna otra petición avanza**. No hay error, no hay
advertencia: solo latencias que crecen cuando hay concurrencia.

La regla práctica, hasta la Fase 14:

> 🧭 **Si el cuerpo del endpoint no hace `await` de nada, decláralo `def` y no `async def`.**
> FastAPI ejecuta los endpoints `def` en un *threadpool*, fuera del bucle, y eso es exactamente lo
> correcto para trabajo bloqueante. Un `async def` con código bloqueante adentro es la peor de las
> tres opciones.

---

## 💻 5. Código mínimo con comentarios

### 5.1 El dominio primero

El dominio de AgendaAPI **no es de FastAPI**, y conviene que se note: son `dataclass` y `StrEnum`
de la biblioteca estándar, como en el Bloque A. Si mañana el framework cambia, esto no se toca.

```python
"""El dominio de la agenda. No sabe que existe HTTP."""

from dataclasses import dataclass
from datetime import datetime, timedelta, timezone
from enum import StrEnum

BOGOTA = timezone(timedelta(hours=-5))


class Branch(StrEnum):
    """Las sedes de la red. Conjunto cerrado y conocido."""

    CENTRO = "centro"
    CHAPINERO = "chapinero"
    SUBA = "suba"
    KENNEDY = "kennedy"
    USAQUEN = "usaquen"


class PhaseKind(StrEnum):
    """Las cinco fases del protocolo Arquitectura de Sonrisa."""

    DIAGNOSIS = "diagnosis"
    ORTHODONTIC = "orthodontic"
    PERIODONTAL = "periodontal"
    RESTORATIVE = "restorative"
    RETENTION = "retention"


# La duración la decide la fase, no el que reserva. Es regla de negocio y por eso
# vive aquí y no en el modelo de entrada.
PHASE_MINUTES: dict[PhaseKind, int] = {
    PhaseKind.DIAGNOSIS: 60,
    PhaseKind.ORTHODONTIC: 20,
    PhaseKind.PERIODONTAL: 45,
    PhaseKind.RESTORATIVE: 90,
    PhaseKind.RETENTION: 20,
}


@dataclass(frozen=True, slots=True)
class Booking:
    """Una cita. Lo que la cosa es, con todo lo que el sistema sabe de ella."""

    booking_id: str
    patient_document: str
    branch: Branch
    phase: PhaseKind
    starts_at: datetime
    minutes: int
    created_by: str
```

> 💡 **`StrEnum` en vez de `Enum`.** Es de 3.11 y hace que el valor **sea** una cadena: se serializa
> solo a JSON, se compara con `==` contra un `str`, y aparece en la documentación de la API como
> una lista de valores permitidos. Es el `Enum` que este caso pide, y cierra de paso el 📌 que la
> Fase 05 dejó abierto.

### 5.2 La frontera

```python
"""AgendaAPI — la agenda de la red Áurea."""

from datetime import date, datetime

from fastapi import FastAPI, HTTPException, status
from pydantic import BaseModel, Field, field_validator

from agenda.domain import BOGOTA, Booking, Branch, PhaseKind, PHASE_MINUTES

app = FastAPI(
    title="AgendaAPI",
    description="Agenda de la red Áurea: disponibilidad y reservas de las diez sedes.",
    version="0.10.0",
)


class BookingRequest(BaseModel):
    """Lo que un cliente puede mandar. Valida forma; el negocio va adentro."""

    patient_document: str = Field(
        min_length=6,
        max_length=12,
        pattern=r"^\d+$",
        description="Documento del paciente, solo dígitos.",
    )
    branch: Branch
    phase: PhaseKind
    starts_at: datetime

    @field_validator("starts_at")
    @classmethod
    def must_be_timezone_aware(cls, value: datetime) -> datetime:
        """Áurea opera en un solo huso; el bot y la web mandan lo que sea.

        Sin zona explícita no se puede saber si '15:40' es la hora de la sede
        o la del teléfono de alguien que está de viaje. Se rechaza en el borde.
        """
        if value.tzinfo is None:
            raise ValueError("la fecha debe traer zona horaria explícita")
        return value


class BookingResponse(BaseModel):
    """Lo que se publica. Se lista lo que sale; no se excluye lo que no."""

    booking_id: str
    branch: Branch
    starts_at: datetime
    minutes: int
```

**Detalles con intención**

- **`branch: Branch` y no `branch: str`.** El tipo dice la verdad, el error de una sede
  inexistente sale con la lista de las válidas, y `/docs` lo publica. Es gratis.
- **El `description` de cada campo va a la documentación.** Escribirlo aquí es lo más barato que
  puedes hacer por quien consuma la API — y en Áurea ese alguien eres tú dentro de seis meses.
- **`@field_validator` lleva `@classmethod`**, y el orden importa: el decorador de Pydantic va
  arriba. Es el error de copiar-pegar más común de la fase.
- **El validador explica su porqué en el docstring**, no la regla. La regla se ve en el código.

### 5.3 El endpoint, y dónde vive cada regla

```python
@app.post(
    "/bookings",
    response_model=BookingResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Reserva una cita",
    responses={
        409: {"description": "El espacio ya está reservado."},
        422: {"description": "La petición no cumple el contrato, o la cita no tiene sentido."},
    },
)
def create_booking(request: BookingRequest) -> Booking:
    """Reserva una cita en una sede.

    Lo que llega aquí YA cumple el contrato de forma: no hay que comprobar el
    documento, ni la sede, ni la zona horaria. Lo que sí hay que comprobar es
    todo lo que depende del estado del sistema.
    """
    # Regla de negocio 1: el reloj. No está en la petición, así que no es del modelo.
    if request.starts_at < datetime.now(BOGOTA):
        raise HTTPException(
            status.HTTP_422_UNPROCESSABLE_CONTENT,
            detail="la cita no puede ser en el pasado",
        )

    minutes = PHASE_MINUTES[request.phase]

    # Regla de negocio 2: el estado. En la Fase 11 esto es una consulta con su
    # transacción; hoy es un diccionario en memoria, y está declarado en §3.
    if is_taken(request.branch, request.starts_at, minutes):
        raise HTTPException(
            status.HTTP_409_CONFLICT,
            detail=f"el espacio de las {request.starts_at:%H:%M} en {request.branch} ya está reservado",
        )

    return store(Booking(
        booking_id=next_booking_id(),
        patient_document=request.patient_document,
        branch=request.branch,
        phase=request.phase,
        starts_at=request.starts_at,
        minutes=minutes,
        created_by="api",
    ))
```

**Detalles con intención**

- **La función devuelve un `Booking` del dominio y el `response_model` lo filtra.** FastAPI toma
  el objeto, lo valida contra `BookingResponse` y publica **solo esos campos**. Ese filtrado es lo
  que evita la fuga, y es automático.
- **`409 Conflict` para el espacio ocupado, `422` para la cita sin sentido.** No es lo mismo y el
  cliente hace cosas distintas: ante un 409 ofrece otro espacio, ante un 422 corrige el dato. Un
  `400` para todo obliga a leer el texto del mensaje para saber qué pasó.
- **El mensaje de error dice qué y dónde**, en español. El detalle `"el espacio de las 15:40 en
  suba ya está reservado"` le sirve a Yuli; `"conflict"` no.
- **`responses={...}`** documenta los códigos que el endpoint puede devolver. FastAPI no los
  adivina.

> ⚠️ **`HTTP_422_UNPROCESSABLE_ENTITY` está obsoleto** en las versiones fijadas por el curso: el
> nombre correcto es `HTTP_422_UNPROCESSABLE_CONTENT`, siguiendo el cambio de nombre del propio
> RFC. El viejo sigue funcionando y emite una advertencia. Lo vas a ver en todos los ejemplos de
> internet.

### 5.4 Qué es OpenAPI y para qué sirve de verdad

Levanta el servidor y abre `/docs`:

```bash
uv run uvicorn agenda.api:app --reload
```

Sale la documentación completa —cada endpoint, cada campo, cada valor permitido, cada código de
error— sin haber escrito una línea de documentación. Y funciona: se puede probar la API desde ahí.

Eso es lo que todo el mundo ve. Para qué sirve **de verdad**, que es lo que a ti te importa:

- **Es un contrato que se puede verificar.** El esquema en JSON (`/openapi.json`) se versiona y se
  le puede hacer `diff`: si un cambio tuyo rompe a un cliente, se ve en ese diff antes de
  desplegarlo.
- **Genera clientes.** Áurea tiene un bot de WhatsApp y una web; los dos pueden generar su cliente
  desde ahí en vez de escribirlo a mano.
- **Y es la prueba de que el tipo dice la verdad.** Si en `/docs` aparece "string" donde debía
  aparecer una lista de cinco sedes, tu modelo está mintiendo — y ahora se ve.

### 5.5 `Depends`, lo mínimo

```python
from typing import Annotated

from fastapi import Depends, Header


def current_actor(x_actor: Annotated[str | None, Header()] = None) -> str:
    """Quién está haciendo esto. Hoy es un encabezado; en la Fase 12 es un usuario.

    Declararlo como dependencia desde ahora hace que cambiarlo después no toque
    ni un endpoint: cambia esta función y ya.
    """
    return x_actor or "anonimo"


@app.post("/bookings", response_model=BookingResponse)
def create_booking(request: BookingRequest, actor: Annotated[str, Depends(current_actor)]) -> Booking:
    ...
```

Es `@Autowired` con dos diferencias que importan: **está en la firma** —se ve quién depende de
qué, sin buscar en un contenedor— y **es una función**, así que probarla es llamarla. En la Fase
11, `Depends` es lo que da la sesión de base de datos con su transacción, y ahí es donde deja de
parecer un adorno.

**Prueba de fuego**

```bash
curl -s localhost:8000/availability?branch=centro&day=2026-10-15 | head -5

curl -s -X POST localhost:8000/bookings \
  -H 'content-type: application/json' \
  -d '{"patient_document":"AB19283746","branch":"centro","phase":"orthodontic","starts_at":"2026-10-15T15:40:00-05:00"}'
```

```json
{"detail":[{"type":"string_pattern_mismatch","loc":["body","patient_document"],
 "msg":"String should match pattern '^\\d+$'","input":"AB19283746"}]}
```

Mira ese error: dice **qué campo**, **qué esperaba** y **qué recibió**, en una estructura que un
cliente puede procesar. No lo escribiste tú. Y la mentira que te va a contar la salida si miras
el lugar equivocado: ese `422` es del **modelo**, no de tu código — si tu endpoint tiene un `if`
que comprueba lo mismo, está de más, y el día que cambie el patrón vas a cambiarlo en un solo
lugar o en dos.

**El patrón a memorizar**

> Valida en la frontera lo que se puede saber mirando la petición; deja para el dominio todo lo
> que necesite mirar el estado. Y publica un modelo de salida que **lista** lo que sale.

---

## 📏 6. Medición — cuánto cuesta validar en la frontera

Esta medición existe para responder la objeción que este perfil trae y que es legítima: *"eso de
validar en tiempo de ejecución tiene que costar algo"*.

**Hipótesis.** El costo de Pydantic es medible pero irrelevante frente al resto de la petición, y
la intuición sobre su peso está equivocada por un orden de magnitud.

**Condiciones.** CPython 3.14.5 · macOS 26.6 · Apple Silicon, 8 núcleos · FastAPI 0.141.1,
Pydantic 2.13.5, Uvicorn 0.52.4 · endpoint de disponibilidad que devuelve **36 espacios** —un día
completo de una sede— y endpoint de reserva con cuatro campos · 300 peticiones por caso más 30 de
calentamiento · cliente `httpx` contra `uvicorn` en `127.0.0.1`, un solo proceso, sin
concurrencia · y, por separado, el costo de Pydantic **sin HTTP**, 2.000 repeticiones.

**Competidores.** El mismo endpoint **con y sin modelo de salida**: uno declara
`response_model=AvailabilityResponse` y el otro devuelve un `dict` crudo construido a mano. Los dos
producen el mismo JSON. Y del lado del costo puro, `model_dump_json()` de Pydantic contra
`json.dumps()` de la biblioteca estándar sobre la misma estructura.

**Resultado, sobre HTTP real:**

| Endpoint | Mediana | p95 |
|---|---|---|
| `GET /availability` — con modelo de salida | 0.83 ms | 1.28 ms |
| `GET /availability-raw` — sin modelo | 0.83 ms | 1.06 ms |
| `POST /bookings` — valida entrada y salida | 0.80 ms | 1.12 ms |
| `POST /bookings` inválido → 422 | **0.67 ms** | 1.01 ms |

**Y el costo puro de Pydantic, sin HTTP de por medio:**

| Operación | Mediana |
|---|---|
| Validar la entrada del POST (4 campos) | **1.1 µs** |
| Validar la salida (36 espacios anidados) | 16.6 µs |
| Validar **y serializar** la salida | 38.5 µs |
| `json.dumps` del diccionario crudo | 12.1 µs |

> ⚖️ **Veredicto. Validar la entrada cuesta 1.1 microsegundos** — una milésima parte de la
> petición. La objeción, para el modelo de entrada, simplemente no tiene sustento: podrías validar
> cien veces cada petición y seguiría siendo invisible.
>
> **Sobre HTTP real, la diferencia entre tener modelo de salida y no tenerlo desaparece en el
> ruido**: 0.83 ms contra 0.83 ms. Los 26 µs que cuesta de más validar y serializar 36 objetos
> anidados son el **3%** de una petición local — y una petición local es el mejor caso posible: en
> producción, con red de por menos y una consulta a la base de datos, ese 3% se vuelve
> indistinguible de cero.
>
> **Dónde sí cuesta, y hay que decirlo:** el modelo de **salida** es 15 veces más caro que el de
> entrada (16.6 µs contra 1.1 µs), porque valida 36 objetos anidados en vez de 4 campos planos. En
> un endpoint que devuelva diez mil filas eso deja de ser ruido, y ahí `response_model` sí es una
> decisión: se puede omitir y serializar a mano, pagando con la pérdida del filtrado automático —
> que es justo la defensa contra la fuga de datos clínicos. **Ese cambio se hace con un número
> delante, nunca por si acaso.**
>
> **Y el dato más útil de la tabla es el último: rechazar es más barato que aceptar.** Una petición
> inválida cuesta 0.67 ms contra 0.80 ms, porque se corta en la frontera y no hace el trabajo. Es
> el argumento de rendimiento —menor, pero real— a favor de validar temprano.
>
> **El umbral:** por debajo de unos cien objetos en la respuesta, el costo de Pydantic es ruido y
> la decisión es solo de diseño. Por encima de mil, mídelo. Y si tu endpoint devuelve diez mil
> objetos, el problema no es Pydantic: es que estás devolviendo diez mil objetos sin paginar.

**Lo que no se midió, y cambia las cosas:** todo esto es con un solo proceso, sin concurrencia, sin
base de datos y en `127.0.0.1`. La latencia real de AgendaAPI la va a dominar la consulta de la
Fase 11, no la validación. El rendimiento bajo carga concurrente es la Fase 14, y la comparación
contra Spring Boot es la 17 — donde esta cifra de 0.83 ms vuelve a aparecer con un competidor de
verdad enfrente.

> 📝 **Una nota de método que vale para todo el curso.** La primera versión de esta medición se
> hizo **en proceso**, con el cliente de pruebas de FastAPI, y decía que el modelo de salida
> costaba un **33% más** (1.28 ms contra 0.96 ms). Sobre HTTP real, esa diferencia desapareció.
> Ninguna de las dos mediciones está mal: miden cosas distintas, y la que responde a la pregunta
> *"¿cuánto le cuesta esto a mi API?"* es la segunda. **Lo que mides cambia la respuesta**, y
> declarar el montaje no es burocracia — es lo que permite saber cuál de las dos citar.

---

## 🧱 7. Miniproyecto — *La cita imposible*

**El encargo**

Yuli, la auxiliar de la sede Centro, en voz de Julián: *"Lo que pasa es que a Yuli le escriben por
WhatsApp entre paciente y paciente, con los guantes puestos. Ella mira la agenda, contesta, y a
veces se le olvida escribirla. Y después llegan dos personas a la misma hora. Necesito que la web
y el bot puedan ver los espacios libres y reservar solos, y que **el sistema no deje meter una
cita que no tiene sentido**."*

Construye el endpoint de disponibilidad de las diez sedes y el de reserva, rechazando en la
frontera todo lo que no tenga sentido.

**Por qué duele**

Porque la mitad de las reglas que Julián llama "que no tenga sentido" **parecen de validación y
son de negocio**, y ponerlas todas en el modelo de entrada es un error que no se paga hoy: se paga
en la Fase 12, cuando el back-office cree una cita por otra puerta y ninguna de esas reglas se
ejecute.

**Datos de entrada**

Las reglas que Áurea necesita, mezcladas a propósito:

1. El documento del paciente tiene entre 6 y 12 dígitos.
2. La sede es una de las diez de la red.
3. La fecha y hora traen zona horaria explícita.
4. La cita no puede ser en el pasado.
5. La cita tiene que caer en un espacio de la grilla: de 7:00 a 19:00, cada 20 minutos.
6. La duración la determina la fase del plan, no quien reserva.
7. **Esa sede tiene que prestar esa especialidad.** Suba no tiene rehabilitador oral, así que una
   fase `restorative` en Suba se rechaza — es el caso de Édgar, y está en la historia.
8. El espacio no puede estar ocupado.
9. Un paciente no puede tener dos citas el mismo día en dos sedes distintas.

**Tu primera tarea es clasificarlas**, y la clasificación es parte de la entrega.

Y el mapa de especialidades por sede, que puedes poner donde decidas:

```python
BRANCH_PHASES = {
    "centro":    {"diagnosis", "orthodontic", "restorative", "retention"},
    "chapinero": {"diagnosis", "orthodontic", "restorative", "retention"},
    "suba":      {"diagnosis", "orthodontic", "retention"},           # sin rehabilitador
    "kennedy":   {"diagnosis", "orthodontic", "retention"},
    "usaquen":   {"diagnosis", "orthodontic", "restorative", "retention"},
    # ... y las cinco restantes. La fase `periodontal` no la presta ninguna:
    # esa la hacen los aliados externos, y es el tema de la Fase 13.
}
```

**Criterios de aceptación**

- [ ] `GET /availability?branch=...&day=...` devuelve los espacios libres de una sede en un día,
      con la duración de cada uno.
- [ ] `POST /bookings` reserva, devuelve `201` con el identificador, y **nunca** deja dos citas
      superpuestas en la misma sede.
- [ ] Cada una de las nueve reglas está implementada **y clasificada** en un comentario: entrada o
      negocio, con su porqué en media línea.
- [ ] Los códigos HTTP son correctos y distinguibles: `422` para lo que no tiene sentido, `409`
      para el espacio ocupado, `404` para una sede que no existe como recurso.
- [ ] El modelo de salida **no publica** ningún campo que el dominio tenga y que no deba salir.
      Agrega al dominio un campo `clinical_note` y demuestra que no aparece en la respuesta.
- [ ] `/docs` muestra los valores permitidos de sede y fase sin que hayas escrito documentación.
- [ ] **Medición:** latencia mediana y p95 de los dos endpoints sobre al menos 300 peticiones, y
      qué porcentaje de esa latencia es validación. Esos números van en el mensaje del tag.

**Restricciones de registro**

> Esto es una **aplicación**: tipos verificados con `mypy --strict`, pruebas con el cliente de
> pruebas de FastAPI, modelos de entrada y salida separados, y el dominio en módulos que no
> importan nada del framework. La restricción va en la dirección contraria a la del Bloque A:
> aquí **no** se vale un archivo de cuatrocientas líneas. Pero tampoco se vale la ceremonia: si
> escribes una interfaz `BookingRepository` con una sola implementación para "poder cambiar de
> almacén", eso es la Fase 03 otra vez — el almacén cambia en la Fase 11 y lo vas a cambiar
> editando una función.

**La trampa**

La regla 7 —la sede tiene que prestar esa especialidad— parece de validación y **parece** que cabe
en el modelo de entrada, porque el mapa es un conjunto cerrado. Ponla ahí y va a funcionar
perfectamente hoy.

Y en la Fase 12, cuando Patricia cree una cita desde el admin de Django, la regla no se va a
ejecutar, porque el admin no pasa por tu modelo de entrada. La cita imposible va a entrar por la
puerta de atrás y nadie va a enterarse hasta que el paciente llegue a Suba y no haya quien lo
atienda.

La segunda trampa es la regla 9: *un paciente no puede tener dos citas el mismo día en dos sedes
distintas*. Esa no la puede contestar el modelo, ni el endpoint solo — **necesita mirar todas las
sedes**, y ahí aparece por primera vez el problema de la Fase 11: la consulta que el modelo obvio
hace cara.

**Pistas**

<details><summary>Pista 1 — el enfoque</summary>

Clasifica las nueve reglas **antes** de escribir código, en una tabla, con la pregunta de §4:
*¿esta regla necesita mirar algo que no está en la petición?* Si la respuesta es sí, es de
negocio, por más que parezca un formato.

Después escribe el dominio —las funciones que deciden— sin importar FastAPI. Y al final, la capa
HTTP, que debería quedarte sorprendentemente corta.
</details>

<details><summary>Pista 2 — la herramienta</summary>

- [Campos y validadores de Pydantic](https://docs.pydantic.dev/latest/concepts/fields/) y
  `field_validator` / `model_validator` — el segundo para reglas que miran **varios** campos a la
  vez, que es lo que la regla 5 pide.
- [`response_model`](https://fastapi.tiangolo.com/tutorial/response-model/) y lo que hace con los
  campos que no declara.
- [Manejo de errores en FastAPI](https://fastapi.tiangolo.com/tutorial/handling-errors/), para que
  tus `HTTPException` salgan con la misma forma que los `422` de Pydantic.
- [El cliente de pruebas](https://fastapi.tiangolo.com/tutorial/testing/), que se usa con `pytest`
  igual que la Fase 08.
</details>

<details><summary>Pista 3 — el esqueleto</summary>

```python
# agenda/domain.py — no importa FastAPI
def slots_for(day: date, branch: Branch) -> list[Slot]: ...
def can_serve(branch: Branch, phase: PhaseKind) -> bool: ...
def is_taken(branch: Branch, starts_at: datetime, minutes: int) -> bool: ...
def same_day_elsewhere(document: str, day: date, branch: Branch) -> Branch | None: ...

# agenda/api.py — solo frontera
class BookingRequest(BaseModel): ...
class BookingResponse(BaseModel): ...

@app.post("/bookings", response_model=BookingResponse, status_code=201)
def create_booking(request: BookingRequest) -> Booking: ...
```
</details>

**Cómo se entrega**

```bash
uv run uvicorn agenda.api:app --reload
uv run pytest -q
```

```bash
git add src/agenda tests/
git commit -m "fase 10 mini: AgendaAPI con validación en la frontera"
git tag -a mini-10 -m "Mini F10: AgendaAPI · disponibilidad <N> ms p95, reserva <M> ms p95, validación <X>% de la latencia"
```

<details><summary>💡 Solución de referencia — la clasificación, que es el entregable real</summary>

**La clasificación de las nueve reglas**, que es lo que se evalúa:

| # | Regla | Dónde | Por qué |
|---|---|---|---|
| 1 | Documento de 6 a 12 dígitos | Entrada | Se ve en la petición |
| 2 | Sede de la red | Entrada | Conjunto cerrado; un `StrEnum` lo resuelve |
| 3 | Zona horaria explícita | Entrada | Se ve en el valor |
| 4 | No en el pasado | **Negocio** | Depende del reloj |
| 5 | Cae en la grilla | **Entrada**, con matiz | La grilla es fija y conocida… **hoy** |
| 6 | Duración según la fase | **Negocio** | El cliente no la manda: la asigna el sistema |
| 7 | La sede presta la especialidad | **Negocio** | Depende de una tabla que cambia |
| 8 | Espacio libre | **Negocio** | Depende del estado |
| 9 | Sin otra cita ese día en otra sede | **Negocio** | Depende del estado de toda la red |

**La decisión de diseño que se tomó**, y es la regla 5: la grilla de 20 minutos se valida **en la
entrada**, porque es una constante del negocio que lleva diez años igual. Es la decisión más
discutible de la tabla y el otro camino es defendible: el día que una sede abra los sábados medio
día o que la duración de los controles cambie a 15 minutos, esa regla se vuelve dependiente de
datos y hay que mudarla. Se eligió dejarla en la entrada porque rechazar temprano una hora
absurda —las 3:47— produce un mensaje mucho mejor, y porque mudarla después cuesta diez minutos.
**Lo importante no es la elección: es que esté escrita y se pueda revisar.**

**La trampa, entera.** La regla 7 en el modelo de entrada funciona hoy y falla en la Fase 12 por
una razón estructural: **el modelo de entrada solo se ejecuta cuando el dato entra por esa
puerta**, y un sistema en crecimiento acaba teniendo más de una puerta — el admin, un proceso
nocturno, una importación, una corrección a mano. Las reglas que viven en el dominio las ven
todas.

El criterio operativo, para el resto del curso: **el modelo de entrada protege el contrato de la
API; el dominio protege los datos.** Cuando dudes, pregúntate qué pasaría si alguien insertara la
fila directamente en la base de datos. Si eso te parece mal, la regla es del dominio (y en la Fase
11, probablemente además una restricción de la tabla).

**Qué se habría hecho distinto si el registro fuera otro.** Como herramienta —un CLI— todo esto
sería una función que valida un archivo, y la mitad de las reglas se comprobarían con el
validador de la Fase 04: el `ExceptionGroup` reportaría todas juntas, que para un lote es mejor
que fallar en la primera. Como script, no existiría: Yuli seguiría mirando la agenda. **La
diferencia real entre los tres registros aquí no es técnica — es que la aplicación puede decir que
no a las tres de la mañana**, y eso es lo que Julián está comprando.
</details>

---

## 🧪 8. Ejercicios (25)

**🟢 Fácil (1–6)**

1. Agrega un campo opcional `notes` al modelo de entrada, con un límite de 200 caracteres, y
   comprueba en `/docs` que aparece como opcional.
2. Cambia `branch: str` por `branch: Branch` en un endpoint y compara el error `422` que produce
   cada versión. Copia los dos.
3. Agrega un campo al dominio que **no** esté en el modelo de salida y demuestra con `curl` que no
   se publica.
4. Haz que un endpoint devuelva `404` cuando la sede no existe como recurso, distinguiéndolo del
   `422` de una sede mal escrita en el cuerpo. Explica la diferencia en una línea.
5. Escribe una prueba con el cliente de pruebas de FastAPI que verifique el `409` del espacio
   ocupado.
6. Mira `/openapi.json`, guárdalo, cambia un modelo, y haz `diff` de los dos. Eso es el contrato
   versionado de §5.4.

**🟡 Intermedio (7–14)**

7. Usa `model_validator(mode="after")` para una regla que mire dos campos a la vez: que la hora
   caiga en la grilla de 20 minutos.
8. Escribe un `@app.exception_handler` para tus errores de dominio (`AurError` de la Fase 04) que
   los convierta en respuestas con la misma forma que los `422` de Pydantic.
9. Agrega paginación al endpoint de disponibilidad —`limit` y `offset` con `Query`— con límites
   máximos declarados. Comprueba qué pasa al pedir `limit=100000`.
10. Declara una dependencia con `Depends` que lea un encabezado de idioma y devuelva los mensajes
    de error en español o en inglés según el cliente.
11. Averigua qué hace `model_config = ConfigDict(extra="forbid")` y actívalo. Manda un campo de
    más y mira el error. Decide si lo dejarías activado.
12. Usa `Annotated[int, Field(ge=1, le=90)]` para un parámetro de consulta y comprueba que el
    límite aparece en `/docs`.
13. Escribe el mismo endpoint dos veces, `def` y `async def`, mete un `time.sleep(1)` en los dos, y
    mide qué le pasa a una segunda petición concurrente en cada caso. Es la lección de §4, medida.
14. Consulta la documentación de Pydantic sobre `computed_field` y agrega a la respuesta un campo
    calculado —la hora de finalización— sin guardarlo en el dominio.

**🟠 Difícil (15–21)**

15. **Diagnóstico.** Un endpoint devuelve `500` con un error de serialización. Reprodúcelo
    devolviendo un `Decimal` desde un endpoint sin decirle a Pydantic qué hacer con él, y da las
    dos formas de arreglarlo.
16. **Diagnóstico.** La API responde bien en desarrollo y en producción se degrada con diez
    usuarios. Hay una causa clásica en esta fase y está en §4. Reprodúcela con dos peticiones
    concurrentes y demuestra la diferencia entre `def` y `async def`.
17. **Medición.** Reproduce la medición de la sección 6 en tu máquina, con y sin `response_model`,
    **sobre HTTP real**. Después repítela con el cliente de pruebas en proceso y explica por qué
    los dos números difieren.
18. **Medición.** Mide cómo crece el costo del modelo de salida con el tamaño: 10, 100, 1.000 y
    10.000 objetos anidados. Encuentra el punto donde deja de ser ruido.
19. **Medición.** Compara `model_dump_json()` de Pydantic contra `json.dumps()` sobre la misma
    estructura, con 36 y con 3.600 objetos. Explica por qué la relación cambia.
20. **De registro.** La web de Áurea quiere mostrar la disponibilidad de las diez sedes en una sola
    pantalla. Decide si eso es un endpoint nuevo, diez llamadas desde el cliente, o algo más.
    Justifica con el costo de las tres y con lo que sabes de la Fase 11.
21. **De registro.** Julián pregunta si el bot de WhatsApp "puede hablar directo con la base de
    datos, para no pasar por la API". Escribe la respuesta con las dos caras —hay una razón real
    por la que alguien lo propondría— y decide. Conecta con la trampa del miniproyecto.

**🔴 Muy difícil (22–25)**

22. **Adversarial.** Consigue crear una cita imposible **sin pasar por el modelo de entrada**.
    Es trivial si las reglas están en el sitio equivocado, así que el ejercicio es: ponlas bien,
    y después demuestra que ya no puedes. Documenta las dos versiones.
23. **Adversarial.** Provoca una fuga de datos: agrega un campo clínico al dominio y encuentra tres
    formas distintas de que acabe en una respuesta —el modelo de salida mal declarado, un endpoint
    que devuelve el objeto sin `response_model`, y un mensaje de error que incluye el objeto—.
    Arregla las tres.
24. **Defiende una decisión.** Un colega propone usar el mismo modelo de Pydantic para la entrada,
    el dominio y la salida: *"es un objeto, no tres, y el mapeo desaparece"*. Tiene un argumento
    real. Escribe las dos caras, implementa la versión de un solo modelo, y encuentra el caso
    concreto de Áurea donde se rompe.
25. **Diseño.** La regla 9 —sin dos citas el mismo día en dos sedes— exige mirar toda la red.
    Diseña cómo responderla sin que cueste diez consultas, sabiendo lo que sabes hoy y **sin base
    de datos todavía**. Después anota qué cambiaría con Postgres delante. La Fase 11 te va a decir
    si acertaste.

**🔥 Opcionales**

- Genera un cliente TypeScript desde `/openapi.json` con alguna herramienta de generación y mira
  cuánto código te ahorró. Es el argumento de §5.4, comprobado.
- Investiga `BackgroundTasks` de FastAPI y decide si sirve para el envío de recordatorios de cita.
  La Fase 15 va a responder que casi nunca, y conviene que llegues con tu propia opinión.
- Lee el código de una ruta de FastAPI en su repositorio y encuentra dónde decide si ejecutar tu
  función en el bucle o en el *threadpool*. Son menos líneas de las que esperas.

---

## 📚 9. Referencias

**Documentación oficial**

- [FastAPI — Tutorial](https://fastapi.tiangolo.com/tutorial/) — completo, bien escrito, y se lee
  en una tarde. Es de las mejores documentaciones del ecosistema.
- [FastAPI — Response Model](https://fastapi.tiangolo.com/tutorial/response-model/) y
  [Handling Errors](https://fastapi.tiangolo.com/tutorial/handling-errors/).
- [Pydantic — Concepts](https://docs.pydantic.dev/latest/concepts/models/) — modelos, campos,
  validadores, y la guía de migración de v1 a v2 que vas a necesitar al copiar ejemplos viejos.
- [Uvicorn](https://www.uvicorn.org/) — el servidor, sus opciones y qué significa cada una.
- [Especificación de OpenAPI](https://spec.openapis.org/oas/latest.html) — para cuando quieras
  saber qué está generando FastAPI exactamente.

**Orden de lectura sugerido.** Antes de escribir: el tutorial de FastAPI hasta *Response Model*
—unas dos horas y cubren el 80% de la fase—. Durante: la documentación de Pydantic sobre campos y
validadores. Después: la parte del tutorial sobre dependencias, que se entiende mucho mejor con la
Fase 11 encima.

> ⚠️ URLs y contenidos cambian, y en FastAPI y Pydantic más que en la biblioteca estándar. Fija
> las versiones que da esta fase, y desconfía de cualquier ejemplo de Pydantic que
> use `.dict()` o `@validator`: es de la v1.

---

## 🚀 10. Cierre y conexión con la siguiente fase

Nació AgendaAPI, y con ella el registro *aplicación*. Lo que te llevas no es FastAPI —eso se
aprende en una tarde— sino **el criterio de dónde vive cada regla**: la frontera valida lo que se
ve en la petición, el dominio valida lo que depende del estado, y el modelo de salida lista lo que
se publica. Ese criterio es el que hace que el sistema aguante cuando aparezca la segunda puerta.

Y te llevas un número que desarma una objeción común: **validar la entrada cuesta 1.1
microsegundos**, y sobre HTTP real el modelo de salida no se nota. La próxima vez que alguien diga
que validar en tiempo de ejecución es caro, vas a poder preguntarle cuánto.

La **Fase 11** trae lo que hoy falta y se nota mucho: **la base de datos**. Las reservas viven en
un diccionario que se borra al reiniciar, y las dos reglas más difíciles del miniproyecto —el
espacio ocupado y la cita del mismo día en otra sede— son consultas que hoy no puedes hacer bien.
Ahí entran SQLAlchemy Core y ORM —que son dos herramientas distintas, no dos niveles de
abstracción—, las migraciones, y el dominio duro de Áurea: el plan de Arquitectura de Sonrisa con
sus cinco fases, su responsable por fase y su plan de pagos en paralelo. Y ahí se planta el caso
que la Fase 14 resuelve: dos auxiliares reservando el mismo espacio de las 3:40.

> **La señal de que quedó bien:** cuando veas un `if` de validación dentro de un servicio, tu
> primera pregunta va a ser por qué no está en la frontera — y la segunda, si no debería estar en
> el dominio porque hay más de una puerta.

> 🏷️ **No cierres la fase sin el tag.** Con el checklist de la sección 2 en verde, el
> miniproyecto corriendo y `git status` limpio:
>
> ```bash
> git tag -a fase-10 -m "F10 cerrada:
> - AgendaAPI responde disponibilidad y reserva, con su dominio separado del framework
> - modelos de entrada, dominio y salida distinguidos, con la regla del listado explícito
> - las nueve reglas clasificadas entre frontera y negocio, con su porqué
> - códigos HTTP distinguibles: 409 para el espacio ocupado, 422 para lo que no tiene sentido
> - /docs publica los valores permitidos sin documentación escrita a mano
> - el costo de validar medido: 1.1 µs la entrada, invisible sobre HTTP real"
> ```
>
> Los commits de la fase llevan su prefijo (`fase 10: …`), los de ejercicio su número
> (`fase 10 ej12: …`) y el miniproyecto el suyo (`fase 10 mini: …`). El miniproyecto terminado
> lleva además su tag anotado `mini-10`, y **en el mensaje de ese tag va el número que arrojó su
> medición**. La convención completa está en
> [`00-convencion-de-git-y-tags.md`](00-convencion-de-git-y-tags.md).
