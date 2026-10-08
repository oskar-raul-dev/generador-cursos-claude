# rescatado de la sesión 2859734a, 2026-09-14T02:50:59Z · Read the two contexts needing coordinated fixes
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-algoritmos-lenguajes/python-for-java-devs
echo "=== ia03 agent_runner: la inyección ==="; sed -n 10,16p src/ia03-tool-calling-y-el-bucle-de-agente/agent_runner.py
echo "--- y en la prosa:"; grep -n -B2 -A2 "_find_availability(agenda, branch" ia03-tool-calling-y-el-bucle-de-agente.md
echo; echo "=== ia06 statistics_helpers ==="; sed -n 18,28p src/ia06-evaluacion/statistics_helpers.py
echo "--- y en la prosa:"; grep -n -B3 -A2 "zip(a, b) if x == y" ia06-evaluacion.md
