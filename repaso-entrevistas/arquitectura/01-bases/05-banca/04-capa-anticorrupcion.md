# 04 — Capa anticorrupción sobre el legado

> Cómo se protege un dominio limpio de un modelo hostil que no puedes cambiar: qué traduce una ACL
> además de la firma, cómo se prueba contra un sistema que no puedes usar, y por qué acaba siendo un
> componente crítico con su propia operación.
> Asume leído [`01-bases/06` — DDD estratégico](../01-bases/06-ddd-estrategico.md).
>
> **Vigencia:** 2026-09-18.

---

## 1. 🎯 El problema

El core devuelve esto, y es representativo:

```text
CTA-MAESTRA
  CODENT   0182        ← código de entidad
  CODOFI   3245        ← oficina
  DC       91          ← dígitos de control
  NUMCTA   0012345678
  SITOPER  3           ← 1=alta 2=baja 3=activa 4=bloqueada 9=en trámite
  IMPSAL   000000125045  ← sin separador decimal. Son 1.250,45. A veces.
  FECVAL   20260917
  IND1     ' '         ← si está en blanco, significa que la cuenta admite descubierto
```

Si eso entra en tu dominio, tu `Cuenta` acaba con un campo `sitOper` y un método
`esActiva() { return sitOper == 3; }`. Y a partir de ahí, **el modelo del core es tu modelo**: cada
cambio suyo te atraviesa, y tu lenguaje ubicuo desaparece.

> **Regla:** la capa anticorrupción no traduce formatos, traduce **conceptos**. Su éxito se mide en
> que ningún término del core aparezca en tu dominio.

---

## 2. 🛡️ Qué es y qué traduce

**Qué es.** Un adaptador con intención de arquitectura: un componente que habla el idioma del core
por un lado y el tuyo por el otro, y que concentra **todo** el conocimiento del modelo ajeno.

Lo que traduce, y son cuatro cosas distintas:

```text
1. FORMATO    → posicional a objetos, importes sin decimal a Money, fechas AAAAMMDD a LocalDate
2. VOCABULARIO→ CTA-MAESTRA a Cuenta, SITOPER=3 a EstadoCuenta.ACTIVA
3. ESTRUCTURA → cuatro campos (CODENT, CODOFI, DC, NUMCTA) a un único Iban
4. SEMÁNTICA  → "IND1 en blanco significa que admite descubierto" a un booleano con nombre
```

- **La cuarta es la difícil y la que da valor.** Las reglas implícitas —qué significa un campo vacío,
  qué combinación de códigos implica qué— no están documentadas en ningún sitio y son lo que la ACL
  captura.
- **La traducción es bidireccional**: también convierte tus operaciones de dominio en el formato que
  el core espera, con sus validaciones y sus códigos.

**La señal de que funciona.** Dos comprobaciones objetivas:

```text
1. Cuando el core cambia, tocas SOLO la ACL.
2. Ningún término del core aparece en tu dominio. Si tu Cuenta tiene `codSitOper`,
   la corrupción ya entró.
```

**Cuándo sí.** Modelo ajeno hostil, inestable, o de un equipo con el que no tienes poder de
negociación. Es el caso del core por definición.

**Cuándo no.** Proveedor limpio y estable: ahí conformista —adoptar su modelo— es más barato y no
pagas el mapeo. La ACL no es gratis.

> **Veredicto:** la ACL es Adapter con ambición de arquitectura. Lo que la distingue es que traduce
> **significado**, no solo firmas, y por eso concentra el conocimiento que nadie documentó.

---

## 3. 🧱 Cómo se estructura

**Qué es.** Tres piezas separadas, y mezclarlas es el error habitual.

