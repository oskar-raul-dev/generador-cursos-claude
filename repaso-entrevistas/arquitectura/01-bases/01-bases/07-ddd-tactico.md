# 07 — DDD táctico

> Los bloques de construcción dentro de un contexto acotado: agregado, entidad, objeto de
> valor, repositorio, servicio de dominio, evento de dominio y fábrica. Y el conflicto
> real que produce la mitad de las decisiones de un servicio Java: **el agregado contra
> el modelo relacional de JPA.**
> Asume leído [`06` — DDD estratégico](06-ddd-estrategico.md).
>
> **Vigencia:** 2026-09-18.

---

## 1. 🎯 El problema

Tu entidad `Pedido` tiene `setEstado()`. Alguien llama a `pedido.setEstado(ENVIADO)`
sobre un pedido sin pagar. No hay error, no hay excepción: hay un pedido enviado y no
cobrado, y lo descubre contabilidad tres semanas después.

La regla *"un pedido no puede enviarse sin estar pagado"* existía. Estaba en un `if`,
dentro de un servicio, en el flujo normal. El problema es que **había otro camino hasta
el estado**, y nada lo impedía.

DDD táctico es la respuesta a esa pregunta: **¿quién protege la regla, y cómo se hace
imposible saltársela?**

> **Regla:** si un objeto puede quedar en estado inválido, la invariante no está
> protegida por el diseño. Está protegida por la buena voluntad de quien llama.

---

## 2. 💎 Objeto de valor (value object)

**Qué es.** Un objeto **sin identidad**, definido por sus atributos, **inmutable**. Dos
objetos con los mismos valores son el mismo objeto. `Money`, `Email`, `IBAN`,
`RangoDeFechas`.

En Java moderno es literalmente un `record`, y la validación va en el constructor
compacto:

```java
public record Iban(String valor) {
    public Iban {                                  // constructor compacto
        if (!esIbanValido(valor))
            throw new IbanInvalido(valor);          // no existe un Iban inválido
    }
}
```

- La validación **al construir** es lo que aporta: a partir de ahí, cualquier método que
  reciba un `Iban` sabe que es válido sin volver a comprobarlo.
- Sustituir `String` por un objeto de valor elimina toda una clase de bugs: ya no puedes
  pasar un IBAN donde iba un BIC, porque el compilador lo impide.

**Cuándo sí.** Casi siempre que un concepto de negocio viaje como `String`, `BigDecimal`
o par de campos. Es el bloque **más barato y más rentable** del DDD táctico.

> **Veredicto:** si solo adoptas una cosa de todo DDD, adopta objetos de valor. No
> requiere arquitectura, requiere un `record`.

---

## 3. 🆔 Entidad

**Qué es.** Un objeto con **identidad propia que persiste en el tiempo**, aunque todos
sus atributos cambien. Un `Cliente` sigue siendo el mismo cliente tras cambiar de
nombre, dirección y teléfono.

**La distinción que se pregunta:** ¿cómo decides si algo es entidad u objeto de valor?

> Pregunta si dos instancias con los mismos datos son intercambiables. Dos billetes de
> 10 € lo son → objeto de valor. Dos clientes llamados igual, no → entidad.

> **Veredicto:** la distinción entidad/objeto de valor parece académica hasta que cuentas los bugs que
> vienen de tratar como intercambiable algo que no lo era, o al revés.

---
## 4. 🛡️ Agregado y raíz de agregado

**Qué es.** Un grupo de entidades y objetos de valor tratado como **una sola unidad de
consistencia**. Tiene una **raíz** que es el único punto de entrada: nada de fuera
referencia a los objetos internos.

La regla de oro, que hay que saber decir literal:

```text
Una transacción, un agregado.
Dentro del agregado: consistencia inmediata.
Entre agregados:     consistencia eventual, vía eventos de dominio.
```

**Cómo se ve en código.** La raíz no expone setters; expone operaciones de negocio que
protegen la invariante:

```java
public class Pedido {                       // raíz de agregado
    private EstadoPedido estado;
    private final List<LineaPedido> lineas; // entidades internas: nadie las toca fuera

    public void enviar() {
        if (estado != PAGADO)
            throw new PedidoNoEnviable(id, estado);   // la invariante vive aquí
        estado = ENVIADO;
        registrar(new PedidoEnviado(id));             // evento de dominio
    }
}
```

