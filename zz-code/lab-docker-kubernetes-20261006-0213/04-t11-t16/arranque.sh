#!/bin/sh
# arranque.sh <imagen> <plataforma> <ruta>: segundos desde docker run hasta el primer 200, en 127.0.0.1:18180
img=$1; plat=$2; path=$3
s=$(python3 -c 'import time; print(time.time())')
docker run -d --rm --name a06-arranque --label curso=lab-docker-kubernetes --platform $plat -p 127.0.0.1:18180:8080 $img >/dev/null
until [ "$(curl -s -o /dev/null -w '%{http_code}' http://127.0.0.1:18180$path)" = "200" ]; do sleep 0.05; done
e=$(python3 -c 'import time; print(time.time())')
arch=$(docker image inspect $img --format '{{.Architecture}}')
docker rm -f a06-arranque >/dev/null
python3 -c "print(f'{$e - $s:.2f}')"
