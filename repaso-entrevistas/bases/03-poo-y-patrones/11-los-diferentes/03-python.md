# 03 — Python

> Explicar el *duck typing* y los `Protocol`, la MRO que decide a quién llama `super()`, por qué el **`@decorator` no es el
> Decorator del GoF**, y qué patrones de persistencia hay detrás de **SQLAlchemy** (Unit of Work e Identity Map) y de
> **Django** (Active Record). **Lenguajes:** Python, con Java al lado solo donde el contraste es el punto. Escrito contra
> **Python 3.14**, la última versión estable publicada en `python.org` el día de la tanda; la de la corrida se fija en la
> revisión técnica. Asume leído [`07/03` — Comportamiento objeto-relacional](../07-fowler-dominio-y-datos/03-comportamiento-objeto-relacional.md).
>
> **Vigencia:** 2026-10-03.
>
> **Versiones ejecutadas:** Python 3.14.8 (SQLAlchemy 2.1.3, Django 6.1.1) (2026-10-04).

---

## 1. 🎯 El problema

Un equipo que viene de Java tiene que auditar las operaciones del repositorio de cuentas, pero **solo en producción**.
Lee que Python tiene "decoradores" y escribe esto:

```python
def auditado(metodo):
    def envoltorio(self, *args, **kwargs):
        registrar(metodo.__name__, args)
        return metodo(self, *args, **kwargs)
    return envoltorio

class RepositorioCuentas:
    @auditado                                   # se aplica al definir la clase, no al crear un objeto
    def guardar(self, cuenta): ...
```

- Ahora **todas** las instancias auditan: las de producción, las de las pruebas y las del proceso nocturno. El `@auditado`
  se aplicó una vez, al ejecutarse la definición de la clase, y cambió la función `guardar` para siempre.
- Lo que el equipo buscaba era el Decorator del GoF ([`05/02`](../05-estructurales/02-decorator.md)): un objeto que envuelve
  **a otro objeto**, elegido al configurar. Se parecen en el nombre y en la idea de "envolver", y en nada más.
- El resto del código tiene el mismo acento: una clase abstracta `IRepositorioCuentas` con una sola implementación,
  `get_saldo()` y `set_saldo()`, y un Singleton con metaclase. Python tiene otras formas para cada una.

---

## 2. 🧱 El modelo de objetos

**Todo es un objeto, también las clases y las funciones.** Una función se pasa, se guarda y se devuelve como cualquier
valor; una clase es un objeto que crea objetos. De ahí salen casi todas las diferencias con Java.

**El *duck typing*.** El glosario de Python lo define como no mirar el tipo de un objeto para decidir si sirve, sino llamar
al método que hace falta: si tiene `guardar`, sirve como repositorio. No hace falta declarar nada.

**`Protocol`: el *duck typing* con tipos.** Desde la PEP 544, un `Protocol` describe métodos, y un verificador de tipos
acepta cualquier clase que los tenga, **sin que lo declare**: es tipado estructural, como las interfaces de Go.

```python
from typing import Protocol

class RepositorioCuentas(Protocol):              # la interfaz, definida donde se usa
    def guardar(self, cuenta: Cuenta) -> None: ...
    def por_id(self, id: CuentaId) -> Cuenta: ...

class RepositorioSqlCuentas:                     # no hereda ni declara nada
    def guardar(self, cuenta: Cuenta) -> None: ...
    def por_id(self, id: CuentaId) -> Cuenta: ...

def cerrar(repo: RepositorioCuentas, id: CuentaId) -> None: ...   # acepta RepositorioSqlCuentas
```

- "Python no tiene interfaces" es falso dos veces: tiene `Protocol` (estructural, comprobado por el verificador de tipos) y
  las clases abstractas de `abc` (nominales, comprobadas al instanciar). Lo que no tiene es la obligación de declararlas.
- Igual que en TypeScript, los tipos **no se comprueban al ejecutar**: las anotaciones son para el verificador.

**Herencia múltiple y MRO.** Python permite heredar de varias clases, y resuelve el orden de búsqueda con la **MRO C3**
(*method resolution order*). `super()` no llama a "la clase base": llama a **la siguiente en la MRO del objeto**, que puede ser
una hermana.

```python
class Repositorio:
    def guardar(self, cuenta): print("guardar")

class Auditable(Repositorio):
    def guardar(self, cuenta):
        print("auditar"); super().guardar(cuenta)

class ConReintentos(Repositorio):
    def guardar(self, cuenta):
        print("reintentar"); super().guardar(cuenta)

class RepositorioProduccion(Auditable, ConReintentos): pass

RepositorioProduccion.__mro__     # (RepositorioProduccion, Auditable, ConReintentos, Repositorio, object)
RepositorioProduccion().guardar(cta)   # imprime: auditar, reintentar, guardar
```

