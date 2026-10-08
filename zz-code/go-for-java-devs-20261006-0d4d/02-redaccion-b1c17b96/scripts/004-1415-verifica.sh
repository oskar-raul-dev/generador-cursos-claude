# rescatado de la sesión b1c17b96, 2026-09-12T14:15:58Z · Inspect phase 17 dictionary and phase 15 missing section
cd /Users/oskar/Developer/Learning/courses-ia-generated/go-for-java-devs
echo "--- Fase 17: cómo se llama su diccionario ---"; grep -n '📖' 17-capstone.md | head
echo; echo "--- Fase 15: busca 'funciona igual' ---"; grep -n 'funciona igual\|🩻' 15-rendimiento-y-profiling.md | head
echo; echo "--- Encabezados de §4 en la fase 15 ---"; sed -n '/^## 🧠 4\./,/^## 🛠️ 5\./p' 15-rendimiento-y-profiling.md | grep -n '^###'
