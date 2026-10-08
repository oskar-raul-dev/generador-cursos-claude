# 01 — Fundamentos del arquitecto

> Lo que se evalúa antes de cualquier patrón: si sabes razonar un trade-off, nombrar un
> atributo de calidad, dibujar lo que propones y dejarlo por escrito. Es el capítulo que
> más rinde por línea, porque decide el tono de toda la entrevista.
> Asume solo experiencia backend; no asume arquitectura previa.
>
> **Vigencia:** 2026-09-18.

---

## 1. 🎯 El problema

Te preguntan *"¿cómo diseñarías un sistema de pagos?"* y empiezas por la tecnología:
Spring Boot, Postgres, Kafka. El entrevistador asiente y no te da el puesto.

Lo que buscaba era otra cosa. Un desarrollador senior elige la mejor opción; un
arquitecto **explica qué pierde al elegirla**. La diferencia cabe en una frase:

> **Regla importante:** un desarrollador responde *qué*, un arquitecto responde *a
> cambio de qué*.

Este capítulo es el vocabulario para responder lo segundo.

---

## 2. ⚖️ Trade-off: la unidad mínima de respuesta

**Qué es.** Toda decisión de arquitectura compra una propiedad pagando con otra. No
existe la opción que gana en todo; si crees que la encontraste, no has identificado el
precio todavía.

**La plantilla de respuesta** que conviene tener memorizada, porque sirve para casi
cualquier pregunta de diseño:

```text
1. Restricción   → "Depende de si el requisito es X o Y"      (pides el dato que falta)
2. Opción        → "Con X yo iría por A"                      (te mojas)
3. Precio        → "A cambio pago B"                          (esto es lo que evalúan)
4. Mitigación    → "Y B lo acoto con C"                       (esto es lo que te separa)
5. Reversibilidad→ "Si me equivoco, salir cuesta D"           (esto casi nadie lo dice)
```

- El paso 1 evita la trampa: casi todas las preguntas de diseño están subespecificadas
  a propósito, y **preguntar es parte de la respuesta**.
- El paso 3 es obligatorio. Una propuesta sin precio suena a folleto.
- El paso 5 es el desempate: las decisiones de arquitectura se clasifican mejor por
  **cuánto cuesta deshacerlas** que por cuánto cuesta tomarlas.

**Cuándo sí.** Siempre. Es el formato por defecto de toda respuesta de diseño.

**Cuándo no.** Si te preguntan una definición ("¿qué es idempotencia?"), no metas
trade-offs: responde la definición y cállate.

> **Veredicto:** la frase *"a cambio pago…"* es la que más sube tu nota por palabra
> dicha en toda la entrevista.

---

## 3. 📐 Atributos de calidad

**Qué es.** Los requisitos no funcionales, con nombre propio. La arquitectura existe
para satisfacerlos: si un sistema solo tuviera requisitos funcionales, bastaría con un
único archivo de código.

Los que se preguntan de verdad, y el conflicto que cada uno provoca:

| Atributo | Qué mide | Contra qué pelea |
|---|---|---|
| **Disponibilidad** | % de tiempo respondiendo | Consistencia, costo |
| **Rendimiento** | Latencia y throughput | Consistencia, seguridad |
| **Escalabilidad** | Crecer sin rediseñar | Simplicidad |
| **Consistencia** | Todos ven el mismo dato | Disponibilidad, latencia |
| **Mantenibilidad** | Costo de cambiar | Rendimiento (abstracciones cuestan) |
| **Testabilidad** | Costo de verificar | Velocidad inicial |
| **Seguridad** | Resistencia al abuso | Usabilidad, latencia |
| **Observabilidad** | Poder diagnosticar | Costo, rendimiento |

> 🧠 **Modelo mental.** Los atributos de calidad **no se suman, se reparten**. Cuando un
> entrevistador dice "quiero alta disponibilidad y consistencia fuerte", el movimiento
> correcto no es prometer las dos: es preguntar cuál cede en una partición de red.

