# PMBRS — Production Monitoring & Batch Reporting System

**A hands-on, end-to-end MES deployment lab: Windows Server, IIS, Oracle Database, and Python/Flask, built and broken on AWS EC2.**

PMBRS is a fictional pharmaceutical manufacturing web application, built the way an actual deployment engineer would build one — not a single-file tutorial project. It exists to demonstrate real infrastructure engineering: provisioning, deployment automation, CI/CD, database administration, security, failure injection, root-cause analysis, and disaster recovery — all documented with real evidence, real error messages, and real fixes.

> This is not a validated GxP production system. It's a controlled engineering lab applying validation-inspired discipline (requirements, testing, traceability, evidence) to a small, real, three-tier application — see [`docs/architecture.md`](docs/architecture.md) for scope.

**Start here:** [Final Case Study](docs/final-case-study.md) — the full accounting of what was built, what broke, and what was deliberately left undone.

---

## Architecture

```
Laptop (browser)
      │  HTTP
      ▼
App Tier — AWS EC2, Windows Server 2022, IIS + Python/Flask (via wfastcgi)
      │  Oracle TCP 1521, private IP, same AZ
      ▼
DB Tier — AWS EC2, Windows Server 2022, Oracle Database 21c XE
```

Two-tier, two-EC2-instance deployment, security-group-segmented, with no public web exposure on the database tier. Full details in [`docs/architecture.md`](docs/architecture.md) and [`docs/dependency-matrix.md`](docs/dependency-matrix.md).

## Tech Stack

`AWS EC2` · `Windows Server 2022` · `IIS` · `Oracle Database 21c XE` · `Python` · `Flask` · `wfastcgi` · `SQL` · `Windows Batch Scripting` · `PowerShell` · `Git` · `CI/CD`

## What's Actually Built Here

- ✅ **Two-tier AWS infrastructure** — segmented app/database EC2 instances, security-group-scoped access, private-IP inter-tier traffic
- ✅ **Oracle 21c XE database** — five-table schema, constraints, indexes, seed data, pluggable-database (multitenant) architecture
- ✅ **Flask REST API** — four live endpoints querying real Oracle data, running under IIS via a custom-built wfastcgi bridge (IIS doesn't run Python natively — this had to be engineered)
- ✅ **Gated CI/CD pipeline** — `BUILD → TEST → DEPLOY → VERIFY`, with explicit exit-code handling at every stage, not just printed status text
- ✅ **Automatic rollback** — a failed VERIFY triggers automatic restoration of the previous working version, independently re-verified before being reported as recovered
- ✅ **Tested disaster recovery** — a real EBS snapshot-and-restore was performed and verified, with measured RPO/RTO, not just documented as a plan
- ✅ **Ten real, documented incidents** — see [`/testing`](testing/) and [`/docs`](docs/) — genuine root-cause analyses, not staged failures
- ✅ **Formal test plan** — 33 tests across 6 categories, honestly recorded results (not a manufactured 100% pass rate) — see [`testing/test-plan.md`](testing/test-plan.md) and [`testing/test-results.md`](testing/test-results.md)

## Real Incidents, Honestly Documented

This project intentionally breaks things and documents what happens, because that's the most useful part of the story:

| Incident | Root Cause |
|---|---|
| `ORA-12541` on first connect | Oracle listener service didn't auto-start after install |
| Oracle instability under load | DB instance under-provisioned (2GB RAM vs. Oracle's 4GB minimum) |
| `ORA-00922` | Unescaped special character in a password broke SQL syntax |
| `ORA-65096` | App user created in the CDB root instead of the pluggable database |
| IIS `500.19` → `500.0` | Locked config section, then app-pool identity lacking filesystem access to a per-user Python install |
| Pipeline false failure | `findstr` pattern assumed JSON spacing Flask doesn't produce |
| DEPLOY stage silent gap | A config file was never added to the deployment script's copy list |
| Bad code deploy | Verified the pipeline correctly detects and auto-rolls-back a syntax error that earlier stages couldn't catch |
| Plaintext credential in public history | A real DB password was committed in an `IDENTIFIED BY` clause, missed by a `findstr "password"` check that didn't match Oracle's syntax; found during a full-history audit and resolved by rotation |

Full writeups: [`testing/incident-001.md`](testing/incident-001.md), [`testing/incident-002.md`](testing/incident-002.md), [`testing/incident-003.md`](testing/incident-003.md), and the incident sections inside [`docs/database-build.md`](docs/database-build.md), [`docs/iis-build.md`](docs/iis-build.md), and [`docs/cicd-pipeline.md`](docs/cicd-pipeline.md).

## Repository Structure

```
PMBRS-MES-LAB/
├── application/       Flask app, IIS config, API reference
├── database/          Oracle schema, constraints, seed data, queries
├── deployment/         CI/CD pipeline scripts (build/test/deploy/verify/rollback)
├── docs/               Architecture, build docs, dependency matrix, DR/rollback plans
├── testing/            Incident writeups and root-cause analyses
└── evidence/           Screenshots and supporting evidence
```

## Documentation Index

- [Final Case Study](docs/final-case-study.md) — the capstone summary: what was built, what broke, what was deliberately left undone
- [Architecture](docs/architecture.md) — topology, design decisions, instance sizing
- [Dependency Matrix](docs/dependency-matrix.md) — security group rules, real values
- [Database Build](docs/database-build.md) — Oracle install, schema, incidents
- [IIS Build](docs/iis-build.md) — server config, Python/Flask bridge, incidents
- [CI/CD Pipeline](docs/cicd-pipeline.md) — pipeline design, incidents
- [Rollback Plan](docs/rollback-plan.md) — automated rollback design, RPO/RTO
- [DR Plan](docs/DR-plan.md) — tested backup/restore, measured RPO/RTO
- [Azure Service Mapping](docs/azure-service-mapping.md) — AWS-to-Azure conceptual mapping (Stage 10)
- [Test Plan](testing/test-plan.md) — formal requirement-to-test mapping
- [Test Results](testing/test-results.md) — results for every test, including honestly-recorded gaps
- [API Reference](application/API.md) — endpoint documentation

## Why This Project Exists

Built to close a real, self-identified gap between manufacturing/MES domain experience and the infrastructure layer underneath MES deployments — Windows Server, IIS, Oracle, SQL, deployment automation, and CI/CD. Every incident above is real, not staged for effect; the value of this project is in what broke and how it was diagnosed, not just in the fact that it eventually worked.

No claim is made to production experience with any specific commercial MES platform not actually used. This project demonstrates understanding of the underlying deployment architecture pattern, engineering discipline, and troubleshooting methodology that transfers across MES/enterprise platforms.

---

**Author:** Abdulwahab Khatib — IT professional with a pharmaceutical manufacturing (GxP) background, building hands-on infrastructure depth through deliberate, documented practice.
