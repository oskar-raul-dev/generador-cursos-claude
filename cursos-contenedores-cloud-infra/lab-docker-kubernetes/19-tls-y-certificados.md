# 🔐 Fase 19 — TLS y certificados: la cadena de confianza, de una vez

> **Curso:** Laboratorio de contenedores y Kubernetes local · Fase 19 de 27 · Parte III — Operarlo · **densa** ⭐
> **Perfil:** el cluster `lab` (control-plane y dos workers), con los valores de `minimo` · **Observabilidad encendida:** ninguna (la fase la apaga para darle memoria a cert-manager)
> **Motor de referencia:** Docker · 🦭 **diverge en el registry**: Podman valida la CA también en `localhost`, y Docker no
> **Servicios que toca:** `inventory` y `pricing`; la puerta · **Paso de generación:** G8 · Cliente mTLS
> **Depende de:** [Fase 18](18-logs.md) · **Habilita:** [Fase 20](20-seguridad-del-pod-y-de-la-red.md)
> **Incidentes que reserva:** 18, 19, 20, 21, 22, 23, 24 · **Medición:** ninguna con identificador; las de esta fase quedan en sus secciones
> **Apéndices de apoyo:** [a01](a01-el-laboratorio.md), [a03](a03-contratos-y-prompts-de-generacion.md), [a04](a04-kubectl-y-k9s.md), [a05](a05-diccionarios.md)
> **Fecha de verificación ejecutada:** 04/10/2026 · macOS arm64
> **Objetivo:** entender quién confía en quién cuando un navegador, un servicio o un nodo abren una conexión cifrada; que la puerta tenga un certificado que se renueva solo; que `inventory` y `pricing` se reconozcan mutuamente; y saber arreglar cada uno de los siete errores de certificado del cuaderno.

---

## 🧭 1. Dónde estamos

Las fases 17 y 18 dejaron un sistema que se deja mirar: métricas y logs. Pero todo viaja en texto plano.
La puerta escucha en `http://`, y entre los pods, las ventas, los precios y las contraseñas de las bases
cruzan la red del cluster sin cifrar.

En La Vecina, los certificados tienen mala fama por una buena razón. El proxy corporativo inspecciona
todo el tráfico cifrado con un certificado propio desde 2006, y el lector lo conoció en el incidente 27,
el primer día. Y hay una historia que el área comercial cuenta todavía: el domingo en que el certificado
del portal de afiliados del Club Vecinos se venció, y se enteraron **por las quejas de los clientes**
(historia §6). Nadie había anotado la fecha. El vicepresidente comercial se lo recuerda a Valentina en la
reunión de esta fase:

> *"Lo único que le pido es que eso no vuelva a pasar un domingo. Que se renueve solo, o que alguien se
> entere el jueves."*

Valentina le contesta con lo que trae esta fase: un emisor que renueva solo, y un laboratorio con los
siete errores de certificado más comunes, para que el equipo los reconozca por el síntoma antes de que
llegue el domingo.

---

## 🎯 2. Objetivos de esta fase

1. Entender la cadena de confianza: qué es una CA, qué firma, qué valida el cliente y con qué nombre.
2. Crear una CA propia y el certificado de la puerta a mano, y servir `https://` en el 8443.
3. Instalar cert-manager con la CA como emisor, y medir una renovación con tráfico.
4. Repartir la CA a los pods con trust-manager.
5. Generar G8: `inventory` y `pricing` con TLS mutuo.
6. Confiar en un registry propio con CA, en los tres sitios donde hay que hacerlo.

---

## 🚫 3. Qué NO entra todavía

- **ACME y Let's Encrypt.** Emiten para dominios públicos que se pueden verificar desde internet;
  `*.localhost` no lo es. El patrón de cert-manager es el mismo con otro emisor, y se nombra en el veredicto.
- **mTLS con un service mesh**, que pone certificados en todos los pods sin tocar el código → [a10](a10-service-mesh.md).
- Revocación (CRL y OCSP), rotación de la CA y HSTS: existen, y en un laboratorio no enseñan nada que se
  pueda medir.
- **La página por HTTPS.** El `storefront` sigue en `http://`, porque su configuración apunta la API a
  `http://api.localhost:8080`: servida por HTTPS, el navegador bloquearía esas llamadas (contenido mixto).
  Es un ejercicio.
- La confianza en el llavero del host: instalada y verificada con `security verify-cert`; el navegador y la desinstalación, sin verificar (sección 5.3).

---

## 🧨 4. El problema, en el laboratorio

Dos preguntas, y ninguna tiene buena respuesta con el sistema de la [Fase 18](18-logs.md).

**¿Quién está del otro lado?** `inventory` le pide un precio a `http://pricing.apps.svc.cluster.local:8080`
y cree lo que le contesten. Cualquier pod del cluster puede contestar en ese nombre si alguien cambia el
`Service`, y cualquier pod puede pedirle a `pricing` que cambie un precio: no hay forma de saber quién
pidió.

**¿Quién lo está leyendo?** El navegador del regente habla con la puerta en texto plano, y la puerta con los
servicios, también:

```text
$ curl -sS https://api.localhost:8443/pricing/prices?store=DRO-007
curl: (35) LibreSSL SSL_connect: SSL_ERROR_SYSCALL in connection to api.localhost:8443
```

El 8443 del host llega al nodo desde la [Fase 07](07-el-cluster-local.md) (el contrato lo reservó), y del otro lado no hay nadie
que hable TLS: la conexión se corta en el saludo.

> 🩻 **Esto sí funciona igual.** Un certificado es un certificado: el mismo archivo PEM que pones en un nginx
> de compose o en un WebLogic lo usa la puerta del cluster. Lo que cambia es dónde vive (un `Secret`) y
> quién lo renueva.

---

## 🧩 5. TLS, a mano y después solo

### 5.1 La cadena de confianza, de una vez

Una conexión TLS empieza con el servidor mostrando su certificado. El cliente se hace tres preguntas, y si
alguna falla, corta:

1. **¿Lo firmó alguien en quien confío?** El certificado dice quién lo firmó (el *issuer*). El cliente
   busca ese firmante en su lista de autoridades de confianza (las CA raíz de su sistema, o la que le
   pases con `--cacert`). Si no está, `unable to get local issuer certificate` o `certificate signed by
   unknown authority`, según quién lo diga.
2. **¿Vale hoy?** Entre `notBefore` y `notAfter`. Si no, `certificate has expired`.
3. **¿Es para el nombre al que llamé?** El nombre de la URL tiene que estar en la extensión *Subject
   Alternative Name* (SAN). El *Common Name* no cuenta hace años. Si no está, `no alternative certificate
   subject name matches target host name`.

Y una cuarta, que el cliente no ve pero el servidor sí: **la clave privada tiene que corresponder al
certificado**, o el servidor no puede probar que es el dueño. Cada pregunta es un incidente del cuaderno
(18, 19, 20 y 21).

