K="kubectl --context kind-minimo"
A=http://api.localhost:8080/inventory
set -x
$K -n apps scale deploy/inventory --replicas=2
$K -n apps rollout status deploy/inventory --timeout=180s
sleep 20
$K -n apps get pods -l app.kubernetes.io/name=inventory
set +x
echo "=== seis reposiciones de 5 unidades de SKU-0001 en DRO-007"
for i in 1 2 3 4 5 6; do curl -sS -o /dev/null -w "RESTOCK $i → %{http_code}\n" -X POST -H 'Content-Type: application/json' -d "{\"type\":\"RESTOCK\",\"quantity\":5,\"reference\":\"RO-90$i\"}" $A/stock/DRO-007/SKU-0001/movements; done
echo "=== veinte consultas de la existencia"
for i in $(seq 1 20); do curl -sS $A/stock/DRO-007/SKU-0001 | python3 -c 'import sys,json;d=json.load(sys.stdin);print(d.get("quantity",d))'; done | sort | uniq -c
echo "=== una venta de 12 unidades (un ajuste), cuatro veces"
for i in 1 2 3 4; do curl -sS -w " → %{http_code}\n" -X POST -H 'Content-Type: application/json' -d '{"type":"ADJUSTMENT","quantity":-12,"reasonCode":"DAMAGED"}' $A/stock/DRO-007/SKU-0001/movements; done
echo "=== los logs: ¿alguien se queja?"
for p in $($K -n apps get pods -l app.kubernetes.io/name=inventory -o name); do echo "--- $p"; $K -n apps logs $p | grep -ci "error\|exception\|warn" ; done
