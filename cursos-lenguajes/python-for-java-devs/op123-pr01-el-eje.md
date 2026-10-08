# 📜 pr01 — El eje: contrato implícito, esquema, IDL

> Python para desarrolladores Java senior · **Carta** · Track `pr` — Protocolos y contratos más
> allá de REST · sección 1 de 8
> Se lee suelta: no hace falta ninguna otra sección de la carta.
> Versiones verificadas contra PyPI el 05/10/2026 · Código probado el 05/10/2026 con Python 3.14.7,
> en contenedor: las salidas son las de esa corrida.

---

## 🎯 1. Qué problema resuelve

La agenda en línea publica un mensaje cada vez que se confirma una cita, y tres procesos lo leen (`db14`). Un día, el equipo de la
agenda decide que la sede debe viajar como identificador numérico y no como nombre, y cambia `"sede": "Suba"` por `"sede_id": 3`.
Despliega un viernes. El lunes, el proceso de recordatorios lleva dos días cayéndose con `KeyError: 'sede'` en cada mensaje, y nadie lo
había anunciado porque "era un cambio chico".

El problema no es el cambio: es que **el contrato entre los dos lados no estaba escrito en ningún lado**. Este track recorre las formas de
escribirlo, y esta sección las ordena en un eje. En un extremo, el **contrato implícito**: JSON que cada lado interpreta a su manera. En el
medio, un **esquema compartido** (JSON Schema, un modelo de Pydantic) contra el que se valida en la frontera. En el otro extremo, un
**IDL** (Protobuf, Avro, Thrift) del que se **genera** el código de los dos lados, con reglas de compatibilidad explícitas. Cada escalón
compra algo frente al cambio del viernes.

---

## 🧠 2. El modelo

| Escalón | Dónde vive el contrato | El cambio del viernes | Compatibilidad |
|---|---|---|---|
| **Implícito** (JSON a mano) | En la cabeza de cada equipo | `KeyError` en producción, lejos del cambio | Ninguna garantía |
| **Esquema compartido** (Pydantic, JSON Schema, OpenAPI) | Un archivo que los dos lados usan | Error de validación **en la frontera**, con el campo y la razón | La que se pruebe (`pr07`) |
| **IDL con generación** (Protobuf, Avro) | Un `.proto` o `.avsc` versionado | **Renombrar es compatible**: el cable usa números, no nombres | Reglas explícitas hacia atrás y hacia adelante |

La diferencia del tercer escalón no es solo "hay un esquema": es que el formato está diseñado para evolucionar. En Protobuf, cada campo tiene
un **número**, y es el número lo que viaja; el nombre es para el código. Cambiar el nombre no rompe a nadie; agregar un campo nuevo tampoco
(los lectores viejos lo ignoran); reutilizar un número, sí.

### Esto sí funciona igual

Este perfil conoce los tres escalones desde Java: un `Map<String, Object>` deserializado de JSON, un DTO con Bean Validation, y las clases que
genera `protoc` o el plugin de Avro de Maven. Las reglas de compatibilidad de Protobuf y Avro son las mismas en los dos lenguajes, porque son del
formato, no de la biblioteca.

---

## 💻 3. El ejemplo que corre

```bash
uv add pydantic grpcio-tools protobuf
```

Dos versiones del contrato en Protobuf. `v1/cita.proto`:

```protobuf
syntax = "proto3";
package aurea.v1;
message CitaConfirmada {
  string sede = 1;
  string hora = 2;
}
```

El cambio del viernes, hecho con las reglas del formato: el campo 1 cambia de nombre, y el identificador numérico es un campo **nuevo**, el 3.
`v2/cita.proto`:

```protobuf
syntax = "proto3";
package aurea.v2;
message CitaConfirmada {
  string sede_nombre = 1;
  string hora = 2;
  int32 sede_id = 3;
}
```

```bash
python -m grpc_tools.protoc -I . --python_out=. v1/cita.proto v2/cita.proto
```

`eje.py`:

