# Prompt base: temario de POO y patrones de diseño para entrevistas

Este documento es el **contrato de contenido** de `03-poo-y-patrones/`: qué cubre cada archivo, qué
confusiones tiene que desmontar, qué código se escribe y en qué lenguajes, y con qué otros documentos
se toca. La forma —tono, plantillas, callouts, cantidad de preguntas— la manda
[`guia-de-estilo-y-convenciones.md`](guia-de-estilo-y-convenciones.md), que es normativa y gana sobre
este documento en todo lo que declare. El orden de producción lo manda
[`plan-de-produccion.md`](plan-de-produccion.md).

**Audiencia:** alguien que ya programa en algún lenguaje orientado a objetos y se prepara para
entrevistas de **Backend Senior, Arquitecto o Tech Lead**, con Java como lenguaje de la entrevista.
No se explica qué es una variable, un bucle ni una clase en su sintaxis más básica; sí se explica todo
lo que pasa cuando esa clase se compara, se copia, se hereda o se guarda en un mapa. **No se asume
leído ningún otro curso** (§1.2 de la guía).

**La aportación propia de este corpus**, y lo que hay que proteger en cada documento:

- **la base que se aprende a los golpes**, dicha de frente y en orden;
- **cada patrón en C++ (como nació y como se escribe hoy) y en Java**, con lo que el lenguaje
  absorbió;
- **los antipatrones** con su salida;
- **las rutas**, para que nadie tenga que leer todo.

**Baseline de versiones:** C++23; Java 17 y 21 como versiones de trabajo (código en 21, alternativa
en Java 17 siempre) y Java 25 solo en callouts; C#, en su última versión estable (§5.3 de la guía). Las
versiones exactas de compiladores y runtimes se fijan en la tanda técnica. Donde este documento dice
*verificar*, la duda es real y se resuelve antes de escribir.

> **Vigencia:** 2026-10-04. **Estado:** corpus completo (T0–T26 cerradas): 74 capítulos, 13 simulaciones, 13
> solucionarios y 14 README, más el bloque opcional `14-talleres` (seis talleres, su solucionario, su README y el
> laboratorio), aprobado el 2026-10-04 en su versión intermedia y escrito en T26.

**Salto rápido:** [1](#1--inventario-de-archivos) · [2](#2--cómo-se-lee-la-ficha) · [B01](#3--bloque-01--modelo-de-objetos) · [B02](#4--bloque-02--modelado-oo) · [B03](#5-️-bloque-03--principios-de-diseño) · [B04](#6--bloque-04--creacionales) · [B05](#7--bloque-05--estructurales) · [B06](#8--bloque-06--comportamiento) · [B07](#9-️-bloque-07--fowler-dominio-y-datos) · [B08](#10--bloque-08--fowler-presentación-distribución-y-base) · [B09](#11--bloque-09--ddd-táctico-y-otros) · [B10](#12--bloque-10--concurrencia) · [B11](#13--bloque-11--los-diferentes) · [B12](#14-️-bloque-12--antipatrones) · [B13](#15--bloque-13--patrones-en-la-práctica) · [README](#16--el-readmemd-del-corpus) · [Fuera](#17--qué-queda-fuera-y-por-qué) · [Talleres](#18--los-talleres)

---

# 1. 📦 Inventario de archivos

```text
03-poo-y-patrones/
├── README.md                                   qué es, rutas, mapa, versiones
├── prompts/
│   ├── guia-de-estilo-y-convenciones.md        normativa editorial
│   ├── prompt-base.md                          este documento
│   ├── prompts-de-fase.md                      el prompt de cada tanda
│   ├── plan-de-produccion.md                   tandas, estado, bitácora y checklist (se conserva)
│   └── verificar-corpus.py                     enlaces, anclas, preguntas, rutas
├── 01-modelo-de-objetos/
│   ├── 01-identidad-estado-y-referencias.md
│   ├── 02-igualdad-identidad-y-hash.md
│   ├── 03-inmutabilidad-y-objetos-especiales.md
│   ├── 04-copia-ciclo-de-vida-y-recursos.md
│   ├── 05-polimorfismo-y-despacho.md
│   ├── 06-herencia-vertical-y-horizontal.md
│   ├── 07-genericos-y-varianza.md
│   ├── 08-la-ausencia-y-el-error.md
│   ├── 09-simulacion-de-entrevista.md
│   └── 10-respuestas.md
├── 02-modelado-oo/
│   ├── 01-uml-lo-justo-en-mermaid.md
│   ├── 02-de-la-asociacion-al-codigo.md
│   ├── 03-navegabilidad-y-coherencia.md
│   ├── 04-agregacion-composicion-y-propiedad.md
│   ├── 05-redundancia-controlada.md
│   ├── 06-entidades-valores-y-primitivos.md
│   ├── 07-objetos-frente-a-tablas.md
│   ├── 08-simulacion-de-entrevista.md
│   └── 09-respuestas.md
├── 03-principios-de-diseno/
│   ├── 01-encapsulacion-de-verdad.md
│   ├── 02-solid-sin-catecismo.md
│   ├── 03-grasp.md
│   ├── 04-acoplamiento-cohesion-y-dependencias.md
│   ├── 05-diseno-por-contrato.md
│   ├── 06-simulacion-de-entrevista.md
│   └── 07-respuestas.md
├── 04-creacionales/
│   ├── 01-factory-method.md
│   ├── 02-abstract-factory.md
│   ├── 03-builder.md
│   ├── 04-prototype.md
│   ├── 05-singleton.md
│   ├── 06-inyeccion-de-dependencias-e-ioc.md
│   ├── 07-mas-alla-del-gof.md
│   ├── 08-simulacion-de-entrevista.md
│   └── 09-respuestas.md
├── 05-estructurales/
│   ├── 01-adapter.md
│   ├── 02-decorator.md
│   ├── 03-proxy.md
│   ├── 04-facade.md
│   ├── 05-composite.md
│   ├── 06-bridge.md
│   ├── 07-flyweight.md
│   ├── 08-simulacion-de-entrevista.md
│   └── 09-respuestas.md
├── 06-comportamiento/
│   ├── 01-strategy.md
│   ├── 02-template-method.md
│   ├── 03-observer.md
│   ├── 04-command.md
│   ├── 05-chain-of-responsibility.md
│   ├── 06-state.md
│   ├── 07-visitor.md
│   ├── 08-iterator-y-mediator.md
│   ├── 09-memento-e-interpreter.md
│   ├── 10-simulacion-de-entrevista.md
│   └── 11-respuestas.md
├── 07-fowler-dominio-y-datos/
│   ├── 01-logica-de-dominio.md
│   ├── 02-fuentes-de-datos.md
│   ├── 03-comportamiento-objeto-relacional.md
│   ├── 04-estructura-objeto-relacional.md
│   ├── 05-metadatos-y-consultas.md
│   ├── 06-simulacion-de-entrevista.md
│   └── 07-respuestas.md
├── 08-fowler-presentacion-distribucion-y-base/
│   ├── 01-presentacion-web.md
│   ├── 02-distribucion.md
│   ├── 03-concurrencia-offline.md
│   ├── 04-estado-de-sesion.md
│   ├── 05-patrones-base.md
│   ├── 06-simulacion-de-entrevista.md
│   └── 07-respuestas.md
├── 09-ddd-tactico-y-otros/
│   ├── 01-entidad-valor-y-agregado.md
│   ├── 02-eventos-servicios-y-fabricas.md
│   ├── 03-specification-null-object-y-type-object.md
│   ├── 04-simulacion-de-entrevista.md
│   └── 05-respuestas.md
├── 10-concurrencia/
│   ├── 01-inmutabilidad-y-confinamiento.md
│   ├── 02-esperar-y-coordinar.md
│   ├── 03-producer-consumer-y-thread-pool.md
│   ├── 04-future-y-active-object.md
│   ├── 05-reactor-y-proactor.md
│   ├── 06-inicializacion-perezosa-segura.md
│   ├── 07-simulacion-de-entrevista.md
│   └── 08-respuestas.md
├── 11-los-diferentes/
│   ├── 01-go.md
│   ├── 02-javascript-y-typescript.md
│   ├── 03-python.md
│   ├── 04-simulacion-de-entrevista.md
│   └── 05-respuestas.md
├── 12-antipatrones/
│   ├── 01-code-smells-dentro-de-una-clase.md
│   ├── 02-code-smells-entre-clases.md
│   ├── 03-antipatrones-de-diseno-oo.md
│   ├── 04-el-patron-mal-usado.md
│   ├── 05-antipatrones-de-codigo-y-de-proceso.md
│   ├── 06-simulacion-de-entrevista.md
│   └── 07-respuestas.md
└── 13-patrones-en-la-practica/
    ├── 01-patrones-en-spring.md
    ├── 02-patrones-en-el-jdk-y-la-stl.md
    ├── 03-refactorizar-hacia-patrones.md
    ├── 04-como-se-elige.md
    ├── 05-simulacion-final.md
    └── 06-respuestas.md
└── 14-talleres/                                opcional (guía §13.2)
    ├── README.md
    ├── 01-caracterizacion.md
    ├── 02-igualdad-hash-e-inmutabilidad.md
    ├── 03-partir-el-god-object.md
    ├── 04-strategy-y-state.md
    ├── 05-chain-y-decorator.md
    ├── 06-eventos-y-bloqueo-optimista.md
    ├── 07-respuestas.md
    └── laboratorio/
        ├── legado/                             el punto de partida, sin pruebas
        └── estados/01 … 06/                    el laboratorio al cerrar cada taller
```

Cada bloque tiene además su `README.md`, que se escribe en la tanda de cierre. Los talleres se aprobaron
después de T25: `14-talleres/` tiene sus fichas en §18 y se escribió en T26.

# 2. 🧭 Cómo se lee la ficha

Cada entrada de las secciones 3 a 15 tiene este molde:

- **Objetivo** — la frase que el lector debe poder decir después de leerlo.
- **Plantilla y nivel** — cuál de las plantillas de §6 de la guía, y el nivel de cada patrón.
- **Cubre** — el contenido mínimo obligatorio. Es el piso, no el índice.
- **Código** — qué se escribe y en qué lenguajes, con el inserto de lenguaje si lo hay.
- **Desmonta** — las sobregeneralizaciones de entrevista que tiene que atacar. **Al menos una.**
- **Se toca con** — los enlaces internos obligatorios.
- **Ruta corta: sí** — solo en los capítulos de la ruta "entrevista esta semana", que se escriben
  autocontenidos (§12 de la guía).

Lo que **no** está en la ficha puede entrar si se justifica; lo que **sí** está no se omite sin
declararlo en el propio documento.

---

# 3. 🧩 Bloque `01` — Modelo de objetos

**Qué hace el bloque:** dice qué hace el lenguaje con los objetos —en memoria, al compararlos, al
copiarlos, al heredarlos, al destruirlos— y fija el vocabulario de todo el corpus. Es la base que se
aprende a los golpes. Banda de preguntas: 20–30. `## N. 🧬 En los lenguajes` obligatoria en `01/02`
a `01/06`.

## `01/01` — Identidad, estado y referencias

- **Objetivo:** decir qué copia una asignación y qué recibe un método, en C++ y en Java, y dibujarlo.
- **Plantilla:** concepto (§6.1).
- **Cubre:**
  - Objeto como identidad + estado + comportamiento.
  - **Los cuatro pilares** (abstracción, encapsulación, herencia, polimorfismo): una frase precisa por
    pilar, su simplificación habitual y el capítulo dueño de cada uno; el matiz de que la lista es
    didáctica (los cuatro elementos mayores de Booch son abstracción, encapsulación, modularidad y
    jerarquía) y de que la herencia es el pilar más prescindible (Go). Añadido a petición de Oskar tras
    T5, por ser pregunta de apertura habitual.
  - En Java, variables de tipo referencia: la asignación copia la referencia. *Aliasing*: `titular` y
    `ana` apuntan a la misma `Persona`, y una mutación por un nombre se ve por el otro.
  - **Java pasa todo por valor, y el valor de una variable de objeto es una referencia**: mutar el
    objeto recibido se ve fuera; reasignar el parámetro no.
  - En C++, el valor por defecto: la asignación copia el objeto; `&`, `const&` y puntero como formas
    de no copiar; dónde vive el objeto (pila contra heap) y por qué no es lo mismo que "valor o
    referencia".
  - El diagrama de memoria en Mermaid como herramienta del corpus.
  - `==` en Java compara referencias (adelanto de `01/02`); `null` como ausencia de referencia
    (adelanto de `01/08`).
- **Código:** C++ y Java. Tabla `🧬` recomendada: C# (`class` contra `struct`, `ref`), Python
  (nombres ligados a objetos, "paso por asignación"), JS (como Java para objetos), Go (valor por
  defecto, punteros explícitos).
- **Desmonta:** "los cuatro pilares son la definición de la POO" · "abstracción y encapsulación son lo
  mismo" · "Java pasa los objetos por referencia" · "una asignación copia el objeto" · "en C++ los
  objetos van siempre en el heap" · "si lo paso a un método, el método no puede cambiarlo".
- **Se toca con:** `01/02`, `01/04`, `02/04`.

## `01/02` — Igualdad, identidad y hash

- **Objetivo:** escribir `equals` y `hashCode` (y `operator==` y `std::hash`) de `Documento`, decir
  qué campos y por qué, y explicar qué se rompe si no.
- **Plantilla:** concepto, con autopsia de bug.
- **Cubre:**
  - Identidad (`==`) contra igualdad de valor (`equals`).
  - **El contrato de `equals`** (reflexiva, simétrica, transitiva, consistente, `null`) y **el de
    `hashCode`**: iguales implican mismo hash, y no al revés.
  - Cómo usa `HashMap` los dos: cubo por hash, comparación por `equals`. Sobrescribir uno solo
    compila y rompe el mapa.
  - **Autopsia: la clave mutable**: el `Documento` cuyo número se corrige dentro de un `HashSet`.
  - `equals` con herencia: `getClass()` contra `instanceof`, y por qué no hay forma de extender una
    clase instanciable añadiendo un campo de valor sin romper el contrato (Bloch). Preferir
    composición o clases finales; records.
  - `compareTo` coherente con `equals`: `new BigDecimal("1.0")` y `new BigDecimal("1.00")`, dos
    elementos en `HashSet`, uno en `TreeSet`. Consecuencia para `Dinero`.
  - Igualdad por identidad o por clave natural en una entidad (adelanto de `02/06` y `09/01`).
  - C++20: `operator==` y `<=>` por defecto; `std::hash<T>` para `unordered_map`.
  - La caché de `Integer` y el `==` que funciona hasta 127 (dueño: `01/03`; aquí se nombra).
- **Código:** C++ y Java completos. Tabla `🧬`: C++ · Java · C# (`Equals`/`GetHashCode`, `record`) ·
  Python (`__eq__` deja `__hash__ = None` si no se define) · JS (sin igualdad de valor; `Map` por
  identidad, *SameValueZero*, `NaN`) · Go (structs comparables; slices y mapas no pueden ser clave).
- **Desmonta:** "con sobrescribir `equals` basta" · "`equals` con `instanceof` siempre está bien" ·
  "dos `BigDecimal` con el mismo valor son `equals`" · "`hashCode` distinto implica objetos distintos,
  y al revés".
- **Se toca con:** `01/03`, `02/06`, `07/03`, `09/01`.
- **Ruta corta: sí.**

## `01/03` — Inmutabilidad y objetos especiales

- **Objetivo:** explicar por qué `String`, los enums y los records son como son, y hacer inmutable una
  clase de verdad, no solo de nombre.
- **Plantilla:** concepto.
- **Cubre:**
  - **`String` inmutable y por qué**: seguridad (rutas, URLs, nombres de clase), hash cacheado,
    compartible entre hilos sin sincronizar, el *pool* y `intern()`.
  - **Enums**: una instancia por constante, creada por la JVM; comparables con `==`; con campos y
    comportamiento; `EnumMap`, `EnumSet`; `values()`; el enum como Singleton y como Multiton
    (adelanto de `04/05` y `04/07`).
  - La caché de `Integer` (−128 a 127) y el `==` que falla en 128.
  - Records: inmutabilidad **superficial**, el record con un campo `List`.
  - Las virtudes de lo inmutable: seguro entre hilos, clave de mapa válida, se comparte sin copia,
    atomicidad ante fallos, razonamiento local.
  - **No modificable contra inmutable**: `Collections.unmodifiableList` es una vista que cambia si
    cambia el original; `List.of` y `List.copyOf` no.
  - `final` no hace inmutable al objeto; copias defensivas en el constructor y en los getters.
  - C++: `const` (en el objeto, en el método, en la referencia), `const` no es transitivo a través de
    punteros.
  - `Pais` como objeto inmutable compartido: ¿`enum` o clase? (adelanto de `05/07`).
- **Código:** C++ y Java. Tabla `🧬`: C++ (`const`) · Java · C# (`readonly`, `init`, `record`) · Python
  (tuplas, `frozen`) · JS (`Object.freeze` superficial) · TS (`readonly` solo en compilación) · Go (sin
  `const` para structs; inmutabilidad por convención).
- **Desmonta:** "`final` hace inmutable al objeto" · "`unmodifiableList` es inmutable" · "los enums son
  constantes numéricas" · "lo inmutable es lento porque copia todo" · "un record es inmutable".
- **Se toca con:** `01/02`, `02/06`, `08/05`, `10/01`.
- **Ruta corta: sí.**

## `01/04` — Copia, ciclo de vida y recursos

- **Objetivo:** decir cuándo una copia comparte estado, cómo se copia bien en cada lenguaje, y quién
  libera qué —memoria y recursos— y cuándo.
- **Plantilla:** concepto.
- **Cubre:**
  - Copia superficial contra profunda, con `Persona` y su lista de documentos.
  - Por qué `clone()` está roto en Java (Bloch): `Cloneable` sin método, copia superficial, `final`
    incompatible; el constructor de copia y la fábrica de copia.
  - C++: constructor de copia, asignación, movimiento; **regla de 0/3/5**; cuándo el compilador los
    genera; *copy elision*.
  - Construcción: **no llamar métodos sobrescribibles desde el constructor** (autopsia); el `this`
    que escapa antes de terminar de construir.
  - Destrucción: destructores deterministas en C++ contra GC en Java; el GC libera memoria, no
    archivos ni sockets; `finalize` obsoleto (y eliminado como mecanismo útil), `Cleaner` como red de
    seguridad.
  - **RAII** como idea (dueño de la idea; el patrón está en `04/07`) frente a `try-with-resources`,
    `using` y `with`.
- **Código:** C++ y Java. Tabla `🧬`: C++ · Java · C# (`IDisposable`, `using`) · Python (`with`,
  `copy.deepcopy`) · JS (`structuredClone`) · Go (`defer`, copia de structs con slices compartidos).
