# El generador de caos (Fase 22): el mismo molde que pricing, sin dependencias.

# golang:1.27.1-alpine
FROM golang@sha256:8a5910f31396cd4d89662f56c68b3ae31d374308270a1c3bd96672ee5ed43414 AS build
WORKDIR /src
COPY go.mod main.go ./
RUN CGO_ENABLED=0 go build -trimpath -ldflags="-s -w" -o /out/chaos .

# gcr.io/distroless/static-debian13:nonroot — sin shell; usuario 65532.
FROM gcr.io/distroless/static-debian13@sha256:e2e927ec666bae08560abb3c55d0659eceabb657f56b6782ab500a9fc7f555e3
COPY --from=build /out/chaos /chaos
EXPOSE 8080
CMD ["/chaos"]
