# 18-Day Schedule

## Week 1 — Terraform (Days 1–6)

| Day | Topic | Est. Time | Task |
|-----|-------|-----------|------|
| 1 | Providers, Resources, State | 1–2h | Create local file resource, run init/plan/apply |
| 2 | Variables, Data Sources, Outputs | 1–2h | Parameterize config, use data sources |
| 3 | Modules | 2–3h | Build and call a reusable module |
| 4 | Remote State & Backends | 1–2h | Store state in S3, add locking with DynamoDB |
| 5 | Meta-arguments & Lifecycle | 1–2h | Use count/for_each, lifecycle rules |
| 6 | CI/CD & Best Practices | 2h | Lint, format, validate, automate with GitHub Actions |

## Week 2 — Kubernetes (Days 7–12)

| Day | Topic | Est. Time | Task |
|-----|-------|-----------|------|
| 7 | Architecture, Pods, kubectl | 2h | Run pods imperatively & declaratively |
| 8 | Deployments & Services | 2h | Deploy nginx, expose via ClusterIP/NodePort |
| 9 | ConfigMaps, Secrets, Namespaces | 1–2h | Inject config, use secrets, multi-namespace |
| 10 | Ingress & Volumes | 2h | Set up Ingress controller, PV/PVC |
| 11 | Helm | 2h | Package and deploy with Helm charts |
| 12 | RBAC, Network Policies, Monitoring | 2h | Restrict access, monitor with metrics-server |

## Week 3 — AWS (Days 13–16)

| Day | Topic | Est. Time | Task |
|-----|-------|-----------|------|
| 13 | IAM & EC2 | 2h | Create roles, launch EC2, SSH in |
| 14 | S3 & VPC | 2h | Bucket policies, custom VPC with subnets |
| 15 | RDS, ALB, Auto Scaling | 2–3h | Launch RDS, ALB in front of ASG |
| 16 | EKS & ECR | 2–3h | Create EKS cluster, push image to ECR |

## Week 4 — Integration (Days 17–18)

| Day | Topic | Est. Time | Task |
|-----|-------|-----------|------|
| 17 | Terraform + AWS | 2h | Provision full AWS infra with Terraform |
| 18 | Terraform + K8s + AWS | 3h | EKS with Terraform, deploy app, CI/CD pipeline |