- **Desmonta:** "`clone()` hace copia profunda" · "el GC cierra los recursos" · "en C++ siempre hay
  que escribir destructor" · "mover es copiar más rápido".
- **Se toca con:** `01/01`, `04/04`, `04/07`.

## `01/05` — Polimorfismo y despacho

- **Objetivo:** predecir qué método se llama cuando se cruzan sobrecarga y sobrescritura, y explicar
  por qué Visitor existe.
- **Plantilla:** concepto, con autopsia de bug.
- **Cubre:**
  - Los cuatro polimorfismos: subtipo, paramétrico, *ad hoc* (sobrecarga), coerción.
  - **La sobrecarga se resuelve al compilar por el tipo estático; la sobrescritura al ejecutar por el
    tipo dinámico del receptor.** Autopsia: `validar(Documento)` y `validar(Pasaporte)` llamados con
    una variable de tipo `Documento`.
  - Despacho estático contra dinámico; *single dispatch* y por qué no hay *double dispatch* (la raíz
    de Visitor, `06/07`).
  - La vtable en un diagrama Mermaid: el costo real de una llamada virtual.
  - C++: `virtual`, `override`, `final`; el **destructor virtual** y el borrado por puntero a la base;
    **el *slicing*** al pasar por valor (autopsia).
  - Ocultar contra sobrescribir: métodos estáticos y atributos no son polimórficos.
- **Código:** C++ y Java. Tabla `🧬`: C++ (no virtual por defecto) · Java (virtual por defecto) · C#
  (`virtual`/`override` explícitos, `new` para ocultar) · Python y JS (todo dinámico, sin sobrecarga
  real) · Go (sin herencia: despacho por interfaz).
- **Desmonta:** "polimorfismo es herencia" · "Java elige el método más específico al ejecutar" · "los
  atributos se sobrescriben" · "en C++ todos los métodos son virtuales".
- **Se toca con:** `01/06`, `06/07`.
- **Ruta corta: sí.**

## `01/06` — Herencia vertical y horizontal

- **Objetivo:** decidir entre heredar, implementar, mezclar y componer, y resolver el diamante en
  cada lenguaje.
- **Plantilla:** concepto.
- **Cubre:**
  - **Vertical**: herencia de implementación; la clase base frágil; **LSP** con el contraejemplo
    clásico del cuadrado y el rectángulo nombrado en prosa y demostrado con el dominio (un
    `DocumentoQueNoVence` que rompe un contrato de `Documento`).
  - **Horizontal**: interfaces con métodos `default`; mixins; **traits** (mención breve a PHP, con su
    `insteadof`, a Scala y a Rust).
  - **El diamante**: herencia virtual en C++; la regla de `default` en Java (la clase gana, luego la
    interfaz más específica, si no, sobrescribir con `X.super.m()`); MRO C3 en Python.
  - **Composición antes que herencia**, y delegación.
  - Clase abstracta contra interfaz hoy.
  - Persona y organización: ¿superclase "parte"?
  - Jerarquías selladas (`sealed`), abiertas contra cerradas, y el *expression problem*.
- **Código:** C++ y Java. Tabla `🧬`: C++ (herencia múltiple, virtual) · Java · C# (sin herencia
  múltiple de clases, interfaces con implementación por defecto) · Python (MRO) · JS (prototipos,
  mixins) · Go (sin herencia, *embedding*).
- **Desmonta:** "la herencia es para reutilizar código" · "es-un basta para heredar" · "las interfaces
  no tienen implementación" · "la herencia múltiple es mala en sí".
- **Se toca con:** `01/05`, `03/02`, `05/02`, `06/02`, `11/01`.
- **Ruta corta: sí.**

## `01/07` — Genéricos y varianza

- **Objetivo:** decir por qué `List<Pasaporte>` no es un `List<Documento>`, escribir la firma con
  comodines correcta, y explicar qué queda de un genérico al ejecutar.
