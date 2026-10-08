# ✍️ Guía de estilo, tono y convenciones

## Bases de datos — repaso para entrevistas de Backend Senior, Tech Lead y Arquitecto

Esta guía es la fuente de verdad editorial de `repaso-bases-de-datos-entrevistas/` y manda sobre sus
trece bloques, sus capítulos, sus labs, sus simulaciones y sus solucionarios. Cualquier chat que
produzca o edite un `.md` de este corpus la sigue entera. Su objetivo es que todos los documentos se
lean como escritos por la misma mano y apunten al mismo lugar: **que puedas explicar qué hace el
motor por dentro, distinguir lo que manda el estándar de lo que hace tu motor, y defender una
decisión de datos en voz alta**.

Desciende de la guía de `repaso-apis-y-protocolos-entrevistas` —de la que hereda el tono, la
pedagogía del andamio, el patrón fijo de concepto, las tres capas de respuesta, los callouts y las
reglas de enlace— y **diverge en cinco puntos declarados**: §1.1, §4.2, §4.4, §5 y §8. La razón de
fondo de las divergencias es doble: **este corpus es autocontenido y se publica suelto**, y su
fuente de autoridad no es una norma pública y gratuita sino **un estándar de pago más tres motores
que no lo cumplen igual**.

Un cambio **de forma y no de fondo** se añadió en la revisión del 2026-10-05, a pedido explícito del
autor: **todo diagrama de nodos y flechas, o de mensajes entre partes, se escribe en Mermaid** (§9.5);
la sesión real y su salida siguen en `text` o `sql`. La madre hizo el mismo cambio ese día, así que no
cuenta como divergencia.

> **Nota sobre la ascendencia.** Esa guía madre se **nombra, no se enlaza**. Esta carpeta tiene que
> poder copiarse fuera del repositorio sin dejar un solo enlace roto. Es la regla de §1.1 aplicada a
> la propia guía.

Si dudas entre dos formas de escribir algo, gana la que le sirva más a alguien que mañana tiene una
entrevista donde le van a preguntar por qué su índice no se usa, o qué pasa si dos transacciones
tocan la misma fila.

> **Vigencia:** 2026-10-05.

---

## 1. 🧭 Principio rector

**Todo lo que se escribe apunta a que alguien entienda el mecanismo, sepa de dónde viene el
comportamiento, y pueda defender una decisión de datos en voz alta.**

No enseñamos "bases de datos" como las enseña la universidad. El temario clásico dedica un semestre
al álgebra relacional y llega al final del curso sin haber leído nunca un plan de ejecución. Aquí el
orden es el contrario: **el modelo importa porque explica el motor, y el motor importa porque
explica la consulta que tarda ocho segundos en producción**.

```text
Un curso clásico  → te enseña las formas normales y la teoría de dependencias funcionales.
Este repaso       → te enseña por qué tu índice compuesto no se usa, dónde lo puedes ver,
                    y qué le dices al entrevistador cuando te pregunta por qué.
```

El filtro para cada párrafo es este: **¿esto ayuda a explicar, a decidir un esquema o a diagnosticar
una consulta lenta?** Si no, sobra. Aunque sea cierto y esté en el manual.

Y el corolario, que es la marca de este corpus:

> Cada afirmación sobre comportamiento se etiqueta como **estándar**, como **motor** o como
> **convención**. Nunca se mezclan. Cada mecanismo se nombra con lo que cuesta. Cada decisión
> responde a "¿por qué funciona así, y qué se rompe si lo ignoro?".

Una afirmación sobre bases de datos sin su categoría no está explicada: está recordada. Y la mitad
de lo que "todo el mundo sabe" sobre SQL es cierto en un motor, falso en otro, y nunca estuvo en el
estándar.

### 1.1 Autocontenido: la divergencia que define la carpeta

**Divergencia declarada, y la más fácil de incumplir por inercia.**

**Este corpus no enlaza a ningún otro documento del repositorio.** Ni a
`repaso-arquitectura-entrevistas`, ni a `repaso-bases-entrevistas`, ni a
`repaso-spring-entrevistas`, ni a `repaso-microservicios`, ni a `repaso-aws-entrevistas`, ni a
`preguntas-entrevista`. Ni con enlace, ni con una mención de cortesía del tipo *"esto ya está
explicado en…"*.

Lo que allí ya esté escrito —ACID, CAP, caché, coma flotante, N+1, saga, outbox, idempotencia— **se
vuelve a explicar aquí, desde cero y con sus propias palabras**. El solapamiento es deliberado y no
hay que evitarlo: es la condición para que la carpeta pueda copiarse fuera y siga completa.

Consecuencias prácticas, todas verificables:

- **El pie de navegación y la sección "Relacionado" solo apuntan dentro de esta carpeta.**
- **El "Qué NO está aquí" del README nombra temas, no corpus vecinos.** Se dice *"la analítica y el
  almacén de datos son otro oficio y no entran"*, no *"eso está en tal carpeta"*.
- **Un concepto prestado se reescribe, no se resume.** Si el capítulo `04/01` necesita ACID, lo
  explica entero. Que exista una explicación mejor en otra carpeta es irrelevante aquí.
- La comprobación es mecánica y está en §12.

### 1.2 Qué NO es este corpus

Cinco cosas quedan fuera por decisión editorial, y se declaran para que ningún documento las
prometa:

- **No es administración avanzada.** Réplicas, *failover*, *sharding*, afinado de parámetros del
  servidor y alta disponibilidad. Se nombran lo justo para explicar consistencia y respaldos.
- **No es analítica ni almacén de datos.** Modelo estrella, ETL/ELT, y los motores columnares
  analíticos —ClickHouse, DuckDB, BigQuery, Snowflake, Redshift—. El bloque 09 habla de wide-column
  **operacional**, que es otra cosa y se dice.
- **No es nube gestionada.** RDS, Aurora, Cloud SQL, Atlas. Aparecen como nombres cuando se habla de
  respaldos o de compatibilidad de API, y nada más.
- **No es teoría de sistemas distribuidos.** Consenso, Raft, relojes vectoriales. CAP se explica en
  `09/01` lo justo para elegir motor.
- **No es seguridad de aplicación.** Cifrado en reposo, gestión de secretos, cumplimiento. Sí entran
  la inyección SQL (`10/02`) y el mínimo privilegio (`06/01`), porque son del oficio de quien
  escribe consultas.

