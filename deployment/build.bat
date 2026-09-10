@echo off
setlocal enabledelayedexpansion
set SCRIPT_STATUS=0

echo ===== BUILD STAGE =====

if not exist "C:\PMBRS\application\app.py" (
    echo [FAIL] app.py not found
    set SCRIPT_STATUS=1
    goto :end
)
if not exist "C:\PMBRS\application\web.config" (
    echo [FAIL] web.config not found
    set SCRIPT_STATUS=1
    goto :end
)
if not exist "C:\PMBRS\application\config.py" (
    echo [FAIL] config.py not found - required for deployment, must exist on server but never in Git
    set SCRIPT_STATUS=1
    goto :end
)

echo [PASS] All required application files present

where python >nul 2>&1
if errorlevel 1 (
    echo [FAIL] Python not found on PATH
    set SCRIPT_STATUS=1
    goto :end
)
echo [PASS] Python available

echo [PASS] BUILD stage complete

:end
if %SCRIPT_STATUS%==0 (
    echo BUILD: PASS
    exit /b 0
) else (
    echo BUILD: FAIL
    exit /b 1
)