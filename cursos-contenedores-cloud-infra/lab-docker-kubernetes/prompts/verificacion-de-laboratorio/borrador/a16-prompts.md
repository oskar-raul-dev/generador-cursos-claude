# Prompts del patrimonio (borrador de T1b; la versión que funcionó se publica en a16)

## Prompt P-1 · Contingencia

Genera **Contingencia**, la versión reducida del Siga que opera en un solo sitio, en
`src/lab/legacy/contingencia/`. Es código heredado de 2016: se escribe como lo habría escrito un
equipo Java EE de entonces, sin modernizarlo, y con identificadores en inglés y comentarios en
español.

**Stack.** Jakarta EE 11 sobre Eclipse GlassFish (imagen oficial, versión de a01), JPA con
**Hibernate** como proveedor (empaquetado en el WAR), y PostgreSQL. Maven, un solo módulo,
`packaging war`, Java 21 (el JDK de la imagen de GlassFish). La API de Jakarta EE va `provided`, y
también la de JAX-WS (`jakarta.xml.ws-api`), que Jakarta EE 11 dejó como opcional y GlassFish sigue
trayendo. Nada de construcciones posteriores a 2016 en el código: ni `record`, ni `var`.

**Hibernate dentro de GlassFish**, dos cosas que hay que hacer explícitas: las entidades se listan una
por una en `persistence.xml` (con `exclude-unlisted-classes`), porque dentro del WAR desplegado
Hibernate no las descubre; y la plataforma de transacciones es una clase propia de unas quince líneas
que extiende `AbstractJtaPlatform` y busca `java:appserver/TransactionManager` y
`java:comp/UserTransaction`, porque Hibernate 7 ya no trae la de GlassFish.

**Datos.** El esquema y los datos iniciales viven en `db/` como SQL que corre la imagen de Postgres
al crearse (`docker-entrypoint-initdb.d`); Hibernate no crea tablas (`hibernate.hbm2ddl.auto=none`).
Tablas, con los nombres del contrato del curso: `store`, `product` (con `category`), `price`
(precio vigente por producto y droguería), `stock_level` (cantidad y umbral), `stock_movement`
(`SALE`, `LOAN_OUT`, `LOAN_IN`), `replenishment_order` (el préstamo: origen y destino son
droguerías; estados `PENDING`, `DISPATCHED`), `dispatch` (domicilios esperando moto: `PENDING`,
`ASSIGNED`), y las dos de la Braqui que viven en esta misma base desde que es módulo del Siga:
`rider` y `braqui_transfer`, más `transfer_file_processed`. Datos iniciales: ocho droguerías de
Santander, Boyacá y Bogotá, ocho productos de droguería con precio en pesos, existencias para todos,
cuatro motos y tres domicilios pendientes.

**El procedimiento del préstamo, en PL/pgSQL:** `register_loan(sku, origin_store, destination_store,
quantity)` comprueba existencias en el origen, descuenta en el origen (`LOAN_OUT`), crea la
`replenishment_order` en `PENDING` y devuelve su id. No suma en el destino: eso pasa cuando llega la
moto, y nadie lo modela todavía. Es la traducción a mano del PL/SQL del central.

**Dos servicios SOAP (JAX-WS, `@WebService` sobre `@Stateless`):** GlassFish los publica en la raíz
del servidor, en `/PriceService/PriceService` y `/StockService/StockService`, no bajo el contexto
del WAR.
- `PriceService`: `getPrice(sku, storeId)` devuelve el precio vigente en COP; `listCatalog()`
  devuelve sku, nombre, categoría y precio de referencia de todos los productos.
- `StockService`: `getStock(sku, storeId)`, `registerSale(sku, storeId, quantity, deliveryAddress)`
  (descuenta, registra `SALE` y, si hay dirección, crea un `dispatch` pendiente) y
  `requestLoan(sku, originStore, destinationStore, quantity)`, que llama a `register_loan`.

Los dos exigen **HTTP Basic** contra un usuario y una contraseña que llegan por variables de entorno
(`SOAP_USER`, `SOAP_PASSWORD`), revisado en un `SOAPHandler` declarado con `@HandlerChain` (un filtro
de servlet no ve los endpoints EJB). Sin credenciales responde un fault `Client` con el texto
`No autorizado`.

**El lote de traslados**, un `@Singleton @Startup` con `TimerService` cada `TRANSFER_BATCH_MINUTES`
minutos (15 por defecto): en una transacción propia toma los préstamos `PENDING`, los pasa a
`DISPATCHED` **y confirma**; **después** escribe `traslados_AAAAMMDD_HHMM.txt` en `TRANSFER_DIR`, una
línea por préstamo con los campos `id|sku|origen|destino|cantidad|fecha` separados por barra
vertical, y al final un archivo vacío con el mismo nombre y extensión `.ok`. El orden —confirmar y
después escribir— es el de la historia, y no se corrige.

