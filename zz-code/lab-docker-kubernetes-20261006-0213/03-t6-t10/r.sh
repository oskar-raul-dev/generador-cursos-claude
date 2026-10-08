# Imprime el comando y su salida, sin el ruido de xtrace.
r() { printf '$ %s\n' "$*"; eval "$@" 2>&1; }
