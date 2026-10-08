K="kubectl --context kind-minimo"
set -x
: === ejercicio 8: el usuario de replenish contra la base de inventory
URL=$($K -n apps get secret replenish-db -o jsonpath='{.data.DATABASE_URL}' | base64 -d | sed 's#/replenish$#/inventory#')
$K -n data exec postgres-0 -- psql "$URL" -c 'SELECT 1' 2>&1 | sed 's#//replenish:[^@]*@#//replenish:***@#'
: === un Job no se edita
$K -n apps get job seed -o name
sed 's/value: "20"/value: "21"/' deploy/jobs/seed.yaml | $K apply -f - 2>&1 | tail -2
: === ejercicio 11: el seed otra vez
task seed:job -- minimo 2>&1 | tail -1
curl -sS http://api.localhost:8080/catalog/products | python3 -c 'import sys,json;print(len(json.load(sys.stdin)),"productos")'
: === ejercicio 22: dos réplicas de Postgres
$K -n data scale statefulset/postgres --replicas=2
$K -n data rollout status statefulset/postgres --timeout=180s
$K -n data get pods,pvc
$K -n data exec postgres-1 -- psql -U postgres -d pricing -tAc 'SELECT count(*) FROM prices' 2>&1
$K -n data exec postgres-0 -- psql -U postgres -d pricing -tAc 'SELECT count(*) FROM prices'
$K -n data scale statefulset/postgres --replicas=1
$K -n data rollout status statefulset/postgres --timeout=180s
$K -n data get pvc
