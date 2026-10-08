set -u
date -u
kubectl apply -f src/lab/platform/data/nats-ha/ >/dev/null
kubectl -n data rollout status statefulset/nats-ha --timeout=180s >/dev/null
IMG=natsio/nats-box@sha256:be25666441c3aee65193aba33d60ff2f06ede7ee9eba58864324b33d7eb94fea
kubectl -n data run nats-box --image=$IMG --restart=Never --overrides='{"spec":{"securityContext":{"runAsNonRoot":true,"runAsUser":1000,"seccompProfile":{"type":"RuntimeDefault"}},"containers":[{"name":"nats-box","image":"'$IMG'","command":["sleep","infinity"],"securityContext":{"allowPrivilegeEscalation":false,"capabilities":{"drop":["ALL"]}}}]}}' >/dev/null
kubectl -n data wait --for=condition=Ready pod/nats-box --timeout=180s >/dev/null
N="kubectl -n data exec nats-box -- nats -s nats://nats-ha.data:4222"
$N stream add A15 --subjects 'a15.>' --replicas 3 --storage file --defaults >/dev/null
echo "--- ventana de duplicados: $($N stream info A15 -j | python3 -c "import json,sys;print(json.load(sys.stdin)['config']['duplicate_window']/1e9,'s')")"
L0=$($N stream info A15 -j | python3 -c "import json,sys;print(json.load(sys.stdin)['cluster']['leader'])")
echo "--- con $L0 de líder"; $N pub -J a15.venta venta-1 -H Nats-Msg-Id:venta-1 2>&1 | tail -1
node=$(kubectl -n data get pod "$L0" -o jsonpath='{.spec.nodeName}')
cid=$(docker exec "$node" crictl ps --name nats --label io.kubernetes.pod.name="$L0" -q)
pid=$(docker exec "$node" crictl inspect -o go-template --template '{{.info.pid}}' "$cid")
docker exec "$node" kill -9 "$pid" && echo "--- kill -9 a $L0 ($(date -u +%T))"
for i in $(seq 1 30); do sleep 1; L1=$($N stream info A15 -j 2>/dev/null | python3 -c "import json,sys
try: print(json.load(sys.stdin)['cluster'].get('leader',''))
except Exception: print('')"); [ -n "$L1" ] && [ "$L1" != "$L0" ] && break; done
echo "--- líder nuevo: $L1 ($(date -u +%T)); la misma venta, otra vez"
$N pub -J a15.venta venta-1 -H Nats-Msg-Id:venta-1 2>&1 | tail -1
echo "--- mensajes en el stream: $($N stream info A15 -j | python3 -c "import json,sys;print(json.load(sys.stdin)['state']['messages'])")"
echo "--- limpieza"
kubectl -n data delete pod nats-box >/dev/null; kubectl delete -f src/lab/platform/data/nats-ha/ --wait >/dev/null; kubectl -n data delete pvc -l app.kubernetes.io/name=nats-ha
for n in lab-worker lab-worker2; do docker exec $n crictl rmi $IMG >/dev/null 2>&1; done; kubectl -n data get pods --no-headers
