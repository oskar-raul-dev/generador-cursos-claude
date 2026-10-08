# rescatado de la sesión b1c17b96, 2026-09-12T14:18:05Z · Locate the 28 vs 46 discrepancy
cd /Users/oskar/Developer/Learning/courses-ia-generated/go-for-java-devs
echo "=== Mini proyectos nombrados en propuesta-fases-y-alcance.md §3 ==="
grep -oE '`[a-z][a-z-]+`' prompts/propuesta-fases-y-alcance.md | tr -d '`' | sort -u | comm -12 - /tmp/prompt.txt | tr '\n' ' '
echo; echo "conteo: $(grep -oE '`[a-z][a-z-]+`' prompts/propuesta-fases-y-alcance.md | tr -d '`' | sort -u | comm -12 - /tmp/prompt.txt | wc -l)"
echo
echo "=== dónde se afirma 'veintiocho' ==="
grep -rn 'veintiocho\|28 mini\|28 mini proyectos' README.md 0-ESTRUCTURA-CURSO.md prompts/*.md
