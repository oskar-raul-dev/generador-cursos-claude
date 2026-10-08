set -x
NGX=nginxinc/nginx-unprivileged@sha256:ed04ec1ff34502c339ee5c3ae3f855442398edc1d05591e2b98981dcbbd20b1e
run() { kubectl run cliente --rm --attach --restart=Never --quiet --image=$NGX -- "$@" </dev/null; }
run curl -s 'http://pricing.default.svc.cluster.local:8080/health/live'
run cat /etc/resolv.conf
task inc:break -- 06
kubectl get endpointslices -l kubernetes.io/service-name=pricing
run curl -sS -m 5 'http://pricing:8080/health/live'
kubectl describe svc pricing | grep -E "Selector|Endpoints"
task inc:fix -- 06
kubectl get endpointslices -l kubernetes.io/service-name=pricing
task inc:break -- 05
sleep 25
kubectl get pods -l app.kubernetes.io/name=pricing
kubectl describe pod -l app.kubernetes.io/name=pricing | grep -E "Failed|BackOff|Image:"
kubectl get deploy pricing
run curl -s 'http://pricing:8080/health/live'
task inc:fix -- 05
kubectl rollout status deploy/pricing --timeout=90s
kubectl get pods -l app.kubernetes.io/name=pricing
