# Bases de datos — repaso para entrevistas de Backend Senior, Tech Lead y Arquitecto

> **Objetivo:** que puedas explicar **qué hace el motor por dentro**, distinguir **lo que manda el
> estándar de lo que hace tu motor**, y **defender una decisión de datos en voz alta**.
> **Audiencia:** gente que ya programa y ya escribe SQL. No se explica qué es una tabla ni qué es un
> `SELECT`; se explica por qué tu índice no se usa y qué pasa cuando dos transacciones tocan la
> misma fila. **Baseline:** PostgreSQL 18.6 · MySQL 9.7.2 · MariaDB 12.3.3 · SQLite 3.53.4 · Redis
> 8.10.1 · MongoDB 8.0.20. **Vigencia:** 27 de septiembre de 2026.
>
> ✅ **Completo.** Trece bloques: 69 capítulos, 6 laboratorios, 13 simulaciones de entrevista y
> **1 720 respuestas** en los solucionarios de cada bloque. Todas las sesiones están corridas contra
> el entorno del corpus, con su salida literal. Cómo se edita ahora que
> está cerrado, está en la guía de estilo:
> [`prompts/guia-de-estilo-y-convenciones.md`](prompts/guia-de-estilo-y-convenciones.md).

Esta carpeta es **autocontenida a propósito**: no enlaza a ningún otro material, se explica todo
desde cero, y se puede copiar suelta sin dejar un enlace roto.

---

## Salto rápido

