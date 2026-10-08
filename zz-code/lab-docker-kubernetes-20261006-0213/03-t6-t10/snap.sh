#!/bin/zsh
# Foto de memoria: contenedores de apps y observability en los tres nodos, y el total de cada nodo.
echo "# $1 · $(date '+%d/%m/%Y %H:%M:%S')"
for ns in apps observability; do
  for n in lab-control-plane lab-worker lab-worker2; do python3 /Users/oskar/Developer/Learning/courses-ia-generated/zz-code/lab-docker-kubernetes-20261006-0213/03-t6-t10/mem.py $n $ns; done | sort | awk -v ns=$ns '{print; s+=$3} END {printf "TOTAL %-34s %7.1f MiB\n", ns, s}'
done
docker stats --no-stream --format '{{.Name}} {{.MemUsage}}' lab-control-plane lab-worker lab-worker2
