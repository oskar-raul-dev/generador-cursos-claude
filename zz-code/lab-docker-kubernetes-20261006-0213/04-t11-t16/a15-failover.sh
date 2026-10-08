#!/usr/bin/env bash
# uso: a15-failover.sh <etiqueta> <modo: delete|kill9> <prefijo de id>
set -u
TAG=$1; MODE=$2; P=$3
N="kubectl -n data exec nats-box -- nats -s nats://nats-ha.data:4222"
ts() { python3 -u -c 'import sys,time
t0=time.time()
for l in sys.stdin: print(f"{time.time()-t0:6.2f} {l.rstrip()}", flush=True)'; }
leader() { $N stream info A15 -j 2>/dev/null | python3 -c "import json,sys
try: print(json.load(sys.stdin)['cluster'].get('leader','-'))
except Exception: print('?')"; }
before=$($N stream info A15 -j | python3 -c "import json,sys;print(json.load(sys.stdin)['state']['messages'])")
L0=$(leader); echo "[$TAG] mensajes antes: $before · líder: $L0"
kubectl -n data exec nats-box -- sh -c "i=0; while [ \$i -lt 400 ]; do i=\$((i+1)); if nats -s nats://nats-ha.data:4222 --timeout 2s pub -J a15.venta v$P\$i -H Nats-Msg-Id:$P\$i >/dev/null 2>/tmp/err; then echo \"ok $P\$i\"; else echo \"err $P\$i \$(tail -1 /tmp/err)\"; fi; sleep 0.1; done" | ts > /tmp/a15-$TAG-pub.txt &
PUB=$!
( for s in $(seq 1 45); do echo "líder: $(leader)"; sleep 1; done ) | ts > /tmp/a15-$TAG-lider.txt &
LW=$!
sleep 10
echo "[$TAG] +10 s: $MODE a $L0"
if [ "$MODE" = delete ]; then
  kubectl -n data delete pod "$L0" --wait=false
else
  node=$(kubectl -n data get pod "$L0" -o jsonpath='{.spec.nodeName}')
  cid=$(docker exec "$node" crictl ps --name nats --label io.kubernetes.pod.name="$L0" -q)
  pid=$(docker exec "$node" crictl inspect -o go-template --template '{{.info.pid}}' "$cid")
  docker exec "$node" kill -9 "$pid" && echo "kill -9 al pid $pid de $L0 en $node"
fi
wait $PUB; kill $LW 2>/dev/null; wait $LW 2>/dev/null
ok=$(grep -c ' ok ' /tmp/a15-$TAG-pub.txt); err=$(grep -c ' err ' /tmp/a15-$TAG-pub.txt)
after=$($N stream info A15 -j | python3 -c "import json,sys;print(json.load(sys.stdin)['state']['messages'])")
echo "[$TAG] publicadas con confirmación: $ok · fallidas: $err · mensajes en el stream: $before → $after (+$((after-before)))"
echo "[$TAG] primera y última falla:"; grep ' err ' /tmp/a15-$TAG-pub.txt | sed -n '1p;$p'
echo "[$TAG] la primera confirmada después de la primera falla:"; awk '/ err /{f=1} f && / ok /{print; exit}' /tmp/a15-$TAG-pub.txt
echo "[$TAG] cambios de líder:"; awk '{k=$3} k!=prev{print; prev=k}' /tmp/a15-$TAG-lider.txt
echo "[$TAG] ¿están todas las confirmadas? (por Nats-Msg-Id)"
$N sub a15.venta --stream A15 --all --raw --count "$after" 2>/dev/null | grep "^v$P" | sed 's/^v//' | sort -u > /tmp/a15-$TAG-stream.txt
grep ' ok ' /tmp/a15-$TAG-pub.txt | awk '{print $3}' | sort -u > /tmp/a15-$TAG-ok.txt
echo "  confirmadas que faltan en el stream: $(comm -23 /tmp/a15-$TAG-ok.txt /tmp/a15-$TAG-stream.txt | wc -l)"
echo "  en el stream sin confirmación (falló el pub, pero se guardó): $(comm -13 /tmp/a15-$TAG-ok.txt /tmp/a15-$TAG-stream.txt | wc -l)"
kubectl -n data get pods -l app.kubernetes.io/name=nats-ha -o custom-columns=POD:.metadata.name,LISTO:.status.containerStatuses[0].ready,REINICIOS:.status.containerStatuses[0].restartCount,NODO:.spec.nodeName
