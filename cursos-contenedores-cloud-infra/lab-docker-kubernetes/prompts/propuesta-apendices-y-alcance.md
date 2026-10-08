# 📎 Propuesta de apéndices y alcance
## Laboratorio de contenedores y Kubernetes local — dieciséis apéndices

> **Qué es este documento:** qué cubre cada apéndice, qué deja fuera, cuándo se escribe y cuántos
> ejercicios lleva. Los prompts de [`prompts-de-apendice.md`](prompts-de-apendice.md) copian de
> aquí.
> **Precedencia:** debajo del [alcance](alcance-del-proyecto.md), de la
> [guía](guia-de-estilo-y-convenciones.md) y del [contrato del cluster](contrato-del-cluster.md), al
> mismo nivel que la [propuesta de fases](propuesta-fases-y-alcance.md).
> **Fecha:** 30/09/2026. Sale de la §6 de la propuesta de fases del 14/09, renumerada, con tres
> apéndices nuevos (`a01`, `a05` y `a08`), más `a16` (D19, D29). Todas sus decisiones están
> cerradas.

---

## 1. 🧭 Qué es un apéndice en este curso

Un apéndice **no se lee de corrido**: se entra por el índice buscando algo concreto y se sale. Es
receta, referencia o ampliación, nunca camino base, y no lleva peso declarado.

Hay tres clases, y cada una tiene su regla:

- **De laboratorio** (`a01`–`a03`, y `a16`): el curso no funciona sin ellos. `a16` lleva el número
  más alto porque fue el último en decidirse, no porque sea el último en escribirse. Se escriben **antes** de la fase
  que los necesita y quedan verificados en macOS arm64; lo de Windows y Linux se declara no
  verificado por el autor.
- **De consulta que crece** (`a04`, `a05`): se abren con su esqueleto y cada fase les suma sus
  entradas en la misma tanda.
- **Ampliaciones 🔥** (`a06`–`a15`): opcionales. Ninguna fase depende de ellas; las fases las
  señalan con un puntero y siguen.

Cuatro reglas lo mantienen en su sitio:

- **Un apéndice no repite lo que explica una fase: la enlaza.**
- **Nada sin ejecutar.** Lo no verificado se declara con esas palabras.
- **Los nombres técnicos son los del contrato del cluster.**
- **Los 🔥 respetan el presupuesto de memoria**: si una ampliación no entra en el perfil `lab`, lo
  dice en su encabezado con el número medido, y propone qué apagar.

---

## 2. 📊 Los dieciséis, de un vistazo

| # | Archivo | Qué es | Ej. | Cuándo se escribe | Tag |
|---|---|---|---|---|---|
| a01 | `a01-el-laboratorio.md` | versiones, Taskfile, perfiles, memoria | 8 | antes de F00 | ✅ |
| a02 | `a02-problemas-del-ambiente.md` | la cola larga de la instalación, por plataforma | 8 | antes de F00; crece | — |
| a03 | `a03-contratos-y-prompts-de-generacion.md` | OpenAPI, suite Hurl, matriz G0–G13 | 8 | antes de F02; crece por paso | ✅ |
| a04 | `a04-kubectl-y-k9s.md` | referencia rápida | 10 | esqueleto antes de F07; crece | — |
| a05 | `a05-diccionarios.md` | compose ⇄ K8s, `Ingress` ⇄ Gateway, local ⇄ nube | 6 | esqueleto antes de F06; crece | — |
| a06 | `a06-arquitecturas-y-multiplataforma.md` | 🔥 ARM, amd64 y la emulación | 6 | T13 | — |
| a07 | `a07-imagenes-sin-docker.md` | 🔥 Buildah, Kaniko, Jib, ko | 6 | T13 | — |
| a08 | `a08-la-jvm-nativa.md` | 🔥 compilación nativa contra AOT cache, medido | 6 | T13 | — |
| a09 | `a09-frontend-con-runtime.md` | 🔥 renderizado en servidor | 5 | T13 | — |
| a10 | `a10-service-mesh.md` | 🔥 mTLS, reintentos y métricas sin tocar código | 6 | T13 | — |
| a11 | `a11-gitops-de-lectura.md` | 🔥 qué resuelve y qué cuesta | 5 | T13 | — |
| a12 | `a12-operators-de-lectura.md` | 🔥 recursos propios y controladores | 5 | T13 | — |
| a13 | `a13-respaldo-y-restauracion.md` | 🔥 los datos del cluster | 6 | T13 | — |
| a14 | `a14-las-gui.md` | 🔥 Headlamp, Podman Desktop, Docker Desktop | 5 | T13 | — |
| a15 | `a15-statefulset-de-varios-miembros.md` | 🔥 arranque ordenado y failover | 6 | T13 | — |
| a16 | `a16-el-patrimonio.md` | de laboratorio: Contingencia, el portal y la Braqui, cómo están hechos y con qué prompts | 6 | T1b, antes de F00 | ✅ |

