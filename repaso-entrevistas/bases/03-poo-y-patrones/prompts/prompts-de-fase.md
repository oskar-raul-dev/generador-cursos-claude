# 🗺️ Prompts por fase

## POO y patrones de diseño — un prompt por tanda

Cada sección es el prompt completo de una tanda de [`plan-de-produccion.md`](plan-de-produccion.md),
listo para pegar al empezar la sesión que la escribe.

**Qué manda sobre qué.** El contenido de cada capítulo lo fija su ficha en
[`prompt-base.md`](prompt-base.md); la forma, [`guia-de-estilo-y-convenciones.md`](guia-de-estilo-y-convenciones.md);
el orden, el plan. Estos prompts **no repiten** las fichas: dicen qué pesa en cada capítulo, cuántas
preguntas lleva, qué hay que verificar y dónde está el riesgo. Si una ficha cambia, el prompt se
corrige después, **nunca al revés**.

**Una sesión, una tanda.** Si una sesión no cierra su tanda, la siguiente empieza por el estado que
dejó anotado en la bitácora del plan, no desde cero.

**Los números de preguntas** van como `total (🟢/🟡/🟠/🔴)` y son orientativos: se ajustan a lo que
el capítulo enseña de verdad, dentro de la banda de §8.1 de la guía y sin repetir el reparto del
vecino.

> **Vigencia:** 2026-10-03. Al día con la guía y el `prompt-base.md` de esa fecha.

