#!/bin/zsh
# Autopsia F17: series y memoria de Prometheus antes y después de etiquetar pricing con la ruta cruda.
S=/Users/oskar/Developer/Learning/courses-ia-generated/zz-code/lab-docker-kubernetes-20261006-0213/03-t6-t10
q() { python3 $S/promq.py "$1"; }
foto() {
  echo "## $1 · $(date +%H:%M:%S)"
  echo -n "series totales:   "; q 'prometheus_tsdb_head_series' | awk '{print $1}'
  echo -n "series de pricing: "; q 'count({service="pricing"})' | awk '{print $1}'
  echo -n "memoria Prometheus (MiB, cAdvisor): "; q 'sum(container_memory_working_set_bytes{namespace="observability",container="prometheus"})/1048576' | awk '{print $1}'
  echo -n "memoria Prometheus (MiB, go heap):  "; q 'go_memstats_heap_inuse_bytes{job="prometheus"}/1048576' | awk '{print $1}'
}
foto "$1"
