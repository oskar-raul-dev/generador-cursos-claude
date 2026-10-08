#!/bin/zsh
# B-00 sexta entrega: memoria de la VM y de cada pieza, apagada y encendida, tres ciclos.
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-contenedores-cloud-infra/lab-docker-kubernetes/src/lab
S=/Users/oskar/Developer/Learning/courses-ia-generated/zz-code/lab-docker-kubernetes-20261006-0213/03-t6-t10
vm() { docker exec lab-control-plane awk '/^MemTotal/{t=$2} /^MemAvailable/{a=$2} END {printf "%d", (t-a)/1024}' /proc/meminfo; }
piece() { for n in lab-control-plane lab-worker lab-worker2; do python3 $S/mem.py $n observability; done; }
for i in 1 2 3; do
  task obs:off PROFILE=minimo CLUSTER=lab -- all >/dev/null 2>&1
  kubectl --context kind-lab -n observability wait --for=delete pod --all --timeout=120s >/dev/null 2>&1
  sleep 60; echo "ciclo $i · apagada · vm_usada_MiB=$(vm)"
  task obs:on PROFILE=minimo CLUSTER=lab -- metrics >/dev/null 2>&1
  sleep 60; echo "ciclo $i · solo Prometheus · vm_usada_MiB=$(vm)"; piece
  task obs:on PROFILE=minimo CLUSTER=lab -- dashboards >/dev/null 2>&1
  sleep 60; echo "ciclo $i · Prometheus y Grafana · vm_usada_MiB=$(vm)"; piece
done
