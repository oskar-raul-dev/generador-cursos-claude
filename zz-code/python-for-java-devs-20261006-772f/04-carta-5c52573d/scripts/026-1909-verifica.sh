# rescatado de la sesión 5c52573d, 2026-10-05T19:09:57Z · Print PuLP 4 variable creation signatures
docker run --rm --label curso=python-for-java-devs python:3.14.7 sh -c 'pip install -q --root-user-action=ignore PuLP==4.0.0 >/dev/null 2>&1; python -c "
import pulp, inspect
for n in (\"add_variable\",\"add_variable_dicts\",\"add_variable_dict\"):
    f=getattr(pulp.LpProblem,n); print(n, inspect.signature(f)); print((f.__doc__ or \"\").strip()[:300]); print()
"'
