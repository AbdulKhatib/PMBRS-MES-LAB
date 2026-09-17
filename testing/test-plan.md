# PMBRS — Test Plan (Stage 7)

## Purpose

This document formalizes the testing already performed throughout the PMBRS build into a structured requirement-to-test mapping, consistent with the validation-inspired discipline established in `project-charter.md`. Results and evidence are recorded in `test-results.md`.

Tests are organized by system layer, matching the project's stage structure.

## Test Categories

### 1. Infrastructure & Network

| ID | Requirement | Test |
|---|---|---|
| INF-01 | App tier and DB tier reside in the same AZ and subnet | Confirm via EC2 console instance details |
| INF-02 | App tier can reach DB tier on port 1521 | `Test-NetConnection` from app tier to DB tier private IP |
| INF-03 | DB tier has no inbound web exposure | Review DB tier security group inbound rules |
| INF-04 | DB tier only accepts 1521 from the app tier's security group | Review SG rule source scoping |

### 2. Database

| ID | Requirement | Test |
|---|---|---|
| DB-01 | Oracle listener is reachable and reports READY services | `lsnrctl status` |
| DB-02 | PMBRS schema exists with correct tables and constraints | Query `USER_TABLES`, `USER_CONSTRAINTS` in `XEPDB1` |
| DB-03 | Seed data loads without constraint violations | Run `04_seed_data.sql`, confirm row counts |
| DB-04 | Active batches query returns correct results | Run query 1 from `05_queries.sql` |
| DB-05 | Failed batch correctly joins to its production event | Run query 2 from `05_queries.sql` |
| DB-06 | Batch count per equipment is accurate | Run query 3 from `05_queries.sql` |

### 3. Application (API)

| ID | Requirement | Test |
|---|---|---|
| APP-01 | `/` returns a liveness response independent of the database | GET `/` |
| APP-02 | `/health` reports both application and database status accurately | GET `/health`, compare against actual DB state |
| APP-03 | `/health` degrades gracefully (does not crash) when the database is unreachable | GET `/health` with DB tier stopped |
| APP-04 | `/batches` returns all seeded batches with correct fields | GET `/batches`, compare against seed data |
| APP-05 | `/equipment` returns all seeded equipment | GET `/equipment` |
| APP-06 | `/events` correctly joins events to batch and equipment names | GET `/events` |

### 4. Deployment / CI/CD

| ID | Requirement | Test |
|---|---|---|
| CICD-01 | BUILD stage fails if a required application file is missing | Temporarily rename a required file, run `pipeline.bat` |
| CICD-02 | TEST stage correctly detects application health failure | Deploy a bad database credential, run pipeline |
| CICD-03 | TEST stage correctly detects a healthy system as passing | Run pipeline against known-good state |
| CICD-04 | DEPLOY stage backs up the current live version before overwriting | Inspect `.backup` files after a DEPLOY run |
| CICD-05 | VERIFY stage catches a bad code deployment that BUILD/TEST could not | Deploy a Python syntax error, run pipeline |
| CICD-06 | A failed VERIFY automatically triggers rollback with no manual step | Same as CICD-05, observe pipeline behavior |
| CICD-07 | Rollback independently re-verifies the restored version before reporting success | Inspect rollback output/log |
| CICD-08 | A full pipeline run with no injected failure passes all four stages | Run `pipeline.bat` against known-good state |

### 5. Disaster Recovery

| ID | Requirement | Test |
|---|---|---|
| DR-01 | An EBS snapshot of the DB volume can be created while the instance remains running | Create snapshot, observe instance stays reachable throughout |
| DR-02 | A volume restored from snapshot contains intact, correctly-sized Oracle data files | Attach restored volume, inspect file sizes |
| DR-03 | A restored volume mounts cleanly without manual repair | Bring restored disk online in Windows |

### 6. Security / Configuration

| ID | Requirement | Test |
|---|---|---|
| SEC-01 | No credentials exist in any file tracked by Git in the current working tree | Search current tree for secret patterns |
| SEC-02 | `.gitignore` correctly excludes `config.py`, logs, and backup files | Confirm these filenames never appear in `git log` history |
| SEC-03 | Full commit history (not just current files) contains no live, unrotated credentials | Search full commit history content for secret patterns |

## Negative / Failure Tests

These deliberately induce failure to confirm the system fails safely and detectably, rather than silently succeeding or failing unsafely.

| ID | Scenario | Expected Behavior |
|---|---|---|
| NEG-01 | Invalid database credential deployed | TEST stage fails; pipeline stops before DEPLOY |
| NEG-02 | Syntax error in application code deployed | VERIFY stage fails after DEPLOY; automatic rollback restores working version |
| NEG-03 | A deployable file (config.py) omitted from DEPLOY's copy list | Change to that file never reaches production; discovered via unexpected pipeline PASS during a deliberate failure test |