- [Lo que este corpus deja claro](#-lo-que-este-corpus-deja-claro)
- [El ancla: estándar, motor y convención](#-el-ancla-estándar-motor-y-convención)
- [Los trece bloques](#-los-trece-bloques)
- [Cómo se estudia](#-cómo-se-estudia)
- [El entorno](#-el-entorno)
- [La máquina donde se corrió todo](#️-la-máquina-donde-se-corrió-todo)
- [Qué NO está aquí](#-qué-no-está-aquí)
- [Verificación](#-verificación)

---

## 🎯 Lo que este corpus deja claro

Diez cosas que, al terminar, tienes que poder decir sin dudar. Si ya las sabes todas, este material
no es para ti.

1. **Por qué `NULL = NULL` no es verdadero**, y qué se rompe en `WHERE`, en `NOT IN`, en los
   agregados y en `UNIQUE` por culpa de eso.
2. **Por qué tu índice no se usa**, en las seis situaciones concretas en que el motor decide que le
   sale más barato leer la tabla entera.
3. **Qué significa exactamente cada letra de ACID**, y cuál de las cuatro no te da lo que crees.
4. **Que «`REPEATABLE READ` evita las lecturas fantasma» es tres respuestas distintas** según hables
   del estándar, de PostgreSQL o de MySQL — y que recitarlo sin decir cuál es el error más común de
   las entrevistas de datos.
5. **Cómo se lee un plan de ejecución** de arriba abajo, y qué te está diciendo la diferencia entre
   el coste estimado y el tiempo real.
6. **Cómo se provoca un interbloqueo a propósito**, cómo lo detecta el motor, y por qué ordenar los
   accesos lo evita.
7. **Que el N+1 no es culpa del ORM**, y las cuatro formas de arreglarlo.
8. **Qué se pierde exactamente en un corte de corriente**, y qué te cuesta no perder nada.
9. **Cuándo el problema deja de ser relacional** —clave-valor, documental, grafo, serie temporal,
   texto, vectorial— y qué se paga en cada caso.
10. **Por qué nunca se guarda dinero en coma flotante**, y qué tipo usar en cada motor.

---

## 📜 El ancla: estándar, motor y convención

Es el rasgo que distingue a este corpus. **Toda afirmación sobre comportamiento se etiqueta con una
de tres categorías, y no se mezclan:**

| Categoría | Qué significa | Cómo se cita |
|---|---|---|
| **Estándar** | Lo que manda ISO/IEC 9075 (SQL) | Por parte y cláusula, **sin URL** — la norma es de pago |
| **Motor** | Lo que hace de verdad PostgreSQL, MySQL/MariaDB o SQLite | Enlace a la doc oficial, con su número de versión |
| **Convención** | Lo que "todo el mundo sabe" y a veces es falso | Sin cita: se dice que es costumbre y de dónde viene |

El caso que justifica toda la decisión:

```text
«REPEATABLE READ evita las lecturas fantasma»
  Estándar   → falso: el estándar permite fantasmas en REPEATABLE READ
  PostgreSQL → cierto: su REPEATABLE READ es snapshot isolation y no ve filas nuevas,
               aunque no evita el write skew
  MySQL      → cierto en InnoDB, por otro mecanismo: instantánea al leer y next-key locks
               en las lecturas con bloqueo, que no están en el estándar
  Convención → lo que se recita en las entrevistas, sin distinguir cuál de los tres
```

Cada capítulo lleva una sección `📜 Estándar, motor y convención` con esa tabla, y **al menos dos de
sus preguntas distinguen una categoría de otra**.

---

## 📚 Los trece bloques

Cada bloque es una carpeta, cierra con **su propia simulación de entrevista y su propio
solucionario**, y se puede estudiar suelto. Las preguntas son las de los capítulos, sin contar las
de la simulación.

| # | Bloque | Cap. | Preguntas | Qué te deja poder explicar |
|---|---|---|---|---|
| 01 | **[Fundamentos y modelo relacional](01-fundamentos-y-modelo-relacional/README.md)** | 6 | 116 | Claves, álgebra, normalización, integridad, nulos |
| 02 | **[SQL](02-sql/README.md)** | 8 | 148 | Tipos, orden lógico, joins, agregación, CTE, ventanas, `UPSERT`, dialectos |
| 03 | **[El motor por dentro: índices y planes](03-el-motor-por-dentro/README.md)** | 6 | 109 | Páginas, familias de índices, estadísticas, `EXPLAIN`, cuándo no se usa |
| 04 | **[Transacciones y concurrencia](04-transacciones-y-concurrencia/README.md)** | 6 | 114 | ACID, aislamiento, MVCC, bloqueos, interbloqueos, WAL |
| 05 | **[Programación en el motor](05-programacion-en-el-motor/README.md)** | 3 | 54 | Funciones, disparadores, claves generadas |
| 06 | **[Operación: respaldos, migraciones y salud](06-operacion/README.md)** | 5 | 90 | Roles, PITR, migraciones, expandir-contraer, mantenimiento |
| 07 | **[No relacional: clave-valor](07-clave-valor/README.md)** | 6 | 106 | Redis, caché e invalidación, DynamoDB y diseño desde el acceso |
| 08 | **[No relacional: documental](08-documental/README.md)** | 5 | 85 | MongoDB, agregación, incrustar o referenciar, `jsonb` como tercera vía |
| 09 | **[Otros modelos no SQL](09-otros-modelos/README.md)** | 6 | 107 | CAP, wide-column, grafo, series temporales, texto, vectorial |
| 10 | **[Interfaz con los lenguajes](10-interfaz-con-los-lenguajes/README.md)** | 7 | 122 | Driver, pool, inyección, tipos, transacciones — en Java, Python, TS y Go |
| 11 | **[ORMs: qué resuelven y qué rompen](11-orms/README.md)** | 5 | 83 | Los dos patrones, N+1, carga y cachés, cuándo no usar ORM, pruebas reales |
| 12 | **[Diseño, y las decisiones que se preguntan](12-diseno/README.md)** | 6 | 108 | Elegir motor, identidad, fechas y dinero, auditoría, multi-inquilino, paginación |
| 13 | **[Laboratorio](13-laboratorio/README.md)** | 6 labs | 90 | Todo lo anterior, corriendo en Docker, con errores provocados a propósito |

**1 332 preguntas** en capítulos y labs, y 336 `S#` y 52 escenarios más en las simulaciones: las
**1 720 respuestas** de los trece solucionarios.

**Dos ejes de comparación, en dos niveles distintos.** El eje de los bloques 1 a 9 y 12 es **el
motor** —PostgreSQL principal, MySQL/MariaDB de contraste, SQLite embebida—; el eje de los bloques
10 y 11 es **el lenguaje** —Java, Python, TypeScript y Go—. Un lenguaje aparece fuera de esos dos
bloques solo cuando su comportamiento por defecto es una trampa.

---

## 🧭 Cómo se estudia

- **En orden la primera vez, suelto después.** Los bloques 01 a 04 son acumulativos. Después, el
  orden que respeta lo que cada capítulo asume leído es **10, 11, 07, 08, 09, 05, 06 y 12**: los
  clientes de Redis y MongoDB de `10/07` van antes de sus bloques, y `06/01` parte de la inyección
  de `10/02`. Cada lab se hace al llegar al bloque que practica.
- **Un concepto tiene un solo dueño.** El README de cada bloque declara cuáles son los suyos. Los
  demás capítulos usan y enlazan, no redefinen.
- **Las preguntas no traen respuesta a la vista.** Entre 15 y 25 por capítulo, graduadas 🟢
  definición · 🟡 distinción · 🟠 criterio · 🔴 diseño o diagnóstico, y ordenadas de menor a mayor.
  Todas las respuestas viven en el solucionario **de su bloque**, en tres capas: ⏱️ 30 segundos · 🗣️
  2 minutos · 🔬 el detalle.
- **Si solo tienes una semana**, los bloques 01, 03 y 04. Son los que más se preguntan y los que más
  se olvidan. Cada README de bloque dice, en «Si el calendario aprieta», sus dos capítulos más
  rentables.

---

## 🐳 El entorno

Todo corre en Docker, en local, **sin nube y sin coste**. El `compose` vive en
[`13-laboratorio/entorno/`](13-laboratorio/entorno/) y lo levanta el lab `l00`.

```bash
cd 13-laboratorio/entorno
docker compose up -d          # los cinco servicios, con healthcheck
docker compose ps             # todos tienen que estar `healthy` antes de cargar
```

- **`up -d`** arranca los servicios del `compose` en segundo plano; **`ps`** enseña su estado, y la
  columna de salud tiene que decir `healthy` en los cinco antes de cargar datos.
- Los motores del bloque 09 —Cassandra, Neo4j, TimescaleDB con pgvector, OpenSearch y Qdrant—
  viven en `docker-compose.otros.yml` y se levantan solo para ese bloque y el lab `l05`; DynamoDB
  Local y los contenedores de los cuatro lenguajes, con sus perfiles en el `compose` principal.

```text
bd-lab-postgres   PostgreSQL 18.6    5432       bd-lab-redis   Redis 8.10.1    6379
bd-lab-mysql      MySQL 9.7.2        3306       bd-lab-mongo   MongoDB 8.0.20 27017
bd-lab-maria      MariaDB 12.3.3     3307       SQLite 3.53.4  fichero tienda.db, sin servicio
```

El dominio es **una tienda**: seis tablas —`clientes`, `productos`, `pedidos`, `pedido_lineas`,
`pagos`, `eventos_pedido`— y las mismas en todo el corpus, del álgebra relacional al diseño desde el
patrón de acceso en DynamoDB. Un millón de pedidos, 3,5 millones de líneas y 4,1 millones de
eventos, porque **con mil filas `EXPLAIN` no enseña nada**: el planificador elige barrido secuencial
siempre, y con razón.

La carga es **determinista** —`setseed(0.42)`, paralelismo apagado, cupos exactos— y **los cuatro
motores relacionales tienen exactamente las mismas filas con los mismos `id`**: PostgreSQL genera, y
MySQL, MariaDB y SQLite importan de él. Sin eso, el capítulo de dialectos compararía cuatro
conjuntos de datos distintos.

El esquema, los identificadores, los volúmenes y las versiones tienen **un único dueño**:
[`prompts/dominio-entorno-y-datos-fijos.md`](prompts/dominio-entorno-y-datos-fijos.md). Ningún
documento inventa un nombre, un número ni una versión que no esté ahí. **MongoDB va en 8.0.20 y no
en la última de su rama**: de la 8.0.21 en adelante no arranca en el núcleo de Docker Desktop del
entorno, y ese documento explica por qué en §4.1.

---

## 🖥️ La máquina donde se corrió todo

Los tiempos pegados en el corpus vienen todos de aquí, o dejarían de ser comparables entre
capítulos:

```text
Apple M1 Pro · 8 núcleos · 32 GB · macOS 26.7
Docker Desktop 4.92.0 — motor 29.8.0, núcleo 7.0.12; la VM ve 8 CPU y 7,75 GB
PostgreSQL con shared_buffers=256MB, work_mem=8MB, random_page_cost=1.1,
           max_parallel_workers_per_gather=0 y jit=off
```

Docker Desktop se actualizó el 26 de septiembre de 2026, desde la 4.83.0; lo escrito antes se
corrió con aquella versión, y lo que dependía del núcleo —MongoDB— se volvió a correr ese mismo día.

> **⚠️ Qué es reproducible y qué no.** Las filas que devuelve cada consulta, las filas reales de un
> plan y su **forma** —qué nodos, en qué orden, qué índice— son reproducibles en cualquier máquina:
> la semilla es determinista y los parámetros del motor están fijados. **Las estimaciones y los
> costes de `EXPLAIN` cambian con cada muestra de `ANALYZE`**, y **los milisegundos no son
> reproducibles**, porque dependen del disco, de la memoria y de la caché. Un tiempo o una
> estimación que no reproduces no es un error del corpus.

---

## 🚫 Qué NO está aquí

Se declara para que no lo busques, y porque un temario que no dice dónde para no es un temario.

- **Administración avanzada.** Réplicas, *failover*, *sharding*, tuning de parámetros del servidor y
  alta disponibilidad. Se nombra lo justo para explicar consistencia y respaldos.
- **Analítica y almacén de datos.** Modelo estrella, ETL/ELT, y los motores columnares analíticos.
  Es otro oficio.
- **Bases gestionadas en la nube.** Aparecen como nombres cuando se habla de respaldos, nada más;
  DynamoDB se practica con su versión local.
- **Teoría de sistemas distribuidos.** Consenso, relojes vectoriales. CAP se explica en `09/01` lo
  justo para elegir motor.
- **Seguridad de aplicación.** Cifrado en reposo y gestión de secretos. Sí entran la inyección SQL
  (`10/02`), el mínimo privilegio (`06/01`) y el aislamiento entre inquilinos (`12/05`), porque son
  del oficio.

---

## ✅ Verificación

Los controles que se corren antes de dar cualquier edición por cerrada.

```bash
# 1. Los datos son los declarados: 22 comprobaciones, todas en OK
cd 13-laboratorio/entorno
PGPASSWORD=postgres psql -h 127.0.0.1 -U postgres -d tienda -f verificar.sql

# 2. Los siete controles del corpus, desde la raíz de la carpeta
bash prompts/verificar-corpus.sh
```

- **`verificar.sql`** compara 22 recuentos y valores fijos de la tienda con los del documento de
  dominio; MySQL, MariaDB y SQLite tienen el suyo en la misma carpeta.
- **`verificar-corpus.sh`** comprueba enlaces internos, que ningún documento salga de la carpeta,
  la sincronía de preguntas y simulaciones con su solucionario, las anclas, el ancho de la prosa y
  que cada enunciado del solucionario sea copia literal del de su capítulo. Sale con código 1 si
  algo falla, así que se puede encadenar.

Los controles excluyen `prompts/` a propósito: la guía de estilo nombra a su guía madre (es la regla
de autocontenido aplicada a sí misma).

---

**Empieza por:**
[`01-fundamentos-y-modelo-relacional/`](01-fundamentos-y-modelo-relacional/README.md)
