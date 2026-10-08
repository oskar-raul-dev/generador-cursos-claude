# rescatado de la sesión 5c52573d, 2026-10-05T19:10:37Z · Probe PuLP 4 solve status and value API
docker run --rm --label curso=python-for-java-devs python:3.14.7 sh -c 'pip install -q --root-user-action=ignore PuLP==4.0.0 highspy==1.15.1 >/dev/null 2>&1; python -c "
import pulp, inspect
print(list(pulp.LpSolveStatus) if hasattr(pulp.LpSolveStatus, \"__iter__\") else pulp.LpSolveStatus)
p = pulp.LpProblem(\"t\", pulp.LpMinimize)
x = p.add_variable(\"x\", 0, 5)
p += x
p += x >= 2
r = p.solve(pulp.HiGHS(msg=False))
print(\"solve devuelve:\", repr(r), type(r))
print([n for n in dir(p) if not n.startswith(\"_\")])
print(\"value:\", pulp.value(p.objective) if hasattr(pulp,\"value\") else \"sin pulp.value\", x.value())
"'
