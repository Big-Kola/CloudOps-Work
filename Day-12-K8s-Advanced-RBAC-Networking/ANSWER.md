# Day 12 — Model Answer

## How would you give a CI/CD service account permission to deploy only to the `staging` namespace?

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: ci-deployer
  namespace: staging
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  namespace: staging
  name: deployer
rules:
  - apiGroups: ["apps"]
    resources: ["deployments"]
    verbs: ["get", "list", "watch", "create", "update", "patch"]
  - apiGroups: [""]
    resources: ["pods", "services", "configmaps", "secrets"]
    verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: ci-deployer-binding
  namespace: staging
subjects:
  - kind: ServiceAccount
    name: ci-deployer
    namespace: staging
roleRef:
  kind: Role
  name: deployer
  apiGroup: rbac.authorization.k8s.io
```

This binds the deployer Role only in the `staging` namespace. The CI system authenticates as this ServiceAccount and can only modify resources in `staging`.

## How do Network Policies work at the pod level?

A NetworkPolicy is a pod-level firewall enforced by the CNI plugin (Calico, Cilium, Weave). Policies use `podSelector` labels to target pods and define ingress/egress rules.

**Policy that blocks all traffic except from Prometheus:**
```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-only-prometheus
spec:
  podSelector:
    matchLabels:
      app: myapp
  policyTypes:
    - Ingress
  ingress:
    - from:
        - podSelector:
            matchLabels:
              app: prometheus
      ports:
        - port: 9090
```

## What does `kubectl top` show?

Shows current CPU and memory usage for nodes (`kubectl top nodes`) and pods (`kubectl top pods`). Data comes from **metrics-server**, which collects resource metrics from the kubelet's Summary API. Required for HorizontalPodAutoscaler (HPA) and `kubectl top`.
