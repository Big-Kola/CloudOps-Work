# Day 16 — Model Answer

## How does IAM authentication work with EKS?

EKS uses IAM for authentication (who you are) and Kubernetes RBAC for authorization (what you can do):

1. **Authenticate:** `aws eks get-token` generates a token signed by the AWS STS API. The token is passed as a Bearer token in kubectl requests
2. **Map IAM to RBAC:** The `aws-auth` ConfigMap in the `kube-system` namespace maps IAM roles/users to Kubernetes RBAC users/groups
3. **Authorize:** Kubernetes API Server validates the token via the EKS webhook authenticator, extracts the IAM role ARN, looks up the mapping in `aws-auth`, and applies RBAC rules

## What's the aws-auth ConfigMap?

A ConfigMap that maps IAM principals to Kubernetes RBAC identities:
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: aws-auth
  namespace: kube-system
data:
  mapRoles: |
    - rolearn: arn:aws:iam::123456:role/EKS-Worker-Role
      username: system:node:{{EC2PrivateDNSName}}
      groups:
        - system:bootstrappers
        - system:nodes
  mapUsers: |
    - userarn: arn:aws:iam::123456:user/admin
      username: admin
      groups:
        - system:masters
```

## EKS vs self-managed K8s:

| Factor | EKS | Self-Managed |
|--------|-----|--------------|
| Control plane | AWS manages (HA, upgrades, patches) | You manage (etcd, API server, scheduler) |
| Cost | Control plane costs ~$0.10/hr (~$73/mo) | No control plane cost (just EC2 for masters) |
| Operations | Zero control plane maintenance | Full operational burden |
| Upgrades | AWS handles control plane upgrades | Manual control plane upgrades |
| Integration | Native IAM, ALB, VPC CNI | Custom integration needed |
| Flexibility | Limited to supported versions | Full control over version, addons, config |
