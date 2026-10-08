# 🎯 Alcance del proyecto
## Laboratorio de contenedores y Kubernetes local

> **Qué es este documento:** la fuente de verdad de **qué** enseña el curso, a quién y con qué
> límites. Lo que no esté aquí no está en el curso.
> **Fecha de esta versión:** 30 de septiembre de 2026. Consolida la propuesta de fases del 14/09 y
> las decisiones de la sesión del 30/09. Los documentos preliminares (`prompts/_desechable-*`) se borraron
> al cerrar la producción, el 05/10/2026; el registro de decisiones sigue en la propuesta de fases §12.
> **Precedencia:** manda este documento. Después viene
> [`guia-de-estilo-y-convenciones.md`](guia-de-estilo-y-convenciones.md), que decide **cómo** se
> escribe; después [`contrato-del-cluster.md`](contrato-del-cluster.md), que fija los nombres
> técnicos, y las dos propuestas de alcance. Las plantillas, los prompts y el formato del cuaderno se
> actualizan siempre al final. Por encima de todos está el `CLAUDE.md` del repositorio, en lo que este
> curso no haya declarado como excepción (§12).
> **Estado de las decisiones:** el registro vive en
> [`propuesta-fases-y-alcance.md`](propuesta-fases-y-alcance.md) §12. Lo que depende de la
> verificación de laboratorio (versiones y presupuesto de memoria) se fija en `a01`; la verificación
> se hizo el 03/10/2026. Todas las decisiones están cerradas (D1–D32).

---

## 1. 🧭 En una frase

**Un curso que enseña la plataforma completa —contenedor, orquestador y todo lo que queda
alrededor— construyendo un sistema de cuatro microservicios políglotas sobre un Kubernetes local
que se puede romper sin pagar, y midiendo lo que cada decisión cuesta.**

No forma administradores de cluster ni prepara una certificación. Forma la capacidad de mirar un
servicio y decir *"esto lo resuelve el contenedor, esto lo resuelve el orquestador, y esto lo tengo
que escribir yo"*, con el laboratorio encima de la mesa para demostrarlo.

---

## 2. 🔥 El problema que resuelve

El lector ha desplegado cosas. Tiene un `docker-compose.yml` en su proyecto, alguna vez hizo
`kubectl apply` de un YAML que le pasó otro equipo, y sabe que "en producción corre en Kubernetes".
Lo que no tiene es **la panorámica**: qué parte del sistema resuelve cada capa, dónde termina lo que
la plataforma regala y dónde empieza lo que tiene que escribir él.

Y no la tiene por una razón muy concreta: **nunca tuvo una plataforma que pudiera romper**. El
cluster corporativo es de otro equipo, el de la nube cuesta dinero, y en ninguno de los dos se
puede tumbar un nodo o expirar un certificado para ver qué pasa. Así que aprende los síntomas en
producción, de madrugada, y con público.

El curso existe para que eso pase antes y en casa. El villano es uno solo, **confundir capas**, y
tiene tres caras:

- **"Kubernetes lo resuelve."** Creer que el orquestador reintenta, deduplica o compensa por ti.
  No lo hace, y la Parte IV del curso existe para demostrarlo.
- **"Es como compose, pero con más YAML."** Trasladar el instinto de compose al cluster:
  `depends_on` que no espera, `restart: always` que no es un `Deployment`, volúmenes que son del
  host. Es la 🪞 recurrente del curso.
- **"Un contenedor es una VM chica."** Ponerle más RAM, entrarle por SSH, meterle systemd. Es el
  origen de la mitad de los errores de intuición de este perfil.

> ⚠️ **El antagonista no es ninguna herramienta.** Ni Docker, ni Podman, ni Kubernetes, ni compose.
> Cada una gana en algún sitio, y el curso cierra con el ⚖️ veredicto de cuándo **no** necesitabas
> nada de esto.

---

## 3. 🎓 Objetivo pedagógico

Al terminar, el estudiante puede hacer seis cosas que antes no podía:

1. **Empaquetar cualquier runtime en una imagen defendible**: multi-stage, base elegida con
   criterio, caché aprovechado, y el costo de cada decisión medido.
