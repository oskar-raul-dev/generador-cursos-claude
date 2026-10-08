# Dockerfile definitivo de pricing (Fase 04): compila en una etapa y corre en otra.

# ── Etapa de build: el compilador de Go, que no viaja a la imagen final ──
# golang:1.27.1-alpine
FROM golang@sha256:8a5910f31396cd4d89662f56c68b3ae31d374308270a1c3bd96672ee5ed43414 AS build
WORKDIR /src
# Primero el módulo: si mañana hay dependencias, esta capa se reutiliza mientras go.mod no cambie.
COPY go.mod go.sum ./
RUN go mod download
COPY main.go ./
# Binario estático (sin cgo: no necesita la libc de ninguna base), sin rutas locales ni símbolos de depuración.
RUN CGO_ENABLED=0 go build -trimpath -ldflags="-s -w" -o /out/pricing .
# La carpeta de los datos (G1), vacía: distroless no tiene shell para crearla en la etapa final.
RUN mkdir -p /out/data

# ── Etapa final: solo el binario ──
# gcr.io/distroless/static-debian13:nonroot — sin shell ni gestor de paquetes; usuario 65532.
FROM gcr.io/distroless/static-debian13@sha256:e2e927ec666bae08560abb3c55d0659eceabb657f56b6782ab500a9fc7f555e3
COPY --from=build /out/pricing /pricing
# Del usuario que corre (65532): un volumen que se monte aquí hereda el dueño (Fase 03).
COPY --from=build --chown=65532:65532 /out/data /var/lib/pricing
EXPOSE 8080
# Forma JSON: el binario es el proceso 1 (Fase 03).
CMD ["/pricing"]
