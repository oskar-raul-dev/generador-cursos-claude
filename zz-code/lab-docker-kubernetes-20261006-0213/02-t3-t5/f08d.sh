set -x
kubectl apply -f /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/lab-docker-kubernetes-20261006-0213/02-t3-t5/f08m/
kubectl rollout status deploy/pricing --timeout=60s
kubectl patch deploy pricing --type=merge -p '{"spec":{"selector":{"matchLabels":{"app.kubernetes.io/name":"pricing","app.kubernetes.io/component":"backend"}}}}'
kubectl apply -f /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/lab-docker-kubernetes-20261006-0213/02-t3-t5/pod-suelto.yaml
kubectl wait --for=condition=Ready pod/pricing-suelto --timeout=60s
kubectl delete pod pricing-suelto
sleep 5
kubectl get pods
kubectl get rs -l app.kubernetes.io/name=pricing
kubectl delete rs -l app.kubernetes.io/name=pricing --wait=false
sleep 3
kubectl get rs,pods -l app.kubernetes.io/name=pricing
kubectl describe deploy pricing | sed -n '/^Events:/,$p'
kubectl delete -f /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/lab-docker-kubernetes-20261006-0213/02-t3-t5/f08m/
