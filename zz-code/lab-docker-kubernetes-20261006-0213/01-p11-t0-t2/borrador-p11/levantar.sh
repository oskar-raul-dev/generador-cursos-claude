#!/usr/bin/env bash
# Script de P11 (no es del curso): cluster + Envoy Gateway + Gateway de prueba + confianza en el registry.
set -euo pipefail
perfil=${1:-minimo}
cd "$(dirname "$0")"
KIND_EXPERIMENTAL_PROVIDER=${ENGINE:-docker} kind create cluster --config "kind/cluster-$perfil.yaml"
ctx="kind-$perfil"
for n in $(KIND_EXPERIMENTAL_PROVIDER=${ENGINE:-docker} kind get nodes --name "$perfil"); do
  ${ENGINE:-docker} exec "$n" mkdir -p /etc/containerd/certs.d/lab-registry:5000
  ${ENGINE:-docker} cp registry/certs/ca.crt "$n":/etc/containerd/certs.d/lab-registry:5000/ca.crt
  printf '[host."https://lab-registry:5000"]\n  ca = "/etc/containerd/certs.d/lab-registry:5000/ca.crt"\n' | ${ENGINE:-docker} exec -i "$n" tee /etc/containerd/certs.d/lab-registry:5000/hosts.toml >/dev/null
done
helm install eg oci://docker.io/envoyproxy/gateway-helm --version v1.9.2 -n gateway --create-namespace --kube-context "$ctx" --wait --timeout 5m >/dev/null
kubectl --context "$ctx" apply -f envoyproxy-nodeport.yaml
kubectl --context "$ctx" apply -f gateway-prueba.yaml
kubectl --context "$ctx" -n apps rollout status deploy/pricing --timeout=180s
kubectl --context "$ctx" -n gateway wait --for=condition=Programmed gateway/lab --timeout=180s
