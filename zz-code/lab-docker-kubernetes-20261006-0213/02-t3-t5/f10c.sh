set -x
task inc:break -- 08
sleep 3
curl -sS -i -m 5 'http://api.localhost:8080/pricing/prices/SKU-0003?store=DRO-007' | head -3
kubectl -n apps get pods -l app.kubernetes.io/name=pricing
kubectl -n apps logs deploy/pricing --tail=2
kubectl -n apps get httproute pricing -o jsonpath='{range .status.parents[*]}{.parentRef.name} {.parentRef.namespace}{"\n"}{range .conditions[*]}{.type}={.status} {.reason}: {.message}{"\n"}{end}{end}'
kubectl -n apps describe httproute pricing | sed -n '/Status:/,$p' | head -25
task inc:fix -- 08
sleep 3
curl -sS -m 5 'http://api.localhost:8080/pricing/prices/SKU-0003?store=DRO-007'; echo