**La regla de encendido.** Un `GET /contingencia/status` (servlet, JSON) responde el modo:
Contingencia está `ACTIVE` cuando no puede **abrir una conexión** con `SIGA_CENTRAL_URL` (cinco
segundos para conectar), y `STANDBY` cuando la abre, aunque el central tarde un minuto en contestar
después. Sin `SIGA_CENTRAL_URL`, siempre `ACTIVE`.

**Configuración del servidor.** El pool JDBC `jdbc/contingencia` se crea al arrancar con
`custom/init.sh` de la imagen de GlassFish (que la imagen corre antes de levantar el dominio): un
archivo de comandos de `asadmin` con `start-domain`, `create-jdbc-connection-pool`,
`create-jdbc-resource` y `stop-domain`, armado con `DB_HOST`, `DB_NAME`, `DB_USER` y `DB_PASSWORD`, que no
hace nada si el pool ya existe. El driver de Postgres va en `glassfish/lib` de la imagen, bajado con
`ADD --checksum`. El WAR se copia a `/deploy`.

**Dockerfile** multi-stage: Maven con Temurin 21 para construir, la imagen de GlassFish para correr,
las dos por digest con el tag en un comentario.

**No hagas:** pruebas, logs estructurados, sondas de salud, métricas ni manejo de señales. Nada de lo
que el curso enseña. Es el sistema como está.

## Prompt P-2 · El portal

Genera **el portal** (PPVW) en `src/lab/legacy/portal/`, como lo habrían hecho en 2019 unos
aprendices con una pasante y un trimestre de plazo: un proyecto Laravel creado con `composer
create-project` y `artisan`, sin pruebas propias, con identificadores en inglés y comentarios en
español.

**Datos:** SQLite en `database/database.sqlite`, con una tabla `products` (sku, nombre, categoría,
precio, `synced_at`) creada por migración.

**El catálogo:** `GET /` muestra el catálogo en una tabla HTML (Blade), con la hora de la última
sincronización. Es lo único que el laboratorio necesita del portal.

**La sincronización nocturna:** un comando `catalog:sync` que llama a `listCatalog` del
`PriceService` de Contingencia con `SoapClient` (extensión `soap`) y HTTP Basic, y reemplaza la tabla.
Se programa en el scheduler de Laravel todos los días a las 2:00; en el laboratorio se corre a mano o
con `schedule:work`.

**Configuración:** el `.env` **se versiona** con el `APP_KEY` y las credenciales SOAP de
Contingencia en texto plano, como lo dejaron (es una maña de la historia y no se corrige aquí).

**Ejecución:** `php artisan serve` en el puerto 8080, en un solo contenedor, con `php` (CLI, la
versión de a01) más la extensión `soap` (que en Alpine se compila con `$PHPIZE_DEPS`). Dockerfile con
`composer` por digest para instalar, y el `.env` viaja dentro de la imagen porque nadie puso un
`.dockerignore` para él. La zona horaria de la aplicación es `America/Bogota`.

**Limpieza del esqueleto:** el proyecto de hoy trae archivos que un portal de 2019 no tenía (pruebas
de ejemplo, Vite, `README.md`, archivos para asistentes de código); se borran.

**No hagas:** pruebas, colas, autenticación de usuarios, nada de lo que el curso enseña.

## Prompt P-3 · La Braqui

Genera **la Braqui** en `src/lab/legacy/braqui/`, en dos piezas que viven en la misma carpeta.

**El despachador (Node, la versión de a01):** un proceso que **cada 30 segundos** consulta la tabla
`dispatch` de la base de Contingencia (`DATABASE_URL`, con el cliente `pg`) buscando los `PENDING`,
asigna a cada uno la moto libre con menos asignaciones de la tabla `rider`, y lo pasa a `ASSIGNED`
con el id de la moto. Escribe una línea de texto por asignación. Expone `GET /dispatches` (JSON con
los últimos veinte) en el puerto 8080, con `node:http`, sin framework. Lee tablas que no son suyas a
propósito: así quedó en 2023.

**El aviso de traslados (Python, la versión de a01):** `transfers/process_transfers.py`, que corre
cada cinco minutos con `cron` (busybox `crond` en un contenedor `python` alpine) y hace exactamente lo
que hace el de la historia, con sus tres parches:
1. toma un archivo de bloqueo; si ya existe, sale sin hacer nada y sin error;
2. lista `traslados_*.txt` en `TRANSFER_DIR` en orden de nombre, y procesa un `.txt` solo si ya existe
   su `.ok`;
3. salta los nombres que ya están en `transfer_file_processed`;
4. inserta cada línea en `braqui_transfer`, registra el nombre del archivo en
   `transfer_file_processed` y lo mueve a `procesados/`;
5. borra el bloqueo.
Dependencias en `transfers/requirements.txt` (`psycopg[binary]`), instaladas en un `venv` dentro de
la imagen. El `crond` de busybox no hereda el entorno del contenedor: un `start.sh` escribe el
crontab con las variables en la misma línea. La imagen lleva `tzdata`, o `TZ` no tiene efecto.

**No hagas:** reintentos, idempotencia por contenido, avisos al Siga, compensaciones ni métricas. Las
fallas que esconden los parches son el material de las Fases 12, 24, 25 y 26.
