# 01 — Anatomía y evidencia del monolito distribuido

Aprenderás a sostener o rechazar el diagnóstico de monolito distribuido con evidencia: qué
señales cuentan, por qué ninguna basta sola y cómo separar la autonomía que un sistema declara de la
que de verdad tiene.

## 1. 🎯 Síntoma y decisión

Hace dos años la plataforma de comercio se partió en cinco componentes —`orders`, `inventory`,
`payments`, `notifications` y una pasarela de composición—, cada uno con su repositorio, su pipeline
y su contenedor. Hoy, añadir la expiración de reservas tardó cinco semanas: cambios en tres
repositorios, un DDL coordinado sobre el esquema que todos comparten, un hueco en el release train
semanal y la aprobación de tres equipos. La dirección pregunta si tienen microservicios o un
monolito distribuido, y un arquitecto ya propone dividir más fino.

Antes de cualquier propuesta hay que responder la pregunta con evidencia. La decisión de este
capítulo es qué evidencia sostiene el diagnóstico, cuál lo refuta y qué moneda domina.

## 2. 🧠 Modelo mental

La topología dice cuántos procesos hay; la **autonomía efectiva** dice si un equipo puede cambiar,
desplegar y operar su capacidad sin esperar a otros. Repositorios, pipelines y contenedores separados
son autonomía **nominal**: la condición necesaria, no la prueba.

```text
                      autonomía efectiva baja          autonomía efectiva alta
un proceso            monolito difícil de cambiar      monolito modular
varios procesos       monolito distribuido             servicios autónomos
                      paga red Y coordinación          paga red, compra independencia
```

Un monolito distribuido paga a la vez los costes de los dos mundos: la coordinación de cambio y de
despliegue del monolito, y la red, los contratos remotos y los fallos parciales de la distribución.
Se diagnostica siguiendo un cambio real a través de las cinco monedas —código, datos, despliegue,
runtime y equipos— y comprobando si el patrón se repite.

## 3. 🔍 Evidencia antes del diagnóstico

| Nivel | En el sistema de comercio |
|---|---|
| Observación | la expiración de reservas tocó tres repositorios, un DDL compartido, el release train y tres aprobaciones; en seis meses, siete de cada diez cambios de negocio siguieron ese patrón; checkout necesita los cinco componentes disponibles |
| Inferencia | los componentes están separados en proceso, pero no en cambio, datos ni despliegue |
| Diagnóstico | monolito distribuido: evidencia recurrente en cuatro monedas y ningún beneficio compensatorio medido, porque ningún componente escala ni se despliega por separado |
| Recomendación | corregir primero la moneda dominante —datos y release— antes de cualquier nueva división, y evaluar fusionar donde el cambio siempre cruza |

Las cifras son supuestos del ejercicio. Qué refutaría el diagnóstico: si ese 70 % fuera un único
proyecto transversal y no el patrón habitual, o si algún componente sí se desplegara por su cuenta
con su propio SLO, el cuadro sería parcial y la remediación, más acotada. La
matriz de la sección siguiente ordena esa evidencia.

## 4. 🛠️ Diagnóstico por autonomía efectiva

Se elige un cambio real —por ejemplo, añadir expiración de reservas— y se sigue de extremo a extremo.
Si modifica tres repositorios, requiere DDL coordinado, entra al release train de cinco servicios,
necesita toda la cadena disponible y obliga a varios equipos a aprobar, existe evidencia combinada.
Ninguna fila aislada basta.

| Moneda | Evidencia de pérdida de autonomía | Contraejemplo sano |
|---|---|---|
| código | el mismo cambio cruza componentes siempre | librería estable con owner |
| datos | escrituras cruzadas e invariantes sin dueño | motor compartido con permisos claros |
| despliegue | release train obligatorio | rollout conjunto ocasional y deliberado |
| runtime | todos son obligatorios para cada operación | dependencia degradable o asíncrona |
| equipos | decisiones rutinarias requieren comité | contrato gobernado y cambio local |

El diagnóstico exige recurrencia y ausencia de beneficio compensatorio. Una cadena síncrona puede
ser correcta si la respuesta inmediata es una garantía y su disponibilidad cumple el SLO. Una base
compartida puede abaratar joins con ownership de escritura estricto. El problema aparece cuando se
pagan red, serialización, compatibilidad y fallos parciales sin obtener despliegue, escala u ownership
independientes.

Antes de dividir otra vez, se corrige la moneda dominante: dueño de datos, contrato, cadena o release.
También es válida la hipótesis de fusionar componentes si recupera una transacción y reduce operación.

## 5. 🧰 Plataformas

| Plataforma | Mecanismo relevante | Qué no resuelve | Trampa frecuente |
|---|---|---|---|
| Java | no aplica: artefactos no prueban autonomía | un JAR por componente no decide el diagnóstico | contar proyectos |
| Node/TypeScript | no aplica: paquetes no equivalen a servicios | workspaces no explican releases | contar paquetes |
| Go | no aplica: binarios separados son evidencia parcial | el build no muestra ownership | contar procesos |
| Python | no aplica: workers y apps pueden compartir release | el entorno no muestra datos | contar contenedores |

