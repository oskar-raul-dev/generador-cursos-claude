# 07 — BPM y arquitectura dirigida por workflow

> Cuándo un proceso de negocio largo deja de caber en código y merece un motor: qué aporta BPMN,
> cómo se relaciona con la saga orquestada, y el criterio honesto para no acabar con un ESB
> disfrazado de motor de procesos.
> Asume leído [`02-eventos/05` — Saga](../02-eventos/05-saga.md).
>
> **Vigencia:** 2026-09-18.

---

## 1. 🎯 El problema

La originación de un préstamo dura tres semanas y tiene esta forma:

```text
Solicitud → validación documental → scoring automático → si importe > X, comité
         → oferta al cliente (7 días para aceptar) → firma digital → formalización
         → si en cualquier punto falta un documento, vuelve al cliente y espera
         → si el cliente no responde en 15 días, caduca
```

Escribirlo en código produce una máquina de estados con veinte estados, plazos, saltos hacia atrás,
tareas humanas y un proceso nocturno que caduca lo vencido. Funciona, y tiene tres problemas:

```text
1. El proceso no se ve en ningún sitio. Está repartido entre servicios y tablas de estado.
2. Negocio no puede cambiarlo. Mover el umbral del comité es un despliegue.
3. Nadie sabe responder "¿cuántas solicitudes llevan más de 5 días paradas y en qué paso?"
```

> **Regla:** cuando el proceso dura semanas, tiene tareas humanas y negocio quiere verlo y
> cambiarlo, deja de ser lógica de aplicación y pasa a ser un **artefacto de negocio**.

---

## 2. 🗺️ Qué es BPMN y qué aporta un motor

**Qué es.** BPMN es una notación estándar para modelar procesos de negocio, **ejecutable**: el
diagrama no documenta el proceso, **es** el proceso. Un motor —Camunda, Flowable— lo ejecuta.

Los elementos que hay que reconocer:

```text
Tarea de servicio  → invoca a un sistema. Aquí llamas a tu servicio de scoring.
Tarea de usuario   → espera a una persona. El analista del comité.
Puerta (gateway)   → decisión: exclusiva (o una u otra), paralela (todas), inclusiva.
Evento temporal    → "si pasan 15 días, caduca". Sin cron, sin tabla de vencimientos.
Evento de mensaje  → "cuando llegue la firma, continúa".
Subproceso         → agrupa y permite compensación y manejo de errores por bloque.
Evento de compensación → deshacer un paso ya ejecutado. La saga, en notación.
```

**Lo que aporta, y es más de lo que parece:**

- **El proceso es visible y versionado.** Existe un diagrama que negocio entiende y que se puede
  discutir en una reunión sin traducir.
- **El estado está persistido y es consultable.** "¿Cuántas solicitudes están esperando al comité y
  desde cuándo?" es una consulta, no un proyecto.
- **Los plazos son primera clase.** Un evento temporal sustituye a un `@Scheduled` con una tabla de
  vencimientos, que es donde aparecen los bugs.
- **Las tareas humanas son un concepto**, con bandeja, asignación, reasignación y escalado. Eso es
  mucho código que no escribes.
- **La compensación está modelada**, no improvisada.

> **Veredicto:** un motor de BPM no es "un orquestador más elegante". Aporta plazos, tareas humanas
> y visibilidad del estado, que es exactamente lo que un proceso de semanas necesita y lo que el
> código ad hoc hace peor.

---

## 3. 🔗 Relación con la saga

**Qué es.** La conexión que hay que saber hacer, porque un motor de procesos **es** un orquestador de
sagas con más capacidades.

| | Saga orquestada a mano | Motor BPM |
|---|---|---|
| Flujo visible | En el código del orquestador | En un diagrama ejecutable |
| Estado | Tabla propia que diseñas | Persistido por el motor |
| Compensación | La escribes | Modelada con eventos de compensación |
| Plazos | `@Scheduled` y tabla de vencimientos | Eventos temporales nativos |
| Tareas humanas | Lo construyes entero | Concepto de primera clase |
| Duración típica | Segundos o minutos | Días o semanas |
| Coste | Una clase y una tabla | Un motor que operar |

- **La saga de [`02-eventos/05`](../02-eventos/05-saga.md) sigue siendo la respuesta** para procesos
  cortos y técnicos: reservar asiento, cobrar, confirmar. Ahí un motor es desproporcionado.
- **El motor gana cuando aparecen los plazos y las personas.** Si el proceso espera a un humano o a
  que pasen días, el código ad hoc tiene que construir mucho.

