K="kubectl --context kind-minimo"
set -x
$K apply -f deploy/legacy/contingencia.yaml
$K -n legacy rollout status deploy/contingencia --timeout=180s
$K -n legacy exec deploy/portal -- php artisan catalog:sync
set +x
echo "=== incidente 10, con delete pod"
task inc:break -- 10
sleep 15
set -x
$K -n legacy get pods -l app.kubernetes.io/name=portal
$K -n legacy describe pod -l app.kubernetes.io/name=portal > /tmp/describe-portal.txt 2>&1; sed -n '/^Events:/,$p' /tmp/describe-portal.txt | tail -5; rm -f /tmp/describe-portal.txt
$K -n legacy get pods -l app.kubernetes.io/name=contingencia
set +x
T0=$(date +%s)
task inc:fix -- 10
until [ "$($K -n legacy get pods -l app.kubernetes.io/name=portal -o jsonpath='{.items[0].status.containerStatuses[0].ready}')" = "true" ]; do sleep 1; done
echo "listo $(( $(date +%s) - T0 )) s después de crear el Secret, sin reiniciar nada"
set -x
$K -n legacy get pods -l app.kubernetes.io/name=portal
$K -n legacy exec deploy/portal -- php artisan catalog:sync
