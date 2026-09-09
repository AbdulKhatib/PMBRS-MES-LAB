# PMBRS — Architecture

## Overview

PMBRS is a three-tier fictional manufacturing application built to demonstrate real infrastructure engineering practices: Windows Server, IIS, Oracle, network segmentation, and Python/Flask deployment on AWS EC2.

## Topology

```
Laptop (browser)
      |
      | HTTP (port 8080)
      v
App Tier EC2 — pmbrs-app-vm
Windows Server 2022 / IIS / Python 3.14 / Flask (via wfastcgi)
      |
      | Oracle TCP (port 1521), private IP, same AZ
      v
DB Tier EC2 — mes-lab-vm
Windows Server 2022 / Oracle Database 21c XE / PMBRS schema (XEPDB1)
```

## Instance Details

| Attribute | App Tier — pmbrs-app-vm | DB Tier — mes-lab-vm |
|---|---|---|
| Role | IIS + Flask application | Oracle 21c XE database |
| OS | Windows Server 2022 | Windows Server 2022 |
| Instance type | t3.micro | m7i-flex.large (resized from t3.small after RAM exhaustion — see incident log) |
| Region / AZ | us-east-2 / us-east-2b | us-east-2 / us-east-2b |
| VPC / Subnet | Same VPC and subnet as DB tier | Same VPC and subnet as app tier |
| Private IP | 172.31.22.87 | 172.31.16.100 |
| Public IP | Yes (browser access) | No inbound web exposure |

## Design Decisions

**Two-tier split over single-VM.** App and database run on separate EC2 instances rather than one combined box. This mirrors real MES deployment patterns, gives each tier independently sized resources, and creates an actual network boundary to secure and document — rather than a single machine with everything colocated.

**Same AZ, same subnet.** Both instances were deliberately placed in us-east-2b to minimize latency and avoid cross-AZ data transfer costs on the app-to-database connection path, which is hit on every request.

**Private IP for inter-tier traffic.** The app tier connects to the database over its private IP (172.31.16.100), not its public IP. This keeps the traffic off the public internet, avoids any public-IP data transfer cost, and allows the DB tier's security group to scope Oracle access to the app tier specifically rather than any public source.

**No public web exposure on the DB tier.** mes-lab-vm has no inbound rule for port 80/443 — it is not, and should never be, reachable as a web server. Its only inbound exposure is RDP (management) and Oracle's listener port, scoped to the app tier's security group.

## Instance Sizing Note

The DB tier was originally provisioned as t3.small (2GB RAM). Oracle 21c XE's recommended minimum is 4GB, and the undersized instance caused intermittent listener/service instability under normal idle load (see incident log). The instance was resized to m7i-flex.large (8GB RAM) after t3.medium was unavailable in this AZ at the time of resizing. This is a genuine capacity constraint encountered during the build, not a planning oversight corrected in advance — documented here rather than hidden.
