#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENVOY_GATEWAY_VERSION="${1:-v1.6.0}"

echo "============================================"
echo " Envoy Gateway Installer (Cluster-Level)"
echo " Version: ${ENVOY_GATEWAY_VERSION}"
echo "============================================"

# ============================================================================
# Step 1: Install Envoy Gateway Operator (if not already installed)
# ============================================================================
echo ""
echo "--- Step 1/2: Envoy Gateway Operator ---"

if helm status eg -n envoy-gateway-system &>/dev/null; then
    echo "[INFO] Envoy Gateway is already installed. Checking version..."
    CURRENT=$(helm get metadata eg -n envoy-gateway-system -o json | grep -o '"version":"[^"]*"' | head -1)
    echo "[INFO] Current: ${CURRENT}"
    echo "[INFO] Skipping install. To upgrade, run: helm upgrade eg oci://docker.io/envoyproxy/gateway-helm --version ${ENVOY_GATEWAY_VERSION} -n envoy-gateway-system"
else
    echo "[INFO] Installing Envoy Gateway ${ENVOY_GATEWAY_VERSION}..."
    helm install eg oci://docker.io/envoyproxy/gateway-helm \
        --version "${ENVOY_GATEWAY_VERSION}" \
        -n envoy-gateway-system \
        --create-namespace
fi

echo "[INFO] Waiting for Envoy Gateway controller to be ready..."
kubectl wait --timeout=5m -n envoy-gateway-system deployment/envoy-gateway --for=condition=Available

# ============================================================================
# Step 2: Apply EnvoyProxy + GatewayClass (cluster-wide resources)
# ============================================================================
echo ""
echo "--- Step 2/2: EnvoyProxy + GatewayClass ---"

echo "[INFO] Applying EnvoyProxy + GatewayClass from eg-infra.yaml..."
kubectl apply -f "${SCRIPT_DIR}/eg-infra.yaml"

echo ""
echo "[INFO] Envoy Gateway installation complete!"
echo "[INFO] GatewayClass 'envoy-gateway' is ready for use."
echo "[INFO] The Gateway resource (namespace-scoped) is managed by the application Helm chart."
