# 🧠 Guía de aprendizaje

> Go para desarrolladores Java senior · la plataforma Meridian
> Cómo estudiar este curso con dos horas diarias, de lunes a viernes, sin que se
> te olvide a las tres semanas.

Este documento no es parte del temario: es el método para recorrerlo. Está escrito
para un contexto concreto —**refrescamiento profesional mientras buscas empleo**—,
y eso cambia varias decisiones respecto a estudiar sin prisa. Si tu situación es
otra, la parte del calendario sobra y el resto sirve igual.

---

## 1. El problema que hay que resolver

El curso son **131 horas y unas 36.000 líneas**. A dos horas diarias de lunes a
viernes, eso es **entre tres y cuatro meses**. Y ahí está el problema que nadie
menciona en los cursos largos:

> **Lo que estudies en la Fase 02 lo habrás olvidado cuando llegues a la Fase 12,
> salvo que hagas algo deliberado para impedirlo.**

No es una cuestión de esfuerzo ni de inteligencia. Es cómo funciona la memoria, y
tiene solución conocida. Lo que sigue es esa solución, adaptada a material técnico
—que es un caso especial— y a tu calendario.

---

## 2. La curva del olvido, con la honestidad que merece

### 2.1 Lo que realmente dice el experimento

Hermann Ebbinghaus publicó en 1885 el primer estudio sistemático sobre el olvido.
Se experimentó **a sí mismo** —n = 1— memorizando listas de sílabas sin sentido
(*WID*, *ZOF*, *KAP*) y midiendo cuánto tardaba en reaprenderlas días después. La
curva que obtuvo cae en picado: la mayor parte de la pérdida ocurre en las primeras
horas y después se aplana.

Las cifras que circulan —*"olvidas el 50% en una hora y el 70% en un día"*— son de
**ese** experimento, con **ese** material. Y hay que decirlo claro:

> ⚠️ **Las sílabas sin sentido no son este curso.** Ebbinghaus eligió material sin
> significado justamente para aislar la memoria pura de la comprensión. Tú vas a
> estudiar material **con significado**, **conectado a ocho años de experiencia en
> Java**, y **ejecutándolo en una terminal**. Tu curva es mucho más plana que la
> suya.

Lo que sí se traslada, y está replicado (Murre y Dros repitieron el experimento en
2015 con resultados muy parecidos):

- **La forma de la curva.** El olvido es rápido al principio y lento después.
- **La primera repetición es la que más rinde.** Revisar algo al día siguiente
  cuesta minutos y salva horas.
- **Cada repaso aplana la curva.** Después de cuatro o cinco repasos espaciados, la
  retención dura meses.

### 2.2 Los tres hallazgos que sí tienen evidencia sólida

De la investigación posterior, tres cosas están bien establecidas y son las que
vamos a usar:

**El efecto de espaciado.** Repartir el estudio en el tiempo retiene mucho más que
concentrarlo, incluso con el mismo número total de minutos. El metaanálisis de
Cepeda y colegas (2006, 254 estudios) además encontró algo accionable: **el
intervalo óptimo escala con el tiempo que quieres retener**. Si quieres acordarte
dentro de seis meses, los repasos separados por semanas ganan a los separados por
días.

**El efecto de prueba —o práctica de recuperación—.** *Intentar recordar* algo
consolida mucho más que volver a leerlo. Roediger y Karpicke (2006) lo demostraron
de la forma más incómoda posible: los estudiantes que releían se sentían **más
seguros** y rendían **peor** en la prueba a la semana. Esa es la trampa principal de
un curso de 36.000 líneas.

**Las dificultades deseables.** Robert Bjork acuñó el término para las condiciones
de estudio que hacen la práctica más difícil **y** el aprendizaje más duradero:
espaciar, intercalar temas distintos, recuperar en vez de releer, variar el
contexto. Todas se sienten peor mientras estudias y funcionan mejor después.

> 🧭 **La regla que sale de las tres.** Si una sesión de estudio se siente cómoda y
> fluida, probablemente no estás aprendiendo mucho. **La fluidez al leer es una
> ilusión**: reconoces el material, y reconocer no es recordar. La prueba es
> cerrar el documento e intentar reconstruirlo.

### 2.3 La advertencia que casi nadie hace

Casi toda esta investigación se hizo sobre **material declarativo** —vocabulario,
fechas, definiciones— y sobre estudiantes universitarios en laboratorio. La
transferencia a la adquisición de **habilidades complejas** está menos estudiada y
los efectos son más modestos.

