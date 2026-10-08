set -x
kubectl delete -f deploy/manifests/pricing/deployment.yaml -n default --ignore-not-found 2>&1 | tail -1
kubectl -n default delete deploy/pricing svc/pricing
time task images:load -- minimo
task deploy -- minimo
kubectl -n apps rollout status deploy --timeout=180s
kubectl -n apps get pods -o wide
kubectl -n apps get svc
task conformance TARGET=cluster -- G1
task conformance TARGET=cluster -- G1