```text
CLIENTE TÉCNICO   → habla el protocolo: MQ, CICS, fichero, SOAP.
                    Solo transporte. No sabe nada de negocio.
MODELO EXTERNO    → los DTO que reflejan el formato del core, tal cual, con sus nombres feos.
                    Se generan del copybook o del WSDL si se puede.
TRADUCTOR         → aquí vive TODO el conocimiento: mapeo, reglas implícitas, decisiones.
                    Es el único sitio donde conviven los dos vocabularios.
        ↓
PUERTO DEL DOMINIO → la interfaz que tu dominio definió. Habla solo tu lenguaje.
```

- **El modelo externo se conserva tal cual**, con sus nombres horribles. Intentar "mejorarlo" a medio
  camino produce un tercer vocabulario que no es ni el suyo ni el tuyo.
- **El traductor es donde se documenta lo indocumentado.** Cada regla implícita va con un comentario
  que diga de dónde salió: *"si `IND1` viene en blanco, admite descubierto — confirmado con el equipo
  de core, 2026-03"*. Ese comentario vale más que el código.
- **Es un puerto de [`01-bases/03`](../01-bases/03-arquitecturas-de-aplicacion.md)**: el dominio
  define la interfaz, la ACL la implementa. La dirección de la dependencia importa.

> **Veredicto:** separar transporte, modelo externo y traducción es lo que permite que un cambio de
> protocolo —de MQ a API— no toque las reglas, y que un cambio de regla no toque el transporte.

---

## 4. 🧪 Probar contra algo que no puedes usar

**Qué es.** El problema práctico más subestimado: **el entorno de integración del banco va a estar
caído la mitad del tiempo**, va a tener datos distintos cada semana, y no lo controlas.

Las tres capas de prueba, y hacen falta las tres:

```text
1. Con respuestas REALES CAPTURADAS
   Se guardan respuestas reales del core —anonimizadas— como ficheros de prueba.
   El traductor se prueba contra ellas. Es lo que captura los casos raros de verdad.

2. Con un DOBLE del core
   Un servicio que responde como el core para los casos conocidos. Permite probar el
   flujo completo sin depender de su entorno.

3. Contra el entorno REAL, periódicamente
   Un conjunto pequeño de pruebas de contrato que se ejecutan cuando el entorno está vivo,
   para detectar que el core cambió algo.
```

- **La capa 1 es la que más valor da y la que menos se hace.** Las respuestas reales contienen los
  casos que nadie te contó: el campo que a veces viene con espacios, el importe negativo con signo al
  final, la respuesta de error con un formato distinto.
- **Anonimizar bien es parte del trabajo**: esas capturas contienen datos de clientes reales, y
  guardarlas en el repositorio sin anonimizar es una filtración.
- **La capa 3 es la que detecta la deriva.** El core cambia sin avisarte, y la única forma de
  enterarte antes que tus usuarios es una prueba periódica contra el entorno real.

> ⚠️ **Advertencia.** Probar solo contra el doble produce una ACL que funciona perfectamente con lo
> que **tú creías** que el core devuelve. La primera respuesta inesperada en producción revela la
> diferencia.

> **Veredicto:** las respuestas reales capturadas son la fuente de verdad, no la documentación. En un
> sistema de treinta años, el manual y el comportamiento divergieron hace mucho.

---
## 5. 🔧 Lo que la ACL acaba teniendo

**Qué es.** Lo que nadie planifica y todo el mundo acaba añadiendo, porque el core impone
restricciones que hay que absorber en algún sitio.

```text
CACHÉ            → muchos cores cobran por transacción o tienen capacidad limitada.
                   Cachear consultas repetidas es a menudo un requisito, no una optimización.
RESILIENCIA      → timeout, reintento con jitter y circuit breaker. El core se degrada.
MODO DEGRADADO   → qué haces durante la ventana batch. Decidido con negocio, no improvisado.
LIMITADOR        → el core puede tener un máximo de transacciones por segundo contratado.
                   Superarlo puede ser una penalización económica.
TRAZABILIDAD     → registrar qué se pidió y qué respondió, para la conciliación y la auditoría.
IDEMPOTENCIA     → si el core no la ofrece, la ACL la construye con una clave de negocio.
```