Con **TLS mutuo** (mTLS), el servidor también le pide al cliente un certificado y se hace las mismas
preguntas. Eso es G8.

> 🧠 **Quién valida a quién, en este laboratorio.** La pregunta que ordena todo lo demás es *quién es el
> cliente*, porque cada cliente tiene su propia lista de autoridades de confianza, y la CA hay que ponerla
> en la de ese cliente:
>
> | Cliente → servidor | Con qué CA valida | Dónde se pone |
> |---|---|---|
> | tu navegador o `curl` → la puerta (8443) | las del sistema operativo, o `--cacert` | el llavero del host (sección 5.3) |
> | la puerta → los servicios | ninguna: la puerta termina el TLS y les habla en HTTP | — |
> | `inventory` → `pricing` (8443) | la CA que reparte trust-manager | el `ConfigMap` `lab-ca`, montado (sección 5.6) |
> | `pricing` → el certificado de `inventory` | la misma | el mismo `ConfigMap` |
> | el containerd de un nodo → el registry | la de `certs.d/<registry>/` | cada nodo (sección 5.7) |
> | el motor del host → el registry en `localhost` | Docker: ninguna (lo trata como inseguro); Podman: la de su máquina | la máquina de Podman |
>
> La mitad de los errores de certificado de un equipo nuevo son una CA bien hecha, puesta en la lista del
> cliente equivocado.

**Terminar o pasar.** La puerta de este laboratorio **termina** el TLS (`mode: Terminate`): descifra, mira la
ruta y le pasa HTTP al servicio. Es lo que permite rutear por prefijo y aplicar CORS, y significa que entre la
puerta y el pod el tráfico va en claro, dentro de la red del cluster. La alternativa es `Passthrough`: la puerta
reenvía el TLS sin abrirlo, rutea solo por el nombre que el cliente anuncia en el saludo (SNI), y el pod tiene
su propio certificado. Se gana cifrado de punta a punta; se pierde todo lo que la puerta hacía mirando la
petición. Para las llamadas entre servicios, esta fase elige un tercer camino: TLS mutuo entre los dos pods, sin
la puerta en el medio.

### 5.2 La CA y el certificado de la puerta, a mano

`scripts/tls/certs.py` arma la CA y los certificados que firma, con la biblioteca `cryptography` de
Python (un solo script para los tres sistemas; no depende de que haya `openssl`). Todo queda en
`.secrets/tls/`, fuera de git:

```bash
task tls:ca              # la CA, una vez: La Rebotica · CA del laboratorio, diez años
task tls:gateway -- lab  # el certificado de la puerta, y el Secret lab-tls en gateway
```

El certificado de la puerta lleva en el SAN los seis nombres que la puerta sirve:

```text
$ openssl x509 -in .secrets/tls/gateway.crt -noout -ext subjectAltName
X509v3 Subject Alternative Name:
    DNS:api.localhost, DNS:storefront.localhost, DNS:grafana.localhost, DNS:prometheus.localhost,
    DNS:api.tenant-b.localhost, DNS:storefront.tenant-b.localhost
```

`task tls:gateway` lo sube como `Secret` de tipo `kubernetes.io/tls` (dos claves, `tls.crt` y `tls.key`).
La puerta agrega un listener HTTPS que lo usa, y el `EnvoyProxy` publica su NodePort fijo, el 30443 que kind
ya mapea al 8443 del host:

```yaml
- name: https
  protocol: HTTPS
  port: 8443
  tls:
    mode: Terminate          # la puerta descifra; a los servicios les llega HTTP
    certificateRefs:
      - kind: Secret
        name: lab-tls
```

Las rutas no cambian: una `HTTPRoute` sin `sectionName` cuelga de todos los listeners de su puerta.

```text
$ curl -sS -o /dev/null -w "%{http_code}\n" --cacert .secrets/tls/ca.crt 'https://api.localhost:8443/pricing/prices?store=DRO-007'
200
$ curl -sS -o /dev/null 'https://api.localhost:8443/pricing/prices?store=DRO-007'
curl: (60) SSL certificate problem: unable to get local issuer certificate
```

Con la CA, 200. Sin ella, la primera pregunta de la sección 5.1. Y una observación que la sección 5.4 vuelve a
usar: cuando el `Secret` cambió (la CA se regeneró y el certificado con ella), **la puerta sirvió el nuevo en
menos de cinco segundos, sin reiniciar nada**. Envoy Gateway vigila los `Secret` de sus listeners.

### 5.3 La confianza en el host

Para que el navegador acepte `https://api.localhost:8443` sin aviso, la CA tiene que estar entre las
autoridades de confianza del sistema. Es un cambio en tu máquina, y se deshace igual. En macOS, la forma
corta usa el llavero de tu usuario y pide tu contraseña en un diálogo:

```bash
security add-trusted-cert -r trustRoot -p ssl -k ~/Library/Keychains/login.keychain-db .secrets/tls/ca.crt
```