Programar es sobre todo conocimiento **procedimental** ("cómo se hace") y
**condicional** ("cuándo conviene"), no declarativo. Por eso:

> **Las tarjetas no sustituyen a teclear.** Complementan. El 70% de tu tiempo tiene
> que ser código que se ejecuta; el resto es lo que impide que ese 70% se evapore.

Si tuvieras que elegir entre las dos cosas, elige teclear. Este documento existe
porque no tienes que elegir.

---

## 3. Por qué las tarjetas normales fracasan con programación

El error habitual es hacer tarjetas de API:

```text
❌  Frente:  ¿Cómo se declara un canal con búfer en Go?
    Dorso:   make(chan T, n)
```

Esa tarjeta es **inútil** y hace daño de tres formas:

1. **Eso se busca en un segundo** con `go doc`. Memorizar sintaxis es el uso menos
   rentable de tu memoria.
2. **No es lo que te va a fallar.** Lo que te va a fallar no es la sintaxis del
   canal: es no darte cuenta de que ese canal necesita un tope.
3. **Genera la ilusión de progreso.** Doscientas tarjetas de sintaxis en verde y
   sigues sin saber diseñar concurrencia.

Lo que sí merece una tarjeta es **el criterio**: las decisiones, los umbrales, los
síntomas y los reflejos que hay que recalibrar. Y da la casualidad de que **este
curso está estructurado exactamente alrededor de eso**.

---

## 4. Los seis tipos de tarjeta de este curso

Y dónde sale cada uno del material, con ejemplos reales.

### Tipo 1 — Reflejo ☕ (de `INSTINTOS.md`)

La más valiosa del curso. Cada entrada de `INSTINTOS.md` ya viene con las tres
partes de una buena tarjeta: el reflejo, su coste y el antídoto.

```text
Frente:  ☕ "Un pool es un `for` con `go` dentro."
         ¿Qué cuesta y qué hay que hacer en su lugar?

Dorso:   Coste (F06): 2.000.000 de goroutines y ~4 GB solo en pilas con un millón
         de filas, frente a 8 goroutines y 16 KB.
         Antídoto: el canal acotado FRENA al productor; el semáforo solo limita la
         ejecución, no la creación.
         Regla: cero concurrencia sin límite — toda goroutine tiene un dueño que
         sabe cuándo termina, y todo conjunto tiene un tope.
```

### Tipo 2 — Diagnóstico (de las "Errores comunes" de cada §7)

**Esta sección del curso ya está escrita en formato de tarjeta**: síntoma → causa →
fix mínimo. Son unas 130 en total y se convierten casi automáticamente.

```text
Frente:  El servicio se cuelga tras N peticiones. No hay errores en el log, no hay
         excepciones, las métricas no muestran nada raro. ¿Qué miras primero y qué
         apostarías que es?

Dorso:   db.Stats(): si InUse == MaxOpenConns, Idle == 0 y WaitCount crece, el pool
         está agotado.
         Causa casi segura: rows.Close() olvidado en un camino de ERROR — nadie lo
         olvida en el camino feliz.
         Fix: defer rows.Close() justo tras comprobar el error de Query. Linter:
         rowserrcheck.                                              (F09)
```

### Tipo 3 — Decisión (de los ⚖️ veredictos)

La que más rinde en una entrevista, porque la pregunta se formula igual.

```text
Frente:  Te proponen MongoDB para un servicio nuevo. ¿Qué preguntas antes de
         opinar, y qué respuesta lo descarta?

Dorso:   1. ¿Siempre lees el agregado entero? Si no → relacional.
         2. ¿Las partes tienen ciclo de vida propio? Si sí → relacional.
         3. ¿Necesitas transacciones multi-entidad a menudo? Si sí → el modelo
            documental está mal aplicado.
         4. ¿Quién define la forma del dato? Si un tercero que puede cambiarla,
            punto a favor del documento.
         La respuesta que NO vale: "es que ya lo tenemos levantado". Elegir el
         almacén por disponibilidad y no por la forma del dato es la causa raíz de
         la autopsia de la F11.
```

### Tipo 4 — Traducción (de los 📖 diccionarios)

Los dieciséis diccionarios del curso. **Siempre en las dos direcciones**, y la
tarjeta pregunta por la tercera columna, que es la que enseña.

