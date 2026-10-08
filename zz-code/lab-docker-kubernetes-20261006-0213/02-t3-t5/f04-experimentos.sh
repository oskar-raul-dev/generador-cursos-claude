#!/bin/bash
# Experimentos de la F04 después de B-04. Todo etiquetado como lab-f04/*.
S=/Users/oskar/Developer/Learning/courses-ia-generated/zz-code/lab-docker-kubernetes-20261006-0213/02-t3-t5; LAB=/Users/oskar/Developer/Learning/courses-ia-generated/cursos-contenedores-cloud-infra/lab-docker-kubernetes/src/lab
set -x
cd $LAB
# a) Tamaños de G0 (una etapa), con los Dockerfile de la Fase 02 guardados
for s in pricing inventory catalog replenish storefront; do
  docker build -q --label curso=lab-docker-kubernetes -t lab-f04/$s-g0 -f $S/$s.Dockerfile.g0 services/$s >/dev/null
  dive lab-f04/$s-g0 --json $S/dive-$s-g0.json >/dev/null 2>&1
  u=$(python3 -c "import json;print(round(json.load(open('$S/dive-$s-g0.json'))['image']['sizeBytes']/1e6,1))")
  v=$(docker save lab-f04/$s-g0 | wc -c); echo "G0 $s descomprimida ${u} MB viaja $((v/1000000)) MB"
  docker run --rm --entrypoint id lab-f04/$s-g0 2>&1 | head -1
done
# b) Orden de instrucciones con replenish: COPY . . antes de npm ci
mkdir -p $S/orden && cp -R services/replenish/. $S/orden/
cat > $S/orden/Dockerfile <<'EOD'
FROM node@sha256:ebfe2f90462722a7a4de65e91990e97fe0d401c70e0e762c5b53302f905ec1c1 AS build
WORKDIR /app
COPY . .
RUN npm ci
RUN npm run build
FROM node@sha256:ebfe2f90462722a7a4de65e91990e97fe0d401c70e0e762c5b53302f905ec1c1
WORKDIR /app
COPY --from=build /app /app
USER node
CMD ["node", "dist/main.js"]
EOD
docker build -q -t lab-f04/replenish-orden $S/orden >/dev/null
for i in 1 2 3; do echo "// cambio $i" >> $S/orden/src/replenishment-orders.controller.ts; /usr/bin/time -p docker build -q -t lab-f04/replenish-orden $S/orden 2>&1 | grep real; done
# c) .dockerignore: tocar CLAUDE.md con y sin la línea que lo excluye
mkdir -p $S/ignore && cp -R services/replenish/. $S/ignore/
docker build -q -t lab-f04/replenish-ignore $S/ignore >/dev/null
for i in 1 2 3; do echo "nota $i" >> $S/ignore/CLAUDE.md; /usr/bin/time -p docker build -q -t lab-f04/replenish-ignore $S/ignore 2>&1 | grep real; done
grep -v CLAUDE.md $S/ignore/.dockerignore > $S/ignore/.di && mv $S/ignore/.di $S/ignore/.dockerignore
docker build -q -t lab-f04/replenish-ignore $S/ignore >/dev/null
for i in 1 2 3; do echo "nota sin ignore $i" >> $S/ignore/CLAUDE.md; /usr/bin/time -p docker build -q -t lab-f04/replenish-ignore $S/ignore 2>&1 | grep real; done
# d) nginx de catalog sin compartir la red
docker run -d --name f04-fpm --label curso=lab-docker-kubernetes lab/catalog >/dev/null
docker run -d --name f04-nginx --label curso=lab-docker-kubernetes -p 127.0.0.1:18405:8080 -v $LAB/services/catalog/nginx.conf:/etc/nginx/conf.d/default.conf:ro nginxinc/nginx-unprivileged@sha256:ed04ec1ff34502c339ee5c3ae3f855442398edc1d05591e2b98981dcbbd20b1e >/dev/null
sleep 3; curl -s -i http://127.0.0.1:18405/products | head -1; docker logs f04-nginx 2>&1 | grep error | tail -1
docker rm -f f04-fpm f04-nginx >/dev/null
