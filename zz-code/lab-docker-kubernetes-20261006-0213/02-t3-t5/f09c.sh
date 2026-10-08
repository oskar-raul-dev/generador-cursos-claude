set -x
NGX=nginxinc/nginx-unprivileged@sha256:ed04ec1ff34502c339ee5c3ae3f855442398edc1d05591e2b98981dcbbd20b1e
kubectl delete -f /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/lab-docker-kubernetes-20261006-0213/02-t3-t5/f08m/
task images:load -- minimo >/dev/null
task deploy -- minimo >/dev/null
kubectl -n apps rollout status deploy --timeout=180s >/dev/null
c() { kubectl run cliente -n apps --rm --attach --restart=Never --quiet --image=$NGX -- curl -s "$@" </dev/null 2>/dev/null | head -1; }
c -X POST -H 'Content-Type: application/json' -d '{"sku":"SKU-0003","name":"Salbutamol inhalador 100 mcg","category":"venta libre"}' http://catalog:8080/products
c http://catalog:8080/products
kubectl -n apps exec deploy/catalog -c php-fpm -- kill -TERM 1
sleep 8
kubectl -n apps get pods -l app.kubernetes.io/name=catalog
c http://catalog:8080/products
kubectl -n apps delete pod -l app.kubernetes.io/name=catalog
kubectl -n apps rollout status deploy/catalog --timeout=120s
kubectl -n apps get pods -l app.kubernetes.io/name=catalog
c http://catalog:8080/products
