# golang:1.27.1-alpine
FROM golang@sha256:8a5910f31396cd4d89662f56c68b3ae31d374308270a1c3bd96672ee5ed43414 AS build
WORKDIR /src
COPY go.mod ./
COPY main.go ./
# Binario estático: la etapa final no tiene libc.
RUN CGO_ENABLED=0 go build -trimpath -ldflags="-s -w" -o /out/pricing .

# gcr.io/distroless/static-debian13:nonroot
FROM gcr.io/distroless/static-debian13@sha256:e2e927ec666bae08560abb3c55d0659eceabb657f56b6782ab500a9fc7f555e3
COPY --from=build /out/pricing /pricing
# El usuario nonroot de distroless (65532): ningún puerto privilegiado hace falta.
USER nonroot
EXPOSE 8080
ENTRYPOINT ["/pricing"]
