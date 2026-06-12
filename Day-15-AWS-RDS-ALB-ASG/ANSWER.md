# Day 15 — Model Answer

## Design a highly-available web application architecture on AWS:

**Components:**
- **VPC** — `10.0.0.0/16` with public and private subnets across 2 AZs
- **ALB** — internet-facing, in public subnets, listens on port 80/443
- **Target Group** — routes to EC2 instances on port 80, with health checks
- **ASG** — EC2 instances in private subnets, min 2 / max 10, attaches to the target group
- **RDS** — Multi-AZ MySQL/PostgreSQL in private DB subnets, not publicly accessible

**Traffic flow:**
1. User hits the ALB's DNS name (`https://web-alb-123.elb.amazonaws.com`)
2. ALB terminates TLS (optional), forwards HTTP to the target group
3. Target group distributes requests across healthy EC2 instances in the ASG
4. Application code on EC2 connects to RDS using the DB endpoint (internal DNS)
5. RDS Multi-AZ synchronously replicates to a standby in another AZ

## How does RDS Multi-AZ work?

A synchronous standby replica is provisioned in a different AZ. The primary synchronously replicates data to the standby. If the primary fails, AWS automatically fails over to the standby (DNS change, typically 60-120 seconds). Multi-AZ is for high availability, not read scaling (use Read Replicas for that).

## How does the ASG register instances with the ALB?

The ASG's launch configuration/template specifies a target group ARN. When a new instance launches:
1. The ASG automatically calls `RegisterTargets` on the target group
2. The ALB performs health checks (HTTP GET to `/health` or similar)
3. Once healthy, the instance starts receiving traffic
4. On scale-in or termination, the ASG deregisters the instance first, then terminates it (connection draining completes before shutdown)
