K="kubectl --context kind-minimo"
set -x
task images:load -- minimo 2>&1 | grep -v "^using docker"
: === el rollout antes de la migración
$K apply -f deploy/manifests/pricing/deployment.yaml
$K -n apps rollout status deploy/pricing --timeout=120s
sleep 3
curl -sS -X PUT -H 'Content-Type: application/json' -d '{"store":"DRO-007","price":21900}' http://api.localhost:8080/pricing/prices/SKU-0003; echo
$K -n apps logs deploy/pricing | tail -3
$K apply -f deploy/jobs/pricing-migrate.yaml
$K -n apps wait --for=condition=complete job/pricing-migrate --timeout=120s
$K -n apps logs job/pricing-migrate
curl -sS -X PUT -H 'Content-Type: application/json' -d '{"store":"DRO-007","price":21900}' http://api.localhost:8080/pricing/prices/SKU-0003; echo
: === dos migraciones de catalog a la vez, sobre la base vacía
$K apply -f deploy/jobs/experimentos/catalog-migrate-dos-a-la-vez.yaml
sleep 40
$K -n apps get pods -l job-name=catalog-migrate-x2
for p in $($K -n apps get pods -l job-name=catalog-migrate-x2 -o name); do echo "--- $p"; $K -n apps logs $p | tail -8; done
$K -n apps get job catalog-migrate-x2