2. **Traducir un sistema de compose a Kubernetes y de vuelta**, sabiendo qué no tiene traducción.
3. **Desplegar, configurar, exponer, escalar y actualizar** un sistema de varios servicios con
   YAML escrito a mano primero y con Helm después, sin cortar peticiones.
4. **Diagnosticar un fallo de plataforma en los primeros treinta segundos**: qué mirar, qué comando
   correr, qué hipótesis descartar.
5. **Operar TLS de punta a punta**: CA propia, certificados emitidos y renovados solos, mTLS entre
   servicios, y los seis o siete fallos de certificados que más incidentes producen.
6. **Decidir qué va en el código y qué en la plataforma** para resiliencia, comunicación y
   consistencia entre servicios: timeouts, gRPC, sagas, eventos, idempotencia y outbox.

Lo que **no** es objetivo: administrar un cluster de producción, operar una nube concreta,
aprobar una certificación, ni enseñar a programar los servicios.

---

## 4. 👥 Perfil del estudiante

Desarrollador **semi-senior o senior políglota**: ha escrito JavaScript, PHP y Java, monta un
endpoint sin pensarlo, entiende un ORM, una migración y un token, y ha visto un
`docker-compose.yml`. **Se le explica infraestructura, no programación.**

**Lo que se da por sabido y no se explica jamás:** qué es HTTP, JSON, una API REST, una base de
datos relacional, una transacción, una variable de entorno, un proceso, un puerto o una línea de
comandos.

**Lo que se explica con cero ambigüedad**, aunque el lector sea senior: qué es exactamente un
contenedor (un proceso con la vista recortada), qué hace el bucle de reconciliación, la diferencia
entre readiness y liveness, qué promete un `request` y qué impone un `limit`, qué valida un cliente
TLS y en qué orden, y qué garantiza —y qué no— una entrega *al menos una vez*.

> 🧭 **Ninguna caja negra prematura, no menos profundidad.** El lector sabe qué es un servicio; el
> curso le enseña qué le pasa cuando el cluster lo mata. Si una frase obliga al lector a suponer
> algo, está mal escrita.

**Requisitos de entrada:** un equipo con virtualización habilitada y una de las tres plataformas del
§8; soltura con la terminal; y la memoria que fije la verificación de laboratorio (§7.2). **No hace
falta ningún runtime instalado en el host**: Java, PHP, Node y Go se compilan siempre dentro de un
contenedor.

---

## 5. 🧭 La pregunta que ordena el curso

> *¿Qué te da el contenedor, qué te da el orquestador, y qué te sigue tocando escribir a ti?*

Se presenta en la Fase 00, reaparece en el ⚖️ veredicto de cada fase respondida para lo que la
fase acaba de enseñar, y ordena el arco entero:

- Las **Partes 0 a III** son lo que la plataforma **sí** te regala: empaquetado, reinicio,
  descubrimiento, configuración, estado, escalado, salud, entrada, certificados.
- La **Parte IV** es lo que no te va a dar nunca: timeouts con criterio, balanceo de conexiones
  largas, compensaciones, mensajes que no se pierden y operaciones que se pueden repetir.
- El **cierre** responde la pregunta que el curso se gana a lo largo de veintiocho fases: ¿de
  verdad necesitabas un orquestador?

---

## 6. 📏 Cómo se mide

**Todo "mejor que" lleva un número**, medido con un arnés consistente y consolidado en
`BENCHMARKS.md`. Seis mediciones son del camino base (propuesta §8) y cada una declara hipótesis,
condiciones, resultado y veredicto.

Lo que el curso mide es **costo de plataforma**, no rendimiento de negocio:

- **tamaño** de imagen y de capa, y **tiempo de build** en frío y con caché;
- **tiempo hasta el primer request atendido** y hasta readiness, por runtime;
- **memoria en reposo y bajo carga**, por pod y del host entero, por perfil;
- **réplicas necesarias** para sostener una tasa de peticiones, por runtime;
- **distribución del tráfico** entre réplicas;
- **tiempo de creación** de un cluster, por herramienta y por motor.

Las reglas de honestidad no se negocian: se publica lo que salió y no lo que se esperaba · **el
empate se llama empate** · nada de números redondos sin dispersión · el competidor se configura bien
· se declara lo que no se midió · y **nunca se extrapola** de un portátil a producción.

