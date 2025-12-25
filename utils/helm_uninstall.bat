@echo off
setlocal

echo [INFO] Uninstalling Helm Chart...
helm uninstall connect-go-boilerplate

if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Helm uninstall failed.
    exit /b %ERRORLEVEL%
)

echo [INFO] Helm uninstall completed successfully.
endlocal
