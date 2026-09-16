@echo off
REM ============================================================
REM PMBRS ROLLBACK SCRIPT
REM Restores the previous working version of app.py, web.config,
REM and config.py from backups made by deploy.bat, then confirms
REM the restored version is actually healthy before declaring
REM the rollback a success.
REM ============================================================

setlocal enabledelayedexpansion
set SCRIPT_STATUS=0
set LOGFILE=C:\PMBRS\deployment\deployment.log

echo ===== ROLLBACK STAGE ===== >> %LOGFILE%
echo %date% %time% - Starting rollback >> %LOGFILE%
echo ===== ROLLBACK STAGE =====

REM --- app.py is required. If there's no backup, we have nothing
REM --- to roll back to, so stop immediately rather than guessing.
if not exist "C:\PMBRS\deployment\app.py.backup" (
    echo [FAIL] No backup found for app.py - cannot roll back >> %LOGFILE%
    echo [FAIL] No backup found for app.py - cannot roll back
    set SCRIPT_STATUS=1
    goto :end
)

REM --- Restore app.py from its backup copy
copy /Y "C:\PMBRS\deployment\app.py.backup" "C:\inetpub\wwwroot\pmbrs\app.py" >nul
if errorlevel 1 (
    echo [FAIL] Could not restore app.py >> %LOGFILE%
    set SCRIPT_STATUS=1
    goto :end
)
echo [PASS] app.py restored from backup >> %LOGFILE%

REM --- web.config and config.py are restored if a backup exists,
REM --- but a missing backup for these two doesn't stop the rollback -
REM --- app.py is the critical file; these are supporting files that
REM --- may not always change between deployments.
if exist "C:\PMBRS\deployment\web.config.backup" (
    copy /Y "C:\PMBRS\deployment\web.config.backup" "C:\inetpub\wwwroot\pmbrs\web.config" >nul
    echo [PASS] web.config restored from backup >> %LOGFILE%
)

if exist "C:\PMBRS\deployment\config.py.backup" (
    copy /Y "C:\PMBRS\deployment\config.py.backup" "C:\inetpub\wwwroot\pmbrs\config.py" >nul
    echo [PASS] config.py restored from backup >> %LOGFILE%
)

REM --- IIS caches the running Python process; the app pool must be
REM --- recycled or IIS will keep serving the BROKEN version from
REM --- memory even though the files on disk are now fixed.
%windir%\system32\inetsrv\appcmd.exe recycle apppool /apppool.name:"PMBRS"
if errorlevel 1 (
    echo [FAIL] Could not recycle application pool during rollback >> %LOGFILE%
    set SCRIPT_STATUS=1
    goto :end
)
echo [PASS] Application pool recycled after rollback >> %LOGFILE%

REM --- Give IIS a few seconds to actually restart the worker process
REM --- before we hit it with a health check - otherwise we might
REM --- test against a process that's still mid-restart.
timeout /t 5 /nobreak >nul

REM --- Don't just assume the restore worked - actually re-check
REM --- health, the same way VERIFY does after a normal deploy.
REM --- A rollback that isn't itself verified isn't trustworthy.
curl -s -o rollback_verify.json -w "%%{http_code}" http://localhost:8080/health > rollback_httpcode.txt
set /p RBHTTPCODE=<rollback_httpcode.txt

if not "%RBHTTPCODE%"=="200" (
    echo [FAIL] Rollback verification failed - HTTP %RBHTTPCODE% >> %LOGFILE%
    set SCRIPT_STATUS=1
    goto :end
)

findstr /C:"\"database\":\"OK\"" rollback_verify.json >nul
if errorlevel 1 (
    echo [FAIL] Rollback verification - database still unhealthy >> %LOGFILE%
    set SCRIPT_STATUS=1
    goto :end
)

echo [PASS] Rollback verified healthy >> %LOGFILE%

REM --- Clean up temp files from the verification check above
del rollback_verify.json rollback_httpcode.txt >nul 2>&1

:end
REM --- Same PASS/FAIL exit-code pattern as every other stage script.
REM --- pipeline.bat checks this exit code to decide whether to
REM --- report "rolled back successfully" or "manual intervention needed."
if %SCRIPT_STATUS%==0 (
    echo ROLLBACK: PASS >> %LOGFILE%
    echo ROLLBACK: PASS
    exit /b 0
) else (
    echo ROLLBACK: FAIL >> %LOGFILE%
    echo ROLLBACK: FAIL
    exit /b 1
)