---

## 2. 🎤 Tono

El tono es **semi formal, cálido y directo**, de colega a colega. Piensa en alguien que ya pasó por
esto —la consulta que iba bien con mil filas y murió con un millón, el `VACUUM` que no corría porque
había una transacción abierta desde el martes, el `float` que perdió tres céntimos al mes durante
dos años— y te lo explica con paciencia y sin solemnidad de manual.

Cómo se ve en la práctica:

- **Tuteo latinoamericano, siempre.** Nada de voseo, nada de "usted", nada de impersonal permanente.
- **Semi formal.** Cercano, pero no chat. Frases completas, puntuación correcta.
- **Humor mínimo y seco.** Como mucho **un desdramatizador por documento**, y si no fluye solo, se
  borra.
- **Honesto sobre la categoría.** Cuando algo se hace "porque siempre se ha hecho así" y el estándar
  dice otra cosa —`SELECT *`, el `VARCHAR(255)`, "REPEATABLE READ evita fantasmas"— **se dice que es
  convención y se dice qué hace cada motor**. Es el recurso pedagógico central del corpus.
- **Honesto sobre lo obsoleto.** Media internet sigue explicando MySQL con MyISAM, `mysql_query()` y
  consejos de afinado de 2009. Cuando una fuente que el lector va a encontrar esté anticuada, se
  nombra y se da la vigente.
- **Honesto sobre el precio.** Todo mecanismo se nombra con lo que cuesta, en las cinco monedas de
  §4.2. Nada de "es más lento": se dice en qué y cuánto.
- **Sin absolutos falsos.** Nada de "siempre" ni "nunca" salvo cuando se puede sostener —"nunca coma
  flotante para dinero" se sostiene, y se explica por qué—.
- **Cálido sin condescendencia.** Explicamos desde cero, pero nunca infantilizamos.
- **Sin relleno motivacional.** Quien lee ya sabe por qué está repasando.

---

## 3. 🗣️ Idioma y forma de la narrativa

- **Español latinoamericano neutro**, técnico y claro, para toda la narrativa.
- **Las palabras clave de SQL van en mayúsculas**: `SELECT`, `LEFT JOIN`, `GROUP BY`, `ON CONFLICT`.
  Es la convención universal y ayuda a separar el lenguaje del identificador de un vistazo.
- **Los términos del oficio se quedan en inglés**: *index-only scan*, *write skew*, *deadlock*,
  *bloat*, *snapshot*, *sharding*, *upsert*, *cache-aside*, *eventually consistent*. Traducirlos a
  la fuerza confunde y no es lo que el lector va a leer en la documentación ni oír en la entrevista.
  **La primera vez que aparece uno se da su traducción entre paréntesis**; después ya no. Dos
  excepciones fijas, porque el término en español está asentado: *bloqueo* (por *lock*) e
  *interbloqueo* (por *deadlock*), que se usan con el inglés entre paréntesis la primera vez.
- **El esquema de ejemplo se escribe en español.** **Divergencia declarada respecto de
  `CLAUDE.md`**, que pide todo lo ejecutable en inglés. Aquí no aplica: el esquema no es
  infraestructura versionada, es **el vocabulario de la narrativa**, y `SELECT * FROM pedidos WHERE
  cliente_id = 4210` se lee en el mismo idioma que el párrafo que lo explica. Cambiar de idioma
  dentro de la misma frase obliga al lector a traducir dos veces. Lo que sí queda en inglés: nombres
  de contenedor, variables de entorno y cualquier identificador del `docker compose` (§5.1).
- **Los comentarios dentro del código van en español**, como en todo el repositorio.
- **Markdown siempre.** Nada de HTML embebido.
- **La prosa se envuelve a 100 columnas.** No es cosmética: el techo de 200-350 líneas de §4.6 solo
  significa lo mismo en todos los capítulos si todos van al mismo ancho. A 116 columnas, un capítulo
  "de 350 líneas" lleva un 16 % más de texto que su vecino, y la banda deja de medir nada. Quedan
  fuera del ajuste, porque no se pueden partir: los bloques de código, las filas de tabla, los
  encabezados y las URL largas. Se comprueba y se corrige con `python3 prompts/reflow.py <fichero>`
  —con `--check` solo informa—.
- **Estructura visual primero, pero la prosa no es el último recurso.** El orden de preferencia es
  sesión real → diagrama (§9.5) → tabla → lista → párrafo *para exponer una relación entre cosas*. El **porqué** de
  una decisión se escribe en prosa.
- **Nada de prosa telegrama.** Una frase corta y sola es un buen golpe de ritmo; tres seguidas son
  un telegrama. Regla práctica: **una frase aislada por sección, dos si la sección es larga**.
- **El recurso visual principal de este corpus es la sesión real** (§9.1). Es el equivalente aquí
  del intercambio HTTP del corpus de protocolos.
- **Tablas solo para comparar o mapear**, con tres o cuatro columnas como norma. **Si necesitas
  explicar una celda, ya no es una tabla.**
- **Encabezados con emoji, con moderación.** Uno por sección `##` numerada, **ninguno en las
  subsecciones `###`**. El emoji es funcional: 🎯 el problema, 🧱 mecanismo, 📜 estándar y motor, ⚖️
  comparación, 🧭 criterio de elección, 🩺 diagnóstico, 🔭 dónde aparece de verdad, 🪦 lo obsoleto, ⚠️
  errores frecuentes, 🧪 ejercicios (solo labs), 🧠 preguntas, 📚 referencias.

---

## 4. 🎓 Pedagogía: "como para un bebé"

> **"Como para un bebé" significa cero ambigüedad, no menos profundidad.**

No es escribir más simple: es no dejar ningún hueco donde el lector tenga que adivinar. Se explica
qué es exactamente una página de 8 kB, por qué existe, qué pasa cuando una fila no cabe y quién
decide moverla fuera de línea. No se dice "PostgreSQL guarda los valores grandes aparte" y se sigue
adelante.

### 4.1 La regla del andamio

Todo concepto nuevo se presenta en tres tiempos, en este orden:

1. **El problema primero.** Antes de nombrar el mecanismo, muestra el dolor que resuelve. *"Dos
   cajeros cobran el mismo pedido en el mismo segundo. Los dos leen saldo 100, los dos restan 30,
   los dos escriben 70. Se cobró 60 y el saldo dice que se cobró 30. ¿Quién impide esto?"*
