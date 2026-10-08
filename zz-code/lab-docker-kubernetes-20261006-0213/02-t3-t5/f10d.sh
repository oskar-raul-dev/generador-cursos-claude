set -x
task cluster:down -- minimo
task cluster:up -- lab
task images:load -- lab
task platform:gateway -- lab
kubectl --context kind-lab apply -f /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/lab-docker-kubernetes-20261006-0213/02-t3-t5/envoyproxy-local.yaml
sleep 10
task deploy -- lab
kubectl --context kind-lab -n apps rollout status deploy/pricing --timeout=120s
kubectl --context kind-lab -n gateway get pods -o wide -l gateway.envoyproxy.io/owning-gateway-name=lab
kubectl --context kind-lab -n gateway get svc -l gateway.envoyproxy.io/owning-gateway-name=lab -o jsonpath='{.items[0].spec.externalTrafficPolicy}{"\n"}'
time curl -sS -m 10 http://api.localhost:8080/pricing/health/live; echo "exit $?"
kubectl --context kind-lab apply -f platform/gateway/envoyproxy.yaml
sleep 10
kubectl --context kind-lab -n gateway get svc -l gateway.envoyproxy.io/owning-gateway-name=lab -o jsonpath='{.items[0].spec.externalTrafficPolicy}{"\n"}'
time curl -sS -m 10 http://api.localhost:8080/pricing/health/live; echo "exit $?"
kubectl --context kind-lab -n apps logs deploy/pricing --tail=2
