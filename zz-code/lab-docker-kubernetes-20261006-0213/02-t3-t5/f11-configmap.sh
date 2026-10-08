K="kubectl --context kind-minimo"
set -x
$K -n apps logs deploy/pricing | grep -i tope
curl -sS -X PUT -H 'Content-Type: application/json' -d '{"store":"DRO-007","price":21900}' http://api.localhost:8080/pricing/prices/SKU-0003; echo
# Un pod testigo que monta el mismo ConfigMap: muestra qué ve el archivo montado.
$K -n apps run testigo --restart=Never --image=nginxinc/nginx-unprivileged@sha256:ed04ec1ff34502c339ee5c3ae3f855442398edc1d05591e2b98981dcbbd20b1e --overrides='{"spec":{"volumes":[{"name":"caps","configMap":{"name":"pricing-regulated-caps"}}],"containers":[{"name":"testigo","image":"nginxinc/nginx-unprivileged@sha256:ed04ec1ff34502c339ee5c3ae3f855442398edc1d05591e2b98981dcbbd20b1e","command":["sleep","3600"],"volumeMounts":[{"name":"caps","mountPath":"/etc/pricing"}]}]}}'
$K -n apps wait --for=condition=Ready pod/testigo --timeout=60s
$K -n apps exec testigo -- cat /etc/pricing/regulated-caps.csv
set +x
echo "=== $(date +%H:%M:%S) task inc:break -- 09 (la circular: 20000 -> 18000)"
task inc:break -- 09
T0=$(date +%s)
for i in $(seq 0 13); do
  now=$(( $(date +%s) - T0 ))
  file=$($K -n apps exec testigo -- cat /etc/pricing/regulated-caps.csv | tr -d '\n')
  resp=$(curl -sS 'http://api.localhost:8080/pricing/prices/SKU-0003?store=DRO-007')
  echo "t=${now}s archivo montado: ${file} · pricing: ${resp}"
  sleep 30
done
set -x
$K -n apps get configmap pricing-regulated-caps -o jsonpath='{.data.regulated-caps\.csv}'
task inc:fix -- 09
curl -sS 'http://api.localhost:8080/pricing/prices/SKU-0003?store=DRO-007'; echo
curl -sS -X PUT -H 'Content-Type: application/json' -d '{"store":"DRO-007","price":21900}' http://api.localhost:8080/pricing/prices/SKU-0003; echo
$K -n apps logs deploy/pricing | grep -i tope
$K -n apps delete pod testigo --wait=false
