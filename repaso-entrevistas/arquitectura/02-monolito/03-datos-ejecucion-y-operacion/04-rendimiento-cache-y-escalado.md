# 04 — Rendimiento, caché y escalado

Aprenderás a escalar un monolito siguiendo el recurso que de verdad limita: cómo pasar de «checkout
va lento» a una hipótesis medible, qué compran réplicas, caché o escalado vertical, y por qué extraer
el módulo caliente sin esa medición suele mover el cuello de sitio sin ensancharlo.

## 1. 🎯 Síntoma y decisión

En la hora pico, el p99 de checkout llega a 1,8 s con un SLO de 800 ms. El equipo propone extraer
`inventory` a un servicio «porque es lo que más aparece en las trazas». Antes, alguien prueba lo
rápido: pasar de 4 a 8 réplicas. El p99 empeora y la base empieza a rechazar conexiones. La CPU de
las réplicas nunca pasó del 35 %.

Tres respuestas —extraer, replicar, cachear— compiten por el mismo síntoma, y ninguna se puede elegir
sin saber qué recurso se agota. La decisión de este capítulo es cómo encontrarlo y qué movimiento
compra capacidad en ese recurso.

## 2. 🧠 Modelo mental

```text
SLO incumplido en checkout
   │ ¿dónde espera la petición?          traza por etapa
   ▼
¿CPU alta en el proceso? ── sí ──► perfil de CPU ─► hotspot, o más réplicas
   │ no
   ▼
espera en pool, lock, consulta o dependencia
   └─► reducir el tiempo de uso, índice, límite de concurrencia,
       caché de lecturas que toleren obsolescencia
```

Una réplica más solo añade capacidad si el límite es el cómputo del proceso. Si el límite es la base,
cada réplica abre su propio pool: con 8 réplicas y pools de 20, son 160 conexiones potenciales contra
un PostgreSQL cuyo `max_connections` por defecto es 100. La relación que manda es simple: conexiones
ocupadas ≈ peticiones por segundo × segundos que cada una retiene la conexión. Bajar el tiempo de uso
libera más capacidad que subir el pool.

## 3. 🔍 Evidencia antes del diagnóstico

| Nivel | En el sistema de comercio |
|---|---|
| Observación | p99 de 1,8 s solo en la hora pico; CPU de las réplicas al 35 %; el 70 % del tiempo de la traza en «esperando conexión» y en una consulta de disponibilidad que recorre la tabla sin índice por `sku`; errores de conexión al duplicar réplicas |
| Inferencia | el límite está en la base —una consulta cara y conexiones retenidas—, no en el cómputo de la aplicación |
| Diagnóstico | extraer `inventory` no cambiaría el recurso limitante: misma consulta, misma base, más red |
| Recomendación | índice para la consulta, menos tiempo de conexión por petición, pools dimensionados contra la base y caché solo para lecturas de catálogo |

Las cifras son supuestos del ejercicio. Qué refutaría el diagnóstico: si la traza mostrara CPU al
90 % en serialización JSON, el cuello sería el proceso y las réplicas o la optimización del hotspot sí
ayudarían. Y si la consulta ya tuviera índice y siguiera lenta, habría que mirar su plan y los locks
antes de concluir.

## 4. 🛠️ Del SLO al recurso limitante

Primero se separan latencia, throughput, errores y saturación por ruta. CPU alta conduce a perfiles;
CPU baja con alta latencia apunta a I/O, locks, colas o pools. Añadir réplicas ayuda si el trabajo es
paralelizable y el estado de sesión no vive en memoria local; puede empeorar el sistema si cada
réplica abre más conexiones contra una base ya saturada.

| Cuello observado | Primer movimiento reversible | Riesgo que vigilar |
|---|---|---|
| CPU del proceso | optimizar hotspot o escalar réplicas | coordinación y costo |
| heap/GC | reducir retención y limitar lotes | OOM del proceso compartido |
| consultas | índice, plan, paginación o read model | datos obsoletos |
| pool de conexiones | reducir tiempo de uso y acotar concurrencia | cola y timeout |
| dependencia externa | cachear lectura o degradar | invalidación y consistencia |

Una caché necesita propietario, clave, TTL o invalidación y comportamiento ante miss. Cachear stock
para decidir una reserva rompe la invariante; cachear una vista de catálogo puede aceptar segundos de
obsolescencia. La afinidad de sesión puede estabilizar temporalmente una migración, pero reduce
balanceo y oculta estado por réplica.

Extraer el módulo caliente solo ayuda si separa el recurso limitante. Si `inventory` sigue usando la
misma consulta y el mismo pool, HTTP añade latencia sin crear capacidad. El experimento se conserva
únicamente si mejora el SLO bajo la misma carga y no degrada corrección ni coste por operación.

## 5. 🧰 Plataformas

| Plataforma | Mecanismo relevante | Qué no resuelve | Trampa frecuente |
|---|---|---|---|
| Java | JFR/JDK Mission Control y métricas de runtime | el perfil no decide la frontera | optimizar solo microbenchmarks |
| Node/TypeScript | profiler V8 y métricas del event loop | más workers no aceleran I/O limitado por DB | bloquear el event loop |
| Go | `pprof`, trace y métricas runtime | goroutines no crean capacidad de CPU | perfilar sin considerar overhead |
| Python | `cProfile`, `tracemalloc` y métricas de workers | threads no eliminan toda restricción de CPU | atribuir todo al GIL |

