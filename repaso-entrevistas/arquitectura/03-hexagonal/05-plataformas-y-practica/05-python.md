# 05 — Python

Este capítulo enseña a mantener contratos y ciclos de vida explícitos en Python aunque el lenguaje permita duck typing, imports dinámicos, ORM activo y ejecución asíncrona.

## 1. 🎯 El problema

Una ruta FastAPI recibe un modelo Pydantic, lo usa como entidad, abre una `Session` global y lanza `HTTPException` desde la regla de crédito. La aplicación es corta, pero el núcleo ya depende de validación HTTP, serialización, ORM y estado global.

## 2. 🧭 Tipos con responsabilidades distintas

Una dataclass o clase ordinaria puede modelar `Order`; Pydantic valida y serializa DTO de borde; SQLAlchemy mapea registros. Compartir una clase para los tres papeles ahorra código al inicio, pero mezcla invariantes, coerción externa y ciclo de vida de sesión.

`Protocol` expresa un puerto estructural para el type checker sin exigir herencia:

```python
from typing import Protocol

class Orders(Protocol):
    def save(self, order: "Order") -> None: ...

class CreateOrder:
    def __init__(self, orders: Orders) -> None:
        self._orders = orders
```

Las anotaciones no validan runtime por sí solas. Pydantic sí procesa datos al construir un modelo y puede hacer coerción; configura modo estricto cuando aceptar conversiones silenciosas rompería el contrato.

## 3. 🔄 Composición, sesión y async

Una factory de arranque crea engine, `sessionmaker`, adapters y app. FastAPI `Depends` puede administrar recursos del borde con `yield`, pero el caso de uso no importa `Depends`. La dependencia de ruta adapta una sesión al puerto y controla cierre; la transacción debe abarcar la unidad de aplicación, no cada método de repository por separado.

```python
def build_create_order(session_factory) -> CreateOrder:
    return CreateOrder(SqlAlchemyOrders(session_factory))

def create_app(create_order: CreateOrder) -> FastAPI:
    app = FastAPI()
    # La ruta valida DTO, construye comando y llama create_order.
    return app
```

`Session` y `AsyncSession` son objetos con estado; no se comparten entre threads o tareas concurrentes. Async ayuda cuando las librerías de I/O son async, pero no vuelve no bloqueante a un driver síncrono. Decide una cadena coherente y mueve trabajo bloqueante fuera del event loop cuando corresponda.

## 4. 🧩 Errores y pruebas

El adapter traduce `IntegrityError`, ausencia y timeout a errores propios, conservando la causa con `raise ... from exc`. El dominio no lanza `HTTPException`; la ruta convierte `OrderNotFound` o `InsufficientInventory` a su contrato HTTP. Un bloque `except Exception` que pierde la causa destruye diagnóstico y suele mezclar fallos recuperables.

pytest prueba dominio y aplicación sin FastAPI. `TestClient` o un cliente async prueba rutas, Pydantic y handlers de errores. SQLAlchemy se prueba con una base compatible, sesiones nuevas y rollback o datos aislados. Los overrides de dependencias son útiles en tests HTTP, pero no reemplazan el contrato del adapter real.

## 5. 🧰 Contraste de plataforma

| Plataforma | Qué da hecho | Qué te deja a ti | Trampa frecuente |
|---|---|---|---|
| Java | contratos nominales y contenedor | limitar anotaciones y proxies | cargar framework para toda regla |
| Node/TS | tipos borrados y módulos async | validación runtime y tokens | creer que compilar valida JSON |
| Go | interfaces implícitas y wiring | lifecycle manual y errores | crear abstracciones demasiado pronto |
| Python | `Protocol`, Pydantic, FastAPI y context managers | disciplina de tipos, scopes y async | compartir DTO, ORM y dominio por comodidad |

## 6. ⚖️ Decisión y coste

