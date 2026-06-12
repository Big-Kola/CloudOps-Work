# Day 8: Deployments & Services

## Concept

**Deployment** — the standard way to run stateless applications. It manages ReplicaSets, which ensure N pod replicas run at all times. Deployments support rolling updates and rollbacks.

**Service** — a stable network endpoint to access pods. Pods die and get new IPs — Services provide a single DNS name and load-balance across healthy pods. Types:
- `ClusterIP` — internal cluster IP (default)
- `NodePort` — exposes on each node's IP at a static port
- `LoadBalancer` — provisions a cloud load balancer

## Task

1. **Create `deployment.yaml`**
   ```yaml
   apiVersion: apps/v1
   kind: Deployment
   metadata:
     name: nginx-deploy
   spec:
     replicas: 3
     selector:
       matchLabels:
         app: nginx
     template:
       metadata:
         labels:
           app: nginx
       spec:
         containers:
           - name: nginx
             image: nginx:alpine
             ports:
               - containerPort: 80
   ```

2. **Create `service.yaml`**
   ```yaml
   apiVersion: v1
   kind: Service
   metadata:
     name: nginx-svc
   spec:
     selector:
       app: nginx
     ports:
       - port: 80
         targetPort: 80
     type: ClusterIP
   ```

3. **Apply both**
   ```bash
   kubectl apply -f deployment.yaml
   kubectl apply -f service.yaml
   ```

4. **Examine the deployment**
   ```bash
   kubectl get deployments
   kubectl get replicasets
   kubectl get pods -l app=nginx
   kubectl describe deployment nginx-deploy
   ```

5. **Test the service**
   ```bash
   # Get the service's ClusterIP
   kubectl get svc nginx-svc

   # Run a temporary pod and curl the service
   kubectl run test-pod --image=busybox --rm -it --restart=Never -- wget -qO- http://nginx-svc
   ```

6. **Perform a rolling update**
   ```bash
   kubectl set image deployment/nginx-deploy nginx=nginx:1.25-alpine
   kubectl rollout status deployment/nginx-deploy
   ```

7. **Rollback**
   ```bash
   kubectl rollout undo deployment/nginx-deploy
   kubectl rollout status deployment/nginx-deploy
   ```

8. **Scale up**
   ```bash
   kubectl scale deployment/nginx-deploy --replicas=5
   ```

## Real-world relevance

Deployments + Services are the bread and butter of K8s. You deploy your app as a Deployment (for self-healing, scaling, updates) and expose it with a Service (for stable networking). This pattern is used for almost every stateless workload.

## Summary

- Deployment manages ReplicaSets → Pods (self-healing, scaling, rolling updates)
- Service provides stable DNS and load-balancing across pods
- `kubectl rollout` commands manage updates and rollbacks
- `kubectl scale` adjusts replica count

## Interview Question

Explain how a Service routes traffic to pods. What role do labels and selectors play? Walk through what happens when you update a Deployment's image — from the `kubectl set image` to the new pod serving traffic.
