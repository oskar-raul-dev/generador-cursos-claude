# 04 — Extraer un módulo a servicio

Aprenderás a comprobar qué autonomía compra una extracción antes de hacerla, a transferir la
autoridad sobre los datos sin perder ni duplicar operaciones, y a cancelarla si deja de compensar.
Una API interna limpia es buena preparación; no elimina la nueva semántica de red.

## 1. 🎯 Síntoma y decisión

El equipo de `payments` pide su propio despliegue. Sus razones: el proveedor de pagos publica cambios
de API cada mes y cada adaptación espera el release semanal del monolito; el auditor ha confirmado
que los datos de pago deben vivir en un entorno con credenciales y despliegue separados; y un
incidente de memoria en reportes tumbó los cobros durante veinte minutos en la última campaña.
`payments` ya es un módulo con API interna, dueño de sus tablas y una regla en CI que lo protege.

Esta vez la extracción tiene razones medidas y una restricción confirmada. La decisión de este
capítulo es cómo hacerla sin perder operaciones, qué criterios la cancelan y cuándo se da por
terminada.

## 2. 🧠 Modelo mental

Extraer no es mover código: es **transferir autoridad**. El orden importa porque, mientras dos
lugares pueden escribir el mismo efecto, no hay una verdad.

```text
API local estable → fachada seleccionable → contrato remoto compatible
  → copia inicial + cambios capturados → validar convergencia
  → detener escritor viejo + drenar → aplicar cambios finales
  → activar escritor nuevo → observar → retirar el camino antiguo
```

`orders` conserva el estado del pedido y las referencias de pago; `inventory`, las reservas;
`notifications`, las entregas. `payments` adquiere autoridad exclusiva sobre intentos, claves y
autorizaciones. La garantía local pedido-reserva puede continuar, pero el resultado del pago ya
exige [estado incierto y reconciliación](../04-monolito-distribuido/05-fallos-parciales-retries-y-falsas-transacciones.md)
entre dos procesos. El contrato remoto declara plazo, errores, identidad, consulta y versiones
soportadas.

## 3. 🔍 Evidencia antes del diagnóstico

| Nivel | En el sistema de comercio |
|---|---|
| Observación | cada adaptación al proveedor espera de media cuatro días por el release común; el auditor exige un entorno separado para los datos de pago; un incidente de memoria en reportes interrumpió los cobros veinte minutos; `payments` ya tiene API interna, dueño de tablas y regla en CI |
| Inferencia | la cadencia, el aislamiento regulatorio y el aislamiento de fallos son razones reales para otra unidad de despliegue; la preparación interna ya existe |
| Diagnóstico | extracción justificada de `payments`, con riesgo concentrado en la transferencia de datos y en el nuevo resultado incierto entre procesos |
| Recomendación | extraer con fachada seleccionable, copia inicial más captura de cambios, corte con drenaje, capa anticorrupción en `orders` y criterios de cancelación acordados antes de empezar |

Las cifras son supuestos del ejercicio. Qué refutaría la recomendación: si la espera de cuatro días
viniera de aprobaciones comunes y no del release, un pipeline propio para el módulo la resolvería
sin extraer; si el incidente de memoria se contiene con cupos de recursos en el proceso, ese motivo
desaparece. La restricción del auditor, en cambio, se sostiene sola. La
[matriz](01-monolito-monolito-modular-o-servicios-matriz-de-decision.md) es el lugar donde se contrastan.

## 4. 🛠️ Contrato, traducción y datos

**Capa anticorrupción entre el modelo que sale y el que queda.** Una vez fuera, el modelo de
`payments` evoluciona por su cuenta. Si adopta el vocabulario de su proveedor —«requiere captura»,
«completado»— y `orders` consume ese contrato tal cual, el primer cambio del servicio nuevo se
propaga al monolito. La capa anticorrupción, el patrón que Eric Evans describe en *Domain-Driven
Design*, es el traductor que evita ese contagio: vive del lado del consumidor, convierte el modelo
ajeno al propio y es el único que conoce ambos.

```text
orders (queda en el monolito)                    payments (servicio extraído)
PaymentResult: AUTHORIZED | REJECTED | PENDING   contrato remoto v1
        ▲
        └── ACL de orders: traduce estados, errores y plazos del contrato remoto

payments durante la migración
modelo nuevo ◄── ACL de payments ◄── tablas legadas del monolito (status = 3, flags sueltos)
```

