# 🧪 Bloque 06 — Talleres (opcional)

**Todo en este bloque es opcional.** Ningún capítulo ni simulación de los bloques 01 a 05 depende de
él: el repaso para entrevistas está completo sin abrir esta carpeta. Los talleres sirven para
**palpar** lo que los capítulos describen, con un legado que funciona pero se escribió sin
organización, y para practicar lo que más cuesta a un perfil senior: orientarse rápido en una base de
código que no escribió.

El sistema es `mono-legacy`, una tienda Spring Boot con `orders`, `inventory`, `payments` y
`notifications`: sin contrato, con los errores escondidos en un `200`, paquetes por capa, un
*trigger* que devuelve stock, el proveedor de pago dentro de la transacción y el esquema creado por
Hibernate al arrancar. Diez talleres lo recuperan paso a paso **sin romper a quien lo usa**, casi todo
sin salir del monolito; el último lo distribuye solo para medir lo que cuesta.

> **Vigencia:** 2026-09-29. Todos los talleres están escritos y corridos: cada salida pegada en ellos
> es literal y de ese día. Las reglas del bloque están en §11 y §12 de la
> [guía de estilo](../prompts/guia-de-estilo-y-convenciones.md).

## 🗺️ Mapa

| # | Taller | Qué desarma | Capítulos |
|---|---|---|---|
| 01 | [Heredar el legado](01-heredar-el-legado.md) | arqueología sin documentación: rutas, tablas, la regla de pago en un `if` | `01/01`, `01/03`, `05/03` |
| 02 | [Los errores escondidos](02-los-errores-escondidos.md) | `200` con error, `500` con traza, entidades serializadas; el frontend que los sufre | `02/02`, `04/04` |
| 03 | [Caracterización](03-caracterizacion.md) | congelar lo que hay, defectos incluidos, antes de tocar nada | `03/07`, `05/03` |
| 04 | [El contrato](04-el-contrato.md) | `openapi.yaml` desde lo observado, `problem+json`, `hurl/v1`; romper un cliente a sabiendas | `02/02`, `04/04` |
| 05 | [SQLite miente](05-sqlite-miente.md) | pruebas contra otra base; el dinero en `double`; Testcontainers | `03/01`, `03/07` |
| 06 | [Modularizar](06-modularizar.md) | de capas a capacidades; el ciclo; el *trigger*; Spring Modulith y ArchUnit | `01/06`, `02/01`–`02/03`, `02/06` |
| 07 | [Transacciones y concurrencia](07-transacciones-y-concurrencia.md) | el pool agotado, la sobreventa, el doble cobro, `Idempotency-Key` | `03/01`, `03/02`, `04/05` |
| 08 | [Eventos, jobs y dos instancias](08-eventos-jobs-y-dos-instancias.md) | notificación en la transacción, *outbox*, caché y job por instancia | `02/05`, `03/03`, `03/04` |
| 09 | [Migraciones de esquema](09-migraciones-de-esquema.md) | Flyway sobre `ddl-auto`, *expand/contract* con dos versiones vivas | `02/04`, `03/05` |
| 10 | [El monolito distribuido provocado](10-el-monolito-distribuido-provocado.md) | `inventory` a otro proceso con la base compartida; medir y desmontar | `04/01`–`04/08`, `05/04` |
| 11 | [Respuestas](11-respuestas.md) | solucionario de las preguntas y ejercicios de los diez talleres | — |

Cada taller sigue la misma plantilla: qué enseña, versiones exactas, mapa de carpetas, **recorrido de
la base de código** con rutas y líneas, partes con su fallo **provocado antes** de la corrección,
evidencia, errores reales encontrados al correrlo (🩺), *teardown*, preguntas y ejercicios.

## 🔀 Dependencias y rutas de lectura

```text
01 ─┬─ 02 (frontend opcional)
    ├─ 03 ── 04 ── 06 ─┬─ 07 ── 08
    │                  └─ 09 ── 10
    └─ 05
```

El laboratorio es **acumulativo**: cada taller modifica el legado que dejó el anterior, y su estado
queda congelado en `laboratorio/estados/NN/`. Se puede empezar en cualquier taller arrancando su
estado previo con `lab.py --estado NN`.

| Si tienes… | Recorre |
|---|---|
| Una tarde | `01 → 03 → 04`: heredar, congelar, contratar |
| Una entrevista de Tech Lead Java | lo anterior más `06` y `07`: límites internos y transacciones |
| Una entrevista de arquitecto | lo anterior más `10`: distribuir, medir y desmontar |
| Tiempo para todo | en orden; `05`, `08` y `09` cierran los pecados de pruebas, runtime y esquema |

