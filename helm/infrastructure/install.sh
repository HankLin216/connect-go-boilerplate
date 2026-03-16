#!/bin/bash
set -e

# ============================================================================
# Infrastructure Installer
#
# For fresh environments (no existing infra):
#   bash helm/infrastructure/install.sh
#   → Installs everything with default settings.
#
# For existing environments (selective install):
#   bash helm/infrastructure/install.sh --select
#   → Prompts you to choose which components to install.
#
# Individual components can also be installed directly:
#   bash helm/infrastructure/envoy-gateway/install.sh
#   bash helm/infrastructure/keycloak/install.sh [VERSION] [NAMESPACE]
#   bash helm/infrastructure/elk/install.sh [NAMESPACE]
#   bash helm/infrastructure/monitoring/install.sh [NAMESPACE]
#   bash helm/infrastructure/tracing/install.sh [NAMESPACE]
#
# After infrastructure is ready, install the application chart:
#   helm upgrade --install connect-go-boilerplate ./helm/connect-go-boilerplate \
#     --namespace <APP_NAMESPACE> --create-namespace
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SELECT_MODE=false
APP_NAMESPACE="connect-go"

# Parse arguments
for arg in "$@"; do
    case $arg in
        --select)
            SELECT_MODE=true
            ;;
        --namespace=*)
            APP_NAMESPACE="${arg#*=}"
            ;;
        *)
            APP_NAMESPACE="$arg"
            ;;
    esac
done

# --------------------------------------------------------------------------
# Helper: ask user whether to install a component (only in --select mode)
# Returns 0 (yes) or 1 (no)
# --------------------------------------------------------------------------
should_install() {
    local component="$1"
    local status="$2"  # "installed" or "not found"

    if [ "$SELECT_MODE" = false ]; then
        return 0  # Install everything in default mode
    fi

    if [ "$status" = "installed" ]; then
        echo ""
        read -r -p "[?] ${component} is already installed. Reinstall/update? [y/N]: " answer
        case "$answer" in
            [yY]|[yY][eE][sS]) return 0 ;;
            *) return 1 ;;
        esac
    else
        echo ""
        read -r -p "[?] Install ${component}? [Y/n]: " answer
        case "$answer" in
            [nN]|[nN][oO]) return 1 ;;
            *) return 0 ;;
        esac
    fi
}

# --------------------------------------------------------------------------
# Detect existing infrastructure
# --------------------------------------------------------------------------
detect_status() {
    local name="$1"
    local check_cmd="$2"
    if eval "$check_cmd" &>/dev/null; then
        echo "installed"
    else
        echo "not found"
    fi
}

ENVOY_STATUS=$(detect_status "Envoy Gateway" "helm status eg -n envoy-gateway-system")
KEYCLOAK_STATUS=$(detect_status "Keycloak Operator" "kubectl get deployment keycloak-operator -n ${APP_NAMESPACE}")
ECK_STATUS=$(detect_status "ECK Operator" "helm status elastic-operator -n elastic-system")
PROMETHEUS_STATUS=$(detect_status "kube-prometheus-stack" "helm status kube-prometheus-stack -n ${APP_NAMESPACE}")
TRACING_STATUS=$(detect_status "Tracing" "helm status connect-go-tracing -n ${APP_NAMESPACE}")

echo "============================================================"
echo " Connect-Go-Boilerplate: Infrastructure Installer"
echo " App Namespace: ${APP_NAMESPACE}"
echo " Mode:          $([ "$SELECT_MODE" = true ] && echo "Selective" || echo "Full Install")"
echo "============================================================"
echo ""
echo " Detected infrastructure:"
echo "   1. Envoy Gateway ........... ${ENVOY_STATUS}"
echo "   2. Keycloak Operator ....... ${KEYCLOAK_STATUS}"
echo "   3. ECK Operator + ELK ...... ${ECK_STATUS}"
echo "   4. Prometheus + Monitoring .. ${PROMETHEUS_STATUS}"
echo "   5. Tracing (Jaeger + OTel) .. ${TRACING_STATUS}"
echo ""

# --- 1. Envoy Gateway ---
if should_install "Envoy Gateway" "$ENVOY_STATUS"; then
    echo ">>> [1/5] Envoy Gateway"
    bash "${SCRIPT_DIR}/envoy-gateway/install.sh" "v1.6.0"
    echo ""
else
    echo ">>> [1/5] Envoy Gateway — skipped"
    echo ""
fi

# --- 2. Keycloak Operator ---
if should_install "Keycloak Operator" "$KEYCLOAK_STATUS"; then
    echo ">>> [2/5] Keycloak Operator"
    bash "${SCRIPT_DIR}/keycloak/install.sh" "26.0.0" "${APP_NAMESPACE}"
    echo ""
else
    echo ">>> [2/5] Keycloak Operator — skipped"
    echo ""
fi

# --- 3. ECK Operator + ELK Stack ---
if should_install "ECK Operator + ELK Stack" "$ECK_STATUS"; then
    echo ">>> [3/5] ECK Operator + ELK Stack"
    bash "${SCRIPT_DIR}/elk/install.sh" "${APP_NAMESPACE}"
    echo ""
else
    echo ">>> [3/5] ECK Operator + ELK Stack — skipped"
    echo ""
fi

# --- 4. Prometheus Stack + Monitoring ---
if should_install "Prometheus + Monitoring" "$PROMETHEUS_STATUS"; then
    echo ">>> [4/5] Prometheus Stack + Monitoring"
    bash "${SCRIPT_DIR}/monitoring/install.sh" "${APP_NAMESPACE}"
    echo ""
else
    echo ">>> [4/5] Prometheus + Monitoring — skipped"
    echo ""
fi

# --- 5. Tracing (Jaeger + OTel Collector) ---
if should_install "Tracing (Jaeger + OTel)" "$TRACING_STATUS"; then
    echo ">>> [5/5] Tracing (Jaeger + OTel Collector)"
    bash "${SCRIPT_DIR}/tracing/install.sh" "${APP_NAMESPACE}"
    echo ""
else
    echo ">>> [5/5] Tracing — skipped"
    echo ""
fi

echo "============================================================"
echo " Infrastructure setup complete!"
echo ""
echo " Next step: Install the application Helm chart"
echo ""
echo "   Option 1 — Using Helm directly:"
echo "     helm upgrade --install connect-go-boilerplate ./helm/connect-go-boilerplate \\"
echo "       --namespace ${APP_NAMESPACE} --create-namespace"
echo ""
echo "   Option 2 — Using Make:"
echo "     make helm-install        # install/upgrade app chart only"
echo "     make full-helm-install   # build image + install app chart"
echo "============================================================"
