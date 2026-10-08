# rescatado de la sesión 5c52573d, 2026-10-05T19:10:25Z · Find PuLP 4 status API
docker run --rm --label curso=python-for-java-devs python:3.14.7 sh -c 'pip install -q --root-user-action=ignore PuLP==4.0.0 >/dev/null 2>&1; python -c "
import pulp
print([n for n in dir(pulp) if \"tatus\" in n])
print([n for n in dir(pulp.LpProblem) if \"tatus\" in n or n==\"objective\" or \"value\" in n.lower()])
from pulp import constants as c; print([n for n in dir(c) if \"tatus\" in n])
"'
