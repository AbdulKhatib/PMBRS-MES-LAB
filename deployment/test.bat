@echo off
setlocal enabledelayedexpansion
set SCRIPT_STATUS=0

echo ===== TEST STAGE =====

sc query W3SVC | findstr "RUNNING" >nul
if errorlevel 1 (
    echo [FAIL] IIS service not running
    set SCRIPT_STATUS=1
    goto :end
)
echo [PASS] IIS service running

curl -s -o response.json http://localhost:8080/health
if errorlevel 1 (
    echo [FAIL] Could not reach /health endpoint
    set SCRIPT_STATUS=1
    goto :end
)

findstr /C:"\"application\":\"OK\"" response.json >nul
if errorlevel 1 (
    echo [FAIL] Application health check did not return OK
    set SCRIPT_STATUS=1
    goto :end
)
echo [PASS] Application health OK

findstr /C:"\"database\":\"OK\"" response.json >nul
if errorlevel 1 (
    echo [FAIL] Database health check did not return OK
    set SCRIPT_STATUS=1
    goto :end
)
echo [PASS] Database health OK

del response.json >nul 2>&1

:end
if %SCRIPT_STATUS%==0 (
    echo TEST: PASS
    exit /b 0
) else (
    echo TEST: FAIL
    exit /b 1
)