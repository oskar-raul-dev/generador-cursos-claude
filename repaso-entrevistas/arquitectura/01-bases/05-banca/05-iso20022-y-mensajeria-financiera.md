# 05 — ISO 20022, ISO 8583 y SWIFT

> Los formatos con los que los bancos se hablan entre sí. No para implementarlos de memoria, sino
> para reconocerlos, saber qué problema resuelve cada uno y entender por qué la migración a ISO
> 20022 es uno de los proyectos más grandes del sector.
> Asume leído [`04` — Capa anticorrupción](04-capa-anticorrupcion.md).
>
> **Vigencia:** 2026-09-18.

---

## 1. 🎯 El problema

Una transferencia entre dos bancos no viaja por una API REST. Viaja por una red interbancaria con un
formato acordado, y ese formato determina qué información se puede transmitir:

```text
Formato MT antiguo (SWIFT):
  :50K:/ES9121000418450200051332
  JUAN PEREZ GARCIA
  CALLE MAYOR 1 MADRID          ← 4 líneas de 35 caracteres. Sin estructura.
```

El nombre, la calle y la ciudad están en un bloque de texto libre. Eso significa que **un sistema
automático no puede saber cuál es la ciudad**, y por tanto no puede comprobar de forma fiable si el
ordenante está en una lista de sanciones. De ahí salen las falsas alarmas, la revisión manual y los
retrasos.

> **Regla:** en pagos interbancarios, el formato del mensaje **es** la capacidad del sistema. Lo que
> no cabe estructurado, no se puede automatizar.

---

## 2. 📋 ISO 20022

**Qué es.** Un estándar de mensajería financiera basado en XML, con datos **estructurados** y un
diccionario común de conceptos. Es el que está sustituyendo a todo lo demás.

La nomenclatura, que hay que saber leer:

```text
pacs.008  → Customer Credit Transfer. La transferencia entre bancos.
pacs.002  → Payment Status Report. El acuse: aceptada, rechazada, pendiente.
pacs.004  → Payment Return. La devolución.
pain.001  → Customer Credit Transfer Initiation. El cliente ordena a SU banco.
pain.002  → el estado de esa orden, hacia el cliente.
camt.053  → Bank to Customer Statement. El extracto.
camt.056  → la petición de cancelación.

pacs = payments clearing and settlement · pain = payments initiation · camt = cash management
```

- **`pain` es cliente↔banco; `pacs` es banco↔banco.** Confundirlos es el error de vocabulario más
  frecuente, y distinguirlos demuestra de inmediato que has trabajado con esto.
- **`camt.053` es el extracto**, y es el mensaje que más aparece en integraciones de tesorería
  corporativa.

**Lo que aporta frente a MT:**

```text
Datos estructurados  → nombre, calle, ciudad y país en campos distintos.
                       Permite automatizar sanciones, antiblanqueo y conciliación.
Más espacio          → la información de remesa cabe, así que el receptor puede conciliar
                       automáticamente contra su factura.
Vocabulario común    → el mismo diccionario para pagos, valores, tarjetas y tesorería.
Extensible           → sin romper a quien no entienda las extensiones.
```

> ⚠️ **Advertencia.** ISO 20022 **no es un protocolo de transporte**: define el contenido y la
> estructura del mensaje. Cómo viaja —SWIFT, la red de pagos instantáneos local, un fichero, una
> API— es otra decisión. Confundir el estándar con el canal es un error frecuente.

> **Veredicto:** ISO 20022 resuelve un problema de **automatización**, no de tecnología. Su valor es
> que los datos estructurados permiten decidir por máquina lo que antes requería una persona leyendo
> texto libre.

---

## 3. 🔄 La migración, y por qué es enorme

**Qué es.** El sector entero está sustituyendo MT por ISO 20022, y es uno de los proyectos más
grandes que ha habido en banca. Entender **por qué es tan caro** vale más que memorizar códigos.

Los problemas, y ninguno es técnico en el sentido habitual:

