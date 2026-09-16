# Incident 001 — Bad database credential; DEPLOY stage gap discovered

## Summary

While attempting to deliberately inject a database connection failure to test the pipeline's failure detection (Stage 8), an unrelated real defect in `deploy.bat` was discovered first: the DEPLOY stage does not copy `config.py` to the live site. This meant an initial "failure injection" attempt produced no failure at all — the pipeline correctly reported success because the bad change never actually reached production. After understanding why, the failure was re-injected directly against the live configuration, the pipeline correctly detected and stopped on it, and the underlying DEPLOY gap was then fixed.

## Timeline

**1. Attempted failure injection.** `config.py` in the source folder (`C:\PMBRS\application\`) was edited to contain an invalid database username (`pmbrs_ap` instead of `pmbrs_app`). `pipeline.bat` was run expecting TEST or VERIFY to fail.

**2. Unexpected result: pipeline passed.** All four stages reported PASS, including the database health check — despite the credential change.

**3. Investigation.** Rather than assume the injected failure was somehow ineffective, `deploy.bat` was reviewed directly. It copies only `app.py` and `web.config` to the live site (`C:\inetpub\wwwroot\pmbrs\`) — `config.py` is not in its copy list. The live site's `config.py` still held the original, correct credentials throughout the entire "failed" injection attempt.

**Root cause (finding 1):** DEPLOY's file list was written when only `app.py` and `web.config` existed as deployable files. `config.py` was added later in the project (to remove hardcoded credentials from source, see `database-build.md`) without updating DEPLOY to include it. As a result, any change to `config.py` — including legitimate ones, not just this deliberate bad one — would never reach production through this pipeline.

**4. Correcting the test.** To properly exercise the pipeline's failure detection as originally intended, the bad credential was applied directly to the live file (`C:\inetpub\wwwroot\pmbrs\config.py`), simulating what DEPLOY should have done if the gap did not exist.

**5. Pipeline correctly detected the failure.** `pipeline.bat` was run again:
```
BUILD       PASS
TEST        FAIL
```
TEST stage's database health check correctly caught the invalid credential and the pipeline stopped immediately — DEPLOY and VERIFY never ran. This is the correct, intended behavior.

**6. Recovery.** Both the live and source copies of `config.py` were corrected back to valid credentials. `pipeline.bat` was re-run and returned to a full PASS across all four stages, confirming clean recovery.

**7. Fixed the underlying gap.** `deploy.bat` was updated to include `config.py` in its copy step, with the same error handling pattern used for the other two files. Pipeline re-verified green after the fix.

## Root Causes

1. **DEPLOY stage incompleteness** — a file added to the application after the pipeline was first written was never added to the deployment step, creating a silent gap where changes to that file would never ship.
2. (By design, not a defect) — the failure injection itself worked exactly as intended once applied to the correct location; the initial "non-failure" was a true negative caused by the gap above, not a weakness in the detection logic.

## Resolution

- `deploy.bat` now copies `config.py` alongside `app.py` and `web.config`, with matching failure handling.
- Both live and source `config.py` restored to correct values.
- Full pipeline re-verified passing after the fix.

## Lesson

A pipeline is only as complete as its own maintenance. Adding a new deployable file to an application does not automatically mean the deployment automation was updated to include it — this has to be checked deliberately, and it will not surface as an obvious error; it surfaces as changes silently failing to deploy while the pipeline reports success. This was caught here because an unexpected PASS during a deliberate failure test prompted investigation rather than being accepted at face value — the same principle as the two `findstr` pattern bugs found during initial pipeline testing (see `cicd-pipeline.md`): an automated result, pass or fail, is a starting point for verification, not a final answer on its own.