Los nombres de archivo son canónicos y no se renumeran.

---

## 3. 🧰 a01 — El laboratorio (8 ejercicios)

- **Alcance:** la tabla de **versiones fijadas** —motores, kind, la imagen de nodo, kubectl, Helm,
  helm-diff, k9s, el controlador de Gateway, cert-manager, trust-manager, Prometheus, Grafana, Loki,
  Fluent Bit, Tempo, metrics-server, Postgres, Valkey, NATS, k6, hyperfine, Hurl, dive, Python y las
  imágenes base de los cinco servicios—, cada una con su digest o su checksum y la fecha de verificación.
  **Es el único sitio del curso donde vive una versión.** El Taskfile, tarea por tarea, con el
  comando que corre debajo. Los tres perfiles y sus interruptores. Y **la tabla de memoria medida**
  (B-00): cuánto ocupa cada perfil con cada motor en macOS arm64, y cuánta memoria hay que darle a
  la máquina virtual de Docker Desktop o de Podman. La tabla deja una columna para Windows 11 y
  Linux, vacía hasta que alguien la mida al hacer el curso.
- **🐍 Sección corta: los scripts (D31).** Lo mínimo para correr los scripts del laboratorio y nada
  más: dónde viven (`src/lab/scripts/<sección>/`, cada directorio con su `requirements.txt`), cómo
  la tarea del Taskfile crea el `.venv` si no existe e instala las dependencias, y **la única
  diferencia entre sistemas que el lector tiene que conocer**: el intérprete del entorno está en
  `.venv/bin/python` en macOS y Linux, y en `.venv\Scripts\python.exe` en Windows, y el Taskfile la
  resuelve con una variable por sistema. **Un ejemplo breve:** `scripts/seed/`, que siembra
  droguerías y productos con Faker en `es_CO` —un `requirements.txt` de una línea, un script de
  unas treinta líneas y su tarea `seed:generate`—. Es el mismo seed que la F12 corre como `Job`.
- **No entra:** instalar nada (es la Fase 00), explicar ninguna herramienta, enseñar Python ni
  `venv`: el lector sabe buscarlos.
- **Depende de:** la verificación de laboratorio (P11, hecha el 03/10/2026; sus hallazgos están en
  `prompts/verificacion-de-laboratorio/hallazgos.md`). **B-00 se publica en tres entregas**: la
  infraestructura por perfil y por motor en T1, el perfil `legacy` en T1b y los cinco servicios en
  T2; cada entrega declara lo que falta. Lleva tag propio porque deja `src/lab/Taskfile.yml` y
  `src/lab/kind/`.

## 4. 🩺 a02 — Solución de problemas del ambiente (8 ejercicios)

- **Alcance:** la cola larga de la Fase 00, por plataforma y en el orden de siempre. En Windows:
  las características de WSL 2 y su estado real, la virtualización en firmware, el servicio de
  cómputo de Hyper-V, el `DISM` que parece colgado, el *pipe* que se pelean los dos motores y la
  variable de entorno que rompe el CLI de Podman. En macOS: la máquina de Podman y su proveedor de
  virtualización, la memoria asignada, Rosetta. En Linux: el socket, el grupo y rootless. Y lo común:
  el cluster de kind que no revive tras reiniciar el equipo, y la creación que excede el tiempo con
  Podman.
- **No entra:** lo que ya cuentan los cuatro incidentes de ambiente del cuaderno; se enlazan.
- **Fuente de partida:** la guía de Windows del material preliminar, que se reescribe verificada y
  no se cita.