**Cuándo sí.** Nombrarlos explícitamente al abrir cualquier diseño: *"antes de elegir,
¿qué es lo que más duele aquí: latencia o consistencia?"*.

**Cuándo no.** No recites los ocho. Nombra los dos que están en tensión en ese problema.

> **Veredicto:** el atributo que no nombras es el que te va a romper el diseño en la
> pregunta de seguimiento.

---

## 4. 📝 ADR — Architecture Decision Record

**Qué es.** Un archivo corto en el repositorio que registra **una** decisión: el
contexto, las opciones, la elegida y las consecuencias. Se escribe una vez y no se
edita; si la decisión cambia, se escribe un ADR nuevo que marca al anterior como
*superseded*.

La estructura mínima, que es la de Michael Nygard y la que se espera que cites:

```text
# ADR-007 — Usar outbox transaccional para publicar eventos de inventario

Estado:      Aceptado  (2026-03-14)
Contexto:    El publish a Kafka vive fuera de la transacción de BD. Si el commit
             ocurre y el publish falla, el evento se pierde. Pasó 3 veces en Q1.
Decisión:    Escribir el evento en una tabla outbox dentro de la misma transacción,
             y publicarlo con un relay aparte.
Consecuencias:
  + El evento no se pierde: commit atómico con el cambio de estado.
  − Entrega at-least-once: los consumidores deben ser idempotentes.
  − Un proceso más que operar y monitorear (lag del relay).
Alternativas: 2PC (descartado: no lo soporta Kafka), CDC sobre el binlog
             (descartado hoy: no tenemos Debezium en operación).
```

- **`Estado` con fecha** es lo que convierte al ADR en historia y no en documentación
  que envejece mintiendo.
- **`Consecuencias` con signo** `+` y `−`: un ADR sin consecuencias negativas es una
  justificación, no una decisión.
- **`Alternativas` con el motivo del descarte** es la sección que demuestra que hubo
  análisis. Es también la que más se olvida.

**Cuándo sí.** Decisiones estructurales, caras de revertir, o que alguien va a
cuestionar en seis meses.

**Cuándo no.** Elegir una librería de fechas. Si la decisión cabe en un comentario del
código, no merece ADR.

> ⚠️ **Advertencia.** En entrevista, *"lo documentamos en un ADR"* es una de las
> respuestas de liderazgo técnico con mejor relación valor/esfuerzo. Pero prepárate la
> pregunta siguiente: *"¿dónde vivían?"*. La respuesta buena es "en el repo, junto al
> código, en `docs/adr/`"; la mala es "en Confluence".

> **Veredicto:** el ADR es la herramienta de liderazgo técnico con mejor relación valor/esfuerzo que
> existe. Cuesta veinte minutos y es lo que queda del razonamiento cuando tú ya no estés
> en el equipo.

---
## 5. 🗺️ C4 — el modelo para dibujar

**Qué es.** Cuatro niveles de zoom para diagramar software, de Simon Brown. Resuelve el
problema real de los diagramas: que cada uno mezcla niveles de abstracción distintos y
acaba sin significar nada.

```text
Nivel 1  Contexto    → tu sistema como una caja + usuarios + sistemas externos
Nivel 2  Contenedor  → apps y bases de datos desplegables, con protocolos
Nivel 3  Componente  → piezas internas de UN contenedor
Nivel 4  Código      → clases. Casi nunca se dibuja.
```

- **Nivel 1** es el que dibujas primero en una pizarra, siempre. Sitúa el problema y te
  da 30 segundos para pensar.
- **Nivel 2 es el que importa en entrevista.** Es donde se ven los servicios, las bases
  de datos y las flechas con protocolo y sincronía: `REST/JSON`, `Kafka, async`.
- **Nivel 4 no se dibuja.** Si lo dibujas, el código ya lo cuenta mejor y quedará
  desactualizado en una semana.

**Cuándo sí.** Toda pregunta de "diseña X": empieza por Contexto, baja a Contenedor, y
solo bajas a Componente si te lo piden.

