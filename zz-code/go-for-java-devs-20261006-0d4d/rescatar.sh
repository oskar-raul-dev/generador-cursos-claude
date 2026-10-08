#!/usr/bin/env bash
# Rebuilds this directory's generated folders from the session transcripts, from scratch.
# The list of sessions and options lives in ../rescates.tsv; the work is done by ../regenerar-rescates.py
# (which calls zz-instrucciones/herramientas/rescatar-transcripcion.py). Add --comprobar to regenerate
# aside and compare without touching anything. Never calls Docker.
set -euo pipefail
exec python3 "$(cd "$(dirname "$0")" && pwd)/../regenerar-rescates.py" --dir go-for-java-devs-20261006-0d4d "$@"
