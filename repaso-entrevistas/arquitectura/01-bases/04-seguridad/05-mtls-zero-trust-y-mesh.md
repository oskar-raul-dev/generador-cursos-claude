# 05 — mTLS, zero-trust y service mesh

> Cómo se verifica la identidad de un servicio sin gestionar credenciales en el código, qué dice
> de verdad el modelo zero-trust, y qué te da y qué te cuesta una malla de servicios. Es la capa
> de transporte de todo lo anterior.
> Asume leído [`04` — Propagación de identidad](04-propagacion-de-identidad.md).
>
> **Vigencia:** 2026-09-18.

---

## 1. 🎯 El problema

[`04`](04-propagacion-de-identidad.md) terminó con dos identidades: la del usuario y la del
servicio. La del usuario viaja en un token. **¿Y la del servicio?**

Las opciones obvias fallan:

```text
Credencial en variable de entorno → hay que distribuirla, rotarla y evitar que acabe en un log.
                                    Y si se filtra, cualquiera es ese servicio.
Lista de IP permitidas            → las IP cambian con cada despliegue en un orquestador.
                                    Y una IP no es una identidad: es una ubicación.
Red interna de confianza          → ya vimos que no es una frontera.
```

mTLS resuelve las tres: la identidad es un **certificado**, se verifica criptográficamente, y la
infraestructura puede emitirlo y rotarlo sin que tu código se entere.

> **Regla:** una dirección de red no es una identidad. La identidad es algo que se puede probar, y
> en una red eso significa criptografía.

---

## 2. 🤝 mTLS

**Qué es.** TLS mutuo: además de que el cliente verifique el certificado del servidor —lo normal en
HTTPS—, el **servidor verifica el del cliente**. Ambas partes prueban quién son.

```text
TLS normal  → el cliente comprueba: "este servidor es de verdad banco.com"
mTLS        → y además el servidor comprueba: "este cliente es de verdad el servicio Pagos"
```

**Lo que compra:**

- **Identidad criptográfica de servicio**, no una contraseña compartida. Nadie puede suplantar a
  `Pagos` sin su clave privada.
- **Cifrado en tránsito** dentro del clúster, que muchas normativas exigen y que la red interna no
  garantiza por sí sola.
- **Autorización por identidad**: `Riesgo` puede declarar "solo acepto llamadas de `Pagos` y
  `Originacion`", y eso lo aplica el transporte, no el código.

**Lo que cuesta, y es lo que se pregunta:**

```text
Emisión de certificados  → hace falta una CA interna y un proceso automático
Rotación                 → certificados de vida corta (horas); a mano es inviable
Distribución             → cada instancia necesita el suyo antes de arrancar
Revocación               → CRL y OCSP son incómodos; la vida corta es la mitigación real
Depuración               → un fallo de handshake es opaco comparado con un 401
```

- **La vida corta sustituye a la revocación.** Con certificados de una hora, revocar es dejar de
  renovar. Es el mismo razonamiento que la caducidad corta del JWT en
  [`03`](03-oauth2-oidc-y-jwt.md).
- **Todo eso es exactamente lo que automatiza una malla de servicios**, y es su argumento principal.

**Cuándo sí.** Comunicación entre servicios en un entorno con orquestador, dominios regulados,
y cuando el cifrado interno es requisito.

**Cuándo no.** Sistemas pequeños sin orquestador, donde montar y operar una CA interna cuesta más
de lo que el riesgo justifica. Ahí, Client Credentials sobre TLS normal es una respuesta honesta.

> 💡 **Truco.** El detalle que demuestra uso real: **atar el token al certificado** (RFC 8705). El
> access token queda ligado al certificado del cliente, así que robarlo no basta: hay que robar
> también la clave privada. Es lo que Open Banking exige en Europa, y enlaza con
> [`06-banca/06`](../05-banca/).

