@echo off
setlocal

REM Check if the correct number of arguments are provided
if "%~2"=="" (
    echo Usage: run_docker_image.bat container_name env
    exit /b 1
)

REM Assign input arguments to variables
set CONTAINER_NAME=%~1
set ENVIRONMENT=%~2

REM Get the latest git tag
for /f "delims=" %%i in ('git describe --tags --always') do set GIT_TAG=%%i

REM Check if GIT_TAG is empty or contains an error message
if "%GIT_TAG%"=="" (
    set GIT_TAG=v0.0.0
)

REM Run the Docker image based on environment
if "%ENVIRONMENT%" == "Development" (
    docker run -d --rm --name %CONTAINER_NAME%-dev -p 9000:9000 connect-go-boilerplate:%GIT_TAG%-dev
) else (
    docker run -d --rm --name %CONTAINER_NAME% -p 9000:9000 connect-go-boilerplate:%GIT_TAG%
)

endlocal