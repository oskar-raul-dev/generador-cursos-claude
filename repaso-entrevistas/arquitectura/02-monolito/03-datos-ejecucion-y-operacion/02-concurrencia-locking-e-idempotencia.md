# 02 — Concurrencia, locking e idempotencia

Aprenderás a proteger el stock y los cobros ante dos amenazas que se parecen y no son la misma:
peticiones distintas que se pisan sobre la misma fila, y la misma petición que llega dos veces. Cada
una tiene su defensa, y confundirlas deja abierto uno de los dos agujeros.

## 1. 🎯 Síntoma y decisión

Tras escalar `CreateOrder` a tres réplicas llega una venta relámpago. `SKU-003` tenía 5 unidades y
se entregan 7 reservas; ninguna restricción de la base saltó. La misma semana, un cliente cuya
petición expiró en el gateway reintenta y termina con dos reservas del mismo carrito, separadas por
treinta segundos.

Los dos incidentes dejan «una reserva de más», pero no tienen la misma causa. En el primero, dos
intenciones distintas compitieron por una fila; en el segundo, una sola intención llegó dos veces.
La decisión de este capítulo es qué defensa corresponde a cada uno y cuánto cuesta.

## 2. 🧠 Modelo mental

```text
carrera: dos intenciones, una fila          repetición: una intención, dos llegadas
cliente A ─► reservar 1 ─┐                  cliente ─► reservar 1 (K-1) ─► timeout
cliente B ─► reservar 1 ─┼─► fila SKU-003   cliente ─► reservar 1 (K-1) ─► ¿otra vez?
                         │
defensa: la base compara y resta            defensa: la clave identifica la intención
en la misma sentencia, o con versión        y devuelve el mismo resultado
```

Contra la **carrera**, la comparación tiene que ocurrir donde vive el dato: un `UPDATE` condicional,
una versión que la escritura verifica o un lock de fila. Un mutex en el proceso no alcanza, porque
cada réplica tiene el suyo. Contra la **repetición**, hace falta una identidad de operación que la
base haga única, confirmada en la misma transacción que el efecto, y una respuesta guardada que se
devuelve igual. Ninguna de las dos defensas sustituye a la otra: un `UPDATE` condicional no distingue
un reintento de un cliente nuevo, y una clave no impide que dos claves distintas se pisen.

## 3. 🔍 Evidencia antes del diagnóstico

| Nivel | En el sistema de comercio |
|---|---|
| Observación | 7 reservas de `SKU-003` con stock inicial 5 y ninguna violación del `CHECK`; marcas de tiempo a milisegundos de distancia desde réplicas distintas; dos reservas con el mismo carrito separadas por un timeout del gateway |
| Inferencia | la reserva lee el stock, decide en la aplicación y escribe el valor calculado; la operación no tiene identidad propia |
| Diagnóstico | dos defectos: actualización perdida entre réplicas y efecto repetido por reintento |
| Recomendación | `UPDATE` condicional sobre la fila y clave de idempotencia reclamada en la misma transacción que la reserva |

Las cifras son del ejercicio. Qué refutaría el diagnóstico: si las unidades de más coinciden con
ajustes del backoffice, la causa es otro escritor, no la carrera; si las dos reservas «duplicadas»
tenían carritos distintos, eran dos intenciones y la clave no debe fusionarlas. La sección de código
reproduce los dos defectos contra PostgreSQL y muestra la salida.

## 4. 🛠️ Tres defensas para tres problemas

Una restricción de base protege la invariante incluso si otro camino de código se equivoca. Un
`UPDATE ... WHERE available >= quantity` puede reservar y comprobar en una operación; las filas
afectadas distinguen éxito de falta de stock. El lock optimista añade una versión y aborta si alguien
cambió la fila leída. El pesimista reserva acceso durante la transacción y conviene solo cuando la
contención hace demasiado caros los conflictos repetidos.