2. **El mecanismo después.** Ahora sí, el nombre y la definición mínima.
3. **La sesión que lo demuestra.** La consulta y su salida reales, con la viñeta que dice qué mirar.

Por eso **`## 1. 🎯 El problema` es la sección de apertura obligatoria de todo capítulo**.

### 4.2 Ninguna afirmación sin categoría, y ningún mecanismo sin coste

**Divergencia declarada.** En el corpus de protocolos la fuente era el RFC, pública y citable con
precisión. Aquí la fuente se parte en tres, porque **el estándar SQL es de pago y ningún motor lo
cumple entero**:

| Categoría | Qué es | Cómo se cita |
|---|---|---|
| **Estándar** | Lo que manda ISO/IEC 9075 | Por parte y cláusula (*"9075-2, `<join specification>`"*), **sin URL** |
| **Motor** | Lo que hace de verdad PostgreSQL, MySQL/MariaDB o SQLite | Enlace a la doc oficial del motor, verificado por código de estado |
| **Convención** | Lo que se recita en el gremio, cierto a medias | Sin cita: se dice que es costumbre y de dónde viene |

Reglas duras de la categoría:

- **Nunca se escribe "el estándar dice" cuando lo que se sabe es lo que hace PostgreSQL.** Es el
  error más caro de este corpus, porque parece autoridad y es falsable en dos minutos.
- **Si no se pudo verificar la cláusula del estándar, se dice.** *"Los tres motores lo hacen así; no
  he verificado la cláusula del estándar"* es honesto, útil y perfectamente publicable. Inventarse
  una cláusula, no.
- **Cuando los motores difieren, difieren en una tabla**, no en un párrafo con "en algunos motores".
- **"En algunos motores" está prohibido.** O se dice cuáles, o no se dice.

**Y la otra mitad: el precio.** Aquí las monedas no son las del protocolo. Son cinco:

```text
tiempo · E/S y páginas leídas · espacio en disco · concurrencia y bloqueo · riesgo de pérdida
```

