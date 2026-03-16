@echo off
setlocal

REM ============================================================================
REM Helm Uninstall Script (Windows)
REM
REM Usage:
REM   helm_uninstall.bat              — Uninstall app chart only (default)
REM   helm_uninstall.bat app          — Uninstall app chart only
REM   helm_uninstall.bat all          — Uninstall app + all infrastructure
REM ============================================================================

IF "%1"=="all" GOTO UninstallAll
IF "%1"=="app" GOTO UninstallApp

GOTO UninstallApp

:UninstallAll
echo [INFO] Uninstalling all Helm charts...

echo.
echo --- App Chart ---
helm uninstall connect-go-boilerplate --namespace connect-go 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo [WARN] App chart not found or already removed.
)

echo.
echo --- ELK Chart ---
helm uninstall connect-go-elk --namespace connect-go 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo [WARN] ELK chart not found or already removed.
)

echo.
echo --- Monitoring Routes Chart ---
helm uninstall connect-go-monitoring --namespace connect-go 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo [WARN] Monitoring routes chart not found or already removed.
)

echo.
echo --- kube-prometheus-stack ---
helm uninstall kube-prometheus-stack --namespace connect-go 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo [WARN] kube-prometheus-stack not found or already removed.
)

echo.
echo --- ECK Operator ---
helm uninstall elastic-operator --namespace elastic-system 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo [WARN] ECK Operator not found or already removed.
)

echo.
echo [INFO] Full uninstall completed.
echo [NOTE] Envoy Gateway and Keycloak Operator are not removed by this script.
echo [NOTE] To remove them manually:
echo          helm uninstall eg -n envoy-gateway-system
echo          kubectl delete -f https://raw.githubusercontent.com/keycloak/keycloak-k8s-resources/26.0.0/kubernetes/kubernetes.yml -n connect-go
GOTO End

:UninstallApp
echo [INFO] Uninstalling App Helm Chart...
helm uninstall connect-go-boilerplate --namespace connect-go

if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Helm uninstall failed.
    exit /b %ERRORLEVEL%
)

echo [INFO] App Helm uninstall completed successfully.
GOTO End

:End
endlocal
