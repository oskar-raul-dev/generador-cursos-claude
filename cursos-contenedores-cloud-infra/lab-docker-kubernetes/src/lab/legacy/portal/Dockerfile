# composer:2.10.3
FROM composer@sha256:af98f42dfff7c68ba8d53c2164fd9fde1087b7d449514baa38c418b1f6bc4bac AS vendor
WORKDIR /app
COPY composer.json composer.lock ./
RUN composer install --no-dev --no-scripts --no-autoloader --prefer-dist --no-interaction
COPY . .
RUN composer dump-autoload --optimize --no-dev

# php:8.5.11-cli-alpine
FROM php@sha256:93684051146ec037620855feb77f278090bde45ddc030801cd3f2a7685bc4deb
# SOAP para hablar con Contingencia; SQLite ya viene en la imagen.
RUN apk add --no-cache --virtual .build-deps $PHPIZE_DEPS libxml2-dev \
 && docker-php-ext-install soap \
 && apk del .build-deps && apk add --no-cache libxml2
WORKDIR /app
COPY --from=vendor /app /app
# El servidor de desarrollo de artisan: así corre el portal en el laboratorio (a16).
CMD ["sh", "-c", "touch database/database.sqlite && php artisan migrate --force && php artisan serve --host=0.0.0.0 --port=8080"]
