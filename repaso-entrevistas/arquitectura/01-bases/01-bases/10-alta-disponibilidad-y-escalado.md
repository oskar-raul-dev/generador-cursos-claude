# 10 — Alta disponibilidad y escalado

> Horizontal contra vertical y por qué "horizontal" es una respuesta incompleta. Estado,
> sesión, réplicas, autoescalado, balanceo, salud contra disponibilidad, zonas y regiones,
> RTO y RPO, despliegues sin caída y el costo real de cada nueve añadido.
> Asume leído [`09` — Resiliencia](09-resiliencia.md).
>
> **Vigencia:** 2026-09-18.

---

## 1. 🎯 El problema

*"El sistema tiene que aguantar diez veces más carga."* La respuesta refleja es "escalamos
horizontalmente". Y la pregunta siguiente te desmonta: *"¿y la sesión del usuario?"*.

Porque escalar horizontalmente **solo funciona si el servicio no tiene estado**, y casi
ningún servicio nace sin estado. La respuesta completa tiene dos mitades y casi todo el
mundo da una:

> **Escalo horizontalmente, y puedo hacerlo porque el servicio es sin estado — y lo es
> porque la sesión está fuera, en Redis, y los ficheros en almacenamiento de objetos.**

---

## 2. ↔️ Horizontal contra vertical

| | Vertical (scale up) | Horizontal (scale out) |
|---|---|---|
| Qué haces | Máquina más grande | Más máquinas |
| Techo | El de la máquina mayor | Prácticamente ninguno |
| Coste | Superlineal: el doble de CPU cuesta más del doble | Lineal |
| Disponibilidad | **No mejora**: sigue habiendo un punto único de fallo | Mejora: sobrevives a perder una instancia |
| Complejidad | Ninguna | Estado, balanceo, coherencia |
| Requiere | Nada | **Que el servicio no tenga estado** |

- La fila de disponibilidad es la que se pregunta: **escalar vertical no da HA**. Una
  máquina más grande sigue siendo una máquina.
- Escalar vertical no es una vergüenza: es lo correcto para bases de datos relacionales
  hasta un punto sorprendentemente alto, y es reversible en minutos.

> **Veredicto:** vertical para la base de datos, horizontal para todo lo demás — y horizontal solo
> después de haber sacado el estado. Escalar vertical no es rendirse: es la respuesta
> correcta más veces de las que se admite.

---
## 3. 🗃️ Estado: el verdadero obstáculo

Los cuatro sitios donde se esconde el estado que impide escalar, con su salida:

```text
Sesión HTTP en memoria  → Redis (Spring Session), o JWT sin estado en servidor
Ficheros en disco local → S3 / GCS / almacenamiento de objetos
Caché local de la app   → caché distribuida, o aceptar incoherencia y medirla
Scheduler @Scheduled    → se ejecuta en TODAS las instancias: hace falta ShedLock o un
                          planificador con elección de líder
```

- El último es el que más sorprende en producción: escalas a tres instancias y el trabajo
  nocturno se ejecuta tres veces.
- **Sticky sessions** (el balanceador manda siempre al mismo nodo) es el parche clásico.
  Funciona, y el precio es que pierdes el reparto uniforme y la sesión se pierde igual
  cuando el nodo cae. Es una muleta, no una solución.

> 🧠 **Modelo mental.** Escalar no es un problema de capacidad, es **un problema de
> estado**. Quien identifica dónde vive el estado ya ha respondido la pregunta.

> **Veredicto:** escalar no es un problema de capacidad, es un problema de estado. Quien sabe enumerar
> dónde se esconde ya ha respondido la pregunta.

---
## 4. 📈 Autoescalado

**Qué es.** Añadir o quitar instancias automáticamente según una métrica.

**Sobre qué métrica**, en orden de utilidad real:

```text
Longitud de cola / lag del consumidor  → la mejor: mide trabajo pendiente
Peticiones por segundo por instancia   → buena para HTTP
Latencia p99                           → buena, pero reacciona tarde
CPU                                    → la que todos usan y la peor: un servicio
                                         bloqueado en I/O tiene CPU baja y está saturado
```

**Lo que hay que nombrar además de la métrica**, porque es donde se falla:

- **El tiempo de arranque.** Si la instancia tarda 3 minutos en estar lista, el
  autoescalado llega tarde al pico. Es el argumento real para cuidar el tiempo de
  arranque en Spring Boot.
