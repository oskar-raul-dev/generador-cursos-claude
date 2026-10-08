set -x
task platform:gateway -- minimo
kubectl -n gateway get gatewayclass,gateway
kubectl -n gateway get pods,svc
curl -sS -i -m 5 http://api.localhost:8080/pricing/health/live | head -5
task deploy -- minimo
kubectl -n apps get httproute
kubectl -n apps get httproute pricing -o jsonpath='{range .status.parents[0].conditions[*]}{.type}={.status} {.reason}{"\n"}{end}'
curl -sS -i -m 5 http://api.localhost:8080/pricing/health/live | head -4
curl -sS -m 5 -X PUT -H 'Content-Type: application/json' -d '{"store":"DRO-007","price":21900}' http://api.localhost:8080/pricing/prices/SKU-0003; echo
curl -sS -m 5 'http://api.localhost:8080/pricing/prices/SKU-0003?store=DRO-007'; echo
curl -sS -m 5 -X POST -H 'Content-Type: application/json' -d '{"sku":"SKU-0003","name":"Salbutamol inhalador 100 mcg","category":"venta libre"}' http://api.localhost:8080/catalog/products; echo
curl -sS -m 5 http://api.localhost:8080/catalog/products; echo
curl -sS -m 5 http://storefront.localhost:8080/ | head -7
curl -sS -i -m 5 -X OPTIONS -H 'Origin: http://storefront.localhost:8080' -H 'Access-Control-Request-Method: GET' http://api.localhost:8080/catalog/products | head -12
curl -sS -i -m 5 -H 'Origin: http://storefront.localhost:8080' http://api.localhost:8080/catalog/products | grep -i "access-control\|HTTP/"
curl -sS -i -m 5 -H 'Origin: http://otra.localhost:8080' http://api.localhost:8080/catalog/products | grep -i "access-control\|HTTP/"
curl -sS -i -m 5 http://api.localhost:8080/no-existe | head -3
python3 -c "import socket;print(socket.getaddrinfo('api.localhost',8080)[0][4])"
dscacheutil -q host -a name api.localhost