> 🧠 **Modelo mental.** Saga es orquestación **técnica** de segundos; BPM es orquestación **de
> negocio** de semanas. Es el mismo patrón a dos escalas de tiempo, y confundirlas lleva a usar la
> herramienta equivocada en las dos direcciones.

> **Veredicto:** saga y motor son el mismo patrón a dos escalas de tiempo. Lo que decide no es la
> complejidad del flujo: son los plazos y las personas.

---
## 4. 🧩 Reglas de negocio: DMN

**Qué es.** El complemento de BPMN para las **decisiones**: una tabla de decisión ejecutable que
negocio puede leer y, con gobierno, modificar.

```text
Importe     Scoring   Antigüedad  →  Resultado
< 10.000    > 700     cualquiera  →  APROBACIÓN AUTOMÁTICA
< 10.000    600-700   > 2 años    →  APROBACIÓN AUTOMÁTICA
< 10.000    600-700   < 2 años    →  COMITÉ
>= 10.000   cualquiera cualquiera →  COMITÉ
cualquiera  < 600     cualquiera  →  RECHAZO
```

- **Separa el flujo de la política.** El proceso dice "hay que decidir"; la tabla dice cómo se
  decide. Cambiar el umbral de 10.000 a 15.000 no toca el proceso ni el código.
- **Es auditable**: la tabla es el registro de qué política estaba vigente en cada momento, que en
  banca es exigible.
- **El riesgo es el gobierno**: si negocio puede cambiar la tabla sin control, un cambio mal hecho
  aprueba préstamos que no debía. Hace falta versionado, aprobación y despliegue controlado — es
  código, aunque parezca una hoja de cálculo.

> **Veredicto:** DMN resuelve el problema real —que las políticas cambian más rápido que el
> software— y crea uno nuevo: gobernar quién cambia qué. Nombrar ambos es la respuesta completa.

---

## 5. 🪦 El riesgo: el ESB con otro nombre

