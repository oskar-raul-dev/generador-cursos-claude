# rescatado de la sesión b1c17b96, 2026-09-12T19:34:07Z · Verify proposal files and links
cd /Users/oskar/Developer/Learning/courses-ia-generated/propuestas-cursos/propuesta-java-arquitectura
wc -l *.md
echo "--- enlaces internos ---"
grep -ohE '\]\([0-9A-Za-z._/-]+\.md\)' *.md | tr -d '()]' | sed 's/^\[//' | sort -u | while read p; do [ -e "$p" ] && echo "OK   $p" || echo "ROTO $p"; done