```text
Truncamiento    → MT tiene campos más cortos. Al convertir ISO 20022 → MT, se PIERDE información.
                  Y esa pérdida es irrecuperable en el resto de la cadena.
Convivencia     → durante años conviven ambos, así que hace falta traducción en las dos
                  direcciones, con reglas acordadas sobre qué se pierde.
Cadena completa → un pago pasa por varios bancos. El eslabón más antiguo marca el mínimo común.
Sistemas internos→ el core, el antiblanqueo, la conciliación y el reporting hablan MT.
                  Migrar el mensaje sin migrar el resto no aporta nada.
Regulatorio     → hay fechas límite fijadas por los reguladores y los operadores de la red.
```

- **El truncamiento es el problema conceptual del capítulo**: la traducción no es reversible. Es un
  caso real y muy visible del problema de versionado de contratos de
  [`01-bases/08`](../01-bases/08-comunicacion-e-integracion.md), con años de convivencia obligada.
- **Migrar el formato sin migrar el aprovechamiento** es el error estratégico: bancos que traducen
  ISO 20022 a su modelo MT interno y tiran los datos estructurados, quedándose con el coste de la
  migración y sin el beneficio.

> **Veredicto:** la migración a ISO 20022 no es un cambio de formato, es un cambio de capacidad. Un
> banco que la hace sin rediseñar su antiblanqueo y su conciliación paga el proyecto y no cobra el
> retorno.

---

## 4. 💳 ISO 8583

**Qué es.** El estándar de mensajería de **tarjetas**: autorizaciones, anulaciones, liquidaciones.
Es de 1987, binario, compacto, y sigue moviendo prácticamente todas las transacciones con tarjeta del
mundo.

Su estructura, que es lo que hay que reconocer:

```text
MTI (4 dígitos)  → tipo de mensaje. 0100 = petición de autorización,
                   0110 = respuesta, 0400 = anulación, 0200 = financiero.
Bitmap           → un mapa de bits que dice qué campos vienen presentes.
                   Es lo que lo hace compacto: no se envía lo que no aplica.
Campos           → numerados. DE2 = número de tarjeta, DE4 = importe,
                   DE39 = código de respuesta, DE7 = fecha y hora.
```

- **Diseñado para latencia mínima**, porque una autorización tiene que responder en milisegundos con
  el cliente esperando en el terminal.
- **El flujo de dos fases es lo que hay que entender**: la **autorización** reserva el importe —el
  saldo disponible baja— y la **liquidación** mueve el dinero de verdad, horas o días después. Son
  dos mensajes distintos y dos momentos distintos.
- Eso conecta directamente con el saldo disponible frente al contable de
  [`01`](01-core-bancario-y-legado.md): la autorización crea la retención, la liquidación crea el
  asiento.

> 💡 **Truco.** Saber que una autorización no es un cobro, y que entre ambas pueden pasar días y el
> importe puede diferir —una propina en un restaurante, un ajuste de hotel—, explica la mitad de las
> incidencias que reportan los clientes. Decirlo en entrevista demuestra dominio del negocio, no solo
> del formato.

> **Veredicto:** ISO 8583 sobrevive porque resuelve muy bien un problema muy acotado: autorizar en
> milisegundos con un formato mínimo. No compite con ISO 20022; están en capas distintas del negocio.

---

## 5. 🌐 SWIFT y las redes

**Qué es.** SWIFT es la red de mensajería que conecta a los bancos internacionalmente. Es
**transporte y mensajería**, no compensación: no mueve dinero, transmite instrucciones. El dinero se
mueve por los sistemas de liquidación de cada moneda.

Lo que hay que distinguir:

```text
SWIFT          → la red de mensajería. Transmite instrucciones entre entidades.
BIC            → el identificador de una entidad en esa red (antes "código SWIFT").
IBAN           → el identificador de una CUENTA, estandarizado. No es lo mismo que el BIC.
Compensación   → el proceso por el que se netean las obligaciones entre bancos.
Liquidación    → el momento en que el dinero se mueve de verdad, normalmente en el banco central.
```

- **SEPA** en Europa, con sus esquemas: transferencia ordinaria, adeudo domiciliado, y transferencia
  **instantánea**, que liquida en segundos y 24/7 — y que rompe el modelo de ventana batch, porque
  no hay horario de cierre que valga.
