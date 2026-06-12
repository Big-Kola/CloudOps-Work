# Day 13 — Model Answer

## Difference between an IAM user and an IAM role:

| Feature | IAM User | IAM Role |
|---------|----------|----------|
| Credentials | Long-term (access key + secret key, password) | Temporary (STS: temporary credentials, auto-rotate) |
| Identity | Represents a person or service with persistent identity | Assumed by a trusted entity, no permanent credentials |
| Use case | Humans (CLI, console), long-running service accounts | EC2 instances, Lambda, cross-account access |
| Authentication | Static credentials | Dynamic via `sts:AssumeRole` |

## How to give an EC2 instance permission to write to an S3 bucket:

1. **Create an IAM role** with a trust policy allowing `ec2.amazonaws.com` to assume it
2. **Attach a policy** to the role granting `s3:PutObject` on the target bucket
3. **Create an instance profile** and add the role to it
4. **Launch EC2** with `--iam-instance-profile Name=MyProfile`
5. Inside the instance, the AWS SDK automatically retrieves temporary credentials from the instance metadata service (`http://169.254.169.254/latest/meta-data/iam/security-credentials/`)
6. The instance can now run `aws s3 cp file.txt s3://bucket/` without any hardcoded keys

**Never put AWS access keys on EC2** — keys can be stolen from the instance. IAM roles with STS are the only secure approach.