## 5. 📜 a03 — Los contratos y los prompts de generación (8 ejercicios)

- **Alcance:** cómo se lee y se cambia un OpenAPI del curso, y cómo se navega con Swagger UI
  (`task contracts:docs`), que corre en un contenedor y nunca entra al cluster; la suite de conformidad en Hurl y cómo
  se corre contra compose y contra el cluster; **la matriz de generación** (contrato del cluster §6),
  con el prompt completo de cada celda, el `CLAUDE.md` de cada servicio y la regla de que ninguna
  capacidad llega antes que su fase; y qué hacer cuando el código generado no pasa la suite.
- **Crece por paso:** cada tanda que estrena un paso G agrega aquí sus prompts, en la misma tanda.
- **No entra:** enseñar a programar ninguno de los cinco stacks.
- Lleva tag propio porque deja `src/lab/contracts/`.

## 6. ⌨️ a04 — `kubectl` y k9s (10 ejercicios)

- **Alcance:** los verbos de trabajo diario agrupados por pregunta (qué hay, qué le pasa, qué dice,
  entrar, reenviar un puerto, depurar con un contenedor efímero), las salidas que conviene leer
  (`-o wide`, `-o yaml`, `jsonpath`), contextos y namespaces, y los atajos de k9s que corresponden a
  cada uno.
- **Crece:** cada fase de la Parte II y la 21 le suman lo que estrenan.
- **No entra:** los objetos; los explican sus fases.

## 7. 📖 a05 — Los diccionarios (6 ejercicios)

- **Alcance:** tres tablas en las dos direcciones. **compose ⇄ Kubernetes** (la de la Fase 06,
  completa), **`Ingress` ⇄ Gateway API** (para leer clusters ajenos: cada campo y cada anotación
  común con su equivalente, y qué no tiene traducción), y **local ⇄ nube** 🌩️ (`kind load` ⇄ un
  registry gestionado, `StorageClass` ⇄ el disco del proveedor, `LoadBalancer` ⇄ una IP facturada,
  HPA ⇄ el autoescalado de nodos encima, `Secret` ⇄ el gestor de secretos, y la 🚧 frontera de lo
  que el laboratorio nunca da). **Las columnas de la nube son OCI y Azure**, las dos que discute la
  historia, con AWS y Google nombradas al pie (D21); el apéndice no recomienda ninguna.
- **Crece:** cada fase que tiene 📖 o 🌩️ suma sus filas.

## 8. 🔥 a06 — Arquitecturas y builds multiplataforma (6 ejercicios)

