# 07 — Caché

> Los patrones de caché, la invalidación —que es el problema de verdad—, el thundering herd y
> las estampidas, dónde poner la caché y por qué una caché mal puesta empeora el sistema en vez
> de mejorarlo.
> Asume leído [`06` — CQRS](06-cqrs.md).
>
> **Vigencia:** 2026-09-18.

---

## 1. 🎯 El problema

La consulta tarda 400 ms y se repite 5.000 veces por segundo con el mismo resultado. Poner una
caché delante es obvio, y también lo es la frase que todo el mundo cita:

> *"Solo hay dos cosas difíciles en informática: la invalidación de caché y nombrar cosas."*
> — Phil Karlton

No es una broma: **la parte fácil es guardar; la difícil es saber cuándo el dato dejó de valer**.
Y una caché con invalidación mal resuelta produce algo peor que la lentitud original: datos
incorrectos servidos rápido, sin error y sin rastro.

> **Regla:** antes de añadir una caché, responde tres preguntas: qué tolerancia de obsolescencia
> tiene ese dato, cómo se invalida, y qué pasa cuando la caché no está. Si falta alguna, todavía
> no tienes un diseño.

---

## 2. 📐 Los patrones

**Cache-aside (lazy loading).** La aplicación gestiona la caché: mira primero, y si falla,
consulta el origen y guarda.

```java
var valor = cache.get(clave);
if (valor == null) {                 // fallo de caché
    valor = origen.consultar(clave);
    cache.put(clave, valor, TTL);
}
return valor;
```

- Es el más usado, con diferencia. Solo se cachea lo que se pide, y la caché puede caerse sin
  romper nada: se degrada a consultar el origen.
- Su defecto: en un fallo de caché se paga la latencia completa, y **la primera petición de cada
  clave siempre falla**. Es el patrón que sufre la estampida de §4.

**Read-through.** La caché consulta el origen por ti; la aplicación solo habla con la caché.
Mismo comportamiento, menos código en la aplicación y más acoplamiento con la librería.

**Write-through.** Escribes en la caché y esta escribe en el origen, sincronizadamente.

- La caché nunca está obsoleta. A cambio, cada escritura paga la latencia de ambos, y cacheas
  cosas que quizá nadie lea.

**Write-behind (write-back).** Escribes en la caché y esta persiste después, de forma asíncrona.

- Escrituras muy rápidas y absorción de picos. **Riesgo de pérdida de datos** si la caché cae
  antes de persistir: solo para datos que se pueden perder, como contadores de visitas.

**Refresh-ahead.** La caché refresca las entradas populares antes de que caduquen.

- Evita que el usuario pague nunca el fallo. Cuesta consultas al origen que quizá nadie
  necesitaba.

**Cuándo sí cada uno.** Cache-aside por defecto. Write-through cuando la obsolescencia es
inaceptable y las escrituras son pocas. Write-behind solo para datos desechables. Refresh-ahead
cuando hay un conjunto pequeño de claves muy calientes.

> **Veredicto:** cache-aside resuelve el 90 % de los casos y es el único que sobrevive con
> dignidad a que la caché se caiga. Los demás se eligen por una razón concreta que hay que poder
> nombrar.

---

## 3. 🗑️ Invalidación

**Qué es.** Cómo se saca de la caché un dato que dejó de valer. Las tres estrategias, y **se
combinan**:

**1. TTL (caducidad por tiempo).** La entrada expira sola.

- Simple, robusto y no requiere coordinación: si todo lo demás falla, el TTL corrige.
- **Su valor es una declaración de obsolescencia tolerable**: un TTL de 60 segundos dice "acepto
  servir datos de hasta un minuto". Eso es una decisión de negocio, no un número por defecto.

**2. Invalidación explícita al escribir.** Al modificar el dato, borras su entrada.

- Precisa, y frágil: hay que acordarse en **todos** los caminos de escritura, incluidos los
  trabajos por lotes, las migraciones y el `UPDATE` manual de soporte.
