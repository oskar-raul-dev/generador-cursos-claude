# 04 — Cómo se elige

> El árbol de decisión de todo el corpus, para usarlo **en voz alta**: del síntoma al patrón —o a ninguno—, los pares que se
> confunden y las preguntas que hay que hacer antes de elegir. **Excepción declarada a la plantilla**: es un capítulo sin código;
> todo va en árboles en bloque `text` y tablas, y cada rama enlaza al capítulo dueño. Asume leídos los bloques de patrones, del
> [`04`](../04-creacionales/01-factory-method.md) al [`10`](../10-concurrencia/01-inmutabilidad-y-confinamiento.md).
>
> **Vigencia:** 2026-10-03.

---

## 1. 🎯 El problema

La pregunta de entrevista no suele ser "¿qué es un Decorator?", sino esta: *"tenemos que añadir auditoría a las transferencias, pero
solo para las cuentas empresariales y sin tocar el código que ya funciona. ¿Cómo lo harías?"*. Quien estudió el catálogo de memoria
recorre los 23 nombres buscando uno que encaje. Quien estudió las tensiones hace preguntas: ¿qué varía?, ¿cuántas variantes hay hoy?,
¿quién paga el cambio?, ¿lo trae ya el lenguaje o el marco?

Este capítulo ordena esas preguntas. No sustituye a ningún capítulo: es el índice que se recorre con la cabeza en una entrevista, y
cada hoja remite al capítulo donde está el precio completo.

---

## 2. 🧭 Las cinco preguntas antes de elegir

```mermaid
flowchart TD
    p1["1. ¿Qué varía, exactamente?<br/>el algoritmo, el estado, la creación, la interfaz, la estructura, el momento"]
    p2["2. ¿Cuántas variantes reales hay hoy?<br/>una: código directo. Dos o más: ahora sí hay tensión"]
    p3["3. ¿Quién paga si cambia después?<br/>mi código: refactorizo cuando haga falta. Otros: diseño la frontera ya"]
    p4["4. ¿Lo trae el lenguaje o el marco?<br/>lambda, enum, record, sealed, try-with-resources, el contenedor, @Transactional"]
    p5["5. ¿Qué cuesta, en las cuatro monedas?<br/>indirección · acoplamiento · legibilidad · rendimiento y memoria"]
    p1 --> p2 --> p3 --> p4 --> p5
```

- La pregunta 4 es la que más patrones elimina: en Java 21, un Strategy de una línea es una lambda, un Visitor es un `switch` sellado,
  un Singleton es un bean y un Value Object es un `record` con validación. La tesis del corpus: parte de los patrones era un rodeo para
  lo que al lenguaje le faltaba ([`11`](../11-los-diferentes/01-go.md) lo muestra en tres lenguajes más).
- "Siempre hay un patrón para cada problema" es la simplificación de este capítulo: muchas veces la respuesta correcta es una función,
  un `enum`, un dato en una tabla, o nada.

---

## 3. 🧭 Crear objetos

```mermaid
flowchart LR
    n1["¿La creación es un new con validación?"]
    r2(["constructor. Sin patrón"])
    n1 -->|"sí"| r2
    n3["¿Muchos parámetros opcionales, o el objeto nace en pasos?"]
    r4(["Builder (04/03); en Go, functional options"])
    n3 -->|"sí"| r4
    q5{"¿Hay que elegir la clase concreta según algo?"}
    r6(["Type Object (09/03): un dato, no una clase"])
    q5 -->|"¿la diferencia es solo de datos?"| r6
    r7(["Factory Method (04/01)"])
    q5 -->|"¿una subclase decide qué crear?"| r7
    r8(["Abstract Factory (04/02), solo con dos familias reales"])
    q5 -->|"¿familias de objetos que van juntos?"| r8
    n9["¿Copiar un ejemplar ya configurado?"]
    r10(["Prototype (04/04), o un constructor de copia"])
    n9 -->|"sí"| r10
    q11{"¿Una sola instancia?"}
    r12(["Singleton (04/05), raro"])
    q11 -->|"¿la unicidad es un hecho del dominio o del entorno?"| r12
    r13(["un bean del contenedor, inyectado (04/06)"])
    q11 -->|"¿es comodidad de acceso?"| r13
    n14["¿Crear un agregado entero con reglas?"]
    r15(["fábrica de dominio (09/02)"])
    n14 -->|"sí"| r15
    n16["¿Caro y a menudo sin usar?"]
    r17(["inicialización perezosa: holder, DCL con volatile, call_once (10/06)"])
    n16 -->|"sí"| r17
```

