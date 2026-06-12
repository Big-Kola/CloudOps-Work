# Day 14: S3 & VPC

## Concept

**S3 (Simple Storage Service)** — object storage. Buckets hold objects (files). Key features:
- Unlimited storage, 99.999999999% durability
- Storage classes: Standard, Infrequent Access, Glacier (archive)
- Bucket policies and ACLs for access control
- Versioning, encryption (SSE-S3, SSE-KMS, SSE-C)
- Static website hosting
- Cross-region replication

**VPC (Virtual Private Cloud)** — your private network in AWS. Key components:
- CIDR block (e.g., 10.0.0.0/16)
- Subnets (public = has route to Internet Gateway, private = no direct internet)
- Internet Gateway (IGW) — allows public internet access
- NAT Gateway / NAT Instance — allows private subnets to access internet (updates, etc.)
- Route Tables — control traffic between subnets, IGW, NAT
- Security Groups — instance-level firewall (stateful)
- NACLs — subnet-level firewall (stateless)

## Task

### S3

1. **Create a bucket**
   ```bash
   aws s3 mb s3://cloudops-tasks-$(aws sts get-caller-identity --query Account --output text)
   ```

2. **Upload and manage objects**
   ```bash
   echo "Hello S3" > hello.txt
   aws s3 cp hello.txt s3://your-bucket/
   aws s3 ls s3://your-bucket/
   aws s3 presign s3://your-bucket/hello.txt --expires-in 3600
   ```

3. **Enable versioning**
   ```bash
   aws s3api put-bucket-versioning \
     --bucket your-bucket \
     --versioning-configuration Status=Enabled
   aws s3api list-object-versions --bucket your-bucket
   ```

4. **Apply a bucket policy** — `policy.json`
   ```json
   {
     "Version": "2012-10-17",
     "Statement": [
       {
         "Effect": "Deny",
         "Principal": "*",
         "Action": "s3:*",
         "Resource": "arn:aws:s3:::your-bucket/*",
         "Condition": {
           "Bool": {
             "aws:SecureTransport": "false"
           }
         }
       }
     ]
   }
   ```
   ```bash
   aws s3api put-bucket-policy --bucket your-bucket --policy file://policy.json
   ```

### VPC

5. **Create a VPC**
   ```bash
   aws ec2 create-vpc --cidr-block 10.0.0.0/16
   # Note the VPC ID, let's say vpc-xxxx
   ```

6. **Create subnets**
   ```bash
   aws ec2 create-subnet --vpc-id vpc-xxxx --cidr-block 10.0.1.0/24
   aws ec2 create-subnet --vpc-id vpc-xxxx --cidr-block 10.0.2.0/24
   ```

7. **Create and attach an Internet Gateway**
   ```bash
   aws ec2 create-internet-gateway
   aws ec2 attach-internet-gateway --vpc-id vpc-xxxx --internet-gateway-id igw-xxxx
   ```

8. **Create a route table for public subnet**
   ```bash
   aws ec2 create-route-table --vpc-id vpc-xxxx
   aws ec2 create-route --route-table-id rtb-xxxx --destination-cidr-block 0.0.0.0/0 --gateway-id igw-xxxx
   aws ec2 associate-route-table --route-table-id rtb-xxxx --subnet-id subnet-xxxx
   ```

9. **Add a NACL to block SSH from a specific IP** — or just observe the default NACL (allows all).
   ```bash
   # Replace the default NACL entry to deny SSH from 0.0.0.0/0
   aws ec2 describe-network-acls --filters "Name=vpc-id,Values=vpc-xxxx"
   ```

10. **Launch an EC2 instance in the public subnet** and verify internet access (should be able to ping 8.8.8.8 or curl google.com).

## Real-world relevance

S3 is the backbone of cloud storage — logs, backups, static assets, Terraform state, data lakes. VPC design is the first thing you plan in any AWS migration. Public vs private subnet architecture separates publicly-accessible services from internal databases.

## Summary

- S3: object storage with versioning, policies, encryption, static hosting
- VPC: your isolated network with subnets, IGW, NAT, route tables
- Public subnet = route to IGW; Private subnet = route to NAT or no internet
- Security Groups (stateful) vs NACLs (stateless, subnet-level)

## Interview Question

Design a VPC for a 3-tier web application (web, app, db). Which tiers go in public vs private subnets? What's the difference between a Security Group and a NACL? How would you allow the app tier to access the internet for updates without exposing it to inbound traffic?
