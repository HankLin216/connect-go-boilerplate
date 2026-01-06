@echo off
REM utils/export_realm.bat
REM Script to export Keycloak realm to JSON

echo [INFO] Exporting Keycloak realm...
docker exec keycloak /opt/keycloak/bin/kc.sh export --dir /tmp/export --realm connect-go --users realm_file
IF %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Failed to export realm from Keycloak container.
    exit /b %ERRORLEVEL%
)

docker cp keycloak:/tmp/export/connect-go-realm.json ./keycloak-realm-temp.json
IF %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Failed to copy exported realm to ./keycloak-realm-temp.json
    exit /b %ERRORLEVEL%
)

move /Y .\keycloak-realm-temp.json .\keycloak-realm.json
IF %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Failed to replace keycloak-realm.json
    exit /b %ERRORLEVEL%
)

docker exec keycloak rm -rf /tmp/export
echo [INFO] Realm exported to ./keycloak-realm.json successfully.
exit /b 0
