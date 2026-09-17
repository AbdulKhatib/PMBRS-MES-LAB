# PMBRS — Azure Service Mapping (Stage 10)

## Purpose

This document maps PMBRS's actual AWS architecture to equivalent Azure services, as a way of applying AZ-900/cloud-fundamentals concepts against a system that was actually built and operated, rather than studying services in the abstract. No Azure infrastructure was built for this exercise — this is a conceptual mapping exercise, consistent with the project's original scope.

## Component Mapping

| PMBRS Component (AWS) | Azure Equivalent | Notes |
|---|---|---|
| EC2 (Windows Server 2022, app tier) | Azure Virtual Machine (Windows Server 2022) | Direct IaaS equivalent — same OS, same manual configuration responsibility |
| EC2 (Windows Server 2022, DB tier + Oracle XE) | Azure Virtual Machine | Oracle is not a native Azure PaaS offering; running Oracle on Azure means a VM either way — this is one case where "moving to Azure" would look almost identical to the current AWS setup, not simpler |
| VPC / subnet | Virtual Network (VNet) / Subnet | Same conceptual model — a private network boundary containing the resources |
| Security Groups | Network Security Groups (NSGs) | Same function: stateful, rule-based inbound/outbound filtering. The SG-to-SG reference pattern used for the app→DB Oracle connection has a direct NSG equivalent (referencing another NSG or Application Security Group as a rule source, rather than a static IP) |
| Elastic IP / public IP | Azure Public IP | Same concept — a static, internet-routable address assigned to a VM's NIC |
| EBS volume | Azure Managed Disk | Same role — persistent block storage attached to a VM, independent of the VM's lifecycle |
| EBS Snapshot | Azure Managed Disk Snapshot | Directly equivalent mechanism — point-in-time, live (no VM downtime required), used the same way in this project's DR test |
| IIS (on Windows Server) | IIS on Azure VM, or Azure App Service | IIS-on-VM is the direct equivalent, matching this project's actual setup. App Service is Azure's PaaS alternative — it would remove the need to manage IIS, Windows Firewall, and the OS entirely, at the cost of losing some low-level control this project deliberately wanted (e.g. direct wfastcgi configuration, IIS `web.config` handler tuning) |
| Manual RDP-based server administration | Same (RDP to VM), or Azure Bastion for browser-based access without exposing RDP publicly | Azure Bastion is a meaningful security improvement over this project's current "My IP" RDP security group pattern — worth noting as a real upgrade path, not just a rename |
| Batch/PowerShell CI/CD pipeline (local scripts) | Azure DevOps Pipelines, or GitHub Actions | The BUILD→TEST→DEPLOY→VERIFY logic in this project's `.bat` scripts maps conceptually to pipeline *stages* in either tool — the difference is execution location: this project's pipeline runs manually on the server itself, while Azure DevOps/GitHub Actions would run from a managed runner and push changes out to the VM, a meaningful architectural difference, not just a tooling swap |
| Manual credential storage (`config.py`, gitignored) | Azure Key Vault | This is a genuine gap in the current build worth naming honestly: PMBRS's credential handling (a gitignored local file) is a reasonable minimum for a lab, but Key Vault (or AWS's own equivalent, Secrets Manager, also not used here) is the correct pattern for anything beyond a lab — centrally managed, access-controlled, auditable secret storage instead of a file sitting on a server's disk |
| AWS account root / IAM | Microsoft Entra ID (formerly Azure AD) + RBAC | Identity and access management layer — this project used a single Administrator account throughout, which is itself worth flagging as a lab-scale simplification; a production system on either platform would use scoped, non-root credentials per component |
| CloudWatch (not used in this project) | Azure Monitor | Neither platform's monitoring service was used in this build — logging was limited to the application's own `deployment.log` and Windows Event Viewer. This is a real, acknowledged gap for a production system on either cloud |

## Cost Model Differences Observed

This project experienced two real AWS capacity/cost events worth noting against Azure's equivalent behavior:

- **AWS t3.medium was unavailable in us-east-2b** when the DB tier needed resizing, forcing a move to `m7i-flex.large` at roughly 4-5x the hourly cost. Azure's regional SKU availability follows the same general pattern (not every VM size is guaranteed in every region/zone) — this is a cloud-platform-general lesson, not AWS-specific, and the same capacity-check discipline would apply when sizing an Azure VM.
- **EBS/Managed Disk resizing** in this project required a stop → resize → start cycle with no data loss, since the disk is decoupled from the VM's lifecycle. Azure Managed Disks follow the same decoupled model.

## What Would Actually Change, Not Just Rename, If This Moved to Azure

Being specific rather than just swapping service names:

1. **Oracle stays exactly as complex.** Neither AWS nor Azure offers Oracle as a managed PaaS database in the way both offer their own SQL engines (RDS/Azure SQL). Moving PMBRS's database tier to Azure means the same manual Windows Server + Oracle install this project already did — no simplification here.
2. **The app tier could genuinely simplify** by moving from IIS-on-VM to Azure App Service, removing the entire wfastcgi/IIS configuration layer this project spent real effort building (see `docs/iis-build.md` incidents). This is the one place a PaaS move would meaningfully reduce operational surface area, at the cost of some of the low-level engineering this project specifically wanted to practice.
3. **Credential handling would need to genuinely change**, not just be renamed — moving `config.py` to Key Vault is an actual architectural improvement this project's current approach doesn't have, independent of which cloud is used.
4. **RDP-based management should move to Bastion (or Azure's equivalent access model)** rather than keeping "My IP" security-group rules — this project hit real friction from that pattern (IP drift breaking access three separate times) that a managed bastion/jump-host approach avoids entirely.

## Conclusion

The mapping exercise is most useful where it reveals genuine architectural differences rather than confirming that everything has a same-named counterpart. For PMBRS specifically: the database tier would look almost identical on Azure (Oracle-on-VM either way), the app tier has a real opportunity to simplify via a PaaS move, and the project's actual operational pain points during this build — IP-based access rules and local credential storage — map to specific, nameable Azure services (Bastion, Key Vault) that would have addressed them, which is a more concrete lesson than treating this as an abstract service-naming exercise.
