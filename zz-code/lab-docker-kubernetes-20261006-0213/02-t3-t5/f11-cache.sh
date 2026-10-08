set -x
K="kubectl --context kind-minimo"
task build -- storefront 2>&1 | tail -1
kind load docker-image lab/storefront:g2 --name minimo
$K -n apps rollout restart deploy/storefront deploy/storefront-qa
$K -n apps rollout status deploy/storefront-qa --timeout=120s
$K -n apps rollout status deploy/storefront --timeout=120s
sleep 3
curl -sS -I http://storefront-qa.localhost:8080/ | grep -i "cache-control\|etag"
rm -rf /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/lab-docker-kubernetes-20261006-0213/02-t3-t5/chrome-cache-b
: un perfil nuevo ve G2 con la cabecera
python3 /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/lab-docker-kubernetes-20261006-0213/02-t3-t5/dom-perfil.py http://storefront-qa.localhost:8080/ /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/lab-docker-kubernetes-20261006-0213/02-t3-t5/chrome-cache-b
: se despliega en QA otra imagen, la de G1, y el mismo perfil vuelve a abrir la página
$K -n apps set image deploy/storefront-qa storefront=lab/storefront:g1
$K -n apps rollout status deploy/storefront-qa --timeout=120s
sleep 3
python3 /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/lab-docker-kubernetes-20261006-0213/02-t3-t5/dom-perfil.py http://storefront-qa.localhost:8080/ /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/lab-docker-kubernetes-20261006-0213/02-t3-t5/chrome-cache-b
$K apply -f deploy/qa/qa.yaml
$K -n apps rollout status deploy/storefront-qa --timeout=120s