- **La histéresis.** Umbrales distintos para subir y para bajar, y periodo de
  enfriamiento; si no, el sistema oscila creando y destruyendo instancias.
- **Lo que hay detrás.** Escalar la capa de aplicación a 50 instancias contra una base de
  datos con 100 conexiones convierte el escalado en una denegación de servicio a tu
  propia BD. **El pool de conexiones es el límite real** más veces de lo que parece.

> **Veredicto:** el autoescalado falla más por la métrica que por la configuración. Si eliges CPU sin
> pensarlo, has automatizado una medida que no correlaciona con tu saturación.

---
## 5. ⚖️ Balanceo y comprobaciones de salud

**Algoritmos**, con cuándo importa la diferencia: *round robin* (por defecto), *least
connections* (mejor con peticiones de duración desigual), *hash por clave* (cuando
necesitas afinidad).

**Salud contra disponibilidad: dos endpoints distintos**, y esto es pregunta de
entrevista:

```text
/health/liveness   → ¿el proceso está vivo? Si falla → REINICIAR
/health/readiness  → ¿puede atender tráfico ahora?  Si falla → SACAR DEL BALANCEO
```

- Confundirlos tiene consecuencia concreta: si el *liveness* comprueba la base de datos y
  la BD se cae, Kubernetes **reinicia todos tus pods** en bucle por un problema que no
  estaba en ellos.
- El *readiness* sí debe comprobar dependencias críticas: un pod que arrancó pero aún no
  tiene el pool de conexiones listo no debe recibir tráfico.
- Spring Boot Actuator expone ambos por separado, y hay que activarlos explícitamente.

> **Veredicto:** dos endpoints, dos preguntas, dos consecuencias. Confundirlos convierte la caída de una
> dependencia en la caída de tu flota entera.

---
## 6. 🌍 Zonas, regiones y multi-región

```text
Zona de disponibilidad (AZ) → datacenter independiente, latencia de ~1 ms entre zonas
Región                      → conjunto de zonas, separadas por cientos o miles de km
```

**La regla base:** multi-AZ es barato y casi obligatorio; multi-región es caro y se
justifica por cumplimiento normativo, por latencia de usuarios lejanos o por un RTO que
no tolera perder una región entera.

**Los modelos multi-región**, con su precio:

| Modelo | RTO | Coste | El problema real |
|---|---|---|---|
| **Activo-pasivo** (piloto) | Minutos a horas | Bajo | La región pasiva nunca se ha probado bajo carga |
| **Activo-pasivo caliente** | Minutos | Medio | Igual, pero menos |
| **Activo-activo** | Cercano a cero | Alto | **Escritura en dos regiones**: conflictos y latencia de replicación |

