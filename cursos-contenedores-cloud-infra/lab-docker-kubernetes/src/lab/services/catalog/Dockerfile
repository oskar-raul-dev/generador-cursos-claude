# Dockerfile definitivo de catalog (Fase 04): PHP-FPM con la aplicación. nginx es otro contenedor,
# con la imagen oficial sin privilegios y el nginx.conf de esta carpeta (compose.yaml y la Fase 09).

# ── Etapa de build: Composer sobre la misma PHP que corre después ──
# php:8.5-fpm-alpine (PHP 8.5.11)
FROM php@sha256:fa01fb1645cd0fc566a5f146b099adace33b906571f972f71f2182a7c12d1cd7 AS build
# composer:2.10.3
COPY --from=composer@sha256:af98f42dfff7c68ba8d53c2164fd9fde1087b7d449514baa38c418b1f6bc4bac /usr/bin/composer /usr/bin/composer
# G10: la extensión de OpenTelemetry también aquí: el paquete de Laravel se niega a registrarse sin ella, y Composer
# lo registra al armar el autoload. Se compila dos veces (aquí y en la final): es el costo de PHP.
RUN apk add --no-cache --virtual .build-deps $PHPIZE_DEPS \
 && pecl install opentelemetry-1.4.2 && docker-php-ext-enable opentelemetry \
 && apk del .build-deps
WORKDIR /app
# Primero el lock: las dependencias quedan en su capa mientras composer.lock no cambie.
COPY composer.json composer.lock ./
RUN composer install --no-dev --no-interaction --prefer-dist --no-scripts --no-autoloader
COPY . .
RUN composer dump-autoload --no-dev --optimize --classmap-authoritative

# ── Etapa final: PHP-FPM y el código, sin Composer ──
# php:8.5-fpm-alpine (PHP 8.5.11)
FROM php@sha256:fa01fb1645cd0fc566a5f146b099adace33b906571f972f71f2182a7c12d1cd7
# G3: la extensión de Postgres. Se compila con las cabeceras de libpq, que se borran después; queda
# solo la biblioteca que la extensión necesita para correr.
# G6: APCu, la memoria compartida entre los hijos de FPM donde viven los contadores de /metrics. No viene
# con PHP: se compila desde PECL, con la versión fijada. G10: la extensión de OpenTelemetry, también desde PECL:
# es la que deja que la instrumentación de Laravel se enganche a las funciones sin tocar el código.
RUN apk add --no-cache --virtual .build-deps $PHPIZE_DEPS postgresql-dev \
 && docker-php-ext-install pdo_pgsql \
 && pecl install apcu-5.1.28 && docker-php-ext-enable apcu \
 && pecl install opentelemetry-1.4.2 && docker-php-ext-enable opentelemetry \
 && apk del .build-deps && apk add --no-cache libpq
WORKDIR /app
COPY --from=build --chown=www-data:www-data /app /app
# Sin archivo .env: la configuración entra por variables (clear_env = no en la imagen base).
ENV APP_ENV=production \
    APP_DEBUG=false \
    LOG_CHANNEL=stderr \
    LOG_STDERR_FORMATTER=App\\Logging\\JsonLineFormatter \
    CACHE_STORE=array \
    SESSION_DRIVER=array \
    QUEUE_CONNECTION=sync \
    DB_CONNECTION=sqlite
# FPM escucha solo en localhost: el único que le habla es el nginx que comparte su red.
# G7: FPM no escribe su línea de acceso (la de la petición la escribe Laravel, en JSON) ni sus avisos de
# arranque; lo que sí escribe, sus errores, sigue siendo texto: FPM no tiene formato JSON.
RUN printf '[global]\nlog_level = warning\n[www]\nlisten = 127.0.0.1:9000\naccess.log = /dev/null\n' > /usr/local/etc/php-fpm.d/zz-lab.conf \
    && mkdir -p /var/lib/catalog && chown www-data:www-data /var/lib/catalog
USER www-data
# El arranque (con SQLite, aplica el esquema) termina con exec php-fpm, que queda como proceso 1.
CMD ["sh", "/app/start.sh"]
