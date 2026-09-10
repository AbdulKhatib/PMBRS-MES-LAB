@echo off
setlocal enabledelayedexpansion
set SCRIPT_STATUS=0

echo ===== VERIFY STAGE =====

curl -s -o verify_response.json -w "%%{http_code}" http://localhost:8080/health > httpcode.txt
set /p HTTPCODE=<httpcode.txt

if not "%HTTPCODE%"=="200" (
    echo [FAIL] Expected HTTP 200, got %HTTPCODE%
    set SCRIPT_STATUS=1
    goto :end
)
echo [PASS] HTTP 200 confirmed

findstr /C:"\"database\":\"OK\"" verify_response.json >nul
if errorlevel 1 (
    echo [FAIL] Post-deploy database check failed
    set SCRIPT_STATUS=1
    goto :end
)
echo [PASS] Post-deploy database check OK

del verify_response.json httpcode.txt >nul 2>&1

:end
if %SCRIPT_STATUS%==0 (
    echo VERIFY: PASS
    exit /b 0
) else (
    echo VERIFY: FAIL
    exit /b 1
)