---

## 4. 🧭 Componer y envolver

```mermaid
flowchart LR
    n1["¿Una interfaz que no encaja con la que necesito?"]
    r2(["Adapter (05/01)"])
    n1 -->|"sí"| r2
    n3["¿Añadir comportamiento sin tocar la clase, combinable?"]
    r4(["Decorator (05/02)"])
    n3 -->|"sí"| r4
    n5["¿Controlar el acceso: perezoso, remoto, con permisos?"]
    r6(["Proxy (05/03); en Spring, la anotación ya lo es (13/01)"])
    n5 -->|"sí"| r6
    n7["¿Esconder un subsistema detrás de una entrada simple?"]
    r8(["Facade (05/04)"])
    n7 -->|"sí"| r8
    n9["¿Parte-todo, tratar igual una hoja y un grupo?"]
    r10(["Composite (05/05)"])
    n9 -->|"sí"| r10
    n11["¿Dos dimensiones que varían por separado?"]
    r12(["Bridge (05/06)"])
    n11 -->|"sí"| r12
    n13["¿Miles de objetos que comparten la mayor parte del estado?"]
    r14(["Flyweight (05/07), casi siempre una caché de fábrica"])
    n13 -->|"sí"| r14
```

---

## 5. 🧭 Variar el comportamiento

```mermaid
flowchart LR
    n1["¿Cambia el algoritmo (la comisión por tipo de cuenta)?"]
    r2(["Strategy (06/01): lambda o enum con comportamiento"])
    n1 -->|"sí"| r2
    n3["¿Un algoritmo fijo con pasos que varían?"]
    r4(["Template Method (06/02); mejor por composición, con callbacks"])
    n3 -->|"sí"| r4
    n5["¿Otros reaccionan cuando algo pasa?"]
    r6(["Observer (06/03); en el dominio, un evento (09/02)"])
    n5 -->|"sí"| r6
    n7["¿Una operación como objeto: deshacer, encolar, auditar?"]
    r8(["Command (06/04)"])
    n7 -->|"sí"| r8
    n9["¿Varios manejadores en cadena, cada uno decide?"]
    r10(["Chain of Responsibility (06/05)"])
    n9 -->|"sí"| r10
    n11["¿El comportamiento cambia según el estado del objeto?"]
    r12(["State (06/06), o un enum o una tabla de transiciones"])
    n11 -->|"sí"| r12
    n13["¿Operaciones sobre una jerarquía cerrada?"]
    r14(["switch sobre tipos sellados; Visitor (06/07) solo sin ellos"])
    n13 -->|"sí"| r14
    n15["¿Recorrer sin exponer la estructura?"]
    r16(["Iterator (06/08): Iterable, generadores"])
    n15 -->|"sí"| r16
    n17["¿Muchos objetos que se coordinan entre sí?"]
    r18(["Mediator (06/08), sin dejar que se vuelva un God Object"])
    n17 -->|"sí"| r18
    n19["¿Guardar y restaurar un estado?"]
    r20(["objetos inmutables, o Memento (06/09)"])
    n19 -->|"sí"| r20
    n21["¿Reglas combinables con nombre del negocio?"]
    r22(["Specification (09/03); un Predicate en Java"])
    n21 -->|"sí"| r22
```

---

## 6. 🧭 El dominio y los datos

