# 06 — Simulación de entrevista

> El examen del bloque `08-fowler-presentacion-distribucion-y-base`: preguntas transversales que cruzan los cinco
> capítulos y cinco ejercicios de diseño de veinte minutos. Asume leídos los capítulos [`01`](01-presentacion-web.md) a
> [`05`](05-patrones-base.md). Las respuestas, en [`07` — Respuestas](07-respuestas.md#06--simulación-de-entrevista).
>
> **Vigencia:** 2026-10-03.

---

## 1. 🧭 Cómo se usa este documento

- **Con cronómetro.** Una pregunta `S#`: dos minutos en voz alta. Un ejercicio: veinte minutos.
- **Separando lo vivo de lo histórico.** Este bloque tiene mucho nivel C. El entrevistador no espera que escribas un
  Two Step View: espera que sepas qué lo reemplazó, y que escribas bien lo que sigue vivo —DTO, `@Version`, `Dinero`.
- **Con números.** Los ejercicios de dinero se resuelven con montos concretos y comprobando que las partes suman el total.
- **Solo después, el solucionario.** Las `S#` que ya son preguntas de capítulo remiten a su respuesta.

---

## 2. 🧠 Preguntas transversales

### Bloque A — Presentación

**S1.** ¿Qué diferencia hay entre el MVC original y Spring MVC? 🟡

**S2.** ¿Por qué el `DispatcherServlet` es un Front Controller? 🟢

**S3.** ¿Qué reemplazó a las vistas de plantilla en un *backend* que sirve a una aplicación de una sola página? 🟡

### Bloque B — Distribución

**S4.** ¿Qué dice la primera ley de Fowler de los objetos distribuidos? 🟢

**S5.** ¿Por qué no exponer la entidad en el API? 🟠

**S6.** ¿Dónde se arma el DTO, y por qué? 🟠

**S7.** ¿Por qué Fowler desaconseja los DTO dentro del mismo proceso? 🟠

**S8.** ¿Qué diferencia hay entre un DTO y un Value Object? 🟡

### Bloque C — Concurrencia y sesión

**S9.** ¿Por qué la transacción de la base no evita la actualización perdida entre peticiones? 🟠

**S10.** ¿Qué diferencia hay entre `SELECT ... FOR UPDATE` y un Pessimistic Offline Lock? 🟡

**S11.** ¿Qué le dices al usuario cuando hay un conflicto de edición? 🟠

**S12.** ¿Por qué "un servicio sin estado no tiene estado de sesión" es falso? 🟠

**S13.** ¿Qué relación hay entre `@Version` y `ETag`? 🟡

**S14.** ¿Por qué añadir un movimiento puede requerir bloquear la cuenta? 🟠

### Bloque D — Patrones base

**S15.** ¿Qué hace de un objeto un Value Object, y por qué un `record` no basta? 🟡

**S16.** ¿Cómo repartes 1 000,00 COP entre tres titulares sin perder centavos? 🟠

**S17.** ¿Por qué `HALF_EVEN` para dinero? 🟠

**S18.** ¿Qué diferencia hay entre Special Case y `Optional`? 🟡

**S19.** ¿Qué diferencia hay entre Gateway y Adapter? 🟡

**S20.** ¿Qué es Separated Interface en el vocabulario de hoy? 🟢

### Bloque E — Los lenguajes

**S21.** ¿Cómo se escribe `Dinero` en C++ y por qué así? 🟡

**S22.** ¿Por qué un objeto de valor es más natural en C++ que en Java? 🟡

### Bloque F — Las que descolocan

**S23.** "Usamos los mismos objetos de JPA en el API: menos clases, menos mapeo." ¿Qué respondes? 🔴

**S24.** "Para evitar conflictos de edición, bloqueamos la fila mientras el usuario edita." ¿Qué le dices? 🔴

**S25.** "El dinero en `double` está bien, redondeamos al mostrar." ¿Cómo lo desmontas? 🔴

**S26.** "Nuestros servicios son *stateless*, así que no tenemos que pensar en sesiones." ¿Qué preguntas? 🔴

**S27.** Te piden que nombres los once patrones base de Fowler. ¿Qué haces si no los recuerdas todos? 🔴

**S28.** "MVC está obsoleto, ahora todo es API." ¿Estás de acuerdo? 🔴

**S29.** "Un `NullCuenta` en todas partes nos ahorró los `NullPointerException`." ¿Qué riesgo ves? 🔴

**S30.** "¿Para qué `repartir`, si la diferencia es un centavo?" 🔴

---

## 3. 📐 Ejercicios de diseño

### E1 — El DTO de alta de persona (diseñar)

**Fuerza:** diseñar el contrato de entrada de un API sin exponer la entidad, y decidir qué valida quién.

El API recibe el alta de una persona con sus documentos, su contacto y, si es menor, el identificador de su tutor. Diseña
el DTO de entrada y el de respuesta, di qué se valida en el DTO y qué en el dominio, y escribe la operación.

### E2 — La edición de documentos que se pisa (diseñar)

**Fuerza:** proteger una transacción de negocio de varias peticiones sin bloquear a nadie.

Dos operadores pueden editar a la vez los documentos de Ana (corregir un vencimiento, añadir un pasaporte). Hoy el último
en guardar gana. Diseña la solución de punta a punta: entidad, DTO, servicio, respuesta del API y mensaje al usuario.

### E3 — `Dinero` con su reparto (escribir)

**Fuerza:** escribir un Value Object correcto con una operación que nadie hace bien a la primera.

Escribe `Dinero` en Java con moneda, escala por moneda, suma que rechaza monedas distintas, y `repartir` por proporciones.
Muestra el reparto de 1 000,00 COP en 70 % y 30 %, y de 0,05 USD entre tres.

### E4 — El saldo bonito (elegir, sin patrón)

**Fuerza:** reconocer que formatear un número para mostrarlo no necesita un patrón.

La pantalla tiene que mostrar los saldos con separador de miles y símbolo de moneda: `$ 1.500.000,00` para Ana y
`US$ 2,300.00` para Carmen. Un compañero propone una jerarquía `FormateadorDinero` con una implementación por moneda, una
fábrica y un Transform View. Diseña la solución.

### E5 — La sesión que se pierde (revisar)

**Fuerza:** encontrar dónde está el estado en un servicio que se cree sin estado.

Un servicio desplegado en cuatro contenedores guarda en un `ConcurrentHashMap` estático los asistentes de alta en curso,
indexados por usuario. "Somos *stateless*: no usamos `HttpSession`." Los usuarios se quejan de que el asistente se reinicia
a veces. Diagnostica y propón la corrección.

---

## 4. 🧭 Las frases que hay que tener listas

> "No distribuyo mis objetos: en la frontera remota devuelvo un DTO armado dentro de la transacción, con lo que el cliente
> necesita, en una llamada."

> "La actualización perdida está entre dos peticiones: `@Version`, la versión en el formulario, y un mensaje que diga qué
> cambió."

> "El dinero es un `Dinero`: moneda, escala, y un `repartir` cuyas partes suman exactamente el total."

---

**Anterior:** [`05` — Patrones base](05-patrones-base.md) ·
**Siguiente:** [`07` — Respuestas](07-respuestas.md) ·
**Relacionado:** [`03` — Concurrencia offline](03-concurrencia-offline.md)
