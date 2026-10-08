# 08 — Simulación de entrevista

> El examen del bloque: preguntas que cruzan los siete capítulos de comunicación y escenarios donde
> hay que elegir estilo y defenderlo. Asume leídos [`01`](01-estilos-de-comunicacion.md) a
> [`07`](07-contratos-y-versionado.md). Las respuestas de los escenarios están en
> [`09`](09-respuestas.md).
>
> **Vigencia:** 2026-09-29.

---

## 1. 🎯 Cómo se usa esto

Mismo método que en el bloque anterior, con un añadido propio de este tema:

```text
1. Dos minutos por pregunta, cronómetro, en voz alta.
2. En las comparativas, estructura la respuesta: qué dimensión decide · qué la frena ·
   qué cuesta adoptarla. Sin esa estructura, suena a preferencia.
3. Los escenarios: quince minutos, papel, y dibujando los tramos con su estilo.
4. Cuando cites una cifra de rendimiento, di de dónde sale. Si no lo sabes, no la cites.
```

La trampa característica de este bloque es responder con tecnologías en vez de con criterios. Si la
respuesta empieza por "usaría Kafka", falta el paso anterior: qué tipo de integración es.

---

## 2. 🧠 Preguntas transversales

### Estilos y acoplamiento

1. **S1.** ¿Cuáles son los dos ejes que clasifican una integración? 🟢
2. **S2.** ¿Qué es el acoplamiento temporal y por qué una cola no lo elimina? 🟡
3. **S3.** Diferencia entre comando y evento, y por qué el nombre lo delata. 🟢
4. **S4.** ¿Por qué "asíncrono es más rápido" es falso, y qué querían decir? 🟡
5. **S5.** Asíncrono de integración contra no bloqueante: da un ejemplo de cada combinación. 🟡

### HTTP entre servicios

6. **S6.** ¿Qué cinco parámetros del cliente HTTP son decisiones de arquitectura? 🟢
7. **S7.** ¿Por qué el timeout se elige desde lo que tú puedes esperar? 🟡
8. **S8.** ¿Qué códigos invitan a reintentar y cuáles no? 🟢
9. **S9.** ¿Qué es el `N+1` distribuido y cómo se sale de él? 🟡
10. **S10.** Tu endpoint promete un segundo y llama a dos servicios. Reparte los plazos. 🟠

### gRPC y la comparativa

11. **S11.** ¿Qué representa el número de un campo en un `.proto`? 🟢
12. **S12.** ¿Qué es un deadline y en qué se diferencia de un timeout local? 🟢
13. **S13.** ¿Por qué el balanceo por conexión no reparte el tráfico gRPC? 🟡
14. **S14.** "gRPC es siete veces más rápido." Responde. 🟠
15. **S15.** Estructura la respuesta completa a "¿HTTP o gRPC entre tus servicios?". 🔴

### Tiempo real

16. **S16.** ¿Cuándo SSE y cuándo WebSocket? 🟡
17. **S17.** ¿Qué significa que WebSocket "no trae semántica"? 🟢
18. **S18.** ¿Por qué una conexión abierta convierte al servicio en algo con estado? 🟡
19. **S19.** ¿Qué hay que diseñar al recibir webhooks? 🟢

### Mensajería

20. **S20.** ¿Qué garantía de entrega da un broker, de verdad? 🟢
21. **S21.** ¿Por qué el orden solo se garantiza dentro de la partición? 🟡
22. **S22.** ¿Qué pasa si se confirma el mensaje antes de aplicar el efecto? ¿Y después? 🟡
23. **S23.** El lag crece en una sola partición. Diagnostica. 🟠
24. **S24.** "Usamos exactly-once." ¿Qué preguntas? 🟠

### Contratos

25. **S25.** Define compatibilidad hacia atrás y hacia adelante, y di cuál importa en eventos. 🟡
26. **S26.** ¿Qué cambios rompen sin que lo detecte una comparación de esquemas? 🟠
27. **S27.** ¿Qué resuelve un pacto que no resuelve una prueba de integración? 🟡
28. **S28.** ¿Por qué crear `/v2` es "una derrota administrada"? 🟡