> **Veredicto:** mTLS da identidad de servicio sin credenciales en el código, y su coste real no es
> el protocolo: es el ciclo de vida de los certificados. Quien no ha operado eso subestima el
> problema.

---

## 3. 🚧 Zero-trust

**Qué es.** Un modelo, no un producto. Su enunciado, en la formulación del NIST (SP 800-207):

> **Nunca confíes, verifica siempre.** La ubicación en la red no otorga confianza.

Los principios que lo componen:

```text
1. Sin confianza implícita por ubicación → estar dentro no da permisos
2. Verificación en cada petición         → no en el borde, y no una sola vez
3. Mínimo privilegio, con caducidad      → y por recurso, no por zona
4. Asume la brecha                       → diseña como si el atacante ya estuviera dentro
5. Todo se registra y se inspecciona     → para poder responder qué pasó
```

**Lo que sustituye.** El modelo de perímetro —"castillo y foso"— donde el cortafuegos separa fuera
de dentro y todo lo de dentro se confía. Ese modelo falla porque una sola brecha da acceso lateral
a todo, y porque con nube, trabajo remoto y servicios gestionados el perímetro ya no existe.

**Cómo se materializa**, que es lo que evita que suene a folleto:

| Principio | Mecanismo concreto |
|---|---|
| Identidad de servicio | mTLS con certificados de vida corta |
| Identidad de usuario | Token validado en cada salto, con `aud` acotado |
| Autorización por petición | PEP en cada servicio, PDP con políticas declarativas |
| Mínimo privilegio | Scopes acotados, token exchange, permisos con caducidad |
| Asumir la brecha | Segmentación, radio de daño acotado, detección |

> ⚠️ **Advertencia.** "Hacemos zero-trust" sin poder nombrar los mecanismos es la respuesta que más
> suena a marketing en todo el bloque. La buena es: *"zero-trust significa que este servicio
> verifica quién llama y en nombre de quién, en cada petición, aunque venga de dentro"*.

> **Veredicto:** zero-trust no se compra, se implementa. Y su consecuencia práctica más importante
> es que **la red deja de ser un control de seguridad** y pasa a ser solo transporte.

---

## 4. 🕸️ Service mesh

**Qué es.** Una capa de infraestructura que intercepta todo el tráfico entre servicios mediante un
**sidecar** —un proxy junto a cada instancia— y le aplica políticas sin tocar el código.

```text
[ Pagos ] ←→ [ sidecar ] ←═ mTLS ═→ [ sidecar ] ←→ [ Riesgo ]
                  ↑                        ↑
              plano de control: políticas, certificados, telemetría
```

**Lo que te da sin escribir código:**

```text
mTLS automático        → emisión, rotación y renovación de certificados
Autorización L7        → "solo Pagos puede llamar a POST /riesgo/evaluar"
Observabilidad         → métricas, trazas y logs de cada llamada, uniformes
Resiliencia            → timeouts, reintentos, circuit breaker en el proxy
Control de tráfico     → canario, espejo, división por porcentaje
```

- Los tres últimos solapan con lo que ya haces en el código con Resilience4j y con trazas. La
  malla los mueve a infraestructura y los hace **uniformes entre lenguajes**, que es su argumento
  cuando hay políglota.

**Lo que cuesta:**

- **Un proxy más por instancia**: latencia añadida —del orden de un milisegundo por salto, y son
  dos saltos— y consumo de CPU y memoria multiplicado por el número de instancias.
- **Complejidad operativa alta.** Depurar con un sidecar en medio es notablemente más difícil, y el
  plano de control es un componente crítico nuevo.
- **Curva de aprendizaje**: la configuración de Istio es extensa, y un error en una política de
  autorización corta tráfico de producción.
- Las alternativas modernas —modo sin sidecar, o mallas ligeras— reducen parte del coste y no todo.

**Cuándo sí.** Muchos servicios, varios lenguajes, requisito de cifrado interno y autorización
uniforme, y un equipo de plataforma que la opere.

