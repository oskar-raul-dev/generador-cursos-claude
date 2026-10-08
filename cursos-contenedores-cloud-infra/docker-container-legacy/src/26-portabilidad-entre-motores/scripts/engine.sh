#!/usr/bin/env bash
# Capa fina sobre docker/podman: detecta el motor y expone sus diferencias
# como variables, en lugar de esconderlas tras una abstracción gruesa.

set -euo pipefail

# ENGINE puede forzarse desde fuera: ENGINE=podman ./scripts/run-dev.sh
ENGINE="${ENGINE:-}"

if [[ -z "${ENGINE}" ]]; then
    if command -v docker >/dev/null 2>&1 && docker info >/dev/null 2>&1; then
        ENGINE=docker
    elif command -v podman >/dev/null 2>&1; then
        ENGINE=podman
    else
        echo "ERROR: no encuentro un motor de contenedores utilizable." >&2
        echo "Instala Docker o Podman, o exporta ENGINE=<motor>." >&2
        exit 69
    fi
fi

# Las diferencias reales, expuestas como variables en vez de ocultas
case "${ENGINE}" in
    docker)
        HOST_ALIAS='host.docker.internal'
        VOLUME_OPTS=''            # Docker no necesita :U ni :z
        ;;
    podman)
        HOST_ALIAS='host.containers.internal'
        # :U ajusta el ownership del volumen (F17 §7); solo tiene sentido en Podman
        VOLUME_OPTS=',U'
        ;;
    *)
        echo "ERROR: motor no soportado: ${ENGINE}" >&2
        exit 64
        ;;
esac

export ENGINE HOST_ALIAS VOLUME_OPTS

engine() { command "${ENGINE}" "$@"; }
