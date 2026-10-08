# 06 — Números, tiempo y concurrencia

> El bloque de las **abstracciones con fugas**: tres temas donde el tipo promete una cosa y la
> máquina entrega otra. Es el que menos se parece a un libro de algoritmos y el que más incidentes
> reales explica, sobre todo en dominios con dinero.
>
> **Vigencia:** 2026-09-18. · **Guía editorial:** [`prompts/guia-de-estilo-y-convenciones.md`](../prompts/guia-de-estilo-y-convenciones.md)

---

## Qué es esto, y por qué estos tres juntos

```text
double      promete un número real     → entrega una fracción binaria
LocalDateTime promete un momento       → no identifica ninguno
HashMap     promete un mapa            → no promete nada con varios hilos
```

Los tres comparten la **forma del fallo**: el código parece correcto, compila, pasa los tests y falla
en producción con datos reales. Y ninguno lanza excepción — devuelven un número ligeramente distinto,
una fecha desplazada un día, un contador con el 68 % menos. Por eso se detectan al cuadrar con otro
sistema y no al ejecutar.

El antídoto también es el mismo en los tres: **elegir el tipo por su semántica**, no por costumbre, y
hacer que lo ambiguo sea imposible de expresar.

Las preguntas **no llevan la respuesta al lado**: viven en [`05-respuestas.md`](05-respuestas.md).

---

## Orden de lectura

| # | Documento | Qué cubre |
|---|---|---|
| `01` | [Números, precisión y dinero](01-numeros-precision-y-dinero.md) | IEEE 754, `BigDecimal` y su escala, redondeo bancario, dinero como entero, el tipo `Money` |
| `02` | [Tiempo, fechas y relojes](02-tiempo-fechas-y-relojes.md) | Instante vs local vs zonado, DST, `Period` vs `Duration`, reloj monótono, `Clock` inyectable |
| `03` | [Estructuras de datos y concurrencia](03-estructuras-y-concurrencia.md) | Qué es ser seguro entre hilos, `ConcurrentHashMap`, colas acotadas, inmutabilidad, los cinco modelos |
| `04` | [Simulación de entrevista](04-simulacion-de-entrevista.md) | 30 preguntas transversales + 5 problemas de pizarra |
| `05` | [Respuestas](05-respuestas.md) | Solucionario completo del bloque, en tres capas |

**Si el calendario aprieta y el dominio toca dinero** —banca, seguros, facturación, comercio—, `01`
es el capítulo más rentable de todo el corpus: es lo primero que se pregunta a un perfil senior en
esos dominios y casi nadie lo tiene sistematizado.

---

## La frontera con el resto del repositorio

Este bloque **no es un capítulo de concurrencia en Java**. Esa parte —modelo de memoria, `volatile`,
`synchronized` frente a `ReentrantLock`, dimensionado de pools— ya está cubierta en
[`preguntas-entrevista/04-java-11-17.md`](../../../../preguntas-entrevista/04-java-11-17.md), preguntas 69
a 76, y aquí se enlaza en vez de duplicarse.

Lo que este bloque aporta y no existe en ningún otro sitio del repositorio:

- **El ángulo de estructuras**: qué le pasa a un `HashMap`, a una lista o a una cola cuando hay
  varios hilos, y cuánto cuesta protegerla.
- **El contraste de los cinco modelos de concurrencia**: hilos y virtual threads en Java, GIL en
  Python, un solo hilo en JavaScript, goroutines y canales en Go.
- **Números y tiempo en los cinco lenguajes**, que no aparecen en ningún corpus del repositorio.

---

## Las cinco cosas que este bloque deja claras

1. **`0.1 + 0.2` no es `0.3`** en cuatro de los cinco lenguajes — y en Go depende de si son
   constantes o variables, lo que lo convierte en la mejor trampa de test del corpus.
2. **`HALF_UP` sesga los totales al alza.** El redondeo contable es `HALF_EVEN`, y cuál usar no lo
   decide el programador.
3. **"Guarda todo en UTC" es una respuesta incompleta**: vale para eventos pasados, no para fechas de
   calendario ni para citas futuras.
4. **`Period.ofDays(1)` y `Duration.ofHours(24)` dan resultados distintos**, verificado, y elegir mal
   produce el bug de una hora dos veces al año.
5. **Sincronizar cada método no hace atómica la secuencia**: un mapa sincronizado perdió el 68 % de
   los incrementos en una prueba real con ocho hilos.

---

## Qué NO está aquí

- **Complejidad, estructuras y algoritmos** → bloques [`01`](../01-fundamentos/) a
  [`05`](../05-dp-y-tecnicas/), que este asume leídos.
- **Concurrencia de Java en detalle** →
  [`preguntas-entrevista/04-java-11-17.md`](../../../../preguntas-entrevista/04-java-11-17.md).
- **Transacciones, consistencia distribuida y relojes lógicos** → son de arquitectura:
  [`repaso-arquitectura-entrevistas`](../../../arquitectura/01-bases/).
- **Internacionalización y formateo para presentación** → fuera del alcance: aquí se trata el
  **almacenamiento y el cálculo**, no cómo se muestra.
- **El código implementado en los cinco lenguajes** → bloque opcional
  [`09-implementaciones`](../09-implementaciones/).