**Cuándo no.** No lo menciones por su nombre si no vas a dibujar bien: decir "C4" y
luego hacer un diagrama de cajas sin niveles es peor que no nombrarlo.

> 💡 **Truco.** En una pizarra, **etiqueta cada flecha con protocolo y sincronía**. Es
> el detalle que distingue un diagrama de arquitecto de uno de desarrollador, y abre
> sola la conversación sobre acoplamiento temporal —que es donde quieres estar.

> **Veredicto:** dibujar mal es peor que no dibujar. Si solo retienes una cosa del modelo, que sea que
> el nivel de Contenedor es el que se pregunta, y que sus flechas llevan protocolo y
> sincronía.

---
## 6. 👥 Ley de Conway

**Qué es.** *"Las organizaciones diseñan sistemas que copian su estructura de
comunicación"* (Melvin Conway, 1967). No es una metáfora: es una restricción. Cuatro
equipos producen cuatro módulos, quieras o no.

**La maniobra de Conway inversa** es la consecuencia útil: si quieres una arquitectura
determinada, **reorganiza los equipos para que la produzcan**. Un monolito mantenido por
seis equipos no se parte con un refactor; se parte reasignando la propiedad del código.

**Cuándo sí.** Es la mejor respuesta a *"¿cómo dividirías esto en microservicios?"*
después de la respuesta de dominio: se divide por contexto acotado **y** por equipo que
lo va a operar, y ambos cortes deben coincidir.

**Cuándo no.** No la uses como excusa. "Es que Conway" no justifica una arquitectura
mala; explica su origen.

> **Veredicto:** una frontera de servicio que dos equipos comparten no es una frontera,
> es un punto de coordinación disfrazado.

---

## 7. 🧪 Fitness functions

**Qué es.** Una prueba automatizada que verifica un **atributo de arquitectura**, no una
funcionalidad. Es el mecanismo que impide que la arquitectura se degrade sin que nadie
lo note.

Ejemplos que puedes nombrar y que son reales en un proyecto Java:

- **ArchUnit**: "ninguna clase de `domain` importa `org.springframework`" — hexagonal
  verificada por test, no por disciplina.
- **Presupuesto de latencia**: el pipeline falla si el p99 del endpoint crítico sube de
  200 ms.
- **Grafo de dependencias**: fallar si un módulo nuevo crea un ciclo entre paquetes.

**Cuándo sí.** Cuando una regla de arquitectura importa lo suficiente como para que
duela violarla. Es la respuesta fuerte a *"¿cómo evitas que el equipo rompa la
arquitectura?"*.

**Cuándo no.** Si la regla no está clara, automatizarla congela una confusión.

> **Veredicto:** *"una regla de arquitectura que no está en el pipeline es una
> sugerencia"*. Esa frase, dicha en voz alta, vale un punto entero de liderazgo técnico.

---

## ⚠️ Errores frecuentes

| Se dice | Lo preciso |
|---|---|
| "Elegí microservicios porque escalan mejor" | Escalan **independientemente**; el throughput total puede bajar por la latencia de red |
| "La arquitectura es el diagrama" | El diagrama es la vista; la arquitectura es el conjunto de decisiones caras de revertir |
| "Los no funcionales los vemos después" | Son precisamente los que determinan la estructura; después ya no se pueden meter |
| "Documentamos en Confluence" | Un ADR vive en el repo, versionado con el código que justifica |
| "Escalabilidad = más servidores" | Solo si el servicio es sin estado, y lo es porque la sesión está fuera |
| "El arquitecto decide y el equipo implementa" | El arquitecto que no escribe código pierde el contacto con el costo real de sus decisiones |

---

## 📚 Para profundizar

- **Libro** — Mark Richards y Neal Ford, *Fundamentals of Software Architecture*, 2ª ed.
  (O'Reilly, 2025). Capítulos 4 (*Architecture Characteristics*), 6 (*Measuring and
  Governing*) y 19 (*Architecture Decisions*). **Es el libro de este capítulo**: si solo
  lees uno de todo el bloque, lee este.
