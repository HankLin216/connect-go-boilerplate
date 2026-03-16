#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NAMESPACE="${1:-connect-go}"
RELEASE_NAME="connect-go-tracing"

echo "============================================"
echo " Tracing Stack Installer"
echo " (Jaeger + OpenTelemetry Collector)"
echo " Namespace: ${NAMESPACE}"
echo "============================================"

if helm status "${RELEASE_NAME}" -n "${NAMESPACE}" &>/dev/null; then
    echo "[INFO] Tracing chart '${RELEASE_NAME}' is already installed. Upgrading..."
else
    echo "[INFO] Installing tracing chart..."
fi

helm upgrade --install "${RELEASE_NAME}" "${SCRIPT_DIR}" \
    -n "${NAMESPACE}" \
    --create-namespace

echo ""
echo "[INFO] Tracing stack installation complete!"
echo "[INFO] Jaeger UI will be accessible via Envoy Gateway at /jaeger"
echo "[INFO] OTel Collector is receiving traces on otel-collector:4317"