- Los sistemas de pagos instantáneos son el cambio estructural más relevante: obligan a que los
  sistemas bancarios estén disponibles siempre, lo que choca de frente con el cierre de día de
  [`01` §3](01-core-bancario-y-legado.md#3--en-línea-contra-batch-y-la-ventana).

> **Veredicto:** SWIFT transmite, no liquida. Y los pagos instantáneos son lo que está forzando a los
> bancos a resolver la disponibilidad 24/7, que es la razón arquitectónica detrás de muchas
> modernizaciones actuales.

---

## 6. 🏗️ Qué significa esto para tu diseño

**Qué es.** La parte que de verdad se evalúa: cómo condicionan estos formatos la arquitectura de tu
sistema.

```text
1. NO metas el formato en tu dominio.
   pacs.008 e ISO 8583 entran por una ACL de [`04`](04-capa-anticorrupcion.md) y salen como
   Transferencia y Autorizacion. Tu dominio no conoce DE39 ni :50K:.

2. La validación del esquema es una fase aparte.
   Un mensaje malformado se rechaza antes de tocar el dominio, con el código de error que
   el estándar define. No es una excepción de tu lógica.

3. La idempotencia viene dada por el estándar.
   Los mensajes llevan un identificador único de extremo a extremo. ÚSALO como clave de
   idempotencia en vez de inventar una.

4. El estado es una máquina, no un booleano.
   Iniciada, aceptada, rechazada, devuelta, cancelada. Los mensajes de estado (pacs.002)
   y de devolución (pacs.004) son transiciones, y hay que modelarlas.

5. Las devoluciones son operaciones nuevas, no rollbacks.
   Una devolución genera su propio mensaje y su propio asiento. Es compensación,
   exactamente como en las sagas de [`02-eventos/05`](../02-eventos/05-saga.md).
```

> 🧠 **Modelo mental.** Un pago interbancario **es una saga** que cruza organizaciones: pasos
> irreversibles, compensaciones con nombre propio, estado consultable y ventana de incertidumbre. La
> banca lleva décadas haciendo lo que los microservicios redescubrieron.

---

## 7. 🧭 Cómo se elige

```text
No eliges el formato: viene dado por el canal y por el tipo de operación.
Lo que eliges es cómo lo absorbes:

¿Pago interbancario o extracto?     → ISO 20022 (pacs / pain / camt)
¿Autorización de tarjeta?           → ISO 8583
¿Internacional por SWIFT?           → MT si el corresponsal aún no migró, ISO 20022 si sí
¿Pago instantáneo local?            → ISO 20022, y SIN ventana batch: 24/7

Y en tu diseño, sin excepción:
    → el formato entra por una ACL y NO llega al dominio
    → validación de esquema como fase previa, con el código de error del estándar
    → identificador de extremo a extremo del mensaje COMO clave de idempotencia
    → estado como máquina de estados, no como booleano
    → devoluciones como operaciones nuevas, nunca como rollback
```

---

## ⚠️ Errores frecuentes

| Se dice | Lo preciso |
|---|---|
| "ISO 20022 es un protocolo" | Define el **contenido**; el transporte es otra decisión |
| "`pain` y `pacs` son lo mismo" | `pain` es cliente↔banco; `pacs` es banco↔banco |
| "SWIFT mueve el dinero" | Transmite instrucciones; el dinero se mueve en la liquidación |
| "BIC e IBAN son lo mismo" | BIC identifica la **entidad**; IBAN, la **cuenta** |
| "Una autorización es un cobro" | Reserva el importe; la liquidación llega después y puede diferir |
| "Convertimos ISO 20022 a MT y ya" | Se **pierde** información por truncamiento, de forma irreversible |
| "Migramos el formato" | Sin rediseñar antiblanqueo y conciliación, pagas el coste sin el retorno |
| "Cancelamos el pago" | Se emite una devolución: es una operación nueva, no un rollback |

---

## 📚 Para profundizar

- **Libro** — Gregor Hohpe y Bobby Woolf, *Enterprise Integration Patterns* (Addison-Wesley, 2003).
  Los patrones de traducción de mensajes y de canal de mensajes inválidos, que es cómo se absorbe un
  formato externo sin contaminar el dominio.
- **Libro** — Vlad Khononov, *Learning Domain-Driven Design* (O'Reilly, 2021). Capítulo 4: la capa
  anticorrupción aplicada a un formato impuesto por un tercero.
- **Libro** — Chris Richardson, *Microservices Patterns* (Manning, 2018). Capítulo 4: la saga, que
  es el modelo mental correcto para un pago interbancario.
- **Estándar** — ISO 20022, catálogo de mensajes (`pacs`, `pain`, `camt`) y el diccionario de
  conceptos. Se cita por título: `iso20022.org` y `swift.com` bloquean la verificación automática de
  enlaces, así que no se enlazan (§10.1 de la guía).
- **Estándar** — ISO 8583, *Financial transaction card originated messages*. Se cita por título;
  `iso.org` bloquea la verificación automática.
- **Normativa** — [EBA — Payment services and electronic money](https://www.eba.europa.eu/regulation-and-policy/payment-services-and-electronic-money):
  el marco regulatorio europeo de pagos, que se amplía en [`06`](06-psd2-y-open-banking.md).
- [Spring Cloud Contract — Reference](https://docs.spring.io/spring-cloud-contract/reference/):
  cómo se convierte un contrato de mensaje en una prueba que falla el pipeline.
- **Video** — GOTO Conferences y conferencias del sector de pagos, charlas sobre la migración a ISO
  20022. Búscalas por título.

---

## 🧠 Preguntas

Sin respuestas aquí. Todas, con enunciado literal y respuesta en tres capas, en
[`10` — Respuestas](10-respuestas.md).

1. ¿Qué es ISO 20022? 🟢
2. ¿Qué diferencia hay entre `pain` y `pacs`? 🟢
3. ¿Qué es ISO 8583 y para qué se usa? 🟢
4. ¿Qué es SWIFT y qué no es? 🟢
5. ¿Qué diferencia hay entre BIC e IBAN? 🟢
6. ¿Qué es `camt.053`? 🟡
7. ¿Qué aporta ISO 20022 frente a los mensajes MT? 🟡
8. ¿Qué son el MTI y el bitmap en ISO 8583? 🟡
9. ¿Qué diferencia hay entre autorización y liquidación de una tarjeta? 🟡
10. ¿Qué diferencia hay entre compensación y liquidación? 🟡
11. ¿Por qué ISO 20022 no es un protocolo de transporte? 🟡
12. ¿Qué es el truncamiento en la conversión ISO 20022 a MT? 🟠
13. ¿Por qué la migración a ISO 20022 es tan cara? 🟠
14. ¿Cuál es el error estratégico de migrar el formato sin más? 🟠
15. ¿Qué relación tiene la autorización de tarjeta con el saldo disponible? 🟠
16. ¿Por qué los pagos instantáneos rompen el modelo de ventana batch? 🟠
17. ¿Qué debe usarse como clave de idempotencia en un pago, y por qué? 🟠
18. ¿Por qué una devolución no es un rollback? 🟠
19. ¿Por qué un pago interbancario es una saga? 🟠
20. ¿Cómo debe entrar el formato en tu sistema y hasta dónde debe llegar? 🟠
21. Diseña el servicio que recibe `pacs.008`, los procesa y responde con
    `pacs.002`, con volumen alto y requisito de trazabilidad. 🔴
22. Un pago llega duplicado por la red interbancaria. Describe cómo lo detectas
    y qué tuvo que estar diseñado de antemano. 🔴
23. Te piden migrar a ISO 20022 "cambiando el traductor de entrada". Argumenta
    por qué no basta y qué propones. 🔴

---

**Anterior:** [`04` — Capa anticorrupción](04-capa-anticorrupcion.md) ·
**Siguiente:** [`06` — PSD2 y Open Banking](06-psd2-y-open-banking.md) ·
**Relacionado:** [`08` — Idempotencia y conciliación](08-idempotencia-y-conciliacion.md)
