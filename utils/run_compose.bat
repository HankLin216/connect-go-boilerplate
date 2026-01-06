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
IF "%1"=="restart" GOTO RestartService

GOTO Help

:CheckImage
REM Check if image exists, if not build it
docker image inspect connect-go-boilerplate:%VERSION% >nul 2>&1
IF %ERRORLEVEL% NEQ 0 (
    echo [WARN] Image connect-go-boilerplate:%VERSION% not found. Building...
    IF "%VERSION:~-4%"=="-dev" (
        call .\utils\build_docker_image.bat connect-go-boilerplate Development Dockerfile
    ) ELSE (
        call .\utils\build_docker_image.bat connect-go-boilerplate Production Dockerfile
    )
) ELSE (
    echo [INFO] Image connect-go-boilerplate:%VERSION% found. Skipping build.
)
EXIT /B 0

:Full
CALL :CheckImage
echo [INFO] Starting FULL stack (App, Envoy, ELK, Prometheus, Grafana)...
docker compose up -d
GOTO End

:DevFull
set VERSION=%GIT_TAG%-dev
CALL :CheckImage
echo [INFO] Starting DEV FULL stack (App, Envoy, ELK, Prometheus, Grafana)...
docker compose up -d
GOTO End

:App
CALL :CheckImage
echo [INFO] Starting APP stack (App, Envoy)...
docker compose up -d connect-go-boilerplate envoy-proxy keycloak
GOTO End

:DevApp
set VERSION=%GIT_TAG%-dev
CALL :CheckImage
echo [INFO] Starting DEV APP stack (App, Envoy)...
docker compose up -d connect-go-boilerplate envoy-proxy keycloak
GOTO End

:Down
echo [INFO] Stopping all services...
docker compose down
GOTO End

:RestartService
IF "%2"=="" (
    echo [ERROR] No service specified.
    echo Usage: .\utils\run_compose.bat restart ^<service_name^>
    exit /b 1
)
set SERVICE_NAME=%2
echo [INFO] Restarting service: %SERVICE_NAME%
docker compose -f docker-compose.app.yml -f docker-compose.db.yml -f docker-compose.monitor.yml -f docker-compose.elk.yml up -d --no-deps --force-recreate %SERVICE_NAME%
GOTO End

:Help
echo Usage:
echo   .\utils\run_compose.bat app       - Run App and Envoy only
echo   .\utils\run_compose.bat dev-app   - Run Dev App and Envoy only
echo   .\utils\run_compose.bat full      - Run everything
echo   .\utils\run_compose.bat dev-full  - Run Dev everything
echo   .\utils\run_compose.bat down      - Stop and remove containers
echo   .\utils\run_compose.bat restart ^<service^> - Restart a specific service
GOTO End

:End
