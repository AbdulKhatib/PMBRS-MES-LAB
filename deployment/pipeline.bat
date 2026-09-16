@echo off
setlocal enabledelayedexpansion
cd /d C:\PMBRS\deployment

echo ================================
echo PMBRS DEPLOYMENT PIPELINE
echo ================================

call build.bat
if errorlevel 1 (
    echo.
    echo PIPELINE FAILED AT: BUILD
    echo BUILD       FAIL
    exit /b 1
)

call test.bat
if errorlevel 1 (
    echo.
    echo PIPELINE FAILED AT: TEST
    echo BUILD       PASS
    echo TEST        FAIL
    exit /b 1
)

call deploy.bat
if errorlevel 1 (
    echo.
    echo PIPELINE FAILED AT: DEPLOY
    echo BUILD       PASS
    echo TEST        PASS
    echo DEPLOY      FAIL
    exit /b 1
)

call verify.bat
if errorlevel 1 (
    echo.
    echo PIPELINE FAILED AT: VERIFY - initiating automatic rollback
    echo BUILD       PASS
    echo TEST        PASS
    echo DEPLOY      PASS
    echo VERIFY      FAIL

    call rollback.bat
    if errorlevel 1 (
        echo.
        echo ROLLBACK ALSO FAILED - MANUAL INTERVENTION REQUIRED
        echo ROLLBACK    FAIL
        exit /b 1
    )

    echo.
    echo ROLLBACK    PASS
    echo Deployment failed but previous version restored and verified healthy.
    exit /b 1
)

echo.
echo ================================
echo BUILD       PASS
echo TEST        PASS
echo DEPLOY      PASS
echo VERIFY      PASS
echo PIPELINE: SUCCESS
echo ================================
exit /b 0