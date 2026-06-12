# Day 7: Kubernetes Architecture & Pods

## Concept

Kubernetes is a container orchestration platform. Key architecture:

- **Control Plane** — manages the cluster: API Server (entry point), etcd (key-value store), Scheduler (assigns pods to nodes), Controller Manager (reconciliation loops)
- **Nodes** — worker machines that run containers via the container runtime (containerd)
- **Pod** — smallest deployable unit. One or more containers sharing network/IP/storage. Pods are ephemeral — they die and get replaced.
- **kubectl** — CLI for talking to the API Server

## Task

1. **Install kind** (Kubernetes in Docker) — [kind quick-start docs](https://kind.sigs.k8s.io/docs/user/quick-start/)
   ```bash
   curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.24.0/kind-linux-amd64
   chmod +x ./kind && sudo mv ./kind /usr/local/bin/kind
   ```

2. **Create a cluster** — [kind create cluster docs](https://kind.sigs.k8s.io/docs/user/quick-start/#creating-a-cluster)
   ```bash
   kind create cluster --name cloudops
   ```

3. **Verify** — [`kubectl cluster-info` docs](https://kubernetes.io/docs/reference/generated/kubectl/kubectl-commands#clusterinfo), [`kubectl get nodes` docs](https://kubernetes.io/docs/reference/generated/kubectl/kubectl-commands#get)
   ```bash
   kubectl cluster-info
   kubectl get nodes
   ```

4. **Run an imperative pod** — [`kubectl run` docs](https://kubernetes.io/docs/reference/generated/kubectl/kubectl-commands#run), [`kubectl describe` docs](https://kubernetes.io/docs/reference/generated/kubectl/kubectl-commands#describe)
   ```bash
   kubectl run nginx --image=nginx --restart=Never
   kubectl get pods -o wide
   kubectl describe pod nginx
   ```

5. **Create a declarative pod** — `pod.yaml` — [pod YAML reference](https://kubernetes.io/docs/reference/kubernetes-api/workload-resources/pod-v1/)
   ```yaml
   apiVersion: v1
   kind: Pod
   metadata:
     name: hello-pod
     labels:
       app: hello
   spec:
     containers:
       - name: nginx
         image: nginx:alpine
         ports:
           - containerPort: 80
   ```

6. **Apply it** — [`kubectl apply` docs](https://kubernetes.io/docs/reference/generated/kubectl/kubectl-commands#apply), [`kubectl logs` docs](https://kubernetes.io/docs/reference/generated/kubectl/kubectl-commands#logs), [`kubectl exec` docs](https://kubernetes.io/docs/reference/generated/kubectl/kubectl-commands#exec)
   ```bash
   kubectl apply -f pod.yaml
   kubectl get pods
   kubectl logs hello-pod
   kubectl exec hello-pod -- sh -c "echo Pod is running"
   ```

7. **Port-forward to access nginx** — [`kubectl port-forward` docs](https://kubernetes.io/docs/reference/generated/kubectl/kubectl-commands#port-forward)
   ```bash
   kubectl port-forward pod/hello-pod 8080:80
   # In another terminal: curl http://localhost:8080
   ```

8. **Clean up**
   ```bash
   kubectl delete pod nginx
   kubectl delete -f pod.yaml
   ```

## Real-world relevance

Pods are the atomic unit in K8s. Understanding how the API Server processes your YAML, how the Scheduler picks a node, and how the kubelet starts the container is foundational. You don't run pods directly in production (you use Deployments), but every higher-level abstraction is built on pods.

## Summary

- Control Plane: API Server, etcd, Scheduler, Controller Manager
- Pod: one or more containers with shared network/storage
- Imperative `kubectl run` vs declarative `kubectl apply -f`
- `kubectl describe` shows events and debugging info
- `kubectl exec` runs commands inside containers

## Interview Question

Explain the lifecycle of a pod from creation to running. What components are involved (API Server, Scheduler, kubelet)? What happens when the node running a pod dies?