**Cuándo no.** Pocos servicios, un solo lenguaje, o sin equipo de plataforma. Con cinco servicios en
Java, una librería compartida da resiliencia y trazas, y mTLS se puede resolver en el ingreso y con
Client Credentials hacia dentro.

> 💰 **Costo.** Una malla no es una dependencia, es una **plataforma**: necesita gente que la
> entienda, la actualice y la diagnostique. Es la misma conversación que Kafka en
> [`02-eventos/02`](../02-eventos/02-brokers-comparados.md).

> **Veredicto:** la malla se justifica por **uniformidad entre lenguajes y por mTLS automático**,
> no por resiliencia —eso ya lo tienes en la librería— ni por moda. Si todo es Java, el argumento
> se reduce mucho.

---

## 5. 🧱 Segmentación y radio de daño

**Qué es.** El principio de "asume la brecha" convertido en diseño: si alguien entra, ¿hasta dónde
llega?

```text
Segmentación de red   → los servicios solo alcanzan a los que necesitan (NetworkPolicy)
Autorización L7       → y solo los endpoints que necesitan
Identidades separadas → cada servicio con su propia identidad y sus propios permisos
Datos segmentados     → cada servicio con su base de datos y sus propias credenciales
Secretos por servicio → una credencial comprometida no abre las demás
```

- **La pregunta de arquitectura es siempre la misma**: si `Notificaciones` se compromete, ¿qué
  alcanza? Si la respuesta es "todo", la segmentación no existe.
- En la nube, un caso concreto que hay que nombrar: el **endpoint de metadatos de la instancia**.
  Un SSRF que lo alcance obtiene credenciales de la infraestructura. Bloquearlo es una de las
  medidas con mejor relación coste/beneficio que existen.

> **Veredicto:** la segmentación no impide la brecha, acota su alcance. Y es lo que convierte un
> incidente en un servicio comprometido en vez de en una plataforma comprometida.

---

## 6. 🧭 Cómo se elige

```text
¿Cómo doy identidad a los servicios?
    ¿Hay orquestador y equipo de plataforma?      → mTLS, idealmente automatizado por la malla
    ¿No lo hay?                                   → Client Credentials sobre TLS. Es honesto.
    ¿Dominio regulado o cifrado interno exigido?  → mTLS, no es opcional
    ¿Open Banking o equivalente?                  → mTLS + token atado al certificado (RFC 8705)

¿Service mesh?
    ¿Varios lenguajes y muchos servicios?  → sí: la uniformidad es su argumento real
    ¿Todo Java y pocos servicios?          → probablemente no: librería compartida + mTLS en ingreso
    ¿Hay equipo de plataforma?             → si no, NO. Una malla sin quien la opere es un riesgo.

¿Y zero-trust?
    → No es una decisión, es el modelo. Se materializa en:
      identidad de servicio · token validado en cada salto · autorización por petición
      · mínimo privilegio con caducidad · segmentación · registro completo
```

---

## ⚠️ Errores frecuentes

| Se dice | Lo preciso |
|---|---|
| "Hacemos zero-trust" | ¿Con qué mecanismos? Sin nombrarlos es marketing |
| "La red interna está segura" | Zero-trust empieza por negar exactamente eso |
| "mTLS es TLS con certificado" | Es TLS donde **ambas** partes se verifican |
| "Con la malla ya no necesito autorizar en el servicio" | La malla autoriza la **llamada**; el objeto lo autoriza el servicio |
| "Instalamos Istio y tenemos seguridad" | Tienes transporte cifrado y políticas L7; la autorización de dominio sigue siendo tuya |
| "Revocamos certificados con CRL" | En la práctica se usan certificados de vida corta |
| "Una IP permitida identifica al servicio" | Una IP es una ubicación, no una identidad, y cambia en cada despliegue |

---

## 📚 Para profundizar