*"Un índice en `pedidos(cliente_id)` convierte un `Seq Scan` de un millón de filas en un `Index
Scan` de 38, y lo pagas con ~40 MB de disco, una escritura extra en cada `INSERT` y un `UPDATE` que
ya no puede ser HOT si toca esa columna"* está completo. *"Un índice acelera las consultas"* no lo
está.

### 4.3 Explica el porqué, no solo el cómo

Cada comportamiento lleva su porqué, aunque sea media línea: por qué un B-tree lee tres páginas y no
mil, por qué el planificador prefiere `Seq Scan` cuando estima el 30 % de la tabla, por qué `SELECT
count(*)` es caro en PostgreSQL y barato en MyISAM, por qué un UUIDv4 como clave primaria fragmenta
el índice y un UUIDv7 no.

Cuando el porqué es **histórico** —que en bases de datos pasa mucho— se dice también:
*"`VARCHAR(255)` es el número mágico que todo el mundo copia porque en MySQL antiguo era el máximo
indexable con una cabecera de un byte; en PostgreSQL no significa nada y `text` es igual de
rápido"*.

### 4.4 Ancla en la sesión del motor, no en el ORM

**Divergencia declarada.** Donde el corpus de protocolos anclaba en `curl -v`, aquí el anclaje es
**la sesión interactiva**: `psql`, `mysql`, `sqlite3`, `redis-cli`, `mongosh`, `cqlsh`,
`cypher-shell`.

- Un comportamiento se enseña con la consulta y su salida, no con la anotación que lo genera.
- Un plan se enseña con `EXPLAIN ANALYZE` pegado entero, no descrito.
- Un bloqueo se enseña **con dos sesiones abiertas**, marcadas `-- sesión A` y `-- sesión B`.

**Todas las salidas van corridas de verdad**, contra el entorno de
`dominio-entorno-y-datos-fijos.md`. **Un plan inventado es el error más caro después de una cláusula
del estándar inventada**: los números de coste, las filas estimadas y los tiempos no se aproximan de
memoria. Si no se ha corrido, no se pega.

Un concepto que no se ve en la sesión —lo que el WAL escribe en disco, cómo se parte una página— se
explica igual, **pero se declara que no se observa** y se dice con qué sí se vería (`pg_waldump`,
`pageinspect`, `pg_stat_*`, `SHOW ENGINE INNODB STATUS`).

**Lo que no se hace nunca:** explicar un concepto del motor a través del ORM. El ORM tiene sus dos
bloques (10 y 11) y ahí se habla de él.

### 4.5 Analogías con fecha de caducidad

Las analogías se usan **una vez, para abrir la puerta**, y después se abandonan diciendo dónde se
rompen. Cuidado especial con las cuatro más peligrosas del temario:

- **Una tabla no es una hoja de cálculo** (no hay orden de filas, no hay celda vacía sino `NULL`, y
  el contenido está restringido por dominio);
- **Un índice no es el índice de un libro** (la analogía sirve para el B-tree y se rompe en cuanto
  aparecen la selectividad, el orden de las columnas y el *index-only scan*);
- **Una transacción no es "todo o nada"** (eso es solo la A de ACID; la I es la que cuesta, la que
  se configura y la que se pregunta);
- **"NoSQL" no significa "sin esquema"** (significa que el esquema no lo valida el motor, así que lo
  valida tu código o no lo valida nadie).

### 4.6 Densidad calibrada, con techo de longitud

- **Longitud: banda objetivo y techo duro.**

  | | Banda objetivo | Techo duro |
  |---|---|---|
  | Capítulo normal | 200-350 líneas | **550** |
  | **Capítulo denso**, declarado en la lista de abajo | 200-450 líneas | **550** |

  **El techo de 550 no se pasa.** Un capítulo que lo alcance se parte en dos y se declara en el
  README del bloque; no hay excepción, porque por encima de ahí deja de leerse de una sentada.
  Dentro del techo, la banda objetivo es **una guía de densidad, no un límite**: quedarse en ella es
  la señal de que el capítulo enseña una cosa y no tres.

  **Un capítulo es denso cuando su evidencia mínima no cabe en 350 líneas**, no cuando el tema
  parece difícil. La prueba es mecánica: si las sesiones y los planes que necesita —con las dos
  secciones *recomendadas* ya suprimidas— pasan de ~180 líneas de bloque de código, es denso. La
  lista vive aquí y **se amplía declarándolo, nunca en silencio**:

  ```text
  02/01 tipos · 02/02 SELECT · 02/03 joins · 02/04 agregación · 02/05 CTE · 02/06 ventanas
  03/05 EXPLAIN · 03/06 cuándo no se usa · 04/02 aislamiento · 04/03 MVCC · 04/04 bloqueos
  05/03 claves generadas · 07/02 estructuras de Redis · 07/06 diseño por acceso · 09/03 grafo
  09/04 series temporales · 09/06 vectorial · 10/05 Java · 10/06 Python+TS+Go · 11/02 N+1
  l00 entorno y datos · l01 EXPLAIN e índices
  ```

  El bloque 02 entero está dentro porque cada capítulo contrasta el mismo comportamiento en cuatro
  motores. `03/06` entró por otro motivo: seis mecanismos, cada uno con su cifra medida, su señal en
  el plan y su precio. `07/02`, `09/03`, `09/04`, `09/06` y `05/03`, por pasar de ~180 líneas de
  sesión.

  La razón de que la banda no sea un límite: **§9.1 prohíbe recortar una sesión o un plan**, y un
  capítulo que demuestra seis comportamientos en cuatro motores tiene un suelo de evidencia
  irreducible. Cuando la banda choca con §9.1, **gana §9.1**: la banda mide densidad de prosa, no de
  evidencia. Lo que nunca se hace es recortar un plan para que quepa el capítulo.

- **Orden de poda, cuando hay que podar.** Primero las secciones que esta guía marca como
  *recomendadas* (`🧭 Cómo se elige`, `🔭 Dónde aparece de verdad`); después la prosa; después el
  contenido que **pertenece a otro capítulo** —ahí no se poda, se mueve a su dueño y se enlaza—; y
  solo al final, si nada de lo anterior alcanza, se parte el capítulo en dos y se declara en el
  README del bloque. **Las sesiones no entran en el orden de poda.**
- **Todo capítulo que pase de 400 líneas abre con índice de salto rápido** (§6.2) y **declara su
  longitud y su densidad en el callout `📝` de su propio §1**. El README del bloque la resume, pero
  la fuente es el capítulo (§7.5).
- Un concepto nuevo por vez.
- Repetir lo importante está bien: el coste de un índice, la diferencia entre estándar y motor, y
  "diseña desde el patrón de acceso" reaparecen con otras palabras.
- Ninguna sección supera las dos pantallas sin una sesión, una tabla o un veredicto.
- **Todo documento de más de ~400 líneas abre con un índice de salto rápido** (§6.2).

### 4.7 Cierra los bucles

Si abres un paréntesis —*"esto se ve en `03/05`"*— tiene que cerrarse con enlace real **dentro de
esta carpeta**, y nunca a un archivo que no está escrito. Un documento nuevo se crea antes que los
enlaces que lo citan; si un enlace tiene que existir antes, apunta al README de su bloque.

---

## 5. 💻 Los dos ejes de comparación

> **Regla normativa: este corpus tiene dos ejes, y viven en niveles distintos. No se mezclan.**

**Divergencia declarada.** El borrador del temario proponía cuatro lenguajes como eje único, al
estilo de `repaso-bases-entrevistas`. Aquí no funciona: `GROUP BY` significa lo mismo en los cuatro
lenguajes, y las diferencias interesantes están **entre motores**.

| Eje | Dónde manda | Quiénes |
|---|---|---|
| **Motor** | Bloques 1 a 9 y 12 | PostgreSQL (principal) · MySQL/MariaDB (contraste de dialecto y concurrencia) · SQLite (embebida) |
| **Lenguaje** | Bloques 10 y 11, concentrado | Java · Python · TypeScript · Go |

Reglas del eje de motor:

- **PostgreSQL es el motor de referencia.** Cuando un capítulo enseña un mecanismo sin decir el
  motor, es PostgreSQL. Se dice una vez en el README y no se repite en cada párrafo.
- **MySQL/MariaDB entra cuando difiere de forma interesante**, que es a menudo: índice agrupado,
  `REPEATABLE READ` por defecto, gap locks, tipos, `utf8mb4`, DDL no transaccional.
- **SQLite entra cuando el caso es embebido** o cuando su simplicidad ilumina el mecanismo: un solo
  escritor, tipado dinámico, WAL en un fichero.
- **Los tres no tienen que aparecer en cada capítulo.** Aparecen donde hay diferencia; forzarlos
  produce tablas con la palabra "igual" repetida tres veces.

Reglas del eje de lenguaje:

- **Fuera de los bloques 10 y 11, un lenguaje aparece solo cuando su comportamiento por defecto es
  una trampa**: el driver que devuelve `TIMESTAMP` en la zona del cliente, el que carga el resultado
  entero en memoria, el ORM que abre una transacción que nadie pidió. Entonces se nombra y se
  explica.
- **Derby y H2 entran solo en el eje Java** (`10/05` y `11/05`): Java puro y embebido, por qué
  aparecen en proyectos heredados, y por qué probar contra H2 miente. **No aparecen en las tablas de
  contraste de dialecto** de los demás bloques.
- **En los bloques 10 y 11, los cuatro lenguajes resuelven el mismo ejemplo**, para que la
  comparación sea real y no una colección de fragmentos sueltos.

### 5.1 Dominio, entorno y datos: dueño único

**No se inventan nombres nuevos por capítulo.** El esquema, los identificadores, los volúmenes, los
nombres de contenedor, los puertos y las versiones exactas de cada imagen están fijados en
[`dominio-entorno-y-datos-fijos.md`](dominio-entorno-y-datos-fijos.md), **que es su dueño único**.

Lo mínimo que hay que saber sin abrirlo:

```text
Base      tienda
Tablas    clientes · productos · pedidos · pedido_lineas · pagos · eventos_pedido
IDs       CLI-00311 · PRD-00017 · PED-00042
Volumen   1 000 000 de pedidos · 3 500 000 de líneas
```

**Nunca uses `foo`, `bar`, `tabla1`, `test` ni `mi_tabla`.** Un ejemplo sin significado destruye la
capacidad de reconocer el patrón en un caso real.

**Ninguna versión se escribe de memoria.** Ni la de un motor, ni la de una imagen, ni la de una
librería. Se verifica contra la fuente oficial en la misma edición en que se escribe, igual que una
URL. Y **nunca `latest`** en un `docker compose` del corpus: una imagen móvil invalida los planes
pegados.

---

## 6. 🧱 Plantilla de los capítulos (`NN-tema.md`)

1. **Título** — `# NN — Tema` (dos dígitos, sin emoji en el título).
2. **Blockquote de encabezado** — qué cubre, qué asume leído **con enlace interno**, y
   **`Vigencia:`**.
