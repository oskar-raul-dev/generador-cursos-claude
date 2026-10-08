#!/usr/bin/env bash

set -euo pipefail

IMAGE="${IMAGE:-legacy-node-toolchain:phase09}"
CONTAINER_NAME="${CONTAINER_NAME:-legacy-node-dev}"
NODE_VERSION_VALUE="${NODE_VERSION_VALUE:-10.24.1}"
PROJECT_DIR="${PROJECT_DIR:-$PWD}"
MODULES_VOLUME="${MODULES_VOLUME:-legacy-node10-modules}"

# si el contenedor ya existe lo reutilizamos: crear otro con el mismo nombre falla
if docker container inspect "${CONTAINER_NAME}" >/dev/null 2>&1; then
    echo "El contenedor ${CONTAINER_NAME} ya existe."
    echo "Iniciándolo si está detenido..."
    docker start "${CONTAINER_NAME}" >/dev/null
else
    if ! docker volume inspect "${MODULES_VOLUME}" >/dev/null 2>&1; then
        echo "Creando volumen ${MODULES_VOLUME}..."
        docker volume create "${MODULES_VOLUME}" >/dev/null
    fi

    echo "Creando ${CONTAINER_NAME} con Node ${NODE_VERSION_VALUE}..."

    docker run -d \
        --name "${CONTAINER_NAME}" \
        --platform linux/amd64 \
        -e "NODE_VERSION=${NODE_VERSION_VALUE}" \
        --mount "type=bind,src=${PROJECT_DIR},dst=/workspace" \
        --mount "type=volume,src=${MODULES_VOLUME},dst=/workspace/node_modules" \
        "${IMAGE}" \
        sleep infinity >/dev/null
fi

echo
printf 'Container: %s\n' "${CONTAINER_NAME}"
printf 'Node:      %s\n' "$(docker exec "${CONTAINER_NAME}" node --version)"
printf 'npm:       %s\n' "$(docker exec "${CONTAINER_NAME}" npm --version)"
printf 'Workspace: %s\n' "$(docker exec "${CONTAINER_NAME}" pwd)"
echo
echo "Entrar con:"
echo "  docker exec -it ${CONTAINER_NAME} bash"