```text
petición K ─► INSERT operation(K, IN_PROGRESS) con UNIQUE(K)
             ├─ creada: ejecuta reserva/cobro y guarda respuesta
             └─ existente: devuelve respuesta o estado de la misma operación
```

La idempotencia une identidad, efecto y respuesta. No consiste en ignorar un duplicado: la misma
clave con el mismo payload devuelve el resultado estable; con otro payload se rechaza. La fila de
deduplicación debe confirmarse con el efecto que protege o quedar sujeta a reconciliación explícita.

Los deadlocks y conflictos son resultados esperables bajo concurrencia. Se reintentan solo cuando el
error es transitorio, con límite y jitter. Si un timeout deja incierto un cobro, primero se consulta
por la clave; repetir a ciegas puede producir el segundo efecto que se intentaba evitar.

## 5. 💻 La garantía en código: Go para la carrera, Java para la repetición

Dos fallos distintos, dos ejemplos. Go reproduce la **carrera** entre peticiones simultáneas; Java, la
**repetición** de una misma intención. Los dos usan el mismo esquema en PostgreSQL:

```sql
CREATE TABLE inventory_stock (
  sku       text PRIMARY KEY,
  available integer NOT NULL CHECK (available >= 0)
);
CREATE TABLE idempotency_keys (
  key      text PRIMARY KEY,
  request  text NOT NULL,
  response text NOT NULL
);
```

- El `CHECK` es la restricción de base: ningún camino de código puede dejar el stock negativo.
- `idempotency_keys.key` es `PRIMARY KEY`: la unicidad de la clave la garantiza la base, no una
  consulta previa.

### Go: leer y escribir no es comprobar y restar

```go
// Versión ingenua: lee, decide en memoria y escribe el valor calculado
func reserveNaive(ctx context.Context, db *sql.DB, sku string, qty int) (bool, error) {
	tx, err := db.BeginTx(ctx, nil)
	if err != nil {
		return false, err
	}
	defer tx.Rollback()
	var available int
	err = tx.QueryRowContext(ctx,
		`SELECT available FROM inventory_stock WHERE sku = $1`, sku).Scan(&available)
	if err != nil {
		return false, err
	}
	if available < qty {
		return false, nil
	}
	_, err = tx.ExecContext(ctx,
		`UPDATE inventory_stock SET available = $1 WHERE sku = $2`, available-qty, sku)
	if err != nil {
		return false, err
	}
	return true, tx.Commit()
}

// Versión condicional: la base comprueba y resta en una sola sentencia
func reserve(ctx context.Context, db *sql.DB, sku string, qty int) (bool, error) {
	res, err := db.ExecContext(ctx,
		`UPDATE inventory_stock SET available = available - $1
		  WHERE sku = $2 AND available >= $1`, qty, sku)
	if err != nil {
		return false, err
	}
	rows, err := res.RowsAffected()
	return rows == 1, err
}
```

- La versión ingenua abre una transacción y aun así pierde actualizaciones. En *read committed*, el
  nivel por defecto de PostgreSQL, veinte transacciones pueden leer `5`, y cada una escribe `4`.
- El `CHECK` no salta: ningún valor escrito es negativo. La restricción protege la invariante del
  número, no la de «no vender más de lo que había».
- La versión condicional hace que la base compare y reste sobre la fila bloqueada. Si otra
  transacción la cambió, PostgreSQL reevalúa el `WHERE` con el valor nuevo. `RowsAffected` distingue
  reserva de falta de stock sin una segunda consulta.

El arnés de prueba repone `SKU-003` a 5 unidades y suelta a la vez veinte goroutines que piden una
unidad cada una, con un pool de veinte conexiones:

```bash
DATABASE_URL='postgres://postgres:scratch@localhost:35999/commerce?sslmode=disable' go run .
```

- `DATABASE_URL` apunta a un PostgreSQL 17 desechable en un contenedor local; el driver es
  `github.com/lib/pq` sobre `database/sql`.