```mermaid
flowchart LR
    n1["¿Lógica simple, sin reglas que se repitan?"]
    r2(["Transaction Script (07/01), honesto"])
    n1 -->|"sí"| r2
    n3["¿Reglas que se repiten y cambian?"]
    r4(["Domain Model (07/01) con agregados (09/01)"])
    n3 -->|"sí"| r4
    q5{"¿Cómo llega el modelo a la base?"}
    r6(["Active Record (07/02)"])
    q5 -->|"objetos que se guardan a sí mismos"| r6
    r7(["Data Mapper + Unit of Work + Identity Map (07/02, 07/03): JPA"])
    q5 -->|"dominio que no sabe de tablas"| r7
    n8["¿Un concepto sin identidad, con reglas?"]
    r9(["Value Object (08/05); dinero, Money con su reparto"])
    n8 -->|"sí"| r9
    n10["¿Algo que el negocio sigue en el tiempo?"]
    r11(["Entity (09/01)"])
    n10 -->|"sí"| r11
    n12["¿Una regla que no es de ninguna entidad?"]
    r13(["servicio de dominio (09/02)"])
    n12 -->|"sí"| r13
    n14["¿Ausencia normal con respuesta común?"]
    r15(["Null Object / Special Case (09/03, 08/05); si es un error, excepción"])
    n14 -->|"sí"| r15
    n16["¿Dos usuarios editan lo mismo entre peticiones?"]
    r17(["Optimistic Offline Lock: @Version (08/03)"])
    n16 -->|"sí"| r17
    n18["¿Datos que cruzan la red?"]
    r19(["DTO (08/02), nunca la entidad"])
    n18 -->|"sí"| r19
```

---

## 7. 🧭 Concurrencia

```mermaid
flowchart LR
    q1{"¿Se puede no compartir estado mutable?"}
    r2(["Immutable Object + referencia volatile (10/01)"])
    q1 -->|"¿muchos leen y pocos cambian?"| r2
    r3(["confinamiento (10/01)"])
    q1 -->|"¿solo lo usa un hilo?"| r3
    n4["¿Estado compartido con esperas?"]
    r5(["Monitor: wait en while + notifyAll (10/02)"])
    n4 -->|"sí"| r5
    n6["¿Ritmos distintos de producción y consumo?"]
    r7(["Producer-Consumer con cola acotada (10/03)"])
    n6 -->|"sí"| r7
    n8["¿Trabajo de CPU?"]
    r9(["pool de ≈ núcleos hilos (10/03)"])
    n8 -->|"sí"| r9
    n10["¿Trabajo de E/S en Java 21?"]
    r11(["virtual thread por tarea + semáforo por recurso (10/03)"])
    n10 -->|"sí"| r11
    n12["¿Combinar resultados que llegan después?"]
    r13(["Future: thenCombine, plazo y camino de error (10/04)"])
    n12 -->|"sí"| r13
    n14["¿Miles de conexiones con poca actividad?"]
    r15(["Reactor, sin bloquear el bucle; o virtual threads (10/05)"])
    n14 -->|"sí"| r15
```

---

## 8. ⚖️ Los pares que se confunden

| Par | La diferencia, en una frase |
|---|---|
| Strategy / State | En Strategy elige el cliente; en State, el propio objeto según su estado, y los estados se pasan el control |
| Decorator / Proxy | El Decorator añade comportamiento y se apila; el Proxy controla el acceso a un objeto (`05/03`) |
| Adapter / Facade | El Adapter traduce una interfaz a otra; el Facade simplifica un subsistema entero |
| Factory Method / Abstract Factory | Uno crea un producto con una subclase; la otra crea familias que van juntas |
| Template Method / Strategy | Herencia del algoritmo con pasos redefinidos; composición con el algoritmo entero intercambiable |
| Observer / Mediator | El Observer difunde a quien se suscriba; el Mediator coordina a participantes que conoce |
| Composite / Decorator | Los dos envuelven: el Composite agrupa a muchos hijos; el Decorator, a uno, para añadirle algo |
| Value Object / DTO | El Value Object es un concepto del dominio con reglas; el DTO, un sobre sin reglas para cruzar una frontera |
| Entity / Value Object | La entidad tiene identidad que dura; el valor vale por su contenido y se reemplaza |
| Null Object / `Optional` | El Null Object decide por el llamador; `Optional` obliga a decidir |
| Service Locator / inyección | Con el localizador la clase pide; con inyección, recibe |
| Singleton del GoF / alcance singleton | El del GoF tiene acceso global por cargador de clases; el del contenedor, una instancia por bean, inyectada |

---

## 9. 🧭 Cuando la respuesta es ninguno

