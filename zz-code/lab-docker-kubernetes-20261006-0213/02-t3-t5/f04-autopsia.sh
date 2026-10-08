#!/bin/bash
S=/Users/oskar/Developer/Learning/courses-ia-generated/zz-code/lab-docker-kubernetes-20261006-0213/02-t3-t5; LAB=/Users/oskar/Developer/Learning/courses-ia-generated/cursos-contenedores-cloud-infra/lab-docker-kubernetes/src/lab
rm -rf $S/circular && mkdir -p $S/circular && cp $LAB/services/pricing/{Dockerfile,go.mod,main.go} $S/circular/
cd $S/circular
set -x
docker build -q --label curso=lab-docker-kubernetes -t lab-f04/pricing:circular . 
docker run -d --name pricing-circular --label curso=lab-docker-kubernetes -p 127.0.0.1:18406:8080 lab-f04/pricing:circular
sleep 1; curl -s 'http://127.0.0.1:18406/prices/SKU-0003?store=DRO-007'; echo
sed -i '' 's/12900/13500/' main.go
docker build -q --label curso=lab-docker-kubernetes -t lab-f04/pricing:circular .
docker restart pricing-circular
sleep 1; curl -s 'http://127.0.0.1:18406/prices/SKU-0003?store=DRO-007'; echo
docker ps --filter name=pricing-circular --format '{{.Names}}  {{.Image}}  {{.Status}}'
docker inspect pricing-circular --format '{{.Image}}'
docker image inspect lab-f04/pricing:circular --format '{{.Id}}'
docker rm -f pricing-circular
docker run -d --name pricing-circular --label curso=lab-docker-kubernetes -p 127.0.0.1:18406:8080 lab-f04/pricing:circular
sleep 1; curl -s 'http://127.0.0.1:18406/prices/SKU-0003?store=DRO-007'; echo
docker inspect pricing-circular --format '{{.Image}}'
docker rm -f pricing-circular