- **No hay `setEstado()`**: el único camino hasta `ENVIADO` pasa por la comprobación.
  Esa es toda la diferencia con el modelo anémico de
  [`05` §3](05-fowler-poeaa.md#3--el-modelo-anémico).
- `lineas` es privada y no se devuelve modificable: si expones la lista, expones la
  invariante.
- El evento se registra dentro y se publica al persistir — con
  [`04` §7](04-patrones-gof.md#7-️-observer) `@TransactionalEventListener`, o con outbox
  si tiene que salir del proceso.

**Cómo se dimensiona.** La pregunta correcta no es "¿qué va junto?" sino **"¿qué tiene
que ser consistente en el mismo instante?"**. Todo lo demás va fuera y se sincroniza
después.

> ⚠️ **Advertencia.** El error clásico: hacer agregados enormes "por comodidad". Un
> agregado `Cliente` que contiene todos sus pedidos significa cargar y bloquear todos los
> pedidos para cambiar un teléfono. La contención de bloqueos es el síntoma.

> **Veredicto:** el agregado es la única pieza del DDD táctico que cambia cómo se **comporta** el
> sistema, porque decide el tamaño de tus transacciones. Las demás cambian cómo se lee
> el código.

---
## 5. 🔗 Referencias entre agregados

**La regla:** un agregado referencia a otro **por identidad, no por objeto**.

```java
public class Pedido {
    private final ClienteId clienteId;   // ✅ solo el id
    // private Cliente cliente;          // ❌ arrastra el otro agregado a esta transacción
}
```

- Referenciar por id mantiene la frontera transaccional y evita cargar medio grafo.
- **En JPA esto choca de frente con `@ManyToOne`**, que es exactamente el conflicto de la
  sección siguiente.

> **Veredicto:** referenciar por identidad es la regla que más se incumple y la más barata de cumplir:
> es cambiar un campo. Incumplirla se paga en transacciones que no sabías que eran
> grandes.

---
## 6. ⚔️ El agregado contra JPA

Este es el contenido que hace útil al capítulo, porque es donde se cae la gente y es
donde se toman las decisiones reales de un servicio Java.

| El agregado quiere | JPA/Hibernate quiere |
|---|---|
| Cargarse entero para garantizar la invariante | Cargar lo mínimo: lazy loading |
| Referenciar otros agregados por id | `@ManyToOne` con el objeto entero |
| No exponer colecciones internas | Getters de colecciones para el mapeo |
| Ser inmutable donde se pueda | Constructor sin argumentos y setters |
| Una transacción, un agregado | Cascadas que arrastran medio grafo |

**Las tres salidas, con su precio:**

```text
1. Entidad JPA = agregado           → simple, pero el ORM contamina el dominio
                                      (anotaciones, constructor vacío, colecciones abiertas)
2. Dominio puro + entidad JPA aparte → dominio limpio, precio: mapeo en los dos sentidos
                                      Es la opción de hexagonal de `03` §3
3. Dominio puro + Spring Data JDBC   → JDBC entiende agregados de forma nativa:
                                      guarda la raíz y su contenido, sin lazy loading
```

- La opción 1 es lo que hace el 90 % de los proyectos y es defendible si lo dices a
  conciencia.
- La opción 2 es la correcta cuando el dominio es núcleo y tiene invariantes de verdad.
  **Su precio es el mapeo, y hay que nombrarlo.**
- La opción 3 es la menos conocida y la que más puntúa: **Spring Data JDBC fue diseñado
  con el agregado de DDD como unidad**, sin lazy loading ni caché de primer nivel.

> 💡 **Truco.** Decir *"Spring Data JDBC modela agregados mejor que JPA porque no tiene
> lazy loading ni contexto de persistencia"* es una respuesta que casi nadie da y que
> demuestra que has pensado el conflicto, no solo leído los bloques.

> **Veredicto:** no hay salida gratis, solo tres precios. Lo que descalifica en entrevista no es elegir
> mal: es no saber que estabas eligiendo.

---
## 7. 🗄️ Repositorio por agregado

**La regla:** un repositorio **por raíz de agregado**, no por tabla ni por entidad. Si
tienes `LineaPedidoRepository`, la línea no es interna al agregado — o el agregado está
mal dimensionado.

El repositorio habla el lenguaje del dominio: `pedidosPendientesDe(clienteId)`, no
`findByEstadoAndClienteIdOrderByFecha`. Eso conecta con
[`05` §4](05-fowler-poeaa.md#4-️-repository): la interfaz vive en el dominio, la
implementación en infraestructura.

> **Veredicto:** el número de repositorios es un test de diagnóstico del modelo. Si tienes más
> repositorios que agregados, tus agregados son más pequeños de lo que crees — o no
> existen.

---
## 8. ⚙️ Servicio de dominio

**Qué es.** La operación de negocio que **no pertenece naturalmente a ninguna entidad**,
normalmente porque coordina varias: una transferencia entre dos cuentas, un cálculo de
riesgo que cruza tres agregados.

**Qué NO es.** El `@Service` de Spring. Esa es la Service Layer de
[`05` §8](05-fowler-poeaa.md#8--service-layer), que coordina transacción e
infraestructura. El servicio de dominio es lógica pura, sin dependencias técnicas.

> ⚠️ **Advertencia.** Es la puerta trasera por la que se escapa la lógica del dominio.
> Antes de crear uno, pregúntate si la regla no pertenece a un agregado. Si todos tus
> servicios de dominio están llenos y tus entidades vacías, has vuelto al modelo anémico
> con otro nombre.

> **Veredicto:** el servicio de dominio es necesario y es la pendiente resbaladiza del DDD táctico.
> Úsalo cuando la operación no tenga dueño natural, nunca cuando no encuentres dónde
> ponerla.

---
## 9. 📢 Evento de dominio

**Qué es.** Algo que **ya ocurrió** y le importa al negocio. Nombre en pasado y en
lenguaje ubicuo: `PedidoEnviado`, `PagoRechazado`, `LimiteDeCreditoSuperado`.

**Para qué sirve en este capítulo:** es el mecanismo que permite mantener "una
transacción, un agregado". El agregado A cambia y emite; el agregado B reacciona
después, en otra transacción. La consistencia entre ellos es eventual **a propósito**.

- Dentro del proceso: `@TransactionalEventListener(AFTER_COMMIT)`.
- Fuera del proceso: outbox transaccional, que se ve en
  [`02-eventos/06`](../02-eventos/).

> ⚠️ **Advertencia.** No confundas evento de dominio con evento de integración. El de
> dominio habla tu lenguaje ubicuo y es interno; el de integración es un contrato público
> y cambiarlo rompe a otros. Publicar tus eventos de dominio tal cual al broker convierte
> tu modelo interno en API pública — y ya no puedes refactorizarlo.

> **Veredicto:** el evento de dominio es lo que hace viable la regla de una transacción por agregado.
> Sin él, el agregado pequeño es un ideal que no se puede sostener.

---
## 10. 🏗️ Fábrica

**Qué es.** Encapsula la creación de un agregado cuando construirlo requiere lógica o
debe nacer ya válido y completo.

En la práctica, en Java moderno casi siempre es un **método estático de fábrica en la
propia raíz** (`Pedido.nuevo(clienteId, lineas)`), no una clase aparte. Se conecta con
Builder de [`04` §4](04-patrones-gof.md#4--builder): el objetivo común es **que no exista
un agregado a medio construir**.

> **Veredicto:** la fábrica como clase aparte casi nunca hace falta; el método estático en la raíz sí.
> Lo que importa no es el patrón: es que no exista un agregado a medio construir.

---
## 11. 🧭 Cómo se elige cuánto DDD aplicar

> **DDD táctico completo sobre un dominio sin invariantes es ceremonia cara.**

Saber decir eso vale más que recitar los ocho bloques. El reparto honesto:

```text
Subdominio núcleo    → DDD táctico completo. Se paga solo.
Subdominio soporte   → Objetos de valor + entidades simples. Nada más.
Subdominio genérico  → No lo construyes. Lo compras.
```

Y una pieza es rentable en cualquier caso: **los objetos de valor**. Cuestan un `record`
y eliminan bugs en cualquier dominio, tenga invariantes o no.

---

## ⚠️ Errores frecuentes

| Se dice | Lo preciso |
|---|---|
| "El agregado agrupa lo que va junto" | Agrupa lo que debe ser consistente **en el mismo instante** |
| "Un repositorio por entidad" | Uno por **raíz de agregado** |
| "Las entidades DDD son las entidades JPA" | Pueden serlo, y el precio es que el ORM contamina el dominio |
| "El servicio de dominio es el `@Service`" | El `@Service` es Service Layer; el de dominio no tiene dependencias técnicas |
| "Los eventos de dominio se publican al broker" | Esos son de integración; publicar los de dominio congela tu modelo interno |
| "Referencio el otro agregado con `@ManyToOne`" | Por id: el objeto arrastra el otro agregado a tu transacción |
| "DDD siempre mejora el diseño" | Sobre un dominio sin invariantes es ceremonia cara |

---

## 📚 Para profundizar

- **Libro** — Eric Evans, *Domain-Driven Design* (Addison-Wesley, 2003). Parte II,
  capítulos 5 y 6: los bloques de construcción y el agregado.
- **Libro** — Vaughn Vernon, *Implementing Domain-Driven Design* (Addison-Wesley, 2013).
  Capítulos 5–10, y sobre todo el **10 (Aggregates)**: las cuatro reglas de
  dimensionamiento. Es el mejor material sobre agregados que existe.
- **Libro** — Vaughn Vernon, *Domain-Driven Design Distilled* (Addison-Wesley, 2016).
  La versión de 150 páginas, ideal para repasar antes de una entrevista.
- Martin Fowler — [DDD_Aggregate](https://martinfowler.com/bliki/DDD_Aggregate.html):
  la definición corta y citable.
- [Spring Data JDBC — Reference documentation](https://docs.spring.io/spring-data/relational/reference/jdbc.html):
  el capítulo de agregados explica por qué se diseñó alrededor del agregado de DDD.
- **Tutorial** — Baeldung, «DDD Aggregates in Java»:
  el ejemplo con raíz, invariante y repositorio.
- **Video** — *Domain-Driven Design Europe*, charlas de Vaughn Vernon sobre
  dimensionamiento de agregados. Búscalas por título.

---

## 🧠 Preguntas

Sin respuestas aquí. Todas, con enunciado literal y respuesta en tres capas, en
[`12` — Respuestas](12-respuestas.md).

1. ¿Qué diferencia a una entidad de un objeto de valor? 🟢
2. Enuncia la regla de oro del agregado. 🟢
3. ¿Qué es una raíz de agregado y qué garantiza? 🟢
4. ¿Qué es un evento de dominio y cómo se nombra? 🟢
5. ¿Cómo referencia un agregado a otro y por qué? 🟡
6. ¿En qué se diferencia un servicio de dominio de un `@Service` de Spring? 🟡
7. ¿Cuántos repositorios tiene un agregado con tres entidades internas? 🟡
8. ¿Por qué un `record` es la forma natural del objeto de valor en Java? 🟡
9. ¿Dónde va la validación de un objeto de valor y qué garantiza después? 🟡
10. ¿Cómo decides el tamaño de un agregado? 🟠
11. ¿Por qué un agregado grande produce contención de bloqueos? 🟠
12. ¿En qué se diferencia un evento de dominio de uno de integración? 🟠
13. Nombra tres puntos donde el agregado de DDD choca con JPA. 🟠
14. ¿Por qué Spring Data JDBC modela agregados mejor que JPA? 🟠
15. Si expones la colección interna del agregado, ¿qué rompes? 🟠
16. ¿Qué señal indica que volviste al modelo anémico usando servicios de dominio? 🟠
17. ¿Qué bloque de DDD táctico es rentable incluso en un dominio sin
    invariantes, y por qué? 🟠
18. ¿Cuándo el DDD táctico completo NO se justifica? 🟠
19. Tienes `Cliente` con 5.000 pedidos dentro del agregado. Diagnostica y
    rediseña. 🔴
20. Diseña el agregado de una transferencia bancaria: qué contiene, qué queda
    fuera y cómo mantienes la consistencia con lo de fuera. 🔴
21. Tu dominio es puro pero persistes con JPA. Describe las dos opciones de
    mapeo y elige una justificando el precio. 🔴
22. Una regla de negocio cruza tres agregados. ¿Dónde la pones? 🔴

---

**Anterior:** [`06` — DDD estratégico](06-ddd-estrategico.md) ·
**Siguiente:** [`08` — Comunicación e integración](08-comunicacion-e-integracion.md) ·
**Relacionado:** [`05` — Fowler PoEAA](05-fowler-poeaa.md)
