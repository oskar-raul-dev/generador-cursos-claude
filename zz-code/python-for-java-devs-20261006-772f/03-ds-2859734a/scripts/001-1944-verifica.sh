# rescatado de la sesión 2859734a, 2026-09-13T19:44:11Z · Inspect prose contexts framing the history file
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs
for spec in "prompts/README.md:25:55" "prompts/README.md:88:100" "prompts/prompts-de-fase.md:38:56" "prompts/prompts-de-tracks-ia-ds.md:78:96" "prompts/alcance-del-proyecto.md:142:155" "prompts/guia-de-estilo-y-convenciones.md:560:572" "prompts/guia-de-estilo-y-convenciones.md:610:624"; do
 f=${spec%%:*}; r=${spec#*:}; a=${r%%:*}; b=${r##*:}
 echo "=== $f $a-$b ==="; sed -n "${a},${b}p" "$f"; done
