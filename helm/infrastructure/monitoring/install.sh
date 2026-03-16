#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NAMESPACE="${1:-connect-go}"
PROMETHEUS_STACK_VERSION="${2:-72.6.2}"
RELEASE_NAME_STACK="kube-prometheus-stack"
RELEASE_NAME_ROUTES="connect-go-monitoring"
OCI_CHART="oci://ghcr.io/prometheus-community/charts/kube-prometheus-stack"

echo "============================================"
echo " Prometheus Stack + Monitoring Routes Installer"
echo " (Prometheus + Grafana + Alertmanager)"
echo " Namespace:     ${NAMESPACE}"
echo " Stack Version: ${PROMETHEUS_STACK_VERSION}"
echo "============================================"

# ============================================================================
# Step 1: Install kube-prometheus-stack (if not already installed)
# ============================================================================
echo ""
echo "--- Step 1/2: kube-prometheus-stack ---"

if helm status "${RELEASE_NAME_STACK}" -n "${NAMESPACE}" &>/dev/null; then
    echo "[INFO] kube-prometheus-stack is already installed. Upgrading..."
else
    echo "[INFO] Installing kube-prometheus-stack (OCI: ${OCI_CHART})..."
fi

helm upgrade --install "${RELEASE_NAME_STACK}" "${OCI_CHART}" \
    --version "${PROMETHEUS_STACK_VERSION}" \
    -n "${NAMESPACE}" \
    --create-namespace \
    --set grafana.enabled=true \
    --set grafana.adminPassword=admin \
    --set "grafana.grafana\.ini.server.root_url=http://localhost:30080/grafana" \
    --set "grafana.grafana\.ini.server.serve_from_sub_path=true" \
    --set grafana.serviceMonitor.enabled=true \
    --set grafana.serviceMonitor.path=/grafana/metrics \
    --set prometheus.prometheusSpec.routePrefix=/prometheus \
    --set prometheus.prometheusSpec.externalUrl=http://localhost:30080/prometheus \
    --set prometheus.prometheusSpec.serviceMonitorSelectorNilUsesHelmValues=false \
    --set prometheus.prometheusSpec.podMonitorSelectorNilUsesHelmValues=false

echo "[INFO] Waiting for Prometheus stack to be ready..."
kubectl wait --timeout=5m -n "${NAMESPACE}" deployment/${RELEASE_NAME_STACK}-grafana --for=condition=Available 2>/dev/null || true
kubectl wait --timeout=5m -n "${NAMESPACE}" deployment/${RELEASE_NAME_STACK}-kube-state-metrics --for=condition=Available 2>/dev/null || true

echo "[INFO] kube-prometheus-stack is ready."

# ============================================================================
# Step 2: Install Monitoring Helm chart (HTTPRoutes + ServiceMonitor)
# ============================================================================
echo ""
echo "--- Step 2/2: Monitoring Routes (Helm chart) ---"

if helm status "${RELEASE_NAME_ROUTES}" -n "${NAMESPACE}" &>/dev/null; then
    echo "[INFO] Monitoring routes chart '${RELEASE_NAME_ROUTES}' is already installed. Upgrading..."
else
    echo "[INFO] Installing monitoring routes chart..."
fi

helm upgrade --install "${RELEASE_NAME_ROUTES}" "${SCRIPT_DIR}" \
    -n "${NAMESPACE}" \
    --create-namespace

echo ""
echo "[INFO] Prometheus Stack + Monitoring Routes installation complete!"
echo "[INFO] Grafana will be accessible via Envoy Gateway at /grafana"
echo "[INFO] Prometheus will be accessible via Envoy Gateway at /prometheus"
