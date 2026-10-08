# syntax=docker/dockerfile:1
# Imagen SEPARADA del toolchain: herramientas de diagnóstico que no queremos
# en la imagen de trabajo diaria. Se usa puntualmente y no se publica.

FROM debian/eol:buster

LABEL org.opencontainers.image.title="legacy-node-toolchain-diagnostic"
LABEL org.opencontainers.image.description="Herramientas de diagnóstico para el laboratorio legacy"

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
       binutils \
       ca-certificates \
       curl \
       dnsutils \
       file \
       iproute2 \
       jq \
       less \
       lsof \
       netcat-openbsd \
       procps \
       strace \
       tcpdump \
       vim \
    && rm -rf /var/lib/apt/lists/*

SHELL ["/bin/bash", "-c"]
CMD ["bash"]
