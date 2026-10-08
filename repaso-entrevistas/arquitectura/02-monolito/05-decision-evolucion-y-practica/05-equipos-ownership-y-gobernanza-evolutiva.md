# 05 — Equipos, ownership y gobernanza evolutiva

Aprenderás a asignar decisiones y operación a equipos capaces de sostenerlas, y a gobernar las
excepciones sin convertir la gobernanza en una cola de aprobaciones. Un equipo por servicio no
garantiza autonomía si otros controlan sus datos, sus contratos o sus releases.

## 1. 🎯 Síntoma y decisión

Tras extraer `payments`, la organización tiene cinco equipos y un comité de arquitectura. Un cambio
compatible en la política de reintentos de `payments` esperó tres aprobaciones y once días. Nadie
atiende de noche los pagos pendientes: la guardia rota entre todos los equipos y quien la tiene esa
semana no conoce el reconciliador. Y un informe financiero lleva dos años escribiendo directamente en
una tabla de `inventory` con una «excepción temporal» que se renueva sola cada trimestre.

La autoridad está en el comité, la operación en nadie y las excepciones en ningún registro. La
decisión de este capítulo es quién decide, cambia y recupera cada capacidad, qué controles protegen
de verdad una garantía y cuáles solo añaden espera.

## 2. 🧠 Modelo mental

Una frontera es sostenible cuando la misma unidad organizativa puede **decidir**, **cambiar** y
**recuperar** lo que contiene. Si una de las tres está en otro sitio, la frontera técnica existe y la
autonomía no.

```text
propuesta de cambio de API → dueño de la capacidad + consumidores afectados
  → ejemplos de compatibilidad → decisión registrada
  → CI verifica el contrato → despliegue por el dueño → revisión con evidencia
```

La gobernanza útil distingue **consulta** de **aprobación**: consultar a quien sabe o a quien se
afecta es barato y mejora la decisión; exigir su firma para cada cambio compatible convierte a otro
equipo en dueño de hecho. Los controles automatizados sustituyen a las aprobaciones donde la regla es
verificable, y las personas se reservan para lo que no lo es.

## 3. 🔍 Evidencia antes del diagnóstico

| Nivel | En el sistema de comercio |
|---|---|
| Observación | un cambio compatible de `payments` esperó tres aprobaciones y once días; la guardia de pagos rota entre cinco equipos y los pendientes nocturnos se atienden al día siguiente; el informe financiero escribe en `inventory` con una excepción renovada ocho veces; los cambios semánticos de contrato no tienen revisión con consumidores |
| Inferencia | la autoridad de cambio está en el comité y no en el dueño; la operación de pagos no tiene dueño; las excepciones no caducan |
| Diagnóstico | responsabilidad fragmentada: la frontera técnica de `payments` existe, la organizativa no |
| Recomendación | matriz de autoridad por capacidad, cambios compatibles sin aprobación global y con consulta a consumidores en los semánticos, guardia de pagos en su equipo, y excepciones con dueño, motivo y caducidad real |

Las cifras son supuestos del ejercicio. Qué refutaría el diagnóstico: si las aprobaciones
existieran por un requisito regulatorio concreto —segregación de funciones sobre cambios de pago—, no
serían burocracia sino un control, y la mejora sería automatizarlo, no quitarlo. Y si la guardia
compartida resolviera los incidentes a tiempo, el problema de operación no existiría. Una consulta
ocasional a especialistas es útil y no equivale a una dependencia permanente.

## 4. 🛠️ Autoridad, controles y excepciones

**Matriz de autoridad.** Cada decisión tiene un responsable que decide y una evidencia que la
controla:

| Decisión | Responsable que decide | Evidencia y control |
|---|---|---|
| Estado comercial del pedido | equipo de pedidos | casos de negocio y pruebas del flujo |
| Reserva y vencimiento | equipo de inventario | invariantes, accesos de escritura y alertas |
| Reconciliación y contrato de pago | equipo de pagos | pendientes, versiones soportadas y runbook |
| Entrega de avisos | equipo de notificaciones | edad del trabajo y fallos de canal |
| Pipeline y telemetría comunes | plataforma como proveedor interno | autoservicio y tiempo de recuperación |

Son roles del ejercicio, no cinco equipos obligatorios: un equipo pequeño puede asumir varios, pero
cada decisión y cada guardia deben tener cobertura. El equipo de plataforma ofrece capacidades
comunes que reducen carga cognitiva —el esfuerzo de entender dominio, herramientas y operación para
entregar—; no aprueba reglas de negocio, y su producto se evalúa por uso y por la espera que ahorra.

**Controles proporcionales.** Cada riesgo tiene un control social y, donde se puede, uno automatizado
que lo sustituye:

| Riesgo | Control social | Control automatizado |
|---|---|---|
| escrituras ajenas | acuerdo con el dueño | permisos de base y pruebas de acceso |
| API incompatible | revisión con los consumidores afectados | fixtures y contratos de las versiones soportadas |
| ciclos entre módulos | revisión de la razón de cambio | reglas de dependencias en CI |
| recuperación sin dueño | guardia y ensayo del runbook | alertas de pendientes y auditoría |

**Excepciones con caducidad real.** Una excepción de lectura —un informe que consulta una vista de
`inventory`— puede ser válida si registra motivo, acceso de solo lectura, consumidores, frescura,
dueño y fecha de revisión. Una de escritura es más cara: exige proteger las invariantes y un plan para
devolver la autoridad. Al vencer, no se renueva sola: se revisa si el motivo sigue y cuánto cuesta.

