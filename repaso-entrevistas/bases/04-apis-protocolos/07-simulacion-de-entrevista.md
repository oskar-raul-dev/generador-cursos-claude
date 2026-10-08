# 07 — Simulación de entrevista

> El examen del corpus: 40 preguntas transversales que cruzan capítulos y seis escenarios de diseño y
> diagnóstico. No se responde leyendo: se responde **en voz alta y con cronómetro**, que es como se
> responde en la entrevista real.
>
> Las respuestas están en [`08` — Respuestas](08-respuestas.md), en tres capas. Se miran **después**.
>
> **Vigencia:** 2026-09-17. · **Requisito:** los seis capítulos.

---

## 1. 🎯 Cómo se usa esto

```text
1. Cronómetro a 2 minutos por pregunta.
2. EN VOZ ALTA. Escribir la respuesta en la cabeza no cuenta: la boca descubre los huecos.
3. Primero la frase de 30 segundos. Luego se amplía SOLO si la frase quedó completa.
4. Después se compara con el solucionario, y se anota qué capa faltó.
```

Tres reglas que valen más que el contenido:

- **Si no sabes, se dice, y se dice bien.** *"No lo he tocado en producción; lo que sé es X y lo
  verificaría en el RFC 9110"* es una respuesta aceptable de un Tech Lead. Inventarse una cita
  concreta y fallarla no lo es: hunde toda la entrevista, porque a partir de ahí todo lo demás se
  pone en duda.
- **Distingue las tres afirmaciones**, que es la aportación de este corpus: *lo obliga la norma*, *lo
  recomienda*, *es convención de la industria*. Casi ninguna respuesta de internet lo hace, y hacerlo
  se nota a la primera frase.
- **Cita solo lo que verificaste.** Mejor *"está en la sección de métodos de RFC 9110"* que un número
  de sección inventado.

---

## 2. 🧠 Preguntas transversales

### Bloque A — Norma y contrato

**S1.** ¿Dónde está escrito lo que obliga HTTP, y cómo sabes si lo que lees sigue vigente? 🟡

**S2.** Da tres ejemplos de cosas que todo el mundo hace y que **ninguna norma obliga**. 🟠

**S3.** Un compañero cita RFC 2616. ¿Qué le dices, y cambia eso su conclusión? 🟡

**S4.** ¿`SHOULD` y `MUST` cambian lo que tu cliente tiene que tolerar? Explica con un ejemplo. 🟠

**S5.** ¿Cómo nombrarías hoy un encabezado propio, y qué norma respalda esa decisión? 🟡

### Bloque B — El mensaje

**S6.** Escribe en la pizarra una petición HTTP completa, a mano, y explica cada línea. 🟢

**S7.** ¿Cómo sabe el servidor dónde termina el cuerpo? Da los dos mecanismos. 🟢

**S8.** ¿Qué es un encabezado *hop-by-hop* y por qué te importa detrás de un balanceador? 🟡

**S9.** ¿Qué hace `Vary` y qué rompe su ausencia? 🟠

**S10.** ¿Por qué mandar `Content-Length` y `Transfer-Encoding` a la vez es un problema de
seguridad? 🟠

### Bloque C — Métodos y semántica

**S11.** ¿`PUT` o `PATCH` para cambiar un campo? Y justifica. 🟡

**S12.** ¿Es idempotente `DELETE`? ¿Y `PATCH`? 🟡

**S13.** Diseña el cambio de estado de un pedido de forma idempotente. 🟠

**S14.** ¿Qué garantiza una clave de idempotencia y qué **no** garantiza? 🟠

**S15.** ¿Qué nivel de madurez de Richardson tiene tu última API y por qué está bien? 🟠

**S16.** ¿Cuándo dirías que una API **no** debería ser REST? 🟠

### Bloque D — Formatos y codificación

**S17.** Te piden subir un archivo por una API. Da las opciones y elige, con el coste de cada una. 🟠

**S18.** ¿Por qué existe Base64 y cuánto cuesta exactamente? 🟢