- **Plantilla:** concepto.
- **Cubre:**
  - Arrays covariantes en Java y `ArrayStoreException`.
  - Invarianza de los genéricos; **PECS** (*producer extends, consumer super*) con `Collections.copy`.
  - *Type erasure*: sin `new T()`, sin `instanceof List<String>`, los `Class<T>` como testigos de
    tipo.
  - Plantillas de C++: monomorfización, costo en tamaño del binario, *concepts* como contrato.
  - Varianza en el sitio de uso (Java) contra en la declaración (C# `in`/`out`, Kotlin).
- **Código:** C++ y Java. Tabla `🧬`: C++ · Java · C# (reificados) · TS (varianza estructural, poco
  sólida) · Go (genéricos desde 1.18, sin varianza).
- **Desmonta:** "`List<Pasaporte>` es un `List<Documento>`" · "los genéricos de Java existen al
  ejecutar" · "las plantillas de C++ son genéricos como los de Java".
- **Se toca con:** `01/05`, `04/01`.

## `01/08` — La ausencia y el error en el modelo

- **Objetivo:** decidir cómo se modela "no hay" y "salió mal" en una firma, y defenderlo.
- **Plantilla:** concepto.
- **Cubre:**
  - `null` y su costo.
  - `Optional`: para retornos, no para campos ni parámetros; `get()` sin comprobar como antipatrón.
  - Null Object como adelanto (dueño: `09/03`).
  - Excepciones *checked* contra *unchecked* como decisión de diseño, y por qué la discusión sigue.
  - La excepción como parte del contrato (`03/05`).
  - C++: `std::optional`, `std::expected` (C++23), excepciones contra códigos de error.
  - Go: el error como valor, en una línea con enlace a `11/01`.
- **Código:** C++ y Java.
- **Desmonta:** "`Optional` elimina los `NullPointerException`" · "las *checked exceptions* fueron un
  error y punto" · "devolver `null` es lo mismo que lanzar".
- **Se toca con:** `03/05`, `09/03`, `11/01`.

## `01/09` — Simulación de entrevista

Sigue §7.2 de la guía. **Ejercicios obligatorios:** escribir `Documento` como clave de mapa
(igualdad, hash, inmutabilidad); revisar un fragmento con una clave mutable y un *slicing*; decidir
herencia o composición para persona y organización; y el que se resuelve sin patrón: un record y
listo.

## `01/10` — Respuestas

Solucionario del bloque (§7.3 y §8.3 de la guía).

---

# 4. 📐 Bloque `02` — Modelado OO

**Qué hace el bloque:** pasa del dibujo al código. Es el bloque de la navegabilidad, la multiplicidad
y la redundancia controlada, que mucha gente aprende mal o no aprende. Banda de preguntas: 20–30.
Todos los capítulos llevan al menos un diagrama Mermaid.

## `02/01` — UML lo justo, en Mermaid

- **Objetivo:** leer y dibujar un diagrama de clases informal y uno de secuencia, y decir qué
  significa cada flecha.
- **Plantilla:** concepto. **Dueño de la notación** (§5.7 de la guía).
- **Cubre:**
  - Para qué sirve el UML en un equipo y en una entrevista (pensar y discutir), y para qué no.
  - Las seis relaciones: dependencia, asociación, agregación, composición, generalización,
    realización, con su notación Mermaid.
  - Multiplicidad y navegabilidad.
  - Diagrama de secuencia mínimo.
  - **Qué no dibuja Mermaid** y cómo se aproxima.
  - Cuánto detalle poner: un diagrama por pregunta.
- **Código:** Mermaid; ningún lenguaje.
- **Desmonta:** "la flecha de una asociación dice quién depende de quién" · "agregación y composición
  son lo mismo" · "un diagrama de clases muestra todas las clases".
- **Se toca con:** `02/02`, `02/03`.

## `02/02` — De la asociación al código

- **Objetivo:** convertir cada relación del modelo en el atributo correcto, sin dudar.
- **Plantilla:** concepto.
- **Cubre:**
  - **Uno a uno → atributo; uno a varios → colección; varios a varios → colección en uno o en los dos
    lados, o una clase intermedia.**
  - Ordenada → `List`; sin duplicados → `Set` (y lo que exige de `equals`); calificada → `Map`
    (`Map<TipoDireccion, Direccion>`).
  - **La clase de asociación que se vuelve objeto**: `Empleo` entre `Persona` y `Organizacion`.
  - Opcionalidad: `0..1` y cómo se escribe sin `null` (enlace a `01/08`).
  - **El error típico**: una colección donde la relación es uno a uno, un atributo donde es uno a
    varios, una lista de ids en lugar de referencias.
- **Código:** Java y C++ (en C++, la decisión de tipo de puntero adelanta `02/04`). Mermaid al lado de
  cada caso.
- **Desmonta:** "uno a varios se modela con una lista en el lado de 'varios'" · "una relación varios a
  varios necesita siempre una clase intermedia" · "`List` sirve para todo".
- **Se toca con:** `02/01`, `02/03`, `02/04`.
- **Ruta corta: sí.**

## `02/03` — Navegabilidad y coherencia

- **Objetivo:** decidir qué puntas de una relación son navegables y, si son las dos, mantenerlas
  coherentes.
- **Plantilla:** concepto, con autopsia de bug.
- **Cubre:**
  - La pregunta que decide: **¿qué caso de uso necesita ir de este objeto a aquel?**
  - `Documento` → `TipoDocumento`, sin vuelta, y por qué.
  - El costo de la bidireccional: mantener las dos puntas; el método `agregarDocumento` que fija la
    vuelta, y el que la olvida.
  - La asociación reflexiva `tutor`, y el invariante que cruza objetos: un menor debe tener tutor.
  - **Autopsia: los ciclos** que explotan en `toString`, `equals`/`hashCode` y la serialización JSON;
    el `@Data` de Lombok y el `StackOverflowError`.
- **Código:** Java (el problema es de Java y sus herramientas); C++ en el cierre: ciclos de
  `shared_ptr` y `weak_ptr`.
- **Desmonta:** "si están relacionados, cada uno debe conocer al otro" · "la bidireccional es más
  flexible y no cuesta nada" · "el `StackOverflowError` es culpa de Jackson".
- **Se toca con:** `02/02`, `02/05`, `07/04`, `09/01`.

## `02/04` — Agregación, composición y propiedad

- **Objetivo:** decir quién es dueño del ciclo de vida de cada objeto, y expresarlo en C++ y en Java.
- **Plantilla:** concepto.
- **Cubre:**
  - Agregación contra composición como **propiedad del ciclo de vida**, no como "todo-parte".
  - En C++ es concreto: miembro por valor o `unique_ptr` (posee) contra referencia, puntero crudo que
    no posee, o `shared_ptr` (propiedad compartida y su costo).
  - En Java es conceptual: la composición se expresa no dejando escapar la referencia.
  - **No exponer la colección interna**: `List.copyOf`, vista no modificable, métodos de dominio.
- **Código:** C++ y Java.
- **Desmonta:** "en Java no hay composición porque hay GC" · "devolver la lista es encapsular" ·
  "`shared_ptr` es el puntero seguro por defecto".
- **Se toca con:** `01/04`, `02/02`, `03/01`.

## `02/05` — Redundancia controlada

- **Objetivo:** defender una redundancia en el modelo de objetos y decir qué la mantiene coherente.
- **Plantilla:** concepto.
- **Cubre:**
  - **A diferencia de un esquema relacional normalizado, en el modelo de objetos la redundancia no es
    un defecto si está controlada**, y por qué: el modelo optimiza navegación y comportamiento, no
    almacenamiento.
  - Formas: navegación en los dos sentidos; atributos derivados cacheados (`/edad`, el total de un
    extracto); **el documento principal** como referencia a un elemento de la colección; índices en
    memoria (`Map` por número).
  - **La regla: un único dueño mantiene el invariante**, y nadie más escribe las dos copias.
  - Cuándo la redundancia se vuelve bug: dos dueños, actualización fuera de la raíz, caché sin
    invalidación.
- **Código:** Java; C++ solo si cambia algo.
- **Desmonta:** "la redundancia siempre es mala" · "los datos derivados se calculan siempre al vuelo"
  · "normalizar el modelo de objetos es buena práctica".
- **Se toca con:** `02/03`, `02/07`, `09/01`.

## `02/06` — Entidades, valores y primitivos

- **Objetivo:** distinguir entidad de objeto de valor, y sacar del código los primitivos que esconden
  conceptos.
- **Plantilla:** concepto.
- **Cubre:**
  - Identidad contra valor; ciclo de vida de una entidad.
  - Objeto de valor como concepto (el patrón Value Object es de `08/05`).
  - **Obsesión por los primitivos**: `String email`, `double monto`, `String numeroDocumento`.
  - `Dinero` con `BigDecimal` y moneda; por qué no `double`.
  - Identificadores tipados (`PersonaId`).
  - **El tipo como objeto**: `TipoDocumento` contra `Cedula extends Documento`; cuándo cada uno
    (adelanto de Type Object, `09/03`).
- **Código:** C++ y Java (records en Java; tipos fuertes en C++).
- **Desmonta:** "un objeto de valor es un DTO" · "`double` sirve para dinero si redondeo" · "cada tipo
  de documento merece su subclase".
- **Se toca con:** `01/02`, `01/03`, `08/05`, `09/01`, `09/03`.

## `02/07` — Objetos frente a tablas

- **Objetivo:** explicar por qué el modelo de objetos y el relacional no coinciden, sin hablar de un
  ORM concreto.
- **Plantilla:** concepto.
- **Cubre:**
  - La FK apunta del hijo al padre; la navegación suele ir del padre a los hijos.
  - Varios a varios: tabla intermedia contra dos colecciones.
  - La herencia que la tabla no tiene (adelanto de los tres mapeos de `07/04`).
  - Identidad: clave primaria contra referencia.
  - Granularidad: un objeto de valor que no es una tabla.
  - La redundancia que una base normalizada prohíbe y el modelo admite (`02/05`).
- **Código:** Java y SQL mínimo.
- **Desmonta:** "una clase es una tabla" · "si la FK está en `documento`, `Documento` debe conocer a
  `Persona`".
- **Se toca con:** `02/05`, `07/02`, `07/04`.

## `02/08` — Simulación de entrevista

**Ejercicios obligatorios:** modelar en Mermaid un enunciado de personas, documentos y empleos, con
multiplicidad y navegabilidad justificadas; revisar un modelo con una colección donde la relación es
uno a uno y una bidireccional sin dueño; decidir una redundancia; y el que se resuelve sin patrón.

## `02/09` — Respuestas

Solucionario del bloque.

---

# 5. ⚖️ Bloque `03` — Principios de diseño

**Qué hace el bloque:** da el criterio para decidir dónde va cada responsabilidad y qué depende de
qué. Las señales de diseño roto tienen bloque propio (`12`). Banda de preguntas: 20–30.

## `03/01` — Encapsulación de verdad

- **Objetivo:** distinguir esconder campos de proteger invariantes, y aplicar *tell, don't ask*.
- **Plantilla:** concepto.
- **Cubre:** getters y setters no son encapsulación; invariantes y dónde se protegen; *tell, don't
  ask*; Ley de Demeter y su lectura razonable (no es "un punto por línea"); modelo anémico contra rico
  (el antipatrón completo es de `12/03`).
- **Código:** Java y C++.
- **Desmonta:** "con campos privados y getters ya encapsulé" · "Demeter prohíbe encadenar llamadas" ·
  "el modelo anémico es más simple".
