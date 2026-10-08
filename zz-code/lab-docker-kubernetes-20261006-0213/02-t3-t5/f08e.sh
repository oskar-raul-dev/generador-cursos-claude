set -x
kubectl apply -f /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/lab-docker-kubernetes-20261006-0213/02-t3-t5/f08m/
kubectl rollout status deploy/pricing --timeout=60s
kubectl explain deployment.spec.selector
kubectl get deploy pricing -o jsonpath='{range .status.conditions[*]}{.type}{"\t"}{.status}{"\t"}{.reason}{"\t"}{.message}{"\n"}{end}'
kubectl get deploy pricing -o jsonpath='{.metadata.generation} {.status.observedGeneration} {.status.replicas} {.status.readyReplicas}{"\n"}'
kubectl diff -f /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/lab-docker-kubernetes-20261006-0213/02-t3-t5/f08m2/
kubectl apply -f /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/lab-docker-kubernetes-20261006-0213/02-t3-t5/f08m2/
kubectl get deploy pricing -o jsonpath='{.metadata.generation} {.status.observedGeneration} {.status.replicas} {.status.readyReplicas}{"\n"}'
kubectl rollout status deploy/pricing --timeout=60s
kubectl get pods -l app.kubernetes.io/name=pricing
kubectl get endpointslices -l kubernetes.io/service-name=pricing
kubectl delete -f /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/lab-docker-kubernetes-20261006-0213/02-t3-t5/f08m/
