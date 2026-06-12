# Day 18: Terraform + K8s + AWS — Full Pipeline

## Concept

This is the culmination — all three tools working together:

1. **Terraform** → Provisions the EKS cluster and all AWS infrastructure (VPC, subnets, IAM roles, ECR)
2. **Terraform Kubernetes provider** → Deploys namespaces, deployments, services into the EKS cluster
3. **Helm provider** → Installs charts (nginx-ingress, metrics-server) via Terraform
4. **CI/CD** → GitHub Actions builds the Docker image → pushes to ECR → triggers Terraform apply with the new image tag

This is the "Infrastructure as Code + GitOps" golden path.

## Task

This is a large task. Break it into stages.

### Stage 1: Terraform provisions EKS infrastructure

1. **Create the Terraform structure**
   ```
   Day-18-Terraform-K8s-AWS-Full-Pipeline/
   ├── main.tf
   ├── provider.tf
   ├── variables.tf
   ├── outputs.tf
   ├── terraform.tfvars.example
   └── modules/
       └── app/
           ├── main.tf
           ├── variables.tf
           └── outputs.tf
   ```

2. **`provider.tf`** — AWS + Kubernetes + Helm providers
   ```hcl
   terraform {
     required_providers {
       aws = {
         source  = "hashicorp/aws"
         version = "~> 5.0"
       }
       kubernetes = {
         source  = "hashicorp/kubernetes"
         version = "~> 2.0"
       }
       helm = {
         source  = "hashicorp/helm"
         version = "~> 2.0"
       }
     }
     backend "s3" {
       bucket = "your-tf-state-bucket"
       key    = "day18/terraform.tfstate"
       region = "us-east-1"
       dynamodb_table = "terraform-locks"
       encrypt = true
     }
   }

   provider "aws" {
     region = var.aws_region
   }

   data "aws_eks_cluster" "cluster" {
     name = module.eks.cluster_name
   }

   data "aws_eks_cluster_auth" "cluster" {
     name = module.eks.cluster_name
   }

   provider "kubernetes" {
     host                   = data.aws_eks_cluster.cluster.endpoint
     cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data)
     token                  = data.aws_eks_cluster_auth.cluster.token
   }

   provider "helm" {
     kubernetes {
       host                   = data.aws_eks_cluster.cluster.endpoint
       cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data)
       token                  = data.aws_eks_cluster_auth.cluster.token
     }
   }
   ```

3. **`main.tf`** — VPC + EKS + ECR
   ```hcl
   module "vpc" {
     source  = "terraform-aws-modules/vpc/aws"
     version = "5.8.1"

     name = "day18-vpc"
     cidr = "10.0.0.0/16"
     azs  = ["us-east-1a", "us-east-1b"]

     private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
     public_subnets  = ["10.0.101.0/24", "10.0.102.0/24"]

     enable_nat_gateway = true
     enable_vpn_gateway = false

     tags = { Environment = "day18" }
   }

   module "eks" {
     source  = "terraform-aws-modules/eks/aws"
     version = "20.8.5"

     cluster_name    = "day18-cluster"
     cluster_version = "1.29"

     vpc_id     = module.vpc.vpc_id
     subnet_ids = module.vpc.private_subnets

     eks_managed_node_groups = {
       main = {
         desired_size = 2
         min_size     = 1
         max_size     = 3
         instance_types = ["t3.medium"]
       }
     }

     tags = { Environment = "day18" }
   }

   resource "aws_ecr_repository" "app" {
     name = "day18-app"
     force_delete = true
   }

   output "ecr_repository_url" {
     value = aws_ecr_repository.app.repository_url
   }

   output "cluster_name" {
     value = module.eks.cluster_name
   }
   ```

4. **Apply** — `terraform init && terraform apply --auto-approve`

### Stage 2: Deploy the app via Terraform Kubernetes provider