Para quitarla se necesitan dos pasos: `remove-trusted-cert` quita la confianza, pero el certificado se
queda en el llavero hasta que lo borras con `delete-certificate`. El paso a paso está en
[a01](a01-el-laboratorio.md#-la-ca-del-laboratorio-en-el-llavero): cómo comprobar antes y después con
`security verify-cert`, cómo quitarla aunque ya hayas regenerado el `ca.crt`, la variante para todos los
usuarios, y Linux y Windows.

> ⚠️ **Lo verificado, y lo que no.** En la máquina del autor, la confianza se verificó con `curl
> --cacert` y con `openssl s_client -CAfile`. La instalación en el llavero `login` la hizo el dueño de la
> máquina, no la sesión de laboratorio, porque una CA raíz de confianza puede firmar un certificado para
> cualquier sitio. Después de instalarla, `security verify-cert` valida el certificado de la puerta sin
> ancla explícita (a01). La prueba en el navegador y la desinstalación quedaron sin ejecutar. Firefox
> tiene su propio almacén, y no lee el del sistema salvo que se lo pidas.

Esto es lo mismo que hace el área de TI con el certificado del proxy corporativo (incidente 27): instalar una
CA en cada portátil. Ahora sabes qué poder le estás dando.

### 5.4 cert-manager: el que renueva

Un certificado hecho a mano vence el día que dice, y alguien tiene que acordarse. **cert-manager** es el
controlador que se acuerda: tú declaras qué certificado quieres (un `Certificate`) y quién lo firma (un
`Issuer` o `ClusterIssuer`), y él lo emite, lo guarda en un `Secret` y lo renueva antes de que venza.

```bash
task platform:certs -- lab     # cert-manager y trust-manager (versiones de a01, imágenes por digest),
                               # la CA como Secret del emisor, el ClusterIssuer y el Certificate de la puerta
```

El emisor es la misma CA de la sección 5.2, ahora en manos de cert-manager:

```yaml
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: lab-ca
spec:
  ca:
    secretName: lab-ca        # en el namespace cert-manager: la clave privada de la CA vive solo ahí
---
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: lab-tls
  namespace: gateway
spec:
  secretName: lab-tls         # el mismo Secret que la puerta ya usa
  duration: 24h
  renewBefore: 8h
  dnsNames: [api.localhost, storefront.localhost, …]
  issuerRef: {kind: ClusterIssuer, name: lab-ca}
```

El `Certificate` toma el `Secret` hecho a mano **en un segundo** (`Issuing certificate as Existing issued
Secret is not up to date for spec`) y la puerta, otra vez, lo sirve sin enterarse.

**La renovación, con tráfico.** Con el `Certificate` en una hora de duración y renovación a los 55 minutos,
un script hizo cinco peticiones HTTPS por segundo durante ocho minutos, validando con la CA y anotando el
serial del certificado servido cada vez que cambiaba:

```text
    0.0s 14:53:45 certificado servido: serial 536B346BEB8AA65B…
  299.4s 14:58:45 certificado servido: serial 27C75A5D4211D876…
fin: 2226 bien, 0 mal
Renewing certificate as renewal was scheduled at 2026-10-04 19:58:45 +0000 UTC
reinicios del proxy antes: 10 9 · después: 10 9
```

**El certificado nuevo, servido en el mismo segundo de la renovación; ninguna petición fallida; ningún
reinicio.** Es la respuesta al vicepresidente comercial: el domingo no vuelve a pasar, si cada certificado lo
emite un controlador que lo renueva solo.

### 5.5 trust-manager: la CA para los pods

Los pods que validan a otros (en G8, `inventory` valida a `pricing`) necesitan la CA. Copiarla a cada
imagen es lo que se hacía con el proxy corporativo, y envejece mal. **trust-manager** la reparte: lee la
parte pública de la CA y escribe un `ConfigMap` en cada namespace que se lo pida.

```yaml
apiVersion: trust.cert-manager.io/v1alpha1
kind: Bundle
metadata:
  name: lab-ca
spec:
  sources:
    - secret: {name: lab-ca, key: tls.crt}     # solo el certificado; la clave no sale de cert-manager
  target:
    configMap: {key: ca.crt}
    namespaceSelector:
      matchLabels: {app.kubernetes.io/part-of: lab}
```

```text
$ kubectl get configmap -A | grep lab-ca
apps                 lab-ca   1   6s
data                 lab-ca   1   6s
observability        lab-ca   1   6s
```

Tres namespaces, los que llevan la label del sistema. Si la CA cambia, los tres `ConfigMap` cambian.

### 5.6 G8: `inventory` y `pricing`, con TLS mutuo

El prompt de G8 está en [a03](a03-contratos-y-prompts-de-generacion.md#-el-prompt-de-g8). `pricing` abre un segundo listener en el 8443, con TLS que
**exige** certificado de cliente firmado por la CA del laboratorio; el 8080 sigue en HTTP para la puerta, las
sondas y Prometheus. El certificado del servidor lo lee de sus archivos en cada saludo y lo vuelve a cargar si
cambian, porque cert-manager lo va a renovar:

```go
TLSConfig: &tls.Config{
	MinVersion:     tls.VersionTLS12,
	GetCertificate: reloader.get,                     // relee el archivo si cert-manager lo renovó
	ClientAuth:     tls.RequireAndVerifyClientCert,  // sin certificado de cliente, no hay conexión
	ClientCAs:      clientCAs,                       // la CA que reparte trust-manager
},
```

En el chart, un interruptor (`global.mtls.enabled`, encendido desde esta fase) agrega dos `Certificate`
—el de servidor de `pricing` y el de cliente de `inventory`, cada uno con su `usages`—, monta sus `Secret` y
el `ConfigMap` `lab-ca`, y le da a `inventory`, y solo a él, otra dirección de `pricing`:

```text
PRICING_URL: https://pricing.apps.svc.cluster.local:8443
```

La primera versión la cambiaba en el `ConfigMap` de vecinos, que leen todos. El seed de la segunda cadena, que
también lee esa dirección para cargar los precios, empezó a fallar con `CERTIFICATE_VERIFY_FAILED`: la
[Fase 20](20-seguridad-del-pod-y-de-la-red.md) lo encontró al instalarla. Una variable del `Deployment` gana sobre la del `ConfigMap`.

```bash
task build -- pricing && task build -- inventory   # :g8
task images:load -- lab
task deploy CLUSTER=lab -- minimo
task conformance TARGET=cluster PROFILE=lab -- G8
```

```text
Success /suite/inventory.g8.hurl (3 request(s) in 397 ms)
{"time":"…","level":"INFO","msg":"pricing escuchando con mTLS en :8443","service":"pricing"}
{"time":"…","level":"INFO","msg":"request","service":"pricing","uri":"/prices/{sku}",…,"request_id":"g8-conformance-venta"}
```

La suite no puede ver la otra mitad: que **sin certificado, no se entra**. Desde un pod de prueba en `apps`,
con la CA pero sin certificado de cliente:

```text
(56) OpenSSL SSL_read: OpenSSL/3.5.6: error:0A00045C:SSL routines::tlsv13 alert certificate required, errno 0
```

Y en el log de `pricing`, una advertencia del saludo y **ninguna línea `request`**: la conexión se cortó
antes de llegar al código.

```json
{"time":"…","level":"WARN","msg":"http: TLS handshake error from 10.244.2.177:47762: tls: client didn't provide a certificate","service":"pricing"}
```

### 5.7 El registry con CA propia: tres sitios

Un registry propio sirve las imágenes por HTTPS, con su certificado. El de esta fase corre en un contenedor
en la red de kind, con un certificado firmado por la CA del laboratorio, y se llama `lab-registry` desde los
nodos y `localhost:5001` desde el host:

```bash
task registry:up           # registry:3 por digest, con el certificado de la CA
task registry:push -- pricing
```

Hay **tres** clientes que hablan con él, y cada uno confía por su cuenta:

1. **El motor del host**, que hace el `push`. Con Docker, pasa sin confiar en nada:

   ```text
   $ docker info --format '{{.RegistryConfig.InsecureRegistryCIDRs}}'
   [::1/128 127.0.0.0/8]
   ```

   Docker trata todo `127.0.0.0/8` como registry inseguro y no valida el certificado. 🦭 **Podman no hace esa
   excepción**: el mismo `push` falla con `x509: certificate signed by unknown authority` hasta poner la CA
   **dentro de su máquina** (`~/.config/containers/certs.d/localhost:5001/ca.crt`, en modo sin root). Eso se
   verificó en la preparación del curso, el 03/10/2026, y no se repitió en esta fase.

2. **El containerd de cada nodo**, que hace el `pull`:

   ```text
   Failed to pull image "lab-registry:5000/lab/pricing:g8": … failed to do request: Head
   "https://lab-registry:5000/v2/lab/pricing/manifests/g8": tls: failed to verify certificate:
   x509: certificate signed by unknown authority
   ```

   Se arregla en cada nodo, con la CA y un `hosts.toml` en `/etc/containerd/certs.d/lab-registry:5000/`.
   Los archivos de kind activan esa carpeta desde la [Fase 07](07-el-cluster-local.md) (`config_path`), y por eso no hay que recrear el
   cluster ni reiniciar containerd:

   ```bash
   task registry:trust -- lab      # 1,1 s para los tres nodos; el pull siguiente pasa en 141 ms
   ```

3. **Los clientes del host** (`curl`, el navegador, `skopeo`): `curl: (60) SSL certificate problem: unable to
   get local issuer certificate` hasta `--cacert` o la confianza de la sección 5.3.

**Y una trampa que salió al probarlo**, sin buscarla. Después de traer `pricing:g8` del registry a un nodo,
el `Job` de migraciones de `pricing` —que usa la imagen `lab/pricing:g8`, cargada con `kind load`, **el mismo
digest**— empezó a fallar en ese nodo con `pull access denied`, con la imagen ahí:

```json
{"kind":"ImagePulledRecord","imageRef":"sha256:779857bd6c62…",
 "credentialMapping":{"lab-registry:5000/lab/pricing":{"nodePodsAccessible":true}}}
```

En las versiones recientes de Kubernetes (en la 1.36 del laboratorio, activo por defecto), el kubelet anota de
dónde trajo cada imagen y con qué credenciales, y antes de dejar que un pod use una imagen que **trajo** de un
registry, verifica que ese pod tenga acceso al nombre que pide.
La imagen cargada con `kind load` era la misma, pero el registro decía que se había traído de
`lab-registry`, y para `docker.io/lab/pricing` el kubelet quiso verificar contra Docker Hub. Borrar el
registro no alcanzó: hubo que reiniciar el kubelet de ese nodo. La lección no es el comando: **una imagen con
dos nombres en el mismo nodo ya no es una sola cosa para el kubelet**. Se elige un camino —el registry o
`kind load`— y se sigue.

---

## 🔁 6. Del otro lado: el cliente en Java

`pricing` resolvió su mitad con la biblioteca estándar de Go. La de `inventory` es la que enseña algo del
ecosistema: **Spring Boot trae los *SSL bundles***, un nombre que agrupa un certificado, una clave y una CA, y
que se configura con propiedades. El chart las pone como variables:

```yaml
- {name: SPRING_SSL_BUNDLE_PEM_PRICING_KEYSTORE_CERTIFICATE, value: "file:/etc/tls/client/tls.crt"}
- {name: SPRING_SSL_BUNDLE_PEM_PRICING_KEYSTORE_PRIVATEKEY, value: "file:/etc/tls/client/tls.key"}
- {name: SPRING_SSL_BUNDLE_PEM_PRICING_TRUSTSTORE_CERTIFICATE, value: "file:/etc/tls/ca/ca.crt"}
- {name: SPRING_SSL_BUNDLE_PEM_PRICING_RELOADONUPDATE, value: "true"}
```

Lee PEM directamente: nada de convertir a JKS o PKCS12, que es lo que el instinto de quien viene de WebLogic
espera. Con el bundle, el cliente de `pricing` es un `HttpClient` del JDK con el `SSLContext` que arma Spring:

```java
SslBundles bundles = sslBundles.getObject();
this.pricing = client(pricingUrl, bundles.getBundle("pricing"));
bundles.addBundleUpdateHandler("pricing", bundle -> {
    this.pricing = client(pricingUrl, bundle);
    log.info("certificado de cliente para pricing renovado");
});
```

`reload-on-update` vigila los archivos, y el manejador arma un cliente nuevo cuando cert-manager renueva el
certificado. Sin esas dos líneas, `inventory` presentaría el certificado viejo hasta su próximo reinicio, y el
día que venciera, `pricing` lo rechazaría. En Spring Boot 4, el `RestClient.Builder` autoconfigurado vive en
otro módulo que el servicio no trae (la [Fase 16](16-escalado-y-rollout.md) lo encontró), y por eso el `HttpClient` se arma a mano.

Qué ve `inventory` cuando le falta su certificado (incidente 23):

```text
pricing no contesta: I/O error on GET request for "https://pricing.apps.svc.cluster.local:8443/prices/SKU-0001":
(certificate_required) Received fatal alert: certificate_required
```

---

## 🪞 7. Tu instinto de compose dice… y las apuestas

El instinto, en su mejor versión: *"un certificado se pide una vez al año, se instala en el servidor, y se
pone un recordatorio en el calendario"*. Funcionó durante veinte años, salvo un domingo. Las apuestas,
escritas antes de ejecutar:

> 🪞 **Apuesta antes de ejecutar.** Con cert-manager, un certificado del `Gateway` de una hora se renueva
> solo antes de vencer, y Envoy empieza a servir el nuevo sin reiniciar ningún pod ni cortar una petición.
>
> **Resultado: ganada.** El serial nuevo, servido en el segundo de la renovación; 2.226 peticiones sin un
> fallo; los mismos reinicios antes y después (sección 5.4).

> 🪞 **Apuesta antes de ejecutar.** Entre `inventory` y `pricing`, el mTLS agrega menos de 5 ms a la mediana de
> la venta, y una conexión sin certificado de cliente se rechaza antes de llegar al código de `pricing`.
>
> **Resultado: ganada, las dos mitades.** La mediana no se movió más que la dispersión (sección 8), y el
> rechazo dejó una advertencia del saludo y ninguna línea `request` (sección 5.6).

> 🪞 **Apuesta antes de ejecutar.** Con Docker, el `push` a `localhost:5001` pasa sin confiar en la CA; el
> `pull` desde los nodos de kind falla igual con los dos motores hasta configurar containerd nodo por nodo.
>
> **Resultado: ganada**, con la mitad de Podman tomada de la verificación de preparación (03/10/2026). Y con una
> sorpresa que nadie apostó: el kubelet y sus registros de imágenes traídas (sección 5.7).

> 🪞 **Apuesta antes de ejecutar.** cert-manager y trust-manager suman menos de 150 MiB al cluster.
>
> **Resultado: ganada:** 134 MiB (sección 8).

Las entradas están en [INSTINTOS.md](INSTINTOS.md#un-certificado-se-instala-una-vez-al-año).

---

## 📏 8. Lo que cuesta

**El costo del mTLS en la venta.** Diez ventas por segundo durante treinta segundos por la puerta, con una
réplica de cada servicio; tres corridas con `inventory` llamando a `pricing` por el 8443 con mTLS, y tres por el
8080 en HTTP (la misma imagen, con `PRICING_URL` cambiada):

```text
con mTLS · corrida 1 · med=24.7ms p(95)=44.01ms  · 0 de 300 fallidas
sin mTLS · corrida 1 · med=25.49ms p(95)=47.41ms · 0 de 300
con mTLS · corrida 2 · med=26.88ms p(95)=66.36ms · 0 de 301
sin mTLS · corrida 2 · med=26.04ms p(95)=47.64ms · 0 de 301
con mTLS · corrida 3 · med=26.41ms p(95)=54.93ms · 0 de 301
sin mTLS · corrida 3 · med=25.95ms p(95)=49.38ms · 0 de 300
```

**La mediana es la misma**: 24,7–26,9 ms con mTLS contra 25,5–26,0 sin él, una diferencia más chica que la
dispersión entre corridas. No porque el TLS sea gratis: porque el `HttpClient` de `inventory` **reutiliza la
conexión**, y el saludo —lo caro: el intercambio de claves y la verificación de dos certificados— se paga una
vez por conexión, no por venta. El p95 con mTLS salió más alto en dos de tres corridas, y con la máquina
virtual en el estado de las fases anteriores no separé esa diferencia del ruido. El ejercicio 21 mide el caso
sin reutilizar.

**Lo que cuestan cert-manager y trust-manager**, en memoria, después de setenta minutos y cinco certificados
emitidos:

```text
cert-manager-controller   50.4 MiB      cert-manager-webhook   18.6 MiB
cert-manager-cainjector   30.2 MiB      trust-manager          34.6 MiB
TOTAL                    133.8 MiB
```

Más que Prometheus en reposo, menos que Grafana. Es el precio de no tener un domingo como el del Club Vecinos.

---

## ⚰️ 9. Autopsia: el certificado puesto a mano

**La decisión, con su mejor argumento.** El certificado de la puerta, hecho a mano con la CA, de un año, en el
`Secret`, y un recordatorio en el calendario del equipo para renovarlo. *"Es lo que hacemos con el portal desde
siempre, y cert-manager es un controlador más que operar."*

**Por qué era razonable.** Funciona el año entero sin que nadie lo toque, y la sección 12 dice que cert-manager
tiene un costo de verdad.

**Qué pasó después, con número.** El laboratorio no puede esperar un año: el incidente 18 lo comprime en un
certificado de dos minutos, puesto a mano, y medido desde afuera.

```text
14:49:02  recién cargado: 200
14:51:32  curl: (60) SSL certificate problem: certificate has expired
          el listener https: Programmed=True Accepted=True ResolvedRefs=True
```

**Cero avisos antes de vencer, y el cien por ciento de las conexiones HTTPS rechazadas después**, con la
puerta diciendo que todo está bien: `ResolvedRefs=True`. Envoy Gateway valida el certificado cuando lo carga, no
mientras lo sirve. Y la reparación apurada tiene su propia trampa: un certificado **ya** vencido (alguien
copia el del año pasado) la puerta ni lo carga, y el listener HTTPS entero se cae (`SSL_ERROR_SYSCALL` para
todos los nombres, no solo para el que venció). Es el domingo del Club Vecinos, con el mismo síntoma: el
cliente se entera primero.

**Cuánto cuesta salir, con número.** `task platform:certs -- lab`: cert-manager tomó el `Secret` hecho a mano en
un segundo, y la renovación posterior pasó con **2.226 peticiones y ninguna fallida**. A cambio, 134 MiB y tres
pods que operar.

**Qué lo habría cambiado.** Que el certificado lo emita quien lo renueva. Y, aunque lo renueve un controlador, una
alerta sobre la fecha de vencimiento: la puerta no la va a dar.

**Antes y después, con números:** a mano, 0 avisos y 100 % de rechazos a partir del vencimiento; con cert-manager,
renovación a las 16 horas de un certificado de 24, y 0 fallos en 2.226 peticiones durante una renovación.

---

## 📖 10. Traducción

| En compose o en un servidor | En Kubernetes | Lo que cambia |
|---|---|---|
| el certificado y la clave en un volumen de nginx | un `Secret` `kubernetes.io/tls` referido desde el listener del `Gateway` | la puerta lo relee sola cuando cambia |
| `certbot` en un cron, o el recordatorio en el calendario | cert-manager: `Issuer`/`ClusterIssuer` y `Certificate` | renueva antes de vencer, sin nadie; el `Secret` lo escribe él |
| la CA copiada en cada imagen (`COPY ca.crt …`) | trust-manager: un `Bundle` que escribe un `ConfigMap` por namespace | la CA cambia en un lugar, y los pods la leen montada |
| `insecure-registries` en el `daemon.json` del motor | `certs.d/<registry>/hosts.toml` y `ca.crt` en el containerd de cada nodo | son clientes distintos: el motor del host y el de cada nodo |
| el keystore JKS del servidor de aplicaciones | los PEM que monta el pod, y un *SSL bundle* de Spring Boot | sin conversión de formato, y con recarga |

Y al revés: un `Certificate` de un cluster ajeno es, en compose, un archivo PEM con una fecha que alguien
tiene que vigilar; un `Bundle` de trust-manager es la CA que se copia a mano en cada `Dockerfile`. Las filas
completas, en [a05](a05-diccionarios.md#-compose--kubernetes).

🌩️ En la nube, la puerta pública casi siempre lleva un certificado de una CA pública, emitido por ACME
(cert-manager con Let's Encrypt, o el servicio de certificados del proveedor), porque el dominio se puede
verificar desde internet. Lo que esta fase hizo con una CA propia sigue valiendo **adentro**: el mTLS entre
servicios no necesita una CA pública, y es mejor que no la use.

---

## 🩺 11. Incidentes de esta fase

El laboratorio de certificados, completo. Cada uno con su síntoma literal y su entrada en el cuaderno:

- **[18 — Ayer funcionaba y hoy el navegador no entra](cuaderno-incidentes.md#-incidente-18--ayer-funcionaba-y-hoy-el-navegador-no-entra).** `certificate has expired`.
- **[19 — El cliente no confía en quien firmó](cuaderno-incidentes.md#-incidente-19--el-cliente-no-confía-en-quien-firmó).** `unable to get local issuer certificate`.
- **[20 — El certificado es válido, pero no para este nombre](cuaderno-incidentes.md#-incidente-20--el-certificado-es-válido-pero-no-para-este-nombre).** `no alternative certificate subject name matches`.
- **[21 — El `Gateway` rechaza su propio certificado](cuaderno-incidentes.md#-incidente-21--el-gateway-rechaza-su-propio-certificado).** `tls: private key does not match public key`.
- **[22 — cert-manager no emite nada](cuaderno-incidentes.md#-incidente-22--cert-manager-no-emite-nada).** El `Certificate` en `READY False`.
- **[23 — `pricing` rechaza a `inventory` con mTLS](cuaderno-incidentes.md#-incidente-23--pricing-rechaza-a-inventory-con-mtls).** `certificate_required`.
- **[24 — El cluster no puede traer imágenes del registry propio](cuaderno-incidentes.md#-incidente-24--el-cluster-no-puede-traer-imágenes-del-registry-propio).** `x509: certificate signed by unknown authority`, en tres sitios.

---

## ⚖️ 12. Veredicto honesto: cuándo NO usar esto

**Una CA propia no sirve para la cara pública.** Ningún navegador de un cliente del Club Vecinos va a tener
tu CA instalada. Para lo que ve el público, una CA pública con ACME; la CA propia, para adentro.

**cert-manager es otro controlador que operar.** 134 MiB, tres pods y un *webhook* que, si se cae, deja sin
poder crear ningún `Certificate`. Para un servicio con un solo certificado que dura un año, en una empresa
sin cluster, un recordatorio en el calendario con dos responsables es honesto y más barato.

**El mTLS a mano no escala.** Dos servicios y un interruptor en el chart fueron un paso de generación entero;
veinte servicios, cada uno con su cliente y su recarga, son veinte oportunidades de olvidar la recarga. Eso es
lo que resuelve un service mesh ([a10](a10-service-mesh.md)), con su propio costo.

**La puerta no avisa.** Con un certificado vencido mientras estaba cargado, el `Gateway` siguió diciendo
`ResolvedRefs=True`. La renovación automática no reemplaza la vigilancia: una alerta sobre la fecha de
vencimiento (la métrica `certmanager_certificate_expiration_timestamp_seconds` existe) es lo que habría
avisado el jueves.

**Cuándo NO un registry propio con CA:** cuando `kind load` alcanza (un laboratorio, un nodo); y nunca los dos
caminos a la vez para la misma imagen (sección 5.7). **Cuándo sí:** cuando más de una máquina construye y más
de un cluster despliega.

**La pregunta del curso, para esta fase:** el contenedor te dio un proceso que puede escuchar en TLS. El
orquestador te dio los `Secret`, una puerta que los relee, y controladores que emiten y reparten. **Te tocó a
ti** decidir quién firma, qué nombres van en cada certificado, que cada servicio vuelva a leer sus
certificados cuando cambian, y los tres sitios donde se confía en un registry.

---

## ⚠️ 13. Errores comunes y diagnóstico

**`kubectl create secret tls` falla con `tls: private key does not match public key`.** Está bien que falle:
kubectl valida el par. Un `Secret` aplicado desde YAML no lo valida, y es como se llega al incidente 21.

**El `Certificate` queda en `READY False` con `Issuing certificate as Secret does not exist`.** Mira el
emisor (`kubectl get clusterissuer`) y la `CertificateRequest`: casi siempre es el emisor (incidente 22).

**cert-manager pisa el `Secret` que pusiste a mano.** Es su trabajo: si existe un `Certificate` para ese
`Secret`, cualquier cambio que no coincida con su `spec` lo vuelve a emitir. Para poner uno a mano, primero
se borra el `Certificate`.

**`inventory` sigue presentando el certificado viejo después de la renovación.** Falta
`reload-on-update` o el manejador que rearma el cliente; o el `Secret` está montado con `subPath`, y el
kubelet no actualiza los archivos montados así.

**El pod queda en `ContainerCreating` con `MountVolume.SetUp failed … secret "…" not found`.** El
`Certificate` todavía no emitió su `Secret` (o no va a emitirlo: incidente 22).

**`pull access denied` con la imagen en el nodo.** El kubelet la trajo antes con otro nombre (sección 5.7):
`/var/lib/kubelet/image_manager/pulled/` tiene el registro.

---

## 📋 14. Checklist de validación

```text
[ ] task tls:ca y task tls:gateway -- lab; https://api.localhost:8443 con --cacert, 200
[ ] task platform:certs -- lab; el Certificate lab-tls en READY True, el Bundle en Synced
[ ] la renovación con tráfico, sin una petición fallida
[ ] task conformance TARGET=cluster PROFILE=lab -- G8, y el rechazo sin certificado de cliente
[ ] task registry:up, el pull fallando desde el nodo, task registry:trust -- lab, el pull pasando
[ ] los incidentes 18 a 24 provocados y reparados con task inc:break / inc:fix
```

---

## 🧪 15. Ejercicios (24)

La mitad de diagnóstico; los incidentes del cuaderno son el resto del laboratorio de certificados.

## 🟢 Fácil — leer un certificado (1–7)

### 🟢 Ejercicio 1 — Lo que sirve la puerta
Con `openssl s_client`, muestra el certificado que sirve la puerta para `api.localhost`: quién lo firmó, hasta
cuándo vale y qué nombres tiene.

**Criterio:** el *issuer*, el `notAfter` y el SAN, y `Verify return code: 0 (ok)` con la CA.

<details><summary>Solución</summary>

`openssl s_client -connect 127.0.0.1:8443 -servername api.localhost -CAfile .secrets/tls/ca.crt </dev/null |
openssl x509 -noout -issuer -enddate -ext subjectAltName`. Sin `-servername`, la puerta no sabe qué nombre
pediste.
</details>

### 🟢 Ejercicio 2 — Sin la CA
Pide un precio por HTTPS sin `--cacert` y con `-k`. Explica qué hace `-k` y por qué no se usa.

**Criterio:** los dos resultados, y una frase sobre lo que `-k` deja de comprobar.

<details><summary>Solución</summary>

Sin la CA, `unable to get local issuer certificate`; con `-k`, 200: el cliente no valida nada, y cualquiera en el
medio pasaría.
</details>

### 🟢 Ejercicio 3 — El `Certificate`
Lista los `Certificate` del cluster y di cuándo se renueva cada uno.

**Criterio:** la tabla con `READY`, `notAfter` y `renewalTime`.

<details><summary>Solución</summary>

`kubectl get certificate -A -o custom-columns=NS:.metadata.namespace,NOMBRE:.metadata.name,VENCE:.status.notAfter,RENUEVA:.status.renewalTime`.
</details>

### 🟢 Ejercicio 4 — La CA en los pods
Encuentra la CA que reparte trust-manager en `apps` y comprueba que es la misma de `.secrets/tls/ca.crt`.

**Criterio:** el mismo *fingerprint* en los dos.

<details><summary>Solución</summary>

`kubectl -n apps get cm lab-ca -o jsonpath='{.data.ca\.crt}' | openssl x509 -noout -fingerprint -sha256`, y lo
mismo con el archivo.
</details>

### 🟢 Ejercicio 5 — El 8443 de `pricing`
Desde un pod de prueba, llama a `pricing` por el 8080 y por el 8443 sin certificado.

**Criterio:** 200 por el 8080 y `certificate required` por el 8443, con la línea del saludo en el log de
`pricing`.

<details><summary>Solución</summary>

El pod de la sección 5.6, con la imagen de Hurl y el `ConfigMap` `lab-ca` montado.
</details>

### 🟢 Ejercicio 6 — Renovar ya
Fuerza la renovación del certificado de la puerta y mira el serial antes y después.

**Criterio:** dos seriales distintos y la revisión del `Certificate` sumando uno.

<details><summary>Solución</summary>

Borrar el `Secret` `lab-tls` (cert-manager lo emite de nuevo), o el plugin `cmctl renew` si lo instalas.
</details>

### 🟢 Ejercicio 7 — Una imagen del registry
Sube `replenish` al registry propio y despliega un pod de prueba con ella.

**Criterio:** el pod `Running`, con `Successfully pulled image "lab-registry:5000/lab/replenish:…"`.

<details><summary>Solución</summary>

`task registry:push -- replenish` y `kubectl run` con la imagen de `lab-registry:5000`. Usa un namespace aparte,
y bórralo: la sección 5.7 dice por qué no conviene mezclar los dos nombres.
</details>

## 🟡 Intermedio — llevar el patrón a otro sitio (8–14)

### 🟡 Ejercicio 8 — La página por HTTPS
Haz que el `storefront` funcione en `https://storefront.localhost:8443`, con la API también por HTTPS.

**Criterio:** la página carga el catálogo y vende sin avisos de contenido mixto en la consola del navegador.

<details><summary>Solución</summary>

`API_BASE_URL` del `storefront` con `https://api.localhost:8443`, y el origen del CORS de las rutas con el
esquema y el puerto nuevos (`lab-common.httproute`). Necesita la CA en el navegador (sección 5.3).
</details>

### 🟡 Ejercicio 9 — mTLS para `catalog`
Extiende G8: que `inventory` le hable a `catalog` también con TLS mutuo.

**Criterio:** la venta pasando con `CATALOG_URL` en `https`, y `catalog` rechazando sin certificado.

<details><summary>Solución</summary>

El certificado de servidor de `catalog` y un `server` TLS en su nginx con `ssl_verify_client on` y la CA; en
`inventory`, otro bundle o el mismo. Es nginx quien hace el TLS, no PHP.
</details>

### 🟡 Ejercicio 10 — La segunda cadena
Instala `tenant-b` con mTLS encendido. ¿Puede el `inventory` de `apps-b` hablarle al `pricing` de `apps`?

**Criterio:** la respuesta probada, y por qué.

<details><summary>Solución</summary>

Sí: los dos certificados los firma la misma CA, y `pricing` solo pregunta por la CA. Para separar cadenas hace
falta otra CA por cadena, o mirar el nombre del cliente. La [Fase 20](20-seguridad-del-pod-y-de-la-red.md) lo cierra por red.
</details>

### 🟡 Ejercicio 11 — `pricing` pregunta quién es
Haz que `pricing` acepte solo el certificado de cliente cuyo nombre sea el de `inventory`.

**Criterio:** un certificado de otro nombre firmado por la misma CA, rechazado.

<details><summary>Solución</summary>

`VerifyPeerCertificate` en el `tls.Config` (o `VerifyConnection`), comparando el SAN del certificado del
cliente. Es el paso de "quién eres" después de "quién te firmó".
</details>

### 🟡 Ejercicio 12 — La duración
Cambia la duración del certificado de `pricing` a una hora y verifica que `inventory` sigue vendiendo después
de dos renovaciones.

**Criterio:** dos renovaciones en los eventos, la línea `certificado del servidor cargado` en `pricing` y
`certificado de cliente para pricing renovado` en `inventory`, y ninguna venta fallida.

<details><summary>Solución</summary>

`duration: 1h` y `renewBefore: 55m` en los dos `Certificate`, y el tráfico de fondo durante quince minutos.
</details>

### 🟡 Ejercicio 13 — Podman y el registry
Con Podman, sube una imagen al registry propio. **Predice** qué falla y dónde va la CA.

**Criterio:** el error del `push` y el `push` pasando después.

<details><summary>Solución</summary>

`x509: certificate signed by unknown authority`; la CA en `~/.config/containers/certs.d/localhost:5001/ca.crt`
**dentro de la máquina de Podman** (`podman machine ssh`), no en el host.
</details>

### 🟡 Ejercicio 14 — Una alerta para el jueves
Escribe la consulta de Prometheus que diga cuántos días le quedan a cada certificado.

**Criterio:** la consulta con datos, y el umbral que pondrías.

<details><summary>Solución</summary>

`(certmanager_certificate_expiration_timestamp_seconds - time()) / 86400`. Necesita que Prometheus lea las
métricas de cert-manager: un trabajo más en el `scrape_config`.
</details>

## 🟠 Difícil — diagnosticar (15–20)

### 🟠 Ejercicio 15 — El certificado ya vencido
Pon en la puerta un certificado que **ya** venció. **Predice** el síntoma antes de probarlo.

**Criterio:** el síntoma, las condiciones del listener, y por qué es distinto del incidente 18.

<details><summary>Solución</summary>

La puerta no lo carga: `ResolvedRefs=False … certificate api.localhost has expired`, el listener HTTPS fuera, y
el cliente ve `SSL_ERROR_SYSCALL`, no `certificate has expired`. El 18 es un certificado que vence **estando
cargado**: ahí la puerta no se entera.
</details>

### 🟠 Ejercicio 16 — La CA nueva
Regenera la CA con `--force` y no hagas nada más. **Predice** qué se rompe, en qué orden.

**Criterio:** la lista de lo roto, con su evidencia, y el orden de la reparación.

<details><summary>Solución</summary>

Nada en el momento: todo lo emitido sigue valiendo hasta renovarse. Se rompe después: los clientes con la CA
vieja. Reparar: la CA nueva en el `Secret` `lab-ca`, trust-manager la reparte, se reemiten los certificados, y se
reinician los clientes que no recargan.
</details>

### 🟠 Ejercicio 17 — El nodo que no confía
Agrega un nodo al cluster `lab` (otro worker) y despliega algo desde el registry propio en ese nodo.

**Criterio:** el fallo, explicado, y lo que le falta a `task registry:trust`.

<details><summary>Solución</summary>

El nodo nuevo no tiene la CA en `certs.d`. La tarea es una foto: hay que correrla en cada nodo nuevo, o
ponerla en la creación del cluster (`extraMounts`).
</details>

### 🟠 Ejercicio 18 — La recarga que falta
Quita de `inventory` el manejador que rearma el cliente de `pricing` y deja vencer su certificado (una hora).

**Criterio:** el momento exacto en que la venta empieza a fallar, y la línea del log que lo prueba.

<details><summary>Solución</summary>

Mientras el certificado viejo valga, nada. Cuando vence, `pricing` rechaza el saludo y la
venta da 503. El archivo montado ya tenía el nuevo: lo que faltaba era leerlo.
</details>

### 🟠 Ejercicio 19 — `subPath`
Monta el certificado de `pricing` con `subPath` y fuerza una renovación.

**Criterio:** el archivo dentro del pod sin cambiar, y la explicación.

<details><summary>Solución</summary>

El kubelet no actualiza los archivos montados con `subPath`: el pod se queda con el de su arranque. Por eso el
chart monta la carpeta.
</details>

### 🟠 Ejercicio 20 — Dos nombres, una imagen
Reproduce la trampa de la sección 5.7 en un nodo, y arréglala sin reiniciar el kubelet.

**Criterio:** el `pull access denied` con la imagen presente, el registro del kubelet como evidencia, y la
solución.

<details><summary>Solución</summary>

Una salida: cambiar el tag de la imagen cargada (otro digest no comparte registro). La otra, de verdad: no
mezclar los dos caminos. La política de verificación del kubelet (`imagePullCredentialsVerificationPolicy`)
también se puede cambiar, pero eso es configurar el nodo.
</details>

## 🔴 Muy difícil — medir y diseñar (21–24)

### 🔴 Ejercicio 21 — El costo del saludo
Mide el costo del mTLS **sin** reutilizar conexiones: un `HttpClient` nuevo por venta.

**Criterio:** la mediana con y sin mTLS, tres corridas cada una, comparada con la sección 8.

**Rúbrica:** la diferencia es el saludo TLS completo por petición; la sección 8 no lo vio porque el cliente
reutiliza la conexión. La conclusión dice cuál de los dos es el caso real de `inventory`.

### 🔴 Ejercicio 22 — Una CA por cadena
Diseña la separación de las dos cadenas por certificado: que `pricing` de `apps` no acepte el `inventory` de
`apps-b`.

**Criterio:** el diseño en el chart y la prueba del rechazo.

**Rúbrica:** un emisor por cadena (o un `Issuer` por namespace), su CA en el `Bundle` de cada una, y qué se
pierde: la CA del laboratorio deja de ser una.

### 🔴 Ejercicio 23 — La caída de cert-manager
Baja cert-manager a cero réplicas una hora. **Predice** qué deja de funcionar y qué no.

**Criterio:** la lista con evidencia, incluido lo que pasa al crear un `Certificate` nuevo.

**Rúbrica:** lo emitido sigue sirviendo; no se emite ni se renueva nada; el *webhook* caído rechaza crear o
cambiar `Certificate`. La renovación de 8 horas antes del vencimiento es el margen para arreglarlo.

### 🔴 Ejercicio 24 — El laboratorio de certificados, a ciegas
Pide a alguien que corra uno de los incidentes 18 a 24 sin decirte cuál. Diagnostícalo.

**Criterio:** el ID correcto en menos de diez minutos, con el primer comando que lo distinguió.

**Rúbrica:** empezar por quién es el cliente (navegador, servicio o nodo); después, las cuatro preguntas de la
sección 5.1 en orden; y no tocar nada antes de tener la evidencia.

---

## 📚 16. Referencias

**Documentación oficial** (las versiones de [a01](a01-el-laboratorio.md))

- Gateway API, *TLS*: https://gateway-api.sigs.k8s.io/guides/tls/
- Envoy Gateway, *Secure Gateways*: https://gateway.envoyproxy.io/docs/tasks/security/secure-gateways/
- cert-manager, *CA issuer*: https://cert-manager.io/docs/configuration/ca/
- cert-manager, *Certificate resource* (duración y renovación): https://cert-manager.io/docs/usage/certificate/
- trust-manager: https://cert-manager.io/docs/trust/trust-manager/
- Spring Boot, *SSL bundles*: https://docs.spring.io/spring-boot/reference/features/ssl.html
- Go, `crypto/tls`: https://pkg.go.dev/crypto/tls
- containerd, *Registry configuration* (`hosts.toml`): https://github.com/containerd/containerd/blob/main/docs/hosts.md
- Kubernetes, *Images* (la verificación de imágenes traídas): https://kubernetes.io/docs/concepts/containers/images/

**Libros y ensayos**

- Ivan Ristić, *Bulletproof TLS and PKI*, 2.ª edición (2022): los capítulos de PKI y de validación de
  certificados.
- Let's Encrypt, *How It Works*: https://letsencrypt.org/how-it-works/ (para entender ACME y por qué no aplica a
  `*.localhost`).

**Orden de lectura sugerido:** antes, el capítulo de PKI de Ristić (la cadena); durante, *CA issuer* con la
sección 5.4 delante; después, la guía de `hosts.toml` de containerd, con el incidente 24 abierto.

> ⚠️ Las URL y los contenidos cambian.

---

## 🏁 17. Resultado de la fase

```text
EL ESTADO AL CERRAR LA FASE 19 (cluster lab, valores de minimo)

  gateway         listener https en el 8443 (NodePort 30443), con el Secret lab-tls de cert-manager
  cert-manager    cert-manager y trust-manager (platform/cert-manager/, imágenes por digest)
                  ClusterIssuer lab-ca (la CA de task tls:ca); Bundle lab-ca → ConfigMap lab-ca por namespace
  apps            pricing e inventory en :g8, con mTLS (global.mtls.enabled): pricing-tls e inventory-client-tls
                  catalog y replenish en :g7, storefront en :g5
  host            .secrets/tls/ (la CA y los certificados, fuera de git); lab-registry en 127.0.0.1:5001
  tareas          tls:ca, tls:gateway, platform:certs, registry:up | down | push | trust | untrust
```

> **La señal de que quedó bien:** *"Ante un error de certificado sé cuál de las cuatro preguntas falló, le
> aseguro al comercial que el de la puerta se renueva solo, y sé dónde poner una CA según quién sea el
> cliente."*

> 🏷️ **No cierres la fase sin el tag.** Con el checklist en verde, la suite de G8 pasando y `git status`
> limpio:
>
> ```bash
> git tag -a fase-19-tls-y-certificados -m "F19 cerrada: CA propia y HTTPS en la puerta; cert-manager y trust-manager con renovación medida; G8, mTLS entre inventory y pricing con recarga; registry con CA en los tres sitios; incidentes 18 a 24"
> ```
>
> Y los pares: `inc/18/expired-gateway-cert-*`, `inc/19/unknown-ca-*`, `inc/20/wrong-san-*`,
> `inc/21/key-cert-mismatch-*`, `inc/22/issuer-without-ca-*`, `inc/23/mtls-without-client-cert-*` e
> `inc/24/registry-ca-untrusted-*`. Commits con prefijo `f19:`.

---

## 📌 Pendientes sugeridos

- **F20:** que nadie fuera de `apps` pueda llegar al 8080 de `pricing`, que hoy sigue abierto.
- **F22:** el timeout y el reintento de la llamada mTLS de `inventory`.
- **`a10`:** el mTLS de todos los servicios sin tocar su código.
- **Oskar:** la prueba en el navegador y la desinstalación de la CA, sin verificar (sección 5.3).