- **Borrar es más seguro que actualizar.** Si actualizas la entrada con el valor nuevo, dos
  escrituras concurrentes pueden dejar el valor viejo. Si borras, la siguiente lectura recarga.

**3. Invalidación por evento.** El servicio dueño publica `ProductoActualizado` y quien cachea lo
escucha e invalida.

- Es la única que funciona **entre servicios**: si el dato lo cambia otro equipo, no hay forma de
  que tu código "se acuerde".
- Une este capítulo con [`02-eventos`](../02-eventos/): la caché es un consumidor más.

> ⚠️ **Advertencia.** La combinación correcta casi siempre es **las tres**: invalidación por
> evento o explícita para la precisión, **más TTL como red de seguridad**. Sin TTL, un evento
> perdido deja un dato obsoleto para siempre y nadie lo detecta.

> **Veredicto:** el TTL no es la estrategia, es el suelo. La invalidación precisa da frescura; el
> TTL garantiza que el error tiene fecha de caducidad.

---

## 4. 🐘 Estampida y thundering herd

**Qué es.** Lo que pasa cuando una clave muy popular caduca: mil peticiones fallan a la vez y
todas van al origen simultáneamente.

```text
t=0    la clave "catalogo:home" caduca
t=0    5.000 peticiones en vuelo → 5.000 fallos de caché
t=0    5.000 consultas idénticas contra la base de datos
t=1s   la base de datos se cae, y con ella el sistema que la caché protegía
```

Las tres defensas, y conviene poder nombrarlas:

```text
1. TTL con jitter        → en vez de 300 s exactos, 300 ± 30 aleatorios.
                           Reparte las caducidades y evita la sincronía. Coste: cero.
2. Bloqueo / coalescencia→ solo el primero recalcula; los demás esperan su resultado.
                           Coste: una espera, y un bloqueo distribuido que gestionar.
3. Refresh-ahead         → se refresca antes de caducar, así que nadie ve el fallo.
                           Coste: consultas que quizá nadie necesitaba.
```

- **El jitter es la defensa más barata del capítulo** y es la misma idea que el jitter del
  reintento de [`01-bases/09`](../01-bases/09-resiliencia.md): romper la sincronía.
- Hay una cuarta situación parecida y peor: **caché fría**. Al reiniciar o desplegar, la caché
  está vacía y **todo** el tráfico va al origen. Por eso escalar a 50 instancias con caché local
  puede empeorar el sistema: 50 cachés frías.

> 🩺 **Diagnóstico.** Picos de carga en la base de datos a intervalos regulares que coinciden con
> el TTL configurado: es estampida. Picos al desplegar: es caché fría.

> **Veredicto:** la estampida convierte una caché —que existía para proteger la base de datos— en el
> mecanismo que la tumba. El jitter cuesta una línea y evita la mayoría de los casos.

---
## 5. 📍 Dónde poner la caché

**Qué es.** La capa importa tanto como el patrón, y cada una tiene un compromiso distinto.

| Capa | Alcance | Latencia | Coherencia | Problema |
|---|---|---|---|---|
| **Navegador / CDN** | Por usuario / por región | Mínima | Peor | Invalidar es lento y caro |
| **Gateway** | Global | Muy baja | Media | Solo respuestas completas |
| **En proceso** (Caffeine) | Por instancia | Nanosegundos | **N copias divergentes** | Caché fría al escalar |
| **Distribuida** (Redis) | Global | ~1 ms + red | Una sola copia | Un salto de red; punto de fallo |
| **De la base de datos** | Global | — | Coherente | No la controlas |

- **La caché en proceso es la más rápida y la más traicionera**: con 20 instancias tienes 20
  copias que se invalidan por separado, y un usuario puede ver un dato y su recarga otro. Solo
  para datos casi inmutables, o aceptando la incoherencia y midiéndola.
- **Redis es el valor por defecto** para datos compartidos: una sola copia, invalidación en un
  sitio, coste de una ida y vuelta de red.
