@echo off
setlocal

REM Check if the correct number of arguments are provided
if "%~3"=="" (
    echo Usage: build.bat path\to\config env output\folder\path
    exit /b 1
)

REM Assign input arguments to variables
set CONFIG_FILE=%~1
set ENVIRONMENT=%~2
set OUTPUT_FILE=%~3

REM Get the latest git tag
for /f "delims=" %%i in ('git describe --tags --always') do set GIT_TAG=%%i

REM Check if GIT_TAG is empty or contains an error message
if "%GIT_TAG%"=="" (
    set GIT_TAG=v0.0.0
)

REM Get the parent directory of the utils directory
set SCRIPT_DIR=%~dp0
for %%i in ("%SCRIPT_DIR%..\") do set PARENT_DIR=%%~fi

REM Execute the go build command
go build -o %OUTPUT_FILE% -ldflags "-s -w -X main.Version=%GIT_TAG% -X main.Env=%ENVIRONMENT% -X main.ConfFolderPath=%CONFIG_FILE%" %PARENT_DIR%cmd\server

REM Copy config to bin
xcopy configs\* bin\ /Y

endlocal