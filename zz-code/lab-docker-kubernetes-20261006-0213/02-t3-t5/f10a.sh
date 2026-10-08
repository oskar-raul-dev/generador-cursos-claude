set -x
kubectl config use-context kind-minimo
kubectl -n apps expose deploy pricing --name pricing-lb --type=LoadBalancer --port=8080 --target-port=http
sleep 20
kubectl -n apps get svc pricing-lb
docker run -d --name cloud-provider-kind --label curso=lab-docker-kubernetes --network kind -v /var/run/docker.sock:/var/run/docker.sock registry.k8s.io/cloud-provider-kind/cloud-controller-manager:v0.12.0
sleep 25
kubectl -n apps get svc pricing-lb
IP=$(kubectl -n apps get svc pricing-lb -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
curl -sS -m 8 "http://$IP:8080/health/live"; echo "exit $?"
docker ps --filter label=io.x-k8s.cloud-provider-kind.cluster --format '{{.Names}}  {{.Ports}}' 2>/dev/null; docker ps --format '{{.Names}} {{.Ports}}' | grep -i kindccm
kubectl -n apps delete svc pricing-lb
docker rm -f cloud-provider-kind
