set -x
K="kubectl --context kind-minimo"
$K -n apps rollout status deploy --timeout=180s
$K -n legacy rollout status deploy --timeout=180s
$K apply -f deploy/qa/qa.yaml
$K -n apps set image deploy/storefront storefront=lab/storefront:g1
$K -n apps set image deploy/storefront-qa storefront=lab/storefront:g1
$K -n apps rollout status deploy/storefront --timeout=180s
$K -n apps rollout status deploy/storefront-qa --timeout=180s
$K -n apps rollout status deploy/catalog-qa --timeout=180s
$K -n apps get deploy storefront storefront-qa -o 'custom-columns=NAME:.metadata.name,IMAGE:.spec.template.spec.containers[0].image'
$K -n apps exec deploy/storefront-qa -- printenv API_BASE_URL BRAND_NAME
sleep 3
curl -sS -X POST -H 'Content-Type: application/json' -d '{"sku":"SKU-9001","name":"PRODUCTO DE PRUEBA QA","category":"venta libre"}' http://api-qa.localhost:8080/catalog/products; echo
curl -sS http://api.localhost:8080/catalog/products; echo
curl -sS http://api-qa.localhost:8080/catalog/products; echo