```python
"""El cambio del viernes en los tres escalones: JSON implícito, esquema de Pydantic y Protobuf."""

import importlib.util
import json

from pydantic import BaseModel, ValidationError


def load(path: str):
    spec = importlib.util.spec_from_file_location(path.replace("/", "_"), path)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


# El productor ya está en la versión 2.
new_json = json.dumps({"sede_id": 3, "hora": "09:00"})

# ------------------------------------------------- 1. contrato implícito
try:
    message = json.loads(new_json)
    print("implícito:", f"recordatorio para la sede {message['sede']}")
except KeyError as e:
    print(f"implícito: KeyError {e} — en producción, en cada mensaje")


# ------------------------------------------------- 2. esquema compartido
class CitaConfirmada(BaseModel):
    sede: str
    hora: str


try:
    CitaConfirmada.model_validate_json(new_json)
except ValidationError as e:
    error = e.errors()[0]
    print(f"esquema:   rechazado en la frontera · campo {error['loc']} · {error['msg']}")

# ------------------------------------------------- 3. IDL con números de campo
v1, v2 = load("v1/cita_pb2.py"), load("v2/cita_pb2.py")
wire = v2.CitaConfirmada(sede_nombre="Suba", hora="09:00", sede_id=3).SerializeToString()
old_reader = v1.CitaConfirmada.FromString(wire)
print(f"protobuf:  el lector v1 lee sede={old_reader.sede!r}, hora={old_reader.hora!r} · {len(wire)} bytes en el cable")
print("           el campo nuevo, para el lector v1:", "ignorado y conservado" if old_reader.SerializeToString() == wire else "perdido")
```

```bash
python3 eje.py
```

Salida (Python 3.14.7, 05/10/2026):

```text
implícito: KeyError 'sede' — en producción, en cada mensaje
esquema:   rechazado en la frontera · campo ('sede',) · Field required
protobuf:  el lector v1 lee sede='Suba', hora='09:00' · 15 bytes en el cable
           el campo nuevo, para el lector v1: ignorado y conservado
```

**Detalles con intención**

- **El contrato implícito falla en el lugar equivocado**: en el consumidor, en cada mensaje, con un error que no dice nada del cambio.
- **El esquema falla en la frontera** y dice qué campo y por qué. No evita el problema, pero lo hace visible en el primer mensaje y no en el lunes.
- **Protobuf no falla**: el lector v1 lee `sede` del campo número 1, que el productor v2 llama `sede_nombre`. El nombre no viaja.
- **"Ignorado y conservado"**: el lector v1 no conoce el campo 3, pero lo guarda y lo vuelve a escribir si reenvía el mensaje. Es la compatibilidad
  hacia adelante: un servicio viejo en el medio no borra los datos nuevos.

---

## ⚠️ 4. Lo que se rompe

**Reutilizar un número de campo.** Si el productor hubiera puesto `int32 sede_id = 1;` (el número del campo viejo), el lector v1 leería un entero como
cadena y fallaría, o leería basura. Los números retirados se marcan con `reserved` para que nadie los reutilice.

**Cambiar el tipo de un campo.** `string sede = 1` a `int32 sede = 1` no es compatible. Un cambio de tipo es un campo nuevo con otro número.

**El esquema compartido que no se comparte.** Un modelo de Pydantic copiado y pegado en cada servicio es un contrato implícito con más pasos: cada copia
evoluciona por su lado. El esquema vive en un paquete o repositorio común, versionado.

**Dos versiones del mismo archivo en un proceso.** Protobuf registra cada archivo y cada mensaje en un *pool* global del proceso: dos `cita.proto`
generados con `-I v1` y `-I v2` se llaman igual adentro, y el segundo `import` falla con `duplicate file name cita.proto`, que fue el primer error de
este ejemplo. Las versiones conviven con un `package` distinto (`aurea.v1`, `aurea.v2`) y generando desde la raíz, para que la ruta forme parte del
nombre.

**La versión del código generado.** El `cita_pb2.py` generado por una versión de `protoc` exige un *runtime* de `protobuf` compatible; actualizar uno sin el
otro produce errores al importar. Se generan en el CI con versiones fijas.