> ⚠️ **Advertencia.** El problema de activo-activo no es la infraestructura, es **el
> dato**. Si ambas regiones aceptan escrituras sobre el mismo registro, necesitas
> resolución de conflictos, y esa es una decisión de negocio ("gana la última", "gana la
> mayor", "se revisa a mano"), no de arquitectura. En banca se suele particionar por
> cliente para que cada registro tenga una sola región dueña.

> **Veredicto:** multi-AZ es casi obligatorio y casi gratis; multi-región es caro y se justifica con un
> requisito escrito, no con una aspiración.

---
## 7. ⏱️ RTO y RPO

Las dos siglas que hay que saber sin dudar:

```text
RTO (Recovery Time Objective)  → cuánto tiempo puedes estar caído
RPO (Recovery Point Objective) → cuántos datos puedes perder
```

- **RPO = 0** exige replicación síncrona, y la replicación síncrona **cuesta latencia en
  cada escritura**. Es un trade-off de [`01` §2](01-fundamentos-del-arquitecto.md#2-️-trade-off-la-unidad-mínima-de-respuesta), no una casilla que marcar.
- Un backup nocturno significa RPO de 24 horas. Decirlo en voz alta suele ser suficiente
  para que negocio reconsidere el presupuesto.

> 🩺 **Diagnóstico.** La pregunta que desmonta cualquier plan de recuperación: **"¿cuándo
> fue la última vez que restauraron un backup?"**. Un backup que nunca se ha restaurado
> no es un backup, es una carpeta.

> **Veredicto:** son números de negocio disfrazados de siglas técnicas. Tu trabajo no es elegirlos: es
> traducir lo que cuestan para que negocio los elija bien.

---
## 8. 📊 Los nueves y el presupuesto de error

| Disponibilidad | Caída al mes | Caída al año |
|---|---|---|
| 99 % | ~7,2 h | ~3,65 días |
| 99,9 % | ~43 min | ~8,76 h |
| 99,99 % | ~4,3 min | ~52,6 min |
| 99,999 % | ~26 s | ~5,26 min |

- **Cada nueve multiplica el coste** y normalmente exige multi-región, despliegue
  automático y guardia 24/7.
- **99,99 % son 4 minutos al mes**: menos de lo que tarda un humano en leer la alerta y
  conectarse. A partir de ahí, la recuperación tiene que ser automática, y eso cambia la
  arquitectura entera.

**Presupuesto de error (error budget).** Si el objetivo es 99,9 %, tienes 43 minutos de
caída al mes **para gastar**. Mientras quede presupuesto, se despliega y se experimenta;
cuando se agota, se congelan las funcionalidades y se trabaja en fiabilidad.

> **Veredicto:** convierte la fiabilidad en una negociación con números en vez de en una
> discusión de opiniones. Es la respuesta fuerte a *"¿cómo equilibras velocidad y
> estabilidad?"*.

---

## 9. 🚀 Despliegues sin caída

| Estrategia | Cómo | Precio |
|---|---|---|
| **Rodante (rolling)** | Sustituye instancias por tandas | Conviven dos versiones: el contrato debe ser compatible |
| **Azul-verde** | Dos entornos completos, se cambia el tráfico | Doble infraestructura durante el cambio |
| **Canario** | 1 % del tráfico a la versión nueva, se observa, se sube | Necesita métricas por versión y automatización de reversión |
| **Feature flag** | Se despliega apagado, se enciende por segmento | Deuda de flags si no se limpian |

**Lo que se pregunta de verdad, y es lo que une este capítulo con el 08:** durante
cualquiera de las tres primeras **conviven dos versiones del código contra la misma base
de datos**. De ahí salen dos reglas:

```text
1. Los cambios de esquema son compatibles hacia atrás (expand / contract):
   añade columna → despliega código que la escribe y lee ambas → migra → borra la vieja
2. Nunca se despliega un cambio de esquema destructivo en el mismo release que el código
```

- Esto es compatibilidad de contrato de
  [`08` §5](08-comunicacion-e-integracion.md#5--contratos-y-versionado) aplicada a la base
  de datos.
- **Azul-verde no resuelve el problema del esquema**: los dos entornos comparten los
  datos.

> **Veredicto:** la estrategia de despliegue es la parte fácil. La difícil es el esquema, porque la base
> de datos no tiene azul-verde.

---
## 10. 🧭 Cómo se elige

El orden en que se atacan las cosas cuando piden "que aguante más" o "que no se caiga":

```text
¿El servicio tiene estado?
    → Sácalo primero. Sin esto, escalar horizontalmente no funciona y no hay más conversación.
¿La carga es predecible y el techo está lejos?
    → Vertical. Es reversible en minutos y no añade complejidad.
¿Necesitas sobrevivir a perder una instancia?
    → Horizontal, obligatorio. Vertical no da disponibilidad.

¿Qué métrica dispara el autoescalado?
    → Cola o lag si existe; peticiones por instancia si es HTTP; CPU solo como último recurso.
¿Qué te limita antes de lo que crees?
    → El pool de conexiones a la base de datos, casi siempre.

¿Qué disponibilidad piden, y para qué flujo?
    → Nunca un número único para todo el sistema: se reparte por flujo y se cuenta el coste.
¿Multi-AZ o multi-región?
    → Multi-AZ siempre. Multi-región solo con un requisito escrito de normativa, latencia o RTO.
```

> **Regla de entrevista:** antes de proponer nada, pregunta **qué flujo** tiene que
> aguantar y **qué cuesta un minuto de caída**. Diseñar alta disponibilidad sin esos dos
> datos es elegir el precio antes de conocer el presupuesto.

---

## ⚠️ Errores frecuentes

| Se dice | Lo preciso |
|---|---|
| "Escalo horizontal" | Incompleto sin "porque el servicio no tiene estado" |
| "Escalar vertical da alta disponibilidad" | No: sigue siendo un único punto de fallo |
| "Autoescalo por CPU" | Un servicio bloqueado en I/O está saturado con CPU baja |
| "Liveness comprueba la base de datos" | Eso reinicia toda la flota cuando la BD cae; va en readiness |
| "Tenemos backups" | Un backup no restaurado nunca no es un backup |
| "Multi-región es más disponibilidad" | Es más disponibilidad y un problema de consistencia de datos |
| "Azul-verde evita problemas de esquema" | Comparten datos: el esquema debe ser compatible igual |
| "RPO cero es lo ideal" | Exige replicación síncrona y cuesta latencia en cada escritura |

---

## 📚 Para profundizar

- **Libro** — Betsy Beyer et al., *Site Reliability Engineering* (O'Reilly, 2016).
  Capítulos 3 (*Embracing Risk*, de donde sale el presupuesto de error) y 4 (SLO). Está
  disponible gratis en la web de Google SRE.
- **Libro** — Martin Kleppmann, *Designing Data-Intensive Applications* (O'Reilly, 2017).
  Capítulos 5 y 6: replicación y particionado, que es lo que hay detrás de todo escalado
  de datos.
- **Libro** — Michael Nygard, *Release It!*, 2ª ed. Capítulos 9–11: despliegues sin
  caída y diseño para producción.
- [Google SRE Book — Embracing Risk](https://sre.google/sre-book/embracing-risk/):
  el capítulo del presupuesto de error, íntegro y gratuito.
- [Spring Boot Actuator — Kubernetes Probes](https://docs.spring.io/spring-boot/reference/actuator/endpoints.html#actuator.endpoints.kubernetes-probes):
  liveness y readiness separados, con la configuración exacta.
- [Amazon Builders' Library — Static stability using Availability Zones](https://aws.amazon.com/builders-library/static-stability-using-availability-zones/):
  por qué multi-AZ se diseña para no necesitar reaccionar al fallo.
- **Tutorial** — Baeldung, «Spring Session with Redis»:
  cómo se saca la sesión del proceso, que es el paso 1 de todo escalado horizontal.
- **Video** — GOTO Conferences y SREcon, charlas sobre error budgets y SLO. Búscalas
  por título.

---

## 🧠 Preguntas

Sin respuestas aquí. Todas, con enunciado literal y respuesta en tres capas, en
[`12` — Respuestas](12-respuestas.md).

1. ¿Qué diferencia hay entre escalar vertical y horizontal? 🟢
2. ¿Qué es RTO y qué es RPO? 🟢
3. ¿Cuánta caída al mes permite un 99,99 %? 🟢
4. ¿Por qué "escalo horizontalmente" es una respuesta incompleta? 🟡
5. ¿Qué diferencia hay entre liveness y readiness? 🟡
6. Nombra cuatro sitios donde se esconde el estado que impide escalar. 🟡
7. ¿Por qué escalar vertical no da alta disponibilidad? 🟡
8. ¿Qué pregunta desmonta la mayoría de los planes de recuperación? 🟡
9. ¿Qué pasa con un `@Scheduled` cuando escalas a tres instancias? 🟠
10. ¿Por qué CPU es una mala métrica de autoescalado? 🟠
11. ¿Qué métrica de autoescalado es la mejor y por qué? 🟠
12. ¿Qué son las sticky sessions y qué precio tienen? 🟠
13. ¿Qué pasa si pones la comprobación de BD en el liveness? 🟠
14. ¿Qué es el presupuesto de error y para qué sirve? 🟠
15. ¿Qué límite real suele encontrar el escalado antes que la CPU? 🟠
16. ¿Qué exige un RPO de cero y qué cuesta? 🟠
17. ¿Cuál es el problema real de una arquitectura activo-activo? 🟠
18. ¿Por qué azul-verde no resuelve los cambios de esquema? 🟠
19. ¿Qué es el patrón expand/contract en migraciones de esquema? 🟠
20. Te piden 99,999 %. ¿Qué respondes y qué preguntas antes? 🔴
21. Escalas a 50 instancias y el sistema empeora. Da tres hipótesis ordenadas. 🔴
22. Diseña el despliegue sin caída de un cambio que renombra una columna usada
    por tres servicios. 🔴
23. Un banco pide activo-activo entre dos regiones para cuentas. ¿Qué problemas
    planteas y qué alternativa propones? 🔴

---

**Anterior:** [`09` — Resiliencia](09-resiliencia.md) ·
**Siguiente:** [`11` — Simulación de entrevista](11-simulacion-de-entrevista.md) ·
**Relacionado:** [`03-datos/05` — Réplicas y lag](../03-datos/05-replicas-y-lag.md)