**Qué es.** El modo de fallo del patrón, y es el mismo que el de
[`01-bases/02`](../01-bases/02-estilos-de-despliegue.md#6--soa-y-el-esb).

```text
El motor empieza orquestando. Luego alguien mete una transformación de datos.
Luego una validación de negocio. Luego un cálculo. Luego una integración directa.
Al cabo de dos años: la lógica está en el motor, los servicios son CRUD,
y cualquier cambio de negocio pasa por el equipo que mantiene el motor.
```

- **Es exactamente el ESB**: inteligencia centralizada, cuello de botella de despliegue, y un equipo
  que bloquea a todos los demás.
- **La regla que lo evita**: el motor **coordina**, los servicios **deciden**. Una tarea de servicio
  invoca una operación de negocio completa; no hace tres llamadas y combina resultados.
- **La señal de alarma**: cambios de negocio de un dominio concreto que obligan a desplegar el
  motor. Si eso pasa, la lógica está en el sitio equivocado.

**El segundo riesgo: el acoplamiento al motor.** El proceso queda expresado en el formato del motor,
y migrar a otro es reescribirlo. Es una decisión cara de revertir, en el sentido de
[`01-bases/01`](../01-bases/01-fundamentos-del-arquitecto.md).

> ⚠️ **Advertencia.** *"Lo metemos en el motor porque es más rápido que desplegar"* es la frase con
> la que empieza la degradación. Si algo se mete en el motor para evitar un despliegue, es que el
> problema real es el pipeline.

---

## 6. 🧭 Cómo se elige

```text
¿Cuánto dura el proceso?
    Segundos o minutos, sin humanos → SAGA orquestada a mano. El motor sobra.
    Días o semanas                  → candidato a motor

¿Hay tareas humanas, con bandeja, asignación y escalado?
    Sí → el motor te ahorra construir todo eso
    No → probablemente no lo necesitas

¿Hay plazos y caducidades?
    Sí → eventos temporales nativos contra @Scheduled + tabla de vencimientos
    No → una razón menos

¿Negocio quiere VER el proceso y discutirlo?
    Sí → el diagrama ejecutable es el argumento principal
    No → el valor cae mucho

¿Las políticas cambian más rápido que el software?
    Sí → DMN, con gobierno: versionado, aprobación y despliegue controlado

Y la regla que no se negocia:
    → el motor COORDINA, los servicios DECIDEN. En cuanto el motor calcula o
      transforma, has empezado a construir un ESB.
```

---

## ⚠️ Errores frecuentes

| Se dice | Lo preciso |
|---|---|
| "BPMN es documentación" | Es ejecutable: el diagrama **es** el proceso |
| "Un motor es un orquestador más" | Aporta plazos, tareas humanas y estado consultable; eso es lo que cambia |
| "Usamos el motor para todo" | En cuanto calcula o transforma, es un ESB con otro nombre |
| "DMN permite que negocio cambie las reglas" | Y por eso necesita versionado, aprobación y despliegue controlado |
| "Saga o BPM, es lo mismo" | Saga: segundos, técnica. BPM: semanas, de negocio, con personas |
| "Lo metemos en el motor para no desplegar" | El problema es el pipeline, no el sitio donde vive la lógica |
| "Cambiar de motor será fácil" | El proceso está en su formato: migrar es reescribir |

---

## 📚 Para profundizar

- **Libro** — Bernd Ruecker, *Practical Process Automation* (O'Reilly, 2021). **Es el libro de este
  capítulo**: escrito por uno de los fundadores de Camunda, y honesto sobre cuándo NO usar un motor.
  Trata explícitamente la relación con sagas y microservicios.
- **Libro** — Chris Richardson, *Microservices Patterns* (Manning, 2018). Capítulo 4: la saga
  orquestada, que es el patrón que el motor generaliza.
- **Libro** — Gregor Hohpe y Bobby Woolf, *Enterprise Integration Patterns* (Addison-Wesley, 2003).
  El patrón *Process Manager*, que es la formulación original de lo que hace un motor.
- [Camunda — Workflow patterns](https://docs.camunda.io/docs/components/concepts/workflow-patterns/):
  el modelo de ejecución, las tareas de servicio y los eventos temporales.
- [OMG — BPMN 2.0](https://www.omg.org/spec/BPMN/2.0/): la especificación de la notación, para
  consultar los elementos y su semántica.
- [microservices.io — Saga](https://microservices.io/patterns/data/saga.html): la alternativa más
  ligera, con el criterio para quedarse en ella.
- Martin Fowler — [BoundedContext](https://martinfowler.com/bliki/BoundedContext.html): por qué la
  lógica de un dominio debe vivir en su contexto y no en el orquestador.
- **Video** — GOTO Conferences, charlas de Bernd Ruecker sobre automatización de procesos y sobre el
  riesgo de centralizar la lógica. Búscalas por título.

---

## 🧠 Preguntas

Sin respuestas aquí. Todas, con enunciado literal y respuesta en tres capas, en
[`10` — Respuestas](10-respuestas.md).

1. ¿Qué es BPMN? 🟢
2. ¿Qué es DMN? 🟢
3. Nombra cuatro elementos de un diagrama BPMN ejecutable. 🟢
4. ¿Qué es una tarea de usuario? 🟢
5. ¿Qué aporta un motor de procesos frente a código propio? 🟢
6. ¿Qué diferencia hay entre una saga orquestada y un motor BPM? 🟡
7. ¿Qué es un evento temporal y a qué sustituye? 🟡
8. ¿Por qué se dice que el diagrama BPMN "es" el proceso? 🟡
9. ¿Qué separa DMN del flujo? 🟡
10. ¿Qué es un evento de compensación en BPMN? 🟡
11. ¿Qué pregunta de negocio responde un motor que el código ad hoc no? 🟡
12. ¿Qué riesgo introduce que negocio pueda cambiar una tabla DMN? 🟠
13. ¿Cuándo un motor de procesos se convierte en un ESB? 🟠
14. ¿Cuál es la señal de alarma de esa degradación? 🟠
15. ¿Qué regla evita que el motor absorba la lógica? 🟠
16. ¿Cuándo NO usarías un motor de procesos? 🟠
17. ¿Qué acoplamiento introduce el motor y por qué es caro de revertir? 🟠
18. ¿Por qué "lo metemos en el motor para no desplegar" es una mala señal? 🟠
19. ¿Qué construyes tú si no usas motor y el proceso tiene tareas humanas? 🟠
20. ¿Qué gobierno necesita una tabla DMN y por qué? 🟠
21. Diseña la originación de un préstamo de tres semanas con comité, plazos y
    caducidad. Decide si usas motor y justifica. 🔴
22. Un motor lleva cuatro años en producción y ahora todo cambio de negocio
    pasa por el equipo que lo mantiene. Diagnostica y propón el camino. 🔴
23. Te piden usar el motor para orquestar una saga de tres pasos técnicos que
    dura dos segundos. ¿Qué respondes? 🔴

---

**Anterior:** [`06` — PSD2 y Open Banking](06-psd2-y-open-banking.md) ·
**Siguiente:** [`08` — Idempotencia y conciliación](08-idempotencia-y-conciliacion.md) ·
**Relacionado:** [`02-eventos/05` — Saga](../02-eventos/05-saga.md)
