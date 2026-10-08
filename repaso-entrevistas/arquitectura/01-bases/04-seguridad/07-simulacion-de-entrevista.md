# 07 — Simulación de entrevista

> El examen del bloque. Treinta y dos preguntas `S#` transversales, más cinco escenarios de
> diseño. Se contesta **en voz alta y cronometrado**.
> Asume leídos los capítulos [`01`](01-autenticacion-autorizacion-y-amenazas.md) a
> [`06`](06-secretos-y-criptografia.md).
>
> **Vigencia:** 2026-09-18.

---

## 1. 🎯 Cómo se usa este documento

```text
1. Cronómetro a 2 minutos por pregunta S#.
2. Se contesta EN VOZ ALTA. Grábate.
3. Solo después vas a `08-respuestas.md`.
4. Lo que no supiste decir en 2 minutos, aunque lo supieras, cuenta como fallo.
```

Los escenarios se trabajan con papel, 15 minutos, dibujando **dónde se verifica la identidad y
dónde se decide el permiso en cada salto**. Su solución está en [`08`](08-respuestas.md).

---

## 2. 🧠 Preguntas transversales

### Bloque A — Vocabulario

**S1.** ¿Qué diferencia hay entre autenticación y autorización, y por qué importa
en el diseño? 🟡

**S2.** ¿Qué son OAuth2, OIDC y JWT, y en qué se diferencian? 🟡

**S3.** ¿Qué son PEP y PDP? 🟢

**S4.** ¿Qué modelos de autorización existen y cuándo eliges cada uno? 🟠

**S5.** ¿Qué significa "fallo cerrado" y dónde se incumple? 🟠

### Bloque B — Spring Security

**S6.** ¿Qué pasa entre que llega la petición y que se ejecuta tu controlador? 🟠

**S7.** ¿Por qué una ruta pública puede acabar pidiendo login? 🟡

**S8.** ¿Por qué en un `@Async` el usuario aparece como null? 🟡

**S9.** ¿Por qué `@PreAuthorize` puede no aplicarse, y por qué eso es peor que un
error? 🟠

**S10.** ¿Cuándo es correcto desactivar CSRF y cuándo es un agujero? 🟠

### Bloque C — Tokens

**S11.** ¿Qué seis cosas se validan en un JWT? 🟠

**S12.** ¿Por qué validar `aud` es crítico? 🟠

**S13.** ¿Qué flujo de OAuth2 usarías hoy y cuáles están obsoletos? 🟡

**S14.** ¿Qué es PKCE y qué problema resuelve? 🟡

**S15.** ¿Por qué "con JWT revocamos al instante" es contradictorio? 🟠

**S16.** ¿Qué diferencia hay entre un scope y un permiso sobre un objeto? 🟠

### Bloque D — Distribuido

**S17.** ¿Cuáles son las tres estrategias de propagación de identidad? 🟡

**S18.** Narra la confusión de deputado con tres servicios concretos. 🟠

**S19.** ¿Qué dos identidades hay en una llamada entre servicios? 🟡

**S20.** ¿Qué es el token exchange y qué acota? 🟠

**S21.** ¿Por qué "están en la red interna" no es una garantía? 🟡

**S22.** ¿Qué es mTLS y qué tres problemas resuelve? 🟡

**S23.** ¿Qué significa zero-trust, con mecanismos concretos? 🟠

**S24.** ¿Cuándo NO usarías un service mesh? 🟠

### Bloque E — Datos

**S25.** ¿Por qué un secreto en el código no es un secreto? 🟢

**S26.** ¿Cuál es el primer paso ante un secreto filtrado? 🟠

**S27.** ¿Contra qué NO protege el cifrado de disco? 🟠

**S28.** ¿Con qué se hashean las contraseñas y por qué no con SHA-256? 🟡

### Bloque F — Las que descolocan

**S29.** "Tenemos JWT, ya estamos seguros." Corrige sin quedar como el listo. 🔴

**S30.** ¿Cuál es el peor fallo de seguridad que has visto y qué faltaba? 🔴

**S31.** Si tuvieras que elegir **una sola** medida para un sistema que hoy no
tiene ninguna, ¿cuál y por qué? 🔴

**S32.** ¿Cómo convences a negocio de invertir en seguridad cuando no hay
incidentes? 🔴

---

## 3. 🏗️ Escenarios de diseño

### E1 — El que NO necesita service mesh

> Cinco microservicios Java en Kubernetes, un equipo de seis personas, un producto interno de
> gestión documental sin datos financieros. El equipo quiere instalar Istio "para tener mTLS y
> observabilidad". Diseña tu respuesta.

**Fuerza:** saber decir que no, y proponer lo que sí resuelve el problema real a un coste
proporcional.

### E2 — La cadena de confianza

> Una banca en línea: gateway → `Cuentas` → `Riesgo` → proveedor externo de scoring. Hoy todos los
> servicios internos se llaman sin credenciales porque "están en la red interna". Diseña la
> propagación de identidad completa, salto a salto, y di qué falla hoy.

**Fuerza:** dos identidades, token exchange, el salto al tercero, y la confusión de deputado.

### E3 — Revocación en segundos

> Un banco exige que, al desactivar a un empleado, su acceso a todas las aplicaciones internas se
> corte en menos de 30 segundos. Hoy usan JWT autocontenidos con caducidad de una hora. Diseña la
> solución y declara su coste.

**Fuerza:** el compromiso entre validación sin estado y revocación, y saber que no hay opción
gratis.

### E4 — El dato que hay que cifrar y buscar

> Una pasarela de pagos guarda números de tarjeta para cobros recurrentes. Normativa exige que no
> sean legibles ni para el administrador de base de datos. Soporte necesita buscar por los últimos
> cuatro dígitos, y el sistema antifraude necesita saber si dos clientes usan la misma tarjeta.
> Diseña el almacenamiento.

**Fuerza:** cifrado a nivel de campo, sobre criptográfico, tokenización y hash determinista, todo a
la vez.

### E5 — Sistema heredado sin ninguna medida

> Un monolito bancario de doce años: contraseñas en `application.properties`, autenticación propia
> con SHA-1 sin sal, sin HTTPS interno, y autorización por un `if` sobre un campo `perfil`. No se
> puede parar el negocio. Diseña el plan.

**Fuerza:** priorizar por riesgo y por coste, migrar contraseñas sin invalidarlas, y saber qué se
hace primero.

---

## 4. 🎤 Las tres frases que hay que tener listas

> **Sobre el token:** *"el token dice quién eres; que puedas ver **este** objeto lo decide mi
> servicio, siempre, aunque el gateway ya haya validado."*

> **Sobre la red:** *"la red interna no es una frontera de confianza. Cada servicio verifica quién
> llama y en nombre de quién."*

> **Sobre los secretos:** *"la medida del éxito no es que estén guardados, es que rotarlos sea
> rutina. Si rotar da miedo, no hay gestión de secretos."*

---

**Anterior:** [`06` — Secretos y criptografía](06-secretos-y-criptografia.md) ·
**Siguiente:** [`08` — Respuestas](08-respuestas.md) ·
**Relacionado:** [`README` — índice del bloque](README.md)