- **Se toca con:** `02/04`, `03/02`, `12/03`.

## `03/02` — SOLID sin catecismo

- **Objetivo:** explicar cada principio con el código que lo viola y el que lo cumple, y la lectura
  equivocada de cada uno.
- **Plantilla:** concepto.
- **Cubre:** SRP como "un motivo de cambio" (actor), no "un método"; OCP con puntos de extensión, no
  "nunca tocar el código"; LSP como contrato (enlace a `01/06`); ISP e interfaces de rol; DIP como
  dirección de la dependencia hacia la política, no "siempre interfaces". Cuándo aplicar SOLID es
  ceremonia.
- **Código:** Java y C++, con el dominio.
- **Desmonta:** "SRP es una clase por método" · "OCP prohíbe modificar código" · "DIP es poner una
  interfaz a todo" · "SOLID siempre mejora el diseño".
- **Se toca con:** `01/06`, `03/04`, `12/02`.
- **Ruta corta: sí.**

## `03/03` — GRASP

- **Objetivo:** usar GRASP para responder "¿dónde pondrías esta lógica?" y traducirlo al vocabulario de
  hoy.
- **Plantilla:** concepto; **nivel B** de profundidad.
- **Cubre:** los nueve —Information Expert, Creator, Controller, Low Coupling, High Cohesion,
  Polymorphism, Pure Fabrication, Indirection, Protected Variations— con el dominio; **tabla de
  equivalencias** (Controller → application service; Pure Fabrication → Repository; Protected
  Variations → OCP y puertos).
- **Código:** Java.
- **Desmonta:** "GRASP es teoría de universidad sin uso" · "el Controller de GRASP es el controller de
  MVC".
- **Se toca con:** `03/02`, `03/04`, `07/01`.

## `03/04` — Acoplamiento, cohesión y dependencias

- **Objetivo:** medir a ojo el acoplamiento y la cohesión, y dirigir las dependencias.
- **Plantilla:** concepto. **Dueño de la inyección de dependencias como idea.**
- **Cubre:** tipos de acoplamiento (de datos, de control, de contenido, temporal); cohesión;
  dependencias hacia lo estable; **inversión e inyección de dependencias sin contenedor** (la raíz de
  composición); interfaces de rol; métricas de Martin (acoplamiento aferente y eferente,
  inestabilidad) en breve.
- **Código:** Java y C++.
- **Desmonta:** "inyección de dependencias es Spring" · "bajo acoplamiento es cero dependencias" ·
  "más interfaces, menos acoplamiento".
- **Se toca con:** `03/02`, `04/06`.

## `03/05` — Diseño por contrato y *fail fast*

- **Objetivo:** escribir precondiciones, postcondiciones e invariantes, y decidir dónde se valida.
- **Plantilla:** concepto.
- **Cubre:** Meyer; invariantes de clase (el menor con tutor); cláusulas de guarda; `Objects.requireNonNull`;
  `assert` contra excepción; validar en el constructor contra en el borde; contratos en C++ (*verificar*
  el estado de la propuesta de contratos para C++26).
- **Código:** Java y C++.
- **Desmonta:** "validar es trabajo del controlador web" · "`assert` sirve para validar entradas".
- **Se toca con:** `01/08`, `02/03`, `03/01`.

## `03/06` — Simulación de entrevista

**Ejercicios obligatorios:** aplicar SOLID a una clase `ServicioPersonas` que lo viola todo, y decir
qué principio se viola primero; decidir con GRASP dónde va la validación del tutor; revisar
encapsulación; y el que se resuelve sin patrón.

## `03/07` — Respuestas

Solucionario del bloque.

---

# 6. 🏭 Bloque `04` — Creacionales

**Qué hace el bloque:** los cinco creacionales del GoF y lo que vino después: el contenedor de
inyección, RAII, el pool. Banda de preguntas: 12–20.

## `04/01` — Factory Method y fábricas estáticas

- **Objetivo:** distinguir el Factory Method del GoF de la fábrica estática de Bloch, y elegir.
- **Plantilla y nivel:** patrón A (§6.2).
- **Cubre:** el problema (crear el `Documento` correcto según el `TipoDocumento`); el Factory Method
  del GoF (gancho en subclase); la fábrica estática (`List.of`, `Optional.of`, `valueOf`, `of`/`from`);
  el registro de fábricas por código; ventajas sobre el constructor (nombre, caché, subtipo).
- **Código:** C++98 breve; C++ moderno (`std::make_unique`, mapa de `std::function`); Java.
- **Desmonta:** "Factory Method es cualquier método que crea objetos" · "una fábrica siempre necesita
  una jerarquía".
- **Se toca con:** `04/02`, `04/06`, `09/02`.

## `04/02` — Abstract Factory

- **Objetivo:** reconocer cuándo hay familias de objetos que deben ir juntas, y cuándo no.
- **Plantilla y nivel:** B (§6.3), capítulo propio.
- **Cubre:** familias (validador y formateador de documentos por país); `DocumentBuilderFactory` del
  JDK; diferencia con Factory Method.
- **Código:** Java; C++ como contraste.
- **Desmonta:** "Abstract Factory es un Factory Method más grande".
- **Se toca con:** `04/01`.

## `04/03` — Builder

- **Objetivo:** construir objetos con muchos opcionales sin constructores telescópicos, y distinguir
  el Builder del GoF del de Bloch.
- **Plantilla y nivel:** patrón A.
- **Cubre:** el problema (`Persona` con diez campos opcionales); constructores telescópicos y
  JavaBeans; Builder de Bloch (validación en `build()`, objeto inmutable); Builder del GoF (director y
  representaciones); records y builder; Lombok `@Builder`; en C++ los *designated initializers*
  (C++20) como alternativa; functional options de Go en una línea con enlace.
- **Código:** C++98, C++ moderno, Java.
- **Desmonta:** "el Builder del GoF y el de Bloch son el mismo patrón" · "con records ya no hace falta
  Builder".
- **Se toca con:** `01/03`, `11/01`.

## `04/04` — Prototype

- **Objetivo:** copiar objetos sin conocer su clase concreta, y saber por qué en Java casi nunca se
  hace con `clone()`.
- **Plantilla y nivel:** B.
- **Cubre:** el `clone` virtual de C++ que devuelve `unique_ptr`; constructor de copia; JS como
  lenguaje de prototipos (una línea con enlace a `11/02`); registro de prototipos.
- **Código:** C++ y Java. Inserto **En C#:** `record` con `with`.
- **Desmonta:** "Prototype es `clone()`".
- **Se toca con:** `01/04`, `11/02`.

## `04/05` — Singleton, y por qué casi nunca

- **Objetivo:** escribir un Singleton seguro en tres formas, y argumentar por qué casi siempre la
  respuesta es otra.
- **Plantilla y nivel:** patrón A.
- **Cubre:** el problema; inicialización ansiosa; holder idiom; `enum`; DCL con `volatile` (dueño del
  mecanismo: `10/06`); *Meyers singleton* en C++ (estática local, segura desde C++11); **por qué es
  antipatrón**: estado global, test, dependencias ocultas, ciclo de vida; el *scope* singleton de un
  contenedor como sustituto; reflexión y serialización contra el singleton.
- **Código:** C++98, C++ moderno, Java. Callout **En Java 25:** Stable Values (*preview*).
- **Desmonta:** "Singleton garantiza una sola instancia" · "el bean singleton de Spring es el patrón
  Singleton" · "con `synchronized` en `getInstance` está resuelto".
- **Se toca con:** `04/06`, `10/06`, `12/04`.
- **Ruta corta: sí.**

## `04/06` — Contenedores de inyección e IoC

- **Objetivo:** explicar qué hace un contenedor de IoC y por qué la inyección por constructor es la
  buena.
- **Plantilla y nivel:** patrón A (sin "Cómo nació").
- **Cubre:** inversión de control; qué hace un contenedor (registro, resolución, ciclo de vida,
  *scopes*); inyección por constructor, por *setter* y por campo; Service Locator como contraste
  (antipatrón en `12/04`); Spring como ejemplo; en C++, la raíz de composición a mano.
- **Código:** Java (con y sin Spring); C++.
- **Desmonta:** "IoC e inyección de dependencias son lo mismo" · "la inyección por campo es igual de
  buena".
- **Se toca con:** `03/04`, `04/05`, `13/01`.

## `04/07` — Más allá del GoF

- **Objetivo:** reconocer cuatro patrones creacionales que el GoF no nombra y que se usan todos los
  días.
- **Plantilla:** varios patrones (§6.3). **Niveles:** RAII A · Object Pool B · Lazy Initialization B ·
  Multiton C.
- **Cubre:** RAII (dueño del patrón: `lock_guard`, `unique_ptr`, `fstream`; en Java,
  `try-with-resources` y `Cleaner`); Object Pool (pools de conexiones; cuándo sobra, con objetos
  baratos y virtual threads); Lazy Initialization (`Supplier` memoizado, holder; `std::call_once` con
  enlace a `10/06`); Multiton (el `enum` de Java).
- **Código:** C++ y Java.
- **Desmonta:** "RAII es solo para memoria" · "un pool siempre mejora el rendimiento".
- **Se toca con:** `01/04`, `10/06`.

## `04/08` — Simulación de entrevista

**Ejercicios obligatorios:** elegir la forma de crear documentos de varios países; reemplazar un
Singleton por inyección; revisar un Builder que deja objetos inválidos; y el que se resuelve sin
patrón: un constructor.

## `04/09` — Respuestas

Solucionario del bloque.

---

# 7. 🧱 Bloque `05` — Estructurales

**Qué hace el bloque:** los siete estructurales del GoF, con el foco en distinguir los que se parecen.
Banda de preguntas: 12–20.

## `05/01` — Adapter

- **Objetivo:** adaptar una interfaz ajena sin que se filtre al dominio.
- **Plantilla y nivel:** patrón A.
- **Cubre:** el problema (un servicio externo de verificación de identidad con otra interfaz); adapter
  de objeto contra de clase; `Arrays.asList`, `InputStreamReader`; el adaptador como puerto (una
  línea).
- **Código:** C++98, C++ moderno, Java. Línea con enlace: en Go, las interfaces implícitas.
- **Desmonta:** "Adapter y Facade son lo mismo".
- **Se toca con:** `05/03`, `05/04`, `11/01`.

## `05/02` — Decorator

- **Objetivo:** añadir comportamiento componiendo, y decir lo que cuesta.
- **Plantilla y nivel:** patrón A.
- **Cubre:** el problema (auditoría y reintentos sobre un repositorio de personas, sin subclases
  combinatorias); `java.io`; `Collections.unmodifiableList` como decorador; el orden de composición;
  identidad rota; `@decorator` de Python como el falso amigo (línea con enlace).
- **Código:** C++98, C++ moderno (`unique_ptr` envolviendo), Java.
- **Desmonta:** "Decorator es herencia" · "el `@decorator` de Python es el Decorator del GoF".
- **Se toca con:** `01/06`, `05/03`, `11/03`.
- **Ruta corta: sí.**

## `05/03` — Proxy, y los tres que se confunden

- **Objetivo:** distinguir Proxy de Decorator y de Adapter en una frase, y explicar por qué
  `@Transactional` falla en la llamada interna.
- **Plantilla y nivel:** patrón A. **Dueño de la distinción de los tres.**
- **Cubre:** el problema (carga perezosa de los documentos; control de acceso); proxy virtual, remoto,
  de protección; proxies dinámicos del JDK (`java.lang.reflect.Proxy`) y CGLIB; **la autoinvocación en
  Spring**; *smart pointers* como proxies en C++; la tabla de los tres.