- En `orders`, la ACL traduce el contrato remoto a `PaymentResult`, que es lo que las reglas de pedido
  entienden. Un cambio de vocabulario en `payments` toca un traductor, no las reglas.
- Mientras `payments` todavía lee datos del monolito, su propia ACL traduce la semántica legada
  —códigos numéricos, columnas con varios significados— para que el modelo nuevo no nazca con los
  defectos del viejo.
- **Qué cuesta:** código de mapeo, pruebas de traducción con casos reales y conceptos que existen dos
  veces. Si los dos modelos son el mismo y estables, la ACL es ceremonia.

**Datos y punto de corte.** Se inventarían lectores, escritores, jobs y reparaciones manuales. La
captura de cambios empieza en un punto consistente con la copia inicial y aplica identificadores y
orden por entidad para no perder ni duplicar. Se comparan conteos, claves, importes y estados, no solo
el número de filas. Si no se puede probar una captura sin huecos, una pausa de escritura acordada
para copiar y verificar puede ser más segura.

**Nunca dos escritores.** Dos escrituras independientes no son una estrategia de migración: una puede
confirmar y la otra fallar. Una transición que replica tiene una autoridad, un registro durable de
cambios, deduplicación, orden y reconciliación, con duración y salida documentadas. En el corte se
bloquean comandos nuevos en el escritor viejo, se drenan los admitidos, se aplica el último tramo y se
verifica el punto de avance; después se habilita el nuevo y se cambia la ruta. El viejo queda de solo
lectura y no acepta reintentos tardíos.

**Sombra, rollback y cancelación.** El *shadow traffic* replica consultas o cálculos sin efectos
para contrastar respuestas; no duplica autorizaciones reales. Antes del corte, rollback es desactivar
el destino y seguir con el escritor original; después, exige llevar al origen las operaciones nuevas,
y si eso no se ensayó, lo honesto es declarar recuperación hacia adelante y una pausa segura. Los
criterios se acuerdan antes de empezar: ningún efecto duplicado, toda divergencia monetaria explicada,
p95 dentro del SLO de compra, espera de release reducida en una muestra representativa y una guardia
capaz de reconciliar sin otro equipo. Una divergencia sin explicación suspende el corte; si la
alternativa local satisface el objetivo o falta capacidad para operar el nuevo límite, se cancela.

## 5. 🧰 Plataformas

| Plataforma | Mecanismo relevante | Qué no resuelve | Trampa frecuente |
|---|---|---|---|
| Java | artefacto propio, DTO remoto y migración de esquema compatible | deshacer una autorización externa | reutilizar las entidades del monolito en el servicio nuevo |
| Node/TypeScript | build del servicio y validación del payload en runtime | la coherencia de dos escrituras | compartir tipos entre ejecutables y omitir el contrato real |
| Go | binario propio y deadline explícito en el cliente | recuperar una operación al cancelar el contexto | reintentar con una clave nueva |
| Python | entorno reproducible y worker de reconciliación | la durabilidad de tareas en memoria | extraer solo el endpoint y dejar los datos en el monolito |

Las cuatro trampas dejan la extracción a medias: compartir entidades o tipos mantiene el acoplamiento
de código, una clave nueva por reintento duplica cobros y un endpoint sin sus datos crea un servicio
que sigue escribiendo en la base del monolito. Los [despliegues compatibles](../03-datos-ejecucion-y-operacion/05-despliegues-migraciones-de-esquema-y-rollback.md)
y los [contratos](../04-monolito-distribuido/04-contratos-fragiles-y-despliegues-coordinados.md) del
curso se aplican tal cual; ningún framework sustituye el ensayo del corte, y las versiones reales de
base, build y transporte se verifican antes de implementar.

## 6. ⚖️ Decisión y coste

Conservas autoridad única y trazabilidad mientras ganas cadencia, aislamiento regulatorio y de
fallos propios. Pagas red, observabilidad distribuida, compatibilidad, almacenamiento transitorio,
una capa de traducción y una guardia más. El indicador final no es el despliegue del servicio, sino
autonomía en cambios reales con el SLO de compra estable. Detente al obtenerla: extraer los otros
módulos no es una consecuencia necesaria, y cada uno necesita sus propias razones.

## ⚠️ Errores frecuentes

- «Cambiar la llamada local por HTTP es extraer». Sin transferir datos y autoridad, es un monolito
  distribuido con un salto de red más.
