# Day 8 — Model Answer

## Explain how a Service routes traffic to pods.

A Service uses **labels and selectors** to dynamically discover its target pods:

1. When a pod is created, it gets an IP and a set of labels
2. The Service's `.spec.selector` matches pod labels (e.g., `app: nginx`)
3. The **kube-proxy** on each node watches the API Server for new Services and endpoints
4. kube-proxy programs iptables/IPVS rules to forward traffic from the Service's ClusterIP to the matching pod IPs
5. Traffic to the Service is load-balanced across all matching pods (random by default)

## What happens during a rolling update?

1. `kubectl set image deployment/nginx-deploy nginx=nginx:1.25-alpine` updates the Deployment's pod template
2. The **Deployment Controller** creates a new **ReplicaSet** (with the new image), scaled to 1
3. The new ReplicaSet creates a new pod (with the new image)
4. Once the new pod is Ready, the Deployment scales down the old ReplicaSet by 1
5. Steps 3-4 repeat until all pods are updated (controlled by `maxSurge` and `maxUnavailable`)
6. During the update, both old and new pods serve traffic — zero downtime
7. `kubectl rollout status` shows progress; `kubectl rollout undo` rolls back by scaling up the old ReplicaSet and scaling down the new one
