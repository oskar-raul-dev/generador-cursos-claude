# rescatado de la sesión b1c17b96, 2026-09-12T19:21:39Z · Verify new document
cd /Users/oskar/Developer/Learning/courses-ia-generated/go-for-java-devs
wc -l prompts/aprendizaje.md
n=$(grep -c '^```' prompts/aprendizaje.md); echo "vallas: $n (par=$((n%2==0)))"