- **Libro** — Prabath Siriwardena y Nuwan Dias, *Microservices Security in Action* (Manning,
  2020). Capítulos 6 y 12: mTLS entre servicios y seguridad en el despliegue.
- **Libro** — Christian Posta y Rinor Maloku, *Istio in Action* (Manning, 2022). Capítulos 4 y 9:
  qué hace el sidecar y cómo se configuran mTLS y las políticas de autorización.
- **Libro** — Evan Gilman y Doug Barth, *Zero Trust Networks*, 2ª ed. (O'Reilly, 2024). El modelo
  completo, con la crítica al perímetro y los mecanismos que lo sustituyen.
- [NIST SP 800-207 — Zero Trust Architecture](https://csrc.nist.gov/pubs/sp/800/207/final): la
  formulación canónica, con PEP y PDP y los principios de §3.
- [Istio — Security concepts](https://istio.io/latest/docs/concepts/security/): identidad, mTLS y
  políticas de autorización explicadas por el proyecto.
- [RFC 8705 — mTLS Client Authentication and Certificate-Bound Access Tokens](https://datatracker.ietf.org/doc/html/rfc8705):
  cómo se ata un token a un certificado y por qué robarlo deja de bastar.
- [Spring Security — Reference](https://docs.spring.io/spring-security/reference/index.html):
  configuración de TLS cliente y de servidor de recursos en Spring.
- **Video** — GOTO Conferences y KubeCon, charlas sobre service mesh y sobre el coste real del
  sidecar. Búscalas por título.

---

## 🧠 Preguntas

Sin respuestas aquí. Todas, con enunciado literal y respuesta en tres capas, en
[`08` — Respuestas](08-respuestas.md).

1. ¿Qué es mTLS? 🟢
2. ¿Qué dice el modelo zero-trust? 🟢
3. ¿Qué es un service mesh y qué es el sidecar? 🟢
4. Nombra tres cosas que da una malla sin escribir código. 🟢
5. ¿Qué es la segmentación de red? 🟢
6. ¿Por qué una IP no es una identidad? 🟡
7. ¿Qué tres problemas resuelve mTLS que las alternativas no? 🟡
8. ¿Por qué los certificados de mTLS son de vida corta? 🟡
9. ¿Qué modelo sustituye zero-trust y por qué falló? 🟡
10. ¿Qué es atar un token a un certificado y qué resuelve? 🟡
11. ¿Cuál es el coste concreto de un sidecar? 🟠
12. ¿Por qué el endpoint de metadatos de la nube es un objetivo? 🟠
13. ¿Cuál es el coste real de mTLS, más allá del protocolo? 🟠
14. ¿Por qué "hacemos zero-trust" sin mecanismos es una mala respuesta? 🟠
15. ¿Qué autoriza la malla y qué sigue autorizando el servicio? 🟠
16. ¿Cuándo NO usarías un service mesh? 🟠
17. ¿Cuál es el argumento real de una malla si todo es Java? 🟠
18. ¿Cómo se sustituye la revocación de certificados en la práctica? 🟠
19. ¿Qué pregunta mide si tu segmentación existe? 🟠
20. ¿Por qué la red deja de ser un control de seguridad en zero-trust? 🟠
21. Diseña la identidad de servicio de una plataforma bancaria de 15 servicios
    en Kubernetes, con cifrado interno exigido por normativa. 🔴
22. Te proponen Istio para cinco servicios Java mantenidos por un equipo de
    seis personas. ¿Qué respondes y qué propones? 🔴
23. Un SSRF en un servicio permitió obtener credenciales de la infraestructura.
    Reconstruye el fallo y las medidas, inmediatas y de fondo. 🔴

---

**Anterior:** [`04` — Propagación de identidad](04-propagacion-de-identidad.md) ·
**Siguiente:** [`06` — Secretos y criptografía](06-secretos-y-criptografia.md) ·
**Relacionado:** [`01-bases/09` — Resiliencia](../01-bases/09-resiliencia.md)