- `go run .` compila y ejecuta el `main` del directorio, que corre primero la versión ingenua y
  después la condicional.

```text
naive       reserved=20 rejected=0 failed=0 stock_left=3
conditional reserved=5 rejected=15 failed=0 stock_left=0
```

Veinte clientes recibieron una reserva por cinco unidades, y el stock final ni siquiera es cero: es
el último valor que escribió alguien que leyó uno viejo. Tres corridas dieron `stock_left` de 3, 2
y 3; la versión condicional dio 5 reservas y stock 0 en las tres. Un mutex en el proceso no lo
habría arreglado: con dos réplicas, cada una tendría el suyo.

### Java: una clave, un efecto

```java
// Una clave, un efecto: la fila de la clave y la reserva se confirman juntas
final class IdempotentReservation {

    static String reserveOnce(Connection c, String key, String sku, int qty) throws SQLException {
        String request = sku + ":" + qty;
        c.setAutoCommit(false);
        try {
            try (var claim = c.prepareStatement("""
                    INSERT INTO idempotency_keys (key, request, response)
                    VALUES (?, ?, 'IN_PROGRESS') ON CONFLICT (key) DO NOTHING""")) {
                claim.setString(1, key);
                claim.setString(2, request);
                if (claim.executeUpdate() == 0) {   // otra transacción ya confirmó esta clave
                    c.rollback();
                    return previousResponse(c, key, request);
                }
            }
            String response;
            try (var take = c.prepareStatement("""
                    UPDATE inventory_stock SET available = available - ?
                     WHERE sku = ? AND available >= ?""")) {
                take.setInt(1, qty);
                take.setString(2, sku);
                take.setInt(3, qty);
                response = take.executeUpdate() == 1 ? "RESERVED" : "OUT_OF_STOCK";
            }
            try (var save = c.prepareStatement(
                    "UPDATE idempotency_keys SET response = ? WHERE key = ?")) {
                save.setString(1, response);
                save.setString(2, key);
                save.executeUpdate();
            }
            c.commit();
            return response;
        } catch (SQLException e) {
            c.rollback();
            throw e;
        }
    }

    private static String previousResponse(Connection c, String key, String request)
            throws SQLException {
        try (var read = c.prepareStatement(
                "SELECT request, response FROM idempotency_keys WHERE key = ?")) {
            read.setString(1, key);
            try (var row = read.executeQuery()) {
                row.next();
                String response = row.getString(1).equals(request)
                        ? row.getString(2)
                        : "KEY_REUSED_WITH_DIFFERENT_REQUEST";
                c.commit();
                return response;
            }
        }
    }
}
```

- La clave se reclama con `INSERT ... ON CONFLICT DO NOTHING` **dentro** de la misma transacción que
  la reserva. Un duplicado concurrente queda esperando en el índice único hasta que la primera
  transacción confirma; entonces no inserta nada y lee la respuesta ya guardada. Nunca ve
  `IN_PROGRESS`.
- Si la primera transacción falla y hace rollback, la clave desaparece con ella y el duplicado que
  esperaba ejecuta la reserva: no queda una clave huérfana que bloquee reintentos legítimos.
- La respuesta estable incluye el rechazo: `OUT_OF_STOCK` también se guarda y se repite.
- La misma clave con otro `request` no devuelve el resultado anterior: se rechaza, porque es otra
  intención con un identificador reutilizado.

El arnés corre cuatro casos con `SKU-003` en 5 unidades: una reserva sin clave que el cliente
reintenta tras un timeout; diez hilos simultáneos con la clave `K-1`; `K-1` otra vez con dos
unidades; y diez hilos con claves distintas.

```text
without key, 1 request + 1 retry: stock_left=3
same key x10 concurrent:          {RESERVED=10} stock_left=4
same key, different quantity:     KEY_REUSED_WITH_DIFFERENT_REQUEST
distinct keys x10 concurrent:     {OUT_OF_STOCK=6, RESERVED=4} stock_left=0
```