- **Código:** C++98, C++ moderno, Java (proxy dinámico).
- **Desmonta:** "Proxy y Decorator son lo mismo" · "`@Transactional` funciona en cualquier método".
- **Se toca con:** `05/01`, `05/02`, `07/03`, `13/01`.
- **Ruta corta: sí.**

## `05/04` — Facade

- **Objetivo:** simplificar un subsistema sin convertirlo en una clase dios.
- **Plantilla y nivel:** patrón A.
- **Cubre:** el problema (alta de persona que toca validación, documentos, contactos y notificación);
  la fachada como punto de entrada; SLF4J como fachada; cuándo la fachada se vuelve God Object.
- **Código:** C++98 breve, C++ moderno, Java.
- **Desmonta:** "una fachada esconde el subsistema" (lo simplifica; el subsistema sigue accesible).
- **Se toca con:** `05/01`, `07/01`, `12/03`.

## `05/05` — Composite

- **Objetivo:** tratar igual una hoja y un grupo, y decidir dónde van las operaciones de hijos.
- **Plantilla y nivel:** patrón A.
- **Cubre:** el problema (una `Organizacion` con unidades y subunidades); transparencia contra
  seguridad (métodos de hijos en la interfaz o no); recorridos; Composite con Visitor (enlace).
- **Código:** C++98, C++ moderno (`vector<unique_ptr>`), Java.
- **Desmonta:** "Composite es cualquier árbol".
- **Se toca con:** `06/07`, `06/08`.

## `05/06` — Bridge

- **Objetivo:** reconocer la explosión de subclases en dos dimensiones y separarlas.
- **Plantilla y nivel:** B, capítulo propio.
- **Cubre:** el problema (notificaciones de vencimiento por tipo × canal); JDBC como puente;
  diferencia con Strategy y con Adapter.
- **Código:** Java; C++ como contraste.
- **Desmonta:** "Bridge es un Adapter diseñado de antemano" (es la lectura frecuente; se matiza).
- **Se toca con:** `05/01`, `06/01`.

## `05/07` — Flyweight

- **Objetivo:** reconocer el Flyweight que ya usas, y por qué casi nunca lo escribes.
- **Plantilla y nivel:** C, capítulo propio con anclaje extenso.
- **Cubre:** estado intrínseco contra extrínseco; `Integer.valueOf`, `String.intern`; `Pais` como
  instancia compartida; qué lo reemplazó (inmutabilidad, el JIT, *interning* del runtime).
- **Código:** Java.
- **Desmonta:** "Flyweight es una caché".
- **Se toca con:** `01/03`.

## `05/08` — Simulación de entrevista

**Ejercicios obligatorios:** distinguir en tres fragmentos Proxy, Decorator y Adapter; diseñar la
auditoría de un repositorio; revisar una jerarquía de notificaciones con explosión de subclases; y el
que se resuelve sin patrón.

## `05/09` — Respuestas

Solucionario del bloque.

---

# 8. 🎭 Bloque `06` — Comportamiento

**Qué hace el bloque:** los once de comportamiento del GoF. Es el bloque donde más se nota lo que el
lenguaje absorbió: lambdas, sealed types, iteradores. Banda de preguntas: 12–20.

## `06/01` — Strategy

- **Objetivo:** reemplazar un condicional que crece por algoritmos intercambiables, y saber cuándo una
  lambda basta.
- **Plantilla y nivel:** patrón A.
- **Cubre:** el problema (la comisión por tipo de cuenta, un `switch` que crece); Strategy con
  interfaz; la lambda como Strategy; `Comparator`; en C++, `std::function` contra parámetro de
  plantilla (*policy*); Strategy contra State contra Bridge.
- **Código:** C++98, C++ moderno, Java.
- **Desmonta:** "Strategy necesita una clase por algoritmo" · "Strategy y State son lo mismo".
- **Se toca con:** `05/06`, `06/02`, `06/06`.
- **Ruta corta: sí.**

## `06/02` — Template Method

- **Objetivo:** fijar el esqueleto de un algoritmo y dejar variar los pasos, y compararlo con Strategy.
- **Plantilla y nivel:** patrón A.
- **Cubre:** el problema (la validación de un documento: formato, vigencia, reglas del país);
  `AbstractList`, `HttpServlet.service`; `JdbcTemplate` y por qué su nombre engaña (usa *callbacks*,
  más cerca de Strategy); el idioma NVI de C++ (*non-virtual interface*); herencia contra composición.
- **Código:** C++98, C++ moderno, Java.
- **Desmonta:** "`JdbcTemplate` es un Template Method".
- **Se toca con:** `01/06`, `06/01`, `13/01`.

## `06/03` — Observer

- **Objetivo:** notificar cambios sin acoplar emisor y receptores, y evitar las fugas.
- **Plantilla y nivel:** patrón A.
- **Cubre:** el problema (avisar que un documento vence); Observer clásico; `java.util.Observer`
  obsoleto desde Java 9 y por qué; `PropertyChangeListener`; `Flow`; eventos de Spring (enlace a
  `13/01`); **fugas por suscripciones olvidadas**; síncrono contra asíncrono; reentrada; en C++, lista
  de `std::function` y `weak_ptr`.
- **Código:** C++98, C++ moderno, Java (secuencia en Mermaid). Inserto **En C#:** `event` y delegates.
- **Desmonta:** "Observer es publicar/suscribir con un broker" · "los observadores se liberan solos".
- **Se toca con:** `09/02`, `10/05`, `13/01`.
- **Ruta corta: sí.**

## `06/04` — Command

- **Objetivo:** convertir una petición en un objeto, y decir qué gana: deshacer, encolar, registrar.
- **Plantilla y nivel:** patrón A.
- **Cubre:** el problema (`Transferencia` como operación que se encola, se registra y se revierte);
  deshacer; colas; `Runnable` y `Callable`; la closure como Command.
- **Código:** C++98, C++ moderno (`std::function`), Java.
- **Desmonta:** "Command es un `Runnable`".
- **Se toca con:** `06/09`, `07/03`.

## `06/05` — Chain of Responsibility

- **Objetivo:** encadenar manejadores que deciden si atienden o pasan, y reconocerlo en filtros y
  *middleware*.
- **Plantilla y nivel:** patrón A.
- **Cubre:** el problema (las validaciones de un documento en cadena de `if`); cadena que se corta
  contra cadena que acumula; filtros de servlet, `SecurityFilterChain`, interceptores, *middleware*.
- **Código:** C++98, C++ moderno, Java (secuencia en Mermaid).
- **Desmonta:** "en una Chain todos los eslabones procesan la petición".
- **Se toca con:** `06/01`, `13/01`.

## `06/06` — State

- **Objetivo:** modelar un ciclo de vida sin flags, con transiciones explícitas.
- **Plantilla y nivel:** patrón A.
- **Cubre:** el problema (`Cuenta` abierta, bloqueada, cerrada, con flags booleanos); State con
  interfaz; `enum` con comportamiento; sealed interface; quién decide la transición; State contra
  Strategy.
- **Código:** C++98, C++ moderno (`std::variant` de estados como alternativa), Java.
- **Desmonta:** "State es un `enum` con un `switch`".
- **Se toca con:** `01/03`, `06/01`.

## `06/07` — Visitor, y lo que lo reemplaza

- **Objetivo:** explicar el *double dispatch*, y mostrar por qué sealed + `switch` y `std::visit` lo
  reemplazan casi siempre.
- **Plantilla y nivel:** patrón A.
- **Cubre:** el problema (reportes y exportaciones sobre la jerarquía de documentos); *double
  dispatch* (enlace a `01/05`); Visitor clásico; **sealed + pattern matching de `switch`**,
  exhaustividad comprobada por el compilador; `std::variant` + `std::visit`; el *expression problem*
  (enlace a `01/06`): cuándo Visitor sigue ganando (jerarquía abierta a operaciones, cerrada a tipos);
  uniones discriminadas de TS en una línea con enlace.
- **Código:** C++98, C++ moderno, Java 21. Callouts **En Java 17:** sin `switch` con patrones; **En
  Java 25:** `_`.
- **Desmonta:** "Visitor es para recorrer árboles" · "con sealed types Visitor no sirve nunca".
- **Se toca con:** `01/05`, `01/06`, `05/05`, `11/02`.
- **Ruta corta: sí.**

## `06/08` — Iterator y Mediator

- **Plantilla:** varios patrones. **Niveles:** Iterator B · Mediator B.
- **Objetivo:** reconocer Iterator como característica del lenguaje, y Mediator como centralización
  de la coordinación (y su riesgo).
- **Cubre:** `Iterable`/`Iterator`, `ConcurrentModificationException`, el par `begin()`/`end()` y los
  rangos de C++20, generadores; Mediator para coordinar componentes, y el Mediator que se vuelve God
  Object.
- **Código:** Java y C++.
- **Desmonta:** "hay que implementar Iterator a mano".
- **Se toca con:** `05/05`, `12/03`.

## `06/09` — Memento e Interpreter

- **Plantilla:** varios patrones. **Niveles:** Memento C · Interpreter C.
- **Objetivo:** responder "¿conoces Memento?" y "¿conoces Interpreter?" con criterio.
- **Cubre:** Memento (instantánea sin romper encapsulación; lo reemplazó la inmutabilidad y el
  historial de eventos); Interpreter (gramática pequeña como clases; lo reemplazaron los motores de
  reglas, SpEL, ANTLR). Inserto **En C#:** expression trees.
- **Código:** un bloque por patrón, en Java.
- **Desmonta:** "Interpreter se usa para escribir lenguajes".
- **Se toca con:** `01/03`, `06/04`.

## `06/10` — Simulación de entrevista

**Ejercicios obligatorios:** elegir entre Strategy, State y Template Method en tres enunciados del
dominio; reemplazar un Visitor por sealed types; diseñar las notificaciones de vencimiento sin fugas;
y el que se resuelve sin patrón: un `switch` sobre un `enum` cerrado.

## `06/11` — Respuestas

Solucionario del bloque.

---

# 9. 🗃️ Bloque `07` — Fowler: dominio y datos

**Qué hace el bloque:** la primera mitad de *PoEAA*. **Java primero y completo; C++ solo donde
aporta** (§5.2 de la guía); el inserto de C# es natural aquí. Banda de preguntas: 12–20.

## `07/01` — Organizar la lógica de dominio

- **Plantilla:** varios patrones. **Niveles:** Transaction Script A · Domain Model A · Table Module B ·
  Service Layer A.
- **Objetivo:** elegir cómo se organiza la lógica según su complejidad, y ubicar el Service Layer.
- **Cubre:** el mismo caso (alta de persona con sus documentos) escrito como Transaction Script y como
  Domain Model; cuándo cada uno; Table Module y el `DataSet` de .NET; Service Layer como frontera de
  la aplicación y como lugar de la transacción; el modelo anémico como Transaction Script disfrazado
  (enlace a `12/03`).
- **Código:** Java. Inserto **En C#:** `DataSet` y Table Module.
- **Desmonta:** "Domain Model siempre es mejor" · "Service Layer es donde va la lógica de negocio".
- **Se toca con:** `03/01`, `03/03`, `12/03`.

## `07/02` — Fuentes de datos

- **Plantilla:** varios patrones. **Niveles:** Table Data Gateway B · Row Data Gateway B · Active
  Record A · Data Mapper A.
