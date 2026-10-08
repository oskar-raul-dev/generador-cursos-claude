# rescatado de la sesión 03630220, 2026-09-13T18:28:51Z · Final verification sweep
echo "== cross-curso restante en material publicado =="; grep -nE "cursos-ia|cursos-[a-z]+|CLAUDE\.md|otros cursos del repositorio|curso hermano|python-for-java|ruta-nosql" *.md
echo "== enlaces =="; grep -ohE "\]\(([^)h][^)]*)\)" *.md | sed -E 's/^\]\(//; s/\)$//' | sed 's/#.*//' | sort -u | while read -r l; do [ -z "$l" ] && continue; [ -e "$l" ] || echo "ROTO: $l"; done
echo "== cadena de fases =="; grep -h "^> Depende de:" *.md | sort