> 📝 **Los tiempos dependen de la máquina**, y aquí son parte de lo que se mide. Por eso cada
> medición declara el equipo de referencia, el motor y el perfil, y la conclusión se escribe sobre
> la **proporción** entre alternativas, que sobrevive al cambio de máquina, y no sobre el número
> absoluto, que no.

Dos anclas por fase, cuando la fase las admite:

- 🪞 **Una apuesta** escrita antes de ejecutar y nunca editada después. La apuesta perdida se publica
  igual que la ganada.
- 🧨 **Una rotura provocada**: el experimento que falla a propósito, con el síntoma literal y lo
  que costó salir.

---

## 7. 🧪 El sistema del curso

### 7.1 El dominio

El curso construye el sistema de inventario de una **cadena de retail**: venta → validar producto →
consultar precio → descontar stock → disparar reposición si el stock cae bajo el umbral. Es la
**transacción distribuida más honesta que cabe en un laboratorio**: cuatro servicios, cuatro bases
lógicas y una compensación que significa algo cuando falla a la mitad.

> 🏘️ **La empresa es Droguerías La Vecina**, una cooperativa de droguistas nacida en el área
> metropolitana de Bucaramanga que creció a Boyacá, Cundinamarca y Bogotá. Su historia vive en
> [`00-historia-de-la-vecina.md`](../00-historia-de-la-vecina.md), en la raíz del curso, que es la fuente
> de verdad de todo lo narrativo: personajes, cifras, cronología y reglas de negocio. **Este
> documento fija la estructura; ninguna fase inventa dominio por su cuenta.**
>
> En una línea: la cooperativa lleva veinte años casada con Oracle en el núcleo —un monolito Java EE
> en WebLogic sobre Oracle Database, y Siebel para su club de afiliados— y con Microsoft en el puesto
> de trabajo. La factura de licencias y un pico de domicilios que congeló las cajas de todo el país
> llevan al **proyecto Paracelso**, el POC de la unidad de I+D **Alquimia**, que prueba
> microservicios sobre Postgres antes de elegir nube, y que se construye en **La Rebotica**, un
> laboratorio en portátiles. El curso es ese POC. Un segundo motivo empuja la inversión: la idea, todavía embrionaria, de vender
> el sistema a otras cadenas como servicio, que obliga a que la plataforma nueva pueda instalarse
> para una segunda cadena sin copiarlo todo.
>
> ⚠️ **El curso no enseña regulación farmacéutica.** Fórmula médica, lotes y vencimientos, cadena de
> frío, control especial y dispensación a las EPS no existen en el modelo. El tope de precio regulado
> es una regla configurable de `pricing`, simplificada. El **pendiente** es un estado de la
> compensación de una venta, y el **préstamo entre droguerías** es una `replenishmentOrder` cuyo
> origen es otra `store`: ninguno es una entidad nueva.

Lo que sí está fijado desde aquí, porque es contrato técnico y no narrativa:

- **Las entidades**, en inglés: `product`, `category`, `store`, `stockLevel`, `stockMovement`,
  `replenishmentOrder`, `price`. En JSON van en `camelCase`; en las tablas, en `snake_case`
  (`stock_level`, `stock_movement`, `replenishment_order`).
- **Los cinco servicios**: `catalog`, `inventory`, `replenish`, `pricing` y `storefront`. Ninguna
  fase los renombra.
- **El dominio se mantiene mínimo a propósito.** Si una fase necesita una regla de negocio nueva,
  la declara en la historia primero.

### 7.2 El stack, y qué compra cada pieza

Ninguna pieza entra por variedad. Entra si enseña algo de la plataforma que las otras no enseñan.

