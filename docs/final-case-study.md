# PMBRS — Final Case Study

## What This Project Set Out to Prove

Real pharmaceutical manufacturing and MES experience does not automatically include the infrastructure layer underneath MES deployments — Windows Server administration, database engineering, deployment automation, and CI/CD. This project was built to close that specific, self-identified gap: not through courses or certifications alone, but by designing, building, deploying, breaking, and recovering a real (if fictional) three-tier system, end to end, on real cloud infrastructure.

The standard set at the outset, in the project's own charter, was:

> "The engineer can demonstrate that they designed, built, deployed, tested, intentionally broke, troubleshot, recovered, documented, and version-controlled the system."

This document is the accounting against that standard.

## What Was Built

A two-tier AWS architecture — Windows Server 2022 running IIS and a Python/Flask application on one EC2 instance, Windows Server 2022 running Oracle Database 21c XE on a second, network-segmented instance — implementing a fictional pharmaceutical manufacturing monitoring application (PMBRS). The system includes:

- A five-table Oracle schema with constraints, indexes, and seed data
- A Flask REST API with four live, database-backed endpoints
- A custom-built IIS-to-Python bridge (IIS does not run Python natively; this required real engineering, not configuration)
- A gated `BUILD → TEST → DEPLOY → VERIFY` CI/CD pipeline with explicit exit-code discipline at every stage
- Automatic rollback, triggered by a failed VERIFY, independently re-verified before reporting success
- A tested disaster recovery procedure (EBS snapshot → restore → verify), with measured RPO/RTO from a real, performed restore
- A formal test plan covering infrastructure, database, application, pipeline, DR, and security — including honestly-recorded gaps, not a manufactured 100% pass rate
- A full Git history of 18+ commits, documentation for every stage, and ten real, root-caused incidents

## What Actually Went Wrong (The Real Value of This Project)

Ten incidents were diagnosed and resolved across the build, spanning nearly every layer of the stack:

| # | Layer | Incident |
|---|---|---|
| 1 | Database | Oracle listener didn't auto-start after install |
| 2 | Database | Instance under-provisioned (2GB RAM vs. Oracle's 4GB minimum), causing intermittent instability |
| 3 | Database | Unescaped password character broke `CREATE USER` syntax |
| 4 | Database | Application user created in the CDB root instead of the pluggable database |
| 5 | IIS | Config section locked by default, blocking site-level `web.config` |
| 6 | IIS | App pool identity lacked filesystem access to a per-user Python install |
| 7 | CI/CD | Pipeline false failure — `findstr` pattern assumed JSON spacing Flask doesn't produce |
| 8 | CI/CD | DEPLOY stage silently never copied `config.py`, discovered mid-failure-injection test |
| 9 | CI/CD | Confirmed VERIFY (not BUILD/TEST) is the only stage that can catch a bad code deploy, via a real syntax-error test and successful automatic rollback |
| 10 | Security | A real plaintext credential was committed to public GitHub history, missed by an inadequately-chosen grep pattern, discovered during a deliberate audit, and resolved by rotation |

None of these were staged. Each surfaced from genuinely building the system, was investigated rather than worked around, and is documented with its actual root cause and resolution — not a sanitized retelling.

## What This Project Deliberately Did Not Do

Documented honestly, not hidden:

- **Full instance-loss DR was not tested** — only data-volume recovery onto a still-running instance was proven; recovering onto a brand-new instance after total instance loss is a materially larger, untested scenario.
- **Git history was not purged** after the credential leak — a deliberate, reasoned decision (rotation neutralizes the actual risk; a history rewrite carries real cost for a lab-scoped, non-reused credential), not an oversight.
- **BUILD's missing-file detection was never formally, deliberately tested** as its own isolated case — recorded as a gap in the test results rather than silently assumed passing.
- **No automated backup schedule exists** — the DR snapshot performed was a manual, one-time action, and the realistic RPO today depends on remembering to run it again.
- **No secrets manager (AWS Secrets Manager / Azure Key Vault) was used** — credentials are handled via a gitignored local file, an acceptable minimum for a lab but explicitly named as a gap versus production practice in the Azure mapping document.

## Honest Positioning

Nothing in this project claims direct production experience with any specific commercial MES platform (POMSnet, Aquila, R400, or similar) not actually used. What it demonstrates is the underlying deployment architecture pattern common across MES and enterprise systems — client/application/database layering, deployment automation, validation-inspired testing discipline, failure detection, recovery, and infrastructure-as-documentation — built and proven hands-on rather than studied in the abstract.

The strongest evidence in this repository is not that the system eventually worked. It's the ten-incident log showing what broke, how it was actually diagnosed (not guessed at), and what was learned from each — which is the material that holds up under real interview questioning, because it happened.

## Project Statistics

- **18 Git commits**, each representing a real, working-state change
- **10 documented incidents** with root cause and resolution
- **33 formal tests** across 6 categories, 31 passing, 2 honestly recorded as not fully clean
- **2 AWS EC2 instances**, network-segmented, security-group-scoped
- **1 real disaster recovery test**, performed and measured, not just planned

---

*This project remains a personal engineering lab, not a validated GxP production system. See `docs/architecture.md` and the original project charter for the explicit scope boundary this project operates within.*
