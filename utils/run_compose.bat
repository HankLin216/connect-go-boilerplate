@echo off
REM utils/run_compose.bat
REM Script to manage Docker Compose stack on Windows

REM Get the latest git tag
for /f "delims=" %%i in ('git describe --tags --always') do set GIT_TAG=%%i

REM Check if GIT_TAG is empty
if "%GIT_TAG%"=="" (
    set GIT_TAG=v0.0.0
)

echo [INFO] Detected Version: %GIT_TAG%
set VERSION=%GIT_TAG%

IF "%1"=="" GOTO Help
IF "%1"=="help" GOTO Help
IF "%1"=="full" GOTO Full
IF "%1"=="dev-full" GOTO DevFull
IF "%1"=="app" GOTO App
IF "%1"=="dev-app" GOTO DevApp
IF "%1"=="down" GOTO Down

GOTO Help

:Full
echo [INFO] Starting FULL stack (App, Envoy, ELK, Prometheus, Grafana)...
docker compose up -d --build
GOTO End

:DevFull
echo [INFO] Starting DEV FULL stack (App, Envoy, ELK, Prometheus, Grafana)...
set VERSION=%GIT_TAG%-dev
docker compose up -d --build
GOTO End

:App
echo [INFO] Starting APP stack (App, Envoy)...
docker compose up -d --build connect-go-boilerplate envoy-proxy
GOTO End

:DevApp
echo [INFO] Starting DEV APP stack (App, Envoy)...
set VERSION=%GIT_TAG%-dev
docker compose up -d --build connect-go-boilerplate envoy-proxy
GOTO End

:Down
echo [INFO] Stopping all services...
docker compose down
GOTO End

:Help
echo Usage:
echo   .\utils\run_compose.bat app       - Run App and Envoy only
echo   .\utils\run_compose.bat dev-app   - Run Dev App and Envoy only
echo   .\utils\run_compose.bat full      - Run everything
echo   .\utils\run_compose.bat dev-full  - Run Dev everything
echo   .\utils\run_compose.bat down      - Stop and remove containers
GOTO End

:End
