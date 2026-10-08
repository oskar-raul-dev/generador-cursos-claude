set -x
NGX=nginxinc/nginx-unprivileged@sha256:ed04ec1ff34502c339ee5c3ae3f855442398edc1d05591e2b98981dcbbd20b1e
kubectl -n apps exec deploy/inventory -- getent hosts catalog
kubectl -n apps exec deploy/inventory -- env | grep _URL
kubectl run cliente -n default --rm --attach --restart=Never --quiet --image=$NGX -- curl -sS -m 5 http://catalog:8080/health/live </dev/null
kubectl run cliente -n default --rm --attach --restart=Never --quiet --image=$NGX -- curl -sS -m 5 http://catalog.apps:8080/health/live </dev/null
kubectl -n apps get pod -l app.kubernetes.io/name=catalog -o jsonpath='{range .items[0].spec.containers[*]}{.name}{"  "}{.image}{"\n"}{end}'
kubectl -n apps logs deploy/catalog -c nginx --tail=2
kubectl -n apps logs deploy/catalog -c php-fpm --tail=3
task inc:break -- 07
kubectl rollout status deploy/inventory -n default --timeout=120s
kubectl get pods -A -l app.kubernetes.io/name=inventory
kubectl -n default exec deploy/inventory -- getent hosts catalog; echo "exit $?"
kubectl -n default exec deploy/inventory -- getent hosts catalog.apps.svc.cluster.local; echo "exit $?"
task inc:fix -- 07
curl -sS -m 5 http://api.localhost:8080/catalog/products; echo "exit $?"
kubectl -n apps port-forward svc/storefront 18082:8080 >/dev/null 2>&1 &
PF=$!; sleep 2; curl -s http://127.0.0.1:18082/ | head -12; grep -o "api.localhost:8080" <(curl -s http://127.0.0.1:18082/$(curl -s http://127.0.0.1:18082/ | grep -o 'assets/index-[^"]*\.js' | head -1)) | head -1; kill $PF