- **Objetivo:** distinguir los cuatro, y decidir entre Active Record y Data Mapper.
- **Cubre:** cada uno con `Persona`; Active Record (Rails, Django, Panache) contra Data Mapper (JPA,
  Hibernate, SQLAlchemy); el costo de Active Record en un dominio complejo.
- **Código:** Java y SQL mínimo.
- **Desmonta:** "JPA es Active Record" · "Active Record es un antipatrón".
- **Se toca con:** `02/07`, `07/03`, `11/03`.

## `07/03` — Comportamiento objeto-relacional

- **Plantilla:** varios patrones. **Niveles:** Unit of Work A · Identity Map A · Lazy Load A. **Dueño
  de Unit of Work e Identity Map.**
- **Objetivo:** explicar qué hace el `EntityManager` por dentro, y las trampas de Lazy Load.
- **Cubre:** Unit of Work (registro de nuevos, sucios y borrados; `flush`); Identity Map (un objeto
  por fila dentro de la sesión, y por qué importa para `==`); Lazy Load (inicialización perezosa,
  proxy virtual, *ghost*, *value holder*; el N+1 y la colección perezosa fuera de sesión); los tres en
  JPA.
- **Código:** Java (una Unit of Work mínima a mano, y su equivalente en JPA). Inserto **En C#:**
  `DbContext`.
- **Desmonta:** "el Identity Map es una caché de rendimiento" · "Lazy Load siempre ahorra".
- **Se toca con:** `05/03`, `06/04`, `08/03`, `11/03`, `13/01`.
- **Ruta corta: sí.**

## `07/04` — Estructura objeto-relacional

- **Plantilla:** varios patrones. **Niveles:** Identity Field B · Foreign Key Mapping B · Embedded Value
  B · Single / Class / Concrete Table Inheritance B · Association Table Mapping C · Dependent Mapping C
  · Serialized LOB C · Inheritance Mappers C.
- **Objetivo:** mapear cada estructura del modelo a tablas, y elegir el mapeo de herencia.
- **Cubre:** cada uno con el dominio (`Direccion` como Embedded Value; documentos con tabla única o por
  clase); la tabla de decisión de los tres mapeos de herencia.
- **Código:** Java con anotaciones JPA y SQL.
- **Desmonta:** "la herencia se mapea siempre con una tabla por clase".
- **Se toca con:** `02/03`, `02/07`.

## `07/05` — Metadatos y consultas

- **Plantilla:** varios patrones. **Niveles:** Repository A · Query Object B · Metadata Mapping C.
- **Objetivo:** distinguir Repository de DAO, y decidir cuánto expone.
- **Cubre:** Repository como colección en memoria del dominio; Repository contra DAO; Spring Data;
  Query Object (Criteria API) y la `Specification` de JPA (enlace a `09/03`); Metadata Mapping como lo
  que hacen las anotaciones.
- **Código:** Java.
- **Desmonta:** "Repository y DAO son lo mismo" · "un Repository genérico para todo es buena idea".
- **Se toca con:** `07/03`, `09/01`, `09/03`.

## `07/06` — Simulación de entrevista

**Ejercicios obligatorios:** decidir entre Transaction Script y Domain Model para dos casos; explicar
qué pasa con `==` entre dos lecturas de la misma persona en una sesión y en dos; diseñar un Repository
de personas; y el que se resuelve sin patrón: un script SQL.

## `07/07` — Respuestas

Solucionario del bloque.

---

# 10. 🌐 Bloque `08` — Fowler: presentación, distribución y base

**Qué hace el bloque:** la segunda mitad de *PoEAA*. Mucho nivel C: el catálogo se cubre entero, pero
lo vivo es DTO, el bloqueo optimista, Value Object, Money y Special Case. Mismo reparto de lenguajes
que `07`. Banda de preguntas: 12–20.

## `08/01` — Presentación web

- **Plantilla:** varios patrones. **Niveles:** MVC B · Front Controller B · Page Controller C ·
  Template View C · Transform View C · Two Step View C · Application Controller C.
- **Objetivo:** ubicar cada patrón de presentación en un backend de hoy (Spring MVC, APIs).
- **Cubre:** MVC del servidor contra el original de Smalltalk; `DispatcherServlet` como Front
  Controller; las vistas de plantilla y su reemplazo por APIs JSON.
- **Código:** Java.
- **Desmonta:** "MVC es Spring MVC".
- **Se toca con:** `13/01`.

## `08/02` — Distribución

- **Plantilla:** varios patrones. **Niveles:** Data Transfer Object A · Remote Facade B.
- **Objetivo:** diseñar DTO para una frontera remota, y no confundirlos con el modelo.
- **Cubre:** la primera ley de los objetos distribuidos de Fowler; DTO con records; mapeo (a mano,
  MapStruct); DTO contra entidad expuesta; Remote Facade de grano grueso.
- **Código:** Java.
- **Desmonta:** "un DTO es un modelo anémico" · "exponer la entidad ahorra código".
- **Se toca con:** `02/06`, `08/05`.

## `08/03` — Concurrencia offline

- **Plantilla:** varios patrones. **Niveles:** Optimistic Offline Lock A · Pessimistic Offline Lock B ·
  Coarse-Grained Lock C · Implicit Lock C.
- **Objetivo:** evitar la actualización perdida entre transacciones de negocio largas.
- **Cubre:** la actualización perdida con dos personas editando a Ana; versión y `@Version`; el
  conflicto y qué se le dice al usuario; bloqueo pesimista y `SELECT ... FOR UPDATE`; el saldo de una
  cuenta como caso de bloqueo de grano grueso.
- **Código:** Java y SQL. C++ no aplica: se declara.
- **Desmonta:** "la transacción de la base evita la actualización perdida".
- **Se toca con:** `07/03`, `10/02`.

## `08/04` — Estado de sesión

- **Plantilla:** varios patrones. **Niveles:** Client · Server · Database Session State, los tres C.
- **Objetivo:** decir dónde vive el estado de una conversación con el usuario, y qué lo reemplazó.
- **Cubre:** los tres y su reemplazo por *tokens*, servicios sin estado y almacenes externos.
- **Código:** un bloque mínimo en Java.
- **Desmonta:** "un servicio sin estado no tiene estado de sesión".
- **Se toca con:** `08/01`.

## `08/05` — Patrones base

- **Plantilla:** varios patrones. **Niveles:** Value Object A · Money B · Special Case B · Gateway B ·
  Mapper C · Layer Supertype C · Separated Interface C · Registry C · Plugin C · Service Stub C · Record
  Set C. **Dueño del patrón Value Object.**
- **Objetivo:** escribir un Value Object y un `Dinero` correctos, y reconocer el resto del catálogo.
- **Cubre:** Value Object (igualdad por valor, inmutable, autovalidado); `Dinero` (moneda, `BigDecimal`,
  el reparto de centavos con `allocate`); Special Case (relación con Null Object, `09/03`); Gateway como
  envoltorio de un sistema externo; el resto en fichas C.
- **Código:** Java; C++ en Value Object y `Dinero`.
- **Desmonta:** "Value Object es un record" (es un concepto; el record es una forma de escribirlo) ·
  "el dinero se guarda en `double` con dos decimales".
- **Se toca con:** `01/02`, `02/06`, `09/03`.

## `08/06` — Simulación de entrevista

**Ejercicios obligatorios:** diseñar el DTO de alta de persona; resolver la actualización perdida en
la edición de documentos; escribir `Dinero` con su reparto; y el que se resuelve sin patrón.

## `08/07` — Respuestas

Solucionario del bloque.

---

# 11. 🧬 Bloque `09` — DDD táctico y otros

**Qué hace el bloque:** los bloques de construcción de DDD escritos en código, y tres patrones sueltos
que siguen vivos. Mismo reparto de lenguajes que `07`. Banda de preguntas: 12–20.

## `09/01` — Entidad, valor y agregado

- **Plantilla:** varios patrones. **Niveles:** Entity A · Aggregate A · Value Object (recordatorio y
  enlace).
- **Objetivo:** delimitar un agregado y proteger sus invariantes en código.
- **Cubre:** entidad e identidad; agregado y raíz; `Persona` con sus documentos como agregado;
  referencias entre agregados por identificador; un agregado por transacción; tamaño del agregado.
- **Código:** Java.
- **Desmonta:** "un agregado es una entidad con hijos" · "los agregados se referencian con objetos".
- **Se toca con:** `02/05`, `02/06`, `07/05`.

## `09/02` — Eventos, servicios y fábricas de dominio

- **Plantilla:** varios patrones. **Niveles:** Domain Event A · Domain Service A · Factory B.
- **Objetivo:** decidir cuándo una regla va en un servicio de dominio, y publicar eventos sin acoplar.
- **Cubre:** evento de dominio (`DocumentoVencido`) y dónde se publica; servicio de dominio contra
  servicio de aplicación; fábrica de dominio contra Factory Method.
- **Código:** Java.
- **Desmonta:** "un servicio de dominio es cualquier `@Service`".
- **Se toca con:** `04/01`, `06/03`.

## `09/03` — Specification, Null Object y Type Object

- **Plantilla:** varios patrones. **Niveles:** Specification B · Null Object A · Type Object B.
  **Dueño de Null Object y de Type Object.**
- **Objetivo:** reconocer tres patrones que no son del GoF y resuelven problemas diarios.
- **Cubre:** Specification (reglas combinables: documento vigente y del país; la `Specification` de
  Spring Data); Null Object (contra `null` y contra `Optional`; relación con Special Case); Type Object
  (`TipoDocumento` como caso canónico, cerrando el adelanto de `02/06`).
- **Código:** Java; C++ en Null Object.
- **Desmonta:** "Null Object esconde errores" (a veces; se dice cuándo).
- **Se toca con:** `01/08`, `02/06`, `07/05`, `08/05`.

## `09/04` — Simulación de entrevista

**Ejercicios obligatorios:** delimitar los agregados de personas, documentos y cuentas; decidir entre
subclases y Type Object para un tipo nuevo de documento; y el que se resuelve sin patrón.

## `09/05` — Respuestas

Solucionario del bloque.

---

# 12. 🔁 Bloque `10` — Concurrencia

**Qué hace el bloque:** los patrones de concurrencia de *POSA2* y de *Java Concurrency in Practice* que
siguen vivos. **Solo patrones**, con el JDK como "dónde aparece de verdad". C++ y Java completos.
Banda de preguntas: 12–20.

## `10/01` — Inmutabilidad y confinamiento

- **Plantilla:** varios patrones. **Niveles:** Immutable Object A · Thread Confinement B ·
  Thread-Specific Storage B.
- **Objetivo:** evitar la sincronización haciendo que no haga falta.
- **Cubre:** inmutable como seguro por construcción (publicación segura de campos `final`);
  confinamiento por hilo y por pila; `ThreadLocal` y su fuga en *pools*; Scoped Values.
- **Código:** C++ y Java. Callout **En Java 25:** Scoped Values final.
- **Desmonta:** "lo inmutable es seguro aunque escape `this` en el constructor".
- **Se toca con:** `01/03`, `10/06`.

## `10/02` — Esperar y coordinar

- **Plantilla:** varios patrones. **Niveles:** Monitor B · Read-Write Lock B · Guarded Suspension C ·
  Balking C.