---

## ⚖️ 5. Cuándo NO usarlo

**Un IDL para un endpoint que usa un solo cliente.** Si la API la consume solo la interfaz de la casa, un esquema de Pydantic con OpenAPI (FastAPI lo genera
solo) es suficiente.

**El contrato implícito, entre dos servicios que despliegan por separado.** Ahí es donde aparece el viernes.

**Protobuf hacia el navegador o hacia Patricia.** JSON se lee en las herramientas de desarrollo y en un correo; los binarios, no (`pr03`).

---

## 🧪 6. Ejercicios (10)

**🟢 Fácil (1–3)**

1. Corre el ejemplo. **Criterio:** explicas por qué Protobuf es el único que no falla.
2. Pon `int32 sede_id = 1;` en la v2 y vuelve a correr. **Criterio:** lo que lee el lector v1, y por qué es peor que un error.
3. Imprime el JSON Schema del modelo (`CitaConfirmada.model_json_schema()`). **Criterio:** reconoces el campo obligatorio.

**🟡 Intermedio (4–6)**

4. Agrega `reserved 4;` y `reserved "sala";` a la v2 e intenta usar el número 4. **Criterio:** el error de `protoc`.
5. Haz que el modelo de Pydantic acepte las dos versiones del JSON (con `sede` o con `sede_id`). **Criterio:** una prueba con los dos mensajes.
6. Genera el modelo de Pydantic desde un JSON Schema con `datamodel-code-generator`. **Criterio:** el modelo generado valida los mensajes del ejemplo.

**🟠 Difícil (7–9)**

7. Lee el mensaje v2 desde Java con el `.proto` de la v1 (`jv01`). **Criterio:** Java lee `sede` igual que Python.
8. Escribe una prueba de CI que compare dos versiones de un `.proto` y falle si hay un cambio incompatible (con `buf breaking` o a mano). **Criterio:** detecta
   el cambio del ejercicio 2.
9. Haz el mismo contrato en Avro (`jv01`) y compara sus reglas de evolución con las de Protobuf. **Criterio:** una tabla con tres cambios y su efecto en cada formato.

**🔴 Muy difícil (10)**

10. Ubica en el eje cada frontera entre servicios de un sistema tuyo. **Criterio:** una tabla. *Rúbrica:* (a) cada frontera con su escalón actual; (b) qué cambio la
    rompería y dónde se notaría; (c) el escalón que le corresponde; (d) cuánto cuesta subirla.

---

## 📚 7. Referencias

**Documentación oficial**

- Protobuf, actualizar un mensaje sin romper: https://protobuf.dev/programming-guides/proto3/#updating
- Pydantic, JSON Schema: https://docs.pydantic.dev/latest/concepts/json_schema/
- `grpcio-tools`: https://grpc.io/docs/languages/python/basics/

**Lectura**

- Martin Kleppmann, *Designing Data-Intensive Applications*, capítulo 4 (codificación y evolución).

**Orden de lectura sugerido:** el capítulo 4 de Kleppmann, que compara JSON, Thrift, Protobuf y Avro frente a la evolución; después la sección de actualizar
mensajes de la guía de Protobuf.

---

## 🚀 8. Cierre

Un contrato entre servicios se puede dejar implícito, escribir como esquema compartido o declarar en un IDL. Frente a un cambio, el implícito falla en
producción y lejos; el esquema falla en la frontera y dice por qué; el IDL con números de campo deja renombrar y agregar sin romper a nadie. Se elige el
escalón por lo que cuesta un viernes como ese.

**La señal de que quedó bien:** *"La agenda cambió el formato de la sede un viernes y los recordatorios siguieron funcionando el lunes."*

> 🏷️ **Cierra la sección con su tag**, cuando los ejercicios que elegiste estén hechos:
>
> ```bash
> git tag -a op-pr-fase-01 -m "op pr01 cerrada: el cambio del viernes en los tres escalones del contrato"
> ```
>
> Los commits llevan su prefijo (`op pr01: …`) y los de ejercicio su número
> (`op pr01 ej07: …`).
