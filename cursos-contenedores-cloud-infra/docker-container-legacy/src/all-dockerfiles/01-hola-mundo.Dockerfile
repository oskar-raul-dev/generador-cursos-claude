# syntax=docker/dockerfile:1

FROM debian/eol:buster

LABEL org.opencontainers.image.title="legacy-node-toolchain"
LABEL org.opencontainers.image.description="Toolchain de desarrollo para proyectos Node.js legacy"

WORKDIR /workspace

CMD ["/bin/echo", "👋 Hola desde legacy-node-toolchain"]
