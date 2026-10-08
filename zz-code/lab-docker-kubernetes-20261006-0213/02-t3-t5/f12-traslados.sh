K="kubectl --context kind-minimo"
S=/Users/oskar/Developer/Learning/courses-ia-generated/zz-code/lab-docker-kubernetes-20261006-0213/02-t3-t5/soap.sh
PSQL="$K -n legacy exec deploy/contingencia-db -- psql -U contingencia -d contingencia -tA -c"
espera_archivo() { until [ -n "$($K -n legacy exec deploy/contingencia -c contingencia -- sh -c 'ls /var/lib/contingencia/traslados/*.ok 2>/dev/null')" ]; do sleep 5; done; }
listado() { $K -n legacy exec deploy/contingencia -c contingencia -- sh -c 'cd /var/lib/contingencia/traslados && ls -1 *.txt procesados/*.txt 2>/dev/null'; }
echo "=== $(date +%T) préstamo 1: dos inhaladores de Girón (DRO-003) a Chapinero (DRO-007)"
$S requestLoan '<sku>SKU-0003</sku><originStore>DRO-003</originStore><destinationStore>DRO-007</destinationStore><quantity>2</quantity>'
espera_archivo; echo "=== $(date +%T) Contingencia dejó el archivo:"; listado
sleep 75
echo "=== $(date +%T) el log del aviso (cron, cada minuto):"; $K -n legacy logs deploy/braqui-traslados-cron | tail -2
listado
echo "=== $(date +%T) una corrida muere a la mitad: deja su bloqueo (se simula creando el archivo que dejaría)"
$K -n legacy exec deploy/braqui-traslados-cron -- touch /var/lib/braqui/traslados.lock
echo "=== $(date +%T) préstamo 2"
$S requestLoan '<sku>SKU-0003</sku><originStore>DRO-003</originStore><destinationStore>DRO-007</destinationStore><quantity>1</quantity>'
espera_archivo; echo "=== $(date +%T) archivo nuevo:"; listado
sleep 150
echo "=== $(date +%T) dos minutos y medio después: el log no dice nada nuevo, y el archivo sigue ahí"
$K -n legacy logs deploy/braqui-traslados-cron | tail -2
listado
echo "=== $(date +%T) reiniciar el contenedor (lo que haría cualquiera): kill 1"
$K -n legacy exec deploy/braqui-traslados-cron -- kill 1
sleep 100
$K -n legacy get pods -l app.kubernetes.io/name=braqui-traslados-cron
$K -n legacy exec deploy/braqui-traslados-cron -- ls -l /var/lib/braqui/
listado
echo "=== $(date +%T) traslados en la base de la Braqui:"; $PSQL "SELECT file_name, count(*) FROM braqui_transfer GROUP BY file_name ORDER BY 1"
echo "=== $(date +%T) el CronJob en su lugar"
$K -n legacy delete -f deploy/legacy/antes-de-la-fase-12/braqui-traslados.yaml --wait
$K apply -f deploy/legacy/traslados-cronjob.yaml
sleep 100
$K -n legacy get cronjob braqui-traslados
$K -n legacy get jobs -l app.kubernetes.io/name=braqui-traslados
for j in $($K -n legacy get jobs -l app.kubernetes.io/name=braqui-traslados -o name); do echo "--- $j"; $K -n legacy logs $j; done
listado
echo "=== $(date +%T) traslados en la base de la Braqui:"; $PSQL "SELECT file_name, count(*) FROM braqui_transfer GROUP BY file_name ORDER BY 1"
