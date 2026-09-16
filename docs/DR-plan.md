# PMBRS — Disaster Recovery Plan (Stage 9)

## Scope

This document covers disaster recovery for the **database tier** — full loss or corruption of `mes-lab-vm`'s data volume. It is the infrastructure-level counterpart to `rollback-plan.md`, which covers application-code-level rollback on the app tier and does not address database or volume-level failure.

## Backup Mechanism

Volume-level backup via AWS EBS snapshots. A snapshot captures the complete state of `mes-lab-vm`'s attached volume — including the full Oracle installation, the PMBRS schema, and all data — at the moment the snapshot is taken.

Snapshots are taken **live**, with no instance downtime required; `mes-lab-vm` remained running and reachable throughout the snapshot process performed for this test.

## DR Test — Method and Real Results

A full restore was performed and independently verified, not assumed to work from documentation alone. Steps:

1. Created an EBS snapshot of `mes-lab-vm`'s in-use volume (`vol-0b7befcfda8c38f00`, 60GB, gp2).
2. Created a new volume from that completed snapshot in the same Availability Zone (us-east-2b).
3. Attached the new volume to `mes-lab-vm` as a **second** disk, leaving the live boot volume and running Oracle instance completely untouched throughout.
4. Brought the restored disk online in Windows Disk Management. It mounted cleanly as `E:`, with no signature conflict or initialization required.
5. Verified real data was present and intact: Oracle's core tablespace files (`SYSTEM01.DBF`, `SYSAUX01.DBF`), control files, redo logs, and the `XEPDB1` pluggable database structure were all present at their expected sizes — not empty placeholders.
6. Cleaned up: took the restored disk offline, detached and deleted the temporary volume. The original snapshot was retained as ongoing DR evidence/backup.

### Measured Results

| Metric | Result |
|---|---|
| Snapshot creation time (60GB, in-use volume) | 24 minutes (4:48 PM start, 5:12 PM completed) |
| Volume creation, attach, and mount (mechanical steps only) | A few minutes each; not the bottleneck in this process |
| Data integrity | Confirmed — all expected Oracle data files present at correct, non-zero sizes |
| Instance downtime required for backup | None — mes-lab-vm remained running throughout |
| Instance downtime required to test restore | None — restored volume attached alongside the live boot volume, no impact to the running production system |

## RPO / RTO — Database Tier

**RPO (Recovery Point Objective): equal to the time since the last snapshot was taken.** Snapshots are not currently scheduled/automated for PMBRS — they are taken manually. This means the realistic RPO today is "however long it has been since the last manual snapshot," which is a real, acknowledged gap rather than a hidden one. A production system would address this with a scheduled snapshot policy (e.g. AWS Data Lifecycle Manager, hourly or daily depending on acceptable data loss) rather than relying on manual action.

**RTO (Recovery Time Objective): the snapshot-to-mounted-and-verified-data time, approximately 30-40 minutes** for a volume this size, based on the measured 24-minute snapshot creation plus the (much shorter) volume creation, attach, and verification steps. This is the time to have a fully restored, data-verified volume ready to use — not including the additional step of actually reconfiguring Oracle to run from the restored data if the original instance were genuinely lost (e.g. pointing a fresh EC2 instance at the restored volume as its boot disk, reinstalling the Oracle listener configuration, etc.), which was not exercised in this test and would extend real-world RTO further. That fuller "instance replacement" scenario is noted as a reasonable next test, not claimed as already covered here.

## What This Test Did NOT Cover

- **Full instance loss.** This test proved the *data* is recoverable and intact, using a live instance as the attachment target. It did not test recovering onto a brand-new EC2 instance after `mes-lab-vm` itself was lost entirely — that is a materially different, more involved scenario (new instance, reattaching as boot volume, reconfiguring networking/security groups) and is flagged here as an honest boundary of what was tested, not claimed as proven.
- **Automated/scheduled backups.** Snapshot creation here was a manual, one-time action for this test. No recurring backup schedule currently exists for PMBRS.
- **Cross-region or cross-AZ recovery.** The restored volume was created in the same AZ as the original. A true regional-disaster scenario (loss of us-east-2b entirely) was not tested.

## Result

The core question this test set out to answer — **"if the database volume were lost, is the backup actually restorable and does it contain real, intact data?"** — was answered with direct evidence, not assumption. The restored volume mounted cleanly, contained correctly-sized Oracle data files, and required no manual repair to be readable. This is the meaningful proof point for Stage 9: a backup that has never been test-restored is not a verified backup, only a hoped-for one.
