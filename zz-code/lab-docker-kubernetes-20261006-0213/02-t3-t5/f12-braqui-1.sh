K="kubectl --context kind-minimo"
S=/Users/oskar/Developer/Learning/courses-ia-generated/zz-code/lab-docker-kubernetes-20261006-0213/02-t3-t5/soap.sh
PSQL="$K -n legacy exec deploy/contingencia-db -- psql -U contingencia -d contingencia -c"
set -x
for i in braqui braqui-traslados; do kind load docker-image lab/legacy-$i:a16 --name minimo 2>&1 | grep -v "^using"; done
$K apply -f deploy/legacy/traslados-pvc.yaml -f deploy/legacy/contingencia.yaml -f deploy/legacy/braqui.yaml -f deploy/legacy/antes-de-la-fase-12/braqui-traslados.yaml
$K -n legacy rollout status deploy/contingencia --timeout=300s
$K -n legacy rollout status deploy/braqui --timeout=120s
$K -n legacy rollout status deploy/braqui-traslados-cron --timeout=120s
$K -n legacy get pvc traslados
set +x
until $K -n legacy exec deploy/contingencia -c fachada -- curl -sf -o /dev/null 'http://127.0.0.1:8080/StockService/StockService?wsdl'; do sleep 3; done
echo "=== $(date +%T) Contingencia contesta SOAP"
set -x
: === una venta a domicilio en Contingencia: la Braqui la ve en sus tablas
$S registerSale '<sku>SKU-0001</sku><storeId>DRO-007</storeId><quantity>1</quantity><deliveryAddress>Calle 63 # 9-41, Chapinero</deliveryAddress>'
sleep 35
$K -n legacy logs deploy/braqui | tail -3
$PSQL "SELECT id, store_id, status, rider_id FROM dispatch ORDER BY id DESC LIMIT 2"
: === el Núcleo renombra una columna de su tabla
$PSQL "ALTER TABLE dispatch RENAME COLUMN address TO delivery_address"
$S registerSale '<sku>SKU-0001</sku><storeId>DRO-007</storeId><quantity>1</quantity><deliveryAddress>Carrera 7 # 72-10</deliveryAddress>'
sleep 35
$K -n legacy logs deploy/braqui | tail -2
$PSQL "ALTER TABLE dispatch RENAME COLUMN delivery_address TO address"
