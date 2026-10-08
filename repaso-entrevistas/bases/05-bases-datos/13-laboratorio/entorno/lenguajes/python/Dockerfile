# Python del corpus: psycopg 3 y su pool, en version exacta.
# Versiones verificadas: ver `prompts/dominio-entorno-y-datos-fijos.md` §4.6.
FROM python:3.14.7
RUN pip install --no-cache-dir "psycopg[binary]==3.3.6" "psycopg-pool==3.3.3" \
    "sqlalchemy==2.0.54" "redis==8.1.0" "pymongo==4.18.2" \
    "testcontainers==4.15.0"
WORKDIR /codigo