- «Probamos el servicio nuevo duplicando cobros reales». La sombra solo replica lecturas; los efectos
  no se duplican nunca.
- «Tras el corte, se revierte cambiando el router». Las operaciones escritas en el destino tienen que
  volver al origen, o se pierden.
- «El servicio tiene su base, así que es autónomo». Si otros siguen escribiendo en ella o aprobando
  sus cambios, tiene una base propia y ninguna autonomía.
- «`orders` puede consumir el modelo de `payments` tal cual». Su primer cambio de vocabulario se
  propaga al monolito; la traducción va en una capa anticorrupción.

## 7. ✅ Veredicto

Extrae cuando una restricción o una necesidad medida lo exige y la preparación interna ya existe.
Transfiere la autoridad con un solo escritor en cada momento, copia y captura verificadas, corte con
drenaje y traducción en el consumidor. Acuerda antes de empezar qué te haría cancelar. La extracción
termina cuando la capacidad cambia y se recupera bajo su dueño; mover el código es la parte pequeña de
esa prueba.

## 📚 Referencias

- [Strangler Fig, Martin Fowler](https://martinfowler.com/bliki/StranglerFigApplication.html)
- [Anti-corruption layer pattern, AWS Prescriptive Guidance](https://docs.aws.amazon.com/prescriptive-guidance/latest/cloud-design-patterns/acl.html)
- [Transactional outbox pattern, AWS Prescriptive Guidance](https://docs.aws.amazon.com/prescriptive-guidance/latest/cloud-design-patterns/transactional-outbox.html)
- [Database-per-service pattern, AWS Prescriptive Guidance](https://docs.aws.amazon.com/prescriptive-guidance/latest/modernization-data-persistence/database-per-service.html)

## 🧠 Preguntas

1. 🟢 ¿Qué debe comprar una extracción para que merezca la pena?
2. 🟢 ¿Qué permanece en `orders` al extraer `payments`?
3. 🟢 ¿Qué añade un contrato remoto a una API local?
4. 🟢 ¿Qué significa tener un solo escritor durante la migración?
5. 🟢 ¿Qué tráfico admite la prueba en sombra?
6. 🟡 ¿Por qué copiar las filas no basta para migrar los datos?
7. 🟡 ¿Cómo eliges entre captura continua de cambios y una pausa de escritura?
8. 🟡 ¿Qué falla si la migración usa dos escrituras independientes?
9. 🟡 ¿Qué verificas además del número de filas?
10. 🟡 ¿Cómo se corta el escritor anterior sin perder operaciones?
11. 🟡 ¿Qué haces con un reintento tardío que llega al origen después del corte?
12. 🟡 ¿Cómo cambia el rollback antes y después del corte?
13. 🟡 ¿Qué medirías en el canary del servicio nuevo?
14. 🟡 ¿Qué te haría cancelar la extracción antes del corte?
15. 🟡 ¿Qué revela un servicio con base propia en el que otros equipos siguen escribiendo?
16. 🟡 ¿Cuándo declararías terminada la extracción?
17. 🟡 ¿Qué riesgo comparten reutilizar DTO en Java y compartir tipos en TypeScript entre el monolito y el servicio?
18. 🟠 ¿En qué se diferencian un deadline en Go y un worker de reconciliación en Python ante un resultado incierto?
19. 🟠 El servicio nuevo cobra correctamente, pero no consigue notificar a `orders`. ¿Qué haces?
20. 🟠 Durante la copia aparece una divergencia monetaria. ¿Cómo la recuperas?
21. 🟠 ¿Puedes volver al origen si el esquema del destino ya cambió?
22. 🟠 Descubres que los dos escritores estuvieron activos por error durante una hora. ¿Qué haces?
23. 🟠 ¿Cómo decides si el equipo puede sostener la guardia del servicio nuevo?
24. 🟠 ¿Por qué no extraer enseguida los otros módulos, si esta extracción salió bien?
25. 🟠 Tras la extracción, `payments` quiere cambiar sus estados al vocabulario de su proveedor. ¿Dónde pondrías la traducción para que `orders` no cambie, y qué te costaría?

---

[Índice del bloque](README.md) · [Índice general](../README.md)

**Anterior:** [03 — Recuperar modularidad en un monolito legado](03-recuperar-modularidad-en-un-monolito-legado.md).

**Siguiente:** [05 — Equipos, ownership y gobernanza evolutiva](05-equipos-ownership-y-gobernanza-evolutiva.md).
