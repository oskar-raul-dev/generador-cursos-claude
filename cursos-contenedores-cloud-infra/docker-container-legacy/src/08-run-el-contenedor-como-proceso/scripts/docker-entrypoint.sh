#!/usr/bin/env bash

set -euo pipefail

version="${NODE_VERSION:-10.24.1}"
node_home="/opt/node/${version}"

# si la versión pedida no existe, fallamos temprano y con un mensaje que ayude
if [[ ! -x "${node_home}/bin/node" ]]; then
    echo "ERROR: Node ${version} no está instalado en esta imagen." >&2
    echo "Versiones disponibles:" >&2
    find /opt/node -mindepth 1 -maxdepth 1 -type d -printf '  - %f\n' | sort >&2
    exit 64
fi

export NODE_VERSION="${version}"

# a stderr, para no contaminar la salida del comando que el usuario pidió
printf 'legacy-node-toolchain: Node %s\n' "${NODE_VERSION}" >&2

exec "$@"
