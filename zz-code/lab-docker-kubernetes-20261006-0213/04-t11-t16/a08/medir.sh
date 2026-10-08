#!/bin/bash
# medir.sh <nombre> <args de docker run…>: listo, memoria en reposo y después de 1000 peticiones, 3 corridas
name=$1; shift
t() { python3 -c 'import time; print(time.time())'; }
echo "== $name · imagen $(docker image inspect "${@: -1}" --format '{{.Size}}') bytes"
for run in 1 2 3; do
  s=$(t); docker run -d --name a08-run --label curso=lab-docker-kubernetes -p 127.0.0.1:18180:8080 "$@" >/dev/null
  n=0; until [ "$(curl -s -o /dev/null -w '%{http_code}' http://127.0.0.1:18180/health/ready)" = "200" ] || [ $n -gt 600 ]; do sleep 0.05; n=$((n+1)); done
  e=$(t); sleep 10; m1=$(docker stats --no-stream --format '{{json .}}' a08-run | python3 -c 'import json,sys; print(json.load(sys.stdin)["MemUsage"].split(" ")[0])')
  for k in $(seq 1 500); do
    curl -s -o /dev/null -X POST http://127.0.0.1:18180/stock/DRO-001/SKU-0001/movements -H 'Content-Type: application/json' -d '{"type":"RESTOCK","quantity":1}'
    curl -s -o /dev/null http://127.0.0.1:18180/stock/DRO-001/SKU-0001
  done
  m2=$(docker stats --no-stream --format '{{json .}}' a08-run | python3 -c 'import json,sys; print(json.load(sys.stdin)["MemUsage"].split(" ")[0])'); q=$(curl -s http://127.0.0.1:18180/stock/DRO-001/SKU-0001)
  docker rm -f a08-run >/dev/null
  echo "corrida $run · listo en $(python3 -c "print(f'{$e-$s:.2f}')") s · reposo ${m1} | después de 1000 peticiones ${m2} | $q"
done
