@echo off
setlocal enabledelayedexpansion

if "%~1"=="" (
    echo Usage: %~nx0 [proto_file_directory]
    echo Example: %~nx0 api
    echo Example: %~nx0 internal
    exit /b 1
)

set "proto_file_directory=%~1"

REM Check if the directory exists
if not exist "%proto_file_directory%" (
    echo Error: Directory "%proto_file_directory%" does not exist
    exit /b 1
)

REM set prefix path for relative path calculation
for %%d in (%~dp0..) do set prefix_path=%%~fd

REM replace the prefix path to get relative directory
set modified_proto_file_directory=!proto_file_directory:%prefix_path%\=!

echo Generating proto files for directory: %proto_file_directory%
echo Using buf generate with --path filter...

REM Use buf generate with --path to generate only the specified directory
buf generate --path %modified_proto_file_directory%

if %ERRORLEVEL% NEQ 0 (
    echo Error: Failed to generate proto files for %proto_file_directory%
    exit /b 1
) else (
    echo Successfully generated proto files for %proto_file_directory%
)

endlocal