- **Objetivo:** proteger estado compartido y esperar condiciones sin espera activa.
- **Cubre:** monitor (`synchronized`, `wait`/`notifyAll`; `std::mutex` y `std::condition_variable`); la
  espera en bucle por despertares espurios; `ReentrantReadWriteLock` y `std::shared_mutex`; Guarded
  Suspension y Balking en ficha.
- **Código:** C++ y Java. Callout **En Java 25:** `synchronized` sin *pinning* con virtual threads.
- **Desmonta:** "`notify` basta" · "un *read-write lock* siempre es más rápido".
- **Se toca con:** `08/03`, `10/03`.

## `10/03` — Producer-Consumer y Thread Pool

- **Plantilla:** varios patrones. **Niveles:** Producer-Consumer A · Thread Pool A.
- **Objetivo:** desacoplar producción y consumo, y dimensionar un pool, o no tenerlo.
- **Cubre:** `BlockingQueue`; contrapresión; `ExecutorService`; tamaño del pool según trabajo de CPU
  o de E/S; virtual threads y por qué no se ponen en un pool; en C++, cola con `condition_variable`.
- **Código:** C++ y Java.
- **Desmonta:** "con virtual threads ya no hace falta pensar en concurrencia".
- **Se toca con:** `10/02`, `10/04`.

## `10/04` — Future/Promise y Active Object

- **Plantilla:** varios patrones. **Niveles:** Future/Promise A · Active Object B.
- **Objetivo:** componer resultados asíncronos, y reconocer el Active Object.
- **Cubre:** `Future`, `CompletableFuture` y su composición; `std::future`, `std::promise`,
  `std::async`; Promise de JS en una línea con enlace; Active Object como objeto con su propio hilo y
  cola.
- **Código:** C++ y Java.
- **Desmonta:** "`future.get()` es asíncrono".
- **Se toca con:** `10/03`, `11/02`.

## `10/05` — Reactor y Proactor

- **Plantilla:** varios patrones. **Niveles:** Reactor B · Proactor B.
- **Objetivo:** explicar el bucle de eventos y por qué un servidor atiende miles de conexiones con
  pocos hilos.
- **Cubre:** Reactor (demultiplexor, `epoll`, Netty, el *event loop* de Node); Proactor (finalización
  asíncrona, `io_uring`, IOCP); por qué bloquear el bucle lo detiene todo.
- **Código:** Java (NIO `Selector`) y C++ mínimo.
- **Desmonta:** "Node es multihilo para el código del usuario".
- **Se toca con:** `06/03`, `11/02`.

## `10/06` — Inicialización perezosa segura

- **Plantilla:** varios patrones. **Niveles:** Double-Checked Locking A · Holder idiom B ·
  `std::call_once` B. **Dueño del DCL.**
- **Objetivo:** escribir una inicialización perezosa segura, y explicar por qué el DCL sin `volatile`
  está roto.
- **Cubre:** el DCL roto (autopsia: reordenamiento, publicación parcial); `volatile` y el modelo de
  memoria de Java; el holder idiom; estáticas locales en C++11 y `std::call_once`.
- **Código:** C++ y Java. Callout **En Java 25:** Stable Values (*preview*).
- **Desmonta:** "el DCL es un antipatrón y punto" · "`volatile` hace atómico el incremento".
- **Se toca con:** `04/05`, `04/07`, `10/01`.

## `10/07` — Simulación de entrevista

**Ejercicios obligatorios:** diseñar la cola de transferencias; revisar un Singleton perezoso roto;
elegir pool o virtual threads; y el que se resuelve sin patrón.

## `10/08` — Respuestas

Solucionario del bloque.

---

# 13. 🌍 Bloque `11` — Los diferentes

**Qué hace el bloque:** qué le pasa al modelo de objetos y a los patrones en lenguajes que no son C++
ni Java. Plantilla de lenguaje (§6.4 de la guía). **Los patrones de poco uso no aparecen.** Banda de
preguntas: 12–20.

## `11/01` — Go

- **Objetivo:** escribir Go sin traducir Java, y decir qué patrones cambian o desaparecen.
- **Cubre:** sin clases ni herencia; *embedding* y **por qué no despacha como un override** (la trampa
  de Template Method); interfaces implícitas (Adapter casi gratis; interfaces pequeñas en el
  consumidor); functional options en lugar de Builder; `sync.Once` en lugar del Singleton con DCL; el
  error como valor; channels, pipelines y *worker pools*; `context`.
- **Código:** Go, con Java al lado donde el contraste es el punto.
- **Desmonta:** "Go es orientado a objetos como Java" · "el *embedding* es herencia".
- **Se toca con:** `01/06`, `01/08`, `04/03`, `04/05`, `10/03`.

## `11/02` — JavaScript y TypeScript

- **Objetivo:** explicar el modelo de prototipos y qué patrones trae el lenguaje de serie.
- **Cubre:** prototipos y `class` como azúcar; `this` y su vinculación; closures en lugar de Command y
  Strategy; el módulo como Singleton; `Proxy` y `Reflect`; `EventEmitter`/`EventTarget` como Observer;
  el *event loop* como Reactor; Promise y `async`; mixins; en TS, tipado estructural, uniones
  discriminadas con `never` en lugar de Visitor, *branded types* para objetos de valor.
- **Código:** JS y TS.
- **Desmonta:** "`class` en JS es como en Java" · "TS garantiza los tipos al ejecutar".
- **Se toca con:** `04/04`, `06/07`, `10/04`, `10/05`.

## `11/03` — Python

- **Objetivo:** explicar duck typing, MRO y lo que Python hace distinto con decoradores, recursos y
  persistencia.
- **Cubre:** duck typing y `Protocol`; MRO C3 y `super()`; **`@decorator` frente al Decorator del
  GoF**; context managers; `dataclass(frozen=True)`; `singledispatch` y `match`; el Singleton con
  metaclase como antipatrón y Borg; el módulo como Singleton; **SQLAlchemy (Unit of Work + Identity Map)
  frente a Django ORM (Active Record)**.
- **Código:** Python.
- **Desmonta:** "un decorador de Python es el patrón Decorator" · "Python no tiene interfaces".
- **Se toca con:** `01/06`, `05/02`, `07/02`, `07/03`.

## `11/04` — Simulación de entrevista

**Ejercicios obligatorios:** traducir un Strategy de Java a Go, a JS y a Python; encontrar la trampa
del *embedding*; y el que se resuelve sin patrón en los tres.

## `11/05` — Respuestas

Solucionario del bloque.

---

# 14. 🏚️ Bloque `12` — Antipatrones

**Qué hace el bloque:** reconocer el diseño roto en una revisión de código y salir de él en pasos
pequeños. Plantilla de antipatrones (§6.5 de la guía). Java por defecto (§5.2). Banda de preguntas:
12–20. **Dueño de los nombres de antipatrones y *code smells*.**

## `12/01` — Code smells dentro de una clase

- **Objetivo:** nombrar los *smells* que se ven en una clase y la refactorización que los quita.
- **Cubre:** Long Method, Large Class, Long Parameter List, Primitive Obsession, Data Clumps, Switch
  Statements, Temporary Field, comentarios como desodorante, Mysterious Name; cada uno con la
  refactorización de *Refactoring* (Extract Function, Introduce Parameter Object, Replace Conditional
  with Polymorphism…).
- **Desmonta:** "un método largo siempre es malo" · "los comentarios son documentación".
- **Se toca con:** `02/06`, `06/01`, `12/02`.

## `12/02` — Code smells entre clases

- **Objetivo:** nombrar los *smells* de relación y su salida.
- **Cubre:** Feature Envy, Inappropriate Intimacy, Message Chains, Middle Man, Shotgun Surgery,
  Divergent Change, Refused Bequest, Parallel Inheritance Hierarchies, Lazy Class, Data Class,
  Speculative Generality.
- **Desmonta:** "Middle Man es siempre malo" (a veces es un Facade o un Proxy deliberado).
- **Se toca con:** `03/01`, `03/02`, `12/01`.

## `12/03` — Antipatrones de diseño OO

- **Objetivo:** reconocer los antipatrones de diseño de objetos y planificar la salida.
- **Cubre:** **God Object** (con salida completa: partir por motivo de cambio); Anemic Domain Model;
  Poltergeist; Yo-yo Problem; BaseBean; Call Super; Circle-Ellipse (LSP); Constant Interface;
  Sequential Coupling; Object Orgy.
- **Desmonta:** "un God Object se arregla partiéndolo en clases del mismo tamaño" · "el modelo anémico
  es un antipatrón siempre".
- **Se toca con:** `01/06`, `03/01`, `05/04`, `07/01`.
- **Ruta corta: sí.**

## `12/04` — El patrón mal usado

- **Objetivo:** reconocer cuándo el problema es el patrón.
- **Cubre:** Singletonitis; Service Locator; Golden Hammer; *patternitis* (patrones por currículum);
  capas de más (*lasagna code*); Abstraction Inversion; Inner-Platform Effect.
- **Desmonta:** "más patrones, mejor diseño" · "Service Locator es inyección de dependencias".
- **Se toca con:** `04/05`, `04/06`, `13/03`.

## `12/05` — Antipatrones de código y de proceso

- **Objetivo:** reconocer los antipatrones que nacen del proceso y no del diseño.
- **Cubre:** Big Ball of Mud; Spaghetti Code; Lava Flow; Boat Anchor; Copy-Paste Programming; Cargo
  Cult; Magic Numbers y Magic Strings; código muerto.
- **Desmonta:** "un Big Ball of Mud se arregla reescribiendo".
- **Se toca con:** `13/03`.

## `12/06` — Simulación de entrevista

**Revisión de código en vivo** (§7.2 de la guía): cuatro a seis fragmentos del dominio, cada uno con
defectos que nombrar, priorizar y corregir en el primer paso. Uno de ellos **no tiene ningún
antipatrón** y la respuesta correcta es aprobarlo.

## `12/07` — Respuestas

Solucionario del bloque.

---

# 15. 🔭 Bloque `13` — Patrones en la práctica

**Qué hace el bloque:** cierra el corpus donde el lector trabaja: Spring, el JDK, la STL, y la
refactorización. Banda de preguntas: 12–20.

## `13/01` — Patrones en Spring

- **Objetivo:** reconocer en Spring los patrones del corpus y las trampas que producen.
- **Cubre:** Proxy (AOP, `@Transactional`, `@Cacheable`, la autoinvocación); Template Method y
  *callbacks* (`JdbcTemplate`, `RestTemplate`); Chain of Responsibility (`SecurityFilterChain`,
  interceptores); Observer (`ApplicationEvent`, `@TransactionalEventListener`); Factory
  (`BeanFactory`, `FactoryBean`); Strategy (las interfaces conectables); Singleton del contenedor.
- **Código:** solo Java (§5.2 de la guía).
- **Desmonta:** "Spring usa el patrón Singleton".
- **Se toca con:** `04/06`, `05/03`, `06/03`, `07/03`.
- **Ruta corta: sí.**

## `13/02` — Patrones en el JDK y en la STL

- **Objetivo:** señalar el patrón en las librerías estándar que el lector usa a diario.
- **Cubre:** `java.io` (Decorator), `Iterator`, `Comparator` (Strategy), `Collections` (fábricas,
  vistas, decoradores), `java.util.concurrent`; en la STL, iteradores, *allocators*, `std::function`
  (*type erasure*), `std::variant`, RAII.
- **Código:** C++ y Java.
- **Desmonta:** "los patrones son para el código de aplicación".
- **Se toca con:** `05/02`, `06/08`.

