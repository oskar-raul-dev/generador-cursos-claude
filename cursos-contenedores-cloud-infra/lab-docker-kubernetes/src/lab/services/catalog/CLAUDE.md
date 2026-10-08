# catalog

El maestro de productos y categorías. Sale del portal (`../../legacy/portal/`), que tiene su catálogo
propio, pero no hereda nada de él: ni su `.env`, ni su base, ni su forma de sincronizar.

## Stack

- PHP (la versión de `a01`) con Laravel 13. Las rutas viven en `routes/api.php`, en el grupo `api`
  y sin prefijo (`apiPrefix: ''`).
- **Sin base de datos ni sesiones en G0**: caché y sesión en `array`, logs a `stderr`, y ningún `.env`.
- Imagen: `lab/catalog`, multi-stage desde la Fase 04: Composer en la etapa de build y **PHP-FPM**
  en la final, como `www-data`, escuchando FastCGI solo en `127.0.0.1:9000`. **nginx es otro
  contenedor** (la imagen oficial sin privilegios con `nginx.conf` de esta carpeta) que comparte la
  red y atiende el 8080: en compose, `catalog-nginx`; en el cluster, el segundo contenedor del pod.

## Comandos

```bash
task build -- catalog                 # construye la imagen con el motor activo
task compose:up                       # el sistema en compose
task conformance -- G1                # la suite del paso; tiene que pasar
```

## Convenciones

- Identificadores en inglés, comentarios en español con tildes.
- Desde G7, una línea JSON por evento a stdout (`time`, `level`, `service`, `msg`); la de cada petición,
  con `method`, `uri`, `path`, `status`, `duration_ms` y `request_id` (de `X-Request-Id`).
- El log por petición está en `app/Http/Middleware/LogRequest.php`.
- Lo que no existe cae en `Route::fallback`, que responde `{"error":"not_found"}` con 404.
- El contrato manda: `../../contracts/openapi/catalog.yaml`. Se cambia el contrato y la suite antes
  que el código.

## El contrato, paso a paso

| Paso | Qué | Estado |
|---|---|---|
| G0 | `/health/live`, `/health/ready` triviales; `GET /products` con lista fija | ✅ hecho |
| G1 | almacén propio (SQLite), en `DATA_DIR`, `GET /products/{sku}`, `POST /products`, `PATCH /products/{sku}` (descontinuar exige `reasonCode`), `GET /products?status=`, `GET /categories`, `GET /reason-codes` (tabla sembrada) | ✅ hecho |
| G3 | Postgres por `DATABASE_URL` (conexión `pgsql`, extensión `pdo_pgsql` en la imagen; sin ella, el SQLite de G1), `php artisan migrate --force` para el `Job`; `start.sh` migra solo con SQLite | ✅ hecho |
| G4 | readiness real: `/health/ready` hace `select 1` y responde 503 `{"status":"not_ready"}` si la base no contesta; llega por nginx y FPM, así que también prueba los dos procesos; `PDO::ATTR_TIMEOUT` de 2 s en `pgsql` | ✅ hecho |
| G5 | `inventory` le consulta productos (el mismo `GET /products/{sku}` de G1); apagado limpio: la imagen hereda `STOPSIGNAL SIGQUIT`, que PHP-FPM y nginx atienden terminando lo que tienen | ✅ hecho |
| G6 | `/metrics` con `promphp/prometheus_client_php` y **APCu** (extensión de PECL, en el Dockerfile): los contadores viven en la memoria compartida de los hijos de FPM, porque nada sobrevive a una petición. El middleware `MeasureRequest` toma `route()->uri()`; la ruta de reserva, `uri="/**"`. `METRICS_STORAGE=memory` deja el almacenamiento del proceso, solo para medir lo que se pierde (Fase 17) | ✅ hecho |
| G7 | Monolog con `App\Logging\JsonLineFormatter` (`LOG_STDERR_FORMATTER`); FPM sin línea de acceso y con `log_level = warning`; nginx con su línea de acceso en JSON (`nginx.conf`) y un `nginx-main.conf` con los errores desde `warn`, más `NGINX_ENTRYPOINT_QUIET_LOGS=1` | ✅ hecho |
| G10 | la extensión `opentelemetry` de PECL y `opentelemetry-auto-laravel`, con `OTEL_PHP_AUTOLOAD_ENABLED` | ✅ hecho |

**No agregues nada de un paso pendiente**, aunque sea fácil o el framework lo traiga de serie: una
capacidad antes de su fase invalida el paso.