La tabla dice «no aplica» en las cuatro filas a propósito: ningún mecanismo de plataforma
diagnostica un monolito distribuido. Contar JARs, paquetes, binarios o contenedores mide la
topología, que es justo lo que no está en duda. Lo que decide está en el historial de cambios, el
esquema, el pipeline, la cadena de llamadas y el organigrama, y se lee igual en cualquier lenguaje.

## 6. ⚖️ Decisión y coste

Diagnostica con cambios representativos y evidencia combinada de código, datos, despliegue, runtime y equipos. Medir el historial cuesta tiempo, pero evita una migración basada en una señal aislada. Conserva la distribución cuando su aislamiento o escala compensen la coordinación observada. Propón remediación únicamente para la dependencia que impide autonomía y verifica su efecto en cambios posteriores.

## ⚠️ Errores frecuentes

- «Varios servicios forman microservicios». Varios procesos son una topología; sin cambio, datos y despliegue independientes, son un monolito distribuido.
- «Una base compartida basta para diagnosticarlo». Puede ser una concesión barata con ownership de escritura claro; el diagnóstico necesita más monedas.
- «Toda llamada síncrona lo demuestra». Una cadena corta que cumple su SLO y aporta una garantía es una decisión, no un síntoma.
- «La solución es dividir más fino». Si un cambio ya cruza cinco componentes, cortarlos en diez lo hace cruzar diez.
- «Fusionar servicios es admitir un fracaso». Puede ser la forma más barata de recuperar una transacción y reducir operación.

## 7. ✅ Veredicto

Diagnostica con cambios reales recorridos por las cinco monedas y exige recurrencia: una señal
aislada puede ser una concesión consciente. Si la mayoría de los cambios cruzan componentes, datos y
releases sin que ninguna separación compre escala o independencia medida, el sistema paga a la vez
los costes del monolito y los de la red. La remediación empieza por la moneda dominante, y fusionar
es una opción tan legítima como separar.

## 📚 Referencias

- [Microservices, Fowler y Lewis](https://martinfowler.com/articles/microservices.html)
- [Microservice Trade-Offs, Martin Fowler](https://martinfowler.com/articles/microservice-trade-offs.html)
- [Team Topologies: Key Concepts](https://teamtopologies.com/key-concepts-content)

## 🧠 Preguntas

1. 🟢 ¿Qué es un monolito distribuido?
2. 🟢 ¿Qué diferencia hay entre autonomía nominal y autonomía efectiva?
3. 🟢 ¿Qué evidencia mira cada una de las cinco monedas en este diagnóstico?
4. 🟢 ¿Por qué se diagnostica siguiendo un cambio real y no revisando la arquitectura dibujada?
5. 🟢 ¿Qué costes suma un monolito distribuido que no tiene ni un monolito ni un sistema de servicios autónomos?
6. 🟢 ¿Qué es un release train y por qué es una señal en la moneda de despliegue?
7. 🟡 ¿Por qué diagnosticar por base compartida solamente es una simplificación peligrosa?
8. 🟡 ¿Cuándo mantendrías la distribución aunque haya coordinación, porque compra aislamiento o escala demostrable?
9. 🟡 ¿Qué parte del cambio de expiración de reservas es evidencia de código, cuál de datos y cuál de despliegue?
10. 🟡 ¿Qué proporción de cambios coordinados empezaría a preocuparte y por qué la cifra sola no decide?
11. 🟡 ¿Cómo distingues un despliegue conjunto deliberado de un release train obligatorio?
12. 🟡 ¿Qué dato de runtime mirarías para saber si un componente es obligatorio para checkout?
13. 🟡 ¿Cómo aparece la moneda de equipos en un monolito distribuido?
14. 🟡 ¿Qué diferencia hay entre causa, síntoma y consecuencia en este diagnóstico?
15. 🟡 ¿Qué beneficio compensatorio buscarías antes de concluir que la distribución no compra nada?
16. 🟡 ¿Por qué la ausencia de incidentes no descarta el diagnóstico?
17. 🟡 ¿Por qué artefactos separados en Java o Go siguen siendo evidencia parcial de autonomía?
18. 🟠 ¿Qué información falta al contar workspaces Node o aplicaciones Python como servicios?
19. 🟠 La dirección pregunta si «tienen microservicios o un monolito distribuido» y quiere la respuesta en una semana. ¿Qué harías?
20. 🟠 Un arquitecto propone dividir los cinco componentes en doce para «desacoplar». ¿Qué evidencia pedirías antes?
21. 🟠 Solo `payments` se despliega por su cuenta y cumple su SLO; el resto va en el release train. ¿Qué diagnóstico darías?
22. 🟠 Tras el diagnóstico decides actuar. ¿Qué primera acción reversible elegirías y cómo medirías su efecto?
23. 🟠 Dos arquitectos discrepan: uno ve un monolito distribuido y otro «microservicios inmaduros». ¿Cómo resolverías la discusión?
24. 🟠 ¿Qué evidencia te haría retirar el diagnóstico de monolito distribuido?

---

[Índice del bloque](README.md) · [Índice general](../README.md)

**Anterior:** [09 — Respuestas: Datos, ejecución y operación](../03-datos-ejecucion-y-operacion/09-respuestas.md).

**Siguiente:** [02 — Cadenas síncronas y acoplamiento temporal](02-cadenas-sincronas-y-acoplamiento-temporal.md).
