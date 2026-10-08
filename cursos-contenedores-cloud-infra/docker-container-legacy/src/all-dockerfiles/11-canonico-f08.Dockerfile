# Archivo compuesto por el curso: en el `.md` de la fase solo aparece el fragmento
# que cambia. Aquí está el archivo completo, listo para construir.
# Fase: F08 §7 — canónico con entrypoint y shims

# syntax=docker/dockerfile:1

FROM debian/eol:buster

LABEL org.opencontainers.image.title="legacy-node-toolchain"
LABEL org.opencontainers.image.description="Toolchain de desarrollo para proyectos Node.js legacy"

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
       bash \
       binutils \
       build-essential \
       ca-certificates \
       curl \
       file \
       g++ \
       gcc \
       git \
       jq \
       less \
       make \
       pkg-config \
       procps \
       python2 \
       python3 \
       unzip \
       vim \
       wget \
       xz-utils \
       zip \
    && rm -rf /var/lib/apt/lists/*

SHELL ["/bin/bash", "-c"]

ENV SHELL=/bin/bash

ARG NODE10_VERSION=10.24.1
ARG NODE12_VERSION=12.22.12
ARG NODE14_VERSION=14.21.3
ARG NODE16_VERSION=16.20.2
ARG DEFAULT_NODE_VERSION=10.24.1

RUN set -euxo pipefail; \
    mkdir -p /opt/node /tmp/node-downloads; \
    for version in \
        "${NODE10_VERSION}" \
        "${NODE12_VERSION}" \
        "${NODE14_VERSION}" \
        "${NODE16_VERSION}"; \
    do \
        [[ -n "${version}" ]] || continue; \
        archive="node-v${version}-linux-x64.tar.xz"; \
        base_url="https://nodejs.org/dist/v${version}"; \
        echo "==> Descargando Node ${version}"; \
        curl -fsSLo "/tmp/node-downloads/${archive}" \
            "${base_url}/${archive}"; \
        curl -fsSLo "/tmp/node-downloads/SHASUMS256-${version}.txt" \
            "${base_url}/SHASUMS256.txt"; \
        cd /tmp/node-downloads; \
        grep " ${archive}$" "SHASUMS256-${version}.txt" \
            | sha256sum -c -; \
        mkdir -p "/opt/node/${version}"; \
        tar -xJf "/tmp/node-downloads/${archive}" \
            -C "/opt/node/${version}" \
            --strip-components=1; \
        "/opt/node/${version}/bin/node" --version; \
        PATH="/opt/node/${version}/bin:${PATH}" \
            "/opt/node/${version}/bin/npm" --version; \
    done; \
    rm -rf /tmp/node-downloads

COPY scripts/select-node          /usr/local/bin/select-node
COPY scripts/docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
COPY scripts/legacy-node-command  /usr/local/bin/legacy-node-command

# select-node sigue sirviendo durante el BUILD para fijar la versión por defecto.
# En runtime mandan los shims: no modifican estado y respetan NODE_VERSION.
RUN chmod 0755 /usr/local/bin/select-node \
                /usr/local/bin/docker-entrypoint.sh \
                /usr/local/bin/legacy-node-command \
    && ln -sfn /usr/local/bin/legacy-node-command /usr/local/bin/node \
    && ln -sfn /usr/local/bin/legacy-node-command /usr/local/bin/npm \
    && ln -sfn /usr/local/bin/legacy-node-command /usr/local/bin/npx \
    && NODE_VERSION="${DEFAULT_NODE_VERSION}" node --version \
    && NODE_VERSION="${DEFAULT_NODE_VERSION}" npm --version

ENV NODE_VERSION=${DEFAULT_NODE_VERSION}

WORKDIR /workspace

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
CMD ["bash"]
