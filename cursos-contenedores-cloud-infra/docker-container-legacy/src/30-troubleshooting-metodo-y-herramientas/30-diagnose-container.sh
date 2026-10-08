#!/usr/bin/env bash

set -u

if [[ $# -lt 1 ]]; then
  echo "Uso: $0 <container> [output.md]" >&2
  exit 64
fi

CONTAINER="$1"
OUTPUT="${2:-troubleshooting-${CONTAINER}.md}"

exec > >(tee "$OUTPUT") 2>&1

echo "# Troubleshooting snapshot"
echo
echo "- UTC: $(date -u +'%Y-%m-%dT%H:%M:%SZ')"
echo "- Container: \`$CONTAINER\`"
echo

section() {
  printf '\n## %s\n\n' "$1"
}

run() {
  printf '\n```text\n'
  printf '$ %s\n' "$*"
  "$@" || true
  printf '```\n'
}

# Tapa el VALOR de cualquier par NOMBRE=valor que aparezca en la salida.
# La política es "deny by default": el nombre de la variable es evidencia útil,
# el valor casi nunca lo es y puede ser un secreto. Por eso se conservan solo
# las variables de una lista corta que no puede guardar credenciales.
#
# El truco de las tres expresiones: la primera marca las variables permitidas
# con un centinela, la segunda tapa todo lo que quedó sin marcar, y la tercera
# retira el centinela. Se usa '%KEEP%' y no un carácter de control porque este
# script corre en el HOST, y el sed de macOS no entiende '\x01'.
redact() {
  sed -E \
    -e 's/"(PATH|HOME|HOSTNAME|PWD|SHLVL|TERM|LANG|LC_ALL|NODE_VERSION|NODE_ENV|NODE_PATH|NPM_CONFIG_LOGLEVEL)=/"\1%KEEP%=/g' \
    -e 's/"([A-Za-z_][A-Za-z0-9_]*)=[^"]*"/"\1=<redacted>"/g' \
    -e 's/%KEEP%=/=/g'
}

# Igual que run(), pero pasa la salida por redact().
# Se usa en todo comando capaz de arrastrar valores de variables de entorno.
run_redacted() {
  printf '\n```text\n'
  printf '$ %s\n' "$*"
  "$@" 2>&1 | redact || true
  printf '```\n'
}

section "Docker client/server"
run docker version

section "Docker context"
run docker context show
run docker context ls

section "Docker info"
run docker info

section "Container list"
run docker ps -a --no-trunc

# OJO: 'docker inspect' completo incluye .Config.Env con los valores en claro.
# Es el punto de fuga menos obvio del script; por eso va redactado.
section "Container inspect"
run_redacted docker inspect "$CONTAINER"

section "Container state"
run docker inspect \
  --format 'status={{.State.Status}} running={{.State.Running}} exit={{.State.ExitCode}} oom={{.State.OOMKilled}} error={{printf "%q" .State.Error}} started={{.State.StartedAt}} finished={{.State.FinishedAt}}' \
  "$CONTAINER"

section "Mounts"
run docker inspect \
  --format '{{json .Mounts}}' \
  "$CONTAINER"

section "Network settings"
run docker inspect \
  --format '{{json .NetworkSettings}}' \
  "$CONTAINER"

section "Recent logs"
run docker logs \
  --timestamps \
  --tail 300 \
  "$CONTAINER"

section "Processes"
run docker top "$CONTAINER"

section "Stats"
run docker stats \
  --no-stream \
  "$CONTAINER"

if docker inspect \
     --format '{{.State.Running}}' \
     "$CONTAINER" 2>/dev/null \
     | grep -qx true; then

  section "Runtime identity"
  run docker exec "$CONTAINER" \
    sh -lc 'id; uname -a; cat /etc/os-release'

  section "Node"
  run docker exec "$CONTAINER" \
    sh -lc 'command -v node; node --version; command -v npm; npm --version; node -p "process.platform"; node -p "process.arch"; node -p "process.versions.modules"'

  section "Python and toolchain"
  run docker exec "$CONTAINER" \
    sh -lc 'python2 --version 2>&1; python3 --version 2>&1; gcc --version | head -1; g++ --version | head -1; make --version | head -1'

  section "Filesystem"
  run docker exec "$CONTAINER" \
    sh -lc 'pwd; df -h; df -i; mount | head -100'

  # Antes esto tapaba solo los nombres "sospechosos" y dejaba pasar el resto.
  # Ahora usa la misma política que el inspect: se conserva el nombre y se tapa
  # el valor salvo en la lista corta de redact().
  section "Environment names"
  run_redacted docker exec "$CONTAINER" \
    sh -lc 'env | sed -E "s/^([A-Za-z_][A-Za-z0-9_]*)=(.*)$/\"\1=\2\"/" | sort'

  section "Listening sockets"
  run docker exec "$CONTAINER" \
    sh -lc 'command -v ss >/dev/null && ss -lntup || true'
fi

section "Recent Docker events"
run docker events \
  --since 10m \
  --until "$(date -u +'%Y-%m-%dT%H:%M:%SZ')" \
  --filter "container=$CONTAINER"

echo
echo "Snapshot terminado."
