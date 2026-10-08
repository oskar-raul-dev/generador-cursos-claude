# 🎬 Fase 24 — La saga orquestada: el préstamo sale de la base, y deshacer se vuelve negocio

> **Curso:** Laboratorio de contenedores y Kubernetes local · Fase 24 de 27 · Parte IV — El lab de patrones distribuidos · **densa**
> **Perfil:** el cluster `lab`, con los valores de `minimo` · **Observabilidad encendida:** trazas (Tempo)
> **Motor de referencia:** Docker · 🦭 no diverge en esta fase: la saga vive en el cluster; el patrimonio corre en compose con cualquiera de los dos
> **Servicios que toca:** `inventory` (el orquestador) y `replenish` · **Paso de generación:** G11 · Saga orquestada
> **Depende de:** [Fase 23](23-grpc-y-el-balanceo.md) · **Habilita:** [Fase 25](25-la-coreografia.md)
> **Incidentes que reserva:** ninguno · **Medición:** ninguna (la rotura de la sección 8)
> **Apéndices de apoyo:** [a03](a03-contratos-y-prompts-de-generacion.md), [a04](a04-kubectl-y-k9s.md), [a05](a05-diccionarios.md), [a16](a16-el-patrimonio.md)
> **Fecha de verificación ejecutada:** 04/10/2026 · macOS arm64
> **Objetivo:** llevar el préstamo entre droguerías de un procedimiento en una sola base a una saga entre dos servicios, con cada compensación escrita como operación de negocio, y ver con el generador de caos y las trazas dónde una saga queda a medias y quién la termina.

---

## 🧭 1. Dónde estamos

La [Fase 23](23-grpc-y-el-balanceo.md) dejó las trazas encendidas y una venta que cruza los cuatro servicios en un solo
árbol de tiempos. La venta, sin embargo, es la parte fácil del negocio: descuenta en la misma droguería que cobra. Lo que
trajo la tecnología a La Vecina en 2006, y lo que la saca del monolito en 2026, es otra cosa: **el préstamo entre
vecinas**. Una droguería no tiene el inhalador, otra sí, y alguien tiene que descontar en un lado, mandar la moto y
cobrarle al cliente en el otro.

En el Siga eso es un procedimiento en PL/SQL. En Contingencia, el mismo procedimiento portado a PL/pgSQL en 2016, que
[a16](a16-el-patrimonio.md) trae andando: `register_loan`. Andrés lo abrió en la primera reunión de esta parte con una
frase que no era técnica:

> *"Este procedimiento hace lo que doña Graciela dijo en 1999: 'yo le presto, pero me lo anota y me lo devuelve'. La
> base se acuerda de devolver si algo sale mal. El día que lo partamos en dos servicios, ¿quién se acuerda?"*

Doña Graciela, que estaba en la reunión porque el tema era el préstamo, contestó por él: *"Pues el que lo pidió, mijo.
Lo que se presta se devuelve."* Esta fase es esa frase convertida en código: el préstamo como **saga** coordinada por
`inventory`, donde cada paso tiene su forma de devolverse. Y es también la fase donde aparece la diferencia que la
historia lleva veinte años escondiendo: *"siempre llega"* no significa *"siempre llega ya"*.

---

## 🎯 2. Objetivos de esta fase

1. Ver en Contingencia por qué el préstamo funciona como transacción en una sola base, y por qué deja de funcionar
   cuando el stock y la moto viven en dos bases que no se ven.
2. Generar G11: `POST /loans` en `inventory`, con tres pasos (reservar, despachar, cobrar), sus compensaciones y su
   estado guardado en la base, y pasar la suite `inventory.g11.hurl`.
3. Provocar con el generador de caos un `replenish` caído, uno lento y una compensación que falla, y leer en las trazas
   el préstamo a medio compensar.
4. Matar el orquestador a mitad de una saga y comprobar que otra réplica la termina sin compensar nada dos veces.
5. Explicar con números por qué un timeout no es una falla: es un "no sé", y deja motos huérfanas.

---

## 🚫 3. Qué NO entra todavía

- **Los eventos**: la coreografía, el pub/sub que pierde mensajes y NATS → [Fase 25](25-la-coreografia.md).
- **La clave de idempotencia y el outbox**, que son el arreglo de las huérfanas de la sección 8 →
  [Fase 26](26-idempotencia-y-outbox.md).
- **Un motor de sagas o de flujos de trabajo** (los de la nube, o uno instalado en el cluster): el orquestador se
  escribe a mano para que se vea. La sección 10 nombra los de la nube.
- **El viaje de la moto**: el laboratorio no tiene motos; el destino recibe la unidad apenas se cobra.
- **El reembolso**: con el orden elegido, ningún paso falla después del cobro (sección 5.2). El ejercicio 23 lo escribe.

---

## 🧨 4. El problema, en el laboratorio

### 4.1 Una base que se acuerda de devolver

El patrimonio, en compose. `register_loan` hace tres cosas: bloquea la existencia del origen y la descuenta, registra
un movimiento `LOAN_OUT`, y crea la orden de reposición. Un préstamo de salbutamol de Girón (`DRO-003`) a Chapinero
(`DRO-007`):

```text
$ docker compose exec contingencia-db psql -U contingencia -d contingencia
SELECT register_loan('SKU-0003', 'DRO-003', 'DRO-007', 2);
 register_loan
---------------
             1
SELECT store_id, quantity FROM stock_level WHERE sku = 'SKU-0003' AND store_id = 'DRO-003';
 DRO-003  |       30
```

Ahora el mismo préstamo hacia una droguería que no existe. Los dos primeros pasos salen bien; el tercero choca con la
llave foránea:

```text
SELECT register_loan('SKU-0003', 'DRO-003', 'DRO-099', 2);
ERROR:  insert or update on table "replenishment_order" violates foreign key constraint "replenishment_order_destination_store_id_fkey"
DETAIL:  Key (destination_store_id)=(DRO-099) is not present in table "store".
SELECT store_id, quantity FROM stock_level WHERE sku = 'SKU-0003' AND store_id = 'DRO-003';
 DRO-003  |       30
SELECT count(*) AS movimientos_loan_out FROM stock_movement WHERE type = 'LOAN_OUT';
                    1
```

La existencia sigue en 30 y hay un solo `LOAN_OUT`: **la base deshizo sola el descuento y el movimiento**. Nadie
escribió una línea para eso. Es la propiedad que hace que el procedimiento de 2007 siga funcionando, y es tu instinto,
con razón: dentro de una transacción, si algo falló, no pasó nada.

### 4.2 Dos bases que no se ven

En el cluster, el stock vive en la base de `inventory` y las órdenes en la de `replenish`, con un usuario cada una
([Fase 12](12-estado-y-almacenamiento.md)). El procedimiento no se puede portar tal cual porque ninguna de las dos ve
a la otra:

```text
$ kubectl -n data exec postgres-0 -- psql -U inventory -d inventory -c "SELECT count(*) FROM replenishment_orders;"
ERROR:  relation "replenishment_orders" does not exist
$ kubectl -n data exec postgres-0 -- psql -U inventory -d replenish -c "SELECT count(*) FROM replenishment_orders;"
psql: error: … FATAL:  permission denied for database "replenish"
DETAIL:  User does not have CONNECT privilege.
```

