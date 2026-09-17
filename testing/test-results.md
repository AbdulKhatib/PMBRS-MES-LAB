# PMBRS — Test Results (Stage 7)

Results for every test defined in `test-plan.md`, based on testing actually performed throughout Stages 1-9. Where a test surfaced a real defect, the result links to the corresponding incident writeup rather than restating it here.

## 1. Infrastructure & Network

| ID | Result | Evidence |
|---|---|---|
| INF-01 | PASS | Confirmed both instances in us-east-2b, same subnet — `docs/architecture.md` |
| INF-02 | PASS | `TcpTestSucceeded: True` after Oracle listener and Windows Firewall rule were correctly configured |
| INF-03 | PASS | Confirmed no port 80/443 rule exists on DB tier SG — `docs/dependency-matrix.md` |
| INF-04 | PASS | 1521 rule source is the app tier's security group ID, not an IP — `docs/dependency-matrix.md` |

## 2. Database

| ID | Result | Evidence |
|---|---|---|
| DB-01 | PASS (after fix) | Initial `ORA-12541` — listener not auto-started; resolved by manually starting and setting services to Automatic — see `docs/database-build.md` incident 1 |
| DB-02 | PASS | Five tables, FK constraints, one check constraint, two indexes confirmed created in `XEPDB1` |
| DB-03 | PASS | 13 seed rows committed with no constraint violations |
| DB-04 | PASS | Returned `BATCH-1001 / ACTIVE` correctly |
| DB-05 | PASS | Returned `BATCH-1003` correctly joined to its equipment-fault event |
| DB-06 | PASS | Returned 1 batch each for FILL-01, FILL-02, PACK-01, matching seed data |

## 3. Application (API)

| ID | Result | Evidence |
|---|---|---|
| APP-01 | PASS | `PMBRS is alive` returned consistently |
| APP-02 | PASS | Returns accurate `application`/`database`/`version` fields |
| APP-03 | PASS (implicit) | Application code wraps the DB call in try/except; a DB failure returns `"database": "FAIL: <detail>"` rather than crashing the Flask process — confirmed by the NEG-01 test below, which exercised this exact path |
| APP-04 | PASS | Verified all three seeded batches returned with correct fields |
| APP-05 | PASS | Verified all three seeded equipment records returned |
| APP-06 | PASS | Verified both seeded events, correctly joined to batch/equipment names |

## 4. Deployment / CI/CD

| ID | Result | Evidence |
|---|---|---|
| CICD-01 | Not formally exercised | BUILD's file-existence checks are implemented but a missing-file scenario was not deliberately tested; noted as a gap rather than assumed passing |
| CICD-02 | PASS (after two pipeline bugs found and fixed first) | See `testing/incident-001.md` — required fixing a `findstr` JSON-format bug and a stale-file bug before this test could run correctly |
| CICD-03 | PASS | Full pipeline run: `BUILD PASS / TEST PASS / DEPLOY PASS / VERIFY PASS` |
| CICD-04 | PASS | `.backup` files confirmed present after DEPLOY runs |
| CICD-05 | PASS | See `testing/incident-002.md` — `VERIFY FAIL` with HTTP 500 on injected syntax error |
| CICD-06 | PASS | Rollback triggered automatically, no manual step, immediately following VERIFY failure |
| CICD-07 | PASS | Rollback output confirmed `ROLLBACK: PASS` only after independently re-checking `/health` |
| CICD-08 | PASS | Multiple full clean runs performed across the project, most recently after each incident's fix |

## 5. Disaster Recovery

| ID | Result | Evidence |
|---|---|---|
| DR-01 | PASS | Snapshot completed in 24 minutes; `mes-lab-vm` remained running and reachable throughout — `docs/DR-plan.md` |
| DR-02 | PASS | `SYSTEM01.DBF` (1.3GB), `SYSAUX01.DBF`, control files, redo logs all present at correct sizes on restored volume |
| DR-03 | PASS | Restored volume mounted as `E:` automatically, no signature conflict, no initialization required |

## 6. Security / Configuration

| ID | Result | Evidence |
|---|---|---|
| SEC-01 | PASS (after fix) | Initial check missed a real leak — see `testing/incident-003.md` |
| SEC-02 | PASS | Confirmed these filenames never appear anywhere in `git log` history |
| SEC-03 | FAIL (documented, accepted) | `PmbrsApp2026` remains visible in commit `5833361` in public history. Credential was rotated (no longer valid); history was deliberately not rewritten — see `testing/incident-003.md` for the reasoning. This is recorded as a known, accepted residual finding, not a passed test |

## Negative / Failure Tests

| ID | Result | Evidence |
|---|---|---|
| NEG-01 | PASS | TEST stage correctly failed on invalid credential; pipeline stopped before DEPLOY — `testing/incident-001.md` |
| NEG-02 | PASS | VERIFY stage correctly failed on syntax error; automatic rollback restored working version — `testing/incident-002.md` |
| NEG-03 | PASS (as a discovery, not a designed test) | This scenario was not deliberately designed — it was *discovered* when NEG-01 initially produced an unexpected PASS, revealing `config.py` was missing from DEPLOY's copy list. Fixed and re-verified — `testing/incident-001.md` |

## Summary

| Category | Total | Pass | Fail (accepted) | Not formally exercised |
|---|---|---|---|---|
| Infrastructure & Network | 4 | 4 | 0 | 0 |
| Database | 6 | 6 | 0 | 0 |
| Application (API) | 6 | 6 | 0 | 0 |
| Deployment / CI/CD | 8 | 7 | 0 | 1 |
| Disaster Recovery | 3 | 3 | 0 | 0 |
| Security / Configuration | 3 | 2 | 1 | 0 |
| Negative / Failure | 3 | 3 | 0 | 0 |
| **Total** | **33** | **31** | **1** | **1** |

Two results are deliberately not shown as clean passes:
- **CICD-01** was never formally, deliberately exercised as its own test — BUILD's logic exists and has run correctly as part of every pipeline execution, but a dedicated "delete a required file and confirm BUILD catches it" test was not separately performed. Recorded as a gap, not silently assumed.
- **SEC-03** is an accepted, documented failure (credential visible in git history) rather than a resolved pass, with the reasoning for accepting it recorded in `testing/incident-003.md`.

This mirrors the project's broader principle: a test plan's value is in what it honestly reports, not in reaching 100% green.
