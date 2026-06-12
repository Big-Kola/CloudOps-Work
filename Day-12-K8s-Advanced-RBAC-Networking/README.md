# Day 12: K8s Advanced — RBAC, Network Policies, Monitoring

## Concept

**RBAC (Role-Based Access Control)** — controls who can do what in the cluster.
- `Role` / `ClusterRole` — defines permissions (what verbs on what resources)
- `RoleBinding` / `ClusterRoleBinding` — binds a role to a user, group, or service account
- Rules: `apiGroups`, `resources`, `verbs` (get, list, watch, create, update, delete)

**Network Policies** — firewall rules for pods. By default all pods can talk to each other. NetworkPolicy restricts ingress/egress traffic based on labels, namespaces, or IP blocks.

**Monitoring (metrics-server)** — collects resource metrics (CPU/memory) from kubelet and enables `kubectl top`.

## Task

### RBAC

1. **Create a namespace and service account** — [RBAC docs](https://kubernetes.io/docs/reference/access-authn-authz/rbac/)
   ```bash
   kubectl create namespace team-a
   kubectl create serviceaccount app-sa -n team-a
   ```

2. **Create a Role** — `role.yaml` — [Role & ClusterRole docs](https://kubernetes.io/docs/reference/access-authn-authz/rbac/#role-and-clusterrole)
   ```yaml
   apiVersion: rbac.authorization.k8s.io/v1
   kind: Role
   metadata:
     namespace: team-a
     name: pod-reader
   rules:
     - apiGroups: [""]
       resources: ["pods", "pods/log"]
       verbs: ["get", "list", "watch"]
   ```

3. **Bind the role** — `rolebinding.yaml` — [RoleBinding & ClusterRoleBinding docs](https://kubernetes.io/docs/reference/access-authn-authz/rbac/#rolebinding-and-clusterrolebinding)
   ```yaml
   apiVersion: rbac.authorization.k8s.io/v1
   kind: RoleBinding
   metadata:
     name: pod-reader-binding
     namespace: team-a
   subjects:
     - kind: ServiceAccount
       name: app-sa
       namespace: team-a
   roleRef:
     kind: Role
     name: pod-reader
     apiGroup: rbac.authorization.k8s.io
   ```

4. **Test RBAC** — [`kubectl auth can-i` docs](https://kubernetes.io/docs/reference/generated/kubectl/kubectl-commands#auth)
   ```bash
   kubectl auth can-i get pods --as=system:serviceaccount:team-a:app-sa -n team-a
   kubectl auth can-i delete pods --as=system:serviceaccount:team-a:app-sa -n team-a
   ```

### Network Policies

5. **Deploy two apps** — `apps.yaml`
   ```yaml
   apiVersion: v1
   kind: Pod
   metadata:
     name: frontend
     labels:
       app: frontend
   spec:
     containers:
       - name: nginx
         image: nginx:alpine
   ---
   apiVersion: v1
   kind: Pod
   metadata:
     name: backend
     labels:
       app: backend
   spec:
     containers:
       - name: nginx
         image: nginx:alpine
   ```

6. **Apply a Network Policy** — `netpol.yaml` — [NetworkPolicy docs](https://kubernetes.io/docs/concepts/services-networking/network-policies/)
   ```yaml
   apiVersion: networking.k8s.io/v1
   kind: NetworkPolicy
   metadata:
     name: backend-allow-frontend
   spec:
     podSelector:
       matchLabels:
         app: backend
     policyTypes:
       - Ingress
     ingress:
       - from:
           - podSelector:
               matchLabels:
                 app: frontend
         ports:
           - port: 80
   ```

7. **Test** — exec into frontend, curl backend. Then exec into backend, try curling itself or anything else.

### Monitoring

8. **Install metrics-server** — [metrics-server docs](https://github.com/kubernetes-sigs/metrics-server)
   ```bash
   kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
   ```

9. **View metrics** — [`kubectl top` docs](https://kubernetes.io/docs/reference/generated/kubectl/kubectl-commands#top)
   ```bash
   kubectl top nodes
   kubectl top pods
   ```

## Real-world relevance

RBAC is how platform teams give developers access to namespaces without letting them touch other teams' resources or cluster-level settings. Network Policies are required for production security — without them, a compromised pod can reach any other pod. Metrics-server powers HPA (Horizontal Pod Autoscaler) and resource troubleshooting.

## Summary

- RBAC: Role/ClusterRole define rules, RoleBinding/ClusterRoleBinding assign them
- NetworkPolicy: pod-level firewall, default-deny model
- Network policies require a CNI that supports them (Calico, Cilium, Weave)
- metrics-server enables `kubectl top` and HorizontalPodAutoscaler

## Interview Question

How would you give a CI/CD service account permission to deploy only to the `staging` namespace? Write the RBAC YAML. How do Network Policies work at the pod level — can you write a policy that blocks all traffic except from Prometheus?

What does `kubectl top` show you, and what component provides that data?
