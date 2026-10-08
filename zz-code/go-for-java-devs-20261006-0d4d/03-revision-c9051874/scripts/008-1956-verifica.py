# rescatado de la sesión c9051874, 2026-09-13T19:56:57Z · Cross-check benchmark assignments per phase
import re,io,glob
exp={'00':['B-01'],'01':['B-02','B-03','B-04'],'02':['B-05'],'03':['B-06'],'04':[],'05':[],
 '06':['B-07','B-08','B-09','B-10'],'07':[],'08':['B-11','B-12'],'09':['B-13','B-14','B-15','B-16'],
 '10':[],'11':[],'12':['B-17','B-18'],'13':['B-19','B-20'],'14':['B-21'],'15':['B-22','B-23'],'16':['B-24'],'17':[]}
for f in sorted(glob.glob('[01][0-9]-*.md')):
    if 'convencion' in f or 'historia' in f: continue
    n=f[:2]; s=io.open(f,encoding='utf-8').read()
    i=s.find('## 📐')
    sec=s[i:] if i>0 else ''
    got=sorted(set(re.findall(r'B-\d{2}', sec)))
    e=sorted(exp[n])
    miss=[x for x in e if x not in got]; extra=[x for x in got if x not in e]
    print(f"F{n} esperado={e} en📐={got} {'OK' if not miss else 'FALTA:'+str(miss)} {'extra:'+str(extra) if extra else ''}")