- **La caché con un core que cobra por transacción** es el caso donde la optimización tiene un número
  en euros. Es un argumento que funciona muy bien en una conversación con negocio.
- **El modo degradado durante la ventana** es lo que más se olvida: el core está cerrado cuatro horas
  y tu sistema tiene que hacer algo definido —encolar, mostrar el último dato conocido con su hora, o
  rechazar explícitamente—.

> 💰 **Costo.** La ACL deja de ser "un mapeador" y se convierte en un componente crítico con su
> propia observabilidad, su propio SLA y su propia guardia. Reconocerlo en el diseño evita la
> sorpresa.

> **Veredicto:** una ACL madura es caché, resiliencia, degradación, limitación e idempotencia además
> de traducción. Quien la presupuesta como "un mapeo" subestima el trabajo por un factor grande.

---

## 6. ⚖️ Cuándo NO poner una ACL

**Qué es.** La otra mitad de la decisión, porque la ACL tiene un precio real.

```text
Proveedor limpio y estable      → CONFORMISTA. Adopta su modelo y ahórrate el mapeo.
Una sola llamada, muy simple    → un adaptador normal basta; no hace falta la ceremonia.
Vas a sustituir el core en 6 meses→ la ACL sería trabajo tirado. Evalúa el plazo real
                                   (y en banca el plazo real nunca son 6 meses).
Tu dominio no tiene modelo propio→ si tu "dominio" es CRUD sobre los datos del core,
                                   la ACL traduce a un modelo que no aporta nada.
```

- **El último caso es el más común y el menos reconocido**: un servicio que solo expone datos del
  core no necesita un modelo propio, y forzarlo produce mapeo estéril. Es la misma discusión que el
  DTO entre capas internas de [`01-bases/05`](../01-bases/05-fowler-poeaa.md).
- El precio de la ACL: mapeo en dos sentidos, duplicación de conceptos, latencia añadida, y un
  componente más que operar.

> **Veredicto:** la ACL se justifica cuando tienes un modelo de dominio propio que proteger. Si no lo
> tienes, estás traduciendo de un modelo ajeno a otro ajeno con nombres distintos.

---

## 7. 🧭 Cómo se elige

```text
¿Tienes un modelo de dominio propio con invariantes que proteger?
    No  → no necesitas ACL. Adaptador simple, o conformista.
    Sí  → sigue.

¿El modelo del proveedor es hostil, inestable, o no puedes negociarlo?
    No, es limpio y estable → CONFORMISTA. Más barato, y suficiente.
    Sí                     → ACL.

Si pones ACL, sepárala en tres:
    cliente técnico (protocolo) · modelo externo (tal cual) · traductor (todo el conocimiento)

Y presupuéstala completa, no como un mapeo:
    caché · resiliencia · modo degradado durante la ventana · limitador
    · trazabilidad · idempotencia si el core no la da

Pruebas: las TRES capas.
    respuestas reales capturadas (anonimizadas) · doble del core · contrato contra el real
```

---

## ⚠️ Errores frecuentes

| Se dice | Lo preciso |
|---|---|
| "La ACL mapea campos" | Traduce **conceptos**, incluidas las reglas implícitas que nadie documentó |
| "Tenemos ACL" pero el dominio tiene `codSitOper` | La corrupción ya entró: la ACL es solo un nombre de paquete |
| "Probamos contra el doble" | Funciona con lo que creías que devuelve; usa respuestas reales capturadas |
| "Guardamos las respuestas de prueba" | Contienen datos de clientes: anonimizar es parte del trabajo |
| "Es un mapeador, es sencillo" | Acaba con caché, resiliencia, degradación y limitador: es crítico |
| "ACL siempre que haya un sistema externo" | Con un proveedor limpio, conformista es más barato |
| "El core no cambia" | Cambia sin avisarte; por eso hacen falta pruebas de contrato periódicas |

---

## 📚 Para profundizar