```text
Frente:  @Transactional  →  ¿qué ocupa su lugar en Go, y dónde se rompe la
         equivalencia?

Dorso:   La transacción viaja POR PARÁMETRO: Save(ctx, q DBTX, item).
         Dónde se rompe: no hay propagación automática. Un parámetro más por
         firma a cambio de que el alcance transaccional SE VEA.
         El fallo del atajo: si lo escondes en el context, un olvido de envolver
         escribe fuera de transacción EN SILENCIO — y un *sql.Tx compartido con una
         goroutine no es seguro.                                     (F09)
```

### Tipo 5 — Predicción (de `BENCHMARKS.md`)

Aprovecha el efecto de generación: **predecir antes de ver la respuesta** consolida
más que leerla, incluso cuando te equivocas. Sobre todo cuando te equivocas.

```text
Frente:  B-05. Llamada directa frente a llamada por interfaz.
         ¿Dónde está el coste de verdad?

Dorso:   NO en el salto indirecto: son nanosegundos.
         Está en (a) el inlining que se pierde y (b) que meter un valor en una
         interfaz puede hacerlo escapar al montículo — mira allocs/op.
         Veredicto: evitar interfaces por rendimiento es optimización prematura en
         el 99,9% de los casos.
```

### Tipo 6 — Regla del proyecto (de los 🧭)

Las que se citan de memoria en una revisión de código. Unas cuarenta en el curso.

```text
Frente:  🧭 ¿Dónde se declaran las interfaces, y por qué?

Dorso:   DONDE SE CONSUMEN, no donde se implementan.
         Porque invierte la dirección de las dependencias: `postgres` no sabe que
         existe `opsreport`. Y porque permite que sean diminutas: el consumidor
         declara los dos métodos que usa, no los nueve que el servicio tiene.
         Señal de alarma: una interfaz de más de tres o cuatro métodos.   (F02)
```

---

## 5. El mapa: de dónde salen las tarjetas

No las escribas desde cero. El curso ya tiene el material identificado y marcado.

| Fuente | Tipo | Volumen aproximado |
|---|---|---|
| `INSTINTOS.md`, cada entrada ☕ | Reflejo | ~40 |
| §7 de cada fase, "Errores comunes" | Diagnóstico | ~130 |
| §10 de cada fase, ⚖️ "Cuándo NO usar esto" | Decisión | ~18 |
| §10 de cada fase, 📖 diccionario | Traducción | ~250 filas → elige ~80 |
| `BENCHMARKS.md`, las 24 hipótesis | Predicción | 24 |
| Los 🧭 "Regla del proyecto" | Regla | ~40 |
| Los ⚰️ autopsias, una por fase | Decisión + coste | 16 |

**Total razonable: entre 250 y 350 tarjetas para el curso completo.** Unas veinte
por fase. Si pasas de cuatrocientas, estás haciendo tarjetas de sintaxis y hay que
podar.

> 💡 **La regla de la poda.** Una tarjeta que aciertas cinco veces seguidas sin
> pensar **se borra**. Su trabajo ya está hecho, y cada tarjeta que sobrevive sin
> aportar te roba tiempo de las que sí.

---

## 6. El sistema de repaso

### 6.1 La herramienta

**Anki con el algoritmo FSRS activado** es la recomendación por defecto: es libre,
sincroniza entre máquina y teléfono —lo que permite repasar en huecos muertos— y
FSRS programa mejor que el algoritmo antiguo.

Si prefieres no depender de una aplicación, **una caja de Leitner de papel**
funciona: cinco compartimentos, la tarjeta acertada sube uno y la fallada vuelve al
primero. Es peor y es infinitamente mejor que no repasar.

### 6.2 Los intervalos

Con FSRS no configuras intervalos: fijas la **retención objetivo** y él calcula. Un
90% es razonable para este material; subirlo al 95% multiplica los repasos sin
mucha ganancia.

Si lo haces a mano, la progresión clásica sirve:

```text
acierto → 1 día → 3 días → 7 días → 16 días → 35 días → 90 días
fallo   → vuelve al principio
```

### 6.3 La regla de oro

> 🧭 **Solo se hace tarjeta de lo que ya entendiste.**
>
> Una tarjeta no es para aprender algo: es para **no olvidar** algo que ya
> aprendiste ejecutándolo. Si haces la tarjeta antes de haber tecleado el código,
> estás memorizando una frase, y eso no se transfiere a nada.
>
> Corolario práctico: **las tarjetas de una fase se escriben al terminarla**, no
> mientras la lees.

