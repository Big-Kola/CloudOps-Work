# Day 16: EKS & ECR

## Concept

**EKS (Elastic Kubernetes Service)** — managed Kubernetes control plane. AWS runs the API Server and etcd; you manage worker nodes (or use Fargate for serverless). Integrates with IAM (EKS-specific IAM roles), VPC (CNI for pod networking), and ALB (ALB Ingress Controller).

**ECR (Elastic Container Registry)** — private Docker registry. Stores container images, integrates with IAM for access control, and works with EKS natively.

## Task

1. **Create an ECR repository**
   ```bash
   aws ecr create-repository --repository-name hello-app
   ```

2. **Build and push an image**
   ```bash
   # Get the login command
   aws ecr get-login-password --region us-east-1 | \
     docker login --username AWS --password-stdin <account>.dkr.ecr.us-east-1.amazonaws.com

   # Create a Dockerfile
   cat > Dockerfile << 'EOF'
   FROM nginx:alpine
   COPY index.html /usr/share/nginx/html/index.html
   EOF
   echo "Hello from EKS" > index.html

   # Build, tag, push
   docker build -t hello-app .
   docker tag hello-app:latest <account>.dkr.ecr.us-east-1.amazonaws.com/hello-app:latest
   docker push <account>.dkr.ecr.us-east-1.amazonaws.com/hello-app:latest
   ```

3. **Create an EKS cluster** (this takes ~10-15 min)
   ```bash
   aws eks create-cluster \
     --name cloudops-cluster \
     --role-arn arn:aws:iam::<account>:role/EKS-Cluster-Role \
     --resources-vpc-config subnetIds=subnet-xxx,subnet-yyy
   aws eks wait cluster-active --name cloudops-cluster
   ```

4. **Create a node group**
   ```bash
   aws eks create-nodegroup \
     --cluster-name cloudops-cluster \
     --nodegroup-name standard-workers \
     --scaling-config minSize=2,maxSize=4,desiredSize=2 \
     --subnets subnet-xxx subnet-yyy \
     --instance-types t3.medium \
     --node-role arn:aws:iam::<account>:role/EKS-Worker-Role
   ```

5. **Configure kubectl**
   ```bash
   aws eks update-kubeconfig --name cloudops-cluster --region us-east-1
   kubectl get nodes
   ```

6. **Deploy the image from ECR** — `deploy.yaml`
   ```yaml
   apiVersion: apps/v1
   kind: Deployment
   metadata:
     name: hello-app
   spec:
     replicas: 3
     selector:
       matchLabels:
         app: hello-app
     template:
       metadata:
         labels:
           app: hello-app
       spec:
         containers:
           - name: hello-app
             image: <account>.dkr.ecr.us-east-1.amazonaws.com/hello-app:latest
             ports:
               - containerPort: 80
   ---
   apiVersion: v1
   kind: Service
   metadata:
     name: hello-svc
   spec:
     selector:
       app: hello-app
     ports:
       - port: 80
         targetPort: 80
     type: LoadBalancer
   ```

7. **Apply and access**
   ```bash
   kubectl apply -f deploy.yaml
   kubectl get svc hello-svc  # wait for EXTERNAL-IP
   curl http://<external-ip>
   ```

8. **Clean up** (important — EKS costs money)
   ```bash
   kubectl delete -f deploy.yaml
   aws eks delete-nodegroup --cluster-name cloudops-cluster --nodegroup-name standard-workers
   aws eks delete-cluster --name cloudops-cluster
   aws ecr delete-repository --repository-name hello-app --force
   ```

## Real-world relevance

EKS + ECR is the standard AWS-native approach to Kubernetes. You build images in ECR (private, integrated with IAM) and deploy them to EKS. EKS handles the control plane HA, upgrades, and scaling. Combined with ALB Ingress Controller, it's a battle-tested production setup.

## Summary

- ECR stores container images (private, IAM-authenticated)
- EKS provides a managed K8s control plane
- Node groups run the worker nodes (EC2 or Fargate)
- `aws eks update-kubeconfig` configures kubectl
- EKS integrates with ALB, IAM, and VPC CNI natively
- Always clean up EKS resources to avoid costs

## Interview Question

How does IAM authentication work with EKS? What's the aws-auth ConfigMap and how do you map IAM roles to Kubernetes RBAC? Compare EKS with self-managed K8s — when would you choose one over the other?
