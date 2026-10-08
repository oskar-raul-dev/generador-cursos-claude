# Go del corpus: pgx v5, con el modulo ya descargado en la imagen.
# Versiones verificadas: ver `prompts/dominio-entorno-y-datos-fijos.md` §4.6.
FROM golang:1.27.1
WORKDIR /opt/modulo
RUN go mod init tienda && go get github.com/jackc/pgx/v5@v5.11.0 github.com/jackc/pgx/v5/pgxpool@v5.11.0 \
    github.com/jackc/pgx/v5/stdlib@v5.11.0 gorm.io/gorm@v1.31.2 gorm.io/driver/postgres@v1.6.3 \
    github.com/redis/go-redis/v9@v9.22.0 go.mongodb.org/mongo-driver/v2/mongo@v2.9.1 \
    github.com/testcontainers/testcontainers-go@v0.44.0 \
    github.com/testcontainers/testcontainers-go/modules/postgres@v0.44.0 modernc.org/sqlite@v1.59.0
# sqlc genera codigo Go a partir de consultas SQL: es una herramienta, no una dependencia
RUN go install github.com/sqlc-dev/sqlc/cmd/sqlc@v1.31.1
# El codigo del lector se monta en /opt/modulo/codigo: dentro del modulo, asi que
# `go run` encuentra el go.mod subiendo un directorio.
WORKDIR /opt/modulo/codigo