- **La combinación de dos niveles** —en proceso con TTL corto, Redis detrás— da lo mejor de
  ambas, y añade un modo de fallo más: el TTL corto del nivel 1 es tu ventana de incoherencia.

> **Veredicto:** elegir la capa es elegir entre latencia y coherencia. En proceso gana en
> velocidad y pierde en corrección; distribuida al revés. Decirlo así es la respuesta completa.

---

## 6. 🚫 Qué no se cachea, y qué pasa si la caché cae

**Qué no se cachea.** Datos que deciden sobre dinero en el instante —saldo disponible, límite de
crédito—, datos personales en cachés compartidas sin control de acceso, y resultados de consultas
que casi nunca se repiten: cachear lo que no se vuelve a pedir es memoria gastada y complejidad
añadida.

**Qué pasa si la caché cae**, que es la pregunta de seguimiento garantizada:

```text
Cache-aside     → degrada a consultar el origen. ¿Aguanta el origen TODO el tráfico?
                  Si la respuesta es no, la caché dejó de ser optimización y es una DEPENDENCIA.
Write-through   → las escrituras fallan. Necesitas decidir si degradas o rechazas.
Write-behind    → se pierde lo no persistido. Por eso solo datos desechables.
```

- **La pregunta clave: ¿el origen aguanta sin la caché?** Si con un 95 % de aciertos el origen
  recibe 250 peticiones por segundo, al caer la caché recibirá 5.000. Si no aguanta, la caché es
  crítica y necesita alta disponibilidad, no un nodo suelto.
- La salida intermedia: **limitar la tasa hacia el origen** cuando la caché falla, sirviendo
  errores o datos degradados al resto. Es preferible a tumbar la base de datos.

> ⚠️ **Advertencia.** Mucha gente describe su caché como "una optimización, si falla seguimos".
> Casi nunca es cierto. Comprobarlo —con un número— es lo que convierte esa frase en un hecho o
> en un riesgo identificado.

> **Veredicto:** una caché que el sistema no puede perder no es una caché: es un componente
> crítico disfrazado, y hay que operarla como tal.

---

## 7. 🧭 Cómo se elige

```text
Antes de cachear:
    ¿Es un problema de consulta o de índice?  → arréglalo primero. Cachear un plan malo lo esconde.
    ¿Se repite la misma lectura?              → si no, la caché no va a acertar
    ¿Cuánta obsolescencia tolera el dato?     → ESE número es tu TTL, y es de negocio

Patrón:
    Por defecto                        → cache-aside
    Obsolescencia inaceptable, pocas escrituras → write-through
    Datos desechables, picos de escritura       → write-behind
    Pocas claves muy calientes                  → refresh-ahead encima

Capa:
    Dato compartido y mutable          → Redis
    Dato casi inmutable, latencia extrema → en proceso, asumiendo N copias
    Respuesta completa, pública, por región → CDN
    Lo mejor de dos mundos             → dos niveles, con TTL corto en el primero

Invalidación:
    → precisa (evento o explícita) PARA LA FRESCURA
    + TTL con jitter               PARA LA RED DE SEGURIDAD Y LA ESTAMPIDA
    Nunca solo una de las dos.

Y antes de cerrar:
    → ¿aguanta el origen si la caché cae? Si no, la caché es crítica. Dilo.
```

---

## ⚠️ Errores frecuentes

| Se dice | Lo preciso |
|---|---|
| "Ponemos Redis y listo" | Falta decidir patrón, TTL, invalidación y qué pasa si cae |
| "TTL de 5 minutos" | ¿Por qué 5? El TTL es la obsolescencia que el negocio acepta |
| "Actualizo la entrada al escribir" | Borrar es más seguro: actualizar puede dejar el valor viejo con concurrencia |
| "Invalido al escribir y ya" | Faltan los lotes, las migraciones y los cambios de otros servicios |
| "La caché es solo una optimización" | Comprueba si el origen aguanta sin ella. Casi nunca |
| "Caché local es más rápida" | Y tienes N copias divergentes y N cachés frías al escalar |
| "Los picos son del tráfico" | Si coinciden con el TTL, es estampida: pon jitter |

