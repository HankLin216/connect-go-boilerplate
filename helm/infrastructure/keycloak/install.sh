#!/bin/bash
set -e

KEYCLOAK_VERSION="${1:-26.0.0}"
NAMESPACE="${2:-connect-go}"
BASE_URL="https://raw.githubusercontent.com/keycloak/keycloak-k8s-resources/${KEYCLOAK_VERSION}/kubernetes"

echo "============================================"
echo " Keycloak Operator Installer"
echo " Version: ${KEYCLOAK_VERSION}"
echo " Namespace: ${NAMESPACE}"
echo "============================================"

# --- 1. Check if CRDs already exist ---
if kubectl get crd keycloaks.k8s.keycloak.org &>/dev/null; then
    echo "[INFO] Keycloak CRDs already exist. Skipping CRD install."
else
    echo "[INFO] Installing Keycloak CRDs..."
    kubectl apply -f "${BASE_URL}/keycloaks.k8s.keycloak.org-v1.yml"
    kubectl apply -f "${BASE_URL}/keycloakrealmimports.k8s.keycloak.org-v1.yml"
    echo "[INFO] CRDs installed."
fi

# --- 2. Create namespace ---
kubectl create namespace "${NAMESPACE}" --dry-run=client -o yaml | kubectl apply -f -

# --- 3. Check if operator is running ---
if kubectl get deployment keycloak-operator -n "${NAMESPACE}" &>/dev/null; then
    echo "[INFO] Keycloak Operator already deployed in namespace '${NAMESPACE}'. Skipping."
else
    echo "[INFO] Deploying Keycloak Operator to namespace '${NAMESPACE}'..."
    kubectl apply -f "${BASE_URL}/kubernetes.yml" --namespace "${NAMESPACE}"
    echo "[INFO] Waiting for Keycloak Operator to be ready..."
    kubectl wait --timeout=3m -n "${NAMESPACE}" deployment/keycloak-operator --for=condition=Available
fi

echo ""
echo "[INFO] Keycloak Operator installation complete!"
