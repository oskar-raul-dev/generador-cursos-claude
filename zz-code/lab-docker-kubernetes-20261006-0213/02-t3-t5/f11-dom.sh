K="kubectl --context kind-minimo"
D=/Users/oskar/Developer/Learning/courses-ia-generated/zz-code/lab-docker-kubernetes-20261006-0213/02-t3-t5/dom.sh
echo "=== G1 · storefront.localhost"; $D http://storefront.localhost:8080/
echo "=== G1 · storefront-qa.localhost (API_BASE_URL=http://api-qa.localhost:8080 en el contenedor)"; $D http://storefront-qa.localhost:8080/
echo "=== G1 · la variante silenciosa: el API de producción también acepta el origen de QA"
$K -n apps patch securitypolicy catalog-cors --type=merge -p '{"spec":{"cors":{"allowOrigins":["http://storefront.localhost:8080","http://storefront-qa.localhost:8080"]}}}'
sleep 3
$D http://storefront-qa.localhost:8080/
$K apply -f deploy/manifests/catalog/cors.yaml
echo "=== G2: la misma imagen nueva en los dos"
$K apply -f deploy/manifests/storefront/ -f deploy/qa/qa.yaml
$K -n apps rollout status deploy/storefront --timeout=120s
$K -n apps rollout status deploy/storefront-qa --timeout=120s
$K -n apps get deploy storefront storefront-qa -o 'custom-columns=NAME:.metadata.name,IMAGE:.spec.template.spec.containers[0].image'
sleep 3
curl -sS http://storefront.localhost:8080/config.json; echo
curl -sS http://storefront-qa.localhost:8080/config.json; echo
echo "=== G2 · storefront.localhost"; $D http://storefront.localhost:8080/
echo "=== G2 · storefront-qa.localhost"; $D http://storefront-qa.localhost:8080/