| Servicio | Stack | La lección de plataforma que compra |
|---|---|---|
| `inventory` | Spring Boot 4 · Java 25 LTS | La JVM contra los `limits` del cgroup, en su versión de hoy: la JVM sabe que está en un contenedor, y el `OOMKilled` llega igual por la memoria que no es heap. Arranca lento, lo que obliga a entender readiness, y el AOT cache es su respuesta moderna |
| `catalog` | PHP · Laravel · PHP-FPM + nginx | El modelo de proceso que no encaja: **dos procesos en un pod**, quién responde la sonda, y por qué "un request, un proceso" hace que el escalado por CPU se comporte distinto |
| `replenish` | Node 24 LTS · TypeScript · NestJS | El consumidor de eventos y el lado asíncrono de la saga; el *event loop* como tercer modelo de concurrencia |
| `pricing` | Go | El **piloto** de cada patrón y el **control** de cada medición: la imagen más chica y el arranque más rápido. Es el servidor gRPC |
| `storefront` | React · Vite · nginx | Que el frontend **no es un servicio**: es un archivo que alguien sirve, y su configuración se hornea en build |

**Datos y bus:** un solo **PostgreSQL** con una base y un usuario por servicio (la divergencia con
*database-per-service* se declara en la fase que la estrena), desplegado con la **imagen oficial y
un `StatefulSet` propio**, sin charts de terceros · **SQLite** en tres sitios y en ninguno más · 
**Testcontainers** para las pruebas que sí tocan SQL · **Valkey** como caché y como el pub/sub
deliberadamente frágil · **NATS con JetStream** como bus de la coreografía en serio.

**Las versiones exactas no están en este documento.** Se fijaron en la verificación de laboratorio
(P11), con la regla **"todo en su última LTS, y donde no haya línea LTS, en su última estable, a
la fecha de la verificación"**, y viven en un solo sitio: `a01`. La regla tiene una condición que
la verificación hizo explícita (D32): **la última estable que soportan todas las piezas juntas**. El
nodo de Kubernetes va una versión detrás de la última porque el controlador de Gateway todavía no
soporta la más nueva, y eso se dice en `a01` con esas palabras.

### 7.3 El código es andamiaje, y se genera asistido

Es la decisión de método que hace posible el alcance. El curso publica, por cada servicio, **el
contrato** y **el prompt** que lo genera, y el código resultante vive en `src/lab/`. El lector puede
regenerarlo, escribirlo a mano o usar el que viene, y en los tres casos el curso funciona igual,
porque **ninguna fase enseña a programar el endpoint**.

Cuatro piezas lo sostienen, y el detalle está en el [contrato del cluster](contrato-del-cluster.md) y
en `a03`:

1. **El patrimonio como insumo**: los prompts de los servicios nuevos reciben, además del contrato,
   el código del patrimonio del que se extraen (Contingencia, el portal, la Braqui).
2. **El contrato verificable**: un OpenAPI 3.1 por servicio y un `.proto` para `pricing`, congelados
   en la Fase 02, y documentados con Swagger UI, que corre en un contenedor y nunca dentro del
   cluster.
3. **La suite de conformidad**, escrita en Hurl, que corre igual contra compose y contra el cluster.
   Un servicio regenerado es válido si la pasa; no hay otra definición.
4. **Los prompts escalonados**, una matriz de servicio por paso: las tres oleadas de dominio y las
   capacidades de plataforma (sondas reales, `/metrics`, logs en JSON, gRPC, trazas, eventos,
   outbox). **El código nunca trae una capacidad antes de la fase que la enseña.**

La herramienta de referencia es Claude Code, con un `CLAUDE.md` por servicio; los prompts no
dependen de ella y funcionan con cualquier asistente.

### 7.4 El tamaño mínimo es una restricción de diseño

El laboratorio **se diseña para ocupar lo menos posible**, y eso decide piezas:

- **kind de un solo nodo** por defecto. Los nodos worker se encienden solo en las fases que los
  necesitan (topología, planificación, escalado, `DaemonSet`).
- **La observabilidad se enciende y se apaga por pieza** —métricas, tableros, logs, trazas—, porque
  es lo que más consume. Ninguna fase la exige entera salvo la que la enseña.
- **Nada de distribuciones "todo incluido"**: Prometheus sin Operator, Loki monolítico, Tempo
  monolítico, Fluent Bit como recolector.
- **Tres perfiles de despliegue**, `minimo`, `lab` y `medicion` (contrato del cluster §5).

La meta es que **`minimo` entre en un equipo de 8 GB** en las tres plataformas. El requisito que se
publica no es la meta sino **lo medido** en la verificación de laboratorio, perfil por perfil, y si
algún perfil no entra se achica el perfil, no se sube el requisito sin decirlo.

