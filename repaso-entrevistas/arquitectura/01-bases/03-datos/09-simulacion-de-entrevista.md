# 09 — Simulación de entrevista

> El examen del bloque. Treinta y seis preguntas `S#` transversales que cruzan capítulos, más
> cinco escenarios de diseño. Se contesta **en voz alta y cronometrado**.
> Asume leídos los capítulos [`01`](01-cap-y-consistencia.md) a
> [`08`](08-poliglota-y-multi-tenant.md).
>
> **Vigencia:** 2026-09-18.

---

## 1. 🎯 Cómo se usa este documento

```text
1. Cronómetro a 2 minutos por pregunta S#.
2. Se contesta EN VOZ ALTA. Grábate.
3. Solo después vas a `10-respuestas.md`.
4. Lo que no supiste decir en 2 minutos, aunque lo supieras, cuenta como fallo.
```

Los escenarios se trabajan con papel, 15 minutos, dibujando **dónde vive cada dato y quién
manda si dos copias no coinciden**. Su solución está en [`10`](10-respuestas.md).

---

## 2. 🧠 Preguntas transversales

### Bloque A — Consistencia

**S1.** ¿Qué dice y qué no dice el teorema CAP? 🟠

**S2.** ¿Qué añade PACELC y por qué importa más en el día a día? 🟠

**S3.** ¿En qué se diferencia la C de CAP de la C de ACID? 🟡

**S4.** ¿Por qué "eventualmente consistente" sin plazo es una respuesta
incompleta? 🟠

**S5.** ¿Qué son las garantías de sesión y por qué suelen ser el requisito real? 🟠

**S6.** Te piden consistencia fuerte en todo el sistema. ¿Qué respondes? 🔴

### Bloque B — Transacciones

**S7.** ¿Por qué `@Transactional` no evita una condición de carrera? 🟡

**S8.** ¿Qué anomalías permite el nivel de aislamiento por defecto? 🟠

**S9.** ¿Cuándo eliges bloqueo pesimista sobre optimista? 🟠

**S10.** ¿Cómo evitas un conflicto de concurrencia con una sola sentencia SQL? 🟠

**S11.** ¿Qué hace `REQUIRES_NEW` y qué problema puede causar? 🟠

### Bloque C — Modelo de datos

**S12.** ¿Qué cuatro razones justifican salir del modelo relacional? 🟡

**S13.** ¿Qué diferencia hay entre `Query` y `Scan` en DynamoDB? 🟢

**S14.** ¿Por qué en DynamoDB se diseña desde los patrones de acceso? 🟠

**S15.** ¿Qué consistencia tiene un GSI y por qué importa? 🟠

**S16.** ¿Qué claves de partición producen particiones calientes? 🟠

**S17.** ¿Cuándo NO usarías single-table design? 🟠

### Bloque D — Escala

**S18.** ¿Qué haces antes de shardear, y en qué orden? 🟠

**S19.** ¿Qué diferencia hay entre particionado y sharding? 🟡

**S20.** Enumera seis cosas que se rompen al shardear. 🟠

**S21.** ¿Por qué `hash mod N` es mala idea si los nodos van a cambiar? 🟡

**S22.** ¿Qué diferencia hay entre replicación síncrona y asíncrona, y qué RPO
da cada una? 🟠

**S23.** ¿Qué se pierde exactamente en una conmutación por error? 🟠

**S24.** ¿Cómo garantizas read-your-writes con réplicas de lectura? 🟠

### Bloque E — Lectura

**S25.** ¿Cuáles son los tres niveles de CQRS? 🟡

**S26.** ¿Necesita CQRS event sourcing? ¿Y al revés? 🟡

**S27.** ¿Cuándo NO compensa CQRS? 🟠

**S28.** ¿Por qué hay que combinar invalidación precisa y TTL? 🟠

**S29.** ¿Cómo distingues una estampida de caché de un pico de tráfico? 🟠

