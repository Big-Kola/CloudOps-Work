# Day 7 — Model Answer

## Explain the lifecycle of a pod from creation to running.

1. **User submits pod definition** (via `kubectl apply` or `kubectl run`) → request sent to the **API Server**
2. **API Server** validates the request and stores the pod object in **etcd**
3. **Scheduler** watches for unscheduled pods (`.spec.nodeName` is empty), finds a suitable node based on resource requests, taints/tolerations, affinity rules
4. **Scheduler** updates the pod object in etcd with the chosen node
5. **kubelet** on the assigned node watches for new pods bound to its node, pulls the container image, starts the containers via the container runtime (containerd)
6. kubelet reports pod status back to the API Server

**Pod phases:** `Pending` → `Running` → `Succeeded` (or `Failed`)

## What happens when the node running a pod dies?

- The kubelet stops reporting heartbeats
- The **Controller Manager** detects the node as `NotReady` after a timeout (~40s by default)
- Pods on that node enter `Unknown` state
- If the pod is managed by a higher-level controller (Deployment, StatefulSet, DaemonSet), the controller recreates the pod on a healthy node
- Standalone pods (not managed by a controller) are NOT rescheduled — they remain in `Unknown` until the node recovers
