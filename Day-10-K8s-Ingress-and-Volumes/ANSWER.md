# Day 10 — Model Answer

## How does Ingress differ from a LoadBalancer Service?

| Feature | LoadBalancer Service | Ingress |
|---------|---------------------|---------|
| Layer | L4 (TCP/UDP) or basic L7 | L7 (HTTP/HTTPS) |
| Cost | One cloud LB per Service | One cloud LB shared across many Services |
| Routing | Single Service | Path-based, host-based routing |
| TLS | Terminates at LB (basic) | Centralized TLS termination, multiple certs |
| Features | No virtual hosting | Virtual hosting, redirects, rewrite, auth |

**When to use each:**
- **LoadBalancer Service** — quick dev/test, non-HTTP workloads (gRPC, WebSocket, databases), or when you need only one Service exposed
- **Ingress** — production HTTP(S) workloads with multiple Services, need host/path routing, centralized TLS, or advanced routing rules

## How do PersistentVolumeClaims work?

1. A user creates a **PVC** requesting storage (e.g., 1Gi, ReadWriteOnce access mode)
2. The cluster's **PersistentVolume controller** watches for unbound PVCs
3. It finds or dynamically provisions a **PV** that matches the PVC's requirements (size, access mode, storage class)
4. The PV binds to the PVC — they enter `Bound` state (1:1 binding)
5. A pod references the PVC in its `volumes` section and mounts it at the specified `mountPath`
6. If the pod is deleted and recreated, the PVC (and its data) persists. A new pod can mount the same PVC
7. Only when the PVC is deleted can the PV be reclaimed (retain, recycle, or delete depending on the reclaim policy)
