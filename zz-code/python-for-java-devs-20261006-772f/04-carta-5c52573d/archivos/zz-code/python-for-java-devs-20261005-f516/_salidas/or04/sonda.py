exec(open("pony_saldos.py").read().split("def is_overdue")[0].replace('print(query.get_sql())', ''))
import re
def f_regex(c): return re.search(r"\d3$", c) is not None
def f_loop(c):
    for ch in c:
        if ch == "3": return True
    return False
def f_int(c): return int(c[-3:]) % 7 == 0
for fn_ in (f_regex, f_loop, f_int):
    with db_session:
        try:
            q = select(p for p in Plan if fn_(p.codigo))
            print(fn_.__name__, "OK", len(q[:]), q.get_sql().replace("\n", " ")[-60:])
        except Exception as e:
            print(fn_.__name__, type(e).__name__, str(e)[:100])