Sin clave, el reintento consumió una segunda unidad. Con clave, diez peticiones recibieron la misma
respuesta y el stock bajó una sola vez. El límite es igual de visible: la garantía existe porque el
efecto vive **en la misma base** que la clave. Un cobro a un proveedor externo no entra en ese
`COMMIT`; ese caso es un [fallo parcial remoto](../04-monolito-distribuido/05-fallos-parciales-retries-y-falsas-transacciones.md)
y necesita una clave que el proveedor también respete. El precio local es latencia: los duplicados
esperan el bloqueo de la clave mientras dura la transacción original.

**Validación.** El 2026-09-29 ambos ejemplos corrieron contra `postgres:17.11-alpine` en un
contenedor desechable: Go con `go1.27.1` y `lib/pq v1.10.9` (tres corridas), Java con `javac 25.0.4`
y el driver JDBC `42.7.13` (dos corridas, idénticas). Las salidas son literales; la
reproducción es local, en un solo nodo y sin red real, y no mide rendimiento.

## 6. 🧰 Plataformas

| Plataforma | Mecanismo relevante | Qué no resuelve | Trampa frecuente |
|---|---|---|---|
| Java | versión JPA o lock SQL dentro de transacción | no sustituye una restricción de base | reintentar sin límite |
| Node/TypeScript | transacción del driver y constraint único | el event loop no evita carreras entre peticiones | hacer check-then-insert sin constraint |
| Go | `sql.Tx`, filas afectadas y errores tipados | goroutines no serializan la base | proteger con mutex local entre réplicas |
| Python | transacción y constraint; lock de fila si aplica | el GIL no protege procesos ni datos remotos | usar un lock en memoria |

Las cuatro trampas comparten raíz: tratar un mecanismo del proceso —mutex, event loop, GIL,
goroutine— como si protegiera un dato que vive fuera del proceso. Ninguno se entera de lo que hace
otra réplica, ni un job, ni el backoffice. La fila de Go es la que el ejemplo ejecuta: `RowsAffected`
es la forma de leer el resultado de la comparación que hizo la base, y olvidarse de leerlo es el
fallo silencioso de esa plataforma.

## 7. ⚖️ Decisión y coste

Combina una restricción de stock con una identidad estable de operación. Elige control optimista o pesimista según los conflictos y las esperas medidos; ambos necesitan una transacción bien delimitada. Una cola por SKU puede ordenar una partición caliente, pero añade latencia y no elimina deduplicación ni restricciones. Conserva el mecanismo más simple que evite sobreventa y duplicados bajo concurrencia real.

## ⚠️ Errores frecuentes

- «Si está en un solo proceso no hay carreras». Peticiones concurrentes, jobs y réplicas comparten la fila; el ejemplo en Go vendió 20 unidades de 5 desde un único proceso.
- «Un `CHECK (available >= 0)` evita la sobreventa». Solo impide números negativos; una actualización perdida escribe valores positivos y válidos.
- «Idempotencia es ignorar duplicados». Es devolver el mismo resultado para la misma intención y rechazar una clave reutilizada con otro contenido.
- «Con locking optimista basta reintentar hasta que funcione». Sin límite ni jitter, bajo contención alta los reintentos multiplican la carga que causó el conflicto.
- «La clave se guarda al terminar la operación». En otra transacción, una caída entre ambas deja efecto sin clave o clave sin efecto.

## 8. ✅ Veredicto

Separa las dos preguntas. Para la carrera, deja que la base compare y reste en la misma sentencia,
o usa una versión, y elige lock pesimista o cola por SKU solo si la contención medida lo pide. Para
la repetición, reclama la clave en la misma transacción que el efecto y guarda la respuesta,
rechazos incluidos. Las dos defensas protegen efectos dentro de la base; un cobro remoto necesita
además que el proveedor respete tu clave o te deje consultar por ella.

## 📚 Referencias