3. **Índice de salto rápido** — solo si pasa de ~400 líneas (§6.2).
4. **`## 1. 🎯 El problema`** — apertura obligatoria (§4.1).
5. **Secciones `##` numeradas**, una por concepto, con emoji funcional y numeración arábiga
   continua.
6. **`## N. 📜 Estándar, motor y convención`** — **obligatoria en todo capítulo**. Reúne las
   afirmaciones del capítulo en una tabla de cuatro columnas —afirmación · estándar · PostgreSQL ·
   MySQL—, con SQLite como quinta cuando difiera, y una fila final de **convención** cuando la haya.
   Es la sección que distingue a este corpus y la que hay que escribir con más cuidado.
7. **`## N. 🧭 Cómo se elige`** — recomendada cuando el capítulo presenta alternativas.
8. **`## N. 🔭 Dónde aparece de verdad`** — recomendada. Dónde se topa un backend con esto: el
   informe que tarda ocho segundos, el despliegue que bloqueó la tabla, los tres céntimos perdidos.
9. **`## ⚠️ Errores frecuentes`** — obligatoria. Tabla de dos columnas, **"Se dice" contra "Lo
   preciso"**, con entre cinco y ocho entradas.
10. **`## 📚 Para profundizar`** — cierre obligatorio (§10), máximo ocho entradas.
11. **`## 🧠 Preguntas`** — cierre obligatorio, sin respuestas visibles (§8).
12. **Pie de navegación** — una línea con **Anterior**, **Siguiente** y **Relacionado**, todo dentro
    de esta carpeta.

### 6.1 El patrón fijo de cada concepto

```text
Qué es      → la definición mínima, en una o dos frases
Cómo va     → la sesión real, con su salida
Quién lo manda → estándar, motor o convención. NUNCA se omite.
Cuánto      → tiempo, E/S, espacio, concurrencia o riesgo de pérdida. NUNCA se omite.
Cuándo sí   → los casos donde se paga solo
Cuándo no   → los casos donde sobra o hace daño. NUNCA se omite.
Veredicto   → la frase que resume el criterio, en blockquote
```

Las secciones que no presentan un concepto elegible —el problema, la tabla de estándar y motor, los
errores frecuentes— no llevan veredicto.

### 6.2 Índice de salto rápido

Formato fijo, justo después del blockquote. **Cómo se calcula un ancla de GitHub**: se pasa el
encabezado a minúsculas, se eliminan los caracteres que no son letra, número, espacio, guion o guion
bajo, y los espacios restantes se convierten en guiones; cada carácter borrado deja su espacio, de
ahí los guiones dobles.

| Encabezado | Ancla |
|---|---|
| `## 3. 📜 Estándar, motor y convención` | `#3--estándar-motor-y-convención` |
| `## 🧠 Preguntas` | `#-preguntas` |

### 6.3 Excepciones declaradas a la plantilla

- **`README.md` de la raíz** — para quién es, los trece bloques, "las diez cosas que este corpus
  deja claras", cómo se estudia, verificación.
- **`README.md` de cada bloque** — orden de lectura, tabla de capítulos con su número de preguntas,
  y qué asume leído del bloque anterior.
- **Labs `lNN-*.md`** — §7.2.
- **Simulaciones** — §7.3.
- **Solucionarios** — §7.4.

---

## 7. 📐 Los cinco tipos de documento

### 7.1 Capítulos `NN-tema.md`

El grueso del corpus. Siguen la plantilla de §6 sin desviaciones. Son independientes en lectura pero
acumulativos en vocabulario dentro de su bloque.

**Un concepto tiene un solo dueño**, y se declara en el README del bloque. Los dueños fijos:

| Concepto | Dueño |
|---|---|
| Nulos y lógica de tres valores | `01/06` |
| Dialecto: qué es portable | `02/08` |
| Lectura de `EXPLAIN` | `03/05` |
| Niveles de aislamiento y sus fenómenos | `04/02` |
| Migraciones de esquema, incluidas las generadas por ORM | `06/03` |
| Modelado desde el patrón de acceso | `07/06` (lo reutiliza `09/02`) |
| CAP, lo justo para elegir motor | `09/01` |
| Pool de conexiones | `10/01` |
| Inyección SQL | `10/02` |

Los demás usan y enlazan; no redefinen.

### 7.2 Labs `lNN-tema.md` (bloque 13)

- **Todo se corre en Docker**, con el `compose` del corpus. Sin nube y sin coste: si algo costara
  dinero, no entra.
- **El teardown se escribe junto al recurso**, no al final de la serie.
- **Los errores se reproducen a propósito antes de corregirlos.** Un lab que solo enseña el camino
  feliz no enseña a diagnosticar.
- **Ningún comando ni bandera queda sin explicar**, con desglose en viñetas después de cada bloque
  de código. Un bloque `bash` suelto es un error de estilo.
- Llevan **`## 🧪 Ejercicios`** graduados 🟢🟡🟠🔴, además de sus preguntas. Los 🔥 y 💀 van fuera del
  conteo.

### 7.3 Simulaciones `NN-simulacion-de-entrevista.md`

Una por bloque, como penúltimo documento.

- **Una sección de método**: cronómetro a dos minutos, en voz alta.
- **Preguntas `S#` transversales al bloque**, entre 20 y 30, agrupadas por tema, con un bloque final
  de **"las que descolocan"**.
- **Escenarios**, entre tres y cinco: un esquema que diseñar, una consulta lenta que diagnosticar,
  una decisión que defender. **Uno de ellos, obligatoriamente, es un caso donde la respuesta
  correcta es "no lo resuelve la base de datos"** y hay que subir de capa.
- **Las frases que hay que tener listas** como cierre.