Usa clases simples en el núcleo y reserva validadores/ORM para bordes cuando existen reglas o ritmos de cambio distintos. En un CRUD pequeño, un modelo compartido puede ser aceptable si no filtra sesión ni contrato público y se registra la excepción. La separación añade mappers y type checking; a cambio reduce fallos tardíos propios del tipado gradual.

## ⚠️ Errores frecuentes

- “Duck typing elimina la necesidad de contratos.” Hace más importante probar la semántica.
- “Pydantic es el modelo de dominio.” Es excelente para datos de borde, no posee invariantes por defecto.
- “`Depends` debe aparecer en el caso de uso.” Pertenece a la composición FastAPI.
- “Una `Session` global simplifica transacciones.” Comparte estado y ownership entre requests.
- “`async def` vuelve async cualquier llamada.” Un driver bloqueante sigue bloqueando.

## 7. ✅ Veredicto

Mantén el núcleo en Python ordinario, expresa puertos con `Protocol` cuando aporten claridad y usa Pydantic, FastAPI y SQLAlchemy en adaptadores. Controla sesión, transacción y tarea async desde bordes explícitos.

## 📚 Referencias

- [Python 3.14: `typing.Protocol`](https://docs.python.org/3/library/typing.html#typing.Protocol)
- [Pydantic: models y validación](https://pydantic.dev/docs/validation/latest/concepts/models/)
- [FastAPI: dependencies](https://fastapi.tiangolo.com/tutorial/dependencies/)
- [FastAPI: testing](https://fastapi.tiangolo.com/tutorial/testing/)
- [SQLAlchemy 2.1: Session](https://docs.sqlalchemy.org/en/21/orm/session.html)
- [SQLAlchemy 2.1: transacciones](https://docs.sqlalchemy.org/en/21/orm/session_transaction.html)

## 🧠 Preguntas

1. 🟢 ¿Qué papel cumple `Protocol`?
2. 🟢 ¿Qué valida un modelo Pydantic?
3. 🟢 ¿Qué debería modelar una clase de dominio Python?
4. 🟢 ¿Dónde se construye la aplicación FastAPI?
5. 🟢 ¿Qué recurso representa una `Session`?
6. 🟢 ¿Qué conserva `raise ... from exc`?
7. 🟡 ¿Por qué las anotaciones no validan runtime solas?
8. 🟡 ¿Cuándo activarías validación estricta en Pydantic?
9. 🟡 ¿Por qué `Depends` no entra al caso de uso?
10. 🟡 ¿Cómo delimitas una transacción de aplicación?
11. 🟡 ¿Por qué no compartes `AsyncSession` entre tareas?
12. 🟡 ¿Qué ocurre si llamas un driver síncrono desde `async def`?
13. 🟡 ¿Dónde traduces `IntegrityError`?
14. 🟡 ¿Qué prueba haces con `TestClient`?
15. 🟡 ¿Qué límite tienen los dependency overrides?
16. 🟡 ¿Cuándo aceptarías un modelo compartido?
17. 🟠 El dominio lanza `HTTPException`. ¿Qué contrato introduces?
18. 🟠 Una `Session` global mezcla dos requests. ¿Cómo rediseñas su scope?
19. 🟠 Pydantic convierte `"10"` a entero y el contrato exigía rechazo. ¿Qué ajustas?
20. 🟠 Un adapter captura `Exception` y devuelve `None`. ¿Qué información perdiste?
21. 🟠 Una ruta async ejecuta ORM síncrono lento. ¿Qué riesgo operativo aparece?
22. 🟠 El modelo SQLAlchemy se devuelve como response. ¿Qué fronteras quedan acopladas?
23. 🟠 Todos los tests reemplazan la dependencia de DB. ¿Qué prueba falta?
24. 🟠 ¿Cuándo una clase concreta es más clara que un `Protocol`?

**Siguiente:** [Matriz de decisión y plantilla de servicio](06-matriz-de-decision-y-plantilla-de-servicio.md).
