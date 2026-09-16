# Incident 002 — Bad code deploy; automatic rollback verified

## Summary

A Python syntax error was deliberately introduced into `app.py` (a missing closing parenthesis in the `/health` route's `jsonify()` call) to test whether the pipeline's DEPLOY→VERIFY sequence would catch a bad code deployment that earlier stages could not detect, and whether the newly built automatic rollback would correctly restore and re-verify a working version without manual intervention. Both behaved exactly as designed.

## Why This Failure Type Is Different From Incident 001

Incident 001 involved a bad database credential — a runtime configuration error that TEST's `/health` check could catch immediately, before anything reached production.

This incident is a syntax error in the application's source code — invalid Python cannot be caught by BUILD (which only confirms the file exists, not that it's valid) or by TEST (which checks the *live* site, still running the previous, valid version, not the new source about to be deployed). The defect is only exposed once DEPLOY actually overwrites the live file. This gap between "source is present" and "source is valid" is a real and common class of deployment risk, and this test was designed specifically to exercise it.

## Timeline

**1. Defect introduced.** A closing parenthesis was removed from `app.py`'s `/health` route in the source folder (`C:\PMBRS\application\app.py`), producing invalid Python syntax. The live site (`C:\inetpub\wwwroot\pmbrs\app.py`) was left untouched at this point, still serving the previous valid version.

**2. Pipeline run.**
```
BUILD       PASS   - file exists, Python available (does not parse the file)
TEST        PASS   - checked against the still-live, still-valid previous version
DEPLOY      PASS   - broken source file copied over the live version, app pool recycled
VERIFY      FAIL   - HTTP 500 returned; broken Python could not be loaded by wfastcgi
```

**3. Automatic rollback triggered.** `pipeline.bat`'s VERIFY failure branch called `rollback.bat` without any manual step. Rollback restored `app.py`, `web.config`, and `config.py` from their pre-deployment backups, recycled the application pool again, and independently re-verified the restored version's health before reporting success.

**4. Rollback confirmed successful.**
```
ROLLBACK    PASS
Deployment failed but previous version restored and verified healthy.
```
Confirmed independently with a direct `curl http://localhost:8080/health` on the app tier, returning a fully healthy response — proving the site was genuinely serving working code again, not just that the script claimed success.

**5. Source corrected.** The syntax error was fixed in `C:\PMBRS\application\app.py` and a subsequent full pipeline run returned to complete PASS across all four stages, confirming the system was returned to a true known-good baseline (both live and source now valid and matching).

## Root Cause

Not a system defect — this was an intentional test of the pipeline's failure-handling boundary. The "root cause" of the VERIFY failure was, by design, invalid Python syntax deployed to production. The meaningful finding is that BUILD and TEST, by their design, cannot and are not expected to catch this class of error — only DEPLOY-then-VERIFY can, because verifying the actual running result of a deployment is the only way to confirm the deployed code is valid.

## Result

- The pipeline correctly distinguished between a pre-deployment check (TEST, against the still-good live version) and a post-deployment check (VERIFY, against the newly deployed version) — confirming these are not redundant stages.
- Automatic rollback restored a fully working system with zero manual intervention, and did not report success until the restored version was independently re-verified healthy.
- The overall pipeline exit code correctly remained a failure (`exit /b 1`) even though rollback succeeded — a deployment that required rollback is not treated as a successful deployment, only as a safely-contained one.

## Lesson

Different failure types are caught at different stages, and no single stage can catch everything. A syntax error surviving BUILD and TEST is not a gap in those stages' logic — it's evidence that VERIFY, and the rollback safety net behind it, exist precisely for the class of failure that only manifests once code is actually running in its real environment. Treating VERIFY as "just another check" rather than the stage specifically responsible for post-deployment truth would have been a mistake in the pipeline's design; this test confirmed the distinction was worth building.