**Lo que dijo la verificación (P11), sin los servicios todavía:** la infraestructura de `minimo` con
toda la observabilidad encendida ocupa unos 2,1 GiB de la máquina virtual de Podman y 2,6 GiB de la
de Docker, así que **la máquina virtual necesita 4 GiB** (la de Podman por defecto, de 2 GiB,
colapsa) y queda un margen de 1,4 a 1,8 GiB para los cinco servicios. Que `minimo` quepa en un
portátil de 8 GB se decide en T2, cuando los servicios existan y se midan.

---

## 8. 🧰 Las herramientas

| Capa | Herramienta | Dónde entra |
|---|---|---|
| Motores | **Docker** (Desktop o Engine) y **Podman** (+ Podman Desktop), conviviendo | Fase 00, contraste 🦭 en todo el curso |
| Compose | `docker compose` y `podman compose` | Fase 02 |
| Inspección de imágenes | **dive** | Fases 03–04 |
| Cluster | **kind**, sobre cualquiera de los dos motores | Fase 07 en adelante |
| Comparados una vez | k3d, minikube, el Kubernetes de Docker Desktop | Fase 07 📏 |
| Cliente | **kubectl**, `kubectl debug`, **k9s** | Fase 08 en adelante; kit completo en la Fase 21 |
| Entrada | **Gateway API** con **Envoy Gateway** como controlador, y **cloud-provider-kind** para los `Service` de tipo `LoadBalancer`. Las alternativas se nombran con sus ventajas y desventajas | Fase 10 |
| Paquete | **Helm 4** con helm-diff; Kustomize como sección | Fases 13–14 |
| Certificados | openssl, **cert-manager**, trust-manager; mkcert como atajo opcional | Fase 19 |
| Métricas | **Prometheus** sin Operator, **metrics-server** | Fases 16–17 |
| Tableros | **Grafana** con tableros provisionados como código | Fase 17 |
| Logs | **Loki** monolítico, **Fluent Bit** como `DaemonSet` | Fase 18 |
| Trazas | **Tempo** monolítico, **SDKs de OpenTelemetry** en los servicios | Fase 23 |
| Carga y medición | **k6** (HTTP y gRPC), **hyperfine**, grpcurl | Fase 04 en adelante |
| Contrato | OpenAPI 3.1, Protobuf, **Hurl**, y **Swagger UI** en un contenedor para leer los contratos | Fase 02 en adelante |
| Punto de entrada | **Taskfile** (go-task) | todo el curso |
| Scripting | **Python**, donde haga falta un script que una tarea del Taskfile no resuelve en una línea | todo el curso |

**Por qué Taskfile y no Makefile:** es un binario que corre igual en PowerShell, macOS y Linux. Un
Makefile exige `make` y un shell POSIX, y en Windows eso es una fricción que no enseña nada.

**Python es el lenguaje de scripting, no un stack.** El curso lo usa como un shell con esteroides:
**un solo script que corre igual en macOS, Linux y Windows**, en vez de un `.sh` y un `.ps1` que
hacen lo mismo y se desincronizan en la primera corrección. Por la misma razón que el Taskfile
reemplaza a `make`: mantener dos versiones de cada script es una fricción que no enseña nada.
Ningún servicio del sistema está escrito en Python, y ningún equipo de la historia lo opera como
suyo. Las reglas:

- **Lo que cabe en una línea de una tarea del Taskfile sigue siendo un comando**, no un script.
- **Lo que pasa de ahí es un script de Python**, invocado desde una tarea del Taskfile: utilidades
  del laboratorio, preparación de datos, verificaciones, y el aviso de traslados de la Braqui en el
  patrimonio (D30).
- **Dependencias con `venv` y `pip` donde hagan falta**, por ejemplo Faker para sembrar las bases
  con datos sintéticos. **Un `requirements.txt` por directorio de scripts**, para que las
  dependencias de cada sección viajen con ella, y la tarea del Taskfile que los invoca crea el
  entorno si no existe. El curso no enseña `venv`: el lector sabe buscarlo si no lo conoce. Lo
  mínimo para correr los scripts, con el seed como ejemplo, está en `a01` (D31).
