#!/bin/bash

KEYCLOAK_VERSION="26.0.0"
BASE_URL="https://raw.githubusercontent.com/keycloak/keycloak-k8s-resources/${KEYCLOAK_VERSION}/kubernetes"

echo "Installing Keycloak CRDs and Operator for version ${KEYCLOAK_VERSION}..."

kubectl apply -f "${BASE_URL}/keycloaks.k8s.keycloak.org-v1.yml"
if [ $? -ne 0 ]; then
    echo "Failed to install Keycloak CRD."
    exit 1
fi

kubectl apply -f "${BASE_URL}/keycloakrealmimports.k8s.keycloak.org-v1.yml"
if [ $? -ne 0 ]; then
    echo "Failed to install Keycloak Realm Import CRD."
    exit 1
fi

kubectl create namespace connect-go --dry-run=client -o yaml | kubectl apply -f -

echo "Applying Keycloak Operator to namespace connect-go..."
kubectl apply -f "${BASE_URL}/kubernetes.yml" --namespace connect-go
if [ $? -ne 0 ]; then
    echo "Failed to install Keycloak Operator."
    exit 1
fi

echo "Keycloak Operator and CRDs installed successfully."
