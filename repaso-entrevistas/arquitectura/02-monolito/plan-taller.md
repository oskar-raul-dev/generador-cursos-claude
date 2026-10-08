# 🧪 Plan del bloque de talleres · repaso de monolito

> Documento de **análisis y armado del plan**, no de producción. Recoge las decisiones de la sesión
> de diseño del 29-09-2026 para un bloque `06-talleres/` **opcional** en este corpus, a imagen de los
> que tienen `03-hexagonal/` y `04-microservicios/`, y para un capítulo comparativo
> nuevo en el bloque 01. Todavía no se ha tocado ningún otro archivo: la guía, el `prompt-base.md`,
> el plan de producción y el README siguen diciendo que **no hay laboratorio**. Lo que este
> documento fija se traslada a esos archivos en la primera tanda (ver §12).
>
> **Vigencia:** 2026-09-29.
>
> 📝 **Trasladado el 2026-09-29.** Las decisiones de este registro están ahora en la guía (§3, §5,
> §6, §8, §11, §12, §13), en `prompt-base.md` (§1, ficha `01/06` y §9) y en
> `prompts/plan-de-produccion-talleres.md`, que mandan sobre este documento. Dos cambios respecto de
> lo que aquí se propone: la numeración de tandas continúa la del plan teórico (T11 capítulo `01/06`,
> T12 idioma del corpus, T13–T23 talleres) en lugar de la de §12; y el hueco de *sticky sessions*
> de §7 no existía, porque `03/04` ya cubre la afinidad de sesión. Los ajustes que salgan de revisar
> este plan se hacen en `prompts/`, no aquí.
>
> ✅ **Ejecutado el 2026-09-29.** Los diez talleres (T13–T22) están escritos y corridos, y T23 cerró el
> bloque con su README. Lo que cambió respecto de este registro al correrlos está en la bitácora de
> `prompts/plan-de-produccion-talleres.md` §7; este documento no se actualiza más.

---

## Salto rápido

