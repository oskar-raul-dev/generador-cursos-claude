set -u
date
kubectl -n headlamp get events --sort-by=.lastTimestamp | grep -i -E "pull|readiness|liveness" | tail -5
kubectl -n headlamp port-forward svc/headlamp 38411:80 >/dev/null 2>&1 &
PF=$!; sleep 3
B=http://127.0.0.1:38411
echo "--- la página"; curl -s -o /dev/null -w "%{http_code} %{size_download} bytes\n" $B/
kubectl create namespace a14-prueba >/dev/null
kubectl -n a14-prueba run victima --image=registry.k8s.io/pause@sha256:278fb9dbcca9518083ad1e11276933a2e96f23de604a3a08cc3c80002767d24c --restart=Never >/dev/null 2>&1 || kubectl -n a14-prueba create configmap victima --from-literal=x=1
kubectl -n headlamp create serviceaccount lector >/dev/null
kubectl create clusterrolebinding a14-lector --clusterrole=view --serviceaccount=headlamp:lector >/dev/null
VIEW=$(kubectl -n headlamp create token lector --duration=1h)
echo "--- sin token: listar pods de apps"
curl -s -o /dev/null -w "%{http_code}\n" $B/clusters/main/api/v1/namespaces/apps/pods
echo "--- token view: listar pods de apps"
curl -s -w "\n%{http_code}\n" -H "Authorization: Bearer $VIEW" $B/clusters/main/api/v1/namespaces/apps/pods | python3 -c "import sys;t=sys.stdin.read().rsplit('\n',2);import json;d=json.loads(t[0]);print(len(d['items']),'pods ·',t[1])"
echo "--- token view: leer un Secret"
curl -s -o /dev/null -w "%{http_code}\n" -H "Authorization: Bearer $VIEW" $B/clusters/main/api/v1/namespaces/apps/secrets
echo "--- token view: borrar en a14-prueba"
curl -s -o /dev/null -w "%{http_code}\n" -X DELETE -H "Authorization: Bearer $VIEW" $B/clusters/main/api/v1/namespaces/a14-prueba/configmaps/victima
curl -s -o /dev/null -w "%{http_code}\n" -X DELETE -H "Authorization: Bearer $VIEW" $B/clusters/main/api/v1/namespaces/a14-prueba/pods/victima
kubectl -n a14-prueba get pods,configmaps --no-headers 2>&1 | grep victima
kill $PF
