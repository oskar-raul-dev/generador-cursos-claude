K="kubectl --context kind-minimo"
set -x
$K apply -f /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/lab-docker-kubernetes-20261006-0213/02-t3-t5/f11-variantes.yaml
$K -n apps wait --for=condition=Ready pod/variantes --timeout=60s
$K -n apps exec variantes -- sh -c 'echo env=$TOPE carpeta=$(cat /carpeta/TOPE) subpath=$(cat /subpath/TOPE)'
$K -n apps patch configmap variantes --type=merge -p '{"data":{"TOPE":"18000"}}'
set +x
for i in 1 2 3 4 5 6; do sleep 30; echo "t=$((i*30))s $($K -n apps exec variantes -- sh -c 'echo env=$TOPE carpeta=$(cat /carpeta/TOPE) subpath=$(cat /subpath/TOPE)')"; done
set -x
$K -n legacy get pod clave-que-falta
$K -n legacy get events --field-selector involvedObject.name=clave-que-falta -o custom-columns=REASON:.reason,MESSAGE:.message | tail -2
$K delete -f /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/lab-docker-kubernetes-20261006-0213/02-t3-t5/f11-variantes.yaml --wait=false