---

## 📚 Para profundizar

- **Libro** — Martin Kleppmann, *Designing Data-Intensive Applications* (O'Reilly, 2017).
  Capítulo 11: las cachés como vistas derivadas, y por qué la invalidación es un problema de
  consistencia y no de implementación.
- **Libro** — Michael Nygard, *Release It!*, 2ª ed. (Pragmatic Bookshelf, 2018). Capítulo 5:
  cachés como fuente de fallos en cascada, con el caso de la caché fría.
- **Libro** — Alex Petrov, *Database Internals* (O'Reilly, 2019). Parte I: políticas de
  reemplazo y por qué LRU no siempre es la mejor.
- [Redis — Client-side caching](https://redis.io/docs/latest/develop/clients/client-side-caching/):
  el modelo de dos niveles con invalidación empujada desde el servidor.
- [Spring Framework — Cache Abstraction](https://docs.spring.io/spring-framework/reference/integration/cache.html):
  `@Cacheable`, `@CacheEvict`, y por qué no funciona en llamadas internas.
- [Amazon Builders' Library — Caching challenges and strategies](https://aws.amazon.com/builders-library/caching-challenges-and-strategies/):
  estampida, caché fría y el problema de la caché que se vuelve crítica, con números.
- **Video** — GOTO Conferences y AWS re:Invent, charlas sobre estrategias de caché a escala.
  Búscalas por título.

---

## 🧠 Preguntas

Sin respuestas aquí. Todas, con enunciado literal y respuesta en tres capas, en
[`10` — Respuestas](10-respuestas.md).

1. Nombra cinco patrones de caché. 🟢
2. ¿Qué es cache-aside? 🟢
3. ¿Qué es el thundering herd aplicado a caché? 🟢
4. ¿Qué tres estrategias de invalidación existen? 🟢
5. ¿Qué es la caché fría? 🟢
6. ¿Qué diferencia hay entre write-through y write-behind? 🟡
7. ¿Por qué write-behind puede perder datos? 🟡
8. ¿Por qué es más seguro borrar la entrada que actualizarla? 🟡
9. ¿Qué problema tiene la caché en proceso con varias instancias? 🟡
10. ¿Qué es el TTL con jitter y qué resuelve? 🟡
11. ¿Por qué la invalidación por evento es la única que funciona entre
    servicios? 🟡
12. ¿Qué significa realmente el valor del TTL? 🟠
13. ¿Por qué la invalidación explícita es frágil? 🟠
14. ¿Por qué hay que combinar invalidación precisa y TTL? 🟠
15. ¿Cómo distingues una estampida de un pico de tráfico normal? 🟠
16. ¿Por qué escalar a 50 instancias con caché local puede empeorar el sistema? 🟠
17. ¿Qué preguntas para saber si tu caché es una optimización o una dependencia? 🟠
18. ¿Qué datos no se cachean y por qué? 🟠
19. ¿Qué ganas y qué pierdes con una caché de dos niveles? 🟠
20. ¿Qué haces si la caché cae y el origen no aguanta el tráfico? 🟠
21. Diseña la caché de un catálogo: 5.000 productos, cambian dos veces al día,
    40.000 lecturas por segundo, p99 de 50 ms. 🔴
22. La base de datos tiene picos cada 5 minutos que coinciden con el TTL.
    Diagnostica y da tres soluciones con su coste. 🔴
23. Un usuario ve el precio antiguo al recargar, y el nuevo al volver a
    recargar. Reconstruye qué está pasando y cómo lo arreglas. 🔴

---

**Anterior:** [`06` — CQRS](06-cqrs.md) ·
**Siguiente:** [`08` — Políglota y multi-tenant](08-poliglota-y-multi-tenant.md) ·
**Relacionado:** [`01-bases/09` — Resiliencia](../01-bases/09-resiliencia.md)