## 🔗 Relación con los laboratorios hexagonal y de microservicios

Los tres cursos comparten el caso de estudio —la misma tienda, las mismas reglas de pago, los mismos
productos—, pero cada uno lo redeclara y ninguno lee archivos de otro. Aquí el sistema empieza
**desordenado y sin contrato**, y el taller 04 reconstruye un contrato cuya forma es la unión de los
de hexagonal y microservicios. Sus suites `hurl/v1` se copiaron a `laboratorio/contrato/hurl/hex` y
`hurl/ms` (con el dominio de los usuarios sustituido y dos bloques de microservicios que contradicen
al hexagonal comentados como `NO CABE`) y pasan contra `mono-legacy` desde el taller 07. Es el punto
de enganche de la ruta completa: el legado recuperado aquí es comparable al punto de partida de los
otros dos laboratorios.

## 🧰 El laboratorio

```text
laboratorio/
├── scripts/lab.py      orquestación: Python 3, solo biblioteca estándar (lab.py -h lista las órdenes)
├── contrato/           docker-compose.yml, seed/, toxiproxy/, openapi.yaml, hurl/{legacy,v1,hex,ms}
├── legacy/             mono-legacy: Java 25, Spring Boot 4.1.1, :38081
├── inventory/          mono-inventory, solo para el taller 10, :38082
├── psp-simulator/      el proveedor de pago externo, :38085 (detrás de Toxiproxy en :38185)
├── frontend/           cliente React opcional, :35173
└── estados/01 … 10/    el laboratorio congelado al cerrar cada taller
```

Todo corre en local con Docker (PostgreSQL 17.11 y Toxiproxy); no hay nube ni gasto. Nombres,
puertos, credenciales y versiones fijas: §12 de la guía.

## 💨 Prueba de humo

Desde `06-talleres/`, con el estado final:

```bash
python3 laboratorio/scripts/lab.py check
python3 laboratorio/scripts/lab.py up
python3 laboratorio/scripts/lab.py psp          # en otra terminal
python3 laboratorio/scripts/lab.py legacy       # en otra terminal
python3 laboratorio/scripts/lab.py suite
python3 laboratorio/scripts/lab.py down
```

- `check` comprueba que Docker, `hurl`, Maven, el JDK 25 y Python están instalados, sin instalar nada.
- `up` levanta PostgreSQL (`mono-postgres`, `:35432`) y Toxiproxy (`mono-toxiproxy`) y espera a que
  estén sanos.
- `psp` arranca el simulador del proveedor de pago; `legacy` compila y arranca `mono-legacy`, que al
  arrancar aplica sus migraciones de Flyway. Los dos quedan en primer plano; se paran con Ctrl+C.
- `suite` siembra la base y corre `contrato/hurl/v1` contra `:38081`.
- `down` apaga el entorno y borra sus volúmenes.

Salida del 2026-09-29:

```text
docker   Docker version 29.8.0, build 88096ef
hurl     hurl 8.0.1 (x86_64-apple-darwin25.0) libcurl/8.7.1 (SecureTransport) LibreSSL/3.3.6 zlib/1.2.12 nghttp2/1.68.1
mvn      Apache Maven 3.9.10 (5f519b97e944483d878815739f519b2eade0a91d)
java     openjdk version "25.0.4" 2026-07-21 LTS
python   3.13.4
```

```text
Success 07-notifications.hurl (10 request(s) in 2265 ms)
Success 08-reports.hurl (5 request(s) in 226 ms)
Success 09-idempotency.hurl (13 request(s) in 162 ms)
--------------------------------------------------------------------------------
Executed files:    9
Executed requests: 99 (15.9/s)
Succeeded files:   9 (100.0%)
Failed files:      0 (0.0%)
Duration:          6245 ms (0h:0m:6s:245ms)
```

## 🚫 Qué no está aquí

- No es un curso de Spring Boot, JPA ni React: cada taller explica la decisión, no el framework.
- No hay nube, Kubernetes ni *mesh*: las «dos instancias» del taller 08 son dos procesos locales.
- No hay versiones en otros lenguajes: los talleres son solo Java, y el contraste entre plataformas
  vive en los capítulos.
- `reports/orders-summary` y `batches/{id}` siguen siendo consultas síncronas disfrazadas de lote: ningún
  taller las convierte en un lote real (es el taller 11 del curso hexagonal).
- Los secretos siguen en `application.yaml`: se señalan en el taller 01 y su arreglo es de los cursos
  de nube.
