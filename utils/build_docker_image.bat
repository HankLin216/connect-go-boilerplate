@echo off
setlocal

REM Check if the correct number of arguments are provided
if "%~3"=="" (
    echo Usage: build_docker_image.bat image_name env path\to\Dockerfile
    exit /b 1
)

REM Assign input arguments to variables
set IMAGE_NAME=%~1
set ENVIRONMENT=%~2
set DOCKERFILE_PATH=%~3

REM Get the latest git tag
for /f "delims=" %%i in ('git describe --tags --always') do set GIT_TAG=%%i

REM Check if GIT_TAG is empty or contains an error message
if "%GIT_TAG%"=="" (
    set GIT_TAG=v0.0.0
)

REM Build the Docker image
if "%ENVIRONMENT%" == "Development" (
    docker build --build-arg ENVIRONMENT=%ENVIRONMENT% -t %IMAGE_NAME%:%GIT_TAG%-dev -f %DOCKERFILE_PATH% .
) else (
    docker build --build-arg ENVIRONMENT=%ENVIRONMENT% -t %IMAGE_NAME%:%GIT_TAG% -f %DOCKERFILE_PATH% .
)

endlocal