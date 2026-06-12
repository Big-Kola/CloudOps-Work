# Day 10: Ingress & Volumes

## Concept

**Ingress** — exposes HTTP/HTTPS routes from outside the cluster to Services within the cluster. Unlike NodePort/LoadBalancer Services, Ingress gives you host-based and path-based routing, TLS termination, and virtual hosting — all in one reverse proxy (nginx, Traefik, HAProxy).

**Volumes** — containers are ephemeral; volumes provide persistent or temporary storage.
- `emptyDir` — ephemeral, pod-scoped (shares data between containers in a pod)
- `hostPath` — mounts a node file path (for daemonsets)
- `PersistentVolume (PV)` — cluster-wide storage resource provisioned by admin
- `PersistentVolumeClaim (PVC)` — a request for storage by a user. Pods use PVCs, which bind to PVs.

## Task

1. **Install an Ingress controller**
   ```bash
   kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml
   ```

2. **Wait for it to be ready**
   ```bash
   kubectl wait --namespace ingress-nginx \
     --for=condition=ready pod \
     --selector=app.kubernetes.io/component=controller \
     --timeout=180s
   ```

3. **Create a deployment and service**
   ```yaml
   # cafe.yaml
   apiVersion: apps/v1
   kind: Deployment
   metadata:
     name: coffee
   spec:
     replicas: 2
     selector:
       matchLabels:
         app: coffee
     template:
       metadata:
         labels:
           app: coffee
       spec:
         containers:
           - name: coffee
             image: nginx:alpine
             ports:
               - containerPort: 80
   ---
   apiVersion: v1
   kind: Service
   metadata:
     name: coffee-svc
   spec:
     selector:
       app: coffee
     ports:
       - port: 80
   ```

4. **Create an Ingress**
   ```yaml
   # ingress.yaml
   apiVersion: networking.k8s.io/v1
   kind: Ingress
   metadata:
     name: cafe-ingress
   spec:
     ingressClassName: nginx
     rules:
       - host: cafe.local
         http:
           paths:
             - path: /coffee
               pathType: Prefix
               backend:
                 service:
                   name: coffee-svc
                   port:
                     number: 80
   ```

5. **Apply and test**
   ```bash
   kubectl apply -f cafe.yaml
   kubectl apply -f ingress.yaml
   kubectl get ingress

   # Add to /etc/hosts: 127.0.0.1 cafe.local
   # In a new terminal: kubectl port-forward -n ingress-nginx svc/ingress-nginx-controller 8080:80
   # curl http://cafe.local:8080/coffee
   ```

6. **Create a PVC and pod that uses it** — `volume.yaml`
   ```yaml
   apiVersion: v1
   kind: PersistentVolumeClaim
   metadata:
     name: data-pvc
   spec:
     accessModes:
       - ReadWriteOnce
     resources:
       requests:
         storage: 1Gi
   ---
   apiVersion: v1
   kind: Pod
   metadata:
     name: data-pod
   spec:
     volumes:
       - name: data
         persistentVolumeClaim:
           claimName: data-pvc
     containers:
       - name: writer
         image: alpine
         command: ["sleep", "3600"]
         volumeMounts:
           - name: data
             mountPath: /data
   ```

7. **Test persistence**
   ```bash
   kubectl exec data-pod -- sh -c "echo 'persistent data' > /data/test.txt"
   kubectl delete pod data-pod
   kubectl apply -f volume.yaml  # re-create
   kubectl exec data-pod -- cat /data/test.txt  # still there
   ```

## Real-world relevance

Ingress is how you route production traffic — you have one public endpoint (ALB/nginx) that routes to different services based on the URL path or hostname. Volumes are essential for stateful apps (databases, message queues, file storage). PVC decouples storage consumption from provisioning.

## Summary

- Ingress = layer-7 routing (host/path based), TLS termination
- Need an Ingress controller (nginx, Traefik, ALB) for Ingress resources to work
- `emptyDir` = pod-scoped temporary storage
- `hostPath` = node file access (for system daemons)
- PV/PVC = persistent storage decoupled from pod lifecycle

## Interview Question

Explain how Ingress differs from a LoadBalancer Service. When would you use each? How do PersistentVolumeClaims work — walk through the lifecycle from PVC creation to pod attachment to data persistence across pod restarts.