### Las que descolocan

29. **S29.** Un compañero quiere pasar todas las llamadas a eventos "para desacoplar". Convéncele en
    dos minutos. 🔴
30. **S30.** ¿Qué decisión de comunicación has tomado que hoy harías distinta? 🔴
31. **S31.** El entrevistador insiste en que REST está obsoleto. ¿Qué respondes? 🟠
32. **S32.** Si solo pudieras exigir **una** práctica de este bloque en un equipo nuevo, ¿cuál? 🔴
33. **S33.** Te preguntan por una tecnología de mensajería que no has usado. ¿Cómo lo gestionas? 🟠
34. **S34.** ¿Cómo explicarías la consistencia eventual a alguien de negocio que dice que "los datos
    tienen que estar bien"? 🔴

---

## 3. 🎭 Escenarios de diseño

### E1 — Tres integraciones del mismo sistema

**Fuerza:** el mapa de estilos. Obliga a elegir estilo por tramo en vez de uniformar.

Un comercio electrónico necesita: mostrar la disponibilidad de un producto en la ficha; confirmar un
pedido reservando stock y cobrando; y avisar a un proveedor externo de que prepare el envío.

Elige el estilo de comunicación de cada uno, justifica y di qué pasa si el otro extremo tarda ocho
segundos.

### E2 — La plataforma cambia la respuesta

**Fuerza:** el coste de adopción. El mismo patrón sale barato en una plataforma y caro en otra.

Dos servicios de alto volumen y contrato estable tienen que hablarse. En la versión A, ambos son de
Go y el equipo ya usa gRPC. En la versión B, uno es de Python, otro de Node/TS, y el equipo no ha
usado gRPC nunca. La plataforma solo balancea conexiones.

Decide en cada versión y explica exactamente qué cambia entre las dos.

### E3 — Seguimiento en vivo del pedido

**Fuerza:** el empuje al cliente con estado. Obliga a diseñar reconexión, escalado y autenticación.

El cliente tiene abierta la pantalla de su pedido y quiere ver el estado en vivo: confirmado,
reservado, pagado, enviado. Hay web y aplicación móvil, y los eventos nacen en tres servicios
distintos.

Diseña el camino completo, incluido qué pasa en un despliegue.

### E4 — Un cambio de contrato que rompe

**Fuerza:** la evolución. Obliga a aplicar expand/contract y a gestionar consumidores que no migran.

Tienes que renombrar un campo y cambiar el significado de otro —de importe sin impuestos a importe
con impuestos— en una API que consumen tres servicios internos y una aplicación móvil que no se
actualiza.

Diseña el cambio completo, con fases y con lo que haces con el móvil.

### E5 — El evento que nunca llegó

**Fuerza:** el diagnóstico asíncrono. Obliga a recorrer la cadena completa sin adivinar.

Un cliente reclama: su pedido aparece confirmado pero nunca se reservó el stock. El lag del consumidor
es cero y la DLQ está vacía.

Di qué compruebas, en qué orden, y cuáles son las tres causas más probables.

---

## 4. 🗣️ Las frases que hay que tener listas

> "Primero decido si el que llama necesita al otro vivo ahora mismo. El protocolo viene después: HTTP
> o gRPC es una decisión de segundo orden."

> "Asumo duplicados y hago el consumidor idempotente. Al-menos-una-vez más idempotencia es,
> funcionalmente, exactamente-una-vez; y es lo único que aguanta."

> "El contrato es lo único que de verdad ata a dos servicios. Por eso lo verifico en CI y no en un
> entorno donde todo está desplegado a la vez."

---

**Anterior:** [`07` — Contratos y versionado](07-contratos-y-versionado.md) · **Siguiente:**
[`09` — Respuestas](09-respuestas.md) · **Relacionado:**
[`03-datos-y-consistencia`](../03-datos-y-consistencia/) ·
[`05-plataformas`](../05-plataformas/)