**Conway como restricción.** Las formas de comunicación influyen en el diseño, y
[cómo se llega a un monolito distribuido](../04-monolito-distribuido/07-como-se-llega-granularidad-entidades-y-plataforma-compartida.md)
muestra esa fuerza actuando en los dos sentidos. No es una receta para crear un equipo por tabla: si
una capacidad requiere coordinación continua entre dos equipos, se evalúa una colaboración temporal,
redefinir la autoridad o fusionar la responsabilidad, antes de presuponer otro servicio.

## 5. 🧰 Plataformas

No aplica código comparativo. Los controles técnicos se implementan con las
[herramientas del bloque 02](../02-modularidad-y-limites-internos/06-codigo-compartido-shared-kernel-y-controles-arquitectonicos.md)
en cualquiera de las cuatro plataformas —reglas de dependencias, permisos de base, pruebas de
contrato—; la autoridad, la guardia y la política de compatibilidad son acuerdos que ningún lenguaje
decide. Una herramienta hace cumplir una responsabilidad; no la asigna.

## 6. ⚖️ Decisión y coste

Asigna cada decisión y cada guardia a un equipo capaz de sostenerla, sustituye aprobaciones por
controles automatizados donde la regla es verificable y deja la revisión humana para los cambios
semánticos. Pagas acuerdos explícitos, capacidad de guardia por equipo y mantenimiento de controles;
compras cambios sin espera y recuperación con dueño. Mide separando tiempo de trabajo y tiempo de
espera, releases coordinados por obligación, fallos de cambio, recuperación y carga de guardia, sin
usar esas métricas para clasificar personas. Si un equipo no puede operar su límite, reduce el
alcance, ofrece soporte temporal o reconsidera la topología.

## ⚠️ Errores frecuentes

- «Un equipo por servicio garantiza autonomía». Si otro equipo aprueba sus cambios, escribe en sus
  tablas o hace su guardia, la autonomía es nominal.
- «Más aprobaciones, más gobernanza». Las aprobaciones sobre cambios verificables son espera; la
  gobernanza útil automatiza lo verificable y revisa lo semántico.
- «La guardia compartida entre todos es más justa». Quien no conoce el reconciliador no puede
  recuperar un pago pendiente a las tres de la mañana.
- «Una excepción temporal se renueva si nadie se queja». Sin revisión al vencer, la excepción se
  vuelve la arquitectura real.
- «Reorganizar equipos arregla un contrato incompatible». El organigrama cambia quién decide; el
  contrato sigue necesitando compatibilidad y retirada gobernada.

## 7. ✅ Veredicto

Una frontera es sostenible cuando alguien puede decidir, cambiar y recuperar lo que contiene. Da a
cada capacidad un dueño con autoridad y guardia, sustituye aprobaciones por controles donde la regla
es verificable, consulta a los consumidores en los cambios semánticos y haz que las excepciones
caduquen de verdad. Conserva la coordinación que protege una garantía y retira la que no protege
ninguna.

## 📚 Referencias

- [Key Concepts, Team Topologies](https://teamtopologies.com/key-concepts-content)
- [Conway's Law, Martin Fowler](https://martinfowler.com/bliki/ConwaysLaw.html)
- [Consumer-Driven Contracts: A Service Evolution Pattern, Ian Robinson](https://martinfowler.com/articles/consumerDrivenContracts.html)

## 🧠 Preguntas

1. 🟢 ¿Qué significa ownership efectivo de una capacidad?
2. 🟢 ¿Qué es la carga cognitiva de un equipo en este contexto?
3. 🟢 ¿Qué debe ofrecer un equipo de plataforma y qué no debe hacer?
4. 🟢 ¿Qué datos mínimos exige una excepción arquitectónica?
5. 🟢 ¿Qué distingue una consulta de una aprobación obligatoria?
6. 🟡 ¿Por qué un equipo por servicio puede no tener autonomía?
7. 🟡 ¿Cómo aplicas la ley de Conway sin copiar el organigrama en el código?
8. 🟡 ¿Qué responsabilidad mantiene plataforma sobre la operación de `payments`?
9. 🟡 ¿Cómo revisarías un cambio de API interna sin convertirlo en una aprobación global?
10. 🟡 ¿Qué diferencia una excepción de lectura de una de escritura?
11. 🟡 ¿Qué métricas de entrega usarías para saber si la gobernanza ayuda o estorba?
12. 🟡 ¿Cómo atiendes una capacidad que no tiene una guardia sostenible?
13. 🟡 ¿Cuándo aceptarías ownership compartido de una capacidad?
14. 🟡 ¿Cómo retiras una aprobación que no aporta ninguna garantía?
15. 🟡 ¿Qué evidencia pedirías antes de reorganizar equipos?
16. 🟡 ¿Cómo evalúas si la plataforma interna está funcionando?
17. 🟠 Dos equipos reclaman la misma tabla. ¿Qué haces?
18. 🟠 La excepción del informe financiero venció y sigue escribiendo en producción. ¿Cómo la gestionas?
19. 🟠 Tras dar autonomía a `payments`, mejora la entrega pero empeora la guardia. ¿Qué haces?
20. 🟠 ¿Cómo responderías a quien exige que cada equipo tenga su propio servicio?
21. 🟠 ¿Qué control conserva la autonomía de `payments` sin eliminar toda revisión?
22. 🟠 Una urgencia de producción cruza el ownership de dos equipos. ¿Cómo la resuelves?
23. 🟠 ¿Cuándo fusionarías la responsabilidad de dos equipos?
24. 🟠 ¿Qué demuestra que la gobernanza es suficiente y no hay que añadir más controles?

---

[Índice del bloque](README.md) · [Índice general](../README.md)

**Anterior:** [04 — Extraer un módulo a servicio](04-extraer-un-modulo-a-servicio.md).

**Siguiente:** [06 — Caso completo de system design y estrategia evolutiva](06-caso-completo-de-system-design-y-estrategia-evolutiva.md).