### 7.4 Solucionarios `NN-respuestas.md`

**Uno por bloque**, no uno para todo el corpus: con 69 capítulos, un solucionario único sería
inmanejable. Abre con índice de salto rápido, se organiza por capítulo, **el enunciado se copia
literalmente**, el formato de cada entrada es `**NN → P.** Enunciado en negrita`, y la **respuesta
va en tres capas, siempre las tres** (§8.3).

### 7.5 Los README

- **El de la raíz** presenta el corpus, declara las fases y la frontera de §1.2.
- **El de cada bloque** da el orden de lectura, la tabla de capítulos con su número de preguntas,
  los dueños de concepto del bloque y qué asume leído.
- **Se escribieron todos al cerrar la producción**, desde lo que hay en disco: el número de
  preguntas que cuenta `prompts/verificar-corpus.sh`, las longitudes que cada capítulo declara en su
  `📝` y los dueños de concepto. **Desde entonces se mantienen en la misma edición**: la que cambie
  el número de preguntas, un título, el orden de lectura o un dueño de concepto actualiza el README
  de su bloque, y el de la raíz si cambian los totales.

---

## 8. 🧠 Preguntas y respuestas

**Divergencia declarada respecto del corpus de protocolos, que pide 20-30 por capítulo.**

```text
capítulo      →  15 a 25 preguntas numeradas. Sin respuesta visible.
lab           →  15 a 25 preguntas + 6 a 10 ejercicios 🧪 graduados.
simulación    →  20 a 30 preguntas S# + 3 a 5 escenarios.
solucionario  →  todas las respuestas del bloque, en tres capas, enunciado literal.
```

### 8.1 Las preguntas de capítulo

- **Cantidad: 15 a 25**, calibrada por cuántas cosas distintas enseña el capítulo.
- **Numeración arábiga continua dentro del capítulo**, reiniciada en cada capítulo.
- **Dificultad marcada al final del enunciado** con un solo emoji:

  | | Nivel | Qué pide |
  |---|---|---|
  | 🟢 | Definición | Reproducir algo que el capítulo enunció |
  | 🟡 | Distinción | Diferenciar dos cosas que se confunden |
  | 🟠 | Criterio | Decidir y justificar, o explicar un porqué no obvio |
  | 🔴 | Diseño o diagnóstico | Un esquema que definir, una consulta que arreglar, un fallo que explicar |

- **Reparto orientativo:** 25 % 🟢, 25 % 🟡, 30 % 🟠 y 20 % 🔴, con un escalón de margen. **Que dos
  capítulos vecinos tengan idéntico reparto es señal de que el segundo se copió.**
- **Orden: de menor a mayor dificultad.** Las 🔴 van al final, siempre.
- **Al menos dos preguntas por capítulo distinguen estándar de motor**, que es la aportación propia
  de este corpus: *"¿el nivel de aislamiento por defecto lo fija el estándar, o cada motor?"*.
- **Las 🔴 piden un artefacto o una secuencia**, no una opinión: *"escribe el DDL"*, *"da tres
  hipótesis en orden de probabilidad"*, *"dibuja el orden de los bloqueos que produce el
  interbloqueo"*.
- **Sin respuesta en el documento.** Va todo al solucionario del bloque.

### 8.2 La regla de sincronía

**Quien agregue, elimine o reordene una pregunta refleja el mismo cambio en el solucionario de su
bloque en la misma edición**, con el enunciado copiado literalmente. La comprobación se corre antes
de cerrar, desde la carpeta del bloque:

```bash
for f in [0-9][0-9]-*.md l[0-9][0-9]-*.md; do
  case "$f" in *respuestas*) continue;; esac
  n=$(sed -n '/^## 🧠 Preguntas/,$p' "$f" | grep -cE '^[0-9]+\. ')
  printf '%-50s %s\n' "$f" "$n"
done
grep -cE '^\*\*[0-9]{2} → [0-9]+\.' *-respuestas.md   # debe igualar la suma
```

### 8.3 Las tres capas de la respuesta

```text
⏱️ 30 segundos  → lo que dices primero. Una o dos frases.
🗣️ 2 minutos    → lo que añades cuando dicen "cuéntame más". Tres a cinco frases.
🔬 El detalle   → el matiz, la excepción, el número, y **la categoría cuando aplica**.
```

- **La capa de 30 segundos se escribe como se diría.** Si no cabe en una respiración, está mal.
- **La capa de 2 minutos añade, no repite.**
- **El detalle es donde vive la categoría.** Es la capa natural para "el estándar no lo fija;
  Postgres hace A y MySQL hace B" y para el número medido.

---

## 9. 🧷 Vocabulario visual: reglas y callouts

### 9.1 La sesión (bloque `text` o `sql`)

El recurso principal. Se pega **con el prompt del motor**, para que se vea dónde se está:

```text
tienda=# SELECT count(*) FROM pedidos WHERE estado = 'PENDIENTE';
 count
-------
  4127
(1 fila)
```

Cuando hay **dos sesiones**, se marcan y se ordenan en el tiempo:

```text
-- sesión A                          -- sesión B
BEGIN;
UPDATE pedidos SET estado='ENVIADO'
  WHERE id='PED-00042';
                                     BEGIN;
                                     UPDATE pedidos SET estado='ANULADO'
                                       WHERE id='PED-00042';
                                     -- ⏸ bloqueada: espera a que A confirme
COMMIT;
                                     -- ▶ continúa, y pisa el cambio de A
```

**Los planes de `EXPLAIN` se pegan enteros**, sin recortar los costes ni los tiempos. Recortar un
plan es quitarle la evidencia.

### 9.2 Frase de respuesta correcta (blockquote)

Para la única frase que deberías decir en voz alta. El **veredicto** de §6.1 es un caso particular y
usa siempre la etiqueta `**Veredicto:**`.

### 9.3 Callouts admitidos

Se usan en blockquote, con negrita en la etiqueta. **Como mucho uno por sección `##`, y nunca dos
seguidos.**

- ⚠️ **Advertencia.** Ignorarlo produce una respuesta incorrecta o un fallo real.
- 🧠 **Modelo mental.** La frase que hay que llevarse.
- 💡 **Truco.** El matiz que casi nadie dice y que sube la nota.
- 🩺 **Diagnóstico.** Qué mirarías primero, y con qué consulta.
- 📜 **Estándar o motor.** La diferencia entre lo que manda la norma y lo que hace tu motor, cuando
  merece destacarse fuera de la sección de §6, punto 6.
