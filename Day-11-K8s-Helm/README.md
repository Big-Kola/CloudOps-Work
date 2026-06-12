# Day 11: Helm

## Concept

**Helm** is the package manager for Kubernetes. It bundles YAML manifests into reusable **charts**. A chart is a versioned, templated, and configurable package that deploys a complete application.

Key concepts:
- **Chart** — a package (e.g., `nginx-ingress`, `prometheus`, `my-app`)
- **Values** — configuration values injected into templates (separates config from logic)
- **Release** — a running instance of a chart (you can install the same chart multiple times with different names)
- **Repository** — a collection of published charts (ArtifactHub is the public registry)

Chart structure:
```
mychart/
  Chart.yaml          # metadata (name, version, description)
  values.yaml         # default configuration values
  templates/          # Go-templated YAML manifests
  charts/             # subchart dependencies
```

## Task

1. **Install Helm** — [Helm install docs](https://helm.sh/docs/intro/install/)

2. **Create a chart** — [`helm create` docs](https://helm.sh/docs/helm/helm_create/), [chart structure docs](https://helm.sh/docs/topics/charts/)
   ```bash
   helm create myapp
   tree myapp  # see the structure
   ```

3. **Examine the default chart** — look at `Chart.yaml`, `values.yaml`, and `templates/deployment.yaml`

4. **Customize `values.yaml`** — [values file docs](https://helm.sh/docs/chart_template_guide/values_files/)
   ```yaml
   replicaCount: 2

   image:
     repository: nginx
     tag: alpine
     pullPolicy: IfNotPresent

   service:
     type: ClusterIP
     port: 80

   ingress:
     enabled: false

   resources:
     limits:
       cpu: 500m
       memory: 256Mi
     requests:
       cpu: 250m
       memory: 128Mi
   ```

5. **Install the chart** — [`helm install` docs](https://helm.sh/docs/helm/helm_install/)
   ```bash
   helm install myapp-release ./myapp
   helm list
   kubectl get all -l app.kubernetes.io/instance=myapp-release
   ```

6. **Upgrade with new values** — [`helm upgrade` docs](https://helm.sh/docs/helm/helm_upgrade/)
   ```bash
   helm upgrade myapp-release ./myapp --set replicaCount=3,image.tag=1.25-alpine
   kubectl get pods
   ```

7. **Rollback** — [`helm rollback` docs](https://helm.sh/docs/helm/helm_rollback/)
   ```bash
   helm rollback myapp-release 1
   kubectl get pods
   ```

8. **Search public charts** — [ArtifactHub](https://artifacthub.io/), [Bitnami charts](https://charts.bitnami.com/)
   ```bash
   helm repo add bitnami https://charts.bitnami.com/bitnami
   helm search repo bitnami/nginx
   helm install bitnami-nginx bitnami/nginx --set service.type=ClusterIP
   ```

9. **Uninstall** — [`helm uninstall` docs](https://helm.sh/docs/helm/helm_uninstall/)
   ```bash
   helm uninstall myapp-release
   helm uninstall bitnami-nginx
   ```

## Real-world relevance

No one writes raw YAML for every deploy. Helm charts are the standard way to package and distribute applications. Teams maintain internal chart repositories for their microservices. You can promote the same chart through dev → staging → prod with different `values.yaml` files.

## Summary

- Helm packages K8s manifests into charts with templating
- `values.yaml` separates config from templates
- `helm install`, `helm upgrade`, `helm rollback` manage releases
- Charts are versioned and stored in repos
- `--set` overrides values; `-f values-prod.yaml` uses a values file

## Interview Question

How does Helm templating work? Walk through how `{{ .Values.replicaCount }}` gets resolved. What's the difference between `helm install`, `helm upgrade`, and `helm rollback`? How would you manage different environments (dev/staging/prod) with the same chart?