- [1. Qué se quiere y qué no](#1--qué-se-quiere-y-qué-no)
- [2. Decisiones cerradas](#2--decisiones-cerradas)
- [3. El caso de estudio](#3--el-caso-de-estudio)
- [4. El legado y sus pecados](#4--el-legado-y-sus-pecados)
- [5. La tensión del contrato: 200 para todo](#5--la-tensión-del-contrato-200-para-todo)
- [6. La serie de talleres](#6--la-serie-de-talleres)
- [7. El capítulo comparativo nuevo](#7--el-capítulo-comparativo-nuevo)
- [8. Dependencias y rutas de lectura](#8-️-dependencias-y-rutas-de-lectura)
- [9. Reglas transversales](#9--reglas-transversales)
- [10. Contradicciones con la guía y su corrección](#10-️-contradicciones-con-la-guía-y-su-corrección)
- [11. Fuera de alcance y decisiones abiertas](#11--fuera-de-alcance-y-decisiones-abiertas)
- [12. Siguientes pasos](#12-️-siguientes-pasos)

---

## 1. 🎯 Qué se quiere y qué no

Los capítulos enseñan a **decidir qué permanece unido, qué necesita un límite y cuánto cuesta
distribuir**. Lo que no pueden enseñar es la experiencia de **heredar un monolito escrito sin
organización** —sin contrato, sin documentación, con los errores escondidos en un `200`— y
recuperarle límites sin romper a quien lo usa. Eso se palpa corriéndolo.

```text
Capítulos   → la decisión, la evidencia, el coste, el veredicto.
Talleres    → el mismo monolito heredado, el fallo provocado antes de la corrección,
              y la evidencia pegada.
```

**La tesis del bloque.** El dolor de un monolito casi nunca viene de la tecnología: viene de
**trabajar sin organización**. Por eso hay un solo sabor (Java) y ningún taller termina en "hay que
partirlo en servicios" sin haber intentado antes arreglarlo dentro.

**La ruta completa.** Este bloque es la precuela natural de los otros dos laboratorios:

```text
02-monolito/06-talleres          el legado, "a la maldita sea"
        │  (estado 04: contrato fijado, errores normalizados)
        ├──────────────► 03-hexagonal/06-talleres        la frontera dentro del proceso
        └──────────────► 04-microservicios/06-talleres   la frontera en la red
```

Los tres cursos siguen siendo **independientes**: nada aquí exige haber hecho los otros, ni al
revés. El enganche es de caso de estudio y de contrato, no de archivos compartidos.

**Qué no es:**

- No es un curso de Spring Boot. El framework aparece lo justo para ubicar la decisión.
- No es un taller de frontend legado. El frontend es un cliente React **limpio** que sufre la API
  sucia; el frontend legado es otro curso.
- No es un laboratorio de nube. Todo corre en local con Docker Compose.
- No es obligatorio. El corpus teórico se sostiene sin él, y cada taller lo declara en su primer
  párrafo.

---

## 2. 🧭 Decisiones cerradas

| # | Decisión | Motivo |
|---|---|---|
| D1 | **Mismo caso de estudio que hexagonal y microservicios**: tienda con catálogo, pedidos, reserva de inventario, pago, notificaciones y autenticación; misma semilla y misma regla determinista de pago | Si se hace la ruta completa, el legado es el insumo de los otros dos laboratorios |
| D2 | **Legado nuevo e independiente, `mono-legacy`**, más desordenado que `ms-monolith`. El estado al cerrar el taller 04 es **comparable** a `ms-monolith` estado 01: mismas rutas, mismo contrato, mismos defectos de transacción | No se toca un curso ya cerrado y corrido; la comparabilidad basta para la ruta |
| D3 | **Por fuera, la unión de los dos contratos**: el superconjunto de hexagonal (`v1` de microservicios es un subconjunto) | Al salir del legado, las dos suites `hurl/v1` pasan sin cambios |
| D4 | **Pero con el error típico**: todo responde `200` y el error va en el JSON; un fallo no controlado devuelve `500` con la traza de Java en el cuerpo. El taller 04 lo normaliza a `problem+json` (§5) | Es lo que se hereda de verdad, y rompe al frontend |
| D5 | **Sin OpenAPI de partida.** El contrato se reconstruye desde el comportamiento observado | Así se hace en la realidad empresarial |
| D6 | **Un solo sabor: Java 25 + Spring Boot 4.1.1**, las mismas versiones que los otros dos laboratorios | El dolor no depende del lenguaje; Java es el perfil base |
| D7 | **PostgreSQL 17 en ejecución, SQLite en las pruebas** del legado. El taller 05 demuestra por qué eso miente | Otro pecado real, y da un taller entero |
| D8 | **Frontend React opcional, en la última versión estable** (a verificar en T0), cliente limpio | Sirve para ver romperse lo que la API esconde: `200` con error, traza en un `500` |
| D9 | **Incluye el taller del monolito distribuido provocado** (10) | Es el más valioso para el bloque 04 del corpus |
| D10 | **Vibecoding declarado**, como en los otros dos laboratorios: el código se genera con un asistente y el taller explica decisiones, no líneas | Se quieren ideas arquitectónicas, no frameworks |
| D11 | **Orquestación con `lab.py`** (Python 3, solo biblioteca estándar), **suite con `hurl`** y **estados congelados** en `laboratorio/estados/NN/` | Multi-OS, misma herramienta que los otros dos; cada taller es reproducible solo |
| D12 | **Capítulo comparativo nuevo** sobre estilos de estructura interna, incluidos clean y onion (§7) | El corpus tiene cero menciones a clean y onion, y ninguna a Transaction Script o Active Record |

---

## 3. 🏪 El caso de estudio

El dominio es el de los otros dos laboratorios, **copiado y redeclarado**, no enlazado. Si mañana
cambia la semilla de hexagonal, este bloque no se entera.

| Qué | Valor |
|---|---|
| Productos semilla | `SKU-001` teclado 49.90 (stock 20) · `SKU-002` cable 9.90 (100) · `SKU-003` monitor 222.00 (5) · `SKU-004` webcam 59.00 (**0**) · `SKU-005` workstation 1499.00 (3) |
| Regla determinista de pago | total `> 1000.00` → rechazado; total `== 666.00` → resultado incierto; resto → autorizado |
| Usuarios | un cliente y un operador, con JWT HS256 |
| Moneda | `USD`. En el legado, **`double`** a propósito; el taller 05 lo convierte en decimal |
| Rutas | `health`, `auth/login`, `auth/logout`, `products` (GET y POST), `products/{sku}`, `orders` (GET y POST), `orders/{id}`, `orders/{id}/payment`, `orders/{id}/cancel`, `notifications`, `reports/orders-summary`, `batches/{id}` |

`SKU-004` provoca el stock insuficiente, `SKU-005` el pago rechazado y tres `SKU-003` suman
`666.00`, el pago incierto.

📝 El vocabulario del corpus está en español (`CrearPedido`, `Pedidos`, `Inventario`); el código,
en inglés (`CreateOrder`, `orders`, `inventory`). La guía gana un diccionario inglés → español en
T0, igual que el de microservicios.

---

## 4. 🧟 El legado y sus pecados

`mono-legacy`: Spring Boot 4.1.1 sobre JDK 25 y una base PostgreSQL, **organizado por capa técnica**
(`controller/ service/ repository/ entity/ util/`). Cada defecto está puesto a propósito y tiene un
taller que lo desarma:

| Pecado a propósito | Qué taller lo desarma |
|---|---|
| Sin README útil ni OpenAPI; la regla de pago solo existe en un `if` | `01` |
| Todo responde `200`; el error va en `{"error": "..."}` con mensajes libres | `02`, `04` |
| Un fallo no controlado devuelve `500` con la traza de Java en el cuerpo (`server.error.include-stacktrace=always`) | `02`, `04` |
| `@Entity` serializada directamente en el JSON (con `hashed_password` incluido, y `LazyInitializationException` al azar) | `02`, `04` |
| Pruebas contra SQLite; el dinero en `double` | `05` |
| `products` e `inventory` en **una sola tabla** | `09` (y lo que la separa es el esquema que hexagonal da por hecho) |
| `ddl-auto: update` en lugar de migraciones | `09` |
| Paquetes por capa; servicios que se llaman en ciclo (`OrderService` ↔ `InventoryService`) | `06` |
| Lógica repartida entre controlador, servicio y un *trigger* de PostgreSQL | `06` |
| El proveedor de pago llamado **dentro** de la transacción de base de datos | `07` |
| Stock descontado con leer-restar-escribir, sin bloqueo ni versión | `07` |
| Sin idempotencia en `POST /orders` ni en el pago | `07` |
| Notificación escrita en la misma transacción que la cancelación | `08` |
| Caché en memoria y `@Scheduled` que corre en cada instancia | `08` |
| Secretos en `application.yaml` | declarado en `01`; el arreglo no es de este curso |

> 📝 El legado **no** es modular a propósito. Si lo fuera, los talleres 06 a 08 no tendrían
> material.

---

## 5. 🔀 La tensión del contrato: 200 para todo

D3 y D4 tiran en direcciones opuestas: las suites de hexagonal y de microservicios esperan códigos
de estado y `problem+json`, y el legado responde `200` con el error dentro. La solución es un
recorrido en dos pasos, que es exactamente el que se sigue en una empresa:

```text
taller 03   hurl/legacy   caracteriza lo que HAY: 200 + {"error"}, 500 + traza.
                          Es un golden master: congela también los defectos.
taller 04   openapi.yaml  se escribe desde lo observado, con los errores ya bien:
            hurl/v1       problem+json, 4xx/5xx reales, sin traza.
                          El legado se corrige en un único @RestControllerAdvice.
                          hurl/legacy deja de pasar, y eso se muestra.
```

El paso de uno a otro **rompe al cliente**, y el taller lo hace visible: el frontend que ya había
aprendido a leer `{"error"}` dentro de un `200` deja de mostrar errores. Se resuelve con versionado
declarado (`v1` nace ya correcto; el legado era "v0" sin nombre) y se discute la alternativa
realista: una cabecera o *feature flag* para migrar a los clientes de uno en uno.

**Criterio de enganche:** al cerrar el taller 04, las suites `hurl/v1` **copiadas** de hexagonal y
de microservicios pasan contra `mono-legacy`. Si alguna ruta de uno de los dos contratos no se puede
cumplir sin cambiar el caso de estudio, se declara en §11 y no se fuerza.

---

## 6. 📚 La serie de talleres

| Taller | Qué se hace | Lo que se palpa | Depende de |
|---|---|---|---|
| `01` · Heredar el legado | Levantarlo, arqueología sin documentación: rutas desde el código y los logs, la regla de pago desde un `if` | Tomar una base de código ajena y aprender sobre la marcha | — |
| `02` · Los errores escondidos *(con frontend opcional)* | Provocar `200` con error, `500` con traza, entidad lazy serializada; ver al frontend quedarse en blanco | Por qué sin contrato el cliente se acopla a los accidentes | 01 |
| `03` · Caracterización | `hurl/legacy` como golden master del comportamiento actual, defectos incluidos | Red de seguridad antes de tocar nada | 01 |
| `04` · El contrato | `openapi.yaml` desde lo observado; `problem+json`; `hurl/v1` en verde; las suites de hexagonal y microservicios también | Romper a un cliente a sabiendas y migrarlo | 03 |
| `05` · SQLite miente | Pruebas verdes en SQLite, rojas en PostgreSQL (`FOR UPDATE`, `double`, `LIKE`, fechas); Testcontainers | Evidencia que no es evidencia | 01 |
| `06` · Modularizar | De paquete por capa a paquete por capacidad; API pública por módulo; romper el ciclo; mover la lógica del *trigger*; ArchUnit y Spring Modulith | Recuperar límites sin cambiar de topología | 04 |
| `07` · Transacciones y concurrencia | Proveedor lento con Toxiproxy agota el pool y tumba el catálogo; sacar la llamada de la transacción; sobreventa concurrente; bloqueo y versión; idempotencia | Se arregla **sin** partir el monolito | 06 |
| `08` · Eventos, jobs y dos instancias | Evento interno tras el commit; outbox local; escalar a dos instancias: caché incoherente y `@Scheduled` duplicado | El monolito también escala, y también se equivoca al escalar | 07 |
| `09` · Migraciones | Flyway sobre una base creada con `ddl-auto`; separar `products` de `inventory` con *expand/contract*; *rollback* | Cambiar el esquema con la aplicación viva | 06 |
| `10` · El monolito distribuido provocado | Sacar `inventory` a otro proceso **compartiendo la base**; llamadas síncronas; Toxiproxy; despliegue en *lockstep*; después desmontarlo: fusionar o corregir | Distribuir sin límites no compra autonomía | 09 |
| `11` · Respuestas | Solucionario único del bloque, enunciado literal | — | — |

El frontend no tiene taller propio: vive en `laboratorio/frontend/` y aparece como sección opcional
**🖥️ En el frontend** en `02`, `04` y `07`.

---

## 7. 🧱 El capítulo comparativo nuevo

`01/06` — **Estilos de estructura interna: capas, clean, onion y vertical slice.** Cierra el bloque
01 antes de la simulación; la simulación y el solucionario pasan a `07` y `08`.

- **Objetivo:** elegir cómo se organiza el código dentro de un despliegue y saber qué garantiza cada
  estilo, sin confundirlo con la topología.
- **Cubre:** capas (N-tier) y su regla real; paquete por capa frente a paquete por capacidad; clean
  architecture y onion como variantes de la regla de dependencias; vertical slice; dónde vive la
  lógica (Transaction Script, Active Record, Domain Model); qué estilo tolera qué tamaño de equipo y
  de dominio.
- **🧰 Plataformas:** estructura de paquetes o módulos en Java · Node/TS · Go · Python, y qué
  herramienta hace cumplir la regla en cada una.
- **Desmonta:** «clean y hexagonal son lo mismo con otro nombre», «capas equivale a mal diseño» y
  «vertical slice elimina la necesidad de límites».
- **Se toca con:** `01/03`, `02/01`, `02/03`; y con el curso hexagonal, en prosa, para la
  profundidad.
- **Preguntas:** 24, como el resto de capítulos; el solucionario de `01` y la simulación se amplían
  en consecuencia.

Otros huecos menores, que se resuelven como secciones sin capítulo nuevo: estado en memoria y
*sticky sessions* en `03/04`; método Mikado en `05/03`; capa anticorrupción al extraer en `05/04`.

---

## 8. 🗺️ Dependencias y rutas de lectura

```text
01 ─┬─ 02 (frontend opcional)
    ├─ 03 ── 04 ── 06 ─┬─ 07 ── 08
    │                  └─ 09 ── 10
    └─ 05
```

- **Una tarde:** `01` → `03` → `04`. Es el enganche con los otros dos laboratorios.
- **Tech Lead Java:** `01` → `03` → `04` → `06` → `07`. Son las preguntas que más se repiten: cómo
  metes una red de seguridad en un legado y cómo arreglas el pool sin partir el sistema.
- **Arquitecto:** añadir `10`. Es el argumento, con evidencia, de por qué distribuir no arregla
  límites.

---

## 9. 🧰 Reglas transversales

### 9.1 Forma común

La misma forma que los talleres de microservicios: qué enseña, prerrequisitos y versiones, mapa de
carpetas, recorrido, provocación **antes** de la corrección, errores reales al correrlo, teardown,
preguntas y ejercicios graduados 🟢🟡🟠🔴. Salidas **corridas**, nunca inventadas, con fecha y
máquina de referencia.

### 9.2 Nombres fijos, propuesta

| Qué | Valor |
|---|---|
| Prefijo | `mono-` |
| Aplicación | `mono-legacy` en `:38081`; paquete `dev.mono.legacy` |
| Proceso extraído (taller 10) | `mono-inventory` en `:38082` |
| PostgreSQL | `mono-postgres` en `:35432`, base `mono_legacy` |
| Proveedor de pago | `psp-simulator` en `:38085`; Toxiproxy `mono-toxiproxy`, proxy `psp` en `:38185`, API en `:38474` |
| Frontend | `:35173` |

Los puertos no chocan con microservicios (`2xxxx`) ni con hexagonal (`8081`–`8085`).

---

## 10. ⚠️ Contradicciones con la guía y su corrección

| # | La guía dice | El plan dice | Corrección en T0 |
|---|---|---|---|
| C1 | §6: eje Java · Node/TS · Go · Python | Talleres solo en Java | Nueva sección de talleres en la guía que declare el sabor único y su motivo (D6) |
| C2 | §1.1: no es un curso de Spring | Todo el laboratorio es Spring | Se mantiene: el taller explica decisiones, no el framework (D10) |
| C3 | No hay laboratorio | Bloque `06-talleres/` opcional | README, `prompt-base.md` y plan de producción lo declaran |
| C4 | El bloque 01 tiene 5 capítulos | 6 capítulos | Renumerar `06`/`07` a `07`/`08` y actualizar enlaces entrantes |

---

## 11. 🚫 Fuera de alcance y decisiones abiertas

### Fuera, y declarado

- Otros lenguajes para el legado (D6).
- Frontend legado: es otro curso (D8).
- Gestión de secretos: se señala el pecado, se arregla en los cursos de nube.
- Kubernetes y despliegue real: las "dos instancias" del taller 08 son dos procesos locales.

### Decisiones abiertas

- **Versión exacta de React, Vite, `sqlite-jdbc`, dialecto de Hibernate para SQLite, Flyway,
  Spring Modulith, ArchUnit y Testcontainers:** se verifican en T0 contra la fuente primaria.
- **`batches/{id}` y `reports/orders-summary`:** en el legado, ¿lote real o consulta sincrónica
  disfrazada? Propuesta: consulta sincrónica lenta, que es lo que suele haber.
- **`POST /api/v2/orders`** de microservicios: no forma parte de `v1`; queda fuera salvo que se
  decida lo contrario.

---

## 12. 🛠️ Siguientes pasos

1. **T0 — Contrato editorial:** guía (sección de talleres, diccionario, nombres), `prompt-base.md`
   (ficha de `01/06` y del bloque 06), plan de producción de talleres, versiones verificadas.
2. **T1 — Capítulo `01/06`**, renumeración del bloque 01 y ampliación de simulación y solucionario.
3. **T2 — Legado y taller 01:** `mono-legacy`, semilla, compose, `lab.py`, `psp-simulator`.
4. **T3 en adelante:** un taller por tanda, corrido, con su estado congelado.
5. **Cierre:** solucionario `11`, README del bloque y del corpus, y reubicación de carpetas
   (`02-monolito`, `03-hexagonal`, `04-microservicios`) cuando se decida.