Eso es lo que se buscó desde la [Fase 12](12-estado-y-almacenamiento.md): una base por servicio, para que la Braqui despegada no vuelva a estar atada al
esquema de otro. La factura llega ahora. **No hay una transacción que abarque las dos bases**, y el descuento en una y
la orden en la otra son dos confirmaciones distintas, con un pedazo de red en el medio.

### 4.3 La saga que ya existía, y que nadie compensa

La Vecina ya tiene un préstamo partido en dos sistemas, desde 2020: el aviso de traslados por archivo (historia §1.9).
El lote de Contingencia pasa los préstamos de `PENDING` a `DISPATCHED`, confirma, y **después** escribe el
`traslados_*.txt` que la Braqui recoge. Es una saga de dos pasos —descontar y avisar— sin ninguna compensación. Para
verla fallar basta con que el archivo no se pueda escribir:

```text
$ docker compose exec -u root contingencia chmod 555 /var/lib/contingencia/traslados
$ … SELECT register_loan('SKU-0005', 'DRO-005', 'DRO-004', 3);      # Sogamoso le presta a Tunja
                                                                     # dos minutos después, el lote:
contingencia-1  |   No se pudo escribir traslados_20261004_2312.txt: /var/lib/contingencia/traslados/traslados_20261004_2312.txt|#]
 id |   sku    | origin_store_id | destination_store_id | quantity |   status
----+----------+-----------------+----------------------+----------+------------
  3 | SKU-0005 | DRO-005         | DRO-004              |        3 | DISPATCHED
```

La orden quedó despachada, Sogamoso ya descontó sus tres unidades, y no existe ningún archivo que se lo cuente a la
Braqui. El código lo sabía —el comentario del `catch` dice *"Los préstamos ya quedaron despachados en la base. Nadie los
va a recibir."*— y no hace nada más que dejarlo en el log. **Nadie devuelve la unidad.** De ahí salen, entre otros, los
huérfanos que Luz Marina busca cada lunes.

> 🩻 **Esto sí funciona igual.** Dentro de cada servicio, la transacción local sigue valiendo exactamente como en
> Contingencia: el descuento y su movimiento se confirman juntos o no se confirman. Lo que se pierde es la transacción
> que cruza dos servicios, no las de cada uno.

---

## 🧩 5. La saga, en `inventory`

### 5.1 Qué es una saga

Una **saga** es una transacción larga partida en pasos, cada uno una transacción local de un solo servicio, donde cada
paso tiene una **compensación**: otra operación que deshace su efecto **de negocio**. Si el paso 3 falla, no hay
`ROLLBACK`: se ejecutan las compensaciones del 2 y del 1, en orden inverso. El término viene de un artículo de 1987 de
Garcia-Molina y Salem, pensado para transacciones que duraban demasiado como para tener bloqueos abiertos; en
microservicios se volvió la forma estándar de coordinar datos que viven en bases distintas.

Hay dos maneras de coordinarla. **Orquestada**: un servicio decide el siguiente paso y llama a los demás. **Por
coreografía**: cada servicio reacciona a eventos de los otros, y nadie tiene el dibujo completo. Esta fase hace la
primera; la [Fase 25](25-la-coreografia.md), la segunda, y las compara.

