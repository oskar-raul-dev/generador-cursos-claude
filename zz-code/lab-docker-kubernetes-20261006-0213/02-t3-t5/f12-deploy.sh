K="kubectl --context kind-minimo"
set -x
$K -n apps delete job catalog-migrate-x2 pricing-migrate --ignore-not-found
time task deploy -- minimo
$K -n apps rollout status deploy --timeout=240s
$K -n apps get pods
sleep 5
task conformance TARGET=cluster -- G1
task conformance TARGET=cluster -- G1
task conformance TARGET=cluster -- G2
time task seed:job -- minimo
curl -sS 'http://api.localhost:8080/pricing/prices?store=DRO-012' | head -c 400; echo
curl -sS http://api.localhost:8080/catalog/products | head -c 300; echo