**S30.** ¿Tu caché es una optimización o una dependencia? ¿Cómo lo compruebas? 🟠

**S31.** ¿Cuál es el riesgo principal de la tabla compartida multi-tenant? 🟠

### Bloque F — Las que descolocan

**S32.** "Nosotros usamos NoSQL porque escala mejor." Corrige sin quedar como el
listo. 🔴

**S33.** ¿Cuál es el peor incidente de datos que has visto y qué faltaba? 🔴

**S34.** Si tuvieras que quitar una pieza de una arquitectura de datos típica,
¿cuál y por qué? 🔴

**S35.** ¿Cómo decides dónde vive cada dato en un sistema con seis servicios? 🔴

**S36.** ¿Cómo le explicas a negocio que el saldo puede tardar dos segundos en
actualizarse? 🔴

---

## 3. 🏗️ Escenarios de diseño

### E1 — El que NO hay que shardear

> Una plataforma logística tiene una base Postgres de 1,2 TB con 400 millones de filas en la
> tabla de envíos. Las consultas tardan 8 segundos. El equipo propone shardear por `envioId`.
> Hay 200 escrituras por segundo y 3.000 lecturas. Diseña tu respuesta.

**Fuerza:** distinguir problema de lectura de problema de escritura, y agotar lo barato antes de
lo irreversible.

### E2 — El modelo de DynamoDB

> Un servicio de pedidos debe servir: pedido por id; pedidos de un cliente ordenados por fecha
> descendente con paginación; pedidos pendientes de envío del día; y búsqueda de pedidos por
> número de factura. 50 millones de pedidos, 3.000 lecturas por segundo. Diseña la tabla.

**Fuerza:** patrones de acceso primero, claves compuestas, GSI y saber cuál de los cuatro accesos
no encaja.

### E3 — Consistencia en un e-commerce

> Catálogo, carrito, stock, pedido y pago. Define para cada uno qué modelo de consistencia
> necesita, dónde vive el dato, y qué ve el usuario cuando hay retraso. Justifica cada decisión
> con lo que cuesta la alternativa.

**Fuerza:** que la consistencia se decide por dato y por flujo, no por sistema.

### E4 — La caché que se volvió crítica

> Un catálogo sirve 40.000 lecturas por segundo con Redis delante y un 97 % de aciertos. Un
> viernes Redis se reinicia y la base de datos cae en 40 segundos, tumbando toda la plataforma
> durante 20 minutos. Diagnostica y rediseña.

**Fuerza:** caché fría, estampida, límite de tasa hacia el origen, y reconocer que la caché era
una dependencia.

### E5 — Multi-tenant con un cliente enorme

> SaaS B2B con 3.000 clientes en tabla compartida con `tenant_id`. Un cliente nuevo representa el
> 40 % del volumen y exige residencia de datos en la UE y un informe de aislamiento. Los otros
> 2.999 no pueden verse afectados. Diseña.

**Fuerza:** modelo híbrido, directorio, Row-Level Security y vecino ruidoso, todo junto.

---

## 4. 🎤 Las tres frases que hay que tener listas

> **Sobre consistencia:** *"la P no se elige; lo que eliges es C o A durante la partición. Y el
> resto del tiempo, latencia o consistencia."*

> **Sobre escala:** *"antes de shardear: índices, vertical, réplicas, caché, archivado y
> separación por dominio. El sharding solo resuelve escritura y es lo más caro de revertir."*

> **Sobre caché:** *"invalidación precisa para la frescura, TTL con jitter para la red de
> seguridad. Y la pregunta que falta: ¿aguanta el origen si la caché cae?"*

---

**Anterior:** [`08` — Políglota y multi-tenant](08-poliglota-y-multi-tenant.md) ·
**Siguiente:** [`10` — Respuestas](10-respuestas.md) ·
**Relacionado:** [`README` — índice del bloque](README.md)
