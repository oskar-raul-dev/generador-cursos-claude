# rescatado de la sesión 2859734a, 2026-09-13T19:44:49Z · Grep root-document references
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs
echo "=== links a 00-convencion / documentos raiz en guia y alcance ==="; grep -rn "00-convencion" *.md prompts/*.md | head -20
echo "=== 'documentos de la raíz' ==="; grep -rn "raíz del curso" prompts/*.md *.md | head -20
