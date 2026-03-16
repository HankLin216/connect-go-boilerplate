#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NAMESPACE="${1:-connect-go}"
RELEASE_NAME="connect-go-elk"

echo "============================================"
echo " ECK Operator + ELK Stack Installer"
echo " Namespace: ${NAMESPACE}"
echo "============================================"

# ============================================================================
# Step 1: Install ECK Operator (if not already installed)
# ============================================================================
echo ""
echo "--- Step 1/2: ECK Operator ---"

if helm status elastic-operator -n elastic-system &>/dev/null; then
    echo "[INFO] ECK Operator is already installed."
    echo "[INFO] Skipping install. To upgrade, run: helm upgrade elastic-operator elastic/eck-operator -n elastic-system"
else
    echo "[INFO] Adding Elastic Helm Repo..."
    helm repo add elastic https://helm.elastic.co 2>/dev/null || true
    helm repo update

    echo "[INFO] Installing ECK Operator..."
    helm install elastic-operator elastic/eck-operator \
        -n elastic-system \
        --create-namespace

    echo "[INFO] Waiting for ECK Operator to be ready..."
    kubectl wait --timeout=3m -n elastic-system statefulset/elastic-operator --for=jsonpath='{.status.readyReplicas}'=1 2>/dev/null || \
    kubectl wait --timeout=3m -n elastic-system deployment/elastic-operator --for=condition=Available 2>/dev/null || true
fi

echo "[INFO] ECK Operator is ready."

# ============================================================================
# Step 2: Install ELK Helm chart (ES + Kibana + Logstash + Filebeat)
# ============================================================================
echo ""
echo "--- Step 2/2: ELK Stack (Helm chart) ---"

if helm status "${RELEASE_NAME}" -n "${NAMESPACE}" &>/dev/null; then
    echo "[INFO] ELK chart '${RELEASE_NAME}' is already installed in namespace '${NAMESPACE}'."
    echo "[INFO] Upgrading..."
    helm upgrade "${RELEASE_NAME}" "${SCRIPT_DIR}" \
        -n "${NAMESPACE}"
else
    echo "[INFO] Installing ELK chart..."
    helm install "${RELEASE_NAME}" "${SCRIPT_DIR}" \
        -n "${NAMESPACE}" \
        --create-namespace
fi

echo ""
echo "[INFO] ELK Stack installation complete!"
echo "[INFO] Kibana will be accessible via Envoy Gateway at /kibana"
echo "[INFO] Elasticsearch credentials: elastic / (see values.yaml)"
