# rescatado de la sesión b1c17b96, 2026-09-12T14:17:36Z · Count mini projects and check README figures
cd /Users/oskar/Developer/Learning/courses-ia-generated/go-for-java-devs
echo "=== MINI PROYECTOS declarados en las cabeceras ==="
grep -h '^> Mini proyectos:' [01][0-9]-*.md | sed 's/^> Mini proyectos: //' | tr ',' '\n' | grep -oE '`[a-z-]+`' | tr -d '`' | sort -u | tee /tmp/labs.txt | tr '\n' ' '
echo; echo "TOTAL ÚNICOS: $(wc -l < /tmp/labs.txt)"
echo
echo "=== ¿coinciden con la tabla de 0-ESTRUCTURA §5? ==="
grep -oE '`[a-z-]+`' 0-ESTRUCTURA-CURSO.md | tr -d '`' | sort -u > /tmp/est.txt
comm -23 /tmp/labs.txt /tmp/est.txt | sed 's/^/en fases y NO en estructura: /'
echo
echo "=== README: cifras ==="; grep -nE '131|dieciocho|18 fases|veintiocho|treinta y tres' README.md
