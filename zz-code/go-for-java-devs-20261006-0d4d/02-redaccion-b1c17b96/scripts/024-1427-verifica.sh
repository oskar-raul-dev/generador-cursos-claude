# rescatado de la sesión b1c17b96, 2026-09-12T14:27:57Z · Read style guide sections 9 and 10
cd /Users/oskar/Developer/Learning/courses-ia-generated/go-for-java-devs/prompts
sed -n '/^## 9. Plantilla obligatoria/,/^### 9.1/p' guia-de-estilo-y-convenciones.md
echo "======== §10"
sed -n '/^## 10. Ejercicios/,/^## 11\./p' guia-de-estilo-y-convenciones.md | head -40
