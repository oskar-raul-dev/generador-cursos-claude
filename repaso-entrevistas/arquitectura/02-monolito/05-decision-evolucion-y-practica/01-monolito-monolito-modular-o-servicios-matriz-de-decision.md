# 01 — Monolito, monolito modular o servicios: matriz de decisión

Aprenderás a recomendar una topología con supuestos explícitos y condiciones para revisarla: qué
restricciones descartan opciones, cuáles solo las ordenan y cómo se registra la decisión para que se
pueda reabrir con evidencia y no con cansancio.

## 1. 🎯 Síntoma y decisión

La dirección pide una recomendación para la plataforma de comercio y llega con la respuesta puesta:
«microservicios, porque esperamos un millón de usuarios». Los datos que hay son otros. Doce personas
en dos equipos; un pico medido de 40 compras por segundo en la última campaña; `CreateOrder` necesita
confirmar pedido y reserva juntos; `notifications` satura la CPU durante las campañas y ralentiza
checkout; y un auditor ha pedido separar el acceso a los datos de pago, sin decir todavía qué control
exige.

Hay una preferencia —servicios—, una cifra que no es una carga —usuarios registrados— y varias
restricciones reales mezcladas. La decisión de este capítulo es qué topología recomendar con esos
datos, qué evidencia falta y qué la haría cambiar.

## 2. 🧠 Modelo mental

Una matriz de decisión no suma puntos: primero **filtra** con las restricciones duras y después
**ordena** lo que queda por coste. Una opción que incumple una restricción no negociable queda fuera
aunque gane en todo lo demás.

```text
opciones: monolito simple · monolito modular · servicios · híbridos
   │
   ├─ filtro: restricciones duras (invariante atómica, control regulatorio exigido, SLO)
   │     └─ ¿qué opciones las cumplen?
   │
   ├─ orden: coste total (operación, cambio, equipos) de las que pasan el filtro
   │
   └─ registro: supuestos, evidencia que falta, fecha y señal de revisión
```

Una restricción invalida una solución que no la cumple; una preferencia solo la hace menos atractiva.
«Usamos Kotlin» o «queremos microservicios» son preferencias; «pedido y reserva se confirman juntos»
o «el auditor exige un control concreto sobre los datos de pago» son restricciones, si su dueño las
confirma.

## 3. 🔍 Evidencia antes del diagnóstico

| Nivel | En el sistema de comercio |
|---|---|
| Observación | 40 compras/s de pico medido; dos equipos que cambian `orders`/`inventory` y `payments`; invariante pedido-reserva confirmada por negocio; CPU saturada por `notifications` solo en campañas; petición de auditoría sin control especificado |
| Inferencia | la carga cabe en réplicas de un artefacto; la invariante pide una transacción local; el problema de CPU es un recurso aislable; la cadencia de `payments` podría divergir |
| Diagnóstico | ninguna restricción confirmada exige servicios hoy; el cuello de `notifications` y la auditoría piden medidas acotadas |
| Recomendación | monolito modular, `notifications` como worker con recursos propios del mismo artefacto, y revisión con fecha cuando se conozca el control de auditoría y la cadencia real de `payments` |

Las cifras son supuestos del ejercicio. Qué refutaría la recomendación: si el auditor exige que los
datos de pago vivan en un entorno aislado con credenciales y despliegue propios, `payments` pasa a
tener una razón dura para ser otra unidad; si el equipo de `payments` necesita desplegar a diario y el
release común lo bloquea de forma medida, la cadencia también la da. Las
[cinco unidades](../01-fundamentos-y-modelo-mental/02-unidades-de-codigo-despliegue-ejecucion-y-datos.md)
y el [perfilado de recursos](../03-datos-ejecucion-y-operacion/04-rendimiento-cache-y-escalado.md)
son las herramientas para obtener esa evidencia.

## 4. 🛠️ Matriz, contraste y registro

**La matriz, fila por fila.** Cada restricción apunta a una opción inicial defendible, a su coste y a
la señal que obligaría a revisarla:

