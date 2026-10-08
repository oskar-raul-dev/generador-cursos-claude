# rescatado de la sesión b1c17b96, 2026-09-12T19:59:38Z · Verify plan document and links
cd /Users/oskar/Developer/Learning/courses-ia-generated
wc -l PLAN-REFRESCAMIENTO.md
grep -ohE '\]\([0-9A-Za-z._/-]+\.md\)' PLAN-REFRESCAMIENTO.md | tr -d '()]' | sed 's/^\[//' | while read p; do [ -e "$p" ] && echo "OK   $p" || echo "ROTO $p"; done
