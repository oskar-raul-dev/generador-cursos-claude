set -euo pipefail
find entrada -maxdepth 1 -type f -name '*.csv' -print0 |
  while IFS= read -r -d '' f; do
    printf '%s: %s\n' "$(basename -- "$f")" "$(wc -l < "$f")"
  done | sort