| Restricción | Opción inicial defendible | Coste y señal de revisión |
|---|---|---|
| Dominio incierto y un equipo | monolito simple con fronteras básicas | reordenar código si cambian las capacidades |
| Reglas estables y cambios locales frecuentes | monolito modular | controles de límites; revisar coordinación de releases |
| Invariante que exige commit único | mantener juntos los recursos participantes | menos libertad de separación; revisar el requisito con su dueño |
| Carga aislable y cuello medido | optimizar, aislar recursos o extraer esa capacidad | nueva operación solo si supera a la opción local |
| Equipos con cadencias realmente distintas | módulos primero; servicios si necesitan releases propios | compatibilidad y guardia por servicio |
| Aislamiento contractual o regulatorio confirmado | frontera que cumpla el control exigido | coste de identidad, datos y auditoría |
| Disponibilidad con tolerancia a datos atrasados | proyección o cola durable | frescura, backlog y reconciliación |

**Dos decisiones con la misma plataforma.** Lo que cambia la recomendación es la restricción, no la
moda:

```text
misma plataforma de comercio
   ├─ demanda uniforme + equipos que comparten release → un despliegue, límites internos
   └─ notifications satura CPU en campaña → worker del mismo artefacto con recursos propios
                                             └─ extraer solo si la medición mejora y lo justifica
```

En el primer caso, `orders` reserva mediante `inventory`, registra la intención para `payments` y
deriva los avisos a trabajo durable; el commit local conserva pedido y reserva, y el pago externo
sigue siendo incierto hasta confirmarlo. En el segundo, un worker separado puede escalar sin adquirir
propiedad independiente de reglas y datos; si el cuello real estuviera en una consulta compartida,
trasladar CPU no lo arreglaría.

**La decisión, registrada.** Una recomendación que no dice qué la haría cambiar es una apuesta:

| Campo | Decisión |
|---|---|
| Hipótesis | el despliegue común aún cumple cadencia y disponibilidad |
| Elección | monolito modular; `notifications` como worker; pago externo mediante estado durable |
| Evidencia que falta | control exacto de la auditoría, perfil de pico de la próxima campaña y espera real de `payments` por el release común |
| Experimento | medir veinte cambios y una prueba de pico representativa |
| Revisión | fecha acordada con el responsable técnico de `orders` y producto |
| Señal de reapertura | control regulatorio que exija aislamiento físico, coordinación obligatoria recurrente o SLO incumplido por un recurso aislable |

Una *fitness function* es aquí una comprobación repetible de una propiedad que se quiere conservar:
impedir escrituras ajenas, detectar ciclos o medir la cola máxima. No prueba toda la arquitectura,
pero convierte parte de la decisión en algo que la CI vigila. Y conviene separar lo reversible —una
fachada, un worker— de lo que no lo es tanto —copiar datos a una nueva autoridad, publicar un
contrato externo, asumir una guardia permanente—.

## 5. 🧰 Plataformas

No aplica código comparativo: la decisión depende de invariantes, recursos, equipos y controles, y
cualquiera de las cuatro plataformas puede implementar cualquiera de las opciones. El lenguaje cambia
costes medidos —memoria por proceso, tiempo de arranque, talento disponible—, no la obligación de
elegir una topología. Los mecanismos concretos para hacer cumplir los límites están en el
[bloque 02](../02-modularidad-y-limites-internos/06-codigo-compartido-shared-kernel-y-controles-arquitectonicos.md),
y los de operación, en el bloque 03.

## 6. ⚖️ Decisión y coste

Recomienda la opción de menor coste total que cumpla las restricciones confirmadas, y dile al
interlocutor qué evidencia falta y cuándo se revisa. Un monolito modular paga disciplina de límites y
despliegue común; servicios pagan red, contratos, datos repartidos y guardias; un worker separado paga
un proceso más sin nuevos contratos. Si la presión por «modernizar» no trae una restricción, no es un
argumento: pide la cifra o el control que la respalda.

## ⚠️ Errores frecuentes

- «Esperamos un millón de usuarios, así que microservicios». Los usuarios registrados no son carga;
  importan el pico de operaciones, su distribución y el recurso que limita.