- ⏱️ **Coste.** Tiempo, E/S, espacio, concurrencia o riesgo, cuando no es obvio.
- 📝 **Contexto.** Por qué la respuesta "clásica" que el lector encontrará por internet ya no aplica.
- 📚 **Referencia inline.** El enlace útil justo donde nace la duda.

**Escala de dificultad 🟢🟡🟠🔴.** Solo en enunciados de preguntas y ejercicios (§8.1). En labs se
admiten 🔥 y 💀 para los ejercicios fuera de conteo.

**Marcadores ✅ y ❌.** Solo como señal de sí/no en tablas y bloques `text`.

Fuera de esta lista, de ✅/❌, de la escala y de los emojis de encabezado de §3, **no se usan otros
emojis**. Nada de 🚨, 💸 ni 🎉. La excepción declarada es 🪦 para la sección "lo obsoleto".

### 9.4 Autopsia de una consulta lenta

Cuando un capítulo documenta un fallo real, la estructura es:

1. **El síntoma**, tal y como lo ve el equipo: el informe que tarda, el despliegue que se queda
   colgado, el número que no cuadra.
2. **La sesión real** que lo reproduce, con su plan o su bloqueo.
3. **Qué lo causa**, y si es del estándar, del motor o del esquema.
4. **La corrección**, con la sesión de después y el número nuevo.
5. **La generalización**: qué clase de error es y dónde más aparece.

### 9.5 Diagramas: Mermaid, y la sesión sigue en `text`

A 2026-10-05 el corpus no tiene ningún diagrama: todo lo que parece un dibujo es una sesión de dos
terminales en columnas o una salida de `psql`, y eso es tiempo y salida literal, no un diagrama.
**Todo diagrama que se añada nace en Mermaid**, con estas reglas:

- **` ```mermaid ` con `flowchart`** para nodos y flechas: un árbol B o un árbol de decisión, el
  camino de una escritura (búfer → WAL → `fsync` → página), la réplica y sus réplicas, el grafo de
  esperas de un interbloqueo, el reparto de particiones. Decisión `{…}`, resultado `([…])`, la
  respuesta en la arista; formas para distinguir, nunca color (sin `style`, `classDef` ni
  `%%{init}%%`). `LR` para decisiones y flujos; `TD` para árboles.
- **` ```mermaid ` con `sequenceDiagram`** solo cuando el contenido es una secuencia de mensajes entre
  partes —el driver y el servidor, la aplicación y la caché—, y se declara.
- **Sigue en ` ```text ` o ` ```sql `** lo que es literal o tiempo: la sesión real (§9.1), las dos
  sesiones en columnas, las salidas de `psql`, `mysql`, `cqlsh` y `EXPLAIN`, las tablas alineadas y
  las comparaciones planas `X → Y`. **Una sesión no se redibuja como diagrama**: perdería la salida
  literal, que es lo que este corpus enseña.
- **Se valida dibujándolo**: todo `.md` con Mermaid pasa por `mmdc` en un directorio de `zz-code/`
  antes de cerrar, y `reflow.py` lo deja intacto porque es un bloque de código.

---

## 10. 📚 Bibliografía, referencias y enlaces

### 10.1 Enlaces externos y orden de autoridad

**El estándar es de pago, así que la fuente citable es la documentación del motor.** El cierre `## 📚
Para profundizar` admite, **en este orden y marcando el tipo**:

1. **Documentación oficial del motor**, con URL completa y **sección concreta**: PostgreSQL, MySQL,
   MariaDB, SQLite, Redis, MongoDB. Es la primera entrada de casi todos los capítulos.
2. **El estándar ISO/IEC 9075**, cuando el capítulo se apoya en lo que manda: **por parte y
   cláusula, sin URL y diciendo que es de pago**. Si lo que se cita es un borrador público, se dice
   que es un borrador.
3. **Libro**, con autor, título, editorial, año y **capítulo concreto**. Sin URL. Los tres de
   cabecera del corpus: *Designing Data-Intensive Applications* (Kleppmann), *SQL Performance
   Explained* (Winand) y *The Art of PostgreSQL* (Fontaine).
4. **Recurso de referencia mantenido y sin publicidad**, del tipo `use-the-index-luke.com` o el wiki
   oficial del motor.
5. **Herramienta**: `pgbench`, `pg_stat_statements`, `explain.dalibo.com`, Testcontainers.
6. **Artículo de ingeniería** de un equipo que lo sufrió, con autor y fecha.
7. **Tutorial aplicado**, al final y marcado como tutorial. **Baeldung se cita por título entre
   comillas angulares y sin URL**: su CDN responde `403` a cualquier verificación automática.
8. **Video o charla**, solo por canal y título, sin URL.

**Máximo ocho entradas por capítulo.**

Reglas duras:

- **No se inventan URLs.** Un enlace no verificado no se escribe.
- **Se comprueban por código de estado**, en la misma edición en que se escriben. Ojo: la
  documentación de PostgreSQL responde `302` a la portada cuando la ruta ya no existe, así que
  **aterrizar en el índice general cuenta como roto**.
- **La documentación del motor se enlaza con su versión en la URL** cuando el motor la versiona
  —`/docs/18/`—, no a `/current/`, que se mueve bajo los pies.
- **Nunca se cita una versión obsoleta como vigente.** Si el lector va a encontrarse consejos de
  MySQL 5.7 o de PostgreSQL 9.x por internet, se dice que están anticuados y se da lo vigente.
- **Una URL por concepto**, específica.

### 10.2 Enlaces internos

- **Formato:** enlace Markdown relativo, con el número del documento en el texto visible.
- **Con ancla cuando la sección destino existe y es estable.**
- **Entre bloques, ruta relativa y diciendo qué hay allí**, no solo enlazando:

  ```markdown El método de diseño desde el patrón de acceso está en
  [`07/06`](../07-clave-valor/06-dynamodb-diseno-desde-el-acceso.md) — aquí solo se aplica a
  Cassandra. ```

- **Cada capítulo enlaza al menos a los dos capítulos con los que más se toca**, y cierra con el pie
  de navegación.
- **Ningún enlace sale de esta carpeta** (§1.1).

