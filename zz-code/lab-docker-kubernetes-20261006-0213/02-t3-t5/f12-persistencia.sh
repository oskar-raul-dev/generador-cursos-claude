K="kubectl --context kind-minimo"
A=http://api.localhost:8080/inventory
set -x
: === inventory con dos réplicas, ahora sobre Postgres
$K -n apps scale deploy/inventory --replicas=2
$K -n apps rollout status deploy/inventory --timeout=240s
sleep 20
set +x
for i in 1 2 3 4 5 6; do curl -sS -o /dev/null -w "RESTOCK $i → %{http_code}\n" -X POST -H 'Content-Type: application/json' -d "{\"type\":\"RESTOCK\",\"quantity\":5,\"reference\":\"RO-91$i\"}" $A/stock/DRO-007/SKU-0001/movements; done
echo "=== veinte consultas"
for i in $(seq 1 20); do curl -sS $A/stock/DRO-007/SKU-0001 | python3 -c 'import sys,json;d=json.load(sys.stdin);print(d.get("quantity",d))'; done | sort | uniq -c
echo "=== el ajuste de -12, cuatro veces"
for i in 1 2 3 4; do curl -sS -o /dev/null -w "ADJUSTMENT -12 → %{http_code}\n" -X POST -H 'Content-Type: application/json' -d '{"type":"ADJUSTMENT","quantity":-12,"reasonCode":"DAMAGED"}' $A/stock/DRO-007/SKU-0001/movements; done
curl -sS $A/stock/DRO-007/SKU-0001; echo
set -x
$K -n apps scale deploy/inventory --replicas=1
: === borrar el pod de Postgres
$K -n data delete pod postgres-0
time $K -n data wait --for=condition=Ready pod/postgres-0 --timeout=180s
$K -n data get pod postgres-0
$K -n data get pvc
sleep 3
curl -sS $A/stock/DRO-007/SKU-0001; echo
curl -sS 'http://api.localhost:8080/pricing/prices?store=DRO-012' | python3 -c 'import sys,json;print(len(json.load(sys.stdin)),"precios en DRO-012")'
: === borrar el pod de inventory: en la Fase 09, el almacén se iba con él
$K -n apps delete pod -l app.kubernetes.io/name=inventory
$K -n apps rollout status deploy/inventory --timeout=240s
sleep 15
curl -sS $A/stock/DRO-007/SKU-0001; echo
