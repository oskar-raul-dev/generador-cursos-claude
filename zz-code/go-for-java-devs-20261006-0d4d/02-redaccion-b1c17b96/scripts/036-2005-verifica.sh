# rescatado de la sesión b1c17b96, 2026-09-12T20:05:09Z · Final count of Go course
cd /Users/oskar/Developer/Learning/courses-ia-generated/go-for-java-devs
echo "raíz:"; wc -l *.md | tail -1
echo "prompts (incluye aprendizaje.md):"; wc -l prompts/aprendizaje.md
echo "archivos en raíz: $(ls *.md | wc -l | tr -d ' ')"