- **Ningún script nuevo en `bash` ni en PowerShell.** Un script solo de Windows existe únicamente si
  lo que hace no tiene sentido en los otros dos sistemas, y lo dice en su primera línea.

**Por qué Gateway API y no Ingress:** el controlador de Ingress más usado del ecosistema,
ingress-nginx, **se retiró en marzo de 2026** y su repositorio quedó en solo lectura. El recurso
`Ingress` sigue en la API, pero el curso no enseña a construir sobre lo que el ecosistema está
dejando. **El curso no despliega ni un objeto `Ingress`**: aparece solo en el diccionario de
traducción, porque el lector lo va a encontrar en clusters ajenos.

**Plataformas soportadas:** Windows 11 con WSL 2, macOS Apple Silicon y Linux amd64, **en ese orden y
sin nota al pie**. **El autor verifica solo en macOS arm64**, que es la plataforma de referencia.
Las instrucciones de Windows 11 y de Linux se escriben desde la documentación oficial, se declaran
como no verificadas por el autor con esas palabras, y **se verifican al hacer el curso**: quien lo
recorre en esas plataformas confirma o corrige, y la corrección entra con su fecha.

---

## 9. 🪜 La forma del curso

Cinco partes y un cierre, **28 fases** (`00`–`27`), sin reparto horario: cada fase declara su
**peso** —ligera, media o densa— y ahí termina la promesa de esfuerzo. El detalle, fase por fase,
está en [`propuesta-fases-y-alcance.md`](propuesta-fases-y-alcance.md).

| Parte | Qué hace | Fases |
|---|---|---|
| **0 · Prolegómenos** | El ambiente, el primer contenedor y el sistema en compose | 00 – 02 |
| **I · El modelo y el salto** | Qué pasa debajo, y por qué compose deja de alcanzar | 03 – 06 |
| **II · El despliegue** | Lo que la plataforma te da | 07 – 16 |
| **III · Operarlo** | Observabilidad, TLS, seguridad y diagnóstico | 17 – 21 |
| **IV · El lab de patrones** | Lo que la plataforma no te da | 22 – 26 |
| **Cierre** | El veredicto honesto y el proyecto final | 27 |

Dos reglas de método atraviesan el arco: **infra primero, dominio después** (tres oleadas
horizontales, en las Fases 02, 09 y 16) y **el servicio piloto** (`pricing` estrena cada patrón y los
otros tres lo siguen).

Tres documentos vivos crecen con el curso: `BENCHMARKS.md`, `INSTINTOS.md` y
`cuaderno-incidentes.md`. Los apéndices están en
[`propuesta-apendices-y-alcance.md`](propuesta-apendices-y-alcance.md), y el cuaderno en
[`formato-cuaderno-incidentes.md`](formato-cuaderno-incidentes.md).

---

## 10. ✅ Lo que está dentro del alcance

- Instalar y hacer convivir los dos motores en tres plataformas, con sus incidentes de instalación.
- Contenedores e imágenes con el modelo mental correcto: proceso, capas, OCI, PID 1 y señales,
  usuarios y permisos.
- Empaquetar cuatro runtimes y un frontend estático, con la medición de lo que cuesta cada uno.
- Compose como línea base, y la traducción compose ⇄ Kubernetes en las dos direcciones.
- Kubernetes local de punta a punta: cluster, cargas de trabajo, red y DNS, Gateway API,
  configuración y secretos, estado y almacenamiento, Helm, sondas y recursos, escalado y rollout.
- Observabilidad: métricas, tableros, logs y trazas distribuidas.
- TLS por capas —CA propia, cert-manager, mTLS a mano— y su laboratorio de incidentes.
- Seguridad del pod y de la red en versión práctica: `securityContext`, RBAC mínimo, `NetworkPolicy`.
- Diagnóstico con método, y un cuaderno de incidentes consultable por síntoma.
- Patrones distribuidos: resiliencia, gRPC, saga orquestada y coreografiada, idempotencia y outbox.
- El 🦭 contraste Docker contra Podman donde de verdad diverge, y la 🌩️ frontera con la nube en cada
  fase donde el laboratorio deja de parecerse a ella.
- El ⚰️ anti-patrón de cada tema con números antes y después, y el ⚖️ veredicto de cuándo **no**.

