# rescatado de la sesión c9051874, 2026-09-13T19:57:08Z · Verify every declared mini project appears in its phase
import re,io,glob
labs={'00':['hello-go','build-info','crossbuild'],'01':['movement-parser','text-toolkit','log-grep'],
'02':['shapes','store-registry','notifier'],'03':['error-chain','config-loader','json-codec'],
'04':['validator-tests','fake-clock','golden-report'],'05':['tiny-router','middleware-chain','httptest-lab'],
'06':['race-counter','deadlock-lab','leak-lab','unbounded-queue'],
'07':['cancellable-worker','timeout-client','graceful-server','leak-detector'],
'09':['pool-lab','tx-lab','cursor-vs-offset'],'10':['client-timeouts','backoff-lab','recorded-responses'],
'11':['bson-lab','aggregation-lab'],'12':['cache-aside-lab','stampede-lab','ratelimit-lab'],
'13':['chunked-stream','checkpoint-lab','outbox-lab'],'14':['slog-lab','metrics-lab','distroless-lab'],
'15':['benchstat-lab','escape-lab','pool-vs-alloc']}
files={f[:2]:io.open(f,encoding='utf-8').read() for f in glob.glob('[01][0-9]-*.md') if 'conv' not in f and 'hist' not in f}
tot=0
for n,ls in sorted(labs.items()):
    tot+=len(ls)
    miss=[l for l in ls if l not in files.get(n,'')]
    print(f"F{n}: {len(ls)} labs {'OK' if not miss else 'FALTAN EN LA FASE: '+str(miss)}")
print("total labs declarados:", tot)
