set -u
date
t0=$(date +%s)
helm install headlamp headlamp/headlamp --version 0.45.0 -n headlamp --create-namespace --wait --timeout 5m 2>&1 | head -5
echo "listo en $(( $(date +%s) - t0 )) s"
kubectl -n headlamp get pods -o wide
kubectl -n headlamp get deploy headlamp -o jsonpath='{..image}{"\n"}'
kubectl -n headlamp get pod -l app.kubernetes.io/name=headlamp -o jsonpath='{..imageID}{"\n"}'
kubectl -n headlamp get clusterrolebinding -o name 2>/dev/null | grep -i headlamp; kubectl get clusterrolebinding -o wide | grep -i headlamp
sleep 60
echo "--- memoria en reposo"; kubectl -n headlamp top pods
