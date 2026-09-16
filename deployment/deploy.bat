@echo off
setlocal enabledelayedexpansion
set SCRIPT_STATUS=0
set LOGFILE=C:\PMBRS\deployment\deployment.log

echo ===== DEPLOY STAGE ===== >> %LOGFILE%
echo %date% %time% - Starting deployment >> %LOGFILE%

REM Backup current live version before overwriting
if exist "C:\inetpub\wwwroot\pmbrs\app.py" (
    copy "C:\inetpub\wwwroot\pmbrs\app.py" "C:\PMBRS\deployment\app.py.backup" >nul
    echo [INFO] Previous app.py backed up >> %LOGFILE%
)

copy /Y "C:\PMBRS\application\app.py" "C:\inetpub\wwwroot\pmbrs\app.py" >nul
if errorlevel 1 (
    echo [FAIL] Could not copy app.py >> %LOGFILE%
    set SCRIPT_STATUS=1
    goto :end
)

copy /Y "C:\PMBRS\application\web.config" "C:\inetpub\wwwroot\pmbrs\web.config" >nul
if errorlevel 1 (
    echo [FAIL] Could not copy web.config >> %LOGFILE%
    set SCRIPT_STATUS=1
    goto :end
)


copy /Y "C:\PMBRS\application\config.py" "C:\inetpub\wwwroot\pmbrs\config.py" >nul
if errorlevel 1 (
    echo [FAIL] Could not copy config.py >> %LOGFILE%
    set SCRIPT_STATUS=1
    goto :end
)

echo [PASS] Files deployed >> %LOGFILE%

%windir%\system32\inetsrv\appcmd.exe recycle apppool /apppool.name:"PMBRS"
if errorlevel 1 (
    echo [FAIL] Could not recycle application pool >> %LOGFILE%
    set SCRIPT_STATUS=1
    goto :end
)
echo [PASS] Application pool recycled >> %LOGFILE%

timeout /t 5 /nobreak >nul

:end
if %SCRIPT_STATUS%==0 (
    echo DEPLOY: PASS >> %LOGFILE%
    echo DEPLOY: PASS
    exit /b 0
) else (
    echo DEPLOY: FAIL >> %LOGFILE%
    echo DEPLOY: FAIL
    exit /b 1
)