- **Libro** — Neal Ford, Rebecca Parsons y Patrick Kua, *Building Evolutionary
  Architectures*, 2ª ed. (O'Reilly, 2022). Capítulos 2 y 3: el origen de las fitness
  functions.
- **Libro** — Michael Nygard, *Release It!*, 2ª ed. (Pragmatic Bookshelf, 2018).
  Capítulo 17: el formato ADR es suyo.
- Simon Brown — [The C4 model for visualising software architecture](https://c4model.com/):
  fuente primaria, con los cuatro niveles y las notaciones.
- Martin Fowler — [Conway's Law](https://martinfowler.com/bliki/ConwaysLaw.html): el
  enunciado original y la maniobra inversa.
- [Architecture Decision Records](https://adr.github.io/): plantillas y el catálogo de
  formatos, incluido el de Nygard.
- [ArchUnit](https://www.archunit.org/): la librería con la que se escriben fitness
  functions en Java.
- **Video** — *DeveloperToArchitect*, serie "Software Architecture Monday" de Mark
  Richards. Lecciones cortas, una por concepto; búscala por título.

---

## 🧠 Preguntas

Sin respuestas aquí. Todas, con su enunciado literal y respuesta en tres capas, en
[`12` — Respuestas](12-respuestas.md).

1. Nombra cinco atributos de calidad y di contra qué pelea cada uno. 🟢
2. ¿Cuáles son los cuatro niveles del modelo C4 y cuál casi nunca se dibuja? 🟢
3. ¿Qué secciones tiene un ADR en el formato de Nygard? 🟢
4. ¿Qué diferencia una decisión de arquitectura de una decisión de diseño? 🟡
5. ¿Por qué un ADR no se edita cuando la decisión cambia? 🟡
6. ¿Qué es una fitness function y en qué se diferencia de un test unitario? 🟡
7. Enuncia la ley de Conway y explica qué es la maniobra inversa. 🟡
8. Un ADR sin sección de consecuencias negativas: ¿qué problema tiene? 🟡
9. ¿En qué nivel de C4 aparecen las bases de datos y por qué no antes? 🟡
10. ¿Cuándo una decisión NO merece un ADR? 🟡
11. ¿Qué significa que una decisión sea "reversible" y por qué cambia cómo la tomas? 🟠
12. ¿Por qué etiquetar las flechas de un diagrama con protocolo y sincronía? 🟠
13. Te piden "alta disponibilidad y consistencia fuerte" a la vez. ¿Qué respondes? 🟠
14. ¿Qué tres fitness functions pondrías en un proyecto Spring Boot hexagonal? 🟠
15. ¿Por qué los atributos de calidad no se pueden añadir tarde en el proyecto? 🟠
16. ¿Qué responde un arquitecto que un desarrollador senior no responde? 🟠
17. Un equipo viola la arquitectura en cada PR. ¿Qué haces, más allá de revisar? 🟠
18. ¿Por qué "escalabilidad" es una respuesta incompleta sin "sin estado"? 🟠
19. Tienes 45 minutos y te dicen "diseña un acortador de URLs". ¿Cuáles son tus
    primeros tres movimientos, en orden? 🔴
20. Heredas un sistema sin documentación y sin nadie que lo conociera. ¿Cómo
    reconstruyes su arquitectura y en qué orden? 🔴
21. ¿Cómo mides "mantenibilidad" de forma que entre en un pipeline? 🔴
22. Tu propuesta es técnicamente mejor pero el equipo la rechaza. ¿Qué haces? 🔴
23. ¿Cómo justificas ante negocio una inversión que no añade funcionalidad? 🔴

---

**Siguiente:** [`02` — Estilos de despliegue](02-estilos-de-despliegue.md) ·
**Relacionado:** [`11` — Simulación de entrevista](11-simulacion-de-entrevista.md)
