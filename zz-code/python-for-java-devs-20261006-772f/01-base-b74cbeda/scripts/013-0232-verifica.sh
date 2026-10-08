# rescatado de la sesión b74cbeda, 2026-09-13T02:32:15Z · Find where the split actually breaks
cd /tmp/claude-501/f06 && /opt/homebrew/bin/python3.14 -c "
import csv
for name, enc in [('fontibon','utf-8-sig'), ('restrepo','utf-8'), ('soacha','utf-8')]:
    p=f'data/cierre/{name}.csv'
    with open(p, encoding=enc, newline='') as f:
        rows=list(csv.DictReader(f))
    total_csv=sum(int(str(r['valor']).split()[0]) for r in rows)
    # el split de la Fase 01, sobre un archivo separado por comas
    total_split=0; rotas=0
    with open(p, encoding=enc) as f:
        next(f)
        for line in f:
            parts=line.strip().split(',')
            try: total_split+=int(parts[6])
            except (IndexError, ValueError): rotas+=1
    print(f'{name:10s} filas={len(rows):4d} csv={total_csv:>12,} split={total_split:>12,} rotas={rotas}')
"