- [PostgreSQL Explicit Locking](https://www.postgresql.org/docs/current/explicit-locking.html)
- [PostgreSQL Constraints](https://www.postgresql.org/docs/current/ddl-constraints.html)
- [PostgreSQL 17: Read Committed Isolation Level](https://www.postgresql.org/docs/17/transaction-iso.html#XACT-READ-COMMITTED)
- [PostgreSQL 17: INSERT, ON CONFLICT Clause](https://www.postgresql.org/docs/17/sql-insert.html#SQL-ON-CONFLICT)
- [HTTP Semantics: Idempotent Methods](https://www.rfc-editor.org/rfc/rfc9110.html#name-idempotent-methods)

## 🧠 Preguntas

1. 🟢 ¿Qué diferencia hay entre una carrera y una repetición, y qué defensa corresponde a cada una?
2. 🟢 ¿Qué es una actualización perdida (*lost update*)?
3. 🟢 ¿Por qué el `CHECK (available >= 0)` no saltó en la versión ingenua del ejemplo?
4. 🟢 ¿Qué hace un `UPDATE ... WHERE available >= quantity` que no hace la secuencia leer, decidir y escribir?
5. 🟢 ¿Qué tres cosas une una clave de idempotencia?
6. 🟢 ¿Qué diferencia hay entre locking optimista y pesimista?
7. 🟡 ¿Por qué un mutex dentro del proceso no evita la sobreventa cuando hay varias réplicas?
8. 🟡 ¿Cuándo elegirías serializar la partición caliente con una cola por SKU en lugar de competir por la fila?
9. 🟡 ¿Qué evidencia distinguiría una sobreventa por carrera de una por ajustes manuales de stock?
10. 🟡 ¿Por qué la misma clave con otro contenido debe rechazarse en lugar de devolver el resultado guardado?
11. 🟡 ¿Por qué `OUT_OF_STOCK` también se guarda como respuesta de la clave?
12. 🟡 ¿Qué le pasa a un duplicado concurrente mientras sigue abierta la primera transacción que reclamó la clave?
13. 🟡 ¿Qué ocurre con la clave si la primera transacción hace rollback, y por qué es la conducta correcta?
14. 🟡 ¿Cuándo es un error reintentar automáticamente un conflicto de versión?
15. 🟡 ¿Qué contención medirías para elegir entre locking optimista y pesimista?
16. 🟡 ¿Cuánto tiempo conservarías las claves de idempotencia y de qué depende?
17. 🟡 ¿Qué diferencia operativa hay entre una versión JPA y comprobar filas afectadas con `sql.Tx` en Go?
18. 🟠 ¿Por qué el event loop de Node y el GIL de Python no reemplazan una restricción única compartida?
19. 🟠 El cliente reintenta un cobro tras un timeout y el proveedor no acepta claves de idempotencia. ¿Qué garantía puedes ofrecer y cuál no?
20. 🟠 Tras escalar a tres réplicas aparecen conflictos de versión en el 30 % de las reservas de un SKU. ¿Qué harías primero?
21. 🟠 Aparece un deadlock al reservar pedidos de varias líneas. ¿Cuál es la causa típica y cómo la corregirías sin subir el aislamiento?
22. 🟠 Quieres añadir la tabla de claves a un flujo que ya está en producción. ¿Qué despliegue reversible harías?
23. 🟠 Dos equipos discrepan: uno quiere `SELECT ... FOR UPDATE` en toda reserva y otro solo `UPDATE` condicional. ¿Cómo decidirías?
24. 🟠 ¿Qué criterio te diría que no hace falta una cola por SKU?

---

[Índice del bloque](README.md) · [Índice general](../README.md)

**Anterior:** [01 — Transacciones locales y límites de consistencia](01-transacciones-locales-y-limites-de-consistencia.md).

**Siguiente:** [03 — Eventos internos, jobs y procesamiento asíncrono](03-eventos-internos-jobs-y-procesamiento-asincrono.md).
