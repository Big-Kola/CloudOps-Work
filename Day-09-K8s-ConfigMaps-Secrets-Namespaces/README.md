# Day 9: ConfigMaps, Secrets, Namespaces

## Concept

**ConfigMap** — stores non-sensitive configuration as key-value pairs. Mounted as env vars, files, or command-line args.

**Secret** — similar to ConfigMap but base64-encoded and designed for sensitive data (passwords, tokens, certs). Encrypted at rest if etcd encryption is enabled.

**Namespace** — virtual cluster within a physical cluster. Isolates resources, enables multi-team tenancy, and scopes resource quotas and network policies.

## Task

1. **Create namespaces** — [namespace docs](https://kubernetes.io/docs/concepts/overview/working-with-objects/namespaces/)
   ```bash
   kubectl create namespace dev
   kubectl create namespace prod
   kubectl get namespaces
   ```

2. **Create a ConfigMap** — `configmap.yaml` — [ConfigMap YAML reference](https://kubernetes.io/docs/reference/kubernetes-api/config-and-storage-resources/config-map-v1/)
   ```yaml
   apiVersion: v1
   kind: ConfigMap
   metadata:
     name: app-config
     namespace: dev
   data:
     APP_ENV: development
     LOG_LEVEL: debug
     app.properties: |
       feature_x=true
       max_connections=100
   ```

3. **Create a Secret** — `secret.yaml` — [Secret YAML reference](https://kubernetes.io/docs/reference/kubernetes-api/config-and-storage-resources/secret-v1/)
   ```yaml
   apiVersion: v1
   kind: Secret
   metadata:
     name: db-secret
     namespace: dev
   type: Opaque
   data:
     DB_PASSWORD: cGFzc3dvcmQxMjM=  # "password123" base64
     DB_USER: YWRtaW4=                # "admin" base64
   ```

4. **Create a deployment that uses both** — `deploy.yaml` — [Configuring Pods with ConfigMaps](https://kubernetes.io/docs/tasks/configure-pod-container/configure-pod-configmap/), [Distributing Secrets](https://kubernetes.io/docs/tasks/inject-data-application/distribute-credentials-secure/)
   ```yaml
   apiVersion: apps/v1
   kind: Deployment
   metadata:
     name: app
     namespace: dev
   spec:
     replicas: 1
     selector:
       matchLabels:
         app: myapp
     template:
       metadata:
         labels:
           app: myapp
       spec:
         containers:
           - name: app
             image: nginx:alpine
             env:
               - name: APP_ENV
                 valueFrom:
                   configMapKeyRef:
                     name: app-config
                     key: APP_ENV
               - name: DB_PASSWORD
                 valueFrom:
                   secretKeyRef:
                     name: db-secret
                     key: DB_PASSWORD
             volumeMounts:
               - name: config-volume
                 mountPath: /etc/config
               - name: secret-volume
                 mountPath: /etc/secrets
         volumes:
           - name: config-volume
             configMap:
               name: app-config
           - name: secret-volume
               secret:
                 name: db-secret
   ```

5. **Apply everything**
   ```bash
   kubectl apply -f configmap.yaml
   kubectl apply -f secret.yaml
   kubectl apply -f deploy.yaml
   ```

6. **Verify**
   ```bash
   kubectl exec -n dev deploy/app -- env | grep -E "APP_ENV|DB_PASSWORD"
   kubectl exec -n dev deploy/app -- cat /etc/config/app.properties
   kubectl exec -n dev deploy/app -- ls /etc/secrets
   ```

7. **Resource quota in namespace** — `quota.yaml` — [ResourceQuota docs](https://kubernetes.io/docs/concepts/policy/resource-quotas/)
   ```yaml
   apiVersion: v1
   kind: ResourceQuota
   metadata:
     name: dev-quota
     namespace: dev
   spec:
     hard:
       pods: 10
       requests.cpu: 2
       requests.memory: 4Gi
       limits.cpu: 4
       limits.memory: 8Gi
   ```

## Real-world relevance

ConfigMaps and Secrets decouple config from container images — you can promote the same image through dev → staging → prod and swap config per environment. Namespaces prevent teams from stepping on each other and enable resource quotas, RBAC, and network policies scoped per team.

## Summary

- ConfigMap: non-sensitive config (env vars, files)
- Secret: sensitive data (base64, encryptable at rest)
- Namespaces: virtual clusters for isolation and multi-tenancy
- Always scope resources to namespaces: `-n dev` or `namespace: dev`
- ResourceQuota limits what a namespace can consume

## Interview Question

What's the difference between ConfigMap and Secret? How would you handle database passwords across dev, staging, and prod environments? What happens when you update a ConfigMap — do running pods automatically pick up the change?
