# PMBRS — Rollback Plan (Stage 9)

## Scope

This document covers rollback of the **application tier** — a failed deployment of `app.py`, `web.config`, or `config.py` to IIS on `pmbrs-app-vm`. It does not cover database-level failure or recovery; that is addressed separately in `DR-plan.md` (Stage 9, database/infrastructure disaster recovery).

## Rollback Mechanism

Rollback is automated and built into the deployment pipeline itself, rather than a separate manual procedure invoked after the fact.

```
DEPLOY stage:
  1. Back up the currently live app.py, web.config, config.py
     to C:\PMBRS\deployment\*.backup
  2. Copy new versions from C:\PMBRS\application\ over the live site
  3. Recycle the IIS application pool

VERIFY stage:
  4. Re-check /health against the newly deployed version
  5. If VERIFY fails:
       -> pipeline.bat automatically calls rollback.bat
       -> rollback.bat restores the *.backup files to the live site
       -> recycles the application pool again
       -> independently re-checks /health against the restored version
       -> only reports ROLLBACK: PASS if the restored version is
          confirmed healthy
```

The pipeline's overall exit code remains a failure (`exit /b 1`) even when rollback succeeds. A deployment that required rollback is a failed deployment that was safely contained — not a successful one. This distinction matters for anything that might consume this pipeline's result later (alerting, a future CI system, a human reading the log).

Full implementation: `/deployment/deploy.bat`, `/deployment/rollback.bat`, `/deployment/pipeline.bat`.

## What Is Backed Up, and Retention

Only the single most recent known-good version of each file is retained (`app.py.backup`, `web.config.backup`, `config.py.backup`), overwritten on every new DEPLOY run. This supports rollback exactly one deployment back — sufficient for this project's scale and consistent with its Git-based version history, which already provides a longer-term record of every prior application version if a rollback further back than one step were ever needed. A production system at larger scale would typically retain multiple prior versions; that is intentionally out of scope here.

## RPO / RTO — Application Tier

**RPO (Recovery Point Objective): effectively zero for code changes.** Because rollback restores from a backup taken immediately before the failed deployment, no application code or configuration is lost — the system returns to the exact state it was in immediately prior to the failed deploy attempt.

**RTO (Recovery Time Objective): approximately 15-20 seconds**, measured directly from the deliberate failure test performed for this project (Incident 002): the time between VERIFY detecting a failure and ROLLBACK reporting a confirmed-healthy restored state, including the IIS application pool recycle and settle time built into the script (a 5-second wait after recycling, before the health re-check). This is fully automated and requires no human action once a deployment is initiated — the person running the pipeline is a bystander to the recovery, not a participant in it.

## What This Rollback Does NOT Cover

- **Database schema or data changes.** If a deployment included a database migration that had already been applied, rolling back the application code would not automatically revert the schema or data. No such migrations exist in this version of PMBRS (schema is static, established in Stage 3) — this is noted as a boundary for future stages, not an unaddressed gap in the current one.
- **Infrastructure-level failure.** If the app tier EC2 instance itself became unreachable (not just the application on it), this rollback mechanism cannot help — that scenario is covered by disaster recovery (`DR-plan.md`), not rollback.
- **Failures that VERIFY itself cannot detect.** Rollback only triggers on a VERIFY failure. A defect that passes `/health` but produces incorrect behavior elsewhere (e.g. a bad `/batches` query returning wrong data) would not be caught by this pipeline in its current form — `/health`'s coverage is a real, acknowledged limit, not an oversight; expanding VERIFY's checks to cover more routes would be a reasonable future improvement.

## Verification History

This rollback mechanism has been deliberately tested once, end to end, against a real syntax error deployed to production (see `testing/incident-002.md`). The test confirmed: automatic triggering on VERIFY failure with no manual step, correct restoration of the previous working version, and independent re-verification before the rollback declared itself successful — rather than assuming the restore worked.
