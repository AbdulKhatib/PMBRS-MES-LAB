# PMBRS — Dependency Matrix (Security Groups)

## App Tier — pmbrs-app-vm

| Port | Protocol | Source | Purpose |
|---|---|---|---|
| 80 | TCP | My IP (updated manually per network) | Browser access — default site |
| 8080 | TCP | My IP (updated manually per network) | Browser access — PMBRS Flask application |
| 3389 | TCP | My IP (updated manually per network) | RDP management |

No inbound rule for port 1521 — this tier is an Oracle client, not a listener, and never accepts inbound database connections.

## DB Tier — mes-lab-vm

| Port | Protocol | Source | Purpose |
|---|---|---|---|
| 1521 | TCP | pmbrs-app-vm's security group (SG-to-SG reference, not IP-based) | Oracle listener — accepts connections only from the app tier |
| 3389 | TCP | My IP (updated manually per network) | RDP management |

No inbound rule for port 80/443 — the DB tier has zero web-facing exposure by design.

## Design Notes

**SG-to-SG reference for the database path.** The 1521 rule on the DB tier is scoped to the app tier's security group ID, not a specific IP address. This means the rule remains correct even if the app tier's private IP ever changes (e.g. after a stop/start cycle) — the reference tracks the security group membership, not a static address.

**"My IP" rules require manual maintenance.** Every rule scoped to "My IP" reflects whatever public IP was active at the time it was set. This project was built while moving between a home network and a work network, and this caused three separate access failures during the build — once for RDP, once for HTTP (port 80), and once for the Flask application (port 8080). Each time, the fix was the same: update the rule's source to the current public IP. This is documented here as a known operational pattern, not a one-off bug: any lab or production environment using IP-scoped access rules needs a process for updating them, or should move to a VPN/bastion approach instead.

**Windows Firewall is a second, independent gate.** AWS security groups control traffic at the network/VPC level. Windows Server's own firewall, running inside each instance, is a separate control that must also allow the same ports — a security group rule alone does not guarantee a service is reachable. This was encountered directly: Oracle's listener port (1521) required an explicit Windows Firewall rule in addition to the AWS security group rule before the app tier could successfully connect.