---

## 7. La sesión de dos horas

Dos horas de lunes a viernes. La estructura importa más que las horas.

```text
┌─ 00:00 – 00:12  REPASO (12 min)
│  Las tarjetas que el sistema te programe hoy. Sin excepciones, sin saltarlas,
│  y ANTES de nada — con la cabeza fresca y sin la tentación de dejarlo para el
│  final, que es cuando no se hace.
│
├─ 00:12 – 00:25  RECONSTRUCCIÓN (13 min)
│  Página en blanco. Sin mirar. Escribe de memoria qué hiciste ayer: qué
│  problema resolvía, qué decidiste, y por qué.
│  Después abres el documento y comparas. Lo que no recordaste es exactamente
│  lo que necesita una tarjeta.
│  ⚠️ Esta es la parte que se salta todo el mundo y la que más rinde.
│
├─ 00:25 – 01:40  MATERIAL NUEVO (75 min)
│  Con la terminal abierta. La regla del curso es "diciendo y haciendo": si
│  llevas dos pantallas sin ejecutar nada, algo va mal.
│  - Lee la sección
│  - TECLEA el código (no lo copies: teclearlo es la práctica)
│  - Ejecútalo
│  - Rómpelo a propósito cuando el 🧨 lo pida
│
├─ 01:40 – 01:55  EJERCICIOS (15 min)
│  Los 🟢 y 🟡 de la sección que acabas de ver. Ahora, no el viernes: un
│  ejercicio hecho en caliente cuesta un tercio.
│
└─ 01:55 – 02:00  CIERRE (5 min)
   - Dos o tres tarjetas nuevas de lo de hoy
   - Dos líneas en la bitácora: qué hiciste y qué te sorprendió
   - Si algo quedó a medias, la primera línea de mañana
```

### La bitácora

