#!/usr/bin/env bash
# Prepares a runnable copy of the base-path harness rescued from session b74cbeda.
# The originals under 01-base-b74cbeda/archivos/_tmp/claude-501/ stay as they were rescued; this copies
# them to salidas/claude-501/ and rewrites the old root /tmp/claude-501 to that copy, so every
# script finds its siblings and the uv cache where the README says.
#
# Postgres: the originals connect over a Unix socket in /tmp/claude-501, port 55432. A socket path
# under this directory is too long for macOS (104 bytes), so the connection is rewritten apart:
#   PG_HOST_RUN  host or socket directory to use (default 127.0.0.1, for a Postgres container)
#   PG_PORT_RUN  port to use (default 55432; with a container, the random port Docker assigned)
set -euo pipefail
AQUI="$(cd "$(dirname "$0")" && pwd)"
ORIGEN="$AQUI/01-base-b74cbeda/archivos/_tmp/claude-501"
BASE="$AQUI/salidas/claude-501"
PG_HOST_RUN="${PG_HOST_RUN:-127.0.0.1}"
PG_PORT_RUN="${PG_PORT_RUN:-55432}"
rm -rf "$BASE"
mkdir -p "$BASE"
cp -R "$ORIGEN/." "$BASE/"
grep -rl "/tmp/claude-501" "$BASE" | while read -r f; do
  sed -i '' \
    -e "s|host=/tmp/claude-501 port=55432|host=$PG_HOST_RUN port=$PG_PORT_RUN|g" \
    -e "s|aurea@/agenda?host=/tmp/claude-501&port=55432|aurea@$PG_HOST_RUN:$PG_PORT_RUN/agenda|g" \
    -e "s|/tmp/claude-501|$BASE|g" "$f"
done
echo "BASE=$BASE"
echo "Postgres: host=$PG_HOST_RUN port=$PG_PORT_RUN user=aurea dbname=agenda"