## 11. 🚫 Lo que está fuera del alcance

Se declara y el texto se detiene: **no se dice dónde estaría ese material.**

- cgroups y namespaces por dentro · SBOM, firma de imágenes y cadena de suministro · gestores de
  secretos externos · alertas y cadena de guardia · event sourcing y CQRS · desplegar en una nube de
  pago · escribir un Operator propio · un segundo motor relacional · Kafka · compose como
  herramienta de producción.
- **Ingress y los controladores de Ingress**, salvo como entrada del diccionario de traducción.
- **JVM anteriores a la 25, Jakarta EE y MicroProfile.** El laboratorio queda preparado para
  sumarlos (📌 extensión futura, §15), pero no forman parte de este curso.
- **Profundidad de negocio en el dominio**, que se mantiene mínimo a propósito, y la semilla de
  ciencia de datos que proponían los documentos preliminares.
- **Regulación farmacéutica**: fórmula médica, lotes y vencimientos, cadena de frío, control
  especial y dispensación a las EPS (§7.1).
- **Migrar datos de Oracle a Postgres, convertir PL/SQL, comparar Oracle contra Postgres, y elegir
  un proveedor de nube.** Son decisiones de la empresa de la historia, no contenido del curso.
- **Un SaaS de verdad**: facturación por cliente, alta de clientes, autenticación de varias cadenas
  y el modelo de datos multi-cliente. Del producto de la historia solo entra la pregunta de
  instalar la plataforma para una segunda cadena.
- **Contenedores Windows** (las cajas, los kioscos y los servidores de bodega de la historia son
  clientes del sistema, no cargas del cluster) e **identidad corporativa** contra el directorio de
  usuarios.
- **Enseñar a programar los servicios.** El código es andamiaje (§7.3).

---

## 12. ⚖️ Decisiones cerradas

Si una sesión futura quiere cambiar una, primero la cambia aquí y después en todo lo demás, nunca al
revés. El registro con su fecha está en la propuesta de fases §12.

1. **Idioma:** español latinoamericano neutro con tuteo. Código, comandos, nombres de archivo,
   identificadores y salida de terminal en inglés; **comentarios de código en español con tildes**.
2. **El curso es autocontenido** y no nombra ningún otro curso del repositorio.
3. **Nada de tratamiento legacy.** Todo el stack es actual y cada pieza se elige por lo que hace hoy.
4. **Stack cerrado** (§7.2): Spring Boot, Laravel, NestJS, Go y React. Sin Jakarta EE ni MicroProfile.
5. **`pricing` es el servicio piloto** de cada patrón.
6. **La JVM es la de Java 25, tal cual.** La autopsia del `OOMKilled` se escribe sobre ella.
7. **Gateway API como única entrada al sistema**, con Envoy Gateway. Ningún objeto `Ingress` se
   despliega; las alternativas al controlador se nombran con sus ventajas y desventajas.
8. **Tamaño mínimo** (§7.4): kind de un nodo por defecto, observabilidad por piezas, tres perfiles.
9. **El código es andamiaje generado**, con contrato OpenAPI documentado con Swagger UI, suite Hurl
   y prompts escalonados.
10. **Un solo proyecto de código** en `src/lab/`, que crece fase a fase y se etiqueta en git.
11. **Sin reparto horario:** peso ligera, media o densa.
12. **Ejercicios por peso:** 12 en las ligeras, 20 en las medias y 24 en las densas; 12 en la Fase 27,
    que es de criterio.
13. **Nada se publica sin haberse ejecutado**, y lo no verificado se declara con esas palabras.
14. **Versiones fijadas por digest** en `a01`, con fecha de verificación visible.
15. **Plataformas:** el autor verifica solo en macOS arm64; Windows 11 y Linux se verifican al hacer
    el curso, y mientras tanto se declaran no verificados.