- **Alcance:** ARM contra amd64, `--platform`, imágenes multiarquitectura, y el diagnóstico de la
  imagen que corre lentísima bajo emulación (*"¿por qué mi pod tarda cuarenta segundos en
  arrancar?"*).

## 9. 🔥 a07 — Construir imágenes sin Docker (6 ejercicios)

- **Alcance:** Buildah, Kaniko, y los constructores por lenguaje (Jib para Java, ko para Go), con la
  misma medición de tamaño de la Fase 04 para comparar.

## 10. 🔥 a08 — La JVM nativa (6 ejercicios)

- **Alcance:** `inventory` compilado de forma nativa contra `inventory` con AOT cache contra
  `inventory` a secas: tamaño, build, arranque, readiness y memoria, con el arnés de la Fase 04. Y el
  veredicto de qué se pierde con la nativa (tiempo de build, reflexión, perfiles de ejecución).
- **No entra:** migrar entre versiones de Java (fuera de alcance).

## 11. 🔥 a09 — Qué cambia cuando el frontend necesita un runtime (5 ejercicios)

- **Alcance:** el `storefront` con renderizado en servidor: pasa a ser un servicio, con sondas,
  memoria y escalado, y la configuración deja de hornearse. Es el contrapunto de la Fase 11.

## 12. 🔥 a10 — Service mesh (6 ejercicios)

- **Alcance:** mTLS automático, reintentos y métricas de red sin tocar el código, contra la versión
  a mano de las Fases 19 y 22, con **Istio** (D15) en su modo **ambient**, que no inyecta un proxy
  por pod y es el que menos memoria suma. El apéndice declara la medición de memoria delante, y
  nombra Linkerd y Cilium como alternativas con sus ventajas y desventajas.

## 13. 🔥 a11 — GitOps, de lectura (5 ejercicios)

- **Alcance:** qué resuelve, qué cuesta (un repositorio, un flujo y un plano de control) y por qué
  no está en el camino base. Se puede instalar y mirar; no se construye el flujo.

## 14. 🔥 a12 — Operators y recursos propios, de lectura (5 ejercicios)

- **Alcance:** qué es un recurso propio y su controlador, reconocidos en lo que el curso ya instaló
  (cert-manager, el controlador de Gateway). Escribir uno queda fuera.

## 15. 🔥 a13 — Respaldo y restauración (6 ejercicios)

- **Alcance:** respaldar y restaurar el Postgres del cluster con un `CronJob`, y qué pasa con los
  datos cuando se borra el cluster de kind.

## 16. 🔥 a14 — Las GUI (5 ejercicios)

- **Alcance:** Headlamp para el cluster, Docker Desktop y Podman Desktop para los motores: las tres
  capas (motor, orquestador, GUI) y cuándo una GUI ayuda y cuándo esconde lo que el lector tiene que
  ver.

## 17. 🔥 a15 — Un `StatefulSet` de varios miembros (6 ejercicios)

- **Alcance:** un almacén replicado con arranque ordenado, identidad estable por miembro y failover
  provocado, para ver lo que el Postgres de un solo miembro de la Fase 12 no muestra. El motor es
  **NATS con JetStream en tres miembros** (D25): ya está en el stack desde la Fase 25, pesa poco, y
  su consenso por quórum deja provocar la caída del líder y ver la elección del siguiente sin sumar
  un motor nuevo. MongoDB, la candidata del material preliminar, se nombra como alternativa.

## 18. 🏚️ a16 — El patrimonio (6 ejercicios)

- **Alcance:** lo que La Vecina ya tiene, en la versión que cabe en un portátil, y con lo que arranca
  el taller: **Contingencia** (el código del Siga con JPA e Hibernate, en Eclipse GlassFish, sobre
  su propio PostgreSQL, con dos servicios SOAP —precio y existencias— y el procedimiento del
  préstamo en PL/pgSQL), **el portal** (Laravel creado con `artisan`, con su SQLite, su catálogo
  propio y el job nocturno que lo trae de Contingencia) y **la Braqui** (Node, sondeando cada
  treinta segundos las tablas de despachos de Contingencia, y recibiendo los traslados de préstamo
  por archivo: Contingencia deja el `.txt` y su `.ok` en un volumen compartido, y un script de
  Python con `cron` los recoge cada cinco minutos, con sus tres parches; D30). Cómo se levanta (`task legacy:up`),
  qué mañas tiene a propósito —las de la historia— y **el prompt publicado de cada pieza**.
- **La nota de licencias, en una línea y desde la historia:** el laboratorio no usa WebLogic ni
  Oracle porque arranca de Contingencia, que se construyó en GlassFish y Postgres en 2016.
- **🔥 Sección corta: los dialectos.** El procedimiento del préstamo en PL/SQL (como texto, de la
  historia) contra su versión en PL/pgSQL de Contingencia: `NULL` y texto vacío, secuencias, `NVL`,
  `ROWNUM`. Es contexto para la Fase 24, no tema del curso.
- **No entra:** WebLogic, Oracle Database, migrar datos, ni el *strangler* (es la Fase 10).
- **Depende de:** P11, ya hecha: la imagen oficial de Eclipse GlassFish 8.0.4 es arm64 nativa, pesa
  1 GB, corre con JDK 21 (no con el 25 del curso, y se dice) y trae Metro y JAXB, así que los
  servicios SOAP no necesitan nada extra. Lleva tag propio: `apendice-a16-patrimonio`.

---

## 19. 📌 Pendientes de este documento

- ✅ **D14** (los quince, renumerados), **D15** (Istio en `a10`), **D19** y **D29** (`a16`, el patrimonio, de laboratorio), cerradas por Oskar.
- ✅ **D25**: el motor de `a15` es NATS con JetStream en tres miembros.