- **Libro** — Eric Evans, *Domain-Driven Design* (Addison-Wesley, 2003). Capítulo 14: la capa
  anticorrupción en su formulación original, con la distinción frente a conformista.
- **Libro** — Vlad Khononov, *Learning Domain-Driven Design* (O'Reilly, 2021). Capítulo 4: los
  patrones de relación entre contextos, con ejemplos modernos y el criterio para elegir.
- **Libro** — Michael Feathers, *Working Effectively with Legacy Code* (Prentice Hall, 2004). Las
  técnicas de costura y de caracterización: cómo se prueba algo cuyo comportamiento no está
  documentado, que es exactamente §4.
- Martin Fowler — [BoundedContext](https://martinfowler.com/bliki/BoundedContext.html): la frontera
  que la ACL protege.
- [microservices.io — Strangler application](https://microservices.io/patterns/refactoring/strangler-application.html):
  la ACL como pieza de la migración, no como fin en sí misma.
- [Spring Cloud Contract — Reference](https://docs.spring.io/spring-cloud-contract/reference/): cómo
  se convierte un contrato con el core en una prueba que falla el pipeline.
- [Debezium — Architecture](https://debezium.io/documentation/reference/stable/architecture.html):
  la vía para capturar cambios de un legado al que no puedes añadir una tabla de outbox.
- **Video** — Domain-Driven Design Europe y GOTO Conferences, charlas sobre capa anticorrupción y
  sobre convivencia con sistemas heredados. Búscalas por título.

---

## 🧠 Preguntas

Sin respuestas aquí. Todas, con enunciado literal y respuesta en tres capas, en
[`10` — Respuestas](10-respuestas.md).

1. ¿Qué es una capa anticorrupción? 🟢
2. ¿Qué cuatro cosas traduce una ACL? 🟢
3. ¿En qué tres piezas se estructura? 🟢
4. ¿Cuáles son las tres capas de prueba de una ACL? 🟢
5. ¿Qué es el patrón conformista? 🟢
6. ¿Cuáles son las dos señales de que una ACL funciona? 🟢
7. ¿Por qué el modelo externo se conserva con sus nombres feos? 🟡
8. ¿Por qué la traducción de semántica es la parte difícil? 🟡
9. ¿Por qué hay que anonimizar las respuestas capturadas? 🟡
10. ¿Qué detecta una prueba de contrato periódica contra el entorno real? 🟡
11. ¿Por qué la ACL suele acabar teniendo caché? 🟡
12. ¿Qué es el modo degradado durante la ventana batch? 🟡
13. ¿Cuándo es mejor conformista que ACL? 🟠
14. ¿Cuándo una ACL no aporta nada, aunque haya un sistema externo? 🟠
15. ¿Qué pasa si `codSitOper` aparece en tu dominio? 🟠
16. ¿Por qué probar solo contra el doble es insuficiente? 🟠
17. ¿Por qué la ACL acaba siendo un componente crítico? 🟠
18. ¿Qué información hay que documentar en el traductor y por qué? 🟠
19. ¿Por qué separar transporte, modelo externo y traducción? 🟠
20. ¿Qué argumento económico da la caché en la ACL? 🟠
21. Diseña la ACL sobre un core que expone consulta de saldo por CICS y
    ordenación de transferencias por MQ, con ventana de cierre de 4 horas. 🔴
22. Tu equipo dice tener una ACL, pero cada cambio del core obliga a tocar
    cinco servicios. Diagnostica y propón el camino de corrección. 🔴
23. Hay que integrar con un core del que nadie conoce las reglas y cuyo entorno
    de pruebas está caído la mitad del tiempo. ¿Cómo lo abordas? 🔴

---

**Anterior:** [`03` — Batch y Spring Batch](03-batch-y-spring-batch.md) ·
**Siguiente:** [`05` — ISO 20022, ISO 8583 y SWIFT](05-iso20022-y-mensajeria-financiera.md) ·
**Relacionado:** [`01-bases/06` — DDD estratégico](../01-bases/06-ddd-estrategico.md)
