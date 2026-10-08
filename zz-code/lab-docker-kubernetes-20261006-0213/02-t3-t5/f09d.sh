NGX=nginxinc/nginx-unprivileged@sha256:ed04ec1ff34502c339ee5c3ae3f855442398edc1d05591e2b98981dcbbd20b1e
kubectl run cliente -n apps --rm --attach --restart=Never --quiet --image=$NGX -- sh -c '
I=http://inventory:8080/stock/DRO-007/SKU-0003
echo "\$ POST COUNT 30"; curl -s -H "Content-Type: application/json" -d "{\"type\":\"COUNT\",\"quantity\":30,\"reference\":\"conteo-lunes\"}" $I/movements; echo
echo "\$ POST RESTOCK 6"; curl -s -H "Content-Type: application/json" -d "{\"type\":\"RESTOCK\",\"quantity\":6,\"reference\":\"RO-0002\"}" $I/movements; echo
echo "\$ POST ADJUSTMENT -2 TRANSFER_LOST"; curl -s -H "Content-Type: application/json" -d "{\"type\":\"ADJUSTMENT\",\"quantity\":-2,\"reasonCode\":\"TRANSFER_LOST\",\"reference\":\"traslados_20261003_0308.txt\"}" $I/movements; echo
echo "\$ POST COUNT 31"; curl -s -H "Content-Type: application/json" -d "{\"type\":\"COUNT\",\"quantity\":31,\"reference\":\"conteo-martes\"}" $I/movements; echo
echo "\$ GET"; curl -s $I; echo
echo "\$ PATCH quantity"; curl -s -X PATCH -H "Content-Type: application/merge-patch+json" -d "{\"quantity\":50}" $I; echo' </dev/null 2>/dev/null