## `13/03` — Refactorizar hacia patrones, y desde ellos

- **Objetivo:** llegar a un patrón refactorizando, y quitar uno que sobra.
- **Cubre:** Kerievsky: el patrón como destino; refactorizaciones hacia Strategy, State, Composite;
  refactorizaciones que quitan un patrón (Inline Singleton, de Visitor a sealed types); tests de
  caracterización antes de tocar nada.
- **Código:** Java.
- **Desmonta:** "se diseña con patrones desde el principio".
- **Se toca con:** `12/04`, `12/05`.

## `13/04` — Cómo se elige

- **Objetivo:** tener un árbol de decisión de todo el corpus para usarlo en voz alta.
- **Cubre:** del síntoma al patrón (o a ninguno); los pares que se confunden; las preguntas que hacer
  antes de elegir.
- **Código:** ninguno; árboles de decisión en Mermaid y tablas.
- **Desmonta:** "siempre hay un patrón para cada problema".
- **Se toca con:** todos los bloques de patrones.

## `13/05` — Simulación final

Cruza el corpus entero (§7.2 de la guía). **Ejercicios obligatorios:** modelar y diseñar de punta a
punta el alta de una persona con sus documentos y su cuenta; revisar un *pull request* con
antipatrones de tres bloques; elegir patrones para tres requisitos nuevos; y el que se resuelve sin
patrón.

## `13/06` — Respuestas

Solucionario del bloque.

---

# 16. 📄 El `README.md` del corpus

Se escribe en la tanda de cierre. Lleva:

- Qué es y qué no es, con el bloque `text` de la guía §1.
- **Las rutas de estudio** (§12 de la guía), cada una con su lista de capítulos y las horas
  recalibradas con lo que tardaron los primeros bloques. Las horas de partida salen de 2,5 h por
  capítulo y 3 h por simulación. Esta es la tabla de partida, y en T25 se comprueba con el verificador
  que cada ruta temática incluye los prerrequisitos de sus capítulos:

  | Ruta | Para quién | Capítulos | Horas |
  |---|---|---|---|
  | **Completa** | Quien quiere dominar el tema | Bloques 01–13 y, opcional, el bloque 14 de talleres | ~225 |
  | **POO rápida** | Quien tiene huecos en la base o viene de otro paradigma | `01/01`–`01/06` · `02/02`–`02/05` · `12/03` · simulación del bloque 01 | ~30 |
  | **SOLID y diseño rápida** | Quien va a una entrevista de diseño o de revisión de código | `01/06` · `03/01`, `03/02`, `03/04`, `03/05` · `12/01`–`12/03` · simulación del bloque 12 | ~23 |
  | **Patrones rápida** | Quien ya tiene la base y va por el catálogo | Los capítulos de un patrón de nivel A de los bloques 04–06 · `07/01`–`07/03` · `12/04` · `13/01` y `13/04`. **Fuera:** los diferentes, GRASP, Fowler de niveles B y C, concurrencia | ~55 |
  | **Entrevista esta semana** | Quien tiene la entrevista encima | `01/02`, `01/03`, `01/05`, `01/06`, `02/02`, `03/02`, `04/05`, `05/02`, `05/03`, `06/01`, `06/03`, `06/07`, `07/03`, `12/03`, `13/01`: los quince con **Ruta corta: sí** en su ficha | ~37 |
  | **Persistencia** | Quien trabaja con ORMs y quiere saber qué hacen por dentro | `02/07` · bloques 07 y 08 · `09/01` | ~35 |
  | **Concurrencia** | Quien necesita los patrones de concurrencia | `01/03` · bloque 10 | ~20 |
  | **Políglota** | Quien trabaja en varios lenguajes | Las tablas comparativas de los bloques 01 y 02 · bloque 11 · `13/02` | ~20 |
- El mapa de bloques con su estado.
- Las versiones ejecutadas de cada lenguaje, de la tanda técnica.
- "Qué NO está aquí": patrones de arquitectura e integración.

# 17. 🚫 Qué queda fuera, y por qué

| Tema | Por qué |
|---|---|
| Patrones de arquitectura (capas, hexagonal, microservicios, CQRS, Event Sourcing, Saga) | Son decisiones de sistema, no de objetos. Se mencionan solo como límite |
| Patrones de integración (Hohpe) | Mensajería entre sistemas |
| El bliki de Fowler más allá de lo que toca a objetos | Fuera del alcance del corpus (guía §1.1) |
| Programación funcional como paradigma | Se usa donde reemplaza un patrón (lambdas, inmutabilidad), no se enseña |
| UML formal (OCL, perfiles, diagramas de componentes y despliegue) | §1.1 de la guía |

# 18. 🔧 Los talleres

**Aprobados el 2026-10-04**, en la versión intermedia: seis talleres en Java sobre un módulo legado, con
pruebas como red y un solucionario propio. Las reglas y la plantilla están en §13.2 de la guía; el prompt,
en la tanda T26 de `prompts-de-fase.md`. Del boceto original de trece quedaron fuera Data Mapper, Unit of
Work e Identity Map a mano (los escribe `07/02`–`07/03`), Visitor frente a *sealed types* (`06/07`) y los
talleres en C++ y en los secundarios (bloque 11): los capítulos ya los cubren con código.

**Por qué rinde:** *"refactoriza este código"* es un formato de entrevista en vivo muy común, y la kata lo
entrena tal cual: leer código ajeno, protegerlo con pruebas, nombrar el *smell* y dar el paso pequeño.

**El punto de partida:** `laboratorio/legado/`, unas 560 líneas de Java 21 con H2 en memoria, feas a
propósito, sobre la extensión de cuentas y movimientos de §5.6 de la guía, y **sin pruebas**:

| Pecado | Dónde | Lo arregla |
|---|---|---|
| `GestorCuentas`, un God Object de casi 400 líneas | Todo el módulo | `14/03` |
| El mismo `SELECT` y el mismo mapeo copiados en cinco métodos | `GestorCuentas` | `14/03` |
| El dinero en `double`: comisiones con fracciones de centavo | `Cuenta`, `Movimiento` | `14/02` |
| `equals` sin `hashCode` en `Movimiento`: el depósito duplicado se aplica dos veces | `GestorCuentas.depositar` | `14/02` |
| `Cuenta` como clave de un mapa con el saldo en su `hashCode`: el extracto en caché se queda viejo | `GestorCuentas.extracto` | `14/02` |
| Un `switch` por tipo de cuenta, copiado con diferencias en retiro y transferencia | `retirar`, `transferir` | `14/04` |
| El estado en dos *flags*: una cuenta cerrada recibe transferencias y se puede bloquear | `transferir`, `bloquear` | `14/04` |
| Validaciones en cadenas de `if`, distintas en cada operación: el tope de los menores no aplica a las transferencias | `retirar`, `transferir` | `14/05` |
| Auditoría y notificaciones metidas en cada operación, con `new Notificador()` repartidos | Todo `GestorCuentas` | `14/05`, `14/06` |
| Leer, calcular y escribir el saldo sin control de concurrencia: actualizaciones perdidas | `depositar`, `retirar`, `transferir` | `14/06` |

## `14/01` — Caracterización

- **Objetivo:** congelar lo que el legado hace hoy, defectos incluidos, antes de tocarlo.
- **Cubre:** la prueba de caracterización de Feathers; el *golden master* frente a la prueba por caso; congelar
  un defecto y marcarlo; la base de datos limpia por prueba; qué no se congela (fechas, orden de los correos);
  la prueba que se pone en rojo ante un "arreglo" inocente.
- **Defecto reproducido:** los seis de la tabla, congelados en verde con un comentario que los nombra.
- **Ejercita:** `13/03`, `12/05`.
- **Desmonta:** "primero lo arreglo y después le escribo pruebas".

## `14/02` — Igualdad, hash e inmutabilidad

- **Objetivo:** sacar el dinero del `double` y arreglar las dos igualdades rotas, con la caracterización como red.
- **Cubre:** `Dinero` como Value Object inmutable (`BigDecimal` con escala 2 y moneda, redondeo explícito);
  `Movimiento` con `equals` y `hashCode` del mismo contrato; la identidad de `Cuenta` por su número y la caché
  con clave inmutable; las pruebas de caracterización que cambian a propósito.
- **Defecto reproducido:** el depósito duplicado que se aplica dos veces; el extracto viejo tras depositar y
  retirar el mismo monto; la comisión con fracción de centavo.
- **Ejercita:** `01/02`, `01/03`, `02/06`, `08/05`.
- **Desmonta:** "con `double` y redondear al mostrar alcanza".

## `14/03` — Partir el God Object

- **Objetivo:** repartir las responsabilidades de `GestorCuentas` sin cambiar su comportamiento.
- **Cubre:** Extract Class y Move Method; un repositorio con el SQL una sola vez; el comportamiento que vuelve a
  `Cuenta` (*tell, don't ask*); `GestorCuentas` como Facade que se conserva para los que lo llaman; la
  inyección por constructor en lugar de `new` repartidos.
- **Defecto reproducido:** un cambio de una columna que obliga a tocar cinco métodos.
- **Ejercita:** `12/03`, `12/02`, `03/03`, `05/04`, `07/02`.
- **Desmonta:** "un God Object se parte reescribiéndolo".

## `14/04` — Strategy y State

- **Objetivo:** sacar las comisiones del `switch` y el ciclo de vida de los *flags*.
- **Cubre:** Strategy para la política de comisión de cada tipo de cuenta (el `enum` con comportamiento como
  forma mínima); la diferencia entre retiro y transferencia que era regla y no copia; State para `ABIERTA`,
  `BLOQUEADA` y `CERRADA`, con las transiciones permitidas en un solo sitio; la migración de dos columnas a una.
- **Defecto reproducido:** la transferencia que acredita una cuenta cerrada; la cuenta cerrada y bloqueada a la
  vez.
- **Ejercita:** `06/01`, `06/06`, `09/03`.
- **Desmonta:** "un `enum` con un `switch` ya es State".

## `14/05` — Chain y Decorator

- **Objetivo:** que las reglas de una operación sean eslabones que se reutilizan, y que la auditoría envuelva
  las operaciones en lugar de vivir dentro.
- **Cubre:** Chain of Responsibility para las validaciones de retiro y transferencia, con la regla de los
  menores escrita una vez; Decorator de auditoría sobre la interfaz de las operaciones; el orden de los
  decoradores y de los eslabones.
- **Defecto reproducido:** el menor que transfiere más de lo que puede retirar.
- **Ejercita:** `06/05`, `05/02`, `03/02`.
- **Desmonta:** "la auditoría es un `if` más en cada método".

## `14/06` — Eventos y bloqueo optimista

- **Objetivo:** desacoplar las notificaciones con eventos de dominio y no perder actualizaciones concurrentes.
- **Cubre:** la cuenta que registra sus eventos y el servicio que los publica después de guardar; Observer con
  suscriptores (correo, auditoría); la actualización perdida reproducida con dos hilos; la columna `version` y
  el `UPDATE … WHERE version = ?`; un decorador de reintentos; la transacción que hace atómica la transferencia.
- **Defecto reproducido:** cien depósitos concurrentes de los que se pierden algunos.
- **Ejercita:** `09/02`, `06/03`, `08/03`, `07/03`, `10/02`.
- **Desmonta:** "con `synchronized` en el servicio basta".

## `14/07` — Respuestas

Solucionario del bloque: las preguntas en tres capas y los ejercicios con su solución corrida.