- «La opción con más puntos gana». Una restricción no negociable descarta una opción por muchos puntos
  que sume en escalabilidad o moda.
- «El monolito modular es una fase obligatoria antes de distribuir». Es una opción con su propio
  coste; con restricciones claras de aislamiento, servicios desde el inicio pueden ser correctos.
- «Regulación implica un servicio por módulo». Implica el control que el regulador exige; a veces es
  un permiso, un cifrado o un entorno, no una topología.
- «La decisión es reversible porque existe un botón de rollback». Copiar datos a otra autoridad o
  publicar un contrato externo no se deshace con un despliegue.

## 7. ✅ Veredicto

Filtra con restricciones confirmadas por sus dueños, ordena por coste lo que queda y registra la
decisión con sus supuestos, la evidencia que falta y la señal que la reabriría. Si no puedes explicar
qué garantía o qué autonomía compra cada frontera, todavía no tienes razón suficiente para
introducirla; y si una restricción real la exige, no la retrases por preferencia hacia lo local.

## 📚 Referencias

- [Monolith First, Martin Fowler](https://martinfowler.com/bliki/MonolithFirst.html)
- [Microservice Premium, Martin Fowler](https://martinfowler.com/bliki/MicroservicePremium.html)
- [Microservice Trade-Offs, Martin Fowler](https://martinfowler.com/articles/microservice-trade-offs.html)

## 🧠 Preguntas

1. 🟢 ¿Para qué sirve una matriz de decisión y por qué no suma puntos?
2. 🟢 ¿Qué distingue una restricción de una preferencia?
3. 🟢 ¿Qué dato de carga pedirías primero, en lugar de usuarios registrados?
4. 🟢 ¿Qué aporta un monolito modular a la decisión frente a un monolito simple?
5. 🟢 ¿Qué es una *fitness function* en este contexto?
6. 🟡 ¿Por qué una media de carga resulta insuficiente para decidir?
7. 🟡 ¿Cuándo mantendrías una invariante dentro de una transacción local aunque haya presión por separar?
8. 🟡 ¿Cómo cambia la decisión si dos equipos necesitan cadencias realmente distintas?
9. 🟡 ¿Qué evidencia demostraría una necesidad real de aislamiento para `payments`?
10. 🟡 ¿Por qué no recomendarías servicios por la cifra de un millón de usuarios?
11. 🟡 ¿Qué movimientos son reversibles y cuáles no, al cambiar de topología?
12. 🟡 ¿Cuándo extraerías `notifications` a un servicio, y cuándo basta con un worker?
13. 🟡 ¿Cómo afecta la frescura de datos permitida a la topología?
14. 🟡 ¿Qué debe incluir el registro de una decisión para que se pueda revisar?
15. 🟡 ¿Qué diferencia hay entre un worker separado y un servicio autónomo?
16. 🟡 ¿Qué alternativa considerarías antes de separar una base caliente?
17. 🟠 ¿Aceptarías más latencia para ganar aislamiento? ¿Bajo qué condiciones?
18. 🟠 Dos requisitos confirmados son incompatibles entre sí. ¿Qué haces?
19. 🟠 ¿Cómo defenderías mantener el monolito ante una dirección que quiere «modernizar»?
20. 🟠 ¿Qué invalidaría la matriz que construiste con supuestos?
21. 🟠 La opción más barata incumple el SLO de disponibilidad. ¿Qué haces?
22. 🟠 Tienes que recomendar con una fecha de entrega cercana y sin mediciones. ¿Cómo decides?
23. 🟠 ¿Qué te haría cancelar una extracción que ya se había explorado?
24. 🟠 ¿Cuándo dejarías de comparar topologías y darías la decisión por buena?

---

[Índice del bloque](README.md) · [Índice general](../README.md)

**Anterior:** [10 — Respuestas: Monolito distribuido](../04-monolito-distribuido/10-respuestas.md).

**Siguiente:** [02 — Diseñar un monolito modular desde cero](02-disenar-un-monolito-modular-desde-cero.md).