### 10.3 Vigencia

El README de la raíz declara la fecha de revisión general y **cada documento la repite en su
encabezado**. Cuando un documento incorpora algo reciente —una versión nueva del motor, una función
que antes no existía, un valor por defecto que cambió— se marca con 📝 en el texto.

---

## 11. 🔗 Coherencia entre documentos

- **No contradecir documentos anteriores.** Si `04/02` establece que el `REPEATABLE READ` de
  PostgreSQL es *snapshot isolation*, ningún otro capítulo lo trata como el del estándar.
- **Terminología estable.** Si `03` dice "plan de ejecución", el resto no alterna con "plan de
  consulta" ni con "query plan" sin motivo. Si `04` dice "bloqueo", nadie escribe "lock" suelto.
- **Un concepto tiene un solo dueño**, según la tabla de §7.1. Los demás usan y enlazan.
- **La frontera es de altitud dentro de la carpeta.** El bloque 3 explica **cómo decide el motor**,
  el 10 **cómo se lo pides desde el lenguaje**, el 11 **qué hace el ORM por ti** y el 12 **qué
  decides tú al diseñar**. Los cuatro pueden hablar de índices sin duplicarse.
- **Fuentes de verdad, en orden:**
  1. **Esta guía**, que manda sobre las normas por defecto del repositorio en lo que declare.
  2. **`dominio-entorno-y-datos-fijos.md`**, para esquema, datos, versiones y nombres.
  3. **`CLAUDE.md` de la raíz**, para lo que esta guía no toca.
  4. **`README.md` del corpus y del bloque**, para alcance y orden de lectura.
  5. **Documentos ya publicados** — no se contradicen, se matizan.
  6. Decisiones explícitas del chat actual.

---

## 12. ✅ Checklist antes de dar por cerrado un `.md`

**Estructura**

- [ ] Sigue la plantilla de §6, o está declarado como excepción.
- [ ] Encabezado con objetivo, qué asume leído **con enlace**, y **`Vigencia:`**.
- [ ] Abre con `## 1. 🎯 El problema`, no con una definición.
- [ ] Numeración `##` arábiga y continua; emoji funcional en `##`, **ninguno en `###`**.
- [ ] Hay sección **`📜 Estándar, motor y convención`**, con la fila de convención cuando la haya.
- [ ] Cierra con pie de navegación: Anterior, Siguiente y Relacionado.

**Contenido**

- [ ] Cada concepto sigue **qué es → cómo va → quién lo manda → cuánto → cuándo sí → cuándo no →
  veredicto** (§6.1), sin saltarse ninguno de los tres obligatorios.
- [ ] **Toda afirmación está etiquetada** como estándar, motor o convención; ninguna dice "en
  algunos motores".
- [ ] Ninguna cláusula del estándar citada sin haberla verificado; si no se verificó, se dice.
- [ ] Todo mecanismo lleva su precio en tiempo, E/S, espacio, concurrencia o riesgo de pérdida.
- [ ] **Todas** las sesiones del capítulo están corridas de verdad contra el entorno del corpus
  (§4.4), y su salida está pegada literal. Lo que no se pudo correr va marcado `(sin confirmar)` y
  declarado en el §1 del capítulo, diciendo con qué se vería.
- [ ] **Ningún plan de `EXPLAIN` inventado ni recortado.**
- [ ] Nada de lo excluido en §1.2 se explica aquí como si fuera del temario.
- [ ] Esquema, identificadores y volúmenes de §5.1 respetados; sin `foo`, sin `tabla1`.
- [ ] **Prosa envuelta a 100 columnas** (§3). `python3 prompts/reflow.py --check <fichero>` no
  propone cambios.
- [ ] Dentro de su banda de §4.6 **medida después del ajuste de ancho**, nunca antes: 200-350 para
  un capítulo normal, 200-450 para uno declarado denso en la lista de §4.6. Pasado su
  disparador —400 o 500— se poda por el orden de §4.6, y la decisión se declara en el `📝` de §1 del
  propio capítulo.
- [ ] Si la edición cambia preguntas, títulos, orden o dueños, **el README del bloque está
  actualizado en la misma edición** (§7.5), y el de la raíz si cambian los totales.
- [ ] Si pasa de 400 líneas, **abre con índice de salto rápido** (§6.2).

**Forma**

- [ ] Tono semi formal y cálido, tuteo latinoamericano (§2).
- [ ] Palabras clave de SQL en mayúsculas; términos del oficio en inglés con su traducción la
  primera vez (§3).
- [ ] Sin prosa telegrama; tablas sin celdas que necesiten explicación.
- [ ] Diagramas, si los hay, en Mermaid y dibujados con `mmdc`; sesiones y salidas en `text` o `sql`
      (§9.5).
- [ ] Como mucho un callout por sección `##`, y solo los de §9.3.

**Evaluación**

- [ ] Entre 15 y 25 preguntas, graduadas 🟢🟡🟠🔴, **ordenadas de menor a mayor dificultad**.
- [ ] Al menos dos preguntas distinguen estándar de motor.
- [ ] Reparto de dificultad distinto al del capítulo vecino.
- [ ] En labs, `## 🧪 Ejercicios` presentes y graduados, con teardown junto al recurso.
- [ ] **Solucionario del bloque actualizado en la misma edición** (§8.2), con enunciado literal.
- [ ] Las tres capas ⏱️ 🗣️ 🔬 en todas las respuestas.

**Referencias y enlaces**

- [ ] `## 📚 Para profundizar` presente, máximo ocho entradas, ordenadas por autoridad (§10.1).
- [ ] Todas las URLs verificadas por código de estado en esta edición, y ninguna aterriza en un
  índice general.
- [ ] La documentación del motor enlazada **con su número de versión**, no con `/current/`.
- [ ] Ninguna versión de motor, imagen o librería escrita de memoria.
- [ ] Al menos dos enlaces internos, y ningún enlace interno roto.
- [ ] **Cero enlaces fuera de esta carpeta** (§1.1):

```bash
# desde la raíz del corpus: no debe imprimir nada
grep -rn '](\.\./\.\./' --include='*.md' . | grep -v '^./prompts/'
grep -rn 'repaso-\(aws\|gcp\|spring\|arquitectura\|bases\|microservicios\|apis\)' --include='*.md' . \
  | grep -v '^./prompts/'
```
