#!/bin/sh
# 60 lecturas seguidas por la puerta a $1; imprime la mediana y el p90 en ms (las 10 primeras no cuentan).
for i in $(seq 70); do curl -s -o /dev/null -m 20 -w '%{time_total}\n' "$1"; done | tail -60 | sort -n | awk '{a[NR]=$1*1000} END {printf "mediana %.1f ms · p90 %.1f ms · máx %.1f ms (n=%d)\n", a[int(NR/2)], a[int(NR*0.9)], a[NR], NR}'
