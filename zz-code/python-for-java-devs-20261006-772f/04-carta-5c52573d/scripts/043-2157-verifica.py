# rescatado de la sesión 5c52573d, 2026-10-05T21:57:26Z · Final closure status check
import re
plan=open("prompts/plan-de-produccion-carta.md").read()
rows=re.findall(r"^\| op(\d{3}) \| `[^`]+` \| [^|]+ \| (\S+) \| (\S+) \|$",plan,re.M)
upto=[r for r in rows if int(r[0])<=156]
print("escritas:",sum(r[1]=="✅" for r in upto),"de",len(upto),"· corridas enteras:",sum(r[2]=="✅" for r in upto),"· en parte:",[f"op{r[0]}" for r in upto if r[2]=="🟡"])
print("tandas:",re.findall(r"^\| \*\*(T\d+)\*\* \|.*\| (\S+) \|$",plan,re.M)[:19])
print(re.search(r"Dónde está la producción.*",plan).group(0))