Un archivo, `docs/bitacora.md`, dos líneas por día. No es ceremonia: es **el
material con el que respondes la pregunta 8 de la defensa técnica** (*"¿qué le
dirías a tu yo de la Fase 01?"*) y, con más utilidad inmediata, es de donde salen
las anécdotas concretas de una entrevista.

```markdown
## 2026-09-24 · F06 §6.1

Reproduje la carrera del contador. Se perdieron 41.208 incrementos de 100.000 y
`-race` la encontró en dos segundos; a ojo era invisible.
Me sorprendió que el informe diga dónde se CREÓ cada goroutine, no solo dónde
chocaron. Eso es lo que resuelve el caso.
```

---

## 8. La semana

**Lunes a jueves:** material nuevo, con la estructura de arriba.

**Viernes: nada nuevo.** Es el día de consolidación y es innegociable:

```text
┌─ 20 min   Repaso de tarjetas de la semana, con calma
├─ 40 min   El ejercicio 🟠 o 🔴 que quedó pendiente
├─ 30 min   Relectura ACTIVA de la §10 de la fase en curso:
│           el ⚖️ veredicto y el 📖 diccionario, tapando el dorso
└─ 30 min   Bitácora de la semana + poda de tarjetas + tag de git si toca
```

> 💡 **Por qué el viernes no lleva material nuevo.** El intercalado funciona
> —mezclar temas rinde más que bloquearlos— pero solo cuando hay algo consolidado
> que mezclar. Cuatro días de avance y uno de asentamiento es el reparto que
> sostiene un curso de cuatro meses sin que la Fase 02 se evapore.

**Fin de semana: opcional y sin culpa.** Si repasas tarjetas veinte minutos el
sábado, la curva se aplana más. Si no, no pasa nada: el sistema está diseñado para
cinco días.

---

## 9. El calendario

### 9.1 Las cuentas, sin optimismo

131 horas de curso. De tus 10 horas semanales, unas **7,5 son material nuevo** —el
resto es repaso, reconstrucción y cierre, que no son tiempo perdido sino lo que
hace que el material nuevo se quede.

```text
131 h ÷ 7,5 h/semana ≈ 17,5 semanas ≈ 4 meses
```

Más el viernes de consolidación, que ya está descontado. **Llámalo cuatro meses**, y
desconfía de quien te diga que menos.

### 9.2 El calendario completo

| Semanas | Fases | Hito |
|---|---|---|
| 1 | 00, 01 | Máquina lista, `WorkItem` nace |
| 2 | 02 | 🎯 **La fase que decide el curso** — interfaces en el consumidor |
| 3 | 03, 04 | Errores y tests; el `main` de diagnóstico muere |
| 4 | 05 | API REST con stdlib; `@GetMapping` desmitificado |
| 5–6 | 06, 07 | ⭐ Concurrencia y ciclo de vida · **`bloque-a-completo`** |
| 7 | 08 | ⭐ La migración · `docs/rechazos.md` |
| 8–9 | 09 | PostgreSQL, transacciones, el debate del ORM |
| 10 | 10 | Clientes HTTP, resiliencia, pruebas sin red |
| 11 | 11, 12 | MongoDB y caché |
| 12–13 | 13 | Lotes, outbox, la plataforma se conecta |
| 14 | 14 | Observabilidad y endurecimiento |
| 15 | 15 | Medición y perfilado |
| 16–17 | 16 | ⭐ **El duelo** · `docs/veredicto.md` |
| 18 | 17 | Capstone y defensa técnica |

### 9.3 Los cuatro hitos que puedes enseñar

Marcados a propósito, porque en búsqueda de empleo importa tener algo que mostrar
antes del final:

| Semana | Qué tienes | Para qué sirve |
|---|---|---|
| **6** | Dos servicios completos en Go 1.13: dominio, tests, API, concurrencia, apagado ordenado | Un repositorio real que enseñar |
| **7** | `docs/rechazos.md` — lo que evaluaste y descartaste, con su condición de revisión | Es un ADR. Material de conversación de arquitectura |
| **13** | La plataforma conectada: outbox, lotes reanudables, idempotencia | La parte que más se parece a un sistema de producción |
| **17** | `docs/veredicto.md` — Go frente a Spring Boot, medido | **El artefacto con más valor de entrevista de todo el curso** |

---

## 10. La vía rápida, para empezar a rentabilizar en dos semanas

Cuatro meses es mucho cuando estás buscando trabajo. Hay una forma de extraer buena
parte del valor **antes** de recorrer el curso, y no sustituye al recorrido: lo
prepara.

**Durante las dos primeras semanas, en paralelo o antes de empezar**, lee —solo
leer, sin teclear— estas tres cosas de las dieciocho fases:

1. **Los ⚰️ autopsias** (la §7 de cada fase). Dieciséis casos con su coste en
   números.
2. **Los ⚖️ veredictos** (la §10). Dieciocho respuestas a "cuándo NO usar esto".
3. **Los 📖 diccionarios** (la §10). La traducción en las dos direcciones.

Son unas diez o doce horas y te dan el 80% del material que **se usa en una
conversación de arquitectura**: los costes medidos, los criterios de decisión y el
vocabulario comparado.

> ⚠️ **Lo que la vía rápida NO te da**, y conviene no engañarse: no vas a saber
> escribir Go. Leer sobre el bug del slice compartido no evita que lo cometas; hay
> que verlo pasar en tu terminal. La vía rápida sirve para **hablar del tema con
> criterio**, no para trabajar en el lenguaje.

De estas tres, si solo tuvieras tiempo para una, lee los ⚖️ veredictos. Son lo que
distingue a alguien que "sabe una tecnología" de alguien que sabe **cuándo no
usarla**, que es la pregunta que hace un entrevistador senior.

---

## 11. Qué hacer cuando el plan se interrumpe

Va a pasar. Aparece un proceso de selección, tres entrevistas en una semana, una
prueba técnica de cuatro horas. **El plan tiene que sobrevivir a eso**, porque el
empleo es la prioridad y el curso no.

### El modo mantenimiento

Cuando no puedas dedicar dos horas:

```text
15 minutos al día. SOLO tarjetas. Nada de material nuevo.
```

Eso es todo. Quince minutos mantienen viva la curva de lo ya estudiado
indefinidamente. **Para eso existe la repetición espaciada**: no es solo para
aprender más rápido, es para que una interrupción de tres semanas no te devuelva al
punto de partida.

### Al volver

No retomes donde lo dejaste. Dedica **una sesión entera** a:

1. Las tarjetas atrasadas (puede haber muchas; hazlas todas, aunque duela).
2. Reconstruir de memoria la última fase que terminaste.
3. Releer tu bitácora de las dos semanas anteriores.

Y entonces sigues. Perder un día en recuperar contexto ahorra tres de avanzar mal.

### Si la búsqueda se alarga y hay que recortar

Si llega un punto en el que hay que elegir, este es el orden en que yo recortaría:

1. **Primero, los ejercicios 🔴 y los desafíos de cierre.** Son excelentes y son lo
   más caro por hora.
2. **Después, las fases 11 y 12** (MongoDB y Valkey). Valiosas, y las menos
   conectadas al resto: los otros servicios funcionan sin ellas.
3. **Nunca recortes las fases 02, 06, 09, 13 y 16.** Son las que sostienen el
   curso, y las cuatro primeras son las que más se transfieren a una entrevista de
   Java.

---

## 12. Cómo saber si está funcionando

Cuatro señales, ninguna es "me siento cómodo leyendo":

**A los quince días.** Puedes explicarle a alguien —en voz alta, sin notas— por qué
un slice no es un `ArrayList` y qué bug produce la diferencia. Si necesitas mirar,
la Fase 01 no está consolidada.

**Al mes.** Abres un archivo Go cualquiera de tu propio código y ves **al menos una
cosa que cambiarías**, con el porqué. La capacidad de criticar código propio con
criterio es la primera señal real.

**A los dos meses.** Reconoces un ☕ en código ajeno **sin buscarlo**. Lees un
repositorio de GitHub y te salta a la vista una interfaz de nueve métodos con un
solo implementador.

**Al final.** Puedes sostener veinte minutos de conversación sobre "Go frente a
Spring Boot" **defendiendo las dos posiciones con datos**, incluida la de no migrar.
Ese es el objetivo declarado del curso.

Y la contraseñal, que es la más importante:

> ⚠️ **Si tus tarjetas están todas en verde y no has tecleado en tres días, el
> sistema se rompió.** Las tarjetas mantienen; no construyen. Un porcentaje de
> acierto alto con la terminal cerrada es exactamente la ilusión de fluidez con
> otro disfraz.

---

## 13. Errores comunes del estudio

En el formato del curso: síntoma → causa → fix mínimo.

**1. Releer en vez de recuperar.**
*Síntoma:* llevas cuatro fases, todo te suena, y no sabes explicar ninguna.
*Causa:* releer produce reconocimiento, que se siente como saber y no lo es.
*Fix:* los 13 minutos de reconstrucción en página en blanco. Innegociables.

**2. Copiar y pegar el código.**
*Síntoma:* las sesiones van rapidísimo y no se te queda nada.
*Causa:* teclear **es** la práctica. Copiar salta el paso donde el aprendizaje
ocurre.
*Fix:* teclea. Y cuando el compilador te grite, lee el error antes de arreglarlo.

**3. Tarjetas de sintaxis.**
*Síntoma:* cuatrocientas tarjetas, treinta minutos de repaso diario, y el repaso
empieza a dar pereza.
*Causa:* estás memorizando lo que `go doc` responde en un segundo.
*Fix:* poda. Los seis tipos de §4 y nada más.

**4. Hacer la tarjeta antes de haber ejecutado el código.**
*Síntoma:* aciertas la tarjeta y al escribir el código no te sale.
*Causa:* memorizaste una frase, no un procedimiento.
*Fix:* las tarjetas se escriben **al terminar** la fase, no mientras la lees.

**5. Saltarse el viernes.**
*Síntoma:* avanzas más rápido y a las seis semanas no recuerdas la Fase 02.
*Causa:* sin consolidación, el material nuevo desplaza al viejo.
*Fix:* el viernes no lleva material nuevo. Nunca.

**6. Estudiar sin ejecutar la infraestructura.**
*Síntoma:* llegas a la Fase 09 y `make up` falla, y pierdes la sesión en Docker.
*Causa:* la Fase 00 se hizo por encima.
*Fix:* la Fase 00 se termina de verdad, con el checklist en verde.

**7. Perseguir el 100% de las tarjetas.**
*Síntoma:* el repaso ocupa cuarenta minutos y comes tiempo de teclear.
*Causa:* retención objetivo demasiado alta, o demasiadas tarjetas.
*Fix:* baja FSRS al 90% y poda. **El objetivo no es acordarte de todo: es acordarte
de lo que decide.**

**8. Abandonar durante una racha de entrevistas.**
*Síntoma:* tres semanas sin abrir nada y la sensación de haber perdido el curso.
*Causa:* el plan no contemplaba la interrupción.
*Fix:* modo mantenimiento, 15 minutos de tarjetas. La curva se sostiene sola.

---

## 14. Referencias

### Sobre memoria y estudio

- **Ebbinghaus, H. (1885).** *Über das Gedächtnis*. El original. Traducción inglesa
  libre en https://psychclassics.yorku.ca/Ebbinghaus/ — corto y sorprendentemente
  legible.
- **Murre, J. & Dros, J. (2015).** *Replication and Analysis of Ebbinghaus'
  Forgetting Curve*. PLoS ONE. La replicación moderna; útil para saber qué de aquel
  experimento aguantó.
- **Cepeda, N. et al. (2006).** *Distributed practice in verbal recall tasks: A
  review and quantitative synthesis*. Psychological Bulletin. El metaanálisis del
  efecto de espaciado, con la relación entre intervalo y retención.
- **Roediger, H. & Karpicke, J. (2006).** *Test-Enhanced Learning*. Psychological
  Science. **El estudio que hay que leer**: los que releen se sienten más seguros y
  rinden peor.
- **Brown, Roediger & McDaniel (2014).** *Make It Stick: The Science of Successful
  Learning*. La divulgación bien hecha de todo lo anterior. Si solo lees un libro
  de esta lista, este.
- **Bjork, R.** Trabajos sobre *desirable difficulties* — https://bjorklab.psych.ucla.edu
- **Oakley, B.** *A Mind for Numbers* y el curso *Learning How to Learn* (Coursera,
  gratuito). Orientado a material técnico y muy práctico.

> ⚠️ Casi toda esta investigación se hizo sobre material declarativo y en
> laboratorio. La transferencia a habilidades complejas como programar está menos
> estudiada y los efectos son más modestos. Úsalo como guía, no como receta.

### Herramientas

- **Anki** — https://apps.ankiweb.net — libre, sincroniza, y con **FSRS** activado
  en los ajustes del mazo. Es lo que recomienda este documento.
- **FSRS** — https://github.com/open-spaced-repetition — el algoritmo; el README
  explica por qué programa mejor que SM-2.
- **Caja de Leitner** — cinco compartimentos y papel. Peor que Anki, infinitamente
  mejor que nada.

### Vídeo

- **Learning How to Learn** — Barbara Oakley y Terrence Sejnowski, en Coursera.
  Gratis, unas quince horas, y la mitad es directamente aplicable aquí.
- **Justin Sung**, en YouTube — sobre codificación profunda y mapas conceptuales
  frente a tarjetas. Útil como contrapeso: las tarjetas no son la única
  herramienta, y para material conceptual no siempre son la mejor.
- **Ali Abdaal**, sobre práctica de recuperación — divulgación correcta, aunque
  orientada a estudiantes de medicina más que a ingeniería.

### Del propio curso

- **`INSTINTOS.md`** — la fuente principal de tarjetas, y el documento que hay que
  releer al terminar cada fase.
- **`0-ESTRUCTURA-CURSO.md`** §7 — el inventario de deudas 💸, que es un buen mapa
  de qué se conecta con qué.
- **`BENCHMARKS.md`** — las 24 hipótesis, para las tarjetas de predicción.

---

## 15. Resumen en una página

```text
CADA DÍA (lu–ju, 2 h)
  12 min  tarjetas
  13 min  reconstruir ayer en página en blanco  ← la parte que rinde
  75 min  material nuevo, TECLEANDO
  15 min  ejercicios 🟢🟡 en caliente
   5 min  tarjetas nuevas + bitácora

VIERNES (2 h)
  sin material nuevo · ejercicio 🟠/🔴 · relectura activa de la §10 · poda · tag

CUANDO NO PUEDAS
  15 min de tarjetas. Solo eso. Mantiene la curva indefinidamente.

LAS TARJETAS
  6 tipos: reflejo ☕ · diagnóstico · decisión ⚖️ · traducción 📖 · predicción 📐 ·
  regla 🧭
  250–350 en total. Solo de lo ya ejecutado. Se podan sin pena.

CALENDARIO
  ~18 semanas · hitos que se enseñan en la 6, 7, 13 y 17

LA TRAMPA
  Si se siente cómodo, no estás aprendiendo. La fluidez al leer es una ilusión.
```

> 🧭 **Y la regla que lo gobierna todo:** las tarjetas **mantienen**, la terminal
> **construye**. Si un día tienes que elegir, teclea.
