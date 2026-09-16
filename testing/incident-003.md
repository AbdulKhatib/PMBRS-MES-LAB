# Incident 003 — Plaintext credential committed to public repository

## Summary

A real Oracle database password was committed to the public GitHub repository in plaintext, in `database/01_schema.sql`, and remained there undetected for approximately one week. This was a genuine process failure, not a hypothetical or staged incident: deliberate effort had already been made to keep credentials out of version control, but that effort missed this specific file.

## What Happened

Early in the project, `config.py` was introduced specifically to remove hardcoded database credentials from `application/app.py` and keep them out of Git (see `docs/database-build.md`, "Password Handling"). At the time, a manual check was run before the first commits:

```
findstr /S /I "password" *.py *.sql
```

This search returned no matches and was treated as confirmation that no credentials were present in any file being committed.

The check was flawed. `database/01_schema.sql` contains the line:
```sql
CREATE USER pmbrs_app IDENTIFIED BY PmbrsApp2026
```
This line does not contain the word "password" anywhere — it uses Oracle's `IDENTIFIED BY` syntax. The search was checking the correct files with the wrong pattern, and passed cleanly despite a real credential being present. This file was committed in `5833361` ("Add PMBRS database schema, constraints, and seed data") on 2026-09-09 and remained live in the public repository, unnoticed, through nine days and fifteen subsequent commits.

## Discovery

Found during a deliberate full-repository audit (file structure, extensions, and a full git history content search for secret-like strings) performed as a cleanup pass near project completion — not found because anything broke or because the leak was suspected. The audit specifically searched commit *content* across full history, not just current working-tree files or filenames, which is what surfaced it.

## Root Cause

The original credential-safety verification searched for the word "password" rather than for the actual secret value or for syntax patterns known to carry credentials (e.g. `IDENTIFIED BY`, `PASSWORD=`, connection-string patterns). A keyword search is only as good as the keyword chosen, and "password" does not appear in Oracle's own SQL syntax for setting one.

## Resolution

1. **Credential rotated.** The `pmbrs_app` Oracle user's password was changed via `ALTER USER pmbrs_app IDENTIFIED BY <new value>` on `mes-lab-vm`, and `config.py` on the app tier was updated to match. The exposed value (`PmbrsApp2026`) is no longer valid.
2. **Working tree redacted.** `database/01_schema.sql` was updated to use a placeholder rather than a real value, and the redaction was committed and pushed.
3. **Full pipeline re-verified.** `pipeline.bat` was re-run after rotation to confirm the application still connects successfully with the new credential — `/health` continues to report `"database": "OK"`.

## Decision: Git History Was NOT Purged

The exposed credential remains visible in the public commit history at `5833361`, and this was a deliberate decision, not an oversight. Purging it would require `git filter-repo` or BFG Repo-Cleaner followed by a force-push, rewriting every subsequent commit hash. For a lab-scoped credential that is not reused anywhere else and has already been rotated, this is judged disproportionate: rotation removes the actual risk (the exposed value no longer grants access to anything), while a history rewrite carries real cost (breaks any existing reference to the old commit hashes, requires careful coordination) for a residual exposure that is already neutralized. This mirrors standard practice for low-stakes leaked test/lab credentials in real engineering teams: rotate and document, don't necessarily rewrite history for every instance.

## Lesson

A "no results found" from a credential-safety check is not the same as "no credentials present" — it only proves the specific pattern searched for wasn't matched. Verifying for secrets should search for actual values or known credential-syntax patterns specific to the technology in use (here, Oracle's `IDENTIFIED BY`), not a single generic English word assumed to always appear near a secret. This is the same category of lesson as the `findstr` JSON-spacing bug in the CI/CD pipeline (`docs/cicd-pipeline.md`) — an automated check's result is only as trustworthy as the pattern it was built to detect, and a clean result should prompt confidence proportional to how well that pattern was chosen, not treated as absolute proof.