```mermaid
flowchart LR
    n1["Una sola variante hoy, y es mi código"]
    r2(["código directo; el patrón llega refactorizando (13/03)"])
    n1 --> r2
    n3["Una variación de datos"]
    r4(["un dato: una fila, un campo, un enum"])
    n3 --> r4
    n5["Una función de una línea"]
    r6(["una lambda, no una clase"])
    n5 --> r6
    n7["El lenguaje ya lo trae"]
    r8(["la construcción del lenguaje (record, sealed, try-with-resources)"])
    n7 --> r8
    n9["El marco ya lo hace"]
    r10(["la anotación o el bean, entendiendo el patrón que hay debajo"])
    n9 --> r10
```

**La frase en voz alta:** *"Antes de nombrar un patrón pregunto qué varía y cuántas variantes hay hoy. Si hay una, escribo código
directo; si hay dos y cambian por motivos distintos, elijo el patrón que separa esa variación, y digo lo que cuesta. Y si el lenguaje o
el marco ya lo traen, uso lo que traen."*

---

## ⚠️ Errores frecuentes

| Se dice | Lo preciso |
|---|---|
| "Siempre hay un patrón para cada problema" | Muchas veces la respuesta es una función, un dato, un `enum` o nada |
| "Elegir un patrón es recordar su nombre" | Es identificar qué varía, cuántas variantes hay y qué cuesta separarlas |
| "Strategy y State son lo mismo con otro nombre" | La estructura se parece; quién elige y quién cambia la variante es distinto |
| "Si el patrón existe en el GoF, sigue haciendo falta igual" | Parte del catálogo era un rodeo para lo que a los lenguajes de 1994 les faltaba |
| "Más patrones, diseño más flexible" | Cada patrón añade indirección; solo es flexibilidad si hay una variación real |
| "El marco lo hace, no necesito saber el patrón" | Las trampas del marco son las del patrón: la autoinvocación es la del Proxy |

---

## 📚 Para profundizar

- **Libro** — Gamma, Helm, Johnson y Vlissides, *Design Patterns* (Addison-Wesley, 1994), cap. 1, "Introduction", sección "How to Select
  a Design Pattern". **El que destaca.**
- **Libro** — Freeman y Robson, *Head First Design Patterns*, 2.ª ed. (O'Reilly, 2021), cap. 13, "Patterns in the Real World: Better
  Living with Patterns": los patrones no son una solución mágica, y cuándo no usarlos.
- **Libro** — Ousterhout, *A Philosophy of Software Design*, 2.ª ed. (Yaknyam Press, 2021), cap. 4, "Modules Should Be Deep": el costo
  de la indirección que no esconde nada.
- **Tutorial** — Refactoring Guru, [catálogo de patrones de diseño](https://refactoring.guru/design-patterns/catalog), con sus
  relaciones.

---

## 🧠 Preguntas

Sin respuestas aquí. Todas, con enunciado literal y respuesta en tres capas, en
[`06` — Respuestas](06-respuestas.md#04--cómo-se-elige).

1. ¿Qué preguntas haces antes de elegir un patrón? 🟢
2. ¿Qué patrón eliges si lo que varía es el algoritmo, y qué forma toma en Java 21? 🟢
3. ¿Qué es lo primero que miras para decidir que no hace falta ningún patrón? 🟢
4. ¿Qué diferencia hay entre Strategy y State? 🟡
5. ¿Qué diferencia hay entre Decorator y Proxy? 🟡
6. ¿Qué diferencia hay entre Adapter y Facade? 🟡
7. ¿Qué diferencia hay entre Observer y Mediator? 🟡
8. ¿Por qué "siempre hay un patrón para cada problema" es falso? 🟠
9. ¿Cómo cambia el lenguaje la lista de patrones que hacen falta? 🟠
10. ¿Por qué hay que conocer el patrón aunque el marco lo implemente? 🟠
11. Elige y justifica, con su precio: auditar las transferencias solo de las cuentas empresariales sin tocar el código existente. 🔴
12. Elige y justifica, con su precio: un tipo de documento nuevo por país cada mes, con formato y vigencia propios. 🔴

---

**Anterior:** [`03` — Refactorizar hacia patrones, y desde ellos](03-refactorizar-hacia-patrones.md) ·
**Siguiente:** [`05` — Simulación final](05-simulacion-final.md) ·
**Relacionado:** [`13/01` — Patrones en Spring](01-patrones-en-spring.md)
