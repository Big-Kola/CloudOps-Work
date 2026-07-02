# Day 13: AWS IAM & EC2

## Concept

**IAM (Identity and Access Management)** — AWS's permission system. Three core components:
- **Users** — individuals or service accounts (long-term credentials: password + access keys)
- **Groups** — collections of users with shared permissions
- **Roles** — assumed by trusted entities (EC2 instances, Lambda, users from other accounts) — temporary credentials via STS
- **Policies** — JSON documents that define permissions (Allow/Deny on resources). Attached to users, groups, or roles.

**EC2 (Elastic Compute Cloud)** — virtual machines in the cloud. Key concepts:
- AMI (Amazon Machine Image) — base OS image
- Instance types (t3.micro, m5.large, etc.) — CPU/memory/network capacity
- Security Groups — instance-level firewalls (allow rules only)
- Key Pairs — SSH public/private keys for instance access
- User Data — startup script (cloud-init)

Least privilege is the golden rule: grant only the permissions needed.

## Task

1. **Create an IAM user with CLI access** — [IAM user docs](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_users.html)
   ```bash
   aws iam create-user --user-name dev-user
   aws iam create-access-key --user-name dev-user
   ```

2. **Attach a managed policy** — [IAM policy docs](https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html)
   ```bash
   aws iam attach-user-policy \
     --user-name dev-user \
     --policy-arn arn:aws:iam::aws:policy/AmazonEC2ReadOnlyAccess
   ```

3. **Create an IAM role for EC2** — `ec2-role.json` — [IAM role docs](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles.html), [IAM roles for EC2](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/iam-roles-for-amazon-ec2.html)
   ```json
   {
     "RoleName": "EC2-S3-ReadOnly-Role",
     "AssumeRolePolicyDocument": {
       "Version": "2012-10-17",
       "Statement": [{
         "Effect": "Allow",
         "Principal": {
           "Service": "ec2.amazonaws.com"
         },
         "Action": "sts:AssumeRole"
       }]
     }
   }
   ```
   ```bash
   aws iam create-role --cli-input-json file://ec2-role.json
   aws iam attach-role-policy \
     --role-name EC2-S3-ReadOnly-Role \
     --policy-arn arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess
   aws iam create-instance-profile --instance-profile-name EC2-S3-Profile
   aws iam add-role-to-instance-profile \
     --instance-profile-name EC2-S3-Profile \
     --role-name EC2-S3-ReadOnly-Role
   ```

4. **Launch an EC2 instance** — [EC2 run-instances docs](https://docs.aws.amazon.com/cli/latest/reference/ec2/run-instances.html)
   ```bash
   # Get the latest Amazon Linux 2 AMI
   aws ec2 run-instances \
     --image-id ami-0c55b159cbfafe1f0 \
     --instance-type t3.micro \
     --key-name your-key-pair \
     --security-group-ids sg-xxx \
     --iam-instance-profile Name=EC2-S3-Profile \
     --user-data '#!/bin/bash
       yum update -y
       yum install -y httpd
       systemctl start httpd
       echo "Hello from EC2" > /var/www/html/index.html'
   ```

5. **Connect via SSH** — [EC2 SSH docs](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/connect-to-linux-instance.html)
   ```bash
   aws ec2 describe-instances --query "Reservations[*].Instances[*].PublicIpAddress"
   ssh -i my-key.pem ec2-user@<public-ip>
   ```

6. **Test the IAM role** (inside the instance)
   ```bash
   aws s3 ls  # should work because of the role
   aws ec2 describe-instances  # should fail (no EC2 permission)
   ```

7. **Terminate** — `aws ec2 terminate-instances --instance-ids <id>` — [EC2 terminate docs](https://docs.aws.amazon.com/cli/latest/reference/ec2/terminate-instances.html)

## Real-world relevance

IAM is the foundation of AWS security. Every service uses it. EC2 with IAM roles (never hardcoded keys!) is the standard pattern. Security Groups are your first line of defense. User data automates bootstrapping.

## Summary

- IAM Users = long-term credentials for humans or services
- IAM Roles = temporary credentials assumed by AWS services
- Policies are JSON documents — follow least privilege
- EC2: AMI + instance type + SG + key pair + user data
- Never put access keys on EC2 — use IAM roles instead

## Interview Question

Explain the difference between an IAM user and an IAM role. When would you use each? How do you securely give an EC2 instance permission to write to an S3 bucket? Walk through the entire setup.
