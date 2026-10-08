#!/usr/bin/env bash
set -u
P=q-
N="kubectl -n data exec nats-box -- nats -s nats://nats-ha.data:4222"
ts() { python3 -u -c 'import sys,time
t0=time.time()
for l in sys.stdin: print(f"{time.time()-t0:6.2f} {l.rstrip()}", flush=True)'; }
date -u
before=$($N stream info A15 -j | python3 -c "import json,sys;print(json.load(sys.stdin)['state']['messages'])")
echo "mensajes antes: $before"
kubectl -n data exec nats-box -- sh -c "i=0; while [ \$i -lt 500 ]; do i=\$((i+1)); if nats -s nats://nats-ha.data:4222 --timeout 2s pub -J a15.venta v$P\$i -H Nats-Msg-Id:$P\$i >/dev/null 2>/tmp/err; then echo \"ok $P\$i\"; else echo \"err $P\$i \$(tail -1 /tmp/err)\"; fi; sleep 0.1; done" | ts > /tmp/a15-q-pub.txt &
PUB=$!
sleep 10; echo "+10 s: scale a 1 ($(date -u +%T))"; kubectl -n data scale statefulset nats-ha --replicas=1
sleep 15; echo "+25 s, con un solo miembro:"; $N stream info A15 2>&1 | tail -2
kubectl -n data exec nats-ha-0 -- wget -qO- -S localhost:8222/healthz 2>&1 | grep HTTP
sleep 10; echo "+35 s: scale a 3 ($(date -u +%T))"; kubectl -n data scale statefulset nats-ha --replicas=3
wait $PUB
ok=$(grep -c ' ok ' /tmp/a15-q-pub.txt); err=$(grep -c ' err ' /tmp/a15-q-pub.txt)
after=$($N stream info A15 -j | python3 -c "import json,sys;print(json.load(sys.stdin)['state']['messages'])")
echo "confirmadas: $ok · fallidas: $err · stream: $before → $after (+$((after-before)))"
echo "primera y última falla:"; grep ' err ' /tmp/a15-q-pub.txt | sed -n '1p;$p'
echo "errores, por tipo:"; grep ' err ' /tmp/a15-q-pub.txt | cut -d' ' -f5- | sort | uniq -c
$N sub a15.venta --stream A15 --all --raw --count "$after" 2>/dev/null | grep "^v$P" | sed 's/^v//' | sort -u > /tmp/a15-q-stream.txt
grep ' ok ' /tmp/a15-q-pub.txt | awk '{print $3}' | sort -u > /tmp/a15-q-ok.txt
echo "confirmadas que faltan en el stream: $(comm -23 /tmp/a15-q-ok.txt /tmp/a15-q-stream.txt | wc -l)"
echo "en el stream sin confirmación: $(comm -13 /tmp/a15-q-ok.txt /tmp/a15-q-stream.txt | wc -l)"
$N stream info A15 2>&1 | grep -E "Leader|Replica"
kubectl -n data get pods -l app.kubernetes.io/name=nats-ha