**S19.** ¿Recupera gzip lo que Base64 infla? 🟠

**S20.** ¿Qué diferencia hay entre codificar caracteres y codificar una URL? 🟡

**S21.** ¿Qué tipo de medio pondrías a un recurso propio versionado, y por qué con `+json`? 🟡

### Bloque E — Transporte y seguridad

**S22.** ¿Qué te da HTTPS y qué no te da? 🟢

**S23.** ¿Cómo verifica un cliente que el certificado es legítimo? 🟡

**S24.** "Funciona en Chrome y falla en el JDK." ¿Qué miras primero? 🟠

**S25.** ¿Qué ganó TLS 1.3 sobre 1.2, y qué riesgo trajo? 🟠

**S26.** ¿Ciframos el tramo entre el balanceador y el servicio? Argumenta las dos posturas. 🟠

**S27.** ¿En qué se parecen y en qué no se parecen SSH y TLS? 🟡

### Bloque F — Versiones, caché y tiempo real

**S28.** ¿Qué problema resuelve HTTP/2 y cuál hereda? 🟡

**S29.** ¿Qué aporta HTTP/3 y qué cuesta? 🟠

**S30.** Diferencia `no-cache`, `no-store` y `max-age=0`. 🟡

**S31.** ¿Cómo usarías `ETag` para evitar que dos usuarios se pisen una edición? 🟠

**S32.** ¿SSE o WebSocket? Da el criterio, no la preferencia. 🟠

**S33.** Un equipo migró a HTTP/2 y no mejoró nada. ¿Por dónde empiezas? 🟠

### Bloque G — Las que descolocan

**S34.** ¿Por qué el código de estado `418` existe, y qué te dice eso sobre los RFC? 🟡

**S35.** ¿Puede una respuesta `200` significar que la operación falló? ¿Está bien hacerlo? 🟠

**S36.** Si HTTP no tiene estado, ¿cómo funciona un carrito de compra? 🟡

**S37.** ¿Puede un `GET` llevar cuerpo? ¿Y debería? 🟠

**S38.** Tu API tiene que devolver 200 000 registros. ¿Qué haces? 🔴

**S39.** ¿Qué pasa exactamente entre que escribes una URL y llega el primer octeto de HTML?
Cuéntalo entero. 🔴

**S40.** Si tuvieras que explicarle HTTP a alguien que sabe programar pero nunca ha tocado la red,
¿por dónde empezarías y qué dejarías fuera? 🔴

---

## 3. 🧪 Escenarios

Cada uno es de pizarra: se piensa en voz alta, se pregunta lo que falte y se dibuja. Entre quince y
veinticinco minutos cada uno.

### E1 — El contrato de subida de facturas 🔴

Un banco necesita que sus clientes corporativos suban facturas en PDF —de 1 KB a 50 MB— junto con
metadatos: número de pedido, fecha y centro de coste. El volumen esperado es de 20 000 al día, con
picos de fin de mes de diez veces eso.

**Define el contrato completo:** método, tipo de medio, cómo viaja el binario, límites, validación,
respuestas de éxito y de error, qué pasa si el cliente reintenta, y qué pasa si sube el mismo archivo
dos veces. Justifica cada decisión con su coste, y di explícitamente qué partes son norma y cuáles
convención tuya.

### E2 — El cobro duplicado 🔴

Una pasarela de pagos reporta que el 0,3 % de las transacciones se cobran dos veces. Ocurre solo en
horas pico, nunca se reproduce en pruebas, y los logs muestran que el servicio recibió **dos
peticiones idénticas** separadas por 28 segundos.

Da tus **tres hipótesis ordenadas por probabilidad**, el experimento que distingue cada una y la
corrección definitiva. Di también qué corrección **no** funcionaría y por qué.

### E3 — Los acentos del informe 🟠

Un informe exportado a CSV llega con acentos rotos: a unos usuarios sí y a otros no. El servicio no
ha cambiado en seis meses. El equipo de soporte dice que "se arregla abriéndolo con Google Sheets en
vez de Excel".