> 🧠 **El modelo mental.** Una transacción dice *"esto nunca pasó"*. Una compensación dice *"esto pasó, y ahora pasa lo
> contrario"*. La diferencia se ve en los datos: después de una compensación hay **dos** movimientos, el que reservó y
> el que liberó, y una orden cancelada con su código de razón. Es la regla de [D33](a03-contratos-y-prompts-de-generacion.md#️-los-cuatro-contratos-de-un-vistazo) llevada a la saga: el estado se cambia
> con hechos, también para deshacer.

### 5.2 El préstamo, en tres pasos y en este orden

El contrato de `POST /loans` (en `contracts/openapi/inventory.yaml`) dice los pasos, en orden, con la compensación de
cada uno:

| Paso | Qué hace | Dónde | Su compensación |
|---|---|---|---|
| `RESERVE` | un `LOAN_OUT` en el origen, con la fila bloqueada | base de `inventory` | un `ADJUSTMENT` positivo con el código `LOAN_RELEASED` |
| `DISPATCH` | una orden de reposición con `originStore`: la moto | `replenish` | cancelarla con `SAGA_COMPENSATION`, mientras siga en `PENDING` |
| `CHARGE` | el cobro al cliente, al precio del destino | `pricing` y base de `inventory` | un reembolso (no hace falta: es el último) |
| `RECEIVE` | un `LOAN_IN` en el destino | base de `inventory` | — |

Y si la vecina no tiene, el préstamo termina en **`BACKORDERED`**: el *pendiente* de la historia, con aviso al cliente
y nada que compensar, porque nada se hizo.

**El orden no es cosmético.** El cobro va al final porque es lo que más cuesta deshacer: un reembolso toca la plata de
un cliente; liberar una reserva solo toca un número de la base. Con el cobro hecho, la saga deja de volver atrás y solo
va hacia adelante. La literatura lo llama la **transacción pivote**: antes de ella, todo se compensa; después, todo se
reintenta hasta que sale. Poner el paso caro al final es la decisión de diseño más barata de toda la fase.

> 💡 **Lo que la historia ya decía.** Las tres salidas de una saga son las tres que discutían los fundadores: liberar la
> reserva en la vecina, reembolsar, o dejar el pedido pendiente con aviso al cliente. El código no inventó ninguna.

### 5.3 G11: el orquestador, escrito a mano

El paso se generó con el prompt de G11 de [a03](a03-contratos-y-prompts-de-generacion.md#-los-prompts-de-g11) y pasó la
suite al primer intento. La pieza es `LoanSaga.java`, y lo que importa de ella cabe en tres ideas.

**El estado vive en la base, no en memoria.** Dos tablas nuevas: `loans`, con el préstamo y su estado, y `loan_steps`,
con una fila por cada paso hecho o deshecho. Si el pod muere, la saga no se pierde: queda escrita en qué paso iba.

```sql
-- schema-postgresql.sql (G11): una por cada paso hecho o deshecho
CREATE TABLE IF NOT EXISTS loan_steps (
    id      BIGINT  GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    loan_id BIGINT  NOT NULL,
    step    TEXT    NOT NULL,   -- RESERVE, DISPATCH, CHARGE, RECEIVE
    action  TEXT    NOT NULL,   -- DO o UNDO
    outcome TEXT    NOT NULL,   -- OK o FAILED
    detail  TEXT,
    at      TEXT    NOT NULL
);
```

**Un paso a la vez, según el estado.** La saga es una máquina de estados: lee el préstamo, hace el paso que toca, lo
anota y vuelve a leer.

```java
// LoanSaga.java: da pasos hasta que el préstamo termina o hay que esperar
void advance(long id) {
    boolean more = true;
    while (more) {
        Row loan = load(id);
        more = switch (loan.status()) {
            case "STARTED" -> reserve(loan);
            case "RESERVED" -> dispatch(loan);
            case "DISPATCHED" -> charge(loan);
            case "CHARGED" -> receive(loan);
            case "COMPENSATING" -> compensate(loan);
            default -> false;   // COMPLETED, COMPENSATED o BACKORDERED: terminado
        };
    }
}
```

**`POST /loans` no espera la saga.** Valida, guarda el préstamo en `STARTED`, arranca la saga en un hilo virtual con el
contexto de la traza envuelto —la lección del aviso de la [Fase 23](23-grpc-y-el-balanceo.md)— y contesta `202
Accepted`. Quien pidió el préstamo pregunta después con `GET /loans/{loanId}`.

### 5.4 El préstamo que sale bien

Desplegar G11 tuvo su tropiezo (sección 13); la suite, ninguno:

```text
$ task conformance TARGET=cluster PROFILE=lab -- G11
Success /suite/inventory.g11.hurl (22 request(s) in 2396 ms)
```

Por la puerta, un salbutamol de Girón a Chapinero:

```text
$ curl -s -X POST http://api.localhost:8080/inventory/loans -H "Content-Type: application/json" \
    -d '{"sku":"SKU-0003","originStore":"DRO-003","destinationStore":"DRO-007","quantity":1}'
HTTP/1.1 202 Accepted
{"id":"LOAN-000004",…,"status":"STARTED","saleId":null,"replenishmentOrderId":null,"failure":null,"steps":[]}

$ curl -s http://api.localhost:8080/inventory/loans/LOAN-000004
  "status": "COMPLETED",
  "saleId": "SALE-027150",
  "replenishmentOrderId": "RO-0031",
  "steps": [
    {"step": "RESERVE",  "action": "DO", "outcome": "OK", "detail": "MOV-028554 en DRO-003", "at": "…T03:57:30.835Z"},
    {"step": "DISPATCH", "action": "DO", "outcome": "OK", "detail": "RO-0031",               "at": "…T03:57:30.870Z"},
    {"step": "CHARGE",   "action": "DO", "outcome": "OK", "detail": "SALE-027150 por 12900", "at": "…T03:57:30.878Z"},
    {"step": "RECEIVE",  "action": "DO", "outcome": "OK", "detail": "MOV-028555 en DRO-007", "at": "…T03:57:30.882Z"}
  ]
```

Girón pasó de 499 a 498, Chapinero de 23 a 24, y el cliente pagó 12.900, el precio de Chapinero. En Tempo, la saga
entera es **una traza**: el `POST /loans` contesta a los 9,5 ms y la saga sigue debajo, como hija, hasta los 60 ms
(`task obs:trace`, recortada):

```text
37 spans ['inventory', 'pricing', 'replenish']
     0.0 ms      9.5 ms  inventory  SERVER  POST /loans
     9.6 ms      6.3 ms  inventory  INTERNAL saga DO RESERVE
    17.1 ms     32.2 ms  inventory  INTERNAL saga DO DISPATCH
    26.2 ms     18.6 ms  replenish  SERVER  POST
    49.9 ms      7.2 ms  inventory  INTERNAL saga DO CHARGE
    52.2 ms      0.6 ms  pricing    SERVER  lab.pricing.v1.Pricing/GetPrice
    57.6 ms      4.3 ms  inventory  INTERNAL saga DO RECEIVE
```

### 5.5 `replenish` caído: la primera compensación

El generador de caos de la [Fase 22](22-resiliencia-y-caos.md) se pone ahora entre `inventory` y `replenish`. G11
sumó un parámetro a su tarea, porque hasta aquí solo sabía interceptar a `catalog`:

```bash
task chaos:on TARGET=replenish          # REPLENISH_URL de inventory apunta al generador
task chaos:set -- errorPercent=100      # cada llamada a replenish, un 503
```

```text
  "status": "COMPENSATED",
  "failure": "replenish: 503 Service Unavailable: \"{\"error\":\"unavailable\",\"message\":\"caos: error inyectado\"}\"",
  "steps": [
    {"step": "RESERVE",  "action": "DO",   "outcome": "OK",     "detail": "MOV-028556 en DRO-003"},
    {"step": "DISPATCH", "action": "DO",   "outcome": "FAILED", "detail": "replenish: 503 Service Unavailable: …"},
    {"step": "RESERVE",  "action": "UNDO", "outcome": "OK",     "detail": "MOV-028557 en DRO-003"}
  ]
# LOAN-000005: COMPENSATED a los 355 ms
```

Y en la base, la compensación como hecho, no como borrado:

```text
  id   |  store  |    type    | quantity |  reason_code  |  reference
-------+---------+------------+----------+---------------+-------------
 28556 | DRO-003 | LOAN_OUT   |       -1 |               | LOAN-000005
 28557 | DRO-003 | ADJUSTMENT |        1 | LOAN_RELEASED | LOAN-000005
```

La existencia de Girón volvió a 498. Cualquiera que audite el stock ve qué pasó y por qué.

### 5.6 La compensación que también falla

Una compensación es otra llamada por la red, y puede fallar igual que el paso que deshace. Ocho préstamos hacia
`DRO-024`, que no tiene precio (el cobro falla siempre), con `replenish` fallando la mitad de las veces:

```text
$ task chaos:set -- errorPercent=50
+  0.2s LOAN-000018 COMPENSATED  RESERVE DO OK; DISPATCH DO FAILED; RESERVE UNDO OK
+  1.3s LOAN-000014 COMPENSATING RESERVE DO OK; DISPATCH DO OK; CHARGE DO FAILED; DISPATCH UNDO FAILED
+  1.3s LOAN-000017 COMPENSATED  RESERVE DO OK; DISPATCH DO OK; CHARGE DO FAILED; DISPATCH UNDO OK; RESERVE UNDO OK
  …
+ 34.6s LOAN-000014 COMPENSATED  RESERVE DO OK; DISPATCH DO OK; CHARGE DO FAILED; DISPATCH UNDO FAILED; DISPATCH UNDO OK; RESERVE UNDO OK
```

Uno falló al despachar y solo hubo que liberar; siete despacharon, y de esas siete cancelaciones fallaron cuatro. Esos
cuatro préstamos se quedaron en **`COMPENSATING` durante 33 segundos**, con la moto pedida y la unidad reservada. Ese es
el sistema a medio compensar que pedía la fase: no está roto ni sano, está **en camino**. La traza lo muestra con los
spans de `UNDO` debajo del préstamo:

```text
45 spans ['inventory', 'pricing', 'replenish']
     0.0 ms     11.4 ms  inventory  SERVER  POST /loans
    16.4 ms     16.5 ms  inventory  INTERNAL saga DO DISPATCH
    34.1 ms    575.8 ms  inventory  INTERNAL saga DO CHARGE
   614.2 ms     15.6 ms  inventory  INTERNAL saga UNDO DISPATCH
   629.8 ms      4.8 ms  inventory  INTERNAL saga UNDO RESERVE
```

### 5.7 El barrido, y el orquestador que muere

Lo que terminó esos cuatro préstamos fue el **barrido**: un método con `@Scheduled` que cada 30 s busca préstamos sin
estado final que nadie toca hace más de 30 s, y los retoma. Sin el cobro, los compensa; con el cobro hecho, los termina
(la regla del pivote). Es lo que hace que la saga sobreviva a la muerte de su orquestador.

La primera prueba no salió como se planeó. Con `replenish` demorado 1,5 s y un `kubectl delete pod` normal en medio del
despacho, el préstamo terminó **`COMPLETED`**: el `preStop` de 5 s de la [Fase 16](16-escalado-y-rollout.md) mantuvo
viva la JVM, y el hilo de la saga terminó adentro de esa ventana. El apagado limpio protege las sagas cortas; una más
larga que el plazo del pod se corta igual. Para simular una caída hace falta no dar tiempo:

```text
23:00:02 LOAN-000013 pedido
23:00:03 kubectl delete pod inventory-6fd949c487-f94bv --grace-period=0 --force
+0s (sin respuesta)
+7s DISPATCHED | RESERVE DO OK; DISPATCH DO OK
+37s COMPENSATING | RESERVE DO OK; DISPATCH DO OK
+38s COMPENSATED | RESERVE DO OK; DISPATCH DO OK; DISPATCH UNDO OK; RESERVE UNDO OK
    "failure": "sin terminar en DISPATCHED después de 30 s",
```

El pod murió con la moto ya pedida (RO-0039) y antes de cobrar. El pod nuevo, a los 37 s, la canceló y liberó la unidad.
En Tempo, eso es otra traza, que empieza en un span `saga sweep`: el préstamo tiene ahora dos trazas, la de quien lo
empezó y la de quien lo terminó.

**Con dos réplicas hay dos barridos**, y los dos pueden encontrar el mismo préstamo. Cada uno lo reclama con un
`UPDATE` condicionado a la hora que leyó; si no actualiza ninguna fila, la otra réplica ganó y lo deja. La sección 7
lo pone a prueba.

> 🩻 **Esto sí funciona igual.** El barrido es un `cron` que mira una tabla, como el script de la Braqui: lo nuevo no es
> el mecanismo sino lo que mira. El script buscaba archivos nuevos; el barrido busca trabajo a medias.

**Prueba de fuego.** `task conformance TARGET=cluster PROFILE=lab -- G11` pasa; y un préstamo con `replenish` en 503
termina `COMPENSATED` con un `LOAN_RELEASED` en la existencia del origen.

**El patrón a memorizar.** El estado de la saga se escribe antes de cada llamada y después de cada respuesta; cada
compensación es una operación de negocio con su rastro; y algo que no es el hilo que empezó la saga tiene que poder
terminarla.

---

## 🔁 6. Los otros tres: donde no es mecánico

**`replenish`** casi no cambió: G11 solo sembró el código `SAGA_COMPENSATION`, y la cancelación que usa la saga es la
de G1 (D33 la había adelantado justamente para esto). La regla de esa operación —solo en `PENDING`, 409 si la orden ya
salió— es la que pone el límite de la compensación: el día que la Braqui despache de verdad, una moto que salió no se
cancela, y la saga tiene que esperar o compensar de otra forma. El laboratorio no tiene motos que salgan, y lo declara.

Y destapó una deuda de G10: con las trazas encendidas, `replenish` escribe una advertencia en texto plano al arrancar,
`MetadataLookupWarning: received unexpected error = All promises were rejected`, que rompe la suite de G7. Es el
detector de recursos de Google de la instrumentación de Node, buscando un servidor de metadatos que aquí no existe. El
chart 0.24.0 deja solo los detectores locales (`OTEL_NODE_RESOURCE_DETECTORS`), y G7 vuelve a pasar.

**`pricing`** pone el precio del cobro, por el mismo camino que la venta: G11 extrajo de `SalesController` un
`priceFor(sku, store)` con el gRPC, los reintentos y el circuito de G9, para que la saga no tenga una segunda manera de
preguntar precios. **`catalog`** no participa: el préstamo sale de una existencia que ya está en la vecina.

---

## 🪞 7. Tu instinto de compose dice… y la apuesta

Tu instinto, en su mejor versión: *"si la llamada falló, no pasó nada"*. En la base de Contingencia es exactamente así,
y la sección 4.1 lo mostró. Cuando el paso falla del lado de un vecino, la saga compensa lo que hizo ella. Pero la saga
solo sabe lo que el vecino le contestó, y un timeout no es una respuesta.

> 🪞 **Apuesta antes de ejecutar** (escrita el 04/10/2026 a las 23:20). Con *Sogamoso con lluvia* en `replenish` (la
> mitad de las llamadas tarda 3 s y el 20 % falla) y 20 préstamos seguidos, ninguno queda sin estado final a los 90 s, y
> las órdenes huérfanas en `replenish` son **exactamente tantas** como los despachos que fallaron por timeout; ninguna sale
> de un 503.
> **Resultado:** ganada. 10 `COMPLETED`, 8 `COMPENSATED` por timeout y 2 por 503, todos terminados. Órdenes de Girón a
> Chía: 18, de las cuales 10 son de préstamos completos y **8 están en `PENDING` sin préstamo que las respalde**. Los dos
> préstamos con 503 no dejaron orden.

> 🪞 **Segunda apuesta** (misma hora). Dos réplicas de `inventory` y el orquestador muerto con cinco préstamos a medias:
> ningún préstamo se compensa dos veces.
> **Resultado:** ganada, con letra chica. Diez préstamos, las dos réplicas borradas con `--grace-period=0 --force` 0,7 s
> después: siete alcanzaron a terminar —el kubelet no las mató en el acto— y quedaron **tres** a medias, no cinco. Los
> barridos de los dos pods nuevos corrieron con 170 ms de diferencia y se los repartieron (uno tomó el 49 y el 51; el
> otro, el 50). Cada préstamo tiene un solo `LOAN_RELEASED`, y ningún `UNDO` aparece dos veces.

---

## 📏 8. La rotura: el timeout que dejó motos huérfanas

La fase no mide: rompe. Y la rotura no es la que uno esperaría. `replenish` no está caído, está **lento**: tres segundos
por respuesta, contra los dos que `inventory` espera (G9).

**El cambio exacto:**

```bash
task chaos:set -- errorPercent=0 latencyMs=3000 latencyPercent=100
```

**El síntoma**, en `inventory`: cada préstamo, compensado y con la existencia intacta.

```text
órdenes DRO-003→DRO-007: 7 (PENDING 4, CANCELLED 3)
{"store":"DRO-003","sku":"SKU-0003","quantity":498,"reorderThreshold":0}
# LOAN-000006: COMPENSATED a los 2153 ms
# LOAN-000007: COMPENSATED a los 2099 ms
# LOAN-000008: COMPENSATED a los 2125 ms
# LOAN-000009: COMPENSATED a los 2122 ms
# LOAN-000010: COMPENSATED a los 2131 ms
órdenes DRO-003→DRO-007: 12 (PENDING 9, CANCELLED 3)
{"store":"DRO-003","sku":"SKU-0003","quantity":498,"reorderThreshold":0}
```

**Y en `replenish`**, cinco órdenes nuevas en `PENDING` (y una sexta con el préstamo siguiente) que ningún préstamo
respalda. El generador lo confirma: recibió seis, las demoró y **las pasó todas** (`"delayed": 6, "forwarded": 6`). La
saga dejó de esperar a los 2 s, compensó, y un segundo después `replenish` creó la orden de una moto que va a salir a
recoger una unidad que Girón ya devolvió a su existencia.

**Lo que costó salir:** nada en el código de la saga lo detecta. El préstamo dice `COMPENSATED` con `replenishmentOrderId:
null`; la orden no tiene ninguna referencia al préstamo. Encontrarlas es cruzar dos bases a mano, por droguería, producto y
hora: la consulta de los huérfanos de Luz Marina, versión 2026.

**Por qué pasa:** un timeout no dice *"no pasó"*: dice *"no sé si pasó"*. La saga trató un "no sé" como un "no", y
compensó lo único que sabía compensar. Para cancelar la orden tendría que conocer su número, y el número venía en la
respuesta que no esperó. Hay dos salidas, y las dos son de la [Fase 26](26-idempotencia-y-outbox.md): que el pedido
lleve una clave que la saga conoce de antemano, para poder preguntar *"¿existe la orden de este préstamo?"* o
repetirlo sin duplicarlo; o que la saga, ante un "no sé", **reintente** en lugar de compensar, lo cual solo es seguro con
esa misma clave.

> ⚠️ **No es un problema del generador de caos.** Un `replenish` en quincena, una pausa de recolección de memoria de
> tres segundos o un nodo con la red saturada producen lo mismo. El 503 es la falla amable: el vecino contestó que no
> hizo nada.

---

## ⚰️ 9. Autopsia: el aviso de traslados, una saga sin compensaciones

**La decisión, con su mejor argumento.** En 2020, el Núcleo y los fundadores de la Braqui integraron el préstamo con la
moto por archivo: el lote escribe un `.txt`, un script lo recoge. El Siga no tuvo que exponer nada, la Braqui no tuvo que
abrir un puerto hacia el datacenter, y quedó listo en un par de semanas, en plena pandemia.

**Por qué era razonable.** Cada sistema siguió siendo dueño de lo suyo, y el archivo es el contrato más simple que
existe: cualquiera lo lee, cualquiera lo depura con un editor. Para cientos de traslados al día, sobra.

**Qué pasó después, con número.** Es una saga de dos pasos —descontar en el Siga, despachar en la Braqui— sin ninguna
compensación, y cada falla entre los dos pasos se vuelve un huérfano. En el laboratorio, con la carpeta sin permiso de
escritura, un préstamo de tres unidades quedó `DISPATCHED` en la base y en ningún archivo: Sogamoso perdió 3 unidades de
su existencia y nadie las está llevando a Tunja. La historia no tiene la cuenta, y eso es el dato: el Siga nunca se entera
de si el archivo se leyó (historia §1.9), así que nadie mide cuántos se pierden.

**Cuánto cuesta salir.** No es reescribir el script: es decidir **qué hacer cuando el segundo paso no ocurre**. Hoy la
respuesta es "nada, hasta que el lunes aparezca en la consulta". La saga de esta fase le da una respuesta por paso, a
cambio de dos tablas, un barrido y dos compensaciones escritas a mano: unas 370 líneas en `LoanSaga.java`.

**Qué pregunta lo habría cambiado.** No *"¿cómo le avisamos a la Braqui?"*, sino *"si la Braqui nunca se entera, ¿quién
devuelve la unidad, y cuándo?"*. Es la pregunta que convierte un aviso en una saga.

**Antes y después, con números:** el mismo préstamo con el segundo paso fallando.

| | El aviso por archivo (Contingencia) | La saga de G11 |
|---|---|---|
| El segundo paso falla en el acto | la unidad queda descontada; un log, y nada más | `COMPENSATED` en 355 ms, con la unidad devuelta y su `LOAN_RELEASED` |
| El orquestador muere a la mitad | — (el lote ya confirmó antes de escribir) | compensado por otro pod a los 37 s |
| El segundo paso tarda más que el plazo | — | **sigue mal**: 8 huérfanas en 20 préstamos (sección 8) |

La última fila es la honesta: la saga arregló lo que el archivo no compensaba, y descubrió un huérfano nuevo que el archivo
también tenía, solo que nadie lo veía.

---

## 📖 10. Traducción

| En el monolito o en compose | En el laboratorio | Lo que cambia |
|---|---|---|
| una transacción en una base (`register_loan`) | una saga: pasos locales y compensaciones | el `ROLLBACK` se vuelve código de negocio, y deja rastro |
| el `ROLLBACK` automático | `LOAN_RELEASED`, cancelar con `SAGA_COMPENSATION` | cada compensación puede fallar y hay que reintentarla |
| el lote que retoma lo pendiente | el barrido de `@Scheduled` sobre `loans` | dos réplicas, dos barridos: hay que reclamar cada fila |
| un error del procedimiento | `failure` y `steps` del préstamo | el estado intermedio (`COMPENSATING`) es visible y dura |

Y al revés: una saga sin vecinos, en una sola base, es una transacción que alguien partió sin necesidad. Las filas de la
nube —los motores de flujos de trabajo gestionados— están en [a05](a05-diccionarios.md#️-local--nube).

🌩️ En la nube, un servicio de flujos de trabajo guarda el estado de la saga y la reintenta por ti: el orquestador deja de
morir con tu pod. 🚧 Lo que no te da: las compensaciones, el orden de los pasos y qué hacer con un "no sé". Esas siguen
siendo tuyas.

---

## 🩺 11. Incidentes de esta fase

La fase no reserva incidentes. Sus roturas —el timeout que deja huérfanas, la compensación que falla, el orquestador
que muere— son de diseño y no se diagnostican con `kubectl`; vuelven en los ejercicios 15 a 20.

---

## ⚖️ 12. Veredicto honesto: cuándo NO usar esto

**Si los datos caben en una base, no hagas una saga.** El procedimiento de Contingencia es más corto, más rápido y más
correcto que G11: la base compensa gratis. La saga existe porque Paracelso decidió una base por servicio
([Fase 12](12-estado-y-almacenamiento.md)); si esa decisión no se tomó, esta fase sobra.

**La saga cuesta código, estado y tiempo.** Cuatro estados intermedios que el negocio puede ver, dos tablas, un barrido, y
370 líneas para un préstamo que en PL/pgSQL son 34. Y la consistencia deja de ser inmediata: durante 33 s, cuatro
préstamos tuvieron moto pedida y unidad reservada sin ir a ninguna parte (sección 5.6). *"Siempre llega"* sigue siendo
verdad; *"siempre llega ya"* dejó de serlo.

**Un timeout no se compensa sin una clave.** Mientras el paso remoto no tenga una forma de preguntar si ocurrió, la saga
va a dejar huérfanas en cada vecino lento: 8 de 20 con *Sogamoso con lluvia*. No la pongas en producción sin la
[Fase 26](26-idempotencia-y-outbox.md).

**Orquestar a mano tiene techo.** Para un préstamo de cuatro pasos, se lee de una sentada. Para diez flujos con
temporizadores y esperas de días, un motor de flujos de trabajo (gestionado, o instalado) paga su complejidad.

**Nada de esto lo resuelve Kubernetes.** El cluster reinició el orquestador, le dio una réplica de más y le cortó la
red cuando se le pidió. Qué hacer con un préstamo a medias lo decidió el código.

**La pregunta del curso, para esta fase:** el contenedor te dio un proceso con su base. El orquestador te dio un pod que
vuelve cuando muere, y un `preStop` que, sin pedirlo, terminó una saga. **Te tocó a ti** escribir cada compensación, guardar
el estado antes de cada paso, y decidir qué significa un timeout.

---

## ⚠️ 13. Errores comunes y diagnóstico

**El `task deploy` se queda 10 minutos y termina en `rolled back due to rollback-on-failure`.** Síntoma en el `Job` de
migración: `pull access denied, repository does not exist … docker.io/lab/inventory:g11`. Causa: la imagen nueva no
está en los nodos; `task images:load` toma el perfil como argumento (`task images:load -- lab`), no como variable, y con
`PROFILE=lab` buscó el cluster `minimo` (`ERROR: no nodes found for cluster "minimo"`). Comprobación: `docker exec
lab-worker crictl images | grep g11`. Salida: cargarla y volver a desplegar; `--rollback-on-failure` ya dejó la revisión
anterior funcionando.

**`conflict with "kubectl-set" … containers[name="inventory"].image`.** Un `kubectl set image` de una prueba anterior
quedó como dueño de ese campo ([Fase 13](13-helm-el-paquete.md)): `task deploy FORCE=true`.

**Un préstamo en `COMPENSATING` que no se mueve.** Mira el último paso: un `UNDO FAILED` espera al barrido, que lo
reintenta cada 30 s. Si falla siempre con 409, la orden ya no está en `PENDING`: esa compensación no va a pasar nunca, y
el préstamo necesita una persona (el ejercicio 20).

**El préstamo dice `COMPENSATED`, y en `replenish` hay una orden en `PENDING` que nadie pidió.** Es la sección 8: el
despacho tardó más que el timeout.

**`kubectl logs -l …` no muestra la línea del préstamo.** Con un selector, `kubectl` trae solo las últimas 10 líneas de
cada pod: `--tail=-1` ([a04](a04-kubectl-y-k9s.md#-qué-dice)).

---

## 📋 14. Checklist de validación

```text
[ ] task conformance TARGET=cluster PROFILE=lab -- G11, y siguen pasando G5, G7 y G8
[ ] un préstamo por la puerta termina COMPLETED, con los cuatro pasos y una sola traza en Tempo
[ ] con task chaos:on TARGET=replenish y errorPercent=100, COMPENSATED con LOAN_RELEASED en el origen
[ ] con latencyMs=3000, cuentas las órdenes huérfanas en replenish
[ ] con el pod borrado sin gracia a mitad de un préstamo, el barrido lo termina en menos de un minuto
[ ] task chaos:off y la cadena sin el generador
```

---

## 🧪 15. Ejercicios (24)

Un tercio es provocar y leer estados a medias: una saga se entiende viendo dónde se queda, no viendo cuando sale bien.

## 🟢 Fácil — pedir, mirar y compensar (1–7)

### 🟢 Ejercicio 1 — El préstamo del salbutamol
Pide por la puerta un préstamo de una unidad de `SKU-0003` de `DRO-003` a `DRO-007` y sigue su estado hasta el final.

**Criterio:** `GET /loans/{id}` dice `COMPLETED` con cuatro pasos `DO OK`, y la existencia de Girón bajó en uno.

<details><summary>Solución</summary>

El `POST` contesta 202 con `STARTED`; un segundo después, el `GET` muestra los cuatro pasos. Si contesta 404, la ruta de
`inventory` en la puerta no tiene el prefijo `/inventory` o el pod no está en `:g11`
(`kubectl -n apps get deploy inventory -o jsonpath='{..image}'`).
</details>

### 🟢 Ejercicio 2 — El pendiente
Pide 1.000 unidades del mismo producto a la misma vecina.

**Criterio:** `BACKORDERED`, un solo paso `RESERVE DO FAILED`, ningún `UNDO`, y en el log de `inventory` la línea que
avisa al cliente.

<details><summary>Solución</summary>

`kubectl -n apps logs deploy/inventory | grep pendiente`. No hay nada que compensar porque nada se hizo: el
`findForUpdate` vio que no alcanzaba y la transacción no escribió el movimiento.
</details>

### 🟢 Ejercicio 3 — Los dos movimientos
Con `replenish` en 503 (`task chaos:set -- errorPercent=100`), pide un préstamo y busca sus movimientos en la base.

**Criterio:** dos filas con la referencia del préstamo: `LOAN_OUT -1` y `ADJUSTMENT +1 LOAN_RELEASED`.

<details><summary>Solución</summary>

`kubectl -n data exec postgres-0 -- psql -U inventory -d inventory -c "SELECT type, quantity, reason_code FROM
stock_movements WHERE reference = 'LOAN-0000NN'"`. Que la suma de los dos sea cero es lo que hace que la existencia
cuadre sin haber borrado nada.
</details>

### 🟢 Ejercicio 4 — La traza de una saga
Encuentra el `trace_id` del préstamo del ejercicio 1 en el log de `inventory` y léelo con `task obs:trace`.

**Criterio:** una traza con spans de `inventory`, `replenish` y `pricing`, y los cuatro `saga DO`.

<details><summary>Solución</summary>

La línea `préstamo LOAN-…: 1 × SKU-0003 de …` lleva el `trace_id`. Si faltan spans, espera unos segundos: se exportan en
lotes. Si falta `replenish`, las trazas no están encendidas en él (`OTEL_SDK_DISABLED`).
</details>

### 🟢 Ejercicio 5 — La suite, contra compose
Corre `inventory.g11.hurl` contra compose (`task conformance -- G11`) con las imágenes `:g11`.

**Criterio:** `Success /suite/inventory.g11.hurl`.

<details><summary>Solución</summary>

En compose, `inventory` usa SQLite y `replenish` el suyo (G3: sin `DATABASE_URL`); la saga funciona igual porque el
estado está en `loans` y `loan_steps`, que existen en los dos esquemas. Si falla el paso del precio, `pricing` en compose
no tiene el precio de `DRO-023` hasta que la suite lo pone: corre la suite entera, no pedazos.
</details>

### 🟢 Ejercicio 6 — El patrimonio, otra vez
Repite la sección 4.1 en Contingencia: un `register_loan` que falla en el tercer paso.

**Criterio:** el error de llave foránea, y la existencia del origen igual antes y después.

<details><summary>Solución</summary>

`task legacy:up` y `docker compose -f compose/compose.yaml exec contingencia-db psql -U contingencia -d contingencia`.
Los dos primeros pasos se ejecutaron: el número de la secuencia de la orden se consumió (el siguiente préstamo no es el
2), y es el único rastro de que pasaron.
</details>

### 🟢 Ejercicio 7 — El estado intermedio
Con `task chaos:set -- latencyMs=1500 latencyPercent=100`, pide un préstamo y consulta su estado cada 200 ms.

**Criterio:** ves `RESERVED` (o `STARTED`) durante cerca de 1,5 s antes de `COMPLETED`.

<details><summary>Solución</summary>

Un bucle con `curl` y `sleep 0.2`. Ese segundo y medio es el préstamo "en camino": la unidad ya salió de Girón y el
cliente todavía no pagó. Ninguna consulta del stock de Girón lo distingue de una venta.
</details>

## 🟡 Intermedio — llevar el patrón a otro sitio (8–14)

### 🟡 Ejercicio 8 — El cobro que falla
Pide un préstamo hacia una droguería sin precio para ese producto, sin caos.

**Criterio:** `COMPENSATED` con `DISPATCH UNDO OK` y `RESERVE UNDO OK`, y la orden de `replenish` en `CANCELLED` con
`SAGA_COMPENSATION`.

<details><summary>Solución</summary>

`DRO-024` no tiene precios sembrados. El `CHARGE` falla con el `NOT_FOUND` de `pricing`, y la saga deshace en orden
inverso: primero cancela la moto, después libera. `GET /replenish/replenishment-orders/{id}` muestra
`cancelReasonCode`.
</details>

### 🟡 Ejercicio 9 — Compensaciones en orden inverso
En `loan_steps`, comprueba para el préstamo del ejercicio 8 que los `UNDO` van en el orden contrario a los `DO`.

**Criterio:** una consulta que devuelve `RESERVE DO`, `DISPATCH DO`, `CHARGE DO FAILED`, `DISPATCH UNDO`, `RESERVE UNDO`.

<details><summary>Solución</summary>

`SELECT step, action, outcome FROM loan_steps WHERE loan_id = NN ORDER BY id`. El orden inverso importa cuando un paso
depende del anterior: cancelar la moto antes de liberar evita que otro préstamo reserve una unidad que la moto todavía
podría llevarse.
</details>

### 🟡 Ejercicio 10 — El caos en `catalog`, y la saga ni se entera
Pon el generador entre `inventory` y `catalog` (`task chaos:on`) con `errorPercent=100` y pide un préstamo.

**Criterio:** el préstamo termina `COMPLETED`, mientras una venta falla con 503.

<details><summary>Solución</summary>

La saga no llama a `catalog`: el producto ya está en la existencia de la vecina. Es una decisión del diseño, y tiene su
costo: un producto descontinuado se puede prestar. El ejercicio 22 lo discute.
</details>

### 🟡 Ejercicio 11 — El barrido, más rápido
Cambia `lab.saga.stale-ms` y `lab.saga.sweep-ms` a 10 s (variables `LAB_SAGA_STALE_MS` y `LAB_SAGA_SWEEP_MS`) y repite la
caída de la sección 5.7.

**Criterio:** el préstamo se compensa en menos de 25 s desde el borrado.

<details><summary>Solución</summary>

Las dos variables en el `Deployment` de `inventory` (o en sus valores). Más rápido no es gratis: con 10 s, un despacho que
tarde 12 s por un vecino en quincena lo toma el barrido mientras el hilo original sigue vivo, y los dos trabajan el mismo
préstamo. El plazo tiene que ser mayor que el paso más largo.
</details>

### 🟡 Ejercicio 12 — `kubectl delete` sin forzar
Repite la caída con un `kubectl delete pod` normal y explica el resultado.

**Criterio:** el préstamo termina `COMPLETED` sin pasar por el barrido.

<details><summary>Solución</summary>

El `preStop` de 5 s y el apagado limpio de la [Fase 16](16-escalado-y-rollout.md) dejan vivo el proceso: la saga termina
adentro. Si el despacho tardara más que `terminationGracePeriodSeconds` (30 s), se cortaría igual.
</details>

### 🟡 Ejercicio 13 — Contar los préstamos por estado
Encuentra en `/metrics` de `inventory` cuántos préstamos terminaron en cada estado.

**Criterio:** `lab_loans_total{status="COMPLETED"}`, `…COMPENSATED…` y `…BACKORDERED…` con números que cuadran con lo que
pediste.

<details><summary>Solución</summary>

`kubectl -n apps exec deploy/replenish -- node -e "fetch('http://inventory:8080/metrics').then(r=>r.text()).then(t=>console.log(t.split('\n').filter(l=>l.startsWith('lab_loans')).join('\n')))"`.
Con varias réplicas, cada una cuenta los suyos; Prometheus los suma.
</details>

### 🟡 Ejercicio 14 — El préstamo en el `storefront`
Agrega a la página un botón "Pedir a una vecina" que haga `POST /inventory/loans` y muestre el estado final.

**Criterio:** el botón deja ver `COMPLETED` o `BACKORDERED` sin recargar.

<details><summary>Solución</summary>

La ruta de `inventory` ya acepta `POST` con `Content-Type` desde el navegador (G5). La página tiene que preguntar el
estado después del 202: es la primera vez que la interfaz no recibe el resultado en la respuesta, y hay que decidir qué
ver mientras tanto.
</details>

## 🟠 Difícil — diagnosticar (15–20)

### 🟠 Ejercicio 15 — Encontrar las huérfanas
Con la rotura de la sección 8, escribe la consulta que encuentra las órdenes de `replenish` que ningún préstamo respalda.
Predice antes cuántas vas a encontrar.

**Criterio:** la lista de órdenes huérfanas, igual a la cantidad de préstamos compensados por timeout.

**Rúbrica:** tiene que cruzar dos servicios (no hay una base que tenga las dos tablas): por la API o con dos consultas.
La única pista común es droguería, producto y hora, y eso es frágil: dos préstamos iguales en el mismo minuto no se
distinguen. Esa fragilidad es la razón de la [Fase 26](26-idempotencia-y-outbox.md).

### 🟠 Ejercicio 16 — ¿Timeout o 503?
Con *Sogamoso con lluvia*, separa los préstamos compensados según si el despacho falló por timeout o por 503, solo con lo
que dice `GET /loans/{id}`.

**Criterio:** la clasificación, y las órdenes huérfanas que corresponden a cada grupo.

**Rúbrica:** el `failure` dice `I/O error …` en un caso y `503 Service Unavailable` en el otro; los 503 no dejan orden.
Explica por qué el código trata igual dos cosas que no son iguales.

### 🟠 Ejercicio 17 — La traza partida en dos
Con el orquestador muerto a mitad de una saga, encuentra las dos trazas del mismo préstamo.

**Criterio:** dos `trace_id` para un `loanId`: la del `POST /loans` y la del `saga sweep`.

**Rúbrica:** el barrido no tiene la traza original (no la guarda la base). Propón cómo unirlas: guardar el `traceparent`
en `loans` y usarlo como enlace (*span link*) al retomar.

### 🟠 Ejercicio 18 — El préstamo que nadie retoma
Pon `LAB_SAGA_SWEEP_MS` en un valor enorme, mata el orquestador a mitad de una saga y describe el estado del sistema una
hora después.

**Criterio:** el préstamo en `DISPATCHED`, la unidad reservada y la orden pendiente; ninguna alarma.

**Rúbrica:** es el aviso por archivo otra vez: un paso hecho y otro no, y nadie se entera. Propón la métrica que lo
alarmaría (préstamos sin estado final con más de N minutos).

### 🟠 Ejercicio 19 — La carrera de los barridos
Con dos réplicas, pon el plazo del barrido en 1 s y quita el `AND updated_at = ?` del `UPDATE` que reclama. Predice qué
pasa con cinco préstamos a medias.

**Criterio:** algún préstamo con dos `LOAN_RELEASED`, y la existencia del origen por encima de lo que debería.

**Rúbrica:** dos barridos toman el mismo préstamo y los dos lo compensan; liberar dos veces regala una unidad. El `UPDATE`
condicionado es un bloqueo optimista; un `SELECT … FOR UPDATE SKIP LOCKED` sería otra forma. Vuelve a poner la condición.

### 🟠 Ejercicio 20 — La compensación imposible
Marca a mano como `DISPATCHED` en `replenish` la orden de un préstamo que va a fallar en el cobro, y mira qué hace la saga.

**Criterio:** el préstamo en `COMPENSATING` para siempre, con un `DISPATCH UNDO FAILED` (409) cada 30 s.

**Rúbrica:** una moto que salió no se cancela. La saga tiene que distinguir un fallo que se reintenta (503) de uno que no
(409), y para el segundo, otra salida: un estado que pida a una persona, o una compensación distinta (que el destino
reciba igual y la devolución sea otro préstamo).

## 🔴 Muy difícil — diseñar (21–24)

### 🔴 Ejercicio 21 — Reintentar en vez de compensar
Cambia el despacho para que, ante un timeout, reintente hasta tres veces antes de compensar. Mide con *Sogamoso con
lluvia* cuántas huérfanas y cuántas órdenes duplicadas quedan.

**Criterio:** la tabla antes y después: préstamos completos, compensados, huérfanas y duplicadas.

**Rúbrica:** menos compensaciones y menos huérfanas, y aparecen **duplicadas**: el primer intento llegó tarde y el segundo
también. Sin una clave de idempotencia, reintentar cambia un problema por otro. Es el puente a la [Fase 26](26-idempotencia-y-outbox.md).

### 🔴 Ejercicio 22 — ¿Y si el producto está descontinuado?
Agrega a la saga un paso de validación con `catalog` y decide dónde va y si necesita compensación.

**Criterio:** la suite de G11 sigue pasando, y un préstamo de un producto descontinuado termina en un estado que el
contrato define.

**Rúbrica:** una lectura no necesita compensación y va primero, antes de reservar. Cambia el contrato antes que el código
(estado nuevo o `BACKORDERED` con motivo), y la suite con un caso nuevo.

### 🔴 Ejercicio 23 — El reembolso
Agrega un paso después del cobro que pueda fallar (por ejemplo, confirmar la entrega con `replenish`), y escribe su
compensación: el reembolso.

**Criterio:** con la confirmación fallando, el préstamo termina `COMPENSATED` con un reembolso registrado y la venta del
destino neteada.

**Rúbrica:** el pivote se mueve: el cobro deja de ser el último paso, y la regla del barrido cambia. El reembolso es un
hecho nuevo (una fila con monto negativo o una tabla de reembolsos), nunca un `DELETE` de la venta. Y la pregunta de
negocio: ¿se reembolsa o se reintenta la entrega?

### 🔴 Ejercicio 24 — La recomendación para Andrés
En una página: ¿el préstamo de La Vecina debe salir del Siga como saga orquestada, o quedarse como procedimiento?

**Criterio:** una página, con la sección 4, la apuesta de la sección 7 y la rotura de la sección 8 como evidencia.

**Rúbrica:** lo que gana (las bases separadas, el despliegue de un martes), lo que cuesta (código, estados visibles,
consistencia que tarda) y lo que todavía falta (la clave de la [Fase 26](26-idempotencia-y-outbox.md)). Y la respuesta a *"¿quién se acuerda de
devolver?"*: el registro de la saga y el barrido, no la base.

---

## 📚 16. Referencias

**Documentación oficial** (las versiones de [a01](a01-el-laboratorio.md))

- Kubernetes, *Pod Lifecycle — Termination of Pods*: https://kubernetes.io/docs/concepts/workloads/pods/pod-lifecycle/
  (por qué un `delete` normal dio tiempo de terminar la saga).
- Kubernetes, *Force Delete StatefulSet Pods*: https://kubernetes.io/docs/tasks/run-application/force-delete-stateful-set-pod/
  (lo que el borrado forzado no garantiza).
- Spring Framework, *Task Execution and Scheduling*: https://docs.spring.io/spring-framework/reference/integration/scheduling.html
- OpenTelemetry, *Java API* (spans manuales): https://opentelemetry.io/docs/languages/java/api/
- PostgreSQL, *Transaction Management* en PL/pgSQL: https://www.postgresql.org/docs/current/plpgsql-transactions.html

**Patrones, artículos y libros**

- Hector Garcia-Molina y Kenneth Salem, *Sagas* (SIGMOD, 1987): https://www.cs.cornell.edu/andru/cs711/2002fa/reading/sagas.pdf
  — el artículo de donde sale el término; ocho páginas.
- Chris Richardson, *Microservices Patterns*, Manning, 2018, capítulo 4 (sagas, orquestación y coreografía), y su
  resumen en https://microservices.io/patterns/data/saga.html.
- Microsoft, *Saga design pattern*: https://learn.microsoft.com/en-us/azure/architecture/patterns/saga y
  *Compensating Transaction pattern*: https://learn.microsoft.com/en-us/azure/architecture/patterns/compensating-transaction
  — el segundo trata justamente la compensación que falla.
- Sam Newman, *Building Microservices*, 2.ª edición, O'Reilly, 2021, capítulo 6 (*Workflow*).
- Pat Helland, *Life beyond Distributed Transactions: An Apostate's Opinion*, ACM Queue, 2016: por qué las aplicaciones
  grandes dejan de confiar en transacciones distribuidas.

**Orden de lectura sugerido:** antes, el resumen de microservices.io; durante, el capítulo 4 de Richardson con la
sección 5.2 delante; después, el artículo de 1987 y el de Helland, para ver que el problema es más viejo que los
contenedores.

> ⚠️ Las URL y los contenidos cambian.

---

## 🏁 17. Resultado de la fase

```text
EL ESTADO AL CERRAR LA FASE 24 (cluster lab, valores de minimo)

  apps          inventory:g11 (LoanSaga: POST /loans y GET /loans/{id}, tablas loans y loan_steps, el
                barrido cada 30 s), replenish:g11 (SAGA_COMPENSATION); los demás en :g10, storefront :g5
  chart 0.24.0  OTEL_NODE_RESOURCE_DETECTORS en replenish; global.chaos.target elegible
  tareas        task chaos:on TARGET=replenish
  contratos     inventory.yaml con el préstamo completo; inventory.g11.hurl
```

> **La señal de que quedó bien:** *"Ante un paso que falló, sé qué se deshace y en qué orden; ante un timeout, sé que
> no sé; y si el orquestador se cae, sé quién termina lo que dejó."*

> 🏷️ **No cierres la fase sin el tag.** Con el checklist en verde, las suites pasando y `git status` limpio:
>
> ```bash
> git tag -a fase-24-la-saga-orquestada -m "F24 cerrada: G11, el préstamo como saga orquestada en inventory (reservar, despachar, cobrar) con compensaciones de negocio y estado en la base; el barrido que retoma sagas a medias; el timeout que deja órdenes huérfanas, medido"
> ```
>
> Commits con prefijo `f24:`.

---

## 📌 Pendientes sugeridos

- **F25:** el aviso a `replenish` como evento, y la saga contada otra vez por coreografía para compararlas.
- **F26:** la clave de idempotencia del despacho, que cierra la rotura de la sección 8 y los ejercicios 15 y 21.
- **`a16`:** nombrar el lote de traslados como "la saga sin compensaciones" en el apéndice del patrimonio.
- **El `traceparent` en `loans`**, para que el barrido enlace su traza con la original (ejercicio 17): candidato a G13.
