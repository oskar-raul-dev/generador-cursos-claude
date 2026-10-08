#!/bin/sh
# Conexiones TCP por estado al puerto $1 (hex) en cada réplica de pricing, leídas desde /proc del nodo.
PORT=$1
for p in $(kubectl --context kind-lab -n apps get pods -l app.kubernetes.io/name=pricing,app.kubernetes.io/component=backend -o jsonpath='{range .items[*]}{.metadata.name},{.spec.nodeName} {end}'); do
  pod=${p%,*}; node=${p#*,}
  cid=$(docker exec $node crictl ps --pod $(docker exec $node crictl pods --name $pod -q) -q | head -1)
  pid=$(docker exec $node crictl inspect --output go-template --template '{{.info.pid}}' $cid)
  docker exec $node sh -c "cat /proc/$pid/net/tcp /proc/$pid/net/tcp6" | awk -v pod=$pod -v port=":$PORT" '$2 ~ port"$" {s[$4]++; if ($4=="01") r=r" "$3} END {printf "%s establecidas=%d time_wait=%d%s\n", pod, s["01"]+0, s["06"]+0, r}'
done