Diagnostica la cadena entera —de la base de datos al archivo abierto— y di en qué punto exacto se
rompe, cómo lo confirmarías y qué cambiarías en la respuesta HTTP.

### E4 — La caída del domingo 🟠

A las 03:14 de un domingo, toda la plataforma deja de responder. Los balanceadores están arriba, los
servicios también, y el tráfico interno funciona. Desde fuera, los clientes ven errores de conexión
segura. El último despliegue fue hace once días.

Di **qué miras en los primeros cinco minutos**, en qué orden, con qué comandos exactos, y cuál es la
causa que ya sospechas antes de mirar nada.

### E5 — El seguimiento en vivo 🔴

Producto quiere que el cliente vea el estado de su pedido cambiar en tiempo real, sin recargar. Hay
picos de 50 000 clientes conectados a la vez, la aplicación está detrás de un balanceador con cuatro
instancias y algunos clientes corporativos navegan tras proxies que cortan conexiones largas.

Elige el transporte y **defiende por qué no los otros tres**. Diseña reconexión, qué ocurre si el
cliente estuvo desconectado diez minutos, y cómo escala el reparto de eventos entre instancias.

### E6 — Lo que el protocolo no resuelve 🔴

Un cliente exige que, cuando su sistema envíe una orden de transferencia a tu API, quede
**garantizado** que la orden se ejecuta exactamente una vez: ni cero ni dos. Te pide que lo
resuelvas "con un buen diseño REST", y su arquitecto insiste en que con `PUT` y un `Idempotency-Key`
queda cerrado.

**Explica por qué el protocolo no puede darle esa garantía**, qué es lo máximo que HTTP sí da, y qué
hay que añadir por encima para que el resultado observable sea el que pide. Escribe también cómo se
lo dirías a él sin que suene a excusa.

---

## 4. 💡 Las frases que hay que tener listas

Diez frases que cierran una pregunta bien. No se memorizan: se entienden y salen solas.

1. *"Eso es un `SHOULD`, no un `MUST`: un servidor puede no hacerlo y seguir siendo conforme."*
2. *"RFC 2616 está obsoleto desde 2014; la semántica vive hoy en RFC 9110."*
3. *"El prefijo `X-` está desaconsejado desde RFC 6648; funciona, pero en una API nueva no lo usaría."*
4. *"La idempotencia es del efecto, no de la respuesta: por eso `DELETE` lo es aunque el segundo dé
   `404`."*
5. *"`PATCH` no es idempotente por definición, y ni siquiera se define en RFC 9110."*
6. *"Exactly-once no existe sobre una red que pierde mensajes: lo que hay es at-least-once más una
   operación idempotente."*
7. *"Base64 infla un 33 % exacto, y en datos ya comprimidos gzip lo recupera casi entero; el coste
   caro es la memoria, no el cable."*
8. *"HTTPS autentica al servidor y cifra el canal. No dice que el sitio sea legítimo: el phishing
   también tiene candado."*
9. *"HTTP/2 quitó el bloqueo de cabeza de línea en HTTP y lo heredó de TCP; por eso existe HTTP/3."*
10. *"`no-cache` no significa no cachear: significa revalidar siempre. Lo que casi todos quieren
    decir es `no-store`."*

---

## 5. 📝 Qué anotar después

```text
Por cada pregunta fallada:
  ¿faltó la capa de 30 segundos, la de 2 minutos o el detalle?
  ¿fue desconocimiento, o lo sabía y no lo supe decir?
  ¿confundí norma con convención?
```

La tercera es la que más se repite, y la que más rápido se corrige: casi siempre el conocimiento
estaba y lo que faltaba era **decir de dónde viene**.

---

**Anterior:** [`06` — Versiones, proxies y tiempo real](06-versiones-proxies-y-tiempo-real.md) ·
**Siguiente:** [`08` — Respuestas](08-respuestas.md)
