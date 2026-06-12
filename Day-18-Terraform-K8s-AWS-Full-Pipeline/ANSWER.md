# Day 18 — Model Answer

## Design a complete CI/CD pipeline for a microservice on EKS provisioned by Terraform.

### How does Terraform get the EKS kubeconfig to use the K8s provider?

The K8s provider authenticates using the EKS cluster's token:
```hcl
provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.cluster.token
}
```
The `data.aws_eks_cluster_auth` generates a signed STS token with a 15-minute expiry. This is the standard secure way to authenticate Terraform's K8s provider to EKS without storing static kubeconfig files.

### Git workflow:

- **develop branch** — developers push feature branches, PRs merge here
- **main branch** — protected, merges trigger deployment to staging
- **release tags** — `v1.2.3` triggers deployment to production
- Each PR runs `terraform fmt -check`, `terraform validate`, `terraform plan`
- Merges to main: `terraform apply` for infra changes + build + deploy

### How does the deployment know which image tag to use?

The CI pipeline passes the Git commit SHA as the image tag:
```yaml
- name: Build and push
  run: |
    docker build -t $ECR_REGISTRY/$ECR_REPOSITORY:${{ github.sha }} .
    docker push $ECR_REGISTRY/$ECR_REPOSITORY:${{ github.sha }}

- name: Terraform apply
  env:
    TF_VAR_app_image_tag: ${{ github.sha }}
  run: terraform apply --auto-approve
```
The `TF_VAR_` prefix sets a Terraform variable, which is used in the Kubernetes deployment spec:
```hcl
image = "${aws_ecr_repository.app.repository_url}:${var.app_image_tag}"
```

### How do you handle rollbacks?

- **Kubernetes level:** `kubectl rollout undo deployment/app` reverts to the previous ReplicaSet
- **Helm level:** `helm rollback myapp 2` reverts to revision 2
- **Git level:** revert the commit and push — CI builds the old image tag and reapplies
- **Terraform level:** `terraform apply` with a previous state version or revert the infra PR

### How does IAM authentication work between Terraform, EKS, and ECR?

1. **Terraform ↔ AWS:** AWS credentials (env vars, IAM role, or shared config) — Terraform uses the AWS provider
2. **Terraform ↔ EKS:** The K8s provider generates an EKS token via STS — no permanent kubeconfig needed
3. **CI/CD ↔ ECR:** The CI runner assumes an IAM role that has `ecr:GetAuthorizationToken`, `ecr:BatchCheckLayerAvailability`, `ecr:PutImage`
4. **EKS ↔ ECR:** Nodes have an IAM role attached with `ecr:GetDownloadUrlForLayer`, `ecr:BatchGetImage` — allows pulling images without Docker login on each node
5. **Terraform Helm provider ↔ EKS:** Same K8s token as the K8s provider, tunneled through the Helm provider's Kubernetes config