Las cuatro herramientas responden a la misma pregunta —¿en qué gasta el tiempo este proceso?— y
ninguna a la anterior: si el proceso es el cuello. Un perfil de CPU impecable de una aplicación que
pasa el 70 % del tiempo esperando conexión optimiza lo que no importa. Por eso el orden es traza por
etapa primero, perfil del proceso después, y solo si la traza lo señala.

## 6. ⚖️ Decisión y coste

Mide el recurso limitante, formula una hipótesis y cambia una variable por experimento. Escalar verticalmente, añadir réplicas, optimizar una consulta o aislar trabajo son alternativas que esa medición permite comparar. Cada opción paga capacidad, coordinación o consistencia según el caso. Conserva el cambio solo si mejora el SLO bajo carga comparable y no deteriora corrección ni coste por operación.

## ⚠️ Errores frecuentes

- «Los monolitos no escalan». Se replican horizontalmente si no guardan sesión en memoria y se escalan verticalmente; el límite suele estar en la base o en otro recurso compartido, igual que con servicios.
- «Extraer el módulo caliente resuelve el cuello». Si sigue usando la misma consulta y la misma base, añade una llamada de red delante del mismo cuello.
- «Más réplicas, más capacidad». Cada réplica abre su pool; contra una base saturada, más réplicas son más esperas y más rechazos de conexión.
- «Una caché acelera cualquier lectura». Sin dueño, clave, TTL e invalidación sirve datos viejos, y para decidir una reserva rompe la invariante.
- «La afinidad de sesión resuelve el estado por réplica». Lo esconde: desequilibra la carga y pierde las sesiones cuando cae la réplica.

## 7. ✅ Veredicto

Mide antes de mover nada: traza por etapa para saber dónde espera la petición, perfil del proceso
solo si la traza lo señala, y un cambio por experimento bajo la misma carga. Escala la aplicación
cuando el cómputo es el límite; optimiza la consulta, el pool o el tiempo de uso cuando lo es la
base; cachea lecturas que toleren obsolescencia. Extraer un módulo responde a un recurso que puede
separarse, no a un módulo que aparece mucho en las trazas.

## 📚 Referencias

- [Java Flight Recorder](https://docs.oracle.com/en/java/javase/25/jfapi/)
- [Node.js Diagnostics](https://nodejs.org/learn/getting-started/profiling)
- [Go Diagnostics](https://go.dev/doc/diagnostics)
- [Python Profilers](https://docs.python.org/3/library/profile.html)

## 🧠 Preguntas

1. 🟢 ¿Qué diferencia hay entre latencia, throughput y saturación?
2. 🟢 ¿Por qué el SLO de checkout se mide en el borde del usuario y no por módulo?
3. 🟢 ¿Qué indica una CPU baja con latencia alta?
4. 🟢 ¿Qué necesita una caché para no servir datos equivocados?
5. 🟢 ¿Qué hace falta para que un monolito pueda replicarse horizontalmente?
6. 🟢 ¿Qué relación hay entre throughput, tiempo de uso de una conexión y tamaño del pool?
7. 🟡 ¿Por qué extraer `inventory` sin medir la dependencia es una simplificación peligrosa?
8. 🟡 ¿Cuándo preferirías escalar verticalmente antes que añadir réplicas?
9. 🟡 Al pasar de 4 a 8 réplicas, el p99 empeora. ¿Qué explicación comprobarías primero?
10. 🟡 ¿Por qué cachear el stock para decidir una reserva rompe la invariante y cachear el catálogo no?
11. 🟡 ¿Qué es un read model y qué precio tiene frente a optimizar la consulta original?
12. 🟡 ¿Cuándo es aceptable la afinidad de sesión y cuándo se vuelve un problema?
13. 🟡 ¿Qué cambias en un experimento de rendimiento y qué mantienes fijo?
14. 🟡 ¿Qué te dice un percentil alto que el promedio esconde?
15. 🟡 ¿Cómo afecta un proceso de reportes pesado al rendimiento de checkout dentro del mismo monolito?
16. 🟡 ¿Qué coste por operación vigilarías además de la latencia?
17. 🟡 ¿Qué señales compararías entre JFR en Java y `pprof` en Go antes de atribuir el cuello a CPU?
18. 🟠 ¿Cómo distingues event loop bloqueado en Node de saturación de workers o de base en Python?
19. 🟠 Negocio pide soportar el triple de tráfico en la campaña de diciembre. ¿Cómo planificarías la capacidad sin adivinar?
20. 🟠 Una caché de catálogo con TTL de 10 minutos muestra precios viejos tras una rebaja. ¿Qué harías hoy y qué cambiarías?
21. 🟠 Tras un despliegue, el heap crece hasta el OOM cada seis horas y reinicia todo el monolito. ¿Qué harías primero?
22. 🟠 Quieres mover la sesión de memoria local a una caché compartida. ¿Cómo lo harías de forma reversible?
23. 🟠 Un equipo quiere extraer `inventory` y otro prefiere un índice y un read model. ¿Cómo decidirías?
24. 🟠 ¿Qué criterio te diría que el monolito ya no puede escalar como una sola unidad?

---

[Índice del bloque](README.md) · [Índice general](../README.md)

**Anterior:** [03 — Eventos internos, jobs y procesamiento asíncrono](03-eventos-internos-jobs-y-procesamiento-asincrono.md).

**Siguiente:** [05 — Despliegues, migraciones de esquema y rollback](05-despliegues-migraciones-de-esquema-y-rollback.md).
