#!/bin/bash
# Mide cuánto sube la memoria de la VM con la segunda cadena: tres corridas, 60 s de reposo.
cd /Users/oskar/Developer/Learning/courses-ia-generated/cursos-contenedores-cloud-infra/lab-docker-kubernetes/src/lab
K="kubectl --context kind-minimo"
used() { docker exec minimo-control-plane awk '/MemTotal/{t=$2}/MemAvailable/{a=$2}END{printf "%d", (t-a)/1024}' /proc/meminfo; }
for run in 1 2 3; do
  helm --kube-context kind-minimo -n apps-b uninstall tenant-b --wait >/dev/null 2>&1
  $K -n apps-b delete job --all --wait >/dev/null 2>&1
  $K -n apps-b wait --for=delete pod --all --timeout=120s >/dev/null 2>&1
  sleep 60; before=$(used)
  start=$(date +%s); task deploy TENANT=tenant-b -- minimo >/dev/null 2>&1; rc=$?; ready=$(( $(date +%s) - start ))
  sleep 60; after=$(used)
  ws=$($K -n apps-b get pods --no-headers 2>/dev/null | grep -c Running)
  echo "corrida $run: deploy rc=$rc en ${ready}s; VM antes ${before} MiB, después ${after} MiB, suma $((after-before)) MiB; pods Running: $ws"
done