5. **`modules/app/main.tf`** — deploy an nginx app
   ```hcl
   variable "namespace" {
     type    = string
     default = "production"
   }

   variable "replicas" {
     type    = number
     default = 2
   }

   variable "image" {
     type = string
   }

   resource "kubernetes_namespace" "this" {
     metadata {
       name = var.namespace
     }
   }

   resource "kubernetes_deployment" "app" {
     metadata {
       name      = "app"
       namespace = kubernetes_namespace.this.metadata[0].name
     }
     spec {
       replicas = var.replicas
       selector {
         match_labels = {
           app = "app"
         }
       }
       template {
         metadata {
           labels = {
             app = "app"
           }
         }
         spec {
           container {
             image = var.image
             name  = "app"
             port {
               container_port = 80
             }
           }
         }
       }
     }
   }

   resource "kubernetes_service" "app" {
     metadata {
       name      = "app-svc"
       namespace = kubernetes_namespace.this.metadata[0].name
     }
     spec {
       selector = {
         app = "app"
       }
       port {
         port        = 80
         target_port = 80
       }
       type = "LoadBalancer"
     }
   }

   output "namespace" {
     value = kubernetes_namespace.this.metadata[0].name
   }
   ```

6. **Call the module from root** — add to root `main.tf`
   ```hcl
   module "app" {
     source   = "./modules/app"
     image    = "${aws_ecr_repository.app.repository_url}:latest"
     replicas = 2
     namespace = "production"
   }
   ```

7. **Apply again** — `terraform apply --auto-approve`

### Stage 3: CI/CD with GitHub Actions

8. **`.github/workflows/deploy.yml`**
   ```yaml
   name: Build and Deploy

   on:
     push:
       branches: [main]

   jobs:
     deploy:
       runs-on: ubuntu-latest
       steps:
         - uses: actions/checkout@v4

         - name: Configure AWS credentials
           uses: aws-actions/configure-aws-credentials@v4
           with:
             aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
             aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
             aws-region: us-east-1

         - name: Login to ECR
           id: login-ecr
           uses: aws-actions/amazon-ecr-login@v2

         - name: Build, tag, and push image
           env:
             ECR_REGISTRY: ${{ steps.login-ecr.outputs.registry }}
             ECR_REPOSITORY: day18-app
             IMAGE_TAG: ${{ github.sha }}
           run: |
             docker build -t $ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG .
             docker push $ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG

         - name: Setup Terraform
           uses: hashicorp/setup-terraform@v3
           with:
             terraform_version: 1.9.0

         - name: Terraform apply
           env:
             TF_VAR_app_image_tag: ${{ github.sha }}
           run: |
             terraform init
             terraform apply --auto-approve
   ```

9. **Trigger a deployment** — push a change to the repo, watch the GitHub Action run

10. **Clean up everything**
    ```bash
    terraform destroy --auto-approve
    ```

## Real-world relevance

This is the architecture that powers most modern cloud-native companies:
- Terraform manages the infrastructure (cluster, network, IAM)
- EKS runs the workloads
- ECR stores the container images
- CI/CD automates the build → push → deploy loop
- Everything is in code, reviewed via PRs, and versioned

## Summary

- Terraform can manage not just AWS infra but also Kubernetes resources via the K8s provider
- The Helm provider installs charts (nginx-ingress, cert-manager, etc.)
- EKS integrates natively with IAM, VPC CNI, and ALB
- CI/CD ties it all together: git push → build → ECR → Terraform apply → new pods
- Always destroy test environments to avoid costs

## Interview Question

Design a complete CI/CD pipeline for a microservice running on EKS, provisioned by Terraform. Walk through:
- How does Terraform get the EKS kubeconfig to use the K8s provider?
- What's the Git workflow (dev branch, main branch, PRs)?
- How does the deployment know which image tag to use?
- How do you handle rollbacks?
- How does IAM authentication work between Terraform, EKS, and ECR?

This is the final day. Congratulations — you've built end-to-end infrastructure with Terraform, Kubernetes, and AWS.
