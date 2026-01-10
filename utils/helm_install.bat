@echo off
setlocal

REM Get the latest git tag
for /f "delims=" %%i in ('git describe --tags --always') do set GIT_TAG=%%i

REM Check if GIT_TAG is empty
if "%GIT_TAG%"=="" (
    set GIT_TAG=v0.0.0
)

echo [INFO] Detected Version: %GIT_TAG%

IF "%1"=="full" GOTO Full
IF "%1"=="dev-full" GOTO DevFull
IF "%1"=="install" GOTO Install
IF "%1"=="dev-install" GOTO DevInstall

GOTO Install

:Full
echo [INFO] Building Production Docker image...
call .\utils\build_docker_image.bat connect-go-boilerplate Production Dockerfile
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Docker build failed.
    exit /b %ERRORLEVEL%
)
GOTO Install

:DevFull
echo [INFO] Building Development Docker image...
call .\utils\build_docker_image.bat connect-go-boilerplate Development Dockerfile
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Docker build failed.
    exit /b %ERRORLEVEL%
)
set GIT_TAG=%GIT_TAG%-dev
GOTO Install

:DevInstall
set GIT_TAG=%GIT_TAG%-dev
GOTO Install

:Install
REM Install/Upgrade Helm Chart
echo [INFO] Installing/Upgrading Helm Chart with tag: %GIT_TAG%
helm upgrade --install connect-go-boilerplate ./helm/connect-go-boilerplate ^
    --set connectGoBoilerplate.image.tag=%GIT_TAG% ^
    --set connectGoBoilerplate.image.pullPolicy=Never ^
    --create-namespace ^
    --namespace connect-go

if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Helm install failed.
    exit /b %ERRORLEVEL%
)

echo [INFO] Helm install completed successfully.
endlocal
