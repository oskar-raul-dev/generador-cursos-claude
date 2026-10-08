K="kubectl --context kind-minimo"
set -x
$K -n legacy get secret portal-contingencia -o jsonpath='{.data.CONTINGENCIA_SOAP_PASSWORD}'; echo
$K -n legacy get secret portal-contingencia -o jsonpath='{.data.CONTINGENCIA_SOAP_PASSWORD}' | base64 -d; echo
$K -n legacy exec deploy/portal -- printenv CONTINGENCIA_SOAP_PASSWORD
$K -n legacy exec deploy/portal -- grep SOAP_PASSWORD .env
$K -n legacy exec deploy/portal -- php artisan config:show services.contingencia
$K -n legacy exec deploy/portal -- php artisan catalog:sync
docker run --rm --entrypoint grep lab/legacy-portal:a16 SOAP_PASSWORD .env
set +x
echo "=== incidente 10"
task inc:break -- 10
sleep 15
set -x
$K -n legacy get pods -l app.kubernetes.io/name=portal
$K -n legacy describe pod -l app.kubernetes.io/name=portal | sed -n '/^Events:/,$p' | tail -6
$K -n legacy logs deploy/portal --tail=3
set +x
T0=$(date +%s)
task inc:fix -- 10
until $K -n legacy get pods -l app.kubernetes.io/name=portal -o jsonpath='{range .items[*]}{.status.phase} {.status.containerStatuses[0].ready}{"\n"}{end}' | grep -q "^Running true$"; do sleep 1; done
echo "listo en $(( $(date +%s) - T0 )) s, sin reiniciar nada"
set -x
$K -n legacy get pods -l app.kubernetes.io/name=portal
