# Day 14 — Model Answer

## Design a VPC for a 3-tier web application:

**VPC CIDR:** `10.0.0.0/16`

| Tier | Subnet Type | CIDR | Purpose |
|------|-------------|------|---------|
| Web | Public | `10.0.1.0/24`, `10.0.2.0/24` | ALB (internet-facing) |
| App | Private | `10.0.10.0/24`, `10.0.11.0/24` | EC2/ASG (application logic) |
| DB | Private | `10.0.20.0/24`, `10.0.21.0/24` | RDS (database) |

**Why this layout:**
- **Web tier (public)** — ALB needs internet access to receive user traffic
- **App tier (private)** — EC2 instances don't need direct internet inbound; they receive traffic from the ALB only
- **DB tier (private)** — RDS should never be directly internet-accessible

## Security Group vs NACL:

| Feature | Security Group | NACL |
|---------|---------------|------|
| Level | Instance (ENI) | Subnet |
| State | Stateful (return traffic auto-allowed) | Stateless (return traffic must be explicitly allowed) |
| Rules | Allow only | Allow and Deny |
| Evaluation order | All rules evaluated | Rule numbers (lowest first) |
| Use case | Instance-level firewall (primary) | Subnet-level ACL (defense in depth) |

## How to allow app tier internet access without inbound exposure:

Place app instances in **private subnets** and route their outbound traffic through a **NAT Gateway** (or NAT Instance) in a public subnet. The NAT Gateway has an Elastic IP and can reach the internet for updates, package downloads, API calls. No inbound traffic from the internet reaches the private instances.
