# rescatado de la sesión b1c17b96, 2026-09-12T14:17:49Z · Compare mini projects against source prompts
cd /Users/oskar/Developer/Learning/courses-ia-generated/go-for-java-devs
echo "=== Mini proyectos declarados en prompts-extendidos-fases.md ==="
grep -A1 '^- Mini proyectos' prompts/prompts-extendidos-fases.md | grep -oE '`[a-z-]+`' | tr -d '`' | sort -u > /tmp/prompt.txt
wc -l < /tmp/prompt.txt
echo "--- en mis fases y NO en los prompts:"; comm -23 /tmp/labs.txt /tmp/prompt.txt
echo "--- en los prompts y NO en mis fases:"; comm -13 /tmp/labs.txt /tmp/prompt.txt