**Salto rápido:** [Marco](#el-marco-común) · [T0](#t0--arranque-de-la-escritura) · [T1–T2](#t1--bloque-01-primera-mitad) · [T3–T4](#t3--bloque-02-primera-mitad) · [T5](#t5--bloque-03-entero) · [T6–T7](#t6--bloque-04-primera-mitad) · [T8–T9](#t8--bloque-05-primera-mitad) · [T10–T12](#t10--bloque-06-primer-tercio) · [T13–T14](#t13--bloque-07-primera-mitad) · [T15](#t15--bloque-08-entero) · [T16](#t16--bloque-09-entero) · [T17–T18](#t17--bloque-10-primera-mitad) · [T19](#t19--bloque-11-entero) · [T20–T21](#t20--bloque-12-primera-mitad) · [T22](#t22--bloque-13-entero) · [T23–T24](#t23--revisión-técnica-c-y-java) · [T25](#t25--cierre)

---

## El marco común

Va en todos los prompts donde dice `{{marco}}`. **No lo repitas en el documento: aplícalo.**

```markdown
## Marco (no lo repitas, aplícalo)

Corpus: `bases/03-poo-y-patrones/`. Antes de escribir, lee enteros y en este orden:
(1) `prompts/guia-de-estilo-y-convenciones.md`; (2) en `prompts/prompt-base.md`, §2 y la ficha de
cada documento de esta tanda; (3) `prompts/plan-de-produccion.md`: estado, rutina, verificaciones,
deuda de enlaces y deuda de ejecución; (4) los capítulos ya escritos que la tanda enlaza o de los
que es dueño otro capítulo (§11.1 de la guía).

Reglas que no se negocian:
- El problema antes que el patrón, en el dominio y con los datos de §5.6 (Ana, Luis, Carmen, sus
  documentos, sus cuentas). Nada de `foo`, `Animal`, `Figura` ni `MyClass`.
- La plantilla que toca (§6): concepto, patrón de nivel A, varios patrones, lenguaje o antipatrón.
  Ningún concepto ni patrón sin precio, sin "cuándo no" ni sin veredicto (los C, sin "qué lo
  reemplazó").
- Lenguajes según §5.2: C++ · Java, en ese orden, salvo la excepción declarada del bloque. A lo sumo
  un inserto de lenguaje por patrón (📝 **En C#:**, contra la última versión estable de C#). Java 17 y
  21 son las versiones de trabajo: todo lo que no exista en Java 17 lleva su alternativa en 📝 **En
  Java 17:**, siempre; Java 25 solo en callouts 📝 **En Java 25:**, donde cambia el patrón.
- Código escrito para compilar, sin `...` que oculten lo necesario. **Ninguna salida pegada como
  real**: las esperadas, con `// salida esperada, sin correr`, y anotadas en la deuda de ejecución
  del plan. Los bloques que no compilan a propósito, con `// no compila: <motivo>`.
- Diagramas en Mermaid (§5.7), doce clases como mucho, solo con la notación de su tabla; el
  renderizado se comprueba en la tanda técnica.
- **Nada sin comprobar en esta sesión:** URL (por código de estado), capítulo de libro (contra la
  edición fijada en §10.1 de la guía), JEP y su estado, característica de C++ y su estándar. Lo que
  no se pudo comprobar no se escribe.
- **Ningún enlace sale del corpus** salvo los externos de §10.1 (§1.2 de la guía). Nunca se menciona
  otro curso ni material personal.
- Ningún enlace a un documento que todavía no existe: la mención va en prosa y a la deuda de enlaces
  del plan.
- Preguntas sin respuesta en el capítulo; su solucionario, **en esta misma tanda**, con el enunciado
  copiado literal y las tres capas ⏱️ 🗣️ 🔬.
- Dominio en español sin tildes en identificadores; roles de patrón y API en inglés; comentarios en
  español (§5.1).
- Todo en el hilo principal, secuencial y sin agentes. No se instala nada. No se hace commit: git lo
  hace Oskar. No se toca ningún README antes de T25.
```

Y el **protocolo de tres pasos**, donde dice `{{protocolo}}`:

```markdown
## Cómo quiero que trabajes

**Paso 1 — Antes de escribir.** No redactes todavía. Devuélveme: (a) preguntas bloqueantes
numeradas, marcando las que puedes asumir con un valor por defecto y cuál; (b) tu lectura de cada
capítulo en una línea —el problema con el que abre, el código que escribe y en qué lenguajes, lo que
desmonta—; (c) la lista de URLs, libros, JEPs y características de C++ que vas a comprobar, y cómo;
(d) el reparto de preguntas 🟢🟡🟠🔴 de cada capítulo, distinto del vecino; (e) cualquier
contradicción con lo ya escrito —dímela, no la resuelvas—.
**Paso 2 — Redacción**, cuando yo responda: capítulo a capítulo, en el orden de la tanda, y después de
cada uno su parte del solucionario. Si aparece una duda nueva, **para y pregunta** en vez de rellenar
con un supuesto plausible.
**Paso 3 — Cierre de la tanda:** el checklist de §14 de la guía por archivo, `python3
prompts/verificar-corpus.py` con su salida, la deuda de enlaces y la de ejecución actualizadas, las
casillas del checklist del plan marcadas y una entrada en su bitácora. Repórtalo en lista corta.
```

---

## T0 — Arranque de la escritura

```markdown
Esta es la sesión de la **tanda T0** del corpus `03-poo-y-patrones`. Entregables: las trece
carpetas de bloque y el esqueleto de los trece solucionarios.

{{marco}}

## Qué se hace

- Crear `01-modelo-de-objetos/` … `13-patrones-en-la-practica/` con los nombres exactos del
  inventario (§1 del `prompt-base.md`).
- En cada una, su `NN-respuestas.md` en esqueleto: título, blockquote de encabezado con `Vigencia:`,
  un `# NN — Tema` por capítulo y por la simulación con la nota "pendiente", **sin enlaces** a
  capítulos que todavía no existen.
- Correr `python3 prompts/verificar-corpus.py` y comprobar que solo da avisos de "pendiente".

{{protocolo}}
```

---

## T1 — Bloque 01, primera mitad

```markdown
Esta es la sesión de la **tanda T1**. Entregables: `01/01` a `01/04` en `01-modelo-de-objetos/`, y
sus respuestas en `10-respuestas.md`.

{{marco}}

## Identidad de la tanda

- Primera tanda de escritura: **fija el tono, el dominio y el diagrama de memoria** para todo el
  corpus. Lo que se decida aquí sobre cómo se dibuja una referencia en Mermaid lo usan los 73
  capítulos restantes.
- Banda 200–350 líneas; 20–30 preguntas. `🧬 En los lenguajes` obligatoria en `01/02`–`01/04`.

## Capítulo por capítulo

**`01/01` Identidad, estado y referencias** · 22 (6/6/6/4). Pesa: el diagrama de memoria del
*aliasing* y la demostración de "Java pasa referencias por valor" (mutar contra reasignar el
parámetro). Riesgo: que C++ se quede en "tiene punteros"; tiene que mostrar que el valor es el
defecto. Verificar: nada externo salvo las URLs de la JLS y de cppreference que se citen.

**`01/02` Igualdad, identidad y hash** · 28 (6/7/9/6). **Ruta corta: autocontenido.** Pesa: la
autopsia de la clave mutable con el pasaporte de Ana, y el par `BigDecimal` en `HashSet` contra
`TreeSet`. Riesgo: alargarse con `equals` y herencia; va en una sección, con Bloch. Verificar: el
ítem de *Effective Java* 3.ª ed. para `equals`/`hashCode`; el `@implSpec` de `Object.equals` en la
API de Java 21; `operator<=>` por defecto en cppreference.

**`01/03` Inmutabilidad y objetos especiales** · 26 (7/6/8/5). **Ruta corta: autocontenido.**
Pesa: por qué `String` es inmutable, enums con comportamiento, y "no modificable contra inmutable".
Riesgo: que el record pase por inmutable sin la salvedad del campo `List`. Verificar: la caché de
`Integer` en la Javadoc de `Integer.valueOf`; el ítem de *Effective Java* sobre minimizar la
mutabilidad.

**`01/04` Copia, ciclo de vida y recursos** · 24 (6/6/7/5). Pesa: la regla de 0/3/5, el método
sobrescribible en el constructor (autopsia) y "el GC no cierra recursos". Riesgo: invadir `04/07`
(RAII como patrón); aquí es la idea. Verificar: el estado de `finalize` en Java 21 (JEP 421) y la
Javadoc de `Cleaner`.

{{protocolo}}
```

## T2 — Bloque 01, segunda mitad

```markdown
Esta es la sesión de la **tanda T2**. Entregables: `01/05` a `01/08`, la simulación `01/09` y el
solucionario `01/10` completo.

{{marco}}

## Identidad de la tanda

- Cierra el bloque 01. Banda 200–350; 20–30 preguntas. `🧬` obligatoria en `01/05` y `01/06`.

## Capítulo por capítulo

**`01/05` Polimorfismo y despacho** · 26 (5/8/8/5). **Ruta corta.** Pesa: la autopsia sobrecarga ×
sobrescritura y el *slicing*. La vtable en Mermaid. Verificar: JLS §15.12 (resolución de métodos) por
URL exacta.

**`01/06` Herencia vertical y horizontal** · 28 (6/7/9/6). **Ruta corta.** Pesa: el diamante en
tres lenguajes y LSP con el dominio. Traits de PHP en **una** mención breve. Riesgo: pasar de 350;
si pasa, se poda el *expression problem* a un párrafo con enlace a `06/07`. Verificar: la regla de
resolución de métodos `default` en la JLS; la MRO C3 en la documentación de Python.

**`01/07` Genéricos y varianza** · 22 (5/6/7/4). Pesa: PECS con un ejemplo de documentos, y lo que
el *erasure* prohíbe. Verificar: la sección de comodines del tutorial oficial o de la JLS.

**`01/08` La ausencia y el error en el modelo** · 22 (6/5/7/4). Pesa: `Optional` solo como retorno,
y `std::expected`. Verificar: `std::expected` en cppreference (C++23); la Javadoc de `Optional` y su
nota de uso.

**`01/09` Simulación de entrevista.** Sigue §7.2 de la guía y los ejercicios obligatorios de su
ficha. 30–45 `S#` con "las que descolocan"; 4–6 ejercicios con `**Fuerza:**`, uno sin patrón.

{{protocolo}}
```

---

## T3 — Bloque 02, primera mitad

```markdown
Esta es la sesión de la **tanda T3**. Entregables: `02/01` a `02/04` en `02-modelado-oo/`, y sus
respuestas en `09-respuestas.md`.

{{marco}}

## Identidad de la tanda

- **Fija la notación Mermaid** del corpus (`02/01` es su dueño). Todo diagrama usa solo la notación de
  la tabla de §5.7, porque los de esta tanda son el modelo que copian los demás.
- Banda 200–350; 20–30 preguntas.

## Capítulo por capítulo

**`02/01` UML lo justo, en Mermaid** · 22 (8/6/5/3). Carga hacia 🟢 y 🟡: es vocabulario. Pesa: las
seis relaciones y lo que Mermaid no dibuja, dicho como limitación de la herramienta. Verificar: la
página de `classDiagram` en `mermaid.js.org` por URL exacta; *UML Distilled*, capítulo del diagrama
de clases.

**`02/02` De la asociación al código** · 26 (6/6/8/6). **Ruta corta.** Pesa: la tabla relación →
atributo, `Empleo` como clase de asociación y el error típico. Riesgo: quedarse en Java; el C++ de
cada caso adelanta `02/04`.

**`02/03` Navegabilidad y coherencia** · 24 (5/6/8/5). Pesa: la pregunta del caso de uso, el
`agregarDocumento` que fija la vuelta y la autopsia del ciclo en `toString`/`equals`/JSON.
Verificar: el comportamiento de `@Data` de Lombok en su documentación oficial.

**`02/04` Agregación, composición y propiedad** · 22 (5/6/7/4). Pesa: la propiedad en C++ con los
tres tipos de puntero, y no exponer la colección. Verificar: las *C++ Core Guidelines* sobre
propiedad (sección R) por URL exacta.

{{protocolo}}
```

## T4 — Bloque 02, segunda mitad

```markdown
Esta es la sesión de la **tanda T4**. Entregables: `02/05` a `02/07`, la simulación `02/08` y el
solucionario `02/09` completo.

{{marco}}

## Capítulo por capítulo

**`02/05` Redundancia controlada** · 22 (4/6/7/5). Pesa: **la tesis del capítulo** —en el modelo de
objetos la redundancia no es un defecto si un único dueño mantiene el invariante— y el documento
principal de Ana como ejemplo. Riesgo: que suene a "desnormalizar"; es otra cosa, y se dice.

**`02/06` Entidades, valores y primitivos** · 24 (6/6/7/5). Pesa: `Dinero` con `BigDecimal` y
moneda, la obsesión por los primitivos, y `TipoDocumento` contra subclases (adelanto, sin invadir
`09/03`).

**`02/07` Objetos frente a tablas** · 20 (5/6/6/3). Pesa: la dirección de la FK contra la de la
navegación. Riesgo: convertirse en un capítulo de JPA; el ORM es de `07`.

**`02/08` Simulación de entrevista.** Ejercicios de su ficha: modelar en Mermaid es obligatorio.

{{protocolo}}
```

---

## T5 — Bloque 03 entero

```markdown
Esta es la sesión de la **tanda T5**. Entregables: `03/01` a `03/05`, la simulación `03/06` y el
solucionario `03/07` completo.

{{marco}}

## Identidad de la tanda

- Banda 200–350; 20–30 preguntas. Es la tanda de la ruta "SOLID y diseño".

## Capítulo por capítulo

**`03/01` Encapsulación de verdad** · 22 (5/6/7/4). Pesa: getters no son encapsulación, *tell,
don't ask*, Demeter razonable.

**`03/02` SOLID sin catecismo** · 28 (7/7/8/6). **Ruta corta.** Pesa: la lectura equivocada de cada
principio. Riesgo: el catecismo; cada principio con código que lo viola en el dominio.
Verificar: la formulación de SRP como "actor" en las fuentes de Robert C. Martin que se citen.

**`03/03` GRASP** · 20 (6/6/5/3). Nivel B. Pesa: la tabla de equivalencias. Verificar: Larman
3.ª ed., capítulos de GRASP.

**`03/04` Acoplamiento, cohesión y dependencias** · 22 (5/6/7/4). Pesa: inyección de dependencias
sin contenedor (dueño de la idea).

**`03/05` Diseño por contrato y *fail fast*** · 20 (5/5/6/4). Pesa: el invariante del menor con
tutor. Verificar: el estado de los contratos en C++26 (P2900) antes de mencionarlo.

{{protocolo}}
```

---

## T6 — Bloque 04, primera mitad

```markdown
Esta es la sesión de la **tanda T6**. Entregables: `04/01` a `04/04` en `04-creacionales/`, y sus
respuestas en `09-respuestas.md`.

{{marco}}

## Identidad de la tanda

- **Primera tanda de patrones: estrena la plantilla de nivel A** (§6.2 de la guía). Lo que se decida
  aquí sobre el largo de "Cómo nació" y el reparto C++/Java lo heredan todos los patrones.
- Banda 250–400 en los capítulos de un patrón A; 200–350 en el resto. Preguntas 12–20.

## Capítulo por capítulo

**`04/01` Factory Method y fábricas estáticas** · 16 (4/4/5/3). Pesa: la diferencia GoF/Bloch y el
registro de fábricas por código de `TipoDocumento`. Verificar: el ítem 1 de *Effective Java* 3.ª ed.

**`04/02` Abstract Factory** · 12 (3/4/3/2). Nivel B. Riesgo: inflarlo.

**`04/03` Builder** · 16 (4/5/4/3). Pesa: GoF contra Bloch, y *designated initializers* de C++20.
Verificar: el ítem 2 de *Effective Java* 3.ª ed.

**`04/04` Prototype** · 12 (3/3/4/2). Nivel B. Inserto **En C#:** `record` con `with`. Verificar: la
documentación de `with` en `learn.microsoft.com`.

{{protocolo}}
```

## T7 — Bloque 04, segunda mitad

```markdown
Esta es la sesión de la **tanda T7**. Entregables: `04/05` a `04/07`, la simulación `04/08` y el
solucionario `04/09` completo.

{{marco}}

## Capítulo por capítulo

**`04/05` Singleton, y por qué casi nunca** · 18 (4/4/6/4). **Ruta corta.** Pesa: tres formas
seguras y el argumento contra. El DCL se nombra y enlaza a `10/06` (dueño), que todavía no existe: a
la deuda de enlaces. Callout **En Java 25:** Stable Values. Verificar: JEP 502 y su estado.

**`04/06` Contenedores de inyección e IoC** · 16 (4/4/5/3). Pesa: inyección por constructor y el
contraste con Service Locator. Verificar: la sección de inyección de dependencias de la referencia
de Spring Framework por URL exacta.

**`04/07` Más allá del GoF** · 18 (5/4/5/4). RAII A, Object Pool B, Lazy Initialization B, Multiton C.

**`04/08` Simulación de entrevista.**

{{protocolo}}
```

---

## T8 — Bloque 05, primera mitad

```markdown
Esta es la sesión de la **tanda T8**. Entregables: `05/01` a `05/04` en `05-estructurales/`, y sus
respuestas en `09-respuestas.md`.

{{marco}}

## Capítulo por capítulo

**`05/01` Adapter** · 14 (4/4/4/2). Verificar: Javadoc de `Arrays.asList` e `InputStreamReader`.

**`05/02` Decorator** · 16 (4/5/4/3). **Ruta corta.** Pesa: `java.io` y el precio (identidad rota,
orden de composición). El `@decorator` de Python, una línea con mención en prosa a `11/03` (deuda).

**`05/03` Proxy, y los tres que se confunden** · 18 (4/6/5/3). **Ruta corta.** Pesa: la tabla de los
tres y la autoinvocación de Spring. Verificar: Javadoc de `java.lang.reflect.Proxy`; la sección de
proxies AOP de la referencia de Spring.

**`05/04` Facade** · 14 (4/4/4/2). Riesgo: confundirlo con Service Layer; la diferencia va en
"Con qué se confunde".

{{protocolo}}
```

## T9 — Bloque 05, segunda mitad

```markdown
Esta es la sesión de la **tanda T9**. Entregables: `05/05` a `05/07`, la simulación `05/08` y el
solucionario `05/09` completo.

{{marco}}

## Capítulo por capítulo

**`05/05` Composite** · 16 (4/4/5/3). Pesa: transparencia contra seguridad con la organización.

**`05/06` Bridge** · 12 (3/4/3/2). Nivel B. Pesa: la explosión tipo × canal.

**`05/07` Flyweight** · 12 (4/3/3/2). Nivel C con anclaje extenso. Verificar: Javadoc de
`String.intern`.

**`05/08` Simulación de entrevista.**

{{protocolo}}
```

---

## T10 — Bloque 06, primer tercio

```markdown
Esta es la sesión de la **tanda T10**. Entregables: `06/01` a `06/04` en `06-comportamiento/`, y sus
respuestas en `11-respuestas.md`.

{{marco}}

## Capítulo por capítulo

**`06/01` Strategy** · 16 (4/5/4/3). **Ruta corta.** Pesa: la lambda como Strategy y `std::function`
contra plantilla.

**`06/02` Template Method** · 16 (4/4/5/3). Pesa: NVI en C++ y por qué `JdbcTemplate` engaña.
Verificar: la Javadoc de `JdbcTemplate` y su uso de *callbacks*.

**`06/03` Observer** · 18 (4/5/5/4). **Ruta corta.** Pesa: las fugas, síncrono contra asíncrono.
Inserto **En C#:** `event`. Diagrama de secuencia. Verificar: la deprecación de `java.util.Observer`
en la API de Java 21.

**`06/04` Command** · 14 (3/4/4/3). Pesa: `Transferencia` con deshacer.

{{protocolo}}
```

## T11 — Bloque 06, segundo tercio

```markdown
Esta es la sesión de la **tanda T11**. Entregables: `06/05` a `06/07`, y sus respuestas.

{{marco}}

## Capítulo por capítulo

**`06/05` Chain of Responsibility** · 14 (4/4/4/2). Diagrama de secuencia.

**`06/06` State** · 16 (4/4/5/3). Pesa: la `Cuenta` sin flags, y State contra Strategy.

**`06/07` Visitor, y lo que lo reemplaza** · 18 (4/5/5/4). **Ruta corta.** Pesa: *double dispatch*,
sealed + `switch`, `std::visit`, y cuándo Visitor todavía gana. Callouts **En Java 17** y **En Java
25**. Verificar: JEP 441 (pattern matching de `switch`, final en 21), JEP 456; `std::visit` en
cppreference.

{{protocolo}}
```

## T12 — Bloque 06, cierre

```markdown
Esta es la sesión de la **tanda T12**. Entregables: `06/08` y `06/09`, la simulación `06/10`, el
solucionario `06/11` completo, y **la decisión sobre los talleres**.

{{marco}}

## Capítulo por capítulo

**`06/08` Iterator y Mediator** · 14 (4/4/4/2). Dos B.

**`06/09` Memento e Interpreter** · 12 (4/3/3/2). Dos C. Inserto **En C#:** expression trees.

**`06/10` Simulación de entrevista.**

## La decisión de los talleres

Al cerrar, presenta a Oskar el boceto de §18 del `prompt-base.md` y lo que costaron T6–T12 en sesiones y líneas, y pregúntale si se hacen
los talleres. Si dice que sí, la siguiente sesión es de preparación: reglas en §13.2 de la guía,
fichas en el `prompt-base.md`, `prompts-de-taller.md` y tandas nuevas en el plan, **antes** de T13.

{{protocolo}}
```

---

## T13 — Bloque 07, primera mitad

```markdown
Esta es la sesión de la **tanda T13**. Entregables: `07/01` a `07/03` en
`07-fowler-dominio-y-datos/`, y sus respuestas en `07-respuestas.md`.

{{marco}}

## Identidad de la tanda

- **Cambia el reparto de lenguajes**: Java primero y completo, C++ solo donde aporta, y declarado
  (§5.2 de la guía). El inserto de C# es natural.
- Plantilla de varios patrones (§6.3). Banda 200–350.

## Capítulo por capítulo

**`07/01` Organizar la lógica de dominio** · 16 (4/4/5/3). Pesa: el mismo caso en Transaction
Script y en Domain Model. Verificar: *PoEAA*, capítulos de lógica de dominio.

**`07/02` Fuentes de datos** · 16 (4/5/4/3). Pesa: Active Record contra Data Mapper.

**`07/03` Comportamiento objeto-relacional** · 18 (4/5/5/4). **Ruta corta.** Pesa: una Unit of Work
mínima escrita a mano y su equivalente en JPA; `==` dentro y fuera de la sesión. Inserto **En C#:**
`DbContext`. Verificar: la Javadoc de `EntityManager` de Jakarta Persistence por URL exacta.

{{protocolo}}
```

## T14 — Bloque 07, segunda mitad

```markdown
Esta es la sesión de la **tanda T14**. Entregables: `07/04` y `07/05`, la simulación `07/06` y el
solucionario `07/07` completo.

{{marco}}

## Capítulo por capítulo

**`07/04` Estructura objeto-relacional** · 18 (5/5/5/3). Pesa: la tabla de decisión de los tres
mapeos de herencia con los documentos.

**`07/05` Metadatos y consultas** · 16 (4/4/5/3). Pesa: Repository contra DAO. Verificar: la
referencia de Spring Data JPA sobre repositorios y `Specification`.

**`07/06` Simulación de entrevista.**

{{protocolo}}
```

---

## T15 — Bloque 08 entero

```markdown
Esta es la sesión de la **tanda T15**. Entregables: `08/01` a `08/05`, la simulación `08/06` y el
solucionario `08/07` completo.

{{marco}}

## Identidad de la tanda

- El bloque con más nivel C del corpus. **Riesgo principal: la ficha C que se alarga.** Dos frases,
  un bloque, por qué es raro, qué lo reemplazó.

## Capítulo por capítulo

**`08/01` Presentación web** · 14 (5/4/3/2).
**`08/02` Distribución** · 14 (3/4/4/3). Pesa: DTO con records y la primera ley de los objetos
distribuidos. Verificar: la URL del artículo de Fowler en `martinfowler.com`.
**`08/03` Concurrencia offline** · 16 (4/4/5/3). Pesa: la actualización perdida con Ana editada por
dos personas, y `@Version`.
**`08/04` Estado de sesión** · 12 (4/3/3/2). Tres C.
**`08/05` Patrones base** · 20 (6/5/5/4). Dueño de Value Object. Pesa: `Dinero` y su `allocate`.

{{protocolo}}
```

---

## T16 — Bloque 09 entero

```markdown
Esta es la sesión de la **tanda T16**. Entregables: `09/01` a `09/03`, la simulación `09/04` y el
solucionario `09/05` completo.

{{marco}}

## Capítulo por capítulo

**`09/01` Entidad, valor y agregado** · 18 (4/5/5/4). Pesa: `Persona` con sus documentos como
agregado; referencias por identificador. Verificar: Evans, capítulos de agregados.
**`09/02` Eventos, servicios y fábricas de dominio** · 16 (4/4/5/3).
**`09/03` Specification, Null Object y Type Object** · 18 (5/4/5/4). Dueño de Null Object y Type
Object; cierra el adelanto de `02/06`.

{{protocolo}}
```

---

## T17 — Bloque 10, primera mitad

```markdown
Esta es la sesión de la **tanda T17**. Entregables: `10/01` a `10/03` en `10-concurrencia/`, y sus
respuestas en `08-respuestas.md`.

{{marco}}

## Identidad de la tanda

- **Solo patrones**: el JDK y la STL como "dónde aparece de verdad", nunca como temario.
- C++ y Java completos.

## Capítulo por capítulo

**`10/01` Inmutabilidad y confinamiento** · 16 (4/4/5/3). Callout **En Java 25:** Scoped Values
(JEP 506). Verificar: JLS §17.5 (campos `final`); *Java Concurrency in Practice*, capítulo de
publicación segura.
**`10/02` Esperar y coordinar** · 16 (4/5/4/3). Callout **En Java 25:** JEP 491.
**`10/03` Producer-Consumer y Thread Pool** · 16 (4/4/5/3). Verificar: JEP 444 (virtual threads).

{{protocolo}}
```

## T18 — Bloque 10, segunda mitad

```markdown
Esta es la sesión de la **tanda T18**. Entregables: `10/04` a `10/06`, la simulación `10/07` y el
solucionario `10/08` completo.

{{marco}}

## Capítulo por capítulo

**`10/04` Future/Promise y Active Object** · 14 (3/4/4/3).
**`10/05` Reactor y Proactor** · 14 (4/4/4/2).
**`10/06` Inicialización perezosa segura** · 16 (3/4/5/4). Dueño del DCL: **cierra la deuda de
enlace de `04/05`**. Autopsia del DCL roto.

{{protocolo}}
```

---

## T19 — Bloque 11 entero

```markdown
Esta es la sesión de la **tanda T19**. Entregables: `11/01` a `11/03`, la simulación `11/04` y el
solucionario `11/05` completo.

{{marco}}

## Identidad de la tanda

- Plantilla de lenguaje (§6.4). El código va en Go, JS/TS y Python; Java al lado solo cuando el
  contraste es el punto.
- **Cierra la deuda de enlaces** de las líneas "en Go…", "en JS…" y "en Python…" de los bloques
  anteriores.
- Versiones: las que se fijen en T24; mientras tanto, se escribe contra la última versión estable
  publicada, comprobada en su sitio oficial, y se anota.

## Capítulo por capítulo

**`11/01` Go** · 18 (4/5/5/4). Pesa: la trampa del *embedding* y functional options.
**`11/02` JavaScript y TypeScript** · 18 (4/5/5/4). Pesa: prototipos, `this`, el *event loop*.
**`11/03` Python** · 18 (4/5/5/4). Pesa: `@decorator` contra Decorator, y SQLAlchemy contra Django.

{{protocolo}}
```

---

## T20 — Bloque 12, primera mitad

```markdown
Esta es la sesión de la **tanda T20**. Entregables: `12/01` a `12/03` en `12-antipatrones/`, y sus
respuestas en `07-respuestas.md`.

{{marco}}

## Identidad de la tanda

- **Estrena la plantilla de antipatrones** (§6.5 de la guía): síntoma, por qué aparece, qué cuesta,
  cómo se detecta, salida con código antes y después, veredicto.
- Java por defecto.

## Capítulo por capítulo

**`12/01` Code smells dentro de una clase** · 16 (5/4/4/3). Verificar: los nombres exactos de los
*smells* y refactorizaciones en *Refactoring* 2.ª ed. y en el catálogo de `refactoring.com`.
**`12/02` Code smells entre clases** · 16 (4/5/4/3).
**`12/03` Antipatrones de diseño OO** · 20 (5/5/6/4). **Ruta corta.** Pesa: el God Object con su
salida completa.

{{protocolo}}
```

## T21 — Bloque 12, segunda mitad

```markdown
Esta es la sesión de la **tanda T21**. Entregables: `12/04` y `12/05`, la simulación `12/06` y el
solucionario `12/07` completo.

{{marco}}

## Capítulo por capítulo

**`12/04` El patrón mal usado** · 16 (4/4/5/3).
**`12/05` Antipatrones de código y de proceso** · 14 (4/4/4/2). Verificar: la ficha de *AntiPatterns*
y el artículo *Big Ball of Mud* de Foote y Yoder.
**`12/06` Simulación de entrevista** · formato de revisión de código en vivo; uno de los fragmentos
está bien y se aprueba.

{{protocolo}}
```

---

## T22 — Bloque 13 entero

```markdown
Esta es la sesión de la **tanda T22**. Entregables: `13/01` a `13/04`, la simulación final `13/05` y
el solucionario `13/06` completo.

{{marco}}

## Capítulo por capítulo

**`13/01` Patrones en Spring** · 18 (4/5/5/4). **Ruta corta.** Solo Java. Verificar: las secciones
de la referencia de Spring Framework que se citen.
**`13/02` Patrones en el JDK y en la STL** · 14 (5/4/3/2).
**`13/03` Refactorizar hacia patrones, y desde ellos** · 14 (3/4/4/3). Verificar: Kerievsky, la
ficha y los nombres de las refactorizaciones.
**`13/04` Cómo se elige** · 12 (3/4/3/2).
**`13/05` Simulación final** · cruza el corpus.

{{protocolo}}
```

---

## T23 — Revisión técnica: C++ y Java

```markdown
Esta es la sesión de la **tanda T23**: la revisión técnica del código C++ y Java de todo el corpus,
en un contenedor temporal (§13.1 de la guía).

{{marco}}

## Qué se hace

1. **Pedir permiso a Oskar** para usar Docker y bajar las imágenes. Sin permiso, la tanda no empieza.
2. Fijar las versiones: GCC (14 o posterior) y JDK 17, 21 y 25, con la etiqueta exacta de cada imagen,
   comprobada ese día en su registro.
3. Bloque por bloque: armar los arneses fuera del corpus (scratchpad), compilar y ejecutar cada
   fragmento —el Java con JDK 21, sus alternativas "En Java 17" con JDK 17 y los callouts "En Java 25"
   con JDK 25—, y comprobar que los marcados `// no compila` fallan con el error que el texto dice.
4. Confirmar o corregir cada salida marcada `// salida esperada, sin correr`, y quitar la marca.
4b. Renderizar todos los diagramas Mermaid del corpus con `mermaid-cli` en el mismo contenedor, y
   corregir los que fallen.
5. Añadir `Versiones ejecutadas:` al encabezado de cada capítulo verificado.
6. Lo que no se pudo ejecutar, **se dice** en el capítulo y en la bitácora.
7. Vaciar la deuda de ejecución de C++ y Java en el plan.

**No se entregan archivos de la corrida** al corpus. El contenedor se descarta al terminar.

{{protocolo}}
```

## T24 — Revisión técnica: los secundarios

```markdown
Esta es la sesión de la **tanda T24**: la misma revisión de T23 para Go, JavaScript/TypeScript,
Python y C#: el bloque 11 entero y los insertos de lenguaje de todo el corpus.

{{marco}}

## Qué se hace

Lo mismo que en T23, con las imágenes de Go, Node, Python y .NET SDK, cuyas versiones se fijan ese
día y van al README del corpus. TypeScript se comprueba con `tsc --noEmit --strict`. **Con permiso de
Oskar** antes de bajar nada.

{{protocolo}}
```

---

## T25 — Cierre

```markdown
Esta es la sesión de la **tanda T25**: el cierre del corpus.

{{marco}}

## Qué se hace

- `README.md` del corpus (ficha en §16 del `prompt-base.md`), con **las rutas recalibradas** con lo
  que tardaron los bloques y las versiones de T23–T24.
- `README.md` de los trece bloques (§6.7 de la guía).
- `python3 prompts/verificar-corpus.py` sin errores en todo el corpus, rutas incluidas.
- Literalidad de los trece solucionarios comprobada.
- URLs externas de todo el corpus verificadas por código de estado.
- Misma `Vigencia:` en todo el corpus, o la diferencia justificada.
- **Con permiso de Oskar**: borrar `plan-de-produccion.md` y limpiar sus menciones en la guía, el
  `prompt-base.md` y estos prompts, en la misma edición.

{{protocolo}}
```

---

## T26 — Talleres

```markdown
Esta es la sesión de la **tanda T26**: el bloque opcional `14-talleres`, entero.

{{marco}}

Para esta tanda, el marco cambia en lo que declara §13.2 de la guía: **solo Java**, el código **se
compila y se corre mientras se escribe**, toda salida pegada es real, y el corpus entrega
`14-talleres/laboratorio/`. **Con permiso de Oskar** para usar Docker y bajar la imagen de Maven.

## Qué se hace

1. Preparación (en `prompts/`): las reglas y la plantilla en §13.2 de la guía, las fichas en §18 del
   `prompt-base.md`, la tanda en el plan y el verificador extendido a talleres (banda 8–12 preguntas,
   300–650 líneas, sincronía de ejercicios).
2. `laboratorio/legado/`: el módulo de §18, corrido, con sus defectos comprobados uno por uno.
3. Taller por taller, en orden: primero el código de `laboratorio/estados/NN/` partiendo del estado
   anterior, con cada paso corrido; después el `.md`, con las salidas de esas corridas; después su
   parte de `07-respuestas.md`, con el código de los ejercicios corrido contra el estado.
4. `14-talleres/README.md`, el bloque en el `README.md` del corpus (mapa, ruta completa, versiones) y
   el verificador limpio.

Los arneses de corrida viven en el *scratchpad*: el laboratorio se copia allí para compilarlo, y la
carpeta `target/` nunca se crea dentro del corpus.

{{protocolo}}
```

