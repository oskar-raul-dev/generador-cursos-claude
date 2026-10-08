set -u
K="kubectl --context kind-lab"
echo '$ kubectl -n apps get pods -o wide'; $K -n apps get pods -o wide | head -4
echo; echo '$ kubectl -n apps get deploy -o custom-columns=NAME:.metadata.name,IMAGE:.spec.template.spec.containers[0].image'
$K -n apps get deploy -o custom-columns=NAME:.metadata.name,IMAGE:.spec.template.spec.containers[0].image
echo; echo "\$ kubectl -n apps get deploy inventory -o jsonpath='{.metadata.generation} {.status.observedGeneration} {.status.replicas} {.status.readyReplicas}{\"\\n\"}'"
$K -n apps get deploy inventory -o jsonpath='{.metadata.generation} {.status.observedGeneration} {.status.replicas} {.status.readyReplicas}{"\n"}'
echo; echo "\$ kubectl -n apps get pod -l app.kubernetes.io/name=inventory -o jsonpath='{range .items[0].spec.containers[*]}{.name}{\"  \"}{.image}{\"\\n\"}{end}'"
$K -n apps get pod -l app.kubernetes.io/name=inventory -o jsonpath='{range .items[0].spec.containers[*]}{.name}{"  "}{.image}{"\n"}{end}'
$K -n apps get pod -l app.kubernetes.io/name=inventory -o jsonpath='{range .items[0].spec.initContainers[*]}{.name}{"  "}{.image}{"  restartPolicy="}{.restartPolicy}{"\n"}{end}'
echo; echo "\$ kubectl -n apps get httproute -o jsonpath='{range .items[*]}{.metadata.name}: {range .status.parents[*].conditions[*]}{.type}={.status} {end}{\"\\n\"}{end}'"
$K -n apps get httproute -o jsonpath='{range .items[*]}{.metadata.name}: {range .status.parents[*].conditions[*]}{.type}={.status} {end}{"\n"}{end}'
echo; echo "\$ kubectl get pods -A -o custom-columns=NS:.metadata.namespace,POD:.metadata.name,QOS:.status.qosClass | sort -k3 | head"
$K get pods -A -o custom-columns=NS:.metadata.namespace,POD:.metadata.name,QOS:.status.qosClass --no-headers | awk '{print $3}' | sort | uniq -c
echo; echo '$ kubectl -n apps get deploy inventory -o yaml | grep -n "image:\|resources:" | head'
$K -n apps get deploy inventory -o yaml | grep -c "" 
