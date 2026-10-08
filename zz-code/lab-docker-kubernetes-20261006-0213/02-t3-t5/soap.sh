#!/bin/bash
# soap.sh <operación> <xml de parámetros>: llama al StockService de Contingencia desde su propio pod.
PASS=$(kubectl --context kind-minimo -n legacy get secret portal-contingencia -o jsonpath='{.data.CONTINGENCIA_SOAP_PASSWORD}' | base64 -d)
BODY="<S:Envelope xmlns:S=\"http://schemas.xmlsoap.org/soap/envelope/\" xmlns:c=\"http://soap.contingencia.coodrosan.co/\"><S:Body><c:$1>$2</c:$1></S:Body></S:Envelope>"
kubectl --context kind-minimo -n legacy exec deploy/contingencia -c fachada -- curl -sS -u "portal:$PASS" -H 'Content-Type: text/xml; charset=utf-8' -d "$BODY" http://127.0.0.1:8080/StockService/StockService | grep -o '<return>[^<]*</return>\|<faultstring>[^<]*</faultstring>'