16. **El cuaderno de incidentes es un archivo propio**, con 27 incidentes de IDs globales.
17. **TLS llega después de que el sistema funcione.**
18. **Versiones:** todo en su última LTS, y donde no haya línea LTS, en su última estable.
19. **Service mesh (apéndice 🔥):** Istio en modo ambient.
20. **La empresa es Droguerías La Vecina** (§7.1), con la historia como fuente de verdad narrativa.
21. **El taller arranca con el patrimonio de La Vecina** (historia §5.3): **Contingencia** —el
    código del Siga, en Eclipse GlassFish y PostgreSQL, con sus servicios SOAP—, **el portal**
    (Laravel) y **la Braqui** (Node, leyendo las tablas de Contingencia y recibiendo los traslados
    por archivo, D30). Se crea con prompts
    publicados **antes de escribir capítulos**, se documenta en `a16` y es el insumo de los
    servicios nuevos: el curso extrae, no arranca de cero.
22. **La nube del diccionario** se ilustra con las dos que discute la historia, OCI y Azure, con AWS
    y Google nombradas; el curso no elige ninguna.
23. **El legado entra en la versión que cabe en un portátil**: Contingencia, no el Siga central.
    Nada de WebLogic ni de Oracle se instala, y la razón no es una concesión del curso sino la
    historia: Contingencia se construyó en GlassFish y Postgres en 2016. Lo que el curso enseña es
    la migración de arquitectura, no la de motor.
24. **El producto embrionario** (la idea de vender el sistema a otras cadenas) entra como motivo de
    negocio y en tres fases: una segunda cadena instalada con el mismo chart (F14), cuotas por
    namespace (F15) y aislamiento de red (F20). Un SaaS de verdad queda fuera (§11).
25. **El *strangler* es camino base** (F10): el Gateway reparte el tráfico de precios entre
    Contingencia y `pricing` hasta que Contingencia no recibe nada.
26. **Un solo procedimiento cambia de casa** (F24): el préstamo entre droguerías pasa de una
    transacción en PL/pgSQL dentro de Contingencia a una saga entre servicios. El resto del PL/SQL
    de la historia queda fuera.

**Excepciones declaradas al `CLAUDE.md` del repositorio**, con su porqué (el detalle en la guía §17):

- **Sin reparto horario.** Un curso donde media hora se va esperando a que un cluster levante no
  puede estimar horas con honestidad.
- **Ejercicios por debajo de 20** en la fase ligera y en la de cierre, que son de criterio.
- **Comentarios de código en español**, porque son la parte pedagógica del bloque.
- **`0-ESTRUCTURA-CURSO.md` y los README se escriben al final**, en una tanda propia.
- **Un solo proyecto en `src/lab/`**, y no una carpeta por fase, porque el curso construye un solo
  artefacto.

---

## 13. 🏁 El proyecto final

La Fase 27 cierra con un encargo que ninguna fase explica: **desplegar un servicio nuevo de cero**
—su contrato, su imagen, su subchart, sus sondas, sus límites, sus métricas, su ruta en el Gateway
y su papel en la saga— y hacer que la suite de conformidad y el tablero de la plataforma lo
reconozcan sin tocar a los otros cuatro. Es el mejor criterio de éxito que el curso puede darse.

---

## 14. 🎯 Criterios de éxito

El curso está bien si:

- **Cada fase cierra con algo que se rompió a propósito y se arregló con método**, no con suerte.
- **Al menos una apuesta se pierde en público** y se cuenta entera.
- **Compose gana en algún sitio con número**, y el curso lo concede sin letra chica.
- **Un lector que solo hace las Partes 0 a II** sale con el sistema desplegado con Helm, sondas
  correctas y la tabla de lo que cuesta cada runtime.
- **El cuaderno se puede usar sin haber leído las fases**: se entra por síntoma y se sale con la
  causa.
- **El laboratorio entra en la memoria que promete**, medido en macOS arm64 y confirmado en las otras
  dos plataformas al hacer el curso.

---

## 15. 📌 Extensión futura, fuera de este curso

El laboratorio **queda preparado** para sumar variantes de servicio sin tocar el resto, porque el
contrato y la suite de conformidad definen qué es un servicio válido. La primera candidata es
exactamente lo que este curso deja fuera: **una variante de `inventory` en JVM anteriores (11, 17,
21) o sobre MicroProfile**, para medir contra la de Java 25 lo que cambió en arranque, memoria y
comportamiento frente al cgroup. No se escribe aquí, no se promete fecha y **ninguna fase la
menciona**; se registra para que el diseño del contrato no la cierre.