- El `super()` de `Auditable` llama a `ConReintentos`, que `Auditable` no conoce: lo decide la clase final. Así se componen
  los *mixins* en Python, y así lo explica la tabla de [`01/06` §10](../01-modelo-de-objetos/06-herencia-vertical-y-horizontal.md#10--en-los-lenguajes).

**Propiedades, no *getters*.** Un atributo público se convierte en `@property` el día que necesita lógica, sin cambiar a
quien lo usa. `cuenta.saldo` desde el primer día; `get_saldo()` es Java escrito en Python.

---

## 3. 🧱 Lo que el lenguaje ya trae

| Patrón | En Java | En Python |
|---|---|---|
| Strategy, Command | Interfaz y clases | Una función, o un objeto con `__call__` |
| Value Object | `record` | `@dataclass(frozen=True)` |
| RAII, *try-with-resources* | `AutoCloseable` | El *context manager*: `with`, `__enter__`/`__exit__`, `contextlib` |
| Visitor | Visitor o `switch` sellado | `functools.singledispatch` o `match` con patrones de clase |
| Iterator | `Iterable` | El protocolo de iteración y los generadores (`yield`) |
| Singleton | Holder, enum | El módulo: se ejecuta una vez y queda en `sys.modules` |
| Builder | Builder | Argumentos con nombre y valores por defecto |

- **El objeto de valor** es una línea: `@dataclass(frozen=True) class Dinero: monto: Decimal; moneda: str` da igualdad por
  valor, `hash` y la prohibición de asignar atributos. Como el `record`, es **superficial**: un campo `list` sigue siendo
  modificable.
- **El *context manager*** es el recurso con dueño de [`01/04`](../01-modelo-de-objetos/04-copia-ciclo-de-vida-y-recursos.md):
  `with sesion.begin():` confirma al salir bien y deshace si sale con excepción.

```python
@functools.singledispatch
def describir(m: Movimiento) -> str:
    raise TypeError(f"movimiento desconocido: {type(m).__name__}")

@describir.register
def _(m: Deposito) -> str:
    return f"Depósito de {m.monto}"

@describir.register
def _(m: Retiro) -> str:
    return f"Retiro de {m.monto}"
```

- `singledispatch` elige la función por el tipo del primer argumento: es el despacho que el Visitor fingía, sin `accept`.
  Como el *type switch* de Go, **no comprueba la exhaustividad**: una variante nueva cae en la función base y lanza al
  ejecutar.

---

## 4. 🔀 Los patrones que cambian de forma

**Decorator: el patrón y la sintaxis.** El `@decorator` es, según el glosario, una función que devuelve otra función, aplicada
con la sintaxis `@`; es solo azúcar para `guardar = auditado(guardar)`. Se ejecuta **al definir**, una vez, y cambia la
función para todos. El Decorator del GoF envuelve **un objeto** al **configurar**, y se puede elegir por instancia:

```python
class RepositorioAuditado:                          # el Decorator del GoF, en Python
    def __init__(self, interno: RepositorioCuentas):
        self._interno = interno
    def guardar(self, cuenta: Cuenta) -> None:
        registrar("guardar", cuenta.id)
        self._interno.guardar(cuenta)
    def por_id(self, id: CuentaId) -> Cuenta:
        return self._interno.por_id(id)

repo = RepositorioAuditado(RepositorioSqlCuentas()) if produccion else RepositorioSqlCuentas()
```

- Esta es la salida del §1: auditoría solo donde se configura. Con `Protocol`, `RepositorioAuditado` cumple la interfaz sin
  declararlo.
- Un `@decorator` **puede** implementar un Decorator (envolver funciones con reintentos o con medición), pero también un
  registro, una caché (`functools.cache`) o un Singleton. "Un decorador de Python es el patrón Decorator" confunde la
  sintaxis con una de sus aplicaciones.

**Strategy → funciones.** Ramalho dedica el cap. 10 de *Fluent Python* a esto: las estrategias de una línea son funciones, y
la tabla de comisiones es un diccionario de funciones.

**Persistencia: dos patrones de Fowler, dos librerías.** Lo que [`07/02`](../07-fowler-dominio-y-datos/02-fuentes-de-datos.md)
y [`07/03`](../07-fowler-dominio-y-datos/03-comportamiento-objeto-relacional.md) separan, Python lo tiene en sus dos ORM más
usados:

```python
# SQLAlchemy: la Session es Unit of Work + Identity Map (Data Mapper)
with Session(motor) as sesion, sesion.begin():
    ana = sesion.get(Persona, id_ana)
    ana.agregar_documento(pasaporte)                 # sin save(): la sesión registra el cambio
    assert sesion.get(Persona, id_ana) is ana        # el mapa de identidad: el mismo objeto
# al salir del bloque: flush de todo lo cambiado y commit

# Django: cada modelo se guarda a sí mismo (Active Record)
ana = Persona.objects.get(pk=id_ana)
ana.nombre = "Ana Rojas Medina"
ana.save()                                           # el objeto conoce su tabla
Persona.objects.get(pk=id_ana) is ana                # False: no hay mapa de identidad
```

- El glosario de SQLAlchemy define la `Session` como el ámbito que carga instancias, rastrea sus cambios y los persiste en
  **una sola unidad de trabajo** al hacer *flush*, y el mapa de identidad como la colección que mantiene **una sola instancia**
  por objeto de la base. Es el `EntityManager` de JPA.
- La documentación de Django dice en sus principios de diseño que los modelos encapsulan cada aspecto de un objeto
  **siguiendo el patrón Active Record de Fowler**. Es más simple y acopla el dominio a la tabla; con lógica de negocio rica,
  el precio es el de `07/02`.

---

## 5. 🪦 Los patrones que desaparecen, y por qué

- **Singleton con metaclase.** Una metaclase que guarda la única instancia funciona, y es un antipatrón en Python: esconde la
  creación, complica las pruebas y no aporta nada sobre una variable de módulo. El módulo ya se ejecuta una sola vez.
- **Borg** (todas las instancias comparten el mismo `__dict__`): da estado compartido con muchas instancias. Es el mismo estado
  global con otro disfraz; se nombra para reconocerlo.
- **Builder.** Los argumentos con nombre y los valores por defecto (`Cuenta(id, titular, tipo=AHORROS, limite_diario=None)`)
  cubren lo que en Java necesita un Builder.
- **Iterator como clase.** Un generador con `yield` lo escribe en una función.
- **Visitor.** `singledispatch` o `match` con patrones de clase.

---

## 6. 🩺 Las trampas

**El argumento por defecto mutable.** El valor por defecto se evalúa **una vez**, al definir la función:

```python
def nueva_persona(nombre, documentos=[]):          # una sola lista, compartida por todas las llamadas
    documentos_propios = documentos
    ...
ana = nueva_persona("Ana Rojas Medina")
luis = nueva_persona("Luis Rojas Paz")             # comparte la lista de documentos de Ana
```

- **Por qué parece correcto**: en Java no hay valores por defecto, y en otros lenguajes se evalúan en cada llamada. **La
  corrección**: `documentos=None` y `documentos = [] if documentos is None else documentos` dentro. **La generalización**: el
  mismo error que el atributo de clase mutable, compartido por todas las instancias.

**`super()` no es "la clase base".** Llama a la siguiente en la MRO, como en el §2: en una jerarquía con *mixins*, puede ser una
clase hermana que el autor no conoce. Por eso los métodos cooperativos aceptan `**kwargs` y siempre llaman a `super()`.

**El decorador que borra el nombre.** Un `@auditado` sin `functools.wraps` hace que la función se llame `envoltorio` en los
registros y en las trazas. Todo decorador de funciones usa `@functools.wraps(metodo)` sobre su envoltorio.

**El `frozen` superficial.** `@dataclass(frozen=True)` con un campo `list` impide reasignar el campo, no modificar la lista. Es
la misma trampa del `record` de [`01/03`](../01-modelo-de-objetos/03-inmutabilidad-y-objetos-especiales.md#5--records-inmutabilidad-superficial):
se usa `tuple` o `frozenset`.

---

## 7. 🧭 Cómo se traduce

| Patrón o idioma de Java | Forma idiomática en Python |
|---|---|
| Interfaz | `Protocol` (estructural) o clase abstracta de `abc` (nominal) |
| *Getters* y *setters* | Atributos públicos; `@property` cuando haga falta lógica |
| Strategy, Command | Funciones o *callables* |
| Decorator (GoF) | Una clase que envuelve un objeto; un `@decorator` solo si se quiere para todos |
| Value Object | `@dataclass(frozen=True)` con campos inmutables |
| *try-with-resources* | `with` y *context managers* |
| Visitor | `functools.singledispatch` o `match` |
| Singleton | Un módulo; nunca una metaclase |
| Builder | Argumentos con nombre y valores por defecto |
| JPA (`EntityManager`) | SQLAlchemy (`Session`: Unit of Work e Identity Map) |
| Active Record (Rails, Panache) | Django ORM |

**La frase en voz alta:** *"El `@decorator` de Python es una función que transforma otra al definirla; el Decorator del GoF
envuelve un objeto al configurar. Si quiero auditar solo en producción, envuelvo la instancia. Y Python sí tiene interfaces:
`Protocol` para tipado estructural y `abc` para nominal."*

---

## ⚠️ Errores frecuentes

| Se dice | Lo preciso |
|---|---|
| "Un decorador de Python es el patrón Decorator" | Es una función que transforma otra al definirla; puede implementar un Decorator, o una caché, o un registro |
| "Python no tiene interfaces" | Tiene `Protocol` (estructural) y clases abstractas de `abc`; no obliga a declararlas |
| "`super()` llama a la clase base" | Llama a la siguiente en la MRO del objeto, que puede ser una hermana |
| "Los tipos de Python se comprueban al ejecutar" | Las anotaciones son para el verificador; en ejecución no se comprueban |
| "`frozen=True` hace inmutable el objeto" | Impide reasignar campos; una lista dentro sigue siendo modificable |
| "El Singleton en Python se hace con una metaclase" | Se hace con un módulo; la metaclase es un antipatrón |
| "SQLAlchemy y Django ORM hacen lo mismo" | SQLAlchemy es Data Mapper con Unit of Work e Identity Map; Django es Active Record |

---

## 📚 Para profundizar

- **Libro** — Ramalho, *Fluent Python*, 2.ª ed. (O'Reilly, 2022), cap. 9, "Decorators and Closures", cap. 10, "Design
  Patterns with First-Class Functions", cap. 13, "Interfaces, Protocols, and ABCs", y cap. 14, "Inheritance: For Better or
  For Worse". **El que destaca.**
- **Libro** — Percival y Gregory, *Architecture Patterns with Python* (O'Reilly, 2020), cap. 2, "Repository Pattern", y cap.
  6, "Unit of Work Pattern"; libre en línea como *Cosmic Python*.
- [Python — Glosario, *decorator*](https://docs.python.org/3/glossary.html#term-decorator) y
  [*duck-typing*](https://docs.python.org/3/glossary.html#term-duck-typing)
- [PEP 544 — *Protocols: Structural subtyping*](https://peps.python.org/pep-0544/)
- [Python — *The Python 2.3 Method Resolution Order*](https://docs.python.org/3/howto/mro.html): la MRO C3.
- [SQLAlchemy 2.1 — *Session Basics*](https://docs.sqlalchemy.org/en/21/orm/session_basics.html)
- [Django — *Design philosophies*](https://docs.djangoproject.com/en/6.1/misc/design-philosophies/): los modelos siguen
  Active Record.

---

## 🧠 Preguntas

Sin respuestas aquí. Todas, con enunciado literal y respuesta en tres capas, en
[`05` — Respuestas](05-respuestas.md#03--python).

1. ¿Qué es el *duck typing*? 🟢
2. ¿Qué es un `Protocol`? 🟢
3. ¿Qué es la MRO de Python? 🟢
4. ¿Qué es un *context manager*? 🟢
5. ¿Qué diferencia hay entre un `@decorator` de Python y el patrón Decorator? 🟡
6. ¿Qué diferencia hay entre un `Protocol` y una clase abstracta de `abc`? 🟡
7. ¿Qué diferencia hay entre `@dataclass(frozen=True)` y un `record` de Java? 🟡
8. ¿Qué diferencia hay entre SQLAlchemy y el ORM de Django? 🟡
9. ¿Qué diferencia hay entre `functools.singledispatch` y el `switch` sellado de Java 21? 🟡
10. ¿Por qué `super()` puede llamar a una clase hermana? 🟠
11. ¿Por qué el Singleton con metaclase es un antipatrón en Python? 🟠
12. ¿Por qué "Python no tiene interfaces" es falso? 🟠
13. ¿Por qué un argumento por defecto mutable comparte estado entre llamadas? 🟠
14. ¿Por qué en Python no se escriben *getters* y *setters*? 🟠
15. Escribe un Decorator del GoF que audite un repositorio solo cuando se configure. 🔴
16. Revisa este código y di qué falla: `@auditado` sobre `RepositorioCuentas.guardar` para auditar solo en producción. 🔴
17. Escribe con SQLAlchemy la carga de Ana, el alta de un documento y el guardado, y señala la Unit of Work y el Identity
    Map. 🔴
18. Revisa este código y di qué falla: `def nueva_persona(nombre, documentos=[])` usado para crear a Ana y a Luis. 🔴

---

**Anterior:** [`02` — JavaScript y TypeScript](02-javascript-y-typescript.md) ·
**Siguiente:** [`04` — Simulación de entrevista](04-simulacion-de-entrevista.md) ·
**Relacionado:** [`05/02` — Decorator](../05-estructurales/02-decorator.md)
