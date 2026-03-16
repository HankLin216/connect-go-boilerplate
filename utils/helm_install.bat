@echo off
setlocal

REM ============================================================================
REM Helm Install Script (Windows)
REM
REM Usage:
REM   helm_install.bat install          — Install/upgrade app chart only
REM   helm_install.bat full-install     — Build image + install app chart
REM   helm_install.bat infra            — Install all infrastructure (via WSL/bash)
REM   helm_install.bat infra-select     — Install infrastructure selectively (via WSL/bash)
REM ============================================================================

REM Get the latest git tag
for /f "delims=" %%i in ('git describe --tags --always') do set GIT_TAG=%%i

REM Check if GIT_TAG is empty
if "%GIT_TAG%"=="" (
    set GIT_TAG=v0.0.0
)

echo [INFO] Detected Version: %GIT_TAG%

IF "%1"=="full-install" GOTO FullInstall
IF "%1"=="install" GOTO Install
IF "%1"=="infra" GOTO Infra
IF "%1"=="infra-select" GOTO InfraSelect

GOTO Install

:FullInstall
echo [INFO] Building Production Docker image...
call .\utils\build_docker_image.bat connect-go-boilerplate Production Dockerfile
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Docker build failed.
    exit /b %ERRORLEVEL%
)
GOTO Install

:Install
REM Install/Upgrade App Helm Chart
echo [INFO] Installing/Upgrading App Helm Chart with tag: %GIT_TAG%
helm upgrade --install connect-go-boilerplate ./helm/connect-go-boilerplate ^
    --set connectGoBoilerplate.image.tag=%GIT_TAG% ^
    --set connectGoBoilerplate.image.pullPolicy=Never ^
    --create-namespace ^
    --namespace connect-go

if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Helm install failed.
    exit /b %ERRORLEVEL%
)

echo [INFO] App Helm install completed successfully.
GOTO End

:Infra
echo [INFO] Installing all infrastructure...
bash helm/infrastructure/install.sh
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Infrastructure install failed.
    exit /b %ERRORLEVEL%
)
echo [INFO] Infrastructure install completed.
GOTO End

:InfraSelect
echo [INFO] Installing infrastructure (selective mode)...
bash helm/infrastructure/install.sh --select
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Infrastructure install failed.
    exit /b %ERRORLEVEL%
)
echo [INFO] Infrastructure install completed.
GOTO End

:End
endlocal
